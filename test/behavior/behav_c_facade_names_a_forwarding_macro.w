//! expect-stdout: ready 5
//! expect-stdout: ended
//! expect-stdout: ok

// #3516: a function-like macro that is one call, forwarding each of its
// parameters straight to an argument, is imported as a function with the
// callee's own parameter types, so a contract can name it. This is zlib's
// shape: `inflateInit(strm)` is `inflateInit_((strm), ZLIB_VERSION,
// (int)sizeof(z_stream))`. The macro was imported generic over its
// parameters, and a contract naming it was refused as "not a declaration
// in scope".

use c_import("#define LIB_VERSION \"1.2\"\ntypedef struct st { int level; int open; } st;\nstatic int lib_ended = 0;\nstatic inline int lib_init_(st *s, int level, const char *version, int size) { if (version == 0 || size != (int)sizeof(st)) return -6; s->level = level; s->open = 1; return 0; }\nstatic inline void lib_end(st *s) { s->open = 0; lib_ended = 1; }\n#define lib_init(s, level) lib_init_((s), (level), LIB_VERSION, (int)sizeof(st))\n")

c contract lib:
    resource Stream wraps st
        init lib_init(self), ok 0
        drop lib_end

fn show:
    match Stream.lib_init(5):
        Ok(s) => print(f"ready {s.level}")
        Err(e) => print("failed")

fn main:
    show()
    print(if unsafe { lib_ended } == 1: "ended" else: "not ended")
    print("ok")
