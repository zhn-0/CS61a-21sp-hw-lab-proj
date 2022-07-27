(define-macro (switch expr cases)
  (cons 'cond
          (map (lambda (case)
                          (cons `(eq? ',(car case) ,expr) (cdr case)))
               cases)))
