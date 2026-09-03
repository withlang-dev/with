// MirLower — Wave 7 MIR lowering from typed AST sidecars.
//
// This pass builds explicit control-flow MIR from the semantic result.

use Ast
use InternPool
use Mir
use Sema
use SemaCheck
use Overflow
extern fn with_str_clone_ref(s: &str) -> str
extern fn with_eprint(s: &str) -> Unit

// ── Builder state ────────────────────────────────────────────────

type ScopeEntry {
    local_id: i32,
    drop_kind: i32,
}

type DropScope {
    drops: Vec[ScopeEntry],
}

// Exact move-state snapshot for branch lowering. Lengths are insufficient:
// reinitializing one pre-existing moved place and moving another can preserve
// the vector length while replacing its identity. Restoring cloned contents
// keeps entries and their path storage atomic.
type MirMoveStateSnapshot {
    moved_values: Vec[i32],
    field_base_locals: Vec[i32],
    field_path_starts: Vec[i32],
    field_path_counts: Vec[i32],
    field_path_kinds: Vec[i32],
    field_path_syms: Vec[i32],
}

fn mir_clone_i32_vec(values: &Vec[i32]) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    for i in 0..values.len() as i32:
        out.push(values.get(i as i64))
    out

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
impl Copy for LoopInfo

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
    moved_value_local_ids: Vec[i32],
    moved_field_base_locals: Vec[i32],
    moved_field_path_starts: Vec[i32],
    moved_field_path_counts: Vec[i32],
    moved_field_path_kinds: Vec[i32],
    moved_field_path_syms: Vec[i32],
    stmt_temp_locals: Vec[i32],
    stmt_temp_starts: Vec[i32],
    pending_reset_locals: Vec[i32],
    // #719: per-statement-frame snapshots of the pending-reset stacks.
    stmt_reset_starts: Vec[i32],
    stmt_reset_field_starts: Vec[i32],
    stmt_reset_temp_starts: Vec[i32],
    // Field-place niche (Slice E): a conditionally-moved Drop-bearing field place
    // and its sema type, blanked at the branch/statement boundary so the owner's
    // guarded per-field drop skips it — the field analogue of pending_reset_locals.
    pending_reset_field_places: Vec[i32],
    pending_reset_field_types: Vec[i32],
    // D16 (rvalue-uniform `move`): temps holding a value moved into a
    // share-place callee. Dropped at the same flush points as the pending
    // resets (statement end, or branch-scoped on the moving path), AFTER the
    // call — the end-of-enclosing-statement death §2.4 promises a temporary.
    pending_move_temp_locals: Vec[i32],
    // >0 while lowering a branch body (if/match/loop). Only a field move inside a
    // branch needs the niche reset: an unconditional field move stays statically
    // moved and the owner's partial drop skips it without a reset.
    field_move_in_branch: i32,
    with_cleanup_guard_locals: Vec[i32],
    with_cleanup_payload_locals: Vec[i32],
    with_cleanup_method_syms: Vec[i32],
    with_cleanup_sigs: Vec[i32],
    with_cleanup_mono_syms: Vec[i32],

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
    // D22 Stage 5: lower_expr consumes Sema's contextual-Copy adjustment at
    // the adjusted expression. While materializing that adjustment, lower the
    // same node once at its exact reference type without re-entering it.
    contextual_copy_raw_node: i32,
    // D22 sidecars belong to a concrete checked signature, not merely to the
    // shared generic AST node. lower_fn_with_sig installs this identity before
    // any expression is lowered.
    contextual_fact_sig_idx: i32,
    // D21 evaluates a pipeline receiver once, then lowers the ordinary method
    // call against this exact place. The override is scoped by lower_pipeline.
    pipeline_receiver_override_node: i32,
    pipeline_receiver_override_place: i32,
    in_generator: i32,
    generator_yield_count: i32,

    regex_capture_pat_nodes: Vec[i32],
    regex_capture_opt_places: Vec[i32],

    string_alias_local_ids: Vec[i32],
    string_alias_flags: Vec[i32],
    // #747 (03g): set by lower_if when the just-lowered value-producing if had
    // only view/constant result arms — the result is a VIEW of storage owned
    // elsewhere, so neither the result temp nor a binding of it may drop.
    last_if_result_view: i32,
    string_field_alias_base_locals: Vec[i32],
    string_field_alias_path_starts: Vec[i32],
    string_field_alias_path_counts: Vec[i32],
    string_field_alias_path_kinds: Vec[i32],
    string_field_alias_path_syms: Vec[i32],
    string_field_alias_flags: Vec[i32],
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
        moved_value_local_ids: Vec.new(),
        moved_field_base_locals: Vec.new(),
        moved_field_path_starts: Vec.new(),
        moved_field_path_counts: Vec.new(),
        moved_field_path_kinds: Vec.new(),
        moved_field_path_syms: Vec.new(),
        stmt_temp_locals: Vec.new(),
        stmt_temp_starts: Vec.new(),
        pending_reset_locals: Vec.new(),
        stmt_reset_starts: Vec.new(),
        stmt_reset_field_starts: Vec.new(),
        stmt_reset_temp_starts: Vec.new(),
        pending_reset_field_places: Vec.new(),
        pending_reset_field_types: Vec.new(),
        pending_move_temp_locals: Vec.new(),
        field_move_in_branch: 0,
        with_cleanup_guard_locals: Vec.new(),
        with_cleanup_payload_locals: Vec.new(),
        with_cleanup_method_syms: Vec.new(),
        with_cleanup_sigs: Vec.new(),
        with_cleanup_mono_syms: Vec.new(),
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
        contextual_copy_raw_node: 0,
        contextual_fact_sig_idx: -1,
        pipeline_receiver_override_node: 0,
        pipeline_receiver_override_place: -1,
        in_generator: 0,
        generator_yield_count: 0,
        regex_capture_pat_nodes: Vec.new(),
        regex_capture_opt_places: Vec.new(),
        string_alias_local_ids: Vec.new(),
        string_alias_flags: Vec.new(),
        last_if_result_view: 0,
        string_field_alias_base_locals: Vec.new(),
        string_field_alias_path_starts: Vec.new(),
        string_field_alias_path_counts: Vec.new(),
        string_field_alias_path_kinds: Vec.new(),
        string_field_alias_path_syms: Vec.new(),
        string_field_alias_flags: Vec.new(),
        no_suspend_nodes: Vec.new(),
        sema,
        ast,
        pool,
    }

impl MirBuilder:

    fn has_contextual_copy_adjustment(node: i32) -> i32:
        self.sema.has_contextual_copy_adjustment_for_sig(self.contextual_fact_sig_idx, node)

    fn contextual_copy_adjustment(node: i32) -> ContextualCopyAdjustment:
        self.sema.contextual_copy_adjustment_for_sig(self.contextual_fact_sig_idx, node)

    fn has_contextual_join_decision(node: i32) -> i32:
        self.sema.has_contextual_join_decision_for_sig(self.contextual_fact_sig_idx, node)

    fn contextual_join_decision(node: i32) -> ContextualJoinDecision:
        self.sema.contextual_join_decision_for_sig(self.contextual_fact_sig_idx, node)
    mut fn new_block() -> BlockId:
        self.body.new_block()

    mut fn switch_to(bb: BlockId):
        self.cur_bb = bb

    fn active_no_suspend_node() -> i32:
        let depth = self.no_suspend_nodes.len() as i32
        if depth == 0:
            return 0
        self.no_suspend_nodes.get((depth - 1) as i64)

    mut fn mark_no_suspend_terminator():
        let node = self.active_no_suspend_node()
        if node != 0:
            self.body.set_term_no_suspend_node(self.cur_bb, node)

    mut fn terminate(kind: i32, d0: i32, d1: i32, d2: i32, d3: i32):
        let span = if self.cur_node > 0: self.ast.get_start(self.cur_node) else: 0
        self.body.set_terminator(self.cur_bb, kind, d0, d1, d2, d3, span)
        self.mark_no_suspend_terminator()

    mut fn terminate_with_span(kind: i32, d0: i32, d1: i32, d2: i32, d3: i32, span: i32):
        self.body.set_terminator(self.cur_bb, kind, d0, d1, d2, d3, span)
        self.mark_no_suspend_terminator()

    fn push_scope() -> Unit:
        if with_getenv_str("WITH_TRACE_SCOPES").len() > 0:
            with_eprint(f"[scope] push depth={self.drop_scope_starts.len() as i32} bb={self.cur_bb as i32}")
        self.drop_scope_starts.push(self.drop_local_ids.len() as i32)
        self.bind_scope_starts.push(self.bind_syms.len() as i32)
        self.alias_scope_starts.push(self.alias_syms.len() as i32)
        self.defer_scope_starts.push(self.defer_nodes.len() as i32)
        self.errdefer_scope_starts.push(self.errdefer_nodes.len() as i32)

    fn schedule_drop(local_id: i32, drop_kind: i32) -> Unit:
        if self.drop_kind_owns_value(drop_kind) != 0 and self.local_value_moved(local_id) != 0:
            self.drop_local_ids.push(local_id)
            self.drop_kinds.push(DropKind.DK_STORAGE)
            return
        self.drop_local_ids.push(local_id)
        self.drop_kinds.push(drop_kind)


    fn fn_node_is_drop_body(fn_node: i32) -> i32:
        let raw_sym = self.ast.get_data0(fn_node)
        let decl_index = self.sema.find_decl_index(fn_node)
        let semantic_sym = self.sema.fn_decl_semantic_symbol_at(fn_node, raw_sym, decl_index)
        if self.sema.drop_owner_for_fn_symbol(semantic_sym) != 0:
            return 1
        let raw_name = self.symbol_text(raw_sym)
        if raw_name.len() == 0:
            return 0
        if raw_name == "drop":
            return 1
        if raw_name.len() > 5 and raw_name.slice(raw_name.len() - 5, raw_name.len()) == ".drop":
            return 1
        let sema_sym = self.sema.pool_lookup_symbol(raw_name)
        if sema_sym != 0 and self.sema.drop_owner_for_fn_symbol(sema_sym) != 0:
            return 1
        0

    fn schedule_with_guard_cleanup(guard_local: i32, payload_local: i32, method_sym: i32, sig_idx: i32, mono_sym: i32, drop_kind: i32) -> Unit:
        self.with_cleanup_guard_locals.push(guard_local)
        self.with_cleanup_payload_locals.push(payload_local)
        self.with_cleanup_method_syms.push(method_sym)
        self.with_cleanup_sigs.push(sig_idx)
        self.with_cleanup_mono_syms.push(mono_sym)
        self.schedule_drop(guard_local, drop_kind)

    fn with_cleanup_index_for_guard(guard_local: i32) -> i32:
        var i = self.with_cleanup_guard_locals.len() as i32 - 1
        while i >= 0:
            if self.with_cleanup_guard_locals.get(i as i64) == guard_local:
                return i
            i = i - 1
        -1

    mut fn operand_for_place_arg(place: i32, actual_ty: i32, expected_ty: i32, span: i32) -> i32:
        if expected_ty != 0 and self.sema.can_auto_ref_arg_frozen(expected_ty, actual_ty) != 0:
            let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, place, 0)
            let temp = self.new_temp(expected_ty)
            let temp_place = self.place_for_local(temp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, span)
            return self.body.new_operand(OperandKind.OK_COPY, temp_place)
        self.operand_for_place(place, actual_ty)

    mut fn emit_with_guard_cleanup(guard_local: i32, drop_kind: i32):
        let cleanup_idx = self.with_cleanup_index_for_guard(guard_local)
        if cleanup_idx < 0:
            return
        let method_sym: i32 = self.with_cleanup_method_syms.get(cleanup_idx as i64)
        let payload_local: i32 = self.with_cleanup_payload_locals.get(cleanup_idx as i64)
        let sig_idx: i32 = self.with_cleanup_sigs.get(cleanup_idx as i64)
        let mono_sym: i32 = self.with_cleanup_mono_syms.get(cleanup_idx as i64)
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
        self.body.set_call_contract(args_id, sig_idx, mono_sym)
        let cleanup_generic_node = self.generic_fn_node_for_sym(method_sym)
        if cleanup_generic_node != 0:
            self.body.set_call_intrinsic(args_id, MirIntrinsic.GENERIC_CALL)
            self.body.set_call_ast_node(args_id, cleanup_generic_node)
            self.body.require_call_contract(args_id)
        let fn_op = self.const_operand(ConstKind.CK_FN, method_sym, self.sema.ty_void as i32)
        let cleanup_ret_ty = if sig_idx >= 0: self.sema.sig_return_type(sig_idx) else: self.sema.ty_void as i32
        let cleanup_ret_local = self.new_temp(cleanup_ret_ty)
        let cleanup_ret_place = self.place_for_local(cleanup_ret_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, cleanup_ret_place, next_bb)
        self.switch_to(next_bb)
        if payload_local > 0:
            self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, payload_local, 0, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, guard_local, 0, 0)

    fn drop_kind_owns_value(drop_kind: i32) -> i32:
        let _ = self
        if drop_kind == DropKind.DK_VALUE or drop_kind == DropKind.DK_TASK_DETACHED or drop_kind == DropKind.DK_TASK_EPHEMERAL or drop_kind == DropKind.DK_ASYNC_SCOPE or drop_kind == DropKind.DK_THREAD_SCOPE:
            return 1
        0

    fn local_value_moved(local_id: i32) -> i32:
        for i in 0..self.moved_value_local_ids.len() as i32:
            if self.moved_value_local_ids.get(i as i64) == local_id:
                return 1
        0

    fn mark_local_value_moved(local_id: i32) -> Unit:
        if local_id < 0:
            return
        if self.local_value_moved(local_id) != 0:
            return
        self.moved_value_local_ids.push(local_id)

    fn clear_local_value_moved(local_id: i32) -> Unit:
        var i = self.moved_value_local_ids.len() as i32 - 1
        while i >= 0:
            if self.moved_value_local_ids.get(i as i64) == local_id:
                let last = self.moved_value_local_ids.len() as i32 - 1
                if i != last:
                    self.moved_value_local_ids.set_i32(i as i64, self.moved_value_local_ids.get(last as i64))
                self.moved_value_local_ids.pop()
                return
            i = i - 1

    fn save_move_state() -> MirMoveStateSnapshot:
        MirMoveStateSnapshot {
            moved_values: mir_clone_i32_vec(&self.moved_value_local_ids),
            field_base_locals: mir_clone_i32_vec(&self.moved_field_base_locals),
            field_path_starts: mir_clone_i32_vec(&self.moved_field_path_starts),
            field_path_counts: mir_clone_i32_vec(&self.moved_field_path_counts),
            field_path_kinds: mir_clone_i32_vec(&self.moved_field_path_kinds),
            field_path_syms: mir_clone_i32_vec(&self.moved_field_path_syms),
        }

    mut fn restore_move_state(snapshot: &MirMoveStateSnapshot):
        self.moved_value_local_ids = mir_clone_i32_vec(&snapshot.moved_values)
        self.moved_field_base_locals = mir_clone_i32_vec(&snapshot.field_base_locals)
        self.moved_field_path_starts = mir_clone_i32_vec(&snapshot.field_path_starts)
        self.moved_field_path_counts = mir_clone_i32_vec(&snapshot.field_path_counts)
        self.moved_field_path_kinds = mir_clone_i32_vec(&snapshot.field_path_kinds)
        self.moved_field_path_syms = mir_clone_i32_vec(&snapshot.field_path_syms)

    fn cancel_scheduled_value_drop_for_local(local_id: i32) -> Unit:
        var i = self.drop_local_ids.len() as i32 - 1
        while i >= 0:
            if self.drop_local_ids.get(i as i64) == local_id and self.drop_kind_owns_value(self.drop_kinds.get(i as i64)) != 0:
                self.drop_kinds.set_i32(i as i64, DropKind.DK_STORAGE)
                return
            i = i - 1

    // Whether `local_id` currently has a scheduled value drop in this scope (an
    // owned local), without cancelling it. A share-place borrow (param) has none.
    fn local_has_scheduled_value_drop(local_id: i32) -> i32:
        var i = self.drop_local_ids.len() as i32 - 1
        while i >= 0:
            if self.drop_local_ids.get(i as i64) == local_id and self.drop_kind_owns_value(self.drop_kinds.get(i as i64)) != 0:
                return 1
            i = i - 1
        0

    // §14.7/G3: whether a value-await on `inner` OWNS the result buffer here and so
    // must free it. True for a temporary/rvalue task and for an owned local (whose
    // own drop the await cancels); false for a borrowed param/local (no scheduled
    // value drop — the owner's Task drop frees the buffer). Mirrors the reach of
    // cancel_scheduled_value_drop_for_receiver_expr for the ident case.
    fn await_task_owns_result(inner: i32) -> i32:
        var e = inner
        while e != 0 and self.ast.kind(e) == NodeKind.NK_GROUPED:
            e = self.ast.get_data0(e)
        if e == 0 or self.ast.kind(e) != NodeKind.NK_IDENT:
            return 1
        let local = self.lookup_local(self.ast.get_data0(e))
        if local < 0:
            return 1
        self.local_has_scheduled_value_drop(local)

    fn moved_field_path_matches(idx: i32, base_local: i32, path_start: i32, path_count: i32) -> i32:
        if idx < 0 or idx >= self.moved_field_base_locals.len() as i32:
            return 0
        if self.moved_field_base_locals.get(idx as i64) != base_local:
            return 0
        if self.moved_field_path_counts.get(idx as i64) != path_count:
            return 0
        let stored_start = self.moved_field_path_starts.get(idx as i64)
        for pi in 0..path_count:
            if self.moved_field_path_kinds.get((stored_start + pi) as i64) != self.body.proj_kinds.get((path_start + pi) as i64):
                return 0
            if self.moved_field_path_syms.get((stored_start + pi) as i64) != self.body.proj_d0.get((path_start + pi) as i64):
                return 0
        1

    fn moved_field_path_has_prefix(idx: i32, base_local: i32, path_start: i32, path_count: i32) -> i32:
        if idx < 0 or idx >= self.moved_field_base_locals.len() as i32:
            return 0
        if self.moved_field_base_locals.get(idx as i64) != base_local:
            return 0
        let stored_count = self.moved_field_path_counts.get(idx as i64)
        if stored_count < path_count:
            return 0
        let stored_start = self.moved_field_path_starts.get(idx as i64)
        for pi in 0..path_count:
            if self.moved_field_path_kinds.get((stored_start + pi) as i64) != self.body.proj_kinds.get((path_start + pi) as i64):
                return 0
            if self.moved_field_path_syms.get((stored_start + pi) as i64) != self.body.proj_d0.get((path_start + pi) as i64):
                return 0
        1

    fn local_has_moved_fields(local_id: i32) -> i32:
        for i in 0..self.moved_field_base_locals.len() as i32:
            if self.moved_field_base_locals.get(i as i64) == local_id:
                return 1
        0

    fn place_moved_field_exact(place: i32) -> i32:
        let path_count = self.place_field_projection_count(place)
        if path_count <= 0:
            return 0
        let base_local = self.place_base_local(place)
        let path_start = self.body.place_proj_starts.get(place as i64)
        for i in 0..self.moved_field_base_locals.len() as i32:
            if self.moved_field_path_matches(i, base_local, path_start, path_count) != 0:
                return 1
        0

    fn place_has_moved_field_descendant(place: i32) -> i32:
        let path_count = self.place_field_projection_count(place)
        if path_count < 0:
            return 0
        let base_local = self.place_base_local(place)
        let path_start = if path_count > 0: self.body.place_proj_starts.get(place as i64) else: 0
        for i in 0..self.moved_field_base_locals.len() as i32:
            if self.moved_field_base_locals.get(i as i64) != base_local:
                continue
            let stored_count = self.moved_field_path_counts.get(i as i64)
            if stored_count <= path_count:
                continue
            if path_count == 0 or self.moved_field_path_has_prefix(i, base_local, path_start, path_count) != 0:
                return 1
        0

    fn mark_place_field_moved(place: i32) -> Unit:
        let path_count = self.place_field_projection_count(place)
        if path_count <= 0:
            return
        let base_local = self.place_base_local(place)
        if base_local < 0:
            return
        let path_start: i32 = self.body.place_proj_starts.get(place as i64)
        for i in 0..self.moved_field_base_locals.len() as i32:
            if self.moved_field_path_matches(i, base_local, path_start, path_count) != 0:
                return
        let stored_start = self.moved_field_path_syms.len() as i32
        for pi in 0..path_count:
            self.moved_field_path_kinds.push(self.body.proj_kinds.get((path_start + pi) as i64))
            self.moved_field_path_syms.push(self.body.proj_d0.get((path_start + pi) as i64))
        self.moved_field_base_locals.push(base_local)
        self.moved_field_path_starts.push(stored_start)
        self.moved_field_path_counts.push(path_count)

    fn remove_moved_field_entry(idx: i32) -> Unit:
        let last = self.moved_field_base_locals.len() as i32 - 1
        if idx < 0 or idx > last:
            return
        if idx != last:
            self.moved_field_base_locals.set_i32(idx as i64, self.moved_field_base_locals.get(last as i64))
            self.moved_field_path_starts.set_i32(idx as i64, self.moved_field_path_starts.get(last as i64))
            self.moved_field_path_counts.set_i32(idx as i64, self.moved_field_path_counts.get(last as i64))
        self.moved_field_base_locals.pop()
        self.moved_field_path_starts.pop()
        self.moved_field_path_counts.pop()

    fn clear_moved_fields_for_local(local_id: i32) -> Unit:
        var i = self.moved_field_base_locals.len() as i32 - 1
        while i >= 0:
            if self.moved_field_base_locals.get(i as i64) == local_id:
                self.remove_moved_field_entry(i)
            i = i - 1

    fn clear_moved_fields_for_place(place: i32) -> Unit:
        let path_count = self.place_field_projection_count(place)
        if path_count < 0:
            return
        let base_local = self.place_base_local(place)
        if path_count == 0:
            self.clear_moved_fields_for_local(base_local)
            return
        let path_start = self.body.place_proj_starts.get(place as i64)
        var i = self.moved_field_base_locals.len() as i32 - 1
        while i >= 0:
            if self.moved_field_path_has_prefix(i, base_local, path_start, path_count) != 0:
                self.remove_moved_field_entry(i)
            i = i - 1

    fn partial_drop_field_count(sema_ty: i32) -> i32:
        if sema_ty <= 0:
            return 0
        let resolved = self.sema.resolve_alias(sema_ty as TypeId) as i32
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_TUPLE:
            return self.sema.get_type_d1(resolved as TypeId)
        self.sema.type_reflection_field_count(resolved)

    fn partial_drop_field_token(sema_ty: i32, field_index: i32) -> i32:
        if sema_ty <= 0 or field_index < 0:
            return 0
        let resolved = self.sema.resolve_alias(sema_ty as TypeId) as i32
        if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_TUPLE:
            return field_index
        self.sema.type_reflection_field_name(resolved, field_index)

    mut fn partial_drop_field_type(sema_ty: i32, field_index: i32) -> i32:
        if sema_ty <= 0 or field_index < 0:
            return 0
        let resolved = self.sema.resolve_alias(sema_ty as TypeId) as i32
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_TUPLE:
            let elem_start = self.sema.get_type_d0(resolved as TypeId)
            let elem_count = self.sema.get_type_d1(resolved as TypeId)
            if field_index >= elem_count:
                return 0
            return self.sema.type_extra.get((elem_start + field_index) as i64)
        self.sema.type_reflection_field_type_frozen(resolved, field_index)

    mut fn emit_drop_place_respecting_moved_fields(place: i32, sema_ty: i32):
        if sema_ty <= 0 or sema_ty == self.sema.ty_void as i32 or sema_ty == self.sema.ty_never as i32:
            return
        if self.place_moved_field_exact(place) != 0:
            return
        if self.place_has_moved_field_descendant(place) != 0:
            // D32 (§2.2/§2.4): a Drop-impl owner with a vacated field is
            // still a WHOLE value — reset-on-move left the field a valid
            // empty value — so its custom drop runs like any other scope
            // exit (the drop glue's runtime guard skips the blank field).
            // Decomposing into per-field drops here would silently discard
            // the user drop (pre-D32 sema made this shape unreachable).
            let pd_owner = self.sema.method_owner_symbol_for_type(self.sema.resolve_alias(sema_ty as TypeId) as i32)
            if pd_owner != 0 and self.sema.has_drop_method(pd_owner) != 0:
                self.emit_drop_stmt(place, "scope-exit", 0)
                return
            let field_count = self.partial_drop_field_count(sema_ty)
            if field_count <= 0:
                return
            var fi = field_count - 1
            while fi >= 0:
                let field_ty = self.partial_drop_field_type(sema_ty, fi)
                if field_ty > 0 and self.sema.type_needs_drop_frozen(field_ty) != 0:
                    let field_token = self.partial_drop_field_token(sema_ty, fi)
                    if field_token != 0 or self.sema.get_type_kind(self.sema.resolve_alias(sema_ty as TypeId)) == TypeKind.TY_TUPLE:
                        let field_place = self.new_projected_field_place(place, field_token, field_ty)
                        self.emit_drop_place_respecting_moved_fields(field_place, field_ty)
                fi = fi - 1
            return
        if self.sema.type_needs_drop_frozen(sema_ty) != 0:
            self.emit_drop_stmt(place, "scope-exit", 0)

    mut fn emit_drop_stmt(place: i32, origin_kind: &str, span: i32):
        let stmt_id = self.body.stmt_count()
        let place_text = mir_place_text(&self.body, place)
        let origin = self.pool.intern(f"drop#{stmt_id} {origin_kind} {place_text}")
        self.body.push_stmt(self.cur_bb, StmtKind.Drop, place, origin, span)

    fn push_stmt_temp_frame() -> i32:
        let depth = self.stmt_temp_starts.len() as i32
        self.stmt_temp_starts.push(self.stmt_temp_locals.len() as i32)
        // #719: remember what was already pending so this frame flushes only the
        // resets ITS OWN statement queues. Flushing from 0 drained the enclosing
        // expression's pending resets — e.g. a struct literal that already
        // consumed field 0 — blanking a value a later field still reads.
        self.stmt_reset_starts.push(self.pending_reset_locals.len() as i32)
        self.stmt_reset_field_starts.push(self.pending_reset_field_places.len() as i32)
        self.stmt_reset_temp_starts.push(self.pending_move_temp_locals.len() as i32)
        depth

    fn stmt_temp_needs_drop(type_id: i32) -> i32:
        if type_id == 0 or type_id == self.sema.ty_void as i32 or type_id == self.sema.ty_never as i32:
            return 0
        if self.type_is_channel_endpoint(type_id) != 0:
            return 1
        if self.sema.is_copy_frozen(type_id as TypeId) != 0:
            return 0
        if self.sema.type_is_task(type_id) != 0 or self.sema.type_is_scoped_task(type_id) != 0 or self.sema.type_is_scoped_join_handle(type_id) != 0:
            return 0
        1

    fn type_is_channel_endpoint(type_id: i32) -> i32:
        if type_id == 0:
            return 0
        let resolved = self.sema.resolve_alias(type_id)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        let base = self.sema.get_generic_inst_base(resolved as i32)
        let base_name = self.sema.pool_resolve(base)
        if base_name == "Sender" or base_name == "Receiver":
            return 1
        0

    fn type_needs_value_drop(type_id: i32) -> i32:
        if self.type_is_channel_endpoint(type_id) != 0:
            return 1
        if self.sema.is_copy_frozen(type_id) == 0:
            return 1
        0

    fn register_stmt_temp(local_id: i32, type_id: i32) -> Unit:
        if self.stmt_temp_starts.len() as i32 == 0:
            return
        if self.stmt_temp_needs_drop(type_id) == 0:
            return
        self.stmt_temp_locals.push(local_id)

    fn cancel_stmt_temp_for_local(local_id: i32) -> Unit:
        var i = self.stmt_temp_locals.len() as i32 - 1
        while i >= 0:
            if self.stmt_temp_locals.get(i as i64) == local_id:
                self.stmt_temp_locals.set_i32(i as i64, -1)
                return
            i = i - 1

    mut fn consume_moved_operand(operand_id: i32) -> Unit:
        if operand_id < 0 or operand_id >= self.body.operand_kinds.len() as i32:
            return
        if with_getenv_str("WITH_TRACE_RESETS").len() > 0:
            with_eprint(f"[consume] op={operand_id} kind={self.body.operand_kinds.get(operand_id as i64)} place={self.body.operand_d0.get(operand_id as i64)}")
        if self.body.operand_kinds.get(operand_id as i64) != OperandKind.OK_MOVE:
            return
        let place = self.body.operand_d0.get(operand_id as i64)
        let local_id = mir_place_plain_local(&self.body, place)
        if local_id >= 0:
            // #747 instance F: a live same-scope view binding rooted in this
            // base would be robbed by the whole-base consume below — see
            // materialize_str_views_of_consumed_base.
            self.materialize_str_views_of_consumed_base(local_id)
            // Reset-on-move (spec §2.5.1): record the moved owned local; the
            // statement boundary (flush_stmt_temp_frame) zeroes it so its later
            // drops — drop-before-overwrite, scope-exit — free nothing. The reset
            // is unconditional, so it does not depend on the move analysis below.
            if self.sema.type_needs_drop_frozen(self.local_type(local_id)) != 0:
                self.pending_reset_locals.push(local_id)
                // Stage 4 (§2.5.2): this local is reset-on-move, so its drop must
                // keep its null guard. Locals never recorded here are never reset,
                // and codegen elides their guard (unconditional drop).
                self.body.mark_local_ever_moved(local_id)
            self.mark_local_value_moved(local_id)
            // §2.5.2: do NOT cancel the scope-exit drop here. emit_drop_entry's
            // dynamic moved-skip already elides the drop while the local is moved;
            // a later reassignment clears the moved mark and restores the value
            // drop, so a moved-then-reassigned local's new value is still dropped.
            // The old permanent downgrade to DK_STORAGE was load-bearing and leaked
            // the reassigned value. Reset-on-move + the guarded drop prevent any
            // double-free if the moved-skip and an analysis bug ever disagree.
            self.cancel_stmt_temp_for_local(local_id)
            self.clear_moved_fields_for_local(local_id)
            return
        if self.place_field_projection_count(place) > 0:
            self.mark_place_field_moved(place)
            // Field-place niche (Slice E): blank a moved Drop-bearing field at the
            // branch/statement boundary so the owner's member-level guarded drop
            // (rt_value_is_zero) skips it. Mirrors the whole-local reset above;
            // scoped via flush_pending_resets_since so a conditional field move
            // resets only on the moving path.
            // #697: the blank is equally required for an UNCONDITIONAL move when
            // the base's value drop is not scheduled in this function (share-place
            // param, borrowed receiver, stmt temp): the owner then drops in the
            // CALLER, where the static moved-field exclusion cannot reach, so
            // reset-on-move (§2.5.1) must hold at runtime. Only a base whose sole
            // drop is in this function may elide the blank in favor of the static
            // exclusion.
            self.queue_field_move_reset(place)

    // #697/D17: blank every moved-out Drop-bearing field at the next
    // pending-reset flush. §2.5.1 makes the runtime reset unconditional: the
    // static moved-field exclusion may optimize this function's eventual drop,
    // but it cannot protect a partially moved aggregate that is subsequently
    // moved whole across a call or assignment boundary. Shared by call-argument
    // field moves (consume_moved_operand) and returned-out field moves
    // (cancel_scheduled_value_drop_for_receiver_expr).
    mut fn queue_field_move_reset(place: i32) -> Unit:
        let field_ty = self.place_local_type(place)
        if field_ty > 0 and self.sema.type_needs_drop_frozen(field_ty) != 0:
            let base_local: i32 = self.body.place_locals.get(place as i64)
            if with_getenv_str("WITH_TRACE_RESETS").len() > 0:
                with_eprint(f"[reset-q] field place={place} ty={field_ty} base={base_local} depth={self.pending_reset_field_places.len() as i32}")
            self.pending_reset_field_places.push(place)
            self.pending_reset_field_types.push(field_ty)
            // The base's drop — scope exit here, or drop-before-overwrite
            // of the blanked field — must keep its niche guard (§2.5.2).
            if base_local >= 0:
                self.body.mark_local_ever_moved(base_local)

    // #747 instance F: a live same-scope view binding whose BASE local is
    // consumed whole (moved as a call argument, assignment source, or
    // explicitly dropped) is robbed — reset-on-move blanks the base's storage
    // and the view's later reads see zeroes (execute_binary_link_plan returned
    // "" after every successful link, failing every -e/run/build). The consumer
    // OWNS the whole base including the viewed field, so unlike the
    // place-reassignment capture in finish_assignment_to_place (which
    // transfers the doomed old value), this capture must mint an INDEPENDENT
    // owner. For str that is a fresh copy via the concat runtime — a one-part
    // RK_STR_CONCAT_N is a pass-through in codegen, so concat with "" forces
    // str_concat_n_copy. The binding is re-bound to the owned local (guarded
    // scope-exit drop) and the alias entry is dead-named.
    // Same-scope only, mirroring the reassignment capture: the capture
    // statement executes exactly as often as the binding is created. Residue
    // (recorded in the #747 handoff): a cross-scope consume and a non-str view
    // type keep the robbed-view behavior.
    mut fn materialize_str_views_of_consumed_base(local_id: i32) -> Unit:
        if self.sema.type_needs_drop_frozen(self.local_type(local_id)) == 0:
            return
        let cap_scope_start = if self.alias_scope_starts.len() as i32 > 0: self.alias_scope_starts.get(self.alias_scope_starts.len() - 1) else: 0
        var cap_ai = self.alias_places.len() as i32 - 1
        while cap_ai >= cap_scope_start:
            let cap_sym: i32 = self.alias_syms.get(cap_ai as i64)
            let cap_place: i32 = self.alias_places.get(cap_ai as i64)
            let cap_ty: i32 = self.alias_types.get(cap_ai as i64)
            if cap_sym != 0 and self.place_base_local(cap_place) == local_id and self.place_field_projection_count(cap_place) > 0 and self.type_id_is_str(cap_ty) != 0:
                let cap_local = self.body.new_local(cap_ty, 0, cap_sym, 1)
                self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, cap_local, 0, 0)
                let cap_parts: Vec[i32] = Vec.new()
                cap_parts.push(self.body.new_operand(OperandKind.OK_COPY, cap_place))
                cap_parts.push(self.lower_str_lit(self.pool.intern("")))
                let cap_args = self.body.new_call_args(cap_parts)
                let cap_rv = self.body.new_rvalue(RvalueKind.RK_STR_CONCAT_N, cap_args, 2, 0)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, self.place_for_local(cap_local), cap_rv, 0)
                self.schedule_drop(cap_local, DropKind.DK_VALUE)
                self.bind_local(cap_sym, cap_local)
                // Dead-name the alias entry; the scope pop still removes it
                // positionally, but lookups now resolve to the owned local.
                self.alias_syms.set_i32(cap_ai as i64, 0)
            cap_ai = cap_ai - 1

    mut fn flush_stmt_temp_frame() -> Unit:
        if self.stmt_temp_starts.len() as i32 == 0:
            return
        let frame_idx = self.stmt_temp_starts.len() as i32 - 1
        let start = self.stmt_temp_starts.get(frame_idx as i64)
        var i = self.stmt_temp_locals.len() as i32 - 1
        while i >= start:
            let local_id: i32 = self.stmt_temp_locals.get(i as i64)
            if local_id >= 0:
                self.emit_drop_entry(local_id, DropKind.DK_VALUE)
            i = i - 1
        while self.stmt_temp_locals.len() as i32 > start:
            self.stmt_temp_locals.pop()
        self.stmt_temp_starts.pop()
        var reset_start = 0
        var reset_field_start = 0
        var reset_temp_start = 0
        if self.stmt_reset_starts.len() as i32 > 0:
            reset_start = self.stmt_reset_starts.get((self.stmt_reset_starts.len() as i32 - 1) as i64)
            reset_field_start = self.stmt_reset_field_starts.get((self.stmt_reset_field_starts.len() as i32 - 1) as i64)
            reset_temp_start = self.stmt_reset_temp_starts.get((self.stmt_reset_temp_starts.len() as i32 - 1) as i64)
            self.stmt_reset_starts.pop()
            self.stmt_reset_field_starts.pop()
            self.stmt_reset_temp_starts.pop()
        self.flush_pending_resets_since(reset_start, reset_field_start, reset_temp_start)

    mut fn flush_pending_resets() -> Unit:
        self.flush_pending_resets_since(0, 0, 0)

    // Reset-on-move (spec §2.5.1): emit `local = <zero>` for each owned local moved
    // since `start`, AFTER the move read it, then truncate the pending list back to
    // `start`. The store is raw (not assign_operand_to_place) so it does not clear
    // the moved-from diagnostic state; it only blanks the runtime storage so the
    // local's later drops (drop-before-overwrite, scope-exit) free nothing.
    // `start` scopes the flush to a branch/statement so an outer-scope move's reset
    // is not emitted inside (and made conditional by) an inner branch.
    mut fn flush_pending_resets_since(start: i32, field_start: i32, temp_start: i32) -> Unit:
        // D16: drop the move-arg temporaries first (their values die at the end
        // of the statement / on the moving path), then blank the moved-from
        // sources. The drops are dominated by the temp's initialization — both
        // land on the same path as the move — so they need no sentinel guard.
        var ti = temp_start
        while ti < self.pending_move_temp_locals.len() as i32:
            let tl: i32 = self.pending_move_temp_locals.get(ti as i64)
            let tl_place = self.place_for_local(tl)
            self.emit_drop_stmt(tl_place, "move-arg-temp", 0)
            ti = ti + 1
        while self.pending_move_temp_locals.len() as i32 > temp_start:
            self.pending_move_temp_locals.pop()
        var ri = start
        while ri < self.pending_reset_locals.len() as i32:
            let rl: i32 = self.pending_reset_locals.get(ri as i64)
            let zop = self.body.gen_zero_operand(self.local_type(rl))
            let rval = self.body.new_rvalue(RvalueKind.RK_USE, zop, 0, 0)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, self.place_for_local(rl), rval, 0)
            ri = ri + 1
        while self.pending_reset_locals.len() as i32 > start:
            self.pending_reset_locals.pop()
        // Field-place niche (Slice E): blank each conditionally-moved Drop-bearing
        // field since `field_start` (scoped like the local resets above, so a
        // conditional field move resets only on the moving path). The owner's
        // existing guarded per-field drop then skips the blanked field.
        var fri = field_start
        while fri < self.pending_reset_field_places.len() as i32:
            let fplace: i32 = self.pending_reset_field_places.get(fri as i64)
            let fty: i32 = self.pending_reset_field_types.get(fri as i64)
            if with_getenv_str("WITH_TRACE_RESETS").len() > 0:
                with_eprint(f"[reset-f] field place={fplace} ty={fty} from={field_start}")
            let fzop = self.body.gen_zero_operand(fty)
            let frval = self.body.new_rvalue(RvalueKind.RK_USE, fzop, 0, 0)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, fplace, frval, 0)
            fri = fri + 1
        while self.pending_reset_field_places.len() as i32 > field_start:
            self.pending_reset_field_places.pop()
            self.pending_reset_field_types.pop()

    mut fn finish_stmt_temp_frame(frame_depth: i32) -> Unit:
        while self.stmt_temp_starts.len() as i32 > frame_depth:
            self.flush_stmt_temp_frame()

    fn task_drop_kind_for_binding(node: i32, bind_ty: i32) -> i32:
        if self.sema.type_is_task(bind_ty) == 0:
            return DropKind.DK_VALUE
        if self.sema.ephemeral_task_binding_nodes.contains(node):
            return DropKind.DK_TASK_EPHEMERAL
        DropKind.DK_TASK_DETACHED

    mut fn emit_task_cancel_call(task_op: i32, intrinsic: MirIntrinsic, node: i32):
        let cancel_args: Vec[i32] = Vec.new()
        cancel_args.push(task_op)
        let cancel_call_id = self.body.new_call_args(cancel_args)
        self.body.set_call_intrinsic(cancel_call_id, intrinsic)
        self.body.set_call_ast_node(cancel_call_id, node)
        let cancel_result_local = self.new_temp(self.sema.ty_i32)
        let cancel_result_place = self.place_for_local(cancel_result_local)
        let after_cancel_bb = self.new_block()
        let cancel_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, cancel_unit, cancel_call_id, cancel_result_place, after_cancel_bb)
        self.switch_to(after_cancel_bb)

    mut fn emit_drop_entry(local_id: i32, drop_kind: i32):
        // Stage 6: M7 drop flags are retired. Conditional moves are handled by the
        // niche — reset-on-move blanks the moved branch, and the guarded drop below
        // skips a blanked value at runtime — so a DK_VALUE drop needs no flag.
        if self.drop_kind_owns_value(drop_kind) != 0 and self.local_value_moved(local_id) != 0:
            self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, 0)
            return
        if drop_kind == DropKind.DK_VALUE and self.local_has_moved_fields(local_id) != 0:
            let place = self.place_for_local(local_id)
            self.emit_drop_place_respecting_moved_fields(place, self.local_type(local_id))
            self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, 0)
            return
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
            let await_all_unit = self.unit_operand()
            self.terminate(TermKind.TK_CALL, await_all_unit, await_all_call_id, await_all_place, after_await_all_bb)
            self.switch_to(after_await_all_bb)

            let destroy_args: Vec[i32] = Vec.new()
            destroy_args.push(self.body.new_operand(OperandKind.OK_COPY, scope_place))
            let destroy_call_id = self.body.new_call_args(destroy_args)
            self.body.set_call_intrinsic(destroy_call_id, MirIntrinsic.SCOPE_DESTROY)
            let destroy_result = self.new_temp(0)
            let destroy_place = self.place_for_local(destroy_result)
            let after_destroy_bb = self.new_block()
            let destroy_unit = self.unit_operand()
            self.terminate(TermKind.TK_CALL, destroy_unit, destroy_call_id, destroy_place, after_destroy_bb)
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
            let join_all_unit = self.unit_operand()
            self.terminate(TermKind.TK_CALL, join_all_unit, join_all_call_id, join_all_place, after_join_all_bb)
            self.switch_to(after_join_all_bb)

            let destroy_args: Vec[i32] = Vec.new()
            destroy_args.push(self.body.new_operand(OperandKind.OK_COPY, scope_place))
            let destroy_call_id = self.body.new_call_args(destroy_args)
            self.body.set_call_intrinsic(destroy_call_id, MirIntrinsic.THREAD_SCOPE_DESTROY)
            let destroy_result = self.new_temp(0)
            let destroy_place = self.place_for_local(destroy_result)
            let after_destroy_bb = self.new_block()
            let destroy_unit = self.unit_operand()
            self.terminate(TermKind.TK_CALL, destroy_unit, destroy_call_id, destroy_place, after_destroy_bb)
            self.switch_to(after_destroy_bb)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, 0)
            return
        let place = self.body.new_place(local_id)
        self.emit_drop_stmt(place, "scope-exit", 0)

    mut fn pop_scope_with_goto(target_bb: i32):
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

    mut fn pop_scope_inline():
        if self.drop_scope_starts.len() as i32 == 0:
            return
        if with_getenv_str("WITH_TRACE_SCOPES").len() > 0:
            with_eprint(f"[scope] pop depth={self.drop_scope_starts.len() as i32 - 1} bb={self.cur_bb as i32}")

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

    mut fn emit_drops_for_break(loop_info: LoopInfo):
        var i = self.drop_local_ids.len() as i32 - 1
        while i >= loop_info.break_drop_depth:
            self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
            i = i - 1

    mut fn emit_defers_for_range(start: i32, end: i32):
        var i = end - 1
        while i >= start:
            let defer_body: i32 = self.defer_nodes.get(i as i64)
            let _ = self.lower_expr(defer_body)
            i = i - 1

    mut fn emit_drops_for_range(start: i32, end: i32):
        var i = end - 1
        while i >= start:
            self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
            i = i - 1

    mut fn emit_cleanup_to_target(target: LoopInfo):
        var scope_idx = self.drop_scope_starts.len() as i32 - 1
        var lowest_drop_start = self.drop_local_ids.len() as i32
        var lowest_defer_start = self.defer_nodes.len() as i32
        while scope_idx >= target.break_scope_depth:
            let defer_start: i32 = self.defer_scope_starts.get(scope_idx as i64)
            let defer_end = if scope_idx + 1 < self.defer_scope_starts.len() as i32: self.defer_scope_starts.get((scope_idx + 1) as i64) else: self.defer_nodes.len() as i32
            lowest_defer_start = defer_start
            self.emit_defers_for_range(defer_start, defer_end)

            let drop_start: i32 = self.drop_scope_starts.get(scope_idx as i64)
            let drop_end = if scope_idx + 1 < self.drop_scope_starts.len() as i32: self.drop_scope_starts.get((scope_idx + 1) as i64) else: self.drop_local_ids.len() as i32
            lowest_drop_start = drop_start
            self.emit_drops_for_range(drop_start, drop_end)
            scope_idx = scope_idx - 1

        self.emit_defers_for_range(target.break_defer_depth, lowest_defer_start)
        self.emit_drops_for_range(target.break_drop_depth, lowest_drop_start)

    mut fn emit_drops_for_return():
        var i = self.drop_local_ids.len() as i32 - 1
        while i >= 0:
            self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
            i = i - 1

    mut fn emit_defers_for_return():
        var i = self.defer_nodes.len() as i32 - 1
        while i >= 0:
            let defer_body: i32 = self.defer_nodes.get(i as i64)
            let _ = self.lower_expr(defer_body)
            i = i - 1

    mut fn emit_errdefers_for_return():
        var i = self.errdefer_nodes.len() as i32 - 1
        while i >= 0:
            let errdefer_body: i32 = self.errdefer_nodes.get(i as i64)
            let _ = self.lower_expr(errdefer_body)
            i = i - 1

    fn push_control_target(label: i32, target_kind: i32, continue_bb: i32, break_bb: i32, result_place: i32) -> Unit:
        self.loop_continue_bbs.push(continue_bb)
        self.loop_break_bbs.push(break_bb)
        self.loop_result_places.push(result_place)
        self.loop_break_drop_depths.push(self.drop_local_ids.len() as i32)
        self.loop_break_defer_depths.push(self.defer_nodes.len() as i32)
        self.loop_break_scope_depths.push(self.drop_scope_starts.len() as i32)
        self.loop_labels.push(label)
        self.loop_target_kinds.push(target_kind)

    fn pop_control_target():
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

    fn find_control_target(label: i32, want_continue: i32) -> LoopInfo:
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

    fn find_goto_label_index(label: i32) -> i32:
        var i = 0
        while i < self.goto_label_syms.len() as i32:
            if self.goto_label_syms.get(i as i64) == label:
                return i
            i = i + 1
        -1

    mut fn ensure_goto_label(label: i32, scope_depth: i32) -> i32:
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

    mut fn collect_goto_label_depths(node: i32, scope_depth: i32):
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
        if kind == NodeKind.NK_MAP_LIT:
            let pair_start = self.ast.get_data0(node)
            let pair_count = self.ast.get_data1(node)
            for mi in 0..pair_count:
                self.collect_goto_label_depths(self.ast.get_extra(pair_start + mi * 2), scope_depth)
                self.collect_goto_label_depths(self.ast.get_extra(pair_start + mi * 2 + 1), scope_depth)
            return
        if kind == NodeKind.NK_ARRAY_COMPREHENSION:
            let comp_start = self.ast.get_data1(node)
            let clause_count = self.ast.get_data2(node)
            for ci in 0..clause_count:
                let base = comp_start + ci * 3
                self.collect_goto_label_depths(self.ast.get_extra(base + 1), scope_depth)
                self.collect_goto_label_depths(self.ast.get_extra(base + 2), scope_depth)
            self.collect_goto_label_depths(self.ast.get_data0(node), scope_depth)
            return
        if kind == NodeKind.NK_MAP_COMPREHENSION:
            let comp_start = self.ast.get_data0(node)
            let clause_count = self.ast.get_data1(node)
            for ci in 0..clause_count:
                let base = comp_start + 2 + ci * 3
                self.collect_goto_label_depths(self.ast.get_extra(base + 1), scope_depth)
                self.collect_goto_label_depths(self.ast.get_extra(base + 2), scope_depth)
            self.collect_goto_label_depths(self.ast.get_extra(comp_start), scope_depth)
            self.collect_goto_label_depths(self.ast.get_extra(comp_start + 1), scope_depth)
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

    mut fn define_goto_label(label: i32) -> i32:
        let idx = self.ensure_goto_label(label, self.drop_scope_starts.len() as i32)
        let bb: i32 = self.goto_label_bbs.get(idx as i64)
        self.goto_label_drop_depths.set_i32(idx as i64, self.drop_local_ids.len() as i32)
        self.goto_label_defer_depths.set_i32(idx as i64, self.defer_nodes.len() as i32)
        self.goto_label_scope_depths.set_i32(idx as i64, self.drop_scope_starts.len() as i32)
        self.goto_label_defined.set_i32(idx as i64, 1)
        if self.cur_bb != bb and self.body.term_kind(self.cur_bb) == TermKind.TK_UNREACHABLE:
            self.terminate(TermKind.TK_GOTO, bb, 0, 0, 0)
        self.switch_to(bb as BlockId)
        bb

    mut fn goto_target_info(label: i32) -> LoopInfo:
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
        var scope_depth: i32 = self.goto_label_scope_depths.get(idx as i64)
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

    fn bind_local(sym: i32, local_id: i32) -> Unit:
        self.bind_syms.push(sym)
        self.bind_local_ids.push(local_id)

    fn bind_alias_place(sym: i32, place: i32, ty: i32) -> Unit:
        self.alias_syms.push(sym)
        self.alias_places.push(place)
        self.alias_types.push(ty)

    fn symbol_text(sym: i32) -> &str:
        let pool_text = self.pool.resolve_symbol(sym)
        if pool_text.len() > 0:
            return pool_text
        self.sema.pool_resolve(sym)

    fn symbols_match(a: i32, b: i32) -> bool:
        if a == b:
            return true
        let a_text = self.symbol_text(a)
        a_text.len() > 0 and a_text == self.symbol_text(b)

    fn sema_symbol_for_ast_symbol(sym: i32) -> i32:
        if sym == 0:
            return 0
        let text = self.pool.resolve_symbol(sym)
        if text.len() == 0:
            return sym
        let sema_sym = self.sema.pool_lookup_symbol(text)
        if sema_sym != 0:
            return sema_sym
        sym

    fn lookup_local(sym: i32) -> i32:
        var i = self.bind_syms.len() as i32 - 1
        while i >= 0:
            if self.symbols_match(self.bind_syms.get(i as i64), sym):
                return self.bind_local_ids.get(i as i64)
            i = i - 1
        -1

    fn lookup_alias_place(sym: i32) -> i32:
        var i = self.alias_syms.len() as i32 - 1
        while i >= 0:
            if self.symbols_match(self.alias_syms.get(i as i64), sym):
                return self.alias_places.get(i as i64)
            i = i - 1
        -1

    fn lookup_alias_type(sym: i32) -> i32:
        var i = self.alias_syms.len() as i32 - 1
        while i >= 0:
            if self.symbols_match(self.alias_syms.get(i as i64), sym):
                return self.alias_types.get(i as i64)
            i = i - 1
        0

    mut fn concrete_type(type_id: i32) -> i32:
        if type_id <= 0:
            return type_id
        let subst_count = self.sema.generic_subst_param_syms.len() as i32
        if subst_count == 0:
            return type_id
        self.sema.substitute_type(type_id, self.sema.generic_subst_param_syms, self.sema.generic_subst_type_ids, subst_count)

    mut fn expr_type(node: i32) -> i32:
        if node == 0:
            return self.sema.ty_void as i32
        if self.sema.typed_expr_types.contains(node):
            let typed: i32 = self.sema.typed_expr_types.get(node).unwrap()
            if typed != 0:
                let node_kind = self.ast.kind(node)
                if typed == self.sema.ty_void as i32 and (node_kind == NodeKind.NK_IDENT or node_kind == NodeKind.NK_FIELD_ACCESS or node_kind == NodeKind.NK_BINARY or node_kind == NodeKind.NK_UNARY):
                    return self.fallback_expr_type(node)
                return self.concrete_type(typed as i32)
        self.fallback_expr_type(node)

    fn mir_const_int_width(type_id: i32) -> i32:
        let numeric = self.sema.numeric_operand_type(type_id)
        let resolved = self.sema.resolve_alias(numeric as TypeId)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_INT:
            return self.sema.get_type_d0(resolved)
        64

    fn mir_const_int_is_unsigned(type_id: i32) -> bool:
        let numeric = self.sema.numeric_operand_type(type_id)
        let resolved = self.sema.resolve_alias(numeric as TypeId)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_INT:
            return self.sema.get_type_d1(resolved) == 0
        false

    mut fn binding_type(node: i32) -> i32:
        if self.sema.typed_binding_types.contains(node):
            let typed: i32 = self.sema.typed_binding_types.get(node).unwrap()
            if typed != 0:
                return self.concrete_type(typed as i32)
        let flags = self.ast.get_data2(node)
        let ann_extra = self.sema.local_let_type_ann_extra(flags)
        if ann_extra >= 0:
            let ann_node = self.ast.get_extra(ann_extra)
            let ann_type = self.sema.resolve_type_expr_frozen(ann_node)
            if ann_type != 0:
                return self.concrete_type(ann_type as i32)
        let rhs = self.ast.get_data1(node)
        let rhs_ty = self.expr_type(rhs)
        if rhs_ty != 0:
            return self.concrete_type(rhs_ty)
        self.sema.ty_void as i32

    fn local_type(local_id: i32) -> i32:
        if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
            return self.sema.ty_void as i32
        self.body.local_type_ids.get(local_id as i64) as i32

    mut fn ident_type(sym: i32) -> i32:
        let sym_text = self.pool.resolve_symbol(sym)
        if sym_text == "__FILE__" or sym_text == "__FN__":
            return self.sema.ty_str as i32
        if sym_text == "__LINE__":
            return self.sema.ty_u32 as i32
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
        let module_const_ty = self.try_resolve_module_const_type(sym)
        if module_const_ty != 0:
            return module_const_ty
        self.sema.ty_void as i32

    mut fn resolve_index_generic_inst(node: i32) -> i32:
        // Resolve NodeKind.NK_INDEX(NodeKind.NK_IDENT("Vec"), type_arg) to a TypeKind.TY_GENERIC_INST.
        // Used for Vec[i32].new() and HashMap[str, i32].new().
        // Sema.check_index creates these during the check pass; we only look up here.
        let whole_type = self.sema.resolve_type_level_arg_expr_frozen(node)
        if whole_type > 0:
            let whole_resolved = self.sema.resolve_alias(whole_type as TypeId)
            if self.sema.get_type_kind(whole_resolved) == TypeKind.TY_GENERIC_INST:
                return whole_resolved as i32
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

    mut fn resolve_type_arg_node(type_arg_node: i32) -> i32:
        self.sema.resolve_type_level_arg_expr_frozen(type_arg_node)

    mut fn type_receiver_type(node: i32) -> i32:
        // Resolve a type-level receiver expression to its base sema type.
        // Used for intrinsic classification (Vec, HashMap, etc.)
        // Handles: Vec (NodeKind.NK_IDENT), Vec[i32] (NodeKind.NK_INDEX of NodeKind.NK_IDENT)
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_GENERIC or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_TUPLE or kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_EXTERN_FN or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
            return self.sema.resolve_type_expr_frozen(node) as i32
        if self.ast.kind(node) == NodeKind.NK_IDENT:
            let sym = self.ast.get_data0(node)
            if self.sema.named_types.contains(sym):
                return self.sema.named_types.get(sym).unwrap()
        if self.ast.kind(node) == NodeKind.NK_INDEX:
            let indexed_ty = self.sema.resolve_type_level_arg_expr_frozen(node)
            if indexed_ty != 0:
                return indexed_ty
            let base = self.ast.get_data0(node)
            if self.ast.kind(base) == NodeKind.NK_IDENT:
                let sym = self.ast.get_data0(base)
                if self.sema.named_types.contains(sym):
                    return self.sema.named_types.get(sym).unwrap()
        0

    fn index_expr_is_type_level(expr: i32) -> bool:
        if expr == 0:
            return false
        let kind = self.ast.kind(expr)
        if kind == NodeKind.NK_IDENT:
            let sym = self.ast.get_data0(expr)
            return self.sema.named_types.contains(sym)
        if kind == NodeKind.NK_INDEX or kind == NodeKind.NK_GROUPED:
            return self.index_expr_is_type_level(self.ast.get_data0(expr))
        false

    mut fn vec_literal_type(node: i32) -> i32:
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

    fn collection_len_method_return_type(method_name: &str) -> i32:
        if method_name == "len":
            return self.sema.ty_usize as i32
        if method_name == "is_empty":
            return self.sema.ty_bool as i32
        if method_name == "len32":
            return self.sema.ty_i32 as i32
        if method_name == "len64":
            return self.sema.ty_i64 as i32
        if method_name == "ulen32":
            return self.sema.ty_u32 as i32
        0

    mut fn call_return_type(callee: i32) -> i32:
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
                let method_name: str = with_str_clone_ref(self.pool.resolve_symbol(method_sym))
                let iret = self.intrinsic_return_type(base_ty, method_name)
                if iret != 0 and iret != self.sema.ty_void as i32:
                    return iret
            // Qualified enum variant constructor: EnumType.Variant(...)
            let recv_ty = if base_ty != 0 and base_ty != self.sema.ty_void as i32: base_ty else: self.type_receiver_type(base)
            if recv_ty != 0 and recv_ty != self.sema.ty_void as i32 and self.sema.enum_has_variant(recv_ty, method_sym) != 0:
                return recv_ty
        self.sema.ty_void as i32

    mut fn intrinsic_return_type(recv_type: i32, method_name: &str) -> i32:
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
                if method_name == "push" or method_name == "set_i32" or method_name == "clear":
                    return self.sema.ty_void as i32
                if method_name == "get" or method_name == "remove":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.get_generic_inst_arg(resolved, 0)
                if method_name == "pop":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.find_option_type_for(self.sema.get_generic_inst_arg(resolved, 0))
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
                        return self.sema.find_handle_type_for(elem_ty)
                    if method_name == "get":
                        return self.sema.find_option_ref_type_for(elem_ty)
                    if method_name == "slot":
                        return self.sema.find_slotmapslot_type_for(elem_ty)
                    if method_name == "get_disjoint":
                        let slot_ty = self.sema.find_slotmapslot_type_for(elem_ty)
                        let elems: Vec[i32] = Vec.new()
                        elems.push(slot_ty)
                        elems.push(slot_ty)
                        return self.sema.find_tuple_type(elems, 2) as i32
                    if method_name == "remove" or method_name == "replace":
                        return self.sema.find_option_type_for(elem_ty)
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
                            vs_tid = self.sema.find_generic_inst_type(vs_sym, vs_args, 1) as i32
                        let opt_sym = self.sema.pool_lookup_symbol("Option")
                        let opt_tid = self.sema.find_generic_inst(opt_sym, vs_tid)
                        if opt_tid != 0:
                            return opt_tid
                        let opt_args: Vec[i32] = Vec.new()
                        opt_args.push(vs_tid)
                        return self.sema.find_generic_inst_type(opt_sym, opt_args, 1) as i32
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
                if tk == TypeKind.TY_GENERIC_INST:
                    let value_ty = self.sema.get_generic_inst_arg(resolved, 1)
                    if method_name == "get":
                        return self.sema.find_option_ref_type_for(value_ty)
                    if method_name == "remove":
                        return self.sema.find_option_type_for(value_ty)
                if method_name == "values":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.find_vec_type_for(self.sema.get_generic_inst_arg(resolved, 1))
                if method_name == "items":
                    if tk == TypeKind.TY_GENERIC_INST:
                        let elems: Vec[i32] = Vec.new()
                        elems.push(self.sema.get_generic_inst_arg(resolved, 0))
                        elems.push(self.sema.get_generic_inst_arg(resolved, 1))
                        return self.sema.find_vec_type_for(self.sema.find_tuple_type(elems, 2) as i32)
                if method_name == "entry":
                    if tk == TypeKind.TY_GENERIC_INST:
                        let ek = self.sema.get_generic_inst_arg(resolved, 0)
                        let ev = self.sema.get_generic_inst_arg(resolved, 1)
                        let he_sym = self.sema.pool_lookup_symbol("HashMapEntry")
                        let he_args: Vec[i32] = Vec.new()
                        he_args.push(ek)
                        he_args.push(ev)
                        return self.sema.find_generic_inst_type(he_sym, he_args, 2) as i32
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
                if method_name == "unwrap" or method_name == "expect":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.get_generic_inst_arg(resolved, 0)
                if method_name == "filter":
                    return recv_type
                if method_name == "map" or method_name == "and_then" or method_name == "or_else" or method_name == "inspect":
                    return recv_type
                if method_name == "copied" or method_name == "cloned":
                    if tk == TypeKind.TY_GENERIC_INST:
                        let view_ty = self.sema.get_generic_inst_arg(resolved, 0)
                        let view_resolved = self.sema.resolve_alias(view_ty as TypeId)
                        if self.sema.get_type_kind(view_resolved) == TypeKind.TY_REF and self.sema.get_type_d1(view_resolved) == 0:
                            return self.sema.find_option_type_for(self.sema.get_type_d0(view_resolved))
                if method_name == "unwrap_or":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.get_generic_inst_arg(resolved, 0)
                if method_name == "unwrap_or_else":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.get_generic_inst_arg(resolved, 0)
                if method_name == "flatten":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.get_generic_inst_arg(resolved, 0)
                return self.sema.ty_void as i32
            if type_name == "Result":
                if method_name == "is_ok": return self.sema.ty_bool as i32
                if method_name == "unwrap" or method_name == "expect":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.get_generic_inst_arg(resolved, 0)
                if method_name == "unwrap_or_else":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.get_generic_inst_arg(resolved, 0)
                if method_name == "inspect" or method_name == "inspect_err":
                    return recv_type
                return self.sema.ty_void as i32
            if type_name == "Atomic":
                if method_name == "new": return recv_type
                if method_name == "store": return self.sema.ty_void as i32
                if method_name == "load" or method_name == "swap" or method_name == "fetch_add" or method_name == "fetch_sub" or method_name == "fetch_and" or method_name == "fetch_or" or method_name == "fetch_xor" or method_name == "fetch_min" or method_name == "fetch_max":
                    if tk == TypeKind.TY_GENERIC_INST:
                        return self.sema.get_generic_inst_arg(resolved, 0)
                if method_name == "compare_exchange" or method_name == "compare_exchange_weak":
                    if tk == TypeKind.TY_GENERIC_INST:
                        let atomic_payload = self.sema.get_generic_inst_arg(resolved, 0)
                        return self.sema.find_result_type_for(atomic_payload, atomic_payload)
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

    mut fn struct_field_type(struct_tid: i32, field_sym: i32) -> i32:
        let resolved = self.sema.resolve_alias(struct_tid)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
            let inner = self.sema.get_type_d0(resolved)
            return self.struct_field_type(inner, field_sym)
        let direct = self.sema.struct_field_type_frozen(resolved as i32, field_sym)
        if direct != 0:
            return direct
        let field_text = self.pool.resolve_symbol(field_sym)
        let sema_field = if field_text.len() > 0: self.sema.pool_lookup_symbol(field_text) else: 0
        if sema_field != 0 and sema_field != field_sym:
            return self.sema.struct_field_type_frozen(resolved as i32, sema_field)
        0

    fn tuple_elem_type(tuple_tid: i32, field_idx: i32) -> i32:
        let resolved = self.sema.resolve_alias(tuple_tid)
        let tk = self.sema.get_type_kind(resolved)
        if tk != TypeKind.TY_TUPLE:
            return 0
        let elem_start = self.sema.get_type_d0(resolved)
        let elem_count = self.sema.get_type_d1(resolved)
        if field_idx < 0 or field_idx >= elem_count:
            return 0
        self.sema.type_extra.get((elem_start + field_idx) as i64)

    fn tuple_index_from_field_token(tuple_tid: i32, field_token: i32) -> i32:
        let resolved = self.sema.resolve_alias(tuple_tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_TUPLE:
            return -1
        let elem_count = self.sema.get_type_d1(resolved)
        if field_token >= 0 and field_token < elem_count:
            return field_token
        var field_name = self.pool.resolve_symbol(field_token)
        if field_name.len() == 0:
            field_name = self.sema.pool_resolve(field_token)
        if field_name.len() == 0:
            return -1
        var idx = 0
        for vi in 0..field_name.len() as i32:
            let ch = field_name.byte_at(vi as i64)
            if ch >= 48 and ch <= 57:
                idx = idx * 10 + (ch - 48)
            else:
                return -1
        if idx >= 0 and idx < elem_count:
            return idx
        -1

    mut fn new_projected_field_place(base: i32, field_token: i32, field_ty: i32) -> i32:
        var base_ty = self.place_local_type(base)
        if base_ty > 0 and base_ty != self.sema.ty_void as i32:
            var resolved = self.sema.resolve_alias(base_ty)
            var tk = self.sema.get_type_kind(resolved)
            while tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                base_ty = self.sema.get_type_d0(resolved)
                resolved = self.sema.resolve_alias(base_ty)
                tk = self.sema.get_type_kind(resolved)
            if tk == TypeKind.TY_TUPLE:
                let tuple_idx = self.tuple_index_from_field_token(resolved as i32, field_token)
                if tuple_idx >= 0:
                    return self.body.new_tuple_index_place(base, tuple_idx, field_ty)
        self.body.new_field_place(base, field_token, field_ty)

    fn indexed_element_type(collection_tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(collection_tid) as i32
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
            return self.sema.get_type_d0(resolved)
        if tk == TypeKind.TY_STR:
            return self.sema.ty_i32 as i32
        if tk == TypeKind.TY_PTR:
            return self.sema.get_type_d0(resolved)
        if tk == TypeKind.TY_REF:
            return self.indexed_element_type(self.sema.get_type_d0(resolved))
        if tk == TypeKind.TY_GENERIC_INST:
            let base_sym = self.sema.get_generic_inst_base(resolved)
            if self.pool.resolve_symbol(base_sym) == "Vec" and self.sema.get_generic_inst_arg_count(resolved) > 0:
                return self.sema.get_generic_inst_arg(resolved, 0)
        0

    mut fn assignment_place_value_type(node: i32) -> i32:
        if node == 0:
            return 0
        let exact = self.expr_type(node)
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_NO_SUSPEND:
            return self.assignment_place_value_type(self.ast.get_data0(node))
        // D27's subscript read is &T, but the corresponding IndexPlace slot
        // stores T. Keep assignment/codegen expectations on the physical slot.
        if kind == NodeKind.NK_INDEX and self.index_expr_is_type_level(self.ast.get_data0(node)) == 0:
            let resolved = self.sema.resolve_alias(exact as TypeId)
            if self.sema.get_type_kind(resolved) == TypeKind.TY_REF:
                return self.sema.get_type_d0(resolved)
        exact

    fn is_user_index_place(base_ty: i32) -> i32:
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

    mut fn enum_payload_type(enum_tid: i32, variant_idx: i32, field_idx: i32) -> i32:
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
                    let payload_types = self.sema.enum_variant_payload_types_frozen(resolved, variant_name)
                    if field_idx < payload_types.len() as i32:
                        let payload_ty = payload_types.get(field_idx as i64)
                        if payload_ty != 0:
                            return payload_ty
                    if field_idx < payload_count:
                        return self.sema.type_extra.get((pos + 2 + field_idx) as i64)
                    return 0
                pos = pos + 2 + payload_count
        0

    // D22: value arithmetic sees through a &T view operand to T; sema
    // materializes the operand, so the result type must be the element type.
    fn deref_view_operand_type(ty: i32) -> i32:
        if ty == 0 or ty == self.sema.ty_void as i32:
            return ty
        let resolved = self.sema.resolve_alias(ty) as i32
        if self.sema.get_type_kind(resolved) == TypeKind.TY_REF:
            return self.sema.get_type_d0(resolved)
        ty

    mut fn fallback_expr_type(node: i32) -> i32:
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
                return self.sema.optional_chain_method_result_type_no_check_frozen(base_ty, self.ast.get_data1(node)) as i32
            self.sema.optional_chain_result_type_frozen(base_ty, self.ast.get_data1(node)) as i32
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
            let regex_ty = self.sema.lookup_named_type_ambient(self.sema.syms.regex)
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
                        let asm_rt = self.sema.resolve_type_expr_frozen(asm_ot)
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
        if kind == NodeKind.NK_SLICE:
            let base_ty = self.expr_type(self.ast.get_data0(node))
            if base_ty != 0:
                let resolved = self.sema.resolve_alias(base_ty as TypeId)
                let tk = self.sema.get_type_kind(resolved)
                if tk == TypeKind.TY_ARRAY:
                    return self.sema.find_exact_type(TypeKind.TY_SLICE, self.sema.get_type_d0(resolved), 0, 0) as i32
                if tk == TypeKind.TY_SLICE:
                    return resolved as i32
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
                    if self.sema.types_compatible_frozen(match_ty, arm_ty) != 0:
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
            // D22: a &T operand is a view; value arithmetic auto-derefs it to T
            // (sema materializes the operand). Only raw *T stays address math.
            let lhs_ty = self.deref_view_operand_type(self.expr_type(self.ast.get_data1(node)))
            let rhs_ty = self.deref_view_operand_type(self.expr_type(self.ast.get_data2(node)))
            if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE or op == BinaryOp.OP_AND or op == BinaryOp.OP_OR:
                return self.sema.ty_bool as i32
            if lhs_ty != 0 and lhs_ty != self.sema.ty_void as i32:
                let lhs_resolved = self.sema.resolve_alias(lhs_ty) as i32
                let lhs_tk = self.sema.get_type_kind(lhs_resolved)
                if op == BinaryOp.OP_SUB and lhs_tk == TypeKind.TY_PTR:
                    if rhs_ty != 0 and rhs_ty != self.sema.ty_void as i32:
                        let rhs_resolved = self.sema.resolve_alias(rhs_ty) as i32
                        let rhs_tk = self.sema.get_type_kind(rhs_resolved)
                        if rhs_tk == TypeKind.TY_PTR:
                            return self.sema.ty_isize as i32
                if (op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB) and lhs_tk == TypeKind.TY_PTR:
                    return lhs_ty
            if rhs_ty != 0 and rhs_ty != self.sema.ty_void as i32:
                let rhs_resolved = self.sema.resolve_alias(rhs_ty) as i32
                let rhs_tk = self.sema.get_type_kind(rhs_resolved)
                if op == BinaryOp.OP_ADD and rhs_tk == TypeKind.TY_PTR:
                    return rhs_ty
            if lhs_ty != 0 and lhs_ty == rhs_ty:
                return lhs_ty
            // Keep place materialization aligned with ordinary binary lowering.
            // Repr-enum arithmetic such as `i32 + FnFlags` has an i32 result
            // even though the two operand type IDs are not identical.
            let arithmetic_ty = self.sema.arithmetic_result_type(lhs_ty as TypeId, rhs_ty as TypeId)
            if arithmetic_ty != 0:
                return arithmetic_ty as i32
        if kind == NodeKind.NK_UNARY:
            let uop = self.ast.get_data0(node)
            if uop == UnaryOp.UOP_NOT:
                return self.sema.ty_bool as i32
            if uop == UnaryOp.UOP_NEGATE or uop == UnaryOp.UOP_BIT_NOT:
                return self.deref_view_operand_type(self.expr_type(self.ast.get_data1(node)))
            if uop == UnaryOp.UOP_TRY:
                let inner_node = self.ast.get_data1(node)
                let inner_ty = self.expr_type(inner_node)
                let unwrapped = self.sema.try_unwrapped_type_frozen(inner_ty) as i32
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
            // #687: the inverse of DEREF — `&x` / `&raw const/mut x` build a
            // ref/ptr TO the operand's type. Missing here, `&(*(p as *const
            // T))` fell through to void: the ref temp was void-typed and the
            // fn's return slot got `const ()` instead of the reference, so the
            // raw-to-ref reborrow returned garbage and segfaulted (the temp
            // materialization is fine; only the type lookup was absent). The
            // ref type already exists post-freeze (sema built the signature),
            // so this is a pure frozen lookup.
            if uop == UnaryOp.UOP_REF:
                let inner_ty = self.expr_type(self.ast.get_data1(node))
                if inner_ty != 0 and inner_ty != self.sema.ty_void as i32:
                    let ref_ty = self.sema.find_exact_type(TypeKind.TY_REF, inner_ty, 0, 0) as i32
                    if ref_ty != 0:
                        return ref_ty
            if uop == UnaryOp.UOP_RAW_REF_CONST or uop == UnaryOp.UOP_RAW_REF_MUT:
                let inner_ty = self.expr_type(self.ast.get_data1(node))
                if inner_ty != 0 and inner_ty != self.sema.ty_void as i32:
                    let raw_mut = if uop == UnaryOp.UOP_RAW_REF_MUT: 1 else: 0
                    let ptr_ty = self.sema.find_exact_type(TypeKind.TY_PTR, inner_ty, raw_mut, 0) as i32
                    if ptr_ty != 0:
                        return ptr_ty
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

    mut fn place_local_type(place_id: i32) -> i32:
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
            let proj_d0: i32 = self.body.proj_d0.get((proj_start + pi) as i64)
            let resolved = self.sema.resolve_alias(current_ty) as i32
            let tk = self.sema.get_type_kind(resolved)

            if proj_kind == ProjKind.PK_DOWNCAST:
                if tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST:
                    active_variant_idx = proj_d0
                    continue
                return self.sema.ty_void as i32

            if proj_kind == ProjKind.PK_TUPLE_INDEX:
                let field_ty = self.tuple_elem_type(current_ty, proj_d0)
                if field_ty == 0:
                    return self.sema.ty_void as i32
                current_ty = field_ty
                active_variant_idx = -1
                continue

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

    mut fn new_deref_place(base: i32) -> i32:
        let base_ty = self.place_local_type(base)
        if base_ty <= 0:
            return self.body.new_deref_place(base, 0)
        let resolved = self.sema.resolve_alias(base_ty as TypeId)
        let kind = self.sema.get_type_kind(resolved)
        let pointee = if kind == TypeKind.TY_PTR or kind == TypeKind.TY_REF: self.sema.get_type_d0(resolved) else: 0
        self.body.new_deref_place(base, pointee)

    mut fn operand_type(operand_id: i32) -> i32:
        if operand_id < 0 or operand_id >= self.body.operand_kinds.len() as i32:
            return self.sema.ty_void as i32
        let kind = self.body.operand_kinds.get(operand_id as i64)
        let data: i32 = self.body.operand_d0.get(operand_id as i64)
        if kind == OperandKind.OK_CONSTANT:
            if data >= 0 and data < self.body.const_types.len() as i32:
                return self.body.const_types.get(data as i64)
            return self.sema.ty_void as i32
        if kind == OperandKind.OK_COPY or kind == OperandKind.OK_MOVE:
            return self.place_local_type(data)
        self.sema.ty_void as i32

    fn variant_index(variant_sym: i32) -> i32:
        if variant_sym == 0:
            return 0
        if self.sema.variant_lookup.contains(variant_sym):
            return self.sema.variant_lookup.get(variant_sym).unwrap()
        0

    fn enum_variant_index_for_type(enum_ty: i32, variant_sym: i32) -> i32:
        let index = self.sema.enum_variant_index_for_type(enum_ty, variant_sym)
        if index >= 0:
            return index
        self.variant_index(variant_sym)

    mut fn enum_variant_discriminant_for_type(enum_ty: i32, variant_sym: i32) -> i32:
        let disc = self.sema.enum_variant_discriminant_for_type(enum_ty, variant_sym)
        if disc >= 0:
            return disc
        self.variant_index(variant_sym)

    // Resolve variant sym from an AST node, checking sema's comprehension sidecar first.
    fn resolve_variant_sym(node: i32) -> i32:
        let sym = self.ast.get_data0(node)
        if self.sema.comp_resolved.contains(node):
            return self.sema.comp_resolved.get(node).unwrap()
        sym

    fn resolve_comprehension_marker_variant(variant_sym: i32, enum_ty: i32) -> i32:
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

    fn success_variant_index() -> i32:
        let some_sym = self.pool.intern("Some")
        if self.sema.variant_lookup.contains(some_sym):
            return self.variant_index(some_sym)
        let ok_sym = self.pool.intern("Ok")
        if self.sema.variant_lookup.contains(ok_sym):
            return self.variant_index(ok_sym)
        1

    mut fn materialize_operand(operand_id: i32, type_id: i32, span: i32) -> i32:
        let temp = self.new_temp(type_id)
        let place = self.place_for_local(temp)
        self.assign_operand_to_place(place, operand_id, span)
        self.register_stmt_temp(temp, type_id)
        place

    mut fn new_temp(type_id: i32) -> i32:
        self.next_temp = self.next_temp + 1
        self.body.new_temp(type_id)

    mut fn place_for_local(local_id: i32) -> i32:
        self.body.new_place(local_id)

    mut fn const_operand(kind: i32, d0: i32, type_id: i32) -> i32:
        let c = self.body.new_const(kind, d0, 0, 0, type_id)
        self.body.new_operand(OperandKind.OK_CONSTANT, c)

    mut fn int_const_operand(value: i64, type_id: i32) -> i32:
        let c = self.body.new_const(ConstKind.CK_INT, ast_int_part0(value), ast_int_part1(value), ast_int_part2(value), type_id)
        self.body.new_operand(OperandKind.OK_CONSTANT, c)

    mut fn exact_int_const_operand(node: i32, type_id: i32) -> i32:
        let c = self.body.new_const(ConstKind.CK_INT_EXACT, node, 0, 0, type_id)
        self.body.new_operand(OperandKind.OK_CONSTANT, c)

    mut fn unit_operand() -> i32:
        self.const_operand(ConstKind.CK_UNIT, 0, self.sema.ty_void)

    mut fn try_eval_const(node: i32) -> i64:
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

    fn try_resolve_module_const_node(sym: i32) -> i32:
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

    mut fn try_resolve_module_const_val(sym: i32) -> i64:
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

    fn try_resolve_module_float_const(sym: i32) -> i32:
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

    mut fn try_resolve_module_const_type(sym: i32) -> i32:
        let target_name = self.pool.resolve_symbol(sym)
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
                continue
            let decl_sym = self.ast.get_data0(decl)
            if decl_sym != sym and self.pool.resolve_symbol(decl_sym) != target_name:
                continue
            if self.sema.typed_binding_types.contains(decl as i32):
                return self.sema.typed_binding_types.get(decl as i32).unwrap() as i32
            let flags = self.ast.get_data2(decl)
            let type_extra_packed = flags / 16
            if type_extra_packed > 0:
                let type_ann_node = self.ast.get_extra(type_extra_packed - 1)
                let resolved = self.sema.resolve_type_expr_frozen(type_ann_node) as i32
                if resolved != 0:
                    return resolved
            var value_node = self.ast.get_data1(decl)
            if value_node != 0:
                if self.ast.kind(value_node) == NodeKind.NK_COMPTIME:
                    value_node = self.ast.get_data0(value_node)
                let value_ty = self.expr_type(value_node)
                if value_ty != 0 and value_ty != self.sema.ty_void as i32:
                    return value_ty
        0

    mut fn mark_unsupported():
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
                    let field_name: str = with_str_clone_ref(self.pool.resolve(field_sym))
                    let sema_field_sym = self.sema.pool_lookup_symbol(field_name)
                    let base_ty = self.expr_type(base)
                    let field_ty = self.expr_type(self.cur_node)
                    detail = detail ++ " field=" ++ field_name
                    detail = detail ++ f" base_kind={self.ast.kind(base)} base_ty={base_ty} field_ty={field_ty}"
                    detail = detail ++ f" typed={if self.sema.typed_expr_types.contains(self.cur_node): self.sema.typed_expr_types.get(self.cur_node).unwrap() else: 0}"
                    detail = detail ++ f" field_ast={self.struct_field_type(base_ty, field_sym)} field_sema={self.struct_field_type(base_ty, sema_field_sym)}"
            with_eprint(f"[mir-lower-fail] kind={node_kind} fn={fn_name}{detail}")
        self.body.lowering_failed = 1

    mut fn lower_int_lit(value: i64, type_id: i32) -> i32:
        let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TypeKind.TY_VOID: self.sema.ty_i32 else: type_id
        self.int_const_operand(value, ty)

    mut fn lower_int_lit_node(node: i32, type_id: i32) -> i32:
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

    mut fn lower_bool_lit(value: i32) -> i32:
        self.const_operand(ConstKind.CK_BOOL, value, self.sema.ty_bool)

    mut fn lower_str_lit(sym: i32) -> i32:
        self.const_operand(ConstKind.CK_STR, sym, self.sema.ty_str)

    mut fn lower_str_lit_as(sym: i32, type_id: i32) -> i32:
        let ty = if type_id != 0: type_id else: self.sema.ty_str as i32
        self.const_operand(ConstKind.CK_STR, sym, ty)

    mut fn lower_c_str_lit(sym: i32) -> i32:
        self.const_operand(ConstKind.CK_C_STR, sym, self.sema.ty_cstr_view)

    fn node_is_src_call(node: i32) -> i32:
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

impl MirBuilder:
    mut fn source_location_operand(node: i32) -> i32:
        let path = if self.sema.current_module_path.len() > 0: self.sema.current_module_path else: "<unknown>"
        let loc = self.sema.source_location_for_file_id(self.sema.local_file_id, self.ast.get_start(node))
        self.lower_str_lit(self.pool.intern(f"{path}:{loc.line + 1}:{loc.col + 1}"))

    mut fn source_file_operand(node: i32) -> i32:
        let _ = node
        let path = if self.sema.current_module_path.len() > 0: self.sema.current_module_path else: "<unknown>"
        self.lower_str_lit(self.pool.intern(path))

    mut fn source_line_operand(node: i32) -> i32:
        let loc = self.sema.source_location_for_file_id(self.sema.local_file_id, self.ast.get_start(node))
        self.int_const_operand((loc.line + 1) as i64, self.sema.ty_u32 as i32)

    mut fn source_fn_operand(node: i32) -> i32:
        let _ = node
        self.lower_str_lit(self.pool.intern(self.pool.resolve(self.body.fn_sym)))

    mut fn lower_magic_ident(kind: i32, node: i32) -> i32:
        if kind == SemaMagicIdentKind.FILE:
            return self.source_file_operand(node)
        if kind == SemaMagicIdentKind.LINE:
            return self.source_line_operand(node)
        if kind == SemaMagicIdentKind.FN:
            return self.source_fn_operand(node)
        self.unit_operand()

    fn magic_ident_kind(node: i32) -> i32:
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

    mut fn lower_default_call_arg(default_node: i32, call_node: i32, sig_idx: i32, callable_fn_tid: i32, param_idx: i32) -> i32:
        if self.node_is_src_call(default_node) != 0:
            return self.source_location_operand(call_node)
        let magic_kind = self.magic_ident_kind(default_node)
        if magic_kind != 0:
            return self.lower_magic_ident(magic_kind, call_node)
        self.lower_call_arg(default_node, sig_idx, callable_fn_tid, param_idx)

    mut fn lower_regex_literal(node: i32) -> i32:
        let regex_ty = self.sema.lookup_named_type_ambient(self.sema.syms.regex)
        let inferred_ty = self.expr_type(node)
        let result_ty = if inferred_ty != 0 and self.sema.type_is_unit(inferred_ty) == 0: inferred_ty else: regex_ty
        let c = self.body.new_const(ConstKind.CK_REGEX_LIT, self.ast.get_data0(node), self.ast.get_data1(node), node, result_ty)
        self.body.new_operand(OperandKind.OK_CONSTANT, c)

    fn regex_captures_type() -> i32:
        let sym = self.sema.pool_lookup_symbol("Captures")
        if sym != 0 and self.sema.named_types.contains(sym):
            return self.sema.named_types.get(sym).unwrap()
        self.sema.ty_void as i32

    fn regex_captures_option_type() -> i32:
        let cap_ty = self.regex_captures_type()
        let opt_sym = self.sema.pool_lookup_symbol("Option")
        if opt_sym == 0 or cap_ty == 0:
            return self.sema.ty_void as i32
        let found = self.sema.find_generic_inst(opt_sym, cap_ty)
        if found != 0:
            return found
        let args: Vec[i32] = Vec.new()
        args.push(cap_ty)
        self.sema.find_generic_inst_type(opt_sym, args, 1) as i32

    mut fn regex_ref_operand(regex_place: i32) -> i32:
        let regex_ty = self.sema.lookup_named_type_ambient(self.sema.syms.regex)
        let regex_ref_ty = self.sema.find_exact_type(TypeKind.TY_REF, regex_ty, 0, 0) as i32
        let regex_ref_tmp = self.new_temp(regex_ref_ty)
        let regex_ref_place = self.place_for_local(regex_ref_tmp)
        let regex_ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, regex_place, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, regex_ref_place, regex_ref_rv, self.ast.get_start(self.cur_node))
        self.body.new_operand(OperandKind.OK_COPY, regex_ref_place)

    mut fn captures_ref_operand(captures_place: i32) -> i32:
        let captures_ty = self.regex_captures_type()
        let captures_ref_ty = self.sema.find_exact_type(TypeKind.TY_REF, captures_ty, 0, 0) as i32
        let captures_ref_tmp = self.new_temp(captures_ref_ty)
        let captures_ref_place = self.place_for_local(captures_ref_tmp)
        let captures_ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, captures_place, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, captures_ref_place, captures_ref_rv, self.ast.get_start(self.cur_node))
        self.body.new_operand(OperandKind.OK_COPY, captures_ref_place)

    mut fn lower_regex_method_bool(regex_place: i32, text_place: i32, method_name: &str) -> i32:
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

    mut fn lower_regex_is_match_places(regex_place: i32, text_place: i32) -> i32:
        self.lower_regex_method_bool(regex_place, text_place, "is_match")

    mut fn lower_regex_captures_places(regex_place: i32, text_place: i32) -> i32:
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

    mut fn lower_option_is_some_place(opt_place: i32, opt_ty: i32) -> i32:
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

    mut fn lower_option_unwrap_place(opt_place: i32, opt_ty: i32, result_ty: i32) -> i32:
        let fn_op = self.const_operand(ConstKind.CK_FN, self.sema.pool_lookup_symbol("unwrap"), self.sema.ty_void)
        let args: Vec[i32] = Vec.new()
        let opt_op = self.body.new_operand(OperandKind.OK_MOVE, opt_place)
        self.consume_moved_operand(opt_op)
        args.push(opt_op)
        args.push(self.lower_str_lit(self.pool.intern("")))
        let args_id = self.body.new_call_args(args)
        self.body.set_call_intrinsic(args_id, MirIntrinsic.OPT_UNWRAP)
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        result_place

    // `=~` OBSERVES its subject (captures_match_op takes &str). A named
    // subject must be read in place: lowering it through lower_expr moved the
    // local into a temp, so after the first `/g` iteration the subject was
    // reset-on-move blanked and every later match saw "". One rule for every
    // =~ lowering site (expr, if-cond, while-cond); rvalue subjects still
    // materialize into a stmt temp.
    mut fn lower_regex_subject_place(lhs: i32) -> i32:
        let lhs_kind = self.ast.kind(lhs)
        if lhs_kind == NodeKind.NK_IDENT or lhs_kind == NodeKind.NK_FIELD_ACCESS:
            let p = self.lower_expr_place(lhs)
            if p >= 0:
                return p
        let text_op = self.lower_expr(lhs)
        let text_ty = self.expr_type(lhs)
        self.materialize_operand(text_op, text_ty, self.ast.get_start(lhs))

    mut fn lower_regex_match_expr(node: i32) -> i32:
        let lhs = self.ast.get_data0(node)
        let rhs = self.ast.get_data1(node)
        let text_place = self.lower_regex_subject_place(lhs)
        let regex_op = self.lower_expr(rhs)
        let regex_ty = self.expr_type(rhs)
        let regex_place = self.materialize_operand(regex_op, regex_ty, self.ast.get_start(rhs))
        let captures_opt_place = self.lower_regex_captures_places(regex_place, text_place)
        self.lower_option_is_some_place(captures_opt_place, self.regex_captures_option_type())

    mut fn lower_captures_text_call(captures_place: i32, index: i32, name_sym: i32) -> i32:
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

    mut fn bind_regex_capture_local(sym: i32, value_op: i32, span: i32):
        if sym == 0:
            return
        let local_id = self.body.new_local(self.sema.ty_str as i32, 0, sym, 1)
        self.bind_local(sym, local_id)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, span)
        self.schedule_drop(local_id, DropKind.DK_VALUE)
        let local_place = self.place_for_local(local_id)
        self.assign_operand_to_place(local_place, value_op, span)

    mut fn lower_regex_capture_bindings_from_captures(regex_node: i32, captures_place: i32):
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
            let sym: i32 = self.sema.regex_capture_name_syms.get((name_start + ni) as i64)
            if sym != 0:
                let value_op = self.lower_captures_text_call(captures_place, 0, sym)
                self.bind_regex_capture_local(sym, value_op, self.ast.get_start(regex_node))
            ni = ni + 1

    mut fn lower_regex_capture_bindings_from_option(regex_node: i32, captures_opt_place: i32):
        if regex_node == 0:
            return
        let captures_place = self.lower_option_unwrap_place(captures_opt_place, self.regex_captures_option_type(), self.regex_captures_type())
        self.lower_regex_capture_bindings_from_captures(regex_node, captures_place)

    fn remember_regex_pattern_captures(pat_node: i32, captures_opt_place: i32) -> Unit:
        for i in 0..self.regex_capture_pat_nodes.len() as i32:
            if self.regex_capture_pat_nodes.get(i as i64) == pat_node:
                self.regex_capture_opt_places.set_i32(i as i64, captures_opt_place)
                return
        self.regex_capture_pat_nodes.push(pat_node)
        self.regex_capture_opt_places.push(captures_opt_place)

    fn lookup_regex_pattern_captures(pat_node: i32) -> i32:
        for i in 0..self.regex_capture_pat_nodes.len() as i32:
            if self.regex_capture_pat_nodes.get(i as i64) == pat_node:
                return self.regex_capture_opt_places.get(i as i64)
        -1

    mut fn lower_fmt_to_str(operand: i32, node: i32) -> i32:
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
        // #771 residue: the formatted value is a fresh OWNED str with no later
        // owner — register it so the statement flush drops it (an interpolated
        // non-str leaked one block per f-string segment).
        self.register_stmt_temp(result_local, self.sema.ty_str)
        self.body.new_operand(OperandKind.OK_COPY, result_place)

    mut fn lower_fmt_debug_str(operand: i32, node: i32) -> i32:
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
        // #771 residue: the formatted value is a fresh OWNED str with no later
        // owner — register it so the statement flush drops it (an interpolated
        // non-str leaked one block per f-string segment).
        self.register_stmt_temp(result_local, self.sema.ty_str)
        self.body.new_operand(OperandKind.OK_COPY, result_place)

    mut fn lower_fmt_debug(operand: i32, sema_ty: i32, node: i32) -> i32:
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
        // #771 residue: the formatted value is a fresh OWNED str with no later
        // owner — register it so the statement flush drops it (an interpolated
        // non-str leaked one block per f-string segment).
        self.register_stmt_temp(result_local, self.sema.ty_str)
        self.body.new_operand(OperandKind.OK_COPY, result_place)

    mut fn lower_fmt_with_spec(operand: i32, flags: i32, width: i32, precision: i32, sema_ty: i32, node: i32) -> i32:
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
        // #771 residue: the formatted value is a fresh OWNED str with no later
        // owner — register it so the statement flush drops it (an interpolated
        // non-str leaked one block per f-string segment).
        self.register_stmt_temp(result_local, self.sema.ty_str)
        self.body.new_operand(OperandKind.OK_COPY, result_place)

    mut fn lower_fstring(node: i32) -> i32:
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
                var expr_op = self.lower_expr(expr_node)
                var resolved_ty = if self.expr_type(expr_node) > 0: self.sema.resolve_alias(self.expr_type(expr_node)) else: 0
                var borrowed_str_ref_op = -1
                // A view interpolant formats its POINTEE — formatting observes
                // (D22 transparency); reference bits must never reach the
                // formatter (#728: stage2's own MIR dump printed sym garbage).
                // Skip when lower_expr consumed a recorded adjustment: the
                // operand is already the owned pointee.
                if resolved_ty != 0 and self.sema.get_type_kind(resolved_ty) == TypeKind.TY_REF and self.has_contextual_copy_adjustment(expr_node) == 0:
                    let fmt_ref_ty = resolved_ty
                    let fmt_pointee = self.sema.get_type_d0(resolved_ty)
                    resolved_ty = self.sema.resolve_alias(fmt_pointee as TypeId)
                    if resolved_ty == self.sema.ty_str:
                        // Preserve the &str for the observing fast path. Format
                        // modes whose existing runtime helpers consume str clone
                        // it explicitly below before crossing that ABI.
                        borrowed_str_ref_op = expr_op
                    else:
                        let fmt_ref_place = self.materialize_operand(expr_op, fmt_ref_ty, self.ast.get_start(expr_node))
                        expr_op = self.body.new_operand(OperandKind.OK_COPY, self.new_deref_place(fmt_ref_place))

                var handled = false
                if spec_node != 0:
                    if borrowed_str_ref_op >= 0:
                        expr_op = self.lower_str_clone_ref(borrowed_str_ref_op, node)
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
                        if borrowed_str_ref_op >= 0:
                            self.lower_fstring_buf_write_str_ref(buf_op, borrowed_str_ref_op, node)
                        else:
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

    mut fn lower_fstring_buf_new(node: i32) -> i32:
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

    mut fn lower_fstring_buf_write_str(buf_op: i32, str_op: i32, node: i32):
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

    mut fn lower_fstring_buf_write_str_ref(buf_op: i32, str_ref_op: i32, node: i32):
        let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_buf_write_str_ref"), self.sema.ty_void)
        let call_args: Vec[i32] = Vec.new()
        call_args.push(buf_op)
        call_args.push(str_ref_op)
        let args_id = self.body.new_call_args(call_args)
        let result_local = self.new_temp(self.sema.ty_void)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.body.set_call_intrinsic(args_id, MirIntrinsic.FMT_BUF_WRITE_STR_REF)

    mut fn lower_str_clone_ref(str_ref_op: i32, node: i32) -> i32:
        let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("str_clone_ref"), self.sema.ty_str)
        let call_args: Vec[i32] = Vec.new()
        call_args.push(str_ref_op)
        let args_id = self.body.new_call_args(call_args)
        let result_local = self.new_temp(self.sema.ty_str)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.body.set_call_intrinsic(args_id, MirIntrinsic.STR_CLONE_REF)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_fstring_buf_write_fmt(buf_op: i32, val_op: i32, flags: i32, width: i32, precision: i32, sema_ty: i32, node: i32):
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

    mut fn lower_fstring_buf_finish(buf_op: i32, node: i32) -> i32:
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
        // The finished buffer is a new owned str. Keep it alive through the
        // enclosing expression, then either transfer it to its destination or
        // drop it at the statement boundary. Returning an unregistered copy
        // loses both ownership paths when an f-string is only observed by ++.
        self.register_stmt_temp(result_local, self.sema.ty_str)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_float_lit(sym: i32, type_id: i32) -> i32:
        let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TypeKind.TY_VOID: self.sema.ty_f64 else: type_id
        self.const_operand(ConstKind.CK_FLOAT, sym, ty)

    mut fn lower_unit() -> i32:
        self.unit_operand()

    fn is_bare_none(node: i32) -> bool:
        if node == 0 or self.ast.kind(node) != NodeKind.NK_IDENT:
            return false
        self.pool.resolve(self.ast.get_data0(node)) == "None"

    mut fn ensure_global_local(sym: i32) -> i32:
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
                var ev_ty = self.sema.resolve_type_expr_frozen(ev_type_node)
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
                let annotated = self.sema.resolve_type_expr_frozen(type_node) as i32
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

    mut fn lower_var(sym: i32, type_id: i32, node_id: i32) -> i32:
        let hinted_ty = if self.expected_type != 0: self.expected_type else: type_id
        if self.pool.resolve(sym) == "None" and hinted_ty != 0:
            let hinted_resolved = self.sema.resolve_alias(hinted_ty)
            let hinted_tk = self.sema.get_type_kind(hinted_resolved)
            if hinted_tk == TypeKind.TY_PTR or hinted_tk == TypeKind.TY_REF or hinted_tk == TypeKind.TY_EXTERN_FN:
                return self.const_operand(ConstKind.CK_INT, 0, self.sema.ty_i32)

        let local = self.lookup_local(sym)
        if local >= 0:
            let place = self.body.new_place(local)
            if self.sema.is_copy_frozen(type_id) != 0:
                if self.local_type_is_str(local) != 0:
                    self.mark_string_local_copied(local)
                else:
                    self.mark_string_base_fields_may_alias(local)
                return self.body.new_operand(OperandKind.OK_COPY, place)
            return self.body.new_operand(OperandKind.OK_MOVE, place)
        let alias_place = self.lookup_alias_place(sym)
        if alias_place >= 0:
            // #747 (03h): a view binding rooted in storage THIS frame owns and
            // will drop (consumed param / owned local with a scheduled value
            // drop) read in value position is an ownership TRANSFER, not a
            // share — a bare copy mints a second owner of the same buffers and
            // the base's scope-exit drop frees what the copy carried out
            // (comptime_eval_finish's drain of the evaluator double-freed
            // Sema's hashmap tables). Lower it as a field MOVE so consumers
            // run consume_moved_operand: static drop exclusion plus
            // reset-on-move (§2.5.1). Borrowed bases — mut-fn receiver place,
            // share/ref params — have no scheduled value drop here and keep
            // the pure view.
            let alias_path_count = self.place_field_projection_count(alias_place)
            if alias_path_count > 0:
                let alias_base = self.place_base_local(alias_place)
                let alias_ty = self.place_local_type(alias_place)
                if alias_base >= 0 and alias_ty > 0 and self.sema.type_needs_drop_frozen(alias_ty) != 0 and self.local_has_scheduled_value_drop(alias_base) != 0:
                    return self.body.new_operand(OperandKind.OK_MOVE, alias_place)
            if self.place_type_is_str(alias_place) != 0:
                self.mark_string_place_copied(alias_place)
            else:
                self.mark_string_base_fields_may_alias(self.place_base_local(alias_place))
            return self.body.new_operand(OperandKind.OK_COPY, alias_place)

        let fn_sym = self.sema_symbol_for_ast_symbol(sym)
        let sig_idx = self.call_sig_for_sym(fn_sym)
        if sig_idx >= 0:
            var resolved_fn_sym = fn_sym
            if self.sema.get_sig(resolved_fn_sym) < 0:
                let fn_name = self.pool.resolve_symbol(fn_sym)
                if fn_name.len() > 0:
                    let sema_fn_sym = self.sema.pool_lookup_symbol(fn_name)
                    if sema_fn_sym != 0 and self.sema.get_sig(sema_fn_sym) >= 0:
                        resolved_fn_sym = sema_fn_sym
            let fn_ty = if type_id != 0: type_id else: self.sema.sig_type_ids.get(sig_idx as i64)
            return self.const_operand(ConstKind.CK_FN, resolved_fn_sym, fn_ty)

        // Generic function reference (monomorphized at codegen time)
        if self.sema.generic_fn_node_for_symbol(fn_sym) != 0:
            return self.const_operand(ConstKind.CK_FN, fn_sym, type_id)

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
            let vl_decl_ty: i32 = if self.sema.variant_type_ids.contains(vl_sym): self.sema.variant_type_ids.get(vl_sym).unwrap() else: self.sema.variant_type_ids.get(sym).unwrap()
            // #671: same guard as the constructor-call path — an ambient
            // expectation that does not carry this variant must not retype it.
            var vl_result_ty = if self.expected_type != 0 and self.sema.enum_variant_discriminant_for_type(self.expected_type, vl_sym) >= 0: self.expected_type else: type_id
            if vl_result_ty == 0 or vl_result_ty == self.sema.ty_void as i32:
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

    fn places_are_identical(a: i32, b: i32) -> i32:
        if a == b:
            return 1
        if a < 0 or b < 0 or a >= self.body.place_locals.len() as i32 or b >= self.body.place_locals.len() as i32:
            return 0
        if self.body.place_locals.get(a as i64) != self.body.place_locals.get(b as i64):
            return 0
        let a_count = self.body.place_proj_counts.get(a as i64)
        let b_count = self.body.place_proj_counts.get(b as i64)
        if a_count != b_count:
            return 0
        let a_start = self.body.place_proj_starts.get(a as i64)
        let b_start = self.body.place_proj_starts.get(b as i64)
        for i in 0..a_count:
            if self.body.proj_kinds.get((a_start + i) as i64) != self.body.proj_kinds.get((b_start + i) as i64):
                return 0
            if self.body.proj_d0.get((a_start + i) as i64) != self.body.proj_d0.get((b_start + i) as i64):
                return 0
        1

    mut fn assign_operand_to_place(place: i32, operand_id: i32, span: i32):
        // An exact self-move transfers ownership out of and immediately back into
        // the same place. It is a semantic no-op: consuming the source would queue
        // a reset after the assignment and erase the restored owner (`x = move x`).
        if operand_id >= 0 and operand_id < self.body.operand_kinds.len() as i32:
            if self.body.operand_kinds.get(operand_id as i64) == OperandKind.OK_MOVE:
                if self.places_are_identical(place, self.body.operand_d0.get(operand_id as i64)) != 0:
                    return
        self.consume_moved_operand(operand_id)
        self.update_string_alias_after_assignment(place, operand_id)
        let rval = self.body.new_rvalue(RvalueKind.RK_USE, operand_id, 0, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rval, span)
        let dest_local = mir_place_plain_local(&self.body, place)
        if dest_local >= 0:
            self.clear_local_value_moved(dest_local)
            self.clear_moved_fields_for_local(dest_local)
        else:
            self.clear_moved_fields_for_place(place)

    fn direct_place_local(place: i32) -> i32:
        if place < 0 or place >= self.body.place_locals.len() as i32:
            return -1
        if self.body.place_proj_counts.get(place as i64) != 0:
            return -1
        self.body.place_locals.get(place as i64)

    fn local_type_is_str(local_id: i32) -> i32:
        if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
            return 0
        let tid = self.body.local_type_ids.get(local_id as i64)
        self.type_id_is_str(tid)

    fn place_type_is_str(place: i32) -> i32:
        if place < 0 or place >= self.body.place_locals.len() as i32:
            return 0
        if place < self.body.place_sema_types.len() as i32:
            let tid = self.body.place_sema_types.get(place as i64)
            if self.type_id_is_str(tid) != 0:
                return 1
        let local_id = self.body.place_locals.get(place as i64)
        self.local_type_is_str(local_id)

    // #780: whether a field-access value expr reads through a shared borrow
    // this frame does not own — any base link in the chain typed &T. Read
    // receivers whose `self` is typed as the value type are not caught here;
    // receiver field takes flow through D17's receiver-effect machinery.
    mut fn field_read_base_is_shared_borrow(node: i32) -> i32:
        var cur = node
        var guard = 0
        while guard < 64:
            guard = guard + 1
            let k = self.ast.kind(cur)
            if k == NodeKind.NK_GROUPED:
                cur = self.ast.get_data0(cur)
                continue
            if k != NodeKind.NK_FIELD_ACCESS:
                return 0
            let base = self.ast.get_data0(cur)
            let bty = self.expr_type(base)
            if bty != 0 and self.sema.get_type_kind(self.sema.resolve_alias(bty as TypeId)) == TypeKind.TY_REF:
                return 1
            cur = base
        0

    fn type_id_is_str(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.sema.resolve_alias(tid as TypeId)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_STR: 1 else: 0

    fn string_alias_index(local_id: i32) -> i32:
        for i in 0..self.string_alias_local_ids.len() as i32:
            if self.string_alias_local_ids.get(i as i64) == local_id:
                return i
        -1

    fn set_string_local_flags(local_id: i32, flags: i32):
        if self.local_type_is_str(local_id) == 0:
            return
        let idx = self.string_alias_index(local_id)
        if idx >= 0:
            self.string_alias_flags.set_i32(idx as i64, flags)
            return
        self.string_alias_local_ids.push(local_id)
        self.string_alias_flags.push(flags)

    fn string_local_flags(local_id: i32) -> i32:
        if self.local_type_is_str(local_id) == 0:
            return 1
        let idx = self.string_alias_index(local_id)
        if idx < 0:
            return 0
        self.string_alias_flags.get(idx as i64)

    fn set_string_local_may_alias(local_id: i32, flag: i32):
        let old = self.string_local_flags(local_id)
        let owned = old & 2
        self.set_string_local_flags(local_id, owned | (if flag != 0: 1 else: 0))

    fn string_local_may_alias(local_id: i32) -> i32:
        self.string_local_flags(local_id) & 1

    fn string_local_owned(local_id: i32) -> i32:
        if (self.string_local_flags(local_id) & 2) != 0: 1 else: 0

    fn mark_string_local_copied(local_id: i32):
        self.set_string_local_may_alias(local_id, 1)

    fn place_field_projection_count(place: i32) -> i32:
        if place < 0 or place >= self.body.place_locals.len() as i32:
            return -1
        let proj_start = self.body.place_proj_starts.get(place as i64)
        let proj_count = self.body.place_proj_counts.get(place as i64)
        if proj_count == 0:
            return 0
        for i in 0..proj_count:
            let kind = self.body.proj_kinds.get((proj_start + i) as i64)
            if kind != ProjKind.PK_FIELD and kind != ProjKind.PK_TUPLE_INDEX:
                return -1
        proj_count

    fn place_base_local(place: i32) -> i32:
        if place < 0 or place >= self.body.place_locals.len() as i32:
            return -1
        self.body.place_locals.get(place as i64)

    fn string_field_alias_path_matches(idx: i32, place: i32) -> i32:
        if idx < 0 or idx >= self.string_field_alias_base_locals.len() as i32:
            return 0
        let field_count = self.place_field_projection_count(place)
        if field_count <= 0:
            return 0
        let base_local = self.place_base_local(place)
        if self.string_field_alias_base_locals.get(idx as i64) != base_local:
            return 0
        let stored_count = self.string_field_alias_path_counts.get(idx as i64)
        if stored_count != field_count:
            return 0
        let stored_start = self.string_field_alias_path_starts.get(idx as i64)
        let proj_start = self.body.place_proj_starts.get(place as i64)
        for i in 0..field_count:
            let stored_kind = self.string_field_alias_path_kinds.get((stored_start + i) as i64)
            let place_kind = self.body.proj_kinds.get((proj_start + i) as i64)
            if stored_kind != place_kind:
                return 0
            let stored_field = self.string_field_alias_path_syms.get((stored_start + i) as i64)
            let place_field = self.body.proj_d0.get((proj_start + i) as i64)
            if stored_field != place_field:
                return 0
        1

    fn string_field_alias_index(place: i32) -> i32:
        if self.place_type_is_str(place) == 0:
            return -1
        if self.place_field_projection_count(place) <= 0:
            return -1
        for i in 0..self.string_field_alias_base_locals.len() as i32:
            if self.string_field_alias_path_matches(i, place) != 0:
                return i
        -1

    fn set_string_field_path_flags(base_local: i32, path_start: i32, path_count: i32, flags: i32):
        if base_local < 0 or path_count <= 0:
            return
        for i in 0..self.string_field_alias_base_locals.len() as i32:
            if self.string_field_alias_base_locals.get(i as i64) != base_local:
                continue
            let stored_count = self.string_field_alias_path_counts.get(i as i64)
            if stored_count != path_count:
                continue
            let stored_start = self.string_field_alias_path_starts.get(i as i64)
            var same = 1
            for pi in 0..path_count:
                if self.string_field_alias_path_kinds.get((stored_start + pi) as i64) != self.string_field_alias_path_kinds.get((path_start + pi) as i64):
                    same = 0
                    break
                if self.string_field_alias_path_syms.get((stored_start + pi) as i64) != self.string_field_alias_path_syms.get((path_start + pi) as i64):
                    same = 0
                    break
            if same != 0:
                self.string_field_alias_flags.set_i32(i as i64, flags)
                return
        self.string_field_alias_base_locals.push(base_local)
        self.string_field_alias_path_starts.push(path_start)
        self.string_field_alias_path_counts.push(path_count)
        self.string_field_alias_flags.push(flags)

    fn set_string_field_flags(place: i32, flags: i32):
        if self.place_type_is_str(place) == 0:
            return
        let field_count = self.place_field_projection_count(place)
        if field_count <= 0:
            return
        let idx = self.string_field_alias_index(place)
        if idx >= 0:
            self.string_field_alias_flags.set_i32(idx as i64, flags)
            return
        let path_start = self.string_field_alias_path_syms.len() as i32
        let proj_start: i32 = self.body.place_proj_starts.get(place as i64)
        for i in 0..field_count:
            self.string_field_alias_path_kinds.push(self.body.proj_kinds.get((proj_start + i) as i64))
            self.string_field_alias_path_syms.push(self.body.proj_d0.get((proj_start + i) as i64))
        self.string_field_alias_base_locals.push(self.place_base_local(place))
        self.string_field_alias_path_starts.push(path_start)
        self.string_field_alias_path_counts.push(field_count)
        self.string_field_alias_flags.push(flags)

    fn string_field_flags(place: i32) -> i32:
        if self.place_type_is_str(place) == 0:
            return 1
        if self.place_field_projection_count(place) <= 0:
            return 1
        let idx = self.string_field_alias_index(place)
        if idx < 0:
            return 1
        self.string_field_alias_flags.get(idx as i64)

    fn string_place_flags(place: i32) -> i32:
        let local = self.direct_place_local(place)
        if local >= 0:
            return self.string_local_flags(local)
        self.string_field_flags(place)

    fn set_string_place_flags(place: i32, flags: i32):
        let local = self.direct_place_local(place)
        if local >= 0:
            self.set_string_local_flags(local, flags)
            return
        self.set_string_field_flags(place, flags)

    fn set_string_place_may_alias(place: i32, flag: i32):
        let old = self.string_place_flags(place)
        let owned = old & 2
        self.set_string_place_flags(place, owned | (if flag != 0: 1 else: 0))

    fn string_place_may_alias(place: i32) -> i32:
        self.string_place_flags(place) & 1

    fn string_place_owned(place: i32) -> i32:
        if (self.string_place_flags(place) & 2) != 0: 1 else: 0

    fn mark_string_place_copied(place: i32):
        self.set_string_place_may_alias(place, 1)

    fn mark_string_base_fields_may_alias(base_local: i32):
        if base_local < 0:
            return
        for i in 0..self.string_field_alias_flags.len() as i32:
            if self.string_field_alias_base_locals.get(i as i64) == base_local:
                self.string_field_alias_flags.set_i32(i as i64, self.string_field_alias_flags.get(i as i64) | 1)

    fn forget_string_flow_facts():
        for i in 0..self.string_alias_flags.len() as i32:
            self.string_alias_flags.set_i32(i as i64, 1)
        for i in 0..self.string_field_alias_flags.len() as i32:
            self.string_field_alias_flags.set_i32(i as i64, 1)

    fn operand_string_source_place(operand_id: i32) -> i32:
        if operand_id < 0 or operand_id >= self.body.operand_kinds.len() as i32:
            return -1
        if self.body.operand_kinds.get(operand_id as i64) != OperandKind.OK_COPY:
            return -1
        let place = self.body.operand_d0.get(operand_id as i64)
        if self.place_type_is_str(place) == 0:
            return -1
        place

    fn operand_direct_place(operand_id: i32) -> i32:
        if operand_id < 0 or operand_id >= self.body.operand_kinds.len() as i32:
            return -1
        let kind = self.body.operand_kinds.get(operand_id as i64)
        if kind != OperandKind.OK_COPY and kind != OperandKind.OK_MOVE:
            return -1
        self.body.operand_d0.get(operand_id as i64)

    fn place_source_is_named(place: i32) -> i32:
        let base_local = self.place_base_local(place)
        if base_local < 0 or base_local >= self.body.local_names.len() as i32:
            return 0
        if self.body.local_names.get(base_local as i64) != 0: 1 else: 0

    // #747 (03g): an if-arm result operand that merely READS named storage —
    // a constant, or a copy/move of a PROJECTED place (a field/deref path
    // rooted in a named local/param) — yields a view, not a fresh owned
    // value (D27: a binding names what's there). Field reads of non-Copy
    // types lower as OK_MOVE even when sema models the binding as a view
    // (the base stays live and readable afterwards), so projected moves
    // count as views here. A bare named local is an ownership TRANSFER
    // (`let x = y` moves) and a copy/move of an anonymous temp is a fresh
    // value the statement owns — neither counts.
    fn operand_is_view_read(operand_id: i32) -> i32:
        if operand_id < 0 or operand_id >= self.body.operand_kinds.len() as i32:
            return 0
        let kind = self.body.operand_kinds.get(operand_id as i64)
        if kind == OperandKind.OK_CONSTANT:
            return 1
        if kind != OperandKind.OK_COPY and kind != OperandKind.OK_MOVE:
            return 0
        let place = self.body.operand_d0.get(operand_id as i64)
        if place < 0 or place >= self.body.place_proj_counts.len() as i32:
            return 0
        if self.body.place_proj_counts.get(place as i64) == 0:
            return 0
        self.place_source_is_named(place)

    fn transfer_string_field_facts_between_bases(source_base: i32, dest_base: i32, force_alias: i32):
        if source_base < 0 or dest_base < 0:
            return
        let original_count = self.string_field_alias_base_locals.len() as i32
        for i in 0..original_count:
            if self.string_field_alias_base_locals.get(i as i64) != source_base:
                continue
            let old_flags = self.string_field_alias_flags.get(i as i64)
            let flags = if force_alias != 0: (old_flags | 1) else: old_flags
            self.set_string_field_path_flags(dest_base, self.string_field_alias_path_starts.get(i as i64), self.string_field_alias_path_counts.get(i as i64), flags)

    fn update_string_aggregate_alias_after_assignment(dest_place: i32, operand_id: i32):
        let dest_base = self.direct_place_local(dest_place)
        if dest_base < 0:
            return
        self.mark_string_base_fields_may_alias(dest_base)
        let source_place = self.operand_direct_place(operand_id)
        if source_place < 0:
            return
        let source_base = self.direct_place_local(source_place)
        if source_base < 0:
            return
        let is_copy = if self.body.operand_kinds.get(operand_id as i64) == OperandKind.OK_COPY: 1 else: 0
        let source_named = if is_copy != 0: self.place_source_is_named(source_place) else: 0
        self.transfer_string_field_facts_between_bases(source_base, dest_base, source_named)
        if is_copy != 0:
            self.mark_string_base_fields_may_alias(source_base)

    fn update_string_alias_after_assignment(dest_place: i32, operand_id: i32):
        let dest_local = self.direct_place_local(dest_place)
        if dest_local >= 0:
            self.update_string_aggregate_alias_after_assignment(dest_place, operand_id)
        if self.place_type_is_str(dest_place) == 0:
            return
        let source_place = self.operand_string_source_place(operand_id)
        if source_place >= 0:
            let source_is_named = self.place_source_is_named(source_place)
            let source_may_alias = if source_is_named != 0: 1 else: self.string_place_may_alias(source_place)
            self.set_string_place_flags(dest_place, source_may_alias | (if self.string_place_owned(source_place) != 0: 2 else: 0))
            self.mark_string_place_copied(source_place)
            return
        self.set_string_place_flags(dest_place, 0)

    mut fn update_string_fields_after_aggregate(aggregate_place: i32, fields_id: i32):
        if aggregate_place < 0 or fields_id < 0 or fields_id >= self.body.agg_field_starts.len() as i32:
            return
        let start = self.body.agg_field_starts.get(fields_id as i64)
        let count = self.body.agg_field_counts.get(fields_id as i64)
        for i in 0..count:
            let field_sym: i32 = self.body.agg_field_name_syms.get((start + i) as i64)
            if field_sym == 0:
                continue
            let operand_id: i32 = self.body.agg_field_operands.get((start + i) as i64)
            var field_ty = 0
            let aggregate_ty = if aggregate_place < self.body.place_sema_types.len() as i32: self.body.place_sema_types.get(aggregate_place as i64) else: 0
            if aggregate_ty != 0:
                field_ty = self.struct_field_type(aggregate_ty, field_sym)
            let field_place = self.body.new_field_place(aggregate_place, field_sym, field_ty)
            self.update_string_alias_after_assignment(field_place, operand_id)

    mut fn is_string_concat_node(node: i32) -> bool:
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

    mut fn collect_left_string_concat_parts(node: i32) -> Vec[i32]:
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

fn mir_str_payload_is_raw_marked(text: &str) -> bool:
    text.len() >= 5 and text.byte_at(0) == 1 and text.byte_at(1) == 114 and text.byte_at(2) == 97 and text.byte_at(3) == 119 and text.byte_at(4) == 1

// Fold a ++ chain whose parts are all plain string literals into a single
// literal constant. Unmarked payloads are raw source text whose escapes
// codegen decodes, and escape sequences never span literal boundaries, so
// concatenating raw texts is exact. Chains mixing raw-marked (pre-decoded)
// and unmarked payloads are left to the runtime path. Returns -1 when the
// chain is not foldable.
impl MirBuilder:
    mut fn try_fold_literal_str_concat(node: i32, parts: &Vec[i32]) -> i32:
        for i in 0..parts.len() as i32:
            if self.ast.kind(parts.get(i as i64)) != NodeKind.NK_STRING_LIT:
                return -1
        var marked_count = 0
        for i in 0..parts.len() as i32:
            if mir_str_payload_is_raw_marked(self.pool.resolve(self.ast.get_data0(parts.get(i as i64)))):
                marked_count = marked_count + 1
        if marked_count != 0 and marked_count != parts.len() as i32:
            return -1
        var folded = ""
        for i in 0..parts.len() as i32:
            let payload = self.pool.resolve(self.ast.get_data0(parts.get(i as i64)))
            if marked_count != 0 and i > 0:
                folded = folded ++ payload.slice(5, payload.len())
            else:
                folded = folded ++ payload
        let folded_sym = self.pool.intern(folded)
        let folded_ty = self.expr_type(node)
        self.lower_str_lit_as(folded_sym, folded_ty)

    mut fn lower_str_concat_chain(node: i32, parts: &Vec[i32]) -> i32:
        let saved_expected = self.expected_type
        self.expected_type = self.sema.ty_str as i32
        let operands: Vec[i32] = Vec.new()
        for i in 0..parts.len() as i32:
            operands.push(self.lower_str_concat_part(parts.get(i as i64)))
        self.expected_type = saved_expected

        let args_id = self.body.new_call_args(operands)
        let rv = self.body.new_rvalue(RvalueKind.RK_STR_CONCAT_N, args_id, operands.len() as i32, 0)
        let ty = self.expr_type(node)
        let temp = self.new_temp(ty)
        let place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
        self.set_string_local_flags(temp, 2)
        if self.sema.is_copy_frozen(ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, place)
        self.body.new_operand(OperandKind.OK_MOVE, place)

    fn str_concat_part_is_explicit_move(node: i32) -> i32:
        if node == 0:
            return 0
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_MOVE_ARG:
            return 1
        if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_UNSAFE_BLOCK or kind == NodeKind.NK_NO_SUSPEND:
            return self.str_concat_part_is_explicit_move(self.ast.get_data0(node))
        0

    mut fn lower_str_concat_part(node: i32) -> i32:
        let lowered = self.lower_expr(node)
        if self.body.operand_kinds.get(lowered as i64) != OperandKind.OK_MOVE:
            return lowered
        let place: i32 = self.body.operand_d0.get(lowered as i64)
        if self.str_concat_part_is_explicit_move(node) == 0:
            // Ordinary ++ observes its operands. Named owners retain their
            // scope drops; an anonymous rvalue part has no later owner, so
            // the statement takes it (below) and drops it at the flush.
            if self.place_source_is_named(place) != 0:
                return self.body.new_operand(OperandKind.OK_COPY, place)

        // `move x ++ y` performs D16's explicit move, and an owned rvalue
        // part dies with the statement. Materialize the transferred value
        // as a statement temporary, borrow that temporary for concat, then
        // drop it at the pending-reset flush.
        let moved_ty = self.operand_type(lowered)
        let moved_tmp = self.new_temp(moved_ty)
        let moved_place = self.place_for_local(moved_tmp)
        let moved_rv = self.body.new_rvalue(RvalueKind.RK_USE, lowered, 0, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, moved_place, moved_rv, self.ast.get_start(node))
        self.consume_moved_operand(lowered)
        self.pending_move_temp_locals.push(moved_tmp)
        self.body.new_operand(OperandKind.OK_COPY, moved_place)

    fn same_ident_symbol(lhs: i32, rhs: i32) -> i32:
        if lhs == 0 or rhs == 0:
            return 0
        if self.ast.kind(lhs) != NodeKind.NK_IDENT or self.ast.kind(rhs) != NodeKind.NK_IDENT:
            return 0
        if self.ast.get_data0(lhs) == self.ast.get_data0(rhs): 1 else: 0

    fn unwrap_place_expr(node: i32) -> i32:
        var cur = node
        while cur != 0:
            let kind = self.ast.kind(cur)
            if kind != NodeKind.NK_GROUPED and kind != NodeKind.NK_NO_SUSPEND:
                break
            cur = self.ast.get_data0(cur)
        cur

    fn same_string_place_expr(lhs: i32, rhs: i32) -> i32:
        let l = self.unwrap_place_expr(lhs)
        let r = self.unwrap_place_expr(rhs)
        if l == 0 or r == 0:
            return 0
        let lk = self.ast.kind(l)
        let rk = self.ast.kind(r)
        if lk == NodeKind.NK_IDENT and rk == NodeKind.NK_IDENT:
            if self.ast.get_data0(l) == self.ast.get_data0(r): 1 else: 0
        else if lk == NodeKind.NK_FIELD_ACCESS and rk == NodeKind.NK_FIELD_ACCESS:
            if self.ast.get_data1(l) != self.ast.get_data1(r):
                return 0
            self.same_string_place_expr(self.ast.get_data0(l), self.ast.get_data0(r))
        else:
            0

    fn place_expr_root_symbol(node: i32) -> i32:
        let cur = self.unwrap_place_expr(node)
        if cur == 0:
            return 0
        let kind = self.ast.kind(cur)
        if kind == NodeKind.NK_IDENT:
            return self.ast.get_data0(cur)
        if kind == NodeKind.NK_FIELD_ACCESS:
            return self.place_expr_root_symbol(self.ast.get_data0(cur))
        0

    fn expr_mentions_symbol(node: i32, sym: i32) -> i32:
        if node == 0 or sym == 0:
            return 0
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_IDENT:
            if self.ast.get_data0(node) == sym: 1 else: 0
        else if kind == NodeKind.NK_LABEL:
            self.expr_mentions_symbol(self.ast.get_data1(node), sym)
        else if kind == NodeKind.NK_CLOSURE or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_ASYNC_SCOPE or kind == NodeKind.NK_SCOPE:
            0
        else if kind == NodeKind.NK_BLOCK:
            let stmt_start = self.ast.get_data0(node)
            let stmt_count = self.ast.get_data1(node)
            for si in 0..stmt_count:
                if self.expr_mentions_symbol(self.ast.get_extra(stmt_start + si), sym) != 0:
                    return 1
            self.expr_mentions_symbol(self.ast.get_data2(node), sym)
        else if kind == NodeKind.NK_IF_EXPR:
            if self.expr_mentions_symbol(self.ast.get_data0(node), sym) != 0: return 1
            if self.expr_mentions_symbol(self.ast.get_data1(node), sym) != 0: return 1
            self.expr_mentions_symbol(self.ast.get_data2(node), sym)
        else if kind == NodeKind.NK_WHILE or kind == NodeKind.NK_DO_WHILE:
            if self.expr_mentions_symbol(self.ast.get_data0(node), sym) != 0: return 1
            self.expr_mentions_symbol(self.ast.get_data1(node), sym)
        else if kind == NodeKind.NK_LOOP:
            self.expr_mentions_symbol(self.ast.get_data0(node), sym)
        else if kind == NodeKind.NK_FOR:
            if self.expr_mentions_symbol(self.ast.get_data1(node), sym) != 0: return 1
            self.expr_mentions_symbol(self.ast.get_data2(node), sym)
        else if kind == NodeKind.NK_MATCH:
            if self.expr_mentions_symbol(self.ast.get_data0(node), sym) != 0: return 1
            let arm_start = self.ast.get_data1(node)
            let arm_count = self.ast.get_data2(node)
            for ai in 0..arm_count:
                if self.expr_mentions_symbol(self.ast.get_extra(arm_start + ai), sym) != 0:
                    return 1
            0
        else if kind == NodeKind.NK_MATCH_ARM:
            if self.expr_mentions_symbol(self.ast.get_data2(node), sym) != 0: return 1
            self.expr_mentions_symbol(self.ast.get_data1(node), sym)
        else if kind == NodeKind.NK_RETURN or kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_YIELD or kind == NodeKind.NK_COMPTIME or kind == NodeKind.NK_UNSAFE_BLOCK or kind == NodeKind.NK_COPY_ARG or kind == NodeKind.NK_MOVE_ARG or kind == NodeKind.NK_NO_SUSPEND:
            self.expr_mentions_symbol(self.ast.get_data0(node), sym)
        else if kind == NodeKind.NK_BINARY:
            if self.expr_mentions_symbol(self.ast.get_data1(node), sym) != 0: return 1
            self.expr_mentions_symbol(self.ast.get_data2(node), sym)
        else if kind == NodeKind.NK_UNARY:
            self.expr_mentions_symbol(self.ast.get_data1(node), sym)
        else if kind == NodeKind.NK_LET_BINDING:
            self.expr_mentions_symbol(self.ast.get_data1(node), sym)
        else if kind == NodeKind.NK_LET_ELSE:
            if self.expr_mentions_symbol(self.ast.get_data1(node), sym) != 0: return 1
            self.expr_mentions_symbol(self.ast.get_data2(node), sym)
        else if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
            self.expr_mentions_symbol(self.ast.get_data2(node), sym)
        else if kind == NodeKind.NK_ASSIGN or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_INDEX or kind == NodeKind.NK_PIPELINE or kind == NodeKind.NK_RANGE:
            if self.expr_mentions_symbol(self.ast.get_data0(node), sym) != 0: return 1
            self.expr_mentions_symbol(self.ast.get_data1(node), sym)
        else if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_CAST:
            self.expr_mentions_symbol(self.ast.get_data0(node), sym)
        else if kind == NodeKind.NK_SLICE:
            if self.expr_mentions_symbol(self.ast.get_data0(node), sym) != 0: return 1
            if self.expr_mentions_symbol(self.ast.get_data1(node), sym) != 0: return 1
            self.expr_mentions_symbol(self.ast.get_data2(node), sym)
        else if kind == NodeKind.NK_CALL:
            if self.expr_mentions_symbol(self.ast.get_data0(node), sym) != 0: return 1
            let arg_start = self.ast.get_data1(node)
            let arg_count = self.ast.get_data2(node)
            for ai2 in 0..arg_count:
                if self.expr_mentions_symbol(self.ast.get_extra(arg_start + ai2), sym) != 0:
                    return 1
            0
        else if kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT:
            let elem_start = self.ast.get_data0(node)
            let elem_count = self.ast.get_data1(node)
            for ei in 0..elem_count:
                if self.expr_mentions_symbol(self.ast.get_extra(elem_start + ei), sym) != 0:
                    return 1
            0
        else if kind == NodeKind.NK_MAP_LIT:
            let pair_start = self.ast.get_data0(node)
            let pair_count = self.ast.get_data1(node)
            for mi in 0..pair_count:
                if self.expr_mentions_symbol(self.ast.get_extra(pair_start + mi * 2), sym) != 0:
                    return 1
                if self.expr_mentions_symbol(self.ast.get_extra(pair_start + mi * 2 + 1), sym) != 0:
                    return 1
            0
        else if kind == NodeKind.NK_ARRAY_COMPREHENSION:
            let comp_start = self.ast.get_data1(node)
            let clause_count = self.ast.get_data2(node)
            for ci in 0..clause_count:
                let base = comp_start + ci * 3
                if self.expr_mentions_symbol(self.ast.get_extra(base + 1), sym) != 0:
                    return 1
                if self.expr_mentions_symbol(self.ast.get_extra(base + 2), sym) != 0:
                    return 1
            self.expr_mentions_symbol(self.ast.get_data0(node), sym)
        else if kind == NodeKind.NK_MAP_COMPREHENSION:
            let comp_start = self.ast.get_data0(node)
            let clause_count = self.ast.get_data1(node)
            for ci in 0..clause_count:
                let base = comp_start + 2 + ci * 3
                if self.expr_mentions_symbol(self.ast.get_extra(base + 1), sym) != 0:
                    return 1
                if self.expr_mentions_symbol(self.ast.get_extra(base + 2), sym) != 0:
                    return 1
            if self.expr_mentions_symbol(self.ast.get_extra(comp_start), sym) != 0:
                return 1
            self.expr_mentions_symbol(self.ast.get_extra(comp_start + 1), sym)
        else if kind == NodeKind.NK_STRUCT_LIT:
            let field_start = self.ast.get_data1(node)
            let field_count = self.ast.get_data2(node)
            for fi in 0..field_count:
                if self.expr_mentions_symbol(self.ast.get_extra(field_start + fi * 2 + 1), sym) != 0:
                    return 1
            0
        else if kind == NodeKind.NK_RECORD_UPDATE:
            if self.expr_mentions_symbol(self.ast.get_data0(node), sym) != 0: return 1
            let field_start2 = self.ast.get_data1(node)
            let field_count2 = self.ast.get_data2(node)
            for fi2 in 0..field_count2:
                if self.expr_mentions_symbol(self.ast.get_extra(field_start2 + fi2 * 2 + 1), sym) != 0:
                    return 1
            0
        else if kind == NodeKind.NK_WITH_EXPR or kind == NodeKind.NK_WITH_IMPLICIT or kind == NodeKind.NK_WITH_TUPLE:
            if self.expr_mentions_symbol(self.ast.get_data0(node), sym) != 0: return 1
            self.expr_mentions_symbol(self.ast.get_data1(node), sym)
        else:
            0

    fn string_move_first_place_eligible(place: i32) -> i32:
        if self.place_type_is_str(place) == 0:
            return 0
        let direct = self.direct_place_local(place)
        if direct >= 0:
            return 1
        if self.place_field_projection_count(place) <= 0:
            return 0
        let base_local = self.place_base_local(place)
        if base_local <= 0 or base_local <= self.body.n_params:
            return 0
        if base_local < self.body.local_names.len() as i32 and self.body.local_names.get(base_local as i64) == 0:
            return 0
        1

    fn symbol_is_module_storage(sym: i32) -> i32:
        if sym == 0:
            return 0
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            let kind = self.ast.kind(decl)
            if kind == NodeKind.NK_LET_DECL or kind == NodeKind.NK_EXTERN_VAR:
                if self.ast.get_data0(decl) == sym:
                    return 1
        0

    mut fn try_lower_string_self_concat_assign(place_expr: i32, rhs_expr: i32) -> i32:
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
        if self.same_string_place_expr(place_expr, parts.get(0)) == 0:
            return -1

        let dest_place = self.lower_expr_place(place_expr)
        if self.string_move_first_place_eligible(dest_place) == 0 or self.string_place_may_alias(dest_place) != 0:
            return -1
        let root_sym = self.place_expr_root_symbol(place_expr)
        if self.symbol_is_module_storage(root_sym) != 0:
            return -1
        for i in 1..parts.len() as i32:
            if self.expr_mentions_symbol(parts.get(i as i64), root_sym) != 0:
                return -1

        let saved_expected = self.expected_type
        self.expected_type = self.sema.ty_str as i32
        let operands: Vec[i32] = Vec.new()
        operands.push(self.body.new_operand(OperandKind.OK_MOVE, dest_place))
        for i in 1..parts.len() as i32:
            operands.push(self.lower_str_concat_part(parts.get(i as i64)))
        self.expected_type = saved_expected

        let args_id = self.body.new_call_args(operands)
        let rv = self.body.new_rvalue(RvalueKind.RK_STR_CONCAT_N, args_id, operands.len() as i32, 1)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, dest_place, rv, self.ast.get_start(place_expr))
        self.set_string_place_flags(dest_place, 2)
        dest_place

    mut fn lower_bin_op(op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
        // Short-circuit evaluation for logical and/or
        if op == 11 or op == 12:
            return self.lower_short_circuit(op, lhs_expr, rhs_expr, node)
        if op == BinaryOp.OP_IN or op == BinaryOp.OP_NOT_IN:
            return self.lower_membership(op, lhs_expr, rhs_expr, node)
        if self.sema.operator_method_calls.contains(node):
            let method_sym: i32 = self.sema.operator_method_calls.get(node).unwrap()
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
            let folded = self.try_fold_literal_str_concat(node, parts)
            if folded >= 0:
                return folded
            // #747: every built-in str concat goes through RK_STR_CONCAT_N so
            // codegen retains the MIR operand modes. The old two-part
            // RK_BIN_OP path erased them and called the consuming
            // with_str_concat ABI even for `copy &str`; its callee drop freed
            // the borrowed owner's buffer. The concat-N path preserves its
            // borrow-only operand contract in MIR.
            if parts.len() as i32 >= 2:
                return self.lower_str_concat_chain(node, parts)
        let saved_expected = self.expected_type
        // #634: for a comparison, lower each operand with the OTHER operand's
        // type as the expected type. Otherwise the ambient expected type (bool
        // for `if a == b:`) flowed into an operand and an enum-variant
        // constructor operand (`r == Some(2)`) built its aggregate with the
        // comparison's type instead of its own — "aggregate rvalue missing
        // destination struct type". The bare-None-vs-pointer case keeps its
        // existing special handling. (#586 established the per-operand rebind.)
        let is_cmp = op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE
        if self.is_bare_none(lhs_expr) and (rhs_tk == TypeKind.TY_PTR or rhs_tk == TypeKind.TY_REF):
            self.expected_type = rhs_ty
        else if is_cmp and rhs_ty != 0:
            self.expected_type = rhs_ty
        else:
            self.expected_type = saved_expected
        let lhs = self.lower_expr(lhs_expr)
        if self.is_bare_none(rhs_expr) and (lhs_tk == TypeKind.TY_PTR or lhs_tk == TypeKind.TY_REF):
            self.expected_type = lhs_ty
        else if is_cmp and lhs_ty != 0:
            self.expected_type = lhs_ty
        else:
            self.expected_type = saved_expected
        let rhs = self.lower_expr(rhs_expr)
        self.expected_type = saved_expected
        let rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, op, lhs, rhs)
        var ty = self.expr_type(node)
        if ty == 0 or ty == self.sema.ty_void as i32:
            let lhs_op_ty = self.operand_type(lhs)
            let rhs_op_ty = self.operand_type(rhs)
            if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE or op == BinaryOp.OP_AND or op == BinaryOp.OP_OR:
                ty = self.sema.ty_bool as i32
            else if op == BinaryOp.OP_SHL or op == BinaryOp.OP_SHR:
                ty = lhs_op_ty
            else:
                let arith_ty = self.sema.arithmetic_result_type(lhs_op_ty as TypeId, rhs_op_ty as TypeId)
                if arith_ty != 0:
                    ty = arith_ty as i32
        let temp = self.new_temp(ty)
        let place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
        if op == BinaryOp.OP_CONCAT and self.type_id_is_str(ty) != 0:
            self.set_string_local_flags(temp, 2)
        if self.sema.is_copy_frozen(ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, place)
        self.body.new_operand(OperandKind.OK_MOVE, place)

    mut fn lower_rvalue_to_temp(rv: i32, type_id: i32, span: i32) -> i32:
        let temp = self.new_temp(type_id)
        let place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, span)
        self.body.new_operand(OperandKind.OK_COPY, place)

    mut fn lower_bin_op_operand(op: i32, lhs: i32, rhs: i32, type_id: i32, span: i32) -> i32:
        let rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, op, lhs, rhs)
        let temp = self.new_temp(type_id)
        let place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, span)
        if op == BinaryOp.OP_CONCAT and self.type_id_is_str(type_id) != 0:
            self.set_string_local_flags(temp, 2)
        self.body.new_operand(OperandKind.OK_COPY, place)

    mut fn lower_not_operand(operand: i32, span: i32) -> i32:
        let rv = self.body.new_rvalue(RvalueKind.RK_UN_OP, UnaryOp.UOP_NOT, operand, 0)
        self.lower_rvalue_to_temp(rv, self.sema.ty_bool as i32, span)

    mut fn lower_range_membership_from_parts(op: i32, lhs_place: i32, start_op: i32, end_op: i32, inclusive: i32, span: i32) -> i32:
        let lhs_for_start = self.body.new_operand(OperandKind.OK_COPY, lhs_place)
        let ge = self.lower_bin_op_operand(BinaryOp.OP_GTE, lhs_for_start, start_op, self.sema.ty_bool as i32, span)
        let lhs_for_end = self.body.new_operand(OperandKind.OK_COPY, lhs_place)
        let hi_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
        let le = self.lower_bin_op_operand(hi_op, lhs_for_end, end_op, self.sema.ty_bool as i32, span)
        let both = self.lower_bin_op_operand(BinaryOp.OP_AND, ge, le, self.sema.ty_bool as i32, span)
        if op == BinaryOp.OP_NOT_IN:
            return self.lower_not_operand(both, span)
        both

    mut fn lower_range_literal_membership(op: i32, lhs_expr: i32, range_expr: i32, node: i32) -> i32:
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

    mut fn lower_range_value_membership(op: i32, lhs_expr: i32, range_expr: i32, range_ty: i32, node: i32) -> i32:
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
    mut fn lower_array_literal_membership(op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
        let span = self.ast.get_start(node)
        let extra_start = self.ast.get_data0(rhs_expr)
        let elem_count = self.ast.get_data1(rhs_expr)
        var lhs_ty = self.expr_type(lhs_expr)
        if lhs_ty == 0 and elem_count > 0:
            lhs_ty = self.expr_type(self.ast.get_extra(extra_start))
        // #774: membership OBSERVES its subject — a named non-Copy lhs read
        // via lower_expr was moved into the temp and reset-blanked, so a
        // later `x == "..."` compared "" (same class as the =~ subject fix;
        // the helper reads named places in place, rvalues still materialize).
        let lhs_place = self.lower_regex_subject_place(lhs_expr)
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
    mut fn lower_array_value_membership(op: i32, lhs_expr: i32, rhs_expr: i32, array_ty: i32, node: i32) -> i32:
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
    mut fn lower_str_contains_char(op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
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

    mut fn lower_membership(op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
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

    mut fn lower_short_circuit(op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
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
        // #729-class (see lower_if): the RHS runs on only one path. A temp
        // created inside it that registers into the enclosing statement frame
        // would drop at the enclosing boundary — the join block — which the
        // short-circuit path also reaches, freeing an uninitialized slot
        // (#747: `guard != 0 and s != parser_active_arch()` freed stack
        // garbage on every guard==0 iteration). Frame the RHS and flush its
        // temps, its pending source-resets, and its move state on the RHS
        // path, before merging.
        let rhs_move_state = self.save_move_state()
        let pending_reset_start = self.pending_reset_locals.len() as i32
        let pending_reset_field_start = self.pending_reset_field_places.len() as i32
        let pending_move_temp_start = self.pending_move_temp_locals.len() as i32
        self.field_move_in_branch = self.field_move_in_branch + 1
        let rhs_temp_frame = self.push_stmt_temp_frame()
        let rhs = self.lower_expr(rhs_expr)
        let rhs_rv = self.body.new_rvalue(RvalueKind.RK_USE, rhs, 0, 0)
        let result_place2 = self.place_for_local(result)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, result_place2, rhs_rv, self.ast.get_start(node))
        self.finish_stmt_temp_frame(rhs_temp_frame)
        self.flush_pending_resets_since(pending_reset_start, pending_reset_field_start, pending_move_temp_start)
        self.field_move_in_branch = self.field_move_in_branch - 1
        self.terminate(TermKind.TK_GOTO, end_bb, 0, 0, 0)
        self.restore_move_state(&rhs_move_state)
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

impl MirBuilder:
    mut fn lower_method_bin_op(lhs_expr: i32, rhs_expr: i32, method_sym: i32, node: i32) -> i32:
        // Lower as: method_sym(lhs, rhs)
        let fn_op = self.lower_var(method_sym, 0, 0)
        let arg_nodes: Vec[i32] = Vec.new()
        arg_nodes.push(lhs_expr)
        arg_nodes.push(rhs_expr)
        let ret_ty = self.expr_type(node)
        self.lower_call_with_arg_nodes(fn_op, method_sym, arg_nodes, ret_ty, node)

    mut fn lower_method_un_op(expr: i32, method_sym: i32, node: i32) -> i32:
        let fn_op = self.lower_var(method_sym, 0, 0)
        let arg_nodes: Vec[i32] = Vec.new()
        arg_nodes.push(expr)
        let ret_ty = self.expr_type(node)
        self.lower_call_with_arg_nodes(fn_op, method_sym, arg_nodes, ret_ty, node)

    // TODO(D22): lower the Sema-proven transparent origin transfer for the
    // Continue payload. Compiler-generated Try temporaries do not end origins.
    mut fn lower_user_try_question_mark(expr: i32, node: i32) -> i32:
        let branch_fn: i32 = self.sema.try_branch_fns.get(node).unwrap()
        let from_break_fn: i32 = self.sema.try_from_break_fns.get(node).unwrap()
        let continue_ty: i32 = self.sema.try_continue_tys.get(node).unwrap()
        let break_ty: i32 = self.sema.try_break_tys.get(node).unwrap()
        let branch_ty: i32 = self.sema.try_branch_result_tys.get(node).unwrap()
        let branch_sig: i32 = self.sema.try_branch_sigs.get(node).unwrap()
        let branch_mono_sym: i32 = self.sema.try_branch_mono_syms.get(node).unwrap()
        let from_break_sig: i32 = self.sema.try_from_break_sigs.get(node).unwrap()
        let from_break_mono_sym: i32 = self.sema.try_from_break_mono_syms.get(node).unwrap()

        let branch_args: Vec[i32] = Vec.new()
        branch_args.push(self.lower_expr(expr))
        let branch_op = self.lower_resolved_call_with_operand_args_contract(branch_fn, branch_args, branch_ty, node, branch_sig, branch_mono_sym)
        let branch_place = self.materialize_operand(branch_op, branch_ty, self.ast.get_start(expr))

        let pass_bb = self.new_block()
        let fail_bb = self.new_block()
        let join_bb = self.new_block()

        let continue_sym = self.pool.intern("Continue")
        let break_sym = self.pool.intern("Break")
        let continue_idx = self.enum_variant_index_for_type(branch_ty, continue_sym)
        let break_idx = self.enum_variant_index_for_type(branch_ty, break_sym)
        if continue_idx < 0 or break_idx < 0:
            self.mark_unsupported()
            return self.unit_operand()

        let disc = self.lower_enum_discriminant(branch_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(continue_idx)
        let targets: Vec[i32] = Vec.new()
        targets.push(pass_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, disc, table, fail_bb, 0)

        self.switch_to(fail_bb)
        let ret_place = self.place_for_local(0)
        let ret_ty: i32 = self.body.local_type_ids.get(0)
        let break_downcast = self.body.new_downcast_place(branch_place, break_idx, branch_ty)
        let break_payload_place = self.body.new_field_place(break_downcast, 0, break_ty)
        let break_op = self.operand_for_place(break_payload_place, break_ty)
        let from_break_args: Vec[i32] = Vec.new()
        from_break_args.push(break_op)
        let ret_op = self.lower_resolved_call_with_operand_args_contract(from_break_fn, from_break_args, ret_ty, node, from_break_sig, from_break_mono_sym)
        self.assign_operand_to_place(ret_place, ret_op, self.ast.get_start(expr))
        self.emit_errdefers_for_return()
        self.emit_defers_for_return()
        self.emit_drops_for_return()
        self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

        self.switch_to(pass_bb)
        let result_local = self.new_temp(continue_ty)
        let result_place = self.place_for_local(result_local)
        let continue_downcast = self.body.new_downcast_place(branch_place, continue_idx, branch_ty)
        let payload_place = self.body.new_field_place(continue_downcast, 0, continue_ty)
        let pass_op = self.operand_for_place(payload_place, continue_ty)
        self.assign_operand_to_place(result_place, pass_op, self.ast.get_start(expr))
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        self.operand_for_place(result_place, continue_ty)

    fn is_runtime_pair_multi_index(node: i32) -> i32:
        if self.ast.kind(node) != NodeKind.NK_INDEX:
            return 0
        if self.ast.get_data2(node) == 0:
            return 0
        if self.sema.index_expr_is_type_level(self.ast.get_data0(node)) != 0:
            return 0
        1

    mut fn lower_multi_index_read(node: i32) -> i32:
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
        let mi_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, mi_unit, mi_args_id, mi_result_place, mi_next_bb)
        self.switch_to(mi_next_bb)
        mi_result_place

    mut fn lower_multi_index_set(place_expr: i32, rhs_expr: i32):
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
        let mi_unit = self.unit_operand()
        let ret_place = self.place_for_local(0)
        self.terminate(TermKind.TK_CALL, mi_unit, mi_args_id, ret_place, mi_next_bb)
        self.switch_to(mi_next_bb)

    mut fn lower_fn_address(expr: i32, type_id: i32) -> i32:
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
        if self.sema.get_sig(sym) >= 0 or self.sym_is_generic_fn(sym):
            return self.lower_var(sym, type_id, expr)
        -1

    mut fn lower_un_op(op: i32, expr: i32, node: i32) -> i32:
        if op == UnaryOp.UOP_NEGATE and self.sema.operator_method_calls.contains(node):
            return self.lower_method_un_op(expr, self.sema.operator_method_calls.get(node).unwrap(), node)

        if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT:
            let ref_ty = self.expr_type(node)
            let fn_addr = self.lower_fn_address(expr, ref_ty)
            if fn_addr >= 0:
                return fn_addr
            let place = self.lower_expr_place(expr)
            if self.place_type_is_str(place) != 0:
                self.mark_string_place_copied(place)
            else:
                self.mark_string_base_fields_may_alias(self.place_base_local(place))
            let is_exclusive = op == UnaryOp.UOP_RAW_REF_MUT
            let rv = self.body.new_rvalue(RvalueKind.RK_REF, if is_exclusive: BorrowKind.EXCLUSIVE else: BorrowKind.SHARED, place, 0)
            var ty = self.expr_type(node)
            // §10.6/§10.8: `&x` in ref-to-dyn position takes the dyn ref type
            // so codegen's RK_REF assign sees a dyn destination and builds the
            // fat pointer (mir_build_dyn_trait_value_from_ref_place keys on
            // the destination sema type) — e.g. `Some(&self.source)` for an
            // Option[&dyn Error] payload. Sema already vetted the coercion, so
            // the expected type governs even when the ref expr's own recorded
            // type is void/unknown (ref temps often are).
            if self.expected_type != 0 and self.expected_type != ty:
                let ref_exp_res = self.sema.resolve_alias(self.expected_type as TypeId)
                if self.sema.get_type_kind(ref_exp_res) == TypeKind.TY_REF:
                    if self.sema.get_type_kind(self.sema.resolve_alias(self.sema.get_type_d0(ref_exp_res) as TypeId)) == TypeKind.TY_TRAIT_OBJ:
                        ty = self.expected_type
            let temp = self.new_temp(ty)
            let temp_place = self.place_for_local(temp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(node))
            return self.body.new_operand(OperandKind.OK_COPY, temp_place)

        if op == UnaryOp.UOP_DEREF:
            let expr_ty = self.expr_type(expr)
            let resolved = self.sema.resolve_alias(expr_ty as TypeId)
            if self.sema.get_type_kind(resolved) == TypeKind.TY_REF:
                // Dereference the exact reference value. D27 index expressions
                // have a physical T place underneath their exact &T result;
                // lowering that place directly would dereference T itself when
                // T is a raw pointer (`*slots[0]`), selecting a different
                // operation than sema resolved under D22 §6.6.
                let ref_op = self.lower_expr(expr)
                let ref_place = self.materialize_operand(ref_op, expr_ty, self.ast.get_start(expr))
                return self.body.new_operand(OperandKind.OK_COPY, self.new_deref_place(ref_place))
            let place = self.lower_expr_place(expr)
            let deref_place = self.new_deref_place(place)
            return self.body.new_operand(OperandKind.OK_COPY, deref_place)

        let arg = self.lower_expr(expr)
        let rv = self.body.new_rvalue(RvalueKind.RK_UN_OP, op, arg, 0)
        let ty = self.expr_type(node)
        let temp = self.new_temp(ty)
        let place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
        self.body.new_operand(OperandKind.OK_COPY, place)

    mut fn lower_cast(expr: i32, target_type_id: i32, node: i32) -> i32:
        let op = self.lower_expr(expr)
        // D22 contextual materialization records the cast target on its source
        // expression. The central adjustment consumer has already copied the
        // pointee and performed this ordinary value cast, so do not cast the
        // exact reference a second time.
        if self.has_contextual_copy_adjustment(expr) != 0:
            let adjustment = self.contextual_copy_adjustment(expr)
            if adjustment.target_type == target_type_id:
                return op
        var src_sema_ty = self.operand_type(op)
        if src_sema_ty == 0 or src_sema_ty == self.sema.ty_void as i32:
            src_sema_ty = self.expr_type(expr)
        // A cast consumes its operand only for the transparent std Box value
        // reinterpret (`self as *mut T` in into_inner/drop): the box VALUE is
        // the payload pointer, the move is real, and without reset-on-move
        // the guarded scope-exit drop re-drops the payload (into_inner's
        // double-free). Every other non-Copy cast in the tree is an
        // address-taking cast of a share-place receiver (the comptime
        // evaluator's `self as *mut Sema` family) whose OK_MOVE operand is
        // classification noise: consuming those zeroes the caller's struct
        // through the alias — the stage2 self-host build lost its own
        // resolved-call contracts exactly that way (gates6 flip).
        if self.sema.type_is_std_box_inst(src_sema_ty) != 0:
            self.consume_moved_operand(op)
        let rv = self.body.new_rvalue(RvalueKind.RK_CAST, op, target_type_id, src_sema_ty)
        let temp = self.new_temp(target_type_id)
        let place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
        self.body.new_operand(OperandKind.OK_COPY, place)

    mut fn lower_field_access(node: i32) -> i32:
        let base_expr = self.ast.get_data0(node)
        let field_idx = self.ast.get_data1(node)
        let field_ty = self.expr_type(node)
        if field_ty == 0 or field_ty == self.sema.ty_void as i32:
            self.mark_unsupported()
            return self.place_for_local(0)
        let base = self.lower_field_base_place_for_field(base_expr, field_idx)
        self.new_projected_field_place(base, field_idx, field_ty)

    mut fn lower_user_deref_result_place(place: i32, current_ty: i32, deref_info: &SemaDerefInfo, node: i32) -> i32:
        let result_ref_ty = if deref_info.target_ty != 0: self.sema.find_exact_type(TypeKind.TY_REF, deref_info.target_ty, 0, 0) as i32 else: deref_info.result_ref_ty
        var recv_ref_ty = 0
        if self.sema.generic_fn_node_for_symbol(deref_info.deref_fn) == 0:
            let sig_idx = self.sema.get_sig(deref_info.deref_fn)
            if sig_idx >= 0 and self.sema.sig_get_param_count(sig_idx) > 0:
                recv_ref_ty = self.sema.sig_param_type(sig_idx, 0)
        if recv_ref_ty == 0:
            recv_ref_ty = self.sema.find_exact_type(TypeKind.TY_REF, current_ty, 0, 0) as i32
        let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, place, 0)
        let recv_tmp = self.new_temp(recv_ref_ty)
        let recv_place = self.place_for_local(recv_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, recv_place, rv, self.ast.get_start(node))
        let args: Vec[i32] = Vec.new()
        args.push(self.body.new_operand(OperandKind.OK_COPY, recv_place))
        // Sema records the concrete deref specialization on the base expr
        // (ensure_user_deref_specialization), so the dispatch keeps the full
        // contract requirement.
        let deref_op = self.lower_resolved_call_with_operand_args(deref_info.deref_fn, args, result_ref_ty, node)
        self.materialize_operand(deref_op, result_ref_ty, self.ast.get_start(node))

    mut fn lower_field_base_place_for_field(base_expr: i32, field: i32) -> i32:
        // The checker records the autoderef steps (with the deref fns it
        // resolved) per base expression; use them like lower_field_base_place
        // does. Re-walking with the frozen type-keyed resolver only recovers
        // the GENERIC Deref symbol, whose call then lacks a specialization
        // contract (behav_box_drop: field access through Box[T] hit the
        // generic-contract validator).
        if self.sema.autoderef_step_counts.contains(base_expr):
            var rec_place = self.lower_recorded_autoderef_place(base_expr)
            // The recorded steps stop where sema's transparent-Box special
            // case typed the payload field directly (it records no step for
            // the Box unwrap). A PROJECTED place left Box-typed has no
            // field-on-box codegen path — spec_ss03_7's `&&Box[T]` field
            // access reached codegen as `_x.*.*.f` on the Box and collapsed
            // to `i32 undef`. Mirror the unrecorded walk's payload
            // projection below: land on the payload, not the Box.
            let rec_start: i32 = self.sema.autoderef_step_starts.get(base_expr).unwrap()
            let rec_count: i32 = self.sema.autoderef_step_counts.get(base_expr).unwrap()
            var rec_ty = self.expr_type(base_expr)
            if rec_count > 0:
                rec_ty = self.sema.autoderef_step_tys.get((rec_start + rec_count - 1) as i64)
            var rec_depth = 0
            while rec_ty > 0 and rec_depth < 8:
                let rec_resolved = self.sema.resolve_alias(rec_ty as TypeId)
                if self.sema.get_type_kind(rec_resolved) != TypeKind.TY_GENERIC_INST:
                    break
                if self.sema.type_symbol_is_std_box(self.sema.get_type_d0(rec_resolved)) == 0 or self.sema.get_generic_inst_arg_count(rec_resolved as i32) != 1:
                    break
                let rec_payload = self.sema.get_generic_inst_arg(rec_resolved as i32, 0)
                if self.sema.autoderef_type_has_field_frozen(self.sema.resolve_alias(rec_payload as TypeId), field) == 0:
                    break
                rec_place = self.body.new_deref_place(rec_place, rec_payload)
                rec_ty = rec_payload
                rec_depth = rec_depth + 1
            return rec_place
        var place = self.lower_expr_place(base_expr)
        var current_ty = self.expr_type(base_expr)
        let place_ty = self.place_local_type(place)
        if place_ty != 0 and place_ty != self.sema.ty_void as i32:
            current_ty = place_ty
        var depth = 0
        while current_ty > 0 and depth < 32:
            let current = self.sema.resolve_alias(current_ty as TypeId)
            if with_getenv_str("WITH_DEBUG_BOXWALK").len() > 0:
                let bw_d0 = self.sema.get_type_d0(current)
                with_eprint(f"[boxwalk] depth={depth} current={current as i32} tk={self.sema.get_type_kind(current)} has_field={self.sema.autoderef_type_has_field_frozen(current, field)} d0={bw_d0} is_box={self.sema.type_symbol_is_std_box(bw_d0)} argc={self.sema.get_generic_inst_arg_count(current as i32)}")
            if self.sema.autoderef_type_has_field_frozen(current, field) != 0:
                return place
            let tk = self.sema.get_type_kind(current)
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                place = self.new_deref_place(place)
                current_ty = self.sema.get_type_d0(current)
                depth = depth + 1
                continue
            // Transparent std Box: sema types payload fields directly (its
            // special case records no autoderef steps), so mirror it here —
            // the box place IS the payload pointer and payload access is a
            // deref projection. Emitting Box's generic Deref.deref instead
            // produces a call with no specialization contract (behav_box_drop
            // hit the generic-contract validator through exactly this walk).
            if tk == TypeKind.TY_GENERIC_INST and self.sema.type_symbol_is_std_box(self.sema.get_type_d0(current)) != 0 and self.sema.get_generic_inst_arg_count(current as i32) == 1:
                // The box's sema type is not a pointer, so the untyped deref
                // helper cannot derive the pointee; record the payload type
                // explicitly or downstream field typing collapses to undef.
                let box_payload_ty = self.sema.get_generic_inst_arg(current as i32, 0)
                place = self.body.new_deref_place(place, box_payload_ty)
                current_ty = box_payload_ty
                depth = depth + 1
                continue
            let deref_info = self.sema.resolve_user_deref_info_frozen(current as i32)
            if deref_info.ok == 0:
                return place
            let result_ref_ty = deref_info.result_ref_ty
            place = self.lower_user_deref_result_place(place, current as i32, deref_info, base_expr)
            current_ty = result_ref_ty
            depth = depth + 1
        place

    mut fn lower_field_base_place(base_expr: i32) -> i32:
        if self.sema.autoderef_step_counts.contains(base_expr):
            return self.lower_recorded_autoderef_place(base_expr)
        var base = self.lower_expr_place(base_expr)
        var base_ty = self.expr_type(base_expr)
        let physical_ty = self.place_local_type(base)
        if physical_ty != 0 and physical_ty != self.sema.ty_void as i32:
            base_ty = physical_ty
        while base_ty > 0:
            let resolved = self.sema.resolve_alias(base_ty)
            let tk = self.sema.get_type_kind(resolved)
            if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
                break
            base = self.new_deref_place(base)
            base_ty = self.sema.get_type_d0(resolved)
        base

    mut fn lower_recorded_autoderef_place(expr: i32) -> i32:
        var place = self.lower_expr_place(expr)
        var current_ty = self.expr_type(expr)
        if not self.sema.autoderef_step_counts.contains(expr):
            return place
        let start: i32 = self.sema.autoderef_step_starts.get(expr).unwrap()
        let count: i32 = self.sema.autoderef_step_counts.get(expr).unwrap()
        var first_step = 0
        // A D27 index has semantic type &T but lower_expr_place already lands
        // directly on its physical T slot. Sema's first builtin ref-deref step
        // is therefore already represented by the place; replaying it would
        // generate `_xs[_i].*` and dereference the element value as a pointer.
        let physical_ty = self.place_local_type(place)
        if count > 0 and physical_ty != 0 and physical_ty != self.sema.ty_void as i32:
            let step_fn0 = self.sema.autoderef_step_fns.get(start as i64)
            let step_ty0 = self.sema.autoderef_step_tys.get(start as i64)
            if step_fn0 == 0 and self.sema.resolve_alias(physical_ty as TypeId) == self.sema.resolve_alias(step_ty0 as TypeId):
                current_ty = step_ty0
                first_step = 1
        for i in first_step..count:
            let step_fn = self.sema.autoderef_step_fns.get((start + i) as i64)
            let step_ty: i32 = self.sema.autoderef_step_tys.get((start + i) as i64)
            if step_fn == 0:
                place = self.new_deref_place(place)
            else:
                place = self.lower_user_deref_result_place(place, current_ty, SemaDerefInfo { ok: 1, target_ty: 0, result_ref_ty: step_ty, deref_fn: step_fn }, expr)
            current_ty = step_ty
        place

    mut fn lower_index(base_expr: i32, index_expr: i32) -> i32:
        var base = self.lower_expr_place(base_expr)
        // Indexing through `&Vec[T]` / `&mut Vec[T]` should index the container,
        // not treat the reference itself like a raw pointer. A D27 index has
        // semantic type &T while its place already denotes the physical T
        // slot, so prefer the place type before deciding whether a dereference
        // is still required. Otherwise nested array indexing grows bogus
        // `_a[_i].*[_j]` projections and codegen loses the LLVM element type.
        var base_ty = self.expr_type(base_expr)
        let physical_ty = self.place_local_type(base)
        if physical_ty != 0 and physical_ty != self.sema.ty_void as i32:
            base_ty = physical_ty
        while base_ty > 0:
            let resolved = self.sema.resolve_alias(base_ty)
            if self.sema.get_type_kind(resolved) != TypeKind.TY_REF:
                break
            base = self.new_deref_place(base)
            base_ty = self.sema.get_type_d0(resolved)
        let elem_ty = self.indexed_element_type(base_ty)
        let idx_op = self.lower_expr(index_expr)
        let idx_ty = if self.has_contextual_copy_adjustment(index_expr) != 0:
            self.contextual_copy_adjustment(index_expr).target_type
        else:
            self.expr_type(index_expr)
        let idx_local = self.new_temp(idx_ty)
        let idx_place = self.place_for_local(idx_local)
        self.assign_operand_to_place(idx_place, idx_op, self.ast.get_start(index_expr))
        self.body.new_index_place(base, idx_local, elem_ty)

    mut fn lower_call_place(node: i32) -> i32:
        // D27 E2: `xs.get(i)` is no longer a place-former — it observes,
        // returning &T through VEC_GET_REF, and the ref-deref walk in field
        // lowering handles projections off the result. The element-place
        // treatment below was the issue-64 aliasing accident: with the get
        // node now ref-typed, it double-dereferenced (`_v[_i].*.field`).
        // `[i]` remains the place spelling.
        let _ = node
        -1

    mut fn lower_binding_alias_place(node: i32) -> i32:
        if node == 0:
            return -1
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_GROUPED:
            return self.lower_binding_alias_place(self.ast.get_data0(node))
        if kind == NodeKind.NK_CALL:
            return self.lower_call_place(node)
        if kind == NodeKind.NK_FIELD_ACCESS:
            let base_expr = self.ast.get_data0(node)
            let field_sym = self.ast.get_data1(node)
            // A field projected through a recorded ref/user-Deref view already
            // has an authoritative place walk. Consult it before recursively
            // asking whether the syntactic base is itself an alias place:
            // `(&owner).field` bottoms out at UOP_REF, but the field is still a
            // pure alias and must never acquire an owning drop local.
            if self.sema.autoderef_step_counts.contains(base_expr):
                let autoderef_place = self.lower_recorded_autoderef_place(base_expr)
                let field_ty = self.expr_type(node)
                return self.new_projected_field_place(autoderef_place, field_sym, field_ty)
            var base_place = self.lower_binding_alias_place(base_expr)
            // #747: a field of a NAMED local (the method receiver included) is
            // a pure place projection — "a binding names what's there" (D27).
            // While str was Copy this case byte-copied; under owned str the
            // fallback became a FIELD MOVE that reset the base's field and
            // freed the value at scope exit — stage2's lexer read a blanked
            // self.source and lexed instant EOF for every file. The checker
            // already models these bindings as views (the census annotated
            // every site that mutates the base while one lives), so lowering
            // must alias, not move.
            if base_place < 0 and self.ast.kind(base_expr) == NodeKind.NK_IDENT:
                let base_sym = self.ast.get_data0(base_expr)
                let base_local = self.lookup_local(base_sym)
                if base_local >= 0:
                    base_place = self.place_for_local(base_local)
                else:
                    base_place = self.lookup_alias_place(base_sym)
            if base_place < 0:
                return -1
            var field_base = base_place
            var base_ty = self.expr_type(base_expr)
            while base_ty > 0:
                let resolved = self.sema.resolve_alias(base_ty)
                let tk = self.sema.get_type_kind(resolved)
                if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
                    break
                field_base = self.new_deref_place(field_base)
                base_ty = self.sema.get_type_d0(resolved)
            let field_ty = self.expr_type(node)
            return self.new_projected_field_place(field_base, field_sym, field_ty)
        -1

    mut fn lower_vec_literal_push(vec_place: i32, elem_node: i32, elem_ty: i32):
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

    mut fn lower_vec_literal(node: i32, vec_ty: i32) -> i32:
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
        if self.sema.is_copy_frozen(vec_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, vec_place)
        self.body.new_operand(OperandKind.OK_MOVE, vec_place)

    fn literal_target_base_sym(ty: i32) -> i32:
        if ty == 0:
            return 0
        let resolved = self.sema.resolve_alias(ty)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        self.sema.get_generic_inst_base(resolved as i32)

    fn is_btreeset_base_sym(sym: i32) -> i32:
        if sym == self.sema.syms.btreeset:
            return 1
        let name = self.sema.pool_resolve(sym)
        if name == "BTreeSet" or name.starts_with("BTreeSet"):
            return 1
        0

    fn is_btreemap_base_sym(sym: i32) -> i32:
        if sym == self.sema.syms.btreemap:
            return 1
        let name = self.sema.pool_resolve(sym)
        if name == "BTreeMap" or name.starts_with("BTreeMap"):
            return 1
        0

    mut fn btree_storage_vec_type(target_ty: i32) -> i32:
        let resolved = self.sema.resolve_alias(target_ty)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        let base = self.sema.get_generic_inst_base(resolved as i32)
        if self.is_btreeset_base_sym(base) != 0:
            let values_ty = self.struct_field_type(target_ty, self.pool.intern("values"))
            if values_ty != 0:
                return values_ty
            if self.sema.get_generic_inst_arg_count(resolved as i32) <= 0:
                return 0
            return self.sema.find_vec_type_for(self.sema.get_generic_inst_arg(resolved as i32, 0))
        if self.is_btreemap_base_sym(base) != 0:
            let entries_ty = self.struct_field_type(target_ty, self.pool.intern("entries"))
            if entries_ty != 0:
                return entries_ty
            if self.sema.get_generic_inst_arg_count(resolved as i32) < 2:
                return 0
            let elems: Vec[i32] = Vec.new()
            elems.push(self.sema.get_generic_inst_arg(resolved as i32, 0))
            elems.push(self.sema.get_generic_inst_arg(resolved as i32, 1))
            let pair_ty = self.sema.find_tuple_type(elems, 2) as i32
            return self.sema.find_vec_type_for(pair_ty)
        0

    mut fn emit_btree_new_into(out_place: i32, target_ty: i32, span: i32):
        let storage_ty = self.btree_storage_vec_type(target_ty)
        if storage_ty == 0:
            self.mark_unsupported()
            return
        let storage_local = self.new_temp(storage_ty)
        let storage_place = self.place_for_local(storage_local)
        self.emit_vec_new_into(storage_place, span)
        let storage_op = self.body.new_operand(OperandKind.OK_MOVE, storage_place)
        let fields: Vec[i32] = Vec.new()
        let names: Vec[i32] = Vec.new()
        fields.push(storage_op)
        names.push(0)
        let fid = self.body.new_agg_fields(fields, names)
        let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, fid, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, out_place, rv, span)

    mut fn emit_btree_set_insert(set_place: i32, elem_op: i32, node: i32):
        let insert_sym = self.sema.pool_lookup_symbol("insert")
        let fn_sym = if insert_sym != 0: self.sema.lookup_generic_method_fn(self.sema.syms.btreeset, insert_sym) else: 0
        if fn_sym == 0:
            self.mark_unsupported()
            return
        let args: Vec[i32] = Vec.new()
        args.push(self.body.new_operand(OperandKind.OK_COPY, set_place))
        args.push(elem_op)
        let sig_idx: i32 = self.sema.btree_insert_sigs.get(node).unwrap()
        let mono_sym: i32 = self.sema.btree_insert_mono_syms.get(node).unwrap()
        let _ = self.lower_resolved_call_with_operand_args_contract(fn_sym, args, self.sema.ty_void as i32, node, sig_idx, mono_sym)

    mut fn emit_btree_map_insert(map_place: i32, key_op: i32, val_op: i32, node: i32):
        let insert_sym = self.sema.pool_lookup_symbol("insert")
        let fn_sym = if insert_sym != 0: self.sema.lookup_generic_method_fn(self.sema.syms.btreemap, insert_sym) else: 0
        if fn_sym == 0:
            self.mark_unsupported()
            return
        let args: Vec[i32] = Vec.new()
        args.push(self.body.new_operand(OperandKind.OK_COPY, map_place))
        args.push(key_op)
        args.push(val_op)
        let sig_idx: i32 = self.sema.btree_insert_sigs.get(node).unwrap()
        let mono_sym: i32 = self.sema.btree_insert_mono_syms.get(node).unwrap()
        let _ = self.lower_resolved_call_with_operand_args_contract(fn_sym, args, self.sema.ty_void as i32, node, sig_idx, mono_sym)

    mut fn lower_btree_seq_literal(node: i32, elem_ty: i32) -> i32:
        let elem_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        let target_ty = self.expr_type(node)
        if self.btree_storage_vec_type(target_ty) == 0:
            self.mark_unsupported()
            return self.unit_operand()
        let out_local = self.new_temp(target_ty)
        let out_place = self.place_for_local(out_local)
        self.emit_btree_new_into(out_place, target_ty, self.ast.get_start(node))
        let saved_expected = self.expected_type
        for i in 0..elem_count:
            let elem_node = self.ast.get_extra(elem_start + i)
            if elem_ty != 0:
                self.expected_type = elem_ty
            let elem_op = self.lower_expr(elem_node)
            self.expected_type = saved_expected
            self.emit_btree_set_insert(out_place, elem_op, elem_node)
        if self.sema.is_copy_frozen(target_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, out_place)
        self.body.new_operand(OperandKind.OK_MOVE, out_place)

    mut fn lower_btree_map_literal(node: i32, key_ty: i32, val_ty: i32) -> i32:
        let pair_start = self.ast.get_data0(node)
        let pair_count = self.ast.get_data1(node)
        let target_ty = self.expr_type(node)
        if self.btree_storage_vec_type(target_ty) == 0:
            self.mark_unsupported()
            return self.unit_operand()
        let out_local = self.new_temp(target_ty)
        let out_place = self.place_for_local(out_local)
        self.emit_btree_new_into(out_place, target_ty, self.ast.get_start(node))
        let saved_expected = self.expected_type
        for i in 0..pair_count:
            let key_node = self.ast.get_extra(pair_start + i * 2)
            let val_node = self.ast.get_extra(pair_start + i * 2 + 1)
            if key_ty != 0:
                self.expected_type = key_ty
            let key_op = self.lower_expr(key_node)
            if val_ty != 0:
                self.expected_type = val_ty
            else:
                self.expected_type = saved_expected
            let val_op = self.lower_expr(val_node)
            self.expected_type = saved_expected
            self.emit_btree_map_insert(out_place, key_op, val_op, key_node)
        if self.sema.is_copy_frozen(target_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, out_place)
        self.body.new_operand(OperandKind.OK_MOVE, out_place)

    mut fn lower_btree_new(node: i32, fallback_ty: i32) -> i32:
        var target_ty = self.expr_type(node)
        var storage_ty = self.btree_storage_vec_type(target_ty)
        if storage_ty == 0 and self.expected_type > 0:
            let expected_storage_ty = self.btree_storage_vec_type(self.expected_type)
            if expected_storage_ty != 0:
                target_ty = self.expected_type
                storage_ty = expected_storage_ty
        if storage_ty == 0 and fallback_ty > 0:
            let fallback_storage_ty = self.btree_storage_vec_type(fallback_ty)
            if fallback_storage_ty != 0:
                target_ty = fallback_ty
                storage_ty = fallback_storage_ty
        if storage_ty == 0:
            self.mark_unsupported()
            return self.unit_operand()
        let out_local = self.new_temp(target_ty)
        let out_place = self.place_for_local(out_local)
        self.emit_btree_new_into(out_place, target_ty, self.ast.get_start(node))
        if self.sema.is_copy_frozen(target_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, out_place)
        self.body.new_operand(OperandKind.OK_MOVE, out_place)

    mut fn lower_collection_literal_call(node: i32, intrinsic: MirIntrinsic, operands: &Vec[i32]) -> i32:
        let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("__collection_literal"), self.sema.ty_void)
        let args_id = self.body.new_call_args(operands)
        let ret_type = self.expr_type(node)
        let result_local = self.new_temp(ret_type)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.body.set_call_intrinsic(args_id, intrinsic)
        self.body.set_call_ast_node(args_id, node)
        self.switch_to(next_bb)
        if self.sema.is_copy_frozen(ret_type) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_collection_seq_literal(node: i32) -> i32:
        let elem_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        let target_ty = self.expr_type(node)
        let target_base = self.literal_target_base_sym(target_ty)
        if target_base != self.sema.syms.vec and target_base != self.sema.syms.hashset and self.is_btreeset_base_sym(target_base) == 0:
            return -1
        var elem_ty = 0
        let resolved = self.sema.resolve_alias(target_ty)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST and self.sema.get_generic_inst_arg_count(resolved as i32) > 0:
            elem_ty = self.sema.get_generic_inst_arg(resolved as i32, 0)
        if self.is_btreeset_base_sym(target_base) != 0:
            return self.lower_btree_seq_literal(node, elem_ty)
        let saved_expected = self.expected_type
        let args: Vec[i32] = Vec.new()
        for i in 0..elem_count:
            let elem_node = self.ast.get_extra(elem_start + i)
            if elem_ty != 0:
                self.expected_type = elem_ty
            args.push(self.lower_expr(elem_node))
            self.expected_type = saved_expected
        self.lower_collection_literal_call(node, MirIntrinsic.COLLECTION_LITERAL, &args)

    mut fn lower_map_literal(node: i32) -> i32:
        let pair_start = self.ast.get_data0(node)
        let pair_count = self.ast.get_data1(node)
        let target_ty = self.expr_type(node)
        let resolved = self.sema.resolve_alias(target_ty)
        var key_ty = 0
        var val_ty = 0
        if self.sema.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST and self.sema.get_generic_inst_arg_count(resolved as i32) == 2:
            key_ty = self.sema.get_generic_inst_arg(resolved as i32, 0)
            val_ty = self.sema.get_generic_inst_arg(resolved as i32, 1)
        let target_base = self.literal_target_base_sym(target_ty)
        if self.is_btreemap_base_sym(target_base) != 0:
            return self.lower_btree_map_literal(node, key_ty, val_ty)
        let saved_expected = self.expected_type
        let args: Vec[i32] = Vec.new()
        for i in 0..pair_count:
            let key_node = self.ast.get_extra(pair_start + i * 2)
            let val_node = self.ast.get_extra(pair_start + i * 2 + 1)
            if key_ty != 0:
                self.expected_type = key_ty
            args.push(self.lower_expr(key_node))
            if val_ty != 0:
                self.expected_type = val_ty
            else:
                self.expected_type = saved_expected
            args.push(self.lower_expr(val_node))
            self.expected_type = saved_expected
        self.lower_collection_literal_call(node, MirIntrinsic.MAP_LITERAL, &args)

    mut fn lower_deref(expr: i32) -> i32:
        let base = self.lower_expr_place(expr)
        self.new_deref_place(base)

    mut fn lower_ref(expr: i32, borrow_kind: i32, node: i32) -> i32:
        let place = self.lower_expr_place(expr)
        let rv = self.body.new_rvalue(RvalueKind.RK_REF, borrow_kind, place, 0)
        let ty = self.expr_type(node)
        let temp = self.new_temp(ty)
        let temp_place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(node))
        self.body.new_operand(OperandKind.OK_COPY, temp_place)

    mut fn lower_slice_expr(node: i32) -> i32:
        let base_node = self.ast.get_data0(node)
        let start_node = self.ast.get_data1(node)
        let end_node = self.ast.get_data2(node)
        let base_place = self.lower_expr_place(base_node)
        let start_op = if start_node != 0:
            self.lower_expr(start_node)
        else:
            self.int_const_operand(0, self.sema.ty_i64)
        var end_op = 0
        if end_node != 0:
            end_op = self.lower_expr(end_node)
        else:
            let len_local = self.new_temp(self.sema.ty_i64)
            let len_place = self.place_for_local(len_local)
            let len_rv = self.body.new_rvalue(RvalueKind.RK_LEN, base_place, 0, 0)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, len_place, len_rv, self.ast.get_start(node))
            end_op = self.body.new_operand(OperandKind.OK_COPY, len_place)

        let slice_rv = self.body.new_rvalue(RvalueKind.RK_SLICE, base_place, start_op, end_op)
        let slice_ty = self.expr_type(node)
        let slice_local = self.new_temp(slice_ty)
        let slice_place = self.place_for_local(slice_local)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, slice_place, slice_rv, self.ast.get_start(node))
        self.body.new_operand(OperandKind.OK_COPY, slice_place)

    mut fn finish_assignment_to_place(place_expr: i32, place: i32, dest_ty: i32, rhs: i32, rhs_reset_start: i32, rhs_field_reset_start: i32, rhs_move_temp_start: i32) -> i32:
        // A consuming call in the RHS may move the assignment target itself
        // (`x = normalize(move x)`). Its source reset must run after the call has
        // read x but before drop-before-overwrite and the result store. Leaving it
        // for finish_stmt_temp_frame emits `x = result; x = zero`, erasing the new
        // owner. Resets created later by moving `rhs` into the destination still
        // flush at the ordinary statement boundary.
        self.flush_pending_resets_since(rhs_reset_start, rhs_field_reset_start, rhs_move_temp_start)
        // An exact `x = move x` (including an identical projected place) moves the
        // owner out and immediately back into the same storage. Decide that it is a
        // no-op before drop-before-overwrite; dropping here would destroy the value
        // that the RHS is meant to restore.
        // #747 instance C: the same holds for `x = copy x`. The restore half of a
        // save/restore idiom whose save stayed a VIEW (`let saved = self.f; …;
        // self.f = saved` with no intervening same-scope overwrite) lowers its RHS
        // through the alias as `copy self.f` — an identical-place copy. Emitting the
        // overwrite drop would free the value being "restored", and the 03h cap-local
        // materialization below would capture the CURRENT value and schedule a drop
        // that frees the payload the field still owns (check_fn_body_with_sig_at's
        // current_module_path froze fn_may_alloc's occ array this way). An
        // identical-place store is a no-op for every type; never drop, never
        // materialize, never store.
        if rhs >= 0 and rhs < self.body.operand_kinds.len() as i32:
            let rhs_kind = self.body.operand_kinds.get(rhs as i64)
            if rhs_kind == OperandKind.OK_MOVE or rhs_kind == OperandKind.OK_COPY:
                if self.places_are_identical(place, self.body.operand_d0.get(rhs as i64)) != 0:
                    return rhs
        if dest_ty != 0 and self.sema.is_copy_frozen(dest_ty) == 0 and self.sema.type_needs_drop_frozen(dest_ty) != 0:
            // #747 (03h): D27 — a binding names WHAT'S THERE. A live view
            // binding aliasing exactly this place names the OLD value, so
            // re-targeting the place must not free or re-read it through the
            // alias. The save/overwrite/restore idiom (`let saved = self.f;
            // self.f = fresh; …; self.f = saved`) freed the saved handle at
            // the overwrite and restored `fresh` onto itself at the restore —
            // check_trait_default_method_body_for_impl's assoc_type_bindings
            // save was the transform_sema hashmap double free. Materialize
            // each such view into an owned local bound to the same name
            // BEFORE the store: the binding keeps the original value and owns
            // it (guarded scope-exit drop), a later `self.f = saved` moves it
            // back, and the overwrite drop is skipped — ownership of the old
            // value transferred to the binding.
            // Same-scope only: the capture statement executes exactly as often
            // as the binding is created. A binding in an OUTER scope with the
            // reassignment in a loop/branch would re-run the capture per
            // iteration and clobber the saved value — that residue class keeps
            // the old drop-before-overwrite (recorded in the #747 handoff).
            var alias_took_old_value = 0
            let cap_scope_start = if self.alias_scope_starts.len() as i32 > 0: self.alias_scope_starts.get(self.alias_scope_starts.len() - 1) else: 0
            var cap_ai = self.alias_places.len() as i32 - 1
            while cap_ai >= cap_scope_start:
                if self.places_are_identical(place, self.alias_places.get(cap_ai as i64)) != 0:
                    let cap_sym: i32 = self.alias_syms.get(cap_ai as i64)
                    let cap_local = self.body.new_local(dest_ty, 0, cap_sym, 1)
                    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, cap_local, 0, self.ast.get_start(place_expr))
                    let cap_place = self.place_for_local(cap_local)
                    let cap_rv = self.body.new_rvalue(RvalueKind.RK_USE, self.body.new_operand(OperandKind.OK_COPY, place), 0, 0)
                    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cap_place, cap_rv, self.ast.get_start(place_expr))
                    self.schedule_drop(cap_local, DropKind.DK_VALUE)
                    self.bind_local(cap_sym, cap_local)
                    // Dead-name the alias entry; the scope pop still removes it
                    // positionally, but lookups now resolve to the owned local.
                    self.alias_syms.set_i32(cap_ai as i64, 0)
                    alias_took_old_value = 1
                cap_ai = cap_ai - 1
            // §16.11 / decisions D8: `*p = v` and `p[i] = v` through a RAW
            // pointer are raw stores — the old pointee may be uninitialized
            // (fresh allocation) or already moved out, so the compiler cannot
            // prove a live old value to drop. The programmer drops explicitly
            // (`let old = *p; drop(old)`). Safe places (bindings, `&mut`
            // derefs, fields) keep drop-before-overwrite.
            if self.assign_target_is_raw_pointer_store(place_expr) == 0 and alias_took_old_value == 0:
                self.emit_drop_place_respecting_moved_fields(place, dest_ty)
        self.assign_operand_to_place(place, rhs, self.ast.get_start(place_expr))
        rhs

    mut fn lower_assign(place_expr: i32, rhs_expr: i32):
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
                        let ip_get_ty = self.expr_type(place_expr)
                        let ip_get_fn_op = self.const_operand(ConstKind.CK_FN, ip_get_fn, ip_get_ty)
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
                    let ret_place = self.place_for_local(0)
                    self.terminate(TermKind.TK_CALL, ip_fn_op, ip_args_id, ret_place, ip_next_bb)
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
            let ca_elem_ty = self.assignment_place_value_type(place_expr)
            let ca_cur = self.body.new_operand(OperandKind.OK_COPY, ca_place)
            let ca_inc = self.lower_expr(ca_inc_expr)
            let ca_result = self.lower_bin_op_operand(ca_op, ca_cur, ca_inc, ca_elem_ty, self.ast.get_start(place_expr))
            self.assign_operand_to_place(ca_place, ca_result, self.ast.get_start(place_expr))
            return

        let place = self.lower_expr_place(place_expr)
        let saved_expected = self.expected_type
        let dest_ty = self.assignment_place_value_type(place_expr)
        let rhs_reset_start = self.pending_reset_locals.len() as i32
        let rhs_field_reset_start = self.pending_reset_field_places.len() as i32
        let rhs_move_temp_start = self.pending_move_temp_locals.len() as i32
        if dest_ty != 0 and dest_ty != self.sema.ty_void:
            self.expected_type = dest_ty
        let rhs = self.lower_expr(rhs_expr)
        self.expected_type = saved_expected
        let _ = self.finish_assignment_to_place(place_expr, place, dest_ty, rhs, rhs_reset_start, rhs_field_reset_start, rhs_move_temp_start)

    // True when an assignment target is a direct deref or index through a
    // raw pointer (`*p = v`, `p[i] = v` with p: *const/*mut T), unwrapping
    // unsafe-block/grouping wrappers around the target and its base.
    mut fn assign_target_is_raw_pointer_store(place_expr: i32) -> i32:
        var target = place_expr
        while target != 0:
            let k = self.ast.kind(target)
            if k != NodeKind.NK_UNSAFE_BLOCK and k != NodeKind.NK_GROUPED:
                break
            target = self.ast.get_data0(target)
        if target == 0:
            return 0
        let kind = self.ast.kind(target)
        var base = 0
        if kind == NodeKind.NK_UNARY and self.ast.get_data0(target) == UnaryOp.UOP_DEREF:
            base = self.ast.get_data1(target)
        else if kind == NodeKind.NK_INDEX:
            base = self.ast.get_data0(target)
        if base == 0:
            return 0
        let base_ty = self.expr_type(base)
        if base_ty == 0:
            return 0
        if self.sema.get_type_kind(self.sema.resolve_alias(base_ty as TypeId)) == TypeKind.TY_PTR: 1 else: 0

    mut fn lower_expr_place(node: i32) -> i32:
        if node == 0:
            return self.place_for_local(0)

        if node == self.pipeline_receiver_override_node and self.pipeline_receiver_override_place >= 0:
            return self.pipeline_receiver_override_place

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
            let magic_kind = self.magic_ident_kind(node)
            if magic_kind != 0:
                let op = self.lower_magic_ident(magic_kind, node)
                let ty = self.expr_type(node)
                let tmp = self.new_temp(ty)
                let p = self.place_for_local(tmp)
                self.assign_operand_to_place(p, op, self.ast.get_start(node))
                self.register_stmt_temp(tmp, ty)
                return p
            self.mark_unsupported()
            return self.place_for_local(0)

        if kind == NodeKind.NK_FIELD_ACCESS:
            let base = self.lower_field_base_place(self.ast.get_data0(node))
            let field_sym = self.ast.get_data1(node)
            let field_ty = self.expr_type(node)
            if field_ty == 0 or field_ty == self.sema.ty_void as i32:
                self.mark_unsupported()
                return self.place_for_local(0)
            return self.new_projected_field_place(base, field_sym, field_ty)

        if kind == NodeKind.NK_INDEX:
            if self.vec_literal_type(node) != 0:
                let op = self.lower_expr(node)
                let ty = self.expr_type(node)
                let tmp = self.new_temp(ty)
                let p = self.place_for_local(tmp)
                self.assign_operand_to_place(p, op, self.ast.get_start(node))
                self.register_stmt_temp(tmp, ty)
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

        // A D21 place-threading pipeline already denotes its receiver place.
        // Do not materialize its OK_MOVE carrier into a second owned temporary
        // when the next stage asks for an addressable receiver.
        if kind == NodeKind.NK_PIPELINE and self.sema.pipeline_carrier_kinds.contains(node) and self.sema.pipeline_carrier_kinds.get(node).unwrap() != 0:
            let pipeline_op = self.lower_expr(node)
            if pipeline_op >= 0 and pipeline_op < self.body.operand_kinds.len() as i32:
                let op_kind = self.body.operand_kinds.get(pipeline_op as i64)
                if op_kind == OperandKind.OK_COPY or op_kind == OperandKind.OK_MOVE:
                    return self.body.operand_d0.get(pipeline_op as i64)

        if kind == NodeKind.NK_MOVE_ARG:
            let inner = self.ast.get_data0(node)
            let place = self.lower_expr_place(inner)
            let local_id = mir_place_plain_local(&self.body, place)
            if local_id >= 0:
                self.mark_local_value_moved(local_id)
                self.cancel_scheduled_value_drop_for_local(local_id)
                self.cancel_stmt_temp_for_local(local_id)
            return place

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
        self.register_stmt_temp(tmp, ty)
        p

    mut fn lower_let_binding(node: i32):
        let name_sym = self.ast.get_data0(node)
        let rhs_expr = self.ast.get_data1(node)
        let flags = self.ast.get_data2(node)
        let mutable = flags % 2
        let is_discard_binding = if name_sym != 0 and self.pool.resolve_symbol(name_sym) == "_": 1 else: 0

        let bind_ty = self.binding_type(node)
        if mutable == 0:
            // §2.4: a drop-body self-field let CONSUMES — never the alias
            // path (an alias left the field glue skipping a field nobody
            // owned: the 84ebff6d leak, now bound as an owning local whose
            // drop precedes the glue — spec_ss02_4 pins the WFN order).
            if self.sema.is_copy_frozen(bind_ty) == 0 and not self.sema.drop_consumed_binding_values.contains(rhs_expr):
                let alias_place = self.lower_binding_alias_place(rhs_expr)
                if alias_place >= 0:
                    // A live str view of this place: later self-appends must
                    // take the COPY concat form, never in-place move_first
                    // (`let saved = a.buf; a.buf = a.buf ++ ...` — the alias
                    // taint the dump_mir_str_field_concat pins assert).
                    if self.place_type_is_str(alias_place) != 0:
                        self.mark_string_place_copied(alias_place)
                    self.bind_alias_place(name_sym, alias_place, bind_ty)
                    return
        let local_id = self.body.new_local(bind_ty, mutable, name_sym, 1)

        // d1 = 0 for normal storage, bind_ty for zero-init (no initializer)
        let storage_d1 = if rhs_expr == 0: bind_ty else: 0
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, storage_d1, self.ast.get_start(node))
        var scheduled_drop_kind = DropKind.DK_VALUE
        if self.sema.is_copy_frozen(bind_ty) == 0:
            scheduled_drop_kind = self.task_drop_kind_for_binding(node, bind_ty)
            if is_discard_binding == 0:
                self.schedule_drop(local_id, scheduled_drop_kind)

        var rhs_is_view_if = 0
        if rhs_expr != 0:
            let place = self.place_for_local(local_id)
            let saved_expected = self.expected_type
            self.expected_type = bind_ty
            let rhs_op = self.lower_expr(rhs_expr)
            self.expected_type = saved_expected
            self.assign_operand_to_place(place, rhs_op, self.ast.get_start(node))
            // Ordinary assignment-move transfers a non-Copy RHS place into the
            // binding. Cancel the source's value drop after the value has been
            // captured; projected moves also queue their D17 reset below.
            self.cancel_scheduled_value_drop_for_receiver_expr(rhs_expr)
            // #747 (03g): a pure-view if-result (all result arms place-reads
            // of named storage or constants) binds as a VIEW — cancel the
            // scheduled scope-exit drop so the binding does not free storage
            // its arms merely read.
            if mutable == 0 and self.ast.kind(rhs_expr) == NodeKind.NK_IF_EXPR and self.last_if_result_view != 0:
                rhs_is_view_if = 1
                if self.sema.is_copy_frozen(bind_ty) == 0 and is_discard_binding == 0:
                    self.cancel_scheduled_value_drop_for_local(local_id)
        if is_discard_binding != 0:
            if self.sema.is_copy_frozen(bind_ty) == 0 and rhs_is_view_if == 0:
                self.emit_drop_entry(local_id, scheduled_drop_kind)
            else:
                self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, self.ast.get_start(node))
            return
        self.bind_local(name_sym, local_id)

    mut fn lower_tuple_destructure(node: i32):
        let extra_start = self.ast.get_data0(node)
        let name_count = self.ast.get_data1(node)
        let rhs_expr = self.ast.get_data2(node)
        let rhs_ty = self.expr_type(rhs_expr)
        let rhs_op = self.lower_expr(rhs_expr)
        let rhs_place = self.materialize_operand(rhs_op, rhs_ty, self.ast.get_start(node))
        // Bind each name to the corresponding tuple field. Tuple destructure requires
        // exact arity (sema rejects `..` here), so position ni == tuple element index.
        for ni in 0..name_count:
            let n_sym = self.ast.get_extra(extra_start + ni)
            // Negative sym means ..rest pattern — skip (defensive; not reachable).
            if n_sym < 0:
                continue
            let elem_ty = self.tuple_elem_type(rhs_ty, ni)
            let move_kind = if self.type_needs_value_drop(elem_ty) == 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
            let field_place = self.body.new_tuple_index_place(rhs_place, ni, elem_ty)
            let field_op = self.body.new_operand(move_kind, field_place)
            if n_sym == 0:
                // Discarded `_`: a Drop element must still drop exactly once (#606).
                // Move it into an anonymous local that drops at scope exit so it is
                // neither leaked nor double-freed by the source-tuple consume below.
                if self.type_needs_value_drop(elem_ty) != 0:
                    let discard_local = self.body.new_local(elem_ty, 0, 0, 1)
                    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, discard_local, 0, self.ast.get_start(node))
                    self.schedule_drop(discard_local, DropKind.DK_VALUE)
                    let discard_place = self.place_for_local(discard_local)
                    self.assign_operand_to_place(discard_place, field_op, self.ast.get_start(node))
                continue
            let local_id = self.body.new_local(elem_ty, 0, n_sym, 1)
            self.bind_local(n_sym, local_id)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(node))
            if self.type_needs_value_drop(elem_ty) != 0:
                self.schedule_drop(local_id, DropKind.DK_VALUE)
            let dst_place = self.place_for_local(local_id)
            self.assign_operand_to_place(dst_place, field_op, self.ast.get_start(node))
        // #605/#606: every element has been moved out into a binding (or an anonymous
        // drop-local for `_`), so the source tuple owns nothing. Cancel its value drop
        // (it is a materialized stmt temp) so the new tuple element-drop does not also
        // free the moved-out elements. Oracle: `let (tx, rx) = channel()`.
        let src_local = mir_place_plain_local(&self.body, rhs_place)
        if src_local >= 0:
            self.cancel_stmt_temp_for_local(src_local)
            self.cancel_scheduled_value_drop_for_local(src_local)
            self.mark_local_value_moved(src_local)

    mut fn lower_let_else(node: i32):
        let pat = self.ast.get_data0(node)
        let rhs = self.ast.get_data1(node)
        let else_body = self.ast.get_data2(node)
        let rhs_op = self.lower_expr(rhs)
        let rhs_ty = self.expr_type(rhs)
        let rhs_place = self.materialize_operand(rhs_op, rhs_ty, self.ast.get_start(rhs))

        if else_body == 0:
            let _ = self.lower_pattern(pat, rhs_place)
            // #605/#606: an irrefutable destructure (e.g. `let (a, b) = t`) moves the
            // source's contents into the pattern bindings, which now own and drop them.
            // Two owners must be silenced so the new aggregate element-drop does not
            // double-free the moved-out bindings:
            //   1. the materialized scrutinee copy (rhs_place), and
            //   2. a named source expression (which is copied, not moved, into it).
            let mat_local = mir_place_plain_local(&self.body, rhs_place)
            if mat_local >= 0:
                self.cancel_stmt_temp_for_local(mat_local)
                self.cancel_scheduled_value_drop_for_local(mat_local)
                self.mark_local_value_moved(mat_local)
            self.cancel_scheduled_value_drop_for_receiver_expr(rhs)
            return

        let success_bb = self.new_block()
        let fail_bb = self.new_block()
        let cont_bb = self.new_block()

        self.lower_pattern_match(rhs_place, pat, success_bb, fail_bb)

        self.switch_to(success_bb)
        let _ = self.lower_pattern(pat, rhs_place)
        // #605/#606: consume the let-else subject on the success path so the enum
        // payload-drop does not double-free the moved-out bindings (the fail path
        // diverges, so the subject is owned only here).
        let le_scrut_local = mir_place_plain_local(&self.body, rhs_place)
        if le_scrut_local >= 0:
            self.cancel_stmt_temp_for_local(le_scrut_local)
            self.cancel_scheduled_value_drop_for_local(le_scrut_local)
            self.mark_local_value_moved(le_scrut_local)
        self.cancel_scheduled_value_drop_for_receiver_expr(rhs)
        self.terminate(TermKind.TK_GOTO, cont_bb, 0, 0, 0)

        self.switch_to(fail_bb)
        let _ = self.lower_expr(else_body)
        if self.body.term_kind(self.cur_bb) == TermKind.TK_UNREACHABLE:
            self.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)

        self.switch_to(cont_bb)

    mut fn lower_expr_discard(node: i32) -> i32:
        if node == 0:
            return self.unit_operand()
        if self.sema.detached_task_stmt_nodes.contains(node):
            let task_op = self.lower_expr(node)
            self.emit_task_cancel_call(task_op, MirIntrinsic.FIBER_DETACH, node)
            return self.unit_operand()
        let saved_expected = self.expected_type
        let kind = self.ast.kind(node)
        let result = if kind == NodeKind.NK_BLOCK:
            self.lower_block_mode(node, 0)
        else if kind == NodeKind.NK_IF_EXPR:
            self.lower_if(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node, 0)
        else if kind == NodeKind.NK_MATCH:
            self.lower_match(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node, 0)
        else if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_UNSAFE_BLOCK:
            self.lower_expr_discard(self.ast.get_data0(node))
        else if kind == NodeKind.NK_NO_SUSPEND:
            self.no_suspend_nodes.push(node)
            let inner_result = self.lower_expr_discard(self.ast.get_data0(node))
            self.no_suspend_nodes.pop()
            inner_result
        else if kind == NodeKind.NK_WITH_EXPR and self.sema.with_form_kinds.contains(node) and (self.sema.with_form_kinds.get(node).unwrap() == WithFormKind.Guarded as i32 or self.sema.with_form_kinds.get(node).unwrap() == WithFormKind.GuardedMut as i32):
            self.cur_node = node
            self.lower_with_guarded_mode(node, 0)
        else:
            self.lower_expr(node)
        self.expected_type = saved_expected
        let _ = result
        self.unit_operand()

    fn scope_body_tail_is_method_call(node: i32, scope_sym: i32, method_sym: i32) -> i32:
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

    mut fn lower_block(node: i32) -> i32:
        self.lower_block_mode(node, 1)

    // A want_result block tail that lowered to a LAZY OK_MOVE of a field
    // place (the NK_MOVE_ARG field arm) must materialize BEFORE this
    // block's scope-exit drops: left lazy, pop_scope_inline drops the
    // base local in full (the move was never recorded) and the outer
    // consumer's capture reads freed storage — tail `move owned.field`
    // returned a blanked Vec. ONLY the explicit `move` spelling routes
    // here: bare field tails also lower to OK_MOVE place operands (view
    // returns, borrow tails) and materializing those copies the pointee
    // into a value temp that mismatches a `&`-typed destination.
    // Whole-local OK_MOVE operands are recorded eagerly and stay lazy.
    mut fn materialize_tail_field_move(result: i32, tail_expr: i32) -> i32:
        var tail = tail_expr
        while tail != 0:
            let tk = self.ast.kind(tail)
            if tk != NodeKind.NK_GROUPED and tk != NodeKind.NK_NO_SUSPEND and tk != NodeKind.NK_UNSAFE_BLOCK:
                break
            tail = self.ast.get_data0(tail)
        if tail == 0 or self.ast.kind(tail) != NodeKind.NK_MOVE_ARG:
            return result
        if self.body.operand_kinds.get(result as i64) != OperandKind.OK_MOVE:
            return result
        let place: i32 = self.body.operand_d0.get(result as i64)
        if mir_place_plain_local(&self.body, place) >= 0:
            return result
        let moved_ty = self.operand_type(result)
        let moved_tmp = self.new_temp(moved_ty)
        let moved_place = self.place_for_local(moved_tmp)
        let moved_rv = self.body.new_rvalue(RvalueKind.RK_USE, result, 0, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, moved_place, moved_rv, self.ast.get_start(tail_expr))
        self.consume_moved_operand(result)
        self.body.new_operand(OperandKind.OK_COPY, moved_place)

    mut fn lower_generator_yield(node: i32) -> i32:
        let inner = self.ast.get_data0(node)
        let value_op = if inner != 0: self.lower_expr(inner) else: self.unit_operand()
        let resume_bb = self.new_block()
        let yield_idx = self.generator_yield_count
        self.generator_yield_count = self.generator_yield_count + 1
        self.terminate_with_span(TermKind.TK_YIELD, value_op, resume_bb, yield_idx, 0, self.ast.get_start(node))
        self.switch_to(resume_bb)
        self.unit_operand()

    mut fn lower_block_mode(node: i32, want_result: i32) -> i32:
        if with_getenv_str("WITH_TRACE_SCOPES").len() > 0:
            with_eprint(f"[scope] block node={node} stmts={self.ast.get_data1(node)} tail={self.ast.get_data2(node)} want={want_result} bb={self.cur_bb as i32}")
        let stmt_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail_expr = self.ast.get_data2(node)
        let block_meta = self.ast.find_block_meta(node)
        let block_label = if block_meta >= 0: self.ast.block_meta_label(block_meta) else: 0
        let labeled_after_bb: BlockId = if block_label != 0: self.new_block() else: 0 as BlockId

        if block_label != 0:
            self.push_control_target(block_label, ControlTargetKind.CT_BLOCK, -1, labeled_after_bb, -1)
        self.push_scope()
        let defer_start = self.defer_nodes.len() as i32

        for i in 0..stmt_count:
            let stmt = self.ast.get_extra(stmt_start + i)
            let sk = self.ast.kind(stmt)
            let stmt_frame = self.push_stmt_temp_frame()
            if sk == NodeKind.NK_LET_BINDING:
                self.lower_let_binding(stmt)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_LET_ELSE:
                self.lower_let_else(stmt)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_ASSIGN:
                self.lower_assign(self.ast.get_data0(stmt), self.ast.get_data1(stmt))
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_RETURN:
                let _ = self.lower_return(stmt)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_BREAK:
                let _ = self.lower_break(stmt)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_CONTINUE:
                let _ = self.lower_continue(stmt)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_GOTO:
                let _ = self.lower_goto(stmt)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_LABEL:
                let _ = self.lower_label(stmt)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_YIELD:
                if self.in_generator != 0:
                    let _ = self.lower_generator_yield(stmt)
                    self.finish_stmt_temp_frame(stmt_frame)
                    continue
            
            if sk == NodeKind.NK_DEFER:
                let defer_body = self.ast.get_data0(stmt)
                if defer_body != 0:
                    self.defer_nodes.push(defer_body)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_ERRDEFER:
                let errdefer_body = self.ast.get_data0(stmt)
                if errdefer_body != 0:
                    self.errdefer_nodes.push(errdefer_body)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            if sk == NodeKind.NK_TUPLE_DESTRUCTURE:
                self.lower_tuple_destructure(stmt)
                self.finish_stmt_temp_frame(stmt_frame)
                continue
            let _ = self.lower_expr_discard(stmt)
            self.finish_stmt_temp_frame(stmt_frame)

        var result = self.unit_operand()
        if tail_expr != 0:
            if want_result != 0:
                self.cancel_scheduled_value_drop_for_receiver_expr(tail_expr)
                result = self.lower_expr(tail_expr)
                result = self.materialize_tail_field_move(result, tail_expr)
            else:
                let tail_frame = self.push_stmt_temp_frame()
                result = self.lower_expr_discard(tail_expr)
                self.finish_stmt_temp_frame(tail_frame)

        // Emit defers added in this block scope (LIFO order), before popping scope
        let defer_end = self.defer_nodes.len() as i32
        if defer_end > defer_start:
            var di = defer_end - 1
            while di >= defer_start:
                let defer_body: i32 = self.defer_nodes.get(di as i64)
                let _ = self.lower_expr(defer_body)
                di = di - 1
            // Remove the block's defers from the stack
            while self.defer_nodes.len() as i32 > defer_start:
                self.defer_nodes.pop()

        self.pop_scope_inline()
        if block_label != 0:
            // #640: a labeled block used in value/tail position yields its tail
            // value (§29.13). Materialize the tail value into a stable place before
            // the goto so it is valid in labeled_after_bb (the value was computed in
            // the pre-goto block). Statement-position labeled blocks (want_result
            // == 0) still yield unit.
            var labeled_result = self.unit_operand()
            if want_result != 0:
                let lr_ty = self.operand_type(result)
                if lr_ty != 0 and lr_ty != self.sema.ty_void as i32:
                    let lr_tmp = self.new_temp(lr_ty)
                    let lr_place = self.place_for_local(lr_tmp)
                    self.assign_operand_to_place(lr_place, result, self.ast.get_start(node))
                    labeled_result = self.body.new_operand(OperandKind.OK_COPY, lr_place)
            self.terminate(TermKind.TK_GOTO, labeled_after_bb, 0, 0, 0)
            self.pop_control_target()
            self.switch_to(labeled_after_bb)
            return labeled_result
        if want_result != 0: result else: self.unit_operand()

    mut fn lower_if(cond_expr: i32, then_expr: i32, else_expr_opt: i32, node: i32, want_result: i32) -> i32:
        var cond_op = 0
        var regex_capture_node = 0
        var regex_captures_opt_place = -1
        let cond_frame = self.push_stmt_temp_frame()
        if self.ast.kind(cond_expr) == NodeKind.NK_MATCH_OP:
            let lhs = self.ast.get_data0(cond_expr)
            let rhs = self.ast.get_data1(cond_expr)
            let regex_text_place = self.lower_regex_subject_place(lhs)
            let regex_op = self.lower_expr(rhs)
            let regex_ty = self.expr_type(rhs)
            let regex_capture_place = self.materialize_operand(regex_op, regex_ty, self.ast.get_start(rhs))
            regex_captures_opt_place = self.lower_regex_captures_places(regex_capture_place, regex_text_place)
            cond_op = self.lower_option_is_some_place(regex_captures_opt_place, self.regex_captures_option_type())
            if self.ast.kind(rhs) == NodeKind.NK_REGEX_LIT:
                regex_capture_node = rhs
        else:
            cond_op = self.lower_expr(cond_expr)
        self.finish_stmt_temp_frame(cond_frame)

        let if_entry_bb = self.cur_bb as i32
        let branch_drop_depth = self.drop_local_ids.len() as i32
        let branch_move_state = self.save_move_state()
        // Reset-on-move (spec §2.5.1): only flush resets recorded WITHIN a branch,
        // so an outer-scope move's reset is not pulled inside (and made conditional
        // by) this if.
        let pending_reset_start = self.pending_reset_locals.len() as i32
        let pending_reset_field_start = self.pending_reset_field_places.len() as i32
        let pending_move_temp_start = self.pending_move_temp_locals.len() as i32

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
        // #772: never propagate a VOID result type as the arms' expected type
        // — a statement-if reached in value mode (`with … as mut c:` bodies)
        // poisoned an arm assign's RHS binop to void (invalid MIR).
        if want_result != 0 and result_ty != 0 and result_ty != self.sema.ty_void as i32:
            self.expected_type = result_ty
        else if want_result == 0:
            self.expected_type = self.sema.ty_void as i32

        self.switch_to(then_bb)
        self.field_move_in_branch = self.field_move_in_branch + 1
        if regex_capture_node != 0:
            self.lower_regex_capture_bindings_from_option(regex_capture_node, regex_captures_opt_place)
        // A statement temp created INSIDE a branch belongs to that branch, not to
        // the enclosing statement: registered outward, its drop lands at the
        // enclosing boundary — the join block — which the not-taken path also
        // reaches, dropping a temp that path never created (#729: an else path
        // freeing an uninitialized call-result temp). Frame it like the
        // condition above; a temp moved into the branch result is cancelled by
        // assign_operand_to_place before the frame closes.
        let then_temp_frame = self.push_stmt_temp_frame()
        let then_op = if want_result != 0: self.lower_expr(then_expr) else: self.lower_expr_discard(then_expr)
        // A diverging branch has no value to contribute to the join. lower_return
        // leaves a Unit operand in its unreachable continuation; assigning that
        // operand to the if result place corrupts typed MIR.
        if want_result != 0 and self.sema.body_can_fall_through(then_expr) != 0:
            self.assign_operand_to_place(result_place, then_op, self.ast.get_start(then_expr))
        self.finish_stmt_temp_frame(then_temp_frame)
        // Reset-on-move (spec §2.5.1): flush this branch's pending source-resets
        // INSIDE the branch, before merging. A move in the branch's tail expression
        // has no per-statement flush; left pending it would be emitted after the if
        // on BOTH paths and blank a still-live value on the not-taken path.
        self.flush_pending_resets_since(pending_reset_start, pending_reset_field_start, pending_move_temp_start)
        self.field_move_in_branch = self.field_move_in_branch - 1
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.restore_move_state(&branch_move_state)

        self.switch_to(else_bb)
        self.field_move_in_branch = self.field_move_in_branch + 1
        let else_temp_frame = self.push_stmt_temp_frame()
        let else_op = if else_expr_opt != 0:
            if want_result != 0: self.lower_expr(else_expr_opt) else: self.lower_expr_discard(else_expr_opt)
        else:
            self.unit_operand()
        if want_result != 0 and (else_expr_opt == 0 or self.sema.body_can_fall_through(else_expr_opt) != 0):
            self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
        self.finish_stmt_temp_frame(else_temp_frame)
        self.flush_pending_resets_since(pending_reset_start, pending_reset_field_start, pending_move_temp_start)
        self.field_move_in_branch = self.field_move_in_branch - 1
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.restore_move_state(&branch_move_state)

        self.expected_type = saved_expected

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        if want_result == 0:
            self.last_if_result_view = 0
            return self.unit_operand()
        // #747 (03g): D27 "a binding names what's there" — an if whose result
        // arms are all place-reads of named storage (or constants) yields a
        // VIEW. The result temp used to register a stmt-temp drop and return
        // OK_MOVE; dropping the bit-copied header freed the arm's base
        // storage (Sema.record_named_type_with_pub's
        // `let path = if ...: self.current_module_path else: ""` freed the
        // module-path buffer once per call — the 03g double free). A view
        // result registers no drop and reads as a copy; lower_let_binding
        // cancels a binding's scheduled drop via last_if_result_view. Mixed
        // owned/view arms keep owned typing (residual: the view arm still
        // bit-copies; see handoff 03g).
        self.last_if_result_view = if self.sema.is_copy_frozen(result_ty) == 0 and self.operand_is_view_read(then_op) != 0 and self.operand_is_view_read(else_op) != 0: 1 else: 0
        if self.last_if_result_view != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.register_stmt_temp(result_local, result_ty)
        if self.sema.is_copy_frozen(result_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_if_let(pat: i32, scrutinee_expr: i32, then_expr: i32, else_expr_opt: i32, node: i32) -> i32:
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

        // Each branch is its own temporary scope (lower_if, #729; lower_match):
        // a temp created inside one branch must drop on that branch's path,
        // never at the join where the other path would free garbage.
        self.switch_to(then_bb)
        let _ = self.lower_pattern(pat, scrutinee_place)
        let then_temp_frame = self.push_stmt_temp_frame()
        let then_op = self.lower_expr(then_expr)
        self.assign_operand_to_place(result_place, then_op, self.ast.get_start(then_expr))
        self.finish_stmt_temp_frame(then_temp_frame)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(else_bb)
        let else_temp_frame = self.push_stmt_temp_frame()
        let else_op = if else_expr_opt != 0: self.lower_expr(else_expr_opt) else: self.unit_operand()
        self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
        self.finish_stmt_temp_frame(else_temp_frame)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        // #605/#606: like match, consume the if-let subject so the enum payload-drop
        // does not double-free a moved-out binding. (Unmatched / ref-bound payloads
        // then leak — sound.)
        let iflet_scrut_local = mir_place_plain_local(&self.body, scrutinee_place)
        if iflet_scrut_local >= 0:
            self.cancel_stmt_temp_for_local(iflet_scrut_local)
            self.cancel_scheduled_value_drop_for_local(iflet_scrut_local)
            self.mark_local_value_moved(iflet_scrut_local)
        self.cancel_scheduled_value_drop_for_receiver_expr(scrutinee_expr)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        self.register_stmt_temp(result_local, result_ty)
        if self.sema.is_copy_frozen(result_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_loop(body_expr: i32, node: i32) -> i32:
        let header_bb = self.new_block()
        let body_bb = self.new_block()
        let break_bb = self.new_block()
        let loop_ty = if self.sema.typed_expr_types.contains(node): self.sema.typed_expr_types.get(node).unwrap() else: self.sema.ty_void as i32
        let has_result = loop_ty != 0 and loop_ty != self.sema.ty_void and loop_ty != self.sema.ty_never
        var result_place = -1
        if has_result:
            let result_tmp = self.new_temp(loop_ty)
            result_place = self.place_for_local(result_tmp)

        self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

        self.switch_to(header_bb)
        self.terminate(TermKind.TK_GOTO, body_bb, 0, 0, 0)

        self.push_control_target(self.ast.get_data1(node), ControlTargetKind.CT_LOOP, header_bb, break_bb, result_place)

        self.switch_to(body_bb)
        let pending_reset_start = self.pending_reset_locals.len() as i32
        let pending_reset_field_start = self.pending_reset_field_places.len() as i32
        let pending_move_temp_start = self.pending_move_temp_locals.len() as i32
        self.field_move_in_branch = self.field_move_in_branch + 1
        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
        // Reset-on-move (spec §2.5.1): flush body-local resets before the back-edge,
        // so a move in the loop body's tail is reset inside the body (same as lower_if).
        self.flush_pending_resets_since(pending_reset_start, pending_reset_field_start, pending_move_temp_start)
        self.field_move_in_branch = self.field_move_in_branch - 1
        // Back-edge when body does not diverge.
        self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

        self.pop_control_target()
        self.switch_to(break_bb)
        self.forget_string_flow_facts()
        if has_result:
            if self.sema.is_copy_frozen(loop_ty as TypeId) != 0:
                return self.body.new_operand(OperandKind.OK_COPY, result_place)
            return self.body.new_operand(OperandKind.OK_MOVE, result_place)
        self.unit_operand()

    mut fn lower_while(cond_expr: i32, body_expr: i32, node: i32) -> i32:
        let cond_bb = self.new_block()
        let body_bb = self.new_block()
        let exit_bb = self.new_block()

        self.terminate(TermKind.TK_GOTO, cond_bb, 0, 0, 0)

        self.push_control_target(self.ast.get_data2(node), ControlTargetKind.CT_LOOP, cond_bb, exit_bb, -1)

        self.switch_to(cond_bb)
        var cond_op = 0
        var regex_capture_node = 0
        var regex_captures_opt_place = -1
        let cond_frame = self.push_stmt_temp_frame()
        if self.ast.kind(cond_expr) == NodeKind.NK_MATCH_OP:
            let lhs = self.ast.get_data0(cond_expr)
            let rhs = self.ast.get_data1(cond_expr)
            let text_place = self.lower_regex_subject_place(lhs)
            let regex_op = self.lower_expr(rhs)
            let regex_ty = self.expr_type(rhs)
            let regex_place = self.materialize_operand(regex_op, regex_ty, self.ast.get_start(rhs))
            regex_captures_opt_place = self.lower_regex_captures_places(regex_place, text_place)
            cond_op = self.lower_option_is_some_place(regex_captures_opt_place, self.regex_captures_option_type())
            if self.ast.kind(rhs) == NodeKind.NK_REGEX_LIT:
                regex_capture_node = rhs
        else:
            cond_op = self.lower_expr(cond_expr)
        self.finish_stmt_temp_frame(cond_frame)
        let vals: Vec[i32] = Vec.new()
        vals.push(1)
        let targets: Vec[i32] = Vec.new()
        targets.push(body_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, cond_op, table, exit_bb, 0)

        self.switch_to(body_bb)
        if regex_capture_node != 0:
            self.lower_regex_capture_bindings_from_option(regex_capture_node, regex_captures_opt_place)
        let pending_reset_start = self.pending_reset_locals.len() as i32
        let pending_reset_field_start = self.pending_reset_field_places.len() as i32
        let pending_move_temp_start = self.pending_move_temp_locals.len() as i32
        self.field_move_in_branch = self.field_move_in_branch + 1
        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
        self.flush_pending_resets_since(pending_reset_start, pending_reset_field_start, pending_move_temp_start)
        self.field_move_in_branch = self.field_move_in_branch - 1
        self.terminate(TermKind.TK_GOTO, cond_bb, 0, 0, 0)

        self.pop_control_target()
        self.switch_to(exit_bb)
        self.forget_string_flow_facts()
        self.unit_operand()

    mut fn lower_do_while(body_expr: i32, cond_expr: i32, node: i32) -> i32:
        let body_bb = self.new_block()
        let cond_bb = self.new_block()
        let exit_bb = self.new_block()

        self.terminate(TermKind.TK_GOTO, body_bb, 0, 0, 0)

        self.push_control_target(self.ast.get_data2(node), ControlTargetKind.CT_LOOP, cond_bb, exit_bb, -1)

        self.switch_to(body_bb)
        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
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

    mut fn lower_for(for_node: i32) -> i32:
        let pat_or_sym = self.ast.get_data0(for_node)
        let iter_expr = self.ast.get_data1(for_node)
        let body_expr = self.ast.get_data2(for_node)
        // Check for range-based for: for i in start..end
        if self.ast.kind(iter_expr) == NodeKind.NK_RANGE:
            return self.lower_for_range(for_node, pat_or_sym, iter_expr, body_expr)

        // #607: `for w in &vec` / `for w in &h.field` → borrow-iterate (loop var &T) via
        // the iter_ref path, which borrows the receiver in place (no element copy, no
        // drop-scheduled header copy). The `&` operand is the Vec place itself.
        if self.ast.kind(iter_expr) == NodeKind.NK_UNARY and self.ast.get_data0(iter_expr) == UnaryOp.UOP_REF:
            let ref_inner = self.ast.get_data1(iter_expr)
            let ref_inner_ty = self.expr_type(ref_inner)
            if ref_inner_ty != 0:
                let ref_inner_resolved = self.sema.resolve_alias(ref_inner_ty)
                if self.sema.get_type_kind(ref_inner_resolved) == TypeKind.TY_GENERIC_INST:
                    let rin_sym = self.sema.get_type_name(ref_inner_resolved)
                    if rin_sym != 0 and self.pool.resolve(rin_sym) == "Vec":
                        return self.lower_for_iter_ref(for_node, pat_or_sym, ref_inner, body_expr)

        // Range variable: iter_expr is an ident/expr whose type is TY_RANGE
        let iter_ty = self.expr_type(iter_expr)
        if iter_ty != 0:
            let range_resolved = self.sema.resolve_alias(iter_ty)
            if self.sema.get_type_kind(range_resolved) == TypeKind.TY_RANGE:
                return self.lower_for_range_var(for_node, pat_or_sym, iter_expr, body_expr, range_resolved)
            // A binding of type &Vec[T] (e.g. the &T view yielded by an outer
            // Drop-element loop) borrow-iterates like the syntactic `&vec` form.
            if self.sema.get_type_kind(range_resolved) == TypeKind.TY_REF:
                let ref_pointee = self.sema.resolve_alias(self.sema.get_type_d0(range_resolved))
                if self.sema.get_type_kind(ref_pointee) == TypeKind.TY_GENERIC_INST:
                    let rp_sym = self.sema.get_type_name(ref_pointee)
                    if rp_sym != 0 and self.pool.resolve(rp_sym) == "Vec":
                        return self.lower_for_iter_ref(for_node, pat_or_sym, iter_expr, body_expr)

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
                        // §13 implicit iteration borrows the collection.
                        // Drop-class elements iterate as &T views; Copy-class
                        // elements keep owned bindings read through the
                        // borrowed place (lower_for_vec no longer moves it).
                        let bare_elem = self.sema.get_generic_inst_arg(resolved as i32, 0)
                        if self.sema.type_needs_drop_frozen(bare_elem) != 0 and self.sema.is_copy_frozen(bare_elem) == 0:
                            return self.lower_for_iter_ref(for_node, pat_or_sym, iter_expr, body_expr)
                        return self.lower_for_vec(for_node, pat_or_sym, iter_expr, body_expr)
                    if type_name == "HashMap":
                        return self.lower_for_hashmap(for_node, pat_or_sym, iter_expr, body_expr)
                    if type_name == "Receiver":
                        return self.lower_for_receiver(for_node, pat_or_sym, iter_expr, body_expr)

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
                                    // .iter() ≡ the implicit form (§13): same
                                    // borrow split as the bare-Vec dispatch.
                                    let it_elem = self.sema.get_generic_inst_arg(recv_resolved as i32, 0)
                                    if self.sema.type_needs_drop_frozen(it_elem) != 0 and self.sema.is_copy_frozen(it_elem) == 0:
                                        return self.lower_for_iter_ref(for_node, pat_or_sym, recv, body_expr)
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
        // #912: for a generic iterator, check_for recorded the concrete
        // next() specialization keyed by the for node — dispatch exactly
        // that; the template sym alone names no lowered function.
        let next_sym = self.pool.intern("next")
        let recorded_mono = self.sema.iter_next_mono_syms.get(for_node)
        var recorded_mono_sym = 0
        if recorded_mono.is_some(): recorded_mono_sym = recorded_mono.unwrap()
        let recorded_sig = self.sema.iter_next_sigs.get(for_node)
        var recorded_sig_idx = -1
        if recorded_sig.is_some(): recorded_sig_idx = recorded_sig.unwrap()
        let callee_sym = if recorded_mono_sym != 0: recorded_mono_sym else: self.resolve_method_callee_sym(iter_expr, next_sym)
        if callee_sym == next_sym:
            self.mark_unsupported()

        let iter_op = self.lower_expr(iter_expr)
        let iter_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))
        let elem_ty = self.sema.infer_for_element_type_frozen(iter_ty)

        // Determine next()'s return type (Option[T]) from the method signature.
        let resolved_iter = self.sema.resolve_alias(iter_ty)
        let owner_sym = self.sema.method_owner_symbol_for_type(resolved_iter as i32)
        let sema_next_sym = self.sema.pool_lookup_symbol("next")
        var next_ret_ty = 0
        if recorded_sig_idx >= 0:
            next_ret_ty = self.sema.sig_return_type(recorded_sig_idx)
        if next_ret_ty == 0 and owner_sym != 0 and sema_next_sym > 0:
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
        if recorded_sig_idx >= 0:
            // Route through the generic-call contract so codegen lazily
            // emits the recorded next() specialization (#912).
            self.body.set_call_intrinsic(args_id, MirIntrinsic.GENERIC_CALL)
            self.body.set_call_ast_node(args_id, for_node)
            self.body.set_call_contract(args_id, recorded_sig_idx, recorded_mono_sym)
            self.body.require_call_contract(args_id)
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
        // Drop-class elements MOVE out of the Option temp (the `?` idiom) —
        // a copy leaves the stale Some to double-drop the payload at cleanup.
        let next_payload = self.body.new_operand(if self.sema.is_copy_frozen(elem_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, payload_place)
        self.assign_operand_to_place(item_place, next_payload, self.ast.get_start(iter_expr))

        // #614b + D33: the binding itself lives in a per-iteration scope. A
        // Drop-class element yielded by value (consuming iteration) must drop
        // once per iteration on the back-edge/break edge — registered in the
        // function scope it drops again at exit (the drop#17/drop#20 double).
        self.push_scope()
        self.bind_for_element_or_skip(for_node, pat_or_sym, item_place, elem_ty, body_expr, header_bb)

        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
        self.pop_scope_with_goto(header_bb)

        self.pop_control_target()
        self.switch_to(exit_bb)
        self.forget_string_flow_facts()
        self.unit_operand()

    fn for_label(for_node: i32) -> i32:
        let for_meta = self.ast.find_for_meta(for_node)
        if for_meta >= 0:
            return self.ast.for_meta_label(for_meta)
        0

    mut fn bind_for_element(for_node: i32, pat_or_sym: i32, item_place: i32, elem_ty: i32, body_expr: i32):
        // Bind loop variable: supports both simple identifiers and pattern destructuring
        if self.ast.for_binding_is_pattern(for_node):
            let _ = self.lower_pattern(pat_or_sym, item_place)
            return
        if pat_or_sym != 0:
            let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
            self.bind_local(pat_or_sym, bind_local)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, bind_local, 0, self.ast.get_start(body_expr))
            if self.sema.is_copy_frozen(elem_ty) == 0:
                self.schedule_drop(bind_local, DropKind.DK_VALUE)
            let bind_place = self.place_for_local(bind_local)
            let item_op = self.body.new_operand(OperandKind.OK_COPY, item_place)
            self.assign_operand_to_place(bind_place, item_op, self.ast.get_start(body_expr))

    mut fn bind_for_element_or_skip(for_node: i32, pat_or_sym: i32, item_place: i32, elem_ty: i32, body_expr: i32, continue_bb: i32):
        if self.ast.for_binding_is_pattern(for_node):
            let matched_bb = self.new_block()
            self.lower_pattern_match(item_place, pat_or_sym, matched_bb, continue_bb)
            self.switch_to(matched_bb)
            let _ = self.lower_pattern(pat_or_sym, item_place)
            return
        self.bind_for_element(for_node, pat_or_sym, item_place, elem_ty, body_expr)

    mut fn bind_comprehension_element(comp_node: i32, pat_or_sym: i32, item_place: i32, elem_ty: i32, span_node: i32):
        if self.ast.comprehension_binding_is_pattern(comp_node, pat_or_sym):
            let _ = self.lower_pattern(pat_or_sym, item_place)
            return
        if pat_or_sym != 0:
            let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
            self.bind_local(pat_or_sym, bind_local)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, bind_local, 0, self.ast.get_start(span_node))
            if self.sema.is_copy_frozen(elem_ty) == 0:
                self.schedule_drop(bind_local, DropKind.DK_VALUE)
            let bind_place = self.place_for_local(bind_local)
            let item_op = self.body.new_operand(OperandKind.OK_COPY, item_place)
            self.assign_operand_to_place(bind_place, item_op, self.ast.get_start(span_node))

    mut fn lower_comprehension_leaf(comp_node: i32, out_place: i32, out_elem_ty: i32):
        if self.ast.kind(comp_node) == NodeKind.NK_MAP_COMPREHENSION:
            let comp_start = self.ast.get_data0(comp_node)
            let key_expr = self.ast.get_extra(comp_start)
            let val_expr = self.ast.get_extra(comp_start + 1)
            let target_ty = self.expr_type(comp_node)
            let resolved = self.sema.resolve_alias(target_ty)
            var key_ty = 0
            var val_ty = out_elem_ty
            if self.sema.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST and self.sema.get_generic_inst_arg_count(resolved as i32) == 2:
                key_ty = self.sema.get_generic_inst_arg(resolved as i32, 0)
                val_ty = self.sema.get_generic_inst_arg(resolved as i32, 1)
            let saved_expected2 = self.expected_type
            if key_ty > 0:
                self.expected_type = key_ty
            let key_op = self.lower_expr(key_expr)
            if val_ty > 0:
                self.expected_type = val_ty
            else:
                self.expected_type = saved_expected2
            let val_op = self.lower_expr(val_expr)
            self.expected_type = saved_expected2
            let target_base = self.literal_target_base_sym(target_ty)
            if self.is_btreemap_base_sym(target_base) != 0:
                if self.btree_storage_vec_type(target_ty) == 0:
                    self.mark_unsupported()
                    return
                self.emit_btree_map_insert(out_place, key_op, val_op, key_expr)
                return
            self.emit_map_insert(out_place, key_op, val_op, 0, self.ast.get_start(key_expr))
            return

        let expr = self.ast.get_data0(comp_node)
        let saved_expected = self.expected_type
        if out_elem_ty > 0 and out_elem_ty != self.sema.ty_void:
            self.expected_type = out_elem_ty
        var elem_op = self.lower_expr(expr)
        self.expected_type = saved_expected
        // D33/#912: a bare by-value Drop binding as the result expr (only
        // reachable through consuming/generic iteration — views demand clone
        // at check) must MOVE into the output, and the move must be
        // REGISTERED (consume_moved_operand) so the per-iteration scope
        // drop's moved-skip and reset-on-move blank protect what the output
        // now owns. lower_expr may already produce the OK_MOVE (sema's owned
        // demand) without registering it — register either way.
        if out_elem_ty > 0 and self.sema.is_copy_frozen(out_elem_ty) == 0:
            if self.body.operand_kinds.get(elem_op as i64) == OperandKind.OK_COPY:
                elem_op = self.body.new_operand(OperandKind.OK_MOVE, self.body.operand_d0.get(elem_op as i64))
            if self.body.operand_kinds.get(elem_op as i64) == OperandKind.OK_MOVE:
                self.consume_moved_operand(elem_op)
        let comp_ty = self.expr_type(comp_node)
        let target_base = self.literal_target_base_sym(comp_ty)
        if self.is_btreeset_base_sym(target_base) != 0:
            if self.btree_storage_vec_type(comp_ty) == 0:
                self.mark_unsupported()
                return
            self.emit_btree_set_insert(out_place, elem_op, expr)
            return
        if target_base == self.sema.syms.hashset:
            let unit_op = self.unit_operand()
            self.emit_map_insert(out_place, elem_op, unit_op, 1, self.ast.get_start(expr))
        else:
            self.emit_vec_push(out_place, elem_op, self.ast.get_start(expr))

    fn comprehension_clause_start(comp_node: i32) -> i32:
        if self.ast.kind(comp_node) == NodeKind.NK_MAP_COMPREHENSION:
            return self.ast.get_data0(comp_node) + 2
        self.ast.get_data1(comp_node)

    fn comprehension_clause_count(comp_node: i32) -> i32:
        if self.ast.kind(comp_node) == NodeKind.NK_MAP_COMPREHENSION:
            return self.ast.get_data1(comp_node)
        self.ast.get_data2(comp_node)

    mut fn lower_comprehension_next_or_push(comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32):
        let clause_count = self.comprehension_clause_count(comp_node)
        if clause_index >= clause_count:
            self.lower_comprehension_leaf(comp_node, out_place, out_elem_ty)
            return
        self.lower_comprehension_clause(comp_node, clause_index, out_place, out_elem_ty)

    mut fn lower_comprehension_body(comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, continue_bb: i32):
        let comp_start = self.comprehension_clause_start(comp_node)
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

    mut fn lower_comprehension_range_var(comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, iter_expr: i32, range_ty: i32):
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

    mut fn lower_comprehension_range(comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, range_node: i32):
        let start_node = self.ast.get_data0(range_node)
        let end_node = self.ast.get_data1(range_node)
        let inclusive = self.ast.get_data2(range_node)
        let elem_ty = self.sema.infer_for_element_type_frozen(self.expr_type(range_node))

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

    mut fn lower_comprehension_slice(comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, iter_expr: i32):
        let iter_op = self.lower_expr(iter_expr)
        let iter_ty = self.expr_type(iter_expr)
        let elem_ty = self.sema.infer_for_element_type_frozen(iter_ty)
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

    mut fn lower_comprehension_vec(comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, iter_expr: i32):
        // #934: a comprehension iterates like a `for` (§13): a place receiver
        // is read through its own place — no header move, so the source Vec
        // stays valid afterwards — and Drop-class elements bind &T views read
        // by VEC_GET_REF (lower_for_iter_ref), Copy-class elements by value
        // (lower_for_vec). Materializing the receiver moved it out of its
        // binding, and VEC_GET copied a Drop-class element into a local typed
        // as a reference.
        let iter_ty = self.expr_type(iter_expr)
        let elem_ty = self.sema.infer_for_element_type_frozen(iter_ty)
        let ivk = self.ast.kind(iter_expr)
        var vec_place = 0
        if ivk == NodeKind.NK_IDENT or ivk == NodeKind.NK_FIELD_ACCESS or ivk == NodeKind.NK_INDEX:
            vec_place = self.lower_expr_place(iter_expr)
        else:
            let iter_op = self.lower_expr(iter_expr)
            vec_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))
        let elem_is_view = self.sema.get_type_kind(self.sema.resolve_alias(elem_ty)) == TypeKind.TY_REF

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
        if elem_is_view:
            self.emit_vec_get_ref_into(vec_place, counter_place, elem_place, self.ast.get_start(iter_expr))
        else:
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

    mut fn lower_comprehension_generic_iter(comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32, pat_or_sym: i32, iter_expr: i32, iter_ty: i32):
        // #912: sema recorded the concrete next() specialization keyed by
        // the clause's iterable expression node — dispatch exactly that.
        let next_sym = self.pool.intern("next")
        let recorded_mono = self.sema.iter_next_mono_syms.get(iter_expr)
        var recorded_mono_sym = 0
        if recorded_mono.is_some(): recorded_mono_sym = recorded_mono.unwrap()
        let recorded_sig = self.sema.iter_next_sigs.get(iter_expr)
        var recorded_sig_idx = -1
        if recorded_sig.is_some(): recorded_sig_idx = recorded_sig.unwrap()
        let callee_sym = if recorded_mono_sym != 0: recorded_mono_sym else: self.resolve_method_callee_sym(iter_expr, next_sym)
        if callee_sym == next_sym:
            self.mark_unsupported()
            return

        let iter_op = self.lower_expr(iter_expr)
        let iter_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))
        let elem_ty = self.sema.infer_for_element_type_frozen(iter_ty)

        let resolved_iter = self.sema.resolve_alias(iter_ty)
        let owner_sym = self.sema.method_owner_symbol_for_type(resolved_iter as i32)
        let sema_next_sym = self.sema.pool_lookup_symbol("next")
        var next_ret_ty = 0
        if recorded_sig_idx >= 0:
            next_ret_ty = self.sema.sig_return_type(recorded_sig_idx)
        if next_ret_ty == 0 and owner_sym != 0 and sema_next_sym > 0:
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
        if recorded_sig_idx >= 0:
            // Route through the generic-call contract so codegen lazily
            // emits the recorded next() specialization (#912).
            self.body.set_call_intrinsic(args_id, MirIntrinsic.GENERIC_CALL)
            self.body.set_call_ast_node(args_id, iter_expr)
            self.body.set_call_contract(args_id, recorded_sig_idx, recorded_mono_sym)
            self.body.require_call_contract(args_id)
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
        // Drop-class elements MOVE out of the Option temp (the `?` idiom) —
        // a copy leaves the stale Some to double-drop the payload at cleanup.
        let next_payload = self.body.new_operand(if self.sema.is_copy_frozen(elem_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, payload_place)
        self.assign_operand_to_place(item_place, next_payload, self.ast.get_start(iter_expr))
        // #614b + D33: the binding lives in a per-iteration scope so an
        // owned Drop element drops once on the back-edge — including
        // filter-skipped iterations — never again at function exit. All
        // paths join before the single pop, mirroring lower_comprehension_
        // body's filter shape with one shared continue edge.
        self.push_scope()
        self.bind_comprehension_element(comp_node, pat_or_sym, item_place, elem_ty, iter_expr)
        let clause_extra = self.comprehension_clause_start(comp_node)
        let clause_filter = self.ast.get_extra(clause_extra + clause_index * 3 + 2)
        let iter_join_bb = self.new_block()
        if clause_filter != 0:
            let pass_bb = self.new_block()
            let cond_op = self.lower_expr(clause_filter)
            let fvals: Vec[i32] = Vec.new()
            fvals.push(1)
            let ftargets: Vec[i32] = Vec.new()
            ftargets.push(pass_bb as i32)
            let ftable = self.body.new_switch_table(fvals, ftargets)
            self.terminate(TermKind.TK_SWITCH_INT, cond_op, ftable, iter_join_bb, 0)
            self.switch_to(pass_bb)
            // #771-style frame: the leaf push is a statement — its
            // reset-on-move flush is what blanks a moved-out binding so
            // the back-edge scope drop is inert for it.
            let pass_frame = self.push_stmt_temp_frame()
            self.lower_comprehension_next_or_push(comp_node, clause_index + 1, out_place, out_elem_ty)
            self.finish_stmt_temp_frame(pass_frame)
            self.terminate(TermKind.TK_GOTO, iter_join_bb, 0, 0, 0)
        else:
            let leaf_frame = self.push_stmt_temp_frame()
            self.lower_comprehension_next_or_push(comp_node, clause_index + 1, out_place, out_elem_ty)
            self.finish_stmt_temp_frame(leaf_frame)
            self.terminate(TermKind.TK_GOTO, iter_join_bb, 0, 0, 0)
        self.switch_to(iter_join_bb)
        self.pop_scope_with_goto(header_bb)

        self.switch_to(exit_bb)
        self.forget_string_flow_facts()

    mut fn lower_comprehension_clause(comp_node: i32, clause_index: i32, out_place: i32, out_elem_ty: i32):
        let comp_start = self.comprehension_clause_start(comp_node)
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

    mut fn lower_array_comprehension(comp_node: i32) -> i32:
        var out_ty = self.expr_type(comp_node)
        if out_ty == 0 or out_ty == self.sema.ty_void:
            self.mark_unsupported()
            return self.unit_operand()
        let out_base = self.literal_target_base_sym(out_ty)
        var elem_ty = 0
        let out_resolved = self.sema.resolve_alias(out_ty)
        if self.sema.get_type_kind(out_resolved) == TypeKind.TY_GENERIC_INST:
            if self.sema.get_generic_inst_arg_count(out_resolved as i32) > 0:
                elem_ty = self.sema.get_generic_inst_arg(out_resolved as i32, if self.ast.kind(comp_node) == NodeKind.NK_MAP_COMPREHENSION: 1 else: 0)
        if elem_ty == 0:
            elem_ty = self.sema.ty_i32 as i32

        var out_local = self.new_temp(out_ty)
        var out_place = self.place_for_local(out_local)
        if out_base == self.sema.syms.hashset or out_base == self.sema.syms.hashmap:
            self.emit_map_new_into(out_place, self.ast.get_start(comp_node))
        else if self.is_btreeset_base_sym(out_base) != 0 or self.is_btreemap_base_sym(out_base) != 0:
            if self.btree_storage_vec_type(out_ty) == 0:
                self.mark_unsupported()
                return self.unit_operand()
            self.emit_btree_new_into(out_place, out_ty, self.ast.get_start(comp_node))
        else:
            self.emit_vec_new_into(out_place, self.ast.get_start(comp_node))
        self.lower_comprehension_clause(comp_node, 0, out_place, elem_ty)

        if self.sema.is_copy_frozen(out_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, out_place)
        self.body.new_operand(OperandKind.OK_MOVE, out_place)

    mut fn lower_for_range_var(for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32, range_ty: i32) -> i32:
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
        self.bind_for_element_or_skip(for_node, pat_or_sym, counter_place, elem_ty, body_expr, inc_bb)
        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
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

    mut fn lower_for_range(for_node: i32, pat_or_sym: i32, range_node: i32, body_expr: i32) -> i32:
        // for i in start..end  →  counter = start; while counter < end: body; counter += 1
        let start_node = self.ast.get_data0(range_node)
        let end_node = self.ast.get_data1(range_node)
        let inclusive = self.ast.get_data2(range_node)
        let elem_ty = self.sema.infer_for_element_type_frozen(self.expr_type(range_node))

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
        self.bind_for_element_or_skip(for_node, pat_or_sym, counter_place, elem_ty, body_expr, inc_bb)

        // #614b: establish a per-iteration drop scope around the body and emit its
        // drops on the back-edge. A multi-statement body is an NK_BLOCK that pushes
        // its own scope, but a single-statement body (`for i in ...: let x = mk()`)
        // is a BARE statement — without this barrier its Drop locals register in the
        // enclosing function scope and fire once at exit instead of per iteration.
        self.push_scope()
        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
        self.pop_scope_with_goto(inc_bb)

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

    mut fn lower_for_slice(for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
        // for x in slice → index from 0 to len
        let iter_op = self.lower_expr(iter_expr)
        let iter_ty = self.expr_type(iter_expr)
        let elem_ty = self.sema.infer_for_element_type_frozen(iter_ty)

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
        self.bind_for_element_or_skip(for_node, pat_or_sym, elem_place, elem_ty, body_expr, inc_bb)

        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
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

    mut fn lower_for_vec(for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
        // for x in vec → counter loop using VEC_LEN / VEC_GET intrinsics.
        // §13: the implicit form borrows — a place receiver is read through
        // its own place (no header move; the collection stays valid after the
        // loop). Only rvalue receivers materialize an owning temp, which the
        // enclosing statement frame drops.
        let iter_ty = self.expr_type(iter_expr)
        let elem_ty = self.sema.infer_for_element_type_frozen(iter_ty)

        let ivk = self.ast.kind(iter_expr)
        var vec_place = 0
        if ivk == NodeKind.NK_IDENT or ivk == NodeKind.NK_FIELD_ACCESS or ivk == NodeKind.NK_INDEX:
            vec_place = self.lower_expr_place(iter_expr)
        else:
            let iter_op = self.lower_expr(iter_expr)
            vec_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))

        // Get length via VEC_LEN intrinsic (returns i64)
        let len_local = self.new_temp(self.sema.ty_i64)
        let len_place = self.place_for_local(len_local)
        let len_args: Vec[i32] = Vec.new()
        len_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
        let len_args_id = self.body.new_call_args(len_args)
        self.body.set_call_intrinsic(len_args_id, MirIntrinsic.VEC_LEN)
        let len_after_bb = self.new_block()
        let len_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, len_unit, len_args_id, len_place, len_after_bb)
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
        let get_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, get_unit, get_args_id, elem_place, get_after_bb)
        self.switch_to(get_after_bb)

        // Bind loop variable
        self.bind_for_element_or_skip(for_node, pat_or_sym, elem_place, elem_ty, body_expr, inc_bb)

        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
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

    mut fn lower_for_hashmap(for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
        // for (k, v) in map → materialize map.items() then use the normal Vec loop.
        let map_op = self.lower_expr(iter_expr)
        let map_ty = self.expr_type(iter_expr)
        let elem_ty = self.sema.infer_for_element_type_frozen(map_ty)
        let items_vec_ty = self.sema.find_vec_type_for(elem_ty)

        let map_place = self.materialize_operand(map_op, map_ty, self.ast.get_start(iter_expr))
        let items_local = self.new_temp(items_vec_ty)
        let items_place = self.place_for_local(items_local)
        let items_args: Vec[i32] = Vec.new()
        items_args.push(self.body.new_operand(OperandKind.OK_COPY, map_place))
        let items_args_id = self.body.new_call_args(items_args)
        self.body.set_call_intrinsic(items_args_id, MirIntrinsic.MAP_ITEMS)
        let items_after_bb = self.new_block()
        let items_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, items_unit, items_args_id, items_place, items_after_bb)
        self.switch_to(items_after_bb)

        let len_local = self.new_temp(self.sema.ty_i64)
        let len_place = self.place_for_local(len_local)
        let len_args: Vec[i32] = Vec.new()
        len_args.push(self.body.new_operand(OperandKind.OK_COPY, items_place))
        let len_args_id = self.body.new_call_args(len_args)
        self.body.set_call_intrinsic(len_args_id, MirIntrinsic.VEC_LEN)
        let len_after_bb = self.new_block()
        let len_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, len_unit, len_args_id, len_place, len_after_bb)
        self.switch_to(len_after_bb)

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
        let get_args: Vec[i32] = Vec.new()
        get_args.push(self.body.new_operand(OperandKind.OK_COPY, items_place))
        get_args.push(self.body.new_operand(OperandKind.OK_COPY, counter_place))
        let get_args_id = self.body.new_call_args(get_args)
        self.body.set_call_intrinsic(get_args_id, MirIntrinsic.VEC_GET)
        let get_after_bb = self.new_block()
        let get_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, get_unit, get_args_id, elem_place, get_after_bb)
        self.switch_to(get_after_bb)

        self.bind_for_element_or_skip(for_node, pat_or_sym, elem_place, elem_ty, body_expr, inc_bb)

        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
        self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

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

    mut fn lower_for_iter_place(for_node: i32, pat_or_sym: i32, vec_expr: i32, body_expr: i32) -> i32:
        let vec_op = self.lower_expr(vec_expr)
        let vec_ty = self.expr_type(vec_expr)
        let slot_ty = self.sema.infer_for_element_type_frozen(self.expr_type(self.ast.get_data1(for_node)))
        let vec_place = self.materialize_operand(vec_op, vec_ty, self.ast.get_start(vec_expr))
        let len_local = self.new_temp(self.sema.ty_i64)
        let len_place = self.place_for_local(len_local)
        let len_args: Vec[i32] = Vec.new()
        len_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
        let len_args_id = self.body.new_call_args(len_args)
        self.body.set_call_intrinsic(len_args_id, MirIntrinsic.VEC_LEN)
        let len_after_bb = self.new_block()
        let len_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, len_unit, len_args_id, len_place, len_after_bb)
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
        let slot_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, slot_unit, slot_args_id, slot_place, slot_after_bb)
        self.switch_to(slot_after_bb)
        self.bind_for_element_or_skip(for_node, pat_or_sym, slot_place, slot_ty, body_expr, inc_bb)
        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
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

    // D10 (decisions.md): `for msg in rx:` receives until the channel is
    // closed and drained — the loop desugars through recv() -> Option[T]:
    // loop { match rx.recv(): Some(msg) => body, None => break }.
    mut fn lower_for_receiver(for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
        let rx_op = self.lower_expr(iter_expr)
        let rx_ty = self.expr_type(iter_expr)
        let rx_place = self.materialize_operand(rx_op, rx_ty, self.ast.get_start(iter_expr))
        let elem_ty = self.sema.infer_for_element_type_frozen(self.expr_type(self.ast.get_data1(for_node)))
        let opt_ty = self.sema.find_generic_inst(self.sema.syms.option, elem_ty)
        if opt_ty == 0:
            with_eprint("error: for-over-Receiver missing Option[element] instantiation")
            self.mark_unsupported()
            return self.unit_operand()
        let header_bb = self.new_block()
        let bind_bb = self.new_block()
        let exit_bb = self.new_block()
        self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
        // continue = next receive (header); break = exit.
        self.push_control_target(self.for_label(for_node), ControlTargetKind.CT_LOOP, header_bb, exit_bb, -1)
        self.switch_to(header_bb)
        let opt_local = self.new_temp(opt_ty)
        let opt_place = self.place_for_local(opt_local)
        let recv_args: Vec[i32] = Vec.new()
        recv_args.push(self.body.new_operand(OperandKind.OK_COPY, rx_place))
        let recv_args_id = self.body.new_call_args(recv_args)
        self.body.set_call_intrinsic(recv_args_id, MirIntrinsic.CHAN_RECV)
        let recv_after_bb = self.new_block()
        let recv_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, recv_unit, recv_args_id, opt_place, recv_after_bb)
        self.switch_to(recv_after_bb)
        let disc = self.lower_enum_discriminant(opt_place)
        let some_disc = self.enum_variant_discriminant_for_type(opt_ty, self.sema.syms.some)
        let vals: Vec[i32] = Vec.new()
        vals.push(some_disc)
        let targets: Vec[i32] = Vec.new()
        targets.push(bind_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, disc, table, exit_bb, 0)
        self.switch_to(bind_bb)
        let some_index = self.enum_variant_index_for_type(opt_ty, self.sema.syms.some)
        let downcast_place = self.body.new_downcast_place(opt_place, some_index, opt_ty)
        let payload_place = self.body.new_field_place(downcast_place, 0, elem_ty)
        self.bind_for_element_or_skip(for_node, pat_or_sym, payload_place, elem_ty, body_expr, header_bb)
        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
        self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
        self.pop_control_target()
        self.switch_to(exit_bb)
        self.forget_string_flow_facts()
        self.unit_operand()

    mut fn lower_for_iter_ref(for_node: i32, pat_or_sym: i32, vec_expr: i32, body_expr: i32) -> i32:
        let vec_ty = self.expr_type(vec_expr)
        // #607: borrow-iteration. If the receiver is a place (local/field/index), read len
        // and element refs through that place directly — do NOT materialize a (drop-
        // scheduled) copy of the Vec header. For a Drop-element field/local that copy would
        // be a second live header and double-free the shared buffer at scope exit; iter_ref
        // only borrows (VEC_GET_REF), so the receiver keeps sole ownership. Non-place
        // receivers (e.g. a call result) get a genuine owning temp as before.
        let vk = self.ast.kind(vec_expr)
        var vec_place = 0
        if vk == NodeKind.NK_IDENT or vk == NodeKind.NK_FIELD_ACCESS or vk == NodeKind.NK_INDEX:
            vec_place = self.lower_expr_place(vec_expr)
        else:
            let vec_op = self.lower_expr(vec_expr)
            vec_place = self.materialize_operand(vec_op, vec_ty, self.ast.get_start(vec_expr))
        var resolved_vec = self.sema.resolve_alias(vec_ty)
        // A &Vec[T] receiver (ref-typed binding) reads through one deref.
        if self.sema.get_type_kind(resolved_vec) == TypeKind.TY_REF:
            vec_place = self.new_deref_place(vec_place)
            resolved_vec = self.sema.resolve_alias(self.sema.get_type_d0(resolved_vec))
        var ref_elem_ty = 0
        if self.sema.get_type_kind(resolved_vec) == TypeKind.TY_GENERIC_INST:
            let inner_ty = self.sema.get_generic_inst_arg(resolved_vec as i32, 0)
            ref_elem_ty = self.sema.find_exact_type(TypeKind.TY_REF, inner_ty, 0, 0) as i32
        if ref_elem_ty == 0:
            ref_elem_ty = self.sema.ty_i32 as i32
        let len_local = self.new_temp(self.sema.ty_i64)
        let len_place = self.place_for_local(len_local)
        let len_args: Vec[i32] = Vec.new()
        len_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
        let len_args_id = self.body.new_call_args(len_args)
        self.body.set_call_intrinsic(len_args_id, MirIntrinsic.VEC_LEN)
        let len_after_bb = self.new_block()
        let len_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, len_unit, len_args_id, len_place, len_after_bb)
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
        let ref_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, ref_unit, ref_args_id, ref_place, ref_after_bb)
        self.switch_to(ref_after_bb)
        self.bind_for_element_or_skip(for_node, pat_or_sym, ref_place, ref_elem_ty, body_expr, inc_bb)
        // #771 (the #729 loop shape): stmt temps created INSIDE the body must
        // drop inside the body, not at the loop exit — the zero-iteration path
        // reaches the exit without initializing them (freed stack garbage).
        let loop_body_temp_frame = self.push_stmt_temp_frame()
        let _ = self.lower_expr_discard(body_expr)
        self.finish_stmt_temp_frame(loop_body_temp_frame)
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

    mut fn lower_break(node: i32) -> i32:
        let loop_info = self.find_control_target(self.ast.get_data1(node), 0)
        if loop_info.break_bb < 0:
            return self.unit_operand()

        let value_expr = self.ast.get_data0(node)
        if value_expr != 0:
            let value_op = self.lower_expr(value_expr)
            if loop_info.result_place >= 0:
                self.assign_operand_to_place(loop_info.result_place, value_op, self.ast.get_start(value_expr))

        self.flush_stmt_temp_frame()
        self.emit_cleanup_to_target(loop_info)
        self.terminate(TermKind.TK_GOTO, loop_info.break_bb, 0, 0, 0)

        // Continue lowering in a fresh detached block to keep pass total.
        let after_break = self.new_block()
        self.switch_to(after_break)
        self.unit_operand()

    mut fn lower_continue(node: i32) -> i32:
        let loop_info = self.find_control_target(self.ast.get_data0(node), 1)
        if loop_info.continue_bb < 0:
            return self.unit_operand()

        self.flush_stmt_temp_frame()
        self.emit_cleanup_to_target(loop_info)
        self.terminate(TermKind.TK_GOTO, loop_info.continue_bb, 0, 0, 0)
        let after_continue = self.new_block()
        self.switch_to(after_continue)
        self.unit_operand()

    mut fn lower_goto(node: i32) -> i32:
        let label = self.ast.get_data0(node)
        let target = self.goto_target_info(label)
        if target.break_bb < 0:
            return self.unit_operand()
        self.flush_stmt_temp_frame()
        self.emit_cleanup_to_target(target)
        self.terminate(TermKind.TK_GOTO, target.break_bb, 0, 0, 0)
        let after_goto = self.new_block()
        self.switch_to(after_goto)
        self.unit_operand()

    mut fn lower_label(node: i32) -> i32:
        let label = self.ast.get_data0(node)
        let stmt = self.ast.get_data1(node)
        let _ = self.define_goto_label(label)
        if stmt == 0:
            return self.unit_operand()
        self.lower_expr(stmt)

    mut fn lower_return(node: i32) -> i32:
        let value_expr = self.ast.get_data0(node)
        let saved_expected = self.expected_type
        let ret_ty: i32 = self.body.local_type_ids.get(0)
        if ret_ty > 0:
            self.expected_type = ret_ty
        if value_expr != 0:
            self.cancel_scheduled_value_drop_for_receiver_expr(value_expr)
        let ret_op_raw = if value_expr != 0:
            self.lower_expr(value_expr)
        else if ret_ty > 0 and ret_ty != self.sema.ty_void as i32:
            // Bare `return` in a value-returning fn yields the implicit
            // default (spec: implicit default return) — a unit operand
            // into the typed ret slot fails the typed-MIR validator.
            self.lower_implicit_default_return(ret_ty, self.ast.get_start(node))
        else:
            self.unit_operand()
        let rr_adj = self.adjust_ret_operand_auto_ref(ret_op_raw, value_expr, ret_ty, self.ast.get_start(node))
        let ret_op = if rr_adj >= 0: rr_adj else: ret_op_raw
        self.expected_type = saved_expected
        let ret_place = self.place_for_local(0)
        self.assign_operand_to_place(ret_place, ret_op, self.ast.get_start(node))

        self.flush_stmt_temp_frame()
        self.emit_defers_for_return()
        self.emit_drops_for_return()
        self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

        // Keep lowering total by switching to an unreachable continuation block.
        let after_return = self.new_block()
        self.switch_to(after_return)
        self.unit_operand()

    // Await a single Task with cancellation checks and unwind-with-defers.
    // Returns the operand for the unwrapped result value.
    // task_op: MIR operand for the Task value
    // result_ty: sema type of the unwrapped result (T from Task[T])
    // task_ty: sema type of the Task value (Task[T])
    // node: AST node for the await expression (for span/ast_node)
    mut fn lower_single_await(task_op: i32, result_ty: i32, task_ty: i32, node: i32, await_owns: i32) -> i32:
        let span = self.ast.get_start(node)

        // 1. Emit FIBER_AWAIT intrinsic call. Arg 1 (await_owns) tells codegen whether
        // this value-await OWNS the result buffer and must free it (§14.7/G3): 1 for a
        // temporary/owned-local await, 0 for a borrowed param (the owner's drop frees).
        let await_args: Vec[i32] = Vec.new()
        await_args.push(task_op)
        await_args.push(self.const_operand(ConstKind.CK_INT, await_owns, self.sema.ty_i32))
        let await_args_id = self.body.new_call_args(await_args)
        self.body.set_call_intrinsic(await_args_id, MirIntrinsic.FIBER_AWAIT)
        self.body.set_call_ast_node(await_args_id, node)
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)
        let after_await = self.new_block()
        let await_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, await_unit, await_args_id, result_place, after_await)
        self.switch_to(after_await)

        // 2. Check self-cancellation: IS_CANCELLED() → i32
        let ic_args: Vec[i32] = Vec.new()
        let ic_args_id = self.body.new_call_args(ic_args)
        self.body.set_call_intrinsic(ic_args_id, MirIntrinsic.FIBER_IS_CANCELLED)
        let ic_result = self.new_temp(self.sema.ty_i32 as i32)
        let ic_place = self.place_for_local(ic_result)
        let check_self_bb = self.new_block()
        let ic_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, ic_unit, ic_args_id, ic_place, check_self_bb)
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
        let cancel_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, cancel_unit, cancel_call_id, cancel_result_place, after_cancel_bb)
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
        let wcr_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, wcr_unit, wcr_args_id, wcr_place, check_child_cont)
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
        let scr_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, scr_unit, scr_args_id, scr_place, after_scr)
        self.switch_to(after_scr)
        // D17: same early-exit flush as the `?` error path — moves already
        // executed must blank before the cancellation return.
        self.flush_pending_resets()
        self.emit_defers_for_return()
        self.emit_drops_for_return()
        self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

        // 6. Normal BB: continue with result
        self.switch_to(normal_bb)
        self.body.new_operand(OperandKind.OK_COPY, result_place)

    // Join a Task purely for cleanup: await completion and free its result buffer,
    // but do not propagate child-cancel status into the current fiber.
    mut fn lower_cleanup_await(task_op: i32, node: i32):
        let await_args: Vec[i32] = Vec.new()
        await_args.push(task_op)
        let await_args_id = self.body.new_call_args(await_args)
        self.body.set_call_intrinsic(await_args_id, MirIntrinsic.FIBER_CLEANUP_AWAIT)
        self.body.set_call_ast_node(await_args_id, node)
        let ignored_local = self.new_temp(self.sema.ty_void as i32)
        let ignored_place = self.place_for_local(ignored_local)
        let after_await_bb = self.new_block()
        let cleanup_unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, cleanup_unit, await_args_id, ignored_place, after_await_bb)
        self.switch_to(after_await_bb)

    mut fn lower_unreachable() -> i32:
        self.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)
        let dead_bb = self.new_block()
        self.switch_to(dead_bb)
        self.unit_operand()

    mut fn lower_enum_discriminant(place: i32) -> i32:
        let rv = self.body.new_rvalue(RvalueKind.RK_DISCRIMINANT, place, 0, 0)
        let disc_local = self.new_temp(self.sema.ty_i32)
        let disc_place = self.place_for_local(disc_local)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, disc_place, rv, 0)
        self.body.new_operand(OperandKind.OK_COPY, disc_place)

    mut fn lower_pattern_eq_operand(scrutinee_place: i32, value_op: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
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

    fn pattern_payload_node(owner_pat: i32, payload_entry: i32) -> i32:
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

    mut fn positional_struct_pattern_type(pat_node: i32, scrutinee_place: i32) -> i32:
        if pat_node == 0 or self.ast.kind(pat_node) != NodeKind.NK_PAT_VARIANT:
            return 0
        let type_name_sym = self.ast.get_data0(pat_node)
        if type_name_sym == 0:
            return 0
        let named_tid = self.sema.lookup_named_type_ambient(type_name_sym)
        if named_tid == 0:
            return 0
        if self.sema.get_type_kind(self.sema.resolve_alias(named_tid as TypeId)) != TypeKind.TY_STRUCT:
            return 0
        let subject_place = self.pattern_shape_place(scrutinee_place)
        let subject_ty = self.place_local_type(subject_place)
        let subject_resolved = self.sema.resolve_alias(subject_ty as TypeId)
        let subject_kind = self.sema.get_type_kind(subject_resolved)
        if subject_kind == TypeKind.TY_STRUCT and self.sema.get_type_d0(subject_resolved) == type_name_sym:
            return subject_resolved as i32
        if subject_kind == TypeKind.TY_GENERIC_INST and self.sema.get_type_d0(subject_resolved) == type_name_sym:
            return subject_resolved as i32
        0

    mut fn pattern_subject_ref_mutability(place: i32) -> i32:
        let ty = self.place_local_type(place)
        if ty == 0:
            return -1
        let resolved = self.sema.resolve_alias(ty as TypeId)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_REF:
            return -1
        self.sema.get_type_d1(resolved)

    mut fn pattern_shape_place(place: i32) -> i32:
        if self.pattern_subject_ref_mutability(place) >= 0:
            return self.new_deref_place(place)
        place

    mut fn pattern_child_subject_place(parent_place: i32, child_place: i32, span: i32) -> i32:
        let ref_mut = self.pattern_subject_ref_mutability(parent_place)
        if ref_mut < 0:
            return child_place
        let child_ty = self.place_local_type(child_place)
        if child_ty == 0 or child_ty == self.sema.ty_void as i32:
            return child_place
        let ref_ty = self.sema.find_exact_type(TypeKind.TY_REF, child_ty, ref_mut, 0) as i32
        let borrow_kind = if ref_mut != 0: BorrowKind.EXCLUSIVE else: BorrowKind.SHARED
        let ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, borrow_kind, child_place, 0)
        let ref_local = self.new_temp(ref_ty)
        let ref_place = self.place_for_local(ref_local)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, ref_place, ref_rv, span)
        ref_place

    mut fn lower_regex_pattern_match(scrutinee_place: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
        let regex_ty = self.sema.lookup_named_type_ambient(self.sema.syms.regex)
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

    mut fn lower_pattern_match(scrutinee_place: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
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
                let alt_fail: BlockId = if pi + 1 < p_count: self.new_block() else: fail_bb as BlockId
                self.switch_to(next_test_bb)
                self.lower_pattern_match(scrutinee_place, alt_pat, arm_bb, alt_fail)
                next_test_bb = alt_fail
            return

        if pk == NodeKind.NK_PAT_VARIANT:
            let struct_ty = self.positional_struct_pattern_type(pat_node, scrutinee_place)
            if struct_ty != 0:
                let bind_start = self.ast.get_data1(pat_node)
                let bind_count = self.ast.get_data2(pat_node)
                let struct_subject_place = self.pattern_shape_place(scrutinee_place)
                var cur_test_bb = self.cur_bb
                for bi in 0..bind_count:
                    let inner_pat = self.ast.get_extra(bind_start + bi)
                    let inner_pk = self.ast.kind(inner_pat)
                    if inner_pk == NodeKind.NK_PAT_WILDCARD or inner_pk == NodeKind.NK_PAT_IDENT or inner_pk == NodeKind.NK_PAT_REST:
                        continue
                    let field_name = self.sema.type_reflection_field_name(struct_ty, bi)
                    let field_ty = self.sema.type_reflection_field_type_frozen(struct_ty, bi)
                    let field_place = self.body.new_field_place(struct_subject_place, field_name, field_ty)
                    let child_place = self.pattern_child_subject_place(scrutinee_place, field_place, self.ast.get_start(pat_node))
                    let next_test_bb = self.new_block()
                    self.switch_to(cur_test_bb)
                    self.lower_pattern_match(child_place, inner_pat, next_test_bb, fail_bb)
                    cur_test_bb = next_test_bb
                self.switch_to(cur_test_bb)
                self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
                return

        if pk == NodeKind.NK_PAT_VARIANT or pk == NodeKind.NK_PAT_ENUM_SHORTHAND:
            let variant_subject_place = self.pattern_shape_place(scrutinee_place)
            if self.sema.pattern_value_syms.contains(pat_node):
                let value_sym: i32 = self.sema.pattern_value_syms.get(pat_node).unwrap()
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
                self.switch_to(cur_test_bb as BlockId)
                self.lower_pattern_match(field_place, inner_pat, next_test_bb, fail_bb)
                cur_test_bb = next_test_bb as i32
            self.switch_to(cur_test_bb as BlockId)
            self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
            return

        if pk == NodeKind.NK_PAT_REGEX:
            let regex_subject_place = self.pattern_shape_place(scrutinee_place)
            self.lower_regex_pattern_match(regex_subject_place, pat_node, arm_bb, fail_bb)
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
            // #631: the unit pattern () is irrefutable against a unit subject —
            // always take the arm, no test needed.
            if tup_count == 0:
                self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
                return
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
                let elem_ty: i32 = self.sema.type_extra.get((elem_start + ti) as i64)
                let elem_place = self.body.new_tuple_index_place(tuple_subject_place, ti, elem_ty)
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
            let sp_tail_count = self.ast.get_extra(sp_extra + 1 + sp_head)
            // Get array length from scrutinee sema type
            let sp_arr_ty = self.place_local_type(scrutinee_place)
            let sp_arr_tk = self.sema.get_type_kind(sp_arr_ty)
            if sp_arr_tk == TypeKind.TY_ARRAY:
                let sp_arr_len = self.sema.get_type_d1(sp_arr_ty)
                if sp_has_rest != 0:
                    // [a, b, ..rest, z] matches if there is room for both ends.
                    if sp_arr_len >= sp_head + sp_tail_count:
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

    mut fn lower_pattern(pat_node: i32, scrutinee_place: i32) -> Vec[i32]:
        let out: Vec[i32] = Vec.new()
        if pat_node == 0:
            return out

        let pk = self.ast.kind(pat_node)
        if pk == NodeKind.NK_PAT_WILDCARD:
            // A7 (#606): in a consuming pattern context `_` receives ownership of
            // the value it discards — the destructure/match consume cancels (or
            // partially degrades) the subject's drop, so an unbound Drop value
            // would leak. Move it into an anonymous local that drops at scope
            // exit, mirroring the NK_PAT_IDENT binding path. Borrowed subjects
            // surface here as ref-typed places (no value drop) and are untouched.
            let wc_ty = self.place_local_type(scrutinee_place)
            if self.type_needs_value_drop(wc_ty) != 0:
                let wc_local = self.body.new_local(wc_ty, 0, 0, 1)
                self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, wc_local, 0, self.ast.get_start(pat_node))
                self.schedule_drop(wc_local, DropKind.DK_VALUE)
                let wc_op = self.body.new_operand(OperandKind.OK_MOVE, scrutinee_place)
                let wc_place = self.place_for_local(wc_local)
                self.assign_operand_to_place(wc_place, wc_op, self.ast.get_start(pat_node))
            return out

        if pk == NodeKind.NK_PAT_IDENT:
            let sym = self.ast.get_data0(pat_node)
            let bind_ty = self.place_local_type(scrutinee_place)
            let local_id = self.body.new_local(bind_ty, 0, sym, 1)
            self.bind_local(sym, local_id)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
            if self.type_needs_value_drop(bind_ty) != 0:
                self.schedule_drop(local_id, DropKind.DK_VALUE)
            let src_op = self.body.new_operand(if self.type_needs_value_drop(bind_ty) == 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, scrutinee_place)
            let local_place = self.place_for_local(local_id)
            self.assign_operand_to_place(local_place, src_op, self.ast.get_start(pat_node))
            out.push(local_id)
            out.push(scrutinee_place)
            return out

        if pk == NodeKind.NK_PAT_AT_BINDING:
            let outer_sym = self.ast.get_data0(pat_node)
            let outer_ty = self.place_local_type(scrutinee_place)
            let outer_local = self.body.new_local(outer_ty, 0, outer_sym, 1)
            self.bind_local(outer_sym, outer_local)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, outer_local, 0, self.ast.get_start(pat_node))
            if self.type_needs_value_drop(outer_ty) != 0:
                self.schedule_drop(outer_local, DropKind.DK_VALUE)
            let outer_op = self.body.new_operand(if self.type_needs_value_drop(outer_ty) == 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, scrutinee_place)
            let outer_place = self.place_for_local(outer_local)
            self.assign_operand_to_place(outer_place, outer_op, self.ast.get_start(pat_node))
            out.push(outer_local)
            out.push(scrutinee_place)
            let inner = self.lower_pattern(self.ast.get_data1(pat_node), scrutinee_place)
            for i in 0..inner.len() as i32:
                out.push(inner.get(i as i64))
            return out

        if pk == NodeKind.NK_PAT_VARIANT:
            let struct_ty = self.positional_struct_pattern_type(pat_node, scrutinee_place)
            if struct_ty != 0:
                let bind_start = self.ast.get_data1(pat_node)
                let bind_count = self.ast.get_data2(pat_node)
                let struct_subject_place = self.pattern_shape_place(scrutinee_place)
                for bi in 0..bind_count:
                    let inner_pat = self.ast.get_extra(bind_start + bi)
                    if inner_pat != 0 and self.ast.kind(inner_pat) == NodeKind.NK_PAT_REST:
                        continue
                    let field_name = self.sema.type_reflection_field_name(struct_ty, bi)
                    let field_ty = self.sema.type_reflection_field_type_frozen(struct_ty, bi)
                    let field_place = self.body.new_field_place(struct_subject_place, field_name, field_ty)
                    let child_place = self.pattern_child_subject_place(scrutinee_place, field_place, self.ast.get_start(pat_node))
                    let inner = self.lower_pattern(inner_pat, child_place)
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
                    // A7 (#606): `..` discards the remaining payload fields of the
                    // consumed variant; move each Drop one into an anonymous
                    // drop-scheduled local (same obligation as `_`). By-value
                    // subjects only — a borrowed subject keeps ownership.
                    if self.pattern_subject_ref_mutability(scrutinee_place) < 0:
                        let rest_enum_ty = self.place_local_type(variant_subject_place)
                        let rest_payloads = self.sema.enum_variant_payload_types_frozen(rest_enum_ty, variant_sym)
                        var rpi = bi
                        while rpi < rest_payloads.len() as i32:
                            let rp_ty = rest_payloads.get(rpi as i64)
                            if self.type_needs_value_drop(rp_ty) != 0:
                                let rp_place = self.body.new_field_place(variant_place, rpi, rp_ty)
                                let rp_local = self.body.new_local(rp_ty, 0, 0, 1)
                                self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, rp_local, 0, self.ast.get_start(pat_node))
                                self.schedule_drop(rp_local, DropKind.DK_VALUE)
                                let rp_local_place = self.place_for_local(rp_local)
                                let rp_op = self.body.new_operand(OperandKind.OK_MOVE, rp_place)
                                self.assign_operand_to_place(rp_local_place, rp_op, self.ast.get_start(pat_node))
                            rpi = rpi + 1
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
                if self.sema.is_copy_frozen(bind_ty) == 0:
                    self.schedule_drop(local_id, DropKind.DK_VALUE)
                let src_op = self.body.new_operand(if self.sema.is_copy_frozen(bind_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, child_place)
                let local_place = self.place_for_local(local_id)
                self.assign_operand_to_place(local_place, src_op, self.ast.get_start(pat_node))
                out.push(local_id)
                out.push(child_place)
            return out

        if pk == NodeKind.NK_PAT_TUPLE:
            let t_start = self.ast.get_data0(pat_node)
            let t_count = self.ast.get_data1(pat_node)
            let tuple_subject_place = self.pattern_shape_place(scrutinee_place)
            let tuple_bind_scrut_ty = self.place_local_type(tuple_subject_place)
            let tuple_bind_scrut_resolved = self.sema.resolve_alias(tuple_bind_scrut_ty)
            // #631: the unit pattern () binds nothing.
            if t_count == 0:
                return out
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
                let elem_ty: i32 = self.sema.type_extra.get((elem_start + ti) as i64)
                let field_place = self.body.new_tuple_index_place(tuple_subject_place, ti, elem_ty)
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
                    if self.sema.is_copy_frozen(bind_ty) == 0:
                        self.schedule_drop(local_id, DropKind.DK_VALUE)
                    let src_op = self.body.new_operand(if self.sema.is_copy_frozen(bind_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, child_place)
                    let local_place = self.place_for_local(local_id)
                    self.assign_operand_to_place(local_place, src_op, self.ast.get_start(pat_node))
                    out.push(local_id)
                    out.push(child_place)
            // A7 (#606): `..` discards every unmentioned field. In a consuming
            // (by-value) destructure the pattern owns those fields, so any Drop
            // field among them must move into an anonymous drop-scheduled local
            // or it leaks — same obligation as the `_` wildcard above. Borrowed
            // subjects keep ownership with the referent; skip them.
            if self.ast.get_extra(s_start) != 0 and self.pattern_subject_ref_mutability(scrutinee_place) < 0:
                let rest_subject_ty = self.sema.resolve_alias(self.place_local_type(struct_subject_place) as TypeId) as i32
                let rest_field_count = self.sema.type_reflection_field_count(rest_subject_ty)
                for fi in 0..rest_field_count:
                    let rest_fname = self.sema.type_reflection_field_name(rest_subject_ty, fi)
                    var rest_mentioned = 0
                    for si in 0..s_count:
                        if self.ast.get_extra(s_start + 1 + si * 2) == rest_fname:
                            rest_mentioned = 1
                    if rest_mentioned != 0:
                        continue
                    let rest_fty = self.sema.type_reflection_field_type_frozen(rest_subject_ty, fi)
                    if self.type_needs_value_drop(rest_fty) == 0:
                        continue
                    let rest_fplace = self.body.new_field_place(struct_subject_place, rest_fname, rest_fty)
                    let rest_local = self.body.new_local(rest_fty, 0, 0, 1)
                    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, rest_local, 0, self.ast.get_start(pat_node))
                    self.schedule_drop(rest_local, DropKind.DK_VALUE)
                    let rest_op = self.body.new_operand(OperandKind.OK_MOVE, rest_fplace)
                    let rest_place = self.place_for_local(rest_local)
                    self.assign_operand_to_place(rest_place, rest_op, self.ast.get_start(pat_node))
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
                let src_op = self.body.new_operand(if self.sema.is_copy_frozen(sp_elem_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, field_place)
                let local_place = self.place_for_local(local_id)
                self.assign_operand_to_place(local_place, src_op, self.ast.get_start(pat_node))
                out.push(local_id)
                out.push(field_place)
            let sp_tail_count = self.ast.get_extra(sp_extra + 1 + sp_head_count)
            let sp_has_rest = self.ast.get_extra(sp_extra)
            let rest_sym = self.ast.get_data2(pat_node)
            if sp_has_rest != 0 and rest_sym != 0 and sp_arr_tk == TypeKind.TY_ARRAY:
                let rest_count = sp_arr_len - sp_head_count - sp_tail_count
                let local_id = self.body.new_local(self.sema.ty_i64 as i32, 0, rest_sym, 1)
                self.bind_local(rest_sym, local_id)
                self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
                let count_op = self.int_const_operand(rest_count as i64, self.sema.ty_i64)
                let local_place = self.place_for_local(local_id)
                self.assign_operand_to_place(local_place, count_op, self.ast.get_start(pat_node))
                out.push(local_id)
            // Bind tail variables (from the end of the array)
            for ti in 0..sp_tail_count:
                let sym = self.ast.get_extra(sp_extra + 2 + sp_head_count + ti)
                if sym == 0:
                    continue
                let field_idx = sp_arr_len - sp_tail_count + ti
                let field_place = self.body.new_field_place(scrutinee_place, field_idx, 0)
                let local_id = self.body.new_local(sp_elem_ty, 0, sym, 1)
                self.bind_local(sym, local_id)
                self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
                let src_op = self.body.new_operand(if self.sema.is_copy_frozen(sp_elem_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, field_place)
                let local_place = self.place_for_local(local_id)
                self.assign_operand_to_place(local_place, src_op, self.ast.get_start(pat_node))
                out.push(local_id)
                out.push(field_place)
            return out

        out

    // TODO(D22): pattern binding is structural projection, never an implicit
    // owned-value demand. Preserve an Option[&V] payload as &V in every
    // instantiation, and materialize Copy only at a later recorded demand.
    // Join lowering must consume the one Sema-resolved D22 join decision.
    mut fn lower_match(scrutinee_expr: i32, arms_start: i32, arms_count: i32, node: i32, want_result: i32) -> i32:
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
        let result_is_void = if want_result == 0 or result_ty == 0 or result_ty == self.sema.ty_void as i32: 1 else: 0
        var result_place = -1
        if result_is_void == 0:
            let result_local = self.new_temp(result_ty)
            result_place = self.place_for_local(result_local)
        let join_bb = self.new_block()

        // Runtime drop flags for whole-value Drop moves out of match arms (mirrors
        // lower_if). Create a flag per active whole-value drop obligation at the
        // match entry; an arm that moves the value clears its flag, and the value's
        // scope-exit cleanup drops it only when the flag is still set. Each arm is
        // analyzed from the entry move-state, restored after each arm below.
        let match_entry_bb = self.cur_bb as i32
        let branch_drop_depth = self.drop_local_ids.len() as i32
        let branch_move_state = self.save_move_state()
        let pending_reset_start = self.pending_reset_locals.len() as i32
        let pending_reset_field_start = self.pending_reset_field_places.len() as i32
        let pending_move_temp_start = self.pending_move_temp_locals.len() as i32

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
            // Scope the arm's pattern bindings: a binding (e.g. `Ok(b)`) must only
            // be dropped on the path that actually bound it. Without this, the
            // binding's drop is scheduled in the enclosing scope and runs on every
            // path leaving the match — dropping uninitialized garbage when a
            // different arm was taken (memory corruption for Drop-typed payloads).
            self.push_scope()
            let _ = self.lower_pattern(pat_node, scrutinee_place)
            self.field_move_in_branch = self.field_move_in_branch + 1

            if guard_node != 0:
                // A temp created by the guard exists only on this arm's dispatch
                // path; frame it like the arm body below so it never reaches the
                // enclosing statement frame (which drops at the match's join).
                let guard_temp_frame = self.push_stmt_temp_frame()
                let guard_op = self.lower_expr(guard_node)
                self.finish_stmt_temp_frame(guard_temp_frame)
                let guard_pass_bb = self.new_block()
                let guard_fail_bb = self.new_block()
                let vals: Vec[i32] = Vec.new()
                vals.push(1)
                let targets: Vec[i32] = Vec.new()
                targets.push(guard_pass_bb as i32)
                let table = self.body.new_switch_table(vals, targets)
                self.terminate(TermKind.TK_SWITCH_INT, guard_op, table, guard_fail_bb, 0)
                // Guard failed: the pattern already bound this arm's variables, so
                // drop them before falling through to the next arm (without popping
                // the scope — that happens once on the guard-pass path below).
                self.switch_to(guard_fail_bb)
                let gscope_idx = self.drop_scope_starts.len() as i32 - 1
                let gdrop_start: i32 = self.drop_scope_starts.get(gscope_idx as i64)
                self.emit_drops_for_range(gdrop_start, self.drop_local_ids.len() as i32)
                self.terminate(TermKind.TK_GOTO, fail_bb, 0, 0, 0)
                self.switch_to(guard_pass_bb)

            // The arm body is its own temporary scope (like lower_if's branches
            // after #729): a temp created inside the arm — a call result, or a
            // default-argument value such as assert's message — exists only on
            // this arm's path. Left in the enclosing statement frame, its drop
            // landed at the match's join (here: the function's exit block) and
            // every other arm's path freed uninitialized stack garbage. A temp
            // moved into the arm result is cancelled by assign_operand_to_place
            // before the frame closes.
            let arm_temp_frame = self.push_stmt_temp_frame()
            if result_is_void != 0:
                let _ = self.lower_expr_discard(body_node)
            else:
                let saved_arm_expected = self.expected_type
                if result_ty != 0:
                    self.expected_type = result_ty
                let arm_value = self.lower_expr(body_node)
                self.expected_type = saved_arm_expected
                // A diverging arm has no value to contribute to the join. Like
                // lower_if, lower_return leaves Unit in its unreachable
                // continuation; assigning that placeholder to the match result
                // corrupts typed MIR when the result type is non-Unit.
                if self.sema.body_can_fall_through(body_node) != 0:
                    self.assign_operand_to_place(result_place, arm_value, self.ast.get_start(body_node))
            self.finish_stmt_temp_frame(arm_temp_frame)
            // Reset-on-move (spec §2.5.1): flush this arm's pending source-resets
            // inside the arm, before it merges to the join (same reason as lower_if).
            self.flush_pending_resets_since(pending_reset_start, pending_reset_field_start, pending_move_temp_start)
            self.field_move_in_branch = self.field_move_in_branch - 1
            self.pop_scope_with_goto(join_bb)
            self.restore_move_state(&branch_move_state)

            dispatch_bb = fail_bb

        // #605/#606: the match takes ownership of its subject; arms move payloads out
        // of the materialized scrutinee. Consume the scrutinee copy and a named source
        // so the enum's variant-aware payload drop does not double-free the moved-out
        // bindings. Wildcard / unbound / ref-bound payloads then leak rather than
        // double-free — sound; precise per-variant tracking is a follow-up.
        let match_scrut_local = mir_place_plain_local(&self.body, scrutinee_place)
        if match_scrut_local >= 0:
            self.cancel_stmt_temp_for_local(match_scrut_local)
            self.cancel_scheduled_value_drop_for_local(match_scrut_local)
            self.mark_local_value_moved(match_scrut_local)
        self.cancel_scheduled_value_drop_for_receiver_expr(scrutinee_expr)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        if result_is_void != 0:
            return self.unit_operand()
        if self.sema.is_copy_frozen(result_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn record_call_contract(args_id: i32, node: i32, fallback_sig: i32):
        var sig_idx = fallback_sig
        var mono_sym = 0
        let recorded_sig = self.sema.resolved_call_sigs.get(node)
        let recorded_mono = self.sema.resolved_call_mono_syms.get(node)
        if recorded_sig.is_some():
            sig_idx = recorded_sig.unwrap()
        if recorded_mono.is_some():
            mono_sym = recorded_mono.unwrap()
        else if sig_idx >= 0:
            mono_sym = self.sema.sig_names.get(sig_idx as i64)
        self.body.set_call_contract(args_id, sig_idx, mono_sym)

    mut fn lower_call(fn_expr: i32, arg_exprs_start: i32, arg_exprs_count: i32, ret_type_id: i32, node: i32) -> i32:
        let fn_op = self.lower_expr(fn_expr)
        var sig_idx = self.call_sig_for_expr(fn_expr)
        let recorded_sig = self.sema.resolved_call_sigs.get(node)
        if recorded_sig.is_some():
            sig_idx = recorded_sig.unwrap()
        let callable_fn_tid = if sig_idx >= 0: 0 else: self.callable_fn_type_for_expr(fn_expr)
        var actual_ret_type_id = ret_type_id
        if (actual_ret_type_id == 0 or actual_ret_type_id == self.sema.ty_void as i32) and sig_idx >= 0:
            let sig_ret = self.sema.sig_return_type(sig_idx)
            if sig_ret != 0:
                actual_ret_type_id = sig_ret
        // #747: the resolved callee symbol feeds lower_call_arg's extern
        // bit-copy rule (a call not in comp_resolved lowers conservatively).
        let bc_resolved = self.sema.comp_resolved.get(node)
        let bc_callee_sym: i32 = if bc_resolved.is_some(): bc_resolved.unwrap() else: 0

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
                        args.push(self.lower_call_arg(arg_node, sig_idx, callable_fn_tid, i, bc_callee_sym))
                else:
                    args.push(self.unit_operand())
        else:
            for i in 0..arg_exprs_count:
                let arg_node = self.ast.get_extra(arg_exprs_start + i)
                args.push(self.lower_call_arg(arg_node, sig_idx, callable_fn_tid, i, bc_callee_sym))

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
        self.record_call_contract(args_id, node, sig_idx)
        // #933: a call whose result has no type is a Sema hole, not a unit
        // value — lowering it as unit once aggregated a void payload into an
        // Option and trapped LLVM. Fail here, naming the call.
        if actual_ret_type_id == 0:
            sema_phase_bug(f"BUG: call result has no type: node={node} sig={sig_idx} callee={bc_callee_sym}")
        let result_local = self.new_temp(actual_ret_type_id)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()

        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.register_stmt_temp(result_local, actual_ret_type_id)

        if self.sema.is_copy_frozen(actual_ret_type_id) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    // Callable type redirect: like lower_call but uses a pre-resolved fn operand and symbol.
    mut fn lower_call_redirected(fn_op: i32, fn_sym: i32, arg_exprs_start: i32, arg_exprs_count: i32, ret_type_id: i32, node: i32) -> i32:
        var sig_idx = self.call_sig_for_sym(fn_sym)
        let recorded_sig = self.sema.resolved_call_sigs.get(node)
        if recorded_sig.is_some():
            sig_idx = recorded_sig.unwrap()
        var actual_ret_type_id = ret_type_id
        if (actual_ret_type_id == 0 or actual_ret_type_id == self.sema.ty_void as i32) and sig_idx >= 0:
            let sig_ret = self.sema.sig_return_type(sig_idx)
            if sig_ret != 0:
                actual_ret_type_id = sig_ret
        let args: Vec[i32] = Vec.new()
        for i in 0..arg_exprs_count:
            let arg_node = self.ast.get_extra(arg_exprs_start + i)
            args.push(self.lower_call_arg(arg_node, sig_idx, 0, i, fn_sym))
        let args_id = self.body.new_call_args(args)
        self.body.set_call_ast_node(args_id, node)
        self.record_call_contract(args_id, node, sig_idx)
        if self.sym_is_generic_fn(fn_sym):
            self.body.set_call_intrinsic(args_id, MirIntrinsic.GENERIC_CALL)
            self.require_generic_call_contract(args_id, fn_sym, 0, 0, recorded_sig.is_some(), "redirect")
        let result_local = self.new_temp(actual_ret_type_id)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.register_stmt_temp(result_local, actual_ret_type_id)
        if self.sema.is_copy_frozen(actual_ret_type_id) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    // Like lower_call but takes arg node indices in a Vec instead of reading from
    // pool.extra. This avoids mutating the shared AstPool (which would trigger
    // Vec realloc and invalidate other copies' pointers — use-after-free).
    mut fn lower_call_with_arg_nodes(fn_op: i32, callee_sym: i32, arg_node_vec: &Vec[i32], ret_type_id: i32, node: i32) -> i32:
        self.lower_call_with_arg_nodes_recv(fn_op, callee_sym, -1, arg_node_vec, ret_type_id, node)

    // Variant taking a pre-lowered receiver operand (recv_op >= 0): used by the
    // non-generic method path for `mut self` callees, where the receiver must be
    // an OK_COPY borrow of the caller's place rather than an OK_MOVE consumed
    // argument (§9.5/#641a). Remaining arg nodes shift to sig positions 1..n.
    mut fn lower_call_with_arg_nodes_recv(fn_op: i32, callee_sym: i32, recv_op: i32, arg_node_vec: &Vec[i32], ret_type_id: i32, node: i32) -> i32:
        var sig_idx = self.call_sig_for_sym(callee_sym)
        let recorded_sig = self.sema.resolved_call_sigs.get(node)
        if recorded_sig.is_some():
            sig_idx = recorded_sig.unwrap()
        var actual_ret_type_id = ret_type_id
        if (actual_ret_type_id == 0 or actual_ret_type_id == self.sema.ty_void as i32) and sig_idx >= 0:
            let sig_ret = self.sema.sig_return_type(sig_idx)
            if sig_ret != 0:
                actual_ret_type_id = sig_ret
        let args: Vec[i32] = Vec.new()
        var arg_pos = 0
        if recv_op >= 0:
            args.push(recv_op)
            arg_pos = 1
        for i in 0..arg_node_vec.len() as i32:
            let arg_node = arg_node_vec.get(i as i64)
            if arg_node < 0:
                args.push(self.lower_var(0 - arg_node, 0, 0))
            else:
                args.push(self.lower_call_arg(arg_node, sig_idx, 0, i + arg_pos, callee_sym))
        let args_id = self.body.new_call_args(args)
        self.body.set_call_ast_node(args_id, node)
        self.record_call_contract(args_id, node, sig_idx)
        if self.sym_is_generic_fn(callee_sym):
            self.body.set_call_intrinsic(args_id, MirIntrinsic.GENERIC_CALL)
            self.require_generic_call_contract(args_id, callee_sym, 0, 0, recorded_sig.is_some(), "arg-nodes")
        let result_local = self.new_temp(actual_ret_type_id)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.register_stmt_temp(result_local, actual_ret_type_id)
        if self.sema.is_copy_frozen(actual_ret_type_id) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_std_drop_call(node: i32) -> i32:
        let args_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        if arg_count != 1:
            return self.unit_operand()
        let arg_node = self.ast.get_extra(args_start)
        self.lower_drop_glue_and_consume(arg_node, "std.drop", node)

    // §2.4/#641b: an explicit destructor call is identical to the scope-exit drop,
    // just earlier — the same StmtKind.Drop glue (guarded user drop + field glue +
    // drop_consumed_field skips), then the binding is consumed via the move
    // discipline (moved-mark + reset-on-move) so the scope-exit drop guard-skips
    // and a later reassign re-arms cleanly.
    mut fn lower_drop_glue_and_consume(recv_node: i32, origin: &str, node: i32) -> i32:
        let place = self.lower_expr_place(recv_node)
        // #747 instance F: capture live views BEFORE the drop destroys the
        // storage — consume_moved_operand's own capture would clone freed
        // bytes here. It finds the aliases already dead-named and is a no-op.
        let drop_local = mir_place_plain_local(&self.body, place)
        if drop_local >= 0:
            self.materialize_str_views_of_consumed_base(drop_local)
        self.emit_drop_stmt(place, origin, self.ast.get_start(recv_node))
        let mv = self.body.new_operand(OperandKind.OK_MOVE, place)
        self.consume_moved_operand(mv)
        self.unit_operand()

    fn call_sig_for_sym(sym: i32) -> i32:
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

    fn sym_is_generic_fn(sym: i32) -> bool:
        if sym == 0:
            return false
        if self.call_sig_for_sym(sym) >= 0:
            return false
        if self.sema.generic_fn_node_for_symbol(sym) != 0:
            return true
        let name = self.pool.resolve_symbol(sym)
        if name.len() == 0:
            return false
        let sema_sym = self.sema.pool_lookup_symbol(name)
        sema_sym != 0 and self.sema.get_sig(sema_sym) < 0 and self.sema.generic_fn_node_for_symbol(sema_sym) != 0

    fn generic_fn_node_for_sym(sym: i32) -> i32:
        if not self.sym_is_generic_fn(sym):
            return 0
        let direct = self.sema.generic_fn_node_for_symbol(sym)
        if direct != 0:
            return direct
        let name = self.pool.resolve_symbol(sym)
        if name.len() == 0:
            return 0
        let sema_sym = self.sema.pool_lookup_symbol(name)
        if sema_sym != 0:
            return self.sema.generic_fn_node_for_symbol(sema_sym)
        0

    fn callee_has_move_self(fn_sym: i32) -> bool:
        var fn_node = 0
        if self.sema.fn_decl_nodes.contains(fn_sym):
            fn_node = self.sema.fn_decl_nodes.get(fn_sym).unwrap()
        else:
            fn_node = self.generic_fn_node_for_sym(fn_sym)
            if fn_node == 0:
                return false
        let meta = self.ast.find_fn_meta(fn_node)
        if meta < 0 or self.ast.fn_meta_param_count(meta) == 0:
            return false
        let ps = self.ast.fn_meta_param_start(meta)
        fn_param_is_move_self(self.ast.fn_param_flags(ps, 0)) != 0

    // §9.5/#641a: a `mut self: Self` receiver is a non-consuming mutable borrow of
    // the caller's place; the caller must pass it as OK_COPY of the place, never
    // OK_MOVE + consume.
    fn callee_has_mut_self(fn_sym: i32) -> bool:
        var fn_node = 0
        if self.sema.fn_decl_nodes.contains(fn_sym):
            fn_node = self.sema.fn_decl_nodes.get(fn_sym).unwrap()
        else:
            fn_node = self.generic_fn_node_for_sym(fn_sym)
            if fn_node == 0:
                return false
        let meta = self.ast.find_fn_meta(fn_node)
        if meta < 0 or self.ast.fn_meta_param_count(meta) == 0:
            return false
        let ps = self.ast.fn_meta_param_start(meta)
        fn_param_is_mut_self(self.ast.fn_param_flags(ps, 0)) != 0

    fn call_sig_for_expr(fn_expr: i32) -> i32:
        if fn_expr == 0:
            return -1
        if self.ast.kind(fn_expr) != NodeKind.NK_IDENT:
            return -1
        self.call_sig_for_sym(self.ast.get_data0(fn_expr))

    mut fn callable_fn_type_for_expr(fn_expr: i32) -> i32:
        if fn_expr == 0:
            return 0
        let expr_tid = self.expr_type(fn_expr)
        if expr_tid == 0:
            return 0
        self.sema.callable_any_fn_type(expr_tid as TypeId)

    mut fn lower_call_arg(arg_node: i32, sig_idx: i32, callable_fn_tid: i32, arg_i: i32, callee_sym: i32 = 0) -> i32:
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
        let autocopy_ref_op = self.lower_auto_copy_ref_call_arg(arg_node, expected_ty)
        if autocopy_ref_op >= 0:
            self.expected_type = saved_expected
            return autocopy_ref_op
        let autoderef_op = self.lower_auto_deref_call_arg(arg_node, expected_ty)
        if autoderef_op >= 0:
            self.expected_type = saved_expected
            return autoderef_op
        // #604 stage 1: a Vec/array arg coerced to a []T / []mut T param borrows
        // the place into a fat-pointer view. Never materialize the collection —
        // no header copy, no drop schedule (the lower_for_iter_ref discipline);
        // the caller's binding keeps sole ownership across the call.
        if self.sema.slice_coerce_args.contains(arg_node):
            let sc_place = self.lower_expr_place(arg_node)
            let sc_start = self.int_const_operand(0, self.sema.ty_i64)
            let sc_len_local = self.new_temp(self.sema.ty_i64)
            let sc_len_place = self.place_for_local(sc_len_local)
            let sc_len_rv = self.body.new_rvalue(RvalueKind.RK_LEN, sc_place, 0, 0)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, sc_len_place, sc_len_rv, self.ast.get_start(arg_node))
            let sc_end = self.body.new_operand(OperandKind.OK_COPY, sc_len_place)
            let sc_rv = self.body.new_rvalue(RvalueKind.RK_SLICE, sc_place, sc_start, sc_end)
            let sc_local = self.new_temp(expected_ty)
            let sc_slice_place = self.place_for_local(sc_local)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, sc_slice_place, sc_rv, self.ast.get_start(arg_node))
            self.expected_type = saved_expected
            return self.body.new_operand(OperandKind.OK_COPY, sc_slice_place)
        let lowered = self.lower_expr(arg_node)
        self.expected_type = saved_expected
        // #D5/P1: a PLAIN argument to a share-place (value_ref_abi / IndirectPlace)
        // parameter is a borrow — the caller keeps ownership and drops it in its own
        // scope, so DO NOT cancel the caller's drop. Only an explicit `move`/`copy`,
        // or an owned/extern parameter, consumes the operand. (Plain args to owned
        // params are already rejected at check time, so a plain arg reaching here for
        // a non-share-place param is extern/copy — keep the existing behavior.)
        let arg_kind = self.ast.kind(arg_node)
        let arg_is_copy = arg_kind == NodeKind.NK_COPY_ARG
        let callee_share_place = sig_idx >= 0 and arg_i >= 0 and self.sema.sig_param_uses_value_ref_abi(sig_idx, arg_i) != 0
        // D16 (rvalue-uniform `move`): `move x` always moves, callee-independent.
        // Into a share-place callee, the moved value becomes a statement
        // temporary — the callee borrows the temporary, the source is reset now
        // (consume_moved_operand), and the temporary dies at the end of the
        // enclosing statement (§2.4). Previously the caller kept the value until
        // scope exit — a silent deferred drop contradicting mutability.md's
        // "ownership is transferred to the function".
        if callee_share_place and arg_kind == NodeKind.NK_MOVE_ARG and self.body.operand_kinds.get(lowered as i64) == OperandKind.OK_MOVE:
            let mv_ty = self.operand_type(lowered)
            let mv_tmp = self.new_temp(mv_ty)
            let mv_tmp_place = self.place_for_local(mv_tmp)
            let mv_rv = self.body.new_rvalue(RvalueKind.RK_USE, lowered, 0, 0)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, mv_tmp_place, mv_rv, self.ast.get_start(arg_node))
            self.consume_moved_operand(lowered)
            // The temp dies with the pending-reset flush: after the call, at the
            // statement boundary — or inside the branch on the moving path, so a
            // conditionally-created temp is never dropped on the not-taken path.
            self.pending_move_temp_locals.push(mv_tmp)
            return self.body.new_operand(OperandKind.OK_COPY, mv_tmp_place)
        // A share-place (value_ref_abi) parameter BORROWS — a PLAIN argument
        // stays owned by the caller, which keeps its drop. Only an owned
        // param, or a `copy` (whose clone is a distinct owned temp), consumes
        // the operand.
        if arg_is_copy or not callee_share_place:
            // #747: sema's extern doctrine (extern_param_is_bit_copy): an
            // extern/C param with no DECLARED consume effect is a bit-copy —
            // the callee reads transiently and never owns. Consuming here was
            // the stage2 moved-arg-reset class: the checker modeled no
            // transfer, but the move reset the caller's slot, so every later
            // read (including a later ARG of the same call, args evaluate
            // left-to-right) saw an empty str. Re-issue the operand as a
            // non-consuming share: the caller keeps ownership and its drop;
            // an rvalue arg stays a registered statement temp and still
            // drops exactly once. Explicit `move` keeps its transfer.
            if not arg_is_copy and arg_kind != NodeKind.NK_MOVE_ARG and callee_sym != 0 and self.body.operand_kinds.get(lowered as i64) == OperandKind.OK_MOVE:
                let bc_sym = self.sema_symbol_for_ast_symbol(callee_sym)
                if self.sema.extern_param_is_bit_copy(bc_sym, sig_idx, arg_i) != 0:
                    let bc_place: i32 = self.body.operand_d0.get(lowered as i64)
                    if self.place_type_is_str(bc_place) != 0:
                        self.mark_string_place_copied(bc_place)
                    return self.body.new_operand(OperandKind.OK_COPY, bc_place)
            self.consume_moved_operand(lowered)
        // #606: a by-value `xs.push(a)` arg carries the receiver's buffer; cancel the
        // receiver's drop so it isn't double-freed with the callee's. Gated to NK_CALL
        // args so the receiver-cancel only flows through self-aliasing push chains —
        // bare-ident/borrowed args are unaffected (handled by consume_moved_operand).
        if self.ast.kind(arg_node) == NodeKind.NK_CALL:
            self.cancel_scheduled_value_drop_for_receiver_expr(arg_node)
        lowered

    mut fn lower_method_arg_with_expected(recv_type: i32, method_sym: i32, arg_node: i32, arg_index: i32) -> i32:
        let saved_expected = self.expected_type
        var expected_ty = 0
        if recv_type != 0:
            let resolved_recv = self.sema.auto_deref_ref_ptr_type(recv_type as TypeId) as i32
            expected_ty = self.sema.method_expected_arg_type(resolved_recv, method_sym, arg_index)
            if expected_ty != 0 and expected_ty != self.sema.ty_void as i32:
                self.expected_type = expected_ty
        let autocopy_ref = self.lower_auto_copy_ref_call_arg(arg_node, expected_ty)
        let lowered = if autocopy_ref >= 0: autocopy_ref else: self.lower_expr(arg_node)
        self.expected_type = saved_expected
        lowered

    // Return-boundary auto-ref (D5's call-argument rule at the dual
    // position): an already-lowered place operand of type T feeding a &T
    // return borrows the place, exactly like a call argument does. Runs
    // AFTER lowering so block bodies adjust through their tail operand.
    // Gated to named-rooted places — a temporary's view must keep failing
    // loudly instead of borrowing a dying slot.
    // The tail operand may already have been lowered as a MOVE before the
    // declared &T return proves it a borrow. Un-do the move's §2.5.1
    // bookkeeping for that place — otherwise the epilogue flush blanks the
    // borrowed place, and for a field of a borrowed &Self receiver the blank
    // lands in the CALLER's struct: `fn get(self: &Self) -> &T: stmt();
    // self.field` returned a valid reference to a field this function then
    // zeroed (the std.build capability-accessor corruption, #921 rig).
    mut fn cancel_move_bookkeeping_for_borrowed_place(place: i32) -> Unit:
        var i = self.pending_reset_field_places.len() as i32 - 1
        while i >= 0:
            if self.places_are_identical(place, self.pending_reset_field_places.get(i as i64)) != 0:
                let _p = self.pending_reset_field_places.remove(i as i64)
                let _t = self.pending_reset_field_types.remove(i as i64)
            i = i - 1
        self.clear_moved_fields_for_place(place)
        let local_id = mir_place_plain_local(&self.body, place)
        if local_id >= 0:
            var j = self.pending_reset_locals.len() as i32 - 1
            while j >= 0:
                if self.pending_reset_locals.get(j as i64) == local_id:
                    let _l = self.pending_reset_locals.remove(j as i64)
                j = j - 1
            self.clear_local_value_moved(local_id)

    mut fn adjust_ret_operand_auto_ref(op: i32, value_expr: i32, ret_ty: i32, span: i32) -> i32:
        if op < 0 or value_expr == 0 or ret_ty == 0:
            return -1
        let ok: i32 = self.body.operand_kinds.get(op as i64)
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            return -1
        let actual_ty = self.expr_type(value_expr)
        if actual_ty == 0 or actual_ty == ret_ty:
            return -1
        if self.sema.can_auto_ref_arg_frozen(ret_ty, actual_ty) == 0:
            return -1
        let place: i32 = self.body.operand_d0.get(op as i64)
        if self.place_source_is_named(place) == 0:
            return -1
        if ok == OperandKind.OK_MOVE:
            self.cancel_move_bookkeeping_for_borrowed_place(place)
        if self.place_type_is_str(place) != 0:
            self.mark_string_place_copied(place)
        else:
            self.mark_string_base_fields_may_alias(self.place_base_local(place))
        let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, place, 0)
        let temp = self.new_temp(ret_ty)
        let temp_place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, span)
        self.body.new_operand(OperandKind.OK_COPY, temp_place)

    mut fn lower_auto_ref_call_arg(arg_node: i32, expected_ty: i32) -> i32:
        if arg_node == 0 or expected_ty == 0:
            return -1
        let actual_ty = self.expr_type(arg_node)
        if actual_ty == 0:
            return -1
        if self.sema.can_auto_ref_arg_frozen(expected_ty, actual_ty) == 0:
            return -1
        let place = self.lower_expr_place(arg_node)
        if self.place_type_is_str(place) != 0:
            self.mark_string_place_copied(place)
        else:
            self.mark_string_base_fields_may_alias(self.place_base_local(place))
        let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, place, 0)
        let temp = self.new_temp(expected_ty)
        let temp_place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(arg_node))
        self.body.new_operand(OperandKind.OK_COPY, temp_place)

    // D22 call arguments consume the same Sema record as every other
    // owned-demand position; no MIR path re-derives Copy-ness or demand.
    mut fn lower_auto_copy_ref_call_arg(arg_node: i32, expected_ty: i32) -> i32:
        if arg_node == 0 or expected_ty == 0:
            return -1
        if self.has_contextual_copy_adjustment(arg_node) == 0:
            return -1
        let adjustment = self.contextual_copy_adjustment(arg_node)
        if adjustment.target_type != expected_ty:
            return -1
        self.lower_contextual_copy_adjustment(arg_node)

    // D22 Stage 5: this is the single MIR consumer for Sema's contextual-Copy
    // adjustment. Lower the source at its exact &T type, copy through one
    // dereference, then apply the separately-recorded ordinary value coercion.
    // No inference, overload, dispatch, or ABI decision is repeated here.
    mut fn lower_contextual_copy_adjustment(node: i32) -> i32:
        if node == 0 or self.has_contextual_copy_adjustment(node) == 0:
            return -1
        let adjustment = self.contextual_copy_adjustment(node)
        let saved_raw_node = self.contextual_copy_raw_node
        let saved_expected = self.expected_type
        self.contextual_copy_raw_node = node
        self.expected_type = adjustment.exact_source_type
        let reference_op = self.lower_expr(node)
        self.expected_type = saved_expected
        self.contextual_copy_raw_node = saved_raw_node

        let reference_place = self.materialize_operand(reference_op, adjustment.exact_source_type, self.ast.get_start(node))
        let pointee_place = self.new_deref_place(reference_place)
        // #781: a str materialization mints an independent owner (two-part
        // concat copy); a shallow pointee copy would alias the buffer into a
        // double free.
        if self.type_id_is_str(adjustment.owned_value_type) != 0:
            let sc_parts: Vec[i32] = Vec.new()
            sc_parts.push(self.body.new_operand(OperandKind.OK_COPY, pointee_place))
            sc_parts.push(self.lower_str_lit(self.pool.intern("")))
            let sc_args = self.body.new_call_args(sc_parts)
            let sc_rv = self.body.new_rvalue(RvalueKind.RK_STR_CONCAT_N, sc_args, 2, 0)
            let sc_tmp = self.new_temp(adjustment.owned_value_type)
            let sc_place = self.place_for_local(sc_tmp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, sc_place, sc_rv, self.ast.get_start(node))
            self.set_string_local_flags(sc_tmp, 2)
            return self.body.new_operand(OperandKind.OK_MOVE, sc_place)
        let owned_op = self.body.new_operand(OperandKind.OK_COPY, pointee_place)
        if adjustment.post_copy_type == 0:
            return owned_op

        let rv = self.body.new_rvalue(RvalueKind.RK_CAST, owned_op, adjustment.target_type, adjustment.owned_value_type)
        let temp = self.new_temp(adjustment.target_type)
        let place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
        self.body.new_operand(OperandKind.OK_COPY, place)

    fn contextual_join_arm_index_for_role(join_node: i32, role: i32) -> i32:
        if self.has_contextual_join_decision(join_node) == 0:
            return -1
        let decision = self.contextual_join_decision(join_node)
        for offset in 0..decision.arm_count:
            let index = decision.arm_start + offset
            if self.sema.contextual_join_arm_roles.get(index as i64) == role:
                return index
        -1

    // Synthetic carrier/lazy arms have no ordinary AST expression on which
    // lower_expr can consume an adjustment. Read their exact type and arm kind
    // from Sema's join decision, then perform precisely that recorded action.
    mut fn lower_contextual_join_place_arm(join_node: i32, role: i32, exact_place: i32, span: i32) -> i32:
        let arm_index = self.contextual_join_arm_index_for_role(join_node, role)
        if arm_index < 0:
            self.mark_unsupported()
            return self.unit_operand()
        let decision = self.contextual_join_decision(join_node)
        let exact_type: i32 = self.sema.contextual_join_arm_types.get(arm_index as i64)
        let arm_kind: i32 = self.sema.contextual_join_arm_kinds.get(arm_index as i64)
        var source_type: i32 = exact_type
        var op = self.operand_for_place(exact_place, exact_type)
        if arm_kind == D22_JOIN_ARM_MATERIALIZED_REF:
            let resolved = self.sema.resolve_alias(exact_type as TypeId)
            if self.sema.get_type_kind(resolved) != TypeKind.TY_REF:
                self.mark_unsupported()
                return self.unit_operand()
            source_type = self.sema.get_type_d0(resolved)
            op = self.body.new_operand(OperandKind.OK_COPY, self.new_deref_place(exact_place))

        if self.sema.resolve_alias(source_type as TypeId) == self.sema.resolve_alias(decision.final_type as TypeId):
            return op
        let rv = self.body.new_rvalue(RvalueKind.RK_CAST, op, decision.final_type, source_type)
        let temp = self.new_temp(decision.final_type)
        let place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, span)
        self.body.new_operand(OperandKind.OK_COPY, place)

    mut fn lower_auto_deref_call_arg(arg_node: i32, expected_ty: i32) -> i32:
        if arg_node == 0 or expected_ty == 0:
            return -1
        if self.sema.autoderef_step_counts.contains(arg_node):
            let place = self.lower_recorded_autoderef_place(arg_node)
            let start: i32 = self.sema.autoderef_step_starts.get(arg_node).unwrap()
            let count: i32 = self.sema.autoderef_step_counts.get(arg_node).unwrap()
            var final_ty = self.expr_type(arg_node)
            if count > 0:
                final_ty = self.sema.autoderef_step_tys.get((start + count - 1) as i64)
            if self.sema.types_compatible_frozen(expected_ty, final_ty) != 0:
                return self.body.new_operand(OperandKind.OK_COPY, place)
            if self.sema.can_auto_ref_arg_frozen(expected_ty, final_ty) != 0:
                let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, place, 0)
                let temp = self.new_temp(expected_ty)
                let temp_place = self.place_for_local(temp)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(arg_node))
                return self.body.new_operand(OperandKind.OK_COPY, temp_place)
            return -1
        var current_ty = self.expr_type(arg_node)
        if current_ty == 0:
            return -1
        if self.sema.types_compatible_frozen(expected_ty, current_ty) != 0:
            return -1
        var place = self.lower_expr_place(arg_node)
        let place_ty = self.place_local_type(place)
        if place_ty != 0 and place_ty != self.sema.ty_void as i32:
            current_ty = place_ty
        var depth = 0
        while current_ty > 0 and depth < 32:
            if self.sema.types_compatible_frozen(expected_ty, current_ty) != 0:
                return self.body.new_operand(OperandKind.OK_COPY, place)
            if self.sema.can_auto_ref_arg_frozen(expected_ty, current_ty) != 0:
                let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, place, 0)
                let temp = self.new_temp(expected_ty)
                let temp_place = self.place_for_local(temp)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(arg_node))
                return self.body.new_operand(OperandKind.OK_COPY, temp_place)
            let current_resolved = self.sema.resolve_alias(current_ty as TypeId)
            let current_kind = self.sema.get_type_kind(current_resolved)
            if current_kind == TypeKind.TY_REF or current_kind == TypeKind.TY_PTR:
                let inner = self.sema.get_type_d0(current_resolved)
                if inner == 0:
                    return -1
                place = self.new_deref_place(place)
                current_ty = inner
                depth = depth + 1
                continue
            let deref_info = self.sema.resolve_user_deref_info_frozen(current_resolved as i32)
            if deref_info.ok == 0:
                return -1
            let result_ref_ty = deref_info.result_ref_ty
            place = self.lower_user_deref_result_place(place, current_resolved as i32, deref_info, arg_node)
            current_ty = result_ref_ty
            depth = depth + 1
        -1

    // Generic-method receivers must honor the instantiated signature's
    // receiver contract: a `&Self` param takes the receiver place's ADDRESS
    // (autoref), not the place value. Pushing the walked place raw
    // reintroduced the #627 transparent-box class for migrated impl-block
    // methods — a std Box value and &Box both lower to `ptr`, so codegen
    // cannot recover the lost indirection later (behav_box_as_ref pins this).
    // Only the sig-demands-ref/receiver-is-bare-owner case diverts; every
    // other shape keeps the plain autoderef result.
    mut fn lower_generic_receiver_arg(recv_node: i32, method_sym: i32, sig_idx: i32) -> i32:
        let raw_op = self.lower_receiver_with_method_autoderef_for_method(recv_node, method_sym)
        if sig_idx < 0 or self.sema.sig_get_param_count(sig_idx) <= 0:
            return raw_op
        let expected = self.sema.sig_param_type(sig_idx, 0)
        let actual = self.expr_type(recv_node)
        if expected == 0 or actual == 0 or self.sema.can_auto_ref_arg_frozen(expected, actual) == 0:
            return raw_op
        if self.body.operand_kinds.get(raw_op as i64) != OperandKind.OK_COPY:
            return raw_op
        let place: i32 = self.body.operand_d0.get(raw_op as i64)
        self.operand_for_place_arg(place, actual, expected, self.ast.get_start(recv_node))

    mut fn lower_receiver_with_method_autoderef_for_method(recv_node: i32, method_sym: i32) -> i32:
        if self.has_contextual_copy_adjustment(recv_node) != 0:
            return self.lower_contextual_copy_adjustment(recv_node)
        if method_sym == 0:
            return self.lower_receiver_with_method_autoderef(recv_node)
        let sema_method_sym = self.sema.pool_lookup_symbol(self.pool.resolve_symbol(method_sym))
        let lookup_method = if sema_method_sym != 0: sema_method_sym else: method_sym
        var current_ty = self.expr_type(recv_node)
        if current_ty == 0:
            return self.lower_expr(recv_node)
        var place = self.lower_expr_place(recv_node)
        let place_ty = self.place_local_type(place)
        if place_ty != 0 and place_ty != self.sema.ty_void as i32:
            current_ty = place_ty
        var depth = 0
        while current_ty > 0 and depth < 32:
            let current = self.sema.resolve_alias(current_ty as TypeId)
            if self.sema.autoderef_type_has_method(current, lookup_method) != 0:
                let owner_sym = self.sema.method_owner_symbol_for_type(current as i32)
                if owner_sym != 0 and self.sema.method_has_move_self_flag(owner_sym, lookup_method) != 0:
                    return self.body.new_operand(OperandKind.OK_MOVE, place)
                return self.body.new_operand(OperandKind.OK_COPY, place)
            let kind = self.sema.get_type_kind(current)
            if kind == TypeKind.TY_REF or kind == TypeKind.TY_PTR:
                let inner = self.sema.get_type_d0(current)
                if inner == 0:
                    return self.body.new_operand(OperandKind.OK_COPY, place)
                place = self.new_deref_place(place)
                current_ty = inner
                depth = depth + 1
                continue
            let deref_info = self.sema.resolve_user_deref_info_frozen(current as i32)
            if deref_info.ok == 0:
                return self.body.new_operand(OperandKind.OK_COPY, place)
            let result_ref_ty = deref_info.result_ref_ty
            place = self.lower_user_deref_result_place(place, current as i32, deref_info, recv_node)
            current_ty = result_ref_ty
            depth = depth + 1
        self.body.new_operand(OperandKind.OK_COPY, place)

    mut fn lower_receiver_with_method_autoderef(recv_node: i32) -> i32:
        if self.sema.autoderef_step_counts.contains(recv_node):
            let place = self.lower_recorded_autoderef_place(recv_node)
            return self.body.new_operand(OperandKind.OK_COPY, place)
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
            place = self.new_deref_place(place)
        self.body.new_operand(OperandKind.OK_COPY, place)

    fn recorded_autoderef_result_type(expr: i32, fallback_ty: i32) -> i32:
        if not self.sema.autoderef_step_counts.contains(expr):
            return fallback_ty
        let count = self.sema.autoderef_step_counts.get(expr).unwrap()
        if count <= 0:
            return fallback_ty
        let start = self.sema.autoderef_step_starts.get(expr).unwrap()
        self.sema.autoderef_step_tys.get((start + count - 1) as i64)

    mut fn autoderef_result_type_for_method(recv_ty: i32, method_sym: i32) -> i32:
        if recv_ty == 0 or recv_ty == self.sema.ty_void as i32:
            return recv_ty
        let sema_method_sym = self.sema.pool_lookup_symbol(self.pool.resolve_symbol(method_sym))
        let lookup_method = if sema_method_sym != 0: sema_method_sym else: method_sym
        self.sema.auto_deref_method_type_frozen(recv_ty as TypeId, lookup_method) as i32

    mut fn resolve_method_callee_sym(self_expr: i32, method_sym: i32) -> i32:
        // Translate method_sym from AST pool to sema pool for method lookups.
        let method_text = self.pool.resolve_symbol(method_sym)
        let sema_method_lookup = self.sema.pool_lookup_symbol(method_text)
        let sema_method_sym = if sema_method_lookup != 0: sema_method_lookup else: method_sym
        let obj_type = self.expr_type(self_expr)
        if obj_type != 0 and obj_type != self.sema.ty_void:
            let resolved = self.autoderef_result_type_for_method(obj_type, method_sym)
            let type_name_sym = self.sema.method_owner_symbol_for_type(resolved as i32)
            if type_name_sym != 0:
                if type_name_sym != self.sema.syms.fixed_string:
                    let method_fn = self.sema.lookup_method_fn(type_name_sym, sema_method_sym)
                    if method_fn != 0 and self.sema.lookup_method_sig(type_name_sym, sema_method_sym) >= 0:
                        return method_fn
                    let generic_method_fn = self.sema.lookup_generic_method_fn(type_name_sym, sema_method_sym)
                    if generic_method_fn != 0:
                        return generic_method_fn

        if self.ast.kind(self_expr) == NodeKind.NK_IDENT and self.pool.resolve_symbol(self.ast.get_data0(self_expr)) == "self":
            let current_fn_name = self.sema.pool_resolve(self.body.fn_sym)
            var owner_text = ""
            for ci in 0..current_fn_name.len() as i32:
                if current_fn_name.byte_at(ci as i64) == 46:
                    owner_text = current_fn_name.slice(0, ci as i64)
                    break
            if owner_text.len() > 0:
                let owner_sym = self.sema.pool_lookup_symbol(owner_text)
                if owner_sym != 0:
                    let method_fn = self.sema.lookup_method_fn(owner_sym, sema_method_sym)
                    if method_fn != 0 and self.sema.lookup_method_sig(owner_sym, sema_method_sym) >= 0:
                        return method_fn
                    let generic_method_fn = self.sema.lookup_generic_method_fn(owner_sym, sema_method_sym)
                    if generic_method_fn != 0:
                        return generic_method_fn

        if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
            let type_sym = self.ast.get_data0(self_expr)
            if type_sym != self.sema.syms.fixed_string:
                let method_fn = self.sema.lookup_method_fn(type_sym, method_sym)
                if method_fn != 0 and self.sema.lookup_method_sig(type_sym, method_sym) >= 0:
                    return method_fn

        // Handle Vec[i32].method() — receiver is NodeKind.NK_INDEX of a type name
        if self.ast.kind(self_expr) == NodeKind.NK_INDEX:
            let base = self.ast.get_data0(self_expr)
            if self.ast.kind(base) == NodeKind.NK_IDENT:
                let type_sym = self.ast.get_data0(base)
                if type_sym != self.sema.syms.fixed_string:
                    let method_fn = self.sema.lookup_method_fn(type_sym, method_sym)
                    if method_fn != 0 and self.sema.lookup_method_sig(type_sym, method_sym) >= 0:
                        return method_fn

        method_sym

    fn receiver_is_static_type_expr(expr: i32) -> i32:
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

    fn static_receiver_base_sym(expr: i32) -> i32:
        if expr == 0:
            return 0
        let kind = self.ast.kind(expr)
        if kind == NodeKind.NK_IDENT:
            let sym = self.ast.get_data0(expr)
            let sema_sym = self.sema.pool_lookup_symbol(self.pool.resolve_symbol(sym))
            if self.lookup_local(sym) < 0 and sema_sym != 0 and self.sema.named_types.contains(sema_sym):
                return sema_sym
            return 0
        if kind == NodeKind.NK_INDEX:
            return self.static_receiver_base_sym(self.ast.get_data0(expr))
        if kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_GENERIC:
            return self.sema.pool_lookup_symbol(self.pool.resolve_symbol(self.ast.get_data0(expr)))
        0

    mut fn lower_static_enum_variant_call(enum_ty: i32, variant_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
        var result_ty = self.expr_type(node)
        if result_ty == 0 or result_ty == self.sema.ty_void:
            result_ty = enum_ty
        // #566: a payloadless discriminant-enum variant constructed in CALL form
        // (Color.Red()) materializes as its repr-backed int constant — matching the
        // bare-ident and shorthand paths (lower_var). The RK_AGGREGATE d0=1 form
        // below is for payload-bearing enums only; codegen's variant arm requires a
        // struct repr and a payloadless disc enum lowers to a bare integer.
        let sev_resolved = self.sema.resolve_alias(result_ty)
        if self.sema.disc_repr_types.contains(sev_resolved as i32) and not self.sema.disc_has_payload.contains(sev_resolved as i32):
            let sev_disc_val = self.enum_variant_discriminant_for_type(result_ty, variant_sym)
            return self.int_const_operand(sev_disc_val as i64, result_ty)
        let payload_tys = self.sema.enum_variant_payload_types_frozen(result_ty, variant_sym)
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
        // #693 ROOT CAUSE: a payload moved into the variant aggregate must be
        // CONSUMED (reset-on-move + ever-moved marking) like every other move
        // — the drop-state PLAN skips the payload temp's scope-exit drop, but
        // codegen's emission relies on the guard+blank that only
        // consume_moved_operand arms. Without it the moved-out temp's drop
        // ran unguarded on intact bytes: every Drop-payload enum double-freed
        // at plain scope exit.
        for cfi in 0..fields.len() as i32:
            self.consume_moved_operand(fields.get(cfi as i64))
        // #693 (secondary): the constructed variant is OWNED by this temp — a
        // Drop-payload enum must MOVE into its destination; Copy stays for
        // Copy enums only, matching every other result-operand site.
        if self.sema.is_copy_frozen(result_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, place)
        self.body.new_operand(OperandKind.OK_MOVE, place)

    fn classify_intrinsic(recv_type: i32, method_name: &str) -> MirIntrinsic:
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
        if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
            let arr_len_intrinsic = mir_len_method_intrinsic(MirIntrinsic.ARR_LEN, method_name)
            if arr_len_intrinsic != MirIntrinsic.NONE: return arr_len_intrinsic
            if method_name == "split_at": return MirIntrinsic.SPLIT_AT
            if method_name == "split_at_mut": return MirIntrinsic.SPLIT_AT_MUT
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
        var type_name = self.sema.pool_resolve_symbol(type_name_sym)
        if type_name.len() == 0:
            type_name = self.pool.resolve_symbol(type_name_sym)
        if type_name == "Task" or type_name == "ScopedTask":
            if method_name == "cancel": return MirIntrinsic.FIBER_CANCEL
            if method_name == "is_done": return MirIntrinsic.FIBER_IS_DONE
            if method_name == "was_cancelled": return MirIntrinsic.FIBER_WAS_CANCELLED_RETURN
            return MirIntrinsic.NONE
        if type_name == "Vec":
            if method_name == "new": return MirIntrinsic.VEC_NEW
            if method_name == "with_capacity": return MirIntrinsic.VEC_WITH_CAPACITY
            if method_name == "push": return MirIntrinsic.VEC_PUSH
            if method_name == "get": return MirIntrinsic.VEC_GET
            if method_name == "is_empty": return MirIntrinsic.VEC_IS_EMPTY
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
            if method_name == "split_at": return MirIntrinsic.SPLIT_AT
            if method_name == "split_at_mut": return MirIntrinsic.SPLIT_AT_MUT
            if method_name == "iter_place": return MirIntrinsic.VEC_ITER_PLACE
            if method_name == "map": return MirIntrinsic.VEC_MAP
            if method_name == "filter": return MirIntrinsic.VEC_FILTER
            if method_name == "fold": return MirIntrinsic.VEC_FOLD
            if method_name == "contains": return MirIntrinsic.VEC_CONTAINS
            if method_name == "join": return MirIntrinsic.VEC_JOIN
            return MirIntrinsic.NONE
        if type_name == "FixedString" or type_name.starts_with("FixedString__"):
            if method_name == "new": return MirIntrinsic.FIXED_STRING_NEW
            if method_name == "len": return MirIntrinsic.FIXED_STRING_LEN
            if method_name == "len_i32": return MirIntrinsic.FIXED_STRING_LEN32
            if method_name == "len_i64": return MirIntrinsic.FIXED_STRING_LEN64
            if method_name == "capacity": return MirIntrinsic.FIXED_STRING_CAPACITY
            if method_name == "is_empty": return MirIntrinsic.FIXED_STRING_IS_EMPTY
            if method_name == "clear": return MirIntrinsic.FIXED_STRING_CLEAR
            if method_name == "push_byte": return MirIntrinsic.FIXED_STRING_PUSH_BYTE
            if method_name == "push_str": return MirIntrinsic.FIXED_STRING_PUSH_STR
            if method_name == "as_view": return MirIntrinsic.FIXED_STRING_AS_VIEW
            if method_name == "equals": return MirIntrinsic.FIXED_STRING_EQUALS
            return MirIntrinsic.NONE
        if type_name == "VecIter" or type_name == "VecIterRef":
            if method_name == "next":
                if type_name == "VecIterRef": return MirIntrinsic.VECITERREF_NEXT
                return MirIntrinsic.VECITER_NEXT
            if method_name == "map": return MirIntrinsic.ITER_MAP
            if method_name == "filter": return MirIntrinsic.ITER_FILTER
            if method_name == "filter_map": return MirIntrinsic.ITER_FILTER_MAP
            if method_name == "take": return MirIntrinsic.ITER_TAKE
            if method_name == "drop": return MirIntrinsic.ITER_DROP
            if method_name == "take_while": return MirIntrinsic.ITER_TAKE_WHILE
            if method_name == "drop_while": return MirIntrinsic.ITER_DROP_WHILE
            if method_name == "zip": return MirIntrinsic.ITER_ZIP
            if method_name == "enumerate": return MirIntrinsic.ITER_ENUMERATE
            if method_name == "chain": return MirIntrinsic.ITER_CHAIN
            if method_name == "zip_with": return MirIntrinsic.ITER_ZIP_WITH
            if method_name == "step_by": return MirIntrinsic.ITER_STEP_BY
            if method_name == "flat_map": return MirIntrinsic.ITER_FLAT_MAP
            if method_name == "fold": return MirIntrinsic.ITER_FOLD
            if method_name == "reduce": return MirIntrinsic.ITER_REDUCE
            if method_name == "sum": return MirIntrinsic.ITER_SUM
            if method_name == "product": return MirIntrinsic.ITER_PRODUCT
            if method_name == "min": return MirIntrinsic.ITER_MIN
            if method_name == "max": return MirIntrinsic.ITER_MAX
            if method_name == "min_by": return MirIntrinsic.ITER_MIN_BY
            if method_name == "max_by": return MirIntrinsic.ITER_MAX_BY
            if method_name == "find": return MirIntrinsic.ITER_FIND
            if method_name == "position": return MirIntrinsic.ITER_POSITION
            if method_name == "any": return MirIntrinsic.ITER_ANY
            if method_name == "all": return MirIntrinsic.ITER_ALL
            if method_name == "none": return MirIntrinsic.ITER_NONE
            if method_name == "for_each": return MirIntrinsic.ITER_FOR_EACH
            if method_name == "count": return MirIntrinsic.ITER_COUNT
            if method_name == "collect": return MirIntrinsic.ITER_COLLECT
            if method_name == "partition": return MirIntrinsic.ITER_PARTITION
            if method_name == "unzip": return MirIntrinsic.ITER_UNZIP
            return MirIntrinsic.NONE
        if type_name == "MapIter" or type_name == "FilterIter" or type_name == "FilterMapIter" or type_name == "TakeIter" or type_name == "DropIter" or type_name == "TakeWhileIter" or type_name == "DropWhileIter" or type_name == "ZipIter" or type_name == "EnumerateIter" or type_name == "ChainIter" or type_name == "ZipWithIter" or type_name == "StepByIter" or type_name == "FlatMapIter":
            if method_name == "next":
                if type_name == "MapIter": return MirIntrinsic.MAPITER_NEXT
                if type_name == "FilterIter": return MirIntrinsic.FILTERITER_NEXT
                if type_name == "FilterMapIter": return MirIntrinsic.FILTERMAPITER_NEXT
                if type_name == "TakeIter": return MirIntrinsic.TAKEITER_NEXT
                if type_name == "DropIter": return MirIntrinsic.DROPITER_NEXT
                if type_name == "TakeWhileIter": return MirIntrinsic.TAKEWHILEITER_NEXT
                if type_name == "DropWhileIter": return MirIntrinsic.DROPWHILEITER_NEXT
                if type_name == "ZipIter": return MirIntrinsic.ZIPITER_NEXT
                if type_name == "EnumerateIter": return MirIntrinsic.ENUMERATEITER_NEXT
                if type_name == "ChainIter": return MirIntrinsic.CHAINITER_NEXT
                if type_name == "ZipWithIter": return MirIntrinsic.ZIPWITHITER_NEXT
                if type_name == "StepByIter": return MirIntrinsic.STEPBYITER_NEXT
                if type_name == "FlatMapIter": return MirIntrinsic.FLATMAPITER_NEXT
            if method_name == "map": return MirIntrinsic.ITER_MAP
            if method_name == "filter": return MirIntrinsic.ITER_FILTER
            if method_name == "filter_map": return MirIntrinsic.ITER_FILTER_MAP
            if method_name == "take": return MirIntrinsic.ITER_TAKE
            if method_name == "drop": return MirIntrinsic.ITER_DROP
            if method_name == "take_while": return MirIntrinsic.ITER_TAKE_WHILE
            if method_name == "drop_while": return MirIntrinsic.ITER_DROP_WHILE
            if method_name == "zip": return MirIntrinsic.ITER_ZIP
            if method_name == "enumerate": return MirIntrinsic.ITER_ENUMERATE
            if method_name == "chain": return MirIntrinsic.ITER_CHAIN
            if method_name == "zip_with": return MirIntrinsic.ITER_ZIP_WITH
            if method_name == "step_by": return MirIntrinsic.ITER_STEP_BY
            if method_name == "flat_map": return MirIntrinsic.ITER_FLAT_MAP
            if method_name == "fold": return MirIntrinsic.ITER_FOLD
            if method_name == "reduce": return MirIntrinsic.ITER_REDUCE
            if method_name == "sum": return MirIntrinsic.ITER_SUM
            if method_name == "product": return MirIntrinsic.ITER_PRODUCT
            if method_name == "min": return MirIntrinsic.ITER_MIN
            if method_name == "max": return MirIntrinsic.ITER_MAX
            if method_name == "min_by": return MirIntrinsic.ITER_MIN_BY
            if method_name == "max_by": return MirIntrinsic.ITER_MAX_BY
            if method_name == "find": return MirIntrinsic.ITER_FIND
            if method_name == "position": return MirIntrinsic.ITER_POSITION
            if method_name == "any": return MirIntrinsic.ITER_ANY
            if method_name == "all": return MirIntrinsic.ITER_ALL
            if method_name == "none": return MirIntrinsic.ITER_NONE
            if method_name == "for_each": return MirIntrinsic.ITER_FOR_EACH
            if method_name == "count": return MirIntrinsic.ITER_COUNT
            if method_name == "collect": return MirIntrinsic.ITER_COLLECT
            if method_name == "partition": return MirIntrinsic.ITER_PARTITION
            if method_name == "unzip": return MirIntrinsic.ITER_UNZIP
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
            if method_name == "split_at": return MirIntrinsic.SPLIT_AT
            if method_name == "split_at_mut": return MirIntrinsic.SPLIT_AT_MUT
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
            if method_name == "values": return MirIntrinsic.MAP_VALUES
            if method_name == "items": return MirIntrinsic.MAP_ITEMS
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
            if method_name == "expect": return MirIntrinsic.OPT_EXPECT
            if method_name == "filter": return MirIntrinsic.OPT_FILTER
            return MirIntrinsic.NONE
        if type_name == "Result":
            if method_name == "is_ok": return MirIntrinsic.OPT_IS_SOME
            if method_name == "unwrap": return MirIntrinsic.OPT_UNWRAP
            if method_name == "expect": return MirIntrinsic.OPT_EXPECT
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

    mut fn receiver_option_intrinsic(recv_expr: i32) -> MirIntrinsic:
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
        var method_name = self.pool.resolve_symbol(method_sym)
        if method_name.len() == 0:
            method_name = self.sema.pool_resolve(method_sym)
        let resolved = self.sema.resolve_alias(base_ty)
        let type_name_sym = self.sema.get_type_name(resolved)
        if type_name_sym == 0:
            return MirIntrinsic.NONE
        let type_name = self.pool.resolve_symbol(type_name_sym)
        // HashMap.get and SlotMap.get return borrowed Option-wrapped values.
        if type_name == "HashMap":
            if method_name == "get": return MirIntrinsic.MAP_GET
        if type_name == "HashSet":
            if method_name == "contains": return MirIntrinsic.MAP_CONTAINS
        if type_name == "SlotMap":
            if method_name == "get": return MirIntrinsic.SLOTMAP_GET
        MirIntrinsic.NONE

    mut fn lower_task_join_cleanup_call(self_expr: i32, method_sym: i32, node: i32) -> i32:
        let recv_ty = self.expr_type(self_expr)
        let recv_type = self.autoderef_result_type_for_method(recv_ty, method_sym)
        self.cancel_scheduled_value_drop_for_receiver_expr(self_expr)
        let recv_op = self.lower_receiver_with_method_autoderef_for_method(self_expr, method_sym)
        let stable_op = self.materialize_operand(recv_op, recv_type, self.ast.get_start(self_expr))
        let task_op = self.body.new_operand(OperandKind.OK_COPY, stable_op)
        self.emit_task_cancel_call(task_op, MirIntrinsic.FIBER_CANCEL, node)
        let await_op = self.body.new_operand(OperandKind.OK_COPY, stable_op)
        self.lower_cleanup_await(await_op, node)
        self.unit_operand()

    mut fn lower_method_call(self_expr: i32, method_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
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
                let ret_type = self.method_call_result_type(node)
            let ret_name_sym = self.sema.get_type_name(ret_type)
            if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
                let type_sym = self.ast.get_data0(self_expr)
                if ret_name_sym == type_sym:
                    recv_type = ret_type
        var method_name = self.pool.resolve_symbol(method_sym)
        if method_name.len() == 0:
            method_name = self.sema.pool_resolve(method_sym)
        if method_name == "as_option":
            let resolved_recv = self.sema.resolve_alias(recv_type as TypeId)
            if self.sema.get_type_kind(resolved_recv) == TypeKind.TY_PTR:
                return self.lower_expr(self_expr)
        if method_name == "join" and self.sema.type_is_scoped_join_handle(recv_type) != 0:
            callee_sym = method_sym
        if self.receiver_is_static_type_expr(self_expr) != 0 and recv_type != 0 and self.sema.enum_has_variant(recv_type, method_sym) != 0:
            return self.lower_static_enum_variant_call(recv_type, method_sym, arg_start, arg_count, node)
        let enum_accessor_recv_type = if recv_type != 0 and recv_type != self.sema.ty_void as i32: self.autoderef_result_type_for_method(recv_type, method_sym) else: recv_type
        let enum_accessor_variant = self.sema.enum_accessor_variant_for_method(enum_accessor_recv_type, method_sym)
        if enum_accessor_variant != 0:
            return self.lower_enum_accessor_call(self_expr, method_sym, node)

        // §2.4/#641b: an explicit `x.drop()` on a Drop type routes through the
        // scope-exit drop glue (destructor body + field glue) and consumes the
        // binding — never a plain method call, which would skip field drops.
        // Naked `drop` methods on non-Drop types stay ordinary method calls.
        if method_name == "drop" and arg_count == 0 and self.receiver_is_static_type_expr(self_expr) == 0:
            if enum_accessor_recv_type != 0 and self.sema.type_has_drop_impl(enum_accessor_recv_type) != 0:
                return self.lower_drop_glue_and_consume(self_expr, "explicit.drop", node)

        if self.is_option_type(enum_accessor_recv_type) != 0 and (method_name == "map" or method_name == "and_then" or method_name == "or_else" or method_name == "filter" or method_name == "inspect" or method_name == "copied" or method_name == "cloned"):
            return self.lower_option_combinator_method(self_expr, method_name, arg_start, arg_count, node)

        if self.is_option_type(enum_accessor_recv_type) != 0 and method_name == "zip":
            return self.lower_option_zip_method(self_expr, arg_start, arg_count, node)

        if self.is_option_type(enum_accessor_recv_type) != 0 and method_name == "unzip":
            return self.lower_option_unzip_method(self_expr, arg_count, node)

        if self.is_option_type(enum_accessor_recv_type) != 0 and method_name == "flatten":
            return self.lower_option_flatten_method(self_expr, arg_count, node)

        if self.is_result_type(enum_accessor_recv_type) != 0 and (method_name == "map" or method_name == "map_err" or method_name == "context" or method_name == "with_context" or method_name == "and_then" or method_name == "or_else" or method_name == "inspect" or method_name == "inspect_err"):
            return self.lower_result_combinator_method(self_expr, method_name, arg_start, arg_count, node)

        if self.is_result_type(enum_accessor_recv_type) != 0 and (method_name == "ok" or method_name == "err"):
            return self.lower_result_ok_err_method(self_expr, method_name, arg_count, node)

        if method_name == "join_cleanup" and self.sema.type_is_task(enum_accessor_recv_type) != 0:
            return self.lower_task_join_cleanup_call(self_expr, method_sym, node)

        if self.is_option_type(enum_accessor_recv_type) != 0 and method_name == "transpose":
            return self.lower_option_transpose_method(self_expr, arg_count, node)

        if self.is_result_type(enum_accessor_recv_type) != 0 and method_name == "transpose":
            return self.lower_result_transpose_method(self_expr, arg_count, node)

        if self.is_vec_type(enum_accessor_recv_type) != 0 and (method_name == "sequence" or method_name == "traverse"):
            return self.lower_vec_sequence_or_traverse_method(self_expr, method_name, arg_start, arg_count, node)

        let static_recv_base_for_btree = self.static_receiver_base_sym(self_expr)
        let recv_base_for_btree = self.literal_target_base_sym(enum_accessor_recv_type)
        if method_name == "new" and (self.is_btreeset_base_sym(static_recv_base_for_btree) != 0 or self.is_btreemap_base_sym(static_recv_base_for_btree) != 0 or self.is_btreeset_base_sym(recv_base_for_btree) != 0 or self.is_btreemap_base_sym(recv_base_for_btree) != 0):
            return self.lower_btree_new(node, recv_type)

        if method_name == "unwrap_or" and self.is_option_or_result_type(enum_accessor_recv_type) != 0:
            return self.lower_unwrap_or_method(self_expr, arg_start, arg_count, node)

        if method_name == "unwrap_or_else" and self.is_option_or_result_type(enum_accessor_recv_type) != 0:
            return self.lower_unwrap_or_else_method(self_expr, arg_start, arg_count, node)

        var intrinsic = self.classify_intrinsic(enum_accessor_recv_type, method_name)

        // Parse/lowering timing can leave a direct Option-producing intrinsic
        // without its resolved receiver type. Classify only that known producer;
        // an arbitrary unresolved method name is never evidence of Option.
        if intrinsic == MirIntrinsic.NONE:
            if method_name == "unwrap" or method_name == "expect" or method_name == "is_some" or method_name == "is_none":
                let recv_intr = self.receiver_option_intrinsic(self_expr)
                if recv_intr != MirIntrinsic.NONE:
                    if method_name == "unwrap":
                        intrinsic = MirIntrinsic.OPT_UNWRAP
                    else if method_name == "expect":
                        intrinsic = MirIntrinsic.OPT_EXPECT
                    else if method_name == "is_none":
                        intrinsic = MirIntrinsic.OPT_IS_NONE
                    else:
                        intrinsic = MirIntrinsic.OPT_IS_SOME

        // D27 E2: Sema types vec.get(i) as &T — element access observes. Lower
        // the borrow intrinsic so the result place holds the element address;
        // VEC_GET stays the owned-load form for iteration and materialization.
        if intrinsic == MirIntrinsic.VEC_GET:
            let d27_get_ret = self.expr_type(node)
            if d27_get_ret != 0 and self.sema.get_type_kind(self.sema.resolve_alias(d27_get_ret as TypeId)) == TypeKind.TY_REF:
                intrinsic = MirIntrinsic.VEC_GET_REF

        // For intrinsic calls (Vec/HashMap/Option), bypass lower_call entirely.
        // lower_call → lower_var would mark_unsupported on the bare method sym.
        // Instead, emit the call terminator directly with an intrinsic tag.
        if intrinsic != MirIntrinsic.NONE:
            return self.lower_intrinsic_call(intrinsic, self_expr, method_sym, arg_start, arg_count, node)

        // A static method on a dyn-carrying type (Box[dyn T] under an annotated
        // let makes recv_type Box[dyn T] for `Box.new(...)`) is NOT a dyn
        // dispatch: the receiver is a type name, not a value. Without this
        // guard the branch speculatively lowered `Box` as a variable, marked
        // the body lowering-failed, and only the (layout-dependent, #783) loss
        // of that flag write let the fallback's complete body compile. The
        // static test runs only after the (rare) dyn hit — lookup_local is a
        // linear scan and must not run per method call.
        if self.sema.dyn_trait_symbol_for_type(recv_type) != 0:
            var dyn_recv_is_static = false
            if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
                let dyn_id_sym = self.ast.get_data0(self_expr)
                if self.lookup_local(dyn_id_sym) < 0 and self.sema.named_types.contains(dyn_id_sym):
                    dyn_recv_is_static = true
            if not dyn_recv_is_static:
                let dyn_fn_op = self.const_operand(ConstKind.CK_FN, method_sym, 0)
                let dyn_args: Vec[i32] = Vec.new()
                let dyn_recv_op = self.lower_expr(self_expr)
                self.consume_moved_operand(dyn_recv_op)
                dyn_args.push(dyn_recv_op)
                for dyn_ai in 0..arg_count:
                    let dyn_arg_op = self.lower_expr(self.ast.get_extra(arg_start + dyn_ai))
                    self.consume_moved_operand(dyn_arg_op)
                    dyn_args.push(dyn_arg_op)
                let dyn_args_id = self.body.new_call_args(dyn_args)
                self.body.set_call_intrinsic(dyn_args_id, MirIntrinsic.DYN_CALL)
                self.body.set_call_ast_node(dyn_args_id, node)
                var dyn_ret_ty = self.method_call_result_type(node)
                if dyn_ret_ty == 0:
                    dyn_ret_ty = self.sema.ty_void as i32
                let dyn_result = self.new_temp(dyn_ret_ty)
                let dyn_place = self.place_for_local(dyn_result)
                let dyn_next = self.new_block()
                self.terminate(TermKind.TK_CALL, dyn_fn_op, dyn_args_id, dyn_place, dyn_next)
                self.switch_to(dyn_next)
                if self.sema.is_copy_frozen(dyn_ret_ty) != 0:
                    return self.body.new_operand(OperandKind.OK_COPY, dyn_place)
                return self.body.new_operand(OperandKind.OK_MOVE, dyn_place)

        // A bare method symbol is unresolved only when Sema did not record a
        // concrete signature for this call. Inherent impl methods may legitimately
        // use the bare symbol, so symbol equality alone is not a dispatch test.
        // Generic method symbols keep the
        // GENERIC_CALL handoff so codegen can monomorphize the receiver-specific
        // method instead of looking for an eager function body.
        // Route through MirIntrinsic.GENERIC_CALL so codegen's gen_call handles it
        // (disc enums, from_int, Option methods, concrete/generic struct methods, etc.).
        let recorded_method_sig_opt = self.sema.resolved_call_sigs.get(node)
        let has_recorded_method_sig = recorded_method_sig_opt.is_some()
        let recorded_method_sig: i32 = if has_recorded_method_sig: recorded_method_sig_opt.unwrap() else: -1
        // Machinery-vs-user classification lives in
        // require_generic_call_contract (the single decision point); here we
        // only need "did sema record a signature" to pick the lowering arm.
        let method_is_unresolved = callee_sym == method_sym and not has_recorded_method_sig
        if method_is_unresolved or self.sym_is_generic_fn(callee_sym):
                let gc_fn_op = self.const_operand(ConstKind.CK_FN, callee_sym, 0)
                let gc_args: Vec[i32] = Vec.new()
                let gc_sig_idx = if has_recorded_method_sig: recorded_method_sig else: self.call_sig_for_sym(callee_sym)
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
                    let gc_recv_op =
                        if self.has_contextual_copy_adjustment(self_expr) != 0:
                            self.lower_contextual_copy_adjustment(self_expr)
                        else if self.callee_has_move_self(callee_sym):
                            let gc_recv_place = self.lower_expr_place(self_expr)
                            self.body.new_operand(OperandKind.OK_MOVE, gc_recv_place)
                        else:
                            self.lower_generic_receiver_arg(self_expr, method_sym, gc_sig_idx)
                    if self.callee_has_move_self(callee_sym):
                        self.consume_moved_operand(gc_recv_op)
                    gc_args.push(gc_recv_op)
                let gc_has_resolved_args = self.sema.has_resolved_call_args(node)
                let gc_arg_count = if gc_has_resolved_args != 0: self.sema.get_resolved_call_arg_count(node) else: arg_count
                let gc_param_offset = if gc_is_static: 0 else: 1
                for gc_mai in 0..gc_arg_count:
                    let gc_ma_node = if gc_has_resolved_args != 0: self.sema.get_resolved_call_arg(node, gc_mai) else: self.ast.get_extra(arg_start + gc_mai)
                    if self.ast.kind(gc_ma_node) != NodeKind.NK_CLOSURE:
                        gc_args.push(self.lower_call_arg(gc_ma_node, gc_sig_idx, 0, gc_mai + gc_param_offset))
                    else:
                        gc_args.push(self.const_operand(ConstKind.CK_INT, 0, self.sema.ty_i32))
                let gc_args_id = self.body.new_call_args(gc_args)
                self.body.set_call_intrinsic(gc_args_id, MirIntrinsic.GENERIC_CALL)
                self.require_generic_call_contract(gc_args_id, callee_sym, method_sym, self_expr, has_recorded_method_sig, "method-gc")
                self.body.set_call_ast_node(gc_args_id, node)
                self.record_call_contract(gc_args_id, node, gc_sig_idx)
                var gc_ret_ty = self.method_call_result_type(node)
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
        if self.sema.qualified_extension_call_nodes.contains(node):
            is_static_call = true
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
        // §9.5/#641a: a `mut self` callee borrows the receiver — pass OK_COPY of
        // the caller's place (via the same autoderef discipline the GENERIC_CALL
        // path uses) instead of OK_MOVE + consume. Consuming receivers (`move
        // self` and legacy unflagged `self: T`) keep the plain-arg move path.
        var recv_op = -1
        if not is_static_call:
            if self.has_contextual_copy_adjustment(self_expr) != 0:
                recv_op = self.lower_contextual_copy_adjustment(self_expr)
            else if self.callee_has_mut_self(callee_sym):
                recv_op = self.lower_receiver_with_method_autoderef_for_method(self_expr, method_sym)
            else if self.callee_has_move_self(callee_sym) and self.ast.kind(self_expr) == NodeKind.NK_IDENT and self.lookup_local(self.ast.get_data0(self_expr)) >= 0:
                // §9.5/#D5: a `move self` receiver that is a caller-owned LOCAL is
                // CONSUMED — lower it as OK_MOVE of the caller's place and consume it
                // so the caller does NOT also drop it (the callee owns and drops it;
                // see lower_fn_with_sig). Without this the receiver flows through
                // lower_call_arg, which keeps the caller's drop for a share-place
                // param → double free when the callee returns self or a field of self.
                // Only locals need this: an rvalue/temporary receiver (enum variant,
                // struct literal, call result) has no caller binding to double-drop,
                // and lower_expr_place cannot address it — it flows through the arg
                // path below, which materializes it into a temp.
                let mv_recv_place = self.lower_expr_place(self_expr)
                recv_op = self.body.new_operand(OperandKind.OK_MOVE, mv_recv_place)
                self.consume_moved_operand(recv_op)
            else:
                arg_nodes.push(self_expr)
        let has_resolved_method_args = self.sema.has_resolved_call_args(node)
        let method_arg_count = if has_resolved_method_args != 0: self.sema.get_resolved_call_arg_count(node) else: arg_count
        for i in 0..method_arg_count:
            let method_arg = if has_resolved_method_args != 0: self.sema.get_resolved_call_arg(node, i) else: self.ast.get_extra(arg_start + i)
            arg_nodes.push(method_arg)

        let ret_ty = self.method_call_result_type(node)
        self.lower_call_with_arg_nodes_recv(fn_op, callee_sym, recv_op, arg_nodes, ret_ty, node)

    mut fn method_call_result_type(node: i32) -> i32:
        let pipeline_ret = self.sema.pipeline_call_return_types.get(node)
        if pipeline_ret.is_some():
            return pipeline_ret.unwrap()
        self.expr_type(node)

    // D22: an observer intrinsic's probe argument (HashMap/HashSet get and
    // contains key, Vec.contains element) is read transiently by the runtime;
    // the caller keeps ownership. A &K argument reads the same header through
    // one deref. An owned argument shares its place bitwise (OK_COPY, never
    // consumed); an rvalue lowers through lower_expr_place, which registers a
    // statement temp so the temporary still drops exactly once.
    mut fn lower_observer_probe_arg(arg_node: i32) -> i32:
        let arg_ty = self.expr_type(arg_node)
        let resolved = if arg_ty != 0: self.sema.resolve_alias(arg_ty as TypeId) else: 0
        if self.sema.get_type_kind(resolved) == TypeKind.TY_REF:
            // #747 instance D: when Sema recorded a D22 contextual-copy
            // adjustment on this arg, lower_expr consumes it and already yields
            // the deref'd owned key value. Materializing that VALUE at the ref
            // type and dereferencing again reads memory at the key's value
            // (stamp_move_site_liveness segfaulted on `contains(root)` with
            // root: &i32). Same guard the f-string ref path already carries.
            if self.has_contextual_copy_adjustment(arg_node) != 0:
                return self.lower_expr(arg_node)
            let ref_op = self.lower_expr(arg_node)
            let ref_place = self.materialize_operand(ref_op, resolved as i32, self.ast.get_start(arg_node))
            return self.body.new_operand(OperandKind.OK_COPY, self.new_deref_place(ref_place))
        let place = self.lower_expr_place(arg_node)
        if self.place_type_is_str(place) != 0:
            self.mark_string_place_copied(place)
        self.body.new_operand(OperandKind.OK_COPY, place)

    // #747: str reader intrinsics observe their needle/delim/pattern
    // arguments — the runtime reads the bytes transiently and every result
    // is an independent owned value (rt copies; no view returns), so the
    // caller keeps ownership. The checker already models these as borrows
    // (only method_arg_stores_value args consume); consuming them in MIR was
    // the same moved-arg-reset class as extern str args.
    fn str_intrinsic_observer_arg(intrinsic: MirIntrinsic, i: i32) -> i32:
        if i == 0 and (intrinsic == MirIntrinsic.STR_CONTAINS or intrinsic == MirIntrinsic.STR_STARTS_WITH or intrinsic == MirIntrinsic.STR_ENDS_WITH or intrinsic == MirIntrinsic.STR_FIND or intrinsic == MirIntrinsic.STR_INDEX_OF or intrinsic == MirIntrinsic.STR_SPLIT):
            return 1
        if (i == 0 or i == 1) and intrinsic == MirIntrinsic.STR_REPLACE:
            return 1
        0

    mut fn lower_intrinsic_call(intrinsic: MirIntrinsic, self_expr: i32, method_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
        // Emit a call terminator with a ConstKind.CK_FN operand and intrinsic tag.
        // The ConstKind.CK_FN sym is meaningless — codegen dispatches by intrinsic kind.
        let fn_op = self.const_operand(ConstKind.CK_FN, method_sym, self.sema.ty_void)

        // Build argument operands. For static calls (Vec.new, HashMap.new),
        // the receiver is a type ident — skip it. For instance methods, include it.
        let is_static = intrinsic == MirIntrinsic.VEC_NEW or intrinsic == MirIntrinsic.FIXED_STRING_NEW or intrinsic == MirIntrinsic.VEC_WITH_CAPACITY or intrinsic == MirIntrinsic.MAP_NEW or intrinsic == MirIntrinsic.SLOTMAP_NEW
        let call_args: Vec[i32] = Vec.new()
        var recv_type_for_args = 0
        if not is_static:
            let recv_ty = self.expr_type(self_expr)
            recv_type_for_args = self.autoderef_result_type_for_method(recv_ty, method_sym)
            if intrinsic == MirIntrinsic.FIBER_IS_DONE or intrinsic == MirIntrinsic.FIBER_WAS_CANCELLED_RETURN:
                let recv_autoderef_op = self.lower_receiver_with_method_autoderef_for_method(self_expr, method_sym)
                let recv_place = self.materialize_operand(recv_autoderef_op, recv_type_for_args, self.ast.get_start(self_expr))
                let fid_place = self.body.new_field_place(recv_place, 0, self.sema.ty_i32 as i32)
                call_args.push(self.body.new_operand(OperandKind.OK_COPY, fid_place))
            else:
                let recv_resolved = if recv_ty != 0: self.sema.resolve_alias(recv_ty as TypeId) else: 0
                let recv_kind = self.sema.get_type_kind(recv_resolved)
                let raw_pointer_option_receiver = recv_kind == TypeKind.TY_PTR and (intrinsic == MirIntrinsic.OPT_UNWRAP or intrinsic == MirIntrinsic.OPT_EXPECT or intrinsic == MirIntrinsic.OPT_IS_SOME or intrinsic == MirIntrinsic.OPT_IS_NONE or intrinsic == MirIntrinsic.OPT_FILTER)
                let borrowed_payload_eliminator = recv_kind == TypeKind.TY_REF and self.sema.get_type_d1(recv_resolved) == 0 and (intrinsic == MirIntrinsic.OPT_UNWRAP or intrinsic == MirIntrinsic.OPT_EXPECT)
                var recv_op = 0
                let recv_owner = self.sema.method_owner_symbol_for_type(recv_type_for_args)
                if self.has_contextual_copy_adjustment(self_expr) != 0:
                    recv_op = self.lower_contextual_copy_adjustment(self_expr)
                else if borrowed_payload_eliminator:
                    // D22 exact-payload elimination observes a borrowed carrier
                    // in place. Keep the &Option/&Result operand; codegen extracts
                    // a payload address instead of moving the carrier value.
                    recv_op = self.lower_expr(self_expr)
                else if recv_owner != 0 and self.sema.builtin_method_requires_move_receiver(recv_owner, method_sym) != 0:
                    let recv_place = self.lower_expr_place(self_expr)
                    recv_op = self.body.new_operand(OperandKind.OK_MOVE, recv_place)
                else if raw_pointer_option_receiver:
                    recv_op = self.lower_expr(self_expr)
                else:
                    recv_op = self.lower_receiver_with_method_autoderef_for_method(self_expr, method_sym)
                let channel_endpoint_method = intrinsic == MirIntrinsic.CHAN_SEND or intrinsic == MirIntrinsic.CHAN_RECV or intrinsic == MirIntrinsic.CHAN_CLOSE
                if intrinsic != MirIntrinsic.FIBER_CANCEL and not channel_endpoint_method:
                    self.consume_moved_operand(recv_op)
                call_args.push(recv_op)
        for i in 0..arg_count:
            let arg_node = self.ast.get_extra(arg_start + i)
            // D22: get/contains observe their key/probe argument — the runtime
            // reads it transiently and the caller keeps ownership. Never lower
            // it as a consuming move (#747: a moved str key was blanked after
            // the first lookup, so every later use of the key read empty).
            // #747: str reader needles (contains/starts_with/…/replace/split)
            // are the same observer class.
            if (i == 0 and (intrinsic == MirIntrinsic.MAP_GET or intrinsic == MirIntrinsic.MAP_CONTAINS or intrinsic == MirIntrinsic.VEC_CONTAINS)) or self.str_intrinsic_observer_arg(intrinsic, i) != 0:
                call_args.push(self.lower_observer_probe_arg(arg_node))
                continue
            let arg_op = self.lower_method_arg_with_expected(recv_type_for_args, method_sym, arg_node, i)
            self.consume_moved_operand(arg_op)
            call_args.push(arg_op)
        if intrinsic == MirIntrinsic.OPT_UNWRAP or intrinsic == MirIntrinsic.OPT_EXPECT:
            call_args.push(self.source_location_operand(node))

        let args_id = self.body.new_call_args(call_args)
        var ret_type = self.method_call_result_type(node)
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

        if self.sema.is_copy_frozen(ret_type) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_vtable_call(dyn_expr: i32, _trait_sym: i32, method_sym: i32, args_start: i32, args_count: i32, node: i32) -> i32:
        // Conservative lowering: treat as method call on dynamic receiver.
        self.lower_method_call(dyn_expr, method_sym, args_start, args_count, node)

    mut fn cancel_scheduled_value_drop_for_receiver_expr(expr: i32):
        if expr == 0:
            return
        let kind = self.ast.kind(expr)
        if kind == NodeKind.NK_GROUPED:
            self.cancel_scheduled_value_drop_for_receiver_expr(self.ast.get_data0(expr))
            return
        if kind == NodeKind.NK_CALL:
            return
        if kind == NodeKind.NK_FIELD_ACCESS:
            let root_sym = self.place_expr_root_symbol(expr)
            if root_sym == 0 or self.lookup_local(root_sym) < 0:
                return
            // A Copy field read (e.g. a raw pointer or int field) copies a value and
            // carries no owned buffer out, so it must NOT mark the field moved. Marking
            // a Copy field of a Drop struct moved degrades the owner's whole-value Drop
            // into a partial drop that emits nothing (the fields are not individually
            // needs-drop) — silently bypassing the user `Drop` impl and leaking. Only an
            // owning (non-Copy) field read moves storage out of the projection.
            let field_ty = self.expr_type(expr)
            if field_ty != 0 and self.sema.is_copy_frozen(field_ty) != 0:
                return
            // #780: a str field returned through a shared borrow under an
            // owned-str demand is CLONED by the NK_FIELD_ACCESS value arm
            // (this frame doesn't own the place), so it must not be marked
            // moved or blanked — the caller keeps it. View demands (-> &str)
            // keep the historical place/auto-ref path.
            let ce_owned_demand = self.expected_type != 0 and self.type_id_is_str(self.sema.resolve_alias(self.expected_type as TypeId) as i32) != 0
            if ce_owned_demand and field_ty != 0 and self.type_id_is_str(field_ty) != 0 and self.field_read_base_is_shared_borrow(expr) != 0:
                return
            let recv_place = self.lower_expr_place(expr)
            self.mark_place_field_moved(recv_place)
            // #697/D17: a returned-out field of a base not dropped in this
            // function (share-place param under the weakened effects) needs the
            // runtime blank — it lands at the return flush, after the value is
            // read into the return place.
            self.queue_field_move_reset(recv_place)
            return
        if kind != NodeKind.NK_IDENT:
            return
        let sym = self.ast.get_data0(expr)
        let local = self.lookup_local(sym)
        if local >= 0:
            self.cancel_scheduled_value_drop_for_local(local)

    mut fn enum_accessor_payload_operand(enum_place: i32, enum_ty: i32, variant_sym: i32, variant_index: i32, accessor_kind: i32, result_ty: i32, span: i32) -> i32:
        let payloads = self.sema.enum_variant_payload_types_frozen(enum_ty, variant_sym)
        let payload_count = payloads.len() as i32
        let unwrapped_ty = self.sema.try_unwrapped_type_frozen(result_ty) as i32
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
            let op_kind = if self.sema.is_copy_frozen(payload_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
            return self.body.new_operand(op_kind, field_place)

        let tuple_fields: Vec[i32] = Vec.new()
        let tuple_names: Vec[i32] = Vec.new()
        let tuple_elem_start = if self.sema.get_type_kind(self.sema.resolve_alias(unwrapped_ty as TypeId)) == TypeKind.TY_TUPLE: self.sema.get_type_d0(self.sema.resolve_alias(unwrapped_ty as TypeId)) else: 0
        for pi in 0..payload_count:
            let payload_ty = payloads.get(pi as i64)
            let field_place = self.body.new_field_place(variant_place, pi, payload_ty)
            if accessor_kind == 3 or accessor_kind == 4:
                let ref_mut = if accessor_kind == 4: 1 else: 0
                let elem_ty = if tuple_elem_start > 0: self.sema.type_extra.get((tuple_elem_start + pi) as i64) else: self.sema.find_exact_type(TypeKind.TY_REF, payload_ty, ref_mut, 0) as i32
                let borrow_kind = if accessor_kind == 4: BorrowKind.EXCLUSIVE else: BorrowKind.SHARED
                let ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, borrow_kind, field_place, 0)
                let ref_tmp = self.new_temp(elem_ty)
                let ref_place = self.place_for_local(ref_tmp)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, ref_place, ref_rv, span)
                tuple_fields.push(self.body.new_operand(OperandKind.OK_COPY, ref_place))
            else:
                let op_kind = if self.sema.is_copy_frozen(payload_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
                tuple_fields.push(self.body.new_operand(op_kind, field_place))
            tuple_names.push(0)
        let tuple_fid = self.body.new_agg_fields(tuple_fields, tuple_names)
        let tuple_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, tuple_fid, 0)
        let tuple_tmp = self.new_temp(unwrapped_ty)
        let tuple_place = self.place_for_local(tuple_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, tuple_place, tuple_rv, span)
        self.body.new_operand(if self.sema.is_copy_frozen(unwrapped_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, tuple_place)

    mut fn assign_enum_variant_to_place(result_place: i32, result_ty: i32, variant_sym: i32, fields: &Vec[i32], span: i32):
        let names: Vec[i32] = Vec.new()
        for _ in 0..fields.len() as i32:
            names.push(0)
        let fid = self.body.new_agg_fields(fields, names)
        let tag = self.enum_variant_discriminant_for_type(result_ty, variant_sym)
        let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fid, tag)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, result_place, rv, span)
        // #693: moved payload operands must be consumed (see the ctor twin).
        for cfi in 0..fields.len() as i32:
            self.consume_moved_operand(fields.get(cfi as i64))

    mut fn lower_context_error_operand(message_op: i32, source_op: i32, context_error_ty: i32, span: i32) -> i32:
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

    mut fn lower_enum_accessor_call(self_expr: i32, method_sym: i32, node: i32) -> i32:
        var enum_ty = self.expr_type(self_expr)
        if enum_ty == 0 or enum_ty == self.sema.ty_void as i32:
            enum_ty = self.type_receiver_type(self_expr)
        if enum_ty == 0 or enum_ty == self.sema.ty_void as i32:
            self.mark_unsupported()
            return self.unit_operand()
        enum_ty = self.recorded_autoderef_result_type(self_expr, self.sema.auto_deref_ref_ptr_type(enum_ty as TypeId) as i32)

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
        if accessor_kind == 2 and self.sema.is_copy_frozen(enum_ty) == 0:
            self.emit_drop_stmt(recv_place, "enum-accessor", span)
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
        self.body.new_operand(if self.sema.is_copy_frozen(result_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, result_place)

    mut fn emit_cleanup_awaits_from(task_ops: &Vec[i32], start_idx: i32, node: i32):
        var ci = start_idx
        while ci < task_ops.len() as i32:
            let task_op = task_ops.get(ci as i64)
            self.emit_task_cancel_call(task_op, MirIntrinsic.FIBER_CANCEL, node)
            self.lower_cleanup_await(task_op, node)
            ci = ci + 1

    mut fn lower_question_mark_value(value_op: i32, value_ty: i32, result_ty_hint: i32, node: i32, span_node: i32, cleanup_task_ops: &Vec[i32], cleanup_start_idx: i32) -> i32:
        let value_place = self.materialize_operand(value_op, value_ty, self.ast.get_start(span_node))

        // #605/#606: `?` decomposes the Result/Option — its active payload is moved
        // out on the pass path, or into the propagated error on the fail path. Consume
        // the materialized scrutinee so the enum payload-drop does not also free the
        // extracted value (double-free).
        let qm_scrut_local = mir_place_plain_local(&self.body, value_place)
        if qm_scrut_local >= 0:
            self.cancel_stmt_temp_for_local(qm_scrut_local)
            self.cancel_scheduled_value_drop_for_local(qm_scrut_local)
            self.mark_local_value_moved(qm_scrut_local)

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
                    let conversion_chain = self.sema.error_conversion_chain_frozen(target_err_ty, source_err_ty)
                    if conversion_chain.found == 0 or conversion_chain.ambiguous != 0:
                        self.mark_unsupported()
                    else:
                        var ci = conversion_chain.variant_syms.len() as i32 - 1
                        while ci >= 0:
                            let wrapped_ty = conversion_chain.type_ids.get(ci as i64)
                            let conversion_variant = conversion_chain.variant_syms.get(ci as i64)
                            let wrapped_err_local = self.new_temp(wrapped_ty)
                            let wrapped_err_place = self.place_for_local(wrapped_err_local)
                            let wrapped_fields: Vec[i32] = Vec.new()
                            wrapped_fields.push(target_err_op)
                            self.assign_enum_variant_to_place(wrapped_err_place, wrapped_ty, conversion_variant, wrapped_fields, self.ast.get_start(span_node))
                            target_err_op = self.operand_for_place(wrapped_err_place, wrapped_ty)
                            if ci == 0:
                                break
                            ci = ci - 1
                        let err_fields: Vec[i32] = Vec.new()
                        err_fields.push(target_err_op)
                        self.assign_enum_variant_to_place(ret_place, ret_ty, self.sema.syms.err, err_fields, self.ast.get_start(span_node))
        else if source_option_ty != 0:
            if target_option_ty == 0:
                self.mark_unsupported()
            else:
                let none_fields: Vec[i32] = Vec.new()
                self.assign_enum_variant_to_place(ret_place, ret_ty, self.sema.syms.none, none_fields, self.ast.get_start(span_node))
        else:
            let fail_op = self.body.new_operand(OperandKind.OK_MOVE, value_place)
            self.assign_operand_to_place(ret_place, fail_op, self.ast.get_start(span_node))
        self.emit_cleanup_awaits_from(cleanup_task_ops, cleanup_start_idx, node)
        // D17: moves already executed in this statement (field blanks, move-arg
        // temps) must land before the early error return — the enclosing
        // statement's flush is never reached on this path.
        self.flush_pending_resets()
        self.emit_errdefers_for_return()
        self.emit_defers_for_return()
        self.emit_drops_for_return()
        self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

        // Extract Ok payload via ProjKind.PK_DOWNCAST + field access
        var result_ty = result_ty_hint
        if result_ty == 0 or result_ty == self.sema.ty_void:
            result_ty = self.sema.try_unwrapped_type_frozen(value_ty)
        if result_ty == 0 or result_ty == self.sema.ty_void:
            result_ty = value_ty
        self.switch_to(pass_bb)
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)
        let downcast_place = self.body.new_downcast_place(value_place, self.success_variant_index(), value_ty)
        let payload_place = self.body.new_field_place(downcast_place, 0, result_ty)
        let pass_op = self.body.new_operand(if self.sema.is_copy_frozen(result_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, payload_place)
        self.assign_operand_to_place(result_place, pass_op, self.ast.get_start(span_node))
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        if self.sema.is_copy_frozen(result_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_tuple_await_question_mark(await_node: i32, question_node: i32) -> i32:
        let inner = self.ast.get_data0(await_node)
        if inner == 0 or self.ast.kind(inner) != NodeKind.NK_TUPLE:
            return self.unit_operand()
        let extra = self.ast.get_data0(inner)
        let count = self.ast.get_data1(inner)
        let await_tuple_ty = self.expr_type(await_node)
        let result_tuple_ty = self.expr_type(question_node)

        let task_ops: Vec[i32] = Vec.new()
        let tq_owns: Vec[i32] = Vec.new()
        for i in 0..count:
            let elem = self.ast.get_extra(extra + i)
            tq_owns.push(self.await_task_owns_result(elem))
            self.cancel_scheduled_value_drop_for_receiver_expr(elem)
            task_ops.push(self.lower_expr(elem))

        let fields: Vec[i32] = Vec.new()
        let names: Vec[i32] = Vec.new()
        for i in 0..count:
            let elem_node = self.ast.get_extra(extra + i)
            let task_ty = self.expr_type(elem_node)
            let result_ty = self.tuple_elem_type(await_tuple_ty, i)
            let payload_ty = self.tuple_elem_type(result_tuple_ty, i)
            let awaited = self.lower_single_await(task_ops.get(i as i64), result_ty, task_ty, await_node, tq_owns.get(i as i64))
            let payload = self.lower_question_mark_value(awaited, result_ty, payload_ty, question_node, await_node, &task_ops, i + 1)
            fields.push(payload)
            names.push(0)

        let fid = self.body.new_agg_fields(fields, names)
        let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, fid, 0)
        let tmp = self.new_temp(result_tuple_ty)
        let place = self.place_for_local(tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(question_node))
        self.body.new_operand(if self.sema.is_copy_frozen(result_tuple_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, place)

    // TODO(D22): builtin Option/Result `?` has the same transparent-origin
    // contract as user Try. Preserve the exact payload type and the recorded
    // origin set through this generated branch.
    mut fn lower_question_mark(expr: i32, node: i32) -> i32:
        if self.sema.try_branch_fns.contains(node):
            return self.lower_user_try_question_mark(expr, node)
        if self.ast.kind(expr) == NodeKind.NK_AWAIT:
            let await_inner = self.ast.get_data0(expr)
            if await_inner != 0 and self.ast.kind(await_inner) == NodeKind.NK_TUPLE:
                return self.lower_tuple_await_question_mark(expr, node)

        let cleanup_task_ops: Vec[i32] = Vec.new()
        let value_op = self.lower_expr(expr)
        let value_ty = self.expr_type(expr)
        // #605/#606: `?` consumes its operand; cancel a named source's drop so its
        // payload (now propagated/extracted) is not double-freed.
        self.cancel_scheduled_value_drop_for_receiver_expr(expr)
        let question_ty = self.expr_type(node)
        self.lower_question_mark_value(value_op, value_ty, question_ty, node, expr, &cleanup_task_ops, cleanup_task_ops.len() as i32)

    // TODO(D22): consume one Sema-resolved Join[T,U] decision here. Do not
    // re-derive the result from payload Copy-ness; materialize only arms Sema
    // marked for owned demand and retain unioned origins for a view result.
    mut fn lower_double_question(expr: i32, default_expr: i32, node: i32) -> i32:
        let value_op = self.lower_expr(expr)
        let value_ty = self.expr_type(expr)
        let value_place = self.materialize_operand(value_op, value_ty, self.ast.get_start(expr))
        let carrier_arm = self.contextual_join_arm_index_for_role(node, D22_JOIN_ROLE_CARRIER_PAYLOAD)
        if carrier_arm < 0:
            self.mark_unsupported()
            return self.unit_operand()
        let payload_ty: i32 = self.sema.contextual_join_arm_types.get(carrier_arm as i64)

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
            result_ty = self.sema.try_unwrapped_type_frozen(value_ty)
        if result_ty == 0 or result_ty == self.sema.ty_void:
            result_ty = value_ty
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)

        self.switch_to(some_bb)
        let downcast_place = self.body.new_downcast_place(value_place, self.success_variant_index(), value_ty)
        let payload_place = self.body.new_field_place(downcast_place, 0, payload_ty)
        let some_op = self.lower_contextual_join_place_arm(node, D22_JOIN_ROLE_CARRIER_PAYLOAD, payload_place, self.ast.get_start(expr))
        self.assign_operand_to_place(result_place, some_op, self.ast.get_start(expr))
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(none_bb)
        // #772: a stmt-temp frame + divergence guard, exactly like lower_if's
        // branches. A diverging default (`?? return e`) leaves a Unit operand
        // in its unreachable continuation; assigning it into the typed join
        // result is the void-into-int/str invalid MIR the validator rejects.
        let dq_temp_frame = self.push_stmt_temp_frame()
        let default_op = self.lower_expr(default_expr)
        if self.sema.body_can_fall_through(default_expr) != 0:
            self.assign_operand_to_place(result_place, default_op, self.ast.get_start(default_expr))
        self.finish_stmt_temp_frame(dq_temp_frame)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        if self.sema.is_copy_frozen(result_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    fn is_option_or_result_type(type_id: i32) -> i32:
        if type_id == 0:
            return 0
        let resolved = self.sema.resolve_alias(type_id as TypeId)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        let base = self.sema.get_generic_inst_base(resolved as i32)
        if base == self.sema.syms.option or base == self.sema.syms.result: 1 else: 0

    fn is_option_type(type_id: i32) -> i32:
        if type_id == 0:
            return 0
        let resolved = self.sema.resolve_alias(type_id as TypeId)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        if self.sema.get_generic_inst_base(resolved as i32) == self.sema.syms.option: 1 else: 0

    fn is_result_type(type_id: i32) -> i32:
        if type_id == 0:
            return 0
        let resolved = self.sema.resolve_alias(type_id as TypeId)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        if self.sema.get_generic_inst_base(resolved as i32) == self.sema.syms.result: 1 else: 0

    fn is_vec_type(type_id: i32) -> i32:
        if type_id == 0:
            return 0
        let resolved = self.sema.resolve_alias(type_id as TypeId)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        if self.sema.get_generic_inst_base(resolved as i32) == self.sema.syms.vec: 1 else: 0

    mut fn lower_owned_receiver_place(self_expr: i32, value_ty: i32) -> i32:
        let source_place = self.lower_expr_place(self_expr)
        let value_op = self.body.new_operand(OperandKind.OK_MOVE, source_place)
        // #724 acceptance chase: an UNREGISTERED move leaves the source's
        // scheduled drop live — r.err() extracted the payload while r's
        // enum drop still freed it (double free / freed-payload reads).
        self.consume_moved_operand(value_op)
        self.materialize_operand(value_op, value_ty, self.ast.get_start(self_expr))

    mut fn emit_vec_new_into(vec_place: i32, span: i32):
        let new_sym = self.sema.syms.new
        let fn_op = self.const_operand(ConstKind.CK_FN, new_sym, self.sema.ty_void)
        let args: Vec[i32] = Vec.new()
        let args_id = self.body.new_call_args(args)
        self.body.set_call_intrinsic(args_id, MirIntrinsic.VEC_NEW)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, vec_place, next_bb)
        self.switch_to(next_bb)

    mut fn emit_vec_len_into(vec_place: i32, len_place: i32, span: i32):
        let len_sym = self.sema.syms.len
        let fn_op = self.const_operand(ConstKind.CK_FN, len_sym, self.sema.ty_void)
        let args: Vec[i32] = Vec.new()
        args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
        let args_id = self.body.new_call_args(args)
        self.body.set_call_intrinsic(args_id, MirIntrinsic.VEC_LEN)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, len_place, next_bb)
        self.switch_to(next_bb)

    mut fn emit_vec_get_into(vec_place: i32, index_place: i32, elem_place: i32, span: i32):
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

    // Element view: VEC_GET_REF yields &T for the element at index without
    // copying it — the read lower_for_iter_ref uses for Drop-class elements.
    mut fn emit_vec_get_ref_into(vec_place: i32, index_place: i32, elem_place: i32, span: i32):
        let args: Vec[i32] = Vec.new()
        args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
        args.push(self.body.new_operand(OperandKind.OK_COPY, index_place))
        let args_id = self.body.new_call_args(args)
        self.body.set_call_intrinsic(args_id, MirIntrinsic.VEC_GET_REF)
        let next_bb = self.new_block()
        let unit = self.unit_operand()
        self.terminate(TermKind.TK_CALL, unit, args_id, elem_place, next_bb)
        self.switch_to(next_bb)

    mut fn emit_vec_push(vec_place: i32, elem_op: i32, span: i32):
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

    mut fn emit_map_new_into(map_place: i32, span: i32):
        let new_sym = self.sema.syms.new
        let fn_op = self.const_operand(ConstKind.CK_FN, new_sym, self.sema.ty_void)
        let args: Vec[i32] = Vec.new()
        let args_id = self.body.new_call_args(args)
        self.body.set_call_intrinsic(args_id, MirIntrinsic.MAP_NEW)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, map_place, next_bb)
        self.switch_to(next_bb)

    mut fn emit_map_insert(map_place: i32, key_op: i32, val_op: i32, is_set: i32, span: i32):
        let insert_sym = self.sema.syms.insert
        let fn_op = self.const_operand(ConstKind.CK_FN, insert_sym, self.sema.ty_void)
        let args: Vec[i32] = Vec.new()
        args.push(self.body.new_operand(OperandKind.OK_COPY, map_place))
        args.push(key_op)
        if is_set == 0:
            args.push(val_op)
        let args_id = self.body.new_call_args(args)
        self.body.set_call_intrinsic(args_id, MirIntrinsic.MAP_INSERT)
        let result_local = self.new_temp(self.sema.ty_void)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)

    mut fn lower_option_transpose_method(self_expr: i32, arg_count: i32, node: i32) -> i32:
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

    mut fn lower_result_transpose_method(self_expr: i32, arg_count: i32, node: i32) -> i32:
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

    mut fn tuple_operand_from_fields(fields: &Vec[i32], result_ty: i32, span: i32) -> i32:
        let names: Vec[i32] = Vec.new()
        for _ in 0..fields.len() as i32:
            names.push(0)
        let fid = self.body.new_agg_fields(fields, names)
        let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, fid, 0)
        let tmp = self.new_temp(result_ty)
        let place = self.place_for_local(tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, span)
        self.operand_for_place(place, result_ty)

    mut fn clone_or_copy_place(payload_place: i32, payload_ty: i32, node: i32) -> i32:
        if self.sema.is_copy_frozen(payload_ty) != 0:
            return self.operand_for_place(payload_place, payload_ty)
        let clone_fn_opt = self.sema.clone_contract_fns.get(node)
        let clone_sig_opt = self.sema.clone_contract_sigs.get(node)
        let clone_mono_opt = self.sema.clone_contract_mono_syms.get(node)
        if clone_fn_opt.is_none() or clone_sig_opt.is_none() or clone_mono_opt.is_none():
            self.mark_unsupported()
            return self.operand_for_place(payload_place, payload_ty)
        let clone_fn: i32 = clone_fn_opt.unwrap()
        let sig_idx: i32 = clone_sig_opt.unwrap()
        let mono_sym: i32 = clone_mono_opt.unwrap()
        let expected = if self.sema.sig_get_param_count(sig_idx) > 0: self.sema.sig_param_type(sig_idx, 0) else: 0
        let args: Vec[i32] = Vec.new()
        args.push(self.operand_for_place_arg(payload_place, payload_ty, expected, self.ast.get_start(node)))
        self.lower_resolved_call_with_operand_args_contract(clone_fn, args, payload_ty, node, sig_idx, mono_sym)

    mut fn lower_option_flatten_method(self_expr: i32, arg_count: i32, node: i32) -> i32:
        if arg_count != 0:
            self.mark_unsupported()
            return self.unit_operand()
        let span = self.ast.get_start(node)
        var value_ty = self.expr_type(self_expr)
        if value_ty == 0 or value_ty == self.sema.ty_void:
            value_ty = self.type_receiver_type(self_expr)
        let inner_option_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.option, 0)
        let result_ty = self.expr_type(node)
        if value_ty == 0 or inner_option_ty == 0 or result_ty == 0:
            self.mark_unsupported()
            return self.unit_operand()
        let value_place = self.lower_owned_receiver_place(self_expr, value_ty)
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)
        let some_bb = self.new_block()
        let none_bb = self.new_block()
        let join_bb = self.new_block()
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
        let some_downcast = self.body.new_downcast_place(value_place, some_idx, value_ty)
        let inner_place = self.body.new_field_place(some_downcast, 0, inner_option_ty)
        let inner_op = self.operand_for_place(inner_place, inner_option_ty)
        self.assign_operand_to_place(result_place, inner_op, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        self.operand_for_place(result_place, result_ty)

    mut fn lower_result_ok_err_method(self_expr: i32, method_name: &str, arg_count: i32, node: i32) -> i32:
        if arg_count != 0:
            self.mark_unsupported()
            return self.unit_operand()
        let span = self.ast.get_start(node)
        var value_ty = self.expr_type(self_expr)
        if value_ty == 0 or value_ty == self.sema.ty_void:
            value_ty = self.type_receiver_type(self_expr)
        let ok_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.result, 0)
        let err_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.result, 1)
        let result_ty = self.expr_type(node)
        let payload_ty = if method_name == "ok": ok_ty else: err_ty
        if value_ty == 0 or ok_ty == 0 or err_ty == 0 or result_ty == 0 or payload_ty == 0:
            self.mark_unsupported()
            return self.unit_operand()
        let value_place = self.lower_owned_receiver_place(self_expr, value_ty)
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)
        let wanted_bb = self.new_block()
        let other_bb = self.new_block()
        let join_bb = self.new_block()
        let wanted_variant = if method_name == "ok": self.sema.syms.ok else: self.sema.syms.err
        let disc = self.lower_enum_discriminant(value_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(self.enum_variant_discriminant_for_type(value_ty, wanted_variant))
        let targets: Vec[i32] = Vec.new()
        targets.push(wanted_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, disc, table, other_bb, 0)

        self.switch_to(other_bb)
        let none_fields: Vec[i32] = Vec.new()
        self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.none, none_fields, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(wanted_bb)
        let variant_idx = self.enum_variant_index_for_type(value_ty, wanted_variant)
        let downcast = self.body.new_downcast_place(value_place, variant_idx, value_ty)
        let payload_place = self.body.new_field_place(downcast, 0, payload_ty)
        let some_fields: Vec[i32] = Vec.new()
        let ok_err_payload_op = self.operand_for_place(payload_place, payload_ty)
        // Register the payload move so the materialized receiver temp's
        // drop skips what the Option now owns.
        self.consume_moved_operand(ok_err_payload_op)
        some_fields.push(ok_err_payload_op)
        self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, some_fields, span)
        // §2.5.1 reset-on-move, emitted directly on the moving path: blank
        // the extracted payload so the receiver temp's whole-enum scope drop
        // frees nothing. (The other_bb path keeps its payload — err() on an
        // Ok value must still drop the un-extracted Ok payload.)
        if self.sema.is_copy_frozen(payload_ty) == 0:
            let blank_zop = self.body.gen_zero_operand(payload_ty)
            let blank_rv = self.body.new_rvalue(RvalueKind.RK_USE, blank_zop, 0, 0)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, payload_place, blank_rv, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        self.operand_for_place(result_place, result_ty)

    mut fn lower_option_zip_method(self_expr: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
        if arg_count != 1:
            self.mark_unsupported()
            return self.unit_operand()
        let span = self.ast.get_start(node)
        var left_ty = self.expr_type(self_expr)
        if left_ty == 0 or left_ty == self.sema.ty_void:
            left_ty = self.type_receiver_type(self_expr)
        let right_ty = self.expr_type(self.ast.get_extra(arg_start))
        let left_elem_ty = self.generic_inst_arg_type(left_ty, self.sema.syms.option, 0)
        let right_elem_ty = self.generic_inst_arg_type(right_ty, self.sema.syms.option, 0)
        let result_ty = self.expr_type(node)
        let tuple_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.option, 0)
        if left_ty == 0 or right_ty == 0 or left_elem_ty == 0 or right_elem_ty == 0 or result_ty == 0 or tuple_ty == 0:
            self.mark_unsupported()
            return self.unit_operand()
        let left_place = self.lower_owned_receiver_place(self_expr, left_ty)
        let right_place = self.lower_owned_receiver_place(self.ast.get_extra(arg_start), right_ty)
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)
        let left_some_bb = self.new_block()
        let none_bb = self.new_block()
        let right_some_bb = self.new_block()
        let join_bb = self.new_block()

        let left_disc = self.lower_enum_discriminant(left_place)
        let left_vals: Vec[i32] = Vec.new()
        left_vals.push(self.enum_variant_discriminant_for_type(left_ty, self.sema.syms.some))
        let left_targets: Vec[i32] = Vec.new()
        left_targets.push(left_some_bb as i32)
        let left_table = self.body.new_switch_table(left_vals, left_targets)
        self.terminate(TermKind.TK_SWITCH_INT, left_disc, left_table, none_bb, 0)

        self.switch_to(left_some_bb)
        let right_disc = self.lower_enum_discriminant(right_place)
        let right_vals: Vec[i32] = Vec.new()
        right_vals.push(self.enum_variant_discriminant_for_type(right_ty, self.sema.syms.some))
        let right_targets: Vec[i32] = Vec.new()
        right_targets.push(right_some_bb as i32)
        let right_table = self.body.new_switch_table(right_vals, right_targets)
        self.terminate(TermKind.TK_SWITCH_INT, right_disc, right_table, none_bb, 0)

        self.switch_to(none_bb)
        let none_fields: Vec[i32] = Vec.new()
        self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.none, none_fields, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(right_some_bb)
        let left_idx = self.enum_variant_index_for_type(left_ty, self.sema.syms.some)
        let left_downcast = self.body.new_downcast_place(left_place, left_idx, left_ty)
        let left_payload_place = self.body.new_field_place(left_downcast, 0, left_elem_ty)
        let right_idx = self.enum_variant_index_for_type(right_ty, self.sema.syms.some)
        let right_downcast = self.body.new_downcast_place(right_place, right_idx, right_ty)
        let right_payload_place = self.body.new_field_place(right_downcast, 0, right_elem_ty)
        let tuple_fields: Vec[i32] = Vec.new()
        tuple_fields.push(self.operand_for_place(left_payload_place, left_elem_ty))
        tuple_fields.push(self.operand_for_place(right_payload_place, right_elem_ty))
        let tuple_op = self.tuple_operand_from_fields(tuple_fields, tuple_ty, span)
        let some_fields: Vec[i32] = Vec.new()
        some_fields.push(tuple_op)
        self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, some_fields, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        self.operand_for_place(result_place, result_ty)

    mut fn lower_option_unzip_method(self_expr: i32, arg_count: i32, node: i32) -> i32:
        if arg_count != 0:
            self.mark_unsupported()
            return self.unit_operand()
        let span = self.ast.get_start(node)
        var value_ty = self.expr_type(self_expr)
        if value_ty == 0 or value_ty == self.sema.ty_void:
            value_ty = self.type_receiver_type(self_expr)
        let tuple_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.option, 0)
        let tuple_resolved = self.sema.resolve_alias(tuple_ty)
        let result_ty = self.expr_type(node)
        if value_ty == 0 or tuple_ty == 0 or result_ty == 0 or self.sema.get_type_kind(tuple_resolved) != TypeKind.TY_TUPLE or self.sema.get_type_d1(tuple_resolved) != 2:
            self.mark_unsupported()
            return self.unit_operand()
        let elem_start = self.sema.get_type_d0(tuple_resolved)
        let left_elem_ty: i32 = self.sema.type_extra.get(elem_start as i64)
        let right_elem_ty: i32 = self.sema.type_extra.get((elem_start + 1) as i64)
        let result_resolved = self.sema.resolve_alias(result_ty)
        let result_start = self.sema.get_type_d0(result_resolved)
        let left_option_ty: i32 = self.sema.type_extra.get(result_start as i64)
        let right_option_ty: i32 = self.sema.type_extra.get((result_start + 1) as i64)
        let value_place = self.lower_owned_receiver_place(self_expr, value_ty)
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)
        let some_bb = self.new_block()
        let none_bb = self.new_block()
        let join_bb = self.new_block()

        let disc = self.lower_enum_discriminant(value_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(self.enum_variant_discriminant_for_type(value_ty, self.sema.syms.some))
        let targets: Vec[i32] = Vec.new()
        targets.push(some_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, disc, table, none_bb, 0)

        self.switch_to(none_bb)
        let left_none_local = self.new_temp(left_option_ty)
        let left_none_place = self.place_for_local(left_none_local)
        let left_none_fields: Vec[i32] = Vec.new()
        self.assign_enum_variant_to_place(left_none_place, left_option_ty, self.sema.syms.none, left_none_fields, span)
        let right_none_local = self.new_temp(right_option_ty)
        let right_none_place = self.place_for_local(right_none_local)
        let right_none_fields: Vec[i32] = Vec.new()
        self.assign_enum_variant_to_place(right_none_place, right_option_ty, self.sema.syms.none, right_none_fields, span)
        let none_tuple_fields: Vec[i32] = Vec.new()
        none_tuple_fields.push(self.operand_for_place(left_none_place, left_option_ty))
        none_tuple_fields.push(self.operand_for_place(right_none_place, right_option_ty))
        let none_tuple_op = self.tuple_operand_from_fields(none_tuple_fields, result_ty, span)
        self.assign_operand_to_place(result_place, none_tuple_op, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(some_bb)
        let some_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.some)
        let some_downcast = self.body.new_downcast_place(value_place, some_idx, value_ty)
        let tuple_place = self.body.new_field_place(some_downcast, 0, tuple_ty)
        let left_place = self.body.new_tuple_index_place(tuple_place, 0, left_elem_ty)
        let right_place = self.body.new_tuple_index_place(tuple_place, 1, right_elem_ty)
        let left_some_local = self.new_temp(left_option_ty)
        let left_some_place = self.place_for_local(left_some_local)
        let left_some_fields: Vec[i32] = Vec.new()
        left_some_fields.push(self.operand_for_place(left_place, left_elem_ty))
        self.assign_enum_variant_to_place(left_some_place, left_option_ty, self.sema.syms.some, left_some_fields, span)
        let right_some_local = self.new_temp(right_option_ty)
        let right_some_place = self.place_for_local(right_some_local)
        let right_some_fields: Vec[i32] = Vec.new()
        right_some_fields.push(self.operand_for_place(right_place, right_elem_ty))
        self.assign_enum_variant_to_place(right_some_place, right_option_ty, self.sema.syms.some, right_some_fields, span)
        let some_tuple_fields: Vec[i32] = Vec.new()
        some_tuple_fields.push(self.operand_for_place(left_some_place, left_option_ty))
        some_tuple_fields.push(self.operand_for_place(right_some_place, right_option_ty))
        let some_tuple_op = self.tuple_operand_from_fields(some_tuple_fields, result_ty, span)
        self.assign_operand_to_place(result_place, some_tuple_op, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        self.operand_for_place(result_place, result_ty)

    mut fn lower_vec_sequence_or_traverse_method(self_expr: i32, method_name: &str, arg_start: i32, arg_count: i32, node: i32) -> i32:
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
                wrapper_ty = self.sema.find_option_type_for(output_elem_ty)
            else:
                let result_err_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.result, 1)
                wrapper_ty = self.sema.find_result_type_for(output_elem_ty, result_err_ty)
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
        let success_payload_op = self.operand_for_place(success_payload_place, output_elem_ty)
        self.emit_vec_push(out_vec_place, success_payload_op, span)
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

    mut fn lower_option_combinator_method(self_expr: i32, method_name: &str, arg_start: i32, arg_count: i32, node: i32) -> i32:
        let explicit_owner = method_name == "copied" or method_name == "cloned"
        if explicit_owner:
            if arg_count != 0:
                self.mark_unsupported()
                return self.unit_operand()
        else if arg_count != 1:
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

        let value_place = if explicit_owner: self.lower_expr_place(self_expr) else: self.lower_owned_receiver_place(self_expr, value_ty)
        var mapper_op = 0
        if not explicit_owner:
            mapper_op = self.lower_expr(self.ast.get_extra(arg_start))

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
        if method_name == "or_else":
            let no_args: Vec[i32] = Vec.new()
            let fallback_op = self.lower_call_with_operand_args(mapper_op, no_args, result_ty, node)
            self.assign_operand_to_place(result_place, fallback_op, span)
        else:
            let none_fields: Vec[i32] = Vec.new()
            self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.none, none_fields, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(some_bb)
        let some_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.some)
        let downcast_place = self.body.new_downcast_place(value_place, some_idx, value_ty)
        let payload_place = self.body.new_field_place(downcast_place, 0, payload_ty)
        if method_name == "filter":
            let filter_args: Vec[i32] = Vec.new()
            // Sema types the predicate's parameter OWNED (`x => x > 3` checks x
            // as T), so pass by value. The old &T spelling was dormant: before
            // D22 `find_exact_type(TY_REF, T)` found nothing (no &T in the type
            // table) and fell back to by-value; D22 programs mint &T constantly,
            // which activated the mismatch (ptr passed, i32 expected).
            filter_args.push(self.operand_for_place(payload_place, payload_ty))
            let keep_op = self.lower_call_with_operand_args(mapper_op, filter_args, self.sema.ty_bool as i32, node)
            let keep_bb = self.new_block()
            let reject_bb = self.new_block()
            let keep_vals: Vec[i32] = Vec.new()
            keep_vals.push(1)
            let keep_targets: Vec[i32] = Vec.new()
            keep_targets.push(keep_bb as i32)
            let keep_table = self.body.new_switch_table(keep_vals, keep_targets)
            self.terminate(TermKind.TK_SWITCH_INT, keep_op, keep_table, reject_bb, 0)

            self.switch_to(keep_bb)
            let kept_fields: Vec[i32] = Vec.new()
            kept_fields.push(self.operand_for_place(payload_place, payload_ty))
            self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, kept_fields, span)
            self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

            self.switch_to(reject_bb)
            let rejected_fields: Vec[i32] = Vec.new()
            self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.none, rejected_fields, span)
            self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

            self.switch_to(join_bb)
            self.forget_string_flow_facts()
            return self.operand_for_place(result_place, result_ty)
        if method_name == "and_then":
            let call_args: Vec[i32] = Vec.new()
            call_args.push(self.operand_for_place(payload_place, payload_ty))
            let mapped_op = self.lower_call_with_operand_args(mapper_op, call_args, result_ty, node)
            self.assign_operand_to_place(result_place, mapped_op, span)
        else:
            var payload_op = 0
            if method_name == "map":
                let call_args2: Vec[i32] = Vec.new()
                call_args2.push(self.operand_for_place(payload_place, payload_ty))
                let mapped_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.option, 0)
                payload_op = self.lower_call_with_operand_args(mapper_op, call_args2, mapped_ty, node)
            else if method_name == "inspect":
                let inspect_args: Vec[i32] = Vec.new()
                let ref_ty = self.sema.find_exact_type(TypeKind.TY_REF, payload_ty, 0, 0) as i32
                inspect_args.push(self.operand_for_place_arg(payload_place, payload_ty, ref_ty, span))
                let _ = self.lower_call_with_operand_args(mapper_op, inspect_args, self.sema.ty_void as i32, node)
                payload_op = self.operand_for_place(payload_place, payload_ty)
            else if explicit_owner:
                let owned_payload_ty = self.generic_inst_arg_type(result_ty, self.sema.syms.option, 0)
                let pointee_place = self.new_deref_place(payload_place)
                if method_name == "copied":
                    payload_op = self.body.new_operand(OperandKind.OK_COPY, pointee_place)
                else:
                    payload_op = self.clone_or_copy_place(pointee_place, owned_payload_ty, node)
            else:
                payload_op = self.operand_for_place(payload_place, payload_ty)
            let some_fields: Vec[i32] = Vec.new()
            some_fields.push(payload_op)
            self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.some, some_fields, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        self.operand_for_place(result_place, result_ty)

    mut fn lower_result_combinator_method(self_expr: i32, method_name: &str, arg_start: i32, arg_count: i32, node: i32) -> i32:
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

        let value_place = self.lower_owned_receiver_place(self_expr, value_ty)
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
        else if method_name == "and_then":
            let ok_call_args2: Vec[i32] = Vec.new()
            ok_call_args2.push(self.operand_for_place(ok_payload_place, source_ok_ty))
            let chained_op = self.lower_call_with_operand_args(mapper_op, ok_call_args2, result_ty, node)
            self.assign_operand_to_place(result_place, chained_op, span)
            self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)
            self.switch_to(err_bb)
            let err_idx2 = self.enum_variant_index_for_type(value_ty, self.sema.syms.err)
            let err_downcast2 = self.body.new_downcast_place(value_place, err_idx2, value_ty)
            let err_payload_place2 = self.body.new_field_place(err_downcast2, 0, source_err_ty)
            let err_fields2: Vec[i32] = Vec.new()
            err_fields2.push(self.operand_for_place(err_payload_place2, source_err_ty))
            self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.err, err_fields2, span)
            self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)
            self.switch_to(join_bb)
            self.forget_string_flow_facts()
            return self.operand_for_place(result_place, result_ty)
        else if method_name == "inspect":
            let inspect_args: Vec[i32] = Vec.new()
            let ok_ref_ty = self.sema.find_exact_type(TypeKind.TY_REF, source_ok_ty, 0, 0) as i32
            inspect_args.push(self.operand_for_place_arg(ok_payload_place, source_ok_ty, ok_ref_ty, span))
            let _ = self.lower_call_with_operand_args(mapper_op, inspect_args, self.sema.ty_void as i32, node)
            ok_fields.push(self.operand_for_place(ok_payload_place, source_ok_ty))
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
        else if method_name == "or_else":
            let err_call_args2: Vec[i32] = Vec.new()
            err_call_args2.push(self.operand_for_place(err_payload_place, source_err_ty))
            let recovered_op = self.lower_call_with_operand_args(mapper_op, err_call_args2, result_ty, node)
            self.assign_operand_to_place(result_place, recovered_op, span)
            self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)
            self.switch_to(join_bb)
            self.forget_string_flow_facts()
            return self.operand_for_place(result_place, result_ty)
        else if method_name == "context" or method_name == "with_context":
            var message_op = context_message_op
            if method_name == "with_context":
                let no_context_args: Vec[i32] = Vec.new()
                message_op = self.lower_call_with_operand_args(context_fn_op, no_context_args, self.sema.ty_str as i32, node)
            let source_op = self.operand_for_place(err_payload_place, source_err_ty)
            err_fields.push(self.lower_context_error_operand(message_op, source_op, result_err_ty, span))
        else if method_name == "inspect_err":
            let inspect_err_args: Vec[i32] = Vec.new()
            let err_ref_ty = self.sema.find_exact_type(TypeKind.TY_REF, source_err_ty, 0, 0) as i32
            inspect_err_args.push(self.operand_for_place_arg(err_payload_place, source_err_ty, err_ref_ty, span))
            let _ = self.lower_call_with_operand_args(mapper_op, inspect_err_args, self.sema.ty_void as i32, node)
            err_fields.push(self.operand_for_place(err_payload_place, source_err_ty))
        else:
            err_fields.push(self.operand_for_place(err_payload_place, source_err_ty))
        self.assign_enum_variant_to_place(result_place, result_ty, self.sema.syms.err, err_fields, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        self.operand_for_place(result_place, result_ty)

    mut fn lower_method_arg_or_unit(node: i32, arg_start: i32, arg_count: i32, idx: i32) -> i32:
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

    // TODO(D22): unwrap_or and unwrap_or_else use the same contextual join as
    // `??`. Lower its resolved arm adjustments and origin union rather than
    // assuming the success payload already has the result type.
    mut fn lower_unwrap_or_method(self_expr: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
        let value_ty = self.expr_type(self_expr)
        let value_place = self.lower_owned_receiver_place(self_expr, value_ty)
        let carrier_arm = self.contextual_join_arm_index_for_role(node, D22_JOIN_ROLE_CARRIER_PAYLOAD)
        if carrier_arm < 0:
            self.mark_unsupported()
            return self.unit_operand()
        let payload_ty: i32 = self.sema.contextual_join_arm_types.get(carrier_arm as i64)

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
            result_ty = self.sema.try_unwrapped_type_frozen(value_ty) as i32
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
        let payload_place = self.body.new_field_place(downcast_place, 0, payload_ty)
        let some_op = self.lower_contextual_join_place_arm(node, D22_JOIN_ROLE_CARRIER_PAYLOAD, payload_place, self.ast.get_start(self_expr))
        self.assign_operand_to_place(result_place, some_op, self.ast.get_start(self_expr))
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(none_bb)
        let default_op = self.lower_method_arg_or_unit(node, arg_start, arg_count, 0)
        self.assign_operand_to_place(result_place, default_op, self.ast.get_start(node))
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        if self.sema.is_copy_frozen(result_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_unwrap_or_else_method(self_expr: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
        if arg_count != 1:
            self.mark_unsupported()
            return self.unit_operand()
        var value_ty = self.expr_type(self_expr)
        if value_ty == 0 or value_ty == self.sema.ty_void:
            value_ty = self.type_receiver_type(self_expr)
        var result_ty = self.expr_type(node)
        if result_ty == 0:
            result_ty = self.sema.try_unwrapped_type_frozen(value_ty) as i32
        if value_ty == 0 or result_ty == 0:
            self.mark_unsupported()
            return self.unit_operand()
        let span = self.ast.get_start(node)
        let value_place = self.lower_owned_receiver_place(self_expr, value_ty)
        let fallback_op = self.lower_expr(self.ast.get_extra(arg_start))
        let carrier_arm = self.contextual_join_arm_index_for_role(node, D22_JOIN_ROLE_CARRIER_PAYLOAD)
        let lazy_arm = self.contextual_join_arm_index_for_role(node, D22_JOIN_ROLE_LAZY_RESULT)
        if carrier_arm < 0 or lazy_arm < 0:
            self.mark_unsupported()
            return self.unit_operand()
        let payload_ty: i32 = self.sema.contextual_join_arm_types.get(carrier_arm as i64)
        let lazy_ty: i32 = self.sema.contextual_join_arm_types.get(lazy_arm as i64)

        let success_bb = self.new_block()
        let failure_bb = self.new_block()
        let join_bb = self.new_block()
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)

        let disc = self.lower_enum_discriminant(value_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(self.success_variant_index())
        let targets: Vec[i32] = Vec.new()
        targets.push(success_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, disc, table, failure_bb, 0)

        self.switch_to(success_bb)
        let success_downcast = self.body.new_downcast_place(value_place, self.success_variant_index(), value_ty)
        let success_payload_place = self.body.new_field_place(success_downcast, 0, payload_ty)
        let success_payload_op = self.lower_contextual_join_place_arm(node, D22_JOIN_ROLE_CARRIER_PAYLOAD, success_payload_place, span)
        self.assign_operand_to_place(result_place, success_payload_op, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(failure_bb)
        let call_args: Vec[i32] = Vec.new()
        if self.is_result_type(value_ty) != 0:
            let err_ty = self.generic_inst_arg_type(value_ty, self.sema.syms.result, 1)
            if err_ty == 0:
                self.mark_unsupported()
                return self.unit_operand()
            let err_idx = self.enum_variant_index_for_type(value_ty, self.sema.syms.err)
            let err_downcast = self.body.new_downcast_place(value_place, err_idx, value_ty)
            let err_payload_place = self.body.new_field_place(err_downcast, 0, err_ty)
            call_args.push(self.operand_for_place(err_payload_place, err_ty))
        let lazy_exact_op = self.lower_call_with_operand_args(fallback_op, call_args, lazy_ty, node)
        let lazy_exact_place = self.materialize_operand(lazy_exact_op, lazy_ty, span)
        let default_op = self.lower_contextual_join_place_arm(node, D22_JOIN_ROLE_LAZY_RESULT, lazy_exact_place, span)
        self.assign_operand_to_place(result_place, default_op, span)
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        self.operand_for_place(result_place, result_ty)

    mut fn lower_with_form1(guard_expr: i32, body_expr: i32) -> i32:
        let _ = self.lower_expr(guard_expr)
        self.push_scope()
        let result = self.lower_expr(body_expr)
        self.pop_scope_inline()
        result

    mut fn lower_with_guarded(node: i32) -> i32:
        self.lower_with_guarded_mode(node, 1)

    mut fn lower_with_guarded_mode(node: i32, want_result: i32) -> i32:
        let source = self.ast.get_data0(node)
        let body = self.ast.get_data1(node)
        let encoded = self.ast.get_data2(node)
        let name = decode_with_binding_sym(encoded)
        let is_mut = decode_with_binding_is_mut(encoded)
        let source_ty = self.expr_type(source)
        let payload_ty: i32 = self.sema.with_payload_types.get(node).unwrap()
        let enter_fn: i32 = self.sema.with_enter_methods.get(node).unwrap()
        let exit_fn: i32 = self.sema.with_exit_methods.get(node).unwrap()
        let enter_sig: i32 = self.sema.with_enter_sigs.get(node).unwrap()
        let enter_mono_sym: i32 = self.sema.with_enter_mono_syms.get(node).unwrap()
        let exit_sig: i32 = self.sema.with_exit_sigs.get(node).unwrap()
        let exit_mono_sym: i32 = self.sema.with_exit_mono_syms.get(node).unwrap()
        let span = self.ast.get_start(node)

        self.push_scope()

        let guard_local = self.body.new_local(source_ty, 0, 0, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, guard_local, 0, span)
        let source_op = self.lower_expr(source)
        let guard_place = self.place_for_local(guard_local)
        self.assign_operand_to_place(guard_place, source_op, self.ast.get_start(source))

        let payload_local = self.body.new_local(payload_ty, is_mut, name, 1)
        if name != 0 and self.pool.resolve_symbol(name) != "_":
            self.bind_local(name, payload_local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, payload_local, 0, span)

        let guard_expected = if enter_sig >= 0 and self.sema.sig_get_param_count(enter_sig) > 0: self.sema.sig_param_type(enter_sig, 0) else: 0
        let enter_args: Vec[i32] = Vec.new()
        let enter_guard_place = self.place_for_local(guard_local)
        enter_args.push(self.operand_for_place_arg(enter_guard_place, source_ty, guard_expected, span))
        let enter_args_id = self.body.new_call_args(enter_args)
        self.body.set_call_contract(enter_args_id, enter_sig, enter_mono_sym)
        if self.sym_is_generic_fn(enter_fn):
            self.body.set_call_intrinsic(enter_args_id, MirIntrinsic.GENERIC_CALL)
            self.body.require_call_contract(enter_args_id)
        self.body.set_call_ast_node(enter_args_id, node)
        let enter_op = self.const_operand(ConstKind.CK_FN, enter_fn, self.sema.ty_void as i32)
        let after_enter = self.new_block()
        let payload_place = self.place_for_local(payload_local)
        self.terminate(TermKind.TK_CALL, enter_op, enter_args_id, payload_place, after_enter)
        self.switch_to(after_enter)

        let drop_kind = if is_mut != 0: DropKind.DK_WITH_GUARD_MUT else: DropKind.DK_WITH_GUARD
        self.schedule_with_guard_cleanup(guard_local, payload_local, exit_fn, exit_sig, exit_mono_sym, drop_kind)

        // #772 (barrier): statement-position bodies lower as DISCARD — the
        // CALLER's mode decides, not a type guess (a void guess broke ss07's
        // value-position nested with). Value-mode kept lower_if building a
        // void join and leaking expected_type=void into the arms.
        if want_result == 0:
            let _ = self.lower_expr_discard(body)
            self.pop_scope_inline()
            return self.unit_operand()
        let result = self.lower_expr(body)
        self.pop_scope_inline()
        result

    mut fn lower_with_binding(sym: i32, rhs_expr: i32, body_expr: i32, span: i32) -> i32:
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
        if self.sema.is_copy_frozen(ty) == 0:
            self.schedule_drop(local, DropKind.DK_VALUE)
        let rhs = self.lower_expr(rhs_expr)
        let local_place = self.place_for_local(local)
        self.assign_operand_to_place(local_place, rhs, self.ast.get_start(rhs_expr))
        // Form 2 builder rule: `with <expr> as mut x:` always returns x.
        if is_mut != 0:
            let _ = self.lower_expr_discard(body_expr)
            let local_return_place = self.place_for_local(local)
            self.pop_scope_inline()
            return self.body.new_operand(OperandKind.OK_COPY, local_return_place)
        let result = self.lower_expr(body_expr)
        self.pop_scope_inline()
        result

    mut fn lower_with_tuple(node: i32) -> i32:
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
                let field_place = self.body.new_tuple_index_place(rhs_place, ni, elem_ty)
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
            if self.type_needs_value_drop(elem_ty) != 0:
                self.schedule_drop(local_id, DropKind.DK_VALUE)
            let field_place = self.body.new_tuple_index_place(rhs_place, ni, elem_ty)
            let field_op = self.body.new_operand(if self.type_needs_value_drop(elem_ty) == 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, field_place)
            let dst_place = self.place_for_local(local_id)
            self.assign_operand_to_place(dst_place, field_op, self.ast.get_start(node))
        let result = self.lower_expr(body)
        self.pop_scope_inline()
        result

    mut fn lower_with_form2_3(pat_or_name: i32, rhs_expr: i32, body_expr: i32) -> i32:
        self.push_scope()
        if self.ast.kind(pat_or_name) == NodeKind.NK_IDENT:
            let sym = self.ast.get_data0(pat_or_name)
            let ty = self.expr_type(rhs_expr)
            let local = self.body.new_local(ty, 0, sym, 1)
            self.bind_local(sym, local)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local, 0, self.ast.get_start(pat_or_name))
            if self.sema.is_copy_frozen(ty) == 0:
                self.schedule_drop(local, DropKind.DK_VALUE)
            let rhs = self.lower_expr(rhs_expr)
            let local_place = self.place_for_local(local)
            self.assign_operand_to_place(local_place, rhs, self.ast.get_start(rhs_expr))
        else:
            let _ = self.lower_expr(rhs_expr)
        let result = self.lower_expr(body_expr)
        self.pop_scope_inline()
        result

    mut fn lower_record_update(base_expr: i32, field_updates_start: i32, field_updates_count: i32, node: i32) -> i32:
        let ty = self.expr_type(node)
        let base_place = self.lower_expr_place(base_expr)
        if ty != 0 and self.sema.is_copy_frozen(ty) == 0 and base_place >= 0 and base_place < self.body.place_locals.len() as i32:
            if self.body.place_proj_counts.get(base_place as i64) == 0:
                self.cancel_scheduled_value_drop_for_local(self.body.place_locals.get(base_place as i64))
        let resolved_ty = self.sema.resolve_alias(ty)
        var struct_extra = self.sema.get_type_d1(resolved_ty)
        var struct_fc = self.sema.get_type_d2(resolved_ty)
        if self.sema.get_type_kind(resolved_ty) == TypeKind.TY_GENERIC_INST:
            let base_sym = self.sema.get_generic_inst_base(resolved_ty as i32)
            let base_tid = self.sema.lookup_named_type_ambient(base_sym)
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
            let f_name_sym: i32 = self.sema.type_extra.get((struct_extra + fi * 3) as i64)
            let field_ty = self.struct_field_type(ty, f_name_sym)
            let src_field_place = self.body.new_field_place(base_place, f_name_sym, field_ty)
            var update_idx = -1
            for ui in 0..field_updates_count:
                if self.ast.get_extra(field_updates_start + ui * 2) == f_name_sym:
                    update_idx = ui
                    break
            if update_idx >= 0:
                if field_ty != 0 and self.sema.is_copy_frozen(field_ty) == 0:
                    let old_field_tmp = self.new_temp(field_ty)
                    let old_field_place = self.place_for_local(old_field_tmp)
                    let old_field_op = self.body.new_operand(OperandKind.OK_MOVE, src_field_place)
                    self.assign_operand_to_place(old_field_place, old_field_op, self.ast.get_start(node))
                    self.emit_drop_stmt(old_field_place, "record-update", self.ast.get_start(node))
                result_fields.push(update_ops.get(update_idx as i64))
            else:
                let op_kind = if field_ty != 0 and self.sema.is_copy_frozen(field_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
                let field_op = self.body.new_operand(op_kind, src_field_place)
                result_fields.push(field_op)
            result_names.push(f_name_sym)

        let result_fid = self.body.new_agg_fields(result_fields, result_names)
        let result_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, result_fid, 0)
        let tmp = self.new_temp(ty)
        let result_place = self.place_for_local(tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, result_place, result_rv, self.ast.get_start(node))
        self.update_string_fields_after_aggregate(result_place, result_fid)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_implicit_ok(expr: i32, ok_type_id: i32) -> i32:
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
        // #605/#698: the wrapped Ok payload is moved into the aggregate —
        // consume it so a registered payload temp is not also flush-dropped.
        if self.sema.type_needs_drop_frozen(self.expr_type(expr)) != 0:
            self.consume_moved_operand(op)
        self.body.new_operand(OperandKind.OK_COPY, place)

    mut fn lower_implicit_default_value(type_id: i32, span: i32) -> i32:
        if type_id == self.sema.ty_void:
            return self.unit_operand()
        let resolved = self.sema.resolve_alias(type_id as TypeId)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
            let base = self.sema.get_generic_inst_base(resolved as i32)
            if base == self.sema.syms.option:
                let tmp = self.new_temp(type_id)
                let place = self.place_for_local(tmp)
                let fields: Vec[i32] = Vec.new()
                self.assign_enum_variant_to_place(place, type_id, self.sema.syms.none, fields, span)
                return self.body.new_operand(OperandKind.OK_COPY, place)
            if base == self.sema.syms.result and self.sema.get_generic_inst_arg_count(resolved as i32) == 2:
                let ok_type = self.sema.get_generic_inst_arg(resolved as i32, 0)
                let ok_value = self.lower_implicit_default_value(ok_type, span)
                let tmp = self.new_temp(type_id)
                let place = self.place_for_local(tmp)
                let fields: Vec[i32] = Vec.new()
                fields.push(ok_value)
                self.assign_enum_variant_to_place(place, type_id, self.sema.syms.ok, fields, span)
                return self.body.new_operand(OperandKind.OK_COPY, place)
            // #633 (§4.10): the implicit default of a heap container must equal
            // `.new()`'s value, not a zeroed struct. A zeroed HashMap/HashSet has
            // null buckets and SEGFAULTs on use; a zeroed Vec happens to work but
            // has elem_size=0, differing from Vec.new(). Emit the real constructor.
            if base == self.sema.syms.hashmap or base == self.sema.syms.hashset:
                let map_tmp = self.new_temp(type_id)
                let map_place = self.place_for_local(map_tmp)
                self.emit_map_new_into(map_place, span)
                return self.body.new_operand(OperandKind.OK_COPY, map_place)
            if base == self.sema.syms.vec:
                let vec_tmp = self.new_temp(type_id)
                let vec_place = self.place_for_local(vec_tmp)
                self.emit_vec_new_into(vec_place, span)
                return self.body.new_operand(OperandKind.OK_COPY, vec_place)
        self.const_operand(ConstKind.CK_UNIT, 0, type_id)

    mut fn lower_implicit_default_return(type_id: i32, span: i32) -> i32:
        self.lower_implicit_default_value(type_id, span)

    fn option_payload_type(option_ty: i32) -> i32:
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

    fn generic_inst_arg_type(type_id: i32, base_sym: i32, index: i32) -> i32:
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

    fn option_some_index(option_ty: i32) -> i32:
        let idx = self.enum_variant_index_for_type(option_ty, self.sema.syms.some)
        if idx >= 0:
            return idx
        self.success_variant_index()

    mut fn lower_optional_chain_field(result_place: i32, result_ty: i32, base_place: i32, base_ty: i32, payload_ty: i32, success_idx: i32, success_sym: i32, member_sym: i32, span: i32):
        let downcast_place = self.body.new_downcast_place(base_place, success_idx, base_ty)
        let payload_place = self.body.new_field_place(downcast_place, 0, payload_ty)
        let field_ty = self.sema.struct_field_type_frozen(payload_ty, member_sym)
        if field_ty == 0:
            self.mark_unsupported()
            return

        let field_place = self.body.new_field_place(payload_place, member_sym, field_ty)
        let field_op_kind = if self.sema.is_copy_frozen(field_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
        let field_op = self.body.new_operand(field_op_kind, field_place)
        if field_ty == result_ty:
            self.assign_operand_to_place(result_place, field_op, span)
            return

        let success_fields: Vec[i32] = Vec.new()
        success_fields.push(field_op)
        self.assign_enum_variant_to_place(result_place, result_ty, success_sym, success_fields, span)

    mut fn lower_intrinsic_call_with_receiver_operand(intrinsic: MirIntrinsic, recv_op: i32, recv_type: i32, method_sym: i32, arg_start: i32, arg_count: i32, ret_type: i32, node: i32) -> i32:
        let fn_op = self.const_operand(ConstKind.CK_FN, method_sym, self.sema.ty_void)
        let call_args: Vec[i32] = Vec.new()
        self.consume_moved_operand(recv_op)
        call_args.push(recv_op)
        for ai in 0..arg_count:
            // #747: str reader needles observe (see str_intrinsic_observer_arg).
            if self.str_intrinsic_observer_arg(intrinsic, ai) != 0:
                call_args.push(self.lower_observer_probe_arg(self.ast.get_extra(arg_start + ai)))
                continue
            let arg_op = self.lower_method_arg_with_expected(recv_type, method_sym, self.ast.get_extra(arg_start + ai), ai)
            self.consume_moved_operand(arg_op)
            call_args.push(arg_op)

        let args_id = self.body.new_call_args(call_args)
        self.body.set_call_ast_node(args_id, node)
        let result_local = self.new_temp(ret_type)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.body.set_call_intrinsic(args_id, intrinsic)
        if self.sema.is_copy_frozen(ret_type) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_optional_chain_receiver_operand(payload_place: i32, payload_ty: i32, sig_idx: i32, span: i32) -> i32:
        if sig_idx >= 0 and self.sema.sig_get_param_count(sig_idx) > 0:
            let expected_ty = self.sema.sig_param_type(sig_idx, 0)
            if expected_ty != 0 and self.sema.can_auto_ref_arg_frozen(expected_ty, payload_ty) != 0:
                let rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, payload_place, 0)
                let temp = self.new_temp(expected_ty)
                let temp_place = self.place_for_local(temp)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, span)
                return self.body.new_operand(OperandKind.OK_COPY, temp_place)
        let op_kind = if self.sema.is_copy_frozen(payload_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
        self.body.new_operand(op_kind, payload_place)

    mut fn operand_for_place(place: i32, type_id: i32) -> i32:
        let op_kind = if self.sema.is_copy_frozen(type_id) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
        self.body.new_operand(op_kind, place)

    mut fn lower_call_with_operand_args(fn_op: i32, args: &Vec[i32], ret_type: i32, node: i32) -> i32:
        for ai in 0..args.len() as i32:
            self.consume_moved_operand(args.get(ai as i64))
        let args_id = self.body.new_call_args(args)
        self.body.set_call_ast_node(args_id, node)
        let result_local = self.new_temp(ret_type)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.register_stmt_temp(result_local, ret_type)
        if self.sema.is_copy_frozen(ret_type) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    fn generic_call_symbol_text(sym: i32) -> str:
        let text = self.pool.resolve(sym)
        if text.len() > 0:
            return with_str_clone_ref(text)
        with_str_clone_ref(self.sema.pool_resolve(sym))

    fn generic_call_uses_codegen_dispatch(method_sym: i32, self_expr: i32, has_recorded_sig: bool, recv_ty: i32, recv_kind: i32) -> bool:
        if recv_ty != 0:
            if self.sema.type_is_task(recv_ty) != 0 or self.sema.type_is_scoped_task(recv_ty) != 0 or self.sema.type_is_scoped_join_handle(recv_ty) != 0 or self.type_is_channel_endpoint(recv_ty) != 0:
                return true
            let resolved = self.sema.resolve_alias(recv_ty as TypeId)
            if recv_kind == TypeKind.TY_GENERIC_INST and self.sema.pool_resolve(self.sema.get_generic_inst_base(resolved as i32)) == "Atomic":
                return true
        if has_recorded_sig:
            return false
        if method_sym != 0:
            let method_name = self.generic_call_symbol_text(method_sym)
            if method_sym == self.sema.syms.track or method_name == "spawn" or method_name == "join" or method_name == "from_int":
                return true
            if method_name == "new" and self.sema.pool_resolve(self.static_receiver_base_sym(self_expr)) == "Atomic":
                return true
        false

    // D6-spirit single decision point: every GENERIC_CALL contract
    // requirement flows through here (seven per-site decisions produced
    // four cache-masked machinery strata). Language-machinery calls carry
    // no specialization contract — codegen dispatches them by
    // name/receiver. User-Deref dispatch opts out at its creation site.
    mut fn require_generic_call_contract(args_id: i32, callee_sym: i32, method_sym: i32, self_expr: i32, has_recorded_sig: bool, site: &str):
        let mach_name = self.generic_call_symbol_text(if method_sym != 0: method_sym else: callee_sym)
        var recv_ty = 0
        if self_expr != 0 and self.sema.typed_expr_types.contains(self_expr):
            recv_ty = self.sema.typed_expr_types.get(self_expr).unwrap()
        let recv_kind = if recv_ty != 0: self.sema.get_type_kind(self.sema.resolve_alias(recv_ty as TypeId)) else: -1
        let required = not self.generic_call_uses_codegen_dispatch(method_sym, self_expr, has_recorded_sig, recv_ty, recv_kind)
        if with_getenv_str("WITH_MIR_AUDIT").len() > 0:
            with_eprint(f"[gc-contract] site={site} name={mach_name} recv_ty={recv_ty} recv_kind={recv_kind} recorded={has_recorded_sig} required={required}")
        if required:
            self.body.require_call_contract(args_id)

    mut fn lower_resolved_call_with_operand_args(fn_sym: i32, args: &Vec[i32], ret_type: i32, node: i32, require_contract: bool = true) -> i32:
        self.lower_resolved_call_with_operand_args_contract(fn_sym, args, ret_type, node, -1, 0, require_contract)

    mut fn lower_resolved_call_with_operand_args_contract(fn_sym: i32, args: &Vec[i32], ret_type: i32, node: i32, explicit_sig: i32, explicit_mono_sym: i32, require_contract: bool = true) -> i32:
        let fn_op = self.lower_var(fn_sym, 0, node)
        var sig_idx = self.call_sig_for_sym(fn_sym)
        let recorded_sig_opt = self.sema.resolved_call_sigs.get(node)
        let has_recorded_sig = recorded_sig_opt.is_some()
        let recorded_sig: i32 = if has_recorded_sig: recorded_sig_opt.unwrap() else: -1
        if explicit_sig >= 0:
            sig_idx = explicit_sig
        else if has_recorded_sig:
            sig_idx = recorded_sig
        for ai in 0..args.len() as i32:
            if sig_idx < 0 or self.sema.sig_param_uses_value_ref_abi(sig_idx, ai) == 0:
                self.consume_moved_operand(args.get(ai as i64))
        let args_id = self.body.new_call_args(args)
        self.body.set_call_ast_node(args_id, node)
        if explicit_sig >= 0:
            self.body.set_call_contract(args_id, explicit_sig, explicit_mono_sym)
        else:
            self.record_call_contract(args_id, node, sig_idx)
        if self.sym_is_generic_fn(fn_sym):
            self.body.set_call_intrinsic(args_id, MirIntrinsic.GENERIC_CALL)
            // User-Deref dispatch (autoderef machinery) passes the GENERIC
            // Deref.deref symbol with no per-node recorded sig; codegen
            // monomorphizes GENERIC_CALL by receiver, so no specialization
            // contract can exist for it (behav_rc_arc_basic's auto-deref
            // stratum). Ordinary generic calls keep the requirement.
            if require_contract:
                self.require_generic_call_contract(args_id, fn_sym, 0, 0, explicit_sig >= 0 or has_recorded_sig, "operand-args")
        let result_local = self.new_temp(ret_type)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.register_stmt_temp(result_local, ret_type)
        if self.sema.is_copy_frozen(ret_type) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_call_with_receiver_operand(fn_op: i32, callee_sym: i32, recv_op: i32, arg_start: i32, arg_count: i32, ret_type: i32, node: i32) -> i32:
        var sig_idx = self.call_sig_for_sym(callee_sym)
        let recorded_sig = self.sema.resolved_call_sigs.get(node)
        if recorded_sig.is_some():
            sig_idx = recorded_sig.unwrap()
        let args: Vec[i32] = Vec.new()
        if sig_idx < 0 or self.sema.sig_param_uses_value_ref_abi(sig_idx, 0) == 0:
            self.consume_moved_operand(recv_op)
        args.push(recv_op)
        for ai in 0..arg_count:
            args.push(self.lower_call_arg(self.ast.get_extra(arg_start + ai), sig_idx, 0, ai + 1, callee_sym))
        let args_id = self.body.new_call_args(args)
        self.body.set_call_ast_node(args_id, node)
        self.record_call_contract(args_id, node, sig_idx)
        let result_local = self.new_temp(ret_type)
        let result_place = self.place_for_local(result_local)
        let next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
        self.switch_to(next_bb)
        self.register_stmt_temp(result_local, ret_type)
        if self.sema.is_copy_frozen(ret_type) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_optional_chain_method(result_place: i32, result_ty: i32, base_place: i32, base_ty: i32, payload_ty: i32, success_idx: i32, success_sym: i32, member_sym: i32, extra_start: i32, node: i32):
        let raw_ret_ty = self.sema.optional_chain_method_raw_result_type_frozen(payload_ty, member_sym)
        if raw_ret_ty == 0:
            self.mark_unsupported()
            return

        let downcast_place = self.body.new_downcast_place(base_place, success_idx, base_ty)
        let payload_place = self.body.new_field_place(downcast_place, 0, payload_ty)
        let method_name = self.pool.resolve_symbol(member_sym)
        let arg_count = self.ast.optional_chain_arg_count(extra_start)
        let arg_start = self.ast.optional_chain_arg_start(extra_start)
        var raw_op = 0

        let intrinsic = self.classify_intrinsic(payload_ty, method_name)
        if intrinsic != MirIntrinsic.NONE:
            let payload_op_kind = if self.sema.is_copy_frozen(payload_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
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

        let success_fields: Vec[i32] = Vec.new()
        success_fields.push(raw_op)
        self.assign_enum_variant_to_place(result_place, result_ty, success_sym, success_fields, self.ast.get_start(node))

    mut fn lower_pipeline(lhs_expr: i32, fn_expr: i32, args_start: i32, args_count: i32, node: i32) -> i32:
        if self.sema.pipeline_method_calls.contains(node):
            let method_sym: i32 = self.sema.pipeline_method_calls.get(node).unwrap()
            if self.sema.pipeline_carrier_kinds.contains(node) and self.sema.pipeline_carrier_kinds.get(node).unwrap() != 0:
                let recv_place = self.lower_expr_place(lhs_expr)
                let call_count_before = self.body.call_arg_starts.len() as i32
                let saved_override_node = self.pipeline_receiver_override_node
                let saved_override_place = self.pipeline_receiver_override_place
                self.pipeline_receiver_override_node = lhs_expr
                self.pipeline_receiver_override_place = recv_place
                let _ = self.lower_method_call(lhs_expr, method_sym, args_start, args_count, node)
                self.pipeline_receiver_override_node = saved_override_node
                self.pipeline_receiver_override_place = saved_override_place
                let call_count_after = self.body.call_arg_starts.len() as i32
                // Ordinary argument evaluation may lower calls of its own
                // before the stage call. lower_method_call creates the stage's
                // call record last, after all receiver/argument evaluation.
                if call_count_after > call_count_before:
                    self.body.set_call_pipeline_receiver_place(call_count_after - 1, recv_place)
                else:
                    sema_phase_bug("BUG: D21 pipeline stage lowered no method call")
                let recv_ty = self.expr_type(node)
                let carrier_kind = if self.sema.is_copy_frozen(recv_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE
                return self.body.new_operand(carrier_kind, recv_place)
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
        let ret_ty = self.expr_type(node)
        self.lower_call_with_arg_nodes(fn_op, callee_sym, arg_nodes, ret_ty, node)

    mut fn lower_closure(_captured_start: i32, _captured_count: i32, _params_start: i32, _params_count: i32, node: i32) -> i32:
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

    mut fn lower_optional_chain(node: i32) -> i32:
        let base_expr = self.ast.get_data0(node)
        let member_sym = self.ast.get_data1(node)
        let extra_start = self.ast.get_data2(node)
        let is_call = self.ast.optional_chain_is_call(extra_start)

        let base_op = self.lower_expr(base_expr)
        let base_ty = self.expr_type(base_expr)
        let base_place = self.materialize_operand(base_op, base_ty, self.ast.get_start(base_expr))
        let option_payload_ty = self.generic_inst_arg_type(base_ty, self.sema.syms.option, 0)
        let result_ok_ty = self.generic_inst_arg_type(base_ty, self.sema.syms.result, 0)
        let result_err_ty = self.generic_inst_arg_type(base_ty, self.sema.syms.result, 1)
        var payload_ty = option_payload_ty
        var success_sym = self.sema.syms.some
        var failure_sym = self.sema.syms.none
        var success_idx = self.option_some_index(base_ty)
        var is_result_chain = 0
        if payload_ty == 0 and result_ok_ty != 0 and result_err_ty != 0:
            payload_ty = result_ok_ty
            success_sym = self.sema.syms.ok
            failure_sym = self.sema.syms.err
            success_idx = self.enum_variant_index_for_type(base_ty, self.sema.syms.ok)
            is_result_chain = 1
        if payload_ty == 0 or success_idx < 0:
            self.mark_unsupported()
            return self.unit_operand()

        let success_bb = self.new_block()
        let failure_bb = self.new_block()
        let join_bb = self.new_block()

        let disc = self.lower_enum_discriminant(base_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(success_idx)
        let targets: Vec[i32] = Vec.new()
        targets.push(success_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, disc, table, failure_bb, 0)

        let result_ty = self.expr_type(node)
        let result_local = self.new_temp(result_ty)
        let result_place = self.place_for_local(result_local)

        self.switch_to(success_bb)
        if is_call != 0:
            self.lower_optional_chain_method(result_place, result_ty, base_place, base_ty, payload_ty, success_idx, success_sym, member_sym, extra_start, node)
        else:
            self.lower_optional_chain_field(result_place, result_ty, base_place, base_ty, payload_ty, success_idx, success_sym, member_sym, self.ast.get_start(node))
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(failure_bb)
        if is_result_chain != 0:
            let err_idx = self.enum_variant_index_for_type(base_ty, failure_sym)
            if err_idx < 0:
                self.mark_unsupported()
            else:
                let err_downcast = self.body.new_downcast_place(base_place, err_idx, base_ty)
                let err_payload_place = self.body.new_field_place(err_downcast, 0, result_err_ty)
                let err_fields: Vec[i32] = Vec.new()
                err_fields.push(self.operand_for_place(err_payload_place, result_err_ty))
                self.assign_enum_variant_to_place(result_place, result_ty, failure_sym, err_fields, self.ast.get_start(node))
        else:
            let none_fields: Vec[i32] = Vec.new()
            self.assign_enum_variant_to_place(result_place, result_ty, failure_sym, none_fields, self.ast.get_start(node))
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        self.forget_string_flow_facts()
        if self.sema.is_copy_frozen(result_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, result_place)
        self.body.new_operand(OperandKind.OK_MOVE, result_place)

    mut fn lower_expr(node: i32) -> i32:
        if node == 0:
            return self.unit_operand()

        if node != self.contextual_copy_raw_node and self.has_contextual_copy_adjustment(node) != 0:
            return self.lower_contextual_copy_adjustment(node)

        if node == self.pipeline_receiver_override_node and self.pipeline_receiver_override_place >= 0:
            return self.body.new_operand(OperandKind.OK_COPY, self.pipeline_receiver_override_place)

        self.cur_node = node
        let kind = self.ast.kind(node)

        if kind == NodeKind.NK_INT_LIT:
            let lit_ty = self.expr_type(node)
            return self.lower_int_lit_node(node, lit_ty)

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
            let lit_ty = self.expr_type(node)
            return self.lower_str_lit_as(self.ast.get_data0(node), lit_ty)
        if kind == NodeKind.NK_C_STRING_LIT:
            return self.lower_c_str_lit(self.ast.get_data0(node))

        if kind == NodeKind.NK_FSTRING:
            return self.lower_fstring(node)

        if kind == NodeKind.NK_FLOAT_LIT:
            let lit_ty = self.expr_type(node)
            return self.lower_float_lit(self.ast.get_data0(node), lit_ty)

        if kind == NodeKind.NK_NULL_LIT:
            // Null pointer literal: a zero const carrying the sema-resolved
            // target type (pointer, extern fn, or Option-pointer — §16.10).
            // A bare i32 zero only worked where a destination place repaired
            // it; a call operand has no place context, so the Option-pointer
            // ABI received the wrong shape (spec_ss16_10:27).
            var null_ty = self.expr_type(node)
            if null_ty == 0 or null_ty == self.sema.ty_void as i32:
                null_ty = self.sema.ty_i32 as i32
            return self.const_operand(ConstKind.CK_INT, 0, null_ty)

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
                // Extras: [output_count, out_types.., input_count, in_exprs..]
                let asm_output_count = self.ast.get_extra(asm_extra_start)
                let asm_in_base = asm_extra_start + 1 + asm_output_count
                let asm_input_count = self.ast.get_extra(asm_in_base)
                for asm_ii in 0..asm_input_count:
                    let asm_in_node = self.ast.get_extra(asm_in_base + 1 + asm_ii)
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
            let ident_ty = self.expr_type(node)
            return self.lower_var(self.ast.get_data0(node), ident_ty, node)

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
                cast_tid = self.sema.resolve_type_expr_frozen(self.ast.get_data1(node)) as i32
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
                let fa_base_ast_sym = self.ast.get_data0(fa_base)
                let fa_base_sym = self.sema.pool_lookup_symbol(self.pool.resolve(fa_base_ast_sym))
                if self.sema.named_types.contains(fa_base_sym):
                    let fa_base_ty: i32 = self.sema.named_types.get(fa_base_sym).unwrap()
                    let fa_resolved = self.sema.resolve_alias(fa_base_ty)
                    let fa_tk = self.sema.get_type_kind(fa_resolved)
                    if fa_tk == TypeKind.TY_ENUM:
                        // Build qualified variant key: "Color.Red"
                        let fa_type_name = self.sema.pool_resolve(fa_base_sym)
                        let fa_field_name = self.pool.resolve(fa_field)
                        let fa_field_sym = self.sema.pool_lookup_symbol(fa_field_name)
                        let fa_qual_name = fa_type_name ++ "." ++ fa_field_name
                        let fa_qual_sym = self.sema.pool_lookup_symbol(fa_qual_name)
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
                        if self.sema.variant_lookup.contains(fa_field_sym):
                            let fa_var_tid = self.sema.variant_type_ids.get(fa_field_sym).unwrap()
                            if fa_var_tid == fa_resolved:
                                let fa_disc_tag2 = self.enum_variant_discriminant_for_type(fa_base_ty, fa_field_sym)
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
            self.mark_string_place_copied(place)
            let fa_val_ty = self.expr_type(node)
            if fa_val_ty != 0 and self.sema.type_needs_drop_frozen(fa_val_ty) != 0:
                // #780: a field value read whose base chain passes through a
                // shared borrow (&T param or & field) cannot move out — this
                // frame doesn't own the place (an explicit `return fact.name`
                // through &fact blanked the caller's field; the tail form
                // aliased the buffer into a double free). Materialize an
                // independent owner instead (D22 owned-demand): for str the
                // two-part concat copy (a one-part RK_STR_CONCAT_N is a
                // codegen pass-through). Non-str drop types keep the
                // historical move; recorded as #780 residue.
                let fb_owned_demand = self.expected_type != 0 and self.type_id_is_str(self.sema.resolve_alias(self.expected_type as TypeId) as i32) != 0
                if fb_owned_demand and self.type_id_is_str(fa_val_ty) != 0 and self.field_read_base_is_shared_borrow(node) != 0:
                    let fb_parts: Vec[i32] = Vec.new()
                    fb_parts.push(self.body.new_operand(OperandKind.OK_COPY, place))
                    fb_parts.push(self.lower_str_lit(self.pool.intern("")))
                    let fb_args = self.body.new_call_args(fb_parts)
                    let fb_rv = self.body.new_rvalue(RvalueKind.RK_STR_CONCAT_N, fb_args, 2, 0)
                    let fb_tmp = self.new_temp(fa_val_ty)
                    let fb_place = self.place_for_local(fb_tmp)
                    self.body.push_stmt(self.cur_bb, StmtKind.Assign, fb_place, fb_rv, self.ast.get_start(node))
                    self.set_string_local_flags(fb_tmp, 2)
                    return self.body.new_operand(OperandKind.OK_MOVE, fb_place)
                return self.body.new_operand(OperandKind.OK_MOVE, place)
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
            let idx_exact_ty = self.expr_type(node)
            if idx_exact_ty != 0 and self.sema.get_type_kind(self.sema.resolve_alias(idx_exact_ty as TypeId)) == TypeKind.TY_REF:
                let idx_ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, place, 0)
                let idx_ref_tmp = self.new_temp(idx_exact_ty)
                let idx_ref_place = self.place_for_local(idx_ref_tmp)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, idx_ref_place, idx_ref_rv, self.ast.get_start(node))
                return self.body.new_operand(OperandKind.OK_COPY, idx_ref_place)
            // A8 (#606): extracting a non-Copy element out of an ARRAY by index moves
            // it out of the slot. Blank the slot at the statement boundary
            // (reset-on-move, §2.5.1) and KEEP the array's scheduled drop with its
            // niche guard: the per-element guarded drop skips the blanked slot and
            // still frees the non-extracted siblings. (Replaces the whole-base
            // consume, which cancelled the array's drop and leaked every sibling.)
            // Tightly scoped to a plain array-local base — Vec/slice/map indexing is
            // unaffected.
            let idx_val_ty = self.expr_type(node)
            if idx_val_ty != 0 and self.sema.is_copy_frozen(idx_val_ty as TypeId) == 0:
                let idx_base_local = self.place_base_local(place)
                if idx_base_local >= 0 and idx_base_local < self.body.local_type_ids.len() as i32:
                    let idx_base_ty = self.body.local_type_ids.get(idx_base_local as i64)
                    if idx_base_ty != 0 and self.sema.get_type_kind(self.sema.resolve_alias(idx_base_ty as TypeId)) == TypeKind.TY_ARRAY:
                        // Materialize the element into a temp and blank the slot
                        // IMMEDIATELY after the read (not via the pending-reset
                        // list): a tail-position extraction is consumed after the
                        // block's scope drops are emitted, so a deferred reset
                        // would let the array's drop free the slot first.
                        let a8_tmp = self.new_temp(idx_val_ty)
                        let a8_tmp_place = self.place_for_local(a8_tmp)
                        self.assign_operand_to_place(a8_tmp_place, self.body.new_operand(OperandKind.OK_MOVE, place), self.ast.get_start(node))
                        let a8_zop = self.body.gen_zero_operand(idx_val_ty)
                        let a8_zrv = self.body.new_rvalue(RvalueKind.RK_USE, a8_zop, 0, 0)
                        self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, a8_zrv, self.ast.get_start(node))
                        self.body.mark_local_ever_moved(idx_base_local)
                        self.register_stmt_temp(a8_tmp, idx_val_ty)
                        return self.body.new_operand(OperandKind.OK_MOVE, a8_tmp_place)
            return self.body.new_operand(OperandKind.OK_COPY, place)

        if kind == NodeKind.NK_MULTI_INDEX:
            let mi_place = self.lower_multi_index_read(node)
            return self.body.new_operand(OperandKind.OK_COPY, mi_place)

        if kind == NodeKind.NK_SLICE:
            return self.lower_slice_expr(node)

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
                self.mark_string_place_copied(append_place)
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
            let target_ty = self.assignment_place_value_type(target)
            let rhs_reset_start = self.pending_reset_locals.len() as i32
            let rhs_field_reset_start = self.pending_reset_field_places.len() as i32
            let rhs_move_temp_start = self.pending_move_temp_locals.len() as i32
            if target_ty != 0 and target_ty != self.sema.ty_void as i32:
                self.expected_type = target_ty
            let rhs_op = self.lower_expr(rhs_node)
            self.expected_type = saved_expected
            let place = self.lower_expr_place(target)
            return self.finish_assignment_to_place(target, place, target_ty, rhs_op, rhs_reset_start, rhs_field_reset_start, rhs_move_temp_start)

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
        if kind == NodeKind.NK_MAP_COMPREHENSION:
            return self.lower_array_comprehension(node)

        if kind == NodeKind.NK_BREAK:
            return self.lower_break(node)

        if kind == NodeKind.NK_CONTINUE:
            return self.lower_continue(node)

        if kind == NodeKind.NK_RETURN:
            return self.lower_return(node)

        if kind == NodeKind.NK_MATCH:
            return self.lower_match(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node, 1)

        if kind == NodeKind.NK_CALL:
            let callee = self.ast.get_data0(node)
            if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
                // Distinguish method syntax from a callable field like
                // `ctx.memctl.free(...)`, which should lower as an indirect call.
                if self.callable_fn_type_for_expr(callee) != 0:
                    let call_ty = self.expr_type(node)
                    return self.lower_call(callee, self.ast.get_data1(node), self.ast.get_data2(node), call_ty, node)
                return self.lower_method_call(self.ast.get_data0(callee), self.ast.get_data1(callee), self.ast.get_data1(node), self.ast.get_data2(node), node)
            if self.ast.kind(callee) == NodeKind.NK_INDEX:
                let generic_method_base = self.ast.get_data0(callee)
                if self.ast.kind(generic_method_base) == NodeKind.NK_FIELD_ACCESS:
                    return self.lower_method_call(self.ast.get_data0(generic_method_base), self.ast.get_data1(generic_method_base), self.ast.get_data1(node), self.ast.get_data2(node), node)
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
                    // #671: only an expected type that actually carries this
                    // variant may override the constructor's own enum. An
                    // ambient expectation from an outer construct (a statement's
                    // void, an enclosing fn's return type) otherwise types the
                    // aggregate as a non-enum and codegen has no destination.
                    // The sema-level lookup is the strict one; the MirLower
                    // wrapper falls back to a by-symbol index for ANY type.
                    if self.expected_type != 0 and self.sema.enum_variant_discriminant_for_type(self.expected_type, vc_sym) >= 0:
                        vc_result_ty = self.expected_type
                    if vc_result_ty == 0 or vc_result_ty == self.sema.ty_void as i32:
                        vc_result_ty = self.sema.variant_type_ids.get(vc_sym).unwrap()
                    var vc_variant_idx = self.enum_variant_discriminant_for_type(vc_result_ty, vc_sym)
                    if vc_variant_idx < 0:
                        vc_variant_idx = self.sema.variant_lookup.get(vc_sym).unwrap()
                    let vc_payload_tys = self.sema.enum_variant_payload_types_frozen(vc_result_ty, vc_sym)
                    let vc_args_start = self.ast.get_data1(node)
                    let vc_has_resolved = self.sema.has_resolved_call_args(node)
                    let vc_args_count = if vc_has_resolved != 0: self.sema.get_resolved_call_arg_count(node) else: self.ast.get_data2(node)
                    let vc_fields: Vec[i32] = Vec.new()
                    let vc_names: Vec[i32] = Vec.new()
                    for vci in 0..vc_args_count:
                        let vc_arg = if vc_has_resolved != 0: self.sema.get_resolved_call_arg(node, vci) else: self.ast.get_extra(vc_args_start + vci)
                        let saved_expected = self.expected_type
                        var vc_payload_ty = 0
                        if vci < vc_payload_tys.len() as i32:
                            vc_payload_ty = vc_payload_tys.get(vci as i64)
                            if vc_payload_ty != 0:
                                self.expected_type = vc_payload_ty
                        let vc_arg_op = if vc_arg == 0: self.unit_operand() else: self.lower_expr(vc_arg)
                        vc_fields.push(vc_arg_op)
                        self.expected_type = saved_expected
                        vc_names.push(0)
                        // #605/#606 (#698): move a Drop payload into the variant;
                        // consume the source so it is not also dropped at its
                        // scope/statement flush. This call-form constructor path
                        // (`Some(x)` as NK_CALL) was the one aggregate builder
                        // missing the consume — masked while tail-position temps
                        // never registered; the fn-level frame exposed it.
                        if vc_arg != 0:
                            let vc_arg_drop_ty = if vc_payload_ty != 0: vc_payload_ty else: self.expr_type(vc_arg)
                            if self.sema.type_needs_drop_frozen(vc_arg_drop_ty) != 0:
                                self.consume_moved_operand(vc_arg_op)
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
                    let dt_tid: i32 = self.sema.distinct_type_names.get(dt_sym).unwrap()
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
                if gc_sym == self.sema.syms.src:
                    return self.source_location_operand(node)
                let gc_fn_sym = self.sema_symbol_for_ast_symbol(gc_sym)
                if self.sema.fn_symbol_is_std_builtins_drop(gc_sym) != 0:
                    return self.lower_std_drop_call(node)
                let selected_gc_fn_node = self.sema.resolved_generic_call_nodes.get(node)
                let gc_fn_node = if selected_gc_fn_node.is_some(): selected_gc_fn_node.unwrap() else: self.generic_fn_node_for_sym(gc_fn_sym)
                if gc_fn_node != 0:
                    // User generic calls use Sema's concrete signature for both
                    // ownership lowering and the eventual ABI contract.
                    let gc_fn_op = self.const_operand(ConstKind.CK_FN, gc_fn_sym, 0)
                    var gc_sig_idx = self.call_sig_for_sym(gc_fn_sym)
                    let gc_recorded_sig = self.sema.resolved_call_sigs.get(node)
                    if gc_recorded_sig.is_some():
                        gc_sig_idx = gc_recorded_sig.unwrap()
                    let gc_args: Vec[i32] = Vec.new()
                    let gc_as = self.ast.get_data1(node)
                    let gc_ac = self.ast.get_data2(node)
                    for gc_ai in 0..gc_ac:
                        let gc_arg_node = self.ast.get_extra(gc_as + gc_ai)
                        gc_args.push(self.lower_call_arg(gc_arg_node, gc_sig_idx, 0, gc_ai))
                    // Fill default values for omitted trailing parameters, the same
                    // as non-generic calls do in lower_call (#302).
                    let gc_meta = self.ast.find_fn_meta(gc_fn_node)
                    if gc_meta >= 0:
                        let gc_ps = self.ast.fn_meta_param_start(gc_meta)
                        let gc_pc = self.ast.fn_meta_param_count(gc_meta)
                        for gc_di in gc_ac..gc_pc:
                            let gc_def = self.ast.get_fn_param_default(gc_ps, gc_di)
                            if gc_def != 0:
                                gc_args.push(self.lower_default_call_arg(gc_def, node, gc_sig_idx, 0, gc_di))
                    let gc_args_id = self.body.new_call_args(gc_args)
                    self.body.set_call_intrinsic(gc_args_id, MirIntrinsic.GENERIC_CALL)
                    self.require_generic_call_contract(gc_args_id, gc_fn_sym, 0, 0, gc_recorded_sig.is_some(), "free-generic")
                    self.body.set_call_ast_node(gc_args_id, node)
                    self.record_call_contract(gc_args_id, node, gc_sig_idx)
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
            let call_ty = self.expr_type(node)
            return self.lower_call(callee, self.ast.get_data1(node), self.ast.get_data2(node), call_ty, node)

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
                let form: i32 = self.sema.with_form_kinds.get(node).unwrap()
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
                var f_op = 0
                var f_ref_done = 0
                if f_ty != 0:
                    let f_ty_res = self.sema.resolve_alias(f_ty as TypeId)
                    if self.sema.get_type_kind(f_ty_res) == TypeKind.TY_REF:
                        let init_ty = self.expr_type(f_val_node)
                        if init_ty != 0 and self.sema.get_type_kind(self.sema.resolve_alias(init_ty as TypeId)) != TypeKind.TY_REF:
                            let init_kind = self.ast.kind(f_val_node)
                            if init_kind == NodeKind.NK_IDENT or init_kind == NodeKind.NK_FIELD_ACCESS:
                                // A &-typed field initialized from a place is an
                                // implicit borrow: store the place's ADDRESS.
                                // Lowering the value bit-copied a str header into
                                // the ref slot — view.source then dereferenced
                                // text bytes as a header (derive_deserialize SEGV).
                                let ref_place = self.lower_expr_place(f_val_node)
                                if self.place_type_is_str(ref_place) != 0:
                                    self.mark_string_place_copied(ref_place)
                                let ref_rv = self.body.new_rvalue(RvalueKind.RK_REF, BorrowKind.SHARED, ref_place, 0)
                                let ref_temp = self.new_temp(f_ty)
                                let ref_temp_place = self.place_for_local(ref_temp)
                                self.body.push_stmt(self.cur_bb, StmtKind.Assign, ref_temp_place, ref_rv, self.ast.get_start(f_val_node))
                                f_op = self.body.new_operand(OperandKind.OK_COPY, ref_temp_place)
                                f_ref_done = 1
                if f_ref_done == 0:
                    f_op = self.lower_expr(f_val_node)
                sl_fields.push(f_op)
                sl_names.push(resolved_name)
                self.expected_type = saved_expected
                // #605: a Drop-bearing field value is moved into the aggregate; mark
                // the source consumed so it is not also dropped at its scope exit
                // (otherwise its destructor runs twice -> double-free). Gated on a
                // Drop impl: non-Drop value types are left to copy, which the
                // codebase relies on to share data across constructions and which is
                // harmless without a destructor.
                if self.sema.type_needs_drop_frozen(f_ty) != 0:
                    self.consume_moved_operand(f_op)
            if self.sema.type_decl_nodes.contains(sl_name_sym):
                let sl_td_node: i32 = self.sema.type_decl_nodes.get(sl_name_sym).unwrap()
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
                            let def_op = self.lower_expr(decl_default)
                            sl_fields.push(def_op)
                            sl_names.push(decl_field_name)
                            self.expected_type = saved_expected
                            if self.sema.type_has_drop_impl(decl_field_ty) != 0:
                                self.consume_moved_operand(def_op)
            let sl_fid = self.body.new_agg_fields(sl_fields, sl_names)
            let sl_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, sl_fid, 0)
            var sl_ty = self.expr_type(node)
            if (sl_ty == 0 or sl_ty == self.sema.ty_void) and self.expected_type > 0:
                sl_ty = self.expected_type
            let sl_tmp = self.new_temp(sl_ty)
            let sl_place = self.place_for_local(sl_tmp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, sl_place, sl_rv, self.ast.get_start(node))
            self.update_string_fields_after_aggregate(sl_place, sl_fid)
            return self.body.new_operand(if self.type_needs_value_drop(sl_ty) == 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, sl_place)

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
                var elem_ty = self.expr_type(elem_node)
                if expected_tuple != 0:
                    let exp_elem: i32 = self.sema.type_extra.get((expected_elem_start + i) as i64)
                    self.expected_type = exp_elem
                    if elem_ty == 0 or elem_ty == self.sema.ty_void as i32:
                        elem_ty = exp_elem
                let elem_op = self.lower_expr(elem_node)
                tup_fields.push(elem_op)
                self.expected_type = saved_expected
                tup_names.push(0)
                // #605/#606: a Drop element is moved into the tuple; consume the
                // source so its destructor is not also run at its scope exit (which
                // would double-free). Paired with the tuple's element-drop
                // (mir_emit_drop_tuple_ptr) — both land together.
                if self.sema.type_needs_drop_frozen(elem_ty) != 0:
                    self.consume_moved_operand(elem_op)
            let tup_fid = self.body.new_agg_fields(tup_fields, tup_names)
            let tup_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, tup_fid, 0)
            let tup_ty = self.expr_type(node)
            let tup_tmp = self.new_temp(tup_ty)
            let tup_place = self.place_for_local(tup_tmp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, tup_place, tup_rv, self.ast.get_start(node))
            return self.body.new_operand(if self.type_needs_value_drop(tup_ty) == 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, tup_place)

        if kind == NodeKind.NK_ARRAY_LIT:
            let collection_op = self.lower_collection_seq_literal(node)
            if collection_op >= 0:
                return collection_op
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
            // #586: elements lower under the ARRAY'S ELEMENT type, not the ambient
            // expected type. Without the rebind, the array/let type leaked into
            // enum-variant element temps (Some(1) inside [?i32] typed as the ARRAY
            // type), failing codegen when annotated and silently corrupting the
            // values when un-annotated. Mirrors the NK_TUPLE per-element rebind.
            let arr_saved_expected = self.expected_type
            var arr_elem_expected = 0
            var arr_lit_ty = self.expr_type(node)
            if arr_lit_ty == 0 or arr_lit_ty == self.sema.ty_void as i32:
                // Annotated bindings (`let a: [?i32] = [...]`) type the literal via
                // the annotation, not the node — take the array type from the
                // ambient expectation instead.
                arr_lit_ty = self.expected_type
            if arr_lit_ty != 0:
                let arr_lit_resolved = self.sema.resolve_alias(arr_lit_ty as TypeId)
                let arr_lit_kind = self.sema.get_type_kind(arr_lit_resolved)
                // `[?i32]` (length-less annotation) resolves as a slice; both
                // array and slice carry the element type in d0.
                if arr_lit_kind == TypeKind.TY_ARRAY or arr_lit_kind == TypeKind.TY_SLICE:
                    arr_elem_expected = self.sema.get_type_d0(arr_lit_resolved)
            for i in 0..elem_count:
                let elem_node = self.ast.get_extra(extra_start + i)
                if arr_elem_expected != 0:
                    self.expected_type = arr_elem_expected
                let arr_elem_op = self.lower_expr(elem_node)
                self.expected_type = arr_saved_expected
                arr_fields.push(arr_elem_op)
                arr_names.push(0)
                // #605/#606: move a Drop element into the array; consume the source so
                // it is not also dropped at scope exit. Paired with the array's
                // element-drop (mir_emit_drop_array_ptr) — both land together.
                if self.sema.type_needs_drop_frozen(self.expr_type(elem_node)) != 0:
                    self.consume_moved_operand(arr_elem_op)
            let arr_fid = self.body.new_agg_fields(arr_fields, arr_names)
            let arr_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, arr_fid, 0)
            let arr_ty = self.expr_type(node)
            let arr_tmp = self.new_temp(arr_ty)
            let arr_place = self.place_for_local(arr_tmp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, arr_place, arr_rv, self.ast.get_start(node))
            return self.body.new_operand(if self.type_needs_value_drop(arr_ty) == 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, arr_place)

        if kind == NodeKind.NK_MAP_LIT:
            return self.lower_map_literal(node)

        if kind == NodeKind.NK_VARIANT_SHORTHAND:
            var vs_name_sym = self.resolve_variant_sym(node)
            let vs_args_start = self.ast.get_data1(node)
            let vs_arg_count = self.ast.get_data2(node)
            var vs_result_ty = self.expr_type(node)
            if (vs_result_ty == 0 or vs_result_ty == self.sema.ty_void as i32) and self.expected_type != 0 and self.expected_type != self.sema.ty_void as i32:
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
            let vs_payload_tys = self.sema.enum_variant_payload_types_frozen(vs_result_ty, vs_name_sym)
            for vsi in 0..vs_arg_count:
                let vs_arg = self.ast.get_extra(vs_args_start + vsi)
                let saved_expected = self.expected_type
                var vs_payload_ty = 0
                if vsi < vs_payload_tys.len() as i32:
                    vs_payload_ty = vs_payload_tys.get(vsi as i64)
                    if vs_payload_ty != 0:
                        self.expected_type = vs_payload_ty
                // #933: a payload is a call argument — apply Sema's recorded
                // adjustments in lower_call_arg's order (auto-reference, then
                // the D22 contextual copy) before a plain lowering. Skipping
                // them stored a `&i32` view where `Option[i32]` demanded the
                // value (read back as 0) and would store a value where a
                // reference was expected.
                var vs_arg_op = -1
                if vs_payload_ty != 0:
                    vs_arg_op = self.lower_auto_ref_call_arg(vs_arg, vs_payload_ty)
                    if vs_arg_op < 0:
                        vs_arg_op = self.lower_auto_copy_ref_call_arg(vs_arg, vs_payload_ty)
                    if vs_arg_op < 0:
                        vs_arg_op = self.lower_auto_deref_call_arg(vs_arg, vs_payload_ty)
                if vs_arg_op < 0:
                    vs_arg_op = self.lower_expr(vs_arg)
                vs_fields.push(vs_arg_op)
                self.expected_type = saved_expected
                vs_names.push(0)
                // #605/#606: move a Drop payload into the enum variant; consume the
                // source so it is not also dropped at scope exit. Paired with the
                // enum's variant-aware payload drop (mir_emit_drop_enum_ptr).
                let vs_arg_drop_ty = if vs_payload_ty != 0: vs_payload_ty else: self.expr_type(vs_arg)
                if self.sema.type_needs_drop_frozen(vs_arg_drop_ty) != 0:
                    self.consume_moved_operand(vs_arg_op)
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
            // Stage 6: the niche makes a moved receiver's scope-exit drop inert —
            // reset-on-move blanks it, and the guarded drop / moved-skip elide it —
            // so we keep the drop scheduled rather than cancel it. Canceling (the
            // old behavior for non-flagged moves) would skip the drop on a path
            // where a conditional move did NOT fire, leaking the still-live value
            // (da_drop_conditional_move_value / da_match_conditional_move_value).
            let mv_inner = self.ast.get_data0(node)
            // D17: a Drop-bearing field-place move lowers as an explicit OK_MOVE
            // of the projected place, so consume_moved_operand records the
            // field-path move and emits the reset-on-move blank through whatever
            // pointer reaches the base (#697 machinery). A POD field has nothing
            // to blank — `move w.f` is a plain copy and must not enter the move
            // machinery (marking it moved would wrongly suppress a Drop owner's
            // partial drop).
            if self.ast.kind(mv_inner) == NodeKind.NK_FIELD_ACCESS:
                let mv_fty = self.expr_type(mv_inner)
                if mv_fty != 0 and self.sema.type_needs_drop_frozen(mv_fty) != 0:
                    let mv_place = self.lower_expr_place(mv_inner)
                    if mv_place >= 0:
                        return self.body.new_operand(OperandKind.OK_MOVE, mv_place)
            return self.lower_expr(mv_inner)

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
            let inner = self.ast.get_data0(node)
            let selected_opt = self.sema.comptime_selected_branches.get(node)
            if selected_opt.is_some():
                let selected: i32 = selected_opt.unwrap()
                if selected != 0:
                    return self.lower_expr(selected)
                return self.unit_operand()
            // Non-generic comptime branches are already pruned by ComptimeTransform.
            // Just unwrap and lower the inner expression.
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
                var ta_owns: Vec[i32] = Vec.new()
                for ta_i in 0..ta_count:
                    let ta_elem = self.ast.get_extra(ta_extra + ta_i)
                    ta_owns.push(self.await_task_owns_result(ta_elem))
                    self.cancel_scheduled_value_drop_for_receiver_expr(ta_elem)
                    ta_task_ops.push(self.lower_expr(ta_elem))
                // Await each sequentially, collect results
                var ta_awaited_ops: Vec[i32] = Vec.new()
                var ta_awaited_names: Vec[i32] = Vec.new()
                for ta_i in 0..ta_count:
                    let ta_elem_ty = self.tuple_elem_type(ta_result_ty, ta_i)
                    let ta_elem_node = self.ast.get_extra(ta_extra + ta_i)
                    let ta_task_ty = self.expr_type(ta_elem_node)
                    let ta_op = self.lower_single_await(ta_task_ops.get(ta_i as i64), ta_elem_ty, ta_task_ty, node, ta_owns.get(ta_i as i64))
                    ta_awaited_ops.push(ta_op)
                    ta_awaited_names.push(0)
                // Build result tuple via RK_AGGREGATE
                let ta_agg_id = self.body.new_agg_fields(ta_awaited_ops, ta_awaited_names)
                let ta_agg_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, ta_agg_id, 0)
                let ta_tmp = self.new_temp(ta_result_ty)
                let ta_place = self.place_for_local(ta_tmp)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, ta_place, ta_agg_rv, self.ast.get_start(node))
                return self.body.new_operand(OperandKind.OK_COPY, ta_place)

            // Single task await. Compute ownership BEFORE the cancel (which removes
            // the scheduled drop the query looks for).
            let single_await_owns = self.await_task_owns_result(inner)
            self.cancel_scheduled_value_drop_for_receiver_expr(inner)
            let task_op = self.lower_expr(inner)
            let result_ty = self.expr_type(node)
            let task_inner_ty = self.expr_type(inner)
            return self.lower_single_await(task_op, result_ty, task_inner_ty, node, single_await_owns)

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
            let create_unit = self.unit_operand()
            self.terminate(TermKind.TK_CALL, create_unit, create_call_id, scope_place, after_create_bb)
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
            let create_unit = self.unit_operand()
            self.terminate(TermKind.TK_CALL, create_unit, create_call_id, scope_place, after_create_bb)
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

            // 1. Lower each arm's task expression → task operands. Capture ownership
            // BEFORE the cancel (§14.7/G3): the winner's value-await frees its result
            // buffer iff this scope owns the task (its drop, cancelled just below).
            var task_ops: Vec[i32] = Vec.new()
            var sel_owns: Vec[i32] = Vec.new()
            for ai in 0..arm_count:
                let task_node = self.ast.get_extra(extra_start + ai * 3 + 1)
                sel_owns.push(self.await_task_owns_result(task_node))
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
            let select_unit = self.unit_operand()
            self.terminate(TermKind.TK_CALL, select_unit, select_call_id, select_result_place, switch_bb)
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
                self.switch_to(arm_bbs.get(ai as i64) as BlockId)
                let arm_name = self.ast.get_extra(extra_start + ai * 3)
                let task_node = self.ast.get_extra(extra_start + ai * 3 + 1)
                let arm_body = self.ast.get_extra(extra_start + ai * 3 + 2)

                // Await the winning task to get its result
                let await_args: Vec[i32] = Vec.new()
                await_args.push(task_ops.get(ai as i64))
                await_args.push(self.const_operand(ConstKind.CK_INT, sel_owns.get(ai as i64), self.sema.ty_i32))
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
                let await_unit = self.unit_operand()
                self.terminate(TermKind.TK_CALL, await_unit, await_call_id, await_result_place, after_await_bb)
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
                        let cancel_unit = self.unit_operand()
                        self.terminate(TermKind.TK_CALL, cancel_unit, cancel_call_id, cancel_result_place, after_cancel_bb)
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

fn mir_symbol_for_pool(sema: &Sema, pool: InternPool, sym: i32) -> i32:
    if sym == 0:
        return 0
    // sym is a Sema-pool identity. Numeric symbol IDs have meaning only in
    // their originating pool; probing the output pool with this integer can
    // silently select an unrelated symbol when both pools contain that slot.
    let sema_name = sema.pool_resolve(sym)
    if sema_name.len() > 0:
        return pool.intern(sema_name)
    sym

fn lower_fn_with_sig(builder: MirBuilder, fn_node: i32, sig_idx: i32) -> MirBody:
    if builder.ast.fn_decl_body_is_interface(fn_node):
        sema_phase_bug("BUG: interface body reached MIR lowering (D39: lower_module skips interface declarations)")
    builder.contextual_fact_sig_idx = sig_idx
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
        let drop_body = builder.fn_node_is_drop_body(fn_node)

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
                    p_ty = builder.sema.resolve_type_expr_frozen(p_type_node) as i32
                if p_ty == 0:
                    p_ty = builder.sema.ty_i32 as i32
            let local_id = builder.body.new_local(p_ty, 0, p_name, 1)
            builder.bind_local(p_name, local_id)
            builder.body.push_stmt(builder.cur_bb, StmtKind.StorageLive, local_id, 0, builder.ast.get_start(fn_node))
            if builder.local_type_is_str(local_id) != 0:
                builder.set_string_local_flags(local_id, 1)
            let drop_receiver_self = drop_body != 0 and i == 0 and builder.symbol_text(p_name) == "self"
            // §9.5/#641a: `mut self`/`&self` receivers are BORROWS of the
            // caller's place — the callee does not own them and must not drop
            // them at scope exit. Only consuming receivers (`move self`, and
            // the legacy unflagged `self: ConcreteType` form) are owned here.
            let recv_flags = builder.ast.fn_param_flags(param_start, i)
            let borrowed_receiver = i == 0 and (fn_param_is_mut_self(recv_flags) != 0 or fn_param_is_ref_self(recv_flags) != 0)
            // §9.5/#D5: a `move self` receiver is CONSUMED — the callee owns it and
            // drops it at scope exit (the drop is elided if self, or a field of
            // self, is moved out — e.g. `-> Self: self` or `-> T: self.field`). The
            // caller consumes it at the call site (lower_method_call), so exactly
            // one drop occurs. A read-only move-self body would otherwise infer
            // effect READ and be mis-classified share-place, dropping nothing here.
            let move_self_receiver = i == 0 and fn_param_is_move_self(recv_flags) != 0
            // #D5/P1: a share-place param (PassMode::IndirectPlace / value_ref_abi)
            // is a BORROW of the caller's place — the callee mutates it but does
            // NOT own it, so it is dropped in the caller's scope, not here. Only
            // owned params (consume/escape_value → not value_ref_abi, and move-self
            // receivers) are dropped by the callee.
            let share_place_param = sig_idx >= 0 and builder.sema.sig_param_uses_value_ref_abi(sig_idx, i) != 0 and not move_self_receiver
            if builder.sema.is_copy_frozen(p_ty) == 0 and drop_receiver_self == 0 and not borrowed_receiver and not share_place_param:
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
                        let param_place = builder.place_for_local(param_locals.get(i as i64))
                        let _ = builder.lower_pattern(ppat, param_place)

    // Set expected_type to the function's return type so that intrinsic calls
    // (Vec.new, HashMap.new) in tail position can resolve their generic inst type.
    // Typed let: body lowering GROWS local_type_ids (every new_temp pushes),
    // so an element view here dangles by the time the implicit-Ok wrap
    // decision reads it — stage2's build() returned unwrapped Config bits.
    let ret_ty: i32 = builder.body.local_type_ids.get(0)
    builder.expected_type = ret_ty

    let ret_is_void = ret_ty == builder.sema.ty_void
    // #697/D17: the body's TAIL expression lowers without a per-statement
    // frame, so its call-result temps had nowhere to register — an rvalue
    // argument to a share-place callee was dropped by NOBODY (the callee
    // borrows; the caller never scheduled it). One fn-level frame catches
    // every temp the inner statement frames don't; it flushes in the
    // epilogue, after the return value is captured.
    let body_frame = builder.push_stmt_temp_frame()
    let body_falls_through = builder.sema.body_can_fall_through(body_expr)
    var result = if ret_is_void:
        builder.lower_expr_discard(body_expr)
    else:
        let tail_raw = builder.lower_expr(body_expr)
        let tail_adj = builder.adjust_ret_operand_auto_ref(tail_raw, body_expr, ret_ty, builder.ast.get_end(fn_node))
        let body_result = if tail_adj >= 0: tail_adj else: tail_raw
        if body_falls_through != 0 and builder.operand_type(body_result) == builder.sema.ty_void:
            builder.lower_implicit_default_return(ret_ty, builder.ast.get_end(fn_node))
        else:
            body_result

    // Implicit Ok wrapping: if return type is Result[T, E] and body type is T,
    // wrap the result in Ok(value) — an enum variant construction with tag 0.
    let ret_resolved = builder.sema.resolve_alias(ret_ty)
    if body_falls_through != 0 and not ret_is_void and builder.sema.get_type_kind(ret_resolved) == TypeKind.TY_GENERIC_INST:
        let ret_base = builder.sema.get_generic_inst_base(ret_resolved)
        if builder.sema.pool_resolve(ret_base) == "Result" and builder.sema.get_generic_inst_arg_count(ret_resolved) == 2:
            let result_body_ty = builder.expr_type(body_expr)
            let ok_type = builder.sema.get_generic_inst_arg(ret_resolved, 0)
            if result_body_ty != 0 and result_body_ty != ret_ty:
                if builder.sema.types_compatible_frozen(ok_type, result_body_ty) != 0 or builder.sema.arithmetic_result_type(ok_type, result_body_ty) != 0:
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
    if body_falls_through != 0 and not ret_is_void:
        let ret_place = builder.place_for_local(0)
        builder.assign_operand_to_place(ret_place, result, builder.ast.get_end(fn_node))

    // D16/D17: close the fn-level frame — tail-created temps drop and pending
    // source-resets/move-arg temps land here, after the return value is
    // captured, before the epilogue drops. Without this a tail
    // `eat(move self.r)` never blanks the caller's field, and a tail
    // `peek_h(mk(s))` leaks the rvalue temp (the share-place callee borrows;
    // only the caller can drop it).
    builder.finish_stmt_temp_frame(body_frame)
    builder.emit_defers_for_return()
    builder.pop_scope_inline()
    builder.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

    // Self-tail-call optimization for @[tailrec] functions.
    if (fn_flags / FnFlags.TAILREC) % 2 == 1:
        builder.body.optimize_self_tail_calls()

    // D32: field vacates need a mutable path — rebind the owned param.
    var owned_builder = builder
    return move owned_builder.body

fn lower_fn_clause_dispatcher(sema: &Sema, ast_pool: AstPool, pool: InternPool, group: i32) -> MirBody:
    let dispatch_sym = sema.fn_clause_group_name(group)
    let sig_idx = sema.get_sig(dispatch_sym)
    let dispatch_body_sym = mir_symbol_for_pool(sema, pool, dispatch_sym)
    var builder = MirBuilder.init(sema, ast_pool, pool, dispatch_body_sym)
    if sig_idx < 0:
        builder.body.local_type_ids.set_i32(0, sema.ty_void)
        builder.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)
        return move builder.body

    let ret_ty = sema.sig_return_type(sig_idx)
    builder.body.local_type_ids.set_i32(0, ret_ty)
    builder.push_scope()

    let clause_count = sema.fn_clause_group_clause_count(group)
    let first_clause = if clause_count > 0: sema.fn_clause_group_clause(group, 0) else: 0
    let first_meta = if first_clause != 0: ast_pool.find_fn_meta(first_clause) else: -1
    let param_count = sema.sig_get_param_count(sig_idx)
    let param_locals: Vec[i32] = Vec.new()
    for pi in 0..param_count:
        var p_name = pool.intern(f"__param_{pi}")
        if first_meta >= 0:
            let first_param_start = ast_pool.fn_meta_param_start(first_meta)
            if pi < ast_pool.fn_meta_param_count(first_meta):
                p_name = ast_pool.fn_param_name(first_param_start, pi)
        let p_ty = sema.sig_param_type(sig_idx, pi)
        let local_id = builder.body.new_local(p_ty, 0, p_name, 1)
        builder.bind_local(p_name, local_id)
        builder.body.push_stmt(builder.cur_bb, StmtKind.StorageLive, local_id, 0, if first_clause != 0: ast_pool.get_start(first_clause) else: 0)
        if builder.local_type_is_str(local_id) != 0:
            builder.set_string_local_flags(local_id, 1)
        // §9.5/#641a parity with lower_fn_with_sig: borrow-mode receivers are
        // not owned by the callee — no scope-exit drop.
        var clause_borrowed_receiver = false
        var clause_move_self = false
        if pi == 0 and first_meta >= 0 and 0 < ast_pool.fn_meta_param_count(first_meta):
            let clause_recv_flags = ast_pool.fn_param_flags(ast_pool.fn_meta_param_start(first_meta), 0)
            clause_borrowed_receiver = fn_param_is_mut_self(clause_recv_flags) != 0 or fn_param_is_ref_self(clause_recv_flags) != 0
            clause_move_self = fn_param_is_move_self(clause_recv_flags) != 0
        // #D5/P1: share-place (value_ref_abi) params are borrows — not callee-dropped.
        // A move-self receiver is owned (§9.5/#D5) and dropped by the callee.
        let clause_share_place = sig_idx >= 0 and sema.sig_param_uses_value_ref_abi(sig_idx, pi) != 0 and not clause_move_self
        if sema.is_copy_frozen(p_ty) == 0 and not clause_borrowed_receiver and not clause_share_place:
            builder.schedule_drop(local_id, DropKind.DK_VALUE)
        param_locals.push(local_id)
    builder.body.n_params = param_count

    var dispatch_bb = builder.cur_bb
    for ci in 0..clause_count:
        let clause_node = sema.fn_clause_group_clause(group, ci)
        let clause_di = sema.find_decl_index(clause_node)
        let clause_sym = mir_symbol_for_pool(sema, pool, sema.fn_decl_semantic_symbol_at(clause_node, ast_pool.get_data0(clause_node), clause_di))
        let clause_meta = ast_pool.find_fn_meta(clause_node)
        let arm_bb = builder.new_block()
        let fail_bb = if ci + 1 < clause_count: builder.new_block() else: builder.new_block()

        builder.switch_to(dispatch_bb)
        var cur_test_bb = dispatch_bb
        if clause_meta >= 0:
            let pmeta = ast_pool.find_fn_param_pattern_meta(clause_node)
            if pmeta >= 0:
                let ppat_start = ast_pool.fn_param_pattern_meta_start(pmeta)
                let ppat_count = ast_pool.fn_param_pattern_meta_count(pmeta)
                for pi in 0..param_count:
                    if pi < ppat_count:
                        let ppat = ast_pool.fn_param_pattern_value(ppat_start + pi)
                        if ppat != 0:
                            let next_test_bb = builder.new_block()
                            builder.switch_to(cur_test_bb)
                            let param_place = builder.place_for_local(param_locals.get(pi as i64))
                            builder.lower_pattern_match(param_place, ppat, next_test_bb, fail_bb)
                            cur_test_bb = next_test_bb
            builder.switch_to(cur_test_bb)
            builder.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        else:
            builder.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)

        builder.switch_to(arm_bb)
        let fn_op = builder.const_operand(ConstKind.CK_FN, clause_sym, sema.ty_void)
        let args: Vec[i32] = Vec.new()
        for pi2 in 0..param_count:
            let p_ty = sema.sig_param_type(sig_idx, pi2)
            let place = builder.place_for_local(param_locals.get(pi2 as i64))
            args.push(builder.body.new_operand(if sema.is_copy_frozen(p_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, place))
        let args_id = builder.body.new_call_args(args)
        let call_ret_local = builder.new_temp(ret_ty)
        let call_ret_place = builder.place_for_local(call_ret_local)
        let after_call_bb = builder.new_block()
        builder.terminate(TermKind.TK_CALL, fn_op, args_id, call_ret_place, after_call_bb)
        builder.switch_to(after_call_bb)
        if ret_ty != sema.ty_void:
            let ret_op = builder.body.new_operand(if sema.is_copy_frozen(ret_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, call_ret_place)
            let ret_place = builder.place_for_local(0)
            builder.assign_operand_to_place(ret_place, ret_op, ast_pool.get_start(clause_node))
        builder.emit_drops_for_return()
        builder.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

        dispatch_bb = fail_bb

    builder.switch_to(dispatch_bb)
    let panic_sym = sema.pool_lookup_symbol("with_panic")
    let panic_op = builder.const_operand(ConstKind.CK_FN, panic_sym, sema.ty_void)
    let panic_args: Vec[i32] = Vec.new()
    panic_args.push(builder.lower_str_lit(pool.intern("no function clause matched")))
    panic_args.push(builder.lower_str_lit(pool.intern("")))
    panic_args.push(builder.int_const_operand(0, sema.ty_i32))
    let panic_args_id = builder.body.new_call_args(panic_args)
    let panic_tmp = builder.new_temp(sema.ty_void)
    let panic_place = builder.place_for_local(panic_tmp)
    let unreachable_bb = builder.new_block()
    builder.terminate(TermKind.TK_CALL, panic_op, panic_args_id, panic_place, unreachable_bb)
    builder.switch_to(unreachable_bb)
    builder.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)
    return move builder.body

impl MirBody:
    mut fn optimize_self_tail_calls():
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
            let span: i32 = self.bb_term_spans.get(bb as i64)
            // Copy args to temps
            for ai in 0..arg_count:
                if ai >= n_params: break
                let arg_op: i32 = self.call_arg_operands.get((arg_start + ai) as i64)
                let param_local = ai + 1  // params are locals 1..n_params
                let param_ty: i32 = self.local_type_ids.get(param_local as i64)
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

fn mir_gen_resume_field_sym(sema: &Sema) -> i32:
    sema.pool_lookup_symbol("__with_generator_resume")

fn mir_gen_state_field_start(sema: &Sema, state_tid: i32) -> i32:
    let resolved = sema.resolve_alias(state_tid as TypeId) as i32
    if resolved <= 0 or resolved >= sema.type_d1.len() as i32:
        return 0
    sema.type_d1.get(resolved as i64)

fn mir_gen_state_field_count(sema: &Sema, state_tid: i32) -> i32:
    let resolved = sema.resolve_alias(state_tid as TypeId) as i32
    if sema.generator_state_field_counts.contains(resolved):
        return sema.generator_state_field_counts.get(resolved).unwrap()
    if resolved <= 0 or resolved >= sema.type_d2.len() as i32:
        return 0
    sema.type_d2.get(resolved as i64)

fn mir_gen_state_field_sym(sema: &Sema, state_tid: i32, field_i: i32) -> i32:
    let resolved = sema.resolve_alias(state_tid as TypeId) as i32
    let key = sema_pair_key(resolved, field_i)
    if sema.generator_state_field_names.contains(key):
        return sema.generator_state_field_names.get(key).unwrap()
    let start = mir_gen_state_field_start(sema, state_tid)
    sema.type_extra.get((start + field_i * 3) as i64)

fn mir_gen_state_field_type(sema: &Sema, state_tid: i32, field_i: i32) -> i32:
    let resolved = sema.resolve_alias(state_tid as TypeId) as i32
    let key = sema_pair_key(resolved, field_i)
    if sema.generator_state_field_types.contains(key):
        return sema.generator_state_field_types.get(key).unwrap()
    let start = mir_gen_state_field_start(sema, state_tid)
    sema.type_extra.get((start + field_i * 3 + 1) as i64)

fn mir_gen_find_local_by_sym(body: &MirBody, sym: i32) -> i32:
    if sym == 0:
        return -1
    for li in 1..body.local_names.len() as i32:
        if body.local_names.get(li as i64) == sym:
            return li
    -1

impl MirBody:
    mut fn gen_self_field_place(field_sym: i32, field_ty: i32) -> i32:
        let self_place = self.new_place(1)
        self.new_field_place(self_place, field_sym, field_ty)

    mut fn gen_assign_operand(bb: i32, place: i32, op: i32, span: i32):
        let rv = self.new_rvalue(RvalueKind.RK_USE, op, 0, 0)
        self.push_stmt(bb, StmtKind.Assign, place, rv, span)

    mut fn gen_zero_operand(tid: i32) -> i32:
        let c = self.new_const(ConstKind.CK_ZERO_SIZED, 0, 0, 0, tid)
        self.new_operand(OperandKind.OK_CONSTANT, c)

    mut fn gen_assign_option_some(bb: i32, opt_ty: i32, value_op: i32, span: i32):
        let fields: Vec[i32] = Vec.new()
        let names: Vec[i32] = Vec.new()
        fields.push(value_op)
        names.push(0)
        let fid = self.new_agg_fields(fields, names)
        let rv = self.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fid, 0)
        let ret_place = self.new_place(0)
        let _ = opt_ty
        self.push_stmt(bb, StmtKind.Assign, ret_place, rv, span)

    mut fn gen_assign_option_none(bb: i32, opt_ty: i32, span: i32):
        let fields: Vec[i32] = Vec.new()
        let names: Vec[i32] = Vec.new()
        let fid = self.new_agg_fields(fields, names)
        let rv = self.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fid, 1)
        let ret_place = self.new_place(0)
        let _ = opt_ty
        self.push_stmt(bb, StmtKind.Assign, ret_place, rv, span)

    mut fn gen_store_resume_state(bb: i32, sema: &Sema, state_tid: i32, value: i64, span: i32):
        let resume_sym = mir_gen_resume_field_sym(sema)
        let resume_place = self.gen_self_field_place(resume_sym, sema.ty_i32 as i32)
        let c = self.new_const(ConstKind.CK_INT, ast_int_part0(value), ast_int_part1(value), ast_int_part2(value), sema.ty_i32 as i32)
        let op = self.new_operand(OperandKind.OK_CONSTANT, c)
        self.gen_assign_operand(bb, resume_place, op, span)

    mut fn gen_save_generator_fields(bb: i32, sema: &Sema, state_tid: i32, span: i32):
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

    mut fn gen_restore_generator_fields(bb: i32, sema: &Sema, state_tid: i32, span: i32):
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

fn mir_gen_remap_local(local_map: &Vec[i32], local_id: i32) -> i32:
    if local_id < 0 or local_id >= local_map.len() as i32:
        return local_id
    local_map.get(local_id as i64)

fn mir_gen_remap_place_projection_data(source: &MirBody, local_map: &Vec[i32], proj_i: i32) -> i32:
    let kind = source.proj_kinds.get(proj_i as i64)
    let data = source.proj_d0.get(proj_i as i64)
    if kind == ProjKind.PK_INDEX:
        return mir_gen_remap_local(local_map, data)
    data

fn mir_gen_remap_rvalue(source: &MirBody, local_map: &Vec[i32], rv_id: i32, d_index: i32) -> i32:
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

fn lower_generator_constructor(sema: &Sema, ast_pool: AstPool, pool: InternPool, fn_node: i32, sig_idx: i32) -> MirBody:
    let fn_sym = sema.fn_decl_semantic_symbol(fn_node, ast_pool.get_data0(fn_node))
    let state_tid = sema.generator_fn_state_types.get(fn_sym).unwrap()
    var builder = MirBuilder.init(sema, ast_pool, pool, fn_sym)
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
            if builder.local_type_is_str(local_id) != 0:
                builder.set_string_local_flags(local_id, 1)
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
    return move builder.body

fn lower_generator_next_body(sema: &Sema, source: &MirBody, fn_node: i32) -> MirBody:
    let fn_sym = source.fn_sym
    let next_sym = sema.generator_fn_next_syms.get(fn_sym).unwrap()
    let state_tid = sema.generator_fn_state_types.get(fn_sym).unwrap()
    let yield_ty = sema.generator_fn_yield_types.get(fn_sym).unwrap()
    let opt_ty = sema.find_option_type_for(yield_ty)
    var out = MirBody.init(next_sym, sema)
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
        let base_local = mir_gen_remap_local(&local_map, source.place_locals.get(pi as i64))
        let proj_start = source.place_proj_starts.get(pi as i64)
        let proj_count = source.place_proj_counts.get(pi as i64)
        let new_proj_start = out.proj_kinds.len() as i32
        for ppi in 0..proj_count:
            let src_proj = proj_start + ppi
            out.proj_kinds.push(source.proj_kinds.get(src_proj as i64))
            out.proj_d0.push(mir_gen_remap_place_projection_data(source, &local_map, src_proj))
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
        out.call_sig_indices.push(source.call_sig_indices.get(ca as i64))
        out.call_mono_syms.push(source.call_mono_syms.get(ca as i64))
        out.call_contract_required.push(source.call_contract_required.get(ca as i64))
        out.call_pipeline_receiver_places.push(source.call_pipeline_receiver_places.get(ca as i64))
        for ai in 0..count:
            out.call_arg_operands.push(source.call_arg_operands.get((start + ai) as i64))

    for ri in 0..source.rval_kinds.len() as i32:
        out.rval_kinds.push(source.rval_kinds.get(ri as i64))
        out.rval_d0.push(mir_gen_remap_rvalue(source, &local_map, ri, 0))
        out.rval_d1.push(mir_gen_remap_rvalue(source, &local_map, ri, 1))
        out.rval_d2.push(mir_gen_remap_rvalue(source, &local_map, ri, 2))

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
            var sd0: i32 = source.stmt_d0.get(stmt_id as i64)
            let sd1 = source.stmt_d1.get(stmt_id as i64)
            if sk == StmtKind.StorageLive or sk == StmtKind.StorageDead or sk == StmtKind.Drop:
                sd0 = mir_gen_remap_local(&local_map, sd0)
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

fn mir_fn_is_generic_template(sema: &Sema, ast_pool: AstPool, pool: InternPool, fn_node: i32) -> bool:
    mir_fn_is_generic_template_at(sema, ast_pool, pool, fn_node, -1)

fn mir_fn_is_generic_template_at(sema: &Sema, ast_pool: AstPool, pool: InternPool, fn_node: i32, decl_index: i32) -> bool:
    let meta = ast_pool.find_fn_meta(fn_node)
    if meta >= 0 and ast_pool.fn_meta_tp_count(meta) > 0:
        return true
    let fn_sym = sema.fn_decl_semantic_symbol_at(fn_node, ast_pool.get_data0(fn_node), decl_index)
    if sema.fn_node_is_generic_template(fn_node, fn_sym) != 0:
        return true
    if sema.get_sig(fn_sym) >= 0:
        return false
    if sema.generic_fn_node_for_symbol(fn_sym) != 0:
        return true
    let sema_sym = sema.pool_lookup_symbol(pool.resolve_symbol(fn_sym))
    sema_sym != 0 and sema.get_sig(sema_sym) < 0 and sema.generic_fn_node_for_symbol(sema_sym) != 0

type ConcreteSpecializationLowerResult {
    sema: Sema,
    body: MirBody,
}

impl MirModule:
    fn validate_generic_call_contracts(sema: &Sema):
        for bi in 0..self.bodies.len() as i32:
            let body = &self.bodies[bi as i64]
            let call_count = body.call_arg_starts.len() as i32
            if body.call_sig_indices.len() as i32 != call_count or body.call_mono_syms.len() as i32 != call_count or body.call_contract_required.len() as i32 != call_count or body.call_pipeline_receiver_places.len() as i32 != call_count:
                sema_phase_bug(f"BUG: MIR call-contract tables are not parallel in body {body.fn_sym}")
            for ci in 0..call_count:
                if not body.call_requires_contract(ci):
                    continue
                let sig_idx = body.call_sig_index(ci)
                let mono_sym = body.call_mono_sym(ci)
                if sig_idx < 0 or sig_idx >= sema.sig_names.len() as i32 or mono_sym == 0:
                    // Name the call: the bare body/call ids forced an LLDB
                    // session per occurrence across four machinery strata.
                    let vgc_node = if ci < body.call_ast_nodes.len() as i32: body.call_ast_nodes.get(ci as i64) else: 0
                    let vgc_fn_name = sema.pool_resolve(body.fn_sym)
                    sema_phase_bug(f"BUG: user generic call lacks a concrete contract: body={body.fn_sym}({vgc_fn_name}) call={ci} node={vgc_node} sig={sig_idx} mono={mono_sym}")
                if sema.sig_names.get(sig_idx as i64) != mono_sym:
                    sema_phase_bug(f"BUG: generic call signature/symbol mismatch: body={body.fn_sym} call={ci} sig={sig_idx} mono={mono_sym}")
                if not sema.concrete_specialization_by_sym.contains(mono_sym):
                    sema_phase_bug(f"BUG: generic call contract has no registered specialization: body={body.fn_sym} call={ci} mono={mono_sym}")
                if self.find_body(mono_sym) < 0:
                    sema_phase_bug(f"BUG: generic call contract has no prelowered MIR body: body={body.fn_sym} call={ci} mono={mono_sym}")
                let arg_count = body.call_arg_counts.get(ci as i64)
                if sema.sig_get_param_count(sig_idx) != arg_count:
                    sema_phase_bug(f"BUG: generic call argument/signature mismatch: body={body.fn_sym} call={ci} args={arg_count} params={sema.sig_get_param_count(sig_idx)}")
        for tid in 1..sema.type_kinds.len() as i32:
            if not sema.concrete_drop_sigs.contains(tid):
                continue
            if not sema.concrete_drop_mono_syms.contains(tid):
                sema_phase_bug(f"BUG: concrete generic Drop contract lacks a mono symbol: type={tid}")
            let sig_idx = sema.concrete_drop_sigs.get(tid).unwrap()
            let mono_sym = sema.concrete_drop_mono_syms.get(tid).unwrap()
            if sig_idx < 0 or sig_idx >= sema.sig_names.len() as i32 or sema.sig_names.get(sig_idx as i64) != mono_sym:
                sema_phase_bug(f"BUG: concrete generic Drop signature/symbol mismatch: type={tid} sig={sig_idx} mono={mono_sym}")
            if sema.sig_get_param_count(sig_idx) != 1 or sema.sig_receiver_mode(sig_idx) != ReceiverMode.Move:
                sema_phase_bug(f"BUG: concrete generic Drop contract is not exactly one move receiver: type={tid} sig={sig_idx}")
            if sema.sig_return_type(sig_idx) != sema.ty_void as i32:
                sema_phase_bug(f"BUG: concrete generic Drop contract does not return Unit: type={tid} sig={sig_idx}")
            if self.find_body(mono_sym) < 0:
                sema_phase_bug(f"BUG: concrete generic Drop contract has no prelowered MIR body: type={tid} mono={mono_sym}")

pub type MirLowerResult {
    sema: Sema,
    mir_module: MirModule,
}

fn lower_concrete_specialization(sema: Sema, ast_pool: AstPool, pool: InternPool, specialization: i32) -> ConcreteSpecializationLowerResult:
    let fn_node: i32 = sema.concrete_specialization_nodes.get(specialization as i64)
    let mono_sym: i32 = sema.concrete_specialization_syms.get(specialization as i64)
    let subst_start: i32 = sema.concrete_specialization_subst_starts.get(specialization as i64)
    let subst_count: i32 = sema.concrete_specialization_subst_counts.get(specialization as i64)
    let param_start: i32 = sema.concrete_specialization_param_starts.get(specialization as i64)
    let param_count: i32 = sema.concrete_specialization_param_counts.get(specialization as i64)
    let subst_syms: Vec[i32] = Vec.new()
    let subst_types: Vec[i32] = Vec.new()
    let concrete_params: Vec[i32] = Vec.new()
    for i in 0..subst_count:
        subst_syms.push(sema.concrete_specialization_subst_syms.get((subst_start + i) as i64))
        subst_types.push(sema.concrete_specialization_subst_types.get((subst_start + i) as i64))
    for i in 0..param_count:
        concrete_params.push(sema.concrete_specialization_param_types.get((param_start + i) as i64))

    // Rechecking here restores specialization-specific AST sidecars immediately
    // before MIR lowering. This is still the mutable semantic phase; codegen
    // never re-enters Sema. If rechecking discovers a dependent type, refresh
    // the eager query tables before the read-only MirBuilder sees it.
    let type_count_before = sema.type_kinds.len() as i32
    let sig_idx = sema.check_fn_body_concrete(fn_node, subst_syms, subst_types, mono_sym, concrete_params)
    if sema.type_kinds.len() as i32 != type_count_before:
        sema.preregister_mir_types()

    let saved_subst_syms = sema_clone_i32_vec(&sema.generic_subst_param_syms)
    let saved_subst_types = sema_clone_i32_vec(&sema.generic_subst_type_ids)
    let saved_named: Vec[i32] = Vec.new()
    let saved_named_had: Vec[i32] = Vec.new()
    sema.generic_subst_param_syms = Vec.new()
    sema.generic_subst_type_ids = Vec.new()
    for i in 0..subst_count:
        let sym = subst_syms.get(i as i64)
        let tid = subst_types.get(i as i64)
        if sema.named_types.contains(sym):
            saved_named_had.push(1)
            saved_named.push(sema.named_types.get(sym).unwrap())
        else:
            saved_named_had.push(0)
            saved_named.push(0)
        sema.named_types.insert(sym, tid)
        sema.put_generic_subst(sym, tid, fn_node)

    let saved_file_id = sema.local_file_id
    let saved_module_path = sema_owned_text(sema.current_module_path)
    let saved_module_has_ci = sema.current_module_has_ci
    let decl_index = sema.find_decl_index(fn_node)
    if decl_index >= 0:
        sema.update_decl_source_context(decl_index)
    var builder = MirBuilder.init(&sema, ast_pool, pool, mono_sym)
    let body = lower_fn_with_sig(move builder, fn_node, sig_idx)
    sema.local_file_id = saved_file_id
    sema.current_module_path = saved_module_path
    sema.current_module_has_ci = saved_module_has_ci

    for i in 0..subst_count:
        let sym = subst_syms.get(i as i64)
        if saved_named_had.get(i as i64) != 0:
            sema.named_types.insert(sym, saved_named.get(i as i64))
        else:
            sema.named_types.remove(sym)
    sema.generic_subst_param_syms = saved_subst_syms
    sema.generic_subst_type_ids = saved_subst_types
    ConcreteSpecializationLowerResult { sema, body }

fn lower_module(input_sema: Sema, ast_pool: AstPool, pool: InternPool) -> MirLowerResult:
    var sema = input_sema
    sema.prepare_source_line_offsets()
    var mir_mod = MirModule.init()

    for di in 0..ast_pool.decl_count():
        let decl = ast_pool.get_decl(di)
        if ast_pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        // D39: an interface declaration has no body to lower; the bundle's
        // object defines it.
        if ast_pool.fn_decl_body_is_interface(decl):
            continue

        let fn_sym = sema.fn_decl_semantic_symbol_at(decl as i32, ast_pool.get_data0(decl), di)
        let mir_fn_sym = mir_symbol_for_pool(&sema, pool, fn_sym)
        if mir_fn_is_generic_template_at(&sema, ast_pool, pool, decl as i32, di):
            continue

        sema.update_decl_source_context(di)
        let fn_flags = ast_pool.get_data2(decl)
        if (fn_flags / FnFlags.GEN) % 2 == 1:
            let sig_idx = sema.get_sig(fn_sym)
            if sig_idx < 0:
                continue
            var source_builder = MirBuilder.init(&sema, ast_pool, pool, mir_fn_sym)
            source_builder.in_generator = 1
            let source_body = lower_fn_with_sig(move source_builder, decl as i32, sig_idx)
            let ctor_body = lower_generator_constructor(sema, ast_pool, pool, decl as i32, sig_idx)
            let next_body = lower_generator_next_body(sema, source_body, decl as i32)
            mir_mod.add_body(move ctor_body)
            mir_mod.add_body(move next_body)
            continue
        let sig_idx = sema.get_sig(fn_sym)
        var builder = MirBuilder.init(&sema, ast_pool, pool, mir_fn_sym)
        // fn_sym is the declaration's authoritative Sema-pool identity.
        // mir_fn_sym belongs to the output pool; treating its numeric ID as a
        // Sema symbol can select an unrelated but valid signature in large
        // combined modules and corrupt every parameter type during lowering.
        let body = lower_fn_with_sig(move builder, decl as i32, sig_idx)
        mir_mod.add_body(move body)

    for gi in 0..sema.fn_clause_group_count():
        let dispatch_sym = sema.fn_clause_group_name(gi)
        if sema.generic_fn_node_for_symbol(dispatch_sym) != 0:
            continue
        mir_mod.add_body(lower_fn_clause_dispatcher(&sema, ast_pool, pool, gi))

    // Lower the dynamic specialization queue to a fixpoint. Rechecking a body
    // can discover nested calls, and preregistration can expose concrete
    // generic Drop implementations that have no source call node of their own.
    var specialization = 0
    var specializations_stable = false
    while not specializations_stable:
        while specialization < sema.concrete_specialization_nodes.len() as i32:
            let mono_sym: i32 = sema.concrete_specialization_syms.get(specialization as i64)
            if mir_mod.find_body(mono_sym) < 0:
                var lowered = lower_concrete_specialization(move sema, ast_pool, pool, specialization)
                sema = move lowered.sema
                mir_mod.add_body(move lowered.body)
            specialization = specialization + 1
        sema.preregister_mir_types()
        let before_drop_registration = sema.concrete_specialization_nodes.len() as i32
        sema.register_generic_drop_specializations()
        specializations_stable = sema.concrete_specialization_nodes.len() as i32 == before_drop_registration

    mir_mod.validate_generic_call_contracts(&sema)

    // Snapshot only after every specialization has been checked and lowered;
    // no semantic type may appear later in codegen.
    mir_mod.snapshot_sema_types(&sema)

    MirLowerResult { sema, mir_module: mir_mod }

fn collect_tailrec_fn_syms(sema: &Sema, ast_pool: AstPool, pool: InternPool) -> Vec[i32]:
    let tailrec_syms: Vec[i32] = Vec.new()
    for di in 0..ast_pool.decl_count():
        let decl = ast_pool.get_decl(di)
        if ast_pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        if mir_fn_is_generic_template(sema, ast_pool, pool, decl as i32):
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

fn mir_tailrec_sig_compatible(sema: &Sema, ast_pool: AstPool, fn_a: i32, fn_b: i32) -> i32:
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

type TailrecDropState {
    count: i32,
    first_sym: i32,
}
impl Copy for TailrecDropState

fn tailrec_no_violation -> TailrecViolation:
    TailrecViolation { node: 0, message: "" }

fn tailrec_no_drop_state -> TailrecDropState:
    TailrecDropState { count: 0, first_sym: 0 }

fn tailrec_drop_state_add(state: TailrecDropState, sym: i32) -> TailrecDropState:
    if sym == 0:
        return state
    if state.count == 0:
        return TailrecDropState { count: 1, first_sym: sym }
    TailrecDropState { count: state.count + 1, first_sym: state.first_sym }

fn tailrec_drop_state_remove(state: TailrecDropState, sym: i32) -> TailrecDropState:
    if state.count == 0 or sym == 0:
        return state
    if state.count == 1:
        if state.first_sym == sym:
            return tailrec_no_drop_state()
        return state
    if state.first_sym == sym:
        return TailrecDropState { count: state.count - 1, first_sym: 0 }
    state

fn tailrec_drop_state_message(sema: &Sema, state: TailrecDropState) -> str:
    if state.first_sym != 0:
        return "recursive call is not in tail position (Drop local '" ++ sema.pool_resolve(state.first_sym) ++ "' is live across the call)"
    "recursive call is not in tail position (a Drop local is live across the call)"

fn tailrec_drop_binding_sym(sema: &Sema, node: i32) -> i32:
    let kind = sema.ast.kind(node)
    if kind != NodeKind.NK_LET_BINDING and kind != NodeKind.NK_LET_DECL:
        return 0
    let bind_sym = sema.ast.get_data0(node)
    if bind_sym == 0 or sema.pool_resolve(bind_sym) == "_":
        return 0
    var bind_ty = 0
    if sema.typed_binding_types.contains(node):
        bind_ty = sema.typed_binding_types.get(node).unwrap()
    if bind_ty == 0:
        return 0
    if sema.is_copy_frozen(bind_ty as TypeId) != 0:
        return 0
    let owner_sym = sema.method_owner_symbol_for_type(sema.resolve_alias(bind_ty as TypeId) as i32)
    if owner_sym != 0 and sema.has_drop_method(owner_sym) != 0:
        return bind_sym
    0

fn tailrec_consumed_ident_sym(sema: &Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = sema.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        return sema.ast.get_data0(node)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_MOVE_ARG or kind == NodeKind.NK_NO_SUSPEND:
        return tailrec_consumed_ident_sym(sema, sema.ast.get_data0(node))
    0

fn tailrec_call_consumes_active_drop(sema: &Sema, node: i32, callee_sym: i32, state: TailrecDropState) -> bool:
    if state.count != 1 or state.first_sym == 0:
        return false
    let sig_idx = sema.get_sig(callee_sym)
    if sig_idx < 0:
        return false
    let has_resolved = sema.has_resolved_call_args(node)
    let arg_count = if has_resolved != 0: sema.get_resolved_call_arg_count(node) else: sema.ast.get_data2(node)
    let extra_start = sema.ast.get_data1(node)
    for ai in 0..arg_count:
        let arg = if has_resolved != 0: sema.get_resolved_call_arg(node, ai) else: sema.ast.get_extra(extra_start + ai)
        if tailrec_consumed_ident_sym(sema, arg) != state.first_sym:
            continue
        let param_ty = sema.sig_param_type(sig_idx, ai)
        if param_ty != 0 and sema.is_copy_frozen(param_ty as TypeId) == 0:
            return true
    false

fn tailrec_stmt_ends_drop_sym(sema: &Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = sema.ast.kind(node)
    if kind == NodeKind.NK_CALL:
        let callee = sema.ast.get_data0(node)
        if sema.ast.kind(callee) == NodeKind.NK_IDENT:
            let callee_sym = sema.ast.get_data0(callee)
            if sema.fn_symbol_is_std_builtins_drop(callee_sym) != 0 and sema.ast.get_data2(node) == 1:
                let has_resolved = sema.has_resolved_call_args(node)
                let arg = if has_resolved != 0: sema.get_resolved_call_arg(node, 0) else: sema.ast.get_extra(sema.ast.get_data1(node))
                return tailrec_consumed_ident_sym(sema, arg)
    if kind == NodeKind.NK_LET_BINDING:
        let bind_sym = sema.ast.get_data0(node)
        if bind_sym != 0 and sema.pool_resolve(bind_sym) == "_":
            return tailrec_consumed_ident_sym(sema, sema.ast.get_data1(node))
    0

fn tailrec_verify_recursive_edges(sema: &Sema, node: i32, scc: &Vec[i32], in_tail: i32, active_cleanup: i32, active_drop: TailrecDropState) -> TailrecViolation:
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
                else if active_drop.count != 0 and not tailrec_call_consumes_active_drop(sema, node, callee_sym, active_drop):
                    return TailrecViolation { node, message: tailrec_drop_state_message(sema, active_drop) }
        let callee_violation = tailrec_verify_recursive_edges(sema, callee, scc, 0, active_cleanup, active_drop)
        if callee_violation.node != 0:
            return callee_violation
        let extra_start = sema.ast.get_data1(node)
        let arg_count = sema.ast.get_data2(node)
        for ai in 0..arg_count:
            let arg_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_extra(extra_start + ai), scc, 0, active_cleanup, active_drop)
            if arg_violation.node != 0:
                return arg_violation
        return tailrec_no_violation()
    if kind == NodeKind.NK_BLOCK:
        let extra_start = sema.ast.get_data0(node)
        let stmt_count = sema.ast.get_data1(node)
        let tail = sema.ast.get_data2(node)
        var cleanup_depth = active_cleanup
        var drop_state = active_drop
        for si in 0..stmt_count:
            let stmt = sema.ast.get_extra(extra_start + si)
            let stmt_kind = sema.ast.kind(stmt)
            if stmt_kind == NodeKind.NK_DEFER or stmt_kind == NodeKind.NK_ERRDEFER:
                let defer_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data0(stmt), scc, 0, cleanup_depth, drop_state)
                if defer_violation.node != 0:
                    return defer_violation
                cleanup_depth = cleanup_depth + 1
            else:
                let stmt_violation = tailrec_verify_recursive_edges(sema, stmt, scc, 0, cleanup_depth, drop_state)
                if stmt_violation.node != 0:
                    return stmt_violation
                drop_state = tailrec_drop_state_remove(drop_state, tailrec_stmt_ends_drop_sym(sema, stmt))
                drop_state = tailrec_drop_state_add(drop_state, tailrec_drop_binding_sym(sema, stmt))
        return tailrec_verify_recursive_edges(sema, tail, scc, in_tail, cleanup_depth, drop_state)
    if kind == NodeKind.NK_IF_EXPR:
        let cond_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup, active_drop)
        if cond_violation.node != 0:
            return cond_violation
        let then_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, in_tail, active_cleanup, active_drop)
        if then_violation.node != 0:
            return then_violation
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data2(node), scc, in_tail, active_cleanup, active_drop)
    if kind == NodeKind.NK_MATCH:
        let subject_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup, active_drop)
        if subject_violation.node != 0:
            return subject_violation
        let arm_start = sema.ast.get_data1(node)
        let arm_count = sema.ast.get_data2(node)
        for ai in 0..arm_count:
            let arm = sema.ast.get_extra(arm_start + ai)
            let guard_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data2(arm), scc, 0, active_cleanup, active_drop)
            if guard_violation.node != 0:
                return guard_violation
            let body_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data1(arm), scc, in_tail, active_cleanup, active_drop)
            if body_violation.node != 0:
                return body_violation
        return tailrec_no_violation()
    if kind == NodeKind.NK_RETURN:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 1, active_cleanup, active_drop)
    if kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup, active_drop)
    if kind == NodeKind.NK_DO_WHILE:
        let body_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup, active_drop)
        if body_violation.node != 0:
            return body_violation
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, 0, active_cleanup, active_drop)
    // #530: the body field differs per loop kind — NK_FOR body is d2, but
    // NK_WHILE body is d1 (d2=label) and NK_LOOP body is d0. Reading d2 for
    // all three meant while/loop bodies were never traversed, so a bare
    // recursive call inside a while/loop escaped the @[tailrec] verifier.
    if kind == NodeKind.NK_WHILE:
        let cond_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup, active_drop)
        if cond_violation.node != 0:
            return cond_violation
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, 0, active_cleanup, active_drop)
    if kind == NodeKind.NK_LOOP:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, 0, active_cleanup, active_drop)
    if kind == NodeKind.NK_FOR:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data2(node), scc, 0, active_cleanup, active_drop)
    if kind == NodeKind.NK_LET_DECL or kind == NodeKind.NK_LET_BINDING:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, 0, active_cleanup, active_drop)
    if kind == NodeKind.NK_BINARY:
        let lhs_violation = tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, 0, active_cleanup, active_drop)
        if lhs_violation.node != 0:
            return lhs_violation
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data2(node), scc, 0, active_cleanup, active_drop)
    if kind == NodeKind.NK_UNARY or kind == NodeKind.NK_ASSIGN:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data1(node), scc, 0, active_cleanup, active_drop)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_MOVE_ARG or kind == NodeKind.NK_COPY_ARG or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_UNSAFE_BLOCK or kind == NodeKind.NK_NO_SUSPEND:
        return tailrec_verify_recursive_edges(sema, sema.ast.get_data0(node), scc, in_tail, active_cleanup, active_drop)
    tailrec_no_violation()

impl MirModule:
    fn body_reaches(start_idx: i32, target_idx: i32) -> bool:
        if start_idx == target_idx:
            return true
        let body_count = self.body_count()
        var visited: Vec[i32] = Vec.new()
        for _ in 0..body_count:
            visited.push(0)
        var stack: Vec[i32] = Vec.new()
        stack.push(start_idx)
        while stack.len() > 0:
            let idx = stack.remove(stack.len() - 1)
            if idx < 0 or idx >= body_count:
                continue
            if visited.get(idx as i64) != 0:
                continue
            visited.set_i32(idx as i64, 1)
            let body = &self.bodies[idx as i64]
            for bb in 0..body.block_count():
                if body.term_kind(bb) != TermKind.TK_CALL:
                    continue
                let callee_sym = mir_body_extract_callee_sym(body, body.term_data0(bb))
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

    fn collect_tailrec_scc(start_idx: i32) -> Vec[i32]:
        var members: Vec[i32] = Vec.new()
        let body_count = self.body_count()
        for idx in 0..body_count:
            if self.body_reaches(start_idx, idx) and self.body_reaches(idx, start_idx):
                members.push(idx)
        members

    mut fn mark_tailrec_scc_edges(scc: &Vec[i32]):
        for si in 0..scc.len() as i32:
            let src_idx = scc.get(si as i64)
            // View: a bare element read copies the MirBody's Drop-bearing
            // tables and aliases the module's own (#715 class).
            let body = &self.bodies[src_idx as i64]
            let bb_count = body.block_count()
            let tail_bbs: Vec[i32] = Vec.new()
            for bb in 0..bb_count:
                if body.term_kind(bb) != TermKind.TK_CALL:
                    continue
                let callee_sym = mir_body_extract_callee_sym(body, body.term_data0(bb))
                if callee_sym == 0:
                    continue
                for ti in 0..scc.len() as i32:
                    let dst_idx = scc.get(ti as i64)
                    let dst_body = &self.bodies[dst_idx as i64]
                    if dst_body.fn_sym == callee_sym and mir_is_tail_call_to(body, bb, callee_sym):
                        // Keep the shared body view live only while inspecting
                        // the SCC; mutate the owning body after that view ends.
                        if not mir_vec_contains_i32(&body.mutual_tail_bbs, bb):
                            tail_bbs.push(bb)
                        break
            for ti in 0..tail_bbs.len() as i32:
                let tail_bb: i32 = tail_bbs.get(ti as i64)
                // The direct place is load-bearing: copying the Vec handle
                // would update a temporary and leave the owning body unchanged.
                self.bodies[src_idx as i64].mutual_tail_bbs.push(tail_bb)

    fn tailrec_scc_syms(scc: &Vec[i32]) -> Vec[i32]:
        var syms: Vec[i32] = Vec.new()
        for si in 0..scc.len() as i32:
            let body_idx = scc.get(si as i64)
            if body_idx < 0 or body_idx >= self.body_count():
                continue
            syms.push(self.bodies.get(body_idx as i64).fn_sym)
        syms

    mut fn verify_tailrec_contracts(sema: &Sema, ast_pool: AstPool, tailrec_syms: &Vec[i32]) -> Vec[TailrecViolation]:
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
                let recursive_violation = tailrec_verify_recursive_edges(sema, ast_pool.get_data1(decl_node), &scc_syms, 1, 0, tailrec_no_drop_state())
                if recursive_violation.node != 0:
                    violations.push(move recursive_violation)
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
                    let recursive_violation = tailrec_verify_recursive_edges(sema, ast_pool.get_data1(member_decl), &scc_syms, 1, 0, tailrec_no_drop_state())
                    if recursive_violation.node != 0:
                        violations.push(move recursive_violation)
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
                let src_body = &self.bodies[src_idx as i64]
                for ti2 in 0..scc_syms.len() as i32:
                    let dst_sym = scc_syms.get(ti2 as i64)
                    if mir_body_has_non_tail_call_to(src_body, dst_sym):
                        bad_edge = 1
                        break
                if bad_edge != 0:
                    break
            if bad_edge != 0:
                violations.push(TailrecViolation { node: decl_node, message: "mutual tail-recursive cycle cannot be guaranteed stack-constant: recursive edge is not in guaranteed tail position" })
                continue

            self.mark_tailrec_scc_edges(&scc)
        violations
