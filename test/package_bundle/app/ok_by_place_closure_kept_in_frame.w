//! expect: ok

// #3401: keep stores the closure in a value of the caller's own frame.
use shapes
fn main:
    var k = Keeper { held: [] }
    var xs: List[i32] = [1]
    keep(k, () => xs.len32())
    print(k.held.len())
