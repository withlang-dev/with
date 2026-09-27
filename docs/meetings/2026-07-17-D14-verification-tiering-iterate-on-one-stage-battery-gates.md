# D14 — Verification tiering: iterate on one stage; battery gates commit batches

**Date:** 2026-07-17
**Status:** Accepted — maintainer-directed ("fix this issue deeply").
**Deciders:** Eric (BDFL)

### The decision

- **Iterate tier:** while developing, verify with `with check` and/or
  `with build :dev` (seed → stage1, ONE self-compile, ~3.5 min to a testable
  binary at `out/bootstrap/bin/with-stage1`) plus targeted test files. No
  battery per edit.
- **Commit tier:** the full battery (build, fixpoint, `audit:all`, `:test`,
  `:test-green`, `:last-green`) gates every commit batch. `audit:all` and
  `:test` may run **concurrently** — they share no outputs (audit needs
  stage2, tests need the release binary), and audit's ~6 min hides inside the
  test leg.
- **Batch rule:** independent, low-risk build-layer changes (build.w,
  build/*.w, docs, non-semantic executor changes) may share ONE battery and
  then land as separate per-change commits. Anything touching language
  semantics, codegen, ownership/drop scheduling, or ABI keeps the strict
  battery-per-change rule.
- **Fixpoint stays in the commit tier unconditionally.** The references argue
  convergence from cache keys (Go) or defer the byte-diff to release CI
  (Zig); With's per-commit byte-fixpoint is stronger and has caught real
  nondeterminism. The waste was repeating it per *edit*, not having it.

### Context / why

Measured 2026-07-17 (`out/.build-state/build-times.tsv`, first data from the
D-instrumented executor): stage1 175.9s + stage2 174.3s + link-compiler
173.0s = 77% of an 11.4-min `with build`; the full battery was ~30-40 min.
Three consecutive ~30-min batteries were spent landing three independent
build-graph changes where one batched battery carried identical evidence —
~1 h of pure ceremony in a single session. Every reference compiler tiers
verification (Rust `x build` = stage 1 by default; Zig's dev loop is one
self-compile with fixpoint in release CI only; Go primes its cache for
iteration). See `docs/build-perf-reference-study.md` for the evidence trail.

### What would reopen this

A regression that a batched battery passed but per-change batteries would
have isolated (and that bisection could not); or a recurring bug class that
`check` + stage1 misses and only stage2 exposes, making the iterate tier
untrustworthy.

---
