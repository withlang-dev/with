# D168 — A List's adapters are its iterator's: no eager `List.map`, `filter`, `fold` (delegated)

**Laws:** one owner per fact (D65, D110); the spec leads.

**Date:** 2026-10-28. **Status:** delegated (D98): not C interop, easy to
reverse, prediction 80%. **Issue:** #2772.

**Decision.** `List` has no `map`, `filter` or `fold` method of its own.
A pipeline iterates a List (D142, §13.5): `xs |> map(f) |> collect[List]()`,
`xs |> filter(p)`, `xs |> fold(init, f)` are the iterator's adapters,
whose closures see each element as a view and whose `collect` copies a
value out (D111, D139). `xs.map(f)` is "unknown method", and the
diagnostic names the pipeline spelling.

**Context.** The eager `List.map`/`filter`/`fold` were codegen intrinsics
(`LIST_MAP`, `LIST_FILTER`, `LIST_FOLD`): a hand-written loop per method
that passed each element to the closure by a byte copy and pushed kept
elements by a byte copy. Over a `List[str]` that made a second owner of
every element: `ys |> map(it.to_owned())`, `ys.map(it.len())`,
`ys.filter(it.len() > 0)` each freed every element twice (debug
allocator: DOUBLE FREE), and a longer program read freed bytes. The
declared signature (`List.map(f: fn(&T) -> U)`, BuiltinSigs) said the
closure observes; Sema typed it `fn(T)` (#306) and codegen passed `T`:
two derivations, a second ownership system in codegen (D110 forbids it).
Because `pipeline_method_exists` answered yes for `List.map`, D142's
implicit `.iter()` never applied to `xs |> map(f)` either.

**What the spec says.** Nothing documents `map`/`filter`/`fold` as List
methods: §13.5 (D142) shows `xs |> map(it * 2)` over a List as "the same
traversal" as the iterator; §14.13's examples are `xs.iter() |> map(…)`.
The eager methods were an unspecified surface (the pipeline allowlist
called itself a "temporary bridge").

**Alternatives.** (a) Keep the eager methods and fix their ownership in
codegen: a second implementation of what the iterator adapters and
`collect` already do, and `filter` over a resource-element List has no
owned answer at all. (b) Define them in std as `self.iter() |> map(f) |>
collect[List]()`: a second spelling of a traversal the pipeline already
spells, with a result type that would differ between value and resource
elements. Neither earns a second spelling.

**Removed with it:** the three codegen loops, the C backend's refusals
for them, the may-cancel mark that existed only for them (#2019; the
cancellation guarantee now holds through the iterator adapters,
`da_2019` keeps its assertions), and the List entries in the pipeline
allowlist, closure-parameter typing and builtin signatures.

**Reopens if** a program shows an eager List transform the pipeline cannot
express with the same result.
