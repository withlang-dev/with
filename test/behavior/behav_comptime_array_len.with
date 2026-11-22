//! expect-stdout: 3
//! expect-stdout: 0
//! expect-stdout: false
//! expect-stdout: true
//! expect-stdout: 2

// An array's length is known at compile time as a List's is. `[1, 2,
// 3].len()` in a `comptime` expression was refused: "method 'len' is not
// comptime-evaluable yet".
const THREE: i32 = comptime [1, 2, 3].len() as i32
const NONE_LEFT: i32 = comptime [7].rest().len() as i32
const HAS_SOME: bool = comptime [1, 2].is_empty()
const HAS_NONE: bool = comptime [1].rest().is_empty()

comptime fn count(names: [2]str) -> i32: names.len() as i32

fn main:
    print(THREE)
    print(NONE_LEFT)
    print(HAS_SOME)
    print(HAS_NONE)
    print(comptime count(["a", "b"]))
