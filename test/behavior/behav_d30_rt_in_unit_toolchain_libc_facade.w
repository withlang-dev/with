//! expect-stdout: two values: true true
//! expect-stdout: ok

// D30: compiled in-unit, the runtime's own `libc` facade blocks are in the
// program's pool, but they are not the program's facades: the toolchain
// libc facade keeps every name it renders, `domain environ` included. Taken
// as claims, they removed the domain from its text while its getenv row
// named it, and every program using getenv failed ("unknown domain
// 'environ'"). The lane twin of behav_c_facade_getenv_twice.
use c_import("char *getenv(const char *name);\n")

fn main:
    let home = getenv("HOME").map(v => v.to_owned())
    let path = getenv("PATH")
    print(f"two values: {home.is_some()} {path.is_some()}")
    print("ok")
