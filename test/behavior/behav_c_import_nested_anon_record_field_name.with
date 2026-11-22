//! expect-stdout: 12

// #1380: inside an anonymous record, a named field whose type is itself an
// anonymous record keeps its C name. The translator moved the field's name
// into the first `if` arm and re-read it for the nested type and the field,
// so the field came out as `anon_0` and `o.mid.deep` did not resolve.
use c_import("typedef struct Outer { struct { struct { int a; } deep; int b; } mid; } Outer;\nstatic inline Outer mk(void) { Outer o; o.mid.deep.a = 7; o.mid.b = 5; return o; }\n")

fn main:
    let o = mk()
    print(o.mid.deep.a + o.mid.b)
