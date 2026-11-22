//! expect-error: cannot assign to immutable variable

// #1354: a refutable `let ... else` binds immutable names; `var` is the
// mutable spelling.

fn find(k: i32) -> Option[i32]: if k > 0: Some(k) else: None

fn run(k: i32) -> i32:
    let Some(n) = find(k) else: return -1
    n += 1
    n

fn main:
    print(f"{run(1)}")
