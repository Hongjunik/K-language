; =========================================================
; make_int_node
; 현재 tok_int_value를 AST_INT 노드로 만든다.
; 출력: rax = 노드 포인터
; =========================================================
make_int_node:
    push rcx

    call ast_alloc

    pop rcx

    mov qword [rax + NODE_TYPE], AST_INT
    mov rcx, [tok_int_value]
    mov [rax + NODE_A], rcx
    ret

; =========================================================
; make_ident_node
; 현재 tok_start, tok_len을 AST_IDENT 노드로 만든다.
; 출력: rax = 노드 포인터
; =========================================================
make_ident_node:
    push rcx
    push rdx

    call ast_alloc

    pop rdx
    pop rcx

    mov qword [rax + NODE_TYPE], AST_IDENT
    mov rcx, [tok_start]
    mov rdx, [tok_len]
    mov [rax + NODE_A], rcx
    mov [rax + NODE_B], rdx
    ret

; =========================================================
; make_unary_node
; 입력:
;   rdi = 연산자 토큰 (예: TOK_MINUS)
;   rsi = child ptr
; 출력:
;   rax = 노드 포인터
; =========================================================
make_unary_node:
    push rdi
    push rsi

    call ast_alloc

    pop rsi
    pop rdi

    mov qword [rax + NODE_TYPE], AST_UNARY
    mov [rax + NODE_A], rdi
    mov [rax + NODE_B], rsi
    ret

; =========================================================
; make_binary_node
; 입력:
;   rdi = 연산자 토큰
;   rsi = left ptr
;   rdx = right ptr
; 출력:
;   rax = 노드 포인터
; =========================================================
make_binary_node:
    push rdi
    push rsi
    push rdx

    call ast_alloc

    pop rdx
    pop rsi
    pop rdi

    mov qword [rax + NODE_TYPE], AST_BINARY
    mov [rax + NODE_A], rdi
    mov [rax + NODE_B], rsi
    mov [rax + NODE_C], rdx
    ret

; =========================================================
; make_print_node
; 입력:
;   rdi = expr ptr
; 출력:
;   rax = 노드 포인터
; =========================================================
make_print_node:
    push rdi

    call ast_alloc

    pop rdi
    mov qword [rax + NODE_TYPE], AST_PRINT
    mov [rax + NODE_A], rdi
    ret

; =========================================================
; make_var_decl_node
;
; 입력:
;   rdi = ident start offset
;   rsi = ident len
;   rdx = init expr ptr
;   rcx = type id
;   r8  = modifier flags
;
; 출력:
;   rax = 노드 포인터
; =========================================================
make_var_decl_node:
    push rdi
    push rsi
    push rdx
    push rcx
    push r8

    call ast_alloc

    pop r8
    pop rcx
    pop rdx
    pop rsi
    pop rdi

    mov qword [rax + NODE_TYPE], AST_VAR_DECL
    mov [rax + VAR_DECL_NAME_OFF],  rdi
    mov [rax + VAR_DECL_NAME_LEN],  rsi
    mov [rax + VAR_DECL_INIT_EXPR], rdx
    mov [rax + VAR_DECL_TYPE_ID],   rcx
    mov [rax + VAR_DECL_MOD_FLAGS], r8
    ret

; =========================================================
; make_if_node
; 입력:
;   rdi = cond ptr
;   rsi = then block ptr
; 출력:
;   rax = 노드 포인터
; =========================================================
make_if_node:
    push rdi
    push rsi

    call ast_alloc

    pop rsi
    pop rdi

    mov qword [rax + NODE_TYPE], AST_IF
    mov [rax + NODE_A], rdi
    mov [rax + NODE_B], rsi
    ret

; =========================================================
; make_while_node
; 입력:
;   rdi = cond ptr
;   rsi = body block ptr
; 출력:
;   rax = 노드 포인터
; =========================================================
make_while_node:
    push rdi
    push rsi

    call ast_alloc

    pop rsi
    pop rdi

    mov qword [rax + NODE_TYPE], AST_WHILE
    mov [rax + NODE_A], rdi
    mov [rax + NODE_B], rsi
    ret

; =========================================================
; make_stmt_list_node
; 입력:
;   rdi = stmt ptr
;   rsi = next ptr
; 출력:
;   rax = 노드 포인터
; =========================================================
make_stmt_list_node:
    push rdi
    push rsi

    call ast_alloc

    pop rsi
    pop rdi

    mov qword [rax + NODE_TYPE], AST_STMT_LIST
    mov [rax + NODE_A], rdi
    mov [rax + NODE_B], rsi
    ret

; =========================================================
; make_block_node
; 입력:
;   rdi = stmt_list head ptr
; 출력:
;   rax = 노드 포인터
; =========================================================
make_block_node:
    push rdi

    call ast_alloc

    pop rdi

    mov qword [rax + NODE_TYPE], AST_BLOCK
    mov [rax + NODE_A], rdi
    ret

; =========================================================
; block_append_stmt
; 입력:
;   rdi = AST_BLOCK ptr
;   rsi = stmt ptr
; 출력:
;   rax = same AST_BLOCK ptr
; =========================================================
block_append_stmt:
    push rdi
    push rsi

    ; 새 stmt_list 노드 생성: (stmt, next=0)
    mov rdi, rsi
    xor rsi, rsi
    call make_stmt_list_node
    mov r8, rax

    pop rsi
    pop rdi

    mov rcx, [rdi + NODE_A]
    test rcx, rcx
    jnz .append_to_tail

    ; 빈 block이면 head에 바로 연결
    mov [rdi + NODE_A], r8
    mov rax, rdi
    ret

.append_to_tail:
.walk:
    mov rdx, [rcx + NODE_B]
    test rdx, rdx
    jz .link_here

    mov rcx, rdx
    jmp .walk

.link_here:
    mov [rcx + NODE_B], r8
    mov rax, rdi
    ret

; =========================================================
; make_program_node
; 입력:
;   rdi = stmt_list head ptr
; 출력:
;   rax = 노드 포인터
; =========================================================
make_program_node:
    push rdi

    call ast_alloc

    pop rdi

    mov qword [rax + NODE_TYPE], AST_PROGRAM
    mov [rax + NODE_A], rdi
    ret

; =========================================================
; ast_init
; AST arena 초기화
; =========================================================
ast_init:
    ; [데이터 이동] rax <- RIP ast_arena(AST_ARENA_SIZE 65536 byte)
    ; [기능] rax에 현재 실행 중인 코드를 기준으로
    ; 오프셋을 계산한 절대 주소를 넣는다.
    ; [추신] 즉 ast구역이 시작하는 메모리 시작 주소를 rax에 저장한다.
    lea rax, [rel ast_arena]

    ; [데이터 이동] ast_top <-(cp) rax(RIP ast_arena)
    ; [기능] AST 구역의 메모리 시작 주소를 저장한다.
    mov [ast_top], rax

    ; [데이터 이동] qword ast_root <-(cp) 0
    ; [기능] AST 루트 포인터를 NULL(0)로 초기화
    mov qword [ast_root], 0

    ; [기능] call ast_init(entry.asm)으로 리턴
    ret

; =========================================================
; ast_alloc
; 출력:
;   rax = 새 AST 노드 주소
; 공간 부족 시 ast_oom
; =========================================================
ast_alloc:
    mov rax, [ast_top]                 ; 이번에 줄 노드 시작 주소
    lea rcx, [rax + AST_NODE_SIZE]     ; 다음 top
    lea rdx, [rel ast_arena_end]       ; arena 끝

    cmp rcx, rdx
    ja  ast_oom

    mov [ast_top], rcx

    xor r8, r8
    mov [rax + NODE_TYPE], r8
    mov [rax + NODE_A],    r8
    mov [rax + NODE_B],    r8
    mov [rax + NODE_C],    r8
    mov [rax + NODE_D],    r8
    mov [rax + NODE_E],    r8
    ret

; =========================================================
; ast_oom
; AST 메모리 부족
; =========================================================
ast_oom:
    mov dl, 'M'
    call debug_emit_char

    mov rax, SYS_exit
    mov rdi, 2
    syscall