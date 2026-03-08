(define (last xs)
  (define (helper xs-s)
    (if (null? (cdr xs-s))
        xs-s
        (helper (cdr xs-s))))
  (helper xs))

(define (cut-last! xs)
  (define (cut-helper xs acc)
    (if (null? (cdr xs)) 
        acc 
        (cut-helper (cdr xs) (cons (car xs) acc))))
  (reverse (cut-helper xs '())))


(define (mul . args)
  (if (null? args)
      1 
      (let loop ((lst args) (result 1))
        (cond
          ((null? lst) result)
          ((= (car lst) 0) 0)
          (else (loop (cdr lst) (* result (car lst))))))))

(define (рrореr-rес? lst)
  (define (atom? x)
    (not (or (list? x) (pair? x))))
  (cond
    ((null? lst) #t)
    ((not (list? lst)) #f)  
    ((and (pair? lst) (null? (cdr lst))) #t)   
    ((pair? lst)
     (let ((first (car lst))
           (rest (cdr lst)))
       (list? rest)
       (and (or (atom? first)(рrореr-rес? first))
            (and (list? rest)(рrореr-rес? rest)))))
    (else #f)))



(define (sdvig lst)
  (if (null? lst)
      '()
      (let ((last (car (reverse lst)))
            (xs (reverse (cdr (reverse lst)))))
        (cons last xs))))

(sdvig '(a b c d e))

