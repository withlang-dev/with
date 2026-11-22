//! expect-stdout: ok

type Pair { x: i32, y: i32 } with Copy
type Runner {}

fn take_i32(x: i32) -> i32: x
fn take_i64(x: i64) -> i64: x
fn take_pair(p: Pair) -> i32: p.x + p.y

impl Runner:
    fn take(x: i64) -> i64: x

fn forward_copy[T: Copy](f: fn(T) -> T, value: &T) -> T: f(value)

fn main:
    let x: i32 = 42
    let value = &x
    assert(take_i32(&x) == 42)
    assert(take_i32(value) == 42)
    assert(take_i64(value) == 42)

    let fp: *const fn(i64) -> i64 = &take_i64
    assert(fp(value) == 42)
    let runner = Runner {}
    assert(runner.take(value) == 42)
    assert(forward_copy(take_i32, value) == 42)

    let pair = Pair { x: 20, y: 22 }
    assert(take_pair(&pair) == 42)

    let values: List[i32] = List.new()
    values.push(value)
    assert(values[0] == 42)
    print("ok")
