//! expect-error: integer literal does not fit expected type

// #1856 (§4.2.1): a soft literal is range-checked at the type the settling
// use gives it; 300 does not fit `u8`, reported at the literal.

fn small(r: Result[u8, str]): print(f"{r:?}")

fn main:
    let a = Ok(300)
    small(a)
