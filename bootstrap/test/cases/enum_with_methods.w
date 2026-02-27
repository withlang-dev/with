// Test enum with methods via extend block
type Light = Red | Yellow | Green

extend Light =
    fn next(self: Light) -> Light:
        match self
            Red -> Green
            Yellow -> Red
            Green -> Yellow

    fn is_stop(self: Light) -> bool:
        match self
            Red -> true
            Yellow -> true
            Green -> false

fn main -> i32:
    let l = Red
    let l2 = l.next()
    let l3 = l2.next()
    println(l.is_stop())
    println(l2.is_stop())
    assert(not l2.is_stop())
