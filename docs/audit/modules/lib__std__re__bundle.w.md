# Primary verification — `lib/std/re/bundle.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 35 lines (single complete read)

## Scope examined

Bundle root for the migrated PCRE2 corpus (`docs/wo_bundles.md`, written by
`build/pcre2.w` pcre2-migrate): one `use` per corpus module (`:4–35`).
`pcre2test` and `pcre2posix` are deliberately excluded (harness, never bundle —
`build/pcre2.w:411`). Callers: `build.w:1607` (`wo_bundle_plan("pcre2", …)`).

## Behavioral matrix (all EXECUTED)

- Corpus-vs-bundle diff: `ls lib/std/re/*.w` = 35 modules; minus
  `bundle` (self), `pcre2posix`, `pcre2test` (harness) = 32 expected
  `use` lines; bundle contains exactly those 32 (`defs` + 31 `pcre2_*`).
  `diff` shows only the 3 intended exclusions. PASS.
- `out/bootstrap/bin/with-stage1 check lib/std/re/bundle.w` → exit 0
  (warnings only: redundant-unsafe-prefix style lints in corpus modules).
  PASS.
- `out/bootstrap/bin/with-stage1 check lib/std/re/pcre2test.w` → exit 0
  (build/pcre2.w:462 cohesive check: pcre2test imports pull in every
  module; replicated directly). PASS.

## Findings

None.

Verdict: COMPLETE
