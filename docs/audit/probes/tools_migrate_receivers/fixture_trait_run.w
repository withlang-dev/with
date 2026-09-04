type Pair {
    a: i64,
    b: i64,
}

trait Summable:
    fn total(self: &Self) -> i64

impl Summable for Pair:
    fn total() -> i64: self.a + self.b

fn Pair.zero() -> Pair: Pair { a: 0, b: 0 }

fn main:
    let p = Pair { a: 1, b: 2 }
    print(f"{p.total()}")
