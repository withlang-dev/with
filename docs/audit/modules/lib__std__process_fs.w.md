# Primary verification — `lib/std/process.w` + `lib/std/fs.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: process `e047c8de06f964c4a082c48a7dd68525650a87de6132ca0a441a263325e6896e`;
fs `7941b1b0d443d780bfa3226eb832db05c785da92b9a6ce17e0d2161d756e29e0`
Source examined: child both complete; primary: fs :20-70 + process :40-90
(full read of the finding-implicated regions), plus full probe re-runs below

## Scope examined

Process/FS foundation: env, argv, exec, file/dir tree ops.

Applicable overview targets examined: T10 (surface honesty), T15
(foundations), T23 (error propagation).

## Behavioral matrix

Both probes in `docs/audit/probes/std_io/` re-run by primary, all rc=0:
- `fs_probe`: write/read roundtrip, missing-read len 0, exists true/false,
  bad-write rc=-2, missing-list len 0, mkdir_p/tree/list/copy/rename/real +
  missing (-2 throughout), cleanup. Errors propagate as negative errno, no
  swallowing observed.
- `process_probe`: pid positive, argc/argv, missing-env len 0,
  set/get roundtrip, empty-vs-unset identical, `true`→0/`false`→1/exit42→42/
  nonexistent→127, Command run/status parity incl. exit 7.

## Verdict: no filing — three doc notes

- `run`/`status` byte-identical bodies with near-identical docs (process.w:83
  vs :86): surface bloat, cosmetic.
- fs fns document "0 on success" without naming nonzero=-errno (observed -2
  ENOENT throughout): behavior correct, docs thin. Doc gap, not a defect.
- `env()`'s `with_str_len` normalization branch (:44-46) is a value no-op
  ("" → ""): defensive, harmless.

## Notes

- Exit-code fidelity (42, 7, 127) and errno fidelity (-2) both verified by
  execution — the foundations report truthfully.
