// Migrated from C
use std.engines.c_algorithms_testing.defs

// contract: unproved:0:read only
pub unsafe fn int_hash(__param_vlocation: *mut c_void) -> u32 {
    var __local_location: *mut i32

    (__local_location = ((__param_vlocation as *mut i32)))

    return (((*__local_location) as u32))

}
