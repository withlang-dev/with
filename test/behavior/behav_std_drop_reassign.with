//! expect-stdout: drops=2
// §2.5/#641b: drop(x) consumes via the move discipline, so a later reassign
// re-arms the scope-exit drop — both values drop exactly once.
var DROPS = 0
type R { id: i32 }
impl Drop for R:
    fn drop(move self: Self): DROPS = DROPS + 1
fn run():
    var r = R { id: 1 }
    drop(r)
    r = R { id: 2 }
fn main:
    run()
    print(f"drops={DROPS}")
