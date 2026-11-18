//! expect-check-fail: resource 'Reader': 'bzClose' does not take the representation in param 0: *mut i32 bzerror (§31, §16.2b.13)
//! expect-check-fail: = help: after 'bzClose' name the parameter that receives what 'Reader' wraps: '(param N)'

// #3177, D209 (§31, §16.2b.11): the parameter a destroyer names receives what the resource wraps.
use c_import("typedef struct bz { int open; } bz;\nstatic bz the_bz;\nstatic inline bz *bzOpen(void) { the_bz.open = 1; return &the_bz; }\nstatic inline void bzClose(int *bzerror, bz *b) { *bzerror = 0; b->open = 0; }\nstatic inline void bzEnd(bz *b) { b->open = 0; }\nstatic inline int bzKind(int kind, int n) { return kind + n; }\n")

c contract bzip:
    resource Reader wraps *mut bz
        from bzOpen
        drop bzEnd
        destroys bzClose(param 0)

fn main:
    print(1)
