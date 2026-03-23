//! expect-stdout: ok

use compiler.foundation.SourceMap

fn main:
    var sm = SourceMap.init()
    // Includes CRLF line endings plus UTF-8 multi-byte codepoints.
    let file = sm.add_source_text("utf8_crlf.w", "aé\r\nb😀\r\n")

    let loc0 = sm.offset_to_location(file, 0)
    assert(loc0.line == 0 and loc0.col == 0)

    let loc_after_a = sm.offset_to_location(file, 1)
    assert(loc_after_a.line == 0 and loc_after_a.col == 1)

    // 'é' is two bytes; '\r' begins at byte offset 3.
    let loc_cr = sm.offset_to_location(file, 3)
    assert(loc_cr.line == 0 and loc_cr.col == 3)

    let loc_b = sm.offset_to_location(file, 5)
    assert(loc_b.line == 1 and loc_b.col == 0)

    // '😀' is four bytes; byte offset 10 is the following '\r'.
    let loc_emoji = sm.offset_to_location(file, 6)
    assert(loc_emoji.line == 1 and loc_emoji.col == 1)
    let loc_after_emoji = sm.offset_to_location(file, 10)
    assert(loc_after_emoji.line == 1 and loc_after_emoji.col == 5)

    // Trailing CRLF yields a final empty line entry.
    let loc_eof = sm.offset_to_location(file, 12)
    assert(loc_eof.line == 2 and loc_eof.col == 0)

    assert(sm.line_text(file, 0) == "aé\r")
    assert(sm.line_text(file, 1) == "b😀\r")
    assert(sm.line_text(file, 2) == "")

    println("ok")
