//! expect-stdout: 98

// A C library that calls back into With declares the callback in its header.
// `@[c_export("zz_score")]` defines that symbol. The c_imported prototype and
// the With definition used to become two LLVM functions of one name, so the
// body was renamed `zz_score.1` and the prototype the C code calls stayed
// undefined at link.
use c_import("int zz_score(int v);\nstatic inline int zz_twice(int v) { return zz_score(v) * 2; }\n")

@[c_export("zz_score")]
fn score(v: i32) -> i32: v * v

fn main:
    print(f"{zz_twice(7)}")
