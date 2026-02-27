type Counter = {
    value: i32,
}

fn Counter.get(self: Counter) -> i32: self.value

fn Counter.add(self: Counter, n: i32) -> i32: self.value + n

fn main -> i32:
    let c = Counter { value: 10 }
    assert(c.get() + c.add(12) + 10 == 42)
