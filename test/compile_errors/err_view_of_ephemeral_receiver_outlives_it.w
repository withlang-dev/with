//! expect-check-fail: view 'h' may outlive its origin 's'

// §21.1 Rule 6 / §5.5: a view a method returns from an ephemeral VALUE
// receiver depends on that value's own storage, not only on the origins the
// value carries. `s` here is ephemeral (it holds `&db`) and has a Drop; the
// view `h` it hands out was tied to `db` alone, so consuming `s` while `h`
// lived was accepted, and `h.origin` read a finalized statement.

type Db { n: i32, live: bool }
impl Drop for Db:
    move fn drop():
        if self.live: print("close")

type S = ephemeral { parent: &Db, n: i32, live: bool }
impl Drop for S:
    move fn drop():
        if self.live: print("finalize")

type V = ephemeral { origin: &S, n: i32 }

impl S:
    fn view() -> Option[V]: Some(V { origin: self, n: self.n })

fn main:
    let db = Db { n: 1, live: true }
    let s = S { parent: &db, n: 1, live: true }
    let h = s.view().unwrap()
    drop(s)
    print(f"{h.n}")
