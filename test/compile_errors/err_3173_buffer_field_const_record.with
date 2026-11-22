//! expect-check-fail: fn 'streamPeek': 'buffer field' stores the slice in Stream's record before the call, and param 0: *const stream s is not a pointer the wrapper may write through (§16.2b.8)
//! expect-check-fail: = help: leave the function raw: an operation that takes the record by a const pointer does not read a buffer the caller sets for the call

// #3173, D210 (§16.2b.8): the wrapper writes the fields, so the operation takes the record by a pointer it may write through.
use c_import("typedef struct { const unsigned char *next_in; unsigned int avail_in; int *words; double ratio; } stream;\nstatic inline int streamInit(stream* s) { s->avail_in = 0; return 0; }\nstatic inline void streamEnd(stream* s) { s->avail_in = 0; }\nstatic inline int streamStep(stream* s, int flush) { return flush; }\nstatic inline int streamPeek(const stream* s) { return (int)s->avail_in; }\nstatic inline int streamFree(int n) { return n; }\n")

c contract st:
    resource Stream wraps stream
        init streamInit(self)
        drop streamEnd
    fn streamPeek
        lend
        buffer field next_in remaining field avail_in

fn main:
    print(1)
