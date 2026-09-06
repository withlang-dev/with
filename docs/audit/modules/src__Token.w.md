# Primary verification — `src/Token.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `be3461506f59b673fed82fa49287d53ad585fb0cd1bca6fc85cd1966808c41c8`
Source examined: child 1-408 complete; primary: `TK_KW_THEN` refs (grep),
`tag_name` tail :355-360, keyword-map head :167-170, `t10_then`/`t10_compound_eq`/
`t13_trivia_eof` probe re-runs (all rc=0, compound-assign checks clean)

## Scope examined

Token-kind identity, keyword mapping, diagnostic naming, token-stream contract.

Applicable overview targets examined: T10 (identity), T13 (parser contract),
T24 (kind-list drift).

## Verdict: two cosmetic notes, no filing

- Dead kind `TK_KW_THEN` (=18, `:32`): no `"then"` branch in
  `tag_from_keyword` (grep-verified zero hits), sole producer never emits
  it, `then` lexes as identifier (probe), Fmt.w:407/428 guards dead.
  Harmless dead code — note, not a defect (no behavior).
- `tag_name` falls through to `"unknown"` for 11 compound-assign kinds
  (`TK_AMP_EQ` et al, `:359`): parsing unaffected (probe checks clean),
  only diagnostic naming degraded. Cosmetic — note, not filed.

## Notes

- Parallel tags/starts/ends arrays + NEWLINE-preserved/comments-dropped
  contract corroborated by the passing trivia/EOF probe.
