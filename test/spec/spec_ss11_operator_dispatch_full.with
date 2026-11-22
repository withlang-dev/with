//! expect-stdout: ok
// §11: user operator methods dispatch for mul/div and the comparison family.
type Num { v: i32 }
impl Num:
    fn mul(self: &Self, o: &Num) -> Num: Num { v: self.v * o.v }
    fn div(self: &Self, o: &Num) -> Num: Num { v: self.v / o.v }
    fn ne(self: &Self, o: &Num) -> bool: self.v != o.v
    fn lt(self: &Self, o: &Num) -> bool: self.v < o.v
    fn le(self: &Self, o: &Num) -> bool: self.v <= o.v
    fn gt(self: &Self, o: &Num) -> bool: self.v > o.v
    fn ge(self: &Self, o: &Num) -> bool: self.v >= o.v
fn main:
    let a = Num { v: 6 }
    let b = Num { v: 3 }
    assert((a * b).v == 18)
    assert((a / b).v == 2)
    assert(a != b)
    assert(b < a)
    assert(b <= a)
    assert(a > b)
    assert(a >= b)
    print("ok")
