//! expect-stdout: ate 1
//! expect-stdout: drop 1
//! expect-stdout: ate 2
//! expect-stdout: drop 2
//! expect-stdout: ate 3
//! expect-stdout: drop 3
//! expect-stdout: peek 5
//! expect-stdout: end
//! expect-stdout: drop 5
//! expect-stdout: drop 4

// §3.9, §11.3: a `Box[dyn T]` parameter takes a `Box[C]` for any implementor
// `C` (coerced at the call) and a `Box[dyn T]` as itself; a `&dyn T`
// parameter takes a `&dyn T` as itself. The consuming callee drops the box
// once; an owner that kept it drops it at its scope end (§2.4, reverse
// declaration order). On base every call here was refused: "type 'Box' does
// not implement trait 'Held' required for dyn parameter", and forwarding a
// `&dyn Held` was "argument cannot be converted to dyn trait object". Found
// by #1847's drop-audit cells (consume_call/boxdyn).

use std.box.Box

trait Held:
    fn held(self: &Self) -> i32

type Tok:
    n: i32

impl Held for Tok:
    fn held(self: &Self) -> i32: self.n

impl Drop for Tok:
    move fn drop(): print(f"drop {self.n}")

fn eat(x: Box[dyn Held]): print(f"ate {x.held()}")
fn peek(x: &dyn Held): print(f"peek {x.held()}")
fn relay(x: &dyn Held): peek(x)

fn main:
    // A concrete box coerces at the call; the callee owns and drops it.
    eat(Box.new(Tok { n: 1 }))
    // A Box[dyn T] local moves into the callee.
    let a: Box[dyn Held] = Box.new(Tok { n: 2 })
    eat(a)
    // Conditionally moved, and taken: the callee drops it.
    var b: Box[dyn Held] = Box.new(Tok { n: 3 })
    var flip = true
    if flip:
        eat(move b)
    // Conditionally moved, not taken: its owner drops it at scope end.
    var c: Box[dyn Held] = Box.new(Tok { n: 4 })
    var flop = false
    if flop:
        eat(move c)
    // A &dyn T forwarded to another &dyn T parameter.
    let t = Tok { n: 5 }
    relay(&t)
    print("end")
