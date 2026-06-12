// Wave 1 foundations: structured diagnostics model.

use compiler.foundation.Span

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

pub fn diagnostic_error(message: str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Error,
        code: "",
        message,
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

pub fn diagnostic_warning(message: str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Warning,
        code: "",
        message,
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

pub fn Diagnostic.set_code(self: Diagnostic, code: str) -> Unit:
    self.code = code

pub fn Diagnostic.add_label(self: Diagnostic, span: Span, message: str) -> Unit:
    self.labels.push(DiagnosticLabel { span, message })

pub fn Diagnostic.add_note(self: Diagnostic, message: str) -> Unit:
    self.notes.push(message)

pub fn Diagnostic.add_help(self: Diagnostic, message: str) -> Unit:
    self.helps.push(message)

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
