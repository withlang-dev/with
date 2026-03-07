// Wave 1 foundations: structured diagnostics model.

use std.prelude_core

use compiler.foundation.Span

fn DIAG_SEVERITY_ERROR -> i32: 1
fn DIAG_SEVERITY_WARNING -> i32: 2
fn DIAG_SEVERITY_NOTE -> i32: 3

type DiagnosticLabel = {
    span: Span,
    message: str,
}

type Diagnostic = {
    severity: i32,
    code: str,
    message: str,
    primary: Span,
    labels: Vec[DiagnosticLabel],
    notes: Vec[str],
    helps: Vec[str],
}

type DiagnosticStore = {
    items: Vec[Diagnostic],
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

fn Diagnostic.set_code(self: Diagnostic, code: str):
    self.code = code

fn Diagnostic.add_label(self: Diagnostic, span: Span, message: str):
    self.labels.push(DiagnosticLabel { span, message })

fn Diagnostic.add_note(self: Diagnostic, message: str):
    self.notes.push(message)

fn Diagnostic.add_help(self: Diagnostic, message: str):
    self.helps.push(message)

fn DiagnosticStore.init -> DiagnosticStore:
    DiagnosticStore {
        items: Vec.new(),
    }

fn DiagnosticStore.emit(self: DiagnosticStore, diag: Diagnostic):
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
    self.count_by_severity(DIAG_SEVERITY_ERROR()) > 0
