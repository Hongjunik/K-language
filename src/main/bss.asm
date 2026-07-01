section .bss
    ; ----------------------------------------
    ; 렉서 상태
    ; ----------------------------------------
    cur_off         resq 1    ; 현재 읽는 바이트 오프셋
    cur_line        resq 1    ; 현재 줄 번호 (1부터 시작)
    cur_col         resq 1    ; 현재 열 번호 (v0에서는 바이트 기준)

    ; ----------------------------------------
    ; 현재 활성 입력 버퍼 상태
    ; src_base = 현재 컴파일 중인 소스 버퍼의 시작 주소
    ; src_len  = 현재 소스 버퍼의 총 길이(바이트)
    ;
    ; 중요:
    ; cur_off / tok_start 는 절대주소가 아니라
    ; src_base 기준 offset(오프셋) 값이다.
    ; ----------------------------------------
    src_base        resq 1
    src_len         resq 1

    ; ----------------------------------------
    ; 외부 .k 파일 입력 버퍼
    ; file_src_buf   = 파일 내용을 읽어오는 실제 버퍼
    ; file_src_bytes = 읽은 바이트 수
    ; ----------------------------------------
    file_src_buf    resb 65537
    file_src_bytes  resq 1

    tok_type        resq 1
    tok_start       resq 1    ; src_base 기준 시작 오프셋
    tok_len         resq 1    ; 토큰 길이(바이트)
    tok_int_value   resq 1    ; INT_LITERAL일 때만 사용

    lex_error_code  resq 1

    ; ----------------------------------------
    ; AST 상태
    ; ----------------------------------------
    ; [설명] AST 구역
    ; 크기는 AST_ARENA_SIZE(65536 byte)의 초기화 되지 않은 정적변수
    ast_arena:  
        resb AST_ARENA_SIZE
    ast_arena_end:
    ast_top         resq 1
    ast_root        resq 1

    ; ----------------------------------------
    ; 코드 생성 버퍼 상태
    ; ----------------------------------------
    cg_buf          resb CG_BUF_SIZE
    cg_buf_end:
    cg_top          resq 1
    cg_num_tmp      resb 32

    cg_label_seq    resq 1

    ; debug 출력 on/off
    debug_enabled   resq 1

     ; ----------------------------------------
    ; vars-basic 심볼 테이블
    ; 이름은 active input buffer 기준 offset + len 으로 저장한다.
    ; slot 번호는 심볼 인덱스와 동일하게 쓴다.
    ; ----------------------------------------
    sysm_count      resq 1
    sys_name_offs   resq 64
    sys_name_lens   resq 64