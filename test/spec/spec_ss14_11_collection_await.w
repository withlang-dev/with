//! expect-stdout: ok

use std.task.Task
use std.task.await_all
use std.task.await_first
use std.task.await_any
use std.task.await_settled
extern fn with_fiber_live_fibers() -> i32

async fn tick(): ()

async fn delayed_value(value: i32, ticks: i32) -> i32:
    var i = 0
    while i < ticks:
        tick().await
        i = i + 1
    value

async fn delayed_ok(value: i32, ticks: i32) -> Result[i32, str]:
    var i = 0
    while i < ticks:
        tick().await
        i = i + 1
    Ok(value)

async fn delayed_err(message: str, ticks: i32) -> Result[i32, str]:
    var i = 0
    while i < ticks:
        tick().await
        i = i + 1
    Err(message)

async fn never_result(value: i32) -> Result[i32, str]:
    while true:
        tick().await
    Ok(value)

fn test_await_all_in_input_order():
    let baseline = unsafe { with_fiber_live_fibers() }
    let tasks: Vec[Task[i32]] = Vec.new()
    tasks.push(delayed_value(10, 4))
    tasks.push(delayed_value(20, 0))
    let values = tasks |> await_all
    assert(values.len() == 2)
    assert(values.get(0) == 10)
    assert(values.get(1) == 20)
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn test_fallible_await_all_in_input_order():
    let baseline = unsafe { with_fiber_live_fibers() }
    let tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    tasks.push(delayed_ok(10, 4))
    tasks.push(delayed_ok(20, 0))
    let result = tasks |> await_all
    assert(result.is_ok())
    let values = result.unwrap()
    assert(values.len() == 2)
    assert(values.get(0) == 10)
    assert(values.get(1) == 20)
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn collect_first_error() -> Result[Vec[i32], str]:
    let tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    tasks.push(never_result(10))
    tasks.push(delayed_err("fast", 0))
    tasks |> await_all?

fn test_fallible_await_all_is_completion_fail_fast():
    let baseline = unsafe { with_fiber_live_fibers() }
    let result = collect_first_error()
    assert(result.is_err())
    assert(result.err().unwrap() == "fast")
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn test_await_first_uses_completion_order():
    let baseline = unsafe { with_fiber_live_fibers() }
    let tasks: Vec[Task[i32]] = Vec.new()
    tasks.push(delayed_value(10, 4))
    tasks.push(delayed_value(20, 0))
    assert((tasks |> await_first) == 20)
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn test_await_any_uses_completion_order():
    let baseline = unsafe { with_fiber_live_fibers() }
    let tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    tasks.push(delayed_ok(10, 4))
    tasks.push(delayed_ok(20, 0))
    tasks.push(never_result(30))
    let result = tasks |> await_any
    assert(result.is_ok())
    assert(result.unwrap() == 20)
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn test_await_any_all_fail_is_input_ordered():
    let baseline = unsafe { with_fiber_live_fibers() }
    let tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    tasks.push(delayed_err("slow", 4))
    tasks.push(delayed_err("fast", 0))
    let result = tasks |> await_any
    assert(result.is_err())
    let errors = result.err().unwrap()
    assert(errors.len() == 2)
    assert(errors.get(0) == "slow")
    assert(errors.get(1) == "fast")
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn test_await_any_empty():
    let tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    let result = tasks |> await_any
    assert(result.is_err())
    assert(result.err().unwrap().is_empty())

fn test_await_settled_is_input_ordered():
    let baseline = unsafe { with_fiber_live_fibers() }
    let tasks: Vec[Task[Result[i32, str]]] = Vec.new()
    tasks.push(delayed_err("slow", 4))
    tasks.push(delayed_ok(20, 0))
    let settled = tasks |> await_settled
    assert(settled.len() == 2)
    let first = settled.remove(0)
    let second = settled.remove(0)
    assert(first.is_err())
    assert(first.err().unwrap() == "slow")
    assert(second.is_ok())
    assert(second.unwrap() == 20)
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn main:
    test_await_all_in_input_order()
    test_fallible_await_all_in_input_order()
    test_fallible_await_all_is_completion_fail_fast()
    test_await_first_uses_completion_order()
    test_await_any_uses_completion_order()
    test_await_any_all_fail_is_input_ordered()
    test_await_any_empty()
    test_await_settled_is_input_ordered()
    print("ok")
