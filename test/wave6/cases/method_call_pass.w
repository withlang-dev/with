// Wave 6 unit test: method call resolution
// Covers: struct methods, inherent impl, method chaining

type Counter = {
    value: i32,
}

fn Counter.new -> Counter:
    Counter { value: 0 }

fn Counter.increment(self: Counter) -> Counter:
    Counter { value: self.value + 1 }

fn Counter.get(self: Counter) -> i32:
    self.value

fn main -> i32:
    let c = Counter.new()
    let c2 = c.increment()
    let c3 = c2.increment()
    c3.get()
