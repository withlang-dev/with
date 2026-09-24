//! expect-stdout: add: 8
//! expect-stdout: tail: 0
//! expect-stdout: set: 7
//! expect-stdout: flag: 0
//! expect-stdout: ok

// D64 (spec §16.2b.11): `param N fixed <literal>` binds a C parameter to a
// literal and removes it from the presented signature; the presented call
// always passes the literal. An integer (`param b fixed 5`) and a pointer
// (`param tail fixed null`) on a free operation, and an integer on a
// resource's lend method (`n.set(v)` passes `flags` as 0). A fixed
// argument is a stated fact of the facade, not an optional argument: the
// presented `add3` takes one argument, `Note.set` takes one.

use c_import("static inline int add3(int a, int b, const char *tail) { int t = 0; if (tail != 0) t = 100; return a + b + t; }\nstatic inline int has_tail(int a, const char *tail) { if (tail != 0) return 1; return 0; }\nvoid *malloc(unsigned long size);\nvoid free(void *p);\ntypedef struct note { int v; int flags; } note;\nstatic inline note *note_new(void) { note *n = (note *)malloc(sizeof(note)); n->v = 0; n->flags = 9; return n; }\nstatic inline void note_free(note *n) { free(n); }\nstatic inline void note_set(note *n, int v, int flags) { n->v = v; n->flags = flags; }\nstatic inline int note_v(note *n) { return n->v; }\nstatic inline int note_flags(note *n) { return n->flags; }\n")

c facade notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn add3
        param b fixed 5
        param tail fixed null
    fn has_tail
        param tail fixed null
    fn note_set
        lend
        param flags fixed 0
    fn note_v
        lend
    fn note_flags
        lend

fn main:
    print(f"add: {add3(3)}")
    print(f"tail: {has_tail(1)}")
    let n = Note.new().unwrap()
    n.set(7)
    print(f"set: {n.v()}")
    print(f"flag: {n.flags()}")
    print("ok")
