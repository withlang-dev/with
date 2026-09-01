# Taming `with migrate`: a boring pipeline for 40 upstreams

Status: PLAN v2 (2026-09-01, revised after the SDLC ruling). Nothing here
is implemented yet. Owner: Eric. Line anchors as of `6cd878d3`; re-grep
before editing — function names are the stable references.

## The SDLC ruling (drives everything below)

Migrated code is a **pinned, regenerated artifact**:

- We NEVER modify generated code. Ever.
- Upstream ships a version we want → update the pin → re-migrate →
  fix integration fallout on the With stdlib side (the wrapper), not in
  the generated output.
- Two upstreams today (pcre2, zlib). **Target: ~40.** A pin bump must be
  a boring, reviewable, near-zero-touch operation, or the process does
  not scale.

This re-ranks what generated output must be good at. Nobody edits it, so
*human editability is not a goal*. In priority order, the output must be:

1. **Diff-auditable across re-migrations** — reviewing a pin bump IS
   reviewing the regenerated diff; a one-function upstream patch must
   diff as roughly one function.
2. **Debuggable** — migration bugs are found by stepping generated code
   against the C source; names, types, and control-flow shape must
   survive.
3. **Target-neutral** — one generated artifact for all targets, like the
   C source it came from (Windows is LLP64; everything else LP64).
4. **Total in coverage** — at 40 upstreams, every construct the engine
   can't handle is a blocked pin bump. Loud failure stays mandatory, but
   the failure *rate* is the scaling cost.
5. **Typed at the seam** — the wrapper integrates against typed
   signatures and named constants.

## Architecture decision record

**Considered: lower C to a compiler IR (LLVM IR / bytecode) and emit With
from that — "generic transpiler."** Rejected as the primary path:

- IR is not target-neutral: sizeof/alignof fold and ABI lowers at IR-gen
  per triple → a different generated library per target family (LLP64
  Windows vs LP64), violating goal 3.
- IR output is diff-unstable (temp numbering, block order, structurizer
  cascade) → violates goal 1; and decompiler-grade → violates goal 2.
- IR erases the typed seam (goal 5). Every maintainability-oriented
  transpiler we can point at (`.reference/translate-c` — Zig's
  next-generation translate-c on aro: typed C AST → Zig AST) sits at the
  typed AST; IR-emitters (llvm-cbe, decompilers) serve machines.
- What IR *would* buy — total coverage and semantic certainty — is
  obtainable inside the AST path via the two moves below.

**Adopted: post-expansion typed AST.** The preprocessor and Sema are the
"partial compilation"; we migrate what clang sees after them:

- **(i) Query clang, never re-derive C semantics.** We own the libclang
  bridge (rt/cimport_stubs + the wl_ bridge over static clang), so the
  "libclang API gap" is self-imposed. Expose canonical types, Sema's
  usual-arithmetic-conversions answers, token-accurate extents, macro
  provenance. Every place the engine currently guesses (promotion by
  type-spelling, sizeof-by-prefix, for-clause text binning) becomes a
  query.
- **(ii) Stop un-expanding macros.** Function-like macros inline at use
  sites — clang already expanded them; the engine's pre-expansion
  recovery (the six-way string cascade, STR_/STRING_ prefix guessing,
  stringify/paste machinery, the hand-rolled re-expander) exists only to
  make output *look like* the source. Under never-edit SDLC that is
  cosmetics purchased with exactly the fragility that breaks pin bumps.
  Deleting it lifts coverage (statement macros, do-while(0), X-macro
  output all become ordinary inlined code) and removes the largest
  heuristic surface in the engine. Object-like constants KEEP the
  trivial named-const path (`PCRE2_ERROR_*` — the wrapper needs the
  names). Config-family selection (pcre2 widths) happens where C says it
  does: the preprocessor (`-D PCRE2_CODE_UNIT_WIDTH=8` makes `_16`/`_32`
  code vanish via #if) — the general mechanism width-slice approximated
  with name pruning.

Costs accepted: expanded bodies where source had macro calls (bloat; an
upstream macro edit diffs at every use site — noisy but comprehensible),
and no macro abstractions in output. Both are acceptable for an artifact
nobody edits.

## Engine ruling (unchanged from v1)

Zero library-specific special cases in the engine
(`src/CImport.w`, `src/CiMigrate.w`, `src/CiIR.w`, `src/CiPrint.w`).
Per-library policy lives in the library's **recipe** (see below). The fix
for a special case is the general mechanism it papered over.

Standing grep gate — hits may only be comments citing a discovery case,
never a code condition; no phase may grow the list:

```
grep -in "pcre2\|raylib\|cliteral\|sljit\|zlib\|adler\|deflate" \
  src/CImport.w src/CiMigrate.w src/CiIR.w src/CiPrint.w
```

## The 40-library process shape: recipes

Each upstream gets a declarative recipe (the `build/pcre2.w` action is
the prototype; formalize the shape as data, one per library):

- pin: upstream repo + version/commit
- preprocessor config: -D defines (incl. config-family selection),
  include paths, forced includes (a library-owned shim header is the
  home for upstream-specific helpers — e.g. pcre2test's `cfprintf` —
  never the engine)
- migrate flags: --shared-defs prefix, --modeled-zone, --exclude,
  --no-c-export
- wrapper location (the With-side integration surface that absorbs
  bump fallout)
- validation: how to run the library's own migrated test suite

Pin-bump SDLC: bump pin → re-migrate → generated diff reviewed →
wrapper integration fixed → library suite green. Once recipes are data,
the bump loop is automatable per library (a build target per recipe:
re-migrate + compile + suite).

## Inventory of current violations (from the 6cd878d3 review)

Kept from v1, re-grouped by which adopted mechanism deletes each:

**Deleted by (i) canonical types / clang queries:**
- `ci_type_is_small_int` / `_unsigned_` (CImport.w:~4013-4028):
  integer promotion by type-spelling lists incl. `PCRE2_UCHAR8`.
- `CiPrint.w:~453-466`: scalar-vs-memcpy assignment by
  `starts_with(name, "c_")` — **produces wrong code today** on any
  `c_`-prefixed aggregate typedef; highest severity item in this doc.
- `CT_NAMED(spelling)` leaves (~6285), `type_from_translated_text`
  string re-parse (~6435), `CiScopeState` `HashMap[str,str]` (~5367).
- sizeof/alignof by source-text prefix (~7409); for-clause partitioning
  by semicolon-scanning (~10460); callee names by scan-to-paren
  (5 sites); name-keyed `ci_find_fn_cursor` (~16034) and
  whole-file-scan initializer recovery (~13820) → location-keyed.

**Deleted by (ii) post-expansion migration:**
- `STR_`/`STRING_` prefix guessing (~14215), the six-way string-literal
  cascade (~8595-8625), stringify/paste machinery (~13164-13443), the
  hand-rolled re-expander (~13100), `ci_string_text_contains_macro_like_ident`
  ALL-CAPS heuristic (~13228).
- Width-slice entirely (CiMigrate.w:~34-56, incl. the `_16`/`_32`
  suffix prune that would silently delete `sha_256`/`crc_32`-style
  identifiers in other codebases) → recipe-level -D selection.
- Macro-expression translation limits (variadic/statement-macro bails)
  stop mattering for function-like macros; object-like const path stays.

**Deleted by recipe extraction:**
- `lower_cfprintf_effect_ir` + dispatch + value-position rejection
  (CImport.w:~5923-5980, ~6083, ~10141): pcre2test's helper hand-lowered
  in the engine → pcre2 recipe's forced-include shim, or loud failure.
- `CLITERAL` name matches (~550, ~2828 — raylib!) → same treatment.
- `std.re` destination-prefix sniffing for unsafe/unreachable semantics
  (CiMigrate.w:~139; CImport.w:~3726, ~8959, ~15634) → explicit
  `--modeled-zone` flag in the recipe.
- `ci_migrate_pcre2_order_rank` 32-entry filename table
  (CiMigrate.w:~1199-1260) → dies with order-independent dedup (below),
  not by moving the table.
- `defs.w` header hardcoding "PCRE2" (~462) → use the prefix.

**Independent structural fixes:**
- Order-independent shared-defs dedup: collect per key, merge with
  prefer-concrete-over-opaque as a general rule (make the
  `upgrade_opaque_type` string hack at ~163 structural), then emit.
  Removes the ordering requirement entirely.
- `normalize_output`'s global `"-> void"`→`"-> Unit"` text replace
  (CiMigrate.w:~400-406) rewrites string literals too → fix emission
  sites, delete the replace.
- The >512-element initializer cliff (~11269): one path, or verify the
  text path against the AST and bail on mismatch.
- Wire `CiDeclPool`/`ci_print_decl` (currently dead) into production so
  module-level output stops being `Vec[str]` concatenation, `pub `
  line-prepending, and the `@@DECL|` text-marker merge protocol.

## Phases

| Phase | Contents | Proof |
|---|---|---|
| 1 | Bridge enrichment + canonical types end-to-end (mechanism i). Kills the promotion lists, the `c_` memcpy bug, the text prostheses. | battery + typedef/`c_`-aggregate fixtures |
| 2 | Order-independent dedup; delete the pcre2 rank table. | battery; pcre2 defs.w semantically identical |
| 3 | Recipe extraction: `--modeled-zone`, forced-include shims (cfprintf, CLITERAL), recipe files for pcre2 + zlib; delete the engine cases. | battery + grep gate shrinks to comments-only |
| 4 | Post-expansion migration (mechanism ii): delete recovery machinery + width-slice; pcre2 recipe switches to -D width selection. One-time large regeneration diff, reviewed. | battery; migrated suites green; engine line count drops |
| 5 | Decl layer through CiIR; remaining loud-not-guess fixes. | battery + decl round-trip coverage |
| 6 | Library 3: an upstream never tuned against (sqlite3 amalgamation or lua), recipe-only, **zero engine edits during the run**; failures file issues against general mechanisms. Then library 4... | the generality gate, repeated per new upstream |

Battery per phase (unchanged): `with build :test` (migrator lanes +
test/migrate fixtures), full pcre2 + zlib re-migration with output
compiling and their migrated suites passing, never hand-editing output,
plus the grep gate.

## Traps

- **Never hand-edit migrated output** to pass a gate (the #880
  discipline). Fix the engine or the recipe, re-migrate.
- One source of truth per contract (`ci_rt_ptr_mut`/`ci_rt_ptr_const`
  is the pattern); Phase 1 must kill second derivations it finds.
- The B11 `LEGACY` comments (~14390-14419) are fossils; the legacy
  fallback is gone and body failure is already loud and fatal
  (CiMigrate.w:~1614). Loud-and-stop stays the contract.
- Phase 4's regeneration diff is large by construction — review it as
  a semantic diff (suite-verified), not line-by-line; every later bump
  diff gets smaller because of it.
- Each deleted special case gains a general `test/migrate/` fixture
  (the corpus is 5 files against a 16.5k-line engine; every phase must
  leave it larger).

## Non-goals

- A second `--raw` IR-level tier (100%-coverage disposable port for
  bring-up). Coherent idea, out of scope until the recipe pipeline is
  proven on libraries 3+.
- C++ and computed goto: already loud, stay out.
