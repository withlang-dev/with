//! expect-stdout: 500500
//! expect-debug-alloc: allocations=3

// §4.3c (D119 step 2): a List literal that is never pushed, grown, moved
// out, stored or retained lives in the frame. A thousand calls of a
// function holding `[1, 2, 3, 4]` cost the program's three baseline
// allocations and nothing per call (1003 before the guarantee).
fn f(i: i32) -> i32:
    let t = [1, 2, 3, 4]
    t[0] + i

fn main:
    var s = 0
    for i in 0..1000: s = s + f(i)
    print(s)
