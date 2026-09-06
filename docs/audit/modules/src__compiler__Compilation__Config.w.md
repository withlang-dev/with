# Audit: src/compiler/Compilation/Config.w @ 450733e5

- Module: `src/compiler/Compilation/Config.w` (75 lines, full read)
- Commit: `450733e5` (`git log --oneline -1` confirmed)
- Role: normalized driver-option set owned by `Compilation` (mirrors Zig's `Compilation.Config`)
- Targets traced: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance)
- Probe binary: `out/bootstrap/bin/with-stage1` (verified ELF 64-bit executable, `ls -la` + `file`)

## Summary

Small, self-contained config module: `CompilationConfig` struct (12 fields),
prelude constants (`PRELUDE_FULL=0`, `PRELUDE_CORE=1`, `PRELUDE_NONE=2`,
`PRELUDE_ALLOC=3`), `compilation_normalize_prelude_mode`,
`compilation_effective_prelude_mode`, `compilation_config_default`,
`compilation_config_from_cli` (partial: 5 of 12 fields), and
`compilation_config_clone` (full field copy, #747 owned-`str` clone).
All behavior-affecting logic checks out against in-repo callers; the two
findings below are low-severity and neither is load-bearing.

## Caller map (REGEX-mode searches, `mode:regex`)

- `compilation_config_clone`: zero in-repo callers (definition only,
  `Config.w:72`). Dead `pub fn`, but ownership-correct.
- `compilation_config_default`: `Config.w:63` (inside `from_cli`),
  `Compilation.w:365` (`Compilation.init`).
- `compilation_config_from_cli`: `Compilation.w:385` (`Compilation.configure`).
- `compilation_normalize_prelude_mode`: `Config.w:37,68`, `Compilation.w:614`
  (`set_prelude_mode`), `Zcu.w:255` (`Zcu.set_prelude_mode`).
- `compilation_effective_prelude_mode`: `Frontend.w:1453,1488` only
  (applied at frontend entry, not in `Compilation`).
- `PRELUDE_*` consumers: `Compilation.w:1170` (`rt_in_unit` gate),
  `Frontend.w:1535-1536` (prelude module select), `main.w:349`
  (`--prelude=alloc`), `Zcu.w:171` (default `PRELUDE_FULL`).
- `config.emit_ir|emit_bin|is_test`: no reads anywhere (write-only via
  default/clone). `Compilation.w:994` (`emit_ir(pool)`) is a method, not a
  field read. `config.tool_mode_entry_path` has no direct read either; the
  live value flows via `zcu.tool_mode_entry_path` (`Compilation.w:1519,1820`).
- `config.overflow_mode` read: `Compilation.w:605-606` (guarded by
  `overflow_mode_valid`, `-1` = no override). `config.prelude_mode` reads:
  `Compilation.w:387,945,1170`.

## Probes run (seed `out/bootstrap/bin/with-stage1`, `ls`+`file` verified)

- P1: `with-stage1 --help` → rc=0, usage text (binary alive).
- P2: `check cfg_probe.w` (trivial `fn main -> i32: 0`) → `ok`, rc=0.
- P3: `check --no-prelude cfg_probe.w` → `ok`, rc=0 (NONE path works).
- P4: `check --prelude=alloc cfg_probe.w` → `ok`, rc=0 (ALLOC path works).
- P5 (negative): `check --prelude=bogus cfg_probe.w` → rejected
  `error: invalid --prelude value 'bogus' (expected full|alloc|core|none)`, rc=1.
  CLI validates, so `normalize`'s silent FULL-fallback is unreachable via CLI.
- P6: `run cfg_probe2.w` → rc=0.
- P7 (negative): `check --freestanding cfg_probe2.w` → expected `no_std`
  diagnostics (`no_std requires @[panic_handler]`, `no_std requires @[entry]`),
  rc=1 — freestanding/CORE enforcement fires downstream.

## Findings

1. `src/compiler/Compilation/Config.w:4` — `use Overflow` is unused (low,
   T13-adjacent/style, probe: full-module read + REGEX caller search, refutation
   attempted: no `overflow_mode_valid|default|parse|OVERFLOW_MODE_*` reference
   anywhere in the 75-line file; sibling `Compilation.w:29` carries the same
   import but genuinely uses `overflow_mode_valid` at `:605,623`; build
   succeeds so the unused import is tolerated, zero behavioral impact).
2. `src/main.w:3538-3545` (`test_effective_prelude_mode`) drops
   `--prelude=alloc` (low, T22 spec conformance, probe: P4 confirms the real CLI
   accepts `--prelude=alloc` via `cli_prelude_mode` at `main.w:348-349`, while
   the test-directive override maps only none/core/full and falls through to
   default on alloc; refutation attempted: sole caller is `main.w:3707`, so
   impact is limited to test files requesting alloc via `extra-args`; root
   inconsistency is `enum PreludeMode` at `main.w:80-83` lacking `AllocMode`
   while `Config.w:25` defines `PRELUDE_ALLOC=3`).

## Refuted (reviewed, no finding)

- R1 — `compilation_config_from_cli` resets `overflow_mode/debug_info/hooks/
  emit_*/is_test/tool_mode_entry_path` to defaults: by design on every live
  path. `configure_options` re-sets prelude/overflow/debug/hooks after its
  internal `configure` call; bare `comp.configure` callers re-apply prelude
  plus debug or overflow-from-env (`main.w:816,832,862` call
  `set_overflow_mode(driver_internal_overflow_mode())`); `--overflow` is only
  offered on build-options paths, never on run/test/one-liner paths, so `-1`
  (no override) is the identical outcome; `emit_ir/emit_bin/is_test` are
  write-only (no reader); tool path is always set AFTER configure
  (`main.w:1400,1826`), never before.
- R2 — `Compilation.configure` stores raw normalized prelude instead of
  `effective` (no_std/alloc override deferred to `Frontend.w:1453,1488`):
  truth table over all 8 (mode × no_std) combos shows the only intermediate
  reader (`Compilation.w:1170`, `!= PRELUDE_NONE()`) agrees under raw vs
  effective in every combo (NONE sticks; non-NONE maps to non-NONE).
- R3 — `compilation_config_clone` dead code: ownership is correct
  (scalar copies + `with_str_clone_ref` on the sole owned `str`, matching the
  sibling-clone idiom e.g. `DriverOptions.w:180-184`); no leak/double-free
  observable with zero callers. Informational only.
- R4 — `normalize` silently maps out-of-range ints to FULL: unreachable via
  CLI (P5 rejects bogus values); API callers (`Compilation`/`Zcu` setters)
  inherit the defensive default, consistent with `set_overflow_mode`'s
  invalid→`-1` pattern. Intended.
- R5 — `emit_ir/emit_bin/is_test` dead fields (T15): write-only placeholders,
  no caller depends on them; mirror-shape fidelity question only, no behavior.

## Verdict

Verdict: COMPLETE
