//! expect-stdout: 6

// §4.9a (D103): a value converts to Option[T] where one is demanded — the return site.
fn f(n: i32) -> Option[i32]:
    if n >= 0: return n
    None
fn main: print(f"{f(6) ?? 0}")
