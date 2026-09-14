## Eliminating External Tool Dependencies

### Principle

The With compiler and build system must be self-sufficient. Every operation — compilation, assembly, archiving, path discovery, version detection — uses either LLVM APIs (already statically linked) or With runtime system calls. No `cc`, no `ar`, no `llvm-config`, no `xcrun`, no `git`.

The only subprocess calls that remain are running the With compiler itself (stage chain, test runner) and running user-specified executables (Command targets). Those are architecturally necessary.

---

### Phase 1: Pure-With archive creation

**What it replaces:** `ar rcs` subprocess (BuildGraphOps.w:186)

**Priority:** First because it's zero-risk, zero-investigation, pure With, ~100 lines.

Implement the AR format directly in With. No LLVM dependency, no platform dependency, works identically everywhere.

The format is simple:
- 8-byte magic (`!<arch>\n`)
- For each member: 60-byte header (name, timestamp, uid, gid, mode, size, magic `\x60\n`), then the file contents padded to 2-byte alignment

For long filenames (>16 chars), use the BSD `#1/` extended name format: the name is prepended to the file data and the header's name field reads `#1/<name_length>`.

**Add to runtime (`rt/rt_core.w`):**

```with
@[c_export("with_create_archive")]
pub fn create_archive(output: str, object_files: str) -> i32
```

Where `object_files` is null-separated paths (same convention as the existing argv blobs).

Alternatively, implement entirely in With in the build system layer (BuildGraphOps.w) using `with_fs_read_file` / `with_fs_write_file`. No runtime C code needed — just byte-level format construction.

**Replace in BuildGraphOps.w:186.** Remove the `ar` tool from BuildGraphTools.w.

**Verification:** Create an archive, verify with `nm` that symbols are accessible, link the compiler against it, fixpoint passes.

---

### Phase 2: SDK path discovery + seed compiler probe

**What it replaces:**
- `/usr/bin/xcrun --show-sdk-path` (build_compiler.w:166)
- `with --version` seed probe (build_compiler.w:190)

**Priority:** Second because both are trivial filesystem probes, ~15 lines each.

**SDK path — probe known paths using `with_fs_file_exists`:**

```
1. $SDKROOT environment variable (if set)
2. /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
3. /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
```

On Linux: no SDK path needed (system headers are in `/usr/include`).
On Windows: probe `%WindowsSdkDir%` or known Visual Studio paths.

**Replace in build_compiler.w:166.**

**Seed compiler probe — walk PATH with filesystem checks:**

```
1. $WITH environment variable (if set) — already checked first
2. out/bin/with — already checked
3. Walk $PATH: split on ':', check each dir for 'with' using with_fs_file_exists
4. src/main — already checked as fallback
```

This is what shell `which` does internally — a filesystem probe, not a subprocess. Replace the `with --version` subprocess call with a PATH walk.

**Replace in build_compiler.w:190.**

**Verification:** Compare discovered paths against `xcrun --show-sdk-path` and `which with` on a dev machine.

---

### Phase 3: Git-free version detection

**What it replaces:** `git rev-parse --short HEAD` and `git rev-list --count HEAD` (build_compiler.w:260-274)

**Priority:** Third because it's straightforward file reads, no external dependencies.

**Read `.git` directly through the runtime:**

```with
fn read_git_head_hash(root: str) -> str:
    let head = with_fs_read_file(root ++ "/.git/HEAD")
    if head.starts_with("ref: "):
        // HEAD is a symbolic ref like "ref: refs/heads/main\n"
        let ref_path = head.slice(5, head.len()).trim()
        let hash = with_fs_read_file(root ++ "/.git/" ++ ref_path)
        if hash.len() >= 9:
            return hash.slice(0, 9)  // short hash (9 chars, matching --short=9)
        // Loose ref doesn't exist — check packed-refs
        let packed = with_fs_read_file(root ++ "/.git/packed-refs")
        // parse lines for the matching ref
    else:
        // Detached HEAD — the file contains the hash directly
        return head.slice(0, 9)
    "unknown"
```

**Commit count:** Omit it. The reflog approach is fragile (reflogs get pruned, shallow clones don't have them). Walking the commit graph is complex and unnecessary. The version string `v0.13.1-g<hash>` is sufficient without the count.

If `.git` doesn't exist (tarball build), fall back to reading `src/version` which already contains the release version.

**Replace in build_compiler.w:260-274.**

**Verification:** Compare output against `git rev-parse --short=9 HEAD` on a dev machine.

---

### Phase 4: Git-free committed-state check

**What it replaces:** `git status --porcelain` (build_compiler.w:479-483)

**Priority:** Fourth because it needs design work but has no external dependencies.

**Approach: Hash-based manifest (Option B)**

This is the most robust option and has no git dependency at all. It answers "is this the code I intended to ship?" rather than "is git clean?" — arguably better semantics.

**Mechanics:**

At `with build :fixpoint` success (or a new `with build :bless` command), record content hashes of all source files into a manifest:

```
out/.build-state/blessed-manifest
```

Contents: sorted lines of `<path>:<content-hash>`, covering `src/*.w` (recursively), `rt/*.w`, `lib/std/*.w`, `build.w`, `build_compiler.w`.

At `install-user` / `update-seed` time, recompute hashes of the same files and compare against the manifest. If any file differs or the manifest doesn't exist, fail with a diagnostic listing the changed files. `--force` bypasses as before.

**Why not Option A (mtime-based):** mtime comparison is inherently racy and filesystem-dependent. Content hashing through the runtime is deterministic and portable.

**Why not Option C (skip when no git):** The check should work everywhere, not just in git repos.

**Replace in build_compiler.w:479-483.**

---

### Phase 5: LLVM path discovery

**What it replaces:** `llvm-config --libfiles --link-static ...` (build_compiler.w:354)

**Priority:** Fifth because it requires care around LLVM version portability.

**Current behavior:** Runs `llvm-config --libfiles --link-static engine ...` with 58 hardcoded component names to get a list of LLVM library paths for linking.

**Replacement:**

1. Read `LLVM_PREFIX` environment variable (already used elsewhere), or probe known paths (`/usr/local/llvm`, `/opt/homebrew/opt/llvm`, `/usr`).
2. List `$LLVM_PREFIX/lib/` using `with_fs_list_files`.
3. Include ALL `libLLVM*.a` and `libclang*.a` files found. Do NOT hardcode component names — they change between LLVM versions. Over-linking is free; the linker discards unused objects.
4. Check for unified `libLLVM.a` first — if it exists, use just that instead of component libraries.
5. Write the result to `out/lib/llvm_link.rsp` as before.

**Replace in build_compiler.w:354.**

**Verification:** Diff the generated `llvm_link.rsp` against what `llvm-config` would produce — it should be a superset (same libraries plus possibly unused ones). The compiler must link and fixpoint.

---

### Phase 6: LLVM-based C compilation, assembly, and IR-to-object

**What it replaces:** `cc -c` for C objects, `cc -c` for assembly, `clang -c` for LLVM IR (BuildGraphDispatch.w:116-120)

**Priority:** Last because it requires the most investigation and has the highest risk.

**Critical investigation needed before implementation:**

The compiler dynamically links `libclang` (for `c_import` header parsing) but the full clang compilation pipeline (C source → object file) requires the static clang libraries (`libclangCodeGen.a`, `libclangFrontend.a`, etc.). These are different link dependencies. Before committing to an approach, determine:

1. What clang APIs are available through the current `libclang` dynamic link? Check `rt/clang_bridge.w` for the current API surface.
2. Does `libclang` expose any code emission / compilation function, or only parsing/indexing?
3. Would switching from dynamic `libclang` to static clang libraries be feasible? What's the binary size impact?
4. Can the clang frontend be driven through the LLVM C API that's already statically linked?

**Scope reduction — check how many C files actually need compiling:**

The build timeline says "Apr 5 — Zero C source files." If no `.c` files remain in the build graph, C compilation may not be needed at all. Check `with build --dry-run` for kind-12 (CompileCObject) targets. If there are none, this phase reduces to two problems:

- **Assembly (kind 13):** Can LLVM's MC layer be driven through the existing LLVM C API? The compiler already initializes LLVM targets for codegen — the same target initialization serves assembly. Use `createMCAsmParser` → `MCStreamer` or `LLVMTargetMachineEmitToFile`.
- **LLVM IR to object (kind 14):** The compiler already does this for With source (emit IR → compile to object via LLVM backend). Factor out the "IR text → object file" step into a standalone runtime function. This is likely the easiest of the three.

**Add to the LLVM bridge (`rt/llvm_bridge.w`):**

```with
/// Assemble a .s file to an object file using LLVM's MC layer.
fn wl_assemble_to_object(source: str, output: str, target_triple: str) -> i32

/// Compile an LLVM IR .ll file to an object file.
fn wl_compile_ir_to_object(source: str, output: str) -> i32

/// (Only if C files exist) Compile C source to object.
fn wl_compile_c_to_object(source: str, output: str, include_paths: str, flags: str) -> i32
```

**Replace in BuildGraphDispatch.w:116-120.** Route each target kind to the appropriate LLVM function instead of subprocess.

**Verification:** Rebuild the compiler. Every runtime object (rt_core.o, llvm_bridge.o, clang_bridge.o, fiber_asm.o, etc.) must be produced by the LLVM bridge functions, not by subprocess. `nm` on the output objects should produce identical symbols. Fixpoint must pass.

---

### Ordering

```
Phase 1: Archive creation              (pure With, ~100 lines, zero risk)
Phase 2: SDK probe + seed probe        (filesystem checks, trivial)
Phase 3: Git version detection         (file reads, straightforward)
Phase 4: Committed-state check         (hash manifest, needs design)
Phase 5: LLVM path discovery           (directory listing, version-portability care)
Phase 6: C/asm/IR compilation          (hardest — needs clang API investigation)
```

After each phase: `with build`, fixpoint, test. Commit after each phase.

---

### Verification

After all phases:

```bash
# Confirm no external tool subprocesses remain
rg 'exec_argv_capture|exec_binary' src/ --include '*.w' -l
# Should show only: BuildGraphOps.w (user Command targets),
#                   BuildGraphTests.w (test runner),
#                   build_compiler.w (stage chain — runs With itself)
```

Every remaining subprocess call must be either running the With compiler itself or running a user-specified executable. Zero platform tool invocations.
