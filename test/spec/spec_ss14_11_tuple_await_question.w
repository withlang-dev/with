//! expect-stdout: ok

var TUPLE_AWAIT_STARTED: i32 = 0

fn reset_started:
    unsafe:
        TUPLE_AWAIT_STARTED = 0

fn note_started:
    unsafe:
        TUPLE_AWAIT_STARTED = TUPLE_AWAIT_STARTED + 1

fn started_count -> i32:
    unsafe:
        TUPLE_AWAIT_STARTED

async fn tuple_ok(value: i32) -> Result[i32, str]:
    value

async fn tuple_err(message: str) -> Result[i32, str]:
    Err(message)

fn start_ok(value: i32) -> Task[Result[i32, str]]:
    note_started()
    tuple_ok(value)

fn start_err(message: str) -> Task[Result[i32, str]]:
    note_started()
    tuple_err(message)

fn tuple_await_success -> Result[i32, str]:
    reset_started()
    let (left, right) = (start_ok(10), start_ok(32)).await?
    assert(started_count() == 2)
    left + right

fn tuple_await_left_error -> Result[i32, str]:
    reset_started()
    let (left, right) = (start_err("left"), start_ok(99)).await?
    left + right

fn tuple_await_right_error -> Result[i32, str]:
    reset_started()
    let (left, right) = (start_ok(7), start_err("right")).await?
    left + right

fn main:
    match tuple_await_success():
        Ok(value) => assert(value == 42)
        Err(_) => assert(false)

    match tuple_await_left_error():
        Ok(_) => assert(false)
        Err(message) =>
            assert(message == "left")
            assert(started_count() == 2)

    match tuple_await_right_error():
        Ok(_) => assert(false)
        Err(message) =>
            assert(message == "right")
            assert(started_count() == 2)

    print("ok")
