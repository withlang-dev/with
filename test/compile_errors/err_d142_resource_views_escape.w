//! expect-check-fail: returned ephemeral value may outlive its origin
// D142 / §22.1 rule 8: a list of resource views is as ephemeral as its
// views; returning one over a local is refused.
type Res { n: i32 }
impl Drop for Res:
    move fn drop(): ()
fn leak() -> List[&Res]:
    let xs = [Res { n: 1 }]
    xs.iter() |> collect[List]()
fn main:
    let vs = leak()
    print(f"{vs.len()}")
