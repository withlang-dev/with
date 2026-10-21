//! expect-stdout: 3

// §4.9a (D103): a value converts to Option[T] where one is demanded — the arg site.
fn takes(o: Option[i32]) -> i32: o ?? -1
fn main: print(f"{takes(3)}")
