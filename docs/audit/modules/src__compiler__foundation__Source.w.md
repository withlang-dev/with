# Audit: src/compiler/foundation/Source.w @ 450733e5

- Commit: 450733e58a1a7cce14f9cb2084943fc178815111 (verified via `git rev-parse HEAD`, short 450733e5)
- Module: src/compiler/foundation/Source.w (79 lines, full read)
- Imports: compiler.foundation.Ids only (FileId); one extern: with_fs_read_file(path: &str) -> str
- Re-exported by: src/compiler/foundation/Mod.w:9 (`use compiler.foundation.Source`, verified by read)
- stage1 binary: out/bootstrap/bin/with-stage1 exists (verified via `ls`, ran `--help` + 5 test probes)
- Verdict: COMPLETE

## Scope / targets traced

- T13 ownership/drop: from_string clones owned buffers (`path.clone()`,
  `text.clone()`, Source.w:22-23); line_offsets built owned by
  source_compute_line_offsets (Source.w:73-79, `offsets.push`, no extern).
  All observers borrow (`self: &Self`, Source.w:32,35,59). No
  `impl Copy for Source` anywhere (REGEX search hits only SemaSourceLocation
  and CXSourceLocation); the no-copy rule is load-bearing per
  SourceMap.w:53-54 ("an element copy would share them with the stored entry
  (double free)"), and SourceMap.get_source returns &Source (SourceMap.w:55-58).
- T15 migration fidelity: algorithm line-for-line identical to legacy root
  src/Source.w:23-83. Every surface delta traces to a landed commit:
  `self: &Self` receiver syntax (a27c9e3e eliminate-self migration),
  `.clone()` instead of with_str_clone_ref (d626c192 message names this exact
  seam), `offsets.push(...)` with the with_vec_push_i32 extern deleted
  (f67af6a9 message names src/Source.w + foundation/Source.w), `&str`
  extern ABI (7d8d085e), FileId (= i32, Ids.w:6) for file_id. Dropped root
  extras (`type Location` alias, no-op `deinit`, src/Source.w:21,85-88) have
  zero callers (see Callers).
- T22 spec conformance: byte-column, \n-split, strip-only-\n semantics pinned
  by in-repo goldens (source_map_crlf_test.w:15-16 expects line_text == "a\r";
  source_map_utf8_crlf_test.w:33-34; span_source_test.w:21-29).

## Probes run (all via out/bootstrap/bin/with-stage1 test)

- P1 test/internals/span_source_test.w -> `ok: 1 test passed` (PASS). Directly
  exercises foundation Source: line_count==4, offset_to_location(0)/(7),
  line_text 0/1/2, OOB line 99 == "".
- P2 test/internals/source_map_test.w -> `ok: 1 test passed` (PASS).
  Exercises Source through SourceMap: add/get, offset 5 -> line 1 col 1.
- P3 test/internals/source_map_crlf_test.w -> `ok: 1 test passed` (PASS).
  CRLF: offset 3 -> line 1 col 0; line_text keeps "\r".
- P4 test/internals/source_map_utf8_crlf_test.w -> `ok: 1 test passed` (PASS).
  Multi-byte + CRLF byte columns, trailing-CRLF empty line entry.
- P5 test/internals/diagnostic_test.w -> `ok: 1 test passed` (PASS).
  Downstream consumer (DiagnosticRender via SourceMap) green.
- N1 negative control /tmp/negctl/neg.w (`assert(1 == 2)`) ->
  `error: exit code 134`, `1 of 1 tests failed` (PASS: harness executes
  asserts, positives are not vacuous).

## Callers (REGEX-mode searches only)

- `Source\.from_string|Source\.from_file|offset_to_location|line_text` in
  src: foundation callers are SourceMap.w:21,33,44,63,68 (all via &Source
  views) and DiagnosticRender.w:21,24,34 (via SourceMap). Root-module
  callers (src/Diagnostic.w:130,134,145-149, src/CCodegen.w:359,8021,
  src/Codegen.w, src/main.w:2852, src/compiler/Zcu.w:295-352) resolve the
  legacy root `Source` (src/Source.w), NOT this module — parallel
  implementations, maintainer-chosen (root file header: "Root `Source` now
  follows the foundation implementation shape").
- `from_string|from_file|line_text|line_count|SourceLocation|file_id` in
  src/compiler/foundation: only Source.w, SourceMap.w, DiagnosticRender.w,
  Span.w, Ids.w. No other consumers.
- `\.deinit\(\)|Location\b` in src+lib+test: no `.deinit()` call on any
  Source; bare `Location` hits are unrelated (CXSourceLocation, http header,
  lib/std/compiler.w SourceLocation.new). Root `Location` alias and no-op
  `deinit` therefore have zero dependents.
- `line_count` has no in-repo callers (definition only); `from_file` is
  reached only via SourceMap.add_source_file (no golden covers it — noted
  below, not a defect).

## Findings

1. src/compiler/foundation/Source.w:22-23 — OK / T13+T15 / probes P1-P5 PASS /
   refuted (landed intent d626c192 names this exact fix: "owned struct-literal
   fields fed views (Arena str_value, Source path/text)... replaced with
   .clone()"): `path.clone()` / `text.clone()` on &str params is the
   post-#747 owned-str idiom (same spelling as SourceMap.w:32,43). No defect.
2. src/compiler/foundation/Source.w:73-79 — OK / T15 / probes P1-P4 PASS /
   refuted (landed intent f67af6a9: "offsets IS a Vec[i32]; it is now
   offsets.push(...) and the extern is gone"): method-form push, no extern.
   No defect.
3. src/compiler/foundation/Source.w:59-71 — OK / T22 / probes P1,P3,P4 PASS /
   refuted (goldens pin it: source_map_crlf_test.w:15-16,
   source_map_utf8_crlf_test.w:33-34 assert the "\r" is KEPT): line_text
   strips only trailing \n (byte 10). Byte-column contract documented on
   SourceLocation (Source.w:15-18). No defect.
4. src/compiler/foundation/Source.w:35-57 — OK / T22 / probes P1-P4 PASS:
   offset_to_location clamps (offset<=0 -> 0,0; over-long -> len), upper-bound
   binary search over line_offsets. Byte-column UTF-8 behavior pinned by P4
   (offsets 1/3/6/10/12). Negative-offset and over-long-offset branches have
   no dedicated golden but are 3-line clamps read-verified; no defect.
5. Deltas vs src/Source.w (pub, FileId, no `Location` alias, no no-op
   `deinit`, `self: &Self` receivers) — OK / T15 / refuted vs landed-commit
   intent (a27c9e3e receiver migration; FileId = i32 per Ids.w:6 so raw `0`
   args at Zcu.w-style call sites stay compatible) AND vs callers (zero
   callers of the dropped alias/deinit per Callers). Parallel root/foundation
   implementations are maintainer-chosen. No defect.
6. OBSERVATION (not a defect) / T22: `from_file` (Source.w:28-30) has no
   golden coverage (only reachable via SourceMap.add_source_file, itself
   uncovered); body is a 2-line delegate to from_string, read-verified.
   Empty-text line_count == 1 (offsets=[0]) and trailing-\n sentinel entry
   match the legacy implementation exactly (fidelity, not spec deviation).

## Negative controls

- N1 (above) fails as expected; positives not vacuous.
- Refutation attempts: every candidate delta was checked against both
  in-repo callers (REGEX searches above) and `git log/show`
  (f67af6a9, d626c192, 7d8d085e, a27c9e3e) before being cleared. No issues filed.

Verdict: COMPLETE
