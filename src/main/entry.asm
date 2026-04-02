section .text
    global _start

; =========================================================
; 프로그램 시작점
; =========================================================
_start:
    mov rbp, rsp

    ; argc 확인
    mov rax, [rbp]
    cmp rax, 2
    jb .use_sample_input

    ; argv[1] = 첫 번째 사용자 인자
    mov rdi, [rbp + 16]
    call input_try_use_cli_file
    test rax, rax
    jz .cli_input_fail
    jmp .input_ready

.use_sample_input:
    call input_use_sample_fallback
    jmp .input_ready

.cli_input_fail:
    mov rax, SYS_exit
    mov rdi, 1
    syscall

.input_ready:
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