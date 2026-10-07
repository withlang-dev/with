# D64 — Facade buffer pairing (`buffer param P len|capacity param L [inout]`) and fixed arguments (`param N fixed <literal>`)

**Laws:** 6 (docs/mission.md).

**Date:** 2026-09-24. **Status:** BDFL ruling (Eric: "Yes to buffer pairing.
Yes to fixed/hidden facade arguments. But don't conflate those approvals
with caller-visible slice-length mutation."). §16.2b.8 "Buffers" and
§16.2b.11 "Fixed arguments" carry the text. Resolves #1621 and #1624.

**Decision.** The meaning was already ruled by §16.3c (safe coercion at a
`c_import` boundary only when the binding models the full contract —
length or capacity, copy-back — with `write(fd, data)` as its example);
what was missing was the normative spelling by which facade source proves
that two C parameters participate in that contract. Since guessing the
pairing could manufacture an out-of-bounds call, that spelling is safety
syntax, not parser plumbing, so it needed a ruling. Three tightenings over
the first draft: (1) zlib's `destLen` is **in/out** (capacity on entry,
produced length on exit), so the clause says `capacity … inout`, leaving
room for genuinely output-only lengths; (2) the caller's `[]mut u8` is
**not** modified — a `[]mut T` parameter is an exclusive borrow whose
caller binding survives unchanged, and an FFI call rewriting the caller's
fat-pointer descriptor would be a new With semantic, not modeling of C;
the bridge computes `capacity = dest.len`, calls C with `&capacity`,
bounds-checks the written value against the original capacity, and
returns it as `usize` (a narrowed view `[]mut u8` borrowing from `dest`
may come later); (3) the length **counts bytes** and renders `[]u8` — the
same syntax is not generalized to `T * + size_t` until it is decided
whether the integer means bytes, elements, code units or structs.
Copy-back validity after failure is the status contract's call (§16.2b.4):
the value is presented only on success. A raw pointer parameter no clause
pairs is not a buffer, and `lend`/presentation on such a function is
refused (the hole #1625 found: a bare `lend` on `compress` rendered a
safe call with no bounds contract).

**Fixed arguments.** `param N fixed <literal>` binds a C parameter to a
literal and removes it from the presented signature; the raw operation
stays available. Eric rejected `default`: it reads as an optional argument
callers may override (`prepare(sql, other)`), whereas the fact is "this
facade binds this C parameter to this literal". Between his two spellings
(`param N fixed …`, `bind param N = …`) the first was chosen: it sits in
the existing `param N …` clause family.

**What the others do.** No language declares the pairing in a binding:
Rust (`as_ptr()/len()` in `unsafe`, `improper_ctypes` forbids slices in
`extern`), Go (`&b[0]` + `C.size_t(len(b))`), Zig (`s.ptr, s.len`), Mojo
(`unsafe_ptr(), len(s)`) all split by hand; Swift alone generates a
buffer-taking wrapper, and only from a Clang `__counted_by` annotation
behind an experimental flag, with no out-length support; Vale passes its
own arrays and cannot call a `(T*, n)` API without a C shim. With's
answer is §16.3c's evidence model: an explicit clause is evidence of the
same standing as a header annotation.

**2026-09-25 amendment — explicit element counts (#1643).** Eric approved
the explicit `elements` qualifier: `buffer param P len param L elements`
and `buffer param P capacity param L inout elements`. These render typed
`[]T` and `[]mut T` using the C pointer's element type. The compiler checks
conversion of the slice count to the C count type before the call and checks
a copied-back count against the original element capacity before returning
it as `usize`. The caller's slice remains unchanged and copy-back is still
presented only under the status contract. Unqualified clauses continue to
count bytes; pointer types and names never select the unit. This replaces
the original decision's restriction against element slices, not its explicit
pairing or bounds requirements. Swift's checked-in `SwiftifyImport`
`CountedBy/NamedParams.swift` and `SizedBy/SimpleRawSpan.swift` likewise
distinguish element count from byte count and use exact integer conversion.

---
