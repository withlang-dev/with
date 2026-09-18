# Primary verification — `src/CImport.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `0468d164f10bd2d20723a1baa199c7ccfefae3d61afe2ab4b7927a22678a4426`
Source examined: child broad coverage (targeted full reads 1-800, 2803-3126,
5092-5421, 11900-12020, 15575-15620 + fn/UNSUPPORTED census + ClangBridge
700-937); primary: all-probe re-runs below + #977 dup confirmation

## Scope examined

C header translation: scalar maps, bitfields, macros, VLAs, variadics, failures.

Applicable overview targets examined: T7/T11 (ABI fidelity), T13 (coverage),
T23 (silent mistranslation), T24 (ClangBridge overlap).

## Behavioral matrix

All 8 probes in `docs/audit/probes/cimport/` re-run by primary (`check` rc):
bitfield-ok 0 / bitfield-use-fail 1 / ld-size 0 / macro-run 0 /
paste-use-fail 1 / variadic-unsafe-fail 1 / vla-check 0 / vla-use-fail 1.
Supported constructs translate; unsupported ones fail loudly. No silent
mistranslation demonstrated on the probed surface.

## Verdict: no new filing — known gaps are #977 verbatim

- `c_longdouble=f64` (:640), `c_long=i64`, `c_char=i8` platform invariance =
  open #977 (title matches exactly). Dupe, no filing.
- Child's T24 observation (`ci_map_c_type` region) recorded as child
  evidence; no behavioral divergence attached.

## Notes

- The unsupported-construct failures (VLA use, paste, variadic-unsafe,
  bitfield-use) are all loud rc=1 — the translator honors No Silent
  Fallbacks on its probed boundary.
