//! expect-check-fail: fn 'streamFree': 'buffer field' pairs two fields of the record a lent resource wraps, and 'streamFree' is no lend of one resource (§16.2b.8)
//! expect-check-fail: = help: state it on an operation whose first parameter receives the resource whose record carries the pointer and its count

// #3173, D210 (§16.2b.8): the fields are the lent resource's, so an operation that lends none has none to pair.
use c_import("typedef struct { const unsigned char *next_in; unsigned int avail_in; int *words; double ratio; } stream;\nstatic inline int streamInit(stream* s) { s->avail_in = 0; return 0; }\nstatic inline void streamEnd(stream* s) { s->avail_in = 0; }\nstatic inline int streamStep(stream* s, int flush) { return flush; }\nstatic inline int streamPeek(const stream* s) { return (int)s->avail_in; }\nstatic inline int streamFree(int n) { return n; }\n")

c contract st:
    resource Stream wraps stream
        init streamInit(self)
        drop streamEnd
    fn streamFree
        buffer field next_in remaining field avail_in

fn main:
    print(1)
