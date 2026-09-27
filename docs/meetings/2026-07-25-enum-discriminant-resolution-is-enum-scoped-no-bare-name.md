# Enum discriminant resolution is enum-scoped; no bare-name fallback

**Date:** 2026-07-25
**Status:** Accepted
**Deciders:** Rob O'Callahan

**Decision.** `enum_variant_discriminant_for_type` and
`type_reflection_variant_discriminant` trust `disc_values` **only** through the
qualified `Enum.Variant` key. When the qualified key is absent they fall through
to the variant `index` (for payload enums) rather than to the bare variant-name
key.

**Context.** `disc_values` is populated only for DiscEnums (`enum X: i32: A =
0`), keyed by BOTH the bare variant-name sym and the qualified `X.A` sym. Payload
enums (`enum Option[T] { Some(T) | None }`) never register `disc_values`; their
discriminant is the declaration index. The bare key is therefore shared across
every enum that declares a variant of that name. The compiler's own `enum
CliOneLinerMode { None = 0 }` set `disc_values["None"] = 0`, and the old bare
fallback made `enum_variant_discriminant_for_type(Option[..], None)` return 0
instead of 1. For a niche-encoded `Option[&V]` (the D22 map-view type), codegen's
`RK_DISCRIMINANT` computes `None = (ptr == null) = 1`, so `x.is_none()` lowered
to `discriminant == 0` (i.e. `is_some`) — every niche `is_none` was inverted,
sending `None` into `unwrap` (`unwrap on None` abort). This is why head
self-hosting aborted at `CodegenDispatch.mir_indirect_value_local_ptr`: the
niche `Option[&i64]` returned by `mir_local_types.get(..)` never crashed on a
tiny program (no other enum named a `None` variant), only inside the full
compiler.

**Alternatives weighed.** (a) Register `disc_values` for payload enums too — but
the bare key still collides, so it only papers over the lookup; the bare entry
stays ambiguous. (b) Make codegen's niche path derive the discriminant from the
semantic disc — insufficient, because the bug is that the semantic disc itself
was resolved through a colliding global name key. (c, chosen) Never consult the
bare `disc_values` key: both enum kinds register their qualified variant in
`variant_lookup`, so `qualified_enum_variant_sym` always yields the genuine
`Enum.Variant` key for a valid enum decl; DiscEnums resolve via that qualified
`disc_values` entry, payload enums fall through to `index` (== their implicit
discriminant). No enum's discriminant is ever read through a name another enum
can shadow.

**Reopen if** a variant discriminant is ever needed without a resolvable owning
enum type; then it must be stored per-enum, never under a bare global name.

---
