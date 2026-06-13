//! expect-error: return type mismatch

trait BadReturn:
    fn value(self: &Self) -> i32:
        "wrong"

type BadReturnType { value: i32 }

impl BadReturn for BadReturnType

fn main:
    let x = BadReturnType { value: 1 }
    let _ = x.value()

