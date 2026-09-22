//! expect-check-fail: expected ':' or '{' after the impl header

// #1346 (§29.13): after an impl header comes ':', '{', or the end of the line
// (a bodyless impl, §2.3). A member on the header line with no introducer is
// a parse error, not a member.

type X { v: i32 }

impl X fn a(): 1

fn main:
    let x = X { v: 0 }
    print(f"{x.a()}")
