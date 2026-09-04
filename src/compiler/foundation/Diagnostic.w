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

fn diagnostic_owned_text(text: &str) -> str:
    text.clone()

pub fn diagnostic_error(message: &str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Error,
        code: "",
        message: diagnostic_owned_text(message),
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

pub fn diagnostic_warning(message: &str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Warning,
        code: "",
        message: diagnostic_owned_text(message),
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

impl Diagnostic:
    pub mut fn set_code(code: &str): self.code = diagnostic_owned_text(code)

    pub mut fn add_label(span: Span, message: &str): self.labels.push(DiagnosticLabel { span, message: diagnostic_owned_text(message) })

    pub mut fn add_note(message: &str): self.notes.push(diagnostic_owned_text(message))

    pub mut fn add_help(message: &str): self.helps.push(diagnostic_owned_text(message))

pub fn DiagnosticStore.init -> DiagnosticStore:
    DiagnosticStore {
        items: Vec.new(),
    }

impl DiagnosticStore:
    pub mut fn emit(diag: Diagnostic): self.items.push(diag)

    pub fn count(): self.items.len() as i32

    pub fn count_by_severity(severity: i32) -> i32:
        var n = 0
        for i in 0..self.items.len() as i32:
            if self.items[i].severity == severity:
                n = n + 1
        n

    pub fn has_errors() -> bool: self.count_by_severity(DiagSeverity.Error) > 0
