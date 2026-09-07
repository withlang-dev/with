# Audit: src/compiler/ProjectConfig.w @ 450733e5 — COMPLETE

Module: 779 lines. with.toml manifest loader + validator: root discovery,
line-oriented TOML-subset parser (multi-line array continuation via
pending_key/pending_value), typed entry application with first-error
manifest_error, Conan C-dep metadata expansion, C-import header resolution,
path helpers, and deep-clone constructors. Originated as a new file in
0a36561e (271 lines); no legacy predecessor to mis-port.

## Targets
- T13 ownership/drop: PASS. Ownership is threaded explicitly throughout:
  `project_config_clone_str` returns `""` for empty (no pointless alloc)
  else `runtime_str_clone` (= `with_str_clone_ref`); `project_config_clone`
  deep-clones every owned field (all 10 scalars copied, all 13 vecs +
  7 strings cloned — field count matches the 30-field struct, no field
  dropped or shallow-copied). `move cfg` threading in
  apply/apply_entry/apply_manual_c_dep_entry/load_dep_metadata never
  aliases; every `push` of a borrowed `&str` goes through
  `with_str_clone_ref` (lines 292,299,300,310,323,343,351,430,437,440).
  `project_config_trim`/`strip_quotes`/`slice` return owned `str`, so the
  un-cloned pushes (e.g. line 293 `feature_values.push(trim(value))`,
  line 170 section assignment) are owned values, not dangling borrows —
  confirmed by signature (`-> str`) and by the live probes below.
- T15 migration fidelity: PASS (vacuous). `git log --follow` shows the file
  was created new at 0a36561e, not migrated from a legacy `src/*.w`
  predecessor (no `src/ProjectConfig.w` ever existed); subsequent growth to
  779 lines happened in place. No ported logic to diverge.
- T22 spec conformance: PASS. Overflow values panic/wrap/saturate match
  `docs/with-build.md:219`; bool/int/range validators emit the documented
  first-error diagnostics; `[lint]`/`[runtime]` key gating and the
  build.w-vs-with.toml forbidden-section table (lines 520-545) behave as
  coded, verified live against `out/bootstrap/bin/with-stage1` (see probes).

## Findings
No defects. Refuted candidates (each checked vs in-repo callers):
1. `project_config_clone_str_vec` (line 81) iterates `0..len as i32` —
   truncation only if a manifest vec exceeded i32::MAX; all callers pass
   manifest-scale vecs and the idiom is repo-wide. Not a defect.
2. `project_config_file_exists` (line 119-120) treats a 0-byte with.toml as
   missing (falls back to defaults). No spec clause requires rejecting an
   empty manifest; `src/main.w:1857` shares the helper for build.w
   detection, and the conservative-defaults behavior never miscompiles.
   Not a defect.
3. `project_config_load_dep_metadata` recursion (lines 441-448) has no
   visited-set cycle guard. `requires` chains come from `with get`-fetched
   `metadata.json` under `.with/deps/c/` (trusted local cache); no in-repo
   caller, test, or registry fixture exhibits or constructs a cycle, so a
   defect cannot be demonstrated vs in-repo callers. Robustness note only.
4. Non-`pub` helpers (`load_for_source`, `find_root`, `file_exists`,
   `absolutize_path`) are called from `src/main.w` (lines 1827,1857,2651,
   2707,2767,5303+) and `Compilation.w`/`Frontend.w`/`ComptimeEval.w` via
   `use compiler.ProjectConfig` — the workspace builds (stage1 exists,
   probes run green), so visibility resolves in this build layout.
   Not a defect.
5. `project_config_value_complete` (line 552) treats any line starting with
   `"` as complete, and a trailing incomplete `pending_value` at EOF is
   silently dropped (line 188). Malformed-tail input yields defaults rather
   than corrupt config; no caller depends on partial application. Not a defect.

## Probes run
- Stage1 verified present: `out/bootstrap/bin/with-stage1` (114 MB,
  2026-09-03; `ls` confirmed before any claim).
- `[lint] bogus_key = true` → `error: invalid with.toml: unknown key
  'bogus_key' in [lint]; expected partial_statement_match` (forbidden-key path).
- `[runtime] fiber_worker_count = 99` → `error: invalid with.toml:
  runtime.fiber_worker_count must be a positive integer between 1 and 8`
  (range-validator path).
- `[targets] foo = "bar"` → `error: invalid with.toml: imperative build
  configuration belongs in build.w, not with.toml: [targets]`
  (forbidden-section path).
- Multi-line `libs = ["m",\n"c"]` + `[build] overflow = "wrap"` → manifest
  accepted (compilation proceeded past config to an unrelated semantic
  diagnostic), confirming pending_key continuation.
- Negative control (no with.toml, /tmp/pcfg-noman): `check` → `ok`,
  confirming the default-config path still works.
- Negative controls (static, not executed): `[]` acceptance in
  `project_config_is_string_array_value` (line 637) and `0`-rejection in
  `project_config_parse_positive_i64` (line 380) verified by reading;
  a live Conan-metadata probe was not run (requires a fetched registry
  artifact; disproportionate given the trusted-cache shape).

Verdict: COMPLETE — no findings; T13/T15/T22 all pass, probes confirm live behavior.
