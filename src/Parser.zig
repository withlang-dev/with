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
/// Pending `@[derive(...)]` trait names parsed from attributes that
/// apply to the next top-level type declaration.
pending_derive_traits: []const Ast.Symbol = &.{},
/// Pending function attributes from `@[tailrec]`, `@[inline]`, `@[noinline]`, `@[must_use]`.
pending_tailrec: bool = false,
pending_inline: bool = false,
pending_noinline: bool = false,
pending_must_use: bool = false,

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
        self.skipNewlines();
        self.skipAttributes();
        self.skipNewlines();
        if (self.peek() == .eof) break;

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

    // Derive attributes only apply to type declarations.
    if (self.peek() != .kw_type) {
        self.pending_derive_traits = &.{};
    }

    return switch (self.peek()) {
        .kw_fn => self.parseFnDecl(is_pub, start_span, false, false, false),
        .kw_comptime => blk: {
            self.advance(); // consume 'comptime'
            if (self.peek() != .kw_fn) {
                self.emitError("expected 'fn' after 'comptime'");
                return error.ParseError;
            }
            break :blk self.parseFnDecl(is_pub, start_span, false, false, true);
        },
        .kw_async => blk: {
            self.advance();
            break :blk self.parseFnDecl(is_pub, start_span, true, false, false);
        },
        .kw_gen => blk: {
            self.advance();
            break :blk self.parseFnDecl(is_pub, start_span, false, true, false);
        },
        .kw_type => self.parseTypeDecl(is_pub, start_span),
        .kw_use => self.parseUseDecl(start_span),
        .kw_let, .kw_var => self.parseTopLevelLet(is_pub, start_span),
        .kw_extern => self.parseExternDecl(start_span),
        .kw_error => blk: {
            // `error Name = Variant1, Variant2(payload), ...`
            // Desugars to `type Name = enum { ... }`
            self.advance(); // consume 'error'
            const err_name = try self.expectIdentifier();
            if (self.isIdentifierNamed("from")) {
                // `error AppError from IoError, ParseError` — desugar to wrapper enum.
                self.advance(); // consume 'from'

                var variants: std.ArrayList(Ast.VariantDef) = .empty;
                while (true) {
                    const src_start = self.currentSpan();
                    const src_sym = try self.expectIdentifier();
                    const src_span = self.prevSpan();

                    const src_ty = try self.arena.create(Ast.TypeExpr);
                    src_ty.* = .{
                        .kind = .{ .named = src_sym },
                        .span = src_span,
                    };

                    const src_name = self.pool.resolve(src_sym);
                    const suffix = "Error";
                    const variant_text = if (src_name.len > suffix.len and std.mem.endsWith(u8, src_name, suffix))
                        src_name[0 .. src_name.len - suffix.len]
                    else
                        src_name;
                    const variant_name = self.pool.intern(variant_text) catch return error.ParseError;

                    const payload = try self.arena.alloc(*const Ast.TypeExpr, 1);
                    payload[0] = src_ty;
                    try variants.append(self.arena, .{
                        .name = variant_name,
                        .payload = payload,
                        .span = src_start.merge(src_span),
                    });

                    if (self.peek() != .comma) break;
                    self.advance();
                    self.skipNewlines();
                }

                const variant_slice = try variants.toOwnedSlice(self.arena);
                break :blk .{
                    .kind = .{ .type_decl = .{
                        .name = err_name,
                        .kind = .{ .enum_def = variant_slice },
                        .is_pub = is_pub,
                    } },
                    .span = start_span.merge(self.prevSpan()),
                };
            }
            try self.expect(.eq);
            self.skipNewlines();

            // Parse variants (indented block or comma-separated).
            var variants: std.ArrayList(Ast.VariantDef) = .empty;
            while (self.peek() != .eof) {
                const col = Lexer.columnOf(self.source, self.currentSpan().start);
                if (col == 0) break; // back to top level

                if (self.peek() != .identifier) break;
                const v_start = self.currentSpan();
                const v_name = try self.expectIdentifier();

                // Optional payload: `Variant(Type1, Type2)`
                var payload: ?[]const *const Ast.TypeExpr = null;
                if (self.peek() == .l_paren) {
                    self.advance();
                    var payload_types: std.ArrayList(*const Ast.TypeExpr) = .empty;
                    while (self.peek() != .r_paren and self.peek() != .eof) {
                        if (payload_types.items.len > 0) {
                            try self.expect(.comma);
                        }
                        const ty = try self.parseTypeExpr();
                        try payload_types.append(self.arena, ty);
                    }
                    try self.expect(.r_paren);
                    payload = try payload_types.toOwnedSlice(self.arena);
                }

                try variants.append(self.arena, .{
                    .name = v_name,
                    .payload = payload,
                    .span = v_start.merge(self.prevSpan()),
                });

                // Skip comma or newline between variants.
                if (self.peek() == .comma) self.advance();
                self.skipNewlines();
            }

            const variant_slice = try variants.toOwnedSlice(self.arena);
            break :blk .{
                .kind = .{ .type_decl = .{
                    .name = err_name,
                    .kind = .{ .enum_def = variant_slice },
                    .is_pub = is_pub,
                } },
                .span = start_span.merge(self.prevSpan()),
            };
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
    var assoc_types: std.ArrayList(Ast.AssociatedType) = .empty;

    // Parse trait body — indented fn signatures and associated types.
    while (self.peek() == .kw_fn or self.peek() == .kw_pub or self.peek() == .kw_type or self.peek() == .kw_async) {
        const fn_col = Lexer.columnOf(self.source, self.currentSpan().start);
        if (fn_col == 0) break;

        // Parse associated type: `type Name` or `type Name: Bound` or `type Name = Default`
        if (self.peek() == .kw_type) {
            self.advance(); // consume 'type'
            const at_name = try self.expectIdentifier();
            var bounds: std.ArrayList(Ast.Symbol) = .empty;
            var default_type: ?*const Ast.TypeExpr = null;

            if (self.peek() == .colon) {
                self.advance(); // consume ':'
                try bounds.append(self.arena, try self.parseTypeBoundSymbol());
                while (self.peek() == .plus) {
                    self.advance();
                    try bounds.append(self.arena, try self.parseTypeBoundSymbol());
                }
            }
            if (self.peek() == .eq) {
                self.advance(); // consume '='
                default_type = try self.parseTypeExpr();
            }

            try assoc_types.append(self.arena, .{
                .name = at_name,
                .default = default_type,
                .bounds = bounds.items,
            });
            self.skipNewlines();
            continue;
        }

        const method_start = self.currentSpan();
        if (self.peek() == .kw_pub) self.advance();
        var is_async = false;
        if (self.peek() == .kw_async) {
            is_async = true;
            self.advance();
        }
        try self.expect(.kw_fn);
        const method_name = try self.expectIdentifier();
        var trait_method_tps = try self.parseTypeParams(); // generic trait methods parse here (object-safety checks are later)

        try self.expect(.l_paren);
        const params = try self.parseParamList(null);
        try self.expect(.r_paren);

        var return_type: ?*const Ast.TypeExpr = null;
        if (self.peek() == .arrow) {
            self.advance();
            return_type = try self.parseTypeExpr();
        }
        try self.parseOptionalWhereClause(&trait_method_tps);

        // Check for default body (= expr)
        var has_default = false;
        var default_body: ?*const Ast.Expr = null;
        if (self.peek() == .eq) {
            has_default = true;
            self.advance(); // consume =
            self.skipNewlines();
            default_body = try self.parseExpr();
        }

        try methods.append(self.arena, .{
            .name = method_name,
            .params = params,
            .return_type = return_type,
            .has_type_params = trait_method_tps.len > 0,
            .is_async = is_async,
            .has_default = has_default,
            .default_body = default_body,
            .span = method_start.merge(self.prevSpan()),
        });

        self.skipNewlines();
    }

    return .{
        .kind = .{ .trait_decl = .{
            .name = name,
            .methods = methods.items,
            .associated_types = assoc_types.items,
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
    var assoc_type_bindings: std.ArrayList(Ast.AssociatedTypeBinding) = .empty;

    // Parse indented method definitions and associated type bindings.
    // Methods start with `fn` at a deeper indentation.
    while (self.peek() == .kw_fn or self.peek() == .kw_pub or self.peek() == .kw_async or self.peek() == .kw_type) {
        // Check if this item is indented (i.e., part of the impl block).
        const fn_col = Lexer.columnOf(self.source, self.currentSpan().start);
        if (fn_col == 0) break; // Back to top level — not part of impl

        // Parse associated type binding: `type Name = TypeExpr`
        if (self.peek() == .kw_type) {
            self.advance(); // consume 'type'
            const at_name = try self.expectIdentifier();
            try self.expect(.eq);
            const at_type = try self.parseTypeExpr();
            try assoc_type_bindings.append(self.arena, .{
                .name = at_name,
                .type_expr = at_type,
            });
            self.skipNewlines();
            continue;
        }

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
        var type_params = try self.parseTypeParams();

        // Parse parameters: parens are optional for zero-param functions.
        var params: []const Ast.Param = &.{};
        if (self.peek() == .l_paren) {
            self.advance();
            params = try self.parseParamList(null);
            try self.expect(.r_paren);
        }

        var return_type: ?*const Ast.TypeExpr = null;
        if (self.peek() == .arrow) {
            self.advance();
            return_type = try self.parseTypeExpr();
        }
        try self.parseOptionalWhereClause(&type_params);

        // Accept either '=' or ':' as body introducer (v6.4: colon is idiomatic).
        if (self.peek() == .eq or self.peek() == .colon) {
            self.advance();
        } else {
            self.emitError("expected '=' or ':'");
            return error.ParseError;
        }
        const body = try self.parseBlockOrExpr();

        try method_names.append(self.arena, mangled_name);
        try methods.append(self.arena, .{
            .kind = .{ .function = .{
                .name = mangled_name,
                .type_params = type_params,
                .params = params,
                .return_type = return_type,
                .body = body,
                .is_async = is_async,
                .is_gen = false,
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
            .associated_types = assoc_type_bindings.items,
        } },
        .span = start_span.merge(self.prevSpan()),
    });

    return methods.items;
}

fn parseFnDecl(
    self: *Parser,
    is_pub: Ast.Visibility,
    start_span: Span,
    is_async: bool,
    is_gen: bool,
    is_comptime: bool,
) !Ast.Decl {
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
    // Parse optional type parameters: fn foo[T, U](...)  or  fn foo[T: Trait1 + Trait2](...)
    var type_params = try self.parseTypeParams();

    // Parse parameters: parens are optional for zero-param functions.
    var param_destructures: std.ArrayList(ParamDestructure) = .empty;
    var params: []const Ast.Param = &.{};
    if (self.peek() == .l_paren) {
        self.advance();
        params = try self.parseParamList(&param_destructures);
        try self.expect(.r_paren);
    }

    var return_type: ?*const Ast.TypeExpr = null;
    if (self.peek() == .arrow) {
        self.advance();
        return_type = try self.parseTypeExpr();
    }
    try self.parseOptionalWhereClause(&type_params);

    // Accept either '=' or ':' as body introducer (v6.4: colon is idiomatic).
    if (self.peek() == .eq or self.peek() == .colon) {
        self.advance();
    } else {
        self.emitError("expected '=' or ':'");
            return error.ParseError;
    }
    const raw_body = try self.parseBlockOrExpr();
    const body = try self.injectParamDestructures(raw_body, param_destructures.items);

    return .{
        .kind = .{ .function = .{
            .name = name,
            .type_params = type_params,
            .params = params,
            .return_type = return_type,
            .body = body,
            .is_async = is_async,
            .is_gen = is_gen,
            .is_comptime = is_comptime,
            .is_pub = is_pub,
            .is_tailrec = self.pending_tailrec,
            .is_inline = self.pending_inline,
            .is_noinline = self.pending_noinline,
            .is_must_use = self.pending_must_use,
        } },
        .span = start_span.merge(body.span),
    };
}

/// For parameter destructuring (`fn f({x, y}: Point) = ...`), inject
/// leading let-bindings that project fields from the synthetic param.
fn injectParamDestructures(
    self: *Parser,
    body: *const Ast.Expr,
    destructures: []const ParamDestructure,
) !*const Ast.Expr {
    if (destructures.len == 0) return body;

    var prefix_stmts: std.ArrayList(*const Ast.Expr) = .empty;
    for (destructures) |d| {
        switch (d.kind) {
            .struct_fields => |fields| {
                for (fields) |field| {
                    if (field.binding_name == 0) continue; // wildcard

                    const param_ident = try self.arena.create(Ast.Expr);
                    param_ident.* = .{
                        .kind = .{ .ident = d.param_name },
                        .span = d.span,
                    };

                    const field_access = try self.arena.create(Ast.Expr);
                    field_access.* = .{
                        .kind = .{ .field_access = .{
                            .expr = param_ident,
                            .field = field.field_name,
                        } },
                        .span = d.span,
                    };

                    const let_node = try self.arena.create(Ast.Expr);
                    let_node.* = .{
                        .kind = .{ .let_binding = .{
                            .name = field.binding_name,
                            .type_expr = null,
                            .value = field_access,
                            .is_mut = false,
                        } },
                        .span = d.span,
                    };
                    try prefix_stmts.append(self.arena, let_node);
                }
            },
            .tuple_pattern => |pat| {
                const param_ident = try self.arena.create(Ast.Expr);
                param_ident.* = .{
                    .kind = .{ .ident = d.param_name },
                    .span = d.span,
                };

                const tuple_node = try self.arena.create(Ast.Expr);
                tuple_node.* = .{
                    .kind = .{ .tuple_destructure = .{
                        .names = &.{},
                        .pattern = pat,
                        .value = param_ident,
                        .is_mut = false,
                    } },
                    .span = d.span,
                };
                try prefix_stmts.append(self.arena, tuple_node);
            },
        }
    }

    if (body.kind == .block) {
        const blk = body.kind.block;
        const merged = try self.arena.alloc(*const Ast.Expr, prefix_stmts.items.len + blk.stmts.len);
        @memcpy(merged[0..prefix_stmts.items.len], prefix_stmts.items);
        @memcpy(merged[prefix_stmts.items.len..], blk.stmts);

        const node = try self.arena.create(Ast.Expr);
        node.* = .{
            .kind = .{ .block = .{
                .stmts = merged,
                .tail = blk.tail,
            } },
            .span = if (merged.len > 0) merged[0].span.merge(body.span) else body.span,
        };
        return node;
    }

    const wrapped = try self.arena.create(Ast.Expr);
    wrapped.* = .{
        .kind = .{ .block = .{
            .stmts = prefix_stmts.items,
            .tail = body,
        } },
        .span = if (prefix_stmts.items.len > 0) prefix_stmts.items[0].span.merge(body.span) else body.span,
    };
    return wrapped;
}

fn parseExternDecl(self: *Parser, start_span: Span) !Ast.Decl {
    try self.expect(.kw_extern);
    try self.expect(.kw_fn);
    const name = try self.expectIdentifier();
    try self.expect(.l_paren);
    const params = try self.parseParamList(null);
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
    const derive_traits = self.pending_derive_traits;
    self.pending_derive_traits = &.{};

    try self.expect(.kw_type);
    const name = try self.expectIdentifier();
    var type_params = try self.parseTypeParams();
    try self.parseOptionalWhereClause(&type_params);
    try self.expect(.eq);
    self.skipNewlines();

    // Check for `ephemeral` qualifier before struct body.
    var is_ephemeral = false;
    if (self.peek() == .kw_ephemeral) {
        is_ephemeral = true;
        self.advance();
        self.skipNewlines();
    }

    // Peek to determine struct vs enum vs alias.
    // Enum syntax: `type Color = Red | Green | Blue`
    //          or: `type Shape = | Circle(f64) | Rect(f64, f64)`
    //          or: `type Shape =\n    | Circle(f64)\n    | Rect(f64, f64)`
    var kind: Ast.TypeDeclKind = undefined;
    var struct_fields: ?[]const Ast.FieldDef = null;
    if (self.peek() == .l_brace) {
        const fields = try self.parseStructBody();
        kind = .{ .struct_def = fields };
        struct_fields = fields;
    } else if (self.peek() == .pipe) {
        kind = .{ .enum_def = try self.parseEnumVariants() };
    } else if (self.peek() == .identifier and self.isEnumDef()) {
        kind = .{ .enum_def = try self.parseEnumVariants() };
    } else if (self.peek() == .identifier and self.isIdentifierNamed("distinct")) {
        // `type Name = distinct UnderlyingType`
        self.advance(); // consume 'distinct'
        kind = .{ .distinct = try self.parseTypeExpr() };
    } else if (self.peek() == .kw_fn or self.peek() == .identifier or self.peek() == .ampersand or self.peek() == .l_paren) {
        kind = .{ .alias = try self.parseTypeExpr() };
    } else {
        return error.ParseError;
    }

    if (struct_fields) |fields| {
        // Explicit derive(Copy) must reject obviously non-Copy fields.
        // derive(all) is intentionally not rejected here.
        if (self.hasDeriveTraitNamed(derive_traits, "Copy") and self.structHasObviouslyNonCopyField(fields)) {
            self.emitError("cannot derive Copy for a type with non-Copy fields");
            return error.ParseError;
        }
    }

    return .{
        .kind = .{ .type_decl = .{
            .name = name,
            .type_params = type_params,
            .kind = kind,
            .is_pub = is_pub,
            .derive_traits = derive_traits,
            .is_ephemeral = is_ephemeral,
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

        var link_libs: std.ArrayList(Ast.Symbol) = .empty;
        if (self.peek() == .comma) {
            self.advance(); // consume ','
            self.skipNewlines();

            if (self.peek() != .identifier) {
                self.emitError("expected 'link: \"lib\"' after c_import header string");
                return error.ParseError;
            }
            const arg_name = try self.expectIdentifier();
            if (!std.mem.eql(u8, self.pool.resolve(arg_name), "link")) {
                self.emitError("expected 'link:' named argument");
                return error.ParseError;
            }
            try self.expect(.colon);
            self.skipNewlines();

            if (self.peek() != .string_literal) {
                self.emitError("expected library string after 'link:'");
                return error.ParseError;
            }
            while (self.peek() == .string_literal) {
                const lib_span = self.currentSpan();
                const lib_raw = self.source[lib_span.start .. lib_span.end];
                const lib_unquoted = if (lib_raw.len >= 2 and lib_raw[0] == '"' and lib_raw[lib_raw.len - 1] == '"')
                    lib_raw[1 .. lib_raw.len - 1]
                else
                    lib_raw;
                const lib_name = self.processEscapes(lib_unquoted) catch lib_unquoted;
                try link_libs.append(self.arena, try self.pool.intern(lib_name));
                self.advance(); // consume string literal
                self.skipNewlines();
                if (self.peek() == .comma) {
                    const comma_pos = self.pos;
                    self.advance();
                    self.skipNewlines();
                    if (self.peek() == .string_literal) {
                        continue;
                    }
                    self.pos = comma_pos;
                }
                break;
            }
        }

        try self.expect(.r_paren);
        return .{
            .kind = .{ .c_import = .{
                .header_code = header_code,
                .link_libs = link_libs.items,
            } },
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

    if (path.items.len == 0) {
        self.emitError("expected import path after 'use'");
        return error.ParseError;
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
    const is_var = self.peek() == .kw_var;
    self.advance(); // consume let/var
    const is_mut = if (is_var) true else blk: {
        if (self.peek() == .kw_mut) {
            self.advance();
            break :blk true;
        }
        break :blk false;
    };
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

/// Parse an expression for use inside `[...]` brackets.
/// Uses higher min precedence (6) so that `..` (prec 5) is NOT consumed as a range.
fn parseIndexExpr(self: *Parser) error{ ParseError, OutOfMemory }!*const Ast.Expr {
    return self.parsePrecedence(6);
}

fn parsePrecedence(self: *Parser, min_prec: u8) !*const Ast.Expr {
    var lhs = try self.parsePrimary();

    while (true) {
        const op_info = self.infixOp() orelse break;
        if (op_info.prec < min_prec) break;
        self.advance();
        self.skipNewlines();

        // Special pipeline form: `value |> match ...`
        if (op_info.is_pipeline and !op_info.reverse_pipeline and self.peek() == .kw_match) {
            self.advance(); // consume `match`
            self.skipNewlines();
            const arms = try self.parseMatchArms();
            const node = try self.arena.create(Ast.Expr);
            node.* = .{
                .kind = .{ .match_expr = .{
                    .subject = lhs,
                    .arms = arms,
                } },
                .span = lhs.span.merge(if (arms.len > 0) arms[arms.len - 1].span else lhs.span),
            };
            lhs = node;
            continue;
        }

        const rhs_min_prec = if (op_info.op == .default_op or op_info.right_assoc) op_info.prec else op_info.prec + 1;
        const rhs = try self.parsePrecedence(rhs_min_prec);

        if (op_info.compose != .none) {
            lhs = try self.buildComposedClosure(lhs, rhs, op_info.compose);
            continue;
        }

        const node = try self.arena.create(Ast.Expr);
        node.* = .{
            .kind = if (op_info.is_range)
                .{ .range = .{ .start = lhs, .end = rhs, .inclusive = op_info.inclusive } }
            else if (op_info.is_pipeline)
                .{ .pipeline = .{
                    .lhs = if (op_info.reverse_pipeline) rhs else lhs,
                    .rhs = if (op_info.reverse_pipeline) lhs else rhs,
                } }
            else
                .{ .binary = .{ .op = op_info.op, .lhs = lhs, .rhs = rhs } },
            .span = lhs.span.merge(rhs.span),
        };
        lhs = node;
    }

    return lhs;
}

const ComposeKind = enum {
    none,
    forward, // f >> g  => |x| g(f(x))
    backward, // f << g => |x| f(g(x))
};

const InfixInfo = struct {
    op: Ast.BinOp,
    prec: u8,
    is_pipeline: bool = false,
    reverse_pipeline: bool = false,
    compose: ComposeKind = .none,
    is_range: bool = false,
    inclusive: bool = false,
    right_assoc: bool = false,
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
        .lt_pipe => .{ .op = .add, .prec = 6, .is_pipeline = true, .reverse_pipeline = true, .right_assoc = true },
        .lt_lt => .{ .op = .add, .prec = 6, .compose = .backward },
        .gt_gt => .{ .op = .add, .prec = 6, .compose = .forward },
        .ampersand => .{ .op = .bit_and, .prec = 7 },
        .caret => .{ .op = .bit_xor, .prec = 8 },
        .pipe => .{ .op = .bit_or, .prec = 9 },
        .question_question => .{ .op = .default_op, .prec = 10 },
        .plus => .{ .op = .add, .prec = 11 },
        .plus_plus => .{ .op = .concat, .prec = 11 },
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

fn buildComposedClosure(
    self: *Parser,
    lhs_fn: *const Ast.Expr,
    rhs_fn: *const Ast.Expr,
    compose: ComposeKind,
) !*const Ast.Expr {
    var sym_buf: [48]u8 = undefined;
    const sym_name = std.fmt.bufPrint(&sym_buf, "__pipe_arg_{d}", .{self.pos}) catch return error.ParseError;
    const param_sym = try self.pool.intern(sym_name);
    const param_expr = try self.arena.create(Ast.Expr);
    param_expr.* = .{
        .kind = .{ .ident = param_sym },
        .span = lhs_fn.span,
    };

    const first_callee = if (compose == .forward) lhs_fn else rhs_fn;
    const second_callee = if (compose == .forward) rhs_fn else lhs_fn;

    const first_args = try self.arena.alloc(*const Ast.Expr, 1);
    first_args[0] = param_expr;
    const first_call = try self.arena.create(Ast.Expr);
    first_call.* = .{
        .kind = .{ .call = .{
            .callee = first_callee,
            .args = first_args,
        } },
        .span = lhs_fn.span.merge(rhs_fn.span),
    };

    const second_args = try self.arena.alloc(*const Ast.Expr, 1);
    second_args[0] = first_call;
    const second_call = try self.arena.create(Ast.Expr);
    second_call.* = .{
        .kind = .{ .call = .{
            .callee = second_callee,
            .args = second_args,
        } },
        .span = lhs_fn.span.merge(rhs_fn.span),
    };

    const params = try self.arena.alloc(Ast.Symbol, 1);
    params[0] = param_sym;
    const closure = try self.arena.create(Ast.Expr);
    closure.* = .{
        .kind = .{ .closure = .{
            .params = params,
            .body = second_call,
        } },
        .span = lhs_fn.span.merge(rhs_fn.span),
    };
    return closure;
}

fn parsePrimary(self: *Parser) !*const Ast.Expr {
    const tag = self.peek();
    switch (tag) {
        .int_literal => return self.parseIntLiteral(),
        .float_literal => return self.parseFloatLiteral(),
        .string_literal => return self.parseStringLiteral(),
        .c_string_literal => return self.parseCStringLiteral(),
        .true_literal, .false_literal => return self.parseBoolLiteral(),
        .identifier => return self.parseIdentOrCall(),
        .dot_identifier => return self.parseVariantShorthand(),
        .l_paren => return self.parseGroupedOrTuple(),
        .minus => return self.parseUnaryNegate(),
        .kw_not => return self.parseUnaryNot(),
        .ampersand => return self.parseRefOf(),
        .star => return self.parseDerefExpr(),
        .kw_if => return self.parseIfExpr(),
        .kw_while => return self.parseWhile(null),
        .kw_loop => return self.parseLoop(null),
        .kw_for => return self.parseFor(null),
        .kw_return => return self.parseReturn(),
        .kw_break => return self.parseBreak(),
        .kw_continue => return self.parseContinue(),
        .label => return self.parseLabeledLoop(),
        .kw_unsafe => return self.parseUnsafe(),
        .kw_defer => return self.parseDefer(),
        .kw_spawn => return self.parseSpawn(),
        .kw_async => return self.parseAsyncExpr(),
        .kw_yield => return self.parseYield(),
        .kw_comptime => return self.parseComptime(),
        .kw_select => return self.parseSelectAwait(),
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
    // Strip type suffix (_i32, _u64, etc.) if present.
    const num_text = if (std.mem.lastIndexOf(u8, text, "_")) |idx| blk: {
        const after = text[idx + 1 ..];
        const suffixes = [_][]const u8{ "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64" };
        for (suffixes) |suf| {
            if (std.mem.eql(u8, after, suf)) break :blk text[0..idx];
        }
        break :blk text; // Not a type suffix, keep as-is (e.g. 1_000).
    } else text;
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .int_literal = std.fmt.parseInt(i64, num_text, 0) catch 0 },
        .span = span,
    };
    return node;
}

fn parseFloatLiteral(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    const text = self.source[span.start..span.end];
    self.advance();
    // Strip type suffix (_f32, _f64) if present.
    const num_text = if (std.mem.lastIndexOf(u8, text, "_")) |idx| blk: {
        const after = text[idx + 1 ..];
        if (std.mem.eql(u8, after, "f32") or std.mem.eql(u8, after, "f64")) {
            break :blk text[0..idx];
        }
        break :blk text;
    } else text;
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .float_literal = std.fmt.parseFloat(f64, num_text) catch 0.0 },
        .span = span,
    };
    return node;
}

fn parseStringLiteral(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    // Strip quotes from the source text for the interned symbol.
    // Handle triple-quoted strings: """..."""
    const text = self.source[span.start..span.end];
    const raw = if (text.len >= 6 and std.mem.startsWith(u8, text, "\"\"\""))
        // Strip """ delimiters and optional leading/trailing newlines.
        blk: {
            var content = text[3 .. text.len - 3];
            if (content.len > 0 and content[0] == '\n') {
                content = content[1..];
            }
            if (content.len > 0 and content[content.len - 1] == '\n') {
                content = content[0 .. content.len - 1];
            }
            break :blk content;
        }
    else
        // Strip single-quote delimiters.
        self.source[span.start + 1 .. span.end -| 1];
    const sym = try self.pool.intern(raw);
    self.advance();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .string_literal = sym },
        .span = span,
    };
    return self.parsePostfix(node);
}

fn parseCStringLiteral(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    // Strip c"..." delimiters: skip leading c" and trailing "
    const text = self.source[span.start..span.end];
    const raw = if (text.len >= 3) text[2 .. text.len - 1] else "";
    const sym = try self.pool.intern(raw);
    self.advance();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .c_string_literal = sym },
        .span = span,
    };
    return self.parsePostfix(node);
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

                // Check for partial application: if any arg is `_`, desugar to closure.
                var has_placeholder = false;
                for (args.items) |arg| {
                    if (arg.kind == .ident and std.mem.eql(u8, self.pool.resolve(arg.kind.ident), "_")) {
                        has_placeholder = true;
                        break;
                    }
                }

                if (has_placeholder) {
                    // Desugar f(a, _, b) → |__pa_0| f(a, __pa_0, b)
                    var closure_params: std.ArrayList(Ast.Symbol) = .empty;
                    var new_args: std.ArrayList(*const Ast.Expr) = .empty;
                    var param_counter: u32 = 0;
                    for (args.items) |arg| {
                        if (arg.kind == .ident and std.mem.eql(u8, self.pool.resolve(arg.kind.ident), "_")) {
                            var name_buf: [16]u8 = undefined;
                            const name_len = std.fmt.bufPrint(&name_buf, "__pa_{d}", .{param_counter}) catch unreachable;
                            const psym = self.pool.intern(name_len) catch return error.ParseError;
                            param_counter += 1;
                            try closure_params.append(self.arena, psym);
                            const param_ident = try self.arena.create(Ast.Expr);
                            param_ident.* = .{ .kind = .{ .ident = psym }, .span = arg.span };
                            try new_args.append(self.arena, param_ident);
                        } else {
                            try new_args.append(self.arena, arg);
                        }
                    }
                    const call_node = try self.arena.create(Ast.Expr);
                    call_node.* = .{
                        .kind = .{ .call = .{ .callee = lhs, .args = new_args.items } },
                        .span = lhs.span.merge(end),
                    };
                    const closure_node = try self.arena.create(Ast.Expr);
                    closure_node.* = .{
                        .kind = .{ .closure = .{ .params = closure_params.items, .body = call_node } },
                        .span = lhs.span.merge(end),
                    };
                    lhs = closure_node;
                } else {
                    const node = try self.arena.create(Ast.Expr);
                    node.* = .{
                        .kind = .{ .call = .{
                            .callee = lhs,
                            .args = args.items,
                        } },
                        .span = lhs.span.merge(end),
                    };
                    lhs = node;
                }
            },
            .dot => {
                self.advance();
                // Handle .await as postfix await expression.
                if (self.peek() == .kw_await) {
                    self.advance();
                    const node = try self.arena.create(Ast.Expr);
                    node.* = .{
                        .kind = .{ .await_expr = lhs },
                        .span = lhs.span.merge(self.prevSpan()),
                    };
                    lhs = node;
                    continue;
                }
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
                // Parse with precedence above range (..) so that 0..2 doesn't
                // get consumed as a range expression. Precedence 6 stops
                // before dot_dot (prec 5).
                const index = try self.parseIndexExpr();
                if (self.peek() == .dot_dot) {
                    // Slice expression: arr[start..end]
                    self.advance(); // consume '..'
                    var end_expr: ?*const Ast.Expr = null;
                    if (self.peek() != .r_bracket) {
                        end_expr = try self.parseExpr();
                    }
                    const end = self.currentSpan();
                    try self.expect(.r_bracket);
                    const node = try self.arena.create(Ast.Expr);
                    node.* = .{
                        .kind = .{ .slice = .{
                            .expr = lhs,
                            .start = index,
                            .end = end_expr,
                        } },
                        .span = lhs.span.merge(end),
                    };
                    lhs = node;
                } else {
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
                }
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
            .question_dot => {
                // Optional chaining: `opt?.field` / `opt?.method(args)`
                self.advance(); // consume '?.'
                const member = if (self.peek() == .int_literal) blk: {
                    const sym = try self.internCurrent();
                    self.advance();
                    break :blk sym;
                } else try self.expectIdentifier();
                var end = self.prevSpan();

                var args: ?[]const *const Ast.Expr = null;
                if (self.peek() == .l_paren) {
                    self.advance(); // consume '('
                    var parsed_args: std.ArrayList(*const Ast.Expr) = .empty;
                    self.skipNewlines();
                    if (self.peek() != .r_paren) {
                        while (true) {
                            try parsed_args.append(self.arena, try self.parseExpr());
                            self.skipNewlines();
                            if (self.peek() != .comma) break;
                            self.advance();
                            self.skipNewlines();
                        }
                    }
                    end = self.currentSpan();
                    try self.expect(.r_paren);
                    args = parsed_args.items;
                }

                const node = try self.arena.create(Ast.Expr);
                node.* = .{
                    .kind = .{ .optional_chain = .{
                        .expr = lhs,
                        .member = member,
                        .args = args,
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

    // Check for payload: .Variant(args...)
    var args: std.ArrayList(*const Ast.Expr) = .empty;
    if (self.peek() == .l_paren) {
        self.advance(); // consume '('
        while (self.peek() != .r_paren and self.peek() != .eof) {
            try args.append(self.arena, try self.parseExpr());
            if (self.peek() == .comma) {
                self.advance();
                self.skipNewlines();
            }
        }
        try self.expect(.r_paren);
    }

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .variant_shorthand = .{ .name = sym, .args = args.items } },
        .span = span.merge(self.prevSpan()),
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

    // Check for `if let Pattern = expr` (desugars to match).
    if (self.peek() == .kw_let) {
        return self.parseIfLet(start);
    }

    const cond = try self.parseExpr();

    var use_block = false;
    if (self.peek() == .kw_then) {
        self.advance();
        self.skipNewlines();
    } else if (self.peek() == .colon) {
        self.advance();
        use_block = true;
        // Don't skip newlines — parseBlockOrExpr needs to see the newline
        // to enter multi-line block mode.
    } else {
        self.skipNewlines();
    }

    const then_body = if (use_block) try self.parseBlockOrExpr() else try self.parseExpr();
    var else_body: ?*const Ast.Expr = null;
    const save = self.pos;
    self.skipNewlines();
    if (self.peek() == .kw_else) {
        self.advance();
        // Don't skip newlines for else block — let parseBlockOrExpr handle it
        else_body = try self.parseBlockOrExpr();
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

fn parseIfLet(self: *Parser, start: Span) !*const Ast.Expr {
    const IfClause = union(enum) {
        let_clause: struct {
            pattern: Ast.Pattern,
            subject: *const Ast.Expr,
        },
        cond_expr: *const Ast.Expr,
    };

    self.advance(); // consume 'let'
    var clauses: std.ArrayList(IfClause) = .empty;

    const first_pattern = try self.parsePattern();
    try self.expect(.eq);
    const first_subject = try self.parseExpr();
    try clauses.append(self.arena, .{ .let_clause = .{
        .pattern = first_pattern,
        .subject = first_subject,
    } });

    // Chained form: `if let A = x, let B = y, cond, ...`
    while (self.peek() == .comma) {
        self.advance();
        self.skipNewlines();
        if (self.peek() == .kw_let) {
            self.advance(); // consume 'let'
            const p = try self.parsePattern();
            try self.expect(.eq);
            const s = try self.parseExpr();
            try clauses.append(self.arena, .{ .let_clause = .{
                .pattern = p,
                .subject = s,
            } });
        } else {
            // Boolean clause in mixed if-let chain.
            const cond = try self.parseExpr();
            try clauses.append(self.arena, .{ .cond_expr = cond });
        }
    }

    // Expect then/colon delimiter.
    var use_block = false;
    if (self.peek() == .kw_then) {
        self.advance();
        self.skipNewlines();
    } else if (self.peek() == .colon) {
        self.advance();
        use_block = true;
        // Don't skip newlines — parseBlockOrExpr needs to see the newline
        // to enter multi-line block mode.
    } else {
        self.skipNewlines();
    }

    const then_body = if (use_block) try self.parseBlockOrExpr() else try self.parseExpr();

    // Parse optional else branch.
    var else_body: ?*const Ast.Expr = null;
    const save = self.pos;
    self.skipNewlines();
    if (self.peek() == .kw_else) {
        self.advance();
        else_body = try self.parseBlockOrExpr();
    } else {
        self.pos = save;
    }

    // Always add a wildcard/else arm.
    const else_expr = if (else_body) |eb| eb else blk: {
        const void_node = try self.arena.create(Ast.Expr);
        void_node.* = .{
            .kind = .{ .int_literal = 0 },
            .span = start,
        };
        break :blk void_node;
    };
    // Desugar chained if-let into nested match expressions from right to left.
    var acc = then_body;
    var i: usize = clauses.items.len;
    while (i > 0) {
        i -= 1;
        switch (clauses.items[i]) {
            .let_clause => |clause| {
                var arms: std.ArrayList(Ast.MatchArm) = .empty;
                try arms.append(self.arena, .{
                    .pattern = clause.pattern,
                    .body = acc,
                    .span = start.merge(acc.span),
                });
                try arms.append(self.arena, .{
                    .pattern = .{ .kind = .wildcard, .span = start },
                    .body = else_expr,
                    .span = start.merge(else_expr.span),
                });
                const node = try self.arena.create(Ast.Expr);
                node.* = .{
                    .kind = .{ .match_expr = .{
                        .subject = clause.subject,
                        .arms = arms.items,
                    } },
                    .span = start.merge(acc.span),
                };
                acc = node;
            },
            .cond_expr => |cond| {
                const node = try self.arena.create(Ast.Expr);
                node.* = .{
                    .kind = .{ .if_expr = .{
                        .condition = cond,
                        .then_body = acc,
                        .else_body = else_expr,
                    } },
                    .span = start.merge(acc.span),
                };
                acc = node;
            },
        }
    }

    return acc;
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

fn parseUnsafe(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'unsafe'
    self.diagnostics.emit(Diagnostic.warn(
        "E0901: unnecessary unsafe block",
        start,
    ));
    if (self.peek() == .colon) self.advance();
    return self.parseBlockOrExpr();
}

fn parseYield(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'yield'
    const value = try self.parseExpr();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .yield_expr = value },
        .span = start.merge(value.span),
    };
    return node;
}

fn parseComptime(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'comptime'
    const inner = try self.parseExpr();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .comptime_expr = inner },
        .span = start.merge(inner.span),
    };
    return node;
}

fn parseSelectAwait(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'select'
    try self.expect(.kw_await);
    if (self.peek() == .colon) {
        self.advance();
    }
    self.skipNewlines();

    // Parse arms: `name = task_expr -> body_expr|block`
    var arms: std.ArrayList(Ast.SelectAwaitArm) = .empty;
    var arm_col: ?u32 = null;

    while (self.peek() != .eof) {
        if (self.peek() != .identifier) break;

        // Column check: all arms must be at the same column
        const cur_col = Lexer.columnOf(self.source, self.currentSpan().start);
        if (arm_col) |ac| {
            if (cur_col != ac) break;
        } else {
            arm_col = cur_col;
        }

        // Lookahead: must be `name =`
        if (self.pos + 1 < self.tokens.tags.items.len and self.tokens.tags.items[self.pos + 1] != .eq) break;

        const arm_span = self.currentSpan();
        const name_sym = self.expectIdentifier() catch break;
        if (self.peek() != .eq) break;
        self.advance(); // consume '='
        self.skipNewlines();
        const task_expr = try self.parseExpr();
        try self.expect(.arrow); // ->
        const body_expr = try self.parseBlockOrExpr();

        try arms.append(self.arena, .{
            .name = name_sym,
            .task = task_expr,
            .body = body_expr,
            .span = arm_span.merge(body_expr.span),
        });

        // Only consume trailing newlines if another arm follows.
        // Otherwise, restore so enclosing block parsing can see the boundary.
        const save = self.pos;
        self.skipNewlines();
        if (self.peek() == .identifier and self.pos + 1 < self.tokens.tags.items.len and self.tokens.tags.items[self.pos + 1] == .eq) {
            const next_col = Lexer.columnOf(self.source, self.currentSpan().start);
            if (arm_col != null and next_col == arm_col.?) {
                continue;
            }
        }
        self.pos = save;
        break;
    }

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .select_await = .{ .arms = arms.items } },
        .span = start.merge(if (arms.items.len > 0) arms.items[arms.items.len - 1].span else start),
    };
    return node;
}

fn parseSpawn(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'spawn'
    const value = try self.parseExpr();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .spawn_expr = value },
        .span = start.merge(value.span),
    };
    return node;
}

/// Parse async expression forms used in expression position.
/// - `async: expr_or_block`
/// - `async scope |s|: ...` (currently parsed-and-ignored scope marker)
fn parseAsyncExpr(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'async'

    if (self.isIdentifierNamed("scope")) {
        return self.parseAsyncScopeExpr(start);
    }

    if (self.peek() == .colon) self.advance();
    // Let parseBlockOrExpr see the newline so it can parse an indented block.
    const body = try self.parseBlockOrExpr();
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .async_block = body },
        .span = start.merge(body.span),
    };
    return node;
}

/// Parse `async scope |name|: body`.
fn parseAsyncScopeExpr(self: *Parser, start: Span) !*const Ast.Expr {
    self.advance(); // consume 'scope'

    var scope_name: Ast.Symbol = self.pool.intern("s") catch return error.OutOfMemory;
    if (self.peek() == .pipe) {
        self.advance();
        if (self.peek() == .identifier) scope_name = try self.expectIdentifier();
        try self.expect(.pipe);
    }

    if (self.peek() == .colon) self.advance();
    // Let parseBlockOrExpr see the newline so it can parse an indented block.
    const body = try self.parseBlockOrExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .async_scope = .{
            .name = scope_name,
            .body = body,
        } },
        .span = start.merge(body.span),
    };
    return node;
}

// Parse `with expr as [mut] name: body` or `with expr as [mut] name,... : body`
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
        const value = if (self.peek() == .colon) blk: {
            self.advance();
            self.skipNewlines();
            break :blk try self.parseExpr();
        } else blk: {
            // Shorthand override: `{ base with field }` → `{ base with field: field }`
            const ident_node = try self.arena.create(Ast.Expr);
            ident_node.* = .{
                .kind = .{ .ident = field_name },
                .span = field_start,
            };
            break :blk ident_node;
        };
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

fn parseLabeledLoop(self: *Parser) !*const Ast.Expr {
    // Parse 'label: followed by a loop keyword (for/while/loop)
    const label_span = self.currentSpan();
    const label_text = self.source[label_span.start..label_span.end];
    // Label token text is 'name — strip the leading quote
    const label_name = if (label_text.len > 1) label_text[1..] else label_text;
    const label_sym = try self.pool.intern(label_name);
    self.advance(); // consume label token

    // Expect colon after label
    if (self.peek() != .colon) {
        self.emitError("expected ':' after loop label");
        return error.ParseError;
    }
    self.advance(); // consume ':'
    self.skipNewlines();

    // Now parse the loop keyword
    return switch (self.peek()) {
        .kw_for => self.parseFor(label_sym),
        .kw_while => self.parseWhile(label_sym),
        .kw_loop => self.parseLoop(label_sym),
        else => {
            self.emitError("expected 'for', 'while', or 'loop' after label");
            return error.ParseError;
        },
    };
}

fn parseWhile(self: *Parser, label: ?Ast.Symbol) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'while'
    self.skipNewlines();

    // Check for while-let: `while let Pattern = expr: body`
    // Desugars to: `loop: match expr { Pattern -> body, _ -> break }`
    if (self.peek() == .kw_let) {
        return self.parseWhileLet(start);
    }

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
            .label = label,
        } },
        .span = start.merge(body.span),
    };
    return node;
}

fn parseWhileLet(self: *Parser, start: Span) !*const Ast.Expr {
    self.advance(); // consume 'let'
    const pattern = try self.parsePattern();
    try self.expect(.eq);
    const subject = try self.parseExpr();

    if (self.peek() == .colon) {
        self.advance();
    }

    const body = try self.parseBlockOrExpr();

    // Build break expression for the wildcard arm.
    const break_node = try self.arena.create(Ast.Expr);
    break_node.* = .{
        .kind = .{ .break_expr = .{} },
        .span = start,
    };

    // Build match expression: match subject { Pattern -> body, _ -> break }
    var arms: std.ArrayList(Ast.MatchArm) = .empty;
    try arms.append(self.arena, .{
        .pattern = pattern,
        .body = body,
        .span = start.merge(body.span),
    });
    try arms.append(self.arena, .{
        .pattern = .{ .kind = .wildcard, .span = start },
        .body = break_node,
        .span = start,
    });

    const match_node = try self.arena.create(Ast.Expr);
    match_node.* = .{
        .kind = .{ .match_expr = .{
            .subject = subject,
            .arms = arms.items,
        } },
        .span = start.merge(body.span),
    };

    // Wrap in loop: loop: match_expr
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .loop_expr = .{ .body = match_node } },
        .span = start.merge(body.span),
    };
    return node;
}

fn parseLoop(self: *Parser, label: ?Ast.Symbol) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'loop'

    if (self.peek() == .colon) {
        self.advance();
    }

    const body = try self.parseBlockOrExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .loop_expr = .{ .body = body, .label = label } },
        .span = start.merge(body.span),
    };
    return node;
}

fn parseFor(self: *Parser, label: ?Ast.Symbol) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume 'for'
    self.skipNewlines();
    var binding: Ast.Symbol = 0;
    var binding_pattern: ?Ast.Pattern = null;
    var index_binding: ?Ast.Symbol = null;

    if (self.peek() == .l_paren) {
        // Tuple destructuring in for loop: `for (a, b) in items:`
        const pat = try self.parsePattern();
        if (pat.kind != .tuple_pattern) {
            self.emitError("expected tuple pattern in for loop");
            return error.ParseError;
        }
        binding_pattern = pat;
    } else {
        binding = try self.expectIdentifier();

        // Optional index binding: `for x, i in arr`
        if (self.peek() == .comma) {
            self.advance(); // consume ','
            index_binding = try self.expectIdentifier();
        }
    }

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
            .binding_pattern = binding_pattern,
            .index_binding = index_binding,
            .iterable = iterable,
            .body = body,
            .label = label,
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
    const arms = try self.parseMatchArms();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .match_expr = .{
            .subject = subject,
            .arms = arms,
        } },
        .span = start.merge(if (arms.len > 0) arms[arms.len - 1].span else subject.span),
    };
    return node;
}

fn parseMatchArms(self: *Parser) ![]const Ast.MatchArm {
    var arms: std.ArrayList(Ast.MatchArm) = .empty;
    var arm_col: ?u32 = null; // Column of first arm — used to detect end of match block

    // Parse arms: `pattern -> body` separated by newlines
    while (self.peek() != .eof) {
        // Check if we are still at a match arm (identifier/int/dot_identifier/true/false/string/minus/[/( for patterns)
        const tag = self.peek();
        if (tag != .identifier and tag != .int_literal and
            tag != .dot_identifier and tag != .true_literal and tag != .false_literal and
            tag != .string_literal and tag != .minus and tag != .l_bracket and
            tag != .l_paren and tag != .l_brace)
        {
            break;
        }

        // Column check: all arms must be at the same column as the first arm
        const cur_col = Lexer.columnOf(self.source, self.currentSpan().start);
        if (arm_col) |ac| {
            if (cur_col != ac) break;
        } else {
            arm_col = cur_col;
        }

        const arm_start = self.currentSpan();
        var pattern = try self.parsePattern();

        // Check for or-pattern: `A | B | C`
        if (self.peek() == .pipe) {
            var alternatives: std.ArrayList(Ast.Pattern) = .empty;
            try alternatives.append(self.arena, pattern);
            while (self.peek() == .pipe) {
                self.advance(); // consume '|'
                self.skipNewlines();
                try alternatives.append(self.arena, try self.parsePattern());
            }
            pattern = .{
                .kind = .{ .or_pattern = alternatives.items },
                .span = arm_start.merge(self.prevSpan()),
            };
        }

        // Check for guard clause: `if expr`
        var guard: ?*const Ast.Expr = null;
        if (self.peek() == .kw_if) {
            self.advance(); // consume 'if'
            const guard_expr = try self.parseExpr();
            guard = guard_expr;
        }

        try self.expect(.arrow);
        self.skipNewlines();

        const body = try self.parseBlockOrExpr();

        try arms.append(self.arena, .{
            .pattern = pattern,
            .guard = guard,
            .body = body,
            .span = arm_start.merge(body.span),
        });

        // Skip newlines but save position BEFORE skipping so we can restore
        // if the next thing is not actually a match arm.
        const save = self.pos;
        self.skipNewlines();
        if (self.peek() == .eof) break;

        // Check if the next token could be a match arm at the right column
        const next_tag = self.peek();
        const is_arm_token = (next_tag == .identifier or next_tag == .int_literal or
            next_tag == .dot_identifier or next_tag == .true_literal or next_tag == .false_literal or
            next_tag == .string_literal or next_tag == .minus or next_tag == .l_bracket or
            next_tag == .l_paren or next_tag == .l_brace);
        if (!is_arm_token) {
            self.pos = save;
            break;
        }
        // Also check column — if not at the same column, it's not a match arm
        const next_col = Lexer.columnOf(self.source, self.currentSpan().start);
        if (arm_col) |ac| {
            if (next_col != ac) {
                self.pos = save;
                break;
            }
        }
    }

    return arms.items;
}

fn parsePattern(self: *Parser) !Ast.Pattern {
    const span = self.currentSpan();
    switch (self.peek()) {
        .int_literal => {
            const text = self.source[span.start..span.end];
            self.advance();
            const start_val = std.fmt.parseInt(i64, text, 0) catch 0;
            // Check for range pattern: 1..5 or 1..=5
            if (self.peek() == .dot_dot or self.peek() == .dot_dot_eq) {
                const inclusive = self.peek() == .dot_dot_eq;
                self.advance(); // consume .. or ..=
                const end_span = self.currentSpan();
                const end_text = self.source[end_span.start..end_span.end];
                try self.expect(.int_literal);
                const end_val = std.fmt.parseInt(i64, end_text, 0) catch 0;
                return .{
                    .kind = .{ .range_pattern = .{ .start = start_val, .end = end_val, .inclusive = inclusive } },
                    .span = span.merge(self.prevSpan()),
                };
            }
            return .{
                .kind = .{ .int_literal = start_val },
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
        .minus => {
            // Negative integer pattern: `-42`
            self.advance(); // consume '-'
            const num_span = self.currentSpan();
            const text = self.source[num_span.start..num_span.end];
            try self.expect(.int_literal);
            const val = std.fmt.parseInt(i64, text, 0) catch 0;
            return .{
                .kind = .{ .int_literal = -val },
                .span = span.merge(self.prevSpan()),
            };
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
                // Try parsing as nested patterns first (supports Some(Some(v)), etc.)
                var bindings: std.ArrayList(Ast.Symbol) = .empty;
                var nested: std.ArrayList(Ast.Pattern) = .empty;
                var has_nested = false;
                while (self.peek() != .r_paren and self.peek() != .eof) {
                    const inner_pat = try self.parsePattern();
                    try nested.append(self.arena, inner_pat);
                    // If any pattern is not a simple binding, mark as nested.
                    if (inner_pat.kind != .binding) {
                        has_nested = true;
                    }
                    if (self.peek() == .comma) {
                        self.advance();
                        self.skipNewlines();
                    }
                }
                try self.expect(.r_paren);
                // Extract simple bindings for backward compatibility.
                if (!has_nested) {
                    for (nested.items) |p| {
                        try bindings.append(self.arena, p.kind.binding);
                    }
                }
                return .{
                    .kind = .{ .variant = .{
                        .name = name,
                        .bindings = bindings.items,
                        .nested_patterns = if (has_nested) nested.items else &.{},
                    } },
                    .span = span.merge(self.prevSpan()),
                };
            }
            // Check if it's an uppercase identifier followed by { → struct pattern with type name
            if (name_str.len > 0 and std.ascii.isUpper(name_str[0]) and self.peek() == .l_brace) {
                return self.parseStructPatternInner(name, span);
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
            // Check for at-binding: `name @ Pattern`
            if (self.peek() == .at) {
                self.advance(); // consume '@'
                const inner = try self.arena.create(Ast.Pattern);
                inner.* = try self.parsePattern();
                return .{
                    .kind = .{ .at_binding = .{ .name = name, .pattern = inner } },
                    .span = span.merge(inner.span),
                };
            }
            // Otherwise it's a variable binding
            return .{ .kind = .{ .binding = name }, .span = span };
        },
        .dot_identifier => {
            // .Member variant shorthand pattern
            const text = self.source[span.start + 1 .. span.end];
            const name = try self.pool.intern(text);
            self.advance();
            // Check for payload bindings: .Member(x, y)
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
            return .{
                .kind = .{ .variant = .{
                    .name = name,
                    .bindings = &.{},
                } },
                .span = span,
            };
        },
        .l_paren => {
            // Tuple pattern: `(a, b)` or nested `(x, (y, z))`
            self.advance(); // consume '('
            var elems: std.ArrayList(Ast.Pattern) = .empty;

            if (self.peek() != .r_paren) {
                try elems.append(self.arena, try self.parsePattern());
                while (self.peek() == .comma) {
                    self.advance();
                    self.skipNewlines();
                    // Allow trailing comma.
                    if (self.peek() == .r_paren) break;
                    try elems.append(self.arena, try self.parsePattern());
                }
            }
            try self.expect(.r_paren);
            return .{
                .kind = .{ .tuple_pattern = elems.items },
                .span = span.merge(self.prevSpan()),
            };
        },
        .l_brace => {
            // Struct pattern: { x: 0, y, .. }
            return self.parseStructPatternInner(0, span);
        },
        .l_bracket => {
            // Slice pattern: [a, b, ..rest]
            self.advance(); // consume '['
            var head: std.ArrayList(Ast.Symbol) = .empty;
            var tail: std.ArrayList(Ast.Symbol) = .empty;
            var rest: Ast.Symbol = 0;
            var has_rest = false;
            var in_tail = false;

            while (self.peek() != .r_bracket and self.peek() != .eof) {
                // Check for `..` or `..name` (rest pattern)
                if (self.peek() == .dot_dot or self.peek() == .dot_dot_eq) {
                    if (self.peek() == .dot_dot_eq) {
                        self.emitError("slice rest pattern uses '..', not '..='");
                        return error.ParseError;
                    }
                    if (has_rest) {
                        self.emitError("slice pattern can contain only one '..' rest");
                        return error.ParseError;
                    }
                    has_rest = true;
                    self.advance(); // consume ..
                    // Optional rest binding name
                    if (self.peek() == .identifier) {
                        rest = try self.expectIdentifier();
                    }
                    in_tail = true;
                    if (self.peek() == .comma) self.advance();
                    self.skipNewlines();
                    continue;
                }
                if (self.peek() == .identifier) {
                    const name = try self.expectIdentifier();
                    const name_str = self.pool.resolve(name);
                    // Check for `_` wildcard — use 0 symbol
                    if (std.mem.eql(u8, name_str, "_")) {
                        if (in_tail) {
                            try tail.append(self.arena, 0);
                        } else {
                            try head.append(self.arena, 0);
                        }
                    } else {
                        if (in_tail) {
                            try tail.append(self.arena, name);
                        } else {
                            try head.append(self.arena, name);
                        }
                    }
                } else {
                    break;
                }
                if (self.peek() == .comma) {
                    self.advance();
                    self.skipNewlines();
                }
            }
            try self.expect(.r_bracket);
            return .{
                .kind = .{ .slice_pattern = .{
                    .head = head.items,
                    .rest = rest,
                    .has_rest = has_rest,
                    .tail = tail.items,
                } },
                .span = span.merge(self.prevSpan()),
            };
        },
        else => {
            self.emitError("expected pattern");
            return error.ParseError;
        },
    }
}

/// Parse struct pattern: `{ x: 0, y, .. }` or `TypeName { x, y }`.
/// Field patterns support simple values (int, bool, string, binding, wildcard).
fn parseStructPatternInner(self: *Parser, type_name: Ast.Symbol, start_span: Span) !Ast.Pattern {
    self.advance(); // consume '{'
    self.skipNewlines();

    var fields: std.ArrayList(Ast.StructPatternField) = .empty;
    var has_rest = false;

    while (self.peek() != .r_brace and self.peek() != .eof) {
        self.skipNewlines();
        // Check for `..` (rest/ignore remaining fields)
        if (self.peek() == .dot_dot) {
            has_rest = true;
            self.advance();
            if (self.peek() == .comma) self.advance();
            self.skipNewlines();
            continue;
        }

        // Parse field: `name` (shorthand) or `name: value`
        const field_name = try self.expectIdentifier();
        var pattern: ?*const Ast.Pattern = null;
        if (self.peek() == .colon) {
            self.advance(); // consume ':'
            self.skipNewlines();
            // Parse a simple pattern for the field value
            const p = try self.arena.create(Ast.Pattern);
            const ps = self.currentSpan();
            p.* = switch (self.peek()) {
                .int_literal => blk: {
                    const text = self.source[ps.start..ps.end];
                    self.advance();
                    break :blk .{ .kind = .{ .int_literal = std.fmt.parseInt(i64, text, 0) catch 0 }, .span = ps };
                },
                .true_literal => blk: {
                    self.advance();
                    break :blk .{ .kind = .{ .bool_literal = true }, .span = ps };
                },
                .false_literal => blk: {
                    self.advance();
                    break :blk .{ .kind = .{ .bool_literal = false }, .span = ps };
                },
                .string_literal => blk: {
                    const raw = self.source[ps.start + 1 .. ps.end -| 1];
                    const sym = try self.pool.intern(raw);
                    self.advance();
                    break :blk .{ .kind = .{ .string_literal = sym }, .span = ps };
                },
                .minus => blk: {
                    self.advance();
                    const ns = self.currentSpan();
                    const text = self.source[ns.start..ns.end];
                    try self.expect(.int_literal);
                    break :blk .{ .kind = .{ .int_literal = -(std.fmt.parseInt(i64, text, 0) catch 0) }, .span = ps.merge(self.prevSpan()) };
                },
                .identifier => blk: {
                    const nm = try self.expectIdentifier();
                    const nm_str = self.pool.resolve(nm);
                    if (std.mem.eql(u8, nm_str, "_")) {
                        break :blk .{ .kind = .wildcard, .span = ps };
                    }
                    break :blk .{ .kind = .{ .binding = nm }, .span = ps };
                },
                else => {
                    self.emitError("expected pattern value in struct field");
                    return error.ParseError;
                },
            };
            pattern = p;
        }
        try fields.append(self.arena, .{ .name = field_name, .pattern = pattern });

        if (self.peek() == .comma) {
            self.advance();
            self.skipNewlines();
        }
    }
    try self.expect(.r_brace);
    return .{
        .kind = .{ .struct_pattern = .{
            .type_name = type_name,
            .fields = fields.items,
            .has_rest = has_rest,
        } },
        .span = start_span.merge(self.prevSpan()),
    };
}

fn parseClosure(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    try self.expect(.pipe);

    var params: std.ArrayList(Ast.Symbol) = .empty;
    var param_types: std.ArrayList(?*const Ast.TypeExpr) = .empty;
    var has_types = false;

    // Parse parameters: `|x|` or `|x: i32, y: i32|`
    while (self.peek() != .pipe and self.peek() != .eof) {
        try params.append(self.arena, try self.expectIdentifier());
        // Check for optional type annotation: `: Type`
        if (self.peek() == .colon) {
            self.advance(); // consume ':'
            const ty = try self.parseTypeExpr();
            try param_types.append(self.arena, ty);
            has_types = true;
        } else {
            try param_types.append(self.arena, null);
        }
        if (self.peek() == .comma) {
            self.advance();
            self.skipNewlines();
        }
    }
    try self.expect(.pipe);
    self.skipNewlines();

    // Check for optional return type: `-> Type`
    var return_type: ?*const Ast.TypeExpr = null;
    if (self.peek() == .arrow) {
        self.advance(); // consume '->'
        return_type = try self.parseTypeExpr();
        self.skipNewlines();
    }

    const body = if (self.peek() == .colon) blk: {
        self.advance(); // consume ':'
        break :blk try self.parseBlockOrExpr();
    } else try self.parseExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .closure = .{
            .params = params.items,
            .param_types = if (has_types) param_types.items else &.{},
            .return_type = return_type,
            .body = body,
        } },
        .span = start.merge(body.span),
    };
    return node;
}

fn parseBreak(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    self.advance(); // consume 'break'

    // Check for optional label: `break 'label` or `break 'label expr`
    var label: ?Ast.Symbol = null;
    if (self.peek() == .label) {
        const label_span = self.currentSpan();
        const label_text = self.source[label_span.start..label_span.end];
        const label_name = if (label_text.len > 1) label_text[1..] else label_text;
        label = try self.pool.intern(label_name);
        self.advance(); // consume label
    }

    // Optionally parse a value expression: `break expr`
    var value: ?*const Ast.Expr = null;
    const next = self.peek();
    if (next != .newline and next != .eof and next != .r_brace and
        next != .r_paren and next != .r_bracket)
    {
        value = try self.parseExpr();
    }
    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .break_expr = .{ .value = value, .label = label } },
        .span = if (value) |v| span.merge(v.span) else span,
    };
    return node;
}

fn parseContinue(self: *Parser) !*const Ast.Expr {
    const span = self.currentSpan();
    self.advance(); // consume 'continue'

    // Check for optional label: `continue 'label`
    var label: ?Ast.Symbol = null;
    if (self.peek() == .label) {
        const label_span = self.currentSpan();
        const label_text = self.source[label_span.start..label_span.end];
        const label_name = if (label_text.len > 1) label_text[1..] else label_text;
        label = try self.pool.intern(label_name);
        self.advance(); // consume label
    }

    const node = try self.arena.create(Ast.Expr);
    node.* = .{ .kind = .{ .continue_expr = .{ .label = label } }, .span = span };
    return node;
}

fn parseLetBinding(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    const is_var = self.peek() == .kw_var;
    self.advance();
    const is_mut = if (is_var) true else blk: {
        if (self.peek() == .kw_mut) {
            self.advance();
            break :blk true;
        }
        break :blk false;
    };

    // Check for tuple destructuring: `let (a, b) = expr`
    if (self.peek() == .l_paren) {
        return self.parseTupleDestructure(start, is_mut);
    }

    const name_sym = try self.expectIdentifier();

    // Check for let...else variant pattern: `let Some(x) = expr else { body }`
    // Detect: identifier followed by '(' means variant with payload
    // Or: uppercase identifier followed by '=' could be unit variant (e.g., let None = expr else ...)
    const name_str = self.pool.resolve(name_sym);
    const is_uppercase = name_str.len > 0 and std.ascii.isUpper(name_str[0]);

    if (is_uppercase and self.peek() == .l_paren) {
        // Variant pattern with payload: `let Some(x) = expr else ...`
        self.advance(); // consume '('
        var bindings: std.ArrayList(Ast.Symbol) = .empty;
        while (self.peek() != .r_paren and self.peek() != .eof) {
            try bindings.append(self.arena, try self.expectIdentifier());
            if (self.peek() == .comma) {
                self.advance();
                self.skipNewlines();
            }
        }
        try self.expect(.r_paren);
        try self.expect(.eq);
        self.skipNewlines();
        const value = try self.parseExpr();
        try self.expect(.kw_else);
        self.skipNewlines();
        const else_body = try self.parseExpr();
        const node = try self.arena.create(Ast.Expr);
        node.* = .{
            .kind = .{ .let_else = .{
                .pattern = .{ .name = name_sym, .bindings = bindings.items },
                .value = value,
                .else_body = else_body,
                .is_mut = is_mut,
            } },
            .span = start.merge(else_body.span),
        };
        return node;
    }

    if (is_uppercase and self.peek() == .eq) {
        // Unit variant pattern: `let None = expr else ...`
        // Check if 'else' follows the value — disambiguate from normal let binding
        const saved_pos = self.pos;
        self.advance(); // consume '='
        self.skipNewlines();
        const value = try self.parseExpr();
        if (self.peek() == .kw_else) {
            self.skipNewlines();
            self.advance(); // consume 'else'
            self.skipNewlines();
            const else_body = try self.parseExpr();
            const empty_bindings = try self.arena.alloc(Ast.Symbol, 0);
            const node = try self.arena.create(Ast.Expr);
            node.* = .{
                .kind = .{ .let_else = .{
                    .pattern = .{ .name = name_sym, .bindings = empty_bindings },
                    .value = value,
                    .else_body = else_body,
                    .is_mut = is_mut,
                } },
                .span = start.merge(else_body.span),
            };
            return node;
        }
        // Not a let...else, it's a regular let binding with uppercase name
        // Value already parsed, just create normal let binding
        _ = saved_pos;
        const node = try self.arena.create(Ast.Expr);
        node.* = .{
            .kind = .{ .let_binding = .{
                .name = name_sym,
                .type_expr = null,
                .value = value,
                .is_mut = is_mut,
            } },
            .span = start.merge(value.span),
        };
        return node;
    }

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

fn parseTupleDestructure(self: *Parser, start: Span, is_mut: bool) !*const Ast.Expr {
    const pattern = try self.parsePattern();
    if (pattern.kind != .tuple_pattern) {
        self.emitError("expected tuple destructuring pattern");
        return error.ParseError;
    }

    var names: std.ArrayList(Ast.Symbol) = .empty;
    try self.collectPatternBindings(&pattern, &names);

    try self.expect(.eq);
    self.skipNewlines();
    const value = try self.parseExpr();

    const node = try self.arena.create(Ast.Expr);
    node.* = .{
        .kind = .{ .tuple_destructure = .{
            .names = names.items,
            .pattern = pattern,
            .value = value,
            .is_mut = is_mut,
        } },
        .span = start.merge(value.span),
    };
    return node;
}

fn collectPatternBindings(self: *Parser, pattern: *const Ast.Pattern, out: *std.ArrayList(Ast.Symbol)) !void {
    switch (pattern.kind) {
        .binding => |sym| {
            const name = self.pool.resolve(sym);
            if (!std.mem.eql(u8, name, "_")) {
                try out.append(self.arena, sym);
            }
        },
        .tuple_pattern => |elems| {
            for (elems) |*elem| {
                try self.collectPatternBindings(elem, out);
            }
        },
        .at_binding => |ab| {
            try out.append(self.arena, ab.name);
            try self.collectPatternBindings(ab.pattern, out);
        },
        .variant => |vp| {
            for (vp.bindings) |b| {
                try out.append(self.arena, b);
            }
        },
        .slice_pattern => |sp| {
            for (sp.head) |s| {
                if (s != 0) try out.append(self.arena, s);
            }
            if (sp.has_rest and sp.rest != 0) try out.append(self.arena, sp.rest);
            for (sp.tail) |s| {
                if (s != 0) try out.append(self.arena, s);
            }
        },
        .or_pattern => |alts| {
            for (alts) |*alt| {
                try self.collectPatternBindings(alt, out);
            }
        },
        else => {},
    }
}

fn parseArrayLiteral(self: *Parser) !*const Ast.Expr {
    const start = self.currentSpan();
    self.advance(); // consume '['
    self.skipNewlines();

    var elems: std.ArrayList(*const Ast.Expr) = .empty;
    if (self.peek() != .r_bracket) {
        try elems.append(self.arena, try self.parseExpr());

        // Check for comprehension: [expr for x in iter] or [expr for x in iter if cond]
        if (self.peek() == .kw_for) {
            const map_expr = elems.items[0];
            var clauses: std.ArrayList(Ast.ComprehensionClause) = .empty;
            self.advance(); // consume first 'for'
            while (true) {
                const binding = try self.expectIdentifier();
                try self.expect(.kw_in);
                const iterable = try self.parseExpr();
                try clauses.append(self.arena, .{
                    .binding = binding,
                    .iterable = iterable,
                });
                if (self.peek() != .kw_for) break;
                self.advance(); // consume next 'for'
            }
            // Optional filter: if cond
            var filter: ?*const Ast.Expr = null;
            if (self.peek() == .kw_if) {
                self.advance(); // consume 'if'
                filter = try self.parseExpr();
            }
            const end = self.currentSpan();
            try self.expect(.r_bracket);
            const node = try self.arena.create(Ast.Expr);
            node.* = .{
                .kind = .{ .array_comprehension = .{
                    .expr = map_expr,
                    .binding = clauses.items[0].binding,
                    .iterable = clauses.items[0].iterable,
                    .filter = filter,
                    .clauses = clauses.items,
                } },
                .span = start.merge(end),
            };
            return node;
        }

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
    // Inline body: `fn f -> i32: 42`
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
            // Slice type: []T (no size)
            if (self.peek() == .r_bracket) {
                self.advance(); // consume ']'
                const element = try self.parseTypeExpr();
                const node = try self.arena.create(Ast.TypeExpr);
                node.* = .{
                    .kind = .{ .slice_type = element },
                    .span = start.merge(element.span),
                };
                return node;
            }
            // Array type: [N]T
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
        .kw_dyn => {
            const start = self.currentSpan();
            self.advance(); // consume 'dyn'
            if (self.peek() != .identifier) {
                self.emitError("expected trait name after 'dyn'");
                return error.ParseError;
            }
            const trait_sym = try self.internCurrent();
            const end = self.currentSpan();
            self.advance();
            const node = try self.arena.create(Ast.TypeExpr);
            node.* = .{
                .kind = .{ .trait_object = trait_sym },
                .span = start.merge(end),
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

const ParamDestructure = struct {
    param_name: Ast.Symbol,
    kind: Kind,
    span: Span,

    const StructField = struct {
        field_name: Ast.Symbol,
        binding_name: Ast.Symbol, // 0 for wildcard `_`
    };

    const Kind = union(enum) {
        struct_fields: []const StructField,
        tuple_pattern: Ast.Pattern,
    };
};

fn parseParamList(self: *Parser, destructures_out: ?*std.ArrayList(ParamDestructure)) ![]const Ast.Param {
    var params: std.ArrayList(Ast.Param) = .empty;
    if (self.peek() == .r_paren or self.peek() == .dot_dot_dot) return params.items;

    try params.append(self.arena, try self.parseParam(destructures_out));
    while (self.peek() == .comma) {
        self.advance();
        self.skipNewlines();
        if (self.peek() == .r_paren or self.peek() == .dot_dot_dot) break;
        try params.append(self.arena, try self.parseParam(destructures_out));
    }
    return params.items;
}

fn parseParam(self: *Parser, destructures_out: ?*std.ArrayList(ParamDestructure)) !Ast.Param {
    const start = self.currentSpan();
    const is_mut = self.peek() == .kw_mut;
    if (is_mut) self.advance();

    // Destructuring parameter pattern: `{ x, y }: Type` or `{ x: x1, y: y1 }: Type`
    if (self.peek() == .l_brace) {
        self.advance(); // consume '{'
        var fields: std.ArrayList(ParamDestructure.StructField) = .empty;
        if (self.peek() != .r_brace) {
            while (true) {
                const field_name = try self.expectIdentifier();
                var binding_name = field_name;
                if (self.peek() == .colon) {
                    self.advance();
                    const bind = try self.expectIdentifier();
                    const bind_text = self.pool.resolve(bind);
                    if (std.mem.eql(u8, bind_text, "_")) {
                        binding_name = 0;
                    } else {
                        binding_name = bind;
                    }
                }
                try fields.append(self.arena, .{
                    .field_name = field_name,
                    .binding_name = binding_name,
                });
                if (self.peek() != .comma) break;
                self.advance();
                self.skipNewlines();
                if (self.peek() == .r_brace) break;
            }
        }
        try self.expect(.r_brace);
        try self.expect(.colon);
        const type_expr = try self.parseTypeExpr();

        var synth_buf: [64]u8 = undefined;
        const synth_name = std.fmt.bufPrint(&synth_buf, "__arg_{d}", .{start.start}) catch return error.ParseError;
        const param_name = self.pool.intern(synth_name) catch return error.ParseError;

        if (destructures_out) |out| {
            try out.append(self.arena, .{
                .param_name = param_name,
                .kind = .{ .struct_fields = fields.items },
                .span = start.merge(self.prevSpan()),
            });
        }

        return .{
            .name = param_name,
            .type_expr = type_expr,
            .is_mut = is_mut,
            .span = start.merge(self.prevSpan()),
        };
    }

    // Tuple parameter destructuring: `(a, b): (i32, i32)`
    if (self.peek() == .l_paren) {
        const pattern = try self.parsePattern();
        if (pattern.kind != .tuple_pattern) {
            self.emitError("parameter tuple destructuring requires tuple pattern");
            return error.ParseError;
        }
        try self.expect(.colon);
        const type_expr = try self.parseTypeExpr();

        var synth_buf: [64]u8 = undefined;
        const synth_name = std.fmt.bufPrint(&synth_buf, "__arg_{d}", .{start.start}) catch return error.ParseError;
        const param_name = self.pool.intern(synth_name) catch return error.ParseError;

        if (destructures_out) |out| {
            try out.append(self.arena, .{
                .param_name = param_name,
                .kind = .{ .tuple_pattern = pattern },
                .span = start.merge(self.prevSpan()),
            });
        }

        return .{
            .name = param_name,
            .type_expr = type_expr,
            .is_mut = is_mut,
            .span = start.merge(self.prevSpan()),
        };
    }

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

// ── Type parameter parsing ───────────────────────────────────────

/// Parse optional type parameters: `[T]`, `[T, U]`, `[T: Trait]`, `[T: Trait1 + Trait2]`
fn parseTypeParams(self: *Parser) ![]const Ast.TypeParam {
    if (self.peek() != .l_bracket) return &.{};
    self.advance(); // consume '['

    var params: std.ArrayList(Ast.TypeParam) = .empty;
    try params.append(self.arena, try self.parseOneTypeParam());
    while (self.peek() == .comma) {
        self.advance();
        try params.append(self.arena, try self.parseOneTypeParam());
    }
    try self.expect(.r_bracket);
    return params.items;
}

/// Parse a single type parameter: `T` or `T: Trait1 + Trait2`
fn parseOneTypeParam(self: *Parser) !Ast.TypeParam {
    const name = try self.expectIdentifier();
    var bounds: std.ArrayList(Ast.Symbol) = .empty;

    if (self.peek() == .colon) {
        self.advance(); // consume ':'
        // Parse first bound
        try bounds.append(self.arena, try self.parseTypeBoundSymbol());
        // Parse additional bounds separated by '+'
        while (self.peek() == .plus) {
            self.advance();
            try bounds.append(self.arena, try self.parseTypeBoundSymbol());
        }
    }

    return .{
        .name = name,
        .bounds = bounds.items,
    };
}

fn parseTypeBoundSymbol(self: *Parser) !Ast.Symbol {
    if (self.peek() == .identifier) return self.expectIdentifier();
    if (self.peek() == .kw_type) {
        self.advance();
        return self.pool.intern("type") catch return error.ParseError;
    }
    self.emitError("expected type bound name");
    return error.ParseError;
}

/// Parse an optional `where T: Trait1 + Trait2, U: Trait3` clause.
/// Merges parsed bounds into the type_params slice (creates new entries on arena).
fn parseOptionalWhereClause(self: *Parser, type_params: *[]const Ast.TypeParam) !void {
    if (!self.isIdentifierNamed("where")) return;
    self.advance(); // consume `where`

    // Parse comma-separated constraints: `T: Trait1 + Trait2, U: Trait3`
    while (self.peek() == .identifier) {
        const param_name = try self.expectIdentifier();
        try self.expect(.colon);

        // Parse bounds: Trait1 + Trait2
        var new_bounds: std.ArrayList(Ast.Symbol) = .empty;
        try new_bounds.append(self.arena, try self.parseTypeBoundSymbol());
        while (self.peek() == .plus) {
            self.advance();
            try new_bounds.append(self.arena, try self.parseTypeBoundSymbol());
        }

        // Merge into existing type_params.
        const params = type_params.*;
        var matched_param = false;
        for (params, 0..) |tp, idx| {
            if (tp.name == param_name) {
                matched_param = true;
                // Combine existing bounds with new ones.
                var combined: std.ArrayList(Ast.Symbol) = .empty;
                for (tp.bounds) |b| {
                    try combined.append(self.arena, b);
                }
                for (new_bounds.items) |b| {
                    try combined.append(self.arena, b);
                }
                // Create mutable copy of type_params to update.
                const new_params = try self.arena.alloc(Ast.TypeParam, params.len);
                @memcpy(new_params, params);
                new_params[idx].bounds = combined.items;
                type_params.* = new_params;
                break;
            }
        }
        if (!matched_param) {
            self.emitError("where clause references unknown type parameter");
            return error.ParseError;
        }

        if (self.peek() != .comma) break;
        self.advance(); // consume ','
    }
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

fn isIdentifierNamed(self: *const Parser, name: []const u8) bool {
    if (self.peek() != .identifier) return false;
    const span = self.currentSpan();
    return std.mem.eql(u8, self.source[span.start..span.end], name);
}

fn skipNewlines(self: *Parser) void {
    while (self.peek() == .newline) {
        self.advance();
    }
}

fn skipAttributes(self: *Parser) void {
    self.pending_derive_traits = &.{};
    self.pending_tailrec = false;
    self.pending_inline = false;
    self.pending_noinline = false;
    self.pending_must_use = false;
    var derives: std.ArrayList(Ast.Symbol) = .empty;

    while (self.peek() == .at) {
        const saved = self.pos;
        self.advance(); // consume '@'
        if (self.peek() != .l_bracket) {
            // Not an attribute; restore so normal parsing can diagnose.
            self.pos = saved;
            return;
        }
        self.advance(); // consume '['

        // Parse derive names from `@[derive(...)]`.
        if (self.isIdentifierNamed("derive")) {
            self.advance(); // consume 'derive'
            if (self.peek() == .l_paren) {
                self.advance();
                while (self.peek() != .r_paren and self.peek() != .eof) {
                    if (self.peek() == .identifier) {
                        const sym = self.internCurrent() catch break;
                        self.advance();
                        derives.append(self.arena, sym) catch {};
                    } else {
                        self.advance();
                    }
                    if (self.peek() == .comma) {
                        self.advance();
                        self.skipNewlines();
                    }
                }
                if (self.peek() == .r_paren) self.advance();
            }
        } else if (self.isIdentifierNamed("tailrec")) {
            self.pending_tailrec = true;
            self.advance();
        } else if (self.isIdentifierNamed("inline")) {
            self.pending_inline = true;
            self.advance();
        } else if (self.isIdentifierNamed("noinline")) {
            self.pending_noinline = true;
            self.advance();
        } else if (self.isIdentifierNamed("must_use")) {
            self.pending_must_use = true;
            self.advance();
        }

        // Consume until matching `]`.
        var depth: u32 = 1;
        while (depth > 0 and self.peek() != .eof) {
            switch (self.peek()) {
                .l_bracket => depth += 1,
                .r_bracket => depth -= 1,
                else => {},
            }
            self.advance();
        }
        self.skipNewlines();
    }

    self.pending_derive_traits = derives.items;
}

fn hasDeriveTraitNamed(self: *const Parser, derives: []const Ast.Symbol, name: []const u8) bool {
    for (derives) |d| {
        if (std.mem.eql(u8, self.pool.resolve(d), name)) return true;
    }
    return false;
}

fn structHasObviouslyNonCopyField(self: *const Parser, fields: []const Ast.FieldDef) bool {
    for (fields) |f| {
        if (self.typeExprObviouslyNonCopy(f.type_expr)) return true;
    }
    return false;
}

fn typeExprObviouslyNonCopy(self: *const Parser, te: *const Ast.TypeExpr) bool {
    switch (te.kind) {
        .named => |sym| {
            const name = self.pool.resolve(sym);
            return std.mem.eql(u8, name, "Vec") or
                std.mem.eql(u8, name, "HashMap") or
                std.mem.eql(u8, name, "HashSet") or
                std.mem.eql(u8, name, "Box") or
                std.mem.eql(u8, name, "String");
        },
        .generic => |g| {
            const name = self.pool.resolve(g.name);
            if (std.mem.eql(u8, name, "Vec") or
                std.mem.eql(u8, name, "HashMap") or
                std.mem.eql(u8, name, "HashSet") or
                std.mem.eql(u8, name, "Box") or
                std.mem.eql(u8, name, "String"))
            {
                return true;
            }
            for (g.args) |arg| {
                if (self.typeExprObviouslyNonCopy(arg)) return true;
            }
            return false;
        },
        .array_type => |a| return self.typeExprObviouslyNonCopy(a.element),
        .tuple_type => |elems| {
            for (elems) |elem| {
                if (self.typeExprObviouslyNonCopy(elem)) return true;
            }
            return false;
        },
        .optional => |inner| return self.typeExprObviouslyNonCopy(inner),
        else => return false,
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
    self.diagnostics.emit(Diagnostic.err(
        expected,
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
