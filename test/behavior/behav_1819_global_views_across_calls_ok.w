//! expect-stdout: first!
//! expect-stdout: 65
//! expect-stdout: b0 first!
//! expect-stdout: first! 65
//! expect-stdout: first! 3
//! expect-stdout: first! b1
//! expect-stdout: first!
//! expect-stdout: 129
//! expect-stdout: 2
//! expect-stdout: hi
//! expect-stdout: first!
//! expect-stdout: first!
//! expect-stdout: first!
//! expect-stdout: 193 3

// #1819 (§9.1c: globals are places; §21.1 rule 1): a call is a write of
// every global its callee writes, so a view of that global may not be live
// across it. What stays accepted: a view whose last use is before the
// call, a call that writes another global, a callee that only reads the
// global, a recursive callee that writes nothing, and an argument that
// views a global its callee never writes.

var G: Vec[str] = Vec.new()
var B: Vec[str] = Vec.new()

fn grow():
    for i in 0..64: G.push(f"item{i}")

fn grow_b(): B.push(f"b{B.len()}")

fn peek() -> i64: G.len()

fn depth(n: i32) -> i32: if n == 0: 0 else: depth(n - 1) + 1

fn show_then_grow_b(r: &str):
    grow_b()
    print(f"{r} {B[B.len() as i32 - 1]}")

// A view of G live across a run of `f`: accepted when no closure a caller
// passes for `f` writes G.
fn around(f: fn() -> Unit):
    let r = G[0]
    f()
    print(r)

// The view's last use comes before `f` runs.
fn before_run(f: fn() -> Unit):
    let r = G[0]
    print(r)
    f()

fn main:
    G.push("first" ++ "!")
    // The view's last use is before the call that writes G.
    let before = G[0]
    print(before)
    grow()
    print(f"{G.len()}")
    // The call writes B, not G.
    let r = G[0]
    grow_b()
    print(f"{B[0]} {r}")
    // The callee only reads G.
    let seen = G[0]
    let n = peek()
    print(f"{seen} {n}")
    // A recursive callee that writes no global.
    let deep = G[0]
    let d = depth(3)
    print(f"{deep} {d}")
    // The argument views G; the callee writes only B.
    show_then_grow_b(G[0])
    // A closure that writes G, run after the view's last use.
    let more: fn() -> Unit = () => { for i in 0..64: G.push(f"more{i}") }
    let head = G[0]
    print(head)
    more()
    print(f"{G.len()}")
    print(f"{B.len()}")
    // Closures and a named function that write B, or G after the view.
    around(() => print("hi"))
    around(grow_b)
    before_run(() => { for i in 0..64: G.push(f"late{i}") })
    print(f"{G.len()} {B.len()}")
