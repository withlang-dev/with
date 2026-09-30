type Reader { bytes: str, at: i32 }

comptime fn advance() -> Reader:
    var text = "0123456789abcdef"
    for _ in 0..11:
        text = text ++ text
    var reader = Reader { bytes: move text, at: 0 }
    while reader.at < 2000:
        reader.at = reader.at + 1
    // Replace the shared field, then materialize an independent owned value.
    reader.bytes = "changed"
    reader

const RESULT: Reader = comptime advance()
assert(RESULT.at == 2000)
assert(RESULT.bytes == "changed")
print("ok")
