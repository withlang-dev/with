//! expect-stdout: 2 1 8 21 [a]

// D220 (#690, §29.8): a parameter is a local binding, so the consuming
// rebind applies to it, and a value with no destructor is consumed by the
// read in its own initializer. `var x = x` is the local copy: the caller's
// variable is untouched.
fn bump(x: i32) -> i32:
    var x = x
    x = x + 1
    x

fn twice(n: i32) -> i32:
    let n = n * 2
    n

fn local() -> i32:
    let k = 20
    let k = k + 1
    k

fn trimmed(s: str) -> str:
    let s = s.trim()
    s

fn main:
    let v = 1
    print(f"{bump(v)} {v} {twice(4)} {local()} [{trimmed(" a ")}]")
