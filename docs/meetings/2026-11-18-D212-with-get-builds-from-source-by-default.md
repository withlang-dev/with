# D212 — `with get` builds a C package from source by default

**Laws:** 1 (a user should not need a flag to get what the compiler can
give), the mission's "the programmer never has to become the build system".

**Date:** 2026-11-18. **Status:** ruled by Eric. Implemented 2026-11-23,
with the package-management text and §31.8.5's table.

**Context.** A proof holds only where the source analyzed and the artifact
linked are the same build (§31.8.5), and every library fetched on
darwin-aarch64 arrived as a Conan Center binary. Measured: 13 functions
presented across 22 libraries by default (zlib 3, libxml2 10, every other
library 0), against 1,239 across the 16 that build with `--from-source`.
Cargo and Zig build C dependencies from source; Windows already did.

**Ruling.** Source by default, on four conditions:

- **Cache the builds.** A user-level cache keyed on package version,
  options, target and toolchain: SDL costs minutes once per machine, not
  once per project. CI needs the same cache.
- **Analyze exactly what gets built.** Conan Center recipes patch the
  upstream source; the proofs are drawn from the patched tree that is
  compiled.
- **Not all-or-nothing per chain.** The package itself is built from source
  and only a requirement that is not a CMake project is taken as a binary.
  Calls into that requirement are outside functions, which the proofs
  already handle. Otherwise libcurl loses everything to OpenSSL and libxml2
  to libiconv.
- **Say what happened, every time.** One line per package: built from
  source with proofs, or a prebuilt binary with none, with the pointer to
  `with contract report`. `--binary` is the opt-out.

**Alternatives.** Registry contracts per library as the only route to
coverage: every proof improvement would then reach no program. Source only
when the whole requirement chain is CMake (the first proposal): six of 25
libraries would still fall back.

**Reopen if** source builds make a first `with get` too slow to be the
default even with the cache.

**Found in implementation (2026-11-23).** The seven `with get` scenarios
ran under the new default: zlib, bzip2, sqlite3, libxml2, SDL and raylib
passed at once (5 to 81 seconds on a first build; a second project takes
the cached build in about a second). libcurl built and then did not link.
Its recipe builds with autotools everywhere but Windows, so its option
settings never reached the CMake build `with get` runs, and curl's CMake
found a host package manager's brotli, zstd, libssh2, libidn2, nghttp2 and
libpsl through pkg-config. Two rules came of it, for every package:

- The recipe's CMake settings are those of the method that constructs its
  CMake toolchain, whether or not `generate` reaches it on this platform.
- A source build finds its requirements and nothing else the host has
  installed: host package-manager prefixes are ignored, and pkg-config
  answers only from the requirements' own directories.

OpenSSL is taken as a prebuilt binary (its build needs Perl), and its line
says so.
