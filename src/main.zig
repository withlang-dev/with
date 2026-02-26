//! CLI entry point for the With compiler.
//!
//! Usage:
//!   with run <file.w>     Compile and run a With source file
//!   with build <file.w>   Compile a With source file
//!   with ast <file.w>     Parse and dump the AST (debug)
//!   with tokens <file.w>  Lex and dump tokens (debug)

const std = @import("std");
const c = @cImport(@cInclude("stdlib.h"));
const Driver = @import("Driver.zig");
const Source = @import("Source.zig");
const Lexer = @import("Lexer.zig");
const Token = @import("Token.zig");
const Diagnostic = @import("Diagnostic.zig");
const Migrate = @import("Migrate.zig");

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

    // Parse -O flag from remaining args.
    var opt_level: u8 = 0;
    for (args) |arg| {
        if (arg.len == 3 and arg[0] == '-' and arg[1] == 'O') {
            opt_level = arg[2] - '0';
            if (opt_level > 3) opt_level = 2;
        }
    }

    if (std.mem.eql(u8, command, "build")) {
        if (args.len < 3) {
            stderrPrint("error: 'build' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        }
        var driver = Driver.init(allocator);
        defer driver.deinit();
        driver.opt_level = opt_level;

        const bin_path = try driver.buildBinary(args[2]);
        if (bin_path) |p| {
            var buf: [4096]u8 = undefined;
            var w = std.fs.File.stderr().writer(&buf);
            w.interface.print("compiled: {s}\n", .{p}) catch {};
            w.interface.flush() catch {};
            driver.printWarnings();
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "run")) {
        if (args.len < 3) {
            stderrPrint("error: 'run' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        }
        var driver = Driver.init(allocator);
        defer driver.deinit();
        driver.opt_level = opt_level;

        const bin_path = try driver.buildBinary(args[2]);
        if (bin_path) |p| {
            driver.printWarnings();
            // Execute the binary.
            var child = std.process.Child.init(&.{p}, allocator);
            _ = child.spawn() catch |e| {
                var buf: [4096]u8 = undefined;
                var w = std.fs.File.stderr().writer(&buf);
                w.interface.print("error: failed to spawn binary: {}\n", .{e}) catch {};
                w.interface.flush() catch {};
                std.process.exit(1);
            };
            const term = child.wait() catch |e| {
                var buf: [4096]u8 = undefined;
                var w = std.fs.File.stderr().writer(&buf);
                w.interface.print("error: failed to execute binary: {}\n", .{e}) catch {};
                w.interface.flush() catch {};
                std.process.exit(1);
            };
            if (term == .Exited) {
                std.process.exit(term.Exited);
            }
            std.process.exit(1);
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "ir")) {
        if (args.len < 3) {
            stderrPrint("error: 'ir' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        }
        var driver = Driver.init(allocator);
        defer driver.deinit();

        const module = try driver.compileFile(args[2]);
        if (module) |m| {
            const ok = try driver.emitIR(&m);
            if (!ok) std.process.exit(1);
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "ast")) {
        if (args.len < 3) {
            var buf: [4096]u8 = undefined;
            var w = std.fs.File.stderr().writer(&buf);
            w.interface.writeAll("error: 'ast' requires a source file argument\n") catch {};
            w.interface.flush() catch {};
            std.process.exit(1);
        }
        var driver = Driver.init(allocator);
        defer driver.deinit();

        const module = try driver.compileFile(args[2]);
        if (module) |m| {
            try driver.dumpAst(&m);
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "check")) {
        if (args.len < 3) {
            stderrPrint("error: 'check' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        }
        var driver = Driver.init(allocator);
        defer driver.deinit();

        const module = try driver.compileFile(args[2]);
        if (module) |_| {
            stderrPrint("ok\n");
            driver.printWarnings();
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "test")) {
        var target: []const u8 = "test/cases";
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
        if (args.len < 3) {
            stderrPrint("error: 'fmt' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        }
        const source_text = std.fs.cwd().readFileAlloc(allocator, args[2], 2 * 1024 * 1024) catch {
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

        const module = try driver.compileFile(args[2]);
        if (module) |m| {
            // Render the AST back to formatted source.
            try driver.dumpAst(&m);
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "tokens")) {
        if (args.len < 3) {
            var buf: [4096]u8 = undefined;
            var w = std.fs.File.stderr().writer(&buf);
            w.interface.writeAll("error: 'tokens' requires a source file argument\n") catch {};
            w.interface.flush() catch {};
            std.process.exit(1);
        }
        try dumpTokens(args[2], allocator);
    } else if (std.mem.eql(u8, command, "help") or std.mem.eql(u8, command, "--help") or std.mem.eql(u8, command, "-h")) {
        printUsage();
    } else if (std.mem.eql(u8, command, "repl")) {
        try runRepl(allocator);
    } else if (std.mem.eql(u8, command, "doc")) {
        if (args.len < 3) {
            stderrPrint("error: 'doc' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        }
        try generateDoc(args[2], allocator);
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
        \\  build <file.w>    Compile a With source file to a binary
        \\  run <file.w>      Compile and run a With source file
        \\  check <file.w>    Parse and type-check a source file
        \\  test [path]       Run .w test cases (default: test/cases)
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

    var lines: std.ArrayList([]const u8) = .empty;
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit(allocator);
    }

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
            for (lines.items) |l| allocator.free(l);
            lines.clearRetainingCapacity();
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
        const is_binding = std.mem.startsWith(u8, trimmed, "let ") or
            std.mem.startsWith(u8, trimmed, "var ") or
            std.mem.startsWith(u8, trimmed, "fn ") or
            std.mem.startsWith(u8, trimmed, "type ") or
            std.mem.startsWith(u8, trimmed, "use ") or
            std.mem.startsWith(u8, trimmed, "c_import(");
        const is_stateful_stmt = isLikelyStatefulStatement(trimmed);

        // For declarations and likely stateful statements, execute as a statement
        // first so side effects are persisted consistently.
        if (is_binding or is_stateful_stmt) {
            if (try executeReplLine(allocator, lines.items, line, .statement)) {
                const saved = try allocator.dupe(u8, line);
                try lines.append(allocator, saved);
                continue;
            }
            // Bindings are never treated as printable expressions.
            if (is_binding) continue;
        }

        // Try expression mode (println wrapper) for query-like lines.
        if (try executeReplLine(allocator, lines.items, line, .expression)) {
            continue;
        }

        // Fallback to statement mode for non-printable expressions.
        if (try executeReplLine(allocator, lines.items, line, .statement)) {
            if (isLikelyStatefulStatement(trimmed)) {
                const saved = try allocator.dupe(u8, line);
                try lines.append(allocator, saved);
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

fn executeReplLine(
    allocator: std.mem.Allocator,
    prior_lines: []const []const u8,
    line: []const u8,
    mode: ReplExecMode,
) !bool {
    var src: std.ArrayList(u8) = .empty;
    defer src.deinit(allocator);

    try src.appendSlice(allocator, "fn main() -> i32 =\n");
    for (prior_lines) |prev| {
        try src.appendSlice(allocator, "    ");
        try src.appendSlice(allocator, prev);
        try src.appendSlice(allocator, "\n");
    }

    if (mode == .expression) {
        try src.appendSlice(allocator, "    println(");
        try src.appendSlice(allocator, line);
        try src.appendSlice(allocator, ")\n    0\n");
    } else {
        try src.appendSlice(allocator, "    ");
        try src.appendSlice(allocator, line);
        try src.appendSlice(allocator, "\n    0\n");
    }

    const tmp_path = "/tmp/_with_repl.w";
    {
        const f = std.fs.createFileAbsolute(tmp_path, .{}) catch return false;
        defer f.close();
        f.writeAll(src.items) catch return false;
    }

    var driver = Driver.init(allocator);
    defer driver.deinit();

    const bin_path = try driver.buildBinary(tmp_path);
    if (bin_path == null) return false;

    const bp = bin_path.?;
    var path_buf: [4096]u8 = undefined;
    if (bp.len >= path_buf.len) return false;
    @memcpy(path_buf[0..bp.len], bp);
    path_buf[bp.len] = 0;
    _ = c.system(&path_buf);
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

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".w")) continue;
        const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ target, entry.name });
        defer allocator.free(path);
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

    if (!sourceHasMainFn(source)) {
        summary.skipped += 1;
        testStatusMsg("SKIP", path, "no main");
        return;
    }

    var driver = Driver.init(allocator);
    defer driver.deinit();

    const bin_path_opt = try driver.buildBinary(path);
    if (bin_path_opt == null) {
        summary.failed += 1;
        testStatusMsg("FAIL", path, "compile/link");
        return;
    }
    const bin_path = bin_path_opt.?;
    const expected_exit = loadExpectedExit(path, allocator) catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };
    const expected_stdout = loadExpectedOutput(path, allocator, "stdout") catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };
    defer if (expected_stdout) |buf| allocator.free(buf);
    const expected_stderr = loadExpectedOutput(path, allocator, "stderr") catch |e| {
        summary.failed += 1;
        testStatus("FAIL", path, e);
        return;
    };
    defer if (expected_stderr) |buf| allocator.free(buf);

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
    return std.mem.indexOf(u8, source, "fn main(") != null;
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

fn dumpTokens(path: []const u8, allocator: std.mem.Allocator) !void {
    var source = try Source.fromFile(path, 0, allocator);
    defer source.deinit();

    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    var lexer = Lexer.init(source.text, 0, &diags);
    var tokens = try lexer.tokenize(allocator);
    defer tokens.deinit();

    var buf: [8192]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    const writer = &w.interface;
    for (0..tokens.len()) |i| {
        const tok = tokens.get(i);
        const text = source.text[tok.span.start..tok.span.end];
        try writer.print("{s:16} |{s}|\n", .{ tok.tag.name(), text });
    }
    try w.interface.flush();
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
