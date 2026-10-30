# D174 — A view that cannot outlive its statement establishes an owned-value demand (D22 amendment)

**Status:** Ruled (Eric, 2026-10-30). Amends D22 §3.2 and §6.2
(`d22-Eric-Ruling.md`), as D144 did for plain-bits elements.

## Question

`let p = args()[1]` was refused: "binds a view into a temporary
`List[str]` … demand an owned `str` (`: str` on the binding)". D22 §3.2
says inference alone is not an owned-value demand, so the unannotated
binding stayed a view, and a view into a statement temporary cannot
outlive the statement. The annotation is the only spelling, and it says
nothing the program had not already determined.

## Ruling

> In both cases (`let p = args()[1]`, `fn first(): names()[0]`), a view
> into a statement temporary cannot survive the temporary's destruction.
> The compiler has two sensible choices: construct an independent owned
> value or reject the program. If the type supports the necessary
> ownership-preserving copy, requiring a redundant `: str` annotation
> serves no purpose.

The rule, in Eric's words:

> An unannotated binding or function return whose inferred view would
> refer to a statement temporary requires an owned result. If the viewed
> type supports `Copy`, the compiler materializes an independent owned
> copy before the temporary is destroyed. Otherwise, the program is
> rejected. An explicitly declared `&T` remains a request for a view and
> does not trigger this conversion.

> The word independent matters. In particular, `Copy` must guarantee that
> the result doesn't retain a dangling pointer into the destroyed
> temporary, even for types such as `str` and `List`.

Ruling: approve the D22 amendment and merge #2838 once the specification
and implementation agree. The regression strategy stands: the earlier
use-after-free shapes (#962, #2225, #2659) are covered under the debug
allocator, not merely accepted without an annotation.

## Notes

- `str` (D111) and `List` (D120) are Copy by a counted share: the copy
  holds its own count on the buffer, so it is independent of the
  temporary that is destroyed.
- A resource (identity, D111) is not Copy; its view into a temporary is
  still refused with the `.clone()` remedy.
