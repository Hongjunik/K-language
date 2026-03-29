section .data
    ; ----------------------------------------
    ; 1차 테스트용 샘플 소스
    ; 파일 입력 대신 메모리 버퍼를 직접 토큰화한다.
    ; ----------------------------------------
    sample_src:
        db "변수 x = 7;",10
        db "출력 x;",10,10

        db "만약 (3 > 1) 이면 { 출력 100; }",10,10

        db "변수 a = 0;",10
        db "반복 (a < 3) 동안 { 출력 a; 변수 a = a + 1; }",10,10

        db "반복 (변수 i = 0; i < 3; 변수 i = i + 1) { 출력 i; }",10,0
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

    cg_test_rax_rax:    db "    test rax, rax",10,0
    cg_je_head:         db "    je ",0
    cg_if_false_prefix: db "if_false_",0
    cg_label_tail:      db ":",10,0

    cg_jmp_head:         db "    jmp ",0
    cg_while_cond_prefix: db "while_cond_",0
    cg_while_end_prefix:  db "while_end_",0

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