//! check-only
//! args: --no-std
// §18.7: core language works under --no-std — tuples, ranges, bitwise and
// arithmetic operators, traits, derive. (No std helpers: operators only.)
@[panic_handler]
fn on_panic -> Never:
    unreachable()

trait Area:
    fn area(self: &Self) -> i32

@[derive(Eq)]
type P { x: i32, y: i32 }

impl Area for P:
    fn area(self: &Self) -> i32:
        self.x * self.y

@[entry]
fn start -> i32:
    let t: (i32, i32, i32) = (1, 2, 3)
    var acc = t.0 + t.1 * t.2
    for i in 0..3:
        acc = acc + i
    let bits = (0xF0 & 0x0F) | (1 << 3) ^ 0b10
    acc = acc + bits - (~0 + 1)
    let p = P { x: 4, y: 5 }
    let q = P { x: 4, y: 5 }
    if p == q:
        acc = acc + p.area()
    acc % 100
