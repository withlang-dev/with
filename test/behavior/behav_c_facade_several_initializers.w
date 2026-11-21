//! expect-stdout: kind 1
//! expect-stdout: failed -2
//! expect-stdout: kind 2
//! expect-stdout: failed 9
//! expect-stdout: kind 3
//! expect-stdout: ends 2

// §16.2b.4 (Eric, 2026-11-21, #3173 E): a resource may state several `init`
// clauses, each a constructor. An initializer states its own success
// status on its own line (`init f(self), ok K`), as `from f, nonnull`
// states a fact of one producer; no clause binds to "the init above it".
// A failed initializer never runs the end function.
use c_import("typedef struct { int state; int kind; } strm;
static int strm_ended;
static inline int enc_init(strm* s, int level) { if (level < 0) return -2; s->state = level; s->kind = 1; return 0; }
static inline int dec_init(strm* s, int fail) { if (fail) return 9; s->state = 0; s->kind = 2; return 1; }
static inline void raw_init(strm* s) { s->state = 0; s->kind = 3; }
static inline void strm_end(strm* s) { strm_ended++; s->state = 0; }
static inline int strm_ends(void) { return strm_ended; }
static inline int strm_which(const strm* s) { return s->kind; }
")

c contract z:
    resource Stream wraps strm
        init enc_init(self), ok 0
        init dec_init(self), ok 1
        init raw_init(self)
        drop strm_end
    fn strm_which
        lend

fn show(made: Result[Stream, StreamError]):
    match made:
        Ok(s) => print(f"kind {s.which()}")
        Err(StreamError.Failed(status)) => print(f"failed {status}")

fn main:
    show(Stream.enc_init(3))
    show(Stream.enc_init(-1))
    show(Stream.dec_init(0))
    show(Stream.dec_init(1))
    let r = Stream.raw_init()
    print(f"kind {r.which()}")
    print(f"ends {strm_ends()}")
