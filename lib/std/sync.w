// std.sync — synchronization primitives.

extern fn with_alloc(size: i64) -> *i8
extern fn with_free(ptr: *i8) -> Unit
extern fn with_memcpy(dst: *i8, src: *i8, n: i64) -> Unit
extern fn with_fiber_in_fiber() -> i32
extern fn with_fiber_yield() -> Unit
extern fn with_runtime_has_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

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

type MutexState {
    locked: i32,
    value: *mut u8,
}

type RwLockState {
    state: i32,
    value: *mut u8,
}

/// A mutual exclusion lock protecting a `T`.
///
/// With mutexes are non-poisoning: a panic while a guard is held releases the
/// guard through normal cleanup and does not permanently poison the lock.
pub type Mutex[T] {
    ptr: *mut u8,
}

/// Immutable guard from `Mutex.enter()`. Provides scoped read access.
@[no_await_guard]
pub type MutexGuard[T] ephemeral {
    ptr: *mut u8,
}

/// Mutable guard from `Mutex.enter_mut()`. Provides scoped write access.
@[no_await_guard]
pub type MutexGuardMut[T] ephemeral {
    ptr: *mut u8,
}

/// A reader-writer lock protecting a `T`.
pub type RwLock[T] {
    ptr: *mut u8,
}

/// Read guard from `RwLock.enter()`.
@[no_await_guard]
pub type RwReadGuard[T] ephemeral {
    ptr: *mut u8,
}

/// Write guard from `RwLock.enter_mut()`.
@[no_await_guard]
pub type RwWriteGuard[T] ephemeral {
    ptr: *mut u8,
}

fn sync_wait_for_progress():
    if with_fiber_in_fiber() != 0:
        with_fiber_yield()
        return
    if with_runtime_has_fibers() != 0:
        with_runtime_run_one_step()

/// Create a new generic mutex with the given initial value.
pub fn Mutex.new[T](value: T) -> Mutex[T]:
    let value_ptr = with_alloc(sizeof[T]() as i64) as *mut T
    with_memcpy(value_ptr as *i8, (&raw const (move value) as *const T) as *i8, sizeof[T]() as i64)
    let state = with_alloc(sizeof[MutexState]() as i64) as *mut MutexState
    (unsafe *state).locked = 0
    (unsafe *state).value = value_ptr as *mut u8
    Mutex { ptr: state as *mut u8 }

/// Compatibility constructor for legacy i64 mutex tests and examples.
pub fn mutex_new(value: i64) -> Mutex[i64]:
    Mutex.new(value)

/// Acquire the mutex for reading.
pub fn Mutex.enter[T](self: &Self) -> MutexGuard[T]:
    let state = self.ptr as *mut MutexState
    let locked = (&raw mut (unsafe *state).locked as *mut i32) as *mut Atomic[i32]
    while (unsafe *locked).swap(1, .Acquire) != 0:
        sync_wait_for_progress()
    MutexGuard { ptr: self.ptr }

/// Acquire the mutex for writing.
pub fn Mutex.enter_mut[T](self: &Self) -> MutexGuardMut[T]:
    let state = self.ptr as *mut MutexState
    let locked = (&raw mut (unsafe *state).locked as *mut i32) as *mut Atomic[i32]
    while (unsafe *locked).swap(1, .Acquire) != 0:
        sync_wait_for_progress()
    MutexGuardMut { ptr: self.ptr }

/// Release the read guard, returning a Copy snapshot of the current value.
pub fn MutexGuard.exit[T: Copy](move self: Self) -> T:
    let state = self.ptr as *mut MutexState
    let value = unsafe *((unsafe *state).value as *mut T)
    let locked = (&raw mut (unsafe *state).locked as *mut i32) as *mut Atomic[i32]
    (unsafe *locked).store(0, .Release)
    value

/// Release the write guard, returning a Copy snapshot of the current value.
pub fn MutexGuardMut.exit[T: Copy](move self: Self) -> T:
    let state = self.ptr as *mut MutexState
    let value = unsafe *((unsafe *state).value as *mut T)
    let locked = (&raw mut (unsafe *state).locked as *mut i32) as *mut Atomic[i32]
    (unsafe *locked).store(0, .Release)
    value

impl[T] Scoped[&T] for MutexGuard[T]:
    fn with_enter(self: &Self) -> &T:
        let state = self.ptr as *mut MutexState
        unsafe { (unsafe *state).value as &T }

    fn with_exit(self: &Self) -> Unit:
        let state = self.ptr as *mut MutexState
        let locked = (&raw mut (unsafe *state).locked as *mut i32) as *mut Atomic[i32]
        (unsafe *locked).store(0, .Release)

impl[T] ScopedMut[T] for MutexGuardMut[T]:
    fn with_enter_mut(self: &Self) -> T:
        let state = self.ptr as *mut MutexState
        unsafe *((unsafe *state).value as *mut T)

    fn with_exit_mut(move self: Self, value: T) -> Unit:
        let state = self.ptr as *mut MutexState
        with_memcpy((unsafe *state).value as *i8, (&raw const (move value) as *const T) as *i8, sizeof[T]() as i64)
        let locked = (&raw mut (unsafe *state).locked as *mut i32) as *mut Atomic[i32]
        (unsafe *locked).store(0, .Release)

/// Read the value inside an i64 Mutex.
pub fn mutex_get(m: &Mutex[i64]) -> i64:
    let guard = m.enter()
    guard.exit()

/// Set the value inside a Mutex.
pub fn Mutex.set[T](self: &Self, value: T) -> Unit:
    let state = self.ptr as *mut MutexState
    let locked = (&raw mut (unsafe *state).locked as *mut i32) as *mut Atomic[i32]
    while (unsafe *locked).swap(1, .Acquire) != 0:
        sync_wait_for_progress()
    let value_ptr = (unsafe *state).value as *mut T
    let old = unsafe *value_ptr
    drop(old)
    with_memcpy(value_ptr as *i8, (&raw const (move value) as *const T) as *i8, sizeof[T]() as i64)
    (unsafe *locked).store(0, .Release)

impl[T] Drop for Mutex[T]:
    fn drop(move self: Self):
        let state = self.ptr as *mut MutexState
        let value_ptr = (unsafe *state).value as *mut T
        let value = unsafe *value_ptr
        drop(value)
        with_free(value_ptr as *i8)
        with_free(state as *i8)

/// Create a new generic reader-writer lock with the given initial value.
pub fn RwLock.new[T](value: T) -> RwLock[T]:
    let value_ptr = with_alloc(sizeof[T]() as i64) as *mut T
    with_memcpy(value_ptr as *i8, (&raw const (move value) as *const T) as *i8, sizeof[T]() as i64)
    let state = with_alloc(sizeof[RwLockState]() as i64) as *mut RwLockState
    (unsafe *state).state = 0
    (unsafe *state).value = value_ptr as *mut u8
    RwLock { ptr: state as *mut u8 }

/// Compatibility constructor for legacy i64 RwLock tests and examples.
pub fn rwlock_new(value: i64) -> RwLock[i64]:
    RwLock.new(value)

/// Acquire for reading.
pub fn RwLock.enter[T](self: &Self) -> RwReadGuard[T]:
    let state = self.ptr as *mut RwLockState
    let word = (&raw mut (unsafe *state).state as *mut i32) as *mut Atomic[i32]
    while true:
        let old = (unsafe *word).load(.Acquire)
        if old >= 0:
            match (unsafe *word).compare_exchange(old, old + 1, .Acquire, .Relaxed):
                Ok(_) => return RwReadGuard { ptr: self.ptr }
                Err(_) => ()
        sync_wait_for_progress()
    RwReadGuard { ptr: self.ptr }

/// Acquire for writing.
pub fn RwLock.enter_mut[T](self: &Self) -> RwWriteGuard[T]:
    let state = self.ptr as *mut RwLockState
    let word = (&raw mut (unsafe *state).state as *mut i32) as *mut Atomic[i32]
    while true:
        match (unsafe *word).compare_exchange(0, -1, .Acquire, .Relaxed):
            Ok(_) => return RwWriteGuard { ptr: self.ptr }
            Err(_) => ()
        sync_wait_for_progress()
    RwWriteGuard { ptr: self.ptr }

/// Release read guard, returning a Copy snapshot of the current value.
pub fn RwReadGuard.exit[T: Copy](move self: Self) -> T:
    let state = self.ptr as *mut RwLockState
    let value = unsafe *((unsafe *state).value as *mut T)
    let word = (&raw mut (unsafe *state).state as *mut i32) as *mut Atomic[i32]
    let _ = (unsafe *word).fetch_sub(1, .Release)
    value

/// Release write guard, returning a Copy snapshot of the current value.
pub fn RwWriteGuard.exit[T: Copy](move self: Self) -> T:
    let state = self.ptr as *mut RwLockState
    let value = unsafe *((unsafe *state).value as *mut T)
    let word = (&raw mut (unsafe *state).state as *mut i32) as *mut Atomic[i32]
    (unsafe *word).store(0, .Release)
    value

impl[T] Scoped[&T] for RwReadGuard[T]:
    fn with_enter(self: &Self) -> &T:
        let state = self.ptr as *mut RwLockState
        unsafe { (unsafe *state).value as &T }

    fn with_exit(self: &Self) -> Unit:
        let state = self.ptr as *mut RwLockState
        let word = (&raw mut (unsafe *state).state as *mut i32) as *mut Atomic[i32]
        let _ = (unsafe *word).fetch_sub(1, .Release)

impl[T] ScopedMut[T] for RwWriteGuard[T]:
    fn with_enter_mut(self: &Self) -> T:
        let state = self.ptr as *mut RwLockState
        unsafe *((unsafe *state).value as *mut T)

    fn with_exit_mut(move self: Self, value: T) -> Unit:
        let state = self.ptr as *mut RwLockState
        with_memcpy((unsafe *state).value as *i8, (&raw const (move value) as *const T) as *i8, sizeof[T]() as i64)
        let word = (&raw mut (unsafe *state).state as *mut i32) as *mut Atomic[i32]
        (unsafe *word).store(0, .Release)

/// Read the value inside an i64 RwLock.
pub fn rwlock_read(rw: &RwLock[i64]) -> i64:
    let guard = rw.enter()
    guard.exit()

/// Write a new value inside a RwLock.
pub fn RwLock.write[T](self: &Self, value: T) -> Unit:
    let state = self.ptr as *mut RwLockState
    let word = (&raw mut (unsafe *state).state as *mut i32) as *mut Atomic[i32]
    while true:
        match (unsafe *word).compare_exchange(0, -1, .Acquire, .Relaxed):
            Ok(_) => break
            Err(_) => ()
        sync_wait_for_progress()
    let value_ptr = (unsafe *state).value as *mut T
    let old = unsafe *value_ptr
    drop(old)
    with_memcpy(value_ptr as *i8, (&raw const (move value) as *const T) as *i8, sizeof[T]() as i64)
    (unsafe *word).store(0, .Release)

impl[T] Drop for RwLock[T]:
    fn drop(move self: Self):
        let state = self.ptr as *mut RwLockState
        let value_ptr = (unsafe *state).value as *mut T
        let value = unsafe *value_ptr
        drop(value)
        with_free(value_ptr as *i8)
        with_free(state as *i8)

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
