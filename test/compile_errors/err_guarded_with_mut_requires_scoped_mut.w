//! expect-error: mutable guarded with requires ScopedMut

type Guard {
    value: i32,
}

impl Scoped[i32] for Guard:    fn with_enter(self:
    &Self) -> i32:
        self.value

    fn with_exit(self: &Self) -> void:
        ()

fn main:
    let guard = Guard { value: 1 }
    let _ = with guard as mut data:
        data
