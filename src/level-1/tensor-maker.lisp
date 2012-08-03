(in-package #:matlisp)

(defmacro make-tensor-maker (func-name (tensor-class))
  (let ((opt (get-tensor-class-optimization tensor-class))
	(cocl (get-tensor-counterclass tensor-class)))
    (assert opt nil 'tensor-cannot-find-optimization :tensor-class tensor-class)
    (assert cocl nil 'tensor-cannot-find-counter-class :tensor-class tensor-class)
    `(defun ,func-name (&rest args)
       (labels ((make-dims (dims)
		  (declare (type cons dims))
		  (let* ((vdim (make-index-store dims))
			 (ss (reduce #'* vdim))
			 (store (,(getf opt :store-allocator) ss))
			 (rnk (length vdim)))
		    (make-instance (case rnk (2 ',(getf cocl :matrix)) (1 ',(getf cocl :vector)) (t ',tensor-class))
				   :store store :dimensions vdim)))
		(make-from-array (arr)
		  (declare (type (array * *) arr))
		  (let* ((ret (make-dims (array-dimensions arr)))
			 (st-r (store ret))
			 (lst (make-list (rank ret))))
		    (declare (type ,tensor-class ret)
			     (type ,(linear-array-type (getf opt :store-type)) st-r))
		    (very-quickly
		      (mod-dotimes (idx (dimensions ret))
			with (linear-sums
			      (of-r (strides ret) (head ret)))
			do ,(funcall (getf opt :value-writer) `(,(getf opt :coercer) (apply #'aref arr (lvec->list! idx lst))) 'st-r 'of-r)))
		    ret))
		(make-from-list (lst)
		  (let* ((ret (make-dims (list-dimensions lst)))
			 (st-r (store ret)))
		    (declare (type ,tensor-class ret)
			     (type ,(linear-array-type (getf opt :store-type)) st-r))
		    (very-quickly
		      (list-loop (idx ele lst)
				 with (linear-sums
				       (of-r (strides ret) (head ret)))
				 do ,(funcall (getf opt :value-writer) `(,(getf opt :coercer) ele) 'st-r 'of-r)))
		    ret)))
	 (let ((largs (length args)))
	   (if (= largs 1)
	       (etypecase (first args)
		 (array
		  (make-from-array (first args)))
		 (cons
		  (make-from-list (first args)))
		 (integer
		  (make-dims (list (first args)))))
	       (make-dims args)))))))

(make-tensor-maker make-real-tensor (real-tensor))
(make-tensor-maker make-complex-tensor (complex-tensor))

;;Had to move it here in the wait for copy!
(definline sub-tensor (tensor subscripts)
  (copy (sub-tensor~ tensor subscripts)))

