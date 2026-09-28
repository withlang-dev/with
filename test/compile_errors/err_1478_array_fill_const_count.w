//! expect-check-fail: the count is not a compile-time constant

// #1478 (§4.3a, §9.1b): the count of `[value; N]` is an integer literal or a
// `const`. A module-level `let` is a runtime value even when its initializer
// is a constant, so it is refused by name — it once built a 1-element array
// silently, and after Sema evaluated fill counts it was read through the
// comptime evaluator as if it were a `const`.

let N: i64 = 4

fn main:
    let a = [7 as i32; N]
    print(f"{a.len()}")
