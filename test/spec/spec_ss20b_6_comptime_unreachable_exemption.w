// Spec test: Section 20b.6 — Comptime Unreachable Exemption (formerly 25.66)
//
// Code following a `comptime if` that returns is NOT flagged as unreachable:
// the branch may be erased at compile time, leaving the trailing code live.
// (The negative case — code after an *unconditional* return — is covered by
// test/compile_errors/err_unreachable_after_return.w.)

// PASS: trailing code after a comptime-if return is reachable when the branch
// is erased.
fn compute(x: i32) -> i32:
    comptime if false:
        return 0
    x * x + 1

fn test_comptime_if_return_is_exempt:
    assert(compute(3) == 10)
    assert(compute(0) == 1)

// PASS: a plain conditional return is also not unreachable — control only
// leaves the block when the condition holds.
fn classify(flag: bool) -> i32:
    if flag:
        return 42
    99

fn test_conditional_return_is_reachable:
    assert(classify(true) == 42)
    assert(classify(false) == 99)
