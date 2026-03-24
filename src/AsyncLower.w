// AsyncLower — Wave 9 MIR -> Async-MIR lowering.
//
// This pass runs after MIR construction and records explicit suspend-aware
// state-machine boundaries for async/generator constructs.

use Ast
use InternPool
use Mir
use Sema
use AsyncMir
use Diagnostic
use Span

type AsyncSnapshot {
    live_locals: i32,
    storage_dead: i32,
    drop_count: i32,
    resume_bb: i32,
}

type AsyncLowerResult {
    out_mod: AsyncMirModule,
    diags: DiagnosticList,
}

type AsyncLower {
    mir_mod: MirModule,
    ast: AstPool,
    pool: InternPool,
    sema: Sema,
    diags: DiagnosticList,
    out_mod: AsyncMirModule,
    cur_mir_body: MirBody,
    cur_body: AsyncMirBody,
}

fn async_ast_get_data0(ast: AstPool, node: i32) -> i32:
    ast.get_data0(node)

fn async_ast_get_data1(ast: AstPool, node: i32) -> i32:
    ast.get_data1(node)

fn async_ast_get_data2(ast: AstPool, node: i32) -> i32:
    ast.get_data2(node)

fn async_ast_get_end(ast: AstPool, node: i32) -> i32:
    ast.get_end(node)

fn async_ast_get_start(ast: AstPool, node: i32) -> i32:
    ast.get_start(node)

fn async_ast_kind(ast: AstPool, node: i32) -> i32:
    ast.kind(node)

fn async_body_add_suspend(body: &mut AsyncMirBody, suspend_kind: i32, span_start: i32, span_end: i32, resume_bb: i32, live_locals: i32, storage_dead: i32, drop_count: i32):
    body.add_suspend(suspend_kind, span_start, span_end, resume_bb, live_locals, storage_dead, drop_count)

fn async_body_finalize_states(body: &mut AsyncMirBody):
    body.finalize_states()

fn async_body_suspend_count(body: AsyncMirBody) -> i32:
    body.suspend_count()

fn async_diags_emit(diags: &mut DiagnosticList, diag: Diagnostic):
    diags.emit(diag)

fn async_mod_add_body(out_mod: &mut AsyncMirModule, body: AsyncMirBody):
    out_mod.add_body(body)

fn lower_async_module(mir_mod: MirModule, ast: AstPool, pool: InternPool, sema: Sema, diags: DiagnosticList) -> AsyncLowerResult:
    var lower = AsyncLower {
        mir_mod,
        ast,
        pool,
        sema,
        diags,
        out_mod: AsyncMirModule.init(),
        cur_mir_body: MirBody.init_for_fn(0),
        cur_body: AsyncMirBody.init(0, AM_BODY_SYNC),
    }
    lower.run()
    AsyncLowerResult {
        out_mod: lower.out_mod,
        diags: lower.diags,
    }

fn AsyncLower.run(self: AsyncLower):
    for bi in 0..self.mir_mod.bodies.len() as i32:
        let mir_body: MirBody = self.mir_mod.bodies.get(bi as i64)
        self.lower_body(mir_body)

fn AsyncLower.lower_body(self: AsyncLower, mir_body: MirBody):
    let fn_decl = async_find_fn_decl(self.ast, mir_body.fn_sym)
    let flavor = async_fn_flavor(self.ast, fn_decl)
    self.cur_mir_body = mir_body
    self.cur_body = AsyncMirBody.init(mir_body.fn_sym, flavor)

    if fn_decl != 0:
        let fn_body_node = async_ast_get_data1(self.ast, fn_decl)
        self.walk_expr(fn_body_node)

    if flavor != AM_BODY_GENERATOR:
        for si in 0..async_body_suspend_count(self.cur_body):
            if self.cur_body.suspend_kinds.get(si as i64) == AM_SUSPEND_YIELD:
                self.emit_error_at_span("yield used outside generator function", self.cur_body.suspend_span_starts.get(si as i64), self.cur_body.suspend_span_ends.get(si as i64))
                break

    let cur_body = &mut self.cur_body
    async_body_finalize_states(cur_body)
    let out_mod = &mut self.out_mod
    async_mod_add_body(out_mod, self.cur_body)

fn AsyncLower.emit_error_at_span(self: AsyncLower, message: str, start: i32, end: i32):
    let span = Span {
        file: 0,
        start,
        end,
    }
    let diags = &mut self.diags
    async_diags_emit(diags, Diagnostic.err(message, span))

fn AsyncLower.record_suspend(self: AsyncLower, node: i32, suspend_kind: i32):
    let span_start = async_ast_get_start(self.ast, node)
    let span_end = async_ast_get_end(self.ast, node)
    let snap = async_snapshot_for_span(self.cur_mir_body, span_start)
    let cur_body = &mut self.cur_body
    async_body_add_suspend(cur_body, suspend_kind, span_start, span_end, snap.resume_bb, snap.live_locals, snap.storage_dead, snap.drop_count)

fn AsyncLower.walk_expr(self: AsyncLower, node: i32):
    if not async_node_valid(self.ast, node):
        return

    let kind = async_ast_kind(self.ast, node)

    if kind == NK_AWAIT:
        self.record_suspend(node, AM_SUSPEND_AWAIT)
        self.walk_expr(async_ast_get_data0(self.ast, node))
        return

    if kind == NK_SELECT_AWAIT:
        self.record_suspend(node, AM_SUSPEND_SELECT_AWAIT)
        let arm_start = async_ast_get_data0(self.ast, node)
        let arm_count = async_ast_get_data1(self.ast, node)
        for ai in 0..arm_count:
            let task_expr = async_extra_or_zero(self.ast, arm_start + ai * 3 + 1)
            let arm_body = async_extra_or_zero(self.ast, arm_start + ai * 3 + 2)
            self.walk_expr(task_expr)
            self.walk_expr(arm_body)
        return

    if kind == NK_YIELD:
        self.record_suspend(node, AM_SUSPEND_YIELD)
        self.walk_expr(async_ast_get_data0(self.ast, node))
        return

    if kind == NK_IDENT or kind == NK_INT_LIT or kind == NK_FLOAT_LIT or kind == NK_STRING_LIT or kind == NK_BOOL_LIT or kind == NK_C_STRING_LIT:
        return

    if kind == NK_GROUPED or kind == NK_RETURN or kind == NK_DEFER or kind == NK_ERRDEFER or kind == NK_SPAWN or kind == NK_COMPTIME:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        return

    if kind == NK_UNARY:
        self.walk_expr(async_ast_get_data1(self.ast, node))
        return

    if kind == NK_BINARY:
        self.walk_expr(async_ast_get_data1(self.ast, node))
        self.walk_expr(async_ast_get_data2(self.ast, node))
        return

    if kind == NK_ASSIGN or kind == NK_PIPELINE or kind == NK_RANGE or kind == NK_INDEX:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        self.walk_expr(async_ast_get_data1(self.ast, node))
        return

    if kind == NK_CALL:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        let arg_start = async_ast_get_data1(self.ast, node)
        let arg_count = async_ast_get_data2(self.ast, node)
        for ai in 0..arg_count:
            self.walk_expr(async_extra_or_zero(self.ast, arg_start + ai))
        return

    if kind == NK_FIELD_ACCESS:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        return

    if kind == NK_SLICE:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        self.walk_expr(async_ast_get_data1(self.ast, node))
        self.walk_expr(async_ast_get_data2(self.ast, node))
        return

    if kind == NK_CAST:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        return

    if kind == NK_IF_EXPR:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        self.walk_expr(async_ast_get_data1(self.ast, node))
        self.walk_expr(async_ast_get_data2(self.ast, node))
        return

    if kind == NK_BLOCK:
        let stmt_start = async_ast_get_data0(self.ast, node)
        let stmt_count = async_ast_get_data1(self.ast, node)
        for si in 0..stmt_count:
            self.walk_expr(async_extra_or_zero(self.ast, stmt_start + si))
        self.walk_expr(async_ast_get_data2(self.ast, node))
        return

    if kind == NK_LET_BINDING:
        self.walk_expr(async_ast_get_data1(self.ast, node))
        return

    if kind == NK_LET_ELSE:
        self.walk_expr(async_ast_get_data1(self.ast, node))
        self.walk_expr(async_ast_get_data2(self.ast, node))
        return

    if kind == NK_TUPLE_DESTRUCTURE:
        self.walk_expr(async_ast_get_data2(self.ast, node))
        return

    if kind == NK_WHILE:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        self.walk_expr(async_ast_get_data1(self.ast, node))
        return

    if kind == NK_LOOP:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        return

    if kind == NK_FOR:
        self.walk_expr(async_ast_get_data1(self.ast, node))
        self.walk_expr(async_ast_get_data2(self.ast, node))
        return

    if kind == NK_MATCH:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        let arm_start = async_ast_get_data1(self.ast, node)
        let arm_count = async_ast_get_data2(self.ast, node)
        for ai in 0..arm_count:
            self.walk_expr(async_extra_or_zero(self.ast, arm_start + ai))
        return

    if kind == NK_MATCH_ARM:
        self.walk_expr(async_ast_get_data2(self.ast, node))
        self.walk_expr(async_ast_get_data1(self.ast, node))
        return

    if kind == NK_TUPLE or kind == NK_ARRAY_LIT:
        let start = async_ast_get_data0(self.ast, node)
        let count = async_ast_get_data1(self.ast, node)
        for i in 0..count:
            self.walk_expr(async_extra_or_zero(self.ast, start + i))
        return

    if kind == NK_ARRAY_COMPREHENSION:
        self.walk_expr(async_ast_get_data2(self.ast, node))
        self.walk_expr(async_ast_get_data0(self.ast, node))
        return

    if kind == NK_STRUCT_LIT:
        // d0 is a symbol, not a node — don't walk it
        let field_start = async_ast_get_data1(self.ast, node)
        let field_count = async_ast_get_data2(self.ast, node)
        for fi in 0..field_count:
            let val = async_extra_or_zero(self.ast, field_start + fi * 2 + 1)
            self.walk_expr(val)
        return

    if kind == NK_RECORD_UPDATE:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        let field_start = async_ast_get_data1(self.ast, node)
        let field_count = async_ast_get_data2(self.ast, node)
        for fi in 0..field_count:
            let val = async_extra_or_zero(self.ast, field_start + fi * 2 + 1)
            self.walk_expr(val)
        return

    if kind == NK_CLOSURE or kind == NK_ASYNC_BLOCK:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        return

    if kind == NK_OPTIONAL_CHAIN:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        let extra_start = async_ast_get_data2(self.ast, node)
        let arg_count = async_extra_or_zero(self.ast, extra_start)
        for ai in 0..arg_count:
            self.walk_expr(async_extra_or_zero(self.ast, extra_start + 1 + ai))
        return

    if kind == NK_VARIANT_SHORTHAND:
        let start = async_ast_get_data1(self.ast, node)
        let count = async_ast_get_data2(self.ast, node)
        for i in 0..count:
            self.walk_expr(async_extra_or_zero(self.ast, start + i))
        return

    if kind == NK_ENUM_VARIANT:
        let extra_start = async_ast_get_data2(self.ast, node)
        let count = async_extra_or_zero(self.ast, extra_start)
        for i in 0..count:
            self.walk_expr(async_extra_or_zero(self.ast, extra_start + 1 + i))
        return

    if kind == NK_WITH_EXPR:
        self.walk_expr(async_ast_get_data0(self.ast, node))
        self.walk_expr(async_ast_get_data1(self.ast, node))
        return

    if kind == NK_ASYNC_SCOPE:
        self.walk_expr(async_ast_get_data1(self.ast, node))
        return

fn async_node_valid(ast: AstPool, node: i32) -> bool:
    node > 0 and node < ast.node_count()

fn async_extra_or_zero(ast: AstPool, idx: i32) -> i32:
    if idx < 0 or idx >= ast.extra_len():
        return 0
    ast.get_extra(idx)

fn async_find_fn_decl(ast: AstPool, fn_sym: i32) -> i32:
    for di in 0..ast.decl_count():
        let decl = ast.get_decl(di)
        if ast.kind(decl) == NK_FN_DECL and ast.get_data0(decl) == fn_sym:
            return decl
    0

fn async_fn_flavor(ast: AstPool, fn_decl: i32) -> i32:
    if fn_decl == 0:
        return AM_BODY_SYNC
    let flags = ast.get_data2(fn_decl)
    if (flags / FN_FLAG_GEN) % 2 == 1:
        return AM_BODY_GENERATOR
    if (flags / FN_FLAG_ASYNC) % 2 == 1:
        return AM_BODY_ASYNC
    AM_BODY_SYNC

fn async_snapshot_for_span(body: MirBody, span_start: i32) -> AsyncSnapshot:
    var storage_live = 0
    var storage_dead = 0
    var drop_count = 0

    for bb in 0..body.bb_stmt_starts.len() as i32:
        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let stmt_count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            let stmt_span = body.stmt_spans.get(stmt_id as i64)
            if stmt_span > span_start:
                continue
            let kind = body.stmt_kind(stmt_id)
            if kind == StmtKind.SK_STORAGE_LIVE:
                storage_live = storage_live + 1
                continue
            if kind == StmtKind.SK_STORAGE_DEAD:
                storage_dead = storage_dead + 1
                continue
            if kind == StmtKind.SK_DROP:
                drop_count = drop_count + 1

    var live_locals = storage_live - storage_dead
    if live_locals < 0:
        live_locals = 0

    AsyncSnapshot {
        live_locals,
        storage_dead,
        drop_count,
        resume_bb: async_resume_bb_for_span(body, span_start),
    }

fn async_resume_bb_for_span(body: MirBody, span_start: i32) -> i32:
    for bb in 0..body.bb_stmt_starts.len() as i32:
        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let stmt_count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            if body.stmt_spans.get(stmt_id as i64) == span_start:
                return bb
    0 - 1
