# D71 — Ten rulings from the modeled-C close-out

**Laws:** 1, 5, 6 (docs/mission.md).

**Date:** 2026-09-27. **Status:** BDFL ruling (Eric: "predicted", accepting
the predictions of the close-out brief as written).

Each item was a spec gap or contradiction found while closing the issues the
modeled-C campaign opened; each brief compared the references, quoted the
spec, and predicted a ruling, and Eric accepted the predictions.

1. **#1587 — string slices.** `s[a..b]` on `str`/`&str` is a `&str` view of
   byte offsets; out of range or inside a UTF-8 character panics (§4.8a). Go,
   Rust, Swift and Zig all slice strings; With had range views for arrays and
   Vecs only.
2. **#1239 — positional `get` retired.** `xs[i]` is the one spelling for
   element access; a positional collection has no `get` (Eric, 2026-09-20:
   "`get(1)` shouldn't even be the way to access it … unless there's a
   *really* good reason to have two spellings"). Rust keeps both only because
   its `get` returns `Option`; With's did not. `get` stays the keyed-map
   lookup (D22). The migration is mechanical.
3. **#1482 — `@[flags]` without a repr** doubles in the default integer
   representation; never silently ignored (§4.4a).
4. **#1497 — `from_int`** exists only when every variant is a unit variant; a
   payload variant makes a call a compile error naming it (§4.4a).
5. **#1508 — closure `-> T`** is checked like a declared return type; never
   dropped (§12).
6. **#1564 — `:?`** covers the table's types, their compositions and any
   `impl Debug`; a type with no Debug form is a compile error naming it,
   never a placeholder (§15.4.7).
7. **#1421 — `@[repr(packed(N))]`** caps field alignment at N, C's
   `#pragma pack(N)`; `c_import` emits it (§16.4). My brief predicted it
   would be unwritable outside a facade; the text instead lets any record
   use it, as `repr(packed)` already can — Eric's merge of this PR is his
   ruling on that difference.
8. **#1432 — `ok` lists** several success constants; the success side
   carries the matched status (§16.2b.4; ruling Amendment 1).
9. **#1612 — `valid on failed`** presents an operation on the failed-state
   type (§16.2b.4; ruling Amendment 1).
10. **#1611 — `handle Name wraps *mut T`**: a callback-scope foreign
    representation with no producer, destroyer or `Drop`, borrowed for the
    callback (§16.2b.9; ruling §44, Amendment 1).

The compiler is NON-COMPLIANT on each until implemented.

---
