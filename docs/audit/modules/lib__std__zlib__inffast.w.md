# Primary verification — `lib/std/zlib/inffast.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 785 lines (single complete read)

## Scope examined

`inflate_fast` (`:17`) in full: register-style locals, state load
(`'__ci_bb_0`, `:141`–`:158`: `in/last/out/beg/end`, window
`wsize/whave/wnext`, `hold/bits`, `lcode/dcode` + masks), NEEDBITS loop
(`'__ci_bb_1/4`), literal/length/decode dispatch (`'__ci_bb_5`–`:11`,
`'__ci_bb_77/78` end-of-block vs invalid-literal routing), length+extra
(`'__ci_bb_10/13`–`:16`), distance+extra decode (`'__ci_bb_18`–`:24`),
window-vs-output distance resolution incl. `sane`-gated "too far back"
(`'__ci_bb_27`–`:43`), and the unrolled 3-byte copy loops (`'__ci_bb_60`–
`:73`). Deps: `std.zlib.defs`, `inftrees` (tables only). Callers:
`inflate.w:3170` (guarded by `have >= 6 && left >= 258`),
`infback.w:1774`. No other callers; no test files target it directly.

## Behavioral matrix (EXECUTED vs HELD)

- `docs/audit/probes/zlib_inffast/main.w` — 46056-byte mixed-content stream
  (runs of `ABCDEFGH`/`0123456789`, repeated sentence, full 0–255 binary
  range) compressed by CPython `zlib` level 9 (independent oracle);
  `decompress()` unwraps (unwrap success implies the engine's internal
  adler32 trailer check passed) with exact length and 5/5 spot bytes
  (offsets 0, 1, 7, N-8, N-1). Buffer sizes guarantee the
  `have >= 6 && left >= 258` fast-path gate is taken. ALL-PASS.
  EXECUTED.
- `with check lib/std/zlib/inffast.w` → exit 0 (stage1). EXECUTED.
- Distance-too-far-back error arm (`sane != 0` → `msg` + BAD mode):
  reads correctly against the canonical logic; no crafted fixture reaches
  it (would require a corrupt-distance stream the facade rejects
  earlier). HELD.

Caveat: `run` probes link the stage1-embedded stdlib copy; working-tree
sources verified by full read plus the check above.

## Findings

None. In-report notes (not filed):
- The `sane` flag defaults to 1 (`inflateResetKeep`), so over-long
  distances are loud errors by default; `inflateUndermine` is the only
  mutator and none of the in-repo callers invoke it.

Verdict: COMPLETE
