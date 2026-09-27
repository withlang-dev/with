# D19 — Verification cost scales with blast radius; batteries bless batches

**Date:** 2026-07-22
**Status:** Accepted.
**Deciders:** Eric (BDFL)

**Decision.** The full battery blesses a BATCH of commits, not each commit;
per-change verification is the iterate tier (`with check` / `:dev` +
targeted tests). Only ownership/drop, codegen-determinism, and ABI changes
must sit alone in their batch (with the drop audits). Corollary for the
build system itself: a request must cost what it names — installing a
blessed artifact is a manifest check plus a file copy, never a graph
evaluation (the `:update-seed`/`:install-user` fast path), and evidence is
written once by the step that produces it, only read thereafter.

**Why.** Battery-per-change grew from real incidents, but at ~20–40 min per
battery it made a day of small commits cost hours of redundant
recompilation of the same 160k lines (#684 measures the constant). Process
is a resource with the same failure mode as memory: obligations allocated
per incident and never freed. Verification depth now follows risk, and the
gates themselves must not re-derive what the battery already proved.

**What would reopen this.** A regression that a batched battery localized
too slowly to bisect — that argues for faster builds (#684), not more
batteries.

---
