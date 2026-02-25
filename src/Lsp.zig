//! Minimal Language Server Protocol (LSP) server for the With language.
//!
//! Communicates over stdin/stdout using JSON-RPC 2.0 with Content-Length headers.
//! Supports: initialize, shutdown, textDocument/didOpen, textDocument/didChange,
//! textDocument/publishDiagnostics.

const std = @import("std");
const Driver = @import("Driver.zig");
const Source = @import("Source.zig");

const Allocator = std.mem.Allocator;

allocator: Allocator,

const Self = @This();

pub fn init(allocator: Allocator) Self {
    return .{ .allocator = allocator };
}

pub fn run(self: *Self) !void {
    const stdin = std.fs.File.stdin();
    const stdout = std.fs.File.stdout();

    while (true) {
        const content_len = readContentLength(stdin) catch return;
        if (content_len == 0) continue;

        const body = self.allocator.alloc(u8, content_len) catch continue;
        defer self.allocator.free(body);

        var total: usize = 0;
        while (total < content_len) {
            const n = stdin.read(body[total..]) catch break;
            if (n == 0) break;
            total += n;
        }
        if (total < content_len) continue;

        self.handleMessage(body, stdout) catch continue;
    }
}

fn readContentLength(file: std.fs.File) !usize {
    var content_len: usize = 0;
    var line_buf: [512]u8 = undefined;
    var line_pos: usize = 0;

    // Read headers byte by byte.
    while (true) {
        const n = file.read(line_buf[line_pos .. line_pos + 1]) catch return error.EndOfStream;
        if (n == 0) return error.EndOfStream;

        if (line_buf[line_pos] == '\n') {
            // End of line — check if it's the empty line.
            const end = if (line_pos > 0 and line_buf[line_pos - 1] == '\r') line_pos - 1 else line_pos;
            const line = line_buf[0..end];

            if (line.len == 0) break; // Empty line = end of headers.

            if (std.mem.startsWith(u8, line, "Content-Length: ")) {
                content_len = std.fmt.parseInt(usize, line["Content-Length: ".len..], 10) catch 0;
            }
            line_pos = 0;
        } else {
            line_pos += 1;
            if (line_pos >= line_buf.len) line_pos = 0; // overflow protection
        }
    }
    return content_len;
}

fn handleMessage(self: *Self, body: []const u8, stdout: std.fs.File) !void {
    const method = extractString(body, "\"method\"") orelse "";
    const id = extractNumber(body, "\"id\"");

    if (std.mem.eql(u8, method, "initialize")) {
        const result =
            \\{"capabilities":{"textDocumentSync":{"openClose":true,"change":1},"hoverProvider":false},"serverInfo":{"name":"with-lsp","version":"0.1.0"}}
        ;
        sendResponse(id, result, stdout);
    } else if (std.mem.eql(u8, method, "initialized")) {
        // No response needed.
    } else if (std.mem.eql(u8, method, "shutdown")) {
        sendResponse(id, "null", stdout);
    } else if (std.mem.eql(u8, method, "exit")) {
        std.process.exit(0);
    } else if (std.mem.eql(u8, method, "textDocument/didOpen") or
        std.mem.eql(u8, method, "textDocument/didChange"))
    {
        const uri = extractString(body, "\"uri\"") orelse return;
        const text = extractString(body, "\"text\"") orelse return;
        const unescaped = unescapeJson(self.allocator, text) catch return;
        defer if (unescaped.ptr != text.ptr) self.allocator.free(unescaped);
        self.publishDiagnostics(uri, unescaped, stdout);
    } else if (id != null) {
        sendResponse(id, "null", stdout);
    }
}

fn publishDiagnostics(self: *Self, uri: []const u8, source_text: []const u8, stdout: std.fs.File) void {
    var driver = Driver.init(self.allocator);
    defer driver.deinit();

    var source = Source.fromString("lsp-input", source_text, 0, self.allocator);
    defer source.deinit();
    _ = driver.compileSource(&source) catch null;

    var buf: [32768]u8 = undefined;
    var pos: usize = 0;

    pos += (std.fmt.bufPrint(buf[pos..], "{{\"uri\":\"{s}\",\"diagnostics\":[", .{uri}) catch return).len;

    for (driver.diagnostics.items.items, 0..) |diag, i| {
        if (i > 0) {
            buf[pos] = ',';
            pos += 1;
        }
        const loc_start = source.offsetToLocation(diag.primary.start);
        const loc_end = source.offsetToLocation(diag.primary.end);
        const severity: u8 = if (diag.severity == .@"error") 1 else 2;

        const entry = std.fmt.bufPrint(buf[pos..],
            \\{{"range":{{"start":{{"line":{d},"character":{d}}},"end":{{"line":{d},"character":{d}}}}},"severity":{d},"source":"with","message":"{s}"}}
        , .{
            loc_start.line, loc_start.col, loc_end.line, loc_end.col, severity, diag.message,
        }) catch break;
        pos += entry.len;
    }

    pos += (std.fmt.bufPrint(buf[pos..], "]}}", .{}) catch return).len;
    sendNotification("textDocument/publishDiagnostics", buf[0..pos], stdout);
}

fn sendResponse(id: ?i64, result: []const u8, stdout: std.fs.File) void {
    var buf: [8192]u8 = undefined;
    const json = if (id) |i|
        std.fmt.bufPrint(&buf, "{{\"jsonrpc\":\"2.0\",\"id\":{d},\"result\":{s}}}", .{ i, result }) catch return
    else
        return;

    var header_buf: [128]u8 = undefined;
    const header = std.fmt.bufPrint(&header_buf, "Content-Length: {d}\r\n\r\n", .{json.len}) catch return;
    stdout.writeAll(header) catch return;
    stdout.writeAll(json) catch return;
}

fn sendNotification(method: []const u8, params: []const u8, stdout: std.fs.File) void {
    var json_buf: [65536]u8 = undefined;
    const json = std.fmt.bufPrint(&json_buf, "{{\"jsonrpc\":\"2.0\",\"method\":\"{s}\",\"params\":{s}}}", .{ method, params }) catch return;
    var header_buf: [128]u8 = undefined;
    const header = std.fmt.bufPrint(&header_buf, "Content-Length: {d}\r\n\r\n", .{json.len}) catch return;
    stdout.writeAll(header) catch return;
    stdout.writeAll(json) catch return;
}

// ── Helpers ─────────────────────────────────────────────────────────

fn extractString(json: []const u8, key: []const u8) ?[]const u8 {
    const key_pos = std.mem.indexOf(u8, json, key) orelse return null;
    const after = json[key_pos + key.len ..];
    var i: usize = 0;
    while (i < after.len and (after[i] == ':' or after[i] == ' ' or after[i] == '\t')) : (i += 1) {}
    if (i >= after.len or after[i] != '"') return null;
    i += 1;
    const start = i;
    while (i < after.len) : (i += 1) {
        if (after[i] == '"' and (i == start or after[i - 1] != '\\')) break;
    }
    return after[start..i];
}

fn extractNumber(json: []const u8, key: []const u8) ?i64 {
    const key_pos = std.mem.indexOf(u8, json, key) orelse return null;
    const after = json[key_pos + key.len ..];
    var i: usize = 0;
    while (i < after.len and (after[i] == ':' or after[i] == ' ')) : (i += 1) {}
    if (i >= after.len) return null;
    const start = i;
    while (i < after.len and after[i] >= '0' and after[i] <= '9') : (i += 1) {}
    if (i == start) return null;
    return std.fmt.parseInt(i64, after[start..i], 10) catch null;
}

fn unescapeJson(allocator: Allocator, s: []const u8) ![]const u8 {
    if (std.mem.indexOf(u8, s, "\\") == null) return s;
    var result = try allocator.alloc(u8, s.len);
    var out: usize = 0;
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] == '\\' and i + 1 < s.len) {
            i += 1;
            result[out] = switch (s[i]) {
                'n' => '\n',
                't' => '\t',
                'r' => '\r',
                '\\' => '\\',
                '"' => '"',
                else => s[i],
            };
        } else {
            result[out] = s[i];
        }
        out += 1;
    }
    return result[0..out];
}
