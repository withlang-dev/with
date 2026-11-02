//! expect-stdout: 6
//! expect-stdout: 9
//! expect-stdout: 3
// D126 (§4.3c): a slice demand (`[]T`) supplies the element type to a
// literal in argument position and views it; a List argument is viewed the
// same way. (#2944's example wrote `&[i32]`, a reference to a slice, which
// nothing satisfies; the slice is `[]i32`.)
fn sum(xs: []i32) -> i32:
    var t = 0
    for x in xs: t = t + x
    t
fn main:
    print(sum([1, 2, 3]))
    print(sum([4, 5]))
    let ys = [1, 2]
    print(sum(ys))
