//! Minimal MIR scaffold used to validate phase-0 module layout.
//!
//! This intentionally stays lightweight: it provides a stable in-memory
//! representation and invariants (non-empty names, non-empty bodies,
//! unique function names). Codegen can evolve independently.

const std = @import("std");

pub const Function = struct {
    name: []const u8,
    block_count: u32,
};

pub const AddError = error{
    EmptyName,
    EmptyBody,
    DuplicateFunction,
    OutOfMemory,
};

pub const Module = struct {
    allocator: std.mem.Allocator,
    functions: std.ArrayList(Function),

    pub fn init(allocator: std.mem.Allocator) Module {
        return .{
            .allocator = allocator,
            .functions = .empty,
        };
    }

    pub fn deinit(self: *Module) void {
        for (self.functions.items) |func| {
            self.allocator.free(func.name);
        }
        self.functions.deinit(self.allocator);
    }

    pub fn addFunction(self: *Module, name: []const u8, block_count: u32) AddError!void {
        if (name.len == 0) return error.EmptyName;
        if (block_count == 0) return error.EmptyBody;
        if (self.hasFunction(name)) return error.DuplicateFunction;

        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);
        try self.functions.append(self.allocator, .{
            .name = owned_name,
            .block_count = block_count,
        });
    }

    pub fn hasFunction(self: *const Module, name: []const u8) bool {
        for (self.functions.items) |func| {
            if (std.mem.eql(u8, func.name, name)) return true;
        }
        return false;
    }
};

test "mir module stores functions" {
    const allocator = std.testing.allocator;
    var mir = Module.init(allocator);
    defer mir.deinit();

    try mir.addFunction("main", 1);
    try std.testing.expect(mir.hasFunction("main"));
    try std.testing.expectEqual(@as(usize, 1), mir.functions.items.len);
}

test "mir rejects empty function name" {
    const allocator = std.testing.allocator;
    var mir = Module.init(allocator);
    defer mir.deinit();

    try std.testing.expectError(error.EmptyName, mir.addFunction("", 1));
}

test "mir rejects empty function body" {
    const allocator = std.testing.allocator;
    var mir = Module.init(allocator);
    defer mir.deinit();

    try std.testing.expectError(error.EmptyBody, mir.addFunction("main", 0));
}

test "mir rejects duplicate function names" {
    const allocator = std.testing.allocator;
    var mir = Module.init(allocator);
    defer mir.deinit();

    try mir.addFunction("main", 1);
    try std.testing.expectError(error.DuplicateFunction, mir.addFunction("main", 2));
}

