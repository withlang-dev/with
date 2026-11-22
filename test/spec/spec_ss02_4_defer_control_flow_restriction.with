// Spec test: Section 2.4 — Defer Control Flow Restriction (formerly 25.73)

var DEFER_CONTROL_TRACE = ""

fn defer_control_close_ok -> Result[i32, str]:
    Ok(1)

fn defer_control_local_cleanup:
    let cleanup = defer_control_close_ok()
    defer:
        let _ = match cleanup:
            Ok(n) => n
            Err(_) => 0
        DEFER_CONTROL_TRACE = DEFER_CONTROL_TRACE ++ "D"
    DEFER_CONTROL_TRACE = DEFER_CONTROL_TRACE ++ "B"

// PASS: handle errors locally inside defer instead of using non-local `?`.
fn test_defer_control_local_error_handling:
    DEFER_CONTROL_TRACE = ""
    defer_control_local_cleanup()
    assert(DEFER_CONTROL_TRACE == "BD")
