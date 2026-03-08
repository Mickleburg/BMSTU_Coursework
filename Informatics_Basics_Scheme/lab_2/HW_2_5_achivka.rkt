(define (list-trim-right xs)
  (let solv ((ind-end
              (let get-ind ((sp xs)
                            (ind-individ 0)
                            (ind-off 0))
                (cond
                  ((null? sp) (- ind-off 1))
                  ((char-whitespace? (car sp)) (get-ind
                                                (cdr sp)
                                                (+ ind-individ 1)
                                                ind-off))
                  (else (get-ind
                         (cdr sp)
                         (+ ind-individ 1)
                         (+ ind-individ 1))))))
             (sp xs)
             (ind 0))
    (cond
      ((null? sp) '())
      ((< ind ind-end) (cons (car sp) (solv ind-end (cdr sp) (+ ind 1))))
      (else (cons (car sp) '())))))
#|
Cложность основного алгоритма - O(n), для нахождения ind-end я использую
хвостовую рекурсию, сложность которой также O(n). Значит, итоговая сложность O(2n),
что эквивалентно O(n) ~ O(len(xs))
|#
;(list-trim-right '(#\1 #\2 #\3 #\return #\space #\f #\tab #\newline))  ; (#\1 #\2 #\3 #\return #\space #\f)
;(list-trim-right '(#\newline #\3))  ; (#\newline #\3)
;(list-trim-right '())  ; ()