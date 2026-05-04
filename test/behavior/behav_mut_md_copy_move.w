fn callee(x: i32) -> i32:
    return x

fn main:
    // copy: source binding remains valid after the call
    let a: i32 = 10
    let _ = callee(copy a)
    let b = a + 1   // a is still accessible
    assert(b == 11)

    // move: binding is invalidated but value is passed correctly
    let c: i32 = 99
    let _ = callee(move c)
    // c is no longer accessible here

    print("ok\n")
