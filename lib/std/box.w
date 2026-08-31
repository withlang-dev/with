// std.box — single-owner heap allocation.

use std.traits

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8

/// `Box[T]` owns one heap-allocated `T`.
pub type Box[T] { ptr: *mut T }

pub fn Box.new[T](value: T) -> Box[T]:
    let ptr = with_alloc(sizeof[T]() as i64) as *mut T
    // Move-assign through the pointer: consumes `value` without running its
    // drop (the heap slot now owns it). The old memcpy of `&raw const value`
    // left `value` owned on this side, so the payload was dropped while the
    // heap kept the same bytes — behav_box_drop's double-drop.
    unsafe { *ptr = value }
    ptr as Box[T]

impl[T] Box[T]:
    pub fn as_ref() -> &T:
        unsafe { *(self as *const *const T) as &T }

    pub fn as_ptr() -> *const T:
        unsafe { *(self as *const *const T) }

    pub move fn into_inner() -> T:
        let ptr = self as *mut T
        let value = unsafe { *ptr }
        with_free(ptr as *mut u8)
        value

impl[T] Deref[T] for Box[T]:
    fn deref() -> &T:
        unsafe { *(self as *const *const T) as &T }

impl[T] Drop for Box[T]:
    move fn drop():
        let ptr = self as *mut T
        let value = unsafe { *ptr }
        drop(value)
        with_free(ptr as *mut u8)
