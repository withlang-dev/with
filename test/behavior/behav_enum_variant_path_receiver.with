//! expect-stdout: ok

// #1310: a method call on a bare `Type.Variant` path receiver. `S.A` is a
// variant value, not the field `A` of a place named `S`: as a receiver it
// lowers exactly as `let x = S.A; x.tag()` does (§9.7 / §11). The old
// place lowering projected a field off the type name and failed MIR
// lowering for the whole function.

enum S { A | B(i32) }

impl S:
    fn tag(self: &Self) -> i32:
        match self:
            .A => 1
            .B(n) => n
    fn name(self: &Self) -> str:
        match self:
            .A => "A"
            .B(_) => "B"

enum Plain { X | Y }

impl Plain:
    fn code(self: &Self) -> i32:
        match self:
            .X => 10
            .Y => 20

fn main:
    let x = S.A
    assert(x.tag() == S.A.tag())
    assert(S.A.tag() == 1)
    assert(S.B(7).tag() == 7)
    assert(S.A.name() == "A")
    assert(S.B(1).name() == "B")
    assert(f"{S.A.tag()}{S.B(2).tag()}" == "12")
    assert(Plain.X.code() == 10)
    assert(Plain.Y.code() == 20)
    print("ok")
