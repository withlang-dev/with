// Source location tracking.
//
// A Span identifies a contiguous byte range within a source file.
// Every token and AST node carries a span so diagnostics can
// point back to the original source text.

// Opaque identifier for a loaded source file.
type FileId = i32

// A contiguous byte range within a source file.
type Span = {
    file: FileId,
    start: i32,
    end: i32,
}

// Sentinel span used for compiler-generated nodes with no source location.
fn Span.zero -> Span:
    Span { file: 0, start: 0, end: 0 }

// Returns the length of the span in bytes.
fn Span.len(self: Span) -> i32:
    self.end - self.start

// Extends this span to cover other as well.
fn Span.merge(self: Span, other: Span) -> Span:
    Span {
        file: self.file,
        start: span_min(self.start, other.start),
        end: span_max(self.end, other.end),
    }

fn span_min(a: i32, b: i32) -> i32:
    if a < b:
        return a
    b

fn span_max(a: i32, b: i32) -> i32:
    if a > b:
        return a
    b
