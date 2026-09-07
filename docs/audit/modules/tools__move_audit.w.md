# Primary verification — `tools/move_audit.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 290 lines (single complete read)

## Scope examined

Move-checker verdict matrix (compile-time analog of drop_audit):
shape preludes (`:73`: Drop shape `D` single-owner ground truth, Vec
shape copy-on-move pin with planned [FLIP:->ERR] comments `:220`),
scenario builders (`:97`–`:199`: before-loop+continue #696 shape,
before-loop plain, inside-continue, inside-fallthrough,
inside-then-reinit, inside-then-break, before-used-inside,
while-loop + loop{} #696 variants, divergent-branch #695),
`build_cells` (`:205`, 10 drop + 5 vec cells), runner (`classify`
`:246`: OK / MOVE-ERR on "moved"/"partial move" / OTHER-ERR; `main`
`:260`: vs-expected FAIL + candidate-vs-baseline DIFF). Header comment
(`:1`–`:40`) documents the #696 transfer-function divergence this tool
pins. No callers beyond `with build :move-audit`.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/tools_move_audit/check.txt`: `with check
  tools/move_audit.w` → ok (seed).
- `docs/audit/probes/tools_move_audit/noargs.txt`: `with run
  tools/move_audit.w` (no args) → usage line, exit 2. PASS.
- `docs/audit/probes/tools_move_audit/cell_before_loop_continue.txt`:
  hand-built `sc_before_loop_continue("drop")` expansion, `with check`
  → ok, rc=0 — the OK ground truth holds (no #696 false positive).
  PASS.
- `docs/audit/probes/tools_move_audit/cell_inside_fallthrough.txt`:
  hand-built `sc_inside_fallthrough("drop")` expansion, `with check` →
  `use of moved value` diagnostic, rc=1 — the MOVE-ERR ground truth
  holds and mentions "moved", matching `classify`'s matcher. PASS.
- `docs/audit/probes/tools_move_audit/full_run.txt`: full matrix with
  candidate = installed `with`, no baseline → `move-audit: 15 cells,
  0 vs-expected FAIL, 0 candidate-vs-baseline DIFF`, rc=0. Includes both
  [FLIPPED:#691] vec cells reporting MOVE-ERR as expected. PASS.

## Findings

None. In-report notes (not filed):
- Same candidate caveat as drop_audit: no baseline run, so the DIFF
  column is unexercised; vs-expected contract fully green.
- The stale header paragraph (`:32`–`:37`) still describes the vec
  shape as "copy-on-move TODAY (#607/A5)" while the cell expectations
  already carry the #691 single-owner flip — header and cells agree on
  the flip (cells authoritative, header notes the pin), so no
  contradiction, just a header that could state the flip as landed.
- T13: tool writes cells to fixed `/tmp/move-audit-cells` only.

Verdict: COMPLETE
