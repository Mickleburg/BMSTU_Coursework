(define the-void (if #f #f))

(define (print expr)
  (if (not (equal? expr the-void))
      (begin
        (write expr)
        (newline))))

(define (REPL)
  (let* ((e (read))                                    ; read
         (r (eval e (interaction-environment)))        ; eval
         (_ (print r)))                                ; print
     (REPL)))


(define (REPL)
  (let* ((e (read)))                                   ; read
    (if (not (eof-object? e))
        (let* ((r (eval e (interaction-environment)))  ; eval
               (_ (print r)))                          ; print
          (REPL)))))                                   ; loop
