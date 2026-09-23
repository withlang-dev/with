//! expect-stdout: root S x=1111111111111 y=2222222222222 k=3333333333333
//! expect-stdout: root E B 4 5555555555555
//! expect-stdout: module has p=6666666666666 q=7777777777777 k=8888888888888
//! expect-stdout: module tagged B 9 1234567890123
//! expect-stdout: ok

// #1430 across modules: a root enum whose payload types come from an imported
// module (whose declarations codegen reaches after the root's), and a module
// enum declared above the module types it carries. Every field is printed.

use layout_order_1430

enum Outer:
    S(s: ModInner, k: i64)
    E(e: ModE)

fn show(o: Outer):
    match o:
        Outer.S(s, k) => print(f"root S x={s.x} y={s.y} k={k}")
        Outer.E(ModE.B(a, b)) => print(f"root E B {a} {b}")
        Outer.E(ModE.A(n)) => print(f"root E A {n}")

fn show_mod(o: ModOuter):
    match o:
        ModOuter.Has(l, k) => print(f"module has p={l.p} q={l.q} k={k}")
        ModOuter.Tagged(ModE.B(a, b)) => print(f"module tagged B {a} {b}")
        ModOuter.Tagged(ModE.A(n)) => print(f"module tagged A {n}")
        ModOuter.None1 => print("module none")

fn main:
    show(Outer.S(ModInner { x: 1111111111111, y: 2222222222222 }, 3333333333333))
    show(Outer.E(ModE.B(4, 5555555555555)))
    show_mod(ModOuter.Has(ModLater { p: 6666666666666, q: 7777777777777 }, 8888888888888))
    show_mod(ModOuter.Tagged(ModE.B(9, 1234567890123)))
    print("ok")
