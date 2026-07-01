; =========================================================
; parser_advance
; 다음 토큰 하나 읽기
; =========================================================
parser_advance:
    call next_token
    ret

; =========================================================
; parser_expect
; rdi = expected token
; 현재 tok_type 과 비교 후 맞으면 advance
; =========================================================
parser_expect:
    mov rax, [tok_type]
    cmp rax, rdi
    jne parser_error
    call parser_advance
    ret

; =========================================================
; parser_is_type_token
; 현재 tok_type 이 자료형 시작 토큰이면 eax = 1
; 아니면 eax = 0
; =========================================================
parser_is_type_token:
    mov rax, [tok_type]

    cmp rax, TOK_KW_BOOL
    je .yes
    cmp rax, TOK_KW_CHAR
    je .yes
    cmp rax, TOK_KW_STRING
    je .yes
    cmp rax, TOK_KW_BYTE
    je .yes
    cmp rax, TOK_KW_ADDR
    je .yes
    cmp rax, TOK_KW_VOID
    je .yes

    cmp rax, TOK_KW_INT8
    je .yes
    cmp rax, TOK_KW_INT16
    je .yes
    cmp rax, TOK_KW_INT32
    je .yes
    cmp rax, TOK_KW_INT64
    je .yes
    cmp rax, TOK_KW_INT128
    je .yes

    cmp rax, TOK_KW_FLOAT32
    je .yes
    cmp rax, TOK_KW_FLOAT64
    je .yes
    cmp rax, TOK_KW_FLOAT128
    je .yes

    xor eax, eax
    ret

.yes:
    mov eax, 1
    ret

; =========================================================
; parser_type_id_from_current_token
; 현재 tok_type 을 TYPE_* 값으로 바꾼다.
; 출력:
;   eax = TYPE_* 값
;   자료형 토큰이 아니면 TYPE_UNKNOWN(0)
; =========================================================
parser_type_id_from_current_token:
    mov rax, [tok_type]

    cmp rax, TOK_KW_BOOL
    je .bool_t
    cmp rax, TOK_KW_CHAR
    je .char_t
    cmp rax, TOK_KW_STRING
    je .string_t
    cmp rax, TOK_KW_BYTE
    je .byte_t
    cmp rax, TOK_KW_ADDR
    je .addr_t
    cmp rax, TOK_KW_VOID
    je .void_t

    cmp rax, TOK_KW_INT8
    je .int8_t
    cmp rax, TOK_KW_INT16
    je .int16_t
    cmp rax, TOK_KW_INT32
    je .int32_t
    cmp rax, TOK_KW_INT64
    je .int64_t
    cmp rax, TOK_KW_INT128
    je .int128_t

    cmp rax, TOK_KW_FLOAT32
    je .float32_t
    cmp rax, TOK_KW_FLOAT64
    je .float64_t
    cmp rax, TOK_KW_FLOAT128
    je .float128_t

    xor eax, eax
    ret

.bool_t:
    mov eax, TYPE_BOOL
    ret
.char_t:
    mov eax, TYPE_CHAR
    ret
.string_t:
    mov eax, TYPE_STRING
    ret
.byte_t:
    mov eax, TYPE_BYTE
    ret
.addr_t:
    mov eax, TYPE_ADDR
    ret
.void_t:
    mov eax, TYPE_VOID
    ret

.int8_t:
    mov eax, TYPE_INT8
    ret
.int16_t:
    mov eax, TYPE_INT16
    ret
.int32_t:
    mov eax, TYPE_INT32
    ret
.int64_t:
    mov eax, TYPE_INT64
    ret
.int128_t:
    mov eax, TYPE_INT128
    ret

.float32_t:
    mov eax, TYPE_FLOAT32
    ret
.float64_t:
    mov eax, TYPE_FLOAT64
    ret
.float128_t:
    mov eax, TYPE_FLOAT128
    ret

; =========================================================
; parser_is_decl_start
; 현재 tok_type 이 선언문 시작 토큰이면 eax = 1
; 아니면 eax = 0
; 허용:
;   변수 ...
;   상수 ...
;   무부호 ...
;   자료형 ...
; =========================================================
parser_is_decl_start:
    mov rax, [tok_type]

    cmp rax, TOK_KW_VAR
    je .yes
    cmp rax, TOK_KW_CONST
    je .yes
    cmp rax, TOK_KW_UNSIGNED
    je .yes

    call parser_is_type_token
    test eax, eax
    jnz .yes

    xor eax, eax
    ret

.yes:
    mov eax, 1
    ret

; =========================================================
; parser_consume_decl_prefix
; 선언문 앞부분 prefix 를 소비한다.
;
; 허용:
;   변수 x = ...
;   정수 x = ...
;   상수 정수 x = ...
;   무부호 정수 x = ...
;   변수 상수 정수 x = ...
;
; 현재 단계에서는 타입/수식어를 AST에 저장하지 않고
; parser 진입만 통과시키는 것이 목적이다.
; =========================================================
parser_consume_decl_prefix:
    xor ecx, ecx          ; saw_var
    xor edx, edx          ; modifier flags
    xor eax, eax          ; default TYPE_UNKNOWN

    mov rax, [tok_type]
    cmp rax, TOK_KW_VAR
    jne .mods
    mov ecx, 1
    call parser_advance

.mods:
.mod_loop:
    mov rax, [tok_type]
    cmp rax, TOK_KW_CONST
    je .eat_const
    cmp rax, TOK_KW_UNSIGNED
    je .eat_unsigned
    jmp .after_mods

.eat_const:
    or edx, MODF_CONST
    call parser_advance
    jmp .mod_loop

.eat_unsigned:
    or edx, MODF_UNSIGNED
    call parser_advance
    jmp .mod_loop

.after_mods:
    call parser_is_type_token
    test eax, eax
    jz .no_type

    call parser_type_id_from_current_token
    push rax
    push rdx
    call parser_advance
    pop rdx
    pop rax
    ret

.no_type:
    ; 과거 호환:
    ; "변수 x = ..." 는 허용
    ; 하지만 "상수 x = ..." / "무부호 x = ..." 는 금지
    test ecx, ecx
    jz parser_error

    test edx, edx
    jnz parser_error

    xor eax, eax          ; TYPE_UNKNOWN
    xor edx, edx          ; MODF_NONE
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
; 문장 ::= 선언문 | 출력문 | 조건문 | 반복문
; =========================================================
parse_stmt:
    call parser_is_decl_start
    test eax, eax
    jnz .parse_var

    mov rax, [tok_type]
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
; 선언문 ::= [변수] [상수|무부호]* [자료형] IDENT "=" 표현식 ";"
; 과거 호환:
;   변수 IDENT "=" 표현식 ";"
; =========================================================
parse_var_decl:
    sub rsp, 40

    call parser_consume_decl_prefix
    mov [rsp + 24], rax      ; type id
    mov [rsp + 32], rdx      ; modifier flags

    mov rax, [tok_type]
    cmp rax, TOK_IDENT
    jne parser_error

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
    mov rdx, [rsp + 16]
    mov rcx, [rsp + 24]
    mov r8,  [rsp + 32]
    call make_var_decl_node

    push rax
    mov dl, 'v'
    call debug_emit_char
    pop rax

    add rsp, 40
    ret

; =========================================================
; 세미콜론 없는 선언문
; for-like 헤더의 init / update 용
; =========================================================
parse_var_decl_no_semi:
    sub rsp, 40

    call parser_consume_decl_prefix
    mov [rsp + 24], rax      ; type id
    mov [rsp + 32], rdx      ; modifier flags

    mov rax, [tok_type]
    cmp rax, TOK_IDENT
    jne parser_error

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
    mov rcx, [rsp + 24]
    mov r8,  [rsp + 32]
    call make_var_decl_node

    add rsp, 40
    ret

; =========================================================
; 출력문 ::= "출력" 표현식 ";"
; =========================================================
parse_print_stmt:
    mov rdi, TOK_KW_PRINT
    call parser_expect

    call parse_expr
    push rax

    mov rdi, TOK_SEMI
    call parser_expect

    pop rdi
    call make_print_node
    ret

; =========================================================
; 조건문 ::= "만약" "(" 표현식 ")" "이면" 블록
; =========================================================
parse_if_stmt:
    mov rdi, TOK_KW_IF
    call parser_expect

    mov rdi, TOK_LPAREN
    call parser_expect

    call parse_expr
    push rax

    mov rdi, TOK_RPAREN
    call parser_expect

    mov rdi, TOK_KW_THEN
    call parser_expect

    call parse_block
    mov rsi, rax

    pop rdi
    call make_if_node
    ret

; =========================================================
; 반복문
; while-like:
;   반복 (조건식) 동안 { ... }
;
; for-like:
;   반복 (선언문; 조건식; 선언문) { ... }
; =========================================================
parse_repeat_stmt:
    mov rdi, TOK_KW_WHILE
    call parser_expect

    mov rdi, TOK_LPAREN
    call parser_expect

    call parser_is_decl_start
    test eax, eax
    jnz .for_candidate

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