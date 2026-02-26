//! Phase-0 `diag` facade.

const std = @import("std");
const DiagnosticImpl = @import("Diagnostic.zig");
const Span = @import("Span.zig");

pub const Severity = DiagnosticImpl.Severity;
pub const Label = DiagnosticImpl.Label;
pub const Diagnostic = DiagnosticImpl;
pub const DiagnosticList = DiagnosticImpl.DiagnosticList;

test "diag facade tracks errors and warnings" {
    const allocator = std.testing.allocator;
    var list = DiagnosticList.init(allocator);
    defer list.deinit();

    list.emit(Diagnostic.warn("warn", Span.zero));
    try std.testing.expect(!list.hasErrors());

    list.emit(Diagnostic.err("err", Span.zero));
    try std.testing.expect(list.hasErrors());
}

