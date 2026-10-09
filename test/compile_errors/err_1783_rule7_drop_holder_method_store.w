//! expect-check-fail: implicit drop of `h` uses `&n` after `n` is destroyed (§21.1 Rule 7)

// #1783 (§21.1 rule 7): `h` has a destructor that reads its views and is
// declared before `n`, so it drops after `n`; the view `keep` stored into it
// is read by that drop.
type Holder = ephemeral { v: List[&i32] }
impl Drop for Holder:
    move fn drop(): print(f"drop {self.v.len32()}")
impl Holder:
    mut fn keep(x: &i32): self.v.push(x)
fn main:
    var h = Holder { v: List.new() }
    let n = 5
    h.keep(&n)
    print("end")
