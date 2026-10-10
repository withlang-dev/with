//! expect-stdout: 0 7 -1 2

// D114 (§4.2.1): an untyped literal `return` value takes the type of the
// function's typed returns or typed tail, as a literal arm of an `if` does;
// it does not make the inferred return type the isize default. (A view
// return beside a literal one is #2325.)
fn take(x: i32): x

fn first_or_zero(c: bool, v: i32):
    if c: return 0
    v

fn clamp_negative(v: i32):
    if v < 0: return -1
    return v

fn literal_only(c: bool):
    if c: return 1
    2

fn main:
    let wide: isize = literal_only(false)
    print(f"{take(first_or_zero(true, 5))} {take(clamp_negative(7))} {take(clamp_negative(-9))} {wide}")
