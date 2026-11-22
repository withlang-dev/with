// std.encoding — shared encoding error surface.

/// Why encoded input could not be decoded.
pub error DecodeError =
    | InvalidLength(length: i64)
    | InvalidByte(offset: i64, byte: u8)
    | InvalidPadding(offset: i64)
    | NonCanonicalBits(offset: i64)
