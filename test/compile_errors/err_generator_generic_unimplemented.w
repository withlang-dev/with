//! expect-check-fail: a generic generator function is not implemented yet (#1724)

gen fn twice[T](x: T) -> T:
    yield x
    yield x

fn main:
    for v in twice(3):
        print(v)
