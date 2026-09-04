# Audit: src/TypeLayout.w @ 450733e5

Scope: full module read (452 lines). Targets: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.
Seed compiler: out/bootstrap/bin/with-stage1.

## Summary
Pure layout-query module: align_up, int_bytes, struct/union/enum/tuple/array/range/slice size+align, generic-inst paths, D7 frozen read twins. No allocation, no ownership transfer, no drop glue. All miss paths are loud (`sema_phase_bug`) with memory-safe fallbacks (size 0, align 1, no-drop 0).

## T13 ownership/drop — conforms
- No `drop`, no owner passing, no heap alloc in module. Nothing to leak/double-free.
- Frozen defaults are the safe choices: `type_needs_drop_frozen` miss -> 0 (leak, never spurious drop) (src/TypeLayout.w:429); `is_copy_frozen` miss -> 0 (src/TypeLayout.w:419); size miss -> 0, align miss -> 1 (src/TypeLayout.w:403,409). Verified by read.

## T15 migration fidelity — conforms
- Generic field-type path saves/restores `generic_subst_param_syms/type_ids` around substitution (src/TypeLayout.w:52-66); both early-return paths return before save, single restore point covers both setup branches. No subst-stack leak.
- `type_layout_struct_field_align` honors explicit align override slot (src/TypeLayout.w:86-90); generic twin resolves via `align_of(field_tid)` (src/TypeLayout.w:69-71). Apparent asymmetry considered as candidate defect and REFUTED: generic field types are resolved through substitution (`resolve_generic_return_type_node` / `type_extra` base entry) rather than the monomorphized `type_extra` row that carries the explicit-align slot, and all in-repo layout callers funnel through `type_layout_align_of/size_of` (callers in Sema.w, MirLower.w, Codegen.w, CodegenDispatch.w, CodegenTraits.w, Analysis.w, SemaCheck.w, SemaDecl.w, ComptimeEval.w, BundleInterfaceEmit.w) so no caller reads the explicit slot for a generic inst directly. No exact file:line defect survives.
- `type_layout_int_bytes` edge mapping (bits<=0 -> 4, bytes<=0 -> 1) matches int/float align+size twins (src/TypeLayout.w:12-18,299-302,348-351). No fidelity break.

## T22 spec conformance — conforms
- Struct: field offsets via align_up loop, size padded to max align (src/TypeLayout.w:93-118,154-218); union: max(size) aligned to max align, empty -> 1 (src/TypeLayout.w:161-174,194-208); distinct-type passthrough (src/TypeLayout.w:141-143,189-191); empty struct size 0 vs empty union 1 — matches coded spec, no counterexample in callers.
- Enum: tag + max payload, aligned to tag/repr align (src/TypeLayout.w:234-292); generic-enum fallback 0/4 paths mirror query's own not-found returns (src/TypeLayout.w:236-242).
- Tuple/range/array/slice/ptr/fn sizes+aligns standard (src/TypeLayout.w:294-398).

## Probes
- P1 (EXECUTED): `with-stage1 --help` lists build/run/check/test/bench/fmt/doc/repl/lsp/migrate — compiler live.
- P2 (EXECUTED, negative control): hand-written `/tmp/typelayout_probe.w` with `struct Pair:` rejected at parse (`expected declaration`) — confirms `struct` is not surface syntax in this revision, probe invalid rather than layout failure; no layout claim drawn from it.
- P3 (HELD): end-to-end struct-offset golden probe held — surface struct-decl syntax not rediscovered within batch budget; layout paths instead verified by full read + caller fan-in (11 files reference `type_layout_*`). Reason: syntax discovery would exceed batch budget.
- Negative control: tid==0 returns (align 1 / size 0) and frozen-miss loud-bug + safe-default paths verified by read; no crash-or-silence path.

## Findings
None surviving refutation.

verdict: COMPLETE
