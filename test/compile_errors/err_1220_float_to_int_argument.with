//! expect-check-fail: wrong argument type in call to 'circle'

// #1220 (§4): a float where an integer is demanded is a narrowing spelled
// with `as`; builtin_arg_type_compatible accepted it through the operator
// promotion arm and codegen failed with no location.

fn circle(x: i32, y: i32, r: f32) -> f32: r + (x + y) as f32

fn main:
    let x = 12.7
    print(f"{circle(x, x, 1.0)}")
