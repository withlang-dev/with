# The Windows SDK's own C runtime and C++ runtime (#1915, D81)

Status: implemented on branch `win-own-sdk`; the SDK that carries it is not
yet published or pinned in `sdk.lock`. Non-normative: D81 and spec §16.1
are the ruling; this note records what the Windows SDK carries, where it
comes from, and under which licenses.

## What the Windows SDK carries

Under `<sdk>/libc/windows` (the sysroot clang's MinGW driver takes with
`--sysroot`, and the one c_import and every Windows link read):

| path | contents | built by |
|---|---|---|
| `include/` | mingw-w64's headers, installed as its configure would with `--with-default-msvcrt=ucrt --with-default-win32-winnt=0xa00` | `:sdk-windows-libc` |
| `<arch>-w64-mingw32/lib/crt2.o crtbegin.o crtend.o` | UCRT startup (`crt/crtexe.c`, `crt/crtbegin.c`, `crt/crtend.c`) | `:sdk-windows-libc` |
| `<arch>-w64-mingw32/lib/mingw32.lib mingwex.lib uuid.lib` | the support libraries, from `mingw-w64-crt/Makefile.am`'s own source lists and flags | `:sdk-windows-libc` |
| `<arch>-w64-mingw32/lib/ucrt.lib` (= `msvcrt.lib`) | the `api-ms-win-crt-*` import libraries and `libucrt_extra` wrappers, per `lib-common/ucrt.mri` | `:sdk-windows-libc` |
| `<arch>-w64-mingw32/lib/<dll>.lib` | import libraries of the in-box DLLs the runtime and compiler use: kernel32 ntdll advapi32 bcrypt dbghelp ws2_32 shell32 user32 ole32 oleaut32 version psapi, and for the SDK's own cmake crypt32 secur32 iphlpapi powrprof userenv rpcrt4 wldap32 normaliz | `:sdk-windows-libc` (llvm-dlltool over mingw-w64's `.def` files) |
| `<arch>-w64-mingw32/lib/libc++.a libunwind.a`, `include/c++/v1` | the C++ runtime of the SDK's LLVM | `:sdk-libcxx` |
| `COPYING* DISCLAIMER* PROVENANCE` | mingw-w64's licenses and this build's provenance | `:sdk-windows-libc` |

and `<sdk>/lib/clang/<major>/lib/windows/libclang_rt.builtins-<arch>.a`
(`:sdk-compiler-rt-builtins`). A library an application uses beyond these
(opengl32, gdi32, winmm, ...) is the application's dependency (`with get`
or its own link settings), per D81. `with get` writes the import libraries a
package names for in-box DLLs the SDK does not carry (Eric, 2026-09-30,
ruling A), as it writes Apple framework stubs on macOS: from the `.def` files
of the mingw-w64 release this C runtime was built from (its `PROVENANCE`
names the archive and its sha256; the definitions are fetched once into the
user's cache), preprocessed by the SDK's clang and written by its
llvm-dlltool into the package's `windows-libs/` (compiler.WindowsImportLibs;
`with __windows-import-libs <dir> <dll>...` runs the step alone).

## What the Windows compiler carries (D81)

A Windows compiler built against this SDK carries what a build needs beyond
itself, as the macOS one carries its sysroot: lld's drivers and LLVM's dlltool
are linked into it (`with __ld`, `with __dlltool`), and `libc/windows`,
`lib/clang/<major>` (clang's headers and compiler-rt's builtins),
`bin/cmake.exe`, `bin/ninja.exe` and `share/cmake-<v>` are embedded
(gzip-compressed, `:windows-sysroot`, build/sdk.w run_windows_sysroot_action)
and unpacked to the user's cache on first use. With no SDK named (no link
record, no WITH_LLVM_LD / LLVM_LD / LLVM_PREFIX), a native Windows link, a
c_import, `with cc` (handed the compiler itself as `ld.lld.exe`) and
`with get` read only that: `with build hi.w` works on a machine that has
only `with.exe`, and a fresh checkout runs `:deps` with no SDK present.

## Provenance

- mingw-w64 v14.0.0, `https://github.com/mingw-w64/mingw-w64/archive/refs/tags/v14.0.0.tar.gz`,
  sha256 `d71cc644cd5a37c337f2719f3e0c79d89e8d8d5fb9e2952a62d3fa23623dc137`
  (pinned in `build/sdk.w`), fetched at SDK build time like LLVM's source;
  nothing of it is checked into this repository.
- compiler-rt, libunwind, libc++abi and libc++ from the LLVM source the SDK
  is built from (`llvm-project` at the pinned release tag).
- Every object is compiled by the SDK's own clang; import libraries are
  made by the SDK's own `llvm-dlltool`. The build is `build/sdk.w`.

## Licenses

- mingw-w64: Zope Public License 2.1, with public-domain parts
  (`DISCLAIMER.PD`) and BSD-style notices listed in
  `COPYING.MinGW-w64-runtime.txt`. Every Windows program With links contains
  mingw-w64 startup code (`crt2.o`, parts of `mingw32`/`mingwex`), so the
  runtime notice file is the one a binary distribution carries — the same
  obligation every mingw-w64 and Zig Windows program has.
- compiler-rt, libunwind, libc++abi, libc++: Apache 2.0 with LLVM
  exceptions (the runtime exception means linked binaries need no notice).

## Rebuilding the Windows SDK

On a Windows host with only the previous SDK (no Visual Studio):

```
with build :sdk-windows-libc :sdk-compiler-rt-builtins :sdk-libcxx :sdk-ninja :sdk-llvm :sdk-cmake
with build :package-llvm-sdk
```

`SDK_BOOTSTRAP_PREFIX` names the previous SDK (default `.deps/...`), and
`SDK_OUTPUT_PREFIX` the new one. The libc steps also run on any host (the
SDK's clang cross-compiles them), and with `SDK_OUTPUT_PREFIX` equal to an
installed SDK they add the libc to it without rebuilding LLVM.
