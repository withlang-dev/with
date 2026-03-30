//! expect-stdout: ok

use compiler.foundation.Ids
use compiler.foundation.SourceMap

fn main:
    var sm = SourceMap.init()
    assert(sm.contains(file_id_from_raw(0)))
    assert(not sm.contains(file_id_invalid()))

    let f1 = sm.add_source_text("a.w", "abc\ndef\n")
    let f2 = sm.add_source_text("b.w", "x\ny\n")
    let f1_dup = sm.add_source_text("a.w", "ignored")
    assert(file_id_raw(f1) == file_id_raw(f1_dup))
    assert(file_id_raw(f1) != file_id_raw(f2))

    assert(sm.contains(f1))
    assert(sm.contains(f2))
    let s1 = sm.get_source(f1)
    assert(s1.path == "a.w")
    assert(s1.text == "abc\ndef\n")

    let l = sm.offset_to_location(f1, 5)
    assert(l.line == 1 and l.col == 1)
    assert(sm.line_text(f1, 0) == "abc")
    assert(sm.line_text(f1, 1) == "def")

    print("ok")
