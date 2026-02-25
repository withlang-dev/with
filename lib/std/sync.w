// std.sync — synchronization primitives for bootstrap.
//
// Type declarations in the current bootstrap parser are non-generic.
// This module provides a stable i64-focused API surface.

type Mutex = {
    value: i64
}

type RwLock = {
    value: i64
}

type AtomicI64 = {
    value: i64
}

pub fn mutex_new(value: i64) -> Mutex =
    Mutex { value }

pub fn mutex_get(m: Mutex) -> i64 =
    m.value

pub fn mutex_set(m: *mut Mutex, value: i64) -> void =
    m.value = value

pub fn rwlock_new(value: i64) -> RwLock =
    RwLock { value }

pub fn rwlock_read(rw: RwLock) -> i64 =
    rw.value

pub fn rwlock_write(rw: *mut RwLock, value: i64) -> void =
    rw.value = value

pub fn atomic_new(value: i64) -> AtomicI64 =
    AtomicI64 { value }

pub fn atomic_load(a: AtomicI64) -> i64 =
    a.value

pub fn atomic_store(a: *mut AtomicI64, value: i64) -> void =
    a.value = value

pub fn atomic_add(a: *mut AtomicI64, delta: i64) -> i64 =
    a.value = a.value + delta
    a.value
