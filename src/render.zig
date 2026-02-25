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
            try writer.print("fn {s}(", .{pool.resolve(f.name)});
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
            if (f.return_type) |rt| {
                try writer.writeAll(" -> ");
                try renderTypeExpr(rt, pool, writer);
            }
            try writer.writeAll(" =\n");
            try renderExpr(f.body, pool, writer, indent + 2);
        },
        .type_decl => |t| {
            if (t.is_pub == .public) try writer.writeAll("pub ");
            try writer.print("type {s} = ...", .{pool.resolve(t.name)});
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
            try writer.writeAll(")");
            if (ef.return_type) |rt| {
                try writer.writeAll(" -> ");
                try renderTypeExpr(rt, pool, writer);
            }
        },
        .poisoned => try writer.writeAll("<poisoned>"),
    }
}

fn renderExpr(expr: *const Ast.Expr, pool: *const InternPool, writer: anytype, indent: u32) !void {
    try writeIndent(writer, indent);
    switch (expr.kind) {
        .int_literal => |v| try writer.print("{d}", .{v}),
        .float_literal => |v| try writer.print("{d}", .{v}),
        .string_literal => |s| try writer.print("\"{s}\"", .{pool.resolve(s)}),
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
        .index => |idx| {
            try renderExpr(idx.expr, pool, writer, 0);
            try writer.writeAll("[");
            try renderExpr(idx.index, pool, writer, 0);
            try writer.writeAll("]");
        },
        .block => |b| {
            for (b.stmts) |s| {
                try renderExpr(s, pool, writer, indent + 2);
                try writer.writeAll("\n");
            }
            if (b.tail) |t| {
                try renderExpr(t, pool, writer, indent + 2);
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
        .variant_shorthand => |s| try writer.print(".{s}", .{pool.resolve(s)}),
        .await_expr => |e| {
            try renderExpr(e, pool, writer, 0);
            try writer.writeAll(".await");
        },
        .pipeline => |p| {
            try renderExpr(p.lhs, pool, writer, 0);
            try writer.writeAll(" |> ");
            try renderExpr(p.rhs, pool, writer, 0);
        },
        .grouped => |g| {
            try writer.writeAll("(");
            try renderExpr(g, pool, writer, 0);
            try writer.writeAll(")");
        },
        .poisoned => try writer.writeAll("<poisoned>"),
    }
}

fn renderTypeExpr(te: *const Ast.TypeExpr, pool: *const InternPool, writer: anytype) !void {
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
    };
}

fn unaryOpStr(op: Ast.UnaryOp) []const u8 {
    return switch (op) {
        .negate => "-",
        .not => "not ",
        .ref_of => "&",
        .deref => "*",
        .try_op => "?",
    };
}

fn writeIndent(writer: anytype, indent: u32) !void {
    for (0..indent) |_| {
        try writer.writeAll(" ");
    }
}
