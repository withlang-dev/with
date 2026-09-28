//! expect-stdout: some v1
//! expect-stdout: ok r1
//! expect-stdout: Some("v1!")
//! expect-stdout: None
//! expect-stdout: Some(2)
//! expect-stdout: Ok(3)
//! expect-stdout: Err("e1")
//! expect-stdout: Ok("r1?")
//! expect-stdout: map vw
//! expect-stdout: pair 1 2
//! expect-stdout: else ran
//! expect-stdout: done

// §13.6a: a `for` over an Option or Result is a one-clause comprehension —
// "the first clause determines the carrier family", and nothing requires a
// second. The statement form runs its body once on Some/Ok and not at all on
// None/Err; the expression form (`yield E`) re-wraps E in Some/Ok and passes
// None/Err through, E's type free of the payload's.
use std.collections.HashMap

fn get(b: bool) -> Option[str]: if b: Some("v" ++ "1") else: None
fn res(b: bool) -> Result[str, str]: if b: Ok("r" ++ "1") else: Err("e" ++ "1")

fn main:
    for x in get(true):
        print(f"some {x}")
    for x in get(false):
        print("never none")
    for x in res(true):
        print(f"ok {x}")
    for x in res(false):
        print("never err")
    let a = for x in get(true): yield x ++ "!"
    print(f"{a:?}")
    let b = for x in get(false): yield x ++ "!"
    print(f"{b:?}")
    let c = for x in get(true): yield x.len()
    print(f"{c:?}")
    let d: Result[i64, str] = for x in res(true): yield x.len() + 1
    print(f"{d:?}")
    let e: Result[i64, str] = for x in res(false): yield x.len()
    print(f"{e:?}")
    let owned = res(true)
    let f = for x in owned: yield x ++ "?"
    print(f"{f:?}")
    var m: HashMap[str, str] = HashMap.new()
    m.insert("k", "v" ++ "w")
    for v in m.get("k"):
        print(f"map {v}")
    let p: Option[(i32, i32)] = Some((1, 2))
    for (i, j) in p:
        print(f"pair {i} {j}")
    for x in get(false):
        print("never")
    else:
        print("else ran")
    print("done")
