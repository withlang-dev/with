# D139 — A view of a view of a Copy value satisfies an owned-value demand at every layer (D22 §7.4 applied as written) (delegated)

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-10-20. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2220 (step 2).

**Decision.** D22 §7.4 ("a projected reference may later satisfy an
independently established owned-value demand when its pointee is `Copy`")
applies at every reference layer, not one. A view is itself `Copy`, so
`&&i64` meets a demand for `i64` by reading through both layers, exactly
as `&i64` does through one and as `&&str` already did (D111). The
compiler's one-layer cap on non-`str` pointees (`contextual_copy_value_type`,
from the D111 demands PR, with no recorded reason) is removed; the loop
reads until the demand is met or a layer is not `Copy`.

Concretely: a list iterator that yields `&T` hands `filter`'s predicate
(`fn(&T) -> bool`, `T = &i64`) a `&&i64`, and `filter(it % 2 == 1)` now
compiles, as `for x in it: total + x` and `map(it * 2)` already did.
Nothing an explicit `*it` or `**it` wrote changes meaning.

**What the others do.** Rust: auto-deref through any number of `&` layers
for method receivers and `Copy` reads behind `&&T` via `*` only, but `&&i64 +
1` fails to type — Rust's bar, not its compass. Swift and Go have no
reference-of-reference at the surface. Vale: a reference to a reference is
read through transparently (generational references compose).

**What the spec says.** §7.4 states the rule per projected reference with
no layer count; §7.3 (quoted in the ruling) deliberately preserves the
extra layer in the binding (`b: &&B`), which is why materialization must
read through it later. Nothing in D22 limits the count; the one-layer cap
was the implementation's reading.

**Mission fit.** A deref the compiler can see is forced (Law 1): the demand
is an `i64`, the value is a `Copy` `i64` behind two views, one meaning. The
iterator campaign (#2220 Option 2) makes `ListIter` a view that yields
`&T`, so without this every `filter` over a list of integers would grow a
`*it`.

**Prediction.** Eric rules for it, 90%: "don't make the user write what the
compiler already knows" is the first law, and D22's text already says it.

**What would reopen it.** A case where reading through two layers changes
which program is accepted in a way a person would not expect, or a
performance cost in Sema's demand check (none measured: the loop runs at
most as many steps as there are `&` layers).
