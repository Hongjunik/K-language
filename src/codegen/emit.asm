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