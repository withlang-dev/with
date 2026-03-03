# Fix More Annoyances Checklist

## Scope
- [ ] Add tuple concurrent-await language semantics to the spec.
- [ ] Add collection await combinators to the stdlib (`lib/std/async.w`).
- [ ] Add idiomatic and migration guide sections for concurrent await usage.

## 1. Spec Change (`docs/with-specification.md`)
- [ ] Add new section `§14.11 Concurrent Await` and renumber subsequent sections.
- [ ] Add tuple `.await` examples for 2 and 3 tasks.
- [ ] Specify tuple-await typing: `(Task[A], Task[B], ..., Task[N]).await -> (A, B, ..., N)`.
- [ ] Specify eager-spawn + join semantics and clarify that tasks are already running.
- [ ] Specify `?` behavior with tuple await for `Task[Result[T, E]]` elements.
- [ ] Add fail-fast + cancellation guidance with `async scope |s|` example.
- [ ] Specify tuple arity support (2..12) and tie to tuple-size limit.
- [ ] Add explicit desugaring example for 2-tuple await.
- [ ] Add relationship table comparing tuple await, collection await, `select await`, `async scope`, and `spawn`.
- [ ] Add subsection `§14.11.1 Collection Await (Standard Library)` with `await_all`, `await_first`, `await_any`, `await_settled`.
- [ ] Ensure all internal section references and links are updated after renumbering.

## 2. Compiler/Runtime Parity Tasks (for spec correctness)
- [ ] Audit current parser/sema/codegen behavior for `(task_a, task_b).await`.
- [ ] Implement tuple-await typing rules if any gaps exist.
- [ ] Implement tuple-await lowering/runtime join behavior if any gaps exist.
- [ ] Add diagnostics for invalid tuple-await arity and non-task tuple elements.
- [ ] Validate tuple-await + `?` behavior for tuple-of-`Result` tasks.

## 3. Stdlib Change (`lib/std/async.w`)
- [ ] Add new module `lib/std/async.w`.
- [ ] Add `pub async fn await_all[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[Vec[T], E]`.
- [ ] Add `pub async fn await_all[T](tasks: impl IntoIter[Task[T]]) -> Vec[T]`.
- [ ] Add `pub async fn await_first[T](tasks: impl IntoIter[Task[T]]) -> T`.
- [ ] Add `pub async fn await_any[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[T, Vec[E]]`.
- [ ] Add `pub async fn await_settled[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Vec[Result[T, E]]`.
- [ ] Preserve input-order guarantees where required (`await_all`, `await_settled`).
- [ ] Implement cancellation behavior as documented (`await_all` fail-fast, `await_first`, `await_any`).
- [ ] Ensure lazy iterator consumption/backpressure behavior is documented and tested.
- [ ] Add optional `pub fn with_concurrency[T](tasks: impl IntoIter[Task[T]], n: i32) -> impl IntoIter[Task[T]]`.

## 4. Stdlib Docs
- [ ] Add `lib/std/async/` documentation pages for each public function.
- [ ] Document empty-input behavior for `await_first` and `await_any`.
- [ ] Document cancellation, ordering, and complexity guarantees.
- [ ] Include pipeline-first examples matching spec/guide wording.

## 5. Guide Additions
- [ ] Update `docs/with-idiomatic-guide.md` with a new `Concurrent Await` section.
- [ ] Add sequential-vs-concurrent example (`fetch_user` + `fetch_posts`).
- [ ] Add collection example (`ids |> map(fetch_user) |> await_all`).
- [ ] Add fire-and-forget rule (`spawn` vs `let _ = task`).
- [ ] Add guidance for when to use tuple await vs `async scope`.
- [ ] Update `docs/with-migration-guide.md` async/concurrency section with Rust mappings:
- [ ] `tokio::join!` -> tuple `.await`.
- [ ] `join_all` -> `await_all`.
- [ ] `FuturesUnordered` + limit -> `with_concurrency(...) |> await_all`.
- [ ] Add JS/TS Promise mappings if migration guide includes JS/TS content.

## 6. Tests and Examples
- [ ] Add parser tests for tuple `.await` syntax across tuple arities.
- [ ] Add sema tests for tuple-await typing and `?` propagation.
- [ ] Add runtime/integration tests for:
- [ ] successful tuple await preserving tuple order.
- [ ] tuple await with errors + `?`.
- [ ] `await_all` fail-fast cancellation.
- [ ] `await_first` cancellation of non-winning tasks.
- [ ] `await_any` success + all-fail behavior.
- [ ] `await_settled` full completion behavior.
- [ ] Add one or more runnable examples in `examples/` showcasing tuple await and collection await.

## 7. Decisions to Lock Before Implementation
- [ ] Define behavior for empty inputs to `await_first`.
- [ ] Define behavior for empty inputs to `await_any`.
- [ ] Define ordering of error aggregation for `await_any` all-fail case.
- [ ] Define interaction between cancellation and non-`async scope` drops for each combinator.

## 8. Validation Gates
- [ ] `check` passes for new/updated examples.
- [ ] Unit/integration tests for new async combinators pass.
- [ ] Stage0/Stage2 parity checks pass for tuple-await corpus.
- [ ] Spec text and guide examples match implemented behavior (no known divergence).

## 9. Implicit `.iter()` via `IntoIter`
- [ ] Update iterator-facing stdlib pipeline functions (`map`, `filter`, `count`, and peers) to accept `impl IntoIter[T]` instead of `Iter[T]`.
- [ ] Add compiler behavior to insert implicit `.iter()` when a collection is piped into an iterator function.
- [ ] Preserve explicit `.iter()` behavior (no regression) and keep method-resolution deterministic.
- [ ] Add tests for `Vec`, slice, array, and map/set pipelines without explicit `.iter()`.
- [ ] Document this as ergonomics behavior in guides (no new syntax).

## 10. Drop `collect` When Target Type Is Known
- [ ] Define destination contexts that trigger auto-collect: typed `let`, function return position, and typed call-argument position.
- [ ] Implement pipeline terminus inference so iterator pipelines materialize into the known destination collection type automatically.
- [ ] Keep explicit `collect[...]` available and required when destination type is unknown or ambiguous.
- [ ] Add diagnostics for unresolved destination type (ask for explicit `collect[...]`).
- [ ] Add tests for success and ambiguity/error cases.

## 11. Implicit `self` in `extend`/`impl`
- [ ] Allow methods in `extend`/`impl` blocks to omit explicit first `self` parameter.
- [ ] Infer `self` mode from usage: read-only -> `&Self`, mutation -> `&mut Self`, move/consume -> `Self`.
- [ ] Lower inferred `self` to explicit internal method signature before downstream phases.
- [ ] Add diagnostics for conflicting self-mode usage in one method body.
- [ ] Preserve compatibility for methods that still declare explicit `self`.
- [ ] Add parser/sema/codegen tests for read, mutate, and move cases.

## 12. Statement-Position Partial `match`
- [ ] Distinguish expression-position `match` from statement-position `match` in sema.
- [ ] Require exhaustiveness only for expression-position `match`.
- [ ] Permit partial statement-position `match` with unmatched variants as no-op.
- [ ] Keep existing reachability/usefulness diagnostics where still applicable.
- [ ] Update spec and guides to clarify this split behavior with examples.
- [ ] Add regression tests for expression-required exhaustiveness and statement partial matching.

## 13. Prelude Expansion
- [ ] Add `String`, `Debug`, `Display`, `Default`, `Iter`, `IntoIter`, `Eq`, `Hash`, and `Ord` to prelude exports.
- [ ] Confirm symbol precedence rules vs local/module imports and document collision behavior.
- [ ] Update spec/guide prelude lists and examples.
- [ ] Add compile tests proving these names work without explicit `use`.
- [ ] Add a follow-up tracking task: audit first 20 real programs and adjust prelude as needed.

## 14. Implicit Widening Conversions
- [ ] Specify the exact implicit widening matrix in spec text: signed widening, unsigned widening, `f32 -> f64`, and wider unsigned-to-signed only when provably safe by width.
- [ ] Implement sema coercions for allowed widenings in assignments, call args, returns, and expression unification.
- [ ] Keep narrowing conversions explicit-only via `as`, with unchanged hard errors.
- [ ] Add tests for accepted widenings and rejected narrowings across literals and typed values.
- [ ] Add migration-guide examples showing where explicit casts are no longer needed.

## 15. Combined Validation Gates For These Annoyances
- [ ] Bootstrap test suite passes with all six changes enabled.
- [ ] Self-host test suite passes with all six changes enabled.
- [ ] Parity scripts are updated and passing for intentional behavior changes.
- [ ] No unresolved known divergences remain for these six features.
