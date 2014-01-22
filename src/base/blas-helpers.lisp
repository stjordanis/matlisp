(in-package #:matlisp)
   
(defun consecutive-storep (tensor)
  (declare (type standard-tensor tensor))
  (memoizing (tensor consecutive-storep)
    (mlet* (((sort-std std-perm) (very-quickly (sort-permute-base (copy-seq (the index-store-vector (strides tensor))) #'<))
	     :type (index-store-vector pindex-store-vector))
	    (perm-dims (very-quickly (apply-action! (copy-seq (the index-store-vector (dimensions tensor))) std-perm)) :type index-store-vector))
	   (very-quickly
	     (loop
		:for so-st :across sort-std
		:for so-di :across perm-dims
		:and accumulated-off := (aref sort-std 0) :then (the index-type (* accumulated-off so-di))
		:unless (= so-st accumulated-off) :do (return (values nil perm-dims sort-std std-perm))
		:finally (return (values (aref sort-std 0) perm-dims sort-std std-perm)))))))

(definline blas-copyablep (ten-a ten-b)
  (declare (type standard-tensor ten-a ten-b))
  (when (= (rank ten-a) (rank ten-b))
    (mlet*
     (((csto-a? pdims-a tmp perm-a) (consecutive-storep ten-a) :type (t index-store-vector nil pindex-store-vector))
      ((csto-b? pdims-b tmp perm-b) (consecutive-storep ten-b) :type (t index-store-vector nil pindex-store-vector)))
     (when (and csto-a? csto-b? (very-quickly (lvec-eq perm-a perm-b)) (very-quickly (lvec-eq pdims-a pdims-b)))
       (list csto-a? csto-b?)))))

(definline fortran-nop (op)
  (ecase op (#\T #\N) (#\N #\T)))

(definline fortran-nuplo (op)
  (ecase op (#\U #\L) (#\L #\U)))

(definline split-job (job)
  (declare (type symbol job))
  (let-typed ((name (symbol-name job) :type string))
    (loop :for x :across name :collect (char-upcase x))))

(definline flip-major (job)
  (declare (type symbol job))
  (case job
    (:row-major :col-major)
    (:col-major :row-major)))

(definline blas-matrix-compatiblep (matrix op)
  (declare (type standard-tensor matrix)
	   (type character op))
  (assert (tensor-matrixp matrix) nil 'tensor-not-matrix)
  (let*-typed ((stds (strides matrix) :type index-store-vector)
	       (rs (aref stds 0) :type index-type)
	       (cs (aref stds 1) :type index-type))
    ;;Note that it is not required that (rs = nc * cs) or (cs = nr * rs)
    (cond
      ((and (char/= op #\C) (= cs 1)) (values rs (fortran-nop op) :row-major))
      ((= rs 1) (values cs op :col-major)))))

(definline call-fortran? ( x lb)
  (declare (type standard-tensor x))
  (> (size x) lb))

(defmacro with-columnification ((type (&rest input) (&rest output)) &rest body)
  (with-gensyms (cfunc)
    (let ((input-syms (mapcar #'(lambda (x)
				  (assert (or (symbolp (second x)) (characterp (second x))) nil "Given a non-symbolic input.")
				  (gensym (symbol-name (car x)))) input))
	  (output-syms (mapcar #'(lambda (mat) (gensym (symbol-name mat))) output)))
      `(labels ((,cfunc (a &optional b)
		  (declare (type ,type a))
		  (let ((ret (or b (let ((*default-stride-ordering* :col-major)) (t/zeros ,type (the index-store-vector (dimensions a)))))))
		    (declare (type ,type a ret))
		    (t/copy! (,type ,type) a ret))))
	 (let (,@(mapcar #'(lambda (x sym) (let ((mat (first x)) (job (second x)))
					     `(,sym (if (blas-matrix-compatiblep ,mat ,job) ,mat
							(,cfunc ,mat))))) input input-syms)
	       ,@(mapcar #'(lambda (mat sym) `(,sym (if (eql (third (multiple-value-list (blas-matrix-compatiblep ,mat #\N))) :col-major) ,mat
							(,cfunc ,mat)))) output output-syms))
	   (declare (type ,type ,@(append input-syms output-syms)))
	   (symbol-macrolet (,@(mapcar #'(lambda (mat sym) `(,mat ,sym)) (append (mapcar #'car input) output) (append input-syms output-syms)))
	     ,@body)
	   ,@(mapcar #'(lambda (mat sym) `(unless (eql (third (multiple-value-list (blas-matrix-compatiblep ,mat #\N))) :col-major)
	   				    (,cfunc ,sym ,mat))) output output-syms)
	   nil)))))


(definline pflip.f->l (uidiv)
  (declare (type (simple-array (unsigned-byte 32) (*)) uidiv))
  (let ((ret (make-array (length uidiv) :element-type 'pindex-type)))
    (declare (type pindex-store-vector ret))
    (very-quickly
      (loop :for i :from 0 :below (length uidiv)
	 :do (setf (aref ret i) (1- (aref uidiv i)))))
    ret))

(definline pflip.l->f (idiv)
  (declare (type pindex-store-vector idiv))
  (let ((ret (make-array (length idiv) :element-type '(unsigned-byte 32))))
    (declare (type (simple-array (unsigned-byte 32) (*)) ret))
    (very-quickly
      (loop :for i :from 0 :below (length idiv)
	 :do (setf (aref ret i) (1+ (aref idiv i)))))
    ret))
