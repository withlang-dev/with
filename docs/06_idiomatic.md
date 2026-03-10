Idiomatic Rewrite and Quality
Goal: Rewrite the compiler source to idiomatic With. This is
the quality pass from the manifesto.
Scope: Every file in src/. No functional changes — the
compiler does the same thing, but the code is clean.
Rule: One file at a time. Verify fixpoint after each file.
Never batch multiple files.
Checklist
Enum conversions (one at a time)

 src/Ast.w — const NK_* → type NodeKind: i32 = ...
Update all if kind == NK_X to match kind with .X ->.
 src/Token.w — const TK_* → type TokenKind: i32 = ...
 src/Sema.w — const TY_* → type TypeKind: i32 = ...
 src/Mir.w — const SK_*, TK_*, RK_*, OK_*, CK_*,
PK_* → discriminant enums.
 src/Codegen.w — any remaining integer constant groups.

Handle types

 type NodeId = distinct i32 in src/Ast.w
 type TypeId = distinct i32 in src/Sema.w
 type BlockId = distinct i32 in src/Mir.w
 Update all call sites to use distinct types

Idiomatic patterns

 Replace verbose closures with it where single-parameter
 Replace manual error matching with ?
 Replace nested calls with |> where data flows linearly
 Replace if x == false with if not x
 Remove unnecessary parens on zero-arg functions
 Remove unnecessary return type annotations on Unit functions

Compiler quality

 §7.1 AstPool metadata: add HashMaps for O(1) lookup
 §7.2 Sema scope lookup: add HashMap overlay
 §7.3 Lexer: replace magic numbers with CH_* constants
 §7.4 Document find_source_arg assumptions

Pipeline ownership

 Move state from Driver to Zcu
 Route main.w through compiler.Compilation
 Delete Driver or reduce to thin adapter

Hardcode removal

 Delete is_builtin_fn, is_builtin_value from sema
 Delete name-based dispatch from codegen
 Verify --no-prelude makes println unavailable

Exit gate
Compiler source reads as idiomatic With. Fixpoint holds. All tests
pass. Driver is deleted or reduced to adapter. No hardcoded
user-facing symbol names.