//! Compiler diagnostics: structured errors, warnings, and rendering.
//!
//! Every compiler error is a structured `Diagnostic` value carrying a
//! primary span, optional secondary labels, notes, and help text.
//! The renderer formats these for terminal output with color and
//! source snippets.

const std = @import("std");
const Span = @import("Span.zig");
const Source = @import("Source.zig");

const Diagnostic = @This();

pub const Severity = enum {
    @"error",
    warning,
};

pub const Label = struct {
    span: Span,
    message: []const u8,
};

severity: Severity,
message: []const u8,
primary: Span,
labels: []const Label,
notes: []const []const u8,
helps: []const []const u8,

/// Convenience constructor for a simple error with no extra labels.
pub fn err(message: []const u8, span: Span) Diagnostic {
    return .{
        .severity = .@"error",
        .message = message,
        .primary = span,
        .labels = &.{},
        .notes = &.{},
        .helps = &.{},
    };
}

/// Convenience constructor for a simple warning.
pub fn warn(message: []const u8, span: Span) Diagnostic {
    return .{
        .severity = .warning,
        .message = message,
        .primary = span,
        .labels = &.{},
        .notes = &.{},
        .helps = &.{},
    };
}

/// Render this diagnostic to a writer (any type with print/writeAll).
pub fn render(self: *const Diagnostic, source: *const Source, writer: anytype) !void {
    // Severity prefix.
    switch (self.severity) {
        .@"error" => try writer.writeAll("error"),
        .warning => try writer.writeAll("warning"),
    }
    try writer.print(": {s}\n", .{self.message});

    // Location.
    const loc = source.offsetToLocation(self.primary.start);
    try writer.print(" --> {s}:{d}:{d}\n", .{
        source.name,
        loc.line + 1,
        loc.col + 1,
    });

    // Source snippet.
    const line_text = source.lineText(loc.line);
    const line_num = loc.line + 1;
    const gutter_width = digitCount(line_num);
    try writeSpaces(writer, gutter_width + 1);
    try writer.writeAll("|\n");

    try writer.print("{d} | {s}\n", .{ line_num, line_text });

    try writeSpaces(writer, gutter_width + 1);
    try writer.writeAll("| ");
    try writeSpaces(writer, loc.col);
    const underline_len = @max(self.primary.len(), 1);
    for (0..underline_len) |_| {
        try writer.writeAll("^");
    }
    try writer.writeAll("\n");

    // Notes and helps.
    for (self.notes) |note| {
        try writeSpaces(writer, gutter_width + 1);
        try writer.print("= note: {s}\n", .{note});
    }
    for (self.helps) |help| {
        try writeSpaces(writer, gutter_width + 1);
        try writer.print("= help: {s}\n", .{help});
    }
}

fn writeSpaces(writer: anytype, count: u32) !void {
    for (0..count) |_| {
        try writer.writeAll(" ");
    }
}

fn digitCount(n: u32) u32 {
    if (n == 0) return 1;
    var val = n;
    var count: u32 = 0;
    while (val > 0) {
        val /= 10;
        count += 1;
    }
    return count;
}

/// Accumulator for diagnostics produced during compilation.
pub const DiagnosticList = struct {
    items: std.ArrayList(Diagnostic),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) DiagnosticList {
        return .{
            .items = .empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *DiagnosticList) void {
        self.items.deinit(self.allocator);
    }

    pub fn emit(self: *DiagnosticList, diag: Diagnostic) void {
        self.items.append(self.allocator, diag) catch {};
    }

    pub fn hasErrors(self: *const DiagnosticList) bool {
        for (self.items.items) |d| {
            if (d.severity == .@"error") return true;
        }
        return false;
    }

    pub fn renderAll(self: *const DiagnosticList, source: *const Source, writer: anytype) !void {
        for (self.items.items) |*d| {
            try d.render(source, writer);
            try writer.writeAll("\n");
        }
    }
};
