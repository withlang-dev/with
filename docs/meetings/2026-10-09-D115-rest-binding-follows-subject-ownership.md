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

## Amendment 1 (2026-10-09): an owned `Vec` remainder is O(1)

**Context.** The first implementation took the head of an owned `Vec` with
`remove(0)`, shifting the tail per match, so the canonical recursion
`[h, ..t] => h + sum(t)` was O(n²) where Scala's is O(n). Scala's O(1) comes
from sharing the tail, not from links; With shares the buffer.

**Ruling (Eric, verbatim).** "Bless it, with one question attached. … The
question is about the cost, because I think there is a cheaper encoding. A
Vec today is {ptr, len, cap, elem_size}. Why is elem_size stored in every
Vec at runtime? The element type is known statically at every use, and the
compiler monomorphizes. If the only reason is that the runtime helpers are
type-erased, they can take the element size as an argument instead, since
every call site knows it. Then the offset takes elem_size's slot, and Vec
stays 32 bytes. … A static fact stored in every value is the
representation-level version of the ceremony you've been removing all day."

"One trade-off to state in the ruling so nobody discovers it later: a small
rest keeps the whole original buffer alive. … It's acceptable, since it's
the price of O(1), and the agent's design already handles the common case,
because growing an offset Vec reallocates. But the doc should say so, and
shrink_to_fit should release the prefix."

"So: "Blessed, provided the offset replaces elem_size rather than adding a
field, if nothing needs elem_size at runtime. If something does, tell me
what, and the 40 bytes stands.""

**Blessed words (§9.7).** "A `Vec` remainder shares the subject's buffer
without copying, so taking it is O(1), as taking a view of a place is."

**The condition, checked.** Nothing needs `elem_size` at runtime. Its readers
are the type-erased `with_vec_*` helpers in `rt/rt_core.w` (new, push, get,
grow, remove, set, free, the byte check in `append_bytes`), codegen's inline
drop glue (header word 3, passed to the sized free), the C backend's header
initialization, and one debug-allocator print; every call site has the
static element type. Nothing reinterprets a `Vec` as another element type.
So the offset replaces `elem_size`: `{ptr, len, cap, start}`, 32 bytes,
`ptr` the first live element and `start` the elements before it. Taking a
head advances `ptr` and `start` and lowers `len` and `cap`; free and grow
read `start` to find the allocation. A zeroed header (#633: `elem_size = 0`,
"happens to work") becomes a valid empty Vec.

**Derived, not ruled.**
- The trade-off is stated in §9.7: a small remainder keeps the original
  buffer alive; growing reallocates; `shrink_to_fit()` releases the prefix
  (a new `Vec` method, non-compliant until it lands).
- #2289 is fixed by the same mechanism: a failed guard moves head elements
  back by moving the offset back, and tail elements back into the capacity
  they left; the guard refusal goes.
- A fixed array's remainder `[T; N-k]` is an inline value and moves N-k
  elements; N is a compile-time constant and the length is part of the
  type, so there is no recursion to protect.
- Bootstrap: codegen and the runtime agree on word 3 within one compiler
  generation, so the change is two-step: first every helper takes the element
  size as an argument while the field still holds it (a seed is cut), then
  word 3 becomes `start`.
