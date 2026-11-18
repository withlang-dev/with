//! expect-check-fail: fn 'bzKind': 'param 0 discarded' names param 0: i32 kind, which is not a pointer C writes a number, a flag or a pointer through (§16.2b.11)
//! expect-check-fail: = help: discard an out-pointer to a scalar; a value the function reads is 'fixed', and a record it fills is 'fills'

// #3177, D209 (§31, §16.2b.11): only an out-pointer to a scalar is discarded.
use c_import("typedef struct bz { int open; } bz;\nstatic bz the_bz;\nstatic inline bz *bzOpen(void) { the_bz.open = 1; return &the_bz; }\nstatic inline void bzClose(int *bzerror, bz *b) { *bzerror = 0; b->open = 0; }\nstatic inline void bzEnd(bz *b) { b->open = 0; }\nstatic inline int bzKind(int kind, int n) { return kind + n; }\n")

c contract bzip:
    fn bzKind
        param 0 discarded

fn main:
    print(1)
