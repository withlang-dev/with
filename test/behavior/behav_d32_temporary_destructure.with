//! expect-stdout: drop
//! expect-stdout: 1
//! expect-stdout: drop
//! expect-stdout: 2

// #1281: the spellings the temporary-base help offers. A temporary's
// element is reached by decomposing the whole value (§2.2: whole values
// decompose whole) or by binding it to a `var` and vacating explicitly.
type R { n: i32 }
impl Drop for R:
    move fn drop(): print("drop")
type S { r: R, k: i32 }
fn make() -> (i32, R): (0, R { n: 1 })
fn mk() -> S: S { r: R { n: 2 }, k: 0 }
fn take(r: R) -> i32: r.n
fn main:
    let (_, a) = make()
    print(f"{take(a)}")
    var t = mk()
    print(f"{take(move t.r)}")
