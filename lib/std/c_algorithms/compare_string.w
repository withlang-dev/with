// Migrated from C
use std.c_algorithms.defs
use std.libc

pub unsafe fn string_equal(__param_string1: *mut c_void, __param_string2: *mut c_void) -> c_int {
    return (if strcmp(((__param_string1 as *mut c_char) as *const c_char), ((__param_string2 as *mut c_char) as *const c_char)) == 0: 1 else: 0)

}

pub unsafe fn string_compare(__param_string1: *mut c_void, __param_string2: *mut c_void) -> c_int {
    var __local_result: c_int

    (__local_result = ((strcmp(((__param_string1 as *mut c_char) as *const c_char), ((__param_string2 as *mut c_char) as *const c_char)) as c_int)))

    if ((if __local_result < 0: 1 else: 0) != 0) {
        return -1

    }
    if ((if __local_result > 0: 1 else: 0) != 0) {
        return 1

    }
    return 0


}

pub unsafe fn string_nocase_equal(__param_string1: *mut c_void, __param_string2: *mut c_void) -> c_int {
    return (if string_nocase_compare(((__param_string1 as *mut c_char) as *mut c_void), ((__param_string2 as *mut c_char) as *mut c_void)) == 0: 1 else: 0)

}

pub unsafe fn string_nocase_compare(__param_string1: *mut c_void, __param_string2: *mut c_void) -> c_int {
    var __local_p1: *mut c_char

    var __local_p2: *mut c_char

    var __local_c1: c_int

    var __local_c2: c_int


    (__local_p1 = ((__param_string1 as *mut c_char)))

    (__local_p2 = ((__param_string2 as *mut c_char)))

    while true {
        (__local_c1 = ((tolower(((unsafe *__local_p1) as c_int)) as c_int)))

        (__local_c2 = ((tolower(((unsafe *__local_p2) as c_int)) as c_int)))

        if ((if __local_c1 != __local_c2: 1 else: 0) != 0) {
            if ((if __local_c1 < __local_c2: 1 else: 0) != 0) {
                return -1

            }
            return 1


        }

        if ((if __local_c1 == 0: 1 else: 0) != 0) {
            break

        }

        (__local_p1 = __local_p1 + 1)

        (__local_p2 = __local_p2 + 1)

    }

    return 0

}
