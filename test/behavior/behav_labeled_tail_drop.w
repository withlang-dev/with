//! expect-stdout: id=5 drops=1
// §29.13 (#640): a non-Copy (Drop) value returned from a labeled tail is moved
// out correctly — dropped exactly once at the caller's scope end, no leak/double.
var DROPS = 0
type R { id: i32 }
impl Drop for R:
    fn drop(move self: Self): DROPS = DROPS + 1
fn f() -> R:
    let x = 5
    'done:
        R { id: x }
fn main:
    var saved = 0
    {
        let r = f()
        saved = r.id
    }
    print(f"id={saved} drops={DROPS}")
