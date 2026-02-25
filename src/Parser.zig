//! Recursive descent parser: tokens → AST.
//!
//! The parser consumes a `Token.List` and produces an `Ast.Module`.
//! All AST nodes are arena-allocated.  On parse errors, the parser
//! emits a diagnostic and recovers by skipping to the next top-level
//! declaration.

const std = @import("std");
const Token = @import("Token.zig");
const Ast = @import("Ast.zig");
const Span = @import("Span.zig");
const Diagnostic = @import("Diagnostic.zig");
const InternPool = @import("InternPool.zig");
const Lexer = @import("Lexer.zig");

const Parser = @This();

tokens: *const Token.List,
pos: u32,
arena: std.mem.Allocator,
pool: *InternPool,
/// When true, `as` in postfix position is not consumed (used by `with` parsing).
suppress_as: bool = false,
diagnostics: *Diagnostic.DiagnosticList,
source: []const u8,

pub fn init(
    tokens: *const Token.List,
    source: []const u8,
    arena: std.mem.Allocator,
    pool: *InternPool,
    diagnostics: *Diagnostic.DiagnosticList,
) Parser {
    return .{
        .tokens = tokens,
        .pos = 0,
        .arena = arena,
        .pool = pool,
        .diagnostics = diagnostics,
        .source = source,
    };
}

// ── Public API ───────────────────────────────────────────────────

/// Parse the full token stream as a module (sequence of top-level declarations).
pub fn parseModule(self: *Parser) !Ast.Module {
    var decls: std.ArrayList(Ast.Decl) = .empty;
    self.skipNewlines();

    // Skip optional `module name.subname` declaration at file top
    if (self.peek() == .kw_module) {
        self.advance();
        if (self.peek() == .identifier) self.advance();
        while (self.peek() == .dot) {
            self.advance();
            if (self.peek() == .identifier) self.advance();
        }
        self.skipNewlines();
    }

    while (self.peek() != .eof) {
        if (self.peek() == .kw_pub) {
            // Check for `pub impl` or `pub trait`
            const saved_pos = self.pos;
            self.advance(); // skip pub
            if (self.peek() == .kw_impl) {
                const impl_decls = self.parseImplBlock(.public) catch {
                    self.recoverToTopLevel();
                    continue;
                };
                for (impl_decls) |d| try decls.append(self.arena, d);
                self.skipNewlines();
                continue;
            }
            if (self.peek() == .kw_trait) {
                const trait_decl = self.parseTraitDecl(.public) catch {
                    self.recoverToTopLevel();
                    continue;
                };
                try decls.append(self.arena, trait_decl);
                self.skipNewlines();
                continue;
            }
            self.pos = saved_pos; // backtrack
        } else if (self.peek() == .kw_impl or self.peek() == .kw_extend) {
            const impl_decls = self.parseImplBlock(.private) catch {
                self.recoverToTopLevel();
                continue;
            };
            for (impl_decls) |d| try decls.append(self.arena, d);
            self.skipNewlines();
            continue;
        } else if (self.peek() == .kw_trait) {
            const trait_decl = self.parseTraitDecl(.private) catch {
                self.recoverToTopLevel();
                continue;
            };
            try decls.append(self.arena, trait_decl);
            self.skipNewlines();
            continue;
        }

        const decl = self.parseDecl() catch {
            self.recoverToTopLevel();
            continue;
        };
        try decls.append(self.arena, decl);
        self.skipNewlines();
    }

    return .{
        .decls = decls.items,
        .span = if (decls.items.len > 0)
            decls.items[0].span.merge(decls.items[decls.items.len - 1].span)
        else
            Span.zero,
    };
}

// ── Declaration parsing ──────────────────────────────────────────

fn parseDecl(self: *Parser) !Ast.Decl {
    var is_pub = Ast.Visibility.private;
    const start_span = self.currentSpan();

    if (self.peek() == .kw_pub) {
        is_pub = .public;
        self.advance();
    }

    return switch (self.peek()) {
        .kw_fn => self.parseFnDecl(is_pub, start_span, false),
        .kw_async => blk: {
            self.advance();
            break :blk self.parseFnDecl(is_pub, start_span, true);
        },
        .kw_type => self.parseTypeDecl(is_pub, start_span),
        .kw_use => self.parseUseDecl(start_span),
        .kw_let, .kw_var => self.parseTopLevelLet(is_pub, start_span),
        .kw_extern => self.parseExternDecl(start_span),
        .kw_error => blk: {
            // Skip `error Name = ...` declaration block
            self.advance(); // consume 'error'
            _ = try self.expectIdentifier(); // error name
            try self.expect(.eq);
            self.skipNewlines();
            // Skip indented variant lines
            while (self.peek() != .eof) {
                const col = Lexer.columnOf(self.source, self.currentSpan().start);
                if (col == 0) break;
                // Skip tokens until newline
                while (self.peek() != .newline and self.peek() != .eof) {
                    self.advance();
                }
                self.skipNewlines();
            }
            break :blk .{ .kind = .poisoned, .span = start_span.merge(self.prevSpan()) };
        },
        else => {
            self.emitError("expected declaration (fn, type, let, use, extern)");
            return error.ParseError;
        },
    };
}

fn parseTraitDecl(self: *Parser, vis: Ast.Visibility) !Ast.Decl {
    const start_span = self.currentSpan();
    if (self.peek() == .kw_pub) self.advance();
    try self.expect(.kw_trait);
    const name = try self.expectIdentifier();
    try self.expect(.eq);
    self.skipNewlines();

    var methods: std.ArrayList(Ast.TraitMethodSig) = .empty;

    // Parse trait body — indented fn signatures.
    while (self.peek() == .kw_fn or self.peek() == .kw_pub) {
        const fn_col = Lexer.columnOf(self.source, self.currentSpan().start);
        if (fn_col == 0) break;

        const method_start = self.currentSpan();
        if (self.peek() == .kw_pub) self.advance();
        try self.expect(.kw_fn);
        const method_name = try self.expectIdentifier();

        try self.expect(.l_paren);
        const params = try self.parseParamList();
        try self.expect(.r_paren);

        var return_type: ?*const Ast.TypeExpr = null;
        if (self.peek() == .arrow) {
            self.advance();
            return_type = try self.parseTypeExpr();
        }

        // Check for default body (= ...)
        var has_default = false;
        if (self.peek() == .eq) {
            has_default = true;
            // Skip the default body
            self.advance();
            self.skipNewlines();
            // Skip indented body tokens
            while (self.peek() != .eof and self.peek() != .newline) {
                self.advance();
            }
        }

        try methods.append(self.arena, .{
            .name = method_name,
            .params = params,
            .return_type = return_type,
            .has_default = has_default,
            .span = method_start.merge(self.prevSpan()),
        });

        self.skipNewlines();
    }

    return .{
        .kind = .{ .trait_decl = .{
            .name = name,
            .methods = methods.items,
            .is_pub = vis,
        } },
        .span = start_span.merge(self.prevSpan()),
    };
}

fn parseImplBlock(self: *Parser, vis: Ast.Visibility) ![]const Ast.Decl {
    const start_span = self.currentSpan();
    if (self.peek() == .kw_pub) self.advance(); // skip pub (already consumed in caller)
    // Accept both `impl` and `extend`.
    if (self.peek() == .kw_impl) {
        self.advance();
    } else if (self.peek() == .kw_extend) {
        self.advance();
    } else {
        return error.ParseError;
    }
    const first_name = try self.expectIdentifier();

    // Check for `impl Trait for Type` syntax.
    var trait_name: ?Ast.Symbol = null;
    var type_name = first_name;
    if (self.peek() == .kw_for) {
        self.advance(); // consume 'for'
        trait_name = first_name;
        type_name = try self.expectIdentifier();
    }

    // Accept either `=` or newline for extend blocks.
    if (self.peek() == .eq) {
        self.advance();
    }
    self.skipNewlines();

    var methods: std.ArrayList(Ast.Decl) = .empty;
    var method_names: std.ArrayList(Ast.Symbol) = .empty;

    // Parse indented method definitions.
    // Methods start with `fn` at a deeper indentation.
    while (self.peek() == .kw_fn or self.peek() == .kw_pub or self.peek() == .kw_async) {
        // Check if this fn is indented (i.e., part of the impl block).
        const fn_col = Lexer.columnOf(self.source, self.currentSpan().start);
        if (fn_col == 0) break; // Back to top level — not part of impl
        var method_vis = vis;
        const method_start = self.currentSpan();
        if (self.peek() == .kw_pub) {
            method_vis = .public;
            self.advance();
        }
        var is_async = false;
        if (self.peek() == .kw_async) {
            is_async = true;
            self.advance();
        }
        try self.expect(.kw_fn);
        const method_name_sym = try self.expectIdentifier();

        // Mangle as "Type.method"
        const type_str = self.pool.resolve(type_name);
        const method_str = self.pool.resolve(method_name_sym);
        var buf: [512]u8 = undefined;
        const mangled_name = if (type_str.len + 1 + method_str.len < buf.len) blk: {
            @memcpy(buf[0..type_str.len], type_str);
            buf[type_str.len] = '.';
            @memcpy(buf[type_str.len + 1 ..][0..method_str.len], method_str);
            break :blk self.pool.intern(buf[0 .. type_str.len + 1 + method_str.len]) catch return error.ParseError;
        } else return error.ParseError;

        // Parse optional type parameters
        var type_params: std.ArrayList(u32) = .empty;
        if (self.peek() == .l_bracket) {
            self.advance();
            try type_params.append(self.arena, try self.expectIdentifier());
            while (self.peek() == .comma) {
                self.advance();
                try type_params.append(self.arena, try self.expectIdentifier());
            }
            try self.expect(.r_bracket);
        }

        try self.expect(.l_paren);
        const params = try self.parseParamList();
        try self.expect(.r_paren);

        var return_type: ?*const Ast.TypeExpr = null;
        if (self.peek() == .arrow) {
            self.advance();
            return_type = try self.parseTypeExpr();
        }

        try self.expect(.eq);
        const body = try self.parseBlockOrExpr();

        try method_names.append(self.arena, mangled_name);
        try methods.append(self.arena, .{
            .kind = .{ .function = .{
                .name = mangled_name,
                .type_params = type_params.items,
                .params = params,
                .return_type = return_type,
                .body = body,
                .is_async = is_async,
                .is_pub = method_vis,
            } },
            .span = method_start.merge(body.span),
        });

        self.skipNewlines();
    }

    // Emit an impl_decl to record the trait-type relationship.
    try methods.append(self.arena, .{
        .kind = .{ .impl_decl = .{
            .trait_name = trait_name,
            .type_name = type_name,
            .method_names = method_names.items,
        } },
        .span = start_span.merge(self.prevSpan()),
    });

    return methods.items;
}

fn parseFnDecl(self: *Parser, is_pub: Ast.Visibility, start_span: Span, is_async: bool) !Ast.Decl {
    try self.expect(.kw_fn);
    var name = try self.expectIdentifier();
    // Support method syntax: `fn Type.method(...)` → mangled name `Type.method`
    if (self.peek() == .dot) {
        self.advance(); // consume '.'
        const method_name = try self.expectIdentifier();
        // Mangle as "Type.method" by interning the combined name.
        const type_str = self.pool.resolve(name);
        const method_str = self.pool.resolve(method_name);
        var buf: [512]u8 = undefined;
        if (type_str.len + 1 + method_str.len < buf.len) {
            @memcpy(buf[0..type_str.len], type_str);
            buf[type_str.len] = '.';
            @memcpy(buf[type_str.len + 1 ..][0..method_str.len], method_str);
            name = self.pool.intern(buf[0 .. type_str.len + 1 + method_str.len]) catch return error.ParseError;
        }
    }
    // Parse optional type parameters: fn foo[T, U](...)
    var type_params: std.ArrayList(u32) = .empty;
    if (self.peek() == .l_bracket) {
        self.advance();
        try type_params.append(self.arena, try self.expectIdentifier());
        while (self.peek() == .comma) {
            self.advance();
            try type_params.append(self.arena, try self.expectIdentifier());
        }
        try self.expect(.r_bracket);
    }

    try self.expect(.l_paren);
    const params = try self.parseParamList();
    try self.expect(.r_paren);

    var return_type: ?*const Ast.TypeExpr = null;
    if (self.peek() == .arrow) {
        self.advance();
        return_type = try self.parseTypeExpr();
    }

    try self.expect(.eq);
    const body = try self.parseBlockOrExpr();

    return .{
        .kind = .{ .function = .{
            .name = name,
            .type_params = type_params.items,
            .params = params,
            .return_type = return_type,
            .body = body,
            .is_async = is_async,
            .is_pub = is_pub,
        } },
        .span = start_span.merge(body.span),
    };
}

fn parseExternDecl(self: *Parser, start_span: Span) !Ast.Decl {
    try self.expect(.kw_extern);
    try self.expect(.kw_fn);
    const name = try self.expectIdentifier();
    try self.expect(.l_paren);
    const params = try self.parseParamList();
    // Check for variadic `...`
    var is_variadic = false;
    if (self.peek() == .dot_dot_dot) {
        is_variadic = true;
        self.advance();
    }
    try self.expect(.r_paren);

    var return_type: ?*const Ast.TypeExpr = null;
    const end_span = self.currentSpan();
    if (self.peek() == .arrow) {
        self.advance();
        return_type = try self.parseTypeExpr();
    }

    return .{
        .kind = .{ .extern_fn = .{
            .name = name,
            .params = params,
            .return_type = return_type,
            .is_variadic = is_variadic,
        } },
        .span = start_span.merge(if (return_type) |rt| rt.span else end_span),
    };
}

fn parseTypeDecl(self: *Parser, is_pub: Ast.Visibility, start_span: Span) !Ast.Decl {
    try self.expect(.kw_type);
    const name = try self.expectIdentifier();
    try self.expect(.eq);
    self.skipNewlines();

    // Peek to determine struct vs enum vs alias.
    // Enum syntax: `type Color = Red | Green | Blue`
    //          or: `type Shape = | Circle(f64) | Rect(f64, f64)`
    //          or: `type Shape =\n    | Circle(f64)\n    | Rect(f64, f64)`
    const kind: Ast.TypeDeclKind = if (self.peek() == .l_brace)
        .{ .struct_def = try self.parseStructBody() }
    else if (self.peek() == .pipe)
        .{ .enum_def = try self.parseEnumVariants() }
    else if (self.peek() == .identifier and self.isEnumDef())
        .{ .enum_def = try self.parseEnumVariants() }
    else if (self.peek() == .kw_fn or self.peek() == .identifier or self.peek() == .ampersand or self.peek() == .l_paren)
        .{ .alias = try self.parseTypeExpr() }
    else
        return error.ParseError;

    return .{
        .kind = .{ .type_decl = .{
            .name = name,
            .kind = kind,
            .is_pub = is_pub,
        } },
        .span = start_span.merge(self.prevSpan()),
    };
}

fn parseStructBody(self: *Parser) ![]const Ast.FieldDef {
    try self.expect(.l_brace);
    self.skipNewlines();
    var fields: std.ArrayList(Ast.FieldDef) = .empty;

    while (self.peek() != .r_brace and self.peek() != .eof) {
        const field_start = self.currentSpan();
        const field_name = try self.expectIdentifier();
        try self.expect(.colon);
        const field_type = try self.parseTypeExpr();

        // Optional default value: `field: Type = expr`
        var default_val: ?*const Ast.Expr = null;
        if (self.peek() == .eq) {
            self.advance();
            self.skipNewlines();
            default_val = try self.parseExpr();
        }

        try fields.append(self.arena, .{
            .name = field_name,
            .type_expr = field_type,
            .default = default_val,
            .span = field_start.merge(if (default_val) |d| d.span else field_type.span),
        });

        self.skipNewlines();
        if (self.peek() == .comma) {
            self.advance();
            self.skipNewlines();
        }
    }

    try self.expect(.r_brace);
    return fields.items;
}

/// Look ahead to determine if this is an enum def (Identifier followed by pipe or lparen+pipe).
fn isEnumDef(self: *Parser) bool {
    // Save position and look ahead past the first identifier.
    const saved_pos = self.pos;
    defer self.pos = saved_pos;
    self.advance(); // skip the identifier
    self.skipNewlines();
    // If next is `|` → enum inline: `Red | Green`
    if (self.peek() == .pipe) return true;
    // If next is `(` → variant with data: `Circle(f64)` — then look for `|` after.
    if (self.peek() == .l_paren) {
        // Skip to matching `)`.
        self.advance();
        var depth: u32 = 1;
        while (depth > 0 and self.peek() != .eof) {
            if (self.peek() == .l_paren) depth += 1;
            if (self.peek() == .r_paren) depth -= 1;
            self.advance();
        }
        self.skipNewlines();
        if (self.peek() == .pipe) return true;
    }
    return false;
}

fn parseEnumVariants(self: *Parser) ![]const Ast.VariantDef {
    var variants: std.ArrayList(Ast.VariantDef) = .empty;

    // Skip optional leading `|`
    if (self.peek() == .pipe) {
        self.advance();
        self.skipNewlines();
    }

    while (self.peek() == .identifier) {
        const variant_start = self.currentSpan();
        const variant_name = try self.expectIdentifier();

        var payload: ?[]const *const Ast.TypeExpr = null;
        if (self.peek() == .l_paren) {
            self.advance(); // skip '('
            var types: std.ArrayList(*const Ast.TypeExpr) = .empty;
            while (self.peek() != .r_paren and self.peek() != .eof) {
                try types.append(self.arena, try self.parseTypeExpr());
                if (self.peek() == .comma) {
                    self.advance();
                    self.skipNewlines();
                }
            }
            try self.expect(.r_paren);
            payload = types.items;
        }

        try variants.append(self.arena, .{
            .name = variant_name,
            .payload = payload,
            .span = variant_start.merge(self.prevSpan()),
        });

        self.skipNewlines();
        if (self.peek() == .pipe) {
            self.advance();
            self.skipNewlines();
        } else {
            break;
        }
    }

    return variants.items;
}

fn parseUseDecl(self: *Parser, start_span: Span) !Ast.Decl {
    try self.expect(.kw_use);

    // use c_import("...") — C header import
    if (self.peek() == .kw_c_import) {
        self.advance(); // consume c_import
        try self.expect(.l_paren);
        if (self.peek() != .string_literal) {
            self.emitError("expected string literal after c_import(");
            return error.ParseError;
        }
        const str_span = self.currentSpan();
        // Extract string content without quotes
        const raw = self.source[str_span.start .. str_span.end];
        const unquoted = if (raw.len >= 2 and raw[0] == '"' and raw[raw.len - 1] == '"')
            raw[1 .. raw.len - 1]
        else
            raw;
        // Process escape sequences (especially \n for multi-include strings)
        const header_code = self.processEscapes(unquoted) catch unquoted;
        self.advance(); // consume string literal
        try self.expect(.r_paren);
        return .{
            .kind = .{ .c_import = .{ .header_code = header_code } },
            .span = start_span.merge(self.prevSpan()),
        };
    }

    var path: std.ArrayList(Ast.Symbol) = .empty;

    // Consume an identifier (could be regular .identifier or .dot_identifier stripped of dot)
    if (self.peek() == .identifier) {
        const ident = try self.expectIdentifier();
        try path.append(self.arena, ident);
    }

    // Consume dotted path segments: use foo.bar.Baz
    while (true) {
        if (self.peek() == .dot) {
            self.advance();
            if (self.peek() == .identifier) {
                try path.append(self.arena, try self.expectIdentifier());
            } else if (self.peek() == .star) {
                // use foo.bar.* — glob import
                self.advance();
                break;
            } else if (self.peek() == .l_brace) {
                // use foo.bar.{A, B} — skip brace group
                self.advance();
                while (self.peek() != .r_brace and self.peek() != .eof and self.peek() != .newline) {
                    self.advance();
                }
                if (self.peek() == .r_brace) self.advance();
                break;
            } else {
                break;
            }
        } else if (self.peek() == .dot_identifier) {
            // .HashMap gets lexed as dot_identifier because of uppercase;
            // treat it as a path segment in use declarations
            const span = self.currentSpan();
            // The dot_identifier includes the leading dot, so text is ".HashMap"
            // We want just "HashMap", so skip the first byte
            const text = self.source[span.start + 1 .. span.end];
            try path.append(self.arena, try self.pool.intern(text));
            self.advance();
        } else {
            break;
        }
    }

    // Skip any remaining tokens on this line (handles unknown function-call-like syntax)
    if (self.peek() == .l_paren) {
        var depth: u32 = 1;
        self.advance();
        while (depth > 0 and self.peek() != .eof) {
            if (self.peek() == .l_paren) depth += 1;
            if (self.peek() == .r_paren) depth -= 1;
            self.advance();
        }
    }

    return .{
        .kind = .{ .use_decl = .{ .path = path.items } },
        .span = start_span.merge(self.prevSpan()),
    };
}

fn parseTopLevelLet(self: *Parser, is_pub: Ast.Visibility, start_span: Span) !Ast.Decl {
    const is_mut = self.peek() == .kw_var;
    self.advance(); // consume let/var
    const name = try self.expectIdentifier();

    var type_expr: ?*const Ast.TypeExpr = null;
    if (self.peek() == .colon) {
        self.advance();
        type_expr = try self.parseTypeExpr();
    }

    try self.expect(.eq);
    self.skipNewlines();
    const value = try self.parseExpr();

    return .{
        .kind = .{ .let_decl = .{
            .name = name,
            .type_expr = type_expr,
            .value = value,
            .is_mut = is_mut,
            .is_pub = is_pub,
        } },
        .span = start_span.merge(value.span),
    };
}

// ── Expression parsing (Pratt-style precedence climbing) ─────────

fn parseExpr(self: *Parser) error{ ParseError, OutOfMemory }!*const Ast.Expr {
    const lhs = try self.parsePrecedence(0);

    // Check for assignment: `lhs = rhs`
    if (self.peek() == .eq) {
        self.advance();
        self.skipNewlines();
        const rhs = try self.parseExpr(); // right-associative
        const node = try self.arena.create(Ast.Expr);
        node.* = .{
            .kind = .{ .assign = .{ .target = lhs, .value = rhs } },
            .span = lhs.span.merge(rhs.span),
        };
        return node;
    }

    // Check for compound assignment: `lhs += rhs` → `lhs = lhs + rhs`
    if (self.compoundAssignOp()) |bin_op| {
        self.advance();
        self.skipNewlines();
        const rhs = try self.parseExpr();

        // Build the binary operation: lhs op rhs
        const bin_node = try self.arena.create(Ast.Expr);
        bin_node.* = .{
            .kind = .{ .binary = .{ .op = bin_op, .lhs = lhs, .rhs = rhs } },
            .span = lhs.span.merge(rhs.span),
        };

        // Wrap in assignment: lhs = (lhs op rhs)
        const node = try self.arena.create(Ast.Expr);
        node.* = .{
            .kind = .{ .assign = .{ .target = lhs, .value = bin_node } },
            .span = lhs.span.merge(rhs.span),
        };
        return node;
    }

    return lhs;
}

fn compoundAssignOp(self: *const Parser) ?Ast.BinOp {
    return switch (self.peek()) {
        .plus_eq => .add,
        .minus_eq => .sub,
        .star_eq => .mul,
        .slash_eq => .div,
        .percent_eq => .mod,
        else => null,
    };
}

fn parsePrecedence(self: *Parser, min_prec: u8) !*const Ast.Expr {
    var lhs = try self.parsePrimary();

    while (true) {
        const op_info = self.infixOp() orelse break;
        if (op_info.prec < min_prec) break;
        self.advance();
        self.skipNewlines();
        const rhs = try self.parsePrecedence(op_info.prec + 1);

        const node = try self.arena.create(Ast.Expr);
        node.* = .{
            .kind = if (op_info.is_range)
                .{ .range = .{ .start = lhs, .end = rhs, .inclusive = op_info.inclusive } }
            else if (op_info.is_pipeline)
                .{ .pipeline = .{ .lhs = lhs, .rhs = rhs } }
            else
                .{ .binary = .{ .op = op_info.op, .lhs = lhs, .rhs = rhs } },
            .span = lhs.span.merge(rhs.span),
        };
        lhs = node;
    }

    return lhs;
}

const InfixInfo = struct {
    op: Ast.BinOp,
    prec: u8,
    is_pipeline: bool = false,
    is_range: bool = false,
    inclusive: bool = false,
};

fn infixOp(self: *const Parser) ?InfixInfo {
    return switch (self.peek()) {
        .kw_or => .{ .op = .@"or", .prec = 1 },
        .kw_and => .{ .op = .@"and", .prec = 2 },
        .eq_eq => .{ .op = .eq, .prec = 3 },
        .bang_eq => .{ .op = .neq, .prec = 3 },
        .lt => .{ .op = .lt, .prec = 4 },
        .gt => .{ .op = .gt, .prec = 4 },
        .lt_eq => .{ .op = .lte, .prec = 4 },
        .gt_eq => .{ .op = .gte, .prec = 4 },
        .dot_dot => .{ .op = .add, .prec = 5, .is_range = true }, // op unused for range
        .dot_dot_eq => .{ .op = .add, .prec = 5, .is_range = true, .inclusive = true },
        .pipe_gt => .{ .op = .add, .prec = 6, .is_pipeline = true }, // op unused for pipeline
        .lt_lt => .{ .op = .shl, .prec = 6 },
        .gt_gt => .{ .op = .shr, .prec = 6 },
        .ampersand => .{ .op = .bit_and, .prec = 7 },
        .caret => .{ .op = .bit_xor, .prec = 8 },
        .pipe => .{ .op = .bit_or, .prec = 9 },
        .question_question => .{ .op = .default_op, .prec = 10 },
        .plus => .{ .op = .add, .prec = 11 },
        .minus => .{ .op = .sub, .prec = 11 },
        .plus_wrap => .{ .op = .add_wrap, .prec = 11 },
        .minus_wrap => .{ .op = .sub_wrap, .prec = 11 },
        .star => .{ .op = .mul, .prec = 12 },
        .slash => .{ .op = .div, .prec = 12 },
        .percent => .{ .op = .mod, .prec = 12 },
        .star_wrap => .{ .op = .mul_wrap, .prec = 12 },
        else => null,
    };
}

fn parsePrimary(self: *Parser) !*const Ast.Expr {
    const tag = self.peek();
    switch (tag) {
        .int_literal => return self.parseIntLiteral(),
        .float_literal => return self.parseFloatLiteral(),
        .string_literal => return self.parseStringLiteral(),
        .true_literal, .false_literal => return self.parseBoolLiteral(),
        .identifier => return self.parseIdentOrCall(),
        .dot_identifier => return self.parseVariantShorthand(),
        .l_paren => return self.parseGroupedOrTuple(),
        .minus => return self.parseUnaryNegate(),
        .kw_not => return self.parseUnaryNot(),
        .ampersand => return self.parseRefOf(),
        .star => return self.parseDerefExpr(),
        .kw_if => return self.parseIfExpr(),
        .kw_while => return self.parseWhile(),
        .kw_loop => return self.parseLoop(),
        .kw_for => return self.parseFor(),
        .kw_return => return self.parseReturn(),
        .kw_break => return self.parseBreak(),
        .kw_continue => return self.parseContinue(),
        .kw_defer => return self.parseDefer(),
        .l_bracket => return self.parseArrayLiteral(),
        .kw_let, .kw_var => return self.parseLetBinding(),
        .kw_match => return self.parseMatchExpr(),
        .kw_with => return self.parseWithExpr(),
        .l_brace => return self.parseRecordUpdate(),
        .pipe => return self.parseClosure(),
        else => {
            self.emitError("expected expression");
            return error.ParseError;
        },
    }
}

fn parseIntLiteral(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    const text = self.source[span.start..span.end];
    self.advance();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .int_literal = std.fmt.parseInt(i64, text, 0) catch 0 },
        .span = span,
    };
    return node;
}

fn parseFloatLiteral(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    const text = self.source[span.start..span.end];
    self.advance();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .float_literal = std.fmt.parseFloat(f64, text) catch 0.0 },
        .span = span,
    };
    return node;
}

fn parseStringLiteral(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    // Strip quotes from the source text for the interned symbol.
    const raw = self.source[span.start + 1 .. span.end -| 1];
    const sym = try self.pool.intern(raw);
    self.advance();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .string_literal = sym },
        .span = span,
    };
    return node;
}

fn parseBoolLiteral(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    const val = self.peek() == .true_literal;
    self.advance();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .bool_literal = val },
        .span = span,
    };
    return node;
}

fn parseIdentOrCall(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    const sym = try self.internCurrent();
    self.advance();

    const lhs_node = try self.arena.create(Ast.Expr);
    lhs_node.* = .{
        .kind = .{ .ident = sym },
        .span = span,
    };

    return self.parsePostfix(lhs_node);
}

fn parsePostfix(self: *Parser, lhs_in: *const Ast.Expr) !*const Ast.Expr {
    var lhs = lhs_in;
    while (true) {
        switch (self.peek()) {
            .l_paren => {
                self.advance();
                var args: std.ArrayList(*const Ast.Expr) = .empty;
                if (self.peek() != .r_paren) {
                    try args.append(self.arena, try self.parseExpr());
                    while (self.peek() == .comma) {
                        self.advance();
                        self.skipNewlines();
                        try args.append(self.arena, try self.parseExpr());
                    }
                }
                const end = self.currentSpan();
                try self.expect(.r_paren);
                const node = try self.arena.create(Ast.Expr);
                node.* = .{
                    .kind = .{ .call = .{
                        .callee = lhs,
                        .args = args.items,
                    } },
                    .span = lhs.span.merge(end),
                };
                lhs = node;
            },
            .dot => {
                self.advance();
                // Handle tuple field access: `.0`, `.1`, etc.
                const field = if (self.peek() == .int_literal) blk: {
                    const sym = try self.internCurrent();
                    self.advance();
                    break :blk sym;
                } else try self.expectIdentifier();
                const node = try self.arena.create(Ast.Expr);
                node.* = .{
                    .kind = .{ .field_access = .{
                        .expr = lhs,
                        .field = field,
                    } },
                    .span = lhs.span.merge(self.prevSpan()),
                };
                lhs = node;
            },
            .l_brace => {
                // Struct literal: `Name { field: expr, ... }`
                // Only when LHS is an identifier.
                if (lhs.kind != .ident) return lhs;
                const struct_name = lhs.kind.ident;
                self.advance(); // consume '{'
                self.skipNewlines();

                var fields: std.ArrayList(Ast.FieldInit) = .empty;
                while (self.peek() != .r_brace and self.peek() != .eof) {
                    const field_start = self.currentSpan();
                    const field_name = try self.expectIdentifier();

                    if (self.peek() == .colon) {
                        // Full form: `name: expr`
                        self.advance();
                        self.skipNewlines();
                        const value = try self.parseExpr();
                        try fields.append(self.arena, .{
                            .name = field_name,
                            .value = value,
                            .span = field_start.merge(value.span),
                        });
                    } else {
                        // Shorthand: `name` means `name: name`
                        const ident_node = try self.arena.create(Ast.Expr);
                        ident_node.* = .{
                            .kind = .{ .ident = field_name },
                            .span = field_start,
                        };
                        try fields.append(self.arena, .{
                            .name = field_name,
                            .value = ident_node,
                            .span = field_start,
                        });
                    }

                    self.skipNewlines();
                    if (self.peek() == .comma) {
                        self.advance();
                        self.skipNewlines();
                    }
                }

                const end = self.currentSpan();
                try self.expect(.r_brace);
                const node = try self.arena.create(Ast.Expr);
                node.* = .{
                    .kind = .{ .struct_literal = .{
                        .name = struct_name,
                        .fields = fields.items,
                    } },
                    .span = lhs.span.merge(end),
                };
                lhs = node;
            },
            .l_bracket => {
                self.advance();
                const index = try self.parseExpr();
                const end = self.currentSpan();
                try self.expect(.r_bracket);
                const node = try self.arena.create(Ast.Expr);
                node.* = .{
                    .kind = .{ .index = .{
                        .expr = lhs,
                        .index = index,
                    } },
                    .span = lhs.span.merge(end),
                };
                lhs = node;
            },
            .kw_as => {
                if (self.suppress_as) return lhs;
                self.advance();
                const target_type = try self.parseTypeExpr();
                const cast_node = try self.arena.create(Ast.Expr);
                cast_node.* = .{
                    .kind = .{ .cast = .{ .expr = lhs, .target_type = target_type } },
                    .span = lhs.span.merge(target_type.span),
                };
                lhs = cast_node;
            },
            .question => {
                // Postfix `?` — try operator (unwrap or early return).
                const end = self.currentSpan();
                self.advance();
                const node = try self.arena.create(Ast.Expr);
                node.* = .{
                    .kind = .{ .unary = .{ .op = .try_op, .operand = lhs } },
                    .span = lhs.span.merge(end),
                };
                lhs = node;
            },
            else => return lhs,
        }
    }
}

fn parseVariantShorthand(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    const text = self.source[span.start + 1 .. span.end];
    const sym = try self.pool.intern(text);
    self.advance();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .variant_shorthand = sym },
        .span = span,
    };
    return node;
}

fn parseGroupedOrTuple(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume (
    self.skipNewlines();

    if (self.peek() == .r_paren) {
        const end = self.currentSpan();
        self.advance();
        const node = try self.arena.create(Ast.Expr);
        node.* = .{
            .kind = .{ .tuple = &.{} },
            .span = start.merge(end),
        };
        return node;
    }

    const first = try self.parseExpr();
    if (self.peek() == .comma) {
        var elems: std.ArrayList(*const Ast.Expr) = .empty;
        try elems.append(self.arena, first);
        while (self.peek() == .comma) {
            self.advance();
            self.skipNewlines();
            if (self.peek() == .r_paren) break;
            try elems.append(self.arena, try self.parseExpr());
        }
        const end = self.currentSpan();
        try self.expect(.r_paren);
        const node = try self.arena.create(Ast.Expr);
        node.* = .{
            .kind = .{ .tuple = elems.items },
            .span = start.merge(end),
        };
        return node;
    }

    const end = self.currentSpan();
    try self.expect(.r_paren);
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .grouped = first },
        .span = start.merge(end),
    };
    return self.parsePostfix(node);
}

fn parseUnaryNegate(self: *Parser) error{ ParseError, OutOfMemory }!*const Ast.Expr {
    const span = self.currentSpan();
    self.advance();
    const operand = try self.parsePrimary();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .unary = .{ .op = .negate, .operand = operand } },
        .span = span.merge(operand.span),
    };
    return node;
}

fn parseUnaryNot(self: *Parser) error{ ParseError, OutOfMemory }!*const Ast.Expr {
    const span = self.currentSpan();
    self.advance();
    const operand = try self.parsePrimary();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .unary = .{ .op = .not, .operand = operand } },
        .span = span.merge(operand.span),
    };
    return node;
}

fn parseRefOf(self: *Parser) error{ ParseError, OutOfMemory }!*const Ast.Expr {
    const span = self.currentSpan();
    self.advance(); // consume '&'
    // Check for &mut
    const is_mut = self.peek() == .kw_mut;
    if (is_mut) {
        self.advance(); // consume 'mut'
    }
    const operand = try self.parsePrimary();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .unary = .{
            .op = if (is_mut) .mut_ref_of else .ref_of,
            .operand = operand,
        } },
        .span = span.merge(operand.span),
    };
    return node;
}

fn parseDerefExpr(self: *Parser) error{ ParseError, OutOfMemory }!*const Ast.Expr {
    const span = self.currentSpan();
    self.advance(); // consume '*'
    const operand = try self.parsePrimary();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .unary = .{ .op = .deref, .operand = operand } },
        .span = span.merge(operand.span),
    };
    return node;
}

fn parseIfExpr(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'if'
    self.skipNewlines();
    const cond = try self.parseExpr();

    if (self.peek() == .kw_then) {
        self.advance();
    } else if (self.peek() == .colon) {
        self.advance();
    }
    self.skipNewlines();

    const then_body = try self.parseExpr();
    var else_body: ?*const Ast.Expr = null;
    const save = self.pos;
    self.skipNewlines();
    if (self.peek() == .kw_else) {
        self.advance();
        self.skipNewlines();
        else_body = try self.parseExpr();
    } else {
        self.pos = save; // Don't consume newlines if no else clause.
    }

    const end_span = if (else_body) |eb| eb.span else then_body.span;
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .if_expr = .{
            .condition = cond,
            .then_body = then_body,
            .else_body = else_body,
        } },
        .span = start.merge(end_span),
    };
    return node;
}

fn parseReturn(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'return'
    var value: ?*const Ast.Expr = null;
    if (self.peek() != .newline and self.peek() != .eof and self.peek() != .r_paren and self.peek() != .r_brace) {
        value = try self.parseExpr();
    }
    const end = if (value) |v| v.span else start;
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .return_expr = value },
        .span = start.merge(end),
    };
    return node;
}

fn parseDefer(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'defer'
    const body = try self.parseExpr();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .defer_expr = body },
        .span = start.merge(body.span),
    };
    return node;
}

/// Parse `with expr as [mut] name: body` or `with expr as [mut] name,... : body`
fn parseWithExpr(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'with'
    self.skipNewlines();

    // Parse the source expression, suppressing 'as' in postfix position
    // so it's treated as the with-binding separator, not a type cast.
    self.suppress_as = true;
    const source = try self.parseExpr();
    self.suppress_as = false;

    // Expect 'as'.
    if (self.peek() != .kw_as) {
        self.emitError("expected 'as' in with expression");
        return error.ParseError;
    }
    self.advance(); // consume 'as'

    // Check for 'mut'.
    var is_mut = false;
    if (self.peek() == .kw_mut) {
        is_mut = true;
        self.advance();
    }

    // Parse binding name.
    const name = try self.expectIdentifier();

    // Expect ':' then body.
    if (self.peek() == .colon) {
        self.advance();
    }
    const body = try self.parseBlockOrExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .with_expr = .{
            .source = source,
            .name = name,
            .is_mut = is_mut,
            .body = body,
        } },
        .span = start.merge(body.span),
    };
    return node;
}

/// Parse `{ expr with field: val, ... }`
fn parseRecordUpdate(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume '{'
    self.skipNewlines();

    // Parse the source expression.
    const source = try self.parseExpr();

    // Expect 'with'.
    if (self.peek() != .kw_with) {
        self.emitError("expected 'with' in record update");
        return error.ParseError;
    }
    self.advance(); // consume 'with'
    self.skipNewlines();

    // Determine the struct type name from the source expression.
    const type_name: u32 = switch (source.kind) {
        .ident => |sym| sym,
        else => blk: {
            // For non-ident sources, use a placeholder — codegen will infer
            // from the source value's LLVM type.
            break :blk 0;
        },
    };

    // Parse field overrides.
    var fields: std.ArrayList(Ast.FieldInit) = .empty;
    while (self.peek() != .r_brace and self.peek() != .eof) {
        const field_start = self.currentSpan();
        const field_name = try self.expectIdentifier();
        try self.expect(.colon);
        self.skipNewlines();
        const value = try self.parseExpr();
        try fields.append(self.arena, .{
            .name = field_name,
            .value = value,
            .span = field_start.merge(value.span),
        });
        self.skipNewlines();
        if (self.peek() == .comma) {
            self.advance();
            self.skipNewlines();
        }
    }

    const end = self.currentSpan();
    try self.expect(.r_brace);
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .record_update = .{
            .source = source,
            .type_name = type_name,
            .fields = fields.items,
        } },
        .span = start.merge(end),
    };
    return node;
}

fn parseWhile(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'while'
    self.skipNewlines();
    const condition = try self.parseExpr();

    if (self.peek() == .colon) {
        self.advance();
    }

    const body = try self.parseBlockOrExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .while_expr = .{
            .condition = condition,
            .body = body,
        } },
        .span = start.merge(body.span),
    };
    return node;
}

fn parseLoop(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'loop'

    if (self.peek() == .colon) {
        self.advance();
    }

    const body = try self.parseBlockOrExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .loop_expr = body },
        .span = start.merge(body.span),
    };
    return node;
}

fn parseFor(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'for'
    self.skipNewlines();
    const binding = try self.expectIdentifier();
    try self.expect(.kw_in);
    self.skipNewlines();
    const iterable = try self.parseExpr();

    if (self.peek() == .colon) {
        self.advance();
    }

    const body = try self.parseBlockOrExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .for_expr = .{
            .binding = binding,
            .iterable = iterable,
            .body = body,
        } },
        .span = start.merge(body.span),
    };
    return node;
}

fn parseMatchExpr(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'match'
    self.skipNewlines();
    const subject = try self.parseExpr();
    self.skipNewlines();

    var arms: std.ArrayList(Ast.MatchArm) = .empty;

    // Parse arms: `pattern -> body` separated by newlines
    while (self.peek() != .eof) {
        // Check if we are still at a match arm (identifier, int literal, underscore, dot_identifier, true/false)
        const tag = self.peek();
        if (tag != .identifier and tag != .int_literal and
            tag != .dot_identifier and tag != .true_literal and tag != .false_literal and
            tag != .string_literal)
        {
            break;
        }

        const arm_start = self.currentSpan();
        const pattern = try self.parsePattern();

        try self.expect(.arrow);
        self.skipNewlines();

        const body = try self.parseBlockOrExpr();

        try arms.append(self.arena, .{
            .pattern = pattern,
            .body = body,
            .span = arm_start.merge(body.span),
        });

        // Skip newlines but restore position if we went past the match block
        const save = self.pos;
        self.skipNewlines();
        if (self.peek() == .eof) break;
        // Check if the next token could be a match arm
        const next_tag = self.peek();
        if (next_tag != .identifier and next_tag != .int_literal and
            next_tag != .dot_identifier and next_tag != .true_literal and next_tag != .false_literal and
            next_tag != .string_literal)
        {
            // Not an arm — restore position so outer block parser sees the newlines
            self.pos = save;
            break;
        }
    }

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .match_expr = .{
            .subject = subject,
            .arms = arms.items,
        } },
        .span = start.merge(self.prevSpan()),
    };
    return node;
}

fn parsePattern(self: *Parser) !Ast.Pattern {
    const span = self.currentSpan();
    switch (self.peek()) {
        .int_literal => {
            const text = self.source[span.start..span.end];
            self.advance();
            return .{
                .kind = .{ .int_literal = std.fmt.parseInt(i64, text, 0) catch 0 },
                .span = span,
            };
        },
        .true_literal => {
            self.advance();
            return .{ .kind = .{ .bool_literal = true }, .span = span };
        },
        .false_literal => {
            self.advance();
            return .{ .kind = .{ .bool_literal = false }, .span = span };
        },
        .string_literal => {
            const raw = self.source[span.start + 1 .. span.end -| 1];
            const sym = try self.pool.intern(raw);
            self.advance();
            return .{ .kind = .{ .string_literal = sym }, .span = span };
        },
        .identifier => {
            const name = try self.expectIdentifier();
            // Check for wildcard: `_`
            const name_str = self.pool.resolve(name);
            if (std.mem.eql(u8, name_str, "_")) {
                return .{ .kind = .wildcard, .span = span };
            }
            // Check if this is a variant pattern: `Name(bindings...)`
            if (self.peek() == .l_paren) {
                self.advance(); // skip '('
                var bindings: std.ArrayList(Ast.Symbol) = .empty;
                while (self.peek() != .r_paren and self.peek() != .eof) {
                    try bindings.append(self.arena, try self.expectIdentifier());
                    if (self.peek() == .comma) {
                        self.advance();
                        self.skipNewlines();
                    }
                }
                try self.expect(.r_paren);
                return .{
                    .kind = .{ .variant = .{
                        .name = name,
                        .bindings = bindings.items,
                    } },
                    .span = span.merge(self.prevSpan()),
                };
            }
            // Check if it's an uppercase identifier → unit variant pattern
            if (name_str.len > 0 and std.ascii.isUpper(name_str[0])) {
                return .{
                    .kind = .{ .variant = .{
                        .name = name,
                        .bindings = &.{},
                    } },
                    .span = span,
                };
            }
            // Otherwise it's a variable binding
            return .{ .kind = .{ .binding = name }, .span = span };
        },
        else => {
            self.emitError("expected pattern");
            return error.ParseError;
        },
    }
}

fn parseClosure(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    try self.expect(.pipe);

    var params: std.ArrayList(Ast.Symbol) = .empty;
    // Parse parameter names (no types for closures).
    while (self.peek() != .pipe and self.peek() != .eof) {
        try params.append(self.arena, try self.expectIdentifier());
        if (self.peek() == .comma) {
            self.advance();
            self.skipNewlines();
        }
    }
    try self.expect(.pipe);
    self.skipNewlines();

    const body = try self.parseExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .closure = .{
            .params = params.items,
            .body = body,
        } },
        .span = start.merge(body.span),
    };
    return node;
}

fn parseBreak(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    self.advance();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{ .kind = .break_expr, .span = span };
    return node;
}

fn parseContinue(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    self.advance();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{ .kind = .continue_expr, .span = span };
    return node;
}

fn parseLetBinding(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    const is_mut = self.peek() == .kw_var;
    self.advance();
    const name_sym = try self.expectIdentifier();

    var type_expr: ?*const Ast.TypeExpr = null;
    if (self.peek() == .colon) {
        self.advance();
        type_expr = try self.parseTypeExpr();
    }

    try self.expect(.eq);
    self.skipNewlines();
    const value = try self.parseExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .let_binding = .{
            .name = name_sym,
            .type_expr = type_expr,
            .value = value,
            .is_mut = is_mut,
        } },
        .span = start.merge(value.span),
    };
    return node;
}

fn parseArrayLiteral(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume '['
    self.skipNewlines();

    var elems: std.ArrayList(*const Ast.Expr) = .empty;
    if (self.peek() != .r_bracket) {
        try elems.append(self.arena, try self.parseExpr());
        while (self.peek() == .comma) {
            self.advance();
            self.skipNewlines();
            if (self.peek() == .r_bracket) break;
            try elems.append(self.arena, try self.parseExpr());
        }
    }

    const end = self.currentSpan();
    try self.expect(.r_bracket);
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .array_literal = elems.items },
        .span = start.merge(end),
    };
    return node;
}

// ── Block / indentation-sensitive body parsing ───────────────────

/// After `=` in a function declaration, parse either a single inline
/// expression or an indentation-based block of statements + tail expr.
fn parseBlockOrExpr(self: *Parser) !*const Ast.Expr {
    // Inline body: `fn f() -> i32 = 42`
    if (self.peek() != .newline) {
        return self.parseExpr();
    }

    // Multi-line block body.
    self.skipNewlines();
    if (self.peek() == .eof) {
        self.emitError("expected expression");
        return error.ParseError;
    }

    const block_col = Lexer.columnOf(self.source, self.currentSpan().start);

    var stmts: std.ArrayList(*const Ast.Expr) = .empty;
    var last_expr: *const Ast.Expr = try self.parseExpr();

    while (true) {
        // If not at a newline boundary, we're done (e.g. eof or
        // unexpected token — the last expr is the tail).
        if (self.peek() != .newline and self.peek() != .eof) break;
        if (self.peek() == .eof) break;

        // Save position so we can detect dedent without consuming.
        const save = self.pos;
        self.skipNewlines();

        if (self.peek() == .eof) break;

        const next_col = Lexer.columnOf(self.source, self.currentSpan().start);
        if (next_col < block_col) {
            // Dedented — restore position and stop.
            self.pos = save;
            break;
        }

        // Previous expression was a statement; continue parsing.
        try stmts.append(self.arena, last_expr);
        last_expr = try self.parseExpr();
    }

    // Single expression — return unwrapped.
    if (stmts.items.len == 0) {
        return last_expr;
    }

    // Build a block node.
    const start_span = stmts.items[0].span;
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .block = .{
            .stmts = stmts.items,
            .tail = last_expr,
        } },
        .span = start_span.merge(last_expr.span),
    };
    return node;
}

// ── Type expression parsing ──────────────────────────────────────

fn parseTypeExpr(self: *Parser) !*const Ast.TypeExpr {
    switch (self.peek()) {
        .ampersand => {
            const start = self.currentSpan();
            self.advance();
            const is_mut = self.peek() == .kw_mut;
            if (is_mut) self.advance();
            const pointee = try self.parseTypeExpr();
            const node = try self.arena.create(Ast.TypeExpr);
            node.* = .{
                .kind = .{ .ref_type = .{ .is_mut = is_mut, .pointee = pointee } },
                .span = start.merge(pointee.span),
            };
            return node;
        },
        .question => {
            const start = self.currentSpan();
            self.advance();
            const inner = try self.parseTypeExpr();
            const node = try self.arena.create(Ast.TypeExpr);
            node.* = .{
                .kind = .{ .optional = inner },
                .span = start.merge(inner.span),
            };
            return node;
        },
        .l_paren => {
            const start = self.currentSpan();
            self.advance();
            var types: std.ArrayList(*const Ast.TypeExpr) = .empty;
            if (self.peek() != .r_paren) {
                try types.append(self.arena, try self.parseTypeExpr());
                while (self.peek() == .comma) {
                    self.advance();
                    try types.append(self.arena, try self.parseTypeExpr());
                }
            }
            const end = self.currentSpan();
            try self.expect(.r_paren);
            const node = try self.arena.create(Ast.TypeExpr);
            node.* = .{
                .kind = .{ .tuple_type = types.items },
                .span = start.merge(end),
            };
            return node;
        },
        .kw_fn => {
            const start = self.currentSpan();
            self.advance();
            try self.expect(.l_paren);
            var params: std.ArrayList(*const Ast.TypeExpr) = .empty;
            if (self.peek() != .r_paren) {
                try params.append(self.arena, try self.parseTypeExpr());
                while (self.peek() == .comma) {
                    self.advance();
                    try params.append(self.arena, try self.parseTypeExpr());
                }
            }
            try self.expect(.r_paren);
            try self.expect(.arrow);
            const ret = try self.parseTypeExpr();
            const node = try self.arena.create(Ast.TypeExpr);
            node.* = .{
                .kind = .{ .fn_type = .{ .params = params.items, .return_type = ret } },
                .span = start.merge(ret.span),
            };
            return node;
        },
        .star => {
            const start = self.currentSpan();
            self.advance();
            var is_mut = false;
            if (self.peek() == .kw_mut) {
                is_mut = true;
                self.advance();
            } else if (self.peek() == .identifier) {
                const pspan = self.currentSpan();
                if (std.mem.eql(u8, self.source[pspan.start..pspan.end], "const")) {
                    self.advance();
                }
            }
            const pointee = try self.parseTypeExpr();
            const node = try self.arena.create(Ast.TypeExpr);
            node.* = .{
                .kind = .{ .ptr_type = .{ .is_mut = is_mut, .pointee = pointee } },
                .span = start.merge(pointee.span),
            };
            return node;
        },
        .l_bracket => {
            const start = self.currentSpan();
            self.advance(); // consume '['
            // Parse size as int literal.
            if (self.peek() != .int_literal) {
                self.emitError("expected array size");
                return error.ParseError;
            }
            const size_span = self.currentSpan();
            const size_text = self.source[size_span.start..size_span.end];
            const size = std.fmt.parseInt(u64, size_text, 10) catch {
                self.emitError("expected array size");
                return error.ParseError;
            };
            self.advance();
            try self.expect(.r_bracket);
            const element = try self.parseTypeExpr();
            const node = try self.arena.create(Ast.TypeExpr);
            node.* = .{
                .kind = .{ .array_type = .{ .size = size, .element = element } },
                .span = start.merge(element.span),
            };
            return node;
        },
        .identifier => {
            const span = self.currentSpan();
            const name_sym = try self.internCurrent();
            self.advance();

            if (self.peek() == .l_bracket) {
                self.advance();
                var args: std.ArrayList(*const Ast.TypeExpr) = .empty;
                try args.append(self.arena, try self.parseTypeExpr());
                while (self.peek() == .comma) {
                    self.advance();
                    try args.append(self.arena, try self.parseTypeExpr());
                }
                const end = self.currentSpan();
                try self.expect(.r_bracket);
                const node = try self.arena.create(Ast.TypeExpr);
                node.* = .{
                    .kind = .{ .generic = .{ .name = name_sym, .args = args.items } },
                    .span = span.merge(end),
                };
                return node;
            }

            const node = try self.arena.create(Ast.TypeExpr);
            node.* = .{
                .kind = .{ .named = name_sym },
                .span = span,
            };
            return node;
        },
        else => {
            self.emitError("expected type");
            return error.ParseError;
        },
    }
}

// ── Parameter list ───────────────────────────────────────────────

fn parseParamList(self: *Parser) ![]const Ast.Param {
    var params: std.ArrayList(Ast.Param) = .empty;
    if (self.peek() == .r_paren or self.peek() == .dot_dot_dot) return params.items;

    try params.append(self.arena, try self.parseParam());
    while (self.peek() == .comma) {
        self.advance();
        self.skipNewlines();
        if (self.peek() == .r_paren or self.peek() == .dot_dot_dot) break;
        try params.append(self.arena, try self.parseParam());
    }
    return params.items;
}

fn parseParam(self: *Parser) !Ast.Param {
    const start = self.currentSpan();
    const is_mut = self.peek() == .kw_mut;
    if (is_mut) self.advance();

    const name = try self.expectIdentifier();
    var type_expr: ?*const Ast.TypeExpr = null;
    if (self.peek() == .colon) {
        self.advance();
        type_expr = try self.parseTypeExpr();
    }
    return .{
        .name = name,
        .type_expr = type_expr,
        .is_mut = is_mut,
        .span = start.merge(self.prevSpan()),
    };
}

// ── Token helpers ────────────────────────────────────────────────

fn peek(self: *const Parser) Token.Tag {
    if (self.pos >= self.tokens.len()) return .eof;
    return self.tokens.tags.items[self.pos];
}

fn advance(self: *Parser) void {
    if (self.pos < self.tokens.len()) {
        self.pos += 1;
    }
}

fn currentSpan(self: *const Parser) Span {
    if (self.pos >= self.tokens.len()) return Span.zero;
    return self.tokens.spans.items[self.pos];
}

fn prevSpan(self: *const Parser) Span {
    if (self.pos == 0) return Span.zero;
    return self.tokens.spans.items[self.pos - 1];
}

fn expect(self: *Parser, expected: Token.Tag) !void {
    if (self.peek() != expected) {
        self.emitError(expected.name());
        return error.ParseError;
    }
    self.advance();
}

fn expectIdentifier(self: *Parser) !Ast.Symbol {
    if (self.peek() != .identifier) {
        self.emitError("expected identifier");
        return error.ParseError;
    }
    const sym = try self.internCurrent();
    self.advance();
    return sym;
}

fn internCurrent(self: *Parser) !Ast.Symbol {
    const span = self.currentSpan();
    const text = self.source[span.start..span.end];
    return self.pool.intern(text);
}

fn skipNewlines(self: *Parser) void {
    while (self.peek() == .newline or self.peek() == .comment) {
        self.advance();
    }
}

/// Process escape sequences in a string (for c_import header code).
fn processEscapes(self: *Parser, input: []const u8) ![]const u8 {
    // Quick check: if no backslashes, return as-is
    if (std.mem.indexOf(u8, input, "\\") == null) return input;

    var result: std.ArrayList(u8) = .empty;
    var i: usize = 0;
    while (i < input.len) {
        if (input[i] == '\\' and i + 1 < input.len) {
            switch (input[i + 1]) {
                'n' => {
                    try result.append(self.arena, '\n');
                    i += 2;
                },
                't' => {
                    try result.append(self.arena, '\t');
                    i += 2;
                },
                '\\' => {
                    try result.append(self.arena, '\\');
                    i += 2;
                },
                '"' => {
                    try result.append(self.arena, '"');
                    i += 2;
                },
                else => {
                    try result.append(self.arena, input[i]);
                    i += 1;
                },
            }
        } else {
            try result.append(self.arena, input[i]);
            i += 1;
        }
    }
    return result.items;
}

fn emitError(self: *Parser, expected: []const u8) void {
    _ = expected;
    self.diagnostics.emit(Diagnostic.err(
        "unexpected token",
        self.currentSpan(),
    ));
}

fn recoverToTopLevel(self: *Parser) void {
    while (self.peek() != .eof) {
        switch (self.peek()) {
            .kw_fn, .kw_type, .kw_use, .kw_let, .kw_var, .kw_pub, .kw_extern => return,
            else => self.advance(),
        }
    }
}
