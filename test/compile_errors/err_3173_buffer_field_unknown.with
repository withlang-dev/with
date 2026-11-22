//! expect-check-fail: fn 'streamStep': 'buffer field next_in remaining field avail' names 'avail', which is no field of the record Stream wraps (§16.2b.8)
//! expect-check-fail: = help: name the pointer field and the count field as the header declares them

// #3173, D210 (§16.2b.8): both names are fields of the record the resource wraps.
use c_import("typedef struct { const unsigned char *next_in; unsigned int avail_in; int *words; double ratio; } stream;\nstatic inline int streamInit(stream* s) { s->avail_in = 0; return 0; }\nstatic inline void streamEnd(stream* s) { s->avail_in = 0; }\nstatic inline int streamStep(stream* s, int flush) { return flush; }\nstatic inline int streamPeek(const stream* s) { return (int)s->avail_in; }\nstatic inline int streamFree(int n) { return n; }\n")

c contract st:
    resource Stream wraps stream
        init streamInit(self)
        drop streamEnd
    fn streamStep
        lend
        buffer field next_in remaining field avail

fn main:
    print(1)
