# Audit — `src/compiler/EmbeddedBundles.w`

Status: **COMPLETE**
Source revision: `450733e5` (workspace `/home/shawn/workspace2/with`)
Source examined: full module, 109 lines (single read, complete)

## Scope examined

Embedded `.wo` bundle accessors and manifest parsers (docs/wo_bundles.md, decisions D38/D39):
blob-view constructor, count/name/manifest/interface/present accessors,
`prefix <p> <path>` line parsers, aggregate prefixes, raw address pairs.

Applicable targets: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).

## Callers traced (all in-repo users)

- `src/compiler/Compilation.w:25,563-585` — `register_embedded_bundle_interfaces`
  uses `embedded_bundle_count/name/manifest_text/interface_text/present`,
  `bundle_manifest_prefixes/paths`; `:523` explicit `--link-bundle` path uses prefixes.
- `src/compiler/Link.w:3,996-1032` — `link_stage_select_embedded_bundles` uses
  count/present/manifest+object address pairs/interface text; `:986` explicit-bundle
  check uses `bundle_manifest_prefixes`.
- `src/Codegen.w:22,953` — stores `embedded_bundle_prefixes()` as decl filter.
- `build/runtime.w:255-287` — `br_generate_embedded_bundles` generates the
  `*_data` accessors this module calls.

## Findings

None. Zero defects survived refutation. (No numbered findings.)

## Target-by-target basis

T13 ownership/drop — PASS. `embedded_blob_view` (:26-35) aliases the static blob
(no copy) via the same unsafe `{ptr,len}`-into-`str` idiom Link.w uses at
`src/compiler/Link.w:689-695` for all embedded slices — established idiom, not a
one-off. Every retention site clones: both parsers push only
`with_str_clone_ref` copies (:65, :85); Compilation/Link/Codegen consume the views
transiently (sha, field scan, parse) and keep only the clones; Link reads object
bytes via raw `link_stage_embedded_obj_slice`, never a `str` view. Empty/out-of-range
index yields `""`/0 from the generated layer, and `present` (:44-45) is false —
no panic, no consult. Live probes (P3/P4) linked and ran with no corruption.

T15 migration fidelity — N/A (native compiler source, no migrated corpus). Closest
analogue verified: writer/reader format agreement — `Compilation.w:1315` emits
exactly `"prefix " ++ prefix ++ " " ++ canonical ++ "\n"`, which is what
`bundle_manifest_prefixes` (:59-65) and `bundle_manifest_paths` (:79-85) parse.
Degenerate inputs are safe: `"prefix "` (empty rest) skipped via `sp > 0`;
missing trailing newline handled by the `end == len` scan; `"prefix foo"`
(no path) yields a prefix but no path, matching the writer which never emits it.

T22 spec conformance — PASS. Header claims (:1-14) each trace to code: D39
registration-before-resolve is Compilation `:562-579` via `present`/`interface_text`;
on-demand link selection + abi-sha gate is Link `:994-1030` via the address pairs
and `embedded_bundle_interface_text`; empty-slot rule is `present` + the
`continue` guards at Compilation `:564` and Link `:1001`. Generator/accessor names
match exactly (`manifest_start/end`, `object_start/end`, `interface_start/end`
map to blobs `manifest`/`o`/`wi` at `build/runtime.w:281-285`); zero-bundle builds
degrade to count 0 with no externs, as `build/runtime.w:253-254` states.

## Probes run

- P1: `ls` — requested `seed` and `bootstrap/bin/with-stage1` do NOT exist
  (verified, not assumed); actual binary `out/bootstrap/bin/with-stage1` exists,
  `--help` exits 0.
- P2: `strings` on stage1 — 12 `with_embedded_wo_*` hits (pcre2 o/manifest/wi
  start+end, plain and underscore-prefixed); embedded `prefix `/`abi-sha`/
  `interface-sha` manifest lines present — the pcre2 slot is filled in stage1.
- P3 (end-to-end): `use std.regex.Regex` program compiled, linked, and ran under
  stage1 — exercises `present`, interface registration, prefix selection, abi-sha
  check, and object extraction end to end. Clean link + run.
- P4 (negative controls): regex-negative probe (`"b"` vs `"aaa"` → None, correct);
  regex-free harness (`HARNESS-OK`) — harness validated independently of bundles.

## Out-of-scope observation (NOT a finding against this module)

P3/P4 anomaly: `Regex.compile("a+").find("aaa")` and `.is_match("aaa")` return
None under stage1 (fully non-functional matching; negative control correct).
Refutation vs this module: the clean link+run in P3 proves this module delivered
the right bytes (wrong object/interface/prefix data fails the abi-sha/pairing
checks or the link itself); no code path here can alter match values at runtime.
Root cause lies below this module (pcre2 bundle content or `rt/regex_runtime.w`
marshalling) — referred to the owner, not filed.

Verdict: **COMPLETE**
