// Migrated from C
use std.engines.c_algorithms.defs
use std.engines.c_algorithms.alloc_testing
use std.libc
use std.option

// contract: unproved:0:indexed as an array
pub unsafe fn run_tests(__param_tests: *mut Option[extern "C" fn() -> Unit]) writes allocation_limit {
    var __local_i: i32

    (__local_i = ((0 as i32)))

    while ((__param_tests[__local_i]) != null) {
        run_test((__param_tests[__local_i]).unwrap())


        (__local_i = __local_i + 1)

    }


}

fn run_test(__param_test: extern "C" fn() -> Unit) -> Unit {
    alloc_test_set_limit((-1 as i32))

    __param_test()

    if ((if not (alloc_test_get_allocated() == 0): 1 else: 0) as i64) {
        __assert_rtn(c"run_test".ptr, c"framework.c".ptr, (41 as i32), c"alloc_test_get_allocated() == 0".ptr)
    } else {
        0
    }

}
