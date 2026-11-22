//! expect-stdout: 7

// #3487: a C struct tag that is a With keyword (`struct it`, `struct
// match`) is declared escaped, and every type that refers to it follows.
// The references were left as the keyword and the header did not parse.
use c_import("typedef struct it { int n; } iter_s;\nstruct match { int k; };\ntypedef struct match match_t;\nstatic inline int f(struct it *p, struct match *m) { return p->n + m->k; }")
fn main:
    var a = iter_s { n: 2 }
    var b = match_t { k: 5 }
    print(unsafe { f(&raw mut a, &raw mut b) })
