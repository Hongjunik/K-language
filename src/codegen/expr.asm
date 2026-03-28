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