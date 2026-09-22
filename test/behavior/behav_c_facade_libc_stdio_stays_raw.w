//! only-on: darwin
//! expect-stdout: ok

// Darwin's <stdio.h> translation hands `FILE *` through as `*mut c_void`
// (the bridge types a pointer to a reserved system record, `struct __sFILE`,
// as `void *` — CImport.w type_from_libclang), which is not libc's shape
// for the toolchain libc facade's `CFile` (compiler/LibcFacade.w). The facade
// does not describe it: importing <stdio.h> compiles, and fopen/fclose stay
// the raw surface — never a resource asserted over a `void *`.

use c_import("stdio.h")

fn main:
    let f = unsafe { fopen("/dev/null", "r") }
    if f != null:
        unsafe { fclose(f) }
    print("ok")
