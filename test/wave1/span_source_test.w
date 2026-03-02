//! expect-stdout: ok

use compiler.foundation.Ids
use compiler.foundation.Span
use compiler.foundation.Source

fn main:
    let f = file_id_from_raw(1)
    let s1 = Span { file: f, start: 2, end: 8 }
    let s2 = Span { file: f, start: 1, end: 4 }
    assert(s1.len() == 6)
    assert(s1.is_valid())
    let merged = s1.merge(s2)
    assert(merged.start == 1)
    assert(merged.end == 8)

    let z = span_zero()
    assert(z.start == 0 and z.end == 0)

    let src = Source.from_string("mem.w", "line0\nline1\nline2\n", f)
    assert(src.line_count() == 4)
    let loc0 = src.offset_to_location(0)
    assert(loc0.line == 0 and loc0.col == 0)
    let loc1 = src.offset_to_location(7)
    assert(loc1.line == 1 and loc1.col == 1)
    assert(src.line_text(0) == "line0")
    assert(src.line_text(1) == "line1")
    assert(src.line_text(2) == "line2")
    assert(src.line_text(99) == "")

    println("ok")
