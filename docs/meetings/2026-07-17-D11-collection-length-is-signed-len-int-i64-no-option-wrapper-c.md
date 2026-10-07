# D11 — Collection length is signed: len() -> Int (i64); no Option wrapper; C's -1 conventions stay at the binding layer

**Laws:** 1 (docs/mission.md).

**Date:** 2026-07-17
**Status:** Accepted — BDFL ruling. **Deciders:** Eric (BDFL)

### The decision

`.len()` on every collection (Vec, HashMap, HashSet, BTreeMap, BTreeSet,
str, slices, arrays, SlotMap, VecRange) returns **`Int` (i64)**, not
`usize`. Length is never wrapped in Option. C conventions that encode
absence or failure in a size (null container pointers, `ssize_t -1`)
are translated at the modeled-C binding layer, never inherited by the
core container types. The narrowing family stays: `len32()`/`ulen32()`
panic on overflow as before; `len64()` becomes an identity alias of
`len()` and remains for compatibility.

This supersedes the §18.6 usize contract (the 28d6343c len-family
design). The BTreeMap/BTreeSet `len() -> i64` declarations, previously
a spec violation, become the conformant shape.

### Context / why

`v.len() - 1` on an empty Vec panicked with an unsigned-underflow trap
(#630) — the famous Rust `0..v.len()-1` wart, imported wholesale. The
maintainer's first design instinct (Option[usize], None = nonexistent
container) was run through the standard filter and rejected on the
mission's own clause: With's ownership + init rules make a null
container unrepresentable in safe code, so an Option wrapper forces
every call site to unwrap a case the compiler already proved impossible
— unnecessary characters by definition. Zero of five reference projects
wrap length in Option.

Reference filter (verified in .reference/ checkouts): **signed** — Go
(`builtin.go:179, func len(v Type) int`; Go's own spec prose writes
`len(a)-1`), Swift (`Array.swift:821, var count: Int`), Vale
(`str.vale:24, HashSet.vale:84 — int`). **Unsigned** — Rust
(`vec/mod.rs:2931 usize`), Zig (`array_list.zig usize`). The split
falls exactly along declared values: the ergonomics-first languages
chose signed; the explicitness-philosophy languages chose unsigned and
knowingly accepted the trap. Vale is our designated ownership
reference; Rust is the explicit ergonomics anti-reference.

Mission filter: "built to remove the suffering" (the trap is a named
suffering); "safe as Rust" is a bar, not a compass — signed lengths
clear it with zero loss (overflow and bounds stay runtime-checked; no
real machine holds 2^63 elements, so the lost bit is free); "raw C
stays explicit; modeled C becomes humane" assigns -1-as-error to the
binding layer (the with_net -errno precedent), keeping it out of the
core types. The runtime already stored lengths as i64 (with_vec.len,
with_hashmap_len) — only the sema surface said usize.

### Scope / implementation

Signed applies to the whole length/count/index-of family, so the surface
stays consistent: `len()` and the collection len methods, iterator
`count()` (a length), and `position()`'s index (`Option[Int]`). **`size`
/ `align` type-layout methods stay `usize`** — those are memory-layout
constants for FFI, a different category, deliberately excluded.

Spec-ahead-of-implementation: §18.6 now says `Int`; the sema surface
(`SemaCheck.collection_len_method_return_type`, the `count`/`position`
/`capacity` sites, and lib/std BTree decls) still says `usize` until
**#630** lands the flip (the implementation vehicle). This is the normal
spec-leads-compiler posture — **do not "fix" §18.6 back to usize to match
the compiler; the compiler is what changes.** #630 carries a self-host
flip sweep (#629 protocol: length typing threads through the compiler's
own sources) and the full battery.

### What would reopen this

A concrete C-interop boundary where translating size_t at the modeled
layer is shown to be impossible or pervasively costly, or a real
program that needs > 2^62 elements.

---
