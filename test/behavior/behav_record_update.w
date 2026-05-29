//! expect-stdout: ok

// Behavior test: record update syntax { expr with field: val }

type Config {
    width: i32,
    height: i32,
    depth: i32,
}

type GenericBox[T] {
    value: Option[T],
    label: str,
}

fn GenericBox.set_value(move self: GenericBox[T], value: T) -> GenericBox[T]:
    { self with value: Some(value) }

fn test_basic_update:
    let c = Config { width: 100, height: 200, depth: 50 }
    let c2 = { c with width: 300 }
    assert(c2.width == 300)
    assert(c2.height == 200)
    assert(c2.depth == 50)

fn test_update_multiple_fields:
    let c = Config { width: 10, height: 20, depth: 30 }
    let c2 = { c with width: 100, height: 200 }
    assert(c2.width == 100)
    assert(c2.height == 200)
    assert(c2.depth == 30)

fn test_generic_update:
    let b: GenericBox[i32] = GenericBox { value: None, label: "old" }
    let b2 = { b with value: Some(7) }
    assert(b2.value.unwrap() == 7)
    assert(b2.label == "old")
    let b3 = b2.set_value(9)
    assert(b3.value.unwrap() == 9)
    assert(b3.label == "old")

fn main:
    test_basic_update()
    test_update_multiple_fields()
    test_generic_update()
    print("ok")
