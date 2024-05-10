#lang racket

(require redex
         "wellFormedGrammar.rkt")

(define-extended-language ext-lang well-formed-lang
  [stat (some-form)        ; Assume these are original forms from well-formed-lang
        (another-form)     ; Just an example, replace with actual forms
        (const-declaration)]
  [const-declaration (const varlist '=' explist)])  ; Define the syntax of const-declaration

(provide ext-lang)