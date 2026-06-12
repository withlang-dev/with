//! expect-stdout: ok

fn takes_const_ptr(p: *const i32) -> bool:
    p == null

fn takes_mut_ptr(p: *mut i32) -> bool:
    null == p

fn takes_optional_ptr(p: Option[*mut i32]) -> bool:
    p.is_none()

fn add_one(value: i32) -> i32:
    value + 1

fn main:
    let const_ptr: *const i32 = null
    assert(const_ptr == null)
    assert(null == const_ptr)

    let mut_ptr: *mut i32 = null
    assert(mut_ptr == null)
    assert(takes_const_ptr(null))
    assert(takes_mut_ptr(null))

    let optional: Option[*mut i32] = null
    assert(optional.is_none())
    assert(takes_optional_ptr(null))

    let no_callback: extern "C" fn(i32) -> i32 = null
    assert(no_callback == null)

    let callback: extern "C" fn(i32) -> i32 = add_one
    assert(callback != null)
    assert(callback(41) == 42)

    print("ok")
