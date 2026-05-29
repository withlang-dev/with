//! expect-check-fail: ephemeral values cannot be stored in non-ephemeral structs

type BadToken {
    text: StrView,
}

fn main:
    0
