//! String interning for identifiers and keywords.
//!
//! All identifier strings are deduplicated and stored once. Comparisons
//! become integer equality checks on `Symbol` values.

const std = @import("std");

/// An interned string handle — index into the pool.
pub const Symbol = u32;

const InternPool = @This();

/// Backing storage for all interned bytes, concatenated.
bytes: std.ArrayList(u8),
/// Maps string content to its Symbol.
map: std.StringHashMapUnmanaged(Symbol),
/// Start offsets into `bytes` for each symbol.  symbols[id] .. symbols[id+1]
/// gives the byte range.  An extra sentinel entry stores the total length.
offsets: std.ArrayList(u32),

allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) InternPool {
    var offsets: std.ArrayList(u32) = .empty;
    offsets.append(allocator, 0) catch unreachable;
    return .{
        .bytes = .empty,
        .map = .empty,
        .offsets = offsets,
        .allocator = allocator,
    };
}

pub fn deinit(self: *InternPool) void {
    // Free duplicated map keys.
    var it = self.map.iterator();
    while (it.next()) |entry| {
        self.allocator.free(@constCast(entry.key_ptr.*));
    }
    self.bytes.deinit(self.allocator);
    self.map.deinit(self.allocator);
    self.offsets.deinit(self.allocator);
}

/// Intern a string, returning its `Symbol`.  If the string was already
/// interned, returns the existing symbol.
pub fn intern(self: *InternPool, str: []const u8) !Symbol {
    if (self.map.get(str)) |existing| return existing;

    const id: Symbol = @intCast(self.offsets.items.len - 1);
    try self.bytes.appendSlice(self.allocator, str);
    try self.offsets.append(self.allocator, @intCast(self.bytes.items.len));

    // Duplicate the string for the map key so it doesn't depend on
    // the caller's memory or our bytes buffer (which can reallocate).
    const key = try self.allocator.dupe(u8, str);
    try self.map.put(self.allocator, key, id);
    return id;
}

/// Retrieve the string content for a previously interned symbol.
pub fn resolve(self: *const InternPool, sym: Symbol) []const u8 {
    const start = self.offsets.items[sym];
    const end = self.offsets.items[sym + 1];
    return self.bytes.items[start..end];
}
