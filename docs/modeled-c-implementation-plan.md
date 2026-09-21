# Modeled C Implementation Plan (D51)

## Authority and scope

This is a derivative execution plan for D51. The controlling text is
`docs/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md`
(the ruling); the specification carries its conforming projections
(`docs/modeled-c-spec-projection-draft.md` until blessed, then
`with-specification.md` §16.2b and the sentences it replaces). This plan
cannot amend either. Where this plan and the ruling disagree, the ruling wins
and this plan is wrong.

**Order of operations, fixed by the ruling and by CLAUDE.md.**
1. Spec words are blessed and land (spec leads). Until then the compiler is
   NON-COMPLIANT and no facade code is written.
2. The stages below, each an iterate-tier change with its own tests, batched
   for the battery by blast radius (§ Batching).
3. The SQLite facade (ruling §66) is written against the real `sqlite3.h` and
   must compile before any example, release UAT fixture, blog sample or
   documentation example is rewritten against the new surface.

Target, restated from the ruling in one paragraph: a `c facade name:` block of
ordinary With syntax after `use c_import(...)` states semantic facts about
imported declarations. The core abstraction is the resource (opaque pointer,
in-place struct, by-value token), never Copy, owning a foreign representation
with a designated `drop` and any alternate `destroys`. Explicit facade clauses
override adopted-profile facts, which override conservative defaults; ABI and
header facts and proven contradictions constrain all. Every fact has
provenance that diagnostics and `with analyze` expose. Silent inference is
allowed only where being wrong removes capability. Never half-model unsafely.

## What exists today (the two mechanisms this plan unifies)

Verified at be767c0b; line numbers are of that tree.

**The import record.** `use c_import(...)` parses into one `NK_C_IMPORT` node
(`src/Parser.w:2489-2693`): `link`, `allow_untranslated`, `no_methods` packed
into `d2`, then `strict`, `only`, `owns`, `borrows`, `retains` appended to the
extra pool in a fixed record. `retains:` is read by Sema
(`Sema.w:2483-2516 read_c_import_retentions`, called from
`SemaDecl.w:281-282`) into `retained_extern_params` and consulted per
parameter at `SemaCheck.w:15788`. `owns:`/`borrows:` are read by the Frontend
and handed to CImport as process globals for the duration of translation
(`Frontend.w:440-450`, `CImport.w:56-65`). Two threading paths; the facade
takes the Sema-side one, because facts need spans and provenance.

**The generated-text path.** CImport turns C declarations into With source
text (`CImport.w:773-825`), which the Frontend registers as a synthetic file
`<c_import HEADER>`, parses into the same pool and splices with
`decl_is_c_import = 1` (`Frontend.w:480-536`). Sema's `build_ci_scoping`
(`SemaDecl.w:563-606`) puts every c_import symbol in `ci_syms` and, for
functions, calls `ci_function_requires_raw_abi` (`SemaDecl.w:726-765`): raw
if variadic, if the return is a pointer not vouched by
`ci_overlay_return_is_borrowed_ptr` (five libc names, `:692-698`), or if any
parameter is a pointer other than a `const char *` input (D47). A hit lands
the symbol in `ci_raw_syms`, read at the call site by
`fn_symbol_is_raw_c_import` (`SemaCheck.w:6150`) → "raw c_import function
call requires unsafe context" (`SemaCheck.w:15848-15856`).

**Mechanism A, the #357 owning wrapper** (`CImport.w:1608-1645`
`ci_emit_owning_wrapper`): for a hardcoded table of libc constructors
(`strdup`, `strndup`, `fopen`, `fdopen`, `tmpfile`, `opendir` → their
destructors, `:1433-1446`; `readdir`/`rewinddir` borrow `opendir`'s result,
`:1453-1460`) it emits two renamed externs, `type COwned_<fn> { handle }`,
`impl Drop for COwned_<fn>` calling the destructor inside `unsafe:`, an
**`unsafe fn`** constructor (the template hardcodes `"unsafe fn "` at `:1643`
because no fact says the raw parameters are safe), and a `.handle()` accessor
that hands back the raw pointer. Everything downstream stays `unsafe`.

**Mechanism B, §16.2a auto-methods** (`CImport.w:1856-2137`
`ci_detect_member_functions`): snake_case-prefix detection on the first
parameter's struct type emits `impl S:` forwarding methods (`mut fn` for
`T *`, `fn` for `const T *`, `unsafe` when any type is raw) and a static
constructor `fn S.<name>` for a function returning `*S`. **No `Drop` is
generated** (the constructor leaks); the spec's "longest prefix wins" and
`Type(args)` sugar are not implemented.

**Every imported struct is Copy** (`CImport.w:2310-2311 impl Copy for`), and
Sema forbids `Drop` on a Copy type (`SemaDecl.w:2470-2477`). A resource over
a by-value representation is therefore a distinct non-Copy wrapper struct, as
`COwned_*` already is over a pointer.

**What Sema already provides for resources.** `impl Drop` collection with
`move fn drop` enforcement (`SemaDecl.w:1559-1566`, `2408-2478`),
`type_has_drop_impl` (`Sema.w:5585`); ephemeral types
(`TDK_FLAG_EPHEMERAL`, `ephemeral_types`, `type_is_ephemeral_value`
`SemaCheck.w:23654`); view origins per binding (`BindingProvenance`
`Sema.w:53-64`, `record_view_binding_from_expr` `SemaCheck.w:10160`,
`set_binding_view_deps` `Sema.w:5380`); §21.1 Rule 6 and Rule 7 diagnostics
(`Sema.w:5734`, `5752`); the return-escape and heap-escape checks
(`SemaCheck.w:10412`, `5419`); the struct-field ban on ephemerals
(`SemaDecl.w:402`, `817`). Verified by running on 2026-09-20: a child
`ephemeral { db: &Db, … }` with `Drop` on both drops before its parent,
cannot be returned past it, cannot survive the parent's move, cannot be
stored. No lifetime machinery is added by this plan.

**`CStr`.** Builtin `{ptr, len}` (`Sema.w:2547-2554`) with `len()`, `ptr()`,
`to_owned()` and `unsafe fn CStr.from_ptr` (`lib/std/string.w:100-117`).
`to_str()` (validating) and `to_str_lossy()` do not exist.

**`with analyze`.** One `AnalysisReport` of `AnalysisFact` rows
(`AnalysisTypes.w:120-141`), collected by `analysis_collect_sema`
(`Analysis.w:707-719`), rendered by `facts`/`select:`/`matrix:`/`explain:`
(`Analysis.w:1936-2032`). No contract view.

**Runtime foreign calls.** ~500 hand-written `extern fn` lines across
`rt/*.w` and `lib/std/libc.w`; no contract data.

## Design decisions this plan makes (execution detail, not semantics)

- **Facts live in Sema, not in the text generator.** A `ForeignContract`
  table on `Sema`, filled in Pass 3 beside `read_c_import_retentions`, keyed
  by (declaration sym, parameter index | return | resource) with value,
  provenance (`abi` | `proof` | `facade:<name>` | `profile:<pkg>:<rule>` |
  `default`) and the clause's span. `retains:` becomes a writer of the same
  table (D4 compatibility, deprecated).
- **Raw classification consults the table.** `ci_function_requires_raw_abi`
  returns 0 for a parameter or return covered by a fact; this is the single
  gate that makes a modeled call safe. `SemaCheck.w:15788`'s per-parameter
  consult generalizes to `lend` / `consumes` / `retains … by` / `destroys`.
- **Resources render to ordinary With.** A resource is `type R { repr }` +
  `impl Drop for R` (`move fn drop` calling the designated destroyer inside
  `unsafe {}`) + a safe constructor whose raw call sits in an inner
  `unsafe {}` (the shape the #379 buffer wrapper already uses,
  `CImport.w:1599`), never `unsafe fn`. A dependent child is
  `type C = ephemeral { parent: &P, repr }`. Alternate destroyers are
  `move fn` methods. Rendering happens after facts are read (a second
  Frontend splice, or emission from Sema facts); Mechanism A's generator and
  its `#owns:`/`#borrows:` cache-key lines retire with it.
- **Presentation stays a generator, retargeted.** Mechanism B attaches
  methods to the resource type (`self.repr`), with `of` / `rename` from facts
  overriding prefix detection and multi-resource representations failing
  closed without `of`.
- **Parameter references resolve once.** `param name | N | type T` resolve
  in Sema against the imported signature; every diagnostic prints the
  resolved C parameter (ruling §57).

## Stages

Each stage is an iterate-tier change (`with check src/main.w`, `with build
:dev`, targeted tests) with its own behavior and compile-error tests. "Flip"
names existing tests whose expectation changes; a stage is not done until
they are rewritten in the same batch (never left red, never deleted).

**Stage 0 — spec text lands.** The blessed §16.2b and replacements land in
`with-specification.md`; `spec-inventory-check` (`build.w:1822`) is updated
for the new keywords and any inventoried CLI request in the same batch, or it
goes red. No compiler change.

**Stage 1 — parser and AST.** `c facade name:` as a new top-level declaration
kind (d0 = facade name, d1 = extra_start, d2 = clause count), parsed by a
`parse_c_facade_block` modeled on `parse_impl_block`
(`Parser.w:3074-3316`); `resource`, `fn`, `domain`, `use convention` as
spanned child nodes; clauses (`wraps`, `from`, `init`, `preinit`, `drop`,
`destroys`, `ok`, `borrows`, `independent`, `lend`, `consumes`,
`destroyed_by`, `retains … by`, `returns borrow|static`, `preserves`, `of`,
`rename`, thread capabilities, `callback_thread`) as spanned records;
`param name|N|type T` parsed, unresolved. `c` and `facade` are a two-token
lookahead at top level or new keywords — decide with the blessed grammar.
Tests: parse errors for each malformed clause. Flip: none.

**Stage 2 — facts with provenance.** The `ForeignContract` table; Pass-3
collection; ruling §61 verification (declaration exists, representation
resolves, parameter references unique, destroyer accepts the representation,
producer return/out-parameter matches, status constant is a c_import `let`
with a literal initializer, callback parameter callable, `consumes` target
compatible, domain exists, thread combination legal — `send` requires
`drop_any_thread`); §57 diagnostics printing the resolved C parameter;
`retains:` rewritten as a writer of the table. Tests: one compile-error test
per §61 check; `behav_retained_cstring_owned_ok.w` and
`err_retained_cstring_str_temp.w` keep passing through the table, and
facade-form twins are added. Flip: none.

**Stage 3 — raw classification consults facts.** `ci_function_requires_raw_abi`
returns 0 for covered parameters and returns; the per-parameter consult at
`SemaCheck.w:15788` handles `lend` (default, asserted), `consumes` (move,
suppress Drop), `destroys` (move, terminate), `retains … by`. Tests: a
facaded call compiles with no `unsafe`; the same call without a facade still
demands it. Flip: none — `err_c_import_destroy_heuristic_no_owning_wrapper.w`,
`err_c_import_uncurated_ptr_return_raw.w` and
`err_c_import_raw_call_requires_unsafe.w` must keep failing without a facade
(ruling §60); they are the guard that nothing is inferred from a name.

**Stage 4 — resource rendering with Drop.** Pointer and by-value resources
rendered as above; `destroys` as `move fn`; `preinit`/`init` with Drop arming
(§13.2) for in-place resources; `Representation.zeroed()` as the default
pre-initialization (this consumes the storage-types rule and does not define
it — ruling §67). Mechanism A retired; its eight libc rows become the
toolchain libc facade (ruling §5, "bounded knowledge"). Tests: Drop runs
exactly once on every path; a producer with no destroyer is a compile error
("never half-model unsafely"); a destroyer callable as a lend is a compile
error. Flip: `behav_c_import_owning_wrapper_fopen.w`, `_strdup.w`,
`behav_c_import_owns_annotation.w`, `_borrows_annotation.w`,
`behav_c_import_borrow_param_readdir.w` (and its `d_acceptance` copy) are
rewritten to the libc facade; `owns:`/`borrows:` become deprecated spellings
with a diagnostic naming the facade clause.

**Stage 5 — production and status (ruling §15-§19).** Direct return,
out-parameter (initialize `NULL`, call, inspect; `(status, Option[R])` when
the convention is unknown), in-place `init`; `ok CONST` projecting to a
`Result`-shaped API; failure may still produce (SQLite); trusted null-failure
returns as `Option[R]`. Tests: each production form; a failed `sqlite3_open`
still closes its handle. Flip: none (the sqlite3 UAT is untouched until §66).

**Stage 6 — dependency (ruling §26-§30).** Child resources rendered
`ephemeral { parent: &P, repr }`; the producer call publishes the parent
origin onto the binding (the one gap: today only ephemeral *parameter* types
publish, `SemaCheck.w:10081-10084`); `independent` suppresses; `returns
borrow R from param N` for borrowed returns. Tests: Rule 6/7 messages on
facaded children; `type App { db, stmt }` rejected (§30); a statement cache
owned by the connection compiles. Flip: none.

**Stage 7 — strings, buffers, domains (ruling §31-§43).** `returns borrow
CStr from param N` and `returns static CStr` produce `Option[&CStr]` tied to
the origin; `CStr.to_str()` (validating, `Result`) and `to_str_lossy()` added
to `lib/std/string.w`; owned foreign text as a resource (`sqlite3_mprintf` →
`sqlite3_free`); `domain X process|thread|resource|static`, coarse default
from `link:`, `preserves`; unknown nullability represented as nullable or
otherwise restricted. Tests: view invalidated by a later call on the
resource; `errno` domain example. Flip: `behav_c_import_overlay_getenv_none.w`
and `_strchr_borrowed.w` move from the `SemaDecl.w:692` table to the libc
facade; `behav_cstr_from_ptr_to_owned.w` gains the `to_str` cases.

**Stage 8 — presentation retargeted.** Mechanism B emits methods on the
resource type; `of` and `rename` override; ambiguous grouping omits the sugar;
multi-resource representations fail closed. Tests: `db.prepare(...)` on a
facaded `Database`; `z_stream` with two resources rejects an unassigned
operation naming both. Flip: `behav_c_import_auto_method_baseline.w` and
`_auto_constructor.w` lose their `unsafe` blocks under a facade and keep them
without one.

**Stage 9 — callbacks and threads (ruling §44-§51).** Callback-scope borrow
default; `retains … by` for retained callbacks and userdata; `consumes …
destroyed_by`; reentrancy through known captures; `thread creator` default,
`send`/`share`/`drop_any_thread`, `callback_thread any`. Tests: a callback
argument cannot escape; `send` without `drop_any_thread` is a compile error.
Flip: none.

**Stage 10 — `with analyze` contract view (ruling §63).** A `ForeignContract`
`AnalysisFactKind`, a collector in `analysis_collect_sema`, the suspicious-
configuration checks as `report.violations` (producer with no destroy path;
destroyer presented as a lend; retained callback with no owner; illegal
thread combination; ambiguous profile match; profile fact shadowed; a
destroyer-shaped borrow, advisory, suppressed by explicit `lend`). Tests:
snapshot fixtures. The CLI spelling is settled here (proposed: `contract`).

**Stage 11 — convention profiles (ruling §7, §59).** `use convention
pkg.vN` resolves through ordinary package rules; unique-or-nothing; explicit
clauses override. Tests: a profile rule with two candidates contributes
nothing. This stage may follow the SQLite facade, which needs no profile.

**Stage 12 — the SQLite facade (ruling §66).** Written against the real
`sqlite3.h`, covering the §66 list: `sqlite3` owned pointer resource,
`sqlite3_open` out-parameter production, `SQLITE_OK`, failed-open production,
`sqlite3_close` and `sqlite3_close_v2`, `sqlite3_stmt` dependent child,
`sqlite3_prepare_v2`, `sqlite3_finalize`, borrowed text from `sqlite3_errmsg`,
nullable borrowed text from `sqlite3_column_text`, view invalidation across
statement mutation, a callback API with userdata,
`sqlite3_create_function_v2`'s consume-with-destroy-callback, retained
callback lifetime, thread capabilities, method presentation, one explicit
presentation override. It compiles and typechecks. **Only then**:
`build/release_uat_fixtures/sqlite3_main.w` (11 `unsafe`), the zlib, bzip2
and libcurl fixtures, `examples/c-interop`, the blog and documentation
examples are rewritten, and `user-programs-safe` (`build.w:1836`) goes green.

**Stage 13 — runtime audit (ruling §52).** Domain facts for the
`rt_libc_*` / `with_libc_*` seams that touch `errno`, `environ`, `locale`,
and an audit lane in the shape of `libc-surface-check` (`build/compiler.w:
1243`) that fails when a runtime extern touching a declared domain is added
without a contract row.

**Tooling (ruling §2.3, §63), alongside stages 10-12.** The design rule,
adopted verbatim from the architect's review: *tooling may be aggressive in
proposing; the compiler must remain conservative in believing.* Authoring
burden, not semantics, is what decides whether this architecture is adopted,
so the tooling is not secondary ergonomics; it is part of the campaign.

The intended workflow is tool-assisted designation, reviewed as confirming a
contract rather than learning a mini-language:
1. the tool reads the header and recognizes likely constructors and
   destructors (`foo_create` returning `Foo *`, `foo_destroy(Foo *)`), and
   proposes `resource Foo` with producer and destroyer;
2. it lists the functions that take `Foo *` and proposes their effects, with
   `lend` shown as an assertion about foreign behavior, never as a safe
   default;
3. for every producer that receives a resource, it asks whether the produced
   handle is dependent or independent, and explains the consequence of each;
4. it flags `register_*` / callback-taking shapes and asks about retention
   and destroy-callback transfer;
5. it proposes thread capabilities from header annotations, documentation
   patterns or an adopted profile, never from representation;
6. it shows the effective contract graph — resources, dependencies, domains,
   views — and the user confirms or overrides;
7. the compiler verifies every structurally checkable clause (§61).

Every suggestion answers *why it was suggested* (naming heuristic, header
annotation, convention profile, documentation pattern, prior facade,
compiler proof); every capability-granting line is emitted commented out
with that provenance; the draft is ordinary With source in the project
(`facades/` by convention) and is never adopted silently.

Three diagnostics and views get first-class attention because they will be
used most:
- **`independent`.** Conservative dependency will over-restrict often (an
  API that merely uses an allocator or context temporarily). The Rule 6/7
  and return-escape diagnostics on a facaded child must name the producer,
  the candidate parent, and the exact `independent` clause to write (§8,
  §57), and the generator asks the question up front.
- **Profiles.** A profile is trusted evidence that infers from names, so a
  bad profile can make hundreds of bindings unsound systematically. The
  contract view must be able to list every fact a profile decided, by rule,
  per binding, and profiles get the most aggressive versioning and
  provenance display of any evidence class.
- **Domains.** Process/thread/resource/static domains with preservation and
  invalidation are the hardest part to author correctly; the contract view
  renders the relationships between origins, domains and dependent views,
  not a flat list.

The CLI spellings are proposed, not ruled, and are settled with stage 10.

## Batching (blast radius)

- Stages 1-2 (parser, facts): one batch, no audits.
- Stage 3 (raw classification): alone; it changes which calls are safe.
- Stage 4 (resource rendering, Drop): alone, with `:move-audit` and
  `:drop-audit` — it is drop scheduling.
- Stage 6 (dependency): alone, with the audits — it is ownership analysis.
- Stages 5, 7, 8, 9: each its own batch; 7 and 9 add the audits (Drop of
  owned foreign text; consume-with-destroy-callback).
- Stages 10, 11, 13 and tooling: batch freely.
- Stage 12: its own batch, and it is the gate for every example rewrite.

## Lanes and files this campaign touches

- `spec-inventory-check`: new keywords in `Token.w`/`Parser.w`, any
  inventoried CLI request.
- `user-programs-safe`: goes green at stage 12; must not be weakened before.
- `libc-surface-check` and the new runtime audit lane (stage 13).
- Tests listed under each stage's Flip; the `d_acceptance` copies move with
  their originals.
- Cache key: `Frontend.w:557-576` `#owns:`/`#borrows:` lines retire at stage
  4; a facade does not affect translation, so it needs no key line unless
  stage 4 renders through the Frontend splice (then the facade text keys the
  splice).

## Out of scope

- The `d43-drafts` and storage-types campaigns (ruling §67); this plan
  consumes `Representation.zeroed()` and does not define it.
- Borrowed handles returned by C beyond `returns borrow` (`sqlite3_db_handle`
  is covered; a general borrowed-handle type is not).
- Any change to how a hand-written `extern fn` is gated: it stays the raw
  surface with `@[effect]`.

## Non-compliance until this lands

As recorded in D51 and CLAUDE.md: today's safe `Counter()` auto-constructor
with no `Drop`; the `COwned_*` `unsafe fn` constructor; `retains:` as an
import attribute; no `c facade`; no contract view. Don't add safe c_import
constructors, wrappers or sugar that grant ownership in the meantime.
