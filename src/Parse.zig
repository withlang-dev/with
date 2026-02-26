//! Phase-0 `parse` facade.

const std = @import("std");
const Ast = @import("Ast.zig");
const ParserImpl = @import("Parser.zig");
const Lexer = @import("Lexer.zig");
const Diagnostic = @import("Diagnostic.zig");
const InternPool = @import("InternPool.zig");

pub const Parser = ParserImpl;

fn parseModule(
    source: []const u8,
    token_allocator: std.mem.Allocator,
    ast_allocator: std.mem.Allocator,
    pool: *InternPool,
    diagnostics: *Diagnostic.DiagnosticList,
) !Ast.Module {
    var lexer = Lexer.init(source, 0, diagnostics);
    var tokens = try lexer.tokenize(token_allocator);
    defer tokens.deinit();

    var parser = Parser.init(&tokens, source, ast_allocator, pool, diagnostics);
    return try parser.parseModule();
}

fn parseSource(source: []const u8, allocator: std.mem.Allocator, diagnostics: *Diagnostic.DiagnosticList) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    _ = try parseModule(source, allocator, arena.allocator(), &pool, diagnostics);
}

test "parse facade parses valid source" {
    const allocator = std.testing.allocator;
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    try parseSource(
        \\fn main() -> i32 =
        \\    0
        \\
    , allocator, &diags);

    try std.testing.expect(!diags.hasErrors());
}

test "parse facade reports syntax errors" {
    const allocator = std.testing.allocator;
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    try parseSource(
        \\fn main( -> i32 =
        \\    0
        \\
    , allocator, &diags);

    try std.testing.expect(diags.hasErrors());
}

test "parse module declarations and use imports" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    const module = try parseModule(
        \\module demo.app
        \\use std.io
        \\use std.collections
        \\fn main() -> i32 =
        \\    0
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(!diags.hasErrors());
    try std.testing.expectEqual(@as(usize, 3), module.decls.len);
    try std.testing.expect(module.decls[0].kind == .use_decl);
    try std.testing.expect(module.decls[1].kind == .use_decl);
    try std.testing.expect(module.decls[2].kind == .function);
    try std.testing.expectEqual(@as(usize, 2), module.decls[0].kind.use_decl.path.len);
    try std.testing.expectEqual(@as(usize, 2), module.decls[1].kind.use_decl.path.len);
}

test "parse reports malformed use import" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    _ = try parseModule(
        \\module broken
        \\use
        \\fn main() -> i32 =
        \\    0
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(diags.hasErrors());
}

test "parse function definitions with parameters and return type" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    const module = try parseModule(
        \\fn add(a: i32, b: i32) -> i32 =
        \\    a + b
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(!diags.hasErrors());
    try std.testing.expectEqual(@as(usize, 1), module.decls.len);
    try std.testing.expect(module.decls[0].kind == .function);
    const fn_decl = module.decls[0].kind.function;
    try std.testing.expectEqual(@as(usize, 2), fn_decl.params.len);
    try std.testing.expect(fn_decl.return_type != null);
}

test "parse reports malformed function declaration" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    _ = try parseModule(
        \\fn (a: i32) -> i32 =
        \\    a
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(diags.hasErrors());
}

test "parse let/var/defer in function body" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    const module = try parseModule(
        \\fn main() -> i32 =
        \\    let x = 1
        \\    var y = 2
        \\    defer y = y + 1
        \\    x + y
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(!diags.hasErrors());
    try std.testing.expectEqual(@as(usize, 1), module.decls.len);
    const fn_decl = module.decls[0].kind.function;
    try std.testing.expect(fn_decl.body.kind == .block);
    const block = fn_decl.body.kind.block;
    try std.testing.expectEqual(@as(usize, 3), block.stmts.len);
    try std.testing.expect(block.stmts[0].kind == .let_binding);
    try std.testing.expect(block.stmts[1].kind == .let_binding);
    try std.testing.expect(block.stmts[2].kind == .defer_expr);
    try std.testing.expect(!block.stmts[0].kind.let_binding.is_mut);
    try std.testing.expect(block.stmts[1].kind.let_binding.is_mut);
    try std.testing.expect(block.tail != null);
}

test "parse reports malformed defer statement" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    _ = try parseModule(
        \\fn main() -> i32 =
        \\    defer
        \\    0
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(diags.hasErrors());
}

test "parse core expressions in function blocks" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    const module = try parseModule(
        \\fn foo(x: i32) -> i32 =
        \\    x
        \\
        \\fn main() -> i32 =
        \\    let callv = foo(1)
        \\    let fieldv = obj.field
        \\    let indexv = arr[0]
        \\    let unaryv = -1
        \\    let binaryv = 1 + 2
        \\    let ifv = if 1 > 0 then 1 else 0
        \\    let rangev = 0..=10
        \\    callv
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(!diags.hasErrors());
    try std.testing.expectEqual(@as(usize, 2), module.decls.len);
    const main_fn = module.decls[1].kind.function;
    try std.testing.expect(main_fn.body.kind == .block);
    const block = main_fn.body.kind.block;
    try std.testing.expectEqual(@as(usize, 7), block.stmts.len);
    try std.testing.expect(block.stmts[0].kind.let_binding.value.kind == .call);
    try std.testing.expect(block.stmts[1].kind.let_binding.value.kind == .field_access);
    try std.testing.expect(block.stmts[2].kind.let_binding.value.kind == .index);
    try std.testing.expect(block.stmts[3].kind.let_binding.value.kind == .unary);
    try std.testing.expect(block.stmts[4].kind.let_binding.value.kind == .binary);
    try std.testing.expect(block.stmts[5].kind.let_binding.value.kind == .if_expr);
    try std.testing.expect(block.stmts[6].kind.let_binding.value.kind == .range);
    try std.testing.expect(block.tail != null);
}

test "parse reports malformed core expression syntax" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    _ = try parseModule(
        \\fn main() -> i32 =
        \\    let x = foo(1
        \\    x
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(diags.hasErrors());
}

test "parse type syntax forms in function signatures" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    const module = try parseModule(
        \\fn typed(a: i32, b: MyType, c: Vec[i32], d: &i32, e: &mut i32, f: fn(i32) -> i32, g: (i32, bool)) -> i32 =
        \\    0
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(!diags.hasErrors());
    try std.testing.expectEqual(@as(usize, 1), module.decls.len);
    const fn_decl = module.decls[0].kind.function;
    try std.testing.expectEqual(@as(usize, 7), fn_decl.params.len);
    try std.testing.expect(fn_decl.params[0].type_expr.?.kind == .named);
    try std.testing.expect(fn_decl.params[1].type_expr.?.kind == .named);
    try std.testing.expect(fn_decl.params[2].type_expr.?.kind == .generic);
    try std.testing.expect(fn_decl.params[3].type_expr.?.kind == .ref_type);
    try std.testing.expect(fn_decl.params[4].type_expr.?.kind == .ref_type);
    try std.testing.expect(fn_decl.params[5].type_expr.?.kind == .fn_type);
    try std.testing.expect(fn_decl.params[6].type_expr.?.kind == .tuple_type);
    try std.testing.expect(fn_decl.return_type != null);
}

test "parse reports malformed type syntax" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    _ = try parseModule(
        \\fn bad(x: Vec[i32) -> i32 =
        \\    0
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(diags.hasErrors());
}

test "parse unsafe expressions and unsafe blocks" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    const module = try parseModule(
        \\fn main() -> i32 =
        \\    unsafe:
        \\        let x = 1
        \\        x
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(!diags.hasErrors());
    try std.testing.expectEqual(@as(usize, 1), module.decls.len);
    const body = module.decls[0].kind.function.body;
    try std.testing.expect(body.kind == .block);
}

test "parse reports malformed unsafe block" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    _ = try parseModule(
        \\fn main() -> i32 =
        \\    unsafe:
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(diags.hasErrors());
}

test "parser recovers to next top-level declaration after error" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    var pool = InternPool.init(allocator);
    defer pool.deinit();
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    const module = try parseModule(
        \\fn broken( -> i32 =
        \\    0
        \\
        \\fn recovered() -> i32 =
        \\    1
        \\
    , allocator, arena.allocator(), &pool, &diags);

    try std.testing.expect(diags.hasErrors());
    var found_recovered = false;
    for (module.decls) |decl| {
        if (decl.kind == .function) {
            const name = pool.resolve(decl.kind.function.name);
            if (std.mem.eql(u8, name, "recovered")) {
                found_recovered = true;
            }
        }
    }
    try std.testing.expect(found_recovered);
}
