//! Pipeline orchestration: lex → parse → (future: check → codegen).
//!
//! The Driver is the central coordinator that runs each compilation
//! phase in sequence and manages the shared state (sources, intern
//! pool, diagnostics).

const std = @import("std");
const builtin = @import("builtin");
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
/// Rendered warning messages to print after compilation.
pending_warnings: std.ArrayList([]const u8),
/// Optimization level: 0=none, 1=basic, 2=standard, 3=aggressive.
opt_level: u8,
/// Link libraries requested by `use c_import(..., link: "...")`.
c_import_link_libs: std.AutoHashMapUnmanaged(Ast.Symbol, void),
/// In-memory cache for c_import expansions, keyed by header code text.
c_import_cache: std.StringHashMapUnmanaged([]const Ast.Decl),
/// Emit c_import cache hit/miss diagnostics to stderr when enabled.
trace_c_import_cache: bool,
/// Freestanding mode: no std library (§18.7).
no_std: bool,
/// Alloc tier: core + heap types but no OS (§18.7).
alloc: bool,
/// Path of the main source file being compiled (for __FILE__).
current_source_path: []const u8 = "<unknown>",
/// Source text of the main file (for __LINE__ span→line mapping).
current_source_text: []const u8 = "",

pub fn init(allocator: std.mem.Allocator) Driver {
    return .{
        .allocator = allocator,
        .pool = InternPool.init(allocator),
        .diagnostics = Diagnostic.DiagnosticList.init(allocator),
        .arena = std.heap.ArenaAllocator.init(allocator),
        .imported_paths = .empty,
        .source_dir = ".",
        .next_file_id = 1,
        .pending_warnings = .empty,
        .opt_level = 0,
        .c_import_link_libs = .empty,
        .c_import_cache = .empty,
        .trace_c_import_cache = false,
        .no_std = false,
        .alloc = false,
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
    self.pending_warnings.deinit(self.allocator);
    self.c_import_link_libs.deinit(self.allocator);
    var c_import_it = self.c_import_cache.iterator();
    while (c_import_it.next()) |entry| {
        self.allocator.free(@constCast(entry.key_ptr.*));
    }
    self.c_import_cache.deinit(self.allocator);
}

/// Compile a single source file through the current pipeline.
/// Returns the parsed module on success.
pub fn compileFile(self: *Driver, path: []const u8) !?Ast.Module {
    // Store source directory for import resolution.
    self.source_dir = std.fs.path.dirname(path) orelse ".";
    self.current_source_path = path;

    // Load source.
    var source = Source.fromFile(path, 0, self.allocator) catch |e| {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stderr().writer(&buf);
        w.interface.print("error: cannot open '{s}': {}\n", .{ path, e }) catch {};
        w.interface.flush() catch {};
        return null;
    };
    defer source.deinit();

    const module = try self.compileSource(&source);

    // Render warnings before source is deinitialized.
    if (module != null) {
        for (self.diagnostics.items.items) |diag| {
            if (diag.severity == .warning) {
                const loc = source.offsetToLocation(diag.primary.start);
                var msg_buf: [1024]u8 = undefined;
                const msg = std.fmt.bufPrint(&msg_buf, "warning: {s}\n --> {s}:{d}:{d}\n", .{
                    diag.message, source.name, loc.line + 1, loc.col + 1,
                }) catch continue;
                self.pending_warnings.append(self.allocator, self.arena.allocator().dupe(u8, msg) catch continue) catch {};
            }
        }
    }

    return module;
}

/// Compile from an already-loaded Source.
pub fn compileSource(self: *Driver, source: *Source) !?Ast.Module {
    // Store source text in arena for __LINE__ support.
    self.current_source_text = self.arena.allocator().dupe(u8, source.text) catch "";

    // Reset per-compilation-unit c_import link directives.
    self.c_import_link_libs.clearRetainingCapacity();
    self.trace_c_import_cache = blk: {
        const value = std.process.getEnvVarOwned(self.allocator, "WITH_TRACE_CIMPORT_CACHE") catch
            break :blk false;
        defer self.allocator.free(value);
        break :blk value.len > 0 and !std.mem.eql(u8, value, "0");
    };

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
    sema.no_std = self.no_std;
    sema.alloc = self.alloc;
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

    cg.source_file = self.current_source_path;
    cg.source_text = self.current_source_text;
    cg.genModule(module, &self.pool) catch |err| {
        if (cg.comptime_error_msg) |msg| {
            self.writeStderr("error: comptime_error: ");
            self.writeStderr(msg);
            self.writeStderr("\n");
        } else if (cg.codegen_error_detail) |detail| {
            self.writeStderr("error: ");
            self.writeStderr(detail);
            self.writeStderr("\n");
        } else {
            self.writeStderr("error: code generation failed (");
            self.writeStderr(@errorName(err));
            self.writeStderr(")\n");
        }
        return null;
    };

    // Run optimization passes if requested.
    if (self.opt_level > 0) {
        cg.optimize(self.opt_level);
    }

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

    cg.source_file = self.current_source_path;
    cg.source_text = self.current_source_text;
    cg.genModule(module, &self.pool) catch |err| {
        if (cg.comptime_error_msg) |msg| {
            self.writeStderr("error: comptime_error: ");
            self.writeStderr(msg);
            self.writeStderr("\n");
        } else if (cg.codegen_error_detail) |detail| {
            self.writeStderr("error: ");
            self.writeStderr(detail);
            self.writeStderr("\n");
        } else {
            self.writeStderr("error: code generation failed (");
            self.writeStderr(@errorName(err));
            self.writeStderr(")\n");
        }
        return false;
    };

    cg.printIR();
    return true;
}

/// Link an object file into a binary using the system linker.
pub fn link(obj_path: []const u8, bin_path: []const u8) !bool {
    return linkWithExtraAndLibs(obj_path, bin_path, &.{}, &.{});
}

/// Link with extra object files (e.g., fiber runtime for async programs).
pub fn linkWithExtra(obj_path: []const u8, bin_path: []const u8, extra_objs: []const []const u8) !bool {
    return linkWithExtraAndLibs(obj_path, bin_path, extra_objs, &.{});
}

fn linkWithExtraAndLibs(
    obj_path: []const u8,
    bin_path: []const u8,
    extra_objs: []const []const u8,
    link_libs: []const []const u8,
) !bool {
    return linkArtifactWithExtraAndLibs(obj_path, bin_path, extra_objs, link_libs, .executable);
}

/// Link an object file into a shared library.
pub fn linkShared(obj_path: []const u8, so_path: []const u8) !bool {
    return linkSharedWithExtraAndLibs(obj_path, so_path, &.{}, &.{});
}

fn linkSharedWithExtraAndLibs(
    obj_path: []const u8,
    so_path: []const u8,
    extra_objs: []const []const u8,
    link_libs: []const []const u8,
) !bool {
    return linkArtifactWithExtraAndLibs(obj_path, so_path, extra_objs, link_libs, .shared);
}

const LinkArtifactMode = enum {
    executable,
    shared,
};

fn linkArtifactWithExtraAndLibs(
    obj_path: []const u8,
    out_path: []const u8,
    extra_objs: []const []const u8,
    link_libs: []const []const u8,
    mode: LinkArtifactMode,
) !bool {
    var args_buf: [96][]const u8 = undefined;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    var argc: usize = 0;
    args_buf[argc] = "cc";
    argc += 1;
    if (mode == .shared) {
        switch (builtin.os.tag) {
            .macos, .ios, .tvos, .watchos, .visionos => {
                args_buf[argc] = "-dynamiclib";
                argc += 1;
            },
            else => {
                args_buf[argc] = "-shared";
                argc += 1;
            },
        }
    }
    args_buf[argc] = obj_path;
    argc += 1;
    for (extra_objs) |extra| {
        args_buf[argc] = extra;
        argc += 1;
    }
    args_buf[argc] = "-o";
    argc += 1;
    args_buf[argc] = out_path;
    argc += 1;
    for (link_libs) |lib| {
        if (argc >= args_buf.len) return false;
        args_buf[argc] = std.fmt.allocPrint(arena_alloc, "-l{s}", .{lib}) catch return false;
        argc += 1;
    }

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

fn sourceStem(source_path: []const u8) []const u8 {
    const base = std.fs.path.basename(source_path);
    if (std.mem.endsWith(u8, base, ".w")) {
        return base[0 .. base.len - 2];
    }
    return base;
}

fn shouldLinkLlvmBridge(source_path: []const u8) bool {
    if (std.mem.eql(u8, source_path, "src/main.w")) return true;
    if (std.mem.endsWith(u8, source_path, "/src/main.w")) return true;
    return std.mem.endsWith(u8, source_path, "\\src\\main.w");
}

/// Full pipeline: parse → codegen → link → binary.
pub fn buildBinary(self: *Driver, source_path: []const u8) !?[]const u8 {
    const dir = std.fs.path.dirname(source_path) orelse ".";
    return self.buildBinaryAt(source_path, dir, null);
}

/// Full pipeline: parse → codegen → link → binary.
/// The output binary/object are placed in `output_dir`.
/// If `output_stem` is null, the source filename stem is used.
pub fn buildBinaryAt(
    self: *Driver,
    source_path: []const u8,
    output_dir: []const u8,
    output_stem: ?[]const u8,
) !?[]const u8 {
    const module = try self.compileFile(source_path) orelse return null;
    const stem = output_stem orelse sourceStem(source_path);

    // Build null-terminated object path.
    var obj_buf: [4096]u8 = undefined;
    const obj_path = std.fmt.bufPrint(&obj_buf, "{s}/{s}.o", .{ output_dir, stem }) catch return null;
    obj_buf[obj_path.len] = 0;

    const bin_path = std.fmt.allocPrint(self.arena.allocator(), "{s}/{s}", .{ output_dir, stem }) catch return null;

    const uses_async = try self.compileToObject(&module, obj_buf[0..obj_path.len :0]);
    if (uses_async == null) return null;

    var link_libs: std.ArrayList([]const u8) = .empty;
    var link_libs_it = self.c_import_link_libs.iterator();
    while (link_libs_it.next()) |entry| {
        link_libs.append(self.arena.allocator(), self.pool.resolve(entry.key_ptr.*)) catch return null;
    }

    // Find runtime artifacts relative to the compiler binary.
    const exe_dir = self.findExeDir();

    var helpers_buf: [4096]u8 = undefined;
    const helpers_path = if (exe_dir) |ed|
        std.fmt.bufPrint(&helpers_buf, "{s}/runtime/helpers.o", .{ed}) catch null
    else
        null;

    const needs_llvm_bridge = shouldLinkLlvmBridge(source_path);
    var bridge_buf: [4096]u8 = undefined;
    const bridge_path = if (needs_llvm_bridge and exe_dir != null)
        std.fmt.bufPrint(&bridge_buf, "{s}/runtime/libwith_llvm_bridge.dylib", .{exe_dir.?}) catch null
    else
        null;
    if (needs_llvm_bridge and bridge_path == null) {
        self.writeStderr("error: failed to locate LLVM bridge runtime path\n");
        return null;
    }
    if (bridge_path) |bp| {
        std.fs.accessAbsolute(bp, .{}) catch {
            self.writeStderr("error: missing runtime/libwith_llvm_bridge.dylib\n");
            return null;
        };
    }

    var extras: [4][]const u8 = undefined;
    var extra_count: usize = 0;
    if (uses_async.?) {
        if (exe_dir) |ed| {
            var rt1_buf: [4096]u8 = undefined;
            var rt2_buf: [4096]u8 = undefined;
            const rt1 = std.fmt.bufPrint(&rt1_buf, "{s}/runtime/fiber.o", .{ed}) catch {
                self.writeStderr("error: failed to build fiber runtime path\n");
                return null;
            };
            const rt2 = std.fmt.bufPrint(&rt2_buf, "{s}/runtime/fiber_asm.o", .{ed}) catch {
                self.writeStderr("error: failed to build fiber asm runtime path\n");
                return null;
            };
            extras[extra_count] = rt1;
            extra_count += 1;
            extras[extra_count] = rt2;
            extra_count += 1;
        }
    }
    if (helpers_path) |hp| {
        extras[extra_count] = hp;
        extra_count += 1;
    }
    if (bridge_path) |bp| {
        extras[extra_count] = bp;
        extra_count += 1;
    }
    const link_ok = try linkWithExtraAndLibs(obj_path, bin_path, extras[0..extra_count], link_libs.items);

    if (!link_ok) {
        self.writeStderr("error: linking failed\n");
        return null;
    }

    // Clean up the .o file.
    if (std.fs.path.isAbsolute(obj_path)) {
        std.fs.deleteFileAbsolute(obj_path) catch {};
    } else {
        std.fs.cwd().deleteFile(obj_path) catch {};
    }

    return bin_path;
}

/// Full pipeline: parse → codegen → link → shared library.
/// output_stem should be a basename without extension (e.g., "cell_1").
pub fn buildSharedLibrary(self: *Driver, source_path: []const u8, output_stem: []const u8) !?[]const u8 {
    const module = try self.compileFile(source_path) orelse return null;
    const dir = std.fs.path.dirname(source_path) orelse ".";

    var obj_buf: [4096]u8 = undefined;
    const obj_path = std.fmt.bufPrint(&obj_buf, "{s}/{s}.o", .{ dir, output_stem }) catch return null;
    obj_buf[obj_path.len] = 0;

    const lib_ext = sharedLibraryExt();
    const so_path = std.fmt.allocPrint(self.arena.allocator(), "{s}/{s}.{s}", .{ dir, output_stem, lib_ext }) catch return null;

    const uses_async = try self.compileToObject(&module, obj_buf[0..obj_path.len :0]);
    if (uses_async == null) return null;

    var link_libs: std.ArrayList([]const u8) = .empty;
    var link_libs_it = self.c_import_link_libs.iterator();
    while (link_libs_it.next()) |entry| {
        link_libs.append(self.arena.allocator(), self.pool.resolve(entry.key_ptr.*)) catch return null;
    }

    const exe_dir = self.findExeDir();

    var helpers_buf: [4096]u8 = undefined;
    const helpers_path = if (exe_dir) |ed|
        std.fmt.bufPrint(&helpers_buf, "{s}/runtime/helpers.o", .{ed}) catch null
    else
        null;

    const needs_llvm_bridge = shouldLinkLlvmBridge(source_path);
    var bridge_buf: [4096]u8 = undefined;
    const bridge_path = if (needs_llvm_bridge and exe_dir != null)
        std.fmt.bufPrint(&bridge_buf, "{s}/runtime/libwith_llvm_bridge.dylib", .{exe_dir.?}) catch null
    else
        null;
    if (needs_llvm_bridge and bridge_path == null) {
        self.writeStderr("error: failed to locate LLVM bridge runtime path\n");
        return null;
    }
    if (bridge_path) |bp| {
        std.fs.accessAbsolute(bp, .{}) catch {
            self.writeStderr("error: missing runtime/libwith_llvm_bridge.dylib\n");
            return null;
        };
    }

    var extras: [4][]const u8 = undefined;
    var extra_count: usize = 0;
    if (uses_async.?) {
        if (exe_dir) |ed| {
            var rt1_buf: [4096]u8 = undefined;
            var rt2_buf: [4096]u8 = undefined;
            const rt1 = std.fmt.bufPrint(&rt1_buf, "{s}/runtime/fiber.o", .{ed}) catch {
                self.writeStderr("error: failed to build fiber runtime path\n");
                return null;
            };
            const rt2 = std.fmt.bufPrint(&rt2_buf, "{s}/runtime/fiber_asm.o", .{ed}) catch {
                self.writeStderr("error: failed to build fiber asm runtime path\n");
                return null;
            };
            extras[extra_count] = rt1;
            extra_count += 1;
            extras[extra_count] = rt2;
            extra_count += 1;
        }
    }
    if (helpers_path) |hp| {
        extras[extra_count] = hp;
        extra_count += 1;
    }
    if (bridge_path) |bp| {
        extras[extra_count] = bp;
        extra_count += 1;
    }
    const link_ok = try linkSharedWithExtraAndLibs(obj_path, so_path, extras[0..extra_count], link_libs.items);

    if (!link_ok) {
        self.writeStderr("error: shared library linking failed\n");
        return null;
    }

    std.fs.cwd().deleteFile(obj_path) catch {};
    return so_path;
}

fn sharedLibraryExt() []const u8 {
    return switch (builtin.os.tag) {
        .windows => "dll",
        .macos, .ios, .tvos, .watchos, .visionos => "dylib",
        else => "so",
    };
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
                self.diagnostics.emit(Diagnostic.err("failed to resolve import path", decl.span));
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
                    self.diagnostics.emit(Diagnostic.err("failed to parse imported module", decl.span));
                    try new_decls.append(arena_alloc, decl);
                    continue;
                };

                // Add all declarations from the imported file.
                try new_decls.appendSlice(arena_alloc, imported_decls);
            } else {
                self.diagnostics.emit(Diagnostic.err("import module not found", decl.span));
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
            for (decl.kind.c_import.link_libs) |lib| {
                try self.c_import_link_libs.put(self.allocator, lib, {});
            }
            const cache_key = try self.makeCImportCacheKey(
                decl.kind.c_import.header_code,
                decl.kind.c_import.link_libs,
            );
            var cache_key_owned = true;
            defer if (cache_key_owned) self.allocator.free(cache_key);

            if (self.c_import_cache.get(cache_key)) |cached| {
                if (self.trace_c_import_cache) self.writeStderr("c_import cache hit\n");
                try new_decls.appendSlice(arena_alloc, cached);
            } else {
                if (self.trace_c_import_cache) self.writeStderr("c_import cache miss\n");
                const synthetic = CImport.processCImport(
                    decl.kind.c_import.header_code,
                    arena_alloc,
                    &self.pool,
                ) catch |err| {
                    self.writeStderr("error: c_import processing failed for header snippet: ");
                    const preview_len = @min(decl.kind.c_import.header_code.len, 80);
                    self.writeStderr(decl.kind.c_import.header_code[0..preview_len]);
                    self.writeStderr("\n");
                    return err;
                };
                try self.c_import_cache.put(self.allocator, cache_key, synthetic);
                cache_key_owned = false;
                try new_decls.appendSlice(arena_alloc, synthetic);
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

// ── Helpers ─────────────────────────────────────────────────────

fn makeCImportCacheKey(
    self: *Driver,
    header_code: []const u8,
    link_libs: []const Ast.Symbol,
) ![]u8 {
    var key: std.ArrayList(u8) = .empty;
    errdefer key.deinit(self.allocator);

    try key.appendSlice(self.allocator, header_code);
    try key.appendSlice(self.allocator, "\n#links:");
    for (link_libs) |lib_sym| {
        try key.append(self.allocator, '|');
        try key.appendSlice(self.allocator, self.pool.resolve(lib_sym));
    }

    // Optional global cache-epoch override for explicit invalidation.
    const epoch = std.process.getEnvVarOwned(self.allocator, "WITH_CIMPORT_CACHE_EPOCH") catch "";
    defer if (epoch.len > 0) self.allocator.free(epoch);
    if (epoch.len > 0) {
        try key.appendSlice(self.allocator, "\n#epoch:");
        try key.appendSlice(self.allocator, epoch);
    }

    return key.toOwnedSlice(self.allocator);
}

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

/// Print any pending warnings to stderr.
pub fn printWarnings(self: *const Driver) void {
    const stderr = std.fs.File.stderr();
    for (self.pending_warnings.items) |msg| {
        stderr.writeAll(msg) catch {};
    }
}
