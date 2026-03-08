;1
(define (my-range a b d)
  (if (< (+ a d) b)
      (cons a (my-range (+ a d) b d))
      (if (< a b)
          (cons a '())
          '())))

;O(n)
;(my-range 0 13 3)
;(my-range 0 3 3)
;(my-range 0 0 3)

;2
(define (my-flatten xs)
  (define (atom? el)
    (not (or (pair? el) (list? el))))
  (define (flatten xxs rez)
    (if (null? xxs)
        rez
        (let ((first (car xxs))
              (second (cdr xxs)))
          (if (atom? first)
              (flatten second (cons first rez))
              (flatten second (flatten first rez))))))
  (reverse (flatten xs '())))

;O(n)
;(my-flatten '(1 2 (6 5)))
;(my-flatten '(() 3 4 (12) 9 (((9)))))
;(my-flatten '((9 9) 8 () 7))

;3
(define (my-element? x xs)
  (and
   (not (null? xs))
   (or
    (equal? (car xs) x)
    (my-element? x (cdr xs)))))

;O(n)
;(my-element? 1 '(3 2 1))
;(my-element? 4 '(3 2 1))

;4
(define (my-filter pred? xs)
  (cond
    ((null? xs) '())
    ((pred? (car xs)) (cons (car xs) (my-filter pred? (cdr xs))))
    (else (my-filter pred? (cdr xs)))))

;O(n)
;(my-filter odd? '(1 2 3 4 5 6 7 8 9 10))
;(my-filter (lambda (x) (= (remainder x 3) 0)) (my-range 0 13 1))

;5
(define (my-fold-left op xs)
  (cond
    ((null? xs) '())
    ((null? (cdr xs)) (car xs))
    ((null? (cdr (cdr xs))) (op (car xs) (car (cdr xs))))
    (else (my-fold-left op (cons (op (car xs) (car (cdr xs))) (cdr (cdr xs)))))))

;O(n)
;(my-fold-left  quotient '(16 2 2 2 2))
;(my-fold-left  quotient '(1))

;6
(define (my-fold-right op xs)
  (define (solver op xs)
    (cond
      ((null? xs) '())
      ((null? (cdr xs)) (car xs))
      ((null? (cdr (cdr xs))) (op (car (cdr xs)) (car xs)))
      (else (solver op (cons (op (car (cdr xs)) (car xs)) (cdr (cdr xs)))))))
  (solver op (reverse xs)))

;O(n)
;(my-fold-right expt '(2 3 4))  ; 2417851639229258349412352
;(my-fold-right expt '(2))

;7
(define (reverse! xs)
  (define (solver xs acc)
    (cond
      ((null? xs) '())
      ((null? (cdr xs)) (cons (car xs) acc))
      (else (solver (cdr xs) (cons (car xs) acc)))))
  (solver xs '()))

;O(n)
;(reverse! '(a b c d e))
;(reverse! '())

;8
(define (append! . xs-xs)
  (define (solver xs ys)
  (if (null? xs)
      ys
      (begin
        (let ((last (cdr xs)))
          (if (null? last)
              (set-cdr! xs ys)
              (solver last ys)))
        xs)))
  (define (many-solver xxs-xxs rez)
    (if (null? xxs-xxs)
        rez
        (many-solver (cdr xxs-xxs) (solver rez (car xxs-xxs)))))
  (cond
    ((null? xs-xs) '())
    ((null? (cdr xs-xs)) (car xs-xs))
    (else (many-solver (cdr (cdr xs-xs)) (solver (car xs-xs) (car (cdr xs-xs)))))))

;O(n^2)
;(append! '(a b c) '() '(d e f) '(g))
;(define xs '(1 2 3))
;(define ys '(4 5 6))
;(define zs (append! xs ys))
;(write zs)
;(newline)
;(append!)
