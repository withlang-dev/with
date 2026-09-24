//! expect-check-fail: renders 'FillError', the error type of its 'ok' projection, and

// D64 §16.2b.8, §16.2b.4: the generated `<Fn>Error` never silently
// shadows or is shadowed by a type of the same name.
use c_import("#define FILL_OK 0\nstatic inline int fill(unsigned char *dst, unsigned long *dstLen) { dst[0] = 1; *dstLen = 1; return FILL_OK; }\n")

type FillError { code: i32 }

c facade fills:
    fn fill
        buffer param dst capacity param dstLen inout
        ok FILL_OK

fn main:
    print("unreachable")
