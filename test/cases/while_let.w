// Minimal while-let multi-statement

fn maybe(n: i32) -> Option[i32] =
    if n < 3 then Some(n) else None

fn main() -> i32 =
    var i = 0
    var x = 0
    while let Some(v) = maybe(i):
        x = 1
        i = i + 1
    i
