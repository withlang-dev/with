//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// §9.1 / D60 with D32: a field of a local struct, as the tail `h.name` is.

type Holder { n: i32, name: str }
fn f -> str:
    var h = Holder { n: 0, name: "" }
    h.name = "x".clone()

fn main: print(f())
