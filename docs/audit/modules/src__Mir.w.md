# Primary verification — `src/Mir.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `069f6824b37a6cfc6d8eee32fa5a84cdfe7a8275a227871fde18b64dc7804ce4`
Source examined: child 1-3674 complete (seven reads); primary: clamp region
1083-1104 + 1189-1199 + 1927-1929 (full read), intrinsic enum 200-294,
TK_YIELD validator note 48-49, plus probe re-runs below

## Scope examined

MIR types, arenas, transfer functions, validators, dump routines, intrinsic
enum.

Applicable overview targets examined: T5 (move/drop transfer), T13-14 (MIR
validity), T23 (clamp loudness), T24 (overlap with MirLower.w).

## Behavioral matrix

- `docs/audit/probes/mir_core/probe_many_locals.w` (1100 lets): primary re-ran
  `check --validate-all` → ok rc=0; `--dump-mir` contains the loud marker
  `... locals truncated (77 more)` (grep count 1). Dump cap is display-only;
  validation unaffected.
- `probe_move_drop.w`: child reports validate-all ok + drop-plan/trace
  verified; primary did not re-run (display/plan outputs, no finding
  attached) — recorded as child evidence.

## Verdict: clamps loud and display-only — no finding

- `local_count > 1024` (`:1088-1104`, primary-read): clamps only the debug
  dump loop and appends an explicit `... locals truncated (N more)` marker.
  Analysis/validation paths are untouched. Safe direction.
- Sibling clamps (bb>512, large-count guards, >256, >96) per child report
  all loud; primary read the 1024 representative and the pattern (clamp +
  marker) is uniform.
- Yield-intrinsic cross-check (for the MirSuspendCheck leg): the full
  `MirIntrinsic` enum read by primary — every fiber-suspending intrinsic is
  in the suspend-checker's closed set; `THREAD_SCOPE_JOIN_ALL` blocks the
  OS thread without yielding (rt/rt_core.w:4006-4025), so its absence is
  correct; raw `TK_YIELD` terminators are rejected upstream (`:48-49`).

## Notes (no finding)

- Child info-only notes (write-only `bb_is_cleanup`, zero in-file uses of
  `DropKind` enum) not independently re-checked; harmless either way.
