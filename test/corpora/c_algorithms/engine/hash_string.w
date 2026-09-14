// Migrated from C
use std.calg_testing.defs
use std.libc

pub unsafe fn string_hash(__param_string: *mut c_void) -> c_uint {
    var __local_result: c_uint = ((5381 as c_uint))

    var __local_p: *mut u8

    (__local_p = ((__param_string as *mut u8)))

    while ((if (unsafe *__local_p) != 0: 1 else: 0) != 0) {
        (__local_result = ((((((((__local_result as c_uint) << (5 as c_uint)) as c_uint) +% (__local_result as c_uint)) as c_uint) +% (((unsafe *__local_p) as c_int) as c_uint)) as c_uint)))

        (__local_p = __local_p + 1)

    }

    return __local_result

}

pub unsafe fn string_nocase_hash(__param_string: *mut c_void) -> c_uint {
    var __local_result: c_uint = ((5381 as c_uint))

    var __local_p: *mut u8

    (__local_p = ((__param_string as *mut u8)))

    while ((if (unsafe *__local_p) != 0: 1 else: 0) != 0) {
        (__local_result = ((((((((__local_result as c_uint) << (5 as c_uint)) as c_uint) +% (__local_result as c_uint)) as c_uint) +% ((tolower(((unsafe *__local_p) as c_int)) as c_uint) as c_uint)) as c_uint)))

        (__local_p = __local_p + 1)

    }

    return __local_result

}
