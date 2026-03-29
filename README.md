# K-language

한국어 기반 시스템 프로그래밍 언어 실험 프로젝트.

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

---

## 현재 기준선 (Phase 1 Baseline)

현재 기준 구현은 `K_lang_v02_5` 계열이며,
어셈블리 텍스트 생성 파이프라인이 책임별 파일 분리 이후에도 계속 유지되는 상태를 기준선으로 삼는다.

현재 실제로 검증된 흐름은 아래와 같다.

    sample_src
    → lexer
    → parser
    → AST
    → code generator
    → generated NASM text
    → nasm
    → ld
    → 실행

### 현재 확인된 기능
- 변수 선언: `변수 x = ...;`
- 출력: `출력 ...;`
- 비교 연산: `== != > < >= <=`
- if 문: `만약 (...) 이면 { ... }`
- while 문: `반복 (조건식) 동안 { ... }`
- for-like 문: `반복 (변수선언; 조건식; 변수선언) { ... }`
  - 내부적으로 `init + while(cond) { body; update; }` 로 lowering됨

### 현재 baseline sample_src 기대 출력

    7
    100
    0
    1
    2
    0
    1
    2

## 현재 디렉토리 구조 (Phase 1 종료 기준)

- `src/include/`
  - 공통 정의 허브와 정의 분리 파일
- `src/main/`
  - entry / 상태 초기화 / data / bss
- `src/lexer/`
  - lexer core / lexer debug
- `src/parser/`
  - statement parser / expression parser
- `src/ast/`
  - AST build / AST debug
- `src/codegen/`
  - symbol helper / emit helper / statement codegen / expression codegen
- `src/runtime/`
  - 공통 debug 출력 보조

현재 구조의 목적은 “기능을 유지한 채, 각 파일이 하나의 큰 책임을 갖도록 만드는 것”이다.

## 빌드와 실행

### 로컬
```bash
bash scripts/build.sh
cat build/program_output.txt

