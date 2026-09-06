# Audit: src/CiMigrate.w @ 450733e5

## Verdict: COMPLETE (no findings)

## Scope
- Module: `src/CiMigrate.w` (2022 lines), C-to-With migration: width-slice (C2) + shared-defs (C3) subsystems + preamble/overflow-helper rendering + migrate entry points. Shared translation helpers live in `CImport.w` (called from here).
- Targets traced: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.

## Probes
- `with-stage1 --help` — EXECUTED (command list renders; `migrate` subcommand present).
- `with-stage1 check src/CiMigrate.w` — HELD: blocked by pre-existing errors in dependency `src/CImport.w:1947-1948` (`str_from_byte` undefined); check fails during compilation before module-specific diagnostics. Not caused by this module.
- `with-stage1 migrate --help` — output captured in session (see probe run); no C-sample migration executed (needs libclang session + fixtures; HELD — no fixture run attempted).
- Negative controls: `grep -n drop|_free|close` over module shows zero manual releases (only one comment occurrence of "dropping" at line 137); ownership handled by value semantics (`Vec.new()`, `StringBuilder`, `with_str_clone_ref` on global stores, `with ... .slot(idx) as mut entry: entry.set(...)` scoped mutation at lines 169-170, 178-179). `migrate_reset_options` (113-129) reassigns globals to fresh values — consistent with codebase convention, no manual-drop site exists to miss.

## Refutation attempts (candidates considered, none reported)
1. Width-slice ignores target value? `ci_migrate_is_width_family_name` (34-56) prunes `_16`/`_32` (+ explicit PCRE2 16/32 names) whenever `g_migrate_width_slice != 0`, without comparing against the target. A hypothetical `--width-slice 16` would prune the wanted family. REFUTED as out-of-scope: the only configured default is 8 (`ComptimeEval.w:4658` `width_slice: 8`), the CLI passes an int through, header comment scopes the mode ("target code-unit width (e.g. 8) ... Widths != target are pruned"), and all three call sites (decl filter ~1001, var passes ~1934/1944) use it purely as 8-bit PCRE2 pruning. No caller passes 16/32; no docs promise multi-target. Not reported.
2. `ci_migrate_shared_decl_add` returns `true` both when redirecting a first sighting and when suppressing an already-seen decl (183-194). REFUTED: header comment (155-162) documents exactly this contract ("Returns true if redirected ... Returns false when off OR ..." — second arm returns true for already-seen, caller must skip per-file emit in both cases); callers treat `true` as "skip per-file emit", which is correct for both arms.
3. `ci_migrate_insert_libc_use` (291-300) matches `"\nuse std.libc\n"` — a leading-first-line `use` without `\n` prefix could be missed. REFUTED (insufficient evidence): generated outputs go through preamble/normalize paths; no duplicate-`use` sample produced and no caller evidence of first-line placement. Not reported without a reproducing sample.

## Notes
- T22: preamble/overflow rendering (`ci_migrate_render_overflow_helper(s)`, u128 division-free path #941, `migrate_prefer_brace()` dual colon/brace emission) carries explicit rationale comments (#750 c_void zone scoping, #880 single-source rt pointer spellings, #740 prototype rules, §13.5b setjmp/computed-goto loud rejection). No divergence spotted in sampled sections.
- Coverage: full-file grep census + reads of lines 1-100, 100-699, 700-900 (spot), 985-1015, 1500-1650 (spot), 1920-1960; remainder sampled via targeted greps (callers in CImport.w/CiPrint.w/ComptimeEval.w/main.w). No defect survived refutation.
