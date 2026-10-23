//! expect-error: migrated against LP64 (test model)

// D156 (§16.1, law 10): a corpus is compiled against one data model, spelled
// as fixed widths in its text, and the model is recorded in a constant. A
// seam is checked, never assumed: a corpus value spelled `u64` meeting a host
// C parameter that is 32 bits here is a narrowing the seam has to spell,
// and the diagnostic names the model so the reader knows which side is the
// model's width and which the host's.
pub let C_DATA_MODEL: str = "LP64 (test model)"

extern fn host_takes_int(x: i32) -> i32

fn main:
    let n: u64 = 7
    let r = unsafe { host_takes_int(n) }
    print(r)
