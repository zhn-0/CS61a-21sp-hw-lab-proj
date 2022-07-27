(define (tail-replicate x n)
  (define (func n r)
    (if (= n 0) r (func (- n 1) (cons x r)))
    )
  (func n nil)
  )

(define-macro (def func args body)
  `(define (,func ,@args) ,body)
  )

(define (repeatedly-cube n x)
  (if (zero? n)
      x
      (let ((y (repeatedly-cube (- n 1) x)))
        (* y y y))))
