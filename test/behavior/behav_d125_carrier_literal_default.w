//! expect-stdout: 4 0 7 -1

// D125 (§4.2.1 rule 8): a carrier's payload is a typed arm of the join its
// default makes, so an untyped literal default takes the payload's type
// (`unwrap_or(0)` of an Option[i32] is i32), never the isize default.
fn take(x: i32): x

fn main:
    let some: Option[i32] = Some(3)
    let none: Option[i32] = None
    let ok: Result[i32, str] = Ok(7)
    let err: Result[i32, str] = Err("no")
    print(f"{take(some.map(x => x + 1).unwrap_or(0))} {take(none.unwrap_or(0))} {take(ok.unwrap_or(-1))} {take(err.unwrap_or(-1))}")
