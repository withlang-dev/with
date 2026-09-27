# D38 — Migrated corpora compile once into `.wo` bundles; the boundary is a versioned With ABI, never a C ABI

**Date:** 2026-09-02
**Status:** Ruled by Eric. Verbatim: "I do not wanna compile the migrated
code over and over when there's no changes to it. I wanna compile the
migrated code once and keep the .wo. The normal build cycle should *not*
recompile the migrated libraries."; "None of our compiler code should
have c_export. We are not exposing any C ABIs."; "Compiled user binaries
will need to embed those .wo's that they use. We should automatically do
this." Design: `docs/wo_bundles.md`.

**Decision.** Each migrated corpus is a `.wo` bundle: its With source
(the interface — generics, ownership modes, effects all visible to Sema),
its migrated tests, and one With-native object per target and ABI. The
object key is corpus content × target × sha256 of the ABI-defining
sources (`src/FnAbi.w`, `src/TypeLayout.w`; `docs/with-abi.sha256`) —
Go's toolchain-keyed cache applied to the ABI subset, after the reference
survey (2026-09-02: Go, Rust, Zig key artifacts on the whole toolchain
and recompile; only Swift promises cross-version stability, at the cost
of resilience). The compiler generation is not in the key, so a `.wo` is
rebuilt only when the corpus or an ABI rule changes, and no version
number has to be remembered. The longer road to Swift-level stability is
`docs/abi_roadmap.md` (Level 0 now, Level 1 frozen ABI at a release,
Level 2 library evolution as a campaign). The compiler embeds every
`.wo` and stays one standalone file; a user binary automatically links
the `.wo` objects it references and is standalone too. The boundary
convention is With's own (`FnAbi` pass modes, header types, mangling,
drop protocol), declared and versioned in `docs/with-abi.md`; a change
to an ABI-defining rule must bump the version, enforced by a battery hash
check. No `@[c_export]`, no C surface, anywhere in the compiler.

**Amended by D39 (2026-09-02).** The bundle's interface is its
*declarations* (`.wi`), not its source, and the compiler embeds
interfaces, never corpus sources. See D39.

**Context.** The container corpora (D37) will bring the compiler's
migrated dependencies to 20–30. Today each bootstrap stage recompiles
every corpus (pcre2's `regex_runtime.o` three times per build; zlib
in-unit on every program), and the cost scales linearly with the count.

**Alternatives.** Keying objects by compiler fingerprint (D30's cache as
it stands — correct, but rebuilds every corpus three times per compiler
build; rejected as the *normal* cycle, kept as the fallback when the ABI
version bumps); a platform-C-ABI boundary (rejected: exposes a C surface
from the compiler, which the runtime doctrine forbids, and is not
withy); dynamic libraries (rejected: loader, C symbol tables, versioning,
and multiple files).

**Reasoning.** "Compile once" across compiler generations requires a
stable boundary; the only boundary consistent with the mission is With's
own convention made deliberate — versioned, hash-enforced, and validated
by rebuilding each corpus and running its own tests against both objects
in the battery. Source as the interface keeps every With-ism intact and
avoids a metadata format. Reopen if the ABI version has to bump so often
that the normal cycle recompiles corpora anyway (the signal that pass
modes/layouts are not yet settled enough for the scheme), or if a corpus
needs a boundary the ABI document cannot express.

---
