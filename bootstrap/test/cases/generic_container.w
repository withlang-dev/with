// Test container pattern with methods
type Box = { value: i32 }

impl Box =
    fn new(v: i32) -> Box: Box { value: v }
    fn get(self: Box) -> i32: self.value
    fn double(self: Box) -> Box:
        Box { value: self.value * 2 }
    fn inc(self: Box) -> Box:
        Box { value: self.value + 1 }

fn main -> i32:
    let b = Box.new(5)
    let b2 = b.double()
    let b3 = b2.inc()
    println(b.get())
    println(b2.get())
    println(b3.get())
