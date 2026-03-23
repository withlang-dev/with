//! expect-stdout: ok

use compiler.foundation.Ids
use compiler.foundation.Span
use compiler.foundation.SourceMap
use compiler.foundation.Diagnostic
use compiler.foundation.DiagnosticRender

fn main:
    var sm = SourceMap.init()
    let file = sm.add_source_text("example.w", "let x = y\n")

    let sp = Span {
        file,
        start: 8,
        end: 9,
    }

    var d = diagnostic_error("undefined name", sp)
    d.set_code("E001")
    d.add_label(sp, "unknown identifier")
    d.add_note("bindings must be declared before use")
    d.add_help("add `let y = ...` before this line")

    var store = DiagnosticStore.init()
    store.emit(d)
    store.emit(diagnostic_warning("unused binding", sp))

    assert(store.count() == 2)
    assert(store.count_by_severity(DIAG_SEVERITY_ERROR()) == 1)
    assert(store.count_by_severity(DIAG_SEVERITY_WARNING()) == 1)
    assert(store.has_errors())

    let rendered = render_all_diagnostics(store, sm)
    let expected =
        "error: undefined name [E001]\n" ++
        " --> example.w:1:9\n" ++
        "1 | let x = y\n" ++
        "  |         ^\n" ++
        "  = label @1:9 unknown identifier\n" ++
        "  = note: bindings must be declared before use\n" ++
        "  = help: add `let y = ...` before this line\n" ++
        "\n" ++
        "warning: unused binding\n" ++
        " --> example.w:1:9\n" ++
        "1 | let x = y\n" ++
        "  |         ^\n"
    assert(rendered == expected)

    println("ok")
