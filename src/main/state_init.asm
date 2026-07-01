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
//NOTE - 현재 파일은 65536바이트까지 단회 입력을 받는다.
//TODO - 파일읽기를 스트리밍 처리(streaming processing, 흐름식 처리)
input_try_use_cli_file:
    ; open(path, flags=0, mode=0)
    ; [데이터 이동] rax <-(cp) SYS_open(const 2)
    mov rax, SYS_open
    ; rdi = [rbp + 16] -> input.k

    ; [연산] rsi = rsi xor rsi
    ; [데이터 이동] rsi <- 0(xor 연산 결과값)
    ; [레지스터] rsi는 파일을 어떤 모드로 열지(Flags) 결정하는 정수 값을 넣어 읽기/쓰기 여부가 결정된다.
    ; [기능] 오직 읽기 전용(C언어의 O_RDONLY)으로 파일을 연다.
    ; [추신] rsi의 값으로 파일 읽기의 모드가 정해진다.
    ; 플래그(C언어 기준)  |  실제 숫자 값(8진수/10진수)  |  설명
    ;     O_RDONLY       |             0               |  오직 읽기 전용
    ;     O_WRONLY       |             1               |  오직 쓰기 전용
    ;     ORDWR          |             2               | 읽기와 쓰기 모두 가능
    ;     O_CREAT        |       0100(10진수값 64)       | 파일이 없으면 새로 생성하기 (보통 쓰기 플래그와 OR 연산해서 사용)
    xor rsi, rsi

    ; [연산] rdx = rdx xor rdx
    ; [데이터 이동] rdx <- 0(xor 연산 결과값)
    ; [레지스터] rdx는 파일을 새로 생성할 때(O_CREAT) 부여할 접근 권한(Mode)을 결정하는 정수 값을 넣음
    ; [기능] O_CREAT 또는 O_TMPFILE이 flags(rsi)에 있을 때만 rdx 값이 의미를 가진다.
    ; [주의] rdx는 읽기/쓰기 동작 여부를 정하는 값이 아니다. 읽기/쓰기 여부는 rsi(flags)가 정한다.
    ; [추신] 현재 코드는 rsi = O_RDONLY 이므로 파일을 새로 만들지 않는다. 따라서 rdx = 0은 커널에서 사실상 무시된다.
    ;        만약 출력 파일처럼 새 파일을 만들려면 rsi에 O_CREAT를 포함하고, rdx에 0644 같은 권한값을 넣어야 한다.
    ;        예: rdx = 0644 → 소유자 읽기/쓰기, 그룹 읽기, 기타 사용자 읽기
    ;        단, 최종 파일 권한은 rdx 값 그대로가 아니라 현재 umask에 의해 일부 권한이 제거된 값으로 결정된다.
    ; rdx(mode) 기준 | 실제 숫자 값(8진수) | 권한 문자열 | 설명
    ;     0600       |        0600       | rw------- | 소유자만 읽기/쓰기 가능
    ;     0644       |        0644       | rw-r--r-- | 소유자 읽기/쓰기, 그룹/기타 읽기 가능
    ;     0666       |        0666       | rw-rw-rw- | 모두 읽기/쓰기 가능, 실행 권한 없음
    ;     0700       |        0700       | rwx------ | 소유자만 읽기/쓰기/실행 가능
    ;     0755       |        0755       | rwxr-xr-x | 소유자 모든 권한, 그룹/기타 읽기/실행 가능
    xor rdx, rdx

    ; [커널 호출] syscall
    ; [데이터 이동] rax <- fd(성공시에 파일 디스크립터/file descriptor)/에러코드(실패시)
    ; [기능] 위에서 설정한 rax/rdi/rsi/rdx 값을 기준으로 리눅스 커널에 open 시스템 콜을 요청한다.
    ; [상태] rax = 2 이므로 이번 syscall은 exit가 아니라 open, 즉 파일 열기 요청이다.
    ; [인자] rdi = 파일 이름 주소, rsi = 파일 열기 방식(flags), rdx = 새 파일 생성 시 권한(mode)
    ; [결과] 성공하면 rax에 파일 디스크립터(fd, file descriptor)가 들어온다.
    ; [실패] 실패하면 rax에 음수 에러 코드가 들어온다.
    ; [추신] fd(파일 디스크립터/file descriptor)는 0을 포함한 음이 아닌 정수이다.
    ; 
    syscall


    ; [연산] rax && rax
    ; [데이터 이동] ZF(Zero Flag)/SF(Sign Flag)/PF(Parity Flag) < rax && rax
    ; [기능] 파일 열기에 실패했는지를 판단한다.
    ; 파일 열기에 성공했다면 rax에 fd(파일 디스크립터/file descriptor | 0을 포함한 양의 정수)가 들어간다
    ; 만약 실패하여 오류코드(음수)가 들어간다.
    test rax, rax

    ; [기능] SF(Sign Flag | 전에 결과가 음수였는지 판단)를 통해 만약 SF = 1이면 .fail로 이동
    js .fail

    ; r8 = fd
    ; [데이터 이동] r8 <-(cp) rax(fd(파일 디스크립터/file descriptor | 0을 포함한 양의 정수))
    ; [기능] r8에 fd를 백업한다.
    mov r8, rax

    ; read(fd, file_src_buf, 65536)
    ; [데이터 이동] rax <-(cp) SYS_read(0)
    mov rax, SYS_read

    ; [데이터 이동] rdi <-(cp) r8(fd(파일 디스크립터/file descriptor))
    ; [기능] 위에서 열었던 파일의 fd값을 넣어 어떤 파일을 읽을 지 알려준다.
    mov rdi, r8

    ; [데이터 이동] rsi <- address(file_src_buf)
    ; [기능] file_src_buf 버퍼의 시작 주소를 RIP-relative 방식으로 계산해 rsi에 넣는다.
    ;        lea는 메모리 값을 읽지 않고 주소만 계산한다.
    ;        read(fd, buf, count)에서 rsi는 두 번째 인자 buf 역할이다.
    ; [추신] 이 코드는 file_src_buf의 주소를 상대주소로 계산하라는 이야기다.
    ;        read의 2번째 인자 buf를 넣는다.
    ;        파일 내용이 저장될 메모리 버퍼의 시작 주소다.
    ;        매번 시행마다 프로그램은 돌아가는 주소가 다르게 때문에
    ;        상대적인 주소, 즉 얼마나 멀리 있는 파일(offset) 등으로 표현한다.
    lea rsi, [rel file_src_buf]

    ; [데이터 이동] rdx <-(cp) 65536
    ; [기능] 파일을 한번에 얼마나 읽을지를 알려주는 거다.
    ;        read의 3번째 인자 count를 넣는다.
    ;        이번 read에서 최대 65536바이트까지만 읽는다.
    ; [주의] rdx크기는 최대 버퍼(file_src_buf)크기까지만 해야 메모리 누수 등이 없다.
    mov rdx, 65536

    ; [커널 호출] read(fd, file_src_buf, 65536)
    ; [기능] rax에 들어 있는 syscall 번호와 rdi/rsi/rdx 인자를 기준으로 Linux 커널에 read를 요청한다.
    syscall

    ; [데이터 이동] RFLAGS(SF/PF/ZF) < rax && rax
    ; [추신] 만약 읽기에 실패했다면 rax에 에러코드(음수)가 들어간다.
    test rax, rax

    ; [기능] 읽기가 실패했다면 .read_fail로 점프한다.
    js .read_fail

    ; r9 = bytes_read
    ; [기능] 실제로 읽은 바이트 수를 백업한다.
    ; [데이터 이도] r9 <-(cp) rax
    mov r9, rax

    ; [데이터 이동] [file_src_bytes] <-(cp) r9(파일에서 읽은 바이트 수)
    mov [file_src_bytes], r9

    ; 널 종료 바이트 추가
    ; [데이터 이동] r10 <- (RIP)file_src_buf
    ; [기능] r10에 file_src_buf의 상대 메모리 주소를 계산한 절대 주소를 저장한다.
    lea r10, [rel file_src_buf]

    ; [기능] r10(RIP file_src_buf(버퍼 시작주소)) + r9(file_src_byte(파일읽기에서 읽은 바이트 수))
    ;        주소 위치에 있는 메모리 1바이트에 값을 0을 저장하여 문자열의 끝임을 표시한다.
    ; [데이터 이동] [r10 + r9] <-(cp) 0
    ; [추신] 버퍼의 유효한 데이터 범위는 file_src_buf부터 file_src_buf + file_src_byte -1
    ;        까지 때문이다. 메모리 유효 데이터 문자열의 끝임을 표시한다.
    mov byte [r10 + r9], 0

    ; 현재 활성 입력 버퍼로 연결
    ; [데이터 이동] src_base <-(cp) r10(RIP file_src_buf)
    mov [src_base], r10
    ; [데이터 이동] src_len <-(cp) r9(file_src_byte)
    mov [src_len], r9

    ; close(fd)
    ; [데이터 이동] rax <-(cp) SYS_close(3)
    mov rax, SYS_close
    ; [데이터 이동] rdi <-(cp) r8(fd)
    mov rdi, r8
    ; [커널 호출] rdi의 열고 있는 파일을 닫는다는
    ;             리눅스 커널호출
    syscall

    ; [데이터 이동] rax <-(cp) 1
    ; [기능] .k파일을 읽기에 성공했다는 리턴값
    ; [추신] 파일 읽기의 판단을 ZF로 하기 때문에 rax의 값이 0이 아니면 된다.
    mov rax, 1
    ; [기능] call input_try_use_cli_file 스택으로 리턴
    ret

; 파일 읽기 실패부분
.read_fail:
    ; read 실패여도 fd는 닫고 실패 반환
    ; [데이터 이동] rax <-(cp) SYS_close(3)
    mov rax, SYS_close
    ; [데이터 이동] rdi <-(cp) r8(fd)
    mov rdi, r8
    ; [커널 호출] fd가 가리키는 파일을 닫으라는 리눅스 커널 호출
    syscall

    ; [기능] fail레이블로 점프
    ; [추신] 파일을 닫고 공통 실패 부분으로 넘어간다.
    jmp .fail

; 공통 실패부분
.fail:
    ; [연산] rax xor rax
    ; [데이터 이동] rax <- 0(xor 연산의 값)
    xor rax, rax
    ; [기능] call input_try_use_cli_file로 리턴
    ret

; =========================================================
; lexer_init
;현재 선택된 입력 버퍼(src_base, src_len)는 유지하고,
; 렉서 / 코드생성 상태만 초기화한다.
; =========================================================
lexer_init:
    ; [연산] rax xor rax
    ; [데이터 이동] rax <- 0
    xor rax, rax

    ; ===================
    ; 0으로 초기화
    ; ===================
    mov [cur_off], rax
    mov [tok_type], rax
    mov [tok_start], rax
    mov [tok_len], rax
    mov [tok_int_value], rax
    mov [lex_error_code], rax
    mov [sysm_count], rax
    mov [cg_label_seq], rax

    ; 현재의 줄(행)/열을 초기화하는 부분
    ; (1,1)을 기준으로 잡는다.
    mov qword [cur_line], 1
    mov qword [cur_col], 1
    ret