(define (cddr s) (cdr (cdr s)))

(define (cadr s) (car (cdr s)))

(define (caddr s) (car (cdr (cdr s))))

(define (sign val)
	(cond
		((< val 0) -1)
		((= val 0) 0)
		((> val 0) 1)
	)
)

(define (square x) (* x x))

(define (pow base exp)
	(if (= base 1) 1 (if (= exp 1) base 
		(if (odd? exp) (* base (pow base (quotient exp 2)) (pow base (quotient exp 2)))
					(* (pow base (quotient exp 2)) (pow base (quotient exp 2))))))
)
