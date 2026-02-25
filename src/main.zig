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

    if (std.mem.eql(u8, command, "build")) {
        if (args.len < 3) {
            stderrPrint("error: 'build' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
        }
        var driver = Driver.init(allocator);
        defer driver.deinit();

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

        const bin_path = try driver.buildBinary(args[2]);
        if (bin_path) |p| {
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
        } else {
            std.process.exit(1);
        }
    } else if (std.mem.eql(u8, command, "fmt")) {
        if (args.len < 3) {
            stderrPrint("error: 'fmt' requires a source file argument\n");
            printUsage();
            std.process.exit(1);
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
        \\  fmt <file.w>      Format a source file (to stdout)
        \\  repl              Interactive REPL
        \\  lsp               Start language server (LSP over stdio)
        \\  doc <file.w>      Generate documentation (markdown)
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
                \\  :clear       Clear accumulated bindings
                \\  :help        Show this help
                \\
                \\Enter let/var bindings (persisted across lines) or expressions.
                \\Expressions are automatically printed with println.
                \\
            );
            try out.interface.flush();
            continue;
        }

        // Determine if this is a binding (let/var/fn) or an expression
        const trimmed = std.mem.trimLeft(u8, line, " \t");
        const is_binding = std.mem.startsWith(u8, trimmed, "let ") or
            std.mem.startsWith(u8, trimmed, "var ") or
            std.mem.startsWith(u8, trimmed, "fn ");

        // Build the source
        var src: std.ArrayList(u8) = .empty;
        defer src.deinit(allocator);
        try src.appendSlice(allocator, "fn main() -> i32 =\n");
        for (lines.items) |prev| {
            try src.appendSlice(allocator, "    ");
            try src.appendSlice(allocator, prev);
            try src.appendSlice(allocator, "\n");
        }
        if (is_binding) {
            try src.appendSlice(allocator, "    ");
            try src.appendSlice(allocator, line);
            try src.appendSlice(allocator, "\n    0\n");
        } else {
            // Wrap expression in println
            try src.appendSlice(allocator, "    println(");
            try src.appendSlice(allocator, line);
            try src.appendSlice(allocator, ")\n    0\n");
        }

        // Write temp file
        const tmp_path = "/tmp/_with_repl.w";
        {
            const f = std.fs.createFileAbsolute(tmp_path, .{}) catch {
                try writer_iface.writeAll("error: could not create temp file\n");
                try out.interface.flush();
                continue;
            };
            defer f.close();
            f.writeAll(src.items) catch {};
        }

        // Compile
        var driver = Driver.init(allocator);
        defer driver.deinit();

        const bin_path = try driver.buildBinary(tmp_path);
        if (bin_path == null) {
            // Compilation failed — try without println wrapper if it was an expression
            if (!is_binding) {
                src.clearRetainingCapacity();
                try src.appendSlice(allocator, "fn main() -> i32 =\n");
                for (lines.items) |prev| {
                    try src.appendSlice(allocator, "    ");
                    try src.appendSlice(allocator, prev);
                    try src.appendSlice(allocator, "\n");
                }
                try src.appendSlice(allocator, "    ");
                try src.appendSlice(allocator, line);
                try src.appendSlice(allocator, "\n    0\n");
                {
                    const f = std.fs.createFileAbsolute(tmp_path, .{}) catch continue;
                    defer f.close();
                    f.writeAll(src.items) catch {};
                }
                var driver2 = Driver.init(allocator);
                defer driver2.deinit();
                if (try driver2.buildBinary(tmp_path)) |bp| {
                    var path_buf2: [4096]u8 = undefined;
                    if (bp.len < path_buf2.len) {
                        @memcpy(path_buf2[0..bp.len], bp);
                        path_buf2[bp.len] = 0;
                        _ = c.system(&path_buf2);
                    }
                }
            }
            continue;
        }

        // Execute the compiled binary via system()
        {
            const bp = bin_path.?;
            // Build a null-terminated path for system()
            var path_buf: [4096]u8 = undefined;
            if (bp.len < path_buf.len) {
                @memcpy(path_buf[0..bp.len], bp);
                path_buf[bp.len] = 0;
                _ = c.system(&path_buf);
            }
        }

        // If it was a binding, save it for future lines
        if (is_binding) {
            const saved = try allocator.dupe(u8, line);
            try lines.append(allocator, saved);
        }
    }

    try writer_iface.writeAll("\nGoodbye!\n");
    try out.interface.flush();
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

    // Walk declarations
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |f| {
                // Skip private functions and main
                const name = pool.resolve(f.name);
                if (std.mem.eql(u8, name, "main")) continue;

                // Extract doc comment
                const doc = extractDocComment(source_text, decl.span.start);
                if (doc.len > 0 and std.mem.indexOf(u8, doc, "//") != null) {
                    try w.print("{s}\n", .{doc});
                }

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
                if (doc.len > 0 and std.mem.indexOf(u8, doc, "//") != null) {
                    try w.print("{s}\n", .{doc});
                }

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
                }
            },
            .trait_decl => |td| {
                const name = pool.resolve(td.name);
                const doc = extractDocComment(source_text, decl.span.start);
                if (doc.len > 0 and std.mem.indexOf(u8, doc, "//") != null) {
                    try w.print("{s}\n", .{doc});
                }
                try w.print("### trait `{s}`\n\n", .{name});
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
    _ = @import("Parser.zig");
    _ = @import("render.zig");
    _ = @import("Diagnostic.zig");
    _ = @import("Driver.zig");
    _ = @import("Codegen.zig");
    _ = @import("Sema.zig");
}
