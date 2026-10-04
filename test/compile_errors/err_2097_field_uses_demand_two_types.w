//! expect-error: the uses of this field demand both `f32` and `f64`; write its type

// D89 (§4.3): a field's unsuffixed numeric default takes the type its uses
// in the module demand. Uses that demand two different types are an error
// that asks for the type to be written.

type Ship { speed = 2.5 }

fn narrow(x: f32) -> f32: x
fn wide(x: f64) -> f64: x

fn main:
    let s = Ship {}
    print(f"{narrow(s.speed)} {wide(s.speed)}")
