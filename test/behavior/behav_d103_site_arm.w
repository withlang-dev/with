//! expect-stdout: 7

// §4.9a (D103): a value converts to Option[T] where one is demanded — the arm site.
fn f(n: i32) -> Option[i32]:
    match n:
        0 => None
        _ => n
fn main: print(f"{f(7) ?? 0}")
