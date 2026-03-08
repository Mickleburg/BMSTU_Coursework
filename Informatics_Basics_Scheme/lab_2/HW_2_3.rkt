;1
(define (string-trim-left st)
  (define (good? x)
    (and (not (equal? x #\tab)) (not (equal? x #\space))
         (not (equal? x #\newline)) (not (equal? x #\return))))
  (let* ((xs (string->list st))
         (xs_good
          (let del ((xxs xs))
            (cond
              ((null? xxs) '())
              ((good? (car xxs)) xxs)
              (else (del (cdr xxs)))))))
    (list->string xs_good)))
    
;O(n)
;(string-trim-left  "\t\tabc def")  ; "abc def"
;(string-trim-left  "\t\t\n  ")  ; ""

;2
(define (string-trim-right st)
  (define (good? x)
    (and (not (equal? x #\tab)) (not (equal? x #\space))
         (not (equal? x #\newline)) (not (equal? x #\return))))
  (let* ((xs (reverse (string->list st)))
         (xs_good
          (let del ((xxs xs))
            (cond
              ((null? xxs) '())
              ((good? (car xxs)) xxs)
              (else (del (cdr xxs)))))))
    (list->string (reverse xs_good))))

;O(n^2)
;(string-trim-right "abc def\t")   ; "abc def"

;3
(define (string-trim st)
  (define (good? x)
    (and (not (equal? x #\tab)) (not (equal? x #\space))
         (not (equal? x #\newline)) (not (equal? x #\return))))
  (define (trim xs)
    (let del ((xxs xs))
      (cond
        ((null? xxs) '())
        ((good? (car xxs)) xxs)
        (else (del (cdr xxs))))))
  (let* ((my-list (string->list st))
         (my-rez (reverse (trim (reverse (trim my-list))))))
    (list->string my-rez)))

;O(n^2)
;(string-trim "\t abc def \n")  ; "abc def"
;(string-trim "\t\t\n\n  f \n\t")  ; "f"
;(string-trim "")  ; ""

(define (xs-prefix? xs ys)  ; вспомогательная процедура
  (and
   (<= (length xs) (length ys))
   (let pref? ((sub-xs xs) (main-xs ys))
     (or
      (null? sub-xs)
      (and
       (equal? (car sub-xs) (car main-xs))
       (pref? (cdr sub-xs) (cdr main-xs)))))))

;O(n)

;4
(define (string-prefix? a b)
  (xs-prefix? (string->list a) (string->list b)))

;O(n)
;(string-prefix? "abc" "abcdef")  ; #t
;(string-prefix? "bcd" "abcdef")  ; #f
;(string-prefix? "" "ab")  ; #t
;(string-prefix? "" "")  ; #t

;5
(define (string-suffix? a b)
  (xs-prefix? (reverse (string->list a)) (reverse (string->list b))))

;O(n^2)
;(string-suffix? "def" "abcdef")  ; #t
;(string-suffix? "bcd" "abcdef")  ; #f
;(string-suffix? "" "")  ; #t

;6
(define (string-infix? a b)
  (let prefix? ((sub-xs (string->list a))
                (main-xs (string->list b))
                (len-sub (string-length a))
                (len-main (string-length b)))
    (and
     (<= len-sub len-main)
     (or
      (xs-prefix? sub-xs main-xs)
      (prefix? sub-xs (cdr main-xs) len-sub (- len-main 1))))))

;O(n^2)
;(string-infix? "def" "abcdefgh")  ; #t
;(string-infix? "abc" "abcdefgh")  ; #t
;(string-infix? "fgh" "abcdefgh")  ; #t
;(string-infix? "ijk" "abcdefgh")  ; #f
;(string-infix? "bcd" "abc")  ; #f
;(string-infix? "" "")  ; #t

;7
(define (string-split str sep)
  (define separator (reverse (string->list sep)))
  (let str-split ((xs (reverse (string->list str)))
                  (separ separator)
                  (acc (list "")))
    (if (null? separ)
        (str-split xs separator acc)
        (cond
          ((null? xs) acc)
          ((xs-prefix? separ xs)
           (if (equal? (car acc) "")
               (str-split (cdr xs) (cdr separ) acc)
               (str-split (cdr xs) (cdr separ) (cons "" acc))))
          (else (str-split (cdr xs) separ (cons (string-append (string (car xs)) (car acc)) (cdr acc))))))))

       

;O(n^2)
;(string-split "x;separator-yo;z;;" ";")  ; ("x" "separator-yo" "z")
;(string-split "x-->y-->z" "-->")  ; ("x" "y" "z")
;(string-split "kkk" "k")  ; ("")
