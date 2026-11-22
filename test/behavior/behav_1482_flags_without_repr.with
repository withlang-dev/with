//! expect-stdout: 1 2 4
//! expect-stdout: 1 2 4 8
//! expect-stdout: 1 2 4
//! expect-stdout: 3
//! expect-stdout: 1 16 32
//! expect-stdout: ok

// D71 / §4.4a (#1482): "An `@[flags]` enum with no representation type
// doubles the same way in its default integer representation; the attribute
// is never ignored." The parser set the flags bit only beside an explicit
// `: i32`, so these printed 0 1 2 / 0 1 2 3, and the payload enum's
// discriminants were its variant indexes 0 1 2.

@[flags]
enum G:
    X
    Y
    Z

@[flags]
enum Braced { A, B, C, D }

// With a payload variant it is a discriminant enum in the inferred i32, as
// `enum Ev: i32:` would be (§4.4a "Discriminant enums with payloads").
@[flags]
enum Ev:
    Start
    Data(i32)
    Stop

@[flags]
enum Mixed:
    Low
    High = 16
    Next

fn ev_bits(e: Ev) -> i32: e as i32

fn main:
    print(f"{G.X as i32} {G.Y as i32} {G.Z as i32}")
    print(f"{Braced.A as i32} {Braced.B as i32} {Braced.C as i32} {Braced.D as i32}")
    print(f"{ev_bits(Ev.Start)} {ev_bits(Ev.Data(9))} {ev_bits(Ev.Stop)}")
    print((G.X as i32) | (G.Y as i32))
    print(f"{Mixed.Low as i32} {Mixed.High as i32} {Mixed.Next as i32}")
    match Ev.Data(7):
        Ev.Data(v) => assert(v == 7)
        _ => assert(false)
    match G.from_int(4):
        Some(g) => assert(g as i32 == 4)
        None => assert(false)
    match G.from_int(3):
        Some(_) => assert(false)
        None => print("ok")
