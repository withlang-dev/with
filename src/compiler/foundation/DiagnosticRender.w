// Wave 1 foundations: deterministic diagnostic rendering.

use compiler.foundation.Ids
use compiler.foundation.Span
use compiler.foundation.SourceMap
use compiler.foundation.Diagnostic

fn render_diagnostic(diag: Diagnostic, sm: SourceMap) -> str:
    let sev = render_severity(diag.severity)
    var out = sev
    out = out ++ ": "
    out = out ++ diag.message
    if diag.code.len() > 0:
        out = out ++ " ["
        out = out ++ diag.code
        out = out ++ "]"
    out = out ++ "\n"

    let file_id = diag.primary.file
    let src = sm.get_source(file_id)
    let loc = sm.offset_to_location(file_id, diag.primary.start)
    out = out ++ f" --> {src.path}:{loc.line + 1}:{loc.col + 1}\n"

    let line_text = sm.line_text(file_id, loc.line)
    out = out ++ f"{loc.line + 1} | "
    out = out ++ line_text
    out = out ++ "\n"
    out = out ++ "  | "
    out = out ++ render_caret_line(loc.col, span_underline_len(diag.primary))
    out = out ++ "\n"

    for i in 0..diag.labels.len() as i32:
        let lab = diag.labels.get(i as i64)
        let lloc = sm.offset_to_location(lab.span.file, lab.span.start)
        out = out ++ f"  = label @{lloc.line + 1}:{lloc.col + 1} "
        out = out ++ lab.message
        out = out ++ "\n"

    for i in 0..diag.notes.len() as i32:
        out = out ++ "  = note: "
        out = out ++ diag.notes.get(i as i64)
        out = out ++ "\n"
    for i in 0..diag.helps.len() as i32:
        out = out ++ "  = help: "
        out = out ++ diag.helps.get(i as i64)
        out = out ++ "\n"

    out

fn render_all_diagnostics(store: DiagnosticStore, sm: SourceMap) -> str:
    var out = ""
    for i in 0..store.items.len() as i32:
        out = out ++ render_diagnostic(store.items.get(i as i64), sm)
        if i + 1 < store.items.len() as i32:
            out = out ++ "\n"
    out

fn render_severity(severity: i32) -> str:
    if severity == DiagSeverity.Error:
        return "error"
    if severity == DiagSeverity.Warning:
        return "warning"
    if severity == DiagSeverity.Note:
        return "note"
    "diag"

fn span_underline_len(sp: Span) -> i32:
    let n = sp.len()
    if n <= 0:
        return 1
    if n > 120:
        return 120
    n

fn render_caret_line(col: i32, n: i32) -> str:
    var out = ""
    let pad = clamp_i32(col, 0, 200)
    for i in 0..pad:
        out = out ++ " "
    let marks = clamp_i32(n, 1, 120)
    for i in 0..marks:
        out = out ++ "^"
    if col > 200:
        out = out ++ " ..."
    out

fn clamp_i32(v: i32, lo: i32, hi: i32) -> i32:
    if v < lo:
        return lo
    if v > hi:
        return hi
    v
