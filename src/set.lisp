(in-package #:value-semantics-utils)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Set

(defclass set ()
  ((test :initarg :test :reader set-test)
   (contents :initarg :contents :reader set-contents :type list)
   (count :initarg count :reader set-count :type unsigned-byte))
  (:default-initargs :test #'eqv :contents '())
  (:metaclass class-with-value-semantics))

(defun set (&rest contents)
  (make-instance 'set :contents contents 'count (length contents)))

(defmethod shared-initialize :after ((set set) slots &key)
  (a:coercef (slot-value set 'test) 'function)
  (unless (slot-boundp set 'count)
    (setf (slot-value set 'count) (length (set-contents set))))
  (let* ((test (set-test set))
         (contents-1 (set-contents set))
         (contents-2 (remove-duplicates contents-1 :test test)))
    (unless (= (length contents-1) (length contents-2))
      (setf (slot-value set 'contents) contents-2))))

(defmethod generic-eqv ((x set) (y set))
  (declare (optimize speed))
  (declare #+sbcl (sb-ext:muffle-conditions sb-ext:compiler-note))
  ;; If the set sizes are different, the comparison fails.
  (unless (= (the unsigned-byte (set-count x))
             (the unsigned-byte (set-count y)))
    (return-from generic-eqv (values nil nil nil nil)))
  ;; If the test function is different, the comparison fails.
  (unless (cl:eq (set-test x) (set-test y))
    (return-from generic-eqv (values nil nil nil)))
  (let ((contents (set-contents x))
        (test (set-test x)))
    (declare (type function test))
    ;; If the sets are empty, the comparison succeeds.
    (when (null contents)
      (return-from generic-eqv (values t nil nil nil)))
    ;; The sets are not empty. Return a continuation that will compare
    ;; them element by element.
    (labels ((set-continuation ()
               (let* ((x-value (car contents)))
                 (setf contents (cdr contents))
                 (let ((y-value-p (member x-value (set-contents y) :test test)))
                   (unless y-value-p
                     (return-from set-continuation
                       (values nil nil nil nil)))
                   (let ((y-value (car y-value-p))
                         (continuation (if (not (null contents))
                                           #'set-continuation
                                           nil)))
                     (return-from set-continuation
                       (values t x-value y-value continuation)))))))
      (set-continuation))))

(defun set-insert (set thing)
  (let* ((contents (set-contents set))
         (count (set-count set))
         (foundp (member thing contents :test (set-test set))))
    (if foundp set (copy set :contents (cons thing contents)
                         'count (1+ count)))))

(defun set-remove (set thing)
  (let* ((contents (set-contents set))
         (count (set-count set))
         (foundp (member thing contents :test (set-test set))))
    (if (not foundp)
        set
        (copy set :contents (remove thing contents
                                    :test (set-test set))
              'count (1- count)))))

(defun set-find (set thing)
  (let* ((contents (set-contents set))
         (foundp (member thing contents :test (set-test set))))
    (if foundp
        (values thing t)
        (values nil nil))))

(macrolet ((make (name operator)
             `(defun ,name (x y)
                (let ((contents (,operator (set-contents x)
                                           (set-contents y)
                                           :test (set-test x))))
                  (copy x :contents contents 'count (length contents))))))
  (make set-difference cl:set-difference)
  (make set-union union)
  (make set-intersection intersection)
  (make set-exclusive-or cl:set-exclusive-or))
