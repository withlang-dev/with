//! expect-stdout: ok

type LocalToken = ephemeral {
    text: StrView,
}

fn main:
    var tokens: Vec[LocalToken] = Vec.new()
    tokens.push(LocalToken { text: "hi" })
    assert(tokens.len() == 1)
    print("ok")
