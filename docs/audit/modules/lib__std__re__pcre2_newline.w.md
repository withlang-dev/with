# Primary verification — `lib/std/re/pcre2_newline.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 232 lines (single complete read).

## Scope examined

`_pcre2_is_newline_8` (`:32-124`): type 2 (ANYCRLF) fast path — CR only
with LF-follow (len 2) else len 1, LF len 1; full path — LF/VT/FF/CR len
1, NEL (133, len 1 or 2 by UTF mode), U+2028/2029 (len 3, UTF-gated).
`_pcre2_was_newline_8` (`:125-232`): backward scan with the same table,
CR-before-LF double-step, startptr floor.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r7_context_newline.w` (`output_r7.txt`,
  sequenced reads — no same-expression `&ln`/value mixing):
  `is-crlf-t2=1 len=2 is-lf-t2=1 len=1`,
  `is-nel-any=1 len=2 is-nel-t2=0` (CR-only type rejects NEL),
  `is-lf-fixed=1 len=1`,
  `was-crlf=1 len=2 was-lf=1 len=1`. All match PCRE2 newline semantics.
  PASS.
- `with-stage1 check lib/std/re/pcre2_newline.w` → `ok` (exit 0).

## Findings

None. In-report notes (not filed):
- An earlier probe revision printed `len` from the same `printf` call as
  the `&ln` write; argument order made it stale. Re-sequenced before
  recording — module was correct throughout.

Verdict: COMPLETE
