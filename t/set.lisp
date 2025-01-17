(in-package #:value-semantics-utils/test)

(define-test set-test
  (let ((set-1 (make-instance 'vs:set :test 'vs:eqv)))
    (is eq '() (vs:set-contents set-1))
    (is eq #'vs:eqv (vs:set-test set-1))
    (let ((set-2 (vs:set-insert set-1 42))
          (set-3 (vs:set-insert set-1 42)))
      (isnt eq set-1 set-2)
      (isnt eq set-2 set-3)
      (multiple-value-bind (value foundp) (vs:set-find set-2 42)
        (is vs:eqv 42 value)
        (true foundp))
      (multiple-value-bind (value foundp) (vs:set-find set-2 24)
        (false value)
        (false foundp))
      (is vs:eqv set-2 set-3)
      (is vs:eqv '(42) (vs:set-contents set-2))
      (let ((set-4 (vs:set-insert set-2 24)))
        (is a:set-equal '(42 24) (vs:set-contents set-4))
        (let ((set-5 (vs:set-remove set-4 24)))
          (is vs:eqv set-5 set-2)))
      (let ((set-6 (vs:copy set-2)))
        (is vs:eqv '(42) (vs:set-contents set-6))))))

(define-test set-operations
  (let ((set-1 (vs:set 1 2 3 4))
        (set-2 (vs:set 3 4 5 6)))
    (let ((result (vs:set-contents (vs:set-difference set-1 set-2))))
      (is a:set-equal '(1 2) result))
    (let ((result (vs:set-contents (vs:set-union set-1 set-2))))
      (is a:set-equal '(1 2 3 4 5 6) result))
    (let ((result (vs:set-contents (vs:set-intersection set-1 set-2))))
      (is a:set-equal '(3 4) result))
    (let ((result (vs:set-contents (vs:set-exclusive-or set-1 set-2))))
      (is a:set-equal '(1 2 5 6) result))))
