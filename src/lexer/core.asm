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

    ; 1byte씩 파싱하며 공백/줄바꿈을 제거
    call skip_ws_and_comments

    ; EOF 확인
    ; ==========================
    ; [데이터 이동]
    ; rbx <-(cp) cur_off
    ; rax <-(cp) src_len
    ; [연산]
    ; rbx - rax
    ; [기능]
    ; rbx <= rax이면 emit_eof로 점프한다.
    ; 파일이 끝났는지 다시 판단한다.
    ; ==========================
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

    call try_kw_const
    test eax, eax
    jnz .done

    call try_kw_unsigned
    test eax, eax
    jnz .done

    call try_kw_string
    test eax, eax
    jnz .done

    call try_kw_char
    test eax, eax
    jnz .done

    call try_kw_bool
    test eax, eax
    jnz .done

    call try_kw_byte
    test eax, eax
    jnz .done

    call try_kw_addr
    test eax, eax
    jnz .done

    call try_kw_void
    test eax, eax
    jnz .done

    call try_kw_int128
    test eax, eax
    jnz .done

    call try_kw_int64
    test eax, eax
    jnz .done

    call try_kw_int32
    test eax, eax
    jnz .done

    call try_kw_int16
    test eax, eax
    jnz .done

    call try_kw_int8
    test eax, eax
    jnz .done

    call try_kw_float128
    test eax, eax
    jnz .done

    call try_kw_float64
    test eax, eax
    jnz .done

    call try_kw_float32
    test eax, eax
    jnz .done

    call try_kw_return
    test eax, eax
    jnz .done

    call try_kw_true
    test eax, eax
    jnz .done

    call try_kw_false
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
// ANCHOR: LEXER_SKIP_WS_AND_COMMENTS_CURRENT_STRUCTURE
// NOTE: 현재 skip_ws_and_comments는 이름상 공백/주석 제거 루틴이지만,
;       내부에서 src_base + cur_off 위치의 현재 바이트를 직접 읽는다.
;       즉 "현재 바이트 읽기"와 "공백/주석 판정" 책임이 한 레이블에 섞여 있다.
;
// REVIEW: 리팩토링 시 아래 구조로 분리하는 것을 검토한다.
;         1. lexer_peek_byte:
;            - 입력:  [src_base], [cur_off]
;            - 출력:  al = byte [src_base + cur_off]
;            - 역할:  현재 위치의 1바이트만 읽고 cur_off는 바꾸지 않는다.
;
;         2. lexer_advance_byte:
;            - 입력:  [cur_off]
;            - 출력:  [cur_off] = [cur_off] + 1
;            - 역할:  현재 입력 위치를 다음 바이트로 이동한다.
;
;         3. skip_ws_and_comments:
;            - lexer_peek_byte로 현재 바이트를 확인한다.
;            - CH_SPACE / CH_TAB / CH_LF / CH_CR이면 lexer_advance_byte 후 반복한다.
;            - CH_HASH이면 주석 끝까지 이동한다.
;            - 그 외 바이트면 실제 token 시작 위치로 보고 종료한다.
;
; TODO(refactor): 공백/제어문자 비교값을 직접 숫자 9, 10, 13으로 두지 말고
;                 CH_TAB=0x09, CH_LF=0x0A, CH_CR=0x0D 같은 상수로 분리한다.
;
// NOTE: 현재 구조는 동작상 문제는 없지만, lexer가 커질수록
;       "입력 바이트 로드", "공백 판정", "주석 처리", "토큰 판정"의 경계가 흐려질 수 있다.
;       따라서 기능 추가보다 리팩토링 단계에서 책임 분리를 우선 검토한다.

skip_ws_and_comments:
.skip_loop:
    ; [데이터 이동] rbx <-(cp) cur_off(현재 오프셋)
    mov rbx, [cur_off]

    ; [데이터 이동] rax <-(cp) src_len(읽은 바이트 수)
    mov rax, [src_len]
    ; [연산] rbx(cur_off) - rax(src_len)
    ; [기능] 현재의 오프셋과 읽은 바이트 수와 비교하여
    ; 파싱이 가능한지 판단한다.
    cmp rbx, rax
    ; [기능] rbx >= rax면 .done으로 점프한다.(ZF, CF)
    jae .done

    ; [데이터 이동] r8 <-(cp) src_base(소스 버퍼 시작 주소)
    mov r8, [src_base]
    ; [데이터 이동] al <-(cp) r8(src_base) + rbx(cur_off)
    ; [기능] al에 r8 + rbx의 주소부터 8bit의 내용을 가져온다.
    mov al, [r8 + rbx]

    ; ====================================
    ; 공백 건너뛰기 부분 *유니코드 테이블 참조*
    ; ====================================
    cmp al, ' '     ; space
    je .skip_one
    cmp al, 9       ; tab
    je .skip_one
    cmp al, 10      ; LF(Line Feed) 줄 그대로 커서를 밑으로 내림
    je .skip_one
    cmp al, 13      ; CR(Carriage Return) 커서를 줄 첫부분으로 이동
    je .skip_one

    ; ===============
    ; 주석 건너뛰기 부분
    ; ===============
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

    ; [연산] rbx(cur_off)++
    inc rbx
    ; [데이터 이동] cur_off <-(cp) rbx(cur_off + 1)
    mov [cur_off], rbx

    ; [연산] al - 10
    ; [기능] 현재 바이트가 LF(new line)인지 판단한다.
    cmp al, 10
    jne .not_newline

    ; =================
    ; 줄바꿈
    ; 행 + 1 / 열 = 1
    ; =================

    ; [데이터 이동] rax <-(cp) cur_line
    mov rax, [cur_line]
    ; [연산] rax(cur_line)++
    inc rax
    ; [데이터 이동] cur_line <-(cp) rax(cur_line + 1)
    mov [cur_line], rax
    ; [데이터 이동] cur_col <-(cp) 1
    mov qword [cur_col], 1
    ret

.not_newline:
    ; ================
    ; 줄바꿈 X
    ; 열 + 1
    ; ================
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
//ANCHOR - *키워드 검사 후에 다음에 올 것을 올 수 있는게 맞는지 검사하는 단계*
try_kw_var:
    ; --------------------------------
    ; [데이터 이동]
    ; rdi <- RIP_rel kw_var(kw_var의 메모리 시작 주소)
    ; ecx <-(cp) kw_var_len
    ; r8d <-(cp) TOK_KW_VAR(10)
    ; --------------------------------
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

try_kw_const:
    lea rdi, [rel kw_const]
    mov ecx, kw_const_len
    mov r8d, TOK_KW_CONST
    call try_match_keyword
    ret

try_kw_unsigned:
    lea rdi, [rel kw_unsigned]
    mov ecx, kw_unsigned_len
    mov r8d, TOK_KW_UNSIGNED
    call try_match_keyword
    ret

try_kw_bool:
    lea rdi, [rel kw_bool]
    mov ecx, kw_bool_len
    mov r8d, TOK_KW_BOOL
    call try_match_keyword
    ret

try_kw_char:
    lea rdi, [rel kw_char]
    mov ecx, kw_char_len
    mov r8d, TOK_KW_CHAR
    call try_match_keyword
    ret

try_kw_string:
    lea rdi, [rel kw_string]
    mov ecx, kw_string_len
    mov r8d, TOK_KW_STRING
    call try_match_keyword
    ret

try_kw_byte:
    lea rdi, [rel kw_byte]
    mov ecx, kw_byte_len
    mov r8d, TOK_KW_BYTE
    call try_match_keyword
    ret

try_kw_addr:
    lea rdi, [rel kw_addr]
    mov ecx, kw_addr_len
    mov r8d, TOK_KW_ADDR
    call try_match_keyword
    ret

try_kw_void:
    lea rdi, [rel kw_void]
    mov ecx, kw_void_len
    mov r8d, TOK_KW_VOID
    call try_match_keyword
    ret

try_kw_int8:
    lea rdi, [rel kw_int8]
    mov ecx, kw_int8_len
    mov r8d, TOK_KW_INT8
    call try_match_keyword
    ret

try_kw_int16:
    lea rdi, [rel kw_int16]
    mov ecx, kw_int16_len
    mov r8d, TOK_KW_INT16
    call try_match_keyword
    ret

try_kw_int32:
    lea rdi, [rel kw_int32]
    mov ecx, kw_int32_len
    mov r8d, TOK_KW_INT32
    call try_match_keyword
    ret

try_kw_int64:
    lea rdi, [rel kw_int64]
    mov ecx, kw_int64_len
    mov r8d, TOK_KW_INT64
    call try_match_keyword
    ret

try_kw_int128:
    lea rdi, [rel kw_int128]
    mov ecx, kw_int128_len
    mov r8d, TOK_KW_INT128
    call try_match_keyword
    ret

try_kw_float32:
    lea rdi, [rel kw_float32]
    mov ecx, kw_float32_len
    mov r8d, TOK_KW_FLOAT32
    call try_match_keyword
    ret

try_kw_float64:
    lea rdi, [rel kw_float64]
    mov ecx, kw_float64_len
    mov r8d, TOK_KW_FLOAT64
    call try_match_keyword
    ret

try_kw_float128:
    lea rdi, [rel kw_float128]
    mov ecx, kw_float128_len
    mov r8d, TOK_KW_FLOAT128
    call try_match_keyword
    ret

try_kw_return:
    lea rdi, [rel kw_return]
    mov ecx, kw_return_len
    mov r8d, TOK_KW_RETURN
    call try_match_keyword
    ret

try_kw_true:
    lea rdi, [rel kw_true]
    mov ecx, kw_true_len
    mov r8d, TOK_KW_TRUE
    call try_match_keyword
    ret

try_kw_false:
    lea rdi, [rel kw_false]
    mov ecx, kw_false_len
    mov r8d, TOK_KW_FALSE
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
; ================================
; r11을 1씩 증가시키며 예약어와 비교
; 여기서 중요한거는 바이트를 비트의 배열처럼 사용되고 있다는 거
; ================================

    cmp r11, rcx
    je .bytes_ok

    mov al, [r10 + r11]
    cmp al, [rdi + r11]
    jne .no_match

    inc r11
    jmp .compare_loop

.bytes_ok:
; ===================================================================================================
// ANCHOR: LEXER_KEYWORD_BYTES_OK_BOUNDARY_CHECK
// NOTE: .bytes_ok는 최종 keyword match 성공 지점이 아니라,
;       예약어 UTF-8 바이트열이 모두 일치한 "중간 상태"다.
;
// MECHANISM:
;       input[cur_off + i]와 keyword_bytes[i]를 i=0..rcx-1까지 비교하고,
;       모든 바이트가 같으면 이 지점으로 온다.
;
// REVIEW: 예약어 바이트열이 일치해도 바로 성공 처리하면 안 된다.
;         다음 바이트가 token boundary인지 확인해야 한다.
;         예: "정수 x"는 KW_INT로 인정 가능하지만,
;             "정수값"을 KW_INT + IDENT로 잘못 분리하면 안 된다.
;
; TODO(refactor): .bytes_ok 이름을 .keyword_bytes_matched로 바꾸고,
;                 다음 바이트 경계 확인 부분은 .check_keyword_boundary로 분리한다.
;                 경계 확인까지 끝난 최종 성공 지점은 .match_success 같은 이름을 사용한다.
; ===================================================================================================

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
;----------------------------------------------------------------------------------------------------------------------
// ANCHOR: LEXER_IDENT_START_ASCII_RANGE_REFACTOR
// NOTE: 현재 식별자 시작 문자는 ASCII 기준 A-Z, a-z, '_'만 허용한다.
;       기존 구현은 동작은 가능하지만 .check_lower 라벨로 숫자/기호/밑줄 후보까지
;       흘러들어갈 수 있어 흐름과 이름이 직관적으로 맞지 않는다.
;
// REVIEW: 리팩토링 시 소문자 범위(a-z), 대문자 범위(A-Z), 밑줄(_) 검사를
;         명확한 라벨 이름으로 분리한다.
;
; RECOMMENDED_FLOW:
;       1. 'a' <= al <= 'z' 이면 성공
;       2. al < 'a' 이면 대문자 또는 '_' 가능성이 있으므로 추가 검사
;       3. al > 'z' 이면 실패
;       4. 'A' <= al <= 'Z' 이면 성공
;       5. al == '_' 이면 성공
;
; TODO(refactor): .check_lower 같은 모호한 라벨명은 .check_upper / .check_us / .no / .yes로 정리한다.
; TODO(test): 식별자 경계값 테스트를 추가한다.
;             예: _x, A, Z, a, z, a1, 1a, 한글식별자
; TODO(feature): 한글 식별자는 $표시로 진행을 검토 중
; refac_is_ident_start_al:
;     cmp al, 'a' ; 0x0061
;     jb .refac_check_higher
;     cmp al, 'z' ; 0x007A
;     jbe .refac_yes
;     jmp .refac_no

; .refac_check_higher:
;     cmp al, 'A' ; 0x0041
;     jb .refac_no
;     cmp al, 'Z' ; 0x005A
;     jbe .refac_yes
;     jmp .refac_check_us

; .refac_check_us:
;     cmp al, '_' ; 0x005F
;     je .refac_yes

; .refac_no:
;     xor eax, eax
;     ret

; .refac_yes:
;     mov eax, 1
;     ret
;----------------------------------------------------------------------------------------------------------------------
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
    cmp al, 0       ; NULL
    je .yes
    cmp al, ' '     ; space
    je .yes
    cmp al, 9       ; HT
    je .yes
    cmp al, 10      ; LF
    je .yes
    cmp al, 13      ; CR
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