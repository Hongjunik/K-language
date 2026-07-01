%include "src/include/defs.asm"         ; "src/include/layout_defs.asm" && "src/include/token_ast_defs.asm"파일을 include하는 허브파일을 include

%include "src/main/data.asm"            ; section .data 부분의 파일을 include
%include "src/main/bss.asm"             ; section .bss 부분의 파일을 include
%include "src/main/start.asm"           ; "src/main/entry.asm" && "src/mian/state_init.asm"파일을 include하는 허브파일을 include

%include "src/ast/ast.asm"              ; "src/ast/build.asm" && "src/ast/debug.asm"파일을 include하는 허브파일을 include
%include "src/codegen/symbols.asm"
%include "src/codegen/emit.asm"
%include "src/codegen/codegen.asm"      ; "src/codegen/stmt.asm" && "src/codegen/expr.asm"파일을 include하는 허브파일을 include
%include "src/lexer/lexer.asm"          ; "src/lexer/core.asm" && "src/lexer/debug.asm"파일을 include하는 허브파일을 include
%include "src/parser/parser.asm"        ; "src/parser/expr.asm" && "src/parser/stmt.asm"파일을 include하는 허브파일을 include
%include "src/runtime/debug.asm"