// §12.4 (D75) refusal fixture: a `once` parameter is a checked contract — a
// body that may invoke it twice never reaches an interface, so no consumer
// could pass a consuming closure to it.
pub fn twice(f: once fn() -> i32) -> i32: f() + f()
