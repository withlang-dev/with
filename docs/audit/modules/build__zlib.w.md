# Audit: build/zlib.w @ 450733e5

Commit: 450733e5 (HEAD; does not touch build/zlib.w — last zlib.w changes: ae6b7e78, 6e73f5f7, 8aaeeeda)
Module: build/zlib.w (477 lines) — graph-owned zlib 1.3.2 reference/migrate/build/test/check/promote actions
Callers: build.w:2968-3020 (zlib-reference, zlib-migrate, zlib-build, zlib-test, zlib-check-generated, zlib-promote)

## Targets traced
- T13 ownership/drop: all string ownership via `zlib_owned_text(s): s ++ ""` (build/zlib.w:4), byte-identical idiom to pcre2 (`build/pcre2.w:6`). No manual drop/free/retain calls in module (rg ownership|drop|Drop: no hits). Helpers (join/safe_label/dirname/basename/abs/fail/remove/copy) mirror pcre2 helpers line-for-line in behavior. `with-stage1 check build/zlib.w` => ok.
- T15 migration fidelity: `zlib_source_files` (build/zlib.w:104-132) lists 15 upstream .c + 11 headers (26 entries) = whole zlib 1.3.2 library; example.c/minigzip.c migrated separately via `zlib_migrate_one_file` with shared-fragment (build/zlib.w:328-337), matching handoff "whole library + migrated upstream tests" rule. Options (`zlib_migrate_options`, :147-171): no_c_export=true, c_export_functions=false, convert_goto=false, block_style=2, width_slice=8, shared_defs="std.zlib.defs" — identical knobs to pcre2 (:190-194). Threshold `generated_count < 18` (build/zlib.w:339,444) matches promoted tree `lib/std/zlib/` (18 .w files incl. defs/example/minigzip; wc total 23625). `migrate_one` directory-mode arg shape (source_dir as source_path) matches whole-library call shape — convention, not defect (refuted vs build/zlib.w:174,324).
- T22 spec conformance: conforms to docs/completed/zlib-handoff.md:25-42 (6 actions present: run_zlib_reference/migrate/build/test/check_generated/promote), SHA pin ZLIB_SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16 (:7) matches handoff §3, no-c-export enforced at 4 gates (:208-222 reject fn; calls at :341,:375,:441,:458), test runs migrated example + minigzip gzip round-trip (:388-433). No `c_import` in build/zlib.w (rg: nil). Declared write_scopes in build.w:2983-2986 cover the `remove_tree("out/zlib_build"/"out/corpus/zlib-test")` calls at build/zlib.w:347-350 — no scope overreach. Recon docs/specs/std-zlib/recon.md status Observed only; no Agreed contract to violate.

## Probes run
1. `with-stage1 check build/zlib.w` => `ok` (exit 0). PASS.
2. `with-stage1 ast build/zlib.w` => parses; owned_text/MigrateOptions nodes as expected. PASS.
3. rg callers: 6 actions each wired exactly once in build.w:2968-3020. PASS.
4. `ls lib/std/zlib/` => 18 .w files; `ls test/behavior/behav_zlib_std.w` => exists (88 lines, facade matrix). PASS.
5. Negative: `rg c_import build/zlib.w` => nil; `rg ownership|drop` => nil (no hidden manual memory ops). PASS.
6. Negative: `ls out/zlib_reference out/zlib_migrated out/gen/.zlib-migrate-stamp` => absent, so full migrate/build/test pipeline not runnable offline here (reference fetch needs network); static + stage1 checks substitute. NOT RUN (env).

## Findings
None. No defect survived refutation vs in-repo callers and landed-commit intent.

## Negative controls
- Claimed test coverage verified by existence: test/behavior/behav_zlib_std.w exists (88 lines); no coverage asserted by absent files.
- HEAD commit 450733e5 (regex-runtime/pcre2-bundle shim) does not modify build/zlib.w; no intent drift to reconcile.

## Verdict
Verdict: COMPLETE — build/zlib.w conforms on T13/T15/T22; no actionable defects.
