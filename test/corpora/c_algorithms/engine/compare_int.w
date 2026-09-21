// Migrated from C
use std.calg_testing.defs

pub unsafe fn int_equal(__param_vlocation1: *mut c_void, __param_vlocation2: *mut c_void) -> c_int {
    var __local_location1: *mut c_int

    var __local_location2: *mut c_int

    (__local_location1 = ((__param_vlocation1 as *mut c_int)))

    (__local_location2 = ((__param_vlocation2 as *mut c_int)))

    return (if (*__local_location1) == (*__local_location2): 1 else: 0)

}

pub unsafe fn int_compare(__param_vlocation1: *mut c_void, __param_vlocation2: *mut c_void) -> c_int {
    var __local_location1: *mut c_int

    var __local_location2: *mut c_int

    (__local_location1 = ((__param_vlocation1 as *mut c_int)))

    (__local_location2 = ((__param_vlocation2 as *mut c_int)))

    if ((if (*__local_location1) < (*__local_location2): 1 else: 0) != 0) {
        return -1

    }
    if ((if (*__local_location1) > (*__local_location2): 1 else: 0) != 0) {
        return 1

    }
    return 0


}
