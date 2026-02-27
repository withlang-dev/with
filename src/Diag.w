// Diag — Compiler diagnostics: structured errors and warnings.
//
// Every compiler error is a structured Diag value carrying a
// primary span and message. The DiagList accumulates diagnostics
// during compilation.

use Span

type Severity = SevError | SevWarning

type Diag = {
    severity: Severity,
    message: str,
    span: Span,
}

fn Diag.err(message: str, span: Span) -> Diag:
    Diag { severity: SevError, message: message, span: span }

fn Diag.warn(message: str, span: Span) -> Diag:
    Diag { severity: SevWarning, message: message, span: span }

fn Diag.is_error(self: Diag) -> bool:
    match self.severity
        SevError -> true
        SevWarning -> false

// Accumulator for diagnostics produced during compilation.
type DiagList = {
    items: Vec[Diag],
}

fn DiagList.new() -> DiagList:
    DiagList { items: Vec.new() }

fn DiagList.emit(self: DiagList, d: Diag) -> void:
    self.items.push(d)

fn DiagList.has_errors(self: DiagList) -> bool:
    var i = 0
    while i < self.items.len() as i32:
        let d = self.items.get(i as i64)
        if Diag.is_error(d):
            return true
        i = i + 1
    false

fn DiagList.count(self: DiagList) -> i32:
    self.items.len() as i32

// Render a diagnostic to stdout.
fn Diag.render(self: Diag) -> void:
    match self.severity
        SevError -> print("error")
        SevWarning -> print("warning")
    println(": {self.message}")
