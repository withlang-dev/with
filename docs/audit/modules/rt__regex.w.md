# Primary verification — `rt/regex_runtime.w` + `lib/std/regex.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: regex_runtime `9f3c7fa9fc9124a32a34bb38e97655be088913dd0960d7cd5db8ab076f22cc7b`;
regex.w `9777fed996cbae99d83891d75150196f95ae84d33d1ca37f2124c47d98c18e11`
Source examined: child regex_runtime 1-297 + regex.w + corpus spots; primary:
shim `with_regex_compile` :80-112 + `with_regex_match_spans_alloc_at`
:136-175 (full reads), minimal repro + full-matrix re-runs below

## Scope examined

Compiler-side regex calling shim + user-facing regex facade.

Applicable overview targets examined: T15 (engine behavior via facade), T23
(silent falsehood vs loud panic).

## Behavioral matrix (all re-run by primary, seed stage1)

- `re_min.w` (primary): literal "a" vs "a" → `match-FALSE`, `find-NONE`, rc=0.
- `t15_core.w`: 13/19 FAIL (every positive fails; only negatives vacuously pass).
- `t15_groups.w`: 7/16 pass. `t15_replace_split.w`: `panic:
  with_regex_substitute(): heap limit exceeded`.
- Error paths work: bad pattern `(` → code 114; nest limits enforced
  (t23_failures 10/10 per child).

## REGEX-001 — match core universally false, replace panics (filed #1009, CRITICAL)

Classification: **Confirmed user-facing stdlib breakage; reported as #1009**
Severity: **Critical** — confidently-wrong results on every input + panic path
Confidence: **Very high on behavior** (matrix re-runs); **explicitly open on cell**

- Facade + shim both show the standard pcre2 sequence with no argument-shape
  error at this layer (primary reads). Compile half works (Ok + correct
  error codes); match/substitute execution fails.
- Fault localized BY ELIMINATION to the migrated corpus (`lib/std/re/*`)
  as baked into the binaries — consistent with surrounding churn (#955,
  #950). Exact cell TBD (needs lldb/fresh build, outside read-only protocol);
  filed as observable contract breach, not a guessed cell.
- Related, distinct: #980 (=~ /g state), #955 (bundle), #950 (heap flake).

## Notes

- The pcre2 corpus files themselves (`lib/std/re/*`, 35 migrated files) are
  separate checklist modules falling in a later wave; this leg covers the
  shim + facade + behavior only.
