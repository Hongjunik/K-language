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