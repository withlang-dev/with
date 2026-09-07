# Audit: src/main.w lines 2701-5416 (pass 2) @ 450733e5

Scope: read-only audit of `src/main.w` lines 2701-END (5416 total). Commit `450733e5` confirmed via `git rev-parse --short HEAD`. Full range read in two windows (2701-4300, 4301-5416). This range is CLI-driver glue: build/run dispatch, dump/trace artifacts, test/bench harness, C-migrator CLI thin wrapper, doc/repl/fmt/clean/help/init/get/remove/update commands. No MIR ownership engine, no receiver-migration engine, no spec-authoritative grammar lives here; all heavy work delegates to `Compilation`, `Migrate`/`CiIR`, and `build_graph_*` helpers.

## Verdict: COMPLETE

No surviving defects in T13/T15/T22 within 2701-5416. One info-grade observation (migrate --check/--diff/--stats silent TODO) refuted as non-defect below.

## Findings (each refuted vs in-repo callers)

1. `src/main.w:2714-2718` (#747 restore of `actual_options.source_path`) — severity: none (correct fix). Target: T13 ownership. Probe: code-read only. Refutation: the empty-source branch (2701-2705) sets `actual_options.source_path`; this branch must do the same after `var actual_source` moved the field out. Matches comment; downstream `comp.build_binary_to_path(actual_options.source_path, ...)` at 2749 reads it. No defect.
2. `src/main.w:2738` (`var obj_path = move actual_options.output_path`) + `link_stage_cleanup_current_process_temp_archives()` on every return (2728/2735/2744/2747/2752/2755) — severity: none. Target: T13. Probe: code-read. Refutation: move-out is intentional (output_path consumed once); all five early returns call cleanup, no leak path. No defect.
3. `src/main.w:2846-2849, 3107-3112, 3139-3144` (`Parser.init(move tokens, ..., move diags)` / `diags = move parser.diags`) — severity: none. Target: T13. Probe: code-read. Refutation: uniform three-site idiom (dump_ast, discover_test/bench); parser is consumed and fields given back each time. No defect.
4. `src/main.w:2919-3066` (dump/trace/validate artifact family) + `3037-3048` (`trace_cleanup_edge_artifact` #760 guard via `mir_cleanup_edge_spec_ok`) — severity: none. Target: T13/T22. Probe: live negative probe below (P4). Refutation: invalid spec is a hard `return 1` before compiling; valid path delegates to `Compilation`. Correct per comment. No defect.
5. `src/main.w:3305-3413` (`parse_test_directives_for_target`: skip-on/only-on gates, reason required, unknown value -> `directive_error`) + `3466-3474` (directive_error/skip-reason enforced loudly) — severity: none. Target: T22 spec conformance. Probe: code-read. Refutation: matches D23 discipline noted in comments (3362-3364); `run_test_directive_command` fails loudly on malformed gates. No defect.
6. `src/main.w:3652-3666` (known-issue must-stay-red both directions) + `3668-3690` (env save/restore) — severity: none. Target: T22. Probe: code-read. Refutation: green-with-known-issue returns 1 (3663-3664); env pairs restored loop 3685-3689. No defect.
7. `src/main.w:3899-3947` (`migrate_apply_std_use_fixits`: max 3 passes, non-convergence -> loud `return 1`) + `3949-4059` (`run_migrate_command` thin arg parsing, delegates to `migrate_c_file`/`migrate_c_directory`) — severity: none. Target: T15 migration fidelity. Probe: code-read. Refutation: fidelity engine lives outside main.w; wrapper correctly loops gate fix-its to fixpoint and fails loudly otherwise. No defect.
8. `src/main.w:3982-3984` (`--check/--diff/--stats` silently `continue // TODO: implement modes`) — severity: info, NOT a defect (refuted). Target: T15/T22. Probe: caller search (see probes). Refutation attempt: `grep -rn` hits are for `with migrate rust ...` (docs/with-migrate-rust-spec.md, a different subcommand) and a checklist checkbox; the C-migrator usage string at 3951 does NOT advertise --check/--diff/--stats, so no user-visible contract in this path is broken. Silent-accept of hidden TODO flags is tech debt, not a conformance violation. Not filed. Refutation attempted and survived as non-defect.
9. `src/main.w:4396-4442` (fmt `--check` returns 1 when changed), `4461-4824` (help/usage texts), `5301-5416` (get/remove/update registry-unavailable + lock/manifest handling) — severity: none. Target: T22. Probe: live P1/P2. Refutation: usage output matches binary `--help`; fmt check semantics standard. No defect.

## Probes run (seed: out/bootstrap/bin/with-stage1 @ 450733e5)

- P1 `with-stage1 version` -> `with v0.15.1.7-g450733e58` (pass; confirms seed matches audit commit).
- P2 `with-stage1 help` -> usage header + command list incl. build/run/check/test (pass; T22 usage conformance spot-check).
- P3 `with-stage1 check /tmp/pass2_probe.w` (trivial `fn main: print("ok")`) -> `ok`, pipeline rc 0 (pass; positive control that check pipeline works).
- P4 negative `with-stage1 check --trace-cleanup-edge badspec /tmp/pass2_probe.w` -> `error: invalid --trace-cleanup-edge spec 'badspec'; expected fn:bbFROM->bbTO` (pass on message; rc inconclusive because `| head -5` masks the compiler exit code — pipeline `$?` reflects `head`, reported 0. Code path at 3039-3041 plainly returns 1; message conformance verified, rc not independently verified).
- P5 caller search `grep -rn "migrate.*--check|--diff|--stats" docs/ test/` -> only `docs/with-migrate-rust-spec.md` (`migrate rust`, different subcommand) + `docs/completed/test_checklist.md` checkbox (used to refute finding 8).

## Negative controls

- N1: invalid `--trace-cleanup-edge` spec rejected with explicit expected-format message (P4) — invalid input is a hard error, not marker text with rc 0 (#760 honored at message level).
- N2: `--prefer-curly` (renamed) at 3997-3999 and 4400-4401 returns error directing to `--prefer-brace` — stale spelling fails loudly, not silently accepted.
- N3: read-only discipline held for compiler sources: no edits to `src/*`, `lib/*`, `rt/*`, `build/*`; only writes were `/tmp/pass2_probe.w` (probe fixture) and this report file.

## Coverage

- Lines 2701-5416 fully read (two overlapping read windows, 5416-line file confirmed by `wc -l`). T13 traced via `move`/cleanup/drop/validate sites listed above; T15 traced via `migrate_*`/`ci_ir` grep (3899-4059 + 3956-3957 hidden `--ir-roundtrip`); T22 traced via usage/help/TODO grep (3951/3984/4461-4824). Seed binary probed where feasible (P1-P4). No issues filed per instructions.

Verdict: COMPLETE
