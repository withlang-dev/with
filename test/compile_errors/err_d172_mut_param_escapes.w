//! expect-error: a `mut` parameter is a mode, not a value: `r` cannot be returned, stored or moved (§3.8a)
// D172 (2), §3.8a: a `mut` parameter is the caller's place, a mode and not
// a value: it cannot be returned, stored or captured by an escaping
// closure. Returning `r` would move a resource out of the caller's place,
// which still owns it. (A value type, `List[i32]` under D120, returns a
// copy and moves nothing out.)
type Res:
    id: i32

impl Drop for Res:
    move fn drop(): print(f"drop {self.id}")

fn keep(mut r: Res) -> Res:
    r.id = r.id + 1
    r

fn main:
    var r = Res { id: 1 }
    let k = keep(r)
    print(k.id)
