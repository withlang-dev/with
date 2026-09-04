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

impl StackifyGraph:
    pub mut fn add_block(desc: str) -> i32:
        let id = self.blocks.len() as i32
        self.blocks.push(stackify_empty_block(desc))
        id

    pub mut fn add_param(block: i32, value: i32) -> Unit:
        if block < 0 or block >= self.blocks.len() as i32:
            return
        if self.blocks[block].params_count == 0:
            self.blocks[block].params_start = self.block_params.len() as i32
        self.block_params.push(value)
        self.blocks[block].params_count = self.blocks[block].params_count + 1

    mut fn add_target(block: i32, args: &Vec[i32]) -> i32:
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

    pub mut fn add_branch_target(block: i32, args: &Vec[i32]) -> i32:
        self.add_target(block, args)

    mut fn set_succs(block: i32, succs: &Vec[i32]):
        self.blocks[block].succs_start = self.succs.len() as i32
        self.blocks[block].succs_count = succs.len() as i32
        var i: i64 = 0
        while i < succs.len():
            self.succs.push(succs.get(i))
            i = i + 1

    pub mut fn set_br(block: i32, target_block: i32, args: &Vec[i32]) -> Unit:
        if block < 0 or block >= self.blocks.len() as i32:
            return
        let target = self.add_target(target_block, args)
        self.blocks[block].term_kind = StackifyTermKind.Br
        self.blocks[block].targets_start = target
        self.blocks[block].targets_count = 1
        let succs: Vec[i32] = Vec.new()
        succs.push(target_block)
        self.set_succs(block, succs)

    pub mut fn set_cond_br(block: i32, cond: i32, true_block: i32, true_args: &Vec[i32], false_block: i32, false_args: &Vec[i32]) -> Unit:
        if block < 0 or block >= self.blocks.len() as i32:
            return
        let first_target = self.targets.len() as i32
        let _ = self.add_target(true_block, true_args)
        let _ = self.add_target(false_block, false_args)
        self.blocks[block].term_kind = StackifyTermKind.CondBr
        self.blocks[block].cond_value = cond
        self.blocks[block].targets_start = first_target
        self.blocks[block].targets_count = 2
        let succs: Vec[i32] = Vec.new()
        succs.push(true_block)
        succs.push(false_block)
        self.set_succs(block, succs)

    pub mut fn set_select(block: i32, selector: i32, target_blocks: &Vec[i32], default_block: i32) -> Unit:
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
        self.blocks[block].term_kind = StackifyTermKind.Select
        self.blocks[block].selector_value = selector
        self.blocks[block].targets_start = first_target
        self.blocks[block].targets_count = target_blocks.len() as i32
        self.blocks[block].default_target = default_target
        let succs: Vec[i32] = Vec.new()
        var si: i64 = 0
        while si < target_blocks.len():
            succs.push(target_blocks.get(si))
            si = si + 1
        succs.push(default_block)
        self.set_succs(block, succs)

    pub mut fn set_select_targets(block: i32, selector: i32, targets_start: i32, targets_count: i32, default_target: i32) -> Unit:
        if block < 0 or block >= self.blocks.len() as i32:
            return
        self.blocks[block].term_kind = StackifyTermKind.Select
        self.blocks[block].selector_value = selector
        self.blocks[block].targets_start = targets_start
        self.blocks[block].targets_count = targets_count
        self.blocks[block].default_target = default_target
        let succs: Vec[i32] = Vec.new()
        var i = 0
        while i < targets_count:
            if targets_start + i >= 0 and targets_start + i < self.targets.len() as i32:
                succs.push(self.targets[(targets_start + i)].block)
            i = i + 1
        if default_target >= 0 and default_target < self.targets.len() as i32:
            succs.push(self.targets[default_target].block)
        self.set_succs(block, succs)

    pub mut fn set_return(block: i32, values: &Vec[i32]) -> Unit:
        if block < 0 or block >= self.blocks.len() as i32:
            return
        self.blocks[block].term_kind = StackifyTermKind.Return
        self.blocks[block].return_values_start = self.return_values.len() as i32
        self.blocks[block].return_values_count = values.len() as i32
        var i: i64 = 0
        while i < values.len():
            self.return_values.push(values.get(i))
            i = i + 1
        let no_succs: Vec[i32] = Vec.new()
        self.set_succs(block, no_succs)

    pub mut fn set_unreachable(block: i32) -> Unit:
        if block < 0 or block >= self.blocks.len() as i32:
            return
        self.blocks[block].term_kind = StackifyTermKind.Unreachable
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
        let block = graph.blocks[b]
        if block.term_kind != StackifyTermKind.Br and block.term_kind != StackifyTermKind.CondBr and block.term_kind != StackifyTermKind.Select and block.term_kind != StackifyTermKind.Return and block.term_kind != StackifyTermKind.Unreachable:
            return "stackify: block has no terminator: " ++ int_to_string(b as i64) ++ " " ++ block.desc
        var si = 0
        while si < block.succs_count:
            let succ = graph.succs[(block.succs_start + si)]
            if succ < 0 or succ >= n:
                return "stackify: successor block out of range"
            si = si + 1
        var ti = 0
        while ti < block.targets_count:
            let target_index = block.targets_start + ti
            if target_index < 0 or target_index >= graph.targets.len() as i32:
                return "stackify: branch target out of range"
            let target = graph.targets[target_index]
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

impl StackifyDfsState:
    mut fn dfs_post(graph: &StackifyGraph, start: i32):
        if start < 0 or start >= graph.blocks.len() as i32:
            return
        if self.visited[start] != 0:
            return
        let stack_block: Vec[i32] = Vec.new()
        let stack_idx: Vec[i32] = Vec.new()
        self.visited[start] = 1
        stack_block.push(start)
        stack_idx.push(0)
        while stack_block.len() > 0:
            let top = stack_block.len() - 1
            let blk = stack_block.get(top)
            let idx: i32 = stack_idx.get(top)
            let b = graph.blocks[blk]
            if idx < b.succs_count:
                // #183: succ must be computed before set_i32 — codegen re-reads idx after mutation
                let succ = graph.succs[(b.succs_start + idx)]
                stack_idx[top] = idx + 1
                if succ >= 0 and succ < graph.blocks.len() as i32 and self.visited[succ] == 0:
                    self.visited[succ] = 1
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
        let blk = graph.blocks[b]
        var si = 0
        while si < blk.succs_count:
            let succ = graph.succs[(blk.succs_start + si)]
            counts[succ] = counts[succ] + 1
            si = si + 1
        b = b + 1
    var total = 0
    var i = 0
    while i < n:
        starts[i] = total
        total = total + counts[i]
        counts[i] = 0
        i = i + 1
    let pred_data = stackify_bool_vec(total, 0)
    var b2 = 0
    while b2 < n:
        let blk = graph.blocks[b2]
        var si = 0
        while si < blk.succs_count:
            let succ = graph.succs[(blk.succs_start + si)]
            let idx = starts[succ] + counts[succ]
            pred_data[idx] = b2
            counts[succ] = counts[succ] + 1
            si = si + 1
        b2 = b2 + 1
    StackifyPreds { starts, counts, data: pred_data }

fn stackify_pred_count(preds: &StackifyPreds, block: i32) -> i32:
    preds.counts[block]

fn stackify_pred_get(preds: &StackifyPreds, block: i32, idx: i32) -> i32:
    preds.data[(preds.starts[block] + idx)]

fn stackify_domtree_merge(idom: &Vec[i32], rpo_pos: &Vec[i32], a: i32, b: i32) -> i32:
    var n1 = a
    var n2 = b
    while n1 != n2:
        if n1 == stackify_invalid() or n2 == stackify_invalid():
            return stackify_invalid()
        let r1 = rpo_pos[n1]
        let r2 = rpo_pos[n2]
        if r1 > r2:
            n1 = idom[n1]
        else:
            if r2 > r1:
                n2 = idom[n2]
    n1

fn stackify_compute_idom(graph: &StackifyGraph, post_ord: &Vec[i32], rpo_pos: &Vec[i32], preds: &StackifyPreds) -> Vec[i32]:
    let n = graph.blocks.len() as i32
    var idom = stackify_bool_vec(n, stackify_invalid())
    idom[graph.entry] = graph.entry
    var changed = true
    while changed:
        changed = false
        var ri = post_ord.len() as i32 - 1
        while ri >= 0:
            let node = post_ord[ri]
            if node != graph.entry:
                let rponum = rpo_pos[node]
                var parent = stackify_invalid()
                var pi = 0
                let pc = stackify_pred_count(preds, node)
                while pi < pc:
                    let pred = stackify_pred_get(preds, node, pi)
                    let pred_rpo = rpo_pos[pred]
                    if pred_rpo >= 0 and pred_rpo < rponum:
                        parent = pred
                        pi = pc
                    pi = pi + 1
                if parent != stackify_invalid():
                    var pi2 = 0
                    while pi2 < pc:
                        let pred = stackify_pred_get(preds, node, pi2)
                        if pred != parent and idom[pred] != stackify_invalid():
                            parent = stackify_domtree_merge(idom, rpo_pos, parent, pred)
                        pi2 = pi2 + 1
                if parent != stackify_invalid() and parent != idom[node]:
                    idom[node] = parent
                    changed = true
            ri = ri - 1
    idom[graph.entry] = stackify_invalid()
    idom

fn stackify_dominates(idom: &Vec[i32], a: i32, b: i32) -> bool:
    var cur = b
    while true:
        if a == cur:
            return true
        if cur == stackify_invalid():
            return false
        cur = idom[cur]
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
        let block: i32 = post_ord[ri]
        rpo_pos[block] = post_ord.len() as i32 - 1 - ri
        ri = ri - 1
    let preds = stackify_compute_preds(graph)
    let idom = stackify_compute_idom(graph, post_ord, rpo_pos, preds)
    let rpo: Vec[i32] = Vec.new()
    var pi = post_ord.len() as i32 - 1
    while pi >= 0:
        rpo.push(post_ord[pi])
        pi = pi - 1
    var loop_headers = stackify_bool_vec(n, 0)
    var branched_once = stackify_bool_vec(n, 0)
    var merge_nodes = stackify_bool_vec(n, 0)
    var bi = 0
    while bi < rpo.len() as i32:
        let block: i32 = rpo[bi]
        let b = graph.blocks[block]
        var si = 0
        while si < b.succs_count:
            let succ = graph.succs[(b.succs_start + si)]
            let succ_rpo: i32 = rpo_pos[succ]
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
                loop_headers[succ] = 1
            else:
                if branched_once[succ] != 0:
                    merge_nodes[succ] = 1
                else:
                    branched_once[succ] = 1
            si = si + 1
        bi = bi + 1
    var sr = 0
    while sr < rpo.len() as i32:
        let block: i32 = rpo[sr]
        let b = graph.blocks[block]
        if b.term_kind == StackifyTermKind.Select:
            var ti = 0
            while ti < b.targets_count:
                let target = graph.targets[(b.targets_start + ti)]
                merge_nodes[target.block] = 1
                ti = ti + 1
            let default_target = graph.targets[b.default_target]
            merge_nodes[default_target.block] = 1
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

impl StackifyContext:
    mut fn result_push(node_id: i32):
        if self.result_starts.len() == 0:
            return
        self.result_items.push(node_id)
        let top = self.result_counts.len() as i32 - 1
        let new_count = self.result_counts[top] + 1
        self.result_counts[top] = new_count

    mut fn result_push_frame():
        self.result_starts.push(self.result_items.len() as i32)
        self.result_counts.push(0)

    mut fn result_pop_frame() -> i32:
        if self.result_starts.len() == 0:
            return 0
        let idx = self.result_starts.len() as i32 - 1
        let start: i32 = self.result_starts[idx]
        let _ = self.result_starts.pop()
        let _ = self.result_counts.pop()
        start

    fn result_frame_count(start: i32) -> i32:
        self.result_items.len() as i32 - start

    mut fn result_truncate(start: i32):
        while self.result_items.len() as i32 > start:
            let _ = self.result_items.pop()
        return

    mut fn tree_add_child_range(start: i32, count: i32) -> i32:
        let child_start = self.tree.children.len() as i32
        var i = 0
        while i < count:
            self.tree.children.push(self.result_items[(start + i)])
            i = i + 1
        child_start

    mut fn tree_add_child_vec(children: &Vec[i32]) -> i32:
        let child_start = self.tree.children.len() as i32
        var i: i64 = 0
        while i < children.len():
            self.tree.children.push(children.get(i))
            i = i + 1
        child_start

    mut fn tree_add_values_from_vec(values: &Vec[i32]) -> i32:
        let start = self.tree.values.len() as i32
        var i: i64 = 0
        while i < values.len():
            self.tree.values.push(values.get(i))
            i = i + 1
        start

    mut fn tree_add_target_args(target: StackifyTarget) -> i32:
        let start = self.tree.values.len() as i32
        var i = 0
        while i < target.args_count:
            self.tree.values.push(self.graph.target_args[(target.args_start + i)])
            i = i + 1
        start

    mut fn tree_add_block_params(block: i32) -> i32:
        let b = self.graph.blocks[block]
        let params_start: i32 = b.params_start
        let params_count: i32 = b.params_count
        let start = self.tree.values.len() as i32
        var i = 0
        while i < params_count:
            self.tree.values.push(self.graph.block_params[(params_start + i)])
            i = i + 1
        start

    mut fn tree_add_node(node: StackifyNode) -> i32:
        let id = self.tree.nodes.len() as i32
        self.tree.nodes.push(move node)
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

impl StackifyContext:
    mut fn push_process(kind: i32, block: i32, index: i32, value: i32, target: i32):
        self.process_stack.push(StackifyProcessEntry { kind, block, index, value, target })

    mut fn pop_process() -> StackifyProcessEntry:
        self.process_stack.remove(self.process_stack.len() - 1)

    mut fn push_ctrl(kind: i32, label_block: i32):
        self.ctrl_stack.push(StackifyCtrlEntry { kind, label_block })

fn stackify_ctrl_label(entry: &StackifyCtrlEntry) -> i32:
    if entry.kind == StackifyCtrlKind.IfThenElse:
        return stackify_invalid()
    entry.label_block

impl StackifyContext:
    fn resolve_target(target: i32) -> i32:
        var depth = 0
        var i = self.ctrl_stack.len() as i32 - 1
        while i >= 0:
            if stackify_ctrl_label(self.ctrl_stack[i]) == target:
                return depth
            depth = depth + 1
            i = i - 1
        stackify_invalid()

    mut fn add_param_transfer(target: StackifyTarget):
        let id = self.make_param_transfer(target)
        self.result_push(id)

    mut fn make_param_transfer(target: StackifyTarget) -> i32:
        let from_start = self.tree_add_target_args(target)
        let to_start = self.tree_add_block_params(target.block)
        var node = stackify_empty_node(StackifyNodeKind.ParamTransfer)
        node.values_start = from_start
        node.values_count = target.args_count
        node.to_values_start = to_start
        node.to_values_count = self.graph.blocks[target.block].params_count
        self.tree_add_node(move node)

    mut fn push_merge_children(block: i32):
        let start = self.merge_items.len() as i32
        var ri = self.analysis.rpo.len() as i32 - 1
        while ri >= 0:
            let child: i32 = self.analysis.rpo[ri]
            if self.analysis.idom[child] == block and self.analysis.merge_nodes[child] != 0:
                self.merge_items.push(child)
            ri = ri - 1
        self.merge_starts.push(start)
        self.merge_counts.push(self.merge_items.len() as i32 - start)

    mut fn pop_merge_children():
        if self.merge_starts.len() == 0:
            return
        let idx = self.merge_starts.len() as i32 - 1
        let start = self.merge_starts[idx]
        while self.merge_items.len() as i32 > start:
            let _ = self.merge_items.pop()
        let _ = self.merge_starts.pop()
        let _ = self.merge_counts.pop()

    mut fn do_branch(source: i32, target_index: i32):
        let target = self.graph.targets[target_index]
        let source_rpo = self.analysis.rpo_pos[source]
        let target_rpo = self.analysis.rpo_pos[target.block]
        if self.analysis.merge_nodes[target.block] != 0 or target_rpo <= source_rpo:
            let label = self.resolve_target(target.block)
            if label < 0:
                self.ok = false
                self.message = "stackify: branch target is not on the control stack"
                return
            self.add_param_transfer(target)
            var node = stackify_empty_node(StackifyNodeKind.Br)
            node.label = label
            let id = self.tree_add_node(move node)
            self.result_push(id)
            return
        if not stackify_dominates(self.analysis.idom, source, target.block):
            self.ok = false
            self.message = "stackify: forward branch target is not dominated by source"
            return
        self.add_param_transfer(target)
        self.push_process(StackifyProcessKind.DomSubtree, target.block, 0, 0, 0)

    mut fn do_select(block: i32):
        let b = self.graph.blocks[block]
        let selector_value: i32 = b.selector_value
        let targets_start: i32 = b.targets_start
        let targets_count: i32 = b.targets_count
        let default_target: i32 = b.default_target
        let labels_start = self.tree.labels.len() as i32
        var ti = 0
        while ti < targets_count:
            self.tree.labels.push(ti)
            ti = ti + 1
        var select_node = stackify_empty_node(StackifyNodeKind.Select)
        select_node.value = selector_value
        select_node.labels_start = labels_start
        select_node.labels_count = targets_count
        select_node.default_label = targets_count
        let select_id = self.tree_add_node(move select_node)

        var body: Vec[i32] = Vec.new()
        body.push(select_id)
        var extra = targets_count + 1
        var idx = 0
        while idx < targets_count + 1:
            extra = extra - 1
            let target_index = if idx < targets_count: targets_start + idx else: default_target
            let target = self.graph.targets[target_index]
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
            outer.push(self.tree_add_node(move block_node))
            outer.push(self.make_param_transfer(target))
            var br = stackify_empty_node(StackifyNodeKind.Br)
            br.label = resolved + extra
            outer.push(self.tree_add_node(move br))
            body = outer
            idx = idx + 1
        var bi: i64 = 0
        while bi < body.len():
            self.result_push(body.get(bi))
            bi = bi + 1

    mut fn handle_dom_subtree(block: i32):
        self.push_merge_children(block)
        self.push_process(StackifyProcessKind.EndDomSubtree, 0, 0, 0, 0)
        if self.analysis.loop_headers[block] != 0:
            self.push_ctrl(StackifyCtrlKind.Loop, block)
            self.result_push_frame()
            self.push_process(StackifyProcessKind.FinishLoop, block, 0, 0, 0)
            self.push_process(StackifyProcessKind.NodeWithin, block, 0, 0, 0)
        else:
            self.push_process(StackifyProcessKind.NodeWithin, block, 0, 0, 0)

    mut fn finish_loop(header: i32):
        let _ = self.ctrl_stack.pop()
        let start = self.result_pop_frame()
        let count = self.result_frame_count(start)
        let child_start = self.tree_add_child_range(start, count)
        self.result_truncate(start)
        var node = stackify_empty_node(StackifyNodeKind.Loop)
        node.block = header
        node.first_child_start = child_start
        node.first_child_count = count
        let id = self.tree_add_node(move node)
        self.result_push(id)

    mut fn finish_block(out: i32):
        let _ = self.ctrl_stack.pop()
        let start = self.result_pop_frame()
        let count = self.result_frame_count(start)
        let child_start = self.tree_add_child_range(start, count)
        self.result_truncate(start)
        var node = stackify_empty_node(StackifyNodeKind.Block)
        node.block = out
        node.first_child_start = child_start
        node.first_child_count = count
        let id = self.tree_add_node(move node)
        self.result_push(id)

    mut fn else():
        self.result_push_frame()

    mut fn finish_if(cond: i32):
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
        let id = self.tree_add_node(move node)
        self.result_push(id)

    mut fn node_within(block: i32, merge_start: i32):
        let frame_idx = self.merge_starts.len() as i32 - 1
        let start = self.merge_starts[frame_idx]
        let count = self.merge_counts[frame_idx]
        let rel = merge_start
        if rel < count:
            let first: i32 = self.merge_items[(start + rel)]
            self.push_process(StackifyProcessKind.DomSubtree, first, 0, 0, 0)
            self.push_ctrl(StackifyCtrlKind.Block, first)
            self.result_push_frame()
            self.push_process(StackifyProcessKind.FinishBlock, first, 0, 0, 0)
            self.push_process(StackifyProcessKind.NodeWithin, block, rel + 1, 0, 0)
            return

        var leaf = stackify_empty_node(StackifyNodeKind.Leaf)
        leaf.block = block
        let leaf_id = self.tree_add_node(move leaf)
        self.result_push(leaf_id)
        let b = self.graph.blocks[block]
        let term_kind: i32 = b.term_kind
        let targets_start: i32 = b.targets_start
        let cond_value: i32 = b.cond_value
        let return_values_start: i32 = b.return_values_start
        let return_values_count: i32 = b.return_values_count
        if term_kind == StackifyTermKind.Br:
            self.push_process(StackifyProcessKind.DoBranch, block, 0, 0, targets_start)
            return
        if term_kind == StackifyTermKind.CondBr:
            let true_target = targets_start
            let false_target = targets_start + 1
            self.push_ctrl(StackifyCtrlKind.IfThenElse, stackify_invalid())
            self.push_process(StackifyProcessKind.FinishIf, 0, 0, cond_value, 0)
            self.push_process(StackifyProcessKind.DoBranch, block, 0, 0, false_target)
            self.push_process(StackifyProcessKind.Else, 0, 0, 0, 0)
            self.push_process(StackifyProcessKind.DoBranch, block, 0, 0, true_target)
            self.result_push_frame()
            return
        if term_kind == StackifyTermKind.Select:
            self.push_process(StackifyProcessKind.DoSelect, block, 0, 0, 0)
            return
        if term_kind == StackifyTermKind.Return:
            let vals: Vec[i32] = Vec.new()
            var i = 0
            while i < return_values_count:
                vals.push(self.graph.return_values[(return_values_start + i)])
                i = i + 1
            var ret = stackify_empty_node(StackifyNodeKind.Return)
            ret.values_start = self.tree_add_values_from_vec(vals)
            ret.values_count = return_values_count
            let id = self.tree_add_node(move ret)
            self.result_push(id)
            return
        let un = stackify_empty_node(StackifyNodeKind.Unreachable)
        let uid = self.tree_add_node(move un)
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

impl StackifyContext:
    mut fn process(entry: &StackifyProcessEntry):
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
    var analysis = stackify_compute_analysis(graph)
    if not analysis.ok:
        return stackify_result_error(move analysis.message)
    var ctx = stackify_context_new(move graph, move analysis)
    ctx.result_push_frame()
    ctx.push_process(StackifyProcessKind.DomSubtree, ctx.graph.entry, 0, 0, 0)
    while ctx.ok and ctx.process_stack.len() > 0:
        let entry = ctx.pop_process()
        ctx.process(entry)
    if not ctx.ok:
        return stackify_result_error(move ctx.message)
    let root_start = ctx.result_pop_frame()
    let root_count = ctx.result_frame_count(root_start)
    ctx.tree.roots_start = ctx.tree_add_child_range(root_start, root_count)
    ctx.tree.roots_count = root_count
    stackify_result_ok(move ctx.tree)
