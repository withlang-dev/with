// Test &mut Self in trait methods - mutable reference
type Counter = { count: i32 }

trait Incrementable =
    fn increment(self: &mut Self) -> i32

impl Incrementable for Counter =
    fn increment(self: &mut Counter) -> i32:
        self.count = self.count + 1
        self.count

fn main -> i32:
    var c = Counter { count: 0 }
    let a = c.increment()
    let b = c.increment()
    println(a)
    println(b)
    println(c.count)
