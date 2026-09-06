# Audit: src/compiler/BundleInterfaces.w @ 450733e5

- Scope: full module (104 lines). Targets: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.
- Commit verified: HEAD = 450733e5 (`build: the regex runtime shim compiles pcre2 ...`).

## Probes run
- P1 (callers): `grep -rn "bundle_interfaces_register_wi|bundle_interface_text|..." --include="*.w" src/` — callers found outside this module (registration/resolve path); no caller contradicts sentinel/overwrite semantics.
- P2 (spec refs): `docs/wo_bundles.md` exists; `load_link_bundles`, `embedded_std_resolve_path`, `module_source_read` references present in `src/`.
- P3 (sha callees): `sha256_hash_str` / `sha256_hex` definitions located via grep; call shapes at lines 24-25 match.
- P4 (stage1 exec): `seed`, `bootstrap/bin/with-stage1` absent; no `out/bootstrap/bin/with-stage1` binary — dynamic probe not feasible, static-only audit.
- Negative controls: empty-corpus call returns false (line 31-33); non-embedded/non-`.w` dotted-name returns `""` (lines 39-40); zero-section `.wi` returns count 0 so caller errors loudly (lines 100-104).

## Findings
No surviving defects. Candidates considered and refuted vs in-repo callers:
- R1 (T15, refuted): `BundleInterfaces.w:93-99` — a malformed `module` header with whitespace-only path trims to `""`, so the intervening chunk is silently absorbed into the next section instead of erroring. Only reachable on malformed `.wi`; producers emit well-formed headers and the count==0 loud-error covers the empty file. Not a migration defect.
- R2 (T13/T22, refuted): `BundleInterfaces.w:63-67` — `bundle_interface_text` returns `""` for both missing path and legitimately empty tail section (line 101). Callers use it only for paths already known bundle-provided, and `""`-as-absent matches the module's/siblings' sentinel convention (`bundle_module_dotted_name:37-45`). No caller distinguishes the two.
- R3 (T15, refuted): `BundleInterfaces.w:30-34` — `bundle_corpus_contains` does not normalize a trailing-slash corpus (`std/re/` matches nothing). No caller passes trailing slashes (`--bundle-corpus std/re`, `std/wi_demo` per line 27-29). Out-of-contract input.
- T13 ownership holds throughout: map insert clones key+value (`78-79`); all `str` returns clone out of the map/slice (`67`, `76`); section slices (`95`, `101`) are fresh values moved into the map. No drops/leaks vs sibling convention.

VERDICT: COMPLETE — src/compiler/BundleInterfaces.w @ 450733e5
