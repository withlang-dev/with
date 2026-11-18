//! expect-check-fail: fn 'streamStep': 'buffer field words' names a field of type *mut i32, not a pointer to bytes (§16.2b.8)
//! expect-check-fail: = help: after 'buffer field' name the field that points at the bytes; its count follows 'remaining field'

// #3173, D210 (§16.2b.8): the paired field points at bytes.
use c_import("typedef struct { const unsigned char *next_in; unsigned int avail_in; int *words; double ratio; } stream;\nstatic inline int streamInit(stream* s) { s->avail_in = 0; return 0; }\nstatic inline void streamEnd(stream* s) { s->avail_in = 0; }\nstatic inline int streamStep(stream* s, int flush) { return flush; }\nstatic inline int streamPeek(const stream* s) { return (int)s->avail_in; }\nstatic inline int streamFree(int n) { return n; }\n")

c contract st:
    resource Stream wraps stream
        init streamInit(self)
        drop streamEnd
    fn streamStep
        lend
        buffer field words remaining field avail_in

fn main:
    print(1)
