// Wave 1 foundations: deterministic diagnostic rendering helpers.

fn render_diag_header(severity: i32, code: str, message: str) -> str:
    var out = render_severity(severity) ++ ": " ++ message
    if code.len() > 0:
        out = out ++ " [" ++ code ++ "]"
    out

fn render_diag_location(path: str, line: i32, col: i32) -> str:
    f" --> {path}:{line + 1}:{col + 1}"

fn render_diag_source_line(line: i32, text: str) -> str:
    f"{line + 1} | {text}"

fn render_diag_marker_line(col: i32, n: i32) -> str:
    "  | " ++ render_caret_line(col, n)

fn render_diag_label_line(line: i32, col: i32, message: str) -> str:
    f"  = label @{line + 1}:{col + 1} {message}"

fn render_diag_note_line(message: str) -> str:
    "  = note: " ++ message

fn render_diag_help_line(message: str) -> str:
    "  = help: " ++ message

fn render_severity(severity: i32) -> str:
    if severity == DIAG_SEVERITY_ERROR:
        return "error"
    if severity == DIAG_SEVERITY_WARNING:
        return "warning"
    if severity == DIAG_SEVERITY_NOTE:
        return "note"
    "diag"

fn span_underline_len(start: i32, end: i32) -> i32:
    let n = end - start
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
