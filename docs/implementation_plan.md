# Implementation Plan for Open Issue Campaign

This plan orders the enriched open issues so implementation can proceed without
building features on unstable semantic ground. It is intentionally conservative:
finish substrate and decision issues first, then high-impact correctness bugs,
then broad feature surfaces, then the coverage-only sweep.

Every issue remains a separate logical change unless the enriched body says two
issues must land together. After each implementation slice, run the repository
verification gates required by `AGENTS.md`: `with build`, `with build
:fixpoint`, `with build :test`, and `with build :test-green` before seed or
install targets.

## Operating Rules

1. Do not weaken checks to get green. If a diagnostic gate fails, fix the code
   or get a maintainer ruling that the gate is wrong.
2. When an issue is premise-stale, verify the current behavior and close or
   retarget it as a test/documentation issue. Do not implement the old premise.
3. Treat the coverage issues in Phase 13 as close-to-the-feature work when
   practical. They are grouped at the end for accounting, but a feature PR
   should close its matching test issue whenever the implementation and tests
   are naturally one change.
4. Runtime and link-path changes follow the bootstrap sequencing rules in
   `AGENTS.md`; do not mix runtime-object changes with `Link.w` activation in
   the same commit.

## Phase 0: Baseline Decisions and Drift Gates

These unblock later work by settling grammar/API questions and keeping the
spec, requirements, and implementation inventories synchronized.

- `#386` Regenerate docs/requirements.md against current spec v7.1
- `#410` Add the spec inventory gate (keywords/attributes/CLI/modules vs spec tables)
- `#385` Stdlib uses an '=' body introducer not in §29.13 — spec it or migrate
- `#381` Decide the spawn keyword: spec it or remove it
- `#429` Emit spec'd diagnostic codes (E0901, E0951-3, E1101-2, E1201) (§29.12)
- `#380` Enforce pub visibility across module boundaries
- `#454` Enforce explicit types at module boundaries (§4.6)

## Phase 1: Build, Toolchain, Package, and Configuration Surface

This phase makes project configuration and CLI behavior explicit before deeper
compiler work relies on it.

- `#425` --target flag and cross-compilation path (§18.5)
- `#450` with.toml: feature flags, target defaults, defines/link-libs, version constraints (§18.5a)
- `#548` [link] libs key parsing (§16.8)
- `#451` [deps.c.X] manual C dependency tables (§18.8)
- `#466` Hash-pinned lock.json and with get restore (§18.4, §18.8)
- `#467` with remove / with update; init layout fixes (§18.8)
- `#547` With-package source for with get (§18.8)
- `#359` Make embed_file a tracked-input comptime intrinsic
- `#360` Make capability-bearing build effects reproducible and auditable
- `#403` Parse [runtime] with.toml keys (fiber_stack_size, fiber_pool_size)
- `#424` Copy size warning and copy_warn_threshold (§2.3)
- `#476` std.os Layer 1 platform module (§18.6)
- `#537` Implement with doc and with repl (§18.5)

## Phase 2: Parser, Control Flow, and Small Semantic Corrections

These are mostly local correctness fixes with limited dependency fan-out.
Landing them early reduces noise for the larger phases.

- `#461` Bug: separator before numeric suffix accepted (1_000_u64) (§29.1)
- `#443` Bug: expression-position if without else accepted (§9.1)
- `#445` Bug: 'a in b in c' accepted; must be a non-associativity error (§9.9)
- `#448` Bug: labeled do-while colon form fails to parse (§13.5c)
- `#447` Enforce label-must-start-statement error (§13.5a)
- `#462` Bug: one-liner semicolon split inside balanced delimiters (§18.5b.5)
- `#375` with expr as mut x: must always return the binding (remove Unit-dispatch)
- `#382` Implicit default return: apply only when the body has no explicit value return
- `#401` Implement value-carrying break for loop (§13.5d)
- `#543` Unreachable-code detection: goto and Never-call divergence (§20b.5)
- `#459` Lint: suggest 'x not in y' for 'not (x in y)' (§9.9)
- `#371` Remove Result from the hardcoded @[must_use] set
- `#372` Remove the move x/copy x acknowledgment requirement for consuming arguments
- `#384` Opt-in lint: non-exhaustive statement-position match

## Phase 3: Panic, Primitive Runtime Correctness, and Numeric Builtins

Do the loud-failure substrate first, then user-visible formatting and primitive
bugs. Several of these affect test harness expectations, so keep the phase
sliced and rerun the full verification gates after each runtime change.

- `#544` Bug: todo()/unreachable() lower to LLVM unreachable, not a panic (§29.10, §4.10, §14.11.1)
- `#545` Bug: .unwrap()/.expect() do not panic on None/Err — return garbage (§10.5, §10.6)
- `#438` Bug: default float display prints 'inf' for most values (§15.4)
- `#440` f-string float modes: :e scientific and bare :f (§15.4.4)
- `#428` Debug-mode bounds checks for array/slice indexing (§4.3a, §4.8a)
- `#422` Comptime evaluation of bit-manipulation methods (§4.2.4)
- `#446` Int and UInt prelude aliases (§4.1)
- `#546` void vs Unit divergence (§16.3b, §4.1)
- `#460` Bug: bare null silently defaults to *const i8 (§16.10)
- `#463` Opaque type misuse diagnostics (§16.9)
- `#539` Bug: transmute lacks same-size compile error (§16.12)

## Phase 4: Ownership, Borrowing, Drop, Ephemerality, and no_std

These issues define the safety model that later stdlib and async features rely
on. Do not move into generic containers or channel ownership before this phase
is stable.

- `#430` Bug: Drop expression temporaries are never dropped (§2.4)
- `#478` Bug: @[tailrec] accepts Drop local live across recursive call (§9.2)
- `#444` Borrow checker Rule 7: implicit drop is a use (§21.1)
- `#362` Make ephemerality provenance-tracked and modular
- `#378` Implement returned-view origin tracking (§21.1 Rule 6) with the §22.3 diagnostic contract
- `#477` Make stdlib guards and borrowed-data iterators canonically ephemeral (§5.3)
- `#355` Make unproven ephemeral task escape a hard error
- `#350` Implement position-based Task disposition semantics
- `#411` Add ArenaScope guard type with @[no_await_guard] (§7.9, §8.3a)
- `#361` Add allocation attribution and no-allocation checking substrate
- `#437` First-class allocators: real Arena/FrameArena/Pool, Vec.new_in, ephemeral virality (§8.3)
- `#457` FixedString[N] for no_std (§18.7)
- `#458` Bug: no_std gating leaks (builtin Vec/HashMap/async/std.io compile under --no-std) (§18.7)
- `#373` Directed diagnostic: by-value parameter that is only read (or whose view escapes) should suggest &T
- `#387` Enforce the §9.1c global data-race rule (conservative single-thread proof)
- `#402` Align @[effect] with §16.3d (declared effect contracts)

## Phase 5: Generic Identity, Traits, Operators, and Type Reflection

This is the keystone phase. `#391` should land before most generic stdlib
surface work. If a smaller issue can land before `#391` without relying on
`TY_GENERIC_INST` identity, keep it separate and prove that in the PR.

- `#391` Fix sema generic type instantiation (TY_GENERIC_INST erasure) — prerequisite for stdlib-as-generics
- `#423` Verify/complete comptime if deferred branch checking in generics (§17.7)
- `#405` Support generic extend blocks (§9.5)
- `#538` Bug: trait default method bodies never resolve (§11.6)
- `#409` Complete derive targets: Default, Hash, Ord, Display, derive(all), derive(Builder) (§11.8)
- `#435` Cross-package extension coherence (§11.4)
- `#469` Prelude operator traits Add/Sub/Mul/Div/MatMul/Neg (§11.7)
- `#464` Bug: user-defined unary neg fails in codegen (§11.7)
- `#408` Implement user Try trait for ? (§10.2, §11.7)
- `#407` Implement user Deref trait for auto-deref (§3.7)
- `#376` Generalize @[iter_of_self] to user iterator constructors
- `#404` Tensor indexing core: multi-scalar + range slices, and MultiIndexMut (§11.7)
- `#541` TypeInfo module API for non-generic contexts (§17.2)

## Phase 6: Calls, Errors, Patterns, and Desugaring

This phase finishes high-level language ergonomics after the lower semantic
rules are in place.

- `#383` Shadowing: allow consuming-rebind (let x = parse(x)?)
- `#397` Implement named arguments (§9.1a)
- `#456` Named-args rule gaps: implicit+default rejection, placeholder+named rejection (§9.1a, §9.4)
- `#398` Implement implicit parameters and with name(expr): contexts (§7.3a, §9.1a)
- `#393` Complete Option/Result combinators incl. context()/with_context() (§10.5, §10.6)
- `#434` Add the Error trait; error declarations implement it (§10.6, §10.8)
- `#433` error ... from: transitive ? conversion (§10.9)
- `#465` Bug: ?. on Result fails MIR lowering (§10.3)
- `#399` Implement let ... else (§9.7)
- `#400` Implement while let (§9.7)
- `#474` Bug: slice ..rest binding fails MIR lowering (§9.7)
- `#439` Full pattern language in for-loop bindings (§13.5)
- `#468` Positional struct patterns: Point(x, y) (§9.7)
- `#472` Refutable parameter patterns / multiple function clauses (§9.7)
- `#406` Implement match in pipelines (|> match:) (§9.7)

## Phase 7: Generic Stdlib Collections and Shared Ownership

Do `Box`, shared ownership, and `Send`/`Sync` before broad generic containers.
Then land collection construction and iteration surfaces.

- `#475` Implement Box[T] (§3.7, §3.9, §8, §18.7)
- `#470` Implement Rc[T] and Arc[T] (+ Shared[T] alias) (§8.2, §8.4, §14.16)
- `#473` Send/Sync enforcement substance (§14.16)
- `#392` Tier-1 collection operations as With generics (§13.3)
- `#388` Implement collect[C] multi-target (HashMap, HashSet, BTreeMap, BTreeSet, String)
- `#389` Implement collection literals: map literals [k: v], empty [:], expected-type targets (§4.3c)
- `#390` Implement target-polymorphic comprehensions incl. map form [k: v for ...] (§13.6)
- `#414` Implement BTreeMap and BTreeSet (§11.7, §18.6)
- `#452` HashMap iteration: for (k, v) in map and .values() (§4.8, §11.7)
- `#377` Slices: implement split_at/split_at_mut and []mut T exclusivity tests

## Phase 8: FFI, C Interop, Layout, Inline Assembly, and Migrator

This phase depends on the safety and layout substrate from earlier phases. Keep
raw C explicit and fail loudly on unsupported translation or ABI surfaces.

Original issues:

- [ ] `#348` c_import macro helpers still shell out to cc -E (macro `-dM` path done; migrator `preprocess_text` `cc -E` remains)
- [x] `#349` Darwin c_import SDK discovery still shells out to xcrun
- [ ] `#357` Replace heuristic c_import auto-defer with proven-ownership Drop wrappers (removal half + regression tests done; positive owning-wrapper path remains)
- [x] `#379` Curated libc contract overlay for c_import modeled surfaces (cstr_in + nullable_ptr + buf_in shipped; buf_out → #604, owned returns → #357)
- [x] `#426` Bug: str→C-string conversion ignores interior NUL (§16.3c)
- [x] `#427` String conversion APIs: CString, .to_cstring()/.as_cstr(), .as_view()/.to_owned() (§15.1–§15.3)
- [x] `#449` Layout attribute validation: @[align] rules, packed-field refs, repr coverage (§16.4)
- [x] `#542` Union safety rules: single initializer, unsafe non-last-written reads (§16.4)
- [x] `#370` Represent unsafe function pointer and callback types
- [x] `#436` Stdlib helpers for boxing/unboxing C callback context (§16.7)
- [x] `#415` Generate C headers for @[c_export] symbols (§16.5)
- [x] `#416` c_import: no_methods opt-out option (§16.2a)
- [x] `#417` c_import omission manifest: source locations, reason chains, directional diagnostics (§16.2)
- [x] `#418` c_import: selective import and strict completeness flag (§16.2)
- [x] `#412` Inline asm: multiple outputs and {name} placeholder substitution (§16.13)
- [x] `#479` @[target("arch")] architecture guards (§16.13)
- [x] `#453` Migrator: setjmp/longjmp diagnostic (§13.5b)

Discovered during Phase 8 (FFI safety substrate; part of this phase):

- [x] `#601` Match-arm pattern bindings dropped on every path (Result/enum drop corruption)
- [x] `#603` c_import macro collection made libclang-only (toward #348)
- [ ] `#604` `[]mut T` arguments: collection→mutable-slice coercion missing (blocks #379 buf_out; cross-function mutable-slice mechanism — language-design item)
- [ ] `#605` Soundness: aggregate construction copies a non-Copy value instead of moving → double-free (struct-literal case fixed; tuple/array/enum + transitive Drop remain)
- [ ] `#606` Soundness: Drop not propagated through Option/Vec/array/tuple/enum contents → leak

## Phase 9: Async, Fibers, Channels, and Concurrency Runtime

Start with compiler-visible suspension and task observation, then channel
ownership, then lock/scheduler work. Multi-OS-thread scheduling comes late.

- `#354` Implement compiler-visible current-fiber suspension model
- `#374` Add Task.was_cancelled() observation API
- `#421` Await combinators: cancel+join when cancelled mid-flight (§14.11.1)
- `#413` async scope: panic in a tracked task must cancel siblings and propagate (§14.9)
- `#480` Enforce Task sendability conditions (§14.7, §14.22)
- `#419` Bug: channel send does not consume; non-integer element types mistyped (§14.15)
- `#540` Tuple .await? composition (§14.11)
- `#394` Implement generic Atomic[T] per §14.17.1
- `#471` Real generic Mutex[T]/RwLock[T] with fiber-aware blocking (§14.17)
- `#395` Implement Once and fiber-aware Condvar (Barrier follows) (§14.17, §18.6)
- `#455` Work-stealing multi-OS-thread fiber scheduler (§14.18, §14.7)
- `#369` Windows async stack overflow handler does not produce controlled runtime diagnostic

## Phase 10: Closures, Generators, dyn, and Advanced Callable Semantics

These depend on the ownership, generic, and async groundwork. Keep closure
capture decisions explicit; do not infer local non-escape from `let` binding
without a real analysis.

- `#420` Bug: closure capture modes diverge from §12.4
- `#431` Async trait methods through dyn dispatch (§11.5)
- `#432` Object safety: vtable exclusion and Box[dyn] consuming-receiver shim (§11.3)
- `#442` Bug: ref-capturing generators escape their referent's scope (§13.4)

## Phase 11: Regex, String, f-string, and Output Polish

Most formatting correctness is in Phase 3. This phase finishes the language
surface around those features.

- `#396` Verify/implement §15.8 regex conformance: branch-scoped $captures in normal code
- `#441` Reject nested f-strings (§15.4)

## Phase 12: Final Feature Triage and Close-Out

Reserve this phase for issues that became premise-stale during earlier work,
follow-up issue filing for newly discovered bugs, and closing implementation
issues whose work was absorbed into a dependency. Do not add new broad feature
work here; if a new blocker appears, file it and insert it into the correct
earlier phase.

## Phase 13: Coverage Sweep

These test-only issues should be closed next to their implementation when
possible. If not, run this sweep after the implementation phases and fill every
remaining coverage gap with focused behavior or compile-error tests.

- `#481` Tests: allocators coverage (§8)
- `#482` Tests: await in generator coverage (§14)
- `#483` Tests: bit methods coverage (§4)
- `#484` Tests: bitpacked coverage (§4)
- `#485` Tests: c import auto methods coverage (§16)
- `#486` Tests: c import coercion coverage (§16)
- `#487` Tests: c import surface coverage (§16)
- `#488` Tests: coherence errors coverage (§29)
- `#489` Tests: collection await coverage (§14)
- `#490` Tests: comptime with clause coverage (§17)
- `#491` Tests: conan build integration coverage (§18)
- `#492` Tests: default builtins coverage (§4)
- `#493` Tests: default op coverage (§10)
- `#494` Tests: derive coverage (§11)
- `#495` Tests: drop order coverage (§20, §21)
- `#496` Tests: drop semantics coverage (§2)
- `#497` Tests: ephemeral iterators coverage (§13)
- `#498` Tests: error decls coverage (§10)
- `#499` Tests: extern c void coverage (§16)
- `#500` Tests: ffi layout coverage (§16)
- `#501` Tests: fiber stack pool coverage (§14)
- `#502` Tests: fmt block style coverage (§29)
- `#503` Tests: fstring spec coverage (§15)
- `#504` Tests: generator restrictions coverage (§13)
- `#505` Tests: inline asm coverage (§16)
- `#506` Tests: labels goto edge cases coverage (§13)
- `#507` Tests: migrate control flow coverage (§13)
- `#508` Tests: named args coverage (§9)
- `#509` Tests: no shadowing coverage (§29)
- `#510` Tests: no std coverage coverage (§18)
- `#511` Tests: numeric intrinsics coverage (§17)
- `#512` Tests: object safety coverage (§11)
- `#513` Tests: one liner edge coverage (§18)
- `#514` Tests: operator dispatch coverage (§11)
- `#515` Tests: optional chaining coverage (§10)
- `#516` Tests: output functions coverage (§15)
- `#517` Tests: partial app coverage (§9)
- `#518` Tests: pattern forms coverage (§9)
- `#519` Tests: prelude shadowing coverage (§18)
- `#520` Tests: raw pointer lowering coverage (§16)
- `#521` Tests: result discard coverage (§10)
- `#522` Tests: saturating ops coverage (§4)
- `#523` Tests: sec4 misc gaps coverage (§4)
- `#524` Tests: select await edge coverage (§14)
- `#525` Tests: ss14 9 scope coverage (§14)
- `#526` Tests: ss29 block syntax coverage (§29)
- `#527` Tests: ss29 lexical coverage (§29)
- `#528` Tests: string types coverage (§15)
- `#529` Tests: struct literal rules coverage (§4)
- `#530` Tests: tailrec coverage (§9)
- `#531` Tests: task surface coverage (§14)
- `#532` Tests: todo unreachable coverage (§29)
- `#533` Tests: trait coherence coverage (§11)
- `#534` Tests: tuple await coverage (§14)
- `#535` Tests: unsafe forms coverage (§19)
- `#536` Tests: with control flow coverage (§23, §7)

## Parallelization Notes

After Phase 0, some lanes can proceed in parallel if they do not share files or
semantic substrate:

- Tooling/package work in Phase 1 can run alongside small parser fixes in
  Phase 2.
- FFI tests and migrator diagnostics can run alongside non-runtime portions of
  Phase 8.
- Coverage issues can be paired with their owning implementation issue, but do
  not land tests that encode known-broken behavior as expected success.

Avoid parallelizing across these dependency boundaries:

- Do not start collection generics before `#391`.
- Do not start channel ownership or task sendability before `#473` and the
  relevant ownership/drop substrate.
- Do not start `std.os` or broad FFI wrapper work before the raw/ modeled C
  boundary issues are clear.
- Do not run runtime-link migration work in parallel with unrelated runtime
  object changes.
