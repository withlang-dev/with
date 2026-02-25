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
const Codegen = @import("Codegen.zig");
const Sema = @import("Sema.zig");

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

    // Phase 3: Semantic analysis.
    var sema = Sema.init(self.arena.allocator(), &self.pool, &self.diagnostics);
    defer sema.deinit();
    sema.checkModule(&module);

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

/// Compile a module to an object file.
pub fn compileToObject(self: *Driver, module: *const Ast.Module, output_path: [*:0]const u8) !bool {
    var cg = Codegen.init("with_module", self.allocator) catch {
        self.writeStderr("error: failed to initialize LLVM\n");
        return false;
    };
    defer cg.deinit();

    cg.genModule(module, &self.pool) catch {
        self.writeStderr("error: code generation failed\n");
        return false;
    };

    cg.emitObjectFile(output_path) catch {
        self.writeStderr("error: failed to emit object file\n");
        return false;
    };

    return true;
}

/// Dump LLVM IR for a module to stdout.
pub fn emitIR(self: *Driver, module: *const Ast.Module) !bool {
    var cg = Codegen.init("with_module", self.allocator) catch {
        self.writeStderr("error: failed to initialize LLVM\n");
        return false;
    };
    defer cg.deinit();

    cg.genModule(module, &self.pool) catch {
        self.writeStderr("error: code generation failed\n");
        return false;
    };

    cg.printIR();
    return true;
}

/// Link an object file into a binary using the system linker.
pub fn link(obj_path: []const u8, bin_path: []const u8) !bool {
    var child = std.process.Child.init(&.{ "cc", obj_path, "-o", bin_path }, std.heap.page_allocator);
    _ = child.spawn() catch |e| {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stderr().writer(&buf);
        w.interface.print("error: failed to spawn linker: {}\n", .{e}) catch {};
        w.interface.flush() catch {};
        return false;
    };
    const term = child.wait() catch |e| {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stderr().writer(&buf);
        w.interface.print("error: linker failed: {}\n", .{e}) catch {};
        w.interface.flush() catch {};
        return false;
    };
    return term == .Exited and term.Exited == 0;
}

/// Full pipeline: parse → codegen → link → binary.
pub fn buildBinary(self: *Driver, source_path: []const u8) !?[]const u8 {
    const module = try self.compileFile(source_path) orelse return null;

    // Derive output paths from source path: foo.w → foo.o, foo
    const stem = blk: {
        const base = std.fs.path.basename(source_path);
        if (std.mem.endsWith(u8, base, ".w")) {
            break :blk base[0 .. base.len - 2];
        }
        break :blk base;
    };
    const dir = std.fs.path.dirname(source_path) orelse ".";

    // Build null-terminated object path.
    var obj_buf: [4096]u8 = undefined;
    const obj_path = std.fmt.bufPrint(&obj_buf, "{s}/{s}.o", .{ dir, stem }) catch return null;
    obj_buf[obj_path.len] = 0;

    const bin_path = std.fmt.allocPrint(self.arena.allocator(), "{s}/{s}", .{ dir, stem }) catch return null;

    const ok = try self.compileToObject(&module, obj_buf[0..obj_path.len :0]);
    if (!ok) return null;

    const link_ok = try link(obj_path, bin_path);
    if (!link_ok) {
        self.writeStderr("error: linking failed\n");
        return null;
    }

    // Clean up the .o file.
    std.fs.cwd().deleteFile(obj_path) catch {};

    return bin_path;
}

fn writeStderr(self: *const Driver, msg: []const u8) void {
    _ = self;
    var buf: [4096]u8 = undefined;
    var w = std.fs.File.stderr().writer(&buf);
    w.interface.writeAll(msg) catch {};
    w.interface.flush() catch {};
}

fn reportErrors(self: *const Driver, source: *Source) !void {
    var buf: [8192]u8 = undefined;
    var w = std.fs.File.stderr().writer(&buf);
    try self.diagnostics.renderAll(source, &w.interface);
    try w.interface.flush();
}
