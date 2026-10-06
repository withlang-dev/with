// #2219 refusal fixture: a bundle-owned global whose initializer does not
// fold to data (`side()` is a call) has no storage in the object and no
// initializer ever runs for it. `limit_x` reads it, so the build must fail
// naming the global, the body and `side()` — a consumer once read 0 from a
// zeroed stand-in instead.
pub type Point { x: i32, y: i32 }
fn side() -> i32: 3
pub let LIMITS: Point = Point { x: side(), y: 0 }
pub fn limit_x() -> i32: LIMITS.x
pub fn plain(x: i32) -> i32: x
