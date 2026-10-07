# D72 — A `Drop` type whose all-zero storage is a live value gets a hidden liveness byte

**Laws:** 7, 5 (docs/mission.md).

**Date:** 2026-09-27. **Status:** BDFL ruling (Eric: "Problem 1: option 1").

#1431: the reset sentinel is zeroed storage (§2.5.1), so a live `Drop` value
whose bytes are all zero (`Fd { n: 0 }`) is skipped by its own drop. Rust
elaborates per-path drops with a runtime drop flag only where a place is
conditionally live; Mojo and Swift destroy per control-flow path with no
runtime marker at all. Options weighed: (1) a hidden liveness byte for the
affected types only, as the facade renderer's `live` field already does;
(2) per-path drop elaboration replacing the sentinel model (the reference
design, a campaign); (3) restricting `Drop` layouts (the programmer writes
what the compiler knows — rejected). Ruled: (1). A type with an owning
non-null field keeps the storage test and pays nothing. (2) remains the
direction if the sentinel model is ever retired.

---
