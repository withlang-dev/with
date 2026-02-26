// Test where clause syntax for trait bounds
trait Numeric =
    fn value(self: Self) -> i32

type Meters = { v: i32 }
type Seconds = { v: i32 }

impl Numeric for Meters =
    fn value(self: Meters) -> i32 =
        self.v

impl Numeric for Seconds =
    fn value(self: Seconds) -> i32 =
        self.v

fn add_values[A, B](a: A, b: B) -> i32 where A: Numeric, B: Numeric =
    a.value() + b.value()

fn main() -> i32 =
    let m = Meters { v: 10 }
    let s = Seconds { v: 5 }
    println(add_values(m, s))
    0
