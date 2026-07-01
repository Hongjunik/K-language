section .text
    global _start

; ====================================================================
; 프로그램 시작점
; ====================================================================
_start:
    ; ============================================================
    ; [K-language internal compiler core 진입점]
    ;
    ; 이 파일의 _start는 사용자가 직접 실행하는 ./kompiler wrapper의
    ; 진입점이 아니다.
    ;
    ; 사용자-facing 명령:
    ;   ./kompiler -S input.k -o output.asm
    ;
    ; 실제 실행 흐름:
    ;   1. ./kompiler Bash wrapper가 -S, -c, -o 같은 옵션을 해석한다.
    ;   2. wrapper가 src/K_lang_v02_5.asm을 NASM/ld로 빌드한다.
    ;   3. wrapper가 내부 컴파일러 build/kc를 아래 형태로 실행한다.
    ;
    ;        build/kc input.k
    ;
    ;   4. build/kc가 stdout으로 generated assembly를 출력한다.
    ;   5. wrapper가 stdout을 output.asm 같은 파일로 redirect한다.
    ;
    ; 따라서 이 _start 기준 Linux x86-64 초기 스택 구조는
    ; public 명령 전체가 아니라 internal compiler core 호출 기준이다.
    ;
    ;   [rsp + 0]   = argc
    ;   [rsp + 8]   = argv[0] 포인터 -> "build/kc\0"
    ;   [rsp + 16]  = argv[1] 포인터 -> "input.k\0"
    ;   [rsp + 24]  = argv[2] 포인터 -> NULL
    ;
    ; argv[n]에는 문자열 자체가 아니라 문자열 시작 주소가 들어 있다.
    ; x86-64 기준 pointer(포인터, 주소값) 1개는 8바이트이므로
    ; argv 슬롯은 8바이트 간격이다.
    ;
    ; 즉 이 파일에서는 argv[1]을 입력 파일 경로로 보는 것이 맞다.
    ; -S, -o 같은 public CLI option(명령줄 옵션)은 ./kompiler wrapper가
    ; 이미 처리한 뒤에 이 내부 컴파일러를 호출한다.
    ; ============================================================

    ; [레지스터] RBP = Register Base Pointer / 베이스 포인터
    ; [데이터 이동] rsp -> rbp
    ; [기능] _start 진입 직후의 스택 위치를 rbp에 고정 저장한다.
    ; [이유] 이후 call/push 등으로 rsp가 변해도 [rbp], [rbp+8], [rbp+16]으로
    ;        초기 argc/argv 위치를 계속 읽기 위함이다.
    mov rbp, rsp

    ; ------------------------------------------------------------
    ; argc 확인
    ; ------------------------------------------------------------

    ; [레지스터] RAX = Register A Extended / 누산기 계열 임시 저장 레지스터
    ; [데이터 이동] memory([rbp + 0]) -> rax
    ; [값] rax = argc, 즉 명령줄 인자 개수
    ; [기능] 사용자가 입력 파일 또는 옵션을 넘겼는지 먼저 확인한다.
    ;
    ; 예:
    ;   ./kompiler          => argc = 1
    ;   ./kompiler input.k  => argc = 2
    mov rax, [rbp]

    ; [연산] rax(argc)와 2를 비교한다.(rax - 2 == 0이면 rax = 2 || rax - 2 > 0이면 rax > 2 || rax - 2 < 0이면 rax < 2)
    ; [레지스터] RFLAGS = 비교 결과 상태 저장
    ; [기능] argc < 2인지 확인한다.
    ; [주의] cmp는 rax 값을 바꾸지 않고, RFLAGS만 갱신한다.
    cmp rax, 2

    ; [제어 흐름] argc < 2(|RFLAGS| <= |0|)이면 .use_sample_input으로 점프한다.
    ; [기능] argv[1]이 없으므로 사용자가 입력 파일을 지정하지 않은 상태로 판단한다.
    ; [판단 예] ./kompiler 만 실행한 경우
    jb .use_sample_input

    ; ------------------------------------------------------------
    ; argv[1] = internal compiler core 기준 첫 번째 인자
    ; ------------------------------------------------------------

    ; [레지스터] RDI = Register Destination Index / 목적지 인덱스 계열 레지스터
    ; [호출 규약] System V AMD64에서 첫 번째 함수 인자는 rdi로 전달한다.
    ; [데이터 이동] memory([rbp + 16]) -> rdi
    ; [값] rdi = argv[1] 포인터, 즉 입력 파일 경로 문자열의 시작 주소
    ; [기능] wrapper가 넘겨준 input.k 경로를 input_try_use_cli_file에 넘길 준비를 한다.
    ;
    ; public 명령:
    ;   ./kompiler -S input.k -o output.asm
    ;
    ; wrapper가 내부적으로 실행하는 명령:
    ;   build/kc input.k
    ;
    ; 이 _start 기준:
    ;   [rbp + 16] = "input.k\0" 문자열의 시작 주소
    ;   rdi        = "input.k\0" 문자열의 시작 주소
    ;
    ; 주의:
    ;   rdi에 "input.k" 문자들이 직접 들어가는 것이 아니다.
    ;   rdi에는 "input.k" 문자열이 저장된 메모리 주소만 들어간다.
    mov rdi, [rbp + 16]

    ; [함수 호출] input_try_use_cli_file(argv[1])
    ; [전달 인자] rdi = 입력 파일 경로 문자열 주소
    ; [기능] argv[1]이 가리키는 파일을 K-language 입력 파일로 열어본다
    call input_try_use_cli_file

    ; [레지스터] RAX = 함수 반환값 저장 위치
    ; [연산] rax && rax를 계산해 결과가 0인지 RFLAGS에 기록한다.
    ; [기능] input_try_use_cli_file의 성공/실패를 확인한다.
    ; [주의] test는 rax 값을 바꾸지 않고, Zero Flag 같은 상태 플래그만 갱신한다.
    test rax, rax

    ; [제어 흐름] rax == 0이면 .cli_input_fail로 점프한다.
    ; [기능] 파일 열기 또는 입력 준비 실패 처리로 이동한다.
    jz .cli_input_fail

    ; [제어 흐름] 여기까지 왔으면 입력 파일 준비가 성공한 상태다.
    ; [기능] 이후 파서/parser 또는 입력 처리 루틴으로 넘어간다.
    ; [주의] 점프 후에 돌아올 수 없다.
    jmp .input_ready

; sample_src를 사용하는 지역 레이블
.use_sample_input:
    ; [함수 호출] input_use_sample_fallback
    ; [제어 흐름] 'jmp .input_ready'를 스택(Stack)에 저장(push) 후에 "src/main/state_init.asm"으로 점프한다.
    ; [기능] 입력 파일을 지정하지 않은 경우에 sample_src를 사용을 위한 call
    ; [주의] ret(Return)이 없는 레이블에 call 사용시에 복귀하지 못하여 크래쉬 또는 오류가 생길 수 있다.
    call input_use_sample_fallback

    ; [제어 흐름] 여기까지 왔으면 입력 파일 준비가 성공한 상태다.
    ; [기능] 이후 파서/parser 또는 입력 처리 루틴으로 넘어간다.
    ; [주의] 점프 후에 돌아올 수 없다.
    jmp .input_ready

; .k파일을 읽기 실패했을때의 레이블
.cli_input_fail:
    ; [데이터 이동] rax <-(cp) SYS_exit(60)
    mov rax, SYS_exit

    ; [데이터 이동] rdi <-(cp) 1
    mov rdi, 1

    ; [커널 호출] exit(1)호출로 비정상 종료 리눅스 커널 호출
    syscall

.input_ready:
    ; [기능] 현재 선택된 입력 버퍼(src_base, src_len)는 유지하고,
    ;        렉서 / 코드생성 상태만 초기화한다.
    call lexer_init

    ; [기능] AST arena 초기화
    call ast_init
    
    ; [데이터 이동] qword debug_enabled <-(cp) 0
    ; [기능] debug출력을 on/off를 지정한다.
    ; 1 = on / 0 = off
    mov qword [debug_enabled], 0

    ; [기능] 파싱 시작 부분
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
    mov rax, SYS_exit           ; rax에 SYS_exit("src/include/token_ast_defs.asm"에 선언되어 있는 linux syscall number 값:60)의 값을 복사 저장한다.
    xor rdi, rdi                ; rdi의 값과 rdi의 값을 xor(두개의 값이 다를때만 1)하여 rdi에 결과값을 저장(값:0)
    syscall                     ; exit(0) 커널 호출