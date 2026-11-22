//! expect-stdout: init: 0
//! expect-stdout: level: 6
//! expect-stdout: ok

// §16.2b.11: a fixed argument may be a constant the header defines
// (`param version fixed LIB_VERSION`) or the size of an imported type
// (`param size fixed sizeof(st)`). This is the shape of zlib's real
// initializers: `inflateInit_(strm, ZLIB_VERSION, (int)sizeof(z_stream))`.
// The C function refuses any other version text or size, so a wrong
// rendering prints a failure and not `init: 0`.

use c_import("#define LIB_VERSION \"1.2\"\n#define LIB_LEVEL 6\ntypedef struct st { int a; long b; } st;\nstatic inline int lib_init_(const char *version, int size) { if (version == 0 || size != (int)sizeof(st)) return -6; return 0; }\nstatic inline int lib_level(int level) { return level; }\n")

c contract notes:
    fn lib_init_
        rename init
        param version fixed LIB_VERSION
        param size fixed sizeof(st)
    fn lib_level
        rename level
        param level fixed LIB_LEVEL

fn main:

    print(f"init: {init()}")
    print(f"level: {level()}")
    print("ok")
