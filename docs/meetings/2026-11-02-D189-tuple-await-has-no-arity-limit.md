# D189 — Tuple `.await` has no arity limit

**Laws:** 1 (docs/mission.md).

**Date:** 2026-11-02. **Status:** delegated (D98, 90%) on the brief for
#2963.

**Ruling.** §14.11's sentence "Tuple `.await` supports tuple sizes 2..12"
is deleted, and Sema's check ("await tuple requires between 2 and 12
tasks") with it. The desugar is generic over arity; the number was Rust's
tuple-impl macro limit (`tuple_impls!` up to 12), a representation detail
of another language written into With as a rule the user had to remember.
