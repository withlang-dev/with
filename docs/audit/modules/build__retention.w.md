# Primary verification — `build/retention.w`

Status: **COMPLETE**
Verifier: workflow child (read-only source audit)
Source revision: `450733e5`
Module: `build/retention.w` (989 lines, fully read)
Callers: `build.w` only (`use build.retention` at build.w:11; actions wired at
build.w:1919 `run_fixpoint_evidence_action`, build.w:2570 `run_test_green_action`,
build.w:2616 `run_last_green_action`, build.w:2634 `run_require_last_green_action`,
build.w:3023/3042 `run_prune_action` dry-run + apply)

## Scope examined

Test-green / last-green / fixpoint-evidence / require-last-green evidence gates,
seed-archive rotation (`RET_SEED_KEEP = 5`), release-artifact rotation
(`RET_RELEASE_VERSION_KEEP = 5`), small-prune (stale state/seed/release) and
large-prune (temp bin/lib/bootstrap-lib archives, issue61 dirs, embedded
compiler copy) candidates, plus string/path/hash/version helpers.

Applicable targets traced: T13 (ownership/drop — `move` discipline after the
d527f299 share-place migration), T15 (migration fidelity — D19
read-not-rederived evidence, marker-format agreement with
`src/BuildGraphCache.w`), T22 (spec conformance — `docs/with-build.md`
prune/last-green behavior; `docs/requirements.md` "retention" hits are C-pointer
lifetime rules, not this module).

## Probes run (seed `out/bootstrap/bin/with-stage1`, v0.15.1.7-g450733e58)

1. `with-stage1 check build/retention.w` → `ok`, rc=0.
2. `with-stage1 check build.w` (full entry incl. retention) → `ok`, rc=0.
3. `out/bin/with-sha256` vs `sha256sum` on probe file → identical digest
   (`008a9591…b64`). Confirms the content-hash agreement that marker fidelity
   depends on (`BuildGraphCache.w:372-374`).
4. Batch `with-sha256 f1 f2` → one `hex  path` line per file, rc=0. Matches
   `ret_sha256_files_manifest` (retention.w:383-422) line parsing.

## Negative controls

- `with-sha256 /nonexistent_xyz` → stderr message, rc=1. `ret_run_lines`
  returns empty on rc!=0 and every hash caller treats empty as loud failure
  (`:590-592`, `:637-643`, `:680-682`, `:727-729`), so a missing binary can
  never yield an empty hash accepted as evidence. No silent-accept path found:
  `ret_sha256_files_manifest` uses `""` for both empty-input and failure, but
  all four forwarders (`ret_sha256_hex_list`, `ret_append_file_hashes`,
  `ret_sha256_text`→fingerprint, direct callers) check length/countedness
  before use.
- Marker-format fidelity vs `build_cache_test_success_manifest`
  (`src/BuildGraphCache.w:377-413`): `kind:2` == `.Test` (BuildGraphKinds.w:30);
  `output:` empty, `opt:0` == debug, `target-kind:0` == native per
  `target_new` defaults (lib/std/build.w:1976-1997, BuildTarget.native=0,
  OptimizeMode.debug=0); single `arg:compiler=out/release/bin/with` matches
  build.w `:2312-2399` (one arg each, no defines/includes/libs on any of the
  five fingerprinted suites); `compiler:` project-relative rewrite matches
  `build_cache_project_relative`; file set (`*.w` direct children) matches
  `build_graph_test_target_files` + `collect_test_files` (single-star `*`
  has no dotfile exclusion per BuildGraphSupport.w:72-91, so glob ≡
  `ends_with(".w")`); both sorts are byte-wise insertion sorts
  (`build_cache_str_compare` ≡ `ret_str_compare`). No divergence found.

## Findings

No defect survived refutation. Numbered candidates, all refuted or noted:

1. (T13, refuted) `move candidates` / `move all` / `move sorted` idiom
   (`:835-837`, `:928-932`, `ret_add_unique`, `ret_sorted_strings`): every
   moved-from binding is reassigned from the return value with no interim use;
   `bin`/`lib`/etc. in `ret_append_all_prune_candidates(move all, bin)` are
   `&`-borrowed, not moved. `ret_vec_contains` already takes `&Vec[str]` per
   265dfe4c. `check` rc=0 confirms the share-place borrowchecker accepts it.
2. (T13, refuted) Ignored `fs.remove_file` rc in `ret_sha256_text` (`:201`)
   and `ret_archive_verified_seed` (`:574`), and best-effort counting in
   `ret_apply_small_prune` (`:840-853`): repo-wide idiom (same `let _remove` /
   `let _write` pattern in `BuildGraphCache.w:417-421`); temp-file cleanup in
   `ret_sha256_text` runs on all paths including hash failure. Large-prune
   removal (`ret_remove_prune_candidates`, `:905-912`) fails loudly. An
   orphaned seed binary after a failed trim-remove is possible only under an
   already-failing filesystem and is re-reported by the next dry-run, not
   silently blessed.
3. (T15, refuted) `ret_json_field` (`:656-667`) stops at the first `"` and
   would truncate a value containing an escaped quote, despite the comment
   claim. Unreachable in-repo: the only fields extracted are
   `compiler_sha256` / `stage2_fixpoint_sha256` / `stage3_fixpoint_sha256`
   (all hex), written by our own evidence writers; the other two gates use
   substring match on hex digests. Latent robustness note only.
4. (T15, confirmed conformance) D19 read-not-rederived holds:
   `run_last_green_action` (`:687-695`) reads `fixpoint-evidence.json` and
   compares hashes, never re-hashes or rebuilds fixpoint objects; stale
   evidence fails loudly. Matches the `build.w:2616-2628` "no deps on
   build/fixpoint targets" wiring comment.
5. (T22, observation, not a defect) `ret_test_green_fingerprint` (`:457-506`)
   covers 5 native suites by marker+file-hash plus 15 lanes by `.state` file,
   but several `:test`-group lanes (comptime-diff, internals, lexer, parser,
   fmt/lsp cli-selfhost, bundle-interface, wo-drift, invariance,
   requirements/spec checks) contribute no fingerprint input. That boundary is
   landed design, not a module defect; widening it is a build-owner decision.
   No issue filed per task instructions.
6. (T22, observation) Mixed parseable/unparseable version strings fall back
   from numeric to lexicographic compare (`:264-279`); with the
   `starts_with("v")` gate in `ret_release_artifact_version` (`:781-797`)
   real inputs are `vX.Y.Z` and the sort stays total and deterministic.
   Contrived-input only; not a defect.

## Verdict: COMPLETE — no filing; gates fail loudly, marker fidelity verified
