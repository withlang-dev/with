// Test methods on enum types via impl blocks
type Color = Red | Green | Blue

impl Color =
    fn is_warm(self: Color) -> bool:
        match self
            Red -> true
            _ -> false

    fn to_int(self: Color) -> i32:
        match self
            Red -> 0
            Green -> 1
            Blue -> 2

fn main -> i32:
    let r = Red
    let g = Green
    let b = Blue
    println(r.to_int())
    println(g.to_int())
    println(b.to_int())
    assert(r.is_warm())
    assert(not g.is_warm())
