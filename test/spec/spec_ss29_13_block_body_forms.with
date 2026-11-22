//! expect-stdout: ok x=1 y=2 ft=42 s=12
// §29.13 Block Body Syntax:
//  29.13.1.20 — an empty braced body `{}` is legal and returns Unit (on fns
//    and on for/if/else constructs); whitespace inside braces is insignificant
//    and statements may be separated by semicolons.
//  29.13.1.24 — colon-then-brace `fn f: { expr }` parses `{ expr }` as an
//    inline body *expression* (here a literal and a named struct literal).

type P { x: i32, y: i32 }

fn nothing() {}
fn nothing2() {
}
fn sum3(a: i32, b: i32, c: i32) -> i32 { let t = a + b; t + c }
fn forty_two() -> i32: { 42 }
fn make() -> P: P { x: 1, y: 2 }

fn main:
    nothing()
    nothing2()
    for x in 0..0 {}
    if true {}
    if false {} else {}
    let p = make()
    print(f"ok x={p.x} y={p.y} ft={forty_two()} s={sum3(3, 4, 5)}")
