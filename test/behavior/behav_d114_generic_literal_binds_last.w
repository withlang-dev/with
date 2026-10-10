//! expect-stdout: 2147483648 5 0 200 u8

// §4.2.1 (D114): an untyped literal argument binds a type parameter only
// where nothing else does. A typed argument, in any position, and the
// call's demand come first; the isize default is the last resort.
fn apply[T, U](x: T, f: fn(T) -> U) -> U: f(x)
fn paired[T, U](first: T) -> (T, List[U]): (first, List.new())
fn pick[T](a: T, b: T) -> T: if a > b: a else: b
fn name_of_u8(x: u8) -> str: "u8"

fn main:
    let wide = apply(2147483647, (x: i32) -> i64 => x) + 1
    let (first, rest): (i32, List[str]) = paired(5)
    let small: u8 = 200
    let top = pick(1, small)
    print(f"{wide} {first} {rest.len()} {top} {name_of_u8(top)}")
