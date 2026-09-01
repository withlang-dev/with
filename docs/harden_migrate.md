# Hardening `with migrate`: from "works on pcre2" to "works on C"

Status: PLAN (2026-09-01, from the full-engine review). Nothing here is
implemented yet. Owner: Eric. Line numbers are anchors as of `6cd878d3`;
re-grep before editing — the function names are the stable references.

## Ruling context

The engine must contain **zero library-specific special cases**. Everything
in `src/CImport.w` / `src/CiMigrate.w` / `src/CiIR.w` / `src/CiPrint.w` must
be general-purpose C translation; per-library policy (file ordering, width
pruning, modeled-zone unsafe exemptions) belongs to the *caller* — CLI flags
and build scripts such as `build/pcre2.w`. pcre2 migration must keep working
throughout: the fix for a special case is the general mechanism it papered
over, never deletion-and-hope.

Review verdict, for orientation: the function-body translator is sound
(closed CiIR with no raw-text escape hatch, ANF value lowering, real
CFG + `std.cfg.stackify` goto elimination, fail-loud bottom). The rot is in
the type layer (strings), the decl layer (string concatenation), and a set
of text heuristics standing in for libclang API gaps. No from-scratch
rewrite. Each phase below lands independently and keeps pcre2 green.

## The battery (every phase's gate)

A phase is done when ALL of these pass, unchanged from before the phase
except where the phase's own goal says otherwise:

1. `with build :test` — includes the `c-migrator-basic`/`c-migrator-core`
   lanes and the five `test/migrate/*.c` regressions.
2. Full pcre2 re-migration from `.reference/pcre2` with the flags
   `build/pcre2.w` uses today; the migrated output **compiles** and the
   migrated test suite passes (the #880 methodology: never hand-edit
   output; a migrate fix is done only when the regenerated `.w` compiles).
3. Same for zlib from `.reference/zlib`.
4. `grep -in "pcre2\|raylib\|cliteral\|sljit\|zlib\|adler\|deflate" src/CImport.w src/CiMigrate.w src/CiIR.w src/CiPrint.w`
   — hits may only be **comments citing a discovery case**, never a code
   condition. This grep is the standing regression check for the ruling;
   each phase shrinks its hit list and no phase may grow it.

## Inventory: what must go, and what replaces it

### A. Type identity by spelling (the deepest class)

- `ci_type_is_small_int` / `ci_type_is_unsigned_small_int`
  (CImport.w:~4013-4028): C **integer promotion** decided by string-matching
  type spellings, with `PCRE2_UCHAR8` hardcoded into the list. Any other
  library's `typedef uint8_t byte_t;` silently gets wrong promotion — the
  sign-extension bug the function's own comment warns about.
- `CiPrint.w:~453-466`: scalar-copy vs `memcpy` assignment decided by
  `starts_with(name, "c_")` — a `c_`-prefixed aggregate typedef is silently
  scalar-copied. **This produces wrong code today** and outranks every named
  special case in severity.
- `CT_NAMED(spelling)` leaves in `CiTypePool.type_from_libclang`
  (CImport.w:~6285), `type_from_translated_text` re-parsing `"*mut "`
  prefixes back into the IR (~6435), and the function-scope type
  environment being `HashMap[str, str]` (`CiScopeState`, ~5367).

**Replacement (Phase 1): canonical types.** Resolve every typedef through
libclang's canonical type once at the boundary; carry `CiTypeId`
end-to-end; promotion/signedness/aggregate-ness are queries on the resolved
type, never on a spelling. The hardcoded name lists (including the
legitimate `uint8_t`/`c_uchar` entries — they're the same disease) all
delete. Acceptance: a fixture with `typedef uint8_t my_byte;` and
`typedef struct {...} c_thing;` migrates with correct promotion casts and
correct memcpy assignment; the `PCRE2_UCHAR8` lines are gone.

### B. One library's code hand-lowered in the engine

- `lower_cfprintf_effect_ir` (CImport.w:~5923-5980) + dispatch (~6083) +
  by-name rejection in value position (~10141): a ~60-line lowering pass
  for `cfprintf`, a function defined in **pcre2test.c**. Delete outright.
  pcre2test either carries a local shim (`#define cfprintf(c, ...)
  fprintf(__VA_ARGS__)`-equivalent in a forced include owned by
  `build/pcre2.w`) or the call fails loudly like any other untranslatable
  construct. A test driver is not the library; its migration convenience
  must not live in the engine.
- `CLITERAL` (CImport.w:~550, ~2828): raylib's compound-literal macro,
  matched by name with magic slice offsets. The general mechanism is
  compound-literal-through-macro handling from the AST (clang sees through
  it); if that's not reachable, fail loudly. Delete the name matches.

### C. Macro-prefix guessing

- `ci_expr_has_unresolved_string_macro` (CImport.w:~14215):
  `starts_with(ident, "STR_") or starts_with(ident, "STRING_")` — pcre2's
  internal macro-naming conventions deciding initializer routing.
  **Replacement:** ask the preprocessor record whether the identifier *was*
  a macro at that location (the macro session already exists —
  `with_cimport_parse_macros`), never guess from spelling.

### D. Destination-keyed semantics

- `ci_migrate_shared_defs_targets_regex_zone` (CiMigrate.w:~139) +
  consumers (CImport.w:~3726, ~8959, ~15634): `unsafe`-wrapping of
  modeled-libc calls and `__builtin_unreachable` lowering keyed to the
  output module prefix being `std.re`. **Replacement:** an explicit
  `--modeled-zone` CLI flag; `build/pcre2.w` passes it; the engine never
  sniffs destination names. Semantics identical for pcre2, declared instead
  of inferred.

### E. Orchestration policy in the engine

- `ci_migrate_pcre2_order_rank` (CiMigrate.w:~1199-1260): a 32-entry table
  of literal pcre2 filenames is the whole directory-ordering strategy.
  The order matters only because shared-defs dedup is first-sighting-wins.
  **Replacement:** make dedup order-independent — collect all renders per
  key, merge with prefer-concrete-over-opaque as a general rule (the
  `upgrade_opaque_type` string hack at ~163 is half of this already; make
  it structural), then emit. The table then deletes with no `--file-order`
  flag needed. Directory order becomes plain alphabetical.
- Width-slice `_16`/`_32` suffix pruning (CiMigrate.w:~34-56): silently
  deletes `sha_256`/`crc_32`/`utf_16`-style identifiers in any codebase
  when the flag is on, plus hardcoded `PCRE2_UCHAR16/32`, `PCRE2_SPTR16/32`
  names. **Replacement:** `--prune-decls <pattern-file-or-list>` supplied by
  the caller; `build/pcre2.w` owns the pcre2 width-family patterns. The
  engine keeps only the generic prune mechanism.
- `defs.w` header text "shared definitions for migrated PCRE2"
  (CiMigrate.w:~462): use the `--shared-defs` prefix in the comment.

### F. Silent text prostheses (make loud or make structural)

Ordered by wrongness-risk:

1. `normalize_output` global text replace `"-> void"` → `"-> Unit"`
   (CiMigrate.w:~400-406) — rewrites string literals too. Replace with
   emission-site fix (never emit `-> void`), then delete the replace.
2. `for`-clause partitioning by semicolon-scanning source text
   (CImport.w:~10460): a macro expanding to contain `;` mis-bins
   init/cond/inc. Use token-based clause extents from clang; where
   unreachable, detect ambiguity and bail loudly.
3. Global-initializer recovery by scanning the whole raw source for
   `name =` (CImport.w:~13820): name-keyed, breaks on shadowing/same-named
   statics. Key by cursor location, not name.
4. Six-way string-literal text cascade (CImport.w:~8595-8625) with
   heuristic guards tuned to pcre2 (#880): reduce to the token-based
   sources; when the survivors disagree, bail loudly instead of guessing.
5. The `>512`-element initializer cliff (CImport.w:~11269): one code path,
   not two; if the text path must stay for memory reasons, verify its
   output against the AST count and bail on mismatch.
6. `ci_string_text_contains_macro_like_ident` (CImport.w:~13228): ALL-CAPS
   heuristic flags `NULL`/`OP_ADD`-shaped identifiers; scope it to
   identifiers the macro session actually knows.
7. Name-keyed `ci_find_fn_cursor` linear scan (CImport.w:~16034): O(n²)
   and ambiguous for same-named statics; index once by location.

### G. Structural (after A-F; larger)

- Wire `CiDeclPool`/`ci_print_decl` (currently dead — reachable only from
  its own round-trip self-test) into the production path so signatures,
  structs, enums, typedefs, globals and module assembly stop being
  `Vec[str]` concatenation, `pub `-prepending line surgery, and the
  `@@DECL|` text-marker merge protocol. This also gives module-level
  output a verification surface.

## Phases

| Phase | Contents | Risk | Proof |
|---|---|---|---|
| 1 | A (canonical types) | touches promotion/assignment lowering everywhere | battery + new typedef fixtures |
| 2 | E-dedup (order independence), then delete the rank table | shared-defs output reshuffles once (diff review of pcre2 defs.w) | battery; defs.w semantically identical |
| 3 | D + E-width + B + C (policy extraction, deletions) | low — each is flag-plumbing plus a deletion | battery + the §Battery grep shrinks to comments-only |
| 4 | F (loud/structural prostheses), one item per commit | medium — each swaps a guess for a bail; expect new loud failures on constructs previously mistranslated | battery; any new bail on pcre2/zlib is a finding, not a regression |
| 5 | G (decl layer through CiIR) | high — big diff; do last | battery + `ci_ir_roundtrip_test` promoted to cover decls |
| 6 | Third-library proof: migrate a codebase never tuned against (sqlite3 amalgamation or lua) with **zero engine edits allowed during the run**; every failure files an issue against the general mechanism | — | the honest generality gate |

## Traps

- **Never hand-edit migrated output** to get a gate green; fix the engine
  and re-migrate (the #880 discipline).
- **One source of truth per contract**: the rt pointer-spelling rule
  (`ci_rt_ptr_mut`/`ci_rt_ptr_const`, CiMigrate.w:~565) is the pattern —
  when Phase 1 centralizes type identity, kill every second derivation it
  finds, don't leave both.
- The B11 `LEGACY` comments (CImport.w:~14390-14419) are fossils — the
  legacy string translator is gone and body-translation failure is already
  loud and fatal (CiMigrate.w:~1614). Don't "restore" a fallback while
  making prostheses loud; loud-and-stop is the contract.
- Fixture sprawl: each deleted special case gains a minimal `.c` fixture in
  `test/migrate/` reproducing the construct generally (not the pcre2
  spelling), per sweep-all-corpora discipline.
- `test/migrate` has five files against a 16.5k-line engine; every phase
  should leave it larger than it found it.

## Non-goals

- Macro model expansion (statement macros, X-macros, type-generic
  dispatch): the current "single well-typed expression or loudly
  untranslated" policy is a defensible general scope, not a special case.
  Revisit only after Phase 6 data says otherwise.
- Migrating C++ or GNU computed goto (`goto *`): already loud, stays out.
