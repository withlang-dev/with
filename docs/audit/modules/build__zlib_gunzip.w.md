# Audit — `build/zlib_gunzip.w`

Status: **COMPLETE**
Source revision: `450733e5` (module predates it; `git log -- build/zlib_gunzip.w` last touches `0120a808`, `ae6b7e78`, `5cb48c36`, `6e73f5f7`)
Source SHA-256: `5fe717eda27eb31443d09ac50f034fd53d930e88d5bd13fbab24f1dec16d0915`
Lines examined: 1–122 (full module, single read)

Applicable targets: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).

## Verdict: COMPLETE — no defect findings

## Findings

### F1 — build/zlib_gunzip.w:61 — info — T22 — probe: executed (grep + live binary) — refuted as defect
`decompress_gzip_to_file` reports `"could not open output tar"` even though the
path is caller-supplied. Refutation: every in-repo caller always passes a
`*.tar` path (`build/zlib.w:283`, `build/seed.w:132`, `build/sdk.w` tar_path,
`build/pcre2.w:635`), so the wording is accurate on all live paths; cosmetic
only. No issue filed per instructions.

### F2 — build/zlib_gunzip.w:88–94,96 — info — T13/T22 — probe: executed (live binary) — refuted as defect
On failure after partial writes (write error, 8 GiB limit, corrupt tail) the
partial output file is left on disk, and `cleanup_stream` (45–51) ignores
`fclose`-flush errors on the success path, so an ENOSPC-at-close could return
`""/0` with a truncated tar. Refutation: all four callers gate on `rc != 0`
and abort before `extract_tar`, and `fopen(..., "wb")` truncates on retry, so
no caller consumes the partial file; a silently truncated tar still fails
closed downstream at the rc-checked `extract_tar` step. Best-effort cleanup
matches sibling convention (`build/pcre2.w:639`). No issue filed.

### F3 — lib/std/build.w:2217 vs build/zlib_gunzip.w — info — T15/T22 — probe: static (read both) — held, not this module's defect
Two gunzip implementations coexist: `build_zlib_gunzip_source`
(`lib/std/build.w:2217`, facade-based via `decompress_gzip_with_limit`,
whole-tar in memory, `StringBuilder` round-trip) used by the live
`Build.extract_tar_gz` std API, vs this module (direct `inflate` streaming,
4 MiB chunks) compiled by the four `build/*.w` lanes. Both enforce the same
8 GiB cap and the same CLI/rc contract (`<input> <output>`, usage rc=2, error
rc=1), so callers cannot distinguish them by contract; the difference is
memory profile and error-string text only. Convergence is a cross-module
decision outside this module's scope. No issue filed per instructions.

### F4 — build/zlib_gunzip.w:95–97,114 — info — T22 — probe: executed (live binary) — refuted as defect
Trailing garbage after `Z_STREAM_END` is ignored (success), and a 0-byte input
reports `"could not read input archive"` (conflating missing/unreadable with
empty). Refutation: archives are sha256-pinned before gunzip in the
zlib/pcre2/sdk lanes, so trailing-data tolerance is benign; a 0-byte input is
never valid gzip and still fails closed with rc=1. Live probes confirm both
error arms fire (`Z_BUF_ERROR` on truncation, `Z_DATA_ERROR` on garbage).
No issue filed.

## T13 ownership/drop — clean
- `check build.w` rc=0 and standalone `check build/zlib_gunzip.w` rc=0 confirm
  all moves/borrows; `&Vec[u8]` borrows (`bytes_data`, `decompress_gzip_to_file`)
  outlive the raw `source` pointer through the call.
- `cleanup_stream` frees `out_ptr` and closes `file` on every exit; `inflateEnd`
  runs exactly when `initialized=true` (init failure passes `false` at line 69,
  all post-init exits pass `true`). `let _end` / `let _close` ignore rcs:
  best-effort teardown, same pattern as siblings.
- `output_cstr` is used by `fopen` immediately while the local is alive (59).

## T15 migration fidelity — clean (consumer-only; module is hand-written, not migrated)
- Uses the migrated implementation directly (`std.zlib.defs`,
  `std.zlib.inflate`); `inflateInit2_(MAX_WBITS + 16, "1.3.2", ...)` (67)
  selects the gzip wrapper and matches the vendored zlib 1.3.2 per
  `docs/specs/std-zlib/recon.md:25`.
- `UINT_MAX`-clamped `avail_in` refill (77–82) pages arbitrary-length inputs
  through `c_uint` granularity; `Z_NEED_DICT` is correctly mapped to a data
  error (gzip never uses preset dictionaries); the no-progress terminator
  (104–106) matches zlib `Z_BUF_ERROR` semantics.

## T22 spec conformance — clean
- CLI contract matches all four callers: `argv.len() < 3` → usage + rc=2;
  errors print a message and return 1, which each lane's `run_capture` rc check
  turns into a lane failure. Interior-NUL output path rejected (56–58).
- Handoff expectation (`docs/completed/zlib-handoff.md:39`, helpers backed by
  the migrated implementation) holds: this module inflates via migrated
  `std.zlib.inflate`.
- No test file covers this binary: `grep -rn 'gunzip\|decompress_gzip_to_file'
  test/` returns zero hits (`test/behavior/behav_zlib_std.w` exists but
  exercises only the `std.zlib` facade). Coverage here rests on the live
  round-trip probes below, not on committed tests.

## Probes run
1. `out/bootstrap/bin/with-stage1 check build.w` → `ok`, rc=0 (package root;
   includes this module via `build.w:809,2827,2861,2973` inputs).
2. `out/bootstrap/bin/with-stage1 check build/zlib_gunzip.w` → `ok`, rc=0
   standalone (std-only imports; warnings only, from embedded `std.zlib`).
3. Built helper (`with-stage1 build build/zlib_gunzip.w`, rc=0) and ran live
   probes: 200 KB random-binary gzip round-trip byte-identical (`cmp`);
   10 MB random (10,001,559-byte archive, multi-chunk past the 4 MiB buffer)
   round-trip byte-identical; no-arg usage rc=2; truncated input →
   `"zlib output buffer is too small"` rc=1; garbage input →
   `"invalid or corrupt zlib data"` rc=1.
4. Caller search: sole live consumers are the four lane helpers in
   `build/zlib.w:274-288`, `build/seed.w:121-136`, `build/sdk.w:537-551`,
   `build/pcre2.w:620-635`; `build.w` declares the file as an input edge on
   four targets.

## Negative controls
- N1: truncated and garbage inputs produce distinct error strings with rc=1
  (not 0) — proves probes 3 exercise the real error arms rather than
  vacuously passing.
- N2: `test/` tree grep for `gunzip|decompress_gzip_to_file` is empty while
  `test/behavior/behav_zlib_std.w` exists — proves the no-test-coverage claim
  is a verified absence, not an unchecked assertion.
- N3: the 10 MB probe exceeds `ZLIB_CHUNK_SIZE` (4 MiB) while the 200 KB probe
  fits one chunk — proves the `avail_in` refill loop (77–82), not just a
  single-`inflate` path, was exercised.

Verdict: COMPLETE
