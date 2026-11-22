//! expect-stdout: true false 2 | 11
// #2326 (§9.3.1): an implicit `it` closure belongs to the nearest enclosing
// argument whose parameter takes a one-parameter function. `s.contains(it)`
// takes a `&str`, so the closure is `any`'s: `any(n => s.contains(n))`. The
// same through two calls that take values, beside an `it` the argument
// already owns.
fn twice(n: isize): n * 2
fn plus(a: isize, b: isize): a + b

fn main:
    let s = "hello world"
    let names = ["world", "x"]
    let found = names.iter().any(s.contains(it))
    let none = names.iter().all(s.contains(it))
    let count = names.iter().filter(s.contains(it) or it.len() == 1).count()
    let nums = [1, 2, 3]
    let total = nums.iter().map(plus(twice(it), 0)).filter(it > 2).sum()
    print(f"{found} {none} {count} | {total + 1}")
