// MirBuild — AST to MIR lowering for the With compiler.
//
// Transforms a typed AST into a control flow graph of basic blocks.
// All syntax sugar is desugared, all drops are explicit, and
// all control flow is represented as branches between blocks.
//
// Ref: .reference/rust/compiler/rustc_mir_build/src/build/

use Ast
use Type
use Mir

// ── MIR Scope (for tracking defers and drop order) ──────────────────

type MirScope = {
    locals: Vec[i32],
    defers: Vec[i32],
    parent_idx: i32,
}

fn MirScope.new(parent_idx: i32) -> MirScope:
    MirScope {
        locals: Vec.new(),
        defers: Vec.new(),
        parent_idx: parent_idx,
    }

// ── MIR Builder ──────────────────────────────────────────────────────

type MirBuilder = {
    body: MirBody,
    current_bb: i32,
    scopes: Vec[MirScope],
    current_scope_idx: i32,
    pool: AstPool,
    types: TypeTable,
    source: str,
    // Break/continue targets
    break_bb: i32,
    continue_bb: i32,
}

fn MirBuilder.new(pool: AstPool, types: TypeTable, source: str) -> MirBuilder:
    var b = MirBuilder {
        body: MirBody.new(),
        current_bb: -1,
        scopes: Vec.new(),
        current_scope_idx: -1,
        pool: pool,
        types: types,
        source: source,
        break_bb: -1,
        continue_bb: -1,
    }
    b

// ── Scope management ─────────────────────────────────────────────────

fn MirBuilder.push_scope(self: MirBuilder) -> void:
    let sc = MirScope.new(self.current_scope_idx)
    self.scopes.push(sc)
    self.current_scope_idx = (self.scopes.len() as i32) - 1

fn MirBuilder.pop_scope(self: MirBuilder) -> void:
    if self.current_scope_idx >= 0:
        // Emit drops for locals in reverse order
        let sc = self.scopes.get(self.current_scope_idx as i64)
        let lc = sc.locals.len() as i32
        var i = lc - 1
        while i >= 0:
            let local = sc.locals.get(i as i64)
            let decl = MirBody.get_local(self.body, local)
            if not TypeTable.is_copy(self.types, decl.type_id):
                MirBody.add_drop(self.body, self.current_bb, local)
            i = i - 1
        // Emit defers in LIFO order
        let dc = sc.defers.len() as i32
        i = dc - 1
        while i >= 0:
            let defer_node = sc.defers.get(i as i64)
            MirBuilder.lower_expr(self, defer_node)
            i = i - 1
        self.current_scope_idx = sc.parent_idx

fn MirBuilder.track_local(self: MirBuilder, local: i32) -> void:
    if self.current_scope_idx >= 0:
        let sc = self.scopes.get(self.current_scope_idx as i64)
        sc.locals.push(local)

fn MirBuilder.add_defer(self: MirBuilder, node: i32) -> void:
    if self.current_scope_idx >= 0:
        let sc = self.scopes.get(self.current_scope_idx as i64)
        sc.defers.push(node)

// ── Block management ─────────────────────────────────────────────────

fn MirBuilder.new_block(self: MirBuilder) -> i32:
    MirBody.add_block(self.body)

fn MirBuilder.switch_to(self: MirBuilder, bb: i32) -> void:
    self.current_bb = bb

// ── Function lowering ────────────────────────────────────────────────

fn MirBuilder.lower_fn(self: MirBuilder, node: i32) -> MirBody:
    let body = AstPool.get_data1(self.pool, node)
    let extra_start = AstPool.get_data2(self.pool, node)
    let param_count = AstPool.get_extra(self.pool, extra_start)
    // Set up return type (local 0)
    let ret_type_node = AstPool.get_extra(self.pool, extra_start + 2)
    // Add parameter locals
    self.body.arg_count = param_count
    var i = 0
    while i < param_count:
        let p_name = AstPool.get_extra(self.pool, extra_start + 3 + i * 2)
        MirBody.add_local(self.body, p_name, TYPE_I32(), 0)
        i = i + 1
    // Create entry block
    let entry_bb = MirBuilder.new_block(self)
    MirBuilder.switch_to(self, entry_bb)
    MirBuilder.push_scope(self)
    // Lower body
    if body > 0:
        let result = MirBuilder.lower_expr(self, body)
        // Store result in return local
        if result >= 0:
            MirBody.add_assign(self.body, self.current_bb, 0, RV_USE(), result, 0)
    // Emit drops and defers
    MirBuilder.pop_scope(self)
    // Set return terminator
    MirBody.set_return(self.body, self.current_bb)
    self.body

// ── Expression lowering ──────────────────────────────────────────────

// Lower an AST expression to MIR, returns the local holding the result.
fn MirBuilder.lower_expr(self: MirBuilder, node: i32) -> i32:
    if node <= 0:
        return -1
    let kind = AstPool.kind(self.pool, node)
    // Literals: create a temp local, assign constant
    if kind == NK_INT_LIT():
        let tmp = MirBody.add_local(self.body, -1, TYPE_I32(), 0)
        MirBody.add_assign(self.body, self.current_bb, tmp, RV_CONSTANT(), AstPool.get_data0(self.pool, node), 0)
        return tmp
    if kind == NK_FLOAT_LIT():
        let tmp = MirBody.add_local(self.body, -1, TYPE_F64(), 0)
        MirBody.add_assign(self.body, self.current_bb, tmp, RV_CONSTANT(), 0, 0)
        return tmp
    if kind == NK_BOOL_LIT():
        let tmp = MirBody.add_local(self.body, -1, TYPE_BOOL(), 0)
        MirBody.add_assign(self.body, self.current_bb, tmp, RV_CONSTANT(), AstPool.get_data0(self.pool, node), 0)
        return tmp
    if kind == NK_STRING_LIT():
        let tmp = MirBody.add_local(self.body, -1, TYPE_STR(), 0)
        MirBody.add_assign(self.body, self.current_bb, tmp, RV_CONSTANT(), AstPool.get_data0(self.pool, node), 0)
        return tmp
    // Identifier: resolve to local
    if kind == NK_IDENT():
        // In a real implementation, we'd look up the name.
        // For now, return a placeholder.
        let tmp = MirBody.add_local(self.body, AstPool.get_data0(self.pool, node), TYPE_I32(), 0)
        return tmp
    // Binary expression
    if kind == NK_BINARY():
        let lhs = MirBuilder.lower_expr(self, AstPool.get_data0(self.pool, node))
        let rhs = MirBuilder.lower_expr(self, AstPool.get_data1(self.pool, node))
        let op = AstPool.get_data2(self.pool, node)
        let tmp = MirBody.add_local(self.body, -1, TYPE_I32(), 0)
        MirBody.add_assign(self.body, self.current_bb, tmp, RV_BINARY_OP(), lhs, rhs)
        return tmp
    // Unary expression
    if kind == NK_UNARY():
        let operand = MirBuilder.lower_expr(self, AstPool.get_data0(self.pool, node))
        let tmp = MirBody.add_local(self.body, -1, TYPE_I32(), 0)
        MirBody.add_assign(self.body, self.current_bb, tmp, RV_UNARY_OP(), operand, 0)
        return tmp
    // Block
    if kind == NK_BLOCK():
        return MirBuilder.lower_block(self, node)
    // If expression
    if kind == NK_IF_EXPR():
        return MirBuilder.lower_if(self, node)
    // While loop
    if kind == NK_WHILE():
        return MirBuilder.lower_while(self, node)
    // Loop
    if kind == NK_LOOP():
        return MirBuilder.lower_loop(self, node)
    // Return
    if kind == NK_RETURN():
        let value = AstPool.get_data0(self.pool, node)
        if value > 0:
            let result = MirBuilder.lower_expr(self, value)
            MirBody.add_assign(self.body, self.current_bb, 0, RV_USE(), result, 0)
        MirBody.set_return(self.body, self.current_bb)
        // Create unreachable continuation block
        let unreachable_bb = MirBuilder.new_block(self)
        MirBuilder.switch_to(self, unreachable_bb)
        return -1
    // Break
    if kind == NK_BREAK():
        if self.break_bb >= 0:
            MirBody.set_goto(self.body, self.current_bb, self.break_bb)
        let unreachable_bb = MirBuilder.new_block(self)
        MirBuilder.switch_to(self, unreachable_bb)
        return -1
    // Continue
    if kind == NK_CONTINUE():
        if self.continue_bb >= 0:
            MirBody.set_goto(self.body, self.current_bb, self.continue_bb)
        let unreachable_bb = MirBuilder.new_block(self)
        MirBuilder.switch_to(self, unreachable_bb)
        return -1
    // Let binding
    if kind == NK_LET_BINDING():
        return MirBuilder.lower_let(self, node)
    // Assign
    if kind == NK_ASSIGN():
        let target = MirBuilder.lower_expr(self, AstPool.get_data0(self.pool, node))
        let value = MirBuilder.lower_expr(self, AstPool.get_data1(self.pool, node))
        if target >= 0:
            MirBody.add_assign(self.body, self.current_bb, target, RV_USE(), value, 0)
        return -1
    // Call
    if kind == NK_CALL():
        return MirBuilder.lower_call(self, node)
    // Defer
    if kind == NK_DEFER():
        let inner = AstPool.get_data0(self.pool, node)
        MirBuilder.add_defer(self, inner)
        return -1
    // Match
    if kind == NK_MATCH():
        return MirBuilder.lower_match(self, node)
    // Default: return a temp
    let tmp = MirBody.add_local(self.body, -1, TYPE_ERROR(), 0)
    tmp

// ── Block lowering ───────────────────────────────────────────────────

fn MirBuilder.lower_block(self: MirBuilder, node: i32) -> i32:
    let extra_start = AstPool.get_data0(self.pool, node)
    let stmt_count = AstPool.get_data1(self.pool, node)
    let tail = AstPool.get_data2(self.pool, node)
    MirBuilder.push_scope(self)
    var i = 0
    while i < stmt_count:
        let stmt = AstPool.get_extra(self.pool, extra_start + i)
        MirBuilder.lower_expr(self, stmt)
        i = i + 1
    var result = -1
    if tail > 0:
        result = MirBuilder.lower_expr(self, tail)
    MirBuilder.pop_scope(self)
    result

// ── If expression lowering ──────────────────────────────────────────

fn MirBuilder.lower_if(self: MirBuilder, node: i32) -> i32:
    let cond_node = AstPool.get_data0(self.pool, node)
    let then_node = AstPool.get_data1(self.pool, node)
    let else_node = AstPool.get_data2(self.pool, node)
    // Lower condition
    let cond = MirBuilder.lower_expr(self, cond_node)
    // Create blocks
    let then_bb = MirBuilder.new_block(self)
    let else_bb = MirBuilder.new_block(self)
    let join_bb = MirBuilder.new_block(self)
    // Emit switch
    MirBody.set_switch_int(self.body, self.current_bb, cond, then_bb, else_bb)
    // Result local
    let result = MirBody.add_local(self.body, -1, TYPE_I32(), 0)
    // Then branch
    MirBuilder.switch_to(self, then_bb)
    let then_val = MirBuilder.lower_expr(self, then_node)
    if then_val >= 0:
        MirBody.add_assign(self.body, self.current_bb, result, RV_USE(), then_val, 0)
    MirBody.set_goto(self.body, self.current_bb, join_bb)
    // Else branch
    MirBuilder.switch_to(self, else_bb)
    if else_node > 0:
        let else_val = MirBuilder.lower_expr(self, else_node)
        if else_val >= 0:
            MirBody.add_assign(self.body, self.current_bb, result, RV_USE(), else_val, 0)
    MirBody.set_goto(self.body, self.current_bb, join_bb)
    // Continue at join
    MirBuilder.switch_to(self, join_bb)
    result

// ── While loop lowering ──────────────────────────────────────────────

fn MirBuilder.lower_while(self: MirBuilder, node: i32) -> i32:
    let cond_node = AstPool.get_data0(self.pool, node)
    let body_node = AstPool.get_data1(self.pool, node)
    // Create blocks
    let cond_bb = MirBuilder.new_block(self)
    let body_bb = MirBuilder.new_block(self)
    let exit_bb = MirBuilder.new_block(self)
    // Goto condition check
    MirBody.set_goto(self.body, self.current_bb, cond_bb)
    // Condition block
    MirBuilder.switch_to(self, cond_bb)
    let cond = MirBuilder.lower_expr(self, cond_node)
    MirBody.set_switch_int(self.body, self.current_bb, cond, body_bb, exit_bb)
    // Body block
    MirBuilder.switch_to(self, body_bb)
    let saved_break = self.break_bb
    let saved_continue = self.continue_bb
    self.break_bb = exit_bb
    self.continue_bb = cond_bb
    MirBuilder.lower_expr(self, body_node)
    MirBody.set_goto(self.body, self.current_bb, cond_bb)
    self.break_bb = saved_break
    self.continue_bb = saved_continue
    // Continue at exit
    MirBuilder.switch_to(self, exit_bb)
    -1

// ── Loop lowering ────────────────────────────────────────────────────

fn MirBuilder.lower_loop(self: MirBuilder, node: i32) -> i32:
    let body_node = AstPool.get_data0(self.pool, node)
    let body_bb = MirBuilder.new_block(self)
    let exit_bb = MirBuilder.new_block(self)
    MirBody.set_goto(self.body, self.current_bb, body_bb)
    MirBuilder.switch_to(self, body_bb)
    let saved_break = self.break_bb
    let saved_continue = self.continue_bb
    self.break_bb = exit_bb
    self.continue_bb = body_bb
    MirBuilder.lower_expr(self, body_node)
    MirBody.set_goto(self.body, self.current_bb, body_bb)
    self.break_bb = saved_break
    self.continue_bb = saved_continue
    MirBuilder.switch_to(self, exit_bb)
    -1

// ── Let binding lowering ─────────────────────────────────────────────

fn MirBuilder.lower_let(self: MirBuilder, node: i32) -> i32:
    let name_sym = AstPool.get_data0(self.pool, node)
    let value_node = AstPool.get_data1(self.pool, node)
    let local = MirBody.add_local(self.body, name_sym, TYPE_I32(), 0)
    MirBuilder.track_local(self, local)
    if value_node > 0:
        let value = MirBuilder.lower_expr(self, value_node)
        if value >= 0:
            MirBody.add_assign(self.body, self.current_bb, local, RV_USE(), value, 0)
    -1

// ── Call lowering ────────────────────────────────────────────────────

fn MirBuilder.lower_call(self: MirBuilder, node: i32) -> i32:
    let callee = AstPool.get_data0(self.pool, node)
    let extra_start = AstPool.get_data1(self.pool, node)
    let arg_count = AstPool.get_data2(self.pool, node)
    // Lower callee
    let callee_local = MirBuilder.lower_expr(self, callee)
    // Lower arguments
    var i = 0
    while i < arg_count:
        let arg_node = AstPool.get_extra(self.pool, extra_start + i)
        MirBuilder.lower_expr(self, arg_node)
        i = i + 1
    // Create result temp
    let result = MirBody.add_local(self.body, -1, TYPE_I32(), 0)
    // Create continuation block
    let cont_bb = MirBuilder.new_block(self)
    MirBody.set_call(self.body, self.current_bb, callee_local, result, cont_bb)
    MirBuilder.switch_to(self, cont_bb)
    result

// ── Match lowering ───────────────────────────────────────────────────

fn MirBuilder.lower_match(self: MirBuilder, node: i32) -> i32:
    let subject = AstPool.get_data0(self.pool, node)
    let extra_start = AstPool.get_data1(self.pool, node)
    let arm_count = AstPool.get_data2(self.pool, node)
    let subj_local = MirBuilder.lower_expr(self, subject)
    let result = MirBody.add_local(self.body, -1, TYPE_I32(), 0)
    let exit_bb = MirBuilder.new_block(self)
    // For each arm, create a block
    var i = 0
    while i < arm_count:
        let arm_node = AstPool.get_extra(self.pool, extra_start + i)
        if arm_node > 0:
            let arm_kind = AstPool.kind(self.pool, arm_node)
            if arm_kind == NK_MATCH_ARM():
                let body = AstPool.get_data1(self.pool, arm_node)
                let arm_bb = MirBuilder.new_block(self)
                // For simplicity, chain arms as goto fallthrough
                MirBody.set_goto(self.body, self.current_bb, arm_bb)
                MirBuilder.switch_to(self, arm_bb)
                let val = MirBuilder.lower_expr(self, body)
                if val >= 0:
                    MirBody.add_assign(self.body, self.current_bb, result, RV_USE(), val, 0)
                MirBody.set_goto(self.body, self.current_bb, exit_bb)
        i = i + 1
    MirBuilder.switch_to(self, exit_bb)
    result
