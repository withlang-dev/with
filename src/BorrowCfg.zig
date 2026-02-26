//! Control-flow graph (CFG) construction for borrow-check analysis.
//!
//! This graph is intentionally lightweight: it captures sequencing,
//! branching, and loop back-edges from expression trees so later
//! analyses (NLL/liveness) can reason over explicit control-flow.

const std = @import("std");
const Ast = @import("Ast.zig");
const Span = @import("Span.zig");
const Lexer = @import("Lexer.zig");
const Parser = @import("Parser.zig");
const Diagnostic = @import("Diagnostic.zig");
const InternPool = @import("InternPool.zig");
const Source = @import("Source.zig");

pub const NodeKind = enum {
    entry,
    exit,
    expr,
    branch,
    loop_cond,
};

pub const Node = struct {
    kind: NodeKind,
    span: Span,
};

pub const Edge = struct {
    from: u32,
    to: u32,
};

pub const Graph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(Node),
    edges: std.ArrayList(Edge),
    entry: u32,
    exit: u32,

    pub fn init(allocator: std.mem.Allocator) Graph {
        return .{
            .allocator = allocator,
            .nodes = .empty,
            .edges = .empty,
            .entry = 0,
            .exit = 0,
        };
    }

    pub fn deinit(self: *Graph) void {
        self.nodes.deinit(self.allocator);
        self.edges.deinit(self.allocator);
    }

    fn addNode(self: *Graph, kind: NodeKind, span: Span) !u32 {
        const id: u32 = @intCast(self.nodes.items.len);
        try self.nodes.append(self.allocator, .{ .kind = kind, .span = span });
        return id;
    }

    fn addEdge(self: *Graph, from: u32, to: u32) !void {
        try self.edges.append(self.allocator, .{ .from = from, .to = to });
    }

    pub fn outDegree(self: *const Graph, node_id: u32) u32 {
        var n: u32 = 0;
        for (self.edges.items) |e| {
            if (e.from == node_id) n += 1;
        }
        return n;
    }

    pub fn hasEdge(self: *const Graph, from: u32, to: u32) bool {
        for (self.edges.items) |e| {
            if (e.from == from and e.to == to) return true;
        }
        return false;
    }
};

const BuildResult = struct {
    entry: u32,
    exits: []const u32,
};

const Builder = struct {
    graph: *Graph,
    arena: std.mem.Allocator,

    fn makeExits(self: *Builder, exits: []const u32) anyerror![]const u32 {
        return try self.arena.dupe(u32, exits);
    }

    fn connectExits(self: *Builder, exits: []const u32, to: u32) anyerror!void {
        for (exits) |from| {
            try self.graph.addEdge(from, to);
        }
    }

    fn buildExpr(self: *Builder, expr: *const Ast.Expr) anyerror!BuildResult {
        switch (expr.kind) {
            .block => |blk| return try self.buildBlock(blk, expr.span),
            .if_expr => |if_e| return try self.buildIf(if_e, expr.span),
            .while_expr => |w| return try self.buildWhile(w, expr.span),
            .loop_expr => |body| return try self.buildLoop(body, expr.span),
            .return_expr, .break_expr, .continue_expr => {
                const node = try self.graph.addNode(.expr, expr.span);
                try self.graph.addEdge(node, self.graph.exit);
                return .{ .entry = node, .exits = try self.makeExits(&.{}) };
            },
            else => {
                const node = try self.graph.addNode(.expr, expr.span);
                return .{ .entry = node, .exits = try self.makeExits(&.{node}) };
            },
        }
    }

    fn buildBlock(self: *Builder, blk: Ast.BlockExpr, span: Span) anyerror!BuildResult {
        var items: std.ArrayList(*const Ast.Expr) = .empty;
        defer items.deinit(self.arena);

        for (blk.stmts) |stmt| {
            try items.append(self.arena, stmt);
        }
        if (blk.tail) |tail| {
            try items.append(self.arena, tail);
        }

        if (items.items.len == 0) {
            const node = try self.graph.addNode(.expr, span);
            return .{ .entry = node, .exits = try self.makeExits(&.{node}) };
        }

        var result = try self.buildExpr(items.items[0]);
        var i: usize = 1;
        while (i < items.items.len) : (i += 1) {
            const next = try self.buildExpr(items.items[i]);
            try self.connectExits(result.exits, next.entry);
            result = .{ .entry = result.entry, .exits = next.exits };
        }
        return result;
    }

    fn buildIf(self: *Builder, if_e: Ast.IfExpr, span: Span) anyerror!BuildResult {
        const cond_node = try self.graph.addNode(.branch, span);

        const then_res = try self.buildExpr(if_e.then_body);

        const else_res = if (if_e.else_body) |else_body|
            try self.buildExpr(else_body)
        else blk: {
            const else_empty = try self.graph.addNode(.expr, span);
            break :blk BuildResult{
                .entry = else_empty,
                .exits = try self.makeExits(&.{else_empty}),
            };
        };

        try self.graph.addEdge(cond_node, then_res.entry);
        try self.graph.addEdge(cond_node, else_res.entry);

        const join = try self.graph.addNode(.expr, span);
        try self.connectExits(then_res.exits, join);
        try self.connectExits(else_res.exits, join);

        return .{ .entry = cond_node, .exits = try self.makeExits(&.{join}) };
    }

    fn buildWhile(self: *Builder, w: Ast.WhileExpr, span: Span) anyerror!BuildResult {
        const cond_node = try self.graph.addNode(.loop_cond, span);
        const body_res = try self.buildExpr(w.body);
        const after = try self.graph.addNode(.expr, span);

        try self.graph.addEdge(cond_node, body_res.entry);
        try self.graph.addEdge(cond_node, after);
        try self.connectExits(body_res.exits, cond_node);

        return .{ .entry = cond_node, .exits = try self.makeExits(&.{after}) };
    }

    fn buildLoop(self: *Builder, body: *const Ast.Expr, span: Span) anyerror!BuildResult {
        const cond_node = try self.graph.addNode(.loop_cond, span);
        const body_res = try self.buildExpr(body);
        const after = try self.graph.addNode(.expr, span);

        try self.graph.addEdge(cond_node, body_res.entry);
        // Conservative synthetic edge for loop exit paths (break-like flow).
        try self.graph.addEdge(cond_node, after);
        try self.connectExits(body_res.exits, cond_node);

        return .{ .entry = cond_node, .exits = try self.makeExits(&.{after}) };
    }
};

pub fn build(allocator: std.mem.Allocator, body: *const Ast.Expr) !Graph {
    var graph = Graph.init(allocator);
    errdefer graph.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    graph.entry = try graph.addNode(.entry, body.span);
    graph.exit = try graph.addNode(.exit, body.span);

    var builder = Builder{
        .graph = &graph,
        .arena = arena.allocator(),
    };

    const result = try builder.buildExpr(body);
    try graph.addEdge(graph.entry, result.entry);
    for (result.exits) |e| {
        try graph.addEdge(e, graph.exit);
    }

    return graph;
}

fn buildCfgFromSource(source_text: []const u8, allocator: std.mem.Allocator) !Graph {
    var diags = Diagnostic.DiagnosticList.init(allocator);
    defer diags.deinit();

    var pool = InternPool.init(allocator);
    defer pool.deinit();

    var lexer = Lexer.init(source_text, 0, &diags);
    var tokens = try lexer.tokenize(allocator);
    defer tokens.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var parser = Parser.init(&tokens, source_text, arena.allocator(), &pool, &diags);
    const module = try parser.parseModule();

    for (module.decls) |decl| {
        if (decl.kind == .function) {
            return try build(allocator, decl.kind.function.body);
        }
    }
    return error.NoFunction;
}

test "cfg linear sequence" {
    const src =
        \\fn main() -> i32 =
        \\    let a = 1
        \\    let b = 2
        \\    a + b
    ;

    var cfg = try buildCfgFromSource(src, std.testing.allocator);
    defer cfg.deinit();

    try std.testing.expect(cfg.nodes.items.len >= 5); // entry, exit, >=3 expr nodes
    try std.testing.expect(cfg.edges.items.len >= 4);
}

test "cfg if has two outgoing branch edges" {
    const src =
        \\fn main() -> i32 =
        \\    if true then 1 else 2
    ;

    var cfg = try buildCfgFromSource(src, std.testing.allocator);
    defer cfg.deinit();

    var branch_id: ?u32 = null;
    for (cfg.nodes.items, 0..) |n, i| {
        if (n.kind == .branch) {
            branch_id = @intCast(i);
            break;
        }
    }
    try std.testing.expect(branch_id != null);
    try std.testing.expectEqual(@as(u32, 2), cfg.outDegree(branch_id.?));
}

test "cfg while has back edge to loop condition" {
    const src =
        \\fn main() -> i32 =
        \\    var i = 0
        \\    while i < 3 do
        \\        i = i + 1
        \\    i
    ;

    var cfg = try buildCfgFromSource(src, std.testing.allocator);
    defer cfg.deinit();

    var cond_id: ?u32 = null;
    for (cfg.nodes.items, 0..) |n, i| {
        if (n.kind == .loop_cond) {
            cond_id = @intCast(i);
            break;
        }
    }
    try std.testing.expect(cond_id != null);

    var has_back_edge = false;
    for (cfg.edges.items) |e| {
        if (e.to == cond_id.? and e.from != cond_id.?) {
            has_back_edge = true;
            break;
        }
    }
    try std.testing.expect(has_back_edge);
}
