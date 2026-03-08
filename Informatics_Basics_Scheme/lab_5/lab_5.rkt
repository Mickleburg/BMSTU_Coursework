;unit-tests 
(define-syntax test
  (syntax-rules ()
    ((test proc rez) '(proc rez))))

(define (run-test test)
  (write (car test))
  (let ((cur_rez (eval (car test) (interaction-environment)))
        (good_rez (cadr test)))
    (if (equal? cur_rez good_rez)
        (begin
          (display "ok\n")
          #t)      
        (begin
          (display "FAIL\n")
          (display "  Expected:")
          (write good_rez)
          (newline)
          (display "  Returned:")
          (write cur_rez)
          (newline)
          #f))))

(define (run-tests tests)
  (if (null? (cdr tests))
      (run-test (car tests))
      ((lambda (x y)
         (and x y))
       (run-test (car tests))
       (run-tests (cdr tests)))))

;ineterpret
(define (interpret program stack)
  ;процедура, возвращающая индекс певрого слова, следующего за статьёй
  (define (get-ind-define i)
    (if (equal? (vector-ref program i) 'end)
        (+ i 1)
        (get-ind-define (+ i 1))))
  ;процедура, возвращающая инлекс первого слова, следующего за условной конструкцией if
  (define (get-ind-if i)
    (if (equal? (vector-ref program i) 'endif)
        (+ i 1)
        (get-ind-if (+ i 1))))
  ;цикл интерпретатора
  (let cycle ((i 0) (data-stack stack) (return-stack '()) (dictionary '()))
    (if (= (vector-length program) i)
        data-stack
        (let ((word (vector-ref program i)))
          (cond
            ;слово - число
            ((number? word) (cycle (+ i 1) (cons word data-stack) return-stack dictionary))
            ;арифметические операции
            ((equal? word '+) (cycle (+ i 1) (cons (+ (cadr data-stack) (car data-stack)) (cddr data-stack)) return-stack dictionary))
            ((equal? word '-) (cycle (+ i 1) (cons (- (cadr data-stack) (car data-stack)) (cddr data-stack)) return-stack dictionary))
            ((equal? word '*) (cycle (+ i 1) (cons (* (cadr data-stack) (car data-stack)) (cddr data-stack)) return-stack dictionary))
            ((equal? word '/) (cycle (+ i 1) (cons (/ (cadr data-stack) (car data-stack)) (cddr data-stack)) return-stack dictionary))
            ((equal? word 'mod) (cycle (+ i 1) (cons (remainder (cadr data-stack) (car data-stack)) (cddr data-stack)) return-stack dictionary))
            ((equal? word 'neg) (cycle (+ i 1) (cons (* -1 (car data-stack)) (cdr data-stack)) return-stack dictionary))
            ;операции сравнения
            ((equal? word '=) (cycle (+ i 1) (cons (if (= (cadr data-stack) (car data-stack)) -1 0) (cddr data-stack)) return-stack dictionary))
            ((equal? word '>) (cycle (+ i 1) (cons (if (> (cadr data-stack) (car data-stack)) -1 0) (cddr data-stack)) return-stack dictionary))
            ((equal? word '<) (cycle (+ i 1) (cons (if (< (cadr data-stack) (car data-stack)) -1 0) (cddr data-stack)) return-stack dictionary))
            ;логические операци
            ((equal? word 'not) (cycle (+ i 1) (cons (not (car data-stack)) (cdr data-stack)) return-stack dictionary))
            ((equal? word 'and) (cycle (+ i 1) (cons (and (cadr data-stack) (car data-stack)) (cddr data-stack)) return-stack dictionary))
            ((equal? word 'or) (cycle (+ i 1) (cons (or (cadr data-stack) (car data-stack)) (cddr data-stack)) return-stack dictionary))
            ;операции со стеком
            ((equal? word 'drop) (cycle (+ i 1) (cdr data-stack) return-stack dictionary))
            ((equal? word 'swap) (cycle (+ i 1) (cons (cadr data-stack) (cons (car data-stack) (cddr data-stack))) return-stack dictionary))
            ((equal? word 'dup) (cycle (+ i 1) (cons (car data-stack) data-stack) return-stack dictionary))
            ((equal? word 'over) (cycle (+ i 1) (cons (cadr data-stack) data-stack) return-stack dictionary))
            ((equal? word 'rot) (cycle (+ i 1) (cons (caddr data-stack) (cons (cadr data-stack) (cons (car data-stack) (cdddr data-stack)))) return-stack dictionary))
            ((equal? word 'depth) (cycle (+ i 1) (cons (length data-stack) data-stack) return-stack dictionary))
            ;управляющие конструкции
            ((equal? word 'define) (cycle (get-ind-define (+ i 1)) data-stack return-stack (cons (list (vector-ref program (+ i 1)) (+ i 2)) dictionary)))
            ((equal? word 'end) (cycle (car return-stack) data-stack (cdr return-stack) dictionary))
            ((equal? word 'exit) (cycle (car return-stack) data-stack (cdr return-stack) dictionary))
            ((equal? word 'if) (cycle (if (equal? (car data-stack) 0) (get-ind-if (+ i 1)) (+ i 1)) (cdr data-stack) return-stack dictionary))
            ((equal? word 'endif) (cycle (+ i 1) data-stack return-stack dictionary))
            ;слово - определение статьи
            (else (cycle (cadr (assoc word dictionary)) data-stack (cons (+ i 1) return-stack) dictionary)))))))

;start tests 1
(define the-tests-1
  (list (test (interpret #(2 3 * 4 5 * +)
                         (quote ()))
              (26))
        (test (interpret #(10 3 mod neg +)
                         '(1))
              (0))))

(run-tests the-tests-1)

;start tests 2
(define the-tests-2
  (list (test (interpret #(   define abs
                               dup 0 <
                               if neg endif
                               end
                               9 abs
                               -9 abs      ) (quote ()))
              (9 9))
        (test (interpret #(   define =0? dup 0 = end
                               define <0? dup 0 < end
                               define signum
                               =0? if exit endif
                               <0? if drop -1 exit endif
                               drop
                               1
                               end
                               0 signum
                               -5 signum
                               10 signum       ) (quote ()))
              (1 -1 0))
        (test (interpret #(   define -- 1 - end
                               define =0? dup 0 = end
                               define =1? dup 1 = end
                               define factorial
                               =0? if drop 1 exit endif
                               =1? if drop 1 exit endif
                               dup --
                               factorial
                               *
                               end
                               0 factorial
                               1 factorial
                               2 factorial
                               3 factorial
                               4 factorial     ) (quote ()))
              (24 6 2 1 1))
        (test (interpret #(   define =0? dup 0 = end
                               define =1? dup 1 = end
                               define -- 1 - end
                               define fib
                               =0? if drop 0 exit endif
                               =1? if drop 1 exit endif
                               -- dup
                               -- fib
                               swap fib
                               +
                               end
                               define make-fib
                               dup 0 < if drop exit endif
                               dup fib
                               swap --
                               make-fib
                               end
                               10 make-fib     ) (quote ()))
              (0 1 1 2 3 5 8 13 21 34 55))
        (test (interpret #(   define =0? dup 0 = end
                               define gcd
                               =0? if drop exit endif
                               swap over mod
                               gcd
                               end
                               90 99 gcd
                               234 8100 gcd    ) '())
              (18 9))))

(run-tests the-tests-2)