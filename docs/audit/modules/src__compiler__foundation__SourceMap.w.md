# Audit: src/compiler/foundation/SourceMap.w @ 450733e5

Verdict: COMPLETE

Module: 68 lines. Registry keyed by FileId: sentinel slot 0 (`<invalid>`),
`path_index: HashMap[str, i32]`, `next_file_raw` from 1. Read with
`Ids.w` (FileId=i32, validity `>= 0`) and `Source.w` (`from_string` clones
path/text, line 20-26) as companion context.

## Targets traced
- T13 ownership/drop: `get_source -> &Source` (line 55) with sentinel
  fallback `&self.sources[0]` (line 57); `offset_to_location`/`line_text`
  chain the view (lines 63, 68). Insert keys cloned (lines 32, 43);
  `Source.from_string(path, text, id)` borrows then clones internally, so
  no use-after-move under consuming-`insert` rules. Sole in-repo caller
  `DiagnosticRender.w:20` binds `let src = sm.get_source(file_id)` as a
  view — no element copy, no drop-glue duplication.
- T15 migration fidelity: `git show d626c192 -- SourceMap.w` shows exactly
  the two `path.clone()` insert lines now at 32/43 (flip: `HashMap.insert`
  consumes view keys). `git show 96f12487 -- SourceMap.w` shows the
  `-> Source` to `-> &Source` fix now at line 55 with the double-free
  comment (53-54). Current text matches both landed intents; no deviation.
- T22 spec conformance: `contains` (47-51) rejects invalid ids and enforces
  `raw < sources.len()`; invalid-id fallbacks (`{0,0}` line 62, `""`
  line 67, sentinel line 57) are total and consistent; path-keyed dedup
  (26-28, 37-39) keeps first text.

## Findings
None. (No numbered defects — each candidate below was refuted.)
- Candidate C1 (T13): `path` reused after `path.clone()` insert — refuted:
  `.clone()` is a borrow-then-copy; `from_string` re-borrows `path`/`text`
  and clones inside (`Source.w:22-23`); probe compiles+runs clean.
- Candidate C2 (T13): `get_source` view dangles — refuted: returns
  `&self.sources[...]` tied to `&self`; caller holds `sm: &SourceMap`
  (`DiagnosticRender.w:8`); no copy, no second drop glue (per 96f12487).
- Candidate C3 (T22): dup-path silently keeps stale text — refuted vs
  callers and intent: registry is path-keyed by design ("keyed by FileId"
  line 1 + path_index); `source_map_test.w:13-14` pins dedup identity.

## Probes run (binary: out/bootstrap/bin/with-stage1; seed/out/... does NOT exist)
1. `with-stage1 run test/internals/source_map_test.w` -> `ok`, exit 0.
2. `with-stage1 run test/internals/source_map_crlf_test.w` -> `ok`, exit 0.
3. `with-stage1 run test/internals/source_map_utf8_crlf_test.w` -> `ok`, exit 0.
4. `with-stage1 run test/internals/diagnostic_test.w` (sole caller lane) -> `ok`, exit 0.
5. Custom `/tmp/sm_probe.w` (invalid-id fallback, `raw==len` OOB,
   dup-keeps-first-text, dual-view agreement) -> `probe-ok`, exit 0.

## Negative controls
- `contains(file_id_invalid())` and `contains(raw 999)` both false;
  `get_source(invalid).path == "<invalid>"`; `line_text(invalid)==""`.
- `contains(raw == sources.len())` false (strict `<` bound, line 51).
- Caller search (REGEX mode `get_source|add_source_text|SourceMap` over
  `src/`, `tests/`): only `DiagnosticRender.w` + self + unrelated
  `Frontend/Zcu add_source_text_mapping`; zero `tests/*.w` direct hits
  outside `test/internals/` (checked: no `tests/` dir hits; internals lane
  is the coverage).

## Caller/intent check
- `muse.search` REGEX sweep + `grep -rn -E` agree on single consumer
  (`DiagnosticRender.w:20-24`); no refuting caller.
- `git log -- SourceMap.w`: `d626c192` (flip clones), `96f12487`
  (view fix) both match current text; no migration-plan deviation.
- No issues filed (per instructions).

Verdict: COMPLETE
