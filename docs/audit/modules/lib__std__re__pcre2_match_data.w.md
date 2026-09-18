# Primary verification — `lib/std/re/pcre2_match_data.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 331 lines (single complete read).

## Scope examined

`pcre2_match_data_create_8` (`:32-128`): `oveccount 0→1` clamp (PCRE2
requires ≥1 pair), exact `with_alloc` sizing for the ~1 MB frame,
subject/startchar/mark/flags init, null-context→-51-style null return.
`create_from_pattern` (`:129-174`): null-code→null, else top-bracket
sizing. `free` (`:175-188`): null-safe. Getters (`:189-331`):
ovector-count/pointer/size/startchar/mark/heapframes-size — all
null-safe (`-51`/null/0).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r7_context_newline.w` (`output_r7.txt`):
  `md0count=1` (0→1 clamp), `md1count=5`, `md1size=200`,
  `mdnull=1` (null code → null), `mdheap=0 startchar=0 marknull=1`,
  `ovecptr=1`. PASS.
- Indirect: `r3`/`r4`/`r5`/`r6`/`r8`/`r9` create, match, read ovector,
  and free match-data blocks on every case (all exit 0, spans exact).
- `with-stage1 check lib/std/re/pcre2_match_data.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
