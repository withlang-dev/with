//! AST pretty-printer for debugging and snapshot tests.
//!
//! Renders an AST back to a human-readable text form.  This is NOT
//! a formatter — it's a debug dump that shows the tree structure.

const std = @import("std");
const Ast = @import("Ast.zig");
const InternPool = @import("InternPool.zig");

/// Render an entire module to the writer.
pub fn renderModule(module: *const Ast.Module, pool: *const InternPool, writer: anytype) !void {
    for (module.decls) |decl| {
        try renderDecl(&decl, pool, writer, 0);
        try writer.writeAll("\n");
    }
}

fn renderDecl(decl: *const Ast.Decl, pool: *const InternPool, writer: anytype, indent: u32) !void {
    try writeIndent(writer, indent);
    switch (decl.kind) {
        .function => |f| {
            if (f.is_pub == .public) try writer.writeAll("pub ");
            if (f.is_async) try writer.writeAll("async ");
            if (f.is_gen) try writer.writeAll("gen ");
            try writer.print("fn {s}", .{pool.resolve(f.name)});
            if (f.type_params.len > 0) {
                try writer.writeAll("[");
                for (f.type_params, 0..) |tp, tpi| {
                    if (tpi > 0) try writer.writeAll(", ");
                    try writer.print("{s}", .{pool.resolve(tp.name)});
                    if (tp.bounds.len > 0) {
                        try writer.writeAll(": ");
                        for (tp.bounds, 0..) |b, bi| {
                            if (bi > 0) try writer.writeAll(" + ");
                            try writer.print("{s}", .{pool.resolve(b)});
                        }
                    }
                }
                try writer.writeAll("]");
            }
            if (f.params.len > 0) {
                try writer.writeAll("(");
                for (f.params, 0..) |p, i| {
                    if (i > 0) try writer.writeAll(", ");
                    if (p.is_mut) try writer.writeAll("mut ");
                    try writer.print("{s}", .{pool.resolve(p.name)});
                    if (p.type_expr) |te| {
                        try writer.writeAll(": ");
                        try renderTypeExpr(te, pool, writer);
                    }
                }
                try writer.writeAll(")");
            }
            if (f.return_type) |rt| {
                try writer.writeAll(" -> ");
                try renderTypeExpr(rt, pool, writer);
            }
            try writer.writeAll(":\n");
            try renderExpr(f.body, pool, writer, indent + 2);
        },
        .type_decl => |t| {
            if (t.is_pub == .public) try writer.writeAll("pub ");
            try writer.print("type {s}", .{pool.resolve(t.name)});
            if (t.type_params.len > 0) {
                try writer.writeAll("[");
                for (t.type_params, 0..) |tp, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try writer.print("{s}", .{pool.resolve(tp.name)});
                }
                try writer.writeAll("]");
            }
            try writer.writeAll(" = ");
            switch (t.kind) {
                .struct_def => |fields| {
                    try writer.writeAll("{ ");
                    for (fields, 0..) |f, i| {
                        if (i > 0) try writer.writeAll(", ");
                        try writer.print("{s}: ", .{pool.resolve(f.name)});
                        try renderTypeExpr(f.type_expr, pool, writer);
                    }
                    try writer.writeAll(" }");
                },
                .alias => |a| try renderTypeExpr(a, pool, writer),
                .distinct => |d| {
                    try writer.writeAll("distinct ");
                    try renderTypeExpr(d, pool, writer);
                },
                .enum_def => |variants| {
                    try writer.writeAll("\n");
                    for (variants, 0..) |v, vi| {
                        try writeIndent(writer, indent + 2);
                        if (vi > 0) try writer.writeAll("| ");
                        try writer.print("{s}", .{pool.resolve(v.name)});
                        if (v.payload) |payloads| {
                            try writer.writeAll("(");
                            for (payloads, 0..) |p, pi| {
                                if (pi > 0) try writer.writeAll(", ");
                                try renderTypeExpr(p, pool, writer);
                            }
                            try writer.writeAll(")");
                        }
                        try writer.writeAll("\n");
                    }
                },
            }
        },
        .use_decl => |u| {
            try writer.writeAll("use ");
            for (u.path, 0..) |seg, i| {
                if (i > 0) try writer.writeAll(".");
                try writer.print("{s}", .{pool.resolve(seg)});
            }
        },
        .let_decl => |l| {
            if (l.is_pub == .public) try writer.writeAll("pub ");
            try writer.writeAll(if (l.is_mut) "var " else "let ");
            try writer.print("{s}", .{pool.resolve(l.name)});
            if (l.type_expr) |te| {
                try writer.writeAll(": ");
                try renderTypeExpr(te, pool, writer);
            }
            try writer.writeAll(" = ");
            try renderExpr(l.value, pool, writer, 0);
        },
        .extern_fn => |ef| {
            try writer.print("extern fn {s}(", .{pool.resolve(ef.name)});
            for (ef.params, 0..) |p, i| {
                if (i > 0) try writer.writeAll(", ");
                try writer.print("{s}", .{pool.resolve(p.name)});
                if (p.type_expr) |te| {
                    try writer.writeAll(": ");
                    try renderTypeExpr(te, pool, writer);
                }
            }
            if (ef.is_variadic) {
                if (ef.params.len > 0) try writer.writeAll(", ");
                try writer.writeAll("...");
            }
            try writer.writeAll(")");
            if (ef.return_type) |rt| {
                try writer.writeAll(" -> ");
                try renderTypeExpr(rt, pool, writer);
            }
        },
        .c_import => |ci| {
            try writer.print("use c_import(\"{s}\"", .{ci.header_path});
            if (ci.link_libs.len > 0) {
                try writer.writeAll(", link: ");
                for (ci.link_libs, 0..) |lib, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try writer.print("\"{s}\"", .{pool.resolve(lib)});
                }
            }
            try writer.writeAll(")");
        },
        .trait_decl => |td| {
            if (td.is_pub == .public) try writer.writeAll("pub ");
            try writer.print("trait {s} =\n", .{pool.resolve(td.name)});
            for (td.associated_types) |at| {
                try writer.print("    type {s}", .{pool.resolve(at.name)});
                if (at.bounds.len > 0) {
                    try writer.writeAll(": ");
                    for (at.bounds, 0..) |b, bi| {
                        if (bi > 0) try writer.writeAll(" + ");
                        try writer.print("{s}", .{pool.resolve(b)});
                    }
                }
                if (at.default) |d| {
                    try writer.writeAll(" = ");
                    try renderTypeExpr(d, pool, writer);
                }
                try writer.writeAll("\n");
            }
            for (td.methods) |m| {
                try writer.print("    fn {s}(", .{pool.resolve(m.name)});
                for (m.params, 0..) |p, pi| {
                    if (pi > 0) try writer.writeAll(", ");
                    try writer.print("{s}", .{pool.resolve(p.name)});
                    if (p.type_expr) |te| {
                        try writer.writeAll(": ");
                        try renderTypeExpr(te, pool, writer);
                    }
                }
                try writer.writeAll(")");
                if (m.return_type) |rt| {
                    try writer.writeAll(" -> ");
                    try renderTypeExpr(rt, pool, writer);
                }
                try writer.writeAll("\n");
            }
        },
        .impl_decl => |id| {
            if (id.trait_name) |tn| {
                try writer.print("impl {s} for {s}", .{ pool.resolve(tn), pool.resolve(id.type_name) });
            } else {
                try writer.print("extend {s}", .{pool.resolve(id.type_name)});
            }
        },
        .poisoned => try writer.writeAll("<poisoned>"),
    }
}

fn renderExpr(expr: *const Ast.Expr, pool: *const InternPool, writer: anytype, indent: u32) !void {
    // Blocks don't emit their own indent — they delegate to children.
    if (expr.kind != .block) {
        try writeIndent(writer, indent);
    }
    switch (expr.kind) {
        .int_literal => |v| try writer.print("{d}", .{v}),
        .float_literal => |v| try writer.print("{d}", .{v}),
        .string_literal => |s| try writer.print("\"{s}\"", .{pool.resolve(s)}),
        .c_string_literal => |s| try writer.print("c\"{s}\"", .{pool.resolve(s)}),
        .bool_literal => |v| try writer.writeAll(if (v) "true" else "false"),
        .ident => |s| try writer.print("{s}", .{pool.resolve(s)}),
        .binary => |b| {
            try writer.writeAll("(");
            try renderExpr(b.lhs, pool, writer, 0);
            try writer.print(" {s} ", .{binOpStr(b.op)});
            try renderExpr(b.rhs, pool, writer, 0);
            try writer.writeAll(")");
        },
        .unary => |u| {
            try writer.print("({s}", .{unaryOpStr(u.op)});
            try renderExpr(u.operand, pool, writer, 0);
            try writer.writeAll(")");
        },
        .call => |c| {
            try renderExpr(c.callee, pool, writer, 0);
            try writer.writeAll("(");
            for (c.args, 0..) |arg, i| {
                if (i > 0) try writer.writeAll(", ");
                try renderExpr(arg, pool, writer, 0);
            }
            try writer.writeAll(")");
        },
        .field_access => |f| {
            try renderExpr(f.expr, pool, writer, 0);
            try writer.print(".{s}", .{pool.resolve(f.field)});
        },
        .computed_field_access => |cf| {
            try renderExpr(cf.expr, pool, writer, 0);
            try writer.writeAll(".{");
            try renderExpr(cf.field_expr, pool, writer, 0);
            try writer.writeAll("}");
        },
        .optional_chain => |oc| {
            try renderExpr(oc.expr, pool, writer, 0);
            try writer.print("?.{s}", .{pool.resolve(oc.member)});
            if (oc.args) |args| {
                try writer.writeAll("(");
                for (args, 0..) |arg, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try renderExpr(arg, pool, writer, 0);
                }
                try writer.writeAll(")");
            }
        },
        .index => |idx| {
            try renderExpr(idx.expr, pool, writer, 0);
            try writer.writeAll("[");
            try renderExpr(idx.index, pool, writer, 0);
            try writer.writeAll("]");
        },
        .slice => |sl| {
            try renderExpr(sl.expr, pool, writer, 0);
            try writer.writeAll("[");
            if (sl.start) |s| try renderExpr(s, pool, writer, 0);
            try writer.writeAll("..");
            if (sl.end) |e| try renderExpr(e, pool, writer, 0);
            try writer.writeAll("]");
        },
        .block => |b| {
            for (b.stmts) |s| {
                try renderExpr(s, pool, writer, indent);
                try writer.writeAll("\n");
            }
            if (b.tail) |t| {
                try renderExpr(t, pool, writer, indent);
            }
        },
        .if_expr => |ie| {
            try writer.writeAll("if ");
            try renderExpr(ie.condition, pool, writer, 0);
            try writer.writeAll(" then ");
            try renderExpr(ie.then_body, pool, writer, 0);
            if (ie.else_body) |eb| {
                try writer.writeAll(" else ");
                try renderExpr(eb, pool, writer, 0);
            }
        },
        .return_expr => |re| {
            try writer.writeAll("return");
            if (re) |val| {
                try writer.writeAll(" ");
                try renderExpr(val, pool, writer, 0);
            }
        },
        .let_binding => |l| {
            try writer.writeAll(if (l.is_mut) "var " else "let ");
            try writer.print("{s}", .{pool.resolve(l.name)});
            if (l.type_expr) |te| {
                try writer.writeAll(": ");
                try renderTypeExpr(te, pool, writer);
            }
            try writer.writeAll(" = ");
            try renderExpr(l.value, pool, writer, 0);
        },
        .select_await => |sel| {
            try writer.writeAll(if (sel.biased) "select await biased:\n" else "select await:\n");
            for (sel.arms) |arm| {
                try writer.print("    {s} = ", .{pool.resolve(arm.name)});
                try renderExpr(arm.task, pool, writer, 0);
                try writer.writeAll(" -> ");
                try renderExpr(arm.body, pool, writer, 0);
                try writer.writeAll("\n");
            }
        },
        .let_else => |le| {
            try writer.writeAll(if (le.is_mut) "var " else "let ");
            try writer.print("{s}", .{pool.resolve(le.pattern.name)});
            if (le.pattern.bindings.len > 0) {
                try writer.writeAll("(");
                for (le.pattern.bindings, 0..) |b, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try writer.print("{s}", .{pool.resolve(b)});
                }
                try writer.writeAll(")");
            }
            try writer.writeAll(" = ");
            try renderExpr(le.value, pool, writer, 0);
            try writer.writeAll(" else ");
            try renderExpr(le.else_body, pool, writer, 0);
        },
        .tuple_destructure => |td| {
            try writer.writeAll(if (td.is_mut) "var " else "let ");
            if (td.pattern) |pat| {
                try renderPattern(&pat, pool, writer);
            } else {
                try writer.writeAll("(");
                for (td.names, 0..) |name, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try writer.print("{s}", .{pool.resolve(name)});
                }
                try writer.writeAll(")");
            }
            try writer.writeAll(" = ");
            try renderExpr(td.value, pool, writer, 0);
        },
        .assign => |a| {
            try renderExpr(a.target, pool, writer, 0);
            try writer.writeAll(" = ");
            try renderExpr(a.value, pool, writer, 0);
        },
        .tuple => |elems| {
            try writer.writeAll("(");
            for (elems, 0..) |e, i| {
                if (i > 0) try writer.writeAll(", ");
                try renderExpr(e, pool, writer, 0);
            }
            try writer.writeAll(")");
        },
        .range => |r| {
            if (r.start) |s| try renderExpr(s, pool, writer, 0);
            try writer.writeAll(if (r.inclusive) "..=" else "..");
            if (r.end) |e| try renderExpr(e, pool, writer, 0);
        },
        .variant_shorthand => |vs| {
            try writer.print(".{s}", .{pool.resolve(vs.name)});
            if (vs.args.len > 0) {
                try writer.writeAll("(");
                for (vs.args, 0..) |a, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try renderExpr(a, pool, writer, 0);
                }
                try writer.writeAll(")");
            }
        },
        .await_expr => |e| {
            try renderExpr(e, pool, writer, 0);
            try writer.writeAll(".await");
        },
        .async_block => |e| {
            try writer.writeAll("async:\n");
            try renderExpr(e, pool, writer, indent + 2);
        },
        .spawn_expr => |e| {
            try writer.writeAll("spawn ");
            try renderExpr(e, pool, writer, 0);
        },
        .comptime_expr => |e| {
            try writer.writeAll("comptime ");
            try renderExpr(e, pool, writer, 0);
        },
        .async_scope => |as| {
            try writer.print("async scope |{s}|:\n", .{pool.resolve(as.name)});
            try renderExpr(as.body, pool, writer, indent + 2);
        },
        .pipeline => |p| {
            try renderExpr(p.lhs, pool, writer, 0);
            try writer.writeAll(" |> ");
            try renderExpr(p.rhs, pool, writer, 0);
        },
        .break_expr => |be| {
            try writer.writeAll("break");
            if (be.label) |lbl| {
                try writer.print(" '{s}", .{pool.resolve(lbl)});
            }
            if (be.value) |val| {
                try writer.writeAll(" ");
                try renderExpr(val, pool, writer, 0);
            }
        },
        .continue_expr => |ce| {
            try writer.writeAll("continue");
            if (ce.label) |lbl| {
                try writer.print(" '{s}", .{pool.resolve(lbl)});
            }
        },
        .loop_expr => |le| {
            try writer.writeAll("loop:\n");
            try renderExpr(le.body, pool, writer, indent + 2);
        },
        .for_expr => |f| {
            try writer.writeAll("for ");
            if (f.binding_pattern) |bp| {
                try renderPattern(&bp, pool, writer);
            } else {
                try writer.print("{s}", .{pool.resolve(f.binding)});
            }
            if (f.index_binding) |idx| {
                try writer.print(", {s}", .{pool.resolve(idx)});
            }
            try writer.writeAll(" in ");
            try renderExpr(f.iterable, pool, writer, 0);
            try writer.writeAll(":\n");
            try renderExpr(f.body, pool, writer, indent + 2);
        },
        .while_expr => |w| {
            try writer.writeAll("while ");
            try renderExpr(w.condition, pool, writer, 0);
            try writer.writeAll(":\n");
            try renderExpr(w.body, pool, writer, indent + 2);
        },
        .array_literal => |elems| {
            try writer.writeAll("[");
            for (elems, 0..) |e, i| {
                if (i > 0) try writer.writeAll(", ");
                try renderExpr(e, pool, writer, 0);
            }
            try writer.writeAll("]");
        },
        .array_comprehension => |comp| {
            try writer.writeAll("[");
            try renderExpr(comp.expr, pool, writer, 0);
            if (comp.clauses) |clauses| {
                for (clauses) |cl| {
                    try writer.print(" for {s} in ", .{pool.resolve(cl.binding)});
                    try renderExpr(cl.iterable, pool, writer, 0);
                }
            } else {
                try writer.print(" for {s} in ", .{pool.resolve(comp.binding)});
                try renderExpr(comp.iterable, pool, writer, 0);
            }
            if (comp.filter) |f| {
                try writer.writeAll(" if ");
                try renderExpr(f, pool, writer, 0);
            }
            try writer.writeAll("]");
        },
        .struct_literal => |sl| {
            try writer.print("{s} {{ ", .{pool.resolve(sl.name)});
            for (sl.fields, 0..) |f, i| {
                if (i > 0) try writer.writeAll(", ");
                try writer.print("{s}: ", .{pool.resolve(f.name)});
                try renderExpr(f.value, pool, writer, 0);
            }
            try writer.writeAll(" }");
        },
        .grouped => |g| {
            try writer.writeAll("(");
            try renderExpr(g, pool, writer, 0);
            try writer.writeAll(")");
        },
        .match_expr => |m| {
            try writer.writeAll("match ");
            try renderExpr(m.subject, pool, writer, 0);
            try writer.writeAll("\n");
            for (m.arms) |arm| {
                try writeIndent(writer, indent + 2);
                try renderPattern(&arm.pattern, pool, writer);
                try writer.writeAll(" -> ");
                try renderExpr(arm.body, pool, writer, 0);
                try writer.writeAll("\n");
            }
        },
        .cast => |ca| {
            try renderExpr(ca.expr, pool, writer, 0);
            try writer.writeAll(" as ");
            try renderTypeExpr(ca.target_type, pool, writer);
        },
        .defer_expr => |d| {
            try writer.writeAll("defer ");
            try renderExpr(d, pool, writer, 0);
        },
        .closure => |cl| {
            try writer.writeAll("|");
            for (cl.params, 0..) |p, i| {
                if (i > 0) try writer.writeAll(", ");
                try writer.print("{s}", .{pool.resolve(p)});
            }
            try writer.writeAll("| ");
            try renderExpr(cl.body, pool, writer, 0);
        },
        .enum_variant => |ev| {
            try writer.print("{s}.{s}", .{ pool.resolve(ev.type_name), pool.resolve(ev.variant_name) });
            if (ev.args.len > 0) {
                try writer.writeAll("(");
                for (ev.args, 0..) |a, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try renderExpr(a, pool, writer, 0);
                }
                try writer.writeAll(")");
            }
        },
        .with_expr => |w| {
            try writer.writeAll("with ");
            try renderExpr(w.source, pool, writer, 0);
            try writer.writeAll(if (w.is_mut) " as mut " else " as ");
            try writer.print("{s}:\n", .{pool.resolve(w.name)});
            try renderExpr(w.body, pool, writer, indent + 2);
        },
        .record_update => |ru| {
            try writer.writeAll("{ ");
            try renderExpr(ru.source, pool, writer, 0);
            try writer.writeAll(" with ");
            for (ru.fields, 0..) |f, i| {
                if (i > 0) try writer.writeAll(", ");
                try writer.print("{s}: ", .{pool.resolve(f.name)});
                try renderExpr(f.value, pool, writer, 0);
            }
            try writer.writeAll(" }");
        },
        .yield_expr => |y| {
            try writer.writeAll("yield ");
            try renderExpr(y, pool, writer, 0);
        },
        .poisoned => try writer.writeAll("<poisoned>"),
    }
}

fn renderPattern(pat: *const Ast.Pattern, pool: *const InternPool, writer: anytype) !void {
    switch (pat.kind) {
        .wildcard => try writer.writeAll("_"),
        .binding => |s| try writer.print("{s}", .{pool.resolve(s)}),
        .int_literal => |v| try writer.print("{d}", .{v}),
        .bool_literal => |v| try writer.writeAll(if (v) "true" else "false"),
        .string_literal => |s| try writer.print("\"{s}\"", .{pool.resolve(s)}),
        .variant => |vp| {
            try writer.print("{s}", .{pool.resolve(vp.name)});
            if (vp.bindings.len > 0) {
                try writer.writeAll("(");
                for (vp.bindings, 0..) |b, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try writer.print("{s}", .{pool.resolve(b)});
                }
                try writer.writeAll(")");
            }
        },
        .or_pattern => |alternatives| {
            for (alternatives, 0..) |*alt, j| {
                if (j > 0) try writer.writeAll(" | ");
                try renderPattern(alt, pool, writer);
            }
        },
        .at_binding => |ab| {
            try writer.print("{s} @ ", .{pool.resolve(ab.name)});
            try renderPattern(ab.pattern, pool, writer);
        },
        .tuple_pattern => |elems| {
            try writer.writeAll("(");
            for (elems, 0..) |*elem, j| {
                if (j > 0) try writer.writeAll(", ");
                try renderPattern(elem, pool, writer);
            }
            try writer.writeAll(")");
        },
        .range_pattern => |rp| {
            if (rp.inclusive) {
                try writer.print("{}..={}", .{ rp.start, rp.end });
            } else {
                try writer.print("{}..{}", .{ rp.start, rp.end });
            }
        },
        .slice_pattern => |sp| {
            try writer.writeAll("[");
            for (sp.head, 0..) |sym, j| {
                if (j > 0) try writer.writeAll(", ");
                if (sym == 0) {
                    try writer.writeAll("_");
                } else {
                    try writer.print("{s}", .{pool.resolve(sym)});
                }
            }
            if (sp.has_rest) {
                if (sp.head.len > 0) try writer.writeAll(", ");
                try writer.writeAll("..");
                if (sp.rest != 0) {
                    try writer.print("{s}", .{pool.resolve(sp.rest)});
                }
            }
            for (sp.tail, 0..) |sym, j| {
                if (j > 0 or sp.has_rest or sp.head.len > 0) try writer.writeAll(", ");
                if (sym == 0) {
                    try writer.writeAll("_");
                } else {
                    try writer.print("{s}", .{pool.resolve(sym)});
                }
            }
            try writer.writeAll("]");
        },
        .struct_pattern => |sp| {
            if (sp.type_name != 0) {
                try writer.print("{s} ", .{pool.resolve(sp.type_name)});
            }
            try writer.writeAll("{ ");
            for (sp.fields, 0..) |field, j| {
                if (j > 0) try writer.writeAll(", ");
                try writer.print("{s}", .{pool.resolve(field.name)});
                if (field.pattern) |p| {
                    try writer.writeAll(": ");
                    try renderPattern(p, pool, writer);
                }
            }
            if (sp.has_rest) {
                if (sp.fields.len > 0) try writer.writeAll(", ");
                try writer.writeAll("..");
            }
            try writer.writeAll(" }");
        },
    }
}

pub fn renderTypeExpr(te: *const Ast.TypeExpr, pool: *const InternPool, writer: anytype) !void {
    switch (te.kind) {
        .named => |n| try writer.print("{s}", .{pool.resolve(n)}),
        .generic => |g| {
            try writer.print("{s}[", .{pool.resolve(g.name)});
            for (g.args, 0..) |arg, i| {
                if (i > 0) try writer.writeAll(", ");
                try renderTypeExpr(arg, pool, writer);
            }
            try writer.writeAll("]");
        },
        .ref_type => |r| {
            try writer.writeAll("&");
            if (r.is_mut) try writer.writeAll("mut ");
            try renderTypeExpr(r.pointee, pool, writer);
        },
        .ptr_type => |p| {
            try writer.writeAll("*");
            if (p.is_mut) try writer.writeAll("mut ") else try writer.writeAll("const ");
            try renderTypeExpr(p.pointee, pool, writer);
        },
        .fn_type => |f| {
            try writer.writeAll("fn(");
            for (f.params, 0..) |p, i| {
                if (i > 0) try writer.writeAll(", ");
                try renderTypeExpr(p, pool, writer);
            }
            try writer.writeAll(") -> ");
            try renderTypeExpr(f.return_type, pool, writer);
        },
        .tuple_type => |ts| {
            try writer.writeAll("(");
            for (ts, 0..) |t, i| {
                if (i > 0) try writer.writeAll(", ");
                try renderTypeExpr(t, pool, writer);
            }
            try writer.writeAll(")");
        },
        .optional => |o| {
            try writer.writeAll("?");
            try renderTypeExpr(o, pool, writer);
        },
        .array_type => |a| {
            try writer.print("[{d}]", .{a.size});
            try renderTypeExpr(a.element, pool, writer);
        },
        .slice_type => |elem| {
            try writer.writeAll("[]");
            try renderTypeExpr(elem, pool, writer);
        },
        .trait_object => |sym| try writer.print("dyn {s}", .{pool.resolve(sym)}),
        .inferred => try writer.writeAll("_"),
    }
}

fn binOpStr(op: Ast.BinOp) []const u8 {
    return switch (op) {
        .add => "+",
        .sub => "-",
        .mul => "*",
        .div => "/",
        .mod => "%",
        .eq => "==",
        .neq => "!=",
        .lt => "<",
        .gt => ">",
        .lte => "<=",
        .gte => ">=",
        .@"and" => "and",
        .@"or" => "or",
        .bit_and => "&",
        .bit_or => "|",
        .bit_xor => "^",
        .shl => "<<",
        .shr => ">>",
        .add_wrap => "+%",
        .sub_wrap => "-%",
        .mul_wrap => "*%",
        .default_op => "??",
        .concat => "++",
        .in_op => "in",
        .not_in => "not in",
    };
}

fn unaryOpStr(op: Ast.UnaryOp) []const u8 {
    return switch (op) {
        .negate => "-",
        .not => "not ",
        .ref_of => "&",
        .mut_ref_of => "&mut ",
        .deref => "*",
        .try_op => "?",
    };
}

fn writeIndent(writer: anytype, indent: u32) !void {
    for (0..indent) |_| {
        try writer.writeAll(" ");
    }
}
