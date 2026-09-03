# `.wo` bundles: compile a migrated corpus once, link it forever

Status: batches A, B and C0 implemented and reseeded (`467aae3e`,
`8014b8e3`, `22e534c6`, 2026-09-02); batch C (pcre2) is designed below in
"Implementation notes (batch C)" under Eric's D39 ruling on bundle
interfaces. Ruled in direction by Eric (decisions.md D38, D39). Companions: `docs/stdlib_sourcing_plan.md`
(the corpora), `docs/harden_migrate.md` (the migrator), decisions.md D30
(runtime objects as a cache), #761 (the mixed-generation corruption
class this design must never reintroduce).

## The requirement, verbatim

> I do not wanna compile the migrated code over and over when there's no
> changes to it. I wanna compile the migrated code once and keep the .wo.
> The normal build cycle should *not* recompile the migrated libraries. It
> should reuse the .wo's we already compiled.

> None of our compiler code should have c_export. We are not exposing any
> C ABIs.

> Compiled user binaries will need to embed those .wo's that they use. We
> should automatically do this.

So: a `.wo` is rebuilt only when its corpus changes (a re-migration or a
pin bump), never because the compiler changed; the `with` executable
embeds every `.wo` and is one standalone file; a user program links the
`.wo`s it uses, automatically, and is one standalone file too; and no C
ABI is exposed anywhere.

## What a `.wo` is

A **With module bundle**: a corpus's migrated With source and tests in
the tree (`lib/std/<corpus>/`), plus, per (target, ABI), three store
artifacts the compiler writes together and embeds together:

```
lib/std/<corpus>/                the raw migrated modules + the corpus's own
                                 tests (the oracle); source of every artifact
<store>/<corpus>-<key>.o         With-native object: With-mangled symbols
<store>/<corpus>-<key>.manifest  abi-sha, target, object name, one `prefix`
                                 line per module (the on-demand predicate)
<store>/<corpus>-<key>.wi        the interface: every module's public
                                 declarations, bodies removed
```

The **interface is the source's declarations.** It is With text, written
by the compiler from Sema's finalized declarations, and Sema reads it
exactly as it reads embedded stdlib source, so signatures carry receiver
modes, ownership modes, and layouts, and the facade over a raw corpus is
ordinary With. There is no serialized metadata format to design or keep
in sync, and nothing another language could consume: the bundle is
With-only by construction, not by policy. It is the declarations rather
than the whole source because Sema on pcre2's 155k lines costs 6.06 s
per program that imports it (hello world: 0.03 s) and `std.regex` is in
the prelude; see "Implementation notes (batch C)".

The **object is With-native.** Its functions are compiled with With's
calling convention (`FnAbi` pass modes), carry With-mangled names, and
export no C surface. `@[c_export]` does not appear (§Runtime Architecture:
any `@[c_export]` in the compiler codebase is a bug). Inbound `extern fn`
calls from a corpus into libc remain what they are today.

## The one design decision: a versioned With ABI at the bundle boundary

An object compiled by an older compiler is linked into a newer one. That
is safe only if the calling convention at the boundary does not move with
the compiler. Today `FnAbi`, the `str`/`Vec` headers, view
representations, the drop protocol, and mangling may change with any
commit. For `.wo` they change only deliberately:

- `docs/with-abi.md` names the boundary rules; the rules live in
  ABI-owned files (`src/FnAbi.w`, `src/TypeLayout.w`).
- The `.wo` object key is `corpus content sha × target × sha256(ABI-defining
  sources)` and nothing else (`docs/abi_roadmap.md`, Level 0). The compiler
  generation is not in the key. An edit to an ABI-defining file changes
  the key, so every `.wo` is rebuilt once, automatically; nothing has to
  be remembered. `WITH_ABI_VERSION` is a documentation label.
- **Creep is enforced, not remembered.** The `abi-hash-check` battery
  target compares the recorded hashes (`docs/with-abi.sha256`) with the
  files, so an ABI-affecting rule cannot move into an unhashed file, and a
  legitimate change re-records the hash consciously — the fixpoint
  discipline applied to the ABI.

Inside a `.wo` nothing is constrained: it was compiled as one unit by one
compiler.

## How the compiler build uses `.wo`s

1. `build.w` has, per corpus, the pipeline `docs/stdlib_sourcing_plan.md`
   describes: pin, reference fetch, whole-corpus migrate, upstream tests.
   Its output is the bundle's `src/` and `tests/`.
2. A `<corpus>-wo` target compiles `src/` to `obj/<sha>-<target>-abi<N>.o`
   **only if that object does not already exist** in the store. A normal
   build finds it and compiles nothing.
3. The **store** lives outside `out/` so `:clean` never touches it
   (`~/.local/with-wo/` or a repo-local ignored directory), and each
   corpus version is also published as a release asset next to the seed,
   fetched by pin the way `:seed` fetches the seed. The corpus source is
   in the tree, so any `.wo` object can always be rebuilt from source; no
   object is ever checked into git.
4. Every stage of the bootstrap chain (stage1, stage2, stage3, the release
   binary) links the same `.wo` objects, so fixpoint (stage2 == stage3) is
   unaffected by their presence.
5. The compiler **embeds** every `.wo` (source and object) the way it
   embeds the stdlib source and `rt_core.o` today, so the release asset
   stays one file.

## How a user program uses `.wo`s

`use std.zlib` (or `use std.stc.deque` through its facade) resolves against
the embedded bundle interface; Sema checks the program with full ownership
knowledge. At link time the compiler extracts from its embedded store
exactly the `.wo` objects the program referenced and static-links them;
the linker dead-strips what is unreferenced. The user's binary is
standalone and never sees a `.wo` on disk. ABI consistency is automatic
here: a user binary only ever links objects embedded in the compiler that
built it, so they share its `WITH_ABI_VERSION` by construction.

## Verification across compiler generations

Byte-identity no longer applies (a `.wo` compiled by generation G is
linked by G+k), so two checks replace it:

- **Link-time interface check.** Every symbol the bundled source promises
  must be present in the object with the expected mangled name; a miss is
  a hard error naming the corpus and symbol.
- **Battery lane `wo-drift`.** Rebuild each `.wo` from its source with the
  current compiler into a scratch object and run the corpus's migrated
  tests against both the stored and the fresh object. Any boundary drift
  the ABI hash did not catch fails here, in the battery, not in a user's
  program.

## Sequence

1. This note reviewed; `docs/with-abi.md` v1 written by enumerating what
   `compute_fn_abi`, the layout tables, and the header types do today (no
   new rules — the version stamps the current convention); the ABI-hash
   check added to the battery.
2. pcre2 converted first: `lib/std/re` becomes the `pcre2.wo` source,
   the object replaces the per-stage `regex_runtime.o` build, and the
   `with_regex_*` shim retires (D30). Measured: compiler build time before
   and after.
3. zlib converted (today it recompiles its migrated modules in-unit on
   every build).
4. Every new corpus (c-algorithms, TommyDS, STC, M*LIB bptree) arrives as
   a `.wo` from day one. Compiler build cost stays flat as the count
   grows to 30.

## Conforming pcre2 and zlib (the first two bundles)

What each is today, and what changes. Both follow the one pattern; every
later corpus follows it from day one.

**pcre2 today.** `lib/std/re/` holds the migrated modules. A 297-line
shim, `rt/regex_runtime.w`, imports all of them and exports `with_regex_*`;
it is compiled whole-module to IR and then to `regex_runtime.o` three
times per build (`bootstrap-`, `stage2-`, `cross-` targets), embedded
through the `EmbedObjectFiles` assembly generator
(`with_embedded_regex_runtime_o_start/_end`), and linked on demand when a
program's undefined symbols need it (`Link.w`'s
`link_stage_undefined_symbols_need_regex_runtime`). `std.regex` and the
compiler itself (SemaCheck 12 call sites, CCodegen 10, CiMigrate 3,
CodegenDispatch 1) call the shim.

**zlib today.** `lib/std/zlib/` holds the migrated modules; `std.zlib`
imports them directly (the model facade). Nothing prebuilt: every consumer
(`std.build`, `build/zlib_gzip.w`, `build/zlib_gunzip.w`) compiles the
corpus in-unit.

**After.**
- `pcre2.wo` = `lib/std/re/` (source) + its migrated tests + one object per
  target × ABI version, built by a `pcre2-wo` target from a bundle root that
  imports every module (today that root is the shim's `use` list), keyed
  and stored per §"How the compiler build uses `.wo`s", built only when
  absent. `zlib.wo` likewise from `lib/std/zlib/`.
- The embed generator and `Link.w`'s name→slice table become data-driven
  over the set of bundles instead of three hardcoded objects; on-demand
  linking generalizes from "needs regex runtime" to "an undefined symbol
  belongs to bundle X" using each bundle's manifest symbol list (this is
  also the link-time interface check).
- `std.regex` imports `std.re` directly, exactly as `std.zlib` imports
  `std.zlib.*`; the compiler's internal callers move onto `std.regex`;
  `rt/regex_runtime.w` and the `with_regex_*` seam are deleted (D30).
- Each bootstrap stage links the store's objects; stage1 (built by the
  seed) receives them as plain link inputs from `build.w`, stage2 and the
  release binary embed them.

**Order of batches.** (A) extract the ABI-defining classifier and naming
into `src/FnAbi.w` beside `TypeLayout.w`, add `WITH_ABI_VERSION`, record
the ABI-source hash, add the battery check — alone in its battery
(codegen-touching). (B) the `.wo` mechanism: store, key, manifest,
data-driven embed and link tables, on-demand linking. (C) pcre2: bundle
target, `std.regex` over `std.re`, compiler callers off the shim, shim
deleted. (D) zlib: bundle target, consumers link it. (A) comes first so
the key is narrow from the first bundle; without it the only correct key
includes the whole of `Codegen.w`, which recompiles the corpora on most
compiler commits — the thing this design exists to stop.

## Implementation notes (batch B, the mechanism)

Everything below reuses an existing mechanism; the new code is glue.

**Object build.** `with build <root>.w --emit-obj -o <store>/<name>-<key>.o`
compiles the bundle in module-object mode (`emit_object_to_path`), so
every function is `__with_mod_<hash>__<base>`. The hash is of the module's
*canonical* path, and a bundle's modules are reached as `std.<corpus>.*`,
whose canonical path is `<embedded-std>/std/<corpus>/<module>.w` — the
same string in every checkout and every compiler generation. This is why
bundle sources live inside the embedded stdlib tree (`lib/std/<corpus>/`,
as pcre2's and zlib's already do) rather than a checkout-relative
`lib/vendor/`: a module reached by a filesystem path would hash an
absolute path into its symbols and the bundle would not be portable. The
root file is a `use` list of every module in the corpus (a bundle root is
generated by the corpus's migrate action, so it is always complete).

**Key.** `key = sha256(corpus_sha | target | abi_sha)` where `corpus_sha`
is the content hash of the bundle's `src/` (the build cache's
`build_cache_hash_directory_w_files` shape), `target` the triple, and
`abi_sha = sha256(docs/with-abi.sha256)`, the recorded hashes of the
ABI-defining sources. The compiler bakes its own `abi_sha` in at link
time (a second post-link sentinel beside the version stamp; `with version
--abi-sha` prints it), so a bundle built by compiler X carries X's ABI
identity, and a compiler that links a bundle checks the manifest's
`abi_sha` against its own — a mismatch is a hard error, never a silent
link (#761).

**Who builds a bundle.** The compiler whose baked `abi_sha` equals the
key's. In the bootstrap chain that is stage1 (the first compiler carrying
the tree's ABI); the seed builds bundles only for its own `abi_sha`,
which stage1's *link* uses (stage1's code was compiled by the seed). When
the ABI sources are unchanged — the normal cycle — both hashes are equal,
one stored object serves the seed, every stage, and the release binary,
and nothing is compiled. Because stage2 and stage3 embed the same stored
bytes, fixpoint holds for bundles by construction.

**Manifest.** `<name>-<key>.manifest`, written by the compiler with the
object (`--emit-bundle-manifest <path>` alongside `--emit-obj`): `name`,
`key`, `corpus_sha`, `target`, `abi_sha`, and one `prefix
__with_mod_<hash>__` line per module in the bundle. The prefixes are the
on-demand predicate and the link-time interface check: an undefined
symbol starting with a bundle's prefix means that bundle links.

**Store.** `$WITH_WO_DIR`, default `~/.local/with-wo/`, outside `out/`.
Release assets per corpus version later; source always in the tree.

**Link.** `Link.w` gains: `--link-object <path>` (repeatable; a plain
extra object, the way workspace units already join through
`extra_objects`) for `build.w` to hand a stage link its bundles; and
on-demand bundle selection after the undefined-symbol probe, over the
compiler's *embedded* bundles — a generated `out/gen/compiler/
EmbeddedBundles.w` (the `EmbeddedStdlibData.w` pattern) listing each
bundle's name with `with_embedded_wo_<name>_o` and `_manifest` blobs
(produced by the existing `EmbedObjectFiles` generator from the store
files). Empty index until the first bundle. Selection extracts the blob
to the link temp dir, exactly as `regex_runtime.o` is extracted today.

**Build.** `build.w` gains a `wo_bundle(name, root, source_dir)` helper
that registers `<name>-wo` (key computation; skip when the store has the
object; else run the right compiler with `--emit-obj
--emit-bundle-manifest`; publish atomically), adds the object and
manifest to the `embedded-objects` inputs for the stage that embeds
them, and passes `--link-object` for the stage links. The `wo-drift`
lane (rebuild to a scratch object with the current compiler, run the
corpus's migrated tests against stored and fresh) lands with the first
bundle.

**Declarations only for bundle-provided modules.** A program that `use`s
a module an embedded bundle provides must not compile that module's
bodies in-unit — that would duplicate every symbol the bundle defines and
the on-demand predicate would never fire (no undefined symbol would
reference the bundle). So codegen consults the embedded bundle index once
and, for every declaration whose source module carries a bundle prefix,
emits a declaration only, exactly as it does for `extern fn`; the body
comes from the bundle at link time. Sema still checks against the source.
A bundle module may not define generic functions or comptime bodies (the
C-shaped boundary of `docs/abi_roadmap.md` Level 0; the bundle build
refuses one), so nothing from a bundle is ever instantiated at a use site.
Facades (`std.regex`, `std.zlib`) are stdlib source outside the bundle and
compile in-unit as before. (Batch C revises the bootstrap consequence:
stage1 must link the bundle through `--link-bundle` too, or stage1
compiles the corpus in-unit into stage2 while stage2 links the bundle
into stage3 and fixpoint breaks.)

**Order inside the batch.** (1) `--link-object`; (2) the ABI-sha stamp and
`with version --abi-sha`; (3) `--emit-bundle-manifest`; (4) `Link.w`
embedded-bundle selection with an empty index; (5) declarations-only
codegen for bundle-provided modules — all landed in `467aae3e` and
`8014b8e3`, battery green, reseeded. (6) the `build.w` helper and store
land with the first bundle (batch C).

## Implementation notes (batch C, pcre2) — ruled, decisions.md D39

**Two gaps batch B left** (found mapping pcre2; fixed first as batch C0,
alone in a battery because both touch symbol naming):

- Whole-program codegen names a function by its bare base name
  (`fn_abi_module_link_name` with mode 0), but a bundle defines
  `__with_mod_<hash>__<base>`, so a bundle-provided call site would never
  reference a bundle symbol and the on-demand predicate would never fire.
  The three `module_object_mode != 0` naming guards in `Codegen` become
  one predicate — this path uses module link names — true in
  module-object mode or when an embedded bundle provides the path.
- `codegen_canonical_module_path` joins a tree-resolved `lib/std/re/x.w`
  with `$PWD`, so a bundle built from a checkout would hash an absolute
  path into every symbol. The rule maps `lib/std/<rest>` (and
  `…/lib/std/<rest>`) to `<embedded-std>/std/<rest>`, the identity Sema's
  module naming already applies. ABI-defining: re-record
  `docs/with-abi.sha256`. Verified by `--emit-bundle-manifest` on the
  corpus root printing `<embedded-std>/std/re/…` prefixes.

**The measured constraint.** `with check lib/std/re/pcre2test.w` takes
6.06 s; hello world 0.03 s. `std.regex` is imported by the prelude, so
"the facade imports `std.re.*` directly" would put six seconds of Sema on
every program. Batch B's declarations-only rule saves codegen, not Sema.
So a bundle ships its interface, and the compiler embeds interfaces,
never corpus sources.

**Interface (`.wi`) — D39.** A `.wi` is a compiler-recognized source
flavor: ordinary With declaration syntax read in an interface-only parser
mode, in which a function may omit its body and a storage-backed global
may omit its initializer. Ordinary `.w` source never admits either, so
the language does not acquire C-header forward declarations by accident.
In the AST the state is typed, never implied by a missing node: a
function declaration's body is `SourceBody | InterfaceBody`, a global's
initializer is `Expr | InterfaceProvided`, under the invariant that
anything requiring implementation information rejects or ignores
`InterfaceBody` and anything operating on declarations works identically
on both. The compiler writes the interface after full Sema
(`--emit-bundle-interface <path>`, beside `--emit-obj`) from finalized
semantic declarations, never as a syntactic projection: one `module
<embedded-std>/std/<corpus>/<name>.w` section per bundle module holding
the `pub` types with exactly the declarations needed to reproduce their
layout (canonicalized, no alias or import chains), `pub const NAME: T =
<folded value>` (canonical folded constants, never the source
expression, so interface constants carry no implementation
dependencies), `pub let NAME: T` for storage the object supplies, and
every `pub fn`/`pub unsafe fn` signature. Consumers resolve a
bundle-provided module to its `.wi`, run ordinary declaration, type and
layout Sema on it, and never body analysis or MIR for bundle
implementations. A generic or `comptime` declaration in a bundle module
is a bundle-build error (Level 0's C-shaped boundary,
`docs/abi_roadmap.md`).

**Callable semantics are the declaration — D39.** No body-inferred
ownership or effect information is part of an interface. `T` is
consumed; `&T` is borrowed for the call; `&mut T` is a mutable borrow;
`move self` consumes the receiver; `mut self` is the mutable receiver;
raw pointers carry no With ownership beyond their declared type; a
returned reference's origin follows deterministic elision — the receiver
if there is one, else the single borrowed parameter, else the declaration
is ambiguous and the bundle build rejects it (`pub fn choose(a: &Foo, b:
&Foo) -> &Foo` has no interface under the default rules). A source
function whose `T` parameter is not consumed was declared wrong and
should say `&T`; the boundary exposing that is a feature. When an API
genuinely needs to state an origin, With's source language gains a way
to say it (conceptually `-> &Foo from a`): a real language feature for
authors, never an interface-only annotation of inferred Sema facts. If a
caller must know it for correctness, it belongs in the contract.

**Fingerprint — D39.** The bundle build proves the interface is exact,
not merely parseable: Sema computes a canonical exported-declaration
graph from the full source and, separately, from the emitted `.wi`,
hashes both, and requires equality. The graph covers type layouts and
ABI-relevant field offsets, enum discriminant values, parameter and
return types, receiver mode, declaration-level ownership and borrow
modes, calling convention, visibility, constant type and value, extern
function-pointer signatures, and generic constraints when applicable.
The fingerprint is recorded in the manifest, so an object and an
interface from different generations can never be paired: the consumer
checks it before linking. An emitter bug is a build failure, never an
ABI corruption.

**Emitter and fingerprint (batch C2, implemented).** `with build <root>
--emit-obj --bundle-corpus <rel> --emit-bundle-interface <x>.wi
--bundle-fingerprint <a>` writes the object, the interface and the
source-side fingerprint from the Sema codegen hands back (layouts
frozen); `with check <x>.wi --bundle-corpus <rel> --bundle-fingerprint
<b>` reads the `.wi` as the whole bundle (every `module` section
registered, a synthesized root importing each) and writes the
interface-side fingerprint; the bundle build requires `a == b`. The
manifest records `fingerprint` and `interface-sha` (sha256 of the `.wi`
bytes); `--link-bundle` refuses an interface whose sha is not the
manifest's. `--bundle-corpus std/re` selects `<embedded-std>/std/re/…`;
`std/wi_demo` selects the single module `<embedded-std>/std/wi_demo.w`.
The emitter (`src/compiler/BundleInterfaceEmit.w`) prints from Sema's
finalized tables only, never source text, never a placeholder: a
declaration it cannot state exactly is a loud error naming it and
nothing is written. Per section: the module's `use` lines in import order
(a module holding only `use` lines, as pcre2's migrated table modules do,
still gets a section), then types, consts, storage globals, extern fns,
free fns and impl blocks, each group bytewise by name. Exported: every
`pub` declaration plus every corpus type a printed declaration names,
with its own visibility (a layout needs its field types; a std-tier
consumer sees private std declarations through Sema's internal
boundary either way). Aliases are emitted as declarations and resolved
inside every other spelling; `impl Copy for T` follows a Copy type;
struct field defaults are printed when they are literals, casts of
literals (`0 as c_ulong`) or repeat arrays (`[0 as u8; 32]`); a plain
enum never gets `= N`, a discriminant enum always does, with its backing
type. A generic function is corpus-internal at Level 0 (its body
instantiates at each use site, and an interface carries no bodies): it is
omitted from the interface, named there by a note line and in the
manifest's `omitted` lines, and the build warns — a migrated C corpus
exports its macro helpers this way. Refused: generic types and impls,
async/gen/comptime/variadic/`@[c_export]`
functions, extension methods, default parameter values, destructured
parameters, a type with a `drop` method, a droppable mutable global, a
const whose folded value is not a literal, an ambiguous returned
reference (the C1 message), trait objects and Range types, ephemeral or
derived types, traits, `c_import`, extern storage, selector imports.
The fingerprint (`src/compiler/BundleFingerprint.w`) is sha256 over
sorted TSV rows holding spellings and layout numbers only — one `module`
row per corpus module; type rows with kind, size, align, Copy-ness,
layout flags, visibility, fields (name, spelling, offset, explicit
align, default) and variants (name, discriminant, payloads); const,
global, extern and fn rows, the fn rows carrying the receiver mode,
unsafe-ness, per-parameter spelling, share-place verdict and DECLARED
effect (SemaCheck's `declared_param_effect`/`declared_view_origin`, the
rule C1's interface Sema applies, so source and interface agree), the
return spelling and the declared view origin. The source pass warns when
a plain `T` parameter's body only reads it — the D39 "declare it `&T`"
signal. The harness `bundle-interface-tests` regenerates
`test/bundle_interface/wi_demo.wi` byte for byte, requires
fingerprint equality, checks three interface mutations change it, runs
the consumer against the emitted interface, and fires each refusal.
Measured on pcre2 (2026-09-02, stage1): a 4.3k-line `.wi`, source and
interface fingerprints equal, and a tiny `std.re` consumer's `check`
drops from 5.2 s through the source to 0.26 s through the interface.
Corpus findings for batch C3: `defs.w` exports 46 generic functions
(migrated C macros such as `INT8_C[T]`, `PCRE2_GLUE[T]`, `MAX_255[T]`);
they stay corpus-internal and are omitted from the interface (above);
`pcre2_chartables.w`, `pcre2_tables.w` and `pcre2_ucd.w` carry only
`use` lines.

**Resolver.** `use std.re.X` on a compiler whose bundle index provides
`<embedded-std>/std/re/X.w` reads that module's interface section;
otherwise the source, as today. `lib/std/re/` stays out of
`EmbeddedStdlibData.w` (it is excluded today), and that exclusion becomes
the rule for every corpus: three blobs per bundle (object, manifest,
interface), never the 5.5 MB of source.

**`--link-bundle <store>/<name>-<key>`** (repeatable) replaces the bare
`--link-object` for stage links: it names the object, the manifest
(prefixes → declarations only) and the interface (resolver) together, so a
compiler with an empty index (stage1) compiles exactly what a compiler
with the bundle embedded compiles.

**Bootstrap chain.** `wo_bundle("pcre2", "lib/std/re", <root>)` registers
`pcre2-wo`: key = sha256(corpus_sha | target | abi_sha) with `corpus_sha`
from `build_cache_hash_directory_w_files` over the root's closure; store
`$WITH_WO_DIR` (default `~/.local/with-wo/`); present → nothing runs;
absent → the compiler whose stamp equals `abi_sha` builds it (`--emit-obj
--emit-bundle-manifest --emit-bundle-interface`, published atomically).
seed → stage1: the seed's own embedded bundle when it has one, else the
corpus in-unit once (only until the reseed after this batch). stage1 →
stage2: `--link-bundle` with the tree-ABI bundle stage1 built; stage2
embeds it. stage2 → stage3: stage2's index; same stored bytes, so
fixpoint holds by construction. Cross compilers embed the `--target`
bundles the release compiler builds. The five `regex-runtime-ir`/`-object`
target pairs and the `regex_runtime.o` entries in `Link.w`,
`build/package.w`, `build/emit_c.w`, `build/runtime.w`, and
`install-regex-runtime` go away.

**Root.** `rt/regex_runtime.w`'s `use` list (32 modules; `pcre2test` and
`pcre2posix` are harness, not bundle) is the bundle root, moved to
`lib/std/re/bundle.w` and written by the migrate action, which already
post-patches `use` lines into three modules
(`pcre2_ensure_generated_dependencies`).

**Retiring the shim (D30).** `std.regex` imports `std.re.*` through the
interface and calls pcre2 directly, as `std.zlib` does; `Regex.__literal_code`
stays the regex-literal entry and gains `Regex.__capture_count`, so
codegen's `gen_regex_literal_value` calls facade functions only;
SemaCheck's compile-time literal validation (`validate_regex_literal`)
uses `std.regex` like any program — the compiler is one more user of the
facade and links the bundle on demand; `CCodegen`'s ten `with_regex_*`
prototypes, `CiMigrate`'s borrowed-str mask, and `rt/regex_runtime.w` are
deleted; `build/emit_c.w` stops harvesting `with_regex_` exports (its
"found no runtime exports" check retires with the last runtime export; in
the emit-C lane the corpus compiles in-unit as C, no bundle involved).

**Lanes.** `wo-drift`: rebuild the bundle to a scratch object with the
current compiler — byte-identical to the stored one when corpus and ABI
are unchanged (determinism of the bundle itself) — and run `:pcre2-test`
(upstream RunTest) with `pcre2test` linked against the bundle.
`abi-hash-check` already guards the key.

**Known debt.** #941: the migrator emits `/`-based 128-bit overflow
helpers; the promoted `defs.w` files carry a hand edit a re-migrate would
drop. The generator is fixed before the first `wo-drift` run.

**Ruled** as decisions.md D39 (2026-09-02); the spec projection landed
the same day with Eric's blessing of the words: specification §3.4 (the
separate-compilation origin rule) and §18.5c (bundles and interfaces).

## Non-goals

- Dynamic linking (`.so`): a runtime loader, C-ABI symbol tables, and
  version games; nothing here needs it.
- Third-party `.wo` distribution across compiler *releases*: possible
  once `WITH_ABI_VERSION` has been stable for a while, but not a promise
  made now while D22/D27/D30 are still moving pass modes and layouts.
