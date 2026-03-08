;1
(define call/cc call-with-current-continuation)

(define state #f)

(define-syntax use-assertions
  (syntax-rules ()
    ((use-assertions)
     (call/cc
      (lambda (st)
        (set! state st))))))

(define-syntax assert
  (syntax-rules ()
    ((assert condition)
     (if (not (eval condition (interaction-environment)))
         (begin
           (display "FAILED: ")
           (write 'condition)
           (state))
         #t))))

(use-assertions) ; Инициализация вашего каркаса перед использованием

(define (1/x x)
  (assert (not (zero? x))) ; Утверждение: x ДОЛЖЕН БЫТЬ ≠ 0
  (/ 1 x))

(map 1/x '(1 2 3 4 5)) ; ВЕРНЕТ список значений в программу

(map 1/x '(-2 -1 0 1 2)) ; ВЫВЕДЕТ в консоль сообщение и завершит работу программы

;3
(newline)

(define (trib t)
  (if (<= t 1)
      0
      (if (= t 2)
          1
          (+ (trib (- t 1)) (trib (- t 2)) (trib (- t 3))))))

(define (trib-memo t)
  (let ((known-results '()))
    (let helper((n t))
      (let ((res (assoc n known-results)))
        (if res
            (cadr res)
            (let ((get-res (if (<= n 1)
                               0
                               (if (= n 2)
                                   1
                                   (+
                                    (helper (- n 1))
                                    (helper (- n 2))
                                    (helper (- n 3)))))))
              (set! known-results (cons (list n get-res) known-results))
              get-res))))))
(trib 10)
(trib-memo 10)

;4
(newline)
(define-syntax lazy-cons
  (syntax-rules ()
    ((lazy-cons a b) (cons a (delay b)))))

(define (lazy-car p)
  (car p))

(define (lazy-cdr p)
  (force (cdr p)))

(define (lazy-head xs k)
  (if (equal? k 0)
      '()
      (cons (lazy-car xs) (lazy-head (lazy-cdr xs) (- k 1)))))

(define (lazy-ref xs k)
  (if (equal? k 1)
      (lazy-car xs)
      (lazy-ref (lazy-cdr xs) (- k 1))))

(define (lazy-map proc xs)
  (if (null? xs)
      '()
      (lazy-cons (proc (lazy-car xs)) (lazy-map proc (lazy-cdr xs)))))

(define (lazy-zip xs ys)
  (if (or (null? xs) (null? ys))
      '()
      (lazy-cons (list (lazy-car xs) (lazy-car ys)) (lazy-zip (lazy-cdr xs) (lazy-cdr ys)))))

(define ones (lazy-cons 1 ones))
(lazy-head ones 5)  ; (1 1 1 1 1)

;2.3
(newline)

(define fibonacci
  (letrec ((fib-xs
            (lazy-cons
             1
             (lazy-cons
              1
              (lazy-map
               (lambda (xxs) (+ (car xxs) (cadr xxs)))
               (lazy-zip fib-xs (lazy-cdr fib-xs)))))))
    fib-xs))

(lazy-head fibonacci 10)
(lazy-ref fibonacci 10)
;2.1
;процедура работает, просто закомменчена для удобства
#|
(newline)

(define (proc-desugar source dest)
  (let ((in (open-input-file source))
        (out (open-output-file dest)))
    (let read-file ((block (read in)))
      (if (not (eof-object? block))
          (begin
            (write (desugar-machine block) out)
            (write-char #\newline out)
            (read-file (read in)))))
    (close-input-port in)
    (close-output-port out)))

(define (desugar-machine xs)
  (if (and (pair? xs) (eq? (car xs) 'define) (pair? (cadr xs)) (symbol? (caadr xs)))
      `(define ,(caadr xs) (lambda ,(cdadr xs) ,@(cddr xs)))
      xs))

(proc-desugar "input.rkt" "output.rkt")
|#
;2.2
(newline)

(define (counter-line path)
  (let* ((file (open-input-file path))
         (k (let read-symbol ((sym (read-char file))
                              (not-empty #f))
              (if (eof-object? sym)
                  0
                  (if (equal? sym #\newline)
                      (if not-empty
                          (+ 1 (read-symbol (read-char file) #f))
                          (read-symbol (read-char file) #f))
                      (if (not (char-whitespace? sym))
                          (read-symbol (read-char file) #t)
                          (read-symbol (read-char file) not-empty)))))))
    (close-input-port file)
    k))

(counter-line "input.rkt")

;2.4
(newline)

(define-syntax when
  (syntax-rules ()
    ((when cond? act)
     (and cond? act))
    ((when cond? act . actions)
     (begin
       (and cond? act)
       (when cond? . actions)))))

(define x 1)
(when (> x 0) (display "x > 0") (newline) (write (+ 2 2)) (newline))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-syntax for
  (syntax-rules (in as)
    ((for i in xs . exprs)
     (let iter ((sp xs))
       (if (not (null? sp))
           (let ((i (car sp)))
             (begin
               (begin . exprs)
               (iter (cdr sp)))))))
    ((for xs as i . exprs)
     (for i in xs . exprs))))

(define-syntax for
  (syntax-rules (in as)
    ((for i in xs expr ...)
     (let iter ((sp xs))
       (if (not (null? sp))
           (let ((i (car sp)))
             
             expr ...
             
             (iter (cdr sp))))))
    ((for xs as i expr ...)
     (for i in xs expr ...))))

(for i in '(1 2 3)
  (display (list i 97)) (display " win\n"))
(for i in '(1 2 3)
  (for j in '(4 5 6)
    (display (list i j))
    (newline)))
(for '(1 2 3) as i
  (for '(4 5 6) as j
    (display (list i j))
    (newline)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(newline)
; способ 1
(define-syntax repeat
  (syntax-rules (until)
    ((repeat body until cond?)
     (let loop ()
       (begin
         (begin . body)
         (if (not cond?)
             (loop)))))))

(let ((i 0)
      (j 0))
  (repeat ((set! j 0)
           (repeat ((display (list i j))
                    (set! j (+ j 1)))
                   until (= j 3))
           (set! i (+ i 1))
           (newline))
          until (= i 3)))

(newline)
; способ 2
(define-syntax repeat
  (syntax-rules (until)
    ((repeat (exp ...) until cond?)
     (let loop ()
       (begin exp ... (if (not cond?) (loop)))))))

(let ((i 0)
      (j 0))
  (repeat ((set! j 0)
           (repeat ((display (list i j))
                    (set! j (+ j 1)))
                   until (= j 3))
           (set! i (+ i 1))
           (newline))
          until (= i 3)))
