//! expect-check-fail: ephemeral values cannot be stored in non-ephemeral structs

type Token = ephemeral {
    text: StrView,
}

type Module {
    tokens: Vec[Token],
}

fn main:
    0
