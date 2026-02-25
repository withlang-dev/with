//! Source location tracking.
//!
//! A `Span` identifies a contiguous byte range within a source file.
//! Every token and AST node carries a span so that diagnostics can
//! point back to the original source text.

const Source = @import("Source.zig");

/// Opaque identifier for a loaded source file.
pub const FileId = u32;

/// A contiguous byte range within a source file.
pub const Span = @This();

file: FileId,
start: u32,
end: u32,

/// Sentinel span used for compiler-generated nodes with no source location.
pub const zero: Span = .{ .file = 0, .start = 0, .end = 0 };

/// Returns the length of the span in bytes.
pub fn len(self: Span) u32 {
    return self.end - self.start;
}

/// Extends this span to cover `other` as well.
pub fn merge(self: Span, other: Span) Span {
    return .{
        .file = self.file,
        .start = @min(self.start, other.start),
        .end = @max(self.end, other.end),
    };
}
