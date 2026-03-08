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
;;не знаю, 15 часов мучиться с производной было круто...

(define (ln x)
  (log x))
(define (derivative expr)
  (cond
    ((not (list? expr)) (if (number? expr) 0 1)) ;; неожиданная непредусмотренная оплошность(
    ;; Производная константы или переменной
    ((= (length expr) 1) 
     (if (number? (car expr))
         0 ;; Константа
         1)) ;; Переменная

    ;  '(0) ;; Константа
    ;  '(1))) ;; Переменная

    ;; Производная унарных функций (sin, cos, ln)
    ((= (length expr) 2) 
     (let ((op (car expr))
           (arg (list-ref expr 1)))
       (cond 
         ((eq? op 'sin)
          (if (list? arg)
              `(* ,(derivative arg) (cos ,arg))
              `(cos ,arg)))
         ((eq? op 'cos)
          (if (list? arg)
              `(* ,(derivative arg) (- (sin ,arg)))
              `(- (sin ,arg))))
         ((eq? op 'ln)
          (if (list? arg)
              `(* ,(derivative arg) (/ 1 ,arg))
              `(/ 1 ,arg)))
         ((eq? op 'exp) `(* ,(derivative arg) (exp ,arg)))
         ((eq? op 'log)
          `(/ ,(derivative arg) ,arg))
         ((member op '(* + -))
          `(,op ,(derivative arg)))
         (else (cons op (derivative (cdr expr)))))))

    ;; Производная бинарных операций (*, +, -, expt, /)
    ((= (length expr) 3) 
     (let ((op (car expr))
           (arg1 (list-ref expr 1))
           (arg2 (list-ref expr 2)))
       (cond
         ;; Умножение
         ((eq? op '*)
          (cond 
            ((and (list? arg1) (list? arg2))
             `(+ (* ,(derivative arg1) ,arg2) (* ,arg1 ,(derivative arg2))))
            ((list? arg1)
             `(* ,(derivative arg1) ,arg2))
            ((list? arg2)
             `(* ,arg1 ,(derivative arg2)))
            ((number? arg1)
             `(* ,arg1 ,(derivative arg2)))
            ((number? arg2)
             `(* ,(derivative arg1) ,arg2))
            (else
             `(+ (* ,(derivative arg1) ,arg2) (* ,arg1 ,(derivative arg2))))))

         ;; Сложение
         ((eq? op '+)
          `(+ ,(derivative arg1) ,(derivative arg2)))

         ;; Вычитание
         ((eq? op '-)
          `(- ,(derivative arg1) ,(derivative arg2)))

         ;; Возведение в степень
         ((eq? op 'expt)
          (cond 
            ((and (number? arg1) (not (list? arg2)))
             `(* (expt ,arg1 ,arg2) (ln ,arg1)))
            ((and (number? arg2) (not (eq? arg1 'e)))
             `(* ,arg2 (expt ,arg1 ,(- arg2 1))))
            ((and (list? arg2) (eq? arg1 'e))
             `(* ,(derivative arg2) (expt e ,arg2)))
            ((and (list? arg2) (not (eq? arg1 'e)))
             `(* ,(derivative arg2) (expt ,arg1 ,arg2) (ln ,arg1)))
            (else `(expt e ,arg2))))
         ;; Деление
         ((eq? (car expr) '/) 
          `(/ (- (* ,(derivative (list-ref expr 1))
                    ,(list-ref expr 2)) (* ,(list-ref expr 1)
                                           ,(derivative
                                             (list-ref
                                              expr 2))))
              (expt ,(list-ref expr 2) 2))))))
                                                        
    ;; Рекурсия для выражений с большим количеством аргументов
    (else (cond ((eq? (car expr) '+) `(+ ,(derivative (list-ref expr 1)) ,(derivative
                                                                           `(+ ,@(cdr (cdr expr))))))
                ((eq? (car expr) '-) `(- ,(derivative (list-ref expr 1)) ,(derivative
                                                                           `(- ,@(cdr (cdr expr))))))
                ;; Everything's not Alright
                ((eq? (car expr) '*)
                 `(+
                   (* ,(derivative
                        `(* ,(list-ref expr 1)
                            ,(list-ref expr 2)))
                      ,@(cdddr expr))
                   (* ,(list-ref expr 1) ,(list-ref expr 2)
                      ,(derivative `(* ,@(cdddr expr))))))
                ((eq? (car expr) 'expt) `(,(derivative `(expt ,(list-ref expr 1) ,(cdr
                                                                                   (cdr expr))))))))))



; I met a traveller from an antique land,
; Who said - "Two vast and trunkless legs of stone
; Stand in the desert... Near them, on the sand,
; Half sunk a shattered visage lies, whose frown,
; And wrinkled lip, and sneer of cold command,
; Tell that its sculptor well those passions read
; Which yet survive, stamped on these lifeless things,
; The hand that mocked them, and the heart that fed;
; And on the pedestal, these words appear:
; My name is Ozymandias, King of Kings;
; Look on my Works, ye Mighty, and despair!
; Nothing beside remains. Round the decay
; Of that colossal Wreck, boundless and bare
; The lone and level sands stretch far away."


;;this is отчаяние


;; Stand in the ashes of a trillion dead souls and ask the ghosts if honor matters.
;; The silence is your answer

;;tests
(define the-tests
  (list (test (derivative 2) 0)
        (test (derivative 'x) 1)
        (test (derivative '(- x))  '(- 1))
        (test (derivative '(* 1 x))  '(* 1 1))
        (test (derivative '(* 10 x)) '(* 10 1))
        (test (derivative '(* -1 x))  '(* -1 1))
        (test (derivative '(* -4 x))  '(* -4 1))
        (test (derivative '(- (* 2 x) 3))  '(- (* 2 1) 0))
        (test (derivative '(- (* 2 a) a))  '(- (* 2 1) 1))
        (test (derivative '(expt 5 x))  '(* (expt 5 x) (ln 5)))
        (test (derivative '(expt x 10))  '(* 10 (expt x 9)))
        (test (derivative '(* 2 (expt a 5)))  '(* 2 (* 5 (expt a 4))))
        (test (derivative '(- (* 2 x) 3))  '(- (* 2 1) 0))
        (test (derivative '(expt x -2)) '(* -2 (expt x -3)))
        (test (derivative '(cos x)) '(- (sin x)))
        (test (derivative '(sin x)) '(cos x))
        (test (derivative '(expt e x)) '(expt e x))
        (test (derivative '(* 2 (expt e x))) '(* 2 (expt e x)))
        (test (derivative '(* 2 (expt e (* 2 x)))) '(* 2 (* (* 2 1) (expt e (* 2 x)))))
        (test (derivative '(ln x)) '(/ 1 x))
        (test (derivative '(* 3 (ln x))) '(* 3 (/ 1 x)))
        (test (derivative '(+ (expt x 3) (expt x 2))) '(+ (* 3 (expt x 2)) (* 2 (expt x 1))))
        (test (derivative '(expt 5 (expt x 2))) '(* (* 2 (expt x 1)) (expt 5 (expt x 2)) (ln 5)))
        (test (derivative '(/ 3 (* 2 (expt x 2)))) '(/ (- (* 0 (* 2 (expt x 2)))
                                                          (* 3 (* 2 (* 2 (expt x 1)))))
                                                       (expt (* 2 (expt x 2)) 2)))
        (test (derivative '(/ 3 x)) '(/ (- (* 0 x) (* 3 1)) (expt x 2)))
        (test (derivative '(* 2 (* (sin x) (cos x)))) '(* 2 (+ (* (cos x) (cos x))
                                                               (* (sin x) (- (sin x))))))
        (test (derivative '(* 2 (* (expt e x) (* (sin x) (cos x)))))
              '(* 2 (+ (* (expt e x) (* (sin x) (cos x)))
                       (* (expt e x) (+ (* (cos x) (cos x)) (* (sin x) (- (sin x))))))))
        (test (derivative '(cos (* 2 (expt x 2)))) '(* (* 2 (* 2 (expt x 1)))
                                                       (- (sin (* 2 (expt x 2))))))
        (test (derivative '(sin (ln (expt x 2)))) '(* (* (* 2 (expt x 1))
                                                         (/ 1 (expt x 2)))
                                                      (cos (ln (expt x 2)))))
        (test (derivative '(+ (sin (* 2 x)) (cos (* 2 (expt x 2))))) '(+
                                                                       (* (* 2 1) (cos (* 2 x)))
                                                                       (*
                                                                        (* 2 (* 2 (expt x 1)))
                                                                        (- (sin
                                                                            (* 2 (expt x 2)))))))
        (test (derivative '(* (sin (* 2 x)) (cos (* 2 (expt x 2))))) '(+
                                                                       (*
                                                                        (* (* 2 1) (cos (* 2 x)))
                                                                        (cos (* 2 (expt x 2))))
                                                                       (*
                                                                        (sin (* 2 x))
                                                                        (*
                                                                         (* 2 (* 2 (expt x 1)))
                                                                         (- (sin
                                                                             (* 2 (expt x 2))))))))
        (test (derivative '(+ (expt x 10) (sin x) (cos x) (expt 5 x))) '(+
                                                                         (* 10 (expt x 9))
                                                                         (+
                                                                          (cos x)
                                                                          (+ (- (sin x))
                                                                             (*
                                                                              (expt 5 x)
                                                                              (ln 5))))))
        (test (derivative '(* (expt x 10) (sin x) (cos x))) '(+
                                                              (* (* 10 (expt x 9)) ((sin x)
                                                                                    (cos x)))
                                                              (* (expt x 10) (* 1))))))
              
             
(run-tests the-tests)