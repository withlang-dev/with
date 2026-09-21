//! expect-stdout: ok

// C's `((void (*)(void *))-1)` (sqlite3.h's SQLITE_TRANSIENT) is all ones at
// pointer width. A signed integer cast to a pointer widens before it
// converts: `inttoptr` zero-extends, which made the local 0x00000000FFFFFFFF,
// and the module-level binding was emitted as an `i32` global and read back
// as eight bytes, so its upper half was whatever sat next to it.
// sqlite3_bind_text(..., SQLITE_TRANSIENT) then jumped to that address.

let TRANSIENT: unsafe extern "C" fn(*mut c_void) -> Unit = (-1 as extern "C" fn(*mut c_void) -> Unit)
let STATIC: unsafe extern "C" fn(*mut c_void) -> Unit = (0 as extern "C" fn(*mut c_void) -> Unit)
let HIGH: *const u8 = (-4096 as *const u8)

fn main:
    let all_ones = 0usize -% 1
    let local: unsafe extern "C" fn(*mut c_void) -> Unit = (-1 as extern "C" fn(*mut c_void) -> Unit)
    assert(local as usize == all_ones)
    assert(TRANSIENT as usize == all_ones)
    assert(STATIC as usize == 0)
    assert(HIGH as usize == all_ones - 4095)

    let minus_one = -1
    assert((minus_one as *const u8) as usize == all_ones)
    // An unsigned source keeps zero-extending.
    let small: u32 = 4294967295
    assert((small as *const u8) as usize == 4294967295)
    print("ok")
