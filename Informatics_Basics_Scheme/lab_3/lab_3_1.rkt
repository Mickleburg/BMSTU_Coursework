;1
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
