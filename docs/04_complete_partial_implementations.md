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

- [ ] Read `src/Codegen.w` gen_match to find where match arms are processed
- [ ] Read `src/Parser.w` lines 2488-2548 to confirm guard is stored in d2
- [ ] In gen_match arm processing, read d2 (guard node) from NK_MATCH_ARM
- [ ] If guard != 0, generate code to evaluate guard expression
- [ ] After pattern matches but before executing body, emit conditional branch:
      guard true → arm body, guard false → next arm
- [ ] Create basic block for guard evaluation between pattern match and body
- [ ] Handle fall-through to next arm when guard is false
- [ ] Write test `test/cases/behav_match_guards.w`:
      ```
      //! expect-stdout: negative
      fn main:
          let x = -5
          match x
              n if n > 0 -> println("positive")
              n if n < 0 -> println("negative")
              _ -> println("zero")
      ```
- [ ] `make build`
- [ ] Run test: `./scripts/run_tests.sh test/cases/behav_match_guards.w`
- [ ] `make fixpoint`

---

## 2. Loop Statement (§5.6)

**Status: ALREADY COMPLETE.** Token (TK_KW_LOOP), parser
(NK_LOOP, d0=body, d1=label), and codegen (gen_loop) are all
implemented. Labeled loops and break/continue work.

### Tasks

- [x] Token TK_KW_LOOP exists (Token.w line 40)
- [x] Parser creates NK_LOOP node (Parser.w lines 2393-2399)
- [x] Codegen gen_loop implemented (Codegen.w lines 7336-7349)
- [ ] Verify test exists: check for `test/cases/behav_loop_stmt.w`
- [ ] If no test, write one:
      ```
      //! expect-stdout: 5
      fn main:
          let mut i = 0
          loop:
              i = i + 1
              if i == 5:
                  break
          println("{i}")
      ```
- [ ] Run test: `./scripts/run_tests.sh test/cases/behav_loop_stmt.w`

---

## 3. Inclusive Range ..= (§5.7)

**Status: ALREADY COMPLETE.** Lexer produces TK_DOT_DOT_EQ,
parser creates NK_RANGE with d2=1 (inclusive flag), codegen
gen_for_range uses `wl_int_sle` (<=) for inclusive.

### Tasks

- [x] Lexer handles `..=` → TK_DOT_DOT_EQ (Lexer.w lines 269-282)
- [x] Parser creates NK_RANGE with inclusive flag d2=1 (Parser.w lines 1457-1460)
- [x] Codegen uses `<=` for inclusive range (Codegen.w lines 7397-7398)
- [ ] Verify test exists: check for `test/cases/behav_inclusive_range.w`
- [ ] If no test, write one:
      ```
      //! expect-stdout: 1
      //! expect-stdout: 2
      //! expect-stdout: 3
      fn main:
          for i in 1..=3:
              println("{i}")
      ```
- [ ] Run test: `./scripts/run_tests.sh test/cases/behav_inclusive_range.w`

---

## 4. Unsigned Integer Arithmetic (§5.11)

Types u8/u16/u32/u64 exist in sema and codegen maps them to
LLVM integer types. But codegen always uses signed division
(`sdiv`/`srem`). Unsigned types need `udiv`/`urem`/`zext`.

**Files:** `src/Codegen.w` (gen_binary lines 5221-5282),
`src/Sema.w` (type table lines 214-221, 469-476)

### Tasks

- [ ] Read `src/Codegen.w` gen_binary (lines 5221-5282) to find div/rem ops
- [ ] Read `src/Sema.w` to understand signedness flag on integer types
- [ ] Determine how codegen can query signedness at code generation time
      (need to check if sema type info is available in Codegen)
- [ ] In gen_binary division case (line 5268-5269): check signedness,
      use `wl_build_udiv` for unsigned, `wl_build_sdiv` for signed
- [ ] In gen_binary remainder case: use `wl_build_urem` for unsigned,
      `wl_build_srem` for signed
- [ ] In gen_binary right-shift case: use `wl_build_lshr` for unsigned,
      `wl_build_ashr` for signed
- [ ] In comparison ops: use unsigned predicates (`wl_int_ult`, `wl_int_ule`,
      `wl_int_ugt`, `wl_int_uge`) for unsigned types
- [ ] In coerce_int widening: use `wl_build_zext` for unsigned,
      `wl_build_sext` for signed (partially done for i1 already)
- [ ] Write test `test/cases/behav_unsigned.w`:
      ```
      //! expect-stdout: 255
      //! expect-stdout: 85
      fn main:
          let x: u8 = 255
          println("{x}")
          let y: u8 = 255
          let z = y / 3
          println("{z}")
      ```
- [ ] `make build`
- [ ] Run test: `./scripts/run_tests.sh test/cases/behav_unsigned.w`
- [ ] `make fixpoint`

---

## 5. For-Loop Destructuring (§5.12)

**Status: ALREADY COMPLETE.** Parser handles `for (x, y) in ...`
(Parser.w lines 2408-2411). Resolve binds pattern variables
(Resolve.w lines 615-619). Codegen handles via record_local.

### Tasks

- [x] Parser parses tuple patterns in for-loop binding (Parser.w lines 2408-2411)
- [x] Resolve binds pattern variables to loop scope (Resolve.w lines 615-619)
- [x] Codegen handles via binding mechanism (Codegen.w lines 7353-7412)
- [ ] Verify test exists: check for `test/cases/behav_for_destructure.w`
- [ ] If no test, write one:
      ```
      //! expect-stdout: a: 1
      //! expect-stdout: b: 2
      fn main:
          let pairs = vec![(1, "a"), (2, "b")]
          for (n, s) in pairs:
              println("{s}: {n}")
      ```
- [ ] Run test: `./scripts/run_tests.sh test/cases/behav_for_destructure.w`

---

## 6. Self Keyword in Traits/Impls (§3.1)

Sema uses `Self` only for trait object safety checks. Codegen
has limited Self → impl type binding for default trait methods.
General `Self` resolution in impl blocks is missing.

**Files:** `src/Sema.w` (lines 1650-1680), `src/Codegen.w`
(lines 3264-3278), `src/Parser.w`

### Tasks

- [ ] Read `src/Sema.w` lines 1650-1680 to understand current Self handling
- [ ] Read `src/Codegen.w` lines 3264-3278 to understand trait method Self binding
- [ ] In sema impl block processing: when entering an `impl Trait for Type` block,
      bind `Self` to the implementing type in the type resolution scope
- [ ] In sema type resolution: when resolving `NK_TYPE_NAMED` with name "Self",
      look up the current impl's implementing type
- [ ] Handle `Self` in return types of impl methods
- [ ] Handle `Self` in parameter types of impl methods
- [ ] Handle `Self` as constructor: `Self { field: value }` in impl methods
- [ ] Write test `test/cases/behav_self_keyword.w`:
      ```
      //! expect-stdout: 3
      fn main:
          type Point = { x: i32, y: i32 }
          impl Point:
              fn origin() -> Self:
                  Self { x: 0, y: 0 }
              fn sum(self) -> i32:
                  self.x + self.y
          let p = Point { x: 1, y: 2 }
          println("{p.sum()}")
      ```
- [ ] `make build`
- [ ] Run test: `./scripts/run_tests.sh test/cases/behav_self_keyword.w`
- [ ] `make fixpoint`

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

- [ ] Read `src/Sema.w` lines 134 to see `sealed_traits` HashMap
- [ ] Read `src/Sema.w` lines 3065-3133 to see current exhaustiveness checking
- [ ] In `check_match_exhaustiveness`: add case for sealed trait object types
- [ ] When match subject is `dyn SealedTrait`, collect all known implementors
      from `sealed_traits` tracking
- [ ] Check that match arms cover all implementors (similar to enum variant check)
- [ ] If not all implementors covered and no wildcard, emit exhaustiveness error
- [ ] Write test `test/cases/sealed_trait_match.w`:
      ```
      //! expect-stdout: circle
      fn main:
          @[sealed]
          trait Shape:
              fn name(self) -> str

          type Circle = { r: i32 }
          impl Shape for Circle:
              fn name(self) -> str: "circle"

          type Square = { s: i32 }
          impl Shape for Square:
              fn name(self) -> str: "square"

          let s: dyn Shape = Circle { r: 5 }
          println(s.name())
      ```
- [ ] Write negative test `test/cases/err_sealed_not_exhaustive.w`:
      ```
      //! expect-check-fail: exhaustive
      ```
      (match on sealed trait missing an implementor arm)
- [ ] `make build`
- [ ] Run tests
- [ ] `make fixpoint`

---

## 8. `it` Arity Validation (§3.7)

Parser detects `it` keyword and wraps in single-param closure.
Nested `it` is rejected. Missing: sema validation that the
call site expects exactly 1 parameter.

**Files:** `src/Sema.w`, `src/Parser.w` (lines 1514-1522,
1794-1815)

### Tasks

- [ ] Read `src/Parser.w` lines 1794-1815 to see how `it` closures are created
- [ ] Read `src/Sema.w` to find `check_closure` or closure type-checking
- [ ] In sema closure checking: when closure was generated from `it`
      (has implicit param), check that expected function type has arity == 1
- [ ] If arity != 1 and `it` was used, emit error E0902:
      "`it` used in context expecting N parameters"
- [ ] Add a flag to the closure AST node or track in sema to distinguish
      `it`-generated closures from explicit closures
- [ ] Write test `test/cases/it_chained_pipeline.w`:
      ```
      //! expect-stdout: 2
      //! expect-stdout: 4
      fn main:
          let v = vec![1, 2, 3, 4]
          let evens = v.filter(it % 2 == 0)
          for x in evens:
              println("{x}")
      ```
- [ ] Write test `test/cases/it_method_syntax.w`:
      ```
      //! expect-stdout: 3
      fn main:
          let v = vec!["a", "bb", "ccc"]
          let lens = v.map(it.len())
          println("{lens.get(2)}")
      ```
- [ ] `make build`
- [ ] Run tests
- [ ] `make fixpoint`

---

## 9. Closure Capture Inference (§3.6)

Current: all captures are by-value copies into a capture struct.
Needed: borrow by default, mutable borrow when mutated, move
when closure outlives scope.

**Files:** `src/Codegen.w` (lines 8658-9462), `src/Sema.w`
(lines 3338-3346)

### Tasks

- [ ] Read `src/Codegen.w` lines 8658-8700 to understand capture collection
- [ ] Read `src/Codegen.w` lines 9380-9452 to understand `collect_captures`
- [ ] Read `src/Sema.w` lines 3338-3346 to see ephemeral capture check
- [ ] Design capture classification: for each captured variable determine
      borrow vs mutable-borrow vs move vs copy
- [ ] Implement classification: scan closure body for mutations of captured vars
      (if mutated → mutable borrow, else → shared borrow)
- [ ] For Copy types: keep current behavior (copy by value)
- [ ] For non-Copy types: default to shared borrow (`&T` in capture struct)
- [ ] For non-Copy types that are mutated: use mutable borrow (`&mut T`)
- [ ] For closures that outlive their scope (escaping): use move
- [ ] Update capture struct type generation to use `ptr` for borrowed captures
- [ ] Update closure body codegen to load through pointer for borrowed captures
- [ ] Write test `test/cases/capture_move.w`:
      ```
      //! expect-stdout: hello
      fn main:
          let s = "hello"
          let f = || println(s)
          f()
      ```
- [ ] Write test `test/cases/capture_error.w`:
      ```
      //! expect-check-fail: capture
      ```
      (closure captures moved value after move)
- [ ] `make build`
- [ ] Run tests
- [ ] `make fixpoint`

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

- [ ] Read `docs/with-specification.md` lines 3383-3520 for trait definitions
      (Add[Rhs, Output], Sub[Rhs, Output], Mul, Div, Neg)
- [ ] Read `src/Codegen.w` gen_binary (lines 5221-5282) to understand current dispatch
- [ ] Read `src/Sema.w` to understand trait impl lookup infrastructure
- [ ] Define operator trait names: map `OP_ADD` → "Add", `OP_SUB` → "Sub", etc.
- [ ] In sema binary op checking: if both operands are user-defined types,
      look up `Add` (or relevant) trait impl for (LhsType, RhsType)
- [ ] If impl found: record the impl method in AST annotation or type context
- [ ] If impl not found and types are not builtin: emit type error
- [ ] In codegen gen_binary: before builtin handler, check if operands have
      operator trait impl
- [ ] If trait impl exists: generate method call to trait method instead of
      LLVM binary instruction
- [ ] Handle `Output` type: the result type comes from the trait impl,
      not assumed to be same as operands
- [ ] Write test `test/cases/behav_op_overload.w`:
      ```
      //! expect-stdout: 4
      //! expect-stdout: 6
      fn main:
          type Vec2 = { x: i32, y: i32 }

          impl Add for Vec2:
              fn add(self, other: Vec2) -> Vec2:
                  Vec2 { x: self.x + other.x, y: self.y + other.y }

          let a = Vec2 { x: 1, y: 2 }
          let b = Vec2 { x: 3, y: 4 }
          let c = a + b
          println("{c.x}")
          println("{c.y}")
      ```
- [ ] `make build`
- [ ] Run test: `./scripts/run_tests.sh test/cases/behav_op_overload.w`
- [ ] `make fixpoint`

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

- [ ] Match guards evaluate and branch correctly at runtime
- [ ] Loop statement test exists and passes
- [ ] Inclusive range test exists and passes
- [ ] Unsigned div/rem/shift/compare use unsigned LLVM instructions
- [ ] For-loop destructuring test exists and passes
- [ ] `Self` resolves to implementing type in impl blocks
- [ ] Sealed trait match exhaustiveness is checked
- [ ] `it` arity mismatch produces compile error
- [ ] Closure captures use borrow by default (not copy)
- [ ] Operator overloading dispatches to trait methods
- [ ] All tests pass under `./scripts/run_tests.sh`
- [ ] `make fixpoint` holds after each feature
