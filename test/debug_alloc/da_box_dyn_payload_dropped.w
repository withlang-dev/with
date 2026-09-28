//! expect-debug-alloc: leak count=0
// #1847: a Box[dyn T] frees its cell and drops what it holds (a str field,
// a Drop struct, boxes in a Vec and a struct field, moved, reassigned,
// returned, consumed through the vtable). On base the Vec and field cases
// aborted codegen; without them, 7 blocks leaked (the cells and the str).

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
