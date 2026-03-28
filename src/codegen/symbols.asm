; =========================================================
; codegen symbol helpers
; 역할:
;   변수 이름(sample_src 기준 offset + len)을 slot(저장 칸) 번호로 매핑하고,
;   generated assembly의 .bss 선언을 끝부분에 추가한다.
; =========================================================

; =========================================================
; sym_find_slot_by_name
; 입력:
;   rdi = sample_src 기준 이름 시작 offset
;   rsi = 이름 길이
; 출력:
;   rax = slot 번호, 없으면 -1
; =========================================================
sym_find_slot_by_name:
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11

    mov rcx, [sysm_count]
    xor rax, rax

.loop:
    cmp rax, rcx
    jae .not_found

    mov r8, [sys_name_lens + rax*8]
    cmp r8, rsi
    jne .next

    mov r9, [sys_name_offs + rax*8]

    lea r10, [rel sample_src]
    add r10, r9

    lea r11, [rel sample_src]
    add r11, rdi

    mov rdx, rsi
    test rdx, rdx
    jz .found

.cmp_loop:
    mov bl, [r10]
    cmp bl, [r11]
    jne .next

    inc r10
    inc r11
    dec rdx
    jne .cmp_loop

.found:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

.next:
    inc rax
    jmp .loop

.not_found:
    mov rax, -1
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret


; =========================================================
; sym_intern_slot
; 입력:
;   rdi = sample_src 기준 이름 시작 offset
;   rsi = 이름 길이
; 출력:
;   rax = 기존 또는 새 slot 번호
; =========================================================
sym_intern_slot:
    push rdi
    push rsi

    call sym_find_slot_by_name
    cmp rax, -1
    jne .done_existing

    pop rsi
    pop rdi

    mov rax, [sysm_count]
    cmp rax, 64
    jae cg_fail

    mov [sys_name_offs + rax*8], rdi
    mov [sys_name_lens + rax*8], rsi

    mov rcx, rax
    inc rcx
    mov [sysm_count], rcx
    ret

.done_existing:
    add rsp, 16
    ret


; =========================================================
; cg_emit_all_slot_decls
; 출력:
;   sysm_count 개수만큼
;   var_slot_<n> resq 1
;   을 generated assembly의 .bss에 추가
; =========================================================
cg_emit_all_slot_decls:
    push rcx
    push rdx

    xor rcx, rcx

.loop:
    mov rdx, [sysm_count]
    cmp rcx, rdx
    jae .done

    mov rax, rcx
    push rcx
    call cg_emit_slot_bss_decl
    pop rcx

    inc rcx
    jmp .loop

.done:
    pop rdx
    pop rcx
    ret