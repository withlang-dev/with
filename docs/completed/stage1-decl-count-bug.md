# Stage1 Declaration-Count Sensitivity Bug

Status: **FIXED** (session 3, 2026-04-29).
Date: 2026-04-29
Updated: 2026-04-29 (session 3 — root cause found and fixed)

## Root Cause

`parse_const_decl` in `src/Parser.w` packed the type-annotation extras
index with `(type_extra + 1) * 4`, but all readers (including
`top_level_let_type_ann_extra` in `src/SemaDecl.w`) expected `* 16`.

Commit **f2e202c** (p7.11+p7.12: §15.4/§15.12) migrated the
`NK_LET_DECL.d2` flag layout from 2-bit (`mut|pub|type_extra*4`) to
4-bit (`mut|pub|global|global_var|type_extra*16`). It updated
`parse_top_level_let` and all 5 reader sites but missed `parse_const_decl`.

The mismatch caused `collect_let_decl` to read the wrong extras index
for every `const X: T = ...` declaration. The decoded index was
`(actual + 1) / 4 - 1` instead of `actual` — pointing to an unrelated
node in the extras array. Which node it hit depended on the total size
of the extras array, which changed whenever any module's declaration
count changed. Most of the time the wrong node happened to be a
primitive type reference (i32, etc.) and the error was silent. When the
wrong node pointed to a non-primitive type from a module not visible
from the const's source file, `lookup_named_type_visible` correctly
rejected it.

## Fix

One-character change: `src/Parser.w:1879` — `* 4` → `* 16`.

## Why the Bisect Found 365e5ab

The actual encoding bug was introduced in f2e202c (the parent commit).
365e5ab was found by bisect because it added enough extras (new AstPool
fields, `@[iter_of_self]` attribute handling) to shift the decoded
index from a harmless target to a TokenList type node from Token.w.
The bug was latent in f2e202c — it just happened to point to an
innocuous node by luck.

## Symptom

Stage1/stage2 produced bogus **"unknown type X"** errors at unrelated
source locations when the top-level declaration count in certain
compiler source modules changed by even one. The affected `const`
declarations were `SEV_ERROR` and `SEV_WARNING` in `src/Diagnostic.w`.

## Verification

- `make build` — passes
- `make fixpoint` — stage2 == stage3
- `make test` — 721 pass, 1 pre-existing fail (issue114_condition_assign)
- All 6 module reproducers (Token.w, CImport.w, Parser.w, Lexer.w,
  InternPool.w, Source.w) now pass with dummy functions appended

## False Trails Ruled Out

- **`decl_source_paths` corruption**: lengths match, indices aligned
  correctly. Ruled out (session 2–3).
- **Prelude DFS terminating early**: module graph byte-identical between
  runs. Ruled out (session 2).
- **Module-ID instability**: stable across runs. Ruled out.
- **`validate_generic_type_decls` stale context**: this function doesn't
  call `update_decl_source_context`, but the error didn't come from it.
- **`ci_syms` / `is_ci_visible` gate**: TokenList is not in `ci_syms`.
- **Associated type binding resolution**: the impl extras at the
  decoded index happened not to be 12834. Ruled out.

## Previously Blocked Work (Now Unblocked)

- P10.x `&mut` migration sweep
- P11 second seed reinstall
- P12 lockdown
