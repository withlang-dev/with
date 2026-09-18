# Primary verification — `lib/std/zlib/infback.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 2978 lines (two complete reads: 1–1500, 1501–2978)

## Scope examined

`inflateBack` (`:17`): callback-driven raw-deflate decoder — block-type
dispatch (stored `:46`, fixed via `inflate_fixed` `:345`, dynamic via
`inflate_table` `:1012 CODES / :1686 LENS / :1703 DISTS`, `:1686`+), pull
model (`in_` callback with null/BUF_ERROR suspend, `:278`–`:306 and
repeats), push model (`out_` callback with window flush, `:631`–`:640
and repeats), slow literal/match path plus `inflate_fast` shortcut
(`:1759`–`:1798`, `whave` bookkeeping `:1761`–`:1770`), match copy with
`too far back` guard (`:2644`–`:2648`), DONE/BAD/NEED-MORE exits
(`:2772`–`:2852`). `inflateBackEnd` (`:2858`), `inflateBackInit_`
(`:2888`, windowBits 8–15 validation, caller window wiring,
`sane = 1`). Deps: `defs`, `inftrees`, `inffast`. Callers: none in repo
— no `inflateBack*` call sites outside this file (only `use` lines);
unreachable from the safe `std.zlib` facade.

## Behavioral matrix (EXECUTED vs HELD)

- `docs/audit/probes/zlib_infback/main.w` — `inflateBackInit_(15)` with a
  caller 32 KiB window returns 0 and `inflateBackEnd` returns 0.
  ALL-PASS. EXECUTED.
- `with check lib/std/zlib/infback.w` → exit 0 (stage1). EXECUTED.
- `inflateBack()` decode path (the ~2800-line state machine): HELD —
  not executed. Justification: zero in-repo callers, and driving it
  requires `extern "C"` pull/push callbacks with no harness in tree;
  the shared sub-paths it depends on (`inflate_table` builds,
  `inflate_fixed` tables, `inflate_fast` copy loops) are each EXECUTED
  via the inftrees/inffast probes above. Read-only review found the
  callback suspend/resume accounting (`have/left/hold/bits` save and
  `next_in/avail_in` writeback at `:2839`–`:2842`) consistent with the
  canonical implementation.

Caveat: `run` probes link the stage1-embedded stdlib copy; working-tree
sources verified by full read plus the check above.

## Findings

None. In-report notes (not filed):
- Coverage gap is structural (callback API, no callers), not a defect:
  any future caller should add a callback-harness probe driving stored,
  fixed, and dynamic streams through `inflateBack` before relying on it.

Verdict: COMPLETE
