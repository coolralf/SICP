; Exercise 4.12: The procedures define-variable!, set-variable-value! and lookup-variable-value can be expressed in terms of more abstract procedures for traversing the environment structure. Define abstractions that capture the common patterns and redefine the three procedures in terms of these abstractions.

(define (enclosing-environment env) (cdr env))
(define (first-frame env) (car env))
(define the-empty-environment '())

(define (make-frame variables values)
  (cons variables values))
(define (frame-variables frame) (car frame))
(define (frame-values frame) (cdr frame))
(define (add-binding-to-frame! var val frame)
  (set-car! frame (cons var (car frame)))
  (set-cdr! frame (cons val (cdr frame))))

(define (extend-environment vars vals base-env)
  (if (= (length vars) (length vals))
      (cons (make-frame vars vals) base-env)
      (if (< (length vars) (length vals))
          (error "Too many arguments supplied" 
                 vars 
                 vals)
          (error "Too few arguments supplied" 
                 vars 
                 vals))))


(define (find_in_frame var frame)
  (let ((vars (frame-variables frame))
        (vals (frame-values frame)))
      (cond
        ((null? vars) false)
        ((eq? var (car vars)) vals)
        (else 
          (find_in_frame 
            var 
            (make-frame (cdr vars) (cdr vals)))))))
(define (env-loop-wraper f var env)
    (if (eq? env the-empty-environment)
        (error "Unbound variable" var)
        (let ((rezult (f (car env))))
          (if rezult
              rezult
              (env-loop-wraper 
                f 
                var
                (enclosing-environment env))))))

(define (lookup-variable-value var env)
  (define (env-loop frame)
      (let ((target_vals 
            (find_in_frame var frame)))
          (if target_vals
              (car target_vals)
              false)))
  (env-loop-wraper env-loop var env))

(define (define-variable! var val env)
  (let ((frame (first-frame env)))
    (let ((target_vals (find_in_frame var frame)))
      (if target_vals
          (set-car! target_vals val)
          (add-binding-to-frame! var val frame)))))

(define (set-variable-value! var val env)
  (define (env-loop frame)
    (let ((target_vals
          (find_in_frame var frame)))
          (if target_vals
              (set-car! target_vals val)
              false)))
  (env-loop-wraper env-loop var env))



(define variables '(1 2 3))
(define values '(a b c))
(define Aenvironment (list (make-frame variables values)))

(define-variable! 4 'hah Aenvironment)
(lookup-variable-value 2 Aenvironment)
(set-variable-value! 2 'lala Aenvironment)
(lookup-variable-value 2 Aenvironment)

; Welcome to DrRacket, version 6.7 [3m].
; Language: SICP (PLaneT 1.18); memory limit: 128 MB.
; 'b
; 'lala
; > 