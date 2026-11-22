//! expect-error: shadowing is not allowed for 'value': it names a field of the receiver `Slot`, which this method reaches by its bare name (§9.5)

// §9.5 (#1930), §29.8: a pattern binding is a local binding.

type Slot {
    value: i32,
    next: Option[i32],
}

impl Slot:
    fn following -> i32:
        match next:
            Some(value) => value
            None => 0

fn main:
    let s = Slot { value: 1, next: Some(2) }
    print(f"{s.following()}")
