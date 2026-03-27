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

## P11: Split Codegen.w

**Location:** `src/Codegen.w` — 10,491 lines (budget: 5,000)

**Problem:** 2.1x over the file complexity budget.

**Largest sections (split candidates):**
1. `gen_function_dispatch` — lines 4967-8835 — **3,869 lines** (37%)
2. `Collect trait info` — lines 3842-4901 — **1,060 lines** (10%)
3. `gen_function_mir_mono` — lines 8836-9500 — **665 lines**
4. `Helper: is method symbol` — lines 955-1619 — **665 lines**

**Implementation:**
1. Extract `gen_function_dispatch` + MIR eval into `src/CodegenMir.w`
   (~3,900 lines). File does `use Codegen` and defines methods on
   the Codegen type.
2. Extract trait collection into `src/CodegenTraits.w` (~1,060 lines)
3. Extract monomorphization into `src/CodegenMono.w` (~665 lines)
4. Each extraction: `make build && make fixpoint`
5. Target: Codegen.w under 5,000 lines after 3 splits

**Complexity:** Large (structural). Files: `src/Codegen.w` → 3-4 new files

**Prerequisite:** Verify the compiler supports defining methods on a type
in a separate file via `use`. Test with a small example first.

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

## Phase II-2: Fix Generic Type Erasure in Sema

**Location:** `src/Sema.w` (generic_inst_cache), `src/Codegen.w`
(parallel type tracking)

**Problem:** Sema creates `TY_GENERIC_INST` types correctly with
distinct type_extra entries for `Vec[i32]` vs `Vec[str]`. But codegen
had parallel caches that could collide. A codegen-level fix was applied
(sema_tid cache keys). The sema level is correct.

**What remains:**
1. Add tests proving `Vec[i32] != Vec[str]` in sema
2. Remove ~2,000 lines of codegen parallel type tracking that duplicate
   sema's work (now that sema_tid is used as cache key)
3. Clean up the 12 remaining `int_to_string` cache key sites (unblocked
   now but was previously blocked by this bug)

**Implementation:**
1. Write `test/behavior/behav_generic_distinct.w` proving Vec[i32] and
   Vec[str] produce different types
2. Audit codegen's `vec_type_to_elem`, `option_payload_types` etc. —
   which are still needed after the sema_tid fix?
3. Remove redundant parallel tracking
4. `make build && make fixpoint`

**Complexity:** Large. Files: `src/Codegen.w`, `src/Sema.w`, new tests

---

## Phase II-5: C Backend Completion

**Location:** `src/CCodegen.w` (3,775 lines)

**Problem:** Only 16 of 54 MIR intrinsics handled (29.6%). Cannot
self-compile.

**Unhandled intrinsics by category:**
- String methods (14): STR_LEN through STR_REPEAT
- Advanced Vec (7): VEC_MAP, VEC_FILTER, VEC_FOLD, VEC_ITER, etc.
- HashMap (2): MAP_CLEAR, MAP_INCREMENT
- Option (2): OPT_IS_NONE, OPT_FILTER
- Format (4): FMT_TO_STR, FMT_DEBUG_STR, FMT_DEBUG, FMT_SPEC
- Integer (3): ROTATE_LEFT, ROTATE_RIGHT, INT_SWAP_BYTES
- Array (1): ARR_LEN
- Dynamic dispatch (2): DYN_VTABLE_CMP, DYN_DOWNCAST
- Generic (1): GENERIC_CALL

**Implementation order (by impact):**
1. String methods — most programs use strings (14 intrinsics, ~200 lines)
2. ARR_LEN, ROTATE_LEFT/RIGHT — trivial (3 intrinsics, ~30 lines)
3. FMT_TO_STR — f-string support (1 intrinsic, ~50 lines)
4. VEC_ITER, VECITER_NEXT, VEC_WITH_CAPACITY (3 intrinsics, ~100 lines)
5. OPT_IS_NONE, OPT_FILTER (2 intrinsics, ~40 lines)
6. MAP_CLEAR, MAP_INCREMENT (2 intrinsics, ~20 lines)
7. DYN_VTABLE_CMP, DYN_DOWNCAST (2 intrinsics, ~60 lines)
8. VEC_MAP, VEC_FILTER, VEC_FOLD (3 intrinsics, ~200 lines)
9. FMT_DEBUG_STR, FMT_DEBUG, FMT_SPEC (3 intrinsics, ~100 lines)
10. GENERIC_CALL (1 intrinsic, ~300 lines — requires monomorphization)
11. INT_SWAP_BYTES, VEC_JOIN, VEC_CONTAINS (3 intrinsics, ~60 lines)

**Path to self-compile:**
1. Handle all intrinsics above
2. `with build --emit-c src/main.w` produces `out/main.c`
3. `gcc out/main.c runtime/*.c -o with_from_c`
4. `./with_from_c check src/main.w` must succeed

**Complexity:** High. Files: `src/CCodegen.w`. Timeline: 3-4 weeks.

---

## Phase II-6: Tooling

### `with fmt` — Code Formatter

**Current state:** Stub error in main.w:305-307.
**Approach:** Parse source → walk AST → emit formatted text.
**Rules:** 4-space indent, 80-column width, trim trailing whitespace.
**Files:** `src/main.w` (routing), new `src/Formatter.w`
**Complexity:** Medium (requires AST → text emission)

### `with bench` — Benchmarking

**Current state:** No command handler.
**Approach:** `@[bench]` attribute on functions, iteration harness.
**Files:** `src/main.w`, `src/Parser.w` (attribute), new `src/Bench.w`
**Complexity:** Low-Medium

### `with test` improvements

**Current state:** Basic runner (30% complete). Runs files, reports
pass/fail. No `@[test]` discovery, no `--filter`.
**Improvements:**
1. `@[test]` attribute discovery
2. `--filter <pattern>` for selective execution
3. Test count and summary reporting
**Files:** `src/main.w`
**Complexity:** Low

### Error message suggestions

**Current state:** 143 diagnostic sites, only 7 (5%) include help.
**Improvements:**
1. "did you mean?" for undefined variables (Levenshtein distance)
2. Function signature display on arity mismatch
3. "use :? for debug" hint on struct display (already done for some)
**Files:** `src/Sema.w`, possible new `src/Suggestions.w`
**Complexity:** Low per site, medium total

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
| 8 | P11 (split Codegen.w) | Maintainability | Large | Open |
| 9 | Phase II-6 (tooling) | User experience | Large | Open |
| 10 | Phase II-2 (generics) | Correctness | Large | Open |
| 11 | Phase II-5 (C backend) | Portability | High | Open |
