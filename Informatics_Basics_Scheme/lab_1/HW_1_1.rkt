(define (day-of-week day month year)
  (define month-code
    (cond
      ((= month 1)
       (if (or (= (remainder year 400) 0)
               (and (= (remainder year 4) 0)
                    (not (= (remainder year 100) 0))))
           0
           1))
      ((= month 2)
       (if (or (= (remainder year 400) 0)
               (and (= (remainder year 4) 0)
                    (not (= (remainder year 100) 0))))
           3
           4))
      ((= month 3) 4)
      ((= month 4) 0)
      ((= month 5) 2)
      ((= month 6) 5)
      ((= month 7) 0)
      ((= month 8) 3)
      ((= month 9) 6)
      ((= month 10) 1)
      ((= month 11) 4)
      ((= month 12) 6)))
  (define year-code
    (let* ((ost-year (remainder (quotient year 100) 4))
          (vek-code
           (cond
             ((= ost-year 0) 6)
             ((= ost-year 1) 4)
             ((= ost-year 2) 2)
             ((= ost-year 3) 0))))
      (remainder (+
                  vek-code
                  (remainder year 100)
                  (quotient (remainder year 100) 4))
                 7)))
  (remainder (+ 6 day month-code year-code ) 7))

;(day-of-week 01 01 2024) ;1
;(day-of-week 18 10 2024) ;5
;(day-of-week 26 02 2023) ;0
;(day-of-week 16 07 1991) ;2
;(day-of-week 18 05 1868) ;1
;(day-of-week 10 09 1600) ;0

