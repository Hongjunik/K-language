BITS 64

; ============================================
; x86-64 Linux syscall numbers
; ============================================
%define SYS_read         0
%define SYS_write        1
%define SYS_exit         60

; ============================================
; Token IDs
; ============================================
%define TOK_EOF          0
%define TOK_ERROR        1

%define TOK_KW_VAR       10
%define TOK_KW_PRINT     11
%define TOK_KW_IF        12
%define TOK_KW_THEN      13
%define TOK_KW_WHILE     14
%define TOK_KW_DURING    15

%define TOK_IDENT        20
%define TOK_INT_LITERAL  21

%define TOK_SEMI         30
%define TOK_LPAREN       31
%define TOK_RPAREN       32
%define TOK_LBRACE       33
%define TOK_RBRACE       34

%define TOK_ASSIGN       40
%define TOK_PLUS         41
%define TOK_MINUS        42
%define TOK_STAR         43
%define TOK_SLASH        44
%define TOK_PERCENT      45

%define TOK_EQ           50
%define TOK_NE           51
%define TOK_GT           52
%define TOK_LT           53
%define TOK_GE           54
%define TOK_LE           55

; ============================================
; AST Node IDs
; ============================================
%define AST_PROGRAM    1
%define AST_BLOCK      2
%define AST_STMT_LIST  3

%define AST_VAR_DECL   10
%define AST_PRINT      11
%define AST_IF         12
%define AST_WHILE      13

%define AST_INT        20
%define AST_IDENT      21
%define AST_UNARY      22
%define AST_BINARY     23

; --------------------------------------------
; 공통 노드 레이아웃 (48 bytes)
; --------------------------------------------
%define NODE_TYPE      0
%define NODE_A         8
%define NODE_B         16
%define NODE_C         24
%define NODE_D         32
%define NODE_E         40

%define AST_NODE_SIZE  48
%define AST_ARENA_SIZE 65536
%define CG_BUF_SIZE 65536