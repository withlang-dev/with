// Minimal while-let multi-statement

fn maybe(n: i32) -> Option[i32]:
    if n < 3 then Some(n) else None

fn main -> i32:
    var i = 0
    while let Some(v) = maybe(i):
        let _v = v
        i = i + 1
    if i == 3 then 0 else 1
