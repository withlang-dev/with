# Audit — src/compiler/CodegenUnits.w @ 450733e5

Status: COMPLETE (1 low-severity note, no load-bearing defect)
Commit: 450733e5 (`450733e58a1a7cce14f9cb2084943fc178815111`, verified via git rev-parse)
Module: src/compiler/CodegenUnits.w (255 lines, read in full)

## Scope examined

Per-unit generation support for #681: env/default unit counts, MIR→unit
assignment, global-ownership surgery, per-unit object paths, threaded
optimize+emit of generated unit bitcodes, extra-objects enumeration.

Applicable targets: T13 (ownership/drop), T15 (migration fidelity),
T22 (spec conformance).

## T13 — ownership/drop

- `codegen_units_apply_global_ownership` (CodegenUnits.w:75-96): k!=0 deletes
  appending-linkage globals, demotes other non-private definitions to
  declarations (internal→external first, then clear-initializer), iterates via
  saved `next` so delete-during-walk is safe. Unit 0 promotes internal
  definitions to external. Pair is consistent: every non-private definition
  lives in unit 0 only; every other unit holds a matching declaration.
- Refutation vs in-repo emitters: globals are only ever created with
  external (0), internal (8), private (9), or appending (7) linkage
  (CodegenTraits.w:1463-1481, :1934, :2440; CodegenDispatch.w:356;
  Codegen.w:4647 linkage 5 is functions, not globals; no CommonLinkage
  constant exists or is used). The three-way branch covers the whole emitted
  set; no weak/common case is dropped.
- Private-global duplication is sound: all private globals found are
  constant data (bytes/string/regex literals), never mutable shared state.
- Function-side demotion lives in Codegen.w:1347-1358
  (`unit_demote_foreign_definitions`, `__wcu$` owner-defined already) and the
  rename scheme (Codegen.w:1363-1369) is identical in every unit — consistent
  with the header comment (CodegenUnits.w:9-15).
- Callers: Backend.w:158 (ownership), Backend.w:113 (assign),
  Backend.w:174 (emit-all), Compilation.w:1162 (extra objects). All match.

## T15 — migration fidelity

- Wrappers delegate cleanly: `codegen_units_default_count` → policy
  `codegen_units_count_for` after the <2000 single-unit gate and sysinfo read
  (CodegenUnits.w:51-56); `codegen_units_emit_width` → policy
  `codegen_units_emit_width_for` after env override / 8 GiB fallback
  (CodegenUnits.w:61-69). Policy constants match docs/build_time_log.md:30
  (36 KB/stmt, 5 GiB frontend reserve, 21-cell matrix).
- Env override (1..64, CodegenUnits.w:33-38) intentionally bypasses the
  policy 16-cap — documented "explicit override", not a drift.
- Backend dispatch (Backend.w:28-35): multi-unit only when count>1 and not
  module_object_mode; single-unit path resets `last_codegen_unit_count = 1`
  (Backend.w:82), multi-unit sets it (Backend.w:180, default 1 in Zcu.w:161),
  so Compilation.w:1162 links exactly the emitted extras.
- Determinism claim holds: assignment is index-ordered greedy least-loaded
  with strict `<` (ties → unit 0), no map iteration (CodegenUnits.w:131-143);
  emit order is index order (CodegenUnits.w:219-232).

## T22 — spec conformance

- Header contract (CodegenUnits.w:1-18) verified against code: serial
  per-unit generation in Backend.w:109-167, ownership surgery at Backend.w:158,
  `<obj>.u<k>.o` paths (CodegenUnits.w:99-100) produced and consumed
  consistently (CodegenUnits.w:164, :249-254; Compilation.w:1162-1172).
- `codegen_unit_emit_generated` (CodegenUnits.w:148-177): per-thread context,
  parse/target-machine/emit each checked with distinct errors; dispose on all
  paths.
- `codegen_units_emit_generated_all` (CodegenUnits.w:198-247): jobs vector
  fully built before any spawn so element pointers are stable; spawn failure
  degrades to inline execution (CodegenUnits.w:223-224); window clamped to
  [1, unit_count] (CodegenUnits.w:200-202). `join_rc` only observes the thread
  entry return (always 0) but no error is masked — real per-unit status is
  collected from `jobs.rc` (CodegenUnits.w:240-242). Verified by reading, not
  by failure injection.

## Findings

1. (CodegenUnits.w:193-197 comment vs CodegenUnits.w:240-244 code; severity:
   low; targets: T13/T22; probe status: code-read, no probe) — Comment says
   "Removes each unit bitcode file on success" but the cleanup loop removes
   every `.u<k>.gen.bc` unconditionally, including after a failed unit, which
   deletes failure evidence. Refutation attempt: confirmed the `with_fs_remove_file`
   call sits outside any `unit_rc == 0` guard — mismatch stands, but it is
   debuggability-only (Backend still returns nonzero and reports the failing
   unit). No filing per instructions.

## Probes run (out/bootstrap/bin/with-stage1 @ with v0.15.1.7-g450733e58)

- `with-stage1 --help` → usage output, rc=0 (binary exists; `seed/` and
  `bootstrap/bin/` paths do NOT exist — canonical binary is
  `out/bootstrap/bin/with-stage1`).
- Trivial `fn main() -> i32: 0`: default build rc=0; WITH_CODEGEN_UNITS=2
  build rc=0, binary runs rc=0.
- Globals probe (`let G: i32 = 41`, cross-fn read, exit-code check): K=1
  build+run rc=0; K=2 build+run rc=0. Ownership/demote path does not break
  cross-unit global reads.

## Negative controls

- No map iteration in assignment/emit loops (all index/pointer walks) —
  determinism claim not refuted.
- `assign` with unit_count ≤ 0 would index an empty `bin_loads`, but all
  in-repo callers guarantee ≥ 1 (env clamp, default ≥ 1, `> 1` gate at
  Backend.w:31) — robustness-only, not a defect.
- Searched `src/`, `docs/`, `plans/` (REGEX mode) for `__wcu`, linkage
  helpers, caller sites, and policy docs; no contradictory spec or second
  ownership implementation found.

## Verdict: COMPLETE — 1 low-severity note, no filing
