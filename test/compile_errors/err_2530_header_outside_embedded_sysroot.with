//! only-on: darwin
//! env: SDKROOT=
//! env: WITH_SDKROOT=
//! expect-error: 'with_absent_header_2530.h' file not found
//! expect-error: the embedded macOS sysroot this compiler carries (#1915) holds libc only
//! expect-error: WITH_SDKROOT
// #2530: a header outside the embedded (libc-only) macOS sysroot was a
// bare clang "file not found" — no word that the embedded sysroot is what
// was searched, or how to name another. The SDK env names are blanked so
// the embedded sysroot is the one in use on any shell.
use c_import("with_absent_header_2530.h")

fn main:
    print(1)
