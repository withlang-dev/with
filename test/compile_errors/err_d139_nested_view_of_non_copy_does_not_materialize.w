//! expect-check-fail: wrong argument type in call to 'take_res'

// D139's edge: the every-layer read is for Copy values. A view of a view of
// a resource (a type with a destructor) does not become the value, as a
// single view of it never did.
type Res { n: i32 }
impl Drop for Res:
    move fn drop(): ()

fn take_res(r: Res) -> i32: r.n

fn main:
    let res = Res { n: 7 }
    let r = &res
    let rr = &r
    print(f"{take_res(rr)}")
