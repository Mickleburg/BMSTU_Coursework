;1
(display "Problem 1\n\n")
(define-syntax trace
  (syntax-rules ()
    ((_ action)
     (begin
       (write 'action)
       (display " => ")
       (let ((x action))
         (write x)
         (newline)
         x)))))

(define (zip . xss)
  (if (or (null? xss)
          (null? (trace (car xss))))
      '()
      (cons (map car xss)
            (apply zip (map cdr (trace xss))))))
(zip '(1 2 3) '(one two three))

;2
(display "\nProblem 2\n\n")
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

;3
(display "\nProblem 3\n\n")

(define (ref data ind . el)
  (define (solve xs i x)
    (if (= i 0)
        (cons x xs)
        (cons (car xs) (solve (cdr xs) (- i 1) x))))
  (and
   (>= ind 0)
   (cond
     ((pair? data)
      (if (null? el)
          (and (< ind (length data)) (list-ref data ind))
          (and (<= ind (length data)) (solve data ind (car el)))))
     ((vector? data)
      (if (null? el)
          (and (< ind (vector-length data)) (vector-ref data ind))
          (let ((L (vector->list data)))
            (and
             (<= ind (length L))
             (let ((ans (list->vector (solve L ind (car el)))))
               ans)))))
     ((string? data)
      (if (null? el)
          (and (< ind (string-length data)) (string-ref data ind))
          (and
           (char? (car el))
           (let ((L (string->list data)))
             (and
              (<= ind (length L))
              (let ((ans (list->string (solve L ind (car el)))))
                ans)))))))))

(define tests-3
  (list
   (test (ref '(1 2 3) 1) 2)
   (test (ref #(1 2 3) 1) 2)
   (test (ref "123" 1) #\2)
   (test (ref "123" 3) #f)
   (test (ref '(1 2 3) 1 0) (1 0 2 3))
   (test (ref #(1 2 3) 1 0)  #(1 0 2 3))
   (test (ref #(1 2 3) 1 #\0) #(1 #\0 2 3))
   (test (ref "123" 1 #\0) "1023")
   (test (ref "123" 1 0) #f)
   (test (ref "123" 3 #\4) "1234")
   (test (ref "123" 5 #\4) #f)))

(run-tests tests-3)

;4
(display "\nProblem 4\n\n")

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
   (test (if->cond '(if a
               aa
       (if b
           bb
           (if c
               cc
           dd))))
         (cond (a aa) (b bb) (c cc) (else dd)))
   (test (if->cond '(if a
               aa
       (if b
           bb
           (if c
               cc))))
         (cond (a aa) (b bb) (c cc)))
   (test (if->cond '(if (> x 0)
               (display '+)
       (if (= x 0)
           (display 0)
           (display '-))))
         (cond ((> x 0) (display '+))
         ((= x 0) (display 0))
     (else (display '-))))
   (test (if->cond '(if (< d 0)
               (list)
       (if (= d 0)
           (list x)
           (list x1 x2))))
         (cond ((< d 0) (list))
         ((= d 0) (list x))
     (else (list x1 x2))))))

(run-tests tests-4)

;доп тесты
(display "\nDop tests\n\n")
(define counter
  (let ((n 0))
    (lambda ()
      (set! n (+ n 1))
      n)))

(+ (trace (counter))
   (trace (counter)))

(define counter-tests
  (list (test (counter) 3)
        (test (counter) 77) ; ошибка
        (test (counter) 5)))

(run-tests counter-tests)

