; =========================================================
; parse_primary
; 기본식 ::= IDENT | INT_LITERAL | "(" 표현식 ")"
; 기존 IDENT | INT_LITERAL 에 괄호식을 추가
; =========================================================
parse_primary:
    mov rax, [tok_type]

    cmp rax, TOK_IDENT
    je .accept_ident

    cmp rax, TOK_INT_LITERAL
    je .accept_int

    cmp rax, TOK_LPAREN
    je .accept_paren

    jmp parser_error

.accept_ident:
    call debug_emit_token_char
    call make_ident_node
    push rax
    call parser_advance
    pop rax
    ret

.accept_int:
    call debug_emit_token_char
    call make_int_node
    push rax
    call parser_advance
    pop rax
    ret

.accept_paren:
    ; 괄호 시작
    mov dl, '<'
    call debug_emit_char

    call parser_advance
    call parse_expr

    push rax
    mov rdi, TOK_RPAREN
    call parser_expect

    ; 괄호 끝
    mov dl, '>'
    call debug_emit_char
    pop rax
    ret

; =========================================================
; parse_condition
; 조건식 ::= 표현식
; 기존 "기본식 비교연산자 기본식"을
; 표현식 전체로 확장
; 이름은 유지해서 기존 호출부와 일관성 유지
; =========================================================
parse_condition:
    call parse_expr
    ret

; =========================================================
; parse_expr
; 표현식 진입점
; =========================================================
parse_expr:
    call parse_equality
    ret

; =========================================================
; parse_equality
; equality ::= comparison ( (== | !=) comparison )*
; =========================================================
parse_equality:
    mov dl, 'E'
    call debug_emit_char

    call parse_comparison

.eq_loop:
    mov rcx, [tok_type]

    cmp rcx, TOK_EQ
    je .consume_rhs

    cmp rcx, TOK_NE
    je .consume_rhs

    push rax
    mov dl, 'e'
    call debug_emit_char
    pop rax
    ret

.consume_rhs:
    push rax                        ; left
    push rcx                        ; op

    call debug_emit_token_char
    call parser_advance
    call parse_comparison           ; rax = right

    mov rdx, rax
    pop rdi
    pop rsi
    call make_binary_node
    jmp .eq_loop

; =========================================================
; parse_comparison
; comparison ::= additive ( (> | < | >= | <=) additive )*
; =========================================================
parse_comparison:
    mov dl, 'C'
    call debug_emit_char

    call parse_additive

.cmp_loop:
    mov rcx, [tok_type]

    cmp rcx, TOK_GT
    je .consume_rhs

    cmp rcx, TOK_LT
    je .consume_rhs

    cmp rcx, TOK_GE
    je .consume_rhs

    cmp rcx, TOK_LE
    je .consume_rhs

    push rax
    mov dl, 'c'
    call debug_emit_char
    pop rax
    ret

.consume_rhs:
    push rax                            ; left
    push rcx                            ; op

    ; 비교연산자(>, <, >=, <=) 출력
    call debug_emit_token_char
    call parser_advance
    call parse_additive                 ; rax = right

    mov rdx, rax
    pop rdi
    pop rsi
    call make_binary_node
    jmp .cmp_loop

; =========================================================
; parse_additive
; additive ::= multiplicative ( (+ | -) multiplicative )*
; =========================================================
parse_additive:
    mov dl, '['
    call debug_emit_char

    call parse_multiplicative           ; rax = left

.add_loop:
    mov rcx, [tok_type]

    cmp rcx, TOK_PLUS
    je .consume_rhs

    cmp rcx, TOK_MINUS
    je .consume_rhs

    push rax
    mov dl, ']'
    call debug_emit_char
    pop rax
    ret

.consume_rhs:
    push rax                            ; left
    push rcx                            ; op

    ; 현재 연산자(+ -)를 찍는다
    call debug_emit_token_char
    call parser_advance
    call parse_multiplicative           ; rax = right

    mov rdx, rax
    pop rdi
    pop rsi
    call make_binary_node
    jmp .add_loop

; =========================================================
; parse_multiplicative
; multiplicative ::= unary ( (* | / | %) unary )*
; =========================================================
parse_multiplicative:
    mov dl, '{'
    call debug_emit_char

    call parse_unary            ; rax = left

.mul_loop:
    mov rcx, [tok_type]

    cmp rcx, TOK_STAR
    je .consume_rhs

    cmp rcx, TOK_SLASH
    je .consume_rhs

    cmp rcx, TOK_PERCENT
    je .consume_rhs

    push rax
    mov dl, '}'
    call debug_emit_char
    pop rax
    ret

.consume_rhs:
    push rax                    ; letft
    push rcx                    ; op

    ; 현재 연산자(* / %)를 찍는다
    call debug_emit_token_char
    call parser_advance
    call parse_unary            ; rax = right

    mov rdx, rax                ; right
    pop rdi                     ; op
    pop rsi                     ; left
    call make_binary_node       ; rax = new left
    jmp .mul_loop

; =========================================================
; parse_unary
; unary ::= "-" unary | primary
; =========================================================
parse_unary:
    mov rax, [tok_type]

    cmp rax, TOK_MINUS
    je .minus_case

    call parse_primary
    ret

.minus_case:
    mov dl, '-'
    call debug_emit_char

    call parser_advance
    call parse_unary                ; rax = child node

    mov rsi, rax
    mov rdi, TOK_MINUS
    call make_unary_node            ; rax = AST_UNARY
    ret

; =========================================================
; parse_compare_op
; 비교연산자 ::= > | < | >= | <= | == | !=
; =========================================================
;parse_compare_op:
;    mov rax, [tok_type]

;    cmp rax, TOK_GT
;    je .ok
;    cmp rax, TOK_LT
;    je .ok
;    cmp rax, TOK_GE
;    je .ok
;    cmp rax, TOK_LE
;    je .ok
;    cmp rax, TOK_EQ
;    je .ok
;    cmp rax, TOK_NE
;    je .ok

;    jmp parser_error

;.ok:
;    call parser_advance
;    ret