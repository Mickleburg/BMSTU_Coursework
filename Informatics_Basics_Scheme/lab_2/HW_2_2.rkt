;1
(define (list->set xs)
  (cond
   ((null? xs) '())
   ((null? (cdr xs)) (cons (car xs) '()))
   ((list? (member (car xs) (cdr xs))) (list->set (cdr xs)))
   (else (cons (car xs) (list->set (cdr xs))))))

;O(n^2)
;(list->set '(1 2 3 3 3 2 1))  ; (3 2 1)
;(list->set '(2))  ; (2)
;(list->set '())  ; ()

;2
(define (set? xs)
  (cond
    ((null? xs) #t)
    ((null? (cdr xs)) #t)
    ((list? (member (car xs) (cdr xs))) #f)
    (else (set? (cdr xs)))))

;O(n^2)
;(set? '(1 2 3))  ;  #t
;(set? '(1 2 3 3))  ; #f
;(set? '())  ; #t

;3
(define (union xs ys)
  (cond
    ((null? xs) ys)
    ((list? (member (car xs) ys)) (union (cdr xs) ys))
    (else (cons (car xs) (union (cdr xs) ys)))))

;O(n^2)
;(union '(1 2 3) '(2 3 4))  ; (1 2 3 4)
;(union '(a) '())  ; (a)
;(union '() '())  ; ()

;4
(define (intersection xs ys)
  (cond
    ((null? xs) '())
    ((list? (member (car xs) ys)) (cons (car xs) (intersection (cdr xs) ys)))
    (else (intersection (cdr xs) ys))))

;O(n^2)
;(intersection '(1 2 3) '(2 3 4))  ; (2 3)
;(intersection '(1 2 3) '(4 5 6)) ; ()
;(intersection '() '())  ; ()

;5
(define (difference xs ys)
  (cond
    ((null? xs) '())
    ((list? (member (car xs) ys)) (difference (cdr xs) ys))
    (else (cons (car xs) (difference (cdr xs) ys)))))

;O(n^2)
;(difference '(1 2 3 4 5) '(2 3))  ; (1 4 5)
;(difference '(1 2 3) '(4 5 6))  ; (1 2 3)
;(difference '() '())  ; ()

;6
(define (symmetric-difference xs ys)
  (append (difference xs ys) (difference ys xs)))

;O(n^2)
;(symmetric-difference '(1 2 3 4) '(3 4 5 6))  ; (1 2 5 6)
;(symmetric-difference '(1 2) '(3 4 5 6))  ; (1 2 3 4 5 6)
;(symmetric-difference '() '())  ; ()

;7
(define (set-eq? xs ys)
  (and
   (equal? (length xs) (length ys))
   (let set-equal? ((fir xs) (sec ys))
     (or
      (null? fir)
      (and
       (list? (member (car fir) sec))
       (set-equal? (cdr fir) sec))))))

;O(n^2)
;(set-eq? '(1 2 3) '(1 2 3 4))  ; #f
;(set-eq? '(1 2 3) '(3 2 1)) ; #t
;(set-eq? '(1 2) '(1 3))  ; #f