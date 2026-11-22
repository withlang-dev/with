//! expect-stdout: 203

// #1638: the owning spelling stores and returns freely (D62/D63).
type Cnt { name: str, f: fn(i32) -> i32 }
fn mk(k: i32) -> Cnt:
    Cnt { name: "n", f: move x => x + k }
fn direct(c: &Cnt) -> i32: c.f(1) + c.f(2)
fn main:
    let c = mk(100)
    print(direct(&c))
