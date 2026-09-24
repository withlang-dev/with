//! expect-stdout: inflate 5 deflate 25
//! expect-stdout: reset 1 2
//! expect-stdout: ok

// D51 stage 8 (ruling §14, §53; spec §16.2b.3, §16.2b.11): two resources
// wrap `z_stream`, so an operation taking `z_stream *` is a method of the
// one its fn item's `of` names, and of nothing without it. A lend of an
// in-place resource is rendered on it, handing C the pinned cell's address
// (D54). No prefix of `z_stream` matches `inflate`, so the imported names
// stay: `i.inflate(4)`, `InflateStream.inflateInit()`.

use c_import("typedef struct { int state; int mode; } z_stream;
static inline int inflateInit(z_stream* s) { s->state = 1; return 0; }
static inline int deflateInit(z_stream* s, int level) { s->state = 2; s->mode = level; return 0; }
static inline int inflate(z_stream* s, int flush) { return s->state + flush; }
static inline int deflate(z_stream* s, int flush) { return s->state * 10 + flush; }
static inline int inflateReset(z_stream* s) { return s->state; }
static inline int deflateReset(z_stream* s) { return s->state; }
static inline void inflateEnd(z_stream* s) { s->state = 0; }
static inline void deflateEnd(z_stream* s) { s->state = 0; }
")

c facade zlib:
    resource InflateStream wraps z_stream
        init inflateInit(self)
        drop inflateEnd
    resource DeflateStream wraps z_stream
        init deflateInit(self)
        drop deflateEnd
    fn inflate
        of InflateStream
    fn deflate
        of DeflateStream
    fn inflateReset
        of InflateStream
        rename reset
    fn deflateReset
        of DeflateStream
        rename reset

fn main:
    let (_, i) = InflateStream.inflateInit()
    let (_, d) = DeflateStream.deflateInit(3)
    print(f"inflate {i.inflate(4)} deflate {d.deflate(5)}")
    print(f"reset {i.reset()} {d.reset()}")
    print("ok")
