// std.box — single-owner heap allocation.

use std.traits

extern fn with_alloc(size: i64) -> *i8
extern fn with_free(ptr: *i8) -> Unit
extern fn with_memcpy(dst: *i8, src: *i8, n: i64) -> Unit

/// `Box[T]` owns one heap-allocated `T`.
pub type Box[T] { ptr: *mut T }

pub fn Box.new[T](value: T) -> Box[T]:
    let ptr = with_alloc(sizeof[T]() as i64) as *mut T
    with_memcpy(ptr as *i8, (&raw const value as *const T) as *i8, sizeof[T]() as i64)
    ptr as Box[T]

pub fn Box.as_ref[T](self: &Self) -> &T:
    unsafe { *(self as *const *const T) as &T }

pub fn Box.as_ptr[T](self: &Self) -> *const T:
    unsafe { *(self as *const *const T) }

pub fn Box.into_inner[T](move self: Self) -> T:
    let ptr = self as *mut T
    let value = unsafe { *ptr }
    with_free(ptr as *i8)
    value

impl[T] Deref[T] for Box[T]:
    fn deref(self: &Self) -> &T:
        unsafe { *(self as *const *const T) as &T }

impl[T] Drop for Box[T]:
    fn drop(move self: Self):
        let ptr = self as *mut T
        let value = unsafe { *ptr }
        drop(value)
        with_free(ptr as *i8)
