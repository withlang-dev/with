// Wave 6 unit test: control flow typing
// Covers: if/else, while, for, loop/break, return

fn sum_to(n: i32) -> i32:
    var total: i32 = 0
    var i: i32 = 1
    while i <= n:
        total = total + i
        i = i + 1
    total

fn first_positive(items: [4]i32) -> i32:
    for i in 0..4:
        if items[i as i64] > 0:
            return items[i as i64]
    -1

// Direct return as block statement — appears as return_expr in dump
fn clamp(n: i32) -> i32:
    return n + 1

fn main -> i32:
    let s = sum_to(10)
    s
