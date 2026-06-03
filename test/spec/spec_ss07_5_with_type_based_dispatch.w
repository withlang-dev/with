// Spec test: Section 7.5 - With Type-Based Dispatch

use std.sync

type TestGuard {
    value: i32,
}

impl Scoped[i32] for TestGuard =
    fn with_enter(self: &Self) -> i32:
        self.value

    fn with_exit(self: &Self) -> void:
        ()

type Config {
    retries: i32,
}

fn test_scoped_type_uses_guarded_form:
    let guard = TestGuard { value: 7 }
    let out = with guard as data:
        data + 5
    assert(out == 12)

fn test_std_sync_guard_uses_guarded_form:
    let lock = mutex_new(3)
    let out = with lock.enter() as data:
        data * 4
    assert(out == 12)

fn test_non_scoped_type_uses_builder_form:
    let config = with Config { retries: 0 } as mut c:
        c.retries = 3
    assert(config.retries == 3)
