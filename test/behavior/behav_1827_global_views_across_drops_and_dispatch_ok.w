//! expect-stdout: 1
//! expect-stdout: first!
//! expect-stdout: first!
//! expect-stdout: 65
//! expect-stdout: first!
//! expect-stdout: 14 first!
//! expect-stdout: 3 first!
//! expect-stdout: 5 first!
//! expect-stdout: 7
//! expect-stdout: first!
//! expect-stdout: 129 t1 q t3 t4 g7 t5

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7; §2.4): a dyn call
// runs every impl of the method, a call through a stored callable any
// callable value of its type, and a drop its type's Drop impls — each a
// write of every global those bodies write. What stays accepted: a drop, a
// dyn call and a stored callable that write another global, a view whose
// last use is before the drop that writes its global, and a callable of
// another type than the global's writer.

var G: Vec[str] = Vec.new()
var B: Vec[str] = Vec.new()

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop(): B.push(f"t{self.n}")

type Grower:
    n: i32

impl Drop for Grower:
    move fn drop():
        for i in 0..64: G.push(f"grow{i}")

type Guard[T]:
    v: T

impl[T] Drop for Guard[T]:
    move fn drop(): B.push("g7")

trait Grow:
    fn grow(self: &Self)

type Quiet:
    x: i32

impl Grow for Quiet:
    fn grow(self: &Self): B.push("q")

type Twice:
    f: fn(i32) -> i32

fn twice(n: i32) -> i32: n * 2

fn grow_g():
    for i in 0..64: G.push(f"more{i}")

fn run(g: &dyn Grow):
    let r = G[0]
    g.grow()
    print(r)

fn make(n: i32) -> Tok: Tok { n }

fn main:
    G.push("first" ++ "!")
    // A drop that writes another global.
    let r = G[0]
    {
        let t = Tok { n: 1 }
        print(f"{t.n}")
    }
    print(r)
    // The view's last use is before the drop that writes G.
    {
        let g = Grower { n: 2 }
        let v = G[0]
        print(v)
    }
    print(f"{G.len()}")
    // A dyn call whose impls write another global.
    run(Quiet { x: 0 })
    // A stored callable of a type no writer of G has.
    let tw = Twice { f: twice }
    let r2 = G[0]
    print(f"{tw.f(7)} {r2}")
    // A temporary and a reassignment whose drops write another global.
    let r3 = G[0]
    print(f"{make(3).n} {r3}")
    var t4 = Tok { n: 4 }
    t4 = Tok { n: 5 }
    print(f"{t4.n} {r3}")
    // A generic Drop impl that writes another global.
    {
        let gd = Guard { v: 7 }
        print(f"{gd.v}")
    }
    print(r3)
    // G's writer, run after every view's last use.
    let k: fn() -> Unit = grow_g
    k()
    t4 = Tok { n: 6 }
    print(f"{G.len()} {B.join(" ")}")
