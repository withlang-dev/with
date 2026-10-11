// #2333 fixture module: an untyped constant (D88) the root program
// (behav_2333_displaced_untyped_const.w) also names. The module's own
// references type it from their use (`A * B` at `i32`), displaced or not.
pub const A = 10
const B = 3
pub fn f() -> i32: A * B
