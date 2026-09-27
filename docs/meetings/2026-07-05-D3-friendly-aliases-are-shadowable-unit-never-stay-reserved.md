# D3 — Friendly aliases are shadowable; `Unit`/`Never` stay reserved (split of option D)

**Date:** 2026-07-05
**Status:** Accepted
**Issue:** #627 (substrate) · **Spec:** §4.1, §29.8 · **Deciders:** Eric (BDFL)

### Decision

The friendly convenience aliases `Int`, `UInt`, `String`, `StrView`, `CStr`
become prelude-scoped, user-shadowable names: a `type` declaration of the same
name in a user module wins over the builtin alias. The core primitives
(`i8`…`u128`, `f32`/`f64`, `bool`, `str`, `usize`, `isize`) **and** `Unit` and
`Never` stay compiler-reserved (not shadowable).

The original option-D ruling (2026-07-04) demoted all seven friendly names
*including* `Unit`/`Never`. Scoping revealed `Unit` has ~331 uses across the
compiler sources (`Never` ~15) — it is a core type in every `-> Unit`
signature, not a convenience alias — and `Unit`/`Never` are not cleanly
spellable as an alias RHS (no `()`/`!` type syntax). Demoting them is a
high self-host-flip-risk change out of proportion to any benefit, so they are
excluded. Eric ruled for the split.

### Implementation note

Shadowing was already *almost* free: `register_prim` records these names as
empty-path (prelude-tier) entries, and `lookup_named_type_visible` returns a
visible user declaration before the empty-path fallback. The only thing forcing
the builtin was four resolution-first hardcodes in `primitive_type_by_sym`
(SemaDecl.w) for `Int`/`UInt`/`String`/`StrView` — dead when unshadowed (the
named-types path returns first), fired only to override a user shadow. Removing
those four lines enables shadowing with zero self-host impact (the compiler
never shadows these; unshadowed resolution is byte-identical). `CStr` was
already a plain named struct, not resolution-first. This also unblocked the
`StrView`-collision that obstructed probing #625/#626.

### Reasoning

Matches Go's universe-block predeclared identifiers and Rust's prelude — both
shadowable — while keeping the truly foundational names reserved (Zig-style)
where user override would be a footgun with no upside. "Don't make the user
write ceremony / don't block a safe user choice" (mission) argues for
shadowable conveniences; "never risk the self-host build for a cosmetic win"
argues for keeping `Unit`/`Never` reserved.

---
