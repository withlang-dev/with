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
    let variant = body.new_downcast_place(scrutinee, 0)
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

// #1230: a call through a fn-typed value with more arguments than its type
// declares. MirLower resolved a parameter named `check` to
// `std.builtins.check` by name and appended that fn's `loc = src()`
// default; this verifier said ok and LLVM's rejected the call. The fn type
// is `fn(i32)`: one parameter, whatever the argument count.
fn indirect_arity_verdict(arg_count: i32) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_VOID, TypeKind.TY_INT, TypeKind.TY_FN]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let unit_ty = 1
    let int_ty = 2
    let fn_ty = 3
    mir_mod.sema_type_d0[fn_ty] = mir_mod.sema_type_extra.len() as i32
    mir_mod.sema_type_d1[fn_ty] = 1
    mir_mod.sema_type_d2[fn_ty] = unit_ty
    mir_mod.sema_type_extra.push(int_ty)
    var body = MirBody.init_for_fn(1)
    let callee_local = body.new_temp(fn_ty)
    let callee_place = body.new_place(callee_local)
    let result_local = body.new_temp(unit_ty)
    let result_place = body.new_place(result_local)
    let entry = body.new_block()
    let done = body.new_block()
    let callee_operand = body.new_operand(OperandKind.OK_COPY, callee_place)
    let args: Vec[i32] = Vec.new()
    for i in 0..arg_count:
        let argument = body.new_const(ConstKind.CK_INT, i, 0, 0, int_ty)
        args.push(body.new_operand(OperandKind.OK_CONSTANT, argument))
    let call_id = body.new_call_args(&args)
    body.set_terminator(entry, TermKind.TK_CALL, callee_operand, call_id, result_place, done, 0)
    body.set_terminator(done, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    let err = validate_typed_mir_body(mir_mod, body)
    with_str_clone_ref(err.message)

pub fn mir_test_indirect_call_arity() -> Unit:
    assert(indirect_arity_verdict(2).contains("indirect call passes 2 argument(s) but the callee's fn type declares 1"))
    assert(indirect_arity_verdict(0).contains("declares 1"))
    assert(indirect_arity_verdict(1) == "")

// #1444: a discriminant enum's discriminant is a value of its repr type.
// MirLower assigned every discriminant to an i32 temp; codegen then stored
// that i32 through the u8 slot it sized from the loaded value, and a match on
// a u8 enum picked the wrong arm. This verifier said ok.
fn discriminant_dest_verdict(dest_is_repr: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_INT, TypeKind.TY_INT, TypeKind.TY_ENUM]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let i32_ty = 1
    let u8_ty = 2
    let enum_ty = 3
    mir_mod.sema_type_d0[i32_ty] = 32
    mir_mod.sema_type_d0[u8_ty] = 8
    mir_mod.sema_type_d1[u8_ty] = 1
    mir_mod.sema_disc_repr_types.insert(enum_ty, u8_ty)
    var body = MirBody.init_for_fn(1)
    let subject_local = body.new_temp(enum_ty)
    let subject = body.new_place(subject_local)
    let dest_local = body.new_temp(if dest_is_repr: u8_ty else: i32_ty)
    let dest = body.new_place(dest_local)
    let entry = body.new_block()
    let disc = body.new_rvalue(RvalueKind.RK_DISCRIMINANT, subject, 0, 0)
    body.push_stmt(entry, StmtKind.Assign, dest, disc, 0)
    body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    let err = validate_typed_mir_body(mir_mod, body)
    with_str_clone_ref(err.message)

pub fn mir_test_discriminant_repr_dest() -> Unit:
    assert(discriminant_dest_verdict(false).contains("discriminant of a ty=3 enum is its repr ty=2, assigned to ty=1"))
    assert(discriminant_dest_verdict(true) == "")

// #1455: an enum aggregate names its variant by index. `Move(i32, i32) = 7`
// was built as `aggregate(kind=1, tag=7)` of a two-variant enum; codegen
// looked up variant 7's payload type and failed. This verifier said ok.
fn enum_aggregate_verdict(variant: i32) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_ENUM]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let enum_ty = 1
    mir_mod.sema_type_d2[enum_ty] = 2
    var body = MirBody.init_for_fn(1)
    let dest_local = body.new_temp(enum_ty)
    let dest = body.new_place(dest_local)
    let entry = body.new_block()
    let fields: Vec[i32] = Vec.new()
    let names: Vec[i32] = Vec.new()
    let field_table = body.new_agg_fields(&fields, &names)
    let agg = body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, field_table, variant)
    body.push_stmt(entry, StmtKind.Assign, dest, agg, 0)
    body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    with_str_clone_ref(validate_typed_mir_body(mir_mod, body).message)

pub fn mir_test_enum_aggregate_variant_index() -> Unit:
    assert(enum_aggregate_verdict(7).contains("enum aggregate names variant 7 of a ty=1 enum with 2 variants"))
    assert(enum_aggregate_verdict(1) == "")

// #1442: the type the validator derives for an undeclared payload place of a
// one-parameter generic enum instance. `G[T]: A(h: H[T]) | B(n: i64)` has
// Option's shape (one parameter, one single-payload variant first), and the
// Option guess named the argument `i64` as the payload `H[T]`. Types: 1 i64,
// 2 the enum H, 3 `H[T]`, 4 the enum G, 5 `G[i64]`, 6 the parameter T.
fn generic_payload_derived(g_is_option: bool) -> i32:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_INT, TypeKind.TY_ENUM, TypeKind.TY_GENERIC_INST, TypeKind.TY_ENUM, TypeKind.TY_GENERIC_INST, TypeKind.TY_STRUCT]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let h_sym = 101
    let g_sym = 102
    mir_mod.sema_type_d0[1] = 64
    mir_mod.sema_type_d1[1] = 1
    // H: X(t: T) | Y
    mir_mod.sema_type_d0[2] = h_sym
    mir_mod.sema_type_d1[2] = mir_mod.sema_type_extra.len() as i32
    mir_mod.sema_type_d2[2] = 2
    for word in [201, 1, 6, 202, 0]:
        mir_mod.sema_type_extra.push(word)
    // H[T]
    mir_mod.sema_type_d0[3] = h_sym
    mir_mod.sema_type_d1[3] = mir_mod.sema_type_extra.len() as i32
    mir_mod.sema_type_d2[3] = 1
    mir_mod.sema_type_extra.push(6)
    // G: A(h: H[T]) | B(n: i64)
    mir_mod.sema_type_d0[4] = g_sym
    mir_mod.sema_type_d1[4] = mir_mod.sema_type_extra.len() as i32
    mir_mod.sema_type_d2[4] = 2
    for word in [203, 1, 3, 204, 1, 1]:
        mir_mod.sema_type_extra.push(word)
    // G[i64]
    mir_mod.sema_type_d0[5] = g_sym
    mir_mod.sema_type_d1[5] = mir_mod.sema_type_extra.len() as i32
    mir_mod.sema_type_d2[5] = 1
    mir_mod.sema_type_extra.push(1)
    mir_mod.sema_type_d0[6] = 103
    if g_is_option:
        mir_mod.sema_option_sym = g_sym
    var body = MirBody.init_for_fn(1)
    let subject_local = body.new_temp(5)
    let subject = body.new_place(subject_local)
    let variant = body.new_downcast_place(subject, 0)
    let payload = body.new_field_place(variant, 0, 0)
    mir_validate_place_derived_type(mir_mod, body, payload)

pub fn mir_test_generic_payload_not_guessed() -> Unit:
    assert(generic_payload_derived(false) == 3)
    assert(generic_payload_derived(true) == 1)

// #1443: a monomorphized generic call passing the value where the callee's
// parameter is a reference to it. `next.as_ref()` with `next: &Box[L]` passed
// `next.*` — a Box and `&Box` are both `ptr`, so the callee read the node as
// the box. Types: 1 Unit, 2 the struct standing in for Box[L], 3 `&` of it.
fn missing_borrow_verdict(arg_is_ref: bool, generic: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_VOID, TypeKind.TY_STRUCT, TypeKind.TY_REF]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let unit_ty = 1
    let box_ty = 2
    let ref_ty = 3
    mir_mod.sema_type_d0[ref_ty] = box_ty
    var callee = MirBody.init_for_fn(20)
    callee.new_local(ref_ty, 0, 0, 0)
    callee.n_params = 1
    let callee_entry = callee.new_block()
    callee.set_terminator(callee_entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    mir_mod.add_body(callee)
    var body = MirBody.init_for_fn(1)
    let recv_local = body.new_temp(ref_ty)
    let recv_place = body.new_place(recv_local)
    let deref_place = body.new_deref_place(recv_place, box_ty)
    let arg_place = if arg_is_ref: recv_place else: deref_place
    let result_local = body.new_temp(unit_ty)
    let result_place = body.new_place(result_local)
    let entry = body.new_block()
    let done = body.new_block()
    let callee_const = body.new_const(ConstKind.CK_FN, 2, 0, 0, unit_ty)
    let callee_operand = body.new_operand(OperandKind.OK_CONSTANT, callee_const)
    let args: Vec[i32] = Vec.new()
    args.push(body.new_operand(OperandKind.OK_COPY, arg_place))
    let call_id = body.new_call_args(&args)
    if generic:
        body.set_call_intrinsic(call_id, MirIntrinsic.GENERIC_CALL)
        body.set_call_contract(call_id, 0, 20)
    body.set_terminator(entry, TermKind.TK_CALL, callee_operand, call_id, result_place, done, 0)
    body.set_terminator(done, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    let err = validate_typed_mir_body(mir_mod, body)
    with_str_clone_ref(err.message)

pub fn mir_test_generic_call_missing_borrow() -> Unit:
    assert(missing_borrow_verdict(false, true).contains("call argument 0 is a value where the callee parameter is a reference to it"))
    assert(missing_borrow_verdict(true, true) == "")
    // A direct call may pass the place value; codegen takes its address.
    assert(missing_borrow_verdict(false, false) == "")

// #1394: a variant payload moved out on one arm and the whole enum dropped
// at the join, with no reset-on-move blank of the payload. This is #1363's
// MIR (`_8 = move _6<as v0>.f0`, then `drop(_6)`): the enum drop glue frees
// the payload the move's destination owns, and this validator said ok.
// `arm` picks what the moving arm does: 0 moves the payload, 1 moves it and
// blanks it (§2.5.1), 2 moves the whole enum instead (a conditional whole
// move, which the guarded drop handles).
fn vacated_payload_verdict(arm: i32, payload_drops: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_INT, TypeKind.TY_INT, TypeKind.TY_ENUM]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let flag_ty = 1
    let payload_ty = 2
    let enum_ty = 3
    mir_mod.sema_type_d0[enum_ty] = 7
    mir_mod.sema_type_d1[enum_ty] = mir_mod.sema_type_extra.len() as i32
    mir_mod.sema_type_d2[enum_ty] = 1
    mir_mod.sema_type_extra.push(0)
    mir_mod.sema_type_extra.push(1)
    mir_mod.sema_type_extra.push(payload_ty)
    if payload_drops: mir_mod.sema_moved_drop_types.insert(payload_ty, 1)
    var body = MirBody.init_for_fn(1)
    body.n_params = 1
    let flag_local = body.new_temp(flag_ty)
    let flag = body.new_place(flag_local)
    let subject_local = body.new_temp(enum_ty)
    let subject = body.new_place(subject_local)
    let variant = body.new_downcast_place(subject, 0)
    let payload = body.new_field_place(variant, 0, payload_ty)
    let taken_local = body.new_temp(payload_ty)
    let taken = body.new_place(taken_local)
    let whole_local = body.new_temp(enum_ty)
    let whole = body.new_place(whole_local)
    let entry = body.new_block()
    let moving = body.new_block()
    let other = body.new_block()
    let join = body.new_block()
    let done = body.new_block()
    let enum_blank = body.new_const(ConstKind.CK_ZERO_SIZED, 0, 0, 0, enum_ty)
    let enum_blank_op = body.new_operand(OperandKind.OK_CONSTANT, enum_blank)
    let init = body.new_rvalue(RvalueKind.RK_USE, enum_blank_op, 0, 0)
    body.push_stmt(entry, StmtKind.StorageLive, subject_local, 0, 0)
    body.push_stmt(entry, StmtKind.Assign, subject, init, 0)
    let vals: Vec[i64] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(moving)
    let table = body.new_switch_table(&vals, &targets)
    let flag_op = body.new_operand(OperandKind.OK_COPY, flag)
    body.set_terminator(entry, TermKind.TK_SWITCH_INT, flag_op, table, other, 0, 0)
    let moved_place = if arm == 2: subject else: payload
    let moved_op = body.new_operand(OperandKind.OK_MOVE, moved_place)
    let moved = body.new_rvalue(RvalueKind.RK_USE, moved_op, 0, 0)
    body.push_stmt(moving, StmtKind.Assign, if arm == 2: whole else: taken, moved, 0)
    if arm == 1:
        let payload_blank = body.new_const(ConstKind.CK_ZERO_SIZED, 0, 0, 0, payload_ty)
        let payload_blank_op = body.new_operand(OperandKind.OK_CONSTANT, payload_blank)
        let reset = body.new_rvalue(RvalueKind.RK_USE, payload_blank_op, 0, 0)
        body.push_stmt(moving, StmtKind.Assign, payload, reset, 0)
    body.set_terminator(moving, TermKind.TK_GOTO, join, 0, 0, 0, 0)
    body.set_terminator(other, TermKind.TK_GOTO, join, 0, 0, 0, 0)
    body.push_stmt(join, StmtKind.Drop, subject, 0, 0)
    body.set_terminator(join, TermKind.TK_GOTO, done, 0, 0, 0, 0)
    body.set_terminator(done, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    validate_ownership_body(mir_mod, body)

pub fn mir_test_vacated_payload_drop() -> Unit:
    assert(vacated_payload_verdict(0, true).contains("drop of _2 frees _2<as v0>.f0, which a path reaching it moved out (MaybeMoved)"))
    assert(vacated_payload_verdict(1, true) == "")
    assert(vacated_payload_verdict(2, true) == "")
    // A payload with no drop glue is not freed again by the enum's drop.
    assert(vacated_payload_verdict(0, false) == "")

// #1414: a move of a drop-bearing place a path reaching it already moved
// out. A failed match guard's arm bound `move _3<as v0>.f0` and the next arm
// bound it again: a double free that validate-all passed. `shape`:
//   0  moved on one arm, moved again at the join (MaybeMoved)
//   1  moved on one arm and re-initialized there, moved at the join
//   2  moved twice on one path (Moved)
//   3  initialized on one arm only, moved at the join (Maybe: not judged —
//      a path that never wrote the place is not a path that moved it)
//   4  moved on one arm, passed by move to a call at the join (not judged:
//      a call argument OK_MOVE is a borrow for some receivers until #1505)
fn moved_twice_verdict(shape: i32, drops: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_INT, TypeKind.TY_STRUCT, TypeKind.TY_VOID]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let flag_ty = 1
    let value_ty = 2
    let unit_ty = 3
    if drops: mir_mod.sema_moved_drop_types.insert(value_ty, 1)
    var body = MirBody.init_for_fn(1)
    body.n_params = 1
    let flag_local = body.new_temp(flag_ty)
    let flag = body.new_place(flag_local)
    let value_local = body.new_temp(value_ty)
    let value = body.new_place(value_local)
    let first_local = body.new_temp(value_ty)
    let first = body.new_place(first_local)
    let second_local = body.new_temp(value_ty)
    let second = body.new_place(second_local)
    let result_local = body.new_temp(unit_ty)
    let result = body.new_place(result_local)
    let entry = body.new_block()
    let moving = body.new_block()
    let other = body.new_block()
    let join = body.new_block()
    let done = body.new_block()
    let blank = body.new_const(ConstKind.CK_ZERO_SIZED, 0, 0, 0, value_ty)
    let blank_op = body.new_operand(OperandKind.OK_CONSTANT, blank)
    let init = body.new_rvalue(RvalueKind.RK_USE, blank_op, 0, 0)
    let move_op = body.new_operand(OperandKind.OK_MOVE, value)
    let take = body.new_rvalue(RvalueKind.RK_USE, move_op, 0, 0)
    body.push_stmt(entry, StmtKind.StorageLive, value_local, 0, 0)
    if shape != 3:
        body.push_stmt(entry, StmtKind.Assign, value, init, 0)
    if shape == 2:
        body.push_stmt(entry, StmtKind.Assign, first, take, 0)
    let vals: Vec[i64] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(moving)
    let table = body.new_switch_table(&vals, &targets)
    let flag_op = body.new_operand(OperandKind.OK_COPY, flag)
    body.set_terminator(entry, TermKind.TK_SWITCH_INT, flag_op, table, other, 0, 0)
    if shape == 3:
        body.push_stmt(moving, StmtKind.Assign, value, init, 0)
    else if shape != 2:
        body.push_stmt(moving, StmtKind.Assign, first, take, 0)
    if shape == 1:
        body.push_stmt(moving, StmtKind.Assign, value, init, 0)
    body.set_terminator(moving, TermKind.TK_GOTO, join, 0, 0, 0, 0)
    body.set_terminator(other, TermKind.TK_GOTO, join, 0, 0, 0, 0)
    if shape == 4:
        let callee_const = body.new_const(ConstKind.CK_FN, 2, 0, 0, unit_ty)
        let callee = body.new_operand(OperandKind.OK_CONSTANT, callee_const)
        let args: Vec[i32] = Vec.new()
        args.push(move_op)
        let call_id = body.new_call_args(&args)
        body.set_terminator(join, TermKind.TK_CALL, callee, call_id, result, done, 0)
    else:
        body.push_stmt(join, StmtKind.Assign, second, take, 0)
        body.set_terminator(join, TermKind.TK_GOTO, done, 0, 0, 0, 0)
    body.set_terminator(done, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    validate_ownership_body(mir_mod, body)

pub fn mir_test_move_of_moved_place() -> Unit:
    assert(moved_twice_verdict(0, true).contains("move of _2, which a path reaching it already moved out (MaybeMoved)"))
    assert(moved_twice_verdict(1, true) == "")
    assert(moved_twice_verdict(2, true).contains("move of _2, which a path reaching it already moved out (Moved)"))
    assert(moved_twice_verdict(3, true) == "")
    assert(moved_twice_verdict(4, true) == "")
    // A value with no drop glue is not freed twice.
    assert(moved_twice_verdict(0, false) == "")

// #1415: `_4 = move _1.*.p` through `&self` — a move out of a reference's
// pointee — passed validate-all, and both owners freed the value. A raw
// pointer's pointee is owned through the pointer (the unsafe tier) and
// stays legal; so is a copy through a reference.
fn move_through_verdict(pointer_kind: i32, moves: bool, drops: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_INT, pointer_kind]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(if kind == pointer_kind: 1 else: 0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(0)
    let value_ty = 1
    let pointer_ty = 2
    if drops: mir_mod.sema_moved_drop_types.insert(value_ty, 1)
    var body = MirBody.init_for_fn(1)
    body.n_params = 1
    let pointer_local = body.new_temp(pointer_ty)
    let pointer = body.new_place(pointer_local)
    let pointee = body.new_deref_place(pointer, value_ty)
    let dest_local = body.new_temp(value_ty)
    let dest = body.new_place(dest_local)
    let entry = body.new_block()
    let read = body.new_operand(if moves: OperandKind.OK_MOVE else: OperandKind.OK_COPY, pointee)
    let rv = body.new_rvalue(RvalueKind.RK_USE, read, 0, 0)
    body.push_stmt(entry, StmtKind.Assign, dest, rv, 0)
    body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    validate_ownership_body(mir_mod, body)

pub fn mir_test_move_through_reference() -> Unit:
    assert(move_through_verdict(TypeKind.TY_REF, true, true).contains("moves out of _1.* through a reference"))
    assert(move_through_verdict(TypeKind.TY_REF, false, true) == "")
    assert(move_through_verdict(TypeKind.TY_REF, true, false) == "")
    assert(move_through_verdict(TypeKind.TY_PTR, true, true) == "")

// #1464: a field projection on a scalar local. MirLower typed an unannotated
// `async fn`'s Task handle as the awaited i32 and lower_single_await read the
// fiber id as `.f0` of it, declaring the place i32; the verifier took the
// declared type and passed it. The base is an i32 local, or a tuple (i32, i32)
// for the control; the place declares i32 either way.
fn scalar_projection_verdict(base_is_scalar: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_INT, TypeKind.TY_TUPLE]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(0)
        mir_mod.sema_type_d1.push(if kind == TypeKind.TY_TUPLE: 2 else: 0)
        mir_mod.sema_type_d2.push(0)
    mir_mod.sema_type_extra.push(1)
    mir_mod.sema_type_extra.push(1)
    let int_ty = 1
    let tuple_ty = 2
    var body = MirBody.init_for_fn(1)
    let base_local = body.new_temp(if base_is_scalar: int_ty else: tuple_ty)
    let base = body.new_place(base_local)
    let field = body.new_field_place(base, 0, int_ty)
    let dest_local = body.new_temp(int_ty)
    let dest = body.new_place(dest_local)
    let entry = body.new_block()
    let field_read = body.new_operand(OperandKind.OK_COPY, field)
    let read = body.new_rvalue(RvalueKind.RK_USE, field_read, 0, 0)
    body.push_stmt(entry, StmtKind.Assign, dest, read, 0)
    body.set_terminator(entry, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    let err = validate_typed_mir_body(mir_mod, body)
    with_str_clone_ref(err.message)

pub fn mir_test_scalar_field_projection() -> Unit:
    assert(scalar_projection_verdict(true).contains("of a scalar"))
    assert(scalar_projection_verdict(false) == "")

// #1464: a fiber intrinsic whose task operand is not a task handle — the
// awaited value's type standing where the Task[T] lives. Type 2 is the
// generic instance Task[i32] (base symbol 9, the module's Task symbol).
fn task_operand_verdict(operand_is_task: bool) -> str:
    var mir_mod = MirModule.init()
    for kind in [0, TypeKind.TY_INT, TypeKind.TY_GENERIC_INST]:
        mir_mod.sema_type_kinds.push(kind)
        mir_mod.sema_type_d0.push(if kind == TypeKind.TY_GENERIC_INST: 9 else: 0)
        mir_mod.sema_type_d1.push(0)
        mir_mod.sema_type_d2.push(if kind == TypeKind.TY_GENERIC_INST: 1 else: 0)
    mir_mod.sema_type_extra.push(1)
    mir_mod.sema_task_sym = 9
    let int_ty = 1
    let task_ty = 2
    var body = MirBody.init_for_fn(1)
    let handle_local = body.new_temp(if operand_is_task: task_ty else: int_ty)
    let handle = body.new_place(handle_local)
    let result_local = body.new_temp(int_ty)
    let result = body.new_place(result_local)
    let entry = body.new_block()
    let done = body.new_block()
    let args: Vec[i32] = Vec.new()
    args.push(body.new_operand(OperandKind.OK_COPY, handle))
    let owns = body.new_const(ConstKind.CK_INT, 1, 0, 0, int_ty)
    args.push(body.new_operand(OperandKind.OK_CONSTANT, owns))
    let call_id = body.new_call_args(&args)
    body.set_call_intrinsic(call_id, MirIntrinsic.FIBER_AWAIT)
    let unit_const = body.new_const(ConstKind.CK_UNIT, 0, 0, 0, int_ty)
    let unit_callee = body.new_operand(OperandKind.OK_CONSTANT, unit_const)
    body.set_terminator(entry, TermKind.TK_CALL, unit_callee, call_id, result, done, 0)
    body.set_terminator(done, TermKind.TK_RETURN, 0, 0, 0, 0, 0)
    let err = validate_typed_mir_body(mir_mod, body)
    with_str_clone_ref(err.message)

pub fn mir_test_task_operand() -> Unit:
    assert(task_operand_verdict(false).contains("not a Task or ScopedTask handle"))
    assert(task_operand_verdict(true) == "")
