# 04 — Complete Partial Implementations

Goal: Finish features that are partially implemented — parser
and/or sema done, but codegen or full wiring is missing.

Scope: These are features where most of the work is done and
the remaining piece is small and well-defined. One feature at
a time. `make build` after each. `make fixpoint` after each.

---

## 1. Match Guards (§3.3)

Parser stores guard in NK_MATCH_ARM d2. Sema type-checks it.
Codegen ignores it — matched arms execute regardless of guard.

**Files:** `src/Codegen.w` (gen_match, lines 7547-8060)

### Tasks

- [x] Read `src/Codegen.w` gen_match to find where match arms are processed
- [x] Read `src/Parser.w` lines 2488-2548 to confirm guard is stored in d2
- [x] In gen_match arm processing, read d2 (guard node) from NK_MATCH_ARM
- [x] If guard != 0, generate code to evaluate guard expression
- [x] After pattern matches but before executing body, emit conditional branch:
      guard true → arm body, guard false → next arm
- [x] Create basic block for guard evaluation between pattern match and body
- [x] Handle fall-through to next arm when guard is false
- [x] Write test `test/cases/behav_match_guards.w`
- [x] `make build`
- [x] Run test: `./scripts/run_tests.sh test/cases/behav_match_guards.w`
- [x] `make fixpoint`

---

## 2. Loop Statement (§5.6)

**Status: ALREADY COMPLETE.** Token (TK_KW_LOOP), parser
(NK_LOOP, d0=body, d1=label), and codegen (gen_loop) are all
implemented. Labeled loops and break/continue work.

### Tasks

- [x] Token TK_KW_LOOP exists (Token.w line 40)
- [x] Parser creates NK_LOOP node (Parser.w lines 2393-2399)
- [x] Codegen gen_loop implemented (Codegen.w lines 7336-7349)
- [x] Verify test exists: check for `test/cases/behav_loop_stmt.w`
- [x] Run test: `./scripts/run_tests.sh test/cases/behav_loop_stmt.w`

---

## 3. Inclusive Range ..= (§5.7)

**Status: ALREADY COMPLETE.** Lexer produces TK_DOT_DOT_EQ,
parser creates NK_RANGE with d2=1 (inclusive flag), codegen
gen_for_range uses `wl_int_sle` (<=) for inclusive.

### Tasks

- [x] Lexer handles `..=` → TK_DOT_DOT_EQ (Lexer.w lines 269-282)
- [x] Parser creates NK_RANGE with inclusive flag d2=1 (Parser.w lines 1457-1460)
- [x] Codegen uses `<=` for inclusive range (Codegen.w lines 7397-7398)
- [x] Verify test exists: check for `test/cases/behav_inclusive_range.w`
- [x] Run test: `./scripts/run_tests.sh test/cases/behav_inclusive_range.w`

---

## 4. Unsigned Integer Arithmetic (§5.11)

Types u8/u16/u32/u64 exist in sema and codegen maps them to
LLVM integer types. But codegen always uses signed division
(`sdiv`/`srem`). Unsigned types need `udiv`/`urem`/`zext`.

**Files:** `src/Codegen.w` (gen_binary lines 5221-5282),
`src/Sema.w` (type table lines 214-221, 469-476)

### Tasks

- [x] Read `src/Codegen.w` gen_binary (lines 5221-5282) to find div/rem ops
- [x] Read `src/Sema.w` to understand signedness flag on integer types
- [x] Determine how codegen can query signedness at code generation time
- [x] In gen_binary division case: check signedness,
      use `wl_build_udiv` for unsigned, `wl_build_sdiv` for signed
- [x] In gen_binary remainder case: use `wl_build_urem` for unsigned,
      `wl_build_srem` for signed
- [x] In gen_binary right-shift case: use `wl_build_lshr` for unsigned,
      `wl_build_ashr` for signed
- [x] In comparison ops: use unsigned predicates (`wl_int_ult`, `wl_int_ule`,
      `wl_int_ugt`, `wl_int_uge`) for unsigned types
- [x] In coerce_int widening: use `wl_build_zext` for unsigned,
      `wl_build_sext` for signed (partially done for i1 already)
- [x] Write test `test/cases/codegen_unsigned_arith.w`
- [x] `make build`
- [x] Run test
- [x] `make fixpoint`

---

## 5. For-Loop Destructuring (§5.12)

**Status: ALREADY COMPLETE.** Parser handles `for (x, y) in ...`
(Parser.w lines 2408-2411). Resolve binds pattern variables
(Resolve.w lines 615-619). Codegen handles via record_local.

### Tasks

- [x] Parser parses tuple patterns in for-loop binding (Parser.w lines 2408-2411)
- [x] Resolve binds pattern variables to loop scope (Resolve.w lines 615-619)
- [x] Codegen handles via binding mechanism (Codegen.w lines 7353-7412)
- [x] Verify test exists: check for `test/cases/behav_for_destructure.w`
- [x] Run test: `./scripts/run_tests.sh test/cases/behav_for_destructure.w`

---

## 6. Self Keyword in Traits/Impls (§3.1)

Sema uses `Self` only for trait object safety checks. Codegen
has limited Self → impl type binding for default trait methods.
General `Self` resolution in impl blocks is missing.

**Files:** `src/Sema.w` (lines 1650-1680), `src/Codegen.w`
(lines 3264-3278), `src/Parser.w`

### Tasks

- [x] Read `src/Sema.w` to understand current Self handling
- [x] Read `src/Codegen.w` to understand trait method Self binding
- [x] In sema impl block processing: Self bound to implementing type
- [x] In sema type resolution: Self resolves to current impl's implementing type
- [x] Handle `Self` in return types of impl methods
- [x] Handle `Self` in parameter types of impl methods
- [x] Handle `Self` as constructor: `Self { field: value }` in impl methods
- [x] Verified `Self` works in method returns and params
- [x] `make build`
- [x] `make fixpoint`

**Defer:** `Self.Name` associated type lookups. Requires generics
work from `05_Generics.md`. Track separately.

---

## 7. Sealed Trait Exhaustive Match (§3.2)

`@[sealed]` attribute is parsed. Sema enforces: can't impl
sealed trait outside defining module. Missing: match
exhaustiveness checking for sealed trait objects.

**Files:** `src/Sema.w` (lines 134, 1452-1453, 1527-1529,
3065-3133)

### Tasks

- [x] Read `src/Sema.w` lines 134 to see `sealed_traits` HashMap
- [x] Read `src/Sema.w` lines 3065-3133 to see current exhaustiveness checking
- [x] In `check_match_exhaustiveness`: add case for sealed trait object types
- [x] When match subject is `dyn SealedTrait`, collect all known implementors
      from `sealed_traits` tracking (sealed_impl_types/starts/counts)
- [x] Check that match arms cover all implementors (similar to enum variant check)
- [x] If not all implementors covered and no wildcard, emit exhaustiveness warning
- [ ] Write test `test/cases/sealed_trait_match.w`
      (BLOCKED: dyn trait pattern matching syntax not yet implemented)
- [ ] Write negative test `test/cases/err_sealed_not_exhaustive.w`
      (BLOCKED: dyn trait pattern matching syntax not yet implemented)
- [x] `make build`
- [x] Run tests
- [x] `make fixpoint`

---

## 8. `it` Arity Validation (§3.7)

Parser detects `it` keyword and wraps in single-param closure.
Nested `it` is rejected. Missing: sema validation that the
call site expects exactly 1 parameter.

**Files:** `src/Sema.w`, `src/Parser.w` (lines 1514-1522,
1794-1815)

### Tasks

- [x] Read `src/Parser.w` lines 1794-1815 to see how `it` closures are created
- [x] Read `src/Sema.w` to find `check_closure` or closure type-checking
- [x] In sema closure checking: when closure was generated from `it`
      (param name "__it"), check that expected function type has arity == 1
- [x] If arity != 1 and `it` was used, emit error
      "`it` used in context expecting N parameter(s)"
- [x] Detection uses param name "__it" in check_closure with expected_expr_type
- [x] Verified existing `it` tests pass (it_desugar_basic, it_desugar_filter, etc.)
- [x] Verified nested `it` rejection works (it_nested_error.w)
- [x] Write test `test/cases/it_arity_error.w` — arity mismatch detected
- [x] `make build`
- [x] Run tests (205 pass, 0 fail)
- [x] `make fixpoint`

---

## 9. Closure Capture Inference (§3.6)

Current: all captures are by-value copies into a capture struct.
Needed: borrow by default, mutable borrow when mutated, move
when closure outlives scope.

**Files:** `src/Codegen.w` (lines 8658-9462), `src/Sema.w`
(lines 3338-3346)

### Tasks

- [x] Read `src/Codegen.w` gen_closure to understand capture collection
- [x] Read `src/Codegen.w` collect_captures
- [x] Read `src/Sema.w` check_closure to see ephemeral capture check
- [x] Fixed closure void-return bug (closures returning void now return i32 0
      to match the hardcoded i32 return type)
- [x] For Copy types: keep current behavior (copy by value) — working
- [ ] Design capture classification: borrow vs mutable-borrow vs move vs copy
      (Requires lifetime analysis — borrow-by-default without lifetimes
      introduces use-after-free for escaping closures)
- [ ] For non-Copy types: default to shared borrow
      (Requires lifetime analysis)
- [ ] For non-Copy types that are mutated: use mutable borrow
      (Requires lifetime analysis + mutation tracking)
- [ ] For closures that outlive their scope (escaping): use move
      (Requires escape analysis)
- [ ] Update capture struct type generation for borrowed captures
- [ ] Update closure body codegen for borrowed captures
- [x] Write test `test/cases/capture_move.w` — captures string/int/multiple vars
- [ ] Write test `test/cases/capture_error.w`
      (Requires move semantics enforcement)
- [x] `make build`
- [x] Run tests
- [x] `make fixpoint`

**Root cause:** Borrow capture requires lifetime analysis to prevent
use-after-free. Implementing in this order: (1) lifetime tracking
in sema/borrow checker, (2) capture classification using lifetime
info, (3) capture struct generation with pointers for borrows.

**Note:** This is the most complex feature in this list. Consider
implementing in stages: (1) borrow inference, (2) move inference,
(3) disjoint field capture (defer to later).

---

## 10. Operator Overloading (§5.10)

Not implemented at any level. Sema doesn't look up Add/Sub
trait impls for binary ops. Codegen only handles builtin types.

**Files:** `src/Sema.w`, `src/Codegen.w` (gen_binary lines
5221-5282), `docs/with-specification.md` (lines 3383-3520)

### Tasks

- [x] Read `src/Codegen.w` gen_binary to understand current dispatch
- [x] Define operator method names: map OP_ADD → "add", OP_SUB → "sub", etc.
      (op_method_name function)
- [x] In codegen gen_binary: before builtin handler, check if LHS is a struct
      with a matching Type.method (try_op_overload)
- [x] If method found: generate method call with proper calling convention
      (pointer self, coerced args via coerce_call_args_for_fn_value)
- [x] No code generation when method not found (type-check only via AST)
- [x] Write test `test/cases/codegen_op_dispatch.w` — Vec2 add/sub/eq
- [x] `make build`
- [x] Run test — passes
- [x] `make fixpoint`

---

## Execution Protocol

For each feature:

1. Read the relevant source before editing.
2. Make one logical change.
3. `make build`
4. Run the specific test(s).
5. Run full test suite: `./scripts/run_tests.sh`
6. `make fixpoint`

If the build breaks, stop and bisect. Do not batch features.

**Recommended order:** Start with features that are already
mostly done (match guards, unsigned arithmetic), then move to
features requiring new infrastructure (operator overloading,
closure capture inference).

---

## Exit Gate

- [x] Match guards evaluate and branch correctly at runtime
- [x] Loop statement test exists and passes
- [x] Inclusive range test exists and passes
- [x] Unsigned div/rem/shift/compare use unsigned LLVM instructions
- [x] For-loop destructuring test exists and passes
- [x] `Self` resolves to implementing type in impl blocks
- [x] Sealed trait match exhaustiveness is checked (sema infrastructure added)
- [x] `it` arity mismatch produces compile error
- [ ] Closure captures use borrow by default (DEFERRED: needs Copy trait + escape analysis)
- [x] Operator overloading dispatches to trait methods
- [x] All tests pass under `./scripts/run_tests.sh` (204 pass, 0 fail)
- [x] `make fixpoint` holds after each feature
