(define (merge-sort less? xs)
  (cond
    ((null? xs) '())
    ((null? (cdr xs)) xs)
    (else
     (let sort ((xxs (let get-split ((last-el (car xs));распознаю неубывающие подпоследовательности
                                     (xs (cdr xs))
                                     (rez (list (list (car xs)))))
                       (cond
                         ((null? xs) rez)
                         ((less? (car xs) last-el) (get-split
                                                    (car xs)
                                                    (cdr xs)
                                                    (cons (list (car xs)) rez)))
                         (else (get-split
                                (car xs)
                                (cdr xs)
                                (cons (append (car rez) (list (car xs))) (cdr rez))))))))
       (if (null? (cdr xxs))
           (car xxs)
           (sort (let step ((xs xxs))  ; хвостовая рекурсия
                   (cond
                     ((null? xs) '())
                     ((null? (cdr xs)) xs)
                     (else (cons (let merge ((rez '()) (xs-1 (car xs)) (xs-2 (cadr xs)))
                                   (cond
                                     ((null? xs-1) (append rez xs-2))
                                     ((null? xs-2) (append rez xs-1))
                                     ((less? (car xs-1) (car xs-2)) (merge
                                                                     (append rez (list (car xs-1)))
                                                                     (cdr xs-1) xs-2))
                                     (else (merge (append rez (list (car xs-2))) xs-1 (cdr xs-2)))))
                                 (step (cddr xs))))))))))))
