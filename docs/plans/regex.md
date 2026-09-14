# Regex Integration Plan

## Summary

Implement regex as a **normal stdlib/prelude type** backed by the existing migrated PCRE2 engine, with **compiler-known syntax** for `/.../flags`, `=~`, `!~`, and regex `match` arms.

This milestone includes:
- `std.regex` facade on top of `std.re`
- regex literals
- `=~` / `!~`
- scoped `$0`, `$1`, `$name` bindings for direct positive regex conditions
- regex arms in `match`

This milestone does **not** include:
- compiler-side literal validation
- JIT
- full upstream `pcre2test` corpus
- flow-sensitive capture bindings through compound boolean expressions
- magic capture bindings for non-literal `Regex` values

## Implementation Changes

### 1. Stdlib facade first

Add `lib/std/regex.w` and pull it into `lib/std/prelude.w`.

Public API for v1:
- `type Regex`
- `type Match { text: str, start: i32, end: i32 }`
- `type Captures`
- `type RegexError { code: i32, offset: i32, message: str }`
- `fn Regex.compile(pattern: &str) -> Result[Regex, RegexError]`
- `fn Regex.compile_flags(pattern: &str, flags: &str) -> Result[Regex, RegexError]`
- `fn Regex.is_match(self: &Self, text: &str) -> bool`
- `fn Regex.find(self: &Self, text: &str) -> Option[Match]`
- `fn Regex.captures(self: &Self, text: &str) -> Option[Captures]`
- `fn Regex.replace_all(self: &Self, text: &str, repl: &str) -> str`
- `fn Regex.split(self: &Self, text: &str) -> Vec[str]`
- `fn Captures.get(self: &Self, index: i32) -> Option[Match]`
- `fn Captures.by_name(self: &Self, name: &str) -> Option[Match]`

Compiler-only helper:
- `fn Regex.__compile_literal(pattern: &str, flags: &str, file: &str, line: i32, col: i32) -> Regex`
- This must fail loudly with a source-located panic if compilation fails. No silent fallback, no invalid zero-value regex.

Representation defaults:
- `Regex` owns the compiled `pcre2_code` and frees it in `drop`
- `Regex` stores `global: bool` separately from compile options
- `g` is not passed to `pcre2_compile_8`; it only affects higher-level iteration APIs
- `Captures` stores the original subject plus span pairs; explicit APIs return `Option[Match]`
- Compiler-generated `$N` / `$name` locals are plain `str`; unmatched optional groups bind to `""`

Named capture extraction:
- Parse and cache the PCRE2 name table once during `Regex.compile*`
- `Captures.by_name()` uses the cached name-to-index metadata from the owning `Regex`

### 2. Syntax and AST

Update `src/Token.w`, `src/Lexer.w`, `src/Parser.w`, and `src/Ast.w`.

Lexer:
- Add `TK_REGEX_LIT`
- Add dedicated tokens for `=~` and `!~`
- Extend identifier lexing so `$1`, `$name`, `$foo_bar` lex as `TK_IDENT`
- Keep the token span over the full regex literal; parser splits `pattern` and `flags` from source text
- Use context-sensitive `/` disambiguation exactly from `docs/regex-spec.md`
- Regex scanning must respect escaped `/`, escaped `\\`, and character classes `[...]`
- Unknown literal flags are a compile error; duplicate flags are accepted and deduplicated

AST choices:
- Add `NK_REGEX_LIT`
- Add `NK_PAT_REGEX` for regex `match` arms
- Do **not** add `NK_MATCH_OP` / `NK_NEG_MATCH_OP`; parse `=~` and `!~` as `NK_BINARY` with new `BinaryOp` values. This matches the current Pratt parser and reduces downstream branching.

Parser behavior:
- `/.../flags` parses anywhere an expression parses
- `=~` / `!~` use equality-precedence
- `match` arms may use regex literals directly as patterns
- No parser-time capture injection. Parser only needs to accept `$...` identifiers and regex nodes.

### 3. Sema rules and capture scope

Update `src/Sema.w` and `src/SemaCheck.w`.

Type ownership:
- `Regex`, `Match`, `Captures`, and `RegexError` are normal named types from `std.regex`
- The compiler must not register `Regex` as a primitive/builtin type
- Sema resolves `Regex` through the prelude import path, just like `Vec` / `Option`

Operator rules:
- `lhs =~ rhs` requires `lhs: str-compatible`, `rhs: Regex`
- `lhs !~ rhs` requires the same and returns `bool`
- Regex literals typecheck as `Regex`
- Regex `match` arms require the `match` subject to be `str-compatible`

Capture-binding defaults:
- Scoped `$...` bindings are available only for:
  - `if text =~ /literal/:`
  - `while text =~ /literal/:`
  - regex `match` arms
- `!~` never creates captures
- Compound boolean expressions do not get magic captures
  - `if ready and text =~ /.../:` is valid boolean code, but `$1` is not available
  - `if text =~ /a/ or text =~ /b/:` is valid boolean code, but `$1` is not available
- `=~` with a non-literal `Regex` value returns `bool` but does not create `$...` locals in v1
- Using `$...` outside an eligible body is a compile error
- Using `$name` / `$N` that the literal does not declare is a compile error

Implementation strategy:
- Analyze regex literals in sema to extract:
  - numbered group count
  - named group map
- Store that metadata in `AstPoolState`, keyed by the `NK_REGEX_LIT` node
- When checking an eligible `if` / `while` body or regex `match` arm, push synthetic scoped bindings for the declared captures before checking the body, then pop them afterward
- Record per-body capture metadata so lowering can materialize the synthetic locals before user code in that body

LSP/tooling:
- Update hardcoded prelude completions in `src/Lsp.w` so `Regex`, `Match`, `Captures`, and `RegexError` appear like other prelude types

### 4. MIR lowering and codegen

Update `src/MirLower.w`, `src/CodegenTraits.w`, and `src/CodegenDispatch.w`.

Regex literals:
- Lower each literal to a synthetic module runtime-init global using the existing `module_runtime_init` machinery
- Do not invent a separate startup path
- Emit one synthetic global per literal site, with dedup by exact pattern+flags within a module if easy; if dedup complicates bootstrap, use one-per-site for v1
- Runtime init helper calls `Regex.__compile_literal(pattern, flags, file, line, col)`

`=~` / `!~`:
- Non-capturing boolean use lowers to `Regex.is_match(text)` or `Regex.captures(text).is_some()`
- Direct-capture conditions lower to:
  - evaluate literal/global regex
  - call `Regex.captures(text)`
  - branch on `is_some()`
  - materialize synthetic `$...` locals at controlled-body entry from the `Captures` value
- Named and numbered capture locals should use helper accessors that produce `str`, with unmatched optional captures becoming `""`

Regex `match` arms:
- Lower regex arms as ordered `captures()` probes against the string subject
- On success, branch into the arm body and materialize that arm’s `$...` locals before lowering user code
- Non-regex arms keep existing lowering behavior

Critical constraint:
- Do not try to implement regex literals through general comptime execution. The current comptime path cannot call the migrated PCRE2 runtime safely enough for this milestone.

### 5. Follow-up phase after syntax lands

After the above is green, do a second pass for:
- compiler-side regex literal validation in sema
- optional literal dedup improvements across a module
- `captures_all`, `replace_all_fn`, `splitn`
- JIT
- broader `pcre2test` corpus coverage
- any future expansion of capture scope beyond direct positive conditions

Compiler-side literal validation should be a dedicated compiler validation path, not a vague “run it at comptime” shortcut.

## Test Plan

Add or update tests in `test/behavior`, `test/compile_errors`, and the PCRE2 harnesses.

Behavior:
- `Regex.compile()` / `compile_flags()` success and failure
- `is_match`, `find`, `captures`, `by_name`, `replace_all`, `split`
- `/.../flags` lexing and slash-vs-division disambiguation
- direct `if text =~ /.../:` with `$0`, `$1`, `$name`
- direct `while text =~ /.../:` with capture reuse per iteration
- `!~` boolean semantics with no captures
- regex `match` arms with capture bindings
- repeated use of the same literal in one module reuses correct compiled state

Compile errors:
- unknown literal flag
- `$1` outside regex-controlled scope
- `$name` not declared by the regex literal
- `$1` used after `!~`
- `$1` used inside compound boolean cases
- `$1` used when RHS is a non-literal `Regex` variable
- regex `match` arm applied to non-string subject

Engine regression gates:
- `make build`
- `make fixpoint`
- `make test`
- `make test-pcre2`

## Assumptions and Defaults

- `Regex` stays a stdlib/prelude type; the compiler owns only the syntax and lowering.
- V1 capture magic is intentionally narrow: direct positive conditions and regex `match` arms only.
- Non-literal `Regex` values are supported for boolean matching, but not for magic `$...` locals.
- Invalid regex literals are a loud runtime failure in this milestone; compile-time literal validation is a separate follow-up.
- Full upstream `pcre2test` corpus and JIT are not blockers for this milestone.
- After implementation, update `docs/regex-spec.md` and `docs/regex-plan.md` to reflect:
  - compiler-known syntax + stdlib-owned data model
  - direct-condition-only capture scope
  - staged literal validation
