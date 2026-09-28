//! expect-stdout: name 1
//! expect-stdout: drop 1
//! expect-stdout: name 4
//! expect-stdout: name 3
//! expect-stdout: name 4
//! expect-stdout: drop 4
//! expect-stdout: drop 5
//! expect-stdout: name 6
//! expect-stdout: drop 6
//! expect-stdout: len 2
//! expect-stdout: drop 7
//! expect-stdout: name 8
//! expect-stdout: drop 8
//! expect-stdout: name 9
//! expect-stdout: drop 9
//! expect-stdout: drop 10
//! expect-stdout: take 100
//! expect-stdout: end

// #1847 (§2.4, §11.3): a `Box[dyn T]` drops what it holds, exactly once, at
// its owner's drop point, then frees the cell. The vtable carries the
// concrete type's drop glue; a dyn method call borrows its receiver unless
// the method consumes it. On base, `Tok`'s Drop never ran (every `drop N`
// line missing), a Box[Concrete] pushed onto a Vec[Box[dyn T]] or stored in
// a Box[dyn T] field aborted codegen, and a call through the box moved it.

use std.box.Box

trait Named:
    fn name(self: &Self) -> i32
    fn take(move self: Self) -> i32

type Tok:
    n: i32

impl Named for Tok:
    fn name(self: &Self) -> i32: self.n
    fn take(move self: Self) -> i32: self.n * 10

impl Drop for Tok:
    move fn drop(): print(f"drop {self.n}")

type Label:
    text: str

impl Named for Label:
    fn name(self: &Self) -> i32: self.text.len() as i32
    fn take(move self: Self) -> i32: 0

type Point:
    x: i32

impl Copy for Point

impl Named for Point:
    fn name(self: &Self) -> i32: self.x
    fn take(move self: Self) -> i32: self.x

type Holder:
    b: Box[dyn Named]

fn make(n: i32) -> Box[dyn Named]: Box.new(Tok { n })

fn main:
    // A Drop struct, observed through the vtable, dropped at its scope end.
    {
        let b: Box[dyn Named] = Box.new(Tok { n: 1 })
        print(f"name {b.name()}")
    }
    // A str-holding struct: its field is freed with the cell.
    {
        let b: Box[dyn Named] = Box.new(Label { text: "ab".clone() ++ "cd" })
        print(f"name {b.name()}")
    }
    // A Copy struct: nothing to drop but the cell.
    {
        let b: Box[dyn Named] = Box.new(Point { x: 3 })
        print(f"name {b.name()}")
    }
    // Moved out: the new owner drops it, once.
    {
        let b: Box[dyn Named] = Box.new(Tok { n: 4 })
        let c = b
        print(f"name {c.name()}")
    }
    // Reassigned: the old value drops at the assignment.
    {
        var b: Box[dyn Named] = Box.new(Tok { n: 5 })
        b = Box.new(Tok { n: 6 })
        print(f"name {b.name()}")
    }
    // In a Vec: the Vec's drop drops each box.
    {
        var v: Vec[Box[dyn Named]] = Vec.new()
        v.push(Box.new(Tok { n: 7 }))
        v.push(Box.new(Label { text: "x".clone() ++ "y" }))
        print(f"len {v.len()}")
    }
    // In a struct field.
    {
        let h = Holder { b: Box.new(Tok { n: 8 }) }
        print(f"name {h.b.name()}")
    }
    // Returned from a function.
    {
        let b = make(9)
        print(f"name {b.name()}")
    }
    // Consumed through the vtable: the callee owns and drops it.
    {
        let b: Box[dyn Named] = Box.new(Tok { n: 10 })
        let t = b.take()
        print(f"take {t}")
    }
    print("end")
