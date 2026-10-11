//! expect-stdout: hello
//! expect-stdout: ok

fn apply(f: fn() -> i32) -> i32:
    f()

fn apply_void(f: fn() -> Unit): f()

fn main:
    // Capture a string
    let s = "hello"
    let f = () => print(s)
    apply_void(f)

    // Capture an integer
    let x: i32 = 42
    let g = () => x
    assert(apply(g) == 42)

    // Capture multiple variables
    let a: i32 = 10
    let b: i32 = 20
    let h = () => a + b
    assert(apply(h) == 30)

    print("ok")
