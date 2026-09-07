# Primary verification — `lib/std/zlib/trees.w`

Status: **COMPLETE** (no defects; check-as-root anomaly documented, not filed)
Primary verifier: primary (partial source read + full API inventory + probe execution)
Source revision: `450733e5`
Source examined: 2022 lines; deep read lines 1–500 (`_tr_init`, `_tr_tally`,
`_tr_flush_block` incl. fixed/dynamic/stored selection, `_tr_align`,
`_tr_stored_block`, `bi_reverse/flush/windup`) + complete fn inventory via
grep (6 pub `_tr_*`, 13 priv incl. `build_tree`, `send_tree`,
`compress_block`, `detect_data_type`). Remainder HELD.

## Scope examined

Huffman/codec core: `_tr_init` (`:17`), `_tr_tally` (`:42`),
`_tr_flush_block` (`:92`), `_tr_flush_bits` (`:239`), `_tr_align` (`:244`),
`_tr_stored_block` (`:321`); priv `gen_codes`, `tr_static_init`,
`init_block`, `pqdownheap`, `gen_bitlen`, `build_tree`, `scan_tree`,
`send_tree`, `build_bl_tree`, `send_all_trees`, `compress_block`,
`detect_data_type`. No external callers (grep: referenced only from
`deflate.w` engines) — there is no standalone runnable surface by design.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED through `docs/audit/probes/zlib_deflate/probe.w` (rc=0; all 13
  outputs python-oracle OK, see deflate report): level 0 exercises
  `deflate_stored` → `_tr_stored_block`; levels 1/6/9 exercise
  fast/slow matchers → `_tr_tally` → `_tr_flush_block`, with repetitive input
  taking the dynamic-tree path (`send_all_trees`/`compress_block`) and
  incompressible input exercising the stored-fallback comparison. Every path's
  output is a valid stream per the independent oracle (byte-exact
  `zlib.decompress`). This is the only executable coverage possible — the
  module has no public entry point of its own.
- EXECUTED `with check lib/std/zlib/trees.w` → rc=1: single error of the same
  class as deflate (`static_bl_desc`, `:2022`); log at
  `docs/audit/probes/zlib_trees/check.log`. Same refutation (root-mode artifact,
  runtime bytes correct).
- HELD: direct unit-level invocation (no surface exists); lines 501–2022 not
  deep-read.

## Findings

None. In-report notes (not filed):
- Same embedded-vs-worksource caveat as deflate report (probes execute the
  seed's embedded engine; transfer evidence identical).
- T13-style: no heap/Drop of its own; operates on caller-owned
  `internal_state` places.

Verdict: COMPLETE
