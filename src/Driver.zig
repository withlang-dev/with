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
const CImport = @import("CImport.zig");

const Driver = @This();

allocator: std.mem.Allocator,
pool: InternPool,
diagnostics: Diagnostic.DiagnosticList,
/// Arena for AST nodes and other compilation artifacts.
arena: std.heap.ArenaAllocator,
/// Set of already-imported file paths (to avoid duplicates and cycles).
imported_paths: std.StringHashMapUnmanaged(void),
/// Directory of the main source file being compiled (for relative imports).
source_dir: []const u8,
/// Next file ID for imported sources.
next_file_id: Span.FileId,

pub fn init(allocator: std.mem.Allocator) Driver {
    return .{
        .allocator = allocator,
        .pool = InternPool.init(allocator),
        .diagnostics = Diagnostic.DiagnosticList.init(allocator),
        .arena = std.heap.ArenaAllocator.init(allocator),
        .imported_paths = .empty,
        .source_dir = ".",
        .next_file_id = 1,
    };
}

pub fn deinit(self: *Driver) void {
    self.arena.deinit();
    self.pool.deinit();
    self.diagnostics.deinit();
    // Free duplicated keys from imported_paths
    var it = self.imported_paths.iterator();
    while (it.next()) |entry| {
        self.allocator.free(@constCast(entry.key_ptr.*));
    }
    self.imported_paths.deinit(self.allocator);
}

/// Compile a single source file through the current pipeline.
/// Returns the parsed module on success.
pub fn compileFile(self: *Driver, path: []const u8) !?Ast.Module {
    // Store source directory for import resolution.
    self.source_dir = std.fs.path.dirname(path) orelse ".";

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
    var module = parser.parseModule() catch {
        try self.reportErrors(source);
        return null;
    };

    if (self.diagnostics.hasErrors()) {
        try self.reportErrors(source);
        return null;
    }

    // Phase 2.5a: Process c_import declarations (expand to extern fn decls).
    module = self.processCImports(module) catch {
        self.writeStderr("error: c_import processing failed\n");
        return null;
    };

    // Phase 2.5b: Process use imports (expand to imported declarations).
    module = self.processImports(module) catch {
        self.writeStderr("error: import processing failed\n");
        return null;
    };

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

/// Compile a module to an object file. Returns whether async is used.
pub fn compileToObject(self: *Driver, module: *const Ast.Module, output_path: [*:0]const u8) !?bool {
    var cg = Codegen.init("with_module", self.allocator) catch {
        self.writeStderr("error: failed to initialize LLVM\n");
        return null;
    };
    defer cg.deinit();

    cg.genModule(module, &self.pool) catch {
        self.writeStderr("error: code generation failed\n");
        return null;
    };

    cg.emitObjectFile(output_path) catch {
        self.writeStderr("error: failed to emit object file\n");
        return null;
    };

    return cg.uses_async;
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
    return linkWithExtra(obj_path, bin_path, &.{});
}

/// Link with extra object files (e.g., fiber runtime for async programs).
pub fn linkWithExtra(obj_path: []const u8, bin_path: []const u8, extra_objs: []const []const u8) !bool {
    var args_buf: [32][]const u8 = undefined;
    var argc: usize = 0;
    args_buf[argc] = "cc";
    argc += 1;
    args_buf[argc] = obj_path;
    argc += 1;
    for (extra_objs) |extra| {
        args_buf[argc] = extra;
        argc += 1;
    }
    args_buf[argc] = "-o";
    argc += 1;
    args_buf[argc] = bin_path;
    argc += 1;

    var child = std.process.Child.init(args_buf[0..argc], std.heap.page_allocator);
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

    const uses_async = try self.compileToObject(&module, obj_buf[0..obj_path.len :0]);
    if (uses_async == null) return null;

    // If async is used, find and link the fiber runtime objects.
    const link_ok = if (uses_async.?) blk: {
        // Find runtime objects relative to the compiler binary.
        const exe_dir = self.findExeDir() orelse {
            break :blk try linkWithExtra(obj_path, bin_path, &.{});
        };
        var rt1_buf: [4096]u8 = undefined;
        var rt2_buf: [4096]u8 = undefined;
        const rt1 = std.fmt.bufPrint(&rt1_buf, "{s}/runtime/fiber.o", .{exe_dir}) catch break :blk try linkWithExtra(obj_path, bin_path, &.{});
        const rt2 = std.fmt.bufPrint(&rt2_buf, "{s}/runtime/fiber_asm.o", .{exe_dir}) catch break :blk try linkWithExtra(obj_path, bin_path, &.{});
        break :blk try linkWithExtra(obj_path, bin_path, &.{ rt1, rt2 });
    } else try link(obj_path, bin_path);

    if (!link_ok) {
        self.writeStderr("error: linking failed\n");
        return null;
    }

    // Clean up the .o file.
    std.fs.cwd().deleteFile(obj_path) catch {};

    return bin_path;
}

/// Find the directory containing the compiler executable (for runtime objects).
fn findExeDir(self: *Driver) ?[]const u8 {
    var buf: [4096]u8 = undefined;
    const exe_path = std.fs.selfExePath(&buf) catch return null;
    const dir = std.fs.path.dirname(exe_path) orelse return null;
    return std.fmt.allocPrint(self.arena.allocator(), "{s}", .{dir}) catch null;
}

// ── Import resolution ───────────────────────────────────────────

const ImportError = error{ OutOfMemory, ParseFailed, PathTooLong, NotFound };

/// Resolve `use` declarations by loading and parsing imported files,
/// then replacing use_decl nodes with the imported declarations.
fn processImports(self: *Driver, module: Ast.Module) ImportError!Ast.Module {
    var has_imports = false;
    for (module.decls) |decl| {
        if (decl.kind == .use_decl) {
            const path = decl.kind.use_decl.path;
            if (path.len > 0) {
                has_imports = true;
                break;
            }
        }
    }
    if (!has_imports) return module;

    const arena_alloc = self.arena.allocator();
    var new_decls: std.ArrayList(Ast.Decl) = .empty;

    for (module.decls) |decl| {
        if (decl.kind == .use_decl) {
            const use = decl.kind.use_decl;
            if (use.path.len == 0) {
                try new_decls.append(arena_alloc, decl);
                continue;
            }

            // Try to resolve the use path to a file.
            const file_path = self.resolveModulePath(use.path) catch {
                // Unresolvable import — keep the use_decl (Sema ignores it)
                try new_decls.append(arena_alloc, decl);
                continue;
            };

            if (file_path) |path| {
                // Check for duplicate imports.
                if (self.imported_paths.get(path) != null) {
                    // Already imported — skip.
                    continue;
                }

                // Mark as imported.
                const key = self.allocator.dupe(u8, path) catch {
                    try new_decls.append(arena_alloc, decl);
                    continue;
                };
                self.imported_paths.put(self.allocator, key, {}) catch {
                    self.allocator.free(key);
                    try new_decls.append(arena_alloc, decl);
                    continue;
                };

                // Parse the imported file.
                const imported_decls = self.parseImportedFile(path) catch {
                    // Failed to parse — keep original use_decl
                    try new_decls.append(arena_alloc, decl);
                    continue;
                };

                // Add all declarations from the imported file.
                try new_decls.appendSlice(arena_alloc, imported_decls);
            } else {
                // No file found — keep the use_decl
                try new_decls.append(arena_alloc, decl);
            }
        } else {
            try new_decls.append(arena_alloc, decl);
        }
    }

    return .{
        .decls = new_decls.items,
        .span = module.span,
    };
}

/// Resolve a module path (e.g., ["std", "string"]) to a file path.
/// Search order:
///   1. Relative to source directory: <source_dir>/<path>.w
///   2. In lib/ relative to the compiler binary: lib/<path>.w
///   3. In lib/ relative to working directory: lib/<path>.w
fn resolveModulePath(self: *Driver, path: []const Ast.Symbol) ImportError!?[]const u8 {
    const arena_alloc = self.arena.allocator();

    // Build the relative path: join segments with '/' and append '.w'
    var path_buf: [4096]u8 = undefined;
    var pos: usize = 0;
    for (path, 0..) |seg, i| {
        if (i > 0) {
            path_buf[pos] = '/';
            pos += 1;
        }
        const name = self.pool.resolve(seg);
        if (pos + name.len >= path_buf.len) return null;
        @memcpy(path_buf[pos .. pos + name.len], name);
        pos += name.len;
    }
    @memcpy(path_buf[pos .. pos + 2], ".w");
    pos += 2;
    const rel_path = path_buf[0..pos];

    // Strategy 1: relative to source directory
    {
        const full = std.fmt.allocPrint(arena_alloc, "{s}/{s}", .{ self.source_dir, rel_path }) catch return null;
        if (fileExists(full)) return full;
    }

    // Strategy 2: lib/ relative to project root (find by looking for build.zig)
    const project_root = findProjectRoot() catch null;
    if (project_root) |root| {
        const full = std.fmt.allocPrint(arena_alloc, "{s}/lib/{s}", .{ root, rel_path }) catch return null;
        if (fileExists(full)) return full;
    }

    // Strategy 3: lib/ relative to working directory
    {
        const full = std.fmt.allocPrint(arena_alloc, "lib/{s}", .{rel_path}) catch return null;
        if (fileExists(full)) return full;
    }

    return null;
}

/// Parse an imported file and return its declarations.
/// Recursively processes c_import and use declarations in the imported file.
fn parseImportedFile(self: *Driver, path: []const u8) ImportError![]const Ast.Decl {
    const arena_alloc = self.arena.allocator();
    const file_id = self.next_file_id;
    self.next_file_id += 1;

    // Load and lex the file.
    var source = Source.fromFile(path, file_id, self.allocator) catch return error.ParseFailed;
    defer source.deinit();

    var lexer = Lexer.init(source.text, source.file_id, &self.diagnostics);
    var tokens = lexer.tokenize(self.allocator) catch return error.ParseFailed;
    defer tokens.deinit();

    if (self.diagnostics.hasErrors()) return error.ParseFailed;

    // Parse.
    var parser = Parser.init(
        &tokens,
        source.text,
        arena_alloc,
        &self.pool,
        &self.diagnostics,
    );
    var module = parser.parseModule() catch return error.ParseFailed;

    if (self.diagnostics.hasErrors()) return error.ParseFailed;

    // Process c_imports in the imported file.
    module = self.processCImports(module) catch return error.ParseFailed;

    // Recursively process use imports in the imported file.
    // Save and restore source_dir for relative import resolution.
    const saved_dir = self.source_dir;
    self.source_dir = std.fs.path.dirname(path) orelse ".";
    module = try self.processImports(module);
    self.source_dir = saved_dir;

    return module.decls;
}

/// Replace c_import declarations with synthetic extern fn declarations.
fn processCImports(self: *Driver, module: Ast.Module) !Ast.Module {
    var has_c_import = false;
    for (module.decls) |decl| {
        if (decl.kind == .c_import) {
            has_c_import = true;
            break;
        }
    }
    if (!has_c_import) return module;

    const arena_alloc = self.arena.allocator();
    var new_decls: std.ArrayList(Ast.Decl) = .empty;

    for (module.decls) |decl| {
        if (decl.kind == .c_import) {
            const synthetic = try CImport.processCImport(
                decl.kind.c_import.header_code,
                arena_alloc,
                &self.pool,
            );
            try new_decls.appendSlice(arena_alloc, synthetic);
        } else {
            try new_decls.append(arena_alloc, decl);
        }
    }

    return .{
        .decls = new_decls.items,
        .span = module.span,
    };
}

// ── Helpers ─────────────────────────────────────────────────────

fn fileExists(path: []const u8) bool {
    const file = std.fs.cwd().openFile(path, .{}) catch return false;
    file.close();
    return true;
}

/// Walk up from CWD to find the project root (directory containing build.zig).
fn findProjectRoot() error{ PathTooLong, NotFound }![]const u8 {
    var path_buf: [4096]u8 = undefined;
    const cwd = std.process.getCwd(&path_buf) catch return error.NotFound;
    // We need to iterate up parent directories; use a separate buffer to track current dir
    var dir: []const u8 = cwd;
    var check_buf: [4096]u8 = undefined;
    while (true) {
        const check_path = std.fmt.bufPrint(&check_buf, "{s}/build.zig", .{dir}) catch return error.PathTooLong;
        const file = std.fs.cwd().openFile(check_path, .{}) catch {
            const parent = std.fs.path.dirname(dir) orelse return error.NotFound;
            if (std.mem.eql(u8, parent, dir)) return error.NotFound;
            dir = parent;
            continue;
        };
        file.close();
        return dir;
    }
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
