# D146 — The engine corpora live under `std.engines`; facades are named for their function, engines for their provenance, and neither maps onto the other (delegated)

**Date:** 2026-10-22. **Status:** delegated (D98): Eric's direction, the
wording and the layout are the agent's; a veto is a revert.

## Eric's direction

On the STC corpus landing as `std.stc` (#2556): "i don't agree with naming
the with facade 'stc' — that is the name of the 'c engine' but our with
facades are named for their function not for their provenance"; then
"these engine corpus should be grouped together, not placed directly under
std namespace"; then "there won't necessarily be a 1:1 mapping between
engine namespace and facade namespace."

## The rule

- A migrated C library (`with migrate` output, pinned, promoted, bundled;
  D37, D112) is an **engine**. Engines are one tier and live under one
  namespace: `std.engines.<library>`, named for the library they are:
  `std.engines.c_algorithms`, `std.engines.tommyds`, `std.engines.pcre2`,
  `std.engines.zlib`, `std.engines.stc`; their checked-in test corpora
  beside them (`std.engines.c_algorithms_testing`, `std.engines.stc_testing`,
  assembled at test time). The directory is the package: `lib/std/engines/<library>/`.
- A **facade** is the With surface and is named for what it does
  (`std.regex`, `std.zlib`, `std.collections.*`, `std.algorithms`), never
  for an engine. A facade draws on any engines it needs and an engine
  feeds any facades that want it: `std.collections` already composes
  c-algorithms and TommyDS, `std.algorithms` will draw on STC's sort beside
  `std.regex` on pcre2. No facade name implies an engine and no engine name
  implies a facade.
- A program never imports an engine; library maintainers do, from facades
  (§18.1's facade-import rule, #1362, stands over the new paths).

## What moved

`lib/std/{c_algorithms,tommyds,re,zl,stc}` → `lib/std/engines/{c_algorithms,
tommyds,pcre2,zlib,stc}`; the registry entries (`package`, `corpus_rel`,
`corpus_dir`) in `build/*.w`; every importer in the facades, tests, tools and
the build layer; the compiler's one path rule (the pcre2 exemptions in Sema
keep their scope: they are pcre2's, not every engine's); the specs. The
`.wo` bundle names (`pcre2.wo`, `zlib.wo`, …) and the corpus pins are
unchanged. pcre2 and zlib drop the `re`/`zl` abbreviations, which read as
facade names.

## What the others do

Rust's std has no migrated engines; Zig vendors C libraries under
`lib/libc`/`lib/libcxx` by provenance, apart from the std API; Go keeps
`internal/` packages apart from the public tree. The common shape: the
provenance-named implementation tier sits under one explicit directory, the
public API tier elsewhere.

## Mission fit

Law 1 and the facade ruling of 2026-09-12: the user reaches humane,
function-named surfaces; the raw engines are a maintainer tier, and one
namespace says so at every import. The flat `std.<library>` layout put the
engines beside the facades as peers, which is what read as "a facade named
stc".
