# D115 — A slice pattern's rest names the remaining elements; ownership of the subject decides how it binds

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). **Supersedes** the
§9.7 clause "`rest` is bound to the remaining count" (from the 2026-03-10
progress commit 99e000a40, never a ruling) and #1389's rule that an owned
fixed-array place is taken apart by value. **The compiler is NON-COMPLIANT**
until implemented (#2283).

**Context.** #2283: a rest binding on a `Vec` or slice subject was
unimplemented, and §9.7 contradicted itself: its example reads
`rest.len()`, its rule bound "the remaining count". No reference binds a
count: Rust binds a sub-array `[T; N-k]` or `&[T]`, Scala a `Seq`; Zig has no
rest pattern; Swift, Go, Mojo and Vale have no sequence patterns. Probes on
2026-10-08 found two live defects in the area: `let [first, ..] = mk() else
...` with `mk() -> Vec[W]` binds `first` as a view into the temporary, which
is dropped before `first` is read (a silent use-after-free the debug
allocator did not report), and `match move v: [first, ..] => ...` leaks the
`Vec` and its elements.

**Alternatives.** (A) The remaining elements, typed by representation: an
owned fixed array gives `[T; N-k]`, anything else a `[]T` view. (B) A count
everywhere. (C, ruled) The remaining elements, bound by ownership of the
subject: an owned subject is taken apart by value, a place is observed. A
rejects nothing it should, but binds views into temporaries; B drops the
elements and matches no reference.

**Ruling (blessed words, §9.7).**

"`[first, ..rest]` matches one or more elements, and `rest` names the
elements between the matched ends. If the subject is owned — a temporary, or
a place moved with `move` — the pattern takes it apart by value: each binding
is an owned element, and `rest` is the owned remainder (`[T; N-k]` for a
fixed array, `Vec[T]` for a `Vec`). If the subject is a place, the pattern
observes it: elements bind as views and `rest` is a `[]T` view of it. Its
length is `rest.len()`."

**Consequences (derived, not ruled).**
- An owned fixed-array place (`let [a, ..] = arr`) is now observed, not
  taken apart: `a` is a view, and `arr` is not moved out of. For `Copy`
  elements an owned demand still materializes a copy (D22), so only `Drop`
  elements see the change. `let [a, ..] = move arr` takes it apart.
- `match move v:` is the spelling for an owned subject that is a place; the
  leak it has today is a defect of this ruling's implementation.
- The owned `Vec` remainder reuses the subject's buffer: the tail is shifted
  down (a move of the remaining elements, no allocation). `Vec` has no
  offset field, so the shift is the representation.
- Count-based tests convert to `rest.len()`; the `[i32; N]` annotations D113
  added only to keep the count working are removed.

**What would reopen it.** A case where observing a place subject forces
ceremony the by-value rule avoided (a `Drop` array that must be consumed
element-wise without `move`).
