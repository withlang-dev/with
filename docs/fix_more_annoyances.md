# Fix More Annoyances Checklist

## Scope
- [x] Add tuple concurrent-await language semantics to the spec.
- [ ] Add collection await combinators to the stdlib (`lib/std/async.w`).
- [x] Add idiomatic and migration guide sections for concurrent await usage.

## 1. Spec Change (`docs/with-specification.md`)
- [x] Add new section `§14.11 Concurrent Await` and renumber subsequent sections.
- [x] Add tuple `.await` examples for 2 and 3 tasks.
- [x] Specify tuple-await typing: `(Task[A], Task[B], ..., Task[N]).await -> (A, B, ..., N)`.
- [x] Specify eager-spawn + join semantics and clarify that tasks are already running.
- [x] Specify `?` behavior with tuple await for `Task[Result[T, E]]` elements.
- [x] Add fail-fast + cancellation guidance with `async scope |s|` example.
- [x] Specify tuple arity support (2..12) and tie to tuple-size limit.
- [x] Add explicit desugaring example for 2-tuple await.
- [x] Add relationship table comparing tuple await, collection await, `select await`, `async scope`, and `spawn`.
- [x] Add subsection `§14.11.1 Collection Await (Standard Library)` with `await_all`, `await_first`, `await_any`, `await_settled`.
- [x] Ensure all internal section references and links are updated after renumbering.

## 2. Compiler/Runtime Parity Tasks (for spec correctness)
- [x] Audit current parser/sema/codegen behavior for `(task_a, task_b).await`.
- [x] Implement tuple-await typing rules if any gaps exist.
- [x] Implement tuple-await lowering/runtime join behavior if any gaps exist.
- [x] Add diagnostics for invalid tuple-await arity and non-task tuple elements.
- [x] Validate tuple-await + `?` behavior for tuple-of-`Result` tasks.

## 3. Stdlib Change (`lib/std/async.w`)
- [x] Add new module `lib/std/async.w`.
- [x] Add `pub async fn await_all[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[Vec[T], E]`.
- [x] Add `pub async fn await_all[T](tasks: impl IntoIter[Task[T]]) -> Vec[T]`.
- [x] Add `pub async fn await_first[T](tasks: impl IntoIter[Task[T]]) -> T`.
- [x] Add `pub async fn await_any[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Result[T, Vec[E]]`.
- [x] Add `pub async fn await_settled[T, E](tasks: impl IntoIter[Task[Result[T, E]]]) -> Vec[Result[T, E]]`.
- [ ] Preserve input-order guarantees where required (`await_all`, `await_settled`).
- [ ] Implement cancellation behavior as documented (`await_all` fail-fast, `await_first`, `await_any`).
- [ ] Ensure lazy iterator consumption/backpressure behavior is documented and tested.
- [x] Add optional `pub fn with_concurrency[T](tasks: impl IntoIter[Task[T]], n: i32) -> impl IntoIter[Task[T]]`.

Implementation note:
- API signatures now exist in `lib/std/async.w`; full behavior semantics (ordering, fail-fast cancellation, and dynamic-first selection) remain pending Stage0 generic-async/runtime support.

## 4. Stdlib Docs
- [ ] Add `lib/std/async/` documentation pages for each public function.
- [ ] Document empty-input behavior for `await_first` and `await_any`.
- [ ] Document cancellation, ordering, and complexity guarantees.
- [ ] Include pipeline-first examples matching spec/guide wording.

## 5. Guide Additions
- [x] Update `docs/with-idiomatic-guide.md` with a new `Concurrent Await` section.
- [x] Add sequential-vs-concurrent example (`fetch_user` + `fetch_posts`).
- [x] Add collection example (`ids |> map(fetch_user) |> await_all`).
- [x] Add fire-and-forget rule (`spawn` vs `let _ = task`).
- [x] Add guidance for when to use tuple await vs `async scope`.
- [x] Update `docs/with-migration-guide.md` async/concurrency section with Rust mappings:
- [x] `tokio::join!` -> tuple `.await`.
- [x] `join_all` -> `await_all`.
- [x] `FuturesUnordered` + limit -> `with_concurrency(...) |> await_all`.
- [x] Add JS/TS Promise mappings if migration guide includes JS/TS content (N/A: current migration guide has no JS/TS section).

## 6. Tests and Examples
- [x] Add parser tests for tuple `.await` syntax across tuple arities.
- [x] Add sema tests for tuple-await typing and `?` propagation.
- [ ] Add runtime/integration tests for:
- [x] successful tuple await preserving tuple order.
- [x] tuple await with errors + `?`.
- [ ] `await_all` fail-fast cancellation.
- [ ] `await_first` cancellation of non-winning tasks.
- [ ] `await_any` success + all-fail behavior.
- [ ] `await_settled` full completion behavior.
- [ ] Add one or more runnable examples in `examples/` showcasing tuple await and collection await.

## 7. Decisions to Lock Before Implementation
- [x] Define behavior for empty inputs to `await_first`.
- [x] Define behavior for empty inputs to `await_any`.
- [x] Define ordering of error aggregation for `await_any` all-fail case.
- [x] Define interaction between cancellation and non-`async scope` drops for each combinator.

Locked decisions:
- `await_first([])` with current `-> T` signature is a hard runtime panic with stable message `"await_first: empty input"`.
- `await_any([])` returns `Err(Vec.new())`; for non-empty all-fail input, returned error vector is guaranteed non-empty.
- `await_any` all-fail error aggregation order is input order (not completion order).
- Collection combinators are structured by ownership: on early completion (success or fail-fast) they cancel remaining owned tasks and join them before return; if the combinator is itself cancelled/dropped mid-flight, it does the same during unwind.

## 8. Validation Gates
- [ ] `check` passes for new/updated examples.
- [ ] Unit/integration tests for new async combinators pass.
- [ ] Stage0/Stage2 parity checks pass for tuple-await corpus.
- [ ] Spec text and guide examples match implemented behavior (no known divergence).

## 9. Implicit `.iter()` via `IntoIter`
- [x] Update iterator-facing stdlib pipeline functions (`map`, `filter`, `count`, and peers) to accept `impl IntoIter[T]` instead of `Iter[T]`.
- [x] Add compiler behavior to insert implicit `.iter()` when a collection is piped into an iterator function.
- [x] Preserve explicit `.iter()` behavior (no regression) and keep method-resolution deterministic.
- [x] Add tests for `Vec`, slice, array, and map/set pipelines without explicit `.iter()`.
- [x] Document this as ergonomics behavior in guides (no new syntax).

## 10. Drop `collect` When Target Type Is Known
- [x] Define destination contexts that trigger auto-collect: typed `let`, function return position, and typed call-argument position.
- [x] Implement pipeline terminus inference so iterator pipelines materialize into the known destination collection type automatically.
- [x] Keep explicit `collect[...]` available and required when destination type is unknown or ambiguous.
- [x] Add diagnostics for unresolved destination type (ask for explicit `collect[...]`).
- [x] Add tests for success and ambiguity/error cases.

## 11. Implicit `self` in `extend`/`impl`
- [x] Allow methods in `extend`/`impl` blocks to omit explicit first `self` parameter.
- [x] Infer `self` mode from usage: read-only -> `&Self`, mutation -> `&mut Self`, move/consume -> `Self`.
- [x] Lower inferred `self` to explicit internal method signature before downstream phases.
- [x] Add diagnostics for conflicting self-mode usage in one method body.
- [x] Preserve compatibility for methods that still declare explicit `self`.
- [x] Add parser/sema/codegen tests for read, mutate, and move cases.

Current implementation note:
- Implicit receiver insertion is applied only when method bodies reference `self`; static methods stay unchanged.
- `self` mode inference is syntactic in Stage0: assignment through `self` selects `&mut Self`, explicit by-value `self` use selects `Self`, otherwise it selects `&Self`.
- Consume inference is conservative for direct `self` value uses; deeper ownership-sensitive moves (for example field-level move intent) still require explicit receiver annotation when needed.

## 12. Statement-Position Partial `match`
- [x] Distinguish expression-position `match` from statement-position `match` in sema.
- [x] Require exhaustiveness only for expression-position `match`.
- [x] Permit partial statement-position `match` with unmatched variants as no-op.
- [x] Keep existing reachability/usefulness diagnostics where still applicable.
- [x] Update spec and guides to clarify this split behavior with examples.
- [x] Add regression tests for expression-required exhaustiveness and statement partial matching.

## 13. Prelude Expansion
- [x] Add `String`, `Debug`, `Display`, `Default`, `Iter`, `IntoIter`, `Eq`, `Hash`, and `Ord` to prelude exports.
- [x] Confirm symbol precedence rules vs local/module imports and document collision behavior.
- [x] Update spec/guide prelude lists and examples.
- [x] Add compile tests proving these names work without explicit `use`.
- [x] Add a follow-up tracking task: audit first 20 real programs and adjust prelude as needed.

Follow-up tracking task: `Wave 6+ prelude audit` — run the first 20 real self-host programs, collect missing/over-eager prelude names, and adjust the default prelude set.

## 14. Implicit Widening Conversions
- [x] Specify the exact implicit widening matrix in spec text: signed widening, unsigned widening, `f32 -> f64`, and wider unsigned-to-signed only when provably safe by width.
- [x] Implement sema coercions for allowed widenings in assignments, call args, returns, and expression unification.
- [x] Keep narrowing conversions explicit-only via `as`, with unchanged hard errors.
- [x] Add tests for accepted widenings and rejected narrowings across literals and typed values.
- [x] Add migration-guide examples showing where explicit casts are no longer needed.

## 15. Combined Validation Gates For These Annoyances
- [ ] Bootstrap test suite passes with all six changes enabled.
- [ ] Self-host test suite passes with all six changes enabled.
- [ ] Parity scripts are updated and passing for intentional behavior changes.
- [ ] No unresolved known divergences remain for these six features.
