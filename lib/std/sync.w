// std.sync — synchronization primitives.
//
// Provides Mutex, RwLock, and Atomic for concurrent access.

/// A mutual exclusion lock protecting an i64 value.
type Mutex  {
    value: i64
}

/// Immutable guard from `Mutex.enter()`. Provides read access.
@[no_await_guard]
type MutexGuard ephemeral {
    value: i64
}

/// Mutable guard from `Mutex.enter_mut()`. Provides write access.
@[no_await_guard]
type MutexGuardMut ephemeral {
    value: i64
}

/// A reader-writer lock protecting an i64 value.
type RwLock  {
    value: i64
}

/// Read guard from `RwLock.enter()`.
@[no_await_guard]
type RwReadGuard ephemeral {
    value: i64
}

/// Write guard from `RwLock.enter_mut()`.
@[no_await_guard]
type RwWriteGuard ephemeral {
    value: i64
}

/// Memory ordering for atomic operations.
pub enum Order: i32:
    Relaxed = 0
    Acquire = 1
    Release = 2
    AcqRel = 3
    SeqCst = 4

/// Atomic memory fence. Enforces ordering without an associated operation.
pub fn fence(order: Order) -> Unit:
    // Compiler intrinsic: MIR lowering replaces this body.
    0

/// Lock-free atomic operations on integer and pointer types.
pub type Atomic[T] {
    val: T,
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

impl Scoped[i64] for MutexGuard:    fn with_enter(self:
    &Self) -> i64:
        self.value

    fn with_exit(self: &Self) -> Unit:
        ()

impl ScopedMut[i64] for MutexGuardMut:    fn with_enter_mut(self:
    &Self) -> i64:
        self.value

    fn with_exit_mut(mut self: Self, value: i64) -> Unit:
        self.value = value

/// Read the value inside a Mutex.
pub fn mutex_get(m: Mutex) -> i64:
    m.value

/// Set the value inside a Mutex (mutating receiver).
pub fn Mutex.set(mut self: Mutex, value: i64) -> Unit:
    self.value = value

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

/// Write a new value inside a RwLock (mutating receiver).
pub fn RwLock.write(mut self: RwLock, value: i64) -> Unit:
    self.value = value

/// Compatibility alias for old code; prefer `Atomic[i64]`.
pub type AtomicI64 = Atomic[i64]

/// Create a new AtomicI64 with the given initial value.
pub fn atomic_new(value: i64) -> AtomicI64:
    AtomicI64 { val: value }

/// Load the current value atomically.
pub fn atomic_load(a: &AtomicI64) -> i64:
    a.load(.SeqCst)

/// Add `delta` atomically and return the new value.
pub fn Atomic.add(mut self: Atomic[i64], delta: i64) -> i64:
    self.fetch_add(delta, .SeqCst) + delta
