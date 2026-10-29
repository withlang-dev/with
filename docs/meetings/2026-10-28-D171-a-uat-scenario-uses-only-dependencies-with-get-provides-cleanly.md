# D171 — User actions may use system tools; the compiler and its build are bootstrapped; a UAT scenario uses only dependencies `with get` provides cleanly on its platform (ruled)

**Laws:** zero dependencies for the toolchain (D81); the UAT is the user's
real experience.

**Date:** 2026-10-28. **Status:** ruled (Eric). **Issue:** #2788.

**Decision.**

1. Anything done by the *user* may use the host's system tools: `with get`
   building a user's C package, a user's own build. A missing tool is
   named, and installing it is the user's step (package-management.md).
2. Anything done by the *compiler itself* and its *build system* may not:
   it is bootstrapped from our own sources and SDK (D81).
3. The release UAT selects scenarios the toolchain can do: a scenario uses
   only dependencies `with get` provides cleanly on that platform — a Conan
   Center binary, or a CMake source build through the compiler's own
   `cmake`, `ninja` and `with cc`. A dependency chain that needs a host
   tool (Perl, autotools) on a platform is not a scenario for it.

Applied: `libcurl.uat` runs on darwin and linux-x86_64 (Windows builds
every package from source, and openssl's build needs Perl; linux-aarch64
was already out, #2757); `libxml2.uat` runs on darwin and linux-x86_64
(libiconv's build is autotools, on Windows and on linux-aarch64, where
Conan Center publishes no binaries). bzip2, zlib, sqlite3 and sdl keep
`with get` with dependencies covered on every platform.

**Context.** The first end-to-end Windows battery (#2788) failed both
scenarios: `with get` refused openssl ("its own Configure script, which
needs Perl") and libiconv ("autotools (sh and make)"). I first applied the
toolchain's rule to `with get` and proposed migrating or porting the
user's C dependencies; our compiler and build never call `with get`, and
the migrated corpora (pcre2, zlib, OpenSSL under D170) serve the standard
library and the compiler, not `with get`.

**Reopens if** `with get` gains a clean, tool-free way to provide such a
chain on a platform, which would put the scenario back on it.
