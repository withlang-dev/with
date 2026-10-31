# D178 — A `mut fn` call mutates the field paths its body writes, at full depth, within a package; the whole receiver across packages

**Laws:** 1, 3, 6 (docs/mission.md). Rules D172 point 6.

**Date:** 2026-10-31. **Status:** ruled by Eric ("I rule A", "full depth").

**Ruling.** Within a package, a `mut fn` call on a receiver (or a `mut`
argument) mutates the static field paths of that place its body writes,
not the whole place. A live view of a path that is structurally disjoint
(§3.6: the paths diverge at a field access, at any depth) survives the
call. Across packages the call mutates the whole place: the declared mode
is the contract (D172), and the footprint only relaxes above that floor.

A body's footprint over `self` (or over a `mut` parameter) is the union
of:

- the paths it assigns to;
- for a `mut` call on a field path, that path extended by the callee's
  footprint;
- for a `mut` call on the place itself, the callee's footprint;
- the whole place for an assignment to the place, a write through
  `unsafe` or a raw pointer, a call through a trait object or a callable
  value, a callee outside the package, or a `move`.

An index projection ends a path at the indexed field (any element). An
auto-deref through an owning pointer field continues the path through
the field (§3.7). A write to a path conflicts with a view of any prefix or
extension of it. Footprints are computed in the effect fixed point that
settles the declared modes, one per template body, and are never spelled.

**Why.** PR B (D172's enforcement) left seven live-view errors whose
shape is one: a view of field A (`mod` in `self.last_resolved.modules[mi]`)
held across a `mut` call that writes field B (`add_source_text_mapping`).
Each took an owned binding with a ceremony allowance; the `.clone()` of
the substitution lists in `substitute_current` is the same class. §3.6
already guarantees disjoint access for a direct write at any depth; the
same write inside a method was refused, so a statement was legal and the
method containing it was not. The body determines the footprint, so the
caller should not state it (Law 1); the mode stays declared because it is
the contract a reader of the signature needs (Law 6). Rust borrows the
whole receiver and offers free functions over the fields (its view-types
proposal spells footprints at the declaration); Swift's exclusivity treats
a `mutating` method as the whole value; Mojo's origins are field-sensitive
but methods take the whole. Nobody infers it; the spec already has the
path machinery and the disjointness rule.

**Declared footprints** (`mut(cache) fn`) were dropped: writes what the
body already says. **Keeping the annotations** was dropped: ceremony from
a checker coarser than the program.

**Full depth over first segment.** First-segment (`physics`) was
considered: it covers every site found and is smaller to write. Rejected
because §3.6's own words are "at any nesting depth", and a first-segment
footprint would make `self.physics.positions[i] = p` legal beside a view
of `self.physics.velocities` while `self.physics.step()` doing the same
write was refused.

**Consequence.** Sema: the per-signature write effect gains a path set
(`sig_write_paths`), filled where EFF_WRITE on a receiver or `mut`
parameter is recorded and closed in `fixpoint_effect_flow`; the live-view
check at a `mut` call tests the view's path against the callee's
footprint with the prefix rule; across packages the footprint reads as
whole. Spec words in §3.2 and §3.6. Fixtures: `behav_d178_disjoint_field_footprint.w`
(a view of one field across a method writing another, at depth two),
`err_d178_overlapping_footprint.w` (a write to a prefix), and a
cross-package fixture where the same call is refused. The seven PR B
annotations and the `clone-call` allowance come out in the landing PR.

**Reopen if:** footprint inference proves unsound in a case the
second-class reference rule (§3.3) was expected to rule out, or a body
change relaxing a footprint is found to change a public contract.

**Implementation bound (2026-10-31).** A footprint that grows past 64 paths
is read as the whole place (sound: the whole place contains every path).
The compiler's own `Sema` methods transitively write hundreds of fields;
closing those paths over every caller was quadratic (540k entries, 54M
path elements, a stage2 timeout) and a view of a sibling field never
survives such a method anyway. `WITH_PROFILE=1` prints the fixpoint's time,
passes, edges and entries.
