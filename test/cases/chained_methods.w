// Test chained method calls on structs
type Counter = {
    value: i32 = 0,
}

fn Counter.increment(self: Counter) -> Counter:
    Counter { value: self.value + 1 }

fn Counter.add(self: Counter, n: i32) -> Counter:
    Counter { value: self.value + n }

fn Counter.get(self: Counter) -> i32: self.value

fn main -> i32:
    let c = Counter {}
    // Chain method calls
    let c2 = Counter.increment(c)
    let c3 = Counter.add(c2, 10)
    let result = Counter.get(c3)
    println(result)
