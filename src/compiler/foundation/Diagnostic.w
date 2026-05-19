// Wave 1 foundations: structured diagnostics model.

use compiler.foundation.Span

enum DiagSeverity: i32:
    Error = 1
    Warning = 2
    Note = 3

type DiagnosticLabel {
    span: Span,
    message: str,
}

type Diagnostic {
    severity: i32,
    code: str,
    message: str,
    primary: Span,
    labels: Vec[DiagnosticLabel],
    notes: Vec[str],
    helps: Vec[str],
}

type DiagnosticStore {
    items: Vec[Diagnostic],
}

fn diagnostic_error(message: str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Error,
        code: "",
        message,
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

fn diagnostic_warning(message: str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Warning,
        code: "",
        message,
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

fn Diagnostic.set_code(self: Diagnostic, code: str):
    self.code = code

fn Diagnostic.add_label(self: Diagnostic, span: Span, message: str) -> void:
    self.labels.push(DiagnosticLabel { span, message })

fn Diagnostic.add_note(self: Diagnostic, message: str) -> void:
    self.notes.push(message)

fn Diagnostic.add_help(self: Diagnostic, message: str) -> void:
    self.helps.push(message)

fn DiagnosticStore.init -> DiagnosticStore:
    DiagnosticStore {
        items: Vec.new(),
    }

fn DiagnosticStore.emit(self: DiagnosticStore, diag: Diagnostic) -> void:
    self.items.push(diag)

fn DiagnosticStore.count(self: DiagnosticStore) -> i32:
    self.items.len() as i32

fn DiagnosticStore.count_by_severity(self: DiagnosticStore, severity: i32) -> i32:
    var n = 0
    for i in 0..self.items.len() as i32:
        if self.items.get(i as i64).severity == severity:
            n = n + 1
    n

fn DiagnosticStore.has_errors(self: DiagnosticStore) -> bool:
    self.count_by_severity(DiagSeverity.Error) > 0
