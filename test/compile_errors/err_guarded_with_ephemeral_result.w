//! expect-error: guarded with result cannot be ephemeral

type Guard {
    value: i32,
}

impl Scoped[i32] for Guard:    fn with_enter(self:
    &Self) -> i32:
        self.value

    fn with_exit(self: &Self) -> Unit:
        ()

fn main:
    let guard = Guard { value: 42 }
    let _r = with guard as data:
        &data
