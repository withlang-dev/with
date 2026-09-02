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

- `docs/with-abi.md` names the boundary rules and a `WITH_ABI_VERSION`
  constant in the compiler.
- The `.wo` object key is `corpus content sha × target × WITH_ABI_VERSION`
  and nothing else. The compiler generation is not in the key.
- A commit that changes an ABI-defining rule bumps the version; every
  `.wo` is then rebuilt once from its bundled source.
- **The bump is enforced, not remembered.** The battery hashes the
  ABI-defining sources (`compute_fn_abi`, layout, the header types, view
  representations, mangling, drop glue) and fails when that hash changes
  without a version bump — the fixpoint discipline applied to the ABI.

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

## Non-goals

- Dynamic linking (`.so`): a runtime loader, C-ABI symbol tables, and
  version games; nothing here needs it.
- Third-party `.wo` distribution across compiler *releases*: possible
  once `WITH_ABI_VERSION` has been stable for a while, but not a promise
  made now while D22/D27/D30 are still moving pass modes and layouts.
