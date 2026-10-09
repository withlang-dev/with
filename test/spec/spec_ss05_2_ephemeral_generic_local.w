//! expect-stdout: ok

type LocalToken = ephemeral {
    text: StrView,
}

fn main:
    var tokens: List[LocalToken] = List.new()
    tokens.push(LocalToken { text: "hi" })
    assert(tokens.len() == 1)
    print("ok")
