# D81 — Zero dependencies: the compiler carries its SDK per platform; applications bring their own dependencies

**Date:** 2026-09-29. **Status:** BDFL ruling (Eric, in conversation;
"blessed" on the §16.1 words). Spec v7.15: §16.1. Issues #1915, #1826,
#1914.

**Decision.** Building the compiler and building a With program read
nothing but our own SDK; a built program depends at run time only on what
the operating system ships at the system-call boundary (macOS
`libSystem`, the Linux kernel, the DLLs Windows 10+ carries in-box —
`kernel32`, `ntdll`, `ucrtbase` — and not `vcruntime140`, a
redistributable). In Eric's words: "I want *zero* dependencies in *all*
platforms … except our own SDK and system calls"; "I do NOT want with to
require msbuild. I want it to build with its OWN SDK"; "ABSOLUTELY NOT we
do NOT require Visual Studio nor Windows SDK."

- **Our SDK is per platform and exact:** "our SDK is built per-platform to
  provide exactly what's needed to compile With on that platform" — link
  stubs for the system libraries, C runtime startup, compiler-rt
  builtins, libc++ for the compiler's own link, lld, and the C standard
  library headers `c_import` reads. No Xcode or Command Line Tools, no
  Visual Studio or Windows Kits, no system glibc/gcc objects.
- **Applications bring their own dependencies:** "the compiler itself
  shouldn't have dependencies on cocoa, iokit, opengl, or metal … user
  applications are responsible to link their dependencies using
  `with get` or manually." Framework and library headers that cannot be
  redistributed are the package's job ("`with get c.raylib` should
  handle that").
- **§16.1** now says the C standard library headers come from the
  target's sysroot, which the compiler carries; no host SDK is consulted
  unless the program names one.

**Why.** Every borrowed toolchain broke us the same way: Xcode 27's SDK
changed its `.tbd` format and the stage link failed (#1826); Windows linked
through hard-coded Visual Studio 2019 and Windows Kits paths from its
first bootstrap (30e10475, b13b9b04, June 2026), with a `winenv.sh` to
paper over it (#1914); macOS user programs linked through the host `cc`
and `nm`, and failed with a bare "build failed" when they were absent.
None of these dependencies was ever ruled on; each arrived as a
hard-coded path. The mission says the programmer never becomes the build
system — installing and pointing at a vendor toolchain is exactly that.

**How it stays true.** `with build :no-host-toolchain` (in `:gate` and
the battery) fails when any link or compile the build runs names a path
outside the repository, `out/` and our SDK, and runs a program build in
a sandbox that denies the host toolchain.

**References (checked in their trees).** Zig ships per-target libc link
stubs and headers (`lib/libc/darwin/libSystem.tbd`,
`lib/libc/include/any-darwin-any`, glibc abilists, mingw-w64 `.def`
files) and links with its own lld, so `zig build` needs no host SDK.

**Reopen if** a platform's system libraries cannot be stubbed without a
vendor SDK (then the SDK must still carry what we generate from the
running OS, never require the vendor's install), or a redistribution
license forbids shipping a header the C standard library needs.

**Linux rulings (Eric, 2026-09-30).**
- glibc 2.28 is the floor: the linux-x86_64 sysroot's stubs and headers target it, so a With program runs on 2.28 or later.
- A library a user program names that the sysroot does not carry (zlib, curl) may be found on the host, searched after the sysroot: an application brings its own dependencies "via `with get` or manually".
