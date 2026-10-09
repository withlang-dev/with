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
    labels: List[DiagnosticLabel],
    notes: List[str],
    helps: List[str],
}

pub type DiagnosticStore {
    items: List[Diagnostic],
}

fn diagnostic_owned_text(text: &str) -> str:
    text.clone()

pub fn diagnostic_error(message: &str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Error,
        code: "",
        message: diagnostic_owned_text(message),
        primary,
        labels: List.new(),
        notes: List.new(),
        helps: List.new(),
    }

pub fn diagnostic_warning(message: &str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Warning,
        code: "",
        message: diagnostic_owned_text(message),
        primary,
        labels: List.new(),
        notes: List.new(),
        helps: List.new(),
    }

impl Diagnostic:
    pub mut fn set_code(new_code: &str): self.code = diagnostic_owned_text(new_code)

    pub mut fn add_label(span: Span, text: &str): self.labels.push(DiagnosticLabel { span, message: diagnostic_owned_text(text) })

    pub mut fn add_note(text: &str): self.notes.push(diagnostic_owned_text(text))

    pub mut fn add_help(text: &str): self.helps.push(diagnostic_owned_text(text))

pub fn DiagnosticStore.init -> DiagnosticStore:
    DiagnosticStore {
        items: List.new(),
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
