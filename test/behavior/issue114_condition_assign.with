//! expect-stdout: ok

use c_import("issue114_condition_assign.h")

fn main:
    assert(issue114_if_assign(42) == 17)
    assert(issue114_if_assign(5) == 5)
    assert(issue114_compare_assign(3) == 13)
    assert(issue114_compare_assign(2) == 2)
    assert(issue114_logical_assign(4) == 24)
    assert(issue114_logical_assign(0) == 0)
    assert(issue114_while_assign(4) == 6)
    assert(issue114_for_assign(4) == 6)
    assert(issue114_do_assign(3) == 6)
    print("ok")
