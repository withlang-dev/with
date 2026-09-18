# Audit: src/compiler/AbiStamp.w @ 450733e5 — COMPLETE

Module: 19 lines. ABI identity slot: fixed-width sentinel string patched
post-link with sha256 of `docs/with-abi.sha256`; `with version --abi-sha`
prints it; link stage refuses cross-ABI bundles (#761, D38, D13).

## Targets
- T13 ownership/drop: PASS. Only `extern fn with_str_from_cstr(p: *const u8) -> str`
  over a static literal slot; no allocation, no owned value crosses the
  boundary, no drop obligation. Both pub fns return borrowed/static data.
- T15 migration fidelity: PASS. Sentinel `WITHABISHASTAMPv1` + `X` padding is a
  fixed-width slot; `compiler_abi_sha_is_stamped()` = `not starts_with(
  "WITHABISHASTAMP")` correctly distinguishes patched (64-hex sha) from
  unstamped binaries. No logic to mis-port.
- T22 spec conformance: PASS. Callers implement the documented contract:
  - `src/compiler/Compilation.w:520-521` — refuses `--link-bundle` on ABI mismatch
  - `src/compiler/Compilation.w:1289-1292` — refuses bundle-key computation when
    unstamped; emits `abi-sha` manifest line otherwise
  - `src/compiler/Link.w:1008-1009` — refuses embedded bundle on ABI mismatch
  - `src/main.w:964-965` — `version --abi-sha` prints the slot

## Findings
No defects. (1) Refutation: the only candidate concern — `with_str_from_cstr`
returning `str` without a copy/drop — fails vs in-repo usage, since the source
is a static literal with static lifetime (no owner, nothing to free), and all
four call sites use the value read-only. (2) Slot-width vs 64-hex sha and the
post-link patch live in `build/compiler.w` (run_patch_version_action), outside
this module; comment cites it accurately.

## Probes run
- `out/bootstrap/bin/with-stage1 version --abi-sha` → 
  `b5643494731dfc1502811ad142784b8348e998d2c2e472a16c1ca4d8a4db90e8`
  (64-hex, stamped bootstrap — confirms patch pipeline works end to end).
- Negative controls (static, not executed): unstamped guard at Compilation.w:1289
  and both mismatch refusals (Compilation.w:520, Link.w:1008) present; a live
  mixed-ABI link probe was not run (requires building a second tampered bundle;
  disproportionate for a 19-line leaf with all branches statically confirmed).

Verdict: COMPLETE — no findings; T13/T15/T22 all pass, probe confirms stamped output.
