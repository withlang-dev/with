// BorrowCfg — Control-flow graph (CFG) construction for borrow-check analysis.
//
// STUB: CFG construction from AST expression trees is not yet implemented.
// The build_cfg entry point produces entry/exit nodes but does not walk
// the AST to create interior control-flow edges.
//
// This graph is intentionally lightweight: it captures sequencing,
// branching, and loop back-edges from expression trees so later
// analyses (NLL/liveness) can reason over explicit control-flow.

use Ast
use Span

// Node kinds for CFG nodes
enum CfgNodeKind: i32:
    Entry = 0
    Exit = 1
    Expr = 2
    Branch = 3
    LoopCond = 4

type CfgNode {
    kind: i32,
    span_start: i32,
    span_end: i32,
}

type CfgEdge {
    from: i32,
    to: i32,
}

type CfgGraph {
    nodes: Vec[CfgNode],
    edges: Vec[CfgEdge],
    entry: i32,
    exit: i32,
}

fn CfgGraph.init -> CfgGraph:
    CfgGraph {
        nodes: Vec.new(),
        edges: Vec.new(),
        entry: 0,
        exit: 0,
    }

// No-op: reserved for future manual memory management.
fn CfgGraph.deinit(self: CfgGraph):
    return

fn CfgGraph.add_node(self: CfgGraph, kind: i32, span_start: i32, span_end: i32) -> i32:
    let id = self.nodes.len() as i32
    self.nodes.push(CfgNode { kind, span_start, span_end })
    id

fn CfgGraph.add_edge(self: CfgGraph, from: i32, to: i32):
    self.edges.push(CfgEdge { from, to })

fn CfgGraph.out_degree(self: CfgGraph, node_id: i32) -> i32:
    var n = 0
    for i in 0..self.edges.len() as i32:
        if self.edges.get(i as i64).from == node_id:
            n = n + 1
    n

fn CfgGraph.has_edge(self: CfgGraph, from: i32, to: i32) -> bool:
    for i in 0..self.edges.len() as i32:
        let e = self.edges.get(i as i64)
        if e.from == from and e.to == to:
            return true
    false

// Build a CFG from an AST expression subtree.
// For now, builds a simple linear CFG from the expression.
// Full implementation requires walking the AST expression tree.
fn build_cfg(pool: AstPool, expr_node: i32) -> CfgGraph:
    var graph = CfgGraph.init()

    let start = pool.get_start(expr_node)
    let end = pool.get_end(expr_node)

    graph.entry = graph.add_node(CfgNodeKind.Entry, start, end)
    graph.exit = graph.add_node(CfgNodeKind.Exit, start, end)

    let result = build_expr(graph, pool, expr_node)
    graph.add_edge(graph.entry, result)

    // Connect to exit
    let kind = pool.kind(expr_node)
    if kind != NodeKind.NK_RETURN and kind != NodeKind.NK_BREAK and kind != NodeKind.NK_GOTO:
        graph.add_edge(result, graph.exit)

    graph

fn build_expr(graph: CfgGraph, pool: AstPool, node: i32) -> i32:
    let kind = pool.kind(node)
    let start = pool.get_start(node)
    let end = pool.get_end(node)

    if kind == NodeKind.NK_BLOCK:
        return build_block(graph, pool, node)

    if kind == NodeKind.NK_LABEL:
        return build_expr(graph, pool, pool.get_data1(node))

    if kind == NodeKind.NK_IF_EXPR:
        return build_if(graph, pool, node)

    if kind == NodeKind.NK_WHILE:
        return build_while(graph, pool, node)

    if kind == NodeKind.NK_LOOP:
        return build_loop(graph, pool, node)

    if kind == NodeKind.NK_RETURN or kind == NodeKind.NK_BREAK or kind == NodeKind.NK_GOTO:
        let n = graph.add_node(CfgNodeKind.Expr, start, end)
        graph.add_edge(n, graph.exit)
        return n

    // Default: simple expression node
    graph.add_node(CfgNodeKind.Expr, start, end)

fn build_block(graph: CfgGraph, pool: AstPool, node: i32) -> i32:
    let extra_start = pool.get_data0(node)
    let stmt_count = pool.get_data1(node)
    let tail = pool.get_data2(node)
    let start = pool.get_start(node)
    let end = pool.get_end(node)

    if stmt_count == 0 and tail == 0:
        return graph.add_node(CfgNodeKind.Expr, start, end)

    var prev = -1
    var first = -1
    for i in 0..stmt_count:
        let stmt_node = pool.get_extra(extra_start + i)
        let curr = build_expr(graph, pool, stmt_node)
        if i == 0:
            first = curr
        if prev != -1:
            graph.add_edge(prev, curr)
        prev = curr

    if tail != 0:
        let tail_n = build_expr(graph, pool, tail)
        if prev != -1:
            graph.add_edge(prev, tail_n)
        if first == -1:
            first = tail_n
        prev = tail_n

    if first == -1:
        return graph.add_node(CfgNodeKind.Expr, start, end)
    first

fn build_if(graph: CfgGraph, pool: AstPool, node: i32) -> i32:
    let cond_node_idx = pool.get_data0(node)
    let then_node_idx = pool.get_data1(node)
    let else_node_idx = pool.get_data2(node)
    let start = pool.get_start(node)
    let end = pool.get_end(node)

    let branch = graph.add_node(CfgNodeKind.Branch, start, end)

    let then_n = build_expr(graph, pool, then_node_idx)
    graph.add_edge(branch, then_n)

    if else_node_idx != 0:
        let else_n = build_expr(graph, pool, else_node_idx)
        graph.add_edge(branch, else_n)
    else:
        let else_empty = graph.add_node(CfgNodeKind.Expr, start, end)
        graph.add_edge(branch, else_empty)

    branch

fn build_while(graph: CfgGraph, pool: AstPool, node: i32) -> i32:
    let cond_node_idx = pool.get_data0(node)
    let body_node_idx = pool.get_data1(node)
    let start = pool.get_start(node)
    let end = pool.get_end(node)

    let cond = graph.add_node(CfgNodeKind.LoopCond, start, end)
    let body_n = build_expr(graph, pool, body_node_idx)
    let after = graph.add_node(CfgNodeKind.Expr, start, end)

    graph.add_edge(cond, body_n)
    graph.add_edge(cond, after)
    graph.add_edge(body_n, cond)

    cond

fn build_loop(graph: CfgGraph, pool: AstPool, node: i32) -> i32:
    let body_node_idx = pool.get_data0(node)
    let start = pool.get_start(node)
    let end = pool.get_end(node)

    let cond = graph.add_node(CfgNodeKind.LoopCond, start, end)
    let body_n = build_expr(graph, pool, body_node_idx)
    let after = graph.add_node(CfgNodeKind.Expr, start, end)

    graph.add_edge(cond, body_n)
    graph.add_edge(cond, after)
    graph.add_edge(body_n, cond)

    cond
