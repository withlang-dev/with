//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// §2.5.1, §3.8, #1719: `s as []u8` is a byte view of `s`; it moves nothing.
// MIR lowered the cast's source as an OK_MOVE, so the second cast of the
// same str was "a move of _1, which a path reaching it already moved out
// (Moved) ... two owners free one value" while codegen dropped the str
// once (debug-alloc: leak count=0). Locals, parameters and fields alike.

type Doc { body: str, n: i32 }

fn both(s: str) -> i64:
    let a = s as []u8
    let b = s as []u8
    a.len() + b.len()

fn main:
    let input = "abc".clone()
    let a = input as []u8
    let b = input as []u8
    let d = Doc { body: "hello".clone(), n: 1 }
    let c = d.body as []u8
    let e = d.body as []u8
    print(a.len() + b.len() + c.len() + e.len() + both("xy".clone()))
