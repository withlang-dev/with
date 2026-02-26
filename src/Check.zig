//! Phase-0 `check` facade.

const std = @import("std");
const Ast = @import("Ast.zig");
const Sema = @import("Sema.zig");
const Lexer = @import("Lexer.zig");
const Parser = @import("Parser.zig");
const Diagnostic = @import("Diagnostic.zig");
const InternPool = @import("InternPool.zig");

pub fn checkModule(
    allocator: std.mem.Allocator,
    pool: *InternPool,
    diagnostics: *Diagnostic.DiagnosticList,
    module: *const Ast.Module,
) void {
    var sema = Sema.init(allocator, pool, diagnostics);
    defer sema.deinit();
    sema.checkModule(module);
}

fn parseModule(source: []const u8, allocator: std.mem.Allocator, diagnostics: *Diagnostic.DiagnosticList, pool: *InternPool) !Ast.Module {
    var lexer = Lexer.init(source, 0, diagnostics);
    var tokens = try lexer.tokenize(allocator);
    defer tokens.deinit();

    var parser = Parser.init(&tokens, source, allocator, pool, diagnostics);
    return try parser.parseModule();
}

test "check facade validates well-typed module" {
    const allocator = std.testing.allocator;
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var module = try parseModule(
        \\fn add(a: i32, b: i32) -> i32 =
        \\    a + b
        \\
        \\fn main() -> i32 =
        \\    add(1, 2)
        \\
    , arena.allocator(), &diags, &pool);

    checkModule(arena.allocator(), &pool, &diags, &module);
    try std.testing.expect(!diags.hasErrors());
}

test "check facade reports type mismatch" {
    const allocator = std.testing.allocator;
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var module = try parseModule(
        \\fn main() -> i32 =
        \\    missing_name
        \\
    , arena.allocator(), &diags, &pool);

    checkModule(arena.allocator(), &pool, &diags, &module);
    try std.testing.expect(diags.hasErrors());
}
