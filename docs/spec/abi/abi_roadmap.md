# ABI roadmap: from `.wo` bundles to OS-resident frameworks

Status: ROADMAP (2026-09-02). Ruled by Eric: the destination is Swift-level
ABI stability (OS-resident With frameworks); the work proceeds in levels
and **Level 0 is the current focus**. Companions: `docs/with-abi.md` (the
convention), `docs/wo_bundles.md` (the Level 0 mechanism), decisions.md
D38.

## Why levels

Swift's ABI stability (`.reference/swift/docs/ABIStabilityManifesto.md`)
has six components: data layout, type metadata, mangling, calling
convention, runtime API, and standard library ABI. Five of them are
*freezing* work — writing down a convention and promising not to change
it — and Swift shipped without any of it for its first four major
versions. The sixth-order effect, *library evolution* (a framework adds a
field or a case in a system update and existing clients keep working),
is the expensive part: it needs opaque layouts, value witness tables,
runtime type metadata, accessor thunks, and `@inlinable` discipline
(`LibraryEvolution.rst`). Swift added it in Swift 5, opt-in per library
and per type, on Apple platforms only.

The levels below are that history made deliberate: freeze what is cheap
to freeze when it is worth freezing, and build evolution only for the
public surfaces that need it.

## Level 0 — bundles (now)

**What:** a migrated corpus compiles once into a `.wo` bundle and is
reused by every compiler build that leaves the ABI-defining sources
alone (`docs/wo_bundles.md`). The `.wo` object key is

    corpus content sha × target × sha256(ABI-defining sources)

where the ABI-defining sources are today `src/FnAbi.w` and
`src/TypeLayout.w` (`docs/with-abi.sha256`), extended as ABI rules move
out of the large files. This is Go's toolchain-keyed cache applied to
exactly the ABI subset: reuse is automatic, invalidation is automatic, and
no version number has to be remembered. `WITH_ABI_VERSION` in `FnAbi.w`
is a human-readable label for the documentation's version history, not
part of the key.

**Promise:** none across compiler releases. Within a checkout, the
`abi-hash-check` battery target guarantees an ABI-affecting edit cannot
land in an unhashed file unnoticed, and the `wo-drift` lane guarantees a
stored object still passes its corpus's own tests under the current
compiler.

**Delivers:** the compiler's dependencies (pcre2, zlib, then the container
corpora) stop recompiling on every build; the compiler embeds the bundles
and stays one file; user binaries automatically link the bundles they
reference.

**Does not deliver:** shipping a prebuilt With library to someone with a
different compiler release.

**Invariants kept now so the later levels stay possible:**
- No `@[c_export]` and no C ABI at any bundle boundary; the boundary is
  With's convention, so freezing it later freezes something real.
- The ABI rules live only in ABI-owned files, so "what the ABI is" is
  always a readable, hashable set of files.
- Every public type is *frozen* (fixed layout) — the default today and
  the Level 1 rule; resilience arrives as an opt-in, never by changing
  what the default means.
- The `.wo` boundary stays C-shaped (scalars, pointers, plain structs,
  the built-in headers): no generic instantiation across a bundle
  boundary. The moment a boundary needs more is the moment to design
  Level 2, not to grow Level 0.

## Level 1 — the frozen ABI (a release decision)

**What:** at a chosen release, `docs/with-abi.md` becomes normative and
frozen: data layout, calling convention and ownership modes, mangling
(including a spec for specialization names), the runtime entry points
compiled code calls (small by then, per D30), and the layouts and public
functions of the stdlib types that appear in signatures. The hash check
becomes "these files do not change without a major ABI version", and a
major ABI version is a release event.

**Promise:** a With library built by compiler N links into a program
built by compiler N+k for the same major ABI version. Dynamic With
frameworks with stable symbols become possible. OS-resident frameworks at
this level are what C system libraries have always been: a public
layout change requires clients to recompile.

**Cost:** the discipline of never changing a public layout, a stdlib
signature, or the convention without a major version. Cheap in mechanism,
permanent in commitment; hence a release decision, not a commit.

**Prerequisites:** D22/D27/D30 settled (pass modes, views, in-unit
runtime); the mangling spec written; the stdlib's public types audited
for what is being frozen.

## Level 2 — library evolution (a design campaign)

**What:** an opt-in per public type — `resilient` (Swift's `@frozen`
inverted, so that every type today keeps its frozen default). For a
resilient type, outside its module: layout is opaque; size, alignment,
copy, move, and drop come from a generated value witness table (the drop
glue codegen already emits per type is most of it); field access goes
through accessors; values are passed indirectly. Generic code across a
resilience boundary is either specialized by the library and exported, or
refused — With does not need unspecialized generic execution to ship
frameworks, and forbidding it avoids the largest part of Swift's runtime.
Availability annotations mark API added after a framework's first
release. `@inlinable`-style exposure is explicit and permanent.

**Promise:** a resilient framework changes its resilient types and adds
API in a system update; existing clients keep running.

**Cost:** a runtime type-metadata format, witness tables, accessor
thunks, indirect passing for resilient values, and the performance and
compiler-wide discipline that come with them — paid only on the public
surfaces of frameworks that opt in.

**Prerequisites:** Level 1 shipped and exercised by at least one real
framework; a design note answering layout of partially-opaque aggregates,
witness-table format, and the generic-boundary rule.

## Decision record

- 2026-09-02: destination is Swift-level (Level 2); **focus is Level 0**;
  the `.wo` key is the ABI-source hash, not a hand-bumped version.
