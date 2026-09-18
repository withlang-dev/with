# Audit: build/abi.w @ 450733e5

Scope: read-only source audit of `build/abi.w` (61 lines) at commit 450733e5.
Targets traced: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).
Compiler: out/bootstrap/bin/with-stage1 (seed compiler).

## Module summary
Build-graph action enforcing docs/with-abi.md §7 / D38: `run_abi_hash_check_action`
reads `docs/with-abi.sha256` (shasum format), compares each recorded sha256 against
`fs.sha256_file(path)` for `src/FnAbi.w` + `src/TypeLayout.w`, fails the battery on
mismatch/malformed-record/missing-record, writes `ok N files` to the action output.
Wired in build.w:2357-2364 (`.Action "abi-hash-check"`, inputs = the two sources +
the record, `write_scope("out/abi-hash-check")`) and `tests.dep("abi-hash-check")`
(build.w:2593). Helpers: `abi_owned_text` (&str -> owned copy), `abi_split_lines`
(\n split preserving no-trailing-newline tail).

## Target disposition
- T13 ownership/drop: CONFORMANT. `abi_owned_text(s): s ++ ""` is the house idiom,
  repeated verbatim in build/clang_resource.w:14, build/zlib.w:4, build/selfhost.w:9,
  build/wo.w:39, build/runtime.w:5, build/seed.w:5, build/sdk.w:7, build/retention.w:6.
  Copies (`expected`, `path`) die at loop-iteration end; `report` accumulation via
  `++` matches repo-wide owned-string practice; no manual memory ops, no extern
  fns, drop glue compiler-owned. `with-stage1 check build/abi.w` -> `ok`.
- T15 migration fidelity: NOT APPLICABLE (no migrated logic). Per `git log --follow`,
  build/abi.w is a new file in ed75bb1a (single commit); build.w gained only the
  target wiring + `:test` dep in the same commit. No duplicated/forked check logic
  remains in build.w (grep `abi_hash_check` hits only build.w:2357-2364 wiring).
- T22 spec conformance: CONFORMANT (see probes). The §7 "both files" hash scope is
  landed-commit intent, not under-coverage: ed75bb1a moved the §4-5 rules into
  src/FnAbi.w as pure functions (Codegen keeps one-line adapters), and with-abi.md
  §7 "Enforcement (implemented)" + "Not yet under the hash" paragraphs document
  exactly this scope (§3 headers in rt/rt_core.w, §6 drop glue in
  CodegenDispatch.w deferred to the wo-drift lane until D30 retires the in-unit
  runtime). Refutation attempt (claim: hash must cover Codegen.w/rt_core.w):
  refuted by spec text + commit message ("Verified: a tampered record fails, the
  real one passes"). Error paths are fail-closed: missing/empty record -> error;
  `sha256_file` returns "" on missing file (lib/std/build.w:903-906) -> "cannot
  hash" error (empty digest unforgeable); comment/blank-only record -> "records
  no files"; CRLF or `*`-marker input cannot silently pass (split on "  " rejects
  binary-marker lines as malformed; trailing \r makes the digest mismatch ->
  error, never a pass).

## Findings
No defects. (No numbered findings: every candidate below died in refutation.)
1. Candidate (T22, minor): `line.split("  ")` rejects filenames containing double
   spaces and binary-mode `shasum -b` (`*` marker) lines — refuted: record is
   produced by `shasum -a 256` text mode per doc (two-space separator, paths
   `src/FnAbi.w`/`src/TypeLayout.w` contain no double spaces); rejection is a
   loud error, not a silent pass. Not filed.
2. Candidate (T22, minor): `record.len() == 0` conflates missing and empty files;
   `checked == 0` conflates empty and comment-only records — refuted: all three
   states error out with distinct messages; no acceptance-path divergence.
   Not filed.

## Probes run (seed out/bootstrap/bin/with-stage1, linux-x86_64)
- P1 `with-stage1 check build/abi.w` -> `ok` (typecheck).
- P2 `with-stage1 build :abi-hash-check` on clean tree -> `survey: all targets
  green` (positive control; `shasum -a 256 src/FnAbi.w src/TypeLayout.w` matches
  docs/with-abi.sha256 byte-for-byte, verified independently).
- N1 tampered record (scratch worktree @450733e5, first digest nibble flipped) ->
  action exit 1, `abi-hash-check: an ABI-defining source changed ...` + bump/
  re-record remediation; `survey: 1 target(s) failed: abi-hash-check`.
- N2 malformed record (appended `this-is-not-a-valid-line`) -> exit 1,
  `abi-hash-check: malformed line in docs/with-abi.sha256: ...`.
- Repo sources untouched throughout (negatives ran in throwaway worktree
  /tmp/abi-neg-tamper, removed afterwards; `git worktree list` clean).

Verdict: COMPLETE
