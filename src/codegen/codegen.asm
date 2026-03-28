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

cg_emit_if_false_label_name:
    push rax

    lea rdi, [rel cg_if_false_prefix]
    call cg_emit_str

    pop rax
    call cg_emit_u64_dec
    ret

cg_emit_if_false_jump:
    push rax

    lea rdi, [rel cg_je_head]
    call cg_emit_str

    pop rax
    call cg_emit_if_false_label_name
    call cg_emit_nl
    ret

cg_emit_if_false_decl:
    call cg_emit_if_false_label_name

    lea rdi, [rel cg_label_tail]
    call cg_emit_str
    ret

cg_emit_while_cond_label_name:
    push rax

    lea rdi, [rel cg_while_cond_prefix]
    call cg_emit_str

    pop rax
    call cg_emit_u64_dec
    ret

cg_emit_while_end_label_name:
    push rax

    lea rdi, [rel cg_while_end_prefix]
    call cg_emit_str

    pop rax
    call cg_emit_u64_dec
    ret

cg_emit_while_cond_decl:
    call cg_emit_while_cond_label_name
    lea rdi, [rel cg_label_tail]
    call cg_emit_str
    ret

cg_emit_while_end_decl:
    call cg_emit_while_end_label_name
    lea rdi, [rel cg_label_tail]
    call cg_emit_str
    ret

cg_emit_while_cond_jump:
    push rax

    lea rdi, [rel cg_jmp_head]
    call cg_emit_str

    pop rax
    call cg_emit_while_cond_label_name
    call cg_emit_nl
    ret

cg_emit_while_end_jump_zero:
    push rax

    lea rdi, [rel cg_je_head]
    call cg_emit_str

    pop rax
    call cg_emit_while_end_label_name
    call cg_emit_nl
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
; symbol helper block moved to:
;   src/codegen/symbols.asm

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

gen_block:
    mov rax, [rdi + NODE_TYPE]
    cmp rax, AST_BLOCK
    jne cg_fail

    mov rdi, [rdi + NODE_A]
    call gen_stmt_list
    ret

gen_if_stmt:
    push rdi

    ; ----------------------------------------
    ; 1) 조건식 codegen
    ; AST_IF:
    ;   NODE_A = cond ptr
    ;   NODE_B = then block ptr
    ; ----------------------------------------
    mov rdi, [rdi + NODE_A]
    call gen_expr

    ; ----------------------------------------
    ; 2) 사용할 false 라벨 번호 확보
    ; rax = label 번호 값
    ; ----------------------------------------
    mov rax, [cg_label_seq]
    inc qword [cg_label_seq]
    push rax

    ; ----------------------------------------
    ; 3) 조건이 0이면 false 라벨로 점프
    ; ----------------------------------------
    lea rdi, [rel cg_test_rax_rax]
    call cg_emit_str

    mov rax, [rsp]
    call cg_emit_if_false_jump

    ; ----------------------------------------
    ; 4) then block codegen
    ; [rsp + 8] = 원래 AST_IF 노드 주소
    ; ----------------------------------------
    mov rdi, [rsp + 8]
    mov rdi, [rdi + NODE_B]
    call gen_block

    ; ----------------------------------------
    ; 5) false 라벨 선언
    ; ----------------------------------------
    mov rax, [rsp]
    call cg_emit_if_false_decl

    add rsp, 8      ; label id 제거
    add rsp, 8      ; AST_IF ptr 제거
    ret

gen_while_stmt:
    push rdi

    ; ----------------------------------------
    ; 1) 사용할 라벨 번호 확보
    ; ----------------------------------------
    mov rax, [cg_label_seq]
    inc qword [cg_label_seq]
    push rax

    ; ----------------------------------------
    ; 2) while_cond_<n>:
    ; ----------------------------------------
    mov rax, [rsp]
    call cg_emit_while_cond_decl

    ; ----------------------------------------
    ; 3) 조건식 codegen
    ; [rsp + 8] = AST_WHILE 노드 주소
    ; NODE_A = cond ptr
    ; ----------------------------------------
    mov rdi, [rsp + 8]
    mov rdi, [rdi + NODE_A]
    call gen_expr

    lea rdi, [rel cg_test_rax_rax]
    call cg_emit_str

    ; 조건이 0이면 while_end_<n> 으로
    mov rax, [rsp]
    call cg_emit_while_end_jump_zero

    ; ----------------------------------------
    ; 4) 본문 block codegen
    ; NODE_B = body block ptr
    ; ----------------------------------------
    mov rdi, [rsp + 8]
    mov rdi, [rdi + NODE_B]
    call gen_block

    ; ----------------------------------------
    ; 5) 다시 while_cond_<n> 로 점프
    ; ----------------------------------------
    mov rax, [rsp]
    call cg_emit_while_cond_jump

    ; ----------------------------------------
    ; 6) while_end_<n>:
    ; ----------------------------------------
    mov rax, [rsp]
    call cg_emit_while_end_decl

    add rsp, 8      ; label id 제거
    add rsp, 8      ; AST_WHILE ptr 제거
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

    cmp rax, AST_BLOCK
    je .block_stmt

    cmp rax, AST_VAR_DECL
    je .var_decl_stmt

    cmp rax, AST_PRINT
    je .print_stmt

    cmp rax, AST_IF
    je .if_stmt

    cmp rax, AST_WHILE
    je .while_stmt

    jmp cg_fail

.block_stmt:
    call gen_block
    ret

.var_decl_stmt:
    call gen_var_decl
    ret

.print_stmt:
    call gen_print
    ret

.if_stmt:
    call gen_if_stmt
    ret

.while_stmt:
    call gen_while_stmt
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