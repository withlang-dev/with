# Eliminate Makefile

Status: completed; archived as the post-Makefile verification record.

This document replaced the stale `docs/build-plan.md` / `docs/build-spec.md`
pair as the cleanup record for removing the repository Makefile and all
post-seed repository scripts. The historical build-system plan and final-state
spec are archived under `docs/completed/`.

Goal: after a platform has its first working With seed, the With repository can
build, test, verify, fetch/update SDK dependencies, cross-build supported
targets, package releases, update/install seeds from a checkout, and run CI through the
self-hosted `build.w` framework. No normal post-seed workflow may depend on a
repository shell, PowerShell, CMD, Python, or host utility script.

Bootstrap exception: bringing up the first seed on a new platform may use any
system dependencies it needs: shell, PowerShell, CMD, Python, host compilers,
host archive tools, package managers, host CMake/Ninja/Make, and other external
commands. Bootstrap is the only process with that permission, because no
self-hosted seed exists yet. That exception ends once the platform has a seed.
All other repository workflows -- build, test, release packaging, deps, CI,
cross, and post-seed seed/SDK refresh/install -- must depend only on the seed,
self-hosted With code, With-owned fetched artifacts, and OS system calls.
The retained `scripts/install.*` files are outside that repository build graph:
they are convenience first-install downloaders for published compiler binaries,
not build, package, CI, seed-refresh, or SDK-refresh steps.

## Policy

Allowed after first seed:

- `with` / staged `with` compiler binaries built by this repository;
- binaries produced by the build and executed as declared test artifacts;
- With-owned SDK tools fetched or built through declared `with build` targets
  and addressed by path from the graph, not discovered from the host;
- OS loader/kernel behavior required to execute those binaries.

Forbidden after first seed:

- `Makefile` as build dispatch or compatibility glue;
- `.sh`, `.ps1`, or `.cmd` scripts for build, test, release packaging,
  package production, post-seed repository install/update, seed, SDK, or cross
  workflows;
- Python helper scripts as build logic;
- shell command strings such as `sh -c`, `bash -c`, pipes, globbing, `find`,
  `sed`, `wc`, `cp`, `chmod`, `tar`, `zip`, `curl`, `shasum`, `otool`, `ldd`,
  or platform equivalents as hidden build dependencies;
- system LLVM, GCC, MSVC `cl.exe`, host CMake, host Ninja, host Make, host
  `tar`/`zstd`/`zip`, or host package-manager tools in normal release paths.

If a workflow needs filesystem traversal, network fetch, archive extraction,
archive creation, checksums, binary inspection, stripping, subprocess
execution, or install-path mutation, that capability belongs in With code and
must be exposed through `std.build` / project-local build modules with declared
inputs, outputs, and effects.

### Bootstrap Boundary

`docs/with-bootstrap-runbook.md` is the canonical place for system-dependent
first-seed and first-SDK instructions. It may name external tools and host
commands freely, as long as the instructions are explicitly inside the
bootstrap boundary.

`docs/with-release-runbook.md`, `with build`, tests, package targets, normal
SDK/seed refresh, and CI after seed acquisition are not bootstrap. They must not
depend on repository scripts or host utility behavior outside the seed and OS
system calls. Standalone installer scripts may be documented only as optional
published-binary downloaders; they are not a repository build path.

Hidden directories are maintainer-owned by default. Files under any path segment
whose name begins with `.` are outside the agent-actionable scope of this plan
unless the maintainer explicitly names them. The one standing exception is
`.github/workflows/`, which is repository CI configuration and is in scope for
Makefile-elimination work. Audits may mention other hidden-directory
dependencies as external state, but agents must not edit, delete, move, or
classify other hidden-directory contents such as `.demo/` as cleanup work
without a direct instruction.

## Current State

Implemented:

- `with build` is the authoritative stage-chain build.
- Direct graph targets exist for stage1/stage2/stage3, runtime, build,
  selfcheck, fixpoint, test, install, install-user, seed, deps, clean, PCRE2,
  zlib, emit-C, release UAT, bootstrap-C packaging, platform compiler
  packaging, SDK source/rebuild/package, requirements generation, prune,
  test-green, and last-green workflows.
- `with build :seed` and `with build :deps` are the graph entry points for
  fetching the release seed and static LLVM SDK when a With compiler already
  exists. They use With-owned HTTPS fetch helpers; `:deps` consumes `.tar.gz`
  SDK assets, gunzips them with migrated zlib, and extracts them with native
  `ToolFs.extract_tar()`. Both paths verify published `.sha256` sidecars.
- Release and bootstrap runbooks use `with build` for compiler verification
  gates.
- The build graph has repository locking, build-state files, and target
  freshness checks.
- Install/update-seed are gated through last-green/check-committed state.
- CI downloads the release seed in an explicit bootstrap setup step, fetches the
  SDK through `with build :deps`, and then runs direct `with build`,
  `with build :fixpoint`, and `with build :test` commands.
- `with build :cross` exists and fails loudly because non-native codegen/linking
  is not implemented yet. The stale Make-only Zig shell workflow has been
  removed.
- `with build :package-current-host`, `:package-darwin-aarch64`,
  `:package-linux-x86_64`, and `:package-windows-x86_64` produce platform
  compiler assets through With graph actions.
- `with build :package-llvm-sdk`,
  `:package-llvm-sdk-darwin-aarch64`,
  `:package-llvm-sdk-linux-x86_64`, and
  `:package-llvm-sdk-windows-x86_64` produce static SDK `.tar.gz` assets,
  `.sha256` sidecars, and manifests through With graph actions. The actions
  validate required SDK contents and reject invalid CMake-cache provenance.
- `with build :sdk-ninja`, `:sdk-cmake`, `:sdk-llvm`, and `:sdk` are the
  post-seed SDK rebuild path. They use previously fetched With-owned
  CMake/Ninja/Clang/lld tools instead of discovering host build tools.
- `with build :requirements` and `:requirements-check` replace the old Python
  requirements generator. `:test` includes the check target.
- The repository `Makefile`, release package scripts, SDK package scripts, and
  Python requirements generator have graph replacements and are removed by this
  change.
- Release convenience installers are scripts and are intentionally retained
  outside the build graph:
  - `scripts/install.sh`
  - `scripts/install.ps1`
  - `scripts/install.cmd`
- First-platform SDK bootstrap flows are allowed to be script-driven inside the
  bootstrap runbook. They are not the post-seed SDK rebuild or packaging path:
  - `tools/build-ninja.sh`
  - `tools/build-ninja.ps1`
  - `tools/build-cmake.sh`
  - `tools/build-cmake.ps1`
  - `tools/build-static-llvm.sh`
  - `tools/build-static-llvm.ps1`
- Build-system maintenance no longer relies on host `curl`, `tar`, or `zstd`
  for seed/deps fetching, PCRE2/zlib reference fetching/extraction, or generic
  `std.build` download/tar.gz extraction actions.
- `ToolFs.write_tar()` and `ToolFs.extract_tar()` provide native USTAR support
  for regular files, directories, symlinks, GNU long names, and PAX path
  metadata. Build-action tar extraction streams file payloads, so large SDK
  source archives such as the LLVM source tar do not have to fit in a `str` or
  `Vec[u8]`. Symlink validation allows relative links that normalize inside the
  extraction root and rejects escaping targets. `ToolFs.write_tar_gz()` provides
  deterministic gzip-wrapped tar output. The migrated `std.zlib` facade
  supports zlib/gzip decompression and gzip compression; `build/zlib.w` uses a
  With HTTP helper plus migrated zlib gunzip helper plus `ToolFs.extract_tar()`
  for `:zlib-reference`. Bootstrap-C, platform compiler, and SDK packaging are
  graph-owned.
- `ToolFs.scratch_dir()` exists, but repository build modules cannot call it
  directly until the installed seed embeds that API. PCRE2 has moved from the
  shared `out/pcre2_tmp` path to the action-scratch path convention with
  explicit transitional write scopes for old-seed compatibility.
- The active runbooks describe SDK packaging through With-native SDK package
  targets. Installer scripts are retained as convenience first-install
  downloaders only; they are not blockers for Makefile elimination and must not
  be used by post-seed CI, release packaging, seed refresh, SDK refresh, or
  repository install/update flows.

Verification record and release-only follow-up:

- Local verification from this change passed: focused source checks for the
  touched build/compiler modules, `git diff --check`, `with build`,
  `with build :fixpoint`, `with build :test`, `with build :test-green`,
  `with build :sdk-ninja-source --no-deps`,
  `with build :sdk-cmake-source --no-deps`, and
  `with build :sdk-llvm-source --no-deps`.
- Final repository audit passed on 2026-06-24: `Makefile` is absent; the tracked
  script audit returns only retained convenience installers and first-SDK
  bootstrap scripts; CI has no Make or repository script invocation; remaining
  PowerShell hits are bootstrap-runbook examples and installer internals.
- Native SDK packaging on each supported host remains release-matrix
  verification when producing SDK assets. The local Darwin `.deps` SDK used
  during this change was intentionally rejected because its CMake cache names
  `/usr/bin/cc`; that is the provenance tripwire working, not a packaging
  fallback.
- The long SDK rebuild targets run when intentionally producing a new SDK asset
  or bumping `COMPILER_LLVM_VERSION`. They are not normal release rebuild
  steps.

## Script/Shell Dependency Audit

Audit source command:

```sh
git ls-files | rg -v '(^|/)\.[^/]+/' | rg '(\.sh$|\.ps1$|\.cmd$|\.py$|(^|/)Makefile$)'
git ls-files .github/workflows
```

Run this audit after the deletion commit. It intentionally ignores untracked
build outputs, `.deps`, `.reference`, and vendored dependency trees. It also
excludes maintainer-owned hidden directories such as `.demo/`. `.github/workflows/`
is the explicit hidden-directory exception and remains in scope. Classification
is for post-seed policy: a `bootstrap-only` file may remain only behind the
first-seed/new-platform boundary; no `post-seed blocker` paths should remain.

| Path | Classification | Disposition |
| --- | --- | --- |
| `.github/workflows/ci.yml` | bootstrap-boundary CI setup | CI no longer invokes Make; it uses a bootstrap seed acquisition step, then `with build :deps`, `with build`, `with build :fixpoint`, and `with build :test`. |
| `scripts/install.sh` | retained convenience installer | Keep as the Unix first-install downloader for the latest published platform compiler binary. It must not be invoked by CI, package targets, seed refresh, SDK refresh, or repository post-seed install/update flows. |
| `scripts/install.ps1` | retained convenience installer | Keep as the PowerShell first-install downloader for the latest published Windows compiler binary, with the same build-graph boundary as `scripts/install.sh`. |
| `scripts/install.cmd` | retained convenience installer | Keep as the CMD wrapper for the PowerShell first-install downloader, with the same build-graph boundary as `scripts/install.sh`. |
| `tools/build-ninja.sh` | bootstrap-only | Keep only for first SDK bootstrap until With-owned bootstrap tooling exists. |
| `tools/build-ninja.ps1` | bootstrap-only | Windows first-SDK bootstrap counterpart. |
| `tools/build-cmake.sh` | bootstrap-only | Keep only for first SDK bootstrap until With-owned bootstrap tooling exists. |
| `tools/build-cmake.ps1` | bootstrap-only | Windows first-SDK bootstrap counterpart. |
| `tools/build-static-llvm.sh` | bootstrap-only | Keep only for first With-owned LLVM SDK creation on a platform; repeat SDK production must be graph-owned. |
| `tools/build-static-llvm.ps1` | bootstrap-only | Windows first-LLVM-SDK bootstrap counterpart. |

## Progress

- 2026-06-14: Fixed `ToolFs.write_binary` so it writes the provided byte
  payload and added a build.w selfhost regression that round-trips non-text
  bytes through `write_binary` and `read_binary`.
- 2026-06-14: Replaced `scripts/check-no-c-export.py` with a pure With build
  action and deleted the script.
- 2026-06-14: Replaced `scripts/check-requirements-informative.py` with a pure
  With build action and deleted the script.
- 2026-06-14: Documented direct replacements for Make compatibility aliases in
  `docs/with-build.md`; at that point `make cross`, first-seed bootstrap, and
  `make print-version` remained explicit exceptions.
- 2026-06-14: Replaced `scripts/check-spec-inventory.py` with a pure With
  build action and deleted the script.
- 2026-06-14: Removed `sh -c`/`find`/`sed`/`wc` shell fragments from
  `build/retention.w` prune reporting/deletion and switched test `.w`
  manifest discovery to typed `ToolFs.list_files` traversal. Checksums still
  used host `shasum`/`sha256sum` pending the native hashing capability.
- 2026-06-14: Converted `install-user` and `update-seed` to graph `Install`
  targets, removing the old action that spawned host `mkdir`, `cp`, and
  `chmod`.
- 2026-06-14: Added `ToolFs.scratch_dir()` as an action-scoped, driver-managed
  scratch capability with selfhost coverage for write authority and cleanup.
  PCRE2 no longer uses `out/pcre2_tmp`; it uses the action-scratch path
  convention with explicit transitional scopes until a seed containing the new
  API is installed.
- 2026-06-14: Hardened `ProcessRunner.run_spec` so unsupported capture/stdin
  combinations fail loudly, added small `ProcessSpec` builder methods, and
  covered the path in build.w selfhost tests.
- 2026-06-15: Added `with build :print-version` as the Make replacement for
  repository version printing. It uses the compiler version rule
  (`WITH_VERSION`, then `src/version-g<short_hash>`, then `src/version`) and is
  deliberately always-run so it prints every invocation.
- 2026-06-15: Added the self-hosted `with-sha256` utility, built by the graph
  from `tools/with-sha256.w`, and replaced repository build evidence,
  test-green/last-green, and compiler seed-input hashing with that tool.
- 2026-06-15: Added `ToolFs.host_read_text` for future external file hashing
  and added build.w selfhost coverage for action timeout/cwd/env/network
  metadata plus `ProcessSpec` cwd and timeout behavior.
- 2026-06-15: Added `ToolFs.sha256_file()` backed by the BearSSL-derived
  `std.crypto.sha256` implementation, wired the tool-mode evaluator to hash
  files natively, and removed host `shasum` from `Build.download`
  verification.
- 2026-06-15: Audited tracked repository shell, PowerShell, CMD, Python,
  Makefile, and workflow files into bootstrap-only, post-seed blocker, and
  historical/non-build buckets.
- 2026-06-15: Replaced `test/lsp/run_lsp_tests.sh` with the
  `with build :cli-selfhost-lsp-tests` action target and wired it into
  `with build :test`.
- 2026-06-15: Replaced `scripts/check-stack-budget.py` with the explicit
  `with build :stack-budget-check` target. The action classifies PE/ELF/Mach-O
  binaries, invokes the pinned LLVM SDK `llvm-readobj` / `llvm-dwarfdump`
  paths, writes `out/test-graph/stack-budget-check/report.txt`, and enforces
  the previous 64 KiB default budget when run.
- 2026-06-15: Added native uncompressed USTAR creation/extraction to
  `ToolFs.write_tar()` / `ToolFs.extract_tar()` with build.w selfhost coverage
  for directory entries, text files, and binary payloads.
- 2026-06-15: Removed installer scripts from the required release asset and
  upload lists in the release runbook, and clarified in the bootstrap runbook
  that `scripts/install.*` is not the post-seed handoff path; post-seed updates
  use `with build :install-user` / `with build :update-seed`.
- 2026-06-15: Triaged `scripts/generate-requirements.py`. It is not wired into
  `build.w` or current runbooks, but it remains the only known generator for
  `docs/requirements.md` and does not reproduce the committed matrix as a
  no-op. Filed #593 to replace it with a With docs-generation target or
  explicitly retire the generated requirements matrix.
- 2026-06-15: Finished capability denial coverage for action writes and process
  execution. `ActionCtx.process_runner()` now inherits action network/write
  declarations, `ProcessRunner` capture paths must stay within declared action
  outputs/write scopes, and build.w selfhost covers undeclared process capture
  output denial plus an allowed-network process case.
- 2026-06-16: Deleted the unused top-level `memlimit.sh` historical script.
- 2026-06-16: Cleaned the release runbook away from normal post-seed package
  script paths. Release and SDK packaging are now documented as blocked until
  With-native package targets provide archive creation, validation, stripping,
  and binary inspection without host shell, PowerShell, `tar`, `zstd`, `otool`,
  `ldd`, or symbol utilities.
- 2026-06-16: Replaced build-cache freshness fingerprints with `v2`
  SHA-256-backed file-state fingerprints that include absent state, file kind,
  mode/executable bits, symlink targets on POSIX, effect logs, environment
  values, tool identities, and action signatures.
- 2026-06-16: Extended `with build --explain <target>` with freshness reasons,
  including no state, signature changes, changed inputs/dependencies/env/effect
  logs, missing outputs, and changed outputs.
- 2026-06-16: Replaced the stale `make cross` shell workflow with
  `with build :cross`, which fails loudly until cross-target codegen/linking is
  implemented, and deleted `scripts/generate_wl_stubs.sh`.
- 2026-06-16: Migrated `.github/workflows/ci.yml` off Make and system LLVM.
  The workflow now isolates release-seed download as the bootstrap setup step,
  fetches the SDK with `with build :deps`, then runs direct build/fixpoint/test
  graph targets.
- 2026-06-19: Added zlib graph pipeline targets through
  `:zlib-reference`, `:zlib-migrate`, `:zlib-build`, `:zlib-test`,
  `:zlib-check-generated`, and `:zlib-promote`; added a `std.zlib` facade; and
  removed host `curl`, `shasum`, and `tar -xzf` from `build/zlib.w`.
  `:zlib-reference` now fetches through a With HTTP helper, verifies with
  `ToolFs.sha256_file()`, gunzips through migrated zlib, and extracts with
  native `ToolFs.extract_tar()`.
- 2026-06-19: Removed host `curl`/`tar -xzf` from `:pcre2-reference` and host
  `curl`/`zstd`/`tar` from `:seed`/`:deps`. These targets now fetch through
  With-built HTTPS helpers; PCRE2 and SDK `.tar.gz` archives gunzip through
  migrated zlib and extract through native `ToolFs.extract_tar()`. SDK release
  assets are now named `with-llvm-sdk-<llvm-ver>-<platform>.tar.gz`.
- 2026-06-19: Added symlink USTAR entries and deterministic gzip tar writing
  to `std.build`/tool-mode evaluation, added gzip compression to `std.zlib`,
  and replaced `scripts/package-bootstrap-c.sh` with
  `with build :package-bootstrap-c`, which stages emitted C sources and
  bootstrap platform shims, writes `SHA256SUMS`, and produces
  `out/release/with-bootstrap-c-<version>.tar.gz`.
- 2026-06-19: Replaced generic `std.build` host `curl` and `tar xzf` actions.
  `Build.download()` now compiles and runs a With HTTPS helper, and
  `Build.extract_tar_gz()` compiles and runs a With zlib gunzip helper before
  extracting with native `ToolFs.extract_tar()`. Added build.w selfhost coverage
  for `Build.extract_tar_gz()`.
- 2026-06-19: Added platform compiler package targets:
  `:package-current-host`, `:package-darwin-aarch64`,
  `:package-linux-x86_64`, and `:package-windows-x86_64`. The native package
  action enforces host/platform matching, exact `WITH_VERSION` evidence,
  SDK-owned binary dependency inspection, SDK `llvm-strip`, static libclang
  symbol checks where supported, and SHA-256 sidecar output.
- 2026-06-19: Added SDK source, rebuild, and package graph targets:
  `:sdk-ninja-source`, `:sdk-cmake-source`, `:sdk-llvm-source`,
  `:sdk-ninja`, `:sdk-cmake`, `:sdk-llvm`, `:sdk`, `:package-llvm-sdk`, and
  native platform package aliases. SDK package actions validate required tools,
  clang builtin headers, static archives, lld driver links, and CMake-cache
  compiler provenance before producing `.tar.gz`, `.sha256`, and manifest
  outputs.
- 2026-06-19: Extended native tar extraction for upstream PAX metadata and GNU
  long names so GitHub source archives used by SDK source targets extract
  without host `tar`.
- 2026-06-20: Changed build-action tar extraction to stream from disk instead
  of reading the archive into `str`, fixed migrated zlib gunzip to stream large
  decompressed tar output, and accepted relative symlink targets that normalize
  inside the extraction root. Verified `with build :sdk-llvm-source --no-deps`
  against the 2.16 GiB LLVM source tar, including the CUDA symlink fixture that
  uses `../../opt/cuda/bin/ptxas`.
- 2026-06-19: Added `.sha256` sidecar verification to `with build :seed` and
  `with build :deps`.
- 2026-06-19: Replaced `scripts/generate-requirements.py` with
  `with build :requirements` and `with build :requirements-check`, and wired
  the check into `with build :test`.
- 2026-06-19: Deleted the repository `Makefile`, release package scripts, SDK
  package scripts, and the Python requirements generator after their graph
  replacements landed.
- 2026-06-24: Re-ran the final repository audit. The Makefile remains absent,
  tracked scripts are limited to retained installer and bootstrap-boundary
  files, CI does not invoke Make or repository scripts, and remaining
  PowerShell references are bootstrap-runbook examples or installer internals.

## Implementation Tasks

### 1. Fix public build capability correctness

Implement before deleting Make or scripts, because build actions must be
trustworthy once `build.w` owns every workflow.

- [x] Fix `ToolFs.write_binary(path, bytes)` so it writes the provided bytes
  instead of an empty file. Add a build-w/selfhost regression that writes
  non-text bytes and reads them back through `read_binary`.
- [x] Reconcile `ProcessRunner` with the intended struct API. Prefer adding the
  spec-shaped `ProcessRunner.run(spec: ProcessSpec) -> ProcessResult` while
  keeping old argv helpers as compatibility wrappers until build code is
  migrated. The primary public process API should be one structured value with
  argv, cwd, environment, stdin, capture, and timeout.
- [x] Add focused tests for action timeout, declared cwd/env metadata, network
  declaration, write scopes, process capture outputs, and install-path access.
  The tests prove unavailable write/install/network privileges fail loudly and
  declared network/write privileges are deliberately honored.
- [x] Decide and implement network semantics. If the local driver cannot enforce a
  true network sandbox, then network-capable standard operations such as
  downloads must still require an explicit `allow_network()` declaration and
  diagnostics must make undeclared network use visible.
- Add first-class build capabilities for binary copy, executable-bit mutation,
  recursive directory creation/removal, content hashing, archive read/write,
  HTTP(S) fetch, and platform path handling so actions do not reach for shell
  utilities.
  Binary writes, copy/chmod/tree operations, scratch dirs, repository-local
  self-hosted hashing, host file reads, and project-file SHA-256 hashing exist;
  native USTAR file/directory/symlink archive support exists; deterministic
  gzip tar creation exists; zlib/gzip compression and decompression exist
  through `std.zlib`; named repository fetch targets use project-local With
  HTTPS helpers; generic `Build.download()` and `Build.extract_tar_gz()` no
  longer invoke host `curl` or host `tar`. Richer platform path handling
  remains.
- [x] Implement `ToolFs.scratch_dir() -> str` as an action-scoped, driver-managed
  scratch directory. The returned path must be project-relative, private to the
  current action invocation, automatically included in that action's write
  authority, and cleared before non-cache action runs. Migrate manual scratch
  paths such as `out/pcre2_tmp` to this capability.

Defense: these are public `std.build` capability boundaries. Silent data loss,
unclear process semantics, or untested privilege declarations would make
Makefile/script removal trade one unsafe surface for another.

### 2. Make incrementality safe enough to rely on

The build graph already skips fresh targets. That means cache correctness is a
build correctness issue, not a speed feature.

- [x] Replace `with_str_hash` build-cache fingerprints with a cryptographic content
  hash for files, directories, environment effects, effect logs, and action
  signatures.
- [x] Include file kind, executable bit where relevant, symlink target, and absent
  state in fingerprints.
- [x] Include project-local action implementation identity in action signatures:
  either a declared implementation version or a stable function/body
  fingerprint. If unavailable, treat the action as stale.
- [x] Teach `--explain <target>` to report freshness decisions, including the first
  stale input, output, dependency, tool, environment variable, or signature
  mismatch. The current target-shape dump is useful but insufficient.
- [x] Add tests that prove changed inputs rerun, changed outputs rerun, changed
  build/action source reruns, changed declared environment reruns, and unchanged
  targets skip.

Defense: once CI and developers call `with build` directly, a false cache hit
is indistinguishable from a successful build. The cache must prove freshness or
rebuild.

### 3. Replace script-shaped build internals

The Makefile can disappear only after the repository build graph is not quietly
depending on scripts or shell fragments for normal maintenance.

- [x] Replace `build/retention.w` shell snippets used for prune counts, samples,
  and `.w` manifest hashing with typed filesystem traversal and With-native
  hashing.
- [x] Move `scripts/check-no-c-export.py` into a With build action that reads source
  files directly and reports the same violations.
- [x] Move `scripts/check-requirements-informative.py` into a With build action.
- [x] Move `scripts/check-spec-inventory.py` into a With build action.
- [x] Move `test/lsp/run_lsp_tests.sh` into a With build action and delete the
  shell wrapper.
- [x] Move `scripts/check-stack-budget.py` into an explicit With build action
  that uses declared SDK-owned LLVM tools instead of Python and host tool
  discovery.
- [x] Audit `build/`, `src/`, `lib/`, `rt/`, `build.w`, `scripts/`, and `tools/`
  for `sh -c`, `bash -c`, `powershell`, `.py`, `.sh`, `.ps1`, `.cmd`, pipes,
  redirects, and shell utility names. Every post-seed hit must be eliminated or
  moved behind the explicit bootstrap-only boundary.
- Keep external program execution only where the external program is a declared
  With-owned toolchain binary, a compiler stage, a build output under test, or
  an upstream test program whose use is explicitly modeled as an input to the
  target.

Defense: otherwise Make disappears but the build remains partly script-defined.
The goal is not cosmetic deletion; it is a With-owned build graph.

### 4. Replace `make cross`

- [x] Define the intended cross-build command surface. Preferred shape:
  `with build :cross --target <target>` or explicit graph targets named
  `cross-<target>`.
- [x] Move emitted-C cross generation into `build.w` / project-local modules.
  Cross is currently unsupported, so the old emitted-C/Zig workflow was removed
  rather than preserved.
- [x] Replace `scripts/generate_wl_stubs.sh` with With code or remove the need for
  generated stubs entirely. If the stubs remain necessary, generation must fail
  loudly on unclassified declarations and produce deterministic output.
- [x] Use the With-owned static SDK Clang/lld toolchain for compiler-artifact C
  builds. Do not make Zig, GCC, or MSVC `cl.exe` part of the canonical path.
- [x] Add graph outputs under `out/cross/<target>/` with declared inputs, outputs,
  deps, and cleanup/prune coverage.
- [x] Add a smoke target for every supported cross target that can be validated on
  the host without pretending it ran natively.
- [x] Update docs to say whether cross is supported, experimental, or unsupported.
  Do not leave a hidden Make-only workflow.

`with build :cross` is the current command surface. It fails loudly until
cross-target codegen/linking exists, so there are no supported cross outputs or
smoke targets yet.

Defense: the Makefile cannot be deleted while it owns cross-compilation. If
cross is not worth preserving, the correct replacement is a loud unsupported
diagnostic and removal of the stale script path.

### 5. Make seed acquisition script-free after bootstrap

A completely fresh platform cannot run `with build :seed` until it has a With
binary. That is the bootstrap exception, and it may use whatever system
dependencies the bootstrap runbook requires. Once a platform has a seed, seed
updates are normal build graph work.

- [x] Define the official first-seed bootstrap boundary. It may be a documented
  direct release-asset download or a bootstrap-only helper under a clearly named
  `tools/bootstrap/` path. It may depend on system tools, but it must not be
  described as part of normal release, development, test, package, deps, or CI
  flow.
- [x] Ensure post-seed seed refresh is only `with build :seed`, implemented in
  With code with declared network access, host asset selection, checksum
  verification, executable-bit handling, and loud unsupported-host diagnostics.
  The graph target uses a With-built HTTPS helper, fetches and verifies the
  published `.sha256` sidecar, handles the host asset name, output path, and
  executable bit, and fails loudly on unsupported hosts or checksum mismatch.
- [x] Ensure the path downloads the host-named release asset (`with-darwin-aarch64`,
  `with-linux-x86_64`, `with-windows-x86_64.exe`) into `src/main`.
- [x] Ensure the path does not publish or depend on an asset named `main`.
- [x] Remove installer-script dependency from CI and post-seed runbooks. A user or
  CI job that already has a seed must not use `install.sh`, PowerShell, CMD,
  `curl | sh`, or equivalent script bootstrap.

Defense: deleting Make without defining the bootstrap boundary breaks clean CI
and new contributor checkout flows. Using installer scripts in the normal
post-seed path would preserve the external dependency under another name.

### 6. Move SDK build and SDK packaging into `build.w`

The static LLVM/Clang/lld SDK is a With-owned toolchain artifact. Its post-seed
construction and packaging must be graph targets, not shell or PowerShell
scripts.

- [x] Add graph targets for SDK bootstrap-tool production after a seed exists:
  - `with build :sdk-ninja`
  - `with build :sdk-cmake`
  - `with build :sdk-llvm`
  - `with build :sdk`
- [x] Reimplement the behavior of `tools/build-ninja.*`, `tools/build-cmake.*`,
  and `tools/build-static-llvm.*` in With build modules. The graph may invoke
  previously fetched With-owned CMake/Ninja/Clang/lld binaries, but must not
  discover or invoke host Make, host Ninja, host CMake, GCC, MSVC `cl.exe`, or a
  system LLVM.
- [x] Keep the SDK package format aligned with `:deps`: release SDK assets are
  `.tar.gz`, because the graph can already gunzip them through migrated zlib and
  extract the tar stream natively.
- [x] Keep the existing SDK build scripts only as bootstrap-new-platform helpers
  until the first platform seed/SDK asset exists, then move or label them under
  the bootstrap-only boundary.
- [x] Add graph targets for SDK packaging:
  - `with build :package-llvm-sdk`
  - explicit platform aliases where useful, such as
    `:package-llvm-sdk-darwin-aarch64`, `:package-llvm-sdk-linux-x86_64`, and
    `:package-llvm-sdk-windows-x86_64`
- [x] Reimplement the behavior of `scripts/package-llvm-sdk.sh` and
  `scripts/package-llvm-sdk-windows-x86_64.ps1` in With. Validate required SDK
  contents, CMake cache provenance, Clang/lld/nm/strip tools, builtin headers,
  archive libraries, and platform driver symlinks.
- [x] Implement or reuse With-owned archive, compression, and checksum support.
  Release packaging must not call host `tar`, `zip`, `zstd`, `sha256sum`,
  `shasum`, or PowerShell archive APIs.

Defense: after bootstrap, the SDK is part of the self-hosted toolchain supply
chain. If rebuilding or packaging it needs scripts, release production still
depends on host functionality outside the seed.

### 7. Move release packaging into `build.w`

Release assets are compiler outputs. They need the same graph ownership as
build, fixpoint, and tests.

- [x] Add graph targets for platform compiler packages:
  - `with build :package-darwin-aarch64`
  - `with build :package-linux-x86_64`
  - `with build :package-windows-x86_64`
  - `with build :package-current-host`
- [x] Add a graph target for bootstrap-C source packaging:
  - `with build :package-bootstrap-c`
- [x] Reimplement the behavior of `scripts/package-darwin-aarch64.sh`,
  `scripts/package-linux-x86_64.sh`, and
  `scripts/package-windows-x86_64.ps1` in With build modules.
- [x] Reimplement the behavior of `scripts/package-bootstrap-c.sh` in
  `build/package.w` and delete the script.
- [x] Implement release staging in With: copy binaries and resources, preserve
  executable bits, write manifests, write checksums, and produce deterministic
  archives. Platform compiler packages copy the release binary and write
  SHA-256 sidecars; archive production applies to bootstrap-C and SDK packages.
- [x] Implement platform binary inspection in With or via embedded/fetched
  With-owned tools:
  - Mach-O dylib load-command checks for Darwin;
  - ELF `DT_NEEDED` / interpreter checks for Linux;
  - PE import-table checks for Windows.
- [x] Implement strip/symbol checks through embedded or SDK-provided With-owned
  LLVM tools. Do not call host `strip`, `nm`, `otool`, `ldd`, `dumpbin`, or
  PowerShell.
- [x] Make platform compiler package targets depend on completed build, fixpoint,
  release UAT, SDK-owned tool checks, and clean release staging directories.
  SDK provenance is enforced by the SDK package targets. Bootstrap-C packaging
  depends on the release compiler build and emitted-C source generation,
  because it is a source bundle for new-platform bring-up rather than a
  publishable compiler binary.
- [x] Make package targets fail loudly if a platform package cannot be correctly
  produced. Do not emit partial archives or placeholder manifests.

Defense: release scripts are not less important than build scripts. A release
artifact built by shell glue is still a release that depends on host behavior
outside the seed.

### 8. Retain convenience installers outside the build graph

The release keeps shell, PowerShell, and CMD convenience installers for first
install. They are not repository build/release logic: their only job is to
download the latest host platform compiler binary from GitHub and place it on
the user's PATH.

- Define the supported install flow:
  - first install: download the host binary asset directly and place it on
    `PATH`, optionally through the retained convenience installer;
  - later updates: `with build :install-user` / `with build :update-seed` from
    a checked-out repository, guarded by test-green evidence.
- Ensure CI, package targets, seed refresh, SDK refresh, and post-seed
  repository install/update docs do not invoke `scripts/install.*`, `curl | sh`,
  PowerShell-downloaded `.ps1`, or CMD wrappers.

Defense: the post-seed self-hosting rule applies to repository build graph
workflows. A standalone first-install downloader is acceptable only while it
stays outside those workflows and does not become package production logic.

### 9. Migrate CI to `with build`

- Replace `make build` in `.github/workflows/ci.yml` with the bootstrap-boundary
  seed acquisition step followed by direct `with build` commands.
- Stop installing or trusting a system LLVM as the normal CI answer. CI should
  fetch the With-owned static SDK through `with build :deps` or a release asset
  fetch path implemented in With.
- Run these gates directly in CI:
  - `with build`
  - `with build :fixpoint`
  - `with build :test`
- Add release/package CI jobs only after package targets are graph-owned:
  - `with build :package-current-host`
  - `with build :package-llvm-sdk`
- Add `with build :test-green` only if CI is meant to record evidence
  artifacts; otherwise keep it as local/release evidence.
- Keep CI output clear enough that a failure identifies seed acquisition, SDK
  acquisition, build, fixpoint, test, or packaging as the failing phase.

Defense: CI is the authoritative automated proof. If CI still invokes Make or
scripts after the migration, the repository still depends on them.

### 10. Replace or remove Make compatibility aliases

Every live Make target must have a documented direct command, an intentional
alias in `with build`, or be deleted.

Inventory and resolve:

- `all` / `build` -> `with build` or `with build :build`
- `stage1`, `stage2`, `stage3`
- `runtime`
- `selfcheck` and `smoke`
- `test` and `test-pcre2`
- `fixpoint`
- `install`, `install-user`
- `update-seed`
- `clean`
- `seed`
- `deps`
- `pcre2-migrate`, `pcre2-build`, `pcre2-test`, `pcre2-promote`
- `regex-migrate`, `regex-build`, `regex-test`, `regex-promote`
- `print-version` -> `with build :print-version`
- `emit-c-test`, `emit-c-fixpoint`, `emit-c-roundtrip`
- `cross`

For each target, either:

- document the direct `with build` / `with` command;
- add a direct graph alias if compatibility is still valuable; or
- delete the obsolete alias and update docs/tests.

Defense: hidden Make aliases keep institutional behavior outside the build
graph and make later deletion risky.

### 11. Update current documentation and runbooks

- Update `docs/with-build.md` so it links to this active plan and no longer
  names the archived build spec as the current formal contract.
- Do not revive archived umbrella proposals such as
  `docs/completed/toolchain.md`; document the actual post-Make/post-script
  state in current runbooks and user-facing docs.
- Update `docs/with-release-runbook.md` so release packaging uses only
  `with build` graph targets. Remove normal release instructions for
  `scripts/package-*`, host `tar`, host checksum tools,
  host binary-inspection tools, and PowerShell packaging.
- Update `docs/with-bootstrap-runbook.md` only to isolate and label
  first-platform bootstrap scripts and system dependencies. Do not remove host
  dependency instructions from bootstrap; bootstrap is the permitted exception.
  The runbook should state exactly when the bootstrap exception applies and when
  it stops applying.
- Update `AGENTS.md` build/toolchain/release language once Make and scripts are
  gone.
- Archive or delete stale docs that describe Make or scripts as a live
  compatibility layer.

Defense: old instructions are build inputs for agents and humans. Deleted
scripts with stale docs will waste debugging time and may corrupt the stage
chain through wrong bootstrap commands.

### 12. Delete Makefile and post-seed scripts

Completed after the graph replacements landed:

- [x] Remove `Makefile`.
- [x] Remove release package scripts:
  - `scripts/package-darwin-aarch64.sh`
  - `scripts/package-linux-x86_64.sh`
  - `scripts/package-windows-x86_64.ps1`
  - `scripts/package-llvm-sdk.sh`
  - `scripts/package-llvm-sdk-windows-x86_64.ps1`
- [x] Keep SDK build scripts behind the bootstrap-only boundary:
  - `tools/build-ninja.sh`
  - `tools/build-ninja.ps1`
  - `tools/build-cmake.sh`
  - `tools/build-cmake.ps1`
  - `tools/build-static-llvm.sh`
  - `tools/build-static-llvm.ps1`
- [x] Remove Python build checker/generator scripts after their With replacements
  land.
- [x] Run a repository audit after committing the deletions:
  - `Makefile`
  - `.sh`
  - `.ps1`
  - `.cmd`
  - `.py` build helpers
  - `make `
  - `sh -c`
  - `bash -c`
  - `powershell`
  - host utility names used as build commands
- Every remaining hit must be historical archive text, bootstrap-only
  documentation, a source fixture that intentionally discusses scripts, or a
  deliberate negative test.

Defense: this is the mechanical final step, not the migration itself.

## Verification Matrix

Full verification:

```sh
with build
with build :fixpoint
with build :test
with build :pcre2-reference
with build :pcre2-migrate
with build :pcre2-build
with build :pcre2-test
with build :pcre2-promote
with build :zlib-reference
with build :zlib-migrate
with build :zlib-build
with build :zlib-test
with build :zlib-check-generated
with build :zlib-promote
with build :emit-c-test
with build :emit-c-fixpoint
with build :emit-c-roundtrip
with build :release-uat
with build :prune
with build :prune-apply
with build :package-current-host
with build :package-llvm-sdk
```

Run cross verification for each supported target after the cross replacement
exists.

Run platform package verification natively on each supported release platform:

```sh
with build :package-darwin-aarch64
with build :package-linux-x86_64
with build :package-windows-x86_64
with build :package-bootstrap-c
```

Post-delete verification:

```sh
git diff --check
with build
with build :fixpoint
with build :test
with build :test-green
```

Then run the script audit:

```sh
git ls-files | rg -v '(^|/)\.[^/]+/' | rg '(\.sh$|\.ps1$|\.cmd$|\.py$|(^|/)Makefile$)'
rg -n "Makefile|make |sh -c|bash -c|powershell|scripts/package-|scripts/install|generate_wl_stubs|check-no-c-export.py|check-requirements-informative.py|check-spec-inventory.py"
rg -n "make |scripts/|Makefile" .github/workflows
```

The first command should return only retained convenience installers and
bootstrap-boundary files outside maintainer-owned hidden directories.
The second command should return only historical archive text, bootstrap-only
documentation, retained convenience-installer references, intentional fixtures,
or hidden-directory references that the maintainer has not brought into scope.
The third command should return nothing once CI migration is complete.

## Acceptance Criteria

Makefile and post-seed script elimination is complete only when:

- no CI workflow invokes Make or repository scripts;
- no documented normal build/test/install/seed/deps/cross/package/release
  command invokes Make, shell, PowerShell, CMD, Python helpers, or host utility
  scripts;
- first-platform bootstrap is clearly isolated from normal post-seed workflows
  and remains the only system-dependent process;
- a checkout with an existing seed can refresh seed and SDK dependencies through
  `with build` only;
- all live Make targets have direct `with` / `with build` equivalents or have
  been explicitly deleted;
- cross-compilation is either implemented in the graph or loudly removed from
  supported workflows;
- required build-system maintenance such as prune does not use shell snippets;
- action-local transient files use `ToolFs.scratch_dir()` or equivalent
  driver-managed scratch authority instead of shared/manual scratch paths;
- release compiler packages, SDK packages, bootstrap-C packages, checksums,
  manifests, and binary dependency checks are produced by graph targets;
- installer scripts remain only as optional first-install convenience
  downloaders and are not invoked by any post-seed repository workflow;
- public build capabilities do not silently discard data or hide privilege use;
- target freshness uses collision-resistant fingerprints and has actionable
  explanation output;
- repository audits show no post-seed `.sh`, `.ps1`, `.cmd`, Python build
  helpers, Makefile dispatch, or shell command strings remain;
- the Makefile is deleted.
