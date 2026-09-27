# D46 — `with get` builds a C package from source from the recipe read as data; no per-package files; `with cc` is clang inside the binary

**Date:** 2026-09-19. **Status:** ruled (Eric: "with get must build c when
there's no binary for the package"; "we cant be writing special case code
for every conan package"; prerequisites "we need to expose them to the
user … user will need to take care of it"; "OpenSSL can't be a UAT").
Specification §18.5 and §18.8 blessed 2026-09-19. Implemented in #1208.

**Context.** Conan Center publishes no Linux armv8 binaries at all (zlib,
bzip2, sqlite3, openssl, libcurl, raylib checked 2026-09-18), so every
`with get c.X` on linux-aarch64 failed. The old fallback compiled every `.c`
in the tarball with the system `cc` and gave up on any recipe with patches or
a configure step — zlib already — and could not be locked.

**Decision.**
- *Compiler:* clang's driver is linked into `with` (`with cc`), as Zig does;
  the toolchain never trusts a system compiler. `clang_main` lives in the
  clang tool's own objects, archived into the SDK as `libclangMain`; one plain
  extern is aliased to the mangled name per linker. An SDK published before
  this links a stand-in and the compiler says it has no C compiler; a platform
  gains `with cc` when its SDK is republished.
- *Build knowledge:* the package's own CMake build, driven by `cmake` and
  `ninja` with `with cc`. What is package-specific comes from the recipe Conan
  Center already publishes, **read as data and never executed**: archive,
  digest, patches, requirements, and `tc.variables`, evaluated against the
  option defaults and the host under the `if`s that hold.
- *Prerequisites* (`cmake`, `ninja`, Perl for OpenSSL, …) are named and the
  build stops; installing them is the programmer's step. A release UAT may not
  require one, so OpenSSL is not a UAT.

**Rejected.** Per-package port files (written, then deleted the same night:
"special case code for every conan package"). Executing `conanfile.py`
(needs Python and Conan). pkg-config / system packages (apt ceremony, no
Windows story). Hosting our own binaries as the primary answer (moves the
gap). Detecting the stand-in by comparing function addresses (LLVM folds two
distinct function symbols to "not equal"; the stand-in was called).

**What would reopen it.** A class of popular packages whose recipes cannot
be read as data (logic the evaluator cannot follow), or Conan Center
publishing binaries for every platform With targets.

---
