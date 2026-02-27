//! C header import via libclang.
//!
//! Parses C header code using libclang and generates synthetic
//! `extern fn` AST declarations for each C function found.

const std = @import("std");
const Ast = @import("Ast.zig");
const InternPool = @import("InternPool.zig");
const Span = @import("Span.zig");

const c = @cImport({
    @cInclude("clang-c/Index.h");
});

const CImport = @This();

/// Process a c_import string and return synthetic extern fn declarations.
pub fn processCImport(
    header_code: []const u8,
    arena: std.mem.Allocator,
    pool: *InternPool,
) ![]Ast.Decl {
    // Create libclang index
    const index = c.clang_createIndex(0, 0);
    defer c.clang_disposeIndex(index);

    // Create null-terminated header code for libclang
    const code_z = try arena.dupeZ(u8, header_code);

    // Set up unsaved file so we don't need to write to disk
    var unsaved = c.CXUnsavedFile{
        .Filename = "input.h",
        .Contents = code_z.ptr,
        .Length = @intCast(header_code.len),
    };

    // System include paths for macOS
    const args = [_][*:0]const u8{
        "-isystem",
        "/usr/local/llvm/include",
        "-isystem",
        "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include",
        "-isystem",
        "/usr/local/include",
    };

    const tu = c.clang_parseTranslationUnit(
        index,
        "input.h",
        &args,
        args.len,
        @ptrCast(&unsaved),
        1,
        c.CXTranslationUnit_SkipFunctionBodies,
    );
    if (tu == null) {
        return error.CImportFailed;
    }
    defer c.clang_disposeTranslationUnit(tu);

    if (hasErrorDiagnostics(tu)) {
        return error.CImportFailed;
    }

    // Walk top-level declarations
    var ctx = VisitorContext{
        .decls = .empty,
        .arena = arena,
        .pool = pool,
    };

    const cursor = c.clang_getTranslationUnitCursor(tu);
    _ = c.clang_visitChildren(cursor, visitCallback, @ptrCast(&ctx));

    // Best-effort translation for simple object-like macros:
    //   #define NAME 123
    //   #define NAME "text"
    // Function-like macros are intentionally skipped here.
    try processSimpleDefineMacros(&ctx, header_code);

    return ctx.decls.items;
}

fn hasErrorDiagnostics(tu: c.CXTranslationUnit) bool {
    const count = c.clang_getNumDiagnostics(tu);
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        const diag = c.clang_getDiagnostic(tu, i);
        defer c.clang_disposeDiagnostic(diag);
        const sev = c.clang_getDiagnosticSeverity(diag);
        if (sev == c.CXDiagnostic_Error or sev == c.CXDiagnostic_Fatal) {
            return true;
        }
    }
    return false;
}

const VisitorContext = struct {
    decls: std.ArrayList(Ast.Decl),
    arena: std.mem.Allocator,
    pool: *InternPool,
};

fn processSimpleDefineMacros(ctx: *VisitorContext, header_code: []const u8) !void {
    var lines = std.mem.splitScalar(u8, header_code, '\n');
    while (lines.next()) |raw_line| {
        var line = std.mem.trim(u8, raw_line, " \t\r");
        if (!std.mem.startsWith(u8, line, "#define ")) continue;
        line = line["#define ".len..];
        line = std.mem.trimLeft(u8, line, " \t");
        if (line.len == 0) continue;

        // Parse macro name.
        var name_end: usize = 0;
        while (name_end < line.len and isMacroNameChar(line[name_end])) : (name_end += 1) {}
        if (name_end == 0) continue;
        const name = line[0..name_end];
        // Skip function-like macros: NAME(...)
        if (name_end < line.len and line[name_end] == '(') continue;

        var value = std.mem.trimLeft(u8, line[name_end..], " \t");
        if (value.len == 0) continue;
        value = trimOuterParens(value);

        if (parseMacroInt(value)) |int_val| {
            const expr = try ctx.arena.create(Ast.Expr);
            expr.* = .{
                .kind = .{ .int_literal = int_val },
                .span = Span.zero,
            };
            const name_sym = try ctx.pool.intern(name);
            try ctx.decls.append(ctx.arena, .{
                .kind = .{ .let_decl = .{
                    .name = name_sym,
                    .type_expr = null,
                    .value = expr,
                    .is_mut = false,
                    .is_pub = .private,
                } },
                .span = Span.zero,
            });
            continue;
        }

        if (value.len >= 2 and value[0] == '"' and value[value.len - 1] == '"') {
            const inner = value[1 .. value.len - 1];
            const str_sym = try ctx.pool.intern(inner);
            const expr = try ctx.arena.create(Ast.Expr);
            expr.* = .{
                .kind = .{ .string_literal = str_sym },
                .span = Span.zero,
            };
            const name_sym = try ctx.pool.intern(name);
            try ctx.decls.append(ctx.arena, .{
                .kind = .{ .let_decl = .{
                    .name = name_sym,
                    .type_expr = null,
                    .value = expr,
                    .is_mut = false,
                    .is_pub = .private,
                } },
                .span = Span.zero,
            });
            continue;
        }
    }
}

fn isMacroNameChar(ch: u8) bool {
    return (ch >= 'A' and ch <= 'Z') or
        (ch >= 'a' and ch <= 'z') or
        (ch >= '0' and ch <= '9') or
        ch == '_';
}

fn trimOuterParens(value: []const u8) []const u8 {
    var v = std.mem.trim(u8, value, " \t");
    while (v.len >= 2 and v[0] == '(' and v[v.len - 1] == ')') {
        v = std.mem.trim(u8, v[1 .. v.len - 1], " \t");
    }
    return v;
}

fn parseMacroInt(value: []const u8) ?i64 {
    if (value.len == 0) return null;
    if (std.mem.startsWith(u8, value, "0x") or std.mem.startsWith(u8, value, "0X")) {
        return std.fmt.parseInt(i64, value, 0) catch null;
    }
    return std.fmt.parseInt(i64, value, 10) catch null;
}

fn visitCallback(
    cursor: c.CXCursor,
    parent: c.CXCursor,
    client_data: c.CXClientData,
) callconv(.c) c.enum_CXChildVisitResult {
    _ = parent;
    const ctx: *VisitorContext = @ptrCast(@alignCast(client_data));

    const kind = c.clang_getCursorKind(cursor);
    if (kind == c.CXCursor_FunctionDecl) {
        processFunctionDecl(ctx, cursor) catch {};
    }
    if (kind == c.CXCursor_EnumDecl) {
        processEnumDecl(ctx, cursor) catch {};
    }

    return c.CXChildVisit_Continue;
}

fn processFunctionDecl(ctx: *VisitorContext, cursor: c.CXCursor) !void {
    // Get function name
    const name_cx = c.clang_getCursorSpelling(cursor);
    defer c.clang_disposeString(name_cx);
    const name_cstr = c.clang_getCString(name_cx);
    if (name_cstr == null) return;
    const name_slice = std.mem.span(name_cstr);
    if (name_slice.len == 0) return;

    // Skip compiler builtins and internal functions
    if (name_slice.len > 1 and name_slice[0] == '_') {
        // Allow a few well-known underscore functions
        if (!std.mem.eql(u8, name_slice, "_exit")) return;
    }

    const fn_type = c.clang_getCursorType(cursor);

    // Get return type
    const ret_type_cx = c.clang_getResultType(fn_type);
    const ret_type_expr = mapCType(ctx.arena, ctx.pool, ret_type_cx) catch return;

    // Get parameters
    const num_args = c.clang_Cursor_getNumArguments(cursor);
    if (num_args < 0) return;
    const n: u32 = @intCast(num_args);

    var params: std.ArrayList(Ast.Param) = .empty;
    try params.ensureTotalCapacity(ctx.arena, n);

    for (0..n) |i| {
        const arg_cursor = c.clang_Cursor_getArgument(cursor, @intCast(i));
        const arg_type = c.clang_getCursorType(arg_cursor);

        const param_type_expr = mapCType(ctx.arena, ctx.pool, arg_type) catch return;

        // Get parameter name (or generate one)
        const arg_name_cx = c.clang_getCursorSpelling(arg_cursor);
        defer c.clang_disposeString(arg_name_cx);
        const arg_name_cstr = c.clang_getCString(arg_name_cx);
        const arg_name: []const u8 = if (arg_name_cstr != null and std.mem.span(arg_name_cstr).len > 0)
            std.mem.span(arg_name_cstr)
        else blk: {
            var buf: [16]u8 = undefined;
            const generated = std.fmt.bufPrint(&buf, "p{d}", .{i}) catch "p";
            break :blk generated;
        };

        const param_sym = try ctx.pool.intern(arg_name);

        const type_on_heap = try ctx.arena.create(Ast.TypeExpr);
        type_on_heap.* = param_type_expr;

        try params.append(ctx.arena, .{
            .name = param_sym,
            .type_expr = type_on_heap,
            .is_mut = false,
            .span = Span.zero,
        });
    }

    // Check variadic
    const is_variadic = c.clang_isFunctionTypeVariadic(fn_type) != 0;

    const fn_name_sym = try ctx.pool.intern(name_slice);

    // Build return type expr on heap
    const ret_on_heap: ?*const Ast.TypeExpr = if (ret_type_expr.kind == .named) blk: {
        // Check if it's void
        const sym_name = ctx.pool.resolve(ret_type_expr.kind.named);
        if (std.mem.eql(u8, sym_name, "void")) {
            break :blk null; // No return type annotation for void
        }
        const heap = try ctx.arena.create(Ast.TypeExpr);
        heap.* = ret_type_expr;
        break :blk heap;
    } else blk: {
        const heap = try ctx.arena.create(Ast.TypeExpr);
        heap.* = ret_type_expr;
        break :blk heap;
    };

    try ctx.decls.append(ctx.arena, .{
        .kind = .{ .extern_fn = .{
            .name = fn_name_sym,
            .params = params.items,
            .return_type = ret_on_heap,
            .is_variadic = is_variadic,
        } },
        .span = Span.zero,
    });
}

fn processEnumDecl(ctx: *VisitorContext, cursor: c.CXCursor) !void {
    // Visit each enum constant child and create a let_decl for it.
    _ = c.clang_visitChildren(cursor, enumConstantVisitor, @ptrCast(ctx));
}

fn enumConstantVisitor(
    cursor: c.CXCursor,
    parent: c.CXCursor,
    client_data: c.CXClientData,
) callconv(.c) c.enum_CXChildVisitResult {
    _ = parent;
    const ctx: *VisitorContext = @ptrCast(@alignCast(client_data));

    const kind = c.clang_getCursorKind(cursor);
    if (kind != c.CXCursor_EnumConstantDecl) return c.CXChildVisit_Continue;

    const name_cx = c.clang_getCursorSpelling(cursor);
    defer c.clang_disposeString(name_cx);
    const name_cstr = c.clang_getCString(name_cx);
    if (name_cstr == null) return c.CXChildVisit_Continue;
    const name_slice = std.mem.span(name_cstr);
    if (name_slice.len == 0) return c.CXChildVisit_Continue;

    const val = c.clang_getEnumConstantDeclValue(cursor);

    const expr = ctx.arena.create(Ast.Expr) catch return c.CXChildVisit_Continue;
    expr.* = .{
        .kind = .{ .int_literal = @intCast(val) },
        .span = Span.zero,
    };
    const name_sym = ctx.pool.intern(name_slice) catch return c.CXChildVisit_Continue;
    ctx.decls.append(ctx.arena, .{
        .kind = .{ .let_decl = .{
            .name = name_sym,
            .type_expr = null,
            .value = expr,
            .is_mut = false,
            .is_pub = .private,
        } },
        .span = Span.zero,
    }) catch return c.CXChildVisit_Continue;

    return c.CXChildVisit_Continue;
}

const MapError = error{ UnsupportedType, OutOfMemory };

/// Map a libclang CXType to a With TypeExpr.
fn mapCType(arena: std.mem.Allocator, pool: *InternPool, cx_type: c.CXType) MapError!Ast.TypeExpr {
    // Resolve through typedefs and elaborated types to the canonical form
    const canonical = c.clang_getCanonicalType(cx_type);
    const type_kind = canonical.kind;

    return switch (type_kind) {
        c.CXType_Void => makeNamedType(pool, "void"),
        c.CXType_Bool => makeNamedType(pool, "bool"),
        c.CXType_Char_S, c.CXType_SChar => makeNamedType(pool, "i8"),
        c.CXType_Char_U, c.CXType_UChar => makeNamedType(pool, "u8"),
        c.CXType_Short => makeNamedType(pool, "i16"),
        c.CXType_UShort => makeNamedType(pool, "u16"),
        c.CXType_Int => makeNamedType(pool, "i32"),
        c.CXType_UInt => makeNamedType(pool, "u32"),
        c.CXType_Long, c.CXType_LongLong => makeNamedType(pool, "i64"),
        c.CXType_ULong, c.CXType_ULongLong => makeNamedType(pool, "u64"),
        c.CXType_Float => makeNamedType(pool, "f32"),
        c.CXType_Double, c.CXType_LongDouble => makeNamedType(pool, "f64"),
        c.CXType_Pointer => mapPointerType(arena, pool, canonical),
        c.CXType_Enum => {
            // C enums are integers. Map to the underlying integer type.
            const decl = c.clang_getTypeDeclaration(canonical);
            const int_type = c.clang_getEnumDeclIntegerType(decl);
            return mapCType(arena, pool, int_type);
        },
        else => error.UnsupportedType,
    };
}

fn mapPointerType(arena: std.mem.Allocator, pool: *InternPool, cx_type: c.CXType) MapError!Ast.TypeExpr {
    const pointee = c.clang_getPointeeType(cx_type);
    const pointee_canonical = c.clang_getCanonicalType(pointee);

    // char* / const char* → *const i8
    if (pointee_canonical.kind == c.CXType_Char_S or
        pointee_canonical.kind == c.CXType_SChar or
        pointee_canonical.kind == c.CXType_Char_U or
        pointee_canonical.kind == c.CXType_UChar)
    {
        const inner = try arena.create(Ast.TypeExpr);
        inner.* = try makeNamedType(pool, "i8");
        return .{
            .kind = .{ .ptr_type = .{ .is_mut = false, .pointee = inner } },
            .span = Span.zero,
        };
    }

    // void* → *const i8 (opaque pointer, treat like C's void*)
    if (pointee_canonical.kind == c.CXType_Void) {
        const inner = try arena.create(Ast.TypeExpr);
        inner.* = try makeNamedType(pool, "i8");
        return .{
            .kind = .{ .ptr_type = .{ .is_mut = false, .pointee = inner } },
            .span = Span.zero,
        };
    }

    // Function pointer: void(*)(int, float) → fn(i32, f32) -> void
    if (pointee_canonical.kind == c.CXType_FunctionProto or
        pointee_canonical.kind == c.CXType_FunctionNoProto)
    {
        return mapFunctionPointerType(arena, pool, pointee_canonical);
    }

    // Try to map the pointee type recursively
    const pointee_type = mapCType(arena, pool, pointee) catch {
        // Fall back to *const i8 for unmappable pointee types (structs, etc.)
        const inner = try arena.create(Ast.TypeExpr);
        inner.* = try makeNamedType(pool, "i8");
        return .{
            .kind = .{ .ptr_type = .{ .is_mut = false, .pointee = inner } },
            .span = Span.zero,
        };
    };

    const inner = try arena.create(Ast.TypeExpr);
    inner.* = pointee_type;
    return .{
        .kind = .{ .ptr_type = .{ .is_mut = false, .pointee = inner } },
        .span = Span.zero,
    };
}

fn mapFunctionPointerType(arena: std.mem.Allocator, pool: *InternPool, cx_type: c.CXType) MapError!Ast.TypeExpr {
    // Get return type.
    const ret_cx = c.clang_getResultType(cx_type);
    const ret_mapped = try mapCType(arena, pool, ret_cx);
    const ret_heap = try arena.create(Ast.TypeExpr);
    ret_heap.* = ret_mapped;

    // Get parameter types.
    const num_args = c.clang_getNumArgTypes(cx_type);
    const n: u32 = if (num_args < 0) 0 else @intCast(num_args);

    var params: std.ArrayList(*const Ast.TypeExpr) = .empty;
    try params.ensureTotalCapacity(arena, n);

    for (0..n) |i| {
        const arg_cx = c.clang_getArgType(cx_type, @intCast(i));
        const arg_mapped = try mapCType(arena, pool, arg_cx);
        const arg_heap = try arena.create(Ast.TypeExpr);
        arg_heap.* = arg_mapped;
        try params.append(arena, arg_heap);
    }

    return .{
        .kind = .{ .fn_type = .{
            .params = params.items,
            .return_type = ret_heap,
        } },
        .span = Span.zero,
    };
}

fn makeNamedType(pool: *InternPool, name: []const u8) MapError!Ast.TypeExpr {
    return .{
        .kind = .{ .named = try pool.intern(name) },
        .span = Span.zero,
    };
}
