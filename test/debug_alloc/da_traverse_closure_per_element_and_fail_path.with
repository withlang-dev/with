//! expect-debug-alloc: leak count=0
//! expect-stdout: none 2
//! expect-stdout: some 3 hello-1
//! expect-stdout: err bad
//! expect-stdout: ok 2
//! expect-stdout: drops 3
//! expect-stdout: ok

// §10.7 (D165): `List.traverse` calls its closure once per element — the
// callee is copied into each call, never moved by the first iteration — and
// the short-circuit path (`None` / `Err`) releases the elements pushed so
// far. Elements with drop glue (a str, a Drop type) are each dropped once.

var DROPS: i32 = 0

type Tracked { n: isize }
impl Drop for Tracked:
    move fn drop():
        DROPS += 1

fn parse_i32(s: &str) -> Option[i32]: s.parse()

fn main:
    var calls = 0
    let bad = ["1", "2", "three"]
    let p1: Option[List[i32]] = bad.traverse(s =>
        calls += 1
        parse_i32(s))
    print(f"none {calls - 1}")

    let names = ["hello", "world", "again"]
    let p2: Option[List[str]] = names.traverse(s => Some(f"{s}-{1}"))
    let got = p2.unwrap()
    print(f"some {got.len()} {got[0]}")

    let nums = [1, 2, 3]
    let r1: Result[List[Tracked], str] = nums.traverse(n =>
        if n == 2: Err("bad") else: Ok(Tracked { n }))
    match r1:
        Ok(_) => print("unexpected")
        Err(e) => print(f"err {e}")

    let more = [4, 5]
    let r2: Result[List[Tracked], str] = more.traverse(n => Ok(Tracked { n }))
    let kept = r2.unwrap()
    print(f"ok {kept.len()}")
    drop(kept)
    print(f"drops {DROPS}")
    print("ok")
