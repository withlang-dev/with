// BorrowCfg — Control-flow graph (CFG) construction for borrow-check analysis.
//
// This graph is intentionally lightweight: it captures sequencing,
// branching, and loop back-edges from expression trees. It exists for
// future advanced analyses (e.g., loop-iteration-aware borrow tracking,
// branch-divergent uses).
//
// NOTE on NLL last-use semantics (docs/mut.md Rev 8 §8.4 / §15.6):
//
// Non-lexical-lifetime borrow expiry is NOT implemented via this CFG.
// Instead, Sema.expire_dead_borrows_in_block (in SemaCheck.w) provides
// NLL-equivalent behavior by scanning AST statements for future uses of
// each named-borrow's reference symbol via Sema.expr_uses_symbol, which
// recurses through nested blocks, if/else, while/loop/for, match, labels,
// calls, etc. The borrow expires when no future use is found.
//
// In practice this covers all realistic last-use scenarios:
//   - last use earlier in same block, then mutation: borrow expired ✓
//   - last use inside an if/while/loop body, then post-block mutation ✓
//   - last use across nested scopes ✓
//
// What is NOT covered (would require this CFG to be fleshed out):
//   - branch-divergent uses where only some paths use the ref
//   - loop-iteration carry of borrows through the back-edge
//   - precise dataflow when calls might transitively use the ref
//
// This file's CFG construction handles block / if / while / loop /
// return / break / goto. Match and for are not yet built; they would
// be needed for the more advanced analyses above.

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

// Heap-indirected handle: copies share state by design (AstPool
// pattern, truthfully Copy) so the build_* walkers can grow the graph
// through plain parameters under spec §3.8.
type CfgGraphState {
    nodes: Vec[CfgNode],
    edges: Vec[CfgEdge],
    entry: i32,
    exit: i32,
}

type CfgGraph {
    state: *mut CfgGraphState,
}
impl Copy for CfgGraph

extern fn with_alloc(size: i64) -> *mut u8

fn CfgGraph.init -> CfgGraph:
    // Two Vec headers plus two i32s; allocate generously like the other
    // handle states.
    let ptr = with_alloc(128) as *mut CfgGraphState
    unsafe *ptr = CfgGraphState {
        nodes: Vec.new(),
        edges: Vec.new(),
        entry: 0,
        exit: 0,
    }
    CfgGraph { state: ptr }

// No-op: reserved for future manual memory management.
fn CfgGraph.deinit(self: CfgGraph):
    return

fn CfgGraph.entry_node(self: CfgGraph) -> i32:
    let st = self.state
    unsafe { st.entry }

fn CfgGraph.exit_node(self: CfgGraph) -> i32:
    let st = self.state
    unsafe { st.exit }

fn CfgGraph.set_entry(self: CfgGraph, node_id: i32):
    let st = self.state
    unsafe st.entry = node_id

fn CfgGraph.set_exit(self: CfgGraph, node_id: i32):
    let st = self.state
    unsafe st.exit = node_id

fn CfgGraph.node_count(self: CfgGraph) -> i32:
    let st = self.state
    unsafe { st.nodes.len() as i32 }

fn CfgGraph.add_node(self: CfgGraph, kind: i32, span_start: i32, span_end: i32) -> i32:
    let st = self.state
    let id = unsafe { st.nodes.len() as i32 }
    unsafe { st.nodes.push(CfgNode { kind, span_start, span_end }) }
    id

fn CfgGraph.add_edge(self: CfgGraph, from: i32, to: i32) -> Unit:
    let st = self.state
    unsafe { st.edges.push(CfgEdge { from, to }) }

fn CfgGraph.out_degree(self: CfgGraph, node_id: i32) -> i32:
    let st = self.state
    var n = 0
    for i in 0..unsafe { st.edges.len() as i32 }:
        if unsafe { st.edges.get(i as i64) }.from == node_id:
            n = n + 1
    n

fn CfgGraph.has_edge(self: CfgGraph, from: i32, to: i32) -> bool:
    let st = self.state
    for i in 0..unsafe { st.edges.len() as i32 }:
        let e = unsafe { st.edges.get(i as i64) }
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

    graph.set_entry(graph.add_node(CfgNodeKind.Entry, start, end))
    graph.set_exit(graph.add_node(CfgNodeKind.Exit, start, end))

    let result = build_expr(graph, pool, expr_node)
    graph.add_edge(graph.entry_node(), result)

    // Connect to exit
    let kind = pool.kind(expr_node)
    if kind != NodeKind.NK_RETURN and kind != NodeKind.NK_BREAK and kind != NodeKind.NK_GOTO:
        graph.add_edge(result, graph.exit_node())

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

    if kind == NodeKind.NK_DO_WHILE:
        return build_do_while(graph, pool, node)

    if kind == NodeKind.NK_LOOP:
        return build_loop(graph, pool, node)

    if kind == NodeKind.NK_RETURN or kind == NodeKind.NK_BREAK or kind == NodeKind.NK_GOTO:
        let n = graph.add_node(CfgNodeKind.Expr, start, end)
        graph.add_edge(n, graph.exit_node())
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

fn build_do_while(graph: CfgGraph, pool: AstPool, node: i32) -> i32:
    let body_node_idx = pool.get_data0(node)
    let cond_node_idx = pool.get_data1(node)
    let start = pool.get_start(node)
    let end = pool.get_end(node)

    let body_n = build_expr(graph, pool, body_node_idx)
    let cond = graph.add_node(CfgNodeKind.LoopCond, start, end)
    let after = graph.add_node(CfgNodeKind.Expr, start, end)

    graph.add_edge(body_n, cond)
    graph.add_edge(cond, body_n)
    graph.add_edge(cond, after)

    body_n

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
