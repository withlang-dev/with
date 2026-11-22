//! expect-error: method 'Ev.peek' expects 2 argument(s), found 3

// #1973 (§3.8): too many arguments to a method on a value is refused at the
// call, with the counts, receiver excluded.
type Ev { n: i32 }

impl Ev:
    fn peek(a: i32, b: i64) -> i64: a as i64 + b + self.n as i64

fn main:
    let e = Ev { n: 0 }
    print(e.peek(3, 4, 5))
