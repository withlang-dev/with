//! expect-stdout: 2147483648 200 u8

// §4.2.1 (D114): an untyped literal argument binds a type parameter only
// where no typed argument does, in any position; the isize default is the
// last resort. Every argument is an operand, so all of them bind before the
// call's demand (law 2).
fn apply[T, U](x: T, f: fn(T) -> U) -> U: f(x)
fn pick[T](a: T, b: T) -> T: if a > b: a else: b
fn name_of_u8(x: u8) -> str: "u8"

fn main:
    let wide = apply(2147483647, (x: i32) -> i64 => x) + 1
    let small: u8 = 200
    let top = pick(1, small)
    print(f"{wide} {top} {name_of_u8(top)}")
