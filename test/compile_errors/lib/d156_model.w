// A corpus value spelled u64 meets a host C parameter that is 32 bits here.
pub const C_DATA_MODEL: str = "LP64 (test model)"

extern fn host_takes_int(x: i32) -> i32

pub fn seam(n: u64) -> i32:
    unsafe { host_takes_int(n) }
