# Audit: src/compiler/LockFile.w @ 450733e5 — COMPLETE

Module: deterministic `.with/lock.json` handling (load/upsert/remove/write,
sha256 pinning, installed-C-dep tree walk, restore). 458 lines, read in full.

Targets traced: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.

## Probes run
1. `ls out/bootstrap/bin/with-stage1` — exists (114 MB, built Sep 3).
2. `with-stage1 --version` → `with v0.15.1.7-g450733e58` — matches commit
   450733e5, so this exact module compiled clean under stage1 (T13/T15 positive).
3. `with-stage1 check src/compiler/LockFile.w` → `ok` (exit 0). Ownership,
   `move` threading, and `&`/owned signatures typecheck.
4. Python simulation of the lock_write→lock_load line algorithm (conan +
   system entries, trailing `  }` / `}` closers) → ROUNDTRIP-OK: exactly
   `{c.foo, c.bar}`, no spurious empty-name entry.
5. Caller search (REGEX `lock_(load|write|upsert|restore|remove|sha256)` over
   `src/`): all in-repo callers in `src/main.w` (get/remove/update/restore
   paths, lines ~5308–5416); `src/LockFile.w` is a 6-line facade
   (`use compiler.LockFile`), no logic duplication (T15 clean).

## Findings
None. Suspected defects were raised and refuted:

1. (refuted) Spurious `""` entry from `}` closers — `lock_load`
   (LockFile.w:222-223) `continue`s when `current.name` is empty, so the
   unconditional upsert at LockFile.w:248-250 only fires while an entry is
   open. Simulation probe confirms.
2. (refuted) Whole-lock wipe on single-dep failure
   (LockFile.w:367,378) losing siblings — every caller in `src/main.w`
   (`5337`, `5409`) aborts (`return 1`) when `entries.len() == 0` before any
   `lock_write`, so a wiped lock is never persisted.
3. (refuted, note) Escape asymmetry: `lock_json_escape` (LockFile.w:47-54)
   escapes `"`/`\` on write but `lock_line_string_value` (LockFile.w:171-188)
   scans to the next raw `"`. Only reachable with quote/backslash inside a
   name, version, rev, or hex digest — impossible from in-repo callers
   (`c.<name>`, conan versions, hex hashes). Not a defect.
4. (refuted, note) `lock_upsert(lock: &LockFile, …)` called as
   `lock_upsert(move out.lock, …)` (LockFile.w:369) — same owned-into-borrow
   idiom used across `src/compiler/*.w` and `src/main.w`; `check → ok`
   proves it compiles. T13 ownership explicit throughout (`lock_entry_clone`
   via `with_str_clone_ref`, `LockDepWalk` threading `move`, #747 comment).

## Negative controls
- No `tests/` lock tests exist (`rg -ln 'lock_' tests/` → none); relied on
  stage1 `check`, version-match build evidence, and the round-trip simulation.
- `spec/` dir absent; T22 checked against in-code cite only: registry restore
  errors reference spec §18.8 + tracking issue #547 (LockFile.w:404-408).

Verdict: COMPLETE — no actionable defects in src/compiler/LockFile.w @ 450733e5.
