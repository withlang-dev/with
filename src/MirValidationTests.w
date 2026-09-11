use Mir
use Compilation

// Construct malformed MIR directly: testing only corrected source lowering
// would leave the validator's original false-green result untested.
fn verdict(reachable: bool, initialized: bool, terminator: bool) -> str:
    let mir_mod = MirModule.init()
    var body = MirBody.init_for_fn(1)
    let local = body.new_temp(1)
    let place = body.new_place(local)
    let entry = body.new_block()
    let cleanup = body.new_block()
    body.push_stmt(entry, StmtKind.StorageLive, local, 0, 0)
    if initialized:
        let zero = body.gen_zero_operand(1)
        let value = body.new_rvalue(RvalueKind.RK_USE, zero, 0, 0)
        body.push_stmt(entry, StmtKind.Assign, place, value, 0)
    if reachable:
        body.set_terminator(entry, TermKind.TK_GOTO, cleanup, 0, 0, 0, 0)
    else:
        body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    if terminator:
        let done = body.new_block()
        body.set_terminator(cleanup, TermKind.TK_DROP_AND_GOTO, place, done, 0, 0, 0)
        body.set_terminator(done, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    else:
        body.push_stmt(cleanup, StmtKind.Drop, place, 0, 0)
        body.set_terminator(cleanup, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    validate_ownership_body(mir_mod, body)

fn parameter_verdict(dead: bool) -> str:
    let mir_mod = MirModule.init()
    var body = MirBody.init_for_fn(1)
    body.n_params = 1
    let local = body.new_temp(1)
    let place = body.new_place(local)
    let entry = body.new_block()
    body.push_stmt(entry, StmtKind.StorageLive, local, 0, 0)
    if dead: body.push_stmt(entry, StmtKind.StorageDead, local, 0, 0)
    body.push_stmt(entry, StmtKind.Drop, place, 0, 0)
    body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    validate_ownership_body(mir_mod, body)

fn global_verdict(is_global: bool) -> str:
    let mir_mod = MirModule.init()
    var body = MirBody.init_for_fn(1)
    let local = body.new_temp(1)
    if is_global: body.mark_global_local(local)
    let place = body.new_place(local)
    let entry = body.new_block()
    body.push_stmt(entry, StmtKind.Drop, place, 0, 0)
    body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    validate_ownership_body(mir_mod, body)

fn zero_storage_verdict() -> str:
    let mir_mod = MirModule.init()
    var body = MirBody.init_for_fn(1)
    let local = body.new_temp(1)
    let place = body.new_place(local)
    let entry = body.new_block()
    body.push_stmt(entry, StmtKind.StorageLive, local, 1, 0)
    body.push_stmt(entry, StmtKind.Drop, place, 0, 0)
    body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    validate_ownership_body(mir_mod, body)

fn multiple_body_verdict() -> str:
    var mir_mod = MirModule.init()
    for sym in [1, 2]:
        var body = MirBody.init_for_fn(sym)
        let local = body.new_temp(1)
        let place = body.new_place(local)
        let entry = body.new_block()
        body.push_stmt(entry, StmtKind.Drop, place, 0, 0)
        body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
        mir_mod.add_body(body)
    validate_ownership_mir_module(mir_mod)

pub fn mir_test_uninitialized_drop() -> Unit:
    for terminator in [false, true]:
        assert(verdict(true, false, terminator).contains("never initialized it (Uninit)"))
        assert(verdict(true, true, terminator) == "")
        assert(verdict(false, false, terminator) == "")
    assert(mir_drop_plan_action(MirDropState.Uninit) == "invalid")
    assert(mir_drop_plan_action(MirDropState.MaybeGarbage) == "invalid")
    assert(mir_drop_plan_action(MirDropState.Moved) == "skip")
    assert(mir_drop_state_sweep_bound(50000, 50000) == 7500300005i64)
    assert(parameter_verdict(false) == "")
    assert(parameter_verdict(true).contains("never initialized it (Uninit)"))
    assert(global_verdict(true) == "")
    assert(global_verdict(false).contains("never initialized it (Uninit)"))
    assert(zero_storage_verdict() == "")
    let multiple = multiple_body_verdict()
    assert(multiple.contains("fn sym1"))
    assert(multiple.contains("fn sym2"))
