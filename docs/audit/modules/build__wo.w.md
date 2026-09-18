# Audit — `build/wo.w`

Status: **COMPLETE**
Source revision: `450733e5` (module untouched by it; `git show 450733e5 --stat` touches only `build.w`, `src/main.w`)
Source SHA-256: `ec7bf0a1afb55672b65e18554acde11f4a3b3488151f3c64e9cb5436dc70d4ea`
Lines examined: 1–563 (full module, single read)

Applicable targets: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).

## Verdict: COMPLETE — no defect findings

## Findings

### F1 — build/wo.w:178 (`wo_store_prefix`) — info — T22 — probe: static (repo-wide grep) — refuted as defect
`pub fn wo_store_prefix` (slot-spelled `<store>/<name>/<target>-<abi_sha>/<name>`)
has zero callers anywhere in the tree, including inside `build/wo.w` itself:
`wo_bundle_targets` (193) spells the install destination inline as
`plan.install_slot ++ "/" ++ plan.name` (the `$HOME/`-spelled variant the
`.Install` kind requires), and `run_wo_bundle_build_action` (455) spells the
action-side prefix inline as `slot ++ "/" ++ name`. Every other `pub` item is
used: `build.w` calls `wo_bundle_plan` (1607), `wo_bundle_targets` (1819),
`wo_prefix` (460, 470), `wo_group_target_name` (462, 471),
`target_with_wo_corpus_inputs` (2931), `wo_drift_target` (2935),
`wo_drift_target_name` (2938, 2950) and `wo_drift_harness_bin` (2947).
Refutation: the function is `pub`, so the compiler raises no unused-symbol
error (`check build.w` rc=0); it documents the slot spelling next to the
install spelling and is harmless. Hygiene note only, not a defect. No issue
filed per instructions.

### F2 — build/wo.w:267–276 (`wo_basename_no_ext`) — info — T22 — probe: code review — refuted as defect
The `end` scan does not stop at the first `.` after the last `/`, so `end`
lands on the LAST dot (`foo.test.w` → `foo.test`, not `foo`). Refutation: the
only harness ever passed is `lib/std/re/pcre2test.w` (`build.w:2935,2947`),
which contains a single dot, so both conventions yield `pcre2test`; stored and
fresh harness binaries are both derived through this same function
(369, 264–265), so they agree by construction. No caller can observe the
difference today. Not a defect. No issue filed per instructions.

### F3 — build/wo.w:361–362, 428 (`read_text`/`host_read_text` on `.o` bytes) — info — T13/T22 — probe: code review vs `src/ComptimeEval.w:5555–5610` — refuted as defect
The drift comparison (361–362) and the slot `object-sha` check (428) read
binary objects as text although a `read_binary` method exists. Refutation:
both `read_text` (5561–5562) and `read_binary` (5563–5567) are served by the
same `with_fs_read_file` bytes, differing only in result type (`str` vs
bytes), so equality comparison and `wo_sha256_text` over the content are
byte-exact; the writer side (`run_wo_bundle_build_action`, 553) hashes via
the same `read_text` path, so both sides agree. No corruption or false
mismatch path found. Not a defect. No issue filed per instructions.

## T13 ownership/drop — clean
- `pub run_wo_bundle_build_action(ctx: ActionCtx)` (440) and
  `pub run_wo_drift_action(ctx: ActionCtx)` (307) take ctx by value; private
  helpers take `&ActionCtx` (`wo_fail` 57, `wo_drift_run_harness` 385,
  `wo_run` 433) — matches sibling `build/pcre2.w` convention. Passing the
  by-value `ctx` into `&ActionCtx` callees (370, 373) typechecks
  (`check build.w` rc=0).
- `move out` / `move target` / `move build_target` (144, 209, 299, 1819-style
  call sites in `build.w`) match by-value `Vec[str]`/`Target`/`Build` params;
  `move out` into `comp_sort_strings` (144) matches its by-value signature
  (`build/compiler.w:1951`). `check build.w` rc=0 confirms all moves/borrows.
- Every fallible fs/process operation checks its rc or existence:
  `mkdir_all`/`remove_tree`/`rename`/`write_text` (321–324, 457, 489–492,
  556–561), all `wo_run` results (345, 399, 406, 485, 514, 530), manifest
  field validations (542–549), fingerprint length+equality (535). No ignored
  result on a load-bearing path.
- `wo_owned_text(s): s ++ ""` ownership normalization applied at every
  arg/plan boundary (68–71, 163–170, 240–242).

## T15 migration fidelity — clean (module is hand-written, not migrated)
- No migrate options, no `c_export`, no converted-goto surface in this module;
  nothing to fidelity-check against a migration source.
- Corpus-hash shape matches the claimed source: `wo_corpus_sha` (148–154)
  builds `"<path>:<sha256(file)>\n"` over `.w`-filtered `fs.list_files`,
  sorted bytewise via `comp_sort_strings` — the same combined-string shape as
  `build_cache_hash_directory_w_files` (`src/BuildGraphCache.w:332–338`).
  `list_files` walks recursively (rt walk fns), the corpus is flat
  (35 `.w` files, no subdirs), and the identical file set is registered as
  target inputs (`target_with_wo_corpus_inputs`, 237–242), so a corpus edit
  re-runs the bundle target.
- Key construction (460) is exactly the specified
  `sha256(corpus_sha | target | abi_sha)` with `"|"` separators.

## T22 spec conformance — clean (`docs/wo_bundles.md`, header contract)
- Store layout, slot naming `<store>/<name>/<target>-<abi_sha>` (161–170),
  `out/wo/<name>.{o,wi,manifest}` tree copy (22–29, 174–179), manifest-last
  install order `o, wi, manifest` (216–233 with comment 216–217) so a torn
  slot never reads present — all match the header (14–29) and the batch-B
  mechanism note.
- ABI-gated build: refuses to compile unless the compiler's
  `version --abi-sha` stamp equals the slot's `abi_sha` (479–486, sentinel
  noted); manifest `abi-sha`/`target` re-validated post-build (542–545) with
  the `wo_host_target` vs `src/TargetSpec.w` drift message (545) — the
  fail-closed behavior the spec requires.
- `wo_host_target` (125–135) yields exactly the `TargetSpec` spellings:
  `arch()` returns one spelling per architecture (`aarch64`/`x86_64`,
  `lib/std/sysinfo.w:20–28`, so `linux_x86_64`, `darwin_aarch64`, …); the
  unknown-OS `""` fallback is refused by the action's `target.len() == 0`
  guard (450–451). Fail-closed, no silent mis-keying.
- D39 second fingerprint pass: `check <tmp>.wi --bundle-corpus --bundle-
  fingerprint` out of process (522–530), `source_fp == wi_fp` with 64-char
  guard (533–536), manifest `interface-sha` vs sha256 of the `.wi` (546),
  manifest `fingerprint` vs source fingerprint (548) — matches the batch-C2
  contract; appended `name`/`key`/`corpus-sha`/`object-sha` lines (550–553)
  match the manifest fields the slot check (411–431) and drift check
  (352–360) consume.
- Drift lane (244–257, 307–381): rebuilds to scratch with the release
  compiler, hard-errors on `.wi`/manifest-field drift (348–360), compares
  object bytes, runs the harness against the stored bundle always (370) and
  against the fresh one when bytes moved (372–374), stamps only on full pass
  (375). Matches the "Lanes" contract; `build.w:2935` wires harness
  `lib/std/re/pcre2test.w` with arg `-C` as specified.
- Slot presence check (411–431): all three exts via `host_exists`, then
  `corpus-sha`, `target`+`abi-sha`, `interface-sha`, `object-sha` coherence —
  a torn or stale slot rebuilds with a diagnostic (475), never links stale
  bytes.
- Commit `450733e5` does not touch this module (`--stat`: `build.w`,
  `src/main.w` only); no `build/wo.w` adaptation was required by it.

## Probes run
1. `out/bootstrap/bin/with-stage1 check build.w` → `ok`, rc=0 (whole build
   package incl. this module typechecks; ownership/borrow/moves verified).
2. `git show 450733e5 --stat` — commit touches `build.w` + `src/main.w`
   only; `git log --oneline -- build/wo.w` shows the module predates it
   (`9e86c3cc`, `81dbec86`, `afbe870f`) — landed-commit intent established,
   no adaptation owed.
3. Repo-wide caller search for all 16 `pub` items: sole in-repo consumer is
   `build.w` (9 used call sites); `wo_store_prefix` has zero callers (F1);
   `wo_store_dir`/`wo_host_target`/`wo_manifest_field`/`wo_build_target_name`
   used internally.
4. Spec cross-checks: `wo_host_target` vs `target_spec_kind_name`
   (`src/TargetSpec.w:99–116`) and `arch()` contract (`lib/std/sysinfo.w`);
   corpus-hash shape vs `build_cache_hash_directory_w_files`
   (`src/BuildGraphCache.w:332–338`); `read_text`-on-`.o` vs
   `src/ComptimeEval.w:5555–5610` dispatch (F3 refutation).
5. `sha256sum build/wo.w` →
   `ec7bf0a1afb55672b65e18554acde11f4a3b3488151f3c64e9cb5436dc70d4ea`;
   working-tree file identical in length (563 lines) to
   `git show 450733e5:build/wo.w`.

## Negative controls
- N1: standalone `out/bootstrap/bin/with-stage1 check build/wo.w` fails on
  module resolution (`use build.compiler` — submodule must be checked via
  the package root) while `check build.w` passes — proves probe (1)
  exercises the module rather than vacuously passing, and scopes the T13
  typecheck claim to package-root checking.
- N2: REGEX caller search for `wo_store_prefix` across all `.w` files —
  zero hits outside its definition, confirming F1 is unused-pub-API, not a
  live path the audit missed.

Verdict: COMPLETE
