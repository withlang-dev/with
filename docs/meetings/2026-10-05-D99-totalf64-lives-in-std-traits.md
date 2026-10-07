# D99 — `TotalF64` lives in `std.traits` and is imported (delegated)

**Laws:** 1 (docs/mission.md).

**Date:** 2026-10-05. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2182.

**Decision.** `TotalF64` and `TotalF32` are declared in `std.traits`,
beside the `Key` trait they implement, and a program imports them
(`use std.traits.TotalF64`). They are not added to the prelude. The
float-key error's help names the import.

**Why.** §18.2 enumerates the prelude exactly; adding a name to it is a
spec change of its own, and the D29 fallback tier will make every std
name ambient without one. D97's "`std.TotalF64`" says the type is std's,
not which module. `std.traits` is where `Key` lives, so the type sits with
the contract it exists for.

**Prediction.** 75% that Eric keeps it. The alternative he might prefer is
the prelude, for no-import ergonomics; that is a one-line change to
`sema_prelude_gate_allows_name` plus §18.2's list.

**Reopen if** the D29 fallback tier is delayed and programs keyed by floats
turn out common enough that the import is ceremony.
