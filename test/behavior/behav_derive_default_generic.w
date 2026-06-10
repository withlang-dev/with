//! expect-stdout: ok

@[derive(Default)]
type Boxed[T] { value: T }

@[derive(Default)]
type Pair[T] {
    left: T,
    right: T,
}

type Manual { value: i32 }

impl Default for Manual:
    fn default() -> Manual:
        Manual { value: 123 }

fn main:
    let b: Boxed[i32] = Boxed[i32].default()
    assert(b.value == 0)

    let p: Pair[Manual] = Pair[Manual].default()
    assert(p.left.value == 123)
    assert(p.right.value == 123)

    print("ok")
