# Audit — `src/compiler/ConanClient.w`

Status: **COMPLETE** (1 low finding, 2 info notes)
Source revision: `450733e5` (verified via `git rev-parse` in `/home/shawn/workspace2/with`)
Source SHA-256: `887af2080782378ecdef2bb5fccfaa20da38313ed60c3de78dfc13539585513d`
Lines: 1158 (full module read in-session, lines 1–1158)

## Scope examined

Native Conan Center client: curl/tar argv builders, SHA-256 pinning,
hand-rolled JSON extractors (`json_extract_string`, `json_extract_string_array`),
version compare/hint matching, recipe-revision/package-revision resolution,
os/arch package picker (static-preferred), conaninfo requires parsing,
`package_info()` recipe reader for system libs/frameworks (#550) with
hand-maintained table override, binary install + locked restore + C-source
fallback installers, system-package writer, metadata.json writer.
Pub API: `conan_extract_recipe_link_metadata` (:621),
`conan_write_known_system_package` (:835),
`conan_restore_locked_binary_package` (:889), plus `conan_install` (:1157)
consumed via the `src/ConanClient.w` facade (`use ConanClient`, `src/main.w`).

Applicable targets: T13 (ownership/drop), T15 (migration fidelity),
T22 (spec conformance — §18.8 `with get c.X` behavior).

## Findings

1. src/compiler/ConanClient.w:492-508 (`conan_library_name_from_path`) | severity: low | target: T22 | probe: TRIGGER CONFIRMED on live data (no stage1 execution — fn is private)
   Versioned macOS dylibs leak the version into the link name: for
   `libz.1.dylib`, `conan_find_text(base, ".dylib")` finds offset 7, so
   `name = "libz.1"`, and the `lib`-strip yields `"z.1"`. Downstream
   `Link.w:219` emits `-l` ++ lib, i.e. `-lz.1`, which cannot resolve.
   Trigger files exist in real packages: the shared-macOS `zlib/1.3.1`
   binary (`2f813e31…`) contains `lib/libz.1.3.1.dylib`, `lib/libz.1.dylib`,
   `lib/libz.dylib` (fetched live 2026-09-04). The `.so` branch handles
   versioning correctly only because `.so` precedes the version suffix
   (`libfoo.so.1.2` → `foo`); the `.dylib` branch has the version before
   the suffix and needs trailing `.digits` stripping.
   Refutation attempt: NOT refuted. Caller chain is live —
   `conan_scan_libraries` (:521) ← `conan_write_binary_metadata` (:886) ←
   both install and locked-restore paths — so any macOS shared-package
   install with versioned dylibs hits it. Blast radius is bounded: failure
   is LOUD (linker `library not found for -lz.1`), macOS-only,
   shared-packages-only; static packages (e.g. the macOS `zlib` static
   binary ships only `lib/libz.a`) are unaffected.
2. src/compiler/ConanClient.w:395-405 (block brace counting) | severity: info | target: T22 | probe: RAN (live-data mirror, see P5)
   The package-block scanner counts `{`/`}` without string awareness, so a
   `{` or `}` inside a JSON string value would truncate/extend the block
   and could miss a match. No such braces exist in live search responses
   (verified on the full `zlib/1.3.1` response, 10 packages); miss direction
   is fail-loud (falls through to source fallback → loud error when
   unsupported). Robustness note only, not a defect.
3. src/compiler/ConanClient.w:918-919 vs 945-962 (requires recorded) | severity: info | target: T22 | probe: RAN (e2e installs)
   `conan_restore_locked_binary_package` stores RAW conaninfo requires
   lines in metadata.json while `conan_install_binary` stores RESOLVED
   `name/actual` refs. Refuted as a defect: conaninfo pins exact versions,
   so raw and resolved are textually identical, and the lock always carries
   the transitive closure (`lock_upsert_installed_c_dep_tree_seen`,
   `src/compiler/LockFile.w:356-380` recurses via metadata requires).
   No live divergence; noted for symmetry only.

## Refuted suspicions (not findings)

- R1 spacing fragility (`conan_block_matches_setting` :364-366,
  `conan_block_shared` :367-368): REFUTED by live data. The server
  pretty-prints (`"os" : "Linux"`, 4/4 Linux hits are variant-1, 0
  variant-2 in the live `zlib/1.3.1` search response), matching the first
  pattern arm; the compact arm covers non-pretty responses. Both arms
  justified; matcher returns the correct static pick (see P5).
- R2 `warning: no recipe metadata for zlib/1.3.1` during e2e: REFUTED —
  correct behavior. Live `conan-center-index` `config.yml` for zlib lists
  only `1.3.2` (1.3.1 pruned from the index though still hosted), so
  `conan_recipe_folder` rightly returns `""` and the module warns and
  falls back to scanned libs. The indexed 1.3.2 install fetches and
  extracts the recipe with no warning (see P6).

## Target traces

- T13 ownership/drop — CLEAN. All 40+ `Vec.push` sites audited one by one:
  borrows retained via `with_str_clone_ref` (110, 112, 114, 437, 564-slice,
  736, 738, 774, 803, 881, 1101, 1119); owned values (`slice`, `++`
  concatenation, literals, i64 frame counters) pushed directly (199, 271,
  564, 682-712, 737, 783-784, 794-803, 823-829, 870, 876, 883, 1096, 1117);
  owned locals moved once (`include_dirs_abs.push(source_dir)` :1098,
  `objects.push(obj)` :1110 — neither used after). `move Vec` in/out of
  `conan_sorted_insert_unique` matches sibling discipline (`src/Archive.w`
  report). Frame push/pop in the recipe reader is balanced on all paths
  (if/elif/else each push 5, pop-to-indent on every statement line);
  probes P2–P4 exercise if/elif/else/nested/unknown/framework branches
  with exit 0 and exact expected output.
- T15 migration fidelity — N/A (verified). Zero hits for
  migrat|compat|legacy|migration in the module; no shims. The only
  migration-adjacent surface is the `src/ConanClient.w` facade
  (`use compiler.ConanClient`); both import styles resolve — `main.w`
  via facade and `LockFile.w:7` direct — proven by `check` (P1) and the
  live `get` runs (P6).
- T22 spec conformance — CONFORMS except F1 (low). Spec §18.8 behaviors
  verified live: resolve → download → extract into
  `.with/deps/c/<name>/<version>/`, metadata.json with include paths,
  lib paths, lib names, requires; `with.toml` (`c.zlib = "1.3.1"`) and
  fully-pinned lock entry (recipe_rev/package_id/package_rev/sha256)
  written. Recipe extraction follows its documented contract (unresolvable
  conditions skipped, never guessed — P2/P4 prove if/elif/else,
  `in`-lists, framework pairs, option-gated and `and`-compound skips,
  conditional-expression skips); table override wins for the 4 listed
  packages (:751-760). No silent wrong-link path: every failure arm
  either errors loudly or warns and continues with scanned libs.

## Probes (seed compiler `out/bootstrap/bin/with-stage1`, `with v0.15.1.7-g450733e58`)

- P1 `check src/compiler/ConanClient.w` — EXECUTED, `ok`, exit 0.
- P2 `docs/audit/probes/conan_recipe_probe.w` (`run`) — EXECUTED, exit 0:
  Linux→[dl,m,pthread], Windows→[m,pthread,winmm], Macos→[m,other,pthread]
  (correct branch each way); frameworks→lib_paths [-framework,Cocoa],
  libs empty; option-gated append skipped (→[m]); system-package writer
  true/true/false/false for opengl/system, xorg/system, opengl/1.0,
  zlib/system. Metadata verified on disk (opengl libs [GL]; xorg 7 X libs
  sorted).
- P3 `docs/audit/probes/conan_recipe_negative.w` (`run`) — EXECUTED, exit 0:
  no-`package_info` → empty; arch-nested condition conservatively skipped
  (→[m], per documented never-guess contract); `x if c else y`
  conditional expression → empty.
- P4 live `get c.zlib@1.3.1` in `/tmp/conan_e2e` — EXECUTED, exit 0:
  resolved, recipe_rev `cac0f6daea04` (matches independent curl), binary
  `c81087b06d1a` (the predicted first static Linux/x86_64 match),
  downloaded, extracted, metadata (include/lib/z), lock + manifest
  written. Recipe warning shown (see R2).
- P5 live JSON shape check — EXECUTED: search returns
  `{ "results" : [...] }` with `name/version@_/_` refs (parse-compatible);
  package search returns a bare pkg-id→object dict with variant-1 spacing;
  a byte-level mirror of the module's scan over the real response yields
  the static Linux/x86_64 pick first. PASS (supports R1 refutation).
- P6 live `get c.zlib@1.3.2` in `/tmp/conan_e2e2` — EXECUTED, exit 0, no
  recipe warning; recipe fetched + extracted, contributed nothing (zlib
  declares no system libs — correct).
- P7 live macOS packages — EXECUTED (curl, read-only): static macOS zlib
  ships only `libz.a` (F1 unreachable); shared macOS zlib ships
  `libz.1.dylib` + `libz.1.3.1.dylib` (F1 trigger present).

## Negative controls

- N1 caller search redone in REGEX mode (`conan_(install|restore_locked_binary_package|write_known_system_package|extract_recipe_link_metadata|known_link_metadata|link_metadata_with_recipe)`
  over `src/ lib/ tools/`): true results — `conan_install` live at
  `src/main.w:5332,5405`; `conan_restore_locked_binary_package` live at
  `src/compiler/LockFile.w:435`; `conan_write_known_system_package` live
  at `LockFile.w:414` + internal `:1142`; `conan_extract_recipe_link_metadata`
  live in-module at `:768` (pub for tests/probes). F1's chain
  (`conan_scan_libraries` ← `conan_write_binary_metadata` ← install +
  restore) confirmed live, so F1 survives refutation.
- N2 slicing-ownership consistency: `json_extract_string_array:271` pushes
  `json.slice(...)` of a `&str` param directly, proving module-wide
  slice-is-owned semantics — the basis for clearing all bare-`push` sites
  in T13.
- N3 network-independent paths (P2/P3) re-ran green with no network use;
  network-dependent claims (P4–P7) each hit the live API independently
  (curl + stage1 paths agree on revisions and package pick).

READ ONLY: no compiler sources modified. Probes live under
`docs/audit/probes/conan_recipe_probe.w` and
`docs/audit/probes/conan_recipe_negative.w`; `/tmp` scratch (e2e projects,
tgz listings) left out of the repo. No upstream issues filed.

Verdict: COMPLETE — full module read (1–1158), regex caller search with true results, stage1 + live-API probes run; F1 low-confirmed (live trigger data, loud failure, macOS-shared-only), F2/F3 info-only, R1/R2 refuted with evidence.
