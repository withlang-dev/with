# Audit: src/compiler/foundation/Mod.w @ 450733e5

- Commit: 450733e5 (`build: the regex runtime shim compiles pcre2...`)
- Module: `src/compiler/foundation/Mod.w` (12 lines)
- Scope: T13 ownership/drop, T15 migration fidelity, T22 spec conformance
- Stage1 used: `out/bootstrap/bin/with-stage1` (NOTE: `seed/out/bootstrap/bin/with-stage1` does NOT exist; the real binary is `out/bootstrap/bin/with-stage1`)

## Module summary

Umbrella module, full content (src/compiler/foundation/Mod.w:1-12):

```
// Wave 1 foundations umbrella module.

use compiler.foundation.Ids
use compiler.foundation.Arena
use compiler.foundation.Types
use compiler.foundation.Values
use compiler.foundation.InternPool
use compiler.foundation.Span
use compiler.foundation.Source
use compiler.foundation.SourceMap
use compiler.foundation.Diagnostic
use compiler.foundation.DiagnosticRender
```

Ten whole-module `use` decls covering every sibling in `src/compiler/foundation/`
(`Arena`, `Diagnostic`, `DiagnosticRender`, `Ids`, `InternPool`, `Mod`, `Source`,
`SourceMap`, `Span`, `Types`, `Values` — all except itself). No types, functions,
constants, globals, or logic of its own.

## Target traces

- T13 ownership/drop: N/A. The module declares nothing; there is no owned state,
  no move, no `drop`, no resource lifecycle to audit.
- T15 migration fidelity: N/A. Greenfield Wave 1 file (history: `de5a0af8 wave1:
  replace root modules and integrate foundation diagnostics`); no C source, no
  migration mapping, nothing to compare.
- T22 spec conformance: CONFORMS. Dotted-path `use` matches §18.2 import syntax;
  file-path module addressing matches §18.1 (optional `module` header absent, as
  allowed). `with-stage1 check` on the file returns `ok`.

## Refuted candidate (NOT a defect — recorded so it is not re-filed)

- Candidate: bare `use` is module-private per §18.3 (`No pub = module-private`),
  and no `pub use` idiom exists anywhere in `src`/`lib`, so the umbrella
  `Mod.w` cannot re-export and `docs/completed/with-selfhost-wave1.md:235`
  ("`src/compiler/foundation/Mod.w` exports stable API surface") is false.
- Refutation by probe: `use compiler.foundation.Mod` + `FileId` annotation
  type-checks `ok`, while the identical file with NO import fails with
  `unknown type 'FileId'` (src/compiler/foundation/Ids.w:6 defines
  `pub type FileId = i32`). Whole-module `use` therefore transitively brings
  the umbrella's imports into scope — the doc claim holds behaviorally.
  Regex search `foundation[./]Mod` (REGEX mode) finds zero in-repo code
  importers (only the doc line above), so the umbrella is live-but-unused API
  surface, not a broken one. Granular direct imports (used by all 10
  foundation modules and `src/InternPool.w`) remain the in-repo norm.

## Probes run

1. `out/bootstrap/bin/with-stage1 check src/compiler/foundation/Mod.w` → `ok`
2. `out/bootstrap/bin/with-stage1 fmt --check src/compiler/foundation/Mod.w` → exit 0
3. Umbrella transitivity: `/tmp/modprobe/umb.w` (`use compiler.foundation.Mod`,
   `FileId` annotation) → `ok`
4. Direct-import baseline: `/tmp/modprobe/direct.w` (`use compiler.foundation.Ids`)
   → `ok`
5. Negative control, no import: `/tmp/modprobe/noimport.w` → correctly fails
   `unknown type 'FileId'` (proves probe 3 is real re-export, not ambient fallback)
6. Negative control, bogus name: `/tmp/modprobe/bogus2.w`
   (`use compiler.foundation.Mod` + `TotallyBogusName123`) → correctly fails
   `unknown type 'TotallyBogusName123'` (proves the umbrella does not
   resolve arbitrary names)

## Findings

No defects found. Zero numbered findings — every candidate (T13, T15, re-export
efficacy) was either inapplicable to this declaration-free umbrella or refuted
by probe against in-repo siblings and stage1 behavior.

## Verdict

Verdict: COMPLETE — src/compiler/foundation/Mod.w conforms on T13/T15/T22 with no surviving defects.
