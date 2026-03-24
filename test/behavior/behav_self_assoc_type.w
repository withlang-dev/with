//! expect-stdout: ok
trait Transform =
    type Output
    fn apply(self: Self, x: i32) -> Self.Output

type Doubler {}
impl Transform for Doubler =
    type Output = i32
    fn apply(self: Doubler, x: i32) -> Self.Output: x * 2

type Stringer {}
impl Transform for Stringer =
    type Output = str
    fn apply(self: Stringer, x: i32) -> Self.Output: "done"

fn main:
    let d = Doubler{}
    let result = d.apply(21)
    assert(result == 42)
    print("ok")
