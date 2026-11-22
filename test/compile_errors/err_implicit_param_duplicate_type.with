//! expect-check-fail: function has multiple implicit parameters of the same type

type Ctx { value: i32 }

fn f(left: implicit Ctx, right: implicit Ctx) -> i32:
    left.value + right.value

fn main:
    let _ = f()
