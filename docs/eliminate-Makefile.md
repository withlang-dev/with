# Eliminate Makefile

Status: active plan.

This document replaces the stale `docs/build-plan.md` / `docs/build-spec.md`
pair as the active cleanup plan for removing the repository Makefile and all
post-seed repository scripts. The historical build-system plan and final-state
spec are archived under `docs/completed/`.

Goal: after a platform has its first working With seed, the With repository can
build, test, verify, fetch/update SDK dependencies, cross-build supported
targets, package releases, install/update seeds, and run CI through the
self-hosted `build.w` framework. No normal post-seed workflow may depend on a
repository shell, PowerShell, CMD, Python, or host utility script.

Bootstrap exception: bringing up the first seed on a new platform may use any
system dependencies it needs: shell, PowerShell, CMD, Python, host compilers,
host archive tools, package managers, host CMake/Ninja/Make, and other external
commands. Bootstrap is the only process with that permission, because no
self-hosted seed exists yet. That exception ends once the platform has a seed.
All other workflows -- build, test, release, package, install, deps, CI,
cross, and post-seed seed/SDK refresh -- must depend only on the seed,
self-hosted With code, With-owned fetched artifacts, and OS system calls.

## Policy

Allowed after first seed:

- `with` / staged `with` compiler binaries built by this repository;
- binaries produced by the build and executed as declared test artifacts;
- With-owned SDK tools fetched or built through declared `with build` targets
  and addressed by path from the graph, not discovered from the host;
- OS loader/kernel behavior required to execute those binaries.

Forbidden after first seed:

- `Makefile` as build dispatch or compatibility glue;
- `.sh`, `.ps1`, or `.cmd` scripts for build, test, release, package, install,
  seed, SDK, or cross workflows;
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
system calls.

Hidden directories are maintainer-owned by default. Files under any path segment
whose name begins with `.` are outside the agent-actionable scope of this plan
unless the maintainer explicitly names them. The one standing exception is
`.github/workflows/`, which is repository CI configuration and is in scope for
Makefile-elimination work. Audits may mention other hidden-directory
dependencies as external state, but agents must not edit, delete, move, or
classify other hidden-directory contents such as `.demo/` as cleanup work
without a direct instruction.

## Current State

Already true:

- `with build` is the authoritative stage-chain build.
- Direct graph targets exist for stage1/stage2/stage3, runtime, build,
  selfcheck, fixpoint, test, install, install-user, seed, deps, clean, PCRE2,
  emit-C, release UAT, prune, test-green, and last-green workflows.
- `with build :seed` and `with build :deps` are the graph targets for fetching
  the release seed and static LLVM SDK when a With compiler already exists.
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

Still blocking Makefile and script removal:

- A clean checkout with no `with` binary still relies on Makefile logic,
  installer scripts, or manual release-asset fetching to acquire the first
  seed.
- Release packaging is script-driven:
  - `scripts/package-darwin-aarch64.sh`
  - `scripts/package-linux-x86_64.sh`
  - `scripts/package-windows-x86_64.ps1`
  - `scripts/package-bootstrap-c.sh`
  - `scripts/package-llvm-sdk.sh`
  - `scripts/package-llvm-sdk-windows-x86_64.ps1`
- Release installer assets are scripts:
  - `scripts/install.sh`
  - `scripts/install.ps1`
  - `scripts/install.cmd`
- First-platform SDK bootstrap flows are allowed to be script-driven inside the
  bootstrap runbook. Post-seed SDK rebuild and packaging flows still need graph
  replacements for:
  - `tools/build-ninja.sh`
  - `tools/build-ninja.ps1`
  - `tools/build-cmake.sh`
  - `tools/build-cmake.ps1`
  - `tools/build-static-llvm.sh`
  - `tools/build-static-llvm.ps1`
- Build-system maintenance still relies on host utilities for release/SDK
  packaging work. Repository build evidence, compiler seed hashes, generic
  `std.build` download checksum verification, and optional stack-budget
  inspection use With-owned tools or explicit With-owned SDK tool paths.
- `ToolFs.write_tar()` and `ToolFs.extract_tar()` provide native
  uncompressed USTAR support for regular files and directories. Release and
  SDK packaging still need native compression, symlink metadata, archive
  manifests, and package-format targets before host `tar`/`zstd`/`zip` scripts
  can disappear.
- `ToolFs.scratch_dir()` exists, but repository build modules cannot call it
  directly until the installed seed embeds that API. PCRE2 has moved from the
  shared `out/pcre2_tmp` path to the action-scratch path convention with
  explicit transitional write scopes for old-seed compatibility.
- The active runbooks still describe release packaging and SDK packaging
  as deferred until With-native release package targets exist. Installer
  scripts are no longer required release assets in the release runbook, but the
  scripts still exist as transitional byproducts until a With-native installer
  path lands.
- Some std.build / build-cache behavior is not strong enough to be the final
  script-free contract.

## Script/Shell Dependency Audit

Audit source command:

```sh
git ls-files | rg -v '(^|/)\.[^/]+/' | rg '(\.sh$|\.ps1$|\.cmd$|\.py$|(^|/)Makefile$)'
git ls-files .github/workflows
```

This intentionally ignores untracked build outputs, `.deps`, `.reference`, and
vendored dependency trees. It also excludes maintainer-owned hidden directories
such as `.demo/`. `.github/workflows/` is the explicit hidden-directory
exception and remains in scope. Classification is for post-seed policy: a
`bootstrap-only` file may remain only behind the first-seed/new-platform
boundary; a `post-seed blocker` must be replaced or deleted before the Makefile
and script dependency are gone.

| Path | Classification | Disposition |
| --- | --- | --- |
| `.github/workflows/ci.yml` | post-seed blocker | Replace `make build` dispatch with explicit `with build` targets and declared setup steps. |
| `Makefile` | post-seed blocker | Delete after all listed aliases, cross, seed, CI, release, SDK, and install roles have With graph replacements. |
| `scripts/package-bootstrap-c.sh` | post-seed blocker | Replace with a self-hosted packaging target. |
| `scripts/package-darwin-aarch64.sh` | post-seed blocker | Replace with a self-hosted Darwin release packaging target. |
| `scripts/package-linux-x86_64.sh` | post-seed blocker | Replace with a self-hosted Linux release packaging target. |
| `scripts/package-windows-x86_64.ps1` | post-seed blocker | Replace with a self-hosted Windows release packaging target. |
| `scripts/package-llvm-sdk.sh` | post-seed blocker | Replace with self-hosted SDK packaging once archive creation/signing/validation capabilities exist. |
| `scripts/package-llvm-sdk-windows-x86_64.ps1` | post-seed blocker | Replace with self-hosted Windows SDK packaging once archive creation/signing/validation capabilities exist. |
| `scripts/install.sh` | post-seed blocker | Replace release installer behavior with a With-owned installer or direct `with build :install-user` flow. |
| `scripts/install.ps1` | post-seed blocker | Same as `scripts/install.sh` for PowerShell hosts. |
| `scripts/install.cmd` | post-seed blocker | Same as `scripts/install.sh` for CMD hosts. |
| `scripts/generate-requirements.py` | post-seed blocker | Triaged live manual generator for `docs/requirements.md`; replace with a With docs-generation target or explicitly retire the generated matrix (#593). |
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
  script paths. Release and SDK packaging are now documented as deferred until
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

## Next Work Queue

Do not stack new Makefile-elimination implementation work on top of unrelated
compiler/backend fixes. If the worktree contains a verified compiler fix, commit
that logical change first, then continue with this queue.

1. **Defer release and SDK packaging until archive/package capabilities mature.**
   Package targets still need native compression, symlink archive metadata,
   deterministic manifests, package-format decisions, binary inspection, and
   With-owned strip/symbol checks. Start those after the cache/explain/runbook
   groundwork makes failures diagnosable.

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
  native uncompressed USTAR file/directory archive support exists; native
  compression, symlink archive metadata, HTTP fetch, and richer platform path
  handling remain.
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
- [x] Ensure post-seed seed refresh is only `with build :seed`, implemented in With
  code with declared network access, host asset selection, checksum
  verification, executable-bit handling, and loud unsupported-host diagnostics.
- [x] Ensure the path downloads the host-named release asset (`with-darwin-aarch64`,
  `with-linux-x86_64`, `with-windows-x86_64.exe`) into `src/main`.
- [x] Ensure the path does not publish or depend on an asset named `main`.
- [x] Remove installer-script dependency from CI and post-seed runbooks. A user or
  CI job that already has a seed must not use `install.sh`, PowerShell, CMD,
  `curl | sh`, or equivalent script bootstrap.

Defense: deleting Make without defining the bootstrap boundary breaks clean CI
and new contributor checkout flows. Leaving installer scripts in the normal
path preserves the external dependency under another name.

### 6. Move SDK build and SDK packaging into `build.w`

The static LLVM/Clang/lld SDK is a With-owned toolchain artifact. Its post-seed
construction and packaging must be graph targets, not shell or PowerShell
scripts.

- Add graph targets for SDK bootstrap-tool production after a seed exists:
  - `with build :sdk-ninja`
  - `with build :sdk-cmake`
  - `with build :sdk-llvm`
  - `with build :sdk`
- Reimplement the behavior of `tools/build-ninja.*`, `tools/build-cmake.*`,
  and `tools/build-static-llvm.*` in With build modules. The graph may invoke
  previously fetched With-owned CMake/Ninja/Clang/lld binaries, but must not
  discover or invoke host Make, host Ninja, host CMake, GCC, MSVC `cl.exe`, or a
  system LLVM.
- Keep the existing SDK build scripts only as bootstrap-new-platform helpers
  until the first platform seed/SDK asset exists, then move or label them under
  the bootstrap-only boundary.
- Add graph targets for SDK packaging:
  - `with build :package-llvm-sdk`
  - explicit platform aliases where useful, such as
    `:package-llvm-sdk-darwin-aarch64`, `:package-llvm-sdk-linux-x86_64`, and
    `:package-llvm-sdk-windows-x86_64`
- Reimplement the behavior of `scripts/package-llvm-sdk.sh` and
  `scripts/package-llvm-sdk-windows-x86_64.ps1` in With. Validate required SDK
  contents, CMake cache provenance, Clang/lld/nm/strip tools, builtin headers,
  archive libraries, and platform driver symlinks.
- Implement or reuse With-owned archive, compression, and checksum support.
  Release packaging must not call host `tar`, `zip`, `zstd`, `sha256sum`,
  `shasum`, or PowerShell archive APIs.

Defense: after bootstrap, the SDK is part of the self-hosted toolchain supply
chain. If rebuilding or packaging it needs scripts, release production still
depends on host functionality outside the seed.

### 7. Move release packaging into `build.w`

Release assets are compiler outputs. They need the same graph ownership as
build, fixpoint, and tests.

- Add graph targets for platform compiler packages:
  - `with build :package-darwin-aarch64`
  - `with build :package-linux-x86_64`
  - `with build :package-windows-x86_64`
  - `with build :package-current-host`
- Add a graph target for bootstrap-C source packaging:
  - `with build :package-bootstrap-c`
- Reimplement the behavior of `scripts/package-darwin-aarch64.sh`,
  `scripts/package-linux-x86_64.sh`, `scripts/package-windows-x86_64.ps1`, and
  `scripts/package-bootstrap-c.sh` in With build modules.
- Implement release staging in With: copy binaries and resources, preserve
  executable bits, write manifests, write checksums, and produce deterministic
  archives.
- Implement platform binary inspection in With or via embedded/fetched
  With-owned tools:
  - Mach-O dylib load-command checks for Darwin;
  - ELF `DT_NEEDED` / interpreter checks for Linux;
  - PE import-table checks for Windows.
- Implement strip/symbol checks through embedded or SDK-provided With-owned
  LLVM tools. Do not call host `strip`, `nm`, `otool`, `ldd`, `dumpbin`, or
  PowerShell.
- Make package targets depend on completed build, fixpoint, test, release UAT,
  SDK provenance checks, and clean release staging directories.
- Make package targets fail loudly if a platform package cannot be correctly
  produced. Do not emit partial archives or placeholder manifests.

Defense: release scripts are not less important than build scripts. A release
artifact built by shell glue is still a release that depends on host behavior
outside the seed.

### 8. Replace script installers with a With-native install path

The release currently publishes shell, PowerShell, and CMD installers. Those
are external script dependencies and must leave the normal release surface.

- Remove `install.sh`, `install.ps1`, and `install.cmd` from required release
  assets.
- Define the supported install flow:
  - first install: download the host binary asset directly and place it on
    `PATH`, or run a future With-native installer binary;
  - later updates: `with build :install-user` / `with build :update-seed` from
    a checked-out repository, guarded by test-green evidence.
- If a convenience installer remains desirable, implement it as a With program
  compiled and packaged as a binary release asset, not as a shell/PowerShell/CMD
  script.
- Update docs and release notes to stop recommending `curl | sh`,
  PowerShell-downloaded `.ps1`, or CMD wrappers.

Defense: installer scripts are executable build/release logic delivered to
users. Keeping them would contradict the post-seed self-hosting rule.

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
  `scripts/package-*`, `scripts/install.*`, host `tar`, host checksum tools,
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

Only after the preceding tasks pass:

- Remove `Makefile`.
- Remove release package scripts:
  - `scripts/package-darwin-aarch64.sh`
  - `scripts/package-linux-x86_64.sh`
  - `scripts/package-windows-x86_64.ps1`
  - `scripts/package-bootstrap-c.sh`
  - `scripts/package-llvm-sdk.sh`
  - `scripts/package-llvm-sdk-windows-x86_64.ps1`
- Remove installer scripts:
  - `scripts/install.sh`
  - `scripts/install.ps1`
  - `scripts/install.cmd`
- Remove or move SDK build scripts behind the bootstrap-only boundary:
  - `tools/build-ninja.sh`
  - `tools/build-ninja.ps1`
  - `tools/build-cmake.sh`
  - `tools/build-cmake.ps1`
  - `tools/build-static-llvm.sh`
  - `tools/build-static-llvm.ps1`
- Remove Python build checker scripts after their With replacements land.
- Run a repository audit:
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

Before deleting Makefile and scripts:

```sh
with build
with build :fixpoint
with build :test
with build :pcre2-reference
with build :pcre2-migrate
with build :pcre2-build
with build :pcre2-test
with build :pcre2-promote
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

After deleting Makefile and scripts:

```sh
git diff --check
with build
with build :fixpoint
with build :test
with build :test-green
```

Then run the script audit:

```sh
find . -mindepth 1 -type d -name '.*' -prune -o -type f \( -name '*.sh' -o -name '*.ps1' -o -name '*.cmd' \) -print
rg -n "Makefile|make |sh -c|bash -c|powershell|scripts/package-|scripts/install|generate_wl_stubs|check-no-c-export.py|check-requirements-informative.py|check-spec-inventory.py"
rg -n "make |scripts/|Makefile" .github/workflows
```

The first command should return only bootstrap-boundary files outside
maintainer-owned hidden directories, if any. The second command should return
only historical archive text, bootstrap-only documentation, intentional
fixtures, or hidden-directory references that the maintainer has not brought
into scope. The third command should return nothing once CI migration is
complete.

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
- installer scripts are no longer required release assets;
- public build capabilities do not silently discard data or hide privilege use;
- target freshness uses collision-resistant fingerprints and has actionable
  explanation output;
- repository audits show no post-seed `.sh`, `.ps1`, `.cmd`, Python build
  helpers, Makefile dispatch, or shell command strings remain;
- the Makefile is deleted.
