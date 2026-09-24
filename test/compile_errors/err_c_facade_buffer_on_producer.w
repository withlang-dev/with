//! expect-check-fail: a buffer pairing describes a lend or a free operation

// D64 §16.2b.8: a producer's rendering is the resource's constructor; a
// slice in it is not modeled.
use c_import("void *malloc(unsigned long size);\nvoid free(void *p);\ntypedef struct note { int v; } note;\nstatic inline note *note_from(const unsigned char *p, unsigned long n) { note *x = (note *)malloc(sizeof(note)); x->v = (int)n; return x; }\nstatic inline void note_free(note *n) { free(n); }\n")

c facade notes:
    resource Note wraps *mut note
        from note_from
        drop note_free
    fn note_from
        buffer param p len param n

fn main:
    print("unreachable")
