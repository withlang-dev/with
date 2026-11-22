//! expect-stdout: ok

fn test_non_null_pointer_as_option:
    var x: i32 = 42
    let p = (&raw mut x) as *mut i32
    let maybe = p.as_option()
    assert(maybe.is_some())
    assert(unsafe { *maybe.unwrap() } == 42)

fn test_null_mut_pointer_as_option:
    let p: *mut i32 = null
    assert(p.as_option().is_none())

fn test_null_const_pointer_as_option:
    let p: *const i32 = null
    let val = match p.as_option():
        Some(ptr) => unsafe { *ptr }
        None => 0
    assert(val == 0)

fn main:
    test_non_null_pointer_as_option()
    test_null_mut_pointer_as_option()
    test_null_const_pointer_as_option()
    print("ok")
