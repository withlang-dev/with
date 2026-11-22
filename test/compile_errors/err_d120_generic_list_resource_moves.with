//! expect-error: use of moved value (`List[Res]`)

// D120 stage 5 (§2.3): a generic function copies or moves per instantiation,
// and an error inside a generic body names the resource-bearing instantiated
// type (`List[Res]`), never a value instantiation (`List[i64]`).

resource type Res {
    fd: i32,
}

fn consume[T](xs: List[T]) -> isize:
    xs.len()

fn use_twice[T](xs: List[T]) -> isize:
    let a = consume(xs)
    let b = consume(xs)
    a + b

fn main:
    let vals = [1, 2, 3]
    assert(use_twice(vals) == 6)

    var resources: List[Res] = List.new()
    resources.push(Res { fd: 3 })
    let _ = use_twice(resources)
