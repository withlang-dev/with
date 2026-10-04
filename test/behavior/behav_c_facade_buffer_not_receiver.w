//! expect-stdout: filled: 4
//! expect-stdout: ok: 3
//! expect-stdout: copy: hi

// A parameter a `buffer` clause pairs is a buffer, not a resource's
// receiver: `char *dst` has the representation the toolchain libc facade's
// `CHeapStr` wraps (`strdup` is declared here, as <string.h> declares it on
// Windows beside every header that includes it), and the operation is still
// the free function its facade states, never a method of `CHeapStr` (the
// bzip2 release UAT failed on Windows with its `<Fn>Error` rendered twice).

use c_import("#define FILL_OK 0\nchar *strdup(const char *s);\nvoid free(void *p);\nstatic inline void fill_void(char *dst, unsigned int *dstLen) { unsigned int n = 4; if (*dstLen < 4) n = *dstLen; unsigned int i = 0; while (i < n) { dst[i] = 'x'; i++; } *dstLen = n; }\nstatic inline int fill3(char *dst, unsigned int *dstLen) { if (*dstLen < 3) return 1; dst[0] = 1; dst[1] = 2; dst[2] = 3; *dstLen = 3; return FILL_OK; }\n")

c facade fills:
    fn fill_void
        buffer param dst capacity param dstLen inout
    fn fill3
        buffer param dst capacity param dstLen inout
        ok FILL_OK

fn main:
    var xs: [u8; 9] = [0 as u8; 9]
    print(f"filled: {fill_void(xs)}")
    print(f"ok: {fill3(xs).unwrap()}")
    let Some(dup) = CHeapStr.strdup("hi") else:
        print("strdup failed")
        return 1
    print(f"copy: {dup.as_cstr().to_str_lossy()}")
