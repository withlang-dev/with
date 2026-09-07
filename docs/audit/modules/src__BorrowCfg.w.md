# Primary verification — `src/BorrowCfg.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `a57c723e65ce80044d83877f756f98d20e2fdbbbb9a23c695b7e81428d68f47d`
Source examined: all 285 lines (primary read 1-135, 136-160, 160-285 — complete)

## Scope examined

CFG scaffolding for future borrow analyses: `CfgGraph`/`CfgNode`/`CfgEdge`
types (`:35-66`), accessors (`:83-131`), `build_cfg` + builders for
block/if/while/do-while/loop/return/break/goto (`:136-285`).

Applicable overview targets examined: 6 (borrow provenance — correctly
absent here), 13 (AST layout contract adherence), 23 (honesty of
scaffolding vs silent stub).

## Verdict: stub-by-design, openly documented — no defect

- The header (`:1-29`) explicitly states NLL is NOT implemented via this
  CFG, names the real enforcement (`Sema.expire_dead_borrows_in_block` in
  SemaCheck.w — confirmed present at SemaCheck.w:23165), lists uncovered
  shapes, and admits match/for are unbuilt. Model honesty: the file says
  what it is.
- Primary confirmed zero consumers: `grep CfgGraph|build_cfg` outside
  `src/BorrowCfg.w` returns nothing (the `add_node` hits are all
  `AstPool.add_node`; the `use BorrowCfg` lines in Sema.w:9 and
  SemaCheck.w:5 are dead imports with no calls).
- Child's Sema-behavior probes (`borrowcfg_view_conflict.w` fails loudly,
  `_neg` passes, branch/move probes behave) corroborate that enforcement
  lives Sema-side and works. No primary re-run needed: the probes pin
  SemaCheck behavior, which is that module's leg, not this one's.

## Notes (for whoever wires it — not findings)

- `build_block`/`build_if`/`build_while` AST layouts match the AGENTS.md
  layout table (BLOCK d0=extra_start d1=stmt_count d2=tail; IF d0=cond
  d1=then d2=else; WHILE d0=cond d1=body). Correct against current AST.
- `build_if` and `build_while` never build the CONDITION expression into
  the graph (cond indices read but unused, `:226-236`, `:246-254`).
  Conditions can carry borrows/method calls; a future loop-aware analysis
  built on this CFG would inherit the blindness. Flagged now so the wiring
  diff adds conditions — same bug class as #999 (unhandled operand kinds).
- `out_degree`/`has_edge` are O(E) scans — fine for scaffolding scale.
