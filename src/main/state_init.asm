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
    mov [cg_label_seq], rax

    mov qword [cur_line], 1
    mov qword [cur_col], 1
    ret