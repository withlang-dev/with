use std.async

fn main -> i32:
    let tasks = Vec.new()
    let _value = await_first(tasks)
    0
