(define (my-gcd a b)
  (if (= b 0)
      (abs a)
      (my-gcd b (remainder a b))))

(define (my-lcm a b)
  (/ (* a b) (my-gcd a b)))

(define (prime? n)
  (define (check x d)
    (if (= x d)
        #t
        (if (= (remainder x d) 0)
            #f
            (check x (+ d 1)))))
  (check n 2))

;(my-gcd 24 6) ;6
;(my-gcd 26 6) ;2
;(my-lcm 42 30) ;210
;(prime? 100) ;#t
;(prime? 97) ;#f