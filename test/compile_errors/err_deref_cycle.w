//! expect-check-fail: auto-deref cycle through Deref implementation

type DerefCycle { value: i32 }

impl Deref[DerefCycle] for DerefCycle:
    fn deref(self: &Self) -> &DerefCycle:
        self

fn main:
    let value = DerefCycle { value: 1 }
    let _missing = value.missing
