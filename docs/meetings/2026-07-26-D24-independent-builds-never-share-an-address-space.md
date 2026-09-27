# D24 — Independent builds never share an address space

**Date:** 2026-07-26
**Status:** Accepted — BDFL ruling.
**Deciders:** Eric (BDFL)

**Decision.** A build is a process boundary. `parallel(workspaces)` in a
build.w runs each workspace compile as its own `with __workspace-compile`
child process: the plan crosses as a serialized file, the result comes
back the same way, and the children share no memory with the evaluator or
each other. The former implementation — worker threads handed raw interior
pointers into a shared job vector — is deleted and must not return in any
form. An intercept-active workspace still runs in-process (its message
stream needs the live Compilation), sequentially.

**Context (#729).** The thread fan-out was the site of a multi-layer
double-free hunt: share-place-classified params retaining vec handles,
whole-job element copies, and hand-rolled `jobs.ptr + i` arithmetic —
every layer invisible to the ownership analyses because raw pointers and
threads opt out of them. The ruling ends the class structurally instead
of patching its instances: "we claim Rust-level safety; builds have no
business sharing a single process." The build pool (#683) already used
processes for pooled targets; this aligns comptime parallelism with it.

**Reopen if:** never for safety reasons; only revisit the mechanism if
plan serialization becomes a genuine bottleneck, and then only with an
isolation-preserving design (e.g. immutable shared mappings), not shared
mutable memory.

---
