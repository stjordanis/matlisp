;;; -*- Mode: lisp; Syntax: ansi-common-lisp; Package: :matlisp; Base: 10 -*-
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Copyright (c) 2000 The Regents of the University of California.
;;; All rights reserved. 
;;; 
;;; Permission is hereby granted, without written agreement and without
;;; license or royalty fees, to use, copy, modify, and distribute this
;;; software and its documentation for any purpose, provided that the
;;; above copyright notice and the following two paragraphs appear in all
;;; copies of this software.
;;; 
;;; IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY
;;; FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
;;; ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
;;; THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
;;; SUCH DAMAGE.
;;;
;;; THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
;;; INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;;; MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE
;;; PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
;;; CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
;;; ENHANCEMENTS, OR MODIFICATIONS.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package #:matlisp)

(defmacro generate-typed-axpy! (func (tensor-class blas-func fortran-lb))
  ;;Be very careful when using functions generated by this macro.
  ;;Indexes can be tricky and this has no safety net
  ;;Use only after checking the arguments for compatibility.
  (let* ((opt (get-tensor-class-optimization-hashtable tensor-class)))
    (assert opt nil 'tensor-cannot-find-optimization :tensor-class tensor-class)
    `(progn
       (eval-when (:compile-toplevel :load-toplevel :execute)
	 (let ((opt (get-tensor-class-optimization-hashtable ',tensor-class)))
	   (assert opt nil 'tensor-cannot-find-optimization :tensor-class ',tensor-class)
	   (setf (getf opt :axpy) ',func
		 (get-tensor-class-optimization ',tensor-class) opt)))
       (defun ,func (alpha from to)
	 (declare (type ,tensor-class from to)
		  (type ,(getf opt :element-type) alpha))
	 ,(let
	      ((lisp-routine
		 `(let ((f-sto (store from))
			(t-sto (store to)))
		    (declare (type ,(linear-array-type (getf opt :store-type)) f-sto t-sto))
		    (very-quickly
		      (mod-dotimes (idx (dimensions from))
			with (linear-sums
			      (f-of (strides from) (head from))
			      (t-of (strides to) (head to)))
			do (let ((f-val (,(getf opt :reader) f-sto f-of))
				 (t-val (,(getf opt :reader) t-sto t-of)))
			     (declare (type ,(getf opt :element-type) f-val t-val))
			     (let ((t-new (,(getf opt :f+) (,(getf opt :f*) f-val alpha) t-val)))
			       (declare (type ,(getf opt :element-type) t-new))
			       (,(getf opt :value-writer) t-new t-sto t-of))))))))
	    (if blas-func
		`(let* ((call-fortran? (> (number-of-elements to)
					  ,fortran-lb))
			(strd-p (when call-fortran? (blas-copyable-p from to))))
		   (cond
		     ((and call-fortran? strd-p)
		      (,blas-func (number-of-elements from) alpha
				  (store from) (first strd-p)
				  (store to) (second strd-p)
				  (head from) (head to)))
		     (t
		      ,lisp-routine)))
		lisp-routine))
	 to))))

(defmacro generate-typed-num-axpy! (func (tensor-class blas-func fortran-lb))
  ;;Be very careful when using functions generated by this macro.
  ;;Indexes can be tricky and this has no safety net
  ;;(you don't see a matrix-ref do you ?)
  ;;Use only after checking the arguments for compatibility.
  (let* ((opt (get-tensor-class-optimization tensor-class)))
    (assert opt nil 'tensor-cannot-find-optimization :tensor-class tensor-class)
    `(progn
       (eval-when (:compile-toplevel :load-toplevel :execute)
	 (let ((opt (get-tensor-class-optimization-hashtable ',tensor-class)))
	   (assert opt nil 'tensor-cannot-find-optimization :tensor-class ',tensor-class)
	   (setf (getf opt :num-axpy) ',func
		 (get-tensor-class-optimization ',tensor-class) opt)))
       (defun ,func (num-from to)
	 (declare (type ,tensor-class to)
		  (type ,(getf opt :element-type) num-from))
	 ,(let
	      ((lisp-routine
		 `(let-typed
		   ((t-sto (store to) :type ,(linear-array-type (getf opt :store-type))))
		   (very-quickly
		     (mod-dotimes (idx (dimensions to))
		       with (linear-sums
			     (t-of (strides to) (head to)))
		       do (let-typed
			   ((val (,(getf opt :reader) t-sto t-of) :type ,(getf opt :element-type)))
			   (,(getf opt :value-writer) (,(getf opt :f+) num-from val) t-sto t-of)))))))
	    (if blas-func
		`(let* ((call-fortran? (> (number-of-elements to) ,fortran-lb))
			(min-strd (when call-fortran? (consecutive-store-p to))))
		   (cond
		     ((and call-fortran? min-strd)
		      (let ((num-array (,(getf opt :store-allocator) 1)))
			(declare (type ,(linear-array-type (getf opt :store-type)) num-array))
			(let-typed ((id (,(getf opt :fid+)) :type ,(getf opt :element-type)))
				   (,(getf opt :value-writer) id num-array 0))
			(,blas-func (number-of-elements to) num-from
				    num-array 0
				    (store to) min-strd
				    0 (head to))))
		     (t
		      ,lisp-routine)))
		lisp-routine))
	 to))))

;;Real
(generate-typed-axpy! real-typed-axpy!
    (real-tensor daxpy *real-l1-fcall-lb*))

(generate-typed-num-axpy! real-typed-num-axpy!
    (real-tensor daxpy *real-l1-fcall-lb*))

;;Complex
(generate-typed-axpy! complex-typed-axpy!
    (complex-tensor zaxpy *complex-l1-fcall-lb*))

(generate-typed-num-axpy! complex-typed-num-axpy!
    (complex-tensor zaxpy *complex-l1-fcall-lb*))

;;Symbolic
#+maxima
(progn
  (generate-typed-axpy! symbolic-typed-axpy!
      (symbolic-tensor nil 0))
  
  (generate-typed-num-axpy! symbolic-typed-num-axpy!
      (symbolic-tensor nil 0)))

;;---------------------------------------------------------------;;

(defgeneric axpy! (alpha x y)
  (:documentation
   " 
 Syntax
 ======
 (AXPY! alpha x y)

 Y <- alpha * x + y

 If x is T, then

 Y <- alpha + y

 Purpose
 =======
  Same as AXPY except that the result
  is stored in Y and Y is returned.
")
  (:method :before ((alpha number) (x standard-tensor) (y standard-tensor))
    (assert (lvec-eq (dimensions x) (dimensions y) #'=) nil
	    'tensor-dimension-mismatch))
  (:method ((alpha number) (x complex-tensor) (y real-tensor))
    (error 'coercion-error :from 'complex-tensor :to 'real-tensor)))

(defmethod axpy! ((alpha number) (x (eql nil)) (y real-tensor))
  (real-typed-num-axpy! (coerce-real alpha) y))

(defmethod axpy! ((alpha number) (x (eql nil)) (y complex-tensor))
  (complex-typed-num-axpy! (coerce-complex alpha) y))

(defmethod axpy! ((alpha number) (x real-tensor) (y real-tensor))
  (real-typed-axpy! (coerce-real alpha) x y))

(defmethod axpy! ((alpha number) (x real-tensor) (y complex-tensor))
  ;;Weird, shouldn't SBCL know this already ?
  (declare (type complex-tensor y))
  (let ((tmp (tensor-realpart~ y)))
    (declare (type real-tensor tmp))
    (etypecase alpha
      (cl:real (real-typed-axpy! (coerce-real alpha) x tmp))
      (cl:complex
       (real-typed-axpy! (coerce-real (realpart alpha)) x tmp)
       ;;Move tensor to the imagpart.
       (incf (head tmp))
       (real-typed-axpy! (coerce-real (realpart alpha)) x tmp))))
  y)

(defmethod axpy! ((alpha number) (x complex-tensor) (y complex-tensor))
  (complex-typed-axpy! (coerce-complex alpha) x y))

;;
(defgeneric axpy (alpha x y)
  (:documentation
   "
 Syntax
 ======
 (AXPY alpha x y)

 Purpose
 =======
 Computes  
      
                 ALPHA * X + Y

 where ALPHA is a scalar and X,Y are
 tensors.

 The result is stored in a new matrix 
 that has the same dimensions as Y.

 X,Y must have the same dimensions.
")
  (:method :before ((alpha number) (x standard-tensor) (y standard-tensor))
    (unless (lvec-eq (dimensions x) (dimensions y) #'=)
      (error 'tensor-dimension-mismatch))))

(defmethod axpy ((alpha number) (x real-tensor) (y real-tensor))
  (let ((ret (if (complexp alpha)
		 (copy! y (apply #'make-complex-tensor (lvec->list (dimensions y))))
		 (copy y))))
    (axpy! alpha x ret)))

(defmethod axpy ((alpha number) (x complex-tensor) (y real-tensor))
  (let ((ret (copy! y (apply #'make-complex-tensor (lvec->list (dimensions y))))))
    (axpy! alpha y ret)))

(defmethod axpy ((alpha number) (x real-tensor) (y complex-tensor))
  (let ((ret (copy y)))
    (axpy! alpha x ret)))

(defmethod axpy ((alpha number) (x complex-tensor) (y complex-tensor))
  (let ((ret (copy y)))
    (axpy! alpha x ret)))

(defmethod axpy ((alpha number) (x (eql nil)) (y complex-tensor))
  (let ((ret (copy y)))
    (axpy! alpha nil ret)))

(defmethod axpy ((alpha number) (x (eql nil)) (y real-tensor))
  (let ((ret (if (complexp alpha)
		 (copy! y (apply #'make-complex-tensor (lvec->list (dimensions y))))
		 (copy y))))
    (axpy! alpha nil ret)))

(defmethod axpy ((alpha number) (x standard-tensor) (y (eql nil)))
  (scal alpha x))
