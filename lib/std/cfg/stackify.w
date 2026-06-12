// std.cfg.stackify
//
// Generic implementation of the Beyond Relooper stackification
// algorithm. The algorithm operates only on integer block/value IDs
// and explicit CFG edges; compiler frontends adapt their own IRs into
// this shape before calling stackify_graph().

use std.collections

pub enum StackifyTermKind: i32:
    Br = 0
    CondBr = 1
    Select = 2
    Return = 3
    Unreachable = 4

pub enum StackifyNodeKind: i32:
    Block = 0
    Loop = 1
    Leaf = 2
    Br = 3
    If = 4
    Select = 5
    ParamTransfer = 6
    Return = 7
    Unreachable = 8

enum StackifyCtrlKind: i32:
    Block = 0
    Loop = 1
    IfThenElse = 2

enum StackifyProcessKind: i32:
    DomSubtree = 0
    EndDomSubtree = 1
    NodeWithin = 2
    FinishLoop = 3
    FinishBlock = 4
    Else = 5
    FinishIf = 6
    DoBranch = 7
    DoSelect = 8

pub type StackifyTarget {
    block: i32,
    args_start: i32,
    args_count: i32,
}
impl Copy for StackifyTarget

pub type StackifyBlock {
    desc: str,
    params_start: i32,
    params_count: i32,
    succs_start: i32,
    succs_count: i32,
    term_kind: i32,
    cond_value: i32,
    selector_value: i32,
    targets_start: i32,
    targets_count: i32,
    default_target: i32,
    return_values_start: i32,
    return_values_count: i32,
}

pub type StackifyGraph {
    entry: i32,
    blocks: Vec[StackifyBlock],
    block_params: Vec[i32],
    succs: Vec[i32],
    targets: Vec[StackifyTarget],
    target_args: Vec[i32],
    return_values: Vec[i32],
}

pub type StackifyNode {
    kind: i32,
    block: i32,
    label: i32,
    value: i32,
    first_child_start: i32,
    first_child_count: i32,
    second_child_start: i32,
    second_child_count: i32,
    values_start: i32,
    values_count: i32,
    labels_start: i32,
    labels_count: i32,
    default_label: i32,
    to_values_start: i32,
    to_values_count: i32,
}

pub type StackifyTree {
    roots_start: i32,
    roots_count: i32,
    nodes: Vec[StackifyNode],
    children: Vec[i32],
    values: Vec[i32],
    labels: Vec[i32],
}

pub type StackifyResult {
    ok: bool,
    message: str,
    tree: StackifyTree,
}

type StackifyPreds {
    starts: Vec[i32],
    counts: Vec[i32],
    data: Vec[i32],
}

type StackifyAnalysis {
    rpo: Vec[i32],
    rpo_pos: Vec[i32],
    idom: Vec[i32],
    merge_nodes: Vec[i32],
    loop_headers: Vec[i32],
    ok: bool,
    message: str,
}

type StackifyCtrlEntry {
    kind: i32,
    label_block: i32,
}

type StackifyProcessEntry {
    kind: i32,
    block: i32,
    index: i32,
    value: i32,
    target: i32,
}

type StackifyContext {
    graph: StackifyGraph,
    analysis: StackifyAnalysis,
    tree: StackifyTree,
    ctrl_stack: Vec[StackifyCtrlEntry],
    process_stack: Vec[StackifyProcessEntry],
    result_starts: Vec[i32],
    result_counts: Vec[i32],
    result_items: Vec[i32],
    merge_starts: Vec[i32],
    merge_counts: Vec[i32],
    merge_items: Vec[i32],
    ok: bool,
    message: str,
}

fn stackify_invalid -> i32:
    -1

fn stackify_empty_block(desc: str) -> StackifyBlock:
    StackifyBlock {
        desc,
        params_start: 0,
        params_count: 0,
        succs_start: 0,
        succs_count: 0,
        term_kind: stackify_invalid(),
        cond_value: 0,
        selector_value: 0,
        targets_start: 0,
        targets_count: 0,
        default_target: stackify_invalid(),
        return_values_start: 0,
        return_values_count: 0,
    }

pub fn StackifyGraph.new(entry: i32) -> StackifyGraph:
    StackifyGraph {
        entry,
        blocks: Vec.new(),
        block_params: Vec.new(),
        succs: Vec.new(),
        targets: Vec.new(),
        target_args: Vec.new(),
        return_values: Vec.new(),
    }

pub fn StackifyGraph.add_block(mut self: StackifyGraph, desc: str) -> i32:
    let id = self.blocks.len() as i32
    self.blocks.push(stackify_empty_block(desc))
    id

pub fn StackifyGraph.add_param(mut self: StackifyGraph, block: i32, value: i32) -> Unit:
    if block < 0 or block >= self.blocks.len() as i32:
        return
    var b = self.blocks.get(block as i64)
    if b.params_count == 0:
        b.params_start = self.block_params.len() as i32
    self.block_params.push(value)
    b.params_count = b.params_count + 1
    self.update_block(block, b)

fn StackifyGraph.add_target(mut self: StackifyGraph, block: i32, args: Vec[i32]) -> i32:
    let start = self.target_args.len() as i32
    var i: i64 = 0
    while i < args.len():
        self.target_args.push(args.get(i))
        i = i + 1
    let id = self.targets.len() as i32
    self.targets.push(StackifyTarget {
        block,
        args_start: start,
        args_count: args.len() as i32,
    })
    id

pub fn StackifyGraph.add_branch_target(mut self: StackifyGraph, block: i32, args: Vec[i32]) -> i32:
    self.add_target(block, args)

fn StackifyGraph.update_block(mut self: StackifyGraph, block: i32, replacement: StackifyBlock):
    if block < 0 or block >= self.blocks.len() as i32:
        return
    unsafe:
        *((self.blocks.ptr as *mut StackifyBlock) + (block as usize)) = replacement

fn StackifyGraph.set_succs(mut self: StackifyGraph, block: i32, succs: Vec[i32]):
    var b = self.blocks.get(block as i64)
    b.succs_start = self.succs.len() as i32
    b.succs_count = succs.len() as i32
    var i: i64 = 0
    while i < succs.len():
        self.succs.push(succs.get(i))
        i = i + 1
    self.update_block(block, b)

pub fn StackifyGraph.set_br(mut self: StackifyGraph, block: i32, target_block: i32, args: Vec[i32]) -> Unit:
    if block < 0 or block >= self.blocks.len() as i32:
        return
    let target = self.add_target(target_block, args)
    var b = self.blocks.get(block as i64)
    b.term_kind = StackifyTermKind.Br
    b.targets_start = target
    b.targets_count = 1
    self.update_block(block, b)
    let succs: Vec[i32] = Vec.new()
    succs.push(target_block)
    self.set_succs(block, succs)

pub fn StackifyGraph.set_cond_br(mut self: StackifyGraph, block: i32, cond: i32, true_block: i32, true_args: Vec[i32], false_block: i32, false_args: Vec[i32]) -> Unit:
    if block < 0 or block >= self.blocks.len() as i32:
        return
    let first_target = self.targets.len() as i32
    let _ = self.add_target(true_block, true_args)
    let _ = self.add_target(false_block, false_args)
    var b = self.blocks.get(block as i64)
    b.term_kind = StackifyTermKind.CondBr
    b.cond_value = cond
    b.targets_start = first_target
    b.targets_count = 2
    self.update_block(block, b)
    let succs: Vec[i32] = Vec.new()
    succs.push(true_block)
    succs.push(false_block)
    self.set_succs(block, succs)

pub fn StackifyGraph.set_select(mut self: StackifyGraph, block: i32, selector: i32, target_blocks: Vec[i32], default_block: i32) -> Unit:
    if block < 0 or block >= self.blocks.len() as i32:
        return
    let first_target = self.targets.len() as i32
    var i: i64 = 0
    while i < target_blocks.len():
        let empty: Vec[i32] = Vec.new()
        let _ = self.add_target(target_blocks.get(i), empty)
        i = i + 1
    let default_empty: Vec[i32] = Vec.new()
    let default_target = self.add_target(default_block, default_empty)
    var b = self.blocks.get(block as i64)
    b.term_kind = StackifyTermKind.Select
    b.selector_value = selector
    b.targets_start = first_target
    b.targets_count = target_blocks.len() as i32
    b.default_target = default_target
    self.update_block(block, b)
    let succs: Vec[i32] = Vec.new()
    var si: i64 = 0
    while si < target_blocks.len():
        succs.push(target_blocks.get(si))
        si = si + 1
    succs.push(default_block)
    self.set_succs(block, succs)

pub fn StackifyGraph.set_select_targets(mut self: StackifyGraph, block: i32, selector: i32, targets_start: i32, targets_count: i32, default_target: i32) -> Unit:
    if block < 0 or block >= self.blocks.len() as i32:
        return
    var b = self.blocks.get(block as i64)
    b.term_kind = StackifyTermKind.Select
    b.selector_value = selector
    b.targets_start = targets_start
    b.targets_count = targets_count
    b.default_target = default_target
    self.update_block(block, b)
    let succs: Vec[i32] = Vec.new()
    var i = 0
    while i < targets_count:
        if targets_start + i >= 0 and targets_start + i < self.targets.len() as i32:
            succs.push(self.targets.get((targets_start + i) as i64).block)
        i = i + 1
    if default_target >= 0 and default_target < self.targets.len() as i32:
        succs.push(self.targets.get(default_target as i64).block)
    self.set_succs(block, succs)

pub fn StackifyGraph.set_return(mut self: StackifyGraph, block: i32, values: Vec[i32]) -> Unit:
    if block < 0 or block >= self.blocks.len() as i32:
        return
    var b = self.blocks.get(block as i64)
    b.term_kind = StackifyTermKind.Return
    b.return_values_start = self.return_values.len() as i32
    b.return_values_count = values.len() as i32
    var i: i64 = 0
    while i < values.len():
        self.return_values.push(values.get(i))
        i = i + 1
    self.update_block(block, b)
    let no_succs: Vec[i32] = Vec.new()
    self.set_succs(block, no_succs)

pub fn StackifyGraph.set_unreachable(mut self: StackifyGraph, block: i32) -> Unit:
    if block < 0 or block >= self.blocks.len() as i32:
        return
    var b = self.blocks.get(block as i64)
    b.term_kind = StackifyTermKind.Unreachable
    self.update_block(block, b)
    let no_succs: Vec[i32] = Vec.new()
    self.set_succs(block, no_succs)

fn stackify_tree_empty -> StackifyTree:
    StackifyTree {
        roots_start: 0,
        roots_count: 0,
        nodes: Vec.new(),
        children: Vec.new(),
        values: Vec.new(),
        labels: Vec.new(),
    }

fn stackify_result_error(msg: str) -> StackifyResult:
    StackifyResult {
        ok: false,
        message: msg,
        tree: stackify_tree_empty(),
    }

fn stackify_result_ok(tree: StackifyTree) -> StackifyResult:
    StackifyResult {
        ok: true,
        message: "",
        tree,
    }

fn stackify_bool_vec(count: i32, value: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    var i = 0
    while i < count:
        out.push(value)
        i = i + 1
    out

fn stackify_validate_graph(graph: &StackifyGraph) -> str:
    let n = graph.blocks.len() as i32
    if n <= 0:
        return "stackify: graph has no blocks"
    if graph.entry < 0 or graph.entry >= n:
        return "stackify: entry block out of range"
    var b: i32 = 0
    while b < n:
        let block = graph.blocks.get(b as i64)
        if block.term_kind != StackifyTermKind.Br and block.term_kind != StackifyTermKind.CondBr and block.term_kind != StackifyTermKind.Select and block.term_kind != StackifyTermKind.Return and block.term_kind != StackifyTermKind.Unreachable:
            return "stackify: block has no terminator: " ++ int_to_string(b as i64) ++ " " ++ block.desc
        var si = 0
        while si < block.succs_count:
            let succ = graph.succs.get((block.succs_start + si) as i64)
            if succ < 0 or succ >= n:
                return "stackify: successor block out of range"
            si = si + 1
        var ti = 0
        while ti < block.targets_count:
            let target_index = block.targets_start + ti
            if target_index < 0 or target_index >= graph.targets.len() as i32:
                return "stackify: branch target out of range"
            let target = graph.targets.get(target_index as i64)
            if target.block < 0 or target.block >= n:
                return "stackify: branch target block out of range"
            ti = ti + 1
        if block.term_kind == StackifyTermKind.Select:
            if block.default_target < 0 or block.default_target >= graph.targets.len() as i32:
                return "stackify: select default target out of range"
        b = b + 1
    ""

// Accumulator state for the iterative post-order DFS used by
// stackify_compute_analysis. Bundled into a struct so the traversal is
// a method on StackifyDfsState rather than a free fn with `&mut Vec`
// output parameters.
type StackifyDfsState {
    visited: Vec[i32],
    out: Vec[i32],
}

fn StackifyDfsState.dfs_post(mut self: StackifyDfsState, graph: &StackifyGraph, start: i32):
    if start < 0 or start >= graph.blocks.len() as i32:
        return
    if self.visited.get(start as i64) != 0:
        return
    let stack_block: Vec[i32] = Vec.new()
    let stack_idx: Vec[i32] = Vec.new()
    self.visited.set_i32(start as i64, 1)
    stack_block.push(start)
    stack_idx.push(0)
    while stack_block.len() > 0:
        let top = stack_block.len() - 1
        let blk = stack_block.get(top)
        let idx = stack_idx.get(top)
        let b = graph.blocks.get(blk as i64)
        if idx < b.succs_count:
            // #183: succ must be computed before set_i32 — codegen re-reads idx after mutation
            let succ = graph.succs.get((b.succs_start + idx) as i64)
            stack_idx.set_i32(top, idx + 1)
            if succ >= 0 and succ < graph.blocks.len() as i32 and self.visited.get(succ as i64) == 0:
                self.visited.set_i32(succ as i64, 1)
                stack_block.push(succ)
                stack_idx.push(0)
        else:
            self.out.push(blk)
            let _ = stack_block.pop()
            let _ = stack_idx.pop()

fn stackify_compute_preds(graph: &StackifyGraph) -> StackifyPreds:
    let n = graph.blocks.len() as i32
    let starts = stackify_bool_vec(n, 0)
    let counts = stackify_bool_vec(n, 0)
    var b = 0
    while b < n:
        let blk = graph.blocks.get(b as i64)
        var si = 0
        while si < blk.succs_count:
            let succ = graph.succs.get((blk.succs_start + si) as i64)
            counts.set_i32(succ as i64, counts.get(succ as i64) + 1)
            si = si + 1
        b = b + 1
    var total = 0
    var i = 0
    while i < n:
        starts.set_i32(i as i64, total)
        total = total + counts.get(i as i64)
        counts.set_i32(i as i64, 0)
        i = i + 1
    let pred_data = stackify_bool_vec(total, 0)
    var b2 = 0
    while b2 < n:
        let blk = graph.blocks.get(b2 as i64)
        var si = 0
        while si < blk.succs_count:
            let succ = graph.succs.get((blk.succs_start + si) as i64)
            let idx = starts.get(succ as i64) + counts.get(succ as i64)
            pred_data.set_i32(idx as i64, b2)
            counts.set_i32(succ as i64, counts.get(succ as i64) + 1)
            si = si + 1
        b2 = b2 + 1
    StackifyPreds { starts, counts, data: pred_data }

fn stackify_pred_count(preds: &StackifyPreds, block: i32) -> i32:
    preds.counts.get(block as i64)

fn stackify_pred_get(preds: &StackifyPreds, block: i32, idx: i32) -> i32:
    preds.data.get((preds.starts.get(block as i64) + idx) as i64)

fn stackify_domtree_merge(idom: Vec[i32], rpo_pos: Vec[i32], a: i32, b: i32) -> i32:
    var n1 = a
    var n2 = b
    while n1 != n2:
        if n1 == stackify_invalid() or n2 == stackify_invalid():
            return stackify_invalid()
        let r1 = rpo_pos.get(n1 as i64)
        let r2 = rpo_pos.get(n2 as i64)
        if r1 > r2:
            n1 = idom.get(n1 as i64)
        else:
            if r2 > r1:
                n2 = idom.get(n2 as i64)
    n1

fn stackify_compute_idom(graph: &StackifyGraph, post_ord: Vec[i32], rpo_pos: Vec[i32], preds: &StackifyPreds) -> Vec[i32]:
    let n = graph.blocks.len() as i32
    var idom = stackify_bool_vec(n, stackify_invalid())
    idom.set_i32(graph.entry as i64, graph.entry)
    var changed = true
    while changed:
        changed = false
        var ri = post_ord.len() as i32 - 1
        while ri >= 0:
            let node = post_ord.get(ri as i64)
            if node != graph.entry:
                let rponum = rpo_pos.get(node as i64)
                var parent = stackify_invalid()
                var pi = 0
                let pc = stackify_pred_count(preds, node)
                while pi < pc:
                    let pred = stackify_pred_get(preds, node, pi)
                    let pred_rpo = rpo_pos.get(pred as i64)
                    if pred_rpo >= 0 and pred_rpo < rponum:
                        parent = pred
                        pi = pc
                    pi = pi + 1
                if parent != stackify_invalid():
                    var pi2 = 0
                    while pi2 < pc:
                        let pred = stackify_pred_get(preds, node, pi2)
                        if pred != parent and idom.get(pred as i64) != stackify_invalid():
                            parent = stackify_domtree_merge(idom, rpo_pos, parent, pred)
                        pi2 = pi2 + 1
                if parent != stackify_invalid() and parent != idom.get(node as i64):
                    idom.set_i32(node as i64, parent)
                    changed = true
            ri = ri - 1
    idom.set_i32(graph.entry as i64, stackify_invalid())
    idom

fn stackify_dominates(idom: Vec[i32], a: i32, b: i32) -> bool:
    var cur = b
    while true:
        if a == cur:
            return true
        if cur == stackify_invalid():
            return false
        cur = idom.get(cur as i64)
    false

fn stackify_compute_analysis(graph: &StackifyGraph) -> StackifyAnalysis:
    let err = stackify_validate_graph(graph)
    if err.len() > 0:
        return StackifyAnalysis {
            rpo: Vec.new(),
            rpo_pos: Vec.new(),
            idom: Vec.new(),
            merge_nodes: Vec.new(),
            loop_headers: Vec.new(),
            ok: false,
            message: err,
        }
    let n = graph.blocks.len() as i32
    var dfs = StackifyDfsState { visited: stackify_bool_vec(n, 0), out: Vec.new() }
    dfs.dfs_post(graph, graph.entry)
    let post_ord = dfs.out
    var rpo_pos = stackify_bool_vec(n, stackify_invalid())
    var ri = post_ord.len() as i32 - 1
    while ri >= 0:
        let block = post_ord.get(ri as i64)
        rpo_pos.set_i32(block as i64, post_ord.len() as i32 - 1 - ri)
        ri = ri - 1
    let preds = stackify_compute_preds(graph)
    let idom = stackify_compute_idom(graph, post_ord, rpo_pos, preds)
    let rpo: Vec[i32] = Vec.new()
    var pi = post_ord.len() as i32 - 1
    while pi >= 0:
        rpo.push(post_ord.get(pi as i64))
        pi = pi - 1
    var loop_headers = stackify_bool_vec(n, 0)
    var branched_once = stackify_bool_vec(n, 0)
    var merge_nodes = stackify_bool_vec(n, 0)
    var bi = 0
    while bi < rpo.len() as i32:
        let block = rpo.get(bi as i64)
        let b = graph.blocks.get(block as i64)
        var si = 0
        while si < b.succs_count:
            let succ = graph.succs.get((b.succs_start + si) as i64)
            let succ_rpo = rpo_pos.get(succ as i64)
            if succ_rpo <= bi:
                if not stackify_dominates(idom, succ, block):
                    return StackifyAnalysis {
                        rpo,
                        rpo_pos,
                        idom,
                        merge_nodes,
                        loop_headers,
                        ok: false,
                        message: "stackify: irreducible control flow",
                    }
                loop_headers.set_i32(succ as i64, 1)
            else:
                if branched_once.get(succ as i64) != 0:
                    merge_nodes.set_i32(succ as i64, 1)
                else:
                    branched_once.set_i32(succ as i64, 1)
            si = si + 1
        bi = bi + 1
    var sr = 0
    while sr < rpo.len() as i32:
        let block = rpo.get(sr as i64)
        let b = graph.blocks.get(block as i64)
        if b.term_kind == StackifyTermKind.Select:
            var ti = 0
            while ti < b.targets_count:
                let target = graph.targets.get((b.targets_start + ti) as i64)
                merge_nodes.set_i32(target.block as i64, 1)
                ti = ti + 1
            let default_target = graph.targets.get(b.default_target as i64)
            merge_nodes.set_i32(default_target.block as i64, 1)
        sr = sr + 1
    StackifyAnalysis {
        rpo,
        rpo_pos,
        idom,
        merge_nodes,
        loop_headers,
        ok: true,
        message: "",
    }

fn StackifyContext.result_push(mut self: StackifyContext, node_id: i32):
    if self.result_starts.len() == 0:
        return
    self.result_items.push(node_id)
    let top = self.result_counts.len() as i32 - 1
    let new_count = self.result_counts.get(top as i64) + 1
    self.result_counts.set_i32(top as i64, new_count)

fn StackifyContext.result_push_frame(mut self: StackifyContext):
    self.result_starts.push(self.result_items.len() as i32)
    self.result_counts.push(0)

fn StackifyContext.result_pop_frame(mut self: StackifyContext) -> i32:
    if self.result_starts.len() == 0:
        return 0
    let idx = self.result_starts.len() as i32 - 1
    let start = self.result_starts.get(idx as i64)
    let _ = self.result_starts.pop()
    let _ = self.result_counts.pop()
    start

fn StackifyContext.result_frame_count(self: StackifyContext, start: i32) -> i32:
    self.result_items.len() as i32 - start

fn StackifyContext.result_truncate(mut self: StackifyContext, start: i32):
    while self.result_items.len() as i32 > start:
        let _ = self.result_items.pop()
    return

fn StackifyContext.tree_add_child_range(mut self: StackifyContext, start: i32, count: i32) -> i32:
    let child_start = self.tree.children.len() as i32
    var i = 0
    while i < count:
        self.tree.children.push(self.result_items.get((start + i) as i64))
        i = i + 1
    child_start

fn StackifyContext.tree_add_child_vec(mut self: StackifyContext, children: Vec[i32]) -> i32:
    let child_start = self.tree.children.len() as i32
    var i: i64 = 0
    while i < children.len():
        self.tree.children.push(children.get(i))
        i = i + 1
    child_start

fn StackifyContext.tree_add_values_from_vec(mut self: StackifyContext, values: Vec[i32]) -> i32:
    let start = self.tree.values.len() as i32
    var i: i64 = 0
    while i < values.len():
        self.tree.values.push(values.get(i))
        i = i + 1
    start

fn StackifyContext.tree_add_target_args(mut self: StackifyContext, target: StackifyTarget) -> i32:
    let start = self.tree.values.len() as i32
    var i = 0
    while i < target.args_count:
        self.tree.values.push(self.graph.target_args.get((target.args_start + i) as i64))
        i = i + 1
    start

fn StackifyContext.tree_add_block_params(mut self: StackifyContext, block: i32) -> i32:
    let b = self.graph.blocks.get(block as i64)
    let start = self.tree.values.len() as i32
    var i = 0
    while i < b.params_count:
        self.tree.values.push(self.graph.block_params.get((b.params_start + i) as i64))
        i = i + 1
    start

fn StackifyContext.tree_add_node(mut self: StackifyContext, node: StackifyNode) -> i32:
    let id = self.tree.nodes.len() as i32
    self.tree.nodes.push(node)
    id

fn stackify_empty_node(kind: i32) -> StackifyNode:
    StackifyNode {
        kind,
        block: stackify_invalid(),
        label: stackify_invalid(),
        value: 0,
        first_child_start: 0,
        first_child_count: 0,
        second_child_start: 0,
        second_child_count: 0,
        values_start: 0,
        values_count: 0,
        labels_start: 0,
        labels_count: 0,
        default_label: stackify_invalid(),
        to_values_start: 0,
        to_values_count: 0,
    }

fn StackifyContext.push_process(mut self: StackifyContext, kind: i32, block: i32, index: i32, value: i32, target: i32):
    self.process_stack.push(StackifyProcessEntry { kind, block, index, value, target })

fn StackifyContext.pop_process(mut self: StackifyContext) -> StackifyProcessEntry:
    self.process_stack.pop()

fn StackifyContext.push_ctrl(mut self: StackifyContext, kind: i32, label_block: i32):
    self.ctrl_stack.push(StackifyCtrlEntry { kind, label_block })

fn stackify_ctrl_label(entry: StackifyCtrlEntry) -> i32:
    if entry.kind == StackifyCtrlKind.IfThenElse:
        return stackify_invalid()
    entry.label_block

fn StackifyContext.resolve_target(self: StackifyContext, target: i32) -> i32:
    var depth = 0
    var i = self.ctrl_stack.len() as i32 - 1
    while i >= 0:
        if stackify_ctrl_label(self.ctrl_stack.get(i as i64)) == target:
            return depth
        depth = depth + 1
        i = i - 1
    stackify_invalid()

fn StackifyContext.add_param_transfer(mut self: StackifyContext, target: StackifyTarget):
    let id = self.make_param_transfer(target)
    self.result_push(id)

fn StackifyContext.make_param_transfer(mut self: StackifyContext, target: StackifyTarget) -> i32:
    let from_start = self.tree_add_target_args(target)
    let to_start = self.tree_add_block_params(target.block)
    var node = stackify_empty_node(StackifyNodeKind.ParamTransfer)
    node.values_start = from_start
    node.values_count = target.args_count
    node.to_values_start = to_start
    node.to_values_count = self.graph.blocks.get(target.block as i64).params_count
    self.tree_add_node(node)

fn StackifyContext.push_merge_children(mut self: StackifyContext, block: i32):
    let start = self.merge_items.len() as i32
    var ri = self.analysis.rpo.len() as i32 - 1
    while ri >= 0:
        let child = self.analysis.rpo.get(ri as i64)
        if self.analysis.idom.get(child as i64) == block and self.analysis.merge_nodes.get(child as i64) != 0:
            self.merge_items.push(child)
        ri = ri - 1
    self.merge_starts.push(start)
    self.merge_counts.push(self.merge_items.len() as i32 - start)

fn StackifyContext.pop_merge_children(mut self: StackifyContext):
    if self.merge_starts.len() == 0:
        return
    let idx = self.merge_starts.len() as i32 - 1
    let start = self.merge_starts.get(idx as i64)
    while self.merge_items.len() as i32 > start:
        let _ = self.merge_items.pop()
    let _ = self.merge_starts.pop()
    let _ = self.merge_counts.pop()

fn StackifyContext.do_branch(mut self: StackifyContext, source: i32, target_index: i32):
    let target = self.graph.targets.get(target_index as i64)
    let source_rpo = self.analysis.rpo_pos.get(source as i64)
    let target_rpo = self.analysis.rpo_pos.get(target.block as i64)
    if self.analysis.merge_nodes.get(target.block as i64) != 0 or target_rpo <= source_rpo:
        let label = self.resolve_target(target.block)
        if label < 0:
            self.ok = false
            self.message = "stackify: branch target is not on the control stack"
            return
        self.add_param_transfer(target)
        var node = stackify_empty_node(StackifyNodeKind.Br)
        node.label = label
        let id = self.tree_add_node(node)
        self.result_push(id)
        return
    if not stackify_dominates(self.analysis.idom, source, target.block):
        self.ok = false
        self.message = "stackify: forward branch target is not dominated by source"
        return
    self.add_param_transfer(target)
    self.push_process(StackifyProcessKind.DomSubtree, target.block, 0, 0, 0)

fn StackifyContext.do_select(mut self: StackifyContext, block: i32):
    let b = self.graph.blocks.get(block as i64)
    let labels_start = self.tree.labels.len() as i32
    var ti = 0
    while ti < b.targets_count:
        self.tree.labels.push(ti)
        ti = ti + 1
    var select_node = stackify_empty_node(StackifyNodeKind.Select)
    select_node.value = b.selector_value
    select_node.labels_start = labels_start
    select_node.labels_count = b.targets_count
    select_node.default_label = b.targets_count
    let select_id = self.tree_add_node(select_node)

    var body: Vec[i32] = Vec.new()
    body.push(select_id)
    var extra = b.targets_count + 1
    var idx = 0
    while idx < b.targets_count + 1:
        extra = extra - 1
        let target_index = if idx < b.targets_count: b.targets_start + idx else: b.default_target
        let target = self.graph.targets.get(target_index as i64)
        let resolved = self.resolve_target(target.block)
        if resolved < 0:
            self.ok = false
            self.message = "stackify: select target is not on the control stack"
            return
        let outer: Vec[i32] = Vec.new()
        let child_start = self.tree_add_child_vec(body)
        var block_node = stackify_empty_node(StackifyNodeKind.Block)
        block_node.block = stackify_invalid()
        block_node.first_child_start = child_start
        block_node.first_child_count = body.len() as i32
        outer.push(self.tree_add_node(block_node))
        outer.push(self.make_param_transfer(target))
        var br = stackify_empty_node(StackifyNodeKind.Br)
        br.label = resolved + extra
        outer.push(self.tree_add_node(br))
        body = outer
        idx = idx + 1
    var bi: i64 = 0
    while bi < body.len():
        self.result_push(body.get(bi))
        bi = bi + 1

fn StackifyContext.handle_dom_subtree(mut self: StackifyContext, block: i32):
    self.push_merge_children(block)
    self.push_process(StackifyProcessKind.EndDomSubtree, 0, 0, 0, 0)
    if self.analysis.loop_headers.get(block as i64) != 0:
        self.push_ctrl(StackifyCtrlKind.Loop, block)
        self.result_push_frame()
        self.push_process(StackifyProcessKind.FinishLoop, block, 0, 0, 0)
        self.push_process(StackifyProcessKind.NodeWithin, block, 0, 0, 0)
    else:
        self.push_process(StackifyProcessKind.NodeWithin, block, 0, 0, 0)

fn StackifyContext.finish_loop(mut self: StackifyContext, header: i32):
    let _ = self.ctrl_stack.pop()
    let start = self.result_pop_frame()
    let count = self.result_frame_count(start)
    let child_start = self.tree_add_child_range(start, count)
    self.result_truncate(start)
    var node = stackify_empty_node(StackifyNodeKind.Loop)
    node.block = header
    node.first_child_start = child_start
    node.first_child_count = count
    let id = self.tree_add_node(node)
    self.result_push(id)

fn StackifyContext.finish_block(mut self: StackifyContext, out: i32):
    let _ = self.ctrl_stack.pop()
    let start = self.result_pop_frame()
    let count = self.result_frame_count(start)
    let child_start = self.tree_add_child_range(start, count)
    self.result_truncate(start)
    var node = stackify_empty_node(StackifyNodeKind.Block)
    node.block = out
    node.first_child_start = child_start
    node.first_child_count = count
    let id = self.tree_add_node(node)
    self.result_push(id)

fn StackifyContext.else(mut self: StackifyContext):
    self.result_push_frame()

fn StackifyContext.finish_if(mut self: StackifyContext, cond: i32):
    let else_start = self.result_pop_frame()
    let else_count = self.result_frame_count(else_start)
    let else_child_start = self.tree_add_child_range(else_start, else_count)
    self.result_truncate(else_start)
    let then_start = self.result_pop_frame()
    let then_count = self.result_frame_count(then_start)
    let then_child_start = self.tree_add_child_range(then_start, then_count)
    self.result_truncate(then_start)
    let _ = self.ctrl_stack.pop()
    var node = stackify_empty_node(StackifyNodeKind.If)
    node.value = cond
    node.first_child_start = then_child_start
    node.first_child_count = then_count
    node.second_child_start = else_child_start
    node.second_child_count = else_count
    let id = self.tree_add_node(node)
    self.result_push(id)

fn StackifyContext.node_within(mut self: StackifyContext, block: i32, merge_start: i32):
    let frame_idx = self.merge_starts.len() as i32 - 1
    let start = self.merge_starts.get(frame_idx as i64)
    let count = self.merge_counts.get(frame_idx as i64)
    let rel = merge_start
    if rel < count:
        let first = self.merge_items.get((start + rel) as i64)
        self.push_process(StackifyProcessKind.DomSubtree, first, 0, 0, 0)
        self.push_ctrl(StackifyCtrlKind.Block, first)
        self.result_push_frame()
        self.push_process(StackifyProcessKind.FinishBlock, first, 0, 0, 0)
        self.push_process(StackifyProcessKind.NodeWithin, block, rel + 1, 0, 0)
        return

    var leaf = stackify_empty_node(StackifyNodeKind.Leaf)
    leaf.block = block
    let leaf_id = self.tree_add_node(leaf)
    self.result_push(leaf_id)
    let b = self.graph.blocks.get(block as i64)
    if b.term_kind == StackifyTermKind.Br:
        self.push_process(StackifyProcessKind.DoBranch, block, 0, 0, b.targets_start)
        return
    if b.term_kind == StackifyTermKind.CondBr:
        let true_target = b.targets_start
        let false_target = b.targets_start + 1
        self.push_ctrl(StackifyCtrlKind.IfThenElse, stackify_invalid())
        self.push_process(StackifyProcessKind.FinishIf, 0, 0, b.cond_value, 0)
        self.push_process(StackifyProcessKind.DoBranch, block, 0, 0, false_target)
        self.push_process(StackifyProcessKind.Else, 0, 0, 0, 0)
        self.push_process(StackifyProcessKind.DoBranch, block, 0, 0, true_target)
        self.result_push_frame()
        return
    if b.term_kind == StackifyTermKind.Select:
        self.push_process(StackifyProcessKind.DoSelect, block, 0, 0, 0)
        return
    if b.term_kind == StackifyTermKind.Return:
        let vals: Vec[i32] = Vec.new()
        var i = 0
        while i < b.return_values_count:
            vals.push(self.graph.return_values.get((b.return_values_start + i) as i64))
            i = i + 1
        var ret = stackify_empty_node(StackifyNodeKind.Return)
        ret.values_start = self.tree_add_values_from_vec(vals)
        ret.values_count = b.return_values_count
        let id = self.tree_add_node(ret)
        self.result_push(id)
        return
    let un = stackify_empty_node(StackifyNodeKind.Unreachable)
    let uid = self.tree_add_node(un)
    self.result_push(uid)

fn stackify_context_new(graph: StackifyGraph, analysis: StackifyAnalysis) -> StackifyContext:
    StackifyContext {
        graph,
        analysis,
        tree: stackify_tree_empty(),
        ctrl_stack: Vec.new(),
        process_stack: Vec.new(),
        result_starts: Vec.new(),
        result_counts: Vec.new(),
        result_items: Vec.new(),
        merge_starts: Vec.new(),
        merge_counts: Vec.new(),
        merge_items: Vec.new(),
        ok: true,
        message: "",
    }

fn StackifyContext.process(mut self: StackifyContext, entry: StackifyProcessEntry):
    if entry.kind == StackifyProcessKind.DomSubtree:
        self.handle_dom_subtree(entry.block)
        return
    if entry.kind == StackifyProcessKind.EndDomSubtree:
        self.pop_merge_children()
        return
    if entry.kind == StackifyProcessKind.NodeWithin:
        self.node_within(entry.block, entry.index)
        return
    if entry.kind == StackifyProcessKind.FinishLoop:
        self.finish_loop(entry.block)
        return
    if entry.kind == StackifyProcessKind.FinishBlock:
        self.finish_block(entry.block)
        return
    if entry.kind == StackifyProcessKind.Else:
        self.else()
        return
    if entry.kind == StackifyProcessKind.FinishIf:
        self.finish_if(entry.value)
        return
    if entry.kind == StackifyProcessKind.DoBranch:
        self.do_branch(entry.block, entry.target)
        return
    if entry.kind == StackifyProcessKind.DoSelect:
        self.do_select(entry.block)
        return

pub fn stackify_graph(graph: StackifyGraph) -> StackifyResult:
    let analysis = stackify_compute_analysis(graph)
    if not analysis.ok:
        return stackify_result_error(analysis.message)
    var ctx = stackify_context_new(graph, analysis)
    ctx.result_push_frame()
    ctx.push_process(StackifyProcessKind.DomSubtree, ctx.graph.entry, 0, 0, 0)
    while ctx.ok and ctx.process_stack.len() > 0:
        let entry = ctx.pop_process()
        ctx.process(entry)
    if not ctx.ok:
        return stackify_result_error(ctx.message)
    let root_start = ctx.result_pop_frame()
    let root_count = ctx.result_frame_count(root_start)
    ctx.tree.roots_start = ctx.tree_add_child_range(root_start, root_count)
    ctx.tree.roots_count = root_count
    stackify_result_ok(ctx.tree)
