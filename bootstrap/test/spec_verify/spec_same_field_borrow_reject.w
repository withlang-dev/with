// NEGATIVE: shared + mutable borrow of same field should be rejected (§3.2)
// EXPECT: check fails with borrow overlap error
type Point = { x: i32, y: i32 }

fn main -> i32:
    let mut p = Point { x: 1, y: 2 }
    let rx = &p.x
    let rmx = &mut p.x
    println(*rx + *rmx)
