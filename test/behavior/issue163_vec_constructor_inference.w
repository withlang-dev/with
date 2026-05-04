//! expect-stdout: ok

var ISSUE163_DEFER_LEN: i64 = 0

fn issue163_defer_push:
    var order = Vec.new()
    order.push(1)
    defer: ISSUE163_DEFER_LEN = order.len()
    defer: order.push(3)
    order.push(2)

fn issue163_count(xs: &Vec[i32]) -> i64:
    xs.len()

fn main:
    issue163_defer_push()
    assert(ISSUE163_DEFER_LEN == 3)

    var buffer = Vec.new()
    buffer.push(10)
    buffer.push(20)
    assert(buffer.len() == 2)

    var empty = Vec.new()
    assert(issue163_count(&empty) == 0)

    var source = Vec.new()
    var moved = source
    moved.push(7)
    assert(moved.len() == 1)

    print("ok")
