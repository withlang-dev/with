//! expect-stdout: ok

error TokenError =
    | Done

unsafe fn next_option(counter: *mut i32) -> Option[i32]:
    unsafe:
        if *counter >= 4:
            return None
        let value = *counter
        *counter = *counter + 1
        Some(value)

unsafe fn next_result(counter: *mut i32) -> Result[i32, TokenError]:
    unsafe:
        if *counter >= 3:
            return Err(.Done)
        let value = *counter + 10
        *counter = *counter + 1
        Ok(value)

fn main:
    var opt_counter = 0
    var opt_sum = 0
    while let Some(value) = unsafe { next_option(&raw mut opt_counter) }:
        opt_sum = opt_sum + value
    assert(opt_counter == 4)
    assert(opt_sum == 6)

    var result_counter = 0
    var result_sum = 0
    while let Ok(value) = unsafe { next_result(&raw mut result_counter) }:
        result_sum = result_sum + value
    assert(result_counter == 3)
    assert(result_sum == 33)

    print("ok")
