//! expect-stdout: 12
//! expect-stdout: 21
//! expect-stdout: 18
//! expect-stdout: 12
//! expect-stdout: 9
//! expect-stdout: 12

// D218 (§3.2): a closure passed in the same call may not capture a place
// that overlaps a `mut` receiver or `mut` argument. These do not overlap
// and stay legal: another field of the same variable than the one the call
// holds, another variable, a value read into a `let` before the call, and
// a `move` closure.
type Inner { items: List[i32], m: i32 }
impl Inner:
    mut fn each(body: fn(i32) -> i32) -> i32:
        var t = 0
        for v in self.items: t += body(v)
        t

type Bag { n: i32, name: str, inner: Inner }

fn bump(mut b: Inner, body: fn(i32) -> i32) -> i32: b.each(body)
fn mk() -> Bag: Bag { n: 2, name: "bag", inner: Inner { items: [1, 2, 3], m: 4 } }

fn main:
    var x = mk()
    var y = mk()
    print(x.inner.each((v) => v + x.n))
    print(x.inner.each((v) => v + x.n as i32 + x.name.len() as i32))
    print(x.inner.each((v) => v + y.inner.m))
    print(bump(x.inner, (v) => v + x.n))
    print(x.inner.each(move (v) => v + 1))
    let m = x.inner.m
    print(x.inner.each((v) => v + m - 2))
