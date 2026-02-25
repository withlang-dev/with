//! Source file storage and offset-to-location mapping.
//!
//! `Source` owns the text content of a loaded file and provides
//! efficient offset → line/column translation via a precomputed
//! line-start table.

const std = @import("std");
const Span = @import("Span.zig");

const Source = @This();

/// Human-readable file path (for diagnostics).
name: []const u8,
/// The full source text.
text: []const u8,
/// Byte offsets where each line begins (0-indexed lines).
line_offsets: std.ArrayList(u32),
/// Identifier used in Span.file.
file_id: Span.FileId,
/// Whether we own the text buffer (and must free it on deinit).
owns_text: bool,

allocator: std.mem.Allocator,

pub const Location = struct {
    line: u32, // 0-indexed
    col: u32, // 0-indexed, byte offset within line
};

/// Build the line-offset table from source text.
fn computeLineOffsets(text: []const u8, allocator: std.mem.Allocator) std.ArrayList(u32) {
    var offsets: std.ArrayList(u32) = .empty;
    offsets.append(allocator, 0) catch unreachable; // line 0 starts at byte 0
    for (0..text.len) |i| {
        if (text[i] == '\n') {
            offsets.append(allocator, @intCast(i + 1)) catch unreachable;
        }
    }
    return offsets;
}

/// Create a Source from a file path.  Reads the entire file into memory.
pub fn fromFile(path: []const u8, file_id: Span.FileId, allocator: std.mem.Allocator) !Source {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const text = try file.readToEndAlloc(allocator, std.math.maxInt(u32));
    return .{
        .name = path,
        .text = text,
        .line_offsets = computeLineOffsets(text, allocator),
        .file_id = file_id,
        .owns_text = true,
        .allocator = allocator,
    };
}

/// Create a Source from an in-memory string (useful for tests).
pub fn fromString(name: []const u8, text: []const u8, file_id: Span.FileId, allocator: std.mem.Allocator) Source {
    return .{
        .name = name,
        .text = text,
        .line_offsets = computeLineOffsets(text, allocator),
        .file_id = file_id,
        .owns_text = false,
        .allocator = allocator,
    };
}

/// Convert a byte offset to a line/column location.
pub fn offsetToLocation(self: *const Source, offset: u32) Location {
    // Binary search for the line containing `offset`.
    var lo: u32 = 0;
    var hi: u32 = @intCast(self.line_offsets.items.len);
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        if (self.line_offsets.items[mid] <= offset) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    const line = lo - 1;
    const col = offset - self.line_offsets.items[line];
    return .{ .line = line, .col = col };
}

/// Extract the source line that contains the given byte offset.
pub fn lineText(self: *const Source, line: u32) []const u8 {
    const start = self.line_offsets.items[line];
    const end = if (line + 1 < self.line_offsets.items.len)
        self.line_offsets.items[line + 1]
    else
        @as(u32, @intCast(self.text.len));
    // Strip trailing newline if present.
    const slice = self.text[start..end];
    if (slice.len > 0 and slice[slice.len - 1] == '\n') {
        return slice[0 .. slice.len - 1];
    }
    return slice;
}

pub fn deinit(self: *Source) void {
    if (self.owns_text) {
        self.allocator.free(self.text);
    }
    self.line_offsets.deinit(self.allocator);
}
