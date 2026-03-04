// Wave 10: deterministic dyn vtable slot ordering.

trait Duo =
    fn first(self: Self) -> i32
    fn second(self: Self) -> i32

type Num = {
    n: i32,
}

impl Duo for Num =
    fn first(self: Num) -> i32:
        self.n + 1

    fn second(self: Num) -> i32:
        self.n + 2

fn call_first(v: dyn Duo) -> i32:
    v.first()

fn call_second(v: dyn Duo) -> i32:
    v.second()

fn main -> i32:
    let x = Num { n: 3 }
    assert(call_first(x) == 4)
    assert(call_second(x) == 5)
    0
