# Primary verification — Windows runtime (`rt/fiber_core_windows.w` + stub + `rt/windows_x86_64.w` + `rt/windows_aarch64.w`)

Status: **Complete (inspection-grade: cannot execute on Linux)**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: core `0c5ab97305d4c7608baa6b818a49b69d342e1decbe235543fd4608413c715771`;
x86_64 `3f4b53a08a11d0394b19f814801a438390778a2d463d51c30684721051a08bbd`;
aarch64 `92dcbf224c2108ad83c0f08aa5dcd0c6fbaf71b83edd323d997dc8d00544a32c`;
stub `260e5d0cfc20691b2e0b0c3ac742d17fb120b7b0614763262594b79e438ed35b`
Source examined: child all four complete + darwin baseline comparison; primary:
accepted as inspection-grade (all four `check` rc=0 re-runnable on Linux since
With is platform-abstracted at check time, but no Windows execution possible)

## Scope examined

Windows fiber-core parity vs the audited darwin core (baseline:
`docs/audit/modules/rt__fiber_core_darwin.w.md`), x86_64/aarch64 backend parity.

Applicable overview targets examined: T15 (parity), T19 (platform), T23.

## Verdict: parity holds; one architectural divergence recorded

- Parity OK (child comparison, accepted): slot table + generations +
  free-list, `(gen<<10)|slot` ids, MAX_FIBERS=1024, spawn-cap triple,
  1024 panic ring, dead `with_fiber_set_result` twin, INT32_MIN write twin.
  x86_64 vs aarch64 backends differ ONLY in header + arch constant
  (diff-verified by child).
- DIVERGENCE D1 (note, inspection-grade): the Windows core is
  single-threaded — no scheduler mutex/cond/workers/stealing; one
  ready_queue + one steal_queue drained by the same thread. Consequences
  follow: #995's spawn cap and #991's race shape differently there
  (no cross-thread stealing possible; cap logic shared). Any fix for #995/
  #991 must consider both cores. Not a defect per se (design divergence),
  flagged so threaded-assumption fixes don't break the Windows build.

## Notes

- All findings in this file are inspection-grade by construction (stated in
  Status). A Windows runner re-examination is recommended before closing
  any threading fix.
