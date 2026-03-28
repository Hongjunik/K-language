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