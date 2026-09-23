//! expect-stdout: [7]
// §13.5b (#640): goto to a forward label, then the tail expression is the value.
fn f(jump: bool) -> i32:
    var x = 0
    if jump:
        goto 'done
    x = 99
    'done:
        x = x + 7
        x
fn main:
    print(f"[{f(true)}]")
