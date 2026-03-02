# Wave 0 Dump Spec

This document defines the canonical, deterministic text formats for Stage0 dump outputs used as the self-host oracle baseline.

## Scope

Dump kinds:

1. `tokens`
2. `ast`
3. `typed`
4. `llvm`

Common rules:

- UTF-8 text, Unix newlines (`\n`).
- Deterministic ordering only (source-order traversal unless otherwise stated).
- No pointer addresses.
- No absolute host paths in deterministic mode.
- Numeric spans are byte offsets into source (`start..end`, half-open).

---

## 1. Tokens Dump

Command intent:

- `--dump-tokens` or `tokens <file.w>`

Header:

```text
tokens file=<path> count=<N>
```

- `<path>` is source path exactly as provided by CLI (deterministic mode may normalize to repo-relative in future; current canonical form is CLI path).
- `<N>` is number of lexer tokens produced (including EOF token if lexer emits one as a regular token row).

Row format (one token per line):

```text
tok[<i>] tag=<TAG> span=<start>..<end> lex="<escaped_lexeme>"
```

Where:

- `<i>`: zero-based token index in source order.
- `<TAG>`: lexer token tag name (`identifier`, `int_lit`, etc.).
- `<start>..<end>`: byte span.
- `<escaped_lexeme>`:
  - backslash escapes required for `\`, `"`, `\n`, `\r`, `\t`
  - all other bytes emitted as-is.

Example:

```text
tok[0] tag=kw_fn span=0..2 lex="fn"
tok[1] tag=identifier span=3..7 lex="main"
```

---

## 2. AST Dump

Command intent:

- `--dump-ast` or `ast <file.w>`

Header:

```text
module span=<start>..<end> decls=<N>
```

Declaration index table:

```text
decl[<i>] kind=<DECL_KIND> span=<start>..<end>
```

Separator:

```text
---
```

Body:

- Canonical AST render text in declaration/source order.
- Stable spacing/newline style.
- Must not include host-dependent paths.

Notes:

- `<DECL_KIND>` is the `Ast.DeclKind` tag name (e.g. `function`, `type_decl`, `use_decl`, `let_decl`, `extern_fn`, `c_import`, `trait_decl`, `impl_decl`, `poisoned`).
- Body render is canonicalized parser/AST surface representation, not formatter output.

---

## 3. Typed Dump

Command intent:

- `--dump-typed`

Header:

```text
typed module decls=<N>
```

Per declaration:

```text
decl[<i>] kind=<DECL_KIND> span=<start>..<end>
```

Then one or more typed detail lines:

- Function signature:

```text
  fn <name>(<param0>: <type0>, <param1>: <type1>, ...) -> <ret_type>
```

- Optional inferred return line:

```text
  inferred_return: <type>
```

- Extern function signature:

```text
  extern fn <name>(...) -> <ret_type>
```

- Let binding:

```text
  let <name>[ (mut)]: <type>
```

- Type/trait/impl summary lines:

```text
  type <name>
  trait <name>
  impl <trait> for <type>
```

Expression and local-binding typing (function bodies):

```text
<indent>expr <EXPR_KIND> span=<start>..<end> : <type>
<indent>bind <name>[ (mut)]: <type>
```

- Indent is two spaces per depth level.
- Expression traversal order is deterministic preorder over AST child lists.

Type naming rules:

- Use semantic type names from Sema (`i32`, `u64`, `bool`, `str`, type identifiers, etc.).
- No internal IDs or pointer-based identifiers in canonical output.

---

## 4. LLVM Dump

Command intent:

- `--dump-llvm-ir` or `ir <file.w>`

Canonical mode emits textual LLVM IR with normalization:

1. `; ModuleID = ...` line rewritten to:

```text
; ModuleID = '<with_module>'
```

2. `source_filename = ...` line rewritten to:

```text
source_filename = "<source>"
```

3. Any exact source path occurrence matching the compiled source path replaced with `<source>`.

Everything else:

- Preserved byte-for-byte from LLVM text output.
- No optimization pipeline differences in canonical baseline mode (baseline captures should use deterministic dump path consistently).

---

## Validation Rules

For Wave 0 golden checks:

1. Same input + same commit + same toolchain => byte-identical dump files.
2. Golden compare is strict textual diff.
3. Any schema change in this document requires explicit baseline regeneration.
