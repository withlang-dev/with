//! expect-stdout: 9

// §4.9a (D103): a value converts to Option[T] where one is demanded — the if_tail site.
fn f(n: i32) -> Option[i32]:
    if n > 0: n else: None
fn main: print(f"{f(9) ?? 0}")
