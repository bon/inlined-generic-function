#|
This file is a part of inlined-generic-function project.
Copyright (c) 2015 Masataro Asai (guicho2.71828@gmail.com)
|#

(in-package :cl-user)
(defpackage :inlined-generic-function.playground
  (:use ;; :cl
   :closer-common-lisp
   :introspect-environment
   :inlined-generic-function
   :inlined-generic-function.impl
   :trivia :alexandria :iterate))
(in-package :inlined-generic-function.playground)

(defclass box ()
  ((contents :accessor contents :initarg :contents)))

(defmacro boxify (x)
  `(make-instance 'box :contents ,x))

(defgeneric plus (a b)
  (:generic-function-class inlined-generic-function))

(defmethod plus :around (a (b number))
  (+ (contents a) b)
  (call-next-method))

(defmethod plus ((a box) (b fixnum))
  (+ (contents a) b))
(defmethod plus ((a box) (b double-float))
  (+ (contents a) b))

(defun func-using-plus (a b)
  "; Size: 24 bytes. Origin: #x100914B7A5"
  (declare (optimize (speed 3) (safety 0)))
  (plus (boxify a) b))

(defun func-using-inlined-plus (a b)
  "; Size: 323 bytes. Origin: #x1009614DA5"
  (declare (inline plus))
  (declare (optimize (speed 3) (safety 0)))
  (plus (boxify a) b))

(defun func-using-inlined-plus-and-type-added (a b)
  "Thanks to the nature of inlining,
smart compilers like sbcl can detect certain branches are not reachable,
thus removing the checks and reducing the code size.

In this example, the code for dispatching DOUBLE-FLOAT is removed.

; disassembly for FUNC-USING-INLINED-PLUS-AND-TYPE-ADDED
; Size: 29 bytes. Origin: #x10031E7788
; 88:       4801F9           ADD RCX, RDI          ; no-arg-parsing entry point
; 8B:       488BD1           MOV RDX, RCX
; 8E:       48D1E2           SHL RDX, 1
; 91:       710C             JNO L0
; 93:       488BD1           MOV RDX, RCX
; 96:       41BB70060020     MOV R11D, 536872560   ; ALLOC-SIGNED-BIGNUM-IN-RDX
; 9C:       41FFD3           CALL R11
; 9F: L0:   488BE5           MOV RSP, RBP
; A2:       F8               CLC
; A3:       5D               POP RBP
; A4:       C3               RET
"
  (declare (inline plus))
  (declare (optimize (speed 3) (safety 0)))
  (declare (type fixnum a b))
  (plus (boxify a) b))

(let ((*features* (cons :inline-generic-function *features*)))
  (print (inline-generic-function '(plus (1+ a) (1- b)))))

;; benchmark

(defgeneric normal-plus (a b))

(defmethod normal-plus :around (a (b number))
  (+ (contents a) b)
  (call-next-method))

(defmethod normal-plus ((a box) (b fixnum))
  (+ (contents a) b))
(defmethod normal-plus ((a box) (b double-float))
  (+ (contents a) b))

(defun func-using-normal-plus (a b)
  (declare (optimize (speed 3) (safety 0)))
  (normal-plus (boxify a) b))

(defun func-using-normal-inlined-plus (a b)
  (declare (inline plus))
  (declare (optimize (speed 3) (safety 0)))
  (normal-plus (boxify a) b))

(defvar *input* (iter (repeat 1000)
                      (collect (cons (random 100.0d0) (random 100.0d0)))
                      (collect (cons (+ 20 (random 100)) (+ 20 (random 100))))))

(defun benchmark ()
  (time (iter (for (a . b) in *input*)
              (func-using-normal-plus a b)))
  (time (iter (for (a . b) in *input*)
              (func-using-normal-inlined-plus a b)))
  (time (iter (for (a . b) in *input*)
              (func-using-plus a b)))
  (time (iter (for (a . b) in *input*)
              (func-using-inlined-plus a b))))

(let ((*standard-output* (make-broadcast-stream))
      (*error-output* (make-broadcast-stream))
      (*trace-output* (make-broadcast-stream)))
  (iter (repeat 1000)
        (benchmark)))
(sb-ext:gc :full t)

(benchmark)


