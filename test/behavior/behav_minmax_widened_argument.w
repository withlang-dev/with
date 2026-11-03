//! expect-stdout: 3
//! expect-stdout: 2
// `isize.max(i32)`: the argument widens into the receiver's type (§4.2.6);
// codegen compared an i64 against an i32 and LLVM refused the function.
fn update(depth: i32): depth + 1
fn main:
    var best = 0
    var depth = 0
    for _ in 0..3:
        depth = update(depth)
        best = best.max(depth)
    print(best)
    let small: i32 = 2
    print(best.min(small))
