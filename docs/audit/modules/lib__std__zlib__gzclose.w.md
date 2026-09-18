# Primary verification — `lib/std/zlib/gzclose.w`

Status: **INCOMPLETE** (read-dispatch verified; write-dispatch blocked by gzwrite F1; not filed)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 35 lines (single complete read).

## Scope examined

Pure dispatcher `gzclose` (`:15`): null → -2; `mode == 7247` → `gzclose_r`
(read side, `gzread.w`) else `gzclose_w` (write side, `gzwrite.w:440`).
Callers: `minigzip.w` (`gz_compress`, `gz_uncompress`, `file_uncompress`),
`example.w:test_gzio`, any user code closing a `gzFile`. No logic of its own
beyond the branch.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `with check lib/std/zlib/gzclose.w` → rc=0 (ok; log at
  `docs/audit/probes/zlib_gzclose/check.log`).
- EXECUTED `docs/audit/probes/zlib_gzclose/probe.w` (rc=0,
  `probe-gzclose-done`): python-generated `in_py.gz` (64-B gzip member) →
  `gzopen(rb)` → `gzread` 64/64 → `fwrite` → `gzclose` (read-dispatch
  branch). Independent oracle: `out_back.bin` byte-exact vs the 64-B pattern
  (`gzclose_back: 64 OK`). Read-dispatch + `gzclose_r` close path verified.
- HELD: `gzclose_w` direct call and the write-dispatch branch — the only
  executable path (`zlib_gzwrite/probe.w`) segfaults before any close (see
  gzwrite report F1), so no write-side close has ever executed in this audit.

## Findings

None filed. In-report notes (not filed):
- The 20-line dispatcher is fully read and type-clean; the INCOMPLETE is
  coverage-only (write branch), inherited from F1, not a second defect.
- Same embedded-engine caveat as deflate report (probe links seed std).

Verdict: INCOMPLETE
