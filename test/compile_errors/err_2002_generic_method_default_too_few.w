//! expect-error: method 'Bx.scaled' expects 1-2 argument(s), found 0

// #2002: below the required count a generic type's method is refused with
// the range its defaults allow, as a non-generic method's is.
type Bx[T] { v: T }
impl[T] Bx[T]:
    fn scaled(by: i32, plus: i32 = 2) -> i32: by * 5 + plus
fn main:
    let b = Bx { v: 1 }
    print(b.scaled())
