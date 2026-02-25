//! Pipeline orchestration: lex → parse → (future: check → codegen).
//!
//! The Driver is the central coordinator that runs each compilation
//! phase in sequence and manages the shared state (sources, intern
//! pool, diagnostics).

const std = @import("std");
const Source = @import("Source.zig");
const Span = @import("Span.zig");
const InternPool = @import("InternPool.zig");
const Token = @import("Token.zig");
const Lexer = @import("Lexer.zig");
const Ast = @import("Ast.zig");
const Parser = @import("Parser.zig");
const Diagnostic = @import("Diagnostic.zig");
const render = @import("render.zig");

const Driver = @This();

allocator: std.mem.Allocator,
pool: InternPool,
diagnostics: Diagnostic.DiagnosticList,
/// Arena for AST nodes and other compilation artifacts.
arena: std.heap.ArenaAllocator,

pub fn init(allocator: std.mem.Allocator) Driver {
    return .{
        .allocator = allocator,
        .pool = InternPool.init(allocator),
        .diagnostics = Diagnostic.DiagnosticList.init(allocator),
        .arena = std.heap.ArenaAllocator.init(allocator),
    };
}

pub fn deinit(self: *Driver) void {
    self.arena.deinit();
    self.pool.deinit();
    self.diagnostics.deinit();
}

/// Compile a single source file through the current pipeline.
/// Returns the parsed module on success.
pub fn compileFile(self: *Driver, path: []const u8) !?Ast.Module {
    // Load source.
    var source = Source.fromFile(path, 0, self.allocator) catch |e| {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stderr().writer(&buf);
        w.interface.print("error: cannot open '{s}': {}\n", .{ path, e }) catch {};
        w.interface.flush() catch {};
        return null;
    };
    defer source.deinit();

    return self.compileSource(&source);
}

/// Compile from an already-loaded Source.
pub fn compileSource(self: *Driver, source: *Source) !?Ast.Module {
    // Phase 1: Lex.
    var lexer = Lexer.init(source.text, source.file_id, &self.diagnostics);
    var tokens = try lexer.tokenize(self.allocator);
    defer tokens.deinit();

    if (self.diagnostics.hasErrors()) {
        try self.reportErrors(source);
        return null;
    }

    // Phase 2: Parse.
    var parser = Parser.init(
        &tokens,
        source.text,
        self.arena.allocator(),
        &self.pool,
        &self.diagnostics,
    );
    const module = parser.parseModule() catch {
        try self.reportErrors(source);
        return null;
    };

    if (self.diagnostics.hasErrors()) {
        try self.reportErrors(source);
        return null;
    }

    return module;
}

/// Print the AST for debugging.
pub fn dumpAst(self: *const Driver, module: *const Ast.Module) !void {
    var buf: [8192]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    try render.renderModule(module, &self.pool, &w.interface);
    try w.interface.flush();
}

fn reportErrors(self: *const Driver, source: *Source) !void {
    var buf: [8192]u8 = undefined;
    var w = std.fs.File.stderr().writer(&buf);
    try self.diagnostics.renderAll(source, &w.interface);
    try w.interface.flush();
}
