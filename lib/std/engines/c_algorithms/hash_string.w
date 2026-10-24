// Migrated from C
use std.engines.c_algorithms.defs
use std.libc

pub unsafe fn string_hash(__param_string: *mut c_void) -> u32 {
    var __local_result: u32 = ((5381 as u32))

    var __local_p: *mut u8

    (__local_p = ((__param_string as *mut u8)))

    while ((if (*__local_p) != 0: 1 else: 0) != 0) {
        (__local_result = ((((((((__local_result as u32) << (5 as u32)) as u32) +% (__local_result as u32)) as u32) +% (((*__local_p) as i32) as u32)) as u32)))

        (__local_p = __local_p + 1)

    }

    return __local_result

}

pub unsafe fn string_nocase_hash(__param_string: *mut c_void) -> u32 {
    var __local_result: u32 = ((5381 as u32))

    var __local_p: *mut u8

    (__local_p = ((__param_string as *mut u8)))

    while ((if (*__local_p) != 0: 1 else: 0) != 0) {
        (__local_result = ((((((((__local_result as u32) << (5 as u32)) as u32) +% (__local_result as u32)) as u32) +% (tolower(((*__local_p) as i32)) as u32)) as u32)))

        (__local_p = __local_p + 1)

    }

    return __local_result

}
