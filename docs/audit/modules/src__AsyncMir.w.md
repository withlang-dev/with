# src/AsyncMir.w — module audit @450733e5

Verdict: COMPLETE (3 reported findings investigated; all refuted, no live defect).

## F1 [T13, REFUTED] `add_suspend` (:61) is `fn`, not `mut fn`, yet pushes to self's Vecs

Refuted. `Vec.push` is callable on `fn`-receiver methods and on `let`
bindings throughout shipped, compiling code:

- Same file, `add_body` (:96-99) is also `fn` and does
  `self.bodies.push(move body)` — identical shape, accepted with no diagnostic.
- `src/BuildGraphSupport.w:43-46`: `let out: Vec[str] = Vec.new()` followed by
  `out.push(...)` — compiles as part of the build.

The receiver-mode rule (AGENTS.md: `mut fn` mutates the receiver place in
place) is not violated: pushing to a `Vec` field is not a place mutation of
`self` under the compiler's accepted semantics, as proven by the above
counterexamples the seed compiler accepts. No diagnostic, no miscompile.

## F2 [T22, REFUTED] `state_count` stale unless `finalize_states` is called

Refuted as a live defect. The sole producer path,
`src/AsyncLower.w:85-101`, calls `self.cur_body.finalize_states()` (:100)
unconditionally after the walk and before `add_body`. The only reader of
`state_count` is the internal `dump_async_mir_module` (:148), which runs on
bodies already added post-finalize. No mid-build read path exists. At most a
latent footgun if a future producer forgets finalization; not a defect today.

## F3 [T22, REFUTED] `requires_async_runtime` false for pure-Yield Sync generator

Refuted. The predicate answers whether the async *executor runtime* is
needed, not whether suspension exists. Generator-flavor bodies lower to state
machines; a Sync-flavor body containing `Yield` is rejected outright by the
producer (`AsyncLower.w:94-98` emits "yield used outside generator function").
No spec text requires the async runtime for generators. Design judgment, not a
defect; no probe can distinguish a "wrong" answer here.

## Probes / controls

- Source read of full module (164 lines) plus producer `AsyncLower.w:85-101`.
- Caller/receiver audit via grep (no other `state_count` readers/producers).
- `Vec.push`-on-`let` control: `BuildGraphSupport.w:43-46` (shipped, compiling).
