BITS 64

; ============================================
; x86-64 Linux syscall numbers
; ============================================
%define SYS_read         0
%define SYS_write        1
%define SYS_exit         60

; ============================================
; Token IDs
; ============================================
%define TOK_EOF          0
%define TOK_ERROR        1

%define TOK_KW_VAR       10
%define TOK_KW_PRINT     11
%define TOK_KW_IF        12
%define TOK_KW_THEN      13
%define TOK_KW_WHILE     14
%define TOK_KW_DURING    15

%define TOK_IDENT        20
%define TOK_INT_LITERAL  21

%define TOK_SEMI         30
%define TOK_LPAREN       31
%define TOK_RPAREN       32
%define TOK_LBRACE       33
%define TOK_RBRACE       34

%define TOK_ASSIGN       40
%define TOK_PLUS         41
%define TOK_MINUS        42
%define TOK_STAR         43
%define TOK_SLASH        44
%define TOK_PERCENT      45

%define TOK_EQ           50
%define TOK_NE           51
%define TOK_GT           52
%define TOK_LT           53
%define TOK_GE           54
%define TOK_LE           55

; ============================================
; AST Node IDs
; ============================================
%define AST_PROGRAM    1
%define AST_BLOCK      2
%define AST_STMT_LIST  3

%define AST_VAR_DECL   10
%define AST_PRINT      11
%define AST_IF         12

%define AST_INT        20
%define AST_IDENT      21
%define AST_UNARY      22
%define AST_BINARY     23

; --------------------------------------------
; 공통 노드 레이아웃 (48 bytes)
; --------------------------------------------
%define NODE_TYPE      0
%define NODE_A         8
%define NODE_B         16
%define NODE_C         24
%define NODE_D         32
%define NODE_E         40

%define AST_NODE_SIZE  48
%define AST_ARENA_SIZE 65536
%define CG_BUF_SIZE 65536

section .data
    ; ----------------------------------------
    ; 1차 테스트용 샘플 소스
    ; 파일 입력 대신 메모리 버퍼를 직접 토큰화한다.
    ; ----------------------------------------
    sample_src:
        db "출력 3 > 1; 출력 1 < 5; 출력 5 >= 6; 출력 3 <= 2;",0
    sample_src_len equ $ - sample_src - 1
    ; ----------------------------------------
    ; 한국어 키워드 (UTF-8 소스 파일 저장 전제)
    ; ----------------------------------------
    kw_var:        db "변수"
    kw_var_len     equ $ - kw_var

    kw_print:      db "출력"
    kw_print_len   equ $ - kw_print

    kw_if:         db "만약"
    kw_if_len      equ $ - kw_if

    kw_then:       db "이면"
    kw_then_len    equ $ - kw_then

    kw_while:      db "반복"
    kw_while_len   equ $ - kw_while

    kw_during:     db "동안"
    kw_during_len  equ $ - kw_during

    ; 디버그 출력용 버퍼: 한 글자 + 줄바꿈
    debug_buf:     db 0, 10

    ; ----------------------------------------
    ; 코드 생성 버퍼 상태
    ; ----------------------------------------
    cg_head:
;        db "BITS 64",10
;        db "global _start",10
;        db "section .bss",10
;        db "    var_values resq 64",10
;        db "section .text",10
;        db "_start:",10,0

        db "BITS 64",10
        db "global _start",10
        db "section .text",10
        db "_start:",10,0

    cg_exit:
        db "    mov rax, 60",10
        db "    xor rdi, rdi",10
        db "    syscall",10,10,0

    cg_mov_rax:         db "    mov rax, ",0
    cg_push_rax:        db "    push rax",10,0
    cg_pop_rcx:         db "    pop rcx",10,0
    cg_add_rax_rcx:    db "    add rax, rcx",10,0
    cg_neg_rax:         db "    neg rax",10,0
    cg_mov_rbx_rax:     db "    mov rbx, rax",10,0
    cg_pop_rax:         db "    pop rax",10,0
    cg_sub_rax_rbx:     db "    sub rax, rbx",10,0
    cg_imul_rax_rcx:    db "    imul rax, rcx",10,0
    cg_cqo:             db "    cqo",10,0
    cg_idiv_rbx:        db "    idiv rbx",10,0
    cg_mov_rax_rdx:     db "    mov rax, rdx",10,0

    cg_cmp_rax_rbx:     db "    cmp rax, rbx",10,0
    cg_mov_eax_0:       db "    mov eax, 0",10,0

    cg_sete_al:         db "    sete al",10,0
    cg_setne_al:        db "    setne al",10,0
    cg_setg_al:         db "    setg al",10,0
    cg_setl_al:         db "    setl al",10,0
    cg_setge_al:        db "    setge al",10,0
    cg_setle_al:        db "    setle al",10,0

    cg_call_print:      db "    call print_rax_nl",10,0

    ; ----------------------------------------
    ; vars-basic용 slot 이름/선언/저장/로드 helper 문자열
    ; ----------------------------------------
    cg_var_slot_prefix: db "var_slot_",0
    cg_slot_bss_tail:   db " resq 1",10,0

    cg_store_slot_head: db "    mov [rel ",0
    cg_store_slot_tail: db "], rax",10,0

    cg_load_slot_head:  db "    mov rax, [rel ",0
    cg_load_slot_tail:  db "]",10,0

;    cg_call_print:      db "    call print_rax_nl",10,0
;    cg_store_var_prefix:    db "    mov [rel var_values + ",0
;    cg_store_var_suffix:    db "], rax",10,0

;    cg_load_var_prefix:     db "    mov rax, [rel var_values + ",0
;    cg_load_var_suffix:     db "]",10,0


    cg_bss_tail:
        db "section .bss",10
        db "    print_buf resb 32",10,0

    cg_runtime:
        db "print_rax_nl:",10
        db "    push rbx",10
        db "    push rcx",10
        db "    push rdx",10
        db "    push rsi",10
        db "    push rdi",10
        db "    xor r8, r8",10
        db "    cmp rax, 0",10
        db "    jge .prepare",10
        db "    mov r8, 1",10
        db "    neg rax",10
        db ".prepare:",10
        db "    lea rsi, [rel print_buf + 31]",10
        db "    mov byte [rsi], 10",10
        db "    mov rcx, 1",10
        db "    mov rbx, 10",10
        db "    cmp rax, 0",10
        db "    jne .loop",10
        db "    dec rsi",10
        db "    mov byte [rsi], '0'",10
        db "    inc rcx",10
        db "    jmp .after_digits",10
        db ".loop:",10
        db "    xor rdx, rdx",10
        db "    div rbx",10
        db "    add dl, '0'",10
        db "    dec rsi",10
        db "    mov [rsi], dl",10
        db "    inc rcx",10
        db "    test rax, rax",10
        db "    jne .loop",10
        db ".after_digits:",10
        db "    test r8, r8",10
        db "    jz .write",10
        db "    dec rsi",10
        db "    mov byte [rsi], '-'",10
        db "    inc rcx",10
        db ".write:",10
        db "    mov rax, 1",10
        db "    mov rdi, 1",10
        db "    mov rdx, rcx",10
        db "    syscall",10
        db "    pop rdi",10
        db "    pop rsi",10
        db "    pop rdx",10
        db "    pop rcx",10
        db "    pop rbx",10
        db "    ret",10,0

section .bss
    ; ----------------------------------------
    ; 렉서 상태
    ; ----------------------------------------
    cur_off         resq 1    ; 현재 읽는 바이트 오프셋
    cur_line        resq 1    ; 현재 줄 번호 (1부터 시작)
    cur_col         resq 1    ; 현재 열 번호 (v0에서는 바이트 기준)

    tok_type        resq 1
    tok_start       resq 1    ; sample_src 기준 시작 오프셋
    tok_len         resq 1    ; 토큰 길이(바이트)
    tok_int_value   resq 1    ; INT_LITERAL일 때만 사용

    lex_error_code  resq 1

    ; ----------------------------------------
    ; AST 상태
    ; ----------------------------------------
    ast_arena       resb AST_ARENA_SIZE
    ast_arena_end:
    ast_top         resq 1
    ast_root        resq 1

    ; ----------------------------------------
    ; 코드 생성 버퍼 상태
    ; ----------------------------------------
    cg_buf          resb CG_BUF_SIZE
    cg_buf_end:
    cg_top          resq 1
    cg_num_tmp      resb 32

    ; debug 출력 on/off
    debug_enabled   resq 1

     ; ----------------------------------------
    ; vars-basic 심볼 테이블
    ; 이름은 sample_src 기준 offset + len 으로 저장한다.
    ; slot 번호는 심볼 인덱스와 동일하게 쓴다.
    ; ----------------------------------------
    sysm_count      resq 1
    sys_name_offs   resq 64
    sys_name_lens   resq 64
    

section .text
    global _start

; =========================================================
; 프로그램 시작점
; =========================================================
_start:
    call lexer_init
    call ast_init
    mov qword [debug_enabled], 0
    call parse_program
    mov [ast_root], rax

    call cg_init
    mov rdi, [ast_root]
    call gen_program
    call cg_flush

    mov rax, SYS_exit
    xor rdi, rdi
    syscall

;.lex_loop:
;    call next_token
;    call debug_emit_token_char

;    mov rax, [tok_type]
;    cmp rax, TOK_EOF
;    je .done
;    cmp rax, TOK_ERROR
;    je .done
;    jmp .lex_loop

.done:
    mov rax, SYS_exit
    xor rdi, rdi
    syscall

; =========================================================
; lexer_init
; 초기 상태 설정
; =========================================================
lexer_init:
    xor rax, rax
    mov [cur_off], rax
    mov [tok_type], rax
    mov [tok_start], rax
    mov [tok_len], rax
    mov [tok_int_value], rax
    mov [lex_error_code], rax
    mov [sysm_count], rax

    mov qword [cur_line], 1
    mov qword [cur_col], 1
    ret

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
; 입력:
;   rdi = ident start
;   rsi = ident len
;   rdx = init expr ptr
; 출력:
;   rax = 노드 포인터
; =========================================================
make_var_decl_node:
    push rdi
    push rsi
    push rdx

    call ast_alloc
    
    pop rdx
    pop rsi
    pop rdi

    mov qword [rax + NODE_TYPE], AST_VAR_DECL
    mov [rax + NODE_A], rdi
    mov [rax + NODE_B], rsi
    mov [rax + NODE_C], rdx
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
    lea rax, [rel ast_arena]
    mov [ast_top], rax
    mov qword [ast_root], 0
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

ast_dump_root:
    mov rdi, [ast_root]
    test rdi, rdi
    jz .done
    call ast_dump_node
.done:
    ret

cg_init:
    lea rax, [rel cg_buf]
    mov [cg_top], rax
    ret

cg_emit_byte:
    ; 주의: cg_emit_u64_dec가 r8을 자릿수 카운터로 사용하므로
    ; 여기서 r8을 덮어쓰면 숫자 출력 루프가 망가진다.
    ; 따라서 r8은 보존한다.
    push r8

    mov rax, [cg_top]
    lea rcx, [rax + 1]
    lea r8, [rel cg_buf_end]

    cmp rcx, r8
    ja cg_oom

    mov [rax], dl
    mov [cg_top], rcx

    pop r8
    ret

cg_emit_str:
.loop:
    mov al, [rdi]
    test al, al
    jz .done

    mov dl, al
    call cg_emit_byte
    inc rdi
    jmp .loop

.done:
    ret

cg_emit_nl:
    mov dl, 10
    call cg_emit_byte
    ret

cg_emit_u64_dec:
    push rbx
    push rsi
    push r8

    lea rsi, [rel cg_num_tmp + 31]
    xor r8, r8
    mov rbx, 10

    cmp rax, 0
    jne .loop

    dec rsi
    mov byte [rsi], '0'
    mov r8, 1
    jmp .emit

.loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    inc r8
    test rax, rax
    jne .loop

.emit:
    cmp r8, 0
    je .done_emit

    mov dl, [rsi]
    call cg_emit_byte
    inc rsi
    dec r8
    jmp .emit

.done_emit:
    pop r8
    pop rsi
    pop rbx
    ret

; =========================================================
; cg_emit_slot_symbol_name
; 입력:
;   rax = slot 번호 (값)
; 출력:
;   generated assembly에 "var_slot_<slot>" 문자열을 추가
; =========================================================
cg_emit_slot_symbol_name:
    push rax

    lea rdi, [rel cg_var_slot_prefix]
    call cg_emit_str

    pop rax
    call cg_emit_u64_dec
    ret

; =========================================================
; cg_emit_slot_bss_decl
; 입력:
;   rax = slot 번호 (값)
; 출력:
;   generated assembly에
;       var_slot_<slot> resq 1
;   한 줄을 추가
; =========================================================
cg_emit_slot_bss_decl:
    push rax

    ; 들여쓰기 4칸
    mov dl, ' '
    call cg_emit_byte
    mov dl, ' '
    call cg_emit_byte
    mov dl, ' '
    call cg_emit_byte
    mov dl, ' '
    call cg_emit_byte

    pop rax
    call cg_emit_slot_symbol_name

    lea rdi, [rel cg_slot_bss_tail]
    call cg_emit_str
    ret

; =========================================================
; cg_emit_slot_store_rax
; 입력:
;   rax = slot 번호 (값)
; 출력:
;   generated assembly에
;       mov [rel var_slot_<slot>], rax
;   한 줄을 추가
; =========================================================
cg_emit_slot_store_rax:
    push rax

    lea rdi, [rel cg_store_slot_head]
    call cg_emit_str

    pop rax
    call cg_emit_slot_symbol_name

    lea rdi, [rel cg_store_slot_tail]
    call cg_emit_str
    ret

; =========================================================
; cg_emit_slot_load_rax
; 입력:
;   rax = slot 번호 (값)
; 출력:
;   generated assembly에
;       mov rax, [rel var_slot_<slot>]
;   한 줄을 추가
; =========================================================
cg_emit_slot_load_rax:
    push rax

    lea rdi, [rel cg_load_slot_head]
    call cg_emit_str

    pop rax
    call cg_emit_slot_symbol_name

    lea rdi, [rel cg_load_slot_tail]
    call cg_emit_str
    ret

cg_flush:
    lea rsi, [rel cg_buf]
    mov rdx, [cg_top]
    sub rdx, rsi

    mov rax, SYS_write
    mov rdi, 1
    syscall
    ret

cg_oom:
    mov byte [debug_buf], 'G'
    mov rax, SYS_write
    mov rdi, 2
    lea rsi, [rel debug_buf]
    mov rdx, 2
    syscall

    mov rax, SYS_exit
    mov rdi, 3
    syscall

gen_program:
    push rdi
    lea rdi, [rel cg_head]
    call cg_emit_str
    pop rdi

    mov rdi, [rdi + NODE_A]
    call gen_stmt_list

    lea rdi, [rel cg_exit]
    call cg_emit_str

    lea rdi, [rel cg_runtime]
    call cg_emit_str

    lea rdi, [rel cg_bss_tail]
    call cg_emit_str

    call cg_emit_all_slot_decls
    ret

; =========================================================
; sym_find_slot_by_name
; 입력:
;   rdi = sample_src 기준 이름 시작 offset
;   rsi = 이름 길이
; 출력:
;   rax = slot 번호, 없으면 -1
; =========================================================
sym_find_slot_by_name:
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11

    mov rcx, [sysm_count]
    xor rax, rax

.loop:
    cmp rax, rcx
    jae .not_found

    mov r8, [sys_name_lens + rax*8]
    cmp r8, rsi
    jne .next

    mov r9, [sys_name_offs + rax*8]

    lea r10, [rel sample_src]
    add r10, r9

    lea r11, [rel sample_src]
    add r11, rdi

    mov rdx, rsi
    test rdx, rdx
    jz .found

.cmp_loop:
    mov bl, [r10]
    cmp bl, [r11]
    jne .next

    inc r10
    inc r11
    dec rdx
    jne .cmp_loop

.found:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

.next:
    inc rax
    jmp .loop

.not_found:
    mov rax, -1
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

; =========================================================
; sym_intern_slot
; 입력:
;   rdi = sample_src 기준 이름 시작 offset
;   rsi = 이름 길이
; 출력:
;   rax = 기존 또는 새 slot 번호
; =========================================================
sym_intern_slot:
    push rdi
    push rsi

    call sym_find_slot_by_name
    cmp rax, -1
    jne .done_existing

    pop rsi
    pop rdi

    mov rax, [sysm_count]
    cmp rax, 64
    jae cg_fail

    mov [sys_name_offs + rax*8], rdi
    mov [sys_name_lens + rax*8], rsi

    mov rcx, rax
    inc rcx
    mov [sysm_count], rcx
    ret

.done_existing:
    add rsp, 16
    ret

; =========================================================
; cg_emit_all_slot_decls
; 출력:
;   sysm_count 개수만큼
;   var_slot_<n> resq 1
;   을 generated assembly의 .bss에 추가
; =========================================================
cg_emit_all_slot_decls:
    push rcx
    push rdx

    xor rcx, rcx
    mov rdx, [sysm_count]

.loop:
    cmp rcx, rdx
    jae .done

    mov rax, rcx
    call cg_emit_slot_bss_decl

    inc rcx
    jmp .loop

.done:
    pop rdx
    pop rcx
    ret

; =========================================================
; gen_var_decl
; 입력:
;   rdi = AST_VAR_DECL 노드 주소
; 출력:
;   generated assembly에
;   [초기식 계산] + [slot store]
;   를 추가
; =========================================================
gen_var_decl:
    push rdi

    mov rdi, [rdi + NODE_C]
    call gen_expr

    pop rdi

    mov rcx, [rdi + NODE_A]
    mov rdx, [rdi + NODE_B]
    mov rdi, rcx
    mov rsi, rdx
    call sym_intern_slot

    call cg_emit_slot_store_rax
    ret

; =========================================================
; gen_ident_load
; 입력:
;   rdi = AST_IDENT 노드 주소
; 출력:
;   generated assembly에
;   mov rax, [rel var_slot_<slot>]
;   을 추가
; =========================================================
gen_ident_load:
    mov rcx, [rdi + NODE_A]
    mov rdx, [rdi + NODE_B]
    mov rdi, rcx
    mov rsi, rdx
    call sym_find_slot_by_name

    cmp rax, -1
    je cg_fail

    call cg_emit_slot_load_rax
    ret

gen_stmt_list:
.loop:
    test rdi, rdi
    jz .done

    mov rax, [rdi + NODE_TYPE]
    cmp rax, AST_STMT_LIST
    jne cg_fail

    push qword [rdi + NODE_B]
    mov rdi, [rdi + NODE_A]
    call gen_stmt

    pop rdi
    jmp .loop

.done:
    ret

gen_stmt:
    mov rax, [rdi + NODE_TYPE]

    cmp rax, AST_VAR_DECL
    je .var_decl_stmt

    cmp rax, AST_PRINT
    je .print_stmt

    jmp cg_fail

.var_decl_stmt:
    call gen_var_decl
    ret

.print_stmt:
    call gen_print
    ret

gen_print:
    mov rdi, [rdi + NODE_A]
    call gen_expr

    lea rdi, [rel cg_call_print]
    call cg_emit_str
    ret

gen_expr:
    mov rax, [rdi + NODE_TYPE]

    cmp rax, AST_INT
    je .int_lit

    cmp rax, AST_IDENT
    je .ident

    cmp rax, AST_UNARY
    je .unary

    cmp rax, AST_BINARY
    je .binary

    jmp cg_fail

.ident:
    call gen_ident_load
    ret

.int_lit:
    push rdi
    lea rdi, [rel cg_mov_rax]
    call cg_emit_str
    pop rdi

    mov rax, [rdi + NODE_A]
    call cg_emit_u64_dec
    call cg_emit_nl
    ret

.unary:
    mov rax, [rdi + NODE_A]
    cmp rax, TOK_MINUS
    jne cg_fail

    mov rdi, [rdi + NODE_B]
    call gen_expr

    lea rdi, [rel cg_neg_rax]
    call cg_emit_str
    ret

.binary:
    push qword [rdi + NODE_C]    ; right ptr
    push qword [rdi + NODE_A]    ; op

    mov rdi, [rdi + NODE_B]      ; left
    call gen_expr

    lea rdi, [rel cg_push_rax]
    call cg_emit_str

    pop rcx                      ; op
    pop rdi                      ; right ptr

    push rcx
    call gen_expr
    pop rcx

    cmp rcx, TOK_PLUS
    je .op_plus
    cmp rcx, TOK_MINUS
    je .op_minus
    cmp rcx, TOK_STAR
    je .op_star
    cmp rcx, TOK_SLASH
    je .op_slash
    cmp rcx, TOK_PERCENT
    je .op_percent

    cmp rcx, TOK_EQ
    je .op_eq
    cmp rcx, TOK_NE
    je .op_ne
    cmp rcx, TOK_GT
    je .op_gt
    cmp rcx, TOK_LT
    je .op_lt
    cmp rcx, TOK_GE
    je .op_ge
    cmp rcx, TOK_LE
    je .op_le

    jmp cg_fail

.op_plus:
    lea rdi, [rel cg_pop_rcx]
    call cg_emit_str
    lea rdi, [rel cg_add_rax_rcx]
    call cg_emit_str
    ret

.op_minus:
    lea rdi, [rel cg_mov_rbx_rax]
    call cg_emit_str
    lea rdi, [rel cg_pop_rax]
    call cg_emit_str
    lea rdi, [rel cg_sub_rax_rbx]
    call cg_emit_str
    ret

.op_star:
    lea rdi, [rel cg_pop_rcx]
    call cg_emit_str
    lea rdi, [rel cg_imul_rax_rcx]
    call cg_emit_str
    ret

.op_slash:
    lea rdi, [rel cg_mov_rbx_rax]
    call cg_emit_str
    lea rdi, [rel cg_pop_rax]
    call cg_emit_str
    lea rdi, [rel cg_cqo]
    call cg_emit_str
    lea rdi, [rel cg_idiv_rbx]
    call cg_emit_str
    ret

.op_percent:
    lea rdi, [rel cg_mov_rbx_rax]
    call cg_emit_str
    lea rdi, [rel cg_pop_rax]
    call cg_emit_str
    lea rdi, [rel cg_cqo]
    call cg_emit_str
    lea rdi, [rel cg_idiv_rbx]
    call cg_emit_str
    lea rdi, [rel cg_mov_rax_rdx]
    call cg_emit_str
    ret

.op_eq:
    call emit_compare_eq
    ret

.op_ne:
    call emit_compare_ne
    ret

.op_gt:
    call emit_compare_gt
    ret

.op_lt:
    call emit_compare_lt
    ret

.op_ge:
    call emit_compare_ge
    ret

.op_le:
    call emit_compare_le
    ret

emit_compare_common:
    lea rdi, [rel cg_mov_rbx_rax]
    call cg_emit_str

    lea rdi, [rel cg_pop_rax]
    call cg_emit_str

    lea rdi, [rel cg_cmp_rax_rbx]
    call cg_emit_str

    lea rdi, [rel cg_mov_eax_0]
    call cg_emit_str
    ret

emit_compare_eq:
    call emit_compare_common
    lea rdi, [rel cg_sete_al]
    call cg_emit_str
    ret

emit_compare_ne:
    call emit_compare_common
    lea rdi, [rel cg_setne_al]
    call cg_emit_str
    ret

emit_compare_gt:
    call emit_compare_common
    lea rdi, [rel cg_setg_al]
    call cg_emit_str
    ret

emit_compare_lt:
    call emit_compare_common
    lea rdi, [rel cg_setl_al]
    call cg_emit_str
    ret

emit_compare_ge:
    call emit_compare_common
    lea rdi, [rel cg_setge_al]
    call cg_emit_str
    ret

emit_compare_le:
    call emit_compare_common
    lea rdi, [rel cg_setle_al]
    call cg_emit_str
    ret

cg_fail:
    mov byte [debug_buf], 'C'
    mov rax, SYS_write
    mov rdi, 2
    lea rsi, [rel debug_buf]
    mov rdx, 2
    syscall

    mov rax, SYS_exit
    mov rdi, 4
    syscall

ast_dump_node:
    test rdi, rdi
    jz .done

    mov rax, [rdi + NODE_TYPE]

    cmp rax, AST_PROGRAM
    je .program

    cmp rax, AST_BLOCK
    je .block

    cmp rax, AST_STMT_LIST
    je .stmt_list

    cmp rax, AST_VAR_DECL
    je .var_decl

    cmp rax, AST_PRINT
    je .print

    cmp rax, AST_IF
    je .if_stmt

    cmp rax, AST_INT
    je .int_lit

    cmp rax, AST_IDENT
    je .ident

    cmp rax, AST_UNARY
    je .unary

    cmp rax, AST_BINARY
    je .binary

    mov dl, '?'
    call debug_emit_char
    ret

.program:
    push rdi
    mov dl, 'P'
    call debug_emit_char
    pop rdi

    mov rdi, [rdi + NODE_A]
    call ast_dump_node
    ret

.block:
    push rdi
    mov dl, 'B'
    call debug_emit_char
    pop rdi

    mov rdi, [rdi + NODE_A]
    call ast_dump_node
    ret

.stmt_list:
    push rdi
    mov dl, 'S'
    call debug_emit_char
    pop rdi

    push qword [rdi + NODE_B]   ; next 저장
    mov rdi, [rdi + NODE_A]     ; stmt
    call ast_dump_node

    pop rdi                     ; next 복구
    call ast_dump_node
    ret

.var_decl:
    push rdi
    mov dl, 'V'
    call debug_emit_char
    pop rdi

    mov rdi, [rdi + NODE_C]     ; init expr
    call ast_dump_node
    ret

.print:
    push rdi
    mov dl, 'R'
    call debug_emit_char
    pop rdi

    mov rdi, [rdi + NODE_A]
    call ast_dump_node
    ret

.if_stmt:
    push rdi
    mov dl, 'I'
    call debug_emit_char
    pop rdi

    push qword [rdi + NODE_B]   ; then block 저장
    mov rdi, [rdi + NODE_A]     ; cond
    call ast_dump_node

    pop rdi
    call ast_dump_node
    ret

.int_lit:
    push rdi

    mov dl, 'N'
    call debug_emit_char
    pop rdi

    ret

.ident:
    push rdi

    mov dl, 'A'
    call debug_emit_char
    pop rdi
    
    ret

.unary:
    push rdi
    mov dl, 'U'
    call debug_emit_char
    pop rdi

    mov rdi, [rdi + NODE_B]
    call ast_dump_node
    ret

.binary:
    push rdi
    mov dl, 'X'
    call debug_emit_char
    pop rdi

    push qword [rdi + NODE_C]   ; right 저장
    mov rdi, [rdi + NODE_B]     ; left
    call ast_dump_node

    pop rdi
    call ast_dump_node
    ret

.done:
    ret

; =========================================================
; next_token
; 토큰 하나를 읽어서 tok_* 필드에 기록
; =========================================================
next_token:
    ; 이전 토큰 정보 초기화
    mov qword [tok_type], 0
    mov qword [tok_start], 0
    mov qword [tok_len], 0
    mov qword [tok_int_value], 0
    mov qword [lex_error_code], 0

    call skip_ws_and_comments

    ; EOF 확인
    mov rbx, [cur_off]
    cmp rbx, sample_src_len
    jae .emit_eof

    ; ----------------------------------------
    ; 1) 한국어 키워드 먼저 검사
    ; ----------------------------------------
    call try_kw_var
    test eax, eax
    jnz .done

    call try_kw_print
    test eax, eax
    jnz .done

    call try_kw_if
    test eax, eax
    jnz .done

    call try_kw_then
    test eax, eax
    jnz .done

    call try_kw_while
    test eax, eax
    jnz .done

    call try_kw_during
    test eax, eax
    jnz .done

    ; 현재 문자 로드
    lea r8, [rel sample_src]
    mov rbx, [cur_off]
    mov al, [r8 + rbx]

    ; ----------------------------------------
    ; 2) 정수 리터럴
    ; ----------------------------------------
    cmp al, '0'
    jb .check_ident
    cmp al, '9'
    jbe .lex_int

.check_ident:
    ; ----------------------------------------
    ; 3) ASCII 식별자
    ; ----------------------------------------
    call is_ident_start_al
    test eax, eax
    jnz .lex_ident

    ; 현재 문자 다시 읽기
    mov rdx, [cur_off]
    lea r8, [rel sample_src]
    mov al, [r8 + rdx]

    ; ----------------------------------------
    ; 4) 2글자 연산자 먼저
    ; ----------------------------------------
    cmp al, '='
    je .maybe_eq

    cmp al, '!'
    je .maybe_ne

    cmp al, '>'
    je .maybe_ge

    cmp al, '<'
    je .maybe_le

    ; ----------------------------------------
    ; 5) 1글자 기호 / 연산자
    ; ----------------------------------------
    cmp al, ';'
    je .emit_semi
    cmp al, '('
    je .emit_lparen
    cmp al, ')'
    je .emit_rparen
    cmp al, '{'
    je .emit_lbrace
    cmp al, '}'
    je .emit_rbrace
    cmp al, '='
    je .emit_assign
    cmp al, '+'
    je .emit_plus
    cmp al, '-'
    je .emit_minus
    cmp al, '*'
    je .emit_star
    cmp al, '/'
    je .emit_slash
    cmp al, '%'
    je .emit_percent
    cmp al, '>'
    je .emit_gt
    cmp al, '<'
    je .emit_lt

    ; ----------------------------------------
    ; 6) 알 수 없는 문자
    ; ----------------------------------------
    mov qword [tok_type], TOK_ERROR
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 1
    mov qword [lex_error_code], 1
    call advance_one
    jmp .done

.emit_eof:
    mov qword [tok_type], TOK_EOF
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 0
    jmp .done

.maybe_eq:
    mov dl, [r8 + rbx + 1]
    cmp dl, '='
    je .emit_eq
    jmp .emit_assign

.maybe_ne:
    mov dl, [r8 + rbx + 1]
    cmp dl, '='
    je .emit_ne
    mov qword [tok_type], TOK_ERROR
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 1
    mov qword [lex_error_code], 2
    call advance_one
    jmp .done

.maybe_ge:
    mov dl, [r8 + rbx + 1]
    cmp dl, '='
    je .emit_ge
    jmp .emit_gt

.maybe_le:
    mov dl, [r8 + rbx + 1]
    cmp dl, '='
    je .emit_le
    jmp .emit_lt

.lex_ident:
    call lex_identifier
    jmp .done

.lex_int:
    call lex_int_literal
    jmp .done

.emit_semi:
    mov qword [tok_type], TOK_SEMI
    jmp .advance_1

.emit_lparen:
    mov qword [tok_type], TOK_LPAREN
    jmp .advance_1

.emit_rparen:
    mov qword [tok_type], TOK_RPAREN
    jmp .advance_1

.emit_lbrace:
    mov qword [tok_type], TOK_LBRACE
    jmp .advance_1

.emit_rbrace:
    mov qword [tok_type], TOK_RBRACE
    jmp .advance_1

.emit_assign:
    mov qword [tok_type], TOK_ASSIGN
    jmp .advance_1

.emit_plus:
    mov qword [tok_type], TOK_PLUS
    jmp .advance_1

.emit_minus:
    mov qword [tok_type], TOK_MINUS
    jmp .advance_1

.emit_star:
    mov qword [tok_type], TOK_STAR
    jmp .advance_1

.emit_slash:
    mov qword [tok_type], TOK_SLASH
    jmp .advance_1

.emit_percent:
    mov qword [tok_type], TOK_PERCENT
    jmp .advance_1

.emit_gt:
    mov qword [tok_type], TOK_GT
    jmp .advance_1

.emit_lt:
    mov qword [tok_type], TOK_LT
    jmp .advance_1

.emit_eq:
    mov qword [tok_type], TOK_EQ
    jmp .advance_2

.emit_ne:
    mov qword [tok_type], TOK_NE
    jmp .advance_2

.emit_ge:
    mov qword [tok_type], TOK_GE
    jmp .advance_2

.emit_le:
    mov qword [tok_type], TOK_LE
    jmp .advance_2

.advance_1:
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 1
    call advance_one
    jmp .done

.advance_2:
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 2
    call advance_one
    call advance_one
    jmp .done

.done:
    ret

; =========================================================
; skip_ws_and_comments
; 공백 / 줄바꿈 / # 주석 건너뛰기
; =========================================================
skip_ws_and_comments:
.skip_loop:
    mov rbx, [cur_off]
    cmp rbx, sample_src_len
    jae .done

    lea r8, [rel sample_src]
    mov al, [r8 + rbx]

    ; 공백 문자
    cmp al, ' '
    je .skip_one
    cmp al, 9
    je .skip_one
    cmp al, 10
    je .skip_one
    cmp al, 13
    je .skip_one

    ; 주석 시작
    cmp al, '#'
    je .skip_comment

    jmp .done

.skip_one:
    call advance_one
    jmp .skip_loop

.skip_comment:
.comment_loop:
    mov rbx, [cur_off]
    cmp rbx, sample_src_len
    jae .done

    lea r8, [rel sample_src]
    mov al, [r8 + rbx]
    cmp al, 10
    je .skip_loop
    call advance_one
    jmp .comment_loop

.done:
    ret

; =========================================================
; advance_one
; 현재 바이트 1개 전진
; 줄바꿈이면 line++, col=1
; 아니면 col++
; =========================================================
advance_one:
    mov rbx, [cur_off]
    cmp rbx, sample_src_len
    jae .done

    lea r8, [rel sample_src]
    mov al, [r8 + rbx]

    inc rbx
    mov [cur_off], rbx

    cmp al, 10
    jne .not_newline

    mov rax, [cur_line]
    inc rax
    mov [cur_line], rax
    mov qword [cur_col], 1
    ret

.not_newline:
    mov rax, [cur_col]
    inc rax
    mov [cur_col], rax

.done:
    ret

; =========================================================
; lex_identifier
; [A-Za-z_][A-Za-z0-9_]*
; =========================================================
lex_identifier:
    mov r9, [cur_off]
    lea r10, [rel sample_src]
    add r10, r9
    xor rcx, rcx

.loop:
    mov al, [r10 + rcx]
    call is_ident_continue_al
    test eax, eax
    jz .done

    inc rcx
    jmp .loop

.done:
    mov qword [tok_type], TOK_IDENT
    mov [tok_start], r9
    mov [tok_len], rcx

    mov rax, [cur_off]
    add rax, rcx
    mov [cur_off], rax

    mov rax, [cur_col]
    add rax, rcx
    mov [cur_col], rax
    ret

; =========================================================
; lex_int_literal
; [0-9]+
; 숫자값도 tok_int_value에 누적
; =========================================================
lex_int_literal:
    mov r9, [cur_off]
    lea r10, [rel sample_src]
    add r10, r9

    xor rcx, rcx            ; 길이
    xor rax, rax            ; 숫자값

.loop:
    mov bl, [r10 + rcx]
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done

    imul rax, rax, 10
    movzx rdx, bl
    sub rdx, '0'
    add rax, rdx

    inc rcx
    jmp .loop

.done:
    mov qword [tok_type], TOK_INT_LITERAL
    mov [tok_start], r9
    mov [tok_len], rcx
    mov [tok_int_value], rax

    mov rax, [cur_off]
    add rax, rcx
    mov [cur_off], rax

    mov rax, [cur_col]
    add rax, rcx
    mov [cur_col], rax
    ret

; =========================================================
; 한국어 키워드 검사 래퍼들
; eax = 1 이면 매칭 성공, 0이면 실패
; =========================================================
try_kw_var:
    lea rdi, [rel kw_var]
    mov ecx, kw_var_len
    mov r8d, TOK_KW_VAR
    call try_match_keyword
    ret

try_kw_print:
    lea rdi, [rel kw_print]
    mov ecx, kw_print_len
    mov r8d, TOK_KW_PRINT
    call try_match_keyword
    ret

try_kw_if:
    lea rdi, [rel kw_if]
    mov ecx, kw_if_len
    mov r8d, TOK_KW_IF
    call try_match_keyword
    ret

try_kw_then:
    lea rdi, [rel kw_then]
    mov ecx, kw_then_len
    mov r8d, TOK_KW_THEN
    call try_match_keyword
    ret

try_kw_while:
    lea rdi, [rel kw_while]
    mov ecx, kw_while_len
    mov r8d, TOK_KW_WHILE
    call try_match_keyword
    ret

try_kw_during:
    lea rdi, [rel kw_during]
    mov ecx, kw_during_len
    mov r8d, TOK_KW_DURING
    call try_match_keyword
    ret

; =========================================================
; try_match_keyword
; 입력:
;   rdi = 키워드 바이트열 주소
;   rcx = 키워드 길이(바이트)
;   r8  = 토큰 ID
; 반환:
;   eax = 1(성공) / 0(실패)
; =========================================================
try_match_keyword:
    push rbx
    push r9
    push r10
    push r11

    mov r9, [cur_off]

    mov rax, r9
    add rax, rcx
    cmp rax, sample_src_len
    ja .no_match

    lea r10, [rel sample_src]
    add r10, r9              ; r10 = 현재 입력 위치 주소

    xor r11, r11
.compare_loop:
    cmp r11, rcx
    je .bytes_ok

    mov al, [r10 + r11]
    cmp al, [rdi + r11]
    jne .no_match

    inc r11
    jmp .compare_loop

.bytes_ok:
    ; 다음 바이트가 구분자여야 키워드로 인정
    mov al, [r10 + rcx]
    call is_delimiter_al
    test eax, eax
    jz .no_match

    mov [tok_type], r8
    mov [tok_start], r9
    mov [tok_len], rcx

    mov rax, [cur_off]
    add rax, rcx
    mov [cur_off], rax

    mov rax, [cur_col]
    add rax, rcx             ; v0에서는 열도 바이트 기준
    mov [cur_col], rax

    mov eax, 1
    jmp .done

.no_match:
    xor eax, eax

.done:
    pop r11
    pop r10
    pop r9
    pop rbx
    ret

; =========================================================
; is_ident_start_al
; AL이 식별자 시작 문자인지 검사
; [A-Za-z_]
; 반환: eax = 1 또는 0
; =========================================================
is_ident_start_al:
    cmp al, 'A'
    jb .check_lower
    cmp al, 'Z'
    jbe .yes

.check_lower:
    cmp al, 'a'
    jb .check_us
    cmp al, 'z'
    jbe .yes

.check_us:
    cmp al, '_'
    je .yes

    xor eax, eax
    ret

.yes:
    mov eax, 1
    ret

; =========================================================
; is_ident_continue_al
; AL이 식별자 뒤에 올 수 있는 문자인지 검사
; [A-Za-z0-9_]
; 반환: eax = 1 또는 0
; =========================================================
is_ident_continue_al:
    cmp al, 'A'
    jb .check_lower
    cmp al, 'Z'
    jbe .yes

.check_lower:
    cmp al, 'a'
    jb .check_digit
    cmp al, 'z'
    jbe .yes

.check_digit:
    cmp al, '0'
    jb .check_us
    cmp al, '9'
    jbe .yes

.check_us:
    cmp al, '_'
    je .yes

    xor eax, eax
    ret

.yes:
    mov eax, 1
    ret

; =========================================================
; is_delimiter_al
; 키워드 뒤 경계 검사
; 공백 / 줄바꿈 / 주석 / 기호 / 연산자 / 문자열 끝을 구분자로 본다.
; 반환: eax = 1 또는 0
; =========================================================
is_delimiter_al:
    cmp al, 0
    je .yes
    cmp al, ' '
    je .yes
    cmp al, 9
    je .yes
    cmp al, 10
    je .yes
    cmp al, 13
    je .yes
    cmp al, '#'
    je .yes
    cmp al, ';'
    je .yes
    cmp al, '('
    je .yes
    cmp al, ')'
    je .yes
    cmp al, '{'
    je .yes
    cmp al, '}'
    je .yes
    cmp al, '='
    je .yes
    cmp al, '+'
    je .yes
    cmp al, '-'
    je .yes
    cmp al, '*'
    je .yes
    cmp al, '/'
    je .yes
    cmp al, '%'
    je .yes
    cmp al, '>'
    je .yes
    cmp al, '<'
    je .yes
    cmp al, '!'
    je .yes

    xor eax, eax
    ret

.yes:
    mov eax, 1
    ret

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

; =========================================================
; debug_emit_char
; dl에 들어 있는 문자 1개 + 줄바꿈 출력
; =========================================================
debug_emit_char:
    cmp qword [debug_enabled], 0
    je .skip_emit

    mov [debug_buf], dl

    mov rax, SYS_write
    mov rdi, 2
    lea rsi, [rel debug_buf]
    mov rdx, 2
    syscall

.skip_emit:
    ret