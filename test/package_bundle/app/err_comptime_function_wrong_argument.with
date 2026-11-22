//! expect-error: operator requires integer comptime values

// #3401: a `comptime` function's parameters are checked at the importer's call.
use shapes
const BAD: i32 = comptime squared("three")
fn main: print(BAD)
