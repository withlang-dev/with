# D157 — `List[T]` is implemented by the runtime; STC `vec` is a comparison engine, never a dependency of the runtime (amends the 2026-09-12 facade map)

**Laws:** 3 (the compiler owns what it already lowers), 9 (one spelling of one meaning); tested against 10.

**Date:** 2026-10-24. **Status:** ruled by Eric on the brief posted after #2614. **Supersedes:** the `List`/`Vec` row of the facade map in `docs/proposals/stdlib_sourcing_plan.md` and `docs/spec/stdlib/stdlib_inventory.md` line 15 ("STC `vec` in Phase 3").

## The ruling

> `List[T]` is implemented by the runtime (`rt_core`). The compiler knows
> its layout and intrinsics (literals, comprehensions, `for`, `xs[i]` as a
> place, `push`/`pop`, copy-on-write, the counted copy class), and that
> knowledge is the engine. STC's `vec` is a comparison engine in the
> benchmark, never a dependency of the runtime. The facade map's List row
> reads "rt_core; STC vec comparison", and `stdlib_inventory.md` line 15 is
> corrected to match. Reopening condition: the comparison row shows a
> measured gap, or a feature `rt_core` lacks that `vec` has.

> This is D149's reasoning applied again, and the brief's point that STC's
> `vec` is a template per element type settles it: for an arbitrary `T` it
> would be a byte vector with the facade doing element arithmetic, which is
> `rt_core` with extra steps. One addition to the record: `List` is
> compiler-known in ten places, so it's part of the language's surface, and
> the sourcing rule ("migrate the engine, facade the With-ness") was written
> for library containers, not for types the compiler itself lowers to.

## Context

The 2026-09-12 facade map named STC `vec` as `List`'s primary engine. Every
other row of the map landed (Phases 1–4, the 2026-10-24 close-out in
#2614); this row was the last one open. The brief: every reference language
owns its growable array (Zig `std.ArrayList`, Rust `Vec`, Swift `Array`,
Go's runtime slices, Mojo `List`; Vale's `List<E>` is a struct over the
builtin `Array`); the spec names no engine (§4.8a, D118); D152 fixes the
counted copy, D120 copy-on-write, D115 the O(1) `remove(0)`; ten compiler
sources know `List`'s layout; the benchmark's `List push/index/pop
(rt_core)` row reads 2/0/1 ns beside the STC word shapes at 2/0/0.

## What this changes

- `docs/proposals/stdlib_sourcing_plan.md`: the `List` row reads "rt_core;
  STC `vec` comparison"; "What remains" item 1 is closed by this ruling.
- `docs/spec/stdlib/stdlib_inventory.md` line 15: the gap column reads
  "ruled D157: rt_core is the engine; STC `vec` is the comparison row in
  `test/benchmark/stc_engines.w`".
- The sourcing rule's scope is recorded: it is for library containers; a
  type the compiler lowers to is the language's own.

## What would reopen it

The comparison row showing a measured gap, or a feature `rt_core` lacks
that `vec` has.
