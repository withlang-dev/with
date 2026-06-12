//! expect-check-fail: ephemeral values cannot be stored in non-ephemeral structs

type OptionToken = ephemeral {
    text: StrView,
}

type BadOptionStore {
    token: Option[OptionToken],
}

fn main:
    0
