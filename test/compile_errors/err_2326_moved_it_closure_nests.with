//! expect-check-fail: nested implicit closure is ambiguous

// #2326 (§9.3.1): `it` in `plus(it, ...)` belongs to `map`, the nearest
// argument that takes a function, so the inner `map(it * 0)` is an `it`
// closure inside another: nested `it` is forbidden (E0951).
fn plus(a: isize, b: isize): a + b

fn main:
    let nums = [1, 2, 3]
    print(nums.iter().map(plus(it, nums.iter().map(it * 0).sum())).sum())
