//! CLI entry point for the With compiler.
//!
//! Usage:
//!   with run <file.w>     Compile and run a With source file
//!   with build <file.w>   Compile a With source file
//!   with ast <file.w>     Parse and dump the AST (debug)
//!   with tokens <file.w>  Lex and dump tokens (debug)

const std = @import("std");
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

    if (std.mem.eql(u8, command, "run") or std.mem.eql(u8, command, "build")) {
        if (args.len < 3) {
            var buf: [4096]u8 = undefined;
            var w = std.fs.File.stderr().writer(&buf);
            w.interface.print("error: '{s}' requires a source file argument\n", .{command}) catch {};
            w.interface.flush() catch {};
            printUsage();
            std.process.exit(1);
        }
        const file = args[2];
        var driver = Driver.init(allocator);
        defer driver.deinit();

        const module = try driver.compileFile(file);
        if (module) |m| {
            try driver.dumpAst(&m);
            // TODO: type check, codegen, link, (run)
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

fn printUsage() void {
    var buf: [4096]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    w.interface.writeAll(
        \\Usage: with <command> [options]
        \\
        \\Commands:
        \\  run <file.w>      Compile and run a With source file
        \\  build <file.w>    Compile a With source file to a binary
        \\  ast <file.w>      Parse and dump the AST (debug)
        \\  tokens <file.w>   Lex and dump tokens (debug)
        \\  version           Print compiler version
        \\  help              Show this message
        \\
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
    _ = @import("Parser.zig");
    _ = @import("render.zig");
    _ = @import("Diagnostic.zig");
    _ = @import("Driver.zig");
}
