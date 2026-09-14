//! expect-stdout: ok

type Inner[T] { value: T }
type Outer[T] { left: i32, inner: Inner[T], right: i32 }

fn integers() -> Outer[i32]: Outer { left: 11, inner: Inner { value: 22 }, right: 33 }
fn strings() -> Outer[str]: Outer { right: 55, inner: Inner { value: "owned".clone() }, left: 44 }

fn main:
    let ints = integers()
    assert(ints.left == 11)
    assert(ints.inner.value == 22)
    assert(ints.right == 33)
    let texts = strings()
    assert(texts.left == 44)
    assert(texts.inner.value == "owned")
    assert(texts.right == 55)
    print("ok")
