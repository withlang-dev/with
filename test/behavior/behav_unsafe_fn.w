//! expect-stdout: ok

// Tests: unsafe fn — function-level unsafe context

type Data {
    val: i32,
    flag: bool,
}

unsafe fn read_ptr(p: *const i32) -> i32:
    *p

unsafe fn write_ptr(p: *mut i32, v: i32):
    *p = v

unsafe fn modify_struct(p: *mut Data):
    // Auto-deref through *mut; the unsafe fn body is already an unsafe context.
    p.val = p.val + 10
    p.flag = true

fn test_unsafe_fn_read:
    let x = 42
    let p = &x as *const i32
    let v = unsafe { read_ptr(p) }
    assert(v == 42)

fn test_unsafe_fn_write:
    var x = 0
    let p = &raw mut x as *mut i32
    unsafe { write_ptr(p, 99) }
    assert(x == 99)

fn test_unsafe_fn_struct_deref:
    var d = Data { val: 5, flag: false }
    let p = &raw mut d as *mut Data
    unsafe { modify_struct(p) }
    assert(d.val == 15)
    assert(d.flag == true)

fn main:
    test_unsafe_fn_read()
    test_unsafe_fn_write()
    test_unsafe_fn_struct_deref()
    print("ok")
