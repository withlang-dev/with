# Audit: src/bootstrap_main.w @ 450733e5

- Commit: 450733e5 (`git rev-parse --short HEAD` = 450733e5)
- Module: src/bootstrap_main.w (250 lines)
- Scope: read-only source audit; targets T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance)
- Seed compiler: out/bootstrap/bin/with-stage1

## Module summary
Minimal bootstrap-recovery CLI entry point. `main` dispatches on `with_arg_at(1)` to
`version` / `help` / `build` / `check`, else prints `error: bootstrap recovery entry
supports only build/check/version/help` and exits 1. Helpers `parse_source_arg`
(skip `-o <path>`, `--output=<path>`, `--emit-c`), `has_emit_c_flag`,
`parse_output_arg`, `cli_help_topic`, plus `run_build` / `run_check` / `run_help`
and static help-text printers. All FFI (`with_arg_count`, `with_arg_at`,
`with_eprint`, `with_write`, `exit`, `with_raise_stack_limit`,
`with_install_interrupt_handlers`) declared `extern fn` without bodies, as required.

## T13 ownership/drop — not applicable, no finding
- No `type` declarations, no heap-owning values, no `move`/`drop` in the module
  (verified by full 250-line read; only `let`/`var` over `i32`/`str`/`bool` and a
  `var comp = Compilation.init()` handle owned locally per call).
- `comp` is function-local in `run_build` (lines 93–108) and `run_check` (lines 115–123);
  no cross-call sharing, no aliasing, nothing to leak/double-free at this layer.
- Refutation attempt: searched for in-repo callers of this module's fns outside
  `src/bootstrap_main.w` — none (only name-collision hits like `run_build_command`
  in `src/main.w`); the module is a standalone entry point, so no caller can
  violate an ownership contract it does not expose.

## T15 migration fidelity — not applicable, no finding
- Module is hand-written bootstrap entry, not migrated C code; no `CiMigrate`/
  `Migrate` markers, no translated control flow to compare. Nothing to diff.

## T22 spec conformance — conforms, no finding
- Syntax matches language spec as enforced by the seed compiler itself
  (probe P1 below type-checks the module clean).
- `parse_source_arg` correctly skips `-o` plus its value (`i = i + 2`), `--output=`
  prefix (9-char `slice(0,9) == "--output="`), and bare `--emit-c`; first
  non-flag (`arg[0] != 45`, i.e. not `-`) is the source file. `parse_output_arg`
  handles both `-o <path>` (with bounds check `i + 1 < argc`) and
  `--output=<path>` (`slice(9, len)`). Edge case `-o` with no value returns `""`
  and callers emit `error: 'build' requires a source file argument` — correct.
- `cli_help_topic` returns `""` when `argc < 3`; `run_help` prints usage and
  returns 0 in that case, dispatches the 8 documented topics, and returns 1 with
  `error: unknown help topic '...'` otherwise — matches `print_usage` topic list.
- Intentional scope narrowing is not a defect: `main` rejects every command except
  `build`/`check`/`version`/`help` with an explicit "bootstrap recovery entry"
  message. The full compiler (`src/main.w`) serves the remaining commands; the
  filename and message document the split. Refutation (claiming missing `run`/
  `fmt`/etc. as a defect) fails against that in-repo design.
- `version` prints `with WITH_VERSION_PLACEHOLDER` — a build-time substitution
  token, consistent with a bootstrap template; seed binary reports
  `with v0.15.1.7-g450733e58` at runtime (probe P2), so substitution happens at
  build, not a source-level bug.
- `comp.configure(0, false, false, true)` / `emit_c` / `build_binary_to_path` /
  `compile_file` / `decl_count` / `print_warnings` call sites (lines 93–123) are
  the `Compilation` API surface used identically by the bootstrap path; no
  signature mismatch (module check-passes, probe P1).

## Probes (seed compiler out/bootstrap/bin/with-stage1) — all EXECUTED
- P1 `with-stage1 check src/bootstrap_main.w` → `ok`, exit 0. EXECUTED.
- P2 `with-stage1 version` → `with v0.15.1.7-g450733e58`. EXECUTED.
- P3 negative control `with-stage1 check` (no file) → `error: 'check' requires a source file argument`. EXECUTED — matches module's own missing-arg behavior.
- P4 source-level negative control: `grep -rn run_build/run_check/...` outside
  `src/bootstrap_main.w` shows only unrelated `src/main.w` names
  (`run_build_command`, `run_help_command`); no external callers to cross-check —
  confirms entry-point isolation. EXECUTED.

## Findings
None.

## Verdict
Verdict: COMPLETE
