// Migrated from C
use std.engines.c_algorithms_testing.defs

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn pointer_equal(__param_location1: *mut c_void, __param_location2: *mut c_void) -> i32 {
    return (if __param_location1 == __param_location2: 1 else: 0)

}

// contract: unproved:0:read only,unproved:1:read only
pub unsafe fn pointer_compare(__param_location1: *mut c_void, __param_location2: *mut c_void) -> i32 {
    if (__param_location1 < __param_location2) {
        return -1

    }
    if (__param_location1 > __param_location2) {
        return 1

    }
    return 0


}
