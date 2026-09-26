//! expect-debug-alloc: leak count=0
//! expect-stdout: vec stopped at bad2
//! expect-stdout: set stopped at bad3
//! expect-stdout: all 4

// §13.6: a `?` in a comprehension's element leaves the function while the
// collection is being built. The collection and the elements already in it
// are released exactly once on that path, like any statement temporary; a
// comprehension that finishes moves its collection out as before.
use std.collections.{HashSet}

fn check(i: i32, bad: i32) -> Result[str, str]:
    if i == bad: return Err(f"bad{i}")
    Ok(f"ok{i}")

fn checked_vec(bad: i32) -> Result[Vec[str], str]:
    let v = [check(i, bad)? for i in 0..6]
    Ok(v)

fn checked_set(bad: i32) -> Result[HashSet[str], str]:
    let s: HashSet[str] = [check(i, bad)? for i in 0..6]
    Ok(s)

fn main:
    match checked_vec(2):
        Ok(v) => print(f"vec kept {v.len()}")
        Err(e) => print(f"vec stopped at {e}")
    match checked_set(3):
        Ok(s) => print(f"set kept {s.len()}")
        Err(e) => print(f"set stopped at {e}")
    match checked_vec(9):
        Ok(v) => print(f"all {v.len() - 2}")
        Err(e) => print(f"vec stopped at {e}")
