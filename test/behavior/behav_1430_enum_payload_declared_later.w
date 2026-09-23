//! expect-stdout: enum A 7
//! expect-stdout: enum B 33 4444444444444
//! expect-stdout: struct x=1111111111111 y=2222222222222 k=3333333333333
//! expect-stdout: tuple x=1111111111111 y=2222222222222 e=B 5 6666666666666 z=5555555555555
//! expect-stdout: option-struct x=1111111111111 y=2222222222222
//! expect-stdout: option-enum B 7 3333333333333
//! expect-stdout: option-none
//! expect-stdout: result-ok x=1111111111111 y=2222222222222
//! expect-stdout: result-err B 5 3333333333333
//! expect-stdout: vec x=1111111111111 y=2222222222222
//! expect-stdout: vec x=3 y=4444444444444
//! expect-stdout: generic-enum x=4 y=5555555555555 k=6666666666666
//! expect-stdout: generic-struct x=1111111111111 y=2222222222222 b=3333333333333 tail=4444444444444
//! expect-stdout: alias x=1111111111111 y=2222222222222 k=3333333333333
//! expect-stdout: nested p=1111111111111 q=2222222222222 r=33 m=4444444444444 tail=5555555555555
//! expect-stdout: ok

// #1430: an enum whose payload type is declared after it is laid out exactly
// as if the payload type came first. Codegen defined bodies in declaration
// order and sized each payload with LLVM's DataLayout, which sized a
// still-bodiless placeholder as 0: `Outer.Inner(InnerE.A(7))` read back 0, a
// later struct payload aborted in SROA, and every payload field past the
// truncation read garbage. Each shape below holds a later-declared type by
// value and prints every field; the i64 values are wider than any truncated
// payload could hold. Nested, the three enums are declared in reverse order.
// The generic templates come first only because Sema does not yet resolve a
// generic declared after its user (a separate issue); their instantiations
// still take the later-declared Inner.

enum Gen[T]:
    Of(t: T)
    Nothing

type Pair[T] { a: T, b: i64 }

enum Outer:
    E(e: InnerE)
    S(s: Inner, k: i64)
    T(t: (Inner, InnerE, i64))
    OS(o: Option[Inner])
    OE(o: Option[InnerE])
    R(r: Result[Inner, InnerE])
    V(v: Vec[Inner])
    GE(g: Gen[Inner], k: i64)
    GS(p: Pair[Inner], tail: i64)
    AL(i: LaterAlias, k: i64)

fn show_inner_e(tag: str, e: &InnerE):
    match e:
        InnerE.A(n) => print(f"{tag} A {n}")
        InnerE.B(a, b) => print(f"{tag} B {a} {b}")

fn show(o: Outer):
    match o:
        Outer.E(e) => show_inner_e("enum", &e)
        Outer.S(s, k) => print(f"struct x={s.x} y={s.y} k={k}")
        Outer.T(t) =>
            let (s, e, z) = t
            match e:
                InnerE.B(a, b) => print(f"tuple x={s.x} y={s.y} e=B {a} {b} z={z}")
                InnerE.A(n) => print(f"tuple x={s.x} y={s.y} e=A {n} z={z}")
        Outer.OS(Some(v)) => print(f"option-struct x={v.x} y={v.y}")
        Outer.OS(None) => print("option-none")
        Outer.OE(Some(e)) => show_inner_e("option-enum", &e)
        Outer.OE(None) => print("option-none")
        Outer.R(Ok(v)) => print(f"result-ok x={v.x} y={v.y}")
        Outer.R(Err(e)) => show_inner_e("result-err", &e)
        Outer.V(v) =>
            for item in v:
                print(f"vec x={item.x} y={item.y}")
        Outer.GE(Gen.Of(t), k) => print(f"generic-enum x={t.x} y={t.y} k={k}")
        Outer.GE(Gen.Nothing, k) => print(f"generic-enum nothing k={k}")
        Outer.GS(p, tail) => print(f"generic-struct x={p.a.x} y={p.a.y} b={p.b} tail={tail}")
        Outer.AL(v, k) => print(f"alias x={v.x} y={v.y} k={k}")

fn main:
    show(Outer.E(InnerE.A(7)))
    show(Outer.E(InnerE.B(33, 4444444444444)))
    show(Outer.S(Inner { x: 1111111111111, y: 2222222222222 }, 3333333333333))
    show(Outer.T((Inner { x: 1111111111111, y: 2222222222222 }, InnerE.B(5, 6666666666666), 5555555555555)))
    show(Outer.OS(Some(Inner { x: 1111111111111, y: 2222222222222 })))
    show(Outer.OE(Some(InnerE.B(7, 3333333333333))))
    show(Outer.OS(None))
    show(Outer.R(Ok(Inner { x: 1111111111111, y: 2222222222222 })))
    show(Outer.R(Err(InnerE.B(5, 3333333333333))))
    var xs: Vec[Inner] = Vec.new()
    xs.push(Inner { x: 1111111111111, y: 2222222222222 })
    xs.push(Inner { x: 3, y: 4444444444444 })
    show(Outer.V(xs))
    show(Outer.GE(Gen.Of(Inner { x: 4, y: 5555555555555 }), 6666666666666))
    show(Outer.GS(Pair { a: Inner { x: 1111111111111, y: 2222222222222 }, b: 3333333333333 }, 4444444444444))
    show(Outer.AL(Inner { x: 1111111111111, y: 2222222222222 }, 3333333333333))
    match Top.X(Mid.Y(Leaf { p: 1111111111111, q: 2222222222222, r: 33 }, 4444444444444), 5555555555555):
        Top.X(Mid.Y(c, m), tail) => print(f"nested p={c.p} q={c.q} r={c.r} m={m} tail={tail}")
        Top.X(Mid.Z, tail) => print(f"nested Z tail={tail}")
        Top.Nil => print("nested nil")
    print("ok")

enum Top:
    X(b: Mid, tail: i64)
    Nil

enum Mid:
    Y(c: Leaf, m: i64)
    Z

type Leaf { p: i64, q: i64, r: i32 }

type LaterAlias = Inner

type Inner { x: i64, y: i64 }

enum InnerE:
    A(n: i32)
    B(a: i32, b: i64)
