// Test deeply nested struct access
type Inner = {
    value: i32,
}

type Middle = {
    inner: Inner,
    label: i32,
}

type Outer = {
    middle: Middle,
    id: i32,
}

fn main() -> i32 =
    let inner = Inner { value: 42 }
    let middle = Middle { inner: inner, label: 10 }
    let outer = Outer { middle: middle, id: 1 }

    // Deep field access
    println(outer.id)
    println(outer.middle.label)
    println(outer.middle.inner.value)
    0
