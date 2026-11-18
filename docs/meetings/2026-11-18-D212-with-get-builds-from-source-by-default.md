# D212 — `with get` builds a C package from source by default

**Laws:** 1 (a user should not need a flag to get what the compiler can
give), the mission's "the programmer never has to become the build system".

**Date:** 2026-11-18. **Status:** ruled by Eric. The package-management text
and §31.8.5's table change with the implementation.

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
