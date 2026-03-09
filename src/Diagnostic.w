// Wave 1 foundations: diagnostics model + deterministic rendering.

use Span
use Source
use DiagnosticRender

extern fn with_eprintln(s: str) -> void

fn DIAG_SEVERITY_ERROR -> i32: 1
fn DIAG_SEVERITY_WARNING -> i32: 2
fn DIAG_SEVERITY_NOTE -> i32: 3

// Legacy aliases kept for existing callers.
fn SEV_ERROR -> i32: DIAG_SEVERITY_ERROR()
fn SEV_WARNING -> i32: DIAG_SEVERITY_WARNING()

type DiagnosticLabel = {
    span: Span,
    message: str,
}

// Legacy alias kept for existing callers.
type Label = DiagnosticLabel

type Diagnostic = {
    severity: i32,
    code: str,
    message: str,
    primary: Span,
    labels: Vec[DiagnosticLabel],
    notes: Vec[str],
    helps: Vec[str],
}

fn diagnostic_error(message: str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DIAG_SEVERITY_ERROR(),
        code: "",
        message,
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

fn diagnostic_warning(message: str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DIAG_SEVERITY_WARNING(),
        code: "",
        message,
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

fn Diagnostic.err(message: str, span: Span) -> Diagnostic:
    diagnostic_error(message, span)

fn Diagnostic.warn(message: str, span: Span) -> Diagnostic:
    diagnostic_warning(message, span)

fn Diagnostic.set_code(self: Diagnostic, code: str):
    self.code = code

fn Diagnostic.add_label(self: Diagnostic, span: Span, message: str):
    self.labels.push(DiagnosticLabel { span, message })

fn Diagnostic.add_note(self: Diagnostic, message: str):
    self.notes.push(message)

fn Diagnostic.add_help(self: Diagnostic, message: str):
    self.helps.push(message)

fn Diagnostic.render(self: Diagnostic, source: Source):
    let code: str = self.code
    let message: str = self.message
    with_eprintln(render_diag_header(self.severity, code, message))

    let loc = source.offset_to_location(self.primary.start)
    let source_path: str = source.path
    with_eprintln(render_diag_location(source_path, loc.line, loc.col))

    let line_text: str = source.line_text(loc.line)
    with_eprintln(render_diag_source_line(loc.line, line_text))
    with_eprintln(render_diag_marker_line(loc.col, span_underline_len(self.primary.start, self.primary.end)))

    for i in 0..self.labels.len() as i32:
        let lab: DiagnosticLabel = self.labels.get(i as i64)
        let lloc = source.offset_to_location(lab.span.start)
        let label_message: str = lab.message
        with_eprintln(render_diag_label_line(lloc.line, lloc.col, label_message))

    for i in 0..self.notes.len() as i32:
        let note: str = self.notes.get(i as i64)
        with_eprintln(render_diag_note_line(note))
    for i in 0..self.helps.len() as i32:
        let help: str = self.helps.get(i as i64)
        with_eprintln(render_diag_help_line(help))

type DiagnosticList = {
    items: Vec[Diagnostic],
}

fn DiagnosticList.init -> DiagnosticList:
    DiagnosticList {
        items: Vec.new(),
    }

// No-op: reserved for future manual memory management.
fn DiagnosticList.deinit(self: DiagnosticList):
    return

fn DiagnosticList.emit(self: DiagnosticList, diag: Diagnostic):
    self.items.push(diag)

fn DiagnosticList.count(self: DiagnosticList) -> i32:
    self.items.len() as i32

fn DiagnosticList.count_by_severity(self: DiagnosticList, severity: i32) -> i32:
    var n = 0
    for i in 0..self.items.len() as i32:
        if self.items.get(i as i64).severity == severity:
            n = n + 1
    n

fn DiagnosticList.has_errors(self: DiagnosticList) -> bool:
    self.count_by_severity(DIAG_SEVERITY_ERROR()) > 0

fn DiagnosticList.render_all(self: DiagnosticList, source: Source):
    for i in 0..self.items.len() as i32:
        self.items.get(i as i64).render(source)
        if i + 1 < self.items.len() as i32:
            with_eprintln("")

fn DiagnosticList.render_warnings(self: DiagnosticList, source: Source):
    var printed = 0
    for i in 0..self.items.len() as i32:
        if self.items.get(i as i64).severity != DIAG_SEVERITY_WARNING():
            continue
        if printed != 0:
            with_eprintln("")
        self.items.get(i as i64).render(source)
        printed = printed + 1
