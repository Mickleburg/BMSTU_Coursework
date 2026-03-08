(define (if->cond data)
  (if (and (list? data) (equal? (car data) 'if))
      (let ((condition (cadr data))
            (true_v (caddr data))
            (false_v (if (null? (cdddr data))
                         '()
                         (cadddr data))))
        (cond
          ((null? false_v) `(cond (,condition ,true_v)))
          ((and (list? false_v) (equal? (car false_v) 'if))
           `(cond (,condition ,true_v)
                  ,@(cdr (if->cond false_v))))
          (else `(cond (,condition ,true_v) (else ,false_v)))))
      data))


(define tests-4
  (list
   (test (if->cond '(if (> x 0)
                        +1
                        (if (< x 0)
                            -1
                            0)))
         (cond ((> x 0) +1) ((< x 0) -1) (else 0)))
   (test (if->cond '(if (equal? (car expr) 'lambda)
                        (compile-lambda expr)
                        (if (equal? (car expr) 'define)
                            (compile-define expr)
                            (if (equal? (car expr) 'if)
                                (compile-if expr)))))
         (cond ((equal? (car expr) 'lambda) (compile-lambda expr))
               ((equal? (car expr) 'define) (compile-define expr))
               ((equal? (car expr) 'if) (compile-if expr))))
   (test (if->cond '(if (not (integer? x))
                        (display "x - is't a number")
                        (if (<= x 0)
                            (display "x -> X")
                            (display "x -> N"))))
         (cond ((not (integer? x)) (display "x - is't a number"))
               ((<= x 0) (display "x -> X"))
               (else (display "x -> N"))))))

(run-tests tests-4)
