//! expect-check-fail: resource 'Stream' states two initializers, 'init enc_init' and 'init dec_init'; one in-place initializer is modeled
//! expect-check-fail: = help: state 'dec_init' on a resource of its own, or leave it raw

// A second `init` clause was accepted and the first dropped without a word:
// `Stream.enc_init` did not exist. One in-place initializer is modeled, and
// a second is an error that says so (#3173 found it: xz has many
// initializers over one stream and one end function).
use c_import("typedef struct { int state; int kind; } strm;
static inline void enc_init(strm* s, int level) { s->state = level; s->kind = 1; }
static inline void dec_init(strm* s) { s->state = 0; s->kind = 2; }
static inline void strm_end(strm* s) { s->state = 0; }
static inline int strm_which(const strm* s) { return s->kind; }
")

c contract z:
    resource Stream wraps strm
        init enc_init(self)
        init dec_init(self)
        drop strm_end
    fn strm_which
        lend

fn main: print(1)
