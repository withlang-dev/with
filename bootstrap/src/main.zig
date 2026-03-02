//! CLI entry point for the With compiler.
//!
//! Usage:
//!   with run [file.w]     Build + run package or source file
//!   with build [file.w]   Build package or source file
//!   with clean            Remove .with build/test artifacts
//!   with ast <file.w>     Parse and dump the AST (debug)
//!   with tokens <file.w>  Lex and dump tokens (debug)

const std = @import("std");
const c = @cImport(@cInclude("stdlib.h"));
const Driver = @import("Driver.zig");
const Source = @import("Source.zig");
const Lexer = @import("Lexer.zig");
const Token = @import("Token.zig");
const Parser = @import("Parser.zig");
const Diagnostic = @import("Diagnostic.zig");
const Migrate = @import("Migrate.zig");

const DumpArtifact = enum {
    tokens,
    ast,
    typed,
    llvm,
};

const CheckCommandOptions = struct {
    source_file: ?[]const u8 = null,
    dump_tokens: bool = false,
    dump_ast: bool = false,
    dump_typed: bool = false,
    dump_llvm_ir: bool = false,
    dump_out: ?[]const u8 = null,
    dump_dir: ?[]const u8 = null,
    deterministic: bool = false,

    fn dumpCount(self: CheckCommandOptions) u32 {
        var count: u32 = 0;
        if (self.dump_tokens) count += 1;
        if (self.dump_ast) count += 1;
        if (self.dump_typed) count += 1;
        if (self.dump_llvm_ir) count += 1;
        return count;
    }
};

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        printUsage();
        return;
    }

    const command = args[1];

    // Parse flags from remaining args.
    var opt_level: u8 = 0;
    var no_std = false;
    var alloc_mode = false;
    var release_mode = false;
    var deterministic_mode = false;
    for (args) |arg| {
        if (arg.len == 3 and arg[0] == '-' and arg[1] == 'O') {
            opt_level = arg[2] - '0';
            if (opt_level > 3) opt_level = 2;
        } else if (std.mem.eql(u8, arg, "--release")) {
            release_mode = true;
            if (opt_level < 2) opt_level = 2;
        } else if (std.mem.eql(u8, arg, "--no-std")) {
            no_std = true;
        } else if (std.mem.eql(u8, arg, "--alloc")) {
            alloc_mode = true;
        } else if (std.mem.eql(u8, arg, "--deterministic")) {
            deterministic_mode = true;
        }
    }

    // Find the first non-flag positional argument after the command.
    const source_file: ?[]const u8 = blk: {
        for (args[2..]) |arg| {
            if (!std.mem.startsWith(u8, arg, "-")) break :blk arg;
        }
        break :blk null;
    };

    if (std.mem.eql(u8, command, "build")) {
        const code = try runBuildCommand(
            args[2..],
            opt_level,
            no_std,
            alloc_mode,
            release_mode,
            std.heap.page_allocator,
        );
        if (code != 0) std.process.exit(code);
    } else if (std.mem.eql(u8, command, "run")) {
        const code = try runRunCommand(
            args[2..],
            opt_level,
            no_std,
            alloc_mode,
            release_mode,
            std.heap.page_allocator,
        );
        if (code != 0) std.process.exit(code);
    } else if (std.mem.eql(u8, command, "ir")) {
        const file = source_file orelse {
            stderrPrint("error: 'ir' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        };
        var driver = Driver.init(allocator);
        defer driver.deinit();
        driver.deterministic = deterministic_mode;

        const module = try driver.compileFile(file);
        if (module) |m| {
            const ok = try driver.emitIR(&m);
            if (!ok) std.process.exit(1);
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "ast")) {
        const file = source_file orelse {
            var buf: [4096]u8 = undefined;
            var w = std.fs.File.stderr().writer(&buf);
            w.interface.writeAll("error: 'ast' requires a source file argument\n") catch {};
            w.interface.flush() catch {};
            std.process.exit(1);
        };
        var driver = Driver.init(allocator);
        defer driver.deinit();
        driver.deterministic = deterministic_mode;

        const module = try driver.compileFile(file);
        if (module) |m| {
            try driver.dumpAst(&m);
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "check")) {
        const check_opts = parseCheckCommandOptions(args[2..], deterministic_mode) catch {
            printUsage();
            std.process.exit(1);
        };
        const file = check_opts.source_file orelse {
            stderrPrint("error: 'check' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        };
        var driver = Driver.init(allocator);
        defer driver.deinit();
        driver.no_std = no_std;
        driver.alloc = alloc_mode;
        driver.deterministic = check_opts.deterministic or check_opts.dumpCount() > 0;

        const module = try driver.compileFile(file);
        if (module) |m| {
            if (check_opts.dumpCount() == 0) {
                stderrPrint("ok\n");
                driver.printWarnings();
            } else {
                try emitCheckDumps(&driver, &m, file, check_opts, allocator);
            }
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "test")) {
        const code = try runTestCommand(args[2..], opt_level, no_std, alloc_mode, std.heap.page_allocator);
        if (code != 0) std.process.exit(code);
    } else if (std.mem.eql(u8, command, "clean")) {
        const code = try runCleanCommand(args[2..], std.heap.page_allocator);
        if (code != 0) std.process.exit(code);
    } else if (std.mem.eql(u8, command, "test-harness")) {
        var target: []const u8 = "bootstrap/test/cases";
        var update_snapshots = false;
        if (args.len >= 3) {
            for (args[2..]) |arg| {
                if (std.mem.eql(u8, arg, "--update")) {
                    update_snapshots = true;
                } else {
                    target = arg;
                }
            }
        }
        // The test runner may compile many modules in one process.
        // Use page allocator here to avoid noisy leak diagnostics from
        // long-lived compiler caches that are intentionally process-scoped.
        const ok = try runTests(target, update_snapshots, std.heap.page_allocator);
        if (!ok) std.process.exit(1);
    } else if (std.mem.eql(u8, command, "fmt")) {
        const file = source_file orelse {
            stderrPrint("error: 'fmt' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        };
        const source_text = std.fs.cwd().readFileAlloc(allocator, file, 2 * 1024 * 1024) catch {
            stderrPrint("error: failed to read source file for formatting\n");
            std.process.exit(1);
        };
        defer allocator.free(source_text);

        // Temporary comment-preserving strategy:
        // render-based formatting currently drops comments, so if comments are
        // present we keep source text verbatim until comment-aware CST fmt lands.
        if (std.mem.indexOf(u8, source_text, "//") != null) {
            var out_buf: [16384]u8 = undefined;
            var out = std.fs.File.stdout().writer(&out_buf);
            out.interface.writeAll(source_text) catch {};
            if (source_text.len == 0 or source_text[source_text.len - 1] != '\n') {
                out.interface.writeAll("\n") catch {};
            }
            out.interface.flush() catch {};
            return;
        }

        var driver = Driver.init(allocator);
        defer driver.deinit();

        const module = try driver.compileFile(file);
        if (module) |m| {
            // Render the AST back to formatted source.
            try driver.dumpAst(&m);
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "tokens")) {
        const file = source_file orelse {
            var buf: [4096]u8 = undefined;
            var w = std.fs.File.stderr().writer(&buf);
            w.interface.writeAll("error: 'tokens' requires a source file argument\n") catch {};
            w.interface.flush() catch {};
            std.process.exit(1);
        };
        try dumpTokens(file, allocator, deterministic_mode);
    } else if (std.mem.eql(u8, command, "help") or std.mem.eql(u8, command, "--help") or std.mem.eql(u8, command, "-h")) {
        printUsage();
    } else if (std.mem.eql(u8, command, "repl")) {
        try runRepl(allocator);
    } else if (std.mem.eql(u8, command, "doc")) {
        const file = source_file orelse {
            stderrPrint("error: 'doc' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        };
        try generateDoc(file, allocator);
    } else if (std.mem.eql(u8, command, "migrate")) {
        if (args.len < 4) {
            stderrPrint("error: 'migrate' requires <lang> and <path>\n");
            printUsage();
            std.process.exit(1);
        }

        var mode: Migrate.Mode = .write;
        for (args[4..]) |arg| {
            if (std.mem.eql(u8, arg, "--check")) {
                if (mode != .write) {
                    stderrPrint("error: choose only one of --check or --diff\n");
                    std.process.exit(1);
                }
                mode = .check;
            } else if (std.mem.eql(u8, arg, "--diff")) {
                if (mode != .write) {
                    stderrPrint("error: choose only one of --check or --diff\n");
                    std.process.exit(1);
                }
                mode = .diff;
            } else {
                var err_buf: [512]u8 = undefined;
                const msg = std.fmt.bufPrint(&err_buf, "error: unknown migrate flag '{s}'\n", .{arg}) catch "error: unknown migrate flag\n";
                stderrPrint(msg);
                std.process.exit(1);
            }
        }

        const code = Migrate.run(allocator, args[2], args[3], mode) catch |err| {
            switch (err) {
                error.UnsupportedLanguage => stderrPrint("error: unsupported migrate language (use rust|zig|swift)\n"),
                error.InvalidPath => stderrPrint("error: migrate path not found or unsupported\n"),
                error.NoInputFiles => stderrPrint("error: no source files found for selected language\n"),
                else => {
                    var err_buf: [512]u8 = undefined;
                    const msg = std.fmt.bufPrint(&err_buf, "error: migrate failed ({s})\n", .{@errorName(err)}) catch "error: migrate failed\n";
                    stderrPrint(msg);
                },
            }
            std.process.exit(1);
        };
        if (code != 0) std.process.exit(@intCast(code));
    } else if (std.mem.eql(u8, command, "lsp")) {
        const Lsp = @import("Lsp.zig");
        var lsp = Lsp.init(allocator);
        try lsp.run();
    } else if (std.mem.eql(u8, command, "version") or std.mem.eql(u8, command, "--version")) {
        var buf: [256]u8 = undefined;
        var w = std.fs.File.stdout().writer(&buf);
        w.interface.writeAll("with 0.0.1\n") catch {};
        w.interface.flush() catch {};
    } else {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stderr().writer(&buf);
        w.interface.print("error: unknown command '{s}'\n\n", .{command}) catch {};
        w.interface.flush() catch {};
        printUsage();
        std.process.exit(1);
    }
}

fn stderrPrint(msg: []const u8) void {
    var buf: [4096]u8 = undefined;
    var w = std.fs.File.stderr().writer(&buf);
    w.interface.writeAll(msg) catch {};
    w.interface.flush() catch {};
}

fn printUsage() void {
    var buf: [4096]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    w.interface.writeAll(
        \\Usage: with <command> [options]
        \\
        \\Commands:
        \\  build [file.w]    Build package (default entrypoint) or a source file
        \\  run [file.w]      Build + run package or a source file
        \\  check <file.w>    Parse/type-check; optional dump flags for oracle baselines
        \\                    --dump-tokens --dump-ast --dump-typed --dump-llvm-ir
        \\                    [--dump-out <path>] [--dump-dir <dir>] [--deterministic]
        \\  test [flags] [filter]
        \\                    Run package tests (annotations: @[test], @[before], @[after])
        \\                    Workspace root: add -p <member> to select one package
        \\  clean [--all]     Delete .with/ artifacts (workspace: all members)
        \\  test-harness [path] [--update]
        \\                    Run built-in snapshot harness (default: bootstrap/test/cases)
        \\  fmt <file.w>      Format a source file (to stdout)
        \\  repl              Interactive REPL
        \\  lsp               Start language server (LSP over stdio)
        \\  doc <file.w>      Generate documentation (markdown)
        \\  migrate <lang> <path> [--check|--diff]
        \\                    Translate rust/zig/swift sources to .w
        \\  ir <file.w>       Dump LLVM IR (debug)
        \\  ast <file.w>      Parse and dump the AST (debug)
        \\  tokens <file.w>   Lex and dump tokens (debug)
        \\  version           Print compiler version
        \\  help              Show this message
        \\
    ) catch {};
    w.interface.flush() catch {};
}

fn runRepl(allocator: std.mem.Allocator) !void {
    const stdin_file = std.fs.File.stdin();
    var out_buf: [8192]u8 = undefined;
    var out = std.fs.File.stdout().writer(&out_buf);
    const writer_iface = &out.interface;

    try writer_iface.writeAll("With REPL v0.0.1 - type expressions or :quit to exit\n");
    try out.interface.flush();

    var repl_state = ReplState.init();
    defer repl_state.deinit(allocator);

    var line_buf: [4096]u8 = undefined;

    while (true) {
        // Print prompt
        try writer_iface.writeAll("with> ");
        try out.interface.flush();

        // Read line using raw file read (byte by byte until newline)
        var pos: usize = 0;
        const got_line = while (pos < line_buf.len - 1) {
            const n = stdin_file.read(line_buf[pos .. pos + 1]) catch break false;
            if (n == 0) break false; // EOF
            if (line_buf[pos] == '\n') break true;
            pos += 1;
        } else false;
        if (!got_line and pos == 0) break; // EOF with no data
        const line_or_null = line_buf[0..pos];
        const line = std.mem.trimRight(u8, line_or_null, &.{ '\r', '\n' });

        if (line.len == 0) continue;
        if (std.mem.eql(u8, line, ":quit") or std.mem.eql(u8, line, ":q")) break;
        if (std.mem.eql(u8, line, ":clear")) {
            repl_state.clear(allocator);
            try writer_iface.writeAll("(cleared)\n");
            try out.interface.flush();
            continue;
        }
        if (std.mem.eql(u8, line, ":help")) {
            try writer_iface.writeAll(
                \\Commands:
                \\  :quit, :q    Exit the REPL
                \\  :clear       Clear accumulated state
                \\  :help        Show this help
                \\
                \\Enter declarations, mutation statements, or expressions.
                \\Declarations and mutation statements persist across lines.
                \\Expressions are automatically printed with println.
                \\
            );
            try out.interface.flush();
            continue;
        }

        // Determine whether this line should be persisted as REPL state.
        const trimmed = std.mem.trimLeft(u8, line, " \t");
        const is_binding = std.mem.startsWith(u8, trimmed, "let ") or std.mem.startsWith(u8, trimmed, "var ");
        const is_module_decl = std.mem.startsWith(u8, trimmed, "fn ") or
            std.mem.startsWith(u8, trimmed, "type ") or
            std.mem.startsWith(u8, trimmed, "use ") or
            std.mem.startsWith(u8, trimmed, "c_import(");
        const is_stateful_stmt = isLikelyStatefulStatement(trimmed);

        // For declarations and likely stateful statements, execute as a statement
        // first so side effects are persisted consistently.
        if (is_module_decl or is_binding or is_stateful_stmt) {
            const persist_kind: ReplPersistKind = if (is_module_decl) .module_decl else .body_stmt;
            if (try executeReplLine(allocator, &repl_state, line, .statement, persist_kind)) {
                const cell_id = repl_state.lastLoadedCellId() orelse 0;
                try repl_state.persistLine(allocator, line, persist_kind, cell_id);
                continue;
            }
            // Bindings are never treated as printable expressions.
            if (is_binding or is_module_decl) continue;
        }

        // Try expression mode (println wrapper) for query-like lines.
        if (try executeReplLine(allocator, &repl_state, line, .expression, .body_stmt)) {
            continue;
        }

        // Fallback to statement mode for non-printable expressions.
        if (try executeReplLine(allocator, &repl_state, line, .statement, .body_stmt)) {
            if (isLikelyStatefulStatement(trimmed)) {
                const cell_id = repl_state.lastLoadedCellId() orelse 0;
                try repl_state.persistLine(allocator, line, .body_stmt, cell_id);
            }
        }
    }

    try writer_iface.writeAll("\nGoodbye!\n");
    try out.interface.flush();
}

const ReplExecMode = enum {
    expression,
    statement,
};

const ReplPersistKind = enum {
    module_decl,
    body_stmt,
};

const ReplSymbolKind = enum {
    let_binding,
    var_binding,
    fn_decl,
    type_decl,
};

const ReplSymbol = struct {
    kind: ReplSymbolKind,
    persist_kind: ReplPersistKind,
    line_index: usize,
    cell_id: usize,
    address: ?usize = null,
};

const ReplLoadedCell = struct {
    id: usize,
    source_path: []const u8,
    dylib_path: []const u8,
    dylib: std.DynLib,
};

const ReplState = struct {
    module_lines: std.ArrayList([]const u8) = .empty,
    body_lines: std.ArrayList([]const u8) = .empty,
    loaded_cells: std.ArrayList(ReplLoadedCell) = .empty,
    symbols: std.StringHashMapUnmanaged(ReplSymbol) = .empty,
    next_cell_id: usize = 1,

    fn init() ReplState {
        return .{};
    }

    fn deinit(self: *ReplState, allocator: std.mem.Allocator) void {
        self.clear(allocator);
        self.module_lines.deinit(allocator);
        self.body_lines.deinit(allocator);
        self.loaded_cells.deinit(allocator);
        self.symbols.deinit(allocator);
    }

    fn clear(self: *ReplState, allocator: std.mem.Allocator) void {
        for (self.module_lines.items) |line| allocator.free(line);
        self.module_lines.clearRetainingCapacity();

        for (self.body_lines.items) |line| allocator.free(line);
        self.body_lines.clearRetainingCapacity();

        for (self.loaded_cells.items) |*cell| {
            cell.dylib.close();
            std.fs.deleteFileAbsolute(cell.source_path) catch {};
            std.fs.deleteFileAbsolute(cell.dylib_path) catch {};
            allocator.free(cell.source_path);
            allocator.free(cell.dylib_path);
        }
        self.loaded_cells.clearRetainingCapacity();

        var sym_it = self.symbols.iterator();
        while (sym_it.next()) |entry| {
            allocator.free(@constCast(entry.key_ptr.*));
        }
        self.symbols.clearRetainingCapacity();
        self.next_cell_id = 1;
    }

    fn persistLine(
        self: *ReplState,
        allocator: std.mem.Allocator,
        line: []const u8,
        persist_kind: ReplPersistKind,
        cell_id: usize,
    ) !void {
        const line_copy = try allocator.dupe(u8, line);
        const target = switch (persist_kind) {
            .module_decl => &self.module_lines,
            .body_stmt => &self.body_lines,
        };

        const maybe_symbol = parseReplSymbol(line);
        if (maybe_symbol) |sym| {
            if (self.symbols.getPtr(sym.name)) |entry| {
                if (entry.persist_kind == persist_kind and entry.line_index < target.items.len) {
                    allocator.free(target.items[entry.line_index]);
                    target.items[entry.line_index] = line_copy;
                    entry.kind = sym.kind;
                    entry.cell_id = cell_id;
                    entry.address = self.lookupSymbolAddress(sym.kind, sym.name);
                    return;
                }
            }

            const idx = target.items.len;
            try target.append(allocator, line_copy);

            if (self.symbols.getPtr(sym.name)) |entry| {
                entry.* = .{
                    .kind = sym.kind,
                    .persist_kind = persist_kind,
                    .line_index = idx,
                    .cell_id = cell_id,
                    .address = self.lookupSymbolAddress(sym.kind, sym.name),
                };
            } else {
                const key = try allocator.dupe(u8, sym.name);
                try self.symbols.put(allocator, key, .{
                    .kind = sym.kind,
                    .persist_kind = persist_kind,
                    .line_index = idx,
                    .cell_id = cell_id,
                    .address = self.lookupSymbolAddress(sym.kind, sym.name),
                });
            }
            return;
        }

        try target.append(allocator, line_copy);
    }

    fn lastLoadedCellId(self: *const ReplState) ?usize {
        if (self.loaded_cells.items.len == 0) return null;
        return self.loaded_cells.items[self.loaded_cells.items.len - 1].id;
    }

    fn lookupSymbolAddress(self: *ReplState, kind: ReplSymbolKind, symbol_name: []const u8) ?usize {
        if (self.loaded_cells.items.len == 0) return null;
        if (kind != .fn_decl) return null;
        const cell = &self.loaded_cells.items[self.loaded_cells.items.len - 1];

        var name_buf: [256]u8 = undefined;
        if (symbol_name.len + 1 > name_buf.len) return null;
        @memcpy(name_buf[0..symbol_name.len], symbol_name);
        name_buf[symbol_name.len] = 0;
        const name_z: [:0]const u8 = name_buf[0..symbol_name.len :0];

        const ptr = cell.dylib.lookup(*const anyopaque, name_z) orelse return null;
        return @intFromPtr(ptr);
    }
};

const ParsedReplSymbol = struct {
    kind: ReplSymbolKind,
    name: []const u8,
};

fn parseReplSymbol(line: []const u8) ?ParsedReplSymbol {
    const trimmed = std.mem.trimLeft(u8, line, " \t");
    if (std.mem.startsWith(u8, trimmed, "let ")) {
        var rest = std.mem.trimLeft(u8, trimmed["let ".len..], " \t");
        if (std.mem.startsWith(u8, rest, "mut ")) {
            rest = std.mem.trimLeft(u8, rest["mut ".len..], " \t");
        }
        if (identifierPrefix(rest)) |name| {
            return .{ .kind = .let_binding, .name = name };
        }
        return null;
    }
    if (std.mem.startsWith(u8, trimmed, "var ")) {
        const rest = std.mem.trimLeft(u8, trimmed["var ".len..], " \t");
        if (identifierPrefix(rest)) |name| {
            return .{ .kind = .var_binding, .name = name };
        }
        return null;
    }
    if (std.mem.startsWith(u8, trimmed, "fn ")) {
        const rest = std.mem.trimLeft(u8, trimmed["fn ".len..], " \t");
        if (identifierPrefix(rest)) |name| {
            return .{ .kind = .fn_decl, .name = name };
        }
        return null;
    }
    if (std.mem.startsWith(u8, trimmed, "type ")) {
        const rest = std.mem.trimLeft(u8, trimmed["type ".len..], " \t");
        if (identifierPrefix(rest)) |name| {
            return .{ .kind = .type_decl, .name = name };
        }
        return null;
    }
    return null;
}

fn identifierPrefix(s: []const u8) ?[]const u8 {
    if (s.len == 0) return null;
    if (!isIdentStart(s[0])) return null;
    var i: usize = 1;
    while (i < s.len and isIdentContinue(s[i])) : (i += 1) {}
    return s[0..i];
}

fn isIdentStart(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or ch == '_';
}

fn isIdentContinue(ch: u8) bool {
    return isIdentStart(ch) or (ch >= '0' and ch <= '9');
}

fn executeReplLine(
    allocator: std.mem.Allocator,
    repl_state: *ReplState,
    line: []const u8,
    mode: ReplExecMode,
    persist_kind: ReplPersistKind,
) !bool {
    const cell_id = repl_state.next_cell_id;
    repl_state.next_cell_id += 1;

    var src_path_buf: [4096]u8 = undefined;
    const src_path = std.fmt.bufPrint(&src_path_buf, "/tmp/_with_repl_cell_{d}.w", .{cell_id}) catch return false;

    var src: std.ArrayList(u8) = .empty;
    defer src.deinit(allocator);

    for (repl_state.module_lines.items) |prev| {
        try src.appendSlice(allocator, prev);
        try src.appendSlice(allocator, "\n");
    }
    if (mode == .statement and persist_kind == .module_decl) {
        try src.appendSlice(allocator, line);
        try src.appendSlice(allocator, "\n");
    }

    var entry_name_buf: [128]u8 = undefined;
    const entry_name = std.fmt.bufPrint(&entry_name_buf, "__repl_cell_{d}_entry", .{cell_id}) catch return false;
    try src.appendSlice(allocator, "fn ");
    try src.appendSlice(allocator, entry_name);
    try src.appendSlice(allocator, "() -> i32 =\n");

    for (repl_state.body_lines.items) |prev| {
        try src.appendSlice(allocator, "    ");
        try src.appendSlice(allocator, prev);
        try src.appendSlice(allocator, "\n");
    }

    if (mode == .expression) {
        try src.appendSlice(allocator, "    println(");
        try src.appendSlice(allocator, line);
        try src.appendSlice(allocator, ")\n    0\n");
    } else {
        if (persist_kind == .body_stmt) {
            try src.appendSlice(allocator, "    ");
            try src.appendSlice(allocator, line);
            try src.appendSlice(allocator, "\n");
        }
        try src.appendSlice(allocator, "    0\n");
    }

    {
        const f = std.fs.createFileAbsolute(src_path, .{}) catch return false;
        defer f.close();
        f.writeAll(src.items) catch return false;
    }

    var driver = Driver.init(allocator);
    defer driver.deinit();

    var stem_buf: [128]u8 = undefined;
    const stem = std.fmt.bufPrint(&stem_buf, "_with_repl_cell_{d}", .{cell_id}) catch return false;
    const dylib_path_tmp = try driver.buildSharedLibrary(src_path, stem);
    if (dylib_path_tmp == null) return false;

    const dylib_path = try allocator.dupe(u8, dylib_path_tmp.?);
    errdefer allocator.free(dylib_path);
    const src_path_copy = try allocator.dupe(u8, src_path);
    errdefer allocator.free(src_path_copy);

    var dylib = std.DynLib.open(dylib_path) catch return false;
    errdefer dylib.close();

    var entry_name_z_buf: [160]u8 = undefined;
    if (entry_name.len + 1 > entry_name_z_buf.len) return false;
    @memcpy(entry_name_z_buf[0..entry_name.len], entry_name);
    entry_name_z_buf[entry_name.len] = 0;
    const entry_name_z: [:0]const u8 = entry_name_z_buf[0..entry_name.len :0];

    const EntryFn = *const fn () callconv(.c) i32;
    const entry_fn = dylib.lookup(EntryFn, entry_name_z) orelse return false;
    _ = entry_fn();

    try repl_state.loaded_cells.append(allocator, .{
        .id = cell_id,
        .source_path = src_path_copy,
        .dylib_path = dylib_path,
        .dylib = dylib,
    });
    return true;
}

fn isLikelyStatefulStatement(line: []const u8) bool {
    if (hasAssignmentOperator(line)) return true;

    const mutating_patterns = [_][]const u8{
        ".push(",
        ".pop(",
        ".insert(",
        ".remove(",
        ".clear(",
        ".append(",
        ".extend(",
        ".set(",
        ".swap(",
        ".truncate(",
        ".retain(",
        ".sort(",
        ".reverse(",
    };
    for (mutating_patterns) |pat| {
        if (std.mem.indexOf(u8, line, pat) != null) return true;
    }
    return false;
}

fn hasAssignmentOperator(line: []const u8) bool {
    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] != '=') continue;

        const prev: u8 = if (i == 0) 0 else line[i - 1];
        const next: u8 = if (i + 1 < line.len) line[i + 1] else 0;

        // Exclude comparison/arrow tokens.
        if (prev == '=' or prev == '!' or prev == '<' or prev == '>') continue;
        if (next == '=' or next == '>') continue;

        return true;
    }
    return false;
}

const Ast = @import("Ast.zig");
const render = @import("render.zig");
const InternPool = @import("InternPool.zig");

fn generateDoc(path: []const u8, allocator: std.mem.Allocator) !void {
    var driver = Driver.init(allocator);
    defer driver.deinit();

    // Read source for doc comment extraction
    const source_text = std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024) catch "";
    defer if (source_text.len > 0) allocator.free(source_text);

    const module = try driver.compileFile(path) orelse {
        stderrPrint("error: failed to parse file\n");
        std.process.exit(1);
    };

    const pool = &driver.pool;

    var out_buf: [16384]u8 = undefined;
    var out = std.fs.File.stdout().writer(&out_buf);
    const w = &out.interface;

    // Header
    const basename = std.fs.path.basename(path);
    try w.print("# {s}\n\n", .{basename});

    // Index with cross-links.
    try w.writeAll("## Index\n\n");
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |f| {
                const name = pool.resolve(f.name);
                if (std.mem.eql(u8, name, "main")) continue;
                try w.print("- [fn `{s}`](#fn-{s})\n", .{ name, name });
            },
            .type_decl => |td| {
                const name = pool.resolve(td.name);
                try w.print("- [type `{s}`](#type-{s})\n", .{ name, name });
            },
            .trait_decl => |td| {
                const name = pool.resolve(td.name);
                try w.print("- [trait `{s}`](#trait-{s})\n", .{ name, name });
            },
            else => {},
        }
    }
    try w.writeAll("\n");

    // Walk declarations
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |f| {
                // Skip private functions and main
                const name = pool.resolve(f.name);
                if (std.mem.eql(u8, name, "main")) continue;

                // Extract doc comment
                const doc = extractDocComment(source_text, decl.span.start);
                try w.print("<a id=\"fn-{s}\"></a>\n", .{name});
                try w.print("### fn `{s}`\n\n", .{name});
                try emitDocCommentAndExamples(w, doc);

                // Function signature
                try w.writeAll("```\n");
                if (f.is_pub == .public) try w.writeAll("pub ");
                if (f.is_async) try w.writeAll("async ");
                if (f.is_gen) try w.writeAll("gen ");
                try w.print("fn {s}", .{name});
                if (f.type_params.len > 0) {
                    try w.writeAll("[");
                    for (f.type_params, 0..) |tp, tpi| {
                        if (tpi > 0) try w.writeAll(", ");
                        try w.print("{s}", .{pool.resolve(tp.name)});
                        if (tp.bounds.len > 0) {
                            try w.writeAll(": ");
                            for (tp.bounds, 0..) |b, bi| {
                                if (bi > 0) try w.writeAll(" + ");
                                try w.print("{s}", .{pool.resolve(b)});
                            }
                        }
                    }
                    try w.writeAll("]");
                }
                try w.writeAll("(");
                for (f.params, 0..) |p, i| {
                    if (i > 0) try w.writeAll(", ");
                    if (p.is_mut) try w.writeAll("mut ");
                    try w.print("{s}", .{pool.resolve(p.name)});
                    if (p.type_expr) |te| {
                        try w.writeAll(": ");
                        try render.renderTypeExpr(te, pool, w);
                    }
                }
                try w.writeAll(")");
                if (f.return_type) |rt| {
                    try w.writeAll(" -> ");
                    try render.renderTypeExpr(rt, pool, w);
                }
                try w.writeAll("\n```\n\n");
            },
            .type_decl => |td| {
                const name = pool.resolve(td.name);
                const doc = extractDocComment(source_text, decl.span.start);
                try w.print("<a id=\"type-{s}\"></a>\n", .{name});
                try emitDocCommentAndExamples(w, doc);

                switch (td.kind) {
                    .struct_def => |fields| {
                        try w.print("### struct `{s}`\n\n", .{name});
                        if (fields.len > 0) {
                            try w.writeAll("| Field | Type |\n|-------|------|\n");
                            for (fields) |fld| {
                                try w.print("| `{s}` | `", .{pool.resolve(fld.name)});
                                try render.renderTypeExpr(fld.type_expr, pool, w);
                                try w.writeAll("` |\n");
                            }
                            try w.writeAll("\n");
                        }
                    },
                    .enum_def => |variants| {
                        try w.print("### enum `{s}`\n\n", .{name});
                        for (variants) |v| {
                            try w.print("- `{s}`", .{pool.resolve(v.name)});
                            if (v.payload) |payload| {
                                try w.writeAll("(");
                                for (payload, 0..) |pt, pi| {
                                    if (pi > 0) try w.writeAll(", ");
                                    try render.renderTypeExpr(pt, pool, w);
                                }
                                try w.writeAll(")");
                            }
                            try w.writeAll("\n");
                        }
                        try w.writeAll("\n");
                    },
                    .alias => |al| {
                        try w.print("### type `{s}` = `", .{name});
                        try render.renderTypeExpr(al, pool, w);
                        try w.writeAll("`\n\n");
                    },
                    .distinct => |dt| {
                        try w.print("### type `{s}` = distinct `", .{name});
                        try render.renderTypeExpr(dt, pool, w);
                        try w.writeAll("`\n\n");
                    },
                }
            },
            .trait_decl => |td| {
                const name = pool.resolve(td.name);
                const doc = extractDocComment(source_text, decl.span.start);
                try w.print("<a id=\"trait-{s}\"></a>\n", .{name});
                try emitDocCommentAndExamples(w, doc);
                try w.print("### trait `{s}`\n\n", .{name});
                for (td.associated_types) |at| {
                    try w.print("- `type {s}`\n", .{pool.resolve(at.name)});
                }
                for (td.methods) |m| {
                    try w.print("- `fn {s}(", .{pool.resolve(m.name)});
                    for (m.params, 0..) |p, i| {
                        if (i > 0) try w.writeAll(", ");
                        try w.print("{s}", .{pool.resolve(p.name)});
                        if (p.type_expr) |te| {
                            try w.writeAll(": ");
                            try render.renderTypeExpr(te, pool, w);
                        }
                    }
                    try w.writeAll(")");
                    if (m.return_type) |rt| {
                        try w.writeAll(" -> ");
                        try render.renderTypeExpr(rt, pool, w);
                    }
                    try w.writeAll("`\n");
                }
                try w.writeAll("\n");
            },
            else => {},
        }
    }

    try out.interface.flush();
}

/// Extract doc comments (// lines) immediately preceding a declaration.
fn extractDocComment(source: []const u8, decl_start: usize) []const u8 {
    if (decl_start == 0 or source.len == 0) return "";
    // Walk backwards from decl_start to find consecutive // comment lines
    var pos = decl_start;
    // Skip backwards past whitespace before the declaration
    while (pos > 0 and (source[pos - 1] == ' ' or source[pos - 1] == '\t')) pos -= 1;
    if (pos > 0 and source[pos - 1] == '\n') pos -= 1;

    // Now find the start of comment block
    const comment_end = pos;
    while (pos > 0) {
        // Find start of this line
        var line_start = pos;
        while (line_start > 0 and source[line_start - 1] != '\n') line_start -= 1;
        // Check if this line is a // comment
        const line = std.mem.trimLeft(u8, source[line_start .. pos + 1], " \t");
        if (line.len >= 2 and line[0] == '/' and line[1] == '/') {
            // Continue searching
            if (line_start == 0) return source[0 .. comment_end + 1];
            pos = line_start - 1;
        } else {
            // Not a comment — return what we found
            if (line_start >= comment_end) return "";
            return source[line_start + 1 .. comment_end + 1];
        }
    }
    return "";
}

fn emitDocCommentAndExamples(w: anytype, doc: []const u8) !void {
    if (doc.len == 0) return;

    var found_text = false;
    var example_line: ?[]const u8 = null;

    var it = std.mem.splitScalar(u8, doc, '\n');
    while (it.next()) |raw_line| {
        var line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len >= 2 and line[0] == '/' and line[1] == '/') {
            line = std.mem.trimLeft(u8, line[2..], " \t");
        }
        if (line.len == 0) continue;

        if (std.mem.startsWith(u8, line, "example:")) {
            if (example_line == null) {
                example_line = std.mem.trimLeft(u8, line["example:".len..], " \t");
            }
            continue;
        }

        try w.print("{s}\n", .{line});
        found_text = true;
    }

    if (found_text) try w.writeAll("\n");

    if (example_line) |ex| {
        try w.writeAll("**Example**\n\n```with\n");
        try w.print("{s}\n", .{ex});
        try w.writeAll("```\n\n");
    }
}

const PackageTestOptions = struct {
    verbose: bool = false,
    run_pattern: ?[]const u8 = null,
    positional_filter: ?[]const u8 = null,
    count: usize = 1,
    timeout_ns: u64 = 10 * 60 * std.time.ns_per_s,
    short: bool = false,
    failfast: bool = false,
    shuffle: bool = false,
    shuffle_seed: ?u64 = null,
    list: bool = false,
};

const PackageTest = struct {
    name: []const u8,
    file_path: []const u8,
    module_path: []const u8,
    line: u32,
    returns_result: bool,
    before_name: ?[]const u8 = null,
    after_name: ?[]const u8 = null,
};

const PackageTestDiscovery = struct {
    tests: std.ArrayList(PackageTest) = .empty,
    module_paths: std.ArrayList([]const u8) = .empty,

    fn deinit(self: *PackageTestDiscovery, allocator: std.mem.Allocator) void {
        for (self.tests.items) |test_case| {
            allocator.free(test_case.name);
            allocator.free(test_case.file_path);
            allocator.free(test_case.module_path);
            if (test_case.before_name) |name| allocator.free(name);
            if (test_case.after_name) |name| allocator.free(name);
        }
        self.tests.deinit(allocator);
        for (self.module_paths.items) |module_path| allocator.free(module_path);
        self.module_paths.deinit(allocator);
    }
};

const PackageTestRunStatus = enum {
    passed,
    failed,
    skipped,
};

const PackageTestRunResult = struct {
    status: PackageTestRunStatus,
    term: std.process.Child.Term,
    stdout: []u8,
    stderr: []u8,
};

const ParsePackageTestOptionsError = error{
    InvalidArgs,
};

const ParseDurationError = error{
    InvalidDuration,
    Overflow,
};

const with_test_skip_marker = "__WITH_TEST_SKIP__";

const ParseCommandOptionsError = error{
    InvalidArgs,
    OutOfMemory,
};

const ProjectContextKind = enum {
    package,
    workspace,
    none,
};

const ProjectContext = struct {
    kind: ProjectContextKind,
    root: []const u8,
};

const WorkspaceMember = struct {
    name: []const u8,
    root_path: []const u8,
};

const WorkspaceDiscovery = struct {
    members: std.ArrayList(WorkspaceMember) = .empty,

    fn deinit(self: *WorkspaceDiscovery, allocator: std.mem.Allocator) void {
        for (self.members.items) |member| {
            allocator.free(member.name);
            allocator.free(member.root_path);
        }
        self.members.deinit(allocator);
    }
};

const ArtifactLayout = struct {
    with_dir: []const u8,
    build_dir: []const u8,
    test_dir: []const u8,

    fn deinit(self: *const ArtifactLayout, allocator: std.mem.Allocator) void {
        allocator.free(self.with_dir);
        allocator.free(self.build_dir);
        allocator.free(self.test_dir);
    }
};

const PackageBuildInputs = struct {
    source_path: []const u8,
    output_stem: []const u8,

    fn deinit(self: *const PackageBuildInputs, allocator: std.mem.Allocator) void {
        allocator.free(self.source_path);
        allocator.free(self.output_stem);
    }
};

const BuildCommandOptions = struct {
    source_file: ?[]const u8 = null,
    package_filter: ?[]const u8 = null,
};

const RunCommandOptions = struct {
    source_file: ?[]const u8 = null,
    package_filter: ?[]const u8 = null,
    program_args: []const []const u8 = &.{},
};

const TestCommandTopOptions = struct {
    package_filter: ?[]const u8 = null,
    forwarded_args: [][]const u8,
};

const CleanCommandOptions = struct {
    package_filter: ?[]const u8 = null,
    all: bool = false,
};

const DefaultEntryError = error{
    MissingEntrypoint,
    AmbiguousEntrypoint,
};

fn commandOptionError(msg: []const u8) ParseCommandOptionsError {
    stderrPrint(msg);
    return error.InvalidArgs;
}

fn isGlobalDriverFlag(arg: []const u8) bool {
    if (arg.len == 3 and arg[0] == '-' and arg[1] == 'O') return true;
    if (std.mem.eql(u8, arg, "--no-std")) return true;
    if (std.mem.eql(u8, arg, "--alloc")) return true;
    if (std.mem.eql(u8, arg, "--release")) return true;
    if (std.mem.eql(u8, arg, "--deterministic")) return true;
    return false;
}

fn sourceStem(path: []const u8) []const u8 {
    const base = std.fs.path.basename(path);
    if (std.mem.endsWith(u8, base, ".w")) return base[0 .. base.len - 2];
    return base;
}

fn directoryHasWithToml(dir_path: []const u8, allocator: std.mem.Allocator) bool {
    const with_toml = std.fmt.allocPrint(allocator, "{s}/with.toml", .{dir_path}) catch return false;
    defer allocator.free(with_toml);
    return pathExistsAbsolute(with_toml);
}

fn directoryHasWorkspaceToml(dir_path: []const u8, allocator: std.mem.Allocator) bool {
    const workspace_toml = std.fmt.allocPrint(allocator, "{s}/with-workspace.toml", .{dir_path}) catch return false;
    defer allocator.free(workspace_toml);
    return pathExistsAbsolute(workspace_toml);
}

fn detectProjectContext(allocator: std.mem.Allocator) !ProjectContext {
    const cwd = try std.process.getCwdAlloc(allocator);
    const fallback = try allocator.dupe(u8, cwd);
    var current = cwd;

    while (true) {
        const has_package = directoryHasWithToml(current, allocator);
        const has_workspace = directoryHasWorkspaceToml(current, allocator);
        if (has_package and has_workspace) {
            stderrPrint("error: directory cannot contain both with.toml and with-workspace.toml\n");
            allocator.free(fallback);
            allocator.free(current);
            return error.InvalidProjectLayout;
        }
        if (has_package) {
            allocator.free(fallback);
            return .{ .kind = .package, .root = current };
        }
        if (has_workspace) {
            allocator.free(fallback);
            return .{ .kind = .workspace, .root = current };
        }

        const parent = std.fs.path.dirname(current) orelse break;
        if (std.mem.eql(u8, parent, current)) break;

        const next = try allocator.dupe(u8, parent);
        allocator.free(current);
        current = next;
    }

    allocator.free(current);
    return .{ .kind = .none, .root = fallback };
}

fn ensureDirAbsolute(path: []const u8) !void {
    std.fs.makeDirAbsolute(path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
}

fn ensureArtifactLayout(package_root: []const u8, release_mode: bool, allocator: std.mem.Allocator) !ArtifactLayout {
    const with_dir = try std.fmt.allocPrint(allocator, "{s}/.with", .{package_root});
    errdefer allocator.free(with_dir);
    try ensureDirAbsolute(with_dir);

    const build_parent = try std.fmt.allocPrint(allocator, "{s}/build", .{with_dir});
    errdefer allocator.free(build_parent);
    try ensureDirAbsolute(build_parent);

    const build_dir = if (release_mode)
        try std.fmt.allocPrint(allocator, "{s}/release", .{build_parent})
    else
        try allocator.dupe(u8, build_parent);
    errdefer allocator.free(build_dir);
    if (release_mode) try ensureDirAbsolute(build_dir);

    const test_dir = try std.fmt.allocPrint(allocator, "{s}/test", .{with_dir});
    errdefer allocator.free(test_dir);
    try ensureDirAbsolute(test_dir);

    allocator.free(build_parent);
    return .{
        .with_dir = with_dir,
        .build_dir = build_dir,
        .test_dir = test_dir,
    };
}

fn parsePackageNameFromWithToml(package_root: []const u8, allocator: std.mem.Allocator) !?[]const u8 {
    const with_toml = try std.fmt.allocPrint(allocator, "{s}/with.toml", .{package_root});
    defer allocator.free(with_toml);
    if (!pathExistsAbsolute(with_toml)) return null;

    var file = std.fs.openFileAbsolute(with_toml, .{}) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
    defer file.close();

    const text = try file.readToEndAlloc(allocator, 512 * 1024);
    defer allocator.free(text);

    var in_package = false;
    var line_it = std.mem.splitScalar(u8, text, '\n');
    while (line_it.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t\r");
        if (line.len == 0) continue;
        if (line[0] == '#') continue;
        if (line[0] == '[' and line[line.len - 1] == ']') {
            in_package = std.mem.eql(u8, line, "[package]");
            continue;
        }
        if (!in_package) continue;
        if (!std.mem.startsWith(u8, line, "name")) continue;

        var rest = std.mem.trimLeft(u8, line["name".len..], " \t");
        if (rest.len == 0 or rest[0] != '=') continue;
        rest = std.mem.trimLeft(u8, rest[1..], " \t");
        if (rest.len < 2 or rest[0] != '"') continue;
        var end_idx: usize = 1;
        while (end_idx < rest.len and rest[end_idx] != '"') : (end_idx += 1) {}
        if (end_idx >= rest.len) continue;
        return try allocator.dupe(u8, rest[1..end_idx]);
    }

    return null;
}

fn findDefaultPackageEntrypoint(package_root: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const src_main = try std.fmt.allocPrint(allocator, "{s}/src/main.w", .{package_root});
    if (pathExistsAbsolute(src_main)) return src_main;
    allocator.free(src_main);

    const root_main = try std.fmt.allocPrint(allocator, "{s}/main.w", .{package_root});
    if (pathExistsAbsolute(root_main)) return root_main;
    allocator.free(root_main);

    var dir = try std.fs.openDirAbsolute(package_root, .{ .iterate = true });
    defer dir.close();
    var it = dir.iterate();

    var candidate: ?[]const u8 = null;
    var count: usize = 0;
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".w")) continue;
        if (std.mem.startsWith(u8, entry.name, ".")) continue;
        count += 1;
        if (count == 1) {
            candidate = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ package_root, entry.name });
        } else if (candidate) |path| {
            allocator.free(path);
            candidate = null;
        }
    }

    if (count == 1 and candidate != null) return candidate.?;
    if (count > 1) return error.AmbiguousEntrypoint;
    return error.MissingEntrypoint;
}

fn resolvePackageBuildInputs(
    package_root: []const u8,
    explicit_source: ?[]const u8,
    allocator: std.mem.Allocator,
) !PackageBuildInputs {
    if (explicit_source) |src| {
        return .{
            .source_path = try allocator.dupe(u8, src),
            .output_stem = try allocator.dupe(u8, sourceStem(src)),
        };
    }

    const source_path = try findDefaultPackageEntrypoint(package_root, allocator);
    errdefer allocator.free(source_path);

    const package_name = try parsePackageNameFromWithToml(package_root, allocator);
    if (package_name) |name| {
        return .{
            .source_path = source_path,
            .output_stem = name,
        };
    }

    return .{
        .source_path = source_path,
        .output_stem = try allocator.dupe(u8, sourceStem(source_path)),
    };
}

fn parseWorkspaceMembersFromToml(text: []const u8, allocator: std.mem.Allocator) ![][]const u8 {
    var members_buf: std.ArrayList(u8) = .empty;
    defer members_buf.deinit(allocator);

    var in_workspace = false;
    var capturing = false;
    var line_it = std.mem.splitScalar(u8, text, '\n');
    while (line_it.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \t\r");
        if (line.len == 0) continue;
        if (line[0] == '#') continue;
        if (line[0] == '[' and line[line.len - 1] == ']') {
            in_workspace = std.mem.eql(u8, line, "[workspace]");
            continue;
        }
        if (!in_workspace) continue;
        if (!capturing and std.mem.startsWith(u8, line, "members")) {
            capturing = true;
        }
        if (!capturing) continue;

        try members_buf.appendSlice(allocator, line);
        try members_buf.append(allocator, '\n');
        if (std.mem.indexOfScalar(u8, line, ']') != null) break;
    }

    if (members_buf.items.len == 0) return error.InvalidWorkspaceConfig;

    var members: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (members.items) |item| allocator.free(item);
        members.deinit(allocator);
    }

    var i: usize = 0;
    while (i < members_buf.items.len) : (i += 1) {
        if (members_buf.items[i] != '"') continue;
        i += 1;
        const start = i;
        while (i < members_buf.items.len and members_buf.items[i] != '"') : (i += 1) {}
        if (i >= members_buf.items.len) return error.InvalidWorkspaceConfig;
        const value = std.mem.trim(u8, members_buf.items[start..i], " \t\r\n");
        if (value.len == 0) continue;
        try members.append(allocator, try allocator.dupe(u8, value));
    }

    if (members.items.len == 0) return error.InvalidWorkspaceConfig;
    return try members.toOwnedSlice(allocator);
}

fn workspaceContainsRoot(members: []const WorkspaceMember, root_path: []const u8) bool {
    for (members) |member| {
        if (std.mem.eql(u8, member.root_path, root_path)) return true;
    }
    return false;
}

fn sortWorkspaceMembers(members: []WorkspaceMember) void {
    var i: usize = 1;
    while (i < members.len) : (i += 1) {
        var j = i;
        while (j > 0 and std.mem.order(u8, members[j].name, members[j - 1].name) == .lt) : (j -= 1) {
            const tmp = members[j];
            members[j] = members[j - 1];
            members[j - 1] = tmp;
        }
    }
}

fn discoverWorkspaceMembers(workspace_root: []const u8, allocator: std.mem.Allocator) !WorkspaceDiscovery {
    const workspace_toml = try std.fmt.allocPrint(allocator, "{s}/with-workspace.toml", .{workspace_root});
    defer allocator.free(workspace_toml);

    var file = try std.fs.openFileAbsolute(workspace_toml, .{});
    defer file.close();
    const text = try file.readToEndAlloc(allocator, 512 * 1024);
    defer allocator.free(text);

    const configured_members = try parseWorkspaceMembersFromToml(text, allocator);
    defer {
        for (configured_members) |member| allocator.free(member);
        allocator.free(configured_members);
    }

    var out: WorkspaceDiscovery = .{};
    errdefer out.deinit(allocator);

    var all_members = false;
    for (configured_members) |member| {
        if (std.mem.eql(u8, member, "*")) {
            all_members = true;
            break;
        }
    }

    if (all_members) {
        var dir = try std.fs.openDirAbsolute(workspace_root, .{ .iterate = true });
        defer dir.close();
        var it = dir.iterate();
        while (try it.next()) |entry| {
            if (entry.kind != .directory) continue;
            if (std.mem.startsWith(u8, entry.name, ".")) continue;
            const member_root = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ workspace_root, entry.name });
            errdefer allocator.free(member_root);
            if (!directoryHasWithToml(member_root, allocator)) {
                allocator.free(member_root);
                continue;
            }
            if (workspaceContainsRoot(out.members.items, member_root)) {
                allocator.free(member_root);
                continue;
            }
            const member_name = try allocator.dupe(u8, entry.name);
            errdefer allocator.free(member_name);
            try out.members.append(allocator, .{
                .name = member_name,
                .root_path = member_root,
            });
        }
    } else {
        for (configured_members) |member_rel| {
            const member_root = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ workspace_root, member_rel });
            errdefer allocator.free(member_root);
            if (!directoryHasWithToml(member_root, allocator)) {
                var err_buf: [512]u8 = undefined;
                const msg = std.fmt.bufPrint(
                    &err_buf,
                    "error: workspace member '{s}' does not contain with.toml\n",
                    .{member_rel},
                ) catch "error: invalid workspace member\n";
                stderrPrint(msg);
                return error.InvalidWorkspaceConfig;
            }
            if (workspaceContainsRoot(out.members.items, member_root)) {
                allocator.free(member_root);
                continue;
            }
            const member_name = try allocator.dupe(u8, std.fs.path.basename(member_rel));
            errdefer allocator.free(member_name);
            try out.members.append(allocator, .{
                .name = member_name,
                .root_path = member_root,
            });
        }
    }

    sortWorkspaceMembers(out.members.items);
    return out;
}

fn workspaceMemberSelected(member: WorkspaceMember, filter: ?[]const u8) bool {
    if (filter == null) return true;
    return std.mem.eql(u8, member.name, filter.?);
}

fn parseCheckCommandOptions(raw_args: []const []const u8, default_deterministic: bool) ParseCommandOptionsError!CheckCommandOptions {
    var options: CheckCommandOptions = .{ .deterministic = default_deterministic };

    var idx: usize = 0;
    while (idx < raw_args.len) : (idx += 1) {
        const arg = raw_args[idx];
        if (isGlobalDriverFlag(arg)) continue;

        if (std.mem.eql(u8, arg, "--dump-tokens")) {
            options.dump_tokens = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "--dump-ast")) {
            options.dump_ast = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "--dump-typed")) {
            options.dump_typed = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "--dump-llvm-ir")) {
            options.dump_llvm_ir = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "--dump-all")) {
            options.dump_tokens = true;
            options.dump_ast = true;
            options.dump_typed = true;
            options.dump_llvm_ir = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "--dump-out")) {
            if (idx + 1 >= raw_args.len) return commandOptionError("error: --dump-out requires a path\n");
            options.dump_out = raw_args[idx + 1];
            idx += 1;
            continue;
        }
        if (std.mem.startsWith(u8, arg, "--dump-out=")) {
            options.dump_out = arg["--dump-out=".len..];
            continue;
        }
        if (std.mem.eql(u8, arg, "--dump-dir")) {
            if (idx + 1 >= raw_args.len) return commandOptionError("error: --dump-dir requires a path\n");
            options.dump_dir = raw_args[idx + 1];
            idx += 1;
            continue;
        }
        if (std.mem.startsWith(u8, arg, "--dump-dir=")) {
            options.dump_dir = arg["--dump-dir=".len..];
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-")) {
            var err_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&err_buf, "error: unknown check flag '{s}'\n", .{arg}) catch "error: unknown check flag\n";
            return commandOptionError(msg);
        }
        if (options.source_file != null) {
            return commandOptionError("error: check accepts at most one source file\n");
        }
        options.source_file = arg;
    }

    if (options.dump_out != null and options.dump_dir != null) {
        return commandOptionError("error: use either --dump-out or --dump-dir (not both)\n");
    }
    if (options.dump_out != null and options.dumpCount() != 1) {
        return commandOptionError("error: --dump-out requires exactly one dump flag\n");
    }
    if (options.dumpCount() > 0 and !options.deterministic) {
        options.deterministic = true;
    }

    return options;
}

fn parseBuildCommandOptions(raw_args: []const []const u8) ParseCommandOptionsError!BuildCommandOptions {
    var options: BuildCommandOptions = .{};

    var idx: usize = 0;
    while (idx < raw_args.len) : (idx += 1) {
        const arg = raw_args[idx];
        if (isGlobalDriverFlag(arg)) continue;
        if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--package")) {
            if (idx + 1 >= raw_args.len) return commandOptionError("error: -p/--package requires a value\n");
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = raw_args[idx + 1];
            idx += 1;
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-p=")) {
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = arg["-p=".len..];
            continue;
        }
        if (std.mem.startsWith(u8, arg, "--package=")) {
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = arg["--package=".len..];
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-")) {
            var err_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&err_buf, "error: unknown build flag '{s}'\n", .{arg}) catch "error: unknown build flag\n";
            return commandOptionError(msg);
        }
        if (options.source_file != null) {
            return commandOptionError("error: build accepts at most one source file\n");
        }
        options.source_file = arg;
    }

    return options;
}

fn parseRunCommandOptions(raw_args: []const []const u8) ParseCommandOptionsError!RunCommandOptions {
    var options: RunCommandOptions = .{};

    var idx: usize = 0;
    while (idx < raw_args.len) : (idx += 1) {
        const arg = raw_args[idx];
        if (std.mem.eql(u8, arg, "--")) {
            options.program_args = raw_args[idx + 1 ..];
            break;
        }
        if (isGlobalDriverFlag(arg)) continue;
        if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--package")) {
            if (idx + 1 >= raw_args.len) return commandOptionError("error: -p/--package requires a value\n");
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = raw_args[idx + 1];
            idx += 1;
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-p=")) {
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = arg["-p=".len..];
            continue;
        }
        if (std.mem.startsWith(u8, arg, "--package=")) {
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = arg["--package=".len..];
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-")) {
            var err_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&err_buf, "error: unknown run flag '{s}'\n", .{arg}) catch "error: unknown run flag\n";
            return commandOptionError(msg);
        }
        if (options.source_file != null) {
            return commandOptionError("error: run accepts at most one source file\n");
        }
        options.source_file = arg;
    }

    return options;
}

fn parseTestTopOptions(raw_args: []const []const u8, allocator: std.mem.Allocator) ParseCommandOptionsError!TestCommandTopOptions {
    var options: TestCommandTopOptions = .{ .forwarded_args = &.{} };
    var forwarded: std.ArrayList([]const u8) = .empty;
    errdefer forwarded.deinit(allocator);

    var idx: usize = 0;
    while (idx < raw_args.len) : (idx += 1) {
        const arg = raw_args[idx];
        if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--package")) {
            if (idx + 1 >= raw_args.len) return commandOptionError("error: -p/--package requires a value\n");
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = raw_args[idx + 1];
            idx += 1;
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-p=")) {
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = arg["-p=".len..];
            continue;
        }
        if (std.mem.startsWith(u8, arg, "--package=")) {
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = arg["--package=".len..];
            continue;
        }
        try forwarded.append(allocator, arg);
    }

    options.forwarded_args = try forwarded.toOwnedSlice(allocator);
    return options;
}

fn parseCleanCommandOptions(raw_args: []const []const u8) ParseCommandOptionsError!CleanCommandOptions {
    var options: CleanCommandOptions = .{};
    var idx: usize = 0;
    while (idx < raw_args.len) : (idx += 1) {
        const arg = raw_args[idx];
        if (std.mem.eql(u8, arg, "--all")) {
            options.all = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--package")) {
            if (idx + 1 >= raw_args.len) return commandOptionError("error: -p/--package requires a value\n");
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = raw_args[idx + 1];
            idx += 1;
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-p=")) {
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = arg["-p=".len..];
            continue;
        }
        if (std.mem.startsWith(u8, arg, "--package=")) {
            if (options.package_filter != null) return commandOptionError("error: -p/--package may only be provided once\n");
            options.package_filter = arg["--package=".len..];
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-")) {
            var err_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&err_buf, "error: unknown clean flag '{s}'\n", .{arg}) catch "error: unknown clean flag\n";
            return commandOptionError(msg);
        }
        return commandOptionError("error: clean does not accept positional arguments\n");
    }
    return options;
}

fn buildPackageBinary(
    package_root: []const u8,
    source_file: ?[]const u8,
    opt_level: u8,
    no_std: bool,
    alloc_mode: bool,
    release_mode: bool,
    allocator: std.mem.Allocator,
    emit_compiled_line: bool,
) !?[]const u8 {
    var inputs = resolvePackageBuildInputs(package_root, source_file, allocator) catch |err| {
        switch (err) {
            error.MissingEntrypoint => {
                stderrPrint("error: no package entrypoint found (expected src/main.w, main.w, or one top-level .w file)\n");
            },
            error.AmbiguousEntrypoint => {
                stderrPrint("error: multiple top-level .w files found; pass an explicit source file\n");
            },
            else => {
                var err_buf: [256]u8 = undefined;
                const msg = std.fmt.bufPrint(&err_buf, "error: failed to resolve build inputs ({s})\n", .{@errorName(err)}) catch "error: failed to resolve build inputs\n";
                stderrPrint(msg);
            },
        }
        return null;
    };
    defer inputs.deinit(allocator);

    var layout = ensureArtifactLayout(package_root, release_mode, allocator) catch |err| {
        var err_buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&err_buf, "error: failed to create .with directories ({s})\n", .{@errorName(err)}) catch "error: failed to create .with directories\n";
        stderrPrint(msg);
        return null;
    };
    defer layout.deinit(allocator);

    var driver = Driver.init(allocator);
    defer driver.deinit();
    driver.opt_level = opt_level;
    driver.no_std = no_std;
    driver.alloc = alloc_mode;

    const bin_path = try driver.buildBinaryAt(inputs.source_path, layout.build_dir, inputs.output_stem);
    if (bin_path == null) return null;

    if (emit_compiled_line) {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stderr().writer(&buf);
        w.interface.print("compiled: {s}\n", .{bin_path.?}) catch {};
        w.interface.flush() catch {};
    }
    driver.printWarnings();

    return try allocator.dupe(u8, bin_path.?);
}

fn runCompiledBinary(
    binary_path: []const u8,
    run_root: []const u8,
    program_args: []const []const u8,
    allocator: std.mem.Allocator,
) !u8 {
    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.append(allocator, binary_path);
    for (program_args) |arg| try argv.append(allocator, arg);

    var child = std.process.Child.init(argv.items, allocator);
    var cwd_dir = std.fs.openDirAbsolute(run_root, .{}) catch |err| {
        var err_buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&err_buf, "error: failed to open run directory '{s}' ({s})\n", .{ run_root, @errorName(err) }) catch "error: failed to open run directory\n";
        stderrPrint(msg);
        return 1;
    };
    defer cwd_dir.close();
    child.cwd_dir = cwd_dir;

    _ = child.spawn() catch |e| {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stderr().writer(&buf);
        w.interface.print("error: failed to spawn binary: {}\n", .{e}) catch {};
        w.interface.flush() catch {};
        return 1;
    };
    const term = child.wait() catch |e| {
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stderr().writer(&buf);
        w.interface.print("error: failed to execute binary: {}\n", .{e}) catch {};
        w.interface.flush() catch {};
        return 1;
    };
    if (term == .Exited) return term.Exited;
    return 1;
}

fn runBuildCommand(
    raw_args: []const []const u8,
    opt_level: u8,
    no_std: bool,
    alloc_mode: bool,
    release_mode: bool,
    allocator: std.mem.Allocator,
) !u8 {
    const options = parseBuildCommandOptions(raw_args) catch return 1;
    const context = detectProjectContext(allocator) catch return 1;
    defer allocator.free(context.root);

    if (context.kind == .workspace) {
        if (options.source_file != null) {
            stderrPrint("error: workspace build does not accept a direct source file\n");
            return 1;
        }
        var workspace = discoverWorkspaceMembers(context.root, allocator) catch return 1;
        defer workspace.deinit(allocator);

        var selected: usize = 0;
        var failed: usize = 0;
        for (workspace.members.items) |member| {
            if (!workspaceMemberSelected(member, options.package_filter)) continue;
            selected += 1;
            var head_buf: [256]u8 = undefined;
            var w = std.fs.File.stdout().writer(&head_buf);
            w.interface.print("building {s}...\n", .{member.name}) catch {};
            w.interface.flush() catch {};

            const result = try buildPackageBinary(
                member.root_path,
                null,
                opt_level,
                no_std,
                alloc_mode,
                release_mode,
                allocator,
                true,
            );
            if (result) |bin_path| {
                allocator.free(bin_path);
                var ok_buf: [128]u8 = undefined;
                var ok_w = std.fs.File.stdout().writer(&ok_buf);
                ok_w.interface.writeAll("ok\n") catch {};
                ok_w.interface.flush() catch {};
            } else {
                failed += 1;
                var fail_buf: [128]u8 = undefined;
                var fail_w = std.fs.File.stdout().writer(&fail_buf);
                fail_w.interface.writeAll("FAIL\n") catch {};
                fail_w.interface.flush() catch {};
            }
        }
        if (selected == 0) {
            stderrPrint("error: no workspace members matched selection\n");
            return 1;
        }
        return if (failed == 0) 0 else 1;
    }

    if (options.package_filter != null) {
        stderrPrint("error: -p/--package can only be used at a workspace root\n");
        return 1;
    }

    const result = try buildPackageBinary(
        context.root,
        options.source_file,
        opt_level,
        no_std,
        alloc_mode,
        release_mode,
        allocator,
        true,
    );
    if (result) |bin_path| {
        allocator.free(bin_path);
        return 0;
    }
    return 1;
}

fn runRunCommand(
    raw_args: []const []const u8,
    opt_level: u8,
    no_std: bool,
    alloc_mode: bool,
    release_mode: bool,
    allocator: std.mem.Allocator,
) !u8 {
    const options = parseRunCommandOptions(raw_args) catch return 1;
    const context = detectProjectContext(allocator) catch return 1;
    defer allocator.free(context.root);

    var target_root: []const u8 = context.root;
    var target_source: ?[]const u8 = options.source_file;
    var owned_target_root: ?[]const u8 = null;
    defer if (owned_target_root) |path| allocator.free(path);

    if (context.kind == .workspace) {
        if (options.source_file != null) {
            stderrPrint("error: workspace run does not accept a direct source file\n");
            return 1;
        }
        if (options.package_filter == null) {
            stderrPrint("error: workspace run requires -p <member>\n");
            return 1;
        }
        var workspace = discoverWorkspaceMembers(context.root, allocator) catch return 1;
        defer workspace.deinit(allocator);

        var matched_root: ?[]const u8 = null;
        for (workspace.members.items) |member| {
            if (!workspaceMemberSelected(member, options.package_filter)) continue;
            matched_root = member.root_path;
            break;
        }
        if (matched_root == null) {
            stderrPrint("error: workspace member not found\n");
            return 1;
        }
        owned_target_root = try allocator.dupe(u8, matched_root.?);
        target_root = owned_target_root.?;
        target_source = null;
    } else if (options.package_filter != null) {
        stderrPrint("error: -p/--package can only be used at a workspace root\n");
        return 1;
    }

    const built = try buildPackageBinary(
        target_root,
        target_source,
        opt_level,
        no_std,
        alloc_mode,
        release_mode,
        allocator,
        false,
    );
    if (built == null) return 1;
    defer allocator.free(built.?);

    return try runCompiledBinary(built.?, target_root, options.program_args, allocator);
}

fn runTestCommand(
    raw_args: []const []const u8,
    opt_level: u8,
    no_std: bool,
    alloc_mode: bool,
    allocator: std.mem.Allocator,
) !u8 {
    const options = parseTestTopOptions(raw_args, allocator) catch return 1;
    defer allocator.free(options.forwarded_args);

    const context = detectProjectContext(allocator) catch return 1;
    defer allocator.free(context.root);

    if (context.kind == .workspace) {
        var workspace = discoverWorkspaceMembers(context.root, allocator) catch return 1;
        defer workspace.deinit(allocator);

        var selected: usize = 0;
        var failed: usize = 0;
        for (workspace.members.items) |member| {
            if (!workspaceMemberSelected(member, options.package_filter)) continue;
            selected += 1;
            var head_buf: [256]u8 = undefined;
            var w = std.fs.File.stdout().writer(&head_buf);
            w.interface.print("testing {s}...\n", .{member.name}) catch {};
            w.interface.flush() catch {};

            const code = try runPackageTestsAtRoot(
                member.root_path,
                options.forwarded_args,
                opt_level,
                no_std,
                alloc_mode,
                allocator,
            );
            if (code != 0) failed += 1;
        }
        if (selected == 0) {
            stderrPrint("error: no workspace members matched selection\n");
            return 1;
        }
        return if (failed == 0) 0 else 1;
    }

    if (options.package_filter != null) {
        stderrPrint("error: -p/--package can only be used at a workspace root\n");
        return 1;
    }

    return runPackageTestsAtRoot(context.root, options.forwarded_args, opt_level, no_std, alloc_mode, allocator);
}

fn cleanPackageArtifacts(package_root: []const u8, allocator: std.mem.Allocator) !void {
    const with_dir = try std.fmt.allocPrint(allocator, "{s}/.with", .{package_root});
    defer allocator.free(with_dir);
    std.fs.deleteTreeAbsolute(with_dir) catch |err| switch (err) {
        error.FileNotFound => {},
        error.NotDir => {},
        else => return err,
    };
}

fn runCleanCommand(raw_args: []const []const u8, allocator: std.mem.Allocator) !u8 {
    const options = parseCleanCommandOptions(raw_args) catch return 1;
    const context = detectProjectContext(allocator) catch return 1;
    defer allocator.free(context.root);

    if (context.kind == .workspace) {
        var workspace = discoverWorkspaceMembers(context.root, allocator) catch return 1;
        defer workspace.deinit(allocator);

        var selected: usize = 0;
        for (workspace.members.items) |member| {
            if (!workspaceMemberSelected(member, options.package_filter)) continue;
            selected += 1;
            cleanPackageArtifacts(member.root_path, allocator) catch |err| {
                var err_buf: [256]u8 = undefined;
                const msg = std.fmt.bufPrint(&err_buf, "error: failed to clean '{s}' ({s})\n", .{ member.name, @errorName(err) }) catch "error: clean failed\n";
                stderrPrint(msg);
                return 1;
            };
            var ok_buf: [256]u8 = undefined;
            var w = std.fs.File.stdout().writer(&ok_buf);
            w.interface.print("cleaned {s}\n", .{member.name}) catch {};
            w.interface.flush() catch {};
        }
        if (selected == 0) {
            stderrPrint("error: no workspace members matched selection\n");
            return 1;
        }
        return 0;
    }

    if (options.package_filter != null or options.all) {
        stderrPrint("error: --all and -p/--package are only valid at a workspace root\n");
        return 1;
    }
    cleanPackageArtifacts(context.root, allocator) catch |err| {
        var err_buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&err_buf, "error: clean failed ({s})\n", .{@errorName(err)}) catch "error: clean failed\n";
        stderrPrint(msg);
        return 1;
    };
    return 0;
}

fn runPackageTestsAtRoot(
    project_root: []const u8,
    raw_args: []const []const u8,
    opt_level: u8,
    no_std: bool,
    alloc_mode: bool,
    allocator: std.mem.Allocator,
) !u8 {
    const options = parsePackageTestOptions(raw_args) catch return 1;
    const package_name = std.fs.path.basename(project_root);

    var discovery = try discoverPackageTests(project_root, allocator);
    defer discovery.deinit(allocator);
    sortPackageTestsByFileAndLine(discovery.tests.items);
    sortStrings(discovery.module_paths.items);

    if (reportDuplicateTestNames(discovery.tests.items)) return 1;

    var selected_indices: std.ArrayList(usize) = .empty;
    defer selected_indices.deinit(allocator);
    for (discovery.tests.items, 0..) |test_case, idx| {
        if (!packageTestMatchesFilters(test_case, options.run_pattern, options.positional_filter)) continue;
        try selected_indices.append(allocator, idx);
    }

    if (options.list) {
        for (selected_indices.items) |idx| {
            var buf: [4096]u8 = undefined;
            var w = std.fs.File.stdout().writer(&buf);
            w.interface.print("{s}\n", .{discovery.tests.items[idx].name}) catch {};
            w.interface.flush() catch {};
        }
        return 0;
    }

    if (options.shuffle and selected_indices.items.len > 1) {
        const seed = options.shuffle_seed orelse @as(u64, @intCast(@abs(std.time.nanoTimestamp())));
        var prng = std.Random.DefaultPrng.init(seed);
        prng.random().shuffle(usize, selected_indices.items);
    }

    var run_started = try std.time.Timer.start();
    var passed: usize = 0;
    var failed: usize = 0;
    var skipped: usize = 0;

    if (selected_indices.items.len == 0) {
        if (options.run_pattern != null or options.positional_filter != null) {
            stderrPrint("error: no tests matched filter\n");
            return 1;
        }
        printPackageSummary(true, package_name, run_started.read(), skipped);
        return 0;
    }

    var layout = ensureArtifactLayout(project_root, false, allocator) catch |err| {
        var err_buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&err_buf, "error: failed to create .with directories ({s})\n", .{@errorName(err)}) catch "error: failed to create .with directories\n";
        stderrPrint(msg);
        return 1;
    };
    defer layout.deinit(allocator);

    const runner_stem = try std.fmt.allocPrint(allocator, "test_runner_{d}", .{@abs(std.time.nanoTimestamp())});
    defer allocator.free(runner_stem);
    const runner_source_path = try std.fmt.allocPrint(allocator, "{s}/.{s}.w", .{ project_root, runner_stem });
    defer allocator.free(runner_source_path);
    const runner_bin_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ layout.test_dir, runner_stem });
    defer allocator.free(runner_bin_path);
    const runner_obj_path = try std.fmt.allocPrint(allocator, "{s}/{s}.o", .{ layout.test_dir, runner_stem });
    defer allocator.free(runner_obj_path);

    defer deleteAbsoluteFileQuiet(runner_source_path);
    defer deleteAbsoluteFileQuiet(runner_bin_path);
    defer deleteAbsoluteFileQuiet(runner_obj_path);

    var timed_out = false;
    outer: for (selected_indices.items) |selected_idx| {
        if (run_started.read() > options.timeout_ns) {
            timed_out = true;
            failed += 1;
            break;
        }

        const test_case = discovery.tests.items[selected_idx];

        try writeGeneratedTestRunner(runner_source_path, discovery.module_paths.items, test_case);

        var driver = Driver.init(allocator);
        defer driver.deinit();
        driver.opt_level = opt_level;
        driver.no_std = no_std;
        driver.alloc = alloc_mode;

        const bin_path_opt = try driver.buildBinaryAt(runner_source_path, layout.test_dir, runner_stem);
        if (bin_path_opt == null) {
            failed += 1;
            break;
        }

        var count_idx: usize = 0;
        while (count_idx < options.count) : (count_idx += 1) {
            if (run_started.read() > options.timeout_ns) {
                timed_out = true;
                failed += 1;
                break :outer;
            }

            var one_test_timer = try std.time.Timer.start();
            if (options.verbose) printVerboseTestRun("RUN", test_case.name, 0);

            const run_result = runGeneratedTestBinary(runner_bin_path, project_root, options.short, allocator) catch |err| {
                failed += 1;
                if (options.verbose) printVerboseTestRun("FAIL", test_case.name, one_test_timer.read());
                var err_buf: [256]u8 = undefined;
                const msg = std.fmt.bufPrint(&err_buf, "    failed to execute test binary: {s}\n", .{@errorName(err)}) catch "    failed to execute test binary\n";
                stderrPrint(msg);
                if (options.failfast) break :outer;
                continue;
            };
            defer allocator.free(run_result.stdout);
            defer allocator.free(run_result.stderr);

            const elapsed_ns = one_test_timer.read();
            switch (run_result.status) {
                .passed => {
                    passed += 1;
                    if (options.verbose) printVerboseTestRun("PASS", test_case.name, elapsed_ns);
                },
                .skipped => {
                    skipped += 1;
                    if (options.verbose) printVerboseTestRun("SKIP", test_case.name, elapsed_ns);
                },
                .failed => {
                    failed += 1;
                    printFailureReport(test_case, elapsed_ns, run_result.stdout, run_result.stderr);
                    if (options.verbose) printVerboseTestRun("FAIL", test_case.name, elapsed_ns);
                    if (options.failfast) break :outer;
                },
            }
        }

        deleteAbsoluteFileQuiet(runner_bin_path);
        deleteAbsoluteFileQuiet(runner_obj_path);
    }

    if (timed_out) {
        stderrPrint("error: test run timed out\n");
    }

    const ok = failed == 0;
    printPackageSummary(ok, package_name, run_started.read(), skipped);
    return if (ok) 0 else 1;
}

fn parsePackageTestOptions(args: []const []const u8) ParsePackageTestOptionsError!PackageTestOptions {
    var options: PackageTestOptions = .{};
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "-v")) {
            options.verbose = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "-short")) {
            options.short = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "-failfast")) {
            options.failfast = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "-list")) {
            options.list = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "-shuffle")) {
            options.shuffle = true;
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-shuffle=")) {
            const raw_seed = arg["-shuffle=".len..];
            if (raw_seed.len == 0) return packageTestOptionError("error: '-shuffle' seed must be an integer\n");
            options.shuffle = true;
            options.shuffle_seed = std.fmt.parseInt(u64, raw_seed, 10) catch {
                return packageTestOptionError("error: '-shuffle' seed must be an integer\n");
            };
            continue;
        }
        if (std.mem.eql(u8, arg, "-run")) {
            if (i + 1 >= args.len) return packageTestOptionError("error: '-run' requires a pattern\n");
            i += 1;
            options.run_pattern = args[i];
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-run=")) {
            options.run_pattern = arg["-run=".len..];
            continue;
        }
        if (std.mem.eql(u8, arg, "-count")) {
            if (i + 1 >= args.len) return packageTestOptionError("error: '-count' requires a positive integer\n");
            i += 1;
            options.count = std.fmt.parseInt(usize, args[i], 10) catch {
                return packageTestOptionError("error: '-count' requires a positive integer\n");
            };
            if (options.count == 0) return packageTestOptionError("error: '-count' must be >= 1\n");
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-count=")) {
            const raw_count = arg["-count=".len..];
            options.count = std.fmt.parseInt(usize, raw_count, 10) catch {
                return packageTestOptionError("error: '-count' requires a positive integer\n");
            };
            if (options.count == 0) return packageTestOptionError("error: '-count' must be >= 1\n");
            continue;
        }
        if (std.mem.eql(u8, arg, "-timeout")) {
            if (i + 1 >= args.len) return packageTestOptionError("error: '-timeout' requires a duration (e.g. 30s, 5m, 1h)\n");
            i += 1;
            options.timeout_ns = parseDurationNs(args[i]) catch {
                return packageTestOptionError("error: '-timeout' requires a duration (e.g. 30s, 5m, 1h)\n");
            };
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-timeout=")) {
            const raw_timeout = arg["-timeout=".len..];
            options.timeout_ns = parseDurationNs(raw_timeout) catch {
                return packageTestOptionError("error: '-timeout' requires a duration (e.g. 30s, 5m, 1h)\n");
            };
            continue;
        }
        if (std.mem.startsWith(u8, arg, "-bench")) {
            return packageTestOptionError("error: '-bench' is not implemented yet\n");
        }
        if (std.mem.eql(u8, arg, "-cover")) {
            return packageTestOptionError("error: '-cover' is not implemented yet\n");
        }
        if (arg.len > 0 and arg[0] == '-') {
            var err_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&err_buf, "error: unknown test flag '{s}'\n", .{arg}) catch "error: unknown test flag\n";
            return packageTestOptionError(msg);
        }
        if (options.positional_filter != null) {
            return packageTestOptionError("error: only one test filter positional argument is supported\n");
        }
        options.positional_filter = arg;
    }

    return options;
}

fn packageTestOptionError(msg: []const u8) ParsePackageTestOptionsError {
    stderrPrint(msg);
    return error.InvalidArgs;
}

fn parseDurationNs(raw: []const u8) ParseDurationError!u64 {
    if (raw.len < 2) return error.InvalidDuration;
    const unit = raw[raw.len - 1];
    const amount = std.fmt.parseInt(u64, raw[0 .. raw.len - 1], 10) catch return error.InvalidDuration;
    const multiplier: u64 = switch (unit) {
        's' => std.time.ns_per_s,
        'm' => 60 * std.time.ns_per_s,
        'h' => 60 * 60 * std.time.ns_per_s,
        else => return error.InvalidDuration,
    };
    return std.math.mul(u64, amount, multiplier) catch error.Overflow;
}

fn pathExistsAbsolute(path: []const u8) bool {
    std.fs.accessAbsolute(path, .{}) catch return false;
    return true;
}

fn discoverPackageTests(project_root: []const u8, allocator: std.mem.Allocator) !PackageTestDiscovery {
    var discovery: PackageTestDiscovery = .{};
    errdefer discovery.deinit(allocator);

    var dir = try std.fs.openDirAbsolute(project_root, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        const rel_path: []const u8 = entry.path;
        if (!std.mem.endsWith(u8, rel_path, ".w")) continue;
        if (shouldSkipTestDiscoveryPath(rel_path)) continue;

        const module_path = try modulePathFromRelativeWFile(rel_path, allocator);
        defer allocator.free(module_path);
        const source_text = entry.dir.readFileAlloc(allocator, entry.basename, 8 * 1024 * 1024) catch |err| {
            var err_buf: [512]u8 = undefined;
            const msg = std.fmt.bufPrint(&err_buf, "error: failed to read '{s}' ({s})\n", .{ rel_path, @errorName(err) }) catch "error: failed to read test source\n";
            stderrPrint(msg);
            return err;
        };
        defer allocator.free(source_text);

        var source = Source.fromString(rel_path, source_text, 0, allocator);
        defer source.deinit();

        var diags = Diagnostic.DiagnosticList.init(allocator);
        defer diags.deinit();
        var lexer = Lexer.init(source_text, 0, &diags);
        var tokens = try lexer.tokenize(allocator);
        defer tokens.deinit();

        var pool = InternPool.init(allocator);
        defer pool.deinit();
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        var parser = Parser.init(&tokens, source_text, arena.allocator(), &pool, &diags);

        const module = parser.parseModule() catch {
            var err_buf: [512]u8 = undefined;
            const msg = std.fmt.bufPrint(&err_buf, "error: failed to parse '{s}' while discovering tests\n", .{rel_path}) catch "error: failed to parse test source\n";
            stderrPrint(msg);
            return error.ParseError;
        };

        var before_name: ?[]const u8 = null;
        defer if (before_name) |name| allocator.free(name);
        var after_name: ?[]const u8 = null;
        defer if (after_name) |name| allocator.free(name);
        var discovered_indices: std.ArrayList(usize) = .empty;
        defer discovered_indices.deinit(allocator);

        for (module.decls) |decl| {
            if (decl.kind != .function) continue;
            const fn_decl = decl.kind.function;
            const fn_name = pool.resolve(fn_decl.name);

            if (fn_decl.is_before) {
                if (before_name != null) {
                    var err_buf: [512]u8 = undefined;
                    const msg = std.fmt.bufPrint(&err_buf, "error: multiple @[before] functions in '{s}'\n", .{rel_path}) catch "error: multiple @[before] functions\n";
                    stderrPrint(msg);
                    return error.InvalidTestHooks;
                }
                before_name = try allocator.dupe(u8, fn_name);
            }

            if (fn_decl.is_after) {
                if (after_name != null) {
                    var err_buf: [512]u8 = undefined;
                    const msg = std.fmt.bufPrint(&err_buf, "error: multiple @[after] functions in '{s}'\n", .{rel_path}) catch "error: multiple @[after] functions\n";
                    stderrPrint(msg);
                    return error.InvalidTestHooks;
                }
                after_name = try allocator.dupe(u8, fn_name);
            }

            if (!fn_decl.is_test) continue;

            const loc = source.offsetToLocation(decl.span.start);
            const test_idx = discovery.tests.items.len;
            try discovery.tests.append(allocator, .{
                .name = try allocator.dupe(u8, fn_name),
                .file_path = try allocator.dupe(u8, rel_path),
                .module_path = try allocator.dupe(u8, module_path),
                .line = loc.line + 1,
                .returns_result = isResultReturnType(fn_decl.return_type, &pool),
                .before_name = null,
                .after_name = null,
            });
            try discovered_indices.append(allocator, test_idx);
        }

        if (discovered_indices.items.len > 0 and !containsString(discovery.module_paths.items, module_path)) {
            try discovery.module_paths.append(allocator, try allocator.dupe(u8, module_path));
        }

        for (discovered_indices.items) |test_idx| {
            if (before_name) |name| {
                discovery.tests.items[test_idx].before_name = try allocator.dupe(u8, name);
            }
            if (after_name) |name| {
                discovery.tests.items[test_idx].after_name = try allocator.dupe(u8, name);
            }
        }
    }

    return discovery;
}

fn shouldSkipTestDiscoveryPath(path: []const u8) bool {
    var it = std.mem.tokenizeAny(u8, path, "/\\");
    while (it.next()) |segment| {
        if (std.mem.eql(u8, segment, ".git")) return true;
        if (std.mem.eql(u8, segment, ".zig-cache")) return true;
        if (std.mem.eql(u8, segment, "zig-out")) return true;
        if (std.mem.eql(u8, segment, ".with")) return true;
        if (std.mem.eql(u8, segment, "testdata")) return true;
        if (std.mem.eql(u8, segment, "bootstrap")) return true;
        if (std.mem.eql(u8, segment, "examples")) return true;
        if (std.mem.startsWith(u8, segment, ".with_test_runner_")) return true;
        // Skip directories with hyphens — they produce invalid module paths.
        if (std.mem.indexOfScalar(u8, segment, '-') != null) return true;
    }
    return false;
}

fn modulePathFromRelativeWFile(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    if (!std.mem.endsWith(u8, path, ".w")) return error.InvalidModulePath;
    const stem = path[0 .. path.len - 2];

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    for (stem) |ch| {
        if (ch == '/' or ch == '\\') {
            try out.append(allocator, '.');
        } else {
            try out.append(allocator, ch);
        }
    }

    return out.toOwnedSlice(allocator);
}

fn isResultReturnType(return_type: ?*const Ast.TypeExpr, pool: *const InternPool) bool {
    const rt = return_type orelse return false;
    return switch (rt.kind) {
        .named => |sym| std.mem.eql(u8, pool.resolve(sym), "Result"),
        .generic => |g| std.mem.eql(u8, pool.resolve(g.name), "Result"),
        else => false,
    };
}

fn containsString(values: []const []const u8, needle: []const u8) bool {
    for (values) |value| {
        if (std.mem.eql(u8, value, needle)) return true;
    }
    return false;
}

fn reportDuplicateTestNames(tests: []const PackageTest) bool {
    for (tests, 0..) |lhs, i| {
        var j: usize = i + 1;
        while (j < tests.len) : (j += 1) {
            const rhs = tests[j];
            if (!std.mem.eql(u8, lhs.name, rhs.name)) continue;
            var err_buf: [1024]u8 = undefined;
            const msg = std.fmt.bufPrint(
                &err_buf,
                "error: duplicate test name '{s}' in '{s}:{d}' and '{s}:{d}'\n",
                .{ lhs.name, lhs.file_path, lhs.line, rhs.file_path, rhs.line },
            ) catch "error: duplicate test name\n";
            stderrPrint(msg);
            return true;
        }
    }
    return false;
}

fn packageTestMatchesFilters(test_case: PackageTest, run_pattern: ?[]const u8, positional_filter: ?[]const u8) bool {
    if (run_pattern) |pattern| {
        if (std.mem.indexOf(u8, test_case.name, pattern) == null) return false;
    }
    if (positional_filter) |pattern| {
        if (std.mem.indexOf(u8, test_case.name, pattern) == null and
            std.mem.indexOf(u8, test_case.file_path, pattern) == null)
        {
            return false;
        }
    }
    return true;
}

fn writeGeneratedTestRunner(
    runner_source_path: []const u8,
    module_paths: []const []const u8,
    test_case: PackageTest,
) !void {
    var file = try std.fs.createFileAbsolute(runner_source_path, .{ .truncate = true });
    defer file.close();

    var out_buf: [32768]u8 = undefined;
    var out = file.writer(&out_buf);
    const writer = &out.interface;

    try writer.writeAll("use test.testing\n");
    for (module_paths) |module_path| {
        try writer.print("use {s}\n", .{module_path});
    }

    try writer.writeAll("\nfn __with_test_entry -> void:\n");
    if (test_case.returns_result) {
        try writer.print("    match {s}()\n", .{test_case.name});
        try writer.writeAll("        Ok(()) -> ()\n");
        try writer.writeAll("        Err(_e) -> fail(\"returned Err\")\n");
    } else {
        try writer.print("    {s}()\n", .{test_case.name});
    }

    try writer.writeAll("\nfn main -> i32:\n");
    if (test_case.before_name) |before_name| {
        try writer.print("    {s}()\n", .{before_name});
    }
    try writer.writeAll("    __with_test_entry()\n");
    if (test_case.after_name) |after_name| {
        try writer.print("    {s}()\n", .{after_name});
    }
    try writer.writeAll("    0\n");
    try out.interface.flush();
}

fn runGeneratedTestBinary(
    binary_path: []const u8,
    project_root: []const u8,
    short_mode: bool,
    allocator: std.mem.Allocator,
) !PackageTestRunResult {
    var env_map_storage: ?std.process.EnvMap = null;
    defer if (env_map_storage) |*map| map.deinit();

    var env_map_ptr: ?*const std.process.EnvMap = null;
    if (short_mode) {
        env_map_storage = try std.process.getEnvMap(allocator);
        try env_map_storage.?.put("WITH_TEST_SHORT", "1");
        if (env_map_storage) |*map| env_map_ptr = map;
    }

    const run_result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{binary_path},
        .cwd = project_root,
        .env_map = env_map_ptr,
        .max_output_bytes = 1024 * 1024,
    });

    const skipped = outputContainsSkipMarker(run_result.stdout) or outputContainsSkipMarker(run_result.stderr);
    const status: PackageTestRunStatus = if (run_result.term == .Exited and run_result.term.Exited == 0)
        (if (skipped) .skipped else .passed)
    else
        .failed;

    return .{
        .status = status,
        .term = run_result.term,
        .stdout = run_result.stdout,
        .stderr = run_result.stderr,
    };
}

fn outputContainsSkipMarker(output: []const u8) bool {
    return std.mem.indexOf(u8, output, with_test_skip_marker) != null;
}

fn printVerboseTestRun(kind: []const u8, test_name: []const u8, duration_ns: u64) void {
    var buf: [512]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);

    if (std.mem.eql(u8, kind, "RUN")) {
        w.interface.print("=== RUN   {s}\n", .{test_name}) catch {};
        w.interface.flush() catch {};
        return;
    }

    var duration_buf: [32]u8 = undefined;
    const duration_text = formatDuration(duration_ns, &duration_buf);
    w.interface.print("--- {s}: {s} ({s})\n", .{ kind, test_name, duration_text }) catch {};
    w.interface.flush() catch {};
}

fn printFailureReport(test_case: PackageTest, duration_ns: u64, stdout_data: []const u8, stderr_data: []const u8) void {
    var buf: [1024]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    var duration_buf: [32]u8 = undefined;
    const duration_text = formatDuration(duration_ns, &duration_buf);
    w.interface.print("--- FAIL: {s} ({s})\n", .{ test_case.name, duration_text }) catch {};
    w.interface.flush() catch {};

    printIndentedOutput(stdout_data);
    printIndentedOutput(stderr_data);
}

fn printIndentedOutput(data: []const u8) void {
    var line_it = std.mem.splitScalar(u8, data, '\n');
    while (line_it.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, with_test_skip_marker)) continue;
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stdout().writer(&buf);
        w.interface.print("    {s}\n", .{line}) catch {};
        w.interface.flush() catch {};
    }
}

fn printPackageSummary(ok: bool, package_name: []const u8, total_ns: u64, skipped: usize) void {
    var duration_buf: [32]u8 = undefined;
    const duration_text = formatDuration(total_ns, &duration_buf);

    var buf: [1024]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    if (ok) {
        w.interface.writeAll("PASS\n") catch {};
        w.interface.print("ok\t{s}\t{s}\n", .{ package_name, duration_text }) catch {};
    } else {
        w.interface.writeAll("FAIL\n") catch {};
        w.interface.print("FAIL\t{s}\t{s}\n", .{ package_name, duration_text }) catch {};
    }
    if (skipped > 0) {
        w.interface.print("skipped\t{d}\n", .{skipped}) catch {};
    }
    w.interface.flush() catch {};
}

fn formatDuration(duration_ns: u64, buf: []u8) []const u8 {
    const secs = duration_ns / std.time.ns_per_s;
    const millis = (duration_ns % std.time.ns_per_s) / std.time.ns_per_ms;
    return std.fmt.bufPrint(buf, "{d}.{d}{d}{d}s", .{
        secs,
        (millis / 100) % 10,
        (millis / 10) % 10,
        millis % 10,
    }) catch "0.000s";
}

fn deleteAbsoluteFileQuiet(path: []const u8) void {
    std.fs.deleteFileAbsolute(path) catch {};
}

fn sortPackageTestsByFileAndLine(items: []PackageTest) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        var j = i;
        while (j > 0 and packageTestLess(items[j], items[j - 1])) : (j -= 1) {
            const tmp = items[j];
            items[j] = items[j - 1];
            items[j - 1] = tmp;
        }
    }
}

fn packageTestLess(lhs: PackageTest, rhs: PackageTest) bool {
    const path_order = std.mem.order(u8, lhs.file_path, rhs.file_path);
    if (path_order == .lt) return true;
    if (path_order == .gt) return false;
    if (lhs.line < rhs.line) return true;
    if (lhs.line > rhs.line) return false;
    return std.mem.order(u8, lhs.name, rhs.name) == .lt;
}

fn sortStrings(items: [][]const u8) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        var j = i;
        while (j > 0 and std.mem.order(u8, items[j], items[j - 1]) == .lt) : (j -= 1) {
            const tmp = items[j];
            items[j] = items[j - 1];
            items[j - 1] = tmp;
        }
    }
}

const TestSummary = struct {
    passed: usize = 0,
    failed: usize = 0,
    skipped: usize = 0,
};

fn runTests(target: []const u8, update_snapshots: bool, allocator: std.mem.Allocator) !bool {
    var summary: TestSummary = .{};
    const cwd = std.fs.cwd();

    if (std.mem.endsWith(u8, target, ".w")) {
        try runOneTest(target, update_snapshots, allocator, &summary);
        printTestSummary(&summary);
        return summary.failed == 0;
    }

    var dir = cwd.openDir(target, .{ .iterate = true }) catch |e| {
        stderrPrint("error: cannot open test path\n");
        var buf: [4096]u8 = undefined;
        var w = std.fs.File.stderr().writer(&buf);
        w.interface.print("detail: {s}: {}\n", .{ target, e }) catch {};
        w.interface.flush() catch {};
        return false;
    };
    defer dir.close();

    var files: std.ArrayList([]const u8) = .empty;
    defer {
        for (files.items) |path| allocator.free(path);
        files.deinit(allocator);
    }

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".w")) continue;
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ target, entry.name });
        try files.append(allocator, path);
    }

    sortStrings(files.items);
    for (files.items) |path| {
        try runOneTest(path, update_snapshots, allocator, &summary);
    }

    printTestSummary(&summary);
    return summary.failed == 0;
}

fn runOneTest(path: []const u8, update_snapshots: bool, allocator: std.mem.Allocator, summary: *TestSummary) !void {
    const source = std.fs.cwd().readFileAlloc(allocator, path, 2 * 1024 * 1024) catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };
    defer allocator.free(source);

    // Parse test flags from `// FLAGS: --no-std --alloc` comment
    // and inline `//!` directives for self-contained tests.
    var test_no_std = false;
    var test_alloc = false;
    var test_expect_error = false;
    var inline_stdout_list: std.ArrayList(u8) = .empty;
    var inline_stderr_list: std.ArrayList(u8) = .empty;
    var has_inline_stdout = false;
    var has_inline_stderr = false;
    var inline_exit: ?i32 = null;
    defer inline_stdout_list.deinit(allocator);
    defer inline_stderr_list.deinit(allocator);
    {
        var line_iter = std.mem.splitScalar(u8, source, '\n');
        while (line_iter.next()) |line| {
            const trimmed = std.mem.trimLeft(u8, line, " \t");
            if (std.mem.startsWith(u8, trimmed, "// FLAGS:")) {
                const flags_str = trimmed["// FLAGS:".len..];
                var flag_iter = std.mem.splitScalar(u8, flags_str, ' ');
                while (flag_iter.next()) |flag| {
                    const f = std.mem.trim(u8, flag, " \t");
                    if (std.mem.eql(u8, f, "--no-std")) test_no_std = true;
                    if (std.mem.eql(u8, f, "--alloc")) test_alloc = true;
                    if (std.mem.eql(u8, f, "--expect-error")) test_expect_error = true;
                }
            } else if (std.mem.startsWith(u8, trimmed, "//!")) {
                const directive = std.mem.trim(u8, trimmed["//!".len..], " \t");
                if (std.mem.startsWith(u8, directive, "expect-stdout:")) {
                    const val = std.mem.trim(u8, directive["expect-stdout:".len..], " \t");
                    has_inline_stdout = true;
                    inline_stdout_list.appendSlice(allocator, val) catch {};
                    inline_stdout_list.append(allocator, '\n') catch {};
                } else if (std.mem.startsWith(u8, directive, "expect-stderr:")) {
                    const val = std.mem.trim(u8, directive["expect-stderr:".len..], " \t");
                    has_inline_stderr = true;
                    inline_stderr_list.appendSlice(allocator, val) catch {};
                    inline_stderr_list.append(allocator, '\n') catch {};
                } else if (std.mem.startsWith(u8, directive, "expect-exit:")) {
                    const val = std.mem.trim(u8, directive["expect-exit:".len..], " \t");
                    inline_exit = std.fmt.parseInt(i32, val, 10) catch null;
                } else if (std.mem.eql(u8, directive, "expect-error")) {
                    test_expect_error = true;
                } else if (std.mem.eql(u8, directive, "no-std")) {
                    test_no_std = true;
                }
            }
            if (trimmed.len > 0 and !std.mem.startsWith(u8, trimmed, "//")) break;
        }
    }

    if (!sourceHasMainFn(source) and !test_expect_error) {
        summary.skipped += 1;
        testStatusMsg("SKIP", path, "no main");
        return;
    }

    var driver = Driver.init(allocator);
    defer driver.deinit();
    driver.no_std = test_no_std;
    driver.alloc = test_alloc;

    const bin_path_opt = try driver.buildBinary(path);

    // For tests that expect compilation failure, success is bin_path == null.
    if (test_expect_error) {
        if (bin_path_opt == null) {
            summary.passed += 1;
            testStatusMsg("PASS", path, "");
        } else {
            summary.failed += 1;
            testStatusMsg("FAIL", path, "expected compile error but compiled OK");
            // Clean up the binary.
            std.fs.cwd().deleteFile(bin_path_opt.?) catch {};
        }
        return;
    }

    if (bin_path_opt == null) {
        summary.failed += 1;
        testStatusMsg("FAIL", path, "compile/link");
        return;
    }
    const bin_path = bin_path_opt.?;
    const has_inline_directives = has_inline_stdout or has_inline_stderr or inline_exit != null;

    // When inline directives are present, use them instead of sidecar files.
    const expected_exit = if (inline_exit) |ex| ex else loadExpectedExit(path, allocator) catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };
    const expected_stdout: ?[]const u8 = if (has_inline_stdout) inline_stdout_list.items else loadExpectedOutput(path, allocator, "stdout") catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };
    defer if (!has_inline_stdout) {
        if (expected_stdout) |buf| allocator.free(@constCast(buf));
    };
    const expected_stderr: ?[]const u8 = if (has_inline_stderr) inline_stderr_list.items else loadExpectedOutput(path, allocator, "stderr") catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };
    defer if (!has_inline_stderr) {
        if (expected_stderr) |buf| allocator.free(@constCast(buf));
    };

    // Clean up binary and object file after test completes.
    defer std.fs.cwd().deleteFile(bin_path) catch {};
    defer {
        const stem = blk: {
            const base = std.fs.path.basename(path);
            if (std.mem.endsWith(u8, base, ".w")) break :blk base[0 .. base.len - 2];
            break :blk base;
        };
        const dir = std.fs.path.dirname(path) orelse ".";
        var obj_buf: [4096]u8 = undefined;
        if (std.fmt.bufPrint(&obj_buf, "{s}/{s}.o", .{ dir, stem })) |obj_path| {
            std.fs.cwd().deleteFile(obj_path) catch {};
        } else |_| {}
    }

    var child = std.process.Child.init(&.{bin_path}, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    _ = child.spawn() catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };

    const actual_stdout = child.stdout.?.readToEndAlloc(allocator, 64 * 1024) catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };
    defer allocator.free(actual_stdout);

    const actual_stderr = child.stderr.?.readToEndAlloc(allocator, 64 * 1024) catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };
    defer allocator.free(actual_stderr);

    const term = child.wait() catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };

    // Skip snapshot logic for inline-directive tests.
    if (!has_inline_directives) {
        const snapshot_text = formatSnapshot(term, actual_stdout, actual_stderr, allocator) catch |e| {
            summary.failed += 1;
            testStatus("FAIL", path, e);
            return;
        };
        defer allocator.free(snapshot_text);
        const snapshot_path = expectationPath(path, "expected", allocator) catch |e| {
            summary.failed += 1;
            testStatus("FAIL", path, e);
            return;
        };
        defer allocator.free(snapshot_path);
        const existing_snapshot = std.fs.cwd().readFileAlloc(allocator, snapshot_path, 128 * 1024) catch |e| switch (e) {
            error.FileNotFound => null,
            else => {
                summary.failed += 1;
                testStatus("FAIL", path, e);
                return;
            },
        };
        defer if (existing_snapshot) |buf| allocator.free(buf);

        if (existing_snapshot) |expected_snapshot| {
            if (!std.mem.eql(u8, expected_snapshot, snapshot_text)) {
                if (update_snapshots) {
                    std.fs.cwd().writeFile(.{ .sub_path = snapshot_path, .data = snapshot_text }) catch |e| {
                        summary.failed += 1;
                        testStatus("FAIL", path, e);
                        return;
                    };
                } else {
                    summary.failed += 1;
                    testStatusMsg("FAIL", path, "snapshot mismatch");
                    return;
                }
            }
            summary.passed += 1;
            testStatusMsg("PASS", path, "");
            return;
        } else if (update_snapshots) {
            std.fs.cwd().writeFile(.{ .sub_path = snapshot_path, .data = snapshot_text }) catch |e| {
                summary.failed += 1;
                testStatus("FAIL", path, e);
                return;
            };
            summary.passed += 1;
            testStatusMsg("PASS", path, "");
            return;
        }
    }

    if (term != .Exited) {
        summary.failed += 1;
        testStatusMsg("FAIL", path, "abnormal termination");
        return;
    }

    if (@as(i32, term.Exited) != expected_exit) {
        summary.failed += 1;
        var msg_buf: [96]u8 = undefined;
        const msg = std.fmt.bufPrint(&msg_buf, "exit {d} (expected {d})", .{ term.Exited, expected_exit }) catch "exit code mismatch";
        testStatusMsg("FAIL", path, msg);
        return;
    }

    if (expected_stdout) |exp| {
        if (!std.mem.eql(u8, exp, actual_stdout)) {
            summary.failed += 1;
            testStatusMsg("FAIL", path, "stdout mismatch");
            return;
        }
    }

    if (expected_stderr) |exp| {
        if (!std.mem.eql(u8, exp, actual_stderr)) {
            summary.failed += 1;
            testStatusMsg("FAIL", path, "stderr mismatch");
            return;
        }
    }

    summary.passed += 1;
    testStatusMsg("PASS", path, "");
}

fn expectationPath(path: []const u8, suffix: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const stem = if (std.mem.endsWith(u8, path, ".w")) path[0 .. path.len - 2] else path;
    return std.fmt.allocPrint(allocator, "{s}.{s}", .{ stem, suffix });
}

fn loadExpectedOutput(path: []const u8, allocator: std.mem.Allocator, suffix: []const u8) !?[]u8 {
    const exp_path = try expectationPath(path, suffix, allocator);
    defer allocator.free(exp_path);

    return std.fs.cwd().readFileAlloc(allocator, exp_path, 64 * 1024) catch |e| switch (e) {
        error.FileNotFound => null,
        else => return e,
    };
}

fn loadExpectedExit(path: []const u8, allocator: std.mem.Allocator) !i32 {
    const maybe_buf = try loadExpectedOutput(path, allocator, "exit");
    defer if (maybe_buf) |buf| allocator.free(buf);

    if (maybe_buf == null) return 0;
    const raw = maybe_buf.?;
    const trimmed = std.mem.trim(u8, raw, " \t\r\n");
    if (trimmed.len == 0) return 0;
    return std.fmt.parseInt(i32, trimmed, 10) catch error.InvalidExpectedExit;
}

fn formatSnapshot(term: std.process.Child.Term, stdout_data: []const u8, stderr_data: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var exit_code: i32 = -1;
    if (term == .Exited) exit_code = term.Exited;
    return std.fmt.allocPrint(
        allocator,
        "exit: {d}\nstdout:\n{s}\nstderr:\n{s}\n",
        .{ exit_code, stdout_data, stderr_data },
    );
}

fn sourceHasMainFn(source: []const u8) bool {
    // Also accept @[entry] annotation as an alternative entry point.
    if (std.mem.indexOf(u8, source, "@[entry]") != null) return true;

    var search_from: usize = 0;
    while (std.mem.indexOfPos(u8, source, search_from, "fn main")) |idx| {
        // Reject embedded identifiers like `myfn main`.
        if (idx > 0) {
            const prev = source[idx - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') {
                search_from = idx + 1;
                continue;
            }
        }

        var i = idx + "fn main".len;
        while (i < source.len and (source[i] == ' ' or source[i] == '\t')) : (i += 1) {}
        if (i >= source.len) return true;

        // Supports:
        //   fn main(...)
        //   fn main -> i32:
        //   fn main:
        //   fn main = ...
        const next = source[i];
        if (next == '(' or next == '-' or next == ':' or next == '=') return true;

        search_from = idx + 1;
    }

    return false;
}

fn testStatus(label: []const u8, path: []const u8, err: anytype) void {
    var buf: [4096]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    w.interface.print("{s} {s} ({})\n", .{ label, path, err }) catch {};
    w.interface.flush() catch {};
}

fn testStatusMsg(label: []const u8, path: []const u8, msg: []const u8) void {
    var buf: [4096]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    if (msg.len == 0) {
        w.interface.print("{s} {s}\n", .{ label, path }) catch {};
    } else {
        w.interface.print("{s} {s} ({s})\n", .{ label, path, msg }) catch {};
    }
    w.interface.flush() catch {};
}

fn printTestSummary(summary: *const TestSummary) void {
    var buf: [4096]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    w.interface.print(
        "\nSummary: {d} passed, {d} failed, {d} skipped\n",
        .{ summary.passed, summary.failed, summary.skipped },
    ) catch {};
    w.interface.flush() catch {};
}

fn emitCheckDumps(
    driver: *Driver,
    module: *const Ast.Module,
    source_path: []const u8,
    options: CheckCommandOptions,
    allocator: std.mem.Allocator,
) !void {
    var selected: [4]DumpArtifact = undefined;
    var selected_count: usize = 0;
    if (options.dump_tokens) {
        selected[selected_count] = .tokens;
        selected_count += 1;
    }
    if (options.dump_ast) {
        selected[selected_count] = .ast;
        selected_count += 1;
    }
    if (options.dump_typed) {
        selected[selected_count] = .typed;
        selected_count += 1;
    }
    if (options.dump_llvm_ir) {
        selected[selected_count] = .llvm;
        selected_count += 1;
    }
    if (selected_count == 0) return;

    if (options.dump_dir) |dir| {
        if (std.fs.path.isAbsolute(dir)) {
            std.fs.makeDirAbsolute(dir) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        } else {
            try std.fs.cwd().makePath(dir);
        }
    }

    var stdout_buf: [16384]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    for (selected[0..selected_count], 0..) |artifact, idx| {
        const dump_text = try collectDumpArtifact(driver, module, source_path, artifact, allocator, options.deterministic);
        defer allocator.free(dump_text);

        if (options.dump_out) |out_path| {
            try writeTextFile(out_path, dump_text);
            continue;
        }
        if (options.dump_dir) |dir_path| {
            const file_name = try std.fmt.allocPrint(allocator, "{s}/{s}.{s}.dump", .{
                dir_path,
                sourceStem(source_path),
                dumpArtifactSuffix(artifact),
            });
            defer allocator.free(file_name);
            try writeTextFile(file_name, dump_text);
            continue;
        }

        if (selected_count > 1) {
            try stdout_writer.interface.print("== {s} ==\n", .{dumpArtifactHeader(artifact)});
        }
        try stdout_writer.interface.writeAll(dump_text);
        if (selected_count > 1 and idx + 1 < selected_count) {
            if (dump_text.len == 0 or dump_text[dump_text.len - 1] != '\n') {
                try stdout_writer.interface.writeAll("\n");
            }
            try stdout_writer.interface.writeAll("\n");
        }
    }
    try stdout_writer.interface.flush();
}

fn collectDumpArtifact(
    driver: *Driver,
    module: *const Ast.Module,
    source_path: []const u8,
    artifact: DumpArtifact,
    allocator: std.mem.Allocator,
    deterministic: bool,
) ![]u8 {
    switch (artifact) {
        .tokens => return collectTokensDump(source_path, allocator, deterministic),
        .ast => {
            var out: std.ArrayList(u8) = .empty;
            errdefer out.deinit(allocator);
            try driver.writeAst(module, out.writer(allocator), true);
            return out.toOwnedSlice(allocator);
        },
        .typed => {
            var out: std.ArrayList(u8) = .empty;
            errdefer out.deinit(allocator);
            const ok = try driver.writeTyped(module, out.writer(allocator));
            if (!ok) return error.DumpFailed;
            return out.toOwnedSlice(allocator);
        },
        .llvm => {
            var out: std.ArrayList(u8) = .empty;
            errdefer out.deinit(allocator);
            const ok = try driver.writeIR(module, out.writer(allocator));
            if (!ok) return error.DumpFailed;
            return out.toOwnedSlice(allocator);
        },
    }
}

fn dumpArtifactHeader(artifact: DumpArtifact) []const u8 {
    return switch (artifact) {
        .tokens => "TOKENS",
        .ast => "AST",
        .typed => "TYPED",
        .llvm => "LLVM",
    };
}

fn dumpArtifactSuffix(artifact: DumpArtifact) []const u8 {
    return switch (artifact) {
        .tokens => "tokens",
        .ast => "ast",
        .typed => "typed",
        .llvm => "llvm",
    };
}

fn writeTextFile(path: []const u8, data: []const u8) !void {
    if (std.fs.path.isAbsolute(path)) {
        var file = try std.fs.createFileAbsolute(path, .{ .truncate = true });
        defer file.close();
        try file.writeAll(data);
        return;
    }
    try std.fs.cwd().writeFile(.{ .sub_path = path, .data = data });
}

fn dumpTokens(path: []const u8, allocator: std.mem.Allocator, deterministic: bool) !void {
    const out = try collectTokensDump(path, allocator, deterministic);
    defer allocator.free(out);

    var buf: [8192]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    try w.interface.writeAll(out);
    try w.interface.flush();
}

fn collectTokensDump(path: []const u8, allocator: std.mem.Allocator, deterministic: bool) ![]u8 {
    var source = try Source.fromFile(path, 0, allocator);
    defer source.deinit();

    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    var lexer = Lexer.init(source.text, 0, &diags);
    var tokens = try lexer.tokenize(allocator);
    defer tokens.deinit();

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    const writer = out.writer(allocator);
    if (deterministic) {
        try writer.print("tokens file={s} count={d}\n", .{ path, tokens.len() });
        for (0..tokens.len()) |i| {
            const tok = tokens.get(i);
            const text = source.text[tok.span.start..tok.span.end];
            const escaped = try escapeDumpLexeme(text, allocator);
            defer allocator.free(escaped);
            try writer.print("tok[{d}] tag={s} span={d}..{d} lex=\"{s}\"\n", .{
                i,
                tok.tag.name(),
                tok.span.start,
                tok.span.end,
                escaped,
            });
        }
    } else {
        for (0..tokens.len()) |i| {
            const tok = tokens.get(i);
            const text = source.text[tok.span.start..tok.span.end];
            try writer.print("{s:16} |{s}|\n", .{ tok.tag.name(), text });
        }
    }
    return out.toOwnedSlice(allocator);
}

fn escapeDumpLexeme(text: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    for (text) |ch| {
        switch (ch) {
            '\\' => try out.appendSlice(allocator, "\\\\"),
            '"' => try out.appendSlice(allocator, "\\\""),
            '\n' => try out.appendSlice(allocator, "\\n"),
            '\r' => try out.appendSlice(allocator, "\\r"),
            '\t' => try out.appendSlice(allocator, "\\t"),
            else => try out.append(allocator, ch),
        }
    }
    return out.toOwnedSlice(allocator);
}

// ── Tests ────────────────────────────────────────────────────────
comptime {
    _ = @import("Span.zig");
    _ = @import("Source.zig");
    _ = @import("InternPool.zig");
    _ = @import("Token.zig");
    _ = @import("Lexer.zig");
    _ = @import("Ast.zig");
    _ = @import("Types.zig");
    _ = @import("Parse.zig");
    _ = @import("Check.zig");
    _ = @import("Mir.zig");
    _ = @import("Parser.zig");
    _ = @import("render.zig");
    _ = @import("Diagnostic.zig");
    _ = @import("Diag.zig");
    _ = @import("Scaffold.zig");
    _ = @import("Driver.zig");
    _ = @import("Codegen.zig");
    _ = @import("Sema.zig");
}
