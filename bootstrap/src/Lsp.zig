//! Minimal Language Server Protocol (LSP) server for the With language.
//!
//! Communicates over stdin/stdout using JSON-RPC 2.0 with Content-Length headers.
//! Supports: initialize, shutdown, textDocument/didOpen, textDocument/didChange,
//! textDocument/publishDiagnostics, textDocument/hover, textDocument/definition,
//! textDocument/completion, textDocument/references, textDocument/rename.

const std = @import("std");
const Driver = @import("Driver.zig");
const Source = @import("Source.zig");
const Lexer = @import("Lexer.zig");
const Token = @import("Token.zig");
const Parser = @import("Parser.zig");
const Ast = @import("Ast.zig");
const Sema = @import("Sema.zig");
const Diagnostic = @import("Diagnostic.zig");
const InternPool = @import("InternPool.zig");

const Allocator = std.mem.Allocator;

allocator: Allocator,
/// Document store: URI → source text (last received content).
documents: std.StringHashMapUnmanaged([]const u8),

const Self = @This();

pub fn init(allocator: Allocator) Self {
    return .{
        .allocator = allocator,
        .documents = .empty,
    };
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
            \\{"capabilities":{"textDocumentSync":{"openClose":true,"change":1},"hoverProvider":true,"definitionProvider":true,"referencesProvider":true,"renameProvider":true,"completionProvider":{"triggerCharacters":[".",":"]}},"serverInfo":{"name":"with-lsp","version":"0.2.0"}}
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
        // Store a copy of the document text for later hover/def/completion.
        self.storeDocument(uri, unescaped);
        self.publishDiagnostics(uri, unescaped, stdout);
    } else if (std.mem.eql(u8, method, "textDocument/hover")) {
        self.handleHover(body, id, stdout);
    } else if (std.mem.eql(u8, method, "textDocument/definition")) {
        self.handleDefinition(body, id, stdout);
    } else if (std.mem.eql(u8, method, "textDocument/references")) {
        self.handleReferences(body, id, stdout);
    } else if (std.mem.eql(u8, method, "textDocument/rename")) {
        self.handleRename(body, id, stdout);
    } else if (std.mem.eql(u8, method, "textDocument/completion")) {
        self.handleCompletion(body, id, stdout);
    } else if (id != null) {
        sendResponse(id, "null", stdout);
    }
}

// ── Document store ──────────────────────────────────────────────

fn storeDocument(self: *Self, uri: []const u8, text: []const u8) void {
    // If there is an existing entry, free the old text copy.
    if (self.documents.get(uri)) |old_text| {
        self.allocator.free(@constCast(old_text));
        // Reuse the key.
        const copy = self.allocator.dupe(u8, text) catch return;
        self.documents.put(self.allocator, uri, copy) catch {
            self.allocator.free(copy);
        };
        return;
    }
    // New entry: duplicate both key and value.
    const key = self.allocator.dupe(u8, uri) catch return;
    const val = self.allocator.dupe(u8, text) catch {
        self.allocator.free(key);
        return;
    };
    self.documents.put(self.allocator, key, val) catch {
        self.allocator.free(key);
        self.allocator.free(val);
    };
}

fn getDocument(self: *const Self, uri: []const u8) ?[]const u8 {
    return self.documents.get(uri);
}

// ── Diagnostics ─────────────────────────────────────────────────

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

// ── Hover ───────────────────────────────────────────────────────

fn handleHover(self: *Self, body: []const u8, id: ?i64, stdout: std.fs.File) void {
    const uri = extractString(body, "\"uri\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const source_text = self.getDocument(uri) orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    // Extract position from the request.
    const line = extractPosition(body, "\"line\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const character = extractPosition(body, "\"character\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    // Convert line/character to byte offset.
    var source = Source.fromString("lsp-input", source_text, 0, self.allocator);
    defer source.deinit();
    const offset = locationToOffset(&source, @intCast(line), @intCast(character));

    // Find the word at the cursor position.
    const word = wordAtOffset(source_text, offset) orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    // Parse and run sema to get type information.
    const hover_text = self.getHoverInfo(source_text, word) orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    // Build the hover response.
    var buf: [8192]u8 = undefined;
    const result = std.fmt.bufPrint(&buf,
        \\{{"contents":{{"kind":"markdown","value":"```with\n{s}\n```"}}}}
    , .{hover_text}) catch {
        sendResponse(id, "null", stdout);
        return;
    };
    sendResponse(id, result, stdout);
}

fn getHoverInfo(self: *Self, source_text: []const u8, word: []const u8) ?[]const u8 {
    // Set up a mini-compilation pipeline: lex → parse → sema.
    var pool = InternPool.init(self.allocator);
    defer pool.deinit();
    var diagnostics = Diagnostic.DiagnosticList.init(self.allocator);
    defer diagnostics.deinit();
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();

    var lexer = Lexer.init(source_text, 0, &diagnostics);
    var tokens = lexer.tokenize(self.allocator) catch return null;
    defer tokens.deinit();

    var parser = Parser.init(&tokens, source_text, arena.allocator(), &pool, &diagnostics);
    const module = parser.parseModule() catch return null;

    var sema = Sema.init(arena.allocator(), &pool, &diagnostics);
    defer sema.deinit();
    sema.checkModule(&module);

    // Intern the word to look it up in Sema's tables.
    const sym = pool.intern(word) catch return null;

    // 1. Check function signatures.
    if (sema.fn_sigs.get(sym)) |sig| {
        return self.formatFnSig(&sema, word, sig);
    }

    // 2. Check type names.
    if (sema.named_types.get(sym)) |tid| {
        return self.formatTypeHover(&pool, &sema, word, tid);
    }

    // 3. Check scope bindings — walk the AST to find let bindings with this name.
    //    Since Sema scopes are stack-local, we re-check by looking at the module decls.
    const bind_type = self.findBindingType(&sema, &module, sym);
    if (bind_type) |tid| {
        var name_buf: [512]u8 = undefined;
        const type_name = sema.typeName(tid);
        const result = std.fmt.bufPrint(&name_buf, "{s}: {s}", .{ word, type_name }) catch return null;
        return self.dupeStr(result);
    }

    // 4. Check if it is a keyword.
    if (Token.Tag.fromKeyword(word)) |_| {
        var kw_buf: [256]u8 = undefined;
        const result = std.fmt.bufPrint(&kw_buf, "(keyword) {s}", .{word}) catch return null;
        return self.dupeStr(result);
    }

    // 5. Check built-in functions.
    if (isBuiltinName(word)) {
        var bi_buf: [256]u8 = undefined;
        const result = std.fmt.bufPrint(&bi_buf, "(built-in) {s}", .{word}) catch return null;
        return self.dupeStr(result);
    }

    return null;
}

fn formatFnSig(self: *Self, sema: *const Sema, name: []const u8, sig: Sema.FnSigInfo) ?[]const u8 {
    var buf: [1024]u8 = undefined;
    var pos: usize = 0;

    // "fn name("
    const prefix = std.fmt.bufPrint(buf[pos..], "fn {s}(", .{name}) catch return null;
    pos += prefix.len;

    // Parameters.
    for (sig.param_types, 0..) |pt, i| {
        if (i > 0) {
            const comma = std.fmt.bufPrint(buf[pos..], ", ", .{}) catch return null;
            pos += comma.len;
        }
        const pname = sema.typeName(pt);
        const param = std.fmt.bufPrint(buf[pos..], "{s}", .{pname}) catch return null;
        pos += param.len;
    }

    // ") -> RetType"
    const ret_name = sema.typeName(sig.return_type);
    const suffix = std.fmt.bufPrint(buf[pos..], ") -> {s}", .{ret_name}) catch return null;
    pos += suffix.len;

    return self.dupeStr(buf[0..pos]);
}

fn formatTypeHover(self: *Self, pool: *InternPool, sema: *Sema, name: []const u8, tid: Sema.TypeId) ?[]const u8 {
    const resolved = sema.resolveAlias(tid);
    const ty = sema.getType(resolved);
    var buf: [1024]u8 = undefined;

    const result = switch (ty) {
        .struct_type => |st| blk: {
            var pos: usize = 0;
            const header = std.fmt.bufPrint(buf[pos..], "type {s} = {{", .{name}) catch return null;
            pos += header.len;
            for (st.field_names, 0..) |fname, i| {
                const sep = if (i > 0) ", " else " ";
                const field_name = pool.resolve(fname);
                const field_type = sema.typeName(st.field_types[i]);
                const field = std.fmt.bufPrint(buf[pos..], "{s}{s}: {s}", .{ sep, field_name, field_type }) catch break;
                pos += field.len;
            }
            const close = std.fmt.bufPrint(buf[pos..], " }}", .{}) catch return null;
            pos += close.len;
            break :blk buf[0..pos];
        },
        .enum_type => |et| blk: {
            var pos: usize = 0;
            const header = std.fmt.bufPrint(buf[pos..], "type {s} = enum {{ ", .{name}) catch return null;
            pos += header.len;
            for (et.variant_names, 0..) |vname, i| {
                const sep = if (i > 0) ", " else "";
                const variant_name = pool.resolve(vname);
                const variant = std.fmt.bufPrint(buf[pos..], "{s}{s}", .{ sep, variant_name }) catch break;
                pos += variant.len;
            }
            const close = std.fmt.bufPrint(buf[pos..], " }}", .{}) catch return null;
            pos += close.len;
            break :blk buf[0..pos];
        },
        else => blk: {
            const r = std.fmt.bufPrint(&buf, "type {s}", .{name}) catch return null;
            break :blk r;
        },
    };
    return self.dupeStr(result);
}

/// Walk module declarations to find a let binding's type for the given symbol.
fn findBindingType(self: *Self, sema: *Sema, module: *const Ast.Module, sym: InternPool.Symbol) ?Sema.TypeId {
    _ = self;
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |fn_decl| {
                // Check parameters.
                if (fn_decl.params.len > 0) {
                    const sig = sema.fn_sigs.get(fn_decl.name);
                    for (fn_decl.params, 0..) |param, i| {
                        if (param.name == sym) {
                            if (sig) |s| {
                                if (i < s.param_types.len) return s.param_types[i];
                            }
                            // Try to resolve from type annotation.
                            if (param.type_expr) |te| {
                                return sema.resolveTypeExpr(te);
                            }
                        }
                    }
                }
                // Search let bindings in function body.
                if (findBindingInExpr(fn_decl.body, sym)) |type_expr| {
                    return sema.resolveTypeExpr(type_expr);
                }
                // Check if a let binding has no type annotation but has a known value type.
                if (findLetBindingNoAnnotation(fn_decl.body, sym)) |_| {
                    // Without running full sema in context, we can't infer.
                    return null;
                }
            },
            .let_decl => |ld| {
                if (ld.name == sym) {
                    if (ld.type_expr) |te| {
                        return sema.resolveTypeExpr(te);
                    }
                }
            },
            else => {},
        }
    }
    return null;
}

/// Search an expression tree for a let binding with a type annotation.
fn findBindingInExpr(expr: *const Ast.Expr, sym: InternPool.Symbol) ?*const Ast.TypeExpr {
    switch (expr.kind) {
        .let_binding => |lb| {
            if (lb.name == sym) {
                if (lb.type_expr) |te| return te;
            }
            // Also search the value in case it is a block.
            return findBindingInExpr(lb.value, sym);
        },
        .block => |blk| {
            for (blk.stmts) |stmt| {
                if (findBindingInExpr(stmt, sym)) |te| return te;
            }
            if (blk.tail) |tail| {
                return findBindingInExpr(tail, sym);
            }
        },
        .if_expr => |ie| {
            if (findBindingInExpr(ie.then_body, sym)) |te| return te;
            if (ie.else_body) |eb| {
                if (findBindingInExpr(eb, sym)) |te| return te;
            }
        },
        .while_expr => |we| return findBindingInExpr(we.body, sym),
        .for_expr => |fe| return findBindingInExpr(fe.body, sym),
        .loop_expr => |le| return findBindingInExpr(le.body, sym),
        else => {},
    }
    return null;
}

/// Search for a let binding without type annotation (for reporting purposes).
fn findLetBindingNoAnnotation(expr: *const Ast.Expr, sym: InternPool.Symbol) ?[]const u8 {
    switch (expr.kind) {
        .let_binding => |lb| {
            if (lb.name == sym and lb.type_expr == null) return "inferred";
        },
        .block => |blk| {
            for (blk.stmts) |stmt| {
                if (findLetBindingNoAnnotation(stmt, sym)) |r| return r;
            }
            if (blk.tail) |tail| return findLetBindingNoAnnotation(tail, sym);
        },
        else => {},
    }
    return null;
}

// ── Go-to-Definition ────────────────────────────────────────────

fn handleDefinition(self: *Self, body: []const u8, id: ?i64, stdout: std.fs.File) void {
    const uri = extractString(body, "\"uri\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const source_text = self.getDocument(uri) orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    const line = extractPosition(body, "\"line\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const character = extractPosition(body, "\"character\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    var source = Source.fromString("lsp-input", source_text, 0, self.allocator);
    defer source.deinit();
    const offset = locationToOffset(&source, @intCast(line), @intCast(character));

    const word = wordAtOffset(source_text, offset) orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    // Parse to get AST and find the definition span.
    const def_span = self.findDefinitionSpan(source_text, word) orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    // Convert span to LSP location.
    const start_loc = source.offsetToLocation(def_span.start);
    const end_loc = source.offsetToLocation(def_span.end);

    var buf: [4096]u8 = undefined;
    const result = std.fmt.bufPrint(&buf,
        \\{{"uri":"{s}","range":{{"start":{{"line":{d},"character":{d}}},"end":{{"line":{d},"character":{d}}}}}}}
    , .{ uri, start_loc.line, start_loc.col, end_loc.line, end_loc.col }) catch {
        sendResponse(id, "null", stdout);
        return;
    };
    sendResponse(id, result, stdout);
}

fn isWordMatchAt(text: []const u8, idx: usize, word: []const u8) bool {
    if (word.len == 0) return false;
    if (idx + word.len > text.len) return false;
    if (!std.mem.eql(u8, text[idx .. idx + word.len], word)) return false;
    if (idx > 0 and isIdentChar(text[idx - 1])) return false;
    if (idx + word.len < text.len and isIdentChar(text[idx + word.len])) return false;
    return true;
}

fn handleReferences(self: *Self, body: []const u8, id: ?i64, stdout: std.fs.File) void {
    const uri = extractString(body, "\"uri\"") orelse {
        sendResponse(id, "[]", stdout);
        return;
    };
    const source_text = self.getDocument(uri) orelse {
        sendResponse(id, "[]", stdout);
        return;
    };
    const line = extractPosition(body, "\"line\"") orelse {
        sendResponse(id, "[]", stdout);
        return;
    };
    const character = extractPosition(body, "\"character\"") orelse {
        sendResponse(id, "[]", stdout);
        return;
    };

    var source = Source.fromString("lsp-input", source_text, 0, self.allocator);
    defer source.deinit();
    const offset = locationToOffset(&source, @intCast(line), @intCast(character));
    const word = wordAtOffset(source_text, offset) orelse {
        sendResponse(id, "[]", stdout);
        return;
    };

    var buf: [65536]u8 = undefined;
    var pos: usize = 0;
    pos += (std.fmt.bufPrint(buf[pos..], "[", .{}) catch {
        sendResponse(id, "[]", stdout);
        return;
    }).len;

    var found: usize = 0;
    var i: usize = 0;
    while (i + word.len <= source_text.len) : (i += 1) {
        if (!isWordMatchAt(source_text, i, word)) continue;
        const start_loc = source.offsetToLocation(@intCast(i));
        const end_loc = source.offsetToLocation(@intCast(i + word.len));
        if (found > 0) {
            buf[pos] = ',';
            pos += 1;
        }
        const loc = std.fmt.bufPrint(
            buf[pos..],
            \\{{"uri":"{s}","range":{{"start":{{"line":{d},"character":{d}}},"end":{{"line":{d},"character":{d}}}}}}}
        , .{ uri, start_loc.line, start_loc.col, end_loc.line, end_loc.col }) catch break;
        pos += loc.len;
        found += 1;
        i += word.len - 1;
    }

    pos += (std.fmt.bufPrint(buf[pos..], "]", .{}) catch {
        sendResponse(id, "[]", stdout);
        return;
    }).len;

    sendResponse(id, buf[0..pos], stdout);
}

fn handleRename(self: *Self, body: []const u8, id: ?i64, stdout: std.fs.File) void {
    const uri = extractString(body, "\"uri\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const source_text = self.getDocument(uri) orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const new_name = extractString(body, "\"newName\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const line = extractPosition(body, "\"line\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const character = extractPosition(body, "\"character\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    var source = Source.fromString("lsp-input", source_text, 0, self.allocator);
    defer source.deinit();
    const offset = locationToOffset(&source, @intCast(line), @intCast(character));
    const word = wordAtOffset(source_text, offset) orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    var buf: [65536]u8 = undefined;
    var pos: usize = 0;
    pos += (std.fmt.bufPrint(buf[pos..], "{{\"changes\":{{\"{s}\":[", .{uri}) catch {
        sendResponse(id, "null", stdout);
        return;
    }).len;

    var found: usize = 0;
    var i: usize = 0;
    while (i + word.len <= source_text.len) : (i += 1) {
        if (!isWordMatchAt(source_text, i, word)) continue;
        const start_loc = source.offsetToLocation(@intCast(i));
        const end_loc = source.offsetToLocation(@intCast(i + word.len));
        if (found > 0) {
            buf[pos] = ',';
            pos += 1;
        }
        const edit = std.fmt.bufPrint(
            buf[pos..],
            \\{{"range":{{"start":{{"line":{d},"character":{d}}},"end":{{"line":{d},"character":{d}}}}},"newText":"{s}"}}
        , .{ start_loc.line, start_loc.col, end_loc.line, end_loc.col, new_name }) catch break;
        pos += edit.len;
        found += 1;
        i += word.len - 1;
    }

    pos += (std.fmt.bufPrint(buf[pos..], "]}}}}", .{}) catch {
        sendResponse(id, "null", stdout);
        return;
    }).len;
    sendResponse(id, buf[0..pos], stdout);
}

fn findDefinitionSpan(self: *Self, source_text: []const u8, word: []const u8) ?@import("Span.zig") {
    var pool = InternPool.init(self.allocator);
    defer pool.deinit();
    var diagnostics = Diagnostic.DiagnosticList.init(self.allocator);
    defer diagnostics.deinit();
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();

    var lexer = Lexer.init(source_text, 0, &diagnostics);
    var tokens = lexer.tokenize(self.allocator) catch return null;
    defer tokens.deinit();

    var parser = Parser.init(&tokens, source_text, arena.allocator(), &pool, &diagnostics);
    const module = parser.parseModule() catch return null;

    const sym = pool.intern(word) catch return null;

    // Search declarations for a matching name.
    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |fn_decl| {
                if (fn_decl.name == sym) return decl.span;
                // Search parameters.
                for (fn_decl.params) |param| {
                    if (param.name == sym) return param.span;
                }
                // Search let bindings in the body.
                if (findBindingSpanInExpr(fn_decl.body, sym)) |span| return span;
            },
            .type_decl => |td| {
                if (td.name == sym) return decl.span;
            },
            .let_decl => |ld| {
                if (ld.name == sym) return decl.span;
            },
            .extern_fn => |ef| {
                if (ef.name == sym) return decl.span;
            },
            .trait_decl => |trd| {
                if (trd.name == sym) return decl.span;
            },
            else => {},
        }
    }
    return null;
}

/// Search an expression tree for a let binding's span.
fn findBindingSpanInExpr(expr: *const Ast.Expr, sym: InternPool.Symbol) ?@import("Span.zig") {
    switch (expr.kind) {
        .let_binding => |lb| {
            if (lb.name == sym) return expr.span;
            return findBindingSpanInExpr(lb.value, sym);
        },
        .block => |blk| {
            for (blk.stmts) |stmt| {
                if (findBindingSpanInExpr(stmt, sym)) |span| return span;
            }
            if (blk.tail) |tail| return findBindingSpanInExpr(tail, sym);
        },
        .if_expr => |ie| {
            if (findBindingSpanInExpr(ie.then_body, sym)) |span| return span;
            if (ie.else_body) |eb| {
                if (findBindingSpanInExpr(eb, sym)) |span| return span;
            }
        },
        .while_expr => |we| return findBindingSpanInExpr(we.body, sym),
        .for_expr => |fe| {
            if (fe.binding_pattern) |bp| {
                if (patternContainsBinding(&bp, sym)) return expr.span;
            } else if (fe.binding == sym) {
                return expr.span;
            }
            return findBindingSpanInExpr(fe.body, sym);
        },
        .loop_expr => |le| return findBindingSpanInExpr(le.body, sym),
        .with_expr => |we| {
            if (we.name == sym) return expr.span;
            return findBindingSpanInExpr(we.body, sym);
        },
        .match_expr => |me| {
            for (me.arms) |arm| {
                if (findBindingSpanInExpr(arm.body, sym)) |span| return span;
            }
        },
        .closure => |cl| {
            for (cl.params) |p| {
                if (p == sym) return expr.span;
            }
            return findBindingSpanInExpr(cl.body, sym);
        },
        .let_else => |le| {
            for (le.pattern.bindings) |b| {
                if (b == sym) return expr.span;
            }
        },
        .tuple_destructure => |td| {
            for (td.names) |n| {
                if (n == sym) return expr.span;
            }
        },
        else => {},
    }
    return null;
}

fn patternContainsBinding(pattern: *const Ast.Pattern, sym: InternPool.Symbol) bool {
    switch (pattern.kind) {
        .binding => |s| return s == sym,
        .at_binding => |ab| return ab.name == sym or patternContainsBinding(ab.pattern, sym),
        .tuple_pattern => |elems| {
            for (elems) |*elem| {
                if (patternContainsBinding(elem, sym)) return true;
            }
            return false;
        },
        .or_pattern => |alts| {
            for (alts) |*alt| {
                if (patternContainsBinding(alt, sym)) return true;
            }
            return false;
        },
        else => return false,
    }
}

fn addPatternBindingsToCompletion(self: *Self, pattern: *const Ast.Pattern, pool: *InternPool, prefix: []const u8, buf: *[65536]u8, pos: *usize, item_count: *usize, seen: *std.StringHashMapUnmanaged(void)) void {
    switch (pattern.kind) {
        .binding => |sym| {
            const name = pool.resolve(sym);
            self.addCompletionItem(name, 6, prefix, buf, pos, item_count, seen);
        },
        .at_binding => |ab| {
            const name = pool.resolve(ab.name);
            self.addCompletionItem(name, 6, prefix, buf, pos, item_count, seen);
            self.addPatternBindingsToCompletion(ab.pattern, pool, prefix, buf, pos, item_count, seen);
        },
        .tuple_pattern => |elems| {
            for (elems) |*elem| {
                self.addPatternBindingsToCompletion(elem, pool, prefix, buf, pos, item_count, seen);
            }
        },
        .or_pattern => |alts| {
            for (alts) |*alt| {
                self.addPatternBindingsToCompletion(alt, pool, prefix, buf, pos, item_count, seen);
            }
        },
        else => {},
    }
}

// ── Completion ──────────────────────────────────────────────────

fn handleCompletion(self: *Self, body: []const u8, id: ?i64, stdout: std.fs.File) void {
    const uri = extractString(body, "\"uri\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const source_text = self.getDocument(uri) orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    const line = extractPosition(body, "\"line\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };
    const character = extractPosition(body, "\"character\"") orelse {
        sendResponse(id, "null", stdout);
        return;
    };

    var source = Source.fromString("lsp-input", source_text, 0, self.allocator);
    defer source.deinit();
    const offset = locationToOffset(&source, @intCast(line), @intCast(character));

    // Get the partial word being typed (prefix up to cursor).
    const prefix = prefixAtOffset(source_text, offset);

    // Build completion items.
    var buf: [65536]u8 = undefined;
    var pos: usize = 0;

    pos += (std.fmt.bufPrint(buf[pos..], "{{\"isIncomplete\":false,\"items\":[", .{}) catch {
        sendResponse(id, "null", stdout);
        return;
    }).len;

    var item_count: usize = 0;

    // 1. Keywords.
    const keywords = [_][]const u8{
        "fn",    "let",      "var",    "if",       "else",    "then",
        "match", "for",      "in",     "while",    "loop",    "return",
        "break", "continue", "with",   "as",       "mut",     "type",
        "trait", "impl",     "extend", "dyn",      "use",     "module",
        "pub",   "async",    "await",  "spawn",    "comptime", "gen",
        "yield", "defer",    "extern", "not",      "and",     "or",
        "true",  "false",    "struct", "enum",
    };
    for (keywords) |kw| {
        if (prefix.len == 0 or std.mem.startsWith(u8, kw, prefix)) {
            if (item_count > 0) {
                buf[pos] = ',';
                pos += 1;
            }
            // kind: 14 = Keyword
            const item = std.fmt.bufPrint(buf[pos..],
                \\{{"label":"{s}","kind":14}}
            , .{kw}) catch break;
            pos += item.len;
            item_count += 1;
        }
    }

    // 2. Built-in functions.
    const builtins = [_][]const u8{
        "println", "print", "assert", "Some", "Ok", "Err", "None",
        "Vec",     "HashMap", "HashSet", "Channel", "String",
        "Debug",   "Display", "Default", "Iter",    "IntoIter",
        "Eq",      "Hash",    "Ord",
    };
    for (builtins) |bi| {
        if (prefix.len == 0 or std.mem.startsWith(u8, bi, prefix)) {
            if (item_count > 0) {
                buf[pos] = ',';
                pos += 1;
            }
            // kind: 3 = Function
            const item = std.fmt.bufPrint(buf[pos..],
                \\{{"label":"{s}","kind":3}}
            , .{bi}) catch break;
            pos += item.len;
            item_count += 1;
        }
    }

    // 3. Symbols from the document (function names, type names, variable names).
    self.addDocumentSymbols(source_text, prefix, &buf, &pos, &item_count);

    pos += (std.fmt.bufPrint(buf[pos..], "]}}", .{}) catch {
        sendResponse(id, "null", stdout);
        return;
    }).len;

    sendResponse(id, buf[0..pos], stdout);
}

fn addDocumentSymbols(self: *Self, source_text: []const u8, prefix: []const u8, buf: *[65536]u8, pos: *usize, item_count: *usize) void {
    var pool = InternPool.init(self.allocator);
    defer pool.deinit();
    var diagnostics = Diagnostic.DiagnosticList.init(self.allocator);
    defer diagnostics.deinit();
    var arena = std.heap.ArenaAllocator.init(self.allocator);
    defer arena.deinit();

    var lexer = Lexer.init(source_text, 0, &diagnostics);
    var tokens = lexer.tokenize(self.allocator) catch return;
    defer tokens.deinit();

    var parser = Parser.init(&tokens, source_text, arena.allocator(), &pool, &diagnostics);
    const module = parser.parseModule() catch return;

    // Track already-added names to avoid duplicates.
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    defer seen.deinit(self.allocator);

    for (module.decls) |decl| {
        switch (decl.kind) {
            .function => |fn_decl| {
                const name = pool.resolve(fn_decl.name);
                // kind: 3 = Function
                self.addCompletionItem(name, 3, prefix, buf, pos, item_count, &seen);
                // Add parameter names.
                for (fn_decl.params) |param| {
                    const pname = pool.resolve(param.name);
                    // kind: 6 = Variable
                    self.addCompletionItem(pname, 6, prefix, buf, pos, item_count, &seen);
                }
                // Add let bindings from the body.
                self.collectBindingsFromExpr(fn_decl.body, &pool, prefix, buf, pos, item_count, &seen);
            },
            .type_decl => |td| {
                const name = pool.resolve(td.name);
                // kind: 22 = Struct, 13 = Enum
                const kind: u8 = switch (td.kind) {
                    .enum_def => 13,
                    else => 22,
                };
                self.addCompletionItem(name, kind, prefix, buf, pos, item_count, &seen);

                // Add enum variant names.
                if (td.kind == .enum_def) {
                    for (td.kind.enum_def) |variant| {
                        const vname = pool.resolve(variant.name);
                        // kind: 20 = EnumMember
                        self.addCompletionItem(vname, 20, prefix, buf, pos, item_count, &seen);
                    }
                }
                // Add struct field names.
                if (td.kind == .struct_def) {
                    for (td.kind.struct_def) |field| {
                        const fname = pool.resolve(field.name);
                        // kind: 5 = Field
                        self.addCompletionItem(fname, 5, prefix, buf, pos, item_count, &seen);
                    }
                }
            },
            .let_decl => |ld| {
                const name = pool.resolve(ld.name);
                // kind: 6 = Variable
                self.addCompletionItem(name, 6, prefix, buf, pos, item_count, &seen);
            },
            .extern_fn => |ef| {
                const name = pool.resolve(ef.name);
                // kind: 3 = Function
                self.addCompletionItem(name, 3, prefix, buf, pos, item_count, &seen);
            },
            .trait_decl => |trd| {
                const name = pool.resolve(trd.name);
                // kind: 8 = Interface
                self.addCompletionItem(name, 8, prefix, buf, pos, item_count, &seen);
            },
            else => {},
        }
    }
}

fn collectBindingsFromExpr(self: *Self, expr: *const Ast.Expr, pool: *InternPool, prefix: []const u8, buf: *[65536]u8, pos: *usize, item_count: *usize, seen: *std.StringHashMapUnmanaged(void)) void {
    switch (expr.kind) {
        .let_binding => |lb| {
            const name = pool.resolve(lb.name);
            self.addCompletionItem(name, 6, prefix, buf, pos, item_count, seen);
            self.collectBindingsFromExpr(lb.value, pool, prefix, buf, pos, item_count, seen);
        },
        .block => |blk| {
            for (blk.stmts) |stmt| {
                self.collectBindingsFromExpr(stmt, pool, prefix, buf, pos, item_count, seen);
            }
            if (blk.tail) |tail| {
                self.collectBindingsFromExpr(tail, pool, prefix, buf, pos, item_count, seen);
            }
        },
        .if_expr => |ie| {
            self.collectBindingsFromExpr(ie.then_body, pool, prefix, buf, pos, item_count, seen);
            if (ie.else_body) |eb| {
                self.collectBindingsFromExpr(eb, pool, prefix, buf, pos, item_count, seen);
            }
        },
        .while_expr => |we| self.collectBindingsFromExpr(we.body, pool, prefix, buf, pos, item_count, seen),
        .for_expr => |fe| {
            if (fe.binding_pattern) |bp| {
                self.addPatternBindingsToCompletion(&bp, pool, prefix, buf, pos, item_count, seen);
            } else {
                const name = pool.resolve(fe.binding);
                self.addCompletionItem(name, 6, prefix, buf, pos, item_count, seen);
            }
            self.collectBindingsFromExpr(fe.body, pool, prefix, buf, pos, item_count, seen);
        },
        .loop_expr => |le| self.collectBindingsFromExpr(le.body, pool, prefix, buf, pos, item_count, seen),
        .with_expr => |we| {
            const name = pool.resolve(we.name);
            self.addCompletionItem(name, 6, prefix, buf, pos, item_count, seen);
            self.collectBindingsFromExpr(we.body, pool, prefix, buf, pos, item_count, seen);
        },
        .match_expr => |me| {
            for (me.arms) |arm| {
                self.collectBindingsFromExpr(arm.body, pool, prefix, buf, pos, item_count, seen);
            }
        },
        .closure => |cl| {
            for (cl.params) |p| {
                const name = pool.resolve(p);
                self.addCompletionItem(name, 6, prefix, buf, pos, item_count, seen);
            }
            self.collectBindingsFromExpr(cl.body, pool, prefix, buf, pos, item_count, seen);
        },
        .let_else => |le| {
            for (le.pattern.bindings) |b| {
                const name = pool.resolve(b);
                self.addCompletionItem(name, 6, prefix, buf, pos, item_count, seen);
            }
        },
        .tuple_destructure => |td| {
            for (td.names) |n| {
                const name = pool.resolve(n);
                self.addCompletionItem(name, 6, prefix, buf, pos, item_count, seen);
            }
        },
        else => {},
    }
}

fn addCompletionItem(self: *Self, name: []const u8, kind: u8, prefix: []const u8, buf: *[65536]u8, pos: *usize, item_count: *usize, seen: *std.StringHashMapUnmanaged(void)) void {
    // Skip empty names, underscore, or names that don't match prefix.
    if (name.len == 0 or std.mem.eql(u8, name, "_")) return;
    if (prefix.len > 0 and !std.mem.startsWith(u8, name, prefix)) return;
    // Skip duplicates.
    if (seen.get(name) != null) return;
    seen.put(self.allocator, name, {}) catch {};

    if (item_count.* > 0) {
        buf[pos.*] = ',';
        pos.* += 1;
    }
    const item = std.fmt.bufPrint(buf[pos.*..],
        \\{{"label":"{s}","kind":{d}}}
    , .{ name, kind }) catch return;
    pos.* += item.len;
    item_count.* += 1;
}

// ── Response helpers ────────────────────────────────────────────

fn sendResponse(id: ?i64, result: []const u8, stdout: std.fs.File) void {
    var buf: [65536]u8 = undefined;
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

// ── Helpers ─────────────────────────────────────────────────────

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

/// Extract a number from the "position" sub-object of a JSON body.
/// This scopes the search to after the "position" key to avoid matching
/// unrelated "line" or "character" fields elsewhere in the message.
fn extractPosition(json: []const u8, key: []const u8) ?i64 {
    const pos_key = "\"position\"";
    const pos_start = std.mem.indexOf(u8, json, pos_key) orelse return null;
    const sub = json[pos_start..];
    return extractNumber(sub, key);
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
    if (out == s.len) return result;
    const shrunk = allocator.dupe(u8, result[0..out]) catch |err| {
        allocator.free(result);
        return err;
    };
    allocator.free(result);
    return shrunk;
}

/// Convert LSP line/character (both 0-indexed) to a byte offset.
fn locationToOffset(source: *const Source, line: u32, col: u32) u32 {
    if (line >= source.line_offsets.items.len) {
        // Past end of file — clamp to end.
        return @intCast(source.text.len);
    }
    const line_start = source.line_offsets.items[line];
    const line_end = if (line + 1 < source.line_offsets.items.len)
        source.line_offsets.items[line + 1]
    else
        @as(u32, @intCast(source.text.len));
    const max_col = line_end - line_start;
    return line_start + @min(col, max_col);
}

/// Extract the identifier word surrounding a byte offset.
fn wordAtOffset(text: []const u8, offset: u32) ?[]const u8 {
    if (offset >= text.len) return null;

    // Find start of word.
    var start: usize = offset;
    while (start > 0 and isIdentChar(text[start - 1])) {
        start -= 1;
    }

    // Find end of word.
    var end: usize = offset;
    while (end < text.len and isIdentChar(text[end])) {
        end += 1;
    }

    if (start == end) return null;
    return text[start..end];
}

/// Get the prefix being typed (characters before cursor that form an identifier).
fn prefixAtOffset(text: []const u8, offset: u32) []const u8 {
    if (offset == 0 or offset > text.len) return "";
    var start: usize = offset;
    while (start > 0 and isIdentChar(text[start - 1])) {
        start -= 1;
    }
    return text[start..offset];
}

fn isIdentChar(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_';
}

fn isBuiltinName(name: []const u8) bool {
    const builtins = [_][]const u8{
        "println", "print", "assert", "Some", "Ok",      "Err",
        "None",    "Vec",   "HashMap", "HashSet", "Channel", "send",
        "recv",    "close", "String",  "Debug",   "Display", "Default",
        "Iter",    "IntoIter", "Eq",   "Hash",    "Ord",
    };
    for (builtins) |bi| {
        if (std.mem.eql(u8, name, bi)) return true;
    }
    return false;
}

/// Duplicate a string slice using the LSP server's allocator.
/// Used for hover result strings that must outlive the temporary buffers.
fn dupeStr(self: *Self, s: []const u8) ?[]const u8 {
    // We use a simple static buffer approach since hover results are small and short-lived.
    // The caller will use this string before the next request.
    _ = self;
    // Return a pointer into a static buffer that persists until next call.
    const Static = struct {
        var buf: [4096]u8 = undefined;
    };
    if (s.len > Static.buf.len) return null;
    @memcpy(Static.buf[0..s.len], s);
    return Static.buf[0..s.len];
}
