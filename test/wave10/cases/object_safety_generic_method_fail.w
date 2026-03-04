trait Factory =
    fn make[T](self: Self) -> T

fn use_dyn(x: dyn Factory) -> i32:
    0

fn main -> i32: 0
