//! expect-stdout: 1
//! expect-stdout: 2
//! expect-stdout: 42
//! expect-stdout: 3
//! expect-stdout: 11

// #1698 / §12.4, D63 (3): a callee that stores or returns its callable
// parameter takes the owning spellings — a `move ||` closure or a bare
// function — and they run; a callee that only invokes or passes its
// parameter on takes a non-move closure over a local.
type Cnt { f: fn() -> i32 }
fn wrap(f: fn() -> i32) -> Cnt: Cnt { f: f }
fn some(f: fn() -> i32) -> Option[fn() -> i32]: Some(f)
fn forty_two() -> i32: 42
fn run(f: fn() -> i32) -> i32: f()
fn relay(f: fn() -> i32) -> i32: run(f) + 1
fn main:
    var xs: List[i32] = List.new()
    xs.push(1)
    let n = xs.len32()
    let c = wrap(move () => n)
    print(c.f())
    let o = some(move () => n + 1)
    print(o.unwrap()())
    let k = wrap(forty_two)
    print(k.f())
    xs.push(2)
    xs.push(3)
    print(run(() => xs.len32()))
    print(relay(() => xs.len32() + 7))
