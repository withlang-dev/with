//! expect-stdout: first 1 rest 3 4
//! expect-stdout: b 6
//! expect-stdout: drop 7
//! expect-stdout: drop 6
//! expect-stdout: drop 5
//! expect-stdout: drop 4
//! expect-stdout: drop 3
//! expect-stdout: drop 2
//! expect-stdout: drop 1

// D115 (§9.7): an owned fixed array is taken apart by value; `rest` is the
// owned remainder `[W; N-k]`, and every element left unbound (`_`, a bare
// `..`) is still dropped exactly once.
type W { id: i32 }
impl Drop for W:
    move fn drop(): print(f"drop {self.id}")

fn four() -> [W; 4]: [W { id: 1 }, W { id: 2 }, W { id: 3 }, W { id: 4 }]
fn three() -> [W; 3]: [W { id: 5 }, W { id: 6 }, W { id: 7 }]

fn main:
    let [first, ..rest] = four()
    print(f"first {first.id} rest {rest.len()} {rest[2].id}")
    let [_, b, ..] = three()
    print(f"b {b.id}")
