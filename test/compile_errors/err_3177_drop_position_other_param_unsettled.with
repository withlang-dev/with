//! expect-check-fail: 'drop bzClose' takes 2 parameters, and Drop has only the representation to pass: param 0: *mut i32 bzerror is neither fixed nor discarded
//! expect-check-fail: = help: under 'fn bzClose' write 'param 0 discarded' for an out-pointer or 'param 0 fixed null', or write 'destroys bzClose' and name another function as 'drop'

// #3177, D209 (§31, §16.2b.11): a drop at a stated position still has only the resource to pass, so its other parameters are fixed or discarded.
use c_import("typedef struct bz { int open; } bz;\nstatic bz the_bz;\nstatic inline bz *bzOpen(void) { the_bz.open = 1; return &the_bz; }\nstatic inline void bzClose(int *bzerror, bz *b) { *bzerror = 0; b->open = 0; }\nstatic inline void bzEnd(bz *b) { b->open = 0; }\nstatic inline int bzKind(int kind, int n) { return kind + n; }\n")

c contract bzip:
    resource Reader wraps *mut bz
        from bzOpen
        drop bzClose(param 1)

fn main:
    print(1)
