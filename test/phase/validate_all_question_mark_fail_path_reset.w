//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// #2011: `?` over a user enum moves the carrier into the return place on the
// failure path; that move's reset belongs to the failure path alone. Left
// queued, the enclosing statement's flush blanked the still-live carrier on
// the pass path too ("reset of _3 on a path where it was never moved"),
// whether the payload was Copy or moved out.
enum R { Ok(str) | Err(str) }
enum N { Ok(i32) | Err(str) }

fn mk(x: i32) -> R:
    if x < 0: .Err("neg") else: .Ok("pos")

fn mk_n(x: i32) -> N:
    if x < 0: .Err("neg") else: .Ok(x * 2)

fn go() -> R:
    let v = mk(5)?
    .Ok(v)

fn go_n() -> N:
    errdefer: print("cleanup")
    let v = mk_n(5)?
    .Ok(v)

fn main:
    let _ = go()
    let _ = go_n()
