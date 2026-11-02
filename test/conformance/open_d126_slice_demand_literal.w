//! expect-stdout: 6
// D126 (§4.3c): a slice demand types a literal in argument position. #2944
fn sum(xs: &[i32]) -> i32:
    var t = 0
    for x in xs: t = t + x
    t
print(sum([1, 2, 3]))
