//! env: WITH_RT_IN_UNIT=1
//! expect-check-fail: is not comptime-callable: it reaches print -> with_println_str (an extern)

// D104 (§17.1) under D30: a runtime ABI function compiled in-unit is, to
// compile-time code, what the object-linked runtime gives it: no body the
// evaluator runs. Its in-unit body (mostly never checked) read as having no
// forbidden callee, and `print` passed as comptime-callable. The lane twin
// of err_comptime_runtime_call.
comptime fn noisy() -> i32:
    print("hi")
    0

fn main: print(noisy())
