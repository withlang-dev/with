// Migrated from C
use std.calg_testing.defs

pub unsafe fn pointer_equal(__param_location1: *mut c_void, __param_location2: *mut c_void) -> c_int {
    return (if __param_location1 == __param_location2: 1 else: 0)

}

pub unsafe fn pointer_compare(__param_location1: *mut c_void, __param_location2: *mut c_void) -> c_int {
    if ((if __param_location1 < __param_location2: 1 else: 0) != 0) {
        return -1

    }
    if ((if __param_location1 > __param_location2: 1 else: 0) != 0) {
        return 1

    }
    return 0


}
