//! expect-stdout: same scope: 1
//! expect-stdout: outer origin: 5 5
//! expect-stdout: ok
//! expect-stdout: drop 1

// #1783 (§21.1, D22): a view stored through a `mut fn` into its receiver is
// tied to the receiver's binding, and the uses whose origins outlive that
// storage still compile: a holder declared before a same-scope local that is
// never read after the local dies and has no destructor; a holder declared
// after its origin; and a `Drop` holder declared after the local it views
// (rule 7: it drops first).
type Holder = ephemeral { v: Vec[&i32], r: Option[&i32] }
impl Holder:
    mut fn keep(x: &i32):
        self.v.push(x)
        self.r = Some(x)

type Counted = ephemeral { v: Vec[&i32] }
impl Drop for Counted:
    move fn drop(): print(f"drop {self.v.len32()}")
impl Counted:
    mut fn keep(x: &i32): self.v.push(x)

fn main:
    var h = Holder { v: Vec.new(), r: None }
    let n = 5
    h.keep(&n)
    print(f"same scope: {h.v.len32()}")
    let m = 5
    var h2 = Holder { v: Vec.new(), r: None }
    h2.keep(&m)
    print(f"outer origin: {h2.r.unwrap()} {h2.v[0]}")
    let k = 9
    var c = Counted { v: Vec.new() }
    c.keep(&k)
    print("ok")
