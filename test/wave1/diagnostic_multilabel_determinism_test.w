//! expect-stdout: ok

use compiler.foundation.Ids
use compiler.foundation.Span
use compiler.foundation.SourceMap
use compiler.foundation.Diagnostic
use compiler.foundation.DiagnosticRender

fn main:
    var sm = SourceMap.init()
    let file = sm.add_source_text("multi.w", "let a = b + c\n")

    let sp_primary = Span { file, start: 8, end: 9 } // b
    let sp_second = Span { file, start: 12, end: 13 } // c

    var d = diagnostic_error("ordered labels", sp_primary)
    d.set_code("E002")
    d.add_label(sp_second, "rhs operand")
    d.add_label(sp_primary, "lhs operand")

    var store = DiagnosticStore.init()
    store.emit(d)

    let r1 = render_all_diagnostics(store, sm)
    let r2 = render_all_diagnostics(store, sm)
    assert(r1 == r2)

    let expected =
        "error: ordered labels [E002]\n" ++
        " --> multi.w:1:9\n" ++
        "1 | let a = b + c\n" ++
        "  |         ^\n" ++
        "  = label @1:13 rhs operand\n" ++
        "  = label @1:9 lhs operand\n"
    assert(r1 == expected)

    println("ok")
