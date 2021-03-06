;Exercise 5.48: The compile-and-go interface implemented in this section is awkward, since the compiler can be called only once (when the evaluator machine is started). Augment the compiler-interpreter interface by providing a compile-and-run primitive that can be called from within the explicit-control evaluator as follows:
;
;;;; EC-Eval input:
;(compile-and-run
; '(define (factorial n)
;    (if (= n 1)
;        1
;        (* (factorial (- n 1)) n))))
;
;;;; EC-Eval value:
;ok
;
;;;; EC-Eval input:
;(factorial 5)
;
;;;; EC-Eval value:
;120



;;;;;;;;In order to implement compile-and-run,
;implement compile-and-run as primitive-procedures, and then use compiler from outside to compile and return it to the register val and turn on flag, and then go on.
;ofcourse we also need to modify the eceval controller-text adding external-entry-interpreting and branch when return from the op operation

;and since the compiled code to access interpret procedure have done in 5.47 ,
;we just load it
(load "/Users/soulomoon/git/SICP/Chapter5/Exercise5.47.scm")
;I will use my own implementation for this since I don't want to type when I am tesing



(define (compile-and-run expression)
  (let ((instructions
         (assemble (statements
                    (compile expression 'val 'return))
                   eceval)))
    (set-register-contents! eceval 'flag2 true)
    ;(set-register-contents! eceval 'val instructions)
    instructions))
(define primitive-procedures
  (list (list 'car car)
        (list 'cdr cdr)
        (list 'cons cons)
        (list 'null? null?)
	;;above from book -- here are some more
  (list 'display display)
	(list '+ +)
	(list '- -)
	(list '* *)
	(list '= =)
	(list '/ /)
	(list '> >)
	(list '< <)
  (list 'compile-and-run compile-and-run)
        ))

(define the-global-environment (setup-environment))

(define eceval
  (make-machine
    ;;;;extra to hold the the ones about to be interpret
   '(exp env val proc argl continue unev extra extra-go flag2
	 compapp			;*for compiled to call interpreted
	 )
   eceval-operations
  '(
;;SECTION 5.4.4, as modified in 5.5.7
;;*for compiled to call interpreted (from exercise 5.47)
  (assign compapp (label compound-apply))
;;*next instruction supports entry from compiler (from section 5.5.7)
  (branch (label external-entry))
read-eval-print-loop
  (perform (op initialize-stack))
  (perform (op prompt-for-input) (const ";;; EC-Eval input:"))
;;;;if there is nothing go to the end
  (test (op null?) (reg extra))
  (branch (label ev-end))
;;;;;eval the current
  (assign exp (op car) (reg extra))
  (perform (op ev-print) (reg exp))
  (assign extra (op cdr) (reg extra))
  (assign env (op get-global-environment))
  (assign continue (label print-result))
  (goto (label eval-dispatch))
print-result
;;branch here external-entry-interpreting
  (test (op eq?) (reg flag2) (const #t))
  (branch (label external-entry-interpreting))

;;**test if it is 'ok if so , skip it
  (test (op eq?) (const ok) (reg val))
  (branch (label skip-point))
;;**following instruction optional -- if use it, need monitored stack
  (perform (op print-stack-statistics))
  (perform
   (op announce-output) (const ";;; EC-Eval value:"))
  (perform (op user-print) (reg val))

;;;;;;;;skip point
skip-point
  (goto (label read-eval-print-loop))

;;*support for entry from compiler (from section 5.5.7)
external-entry
  (perform (op initialize-stack))
  (assign env (op get-global-environment))
  (assign continue (label print-result))
  (goto (reg val))

;we don't need to initialize-stack and environment here
external-entry-interpreting
  (assign flag2 (const #f))
  (perform (op initialize-stack))
  (assign continue (label print-result))
  (goto (reg val))

unknown-expression-type
  (assign val (const unknown-expression-type-error))
  (goto (label signal-error))

unknown-procedure-type
  (restore continue)
  (assign val (const unknown-procedure-type-error))
  (goto (label signal-error))

signal-error
  (perform (op user-print) (reg val))
  (goto (label read-eval-print-loop))

;;SECTION 5.4.1
eval-dispatch
  (test (op self-evaluating?) (reg exp))
  (branch (label ev-self-eval))
  (test (op variable?) (reg exp))
  (branch (label ev-variable))
  (test (op quoted?) (reg exp))
  (branch (label ev-quoted))
  (test (op assignment?) (reg exp))
  (branch (label ev-assignment))
  (test (op definition?) (reg exp))
  (branch (label ev-definition))
  (test (op if?) (reg exp))
  (branch (label ev-if))
  (test (op lambda?) (reg exp))
  (branch (label ev-lambda))
  (test (op begin?) (reg exp))
  (branch (label ev-begin))
  (test (op application?) (reg exp))
  (branch (label ev-application))
  (goto (label unknown-expression-type))

ev-self-eval
  (assign val (reg exp))
  (goto (reg continue))
ev-variable
  (assign val (op lookup-variable-value) (reg exp) (reg env))
  (goto (reg continue))
ev-quoted
  (assign val (op text-of-quotation) (reg exp))
  (goto (reg continue))
ev-lambda
  (assign unev (op lambda-parameters) (reg exp))
  (assign exp (op lambda-body) (reg exp))
  (assign val (op make-procedure)
              (reg unev) (reg exp) (reg env))
  (goto (reg continue))

ev-application
  (save continue)
  (save env)
  (assign unev (op operands) (reg exp))
  (save unev)
  (assign exp (op operator) (reg exp))
  (assign continue (label ev-appl-did-operator))
  (goto (label eval-dispatch))
ev-appl-did-operator
  (restore unev)
  (restore env)
  (assign argl (op empty-arglist))
  (assign proc (reg val))
  (test (op no-operands?) (reg unev))
  (branch (label apply-dispatch))
  (save proc)
ev-appl-operand-loop
  (save argl)
  (assign exp (op first-operand) (reg unev))
  (test (op last-operand?) (reg unev))
  (branch (label ev-appl-last-arg))
  (save env)
  (save unev)
  (assign continue (label ev-appl-accumulate-arg))
  (goto (label eval-dispatch))
ev-appl-accumulate-arg
  (restore unev)
  (restore env)
  (restore argl)
  (assign argl (op adjoin-arg) (reg val) (reg argl))
  (assign unev (op rest-operands) (reg unev))
  (goto (label ev-appl-operand-loop))
ev-appl-last-arg
  (assign continue (label ev-appl-accum-last-arg))
  (goto (label eval-dispatch))
ev-appl-accum-last-arg
  (restore argl)
  (assign argl (op adjoin-arg) (reg val) (reg argl))
  (restore proc)
  (goto (label apply-dispatch))
apply-dispatch
  (test (op primitive-procedure?) (reg proc))
  (branch (label primitive-apply))
  (test (op compound-procedure?) (reg proc))
  (branch (label compound-apply))
;;*next added to call compiled code from evaluator (section 5.5.7)
  (test (op compiled-procedure?) (reg proc))
  (branch (label compiled-apply))
  (goto (label unknown-procedure-type))

;;*next added to call compiled code from evaluator (section 5.5.7)
compiled-apply
  (restore continue)
  (assign val (op compiled-procedure-entry) (reg proc))
  (goto (reg val))

primitive-apply
  (assign val (op apply-primitive-procedure)
              (reg proc)
              (reg argl))
  (restore continue)
  (goto (reg continue))

compound-apply
  (assign unev (op procedure-parameters) (reg proc))
  (assign env (op procedure-environment) (reg proc))
  (assign env (op extend-environment)
              (reg unev) (reg argl) (reg env))
  (assign unev (op procedure-body) (reg proc))
  (goto (label ev-sequence))

;;;SECTION 5.4.2
ev-begin
  (assign unev (op begin-actions) (reg exp))
  (save continue)
  (goto (label ev-sequence))

ev-sequence
  (assign exp (op first-exp) (reg unev))
  (test (op last-exp?) (reg unev))
  (branch (label ev-sequence-last-exp))
  (save unev)
  (save env)
  (assign continue (label ev-sequence-continue))
  (goto (label eval-dispatch))
ev-sequence-continue
  (restore env)
  (restore unev)
  (assign unev (op rest-exps) (reg unev))
  (goto (label ev-sequence))
ev-sequence-last-exp
  (restore continue)
  (goto (label eval-dispatch))

;;;SECTION 5.4.3

ev-if
  (save exp)
  (save env)
  (save continue)
  (assign continue (label ev-if-decide))
  (assign exp (op if-predicate) (reg exp))
  (goto (label eval-dispatch))
ev-if-decide
  (restore continue)
  (restore env)
  (restore exp)
  (test (op true?) (reg val))
  (branch (label ev-if-consequent))
ev-if-alternative
  (assign exp (op if-alternative) (reg exp))
  (goto (label eval-dispatch))
ev-if-consequent
  (assign exp (op if-consequent) (reg exp))
  (goto (label eval-dispatch))

ev-assignment
  (assign unev (op assignment-variable) (reg exp))
  (save unev)
  (assign exp (op assignment-value) (reg exp))
  (save env)
  (save continue)
  (assign continue (label ev-assignment-1))
  (goto (label eval-dispatch))
ev-assignment-1
  (restore continue)
  (restore env)
  (restore unev)
  (perform
   (op set-variable-value!) (reg unev) (reg val) (reg env))
  (assign val (const ok))
  (goto (reg continue))

ev-definition
  (assign unev (op definition-variable) (reg exp))
  (save unev)
  (assign exp (op definition-value) (reg exp))
  (save env)
  (save continue)
  (assign continue (label ev-definition-1))
  (goto (label eval-dispatch))
ev-definition-1
  (restore continue)
  (restore env)
  (restore unev)
  (perform
   (op define-variable!) (reg unev) (reg val) (reg env))
  (assign val (const ok))
  (goto (reg continue))
ev-end
   )))

(go-two
  '(define (f) (g))
  '((define (g) (+ 1 1))
    (compile-and-run
     '(define (factorial n)
        (if (= n 1)
            1
            (* (factorial (- n 1)) n))))
    (compile-and-run
      '(f))
    (compile-and-run
      '(factorial 5))
    (f)
    (factorial 5)))

;Welcome to DrRacket, version 6.8 [3m].
;Language: SICP (PLaneT 1.18); memory limit: 128 MB.
;(REGISTER SIMULATOR LOADED)
;(EXPLICIT CONTROL EVALUATOR FOR COMPILER LOADED)
;
;
;;;; EC-Eval input:
;λ > (define (g) (+ 1 1))
;
;
;;;; EC-Eval input:
;λ > (compile-and-run '(define (factorial n) (if (= n 1) 1 (* (factorial (- n 1)) n))))
;
;
;;;; EC-Eval input:
;λ > (compile-and-run '(f))
;
;(total-pushes = 9 maximum-depth = 5)
;;;; EC-Eval value:
;2
;
;;;; EC-Eval input:
;λ > (compile-and-run '(factorial 5))
;
;(total-pushes = 26 maximum-depth = 14)
;;;; EC-Eval value:
;120
;
;;;; EC-Eval input:
;λ > (f)
;
;(total-pushes = 12 maximum-depth = 5)
;;;; EC-Eval value:
;2
;
;;;; EC-Eval input:
;λ > (factorial 5)
;
;(total-pushes = 31 maximum-depth = 14)
;;;; EC-Eval value:
;120
;
;;;; EC-Eval input:
;'done
;>
