; =========================================================
; debug_emit_token_char
; 토큰 타입을 1글자 코드로 출력
;
; 출력 예:
;   V = 변수
;   P = 출력
;   I = 만약
;   T = 이면
;   W = 반복
;   D = 동안
;   A = IDENT
;   N = INT_LITERAL
;   ; ( ) { } = + - * / % > < G L E ! $ X
; =========================================================
debug_emit_token_char:
    cmp qword [debug_enabled], 0
    je .skip

    mov rax, [tok_type]
    mov dl, 'X'              ; 기본값 = ERROR

    cmp rax, TOK_EOF
    je .eof
    cmp rax, TOK_ERROR
    je .err

    cmp rax, TOK_KW_VAR
    je .kw_var
    cmp rax, TOK_KW_PRINT
    je .kw_print
    cmp rax, TOK_KW_IF
    je .kw_if
    cmp rax, TOK_KW_THEN
    je .kw_then
    cmp rax, TOK_KW_WHILE
    je .kw_while
    cmp rax, TOK_KW_DURING
    je .kw_during

    cmp rax, TOK_IDENT
    je .ident
    cmp rax, TOK_INT_LITERAL
    je .intlit

    cmp rax, TOK_SEMI
    je .semi
    cmp rax, TOK_LPAREN
    je .lparen
    cmp rax, TOK_RPAREN
    je .rparen
    cmp rax, TOK_LBRACE
    je .lbrace
    cmp rax, TOK_RBRACE
    je .rbrace

    cmp rax, TOK_ASSIGN
    je .assign
    cmp rax, TOK_PLUS
    je .plus
    cmp rax, TOK_MINUS
    je .minus
    cmp rax, TOK_STAR
    je .star
    cmp rax, TOK_SLASH
    je .slash
    cmp rax, TOK_PERCENT
    je .percent

    cmp rax, TOK_EQ
    je .eq
    cmp rax, TOK_NE
    je .ne
    cmp rax, TOK_GT
    je .gt
    cmp rax, TOK_LT
    je .lt
    cmp rax, TOK_GE
    je .ge
    cmp rax, TOK_LE
    je .le

    jmp .emit

.kw_var:
    mov dl, 'V'
    jmp .emit
.kw_print:
    mov dl, 'P'
    jmp .emit
.kw_if:
    mov dl, 'I'
    jmp .emit
.kw_then:
    mov dl, 'T'
    jmp .emit
.kw_while:
    mov dl, 'W'
    jmp .emit
.kw_during:
    mov dl, 'D'
    jmp .emit

.ident:
    mov dl, 'A'
    jmp .emit
.intlit:
    mov dl, 'N'
    jmp .emit

.semi:
    mov dl, ';'
    jmp .emit
.lparen:
    mov dl, '('
    jmp .emit
.rparen:
    mov dl, ')'
    jmp .emit
.lbrace:
    mov dl, '{'
    jmp .emit
.rbrace:
    mov dl, '}'
    jmp .emit

.assign:
    mov dl, '='
    jmp .emit
.plus:
    mov dl, '+'
    jmp .emit
.minus:
    mov dl, '-'
    jmp .emit
.star:
    mov dl, '*'
    jmp .emit
.slash:
    mov dl, '/'
    jmp .emit
.percent:
    mov dl, '%'
    jmp .emit

.eq:
    mov dl, 'x'      ; ==
    jmp .emit
.ne:
    mov dl, 'n'
    jmp .emit
.gt:
    mov dl, '>'
    jmp .emit
.lt:
    mov dl, '<'
    jmp .emit
.ge:
    mov dl, 'G'      ; >=
    jmp .emit
.le:
    mov dl, 'L'      ; <=
    jmp .emit

.eof:
    mov dl, '$'
    jmp .emit
.err:
    mov dl, 'X'

.emit:
    mov [debug_buf], dl

    mov rax, SYS_write
    mov rdi, 2
    lea rsi, [rel debug_buf]
    mov rdx, 2
    syscall

.skip:
    ret