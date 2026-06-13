// Wave 1 foundations: structured diagnostics model.

use compiler.foundation.Span

extern fn with_str_clone(s: str) -> str

pub enum DiagSeverity: i32:
    Error = 1
    Warning = 2
    Note = 3

pub type DiagnosticLabel {
    span: Span,
    message: str,
}

pub type Diagnostic {
    severity: i32,
    code: str,
    message: str,
    primary: Span,
    labels: Vec[DiagnosticLabel],
    notes: Vec[str],
    helps: Vec[str],
}

pub type DiagnosticStore {
    items: Vec[Diagnostic],
}

fn diagnostic_owned_text(text: str) -> str:
    with_str_clone(text)

pub fn diagnostic_error(message: str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Error,
        code: "",
        message: diagnostic_owned_text(message),
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

pub fn diagnostic_warning(message: str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Warning,
        code: "",
        message: diagnostic_owned_text(message),
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

pub fn Diagnostic.set_code(self: Diagnostic, code: str) -> Unit:
    self.code = diagnostic_owned_text(code)

pub fn Diagnostic.add_label(self: Diagnostic, span: Span, message: str) -> Unit:
    self.labels.push(DiagnosticLabel { span, message: diagnostic_owned_text(message) })

pub fn Diagnostic.add_note(self: Diagnostic, message: str) -> Unit:
    self.notes.push(diagnostic_owned_text(message))

pub fn Diagnostic.add_help(self: Diagnostic, message: str) -> Unit:
    self.helps.push(diagnostic_owned_text(message))

pub fn DiagnosticStore.init -> DiagnosticStore:
    DiagnosticStore {
        items: Vec.new(),
    }

pub fn DiagnosticStore.emit(self: DiagnosticStore, diag: Diagnostic) -> Unit:
    self.items.push(diag)

pub fn DiagnosticStore.count(self: DiagnosticStore) -> i32:
    self.items.len() as i32

pub fn DiagnosticStore.count_by_severity(self: DiagnosticStore, severity: i32) -> i32:
    var n = 0
    for i in 0..self.items.len() as i32:
        if self.items.get(i as i64).severity == severity:
            n = n + 1
    n

pub fn DiagnosticStore.has_errors(self: DiagnosticStore) -> bool:
    self.count_by_severity(DiagSeverity.Error) > 0
