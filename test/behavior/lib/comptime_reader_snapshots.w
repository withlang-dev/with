type Reader { bytes: str, at: i32, checksum: i32 }

comptime fn Reader.byte(mut self: Self) -> i32:
    if self.at >= self.bytes.len() as i32:
        return 0
    let b = self.bytes[self.at] as i32
    self.at = self.at + 1
    b

comptime fn advance() -> Reader:
    var text = "0123456789abcdef"
    for _ in 0..12:
        text = text ++ text
    var reader = Reader { bytes: text, at: 0, checksum: 0 }
    while reader.at < 512:
        reader.checksum = reader.checksum + reader.byte()
    // Replace the shared field, then materialize an independent owned value.
    reader.bytes = "changed"
    reader

const RESULT: Reader = comptime advance()
assert(RESULT.at == 512)
assert(RESULT.checksum == 35904)
assert(RESULT.bytes == "changed")
print("ok")
