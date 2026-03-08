;1
(define (make-multi-vector sizes . fill)
  (let ((vec
         (if (null? fill)
             (make-vector (apply * sizes))
             (make-vector (apply * sizes) (car fill)))))
    (vector 'mvec sizes vec)))

;2
(define (multi-vector? m)
  (and (vector? m) (equal? 'mvec (car (vector->list m)))))

;3
(define (get-index index sizes)
  (let calc ((mn (apply * sizes))
             (divs sizes)
             (koefs index))
    (if (null? koefs)
        0
        (+ (calc (/ mn (car divs)) (cdr divs) (cdr koefs))
           (* (car koefs) (/ mn (car divs)))))))

(define (multi-vector-ref m indices)
  (let give-el ((xs (vector->list (car (cdr (cdr (vector->list m))))))
                (ind (get-index indices (car (cdr (vector->list m))))))
    (if (equal? ind 0)
        (car xs)
        (give-el (cdr xs) (- ind 1)))))

;4
(define (multi-vector-set! m indices x)
  (vector-set! (vector-ref m 2)
               (get-index indices (car (cdr (vector->list m))))
               x))

#|

(define m (make-multi-vector '(11 12 9 16)))
(multi-vector? m)  ; #t
(multi-vector-set! m '(10 7 6 12) 'test)
(multi-vector-ref m '(10 7 6 12))  ; test

(multi-vector-set! m '(1 2 1 1) 'X)
(multi-vector-set! m '(2 1 1 1) 'Y)
(multi-vector-ref m '(1 2 1 1))  ; X
(multi-vector-ref m '(2 1 1 1))  ; Y

(define m (make-multi-vector '(3 5 7) -1))
(multi-vector-ref m '(0 0 0)) ; -1
|#