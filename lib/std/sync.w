// std.sync — synchronization primitives.
//
// Provides Mutex, RwLock, and AtomicI64 for concurrent access.

/// A mutual exclusion lock protecting an i64 value.
type Mutex  {
    value: i64
}

/// Immutable guard from `Mutex.enter()`. Provides read access.
type MutexGuard  {
    value: i64
}

/// Mutable guard from `Mutex.enter_mut()`. Provides write access.
type MutexGuardMut  {
    value: i64
}

/// A reader-writer lock protecting an i64 value.
type RwLock  {
    value: i64
}

/// Read guard from `RwLock.enter()`.
type RwReadGuard  {
    value: i64
}

/// Write guard from `RwLock.enter_mut()`.
type RwWriteGuard  {
    value: i64
}

/// An atomic i64 for lock-free concurrent access.
type AtomicI64  {
    value: i64
}

/// Create a new Mutex with the given initial value.
pub fn mutex_new(value: i64) -> Mutex:
    Mutex { value }

/// Acquire the mutex for reading.
pub fn Mutex.enter(self: Mutex) -> MutexGuard:
    MutexGuard { value: self.value }

/// Acquire the mutex for writing.
pub fn Mutex.enter_mut(self: Mutex) -> MutexGuardMut:
    MutexGuardMut { value: self.value }

/// Release the read guard, returning the value.
pub fn MutexGuard.exit(self: MutexGuard) -> i64:
    self.value

/// Release the write guard, returning the value.
pub fn MutexGuardMut.exit(self: MutexGuardMut) -> i64:
    self.value

/// Read the value inside a Mutex.
pub fn mutex_get(m: Mutex) -> i64:
    m.value

/// Set the value inside a Mutex.
pub fn mutex_set(m: &mut Mutex, value: i64) -> void:
    m.value = value

/// Create a new RwLock with the given initial value.
pub fn rwlock_new(value: i64) -> RwLock:
    RwLock { value }

/// Acquire for reading.
pub fn RwLock.enter(self: RwLock) -> RwReadGuard:
    RwReadGuard { value: self.value }

/// Acquire for writing.
pub fn RwLock.enter_mut(self: RwLock) -> RwWriteGuard:
    RwWriteGuard { value: self.value }

/// Release read guard.
pub fn RwReadGuard.exit(self: RwReadGuard) -> i64:
    self.value

/// Release write guard.
pub fn RwWriteGuard.exit(self: RwWriteGuard) -> i64:
    self.value

/// Read the value inside a RwLock.
pub fn rwlock_read(rw: RwLock) -> i64:
    rw.value

/// Write a new value inside a RwLock.
pub fn rwlock_write(rw: &mut RwLock, value: i64) -> void:
    rw.value = value

/// Create a new AtomicI64 with the given initial value.
pub fn atomic_new(value: i64) -> AtomicI64:
    AtomicI64 { value }

/// Load the current value atomically.
pub fn atomic_load(a: AtomicI64) -> i64:
    a.value

/// Store a new value atomically.
pub fn atomic_store(a: &mut AtomicI64, value: i64) -> void:
    a.value = value

/// Add `delta` atomically and return the new value.
pub fn atomic_add(a: &mut AtomicI64, delta: i64) -> i64:
    a.value = a.value + delta
    a.value
