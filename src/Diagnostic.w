// Diagnostic — Compiler diagnostics: structured errors, warnings, and rendering.
//
// Every compiler error is a structured Diagnostic value carrying a
// primary span, optional labels, notes, and help text.

use Span
use Source

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str

// Severity levels.
fn SEV_ERROR -> i32: 0
fn SEV_WARNING -> i32: 1

// A secondary label with span and message.
type Label = {
    span: Span,
    message: str,
}

type Diagnostic = {
    severity: i32,
    message: str,
    primary: Span,
    labels: Vec[Label],
    notes: Vec[str],
    helps: Vec[str],
}

// Convenience constructor for a simple error with no extra labels.
fn Diagnostic.err(message: str, span: Span) -> Diagnostic:
    Diagnostic {
        severity: SEV_ERROR(),
        message,
        primary: span,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

// Convenience constructor for a simple warning.
fn Diagnostic.warn(message: str, span: Span) -> Diagnostic:
    Diagnostic {
        severity: SEV_WARNING(),
        message,
        primary: span,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

// Render this diagnostic to stderr.
fn Diagnostic.render(self: Diagnostic, source: Source):
    // Severity prefix.
    var out = ""
    if self.severity == SEV_ERROR():
        out = "error"
    else:
        out = "warning"
    out = out ++ ": " ++ self.message
    with_eprintln(out)

    // Location.
    let loc = source.offset_to_location(self.primary.start)
    let line_num = loc.line + 1
    let col_num = loc.col + 1
    with_eprintln(" --> " ++ source.name ++ ":" ++ int_to_string(line_num) ++ ":" ++ int_to_string(col_num))

    // Source snippet.
    let line_text = source.line_text(loc.line)
    let gutter_w = digit_count(line_num)
    with_eprintln(spaces(gutter_w + 1) ++ "|")
    with_eprintln(int_to_string(line_num) ++ " | " ++ line_text)

    var underline = ""
    let raw_u_len = if self.primary.len() > 0: self.primary.len() else: 1
    let u_len = clamp_i32(raw_u_len, 1, 120)
    for u_i in 0..u_len:
        underline = underline ++ "^"
    let col_pad = clamp_i32(loc.col, 0, 200)
    var marker = spaces(gutter_w + 1) ++ "| " ++ spaces(col_pad) ++ underline
    if loc.col > 200 or raw_u_len > 120:
        marker = marker ++ " ..."
    with_eprintln(marker)

    // Notes and helps.
    for n_i in 0..self.notes.len() as i32:
        with_eprintln(spaces(gutter_w + 1) ++ "= note: " ++ self.notes.get(n_i as i64))
    for h_i in 0..self.helps.len() as i32:
        with_eprintln(spaces(gutter_w + 1) ++ "= help: " ++ self.helps.get(h_i as i64))

fn spaces(count: i32) -> str:
    let n = clamp_i32(count, 0, 512)
    var result = ""
    for i in 0..n:
        result = result ++ " "
    result

fn clamp_i32(v: i32, lo: i32, hi: i32) -> i32:
    if v < lo:
        return lo
    if v > hi:
        return hi
    v

fn digit_count(n: i32) -> i32:
    if n == 0: return 1
    var val = n
    var count = 0
    while val > 0:
        val = val / 10
        count = count + 1
    count

// Accumulator for diagnostics produced during compilation.
type DiagnosticList = {
    items: Vec[Diagnostic],
}

fn DiagnosticList.init -> DiagnosticList:
    DiagnosticList {
        items: Vec.new(),
    }

fn DiagnosticList.deinit(self: DiagnosticList):
    return

fn DiagnosticList.emit(self: DiagnosticList, diag: Diagnostic):
    self.items.push(diag)

fn DiagnosticList.has_errors(self: DiagnosticList) -> bool:
    for i in 0..self.items.len() as i32:
        if self.items.get(i as i64).severity == SEV_ERROR():
            return true
    false

fn DiagnosticList.render_all(self: DiagnosticList, source: Source):
    for i in 0..self.items.len() as i32:
        self.items.get(i as i64).render(source)
        with_eprintln("")
