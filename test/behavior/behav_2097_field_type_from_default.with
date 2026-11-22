//! expect-stdout: 0 2.5 true ship 480 5000000000 7
//! expect-stdout: 9 b
//! expect-stdout: 20 12.5 3
//! expect-stdout: 4 8 4
//! expect-stdout: ok

// D89 (§4.3, #2097): a field with a default may omit its type; the field
// then has the type of its default. When the default is an unsuffixed
// numeric constant expression, the field's numeric type is what its uses in
// the module demand, and the default (`i32`, `f64`) when none demands
// anything.

type V2 { x: f32 = 0.0, y: f32 = 0.0 }

// No use demands anything of these: the defaults' own types.
type Plain { ticks = 0, rate = 2.5, alive = true, name = "ship", pos = V2 { x: 480.0, y: 300.0 }, big = 5000000000, small = 7u8 }

type Block:
    count = 3
    label = "b"

// Every use of `radius` and `speed` is f32, and of `hits` u8: so are they.
type Ship { radius = 10.0, speed = 2.5, hits = 3, pos = V2 {} }

fn scale(r: f32, by: f32) -> f32: r * by

fn bump(n: u8) -> u8: n

fn area(s: &Ship, dt: f32) -> f32:
    s.pos.x + s.speed * dt

fn main:
    let p = Plain {}
    print(f"{p.ticks} {p.rate} {p.alive} {p.name} {p.pos.x} {p.big} {p.small}")
    let b = Block { count: 9 }
    print(f"{b.count} {b.label}")
    let s = Ship {}
    print(f"{scale(s.radius, 2.0)} {area(s, 5.0)} {bump(s.hits)}")
    // The fields have the sizes of the types decided.
    print(f"{size_of[f32]()} {size_of[f64]()} {size_of[Ship]() - size_of[V2]() - 4 - 1 - 3}")
    print("ok")
