#lang racket

(require redex
         "../../../grammar.rkt"
         "../../../Meta-functions/grammarMetaFunctions.rkt"
         "../../../Meta-functions/delta.rkt"
         "../../../Meta-functions/substitution.rkt"
         "../../../Meta-functions/objStoreMetaFunctions.rkt"
         "./prepare.rkt")

;                                                                                          
;                                                                                          
;                   ;;;     ;;;                ;;                                        ; 
;                     ;       ;               ;                                          ; 
;                     ;       ;               ;                                          ; 
;                     ;       ;               ;                                          ; 
;  ;      ;  ;;;;     ;       ;             ;;;;;    ;;;;    ;;;;   ;;;;;;;  ;;;;    ;;;;; 
;  ;      ; ;;  ;;    ;       ;               ;     ;;  ;;   ;;  ;  ;  ;  ; ;;  ;;  ;;  ;; 
;   ; ;; ;  ;    ;    ;       ;               ;     ;    ;   ;      ;  ;  ; ;    ;  ;    ; 
;   ; ;; ;  ;;;;;;    ;       ;      ;;;      ;     ;    ;   ;      ;  ;  ; ;;;;;;  ;    ; 
;   ; ;; ;  ;         ;       ;               ;     ;    ;   ;      ;  ;  ; ;       ;    ; 
;    ;  ;   ;;   ;    ;       ;               ;     ;;  ;;   ;      ;  ;  ; ;;   ;  ;;  ;; 
;    ;  ;    ;;;;      ;;;     ;;;            ;      ;;;;    ;      ;  ;  ;  ;;;;    ;;;;; 
;                                                                                          
;                                                                                          
;                                                                                          
;
; stored tables have more constraints than regular tableconstructor; the
; following formal systems checks them
(define-judgment-form
  ext-lang
  #:mode (well_formed_stored_table I I I I)
  #:contract (well_formed_stored_table C σ θ (field ...))

  ; rule added to simplify the use of this system
  [---------------------------------------------------------------------------
   (well_formed_stored_table any σ θ ())]

  [; key must not be nil or nan, value must not be nil but we still allow it
   ; to simplify the formalization of iterators (see next in deltaBasic)
   ; nil-valued fields do not introduce the risk of obtaining an stuck
   ; configuration
   (side-condition ,(not (or (is_nil? (term v_1))
                             (equal? (term v_1)
                                     +nan.0))))
   
   (well_formed_term any σ θ v_1)
   (well_formed_term any σ θ v_2)
   (well_formed_stored_table any σ θ (field ...))
   ---------------------------------------------------------------------------
   (well_formed_stored_table any σ θ ((\[ v_1 \] = v_2) field ...))]
  )

; check table field from a table constructor
(define-judgment-form
  ext-lang
  #:mode (well_formed_conf_table_field I I I I)
  #:contract (well_formed_conf_table_field C σ θ (field ...))

  [; valid intermediate state of computation: wfecore ... does not include tagged
   ; terms
   (side-condition ,(redex-match?  ext-lang
                                   (v ... e_3 wfecore ...)
                                   (term (e_1 e_2))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2)
   ---------------------------------------------------------------------------
   (well_formed_conf_table_field any σ θ ((\[ e_1 \] = e_2)))]
  
  [(well_formed_term any σ θ e)
   ---------------------------------------------------------------------------
   (well_formed_conf_table_field any σ θ (e))]

  [; valid intermediate state of computation
   (side-condition ,(redex-match?  ext-lang
                                   (v ... e_3 wfecore ...)
                                   (term (e_1 e_2))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2)
   (well_formed_conf_table_field any σ θ (field_1 field_2 ...))
   ---------------------------------------------------------------------------
   (well_formed_conf_table_field any σ θ ((\[ e_1 \] = e_2) field_1
                                                            field_2 ...))]

  [(well_formed_term any σ θ e)
   (well_formed_conf_table_field any σ θ (field_1 field_2 ...))
   ---------------------------------------------------------------------------
   (well_formed_conf_table_field any σ θ (e field_1 field_2 ...))]
  )



(define-judgment-form
  ext-lang
  #:mode (well_formed_term I I I I)
  #:contract (well_formed_term C σ θ t)


  ;                                          
  ;                                          
  ;                                          
  ;                                          
  ;             ;               ;            
  ;             ;               ;            
  ;    ;;;;   ;;;;;;    ;;;   ;;;;;;   ;;;;  
  ;   ;    ;    ;      ;   ;    ;     ;    ; 
  ;   ;         ;          ;    ;     ;      
  ;    ;;;;     ;      ;;;;;    ;      ;;;;  
  ;        ;    ;     ;    ;    ;          ; 
  ;   ;    ;    ;     ;   ;;    ;     ;    ; 
  ;    ;;;;      ;;;   ;;; ;     ;;;   ;;;;  
  ;                                          
  ;                                          
  ;                                          
  ;                                          


  [-----------------------------
   (well_formed_term any σ θ \;)]

  [(side-condition
    ; TODO: for some reason Redex won't let me combine these matches into a
      ; single one, using the same approach as with function calls
    ,(or
      ; break inside a while loop 
      (redex-match?  ext-lang
                     (side-condition
                      (in-hole C_2 (while e do C_3 end))
                      (not (or (redex-match?  ext-lang
                                              (in-hole C_4 (C_5 (renv ...) RetStat))
                                              (term  C_3))
                               (redex-match?  ext-lang
                                              (in-hole C_4 (C_5 (renv ...) RetExp))
                                              (term  C_3))
                               (redex-match?  ext-lang
                                              (in-hole C_4 (function Name parameters C_5 end))
                                              (term  C_3)))))
                     (term any))
      ; break inside a tagged s: ((in-hole Elf break) Break)
      ; we aprox. the definition of Elf, and also ask for a break outside
      ; of function defs.
      (redex-match?  ext-lang
                     (side-condition
                      (in-hole C_2 (C_3 Break))
                      (not (or (redex-match?  ext-lang
                                              (in-hole C_4 (C_5 (renv ...) RetStat))
                                              (term  C_3))
                               (redex-match?  ext-lang
                                              (in-hole C_4 (C_5 (renv ...) RetExp))
                                              (term  C_3))
                               (redex-match?  ext-lang
                                              (in-hole C_4 (function Name parameters C_5 end))
                                              (term  C_3)))))
                     (term any))))
   --------------------------------
   (well_formed_term any σ θ break)]

  [-----------------------------------
   (well_formed_term any σ θ (return))]

  [; e_1 e_2 ... must be a legitimate intermediate state of computation
   (side-condition ,(redex-match?  ext-lang
                                   (v ... e_3 wfecore ...)
                                   (term (e_1 e_2 ...))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2) ...
   -----------------------------------------------------------------
   (well_formed_term any σ θ (return e_1 e_2 ...))]

  ; fun call
  [; e_1 (e_2 ...) must be a legitimate intermediate state of evaluation
   (side-condition ,(redex-match?  ext-lang
                                   (v ... e_3 wfecore ...)
                                   (term (e_1 e_2 ...))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2) ...
   ----------------------------------------------------------------------
   (well_formed_term any σ θ ($statFCall e_1 (e_2 ...)))]

  [(side-condition ,(redex-match?  ext-lang
                                   ; after the evaluation of e_1, the method call
                                   ; is rewritten into a function call over some
                                   ; table value; the list of parameters is
                                   ; evaluated only after this transformation
                                   (wfecore ...)
                                   (term (e_2 ...))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2) ...
   --------------------------------------------------------------------
   (well_formed_term any σ θ ($statFCall e_1 : Name (e_2 ...)))]
  
  ; var assignment
  [; the following checks if a var of the form e \[ e \] is also a valid
   ; intermediate state of computation
   (well_formed_term any σ θ var_1) ...
   (well_formed_term any σ θ e_1) ...

   ; var ... = e ... must be a legitimate intermediate state of evaluation
   (side-condition ,(redex-match?  ext-lang
                                   (evar_2 ... v ... e_2 wfecore_2 ...)
                                   (term (var_1 ... e_1 ...))))
   
   ----------------------------------------------------------------------
   (well_formed_term any σ θ (var_1 ... = e_1 ...))]

  [(well_formed_term any σ θ s)
   ----------------------------------------------------------------------
   (well_formed_term any σ θ (do s end))]

  [(well_formed_term any σ θ e)
   (well_formed_term any σ θ wfscore_1)
   (well_formed_term any σ θ wfscore_2)
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (if e then wfscore_1 else wfscore_2 end))]

  [(well_formed_term any σ θ e)
   (well_formed_term ,(plug (term any)
                            (term (while e do hole end))) σ θ wfscore)
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (while e do wfscore end))]
  
  [(well_formed_term any σ θ e)
   (well_formed_term ,(plug (term any)
                            (term ($iter e do hole end))) σ θ wfscore)
   --------------------------------------------------------------------------
   (well_formed_term any σ θ ($iter e do wfscore end))]

  ; local var
  [(well_formed_term ,(plug (term any)
                            (term (local Name ... = in hole end))) σ θ
                                                                   wfscore)
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (local Name ... = in wfscore end))]
  
  [; checks if e ... is a valid intermediate state of evaluation
   (side-condition ,(redex-match?  ext-lang
                                   (v ... e_3 wfecore ...)
                                   (term (e_1 e_2 ...))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2) ...
   (well_formed_term ,(plug (term any)
                            (term (local Name ... = e_1 e_2 ... in
                                    hole end))) σ θ wfscore)
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (local Name ... = e_1 e_2 ... in wfscore end))]

  [(well_formed_term any σ θ r) ...
   (well_formed_term ,(plug (term any)
                            (term (hole ((rEnv r) ...)
                                        LocalBody))) σ θ s)
   --------------------------------------------------------------------------
   (well_formed_term any σ θ
                     (s ((rEnv r) ...) LocalBody))]

  ; conc stats
  [(well_formed_term any σ θ wfssing)
   (well_formed_term any σ θ wfscoresing_1)
   (well_formed_term any σ θ wfscoresing_2) ...
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (wfssing wfscoresing_1 wfscoresing_2 ...))]

  ; error object
  [(well_formed_term any σ θ v)
   --------------------------------------------------------------------------
   (well_formed_term any σ θ ($err v))]

  
  ;                                                                          
  ;                                                                          
  ;   ;;;             ;                                                      
  ;     ;             ;                                                      
  ;     ;             ;                         ;               ;            
  ;     ;             ;                         ;               ;            
  ;     ;       ;;;   ;;;;;            ;;;;   ;;;;;;    ;;;   ;;;;;;   ;;;;  
  ;     ;      ;   ;  ;;  ;;          ;    ;    ;      ;   ;    ;     ;    ; 
  ;     ;          ;  ;    ;          ;         ;          ;    ;     ;      
  ;     ;      ;;;;;  ;    ;           ;;;;     ;      ;;;;;    ;      ;;;;  
  ;     ;     ;    ;  ;    ;               ;    ;     ;    ;    ;          ; 
  ;     ;     ;   ;;  ;;  ;;          ;    ;    ;     ;   ;;    ;     ;    ; 
  ;      ;;;   ;;; ;  ;;;;;            ;;;;      ;;;   ;;; ;     ;;;   ;;;;  
  ;                                                                          
  ;                                                                          
  ;                                                                          
  ;                                                                          
  

  ; Break tag
  [(well_formed_term ,(plug (term any)
                            (term (hole Break))) σ θ s_1)
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (s_1 Break))]

  ; table assignment, wrong key
  [(well_formed_term any σ θ tid) ; checks for membership of objref to θ
   (well_formed_term any σ θ v_1)
   (well_formed_term any σ θ v_2)

   ; v_1 should not belong to dom(θ (objref))
   (side-condition ,(is_nil? (term (δ rawget tid v_1 θ))))
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (((tid \[ v_1 \]) = v_2) WrongKey tid_2 ...))]

  ; table assignment, nontable
  [(well_formed_term any σ θ v_1)
   (well_formed_term any σ θ v_2)
   (well_formed_term any σ θ v_3)
   (side-condition ,(not (is_tid? (term v_1))))
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (((v_1 \[ v_2 \]) = v_3) NonTable tid ...))]

  ; to avoid ambiguous cases (we consider case $err in isolation)
  [(side-condition ,(not (redex-match? ext-lang
                                       (($err v) ...
                                        break ...
                                        \; ...)
                                        (term (s)))))
   (well_formed_term any σ θ s)
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (s Meta tid ...))]

  ; WFunCall
  [(well_formed_term any σ θ v_1)
   (well_formed_term any σ θ v_2) ...
   (side-condition ,(not (is_cid? (term v_1))))
   --------------------------------------------------------------------------
   (well_formed_term any σ θ (($statFCall v_1 (v_2 ...)) WFunCall tid ...))]
  
  [(well_formed_term ,(plug (term any)
                            (term (hole ((rEnv r) ...) RetStat))) σ θ s)
   (well_formed_term any σ θ r) ...
   ------------------------------------------------------------------------
   (well_formed_term any σ θ (s ((rEnv r) ...) RetStat))]

  
  ;                                  
  ;                                  
  ;                                  
  ;                                  
  ;                                  
  ;                                  
  ;    ;;;;   ;;  ;;  ;;;;;    ;;;;  
  ;   ;;  ;;   ;  ;   ;;  ;;  ;    ; 
  ;   ;    ;    ;;    ;    ;  ;      
  ;   ;;;;;;    ;;    ;    ;   ;;;;  
  ;   ;         ;;    ;    ;       ; 
  ;   ;;   ;   ;  ;   ;;  ;;  ;    ; 
  ;    ;;;;   ;;  ;;  ;;;;;    ;;;;  
  ;                   ;              
  ;                   ;              
  ;                   ;              
  ;                            

  [--------------------------------
   (well_formed_term any σ θ nil)]

  [--------------------------------
   (well_formed_term any σ θ Boolean)]

  [--------------------------------
   (well_formed_term any σ θ Number)]

  [--------------------------------
   (well_formed_term any σ θ String)]

  [(side-condition (refBelongsToTheta? objref θ))
   ----------------------------------------------
   (well_formed_term any σ θ objref)]

  [(side-condition (refBelongsToTheta? cid θ))
   ----------------------------------------------
   (well_formed_term any σ θ cid)]

  ; functiondef
  [(well_formed_term ,(plug (term any)
                            (term (function Name_1 (Name_2 ...)
                                            hole
                                            end))) σ θ wfscore)
   ----------------------------------------------
   (well_formed_term any σ θ (function Name_1 (Name_2 ...) wfscore end))]

  [(well_formed_term ,(plug (term any)
                            (term (function Name_1 (Name_2 ... <<<)
                                            hole
                                            end))) σ θ wfscore)
   ----------------------------------------------
   (well_formed_term any σ θ (function Name_1 (Name_2 ... <<<) wfscore end))]

  ; vararg mark
  [; <<< is being captured, according to the scoping rules codified in fv
   (side-condition ,(not (member (term <<<)
                                 (term (fv ,(plug (term any) (term <<<)))))))
   ---------------------------------------------------------------------------
   (well_formed_term any σ θ <<<)]

  ; A Name's occurrence must be bounded
  [(side-condition
    ,(or (redex-match?  ext-lang
                        (in-hole C_2
                                 (function Name_1
                                           (Name_2 ...
                                            (side-condition
                                             Name_3
                                             (equal? (term Name_3)
                                                     (term Name_4)))
                                            any_2 ...)
                                           C_3 end))
                        (term any))
         (redex-match?  ext-lang
                        (in-hole C_2
                                 (local Name_1 ...
                                   (side-condition Name_2
                                                   (equal? (term Name_2)
                                                           (term Name_4)))
                                   Name_3 ... = e ... in C_3 end))
                        (term any))))
   ---------------------------------------------------------------------------
   (well_formed_term any σ θ Name_4)]

  [; (e_1 \[ e_2 \]) must represent a valid intermediate state of evaluation
   (side-condition ,(redex-match?  ext-lang
                                   (v ... e_3 wfecore ...)
                                   (term (e_1 e_2))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2)
   ---------------------------------------------------------------------------
   (well_formed_term any σ θ (e_1 \[ e_2 \]))]

  ; built-in service
  [---------------------------------------------------------------------------
   (well_formed_term any σ θ ($builtIn builtinserv ()))]

  [; e_1 ... must represent a valid intermediate state of evaluation
   (side-condition ,(redex-match? ext-lang
                                  (v ... e_3 wfecore ...)
                                  (term (e_1 e_2 ...))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2) ...
   ---------------------------------------------------------------------------
   (well_formed_term any σ θ ($builtIn builtinserv (e_1 e_2 ...)))]

  ; parenthesized expression
  [(well_formed_term any σ θ e)
   ---------------------------------------------------------------------------
   (well_formed_term any σ θ (\( e \)))]

  ; table constructor and fields
  [---------------------------------------------------------------------------
   (well_formed_term any σ θ (\{ \}))]
  
  [(well_formed_conf_table_field any σ θ (field_1 field_2 ...))
   ---------------------------------------------------------------------------
   (well_formed_term any σ θ (\{ field_1 field_2 ... \}))]


  ; binop
  [(side-condition ,(redex-match?  ext-lang
                                   (v ... e_3 wfecore ...)
                                   (term (e_1 e_2))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2)
   ---------------------------------------------------------------------------
   (well_formed_term any σ θ (e_1 binop e_2))]

  ; unop
  [(well_formed_term any σ θ e)
   ---------------------------------------------------------------------------
   (well_formed_term any σ θ (unop e))]

  ; val ref
  [-----------------------------------
   (well_formed_term any ((any_1 v_1) ... (r v_2) (any_2 v_3) ...) θ r)]

  [(well_formed_term any σ θ r)
   -----------------------------------
   (well_formed_term any σ θ (rEnv r))]

  ; tuples
  [--------------------------------------------------
   (well_formed_term any σ θ (< >))]
  
  [(side-condition ,(redex-match?  ext-lang
                                   (v ... e_3 wfecore ...)
                                   (term (e_1 e_2 ...))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2) ...
   --------------------------------------------------
   (well_formed_term any σ θ (< e_1 e_2 ... >))]
  ; fun call
  [(side-condition ,(redex-match?  ext-lang
                                   (v ... e_3 wfecore ...)
                                   (term (e_1 e_2 ...))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2) ...
   ----------------------------------------------------------------------
   (well_formed_term any σ θ (e_1 (e_2 ...)))]

  [(side-condition ,(redex-match?  ext-lang
                                   ; after the evaluation of e_1, the method call
                                   ; is rewritten into a function call over some
                                   ; table value; the list of parameters is
                                   ; evaluated only after this transformation
                                   (wfecore ...)
                                   (term (e_2 ...))))
   (well_formed_term any σ θ e_1)
   (well_formed_term any σ θ e_2) ...
   --------------------------------------------------------------------
   (well_formed_term any σ θ (e_1 : Name (e_2 ...)))]
  
  ;                                                                  
  ;                                                                  
  ;   ;;;             ;                                              
  ;     ;             ;                                              
  ;     ;             ;                                              
  ;     ;             ;                                              
  ;     ;       ;;;   ;;;;;            ;;;;   ;;  ;;  ;;;;;    ;;;;  
  ;     ;      ;   ;  ;;  ;;          ;;  ;;   ;  ;   ;;  ;;  ;    ; 
  ;     ;          ;  ;    ;          ;    ;    ;;    ;    ;  ;      
  ;     ;      ;;;;;  ;    ;          ;;;;;;    ;;    ;    ;   ;;;;  
  ;     ;     ;    ;  ;    ;          ;         ;;    ;    ;       ; 
  ;     ;     ;   ;;  ;;  ;;          ;;   ;   ;  ;   ;;  ;;  ;    ; 
  ;      ;;;   ;;; ;  ;;;;;            ;;;;   ;;  ;;  ;;;;;    ;;;;  
  ;                                                   ;              
  ;                                                   ;              
  ;                                                   ;              
  ;                                                                  
  [(well_formed_term any σ θ e)
   (well_formed_term any σ θ v)
   (where ((v_1 (v_2 ...)) ...

           ; successful fcall
           (s (renv ...) RetExp) ...
           (< v_3 ... >) ...

           ; problems in fcall
           (δbasic error v_4) ...
           ($err v_5) ...
           ((v_6 (v_7 ...)) WFunCall tid_1 ...) ...
           ((v_8 (v_9 ...)) Meta tid_2 ...) ...
           )
          (e))
   ------------------------------------------------------------
   (well_formed_term any σ θ (e ProtMD v))]

  [(well_formed_term any σ θ e)
   (where (v ...
           (\( e_2 \)) ...)
          (e))
   ------------------------------------------------------------
   (well_formed_term any σ θ (e ProtMD))]

  [(well_formed_term any σ θ v_1)
   (well_formed_term any σ θ v_2)
   (side-condition ,(not (is_tid? (term v_1))))
   ------------------------------------------------------
   (well_formed_term any σ θ ((v_1 \[ v_2 \]) NonTable tid ...))]

  [(well_formed_term any σ θ tid) ; checks for (refBelongsToTheta? objref θ)
   (well_formed_term any σ θ v)
   (side-condition ,(is_nil? (term (δ rawget tid v θ))))
   ------------------------------------------------------
   (well_formed_term any σ θ ((tid \[ v \]) WrongKey tid_2 ...))]
  
  [(side-condition ,(not (redex-match? ext-lang
                                       (
                                        ($err v_1) ...
                                        v_2 ...
                                        Name ...
                                        r ...
                                        <<< ...
                                        (< e_2 ... >) ...
                                        )
                                       (term (e)))))
   (well_formed_term any σ θ e)
   ; note that we do not need to check tid ...: the notion of wft
   ; does not depend on them
   -------------------------------------------
   (well_formed_term any σ θ (e Meta tid ...))]

  [(well_formed_term any σ θ v_1)
   (well_formed_term any σ θ v_2)
   (side-condition
    
    ,(or
      ; arith op
      (and (is_arithop? (term binop))
           (or (not (is_number? (term (δ tonumber v_1 nil))))
               (not (is_number? (term (δ tonumber v_2 nil))))))
      ; string concat
      (and (is_strconcat? (term binop))
           (or (not (or (is_number? (term v_1))
                        (is_string? (term v_1))))
               (not (or (is_number? (term v_2))
                        (is_string? (term v_2))))))

      ;relop
      (and (is_relop? (term binop))
           (not (and (equal? (term (δ type v_1))
                             (term (δ type v_2)))
                     (or (is_string? (term v_1))
                         (is_number? (term v_1))))))
      ))
   ----------------------------------------------------------------------------
   (well_formed_term any σ θ ((v_1 binop v_2) BinopWO tid ...))]

  [(side-condition ,(not (is_string? (term v))))
   (well_formed_term any σ θ v)
   ---------------------------------------------------
   (well_formed_term any σ θ ((\# v) StrLenWrongOp tid ...))]

  [(side-condition ,(and (not (is_number? (term v)))
                         (not (is_number? (term (δ tonumber v nil))))))
   (well_formed_term any σ θ v)
   ------------------------------------------------------------------------
   (well_formed_term any σ θ ((- v) NegWrongOp tid ...))]

  [(side-condition ,(equal? (term (δ == v_1 v_2))
                            (term false)))
   (well_formed_term any σ θ v_1)
   (well_formed_term any σ θ v_2)
   ------------------------------------------------------------------------
   (well_formed_term any σ θ ((v_1 == v_2) EqFail tid ...))]

  [(well_formed_term any σ θ v_1)
   (well_formed_term any σ θ v_2) ...
   (side-condition ,(not (is_cid? (term v_1))))
   --------------------------------------------------------------------------
   (well_formed_term any σ θ ((v_1 (v_2 ...)) WFunCall tid ...))]

  [(well_formed_term ,(plug (term any)
                            (term (hole ((rEnv r) ...) RetExp))) σ θ s)
   (well_formed_term any σ θ r) ...
   ------------------------------------------------------------------------
   (well_formed_term any σ θ (s ((rEnv r) ...) RetExp))]
  )

(provide well_formed_term)

; well-formedness of stores
(define-metafunction  ext-lang
  well_formed_vsp : vsp σ θ -> any

  [(well_formed_vsp (r v) σ θ)
   #t
   
   ; value must be well formed: tid and cid must belong to dom(θ)
   (side-condition (judgment-holds (well_formed_term hole σ θ v)))]

  ; default
  [(well_formed_vsp any ...)
   #f]
  )

(define-metafunction  ext-lang
  well_formed_sigma : σ σ θ -> any
  
  [(well_formed_sigma () σ θ)
   #t]

  ; stdout file
  [(well_formed_sigma ((refStdout String) (r v) ...) σ θ)
   (well_formed_sigma ((r v) ...) σ θ)]
  
  [(well_formed_sigma ((r v) vsp ...) σ θ)
   (well_formed_sigma (vsp ...) σ θ)

   (side-condition (term (well_formed_vsp (r v) σ θ)))]

  ; default
  [(well_formed_sigma _ _ _)
   #f])

(define-metafunction  ext-lang
  well_formed_osp : osp σ θ -> any
  
  [(well_formed_osp (tid_1 ((\{ field ... \}) tid_2 pos)) σ θ)
   #t

   ; meta-table tid_2 must not be removed before tid_1
   (side-condition (judgment-holds (well_formed_term hole σ θ tid_2)))

   ; table constructor must be well formed
   (side-condition (judgment-holds (well_formed_stored_table hole σ θ 
                                                             (field ...))))]

  [(well_formed_osp (tid_1 ((\{ field ... \}) nil pos)) σ θ)
   #t
   
   ; table constructor must be well formed
   (side-condition (judgment-holds (well_formed_stored_table hole σ θ 
                                                             (field ...))))]

  [(well_formed_osp (cid_1 functiondef_1) σ θ)
   #t
   
   ; functiondef must be well formed
   (side-condition (judgment-holds (well_formed_term hole σ θ 
                                                     functiondef_1)))

   ; functiondef must be unique in the store
   ; to preserve closure caching invariant
   (side-condition (not (redex-match ext-lang
                                     (side-condition  (osp_1 ...
                                                       (cid_2 functiondef_2)
                                                       osp_2 ...)
                                                      (and (equal? (term functiondef_1)
                                                                   (term functiondef_2))
                                                           (not (equal? (term cid_1)
                                                                        (term cid_2)))))
                                     (term θ))))
   ]

  ; default
  [(well_formed_osp any ...)
   #f]
  )

; auxiliar function of well_formed_conf:
; well_formed_theta θ_1 σ θ_2 iterates through θ_1, checking
; wf of each osp in θ_1, with respect to the information in σ
; and θ_2 (original θ store)
(define-metafunction  ext-lang
  well_formed_theta : θ σ θ -> any
  
  [(well_formed_theta () σ θ)
   #t]

  [(well_formed_theta (osp_1 osp_2 ...) σ θ)
   (well_formed_theta (osp_2 ...) σ θ)

   (side-condition (term (well_formed_osp osp_1 σ θ)))]

  [(well_formed_theta _ _ _)
   #f])

; well-formedness of configurations
(define-metafunction  ext-lang
  [(well_formed_conf (σ : θ : t))
   ,(and
     (term (well_formed_sigma σ σ θ))

     (term (well_formed_theta θ σ θ))
     
     (judgment-holds
      (well_formed_term hole σ θ t)))])

(provide well_formed_conf)

; final states
; PRE : {t is well-formed, with respect to some stores}
(define-metafunction  ext-lang
  is_final_stat : s -> any
  
  [(is_final_stat (in-hole E (return v ...)))
   #t

   ; (return v ...) occurs outside of a funcall
   (side-condition (not (or (redex-match?  ext-lang
                                           (in-hole E_2 ((in-hole Elf hole)
                                                         (renv ...) RetStat))
                                           (term E))
                            
                            (redex-match?  ext-lang
                                           (in-hole E_2 ((in-hole Elf hole)
                                                         (renv ...) RetExp))
                                           (term E))

                            (redex-match?  ext-lang
                                           (in-hole E_2 ((in-hole Elf hole)
                                                         Break))
                                           (term E)))))]

  [(is_final_stat ($err v))
   #t]

  [(is_final_stat \;)
   #t]

  ; default
  [(is_final_stat s)
   #f]
  )

(define-metafunction  ext-lang
  is_final_conf : (σ : θ : t) -> any

  ; the concept depends only on the stat
  [(is_final_conf (σ : θ : s))
   (is_final_stat s)]

  [(is_final_conf (σ : θ : v))
   #t]
  )

(provide is_final_conf)
