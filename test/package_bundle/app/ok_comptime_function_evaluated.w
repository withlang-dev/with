//! expect: ok

// #3401: a `comptime` function of the package, evaluated in the importer.
use shapes
const NINE: i32 = comptime squared(3)
fn main: print(NINE)
