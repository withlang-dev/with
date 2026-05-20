---

# Implementation Priority Checklist

Purpose: track the remaining language and tooling work needed to
finish With for the book, release, and post-release follow-through.

Conventions:
- All items stay unchecked until merged and verified.
- References use `docs/with-implementation-notes.md` section numbers
  plus `docs/with-specification.md` section numbers where the feature
  has a direct language-spec anchor.
- Verification bar for feature work: `make build`, `make selfcheck`,
  `make fixpoint`, `make test`.

---

## Tier 1 — Blocks Release / Blocks The Book

- [ ] `1. C backend code generation`
  Refs: implementation notes §14; semantic parity requirement is spec-wide.
  Status: Partial. ~25 compile errors remaining in self-compile round-trip.
  Why now: blocks cross-compilation, which blocks multi-platform release. The `--emit-c` path is the portability story — it's how With runs on any platform without shipping LLVM.
  Architecture/design: keep MIR as the single semantic IR. The C backend is an emitter, not a second typechecker. All semantic resolution (generics, closures, trait dispatch, async) must be complete before C emission sees them. Wrapping arithmetic (`+%`, `-%`, `*%`) already works in the LLVM backend and runtime — CCodegen just needs to emit them correctly.
  Implementation strategy: close the remaining ~25 errors by category (Vec type inference, string escaping, unquoted constants, MIR label references). The `make emit-c-test` target compiles the compiler as C with zig and checks behavioral equivalence with stage2. Drive errors to zero against that target. Do not hand-maintain `with_runtime.h` — generate it from `rt_core.w`'s `@[c_export]` surface.
  Primary code: `src/CCodegen.w`, `runtime/with_runtime.h`, `Makefile`.

- [ ] `2. Borrow checker`
  Refs: implementation notes §2; ownership and reference rules across spec §3.
  Status: Partial. CFG construction is a stub (`src/BorrowCfg.w:1`), but real conflict detection and disjoint-path logic exists in `src/SemaCheck.w:4940`.
  Why now: without this, users write programs that compile and crash with use-after-free. The intern pool dangling pointer bug from this session only existed because nothing enforced borrow rules on `str` values pointing into Vec buffers. The borrow checker would have caught it at compile time. If the book teaches patterns that compile but crash, every reader learns the wrong habits.
  Architecture/design: move from mostly local borrow bookkeeping to real CFG- and liveness-driven analysis. Keep the existing field-path disjointness logic as a fast, correct refinement on top. NLL (non-lexical lifetimes) is the target model — borrows expire at last use, not at scope end.
  Implementation strategy: finish `src/BorrowCfg.w`, wire branch/loop/await-aware liveness into borrow expiry, preserve the current disjoint-field and reborrow behavior, and expand tests for branches, loops, closures, and async borrows.
  Primary code: `src/BorrowCfg.w`, `src/SemaCheck.w`, `test/behavior/behav_borrow_basic.w`, `test/behavior/behav_borrow_advanced.w`, `test/behavior/borrow_disjoint_fields.w`.

- [ ] `3. Pattern match compilation`
  Refs: implementation notes §9; spec §9.7.
  Status: Partial. Basic patterns work. Nested constructor patterns, guard clauses, and binding-aware or-patterns are incomplete per `behav_pattern_advanced.w`.
  Why now: users write `match` constantly. Incomplete patterns make the language feel unfinished immediately.
  Architecture/design: keep match lowering decision-tree based, not as naive if/else chains. Exhaustiveness and usefulness checks stay in sema; MIR/codegen consumes already-validated patterns.
  Implementation strategy: finish nested constructor patterns, guard clauses, binding-aware or-patterns, and the remaining advanced forms. Extend exhaustiveness tests alongside lowering work.
  Primary code: `src/Parser.w`, `src/SemaCheck.w`, `src/MirLower.w`, `test/behavior/behav_pattern_advanced.w`.

- [ ] `4. Error type lowering`
  Refs: implementation notes §12; spec §§10.8-10.9.
  Status: Partial.
  Why now: error declarations and error conversion are tutorial-level features. The book's error handling chapter depends on these.
  Architecture/design: lower named error declarations to ordinary compiler-known enum-like types early in sema so `match`, `?`, implicit `Ok`, and diagnostics all reuse the existing Result machinery.
  Implementation strategy: implement parser/AST/sema support for `error Name = ...` and `error A from B`, wire them through type construction and propagation, and cover both declaration syntax and conversion behavior in behavior tests.
  Primary code: `src/Parser.w`, `src/SemaDecl.w`, `src/SemaCheck.w`, `test/behavior/behav_error_decl.w`.

- [ ] `5. Enum accessor method generation`
  Refs: implementation notes §19; spec §4.4.
  Status: Partial. Option/Result have hardcoded helpers. User-defined enums don't get them.
  Why now: users expect `.is_variant()`, `.unwrap_variant()` on every enum. Without them, pattern matching is the only way to inspect enums, which makes simple checks verbose.
  Architecture/design: synthesize enum helper methods once during sema/comptime transformation so method lookup is uniform for all enums, generic enums, and monomorphized uses.
  Implementation strategy: generalize the existing Option/Result builtin helper path to arbitrary enums. Generate `is_*`, `as_*`, and unwrap-style accessors consistently. Test that the helpers work for user-defined enums, not only Option and Result.
  Primary code: `src/SemaCheck.w`, `src/MirLower.w`, `lib/std/option.w`, `lib/std/result.w`.

- [ ] `6. String auto-promotion`
  Refs: implementation notes §29; spec §15.3.
  Status: Partial.
  Why now: first real programs are string-heavy. Rough edges here surface in the first 10 minutes.
  Architecture/design: keep promotion as a sema coercion based on expected type. Borrowed string contexts must stay zero-copy; owned `str` contexts may allocate.
  Implementation strategy: centralize literal-to-`str` promotion rules for bindings, call arguments, returns, and struct fields. Make the rules explicit and testable rather than scattered across lowering/codegen special cases.
  Primary code: `src/SemaCheck.w`, `src/MirLower.w`, `src/CodegenDispatch.w`.

- [ ] `7. HashMap convenience methods`
  Refs: implementation notes §40; spec §13.3.
  Status: Partial.
  Why now: HashMap is a core collection. Missing methods make example code visibly worse than it should be.
  Architecture/design: keep the user-facing API in `lib/std`. Reserve compiler intrinsics for the small runtime-backed operations that truly need them.
  Implementation strategy: expose and finish the convenience surface the notes call for, starting with the methods the tutorial uses. Lift the existing `increment` intrinsic support into a clean standard-library API.
  Primary code: `lib/std/collections.w`, `src/MirLower.w`, `src/CodegenDispatch.w`, `src/CCodegen.w`.

---

## Tier 2 — Blocks Real Programs / Blocks Ecosystem Growth

- [ ] `8. with block lowering`
  Refs: implementation notes §4; spec §7.5.
  Status: Partial. Single-binding `with` works. Multi-with and guarded/`Scoped` forms are incomplete.
  Why now: `with` is central to the language identity. The language is named after it.
  Architecture/design: keep `with` as structured enter/exit lowering with guaranteed cleanup on normal completion, early return, error propagation, and suspension restrictions.
  Implementation strategy: finish sema support for multi-binding `with`, finish the guarded/`Scoped` form, verify `enter`/`exit` balancing under `defer`, `errdefer`, async scope, and `no_await_guard` interactions.
  Primary code: `src/MirLower.w`, `src/SemaCheck.w`, `lib/std/traits.w`, `test/behavior/behav_multi_with.w`.

- [ ] `9. Object safety checking`
  Refs: implementation notes §30; spec §11.3.
  Status: Partial. Core checks exist in sema. Vtable construction exists in codegen. Box-by-value-self shim is missing.
  Why now: traits without dependable dyn dispatch block common interface patterns.
  Architecture/design: keep object-safety checks in sema and vtable construction in codegen. Do not spread object-safety rules across backend code paths.
  Implementation strategy: either implement the `Box[dyn Trait]` by-value-self shim described in the notes, or explicitly narrow the supported model and document the restriction. Don't leave it ambiguous.
  Primary code: `src/SemaDecl.w`, `src/CodegenTraits.w`, `src/CodegenDispatch.w`.

- [ ] `10. Standard library`
  Refs: implementation notes §17; library surface across spec §§13-16.
  Status: Partial. Core types exist. Many expected utility functions are missing.
  Why now: every missing std function is a papercut. Users shouldn't need workarounds for basic operations.
  Architecture/design: keep the standard-library surface in `lib/std`. The compiler exposes only true intrinsics that std builds upon.
  Implementation strategy: prioritize tutorial-critical modules first: strings, formatting, collections, file I/O, process/time, async helpers. When a missing std API needs compiler/runtime support, add the minimal primitive and put the ergonomic API in std.
  Primary code: `lib/std/`, `src/MirLower.w`, `src/CodegenDispatch.w`, `rt/`.

- [ ] `11. Attribute system`
  Refs: implementation notes §32; spec §11.8.
  Status: Partial. Parser recognizes some attributes. `repr(C)` doesn't work per test.
  Why now: `repr(C)` blocks FFI struct layout guarantees, which blocks serious C interop.
  Architecture/design: parse attributes once into AST metadata, validate them in sema, let codegen consume normalized metadata.
  Implementation strategy: finish `repr(C)` first (it's the most-needed attribute), audit the supported attribute list against tests, and add tests that prove semantic effect rather than parser-only acceptance.
  Primary code: `src/Parser.w`, `src/Ast.w`, `src/SemaDecl.w`, `src/SemaCheck.w`, `test/behavior/behav_attr.w`.

---

## Tier 3 — Blocks Advanced Users / Post-Release

- [ ] `12. Generator compilation`
  Refs: implementation notes §5.
  Status: Partial. Parser/sema recognize `gen`/`yield`. MIR lowering is placeholder.
  Why later: the async story already works. Generators compose with async but aren't required for it. Many languages shipped without generators and added them later.
  Architecture/design: lower generators through the same async-MIR/state-machine infrastructure, with `yield` as a first-class suspend point and an iterator-style resume interface.
  Implementation strategy: replace the placeholder `yield` lowering in `src/MirLower.w`, materialize generator frame/state and resume points, add direct generator tests.
  Primary code: `src/Parser.w`, `src/MirLower.w`, `src/AsyncLower.w`, `src/AsyncMir.w`.

- [ ] `13. @[repr(packed)]`
  Refs: implementation notes §49; spec §16.4.
  Status: Partial.
  Why later: needed for binary formats and hardware, not for the tutorial or first programs.
  Architecture/design: keep packed layout separate from bitpacked representation. Packed affects ABI/layout/alignment; bitpacked affects bitfield encoding.
  Implementation strategy: finish the semantic/layout guarantees, make unaligned access behavior explicit, add ABI/layout tests comparing field offsets.
  Primary code: `src/Parser.w`, `src/SemaDecl.w`, `src/TypeLayout.w`, `src/Codegen.w`.

- [ ] `14. C macro → generic translation`
  Refs: implementation notes §52; `c_import` design in §16.
  Status: Partial in CImport.
  Why later: many C libraries expose macro APIs, but users can work around missing translations with manual bindings.
  Architecture/design: keep translation conservative and pattern-based. Only translate macros the compiler can prove structurally. Emit explicit fallback stubs for the rest.
  Implementation strategy: extend the recognizer in `src/CImport.w` for common forms, add real-header regression fixtures, keep unsupported macros visible instead of silently dropping them.
  Primary code: `src/CImport.w`, `runtime/clang_bridge.c`.

- [ ] `15. ScopedSend trait`
  Refs: implementation notes §25; spec §14.15.
  Status: Not implemented. Only registered as a lang trait in `src/Sema.w:1039`.
  Why later: safe cross-fiber capture rules need this eventually, but the current Send model works for initial async programs.
  Architecture/design: derive `Send` and `ScopedSend` from type structure and escape properties in sema.
  Implementation strategy: implement auto-derivation rules, integrate into async-scope and spawn capture checking, add negative tests for non-thread-safe captures.
  Primary code: `src/Sema.w`, `src/SemaCheck.w`, `lib/std/task.w`.

- [ ] `16. Implicit drop as use`
  Refs: implementation notes §34; spec §21.7.
  Status: Not implemented.
  Why later: ergonomics/soundness refinement, not a feature blocker.
  Architecture/design: integrate into borrow/use tracking so destructor-triggering end-of-scope counts as a use.
  Implementation strategy: implement inside the borrow/liveness machinery rather than sprinkling special cases into diagnostics.
  Primary code: `src/SemaCheck.w`, `src/BorrowCfg.w`.

---

## Tier 4 — Nice To Have / Community Can Contribute

- [ ] `17. @[derive(Builder)]`
  Refs: implementation notes §39; spec §11.8.
  Status: Not implemented.
  Architecture/design: implement as a comptime transform following the derive-generated `Clone` model.
  Primary code: `src/ComptimeTransform.w`, `src/SemaDecl.w`.

- [ ] `18. Raw pointer .as_option()`
  Refs: implementation notes §41; spec §16.1.
  Status: Not implemented.
  Architecture/design: builtin raw-pointer method in sema/MIR. Maps null to `None`, non-null to `Some(ptr)`.
  Primary code: `src/SemaCheck.w`, `src/MirLower.w`.

- [ ] `19. FFI stack switching`
  Refs: implementation notes §31; spec §14.18.
  Status: Not implemented.
  Why later: only matters for async code calling blocking C functions. Implement after the core async story is stable.
  Primary code: `src/SemaCheck.w`, `src/CodegenDispatch.w`, `rt/fiber_core_darwin.w`.

- [ ] `20. C expression evaluator for c_import`
  Refs: implementation notes §51.
  Status: Not implemented.
  Why later: only needed for headers defining constants through expression macros.
  Architecture/design: use libclang-backed constant evaluation, not a separate partial C evaluator.
  Primary code: `src/CImport.w`, `runtime/clang_bridge.c`.

- [ ] `21. Backward pipe / function composition / list comprehensions`
  Refs: spec §9.6, spec §13.6; `behav_backward_pipe.w`, `behav_fn_compose.w`, `behav_list_comp.w`.
  Status: Not implemented.
  Architecture/design: parser-level desugarings onto existing call/combinator/for-comprehension machinery.
  Primary code: `src/Parser.w`, `src/MirLower.w`.

- [x] `22. Magic constants __FILE__ / __LINE__ / __FN__`
  Refs: `test/behavior/behav_magic_const.w`.
  Status: Implemented and covered by behavior tests.
  Architecture/design: semantic magic identifiers lowered through Sema/MIR/comptime source-location plumbing.
  Primary code: `src/SemaCheck.w`, `src/MirLower.w`, `src/ComptimeEval.w`, `src/CodegenDispatch.w`.

- [ ] `23. Module declarations / full pub visibility`
  Refs: spec §§18.1 and 18.3; `test/behavior/behav_pub_module.w`.
  Status: Not implemented.
  Why later: matters for large multi-file projects, not for getting started.
  Primary code: `src/Parser.w`, `src/compiler/Frontend.w`, `src/SemaDecl.w`.

---

## Execution Order

### Before The Book

1. C backend code generation
2. Borrow checker
3. Pattern match compilation
4. Error type lowering
5. Enum accessor method generation
6. String auto-promotion
7. HashMap convenience methods

### Before Release

1. `with` block lowering
2. Object safety checking
3. Standard library
4. Attribute system

### After Release

1. Generator compilation
2. `@[repr(packed)]`
3. C macro → generic translation
4. ScopedSend
5. Implicit drop as use
6. Everything in Tier 4

---

## Critical Path

`C backend → borrow checker → pattern matching → error types → enum accessors → tutorial/book → with blocks → stdlib → generators → release`
