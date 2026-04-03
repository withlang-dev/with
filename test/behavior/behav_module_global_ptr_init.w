var gp: *const u8 = 0 as *const u8
var flag: i32 = 0

fn main:
    gp = "hi" as *const u8
    assert(flag == 0, "pointer global write corrupted adjacent global")
    print("ok")
