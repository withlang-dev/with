// Spec test: Section 20b - Denied Patterns
//
// Positive coverage lives here. The denied forms themselves are covered by
// focused compile-error fixtures:
// - err_suspend_under_guard.w
// - err_may_suspend_call_under_no_await_guard.w
// - err_unused_task.w
// - err_unnecessary_unsafe_block.w
// - err_implicit_narrowing.w
// - err_sign_conversion.w
// - err_unreachable_after_return.w
// - err_unreachable_after_break.w
// - err_unreachable_after_continue.w

fn fallible_ok() -> Result[i32, str]:
    Ok(7)

fn fallible_err() -> Result[i32, str]:
    Err("bad")

fn test_result_discard_has_no_required_ceremony:
    fallible_ok()
    let _ = fallible_err()
    assert(true)

fn test_explicit_narrowing_allowed:
    let big: i64 = 42
    let small: i32 = big as i32
    assert(small == 42)

fn test_implicit_widening_allowed:
    let small: i32 = 42
    let big: i64 = small
    assert(big == 42)

fn test_necessary_unsafe_allowed:
    var x = 5
    let p = (&raw mut x) as *mut i32
    unsafe { *p = 6 }
    assert(x == 6)

fn conditional_value(flag: bool) -> i32:
    if flag: return 42
    0

fn test_conditionally_reachable_code_allowed:
    assert(conditional_value(true) == 42)
    assert(conditional_value(false) == 0)
