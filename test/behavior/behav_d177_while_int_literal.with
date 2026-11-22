//! expect-stdout: 3
//! expect-stdout: found

// D177 (§4.2a): `while 1:` is the constant-true loop `while true:` is — a
// function whose every exit is a `return` inside it does not fall through
// (the migrated C `while (1)` shape).
fn count_to(limit: i32) -> i32:
    var n = 0
    while 1:
        n += 1
        if n >= limit: return n

fn find_two(xs: &List[i32]) -> str:
    var i = 0
    while 1:
        if xs[i] == 2: return "found"
        i += 1

fn main:
    print(f"{count_to(3)}")
    let xs = [1, 2, 3]
    print(find_two(&xs))
