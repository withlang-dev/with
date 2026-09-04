# Audit: src/compiler/TrackedInputs.w @ 450733e5

- Commit: 450733e5 (verified via `git rev-parse --short HEAD`)
- Module: 181 lines, fully read
- Scope: T13 ownership/drop, T15 migration fidelity, T22 spec conformance
- Stage1: `out/bootstrap/bin/with-stage1` exists (ELF x86-64), used for all probes

## Callers (refutation base)

- `src/Sema.w:2503` (`record_tracked_input`), `src/Sema.w:2510`
  (`read_tracked_embed_file`, records dep only `if result.ok`)
- `src/CodegenTraits.w:1326`, `src/CodegenTraits.w:1329` (same ok-gated pattern)
- `src/compiler/Frontend.w:135` (`record_frontend_tracked_input`, `move` capture
  per #747 comment), `src/compiler/Frontend.w:1705`, `src/compiler/Zcu.w:443`,
  `src/compiler/Backend.w:73,153,214` (all `tracked_input_merge_unique` with `move`)
- `src/BuildGraphCache.w:290` (`tracked_input_insert_unique` for dep sorting)
- `src/ComptimeEval.w:2068` (reuses `tracked_input_insert_unique` for effect lines)
- `src/ComptimeEval.w:6310-6324` (`eval_embed_file_call`: arg-count +
  comptime-string checks, `self.fail` on `!read_result.ok`, embeds
  `read_result.contents` verbatim)
- `tracked_embed_resolve` (TrackedInputs.w:155): NO external callers (repo-wide
  rg confirms); the only production read path is `tracked_embed_read`, so the
  unenforced raw join is unreachable from user code.

## Probes run (all via out/bootstrap/bin/with-stage1)

- P1 repo positives PASS (6/6): `test/behavior/embed_file_basic.w`,
  `embed_file_internal_dotdot.w`, `embed_file_empty.w`,
  `embed_file_computed_path.w`, `embed_file_relative_module.w`,
  `const_str_embed_file_const.w`
- P2 repo negatives PASS (4/4): `test/behavior/embed_file_missing.w`
  ("could not read"), `embed_file_runtime_error.w` (comptime-only),
  `test/compile_errors/err_embed_file_absolute_path.w` and
  `err_embed_file_root_escape.w` ("outside the package root")
- P3 live /tmp probe: `sub/../main.w` self-embed through a normalized-in-root
  `..` prints source text — #585 behavior confirmed, no over-rejection
- P4 live /tmp probe (empty path): `embed_file("")` builds clean and embeds `""`
  (see F1)
- Negative control: P2 missing-file and escape cases still fail as expected after
  P3/P4 passes, so the containment gate is not vacuously accepting

## Findings

### F1 (Low, T22, probed-live): directory / empty path embeds "" instead of erroring

- Location: `src/compiler/TrackedInputs.w:179-181`
- `embed_file("")` resolves to the source directory itself (`tracked_dirname` +
  normalize), passes `tracked_inside_root` (path == root), passes
  `runtime_file_exists` (true for a directory), and `runtime_read_file(dir)`
  yields `""`, so `tracked_read_ok` succeeds with empty contents. Same applies to
  `embed_file("subdir")`. No caller validates: `ComptimeEval.w:6310-6324` checks
  only arg-count/comptime-string, and `tracked_embed_read` never calls
  `runtime_is_dir` (which exists in `src/compiler/Runtime.w`).
- Refutation attempt: searched all `read_tracked_embed_file` callers (Sema,
  CodegenTraits) and `eval_embed_file_call` — none pre-filter empty/dir paths;
  spec (`docs/with-specification.md:10185-10204`) says embed reads "a file" and
  errors when "the file does not exist" — a directory is not a file.
- Impact: benign (embeds empty string, still tracked), no soundness hole; fix is
  one `runtime_is_dir` / empty check. Severity Low.

## Refuted (not defects)

- R1 (T13): `parts.push(part)` at line 134 pushes a fresh `path.slice(...)`
  without `with_str_clone_ref` — correct (no alias; slice is a new owned value).
  The line-132 `with_str_clone_ref(part)` clone of a fresh slice is a harmless
  extra retain, released when the local drops. All Vec flows are `move`-balanced
  at every caller above; no copy/view residue (Frontend.w:133 documents the #747
  fix for this exact pattern).
- R2 (T13): `tracked_read_ok/error` borrow `&str` params and clone into the
  result; `prefix` (line 100) is dropped after `starts_with` — balanced.
- R3 (T22): `runtime_getenv("PWD")` anchoring (lines 172-175) is not spec-banned
  "consulting the environment": the embedded path still comes solely from the
  declared comptime arg; PWD only anchors the resolution base when the root is
  absolute and the resolved path relative. No input discovery occurs.
- R4 (T15): no seed-language counterpart of this logic exists in-repo (error
  strings unique to this module; `git log -S tracked_normalize_path` starts at
  fix #585 / #801 commits); the flat `keep`-flag shape (lines 124-134) is an
  intentional, commented workaround for the pre-#629 seed miscompile, and P1/P2
  behavior matches the in-repo tests. No fidelity gap observable.
- R5 (T22): `tracked_embed_resolve` returning an unnormalized, unenforced join
  is unreachable (no external callers) — not a bypass.

## Verdict

Verdict: COMPLETE with 1 Low finding (F1); T13/T15 clean, T22 conformant except F1.
