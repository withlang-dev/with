//! expect-error: unknown method 'missing'

trait BadDefault:
    fn value(self: &Self) -> i32:
        self.missing()

type BadDefaultType { value: i32 }

impl BadDefault for BadDefaultType

fn main:
    let x = BadDefaultType { value: 1 }
    let _ = x.value()

