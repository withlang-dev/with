//! expect-stdout: 2 5 12 30
//! expect-stdout: 7 9
// #2002: a defaulted parameter of a method of a generic type is filled
// when the call omits it, as a free function's (generic_default_args.w)
// and a non-generic type's method's are. `b.get()` was refused ("wrong
// argument count", then "expects 1 argument(s), found 0").
type Bx[T] { v: T }

impl[T] Bx[T]:
    fn get(k: i32 = 2) -> i32: k
    fn scaled(by: i32, plus: i32 = 2) -> i32: by * 5 + plus

type Plain { n: i32 }

impl Plain:
    fn pick[U](x: U, k: i32 = 7) -> i32: k

fn main:
    let b = Bx { v: 1 }
    print(f"{b.get()} {b.get(5)} {b.scaled(2)} {b.scaled(5, 5)}")
    let p = Plain { n: 0 }
    print(f"{p.pick("a")} {p.pick(1, 9)}")
