// Span — Source location tracking.
//
// A Span identifies a contiguous byte range within a source file.
// Every token and AST node carries a span so that diagnostics can
// point back to the original source text.

type Span = { file: i32, start: i32, end: i32 }

// Returns the length of the span in bytes.
fn Span.len(self: Span) -> i32:
    self.end - self.start

// Extends this span to cover other as well.
fn Span.merge(self: Span, other: Span) -> Span:
    let s = if self.start < other.start then self.start else other.start
    let e = if self.end > other.end then self.end else other.end
    Span { file: self.file, start: s, end: e }

// Sentinel span used for compiler-generated nodes with no source location.
fn span_zero() -> Span:
    Span { file: 0, start: 0, end: 0 }
