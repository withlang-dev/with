//! expect-stdout: ok

use compiler.foundation.SourceMap

fn main:
    var sm = SourceMap.init()
    let file = sm.add_source_text("crlf.w", "a\r\nb\r\n")

    let loc0 = sm.offset_to_location(file, 0)
    assert(loc0.line == 0 and loc0.col == 0)

    let loc_b = sm.offset_to_location(file, 3)
    assert(loc_b.line == 1 and loc_b.col == 0)

    assert(sm.line_text(file, 0) == "a\r")
    assert(sm.line_text(file, 1) == "b\r")

    print("ok")
