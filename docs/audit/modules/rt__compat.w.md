# Primary verification — `rt/compat_runtime.w` + `rt/cimport_stubs.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: compat `3ed5cf0f6147dd9366634d442d52e6891ff614d6588a91ee8151524a06ed64ec`;
stubs `0771e908ec171952e721462fe839e6713280193af885c816003f53056d30c8dd`
Source examined: child both complete (1-67, 1-601); primary: CImport.w:590-610
+ Frontend.w:400-420 fallback branches (full reads)

## Scope examined

Compat shims, cimport-unavailable degradation.

Applicable overview targets examined: T15 (shim correctness), T19 (config
coverage), T23 (silent degradation).

## Verdict: shims correct; one inspection-grade degradation note (NOT filed)

- The 15 externs + 15 forwarders are faithful passthroughs with sane
  degenerates (0/-1/opaque=1); recorded as child evidence, primary agrees on
  the pattern from the fallback-branch reads.
- CIMPORT-001 (note, not filed): `CImport.w:599-600` returns "" with NO error
  when libclang is unavailable, vs the neighboring cross-target branch
  (:593-595) and session-failure branch (:605+) which both set
  `g_cimport_last_error` loudly. Frontend falls back to text-spec expansion
  with hints-only omissions. The shape is real in code, but the path requires
  a libclang-less build the audit cannot construct on this host — no
  execution possible, so per the execution standard it stays a note with
  exact lines, not an issue. If a no-libclang configuration is ever built,
  re-examine here first.

## Notes

- Contrast with the fiber_stubs leg (rt__panic_stubs.w.md): same
  degenerate-shim pattern, but there the trio was execution-verified.
