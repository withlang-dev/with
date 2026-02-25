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

const Parser = @This();

tokens: *const Token.List,
pos: u32,
arena: std.mem.Allocator,
pool: *InternPool,
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

    while (self.peek() != .eof) {
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
        else => {
            self.emitError("expected declaration (fn, type, let, use, extern)");
            return error.ParseError;
        },
    };
}

fn parseFnDecl(self: *Parser, is_pub: Ast.Visibility, start_span: Span, is_async: bool) !Ast.Decl {
    try self.expect(.kw_fn);
    const name = try self.expectIdentifier();
    try self.expect(.l_paren);
    const params = try self.parseParamList();
    try self.expect(.r_paren);

    var return_type: ?*const Ast.TypeExpr = null;
    if (self.peek() == .arrow) {
        self.advance();
        return_type = try self.parseTypeExpr();
    }

    try self.expect(.eq);
    self.skipNewlines();
    const body = try self.parseExpr();

    return .{
        .kind = .{ .function = .{
            .name = name,
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
        } },
        .span = start_span.merge(if (return_type) |rt| rt.span else end_span),
    };
}

fn parseTypeDecl(self: *Parser, is_pub: Ast.Visibility, start_span: Span) !Ast.Decl {
    try self.expect(.kw_type);
    const name = try self.expectIdentifier();
    try self.expect(.eq);

    // Peek to determine struct vs enum vs alias.
    const kind: Ast.TypeDeclKind = if (self.peek() == .kw_fn or self.peek() == .identifier or self.peek() == .ampersand or self.peek() == .l_paren)
        .{ .alias = try self.parseTypeExpr() }
    else
        // TODO: Parse struct and enum bodies.
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

fn parseUseDecl(self: *Parser, start_span: Span) !Ast.Decl {
    try self.expect(.kw_use);
    var path: std.ArrayList(Ast.Symbol) = .empty;
    try path.append(self.arena, try self.expectIdentifier());
    while (self.peek() == .dot) {
        self.advance();
        try path.append(self.arena, try self.expectIdentifier());
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
    return self.parsePrecedence(0);
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
            .kind = if (op_info.is_pipeline)
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
        .pipe_gt => .{ .op = .add, .prec = 5, .is_pipeline = true }, // op unused for pipeline
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
        .kw_if => return self.parseIfExpr(),
        .kw_return => return self.parseReturn(),
        .kw_let, .kw_var => return self.parseLetBinding(),
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
        .kind = .{ .int_literal = std.fmt.parseInt(i64, text, 10) catch 0 },
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
                const field = try self.expectIdentifier();
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
    self.skipNewlines();
    if (self.peek() == .kw_else) {
        self.advance();
        self.skipNewlines();
        else_body = try self.parseExpr();
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
    if (self.peek() == .r_paren) return params.items;

    try params.append(self.arena, try self.parseParam());
    while (self.peek() == .comma) {
        self.advance();
        self.skipNewlines();
        if (self.peek() == .r_paren) break;
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
