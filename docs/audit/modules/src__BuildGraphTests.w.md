# Audit: src/BuildGraphTests.w @ 450733e5

## Verdict: COMPLETE (no findings)

## Scope
- Full module read: `src/BuildGraphTests.w` (208 lines).
- Commit verified: `450733e5` (`git rev-parse --short HEAD` = 450733e5).
- Seed compiler present: `out/bootstrap/bin/with-stage1` exists.
- Audit targets traced: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.

## T13 ownership/drop — clean
- Retained strings are cloned via `with_str_clone_ref` at every site: `build_graph_test_target_files` return vec (L35), `run_files/run_keys/pass_keys/pass_paths/failed_paths` (L144-156, L189-192), job constructor (L94), argv building (L52).
- Borrowed access (`active.get(oldest).test_path` L186, `run_files.get(...)` L173, `target.args.get(...)` L46/54) is only read or re-cloned before push; no use-after-free pattern.
- Temp strings from `resolve_join`/`build_graph_argv_append`/fingerprint helpers are consumed immediately or cloned on retain. No missing clone found.
- No explicit drop needed under ref-counted `str`/`Vec` model; no leak-prone raw handle introduced in this module.

## T15 migration fidelity — N/A, clean
- Idioms match codebase conventions (`for i in 0..len as i32`, `.get(i as i64)`, `var`/`let`, `++` concat + `f"..."` interpolation).
- No transliteration artifact (no leftover Rust/Python-ism, no dead shim).

## T22 spec conformance — clean
- Non-glob fast path (L20-22), single-star same-directory expansion (L24-35, `candidate_dir != search_dir` guard L31 + basename match L34).
- Compiler-arg filtering: `compiler=` extracted/resolved (L38-49), excluded from child argv (L55-56), `--quiet` + child path appended (L84-91).
- Jobs-limit parse (L59-82): non-numeric prefix parse, default cores clamped [1,32] with fallback 4; never returns 0 so sliding window (L171-195) cannot deadlock.
- Verdict cache: only passes cached (L150-156), failures always re-run, pass set persisted even on red run (L200), summary counts `cached/ran` consistent (L203, L207).
- Error paths: mkdir failure -> 1 (L98-100, L130-132), spawn failure -> 1 (L179-181), timeout 124 and non-zero propagate with stdout/stderr paths in message (L106-114, L118-126), multi-failure sweep never aborts early and returns first failure code (L191-206).

## Probes
- No compiler `check`/`run` probe EXECUTED. Status: HELD — module is a graph-runner over a full project fixture (`root`, `BuildGraphTarget`, verdict-cache dir, spawned `with-stage1 test` children with 300s timeouts); no small single-file probe can exercise it without fabricating that harness, which would test the harness rather than the module.
- Negative controls (static, no execution): confirmed `build_graph_test_jobs` cannot return 0; confirmed `oldest/next` window indexes `active` monotonically without OOB on empty `run_files` (while-guard L171); confirmed timeout code 124 handled on both sync and wait paths.

## Findings
- None.
