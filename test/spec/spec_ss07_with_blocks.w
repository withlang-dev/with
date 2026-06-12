// Spec test: Section 7 - `with` Blocks

use std.sync

type LocalGuard {
    value: i32,
}

impl Scoped[i32] for LocalGuard:    fn with_enter(self:
    &Self) -> i32:
        self.value

    fn with_exit(self: &Self) -> Unit:
        ()

fn test_guarded_read_block:
    let lock = mutex_new(40)
    let val = with lock.enter() as data:
        data + 2
    assert(val == 42)

fn test_guarded_mut_block:
    let lock = mutex_new(40)
    var seen = 0
    with lock.enter_mut() as mut data:
        data = data + 2
        seen = data
    assert(seen == 42)

fn test_multi_with_nests_left_to_right:
    let a = LocalGuard { value: 10 }
    let b = LocalGuard { value: 32 }
    let val = with a as x, b as y:
        x + y
    assert(val == 42)

type Config {
    timeout: i32,
    retries: i32,
}

fn test_builder_form:
    let c = with Config { timeout: 0, retries: 0 } as mut c:
        c.timeout = 30
        c.retries = 3
    assert(c.timeout == 30)
    assert(c.retries == 3)

fn test_scoped_binding_form:
    let area = with 6 as width:
        width * 7
    assert(area == 42)

fn find_val(flag: bool) -> i32:
    let guard = LocalGuard { value: 42 }
    with guard as data:
        if flag:
            return data
    0

fn test_non_local_return:
    assert(find_val(true) == 42)
    assert(find_val(false) == 0)
