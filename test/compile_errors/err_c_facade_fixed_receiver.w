//! expect-check-fail: which receives a modeled resource; a resource is passed by the value that owns it, never fixed

// D64 §16.2b.11: a parameter that receives a resource is the resource's.
use c_import("void *malloc(unsigned long size);\nvoid free(void *p);\ntypedef struct note { int v; } note;\nstatic inline note *note_new(void) { return (note *)malloc(sizeof(note)); }\nstatic inline void note_free(note *n) { free(n); }\nstatic inline int note_v(note *n) { return n->v; }\n")

c facade notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_v
        lend
        param n fixed null

fn main:
    print("unreachable")
