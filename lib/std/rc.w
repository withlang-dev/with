// std.rc — explicit reference-counted ownership.

use std.collections
use std.traits

extern fn with_alloc(size: i64) -> *i8
extern fn with_free(ptr: *i8) -> Unit
extern fn with_memcpy(dst: *i8, src: *i8, n: i64) -> Unit

type RcControl {
    strong: i64,
    value: *mut u8,
}

/// `Rc[T]` is a single-threaded, explicitly cloned shared owner.
pub type Rc[T] { ptr: *mut u8 }

pub fn Rc.new[T](value: T) -> Rc[T]:
    let value_ptr = with_alloc(sizeof[T]() as i64) as *mut T
    with_memcpy(value_ptr as *i8, (&raw const (move value) as *const T) as *i8, sizeof[T]() as i64)
    let ptr = with_alloc(sizeof[RcControl]() as i64) as *mut RcControl
    (unsafe *ptr).strong = 1
    (unsafe *ptr).value = value_ptr as *mut u8
    Rc { ptr: ptr as *mut u8 }

pub fn Rc.clone[T](self: &Self) -> Rc[T]:
    let ptr = unsafe { *(self as *const *mut u8) } as *mut RcControl
    (unsafe *ptr).strong = (unsafe *ptr).strong + 1
    Rc { ptr: ptr as *mut u8 }

pub fn Rc.strong_count[T](self: &Self) -> i64:
    let ptr = unsafe { *(self as *const *mut u8) } as *mut RcControl
    (unsafe *ptr).strong

pub fn Rc.as_ref[T](self: &Self) -> &T:
    let inner = unsafe { *(self as *const *mut u8) } as *mut RcControl
    (unsafe *inner).value as *mut T as &T

impl[T] Deref[T] for Rc[T]:
    fn deref(self: &Self) -> &T:
        self.as_ref()

impl[T] Drop for Rc[T]:
    fn drop(move self: Self):
        let ptr = self.ptr as *mut RcControl
        let next = (unsafe *ptr).strong - 1
        (unsafe *ptr).strong = next
        if next == 0:
            let value_ptr = (unsafe *ptr).value as *mut T
            let value = unsafe *value_ptr
            drop(value)
            with_free(value_ptr as *i8)
            with_free(ptr as *i8)

/// `Arc[T]` is a thread-safe, explicitly cloned shared owner.
pub type Arc[T] { ptr: *mut u8 }

pub fn Arc.new[T](value: T) -> Arc[T]:
    let value_ptr = with_alloc(sizeof[T]() as i64) as *mut T
    with_memcpy(value_ptr as *i8, (&raw const (move value) as *const T) as *i8, sizeof[T]() as i64)
    let ptr = with_alloc(sizeof[RcControl]() as i64) as *mut RcControl
    (unsafe *ptr).value = value_ptr as *mut u8
    let strong_ptr = &raw mut (unsafe *ptr).strong as *mut i64
    unsafe *strong_ptr = 1
    Arc { ptr: ptr as *mut u8 }

pub fn Arc.clone[T](self: &Self) -> Arc[T]:
    let ptr = unsafe { *(self as *const *mut u8) } as *mut RcControl
    let strong = &raw mut (unsafe *ptr).strong as *mut Atomic[i64]
    let _ = (unsafe *strong).fetch_add(1, .AcqRel)
    Arc { ptr: ptr as *mut u8 }

pub fn Arc.strong_count[T](self: &Self) -> i64:
    let ptr = unsafe { *(self as *const *mut u8) } as *mut RcControl
    let strong = &raw const (unsafe *ptr).strong as *const Atomic[i64]
    (unsafe *strong).load(.Acquire)

pub fn Arc.as_ref[T](self: &Self) -> &T:
    let inner = unsafe { *(self as *const *mut u8) } as *mut RcControl
    (unsafe *inner).value as *mut T as &T

impl[T] Deref[T] for Arc[T]:
    fn deref(self: &Self) -> &T:
        self.as_ref()

impl[T] Drop for Arc[T]:
    fn drop(move self: Self):
        let ptr = self.ptr as *mut RcControl
        let strong = &raw mut (unsafe *ptr).strong as *mut Atomic[i64]
        let old = (unsafe *strong).fetch_sub(1, .AcqRel)
        if old == 1:
            let value_ptr = (unsafe *ptr).value as *mut T
            let value = unsafe *value_ptr
            drop(value)
            with_free(value_ptr as *i8)
            with_free(ptr as *i8)
