# `.wo` bundles: compile a migrated corpus once, link it forever

Status: DESIGN (2026-09-02). Ruled in direction by Eric (decisions.md D38);
nothing here is implemented. Companions: `docs/stdlib_sourcing_plan.md`
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

A **With module bundle**: a corpus's migrated With source, plus one
prebuilt object per (target, With ABI version), plus a manifest.

```
<corpus>.wo/
    manifest            corpus name, upstream pin (tag, tarball sha256),
                        corpus content sha, migrator version that produced
                        the source, per-object records below
    src/                the raw migrated With modules — the interface
    tests/              the corpus's own tests, migrated (the oracle)
    obj/<sha>-<target>-abi<N>.o
                        With-native object: With-mangled symbols, With ABI N
```

The **interface is the source.** Sema reads `src/` exactly as it reads
the embedded stdlib today, so signatures carry receiver modes, ownership
effects, and layouts; generics and `comptime` instantiate at the use site;
the facade over a raw corpus is ordinary With. There is no serialized
metadata format to design or keep in sync, and nothing another language
could consume: the bundle is With-only by construction, not by policy.

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
the embedded bundle source; Sema checks the program with full ownership
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
compile in-unit as before. In the bootstrap chain this is also why
`--link-object` is not on the critical path: a compiler with a bundle
embedded skips the bodies and links its own embedded copy; the seed, which
has none, compiles the corpus in-unit into stage1 once.

**Order inside the batch.** (1) `--link-object`; (2) the ABI-sha stamp and
`with version --abi-sha`; (3) `--emit-bundle-manifest`; (4) `Link.w`
embedded-bundle selection with an empty index; (5) declarations-only
codegen for bundle-provided modules; (6) the `build.w` helper and store
land with the first bundle (batch C). Battery, reseed. Then batch C
converts pcre2 on top.

## Non-goals

- Dynamic linking (`.so`): a runtime loader, C-ABI symbol tables, and
  version games; nothing here needs it.
- Third-party `.wo` distribution across compiler *releases*: possible
  once `WITH_ABI_VERSION` has been stable for a while, but not a promise
  made now while D22/D27/D30 are still moving pass modes and layouts.
