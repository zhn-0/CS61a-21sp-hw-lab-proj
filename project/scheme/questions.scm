(define (caar x) (car (car x)))
(define (cadr x) (car (cdr x)))
(define (cdar x) (cdr (car x)))
(define (cddr x) (cdr (cdr x)))

; Some utility functions that you may find useful to implement

(define (len p)
  (if (null? p) 0 (+ 1 (len (cdr p))))
  )

(define (zip pairs)
  (define l (len (car pairs)))
  (define (func i)
    (if (= i 0) (lambda (p) p)
      (lambda (p) (cdr ((func (- i 1)) p))))
    )
  (define (recur i)
    (if (= i l) nil
      (cons (map (lambda (p) (car ((func i) p))) pairs) (recur (+ i 1))))
    )
  (recur 0)
  )


;; Problem 15
;; Returns a list of two-element lists
(define (enumerate s)
  ; BEGIN PROBLEM 15
  (define (func i s)
    (cond
      ((null? s) nil)
      (else (cons (list i (car s)) (func (+ i 1) (cdr s))))))
  (func 0 s)
  )
  ; END PROBLEM 15

;; Problem 16

;; Merge two lists LIST1 and LIST2 according to COMP and return
;; the merged lists.
(define (merge comp list1 list2)
  ; BEGIN PROBLEM 16
  (define (func list1 list2)
    (cond
      ((and (null? list1) (null? list2)) nil)
      ((null? list1) list2)
      ((null? list2) list1)
      ((comp (car list1) (car list2)) (cons (car list1) (func (cdr list1) list2)))
      (else (cons (car list2) (func list1 (cdr list2))))
      )
    )
  (func list1 list2)
  )
  ; END PROBLEM 16


;; Problem 17

;; Returns a function that checks if an expression is the special form FORM
(define (check-special form)
  (lambda (expr) (equal? form (car expr))))

(define lambda? (check-special 'lambda))
(define define? (check-special 'define))
(define quoted? (check-special 'quote))
(define let?    (check-special 'let))

;; Converts all let special forms in EXPR into equivalent forms using lambda
(define (let-to-lambda expr)
  (cond ((atom? expr)
         ; BEGIN PROBLEM 17
          expr
         ; END PROBLEM 17
         )
        ((quoted? expr)
         ; BEGIN PROBLEM 17
          expr
         ; END PROBLEM 17
         )
        ((or (lambda? expr)
             (define? expr))
         (let ((form   (car expr))
               (params (cadr expr))
               (body   (cddr expr)))
           ; BEGIN PROBLEM 17
           (cons form (cons params (map let-to-lambda body)))
           ; END PROBLEM 17
           ))
        ((let? expr)
         (let ((values (cadr expr))
               (body   (cddr expr)))
           ; BEGIN PROBLEM 17
           (define tmp (zip values))
           (cons (list 'lambda (car tmp) (let-to-lambda (car body))) (map let-to-lambda (cadr tmp)))
           ; END PROBLEM 17
           ))
        (else
         ; BEGIN PROBLEM 17
          (cons (car expr) (map let-to-lambda (cdr expr)))
         ; END PROBLEM 17
         )))

