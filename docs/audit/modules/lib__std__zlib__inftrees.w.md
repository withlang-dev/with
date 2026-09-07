# Primary verification — `lib/std/zlib/inftrees.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 455 lines (single complete read)

## Scope examined

`inflate_table` (`:16`): code-length counting, root/max/min resolution,
over-subscribed reject (`:153`–`:165`, returns -1), incomplete-set reject
(`:168`–`:186`), offset/sort fill, per-type base/extra selection
(CODES/LENS/DISTS, `:217`–`:240`), table-size caps 852/592
(`:260`–`:284`, `:383`–`:408`, return 1), canonical-code fill loop, and
sub-table linkage. `inflate_fixed` (`:443`) wiring `lenfix` (`:454`,
512 entries) / `distfix` (`:455`, 32 entries). Deps: `defs` (`code`
type), `adler32`/`crc32` (linked but unused here — migrator-carried
`use` lines). Callers: `inflate.w` (`:2522` CODES, `:3077` LENS,
`:3094` DISTS), `infback.w` (`:1012`,`:1686`,`:1703`); `inflate_fixed`
called from `inflate.w:1969`, `infback.w:345`.

## Behavioral matrix (EXECUTED vs HELD)

- `docs/audit/probes/zlib_inftrees/main.w` — two distinct level-9/level-6
  dynamic-Huffman streams plus one `Z_FIXED` stream, all compressed by
  CPython `zlib` (independent oracle); every decode byte-exact
  (272-B, 703-B dynamic cases; 360-B fixed case). Dynamic decode
  exercises the full table builder incl. length-repeat codes 16/17/18
  handling and the `lens[256] != 0` end-of-block guard. ALL-PASS.
  EXECUTED.
- Fixed tables `lenfix`/`distfix`: contents verified transitively —
  fixed-Huffman decode is byte-exact against the oracle, which is only
  possible with correct tables. EXECUTED (transitive).
- `with check lib/std/zlib.w` (whole-package graph incl. this module) →
  exit 0. EXECUTED.
- Over-subscribed / incomplete / oversize-table reject arms: read and
  match canonical conditions; no crafted invalid-table fixture executed.
  HELD.

Caveat: `run` probes link the stage1-embedded stdlib copy; working-tree
sources verified by full read plus the check above.

## Findings

One observation, refuted as a defect (not filed):
- `with check lib/std/zlib/inftrees.w` (standalone, stage1) fails with
  `error: shadowing is not allowed for 'lenfix'` (`:454`) and the same
  for `'distfix'` (`:455`), exit 1. Refutation: (a) no other file in
  `lib/std/zlib/` defines `lenfix`/`distfix` (repo-wide grep confirms a
  single definition site each); (b) the module sits in a `use` cycle
  (`inftrees` ↔ `inflate`/`infback`/…), so a single-file check re-imports
  its own top-levels through the cycle — a check-harness scoping
  artifact, not a source duplication; (c) the whole-package
  `with check lib/std/zlib.w` exits 0, proving the package compiles as
  built; (d) runtime fixed-table decode is byte-exact, proving the
  tables' contents. No source change indicated (and none permitted in
  this audit).

Verdict: COMPLETE
