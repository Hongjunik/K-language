; =========================================================
; parser_advance
; 다음 토큰 하나 읽기
; =========================================================
parser_advance:
    call next_token
    ret

; =========================================================
; parser_expect
; 입력:
;   rdi = 기대하는 토큰 ID
; 현재 토큰이 rdi와 같으면 다음 토큰으로 이동
; 다르면 parser_error
; =========================================================
parser_expect:
    mov rax, [tok_type]
    cmp rax, rdi
    jne parser_error
    call parser_advance
    ret

; =========================================================
; parse_program
; 프로그램 ::= 문장*
; =========================================================
parse_program:
    ; 첫 토큰 준비
    call parser_advance

    sub rsp, 16
    xor rax, rax
    mov [rsp], rax
    mov [rsp + 8], rax

.parse_loop:
    mov rax, [tok_type]
    cmp rax, TOK_EOF
    je .success

    call parse_stmt

    mov rdi, rax
    xor rsi, rsi
    call make_stmt_list_node

    mov rcx, [rsp]
    test rcx, rcx
    jnz .append

    mov [rsp], rax
    mov [rsp + 8], rax
    jmp .parse_loop

.append:
    mov rcx, [rsp + 8]
    mov [rcx + NODE_B], rax
    mov [rsp + 8], rax
    jmp .parse_loop

.success:
    mov rdi, [rsp]
    call make_program_node

    mov [ast_root], rax

    push rax
    mov dl, 'O'
    call debug_emit_char
    pop rax

    add rsp, 16
    ret

; =========================================================
; parse_stmt
; 문장 ::= 변수선언문 | 출력문
; =========================================================
parse_stmt:
    mov rax, [tok_type]
    cmp rax, TOK_KW_VAR
    je .parse_var

    cmp rax, TOK_KW_PRINT
    je .parse_print

    cmp rax, TOK_KW_IF
    je .parse_if

    cmp rax, TOK_KW_WHILE
    je .parse_repeat

    jmp parser_error

.parse_var:
    call parse_var_decl
    ret

.parse_print:
    call parse_print_stmt
    ret

.parse_if:
    call parse_if_stmt
    ret

.parse_repeat:
    call parse_repeat_stmt
    ret

; =========================================================
; parse_var_decl
; 변수선언문 ::= "변수" IDENT "=" INT_LITERAL ";"
; 기존 INT_LITERAL 고정에서 parse_expr로 확장
; =========================================================
parse_var_decl:
    mov rdi, TOK_KW_VAR
    call parser_expect

    ; IDENT는 이름 정보를 저장해야 하므로 직접 처리
    mov rax, [tok_type]
    cmp rax, TOK_IDENT
    jne parser_error

    sub rsp, 24
    mov rax, [tok_start]
    mov [rsp], rax
    mov rax, [tok_len]
    mov [rsp + 8], rax

    call parser_advance

    mov rdi, TOK_ASSIGN
    call parser_expect

    call parse_expr
    mov [rsp + 16], rax

    mov rdi, TOK_SEMI
    call parser_expect

    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    mov rdx, [rsp +16]
    call make_var_decl_node              ; rax = AST_VAR_DECL

    push rax
    mov dl, 'v'
    call debug_emit_char
    pop rax

    add rsp, 24
    ret

; =========================================================
; parse_var_decl_no_semi
; for 헤더용:
;   "변수" IDENT "=" expr
; 마지막 세미콜론은 소비하지 않음
; 출력:
;   rax = AST_VAR_DECL ptr
; =========================================================
parse_var_decl_no_semi:
    mov rdi, TOK_KW_VAR
    call parser_expect

    mov rax, [tok_type]
    cmp rax, TOK_IDENT
    jne parser_error

    sub rsp, 24
    mov rax, [tok_start]
    mov [rsp], rax
    mov rax, [tok_len]
    mov [rsp + 8], rax

    call parser_advance

    mov rdi, TOK_ASSIGN
    call parser_expect

    call parse_expr
    mov [rsp + 16], rax

    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    mov rdx, [rsp + 16]
    call make_var_decl_node

    add rsp, 24
    ret

; =========================================================
; parse_print_stmt
; 출력문 ::= "출력" 기본식 ";"
; =========================================================
parse_print_stmt:
    mov rdi, TOK_KW_PRINT
    call parser_expect

    call parse_expr         ; rax = expr
    push rax

    mov rdi, TOK_SEMI
    call parser_expect

    pop rdi
    call make_print_node    ; rax = AST_PRINT

    push rax
    mov dl, 'p'
    call debug_emit_char
    pop rax
    ret

; =========================================================
; parse_if_stmt
; 만약문 ::= "만약" "(" 조건식 ")" "이면" 블록
; =========================================================
parse_if_stmt:
    mov rdi, TOK_KW_IF
    call parser_expect

    mov rdi, TOK_LPAREN
    call parser_expect

    call parse_condition            ; rax = cond
    push rax

    mov rdi, TOK_RPAREN
    call parser_expect

    mov rdi, TOK_KW_THEN
    call parser_expect

    call parse_block                ; rax = block
    mov rsi, rax
    pop rdi                         ; cond

    call make_if_node               ; rax = AST_IF

    push rax
    mov dl, 'i'
    call debug_emit_char
    pop rax
    ret

; =========================================================
; parse_repeat_stmt
;
; 현재 v02 반복문 규칙
;
; while:
;   반복 (조건식) 동안 블록
;
; for:
;   반복 (변수선언; 조건식; 변수선언) 블록
;
; 주의:
; 현재 v02에서는 for의 init/update를 변수선언형으로 제한한다.
; 따라서 첫 clause가 "변수"로 시작하면 for 후보로 처리한다.
; while은 ')' 뒤에 반드시 "동안" 이 있어야 한다.
; for는 ')' 뒤에 "동안" 이 오면 parser_error 로 거부한다.
;
; lowering result for for:
; {
;   init;
;   while (cond) {
;     body;
;     update;
;   }
; }
; =========================================================
parse_repeat_stmt:
    mov rdi, TOK_KW_WHILE         ; "반복"
    call parser_expect

    mov rdi, TOK_LPAREN
    call parser_expect

    mov rax, [tok_type]
    cmp rax, TOK_KW_VAR
    je .for_candidate

    jmp parse_repeat_while_like

.for_candidate:
    jmp parse_repeat_for_like

; =========================================================
; parse_repeat_while_like
; 입력 상태:
;   "반복" "(" 까지 이미 소비됨
;   현재 토큰은 조건식 시작 토큰
; 출력:
;   rax = AST_WHILE ptr
; =========================================================
parse_repeat_while_like:
    call parse_condition
    push rax

    mov rdi, TOK_RPAREN
    call parser_expect

    ; while은 반드시 "동안" 이 있어야 한다.
    mov rdi, TOK_KW_DURING
    call parser_expect

    call parse_block
    mov rsi, rax
    pop rdi

    call make_while_node
    ret


; =========================================================
; parse_repeat_for_like
; 입력 상태:
;   "반복" "(" 까지 이미 소비됨
;   현재 토큰은 init 변수선언 시작 토큰 ("변수")
; 출력:
;   rax = AST_BLOCK ptr
;
; lowering:
; {
;   init;
;   while (cond) {
;     body;
;     update;
;   }
; }
; =========================================================
parse_repeat_for_like:
    ; init
    call parse_var_decl_no_semi
    push rax

    mov rdi, TOK_SEMI
    call parser_expect

    ; cond
    call parse_condition
    push rax

    mov rdi, TOK_SEMI
    call parser_expect

    ; update
    call parse_var_decl_no_semi
    push rax

    mov rdi, TOK_RPAREN
    call parser_expect

    ; for에는 "동안" 금지
    mov rax, [tok_type]
    cmp rax, TOK_KW_DURING
    je parser_error

    ; body block
    call parse_block
    mov r8, rax                  ; body block ptr

    ; update를 body 끝에 append
    pop rsi                      ; update stmt ptr
    mov rdi, r8
    call block_append_stmt
    mov r8, rax                  ; updated body block ptr

    ; while(cond) { body; update; }
    pop rdi                      ; cond expr ptr
    mov rsi, r8
    call make_while_node
    mov r9, rax                  ; while stmt ptr

    ; stmt_list: while 하나
    mov rdi, r9
    xor rsi, rsi
    call make_stmt_list_node
    mov r10, rax                 ; while stmt_list ptr

    ; 바깥 block: init; while(...)
    pop rdi                      ; init stmt ptr
    mov rsi, r10
    call make_stmt_list_node
    mov rdi, rax
    call make_block_node
    ret

; =========================================================
; parse_block
; 블록 ::= "{" 문장* "}"
; =========================================================
parse_block:
    mov rdi, TOK_LBRACE
    call parser_expect

    sub rsp, 16
    xor rax, rax
    mov [rsp], rax
    mov [rsp + 8], rax

.block_loop:
    mov rax, [tok_type]
    cmp rax, TOK_RBRACE
    je .block_end

    call parse_stmt

    mov rdi, rax
    xor rsi, rsi
    call make_stmt_list_node

    mov rcx, [rsp]
    test rcx, rcx
    jnz .append

    mov [rsp], rax
    mov [rsp + 8], rax
    jmp .block_loop

.append:
    mov rcx, [rsp + 8]
    mov [rcx + NODE_B], rax
    mov [rsp + 8], rax
    jmp .block_loop

.block_end:
    mov rdi, TOK_RBRACE
    call parser_expect

    mov rdi, [rsp]
    call make_block_node

    push rax
    mov dl, 'b'
    call debug_emit_char
    pop rax

    add rsp, 16
    ret

; =========================================================
; parser_error
; 현재는 간단하게 '!' 출력 후 종료
; =========================================================
parser_error:
    mov dl, '?'
    call debug_emit_char
    call debug_emit_token_char

    mov rax, SYS_exit
    mov rdi, 1
    syscall