# Primary verification — `src/Lexer.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `3e595d6f5004ba6c5e919f55dd40c88f6da5254382175686034446b0594044b7`
Source examined: child 1-856 complete (two reads); primary: string scanners
:429-460 + raw-string driver :781 (full read), regex-vs-block-comment
:351-352, keyword table :702-705, number bases :469-485, plus probe re-runs below

## Scope examined

Token identity, literal scanning, error spans, recovery behavior.

Applicable overview targets examined: T10 (identity), T18 (error spans),
T23 (silent recovery).

## Behavioral matrix

Probes in `docs/audit/probes/lexer/` re-run by primary: `p10_identity.w` runs
`T10-OK` rc=0 (keywords case-sensitive, bases, floats, ranges, strings,
comments, labels); `c_block.w` (`/* x */`) checks rc=1 loud ("expected
declaration" — confusing shape, not silent); `swallow_code.w`
(primary-authored): string swallowing code to the next quote errors rc=1
pointing at the remnant, not the open quote (misdirected but loud).

## LEX-001 — unterminated string at EOF silently accepted (filed #1005)

Classification: **Confirmed silent acceptance; reported as #1005**
Severity: **Low** — only literal-at-EOF slips through; anything following
produces a loud (if mispointed) error
Confidence: **Very high** (scan read + hexdump-verified probe + rc=0)

`lex_string` returns bare `TK_STRING_LIT` on EOF (`:459`; multi-line `:448`;
raw `:781`) with no diagnostic, despite "for parser recovery" comments —
and no recovery exists downstream. Multi-line strings are legal (scan
doesn't stop at newline), so the only fully-silent shape is EOF termination.

## Notes (no finding)

- `/* x */` lexes as regex-open (no block-comment branch): downstream fails
  loud. A `/*`-comment feature request, not a defect — recorded, not filed.
- `/` operator-vs-regex disambiguation is positional by design; identity
  matrix passes.
