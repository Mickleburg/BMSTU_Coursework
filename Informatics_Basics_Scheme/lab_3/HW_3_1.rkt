;;Unit-tests
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

;;результат можно сделать нечувствительным к его способу представления,
;;высчитывая выражения при помощи eval

;;Derivative
(define (derivative expr)
  (cond
    ;;expr - не выражение
    ((not (list? expr))
     (if (number? expr) 0 1))
    ;;expr - выражение из одного слова
    ((null? (cdr expr))
     (if (number? (car expr)) 0 1))
    ;;бинарные функции
    ((equal? (length expr) 3)
     (cond
       ((equal? (car expr) '+)
        `(+ ,(derivative (cadr expr)) ,(derivative (caddr expr))))
       ((equal? (car expr) '-)
        `(- ,(derivative (cadr expr)) ,(derivative (caddr expr))))
       ((equal? (car expr) '*)
        `(+ (* ,(derivative (cadr expr)) ,(caddr expr)) (* ,(cadr expr) ,(derivative (caddr expr)))))
       ((equal? (car expr) '/)
        `(/ (- (* ,(derivative (cadr expr)) ,(caddr expr))
               (* ,(cadr expr) ,(derivative (caddr expr)))) (expt ,(caddr expr) 2)))
       ((equal? (car expr) 'expt)
        (if (number? (caddr expr))
            (cond
              ((> (caddr expr) 0)
               `(* ,(caddr expr)
                   (* (expt ,(cadr expr) ,(- (caddr expr) 1)) ,(derivative (cadr expr)))))
              ((equal? (caddr expr) 0) 1)
              (else (derivative `(/ 1 (expt ,(cadr expr) ,(abs(caddr expr)))))))
            `(* (expt ,(cadr expr) ,(caddr expr)) (* (log ,(cadr expr)) ,(derivative (caddr expr))))))))
    ;;унарные функции
    ((equal? (length expr) 2)
     (cond
       ((equal? (car expr) 'cos)
        `(* (- (sin ,(cadr expr))) ,(derivative (cadr expr))))
       ((equal? (car expr) 'sin)
        `(* (cos ,(cadr expr)) ,(derivative (cadr expr))))
       ((or (equal? (car expr) 'ln) (equal? (car expr) 'log))
        `(* (/ 1 ,(cadr expr)) ,(derivative (cadr expr))))
       ((equal? (car expr) '-)
        `(- ,(derivative (cadr expr))))
       ;;exp - возведение e в степень
       ((equal? (car expr) 'exp)
        (if (number? (cadr expr))
            0
            `(* (exp ,(cadr expr)) ,(derivative (cadr expr)))))))
    ((> (length expr) 3)
     (if (equal? (car expr) '+)
         `(+ ,(derivative (cadr expr)) ,(derivative (cons '+ (cddr expr))))
         `(+ (* ,(derivative (cadr expr)) ,(cons '* (cddr expr)))
             (* ,(cadr expr) ,(derivative (cons '* (cddr expr)))))))))

;(derivative '(* 2 (sin x) (cos x)))

#|
(define e 2.71828)
(define x 1)

(derivative '2)
(derivative '(2))
(derivative 'x)
(derivative '(x))
(derivative '(- x))
(derivative '(* 1 x))
(derivative '(* -1 x))
(derivative '(* -4 x))
(derivative '(* 10 x))
(derivative '(- (* 2 x) 3))
(derivative '(expt x 10))
(derivative '(* 2 (expt x 5)))
(derivative '(expt x -2))
(derivative '(expt 5 x))
(derivative '(cos x))
(derivative '(sin x))
(derivative '(expt e x))
(derivative '(* 2 (expt e x)))
(derivative '(* 2 (expt e (* 2 x))))
(derivative '(ln x))
(derivative '(* 3 (ln x)))
(derivative '(+ (expt x 3) (expt x 2)))
(derivative '(- (* 2 (expt x 3)) (* 2 (expt x 2))))
(derivative '(/ 3 x))
(derivative '(/ 3 (* 2 (expt x 2))))
;(eval (derivative '(/ 3 (* 2 (expt x 2)))) (interaction-environment))
(derivative '(* 2 (* (sin x) (cos x))))
(derivative '(* 2 (* (expt e x) (* (sin x) (cos x)))))
(derivative '(sin ( * 2 x)))
(derivative '(cos (* 2 (expt x 2))))
(derivative '(sin (ln (expt x 2))))
(derivative '(+ (sin (* 2 x)) (cos (* 2 (expt x 2)))))
(derivative '(* (sin (* 2 x)) (cos (* 2 (expt x 2)))))
|#