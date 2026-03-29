# Detailed Plan — Remaining Finalize Items

Each item is analyzed with evidence, scope, and implementation steps.

---

## Phase 6.1: Delete sema_is_builtin_trait_name — DONE ✓

Replaced with `lang_trait_syms` HashMap (4 language-level traits:
Copy, Drop, Send, ScopedSend). Other 13 resolve from prelude.
Orphan rule only enforced for local impl decls. Commit: `392de03`.

~~**Location:** `src/Sema.w:2612-2629`~~

**Problem:** 17 trait names are hardcoded in a function. Five call sites
check "is this a builtin trait?" before allowing impl/bound/trait-object
usage.

**Hardcoded traits (17):** Copy, Drop, Scoped, ScopedMut, Debug,
Display, Default, Iter, IntoIter, Eq, Hash, Ord, Contains, Index,
IndexMut, Send, ScopedSend

**Call sites (5):**
1. Line 2676 — `collect_impl_decl`: allows impl of builtin traits
   without trait_lookup entry
2. Line 2681 — orphan rule: treats builtin traits as "local"
3. Line 2992 — `dyn Trait` validation
4. Line 3019 — where clause bound validation
5. Line 3349 — trait object type resolution

**Current prelude coverage:** 11 of 17 traits defined in
`lib/std/traits.w`. Missing: Copy, Contains, Index, IndexMut, Send,
ScopedSend.

**Implementation:**
1. Define the 6 missing traits in `lib/std/traits.w` (stub declarations)
2. Ensure all 17 traits are imported via prelude
3. At all 5 call sites, replace `sema_is_builtin_trait_name(name)` with
   `self.trait_lookup.contains(trait_sym)` (traits from prelude are
   already in trait_lookup)
4. For orphan rule (site 2): check `self.prelude_trait_syms.contains()`
   instead (add a prelude trait tracking set)
5. Delete `sema_is_builtin_trait_name` function
6. `make build && make fixpoint`

**Complexity:** Medium. Files: `src/Sema.w`, `lib/std/traits.w`

---

## Phase 6.2: Pre-intern String Dispatch Symbols — DONE ✓

Added 36 pre-interned sym_* fields to Codegen struct. Converted all
59 string dispatch sites to O(1) symbol ID comparisons. 34 string
comparisons remain intentionally (primitive types, ABI names, runtime
C functions).

~~**Location:** `src/Codegen.w` — 92 string comparisons~~

**Problem:** Codegen dispatches on type/function names using string
equality (`name == "Vec"`, `name == "Option"`, etc.). This is O(n)
per comparison and not cache-friendly.

**Top strings (by frequency):** Self (8), Vec (5), self (5), Result (5),
sizeof (4), size_of (4), Option (4), Unit (2), Box (2)

**Implementation:**
1. Add ~25 symbol fields to Codegen struct:
   ```
   sym_vec: i32, sym_option: i32, sym_result: i32,
   sym_hashmap: i32, sym_self: i32, sym_Self: i32, ...
   ```
2. Initialize in `Codegen.init`: `self.sym_vec = self.intern.intern("Vec")`
3. Replace each `name == "Vec"` with `name_sym == self.sym_vec`
4. `make build && make fixpoint`

**Complexity:** Medium (mechanical). Files: `src/Codegen.w`

---

## P2: Eliminate i32 Fallbacks

**Location:** `src/Codegen.w` — 103 uses of `wl_i32_type`

**Problem:** ~68 uses are fallbacks where unknown types default to i32.
This masks type resolution bugs silently.

**Categories:**
- Legitimate (~35): building i32 constants, parameters, struct fields
- Fallback (~68): unknown type → i32 default

**Five specific fallback sites:**
1. Line 2016: `resolve_node_type_expr()` — unmatched type → i32
2. Line 2204: `type_bits_to_llvm_int()` — unknown width → i32
3. Line 2819: `gen_function()` — failed return type → i32
4. Line 2881: `gen_function()` — failed trait object type → i32
5. Line 3452: `monomorphize_method_dispatch()` — missing type params → i32

**Implementation:**
1. Audit all 103 `wl_i32_type` uses, classify as legitimate vs fallback
2. For each fallback: set `self.had_error = 1`, emit specific error
   message with location, return `wl_get_undef()` instead of `wl_i32_type`
3. Add a helper: `fn Codegen.fallback_error(context: str) -> i64`
4. Replace fallback sites incrementally (5-10 per commit)
5. `make build && make fixpoint` after each batch

**Complexity:** Medium-High. Files: `src/Codegen.w`

---

## P5: HashMap Determinism Audit — DONE ✓ (already safe, no iteration found)

**Location:** All src/ files — 160 HashMap declarations

**Problem:** If HashMaps are iterated, non-deterministic key order could
break fixpoint.

**Finding: ALREADY SAFE.** No HashMap iteration detected in the
compiler source. All 160 HashMaps are used for lookup only
(`.get()`, `.contains()`, `.insert()`). No `.keys()`, `.values()`,
`.entries()`, or for-in-loop over HashMap found.

**Evidence:** Fixpoint holds (stage2 == stage3), which proves output
determinism.

**Implementation:** Mark as done. No code changes needed. Add a comment
in `docs/finalize.md` documenting the audit result.

**Complexity:** None (already verified).

---

## P8: NK_POISONED Error Recovery — DONE ✓

Added `Parser.poisoned_expr()` helper that creates NK_POISONED_EXPR
nodes. Changed 15 expression-level error sites in Parser.w to return
poisoned nodes instead of 0. Added NK_POISONED_EXPR handler in
MirLower.w (returns unit_operand). Sema already handled it (returns
TY_ERR). Bottom-of-stack dispatchers (parse_primary, parse_pattern,
parse_type_expr) advance past bad token for forward progress.
4 new error recovery tests. Commit: `73c6116`.

~~**Location:** `src/Ast.w` (lines 26, 78), `src/Parser.w`~~

**Problem:** Parser returns `0` (null node) after errors. Downstream
passes receive null nodes and may crash or produce confusing secondary
errors.

**Current state:** `NK_POISONED_DECL = 9` and `NK_POISONED_EXPR = 69`
already defined in Ast.w but NEVER EMITTED by the parser. 85 `return 0`
statements in Parser.w after `emit_error` calls.

**Implementation:**
1. Create helper `fn Parser.poisoned_node(start, end) -> NodeId` that
   emits `NK_POISONED_EXPR`
2. Replace `return 0` after `emit_error` calls with
   `return self.poisoned_node(start, end)`
3. In Sema.w: when `kind == NK_POISONED_EXPR`, return `TY_ERR` without
   emitting secondary errors
4. In Codegen.w: when `kind == NK_POISONED_EXPR`, skip codegen (emit
   nothing)
5. `make build && make fixpoint`

**Complexity:** Medium. Files: `src/Parser.w`, `src/Sema.w`,
`src/Codegen.w`, `src/MirLower.w`

---

## P11: Split Codegen.w and Sema.w — DONE ✓

Both large files split to under budget:

**Codegen.w:** 10,491 → 3,974 lines. Split into:
- CodegenDispatch.w (5,566 lines — MIR dispatch + mono)
- CodegenTraits.w (1,380 lines — trait collection + vtables)

**Sema.w:** 9,112 → 1,997 lines (commit `c694460`). Split into:
- SemaCheck.w (4,811 lines — type checking)
- SemaDecl.w (1,761 lines — declaration processing)
- SemaDiag.w (1,130 lines — diagnostics)

Uses `use Codegen`/`use Sema` pattern to define methods on the type
from separate files.

---

## P13: Phase Boundary Tests — DONE ✓ (13 tests, commit `a7f22d8`)

**Location:** `test/` directory

**Problem:** No tests verify dump output (`--dump-tokens`, `--dump-ast`,
`--dump-mir`). Phase outputs are untested.

**Current test directives:** `expect-stdout`, `expect-error`,
`check-only`, `skip`

**Implementation:**
1. Add `expect-dump-ast` directive to test runner
2. Write 3 lexer tests: keyword tokens, string interpolation, indentation
3. Write 3 parser tests: if-else structure, match arms, function decl
4. Write 3 sema tests: type annotations, inferred types, error types
5. Write 3 MIR tests: basic blocks, drop insertion, control flow
6. `make build && make fixpoint`

**Complexity:** Small. Files: test runner in `src/main.w`, new test files

---

## P14: Verify Reserved Syntax — DONE ✓ (11 tests, commit `3e1ef15`)

**Location:** `src/Token.w`, `src/Parser.w`

**Problem:** Some reserved keywords lack error-case tests.

**Current state:** 48 keywords defined. Most are implemented. Reserved
but unimplemented: `ERRDEFER` (partially), `MOVE` (partially),
`OPAQUE`, `NULL`, `UNION` (emit errors).

**Implementation:**
1. Write test for each reserved keyword that emits an error:
   - `test/compile_errors/err_reserved_errdefer.w`
   - `test/compile_errors/err_reserved_move.w`
   - `test/compile_errors/err_reserved_opaque.w`
   - `test/compile_errors/err_reserved_null.w`
2. Verify `const`, `it`, `where`, `async`, `await`, `yield` all work
   (behavioral tests)
3. Audit for missing reservations: `macro` is not reserved — add it?
4. `make build && make fixpoint`

**Complexity:** Small. Files: new test files

---

## Phase II-2: Fix Generic Type Erasure in Sema — DONE ✓

Codegen caches fixed to key by sema_tid. Dead cache fields removed.
MIR places carry sema types. Option/Result reverse lookups replaced
with sema queries. Instantiation cache replaced with i64 hash keys
(commit `9775c13`). All layers complete.

**Complexity:** Large. Files: `src/Codegen.w`, `src/Sema.w`, new tests

---

## Phase II-5: C Backend Completion — Intrinsics DONE ✓

**Location:** `src/CCodegen.w` (4,440 lines)

All 54 MIR intrinsics now handled (commit `f434b08`). CCodegen.w
grew from 3,775 → 4,440 lines with the 37 new intrinsic handlers.

**Remaining work:** Self-compile + cross-compilation testing.

**Path to self-compile:**
1. ~~Handle all intrinsics~~ — DONE
2. `with build --emit-c src/main.w` produces `out/main.c`
3. `gcc out/main.c runtime/*.c -o with_from_c`
4. `./with_from_c check src/main.w` must succeed

**Complexity:** Medium (intrinsics done, integration testing remains).
Files: `src/CCodegen.w`

---

## Phase II-6: Tooling — Mostly DONE

### `with fmt` — Code Formatter — DONE ✓

Implemented in main.w (commit `e72847c`). Supports `-w` (write)
and `-l` (list) modes. AST round-trip formatting.

### `with bench` — Benchmarking

**Current state:** No command handler.
**Approach:** `@[bench]` attribute on functions, iteration harness.
**Files:** `src/main.w`, `src/Parser.w` (attribute)
**Complexity:** Low-Medium

### `with test` improvements — DONE ✓

`@[test]` attribute discovery and `--filter` implemented
(commit `cbcfa85`).

### Error message suggestions — Partially DONE

"Did you mean?" for undefined variables/types implemented with
Levenshtein distance (commit `169dac7`). Remaining: function
signature display on arity mismatch, audit for missing locations.
**Files:** `src/Sema.w`, `src/SemaDiag.w`

---

## Priority Order

| Priority | Item | Impact | Effort | Status |
|----------|------|--------|--------|--------|
| 1 | P5 (HashMap audit) | Verification | None | **DONE** ✓ |
| 2 | P14 (reserved syntax) | Test coverage | Small | **DONE** ✓ |
| 3 | P13 (phase tests) | Test coverage | Small | **DONE** ✓ |
| 4 | P8 (poisoned nodes) | Error quality | Medium | **DONE** ✓ |
| 5 | Phase 6.1 (builtin traits) | Code quality | Medium | **DONE** ✓ |
| 6 | Phase 6.2 (pre-intern) | Performance | Medium | **DONE** ✓ |
| 7 | P2 (i32 fallbacks) | Correctness | Medium-High | **DONE** ✓ |
| 8 | P11 (split Codegen+Sema) | Maintainability | Large | **DONE** ✓ |
| 9 | Phase II-6 (tooling) | User experience | Large | **Mostly DONE** |
| 10 | Phase II-2 (generics) | Correctness | Large | **DONE** ✓ |
| 11 | Phase II-5 (C backend) | Portability | High | **Intrinsics DONE** |
