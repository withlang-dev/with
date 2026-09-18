# Primary verification — `lib/std/re/pcre2_error.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 381 lines (single complete read).

## Scope examined

`compile_error_texts` (`:33-252`, 167 entries: first `"no error"`, index
`enumber-100`, entries with embedded format args), `match_error_texts`
(`:253-335`, 72 entries: first `"no error"`, direct-index for negatives,
`"unknown error number"` fallback), `pcre2_get_error_message_8`
(`:336-381`): null→-51, zero-size→-48, ≥100→`n-100` arm with
`sizeof(t)/8` guard→-59 overlong, negatives→`-enumber` arm with
`sizeof/8` guard→-59, `strncpy`+NUL, truncated buffer → still copies
`bufflen-1` bytes but returns -48, else byte count.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r1_misc.w` (`output_r1.txt`), oracle
  `pcre2test -error 101,-1,-48,-45,-68,-34`:
  `err 101 rc=19 msg=\ at end of pattern`,
  `err -1 rc=8 msg=no match`,
  `err -48 rc=14 msg=no more memory`,
  `err -45 rc=14 msg=bad JIT option`,
  `err -68 rc=44 msg=feature is not supported by the JIT compiler`,
  `err -34 rc=16 msg=bad option value` — all six strings byte-identical
  to the C library; `trunc rc=-48 msg=no ` (4-byte buffer: partial copy
  + NOMEMORY, per C), `zerosize rc=-48`. PASS.
- `with-stage1 check lib/std/re/pcre2_error.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
