// std.rc — explicit reference-counted ownership.

use std.collections
use std.traits

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8

type RcControl {
    strong: i64,
    value: *mut u8,
}

/// `Rc[T]` is a single-threaded, explicitly cloned shared owner.
pub type Rc[T] { ptr: *mut u8 }

pub fn Rc.new[T](value: T) -> Rc[T]:
    let value_ptr = with_alloc(sizeof[T]() as i64) as *mut T
    // Move-assign through the pointer: consumes `value` without running its
    // drop (the heap slot now owns it) — the memcpy-of-&raw idiom left the
    // caller's copy owned and double-dropped the payload (std.box had the
    // identical bug).
    unsafe { *value_ptr = value }
    let ptr = with_alloc(sizeof[RcControl]() as i64) as *mut RcControl
    unsafe { (*ptr).strong = 1 }
    unsafe { (*ptr).value = value_ptr as *mut u8 }
    Rc { ptr: ptr as *mut u8 }

impl[T] Rc[T]:
    pub fn clone() -> Rc[T]:
        let ptr = self.ptr as *mut RcControl
        unsafe { (*ptr).strong = (*ptr).strong + 1 }
        Rc { ptr: self.ptr }

    pub fn strong_count() -> i64:
        let ptr = self.ptr as *mut RcControl
        unsafe { (*ptr).strong }

    pub fn as_ref() -> &T:
        let ptr = self.ptr as *mut RcControl
        unsafe { (*ptr).value as *mut T as &T }

impl[T] Deref[T] for Rc[T]:
    fn deref() -> &T:
        self.as_ref()

impl[T] Drop for Rc[T]:
    move fn drop():
        let ptr = self.ptr as *mut RcControl
        let next = unsafe { (*ptr).strong } - 1
        unsafe { (*ptr).strong = next }
        if next == 0:
            let value_ptr = unsafe { (*ptr).value } as *mut T
            let value = unsafe { *value_ptr }
            drop(value)
            with_free(value_ptr as *mut u8)
            with_free(ptr as *mut u8)

/// `Arc[T]` is a thread-safe, explicitly cloned shared owner.
pub type Arc[T] { ptr: *mut u8 }

pub fn Arc.new[T](value: T) -> Arc[T]:
    let value_ptr = with_alloc(sizeof[T]() as i64) as *mut T
    unsafe { *value_ptr = value }
    let ptr = with_alloc(sizeof[RcControl]() as i64) as *mut RcControl
    unsafe { (*ptr).value = value_ptr as *mut u8 }
    let strong_ptr = &raw mut (unsafe *ptr).strong as *mut i64
    unsafe *strong_ptr = 1
    Arc { ptr: ptr as *mut u8 }

impl[T] Arc[T]:
    pub fn clone() -> Arc[T]:
        let ptr = self.ptr as *mut RcControl
        let strong = &raw mut (unsafe *ptr).strong as *mut Atomic[i64]
        let _ = (unsafe *strong).fetch_add(1, .AcqRel)
        Arc { ptr: self.ptr }

    pub fn strong_count() -> i64:
        let ptr = self.ptr as *mut RcControl
        let strong = &raw const (unsafe *ptr).strong as *const Atomic[i64]
        let n = (unsafe *strong).load(.Acquire)
        n

    pub fn as_ref() -> &T:
        let ptr = self.ptr as *mut RcControl
        unsafe { (*ptr).value as *mut T as &T }

impl[T] Deref[T] for Arc[T]:
    fn deref() -> &T:
        self.as_ref()

impl[T] Drop for Arc[T]:
    move fn drop():
        let ptr = self.ptr as *mut RcControl
        let strong = &raw mut (unsafe *ptr).strong as *mut Atomic[i64]
        let old = (unsafe *strong).fetch_sub(1, .AcqRel)
        if old == 1:
            let value_ptr = unsafe { (*ptr).value } as *mut T
            let value = unsafe { *value_ptr }
            drop(value)
            with_free(value_ptr as *mut u8)
            with_free(ptr as *mut u8)
