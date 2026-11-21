//! expect-check-fail: resource 'Stream' states 'init enc_init' twice
//! expect-check-fail: = help: delete one 'init enc_init(self)'

// Several initializers are several constructors; the same one twice is an
// error naming it.
use c_import("typedef struct { int state; } strm;
static inline void enc_init(strm* s) { s->state = 1; }
static inline void strm_end(strm* s) { s->state = 0; }
")

c contract z:
    resource Stream wraps strm
        init enc_init(self)
        init enc_init(self)
        drop strm_end

fn main: print(1)
