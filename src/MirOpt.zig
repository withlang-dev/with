const std = @import("std");

pub const CallKind = enum {
    dyn_dispatch,
    direct,
};

pub const CallSite = struct {
    kind: CallKind,
    receiver_type_known: bool,
};

pub const AllocationKind = enum {
    box,
    stack,
};

pub const Allocation = struct {
    kind: AllocationKind,
    escapes: bool,
};

pub const Field = struct {
    name: []const u8,
    read_count: u32,
    removed: bool = false,
};

pub const Move = struct {
    source_consumed_immediately: bool,
    elided: bool = false,
};

pub const Function = struct {
    name: []const u8,
    calls: std.ArrayList(CallSite),
    allocations: std.ArrayList(Allocation),
    moves: std.ArrayList(Move),

    pub fn init(allocator: std.mem.Allocator, name: []const u8) !Function {
        return .{
            .name = try allocator.dupe(u8, name),
            .calls = .empty,
            .allocations = .empty,
            .moves = .empty,
        };
    }

    pub fn deinit(self: *Function, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        self.calls.deinit(allocator);
        self.allocations.deinit(allocator);
        self.moves.deinit(allocator);
    }
};

pub const TypeDecl = struct {
    name: []const u8,
    fields: std.ArrayList(Field),

    pub fn init(allocator: std.mem.Allocator, name: []const u8) !TypeDecl {
        return .{
            .name = try allocator.dupe(u8, name),
            .fields = .empty,
        };
    }

    pub fn deinit(self: *TypeDecl, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        for (self.fields.items) |field| allocator.free(field.name);
        self.fields.deinit(allocator);
    }
};

pub const Module = struct {
    allocator: std.mem.Allocator,
    functions: std.ArrayList(Function),
    types: std.ArrayList(TypeDecl),

    pub fn init(allocator: std.mem.Allocator) Module {
        return .{
            .allocator = allocator,
            .functions = .empty,
            .types = .empty,
        };
    }

    pub fn deinit(self: *Module) void {
        for (self.functions.items) |*func| func.deinit(self.allocator);
        self.functions.deinit(self.allocator);
        for (self.types.items) |*ty| ty.deinit(self.allocator);
        self.types.deinit(self.allocator);
    }

    pub fn addFunction(self: *Module, name: []const u8) !*Function {
        try self.functions.append(self.allocator, try Function.init(self.allocator, name));
        return &self.functions.items[self.functions.items.len - 1];
    }

    pub fn addType(self: *Module, name: []const u8) !*TypeDecl {
        try self.types.append(self.allocator, try TypeDecl.init(self.allocator, name));
        return &self.types.items[self.types.items.len - 1];
    }
};

pub const Summary = struct {
    devirtualized_calls: usize = 0,
    stack_promoted_boxes: usize = 0,
    removed_fields: usize = 0,
    elided_moves: usize = 0,
};

pub fn optimize(module: *Module) Summary {
    var summary: Summary = .{};
    summary.devirtualized_calls = devirtualize(module);
    summary.stack_promoted_boxes = promoteNonEscapingBoxes(module);
    summary.removed_fields = eliminateDeadFields(module);
    summary.elided_moves = elideRedundantMoves(module);
    return summary;
}

fn devirtualize(module: *Module) usize {
    var changed: usize = 0;
    for (module.functions.items) |*func| {
        for (func.calls.items) |*call| {
            if (call.kind == .dyn_dispatch and call.receiver_type_known) {
                call.kind = .direct;
                changed += 1;
            }
        }
    }
    return changed;
}

fn promoteNonEscapingBoxes(module: *Module) usize {
    var changed: usize = 0;
    for (module.functions.items) |*func| {
        for (func.allocations.items) |*alloc| {
            if (alloc.kind == .box and !alloc.escapes) {
                alloc.kind = .stack;
                changed += 1;
            }
        }
    }
    return changed;
}

fn eliminateDeadFields(module: *Module) usize {
    var changed: usize = 0;
    for (module.types.items) |*ty| {
        for (ty.fields.items) |*field| {
            if (!field.removed and field.read_count == 0) {
                field.removed = true;
                changed += 1;
            }
        }
    }
    return changed;
}

fn elideRedundantMoves(module: *Module) usize {
    var changed: usize = 0;
    for (module.functions.items) |*func| {
        for (func.moves.items) |*mv| {
            if (!mv.elided and mv.source_consumed_immediately) {
                mv.elided = true;
                changed += 1;
            }
        }
    }
    return changed;
}

test "devirtualization rewrites only known receiver call sites" {
    var module = Module.init(std.testing.allocator);
    defer module.deinit();

    const func = try module.addFunction("f");
    try func.calls.append(std.testing.allocator, .{ .kind = .dyn_dispatch, .receiver_type_known = true });
    try func.calls.append(std.testing.allocator, .{ .kind = .dyn_dispatch, .receiver_type_known = false });

    const summary = optimize(&module);
    try std.testing.expectEqual(@as(usize, 1), summary.devirtualized_calls);
    try std.testing.expectEqual(CallKind.direct, func.calls.items[0].kind);
    try std.testing.expectEqual(CallKind.dyn_dispatch, func.calls.items[1].kind);
}

test "escape analysis promotes only non-escaping Box allocations" {
    var module = Module.init(std.testing.allocator);
    defer module.deinit();

    const func = try module.addFunction("f");
    try func.allocations.append(std.testing.allocator, .{ .kind = .box, .escapes = false });
    try func.allocations.append(std.testing.allocator, .{ .kind = .box, .escapes = true });

    const summary = optimize(&module);
    try std.testing.expectEqual(@as(usize, 1), summary.stack_promoted_boxes);
    try std.testing.expectEqual(AllocationKind.stack, func.allocations.items[0].kind);
    try std.testing.expectEqual(AllocationKind.box, func.allocations.items[1].kind);
}

test "dead field elimination removes unread fields only" {
    var module = Module.init(std.testing.allocator);
    defer module.deinit();

    const ty = try module.addType("T");
    try ty.fields.append(std.testing.allocator, .{
        .name = try std.testing.allocator.dupe(u8, "unused"),
        .read_count = 0,
    });
    try ty.fields.append(std.testing.allocator, .{
        .name = try std.testing.allocator.dupe(u8, "used"),
        .read_count = 2,
    });

    const summary = optimize(&module);
    try std.testing.expectEqual(@as(usize, 1), summary.removed_fields);
    try std.testing.expect(ty.fields.items[0].removed);
    try std.testing.expect(!ty.fields.items[1].removed);
}

test "move elision marks immediate consume moves only" {
    var module = Module.init(std.testing.allocator);
    defer module.deinit();

    const func = try module.addFunction("f");
    try func.moves.append(std.testing.allocator, .{ .source_consumed_immediately = true });
    try func.moves.append(std.testing.allocator, .{ .source_consumed_immediately = false });

    const summary = optimize(&module);
    try std.testing.expectEqual(@as(usize, 1), summary.elided_moves);
    try std.testing.expect(func.moves.items[0].elided);
    try std.testing.expect(!func.moves.items[1].elided);
}

test "optimization summary aggregates all pass counts" {
    var module = Module.init(std.testing.allocator);
    defer module.deinit();

    const func = try module.addFunction("f");
    try func.calls.append(std.testing.allocator, .{ .kind = .dyn_dispatch, .receiver_type_known = true });
    try func.allocations.append(std.testing.allocator, .{ .kind = .box, .escapes = false });
    try func.moves.append(std.testing.allocator, .{ .source_consumed_immediately = true });

    const ty = try module.addType("T");
    try ty.fields.append(std.testing.allocator, .{
        .name = try std.testing.allocator.dupe(u8, "unused"),
        .read_count = 0,
    });

    const summary = optimize(&module);
    try std.testing.expectEqual(@as(usize, 1), summary.devirtualized_calls);
    try std.testing.expectEqual(@as(usize, 1), summary.stack_promoted_boxes);
    try std.testing.expectEqual(@as(usize, 1), summary.removed_fields);
    try std.testing.expectEqual(@as(usize, 1), summary.elided_moves);
}
