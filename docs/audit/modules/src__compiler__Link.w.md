# Audit: src/compiler/Link.w @ 450733e5 — COMPLETE

Module: 1576 lines. Link stage: cc-driver and LLVM-lld link-command
builders (Darwin ld64, Linux ELF, Windows COFF, cross-target dispatch),
nm-based undefined-symbol probes driving on-demand runtime selection
(rt_core + platform rt + panic/regex/compat/fiber archives), embedded
runtime-object extraction, .wo embedded-bundle selection (D38/D39), temp
archive registry + cleanup, framework/lib arg mapping (#357), Windows
CRT-implicit lib drop, Linux sysroot/crt/gcc discovery, in-unit runtime
flag (D30 R2c), artifact path helpers.
Source SHA-256: `a99b2628aa701d42655c5cf1e4276feabc6f9a2ff645ab01004c8f467536922c`
(Full module read in-session, lines 1–1576.)

Applicable targets: T13 (ownership/drop), T15 (migration fidelity),
T22 (spec conformance).

## Findings

No defects. Candidate concerns raised and refuted:

1. (T13, src/compiler/Link.w:687-695) `link_stage_str_from_raw_parts`
   builds a `str` aliasing static embedded bytes via `unsafe` raw-pointer
   write, no copy and no visible free — refuted vs sibling discipline:
   `src/compiler/EmbeddedBundles.w:24-35` documents the identical "str
   view over an embedded blob (no copy)" idiom, and every Link consumer
   uses the view read-only by `&str` (`runtime_write_file`,
   `link_stage_extract_blob(data: &str)`, manifest prefix scans). No
   owned value crosses a boundary that requires a drop.
2. (T13, src/compiler/Link.w:116-121) `link_stage_result_for_plan`
   rebinds `var owned_plan = plan` then `move owned_plan.command` —
   refuted: D32 field-vacate comment is accurate; matches the `move`
   discipline at :794, :810, :1295, :1299, and the sole in-repo plan
   consumer (`src/compiler/Compilation.w:1172`) uses the plan once.
   All retained cross-struct copies go through `with_str_clone_ref`
   (registry :238, command inputs/outputs :322-348, :454-468, :505-550,
   :585-596, prefixes :983); `&`-borrowed params are never consumed.
   Shared temp-archive registry is atomically guarded
   (:58-63, :234-239, #617).
3. (T13/T22, src/compiler/Link.w:886-895) `..._need_fiber_runtime`
   returns 0 on `<probe-failed>` while helpers/compat/regex return 1 —
   refuted as a defect: worst case is a loud undefined-symbol link
   error, not a silent mislink, and the compiler-known async path
   (`needs_async_runtime`, :1325) still forces fiber on probe failure.
   A failed `nm` probe with a linkable object is pathological (probe
   and link read the same file); no caller depends on fiber-via-probe
   alone. Accepted asymmetry, not a finding.
4. (T22, src/compiler/Link.w:209-220 vs :528-538) suspected double
   `with_eprint` for `framework:` entries — refuted: the Linux-ELF
   builder inlines its own framework check (:530) and never calls
   `link_stage_lib_args`; the cc path (:340) and Darwin path (:461,
   `is_darwin=1`) each emit at most once per entry.
5. (T22, src/compiler/Link.w:419-436) `link_stage_linux_system_lib_path`
   only special-cases `z`/`zstd`/`xml2` — refuted: deliberate narrow
   fallback (absolute `.so.1` when unversioned `.so` is absent), every
   other lib keeps `-l<name>`; failure mode is a loud linker error.

## Probes run (seed `out/bootstrap/bin/with-stage1` — verified present via `ls`)

- P1 `with-stage1 check src/compiler/Link.w` — EXECUTED, `ok`, exit 0.
- P2 pub-fn probe (`use compiler.Link`, `run /tmp/link_probe.w`) — EXECUTED,
  exit 0, output verbatim:
  `fw1=[Metal]`, `fw2=[]`, `fw3=[]`, `darwin_fw_n=2`,
  `darwin_fw0=-framework`, `darwin_fw1=Metal`, `darwin_m0=-lm`,
  plus stderr `error: link: "framework:Metal" — Apple frameworks are only
  available on macOS targets` and `nondarwin_fw_n=0`.
  Confirms :198-220 (#357: prefix strip, `framework:`-only strip,
  `-framework Name` pair on Darwin, loud empty error on non-Darwin).
- P3 negative controls (live, same probe): bare `"m"` → `""` (not a
  framework); `"framework:"` (empty name, length guard :200) → `""`;
  non-framework `"m"` on Darwin → single `-lm` arg. All match the code.

## Negative controls (static, caller-verified with REGEX search)

- D30 R2c: setter `Compilation.w:1171` precedes the only plan call
  (`Compilation.w:1172`); Link honors the flag at :1347, :1382-1393,
  :1482-1496 (in-unit lanes link only fiber_asm.o / regex archive /
  cimport archive — no duplicate strong symbols).
- §18.5 cross: non-native routes to the LLVM plan (:780-794), flavor
  dispatch at :653-685, no embedded-object fallback for cross
  (:1125-1136, loud `run with build :cross-rt` error).
- D38/D39 bundles: abi-sha refusal (:1007-1012), target refusal
  (:1016-1021), interface-sha pairing check (:1024-1030), explicit
  `--link-bundle` dedup (:985-992, setter fed at Compilation.w:548),
  regex-runtime undef folded into selection (:1336-1342).
- #617 races: registry lock (:234-239), atomic extract-temp-rename with
  matching-reuse accept (:746-759, :950-965); process-exit cleanup calls
  in main.w:2698-2755.
- #650 units: sibling objects joined as full inputs (:1307-1310), undef
  detection spans every unit (:1317-1324).
- Windows: `m`/`c` dropped (:563, :597-608), `.lib` suffixing otherwise,
  archive wrap skipped on COFF (:1183-1184).

Caller searches used REGEX mode only (never literal-with-alternation).

READ ONLY: no compiler sources modified. No upstream issues filed.

Verdict: COMPLETE — no findings; T13/T15(N/A — no migrate logic)/T22 all pass, probes confirm.
