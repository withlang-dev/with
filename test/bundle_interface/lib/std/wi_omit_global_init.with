// #2219 omission fixture: a bundle-owned global whose initializer does not
// fold to data (`side()` is a call) stays corpus-internal while nothing in
// the object reads it — omitted from the interface with a note and named in
// the manifest's `omitted` lines; `plain` is exported as usual.
pub type Point { x: i32, y: i32 }
fn side() -> i32: 3
pub let LIMITS: Point = Point { x: side(), y: 0 }
pub fn plain(x: i32) -> i32: x
