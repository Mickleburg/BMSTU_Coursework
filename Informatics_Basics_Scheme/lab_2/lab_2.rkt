(define (uniq xs)
  (cond
    ((null? xs) '())
    ((null? (cdr xs)) (cons (car xs) '()))
    ((equal? (car xs) (cadr xs)) (uniq (cdr xs)))
    (else (cons (car xs) (uniq (cdr xs))))
    )
  )

(define (delete pred? xs)
  (cond
    ((null? xs) '())
    ((pred? (car xs)) (delete pred? (cdr xs)))
    (else (cons (car xs) (delete pred? (cdr xs))))
    )
  )

(define (polynom xs x0)
  (define (solve xs n)
    (cond
      ((null? xs) 0)
      (else (+ (* (expt x0 n) (car xs))
               (solve (cdr xs) (- n 1)))
            )
      )
    )
  (solve xs (- (length xs) 1))
  )

(define (intersperse e xs)
  (cond
    ((null? xs) '())
    ((null? (cdr xs)) xs)
    (else (append
           (cons (car xs) (list e))
           (intersperse e (cdr xs))
           )
          )
    )
  )

(define (all? pred? xs)
  (or (null? xs)
      (and (pred? (car xs)) (all? pred? (cdr xs)))
      )
  )



(define (f x) (+ x 2))
(define (g x) (* x 3))
(define (h x) (- x))

(define (o . proc)
  (lambda (x)
    (let solve ((xs (reverse proc))
                (res x))
      (if (null? xs)
          res
          (solve (cdr xs) ((car xs) res))
          )
      )
    )
  )
