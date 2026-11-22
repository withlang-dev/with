//! expect-stdout: trace: ate1 drop1 ate2 drop2 ate3 drop3 peek5 end drop5 drop4

// §3.9, §11.3: a `Box[dyn T]` parameter takes a `Box[C]` for any implementor
// `C` (coerced at the call) and a `Box[dyn T]` as itself; a `&dyn T`
// parameter takes a `&dyn T` as itself. The consuming callee drops the box
// once; an owner that kept it drops it at its scope end (§2.4, reverse
// declaration order). On base every call here was refused: "type 'Box' does
// not implement trait 'Held' required for dyn parameter", and forwarding a
// `&dyn Held` was "argument cannot be converted to dyn trait object" (#1854,
// found by #1847's drop-audit cells). main's own locals drop after its last
// statement, so the trace is printed from a function that outlives them.
// One trace line pins order and count (expect-stdout is substring-matched,
// #1855).

use std.box.Box

global var TRACE = ""

fn note(s: &str): TRACE = TRACE ++ " " ++ s

trait Held:
    fn held(self: &Self) -> i32

type Tok:
    n: i32

impl Held for Tok:
    fn held(self: &Self) -> i32: self.n

impl Drop for Tok:
    move fn drop(): note(f"drop{self.n}")

fn eat(x: Box[dyn Held]): note(f"ate{x.held()}")
fn peek(x: &dyn Held): note(f"peek{x.held()}")
fn relay(x: &dyn Held): peek(x)

fn scenario:
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
    note("end")

fn main:
    scenario()
    print("trace:" ++ TRACE)
