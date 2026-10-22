# D150 — A `static inline` function a header defines that no unit owns is published by its sole includer; several includers keep a private copy each

**Date:** 2026-10-22. **Status:** ruled by Eric (on the D148 brief: "pull it
into its own one-paragraph ruling with a fixture, so it's citable").

## The rule

In `with migrate`, a `static inline` function defined in a header is the
header's API. The unit named after the header (`tommyhashdyn.c` for
`tommyhashdyn.h`) publishes it and includers import it (the header-owner
rule). When no unit owns the header, the units that include it define it:
exactly one definer publishes it as `pub`, as the owner would have; two or
more definers keep a private copy each (two copies of one name in one
package do not compile yet, #1139). The rule is general — it changes what
every corpus emits for an un-owned header with a single includer — and it
is the general statement of "one definition, one owner".

## Why

STC's templates are instantiated by define-then-include, and a template
header defines its functions in other headers (`hset.h` is `hmap.h`,
`sort.h` is `priv/sort_prv.h`), so the header-owner rule alone cannot reach
an instantiation: the facade shapes unit (`facade_shapes.c`, D148) is the
one includer that defines `stc_slot_set_*`, and the facades need those
functions published. A unit named after a template header was tried and
refused: under the header-owner rule it claimed every other includer's
instantiations (the test corpus's `IDeq_at` went undefined). Publishing a
sole definer adds surface to a corpus interface only where no second copy
could exist; facades choose what to wrap.

## Fixture

`test/behavior/behav_migrate_header_inline_owner.w`: `engine.c` is the only
includer of `util.h` (no `util.c`), so `util_twice` is `pub fn` in
`eng.engine`; `engine_scale`, the unit's own `static inline`, stays private;
`engine.h`'s API is published by `engine.c` and imported by `user.c`.
Implementation: `CiProject.resolve_header_definers` (src/CiMigrate.w), run
after the project scan.
