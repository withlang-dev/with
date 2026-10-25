# D158 — There is no `std.span` facade: strided and multi-dimensional views are the language's (drops the `Span[T]` row of the 2026-09-12 facade map)

**Laws:** 9 (two spellings of one meaning are a defect), 1; tested against 10.

**Date:** 2026-10-24. **Status:** ruled by Eric on the brief posted after #2614. **Supersedes:** the `Span[T]` row of the facade map in `docs/completed/stdlib_sourcing_plan.md`.

## The ruling

> There is no `std.span` facade. Contiguous non-owning views are `[]T`
> (§4.8a); multi-dimensional arrays are D119's `[T; d1, d2, …]`;
> multi-dimensional and strided slicing is the stated design goal
> (`tensor[2:5, :, newaxis]`) and will be a language feature over those
> types. STC's `cspan` remains in the migrated corpus as an engine and is
> not presented. Reopening condition: a numeric user program needs strided
> views before the language has them; the answer then is to schedule the
> language feature, not to add the facade.

> The reason worth recording: the sourcing rule imports an engine for its
> *hardening*. `cspan` would be imported for its *shape*, and that shape
> would become a second slicing syntax beside the language's own. That's
> the only row in the facade map where that's true.

## Context

STC's `cspan` (`include/stc/cspan.h`) is a multi-dimensional strided view
(`cspan_md`, `c_ALL`/`c_END` slicing, transpose, rank). The spec already
has the non-owning contiguous view (§4.8a `[]T`, a fat pointer that "does
not own the data") and multi-dimensional arrays (D119), and
`docs/spec/001_design-goals.md` lists multi-dimensional indexing as a
design goal. No reference language sources a strided span from a library.

## What this changes

- The facade map's `Span[T]` row and the `std.slice`/`std.span` grouping
  are removed from `docs/completed/stdlib_sourcing_plan.md`; "What remains"
  item 2 is closed by this ruling.
- `cspan` stays a migrated, tested engine under `std.engines.stc`.

## What would reopen it

A numeric user program needing strided views before the language has them;
the response is to schedule the language feature.
