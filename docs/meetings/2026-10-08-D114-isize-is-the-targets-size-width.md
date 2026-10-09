# D114 — `isize` is the target's size width; unsuffixed integers default to `isize`

**Date:** 2026-10-08. **Status:** ruled (Eric Hartford). **Amends** D108
(its "pointer-width" definition becomes the size width; `len()` returning
`isize` stands) and settles D113's open element-default question
(`[1, 2, 3]` is a `Vec[isize]`). D11's signedness stands. **The compiler is
NON-COMPLIANT** until the stages below land.

**Ruling (Eric, verbatim).**

"isize/usize are the target's size width: C's ptrdiff_t/size_t, wide enough
for any length or offset into memory. Not defined as pointer-sized; an
integer that holds a pointer is a separate FFI type if one is ever needed.
Replace the stale types.md sentence ("64-bit on all supported targets") with
this definition."

"len() and the length family return isize. This settles the width question
D11 left open. D11's signedness stands."

"Unsuffixed integer literals default to isize, everywhere, including in
bracket literals."

"Literals and comptime arithmetic are checked at the target's width, not the
host's. wasm32 already makes this real today."

"Values not bounded by memory use a fixed width: timestamps, file sizes and
offsets, hashes, IDs, money, anything serialized or crossing into a C struct
layout. A serialized or C-layout struct with an isize field warns."

"Supported targets today are 64-bit hosts and wasm32. The standing
constraint is that nothing in the language, stdlib or compiler may assume a
particular isize width, so other widths stay possible later without a
redesign. Add that to CLAUDE.md beside the ceremony rules: no code depends on
isize being 32 or 64 bits, and a value whose range isn't bounded by memory is
written with a fixed width."

"I am NOT saying that TODAY, with must compiler on 16- bit and 128-bit. I AM
saying we should not SABOTAGE its ability to do so in the FUTURE, by making
POOR choices today."

**Why size width, not pointer width (from the discussion).** On most
machines they coincide, but not on all: on 16-bit segmented targets
`size_t` is 16 bits while far pointers are 32; on CHERI, capability
pointers are 128 bits while `size_t` is 64. C keeps them apart
(`size_t`/`ptrdiff_t` for sizes and offsets, `uintptr_t` for pointer
storage), and With follows. A hard-coded `i64` default would mean emulated
64-bit arithmetic for every counter on a small target; `i32` cannot index
past 2^31; `isize` scales with the target.

**Work (Eric's stages, count-first).**
1. Spec and log (this entry; §4.1, §4.2.1, D108, D113, CLAUDE.md).
2. Compiler: literal default and the `len()` family to `isize`; comptime
   `isize` arithmetic at the target width; the serialized/C-layout struct
   warning.
3. Stdlib audit: list every integer holding a value not bounded by memory,
   report the list, then move each to an explicit fixed width.
4. Sweep: count and remove the casts between lengths and literal-typed
   integers as a mechanical commit.
5. Corpora whose output the ruling changes re-promote in this campaign
   (D112, third trigger).
Gate after each stage, battery before the PR.

**What would reopen it.** A target where no size width exists that bounds
memory offsets, or a measured cost of `isize` arithmetic on a supported
target that the compiler cannot remove.
