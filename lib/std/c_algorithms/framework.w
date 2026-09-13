// Migrated from C
use std.c_algorithms.defs
use std.c_algorithms.alloc_testing
use std.libc

pub unsafe fn run_tests(__param_tests: *mut extern "C" fn() -> Unit) -> Unit {
    var __local_i: c_int

    (__local_i = ((0 as c_int)))

    while ((if (unsafe __param_tests[__local_i]) != null: 1 else: 0) != 0) {
        run_test((unsafe __param_tests[__local_i]))


        (__local_i = __local_i + 1)

    }


}

fn run_test(__param_test: extern "C" fn() -> Unit) -> Unit {
    alloc_test_set_limit((-1 as c_int))

    __param_test()

    if ((((if not ((if alloc_test_get_allocated() == 0: 1 else: 0) != 0): 1 else: 0) as c_long) as c_long) != 0) {
        __assert_rtn(c"run_test".ptr, c"framework.c".ptr, (41 as c_int), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

}
