//! expect-check-fail: implicit drop of `h` uses `&n` after `n` is destroyed (§21.1 Rule 7)

// #1783 (§21.1 rule 7): the same store spelled directly, `h.v.push(&n)`.
type Holder = ephemeral { v: List[&i32] }
impl Drop for Holder:
    move fn drop(): print(f"drop {self.v.len32()}")
fn main:
    var h = Holder { v: List.new() }
    let n = 5
    h.v.push(&n)
    print("end")
