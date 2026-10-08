//! expect-stdout: trace: name1 drop1 name4 name3 name4 drop4 drop5 name6 drop6 len2 drop7 name8 drop8 name9 drop9 drop10 take100 end

// #1847 (§2.4, §11.3): a `Box[dyn T]` drops what it holds, exactly once, at
// its owner's drop point, then frees the cell. The vtable carries the
// concrete type's drop glue; a dyn method call borrows its receiver unless
// the method consumes it. On base, `Tok`'s Drop never ran (every `dropN`
// missing), a Box[Concrete] pushed onto a Vec[Box[dyn T]] or stored in a
// Box[dyn T] field aborted codegen, and a call through the box moved it.
// One trace line pins order and count (expect-stdout is substring-matched,
// #1855).

use std.box.Box

global var TRACE = ""

fn note(s: &str): TRACE = TRACE ++ " " ++ s

trait Named:
    fn name(self: &Self) -> i32
    fn take(move self: Self) -> i32

type Tok:
    n: i32

impl Named for Tok:
    fn name(self: &Self) -> i32: self.n
    fn take(move self: Self) -> i32: self.n * 10

impl Drop for Tok:
    move fn drop(): note(f"drop{self.n}")

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
        note(f"name{b.name()}")
    }
    // A str-holding struct: its field is freed with the cell.
    {
        let b: Box[dyn Named] = Box.new(Label { text: "ab" ++ "cd" })
        note(f"name{b.name()}")
    }
    // A Copy struct: nothing to drop but the cell.
    {
        let b: Box[dyn Named] = Box.new(Point { x: 3 })
        note(f"name{b.name()}")
    }
    // Moved out: the new owner drops it, once.
    {
        let b: Box[dyn Named] = Box.new(Tok { n: 4 })
        let c = b
        note(f"name{c.name()}")
    }
    // Reassigned: the old value drops at the assignment.
    {
        var b: Box[dyn Named] = Box.new(Tok { n: 5 })
        b = Box.new(Tok { n: 6 })
        note(f"name{b.name()}")
    }
    // In a Vec: the Vec's drop drops each box.
    {
        var v: Vec[Box[dyn Named]] = Vec.new()
        v.push(Box.new(Tok { n: 7 }))
        v.push(Box.new(Label { text: "x" ++ "y" }))
        note(f"len{v.len()}")
    }
    // In a struct field.
    {
        let h = Holder { b: Box.new(Tok { n: 8 }) }
        note(f"name{h.b.name()}")
    }
    // Returned from a function.
    {
        let b = make(9)
        note(f"name{b.name()}")
    }
    // Consumed through the vtable: the callee owns and drops it.
    {
        let b: Box[dyn Named] = Box.new(Tok { n: 10 })
        let t = b.take()
        note(f"take{t}")
    }
    note("end")
    print("trace:" ++ TRACE)
