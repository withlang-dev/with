//! expect-stdout: first 1 rest 2
//! expect-stdout: drop 2
//! expect-stdout: drop 3
//! expect-stdout: drop 1
//! expect-stdout: end

// D115 (§9.7): a place moved with `move` is owned, and the pattern takes it
// apart: nothing is left behind and nothing leaks (`match move v` once
// bound views and never dropped the List).
type W { id: i32 }
impl Drop for W:
    move fn drop(): print(f"drop {self.id}")

fn main:
    let v = [W { id: 1 }, W { id: 2 }, W { id: 3 }]
    match move v:
        [first, ..rest] => print(f"first {first.id} rest {rest.len()}")
        _ => print("empty")
    print("end")
