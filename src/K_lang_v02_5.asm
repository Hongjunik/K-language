%include "src/include/defs.asm"

%include "src/main/data.asm"
%include "src/main/bss.asm"
%include "src/main/start.asm"

%include "src/ast/ast.asm"
%include "src/codegen/symbols.asm"
%include "src/codegen/codegen.asm"
%include "src/lexer/lexer.asm"
%include "src/parser/parser.asm"
%include "src/runtime/debug.asm"