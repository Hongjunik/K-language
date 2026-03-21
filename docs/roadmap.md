# K언어 로드맵

## 기준선
- 기준 기기: 집 데스크톱
- 기준 브랜치: main
- 기준 태그: v0.2.4-fixed-baseline

## 확정 목표
- K언어 컴파일러가 완전히 링크된 ELF 실행 파일까지 직접 생성

## 확장 목표
1. 어셈블리 텍스트 생성
2. ELF 오브젝트 파일 직접 생성
3. 완전히 링크된 ELF 실행 파일 직접 생성

## 현재 완료
- lexer 직접 구현
- parser 기본 문장/표현식 구현
- AST arena allocator
- print-only 정수식 코드 생성

## 다음 단계
1. 간단한 리팩토링
2. 변수/식별자 코드 생성
3. if 코드 생성
4. 이후 while / ELF 직접 생성 단계 검토

## 구현 원칙
- 선택지 B(메모리 버퍼 기반 출력) 유지
- generated assembly와 debug 출력 절대 혼합 금지
- gen_expr 계약: 결과는 rax