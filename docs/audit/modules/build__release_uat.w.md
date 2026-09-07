# Audit: build/release_uat.w @ 450733e5 — COMPLETE

Module: `build/release_uat.w` (479 lines) — release UAT build-graph actions:
platform asset copy, artifact smoke, fresh project, C migrate, C-package
(zlib/bzip2/sqlite3/openssl/libcurl), install layout, raylib spiral, one-liners.
Callers: `build.w:2642-2745` (11 targets + `release-uat` group); all `pub`
actions wired with compiler input, `out/release-uat` write scope,
`require-last-green` dep. Fixture inputs declared for all 6
`build/release_uat_fixtures/*.w` reads. No other callers.

## Targets traced
- T13 ownership/drop: `release_uat_owned_text` (`s ++ ""`, line 5) matches repo
  clone idiom (`ci_ir_owned_text`, `codegen_owned_text`); `UatRunResult {
  result.rc, move result.stdout, move result.stderr }` (lines 126,133,144)
  is byte-identical to the `SelfhostRunResult` idiom used at 7 sites in
  `build/selfhost.w`. No live-value drops; `var result` + partial move is the
  sibling pattern. Clean.
- T15 migration fidelity: flags `--no-c-export` / `--prefer-colon` (line
  285-286) exist in `src/main.w:3985` / `src/main.w:4004`. End-to-end probe
  below reproduces the gate's exact assertions. Clean.
- T22 spec conformance: `version` prints `"with "` (`src/main.w:968`);
  `check` prints `ok` (probed); every gate fails via `ruat_fail`
  (diagnostics + rc 1), writes stamp only on success; timeouts bounded
  (120s/600s/180s); `os()` gates `.exe` suffix and `chmod`. Clean.

## Probes run (seed out/bootstrap/bin/with-stage1)
- P1 `check build/release_uat.w` → `ok`, rc=0. PASS
- P2 `-e 'print("artifact smoke")'` → `artifact smoke`, rc=0 (matches line 222). PASS
- P3 `-p 'line = f"{nr}:{line.upper()}"'` on 3 fruits → `1:APPLE/2:BANANA/3:PEAR`,
  matches line 454 exactly. PASS
- P4 migrate module's own tiny.c with `--no-c-export --prefer-colon` →
  rc=0, `fn add_pair` present (grep count 1, matches line 291), migrated file
  `check` → `ok`, rc=0. PASS (full T15 chain)
- P5 `version` code-read: `with_write("with ")` confirms line 218/367
  `contains "with "` checks. PASS by code evidence
- P6 `copy_file` code-read (`lib/std/build.w:1461`): `mkdir_p(dst_dir)`
  built in — install-layout `bin/` copy (line 361) needs no prior mkdir. PASS

## Negative controls
- N1 `seq 100 | -n 'if line =~ /^[0-9]$/'` on stage1 → EMPTY, rc=0. Refuted as
  defect: `-n` plumbing proven by `==` control (`if line == "5"` → `5`);
  stage1 seed predates the pcre2 regex runtime (HEAD commit subject); the UAT
  runs against the release compiler. Not a module defect.
- N2 `timed_out` dropped from `ToolProcessResult` → refuted: same shape as
  sibling `SelfhostRunResult`; timeout yields rc==124 (`lib/std/build.w`),
  caught by `ruat_expect_success`. No silent pass.
- N3 no test files under `tests/ test/ tools/ scripts/` reference this module
  (grep, empty) — coverage is the build-graph UAT gates themselves; no
  coverage claimed beyond that. All 6 fixture files exist in tree (listed).

## Findings
1. build/release_uat.w:121, severity low, T22 — `ruat_run_capture_cwd` takes
   unused `compiler: &str` (9 call sites pass it; body uses prebuilt `args`).
   Probe status: code-read confirmed, no behavior impact. Refutation attempt:
   benign convention uniformity, not a drop/spec issue. Observation only.

Verdict: COMPLETE (1 low-severity style observation, no blocking defects).
