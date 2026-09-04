# Primary verification — `lib/std/re/pcre2_match_next.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 154 lines (single complete read).

## Scope examined

Entire module: `pcre2_next_match_8` (`:32`, pub — global-match
continuation: returns 0 (done) or 1 (call `pcre2_match_8` again with
`*pstart_offset`/`*poptions`)) and `do_bumpalong` (`:91` — CRLF-aware
and UTF-aware start advance). The `loop { 0; if not ((0 != 0)) {
break } }` at `:43–48` is the migrated C `do {} while (0)`.
Logic read in full: empty-match-at-end terminates (`:70–81` sets
`NOTEMPTY_ATSTART` (8) / plain advance); the `:52–67` arm re-runs
bumpalong when the previous match was zero-width at the start
offset. No defects spotted; semantics match the PCRE2 global-loop
contract used by `pcre2test /g`.

## Upstream fidelity tracking

Same as the engine audit: PCRE2 10.47 pin (`build.w:2865`,
sha `build/pcre2.w:8`), `:pcre2-test` RunTest lane, `wo-drift`.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_engines/dfa_next_matrix.w` (`run_global`,
  canonical match → `pcre2_next_match_8` → match loop, 20-iteration
  guard, never tripped):
  - `\w+` on `hi there` → `[0,2)`, `[3,8)`, then terminal NOMATCH
    (normal exhaustion) — identical to `pcre2test /g`.
  - `a*` on `aa` → `[0,2)`, `[2,2)` (empty-match advancement at end
    of subject, then clean stop) — identical to `pcre2test /g`.
  - `x?` on `ab` → `[0,0)`, `[1,1)`, `[2,2)` — identical to
    `pcre2test /g`.
- Oracle: system pcre2test 10.47 `/g` runs, compared by match
  sequence; all three agree exactly.

## Findings

None.

Verdict: COMPLETE
