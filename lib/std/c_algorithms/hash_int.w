// Migrated from C
use std.c_algorithms.defs

pub unsafe fn int_hash(__param_vlocation: *mut c_void) -> c_uint {
    var __local_location: *mut c_int

    (__local_location = ((__param_vlocation as *mut c_int)))

    return (((*__local_location) as c_uint))

}
