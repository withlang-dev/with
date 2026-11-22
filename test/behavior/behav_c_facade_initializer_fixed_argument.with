//! expect-stdout: flag seen: 7
//! expect-stdout: ended
//! expect-stdout: ok

// §16.2b.11: an in-place initializer may fix its other parameters, as a
// drop or a destroyer may since D209. The constructor omits the fixed
// parameter and always passes the value: `Note.init()` passes 7 for `flag`.
// This is what zlib's `inflateInit_(strm, ZLIB_VERSION, sizeof(z_stream))`
// needs. (Until 2026-11-21 this was refused as "not modeled", #3129.)

use c_import("typedef struct { int n; } note;\nstatic int note_ended = 0;\nstatic inline void note_init(note *n, int flag) { n->n = flag; }\nstatic inline void note_end(note *n) { n->n = 0; note_ended = 1; }\n")

c contract notes:
    resource Note wraps note
        init note_init(self)
        drop note_end
    fn note_init
        param flag fixed 7

fn show:
    let n = Note.init()
    print(f"flag seen: {n.n}")

fn main:
    show()
    print(if unsafe { note_ended } == 1: "ended" else: "not ended")
    print("ok")
