# Audit: lib/std/cfg/stackify.w @ 450733e5

Mode: read-only source audit. Repo sources untouched; probes under /tmp/stackaudit (tidy, outside repo).
Module: 1006 lines. Generic Beyond-Relooper stackification over integer block/value IDs + explicit CFG edges; single entry `stackify_graph(graph) -> StackifyResult`.
In-repo caller: `src/CImport.w` `lower_goto_body_stackify` (line ~15800) builds the CFG via `set_br`/`set_cond_br`/return/unreachable only, calls `stackify_graph(move ctx.state.cfg.graph)` (~15853), emits via `stack_emit_tree`; irreducible rejection surfaces as loud migrate failure. Spec: `docs/with-migrate-spec.md:121,169,184-185,232,453-460,634-639`.

Targets traced: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.
No crypto/encoding claims in module — no independent-oracle check applicable.

## Probes (seed out/bootstrap/bin/with-stage1 run — all EXECUTED)

- P1 linear br+return: `PROBE1 OK roots=4 nodes=4` — EXECUTED, pass.
- P2a diamond cond_br merge: `DIAMOND OK roots=3 nodes=13` — EXECUTED, pass.
- P2b self-loop header: `LOOP OK roots=3 nodes=10` — EXECUTED, pass.
- P2c irreducible (0->1,0->2,1->2,2->1): `ERR stackify: irreducible control flow` — EXECUTED, pass (negative control, loud rejection per spec:232,460).
- P2d unterminated block: `ERR stackify: block has no terminator: 0 lonely` — EXECUTED, pass (negative control, validator stackify.w:345-355).
- P3 select (1 case + default): `SELECT OK roots=3 nodes=14`, node kinds include Select(5), Block(0), ParamTransfer(6), Br(3), Leaf(2), Return(7) — EXECUTED, pass.
- In-repo coverage: `test/behavior/behav_std_cfg_stackify.w` (125 lines, exists) covers straight-line, diamond, natural loop, select-targets param transfer, irreducible rejection; ran `with-stage1 test` — `ok: 1 test passed` — EXECUTED, pass. My probes independently agree with its assertions.

## Findings

No defects surviving refutation. Numbered notes below are observations, not findings of defect.

1. (OBSV, T22) `CiStmtPool.node` stack emitter (`src/CImport.w` ~15486-15552) has arms for Leaf/Block/Loop/Br/If/ParamTransfer/Return/Unreachable but no `Select` arm — a Select-bearing tree would fail with "unsupported stackify node". REFUTED as live defect: the goto CFG builder only emits Br/CondBr/Return/Unreachable (`src/CImport.w:14790,14801` + `block_has_term` 14743 admits Select but nothing constructs one on the goto path); both emitters explicitly reject Select (`stack_emit` unsupported-node, native emitter 15686 "select terminator is not supported"). Select entry points (`set_select`, `set_select_targets`, `add_branch_target`) are exercised only by the behavior test, not by the migrator. Latent dead-API gap only; no caller impact at this commit.
2. (OBSV, T13) Ownership/drop clean: `stackify_graph` takes graph by value and moves it into `StackifyContext` (stackify.w:990-994); caller moves (`move ctx.state.cfg.graph`); internal `&Vec`/`&StackifyGraph` borrows and `move node/tree/message` transfers compiled warning-free under stage1 in all probes. No use-after-move, no missing-drop pattern observed.
3. (OBSV, T15) Migration fidelity: structured lowering matches spec pipeline (spec:184-185 blocks->labeled blocks, loops->while-labeled confirmed against emitter `block_labeled`/`while_labeled` arms); irreducible loudly rejected, not silently miscompiled (P2c + behavior test). Hoisting/param-transfer arity enforced on both sides (stackify `ParamTransfer` nodes carry from/to counts; emitter fails on arity mismatch 15486). No fidelity defect.

## Verdict

Verdict: COMPLETE — no defect findings; diamond/loop/select/irreducible/unterminated probes executed and conforming, in-repo behavior test exists and passes, Select-emitter gap refuted vs in-repo callers.
