// diag_render unit probe: exact inline copy of src/DiagnosticRender.w
// (69 lines, snapshot 450733e5) + main exercising every branch.
// Run: out/bootstrap/bin/with-stage1 run .audit/probes/diag_render/r_units.w
use std.builtins.print_i32

enum DiagSeverity: i32:
    Error = 1
    Warning = 2
    Note = 3

fn render_diag_header(severity: i32, code: &str, message: &str) -> str:
    var out = render_severity(severity) ++ ": " ++ message
    if code.len() > 0:
        out = out ++ " [" ++ code ++ "]"
    out

fn render_diag_location(path: &str, line: i32, col: i32) -> str:
    f" --> {path}:{line + 1}:{col + 1}"

fn render_diag_source_line(line: i32, text: &str) -> str:
    f"{line + 1} | {text}"

fn render_diag_marker_line(col: i32, n: i32) -> str:
    "  | " ++ render_caret_line(col, n)

fn render_diag_label_line(line: i32, col: i32, message: &str) -> str:
    f"  = label @{line + 1}:{col + 1} {message}"

fn render_diag_label_line_in_file(path: &str, line: i32, col: i32, message: &str) -> str:
    f"  = label {path}@{line + 1}:{col + 1} {message}"

fn render_diag_note_line(message: &str) -> str:
    "  = note: " ++ message

fn render_diag_help_line(message: &str) -> str:
    "  = help: " ++ message

fn render_severity(severity: i32) -> str:
    if severity == DiagSeverity.Error:
        return "error"
    if severity == DiagSeverity.Warning:
        return "warning"
    if severity == DiagSeverity.Note:
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

fn main:
    // header: with code / without code (DiagnosticRender.w:8-12)
    print(render_diag_header(1, "E0701", "guard live"))
    print(render_diag_header(2, "", "unused import"))
    // severity: all 4 branches (DiagnosticRender.w:35-42)
    print(render_severity(1))
    print(render_severity(2))
    print(render_severity(3))
    print(render_severity(99))
    // location / source / marker (DiagnosticRender.w:14-21)
    print(render_diag_location("a.w", 0, 0))
    print(render_diag_source_line(0, "let x = 1"))
    print("[" ++ render_diag_marker_line(4, 1) ++ "]")
    // labels: same-file vs in-file (DiagnosticRender.w:23-27)
    print(render_diag_label_line(7, 2, "here"))
    print(render_diag_label_line_in_file("b.w", 7, 2, "there"))
    // note / help (DiagnosticRender.w:29-33)
    print(render_diag_note_line("n"))
    print(render_diag_help_line("h"))
    // underline len: empty, normal, clamped (DiagnosticRender.w:44-50)
    print_i32(span_underline_len(5, 5))
    print_i32(span_underline_len(8, 2))
    print_i32(span_underline_len(0, 3))
    print_i32(span_underline_len(0, 500))
    // caret: col clamp lo/hi, marks clamp, col>200 suffix (DiagnosticRender.w:52-62)
    print("[" ++ render_caret_line(0, 1) ++ "]")
    print("[" ++ render_caret_line(-5, 3) ++ "]")
    print_i32(render_caret_line(500, 200).len())
    print(render_caret_line(500, 2))
    // clamp_i32: all 3 branches (DiagnosticRender.w:64-69)
    print_i32(clamp_i32(-1, 0, 200))
    print_i32(clamp_i32(999, 0, 200))
    print_i32(clamp_i32(7, 0, 200))
