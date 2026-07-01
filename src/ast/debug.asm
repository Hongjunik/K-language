ast_dump_root:
    mov rdi, [ast_root]
    test rdi, rdi
    jz .done
    call ast_dump_node
.done:
    ret

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

    cmp rax, AST_WHILE
    je .while_stmt

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

    ; 선언문 노드 표시
    mov dl, 'V'
    call debug_emit_char

    ; type 존재 여부 표시
    mov rax, [rdi + VAR_DECL_TYPE_ID]
    test rax, rax
    jz .no_type

    mov dl, 'T'
    call debug_emit_char
    jmp .after_type

.no_type:
    mov dl, '-'
    call debug_emit_char

.after_type:
    ; modifier 존재 여부 표시
    mov rax, [rdi + VAR_DECL_MOD_FLAGS]
    test rax, rax
    jz .no_mod

    mov dl, 'M'
    call debug_emit_char
    jmp .after_mod

.no_mod:
    mov dl, '-'
    call debug_emit_char

.after_mod:
    pop rdi

    ; 초기식(init expr) 재귀 덤프 유지
    mov rdi, [rdi + VAR_DECL_INIT_EXPR]
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

.while_stmt:
    push rdi
    mov dl, 'W'
    call debug_emit_char
    pop rdi

    push qword [rdi + NODE_B]   ; body block 저장
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