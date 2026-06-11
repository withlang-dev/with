// MirLower — Wave 7 MIR lowering from typed AST sidecars.
//
// This pass builds explicit control-flow MIR from the semantic result.

use Ast
use InternPool
use Mir
use Sema
use Overflow
extern fn with_eprint(s: str) -> void
extern fn with_fs_read_file(path: str) -> str

// ── Builder state ────────────────────────────────────────────────

type ScopeEntry {
    local_id: i32,
    drop_kind: i32,
}

type DropScope {
    drops: Vec[ScopeEntry],
}

type LoopInfo {
    label: i32,
    target_kind: i32,
    continue_bb: i32,
    break_bb: i32,
    result_place: i32,
    break_drop_depth: i32,
    break_defer_depth: i32,
    break_scope_depth: i32,
}

enum ControlTargetKind: i32:
    CT_LOOP = 1
    CT_BLOCK = 2

type MirBuilder = ephemeral {
    body: MirBody,
    cur_bb: BlockId,

    // Drop scope stack (flat storage + per-scope start offsets).
    drop_local_ids: Vec[i32],
    drop_kinds: Vec[i32],
    drop_scope_starts: Vec[i32],
    with_cleanup_guard_locals: Vec[i32],
    with_cleanup_payload_locals: Vec[i32],
    with_cleanup_method_syms: Vec[i32],

    // Lexical local bindings (sym -> local id), scoped.
    bind_syms: Vec[i32],
    bind_local_ids: Vec[i32],
    bind_scope_starts: Vec[i32],
    // Non-owning lexical aliases (sym -> place), scoped.
    alias_syms: Vec[i32],
    alias_places: Vec[i32],
    alias_types: Vec[i32],
    alias_scope_starts: Vec[i32],

    // Defer/errdefer stacks (body AST nodes).
    defer_nodes: Vec[i32],
    defer_scope_starts: Vec[i32],
    errdefer_nodes: Vec[i32],
    errdefer_scope_starts: Vec[i32],

    // Structured control target stack.
    loop_continue_bbs: Vec[i32],
    loop_break_bbs: Vec[i32],
    loop_result_places: Vec[i32],
    loop_break_drop_depths: Vec[i32],
    loop_break_defer_depths: Vec[i32],
    loop_break_scope_depths: Vec[i32],
    loop_labels: Vec[i32],
    loop_target_kinds: Vec[i32],

    // First-class goto labels. Blocks are allocated on demand so forward
    // gotos can branch before the label statement is lowered.
    goto_label_syms: Vec[i32],
    goto_label_bbs: Vec[i32],
    goto_label_scope_depths: Vec[i32],
    goto_label_drop_depths: Vec[i32],
    goto_label_defer_depths: Vec[i32],
    goto_label_defined: Vec[i32],

    next_temp: i32,
    cur_node: i32,
    expected_type: i32,
    in_generator: i32,
    generator_yield_count: i32,

    regex_capture_pat_nodes: Vec[i32],
    regex_capture_opt_places: Vec[i32],

    string_alias_local_ids: Vec[i32],
    string_alias_flags: Vec[i32],
    no_suspend_nodes: Vec[i32],

    sema: &Sema,
    ast: AstPool,
    pool: InternPool,
}

fn MirBuilder.init(sema: &Sema, ast: AstPool, pool: InternPool, fn_sym: i32) -> MirBuilder:
    var body = MirBody.init(fn_sym, sema)
    let entry = body.new_block()
    MirBuilder {
        body,
        cur_bb: entry,
        drop_local_ids: Vec.new(),
        drop_kinds: Vec.new(),
        drop_scope_starts: Vec.new(),
        with_cleanup_guard_locals: Vec.new(),
        with_cleanup_payload_locals: Vec.new(),
        with_cleanup_method_syms: Vec.new(),
        bind_syms: Vec.new(),
        bind_local_ids: Vec.new(),
        bind_scope_starts: Vec.new(),
        alias_syms: Vec.new(),
        alias_places: Vec.new(),
        alias_types: Vec.new(),
        alias_scope_starts: Vec.new(),
        defer_nodes: Vec.new(),
        defer_scope_starts: Vec.new(),
        errdefer_nodes: Vec.new(),
        errdefer_scope_starts: Vec.new(),
        loop_continue_bbs: Vec.new(),
        loop_break_bbs: Vec.new(),
        loop_result_places: Vec.new(),
        loop_break_drop_depths: Vec.new(),
        loop_break_defer_depths: Vec.new(),
        loop_break_scope_depths: Vec.new(),
        loop_labels: Vec.new(),
        loop_target_kinds: Vec.new(),
        goto_label_syms: Vec.new(),
        goto_label_bbs: Vec.new(),
        goto_label_scope_depths: Vec.new(),
        goto_label_drop_depths: Vec.new(),
        goto_label_defer_depths: Vec.new(),
        goto_label_defined: Vec.new(),
        next_temp: 0,
        cur_node: 0,
        expected_type: 0,
        in_generator: 0,
        generator_yield_count: 0,
        regex_capture_pat_nodes: Vec.new(),
        regex_capture_opt_places: Vec.new(),
        string_alias_local_ids: Vec.new(),
        string_alias_flags: Vec.new(),
        no_suspend_nodes: Vec.new(),
        sema,
        ast,
        pool,
    }

fn MirBuilder.new_block(self: MirBuilder) -> BlockId:
    self.body.new_block()

fn MirBuilder.switch_to(self: MirBuilder, bb: BlockId):
    self.cur_bb = bb

fn MirBuilder.active_no_suspend_node(self: MirBuilder) -> i32:
    let depth = self.no_suspend_nodes.len() as i32
    if depth == 0:
        return 0
    self.no_suspend_nodes.get((depth - 1) as i64)

fn MirBuilder.mark_no_suspend_terminator(self: MirBuilder):
    let node = self.active_no_suspend_node()
    if node != 0:
        self.body.set_term_no_suspend_node(self.cur_bb, node)

fn MirBuilder.terminate(self: MirBuilder, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32):
    let span = if self.cur_node > 0: self.ast.get_start(self.cur_node) else: 0
    self.body.set_terminator(self.cur_bb, kind, d0, d1, d2, d3, span)
    self.mark_no_suspend_terminator()

fn MirBuilder.terminate_with_span(self: MirBuilder, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32, span: i32):
    self.body.set_terminator(self.cur_bb, kind, d0, d1, d2, d3, span)
    self.mark_no_suspend_terminator()

fn MirBuilder.push_scope(self: MirBuilder) -> void:
    self.drop_scope_starts.push(self.drop_local_ids.len() as i32)
    self.bind_scope_starts.push(self.bind_syms.len() as i32)
    self.alias_scope_starts.push(self.alias_syms.len() as i32)
    self.defer_scope_starts.push(self.defer_nodes.len() as i32)
    self.errdefer_scope_starts.push(self.errdefer_nodes.len() as i32)

fn MirBuilder.schedule_drop(self: MirBuilder, local_id: i32, drop_kind: i32) -> void:
    self.drop_local_ids.push(local_id)
    self.drop_kinds.push(drop_kind)

fn MirBuilder.schedule_with_guard_cleanup(self: MirBuilder, guard_local: i32, payload_local: i32, method_sym: i32, drop_kind: i32) -> void:
    self.with_cleanup_guard_locals.push(guard_local)
    self.with_cleanup_payload_locals.push(payload_local)
    self.with_cleanup_method_syms.push(method_sym)
    self.schedule_drop(guard_local, drop_kind)

fn MirBuilder.with_cleanup_index_for_guard(self: MirBuilder, guard_local: i32) -> i32:
    var i = self.with_cleanup_guard_locals.len() as i32 - 1
    while i >= 0:
        if self.with_cleanup_guard_locals.get(i as i64) == guard_local:
            return i
        i = i - 1
    -1

fn MirBuilder.operand_for_place_arg(self: MirBuilder, place: i32, actual_ty: i32, expected_ty: i32, span: i32) -> i32:
    if expected_ty != 0 and self.sema.can_auto_ref_arg(expected_ty, actual_ty) != 0:
        let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, place, 0)
        let temp = self.new_temp(expected_ty)
        let temp_place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, span)
        return self.body.new_operand(OperandKind.OK_COPY, temp_place)
    self.operand_for_place(place, actual_ty)

fn MirBuilder.emit_with_guard_cleanup(self: MirBuilder, guard_local: i32, drop_kind: i32):
    let cleanup_idx = self.with_cleanup_index_for_guard(guard_local)
    if cleanup_idx < 0:
        return
    let method_sym = self.with_cleanup_method_syms.get(cleanup_idx as i64)
    let payload_local = self.with_cleanup_payload_locals.get(cleanup_idx as i64)
    let sig_idx = self.call_sig_for_sym(method_sym)
    let guard_ty = self.local_type(guard_local)
    let guard_place = self.place_for_local(guard_local)
    let guard_expected = if sig_idx >= 0 and self.sema.sig_get_param_count(sig_idx) > 0: self.sema.sig_param_type(sig_idx, 0) else: 0
    let args: Vec[i32] = Vec.new()
    args.push(self.operand_for_place_arg(guard_place, guard_ty, guard_expected, 0))
    if drop_kind == DropKind.DK_WITH_GUARD_MUT:
        let payload_ty = self.local_type(payload_local)
        let payload_place = self.place_for_local(payload_local)
        let payload_expected = if sig_idx >= 0 and self.sema.sig_get_param_count(sig_idx) > 1: self.sema.sig_param_type(sig_idx, 1) else: 0
        args.push(self.operand_for_place_arg(payload_place, payload_ty, payload_expected, 0))
    let args_id = self.body.new_call_args(args)
    let fn_op = self.const_operand(ConstKind.CK_FN, method_sym, self.sema.ty_void as i32)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, self.place_for_local(0), next_bb)
    self.switch_to(next_bb)
    if payload_local > 0:
        self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, payload_local, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, guard_local, 0, 0)

fn MirBuilder.drop_kind_owns_value(self: MirBuilder, drop_kind: i32) -> i32:
    let _ = self
    if drop_kind == DropKind.DK_VALUE or drop_kind == DropKind.DK_TASK_DETACHED or drop_kind == DropKind.DK_TASK_EPHEMERAL or drop_kind == DropKind.DK_ASYNC_SCOPE or drop_kind == DropKind.DK_THREAD_SCOPE:
        return 1
    0

fn MirBuilder.cancel_scheduled_value_drop_for_local(self: MirBuilder, local_id: i32) -> void:
    var i = self.drop_local_ids.len() as i32 - 1
    while i >= 0:
        if self.drop_local_ids.get(i as i64) == local_id and self.drop_kind_owns_value(self.drop_kinds.get(i as i64)) != 0:
            self.drop_kinds.set_i32(i as i64, DropKind.DK_STORAGE)
            return
        i = i - 1

fn MirBuilder.task_drop_kind_for_binding(self: MirBuilder, node: i32, bind_ty: i32) -> i32:
    if self.sema.type_is_task(bind_ty) == 0:
        return DropKind.DK_VALUE
    if self.sema.ephemeral_task_binding_nodes.contains(node):
        return DropKind.DK_TASK_EPHEMERAL
    DropKind.DK_TASK_DETACHED

fn MirBuilder.emit_task_cancel_call(self: MirBuilder, task_op: i32, intrinsic: MirIntrinsic, node: i32):
    let cancel_args: Vec[i32] = Vec.new()
    cancel_args.push(task_op)
    let cancel_call_id = self.body.new_call_args(cancel_args)
    self.body.set_call_intrinsic(cancel_call_id, intrinsic)
    self.body.set_call_ast_node(cancel_call_id, node)
    let cancel_result_local = self.new_temp(self.sema.ty_i32)
    let cancel_result_place = self.place_for_local(cancel_result_local)
    let after_cancel_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), cancel_call_id, cancel_result_place, after_cancel_bb)
    self.switch_to(after_cancel_bb)

fn MirBuilder.emit_drop_entry(self: MirBuilder, local_id: i32, drop_kind: i32):
    if drop_kind == DropKind.DK_WITH_GUARD or drop_kind == DropKind.DK_WITH_GUARD_MUT:
        self.emit_with_guard_cleanup(local_id, drop_kind)
        return
    if drop_kind == DropKind.DK_STORAGE:
        self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, 0)
        return
    if drop_kind == DropKind.DK_TASK_DETACHED:
        let task_place = self.place_for_local(local_id)
        let task_op = self.body.new_operand(OperandKind.OK_COPY, task_place)
        self.emit_task_cancel_call(task_op, MirIntrinsic.FIBER_DETACH_CANCEL, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, 0)
        return
    if drop_kind == DropKind.DK_TASK_EPHEMERAL:
        let cancel_place = self.place_for_local(local_id)
        let cancel_op = self.body.new_operand(OperandKind.OK_COPY, cancel_place)
        self.emit_task_cancel_call(cancel_op, MirIntrinsic.FIBER_CANCEL, 0)
        let await_place = self.place_for_local(local_id)
        let await_op = self.body.new_operand(OperandKind.OK_COPY, await_place)
        self.lower_cleanup_await(await_op, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, 0)
        return
    if drop_kind == DropKind.DK_ASYNC_SCOPE:
        let scope_place = self.place_for_local(local_id)
        let scope_op = self.body.new_operand(OperandKind.OK_COPY, scope_place)
        let await_all_args: Vec[i32] = Vec.new()
        await_all_args.push(scope_op)
        let await_all_call_id = self.body.new_call_args(await_all_args)
        self.body.set_call_intrinsic(await_all_call_id, MirIntrinsic.SCOPE_AWAIT_ALL)
        let await_all_result = self.new_temp(0)
        let await_all_place = self.place_for_local(await_all_result)
        let after_await_all_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), await_all_call_id, await_all_place, after_await_all_bb)
        self.switch_to(after_await_all_bb)

        let destroy_args: Vec[i32] = Vec.new()
        destroy_args.push(self.body.new_operand(OperandKind.OK_COPY, scope_place))
        let destroy_call_id = self.body.new_call_args(destroy_args)
        self.body.set_call_intrinsic(destroy_call_id, MirIntrinsic.SCOPE_DESTROY)
        let destroy_result = self.new_temp(0)
        let destroy_place = self.place_for_local(destroy_result)
        let after_destroy_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), destroy_call_id, destroy_place, after_destroy_bb)
        self.switch_to(after_destroy_bb)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, 0)
        return
    if drop_kind == DropKind.DK_THREAD_SCOPE:
        let scope_place = self.place_for_local(local_id)
        let scope_op = self.body.new_operand(OperandKind.OK_COPY, scope_place)
        let join_all_args: Vec[i32] = Vec.new()
        join_all_args.push(scope_op)
        let join_all_call_id = self.body.new_call_args(join_all_args)
        self.body.set_call_intrinsic(join_all_call_id, MirIntrinsic.THREAD_SCOPE_JOIN_ALL)
        let join_all_result = self.new_temp(0)
        let join_all_place = self.place_for_local(join_all_result)
        let after_join_all_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), join_all_call_id, join_all_place, after_join_all_bb)
        self.switch_to(after_join_all_bb)

        let destroy_args: Vec[i32] = Vec.new()
        destroy_args.push(self.body.new_operand(OperandKind.OK_COPY, scope_place))
        let destroy_call_id = self.body.new_call_args(destroy_args)
        self.body.set_call_intrinsic(destroy_call_id, MirIntrinsic.THREAD_SCOPE_DESTROY)
        let destroy_result = self.new_temp(0)
        let destroy_place = self.place_for_local(destroy_result)
        let after_destroy_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), destroy_call_id, destroy_place, after_destroy_bb)
        self.switch_to(after_destroy_bb)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, 0)
        return
    let place = self.body.new_place(local_id)
    self.body.push_stmt(self.cur_bb, StmtKind.Drop, place, 0, 0)

fn MirBuilder.pop_scope_with_goto(self: MirBuilder, target_bb: i32):
    if self.drop_scope_starts.len() as i32 == 0:
        self.terminate(TermKind.TK_GOTO, target_bb, 0, 0, 0)
        return

    let scope_idx = self.drop_scope_starts.len() as i32 - 1
    let drop_start = self.drop_scope_starts.get(scope_idx as i64)
    var i = self.drop_local_ids.len() as i32 - 1
    while i >= drop_start:
        self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
        i = i - 1

    while self.drop_local_ids.len() as i32 > drop_start:
        self.drop_local_ids.pop()
        self.drop_kinds.pop()
    self.drop_scope_starts.pop()
    self.defer_scope_starts.pop()
    self.errdefer_scope_starts.pop()

    let bind_start = self.bind_scope_starts.get(scope_idx as i64)
    while self.bind_syms.len() as i32 > bind_start:
        self.bind_syms.pop()
        self.bind_local_ids.pop()
    self.bind_scope_starts.pop()

    let alias_start = self.alias_scope_starts.get(scope_idx as i64)
    while self.alias_syms.len() as i32 > alias_start:
        self.alias_syms.pop()
        self.alias_places.pop()
        self.alias_types.pop()
    self.alias_scope_starts.pop()

    self.terminate(TermKind.TK_GOTO, target_bb, 0, 0, 0)

fn MirBuilder.pop_scope_inline(self: MirBuilder):
    if self.drop_scope_starts.len() as i32 == 0:
        return

    let scope_idx = self.drop_scope_starts.len() as i32 - 1
    let drop_start = self.drop_scope_starts.get(scope_idx as i64)
    var i = self.drop_local_ids.len() as i32 - 1
    while i >= drop_start:
        self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
        i = i - 1

    while self.drop_local_ids.len() as i32 > drop_start:
        self.drop_local_ids.pop()
        self.drop_kinds.pop()
    self.drop_scope_starts.pop()
    self.defer_scope_starts.pop()
    self.errdefer_scope_starts.pop()

    let bind_start = self.bind_scope_starts.get(scope_idx as i64)
    while self.bind_syms.len() as i32 > bind_start:
        self.bind_syms.pop()
        self.bind_local_ids.pop()
    self.bind_scope_starts.pop()

    let alias_start = self.alias_scope_starts.get(scope_idx as i64)
    while self.alias_syms.len() as i32 > alias_start:
        self.alias_syms.pop()
        self.alias_places.pop()
        self.alias_types.pop()
    self.alias_scope_starts.pop()

fn MirBuilder.emit_drops_for_break(self: MirBuilder, loop_info: LoopInfo):
    var i = self.drop_local_ids.len() as i32 - 1
    while i >= loop_info.break_drop_depth:
        self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
        i = i - 1

fn MirBuilder.emit_defers_for_range(self: MirBuilder, start: i32, end: i32):
    var i = end - 1
    while i >= start:
        let defer_body = self.defer_nodes.get(i as i64)
        let _ = self.lower_expr(defer_body)
        i = i - 1

fn MirBuilder.emit_drops_for_range(self: MirBuilder, start: i32, end: i32):
    var i = end - 1
    while i >= start:
        self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
        i = i - 1

fn MirBuilder.emit_cleanup_to_target(self: MirBuilder, target: LoopInfo):
    var scope_idx = self.drop_scope_starts.len() as i32 - 1
    var lowest_drop_start = self.drop_local_ids.len() as i32
    var lowest_defer_start = self.defer_nodes.len() as i32
    while scope_idx >= target.break_scope_depth:
        let defer_start = self.defer_scope_starts.get(scope_idx as i64)
        let defer_end = if scope_idx + 1 < self.defer_scope_starts.len() as i32: self.defer_scope_starts.get((scope_idx + 1) as i64) else: self.defer_nodes.len() as i32
        lowest_defer_start = defer_start
        self.emit_defers_for_range(defer_start, defer_end)

        let drop_start = self.drop_scope_starts.get(scope_idx as i64)
        let drop_end = if scope_idx + 1 < self.drop_scope_starts.len() as i32: self.drop_scope_starts.get((scope_idx + 1) as i64) else: self.drop_local_ids.len() as i32
        lowest_drop_start = drop_start
        self.emit_drops_for_range(drop_start, drop_end)
        scope_idx = scope_idx - 1

    self.emit_defers_for_range(target.break_defer_depth, lowest_defer_start)
    self.emit_drops_for_range(target.break_drop_depth, lowest_drop_start)

fn MirBuilder.emit_drops_for_return(self: MirBuilder):
    var i = self.drop_local_ids.len() as i32 - 1
    while i >= 0:
        self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
        i = i - 1

fn MirBuilder.emit_defers_for_return(self: MirBuilder):
    var i = self.defer_nodes.len() as i32 - 1
    while i >= 0:
        let defer_body = self.defer_nodes.get(i as i64)
        let _ = self.lower_expr(defer_body)
        i = i - 1

fn MirBuilder.emit_errdefers_for_return(self: MirBuilder):
    var i = self.errdefer_nodes.len() as i32 - 1
    while i >= 0:
        let errdefer_body = self.errdefer_nodes.get(i as i64)
        let _ = self.lower_expr(errdefer_body)
        i = i - 1

fn MirBuilder.push_control_target(self: MirBuilder, label: i32, target_kind: i32, continue_bb: i32, break_bb: i32, result_place: i32) -> void:
    self.loop_continue_bbs.push(continue_bb)
    self.loop_break_bbs.push(break_bb)
    self.loop_result_places.push(result_place)
    self.loop_break_drop_depths.push(self.drop_local_ids.len() as i32)
    self.loop_break_defer_depths.push(self.defer_nodes.len() as i32)
    self.loop_break_scope_depths.push(self.drop_scope_starts.len() as i32)
    self.loop_labels.push(label)
    self.loop_target_kinds.push(target_kind)

fn MirBuilder.pop_control_target(self: MirBuilder):
    if self.loop_continue_bbs.len() as i32 == 0:
        return
    self.loop_continue_bbs.pop()
    self.loop_break_bbs.pop()
    self.loop_result_places.pop()
    self.loop_break_drop_depths.pop()
    self.loop_break_defer_depths.pop()
    self.loop_break_scope_depths.pop()
    self.loop_labels.pop()
    self.loop_target_kinds.pop()

fn MirBuilder.find_control_target(self: MirBuilder, label: i32, want_continue: i32) -> LoopInfo:
    if self.loop_continue_bbs.len() as i32 == 0:
        return LoopInfo { label: 0, target_kind: 0, continue_bb: -1, break_bb: -1, result_place: -1, break_drop_depth: 0, break_defer_depth: 0, break_scope_depth: 0 }

    var i = self.loop_continue_bbs.len() as i32 - 1
    while i >= 0:
        let target_kind = self.loop_target_kinds.get(i as i64)
        let target_label = self.loop_labels.get(i as i64)
        var matches = 0
        if label != 0:
            if target_label == label:
                matches = 1
        else if target_kind == ControlTargetKind.CT_LOOP:
            matches = 1
        if matches != 0:
            if want_continue != 0 and target_kind != ControlTargetKind.CT_LOOP:
                return LoopInfo { label: target_label, target_kind, continue_bb: -1, break_bb: self.loop_break_bbs.get(i as i64), result_place: self.loop_result_places.get(i as i64), break_drop_depth: self.loop_break_drop_depths.get(i as i64), break_defer_depth: self.loop_break_defer_depths.get(i as i64), break_scope_depth: self.loop_break_scope_depths.get(i as i64) }
            return LoopInfo {
                label: target_label,
                target_kind,
                continue_bb: self.loop_continue_bbs.get(i as i64),
                break_bb: self.loop_break_bbs.get(i as i64),
                result_place: self.loop_result_places.get(i as i64),
                break_drop_depth: self.loop_break_drop_depths.get(i as i64),
                break_defer_depth: self.loop_break_defer_depths.get(i as i64),
                break_scope_depth: self.loop_break_scope_depths.get(i as i64),
            }
        i = i - 1
    LoopInfo { label: 0, target_kind: 0, continue_bb: -1, break_bb: -1, result_place: -1, break_drop_depth: 0, break_defer_depth: 0, break_scope_depth: 0 }

fn MirBuilder.find_goto_label_index(self: MirBuilder, label: i32) -> i32:
    var i = 0
    while i < self.goto_label_syms.len() as i32:
        if self.goto_label_syms.get(i as i64) == label:
            return i
        i = i + 1
    -1

fn MirBuilder.ensure_goto_label(self: MirBuilder, label: i32, scope_depth: i32) -> i32:
    let existing = self.find_goto_label_index(label)
    if existing >= 0:
        if scope_depth >= 0 and self.goto_label_scope_depths.get(existing as i64) < 0:
            self.goto_label_scope_depths.set_i32(existing as i64, scope_depth)
        return existing
    let bb = self.new_block()
    self.goto_label_syms.push(label)
    self.goto_label_bbs.push(bb)
    self.goto_label_scope_depths.push(scope_depth)
    self.goto_label_drop_depths.push(0)
    self.goto_label_defer_depths.push(0)
    self.goto_label_defined.push(0)
    self.goto_label_syms.len() as i32 - 1

fn MirBuilder.collect_goto_label_depths(self: MirBuilder, node: i32, scope_depth: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_LABEL:
        let _ = self.ensure_goto_label(self.ast.get_data0(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        return
    if kind == NodeKind.NK_CLOSURE or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_ASYNC_SCOPE or kind == NodeKind.NK_SCOPE:
        return
    if kind == NodeKind.NK_BLOCK:
        let stmt_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        for si in 0..stmt_count:
            self.collect_goto_label_depths(self.ast.get_extra(stmt_start + si), scope_depth + 1)
        self.collect_goto_label_depths(self.ast.get_data2(node), scope_depth + 1)
        return
    if kind == NodeKind.NK_IF_EXPR:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data2(node), scope_depth)
        return
    if kind == NodeKind.NK_WHILE:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        return
    if kind == NodeKind.NK_DO_WHILE:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        return
    if kind == NodeKind.NK_LOOP:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        return
    if kind == NodeKind.NK_FOR:
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data2(node), scope_depth)
        return
    if kind == NodeKind.NK_MATCH:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        let arm_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        for ai in 0..arm_count:
            self.collect_goto_label_depths(self.ast.get_extra(arm_start + ai), scope_depth)
        return
    if kind == NodeKind.NK_MATCH_ARM:
        self.collect_goto_label_depths(self.ast.get_data2(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        return
    if kind == NodeKind.NK_RETURN or kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_YIELD or kind == NodeKind.NK_COMPTIME or kind == NodeKind.NK_UNSAFE_BLOCK or kind == NodeKind.NK_COPY_ARG or kind == NodeKind.NK_MOVE_ARG or kind == NodeKind.NK_NO_SUSPEND:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        return
    if kind == NodeKind.NK_BINARY:
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data2(node), scope_depth)
        return
    if kind == NodeKind.NK_UNARY:
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        return
    if kind == NodeKind.NK_LET_BINDING:
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        return
    if kind == NodeKind.NK_LET_ELSE:
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data2(node), scope_depth)
        return
    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        self.collect_goto_label_depths(self.ast.get_data2(node), scope_depth)
        return
    if kind == NodeKind.NK_ASSIGN or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_INDEX or kind == NodeKind.NK_PIPELINE or kind == NodeKind.NK_RANGE:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        return
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_CAST:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        return
    if kind == NodeKind.NK_SLICE:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data2(node), scope_depth)
        return
    if kind == NodeKind.NK_CALL:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        let arg_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai2 in 0..arg_count:
            self.collect_goto_label_depths(self.ast.get_extra(arg_start + ai2), scope_depth)
        return
    if kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT:
        let elem_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            self.collect_goto_label_depths(self.ast.get_extra(elem_start + ei), scope_depth)
        return
    if kind == NodeKind.NK_STRUCT_LIT:
        let field_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for fi in 0..field_count:
            self.collect_goto_label_depths(self.ast.get_extra(field_start + fi * 2 + 1), scope_depth)
        return
    if kind == NodeKind.NK_RECORD_UPDATE:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        let field_start2 = self.ast.get_data1(node)
        let field_count2 = self.ast.get_data2(node)
        for fi2 in 0..field_count2:
            self.collect_goto_label_depths(self.ast.get_extra(field_start2 + fi2 * 2 + 1), scope_depth)
        return
    if kind == NodeKind.NK_WITH_EXPR or kind == NodeKind.NK_WITH_IMPLICIT or kind == NodeKind.NK_WITH_TUPLE:
        self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
        self.collect_goto_label_depths(self.ast.get_data1(node), scope_depth + 1)
        return
    if kind == NodeKind.NK_SELECT_AWAIT:
        let arm_start2 = self.ast.get_data0(node)
        let arm_count2 = self.ast.get_data1(node)
        for sai in 0..arm_count2:
            self.collect_goto_label_depths(self.ast.get_extra(arm_start2 + sai * 3 + 1), scope_depth)
            self.collect_goto_label_depths(self.ast.get_extra(arm_start2 + sai * 3 + 2), scope_depth + 1)
        return

fn MirBuilder.define_goto_label(self: MirBuilder, label: i32) -> i32:
    let idx = self.ensure_goto_label(label, self.drop_scope_starts.len() as i32)
    let bb = self.goto_label_bbs.get(idx as i64)
    self.goto_label_drop_depths.set_i32(idx as i64, self.drop_local_ids.len() as i32)
    self.goto_label_defer_depths.set_i32(idx as i64, self.defer_nodes.len() as i32)
    self.goto_label_scope_depths.set_i32(idx as i64, self.drop_scope_starts.len() as i32)
    self.goto_label_defined.set_i32(idx as i64, 1)
    if self.cur_bb != bb and self.body.term_kind(self.cur_bb) == TermKind.TK_UNREACHABLE:
        self.terminate(TermKind.TK_GOTO, bb, 0, 0, 0)
    self.switch_to(bb)
    bb

fn MirBuilder.goto_target_info(self: MirBuilder, label: i32) -> LoopInfo:
    let idx = self.ensure_goto_label(label, -1)
    let bb = self.goto_label_bbs.get(idx as i64)
    if self.goto_label_defined.get(idx as i64) != 0:
        return LoopInfo {
            label,
            target_kind: ControlTargetKind.CT_BLOCK,
            continue_bb: -1,
            break_bb: bb,
            result_place: -1,
            break_drop_depth: self.goto_label_drop_depths.get(idx as i64),
            break_defer_depth: self.goto_label_defer_depths.get(idx as i64),
            break_scope_depth: self.goto_label_scope_depths.get(idx as i64),
        }
    var scope_depth = self.goto_label_scope_depths.get(idx as i64)
    if scope_depth < 0:
        scope_depth = self.drop_scope_starts.len() as i32
    var drop_depth = self.drop_local_ids.len() as i32
    if scope_depth < self.drop_scope_starts.len() as i32:
        drop_depth = self.drop_scope_starts.get(scope_depth as i64)
    var defer_depth = self.defer_nodes.len() as i32
    if scope_depth < self.defer_scope_starts.len() as i32:
        defer_depth = self.defer_scope_starts.get(scope_depth as i64)
    LoopInfo {
        label,
        target_kind: ControlTargetKind.CT_BLOCK,
        continue_bb: -1,
        break_bb: bb,
        result_place: -1,
        break_drop_depth: drop_depth,
        break_defer_depth: defer_depth,
        break_scope_depth: scope_depth,
    }

fn MirBuilder.bind_local(self: MirBuilder, sym: i32, local_id: i32) -> void:
    self.bind_syms.push(sym)
    self.bind_local_ids.push(local_id)

fn MirBuilder.bind_alias_place(self: MirBuilder, sym: i32, place: i32, ty: i32) -> void:
    self.alias_syms.push(sym)
    self.alias_places.push(place)
    self.alias_types.push(ty)

fn MirBuilder.lookup_local(self: MirBuilder, sym: i32) -> i32:
    var i = self.bind_syms.len() as i32 - 1
    while i >= 0:
        if self.bind_syms.get(i as i64) == sym:
            return self.bind_local_ids.get(i as i64)
        i = i - 1
    -1

fn MirBuilder.lookup_alias_place(self: MirBuilder, sym: i32) -> i32:
    var i = self.alias_syms.len() as i32 - 1
    while i >= 0:
        if self.alias_syms.get(i as i64) == sym:
            return self.alias_places.get(i as i64)
        i = i - 1
    -1

fn MirBuilder.lookup_alias_type(self: MirBuilder, sym: i32) -> i32:
    var i = self.alias_syms.len() as i32 - 1
    while i >= 0:
        if self.alias_syms.get(i as i64) == sym:
            return self.alias_types.get(i as i64)
        i = i - 1
    0

fn MirBuilder.expr_type(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.sema.ty_void as i32
    if self.sema.typed_expr_types.contains(node):
        let typed = self.sema.typed_expr_types.get(node).unwrap()
        if typed != 0:
            if typed == self.sema.ty_void as i32 and self.ast.kind(node) == NodeKind.NK_FIELD_ACCESS:
                return self.fallback_expr_type(node)
            return typed as i32
    self.fallback_expr_type(node)

fn MirBuilder.mir_const_int_width(self: MirBuilder, type_id: i32) -> i32:
    let numeric = self.sema.numeric_operand_type(type_id)
    let resolved = self.sema.resolve_alias(numeric as TypeId)
    if self.sema.get_type_kind(resolved) == TypeKind.TY_INT:
        return self.sema.get_type_d0(resolved)
    64

fn MirBuilder.mir_const_int_is_unsigned(self: MirBuilder, type_id: i32) -> bool:
    let numeric = self.sema.numeric_operand_type(type_id)
    let resolved = self.sema.resolve_alias(numeric as TypeId)
    if self.sema.get_type_kind(resolved) == TypeKind.TY_INT:
        return self.sema.get_type_d1(resolved) == 0
    false

fn MirBuilder.binding_type(self: MirBuilder, node: i32) -> i32:
    if self.sema.typed_binding_types.contains(node):
        let typed = self.sema.typed_binding_types.get(node).unwrap()
        if typed != 0:
            return typed as i32
    let flags = self.ast.get_data2(node)
    let ann_extra = self.sema.local_let_type_ann_extra(flags)
    if ann_extra >= 0:
        let ann_node = self.ast.get_extra(ann_extra)
        let ann_type = self.sema.resolve_type_expr(ann_node)
        if ann_type != 0:
            return ann_type as i32
    let rhs = self.ast.get_data1(node)
    let rhs_ty = self.expr_type(rhs)
    if rhs_ty != 0:
        return rhs_ty
    self.sema.ty_void as i32

fn MirBuilder.local_type(self: MirBuilder, local_id: i32) -> i32:
    if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
        return self.sema.ty_void as i32
    self.body.local_type_ids.get(local_id as i64) as i32

fn MirBuilder.ident_type(self: MirBuilder, sym: i32) -> i32:
    let local = self.lookup_local(sym)
    if local >= 0:
        return self.local_type(local)
    let alias_ty = self.lookup_alias_type(sym)
    if alias_ty != 0:
        return alias_ty
    let sig_idx = self.sema.get_sig(sym)
    if sig_idx >= 0:
        return self.sema.sig_type_ids.get(sig_idx as i64) as i32
    if self.sema.named_types.contains(sym):
        return self.sema.named_types.get(sym).unwrap() as i32
    if self.sema.variant_lookup.contains(sym):
        return self.sema.variant_type_ids.get(sym).unwrap() as i32
    self.sema.ty_void as i32

fn MirBuilder.resolve_index_generic_inst(self: MirBuilder, node: i32) -> i32:
    // Resolve NodeKind.NK_INDEX(NodeKind.NK_IDENT("Vec"), type_arg) to a TypeKind.TY_GENERIC_INST.
    // Used for Vec[i32].new() and HashMap[str, i32].new().
    // Sema.check_index creates these during the check pass; we only look up here.
    let base = self.ast.get_data0(node)
    if self.ast.kind(base) != NodeKind.NK_IDENT:
        return 0
    let base_sym = self.ast.get_data0(base)
    if not self.sema.named_types.contains(base_sym):
        return 0
    // Resolve the first type argument (d1 of NodeKind.NK_INDEX)
    let type_arg_node = self.ast.get_data1(node)
    if type_arg_node == 0:
        return 0
    var arg_type = self.resolve_type_arg_node(type_arg_node)
    if arg_type == 0:
        return 0
    // Check for second type argument (d2 of NodeKind.NK_INDEX) — HashMap[K, V]
    let type_arg2_node = self.ast.get_data2(node)
    var arg2_type = 0
    if type_arg2_node != 0:
        arg2_type = self.resolve_type_arg_node(type_arg2_node)
    // Look up TypeKind.TY_GENERIC_INST from sema cache (created by Sema.check_index)
    var cache_key: i64 = (base_sym as i64 *% 31) +% arg_type as i64
    if arg2_type > 0:
        cache_key = (cache_key *% 31) +% arg2_type as i64
    if self.sema.generic_inst_cache.contains(cache_key):
        return self.sema.generic_inst_cache.get(cache_key).unwrap()
    0

fn MirBuilder.resolve_type_arg_node(self: MirBuilder, type_arg_node: i32) -> i32:
    self.sema.resolve_type_level_arg_expr(type_arg_node)

fn MirBuilder.type_receiver_type(self: MirBuilder, node: i32) -> i32:
    // Resolve a type-level receiver expression to its base sema type.
    // Used for intrinsic classification (Vec, HashMap, etc.)
    // Handles: Vec (NodeKind.NK_IDENT), Vec[i32] (NodeKind.NK_INDEX of NodeKind.NK_IDENT)
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_GENERIC or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_TUPLE or kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_EXTERN_FN or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        return self.sema.resolve_type_expr(node) as i32
    if self.ast.kind(node) == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        if self.sema.named_types.contains(sym):
            return self.sema.named_types.get(sym).unwrap()
    if self.ast.kind(node) == NodeKind.NK_INDEX:
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) == NodeKind.NK_IDENT:
            let sym = self.ast.get_data0(base)
            if self.sema.named_types.contains(sym):
                return self.sema.named_types.get(sym).unwrap()
    0

fn MirBuilder.index_expr_is_type_level(self: MirBuilder, expr: i32) -> bool:
    if expr == 0:
        return false
    let kind = self.ast.kind(expr)
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(expr)
        return self.sema.named_types.contains(sym)
    if kind == NodeKind.NK_INDEX or kind == NodeKind.NK_GROUPED:
        return self.index_expr_is_type_level(self.ast.get_data0(expr))
    false

fn MirBuilder.vec_literal_type(self: MirBuilder, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_INDEX:
        return 0
    let base_expr = self.ast.get_data0(node)
    if not self.index_expr_is_type_level(base_expr):
        return 0
    let vec_ty = self.expr_type(node)
    if vec_ty == 0 or vec_ty == self.sema.ty_void:
        return 0
    let resolved = self.sema.resolve_alias(vec_ty) as i32
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    let base_sym = self.sema.get_type_d0(resolved)
    if base_sym == 0:
        return 0
    if self.pool.resolve_symbol(base_sym) != "Vec":
        return 0
    resolved

fn MirBuilder.collection_len_method_return_type(self: MirBuilder, method_name: str) -> i32:
    if method_name == "len":
        return self.sema.ty_usize as i32
    if method_name == "len32":
        return self.sema.ty_i32 as i32
    if method_name == "len64":
        return self.sema.ty_i64 as i32
    if method_name == "ulen32":
        return self.sema.ty_u32 as i32
    0

fn MirBuilder.call_return_type(self: MirBuilder, callee: i32) -> i32:
    if callee == 0:
        return self.sema.ty_void as i32
    let kind = self.ast.kind(callee)
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(callee)
        let sig_idx = self.sema.get_sig(sym)
        if sig_idx >= 0:
            return self.sema.sig_return_type(sig_idx) as i32
        return self.sema.ty_void as i32
    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = self.ast.get_data0(callee)
        let method_sym = self.ast.get_data1(callee)
        let resolved = self.resolve_method_callee_sym(base, method_sym)
        let resolved_sig = self.sema.get_sig(resolved)
        if resolved_sig >= 0:
            return self.sema.sig_return_type(resolved_sig) as i32
        let bare_sig = self.sema.get_sig(method_sym)
        if bare_sig >= 0:
            return self.sema.sig_return_type(bare_sig) as i32
        // Intrinsic methods (Vec/HashMap/Option/str) have no sema sigs.
        // Resolve their return types from the receiver type + method name.
        var base_ty = self.expr_type(base)
        if base_ty == 0 or base_ty == self.sema.ty_void as i32:
            base_ty = self.type_receiver_type(base)
        if base_ty != 0 and base_ty != self.sema.ty_void as i32:
            let method_name = self.pool.resolve_symbol(method_sym)
            let iret = self.intrinsic_return_type(base_ty, method_name)
            if iret != 0 and iret != self.sema.ty_void as i32:
                return iret
            // Sema reports raw value types for Option-returning intrinsics
            // (e.g. HashMap.get returns str, not Option[str]). When .unwrap()
            // is chained, intrinsic_return_type can't match "unwrap" on str.
            // The unwrap just returns the same type sema already reports.
            if method_name == "unwrap":
                return base_ty
            if method_name == "is_some" or method_name == "is_none":
                return self.sema.ty_bool as i32
        // Qualified enum variant constructor: EnumType.Variant(...)
        let recv_ty = if base_ty != 0 and base_ty != self.sema.ty_void as i32: base_ty else: self.type_receiver_type(base)
        if recv_ty != 0 and recv_ty != self.sema.ty_void as i32 and self.sema.enum_has_variant(recv_ty, method_sym) != 0:
            return recv_ty
    self.sema.ty_void as i32

fn MirBuilder.intrinsic_return_type(self: MirBuilder, recv_type: i32, method_name: str) -> i32:
    // Return known return types for intrinsic (builtin) methods.
    // These methods have no sema signatures, so call_return_type can't resolve them.
    let resolved = self.sema.resolve_alias(recv_type) as i32
    let tk = self.sema.get_type_kind(resolved)
    let type_name_sym = self.sema.get_type_name(resolved)
    let len_method_ret = self.collection_len_method_return_type(method_name)
    if type_name_sym != 0:
        let type_name = self.pool.resolve_symbol(type_name_sym)
        if type_name == "Vec":
            if len_method_ret != 0: return len_method_ret
            if method_name == "new": return recv_type
            if method_name == "push": return recv_type
            if method_name == "set_i32" or method_name == "remove" or method_name == "clear":
                return self.sema.ty_void as i32
            if method_name == "get" or method_name == "pop":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "join": return self.sema.ty_str as i32
            if method_name == "filter": return recv_type
            if method_name == "map": return self.expr_type(self.cur_node)
            if method_name == "iter":
                // Vec.iter() returns VecIter[T] with same T as Vec[T].
                let vi_sym = self.sema.pool_lookup_symbol("VecIter")
                if self.sema.named_types.contains(vi_sym):
                    if tk == TypeKind.TY_GENERIC_INST:
                        let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                        if elem_ty > 0:
                            let found = self.sema.find_generic_inst(vi_sym, elem_ty)
                            if found != 0:
                                return found
                    return self.sema.named_types.get(vi_sym).unwrap() as i32
                return self.sema.ty_void as i32
            if method_name == "slot":
                // Vec.slot(i) returns VecSlot[T] with same T as Vec[T].
                let vs_sym = self.sema.pool_lookup_symbol("VecSlot")
                if self.sema.named_types.contains(vs_sym):
                    if tk == TypeKind.TY_GENERIC_INST:
                        let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                        if elem_ty > 0:
                            let found = self.sema.find_generic_inst(vs_sym, elem_ty)
                            if found != 0:
                                return found
                    return self.sema.named_types.get(vs_sym).unwrap() as i32
                return self.sema.ty_void as i32
            if method_name == "iter_place":
                // Vec.iter_place() returns VecIterPlace[T] with same T as Vec[T].
                let vip_sym = self.sema.pool_lookup_symbol("VecIterPlace")
                if self.sema.named_types.contains(vip_sym):
                    if tk == TypeKind.TY_GENERIC_INST:
                        let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                        if elem_ty > 0:
                            let found = self.sema.find_generic_inst(vip_sym, elem_ty)
                            if found != 0:
                                return found
                    return self.sema.named_types.get(vip_sym).unwrap() as i32
                return self.sema.ty_void as i32
            return self.sema.ty_void as i32
        if type_name == "VecSlot":
            if method_name == "get":
                // VecSlot[T].get() returns T.
                if tk == TypeKind.TY_GENERIC_INST:
                    let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                    return elem_ty
            if method_name == "set":
                return self.sema.ty_void as i32
            return self.sema.ty_void as i32
        if type_name == "SlotMap":
            if method_name == "new":
                return recv_type
            if tk == TypeKind.TY_GENERIC_INST:
                let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                if method_name == "insert":
                    return self.sema.ensure_handle_type_for(elem_ty)
                if method_name == "get":
                    return self.sema.ensure_option_ref_type_for(elem_ty)
                if method_name == "slot":
                    return self.sema.ensure_slotmapslot_type_for(elem_ty)
                if method_name == "get_disjoint":
                    let slot_ty = self.sema.ensure_slotmapslot_type_for(elem_ty)
                    let elems: Vec[i32] = Vec.new()
                    elems.push(slot_ty)
                    elems.push(slot_ty)
                    return self.sema.ensure_tuple_type(elems, 2) as i32
                if method_name == "remove" or method_name == "replace":
                    return self.sema.ensure_option_type_for(elem_ty)
                if method_name == "contains":
                    return self.sema.ty_bool as i32
                if len_method_ret != 0:
                    return len_method_ret
            return self.sema.ty_void as i32
        if type_name == "SlotMapSlot":
            if method_name == "get":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "set":
                return self.sema.ty_void as i32
            return self.sema.ty_void as i32
        if type_name == "VecIterPlace":
            if method_name == "next":
                // VecIterPlace[T].next() returns Option[VecSlot[T]].
                if tk == TypeKind.TY_GENERIC_INST:
                    let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                    let vs_sym = self.sema.pool_lookup_symbol("VecSlot")
                    var vs_tid = self.sema.find_generic_inst(vs_sym, elem_ty)
                    if vs_tid == 0:
                        let vs_args: Vec[i32] = Vec.new()
                        vs_args.push(elem_ty)
                        vs_tid = self.sema.ensure_generic_inst_type(vs_sym, vs_args, 1) as i32
                    let opt_sym = self.sema.pool_lookup_symbol("Option")
                    let opt_tid = self.sema.find_generic_inst(opt_sym, vs_tid)
                    if opt_tid != 0:
                        return opt_tid
                    let opt_args: Vec[i32] = Vec.new()
                    opt_args.push(vs_tid)
                    return self.sema.ensure_generic_inst_type(opt_sym, opt_args, 1) as i32
            return self.sema.ty_void as i32
        if type_name == "VecIter":
            if method_name == "next":
                // VecIter[T].next() returns Option[T].
                if tk == TypeKind.TY_GENERIC_INST:
                    let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                    let opt_sym = self.sema.pool_lookup_symbol("Option")
                    let opt_tid = self.sema.find_generic_inst(opt_sym, elem_ty)
                    if opt_tid != 0:
                        return opt_tid
                    return elem_ty
            return self.sema.ty_void as i32
        if type_name == "HashMap":
            if len_method_ret != 0: return len_method_ret
            if method_name == "contains": return self.sema.ty_bool as i32
            if method_name == "new": return recv_type
            if method_name == "insert" or method_name == "clear":
                return self.sema.ty_void as i32
            if method_name == "get" or method_name == "remove":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 1)
            if method_name == "entry":
                if tk == TypeKind.TY_GENERIC_INST:
                    let ek = self.sema.get_generic_inst_arg(resolved, 0)
                    let ev = self.sema.get_generic_inst_arg(resolved, 1)
                    let he_sym = self.sema.pool_lookup_symbol("HashMapEntry")
                    let he_args: Vec[i32] = Vec.new()
                    he_args.push(ek)
                    he_args.push(ev)
                    return self.sema.ensure_generic_inst_type(he_sym, he_args, 2) as i32
            return self.sema.ty_void as i32
        if type_name == "HashMapEntry":
            if method_name == "or_insert" or method_name == "get":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 1)
            if method_name == "set":
                return self.sema.ty_void as i32
            return self.sema.ty_void as i32
        if type_name == "HashSet":
            if len_method_ret != 0: return len_method_ret
            if method_name == "contains" or method_name == "remove": return self.sema.ty_bool as i32
            if method_name == "new": return recv_type
            if method_name == "insert" or method_name == "clear":
                return self.sema.ty_void as i32
            return self.sema.ty_void as i32
        if type_name == "Option":
            if method_name == "is_some" or method_name == "is_none": return self.sema.ty_bool as i32
            if method_name == "unwrap":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "filter":
                return recv_type
            if method_name == "map" or method_name == "and_then":
                return recv_type
            if method_name == "unwrap_or":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "unwrap_or_else":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            return self.sema.ty_void as i32
        if type_name == "Result":
            if method_name == "is_ok": return self.sema.ty_bool as i32
            if method_name == "unwrap":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            return self.sema.ty_void as i32
        if type_name == "Atomic":
            if method_name == "new": return recv_type
            if method_name == "store": return self.sema.ty_void as i32
            if method_name == "load" or method_name == "swap" or method_name == "fetch_add" or method_name == "fetch_sub" or method_name == "fetch_and" or method_name == "fetch_or" or method_name == "fetch_xor" or method_name == "fetch_min" or method_name == "fetch_max":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "compare_exchange" or method_name == "compare_exchange_weak":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            return self.sema.ty_void as i32
    if tk == TypeKind.TY_STR:
        if len_method_ret != 0: return len_method_ret
        if method_name == "byte_at": return self.sema.ty_i32 as i32
        if method_name == "slice": return self.sema.ty_str as i32
        if method_name == "contains" or method_name == "starts_with" or method_name == "ends_with":
            return self.sema.ty_bool as i32
        if method_name == "find": return self.sema.ty_i64 as i32
        if method_name == "repeat": return self.sema.ty_str as i32
        if method_name == "trim" or method_name == "to_upper" or method_name == "to_lower" or method_name == "replace":
            return self.sema.ty_str as i32
        if method_name == "index_of": return self.sema.ty_i64 as i32
        if method_name == "split":
            // str.split() returns Vec[str]
            let vec_sym = self.sema.pool_lookup_symbol("Vec")
            let found = self.sema.find_generic_inst(vec_sym, self.sema.ty_str as i32)
            if found != 0:
                return found
            return self.sema.ty_void as i32
        return self.sema.ty_void as i32
    if tk == TypeKind.TY_ARRAY:
        if len_method_ret != 0: return len_method_ret
        return self.sema.ty_void as i32
    if tk == TypeKind.TY_INT:
        if method_name == "rotate_left" or method_name == "rotate_right" or method_name == "swap_bytes" or method_name == "bitreverse":
            return recv_type
        if method_name == "popcount" or method_name == "clz" or method_name == "ctz":
            return self.sema.ty_i32 as i32
        if method_name == "min" or method_name == "max":
            return recv_type
        if method_name == "abs":
            return self.sema.unsigned_counterpart(recv_type)
    if tk == TypeKind.TY_FLOAT:
        if method_name == "min" or method_name == "max" or method_name == "abs" or method_name == "mul_add":
            return recv_type
    self.sema.ty_void as i32

fn MirBuilder.struct_field_type(self: MirBuilder, struct_tid: i32, field_sym: i32) -> i32:
    let resolved = self.sema.resolve_alias(struct_tid)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
        let inner = self.sema.get_type_d0(resolved)
        return self.struct_field_type(inner, field_sym)
    let direct = self.sema.struct_field_type(resolved as i32, field_sym)
    if direct != 0:
        return direct
    let field_text = self.pool.resolve_symbol(field_sym)
    let sema_field = if field_text.len() > 0: self.sema.pool_lookup_symbol(field_text) else: 0
    if sema_field != 0 and sema_field != field_sym:
        return self.sema.struct_field_type(resolved as i32, sema_field)
    0

fn MirBuilder.tuple_elem_type(self: MirBuilder, tuple_tid: i32, field_idx: i32) -> i32:
    let resolved = self.sema.resolve_alias(tuple_tid)
    let tk = self.sema.get_type_kind(resolved)
    if tk != TypeKind.TY_TUPLE:
        return 0
    let elem_start = self.sema.get_type_d0(resolved)
    let elem_count = self.sema.get_type_d1(resolved)
    if field_idx < 0 or field_idx >= elem_count:
        return 0
    self.sema.type_extra.get((elem_start + field_idx) as i64)

fn MirBuilder.indexed_element_type(self: MirBuilder, collection_tid: i32) -> i32:
    let resolved = self.sema.resolve_alias(collection_tid) as i32
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
        return self.sema.get_type_d0(resolved)
    if tk == TypeKind.TY_STR:
        return self.sema.ty_i32 as i32
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return self.sema.get_type_d0(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.sema.get_generic_inst_base(resolved)
        if self.pool.resolve_symbol(base_sym) == "Vec" and self.sema.get_generic_inst_arg_count(resolved) > 0:
            return self.sema.get_generic_inst_arg(resolved, 0)
    0

fn MirBuilder.is_user_index_place(self: MirBuilder, base_ty: i32) -> i32:
    if base_ty == 0:
        return 0
    let resolved = self.sema.resolve_alias(base_ty) as i32
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE or tk == TypeKind.TY_STR or tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return 0
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.sema.get_generic_inst_base(resolved)
        if base_sym == self.sema.syms.vec or base_sym == self.sema.syms.hashmap:
            return 0
    if self.sema.type_is_index_place(base_ty) != 0:
        return 1
    0

fn MirBuilder.enum_payload_type(self: MirBuilder, enum_tid: i32, variant_idx: i32, field_idx: i32) -> i32:
    let resolved = self.sema.resolve_alias(enum_tid)
    let tk = self.sema.get_type_kind(resolved)
    if variant_idx < 0 or field_idx < 0:
        return 0

    if tk == TypeKind.TY_ENUM:
        let te_start = self.sema.get_type_d1(resolved)
        let variant_count = self.sema.get_type_d2(resolved)
        var pos = te_start
        for vi in 0..variant_count:
            let payload_count = self.sema.type_extra.get((pos + 1) as i64)
            if vi == variant_idx:
                if field_idx < payload_count:
                    return self.sema.type_extra.get((pos + 2 + field_idx) as i64)
                return 0
            pos = pos + 2 + payload_count
        return 0

    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.sema.get_generic_inst_base(resolved)
        if not self.sema.named_types.contains(base_sym):
            return 0
        let base_tid = self.sema.named_types.get(base_sym).unwrap()
        if self.sema.get_type_kind(base_tid) != TypeKind.TY_ENUM:
            return 0
        let te_start = self.sema.get_type_d1(base_tid)
        let variant_count = self.sema.get_type_d2(base_tid)
        var pos = te_start
        for vi in 0..variant_count:
            let variant_name = self.sema.type_extra.get(pos as i64)
            let payload_count = self.sema.type_extra.get((pos + 1) as i64)
            if vi == variant_idx:
                let payload_types = self.sema.resolve_generic_enum_payload(resolved, base_sym, variant_name, payload_count)
                if field_idx < payload_types.len() as i32:
                    let payload_ty = payload_types.get(field_idx as i64)
                    if payload_ty != 0:
                        return payload_ty
                if field_idx < payload_count:
                    return self.sema.type_extra.get((pos + 2 + field_idx) as i64)
                return 0
            pos = pos + 2 + payload_count
    0

fn MirBuilder.fallback_expr_type(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.sema.ty_void as i32
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        return self.ident_type(self.ast.get_data0(node))
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_COPY_ARG or kind == NodeKind.NK_MOVE_ARG:
        return self.expr_type(self.ast.get_data0(node))
    if kind == NodeKind.NK_FIELD_ACCESS:
        let base_node = self.ast.get_data0(node)
        let field_sym = self.ast.get_data1(node)
        let base_ty = self.expr_type(base_node)
        if base_ty != 0 and base_ty != self.sema.ty_void as i32:
            let ft = self.struct_field_type(base_ty, field_sym)
            if ft != 0:
                return ft
            if self.sema.enum_has_variant(base_ty, field_sym) != 0:
                return base_ty
        let recv_ty = self.type_receiver_type(base_node)
        if recv_ty != 0 and recv_ty != self.sema.ty_void as i32 and self.sema.enum_has_variant(recv_ty, field_sym) != 0:
            return recv_ty
        return self.sema.ty_void as i32
    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        let base_node = self.ast.get_data0(node)
        let base_ty = self.expr_type(base_node)
        let extra_start = self.ast.get_data2(node)
        if self.ast.optional_chain_is_call(extra_start) != 0:
            return self.sema.optional_chain_method_result_type_no_check(base_ty, self.ast.get_data1(node)) as i32
        self.sema.optional_chain_result_type(base_ty, self.ast.get_data1(node)) as i32
    if kind == NodeKind.NK_INT_LIT:
        let suffix_ty = self.sema.literal_suffix_type(self.ast.literal_suffix(node as NodeId))
        if suffix_ty != 0:
            return suffix_ty
        let fast = self.ast.int_literal_fast_i64(node as NodeId)
        if fast.ok == 0:
            return self.sema.ty_i64 as i32
        let value = fast.value
        if value < -2147483648 or value > 2147483647:
            return self.sema.ty_i64 as i32
        return self.sema.ty_i32 as i32
    if kind == NodeKind.NK_BOOL_LIT:
        return self.sema.ty_bool as i32
    if kind == NodeKind.NK_REGEX_LIT:
        let regex_ty = self.sema.lookup_named_type_visible(self.sema.syms.regex)
        if regex_ty != 0:
            return regex_ty
        return self.sema.ty_void as i32
    if kind == NodeKind.NK_STRING_LIT:
        return self.sema.ty_str as i32
    if kind == NodeKind.NK_C_STRING_LIT:
        return self.sema.ty_cstr_view as i32
    if kind == NodeKind.NK_FSTRING:
        return self.sema.ty_str as i32
    if kind == NodeKind.NK_NULL_LIT:
        return self.sema.ty_i32 as i32
    if kind == NodeKind.NK_UNSAFE_BLOCK or kind == NodeKind.NK_NO_SUSPEND:
        return self.expr_type(self.ast.get_data0(node))
    if kind == NodeKind.NK_ASM_EXPR:
        let asm_d2 = self.ast.get_data2(node)
        if (asm_d2 & 2) != 0:  // has_output flag
            let asm_es = asm_d2 >> 8
            if asm_es > 0:
                let asm_ot = self.ast.get_extra(asm_es)
                if asm_ot != 0:
                    let asm_rt = self.sema.resolve_type_expr(asm_ot)
                    if asm_rt != 0:
                        return asm_rt as i32
        return self.sema.ty_void as i32
    if kind == NodeKind.NK_CALL:
        return self.call_return_type(self.ast.get_data0(node))
    if kind == NodeKind.NK_ASSIGN:
        let target_ty = self.expr_type(self.ast.get_data0(node))
        if target_ty != 0:
            return target_ty
        return self.sema.ty_void as i32
    if kind == NodeKind.NK_STRUCT_LIT:
        let st_name = self.ast.get_data0(node)
        if self.sema.named_types.contains(st_name):
            return self.sema.named_types.get(st_name).unwrap() as i32
        // Self struct literal — resolve via method context
        let st_name_str = self.sema.pool_resolve(st_name)
        if st_name_str == "Self":
            let fn_sym = self.body.fn_sym
            let fn_name_str = self.sema.pool_resolve(fn_sym)
            for ci in 0..fn_name_str.len() as i32:
                if fn_name_str.byte_at(ci as i64) == 46:
                    let owner_name = fn_name_str.slice(0, ci as i64)
                    let owner_sym = self.sema.pool_lookup_symbol(owner_name)
                    if self.sema.named_types.contains(owner_sym):
                        return self.sema.named_types.get(owner_sym).unwrap() as i32
                    break
    if kind == NodeKind.NK_MATCH:
        // Merge arm body types so payloadless first arms do not collapse the
        // whole expression to void when sema metadata is missing.
        let m_arms_start = self.ast.get_data1(node)
        let m_arms_count = self.ast.get_data2(node)
        var match_ty = 0
        if m_arms_count > 0:
            for mi in 0..m_arms_count:
                let arm_node = self.ast.get_extra(m_arms_start + mi)
                let arm_body = self.ast.get_data1(arm_node)
                if arm_body == 0:
                    continue
                let arm_ty = self.expr_type(arm_body)
                if arm_ty == 0 or arm_ty == self.sema.ty_void as i32:
                    continue
                if match_ty == 0 or match_ty == self.sema.ty_void as i32:
                    match_ty = arm_ty
                    continue
                if self.sema.types_compatible(match_ty, arm_ty) != 0:
                    match_ty = self.sema.preferred_compatible_type(match_ty as TypeId, arm_ty as TypeId) as i32
            if match_ty != 0 and match_ty != self.sema.ty_void as i32:
                return match_ty
    if kind == NodeKind.NK_IF_EXPR:
        // Infer if-expression type from then branch
        let then_expr = self.ast.get_data1(node)
        if then_expr != 0:
            return self.expr_type(then_expr)
    if kind == NodeKind.NK_BLOCK:
        // Infer block type from tail expression
        let tail = self.ast.get_data2(node)
        if tail != 0:
            return self.expr_type(tail)
    if kind == NodeKind.NK_INDEX:
        let base_node = self.ast.get_data0(node)
        let base_ty = self.expr_type(base_node)
        let elem_ty = self.indexed_element_type(base_ty)
        if elem_ty != 0:
            return elem_ty
    if kind == NodeKind.NK_BINARY:
        let op = self.ast.get_data0(node)
        let lhs_ty = self.expr_type(self.ast.get_data1(node))
        let rhs_ty = self.expr_type(self.ast.get_data2(node))
        if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE or op == BinaryOp.OP_AND or op == BinaryOp.OP_OR:
            return self.sema.ty_bool as i32
        if lhs_ty != 0 and lhs_ty != self.sema.ty_void as i32:
            let lhs_resolved = self.sema.resolve_alias(lhs_ty) as i32
            let lhs_tk = self.sema.get_type_kind(lhs_resolved)
            if op == BinaryOp.OP_SUB and (lhs_tk == TypeKind.TY_PTR or lhs_tk == TypeKind.TY_REF):
                if rhs_ty != 0 and rhs_ty != self.sema.ty_void as i32:
                    let rhs_resolved = self.sema.resolve_alias(rhs_ty) as i32
                    let rhs_tk = self.sema.get_type_kind(rhs_resolved)
                    if rhs_tk == TypeKind.TY_PTR or rhs_tk == TypeKind.TY_REF:
                        return self.sema.ty_isize as i32
            if (op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB) and (lhs_tk == TypeKind.TY_PTR or lhs_tk == TypeKind.TY_REF):
                return lhs_ty
        if rhs_ty != 0 and rhs_ty != self.sema.ty_void as i32:
            let rhs_resolved = self.sema.resolve_alias(rhs_ty) as i32
            let rhs_tk = self.sema.get_type_kind(rhs_resolved)
            if op == BinaryOp.OP_ADD and (rhs_tk == TypeKind.TY_PTR or rhs_tk == TypeKind.TY_REF):
                return rhs_ty
        if lhs_ty != 0 and lhs_ty == rhs_ty:
            return lhs_ty
    if kind == NodeKind.NK_UNARY:
        let uop = self.ast.get_data0(node)
        if uop == UnaryOp.UOP_TRY:
            let inner_node = self.ast.get_data1(node)
            let inner_ty = self.expr_type(inner_node)
            let unwrapped = self.sema.try_unwrapped_type(inner_ty) as i32
            if unwrapped != 0:
                return unwrapped
            return inner_ty
        if uop == UnaryOp.UOP_DEREF:
            let inner_node = self.ast.get_data1(node)
            let inner_ty = self.expr_type(inner_node)
            if inner_ty != 0 and inner_ty != self.sema.ty_void as i32:
                let resolved = self.sema.resolve_alias(inner_ty) as i32
                let tk = self.sema.get_type_kind(resolved)
                if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                    return self.sema.get_type_d0(resolved)
    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        var vs_sym = self.ast.get_data0(node)
        if self.sema.comp_resolved.contains(node):
            vs_sym = self.sema.comp_resolved.get(node).unwrap()
        if self.sema.variant_lookup.contains(vs_sym):
            return self.sema.variant_type_ids.get(vs_sym).unwrap() as i32
    if kind == NodeKind.NK_RANGE:
        let range_start = self.ast.get_data0(node)
        let range_end = self.ast.get_data1(node)
        let range_inclusive = self.ast.get_data2(node)
        var range_elem = self.sema.ty_i32 as i32
        if range_start != 0:
            range_elem = self.expr_type(range_start)
        else if range_end != 0:
            range_elem = self.expr_type(range_end)
        let range_found = self.sema.find_range_type(range_elem, range_inclusive) as i32
        if range_found != 0:
            return range_found
        return self.sema.ty_void as i32
    self.sema.ty_void as i32

fn MirBuilder.place_local_type(self: MirBuilder, place_id: i32) -> i32:
    if place_id < 0 or place_id >= self.body.place_locals.len() as i32:
        return self.sema.ty_void as i32
    let local_id = self.body.place_locals.get(place_id as i64)
    if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
        return self.sema.ty_void as i32
    var current_ty = self.body.local_type_ids.get(local_id as i64) as i32
    let proj_start = self.body.place_proj_starts.get(place_id as i64)
    let proj_count = self.body.place_proj_counts.get(place_id as i64)
    var active_variant_idx = -1

    for pi in 0..proj_count:
        let proj_kind = self.body.proj_kinds.get((proj_start + pi) as i64)
        let proj_d0 = self.body.proj_d0.get((proj_start + pi) as i64)
        let resolved = self.sema.resolve_alias(current_ty) as i32
        let tk = self.sema.get_type_kind(resolved)

        if proj_kind == ProjKind.PK_DOWNCAST:
            if tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST:
                active_variant_idx = proj_d0
                continue
            return self.sema.ty_void as i32

        if proj_kind == ProjKind.PK_FIELD:
            var field_ty = 0
            if active_variant_idx >= 0:
                field_ty = self.enum_payload_type(current_ty, active_variant_idx, proj_d0)
            else if tk == TypeKind.TY_TUPLE:
                field_ty = self.tuple_elem_type(current_ty, proj_d0)
            else:
                field_ty = self.struct_field_type(current_ty, proj_d0)
            if field_ty == 0:
                return self.sema.ty_void as i32
            current_ty = field_ty
            active_variant_idx = -1
            continue

        if proj_kind == ProjKind.PK_INDEX:
            let elem_ty = self.indexed_element_type(current_ty)
            if elem_ty == 0:
                return self.sema.ty_void as i32
            current_ty = elem_ty
            active_variant_idx = -1
            continue

        if proj_kind == ProjKind.PK_DEREF:
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                current_ty = self.sema.get_type_d0(resolved)
                active_variant_idx = -1
                continue
            return self.sema.ty_void as i32

        return self.sema.ty_void as i32

    current_ty

fn MirBuilder.variant_index(self: MirBuilder, variant_sym: i32) -> i32:
    if variant_sym == 0:
        return 0
    if self.sema.variant_lookup.contains(variant_sym):
        return self.sema.variant_lookup.get(variant_sym).unwrap()
    0

fn MirBuilder.enum_variant_index_for_type(self: MirBuilder, enum_ty: i32, variant_sym: i32) -> i32:
    let index = self.sema.enum_variant_index_for_type(enum_ty, variant_sym)
    if index >= 0:
        return index
    self.variant_index(variant_sym)

fn MirBuilder.enum_variant_discriminant_for_type(self: MirBuilder, enum_ty: i32, variant_sym: i32) -> i32:
    let disc = self.sema.enum_variant_discriminant_for_type(enum_ty, variant_sym)
    if disc >= 0:
        return disc
    self.variant_index(variant_sym)

// Resolve variant sym from an AST node, checking sema's comprehension sidecar first.
fn MirBuilder.resolve_variant_sym(self: MirBuilder, node: i32) -> i32:
    let sym = self.ast.get_data0(node)
    if self.sema.comp_resolved.contains(node):
        return self.sema.comp_resolved.get(node).unwrap()
    sym

fn MirBuilder.resolve_comprehension_marker_variant(self: MirBuilder, variant_sym: i32, enum_ty: i32) -> i32:
    let text = self.pool.resolve(variant_sym)
    if text != "_Payload" and text != "_Empty":
        return variant_sym
    if enum_ty == 0:
        return variant_sym
    let success = text == "_Payload"
    let option_variant = if success: self.sema.syms.some else: self.sema.syms.none
    if self.sema.enum_has_variant(enum_ty, option_variant) != 0:
        return option_variant
    let result_variant = if success: self.sema.syms.ok else: self.sema.syms.err
    if self.sema.enum_has_variant(enum_ty, result_variant) != 0:
        return result_variant
    variant_sym

fn MirBuilder.success_variant_index(self: MirBuilder) -> i32:
    let some_sym = self.pool.intern("Some")
    if self.sema.variant_lookup.contains(some_sym):
        return self.variant_index(some_sym)
    let ok_sym = self.pool.intern("Ok")
    if self.sema.variant_lookup.contains(ok_sym):
        return self.variant_index(ok_sym)
    1

fn MirBuilder.materialize_operand(self: MirBuilder, operand_id: i32, type_id: i32, span: i32) -> i32:
    let temp = self.new_temp(type_id)
    let place = self.place_for_local(temp)
    self.assign_operand_to_place(place, operand_id, span)
    place

fn MirBuilder.new_temp(self: MirBuilder, type_id: i32) -> i32:
    self.next_temp = self.next_temp + 1
    self.body.new_temp(type_id)

fn MirBuilder.place_for_local(self: MirBuilder, local_id: i32) -> i32:
    self.body.new_place(local_id)

fn MirBuilder.const_operand(self: MirBuilder, kind: i32, d0: i32, type_id: i32) -> i32:
    let c = self.body.new_const(kind, d0, 0, 0, type_id)
    self.body.new_operand(OperandKind.OK_CONSTANT, c)

fn MirBuilder.int_const_operand(self: MirBuilder, value: i64, type_id: i32) -> i32:
    let c = self.body.new_const(ConstKind.CK_INT, ast_int_part0(value), ast_int_part1(value), ast_int_part2(value), type_id)
    self.body.new_operand(OperandKind.OK_CONSTANT, c)

fn MirBuilder.exact_int_const_operand(self: MirBuilder, node: i32, type_id: i32) -> i32:
    let c = self.body.new_const(ConstKind.CK_INT_EXACT, node, 0, 0, type_id)
    self.body.new_operand(OperandKind.OK_CONSTANT, c)

fn MirBuilder.unit_operand(self: MirBuilder) -> i32:
    self.const_operand(ConstKind.CK_UNIT, 0, self.sema.ty_void)

fn MirBuilder.try_eval_const(self: MirBuilder, node: i32) -> i64:
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_INT_LIT:
        let fast = self.ast.int_literal_fast_i64(node as NodeId)
        if fast.ok == 0:
            return -9223372036854775807
        return fast.value
    if kind == NodeKind.NK_COMPTIME:
        return self.try_eval_const(self.ast.get_data0(node))
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_NO_SUSPEND:
        return self.try_eval_const(self.ast.get_data0(node))
    if kind == NodeKind.NK_BOOL_LIT:
        return self.ast.get_data0(node) as i64
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        let inner = self.try_eval_const(self.ast.get_data1(node))
        if inner == -9223372036854775807: return -9223372036854775807
        if op == UnaryOp.UOP_NEGATE:
            let result_ty = self.expr_type(node)
            let arith = int_eval_unary_neg(inner, self.mir_const_int_width(result_ty), self.sema.overflow_mode)
            if arith.ok == 0 or arith.overflow != 0: return -9223372036854775807
            return arith.value
        if op == UnaryOp.UOP_BIT_NOT: return 0 - inner - 1
        if op == UnaryOp.UOP_NOT:
            if inner == 0: return 1
            return 0
        return -9223372036854775807
    if kind == NodeKind.NK_BINARY:
        let op = self.ast.get_data0(node)
        let lv = self.try_eval_const(self.ast.get_data1(node))
        if lv == -9223372036854775807: return -9223372036854775807
        let rv = self.try_eval_const(self.ast.get_data2(node))
        if rv == -9223372036854775807: return -9223372036854775807
        if op == BinaryOp.OP_ADD or op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_ADD_SAT or op == BinaryOp.OP_SUB or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_SUB_SAT or op == BinaryOp.OP_MUL or op == BinaryOp.OP_MUL_WRAP or op == BinaryOp.OP_MUL_SAT:
            let result_ty = self.expr_type(node)
            let arith = int_eval_binary_arithmetic(op, lv, rv, self.mir_const_int_width(result_ty), self.mir_const_int_is_unsigned(result_ty), self.sema.overflow_mode)
            if arith.ok == 0 or arith.overflow != 0: return -9223372036854775807
            return arith.value
        if op == BinaryOp.OP_DIV:
            if rv == 0: return -9223372036854775807
            let result_ty = self.expr_type(node)
            if int_div_overflows(lv, rv, self.mir_const_int_width(result_ty), self.mir_const_int_is_unsigned(result_ty)):
                if self.sema.overflow_mode == OVERFLOW_MODE_WRAP():
                    return int_signed_min(self.mir_const_int_width(result_ty))
                if self.sema.overflow_mode == OVERFLOW_MODE_SATURATE():
                    return int_signed_max(self.mir_const_int_width(result_ty))
                return -9223372036854775807
            return lv / rv
        if op == BinaryOp.OP_MOD:
            if rv == 0: return -9223372036854775807
            let result_ty = self.expr_type(node)
            if int_div_overflows(lv, rv, self.mir_const_int_width(result_ty), self.mir_const_int_is_unsigned(result_ty)):
                if self.sema.overflow_mode == OVERFLOW_MODE_WRAP() or self.sema.overflow_mode == OVERFLOW_MODE_SATURATE():
                    return 0
                return -9223372036854775807
            return lv % rv
        return -9223372036854775807
    if kind == NodeKind.NK_IDENT:
        // Cross-reference to another constant
        let ref_sym = self.ast.get_data0(node)
        return self.try_resolve_module_const_val(ref_sym)
    -9223372036854775807

fn MirBuilder.try_resolve_module_const_node(self: MirBuilder, sym: i32) -> i32:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        let flags = self.ast.get_data2(decl)
        let is_mut = flags % 2
        if is_mut != 0:
            continue
        var value_node = self.ast.get_data1(decl)
        if value_node == 0:
            continue
        if self.ast.kind(value_node) == NodeKind.NK_COMPTIME:
            value_node = self.ast.get_data0(value_node)
        if self.ast.kind(value_node) == NodeKind.NK_IDENT:
            let target = self.try_resolve_module_const_node(self.ast.get_data0(value_node))
            if target != 0:
                return target
        return value_node
    0

fn MirBuilder.try_resolve_module_const_val(self: MirBuilder, sym: i32) -> i64:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        let flags = self.ast.get_data2(decl)
        let is_mut = flags % 2
        if is_mut != 0:
            continue
        var value_node = self.ast.get_data1(decl)
        if value_node == 0:
            continue
        return self.try_eval_const(value_node)
    -9223372036854775807

fn MirBuilder.try_resolve_module_float_const(self: MirBuilder, sym: i32) -> i32:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        let flags = self.ast.get_data2(decl)
        let is_mut = flags % 2
        if is_mut != 0:
            continue
        var value_node = self.ast.get_data1(decl)
        if value_node == 0:
            continue
        if self.ast.kind(value_node) == NodeKind.NK_COMPTIME:
            value_node = self.ast.get_data0(value_node)
        if self.ast.kind(value_node) == NodeKind.NK_FLOAT_LIT:
            return self.ast.get_data0(value_node)
    -1

fn MirBuilder.try_resolve_module_const_type(self: MirBuilder, sym: i32) -> i32:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        if self.sema.typed_binding_types.contains(decl as i32):
            return self.sema.typed_binding_types.get(decl as i32).unwrap() as i32
        let flags = self.ast.get_data2(decl)
        let type_extra_packed = flags / 16
        if type_extra_packed > 0:
            let type_ann_node = self.ast.get_extra(type_extra_packed - 1)
            let resolved = self.sema.resolve_type_expr(type_ann_node) as i32
            if resolved != 0:
                return resolved
    0

fn MirBuilder.mark_unsupported(self: MirBuilder):
    if with_getenv_str("WITH_MIR_AUDIT").len() > 0:
        let node_kind = if self.cur_node != 0: self.ast.kind(self.cur_node) else: 0
        let fn_name = self.pool.resolve(self.body.fn_sym)
        var detail = ""
        if self.cur_node != 0:
            detail = f" span={self.ast.get_start(self.cur_node)}..{self.ast.get_end(self.cur_node)}"
            if node_kind == NodeKind.NK_IDENT:
                let sym = self.ast.get_data0(self.cur_node)
                let name = self.pool.resolve(sym)
                let sema_sym = self.sema.pool_lookup_symbol(name)
                detail = detail ++ " ident=" ++ name
                detail = detail ++ f" typed={if self.sema.typed_expr_types.contains(self.cur_node): self.sema.typed_expr_types.get(self.cur_node).unwrap() else: 0}"
                detail = detail ++ f" sig_ast={self.sema.get_sig(sym)} sig_sema={self.sema.get_sig(sema_sym)}"
                detail = detail ++ f" named_ast={if self.sema.named_types.contains(sym): self.sema.named_types.get(sym).unwrap() else: 0}"
                detail = detail ++ f" named_sema={if self.sema.named_types.contains(sema_sym): self.sema.named_types.get(sema_sym).unwrap() else: 0}"
                detail = detail ++ f" variant_ast={if self.sema.variant_lookup.contains(sym): self.sema.variant_lookup.get(sym).unwrap() else: -1}"
                detail = detail ++ f" variant_sema={if self.sema.variant_lookup.contains(sema_sym): self.sema.variant_lookup.get(sema_sym).unwrap() else: -1}"
            else if node_kind == NodeKind.NK_FIELD_ACCESS:
                let base = self.ast.get_data0(self.cur_node)
                let field_sym = self.ast.get_data1(self.cur_node)
                let field_name = self.pool.resolve(field_sym)
                let sema_field_sym = self.sema.pool_lookup_symbol(field_name)
                let base_ty = self.expr_type(base)
                let field_ty = self.expr_type(self.cur_node)
                detail = detail ++ " field=" ++ field_name
                detail = detail ++ f" base_kind={self.ast.kind(base)} base_ty={base_ty} field_ty={field_ty}"
                detail = detail ++ f" typed={if self.sema.typed_expr_types.contains(self.cur_node): self.sema.typed_expr_types.get(self.cur_node).unwrap() else: 0}"
                detail = detail ++ f" field_ast={self.struct_field_type(base_ty, field_sym)} field_sema={self.struct_field_type(base_ty, sema_field_sym)}"
        with_eprint(f"[mir-lower-fail] kind={node_kind} fn={fn_name}{detail}")
    var b = self.body
    b.lowering_failed = 1
    self.body = b

fn MirBuilder.lower_int_lit(self: MirBuilder, value: i64, type_id: i32) -> i32:
    let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TypeKind.TY_VOID: self.sema.ty_i32 else: type_id
    self.int_const_operand(value, ty)

fn MirBuilder.lower_int_lit_node(self: MirBuilder, node: i32, type_id: i32) -> i32:
    let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TypeKind.TY_VOID: self.sema.ty_i32 else: type_id
    let exact = self.ast.int_literal_exact_expr(node)
    if exact.ok != 0:
        let fast = exact_int_try_i64(exact_int_expr_magnitude(exact))
        if exact.negative != 0 or fast.ok == 0:
            return self.exact_int_const_operand(node, ty)
    let fast = self.ast.int_literal_fast_i64(node as NodeId)
    if fast.ok != 0:
        return self.int_const_operand(fast.value, ty)
    self.exact_int_const_operand(node, ty)

fn MirBuilder.lower_bool_lit(self: MirBuilder, value: i32) -> i32:
    self.const_operand(ConstKind.CK_BOOL, value, self.sema.ty_bool)

fn MirBuilder.lower_str_lit(self: MirBuilder, sym: i32) -> i32:
    self.const_operand(ConstKind.CK_STR, sym, self.sema.ty_str)

fn MirBuilder.lower_str_lit_as(self: MirBuilder, sym: i32, type_id: i32) -> i32:
    let ty = if type_id != 0: type_id else: self.sema.ty_str as i32
    self.const_operand(ConstKind.CK_STR, sym, ty)

fn MirBuilder.lower_c_str_lit(self: MirBuilder, sym: i32) -> i32:
    self.const_operand(ConstKind.CK_C_STR, sym, self.sema.ty_cstr_view)

fn MirBuilder.node_is_src_call(self: MirBuilder, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_CALL:
        return 0
    if self.ast.get_data2(node) != 0:
        return 0
    let callee = self.ast.get_data0(node)
    if callee == 0 or self.ast.kind(callee) != NodeKind.NK_IDENT:
        return 0
    let sym = self.ast.get_data0(callee)
    if sym == self.sema.syms.src:
        return 1
    let canonical_sym = self.sema.pool_lookup_symbol(self.pool.resolve(sym))
    if canonical_sym == self.sema.syms.src: 1 else: 0

fn mir_source_text_for_path(fallback_text: str, path: str) -> str:
    if path.len() > 0 and path != "<unknown>":
        let text = with_fs_read_file(path)
        if text.len() > 0:
            return text
    fallback_text

fn MirBuilder.source_location_operand(self: MirBuilder, node: i32) -> i32:
    let path = if self.sema.current_module_path.len() > 0: self.sema.current_module_path else: "<unknown>"
    let text = mir_source_text_for_path(self.sema.source_text, path)
    let span_start = self.ast.get_start(node)
    var line = 1
    var col = 1
    var i = 0
    while i < span_start and i < text.len() as i32:
        if text.byte_at(i as i64) == 10:
            line = line + 1
            col = 1
        else:
            col = col + 1
        i = i + 1
    self.lower_str_lit(self.pool.intern(f"{path}:{line}:{col}"))

fn MirBuilder.source_file_operand(self: MirBuilder, node: i32) -> i32:
    let _ = node
    let path = if self.sema.current_module_path.len() > 0: self.sema.current_module_path else: "<unknown>"
    self.lower_str_lit(self.pool.intern(path))

fn MirBuilder.source_line_operand(self: MirBuilder, node: i32) -> i32:
    let path = if self.sema.current_module_path.len() > 0: self.sema.current_module_path else: "<unknown>"
    let text = mir_source_text_for_path(self.sema.source_text, path)
    let span_start = self.ast.get_start(node)
    var line = 1
    var i = 0
    while i < span_start and i < text.len() as i32:
        if text.byte_at(i as i64) == 10:
            line = line + 1
        i = i + 1
    self.int_const_operand(line as i64, self.sema.ty_u32 as i32)

fn MirBuilder.source_fn_operand(self: MirBuilder, node: i32) -> i32:
    let _ = node
    self.lower_str_lit(self.pool.intern(self.pool.resolve(self.body.fn_sym)))

fn MirBuilder.lower_magic_ident(self: MirBuilder, kind: i32, node: i32) -> i32:
    if kind == SemaMagicIdentKind.FILE:
        return self.source_file_operand(node)
    if kind == SemaMagicIdentKind.LINE:
        return self.source_line_operand(node)
    if kind == SemaMagicIdentKind.FN:
        return self.source_fn_operand(node)
    self.unit_operand()

fn MirBuilder.magic_ident_kind(self: MirBuilder, node: i32) -> i32:
    var kind = self.sema.magic_ident_kind(node)
    if kind != SemaMagicIdentKind.NONE:
        return kind
    if node == 0 or self.ast.kind(node) != NodeKind.NK_IDENT:
        return SemaMagicIdentKind.NONE
    let sym = self.ast.get_data0(node)
    if sym == self.sema.syms.file_magic:
        return SemaMagicIdentKind.FILE
    if sym == self.sema.syms.line_magic:
        return SemaMagicIdentKind.LINE
    if sym == self.sema.syms.fn_magic:
        return SemaMagicIdentKind.FN
    SemaMagicIdentKind.NONE

fn MirBuilder.lower_default_call_arg(self: MirBuilder, default_node: i32, call_node: i32, sig_idx: i32, callable_fn_tid: i32, param_idx: i32) -> i32:
    if self.node_is_src_call(default_node) != 0:
        return self.source_location_operand(call_node)
    let magic_kind = self.magic_ident_kind(default_node)
    if magic_kind != 0:
        return self.lower_magic_ident(magic_kind, call_node)
    self.lower_call_arg(default_node, sig_idx, callable_fn_tid, param_idx)

fn MirBuilder.lower_regex_literal(self: MirBuilder, node: i32) -> i32:
    let regex_ty = self.sema.lookup_named_type_visible(self.sema.syms.regex)
    let inferred_ty = self.expr_type(node)
    let result_ty = if inferred_ty != 0 and self.sema.type_is_unit(inferred_ty) == 0: inferred_ty else: regex_ty
    let c = self.body.new_const(ConstKind.CK_REGEX_LIT, self.ast.get_data0(node), self.ast.get_data1(node), node, result_ty)
    self.body.new_operand(OperandKind.OK_CONSTANT, c)

fn MirBuilder.regex_captures_type(self: MirBuilder) -> i32:
    let sym = self.sema.pool_lookup_symbol("Captures")
    if sym != 0 and self.sema.named_types.contains(sym):
        return self.sema.named_types.get(sym).unwrap()
    self.sema.ty_void as i32

fn MirBuilder.regex_captures_option_type(self: MirBuilder) -> i32:
    let cap_ty = self.regex_captures_type()
    let opt_sym = self.sema.pool_lookup_symbol("Option")
    if opt_sym == 0 or cap_ty == 0:
        return self.sema.ty_void as i32
    let found = self.sema.find_generic_inst(opt_sym, cap_ty)
    if found != 0:
        return found
    let args: Vec[i32] = Vec.new()
    args.push(cap_ty)
    self.sema.ensure_generic_inst_type(opt_sym, args, 1) as i32

fn MirBuilder.regex_ref_operand(self: MirBuilder, regex_place: i32) -> i32:
    let regex_ty = self.sema.lookup_named_type_visible(self.sema.syms.regex)
    let regex_ref_ty = self.sema.ensure_exact_type(TypeKind.TY_REF, regex_ty, 0, 0) as i32
    let regex_ref_tmp = self.new_temp(regex_ref_ty)
    let regex_ref_place = self.place_for_local(regex_ref_tmp)
    let regex_ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, regex_place, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, regex_ref_place, regex_ref_rv, self.ast.get_start(self.cur_node))
    self.body.new_operand(OperandKind.OK_COPY, regex_ref_place)

fn MirBuilder.captures_ref_operand(self: MirBuilder, captures_place: i32) -> i32:
    let captures_ty = self.regex_captures_type()
    let captures_ref_ty = self.sema.ensure_exact_type(TypeKind.TY_REF, captures_ty, 0, 0) as i32
    let captures_ref_tmp = self.new_temp(captures_ref_ty)
    let captures_ref_place = self.place_for_local(captures_ref_tmp)
    let captures_ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, captures_place, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, captures_ref_place, captures_ref_rv, self.ast.get_start(self.cur_node))
    self.body.new_operand(OperandKind.OK_COPY, captures_ref_place)

fn MirBuilder.lower_regex_method_bool(self: MirBuilder, regex_place: i32, text_place: i32, method_name: str) -> i32:
    let method_sym = self.sema.pool_lookup_symbol(method_name)
    let fn_sym = self.sema.lookup_method_fn(self.sema.syms.regex, method_sym)
    let fn_op = self.lower_var(fn_sym, 0, 0)
    let args: Vec[i32] = Vec.new()
    args.push(self.regex_ref_operand(regex_place))
    args.push(self.body.new_operand(OperandKind.OK_COPY, text_place))
    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(self.sema.ty_bool)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_regex_is_match_places(self: MirBuilder, regex_place: i32, text_place: i32) -> i32:
    self.lower_regex_method_bool(regex_place, text_place, "is_match")

fn MirBuilder.lower_regex_captures_places(self: MirBuilder, regex_place: i32, text_place: i32) -> i32:
    let method_sym = self.sema.pool_lookup_symbol("captures_match_op")
    let fn_sym = self.sema.lookup_method_fn(self.sema.syms.regex, method_sym)
    let fn_op = self.lower_var(fn_sym, 0, 0)
    let args: Vec[i32] = Vec.new()
    args.push(self.regex_ref_operand(regex_place))
    args.push(self.body.new_operand(OperandKind.OK_COPY, text_place))
    let args_id = self.body.new_call_args(args)
    let result_ty = self.regex_captures_option_type()
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    result_place

fn MirBuilder.lower_option_is_some_place(self: MirBuilder, opt_place: i32, opt_ty: i32) -> i32:
    let fn_op = self.const_operand(ConstKind.CK_FN, self.sema.pool_lookup_symbol("is_some"), self.sema.ty_void)
    let args: Vec[i32] = Vec.new()
    args.push(self.body.new_operand(OperandKind.OK_COPY, opt_place))
    let args_id = self.body.new_call_args(args)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.OPT_IS_SOME)
    let result_local = self.new_temp(self.sema.ty_bool)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_option_unwrap_place(self: MirBuilder, opt_place: i32, opt_ty: i32, result_ty: i32) -> i32:
    let fn_op = self.const_operand(ConstKind.CK_FN, self.sema.pool_lookup_symbol("unwrap"), self.sema.ty_void)
    let args: Vec[i32] = Vec.new()
    args.push(self.body.new_operand(OperandKind.OK_COPY, opt_place))
    let args_id = self.body.new_call_args(args)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.OPT_UNWRAP)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    result_place

fn MirBuilder.lower_regex_match_expr(self: MirBuilder, node: i32) -> i32:
    let lhs = self.ast.get_data0(node)
    let rhs = self.ast.get_data1(node)
    let text_op = self.lower_expr(lhs)
    let text_place = self.materialize_operand(text_op, self.expr_type(lhs), self.ast.get_start(lhs))
    let regex_op = self.lower_expr(rhs)
    let regex_place = self.materialize_operand(regex_op, self.expr_type(rhs), self.ast.get_start(rhs))
    let captures_opt_place = self.lower_regex_captures_places(regex_place, text_place)
    self.lower_option_is_some_place(captures_opt_place, self.regex_captures_option_type())

fn MirBuilder.lower_captures_text_call(self: MirBuilder, captures_place: i32, index: i32, name_sym: i32) -> i32:
    let method_name = if name_sym != 0: "name_text" else: "text"
    let method_sym = self.sema.pool_lookup_symbol(method_name)
    let captures_sym = self.sema.pool_lookup_symbol("Captures")
    let fn_sym = self.sema.lookup_method_fn(captures_sym, method_sym)
    let fn_op = self.lower_var(fn_sym, 0, 0)
    let args: Vec[i32] = Vec.new()
    args.push(self.captures_ref_operand(captures_place))
    if name_sym != 0:
        args.push(self.lower_str_lit(name_sym))
    else:
        args.push(self.int_const_operand(index as i64, self.sema.ty_i32))
    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.bind_regex_capture_local(self: MirBuilder, sym: i32, value_op: i32, span: i32):
    if sym == 0:
        return
    let local_id = self.body.new_local(self.sema.ty_str as i32, 0, sym, 1)
    self.bind_local(sym, local_id)
    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, span)
    self.schedule_drop(local_id, DropKind.DK_VALUE)
    self.assign_operand_to_place(self.place_for_local(local_id), value_op, span)

fn MirBuilder.lower_regex_capture_bindings_from_captures(self: MirBuilder, regex_node: i32, captures_place: i32):
    if regex_node == 0:
        return
    let capture_count = if self.sema.regex_capture_counts.contains(regex_node): self.sema.regex_capture_counts.get(regex_node).unwrap() else: 0
    var i = 0
    while i <= capture_count:
        let sym = self.sema.pool_lookup_symbol("$" ++ i.to_string())
        if sym != 0:
            let value_op = self.lower_captures_text_call(captures_place, i, 0)
            self.bind_regex_capture_local(sym, value_op, self.ast.get_start(regex_node))
        i = i + 1
    let name_count = if self.sema.regex_capture_name_counts.contains(regex_node): self.sema.regex_capture_name_counts.get(regex_node).unwrap() else: 0
    let name_start = if self.sema.regex_capture_name_starts.contains(regex_node): self.sema.regex_capture_name_starts.get(regex_node).unwrap() else: 0
    var ni = 0
    while ni < name_count:
        let sym = self.sema.regex_capture_name_syms.get((name_start + ni) as i64)
        if sym != 0:
            let value_op = self.lower_captures_text_call(captures_place, 0, sym)
            self.bind_regex_capture_local(sym, value_op, self.ast.get_start(regex_node))
        ni = ni + 1

fn MirBuilder.lower_regex_capture_bindings_from_option(self: MirBuilder, regex_node: i32, captures_opt_place: i32):
    if regex_node == 0:
        return
    let captures_place = self.lower_option_unwrap_place(captures_opt_place, self.regex_captures_option_type(), self.regex_captures_type())
    self.lower_regex_capture_bindings_from_captures(regex_node, captures_place)

fn MirBuilder.remember_regex_pattern_captures(self: MirBuilder, pat_node: i32, captures_opt_place: i32) -> void:
    for i in 0..self.regex_capture_pat_nodes.len() as i32:
        if self.regex_capture_pat_nodes.get(i as i64) == pat_node:
            self.regex_capture_opt_places.set_i32(i as i64, captures_opt_place)
            return
    self.regex_capture_pat_nodes.push(pat_node)
    self.regex_capture_opt_places.push(captures_opt_place)

fn MirBuilder.lookup_regex_pattern_captures(self: MirBuilder, pat_node: i32) -> i32:
    for i in 0..self.regex_capture_pat_nodes.len() as i32:
        if self.regex_capture_pat_nodes.get(i as i64) == pat_node:
            return self.regex_capture_opt_places.get(i as i64)
    -1

fn MirBuilder.lower_fmt_to_str(self: MirBuilder, operand: i32, node: i32) -> i32:
    // Emit MirIntrinsic.FMT_TO_STR call to format a non-str value to str.
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_to_str"), self.sema.ty_str)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(operand)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.FMT_TO_STR)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fmt_debug_str(self: MirBuilder, operand: i32, node: i32) -> i32:
    // Emit MirIntrinsic.FMT_DEBUG_STR call to wrap a str value in quotes.
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_debug_str"), self.sema.ty_str)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(operand)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.FMT_DEBUG_STR)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fmt_debug(self: MirBuilder, operand: i32, sema_ty: i32, node: i32) -> i32:
    // Emit MirIntrinsic.FMT_DEBUG with value + sema type ID.
    // Codegen dispatches based on type: str→quoted, struct→fields, etc.
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_debug"), self.sema.ty_str)
    let type_const = self.const_operand(ConstKind.CK_INT, sema_ty, self.sema.ty_i32)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(operand)
    call_args.push(type_const)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.FMT_DEBUG)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fmt_with_spec(self: MirBuilder, operand: i32, flags: i32, width: i32, precision: i32, sema_ty: i32, node: i32) -> i32:
    // Emit MirIntrinsic.FMT_SPEC with value + spec parameters.
    // args: [value, flags, width, precision, sema_type_id]
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_spec"), self.sema.ty_str)
    let flags_const = self.const_operand(ConstKind.CK_INT, flags, self.sema.ty_i32)
    let width_const = self.const_operand(ConstKind.CK_INT, width, self.sema.ty_i32)
    let prec_const = self.const_operand(ConstKind.CK_INT, precision, self.sema.ty_i32)
    let type_const = self.const_operand(ConstKind.CK_INT, sema_ty, self.sema.ty_i32)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(operand)
    call_args.push(flags_const)
    call_args.push(width_const)
    call_args.push(prec_const)
    call_args.push(type_const)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.FMT_SPEC)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fstring(self: MirBuilder, node: i32) -> i32:
    // Lower f-string to FmtBuffer approach:
    //   buf = fmt_buf_new()
    //   for each segment: fmt_buf_write_*(buf, value, ...)
    //   result = fmt_buf_finish(buf)
    let seg_count = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)

    if seg_count == 0:
        return self.lower_str_lit(self.pool.intern(""))

    // Step 1: Create FmtBuffer via MirIntrinsic.FMT_BUF_NEW
    let buf_op = self.lower_fstring_buf_new(node)

    // Step 2: For each segment, emit a write call
    var pos = extra_start
    var i = 0
    while i < seg_count:
        let seg_kind = self.ast.get_extra(pos)
        if seg_kind == FStringSegmentKind.LITERAL:
            let sym = self.ast.get_extra(pos + 1)
            let str_op = self.lower_str_lit(sym)
            self.lower_fstring_buf_write_str(buf_op, str_op, node)
            pos = pos + 2
        else if seg_kind == FStringSegmentKind.EXPR:
            let expr_node = self.ast.get_extra(pos + 1)
            let spec_node = self.ast.get_extra(pos + 2)
            let expr_op = self.lower_expr(expr_node)
            let expr_ty = self.expr_type(expr_node)
            let resolved_ty = if expr_ty > 0: self.sema.resolve_alias(expr_ty) else: 0

            var handled = false
            if spec_node != 0:
                let spec_flags = self.ast.get_data0(spec_node)
                let spec_mode = spec_flags & 255
                let spec_width = self.ast.get_data1(spec_node)
                let spec_precision = self.ast.get_data2(spec_node)
                if spec_mode == 63:
                    // Debug mode: format to str then write
                    let debug_str = self.lower_fmt_debug(expr_op, resolved_ty, node)
                    self.lower_fstring_buf_write_str(buf_op, debug_str, node)
                    handled = true
                else if spec_mode != 0 or spec_width > 0 or spec_precision >= 0 or (spec_flags & 0x1C0000) != 0:
                    // Spec formatting: emit FMT_BUF_WRITE_FMT intrinsic
                    self.lower_fstring_buf_write_fmt(buf_op, expr_op, spec_flags, spec_width, spec_precision, resolved_ty, node)
                    handled = true
            if not handled:
                if resolved_ty == self.sema.ty_str:
                    // String: write directly
                    self.lower_fstring_buf_write_str(buf_op, expr_op, node)
                else:
                    // Non-str: format to str then write
                    let formatted = self.lower_fmt_to_str(expr_op, node)
                    self.lower_fstring_buf_write_str(buf_op, formatted, node)
            pos = pos + 3
        else:
            pos = pos + 1
            i = i + 1
            continue
        i = i + 1

    // Step 3: Finalize buffer to str
    self.lower_fstring_buf_finish(buf_op, node)

fn MirBuilder.lower_fstring_buf_new(self: MirBuilder, node: i32) -> i32:
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_buf_new"), self.sema.ty_i32)
    let call_args: Vec[i32] = Vec.new()
    let args_id = self.body.new_call_args(call_args)
    // Result is a pointer (use i32 as placeholder sema type, codegen knows it's ptr)
    let result_local = self.new_temp(self.sema.ty_i32)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.FMT_BUF_NEW)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fstring_buf_write_str(self: MirBuilder, buf_op: i32, str_op: i32, node: i32):
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_buf_write_str"), self.sema.ty_void)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(buf_op)
    call_args.push(str_op)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_void)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.FMT_BUF_WRITE_STR)

fn MirBuilder.lower_fstring_buf_write_fmt(self: MirBuilder, buf_op: i32, val_op: i32, flags: i32, width: i32, precision: i32, sema_ty: i32, node: i32):
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_buf_write_fmt"), self.sema.ty_void)
    let flags_const = self.const_operand(ConstKind.CK_INT, flags, self.sema.ty_i32)
    let width_const = self.const_operand(ConstKind.CK_INT, width, self.sema.ty_i32)
    let prec_const = self.const_operand(ConstKind.CK_INT, precision, self.sema.ty_i32)
    let type_const = self.const_operand(ConstKind.CK_INT, sema_ty, self.sema.ty_i32)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(buf_op)
    call_args.push(val_op)
    call_args.push(flags_const)
    call_args.push(width_const)
    call_args.push(prec_const)
    call_args.push(type_const)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_void)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.FMT_BUF_WRITE_FMT)

fn MirBuilder.lower_fstring_buf_finish(self: MirBuilder, buf_op: i32, node: i32) -> i32:
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_buf_finish"), self.sema.ty_str)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(buf_op)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.FMT_BUF_FINISH)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_float_lit(self: MirBuilder, sym: i32, type_id: i32) -> i32:
    let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TypeKind.TY_VOID: self.sema.ty_f64 else: type_id
    self.const_operand(ConstKind.CK_FLOAT, sym, ty)

fn MirBuilder.lower_unit(self: MirBuilder) -> i32:
    self.unit_operand()

fn MirBuilder.is_bare_none(self: MirBuilder, node: i32) -> bool:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_IDENT:
        return false
    self.pool.resolve(self.ast.get_data0(node)) == "None"

fn MirBuilder.ensure_global_local(self: MirBuilder, sym: i32) -> i32:
    // Check if we already created a proxy local for this global
    let existing = self.lookup_local(sym)
    if existing >= 0:
        return existing
    // Scan module declarations for a mutable let (var) or extern var
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        let dk = self.ast.kind(decl)
        if dk == NodeKind.NK_EXTERN_VAR:
            if self.ast.get_data0(decl) != sym:
                continue
            let ev_flags = self.ast.get_data2(decl)
            let ev_is_mut = ev_flags % 2
            let ev_type_node = self.ast.get_data1(decl)
            var ev_ty = self.sema.resolve_type_expr(ev_type_node)
            if ev_ty <= 0:
                ev_ty = self.sema.ty_i32
            let local_id = self.body.new_local(ev_ty, ev_is_mut, sym, 1)
            self.bind_local(sym, local_id)
            return local_id
        if dk != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        let flags = self.ast.get_data2(decl)
        let is_mut = flags % 2
        // Prefer an explicit type annotation. Otherwise infer from the
        // unwrapped initializer expression instead of the raw comptime wrapper.
        var gty = 0
        let type_extra_packed = flags / 16
        if type_extra_packed > 0:
            let type_node = self.ast.get_extra(type_extra_packed - 1)
            let annotated = self.sema.resolve_type_expr(type_node) as i32
            if annotated > 0:
                gty = annotated
        let val_node = self.ast.get_data1(decl)
        var typed_value = val_node
        while typed_value != 0:
            let typed_kind = self.ast.kind(typed_value)
            if typed_kind != NodeKind.NK_COMPTIME and typed_kind != NodeKind.NK_GROUPED:
                break
            typed_value = self.ast.get_data0(typed_value)
        if gty == 0 and typed_value != 0:
            let inferred = self.expr_type(typed_value)
            if inferred != 0:
                gty = inferred
        if gty == 0:
            gty = self.sema.ty_i32 as i32
        let local_id = self.body.new_local(gty, is_mut, sym, 1)
        self.bind_local(sym, local_id)
        return local_id
    -1

fn MirBuilder.lower_var(self: MirBuilder, sym: i32, type_id: i32, node_id: i32) -> i32:
    let hinted_ty = if self.expected_type != 0: self.expected_type else: type_id
    if self.pool.resolve(sym) == "None" and hinted_ty != 0:
        let hinted_resolved = self.sema.resolve_alias(hinted_ty)
        let hinted_tk = self.sema.get_type_kind(hinted_resolved)
        if hinted_tk == TypeKind.TY_PTR or hinted_tk == TypeKind.TY_REF or hinted_tk == TypeKind.TY_EXTERN_FN:
            return self.const_operand(ConstKind.CK_INT, 0, self.sema.ty_i32)

    let local = self.lookup_local(sym)
    if local >= 0:
        let place = self.body.new_place(local)
        if self.sema.is_copy(type_id) != 0:
            if self.local_type_is_str(local) != 0:
                self.mark_string_local_copied(local)
            return self.body.new_operand(OperandKind.OK_COPY, place)
        return self.body.new_operand(OperandKind.OK_MOVE, place)
    let alias_place = self.lookup_alias_place(sym)
    if alias_place >= 0:
        return self.body.new_operand(OperandKind.OK_COPY, alias_place)

    let sig_idx = self.sema.get_sig(sym)
    if sig_idx >= 0:
        let fn_ty = if type_id != 0: type_id else: self.sema.sig_type_ids.get(sig_idx as i64)
        return self.const_operand(ConstKind.CK_FN, sym, fn_ty)

    // Generic function reference (monomorphized at codegen time)
    if self.sema.generic_fn_nodes.contains(sym):
        return self.const_operand(ConstKind.CK_FN, sym, type_id)

    let const_node = self.try_resolve_module_const_node(sym)
    if const_node != 0:
        let inferred_ty = self.try_resolve_module_const_type(sym)
        let ty = if inferred_ty != 0:
            inferred_ty
        else:
            if type_id != 0: type_id else: self.sema.ty_i32 as i32
        let exact = self.ast.int_literal_exact_expr(const_node)
        if exact.ok != 0:
            let fast = exact_int_try_i64(exact_int_expr_magnitude(exact))
            if exact.negative != 0 or fast.ok == 0:
                return self.exact_int_const_operand(const_node, ty)

    // Try module-level constant (const X = 42)
    let const_val = self.try_resolve_module_const_val(sym)
    if const_val != -9223372036854775807:
        let inferred_ty = self.try_resolve_module_const_type(sym)
        let ty = if inferred_ty != 0:
            inferred_ty
        else:
            if const_val < -2147483648 or const_val > 2147483647: self.sema.ty_i64 else: self.sema.ty_i32
        return self.int_const_operand(const_val, ty)

    // Try module-level float constant (let PI: f64 = 3.14)
    let float_str_idx = self.try_resolve_module_float_const(sym)
    if float_str_idx >= 0:
        let inferred_ty = self.try_resolve_module_const_type(sym)
        let ty = if inferred_ty != 0: inferred_ty else: self.sema.ty_f64
        return self.const_operand(ConstKind.CK_FLOAT, float_str_idx, ty)

    // Check for enum variant without payload (None, etc.)
    if self.sema.variant_lookup.contains(sym):
        let vl_sym = if node_id != 0 and self.sema.comp_resolved.contains(node_id): self.sema.comp_resolved.get(node_id).unwrap() else: sym
        let vl_decl_ty = if self.sema.variant_type_ids.contains(vl_sym): self.sema.variant_type_ids.get(vl_sym).unwrap() else: self.sema.variant_type_ids.get(sym).unwrap()
        var vl_result_ty = if self.expected_type != 0: self.expected_type else: type_id
        if vl_result_ty == 0:
            vl_result_ty = vl_decl_ty
        var vl_variant_idx = self.enum_variant_discriminant_for_type(vl_result_ty, vl_sym)
        if vl_variant_idx < 0:
            vl_variant_idx = self.enum_variant_discriminant_for_type(vl_decl_ty, vl_sym)
        if vl_variant_idx < 0:
            vl_variant_idx = self.sema.variant_lookup.get(vl_sym).unwrap()
        // Match the qualified and shorthand variant lowering paths:
        // payloadless discriminant enums materialize as repr-backed int constants.
        let vl_resolved = self.sema.resolve_alias(vl_decl_ty)
        let vl_is_disc_enum = self.sema.disc_repr_types.contains(vl_resolved as i32)
        if vl_is_disc_enum and not self.sema.disc_has_payload.contains(vl_resolved as i32):
            var vl_disc_val = vl_variant_idx
            if self.sema.disc_values.contains(vl_sym):
                vl_disc_val = self.sema.disc_values.get(vl_sym).unwrap()
            else:
                let vl_bare_sym = self.sema.unqualified_enum_variant_sym(vl_sym)
                if self.sema.disc_values.contains(vl_bare_sym):
                    vl_disc_val = self.sema.disc_values.get(vl_bare_sym).unwrap()
            return self.int_const_operand(vl_disc_val as i64, vl_result_ty)
        let vl_fields: Vec[i32] = Vec.new()
        let vl_names: Vec[i32] = Vec.new()
        let vl_fid = self.body.new_agg_fields(vl_fields, vl_names)
        let vl_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, vl_fid, vl_variant_idx)
        let vl_tmp = self.new_temp(vl_result_ty)
        let vl_place = self.place_for_local(vl_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, vl_place, vl_rv, 0)
        return self.body.new_operand(OperandKind.OK_COPY, vl_place)

    // Try module-level mutable variable (var X = ...)
    let gv_local = self.ensure_global_local(sym)
    if gv_local >= 0:
        let gv_place = self.body.new_place(gv_local)
        return self.body.new_operand(OperandKind.OK_COPY, gv_place)

    if with_getenv_str("WITH_MIR_AUDIT").len() > 0:
        let var_name = self.pool.resolve(sym)
        let fn_name = self.pool.resolve(self.body.fn_sym)
        with_eprint("[mir-var-miss] sym=" ++ var_name ++ " fn=" ++ fn_name)
    self.mark_unsupported()
    self.unit_operand()

fn MirBuilder.assign_operand_to_place(self: MirBuilder, place: i32, operand_id: i32, span: i32):
    self.update_string_local_alias_after_assignment(place, operand_id)
    let rval = self.body.new_rvalue(RvalueKind.RK_USE, operand_id, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rval, span)

fn MirBuilder.direct_place_local(self: MirBuilder, place: i32) -> i32:
    if place < 0 or place >= self.body.place_locals.len() as i32:
        return -1
    if self.body.place_proj_counts.get(place as i64) != 0:
        return -1
    self.body.place_locals.get(place as i64)

fn MirBuilder.local_type_is_str(self: MirBuilder, local_id: i32) -> i32:
    if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
        return 0
    let tid = self.body.local_type_ids.get(local_id as i64)
    self.type_id_is_str(tid)

fn MirBuilder.type_id_is_str(self: MirBuilder, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.sema.resolve_alias(tid as TypeId)
    if self.sema.get_type_kind(resolved) == TypeKind.TY_STR: 1 else: 0

fn MirBuilder.string_alias_index(self: MirBuilder, local_id: i32) -> i32:
    for i in 0..self.string_alias_local_ids.len() as i32:
        if self.string_alias_local_ids.get(i as i64) == local_id:
            return i
    -1

fn MirBuilder.set_string_local_flags(self: MirBuilder, local_id: i32, flags: i32):
    if self.local_type_is_str(local_id) == 0:
        return
    let idx = self.string_alias_index(local_id)
    if idx >= 0:
        self.string_alias_flags.set_i32(idx as i64, flags)
        return
    self.string_alias_local_ids.push(local_id)
    self.string_alias_flags.push(flags)

fn MirBuilder.string_local_flags(self: MirBuilder, local_id: i32) -> i32:
    if self.local_type_is_str(local_id) == 0:
        return 1
    let idx = self.string_alias_index(local_id)
    if idx < 0:
        return 0
    self.string_alias_flags.get(idx as i64)

fn MirBuilder.set_string_local_may_alias(self: MirBuilder, local_id: i32, flag: i32):
    let old = self.string_local_flags(local_id)
    let owned = old & 2
    self.set_string_local_flags(local_id, owned | (if flag != 0: 1 else: 0))

fn MirBuilder.string_local_may_alias(self: MirBuilder, local_id: i32) -> i32:
    self.string_local_flags(local_id) & 1

fn MirBuilder.string_local_owned(self: MirBuilder, local_id: i32) -> i32:
    if (self.string_local_flags(local_id) & 2) != 0: 1 else: 0

fn MirBuilder.mark_string_local_copied(self: MirBuilder, local_id: i32):
    self.set_string_local_may_alias(local_id, 1)

fn MirBuilder.forget_string_flow_facts(self: MirBuilder):
    for i in 0..self.string_alias_flags.len() as i32:
        self.string_alias_flags.set_i32(i as i64, 1)

fn MirBuilder.operand_string_source_local(self: MirBuilder, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= self.body.operand_kinds.len() as i32:
        return -1
    if self.body.operand_kinds.get(operand_id as i64) != OperandKind.OK_COPY:
        return -1
    let place = self.body.operand_d0.get(operand_id as i64)
    let local = self.direct_place_local(place)
    if local < 0 or self.local_type_is_str(local) == 0:
        return -1
    local

fn MirBuilder.update_string_local_alias_after_assignment(self: MirBuilder, dest_place: i32, operand_id: i32):
    let dest_local = self.direct_place_local(dest_place)
    if dest_local < 0 or self.local_type_is_str(dest_local) == 0:
        return
    let source_local = self.operand_string_source_local(operand_id)
    if source_local >= 0:
        let source_is_named = if source_local < self.body.local_names.len() as i32 and self.body.local_names.get(source_local as i64) != 0: 1 else: 0
        let source_may_alias = if source_is_named != 0: 1 else: self.string_local_may_alias(source_local)
        self.set_string_local_flags(dest_local, source_may_alias | (if self.string_local_owned(source_local) != 0: 2 else: 0))
        return
    self.set_string_local_flags(dest_local, 0)

fn MirBuilder.is_string_concat_node(self: MirBuilder, node: i32) -> bool:
    if node == 0:
        return false
    if self.ast.kind(node) != NodeKind.NK_BINARY:
        return false
    if self.ast.get_data0(node) != BinaryOp.OP_CONCAT:
        return false
    if self.sema.operator_method_calls.contains(node):
        return false
    let ty = self.expr_type(node)
    if ty == 0:
        return false
    self.sema.resolve_alias(ty) == self.sema.ty_str

fn MirBuilder.collect_left_string_concat_parts(self: MirBuilder, node: i32) -> Vec[i32]:
    let rev: Vec[i32] = Vec.new()
    var cur = node
    while self.is_string_concat_node(cur):
        rev.push(self.ast.get_data2(cur))
        cur = self.ast.get_data1(cur)
    rev.push(cur)

    let out: Vec[i32] = Vec.new()
    var i = rev.len() as i32 - 1
    while i >= 0:
        out.push(rev.get(i as i64))
        i = i - 1
    out

fn MirBuilder.lower_str_concat_chain(self: MirBuilder, node: i32, parts: Vec[i32]) -> i32:
    let saved_expected = self.expected_type
    self.expected_type = self.sema.ty_str as i32
    let operands: Vec[i32] = Vec.new()
    for i in 0..parts.len() as i32:
        operands.push(self.lower_expr(parts.get(i as i64)))
    self.expected_type = saved_expected

    let args_id = self.body.new_call_args(operands)
    let rv = self.body.new_rvalue(RvalueKind.RK_STR_CONCAT_N, args_id, operands.len() as i32, 0)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    self.set_string_local_flags(temp, 2)
    if self.sema.is_copy(ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, place)
    self.body.new_operand(OperandKind.OK_MOVE, place)

fn MirBuilder.same_ident_symbol(self: MirBuilder, lhs: i32, rhs: i32) -> i32:
    if lhs == 0 or rhs == 0:
        return 0
    if self.ast.kind(lhs) != NodeKind.NK_IDENT or self.ast.kind(rhs) != NodeKind.NK_IDENT:
        return 0
    if self.ast.get_data0(lhs) == self.ast.get_data0(rhs): 1 else: 0

fn MirBuilder.try_lower_string_self_concat_assign(self: MirBuilder, place_expr: i32, rhs_expr: i32) -> i32:
    if place_expr == 0 or rhs_expr == 0:
        return -1
    let dest_ty = self.expr_type(place_expr)
    if dest_ty == 0 or self.sema.resolve_alias(dest_ty as TypeId) != self.sema.ty_str:
        return -1
    if not self.is_string_concat_node(rhs_expr):
        return -1
    let parts = self.collect_left_string_concat_parts(rhs_expr)
    if parts.len() as i32 < 2:
        return -1
    if self.same_ident_symbol(place_expr, parts.get(0)) == 0:
        return -1

    let dest_place = self.lower_expr_place(place_expr)
    let dest_local = self.direct_place_local(dest_place)
    if dest_local < 0 or self.string_local_may_alias(dest_local) != 0:
        return -1

    let saved_expected = self.expected_type
    self.expected_type = self.sema.ty_str as i32
    let operands: Vec[i32] = Vec.new()
    operands.push(self.body.new_operand(OperandKind.OK_MOVE, dest_place))
    for i in 1..parts.len() as i32:
        operands.push(self.lower_expr(parts.get(i as i64)))
    self.expected_type = saved_expected

    let args_id = self.body.new_call_args(operands)
    let rv = self.body.new_rvalue(RvalueKind.RK_STR_CONCAT_N, args_id, operands.len() as i32, 1)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, dest_place, rv, self.ast.get_start(place_expr))
    self.set_string_local_flags(dest_local, 2)
    dest_place

fn MirBuilder.lower_bin_op(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
    // Short-circuit evaluation for logical and/or
    if op == 11 or op == 12:
        return self.lower_short_circuit(op, lhs_expr, rhs_expr, node)
    if op == BinaryOp.OP_IN or op == BinaryOp.OP_NOT_IN:
        return self.lower_membership(op, lhs_expr, rhs_expr, node)
    if self.sema.operator_method_calls.contains(node):
        let method_sym = self.sema.operator_method_calls.get(node).unwrap()
        let reversed = if self.sema.operator_method_reversed.contains(node): self.sema.operator_method_reversed.get(node).unwrap() else: 0
        if reversed != 0:
            return self.lower_method_bin_op(rhs_expr, lhs_expr, method_sym, node)
        return self.lower_method_bin_op(lhs_expr, rhs_expr, method_sym, node)
    // Check for operator overloading: if LHS is a struct with an operator method, lower as call
    let lhs_ty = self.expr_type(lhs_expr)
    let rhs_ty = self.expr_type(rhs_expr)
    let lhs_resolved = if lhs_ty != 0: self.sema.resolve_alias(lhs_ty) else: 0
    let rhs_resolved = if rhs_ty != 0: self.sema.resolve_alias(rhs_ty) else: 0
    let lhs_tk = if lhs_resolved != 0: self.sema.get_type_kind(lhs_resolved) else: 0
    let rhs_tk = if rhs_resolved != 0: self.sema.get_type_kind(rhs_resolved) else: 0
    if lhs_ty != 0:
        if lhs_tk == TypeKind.TY_STRUCT:
            let method_name = mir_op_method_name(op)
            if method_name.len() > 0:
                let type_name_sym = self.sema.get_type_d0(lhs_resolved)
                if type_name_sym != 0:
                    let method_sym = self.sema.pool_lookup_symbol(self.sema.pool_resolve(type_name_sym) ++ "." ++ method_name)
                    let sig = self.sema.get_sig(method_sym)
                    if sig >= 0:
                        return self.lower_method_bin_op(lhs_expr, rhs_expr, method_sym, node)
    // Reversed-operand dispatch: try RHS type
    if rhs_ty != 0:
        if rhs_tk == TypeKind.TY_STRUCT:
            let rhs_method_name = mir_op_method_name(op)
            if rhs_method_name.len() > 0:
                let rhs_type_name_sym = self.sema.get_type_d0(rhs_resolved)
                if rhs_type_name_sym != 0:
                    let rhs_method_sym = self.sema.pool_lookup_symbol(self.sema.pool_resolve(rhs_type_name_sym) ++ "." ++ rhs_method_name)
                    let rhs_sig = self.sema.get_sig(rhs_method_sym)
                    if rhs_sig >= 0:
                        return self.lower_method_bin_op(rhs_expr, lhs_expr, rhs_method_sym, node)
    if op == BinaryOp.OP_CONCAT and self.is_string_concat_node(node):
        let parts = self.collect_left_string_concat_parts(node)
        if parts.len() as i32 > 2:
            return self.lower_str_concat_chain(node, parts)
    let saved_expected = self.expected_type
    if self.is_bare_none(lhs_expr) and (rhs_tk == TypeKind.TY_PTR or rhs_tk == TypeKind.TY_REF):
        self.expected_type = rhs_ty
    else:
        self.expected_type = saved_expected
    let lhs = self.lower_expr(lhs_expr)
    if self.is_bare_none(rhs_expr) and (lhs_tk == TypeKind.TY_PTR or lhs_tk == TypeKind.TY_REF):
        self.expected_type = lhs_ty
    else:
        self.expected_type = saved_expected
    let rhs = self.lower_expr(rhs_expr)
    self.expected_type = saved_expected
    let rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, op, lhs, rhs)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    if op == BinaryOp.OP_CONCAT and self.type_id_is_str(ty) != 0:
        self.set_string_local_flags(temp, 2)
    if self.sema.is_copy(ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, place)
    self.body.new_operand(OperandKind.OK_MOVE, place)

fn MirBuilder.lower_rvalue_to_temp(self: MirBuilder, rv: i32, type_id: i32, span: i32) -> i32:
    let temp = self.new_temp(type_id)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, span)
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_bin_op_operand(self: MirBuilder, op: i32, lhs: i32, rhs: i32, type_id: i32, span: i32) -> i32:
    let rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, op, lhs, rhs)
    let temp = self.new_temp(type_id)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, span)
    if op == BinaryOp.OP_CONCAT and self.type_id_is_str(type_id) != 0:
        self.set_string_local_flags(temp, 2)
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_not_operand(self: MirBuilder, operand: i32, span: i32) -> i32:
    let rv = self.body.new_rvalue(RvalueKind.RK_UN_OP, UnaryOp.UOP_NOT, operand, 0)
    self.lower_rvalue_to_temp(rv, self.sema.ty_bool as i32, span)

fn MirBuilder.lower_range_membership_from_parts(self: MirBuilder, op: i32, lhs_place: i32, start_op: i32, end_op: i32, inclusive: i32, span: i32) -> i32:
    let lhs_for_start = self.body.new_operand(OperandKind.OK_COPY, lhs_place)
    let ge = self.lower_bin_op_operand(BinaryOp.OP_GTE, lhs_for_start, start_op, self.sema.ty_bool as i32, span)
    let lhs_for_end = self.body.new_operand(OperandKind.OK_COPY, lhs_place)
    let hi_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
    let le = self.lower_bin_op_operand(hi_op, lhs_for_end, end_op, self.sema.ty_bool as i32, span)
    let both = self.lower_bin_op_operand(BinaryOp.OP_AND, ge, le, self.sema.ty_bool as i32, span)
    if op == BinaryOp.OP_NOT_IN:
        return self.lower_not_operand(both, span)
    both

fn MirBuilder.lower_range_literal_membership(self: MirBuilder, op: i32, lhs_expr: i32, range_expr: i32, node: i32) -> i32:
    let lhs_ty_raw = self.expr_type(lhs_expr)
    var lhs_ty = lhs_ty_raw
    let start_node = self.ast.get_data0(range_expr)
    let end_node = self.ast.get_data1(range_expr)
    let inclusive = self.ast.get_data2(range_expr)
    if end_node == 0:
        with_eprint("error: range membership requires an upper bound")
        self.mark_unsupported()
        return self.int_const_operand(0, self.sema.ty_bool as i32)
    var elem_ty = lhs_ty
    if elem_ty == 0 and start_node != 0:
        elem_ty = self.expr_type(start_node)
    if elem_ty == 0:
        elem_ty = self.expr_type(end_node)
    if lhs_ty == 0:
        lhs_ty = elem_ty
    let lhs_op = self.lower_expr(lhs_expr)
    let lhs_place = self.materialize_operand(lhs_op, lhs_ty, self.ast.get_start(lhs_expr))
    let start_op = if start_node != 0: self.lower_expr(start_node) else: self.int_const_operand(0, elem_ty)
    let end_op = self.lower_expr(end_node)
    self.lower_range_membership_from_parts(op, lhs_place, start_op, end_op, inclusive, self.ast.get_start(node))

fn MirBuilder.lower_range_value_membership(self: MirBuilder, op: i32, lhs_expr: i32, range_expr: i32, range_ty: i32, node: i32) -> i32:
    let elem_ty = self.sema.get_type_d0(range_ty)
    var lhs_ty = self.expr_type(lhs_expr)
    if lhs_ty == 0:
        lhs_ty = elem_ty
    let lhs_op = self.lower_expr(lhs_expr)
    let lhs_place = self.materialize_operand(lhs_op, lhs_ty, self.ast.get_start(lhs_expr))
    let range_op = self.lower_expr(range_expr)
    let range_place = self.materialize_operand(range_op, range_ty, self.ast.get_start(range_expr))
    let start_place = self.body.new_field_place(range_place, 0, elem_ty)
    let end_place = self.body.new_field_place(range_place, 1, elem_ty)
    let start_op = self.body.new_operand(OperandKind.OK_COPY, start_place)
    let end_op = self.body.new_operand(OperandKind.OK_COPY, end_place)
    let inclusive = self.sema.get_type_d1(range_ty)
    self.lower_range_membership_from_parts(op, lhs_place, start_op, end_op, inclusive, self.ast.get_start(node))

// `x in [a, b, c]` — §9.9 optimizes array-literal membership to a chain of
// zero-allocation equality comparisons (`x == a or x == b or x == c`).
fn MirBuilder.lower_array_literal_membership(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
    let span = self.ast.get_start(node)
    let extra_start = self.ast.get_data0(rhs_expr)
    let elem_count = self.ast.get_data1(rhs_expr)
    var lhs_ty = self.expr_type(lhs_expr)
    if lhs_ty == 0 and elem_count > 0:
        lhs_ty = self.expr_type(self.ast.get_extra(extra_start))
    let lhs_op = self.lower_expr(lhs_expr)
    let lhs_place = self.materialize_operand(lhs_op, lhs_ty, self.ast.get_start(lhs_expr))
    var acc = 0
    var has_acc = 0
    for i in 0..elem_count:
        let elem_node = self.ast.get_extra(extra_start + i)
        let lhs_copy = self.body.new_operand(OperandKind.OK_COPY, lhs_place)
        let elem_op = self.lower_expr(elem_node)
        let cmp = self.lower_bin_op_operand(BinaryOp.OP_EQ, lhs_copy, elem_op, self.sema.ty_bool as i32, span)
        if has_acc == 0:
            acc = cmp
            has_acc = 1
        else:
            acc = self.lower_bin_op_operand(BinaryOp.OP_OR, acc, cmp, self.sema.ty_bool as i32, span)
    if has_acc == 0:
        acc = self.int_const_operand(0, self.sema.ty_bool as i32)
    if op == BinaryOp.OP_NOT_IN:
        return self.lower_not_operand(acc, span)
    acc

// `x in arr` where `arr` is a fixed-size array value. The array length is known,
// so lower to the same zero-allocation equality chain as array literals.
fn MirBuilder.lower_array_value_membership(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, array_ty: i32, node: i32) -> i32:
    let span = self.ast.get_start(node)
    let elem_ty = self.sema.get_type_d0(array_ty)
    let elem_count = self.sema.get_type_d1(array_ty)
    var lhs_ty = self.expr_type(lhs_expr)
    if lhs_ty == 0:
        lhs_ty = elem_ty
    let lhs_op = self.lower_expr(lhs_expr)
    let lhs_place = self.materialize_operand(lhs_op, lhs_ty, self.ast.get_start(lhs_expr))
    let rhs_op = self.lower_expr(rhs_expr)
    let rhs_place = self.materialize_operand(rhs_op, array_ty, self.ast.get_start(rhs_expr))
    var acc = 0
    var has_acc = 0
    for i in 0..elem_count:
        let lhs_copy = self.body.new_operand(OperandKind.OK_COPY, lhs_place)
        let elem_place = self.body.new_field_place(rhs_place, i, elem_ty)
        let elem_op = self.body.new_operand(OperandKind.OK_COPY, elem_place)
        let cmp = self.lower_bin_op_operand(BinaryOp.OP_EQ, lhs_copy, elem_op, self.sema.ty_bool as i32, span)
        if has_acc == 0:
            acc = cmp
            has_acc = 1
        else:
            acc = self.lower_bin_op_operand(BinaryOp.OP_OR, acc, cmp, self.sema.ty_bool as i32, span)
    if has_acc == 0:
        acc = self.int_const_operand(0, self.sema.ty_bool as i32)
    if op == BinaryOp.OP_NOT_IN:
        return self.lower_not_operand(acc, span)
    acc

// `ch in some_str` — emit a STR_CONTAINS_CHAR intrinsic call (recv str, i32 char).
fn MirBuilder.lower_str_contains_char(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
    let fn_op = self.const_operand(ConstKind.CK_FN, 0, self.sema.ty_void)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(self.lower_receiver_with_method_autoderef(rhs_expr))
    call_args.push(self.lower_expr(lhs_expr))
    let args_id = self.body.new_call_args(call_args)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.STR_CONTAINS_CHAR)
    self.body.set_call_ast_node(args_id, node)
    let result = self.new_temp(self.sema.ty_bool as i32)
    let place = self.place_for_local(result)
    let next = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, place, next)
    self.switch_to(next)
    let val = self.body.new_operand(OperandKind.OK_COPY, place)
    if op == BinaryOp.OP_NOT_IN:
        return self.lower_not_operand(val, self.ast.get_start(node))
    val

fn MirBuilder.lower_membership(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
    if self.ast.kind(rhs_expr) == NodeKind.NK_RANGE:
        return self.lower_range_literal_membership(op, lhs_expr, rhs_expr, node)
    if self.ast.kind(rhs_expr) == NodeKind.NK_ARRAY_LIT:
        return self.lower_array_literal_membership(op, lhs_expr, rhs_expr, node)
    let rhs_ty = self.expr_type(rhs_expr)
    let rhs_resolved = if rhs_ty != 0: self.sema.resolve_alias(rhs_ty) else: 0
    if rhs_resolved != 0 and self.sema.get_type_kind(rhs_resolved) == TypeKind.TY_RANGE:
        return self.lower_range_value_membership(op, lhs_expr, rhs_expr, rhs_resolved, node)
    if rhs_resolved != 0 and self.sema.get_type_kind(rhs_resolved) == TypeKind.TY_ARRAY:
        return self.lower_array_value_membership(op, lhs_expr, rhs_expr, rhs_resolved, node)
    // §9.9: `ch in some_str` tests byte/codepoint membership. Chars lower to
    // ints, so distinguish from substring search (`"sub" in str`) by the lhs
    // type — a non-str lhs against a str rhs is char membership (#234).
    if rhs_resolved != 0 and self.sema.get_type_kind(rhs_resolved) == TypeKind.TY_STR:
        let lhs_ty = self.expr_type(lhs_expr)
        let lhs_resolved = if lhs_ty != 0: self.sema.resolve_alias(lhs_ty) else: 0
        if lhs_resolved == 0 or self.sema.get_type_kind(lhs_resolved) != TypeKind.TY_STR:
            return self.lower_str_contains_char(op, lhs_expr, rhs_expr, node)
    // §9.9: `x in collection` desugars to `collection.contains(x)` (Contains
    // trait) for Vec / str / HashMap etc.
    let contains_sym = self.pool.intern("contains")
    // The call-argument extra slot was pre-reserved at parse time (the AST is
    // frozen now); read it back rather than mutating the frozen pool (#234).
    let arg_idx = self.ast.find_membership_arg(node)
    let result = self.lower_method_call(rhs_expr, contains_sym, arg_idx, 1, node)
    if op == BinaryOp.OP_NOT_IN:
        return self.lower_not_operand(result, self.ast.get_start(node))
    result

fn MirBuilder.lower_short_circuit(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
    // Short-circuit: for `a or b`, evaluate a; if true, result is true, else: evaluate b.
    // For `a and b`, evaluate a; if false, result is false, else: evaluate b.
    let result = self.new_temp(self.sema.ty_bool)
    let result_place = self.place_for_local(result)
    let lhs = self.lower_expr(lhs_expr)
    let lhs_rv = self.body.new_rvalue(RvalueKind.RK_USE, lhs, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, result_place, lhs_rv, self.ast.get_start(node))
    let rhs_bb = self.new_block()
    let end_bb = self.new_block()
    let lhs_read = self.body.new_operand(OperandKind.OK_COPY, result_place)
    // Use switch_int: value 1 (true) goes to one target, default goes to other
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    if op == 12:
        // or: if lhs is true (1), skip to end; default (false) → evaluate rhs
        targets.push(end_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, lhs_read, table, rhs_bb, 0)
    else:
        // and: if lhs is true (1), evaluate rhs; default (false) → skip to end
        targets.push(rhs_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, lhs_read, table, end_bb, 0)
    self.switch_to(rhs_bb)
    let rhs = self.lower_expr(rhs_expr)
    let rhs_rv = self.body.new_rvalue(RvalueKind.RK_USE, rhs, 0, 0)
    let result_place2 = self.place_for_local(result)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, result_place2, rhs_rv, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, end_bb, 0, 0, 0)
    self.switch_to(end_bb)
    self.body.new_operand(OperandKind.OK_COPY, self.place_for_local(result))

fn mir_op_method_name(op: i32) -> str:
    if op == 0: return "add"    // BinaryOp.OP_ADD
    if op == 1: return "sub"    // BinaryOp.OP_SUB
    if op == 2: return "mul"    // BinaryOp.OP_MUL
    if op == 3: return "div"    // BinaryOp.OP_DIV
    if op == 4: return "mod"    // BinaryOp.OP_MOD
    if op == 5: return "eq"     // BinaryOp.OP_EQ
    if op == 6: return "ne"     // BinaryOp.OP_NEQ
    if op == 7: return "lt"     // BinaryOp.OP_LT
    if op == 8: return "gt"     // BinaryOp.OP_GT
    if op == 9: return "le"     // BinaryOp.OP_LTE
    if op == 10: return "ge"    // BinaryOp.OP_GTE
    if op == 28: return "matmul" // BinaryOp.OP_MATMUL
    ""

fn MirBuilder.lower_method_bin_op(self: MirBuilder, lhs_expr: i32, rhs_expr: i32, method_sym: i32, node: i32) -> i32:
    // Lower as: method_sym(lhs, rhs)
    let fn_op = self.lower_var(method_sym, 0, 0)
    let arg_nodes: Vec[i32] = Vec.new()
    arg_nodes.push(lhs_expr)
    arg_nodes.push(rhs_expr)
    self.lower_call_with_arg_nodes(fn_op, method_sym, arg_nodes, self.expr_type(node), node)

fn MirBuilder.is_runtime_pair_multi_index(self: MirBuilder, node: i32) -> i32:
    if self.ast.kind(node) != NodeKind.NK_INDEX:
        return 0
    if self.ast.get_data2(node) == 0:
        return 0
    if self.sema.index_expr_is_type_level(self.ast.get_data0(node)) != 0:
        return 0
    1

fn MirBuilder.lower_multi_index_read(self: MirBuilder, node: i32) -> i32:
    let base_op = self.lower_expr(self.ast.get_data0(node))
    let mi_args: Vec[i32] = Vec.new()
    mi_args.push(base_op)
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_INDEX:
        mi_args.push(self.lower_expr(self.ast.get_data1(node)))
        mi_args.push(self.int_const_operand(0, self.sema.ty_i64))
        mi_args.push(self.int_const_operand(0, self.sema.ty_i64))
        mi_args.push(self.lower_expr(self.ast.get_data2(node)))
        mi_args.push(self.int_const_operand(0, self.sema.ty_i64))
        mi_args.push(self.int_const_operand(0, self.sema.ty_i64))
    else:
        let specs_start = self.ast.get_data1(node)
        let specs_count = self.ast.get_data2(node)
        for si in 0..specs_count:
            let spec = self.ast.get_extra(specs_start + si)
            let d0 = self.ast.get_data0(spec)
            let d1 = self.ast.get_data1(spec)
            let d2 = self.ast.get_data2(spec)
            let step_node = d2 - (d2 / INDEX_KIND_SHIFT) * INDEX_KIND_SHIFT
            mi_args.push(if d0 != 0: self.lower_expr(d0) else: self.int_const_operand(0, self.sema.ty_i64))
            mi_args.push(if d1 != 0: self.lower_expr(d1) else: self.int_const_operand(0, self.sema.ty_i64))
            mi_args.push(if step_node != 0: self.lower_expr(step_node) else: self.int_const_operand(0, self.sema.ty_i64))
    let mi_args_id = self.body.new_call_args(mi_args)
    self.body.set_call_intrinsic(mi_args_id, MirIntrinsic.MULTI_INDEX)
    self.body.set_call_ast_node(mi_args_id, node)
    let mi_ret_ty = self.expr_type(node)
    let mi_result = self.new_temp(mi_ret_ty)
    let mi_result_place = self.place_for_local(mi_result)
    let mi_next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), mi_args_id, mi_result_place, mi_next_bb)
    self.switch_to(mi_next_bb)
    mi_result_place

fn MirBuilder.lower_multi_index_set(self: MirBuilder, place_expr: i32, rhs_expr: i32):
    let mi_base_op = self.lower_expr(self.ast.get_data0(place_expr))
    let mi_args: Vec[i32] = Vec.new()
    mi_args.push(mi_base_op)
    let kind = self.ast.kind(place_expr)
    if kind == NodeKind.NK_INDEX:
        mi_args.push(self.lower_expr(self.ast.get_data1(place_expr)))
        mi_args.push(self.int_const_operand(0, self.sema.ty_i64))
        mi_args.push(self.int_const_operand(0, self.sema.ty_i64))
        mi_args.push(self.lower_expr(self.ast.get_data2(place_expr)))
        mi_args.push(self.int_const_operand(0, self.sema.ty_i64))
        mi_args.push(self.int_const_operand(0, self.sema.ty_i64))
    else:
        let specs_start = self.ast.get_data1(place_expr)
        let specs_count = self.ast.get_data2(place_expr)
        for si in 0..specs_count:
            let spec = self.ast.get_extra(specs_start + si)
            let d0 = self.ast.get_data0(spec)
            let d1 = self.ast.get_data1(spec)
            let d2 = self.ast.get_data2(spec)
            let step_node = d2 - (d2 / INDEX_KIND_SHIFT) * INDEX_KIND_SHIFT
            mi_args.push(if d0 != 0: self.lower_expr(d0) else: self.int_const_operand(0, self.sema.ty_i64))
            mi_args.push(if d1 != 0: self.lower_expr(d1) else: self.int_const_operand(0, self.sema.ty_i64))
            mi_args.push(if step_node != 0: self.lower_expr(step_node) else: self.int_const_operand(0, self.sema.ty_i64))
    let mi_rhs_op = self.lower_expr(rhs_expr)
    mi_args.push(mi_rhs_op)
    let mi_args_id = self.body.new_call_args(mi_args)
    self.body.set_call_intrinsic(mi_args_id, MirIntrinsic.MULTI_INDEX_SET)
    self.body.set_call_ast_node(mi_args_id, place_expr)
    let mi_next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), mi_args_id, self.place_for_local(0), mi_next_bb)
    self.switch_to(mi_next_bb)

fn MirBuilder.lower_fn_address(self: MirBuilder, expr: i32, type_id: i32) -> i32:
    if expr == 0:
        return -1
    let kind = self.ast.kind(expr)
    if kind == NodeKind.NK_GROUPED:
        return self.lower_fn_address(self.ast.get_data0(expr), type_id)
    if kind != NodeKind.NK_IDENT:
        return -1
    let sym = self.ast.get_data0(expr)
    if self.lookup_local(sym) >= 0:
        return -1
    if self.lookup_alias_place(sym) >= 0:
        return -1
    if self.sema.get_sig(sym) >= 0 or self.sema.generic_fn_nodes.contains(sym):
        return self.lower_var(sym, type_id, expr)
    -1

fn MirBuilder.lower_un_op(self: MirBuilder, op: i32, expr: i32, node: i32) -> i32:
    if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT:
        let fn_addr = self.lower_fn_address(expr, self.expr_type(node))
        if fn_addr >= 0:
            return fn_addr
        let place = self.lower_expr_place(expr)
        let is_exclusive = op == UnaryOp.UOP_RAW_REF_MUT
        let rv = self.body.new_rvalue(RvalueKind.RK_REF, if is_exclusive: BorrowKind.EXCLUSIVE else: BorrowKind.SHARED, place, 0)
        let ty = self.expr_type(node)
        let temp = self.new_temp(ty)
        let temp_place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, temp_place)

    if op == UnaryOp.UOP_DEREF:
        let place = self.lower_expr_place(expr)
        let deref_place = self.body.new_deref_place(place)
        return self.body.new_operand(OperandKind.OK_COPY, deref_place)

    let arg = self.lower_expr(expr)
    let rv = self.body.new_rvalue(RvalueKind.RK_UN_OP, op, arg, 0)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_cast(self: MirBuilder, expr: i32, target_type_id: i32, node: i32) -> i32:
    let op = self.lower_expr(expr)
    let src_sema_ty = self.expr_type(expr)
    let rv = self.body.new_rvalue(RvalueKind.RK_CAST, op, target_type_id, src_sema_ty)
    let temp = self.new_temp(target_type_id)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_field_access(self: MirBuilder, node: i32) -> i32:
    let base_expr = self.ast.get_data0(node)
    let field_idx = self.ast.get_data1(node)
    let field_ty = self.expr_type(node)
    if field_ty == 0 or field_ty == self.sema.ty_void as i32:
        self.mark_unsupported()
        return self.place_for_local(0)
    let base = self.lower_field_base_place(base_expr)
    self.body.new_field_place(base, field_idx, field_ty)

fn MirBuilder.lower_field_base_place(self: MirBuilder, base_expr: i32) -> i32:
    var base = self.lower_expr_place(base_expr)
    var base_ty = self.expr_type(base_expr)
    while base_ty > 0:
        let resolved = self.sema.resolve_alias(base_ty)
        let tk = self.sema.get_type_kind(resolved)
        if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
            break
        base = self.body.new_deref_place(base)
        base_ty = self.sema.get_type_d0(resolved)
    base

fn MirBuilder.lower_index(self: MirBuilder, base_expr: i32, index_expr: i32) -> i32:
    var base = self.lower_expr_place(base_expr)
    // Indexing through `&Vec[T]` / `&mut Vec[T]` should index the container,
    // not treat the reference itself like a raw pointer.
    var base_ty = self.expr_type(base_expr)
    while base_ty > 0:
        let resolved = self.sema.resolve_alias(base_ty)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_REF:
            break
        base = self.body.new_deref_place(base)
        base_ty = self.sema.get_type_d0(resolved)
    let elem_ty = self.indexed_element_type(base_ty)
    let idx_op = self.lower_expr(index_expr)
    let idx_ty = self.expr_type(index_expr)
    let idx_local = self.new_temp(idx_ty)
    let idx_place = self.place_for_local(idx_local)
    self.assign_operand_to_place(idx_place, idx_op, self.ast.get_start(index_expr))
    self.body.new_index_place(base, idx_local, elem_ty)

fn MirBuilder.lower_call_place(self: MirBuilder, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_CALL:
        return -1
    let callee = self.ast.get_data0(node)
    if self.ast.kind(callee) != NodeKind.NK_FIELD_ACCESS:
        return -1
    let recv_expr = self.ast.get_data0(callee)
    let method_sym = self.ast.get_data1(callee)
    var recv_type = self.expr_type(recv_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        recv_type = self.type_receiver_type(recv_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        return -1
    let method_name = self.pool.resolve_symbol(method_sym)
    let intrinsic = self.classify_intrinsic(recv_type, method_name)
    // Preserve lvalue identity for vec element projections used as a place
    // (for example `items.get(0).tags.push(...)`).
    if intrinsic != MirIntrinsic.VEC_GET:
        return -1
    let arg_count = self.ast.get_data2(node)
    if arg_count != 1:
        return -1
    let arg_start = self.ast.get_data1(node)
    let index_expr = self.ast.get_extra(arg_start)
    self.lower_index(recv_expr, index_expr)

fn MirBuilder.lower_binding_alias_place(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return -1
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_GROUPED:
        return self.lower_binding_alias_place(self.ast.get_data0(node))
    if kind == NodeKind.NK_CALL:
        return self.lower_call_place(node)
    if kind == NodeKind.NK_FIELD_ACCESS:
        let base_expr = self.ast.get_data0(node)
        let base_place = self.lower_binding_alias_place(base_expr)
        if base_place < 0:
            return -1
        let field_sym = self.ast.get_data1(node)
        var field_base = base_place
        var base_ty = self.expr_type(base_expr)
        while base_ty > 0:
            let resolved = self.sema.resolve_alias(base_ty)
            let tk = self.sema.get_type_kind(resolved)
            if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
                break
            field_base = self.body.new_deref_place(field_base)
            base_ty = self.sema.get_type_d0(resolved)
        return self.body.new_field_place(field_base, field_sym, self.expr_type(node))
    -1

fn MirBuilder.lower_vec_literal_push(self: MirBuilder, vec_place: i32, elem_node: i32, elem_ty: i32):
    if elem_node == 0:
        return
    let push_sym = self.pool.intern("push")
    let fn_op = self.const_operand(ConstKind.CK_FN, push_sym, self.sema.ty_void)
    let saved_expected = self.expected_type
    if elem_ty > 0 and elem_ty != self.sema.ty_void:
        self.expected_type = elem_ty
    let elem_op = self.lower_expr(elem_node)
    self.expected_type = saved_expected
    let args: Vec[i32] = Vec.new()
    args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    args.push(elem_op)
    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(self.sema.ty_void)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.VEC_PUSH)

fn MirBuilder.lower_vec_literal(self: MirBuilder, node: i32, vec_ty: i32) -> i32:
    let base_expr = self.ast.get_data0(node)
    let first_elem = self.ast.get_data1(node)
    let second_elem = self.ast.get_data2(node)
    let new_sym = self.pool.intern("new")
    let new_op = self.lower_intrinsic_call(MirIntrinsic.VEC_NEW, base_expr, new_sym, 0, 0, node)
    let vec_place = self.materialize_operand(new_op, vec_ty, self.ast.get_start(node))
    let resolved = self.sema.resolve_alias(vec_ty)
    let elem_ty = if self.sema.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST: self.sema.get_generic_inst_arg(resolved, 0) else: 0
    self.lower_vec_literal_push(vec_place, first_elem, elem_ty)
    if second_elem != 0:
        self.lower_vec_literal_push(vec_place, second_elem, elem_ty)
    if self.sema.is_copy(vec_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, vec_place)
    self.body.new_operand(OperandKind.OK_MOVE, vec_place)

fn MirBuilder.lower_deref(self: MirBuilder, expr: i32) -> i32:
    let base = self.lower_expr_place(expr)
    self.body.new_deref_place(base)

fn MirBuilder.lower_ref(self: MirBuilder, expr: i32, borrow_kind: i32, node: i32) -> i32:
    let place = self.lower_expr_place(expr)
    let rv = self.body.new_rvalue(RvalueKind.RK_REF, borrow_kind, place, 0)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let temp_place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, temp_place)

fn MirBuilder.lower_assign(self: MirBuilder, place_expr: i32, rhs_expr: i32):
    // Multi-index assignment: a[i, j] = value → call multi_index_set
    if self.ast.kind(place_expr) == NodeKind.NK_MULTI_INDEX or self.is_runtime_pair_multi_index(place_expr) != 0:
        self.lower_multi_index_set(place_expr, rhs_expr)
        return
    if self.ast.kind(place_expr) == NodeKind.NK_INDEX:
        var ip_base_ty = self.expr_type(self.ast.get_data0(place_expr))
        while ip_base_ty > 0 and self.sema.get_type_kind(self.sema.resolve_alias(ip_base_ty)) == TypeKind.TY_REF:
            ip_base_ty = self.sema.get_type_d0(self.sema.resolve_alias(ip_base_ty))
        if self.is_user_index_place(ip_base_ty) != 0:
            let ip_set_sym = self.sema.pool_lookup_symbol("set")
            let ip_type_sym = self.sema.get_type_name(ip_base_ty)
            let ip_fn_sym = self.sema.lookup_method_fn(ip_type_sym, ip_set_sym)
            if ip_fn_sym != 0:
                let ip_recv_op = self.lower_expr(self.ast.get_data0(place_expr))
                let ip_idx_op = self.lower_expr(self.ast.get_data1(place_expr))
                let ip_idx_ty = self.expr_type(self.ast.get_data1(place_expr))
                let ip_idx_tmp = self.new_temp(ip_idx_ty)
                let ip_idx_place = self.place_for_local(ip_idx_tmp)
                self.assign_operand_to_place(ip_idx_place, ip_idx_op, self.ast.get_start(place_expr))
                var ip_val_op = 0
                let ip_is_compound = self.ast.kind(rhs_expr) == NodeKind.NK_BINARY and self.ast.get_data1(rhs_expr) == place_expr
                if ip_is_compound:
                    let ip_get_sym = self.sema.pool_lookup_symbol("get")
                    let ip_get_fn = self.sema.lookup_method_fn(ip_type_sym, ip_get_sym)
                    let ip_get_fn_op = self.const_operand(ConstKind.CK_FN, ip_get_fn, self.expr_type(place_expr))
                    let ip_get_args: Vec[i32] = Vec.new()
                    ip_get_args.push(ip_recv_op)
                    ip_get_args.push(self.body.new_operand(OperandKind.OK_COPY, ip_idx_place))
                    let ip_get_args_id = self.body.new_call_args(ip_get_args)
                    let ip_cur_ty = self.expr_type(place_expr)
                    let ip_cur_tmp = self.new_temp(ip_cur_ty)
                    let ip_cur_place = self.place_for_local(ip_cur_tmp)
                    let ip_get_next = self.new_block()
                    self.terminate(TermKind.TK_CALL, ip_get_fn_op, ip_get_args_id, ip_cur_place, ip_get_next)
                    self.switch_to(ip_get_next)
                    let ip_cur_val = self.body.new_operand(OperandKind.OK_COPY, ip_cur_place)
                    let ip_ca_op = self.ast.get_data0(rhs_expr)
                    let ip_inc_val = self.lower_expr(self.ast.get_data2(rhs_expr))
                    ip_val_op = self.lower_bin_op_operand(ip_ca_op, ip_cur_val, ip_inc_val, ip_cur_ty, self.ast.get_start(place_expr))
                else:
                    ip_val_op = self.lower_expr(rhs_expr)
                let ip_fn_op = self.const_operand(ConstKind.CK_FN, ip_fn_sym, self.sema.ty_void)
                let ip_args: Vec[i32] = Vec.new()
                ip_args.push(ip_recv_op)
                ip_args.push(self.body.new_operand(OperandKind.OK_COPY, ip_idx_place))
                ip_args.push(ip_val_op)
                let ip_args_id = self.body.new_call_args(ip_args)
                let ip_next_bb = self.new_block()
                self.terminate(TermKind.TK_CALL, ip_fn_op, ip_args_id, self.place_for_local(0), ip_next_bb)
                self.switch_to(ip_next_bb)
                return
    // §6.3 compound assignment single-evaluation: xs[f()] += g() must
    // evaluate f() and g() exactly once.  The parser desugars += to
    // NK_ASSIGN(target, NK_BINARY(op, target, rhs)) sharing the same AST
    // node for both occurrences of target.  Detect this and lower as a
    // single read-modify-write through the place.
    if self.try_lower_string_self_concat_assign(place_expr, rhs_expr) >= 0:
        return

    if self.ast.kind(rhs_expr) == NodeKind.NK_BINARY and self.ast.get_data1(rhs_expr) == place_expr:
        let ca_op = self.ast.get_data0(rhs_expr)
        let ca_inc_expr = self.ast.get_data2(rhs_expr)
        let ca_place = self.lower_expr_place(place_expr)
        let ca_elem_ty = self.expr_type(place_expr)
        let ca_cur = self.body.new_operand(OperandKind.OK_COPY, ca_place)
        let ca_inc = self.lower_expr(ca_inc_expr)
        let ca_result = self.lower_bin_op_operand(ca_op, ca_cur, ca_inc, ca_elem_ty, self.ast.get_start(place_expr))
        self.assign_operand_to_place(ca_place, ca_result, self.ast.get_start(place_expr))
        return

    let place = self.lower_expr_place(place_expr)
    let saved_expected = self.expected_type
    let dest_ty = self.expr_type(place_expr)
    if dest_ty != 0 and dest_ty != self.sema.ty_void:
        self.expected_type = dest_ty
    let rhs = self.lower_expr(rhs_expr)
    self.expected_type = saved_expected
    // Drop the old value before reassignment if the type implements Drop.
    if dest_ty != 0 and self.sema.is_copy(dest_ty) == 0:
        let resolved_ty = self.sema.resolve_alias(dest_ty)
        let tk = self.sema.get_type_kind(resolved_ty)
        if tk == TypeKind.TY_STRUCT:
            let type_name = self.sema.get_type_d0(resolved_ty)
            if self.sema.has_drop_method(type_name) != 0:
                self.body.push_stmt(self.cur_bb, StmtKind.Drop, place, 0, self.ast.get_start(place_expr))
    self.assign_operand_to_place(place, rhs, self.ast.get_start(place_expr))

fn MirBuilder.lower_expr_place(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.place_for_local(0)

    let kind = self.ast.kind(node)

    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        let local = self.lookup_local(sym)
        if local >= 0:
            return self.place_for_local(local)
        let alias_place = self.lookup_alias_place(sym)
        if alias_place >= 0:
            return alias_place
        // Try module-level mutable variable
        let gv_local = self.ensure_global_local(sym)
        if gv_local >= 0:
            return self.place_for_local(gv_local)
        self.mark_unsupported()
        return self.place_for_local(0)

    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = self.lower_field_base_place(self.ast.get_data0(node))
        let field_sym = self.ast.get_data1(node)
        let field_ty = self.expr_type(node)
        if field_ty == 0 or field_ty == self.sema.ty_void as i32:
            self.mark_unsupported()
            return self.place_for_local(0)
        // Field symbol is mapped deterministically to a projection index by symbol value.
        return self.body.new_field_place(base, field_sym, field_ty)

    if kind == NodeKind.NK_INDEX:
        if self.vec_literal_type(node) != 0:
            let op = self.lower_expr(node)
            let ty = self.expr_type(node)
            let tmp = self.new_temp(ty)
            let p = self.place_for_local(tmp)
            self.assign_operand_to_place(p, op, self.ast.get_start(node))
            return p
        if self.is_runtime_pair_multi_index(node) != 0:
            return self.lower_multi_index_read(node)
        return self.lower_index(self.ast.get_data0(node), self.ast.get_data1(node))

    if kind == NodeKind.NK_MULTI_INDEX:
        return self.lower_multi_index_read(node)

    if kind == NodeKind.NK_ASSIGN:
        let target = self.ast.get_data0(node)
        self.lower_assign(target, self.ast.get_data1(node))
        return self.lower_expr_place(target)

    if kind == NodeKind.NK_CALL:
        let call_place = self.lower_call_place(node)
        if call_place >= 0:
            return call_place

    if kind == NodeKind.NK_UNARY and self.ast.get_data0(node) == UnaryOp.UOP_DEREF:
        return self.lower_deref(self.ast.get_data1(node))

    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_NO_SUSPEND:
        return self.lower_expr_place(self.ast.get_data0(node))

    // Transparent pass-through. lower_expr already does this for the rvalue
    // case (line 4043); the place version was missing the same handling, so
    // `(unsafe *p) = expr` would fall through to the materialize-as-temp
    // fallback below — silently dropping the store. The migrator emits this
    // pattern for every C struct assignment `*p = q`, so the breakage was
    // load-bearing for PCRE2.
    if kind == NodeKind.NK_UNSAFE_BLOCK:
        return self.lower_expr_place(self.ast.get_data0(node))

    // Fallback: materialize value into temp local and return its place.
    let op = self.lower_expr(node)
    let ty = self.expr_type(node)
    let tmp = self.new_temp(ty)
    let p = self.place_for_local(tmp)
    self.assign_operand_to_place(p, op, self.ast.get_start(node))
    p

fn MirBuilder.lower_let_binding(self: MirBuilder, node: i32):
    let name_sym = self.ast.get_data0(node)
    let rhs_expr = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)
    let mutable = flags % 2
    let is_discard_binding = if name_sym != 0 and self.pool.resolve_symbol(name_sym) == "_": 1 else: 0

    let bind_ty = self.binding_type(node)
    if mutable == 0:
        if self.sema.is_copy(bind_ty) == 0:
            let alias_place = self.lower_binding_alias_place(rhs_expr)
            if alias_place >= 0:
                self.bind_alias_place(name_sym, alias_place, bind_ty)
                return
    let local_id = self.body.new_local(bind_ty, mutable, name_sym, 1)

    // d1 = 0 for normal storage, bind_ty for zero-init (no initializer)
    let storage_d1 = if rhs_expr == 0: bind_ty else: 0
    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, storage_d1, self.ast.get_start(node))
    var scheduled_drop_kind = DropKind.DK_VALUE
    if self.sema.is_copy(bind_ty) == 0:
        scheduled_drop_kind = self.task_drop_kind_for_binding(node, bind_ty)
        if is_discard_binding == 0:
            self.schedule_drop(local_id, scheduled_drop_kind)

    if rhs_expr != 0:
        let place = self.place_for_local(local_id)
        let saved_expected = self.expected_type
        self.expected_type = bind_ty
        let rhs_op = self.lower_expr(rhs_expr)
        self.expected_type = saved_expected
        self.assign_operand_to_place(place, rhs_op, self.ast.get_start(node))
    if is_discard_binding != 0:
        if self.sema.is_copy(bind_ty) == 0:
            self.emit_drop_entry(local_id, scheduled_drop_kind)
        else:
            self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, self.ast.get_start(node))
        return
    self.bind_local(name_sym, local_id)

fn MirBuilder.lower_tuple_destructure(self: MirBuilder, node: i32):
    let extra_start = self.ast.get_data0(node)
    let name_count = self.ast.get_data1(node)
    let rhs_expr = self.ast.get_data2(node)
    let rhs_ty = self.expr_type(rhs_expr)
    let rhs_op = self.lower_expr(rhs_expr)
    let rhs_place = self.materialize_operand(rhs_op, rhs_ty, self.ast.get_start(node))
    // Bind each name to the corresponding tuple field
    for ni in 0..name_count:
        let n_sym = self.ast.get_extra(extra_start + ni)
        if n_sym == 0:
            continue
        // Negative sym means ..rest pattern — skip for now
        if n_sym < 0:
            continue
        let elem_ty = self.tuple_elem_type(rhs_ty, ni)
        let local_id = self.body.new_local(elem_ty, 0, n_sym, 1)
        self.bind_local(n_sym, local_id)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(node))
        let field_place = self.body.new_field_place(rhs_place, ni, elem_ty)
        let field_op = self.body.new_operand(OperandKind.OK_COPY, field_place)
        let dst_place = self.place_for_local(local_id)
        self.assign_operand_to_place(dst_place, field_op, self.ast.get_start(node))

fn MirBuilder.lower_let_else(self: MirBuilder, node: i32):
    let pat = self.ast.get_data0(node)
    let rhs = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)
    let rhs_op = self.lower_expr(rhs)
    let rhs_ty = self.expr_type(rhs)
    let rhs_place = self.materialize_operand(rhs_op, rhs_ty, self.ast.get_start(rhs))

    if else_body == 0:
        let _ = self.lower_pattern(pat, rhs_place)
        return

    let success_bb = self.new_block()
    let fail_bb = self.new_block()
    let cont_bb = self.new_block()

    self.lower_pattern_match(rhs_place, pat, success_bb, fail_bb)

    self.switch_to(success_bb)
    let _ = self.lower_pattern(pat, rhs_place)
    self.terminate(TermKind.TK_GOTO, cont_bb, 0, 0, 0)

    self.switch_to(fail_bb)
    let _ = self.lower_expr(else_body)
    if self.body.term_kind(self.cur_bb) == TermKind.TK_UNREACHABLE:
        self.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)

    self.switch_to(cont_bb)

fn MirBuilder.lower_expr_discard(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.unit_operand()
    let saved_expected = self.expected_type
    self.expected_type = self.sema.ty_void as i32
    let kind = self.ast.kind(node)
    let result = if kind == NodeKind.NK_BLOCK:
        self.lower_block_mode(node, 0)
    else if kind == NodeKind.NK_IF_EXPR:
        self.lower_if(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node, 0)
    else:
        self.lower_expr(node)
    self.expected_type = saved_expected
    let _ = result
    self.unit_operand()

fn MirBuilder.scope_body_tail_is_method_call(self: MirBuilder, node: i32, scope_sym: i32, method_sym: i32) -> i32:
    if node == 0 or scope_sym == 0 or method_sym == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_NO_SUSPEND:
        return self.scope_body_tail_is_method_call(self.ast.get_data0(node), scope_sym, method_sym)
    if kind == NodeKind.NK_BLOCK:
        return self.scope_body_tail_is_method_call(self.ast.get_data2(node), scope_sym, method_sym)
    if kind != NodeKind.NK_CALL:
        return 0
    let callee = self.ast.get_data0(node)
    if self.ast.kind(callee) != NodeKind.NK_FIELD_ACCESS:
        return 0
    let recv = self.ast.get_data0(callee)
    if self.ast.kind(recv) != NodeKind.NK_IDENT or self.ast.get_data0(recv) != scope_sym:
        return 0
    if self.ast.get_data1(callee) == method_sym:
        return 1
    0

fn MirBuilder.lower_block(self: MirBuilder, node: i32) -> i32:
    self.lower_block_mode(node, 1)

fn MirBuilder.lower_generator_yield(self: MirBuilder, node: i32) -> i32:
    let inner = self.ast.get_data0(node)
    let value_op = if inner != 0: self.lower_expr(inner) else: self.unit_operand()
    let resume_bb = self.new_block()
    let yield_idx = self.generator_yield_count
    self.generator_yield_count = self.generator_yield_count + 1
    self.terminate_with_span(TermKind.TK_YIELD, value_op, resume_bb, yield_idx, 0, self.ast.get_start(node))
    self.switch_to(resume_bb)
    self.unit_operand()

fn MirBuilder.lower_block_mode(self: MirBuilder, node: i32, want_result: i32) -> i32:
    let stmt_start = self.ast.get_data0(node)
    let stmt_count = self.ast.get_data1(node)
    let tail_expr = self.ast.get_data2(node)
    let block_meta = self.ast.find_block_meta(node)
    let block_label = if block_meta >= 0: self.ast.block_meta_label(block_meta) else: 0
    let labeled_after_bb = if block_label != 0: self.new_block() else: 0

    if block_label != 0:
        self.push_control_target(block_label, ControlTargetKind.CT_BLOCK, -1, labeled_after_bb, -1)
    self.push_scope()
    let defer_start = self.defer_nodes.len() as i32

    for i in 0..stmt_count:
        let stmt = self.ast.get_extra(stmt_start + i)
        let sk = self.ast.kind(stmt)
        if sk == NodeKind.NK_LET_BINDING:
            self.lower_let_binding(stmt)
            continue
        if sk == NodeKind.NK_LET_ELSE:
            self.lower_let_else(stmt)
            continue
        if sk == NodeKind.NK_ASSIGN:
            self.lower_assign(self.ast.get_data0(stmt), self.ast.get_data1(stmt))
            continue
        if sk == NodeKind.NK_RETURN:
            let _ = self.lower_return(stmt)
            continue
        if sk == NodeKind.NK_BREAK:
            let _ = self.lower_break(stmt)
            continue
        if sk == NodeKind.NK_CONTINUE:
            let _ = self.lower_continue(stmt)
            continue
        if sk == NodeKind.NK_GOTO:
            let _ = self.lower_goto(stmt)
            continue
        if sk == NodeKind.NK_LABEL:
            let _ = self.lower_label(stmt)
            continue
        if sk == NodeKind.NK_YIELD:
            if self.in_generator != 0:
                let _ = self.lower_generator_yield(stmt)
                continue
        
        if sk == NodeKind.NK_DEFER:
            let defer_body = self.ast.get_data0(stmt)
            if defer_body != 0:
                self.defer_nodes.push(defer_body)
            continue
        if sk == NodeKind.NK_ERRDEFER:
            let errdefer_body = self.ast.get_data0(stmt)
            if errdefer_body != 0:
                self.errdefer_nodes.push(errdefer_body)
            continue
        if sk == NodeKind.NK_TUPLE_DESTRUCTURE:
            self.lower_tuple_destructure(stmt)
            continue
        let _ = self.lower_expr_discard(stmt)

    var result = self.unit_operand()
    if tail_expr != 0:
        if want_result != 0:
            self.cancel_scheduled_value_drop_for_receiver_expr(tail_expr)
            result = self.lower_expr(tail_expr)
        else:
            result = self.lower_expr_discard(tail_expr)

    // Emit defers added in this block scope (LIFO order), before popping scope
    let defer_end = self.defer_nodes.len() as i32
    if defer_end > defer_start:
        var di = defer_end - 1
        while di >= defer_start:
            let defer_body = self.defer_nodes.get(di as i64)
            let _ = self.lower_expr(defer_body)
            di = di - 1
        // Remove the block's defers from the stack
        while self.defer_nodes.len() as i32 > defer_start:
            self.defer_nodes.pop()

    self.pop_scope_inline()
    if block_label != 0:
        self.terminate(TermKind.TK_GOTO, labeled_after_bb, 0, 0, 0)
        self.pop_control_target()
        self.switch_to(labeled_after_bb)
        return self.unit_operand()
    if want_result != 0: result else: self.unit_operand()

fn MirBuilder.lower_if(self: MirBuilder, cond_expr: i32, then_expr: i32, else_expr_opt: i32, node: i32, want_result: i32) -> i32:
    var cond_op = 0
    var regex_capture_node = 0
    var regex_captures_opt_place = -1
    if self.ast.kind(cond_expr) == NodeKind.NK_MATCH_OP:
        let lhs = self.ast.get_data0(cond_expr)
        let rhs = self.ast.get_data1(cond_expr)
        let text_op = self.lower_expr(lhs)
        let regex_text_place = self.materialize_operand(text_op, self.expr_type(lhs), self.ast.get_start(lhs))
        let regex_op = self.lower_expr(rhs)
        let regex_capture_place = self.materialize_operand(regex_op, self.expr_type(rhs), self.ast.get_start(rhs))
        regex_captures_opt_place = self.lower_regex_captures_places(regex_capture_place, regex_text_place)
        cond_op = self.lower_option_is_some_place(regex_captures_opt_place, self.regex_captures_option_type())
        if self.ast.kind(rhs) == NodeKind.NK_REGEX_LIT:
            regex_capture_node = rhs
    else:
        cond_op = self.lower_expr(cond_expr)

    let then_bb = self.new_block()
    let else_bb = self.new_block()
    let join_bb = self.new_block()

    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(then_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cond_op, table, else_bb, 0)

    let result_ty = if want_result != 0: self.expr_type(node) else: self.sema.ty_void as i32
    let result_local = if want_result != 0: self.new_temp(result_ty) else: -1
    let result_place = if want_result != 0: self.place_for_local(result_local) else: -1

    let saved_expected = self.expected_type
    if want_result != 0 and result_ty != 0:
        self.expected_type = result_ty
    else if want_result == 0:
        self.expected_type = self.sema.ty_void as i32

    self.switch_to(then_bb)
    if regex_capture_node != 0:
        self.lower_regex_capture_bindings_from_option(regex_capture_node, regex_captures_opt_place)
    let then_op = if want_result != 0: self.lower_expr(then_expr) else: self.lower_expr_discard(then_expr)
    if want_result != 0:
        self.assign_operand_to_place(result_place, then_op, self.ast.get_start(then_expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(else_bb)
    let else_op = if else_expr_opt != 0:
        if want_result != 0: self.lower_expr(else_expr_opt) else: self.lower_expr_discard(else_expr_opt)
    else:
        self.unit_operand()
    if want_result != 0:
        self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.expected_type = saved_expected

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    if want_result == 0:
        return self.unit_operand()
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_if_let(self: MirBuilder, pat: i32, scrutinee_expr: i32, then_expr: i32, else_expr_opt: i32, node: i32) -> i32:
    let scrutinee_ty = self.expr_type(scrutinee_expr)
    let saved_expected = self.expected_type
    if scrutinee_ty != 0 and scrutinee_ty != self.sema.ty_void as i32:
        self.expected_type = scrutinee_ty
    else:
        self.expected_type = 0
    let scrutinee_op = self.lower_expr(scrutinee_expr)
    self.expected_type = saved_expected
    let scrutinee_place = self.materialize_operand(scrutinee_op, scrutinee_ty, self.ast.get_start(scrutinee_expr))

    let then_bb = self.new_block()
    let else_bb = self.new_block()
    let join_bb = self.new_block()

    self.lower_pattern_match(scrutinee_place, pat, then_bb, else_bb)

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(then_bb)
    let _ = self.lower_pattern(pat, scrutinee_place)
    let then_op = self.lower_expr(then_expr)
    self.assign_operand_to_place(result_place, then_op, self.ast.get_start(then_expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(else_bb)
    let else_op = if else_expr_opt != 0: self.lower_expr(else_expr_opt) else: self.unit_operand()
    self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_loop(self: MirBuilder, body_expr: i32, node: i32) -> i32:
    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let break_bb = self.new_block()
    let loop_ty = if self.sema.typed_expr_types.contains(node): self.sema.typed_expr_types.get(node).unwrap() else: self.sema.ty_void as i32
    let has_result = loop_ty != 0 and loop_ty != self.sema.ty_void and loop_ty != self.sema.ty_never
    let result_place = if has_result: self.place_for_local(self.new_temp(loop_ty)) else: -1

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.switch_to(header_bb)
    self.terminate(TermKind.TK_GOTO, body_bb, 0, 0, 0)

    self.push_control_target(self.ast.get_data1(node), ControlTargetKind.CT_LOOP, header_bb, break_bb, result_place)

    self.switch_to(body_bb)
    let _ = self.lower_expr_discard(body_expr)
    // Back-edge when body does not diverge.
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_control_target()
    self.switch_to(break_bb)
    self.forget_string_flow_facts()
    if has_result:
        if self.sema.is_copy(loop_ty as TypeId) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        return self.body.new_operand(OperandKind.OK_MOVE, result_place)
    self.unit_operand()

fn MirBuilder.lower_while(self: MirBuilder, cond_expr: i32, body_expr: i32, node: i32) -> i32:
    let cond_bb = self.new_block()
    let body_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, cond_bb, 0, 0, 0)

    self.push_control_target(self.ast.get_data2(node), ControlTargetKind.CT_LOOP, cond_bb, exit_bb, -1)

    self.switch_to(cond_bb)
    var cond_op = 0
    var regex_capture_node = 0
    var regex_captures_opt_place = -1
    if self.ast.kind(cond_expr) == NodeKind.NK_MATCH_OP:
        let lhs = self.ast.get_data0(cond_expr)
        let rhs = self.ast.get_data1(cond_expr)
        let text_op = self.lower_expr(lhs)
        let text_place = self.materialize_operand(text_op, self.expr_type(lhs), self.ast.get_start(lhs))
        let regex_op = self.lower_expr(rhs)
        let regex_place = self.materialize_operand(regex_op, self.expr_type(rhs), self.ast.get_start(rhs))
        regex_captures_opt_place = self.lower_regex_captures_places(regex_place, text_place)
        cond_op = self.lower_option_is_some_place(regex_captures_opt_place, self.regex_captures_option_type())
        if self.ast.kind(rhs) == NodeKind.NK_REGEX_LIT:
            regex_capture_node = rhs
    else:
        cond_op = self.lower_expr(cond_expr)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cond_op, table, exit_bb, 0)

    self.switch_to(body_bb)
    if regex_capture_node != 0:
        self.lower_regex_capture_bindings_from_option(regex_capture_node, regex_captures_opt_place)
    let _ = self.lower_expr_discard(body_expr)
    self.terminate(TermKind.TK_GOTO, cond_bb, 0, 0, 0)

    self.pop_control_target()
    self.switch_to(exit_bb)
    self.forget_string_flow_facts()
    self.unit_operand()

fn MirBuilder.lower_do_while(self: MirBuilder, body_expr: i32, cond_expr: i32, node: i32) -> i32:
    let body_bb = self.new_block()
    let cond_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, body_bb, 0, 0, 0)

    self.push_control_target(self.ast.get_data2(node), ControlTargetKind.CT_LOOP, cond_bb, exit_bb, -1)

    self.switch_to(body_bb)
    let _ = self.lower_expr_discard(body_expr)
    self.terminate(TermKind.TK_GOTO, cond_bb, 0, 0, 0)

    self.switch_to(cond_bb)
    let cond_op = self.lower_expr(cond_expr)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cond_op, table, exit_bb, 0)

    self.pop_control_target()
    self.switch_to(exit_bb)
    self.forget_string_flow_facts()
    self.unit_operand()

fn MirBuilder.lower_for(self: MirBuilder, for_node: i32) -> i32:
    let pat_or_sym = self.ast.get_data0(for_node)
    let iter_expr = self.ast.get_data1(for_node)
    let body_expr = self.ast.get_data2(for_node)
    // Check for range-based for: for i in start..end
    if self.ast.kind(iter_expr) == NodeKind.NK_RANGE:
        return self.lower_for_range(for_node, pat_or_sym, iter_expr, body_expr)

    // Range variable: iter_expr is an ident/expr whose type is TY_RANGE
    let iter_ty = self.expr_type(iter_expr)
    if iter_ty != 0:
        let range_resolved = self.sema.resolve_alias(iter_ty)
        if self.sema.get_type_kind(range_resolved) == TypeKind.TY_RANGE:
            return self.lower_for_range_var(for_node, pat_or_sym, iter_expr, body_expr, range_resolved)

    // Check for slice/vec-based for
    if iter_ty != 0:
        let resolved = self.sema.resolve_alias(iter_ty)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_SLICE or tk == TypeKind.TY_ARRAY:
            return self.lower_for_slice(for_node, pat_or_sym, iter_expr, body_expr)
        // Vec[T] — use counter-based loop with VEC_LEN / VEC_GET intrinsics
        if tk == TypeKind.TY_GENERIC_INST:
            let type_name_sym = self.sema.get_type_name(resolved)
            if type_name_sym != 0:
                let type_name = self.pool.resolve(type_name_sym)
                if type_name == "Vec":
                    return self.lower_for_vec(for_node, pat_or_sym, iter_expr, body_expr)

    // Handle for x in vec.iter() — redirect to lower_for_vec with the Vec receiver.
    // Handle for slot in vec.iter_place() — redirect to lower_for_iter_place.
    if self.ast.kind(iter_expr) == NodeKind.NK_CALL:
        let call_callee = self.ast.get_data0(iter_expr)
        if self.ast.kind(call_callee) == NodeKind.NK_FIELD_ACCESS:
            let recv = self.ast.get_data0(call_callee)
            let msym = self.ast.get_data1(call_callee)
            let mname = self.pool.resolve(msym)
            if mname == "iter":
                let recv_ty = self.expr_type(recv)
                if recv_ty != 0:
                    let recv_resolved = self.sema.resolve_alias(recv_ty)
                    let recv_tk = self.sema.get_type_kind(recv_resolved)
                    if recv_tk == TypeKind.TY_GENERIC_INST:
                        let recv_name_sym = self.sema.get_type_name(recv_resolved)
                        if recv_name_sym != 0:
                            let recv_name = self.pool.resolve(recv_name_sym)
                            if recv_name == "Vec":
                                return self.lower_for_vec(for_node, pat_or_sym, recv, body_expr)
            if mname == "iter_ref":
                let ir_recv_ty = self.expr_type(recv)
                if ir_recv_ty != 0:
                    let ir_recv_resolved = self.sema.resolve_alias(ir_recv_ty)
                    let ir_recv_tk = self.sema.get_type_kind(ir_recv_resolved)
                    if ir_recv_tk == TypeKind.TY_GENERIC_INST:
                        let ir_recv_name_sym = self.sema.get_type_name(ir_recv_resolved)
                        if ir_recv_name_sym != 0:
                            let ir_recv_name = self.pool.resolve(ir_recv_name_sym)
                            if ir_recv_name == "Vec":
                                return self.lower_for_iter_ref(for_node, pat_or_sym, recv, body_expr)
            if mname == "iter_place":
                let ip_recv_ty = self.expr_type(recv)
                if ip_recv_ty != 0:
                    let ip_recv_resolved = self.sema.resolve_alias(ip_recv_ty)
                    let ip_recv_tk = self.sema.get_type_kind(ip_recv_resolved)
                    if ip_recv_tk == TypeKind.TY_GENERIC_INST:
                        let ip_recv_name_sym = self.sema.get_type_name(ip_recv_resolved)
                        if ip_recv_name_sym != 0:
                            let ip_recv_name = self.pool.resolve(ip_recv_name_sym)
                            if ip_recv_name == "Vec":
                                return self.lower_for_iter_place(for_node, pat_or_sym, recv, body_expr)

    // Generic iterator protocol: resolve next() on the iterator type.
    let next_sym = self.pool.intern("next")
    let callee_sym = self.resolve_method_callee_sym(iter_expr, next_sym)
    if callee_sym == next_sym:
        self.mark_unsupported()

    let iter_op = self.lower_expr(iter_expr)
    let iter_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    // Determine next()'s return type (Option[T]) from the method signature.
    let resolved_iter = self.sema.resolve_alias(iter_ty)
    let owner_sym = self.sema.method_owner_symbol_for_type(resolved_iter as i32)
    let sema_next_sym = self.sema.pool_lookup_symbol("next")
    var next_ret_ty = 0
    if owner_sym != 0 and sema_next_sym > 0:
        let sig_idx = self.sema.lookup_method_sig(owner_sym, sema_next_sym)
        if sig_idx >= 0:
            next_ret_ty = self.sema.sig_return_type(sig_idx)
    if next_ret_ty == 0:
        next_ret_ty = iter_ty

    let fn_op = self.const_operand(ConstKind.CK_FN, callee_sym, self.sema.ty_void)

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_control_target(self.for_label(for_node), ControlTargetKind.CT_LOOP, header_bb, exit_bb, -1)

    self.switch_to(header_bb)
    let next_args: Vec[i32] = Vec.new()
    next_args.push(self.body.new_operand(OperandKind.OK_COPY, iter_place))
    let args_id = self.body.new_call_args(next_args)
    let next_local = self.new_temp(next_ret_ty)
    let next_place = self.place_for_local(next_local)
    let after_next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, next_place, after_next_bb)

    self.switch_to(after_next_bb)
    let disc = self.lower_enum_discriminant(next_place)
    let some_idx = self.success_variant_index()
    let vals: Vec[i32] = Vec.new()
    vals.push(some_idx)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, exit_bb, 0)

    self.switch_to(body_bb)
    let item_local = self.new_temp(elem_ty)
    let item_place = self.place_for_local(item_local)
    let downcast_place = self.body.new_downcast_place(next_place, some_idx, next_ret_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, elem_ty)
    let next_payload = self.body.new_operand(OperandKind.OK_COPY, payload_place)
    self.assign_operand_to_place(item_place, next_payload, self.ast.get_start(iter_expr))

    self.bind_for_element(for_node, pat_or_sym, item_place, elem_ty, body_expr)

    let _ = self.lower_expr_discard(body_expr)
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_control_target()
    self.switch_to(exit_bb)
    self.forget_string_flow_facts()
    self.unit_operand()

fn MirBuilder.for_label(self: MirBuilder, for_node: i32) -> i32:
    let for_meta = self.ast.find_for_meta(for_node)
    if for_meta >= 0:
        return self.ast.for_meta_label(for_meta)
    0

fn MirBuilder.bind_for_element(self: MirBuilder, for_node: i32, pat_or_sym: i32, item_place: i32, elem_ty: i32, body_expr: i32):
    // Bind loop variable: supports both simple identifiers and pattern destructuring
    if self.ast.for_binding_is_pattern(for_node):
        let _ = self.lower_pattern(pat_or_sym, item_place)
        return
    if pat_or_sym != 0:
        let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
        self.bind_local(pat_or_sym, bind_local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, bind_local, 0, self.ast.get_start(body_expr))
        if self.sema.is_copy(elem_ty) == 0:
            self.schedule_drop(bind_local, DropKind.DK_VALUE)
        let bind_place = self.place_for_local(bind_local)
        let item_op = self.body.new_operand(OperandKind.OK_COPY, item_place)
        self.assign_operand_to_place(bind_place, item_op, self.ast.get_start(body_expr))

fn MirBuilder.bind_comprehension_element(self: MirBuilder, comp_node: i32, pat_or_sym: i32, item_place: i32, elem_ty: i32, span_node: i32):
    if self.ast.comprehension_binding_is_pattern(comp_node, pat_or_sym):
        let _ = self.lower_pattern(pat_or_sym, item_place)
        return
    if pat_or_sym != 0:
        let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
        self.bind_local(pat_or_sym, bind_local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, bind_local, 0, self.ast.get_start(span_node))
        if self.sema.is_copy(elem_ty) == 0:
            self.schedule_drop(bind_local, DropKind.DK_VALUE)
        let bind_place = self.place_for_local(bind_local)
        let item_op = self.body.new_operand(OperandKind.OK_COPY, item_place)
        self.assign_operand_to_place(bind_place, item_op, self.ast.get_start(span_node))

fn MirBuilder.lower_comprehension_leaf(self: MirBuilder, comp_node: i32, out_place: i32, out_elem_ty: i32):
    let expr = self.ast.get_data0(comp_node)
    let saved_expected = self.expected_type
    if out_elem_ty > 0 and out_elem_ty != self.sema.ty_void:
        self.expected_type = out_elem_ty
    let elem_op = self.lower_expr(expr)
    self.expected_type = saved_expected
    self.emit_vec_push(out_place, elem_op, self.ast.get_start(expr))

fn MirBuilder.lower_comprehension_next_or_push(self: MirBuilder, comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32):
    let clause_count = self.ast.get_data2(comp_node)
    if clause_index >= clause_count:
        self.lower_comprehension_leaf(comp_node, out_place, out_elem_ty)
        return
    self.lower_comprehension_clause(comp_node, clause_index, out_place, out_elem_ty)

fn MirBuilder.lower_comprehension_body(self: MirBuilder, comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, continue_bb: i32):
    let comp_start = self.ast.get_data1(comp_node)
    let filter = self.ast.get_extra(comp_start + clause_index * 3 + 2)
    if filter != 0:
        let pass_bb = self.new_block()
        let skip_bb = self.new_block()
        let cond_op = self.lower_expr(filter)
        let vals: Vec[i32] = Vec.new()
        vals.push(1)
        let targets: Vec[i32] = Vec.new()
        targets.push(pass_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, cond_op, table, skip_bb, 0)

        self.switch_to(pass_bb)
        self.lower_comprehension_next_or_push(comp_node, clause_index + 1, out_place, out_elem_ty)
        self.terminate(TermKind.TK_GOTO, continue_bb, 0, 0, 0)

        self.switch_to(skip_bb)
        self.terminate(TermKind.TK_GOTO, continue_bb, 0, 0, 0)
        return

    self.lower_comprehension_next_or_push(comp_node, clause_index + 1, out_place, out_elem_ty)
    self.terminate(TermKind.TK_GOTO, continue_bb, 0, 0, 0)

fn MirBuilder.lower_comprehension_range_var(self: MirBuilder, comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, iter_expr: i32, range_ty: i32):
    let elem_ty = self.sema.get_type_d0(range_ty)
    let range_op = self.lower_expr(iter_expr)
    let range_place = self.materialize_operand(range_op, range_ty, self.ast.get_start(iter_expr))

    let start_place = self.body.new_field_place(range_place, 0, elem_ty)
    let end_place_field = self.body.new_field_place(range_place, 1, elem_ty)

    let start_op = self.body.new_operand(OperandKind.OK_COPY, start_place)
    let end_op = self.body.new_operand(OperandKind.OK_COPY, end_place_field)

    let counter_local = self.new_temp(elem_ty)
    let counter_place = self.place_for_local(counter_local)
    self.assign_operand_to_place(counter_place, start_op, self.ast.get_start(iter_expr))

    let end_local = self.new_temp(elem_ty)
    let end_place = self.place_for_local(end_local)
    self.assign_operand_to_place(end_place, end_op, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.switch_to(header_bb)
    let counter_read = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let end_read = self.body.new_operand(OperandKind.OK_COPY, end_place)
    let inclusive = self.sema.get_type_d1(range_ty)
    let cmp_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, cmp_op, counter_read, end_read)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_result = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_result, table, exit_bb, 0)

    self.switch_to(body_bb)
    self.bind_comprehension_element(comp_node, pat_or_sym, counter_place, elem_ty, iter_expr)
    self.lower_comprehension_body(comp_node, clause_index, out_place, out_elem_ty, inc_bb)

    self.switch_to(inc_bb)
    let cur_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, elem_ty)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.switch_to(exit_bb)
    self.forget_string_flow_facts()

fn MirBuilder.lower_comprehension_range(self: MirBuilder, comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, range_node: i32):
    let start_node = self.ast.get_data0(range_node)
    let end_node = self.ast.get_data1(range_node)
    let inclusive = self.ast.get_data2(range_node)
    let elem_ty = self.sema.infer_for_element_type(self.expr_type(range_node))

    let start_op = if start_node != 0: self.lower_expr(start_node) else: self.int_const_operand(0, elem_ty)
    let end_op = self.lower_expr(end_node)

    let counter_local = self.new_temp(elem_ty)
    let counter_place = self.place_for_local(counter_local)
    let start_rv = self.body.new_rvalue(RvalueKind.RK_USE, start_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, start_rv, self.ast.get_start(range_node))

    let end_local = self.new_temp(elem_ty)
    let end_place = self.place_for_local(end_local)
    let end_rv = self.body.new_rvalue(RvalueKind.RK_USE, end_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, end_place, end_rv, self.ast.get_start(range_node))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let end_read_op = self.body.new_operand(OperandKind.OK_COPY, end_place)
    let cmp_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, cmp_op, counter_op, end_read_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(range_node))
    let cmp_result = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_result, table, exit_bb, 0)

    self.switch_to(body_bb)
    self.bind_comprehension_element(comp_node, pat_or_sym, counter_place, elem_ty, range_node)
    self.lower_comprehension_body(comp_node, clause_index, out_place, out_elem_ty, inc_bb)

    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, elem_ty)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(range_node))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.switch_to(exit_bb)
    self.forget_string_flow_facts()

fn MirBuilder.lower_comprehension_slice(self: MirBuilder, comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, iter_expr: i32):
    let iter_op = self.lower_expr(iter_expr)
    let iter_ty = self.expr_type(iter_expr)
    let elem_ty = self.sema.infer_for_element_type(iter_ty)
    let slice_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))

    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    let len_rv = self.body.new_rvalue(RvalueKind.RK_LEN, slice_place, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, len_place, len_rv, self.ast.get_start(iter_expr))

    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RvalueKind.RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, zero_rv, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let len_op = self.body.new_operand(OperandKind.OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_read = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_read, table, exit_bb, 0)

    self.switch_to(body_bb)
    let idx_place = self.body.new_index_place(slice_place, counter_local, 0)
    let elem_op = self.body.new_operand(OperandKind.OK_COPY, idx_place)
    let elem_local = self.new_temp(elem_ty)
    let elem_place = self.place_for_local(elem_local)
    self.assign_operand_to_place(elem_place, elem_op, self.ast.get_start(iter_expr))
    self.bind_comprehension_element(comp_node, pat_or_sym, elem_place, elem_ty, iter_expr)
    self.lower_comprehension_body(comp_node, clause_index, out_place, out_elem_ty, inc_bb)

    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.switch_to(exit_bb)
    self.forget_string_flow_facts()

fn MirBuilder.lower_comprehension_vec(self: MirBuilder, comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, iter_expr: i32):
    let iter_op = self.lower_expr(iter_expr)
    let iter_ty = self.expr_type(iter_expr)
    let elem_ty = self.sema.infer_for_element_type(iter_ty)
    let vec_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))

    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    self.emit_vec_len_into(vec_place, len_place, self.ast.get_start(iter_expr))

    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RvalueKind.RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, zero_rv, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let len_op = self.body.new_operand(OperandKind.OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_read = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_read, table, exit_bb, 0)

    self.switch_to(body_bb)
    let elem_local = self.new_temp(elem_ty)
    let elem_place = self.place_for_local(elem_local)
    self.emit_vec_get_into(vec_place, counter_place, elem_place, self.ast.get_start(iter_expr))
    self.bind_comprehension_element(comp_node, pat_or_sym, elem_place, elem_ty, iter_expr)
    self.lower_comprehension_body(comp_node, clause_index, out_place, out_elem_ty, inc_bb)

    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.switch_to(exit_bb)
    self.forget_string_flow_facts()

fn MirBuilder.lower_comprehension_generic_iter(self: MirBuilder, comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, iter_expr: i32, iter_ty: i32):
    let next_sym = self.pool.intern("next")
    let callee_sym = self.resolve_method_callee_sym(iter_expr, next_sym)
    if callee_sym == next_sym:
        self.mark_unsupported()
        return

    let iter_op = self.lower_expr(iter_expr)
    let iter_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    let resolved_iter = self.sema.resolve_alias(iter_ty)
    let owner_sym = self.sema.method_owner_symbol_for_type(resolved_iter as i32)
    let sema_next_sym = self.sema.pool_lookup_symbol("next")
    var next_ret_ty = 0
    if owner_sym != 0 and sema_next_sym > 0:
        let sig_idx = self.sema.lookup_method_sig(owner_sym, sema_next_sym)
        if sig_idx >= 0:
            next_ret_ty = self.sema.sig_return_type(sig_idx)
    if next_ret_ty == 0:
        next_ret_ty = iter_ty

    let fn_op = self.const_operand(ConstKind.CK_FN, callee_sym, self.sema.ty_void)
    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.switch_to(header_bb)
    let next_args: Vec[i32] = Vec.new()
    next_args.push(self.body.new_operand(OperandKind.OK_COPY, iter_place))
    let args_id = self.body.new_call_args(next_args)
    let next_local = self.new_temp(next_ret_ty)
    let next_place = self.place_for_local(next_local)
    let after_next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, next_place, after_next_bb)

    self.switch_to(after_next_bb)
    let disc = self.lower_enum_discriminant(next_place)
    let some_idx = self.success_variant_index()
    let vals: Vec[i32] = Vec.new()
    vals.push(some_idx)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, exit_bb, 0)

    self.switch_to(body_bb)
    let item_local = self.new_temp(elem_ty)
    let item_place = self.place_for_local(item_local)
    let downcast_place = self.body.new_downcast_place(next_place, some_idx, next_ret_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, elem_ty)
    let next_payload = self.body.new_operand(OperandKind.OK_COPY, payload_place)
    self.assign_operand_to_place(item_place, next_payload, self.ast.get_start(iter_expr))
    self.bind_comprehension_element(comp_node, pat_or_sym, item_place, elem_ty, iter_expr)
    self.lower_comprehension_body(comp_node, clause_index, out_place, out_elem_ty, header_bb)

    self.switch_to(exit_bb)
    self.forget_string_flow_facts()

fn MirBuilder.lower_comprehension_clause(self: MirBuilder, comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32):
    let comp_start = self.ast.get_data1(comp_node)
    let base = comp_start + clause_index * 3
    let pat_or_sym = self.ast.get_extra(base)
    let iter_expr = self.ast.get_extra(base + 1)

    if self.ast.kind(iter_expr) == NodeKind.NK_RANGE:
        self.lower_comprehension_range(comp_node, clause_index, out_place, out_elem_ty, pat_or_sym, iter_expr)
        return

    let iter_ty = self.expr_type(iter_expr)
    if iter_ty != 0:
        let range_resolved = self.sema.resolve_alias(iter_ty)
        if self.sema.get_type_kind(range_resolved) == TypeKind.TY_RANGE:
            self.lower_comprehension_range_var(comp_node, clause_index, out_place, out_elem_ty, pat_or_sym, iter_expr, range_resolved)
            return

        let resolved = self.sema.resolve_alias(iter_ty)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_SLICE or tk == TypeKind.TY_ARRAY:
            self.lower_comprehension_slice(comp_node, clause_index, out_place, out_elem_ty, pat_or_sym, iter_expr)
            return
        if tk == TypeKind.TY_GENERIC_INST:
            let type_name_sym = self.sema.get_type_name(resolved)
            if type_name_sym != 0:
                let type_name = self.pool.resolve(type_name_sym)
                if type_name == "Vec":
                    self.lower_comprehension_vec(comp_node, clause_index, out_place, out_elem_ty, pat_or_sym, iter_expr)
                    return

    if self.ast.kind(iter_expr) == NodeKind.NK_CALL:
        let call_callee = self.ast.get_data0(iter_expr)
        if self.ast.kind(call_callee) == NodeKind.NK_FIELD_ACCESS:
            let recv = self.ast.get_data0(call_callee)
            let msym = self.ast.get_data1(call_callee)
            let mname = self.pool.resolve(msym)
            if mname == "iter":
                let recv_ty = self.expr_type(recv)
                if recv_ty != 0:
                    let recv_resolved = self.sema.resolve_alias(recv_ty)
                    if self.sema.get_type_kind(recv_resolved) == TypeKind.TY_GENERIC_INST:
                        let recv_name_sym = self.sema.get_type_name(recv_resolved)
                        if recv_name_sym != 0 and self.pool.resolve(recv_name_sym) == "Vec":
                            self.lower_comprehension_vec(comp_node, clause_index, out_place, out_elem_ty, pat_or_sym, recv)
                            return

    self.lower_comprehension_generic_iter(comp_node, clause_index, out_place, out_elem_ty, pat_or_sym, iter_expr, iter_ty)

fn MirBuilder.lower_array_comprehension(self: MirBuilder, comp_node: i32) -> i32:
    var vec_ty = self.expr_type(comp_node)
    if vec_ty == 0 or vec_ty == self.sema.ty_void:
        self.mark_unsupported()
        return self.unit_operand()
    var elem_ty = self.generic_inst_arg_type(vec_ty, self.sema.syms.vec, 0)
    if elem_ty == 0:
        elem_ty = self.sema.ty_i32 as i32

    let vec_local = self.new_temp(vec_ty)
    let vec_place = self.place_for_local(vec_local)
    self.emit_vec_new_into(vec_place, self.ast.get_start(comp_node))
    self.lower_comprehension_clause(comp_node, 0, vec_place, elem_ty)

    if self.sema.is_copy(vec_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, vec_place)
    self.body.new_operand(OperandKind.OK_MOVE, vec_place)

fn MirBuilder.lower_for_range_var(self: MirBuilder, for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32, range_ty: i32) -> i32:
    // for i in range_var → extract start/end/inclusive from the range struct,
    // then generate the same counter-based loop as lower_for_range.
    // Range layout: {start: Elem, end: Elem, inclusive: i8}
    let elem_ty = self.sema.get_type_d0(range_ty)
    let range_op = self.lower_expr(iter_expr)
    let range_place = self.materialize_operand(range_op, range_ty, self.ast.get_start(iter_expr))

    // Extract fields via projection
    let start_place = self.body.new_field_place(range_place, 0, elem_ty)
    let end_place_field = self.body.new_field_place(range_place, 1, elem_ty)
    let incl_place = self.body.new_field_place(range_place, 2, self.sema.ty_bool)

    // Read start, end, inclusive into locals
    let start_op = self.body.new_operand(OperandKind.OK_COPY, start_place)
    let end_op = self.body.new_operand(OperandKind.OK_COPY, end_place_field)
    let incl_op = self.body.new_operand(OperandKind.OK_COPY, incl_place)

    // Counter = start
    let counter_local = self.new_temp(elem_ty)
    let counter_place = self.place_for_local(counter_local)
    self.assign_operand_to_place(counter_place, start_op, self.ast.get_start(iter_expr))

    // End value
    let end_local = self.new_temp(elem_ty)
    let end_place = self.place_for_local(end_local)
    self.assign_operand_to_place(end_place, end_op, self.ast.get_start(iter_expr))

    // Inclusive flag
    let incl_local = self.new_temp(self.sema.ty_bool)
    let incl_local_place = self.place_for_local(incl_local)
    self.assign_operand_to_place(incl_local_place, incl_op, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_control_target(self.for_label(for_node), ControlTargetKind.CT_LOOP, inc_bb, exit_bb, -1)

    // Header: compare counter < end (use LTE since we can't branch on inclusive at MIR level;
    // for simplicity, use LTE and rely on the sema-level inclusive flag from the range type)
    self.switch_to(header_bb)
    let counter_read = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let end_read = self.body.new_operand(OperandKind.OK_COPY, end_place)
    // Use the static inclusive flag from the range type
    let inclusive = self.sema.get_type_d1(range_ty)
    let cmp_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, cmp_op, counter_read, end_read)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_result = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_result, table, exit_bb, 0)

    // Body
    self.switch_to(body_bb)
    self.bind_for_element(for_node, pat_or_sym, counter_place, elem_ty, body_expr)
    let _ = self.lower_expr_discard(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

    // Increment
    self.switch_to(inc_bb)
    let cur_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, elem_ty)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_control_target()
    self.switch_to(exit_bb)
    self.forget_string_flow_facts()
    self.unit_operand()

fn MirBuilder.lower_for_range(self: MirBuilder, for_node: i32, pat_or_sym: i32, range_node: i32, body_expr: i32) -> i32:
    // for i in start..end  →  counter = start; while counter < end: body; counter += 1
    let start_node = self.ast.get_data0(range_node)
    let end_node = self.ast.get_data1(range_node)
    let inclusive = self.ast.get_data2(range_node)
    let elem_ty = self.sema.infer_for_element_type(self.expr_type(range_node))

    // Evaluate start and end
    let start_op = if start_node != 0: self.lower_expr(start_node) else: self.int_const_operand(0, elem_ty)
    let end_op = self.lower_expr(end_node)

    // Create counter local
    let counter_local = self.new_temp(elem_ty)
    let counter_place = self.place_for_local(counter_local)
    let start_rv = self.body.new_rvalue(RvalueKind.RK_USE, start_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, start_rv, self.ast.get_start(range_node))

    // Store end value in a temp
    let end_local = self.new_temp(elem_ty)
    let end_place = self.place_for_local(end_local)
    let end_rv = self.body.new_rvalue(RvalueKind.RK_USE, end_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, end_place, end_rv, self.ast.get_start(range_node))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_control_target(self.for_label(for_node), ControlTargetKind.CT_LOOP, inc_bb, exit_bb, -1)

    // Header: compare counter < end (or <=)
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let end_read_op = self.body.new_operand(OperandKind.OK_COPY, end_place)
    let cmp_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, cmp_op, counter_op, end_read_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(range_node))
    let cmp_result = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_result, table, exit_bb, 0)

    // Body: bind loop variable = counter, execute body
    self.switch_to(body_bb)
    self.bind_for_element(for_node, pat_or_sym, counter_place, elem_ty, body_expr)

    let _ = self.lower_expr_discard(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

    // Increment: counter = counter + 1, goto header
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, elem_ty)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(range_node))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_control_target()
    self.switch_to(exit_bb)
    self.forget_string_flow_facts()
    self.unit_operand()

fn MirBuilder.lower_for_slice(self: MirBuilder, for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
    // for x in slice → index from 0 to len
    let iter_op = self.lower_expr(iter_expr)
    let iter_ty = self.expr_type(iter_expr)
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    // Materialize slice into a local
    let slice_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))

    // Get length: len_local = RvalueKind.RK_LEN(slice_place)
    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    let len_rv = self.body.new_rvalue(RvalueKind.RK_LEN, slice_place, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, len_place, len_rv, self.ast.get_start(iter_expr))

    // Counter: i64 starting at 0
    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RvalueKind.RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, zero_rv, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_control_target(self.for_label(for_node), ControlTargetKind.CT_LOOP, inc_bb, exit_bb, -1)

    // Header: counter < len
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let len_op = self.body.new_operand(OperandKind.OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_read = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_read, table, exit_bb, 0)

    // Body: bind element = slice[counter]
    self.switch_to(body_bb)
    let idx_place = self.body.new_index_place(slice_place, counter_local, 0)
    let elem_op = self.body.new_operand(OperandKind.OK_COPY, idx_place)

    // Materialize element into a temp so pattern destructuring has a place to read from
    let elem_local = self.new_temp(elem_ty)
    let elem_place = self.place_for_local(elem_local)
    self.assign_operand_to_place(elem_place, elem_op, self.ast.get_start(body_expr))
    self.bind_for_element(for_node, pat_or_sym, elem_place, elem_ty, body_expr)

    let _ = self.lower_expr_discard(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

    // Increment: counter += 1
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_control_target()
    self.switch_to(exit_bb)
    self.forget_string_flow_facts()
    self.unit_operand()

fn MirBuilder.lower_for_vec(self: MirBuilder, for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
    // for x in vec → counter loop using VEC_LEN / VEC_GET intrinsics
    let iter_op = self.lower_expr(iter_expr)
    let iter_ty = self.expr_type(iter_expr)
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    // Materialize vec into a local
    let vec_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))

    // Get length via VEC_LEN intrinsic (returns i64)
    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    let len_args: Vec[i32] = Vec.new()
    len_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    let len_args_id = self.body.new_call_args(len_args)
    self.body.set_call_intrinsic(len_args_id, MirIntrinsic.VEC_LEN)
    let len_after_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), len_args_id, len_place, len_after_bb)
    self.switch_to(len_after_bb)

    // Counter: i64 starting at 0
    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RvalueKind.RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, zero_rv, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_control_target(self.for_label(for_node), ControlTargetKind.CT_LOOP, inc_bb, exit_bb, -1)

    // Header: counter < len
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let len_op = self.body.new_operand(OperandKind.OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_read = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_read, table, exit_bb, 0)

    // Body: elem = vec.get(counter) via VEC_GET intrinsic
    self.switch_to(body_bb)
    let elem_local = self.new_temp(elem_ty)
    let elem_place = self.place_for_local(elem_local)
    let get_args: Vec[i32] = Vec.new()
    get_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    get_args.push(self.body.new_operand(OperandKind.OK_COPY, counter_place))
    let get_args_id = self.body.new_call_args(get_args)
    self.body.set_call_intrinsic(get_args_id, MirIntrinsic.VEC_GET)
    let get_after_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), get_args_id, elem_place, get_after_bb)
    self.switch_to(get_after_bb)

    // Bind loop variable
    self.bind_for_element(for_node, pat_or_sym, elem_place, elem_ty, body_expr)

    let _ = self.lower_expr_discard(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

    // Increment: counter += 1
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_control_target()
    self.switch_to(exit_bb)
    self.forget_string_flow_facts()
    self.unit_operand()

fn MirBuilder.lower_for_iter_place(self: MirBuilder, for_node: i32, pat_or_sym: i32, vec_expr: i32, body_expr: i32) -> i32:
    let vec_op = self.lower_expr(vec_expr)
    let vec_ty = self.expr_type(vec_expr)
    let slot_ty = self.sema.infer_for_element_type(self.expr_type(self.ast.get_data1(for_node)))
    let vec_place = self.materialize_operand(vec_op, vec_ty, self.ast.get_start(vec_expr))
    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    let len_args: Vec[i32] = Vec.new()
    len_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    let len_args_id = self.body.new_call_args(len_args)
    self.body.set_call_intrinsic(len_args_id, MirIntrinsic.VEC_LEN)
    let len_after_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), len_args_id, len_place, len_after_bb)
    self.switch_to(len_after_bb)
    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RvalueKind.RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, zero_rv, self.ast.get_start(vec_expr))
    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_control_target(self.for_label(for_node), ControlTargetKind.CT_LOOP, inc_bb, exit_bb, -1)
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let len_op = self.body.new_operand(OperandKind.OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(vec_expr))
    let cmp_read = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_read, table, exit_bb, 0)
    self.switch_to(body_bb)
    let slot_local = self.new_temp(slot_ty)
    let slot_place = self.place_for_local(slot_local)
    let slot_args: Vec[i32] = Vec.new()
    slot_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    slot_args.push(self.body.new_operand(OperandKind.OK_COPY, counter_place))
    let slot_args_id = self.body.new_call_args(slot_args)
    self.body.set_call_intrinsic(slot_args_id, MirIntrinsic.VEC_SLOT)
    let slot_after_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), slot_args_id, slot_place, slot_after_bb)
    self.switch_to(slot_after_bb)
    self.bind_for_element(for_node, pat_or_sym, slot_place, slot_ty, body_expr)
    let _ = self.lower_expr_discard(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(vec_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.pop_control_target()
    self.switch_to(exit_bb)
    self.forget_string_flow_facts()
    self.unit_operand()

fn MirBuilder.lower_for_iter_ref(self: MirBuilder, for_node: i32, pat_or_sym: i32, vec_expr: i32, body_expr: i32) -> i32:
    let vec_op = self.lower_expr(vec_expr)
    let vec_ty = self.expr_type(vec_expr)
    let vec_place = self.materialize_operand(vec_op, vec_ty, self.ast.get_start(vec_expr))
    let resolved_vec = self.sema.resolve_alias(vec_ty)
    var ref_elem_ty = 0
    if self.sema.get_type_kind(resolved_vec) == TypeKind.TY_GENERIC_INST:
        let inner_ty = self.sema.get_generic_inst_arg(resolved_vec as i32, 0)
        ref_elem_ty = self.sema.ensure_exact_type(TypeKind.TY_REF, inner_ty, 0, 0) as i32
    if ref_elem_ty == 0:
        ref_elem_ty = self.sema.ty_i32 as i32
    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    let len_args: Vec[i32] = Vec.new()
    len_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    let len_args_id = self.body.new_call_args(len_args)
    self.body.set_call_intrinsic(len_args_id, MirIntrinsic.VEC_LEN)
    let len_after_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), len_args_id, len_place, len_after_bb)
    self.switch_to(len_after_bb)
    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RvalueKind.RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, zero_rv, self.ast.get_start(vec_expr))
    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_control_target(self.for_label(for_node), ControlTargetKind.CT_LOOP, inc_bb, exit_bb, -1)
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let len_op = self.body.new_operand(OperandKind.OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(vec_expr))
    let cmp_read = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_read, table, exit_bb, 0)
    self.switch_to(body_bb)
    let ref_local = self.new_temp(ref_elem_ty)
    let ref_place = self.place_for_local(ref_local)
    let ref_args: Vec[i32] = Vec.new()
    ref_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    ref_args.push(self.body.new_operand(OperandKind.OK_COPY, counter_place))
    let ref_args_id = self.body.new_call_args(ref_args)
    self.body.set_call_intrinsic(ref_args_id, MirIntrinsic.VEC_GET_REF)
    let ref_after_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), ref_args_id, ref_place, ref_after_bb)
    self.switch_to(ref_after_bb)
    self.bind_for_element(for_node, pat_or_sym, ref_place, ref_elem_ty, body_expr)
    let _ = self.lower_expr_discard(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(vec_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.pop_control_target()
    self.switch_to(exit_bb)
    self.forget_string_flow_facts()
    self.unit_operand()

fn MirBuilder.lower_break(self: MirBuilder, node: i32) -> i32:
    let loop_info = self.find_control_target(self.ast.get_data1(node), 0)
    if loop_info.break_bb < 0:
        return self.unit_operand()

    let value_expr = self.ast.get_data0(node)
    if value_expr != 0:
        let value_op = self.lower_expr(value_expr)
        if loop_info.result_place >= 0:
            self.assign_operand_to_place(loop_info.result_place, value_op, self.ast.get_start(value_expr))

    self.emit_cleanup_to_target(loop_info)
    self.terminate(TermKind.TK_GOTO, loop_info.break_bb, 0, 0, 0)

    // Continue lowering in a fresh detached block to keep pass total.
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_continue(self: MirBuilder, node: i32) -> i32:
    let loop_info = self.find_control_target(self.ast.get_data0(node), 1)
    if loop_info.continue_bb < 0:
        return self.unit_operand()

    self.emit_cleanup_to_target(loop_info)
    self.terminate(TermKind.TK_GOTO, loop_info.continue_bb, 0, 0, 0)
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_goto(self: MirBuilder, node: i32) -> i32:
    let label = self.ast.get_data0(node)
    let target = self.goto_target_info(label)
    if target.break_bb < 0:
        return self.unit_operand()
    self.emit_cleanup_to_target(target)
    self.terminate(TermKind.TK_GOTO, target.break_bb, 0, 0, 0)
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_label(self: MirBuilder, node: i32) -> i32:
    let label = self.ast.get_data0(node)
    let stmt = self.ast.get_data1(node)
    let _ = self.define_goto_label(label)
    if stmt == 0:
        return self.unit_operand()
    self.lower_expr(stmt)

fn MirBuilder.lower_return(self: MirBuilder, node: i32) -> i32:
    let value_expr = self.ast.get_data0(node)
    let saved_expected = self.expected_type
    let ret_ty = self.body.local_type_ids.get(0)
    if ret_ty > 0:
        self.expected_type = ret_ty
    if value_expr != 0:
        self.cancel_scheduled_value_drop_for_receiver_expr(value_expr)
    let ret_op = if value_expr != 0: self.lower_expr(value_expr) else: self.unit_operand()
    self.expected_type = saved_expected
    let ret_place = self.place_for_local(0)
    self.assign_operand_to_place(ret_place, ret_op, self.ast.get_start(node))

    self.emit_defers_for_return()
    self.emit_drops_for_return()
    self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

    // Keep lowering total by switching to an unreachable continuation block.
    self.switch_to(self.new_block())
    self.unit_operand()

// Await a single Task with cancellation checks and unwind-with-defers.
// Returns the operand for the unwrapped result value.
// task_op: MIR operand for the Task value
// result_ty: sema type of the unwrapped result (T from Task[T])
// task_ty: sema type of the Task value (Task[T])
// node: AST node for the await expression (for span/ast_node)
fn MirBuilder.lower_single_await(self: MirBuilder, task_op: i32, result_ty: i32, task_ty: i32, node: i32) -> i32:
    let span = self.ast.get_start(node)

    // 1. Emit FIBER_AWAIT intrinsic call
    let await_args: Vec[i32] = Vec.new()
    await_args.push(task_op)
    let await_args_id = self.body.new_call_args(await_args)
    self.body.set_call_intrinsic(await_args_id, MirIntrinsic.FIBER_AWAIT)
    self.body.set_call_ast_node(await_args_id, node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let after_await = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), await_args_id, result_place, after_await)
    self.switch_to(after_await)

    // 2. Check self-cancellation: IS_CANCELLED() → i32
    let ic_args: Vec[i32] = Vec.new()
    let ic_args_id = self.body.new_call_args(ic_args)
    self.body.set_call_intrinsic(ic_args_id, MirIntrinsic.FIBER_IS_CANCELLED)
    let ic_result = self.new_temp(self.sema.ty_i32 as i32)
    let ic_place = self.place_for_local(ic_result)
    let check_self_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), ic_args_id, ic_place, check_self_bb)
    self.switch_to(check_self_bb)

    // Branch: 0 → check child, else: → self-cancel cleanup
    let check_child_bb = self.new_block()
    let self_cancel_bb = self.new_block()
    let unwind_bb = self.new_block()
    let normal_bb = self.new_block()
    let sw_vals1: Vec[i32] = Vec.new()
    sw_vals1.push(0)
    let sw_tgts1: Vec[i32] = Vec.new()
    sw_tgts1.push(check_child_bb)
    let sw1 = self.body.new_switch_table(sw_vals1, sw_tgts1)
    let ic_op = self.body.new_operand(OperandKind.OK_COPY, ic_place)
    self.terminate(TermKind.TK_SWITCH_INT, ic_op, sw1, self_cancel_bb, 0)

    // 3. Self-cancel BB: cancel child, join it for cleanup, then unwind.
    self.switch_to(self_cancel_bb)
    let cancel_args: Vec[i32] = Vec.new()
    cancel_args.push(task_op)
    let cancel_call_id = self.body.new_call_args(cancel_args)
    self.body.set_call_intrinsic(cancel_call_id, MirIntrinsic.FIBER_CANCEL)
    self.body.set_call_ast_node(cancel_call_id, node)
    let cancel_result_local = self.new_temp(self.sema.ty_i32)
    let cancel_result_place = self.place_for_local(cancel_result_local)
    let after_cancel_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), cancel_call_id, cancel_result_place, after_cancel_bb)
    self.switch_to(after_cancel_bb)
    self.lower_cleanup_await(task_op, node)
    self.terminate(TermKind.TK_GOTO, unwind_bb, 0, 0, 0)

    // 4. Check child-cancellation: extract fiber_id from task
    self.switch_to(check_child_bb)
    let task_place = self.materialize_operand(task_op, task_ty, span)
    let fid_place = self.body.new_field_place(task_place, 0, self.sema.ty_i32 as i32)
    let fid_op = self.body.new_operand(OperandKind.OK_COPY, fid_place)
    let wcr_args: Vec[i32] = Vec.new()
    wcr_args.push(fid_op)
    let wcr_args_id = self.body.new_call_args(wcr_args)
    self.body.set_call_intrinsic(wcr_args_id, MirIntrinsic.FIBER_WAS_CANCELLED_RETURN)
    let wcr_result = self.new_temp(self.sema.ty_i32 as i32)
    let wcr_place = self.place_for_local(wcr_result)
    let check_child_cont = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), wcr_args_id, wcr_place, check_child_cont)
    self.switch_to(check_child_cont)

    // Branch: 0 → normal, else: → unwind
    let sw_vals2: Vec[i32] = Vec.new()
    sw_vals2.push(0)
    let sw_tgts2: Vec[i32] = Vec.new()
    sw_tgts2.push(normal_bb)
    let sw2 = self.body.new_switch_table(sw_vals2, sw_tgts2)
    let wcr_op = self.body.new_operand(OperandKind.OK_COPY, wcr_place)
    self.terminate(TermKind.TK_SWITCH_INT, wcr_op, sw2, unwind_bb, 0)

    // 5. Unwind BB: set cancelled_return, emit defers+drops, return
    self.switch_to(unwind_bb)
    let scr_args: Vec[i32] = Vec.new()
    let scr_args_id = self.body.new_call_args(scr_args)
    self.body.set_call_intrinsic(scr_args_id, MirIntrinsic.FIBER_SET_CANCELLED_RETURN)
    let scr_result = self.new_temp(self.sema.ty_i32 as i32)
    let scr_place = self.place_for_local(scr_result)
    let after_scr = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), scr_args_id, scr_place, after_scr)
    self.switch_to(after_scr)
    self.emit_defers_for_return()
    self.emit_drops_for_return()
    self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

    // 6. Normal BB: continue with result
    self.switch_to(normal_bb)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

// Join a Task purely for cleanup: await completion and free its result buffer,
// but do not propagate child-cancel status into the current fiber.
fn MirBuilder.lower_cleanup_await(self: MirBuilder, task_op: i32, node: i32):
    let await_args: Vec[i32] = Vec.new()
    await_args.push(task_op)
    let await_args_id = self.body.new_call_args(await_args)
    self.body.set_call_intrinsic(await_args_id, MirIntrinsic.FIBER_CLEANUP_AWAIT)
    self.body.set_call_ast_node(await_args_id, node)
    let ignored_local = self.new_temp(self.sema.ty_void as i32)
    let ignored_place = self.place_for_local(ignored_local)
    let after_await_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), await_args_id, ignored_place, after_await_bb)
    self.switch_to(after_await_bb)

fn MirBuilder.lower_unreachable(self: MirBuilder) -> i32:
    self.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_enum_discriminant(self: MirBuilder, place: i32) -> i32:
    let rv = self.body.new_rvalue(RvalueKind.RK_DISCRIMINANT, place, 0, 0)
    let disc_local = self.new_temp(self.sema.ty_i32)
    let disc_place = self.place_for_local(disc_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, disc_place, rv, 0)
    self.body.new_operand(OperandKind.OK_COPY, disc_place)

fn MirBuilder.lower_pattern_eq_operand(self: MirBuilder, scrutinee_place: i32, value_op: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
    let scrutinee_op = self.body.new_operand(OperandKind.OK_COPY, scrutinee_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_EQ, scrutinee_op, value_op)
    let cmp_tmp = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_tmp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(pat_node))
    let cmp_op = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(arm_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_op, table, fail_bb, 0)

fn MirBuilder.pattern_payload_node(self: MirBuilder, owner_pat: i32, payload_entry: i32) -> i32:
    if payload_entry <= 0 or payload_entry >= self.ast.node_count():
        return 0
    if not self.ast.is_pattern_node(payload_entry):
        return 0
    if payload_entry == owner_pat:
        return 0
    let owner_start = self.ast.get_start(owner_pat)
    let owner_end = self.ast.get_end(owner_pat)
    let payload_start = self.ast.get_start(payload_entry)
    let payload_end = self.ast.get_end(payload_entry)
    if payload_start < owner_start or payload_end > owner_end:
        return 0
    payload_entry

fn MirBuilder.pattern_subject_ref_mutability(self: MirBuilder, place: i32) -> i32:
    let ty = self.place_local_type(place)
    if ty == 0:
        return -1
    let resolved = self.sema.resolve_alias(ty as TypeId)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_REF:
        return -1
    self.sema.get_type_d1(resolved)

fn MirBuilder.pattern_shape_place(self: MirBuilder, place: i32) -> i32:
    if self.pattern_subject_ref_mutability(place) >= 0:
        return self.body.new_deref_place(place)
    place

fn MirBuilder.pattern_child_subject_place(self: MirBuilder, parent_place: i32, child_place: i32, span: i32) -> i32:
    let ref_mut = self.pattern_subject_ref_mutability(parent_place)
    if ref_mut < 0:
        return child_place
    let child_ty = self.place_local_type(child_place)
    if child_ty == 0 or child_ty == self.sema.ty_void as i32:
        return child_place
    let ref_ty = self.sema.ensure_exact_type(TypeKind.TY_REF, child_ty, ref_mut, 0) as i32
    let borrow_kind = if ref_mut != 0: BorrowKind.EXCLUSIVE else: BorrowKind.SHARED
    let ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, borrow_kind, child_place, 0)
    let ref_local = self.new_temp(ref_ty)
    let ref_place = self.place_for_local(ref_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, ref_place, ref_rv, span)
    ref_place

fn MirBuilder.lower_regex_pattern_match(self: MirBuilder, scrutinee_place: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
    let regex_ty = self.sema.lookup_named_type_visible(self.sema.syms.regex)
    let regex_val = self.lower_regex_literal(pat_node)
    let regex_place = self.materialize_operand(regex_val, regex_ty, self.ast.get_start(pat_node))
    let captures_opt_place = self.lower_regex_captures_places(regex_place, scrutinee_place)
    self.remember_regex_pattern_captures(pat_node, captures_opt_place)
    let result_op = self.lower_option_is_some_place(captures_opt_place, self.regex_captures_option_type())
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(arm_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, result_op, table, fail_bb, 0)

fn MirBuilder.lower_pattern_match(self: MirBuilder, scrutinee_place: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
    if pat_node == 0:
        self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    let pk = self.ast.kind(pat_node)
    if pk == NodeKind.NK_PAT_WILDCARD or pk == NodeKind.NK_PAT_IDENT:
        self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    if pk == NodeKind.NK_PAT_AT_BINDING:
        let inner_pat = self.ast.get_data1(pat_node)
        if inner_pat != 0:
            self.lower_pattern_match(scrutinee_place, inner_pat, arm_bb, fail_bb)
        else:
            self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    if pk == NodeKind.NK_PAT_OR:
        let p_start = self.ast.get_data0(pat_node)
        let p_count = self.ast.get_data1(pat_node)
        if p_count <= 0:
            self.terminate(TermKind.TK_GOTO, fail_bb, 0, 0, 0)
            return
        var next_test_bb = self.cur_bb
        for pi in 0..p_count:
            let alt_pat = self.ast.get_extra(p_start + pi)
            let alt_fail = if pi + 1 < p_count: self.new_block() else: fail_bb
            self.switch_to(next_test_bb)
            self.lower_pattern_match(scrutinee_place, alt_pat, arm_bb, alt_fail)
            next_test_bb = alt_fail
        return

    if pk == NodeKind.NK_PAT_VARIANT or pk == NodeKind.NK_PAT_ENUM_SHORTHAND:
        let variant_subject_place = self.pattern_shape_place(scrutinee_place)
        if self.sema.pattern_value_syms.contains(pat_node):
            let value_sym = self.sema.pattern_value_syms.get(pat_node).unwrap()
            let scrutinee_ty = self.place_local_type(variant_subject_place)
            let saved_expected = self.expected_type
            self.expected_type = scrutinee_ty
            let value_op = self.lower_var(value_sym, scrutinee_ty, 0)
            self.expected_type = saved_expected
            self.lower_pattern_eq_operand(variant_subject_place, value_op, pat_node, arm_bb, fail_bb)
            return
        let variant_sym = self.resolve_variant_sym(pat_node)
        let payload_start = self.ast.get_data1(pat_node)
        let payload_count = self.ast.get_data2(pat_node)
        let variant_idx = self.variant_index(variant_sym)
        var disc_idx = variant_idx
        // For disc enums, use the actual discriminant value
        if self.sema.variant_lookup.contains(variant_sym):
            if self.sema.disc_values.contains(variant_sym):
                disc_idx = self.sema.disc_values.get(variant_sym).unwrap()
        var success_bb = arm_bb
        var needs_payload_checks = false
        let variant_place = self.body.new_downcast_place(variant_subject_place, variant_idx, 0)
        for bi in 0..payload_count:
            let inner_pat = self.pattern_payload_node(pat_node, self.ast.get_extra(payload_start + bi))
            if inner_pat == 0:
                continue
            let inner_pk = self.ast.kind(inner_pat)
            if inner_pk == NodeKind.NK_PAT_WILDCARD or inner_pk == NodeKind.NK_PAT_IDENT or inner_pk == NodeKind.NK_PAT_REST:
                continue
            needs_payload_checks = true
            break
        if needs_payload_checks:
            success_bb = self.new_block() as i32
        let disc = self.lower_enum_discriminant(variant_subject_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(disc_idx)
        let targets: Vec[i32] = Vec.new()
        targets.push(success_bb)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, disc, table, fail_bb, 0)
        if not needs_payload_checks:
            return
        var cur_test_bb = success_bb
        for bi in 0..payload_count:
            let inner_pat = self.pattern_payload_node(pat_node, self.ast.get_extra(payload_start + bi))
            if inner_pat == 0:
                continue
            let inner_pk = self.ast.kind(inner_pat)
            if inner_pk == NodeKind.NK_PAT_WILDCARD or inner_pk == NodeKind.NK_PAT_IDENT or inner_pk == NodeKind.NK_PAT_REST:
                continue
            let field_place = self.body.new_field_place(variant_place, bi, 0)
            let next_test_bb = self.new_block()
            self.switch_to(cur_test_bb)
            self.lower_pattern_match(field_place, inner_pat, next_test_bb, fail_bb)
            cur_test_bb = next_test_bb as i32
        self.switch_to(cur_test_bb)
        self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    if pk == NodeKind.NK_PAT_REGEX:
        self.lower_regex_pattern_match(self.pattern_shape_place(scrutinee_place), pat_node, arm_bb, fail_bb)
        return

    let value_subject_place = self.pattern_shape_place(scrutinee_place)
    let scrutinee_op = self.body.new_operand(OperandKind.OK_COPY, value_subject_place)
    // Lower int-literal patterns at the scrutinee's type, not hardcoded i32.
    // Hardcoding i32 truncated values >= 2^31 (e.g. PCRE2's META_END = 0x80000000)
    // to negative i32, so the comparison against a u32 scrutinee always failed
    // and every meta-code match fell through to the default — surfacing as
    // ERR89 ("unknown code in parsed pattern") on every PCRE2 compile.
    let scrut_ty = self.place_local_type(value_subject_place)
    let pat_int_ty = if scrut_ty != 0 and scrut_ty != self.sema.ty_void as i32: scrut_ty else: self.sema.ty_i32
    if pk == NodeKind.NK_PAT_INT or pk == NodeKind.NK_PAT_BOOL or pk == NodeKind.NK_PAT_STRING:
        let lit = if pk == NodeKind.NK_PAT_INT:
            self.lower_int_lit(self.ast.int_lit_value(pat_node), pat_int_ty)
        else if pk == NodeKind.NK_PAT_BOOL:
            self.lower_bool_lit(self.ast.get_data0(pat_node))
        else:
            self.lower_str_lit(self.ast.get_data0(pat_node))
        self.lower_pattern_eq_operand(value_subject_place, lit, pat_node, arm_bb, fail_bb)
        return

    if pk == NodeKind.NK_PAT_RANGE:
        let range_lo = self.ast.get_data0(pat_node)
        let range_hi = self.ast.get_data1(pat_node)
        let inclusive = self.ast.get_data2(pat_node)
        let lo_lit = self.lower_int_lit(range_lo as i64, pat_int_ty)
        let hi_lit = self.lower_int_lit(range_hi as i64, pat_int_ty)
        let ge_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_GTE, scrutinee_op, lo_lit)
        let ge_tmp = self.new_temp(self.sema.ty_bool)
        let ge_place = self.place_for_local(ge_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, ge_place, ge_rv, self.ast.get_start(pat_node))
        let ge_op = self.body.new_operand(OperandKind.OK_COPY, ge_place)
        let range_hi_bb = self.new_block()
        let ge_vals: Vec[i32] = Vec.new()
        ge_vals.push(1)
        let ge_targets: Vec[i32] = Vec.new()
        ge_targets.push(range_hi_bb as i32)
        let ge_table = self.body.new_switch_table(ge_vals, ge_targets)
        self.terminate(TermKind.TK_SWITCH_INT, ge_op, ge_table, fail_bb, 0)
        self.switch_to(range_hi_bb)
        let scrutinee_op2 = self.body.new_operand(OperandKind.OK_COPY, value_subject_place)
        let hi_cmp_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
        let le_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, hi_cmp_op, scrutinee_op2, hi_lit)
        let le_tmp = self.new_temp(self.sema.ty_bool)
        let le_place = self.place_for_local(le_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, le_place, le_rv, self.ast.get_start(pat_node))
        let le_op = self.body.new_operand(OperandKind.OK_COPY, le_place)
        let le_vals: Vec[i32] = Vec.new()
        le_vals.push(1)
        let le_targets: Vec[i32] = Vec.new()
        le_targets.push(arm_bb)
        let le_table = self.body.new_switch_table(le_vals, le_targets)
        self.terminate(TermKind.TK_SWITCH_INT, le_op, le_table, fail_bb, 0)
        return

    if pk == NodeKind.NK_PAT_TUPLE:
        let tup_start = self.ast.get_data0(pat_node)
        let tup_count = self.ast.get_data1(pat_node)
        let tuple_subject_place = self.pattern_shape_place(scrutinee_place)
        let tuple_scrut_ty = self.place_local_type(tuple_subject_place)
        let tuple_scrut_resolved = self.sema.resolve_alias(tuple_scrut_ty)
        if self.sema.get_type_kind(tuple_scrut_resolved) != TypeKind.TY_TUPLE:
            with_eprint("error: tuple pattern reached MIR lowering with non-tuple subject")
            self.mark_unsupported()
            self.terminate(TermKind.TK_GOTO, fail_bb, 0, 0, 0)
            return
        let elem_start = self.sema.get_type_d0(tuple_scrut_resolved)
        let elem_count = self.sema.get_type_d1(tuple_scrut_resolved)
        if tup_count != elem_count:
            with_eprint("error: tuple pattern arity mismatch reached MIR lowering")
            self.mark_unsupported()
            self.terminate(TermKind.TK_GOTO, fail_bb, 0, 0, 0)
            return

        var cur_test_bb = self.cur_bb
        for ti in 0..tup_count:
            let elem_pat = self.ast.get_extra(tup_start + ti)
            let elem_pk = self.ast.kind(elem_pat)
            if elem_pk == NodeKind.NK_PAT_WILDCARD or elem_pk == NodeKind.NK_PAT_IDENT:
                continue
            let elem_ty = self.sema.type_extra.get((elem_start + ti) as i64)
            let elem_place = self.body.new_field_place(tuple_subject_place, ti, elem_ty)
            let next_test = self.new_block()
            self.switch_to(cur_test_bb)
            self.lower_pattern_match(elem_place, elem_pat, next_test, fail_bb)
            cur_test_bb = next_test
        // cur_test_bb is the block reached after all concrete checks pass.
        // Emit a goto to the arm block.
        self.switch_to(cur_test_bb)
        self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    // Dyn trait typed-bind pattern: vtable comparison via intrinsic.
    if pk == NodeKind.NK_PAT_TYPED_BIND:
        let tb_type_sym = self.ast.get_data1(pat_node)
        // Get trait_sym from scrutinee's sema type (TypeKind.TY_TRAIT_OBJ.d0)
        let tb_scrutinee_ty = self.place_local_type(scrutinee_place)
        var tb_trait_sym: i32 = 0
        if self.sema.get_type_kind(tb_scrutinee_ty) == TypeKind.TY_TRAIT_OBJ:
            tb_trait_sym = self.sema.get_type_d0(tb_scrutinee_ty)
        // Emit MirIntrinsic.DYN_VTABLE_CMP(scrutinee, type_sym, trait_sym) → bool
        let tb_fn_op = self.const_operand(ConstKind.CK_FN, 0, self.sema.ty_void)
        let tb_scrutinee_op = self.body.new_operand(OperandKind.OK_COPY, scrutinee_place)
        let tb_type_const = self.int_const_operand(tb_type_sym as i64, self.sema.ty_i32)
        let tb_trait_const = self.int_const_operand(tb_trait_sym as i64, self.sema.ty_i32)
        let tb_args: Vec[i32] = Vec.new()
        tb_args.push(tb_scrutinee_op)
        tb_args.push(tb_type_const)
        tb_args.push(tb_trait_const)
        let tb_args_id = self.body.new_call_args(tb_args)
        self.body.set_call_intrinsic(tb_args_id, MirIntrinsic.DYN_VTABLE_CMP)
        let tb_result = self.new_temp(self.sema.ty_bool)
        let tb_result_place = self.place_for_local(tb_result)
        let tb_switch_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, tb_fn_op, tb_args_id, tb_result_place, tb_switch_bb)
        self.switch_to(tb_switch_bb)
        let tb_cmp_op = self.body.new_operand(OperandKind.OK_COPY, tb_result_place)
        let tb_vals: Vec[i32] = Vec.new()
        tb_vals.push(1)
        let tb_targets: Vec[i32] = Vec.new()
        tb_targets.push(arm_bb)
        let tb_table = self.body.new_switch_table(tb_vals, tb_targets)
        self.terminate(TermKind.TK_SWITCH_INT, tb_cmp_op, tb_table, fail_bb, 0)
        return

    // NodeKind.NK_PAT_SLICE: check array length against pattern count
    if pk == NodeKind.NK_PAT_SLICE:
        let sp_head = self.ast.get_data1(pat_node)
        let sp_extra = self.ast.get_data0(pat_node)
        let sp_has_rest = self.ast.get_extra(sp_extra)
        // Get array length from scrutinee sema type
        let sp_arr_ty = self.place_local_type(scrutinee_place)
        let sp_arr_tk = self.sema.get_type_kind(sp_arr_ty)
        if sp_arr_tk == TypeKind.TY_ARRAY:
            let sp_arr_len = self.sema.get_type_d1(sp_arr_ty)
            if sp_has_rest != 0:
                // [a, b, ..rest] matches if arr_len >= head_count
                if sp_arr_len >= sp_head:
                    self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
                else:
                    self.terminate(TermKind.TK_GOTO, fail_bb, 0, 0, 0)
            else:
                // [a, b, c] matches only if arr_len == head_count
                if sp_arr_len == sp_head:
                    self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
                else:
                    self.terminate(TermKind.TK_GOTO, fail_bb, 0, 0, 0)
            return

    // Other patterns (struct) are conservatively accepted here.
    self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)

fn MirBuilder.lower_pattern(self: MirBuilder, pat_node: i32, scrutinee_place: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    if pat_node == 0:
        return out

    let pk = self.ast.kind(pat_node)
    if pk == NodeKind.NK_PAT_WILDCARD:
        return out

    if pk == NodeKind.NK_PAT_IDENT:
        let sym = self.ast.get_data0(pat_node)
        let bind_ty = self.place_local_type(scrutinee_place)
        let local_id = self.body.new_local(bind_ty, 0, sym, 1)
        self.bind_local(sym, local_id)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
        if self.sema.is_copy(bind_ty) == 0:
            self.schedule_drop(local_id, DropKind.DK_VALUE)
        let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, scrutinee_place)
        self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
        out.push(local_id)
        out.push(scrutinee_place)
        return out

    if pk == NodeKind.NK_PAT_AT_BINDING:
        let outer_sym = self.ast.get_data0(pat_node)
        let outer_ty = self.place_local_type(scrutinee_place)
        let outer_local = self.body.new_local(outer_ty, 0, outer_sym, 1)
        self.bind_local(outer_sym, outer_local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, outer_local, 0, self.ast.get_start(pat_node))
        if self.sema.is_copy(outer_ty) == 0:
            self.schedule_drop(outer_local, DropKind.DK_VALUE)
        let outer_op = self.body.new_operand(if self.sema.is_copy(outer_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, scrutinee_place)
        self.assign_operand_to_place(self.place_for_local(outer_local), outer_op, self.ast.get_start(pat_node))
        out.push(outer_local)
        out.push(scrutinee_place)
        let inner = self.lower_pattern(self.ast.get_data1(pat_node), scrutinee_place)
        for i in 0..inner.len() as i32:
            out.push(inner.get(i as i64))
        return out

    if pk == NodeKind.NK_PAT_VARIANT or pk == NodeKind.NK_PAT_ENUM_SHORTHAND:
        if self.sema.pattern_value_syms.contains(pat_node):
            return out
        let variant_sym = self.resolve_variant_sym(pat_node)
        let bind_start = self.ast.get_data1(pat_node)
        let bind_count = self.ast.get_data2(pat_node)
        let variant_subject_place = self.pattern_shape_place(scrutinee_place)
        let variant_place = self.body.new_downcast_place(variant_subject_place, self.variant_index(variant_sym), 0)
        for bi in 0..bind_count:
            let raw = self.ast.get_extra(bind_start + bi)
            let inner_pat = self.pattern_payload_node(pat_node, raw)
            if inner_pat != 0 and self.ast.kind(inner_pat) == NodeKind.NK_PAT_REST:
                continue
            let field_place = self.body.new_field_place(variant_place, bi, 0)
            let child_place = self.pattern_child_subject_place(scrutinee_place, field_place, self.ast.get_start(pat_node))
            if inner_pat != 0:
                let inner = self.lower_pattern(inner_pat, child_place)
                for i in 0..inner.len() as i32:
                    out.push(inner.get(i as i64))
                continue
            let bind_ty = self.place_local_type(child_place)
            let local_id = self.body.new_local(bind_ty, 0, raw, 1)
            self.bind_local(raw, local_id)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
            if self.sema.is_copy(bind_ty) == 0:
                self.schedule_drop(local_id, DropKind.DK_VALUE)
            let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, child_place)
            self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
            out.push(local_id)
            out.push(child_place)
        return out

    if pk == NodeKind.NK_PAT_TUPLE:
        let t_start = self.ast.get_data0(pat_node)
        let t_count = self.ast.get_data1(pat_node)
        let tuple_subject_place = self.pattern_shape_place(scrutinee_place)
        let tuple_bind_scrut_ty = self.place_local_type(tuple_subject_place)
        let tuple_bind_scrut_resolved = self.sema.resolve_alias(tuple_bind_scrut_ty)
        if self.sema.get_type_kind(tuple_bind_scrut_resolved) != TypeKind.TY_TUPLE:
            with_eprint("error: tuple pattern reached MIR binding lowering with non-tuple subject")
            self.mark_unsupported()
            return out
        let elem_start = self.sema.get_type_d0(tuple_bind_scrut_resolved)
        let elem_count = self.sema.get_type_d1(tuple_bind_scrut_resolved)
        if t_count != elem_count:
            with_eprint("error: tuple pattern arity mismatch reached MIR binding lowering")
            self.mark_unsupported()
            return out

        for ti in 0..t_count:
            let elem_pat = self.ast.get_extra(t_start + ti)
            let elem_ty = self.sema.type_extra.get((elem_start + ti) as i64)
            let field_place = self.body.new_field_place(tuple_subject_place, ti, elem_ty)
            let child_place = self.pattern_child_subject_place(scrutinee_place, field_place, self.ast.get_start(pat_node))
            let inner = self.lower_pattern(elem_pat, child_place)
            for i in 0..inner.len() as i32:
                out.push(inner.get(i as i64))
        return out

    if pk == NodeKind.NK_PAT_STRUCT:
        let s_start = self.ast.get_data1(pat_node)
        let s_count = self.ast.get_data2(pat_node)
        let struct_subject_place = self.pattern_shape_place(scrutinee_place)
        for si in 0..s_count:
            let field_name = self.ast.get_extra(s_start + 1 + si * 2)
            let field_pat = self.ast.get_extra(s_start + 1 + si * 2 + 1)
            let field_place = self.body.new_field_place(struct_subject_place, field_name, 0)
            let child_place = self.pattern_child_subject_place(scrutinee_place, field_place, self.ast.get_start(pat_node))
            if field_pat != 0:
                let inner = self.lower_pattern(field_pat, child_place)
                for i in 0..inner.len() as i32:
                    out.push(inner.get(i as i64))
            else:
                let bind_ty = self.place_local_type(child_place)
                let local_id = self.body.new_local(bind_ty, 0, field_name, 1)
                self.bind_local(field_name, local_id)
                self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
                if self.sema.is_copy(bind_ty) == 0:
                    self.schedule_drop(local_id, DropKind.DK_VALUE)
                let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, child_place)
                self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
                out.push(local_id)
                out.push(child_place)
        return out

    if pk == NodeKind.NK_PAT_OR:
        let p_start = self.ast.get_data0(pat_node)
        if self.ast.get_data1(pat_node) > 0:
            return self.lower_pattern(self.ast.get_extra(p_start), scrutinee_place)
        return out

    if pk == NodeKind.NK_PAT_REGEX:
        let captures_opt_place = self.lookup_regex_pattern_captures(pat_node)
        if captures_opt_place >= 0:
            self.lower_regex_capture_bindings_from_option(pat_node, captures_opt_place)
        return out

    if pk == NodeKind.NK_PAT_TYPED_BIND:
        let tb_bind_sym = self.ast.get_data0(pat_node)
        let tb_type_sym = self.ast.get_data1(pat_node)
        // Look up concrete sema type for the type symbol
        let tb_sema_sym = self.sema.pool_lookup_symbol(self.pool.resolve_symbol(tb_type_sym))
        var tb_concrete_ty = self.sema.ty_i32 as i32
        if self.sema.named_types.contains(tb_sema_sym):
            tb_concrete_ty = self.sema.named_types.get(tb_sema_sym).unwrap()
        // Emit MirIntrinsic.DYN_DOWNCAST(scrutinee, type_sym) → concrete value
        let dc_fn_op = self.const_operand(ConstKind.CK_FN, 0, self.sema.ty_void)
        let dc_scrutinee_op = self.body.new_operand(OperandKind.OK_COPY, scrutinee_place)
        let dc_type_const = self.int_const_operand(tb_type_sym as i64, self.sema.ty_i32)
        let dc_args: Vec[i32] = Vec.new()
        dc_args.push(dc_scrutinee_op)
        dc_args.push(dc_type_const)
        let dc_args_id = self.body.new_call_args(dc_args)
        self.body.set_call_intrinsic(dc_args_id, MirIntrinsic.DYN_DOWNCAST)
        let local_id = self.body.new_local(tb_concrete_ty, 0, tb_bind_sym, 1)
        self.bind_local(tb_bind_sym, local_id)
        let dc_result_place = self.place_for_local(local_id)
        let dc_next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, dc_fn_op, dc_args_id, dc_result_place, dc_next_bb)
        self.switch_to(dc_next_bb)
        out.push(local_id)
        out.push(scrutinee_place)
        return out

    if pk == NodeKind.NK_PAT_SLICE:
        let sp_extra = self.ast.get_data0(pat_node)
        let sp_head_count = self.ast.get_data1(pat_node)
        // Get element type from scrutinee's array type
        let sp_arr_ty = self.place_local_type(scrutinee_place)
        var sp_elem_ty = self.sema.ty_i32 as i32
        let sp_arr_tk = self.sema.get_type_kind(sp_arr_ty)
        if sp_arr_tk == TypeKind.TY_ARRAY:
            let ety = self.sema.get_type_d0(sp_arr_ty)
            if ety != 0:
                sp_elem_ty = ety
        // extras: [has_rest, head_sym0, head_sym1, ..., tail_count, tail_sym0, ...]
        let sp_arr_len = if sp_arr_tk == TypeKind.TY_ARRAY: self.sema.get_type_d1(sp_arr_ty) else: 0
        // Bind head variables
        for si in 0..sp_head_count:
            let sym = self.ast.get_extra(sp_extra + 1 + si)
            if sym == 0:
                continue
            let field_place = self.body.new_field_place(scrutinee_place, si, 0)
            let local_id = self.body.new_local(sp_elem_ty, 0, sym, 1)
            self.bind_local(sym, local_id)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
            let src_op = self.body.new_operand(if self.sema.is_copy(sp_elem_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, field_place)
            self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
            out.push(local_id)
            out.push(field_place)
        // Bind tail variables (from the end of the array)
        let sp_tail_count = self.ast.get_extra(sp_extra + 1 + sp_head_count)
        for ti in 0..sp_tail_count:
            let sym = self.ast.get_extra(sp_extra + 2 + sp_head_count + ti)
            if sym == 0:
                continue
            let field_idx = sp_arr_len - sp_tail_count + ti
            let field_place = self.body.new_field_place(scrutinee_place, field_idx, 0)
            let local_id = self.body.new_local(sp_elem_ty, 0, sym, 1)
            self.bind_local(sym, local_id)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
            let src_op = self.body.new_operand(if self.sema.is_copy(sp_elem_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, field_place)
            self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
            out.push(local_id)
            out.push(field_place)
        return out

    out

fn MirBuilder.lower_match(self: MirBuilder, scrutinee_expr: i32, arms_start: i32, arms_count: i32, node: i32) -> i32:
    if arms_count == 0:
        return self.unit_operand()

    let scrutinee_ty = self.expr_type(scrutinee_expr)
    let saved_scrutinee_expected = self.expected_type
    if scrutinee_ty != 0 and scrutinee_ty != self.sema.ty_void as i32:
        self.expected_type = scrutinee_ty
    else:
        self.expected_type = 0
    let scrutinee_op = self.lower_expr(scrutinee_expr)
    self.expected_type = saved_scrutinee_expected
    let scrutinee_place = self.materialize_operand(scrutinee_op, scrutinee_ty, self.ast.get_start(scrutinee_expr))

    let result_ty = self.expr_type(node)
    let result_is_void = if result_ty == 0 or result_ty == self.sema.ty_void as i32: 1 else: 0
    var result_place = -1
    if result_is_void == 0:
        let result_local = self.new_temp(result_ty)
        result_place = self.place_for_local(result_local)
    let join_bb = self.new_block()

    var dispatch_bb = self.cur_bb
    for ai in 0..arms_count:
        let arm_node = self.ast.get_extra(arms_start + ai)
        let pat_node = self.ast.get_data0(arm_node)
        let body_node = self.ast.get_data1(arm_node)
        let guard_node = self.ast.get_data2(arm_node)

        let arm_bb = self.new_block()
        let fail_bb = if ai + 1 < arms_count: self.new_block() else: join_bb

        self.switch_to(dispatch_bb)
        self.lower_pattern_match(scrutinee_place, pat_node, arm_bb, fail_bb)

        self.switch_to(arm_bb)
        let _ = self.lower_pattern(pat_node, scrutinee_place)

        if guard_node != 0:
            let guard_op = self.lower_expr(guard_node)
            let guard_pass_bb = self.new_block()
            let vals: Vec[i32] = Vec.new()
            vals.push(1)
            let targets: Vec[i32] = Vec.new()
            targets.push(guard_pass_bb as i32)
            let table = self.body.new_switch_table(vals, targets)
            self.terminate(TermKind.TK_SWITCH_INT, guard_op, table, fail_bb, 0)
            self.switch_to(guard_pass_bb)

        if result_is_void != 0:
            let _ = self.lower_expr_discard(body_node)
        else:
            let saved_arm_expected = self.expected_type
            if result_ty != 0:
                self.expected_type = result_ty
            let arm_value = self.lower_expr(body_node)
            self.expected_type = saved_arm_expected
            self.assign_operand_to_place(result_place, arm_value, self.ast.get_start(body_node))
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        dispatch_bb = fail_bb

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    if result_is_void != 0:
        return self.unit_operand()
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_call(self: MirBuilder, fn_expr: i32, arg_exprs_start: i32, arg_exprs_count: i32, ret_type_id: i32, node: i32) -> i32:
    let fn_op = self.lower_expr(fn_expr)
    let sig_idx = self.call_sig_for_expr(fn_expr)
    let callable_fn_tid = if sig_idx >= 0: 0 else: self.callable_fn_type_for_expr(fn_expr)

    let args: Vec[i32] = Vec.new()
    // Use sema-resolved arg order for named-arg and implicit-arg calls
    if self.sema.has_resolved_call_args(node) != 0:
        let resolved_count = self.sema.get_resolved_call_arg_count(node)
        for i in 0..resolved_count:
            let arg_node = self.sema.get_resolved_call_arg(node, i)
            if arg_node < 0:
                // Negative value = implicit parameter marker: 0 - bind_sym
                let impl_sym = 0 - arg_node
                args.push(self.lower_var(impl_sym, 0, 0))
            else if arg_node != 0:
                if self.sema.resolved_call_arg_is_default(node, i) != 0:
                    args.push(self.lower_default_call_arg(arg_node, node, sig_idx, callable_fn_tid, i))
                else:
                    args.push(self.lower_call_arg(arg_node, sig_idx, callable_fn_tid, i))
            else:
                args.push(self.unit_operand())
    else:
        for i in 0..arg_exprs_count:
            let arg_node = self.ast.get_extra(arg_exprs_start + i)
            args.push(self.lower_call_arg(arg_node, sig_idx, callable_fn_tid, i))

        // Fill in default parameter values for missing arguments
        if fn_expr != 0 and self.ast.kind(fn_expr) == NodeKind.NK_IDENT:
            let callee_sym = self.ast.get_data0(fn_expr)
            if self.sema.fn_decl_nodes.contains(callee_sym):
                let fn_node = self.sema.fn_decl_nodes.get(callee_sym).unwrap()
                let meta = self.ast.find_fn_meta(fn_node)
                if meta >= 0:
                    let param_start = self.ast.fn_meta_param_start(meta)
                    let param_count = self.ast.fn_meta_param_count(meta)
                    for di in arg_exprs_count..param_count:
                        let def_node = self.ast.get_fn_param_default(param_start, di)
                        if def_node != 0:
                            args.push(self.lower_default_call_arg(def_node, node, sig_idx, callable_fn_tid, di))

    let args_id = self.body.new_call_args(args)
    self.body.set_call_ast_node(args_id, node)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()

    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)

    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

// Callable type redirect: like lower_call but uses a pre-resolved fn operand and symbol.
fn MirBuilder.lower_call_redirected(self: MirBuilder, fn_op: i32, fn_sym: i32, arg_exprs_start: i32, arg_exprs_count: i32, ret_type_id: i32, node: i32) -> i32:
    let sig_idx = self.call_sig_for_sym(fn_sym)
    let args: Vec[i32] = Vec.new()
    for i in 0..arg_exprs_count:
        let arg_node = self.ast.get_extra(arg_exprs_start + i)
        args.push(self.lower_call_arg(arg_node, sig_idx, 0, i))
    let args_id = self.body.new_call_args(args)
    self.body.set_call_ast_node(args_id, node)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

// Like lower_call but takes arg node indices in a Vec instead of reading from
// pool.extra. This avoids mutating the shared AstPool (which would trigger
// Vec realloc and invalidate other copies' pointers — use-after-free).
fn MirBuilder.lower_call_with_arg_nodes(self: MirBuilder, fn_op: i32, callee_sym: i32, arg_node_vec: Vec[i32], ret_type_id: i32, node: i32) -> i32:
    let sig_idx = self.call_sig_for_sym(callee_sym)
    let args: Vec[i32] = Vec.new()
    for i in 0..arg_node_vec.len() as i32:
        args.push(self.lower_call_arg(arg_node_vec.get(i as i64), sig_idx, 0, i))
    let args_id = self.body.new_call_args(args)
    self.body.set_call_ast_node(args_id, node)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_std_drop_call(self: MirBuilder, node: i32) -> i32:
    let args_start = self.ast.get_data1(node)
    let arg_count = self.ast.get_data2(node)
    if arg_count != 1:
        return self.unit_operand()
    let arg_node = self.ast.get_extra(args_start)
    let place = self.lower_expr_place(arg_node)
    self.body.push_stmt(self.cur_bb, StmtKind.Drop, place, 0, self.ast.get_start(arg_node))
    let local_id = mir_place_plain_local(&self.body, place)
    if local_id >= 0:
        self.cancel_scheduled_value_drop_for_local(local_id)
    self.unit_operand()

fn MirBuilder.call_sig_for_sym(self: MirBuilder, sym: i32) -> i32:
    if sym == 0:
        return -1
    let direct = self.sema.get_sig(sym)
    if direct >= 0:
        return direct
    let name = self.pool.resolve_symbol(sym)
    if name.len() == 0:
        return -1
    let sema_sym = self.sema.pool_lookup_symbol(name)
    self.sema.get_sig(sema_sym)

fn MirBuilder.call_sig_for_expr(self: MirBuilder, fn_expr: i32) -> i32:
    if fn_expr == 0:
        return -1
    if self.ast.kind(fn_expr) != NodeKind.NK_IDENT:
        return -1
    self.call_sig_for_sym(self.ast.get_data0(fn_expr))

fn MirBuilder.callable_fn_type_for_expr(self: MirBuilder, fn_expr: i32) -> i32:
    if fn_expr == 0:
        return 0
    let expr_tid = self.expr_type(fn_expr)
    if expr_tid == 0:
        return 0
    self.sema.callable_any_fn_type(expr_tid as TypeId)

fn MirBuilder.lower_call_arg(self: MirBuilder, arg_node: i32, sig_idx: i32, callable_fn_tid: i32, arg_i: i32) -> i32:
    let saved_expected = self.expected_type
    var expected_ty = 0
    if sig_idx >= 0 and arg_i >= 0 and arg_i < self.sema.sig_get_param_count(sig_idx):
        expected_ty = self.sema.sig_param_type(sig_idx, arg_i)
        if expected_ty != 0 and expected_ty != self.sema.ty_void:
            self.expected_type = expected_ty
    else if callable_fn_tid != 0:
        expected_ty = self.sema.fn_type_param_type(callable_fn_tid, arg_i)
        if expected_ty != 0 and expected_ty != self.sema.ty_void:
            self.expected_type = expected_ty
    let autoref_op = self.lower_auto_ref_call_arg(arg_node, expected_ty)
    if autoref_op >= 0:
        self.expected_type = saved_expected
        return autoref_op
    let autoderef_op = self.lower_auto_deref_call_arg(arg_node, expected_ty)
    if autoderef_op >= 0:
        self.expected_type = saved_expected
        return autoderef_op
    let lowered = self.lower_expr(arg_node)
    self.expected_type = saved_expected
    lowered

fn MirBuilder.lower_method_arg_with_expected(self: MirBuilder, recv_type: i32, method_sym: i32, arg_node: i32, arg_index: i32) -> i32:
    let saved_expected = self.expected_type
    var expected_ty = 0
    if recv_type != 0:
        let resolved_recv = self.sema.auto_deref_ref_ptr_type(recv_type as TypeId) as i32
        expected_ty = self.sema.method_expected_arg_type(resolved_recv, method_sym, arg_index)
        if expected_ty != 0 and expected_ty != self.sema.ty_void as i32:
            self.expected_type = expected_ty
    let lowered = self.lower_expr(arg_node)
    self.expected_type = saved_expected
    lowered

fn MirBuilder.lower_auto_ref_call_arg(self: MirBuilder, arg_node: i32, expected_ty: i32) -> i32:
    if arg_node == 0 or expected_ty == 0:
        return -1
    let actual_ty = self.expr_type(arg_node)
    if actual_ty == 0:
        return -1
    if self.sema.can_auto_ref_arg(expected_ty, actual_ty) == 0:
        return -1
    let place = self.lower_expr_place(arg_node)
    let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, place, 0)
    let temp = self.new_temp(expected_ty)
    let temp_place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(arg_node))
    self.body.new_operand(OperandKind.OK_COPY, temp_place)

fn MirBuilder.lower_auto_deref_call_arg(self: MirBuilder, arg_node: i32, expected_ty: i32) -> i32:
    if arg_node == 0 or expected_ty == 0:
        return -1
    let expected_resolved = self.sema.resolve_alias(expected_ty as TypeId)
    let expected_kind = self.sema.get_type_kind(expected_resolved)
    if expected_kind != TypeKind.TY_REF and expected_kind != TypeKind.TY_PTR:
        return -1
    var current_ty = self.expr_type(arg_node)
    if current_ty == 0:
        return -1
    if self.sema.types_compatible(expected_ty, current_ty) != 0:
        return -1

    var deref_count = 0
    var depth = 0
    while current_ty > 0 and depth < 32:
        let current_resolved = self.sema.resolve_alias(current_ty as TypeId)
        let current_kind = self.sema.get_type_kind(current_resolved)
        if current_kind != TypeKind.TY_REF and current_kind != TypeKind.TY_PTR:
            break
        deref_count = deref_count + 1
        current_ty = self.sema.get_type_d0(current_resolved)
        if current_ty != 0 and self.sema.types_compatible(expected_ty, current_ty) != 0:
            var place = self.lower_expr_place(arg_node)
            for _ in 0..deref_count:
                place = self.body.new_deref_place(place)
            return self.body.new_operand(OperandKind.OK_COPY, place)
        depth = depth + 1
    -1

fn MirBuilder.lower_receiver_with_method_autoderef(self: MirBuilder, recv_node: i32) -> i32:
    var current_ty = self.expr_type(recv_node)
    if current_ty == 0:
        return self.lower_expr(recv_node)
    var deref_count = 0
    var depth = 0
    while current_ty > 0 and depth < 32:
        let current_resolved = self.sema.resolve_alias(current_ty as TypeId)
        let current_kind = self.sema.get_type_kind(current_resolved)
        if current_kind != TypeKind.TY_REF and current_kind != TypeKind.TY_PTR:
            break
        let inner_ty = self.sema.get_type_d0(current_resolved)
        if inner_ty == 0:
            break
        deref_count = deref_count + 1
        current_ty = inner_ty
        depth = depth + 1
    if deref_count == 0:
        return self.lower_expr(recv_node)
    var place = self.lower_expr_place(recv_node)
    for _ in 0..deref_count:
        place = self.body.new_deref_place(place)
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.resolve_method_callee_sym(self: MirBuilder, self_expr: i32, method_sym: i32) -> i32:
    // Translate method_sym from AST pool to sema pool for method lookups.
    let sema_method_sym = self.sema.pool_lookup_symbol(self.pool.resolve_symbol(method_sym))
    let obj_type = self.expr_type(self_expr)
    if obj_type != 0 and obj_type != self.sema.ty_void:
        let resolved = self.sema.auto_deref_ref_ptr_type(obj_type as TypeId)
        let type_name_sym = self.sema.method_owner_symbol_for_type(resolved as i32)
        if type_name_sym != 0:
            let method_fn = self.sema.lookup_method_fn(type_name_sym, sema_method_sym)
            if method_fn != 0 and self.sema.lookup_method_sig(type_name_sym, sema_method_sym) >= 0:
                return method_fn

    if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
        let type_sym = self.ast.get_data0(self_expr)
        let method_fn = self.sema.lookup_method_fn(type_sym, method_sym)
        if method_fn != 0 and self.sema.lookup_method_sig(type_sym, method_sym) >= 0:
            return method_fn

    // Handle Vec[i32].method() — receiver is NodeKind.NK_INDEX of a type name
    if self.ast.kind(self_expr) == NodeKind.NK_INDEX:
        let base = self.ast.get_data0(self_expr)
        if self.ast.kind(base) == NodeKind.NK_IDENT:
            let type_sym = self.ast.get_data0(base)
            let method_fn = self.sema.lookup_method_fn(type_sym, method_sym)
            if method_fn != 0 and self.sema.lookup_method_sig(type_sym, method_sym) >= 0:
                return method_fn

    method_sym

fn MirBuilder.receiver_is_static_type_expr(self: MirBuilder, expr: i32) -> i32:
    if expr == 0:
        return 0
    let kind = self.ast.kind(expr)
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(expr)
        if self.lookup_local(sym) < 0 and self.sema.named_types.contains(sym):
            return 1
    if kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_GENERIC or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_TUPLE or kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_EXTERN_FN or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        return 1
    if kind == NodeKind.NK_INDEX:
        return self.receiver_is_static_type_expr(self.ast.get_data0(expr))
    0

fn MirBuilder.lower_static_enum_variant_call(self: MirBuilder, enum_ty: i32, variant_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
    var result_ty = self.expr_type(node)
    if result_ty == 0 or result_ty == self.sema.ty_void:
        result_ty = enum_ty
    let payload_tys = self.sema.enum_variant_payload_types(result_ty, variant_sym)
    let has_resolved = self.sema.has_resolved_call_args(node)
    let count = if has_resolved != 0: self.sema.get_resolved_call_arg_count(node) else: arg_count
    let fields: Vec[i32] = Vec.new()
    let names: Vec[i32] = Vec.new()
    for i in 0..count:
        let arg_node = if has_resolved != 0: self.sema.get_resolved_call_arg(node, i) else: self.ast.get_extra(arg_start + i)
        let saved_expected = self.expected_type
        if i < payload_tys.len() as i32:
            let payload_ty = payload_tys.get(i as i64)
            if payload_ty != 0:
                self.expected_type = payload_ty
        fields.push(if arg_node == 0: self.unit_operand() else: self.lower_expr(arg_node))
        self.expected_type = saved_expected
        names.push(0)
    let fid = self.body.new_agg_fields(fields, names)
    let tag = self.enum_variant_discriminant_for_type(result_ty, variant_sym)
    let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fid, tag)
    let tmp = self.new_temp(result_ty)
    let place = self.place_for_local(tmp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.classify_intrinsic(self: MirBuilder, recv_type: i32, method_name: str) -> MirIntrinsic:
    if recv_type == 0 or method_name.len() == 0:
        return MirIntrinsic.NONE
    let resolved = self.sema.auto_deref_ref_ptr_type(recv_type as TypeId)
    // Check primitive types first (no type_name_sym for TypeKind.TY_STR, TypeKind.TY_INT, etc.)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_STR:
        let str_len_intrinsic = mir_len_method_intrinsic(MirIntrinsic.STR_LEN, method_name)
        if str_len_intrinsic != MirIntrinsic.NONE: return str_len_intrinsic
        if method_name == "byte_at": return MirIntrinsic.STR_BYTE_AT
        if method_name == "slice": return MirIntrinsic.STR_SLICE
        if method_name == "contains": return MirIntrinsic.STR_CONTAINS
        if method_name == "starts_with": return MirIntrinsic.STR_STARTS_WITH
        if method_name == "ends_with": return MirIntrinsic.STR_ENDS_WITH
        if method_name == "find": return MirIntrinsic.STR_FIND
        if method_name == "split": return MirIntrinsic.STR_SPLIT
        if method_name == "trim": return MirIntrinsic.STR_TRIM
        if method_name == "to_upper" or method_name == "upper": return MirIntrinsic.STR_TO_UPPER
        if method_name == "to_lower" or method_name == "lower": return MirIntrinsic.STR_TO_LOWER
        if method_name == "replace": return MirIntrinsic.STR_REPLACE
        if method_name == "index_of": return MirIntrinsic.STR_INDEX_OF
        if method_name == "repeat": return MirIntrinsic.STR_REPEAT
        return MirIntrinsic.NONE
    if tk == TypeKind.TY_ARRAY:
        let arr_len_intrinsic = mir_len_method_intrinsic(MirIntrinsic.ARR_LEN, method_name)
        if arr_len_intrinsic != MirIntrinsic.NONE: return arr_len_intrinsic
        return MirIntrinsic.NONE
    if tk == TypeKind.TY_INT:
        if method_name == "rotate_left": return MirIntrinsic.ROTATE_LEFT
        if method_name == "rotate_right": return MirIntrinsic.ROTATE_RIGHT
        if method_name == "swap_bytes": return MirIntrinsic.INT_SWAP_BYTES
        if method_name == "popcount": return MirIntrinsic.POPCOUNT
        if method_name == "clz": return MirIntrinsic.CLZ
        if method_name == "ctz": return MirIntrinsic.CTZ
        if method_name == "bitreverse": return MirIntrinsic.BITREVERSE
        if method_name == "min": return MirIntrinsic.MIN
        if method_name == "max": return MirIntrinsic.MAX
        if method_name == "abs": return MirIntrinsic.ABS
    if tk == TypeKind.TY_FLOAT:
        if method_name == "min": return MirIntrinsic.MIN
        if method_name == "max": return MirIntrinsic.MAX
        if method_name == "abs": return MirIntrinsic.ABS
        if method_name == "mul_add": return MirIntrinsic.FMA
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym == 0:
        return MirIntrinsic.NONE
    let type_name = self.pool.resolve_symbol(type_name_sym)
    if type_name == "Vec":
        if method_name == "new": return MirIntrinsic.VEC_NEW
        if method_name == "with_capacity": return MirIntrinsic.VEC_WITH_CAPACITY
        if method_name == "push": return MirIntrinsic.VEC_PUSH
        if method_name == "get": return MirIntrinsic.VEC_GET
        let vec_len_intrinsic = mir_len_method_intrinsic(MirIntrinsic.VEC_LEN, method_name)
        if vec_len_intrinsic != MirIntrinsic.NONE: return vec_len_intrinsic
        if method_name == "set_i32": return MirIntrinsic.VEC_SET
        if method_name == "remove": return MirIntrinsic.VEC_REMOVE
        if method_name == "clear": return MirIntrinsic.VEC_CLEAR
        if method_name == "pop": return MirIntrinsic.VEC_POP
        if method_name == "iter": return MirIntrinsic.VEC_ITER
        if method_name == "iter_ref": return MirIntrinsic.VEC_ITER_REF
        if method_name == "slot": return MirIntrinsic.VEC_SLOT
        if method_name == "get_disjoint": return MirIntrinsic.VEC_GET_DISJOINT
        if method_name == "range": return MirIntrinsic.VEC_RANGE
        if method_name == "iter_place": return MirIntrinsic.VEC_ITER_PLACE
        if method_name == "map": return MirIntrinsic.VEC_MAP
        if method_name == "filter": return MirIntrinsic.VEC_FILTER
        if method_name == "fold": return MirIntrinsic.VEC_FOLD
        if method_name == "contains": return MirIntrinsic.VEC_CONTAINS
        if method_name == "join": return MirIntrinsic.VEC_JOIN
        return MirIntrinsic.NONE
    if type_name == "VecIter" or type_name == "VecIterRef":
        if method_name == "next":
            if type_name == "VecIterRef": return MirIntrinsic.VECITERREF_NEXT
            return MirIntrinsic.VECITER_NEXT
        if method_name == "map": return MirIntrinsic.ITER_MAP
        if method_name == "filter": return MirIntrinsic.ITER_FILTER
        if method_name == "take": return MirIntrinsic.ITER_TAKE
        if method_name == "zip": return MirIntrinsic.ITER_ZIP
        if method_name == "flat_map": return MirIntrinsic.ITER_FLAT_MAP
        if method_name == "fold": return MirIntrinsic.ITER_FOLD
        if method_name == "reduce": return MirIntrinsic.ITER_REDUCE
        if method_name == "sum": return MirIntrinsic.ITER_SUM
        if method_name == "count": return MirIntrinsic.ITER_COUNT
        if method_name == "collect": return MirIntrinsic.ITER_COLLECT_VEC
        if method_name == "partition": return MirIntrinsic.ITER_PARTITION
        return MirIntrinsic.NONE
    if type_name == "MapIter" or type_name == "FilterIter" or type_name == "TakeIter" or type_name == "ZipIter" or type_name == "FlatMapIter":
        if method_name == "next":
            if type_name == "MapIter": return MirIntrinsic.MAPITER_NEXT
            if type_name == "FilterIter": return MirIntrinsic.FILTERITER_NEXT
            if type_name == "TakeIter": return MirIntrinsic.TAKEITER_NEXT
            if type_name == "ZipIter": return MirIntrinsic.ZIPITER_NEXT
            if type_name == "FlatMapIter": return MirIntrinsic.FLATMAPITER_NEXT
        if method_name == "map": return MirIntrinsic.ITER_MAP
        if method_name == "filter": return MirIntrinsic.ITER_FILTER
        if method_name == "take": return MirIntrinsic.ITER_TAKE
        if method_name == "zip": return MirIntrinsic.ITER_ZIP
        if method_name == "flat_map": return MirIntrinsic.ITER_FLAT_MAP
        if method_name == "fold": return MirIntrinsic.ITER_FOLD
        if method_name == "reduce": return MirIntrinsic.ITER_REDUCE
        if method_name == "sum": return MirIntrinsic.ITER_SUM
        if method_name == "count": return MirIntrinsic.ITER_COUNT
        if method_name == "collect": return MirIntrinsic.ITER_COLLECT_VEC
        if method_name == "partition": return MirIntrinsic.ITER_PARTITION
        return MirIntrinsic.NONE
    if type_name == "VecSlot":
        if method_name == "get": return MirIntrinsic.VECSLOT_GET
        if method_name == "set": return MirIntrinsic.VECSLOT_SET
        return MirIntrinsic.NONE
    if type_name == "SlotMap":
        if method_name == "new": return MirIntrinsic.SLOTMAP_NEW
        if method_name == "insert": return MirIntrinsic.SLOTMAP_INSERT
        if method_name == "get": return MirIntrinsic.SLOTMAP_GET
        if method_name == "slot": return MirIntrinsic.SLOTMAP_SLOT
        if method_name == "remove": return MirIntrinsic.SLOTMAP_REMOVE
        if method_name == "replace": return MirIntrinsic.SLOTMAP_REPLACE
        if method_name == "contains": return MirIntrinsic.SLOTMAP_CONTAINS
        let slotmap_len_intrinsic = mir_len_method_intrinsic(MirIntrinsic.SLOTMAP_LEN, method_name)
        if slotmap_len_intrinsic != MirIntrinsic.NONE: return slotmap_len_intrinsic
        if method_name == "get_disjoint": return MirIntrinsic.SLOTMAP_GET_DISJOINT
        return MirIntrinsic.NONE
    if type_name == "SlotMapSlot":
        if method_name == "get": return MirIntrinsic.SLOTMAPSLOT_GET
        if method_name == "set": return MirIntrinsic.SLOTMAPSLOT_SET
        return MirIntrinsic.NONE
    if type_name == "VecRange":
        if method_name == "get": return MirIntrinsic.VECRANGE_GET
        if method_name == "set": return MirIntrinsic.VECRANGE_SET
        let vecrange_len_intrinsic = mir_len_method_intrinsic(MirIntrinsic.VECRANGE_LEN, method_name)
        if vecrange_len_intrinsic != MirIntrinsic.NONE: return vecrange_len_intrinsic
        return MirIntrinsic.NONE
    if type_name == "VecIterPlace":
        if method_name == "next": return MirIntrinsic.VECITERPLACE_NEXT
        return MirIntrinsic.NONE
    if type_name == "HashMap":
        if method_name == "new": return MirIntrinsic.MAP_NEW
        if method_name == "insert": return MirIntrinsic.MAP_INSERT
        if method_name == "get": return MirIntrinsic.MAP_GET
        if method_name == "contains": return MirIntrinsic.MAP_CONTAINS
        let map_len_intrinsic = mir_len_method_intrinsic(MirIntrinsic.MAP_LEN, method_name)
        if map_len_intrinsic != MirIntrinsic.NONE: return map_len_intrinsic
        if method_name == "remove": return MirIntrinsic.MAP_REMOVE
        if method_name == "clear": return MirIntrinsic.MAP_CLEAR
        if method_name == "increment": return MirIntrinsic.MAP_INCREMENT
        if method_name == "decrement": return MirIntrinsic.MAP_DECREMENT
        if method_name == "update": return MirIntrinsic.MAP_UPDATE
        if method_name == "keys": return MirIntrinsic.MAP_KEYS
        if method_name == "entry": return MirIntrinsic.MAP_ENTRY
        return MirIntrinsic.NONE
    if type_name == "HashMapEntry":
        if method_name == "or_insert": return MirIntrinsic.ENTRY_OR_INSERT
        if method_name == "get": return MirIntrinsic.ENTRY_GET
        if method_name == "set": return MirIntrinsic.ENTRY_SET
        return MirIntrinsic.NONE
    if type_name == "HashSet":
        if method_name == "new": return MirIntrinsic.MAP_NEW
        if method_name == "insert": return MirIntrinsic.MAP_INSERT
        if method_name == "contains": return MirIntrinsic.MAP_CONTAINS
        let set_len_intrinsic = mir_len_method_intrinsic(MirIntrinsic.MAP_LEN, method_name)
        if set_len_intrinsic != MirIntrinsic.NONE: return set_len_intrinsic
        if method_name == "remove": return MirIntrinsic.MAP_REMOVE
        if method_name == "clear": return MirIntrinsic.MAP_CLEAR
        return MirIntrinsic.NONE
    if type_name == "Option":
        if method_name == "is_some": return MirIntrinsic.OPT_IS_SOME
        if method_name == "is_none": return MirIntrinsic.OPT_IS_NONE
        if method_name == "unwrap": return MirIntrinsic.OPT_UNWRAP
        if method_name == "filter": return MirIntrinsic.OPT_FILTER
        return MirIntrinsic.NONE
    if type_name == "Result":
        if method_name == "is_ok": return MirIntrinsic.OPT_IS_SOME
        if method_name == "unwrap": return MirIntrinsic.OPT_UNWRAP
        return MirIntrinsic.NONE
    if type_name == "Atomic":
        if method_name == "load": return MirIntrinsic.ATOMIC_LOAD
        if method_name == "store": return MirIntrinsic.ATOMIC_STORE
        if method_name == "swap": return MirIntrinsic.ATOMIC_SWAP
        if method_name == "fetch_add": return MirIntrinsic.ATOMIC_FETCH_ADD
        if method_name == "fetch_sub": return MirIntrinsic.ATOMIC_FETCH_SUB
        if method_name == "fetch_and": return MirIntrinsic.ATOMIC_FETCH_AND
        if method_name == "fetch_or": return MirIntrinsic.ATOMIC_FETCH_OR
        if method_name == "fetch_xor": return MirIntrinsic.ATOMIC_FETCH_XOR
        if method_name == "fetch_min": return MirIntrinsic.ATOMIC_FETCH_MIN
        if method_name == "fetch_max": return MirIntrinsic.ATOMIC_FETCH_MAX
        if method_name == "compare_exchange": return MirIntrinsic.ATOMIC_CAS
        if method_name == "compare_exchange_weak": return MirIntrinsic.ATOMIC_CAS_WEAK
        return MirIntrinsic.NONE
    MirIntrinsic.NONE

fn MirBuilder.receiver_option_intrinsic(self: MirBuilder, recv_expr: i32) -> MirIntrinsic:
    // Check if recv_expr is a call to an intrinsic method that returns Option.
    // Used to classify chained .unwrap()/.is_some() when the receiver type is void.
    if self.ast.kind(recv_expr) != NodeKind.NK_CALL:
        return MirIntrinsic.NONE
    let callee = self.ast.get_data0(recv_expr)
    if self.ast.kind(callee) != NodeKind.NK_FIELD_ACCESS:
        return MirIntrinsic.NONE
    let base = self.ast.get_data0(callee)
    let method_sym = self.ast.get_data1(callee)
    let base_ty = self.expr_type(base)
    if base_ty == 0 or base_ty == self.sema.ty_void:
        return MirIntrinsic.NONE
    let method_name = self.pool.resolve_symbol(method_sym)
    let resolved = self.sema.resolve_alias(base_ty)
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym == 0:
        return MirIntrinsic.NONE
    let type_name = self.pool.resolve_symbol(type_name_sym)
    // HashMap.get and SlotMap.get return Option-wrapped values.
    if type_name == "HashMap":
        if method_name == "get": return MirIntrinsic.MAP_GET
    if type_name == "HashSet":
        if method_name == "contains": return MirIntrinsic.MAP_CONTAINS
    if type_name == "SlotMap":
        if method_name == "get": return MirIntrinsic.SLOTMAP_GET
    MirIntrinsic.NONE

fn MirBuilder.lower_method_call(self: MirBuilder, self_expr: i32, method_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
    // Lower method calls as normal calls with receiver inserted as first arg.
    var callee_sym = if self.sema.comp_resolved.contains(node):
        self.sema.comp_resolved.get(node).unwrap()
    else:
        self.resolve_method_callee_sym(self_expr, method_sym)

    // Classify intrinsic early — needed to decide whether to mark_unsupported.
    // For instance methods (vec.push), recv_type comes from the receiver expression.
    // For static calls (Vec.new), the receiver is a type ident — use its symbol to
    // look up the type name, and fall back to the call's return type.
    var recv_type = self.expr_type(self_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        recv_type = self.type_receiver_type(self_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        // Fall back to call's return type for static constructors (Vec.new())
        let ret_type = self.expr_type(node)
        let ret_name_sym = self.sema.get_type_name(ret_type)
        if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
            let type_sym = self.ast.get_data0(self_expr)
            if ret_name_sym == type_sym:
                recv_type = ret_type
    let method_name = self.pool.resolve_symbol(method_sym)
    if method_name == "as_option":
        let resolved_recv = self.sema.resolve_alias(recv_type as TypeId)
        if self.sema.get_type_kind(resolved_recv) == TypeKind.TY_PTR:
            return self.lower_expr(self_expr)
    if method_name == "join" and self.sema.type_is_scoped_join_handle(recv_type) != 0:
        callee_sym = method_sym
    if self.receiver_is_static_type_expr(self_expr) != 0 and recv_type != 0 and self.sema.enum_has_variant(recv_type, method_sym) != 0:
        return self.lower_static_enum_variant_call(recv_type, method_sym, arg_start, arg_count, node)
    let enum_accessor_recv_type = if recv_type != 0 and recv_type != self.sema.ty_void as i32: self.sema.auto_deref_ref_ptr_type(recv_type as TypeId) as i32 else: recv_type
    let enum_accessor_variant = self.sema.enum_accessor_variant_for_method(enum_accessor_recv_type, method_sym)
    if enum_accessor_variant != 0:
        return self.lower_enum_accessor_call(self_expr, method_sym, node)

    if self.is_option_type(enum_accessor_recv_type) != 0 and (method_name == "map" or method_name == "and_then"):
        return self.lower_option_combinator_method(self_expr, method_name, arg_start, arg_count, node)

    if self.is_result_type(enum_accessor_recv_type) != 0 and (method_name == "map" or method_name == "map_err" or method_name == "context" or method_name == "with_context"):
        return self.lower_result_combinator_method(self_expr, method_name, arg_start, arg_count, node)

    if self.is_option_type(enum_accessor_recv_type) != 0 and method_name == "transpose":
        return self.lower_option_transpose_method(self_expr, arg_count, node)

    if self.is_result_type(enum_accessor_recv_type) != 0 and method_name == "transpose":
        return self.lower_result_transpose_method(self_expr, arg_count, node)

    if self.is_vec_type(enum_accessor_recv_type) != 0 and (method_name == "sequence" or method_name == "traverse"):
        return self.lower_vec_sequence_or_traverse_method(self_expr, method_name, arg_start, arg_count, node)

    if method_name == "unwrap_or" and self.is_option_or_result_type(enum_accessor_recv_type) != 0:
        return self.lower_unwrap_or_method(self_expr, arg_start, arg_count, node)

    var intrinsic = self.classify_intrinsic(recv_type, method_name)

    // When classify_intrinsic fails for "unwrap"/"is_some", handle as Option
    // intrinsic. Sema's type system returns the raw value type for HashMap.get
    // (e.g., i32 instead of Option[i32]), so classify_intrinsic can't match Option.
    // Two fallbacks:
    // 1. Receiver is a direct call to HashMap.get/Vec.get (chained: map.get(k).unwrap())
    // 2. No sig exists for this method on the receiver type (let x = map.get(k); x.unwrap())
    if intrinsic == MirIntrinsic.NONE:
        if method_name == "unwrap" or method_name == "is_some" or method_name == "is_none":
            var is_option_method = false
            let recv_intr = self.receiver_option_intrinsic(self_expr)
            if recv_intr != MirIntrinsic.NONE:
                is_option_method = true
            else if callee_sym == method_sym:
                // Unresolved method — no sig found for unwrap/is_some/is_none on the receiver type.
                // User-defined types with these names would have a sig. This is an Option intrinsic.
                is_option_method = true
            if is_option_method:
                if method_name == "unwrap":
                    intrinsic = MirIntrinsic.OPT_UNWRAP
                else if method_name == "is_none":
                    intrinsic = MirIntrinsic.OPT_IS_NONE
                else:
                    intrinsic = MirIntrinsic.OPT_IS_SOME

    // For intrinsic calls (Vec/HashMap/Option), bypass lower_call entirely.
    // lower_call → lower_var would mark_unsupported on the bare method sym.
    // Instead, emit the call terminator directly with an intrinsic tag.
    if intrinsic != MirIntrinsic.NONE:
        return self.lower_intrinsic_call(intrinsic, self_expr, method_sym, arg_start, arg_count, node)

    if self.sema.dyn_trait_symbol_for_type(recv_type) != 0:
        let dyn_fn_op = self.const_operand(ConstKind.CK_FN, method_sym, 0)
        let dyn_args: Vec[i32] = Vec.new()
        dyn_args.push(self.lower_expr(self_expr))
        for dyn_ai in 0..arg_count:
            dyn_args.push(self.lower_expr(self.ast.get_extra(arg_start + dyn_ai)))
        let dyn_args_id = self.body.new_call_args(dyn_args)
        self.body.set_call_intrinsic(dyn_args_id, MirIntrinsic.DYN_CALL)
        self.body.set_call_ast_node(dyn_args_id, node)
        var dyn_ret_ty = self.expr_type(node)
        if dyn_ret_ty == 0:
            dyn_ret_ty = self.sema.ty_void as i32
        let dyn_result = self.new_temp(dyn_ret_ty)
        let dyn_place = self.place_for_local(dyn_result)
        let dyn_next = self.new_block()
        self.terminate(TermKind.TK_CALL, dyn_fn_op, dyn_args_id, dyn_place, dyn_next)
        self.switch_to(dyn_next)
        if self.sema.is_copy(dyn_ret_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, dyn_place)
        return self.body.new_operand(OperandKind.OK_MOVE, dyn_place)

    // If resolution returned bare method_sym, the method is unresolved.
    // Route through MirIntrinsic.GENERIC_CALL so codegen's gen_call handles it
    // (disc enums, from_int, Option methods, concrete/generic struct methods, etc.).
    if callee_sym == method_sym:
            let gc_fn_op = self.const_operand(ConstKind.CK_FN, callee_sym, 0)
            let gc_args: Vec[i32] = Vec.new()
            // Lower self + method args so the handler can eval them.
            // Skip receiver for static calls (type name, not value expression).
            var gc_is_static = false
            if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
                let gc_id_sym = self.ast.get_data0(self_expr)
                if self.lookup_local(gc_id_sym) < 0 and self.sema.named_types.contains(gc_id_sym):
                    gc_is_static = true
            if self.ast.kind(self_expr) == NodeKind.NK_TYPE_NAMED or self.ast.kind(self_expr) == NodeKind.NK_TYPE_GENERIC or self.ast.kind(self_expr) == NodeKind.NK_TYPE_PTR or self.ast.kind(self_expr) == NodeKind.NK_TYPE_REF or self.ast.kind(self_expr) == NodeKind.NK_TYPE_ARRAY or self.ast.kind(self_expr) == NodeKind.NK_TYPE_SLICE or self.ast.kind(self_expr) == NodeKind.NK_TYPE_TUPLE or self.ast.kind(self_expr) == NodeKind.NK_TYPE_FN or self.ast.kind(self_expr) == NodeKind.NK_TYPE_EXTERN_FN or self.ast.kind(self_expr) == NodeKind.NK_TYPE_TRAIT_OBJ:
                gc_is_static = true
            if self.ast.kind(self_expr) == NodeKind.NK_INDEX:
                let gc_idx_base = self.ast.get_data0(self_expr)
                if self.ast.kind(gc_idx_base) == NodeKind.NK_IDENT:
                    let gc_idx_sym = self.ast.get_data0(gc_idx_base)
                    if self.lookup_local(gc_idx_sym) < 0 and self.sema.named_types.contains(gc_idx_sym):
                        gc_is_static = true
            if not gc_is_static:
                gc_args.push(self.lower_expr(self_expr))
            for gc_mai in 0..arg_count:
                let gc_ma_node = self.ast.get_extra(arg_start + gc_mai)
                if self.ast.kind(gc_ma_node) != NodeKind.NK_CLOSURE:
                    gc_args.push(self.lower_expr(gc_ma_node))
                else:
                    gc_args.push(self.const_operand(ConstKind.CK_INT, 0, self.sema.ty_i32))
            let gc_args_id = self.body.new_call_args(gc_args)
            self.body.set_call_intrinsic(gc_args_id, MirIntrinsic.GENERIC_CALL)
            self.body.set_call_ast_node(gc_args_id, node)
            var gc_ret_ty = self.expr_type(node)
            if gc_ret_ty == 0:
                gc_ret_ty = self.sema.ty_i32 as i32
            let gc_result = self.new_temp(gc_ret_ty)
            let gc_place = self.place_for_local(gc_result)
            let gc_next = self.new_block()
            self.terminate(TermKind.TK_CALL, gc_fn_op, gc_args_id, gc_place, gc_next)
            self.switch_to(gc_next)
            return self.body.new_operand(OperandKind.OK_COPY, gc_place)

    let fn_op = self.lower_var(callee_sym, 0, 0)
    let arg_nodes: Vec[i32] = Vec.new()
    // For static method calls (receiver is a type name, not a value),
    // don't pass the receiver as an argument.
    var is_static_call = false
    if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
        let recv_sym = self.ast.get_data0(self_expr)
        if self.lookup_local(recv_sym) < 0 and self.sema.named_types.contains(recv_sym):
            is_static_call = true
    if self.ast.kind(self_expr) == NodeKind.NK_TYPE_NAMED or self.ast.kind(self_expr) == NodeKind.NK_TYPE_GENERIC or self.ast.kind(self_expr) == NodeKind.NK_TYPE_PTR or self.ast.kind(self_expr) == NodeKind.NK_TYPE_REF or self.ast.kind(self_expr) == NodeKind.NK_TYPE_ARRAY or self.ast.kind(self_expr) == NodeKind.NK_TYPE_SLICE or self.ast.kind(self_expr) == NodeKind.NK_TYPE_TUPLE or self.ast.kind(self_expr) == NodeKind.NK_TYPE_FN or self.ast.kind(self_expr) == NodeKind.NK_TYPE_EXTERN_FN or self.ast.kind(self_expr) == NodeKind.NK_TYPE_TRAIT_OBJ:
        is_static_call = true
    // Also detect Vec[i32].method() as static
    if self.ast.kind(self_expr) == NodeKind.NK_INDEX:
        let idx_base = self.ast.get_data0(self_expr)
        if self.ast.kind(idx_base) == NodeKind.NK_IDENT:
            let recv_sym = self.ast.get_data0(idx_base)
            if self.lookup_local(recv_sym) < 0 and self.sema.named_types.contains(recv_sym):
                is_static_call = true
    if not is_static_call:
        arg_nodes.push(self_expr)
    for i in 0..arg_count:
        arg_nodes.push(self.ast.get_extra(arg_start + i))

    self.lower_call_with_arg_nodes(fn_op, callee_sym, arg_nodes, self.expr_type(node), node)

fn MirBuilder.lower_intrinsic_call(self: MirBuilder, intrinsic: MirIntrinsic, self_expr: i32, method_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
    // Emit a call terminator with a ConstKind.CK_FN operand and intrinsic tag.
    // The ConstKind.CK_FN sym is meaningless — codegen dispatches by intrinsic kind.
    let fn_op = self.const_operand(ConstKind.CK_FN, method_sym, self.sema.ty_void)

    // Build argument operands. For static calls (Vec.new, HashMap.new),
    // the receiver is a type ident — skip it. For instance methods, include it.
    let is_static = intrinsic == MirIntrinsic.VEC_NEW or intrinsic == MirIntrinsic.VEC_WITH_CAPACITY or intrinsic == MirIntrinsic.MAP_NEW or intrinsic == MirIntrinsic.SLOTMAP_NEW
    let call_args: Vec[i32] = Vec.new()
    var recv_type_for_args = 0
    if not is_static:
        let recv_ty = self.expr_type(self_expr)
        recv_type_for_args = recv_ty
        let recv_resolved = if recv_ty != 0: self.sema.resolve_alias(recv_ty as TypeId) else: 0
        let recv_kind = self.sema.get_type_kind(recv_resolved)
        let raw_pointer_option_receiver = recv_kind == TypeKind.TY_PTR and (intrinsic == MirIntrinsic.OPT_UNWRAP or intrinsic == MirIntrinsic.OPT_IS_SOME or intrinsic == MirIntrinsic.OPT_IS_NONE or intrinsic == MirIntrinsic.OPT_FILTER)
        if raw_pointer_option_receiver:
            call_args.push(self.lower_expr(self_expr))
        else:
            call_args.push(self.lower_receiver_with_method_autoderef(self_expr))
    for i in 0..arg_count:
        let arg_node = self.ast.get_extra(arg_start + i)
        call_args.push(self.lower_method_arg_with_expected(recv_type_for_args, method_sym, arg_node, i))

    let args_id = self.body.new_call_args(call_args)
    var ret_type = self.expr_type(node)
    if intrinsic == MirIntrinsic.VEC_PUSH and self.expected_type == self.sema.ty_void as i32:
        ret_type = self.sema.ty_void as i32
    // For static constructors (Vec.new, HashMap.new), expr_type often returns
    // the bare struct type (TypeKind.TY_STRUCT) instead of the generic instance
    // (TypeKind.TY_GENERIC_INST). Use the expected type from the let binding if available.
    // Only apply to static constructors — instance methods (str.slice, vec.len) must
    // keep their own return type, not inherit the function's generic return type.
    if is_static and self.expected_type > 0:
        let expected_resolved = self.sema.resolve_alias(self.expected_type)
        let et_tk = self.sema.get_type_kind(expected_resolved)
        var expected_matches_receiver = false
        if et_tk == TypeKind.TY_GENERIC_INST:
            let expected_base = self.sema.get_type_d0(expected_resolved)
            let recv_base_ty = self.type_receiver_type(self_expr)
            if recv_base_ty != 0:
                let recv_resolved = self.sema.resolve_alias(recv_base_ty)
                if self.sema.get_type_kind(recv_resolved) == TypeKind.TY_STRUCT:
                    expected_matches_receiver = self.sema.get_type_d0(recv_resolved) == expected_base
        if expected_matches_receiver:
            ret_type = expected_resolved as i32
    // If ret_type is still a base struct (not generic instance) for a static
    // constructor, try to resolve from the NodeKind.NK_INDEX receiver (Vec[i32]).
    if is_static:
        let ret_resolved = if ret_type != 0: self.sema.resolve_alias(ret_type) else: 0
        let ret_tk = self.sema.get_type_kind(ret_resolved)
        if ret_type == 0 or ret_type == self.sema.ty_void or ret_tk == TypeKind.TY_STRUCT:
            // Try resolving generic instance from NodeKind.NK_INDEX receiver (e.g. Vec[i32])
            if self.ast.kind(self_expr) == NodeKind.NK_INDEX:
                let gi_type = self.resolve_index_generic_inst(self_expr)
                if gi_type > 0:
                    ret_type = gi_type
        // Re-check after NodeKind.NK_INDEX resolution
        let ret_resolved2 = if ret_type != 0: self.sema.resolve_alias(ret_type) else: 0
        let ret_tk2 = self.sema.get_type_kind(ret_resolved2)
        if ret_type == 0 or ret_type == self.sema.ty_void or ret_tk2 == TypeKind.TY_STRUCT:
            self.mark_unsupported()
    let result_local = self.new_temp(ret_type)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()

    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)

    // Tag call with intrinsic kind for codegen dispatch.
    let call_id = self.body.call_arg_starts.len() as i32 - 1
    self.body.set_call_intrinsic(call_id, intrinsic)

    if self.sema.is_copy(ret_type) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_vtable_call(self: MirBuilder, dyn_expr: i32, _trait_sym: i32, method_sym: i32, args_start: i32, args_count: i32, node: i32) -> i32:
    // Conservative lowering: treat as method call on dynamic receiver.
    self.lower_method_call(dyn_expr, method_sym, args_start, args_count, node)

fn MirBuilder.cancel_scheduled_value_drop_for_receiver_expr(self: MirBuilder, expr: i32):
    if expr == 0:
        return
    let kind = self.ast.kind(expr)
    if kind == NodeKind.NK_GROUPED:
        self.cancel_scheduled_value_drop_for_receiver_expr(self.ast.get_data0(expr))
        return
    if kind != NodeKind.NK_IDENT:
        return
    let sym = self.ast.get_data0(expr)
    let local = self.lookup_local(sym)
    if local >= 0:
        self.cancel_scheduled_value_drop_for_local(local)

fn MirBuilder.enum_accessor_payload_operand(self: MirBuilder, enum_place: i32, enum_ty: i32, variant_sym: i32, variant_index: i32, accessor_kind: i32, result_ty: i32, span: i32) -> i32:
    let payloads = self.sema.enum_variant_payload_types(enum_ty, variant_sym)
    let payload_count = payloads.len() as i32
    let unwrapped_ty = self.sema.try_unwrapped_type(result_ty) as i32
    if payload_count <= 0 or unwrapped_ty == 0:
        with_eprint("error: enum accessor lowering missing payload type")
        self.mark_unsupported()
        return self.unit_operand()

    let variant_place = self.body.new_downcast_place(enum_place, variant_index, enum_ty)
    if payload_count == 1:
        let payload_ty = payloads.get(0)
        let field_place = self.body.new_field_place(variant_place, 0, payload_ty)
        if accessor_kind == 3 or accessor_kind == 4:
            let borrow_kind = if accessor_kind == 4: BorrowKind.EXCLUSIVE else: BorrowKind.SHARED
            let ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, borrow_kind, field_place, 0)
            let ref_tmp = self.new_temp(unwrapped_ty)
            let ref_place = self.place_for_local(ref_tmp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, ref_place, ref_rv, span)
            return self.body.new_operand(OperandKind.OK_COPY, ref_place)
        let op_kind = if self.sema.is_copy(payload_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
        return self.body.new_operand(op_kind, field_place)

    let tuple_fields: Vec[i32] = Vec.new()
    let tuple_names: Vec[i32] = Vec.new()
    let tuple_elem_start = if self.sema.get_type_kind(self.sema.resolve_alias(unwrapped_ty as TypeId)) == TypeKind.TY_TUPLE: self.sema.get_type_d0(self.sema.resolve_alias(unwrapped_ty as TypeId)) else: 0
    for pi in 0..payload_count:
        let payload_ty = payloads.get(pi as i64)
        let field_place = self.body.new_field_place(variant_place, pi, payload_ty)
        if accessor_kind == 3 or accessor_kind == 4:
            let ref_mut = if accessor_kind == 4: 1 else: 0
            let elem_ty = if tuple_elem_start > 0: self.sema.type_extra.get((tuple_elem_start + pi) as i64) else: self.sema.ensure_exact_type(TypeKind.TY_REF, payload_ty, ref_mut, 0) as i32
            let borrow_kind = if accessor_kind == 4: BorrowKind.EXCLUSIVE else: BorrowKind.SHARED
            let ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, borrow_kind, field_place, 0)
            let ref_tmp = self.new_temp(elem_ty)
            let ref_place = self.place_for_local(ref_tmp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, ref_place, ref_rv, span)
            tuple_fields.push(self.body.new_operand(OperandKind.OK_COPY, ref_place))
        else:
            let op_kind = if self.sema.is_copy(payload_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
            tuple_fields.push(self.body.new_operand(op_kind, field_place))
        tuple_names.push(0)
    let tuple_fid = self.body.new_agg_fields(tuple_fields, tuple_names)
    let tuple_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, tuple_fid, 0)
    let tuple_tmp = self.new_temp(unwrapped_ty)
    let tuple_place = self.place_for_local(tuple_tmp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, tuple_place, tuple_rv, span)
    self.body.new_operand(if self.sema.is_copy(unwrapped_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, tuple_place)

fn MirBuilder.assign_enum_variant_to_place(self: MirBuilder, result_place: i32, result_ty: i32, variant_sym: i32, fields: Vec[i32], span: i32):
    let names: Vec[i32] = Vec.new()
    for _ in 0..fields.len() as i32:
        names.push(0)
    let fid = self.body.new_agg_fields(fields, names)
    let tag = self.enum_variant_discriminant_for_type(result_ty, variant_sym)
    let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fid, tag)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, result_place, rv, span)

fn MirBuilder.lower_context_error_operand(self: MirBuilder, message_op: i32, source_op: i32, context_error_ty: i32, span: i32) -> i32:
    let fields: Vec[i32] = Vec.new()
    fields.push(message_op)
    fields.push(source_op)
    let names: Vec[i32] = Vec.new()
    names.push(self.pool.intern("message"))
    names.push(self.pool.intern("source"))
    let fid = self.body.new_agg_fields(fields, names)
    let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, fid, 0)
    let tmp = self.new_temp(context_error_ty)
    let place = self.place_for_local(tmp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, span)
    self.operand_for_place(place, context_error_ty)

fn MirBuilder.lower_enum_accessor_call(self: MirBuilder, self_expr: i32, method_sym: i32, node: i32) -> i32:
    var enum_ty = self.expr_type(self_expr)
    if enum_ty == 0 or enum_ty == self.sema.ty_void as i32:
        enum_ty = self.type_receiver_type(self_expr)
    if enum_ty == 0 or enum_ty == self.sema.ty_void as i32:
        self.mark_unsupported()
        return self.unit_operand()
    enum_ty = self.sema.auto_deref_ref_ptr_type(enum_ty as TypeId) as i32

    let variant_sym = self.sema.enum_accessor_variant_for_method(enum_ty, method_sym)
    let accessor_kind = self.sema.enum_accessor_kind_for_method(enum_ty, method_sym)
    let variant_index = self.enum_variant_index_for_type(enum_ty, variant_sym)
    let variant_disc = self.enum_variant_discriminant_for_type(enum_ty, variant_sym)
    let span = self.ast.get_start(node)

    if accessor_kind == 1:
        let recv_place = self.lower_field_base_place(self_expr)
        let disc = self.lower_enum_discriminant(recv_place)
        let expected = self.int_const_operand(variant_disc as i64, self.sema.ty_i32)
        let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_EQ, disc, expected)
        let cmp_tmp = self.new_temp(self.sema.ty_bool as i32)
        let cmp_place = self.place_for_local(cmp_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, span)
        return self.body.new_operand(OperandKind.OK_COPY, cmp_place)

    let result_ty = self.expr_type(node)
    if result_ty == 0 or result_ty == self.sema.ty_void as i32:
        with_eprint("error: enum accessor lowering missing result type")
        self.mark_unsupported()
        return self.unit_operand()

    var recv_place = 0
    if accessor_kind == 2:
        let saved_expected = self.expected_type
        self.expected_type = enum_ty
        let recv_op = self.lower_expr(self_expr)
        self.expected_type = saved_expected
        let recv_tmp = self.new_temp(enum_ty)
        recv_place = self.place_for_local(recv_tmp)
        self.assign_operand_to_place(recv_place, recv_op, span)
        self.cancel_scheduled_value_drop_for_receiver_expr(self_expr)
    else:
        recv_place = self.lower_field_base_place(self_expr)

    let result_tmp = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_tmp)
    let some_bb = self.new_block()
    let none_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(recv_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(variant_disc)
    let targets: Vec[i32] = Vec.new()
    targets.push(some_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, none_bb, 0)

    self.switch_to(none_bb)
    if accessor_kind == 2 and self.sema.is_copy(enum_ty) == 0:
        self.body.push_stmt(self.cur_bb, StmtKind.Drop, recv_place, 0, span)
    let none_fields: Vec[i32] = Vec.new()
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.none, none_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb as i32, 0, 0, 0)

    self.switch_to(some_bb)
    let payload = self.enum_accessor_payload_operand(recv_place, enum_ty, variant_sym, variant_index, accessor_kind, result_ty, span)
    let some_fields: Vec[i32] = Vec.new()
    some_fields.push(payload)
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, some_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb as i32, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    self.body.new_operand(if self.sema.is_copy(result_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_question_mark(self: MirBuilder, expr: i32, node: i32) -> i32:
    let value_op = self.lower_expr(expr)
    let value_ty = self.expr_type(expr)
    let value_place = self.materialize_operand(value_op, value_ty, self.ast.get_start(expr))

    let pass_bb = self.new_block()
    let fail_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(value_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.success_variant_index())
    let targets: Vec[i32] = Vec.new()
    targets.push(pass_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, fail_bb, 0)

    self.switch_to(fail_bb)
    let ret_place = self.place_for_local(0)
    let ret_ty = self.body.local_type_ids.get(0)
    let source_err_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.result, 1)
    let target_err_ty = self.generic_inst_arg_type(ret_ty, self.sema.syms.result, 1)
    let source_option_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.option, 0)
    let target_option_ty = self.generic_inst_arg_type(ret_ty, self.sema.syms.option, 0)
    if source_err_ty != 0:
        if target_err_ty == 0:
            self.mark_unsupported()
        else:
            let err_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.err)
            if err_idx < 0:
                self.mark_unsupported()
            else:
                let err_downcast = self.body.new_downcast_place(value_place, err_idx, value_ty)
                let err_payload_place = self.body.new_field_place(err_downcast, 0, source_err_ty)
                var target_err_op = self.operand_for_place(err_payload_place, source_err_ty)
                let conversion_variant = self.sema.error_conversion_variant(target_err_ty, source_err_ty)
                if conversion_variant > 0:
                    let wrapped_err_local = self.new_temp(target_err_ty)
                    let wrapped_err_place = self.place_for_local(wrapped_err_local)
                    let wrapped_fields: Vec[i32] = Vec.new()
                    wrapped_fields.push(target_err_op)
                    self.assign_enum_variant_to_place(wrapped_err_place, target_err_ty, conversion_variant, wrapped_fields, self.ast.get_start(expr))
                    target_err_op = self.operand_for_place(wrapped_err_place, target_err_ty)
                else if conversion_variant < 0:
                    self.mark_unsupported()
                if conversion_variant >= 0:
                    let err_fields: Vec[i32] = Vec.new()
                    err_fields.push(target_err_op)
                    self.assign_enum_variant_to_place(ret_place, ret_ty, self.sema.syms.err, err_fields, self.ast.get_start(expr))
    else if source_option_ty != 0:
        if target_option_ty == 0:
            self.mark_unsupported()
        else:
            let none_fields: Vec[i32] = Vec.new()
            self.assign_enum_variant_to_place(ret_place, ret_ty, self.sema.syms.none, none_fields, self.ast.get_start(expr))
    else:
        let fail_op = self.body.new_operand(OperandKind.OK_MOVE, value_place)
        self.assign_operand_to_place(ret_place, fail_op, self.ast.get_start(expr))
    self.emit_errdefers_for_return()
    self.emit_defers_for_return()
    self.emit_drops_for_return()
    self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

    // Extract Ok payload via ProjKind.PK_DOWNCAST + field access
    var result_ty = self.expr_type(node)
    if result_ty == 0 or result_ty == self.sema.ty_void:
        result_ty = value_ty
    self.switch_to(pass_bb)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let downcast_place = self.body.new_downcast_place(value_place, self.success_variant_index(), value_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, result_ty)
    let pass_op = self.body.new_operand(if self.sema.is_copy(result_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, payload_place)
    self.assign_operand_to_place(result_place, pass_op, self.ast.get_start(expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_double_question(self: MirBuilder, expr: i32, default_expr: i32, node: i32) -> i32:
    let value_op = self.lower_expr(expr)
    let value_ty = self.expr_type(expr)
    let value_place = self.materialize_operand(value_op, value_ty, self.ast.get_start(expr))

    let some_bb = self.new_block()
    let none_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(value_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.success_variant_index())
    let targets: Vec[i32] = Vec.new()
    targets.push(some_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, none_bb, 0)

    var result_ty = self.expr_type(node)
    if result_ty == 0 or result_ty == self.sema.ty_void:
        result_ty = self.sema.try_unwrapped_type(value_ty)
    if result_ty == 0 or result_ty == self.sema.ty_void:
        result_ty = value_ty
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(some_bb)
    let downcast_place = self.body.new_downcast_place(value_place, self.success_variant_index(), value_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, result_ty)
    let some_op = self.body.new_operand(if self.sema.is_copy(result_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, payload_place)
    self.assign_operand_to_place(result_place, some_op, self.ast.get_start(expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(none_bb)
    let default_op = self.lower_expr(default_expr)
    self.assign_operand_to_place(result_place, default_op, self.ast.get_start(default_expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.is_option_or_result_type(self: MirBuilder, type_id: i32) -> i32:
    if type_id == 0:
        return 0
    let resolved = self.sema.resolve_alias(type_id as TypeId)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    let base = self.sema.get_generic_inst_base(resolved as i32)
    if base == self.sema.syms.option or base == self.sema.syms.result: 1 else: 0

fn MirBuilder.is_option_type(self: MirBuilder, type_id: i32) -> i32:
    if type_id == 0:
        return 0
    let resolved = self.sema.resolve_alias(type_id as TypeId)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.sema.get_generic_inst_base(resolved as i32) == self.sema.syms.option: 1 else: 0

fn MirBuilder.is_result_type(self: MirBuilder, type_id: i32) -> i32:
    if type_id == 0:
        return 0
    let resolved = self.sema.resolve_alias(type_id as TypeId)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.sema.get_generic_inst_base(resolved as i32) == self.sema.syms.result: 1 else: 0

fn MirBuilder.is_vec_type(self: MirBuilder, type_id: i32) -> i32:
    if type_id == 0:
        return 0
    let resolved = self.sema.resolve_alias(type_id as TypeId)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.sema.get_generic_inst_base(resolved as i32) == self.sema.syms.vec: 1 else: 0

fn MirBuilder.lower_owned_receiver_place(self: MirBuilder, self_expr: i32, value_ty: i32) -> i32:
    let saved_expected = self.expected_type
    self.expected_type = value_ty
    let value_op = self.lower_expr(self_expr)
    self.expected_type = saved_expected
    self.materialize_operand(value_op, value_ty, self.ast.get_start(self_expr))

fn MirBuilder.emit_vec_new_into(self: MirBuilder, vec_place: i32, span: i32):
    let new_sym = self.sema.syms.new
    let fn_op = self.const_operand(ConstKind.CK_FN, new_sym, self.sema.ty_void)
    let args: Vec[i32] = Vec.new()
    let args_id = self.body.new_call_args(args)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.VEC_NEW)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, vec_place, next_bb)
    self.switch_to(next_bb)

fn MirBuilder.emit_vec_len_into(self: MirBuilder, vec_place: i32, len_place: i32, span: i32):
    let len_sym = self.sema.syms.len
    let fn_op = self.const_operand(ConstKind.CK_FN, len_sym, self.sema.ty_void)
    let args: Vec[i32] = Vec.new()
    args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    let args_id = self.body.new_call_args(args)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.VEC_LEN)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, len_place, next_bb)
    self.switch_to(next_bb)

fn MirBuilder.emit_vec_get_into(self: MirBuilder, vec_place: i32, index_place: i32, elem_place: i32, span: i32):
    let get_sym = self.sema.syms.get
    let fn_op = self.const_operand(ConstKind.CK_FN, get_sym, self.sema.ty_void)
    let args: Vec[i32] = Vec.new()
    args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    args.push(self.body.new_operand(OperandKind.OK_COPY, index_place))
    let args_id = self.body.new_call_args(args)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.VEC_GET)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, elem_place, next_bb)
    self.switch_to(next_bb)

fn MirBuilder.emit_vec_push(self: MirBuilder, vec_place: i32, elem_op: i32, span: i32):
    let push_sym = self.sema.syms.push
    let fn_op = self.const_operand(ConstKind.CK_FN, push_sym, self.sema.ty_void)
    let args: Vec[i32] = Vec.new()
    args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    args.push(elem_op)
    let args_id = self.body.new_call_args(args)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.VEC_PUSH)
    let result_local = self.new_temp(self.sema.ty_void)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)

fn MirBuilder.lower_option_transpose_method(self: MirBuilder, self_expr: i32, arg_count: i32, node: i32) -> i32:
    if arg_count != 0:
        self.mark_unsupported()
        return self.unit_operand()
    let span = self.ast.get_start(node)
    var value_ty = self.expr_type(self_expr)
    if value_ty == 0 or value_ty == self.sema.ty_void:
        value_ty = self.type_receiver_type(self_expr)
    let inner_result_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.option, 0)
    let inner_ok_ty = self.generic_inst_arg_type(inner_result_ty, self.sema.syms.result, 0)
    let inner_err_ty = self.generic_inst_arg_type(inner_result_ty, self.sema.syms.result, 1)
    let result_ty = self.expr_type(node)
    let result_ok_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.result, 0)
    if value_ty == 0 or inner_result_ty == 0 or inner_ok_ty == 0 or inner_err_ty == 0 or result_ty == 0 or result_ok_ty == 0:
        self.mark_unsupported()
        return self.unit_operand()

    let value_place = self.lower_owned_receiver_place(self_expr, value_ty)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let some_bb = self.new_block()
    let none_bb = self.new_block()
    let inner_ok_bb = self.new_block()
    let inner_err_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(value_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.enum_variant_discriminant_for_type(value_ty, self.sema.syms.some))
    let targets: Vec[i32] = Vec.new()
    targets.push(some_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, none_bb, 0)

    self.switch_to(none_bb)
    let none_option_local = self.new_temp(result_ok_ty)
    let none_option_place = self.place_for_local(none_option_local)
    let none_fields: Vec[i32] = Vec.new()
    self.assign_enum_variant_to_place(none_option_place, result_ok_ty, self.sema.syms.none, none_fields, span)
    let none_ok_fields: Vec[i32] = Vec.new()
    none_ok_fields.push(self.operand_for_place(none_option_place, result_ok_ty))
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.ok, none_ok_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(some_bb)
    let some_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.some)
    let some_downcast = self.body.new_downcast_place(value_place, some_idx, value_ty)
    let inner_result_place = self.body.new_field_place(some_downcast, 0, inner_result_ty)
    let inner_disc = self.lower_enum_discriminant(inner_result_place)
    let inner_vals: Vec[i32] = Vec.new()
    inner_vals.push(self.enum_variant_discriminant_for_type(inner_result_ty, self.sema.syms.ok))
    let inner_targets: Vec[i32] = Vec.new()
    inner_targets.push(inner_ok_bb as i32)
    let inner_table = self.body.new_switch_table(inner_vals, inner_targets)
    self.terminate(TermKind.TK_SWITCH_INT, inner_disc, inner_table, inner_err_bb, 0)

    self.switch_to(inner_ok_bb)
    let ok_idx = self.enum_variant_index_for_type(inner_result_ty, self.sema.syms.ok)
    let ok_downcast = self.body.new_downcast_place(inner_result_place, ok_idx, inner_result_ty)
    let ok_payload_place = self.body.new_field_place(ok_downcast, 0, inner_ok_ty)
    let some_option_local = self.new_temp(result_ok_ty)
    let some_option_place = self.place_for_local(some_option_local)
    let some_fields: Vec[i32] = Vec.new()
    some_fields.push(self.operand_for_place(ok_payload_place, inner_ok_ty))
    self.assign_enum_variant_to_place(some_option_place, result_ok_ty, self.sema.syms.some, some_fields, span)
    let ok_fields: Vec[i32] = Vec.new()
    ok_fields.push(self.operand_for_place(some_option_place, result_ok_ty))
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.ok, ok_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(inner_err_bb)
    let err_idx = self.enum_variant_index_for_type(inner_result_ty, self.sema.syms.err)
    let err_downcast = self.body.new_downcast_place(inner_result_place, err_idx, inner_result_ty)
    let err_payload_place = self.body.new_field_place(err_downcast, 0, inner_err_ty)
    let err_fields: Vec[i32] = Vec.new()
    err_fields.push(self.operand_for_place(err_payload_place, inner_err_ty))
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.err, err_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    self.operand_for_place(result_place, result_ty)

fn MirBuilder.lower_result_transpose_method(self: MirBuilder, self_expr: i32, arg_count: i32, node: i32) -> i32:
    if arg_count != 0:
        self.mark_unsupported()
        return self.unit_operand()
    let span = self.ast.get_start(node)
    var value_ty = self.expr_type(self_expr)
    if value_ty == 0 or value_ty == self.sema.ty_void:
        value_ty = self.type_receiver_type(self_expr)
    let inner_option_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.result, 0)
    let inner_err_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.result, 1)
    let inner_some_ty = self.generic_inst_arg_type(inner_option_ty, self.sema.syms.option, 0)
    let result_ty = self.expr_type(node)
    let result_some_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.option, 0)
    if value_ty == 0 or inner_option_ty == 0 or inner_err_ty == 0 or inner_some_ty == 0 or result_ty == 0 or result_some_ty == 0:
        self.mark_unsupported()
        return self.unit_operand()

    let value_place = self.lower_owned_receiver_place(self_expr, value_ty)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let ok_bb = self.new_block()
    let err_bb = self.new_block()
    let inner_some_bb = self.new_block()
    let inner_none_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(value_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.enum_variant_discriminant_for_type(value_ty, self.sema.syms.ok))
    let targets: Vec[i32] = Vec.new()
    targets.push(ok_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, err_bb, 0)

    self.switch_to(err_bb)
    let err_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.err)
    let err_downcast = self.body.new_downcast_place(value_place, err_idx, value_ty)
    let err_payload_place = self.body.new_field_place(err_downcast, 0, inner_err_ty)
    let err_result_local = self.new_temp(result_some_ty)
    let err_result_place = self.place_for_local(err_result_local)
    let err_fields: Vec[i32] = Vec.new()
    err_fields.push(self.operand_for_place(err_payload_place, inner_err_ty))
    self.assign_enum_variant_to_place(err_result_place, result_some_ty, self.sema.syms.err, err_fields, span)
    let err_some_fields: Vec[i32] = Vec.new()
    err_some_fields.push(self.operand_for_place(err_result_place, result_some_ty))
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, err_some_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(ok_bb)
    let ok_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.ok)
    let ok_downcast = self.body.new_downcast_place(value_place, ok_idx, value_ty)
    let inner_option_place = self.body.new_field_place(ok_downcast, 0, inner_option_ty)
    let inner_disc = self.lower_enum_discriminant(inner_option_place)
    let inner_vals: Vec[i32] = Vec.new()
    inner_vals.push(self.enum_variant_discriminant_for_type(inner_option_ty, self.sema.syms.some))
    let inner_targets: Vec[i32] = Vec.new()
    inner_targets.push(inner_some_bb as i32)
    let inner_table = self.body.new_switch_table(inner_vals, inner_targets)
    self.terminate(TermKind.TK_SWITCH_INT, inner_disc, inner_table, inner_none_bb, 0)

    self.switch_to(inner_none_bb)
    let none_fields: Vec[i32] = Vec.new()
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.none, none_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(inner_some_bb)
    let some_idx = self.enum_variant_index_for_type(inner_option_ty, self.sema.syms.some)
    let some_downcast = self.body.new_downcast_place(inner_option_place, some_idx, inner_option_ty)
    let some_payload_place = self.body.new_field_place(some_downcast, 0, inner_some_ty)
    let ok_result_local = self.new_temp(result_some_ty)
    let ok_result_place = self.place_for_local(ok_result_local)
    let ok_fields: Vec[i32] = Vec.new()
    ok_fields.push(self.operand_for_place(some_payload_place, inner_some_ty))
    self.assign_enum_variant_to_place(ok_result_place, result_some_ty, self.sema.syms.ok, ok_fields, span)
    let some_fields: Vec[i32] = Vec.new()
    some_fields.push(self.operand_for_place(ok_result_place, result_some_ty))
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, some_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    self.operand_for_place(result_place, result_ty)

fn MirBuilder.lower_vec_sequence_or_traverse_method(self: MirBuilder, self_expr: i32, method_name: str, arg_start: i32, arg_count: i32, node: i32) -> i32:
    let span = self.ast.get_start(node)
    var recv_type = self.expr_type(self_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        recv_type = self.type_receiver_type(self_expr)
    let recv_elem_ty = self.generic_inst_arg_type(recv_type, self.sema.syms.vec, 0)
    let result_ty = self.expr_type(node)
    var wrapper_base = self.sema.syms.option
    var output_vec_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.option, 0)
    var output_elem_ty = self.generic_inst_arg_type(output_vec_ty, self.sema.syms.vec, 0)
    if output_vec_ty == 0:
        wrapper_base = self.sema.syms.result
        output_vec_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.result, 0)
        output_elem_ty = self.generic_inst_arg_type(output_vec_ty, self.sema.syms.vec, 0)
    if recv_type == 0 or recv_elem_ty == 0 or result_ty == 0 or output_vec_ty == 0 or output_elem_ty == 0:
        self.mark_unsupported()
        return self.unit_operand()
    if method_name == "sequence" and arg_count != 0:
        self.mark_unsupported()
        return self.unit_operand()
    if method_name == "traverse" and arg_count != 1:
        self.mark_unsupported()
        return self.unit_operand()

    let recv_place = self.lower_owned_receiver_place(self_expr, recv_type)
    var mapper_op = 0
    var wrapper_ty = recv_elem_ty
    if method_name == "traverse":
        mapper_op = self.lower_method_arg_with_expected(recv_type, self.sema.syms.traverse, self.ast.get_extra(arg_start), 0)
        if wrapper_base == self.sema.syms.option:
            wrapper_ty = self.sema.ensure_option_type_for(output_elem_ty)
        else:
            let result_err_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.result, 1)
            wrapper_ty = self.sema.ensure_result_type_for(output_elem_ty, result_err_ty)
    let success_variant = if wrapper_base == self.sema.syms.option: self.sema.syms.some else: self.sema.syms.ok
    let failure_variant = if wrapper_base == self.sema.syms.option: self.sema.syms.none else: self.sema.syms.err
    let failure_payload_ty = if wrapper_base == self.sema.syms.result: self.generic_inst_arg_type(wrapper_ty, self.sema.syms.result, 1) else: 0
    if wrapper_ty == 0 or (wrapper_base == self.sema.syms.result and failure_payload_ty == 0):
        self.mark_unsupported()
        return self.unit_operand()

    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let out_vec_local = self.new_temp(output_vec_ty)
    let out_vec_place = self.place_for_local(out_vec_local)
    self.emit_vec_new_into(out_vec_place, span)

    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    self.emit_vec_len_into(recv_place, len_place, span)

    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RvalueKind.RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, zero_rv, span)

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let item_success_bb = self.new_block()
    let item_fail_bb = self.new_block()
    let inc_bb = self.new_block()
    let done_bb = self.new_block()
    let join_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let len_op = self.body.new_operand(OperandKind.OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, span)
    let cmp_read = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let header_vals: Vec[i32] = Vec.new()
    header_vals.push(1)
    let header_targets: Vec[i32] = Vec.new()
    header_targets.push(body_bb as i32)
    let header_table = self.body.new_switch_table(header_vals, header_targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_read, header_table, done_bb, 0)

    self.switch_to(body_bb)
    let recv_elem_local = self.new_temp(recv_elem_ty)
    let recv_elem_place = self.place_for_local(recv_elem_local)
    self.emit_vec_get_into(recv_place, counter_place, recv_elem_place, span)
    var wrapper_place = recv_elem_place
    if method_name == "traverse":
        let call_args: Vec[i32] = Vec.new()
        call_args.push(self.operand_for_place(recv_elem_place, recv_elem_ty))
        let wrapper_op = self.lower_call_with_operand_args(mapper_op, call_args, wrapper_ty, node)
        wrapper_place = self.materialize_operand(wrapper_op, wrapper_ty, span)
    let item_disc = self.lower_enum_discriminant(wrapper_place)
    let item_vals: Vec[i32] = Vec.new()
    item_vals.push(self.enum_variant_discriminant_for_type(wrapper_ty, success_variant))
    let item_targets: Vec[i32] = Vec.new()
    item_targets.push(item_success_bb as i32)
    let item_table = self.body.new_switch_table(item_vals, item_targets)
    self.terminate(TermKind.TK_SWITCH_INT, item_disc, item_table, item_fail_bb, 0)

    self.switch_to(item_success_bb)
    let success_idx = self.enum_variant_index_for_type(wrapper_ty, success_variant)
    let success_downcast = self.body.new_downcast_place(wrapper_place, success_idx, wrapper_ty)
    let success_payload_place = self.body.new_field_place(success_downcast, 0, output_elem_ty)
    self.emit_vec_push(out_vec_place, self.operand_for_place(success_payload_place, output_elem_ty), span)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

    self.switch_to(item_fail_bb)
    if wrapper_base == self.sema.syms.option:
        let fail_fields: Vec[i32] = Vec.new()
        self.assign_enum_variant_to_place(result_place, result_ty, failure_variant, fail_fields, span)
    else:
        let failure_idx = self.enum_variant_index_for_type(wrapper_ty, failure_variant)
        let failure_downcast = self.body.new_downcast_place(wrapper_place, failure_idx, wrapper_ty)
        let failure_payload_place = self.body.new_field_place(failure_downcast, 0, failure_payload_ty)
        let fail_fields2: Vec[i32] = Vec.new()
        fail_fields2.push(self.operand_for_place(failure_payload_place, failure_payload_ty))
        self.assign_enum_variant_to_place(result_place, result_ty, failure_variant, fail_fields2, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(inc_bb)
    let cur_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, span)
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.switch_to(done_bb)
    let success_fields: Vec[i32] = Vec.new()
    success_fields.push(self.operand_for_place(out_vec_place, output_vec_ty))
    self.assign_enum_variant_to_place(result_place, result_ty, success_variant, success_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    self.operand_for_place(result_place, result_ty)

fn MirBuilder.lower_option_combinator_method(self: MirBuilder, self_expr: i32, method_name: str, arg_start: i32, arg_count: i32, node: i32) -> i32:
    if arg_count != 1:
        self.mark_unsupported()
        return self.unit_operand()

    let span = self.ast.get_start(node)
    var value_ty = self.expr_type(self_expr)
    if value_ty == 0 or value_ty == self.sema.ty_void:
        value_ty = self.type_receiver_type(self_expr)
    let payload_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.option, 0)
    let result_ty = self.expr_type(node)
    if payload_ty == 0 or result_ty == 0:
        self.mark_unsupported()
        return self.unit_operand()

    let saved_expected = self.expected_type
    self.expected_type = value_ty
    let value_op = self.lower_expr(self_expr)
    self.expected_type = saved_expected
    let value_place = self.materialize_operand(value_op, value_ty, self.ast.get_start(self_expr))
    let mapper_op = self.lower_expr(self.ast.get_extra(arg_start))

    let some_bb = self.new_block()
    let none_bb = self.new_block()
    let join_bb = self.new_block()
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    let disc = self.lower_enum_discriminant(value_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.enum_variant_discriminant_for_type(value_ty, self.sema.syms.some))
    let targets: Vec[i32] = Vec.new()
    targets.push(some_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, none_bb, 0)

    self.switch_to(none_bb)
    let none_fields: Vec[i32] = Vec.new()
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.none, none_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(some_bb)
    let some_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.some)
    let downcast_place = self.body.new_downcast_place(value_place, some_idx, value_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, payload_ty)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(self.operand_for_place(payload_place, payload_ty))
    let raw_ret_ty = if method_name == "and_then": result_ty else: self.generic_inst_arg_type(result_ty, self.sema.syms.option, 0)
    let mapped_op = self.lower_call_with_operand_args(mapper_op, call_args, raw_ret_ty, node)
    if method_name == "and_then":
        self.assign_operand_to_place(result_place, mapped_op, span)
    else:
        let some_fields: Vec[i32] = Vec.new()
        some_fields.push(mapped_op)
        self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, some_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    self.operand_for_place(result_place, result_ty)

fn MirBuilder.lower_result_combinator_method(self: MirBuilder, self_expr: i32, method_name: str, arg_start: i32, arg_count: i32, node: i32) -> i32:
    if arg_count != 1:
        self.mark_unsupported()
        return self.unit_operand()

    let span = self.ast.get_start(node)
    var value_ty = self.expr_type(self_expr)
    if value_ty == 0 or value_ty == self.sema.ty_void:
        value_ty = self.type_receiver_type(self_expr)
    let source_ok_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.result, 0)
    let source_err_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.result, 1)
    let result_ty = self.expr_type(node)
    let result_ok_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.result, 0)
    let result_err_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.result, 1)
    if source_ok_ty == 0 or source_err_ty == 0 or result_ok_ty == 0 or result_err_ty == 0:
        self.mark_unsupported()
        return self.unit_operand()

    let saved_expected = self.expected_type
    self.expected_type = value_ty
    let value_op = self.lower_expr(self_expr)
    self.expected_type = saved_expected
    let value_place = self.materialize_operand(value_op, value_ty, self.ast.get_start(self_expr))
    var mapper_op = 0
    var context_message_op = 0
    var context_fn_op = 0
    if method_name == "context":
        context_message_op = self.lower_expr(self.ast.get_extra(arg_start))
    else if method_name == "with_context":
        context_fn_op = self.lower_expr(self.ast.get_extra(arg_start))
    else:
        mapper_op = self.lower_expr(self.ast.get_extra(arg_start))

    let ok_bb = self.new_block()
    let err_bb = self.new_block()
    let join_bb = self.new_block()
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    let disc = self.lower_enum_discriminant(value_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.enum_variant_discriminant_for_type(value_ty, self.sema.syms.ok))
    let targets: Vec[i32] = Vec.new()
    targets.push(ok_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, err_bb, 0)

    self.switch_to(ok_bb)
    let ok_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.ok)
    let ok_downcast = self.body.new_downcast_place(value_place, ok_idx, value_ty)
    let ok_payload_place = self.body.new_field_place(ok_downcast, 0, source_ok_ty)
    let ok_fields: Vec[i32] = Vec.new()
    if method_name == "map":
        let ok_call_args: Vec[i32] = Vec.new()
        ok_call_args.push(self.operand_for_place(ok_payload_place, source_ok_ty))
        ok_fields.push(self.lower_call_with_operand_args(mapper_op, ok_call_args, result_ok_ty, node))
    else:
        ok_fields.push(self.operand_for_place(ok_payload_place, source_ok_ty))
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.ok, ok_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(err_bb)
    let err_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.err)
    let err_downcast = self.body.new_downcast_place(value_place, err_idx, value_ty)
    let err_payload_place = self.body.new_field_place(err_downcast, 0, source_err_ty)
    let err_fields: Vec[i32] = Vec.new()
    if method_name == "map_err":
        let err_call_args: Vec[i32] = Vec.new()
        err_call_args.push(self.operand_for_place(err_payload_place, source_err_ty))
        err_fields.push(self.lower_call_with_operand_args(mapper_op, err_call_args, result_err_ty, node))
    else if method_name == "context" or method_name == "with_context":
        var message_op = context_message_op
        if method_name == "with_context":
            let no_context_args: Vec[i32] = Vec.new()
            message_op = self.lower_call_with_operand_args(context_fn_op, no_context_args, self.sema.ty_str as i32, node)
        let source_op = self.operand_for_place(err_payload_place, source_err_ty)
        err_fields.push(self.lower_context_error_operand(message_op, source_op, result_err_ty, span))
    else:
        err_fields.push(self.operand_for_place(err_payload_place, source_err_ty))
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.err, err_fields, span)
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    self.operand_for_place(result_place, result_ty)

fn MirBuilder.lower_method_arg_or_unit(self: MirBuilder, node: i32, arg_start: i32, arg_count: i32, idx: i32) -> i32:
    if self.sema.has_resolved_call_args(node) != 0:
        if idx >= self.sema.get_resolved_call_arg_count(node):
            return self.unit_operand()
        let resolved_arg = self.sema.get_resolved_call_arg(node, idx)
        if resolved_arg == 0:
            return self.unit_operand()
        if resolved_arg < 0:
            return self.lower_var(0 - resolved_arg, 0, 0)
        return self.lower_expr(resolved_arg)
    if idx >= arg_count:
        return self.unit_operand()
    self.lower_expr(self.ast.get_extra(arg_start + idx))

fn MirBuilder.lower_unwrap_or_method(self: MirBuilder, self_expr: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
    let value_op = self.lower_expr(self_expr)
    let value_ty = self.expr_type(self_expr)
    let value_place = self.materialize_operand(value_op, value_ty, self.ast.get_start(self_expr))

    let some_bb = self.new_block()
    let none_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(value_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.success_variant_index())
    let targets: Vec[i32] = Vec.new()
    targets.push(some_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, none_bb, 0)

    var result_ty = self.expr_type(node)
    if result_ty == 0:
        result_ty = self.sema.try_unwrapped_type(value_ty) as i32
    if result_ty == 0:
        result_ty = self.sema.ty_void as i32

    if self.sema.type_is_unit(result_ty) != 0:
        self.switch_to(some_bb)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(none_bb)
        let _ = self.lower_method_arg_or_unit(node, arg_start, arg_count, 0)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        return self.unit_operand()

    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(some_bb)
    let downcast_place = self.body.new_downcast_place(value_place, self.success_variant_index(), value_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, result_ty)
    let some_op = self.body.new_operand(if self.sema.is_copy(result_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, payload_place)
    self.assign_operand_to_place(result_place, some_op, self.ast.get_start(self_expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(none_bb)
    let default_op = self.lower_method_arg_or_unit(node, arg_start, arg_count, 0)
    self.assign_operand_to_place(result_place, default_op, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_with_form1(self: MirBuilder, guard_expr: i32, body_expr: i32) -> i32:
    let _ = self.lower_expr(guard_expr)
    self.push_scope()
    let result = self.lower_expr(body_expr)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_with_guarded(self: MirBuilder, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let encoded = self.ast.get_data2(node)
    let name = decode_with_binding_sym(encoded)
    let is_mut = decode_with_binding_is_mut(encoded)
    let source_ty = self.expr_type(source)
    let payload_ty = self.sema.with_payload_types.get(node).unwrap()
    let enter_fn = self.sema.with_enter_methods.get(node).unwrap()
    let exit_fn = self.sema.with_exit_methods.get(node).unwrap()
    let span = self.ast.get_start(node)

    self.push_scope()

    let guard_local = self.body.new_local(source_ty, 0, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, guard_local, 0, span)
    let source_op = self.lower_expr(source)
    self.assign_operand_to_place(self.place_for_local(guard_local), source_op, self.ast.get_start(source))

    let payload_local = self.body.new_local(payload_ty, is_mut, name, 1)
    if name != 0 and self.pool.resolve_symbol(name) != "_":
        self.bind_local(name, payload_local)
    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, payload_local, 0, span)

    let enter_sig = self.call_sig_for_sym(enter_fn)
    let guard_expected = if enter_sig >= 0 and self.sema.sig_get_param_count(enter_sig) > 0: self.sema.sig_param_type(enter_sig, 0) else: 0
    let enter_args: Vec[i32] = Vec.new()
    enter_args.push(self.operand_for_place_arg(self.place_for_local(guard_local), source_ty, guard_expected, span))
    let enter_args_id = self.body.new_call_args(enter_args)
    self.body.set_call_ast_node(enter_args_id, node)
    let enter_op = self.const_operand(ConstKind.CK_FN, enter_fn, self.sema.ty_void as i32)
    let after_enter = self.new_block()
    self.terminate(TermKind.TK_CALL, enter_op, enter_args_id, self.place_for_local(payload_local), after_enter)
    self.switch_to(after_enter)

    let drop_kind = if is_mut != 0: DropKind.DK_WITH_GUARD_MUT else: DropKind.DK_WITH_GUARD
    self.schedule_with_guard_cleanup(guard_local, payload_local, exit_fn, drop_kind)

    let result = self.lower_expr(body)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_with_binding(self: MirBuilder, sym: i32, rhs_expr: i32, body_expr: i32, span: i32) -> i32:
    // Recover mutability from the encoded d2 value passed via the caller.
    // The caller extracts sym via decode_with_binding_sym, but we need
    // the original encoded value to check is_mut. Re-derive from the
    // with-expr node being lowered.
    let with_node = self.cur_node
    let encoded = self.ast.get_data2(with_node)
    let is_mut = decode_with_binding_is_mut(encoded)
    self.push_scope()
    let ty = self.expr_type(rhs_expr)
    let local = self.body.new_local(ty, is_mut, sym, 1)
    self.bind_local(sym, local)
    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local, 0, span)
    if self.sema.is_copy(ty) == 0:
        self.schedule_drop(local, DropKind.DK_VALUE)
    let rhs = self.lower_expr(rhs_expr)
    self.assign_operand_to_place(self.place_for_local(local), rhs, self.ast.get_start(rhs_expr))
    // Form 2 builder rule: `with <expr> as mut x:` always returns x.
    if is_mut != 0:
        let _ = self.lower_expr_discard(body_expr)
        let local_place = self.place_for_local(local)
        self.pop_scope_inline()
        return self.body.new_operand(OperandKind.OK_COPY, local_place)
    let result = self.lower_expr(body_expr)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_with_tuple(self: MirBuilder, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let extra_start = self.ast.get_data2(node)
    let name_count = self.ast.get_extra(extra_start)
    let is_mut = self.ast.get_extra(extra_start + 1)
    let rhs_ty = self.expr_type(source)
    let rhs_op = self.lower_expr(source)
    let rhs_place = self.materialize_operand(rhs_op, rhs_ty, self.ast.get_start(source))
    self.push_scope()
    if is_mut != 0:
        for ni in 0..name_count:
            let n_sym = self.ast.get_extra(extra_start + 2 + ni)
            if n_sym == 0:
                continue
            let elem_ty = self.tuple_elem_type(rhs_ty, ni)
            let field_place = self.body.new_field_place(rhs_place, ni, elem_ty)
            self.bind_alias_place(n_sym, field_place, elem_ty)
        let _ = self.lower_expr_discard(body)
        self.pop_scope_inline()
        return self.body.new_operand(OperandKind.OK_COPY, rhs_place)
    for ni in 0..name_count:
        let n_sym = self.ast.get_extra(extra_start + 2 + ni)
        if n_sym == 0:
            continue
        let elem_ty = self.tuple_elem_type(rhs_ty, ni)
        let local_id = self.body.new_local(elem_ty, is_mut, n_sym, 1)
        self.bind_local(n_sym, local_id)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(node))
        if self.sema.is_copy(elem_ty) == 0:
            self.schedule_drop(local_id, DropKind.DK_VALUE)
        let field_place = self.body.new_field_place(rhs_place, ni, elem_ty)
        let field_op = self.body.new_operand(OperandKind.OK_COPY, field_place)
        let dst_place = self.place_for_local(local_id)
        self.assign_operand_to_place(dst_place, field_op, self.ast.get_start(node))
    let result = self.lower_expr(body)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_with_form2_3(self: MirBuilder, pat_or_name: i32, rhs_expr: i32, body_expr: i32) -> i32:
    self.push_scope()
    if self.ast.kind(pat_or_name) == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(pat_or_name)
        let ty = self.expr_type(rhs_expr)
        let local = self.body.new_local(ty, 0, sym, 1)
        self.bind_local(sym, local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local, 0, self.ast.get_start(pat_or_name))
        if self.sema.is_copy(ty) == 0:
            self.schedule_drop(local, DropKind.DK_VALUE)
        let rhs = self.lower_expr(rhs_expr)
        self.assign_operand_to_place(self.place_for_local(local), rhs, self.ast.get_start(rhs_expr))
    else:
        let _ = self.lower_expr(rhs_expr)
    let result = self.lower_expr(body_expr)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_record_update(self: MirBuilder, base_expr: i32, field_updates_start: i32, field_updates_count: i32, node: i32) -> i32:
    let ty = self.expr_type(node)
    let base_place = self.lower_expr_place(base_expr)
    if ty != 0 and self.sema.is_copy(ty) == 0 and base_place >= 0 and base_place < self.body.place_locals.len() as i32:
        if self.body.place_proj_counts.get(base_place as i64) == 0:
            self.cancel_scheduled_value_drop_for_local(self.body.place_locals.get(base_place as i64))
    let resolved_ty = self.sema.resolve_alias(ty)
    var struct_extra = self.sema.get_type_d1(resolved_ty)
    var struct_fc = self.sema.get_type_d2(resolved_ty)
    if self.sema.get_type_kind(resolved_ty) == TypeKind.TY_GENERIC_INST:
        let base_sym = self.sema.get_generic_inst_base(resolved_ty as i32)
        let base_tid = self.sema.lookup_named_type_visible(base_sym)
        if base_tid != 0:
            let base_resolved = self.sema.resolve_alias(base_tid)
            if self.sema.get_type_kind(base_resolved) == TypeKind.TY_STRUCT:
                struct_extra = self.sema.get_type_d1(base_resolved)
                struct_fc = self.sema.get_type_d2(base_resolved)

    let update_ops: Vec[i32] = Vec.new()
    for i in 0..field_updates_count:
        let f_name_sym = self.ast.get_extra(field_updates_start + i * 2)
        let f_val_node = self.ast.get_extra(field_updates_start + i * 2 + 1)
        let field_ty = self.struct_field_type(ty, f_name_sym)
        let saved_expected = self.expected_type
        if field_ty != 0:
            self.expected_type = field_ty
        let f_val = self.lower_expr(f_val_node)
        self.expected_type = saved_expected
        update_ops.push(f_val)

    let result_fields: Vec[i32] = Vec.new()
    let result_names: Vec[i32] = Vec.new()
    for fi in 0..struct_fc:
        let f_name_sym = self.sema.type_extra.get((struct_extra + fi * 3) as i64)
        let field_ty = self.struct_field_type(ty, f_name_sym)
        let src_field_place = self.body.new_field_place(base_place, f_name_sym, field_ty)
        var update_idx = -1
        for ui in 0..field_updates_count:
            if self.ast.get_extra(field_updates_start + ui * 2) == f_name_sym:
                update_idx = ui
                break
        if update_idx >= 0:
            if field_ty != 0 and self.sema.is_copy(field_ty) == 0:
                let old_field_tmp = self.new_temp(field_ty)
                let old_field_place = self.place_for_local(old_field_tmp)
                let old_field_op = self.body.new_operand(OperandKind.OK_MOVE, src_field_place)
                self.assign_operand_to_place(old_field_place, old_field_op, self.ast.get_start(node))
                self.body.push_stmt(self.cur_bb, StmtKind.Drop, old_field_place, 0, self.ast.get_start(node))
            result_fields.push(update_ops.get(update_idx as i64))
        else:
            let op_kind = if field_ty != 0 and self.sema.is_copy(field_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
            let field_op = self.body.new_operand(op_kind, src_field_place)
            result_fields.push(field_op)
        result_names.push(f_name_sym)

    let result_fid = self.body.new_agg_fields(result_fields, result_names)
    let result_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, result_fid, 0)
    let tmp = self.new_temp(ty)
    let result_place = self.place_for_local(tmp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, result_place, result_rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_implicit_ok(self: MirBuilder, expr: i32, ok_type_id: i32) -> i32:
    let op = self.lower_expr(expr)
    let fields: Vec[i32] = Vec.new()
    fields.push(op)
    let no_names: Vec[i32] = Vec.new()
    no_names.push(0)
    let fid = self.body.new_agg_fields(fields, no_names)
    let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fid, 0)
    let tmp = self.new_temp(ok_type_id)
    let place = self.place_for_local(tmp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(expr))
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_implicit_default_return(self: MirBuilder, type_id: i32) -> i32:
    if type_id == self.sema.ty_void:
        return self.unit_operand()
    if self.sema.get_type_kind(type_id) == TypeKind.TY_BOOL:
        return self.lower_bool_lit(0)
    self.lower_int_lit(0, type_id)

fn MirBuilder.option_payload_type(self: MirBuilder, option_ty: i32) -> i32:
    if option_ty == 0:
        return 0
    let resolved = self.sema.resolve_alias(option_ty as TypeId)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.sema.get_generic_inst_base(resolved as i32) != self.sema.syms.option:
        return 0
    if self.sema.get_generic_inst_arg_count(resolved as i32) <= 0:
        return 0
    self.sema.get_generic_inst_arg(resolved as i32, 0)

fn MirBuilder.generic_inst_arg_type(self: MirBuilder, type_id: i32, base_sym: i32, index: i32) -> i32:
    if type_id == 0:
        return 0
    let resolved = self.sema.resolve_alias(type_id as TypeId)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.sema.get_generic_inst_base(resolved as i32) != base_sym:
        return 0
    if self.sema.get_generic_inst_arg_count(resolved as i32) <= index:
        return 0
    self.sema.get_generic_inst_arg(resolved as i32, index)

fn MirBuilder.option_some_index(self: MirBuilder, option_ty: i32) -> i32:
    let idx = self.enum_variant_index_for_type(option_ty, self.sema.syms.some)
    if idx >= 0:
        return idx
    self.success_variant_index()

fn MirBuilder.lower_optional_chain_field(self: MirBuilder, result_place: i32, result_ty: i32, base_place: i32, base_ty: i32, member_sym: i32, span: i32):
    let payload_ty = self.option_payload_type(base_ty)
    if payload_ty == 0:
        self.mark_unsupported()
        return

    let some_idx = self.option_some_index(base_ty)
    let downcast_place = self.body.new_downcast_place(base_place, some_idx, base_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, payload_ty)
    let field_ty = self.sema.struct_field_type(payload_ty, member_sym)
    if field_ty == 0:
        self.mark_unsupported()
        return

    let field_place = self.body.new_field_place(payload_place, member_sym, field_ty)
    let field_op_kind = if self.sema.is_copy(field_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
    let field_op = self.body.new_operand(field_op_kind, field_place)
    if field_ty == result_ty:
        self.assign_operand_to_place(result_place, field_op, span)
        return

    let some_fields: Vec[i32] = Vec.new()
    some_fields.push(field_op)
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, some_fields, span)

fn MirBuilder.lower_intrinsic_call_with_receiver_operand(self: MirBuilder, intrinsic: MirIntrinsic, recv_op: i32, recv_type: i32, method_sym: i32, arg_start: i32, arg_count: i32, ret_type: i32, node: i32) -> i32:
    let fn_op = self.const_operand(ConstKind.CK_FN, method_sym, self.sema.ty_void)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(recv_op)
    for ai in 0..arg_count:
        call_args.push(self.lower_method_arg_with_expected(recv_type, method_sym, self.ast.get_extra(arg_start + ai), ai))

    let args_id = self.body.new_call_args(call_args)
    self.body.set_call_ast_node(args_id, node)
    let result_local = self.new_temp(ret_type)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, intrinsic)
    if self.sema.is_copy(ret_type) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_optional_chain_receiver_operand(self: MirBuilder, payload_place: i32, payload_ty: i32, sig_idx: i32, span: i32) -> i32:
    if sig_idx >= 0 and self.sema.sig_get_param_count(sig_idx) > 0:
        let expected_ty = self.sema.sig_param_type(sig_idx, 0)
        if expected_ty != 0 and self.sema.can_auto_ref_arg(expected_ty, payload_ty) != 0:
            let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, payload_place, 0)
            let temp = self.new_temp(expected_ty)
            let temp_place = self.place_for_local(temp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, span)
            return self.body.new_operand(OperandKind.OK_COPY, temp_place)
    let op_kind = if self.sema.is_copy(payload_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
    self.body.new_operand(op_kind, payload_place)

fn MirBuilder.operand_for_place(self: MirBuilder, place: i32, type_id: i32) -> i32:
    let op_kind = if self.sema.is_copy(type_id) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
    self.body.new_operand(op_kind, place)

fn MirBuilder.lower_call_with_operand_args(self: MirBuilder, fn_op: i32, args: Vec[i32], ret_type: i32, node: i32) -> i32:
    let args_id = self.body.new_call_args(args)
    self.body.set_call_ast_node(args_id, node)
    let result_local = self.new_temp(ret_type)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    if self.sema.is_copy(ret_type) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_call_with_receiver_operand(self: MirBuilder, fn_op: i32, callee_sym: i32, recv_op: i32, arg_start: i32, arg_count: i32, ret_type: i32, node: i32) -> i32:
    let sig_idx = self.call_sig_for_sym(callee_sym)
    let args: Vec[i32] = Vec.new()
    args.push(recv_op)
    for ai in 0..arg_count:
        args.push(self.lower_call_arg(self.ast.get_extra(arg_start + ai), sig_idx, 0, ai + 1))
    let args_id = self.body.new_call_args(args)
    self.body.set_call_ast_node(args_id, node)
    let result_local = self.new_temp(ret_type)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    if self.sema.is_copy(ret_type) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_optional_chain_method(self: MirBuilder, result_place: i32, result_ty: i32, base_place: i32, base_ty: i32, member_sym: i32, extra_start: i32, node: i32):
    let payload_ty = self.option_payload_type(base_ty)
    if payload_ty == 0:
        self.mark_unsupported()
        return
    let raw_ret_ty = self.sema.optional_chain_method_raw_result_type(payload_ty, member_sym)
    if raw_ret_ty == 0:
        self.mark_unsupported()
        return

    let some_idx = self.option_some_index(base_ty)
    let downcast_place = self.body.new_downcast_place(base_place, some_idx, base_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, payload_ty)
    let method_name = self.pool.resolve_symbol(member_sym)
    let arg_count = self.ast.optional_chain_arg_count(extra_start)
    let arg_start = self.ast.optional_chain_arg_start(extra_start)
    var raw_op = 0

    let intrinsic = self.classify_intrinsic(payload_ty, method_name)
    if intrinsic != MirIntrinsic.NONE:
        let payload_op_kind = if self.sema.is_copy(payload_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
        let payload_op = self.body.new_operand(payload_op_kind, payload_place)
        raw_op = self.lower_intrinsic_call_with_receiver_operand(intrinsic, payload_op, payload_ty, member_sym, arg_start, arg_count, raw_ret_ty, node)
    else:
        let recv_resolved = self.sema.auto_deref_ref_ptr_type(payload_ty as TypeId) as i32
        let owner_sym = self.sema.method_owner_symbol_for_type(recv_resolved)
        let callee_sym = if owner_sym != 0: self.sema.lookup_method_fn(owner_sym, member_sym) else: 0
        if callee_sym == 0:
            self.mark_unsupported()
            return
        let fn_op = self.lower_var(callee_sym, 0, 0)
        let sig_idx = self.call_sig_for_sym(callee_sym)
        let recv_op = self.lower_optional_chain_receiver_operand(payload_place, payload_ty, sig_idx, self.ast.get_start(node))
        raw_op = self.lower_call_with_receiver_operand(fn_op, callee_sym, recv_op, arg_start, arg_count, raw_ret_ty, node)

    if raw_ret_ty == result_ty:
        self.assign_operand_to_place(result_place, raw_op, self.ast.get_start(node))
        return

    let some_fields: Vec[i32] = Vec.new()
    some_fields.push(raw_op)
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, some_fields, self.ast.get_start(node))

fn MirBuilder.lower_pipeline(self: MirBuilder, lhs_expr: i32, fn_expr: i32, args_start: i32, args_count: i32, node: i32) -> i32:
    if self.sema.pipeline_method_calls.contains(node):
        let method_sym = self.sema.pipeline_method_calls.get(node).unwrap()
        return self.lower_method_call(lhs_expr, method_sym, args_start, args_count, node)
    let fn_op = self.lower_expr(fn_expr)
    let callee_sym =
        if fn_expr != 0 and self.ast.kind(fn_expr) == NodeKind.NK_IDENT:
            self.ast.get_data0(fn_expr)
        else:
            0
    let arg_nodes: Vec[i32] = Vec.new()
    arg_nodes.push(lhs_expr)
    for i in 0..args_count:
        arg_nodes.push(self.ast.get_extra(args_start + i))
    self.lower_call_with_arg_nodes(fn_op, callee_sym, arg_nodes, self.expr_type(node), node)

fn MirBuilder.lower_closure(self: MirBuilder, _captured_start: i32, _captured_count: i32, _params_start: i32, _params_count: i32, node: i32) -> i32:
    // Emit ConstKind.CK_CLOSURE so MIR codegen can delegate to gen_closure.
    // The closure body is compiled as a separate function by AST codegen.
    let ty = self.expr_type(node)
    if ty == 0:
        return self.unit_operand()
    let tmp = self.new_temp(ty)
    let place = self.place_for_local(tmp)
    let closure_const = self.body.new_const(ConstKind.CK_CLOSURE, node, 0, 0, ty)
    let op = self.body.new_operand(OperandKind.OK_CONSTANT, closure_const)
    let rv = self.body.new_rvalue(RvalueKind.RK_USE, op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_optional_chain(self: MirBuilder, node: i32) -> i32:
    let base_expr = self.ast.get_data0(node)
    let member_sym = self.ast.get_data1(node)
    let extra_start = self.ast.get_data2(node)
    let is_call = self.ast.optional_chain_is_call(extra_start)

    let base_op = self.lower_expr(base_expr)
    let base_ty = self.expr_type(base_expr)
    let base_place = self.materialize_operand(base_op, base_ty, self.ast.get_start(base_expr))

    let some_bb = self.new_block()
    let none_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(base_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.option_some_index(base_ty))
    let targets: Vec[i32] = Vec.new()
    targets.push(some_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, none_bb, 0)

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(some_bb)
    if is_call != 0:
        self.lower_optional_chain_method(result_place, result_ty, base_place, base_ty, member_sym, extra_start, node)
    else:
        self.lower_optional_chain_field(result_place, result_ty, base_place, base_ty, member_sym, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(none_bb)
    let none_fields: Vec[i32] = Vec.new()
    self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.none, none_fields, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    self.forget_string_flow_facts()
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_expr(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.unit_operand()

    self.cur_node = node
    let kind = self.ast.kind(node)

    if kind == NodeKind.NK_INT_LIT:
        return self.lower_int_lit_node(node, self.expr_type(node))

    if kind == NodeKind.NK_BOOL_LIT:
        return self.lower_bool_lit(self.ast.get_data0(node))

    if kind == NodeKind.NK_REGEX_LIT:
        return self.lower_regex_literal(node)

    if kind == NodeKind.NK_MATCH_OP:
        return self.lower_regex_match_expr(node)

    if kind == NodeKind.NK_NEG_MATCH_OP:
        let match_op = self.lower_regex_match_expr(node)
        let one = self.lower_bool_lit(1)
        let rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_NEQ, match_op, one)
        let tmp = self.new_temp(self.sema.ty_bool)
        let place = self.place_for_local(tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, place)

    if kind == NodeKind.NK_STRING_LIT:
        return self.lower_str_lit_as(self.ast.get_data0(node), self.expr_type(node))
    if kind == NodeKind.NK_C_STRING_LIT:
        return self.lower_c_str_lit(self.ast.get_data0(node))

    if kind == NodeKind.NK_FSTRING:
        return self.lower_fstring(node)

    if kind == NodeKind.NK_FLOAT_LIT:
        return self.lower_float_lit(self.ast.get_data0(node), self.expr_type(node))

    if kind == NodeKind.NK_NULL_LIT:
        // Null pointer literal: lower as integer 0 (codegen emits wl_const_null for ptr targets)
        return self.const_operand(ConstKind.CK_INT, 0, self.sema.ty_i32)

    if kind == NodeKind.NK_POISONED_EXPR:
        return self.unit_operand()

    if kind == NodeKind.NK_UNSAFE_BLOCK:
        // Transparent pass-through: just lower the inner body
        return self.lower_expr(self.ast.get_data0(node))

    if kind == NodeKind.NK_NO_SUSPEND:
        self.no_suspend_nodes.push(node)
        let result = self.lower_expr(self.ast.get_data0(node))
        self.no_suspend_nodes.pop()
        return result

    if kind == NodeKind.NK_ASM_EXPR:
        // Inline assembly — emit as a call with MirIntrinsic.ASM marker
        // Lower input expression values as MIR args
        let asm_packed_d2 = self.ast.get_data2(node)
        let asm_extra_start = asm_packed_d2 >> 8
        let asm_args: Vec[i32] = Vec.new()
        if asm_extra_start > 0:
            let asm_input_count = self.ast.get_extra(asm_extra_start + 1)
            for asm_ii in 0..asm_input_count:
                let asm_in_node = self.ast.get_extra(asm_extra_start + 2 + asm_ii)
                asm_args.push(self.lower_expr(asm_in_node))
        let asm_args_id = self.body.new_call_args(asm_args)
        self.body.set_call_intrinsic(asm_args_id, MirIntrinsic.ASM)
        self.body.set_call_ast_node(asm_args_id, node)
        let asm_ret_ty = self.expr_type(node)
        let asm_result_local = self.new_temp(asm_ret_ty)
        let asm_result_place = self.place_for_local(asm_result_local)
        let asm_callee = self.unit_operand()
        let asm_next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, asm_callee, asm_args_id, asm_result_place, asm_next_bb)
        self.switch_to(asm_next_bb)
        if asm_ret_ty != self.sema.ty_void as i32:
            return self.body.new_operand(OperandKind.OK_COPY, asm_result_place)
        return self.unit_operand()

    if kind == NodeKind.NK_COMPTIME_ERROR:
        // Emit unreachable — if this code is ever reached, it's a compile error
        self.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)
        let dead_bb = self.new_block()
        self.switch_to(dead_bb)
        return self.unit_operand()

    if kind == NodeKind.NK_IDENT:
        let magic_kind = self.magic_ident_kind(node)
        if magic_kind != 0:
            return self.lower_magic_ident(magic_kind, node)
        return self.lower_var(self.ast.get_data0(node), self.expr_type(node), node)

    if kind == NodeKind.NK_BINARY:
        let op = self.ast.get_data0(node)
        let lhs = self.ast.get_data1(node)
        let rhs = self.ast.get_data2(node)
        if op == BinaryOp.OP_DEFAULT:
            return self.lower_double_question(lhs, rhs, node)
        return self.lower_bin_op(op, lhs, rhs, node)

    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        let operand = self.ast.get_data1(node)
        if op == UnaryOp.UOP_TRY:
            return self.lower_question_mark(operand, node)
        return self.lower_un_op(op, operand, node)

    if kind == NodeKind.NK_CAST:
        // Read pre-resolved cast type from sema sidecar (avoids add_type on
        // shallow-copied Sema — see resolve_type_expr aliasing bug).
        var cast_tid = 0
        if self.sema.typed_expr_types.contains(node):
            cast_tid = self.sema.typed_expr_types.get(node).unwrap() as i32
        else:
            cast_tid = self.sema.resolve_type_expr(self.ast.get_data1(node)) as i32
        return self.lower_cast(self.ast.get_data0(node), cast_tid, node)

    if kind == NodeKind.NK_FIELD_ACCESS:
        let fa_base = self.ast.get_data0(node)
        let fa_field = self.ast.get_data1(node)
        // Distinct type .value access: transparent (no-op)
        let fa_base_type = self.expr_type(fa_base)
        if fa_base_type > 0:
            let fa_base_resolved = self.sema.resolve_alias(fa_base_type)
            let fa_base_sym = self.sema.get_type_d0(fa_base_resolved)
            if fa_base_sym > 0 and self.sema.distinct_type_names.contains(fa_base_sym):
                return self.lower_expr(fa_base)
        // Enum variant access: Color.Red → discriminant value constant
        if self.ast.kind(fa_base) == NodeKind.NK_IDENT:
            let fa_base_sym = self.ast.get_data0(fa_base)
            if self.sema.named_types.contains(fa_base_sym):
                let fa_base_ty = self.sema.named_types.get(fa_base_sym).unwrap()
                let fa_resolved = self.sema.resolve_alias(fa_base_ty)
                let fa_tk = self.sema.get_type_kind(fa_resolved)
                if fa_tk == TypeKind.TY_ENUM:
                    // Build qualified variant key: "Color.Red"
                    let fa_type_name = self.pool.resolve(fa_base_sym)
                    let fa_field_name = self.pool.resolve(fa_field)
                    let fa_qual_name = fa_type_name ++ "." ++ fa_field_name
                    let fa_qual_sym = self.pool.intern(fa_qual_name)
                    if self.sema.variant_lookup.contains(fa_qual_sym):
                        let fa_disc_tag = self.enum_variant_discriminant_for_type(fa_base_ty, fa_qual_sym)
                        // Plain enums are always lowered as full aggregate values.
                        // Only payloadless discriminant enums lower to their repr integer.
                        let fa_is_disc_enum = self.sema.disc_repr_types.contains(fa_resolved as i32)
                        if not fa_is_disc_enum or self.sema.disc_has_payload.contains(fa_resolved as i32):
                            let fa_fields: Vec[i32] = Vec.new()
                            let fa_names: Vec[i32] = Vec.new()
                            let fa_fid = self.body.new_agg_fields(fa_fields, fa_names)
                            let fa_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fa_fid, fa_disc_tag)
                            let fa_tmp = self.new_temp(fa_base_ty)
                            let fa_place = self.place_for_local(fa_tmp)
                            self.body.push_stmt(self.cur_bb, StmtKind.Assign, fa_place, fa_rv, self.ast.get_start(node))
                            return self.body.new_operand(OperandKind.OK_COPY, fa_place)
                        return self.int_const_operand(fa_disc_tag as i64, fa_base_ty)
                    // Also try bare variant sym (some enums register just "Red")
                    if self.sema.variant_lookup.contains(fa_field):
                        let fa_var_tid = self.sema.variant_type_ids.get(fa_field).unwrap()
                        if fa_var_tid == fa_resolved:
                            let fa_disc_tag2 = self.enum_variant_discriminant_for_type(fa_base_ty, fa_field)
                            let fa_is_disc_enum2 = self.sema.disc_repr_types.contains(fa_resolved as i32)
                            if not fa_is_disc_enum2 or self.sema.disc_has_payload.contains(fa_resolved as i32):
                                let fa_fields2: Vec[i32] = Vec.new()
                                let fa_names2: Vec[i32] = Vec.new()
                                let fa_fid2 = self.body.new_agg_fields(fa_fields2, fa_names2)
                                let fa_rv2 = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fa_fid2, fa_disc_tag2)
                                let fa_tmp2 = self.new_temp(fa_base_ty)
                                let fa_place2 = self.place_for_local(fa_tmp2)
                                self.body.push_stmt(self.cur_bb, StmtKind.Assign, fa_place2, fa_rv2, self.ast.get_start(node))
                                return self.body.new_operand(OperandKind.OK_COPY, fa_place2)
                            return self.int_const_operand(fa_disc_tag2 as i64, fa_base_ty)
        let place = self.lower_field_access(node)
        return self.body.new_operand(OperandKind.OK_COPY, place)

    if kind == NodeKind.NK_INDEX:
        let vec_ty = self.vec_literal_type(node)
        if vec_ty != 0:
            return self.lower_vec_literal(node, vec_ty)
        if self.is_runtime_pair_multi_index(node) != 0:
            let mi_place = self.lower_multi_index_read(node)
            return self.body.new_operand(OperandKind.OK_COPY, mi_place)
        var ip_rd_base_ty = self.expr_type(self.ast.get_data0(node))
        while ip_rd_base_ty > 0 and self.sema.get_type_kind(self.sema.resolve_alias(ip_rd_base_ty)) == TypeKind.TY_REF:
            ip_rd_base_ty = self.sema.get_type_d0(self.sema.resolve_alias(ip_rd_base_ty))
        if self.is_user_index_place(ip_rd_base_ty) != 0:
            let ip_get_sym = self.sema.pool_lookup_symbol("get")
            let ip_rd_type_sym = self.sema.get_type_name(ip_rd_base_ty)
            let ip_rd_fn_sym = self.sema.lookup_method_fn(ip_rd_type_sym, ip_get_sym)
            if ip_rd_fn_sym != 0:
                let ip_rd_recv_op = self.lower_expr(self.ast.get_data0(node))
                let ip_rd_idx_op = self.lower_expr(self.ast.get_data1(node))
                let ip_rd_ret_ty = self.expr_type(node)
                let ip_rd_fn_op = self.const_operand(ConstKind.CK_FN, ip_rd_fn_sym, ip_rd_ret_ty)
                let ip_rd_args: Vec[i32] = Vec.new()
                ip_rd_args.push(ip_rd_recv_op)
                ip_rd_args.push(ip_rd_idx_op)
                let ip_rd_args_id = self.body.new_call_args(ip_rd_args)
                let ip_rd_result = self.new_temp(ip_rd_ret_ty)
                let ip_rd_place = self.place_for_local(ip_rd_result)
                let ip_rd_next = self.new_block()
                self.terminate(TermKind.TK_CALL, ip_rd_fn_op, ip_rd_args_id, ip_rd_place, ip_rd_next)
                self.switch_to(ip_rd_next)
                return self.body.new_operand(OperandKind.OK_COPY, ip_rd_place)
        let place = self.lower_index(self.ast.get_data0(node), self.ast.get_data1(node))
        return self.body.new_operand(OperandKind.OK_COPY, place)

    if kind == NodeKind.NK_MULTI_INDEX:
        let mi_place = self.lower_multi_index_read(node)
        return self.body.new_operand(OperandKind.OK_COPY, mi_place)

    if kind == NodeKind.NK_BLOCK:
        return self.lower_block(node)

    if kind == NodeKind.NK_LABEL:
        return self.lower_label(node)

    if kind == NodeKind.NK_GOTO:
        return self.lower_goto(node)

    if kind == NodeKind.NK_LET_BINDING:
        self.lower_let_binding(node)
        return self.unit_operand()

    if kind == NodeKind.NK_LET_ELSE:
        self.lower_let_else(node)
        return self.unit_operand()

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        self.lower_tuple_destructure(node)
        return self.unit_operand()

    if kind == NodeKind.NK_DEFER:
        let defer_body = self.ast.get_data0(node)
        if defer_body != 0:
            self.defer_nodes.push(defer_body)
        return self.unit_operand()

    if kind == NodeKind.NK_ERRDEFER:
        let errdefer_body = self.ast.get_data0(node)
        if errdefer_body != 0:
            self.errdefer_nodes.push(errdefer_body)
        return self.unit_operand()

    if kind == NodeKind.NK_ASSIGN:
        let target = self.ast.get_data0(node)
        let rhs_node = self.ast.get_data1(node)
        let append_place = self.try_lower_string_self_concat_assign(target, rhs_node)
        if append_place >= 0:
            let append_local = self.direct_place_local(append_place)
            if append_local >= 0:
                self.mark_string_local_copied(append_local)
            return self.body.new_operand(OperandKind.OK_COPY, append_place)
        // Lower the RHS first so we have its value available, then perform the
        // assignment. The expression value of `lhs = rhs` is `rhs` per C/With
        // semantics — NOT a re-load of `*lhs`. The previous code did
        // `lower_assign(target, rhs); lower_expr_place(target); OK_COPY`,
        // which emitted an unconditional load through `*lhs` after the store.
        // For `*lengthptr = *lengthptr + length`, that meant a third
        // `load i64, ptr lengthptr` that LLVM treated as an unconditional
        // dereference, propagating "lengthptr is non-null" out of the guarded
        // block and constant-folding the surrounding null check.
        let saved_expected = self.expected_type
        let target_ty = self.expr_type(target)
        if target_ty != 0 and target_ty != self.sema.ty_void as i32:
            self.expected_type = target_ty
        let rhs_op = self.lower_expr(rhs_node)
        self.expected_type = saved_expected
        let place = self.lower_expr_place(target)
        if target_ty != 0 and self.sema.is_copy(target_ty) == 0:
            let resolved_ty = self.sema.resolve_alias(target_ty)
            let tk = self.sema.get_type_kind(resolved_ty)
            if tk == TypeKind.TY_STRUCT:
                let type_name = self.sema.get_type_d0(resolved_ty)
                if self.sema.has_drop_method(type_name) != 0:
                    self.body.push_stmt(self.cur_bb, StmtKind.Drop, place, 0, self.ast.get_start(target))
        self.assign_operand_to_place(place, rhs_op, self.ast.get_start(target))
        return rhs_op

    if kind == NodeKind.NK_IF_EXPR:
        return self.lower_if(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node, 1)

    if kind == NodeKind.NK_WHILE:
        return self.lower_while(self.ast.get_data0(node), self.ast.get_data1(node), node)

    if kind == NodeKind.NK_DO_WHILE:
        return self.lower_do_while(self.ast.get_data0(node), self.ast.get_data1(node), node)

    if kind == NodeKind.NK_LOOP:
        return self.lower_loop(self.ast.get_data0(node), node)

    if kind == NodeKind.NK_FOR:
        return self.lower_for(node)

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        return self.lower_array_comprehension(node)

    if kind == NodeKind.NK_BREAK:
        return self.lower_break(node)

    if kind == NodeKind.NK_CONTINUE:
        return self.lower_continue(node)

    if kind == NodeKind.NK_RETURN:
        return self.lower_return(node)

    if kind == NodeKind.NK_MATCH:
        return self.lower_match(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NodeKind.NK_CALL:
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
            // Distinguish method syntax from a callable field like
            // `ctx.memctl.free(...)`, which should lower as an indirect call.
            if self.callable_fn_type_for_expr(callee) != 0:
                return self.lower_call(callee, self.ast.get_data1(node), self.ast.get_data2(node), self.expr_type(node), node)
            return self.lower_method_call(self.ast.get_data0(callee), self.ast.get_data1(callee), self.ast.get_data1(node), self.ast.get_data2(node), node)
        var generic_builtin_sym = 0
        if self.ast.kind(callee) == NodeKind.NK_INDEX or self.ast.kind(callee) == NodeKind.NK_TYPE_GENERIC:
            let gb_base = self.ast.get_data0(callee)
            if self.ast.kind(gb_base) == NodeKind.NK_IDENT:
                let gb_sym = self.ast.get_data0(gb_base)
                let gb_name = self.pool.resolve(gb_sym)
                if gb_name == "transmute" or gb_name == "sizeof" or gb_name == "size_of" or gb_name == "alignof" or gb_name == "align_of" or gb_name == "nameof" or gb_name == "type_name" or gb_name == "chan":
                    generic_builtin_sym = gb_sym
        if generic_builtin_sym > 0:
            let gc_fn_op = self.const_operand(ConstKind.CK_FN, generic_builtin_sym, 0)
            let gc_args: Vec[i32] = Vec.new()
            let gc_as = self.ast.get_data1(node)
            let gc_ac = self.ast.get_data2(node)
            for gc_ai in 0..gc_ac:
                let gc_arg_node = self.ast.get_extra(gc_as + gc_ai)
                gc_args.push(self.lower_expr(gc_arg_node))
            let gc_args_id = self.body.new_call_args(gc_args)
            self.body.set_call_intrinsic(gc_args_id, MirIntrinsic.GENERIC_CALL)
            self.body.set_call_ast_node(gc_args_id, node)
            var gc_ret_ty = self.expr_type(node)
            if gc_ret_ty == 0:
                gc_ret_ty = self.sema.ty_i32 as i32
            let gc_result = self.new_temp(gc_ret_ty)
            let gc_place = self.place_for_local(gc_result)
            let gc_next = self.new_block()
            self.terminate(TermKind.TK_CALL, gc_fn_op, gc_args_id, gc_place, gc_next)
            self.switch_to(gc_next)
            return self.body.new_operand(OperandKind.OK_COPY, gc_place)
        // Check for enum variant constructor call: Some(v), Ok(v), Err(e), etc.
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            var vc_sym = self.ast.get_data0(callee)
            // Resolve for-comprehension _Payload marker
            if self.sema.comp_resolved.contains(node):
                vc_sym = self.sema.comp_resolved.get(node).unwrap()
            if self.sema.variant_lookup.contains(vc_sym):
                var vc_result_ty = self.expr_type(node)
                if self.expected_type != 0:
                    vc_result_ty = self.expected_type
                if vc_result_ty == 0:
                    vc_result_ty = self.sema.variant_type_ids.get(vc_sym).unwrap()
                var vc_variant_idx = self.enum_variant_discriminant_for_type(vc_result_ty, vc_sym)
                if vc_variant_idx < 0:
                    vc_variant_idx = self.sema.variant_lookup.get(vc_sym).unwrap()
                let vc_payload_tys = self.sema.enum_variant_payload_types(vc_result_ty, vc_sym)
                let vc_args_start = self.ast.get_data1(node)
                let vc_has_resolved = self.sema.has_resolved_call_args(node)
                let vc_args_count = if vc_has_resolved != 0: self.sema.get_resolved_call_arg_count(node) else: self.ast.get_data2(node)
                let vc_fields: Vec[i32] = Vec.new()
                let vc_names: Vec[i32] = Vec.new()
                for vci in 0..vc_args_count:
                    let vc_arg = if vc_has_resolved != 0: self.sema.get_resolved_call_arg(node, vci) else: self.ast.get_extra(vc_args_start + vci)
                    let saved_expected = self.expected_type
                    if vci < vc_payload_tys.len() as i32:
                        let payload_ty = vc_payload_tys.get(vci as i64)
                        if payload_ty != 0:
                            self.expected_type = payload_ty
                    vc_fields.push(if vc_arg == 0: self.unit_operand() else: self.lower_expr(vc_arg))
                    self.expected_type = saved_expected
                    vc_names.push(0)
                let vc_fid = self.body.new_agg_fields(vc_fields, vc_names)
                let vc_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, vc_fid, vc_variant_idx)
                let vc_tmp = self.new_temp(vc_result_ty)
                let vc_place = self.place_for_local(vc_tmp)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, vc_place, vc_rv, self.ast.get_start(node))
                return self.body.new_operand(OperandKind.OK_COPY, vc_place)
        // Distinct type constructor: Meters(42) → transparent (just the inner value)
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let dt_sym = self.ast.get_data0(callee)
            if self.sema.distinct_type_names.contains(dt_sym):
                let dt_tid = self.sema.distinct_type_names.get(dt_sym).unwrap()
                let dt_args_start = self.ast.get_data1(node)
                let dt_args_count = self.ast.get_data2(node)
                if dt_args_count == 1:
                    let dt_arg = self.ast.get_extra(dt_args_start)
                    let dt_val = self.lower_expr(dt_arg)
                    // Transparent: distinct types have same LLVM type as inner,
                    // so the constructor is just the inner value itself
                    return dt_val
        // Callable type syntax: TypeName(args) → TypeName.new(args)
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let ct_sym = self.ast.get_data0(callee)
            if self.sema.type_decl_nodes.contains(ct_sym):
                let ct_new_name = self.pool.resolve(ct_sym) ++ ".new"
                let ct_new_sym = self.pool.intern(ct_new_name)
                let ct_new_sig = self.sema.get_sig(ct_new_sym)
                if ct_new_sig >= 0:
                    let ct_fn_op = self.const_operand(ConstKind.CK_FN, ct_new_sym, 0)
                    let ct_ret_ty = self.expr_type(node)
                    return self.lower_call_redirected(ct_fn_op, ct_new_sym, self.ast.get_data1(node), self.ast.get_data2(node), ct_ret_ty, node)
        // Generic function call — delegate to codegen's monomorphize_generic_call
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let gc_sym = self.ast.get_data0(callee)
            if self.sema.fn_symbol_is_std_builtins_drop(gc_sym) != 0:
                return self.lower_std_drop_call(node)
            if self.sema.generic_fn_nodes.contains(gc_sym):
                // Lower args and emit call. Codegen intercepts via MirIntrinsic.GENERIC_CALL
                // and routes to monomorphize_generic_call_core with pre-evaluated MIR args.
                let gc_fn_op = self.const_operand(ConstKind.CK_FN, gc_sym, 0)
                let gc_args: Vec[i32] = Vec.new()
                let gc_as = self.ast.get_data1(node)
                let gc_ac = self.ast.get_data2(node)
                for gc_ai in 0..gc_ac:
                    let gc_arg_node = self.ast.get_extra(gc_as + gc_ai)
                    gc_args.push(self.lower_expr(gc_arg_node))
                // Fill default values for omitted trailing parameters, the same
                // as non-generic calls do in lower_call (#302).
                let gc_meta = self.ast.find_fn_meta(self.sema.generic_fn_nodes.get(gc_sym).unwrap())
                if gc_meta >= 0:
                    let gc_ps = self.ast.fn_meta_param_start(gc_meta)
                    let gc_pc = self.ast.fn_meta_param_count(gc_meta)
                    for gc_di in gc_ac..gc_pc:
                        let gc_def = self.ast.get_fn_param_default(gc_ps, gc_di)
                        if gc_def != 0:
                            gc_args.push(self.lower_default_call_arg(gc_def, node, -1, 0, gc_di))
                let gc_args_id = self.body.new_call_args(gc_args)
                self.body.set_call_intrinsic(gc_args_id, MirIntrinsic.GENERIC_CALL)
                self.body.set_call_ast_node(gc_args_id, node)
                var gc_ret_ty = self.expr_type(node)
                if gc_ret_ty == 0:
                    gc_ret_ty = self.sema.ty_i32 as i32
                let gc_result = self.new_temp(gc_ret_ty)
                let gc_place = self.place_for_local(gc_result)
                let gc_next = self.new_block()
                self.terminate(TermKind.TK_CALL, gc_fn_op, gc_args_id, gc_place, gc_next)
                self.switch_to(gc_next)
                return self.body.new_operand(OperandKind.OK_COPY, gc_place)
        // Check for builtin calls (embed_file, src, etc.) — no sig, not a local
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let bu_sym = self.ast.get_data0(callee)
            let bu_sig = self.sema.get_sig(bu_sym)
            let bu_local = self.lookup_local(bu_sym)
            if bu_sig < 0 and bu_local < 0:
                // Unresolved bare function — route through gen_call
                let bu_fn_op = self.const_operand(ConstKind.CK_FN, bu_sym, 0)
                let bu_args: Vec[i32] = Vec.new()
                let bu_args_id = self.body.new_call_args(bu_args)
                self.body.set_call_intrinsic(bu_args_id, MirIntrinsic.GENERIC_CALL)
                self.body.set_call_ast_node(bu_args_id, node)
                var bu_ret_ty = self.expr_type(node)
                if bu_ret_ty == 0:
                    bu_ret_ty = self.sema.ty_i32 as i32
                let bu_result = self.new_temp(bu_ret_ty)
                let bu_place = self.place_for_local(bu_result)
                let bu_next = self.new_block()
                self.terminate(TermKind.TK_CALL, bu_fn_op, bu_args_id, bu_place, bu_next)
                self.switch_to(bu_next)
                return self.body.new_operand(OperandKind.OK_COPY, bu_place)
        // Intrinsic free functions: fence(order)
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let ifn_sym = self.ast.get_data0(callee)
            let ifn_name = self.pool.resolve(ifn_sym)
            if ifn_name == "fence":
                let ifn_args: Vec[i32] = Vec.new()
                let ifn_as = self.ast.get_data1(node)
                let ifn_ac = self.ast.get_data2(node)
                for ifn_ai in 0..ifn_ac:
                    ifn_args.push(self.lower_expr(self.ast.get_extra(ifn_as + ifn_ai)))
                let ifn_args_id = self.body.new_call_args(ifn_args)
                self.body.set_call_intrinsic(ifn_args_id, MirIntrinsic.ATOMIC_FENCE)
                let ifn_callee = self.unit_operand()
                let ifn_result = self.new_temp(self.sema.ty_void as i32)
                let ifn_place = self.place_for_local(ifn_result)
                let ifn_next = self.new_block()
                self.terminate(TermKind.TK_CALL, ifn_callee, ifn_args_id, ifn_place, ifn_next)
                self.switch_to(ifn_next)
                return self.unit_operand()
        return self.lower_call(callee, self.ast.get_data1(node), self.ast.get_data2(node), self.expr_type(node), node)

    if kind == NodeKind.NK_PIPELINE:
        let rhs = self.ast.get_data1(node)
        if self.ast.kind(rhs) == NodeKind.NK_CALL:
            return self.lower_pipeline(self.ast.get_data0(node), self.ast.get_data0(rhs), self.ast.get_data1(rhs), self.ast.get_data2(rhs), node)
        return self.lower_pipeline(self.ast.get_data0(node), rhs, 0, 0, node)

    if kind == NodeKind.NK_WITH_EXPR:
        let source = self.ast.get_data0(node)
        let body = self.ast.get_data1(node)
        let name = decode_with_binding_sym(self.ast.get_data2(node))
        if self.sema.with_form_kinds.contains(node):
            let form = self.sema.with_form_kinds.get(node).unwrap()
            if form == WithFormKind.Guarded or form == WithFormKind.GuardedMut:
                return self.lower_with_guarded(node)
        if name != 0:
            return self.lower_with_binding(name, source, body, self.ast.get_start(node))
        return self.lower_with_form1(source, body)

    if kind == NodeKind.NK_WITH_IMPLICIT:
        let wi_source = self.ast.get_data0(node)
        let wi_body = self.ast.get_data1(node)
        let wi_name = self.ast.get_data2(node)
        return self.lower_with_binding(wi_name, wi_source, wi_body, self.ast.get_start(node))

    if kind == NodeKind.NK_WITH_TUPLE:
        return self.lower_with_tuple(node)

    if kind == NodeKind.NK_STRUCT_LIT:
        let sl_fields_start = self.ast.get_data1(node)
        let sl_field_count = self.ast.get_data2(node)
        let sl_name_sym = self.ast.get_data0(node)
        let sl_struct_ty = self.expr_type(node)
        let sl_fields: Vec[i32] = Vec.new()
        let sl_names: Vec[i32] = Vec.new()
        for i in 0..sl_field_count:
            let f_name_sym = self.ast.get_extra(sl_fields_start + i * 2)
            let f_val_node = self.ast.get_extra(sl_fields_start + i * 2 + 1)
            let saved_expected = self.expected_type
            var resolved_name = f_name_sym
            var f_ty = 0
            if f_name_sym == 0:
                let info = self.sema.struct_field_info_by_index(sl_struct_ty, i)
                resolved_name = (info % 4294967296) as i32
                f_ty = (info / 4294967296) as i32
            else:
                f_ty = self.struct_field_type(sl_struct_ty, f_name_sym)
            if f_ty != 0:
                self.expected_type = f_ty
            sl_fields.push(self.lower_expr(f_val_node))
            sl_names.push(resolved_name)
            self.expected_type = saved_expected
        if self.sema.type_decl_nodes.contains(sl_name_sym):
            let sl_td_node = self.sema.type_decl_nodes.get(sl_name_sym).unwrap()
            let sl_td_extra = self.ast.get_data1(sl_td_node)
            let sl_td_packed = self.ast.get_data2(sl_td_node)
            if type_decl_sub_kind(sl_td_packed) == TypeDeclKind.Struct:
                let sl_decl_field_count = self.ast.get_extra(sl_td_extra)
                let sl_positional = if sl_field_count > 0: self.ast.get_extra(sl_fields_start) == 0 else: false
                for dfi in 0..sl_decl_field_count:
                    let decl_base = sl_td_extra + 1 + dfi * 3
                    let decl_field_name = self.ast.get_extra(decl_base)
                    let decl_default = self.ast.get_extra(decl_base + 2)
                    var present = false
                    if sl_positional:
                        present = dfi < sl_field_count
                    else:
                        for li in 0..sl_field_count:
                            let lit_f = self.ast.get_extra(sl_fields_start + li * 2)
                            if lit_f == decl_field_name:
                                present = true
                                break
                    if not present and decl_default != 0:
                        let saved_expected = self.expected_type
                        let info = self.sema.struct_field_info_by_index(sl_struct_ty, dfi)
                        let decl_field_ty = (info / 4294967296) as i32
                        if decl_field_ty != 0:
                            self.expected_type = decl_field_ty
                        sl_fields.push(self.lower_expr(decl_default))
                        sl_names.push(decl_field_name)
                        self.expected_type = saved_expected
        let sl_fid = self.body.new_agg_fields(sl_fields, sl_names)
        let sl_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, sl_fid, 0)
        var sl_ty = self.expr_type(node)
        if (sl_ty == 0 or sl_ty == self.sema.ty_void) and self.expected_type > 0:
            sl_ty = self.expected_type
        let sl_tmp = self.new_temp(sl_ty)
        let sl_place = self.place_for_local(sl_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, sl_place, sl_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, sl_place)

    if kind == NodeKind.NK_RECORD_UPDATE:
        return self.lower_record_update(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NodeKind.NK_RANGE:
        let range_start_node = self.ast.get_data0(node)
        let range_end_node = self.ast.get_data1(node)
        let range_inclusive = self.ast.get_data2(node)
        var range_elem = self.sema.ty_i32 as i32
        if range_start_node != 0:
            range_elem = self.expr_type(range_start_node)
        else if range_end_node != 0:
            range_elem = self.expr_type(range_end_node)
        let start_op = if range_start_node != 0: self.lower_expr(range_start_node) else: self.int_const_operand(0, range_elem)
        let end_op = self.lower_expr(range_end_node)
        let incl_op = self.int_const_operand(range_inclusive, self.sema.ty_bool)
        let range_fields: Vec[i32] = Vec.new()
        let range_names: Vec[i32] = Vec.new()
        range_fields.push(start_op)
        range_fields.push(end_op)
        range_fields.push(incl_op)
        range_names.push(0)
        range_names.push(0)
        range_names.push(0)
        let range_fid = self.body.new_agg_fields(range_fields, range_names)
        let range_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, range_fid, 0)
        let range_ty = self.expr_type(node)
        let range_tmp = self.new_temp(range_ty)
        let range_place = self.place_for_local(range_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, range_place, range_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, range_place)

    if kind == NodeKind.NK_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        if elem_count == 0:
            return self.unit_operand()
        let tup_fields: Vec[i32] = Vec.new()
        let tup_names: Vec[i32] = Vec.new()
        let saved_expected = self.expected_type
        var expected_tuple = 0
        var expected_elem_start = 0
        if saved_expected > 0:
            let expected_resolved = self.sema.resolve_alias(saved_expected)
            if self.sema.get_type_kind(expected_resolved) == TypeKind.TY_TUPLE and self.sema.get_type_d1(expected_resolved) == elem_count:
                expected_tuple = expected_resolved as i32
                expected_elem_start = self.sema.get_type_d0(expected_resolved)
        for i in 0..elem_count:
            let elem_node = self.ast.get_extra(extra_start + i)
            if expected_tuple != 0:
                self.expected_type = self.sema.type_extra.get((expected_elem_start + i) as i64)
            tup_fields.push(self.lower_expr(elem_node))
            self.expected_type = saved_expected
            tup_names.push(0)
        let tup_fid = self.body.new_agg_fields(tup_fields, tup_names)
        let tup_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, tup_fid, 0)
        let tup_ty = self.expr_type(node)
        let tup_tmp = self.new_temp(tup_ty)
        let tup_place = self.place_for_local(tup_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, tup_place, tup_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, tup_place)

    if kind == NodeKind.NK_ARRAY_LIT:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        if elem_count > 64:
            let first_node = self.ast.get_extra(extra_start)
            var is_fill = true
            for fi in 1..elem_count:
                if self.ast.get_extra(extra_start + fi) != first_node:
                    is_fill = false
                    break
            if is_fill:
                let fill_op = self.lower_expr(first_node)
                let fill_rv = self.body.new_rvalue(RvalueKind.RK_ARRAY_FILL, fill_op, elem_count, 0)
                let fill_ty = self.expr_type(node)
                let fill_tmp = self.new_temp(fill_ty)
                let fill_place = self.place_for_local(fill_tmp)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, fill_place, fill_rv, self.ast.get_start(node))
                return self.body.new_operand(OperandKind.OK_COPY, fill_place)
        let arr_fields: Vec[i32] = Vec.new()
        let arr_names: Vec[i32] = Vec.new()
        for i in 0..elem_count:
            let elem_node = self.ast.get_extra(extra_start + i)
            arr_fields.push(self.lower_expr(elem_node))
            arr_names.push(0)
        let arr_fid = self.body.new_agg_fields(arr_fields, arr_names)
        let arr_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, arr_fid, 0)
        let arr_ty = self.expr_type(node)
        let arr_tmp = self.new_temp(arr_ty)
        let arr_place = self.place_for_local(arr_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, arr_place, arr_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, arr_place)

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        var vs_name_sym = self.resolve_variant_sym(node)
        let vs_args_start = self.ast.get_data1(node)
        let vs_arg_count = self.ast.get_data2(node)
        var vs_result_ty = self.expr_type(node)
        if (vs_result_ty == 0 or vs_result_ty == self.sema.ty_void as i32) and self.expected_type != 0:
            vs_result_ty = self.expected_type
        vs_name_sym = self.resolve_comprehension_marker_variant(vs_name_sym, vs_result_ty)
        var vs_variant_idx = self.enum_variant_discriminant_for_type(vs_result_ty, vs_name_sym)
        if vs_variant_idx < 0:
            vs_variant_idx = self.variant_index(vs_name_sym)
        // Plain enums are always lowered as full aggregate values.
        // Only payloadless discriminant enums lower to their repr integer.
        if self.sema.variant_lookup.contains(vs_name_sym):
            let vs_resolved = self.sema.resolve_alias(vs_result_ty)
            if self.sema.disc_repr_types.contains(vs_resolved as i32):
                if vs_arg_count == 0:
                    let vs_is_disc_enum = self.sema.disc_repr_types.contains(vs_resolved as i32)
                    if not vs_is_disc_enum or self.sema.disc_has_payload.contains(vs_resolved as i32):
                        let vs_de_fields: Vec[i32] = Vec.new()
                        let vs_de_names: Vec[i32] = Vec.new()
                        let vs_de_fid = self.body.new_agg_fields(vs_de_fields, vs_de_names)
                        let vs_de_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, vs_de_fid, vs_variant_idx)
                        let vs_de_tmp = self.new_temp(vs_result_ty)
                        let vs_de_place = self.place_for_local(vs_de_tmp)
                        self.body.push_stmt(self.cur_bb, StmtKind.Assign, vs_de_place, vs_de_rv, self.ast.get_start(node))
                        return self.body.new_operand(OperandKind.OK_COPY, vs_de_place)
                    return self.int_const_operand(vs_variant_idx, vs_result_ty)
        let vs_fields: Vec[i32] = Vec.new()
        let vs_names: Vec[i32] = Vec.new()
        let vs_payload_tys = self.sema.enum_variant_payload_types(vs_result_ty, vs_name_sym)
        for vsi in 0..vs_arg_count:
            let vs_arg = self.ast.get_extra(vs_args_start + vsi)
            let saved_expected = self.expected_type
            if vsi < vs_payload_tys.len() as i32:
                let payload_ty = vs_payload_tys.get(vsi as i64)
                if payload_ty != 0:
                    self.expected_type = payload_ty
            vs_fields.push(self.lower_expr(vs_arg))
            self.expected_type = saved_expected
            vs_names.push(0)
        let vs_fid = self.body.new_agg_fields(vs_fields, vs_names)
        let vs_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, vs_fid, vs_variant_idx)
        let vs_tmp = self.new_temp(vs_result_ty)
        let vs_place = self.place_for_local(vs_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, vs_place, vs_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, vs_place)

    if kind == NodeKind.NK_CLOSURE:
        return self.lower_closure(0, 0, self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NodeKind.NK_GROUPED:
        return self.lower_expr(self.ast.get_data0(node))

    if kind == NodeKind.NK_MOVE_ARG:
        let inner = self.ast.get_data0(node)
        self.cancel_scheduled_value_drop_for_receiver_expr(inner)
        return self.lower_expr(inner)

    if kind == NodeKind.NK_COPY_ARG:
        let inner = self.ast.get_data0(node)
        if self.ast.state.copy_arg_needs_clone.contains(node):
            // Clone-only type: emit inner.clone()
            let clone_sym = self.pool.intern("clone")
            return self.lower_method_call(inner, clone_sym, -1, 0, node)
        return self.lower_expr(inner)

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        return self.lower_optional_chain(node)

    if kind == NodeKind.NK_COMPTIME:
        // Comptime branches are already pruned by ComptimeTransform.
        // Just unwrap and lower the inner expression.
        let inner = self.ast.get_data0(node)
        if inner != 0:
            return self.lower_expr(inner)
        return self.unit_operand()

    // expr.await → suspend until fiber completes, check cancellation,
    // emit unwind path with defers if cancelled, return result
    //
    // lower_single_await: await one Task, with cancellation checks + unwind.
    // Used by both single await and tuple await (called N times for tuple).
    // Defined inline as a nested scope to keep it near the NK_AWAIT handler.

    if kind == NodeKind.NK_AWAIT:
        let inner = self.ast.get_data0(node)

        // Tuple await: (t1, t2, ...).await → await each, build result tuple
        if self.ast.kind(inner) == NodeKind.NK_TUPLE:
            let ta_extra = self.ast.get_data0(inner)
            let ta_count = self.ast.get_data1(inner)
            let ta_result_ty = self.expr_type(node)
            // Lower all task expressions first (spawns all fibers)
            var ta_task_ops: Vec[i32] = Vec.new()
            for ta_i in 0..ta_count:
                let ta_elem = self.ast.get_extra(ta_extra + ta_i)
                self.cancel_scheduled_value_drop_for_receiver_expr(ta_elem)
                ta_task_ops.push(self.lower_expr(ta_elem))
            // Await each sequentially, collect results
            var ta_awaited_ops: Vec[i32] = Vec.new()
            var ta_awaited_names: Vec[i32] = Vec.new()
            for ta_i in 0..ta_count:
                let ta_elem_ty = self.tuple_elem_type(ta_result_ty, ta_i)
                let ta_elem_node = self.ast.get_extra(ta_extra + ta_i)
                let ta_task_ty = self.expr_type(ta_elem_node)
                let ta_op = self.lower_single_await(ta_task_ops.get(ta_i as i64), ta_elem_ty, ta_task_ty, node)
                ta_awaited_ops.push(ta_op)
                ta_awaited_names.push(0)
            // Build result tuple via RK_AGGREGATE
            let ta_agg_id = self.body.new_agg_fields(ta_awaited_ops, ta_awaited_names)
            let ta_agg_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, ta_agg_id, 0)
            let ta_tmp = self.new_temp(ta_result_ty)
            let ta_place = self.place_for_local(ta_tmp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, ta_place, ta_agg_rv, self.ast.get_start(node))
            return self.body.new_operand(OperandKind.OK_COPY, ta_place)

        // Single task await
        self.cancel_scheduled_value_drop_for_receiver_expr(inner)
        let task_op = self.lower_expr(inner)
        let result_ty = self.expr_type(node)
        let task_inner_ty = self.expr_type(inner)
        return self.lower_single_await(task_op, result_ty, task_inner_ty, node)

    if kind == NodeKind.NK_YIELD:
        let inner = self.ast.get_data0(node)
        if self.in_generator != 0:
            return self.lower_generator_yield(node)
        if inner != 0:
            let _ = self.lower_expr(inner)
        return self.unit_operand()

    if kind == NodeKind.NK_ASYNC_SCOPE:
        // async scope: d0=name(sym), d1=body(node)
        // 1. Create scope handle via with_scope_create()
        let scope_sym = self.ast.get_data0(node)
        let span = self.ast.get_start(node)
        let create_args: Vec[i32] = Vec.new()
        let create_call_id = self.body.new_call_args(create_args)
        self.body.set_call_intrinsic(create_call_id, MirIntrinsic.SCOPE_CREATE)
        self.body.set_call_ast_node(create_call_id, node)
        let scope_local = self.new_temp(self.sema.ty_i64)
        let scope_place = self.place_for_local(scope_local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, scope_local, 0, span)
        let after_create_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), create_call_id, scope_place, after_create_bb)
        self.switch_to(after_create_bb)
        self.schedule_drop(scope_local, DropKind.DK_ASYNC_SCOPE)
        // Bind scope handle to scope variable name
        if scope_sym > 0:
            let bind_local = self.body.new_local(self.sema.ty_i64 as i32, 0, scope_sym, 1)
            self.bind_local(scope_sym, bind_local)
            let bind_place = self.place_for_local(bind_local)
            let scope_op = self.body.new_operand(OperandKind.OK_COPY, scope_place)
            self.assign_operand_to_place(bind_place, scope_op, span)
        // 2. Execute scope body (s.track() calls resolve via existing codegen path)
        let scope_body = self.ast.get_data1(node)
        var body_result = self.unit_operand()
        if scope_body != 0:
            if self.scope_body_tail_is_method_call(scope_body, scope_sym, self.sema.syms.track) != 0:
                body_result = self.lower_expr_discard(scope_body)
            else:
                body_result = self.lower_expr(scope_body)
        // 3. Cleanup is a scheduled scope drop so return/?/break/continue
        // paths run the same await-all/destroy sequence as fallthrough.
        self.cancel_scheduled_value_drop_for_local(scope_local)
        self.emit_drop_entry(scope_local, DropKind.DK_ASYNC_SCOPE)
        return body_result

    if kind == NodeKind.NK_SCOPE:
        let scope_sym = self.ast.get_data0(node)
        let span = self.ast.get_start(node)
        let create_args: Vec[i32] = Vec.new()
        let create_call_id = self.body.new_call_args(create_args)
        self.body.set_call_intrinsic(create_call_id, MirIntrinsic.THREAD_SCOPE_CREATE)
        self.body.set_call_ast_node(create_call_id, node)
        let scope_local = self.new_temp(self.sema.ty_i64)
        let scope_place = self.place_for_local(scope_local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, scope_local, 0, span)
        let after_create_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), create_call_id, scope_place, after_create_bb)
        self.switch_to(after_create_bb)
        self.schedule_drop(scope_local, DropKind.DK_THREAD_SCOPE)
        if scope_sym > 0:
            let bind_local = self.body.new_local(self.sema.ty_i64 as i32, 0, scope_sym, 1)
            self.bind_local(scope_sym, bind_local)
            let bind_place = self.place_for_local(bind_local)
            let scope_op = self.body.new_operand(OperandKind.OK_COPY, scope_place)
            self.assign_operand_to_place(bind_place, scope_op, span)
        let scope_body = self.ast.get_data1(node)
        var body_result = self.unit_operand()
        if scope_body != 0:
            if self.scope_body_tail_is_method_call(scope_body, scope_sym, self.sema.syms.spawn_method) != 0:
                body_result = self.lower_expr_discard(scope_body)
            else:
                body_result = self.lower_expr(scope_body)
        self.cancel_scheduled_value_drop_for_local(scope_local)
        self.emit_drop_entry(scope_local, DropKind.DK_THREAD_SCOPE)
        return body_result

    if kind == NodeKind.NK_ASYNC_BLOCK:
        // Emit CK_ASYNC_BLOCK constant — codegen handles the fiber spawn.
        // Same pattern as CK_CLOSURE: MIR just creates a marker, codegen
        // creates the anonymous function, collects captures, and spawns.
        let ab_ty = self.expr_type(node)
        if ab_ty == 0:
            return self.unit_operand()
        let ab_tmp = self.new_temp(ab_ty)
        let ab_place = self.place_for_local(ab_tmp)
        let ab_const = self.body.new_const(ConstKind.CK_ASYNC_BLOCK, node, 0, 0, ab_ty)
        let ab_op = self.body.new_operand(OperandKind.OK_CONSTANT, ab_const)
        let ab_rv = self.body.new_rvalue(RvalueKind.RK_USE, ab_op, 0, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, ab_place, ab_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, ab_place)

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        if arm_count <= 0:
            return self.unit_operand()
        let span = self.ast.get_start(node)

        // 1. Lower each arm's task expression → task operands
        var task_ops: Vec[i32] = Vec.new()
        for ai in 0..arm_count:
            let task_node = self.ast.get_extra(extra_start + ai * 3 + 1)
            self.cancel_scheduled_value_drop_for_receiver_expr(task_node)
            let task_op = self.lower_expr(task_node)
            task_ops.push(task_op)

        // 2. Emit select intrinsic call: passes all task operands, returns winner index
        let select_args: Vec[i32] = Vec.new()
        for ai in 0..arm_count:
            select_args.push(task_ops.get(ai as i64))
        let select_call_id = self.body.new_call_args(select_args)
        let select_biased = self.ast.get_data2(node)
        let select_intrinsic = if select_biased != 0: MirIntrinsic.FIBER_SELECT_BIASED else: MirIntrinsic.FIBER_SELECT
        self.body.set_call_intrinsic(select_call_id, select_intrinsic)
        self.body.set_call_ast_node(select_call_id, node)
        let select_result_local = self.new_temp(self.sema.ty_i32)
        let select_result_place = self.place_for_local(select_result_local)
        let switch_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), select_call_id, select_result_place, switch_bb)
        self.switch_to(switch_bb)

        // 3. Create basic blocks for each arm + join
        var arm_bbs: Vec[i32] = Vec.new()
        var switch_vals: Vec[i32] = Vec.new()
        for ai in 0..arm_count:
            let arm_bb = self.new_block()
            arm_bbs.push(arm_bb)
            switch_vals.push(ai)
        let join_bb = self.new_block()
        let select_expr_type = self.expr_type(node)
        let result_local = self.new_temp(select_expr_type)
        let result_place = self.place_for_local(result_local)

        // 4. Switch on winner index
        let switch_op = self.body.new_operand(OperandKind.OK_COPY, select_result_place)
        let switch_table = self.body.new_switch_table(switch_vals, arm_bbs)
        self.terminate(TermKind.TK_SWITCH_INT, switch_op, switch_table, join_bb, 0)

        // 5. Each arm: await winner, cancel losers, execute body
        for ai in 0..arm_count:
            self.switch_to(arm_bbs.get(ai as i64) as i32)
            let arm_name = self.ast.get_extra(extra_start + ai * 3)
            let task_node = self.ast.get_extra(extra_start + ai * 3 + 1)
            let arm_body = self.ast.get_extra(extra_start + ai * 3 + 2)

            // Await the winning task to get its result
            let await_args: Vec[i32] = Vec.new()
            await_args.push(task_ops.get(ai as i64))
            let await_call_id = self.body.new_call_args(await_args)
            self.body.set_call_intrinsic(await_call_id, MirIntrinsic.FIBER_AWAIT)
            self.body.set_call_ast_node(await_call_id, node)
            var await_result_ty = self.expr_type(task_node)
            if await_result_ty != 0:
                await_result_ty = self.sema.unwrap_task_type(await_result_ty as TypeId) as i32
            if await_result_ty == 0:
                await_result_ty = self.expr_type(node)
            let await_result_local = self.new_temp(await_result_ty)
            let await_result_place = self.place_for_local(await_result_local)
            let after_await_bb = self.new_block()
            self.terminate(TermKind.TK_CALL, self.unit_operand(), await_call_id, await_result_place, after_await_bb)
            self.switch_to(after_await_bb)

            // Bind result to arm variable
            let bind_local = self.body.new_local(await_result_ty, 0, arm_name, 1)
            self.bind_local(arm_name, bind_local)
            let bind_place = self.place_for_local(bind_local)
            let await_result_op = self.body.new_operand(OperandKind.OK_COPY, await_result_place)
            self.assign_operand_to_place(bind_place, await_result_op, span)

            // Cancel losing tasks
            for li in 0..arm_count:
                if li != ai:
                    let cancel_args: Vec[i32] = Vec.new()
                    let loser_task = task_ops.get(li as i64)
                    cancel_args.push(loser_task)
                    let cancel_call_id = self.body.new_call_args(cancel_args)
                    self.body.set_call_intrinsic(cancel_call_id, MirIntrinsic.FIBER_CANCEL)
                    self.body.set_call_ast_node(cancel_call_id, node)
                    let cancel_result_local = self.new_temp(self.sema.ty_i32)
                    let cancel_result_place = self.place_for_local(cancel_result_local)
                    let after_cancel_bb = self.new_block()
                    self.terminate(TermKind.TK_CALL, self.unit_operand(), cancel_call_id, cancel_result_place, after_cancel_bb)
                    self.switch_to(after_cancel_bb)
                    self.lower_cleanup_await(loser_task, node)

            // Execute arm body
            let body_op = self.lower_expr(arm_body)

            // Store body result and branch to join
            self.assign_operand_to_place(result_place, body_op, span)
            self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        return self.body.new_operand(OperandKind.OK_COPY, result_place)

    self.mark_unsupported()
    self.unit_operand()

fn lower_fn(builder: MirBuilder, fn_node: i32) -> MirBody:
    let fn_sym = builder.ast.get_data0(fn_node)
    var sig_idx = builder.sema.get_sig(fn_sym)
    // If sig not found, try translating fn_sym from AST pool to sema pool.
    // Sema registers sigs under sema pool symbols, not AST pool symbols.
    if sig_idx < 0:
        let sema_fn_sym = builder.sema.pool_lookup_symbol(builder.pool.resolve_symbol(fn_sym))
        sig_idx = builder.sema.get_sig(sema_fn_sym)
    // Also try method lookup for methods: "Type.method" → fn_sym for (type_sym, method_sym)
    if sig_idx < 0:
        let fn_name = builder.pool.resolve_symbol(fn_sym)
        // Split "Type.method" on the dot
        var dot_pos = -1
        for ci in 0..fn_name.len() as i32:
            if fn_name.byte_at(ci as i64) == 46:
                dot_pos = ci
                break
        if dot_pos > 0:
            let type_part = fn_name.slice(0, dot_pos as i64)
            let method_part = fn_name.slice((dot_pos + 1) as i64, fn_name.len())
            let sema_type_sym = builder.sema.pool_lookup_symbol(type_part)
            let sema_method_sym = builder.sema.pool_lookup_symbol(method_part)
            sig_idx = builder.sema.lookup_method_sig(sema_type_sym, sema_method_sym)
    lower_fn_with_sig(builder, fn_node, sig_idx)

fn lower_fn_with_sig(builder: MirBuilder, fn_node: i32, sig_idx: i32) -> MirBody:
    let fn_flags = builder.ast.get_data2(fn_node)
    if sig_idx >= 0:
        var body_ret_ty = builder.sema.sig_return_type(sig_idx)
        if (fn_flags / FnFlags.ASYNC) % 2 == 1:
            body_ret_ty = builder.sema.unwrap_task_type(body_ret_ty as TypeId) as i32
        if (fn_flags / FnFlags.GEN) % 2 == 1 and builder.in_generator != 0:
            body_ret_ty = builder.sema.ty_void as i32
        builder.body.local_type_ids.set_i32(0, body_ret_ty)
    else:
        // No sig — try to get return type from typed_expr_types on body expression
        let body_expr = builder.ast.get_data1(fn_node)
        let ret_ty = builder.expr_type(body_expr)
        if ret_ty != 0 and ret_ty != builder.sema.ty_void:
            builder.body.local_type_ids.set_i32(0, ret_ty)
        else:
            builder.body.local_type_ids.set_i32(0, builder.sema.ty_void)

    builder.push_scope()
    let body_expr = builder.ast.get_data1(fn_node)
    builder.collect_goto_label_depths(body_expr, builder.drop_scope_starts.len() as i32)

    // Parameters: locals 1..n
    let meta = builder.ast.find_fn_meta(fn_node)
    if meta >= 0:
        let param_start = builder.ast.fn_meta_param_start(meta)
        let param_count = builder.ast.fn_meta_param_count(meta)

        // Parameter locals must occupy locals 1..n contiguously (codegen binds
        // incoming arguments to them in order), so create them all first and
        // record their ids before destructuring any parameter patterns.
        let param_locals: Vec[i32] = Vec.new()
        for i in 0..param_count:
            let p_name = builder.ast.fn_param_name(param_start, i)
            var p_ty = 0
            if sig_idx >= 0:
                p_ty = builder.sema.sig_param_type(sig_idx, i)
            else:
                // No sig — resolve param type from type annotation AST node
                let p_type_node = builder.ast.fn_param_type(param_start, i)
                if p_type_node > 0:
                    p_ty = builder.sema.resolve_type_expr(p_type_node) as i32
                if p_ty == 0:
                    p_ty = builder.sema.ty_i32 as i32
            let local_id = builder.body.new_local(p_ty, 0, p_name, 1)
            builder.bind_local(p_name, local_id)
            builder.body.push_stmt(builder.cur_bb, StmtKind.StorageLive, local_id, 0, builder.ast.get_start(fn_node))
            if builder.sema.is_copy(p_ty) == 0:
                builder.schedule_drop(local_id, DropKind.DK_VALUE)
            param_locals.push(local_id)
        builder.body.n_params = param_count

        // Parameter patterns (§9.7): `fn f({ x, y }: Point)` destructures the
        // incoming parameter, binding the pattern's variables. Done after all
        // param locals exist so the field-locals don't split the param range.
        let ppmeta = builder.ast.find_fn_param_pattern_meta(fn_node)
        if ppmeta >= 0:
            let pp_start = builder.ast.fn_param_pattern_meta_start(ppmeta)
            let pp_count = builder.ast.fn_param_pattern_meta_count(ppmeta)
            for i in 0..param_count:
                if i < pp_count:
                    let ppat = builder.ast.fn_param_pattern_value(pp_start + i)
                    if ppat != 0:
                        let _ = builder.lower_pattern(ppat, builder.place_for_local(param_locals.get(i as i64)))

    // Set expected_type to the function's return type so that intrinsic calls
    // (Vec.new, HashMap.new) in tail position can resolve their generic inst type.
    let ret_ty = builder.body.local_type_ids.get(0)
    builder.expected_type = ret_ty

    let ret_is_void = ret_ty == builder.sema.ty_void
    var result = if ret_is_void:
        builder.lower_expr_discard(body_expr)
    else:
        builder.lower_expr(body_expr)

    // Implicit Ok wrapping: if return type is Result[T, E] and body type is T,
    // wrap the result in Ok(value) — an enum variant construction with tag 0.
    let ret_resolved = builder.sema.resolve_alias(ret_ty)
    if not ret_is_void and builder.sema.get_type_kind(ret_resolved) == TypeKind.TY_GENERIC_INST:
        let ret_base = builder.sema.get_generic_inst_base(ret_resolved)
        if builder.sema.pool_resolve(ret_base) == "Result" and builder.sema.get_generic_inst_arg_count(ret_resolved) == 2:
            let body_ty = builder.expr_type(body_expr)
            let ok_type = builder.sema.get_generic_inst_arg(ret_resolved, 0)
            if body_ty != 0 and body_ty != ret_ty:
                if builder.sema.types_compatible(ok_type, body_ty) != 0 or builder.sema.arithmetic_result_type(ok_type, body_ty) != 0:
                    // Wrap in Ok variant (tag=0)
                    let ok_fields: Vec[i32] = Vec.new()
                    let ok_names: Vec[i32] = Vec.new()
                    ok_fields.push(result)
                    ok_names.push(0)
                    let ok_fid = builder.body.new_agg_fields(ok_fields, ok_names)
                    let ok_rv = builder.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, ok_fid, 0)
                    let ok_tmp = builder.new_temp(ret_ty)
                    let ok_place = builder.place_for_local(ok_tmp)
                    builder.body.push_stmt(builder.cur_bb, StmtKind.Assign, ok_place, ok_rv, builder.ast.get_end(fn_node))
                    result = builder.body.new_operand(OperandKind.OK_COPY, ok_place)

    // Implicit return value assignment for non-diverging tail expressions.
    if not ret_is_void:
        let ret_place = builder.place_for_local(0)
        builder.assign_operand_to_place(ret_place, result, builder.ast.get_end(fn_node))

    builder.emit_defers_for_return()
    builder.pop_scope_inline()
    builder.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

    // Self-tail-call optimization for @[tailrec] functions.
    if (fn_flags / FnFlags.TAILREC) % 2 == 1:
        builder.body.optimize_self_tail_calls()

    builder.body

fn MirBody.optimize_self_tail_calls(mut self: MirBody):
    let fn_sym = self.fn_sym
    if fn_sym == 0 or self.n_params == 0:
        return
    let bb_count = self.block_count()
    var bb = 0
    while bb < bb_count:
        if bb < 0 or bb >= self.bb_term_kinds.len() as i32 or self.bb_term_kinds.get(bb as i64) != TermKind.TK_CALL:
            bb = bb + 1
            continue
        let callee_op_id = if bb >= 0 and bb < self.bb_term_d0.len() as i32: self.bb_term_d0.get(bb as i64) else: 0
        let args_id = if bb >= 0 and bb < self.bb_term_d1.len() as i32: self.bb_term_d1.get(bb as i64) else: 0
        let result_place = if bb >= 0 and bb < self.bb_term_d2.len() as i32: self.bb_term_d2.get(bb as i64) else: 0
        let next_bb = if bb >= 0 and bb < self.bb_term_d3.len() as i32: self.bb_term_d3.get(bb as i64) else: 0
        // Check: callee is this function
        if callee_op_id < 0 or callee_op_id >= self.operand_kinds.len() as i32:
            bb = bb + 1
            continue
        let op_kind = self.operand_kinds.get(callee_op_id as i64)
        if op_kind != OperandKind.OK_CONSTANT:
            bb = bb + 1
            continue
        let const_id = self.operand_d0.get(callee_op_id as i64)
        if const_id < 0 or const_id >= self.const_kinds.len() as i32:
            bb = bb + 1
            continue
        if self.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
            bb = bb + 1
            continue
        if self.const_d0.get(const_id as i64) != fn_sym:
            bb = bb + 1
            continue
        // Check: result goes to local 0 (return place)
        if result_place >= 0 and result_place < self.place_locals.len() as i32:
            if self.place_locals.get(result_place as i64) != 0:
                bb = bb + 1
                continue
        // Check: next block is pure TK_RETURN (no statements)
        if next_bb < 0 or next_bb >= bb_count:
            bb = bb + 1
            continue
        if next_bb < 0 or next_bb >= self.bb_term_kinds.len() as i32 or self.bb_term_kinds.get(next_bb as i64) != TermKind.TK_RETURN:
            bb = bb + 1
            continue
        if self.bb_stmt_counts.get(next_bb as i64) != 0:
            bb = bb + 1
            continue
        // This is a self-tail-call. Transform it.
        // Step 1: Read call args into temp locals (aliasing safety)
        let arg_start = self.call_arg_starts.get(args_id as i64)
        let arg_count = self.call_arg_counts.get(args_id as i64)
        let n_params = self.n_params
        let span = self.bb_term_spans.get(bb as i64)
        // Copy args to temps
        for ai in 0..arg_count:
            if ai >= n_params: break
            let arg_op = self.call_arg_operands.get((arg_start + ai) as i64)
            let param_local = ai + 1  // params are locals 1..n_params
            let param_ty = self.local_type_ids.get(param_local as i64)
            let tmp = self.new_temp(param_ty)
            let tmp_place = self.new_place(tmp)
            let rv = self.new_rvalue(RvalueKind.RK_USE, arg_op, 0, 0)
            self.push_stmt(bb, StmtKind.Assign, tmp_place, rv, span)
        // Copy temps back to params
        // We pushed n temps starting at (local_count - n_params) before temps were added
        let first_tmp = self.local_type_ids.len() as i32 - arg_count
        for ai in 0..arg_count:
            if ai >= n_params: break
            let tmp_local = first_tmp + ai
            let param_local = ai + 1
            let param_place = self.new_place(param_local)
            let tmp_place_read = self.new_place(tmp_local)
            let tmp_op = self.new_operand(OperandKind.OK_COPY, tmp_place_read)
            let rv = self.new_rvalue(RvalueKind.RK_USE, tmp_op, 0, 0)
            self.push_stmt(bb, StmtKind.Assign, param_place, rv, span)
        // Replace terminator with GOTO to entry block (bb0)
        self.set_terminator(bb, TermKind.TK_GOTO, 0, 0, 0, 0, span)
        bb = bb + 1

fn mir_gen_resume_field_sym(sema: Sema) -> i32:
    sema.pool_lookup_symbol("__with_generator_resume")

fn mir_gen_state_field_start(sema: Sema, state_tid: i32) -> i32:
    let resolved = sema.resolve_alias(state_tid as TypeId) as i32
    if resolved <= 0 or resolved >= sema.type_d1.len() as i32:
        return 0
    sema.type_d1.get(resolved as i64)

fn mir_gen_state_field_count(sema: Sema, state_tid: i32) -> i32:
    let resolved = sema.resolve_alias(state_tid as TypeId) as i32
    if sema.generator_state_field_counts.contains(resolved):
        return sema.generator_state_field_counts.get(resolved).unwrap()
    if resolved <= 0 or resolved >= sema.type_d2.len() as i32:
        return 0
    sema.type_d2.get(resolved as i64)

fn mir_gen_state_field_sym(sema: Sema, state_tid: i32, field_i: i32) -> i32:
    let resolved = sema.resolve_alias(state_tid as TypeId) as i32
    let key = sema_pair_key(resolved, field_i)
    if sema.generator_state_field_names.contains(key):
        return sema.generator_state_field_names.get(key).unwrap()
    let start = mir_gen_state_field_start(sema, state_tid)
    sema.type_extra.get((start + field_i * 3) as i64)

fn mir_gen_state_field_type(sema: Sema, state_tid: i32, field_i: i32) -> i32:
    let resolved = sema.resolve_alias(state_tid as TypeId) as i32
    let key = sema_pair_key(resolved, field_i)
    if sema.generator_state_field_types.contains(key):
        return sema.generator_state_field_types.get(key).unwrap()
    let start = mir_gen_state_field_start(sema, state_tid)
    sema.type_extra.get((start + field_i * 3 + 1) as i64)

fn mir_gen_find_local_by_sym(body: MirBody, sym: i32) -> i32:
    if sym == 0:
        return -1
    for li in 1..body.local_names.len() as i32:
        if body.local_names.get(li as i64) == sym:
            return li
    -1

fn MirBody.gen_self_field_place(mut self: MirBody, field_sym: i32, field_ty: i32) -> i32:
    let self_place = self.new_place(1)
    self.new_field_place(self_place, field_sym, field_ty)

fn MirBody.gen_assign_operand(mut self: MirBody, bb: i32, place: i32, op: i32, span: i32):
    let rv = self.new_rvalue(RvalueKind.RK_USE, op, 0, 0)
    self.push_stmt(bb, StmtKind.Assign, place, rv, span)

fn MirBody.gen_zero_operand(mut self: MirBody, tid: i32) -> i32:
    let c = self.new_const(ConstKind.CK_ZERO_SIZED, 0, 0, 0, tid)
    self.new_operand(OperandKind.OK_CONSTANT, c)

fn MirBody.gen_assign_option_some(mut self: MirBody, bb: i32, opt_ty: i32, value_op: i32, span: i32):
    let fields: Vec[i32] = Vec.new()
    let names: Vec[i32] = Vec.new()
    fields.push(value_op)
    names.push(0)
    let fid = self.new_agg_fields(fields, names)
    let rv = self.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fid, 0)
    let ret_place = self.new_place(0)
    let _ = opt_ty
    self.push_stmt(bb, StmtKind.Assign, ret_place, rv, span)

fn MirBody.gen_assign_option_none(mut self: MirBody, bb: i32, opt_ty: i32, span: i32):
    let fields: Vec[i32] = Vec.new()
    let names: Vec[i32] = Vec.new()
    let fid = self.new_agg_fields(fields, names)
    let rv = self.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fid, 1)
    let ret_place = self.new_place(0)
    let _ = opt_ty
    self.push_stmt(bb, StmtKind.Assign, ret_place, rv, span)

fn MirBody.gen_store_resume_state(mut self: MirBody, bb: i32, sema: Sema, state_tid: i32, value: i64, span: i32):
    let resume_sym = mir_gen_resume_field_sym(sema)
    let resume_place = self.gen_self_field_place(resume_sym, sema.ty_i32 as i32)
    let c = self.new_const(ConstKind.CK_INT, ast_int_part0(value), ast_int_part1(value), ast_int_part2(value), sema.ty_i32 as i32)
    let op = self.new_operand(OperandKind.OK_CONSTANT, c)
    self.gen_assign_operand(bb, resume_place, op, span)

fn MirBody.gen_save_generator_fields(mut self: MirBody, bb: i32, sema: Sema, state_tid: i32, span: i32):
    let resume_sym = mir_gen_resume_field_sym(sema)
    let field_count = mir_gen_state_field_count(sema, state_tid)
    for fi in 0..field_count:
        let field_sym = mir_gen_state_field_sym(sema, state_tid, fi)
        if field_sym == resume_sym:
            continue
        let local_id = mir_gen_find_local_by_sym(self, field_sym)
        if local_id < 0:
            continue
        let field_ty = mir_gen_state_field_type(sema, state_tid, fi)
        let dst = self.gen_self_field_place(field_sym, field_ty)
        let src_place = self.new_place(local_id)
        let op = self.new_operand(OperandKind.OK_COPY, src_place)
        self.gen_assign_operand(bb, dst, op, span)

fn MirBody.gen_restore_generator_fields(mut self: MirBody, bb: i32, sema: Sema, state_tid: i32, span: i32):
    let resume_sym = mir_gen_resume_field_sym(sema)
    let field_count = mir_gen_state_field_count(sema, state_tid)
    for fi in 0..field_count:
        let field_sym = mir_gen_state_field_sym(sema, state_tid, fi)
        if field_sym == resume_sym:
            continue
        let local_id = mir_gen_find_local_by_sym(self, field_sym)
        if local_id < 0:
            continue
        let field_ty = mir_gen_state_field_type(sema, state_tid, fi)
        let src = self.gen_self_field_place(field_sym, field_ty)
        let dst = self.new_place(local_id)
        let op = self.new_operand(OperandKind.OK_COPY, src)
        self.gen_assign_operand(bb, dst, op, span)

fn mir_gen_remap_local(local_map: Vec[i32], local_id: i32) -> i32:
    if local_id < 0 or local_id >= local_map.len() as i32:
        return local_id
    local_map.get(local_id as i64)

fn mir_gen_remap_place_projection_data(source: MirBody, local_map: Vec[i32], proj_i: i32) -> i32:
    let kind = source.proj_kinds.get(proj_i as i64)
    let data = source.proj_d0.get(proj_i as i64)
    if kind == ProjKind.PK_INDEX:
        return mir_gen_remap_local(local_map, data)
    data

fn mir_gen_remap_rvalue(source: MirBody, local_map: Vec[i32], rv_id: i32, d_index: i32) -> i32:
    let rk = source.rval_kinds.get(rv_id as i64)
    let raw =
        if d_index == 0: source.rval_d0.get(rv_id as i64)
        else if d_index == 1: source.rval_d1.get(rv_id as i64)
        else: source.rval_d2.get(rv_id as i64)
    if rk == RvalueKind.RK_REF or rk == RvalueKind.RK_ADDR_OF:
        if d_index == 1 or (rk == RvalueKind.RK_ADDR_OF and d_index == 0):
            return raw
    let _ = local_map
    raw

fn lower_generator_constructor(sema: Sema, ast_pool: AstPool, pool: InternPool, fn_node: i32, sig_idx: i32) -> MirBody:
    let fn_sym = ast_pool.get_data0(fn_node)
    let state_tid = sema.generator_fn_state_types.get(fn_sym).unwrap()
    var builder = MirBuilder.init(&sema, ast_pool, pool, fn_sym)
    builder.body.local_type_ids.set_i32(0, state_tid)
    builder.push_scope()

    let meta = ast_pool.find_fn_meta(fn_node)
    if meta >= 0:
        let param_start = ast_pool.fn_meta_param_start(meta)
        let param_count = ast_pool.fn_meta_param_count(meta)
        for pi in 0..param_count:
            let p_name = ast_pool.fn_param_name(param_start, pi)
            let p_ty = sema.sig_param_type(sig_idx, pi)
            let local_id = builder.body.new_local(p_ty, 0, p_name, 1)
            builder.bind_local(p_name, local_id)
        builder.body.n_params = param_count

    let fields: Vec[i32] = Vec.new()
    let names: Vec[i32] = Vec.new()
    let resume_sym = mir_gen_resume_field_sym(sema)
    let field_count = mir_gen_state_field_count(sema, state_tid)
    for fi in 0..field_count:
        let field_sym = mir_gen_state_field_sym(sema, state_tid, fi)
        let field_ty = mir_gen_state_field_type(sema, state_tid, fi)
        names.push(field_sym)
        if field_sym == resume_sym:
            fields.push(builder.int_const_operand(0, sema.ty_i32 as i32))
        else:
            let local_id = builder.lookup_local(field_sym)
            if local_id >= 0:
                fields.push(builder.body.new_operand(OperandKind.OK_COPY, builder.place_for_local(local_id)))
            else:
                fields.push(builder.body.gen_zero_operand(field_ty))
    let fid = builder.body.new_agg_fields(fields, names)
    let rv = builder.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, fid, 0)
    let ret_place = builder.place_for_local(0)
    builder.body.push_stmt(builder.cur_bb, StmtKind.Assign, ret_place, rv, ast_pool.get_start(fn_node))
    builder.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)
    builder.body

fn lower_generator_next_body(sema: Sema, source: MirBody, fn_node: i32) -> MirBody:
    let fn_sym = source.fn_sym
    let next_sym = sema.generator_fn_next_syms.get(fn_sym).unwrap()
    let state_tid = sema.generator_fn_state_types.get(fn_sym).unwrap()
    let yield_ty = sema.generator_fn_yield_types.get(fn_sym).unwrap()
    let opt_ty = sema.ensure_option_type_for(yield_ty)
    var out = MirBody.init(next_sym, &sema)
    out.local_type_ids.set_i32(0, opt_ty)
    let entry_bb = out.new_block()
    let self_sym = sema.pool_lookup_symbol("self")
    let _self_local = out.new_local(state_tid, 1, self_sym, 1)
    out.n_params = 1

    let local_map: Vec[i32] = Vec.new()
    local_map.push(0)
    for li in 1..source.local_count():
        let mapped = out.new_local(
            source.local_type_ids.get(li as i64),
            source.local_mutables.get(li as i64),
            source.local_names.get(li as i64),
            source.local_is_user_var.get(li as i64),
        )
        local_map.push(mapped)

    for ci in 0..source.const_kinds.len() as i32:
        out.const_kinds.push(source.const_kinds.get(ci as i64))
        out.const_d0.push(source.const_d0.get(ci as i64))
        out.const_d1.push(source.const_d1.get(ci as i64))
        out.const_d2.push(source.const_d2.get(ci as i64))
        out.const_types.push(source.const_types.get(ci as i64))

    for pi in 0..source.place_locals.len() as i32:
        let base_local = mir_gen_remap_local(local_map, source.place_locals.get(pi as i64))
        let proj_start = source.place_proj_starts.get(pi as i64)
        let proj_count = source.place_proj_counts.get(pi as i64)
        let new_proj_start = out.proj_kinds.len() as i32
        for ppi in 0..proj_count:
            let src_proj = proj_start + ppi
            out.proj_kinds.push(source.proj_kinds.get(src_proj as i64))
            out.proj_d0.push(mir_gen_remap_place_projection_data(source, local_map, src_proj))
        out.place_locals.push(base_local)
        out.place_sema_types.push(source.place_sema_types.get(pi as i64))
        out.place_proj_starts.push(new_proj_start)
        out.place_proj_counts.push(proj_count)

    for oi in 0..source.operand_kinds.len() as i32:
        let ok = source.operand_kinds.get(oi as i64)
        out.operand_kinds.push(ok)
        out.operand_d0.push(source.operand_d0.get(oi as i64))

    for ai in 0..source.agg_field_starts.len() as i32:
        let start = source.agg_field_starts.get(ai as i64)
        let count = source.agg_field_counts.get(ai as i64)
        out.agg_field_starts.push(out.agg_field_operands.len() as i32)
        out.agg_field_counts.push(count)
        for fi in 0..count:
            out.agg_field_operands.push(source.agg_field_operands.get((start + fi) as i64))
            out.agg_field_name_syms.push(source.agg_field_name_syms.get((start + fi) as i64))

    for ca in 0..source.call_arg_starts.len() as i32:
        let start = source.call_arg_starts.get(ca as i64)
        let count = source.call_arg_counts.get(ca as i64)
        out.call_arg_starts.push(out.call_arg_operands.len() as i32)
        out.call_arg_counts.push(count)
        out.call_intrinsic_kinds.push(source.call_intrinsic_kinds.get(ca as i64))
        out.call_ast_nodes.push(source.call_ast_nodes.get(ca as i64))
        for ai in 0..count:
            out.call_arg_operands.push(source.call_arg_operands.get((start + ai) as i64))

    for ri in 0..source.rval_kinds.len() as i32:
        out.rval_kinds.push(source.rval_kinds.get(ri as i64))
        out.rval_d0.push(mir_gen_remap_rvalue(source, local_map, ri, 0))
        out.rval_d1.push(mir_gen_remap_rvalue(source, local_map, ri, 1))
        out.rval_d2.push(mir_gen_remap_rvalue(source, local_map, ri, 2))

    for bb in 0..source.block_count():
        let _ = out.new_block()

    let switch_vals: Vec[i32] = Vec.new()
    let switch_targets: Vec[i32] = Vec.new()
    switch_vals.push(0)
    switch_targets.push(1)

    for bb in 0..source.block_count():
        let new_bb = bb + 1
        let start = source.bb_stmt_starts.get(bb as i64)
        let count = source.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            let sk = source.stmt_kinds.get(stmt_id as i64)
            var sd0 = source.stmt_d0.get(stmt_id as i64)
            let sd1 = source.stmt_d1.get(stmt_id as i64)
            if sk == StmtKind.StorageLive or sk == StmtKind.StorageDead or sk == StmtKind.Drop:
                sd0 = mir_gen_remap_local(local_map, sd0)
            out.push_stmt(new_bb, sk, sd0, sd1, source.stmt_spans.get(stmt_id as i64))

        let tk = source.term_kind(bb)
        let d0 = source.term_data0(bb)
        let d1 = source.term_data1(bb)
        let d2 = source.term_data2(bb)
        let d3 = source.term_data3(bb)
        let span = source.bb_term_spans.get(bb as i64)
        if tk == TermKind.TK_YIELD:
            out.gen_save_generator_fields(new_bb, sema, state_tid, span)
            out.gen_store_resume_state(new_bb, sema, state_tid, (d2 + 1) as i64, span)
            out.gen_assign_option_some(new_bb, opt_ty, d0, span)
            out.set_terminator(new_bb, TermKind.TK_RETURN, 0, 0, 0, 0, span)
            switch_vals.push(d2 + 1)
            switch_targets.push(d1 + 1)
            continue
        if tk == TermKind.TK_RETURN:
            out.gen_store_resume_state(new_bb, sema, state_tid, -1, span)
            out.gen_assign_option_none(new_bb, opt_ty, span)
            out.set_terminator(new_bb, TermKind.TK_RETURN, 0, 0, 0, 0, span)
            continue
        if tk == TermKind.TK_GOTO:
            out.set_terminator(new_bb, tk, d0 + 1, d1, d2, d3, span)
            continue
        if tk == TermKind.TK_SWITCH_INT:
            let vals: Vec[i32] = Vec.new()
            let targets: Vec[i32] = Vec.new()
            let sw_start = source.switch_table_starts.get(d1 as i64)
            let sw_count = source.switch_table_counts.get(d1 as i64)
            for si in 0..sw_count:
                vals.push(source.switch_table_vals.get((sw_start + si) as i64))
                targets.push(source.switch_table_targets.get((sw_start + si) as i64) + 1)
            let new_table = out.new_switch_table(vals, targets)
            out.set_terminator(new_bb, tk, d0, new_table, d2 + 1, d3, span)
            continue
        if tk == TermKind.TK_CALL:
            out.set_terminator(new_bb, tk, d0, d1, d2, d3 + 1, span)
            continue
        if tk == TermKind.TK_DROP_AND_GOTO:
            out.set_terminator(new_bb, tk, d0, d1 + 1, d2, d3, span)
            continue
        out.set_terminator(new_bb, tk, d0, d1, d2, d3, span)

    let done_bb = out.new_block()
    out.gen_assign_option_none(done_bb as i32, opt_ty, 0)
    out.set_terminator(done_bb as i32, TermKind.TK_RETURN, 0, 0, 0, 0, 0)

    out.gen_restore_generator_fields(entry_bb as i32, sema, state_tid, 0)
    let resume_sym = mir_gen_resume_field_sym(sema)
    let resume_place = out.gen_self_field_place(resume_sym, sema.ty_i32 as i32)
    let resume_tmp = out.new_temp(sema.ty_i32 as i32)
    let resume_tmp_place = out.new_place(resume_tmp)
    let resume_op = out.new_operand(OperandKind.OK_COPY, resume_place)
    out.gen_assign_operand(entry_bb as i32, resume_tmp_place, resume_op, 0)
    let switch_op = out.new_operand(OperandKind.OK_COPY, resume_tmp_place)
    let dispatch_table = out.new_switch_table(switch_vals, switch_targets)
    out.set_terminator(entry_bb as i32, TermKind.TK_SWITCH_INT, switch_op, dispatch_table, done_bb as i32, 0, 0)

    out

fn lower_module(sema: Sema, ast_pool: AstPool, pool: InternPool) -> MirModule:
    var mir_mod = MirModule.init()
    // Snapshot sema type tables before any MirBuilder copy can realloc/free the buffer
    mir_mod.snapshot_sema_types(sema)

    for di in 0..ast_pool.decl_count():
        let decl = ast_pool.get_decl(di)
        if ast_pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue

        let fn_sym = ast_pool.get_data0(decl)
        let meta = ast_pool.find_fn_meta(decl)
        if meta >= 0 and ast_pool.fn_meta_tp_count(meta) > 0:
            continue

        var fn_sema = sema
        fn_sema.update_decl_source_context(di)
        let fn_flags = ast_pool.get_data2(decl)
        if (fn_flags / FnFlags.GEN) % 2 == 1:
            let sig_idx = fn_sema.get_sig(fn_sym)
            if sig_idx < 0:
                continue
            var source_builder = MirBuilder.init(&fn_sema, ast_pool, pool, fn_sym)
            source_builder.in_generator = 1
            let source_body = lower_fn_with_sig(source_builder, decl as i32, sig_idx)
            let ctor_body = lower_generator_constructor(fn_sema, ast_pool, pool, decl as i32, sig_idx)
            let next_body = lower_generator_next_body(fn_sema, source_body, decl as i32)
            mir_mod.add_body(ctor_body)
            mir_mod.add_body(next_body)
            continue
        var builder = MirBuilder.init(&fn_sema, ast_pool, pool, fn_sym)
        let body = lower_fn(builder, decl as i32)
        mir_mod.add_body(body)

    mir_mod

fn collect_tailrec_fn_syms(ast_pool: AstPool) -> Vec[i32]:
    let tailrec_syms: Vec[i32] = Vec.new()
    for di in 0..ast_pool.decl_count():
        let decl = ast_pool.get_decl(di)
        if ast_pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        let meta = ast_pool.find_fn_meta(decl)
        if meta >= 0 and ast_pool.fn_meta_tp_count(meta) > 0:
            continue
        let fn_flags = ast_pool.get_data2(decl)
        if (fn_flags / FnFlags.TAILREC) % 2 == 1:
            tailrec_syms.push(ast_pool.get_data0(decl))
    tailrec_syms

// ── Mutual tail-call optimization ──────────────────────────────

fn mir_body_extract_callee_sym(body: &MirBody, callee_op_id: i32) -> i32:
    // Extract function symbol from a TK_CALL terminator's callee operand.
    if callee_op_id < 0 or callee_op_id >= body.operand_kinds.len() as i32:
        return 0
    if body.operand_kinds.get(callee_op_id as i64) != OperandKind.OK_CONSTANT:
        return 0
    let const_id = body.operand_d0.get(callee_op_id as i64)
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        return 0
    if body.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
        return 0
    body.const_d0.get(const_id as i64)

fn mir_place_plain_local(body: &MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return -1
    if body.place_proj_counts.get(place_id as i64) != 0:
        return -1
    body.place_locals.get(place_id as i64)

fn mir_stmt_forward_local(body: &MirBody, stmt_id: i32, source_local: i32) -> i32:
    if body.stmt_kind(stmt_id) != StmtKind.Assign:
        return -1
    let dest_place = body.stmt_data0(stmt_id)
    let dest_local = mir_place_plain_local(body, dest_place)
    if dest_local < 0:
        return -1
    let rv_id = body.stmt_data1(stmt_id)
    if rv_id < 0 or rv_id >= body.rval_kinds.len() as i32:
        return -1
    if body.rval_kinds.get(rv_id as i64) != RvalueKind.RK_USE:
        return -1
    let operand_id = body.rval_d0.get(rv_id as i64)
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return -1
    let operand_kind = body.operand_kinds.get(operand_id as i64)
    if operand_kind != OperandKind.OK_COPY and operand_kind != OperandKind.OK_MOVE:
        return -1
    let source_place = body.operand_d0.get(operand_id as i64)
    if mir_place_plain_local(body, source_place) != source_local:
        return -1
    dest_local

fn mir_is_tail_return_path(body: &MirBody, bb: i32, current_local: i32, depth: i32) -> bool:
    if bb < 0 or bb >= body.block_count():
        return false
    if depth > body.block_count():
        return false
    let stmt_start = body.bb_stmt_starts.get(bb as i64)
    let stmt_count = body.bb_stmt_counts.get(bb as i64)
    var local = current_local
    for si in 0..stmt_count:
        let stmt_id = stmt_start + si
        let next_local = mir_stmt_forward_local(body, stmt_id, local)
        if next_local < 0:
            return false
        local = next_local
    let tk = body.term_kind(bb)
    if tk == TermKind.TK_RETURN:
        return local == 0
    if tk == TermKind.TK_GOTO:
        return mir_is_tail_return_path(body, body.term_data0(bb), local, depth + 1)
    false

fn mir_is_tail_call_to(body: &MirBody, bb: i32, target_sym: i32) -> bool:
    // Check if block bb ends with a tail call to target_sym.
    if body.term_kind(bb) != TermKind.TK_CALL:
        return false
    let callee_sym = mir_body_extract_callee_sym(body, body.term_data0(bb))
    if callee_sym != target_sym:
        return false
    // Result must go to local 0 (return place)
    let result_place = body.term_data2(bb)
    let result_local = mir_place_plain_local(body, result_place)
    if result_local < 0:
        return false
    let next_bb = body.term_data3(bb)
    mir_is_tail_return_path(body, next_bb, result_local, 0)

fn mir_vec_contains_i32(v: &Vec[i32], value: i32) -> bool:
    for i in 0..v.len() as i32:
        if v.get(i as i64) == value:
            return true
    false

fn mir_push_unique_i32(v: Vec[i32], value: i32) -> void:
    if not mir_vec_contains_i32(&v, value):
        v.push(value)

fn mir_body_has_call_to(body: &MirBody, target_sym: i32) -> bool:
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        if mir_body_extract_callee_sym(body, body.term_data0(bb)) == target_sym:
            return true
    false

fn mir_body_has_non_tail_call_to(body: &MirBody, target_sym: i32) -> bool:
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        if mir_body_extract_callee_sym(body, body.term_data0(bb)) != target_sym:
            continue
        if not mir_is_tail_call_to(body, bb, target_sym):
            return true
    false

fn tailrec_find_decl(ast_pool: AstPool, fn_sym: i32) -> i32:
    for di in 0..ast_pool.decl_count():
        let decl = ast_pool.get_decl(di)
        if ast_pool.kind(decl) == NodeKind.NK_FN_DECL and ast_pool.get_data0(decl) == fn_sym:
            return decl as i32
    0

fn mir_fn_is_tailrec(ast_pool: AstPool, fn_sym: i32) -> i32:
    let fn_node = tailrec_find_decl(ast_pool, fn_sym)
    if fn_node == 0:
        return 0
    let flags = ast_pool.get_data2(fn_node)
    if (flags / FnFlags.TAILREC) % 2 == 1:
        return 1
    0

fn mir_tailrec_sig_compatible(sema: Sema, ast_pool: AstPool, fn_a: i32, fn_b: i32) -> i32:
    let sig_a = sema.get_sig(fn_a)
    let sig_b = sema.get_sig(fn_b)
    if sig_a < 0 or sig_b < 0:
        return 0
    if sema.sig_is_variadic(sig_a) != 0 or sema.sig_is_variadic(sig_b) != 0:
        return 0
    if sema.sig_return_type(sig_a) != sema.sig_return_type(sig_b):
        return 0
    let count_a = sema.sig_get_param_count(sig_a)
    let count_b = sema.sig_get_param_count(sig_b)
    if count_a != count_b:
        return 0
    for pi in 0..count_a:
        if sema.sig_param_type(sig_a, pi) != sema.sig_param_type(sig_b, pi):
            return 0
    let node_a = tailrec_find_decl(ast_pool, fn_a)
    let node_b = tailrec_find_decl(ast_pool, fn_b)
    if node_a == 0 or node_b == 0:
        return 0
    let meta_a = ast_pool.find_fn_meta(node_a)
    let meta_b = ast_pool.find_fn_meta(node_b)
    let cc_a = if meta_a >= 0: ast_pool.fn_meta_tp_start(meta_a) else: 0
    let cc_b = if meta_b >= 0: ast_pool.fn_meta_tp_start(meta_b) else: 0
    if cc_a != cc_b:
        return 0
    1

fn tailrec_scc_contains(scc: &Vec[i32], fn_sym: i32) -> bool:
    for i in 0..scc.len() as i32:
        if scc.get(i as i64) == fn_sym:
            return true
    false

type TailrecViolation {
    node: i32,
    message: str,
}

fn tailrec_no_violation -> TailrecViolation:
    TailrecViolation { node: 0, message: "" }

fn tailrec_verify_recursive_edges(sema: &Sema, node: i32, scc: &Vec[i32], in_tail: i32, active_cleanup: i32) -> TailrecViolation:
    if node == 0:
        return tailrec_no_violation()
    let kind = sema.ast.kind(node)
    if kind == NodeKind.NK_CALL:
        let callee = sema.ast.get_data0(node)
        if sema.ast.kind(callee) == NodeKind.NK_IDENT:
            let callee_sym = sema.ast.get_data0(callee)
            if tailrec_scc_contains(scc, callee_sym):
                if in_tail == 0:
                    return TailrecViolation { node, message: "recursive call is not in tail position (function is @[tailrec])" }
                else if active_cleanup != 0:
                    return TailrecViolation { node, message: "recursive call cannot be lowered stack-constantly for @[tailrec]: active defer/errdefer cleanup remains" }
        let callee_violation = tailrec_verify_recursive_edges(sema, callee, scc, 0, active_cleanup)
        if callee_violation.node != 0:
            return callee_violation
        let extra_start = sema.ast.get_data1(node)
        let arg_count = sema.ast.get_data2(node)
        for ai in 0..arg_count:
            let arg_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_extra(extra_start + ai), scc, 0, active_cleanup)
            if arg_violation.node != 0:
                return arg_violation
        return tailrec_no_violation()
    if kind == NodeKind.NK_BLOCK:
        let extra_start = sema.ast.get_data0(node)
        let stmt_count = sema.ast.get_data1(node)
        let tail = sema.ast.get_data2(node)
        var cleanup_depth = active_cleanup
        for si in 0..stmt_count:
            let stmt = sema.ast.get_extra(extra_start + si)
            let stmt_kind = sema.ast.kind(stmt)
            if stmt_kind == NodeKind.NK_DEFER or stmt_kind == NodeKind.NK_ERRDEFER:
                let defer_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data0(stmt), scc, 0, cleanup_depth)
                if defer_violation.node != 0:
                    return defer_violation
                cleanup_depth = cleanup_depth + 1
            else:
                let stmt_violation = tailrec_verify_recursive_edges(sema, stmt, scc, 0, cleanup_depth)
                if stmt_violation.node != 0:
                    return stmt_violation
        return tailrec_verify_recursive_edges(sema, tail, scc, in_tail, cleanup_depth)
    if kind == NodeKind.NK_IF_EXPR:
        let cond_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup)
        if cond_violation.node != 0:
            return cond_violation
        let then_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, in_tail, active_cleanup)
        if then_violation.node != 0:
            return then_violation
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data2(node), scc, in_tail, active_cleanup)
    if kind == NodeKind.NK_MATCH:
        let subject_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup)
        if subject_violation.node != 0:
            return subject_violation
        let arm_start = sema.ast.get_data1(node)
        let arm_count = sema.ast.get_data2(node)
        for ai in 0..arm_count:
            let arm = sema.ast.get_extra(arm_start + ai)
            let guard_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data2(arm), scc, 0, active_cleanup)
            if guard_violation.node != 0:
                return guard_violation
            let body_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data1(arm), scc, in_tail, active_cleanup)
            if body_violation.node != 0:
                return body_violation
        return tailrec_no_violation()
    if kind == NodeKind.NK_RETURN:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 1, active_cleanup)
    if kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup)
    if kind == NodeKind.NK_DO_WHILE:
        let body_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup)
        if body_violation.node != 0:
            return body_violation
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, 0, active_cleanup)
    if kind == NodeKind.NK_FOR or kind == NodeKind.NK_WHILE or kind == NodeKind.NK_LOOP:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data2(node), scc, 0, active_cleanup)
    if kind == NodeKind.NK_LET_DECL or kind == NodeKind.NK_LET_BINDING:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, 0, active_cleanup)
    if kind == NodeKind.NK_BINARY:
        let lhs_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, 0, active_cleanup)
        if lhs_violation.node != 0:
            return lhs_violation
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data2(node), scc, 0, active_cleanup)
    if kind == NodeKind.NK_UNARY or kind == NodeKind.NK_ASSIGN:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, 0, active_cleanup)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_MOVE_ARG or kind == NodeKind.NK_COPY_ARG or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_UNSAFE_BLOCK or kind == NodeKind.NK_NO_SUSPEND:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, in_tail, active_cleanup)
    tailrec_no_violation()

fn MirModule.body_reaches(self: &MirModule, start_idx: i32, target_idx: i32) -> bool:
    if start_idx == target_idx:
        return true
    let body_count = self.body_count()
    var visited: Vec[i32] = Vec.new()
    for _ in 0..body_count:
        visited.push(0)
    var stack: Vec[i32] = Vec.new()
    stack.push(start_idx)
    while stack.len() > 0:
        let idx = stack.pop()
        if idx < 0 or idx >= body_count:
            continue
        if visited.get(idx as i64) != 0:
            continue
        visited.set_i32(idx as i64, 1)
        let body = self.bodies.get(idx as i64)
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let callee_sym = mir_body_extract_callee_sym(&body, body.term_data0(bb))
            if callee_sym == 0:
                continue
            let callee_idx = self.find_body(callee_sym)
            if callee_idx < 0:
                continue
            if callee_idx == target_idx:
                return true
            if visited.get(callee_idx as i64) == 0:
                stack.push(callee_idx)
    false

fn MirModule.collect_tailrec_scc(self: &MirModule, start_idx: i32) -> Vec[i32]:
    var members: Vec[i32] = Vec.new()
    let body_count = self.body_count()
    for idx in 0..body_count:
        if self.body_reaches(start_idx, idx) and self.body_reaches(idx, start_idx):
            members.push(idx)
    members

fn MirModule.mark_tailrec_scc_edges(self: &MirModule, scc: &Vec[i32]):
    for si in 0..scc.len() as i32:
        let src_idx = scc.get(si as i64)
        let body = self.bodies.get(src_idx as i64)
        let bb_count = body.block_count()
        for bb in 0..bb_count:
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let callee_sym = mir_body_extract_callee_sym(&body, body.term_data0(bb))
            if callee_sym == 0:
                continue
            for ti in 0..scc.len() as i32:
                let dst_idx = scc.get(ti as i64)
                let dst_body = self.bodies.get(dst_idx as i64)
                if dst_body.fn_sym == callee_sym and mir_is_tail_call_to(&body, bb, callee_sym):
                    mir_push_unique_i32(body.mutual_tail_bbs, bb)
                    break

fn MirModule.tailrec_scc_syms(self: &MirModule, scc: &Vec[i32]) -> Vec[i32]:
    var syms: Vec[i32] = Vec.new()
    for si in 0..scc.len() as i32:
        let body_idx = scc.get(si as i64)
        if body_idx < 0 or body_idx >= self.body_count():
            continue
        syms.push(self.bodies.get(body_idx as i64).fn_sym)
    syms

fn MirModule.verify_tailrec_contracts(self: &MirModule, sema: &Sema, ast_pool: AstPool, tailrec_syms: Vec[i32]) -> Vec[TailrecViolation]:
    let violations: Vec[TailrecViolation] = Vec.new()
    let body_count = self.body_count()
    var processed: Vec[i32] = Vec.new()
    for _ in 0..body_count:
        processed.push(0)
    for ti in 0..tailrec_syms.len() as i32:
        let fn_sym = tailrec_syms.get(ti as i64)
        let body_idx = self.find_body(fn_sym)
        if body_idx < 0:
            continue
        if processed.get(body_idx as i64) != 0:
            continue
        let scc = self.collect_tailrec_scc(body_idx)
        let scc_syms = self.tailrec_scc_syms(&scc)
        for bi in 0..body_count:
            let body_sym = self.bodies.get(bi as i64).fn_sym
            if tailrec_scc_contains(&scc_syms, body_sym):
                processed.set_i32(bi as i64, 1)
        let decl_node = tailrec_find_decl(ast_pool, fn_sym)
        if decl_node == 0:
            continue

        if scc.len() == 1:
            let recursive_violation = tailrec_verify_recursive_edges(sema, ast_pool.get_data1(decl_node), &scc_syms, 1, 0)
            if recursive_violation.node != 0:
                violations.push(recursive_violation)
            continue

        var all_annotated = 1
        for si in 0..scc_syms.len() as i32:
            let member_sym = scc_syms.get(si as i64)
            if mir_fn_is_tailrec(ast_pool, member_sym) == 0:
                all_annotated = 0
                break
        if all_annotated == 0:
            violations.push(TailrecViolation { node: decl_node, message: "mutual tail-recursive cycle cannot be guaranteed stack-constant: every function in the cycle must be annotated @[tailrec]" })
            continue

        var recursive_violation_found = 0
        for si in 0..scc_syms.len() as i32:
            let member_sym = scc_syms.get(si as i64)
            let member_decl = tailrec_find_decl(ast_pool, member_sym)
            if member_decl != 0:
                let recursive_violation = tailrec_verify_recursive_edges(sema, ast_pool.get_data1(member_decl), &scc_syms, 1, 0)
                if recursive_violation.node != 0:
                    violations.push(recursive_violation)
                    recursive_violation_found = 1
                    break
        if recursive_violation_found != 0:
            continue

        var compatible = 1
        let leader_sym = scc_syms.get(0)
        for si in 1..scc_syms.len() as i32:
            let member_sym = scc_syms.get(si as i64)
            if mir_tailrec_sig_compatible(*sema, ast_pool, leader_sym, member_sym) == 0:
                compatible = 0
                break
        if compatible == 0:
            violations.push(TailrecViolation { node: decl_node, message: "mutual @[tailrec] cycle has differing function signatures or calling conventions" })
            continue

        var bad_edge = 0
        for si in 0..scc.len() as i32:
            let src_idx = scc.get(si as i64)
            let src_body = self.bodies.get(src_idx as i64)
            for ti2 in 0..scc_syms.len() as i32:
                let dst_sym = scc_syms.get(ti2 as i64)
                if mir_body_has_non_tail_call_to(&src_body, dst_sym):
                    bad_edge = 1
                    break
            if bad_edge != 0:
                break
        if bad_edge != 0:
            violations.push(TailrecViolation { node: decl_node, message: "mutual tail-recursive cycle cannot be guaranteed stack-constant: recursive edge is not in guaranteed tail position" })
            continue

        self.mark_tailrec_scc_edges(&scc)
    violations
