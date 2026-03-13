//! expect-stdout: ok
trait Mapper =
    type Input = i32
    type Output = i32
    fn map(self: Self, x: Self.Input) -> Self.Output

type Tripler = {}
impl Mapper for Tripler =
    type Input = i32
    type Output = i32
    fn map(self: Tripler, x: i32) -> i32: x * 3

fn main:
    let t = Tripler{}
    let result = t.map(7)
    assert(result == 21)
    print("ok")
