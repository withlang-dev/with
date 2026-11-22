//! expect-error: method 'Ev.make' expects 2 argument(s), found 1

// #1973 (§3.8): a method call is checked against its declaration's
// parameter list, receiver excluded, as a free call is. `self.make(3)`
// passed `with check` and failed LLVM verification at build.
type Ev { n: i32 }

impl Ev:
    mut fn make(a: i32, b: i64) -> i32: a + b as i32
    mut fn run() -> i32: self.make(3)

fn main:
    var e = Ev { n: 0 }
    print(e.run())
