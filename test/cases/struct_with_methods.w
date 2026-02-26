// Test struct with impl block methods
type Counter = { count: i32 }

impl Counter =
    fn new() -> Counter = Counter { count: 0 }
    fn value(self: Counter) -> i32 = self.count
    fn increment(self: Counter) -> Counter = Counter { count: self.count + 1 }

fn main() -> i32 =
    let c0 = Counter.new()
    let c1 = c0.increment()
    let c2 = c1.increment()
    let c3 = c2.increment()
    println(c0.value())
    println(c3.value())
    0
