//! expect-stdout: 1
//! expect-stdout: 1
//! expect-stdout: 2
//! expect-stdout: 2
//! expect-stdout: drop t

// §3.8, §3.8a: a function value's type states each parameter's mode. A
// call through it does not take an argument its `&T` parameter observes or
// its `mut T` parameter writes in place. (`let f = obs; f(b); f(b)` was a
// use of a moved value: every argument of a call through a value was
// marked moved.)
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

type Bag { n: i32, tag: Tag }

fn obs(b: &Bag) -> i32: b.n
fn bump(mut b: Bag) -> i32:
    b.n += 1
    b.n

fn main:
    var b = Bag { n: 1, tag: Tag { name: "t" } }
    let f = obs
    print(f(b))
    print(f(b))
    let g = bump
    print(g(b))
    print(b.n)
