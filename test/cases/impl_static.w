type Counter = { value: i32 }

impl Counter =
    fn new -> Counter: Counter { value: 0 }
    fn with_value(v: i32) -> Counter: Counter { value: v }
    fn get(self: &Counter) -> i32: self.value

fn main -> i32:
    let c = Counter.new()
    println(c.get())
    let c2 = Counter.with_value(42)
    println(c2.get())
