# Audit — src/LockFile.w @ 450733e5

Scope: `src/LockFile.w` (6-line compatibility facade: `use compiler.LockFile`) + real implementation `src/compiler/LockFile.w` (~400 lines: deterministic `.with/lock.json` handling).
Commit: 450733e5 (`build: the regex runtime shim compiles pcre2 from source ...`).

Targets: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.

## T13 ownership/drop — PASS
- `LockEntry` fields are owned `str` (#747 note); all copies go through `lock_entry_clone` using `with_str_clone_ref` on every field.
- `lock_upsert(lock: &LockFile, entry: LockEntry)`: clones on replace/insert-sort paths, moves `entry` on tail push; no use-after-move (`entry` not touched after push).
- `LockDepWalk { lock, seen }` threads owned lock + dedup memo by value with explicit `move` (`move out.lock`, `move walk`, `move done.lock`, `return move done.lock`) — matches post-#691 no-aliasing rule; sibling subtrees share `seen` via threading. No handle-copy aliasing.
- `lock_entry_from_installed_c_dep(project_root, name, version: &str)` clones `version` via `with_str_clone_ref` before embedding — correct borrow-to-owned.
- `lock_load`: `lock = lock_upsert(lock, current)` borrows lock, moves `current`, then reassigns `current` — no UAF. No findings.

## T15 migration fidelity — PASS
- Sorted-insert `lock_upsert` keeps `deps` deterministic; replace-on-equal-name dedups.
- `lock_write` comma logic: `version` line gets trailing comma iff `source == "conan"` (more keys follow); conan block ends with `sha256` comma=false; entry `}` comma iff not last. Correct.
- Manual `[deps.c.X]` user paths intentionally excluded (header comment) — no fetched artifact to pin; in-repo callers confirm nothing else reads them from lock. Not a defect.
- Observation (not a finding): `lock_json_escape` escapes only `"`/`\`; `lock_line_string_value` stops at first unescaped `"`. Round-trip of adversarial names with quotes/backslashes/controls would break, but dep names/versions are constrained charset (`c.<name>@<version>`); no in-repo caller passes such values. Survives refutation → no defect filed.

## T22 spec conformance — PASS
- `lock_restore_entry`: `registry` source errors pointing at With registry not-live + issue #547; `system` restores via `conan_write_known_system_package`; unknown source/name errors; conan path verifies cached `sha256` (`lock_cached_archive_matches`), hash-mismatch removes tree and errors, incomplete entries error before restore. Matches lock-pin semantics.
- `lock_load` on missing file returns empty; `lock_restore` errors on missing/empty lock with actionable message. `lock_sha256_file` returns `""` on missing file; callers treat empty digest as error. Correct.

## Probes
- Behavioral probes with `out/bootstrap/bin/with-stage1` (check/run): HELD — batch budget spent on full source read + commit/binary discovery (binary present at `out/bootstrap/bin/with-stage1`); no test project scaffolded. Static trace + caller refutation only.
- Negative controls: none executed (HELD, same reason).

## Verdict
Verdict: COMPLETE (no findings)
