;;Unit-tests
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

;;Stream
;; Конструктор потока
(define (make-stream items . eos)
  (if (null? eos)
      (make-stream items #f)
      (list items (car eos))))
;; Запрос текущего символа
(define (peek stream)
  (if (null? (car stream))
      (cadr stream)
      (caar stream)))
;; Продвижение вперёд
(define (next stream)
  (let ((n (peek stream)))
    (if (not (null? (car stream)))
        (set-car! stream (cdr (car stream))))
    n))

;1
;;BNF
;; <str> ::= <substr> | <substr> <sep> <str>
;; <sep> ::= " " | " " <sep> | E
;; <substr> ::= <sign> <digits-zero> "/" <digits>
;; <sign> ::= "+" | "-" | E
;; <digits-zero> ::= <digit-zero> | <digit-zero> <digits-zero>
;; <digit-zero> ::= "0" | <digit>
;; <digit> ::= "1" | ... | "9"
;; <digits> ::= <digit> | <digit> <digits-zero>

(define (char->num x)
  (- (char->integer x) 48))

;; <sign> ::= "+" | "-" | E
(define (scan-sign s)
  (and
   (peek s)
   (if (or (equal? (peek s) #\+) (equal? (peek s) #\-))
       (next s)
       #\+)))

;; <digit> ::= "1" | ... | "9"
(define digit-char '(#\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9))

;; <digit-zero> ::= "0" | <digit>
(define (scan-digit-zero s)
  (and
   (or (equal? (peek s) #\0) (member (peek s) digit-char))
   (next s)))
    
;; <digits-zero> ::= <digit-zero> | <digit-zero> <digits-zero>
(define (scan-digits-zero s)
  (let scan ((rez '()) (el (scan-digit-zero s)))
    (if el
        (scan (cons el rez) (scan-digit-zero s))
        (and (not (null? rez)) (reverse rez)))))

(define (scan-slash s)
  (and
   (equal? (peek s) #\/)
   (next s)))

;; <digits> ::= <digit> | <digit> <digits-zero>
(define (scan-digits s)
  (let ((fir (and (member (peek s) digit-char ) (next s))))
    (and fir
         (let ((other (scan-digits-zero s)))
           (if other
               (cons fir other)
               (list fir))))))

(define (create-num xs)
  (let loop ((xxs xs) (rez 0))
    (if (null? (cdr xxs))
        (+ (* rez 10) (char->num (car xxs)))
        (loop (cdr xxs) (+ (* rez 10) (char->num (car xxs)))))))

(define (create-digit xs)
  (*
   (if (equal? (car xs) #\-) -1 1)
   (/
    (create-num (cadr xs))
    (create-num (caddr xs)))))
  

;; <substr> ::= <sign> <digits-zero> "/" <digits>
(define (scan-fraction s)
  (let ((sign (scan-sign s)))
    (and
     sign
     (let ((digits-zero (scan-digits-zero s)))
       (and
        digits-zero
        (let ((slash (scan-slash s)))
          (and
           slash
           (let ((digits (scan-digits s)))
             (and
              digits
              (create-digit (list sign digits-zero digits)))))))))))

;; <sep> ::= " " | " " <sep> | E
(define (scan-seps s)
  (define (scan-sep s)
    (and (char-whitespace? (peek s)) (next s)))
  (let loop ()
    (if (not (scan-sep s))
        s
        (loop))))

;; <str> ::= <substr> | <substr> <sep> <str>
(define (scan-fractions s)
  (let loop ((rez '()) (num (scan-fraction (scan-seps s))))
    (and
     num
     (if (peek s)
         (loop (cons num rez) (scan-fraction (scan-seps s)))
         (reverse (cons num rez))))))
      

(define (scan-frac substr)
  (let* ((s (make-stream (string->list substr)))
         (num (scan-fraction s)))
    (and
     (not (peek s))
     num)))
(define (scan-many-fracs str)
  (scan-fractions (make-stream (string->list str))))
(define (valid-frac? substr)
  (if (scan-frac substr) #t #f))
(define (valid-many-fracs? str)
  (if (scan-many-fracs str) #t #f))

(define the-tests
  (list (test (scan-frac "110/111") 110/111)
        (test (scan-frac "-4/3") -4/3)
        (test (scan-frac "+5/10") 1/2)
        (test (scan-frac "5.0/10") #f)
        (test (scan-frac "FF/10") #f)
        (test (scan-many-fracs "\t1/2 1/3\n\n10/8") (1/2 1/3 5/4))
        (test (scan-many-fracs "\t1/2 1/3\n\n2/-5") #f)
        (test (scan-many-fracs "+1/2-3/4") (1/2 -3/4))
        (test (valid-frac? "110/111") #t)
        (test (valid-frac? "-4/3") #t)
        (test (valid-frac? "+5/10") #t)
        (test (valid-frac? "5.0/10") #f)
        (test (valid-frac? "FF/10") #f)
        (test (valid-many-fracs? "\t1/2 1/3\n\n10/8") #t)
        (test (valid-many-fracs? "\t1/2 1/3\n\n2/-5") #f)
        (test (valid-many-fracs? "+1/2-3/4") #t)))

(run-tests the-tests)

;;2
;; BNF:
;; <Program>  ::= <Articles> <Body> .
;; <Articles> ::= <Article> <Articles> | .
;; <Article>  ::= define word <Body> end .
;; <Body>     ::= if <Body> endif <Body>
;;              | while <Body> do <Body> wend <Body>
;;              | integer <Body> | word <Body> | .

(define define-words '())
(define (semantic-verification s)
  (let loop ((word (peek s))
             (prog (car s)))
    (if (null? (cdr prog))
        (or (number? word) (member word define-words))
        (begin
          
          ;; проверка на то, что слово определено
          (if (not (or (number? word) (member word define-words)))
              ;;сообщение об ошибке
              (begin
                (newline)
                (write word)
                (display ": undefined;")
                (newline)))
          
          (and (or (number? word) (member word define-words)) (loop (car prog) (cdr prog)))))))

(define default-name (list 'define 'end 'if 'endif 'while 'do 'wend))
(define (name? word)
  (and (symbol? word) (not (member word default-name))))

;; <Body>     ::= if <Body> endif <Body>
;;              | while <Body> do <Body> wend <Body>
;;              | integer <Body> | word <Body> | .
(define (parse-body s)
  (cond
    
    ((equal? (peek s) 'if)
     (let* ((get-if (next s))
            (body-1 (parse-body s))
            (get-endif (and body-1 (equal? (peek s) 'endif) (next s)))
            (body-2 (and get-endif (parse-body s))))
       (and body-2 (cons (list 'if body-1) body-2))))
    
    ((equal? (peek s) 'while)
     (let* ((get-while (next s))
            (body-1 (parse-body s))
            (get-do (and body-1 (equal? (peek s) 'do) (next s)))
            (body-2 (and get-do (parse-body s)))
            (get-wend (and body-2 (equal? (peek s) 'wend) (next s)))
            (body-3 (and get-wend (parse-body s))))
       (and body-3 (cons (list 'while body-1 body-2) body-3))))
    
    ((number? (peek s))
     (let* ((x (next s))
            (body (parse-body s)))
       (and body (cons x body))))
    
    ((and (not (member (peek s) default-name)) (peek s))
     (let* ((get-word (next s))
            (body (parse-body s)))
       (and body (cons get-word body))))
    
    (else '())))

;; <Article>  ::= define word <Body> end .
(define (parse-article s)
  (let* ((get-define (next s))
         (get-name (and (name? (peek s)) (next s)))
         (body (and get-name (parse-body s)))
         (get-end (and body (equal? (peek s) 'end) (next s))))
    ;;добавление нового слова
    (and get-end (set! define-words (cons get-name define-words)))
    (and get-end (list get-name body))))
         

;; <Articles> ::= <Article> <Articles> | .
(define (parse-articles s)
  (if (equal? (peek s) 'define)
      (let* ((first (parse-article s))
             (second (and first (parse-articles s))))
        (and first second (cons first second)))
      '()))

;; <Program>  ::= <Articles> <Body> .
(define (parse-program s)
  (begin
    (set!
     define-words
     (list '+ '- '* '/ 'mod 'neg
           '= '> '<
           'not 'and 'or
           'drop 'swap 'dup 'over 'rot 'depth
           'if 'endif 'while 'do 'wend
           'exit 'x))
    (let* ((articles (parse-articles s))
           ;; flag - результат семантической проверки
           (flag (and articles (semantic-verification s)))
           (body (and flag (parse-body s))))
      (and body (list articles body)))))
  

(define (parse s) (parse-program (make-stream (vector->list s))))
(define (valid? s) (if (parse s) #t #f))

;;Тестирование
(define the-tests-2
  (list (test (parse #(1 2 +))
              (() (1 2 +)))
        (test (parse #(x dup 0 swap if drop -1 endif))
              (() (x dup 0 swap (if (drop -1)))))
        ;; добавил wend и 1, чтобы разбор проходил корректно
        (test (parse #(1 x dup while dup 0 > do 1 - swap over * swap wend))
              (() (1 x dup (while (dup 0 >) (1 - swap over * swap)))))
        (test (parse #( define -- 1 - end
                         define =0? dup 0 = end
                         define =1? dup 1 = end
                         define factorial
                         =0? if drop 1 exit endif
                         =1? if drop 1 exit endif
                         1 swap
                         while dup 0 > do
                         1 - swap over * swap
                         wend
                         drop
                         end
                         0 factorial
                         1 factorial
                         2 factorial
                         3 factorial
                         4 factorial ))
              ;; добавил скобку в нужном месте и убрал в ненужном
              (((-- (1 -))
                (=0? (dup 0 =))
                (=1? (dup 1 =))
                (factorial
                 (=0? (if (drop 1 exit)) =1? (if (drop 1 exit))
                      1 swap (while (dup 0 >) (1 - swap over * swap)) drop)))
               (0 factorial 1 factorial 2 factorial 3 factorial 4 factorial)))
        (test (parse #(define word w1 w2 w3))
              #f)
        (test (valid? #(1 2 +)) #t)
        (test (valid? #(define 1 2 end)) #f)
        (test (valid? #(define x if end endif)) #f)))

(run-tests the-tests-2)

(define my-test
  (list (test (parse #(while cond do  1 2 3 the-action wend))
              #f)
        (test (parse #(define cond dup 0 > end
                        define the-action 100 swap end
                        while cond do  1 2 3 the-action wend))
              (((cond (dup 0 >)) (the-action (100 swap))) ((while (cond) (1 2 3 the-action)))))
        (test (parse #(if if if if act endif endif endif endif))
              #f)
        (test (parse #(define act 666 end if if if if act endif endif endif endif))
              (((act (666))) ((if ((if ((if ((if (act)))))))))))))

(run-tests my-test)