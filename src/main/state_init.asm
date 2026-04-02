; =========================================================
; input_use_sample_fallback
; 기본 입력 버퍼를 sample_src 로 설정
; =========================================================
input_use_sample_fallback:
    lea rax, [rel sample_src]
    mov [src_base], rax
    mov qword [src_len], sample_src_len
    ret

; =========================================================
; input_try_use_cli_file
; 입력:
;   rdi = 파일 경로 문자열 포인터
; 출력:
;   rax = 1 이면 성공
;   rax = 0 이면 실패
; =========================================================
input_try_use_cli_file:
    ; open(path, flags=0, mode=0)
    mov rax, SYS_open
    xor rsi, rsi
    xor rdx, rdx
    syscall

    test rax, rax
    js .fail

    ; r8 = fd
    mov r8, rax

    ; read(fd, file_src_buf, 65536)
    mov rax, SYS_read
    mov rdi, r8
    lea rsi, [rel file_src_buf]
    mov rdx, 65536
    syscall

    test rax, rax
    js .read_fail

    ; r9 = bytes_read
    mov r9, rax
    mov [file_src_bytes], r9

    ; 널 종료 바이트 추가
    lea r10, [rel file_src_buf]
    mov byte [r10 + r9], 0

    ; 현재 활성 입력 버퍼로 연결
    mov [src_base], r10
    mov [src_len], r9

    ; close(fd)
    mov rax, SYS_close
    mov rdi, r8
    syscall

    mov rax, 1
    ret

.read_fail:
    ; read 실패여도 fd는 닫고 실패 반환
    mov rax, SYS_close
    mov rdi, r8
    syscall

.fail:
    xor rax, rax
    ret

; =========================================================
; lexer_init
;현재 선택된 입력 버퍼(src_base, src_len)는 유지하고,
; 렉서 / 코드생성 상태만 초기화한다.
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