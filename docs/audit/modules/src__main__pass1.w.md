# Audit: src/main.w LINES 1-2700 @ 450733e5 — pass1

Scope: /home/shawn/workspace2/with/src/main.w lines 1-2700 ONLY (file = 5416 lines).
Commit: 450733e5 (verified `git rev-parse --short HEAD` = 450733e5).
Mode: READ ONLY for compiler sources. No source edits made.
Probe binary: out/bootstrap/bin/with-stage1 (exists; `seed` dir absent — negative control noted).

## Coverage
- Read lines 1-1300 and 1301-2700 fully via two bounded reads.
- Traced: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.
- Probes: grep trace over lines 1-2700; `with-stage1 --version/--help`; `with-stage1 check` on trivial program.

## T13 ownership/drop
- `emit_c_header_next_to` (src/main.w:596-604): correct — borrows `&comp.zcu.last_sema` (line 600) with comment citing blank-on-move root-15 class. No move out of borrowed Compilation.
- `emit-c-header` command (src/main.w:824): `let sema = comp.zcu.last_sema` — bare field move, the exact pattern the line 598-599 comment warns against. Refutation: `comp` is not used after line 825 except drop at scope end; no use-after-move, no caller reuses it. Benign in this scope; inconsistent style only, not a live defect.
- Other `move` uses in range (`move syn` :663/:676/:688, `move _sp_build` :793, `move result.effect_records` pattern not in range / `move retire.name` :2061 etc. beyond 2700 — out of scope): all intentional transfers into sinks, no aliasing of borrowed graph elements observed in 1-2700.
- `cli_synthetic_add_mapping(syn, ...)` takes `syn` by value and returns it; callers reassign (`syn = cli_synthetic_add_mapping(move syn, ...)`). Correct linear threading.

## T15 migration fidelity
- Range contains only dispatch surface: `use CiMigrate` (:21), `use ReceiverMigration` (:36), `run_migrate_command(argc)` (:989), `run_receiver_migration()` (:870). No migration rewrite logic lives in lines 1-2700, so fidelity cannot be judged here — deferred to the module owning the migration implementation. Passthrough signatures look intact (no arg-shuffling at call sites in range).

## T22 spec conformance (CLI contract in range)
- `cli_option_takes_value` (:267-274) + `find_source_arg` (:1049-1067): `=`-form flags (`--target=x`, `--bundle-corpus=x`, `--link-bundle=x`, `--emit-bundle-*=x`) are NOT in the prefix-skip list, but refuted as non-defects: every such arg starts with `-`, so `find_source_arg` never returns it as a source (line 1064 `byte != 45` guard); exact `--target x` space form IS skipped via `cli_option_takes_value`. No source misparse.
- `find_output_arg` (:1069-1080) handles `-o` + `--output=` only; `--out=` skip in `find_source_arg` (:1060) belongs to reduce path — no conflict.
- `cli_one_liner_scan` (:442-504): mutual-exclusion of -e/-n/-p, missing-arg and file-combining errors all return early with `ok=false`. Sound.
- `check` bundle-fingerprint gate (:927-929) requires `--bundle-corpus` when `--bundle-fingerprint` given. Conformant loud-failure behavior.

## Probes run
1. `sed -n '1,2700p' src/main.w | grep -n -iE 'drop|ownership|move |clone|last_sema|cheader|emit_c|bundle|receiver|migrat|target_spec|spec'` — hit list confirms only dispatch/borrow sites above; no hidden drop/ownership logic in range. Status: PASS (evidence, not a compiler run).
2. `out/bootstrap/bin/with-stage1 --version` → `with v0.15.1.7-g450733e58` (matches audited commit). Status: PASS.
3. `out/bootstrap/bin/with-stage1 --help` → usage with build/run/check/test/bench/fmt/doc/repl/lsp/migrate/init/get/remove/update. Status: PASS.
4. `with-stage1 check /tmp/probe_hi.w` (`fn main: print("hi")`) → `ok`, rc=0. Status: PASS (positive control: probe binary can check a trivial file).

## Negative controls
- `/home/shawn/workspace2/with/seed` absent (`ls: No such file or directory`); probe used `out/bootstrap/bin/with-stage1` instead per "where feasible". No seed-based differential run possible.
- No compiler sources modified (read-only honored; only this report file written).

## Findings
1. (src/main.w:824, severity: low/info, target: T13, probe: n/a — static, refutation attempted: PASS as benign) Bare `let sema = comp.zcu.last_sema` moves Sema out of `comp`, contradicting the line 598-599 guidance applied correctly at line 600. Refuted as live defect: no subsequent use of `comp` before scope end; observable behavior identical to a borrow here. Suggest aligning to `&comp.zcu.last_sema` for consistency — NOT filed as issue per instructions.
2. (scope note, not a defect) T15 fidelity and deep T13 drop-plan logic live outside lines 1-2700; no verdict possible on them from this pass alone.

## Verdict
Verdict: COMPLETE — lines 1-2700 fully read, T13/T15/T22 traced, probes run, every observation survived refutation vs in-repo callers; no blocking defect in scope.
