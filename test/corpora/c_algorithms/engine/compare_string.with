// Migrated from C
use std.engines.c_algorithms_testing.defs
use std.libc

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn string_equal(__param_string1: *mut c_void, __param_string2: *mut c_void) -> i32 {
    return (if strcmp(((__param_string1 as *mut c_char) as *const c_char), ((__param_string2 as *mut c_char) as *const c_char)) == 0: 1 else: 0)

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn string_compare(__param_string1: *mut c_void, __param_string2: *mut c_void) -> i32 {
    var __local_result: i32

    (__local_result = ((strcmp(((__param_string1 as *mut c_char) as *const c_char), ((__param_string2 as *mut c_char) as *const c_char)) as i32)))

    if (__local_result < 0) {
        return -1

    }
    if (__local_result > 0) {
        return 1

    }
    return 0


}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn string_nocase_equal(__param_string1: *mut c_void, __param_string2: *mut c_void) -> i32 {
    return (if string_nocase_compare(((__param_string1 as *mut c_char) as *mut c_void), ((__param_string2 as *mut c_char) as *mut c_void)) == 0: 1 else: 0)

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn string_nocase_compare(__param_string1: *mut c_void, __param_string2: *mut c_void) -> i32 {
    var __local_p1: *mut c_char

    var __local_p2: *mut c_char

    var __local_c1: i32

    var __local_c2: i32


    (__local_p1 = ((__param_string1 as *mut c_char)))

    (__local_p2 = ((__param_string2 as *mut c_char)))

    while true {
        (__local_c1 = ((tolower(((*__local_p1) as i32)) as i32)))

        (__local_c2 = ((tolower(((*__local_p2) as i32)) as i32)))

        if (__local_c1 != __local_c2) {
            if (__local_c1 < __local_c2) {
                return -1

            }
            return 1


        }

        if (__local_c1 == 0) {
            break

        }

        (__local_p1 = __local_p1 + 1)

        (__local_p2 = __local_p2 + 1)

    }

    return 0

}
