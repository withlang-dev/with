// Test: generic struct with methods
type Pair = {
    first: i32,
    second: i32
}

impl Pair =
    fn sum(self: Pair) -> i32 =
        self.first + self.second

    fn max(self: Pair) -> i32 =
        if self.first > self.second then self.first
        else self.second

    fn min(self: Pair) -> i32 =
        if self.first < self.second then self.first
        else self.second

fn main() -> i32 =
    let p = Pair { first: 20, second: 22 }
    assert(p.sum() == 42)
    assert(p.max() == 22)
    assert(p.min() == 20)

    let q = Pair { first: 42, second: 1 }
    assert(q.max() == 42)
    assert(q.min() == 1)
    0
