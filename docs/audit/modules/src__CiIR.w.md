# Audit: src/CiIR.w @ 450733e5 — verdict INCOMPLETE (3 findings, all low severity)

- Commit: 450733e58a1a7cce14f9cb2084943fc178815111 (matches request 450733e5)
- Module: 950 lines. SoA IR pools (CiType/CiExpr/CiStmt/CiDecl) + CiModule/CiProject for `with migrate`.
- Consumers in-repo: `src/CiPrint.w` (`use CiIR`), `src/CImport.w` (`use CiIR`, live `set_type` caller + pool `deinit` sites), `src/CiMigrate.w`, `tools/debug_sema_layout.w`, `src/main.w` roundtrip harness comment.
- Scope: T13 ownership/drop, T15 migration fidelity, T22 spec conformance. READ ONLY — no sources modified.

## Findings

### 1. `src/CiIR.w:451` — CIS_DO_WHILE comment omits d2 (cond_setup); constructor + printer agree — severity: low — target: T22 — probe: EXECUTED
- Enum comment documents `CIS_DO_WHILE` as `d0 = body_block, d1 = cond_expr` only.
- Constructor `do_while_stmt` (`src/CiIR.w:614-615`) stores a third slot: `d2 = cond_setup`.
- Printer honors d2 in both paths (`src/CiPrint.w:304-316` compact, `src/CiPrint.w:907-919` pretty) including `cond_setup != 0` guard.
- Refutation attempt: no behavioral/fidelity loss — producer and consumer agree; stale comment only. Fix: document `d2 = cond_setup (0 if none)` at line 451.

### 2. `src/CiIR.w:456` — CIS_VAR_DECL comment says "flags in extra"; flags live in flags column — severity: low — target: T22 — probe: EXECUTED
- Comment: `CIS_VAR_DECL ...; flags in extra`.
- Constructor `var_decl` (`src/CiIR.w:618-624`) packs `is_mut/has_init` into `f` and passes it as the `flags` arg to `add` (flags column), never touching `extra`.
- Printer reads `stmts.get_flags(id)` (`src/CiPrint.w:324-328`, `src/CiPrint.w:1001-1005`, `823-831`).
- Refutation attempt: producer/consumer agree; comment is stale. Fix: change comment to "flags in flags column (bit0=is_mut, bit1=has_init)".

### 3. `src/CiIR.w:384-398` — `CiExprPool.set_type` rebuilds the whole types vec per call (O(n) + fresh allocation); live caller — severity: low — target: T13 — probe: HELD (reason below)
- Implementation copies all `n` entries into a new `Vec` and overwrites `st.types`; live caller `src/CImport.w:6665` (`self.set_type(value_id, ty_id)`).
- Indisputable part: O(n) time + O(n) allocation churn per single type patch (a direct indexed store would be O(1)).
- Conditional part (NOT claimed as fact): whether the overwritten `st.types` backing buffer is released depends on `Vec` field-reassignment drop semantics, which was not confirmed within this audit's probe budget — hence probe HELD for the leak half, EXECUTED (code-read + caller grep) for the complexity half.
- Refutation attempt: caller is live, so the path is reachable; no counterexample found. Suggested fix: add an indexed `types.set(idx, value)` primitive instead of rebuild-and-replace.

## Probes run
- `out/bootstrap/bin/with-stage1 check src/CiIR.w` — EXECUTED, fails standalone with `undefined variable i64_to_string` at `src/CiIR.w:861:25` and `src/CiIR.w:877:51` (help suggests `i64.to_string`). NOT reported as a finding: compiler modules are not standalone-checkable (prelude/build wiring via `build.w`); without a full-build probe this reads as a harness artifact, not a module defect.
- Caller/counterexample greps over `src`, `tools` — EXECUTED: `CiPrint.w` reads DO_WHILE d2 and VAR_DECL flags (kills behavioral readings of findings 1–2); `CImport.w:6665` live `set_type` caller; `CImport.w` deinits type/expr/stmt pools at multiple sites (8763+, 11175+, 14260+).
- Negative controls (checked, not claimed): `CiDeclPool.deinit` has no observed call sites in the greps above — insufficient context to claim a leak (decl pools may be intentionally transferred); `Vec[str]` deinits free only the backing buffer — same idiom needs comparison against `src/Ast.w` before any claim; null-sentinel failure mode for unsupported constructs (header lines 24–25) needs caller handling review in `CImport.w`/`CiMigrate.w` — deferred, not claimed.

## Verdict
INCOMPLETE — 3 numbered findings above (2 doc-only T22 lows, 1 T13 perf low with HELD leak half). No ownership soundness, migration-fidelity, or spec-conformance defect with behavioral impact was confirmed.
