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

;; Лексический анализатор
(define (delit-sep xs)
  (let loop ((rez xs))
    (if (and (not (null? rez)) (char-whitespace? (car rez)))
        (loop (cdr rez))
        rez)))

(define (dig? sym)
  (and sym (>= (char->integer sym) (char->integer #\0))
       (<= (char->integer sym) (char->integer #\9))))
(define (letter? sym)
  (and sym (or
            (and (>= (char->integer sym) (char->integer #\a))
                 (<= (char->integer sym) (char->integer #\z)))
            (and (>= (char->integer sym) (char->integer #\A))
                 (<= (char->integer sym) (char->integer #\Z))))))
(define (valid-end-num? sym)
  (or (not sym) (char-whitespace? sym) (op? sym) (equal? sym #\))))
(define (op? sym)
  (and sym (member sym (list #\+ #\- #\* #\/ #\^))))

(define (scan-Op s)
  (and (op? (peek s)) (string->symbol (list->string (list (next s))))))

(define (scan-Seps s)
  (define (scan-sep s)
    (and (peek s) (char-whitespace? (peek s)) (next s)))
  (let loop ()
    (if (not (scan-sep s))
        s
        (loop))))

(define (scan-Digs s)
  (let loop ((rez '()))
    (or
     (and (dig? (peek s)) (loop (cons (next s) rez)))
     (and (valid-end-num? (peek s)) rez))))

(define (scan-DigsM s)
  (if (equal? (peek s) #\-)
      (let* ((minus (next s))
             (dig (and (dig? (peek s)) (next s)))
             (Digs (scan-Digs s)))
        (and Digs (append Digs (list dig minus))))
      (let* ((dig (and (dig? (peek s)) (next s)))
             (Digs (and dig (scan-Digs s))))
        (and Digs (append Digs (list dig))))))

(define (scan-NumP s)
  (let loop ((rez '()))
    (or
     (and (dig? (peek s)) (loop (cons (next s) rez)))
     (and (equal? (peek s) #\e)
          (let* ((exp (next s))(tokenize "-a + b * x^2 + dy")
                 (DigsM (scan-DigsM s)))
            (and DigsM (append DigsM (list exp) rez))))
     (and (valid-end-num? (peek s)) rez))))

(define (scan-Numd s)
  (let loop ((rez '()) (c (peek s)))
    (or
     (and (dig? c) (loop (cons (next s) rez) (peek s)))
     (and (equal? c #\/)
          (let* ((slash (next s))
                 (Digs (scan-Digs s)))
            (and Digs (reverse (append Digs (list slash) rez)))))
     (and (equal? c #\e)
          (let* ((exp (next s))
                 (DigsM (scan-DigsM s)))
            (and DigsM (reverse (append DigsM (list exp) rez)))))
     (and (equal? c #\.)
          (let* ((point (next s))
                 (dig (and (dig? (peek s)) (next s)))
                 (NumP (and dig (scan-NumP s))))
            (and Nump (reverse (append Nump (list dig point) rez)))))
     (and (valid-end-num? c) (reverse rez)))))

(define (scan-Vard s)
  (let loop ((rez '()))
    (if (letter? (peek s))
        (loop (cons (next s) rez))
        (and
         (or (not (peek s)) (char-whitespace? (peek s)) (op? (peek s)) (equal? (peek s) #\)))
         (reverse rez)))))

(define (scan-Ent s)
         (or
          (and (letter? (peek s))
               (let* ((letter (next s))
                      (Vard (scan-Vard s)))
                 (and Vard (list (string->symbol (list->string (cons letter Vard)))))))  ;; Place
          (and (dig? (peek s))
               (let* ((dig (next s))
                      (Numd (scan-Numd s)))
                 (and Numd (list (string->number (list->string (cons dig Numd)))))))))  ;; Place

(define (scan-Obj s)
         (cond
           ((equal? (peek (scan-Seps s)) #\() (let ((br (next s))) (list "(")))
           ((equal? (peek s) #\)) (let ((br (next s))) (list ")")))
           ((op? (peek s)) (list (scan-Op s)))
           ((equal? (peek s) #\-)
            (let* ((minus (next s))
                   (Ent (scan-Ent (scan-Seps s))))
              (and Ent (cons '- Ent))))  ;; Place - ()
           (else (scan-Ent s))))  ;; Place ()

(define (scan-Expr s)
  (if (peek (scan-Seps s))
      (let* ((Obj (scan-Obj (scan-Seps s)))
             (Expr (and Obj (scan-Expr (scan-Seps s)))))
        (and Expr (append Obj Expr)))  ;; Place () ()
      '()))

;; BNF
;; Expr  ::= Seps Obj Seps Expr | E.
;; Seps  ::= " " Seps | E .
;; Obj   ::= ( | ) | Op | - Ent | Ent.
;; Op    ::= + | - | * | / | ^ .
;; Ent   ::= letter Vard | dig Numd .
;; Vard  ::= letter Vard | E .
;; Numd  ::= dig Numd | / Digs | e DigsM | . dig NumP | E .
;; NumP  ::= dig NumP | e DigsM | E .
;; DigsM ::= - dig Digs | dig Digs .
;; Digs  ::= dig Digs | E .
(define (tokenize str)
  (scan-Expr (make-stream (reverse (delit-sep (reverse (string->list str)))))))

#|
(tokenize "-a")
(tokenize "-a + b * x^2 + dy")
(tokenize "(a - 1)/(b + 1)")
(tokenize "a ^ a ^ a")
(tokenize "a ^ (b ^ c)")
(tokenize "(5 * (5+5)) ^ (b ^ ((3 ^ 4)*3))")
(tokenize "a/b/c/d")
(tokenize "a^b^c^d")
(tokenize "a/(b/c)")
(tokenize "a + b/c^2 - d")
(tokenize "1.2.3")
(tokenize "6.022e23 * 1.38e-23 is r")
(tokenize "1e2e3")
(tokenize "1e2.3")
(tokenize "!@#$%^&*()")
(tokenize "12x34 56y78")
(tokenize "12y34 56y78")
(tokenize "            ")
|#

;; Синтаксический анализатор
(define AddOp (list '+ '-))
(define MulOp (list '* '/))
(define PowOp (list '^))
(define OP (append AddOp MulOp PowOp))

(define (append-op xs rez)
  (if (null? rez)
      xs
      (let loop ((tree rez))
        (if (member (car tree) OP)
            (if (and (pair? xs) (null? (cdr xs)))
                (cons (car xs) tree)
                (cons xs tree))
            (cons (loop (car tree)) (cdr tree))))))

(define (parse-power s)
  (cond
    ((or (and (symbol? (peek s)) (not (equal? (peek s) '-))) (number? (peek s))) (next s)) ;; Place
    ((equal? (peek s) "(")
     (let* ((bracket-1 (next s))
            (Expr (parse-expr s))
            (bracket-2 (and Expr (equal? (peek s) ")") (next s))))

       (and bracket-2 Expr)))                             ;; Place
    ((equal? (peek s) '-)
     (let* ((unaryMinus (next s))
            (Power (parse-power s)))
       (and Power (list unaryMinus Power))))                 ;; Place
    (else #f)))

(define (parse-factord s)
  (cond
    ((member (peek s) PowOp)
     (let* ((Op (next s))
            (Power (and Op (parse-power s)))
            (FactorD (and Power (parse-factord s))))
       (and FactorD (if (null? FactorD)
                        (list Op Power)
                        (list Op (cons Power FactorD))))))  ;; Place
    (else '())))

(define (parse-factor s)
  (let* ((Power (parse-power s))
         (FactorD (and Power (parse-factord s))))
    (and FactorD (if (and (null? FactorD) (pair? Power)) Power (cons Power FactorD)))))  ;; Place XXX

(define (parse-termd s)
  (cond
    ((member (peek s) MulOp)
     (let* ((Op (next s))
            (Factor (and Op (parse-factor s)))
            (TermD (and Factor (parse-termd s))))
       (and TermD (append-op (if (null? (cdr Factor))
                                 (cons Op Factor)
                                 (list Op Factor))
                             TermD)))) ;; Place
    (else '())))

(define (parse-term s)
  (let* ((Factor (parse-factor s))
         (TermD (and Factor (parse-termd s))))
    (and Termd (append-op Factor TermD))))  ;; Place

(define (parse-exprd s)
  (cond
    ((member (peek s) AddOp)
     (let* ((Op (next s))
            (Term (and Op (parse-term s)))
            (ExprD (and Term (parse-exprd s))))
       (and ExprD (append-op (if (null? (cdr Term))
                                 (cons Op Term)
                                 (list Op Term))
                             ExprD)))) ;; Place
    (else '())))

(define (parse-expr s)
  (let* ((Term (parse-term s))
         (ExprD (and Term (parse-exprd s))))
    (and ExprD (append-op Term ExprD))))  ;; Place

;; Expr    ::= Term Expr' .
;; Expr'   ::= AddOp Term Expr' | .
;; Term    ::= Factor Term' .
;; Term'   ::= MulOp Factor Term' | .
;; Factor  ::= Power Factor' .
;; Factor' ::= PowOp Power Factor' | .
;; Power   ::= value | "(" Expr ")" | unaryMinus Power .
(define (parse tokens)
  (let* ((s (make-stream tokens))
         (rez (parse-expr s)))
    (and (not (peek s))
         (if (and rez (null? (cdr rez)))
             (car rez)
             rez))))

#|
(parse '("(" "(" "(" "(" 0 ")" ")" ")" ")"))
(parse '("(" "(" "(" "(" 1 + 1 ")" ")" ")" ")"))
(parse '(- a))
(parse '(1))
(parse '(a))
(parse '(a * "(" "(" b ")" + c ")"))
(parse '(a * "(" b + c ")"))
(parse '(- a + b * x ^ 2 + dy))
(display "TRESH\n")
(parse '(a * "(" b + c))
(parse '(a * b + c ")"))
(parse '(a * b + ))
(parse '(a * "(" b + + c ")"))
(parse '(* "(" b + + c ")"))
(parse '(a * "(" b + c ")" ")"))
(parse '(")" a + b "("))
(parse '("(" a + b ")" "(" c - d ")"))
(parse '(1 2))
(parse '(a 1))
(parse '())
(parse '("("))
(parse '(")"))
(parse '("(" ")"))
(parse (tokenize "a/b/c/d"))
(parse (tokenize "a+b+c+d"))
(parse (tokenize "a^b^c^d"))
(parse (tokenize "a/(b/c)"))
(parse (tokenize "a + b * c"))
(parse (tokenize "a + b / c ^ 2 - d"))
(parse (tokenize "x^(a + 1)"))
(parse (tokenize "-a"))
|#

;; Преобразователь дерева разбора в выражение на Scheme
(define (tree->scheme tree)
  (let loop ((tree tree))
    (if (not (pair? tree))
        tree
        (if (equal? (car tree) '-)
            (cons '- (loop (cdr tree)))
            (let ((fir (car tree)) (op (cadr tree)) (sec (caddr tree)))
              (if (not (equal? op '^))
                  (list op (loop fir) (loop sec))
                  (list 'expt (loop fir) (loop sec))))))))
#|
(tree->scheme (parse (tokenize "x^(a + 1)")))
(eval (tree->scheme (parse (tokenize "2^2^2^2")))
      (interaction-environment))
|#
