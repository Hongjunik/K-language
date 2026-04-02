; =========================================================
; next_token
; 토큰 하나를 읽어서 tok_* 필드에 기록
; =========================================================
next_token:
    ; 이전 토큰 정보 초기화
    mov qword [tok_type], 0
    mov qword [tok_start], 0
    mov qword [tok_len], 0
    mov qword [tok_int_value], 0
    mov qword [lex_error_code], 0

    call skip_ws_and_comments

    ; EOF 확인
    mov rbx, [cur_off]
    mov rax, [src_len]
    cmp rbx, rax
    jae .emit_eof

    ; ----------------------------------------
    ; 1) 한국어 키워드 먼저 검사
    ; ----------------------------------------
    call try_kw_var
    test eax, eax
    jnz .done

    call try_kw_print
    test eax, eax
    jnz .done

    call try_kw_if
    test eax, eax
    jnz .done

    call try_kw_then
    test eax, eax
    jnz .done

    call try_kw_while
    test eax, eax
    jnz .done

    call try_kw_during
    test eax, eax
    jnz .done

    ; 현재 문자 로드
    mov r8, [src_base]
    mov rbx, [cur_off]
    mov al, [r8 + rbx]

    ; ----------------------------------------
    ; 2) 정수 리터럴
    ; ----------------------------------------
    cmp al, '0'
    jb .check_ident
    cmp al, '9'
    jbe .lex_int

.check_ident:
    ; ----------------------------------------
    ; 3) ASCII 식별자
    ; ----------------------------------------
    call is_ident_start_al
    test eax, eax
    jnz .lex_ident

    ; 현재 문자 다시 읽기
    mov rdx, [cur_off]
    mov r8, [src_base]
    mov al, [r8 + rdx]

    ; ----------------------------------------
    ; 4) 2글자 연산자 먼저
    ; ----------------------------------------
    cmp al, '='
    je .maybe_eq

    cmp al, '!'
    je .maybe_ne

    cmp al, '>'
    je .maybe_ge

    cmp al, '<'
    je .maybe_le

    ; ----------------------------------------
    ; 5) 1글자 기호 / 연산자
    ; ----------------------------------------
    cmp al, ';'
    je .emit_semi
    cmp al, '('
    je .emit_lparen
    cmp al, ')'
    je .emit_rparen
    cmp al, '{'
    je .emit_lbrace
    cmp al, '}'
    je .emit_rbrace
    cmp al, '='
    je .emit_assign
    cmp al, '+'
    je .emit_plus
    cmp al, '-'
    je .emit_minus
    cmp al, '*'
    je .emit_star
    cmp al, '/'
    je .emit_slash
    cmp al, '%'
    je .emit_percent
    cmp al, '>'
    je .emit_gt
    cmp al, '<'
    je .emit_lt

    ; ----------------------------------------
    ; 6) 알 수 없는 문자
    ; ----------------------------------------
    mov qword [tok_type], TOK_ERROR
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 1
    mov qword [lex_error_code], 1
    call advance_one
    jmp .done

.emit_eof:
    mov qword [tok_type], TOK_EOF
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 0
    jmp .done

.maybe_eq:
    mov dl, [r8 + rbx + 1]
    cmp dl, '='
    je .emit_eq
    jmp .emit_assign

.maybe_ne:
    mov dl, [r8 + rbx + 1]
    cmp dl, '='
    je .emit_ne
    mov qword [tok_type], TOK_ERROR
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 1
    mov qword [lex_error_code], 2
    call advance_one
    jmp .done

.maybe_ge:
    mov dl, [r8 + rbx + 1]
    cmp dl, '='
    je .emit_ge
    jmp .emit_gt

.maybe_le:
    mov dl, [r8 + rbx + 1]
    cmp dl, '='
    je .emit_le
    jmp .emit_lt

.lex_ident:
    call lex_identifier
    jmp .done

.lex_int:
    call lex_int_literal
    jmp .done

.emit_semi:
    mov qword [tok_type], TOK_SEMI
    jmp .advance_1

.emit_lparen:
    mov qword [tok_type], TOK_LPAREN
    jmp .advance_1

.emit_rparen:
    mov qword [tok_type], TOK_RPAREN
    jmp .advance_1

.emit_lbrace:
    mov qword [tok_type], TOK_LBRACE
    jmp .advance_1

.emit_rbrace:
    mov qword [tok_type], TOK_RBRACE
    jmp .advance_1

.emit_assign:
    mov qword [tok_type], TOK_ASSIGN
    jmp .advance_1

.emit_plus:
    mov qword [tok_type], TOK_PLUS
    jmp .advance_1

.emit_minus:
    mov qword [tok_type], TOK_MINUS
    jmp .advance_1

.emit_star:
    mov qword [tok_type], TOK_STAR
    jmp .advance_1

.emit_slash:
    mov qword [tok_type], TOK_SLASH
    jmp .advance_1

.emit_percent:
    mov qword [tok_type], TOK_PERCENT
    jmp .advance_1

.emit_gt:
    mov qword [tok_type], TOK_GT
    jmp .advance_1

.emit_lt:
    mov qword [tok_type], TOK_LT
    jmp .advance_1

.emit_eq:
    mov qword [tok_type], TOK_EQ
    jmp .advance_2

.emit_ne:
    mov qword [tok_type], TOK_NE
    jmp .advance_2

.emit_ge:
    mov qword [tok_type], TOK_GE
    jmp .advance_2

.emit_le:
    mov qword [tok_type], TOK_LE
    jmp .advance_2

.advance_1:
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 1
    call advance_one
    jmp .done

.advance_2:
    mov rax, [cur_off]
    mov [tok_start], rax
    mov qword [tok_len], 2
    call advance_one
    call advance_one
    jmp .done

.done:
    ret

; =========================================================
; skip_ws_and_comments
; 공백 / 줄바꿈 / # 주석 건너뛰기
; =========================================================
skip_ws_and_comments:
.skip_loop:
    mov rbx, [cur_off]
    mov rax, [src_len]
    cmp rbx, rax
    jae .done

    mov r8, [src_base]
    mov al, [r8 + rbx]

    cmp al, ' '
    je .skip_one
    cmp al, 9
    je .skip_one
    cmp al, 10
    je .skip_one
    cmp al, 13
    je .skip_one

    cmp al, '#'
    je .skip_comment

    jmp .done

.skip_one:
    call advance_one
    jmp .skip_loop

.skip_comment:
.comment_loop:
    mov rbx, [cur_off]
    mov rax, [src_len]
    cmp rbx, rax
    jae .done

    mov r8, [src_base]
    mov al, [r8 + rbx]
    cmp al, 10
    je .skip_loop

    call advance_one
    jmp .comment_loop

.done:
    ret

; =========================================================
; advance_one
; 현재 바이트 1개 전진
; 줄바꿈이면 line++, col=1
; 아니면 col++
; =========================================================
advance_one:
    mov rbx, [cur_off]
    mov rax, [src_len]
    cmp rbx, rax
    jae .done

    mov r8, [src_base]
    mov al, [r8 + rbx]

    inc rbx
    mov [cur_off], rbx

    cmp al, 10
    jne .not_newline

    mov rax, [cur_line]
    inc rax
    mov [cur_line], rax
    mov qword [cur_col], 1
    ret

.not_newline:
    mov rax, [cur_col]
    inc rax
    mov [cur_col], rax

.done:
    ret

; =========================================================
; lex_identifier
; [A-Za-z_][A-Za-z0-9_]*
; =========================================================
lex_identifier:
    mov r9, [cur_off]
    mov r10, [src_base]
    add r10, r9
    xor rcx, rcx

.loop:
    mov al, [r10 + rcx]
    call is_ident_continue_al
    test eax, eax
    jz .done

    inc rcx
    jmp .loop

.done:
    mov qword [tok_type], TOK_IDENT
    mov [tok_start], r9
    mov [tok_len], rcx

    mov rax, [cur_off]
    add rax, rcx
    mov [cur_off], rax

    mov rax, [cur_col]
    add rax, rcx
    mov [cur_col], rax
    ret

; =========================================================
; lex_int_literal
; [0-9]+
; 숫자값도 tok_int_value에 누적
; =========================================================
lex_int_literal:
    mov r9, [cur_off]
    mov r10, [src_base]
    add r10, r9

    xor rcx, rcx            ; 길이
    xor rax, rax            ; 숫자값

.loop:
    mov bl, [r10 + rcx]
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done

    imul rax, rax, 10
    movzx rdx, bl
    sub rdx, '0'
    add rax, rdx

    inc rcx
    jmp .loop

.done:
    mov qword [tok_type], TOK_INT_LITERAL
    mov [tok_start], r9
    mov [tok_len], rcx
    mov [tok_int_value], rax

    mov rax, [cur_off]
    add rax, rcx
    mov [cur_off], rax

    mov rax, [cur_col]
    add rax, rcx
    mov [cur_col], rax
    ret

; =========================================================
; 한국어 키워드 검사 래퍼들
; eax = 1 이면 매칭 성공, 0이면 실패
; =========================================================
try_kw_var:
    lea rdi, [rel kw_var]
    mov ecx, kw_var_len
    mov r8d, TOK_KW_VAR
    call try_match_keyword
    ret

try_kw_print:
    lea rdi, [rel kw_print]
    mov ecx, kw_print_len
    mov r8d, TOK_KW_PRINT
    call try_match_keyword
    ret

try_kw_if:
    lea rdi, [rel kw_if]
    mov ecx, kw_if_len
    mov r8d, TOK_KW_IF
    call try_match_keyword
    ret

try_kw_then:
    lea rdi, [rel kw_then]
    mov ecx, kw_then_len
    mov r8d, TOK_KW_THEN
    call try_match_keyword
    ret

try_kw_while:
    lea rdi, [rel kw_while]
    mov ecx, kw_while_len
    mov r8d, TOK_KW_WHILE
    call try_match_keyword
    ret

try_kw_during:
    lea rdi, [rel kw_during]
    mov ecx, kw_during_len
    mov r8d, TOK_KW_DURING
    call try_match_keyword
    ret

; =========================================================
; try_match_keyword
; 입력:
;   rdi = 키워드 바이트열 주소
;   rcx = 키워드 길이(바이트)
;   r8  = 토큰 ID
; 반환:
;   eax = 1(성공) / 0(실패)
; =========================================================
try_match_keyword:
    push rbx
    push r9
    push r10
    push r11

    mov r9, [cur_off]

    mov rax, r9
    add rax, rcx
    mov rdx, [src_len]
    cmp rax, rdx
    ja .no_match

    mov r10, [src_base]
    add r10, r9              ; r10 = 현재 입력 위치 주소

    xor r11, r11
.compare_loop:
    cmp r11, rcx
    je .bytes_ok

    mov al, [r10 + r11]
    cmp al, [rdi + r11]
    jne .no_match

    inc r11
    jmp .compare_loop

.bytes_ok:
    ; 다음 바이트가 구분자여야 키워드로 인정
    mov al, [r10 + rcx]
    call is_delimiter_al
    test eax, eax
    jz .no_match

    mov [tok_type], r8
    mov [tok_start], r9
    mov [tok_len], rcx

    mov rax, [cur_off]
    add rax, rcx
    mov [cur_off], rax

    mov rax, [cur_col]
    add rax, rcx             ; v0에서는 열도 바이트 기준
    mov [cur_col], rax

    mov eax, 1
    jmp .done

.no_match:
    xor eax, eax

.done:
    pop r11
    pop r10
    pop r9
    pop rbx
    ret

; =========================================================
; is_ident_start_al
; AL이 식별자 시작 문자인지 검사
; [A-Za-z_]
; 반환: eax = 1 또는 0
; =========================================================
is_ident_start_al:
    cmp al, 'A'
    jb .check_lower
    cmp al, 'Z'
    jbe .yes

.check_lower:
    cmp al, 'a'
    jb .check_us
    cmp al, 'z'
    jbe .yes

.check_us:
    cmp al, '_'
    je .yes

    xor eax, eax
    ret

.yes:
    mov eax, 1
    ret

; =========================================================
; is_ident_continue_al
; AL이 식별자 뒤에 올 수 있는 문자인지 검사
; [A-Za-z0-9_]
; 반환: eax = 1 또는 0
; =========================================================
is_ident_continue_al:
    cmp al, 'A'
    jb .check_lower
    cmp al, 'Z'
    jbe .yes

.check_lower:
    cmp al, 'a'
    jb .check_digit
    cmp al, 'z'
    jbe .yes

.check_digit:
    cmp al, '0'
    jb .check_us
    cmp al, '9'
    jbe .yes

.check_us:
    cmp al, '_'
    je .yes

    xor eax, eax
    ret

.yes:
    mov eax, 1
    ret

; =========================================================
; is_delimiter_al
; 키워드 뒤 경계 검사
; 공백 / 줄바꿈 / 주석 / 기호 / 연산자 / 문자열 끝을 구분자로 본다.
; 반환: eax = 1 또는 0
; =========================================================
is_delimiter_al:
    cmp al, 0
    je .yes
    cmp al, ' '
    je .yes
    cmp al, 9
    je .yes
    cmp al, 10
    je .yes
    cmp al, 13
    je .yes
    cmp al, '#'
    je .yes
    cmp al, ';'
    je .yes
    cmp al, '('
    je .yes
    cmp al, ')'
    je .yes
    cmp al, '{'
    je .yes
    cmp al, '}'
    je .yes
    cmp al, '='
    je .yes
    cmp al, '+'
    je .yes
    cmp al, '-'
    je .yes
    cmp al, '*'
    je .yes
    cmp al, '/'
    je .yes
    cmp al, '%'
    je .yes
    cmp al, '>'
    je .yes
    cmp al, '<'
    je .yes
    cmp al, '!'
    je .yes

    xor eax, eax
    ret

.yes:
    mov eax, 1
    ret