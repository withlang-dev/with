const std = @import("std");

pub const Lang = enum {
    rust,
    zig,
    swift,
};

pub const Mode = enum {
    write,
    check,
    diff,
};

pub const RunError = error{
    UnsupportedLanguage,
    InvalidPath,
    NoInputFiles,
    OutOfMemory,
} || std.fs.Dir.OpenError || std.fs.Dir.StatFileError || std.fs.File.OpenError || std.fs.File.WriteError || std.fs.File.ReadError;

const Summary = struct {
    files_scanned: usize = 0,
    files_matched: usize = 0,
    files_changed: usize = 0,
    manual_fixups: usize = 0,
};

const TransformResult = struct {
    text: []u8,
    manual_fixups: usize,
};

pub fn parseLang(value: []const u8) ?Lang {
    if (std.mem.eql(u8, value, "rust")) return .rust;
    if (std.mem.eql(u8, value, "zig")) return .zig;
    if (std.mem.eql(u8, value, "swift")) return .swift;
    return null;
}

pub fn run(
    allocator: std.mem.Allocator,
    lang_raw: []const u8,
    target_path: []const u8,
    mode: Mode,
) RunError!u8 {
    const lang = parseLang(lang_raw) orelse return error.UnsupportedLanguage;

    var summary: Summary = .{};
    const stat = std.fs.cwd().statFile(target_path) catch return error.InvalidPath;

    switch (stat.kind) {
        .file => try processOneFile(allocator, lang, target_path, mode, &summary),
        .directory => try walkDirectory(allocator, lang, target_path, mode, &summary),
        else => return error.InvalidPath,
    }

    if (summary.files_matched == 0) return error.NoInputFiles;

    {
        var msg_buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&msg_buf, "migrate summary: scanned={d} matched={d} changed={d} manual_fixups={d}\n", .{
            summary.files_scanned,
            summary.files_matched,
            summary.files_changed,
            summary.manual_fixups,
        }) catch "";
        std.fs.File.stdout().writeAll(msg) catch {};
    }

    if (mode == .check and summary.files_changed > 0) return 1;
    return 0;
}

fn walkDirectory(
    allocator: std.mem.Allocator,
    lang: Lang,
    target_path: []const u8,
    mode: Mode,
    summary: *Summary,
) RunError!void {
    var dir = std.fs.cwd().openDir(target_path, .{ .iterate = true }) catch return error.InvalidPath;
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        const full_path = try std.fs.path.join(allocator, &.{ target_path, entry.path });
        defer allocator.free(full_path);
        try processOneFile(allocator, lang, full_path, mode, summary);
    }
}

fn processOneFile(
    allocator: std.mem.Allocator,
    lang: Lang,
    file_path: []const u8,
    mode: Mode,
    summary: *Summary,
) RunError!void {
    summary.files_scanned += 1;

    const src_ext = sourceExt(lang);
    if (!std.mem.endsWith(u8, file_path, src_ext)) return;
    summary.files_matched += 1;

    const src_text = try std.fs.cwd().readFileAlloc(allocator, file_path, 4 * 1024 * 1024);
    defer allocator.free(src_text);

    const transformed = try transform(allocator, lang, src_text);
    defer allocator.free(transformed.text);

    summary.manual_fixups += transformed.manual_fixups;

    const out_path = try std.fmt.allocPrint(allocator, "{s}.w", .{file_path[0 .. file_path.len - src_ext.len]});
    defer allocator.free(out_path);

    switch (mode) {
        .write => {
            const existing = std.fs.cwd().readFileAlloc(allocator, out_path, 4 * 1024 * 1024) catch null;
            defer if (existing) |buf| allocator.free(buf);
            const changed = existing == null or !std.mem.eql(u8, existing.?, transformed.text);
            if (changed) {
                try writeFile(out_path, transformed.text);
                summary.files_changed += 1;
                printLine("wrote {s}\n", .{out_path});
            }
        },
        .check => {
            const existing = std.fs.cwd().readFileAlloc(allocator, out_path, 4 * 1024 * 1024) catch null;
            defer if (existing) |buf| allocator.free(buf);
            const changed = existing == null or !std.mem.eql(u8, existing.?, transformed.text);
            if (changed) {
                summary.files_changed += 1;
                printLine("would migrate {s} -> {s}\n", .{ file_path, out_path });
            }
        },
        .diff => {
            if (!std.mem.eql(u8, src_text, transformed.text)) {
                summary.files_changed += 1;
                printDiff(file_path, out_path, src_text, transformed.text);
            }
        },
    }
}

fn printLine(comptime fmt: []const u8, args: anytype) void {
    var msg_buf: [4096]u8 = undefined;
    const msg = std.fmt.bufPrint(&msg_buf, fmt, args) catch return;
    std.fs.File.stdout().writeAll(msg) catch {};
}

fn printDiff(path_before: []const u8, path_after: []const u8, before: []const u8, after: []const u8) void {
    var header_buf: [8192]u8 = undefined;
    const header = std.fmt.bufPrint(&header_buf, "--- {s}\n+++ {s}\n@@\n", .{ path_before, path_after }) catch "";
    std.fs.File.stdout().writeAll(header) catch {};

    var before_it = std.mem.splitScalar(u8, before, '\n');
    var after_it = std.mem.splitScalar(u8, after, '\n');
    while (true) {
        const b = before_it.next();
        const a = after_it.next();
        if (b == null and a == null) break;

        if (b != null and a != null and std.mem.eql(u8, b.?, a.?)) {
            continue;
        }
        if (b) |line| printLine("-{s}\n", .{line});
        if (a) |line| printLine("+{s}\n", .{line});
    }
}

fn writeFile(path: []const u8, text: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(text);
}

fn sourceExt(lang: Lang) []const u8 {
    return switch (lang) {
        .rust => ".rs",
        .zig => ".zig",
        .swift => ".swift",
    };
}

fn transform(allocator: std.mem.Allocator, lang: Lang, text: []const u8) !TransformResult {
    return switch (lang) {
        .rust => transformRust(allocator, text),
        .zig => transformZig(allocator, text),
        .swift => transformSwift(allocator, text),
    };
}

fn transformRust(allocator: std.mem.Allocator, text: []const u8) !TransformResult {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var manual_fixups: usize = 0;
    manual_fixups += countNeedle(text, "Pin<");
    manual_fixups += countNeedle(text, "FnMut");
    manual_fixups += countNeedle(text, "FnOnce");
    manual_fixups += countNeedle(text, "proc_macro");

    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |raw_line| {
        var line = raw_line;
        line = std.mem.trimRight(u8, line, " \t\r");

        line = try replaceOwnedInline(allocator, line, "#[", "@[");
        defer allocator.free(line);

        var line_buf = std.ArrayList(u8).empty;
        defer line_buf.deinit(allocator);
        try line_buf.appendSlice(allocator, line);

        try replaceInArrayList(allocator, &line_buf, "let mut ", "var ");
        try replaceInArrayList(allocator, &line_buf, "Ok(())", "Ok()");
        try replaceInArrayList(allocator, &line_buf, "::", ".");
        try replaceInArrayList(allocator, &line_buf, ".to_string()", "");

        const collapsed = try rewriteStringFrom(allocator, line_buf.items);
        defer allocator.free(collapsed);
        const rewritten_println = try rewriteRustPrintln(allocator, collapsed);
        defer allocator.free(rewritten_println);
        const no_lifetimes = try stripSimpleRustLifetimes(allocator, rewritten_println);
        defer allocator.free(no_lifetimes);

        if (std.mem.endsWith(u8, no_lifetimes, ";")) {
            try out.appendSlice(allocator, no_lifetimes[0 .. no_lifetimes.len - 1]);
        } else {
            try out.appendSlice(allocator, no_lifetimes);
        }
        try out.append(allocator, '\n');
    }

    const braced = try bracesToIndent(allocator, out.items);
    return .{
        .text = braced,
        .manual_fixups = manual_fixups,
    };
}

fn transformZig(allocator: std.mem.Allocator, text: []const u8) !TransformResult {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var manual_fixups: usize = 0;
    manual_fixups += countNeedle(text, "undefined");
    manual_fixups += countNeedle(text, "errdefer");
    manual_fixups += countNeedle(text, "allocator");

    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |raw_line| {
        var line = try allocator.dupe(u8, std.mem.trimRight(u8, raw_line, " \t\r"));
        defer allocator.free(line);

        const trimmed = std.mem.trimLeft(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, "const ")) {
            const idx = std.mem.indexOf(u8, line, "const ") orelse 0;
            const replaced = try std.fmt.allocPrint(allocator, "{s}let {s}", .{
                line[0..idx],
                line[idx + "const ".len ..],
            });
            allocator.free(line);
            line = replaced;
        }

        const line1 = try rewriteZigTry(allocator, line);
        defer allocator.free(line1);
        const line2 = try rewriteAtAs(allocator, line1);
        defer allocator.free(line2);
        const line3 = try rewriteSimpleZigFn(allocator, line2);
        defer allocator.free(line3);

        const line4 = try replaceOwnedInline(allocator, line3, "orelse", "??");
        defer allocator.free(line4);
        const line5 = try replaceOwnedInline(allocator, line4, "null", "None");
        defer allocator.free(line5);

        if (std.mem.endsWith(u8, line5, ";")) {
            try out.appendSlice(allocator, line5[0 .. line5.len - 1]);
        } else {
            try out.appendSlice(allocator, line5);
        }
        try out.append(allocator, '\n');
    }

    const braced = try bracesToIndent(allocator, out.items);
    return .{
        .text = braced,
        .manual_fixups = manual_fixups,
    };
}

fn transformSwift(allocator: std.mem.Allocator, text: []const u8) !TransformResult {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var manual_fixups: usize = 0;
    manual_fixups += countNeedle(text, "weak ");
    manual_fixups += countNeedle(text, "unowned ");
    manual_fixups += countNeedle(text, "@MainActor");
    manual_fixups += countNeedle(text, "Combine");

    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |raw_line| {
        const trimmed = std.mem.trim(u8, raw_line, " \t\r");
        var line = try allocator.dupe(u8, trimmed);
        defer allocator.free(line);

        try replaceInSliceAlloc(&line, allocator, "func ", "fn ");
        try replaceInSliceAlloc(&line, allocator, "protocol ", "trait ");
        try replaceInSliceAlloc(&line, allocator, "nil", "None");
        try replaceInSliceAlloc(&line, allocator, "try await ", "");
        try replaceInSliceAlloc(&line, allocator, ".await", ".await");

        const guard_line = try rewriteSwiftGuardLet(allocator, line);
        defer allocator.free(guard_line);
        const ext_line = try rewriteSwiftExtension(allocator, guard_line);
        defer allocator.free(ext_line);
        const interp_line = try rewriteSwiftInterpolation(allocator, ext_line);
        defer allocator.free(interp_line);
        const opt_line = try rewriteSwiftOptionals(allocator, interp_line);
        defer allocator.free(opt_line);

        if (std.mem.endsWith(u8, opt_line, ";")) {
            try out.appendSlice(allocator, opt_line[0 .. opt_line.len - 1]);
        } else {
            try out.appendSlice(allocator, opt_line);
        }
        try out.append(allocator, '\n');
    }

    const braced = try bracesToIndent(allocator, out.items);
    return .{
        .text = braced,
        .manual_fixups = manual_fixups,
    };
}

fn rewriteSwiftGuardLet(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    const prefix = "guard let ";
    if (!std.mem.startsWith(u8, line, prefix)) return allocator.dupe(u8, line);
    const else_idx = std.mem.indexOf(u8, line, " else ") orelse return allocator.dupe(u8, line);
    const assign = line[prefix.len..else_idx];
    const eq_idx = std.mem.indexOf(u8, assign, "=") orelse return allocator.dupe(u8, line);
    const name = std.mem.trim(u8, assign[0..eq_idx], " \t");
    const expr = std.mem.trim(u8, assign[eq_idx + 1 ..], " \t");
    return std.fmt.allocPrint(allocator, "let Some({s}) = {s} else return", .{ name, expr });
}

fn rewriteSwiftExtension(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    const prefix = "extension ";
    if (!std.mem.startsWith(u8, line, prefix)) return allocator.dupe(u8, line);
    const rest = line[prefix.len..];
    const colon_idx = std.mem.indexOfScalar(u8, rest, ':') orelse return allocator.dupe(u8, line);
    const type_name = std.mem.trim(u8, rest[0..colon_idx], " \t");
    const trait_name = std.mem.trim(u8, rest[colon_idx + 1 ..], " \t{}");
    if (trait_name.len == 0) return allocator.dupe(u8, line);
    return std.fmt.allocPrint(allocator, "impl {s} for {s}", .{ trait_name, type_name });
}

fn rewriteSwiftInterpolation(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (i + 2 < line.len and line[i] == '\\' and line[i + 1] == '(') {
            i += 2;
            const start = i;
            var depth: usize = 1;
            while (i < line.len and depth > 0) : (i += 1) {
                if (line[i] == '(') depth += 1 else if (line[i] == ')') depth -= 1;
            }
            const expr = std.mem.trim(u8, line[start .. i - 1], " \t");
            try out.append(allocator, '{');
            try out.appendSlice(allocator, expr);
            try out.append(allocator, '}');
            i -= 1;
            continue;
        }
        try out.append(allocator, line[i]);
    }

    return out.toOwnedSlice(allocator);
}

fn rewriteSwiftOptionals(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == ':' and i + 2 < line.len) {
            var j = i + 1;
            while (j < line.len and line[j] == ' ') : (j += 1) {}
            const type_start = j;
            while (j < line.len and (std.ascii.isAlphanumeric(line[j]) or line[j] == '_')) : (j += 1) {}
            if (j < line.len and line[j] == '?') {
                try out.append(allocator, ':');
                try out.appendSlice(allocator, line[i + 1 .. type_start]);
                try out.appendSlice(allocator, "Option[");
                try out.appendSlice(allocator, line[type_start..j]);
                try out.append(allocator, ']');
                i = j;
                continue;
            }
        }
        try out.append(allocator, line[i]);
    }

    return out.toOwnedSlice(allocator);
}

fn rewriteSimpleZigFn(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    const trimmed = std.mem.trim(u8, line, " \t");
    if (!std.mem.startsWith(u8, trimmed, "fn ")) return allocator.dupe(u8, line);
    if (std.mem.indexOf(u8, trimmed, "{") == null) return allocator.dupe(u8, line);
    if (std.mem.indexOf(u8, trimmed, "return ") == null) return allocator.dupe(u8, line);
    if (trimmed[trimmed.len - 1] != '}') return allocator.dupe(u8, line);

    const fn_prefix_end = std.mem.indexOf(u8, trimmed, "{") orelse return allocator.dupe(u8, line);
    const header = std.mem.trimRight(u8, trimmed[0..fn_prefix_end], " \t");
    const body = std.mem.trim(u8, trimmed[fn_prefix_end + 1 .. trimmed.len - 1], " \t");
    if (!std.mem.startsWith(u8, body, "return ")) return allocator.dupe(u8, line);
    var expr = std.mem.trim(u8, body["return ".len..], " \t");
    if (std.mem.endsWith(u8, expr, ";")) expr = expr[0 .. expr.len - 1];

    const close_paren = std.mem.lastIndexOfScalar(u8, header, ')') orelse return allocator.dupe(u8, line);
    const before_ret = std.mem.trimRight(u8, header[0 .. close_paren + 1], " \t");
    const ret_ty = std.mem.trim(u8, header[close_paren + 1 ..], " \t");
    return std.fmt.allocPrint(allocator, "{s} -> {s} = {s}", .{ before_ret, ret_ty, expr });
}

fn rewriteZigTry(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    const idx = std.mem.indexOf(u8, line, "try ") orelse return allocator.dupe(u8, line);
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);
    try out.appendSlice(allocator, line[0..idx]);
    try out.appendSlice(allocator, line[idx + "try ".len ..]);
    var rewritten = try out.toOwnedSlice(allocator);
    if (std.mem.endsWith(u8, rewritten, ";")) {
        const tail = rewritten[0 .. rewritten.len - 1];
        const with_q = try std.fmt.allocPrint(allocator, "{s}?;", .{tail});
        allocator.free(rewritten);
        rewritten = with_q;
    } else if (!std.mem.endsWith(u8, rewritten, "?")) {
        const with_q = try std.fmt.allocPrint(allocator, "{s}?", .{rewritten});
        allocator.free(rewritten);
        rewritten = with_q;
    }
    return rewritten;
}

fn rewriteAtAs(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    const prefix = "@as(";
    const start = std.mem.indexOf(u8, line, prefix) orelse return allocator.dupe(u8, line);
    var i = start + prefix.len;
    const comma = std.mem.indexOfPos(u8, line, i, ",") orelse return allocator.dupe(u8, line);
    const ty = std.mem.trim(u8, line[i..comma], " \t");
    i = comma + 1;
    var depth: usize = 1;
    const expr_start = i;
    while (i < line.len and depth > 0) : (i += 1) {
        if (line[i] == '(') depth += 1 else if (line[i] == ')') depth -= 1;
    }
    if (depth != 0 or i == 0) return allocator.dupe(u8, line);
    const expr = std.mem.trim(u8, line[expr_start .. i - 1], " \t");
    return std.fmt.allocPrint(allocator, "{s}{s} as {s}{s}", .{
        line[0..start],
        expr,
        ty,
        line[i..],
    });
}

fn rewriteStringFrom(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    const pattern = "String.from(";
    const start = std.mem.indexOf(u8, line, pattern) orelse return allocator.dupe(u8, line);
    var i = start + pattern.len;
    const arg_start = i;
    var depth: usize = 1;
    while (i < line.len and depth > 0) : (i += 1) {
        if (line[i] == '(') depth += 1 else if (line[i] == ')') depth -= 1;
    }
    if (depth != 0 or i == 0) return allocator.dupe(u8, line);
    const arg = std.mem.trim(u8, line[arg_start .. i - 1], " \t");
    return std.fmt.allocPrint(allocator, "{s}{s}{s}", .{
        line[0..start],
        arg,
        line[i..],
    });
}

fn rewriteRustPrintln(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    const prefix = "println!(\"{}\",";
    const idx = std.mem.indexOf(u8, line, prefix) orelse return allocator.dupe(u8, line);
    var expr = std.mem.trim(u8, line[idx + prefix.len ..], " \t");
    if (std.mem.endsWith(u8, expr, ");")) expr = expr[0 .. expr.len - 2];
    if (std.mem.endsWith(u8, expr, ")")) expr = expr[0 .. expr.len - 1];
    return std.fmt.allocPrint(allocator, "{s}println(\"{{{s}}}\"){s}", .{
        line[0..idx],
        std.mem.trim(u8, expr, " \t"),
        "",
    });
}

fn stripSimpleRustLifetimes(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == '\'' and i + 1 < line.len and (std.ascii.isAlphabetic(line[i + 1]) or line[i + 1] == '_')) {
            i += 1;
            while (i < line.len and (std.ascii.isAlphanumeric(line[i]) or line[i] == '_')) : (i += 1) {}
            if (i < line.len and line[i] == ' ') continue;
            i -= 1;
            continue;
        }
        try out.append(allocator, line[i]);
    }

    return out.toOwnedSlice(allocator);
}

fn bracesToIndent(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var indent: usize = 0;
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |raw| {
        var line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0) {
            try out.append(allocator, '\n');
            continue;
        }

        while (line.len > 0 and line[0] == '}') {
            if (indent > 0) indent -= 1;
            line = std.mem.trimLeft(u8, line[1..], " \t");
        }
        if (line.len == 0) continue;

        var opens = false;
        if (line[line.len - 1] == '{') {
            opens = true;
            line = std.mem.trimRight(u8, line[0 .. line.len - 1], " \t");
        }
        if (line.len > 0 and line[line.len - 1] == ';') {
            line = std.mem.trimRight(u8, line[0 .. line.len - 1], " \t");
        }
        if (line.len == 0) continue;

        var i: usize = 0;
        while (i < indent) : (i += 1) try out.appendSlice(allocator, "    ");
        try out.appendSlice(allocator, line);
        if (opens) try out.append(allocator, ':');
        try out.append(allocator, '\n');

        if (opens) indent += 1;
    }

    return out.toOwnedSlice(allocator);
}

fn replaceOwnedInline(allocator: std.mem.Allocator, input: []const u8, needle: []const u8, replacement: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    defer out.deinit(allocator);

    var start: usize = 0;
    while (std.mem.indexOfPos(u8, input, start, needle)) |idx| {
        try out.appendSlice(allocator, input[start..idx]);
        try out.appendSlice(allocator, replacement);
        start = idx + needle.len;
    }
    try out.appendSlice(allocator, input[start..]);
    return out.toOwnedSlice(allocator);
}

fn replaceInArrayList(allocator: std.mem.Allocator, buf: *std.ArrayList(u8), needle: []const u8, replacement: []const u8) !void {
    if (needle.len == 0) return;
    const current = try allocator.dupe(u8, buf.items);
    defer allocator.free(current);

    const rewritten = try replaceOwnedInline(allocator, current, needle, replacement);
    defer allocator.free(rewritten);

    try buf.resize(allocator, 0);
    try buf.appendSlice(allocator, rewritten);
}

fn replaceInSliceAlloc(slice: *[]u8, allocator: std.mem.Allocator, needle: []const u8, replacement: []const u8) !void {
    const rewritten = try replaceOwnedInline(allocator, slice.*, needle, replacement);
    allocator.free(slice.*);
    slice.* = rewritten;
}

fn countNeedle(haystack: []const u8, needle: []const u8) usize {
    if (needle.len == 0) return 0;
    var count: usize = 0;
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, haystack, start, needle)) |idx| {
        count += 1;
        start = idx + needle.len;
    }
    return count;
}

test "rust migration rewrites common forms" {
    const allocator = std.testing.allocator;
    const input =
        \\#[derive(Clone)]
        \\fn main() {
        \\    let mut x = 1;
        \\    println!("{}", x);
        \\    let s = String::from("abc");
        \\    let u = Ok(());
        \\}
        \\
    ;
    const out = try transformRust(allocator, input);
    defer allocator.free(out.text);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "@[derive(Clone)]") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "var x = 1") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "println(\"{x}\")") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "let s = \"abc\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "Ok()") != null);
}

test "zig migration rewrites common forms" {
    const allocator = std.testing.allocator;
    const input =
        \\const x: i32 = @as(i32, 1);
        \\const y = try maybe();
        \\const z = x orelse 0;
        \\const n = null;
        \\
    ;
    const out = try transformZig(allocator, input);
    defer allocator.free(out.text);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "let x: i32 = 1 as i32") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "let y = maybe()?") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "??") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "None") != null);
}

test "swift migration rewrites common forms" {
    const allocator = std.testing.allocator;
    const input =
        \\protocol P {}
        \\guard let x = value else { return }
        \\let msg = "value is \\(x)"
        \\let y: Int? = nil
        \\extension User: Greeter {}
        \\
    ;
    const out = try transformSwift(allocator, input);
    defer allocator.free(out.text);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "trait P") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "let Some(x) = value else return") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "\"value is {x}\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "Option[Int]") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.text, "impl Greeter for User") != null);
}
