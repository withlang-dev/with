//! expect-stdout: 2
//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: 7
//! expect-stdout: 8
//! expect-stdout: 1

// #1770 (§4.4a): `value as i32` on an enum with a payload variant extracts
// the discriminant. MirLower emitted an RK_CAST from the enum aggregate to
// i32, which codegen has no arm for: the f-string printed the variant and
// the addition was invalid LLVM. The cast is lowered as the discriminant
// read (RK_DISCRIMINANT) and a cast from the tag's type.

enum R:
    A
    B(i32)
    C

enum Q: i64:
    X = 7
    Y(i32) = 8

fn ra(r: R) -> i32: r as i32

fn main:
    print(f"{R.C as i32}")
    let a = R.C as i32
    print(a + 1)
    print(ra(R.C))
    print(Q.X as i64)
    print(Q.Y(3) as i32)
    print(R.B(9) as u8)
