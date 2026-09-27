# D50 — The build keys work on what it is made from: content of inputs and the producing tool, never a commit, a checkout or the build driver

**Date:** 2026-09-20. **Status:** ruled (Eric: "our entire build process is absolutely addicted to re-doing things it's already done"; after the survey and the reference comparison, "correct. please implement it").

**Context.** A survey of one battery (build 274 s, fixpoint 107 s, test 836 s) and the cache code found the redo had one shape: identity standing in for content. `:fixpoint` recompiled what `build` had just compiled; every action's key carried the orchestrating binary; the compiler named its checkout in DWARF, in module link-name hashes and in the linker's debug map, so nothing built in one worktree was usable in another; green evidence named a commit (D49).

**What the others do** (verified in `.reference/`). Go: action ID = content of inputs + the ID of the tool that produces the output; dependents hash a dependency's *content* ID, so a byte-identical rebuild stops there; `-trimpath` always; one per-user cache; test results cached on the binary plus what the test read. Zig: content digests + compiler version; byte-for-byte stage3/stage4 in CI release scripts only; manifests store prefix-relative paths. Rust: "uplifts" a later stage from artifacts an earlier one built (`compile.rs:1089`); `omit-git-hash` on by default for dev ("can cause a lot of rebuilds"); `remap-debuginfo`; `download-rustc = if-unchanged`. Scala 3: two compiles, API-hash early cutoff, `-sourceroot`. Bazel (Mojo's tree): content digests, hermetic, shared disk and remote caches. Vale: `sbt clean` and `rm -rf` every build — the counter-example.

**Decisions.**
1. `:fixpoint` compares the unit digests of the two compiles the build already does (`stage2`; `link-compiler`, which is a stage3). No extra compile, and the whole compiler: the old objects were `--emit-obj` module objects holding main.w alone. (#1224)
2. An action that names its compiler keys on the seed `WITH` names, not on the orchestrator; a workspace compile keeps the driver, which is its producer. The state records each signature component so a stale reason names what changed. (#1225)
3. `WITH_FILE_PREFIX_MAP=<from>=<to>` (clang's `-ffile-prefix-map`): the mapped root is what enters the DWARF compile unit, the module link-name hash and, with `-oso_prefix`, the debug map. The compiler's own build maps its root to `/with-src`. One commit built in two worktrees gives a byte-identical release compiler. Debuggers map back: `settings set target.source-map /with-src <checkout>`.

**Still to do, in order:** a per-user content-addressed artifact store (a known tree's compiler is fetched, not built: Rust's `if-unchanged`); early cutoff on a dependency's output content (Go's content ID); no commit stamp in dev builds (stamp at install/package); cacheable test lanes (Zig: a run step is cached unless it declares side effects). Withdrawn: a finer-than-whole-compiler test fingerprint — Rust's compiletest and Go both invalidate every test when the compiler changes.

**Reopen if** two builds of one identity are found to behave differently; fix the nondeterminism, do not re-key on identity.

---
