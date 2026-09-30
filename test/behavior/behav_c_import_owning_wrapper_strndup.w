//! skip-on: windows strndup is POSIX: neither Windows' UCRT nor mingw-w64's runtime (the SDK's C runtime, #1915) defines it; the libc facade's rendering is covered on Windows by behav_c_import_owning_wrapper_strdup
//! expect-stdout: strndup 3
//! expect-stdout: ok

// D51 §16.2b / ruling §5: libc's owned strings are modeled by the toolchain
// libc facade (compiler/LibcFacade.w). strndup produces a `CHeapStr` whose
// Drop calls free exactly once; the constructor yields `Option[CHeapStr]`
// (NULL produced nothing, §16.2b.8) and needs no `unsafe`. Split from
// behav_c_import_owning_wrapper_strdup, which runs on Windows too.

use c_import("char *strndup(const char *s, unsigned long n);
unsigned long strlen(const char *s);
void free(void *p);
")

fn main:
    let short = CHeapStr.strndup("hello", 3).unwrap()
    print(f"strndup {strlen(short.repr as *const i8)}")
    print("ok")
