#|
  This file is a part of inlined-generic-function project.
  Copyright (c) 2015 Masataro Asai (guicho2.71828@gmail.com)
|#

(in-package :cl-user)

(defpackage inlined-generic-function
  (:nicknames :inlined-gf)
  (:export
   #:inlined-generic-function
   #:freeze-inlined-generic-function))

(defpackage inlined-generic-function.impl
  (:use :closer-common-lisp :trivia :alexandria :iterate
        :introspect-environment
        #+nil :SANDALPHON.COMPILER-MACRO
        :inlined-generic-function)
  (:export
   #:inlined-method
   #:method-lambda-expression
   #:inline-generic-function
   #:method-lambda-expression*))

