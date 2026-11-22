//! expect-stdout: failed status=-1 ends=0
//! expect-stdout: true
//! expect-stdout: false
//! expect-stdout: ends=1
//! expect-stdout: true
//! expect-stdout: false

// §16.2b.4 (Eric, 2026-11-21, #3173): a status after `ok` is a constant's name
// or an integer literal. Nothing assumes 0 means success; `ok 0` is the
// contract saying so. A failed in-place init never runs the end function,
// and a negative literal is a status like any other.
use c_import("typedef struct { int state; } z_stream;
static int z_ended;
static inline int z_init(z_stream* s, int fail) { if (fail) return -1; s->state = 7; return 0; }
static inline void z_end(z_stream* s) { z_ended++; s->state = 0; }
static inline int z_ends(void) { return z_ended; }
static inline int z_poke(z_stream* s, int v) { if (v < 0) return -1; s->state = v; return 0; }
static inline int z_neg(int v) { return v > 0 ? -1 : 5; }
")

c contract zl:
    resource Stream wraps z_stream
        init z_init(self)
        ok 0
        drop z_end
    fn z_poke
        lend
        ok 0
    fn z_neg
        ok -1

fn main:
    match Stream.init(1):
        Ok(_) => print("bad")
        Err(StreamError.Failed(status)) => print(f"failed status={status} ends={z_ends()}")
    match Stream.init(0):
        Ok(s) =>
            print(s.poke(3).is_ok())
            print(s.poke(-4).is_ok())
        Err(_) => print("bad")
    print(f"ends={z_ends()}")
    print(z_neg(2).is_ok())
    print(z_neg(0).is_ok())
