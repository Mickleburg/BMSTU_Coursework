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
