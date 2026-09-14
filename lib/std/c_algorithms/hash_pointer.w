// Migrated from C
use std.c_algorithms.defs

pub unsafe fn pointer_hash(__param_location: *mut c_void) -> c_uint {
    return (((__param_location as c_ulong) as c_uint))

}
