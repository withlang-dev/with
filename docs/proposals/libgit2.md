# libgit2 Migration Proposal

Migrate libgit2 to With using `with migrate`, making git a native capability of the compiler, build system, and standard library.

**Status: BLOCKED on zlib migration.** Git objects are zlib-compressed. Every read operation -- opening a commit, reading a blob, listing a tree -- requires zlib decompression. libgit2 cannot function without zlib. The zlib migration (~15K lines of clean C, public domain) must land first as `std.compress.zlib` before this proposal can begin.

---

## 1. What libgit2 Is

libgit2 is a portable, pure C implementation of git core methods. It is a library, not a CLI wrapper around git. It provides programmatic access to git repositories without requiring git to be installed.

- ~200K lines of C
- MIT licensed
- No external dependencies beyond system libraries
- Used in production by GitHub Desktop, Visual Studio, GitKraken, Sublime Merge, and others
- Clean, well-documented API
- Cross-platform: Linux, macOS, Windows, BSD

---

## 2. Why

The compiler and build system currently shell out to git for version detection and committed-state checks. The package manager will need git for fetching dependencies. The migration tool could fetch source directly from repositories. Today these are external tool dependencies. After this migration, they are native With code.

The broader principle: the With compiler stands on system calls alone. Every capability it needs, it owns. libgit2 migrated to With means git operations are as native as regex (PCRE2) or JSON (std.json).

This is also a proof point. PCRE2 (73K lines of C) demonstrated the migration tool on complex, macro-heavy systems code. libgit2 (200K lines) demonstrates it at a larger scale on clean, well-structured library code. Two major C libraries running as native With, both migrated mechanically.

---

## 3. What It Enables

### 3.1 Package management (`with get`)

Native git clone, fetch, and checkout. The package manager fetches With packages directly from git repositories without requiring git, curl, or tar on the system.

```bash
# Fetch a With package from a git repository
with get github.com/user/package@v1.2.0

# Fetch a specific commit
with get github.com/user/package@abc1234

# Fetch a C package and migrate it
with get c.github.com/user/clib
```

The package manager resolves the version tag or commit, clones the minimum necessary objects (shallow clone or single-commit fetch), and places the source in the project's dependency directory. Lock files reference exact commit hashes, verifiable by the compiler without external tools.

### 3.2 Build system

Version detection reads `.git/HEAD` and refs natively. Committed-state enforcement compares the index against the working tree natively. No subprocess calls to git.

```with
use std.git

let repo = git.open(".")
let head = repo.head_commit()
let version = f"v0.13.1-g{head.short_id()}"

if repo.is_dirty():
    print("error: working tree has uncommitted changes")
```

### 3.3 Migration tool

`with migrate` can fetch C source directly from a git URL:

```bash
# Migrate a C library directly from its repository
with migrate git://github.com/edubart/minicoro -o rt/minicoro.w

# Migrate a specific tag
with migrate git://github.com/PCRE2Project/pcre2@pcre2-10.44 -o lib/std/re/
```

No manual download step. The migration tool resolves the ref, fetches the source tree, and migrates it in one command.

### 3.4 Standard library (`std.git`)

A public API for With programs that work with git repositories:

```with
use std.git

let repo = git.open("/path/to/repo")

// Read refs
let head = repo.head()
let branches = repo.branches()
let tags = repo.tags()

// Read objects
let commit = repo.lookup_commit(head.target())
let tree = commit.tree()
let blob = tree.entry_by_path("src/main.w").to_blob()
let content = blob.content()

// Status
let status = repo.status()
for entry in status:
    print(f"{entry.path}: {entry.status}")

// Clone
git.clone("https://github.com/user/repo", "/local/path")

// Diff
let diff = repo.diff_index_to_workdir()
for delta in diff.deltas():
    print(f"{delta.old_file.path} -> {delta.new_file.path}")
```

### 3.5 Developer tooling

The LSP server and future IDE integrations can read git state natively:

- Show current branch in diagnostics
- Annotate symbols with "last modified in commit X"
- Provide git-aware file watching (ignore untracked files)
- Integrate blame information into hover tooltips

### 3.6 CI and deployment

Programs built with With can inspect their own build provenance:

```with
use std.git

fn build_info() -> str:
    let repo = git.open(".")
    let commit = repo.head_commit()
    f"built from {commit.short_id()} on {commit.time()} by {commit.author().name}"
```

---

## 4. Migration Plan

### 4.1 Obtain and prepare

```bash
git clone https://github.com/libgit2/libgit2 .reference/libgit2
cd .reference/libgit2
git checkout v1.8.4  # pin to a specific release
```

### 4.2 Scope the migration

libgit2's source is organized into:

```
src/libgit2/       -- core library (~150K lines)
src/util/          -- platform utilities (~30K lines)
deps/              -- bundled dependencies (http-parser, zlib, etc.)
```

The core library includes subsystems we don't need immediately (merge, rebase, blame, cherry-pick, stash). The migration can be incremental:

**Phase A -- Read-only operations (immediate need):**
- Repository opening and discovery
- Reference reading (HEAD, branches, tags)
- Object database reading (commits, trees, blobs)
- Index reading and status computation
- Config file parsing

**Phase B -- Network operations (for package management):**
- HTTP/HTTPS transport (the compiler already has a TLS stack from BearSSL)
- Git protocol support
- Clone and fetch
- Shallow clone support

**Phase C -- Write operations (future):**
- Index modification
- Commit creation
- Reference updates
- Push

### 4.3 Handle bundled dependencies

libgit2 bundles several small C libraries:

- **zlib** -- Compression. Git objects are zlib-compressed. Every read operation requires decompression. This is a hard prerequisite, not an optional dependency. **zlib must be migrated to With as `std.compress.zlib` before libgit2 migration can begin.** zlib is ~15K lines of clean C under a permissive license (zlib license). It is also independently useful for the compiler and standard library (compressed assets, package archives, HTTP content-encoding).
- **http-parser** -- HTTP/1.1 parser. The compiler may already have HTTP parsing from the package manager. Deduplicate or migrate separately.
- **pcre/pcre2** -- Optional, for gitignore pattern matching. With already has PCRE2 migrated. No work needed.
- **sha1/sha256** -- Hashing. The BearSSL port already provides SHA-256. SHA-1 is needed for git object IDs. BearSSL includes SHA-1 as well. No work needed.

Dependency status:

| Dependency | Status | Blocking? |
|---|---|---|
| zlib | **Not migrated -- BLOCKER** | Yes. Must land before libgit2. |
| SHA-1 / SHA-256 | Available via BearSSL port | No |
| PCRE2 | Already migrated | No |
| http-parser | Needed for Phase B (network) only | No, Phase A proceeds without it |

### 4.4 Migrate

```bash
with migrate .reference/libgit2/src/libgit2/ \
    -o lib/std/git/ \
    -I .reference/libgit2/include \
    -I .reference/libgit2/src/libgit2 \
    -I .reference/libgit2/src/util \
    --no-c-export
```

This will produce a set of With modules under `lib/std/git/`. The migration tool handles struct translation, typedef resolution, function signature conversion, and goto elimination.

Platform-specific code (Windows vs Unix filesystem operations, threading, etc.) will need conditional compilation or platform-abstraction rewrites after migration, following the same pattern as the runtime's platform layer.

### 4.5 Build a With-native API layer

The migrated code preserves libgit2's C API shape. Layer a With-idiomatic API on top:

```
lib/std/git/          -- migrated libgit2 internals (private)
lib/std/git.w         -- public With API (Repository, Commit, Tree, etc.)
```

The public API uses With types (str, Vec, Option, Result), handles, and the ownership model. The internals remain close to libgit2's original structure for maintainability and future upstream sync.

---

## 5. Integration Points

### 5.1 Wire into the build system

After Phase A, replace the git subprocess calls in `build_compiler.w`:

| Current | Replacement |
|---|---|
| `git rev-parse --short HEAD` | `repo.head_commit().short_id()` |
| `git rev-list --count HEAD` | Omit, or `repo.head_commit().ancestor_count()` |
| `git status --porcelain` | `repo.is_dirty()` |

### 5.2 Wire into the package manager

After Phase B, `with get` uses native git transport:

```with
use std.git

fn fetch_package(url: str, version: str, dest: str) -> Result[str, Error]:
    let opts = git.CloneOptions.new()
        .depth(1)
        .branch(version)
    git.clone(url, dest, opts)
```

### 5.3 Wire into the migration tool

After Phase B, `with migrate` accepts git URLs:

```with
use std.git

fn fetch_source(url: str, ref: str, dest: str) -> Result[str, Error]:
    let opts = git.CloneOptions.new().depth(1)
    if ref.len() > 0:
        opts = opts.branch(ref)
    git.clone(url, dest, opts)
```

---

## 6. Risks

| Risk | Mitigation |
|---|---|
| zlib migration must land first | zlib is ~15K lines of clean C, public domain, well-understood. It is a smaller and simpler migration than PCRE2. Independently useful for std.compress. |
| 200K lines is a large migration | Phase A alone is ~50-80K lines (read-only core). Start there. |
| Platform-specific code (Windows, Unix) | libgit2 already abstracts this. The migration preserves the abstraction layer; rewire it to With's runtime platform APIs. |
| Upstream updates | Pin to a release tag. Re-migrate when needed. The migrated code is a snapshot, same as PCRE2. |
| Network stack integration | The BearSSL TLS port already provides HTTPS. Wire libgit2's HTTP transport to use it instead of system OpenSSL/SecureTransport. |
| Migration tool bugs | libgit2 is cleaner C than PCRE2 (no computed gotos, no macro codegen). Expect fewer migrator issues. |

---

## 7. Size Estimate

| Component | Estimated LOC | Notes |
|---|---|---|
| **zlib migration (prerequisite)** | **~25-35K** | **Must land first as std.compress.zlib** |
| Phase A migration output | ~100-150K | Read-only core + utilities |
| Phase B migration output | ~30-50K | Network transport |
| std.git public API | ~500-1000 | With-idiomatic wrapper |
| Build system integration | ~100 | Replace git subprocess calls |
| Package manager integration | ~200-400 | Clone/fetch for `with get` |
| **Total** | **~160-240K migrated** | Plus ~1-2K hand-written |

---

## 8. Timeline

This is not blocking current work. The immediate git needs (HEAD hash, committed-state check) are solved with ~70 lines of file reads and a hash manifest. libgit2 migration is a strategic investment that pays off when package management comes online.

Prerequisite chain:

```
zlib migration (~15K lines C)
  --> std.compress.zlib
    --> libgit2 Phase A (read-only, ~50-80K lines)
      --> build system integration (replace git subprocess calls)
      --> libgit2 Phase B (network, ~30-50K lines)
        --> with get git-based packages
        --> with migrate from git URLs
```

Suggested sequencing:

1. Ship the manual git file reads and hash manifest now (Phase 5-6 of no-deps plan).
2. Migrate zlib to `std.compress.zlib`. This is independently useful (compressed assets, package archives, HTTP content-encoding) and unblocks libgit2.
3. Migrate libgit2 Phase A (read-only) after zlib lands.
4. Replace the manual file reads with std.git calls.
5. Migrate Phase B (network) when `with get` is ready for git-based packages. Wire HTTP transport to the BearSSL TLS stack.
6. Phase C (write operations) as needed.

---

## 9. Success Criteria

The zlib prerequisite is met when:

1. `std.compress.zlib` provides inflate/deflate operations.
2. zlib is migrated With code, not a system library link.
3. Compression/decompression round-trips match the reference zlib output.

The libgit2 migration is complete when:

1. `std.git` can open a repository, read HEAD, list refs, read commits/trees/blobs, and report status.
2. The build system uses `std.git` instead of subprocess calls to git.
3. `with get` can clone and fetch from git repositories without git installed.
4. All git operations work on Darwin, Linux, and Windows.
5. `make build && make fixpoint && make test` pass.
6. git is not required on the system for any compiler or build system operation.