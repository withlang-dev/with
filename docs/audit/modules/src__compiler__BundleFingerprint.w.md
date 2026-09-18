# Audit: src/compiler/BundleFingerprint.w @ 450733e5 — COMPLETE

Verdict: COMPLETE

Scope: read-only audit of `src/compiler/BundleFingerprint.w` (61 lines) at commit
450733e5. Targets traced: T13 ownership/drop, T15 migration fidelity, T22 spec
conformance. Callers traced via repo grep; doc contract `docs/wo_bundles.md`
fingerprint section checked; `out/bootstrap/bin/with-stage1 --help` probed.

## Findings

1. src/compiler/BundleFingerprint.w:21-36 (bf_sorted_lines) — OK (T13, probe: code read; refutation: callers pass only short-lived Vecs) — Insertion sort clones each string via `with_str_clone_ref` on every move (O(n^2) clones, old `sorted` vec dropped by move `sorted = out`). No leak/double-free shape: every pushed element is a fresh clone, `item`/`existing` borrows are never stored. Cost is fine (export-row counts are small). No change.
2. src/compiler/BundleFingerprint.w:41-59 (bundle_fingerprint_text) — OK (T22, probe: code read + docs/wo_bundles.md:368-381,411-427 greps) — Canonical TSV matches documented contract: `bundle-fingerprint\tv1\ttarget:<resolved>\tcorpus:<corpus>` header, `module\t<name>` rows plus export row-split lines, blank rows skipped, all lines sorted via `with_str_cmp_ref` (bytewise). Target pinned via `target_spec_resolved_name()` (src/TargetSpec.w:99), consistent with Link.w:1017 target check. No TypeId/node-id/span leakage (rows come from `BundleInterfaceModel.row` spellings + layout numbers only, per header comment). No change.
3. src/compiler/BundleFingerprint.w:61 (bundle_fingerprint_sha) — OK (T13/T22, probe: code read; refutation: Compilation.w:446-453,537,572,1278 use `bundle_text_sha256` uniformly) — Thin delegate to `bundle_text_sha256` (BundleInterfaces.w:22); single sha256 primitive shared by fingerprint, `.wi` sha, and manifest paths, so `a == b` cross-process comparison is apples-to-apples. No ownership issue (borrow in, owned str out). No change.
4. T15 migration fidelity — N/A, no defect (probe: `grep -rn bundle_fingerprint src/ tests/ seed/` shows hits only under `src/compiler`, `src/main.w`; zero `seed/` hits) — New module with no seed counterpart; nothing to migrate. Negative control: sibling `bundle_text_sha256` lives in `BundleInterfaces.w:22` and is reused rather than reimplemented here. No change.
5. Callers (refutation sweep) — OK — `Compilation.w:446-466,1245-1256` (write + check paths), `DriverOptions.w:262,512,521` (arg plumbing + empty-corpus guard), `main.w:845,926-930` (check/build wiring, errors when fingerprint requested with empty corpus). No caller depends on declaration order (sorted), on unsorted output, or on TypeIds. No defect survives refutation.

## Probes run

- P1 (read): full module read, 61 lines, commit 450733e5 confirmed via `git rev-parse --short HEAD`.
- P2 (callers): `grep -rn "bundle_fingerprint" --include="*.w" src/ tests/ seed/` → Compilation.w, DriverOptions.w, main.w, BundleFingerprint.w only.
- P3 (primitives): `grep -rn "bf_sorted_lines|bundle_text_sha256|target_spec_resolved_name"` → single sha/target primitives shared across fingerprint, manifest, link checks.
- P4 (spec): `grep -n fingerprint docs/wo_bundles.md` → lines 368-381 (two-process a==b protocol), 411+ (sha256 over TSV) match implementation.
- P5 (binary): `out/bootstrap/bin/with-stage1 --help | grep -i bundle` → no bundle lines in help excerpt (help does not advertise bundle flags); no live `build --bundle-fingerprint` run attempted (read-only audit, avoids corpus side effects). Status: inconclusive, not blocking — static + caller evidence sufficient.

## Negative controls

- N1: `seed/` has no `bundle_fingerprint` symbol → T15 has no migration source; not a gap.
- N2: empty-corpus misuse is rejected at `main.w:927` / `DriverOptions.w:521`, so fingerprint never runs with an empty corpus silently.
- N3: blank export rows (`end > start` guard, line 52) are dropped rather than hashed, so trailing-newline variance cannot flip the hash.

Verdict: COMPLETE
