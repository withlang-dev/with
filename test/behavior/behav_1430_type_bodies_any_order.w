//! expect-stdout: struct-option B 7 1111111111111
//! expect-stdout: struct-result x=2222222222222 y=3333333333333
//! expect-stdout: struct-tail 4444444444444
//! expect-stdout: disc-payload move x=1111111111111 y=2222222222222
//! expect-stdout: disc-payload tag B 9 3333333333333
//! expect-stdout: disc-payload quit
//! expect-stdout: disc-field blue 1111111111111
//! expect-stdout: disc-in-enum red 2222222222222
//! expect-stdout: bitpacked-in-enum 2 1 1111111111111
//! expect-stdout: bitpacked-nested 15 2 1
//! expect-stdout: ok

// #1430: a type referenced before its declaration gets the same body as if it
// came first, for every kind whose body or representation codegen settled in
// declaration order: a struct holding a later enum through Option/Result (an
// instantiation sized at the struct's declaration), a discriminant enum whose
// payloads are declared later, a payload-less discriminant enum (represented
// by its repr integer — seen before its declaration it was a bodiless struct,
// and the program failed LLVM verification), and a bitpacked struct (its
// backing integer). Every field is printed.

type Holder { o: Option[InnerE], r: Result[Inner, str], tail: i64 }

enum Msg: i32:
    Quit = 0
    Move(p: Inner) = 1
    Tag(e: InnerE) = 2

type Rec { k: Kind, n: i64 }

enum KindBox:
    K(k: Kind, m: i64)
    None1

enum FlagBox:
    F(f: Flags, m: i64)
    None1

@[bitpacked] type Wrap { hi: u4, inner: Flags }

fn kname(k: Kind) -> str:
    match k:
        .Red => "red"
        .Blue => "blue"

fn show_msg(m: Msg):
    match m:
        .Quit => print("disc-payload quit")
        .Move(p) => print(f"disc-payload move x={p.x} y={p.y}")
        .Tag(InnerE.B(a, b)) => print(f"disc-payload tag B {a} {b}")
        .Tag(InnerE.A(n)) => print(f"disc-payload tag A {n}")

fn main:
    var h = Holder { o: Some(InnerE.B(7, 1111111111111)), r: Ok(Inner { x: 2222222222222, y: 3333333333333 }), tail: 4444444444444 }
    match h.o:
        Some(InnerE.B(a, c)) => print(f"struct-option B {a} {c}")
        Some(InnerE.A(n)) => print(f"struct-option A {n}")
        None => print("struct-option none")
    match move h.r:
        Ok(v) => print(f"struct-result x={v.x} y={v.y}")
        Err(s) => print(f"struct-result err {s}")
    print(f"struct-tail {h.tail}")
    show_msg(Msg.Move(Inner { x: 1111111111111, y: 2222222222222 }))
    show_msg(Msg.Tag(InnerE.B(9, 3333333333333)))
    show_msg(Msg.Quit)
    let r = Rec { k: Kind.Blue, n: 1111111111111 }
    print(f"disc-field {kname(r.k)} {r.n}")
    match KindBox.K(Kind.Red, 2222222222222):
        KindBox.K(k, m) => print(f"disc-in-enum {kname(k)} {m}")
        KindBox.None1 => print("disc-in-enum none")
    match FlagBox.F(Flags { a: 2, b: 1 }, 1111111111111):
        FlagBox.F(f, m) => print(f"bitpacked-in-enum {f.a as i32} {f.b as i32} {m}")
        FlagBox.None1 => print("bitpacked-in-enum none")
    let w = Wrap { hi: 0xF, inner: Flags { a: 2, b: 1 } }
    print(f"bitpacked-nested {w.hi as i32} {w.inner.a as i32} {w.inner.b as i32}")
    print("ok")

@[bitpacked] type Flags { a: u2, b: u2 }

enum Kind: i32:
    Red = 1
    Blue = 2

type Inner { x: i64, y: i64 }

enum InnerE:
    A(n: i32)
    B(a: i32, b: i64)
