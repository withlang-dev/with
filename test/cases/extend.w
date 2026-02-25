type Counter = {
    value: i32
}

extend Counter =
    fn new(v: i32) -> Counter =
        Counter { value: v }

    fn get(self: Counter) -> i32 =
        self.value

    fn add(self: Counter, n: i32) -> Counter =
        Counter { value: self.value + n }

fn main() -> i32 =
    let c = Counter.new(10)
    let c2 = c.add(32)
    assert(c2.get() == 42)
    0
