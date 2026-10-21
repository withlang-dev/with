//! expect-stdout: 5

// §4.9a (D103): a value converts to Option[T] where one is demanded — the tail site.
fn f(n: i32) -> Option[i32]:
    if n < 0: return None
    n
fn main: print(f"{f(5) ?? 0}")
