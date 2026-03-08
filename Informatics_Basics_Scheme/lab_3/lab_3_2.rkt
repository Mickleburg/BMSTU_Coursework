(define-syntax test
  (syntax-rules ()
    ((test proc rez) '(proc rez))))

(define (run-test test)
  (write (car test))
  (let ((cur_rez (eval (car test) (interaction-environment)))
        (good_rez (cadr test)))
    (if (equal? cur_rez good_rez)
        (begin
         (display "ok\n")
         #t)      
        (begin
          (display "FAIL\n")
          (display "  Expected:")
          (write good_rez)
          (newline)
          (display "  Returned:")
          (write cur_rez)
          (newline)
          #f))))

(define (run-tests tests)
  (if (null? (cdr tests))
      (run-test (car tests))
      ((lambda (x y)
         (and x y))
       (run-test (car tests))
       (run-tests (cdr tests)))))

(define (signum x)
  (cond
    ((< x 0) -1)
    ((= x 0)  1)
    (else     1)))

(define the-tests
  (list (test (signum -2) -1)
        (test (signum  0)  0)
        (test (signum  2)  1)))

(run-tests the-tests)