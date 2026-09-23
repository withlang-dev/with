//! expect-debug-alloc: leak count=0
//! expect-stdout: R err vec 0
//! expect-stdout: R ok vec 3
//! expect-stdout: O none vec 0
//! expect-stdout: O some vec 3
//! expect-stdout: R err map 0
//! expect-stdout: O none opt none
//! expect-stdout: typed let 0
//! expect-stdout: arg 0
//! expect-stdout: uses err 4
//! expect-stdout: loop 0 3 0

// #1378 (§10: `unwrap_or_else[U]((fn(E) -> U)) -> Join[T, U]`): a lazy
// fallback whose body is a constructor with no expected type (`Vec.new()`)
// infers the bare generic `Vec`; the join settles it to the payload's
// `Vec[i32]`, and the closure returns that type. The closure used to keep
// `fn(str) -> Vec`, and codegen died: "BUG: closure result lacks LLVM type".
// Covers: Result/Option × Err/None and Ok/Some paths, Vec / HashMap /
// Option fallbacks, an annotated binding, a borrowed call argument, a
// fallback that uses the Err payload, and a loop.
use std.collections

fn mkv(n: i32) -> Vec[i32]:
    var xs: Vec[i32] = Vec.new()
    for i in 0..n: xs.push(i)
    xs

fn rv(ok: bool) -> Result[Vec[i32], str]:
    if not ok: return Err("no" ++ "pe")
    Ok(mkv(3))

fn ov(ok: bool) -> Option[Vec[i32]]:
    if not ok: return None
    Some(mkv(3))

fn rm(ok: bool) -> Result[HashMap[str, i32], str]:
    if not ok: return Err("no" ++ "pe")
    Ok(HashMap.new())

fn roo(ok: bool) -> Option[Option[i32]]:
    if not ok: return None
    Some(Some(1))

fn count(xs: &Vec[i32]): xs.len()

fn main:
    let a = rv(false).unwrap_or_else((_) => Vec.new())
    print(f"R err vec {a.len()}")
    let b = rv(true).unwrap_or_else((_) => Vec.new())
    print(f"R ok vec {b.len()}")
    let c = ov(false).unwrap_or_else(() => Vec.new())
    print(f"O none vec {c.len()}")
    let d = ov(true).unwrap_or_else(() => Vec.new())
    print(f"O some vec {d.len()}")
    let m = rm(false).unwrap_or_else((_) => HashMap.new())
    print(f"R err map {m.len()}")
    let o = roo(false).unwrap_or_else(() => None)
    print(f"O none opt {if o.is_some(): "some" else: "none"}")
    let t: Vec[i32] = rv(false).unwrap_or_else((_) => Vec.new())
    print(f"typed let {t.len()}")
    print(f"arg {count(&rv(false).unwrap_or_else((_) => Vec.new()))}")
    let u = rv(false).unwrap_or_else((e) => mkv(e.len32()))
    print(f"uses err {u.len()}")

    var lens = ""
    for k in 0..3:
        let v = rv(k == 1).unwrap_or_else((_) => Vec.new())
        lens = lens ++ (if k > 0: " " else: "") ++ f"{v.len()}"
    print(f"loop {lens}")
