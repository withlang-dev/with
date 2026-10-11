//! expect-stdout: 35

// #2333 (§4.2.1 D88, D114, #1703): a module's untyped constant keeps its
// type context when the root declares a global of the same name. The root's
// `A` displaces the module's, which is registered under its displaced
// identity; the module's bare `A` in `A * B` still finds it, so the tail
// takes the declared `i32` and nothing narrows. It read `isize` before.
use displaced_const_owner

let A = 5

fn main:
    print(f() + A)
