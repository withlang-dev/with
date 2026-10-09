//! expect-check-fail: E0921
//! expect-check-fail: program may run concurrently here
//! expect-check-fail: std/task.w@

// #670: the concurrency-evidence label lives in the std prelude (the async
// call inside the instantiated combinator body), so it must be rendered
// against THAT file's line table and name the file.

use std.task.Task
use std.task.await_all
use std.builtins.print_i32
var counter: i32 = 0

fn main:
    counter = counter + 1
    let ts: List[Task[Result[i32, str]]] = List.new()
    let _ = ts |> await_all
    print_i32(counter)
