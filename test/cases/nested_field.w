type Inner = {
    value: i32,
}

type Outer = {
    inner: Inner,
    extra: i32,
}

fn main() -> i32 =
    let o = Outer { inner: Inner { value: 40 }, extra: 2 }
    assert(o.inner.value + o.extra == 42)
    0
