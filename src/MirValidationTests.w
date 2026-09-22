use MirCore

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
        let constant = body.new_const(ConstKind.CK_ZERO_SIZED, 0, 0, 0, 1)
        let zero = body.new_operand(OperandKind.OK_CONSTANT, constant)
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

// #1180: a call handing a Unit operand to a callee whose parameter is not Unit.
// callee_kind: 0 = named callee with no body (runtime/extern), 1 = body with
// an i32 parameter, 2 = body with a Unit parameter.
fn unit_argument_verdict(callee_kind: i32, arg_is_unit: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_VOID, TypeKind.TY_INT]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let unit_ty = 1
    let int_ty = 2
    if callee_kind != 0:
        var callee = MirBody.init_for_fn(2)
        callee.new_local(if callee_kind == 2: unit_ty else: int_ty, 0, 0, 0)
        callee.n_params = 1
        let callee_entry = callee.new_block()
        callee.set_terminator(callee_entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
        mir_mod.add_body(callee)
    var body = MirBody.init_for_fn(1)
    let arg_local = body.new_temp(if arg_is_unit: unit_ty else: int_ty)
    let arg_place = body.new_place(arg_local)
    let result_local = body.new_temp(unit_ty)
    let result_place = body.new_place(result_local)
    let entry = body.new_block()
    let done = body.new_block()
    let callee_const = body.new_const(ConstKind.CK_FN, 2, 0, 0, unit_ty)
    let callee_operand = body.new_operand(OperandKind.OK_CONSTANT, callee_const)
    let args: Vec[i32] = Vec.new()
    args.push(body.new_operand(OperandKind.OK_COPY, arg_place))
    let call_id = body.new_call_args(&args)
    body.set_terminator(entry, TermKind.TK_CALL, callee_operand, call_id, result_place, done, 0)
    body.set_terminator(done, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    let err = validate_typed_mir_body(mir_mod, body)
    with_str_clone_ref(err.message)

pub fn mir_test_unit_call_argument() -> Unit:
    assert(unit_argument_verdict(0, true).contains("call argument 0 is Unit"))
    assert(unit_argument_verdict(1, true).contains("call argument 0 is Unit"))
    assert(unit_argument_verdict(2, true) == "")
    assert(unit_argument_verdict(0, false) == "")
    assert(unit_argument_verdict(1, false) == "")

// A payload read out of an enum variant whose declared type is not the
// variant's payload type. `?` over `Result[Unit, E]` once declared the Unit
// payload as the whole Result; the verifier trusted the declaration and
// codegen loaded an unsized field. The enum has one variant with one payload.
fn payload_read_verdict(payload_is_unit: bool, declared_is_enum: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_VOID, TypeKind.TY_INT, TypeKind.TY_ENUM]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let unit_ty = 1
    let int_ty = 2
    let enum_ty = 3
    let payload_ty = if payload_is_unit: unit_ty else: int_ty
    // The variant record: its name, its payload count, its payload types.
    mir_mod.sema_type_d0[enum_ty] = 7
    mir_mod.sema_type_d1[enum_ty] = mir_mod.sema_type_extra.len() as i32
    mir_mod.sema_type_d2[enum_ty] = 1
    mir_mod.sema_type_extra.push(0)
    mir_mod.sema_type_extra.push(1)
    mir_mod.sema_type_extra.push(payload_ty)
    let declared_ty = if declared_is_enum: enum_ty else: payload_ty
    var body = MirBody.init_for_fn(1)
    let scrutinee_local = body.new_temp(enum_ty)
    let scrutinee = body.new_place(scrutinee_local)
    let destination_local = body.new_temp(declared_ty)
    let destination = body.new_place(destination_local)
    let variant = body.new_downcast_place(scrutinee, 0, enum_ty)
    let payload = body.new_field_place(variant, 0, declared_ty)
    let entry = body.new_block()
    let payload_operand = body.new_operand(OperandKind.OK_MOVE, payload)
    let read = body.new_rvalue(RvalueKind.RK_USE, payload_operand, 0, 0)
    body.push_stmt(entry, StmtKind.Assign, destination, read, 0)
    body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    let err = validate_typed_mir_body(mir_mod, body)
    with_str_clone_ref(err.message)

pub fn mir_test_enum_payload_read() -> Unit:
    assert(payload_read_verdict(true, true).contains("enum payload read declares"))
    assert(payload_read_verdict(false, true).contains("enum payload read declares"))
    assert(payload_read_verdict(true, false) == "")
    assert(payload_read_verdict(false, false) == "")

// #1229: an `aggregate` assigned to a slice-typed place. An array literal
// passed to a `[]T` parameter was typed as the slice and lowered this way;
// codegen passed the elements as {ptr, len} and the callee segfaulted while
// this verifier said ok. A slice is produced by `slice`, never built from
// fields; the same aggregate into an array-typed place is the literal itself.
fn slice_aggregate_verdict(dest_is_slice: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_INT, TypeKind.TY_ARRAY, TypeKind.TY_SLICE]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(if kind == TypeKind.TY_INT: 0 else: 1)
        mir_mod.sema_type_d1.push(if kind == TypeKind.TY_ARRAY: 2 else: 0)
        mir_mod.sema_type_d2.push(0)
    let int_ty = 1
    let array_ty = 2
    let slice_ty = 3
    var body = MirBody.init_for_fn(1)
    let dest_local = body.new_temp(if dest_is_slice: slice_ty else: array_ty)
    let dest = body.new_place(dest_local)
    let entry = body.new_block()
    let fields: Vec[i32] = Vec.new()
    let names: Vec[i32] = Vec.new()
    for value in [5, 6]:
        let element = body.new_const(ConstKind.CK_INT, value, 0, 0, int_ty)
        fields.push(body.new_operand(OperandKind.OK_CONSTANT, element))
        names.push(0)
    let field_table = body.new_agg_fields(&fields, &names)
    let aggregate = body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, field_table, 0)
    body.push_stmt(entry, StmtKind.Assign, dest, aggregate, 0)
    body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    let err = validate_typed_mir_body(mir_mod, body)
    with_str_clone_ref(err.message)

pub fn mir_test_slice_aggregate() -> Unit:
    assert(slice_aggregate_verdict(true).contains("aggregate assigned to a slice-typed place"))
    assert(slice_aggregate_verdict(false) == "")
