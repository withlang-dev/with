# Incremental Compilation: Rebuild What Changed

## Scope

Today any real edit to one file of a With program rebuilds the whole
executable. For WIPE that is 18 s on an Apple M5 Max and 65 s on a Steam
Deck, so a one-line tuning change waits as long as a clean build. This plan
makes the rebuild proportional to the edit: first by removing work that is
repeated for no reason, then by reusing machine code per codegen unit,
then by re-analyzing only the declarations an edit can affect.

It serves the Steam Dev loop (`docs/plans/steam-dev.md` §4 and §7), where
the build is most of the reload time, and every With program after that.

Eric asked for this research on 2026-10-18. This is a plan, not a
specification. Every number below was measured that day on v0.15.3.0 with
WIPE at `5653888`; nothing here is an estimate unless it says so.

## 1. Where the time goes

`WITH_PROFILE=1 with build` after adding one function to
`src/presentation.w` (Mac, warm build cache):

| Phase | Time | Share |
|---|---|---|
| `frontend.read`, `parse`, `resolve`, `imports`, `interface` | 0.10 s | 1% |
| `frontend.c_import` | 3.36 s | 19% |
| `frontend.comptime` | 0.73 s | 4% |
| `frontend.sema` (12,917 declarations) | 9.42 s | 52% |
| of which `sema.bodies`, run twice | 4.27 s + 4.30 s | |
| `mir.lower` and checks | 0.38 s | 2% |
| `llvm.gen_module` | 0.68 s | 4% |
| `llvm.optimize` | 1.12 s | 6% |
| `llvm.emit_object` | 1.88 s | 10% |
| `link`, `dsymutil` | 0.20 s | 1% |
| **Total** | **18.0 s** | |

A comment-only edit is already a no-op (0.4 s), and the no-change build is
0.4 s: the build system's file-level skipping works. Below the target
boundary nothing is reused.

What the profile says:

1. **C headers are translated again every build.** WIPE's `c_import`s of
   raylib, SDL3 and the Steamworks flat API do not change between edits,
   but cost 3.4 s each time. A disk cache exists
   (`c_import_fs_cache_lookup`, `src/compiler/Frontend.w:470`) and is
   skipped whenever a compilation has more than one `c_import`, because
   the translator deduplicates declarations shared between imports and a
   cached expansion would make that table wrong. WIPE has nineteen files
   that `c_import`.
2. **Sema checks every body, twice.** The first `sema.bodies` pass reports
   `added types=123 symbols=33 sigs=22`; the second reports `symbols=0`
   and costs the same 4.3 s. Why the second pass covers every body rather
   than what the first added has not been investigated.
3. **LLVM redoes every unit.** Codegen units exist (#681,
   `src/compiler/CodegenUnits.w`) and are emitted in parallel, but every
   unit is regenerated, optimized and emitted on every build.
4. **Linking is not the problem.** 0.15 s. Incremental linking, the hard
   part of Zig's design, buys almost nothing here.

## 2. What other compilers do

| Compiler | Unit of reuse | Change detection | Codegen and link |
|---|---|---|---|
| Zig (0.17, `-fincremental --watch`, x86_64 Linux) | Per file for parse and AstGen (ZIR cached on disk); per *analysis unit* for Sema: a type's layout, a declaration's type, a constant's value, a function body | Hash of each declaration's source in ZIR; declarations matched by name across edits; a dependency graph recorded during analysis; re-analysis stops when a unit's result is unchanged | Own backend, per function; own linker patches the output file in place. 50–70 ms rebuilds of a real application. Compiler state is in memory under `--watch`, not yet on disk |
| rustc | Query results, and object files per codegen unit | Red-green: every query's result and the query graph are saved; a query whose inputs are all green is green without re-running | LLVM per codegen unit; an unchanged unit's object file is reused. 256 units by default in incremental builds |
| Swift | Per file | Per-file dependency records (`.swiftdeps`) and a hash of the tokens that can affect other files, so a body-only edit does not cascade | Per file. A change to an imported module or C header rebuilds the whole module |
| Go | Per package | An action ID hashing the package's inputs and its dependencies' export data | Per package, cached in `GOCACHE` |
| Live++ (C++) | Per translation unit | The build system | Hot-patches the running process instead of linking incrementally |

Three lessons apply to With directly:

1. **Cache what is a pure function of its inputs, keyed by those inputs.**
   Zig's per-file ZIR, Go's action IDs and rustc's codegen-unit objects
   are all this. It is the cheap part, and it is where WIPE's first 3.4 s
   and most of its 3.7 s of LLVM time are.
2. **Early cutoff is what makes fine-grained reuse pay.** Zig and rustc
   both stop propagating when a re-analyzed unit produces the same result
   as before. Without it, any edit to a widely used declaration still
   invalidates everything downstream.
3. **Language design decides how hard Sema is.** Zig changed its language
   to make analysis units independent. The With features that cross body
   boundaries are the ones to model: generic bodies checked at
   instantiation, `comptime`, and anything Sema infers from a body that
   callers see. The `.wi` interface rule (`docs/spec/toolchain/bundles-and-interfaces.md`:
   "no body-inferred information is part of an interface") already states
   the firewall at the corpus level.

Two options were looked at and set aside:

- **Incremental linking.** Linking is 0.15 s for WIPE. Fast full links
  (lld, mold) are why most toolchains never needed it; Zig needed it only
  because its rebuilds reach milliseconds.
- **A second, faster backend.** Cranelift saves rustc about 10–15% on
  debug builds (Rust project goal, February 2026); TPDE claims 10–20× over
  LLVM `-O0` but is young. Neither is a first step; both are worth a look
  once LLVM is the remaining cost.

## 3. Stages

Each stage is independently useful, measured on WIPE, and kept only if it
holds the fixpoint and the battery.

### Stage 1: stop repeating work (no new architecture)

1. **The `c_import` disk cache for compilations with several imports.**
   Key one entry on the ordered list of every `c_import` in the
   compilation (each header's resolved path, contents hash and flags) and
   cache the whole deduplicated translation together, so the dedup table
   is the one the cache was made with. The existing dependency manifest
   (`c_import_fs_cache_deps_manifest`) already records every header a
   translation read. Expected saving: the measured 3.4 s, less the cost of
   reading the entry back.
2. **Find why `sema.bodies` runs twice over every body.** If the second
   pass exists to check bodies that the first pass's additions affect, it
   should run over those bodies only. Expected saving: up to the measured
   4.3 s; the real number depends on what the pass needs.
3. **`-O0` for dev builds.** `llvm.optimize` is 1.1 s of a rebuild, and
   debugging needs `-O0` anyway (Steam Dev §6). `with dev` passes it;
   nothing changes for `with build`.

Stage 1 is done when WIPE's one-file rebuild is measured again with each
change separately.

### Stage 2: reuse machine code per codegen unit

1. **Stable partitioning.** Today MIR bodies are packed greedily into
   size-balanced units by statement count. If one edit can move other
   bodies between units, unchanged code is regenerated anyway; whether it
   does is the first thing to measure. A partition by module (or by
   source file, with a size cap that splits a large file into fixed
   halves) keeps a body's unit stable across edits, as rustc's
   per-module units do.
2. **Key each unit on its content.** The hash of a unit's MIR bodies, the
   declarations they reference (signatures and layouts), the target,
   optimization level and compiler ABI identity (`with version --abi-sha`).
   A hit reuses the unit's object file from the build cache; a miss
   regenerates it.
3. **Determinism holds per unit.** `CodegenUnits.w` already makes unit
   pipelines order-driven so stage2 equals stage3 per unit; a cached
   object must be byte-identical to a freshly generated one, and the
   fixpoint checks it.

With Stage 2 an edit to one function costs Sema plus one unit's LLVM time
plus the link.

### Stage 3: re-analyze only what an edit affects

The Zig design, adapted:

1. **Per-file front-end cache.** Parse and resolve results cached by file
   content hash. Small today (0.1 s) but the precondition for the rest.
2. **Analysis units and a recorded dependency graph.** Units: a type's
   layout, a declaration's signature, a constant's value, a function body,
   a generic instance. Sema records each unit's dependencies as it
   analyzes it, plus a dependency on the source hash of each declaration
   it reads.
3. **Early cutoff.** A re-analyzed unit whose result is unchanged does not
   invalidate its dependents.
4. **The With-specific edges**, each needing a design note before code:
   generic bodies checked per instantiation (an instance depends on the
   generic's body); `comptime` evaluation; implicit parameters and
   `with context`; ownership, effect and receiver inference that callers
   observe; view-liveness and ephemerality, which propagate through types.
5. **Where the state lives.** A resident compiler under `with dev watch`
   holds the graph in memory, as Zig does today; a disk format is later.

Stage 3 is a compiler project of its own and is planned in its own
document once Stages 1 and 2 have been measured.

## 4. Acceptance

- Each stage reports WIPE's one-file rebuild time on the Mac and on the
  Deck, before and after, in this document.
- `with build :fixpoint` holds with every cache enabled, and with every
  cache disabled.
- A cached build and a clean build of the same sources produce
  byte-identical objects.
- A cache that cannot prove its key complete is not consulted: a wrong hit
  is a miscompile, and a miss is only slow (mission rule 7).
- `WITH_PROFILE=1` names each cache's hits and misses, so a regression is
  visible in the profile.

## 5. Open questions

1. The cache's home: `out/.build-state` per project, or a shared user
   cache like `GOCACHE`, so a dependency's units are shared between
   projects.
2. Whether Stage 2's unit key can name referenced declarations precisely
   before Stage 3 exists, or must start from a coarser key (the unit's MIR
   plus the hash of every exported signature in the program).
3. Whether `with dev watch` should run a resident compiler from Stage 1
   on, so in-memory caches pay off before any disk format exists.

## 6. References

- Matthew Lugg, "Inside Zig's Incremental Compilation", 2026-07-28:
  https://mlugg.co.uk/posts/incremental-compilation-internals/
- Zig 0.16.0 release notes: https://ziglang.org/download/0.16.0/release-notes.html
- Mitchell Hashimoto, "Zig Builds Are Getting Faster":
  https://mitchellh.com/writing/zig-builds-getting-faster
- rustc dev guide, incremental compilation in detail:
  https://github.com/rust-lang/rustc-dev-guide/blob/main/src/queries/incremental-compilation-in-detail.md
- Rust RFC 1298, incremental compilation (codegen-unit reuse):
  https://rust-lang.github.io/rfcs/1298-incremental-compilation.html
- Cargo profiles (codegen units for incremental builds):
  https://doc.rust-lang.org/cargo/reference/profiles.html
- Swift driver, incremental builds: https://github.com/swiftlang/swift/blob/main/docs/Driver.md
- Rust 2026 goal, Cranelift performance: https://rust-lang.github.io/goals/2026/improve-cg_clif-performance.html
- Live++ FAQ (hot-patching instead of incremental linking): https://liveplusplus.tech/faq.html
- mold 2.42.1 release notes: https://github.com/rui314/mold/releases/tag/v2.42.1
- In this repository: `src/compiler/CodegenUnits.w` (#681),
  `src/compiler/Frontend.w` (the `c_import` caches),
  `docs/spec/toolchain/bundles-and-interfaces.md` (interfaces and fingerprints).
