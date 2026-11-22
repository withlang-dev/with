//! expect-stdout: ok

// #566: a payloadless discriminant-enum variant constructed in CALL form
// (Color.Red()) lowers to its repr-backed int constant — same as the bare
// Color.Red path. Previously check passed but codegen died (§9.7/§4.4).

enum Color { Red | Green | Blue }

fn pick(n: i32) -> Color:
    if n == 0: Color.Red() else: Color.Blue()

fn main:
    let c = pick(0)
    assert(c == Color.Red)
    let d = Color.Green()
    assert(d == Color.Green)
    assert(pick(5) == Color.Blue)
    print("ok")
