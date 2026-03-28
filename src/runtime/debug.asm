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