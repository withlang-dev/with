//! expect-contract: violations=0 ok
//! expect-contract-not: #1674

// #1674 follow-up: an in-place producer (`init z_init(self)`, D54) is
// rendered as the constructor `Stream.init(ends, misplaced)`, with the
// storage slot — its first C parameter — removed. It is not a lend method
// of the resource: registering it as one put the slot's bit 0 on the
// constructor's first real parameter, `ends`, which holds no resource, and
// the audit reported it on behav_c_facade_resource_in_place_pinned.w.
use c_import("typedef struct z_stream_s { int state; struct z_stream_s* strm; int* ends; int* misplaced; } z_stream;
static inline int z_init(z_stream* s, int* ends, int* misplaced) { s->state = 7; s->strm = s; s->ends = ends; s->misplaced = misplaced; return 0; }
static inline int z_check(const z_stream* s) { return s->strm == s ? s->state : -1; }
static inline void z_end(z_stream* s) { if (s->strm == s && s->state == 7) { s->state = 0; (*s->ends)++; } }
")

c facade zl:
    resource Stream wraps z_stream
        init z_init(self)
        drop z_end
    fn z_init
        lend
    fn z_check
        lend

fn main:
    var ends: c_int = 0
    var misplaced: c_int = 0
    let (_, s) = Stream.init(&raw mut ends, &raw mut misplaced)
    print(f"{s.check()}")
