//! expect-error: method 'Ev.scale' expects 1-2 argument(s), found 0

// #1973: a method's defaulted parameters widen the accepted count, as a
// free function's do; below the required count the call is refused.
type Ev { n: i32 }

impl Ev:
    fn scale(a: i32, b: i32 = 2) -> i32: self.n * a * b

fn main:
    let e = Ev { n: 3 }
    print(e.scale(1))
    print(e.scale())
