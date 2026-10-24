// Migrated from C
use std.engines.c_algorithms_testing.defs

pub unsafe fn pointer_hash(__param_location: *mut c_void) -> u32 {
    return (((__param_location as u64) as u32))

}
