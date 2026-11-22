//! expect-stdout: 41 42

type GenericGuard[T] { ptr: *mut T }

impl[T] Scoped[&T] for GenericGuard[T]:
    fn with_enter(self: &Self) -> &T: unsafe { self.ptr as &T }
    fn with_exit(self: &Self) -> Unit: ()

impl[T] ScopedMut[T] for GenericGuard[T]:
    fn with_enter_mut(self: &Self) -> T: unsafe *self.ptr
    mut fn with_exit_mut(value: T) -> Unit: unsafe *self.ptr = move value

fn main:
    var n: i32 = 41
    var before = 0
    with GenericGuard { ptr: &raw mut n } as value:
        before = *value
    let guard: GenericGuard[i32] = GenericGuard { ptr: &raw mut n }
    with guard as mut value:
        value = value + 1
    var after = 0
    with GenericGuard { ptr: &raw mut n } as value:
        after = *value
    print(f"{before} {after}")
