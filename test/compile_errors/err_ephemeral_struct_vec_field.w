//! expect-check-fail: ephemeral values cannot be stored in non-ephemeral structs

type Token = ephemeral {
    text: StrView,
}

type Module {
    tokens: List[Token],
}

fn main:
    0
