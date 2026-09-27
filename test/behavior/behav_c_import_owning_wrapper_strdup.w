//! expect-stdout: strdup h
//! expect-stdout: ok

// D51 §16.2b / ruling §5: libc's owned strings are modeled by the toolchain
// libc facade (compiler/LibcFacade.w), rendered like any facade — no
// generated owning wrapper. strdup produces a `CHeapStr`
// whose Drop calls free exactly once; the constructor yields
// `Option[CHeapStr]` (NULL produced nothing, §16.2b.8) and needs no `unsafe`.
// The raw C names stay raw. free's exactly-once is witnessed by the macOS/
// glibc allocator (a second free aborts) and by `leaks --atExit` (none left).

use c_import("char *strdup(const char *s);
unsigned long strlen(const char *s);
void free(void *p);
")

fn main:
    let owned = CHeapStr.strdup("hello").unwrap()
    let first = unsafe { *(owned.repr as *const u8) }
    print(f"strdup {if first == 104u8: \"h\" else: \"bad\"}")
    print("ok")
