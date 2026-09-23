//! expect-stdout: = 9 9
//! expect-stdout: += 10 10
//! expect-stdout: -= 8 8
//! expect-stdout: *= 24 24
//! expect-stdout: /= 12 12
//! expect-stdout: %= 2 2
//! expect-stdout: &= 2 2
//! expect-stdout: |= 10 10
//! expect-stdout: ^= 9 9
//! expect-stdout: <<= 36 36
//! expect-stdout: >>= 18 18
//! expect-stdout: +%= 19 19
//! expect-stdout: -%= 18 18
//! expect-stdout: *%= 36 36
//! expect-stdout: +|= 37 37
//! expect-stdout: -|= 36 36
//! expect-stdout: *|= 72 72
//! expect-stdout: max+%= -2147483648
//! expect-stdout: max+|= 2147483647

// §9.1 / D60: an assignment `place = value` is an expression whose type is
// the type of `place`; as the tail of a body whose declared return type is
// not `Unit`, the body yields a read of `place` after the store. Every
// assignment operator returns the stored value — #1319 returned
// `i32.default()` (0) for each, with no diagnostic.

var g: i32 = 0

fn op_eq -> i32: g = 9
fn op_add -> i32: g += 1
fn op_sub -> i32: g -= 2
fn op_mul -> i32: g *= 3
fn op_div -> i32: g /= 2
fn op_mod -> i32: g %= 5
fn op_and -> i32: g &= 6
fn op_or -> i32: g |= 8
fn op_xor -> i32: g ^= 3
fn op_shl -> i32: g <<= 2
fn op_shr -> i32: g >>= 1
fn op_addw -> i32: g +%= 1
fn op_subw -> i32: g -%= 1
fn op_mulw -> i32: g *%= 2
fn op_adds -> i32: g +|= 1
fn op_subs -> i32: g -|= 1
fn op_muls -> i32: g *|= 2

// The read is of the stored place, so wrapping and saturating ops return
// what the place holds, not an unbounded result.
fn wrap_max -> i32:
    var n: i32 = 2147483647
    n +%= 1
fn sat_max -> i32:
    var n: i32 = 2147483647
    n +|= 1

fn main:
    g = 5
    print(f"= {op_eq()} {g}")
    print(f"+= {op_add()} {g}")
    print(f"-= {op_sub()} {g}")
    print(f"*= {op_mul()} {g}")
    print(f"/= {op_div()} {g}")
    print(f"%= {op_mod()} {g}")
    print(f"&= {op_and()} {g}")
    print(f"|= {op_or()} {g}")
    print(f"^= {op_xor()} {g}")
    print(f"<<= {op_shl()} {g}")
    print(f">>= {op_shr()} {g}")
    print(f"+%= {op_addw()} {g}")
    print(f"-%= {op_subw()} {g}")
    print(f"*%= {op_mulw()} {g}")
    print(f"+|= {op_adds()} {g}")
    print(f"-|= {op_subs()} {g}")
    print(f"*|= {op_muls()} {g}")
    print(f"max+%= {wrap_max()}")
    print(f"max+|= {sat_max()}")
