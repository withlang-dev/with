//! expect-check-fail: 'variadic param …' is stated twice; one variadic function has one closed set of cases
//! expect-check-fail: = help: put every case under one 'variadic param … selected by param …:' clause

// #3129 (§16.2b.5): one variadic function has one set of cases.
use c_import("enum opt { OPT_A = 1, OPT_B = 2 };\nint set_opt(int which, ...);\n")

c contract opts:
    fn set_opt
        variadic param 1 selected by param which:
            case OPT_A: c_long
        variadic param 1 selected by param which:
            case OPT_B: c_long

fn main:
    print("unreachable")
