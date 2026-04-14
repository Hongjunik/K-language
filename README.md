# K-language

한국어 기반 시스템 프로그래밍 언어 실험 프로젝트.

---

## 한 줄 소개

K-language는 한국어 기반 문법을 가진 실험용 프로그래밍 언어이며,  
가능한 많은 층을 어셈블리어(assembly language, 어셈블리어)로 직접 구현하면서  
시스템 프로그래밍의 구조와 감각을 몸으로 익히는 것을 목표로 한다.

---

## 프로젝트 목적

K-language의 목적은 단순히 새로운 문법의 언어를 빠르게 완성하는 것이 아니다.

이 프로젝트는 다음 두 가지를 동시에 추구한다.

1. **한국어 기반 문법을 가진 언어 설계 경험**
2. **저수준 시스템 구현 경험**

즉, “문법을 만드는 일”과 “컴파일러 내부를 직접 만드는 일”을 함께 다룬다.

특히 C가 태어나던 시기의 감각에 가깝게, 고수준 도구에 너무 많이 기대지 않고  
핵심 단계를 직접 만들면서 다음을 체험하는 것을 중시한다.

- 렉서(lexer, 어휘 분석기) 직접 구현
- 파서(parser, 구문 분석기) 직접 구현
- AST(Abstract Syntax Tree, 추상 구문 트리) 직접 구현
- 코드 생성기(code generator, 코드 생성기) 직접 구현
- 장기적으로 ELF 오브젝트 파일과 ELF 실행 파일 직접 생성

---

## 개발 철학

- 가능한 한 많은 핵심 로직을 어셈블리어로 직접 구현한다.
- 범위는 작게 잡고 점진적으로 확장한다.
- 먼저 작은 수직 절단(vertical slice, 끝까지 이어지는 최소 기능 흐름)을 완성한다.
- 렉서 → 파서 → AST → 코드 생성기 → 리팩토링 순으로 진행한다.
- 실행 가능한 흐름이 생긴 뒤에 구조 정리를 한다.
- 최종적으로는 완전히 링크된 ELF 실행 파일까지 직접 생성하는 것을 지향한다.

이 프로젝트는 “처음부터 거대한 언어를 만드는 것”보다  
**작지만 끝까지 이어지는 구현 흐름을 실제로 작동시키는 것**을 더 중요하게 본다.

---

## 최종 목표와 확장 목표

### 최종 목표

K-language 컴파일러가 **완전히 링크된 ELF 실행 파일**까지 직접 생성하는 것

### 확장 목표

1. 어셈블리 텍스트 생성
2. ELF 오브젝트 파일 직접 생성
3. 완전히 링크된 ELF 실행 파일 직접 생성

현재는 위 확장 목표 중 **1단계: 어셈블리 텍스트 생성**을 진행 중이다.  
현재 브랜치 기준으로는 외부 `.k` 파일 입력과 `kompiler` 1차 드라이버까지 연결된 상태로 본다.

---

## 현재 기준선 (Phase 1 Baseline)

현재 기준 구현은 `K_lang_v02_5` 계열이며,  
어셈블리 텍스트 생성 파이프라인이 책임별 파일 분리 이후에도 계속 유지되는 상태를 기준선으로 삼는다.

현재 실제로 검증하는 흐름은 아래와 같다.

```text
.k source 또는 fallback sample_src
  ↓
lexer
  ↓
parser
  ↓
AST
  ↓
code generator
  ↓
generated NASM text
  ↓
nasm
  ↓
ld
  ↓
실행

즉, 현재는 여전히 NASM과 ld를 사용하지만,
그 위에 최종 사용자용 명령 kompiler를 두고 .k 입력을 처리하는 형태로 정리하고 있다.

현재 확인된 기능
변수 선언: 변수 x = ...;
출력: 출력 ...;
비교 연산: == != > < >= <=
if 문: 만약 (...) 이면 { ... }
while 문: 반복 (조건식) 동안 { ... }
for-like 문: 반복 (변수선언; 조건식; 변수선언) { ... }
내부적으로 init + while(cond) { body; update; } 로 lowering됨
현재 baseline 기대 출력
7
100
0
1
2
0
1
2

의미는 다음과 같다.

7 = 변수 선언 + 출력
100 = 비교 + if
0 1 2 = while
0 1 2 = for-like lowering
K언어 명세 요약

이 절은 현재 브랜치에서 실제로 구현되어 있는 문법만 정리한 요약 명세다.
즉 앞으로 타입 시스템이나 추가 문법이 들어오면 이 절도 같이 갱신해야 한다.

1. 값과 이름

현재 기본적으로 지원하는 값은 아래와 같다.

정수 리터럴
예: 0, 1, 7, 100
식별자(identifier, 변수 이름)
예: x, a, i
2. 키워드

현재 구현 기준 핵심 키워드는 아래와 같다.

변수
출력
만약
이면
반복
동안
3. 구분 기호

현재 문법에서 사용하는 주요 기호는 아래와 같다.

문장 끝: ;
괄호: ( )
블록: { }
대입: =
4. 산술 연산자

현재 표현식에서 사용하는 산술 연산자는 아래와 같다.

+
-
*
/
%
5. 비교 연산자

현재 조건식에서 사용하는 비교 연산자는 아래와 같다.

==
!=
>
<
>=
<=
6. 표현식

현재 표현식은 아래 요소를 조합하는 방향으로 사용한다.

정수 리터럴
식별자
괄호를 포함한 식
산술식
비교식

예시:

7
x
(a + 1)
x * 3
a < 3
3 > 1
x == y
7. 변수 선언문

현재 변수 선언문은 아래 형태를 따른다.

변수 식별자 = 표현식;

예시:

변수 x = 7;
변수 a = 0;
변수 i = i + 1;
8. 출력문

현재 출력문은 아래 형태를 따른다.

출력 표현식;

예시:

출력 x;
출력 100;
출력 a + 1;
9. 만약문

현재 if 문은 아래 형태를 따른다.

만약 (조건식) 이면 { ... }

예시:

만약 (3 > 1) 이면 { 출력 100; }
10. 반복문

현재 반복문은 두 형태로 사용한다.

while 형태
반복 (조건식) 동안 { ... }

예시:

반복 (a < 3) 동안 { 출력 a; 변수 a = a + 1; }
for-like 형태
반복 (변수선언; 조건식; 변수선언) { ... }

예시:

반복 (변수 i = 0; i < 3; 변수 i = i + 1) { 출력 i; }

현재 구현에서는 이 for-like 문을 내부적으로 아래와 같은 while 구조로 바꾸어 처리한다.

{
  init;
  while (cond) {
    body;
    update;
  }
}

또한 현재 버전에서는 for-like 문의 init와 update를 변수선언형으로 제한한다.

11. 블록

현재 블록은 아래처럼 중괄호로 묶는다.

{
  문장들...
}

즉 if 문과 반복문 본문은 현재 블록 형태로 처리된다고 보는 것이 맞다.

12. 현재 버전에서 아직 없는 것 / 아직 고정되지 않은 것

아래는 아직 현재 기준 README에서 “지원 완료”라고 적지 않는 것이 맞다.

타입 지정 문법
함수 선언/호출
문자열 리터럴
배열
사용자 정의 구조체
else 문
여러 파일 입력과 링크
ELF 직접 생성

즉 현재 README는 “지금 실제로 되는 문법”만 적고, 미래 계획은 별도 단계로 둔다.

현재 디렉토리 구조 (Phase 1 종료 기준)
src/include/
공통 정의 허브와 정의 분리 파일
src/main/
entry / 상태 초기화 / data / bss
src/lexer/
lexer core / lexer debug
src/parser/
statement parser / expression parser
src/ast/
AST build / AST debug
src/codegen/
symbol helper / emit helper / statement codegen / expression codegen
src/runtime/
공통 debug 출력 보조
scripts/
기준선 검증용 스크립트
build/
중간 산출물과 테스트 산출물

현재 구조의 목적은 “기능을 유지한 채, 각 파일이 하나의 큰 책임을 갖도록 만드는 것”이다.

빌드와 실행
로컬 기준선 검증
bash scripts/build.sh
cat build/program_output.txt

현재 scripts/build.sh는 baseline용 .k 입력을 자동으로 만들고,
kompiler를 통해 generated assembly와 실행 파일을 생성한 뒤,
최종 출력이 기준선과 같은지 확인하는 용도로 사용한다.

kompiler 사용법

현재 최종 사용자용 컴파일러 명령 이름은 kompiler다.

실행 파일까지 생성
./kompiler build/hello.k

기본 출력 파일 이름은 a.out이다.

실행 파일 이름 지정
./kompiler build/hello.k -o build/hello_run
generated assembly까지만 생성
./kompiler -S build/hello.k

기본 출력 파일 이름은 hello.asm이다.

object file까지만 생성
./kompiler -c build/hello.k

기본 출력 파일 이름은 hello.o이다.

도움말 보기
./kompiler --help
직접 .k 파일 테스트 예시

테스트 파일 생성:

mkdir -p build

cat > build/hello.k <<'EOF'
변수 x = 7;
출력 x;

만약 (3 > 1) 이면 { 출력 100; }

변수 a = 0;
반복 (a < 3) 동안 { 출력 a; 변수 a = a + 1; }

반복 (변수 i = 0; i < 3; 변수 i = i + 1) { 출력 i; }
EOF

generated assembly 생성:

./kompiler -S build/hello.k -o build/hello.asm

object file 생성:

./kompiler -c build/hello.k -o build/hello.o

실행 파일 생성 및 실행:

./kompiler build/hello.k -o build/hello_run
./build/hello_run

기대 출력:

7
100
0
1
2
0
1
2
현재 단계에서 중요한 점

현재는 아직 generated assembly를 만들고, 그 뒤 NASM과 ld를 통해 오브젝트 파일과 실행 파일을 만드는 구조다.

즉 지금 단계에서 kompiler는 최종 사용자용 명령이지만, 내부적으로는 아직 부트스트랩 방식과 외부 도구를 사용한다.

이것은 우회가 아니라, 장기적으로

직접 오브젝트 파일 생성
더 나아가 직접 ELF 실행 파일 생성

으로 가기 위한 정상적인 중간 단계다.

장기 방향

장기 방향은 아래와 같다.

.k 입력과 kompiler 사용 흐름 안정화
generated assembly 생성 경로 안정화
오브젝트 파일 직접 생성
완전히 링크된 ELF 실행 파일 직접 생성

즉 지금의 NASM / ld 사용은 최종 목표에서 벗어난 것이 아니라,
ELF까지 가기 위한 중간 단계다.