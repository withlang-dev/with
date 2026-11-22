//! expect-stdout: true
//! expect-stdout: false
//! expect-stdout: true
//! expect-stdout: true

// §11.7: `contains` compares each element by its type's `==` — a str by its
// text, a tuple part by part. By their bytes, two equal strs at different
// addresses differed (a driver flag table matched nothing).
fn flag(s: &str) -> str: s ++ ""

fn main:
    let known = ["--emit-c", "--emit-obj"]
    print(known.contains(flag("--emit-c")))
    print(known.contains(flag("--emit")))
    let pairs = [(1, flag("a")), (2, flag("b"))]
    print(pairs.contains((2, flag("b"))))
    let nums = [3, 5, 8]
    print(nums.contains(5))
