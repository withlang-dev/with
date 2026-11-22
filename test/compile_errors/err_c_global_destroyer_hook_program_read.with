//! expect-check-fail: read of C global `zfree` may race
// §31.8.6: the read the generated call makes of a function-pointer global
// a `freed by` clause names rests on the clause. A read the program itself
// writes is under the global rule as any other.
use c_import("typedef unsigned char xchar;\ntypedef struct _zdoc zdoc;\ntypedef void (*zfreefn)(void *);\nextern zfreefn zfree;\nzdoc *zdocRead(const char *path);\nvoid zdocFree(zdoc *d);\nxchar *zdocGetTitle(const zdoc *d);\n")

c contract z:
    text utf8
    resource Doc wraps *mut _zdoc
        from zdocRead
        drop zdocFree
    fn zdocGetTitle
        lend
        text return, owned, freed by zfree

fn main:
    let hook = zfree
    let _ = hook
