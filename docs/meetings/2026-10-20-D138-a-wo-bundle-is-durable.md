# D138 — A `.wo` bundle is durable: rebuilt when its sources or the contracts it imports change, never because the compiler did

**Date:** 2026-10-20. **Status:** ruled (Eric). **Extends:** D38 (`.wo`
bundles), D39 (the interface flavor), D30 (the runtime bundle), D132 (a
runtime is identified by its bytes). **Supersedes:** the `compiler-src-sha`
slot key of 2026-09-09 (ab30b320a).

**Ruling (Eric, 2026-10-20).** "I really need to just have a binary .wo of
those, and only ever rebuild them when we change the pinned source, or we
change the .wo contract, not every time we change the With compiler. When
we have 100 corpora, it will be absolutely infeasible to rebuild them every
day." And: "make the .wo durable - i don't wanna keep rebuilding it when the
C library didn't change and the .wo works fine as it is, no need to rebuild
it - we need to craft our build system imagining that there are 50,000 of
them - that's how scalable it needs to be." And: "just imagine how many
useless CPU cycles, how much electricity we are burning, and waste heat we
are producing, to compile it over and over and over when nothing changed."

**Decision.** A stored bundle is reused by every compiler that can link it.
It is rebuilt for exactly four reasons, each a fact about the bundle, and
the compiler that built it is provenance (the manifest's `generation`),
never a key:

1. **Its sources changed** — the corpus (`corpus-sha`), or a non-corpus
   module whose functions the object carries as internal copies (the
   manifest's `carried` lines, hashed into `carried-sha`).
2. **Its target changed** — a bundle is compiled for one platform.
3. **The ABI identity changed** — `abi-sha`, the recorded hashes of the
   ABI-defining sources (D38).
4. **A contract it imports changed.** The manifest records every symbol
   the object references and does not define as `import <symbol> <rt|foreign>
   <contract>`; the runtime bundle records every runtime symbol it defines
   as `provides <symbol> <contract>`. The contract is the declaration's
   parameter types and effects, variadicity and return type, spelled
   canonically (`BundleInterfaceEmit.bundle_symbol_contract`). A bundle
   links against any runtime whose contract for each `rt` import is the
   one it was built against; a `foreign` import is the platform's (libc)
   and is checked by nothing but the link.

The compiler owns the rule: `--emit-bundle-manifest` writes the rows and
refuses an object that references a symbol no declaration of its unit
names (the carried-copy class that motivated the superseded key: a
module-link-named reference nothing at a consumer's link could define),
and every link — an embedded bundle, `--link-bundle` — refuses a bundle
whose runtime imports this compiler's runtime no longer provides as
declared (`Link.link_stage_bundle_import_drift`). The build store applies
the same rule before reusing a slot (`build/wo.w wo_slot_status`), so a
compiler never embeds a bundle it would refuse. A bundle or a runtime from
before the rows is judged as before: it must be the compiler's own
generation.

**Why.** The superseded key hashed all of `src/`: every commit rebuilt
every bundle for every target, the store held 43 generations of one
unchanged zlib object, and a fifth corpus would have cost a fifth more. The
incident behind that key (a stored object referencing `std.libc` wrappers
the new codegen no longer defined) is a contract violation the manifest now
names and the bundle build refuses, not a reason to key on the compiler.
At fifty thousand bundles nothing per-commit may touch them: a bundle's
validity is a join of facts the bundle and the runtime each wrote once.

**Verification.** `wo-drift` keeps rebuilding each bundle with the current
compiler into scratch and running the corpus's harness against the stored
and the fresh object; a byte difference under equal interface, fingerprint,
ABI, target and contracts is reported and the slot stays.

**What would reopen it.** A runtime behavior change behind an unchanged
signature that a stored bundle cannot tolerate: that is an ABI change and
bumps `docs/with-abi.sha256` (reason 3), as the ABI roadmap says; the
contract rows do not model semantics, only declarations.
