// Migrated from C
use std.engines.c_algorithms.defs

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn int_equal(__param_vlocation1: *mut c_void, __param_vlocation2: *mut c_void) -> i32 {
    var __local_location1: *mut i32

    var __local_location2: *mut i32

    (__local_location1 = ((__param_vlocation1 as *mut i32)))

    (__local_location2 = ((__param_vlocation2 as *mut i32)))

    return (if (*__local_location1) == (*__local_location2): 1 else: 0)

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn int_compare(__param_vlocation1: *mut c_void, __param_vlocation2: *mut c_void) -> i32 {
    var __local_location1: *mut i32

    var __local_location2: *mut i32

    (__local_location1 = ((__param_vlocation1 as *mut i32)))

    (__local_location2 = ((__param_vlocation2 as *mut i32)))

    if ((*__local_location1) < (*__local_location2)) {
        return -1

    }
    if ((*__local_location1) > (*__local_location2)) {
        return 1

    }
    return 0


}
