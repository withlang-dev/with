//! expect-stdout: ok

// §16.4 union safety: one initializer; safe read of the last-written field;
// safe writes; non-last-written reads only under unsafe.

type Value = union { a: i32, b: i32 }

fn main:
    var v = Value { a: 1 }
    let x = v.a          // last-written is a — safe
    v.b = 5              // writing any field is safe
    let y = v.b          // last-written is now b — safe
    unsafe:
        let _ = v.a      // non-last-written read requires unsafe — allowed here
    if x == 1 and y == 5:
        print("ok")
    else:
        print("bad")
