; =========================================================
; AST_VAR_DECL field aliases
; =========================================================
%define VAR_DECL_NAME_OFF   NODE_A
%define VAR_DECL_NAME_LEN   NODE_B
%define VAR_DECL_INIT_EXPR  NODE_C
%define VAR_DECL_TYPE_ID    NODE_D
%define VAR_DECL_MOD_FLAGS  NODE_E

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