use ComptimeValue
use Sema
use Ast
use Span
use Diagnostic
use InternPool
use TypeLayout

const COMPTIME_RECURSION_LIMIT: i32 = 256
const COMPTIME_STEP_LIMIT: i32 = 50000

enum ComptimeControlKind: i32:
    CTL_VALUE = 0
    CTL_RETURN = 1
    CTL_BREAK = 2
    CTL_CONTINUE = 3
    CTL_ERROR = 4

type ComptimeControl {
    kind: i32,
    value: ComptimeValue,
    label: i32,
}

type ComptimeEvaluator {
    sema: Sema,
    ast: AstPool,
    pool: InternPool,
    slot_syms: Vec[i32],
    slot_values: Vec[ComptimeValue],
    slot_muts: Vec[i32],
    scope_starts: Vec[i32],
    loop_labels: Vec[i32],
    extra_values: Vec[ComptimeValue],
    active_global_syms: Vec[i32],
    active_fn_syms: Vec[i32],
    steps: i32,
    step_budget: i32,
    recursion_limit: i32,
    require_success: i32,
    had_error: i32,
}

type ComptimeEvalResult {
    value: ComptimeValue,
    extras: Vec[ComptimeValue],
}

fn comptime_control_value(value: ComptimeValue) -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_VALUE, value, label: 0 }

fn comptime_control_return(value: ComptimeValue) -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_RETURN, value, label: 0 }

fn comptime_control_break(value: ComptimeValue, label: i32) -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_BREAK, value, label }

fn comptime_control_continue(label: i32) -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_CONTINUE, value: comptime_value_void(0), label }

fn comptime_control_error() -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_ERROR, value: comptime_value_invalid(), label: 0 }

fn ComptimeEvaluator.init(sema: Sema, ast: AstPool, pool: InternPool, require_success: i32) -> ComptimeEvaluator:
    ComptimeEvaluator {
        sema,
        ast,
        pool,
        slot_syms: Vec.new(),
        slot_values: Vec.new(),
        slot_muts: Vec.new(),
        scope_starts: Vec.new(),
        loop_labels: Vec.new(),
        extra_values: Vec.new(),
        active_global_syms: Vec.new(),
        active_fn_syms: Vec.new(),
        steps: 0,
        step_budget: COMPTIME_STEP_LIMIT,
        recursion_limit: COMPTIME_RECURSION_LIMIT,
        require_success,
        had_error: 0,
    }

fn comptime_eval_result_invalid() -> ComptimeEvalResult:
    ComptimeEvalResult {
        value: comptime_value_invalid(),
        extras: Vec.new(),
    }

fn comptime_try_eval_expr_result(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ast: AstPool, pool: InternPool, node: i32) -> ComptimeEvalResult:
    let sema = unsafe: *sema_ptr
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 0)
    let value = evaluator.eval_root(diags, node)
    ComptimeEvalResult {
        value,
        extras: evaluator.extra_values,
    }

fn comptime_force_eval_expr_result(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ast: AstPool, pool: InternPool, node: i32) -> ComptimeEvalResult:
    let sema = unsafe: *sema_ptr
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 1)
    let value = evaluator.eval_root(diags, node)
    ComptimeEvalResult {
        value,
        extras: evaluator.extra_values,
    }

fn comptime_try_eval_expr(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ast: AstPool, pool: InternPool, node: i32) -> ComptimeValue:
    comptime_try_eval_expr_result(sema_ptr, diags, ast, pool, node).value

fn comptime_force_eval_expr(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ast: AstPool, pool: InternPool, node: i32) -> ComptimeValue:
    comptime_force_eval_expr_result(sema_ptr, diags, ast, pool, node).value

fn ComptimeEvaluator.eval_root(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeValue:
    let signal = self.eval_expr(diags, node)
    if signal.kind == ComptimeControlKind.CTL_VALUE:
        return signal.value
    if signal.kind == ComptimeControlKind.CTL_RETURN:
        return signal.value
    if signal.kind == ComptimeControlKind.CTL_BREAK:
        self.fail(diags, node, "break escaped comptime evaluation")
        return comptime_value_invalid()
    if signal.kind == ComptimeControlKind.CTL_CONTINUE:
        self.fail(diags, node, "continue escaped comptime evaluation")
        return comptime_value_invalid()
    comptime_value_invalid()

fn ComptimeEvaluator.fail(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32, msg: str) -> ComptimeControl:
    if self.had_error == 0 and self.require_success != 0 and self.sema.suppress_errors == 0:
        let start = self.ast.get_start(node)
        let end = self.ast.get_end(node)
        diags.emit(Diagnostic.err(msg, Span { file: self.sema.local_file_id, start, end }))
    self.had_error = 1
    comptime_control_error()

fn ComptimeEvaluator.unsupported(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    self.fail(diags, node, "expression is not comptime-evaluable yet")

fn ComptimeEvaluator.step(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> i32:
    if self.had_error != 0:
        return 0
    self.steps = self.steps + 1
    if self.steps > self.step_budget:
        self.fail(diags, node, "comptime step limit exceeded")
        return 0
    1

fn ComptimeEvaluator.push_scope(self: ComptimeEvaluator):
    self.scope_starts.push(self.slot_syms.len() as i32)

fn ComptimeEvaluator.pop_scope(self: ComptimeEvaluator):
    if self.scope_starts.len() as i32 == 0:
        return
    let start = self.scope_starts.get((self.scope_starts.len() as i32 - 1) as i64)
    while self.slot_syms.len() as i32 > start:
        self.slot_syms.pop()
        self.slot_values.pop()
        self.slot_muts.pop()
    self.scope_starts.pop()

fn ComptimeEvaluator.bind_value(self: ComptimeEvaluator, sym: i32, value: ComptimeValue, is_mut: i32):
    self.slot_syms.push(sym)
    self.slot_values.push(value)
    self.slot_muts.push(is_mut)

fn ComptimeEvaluator.lookup_slot_index(self: ComptimeEvaluator, sym: i32) -> i32:
    var i = self.slot_syms.len() as i32 - 1
    while i >= 0:
        if self.slot_syms.get(i as i64) == sym:
            return i
        i = i - 1
    0 - 1

fn ComptimeEvaluator.lookup_value(self: ComptimeEvaluator, diags: &mut DiagnosticList, sym: i32, node: i32) -> ComptimeControl:
    let idx = self.lookup_slot_index(sym)
    if idx >= 0:
        return comptime_control_value(self.slot_values.get(idx as i64))
    let decl = self.find_module_let_decl(sym)
    if decl == 0:
        return self.fail(diags, node, "runtime value is not available at comptime")
    if self.ast.get_data2(decl) % 2 != 0:
        return self.fail(diags, node, "mutable global access is not allowed in comptime")
    self.eval_module_let_decl(diags, decl, node)

fn ComptimeEvaluator.assign_value(self: ComptimeEvaluator, diags: &mut DiagnosticList, sym: i32, value: ComptimeValue, node: i32) -> ComptimeControl:
    let idx = self.lookup_slot_index(sym)
    if idx < 0:
        return self.fail(diags, node, "assignment target is not available at comptime")
    if self.slot_muts.get(idx as i64) == 0:
        return self.fail(diags, node, "cannot assign to immutable variable")
    self.bind_value(sym, value, self.slot_muts.get(idx as i64))
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.find_module_let_decl(self: ComptimeEvaluator, sym: i32) -> i32:
    var di = self.ast.decl_count() as i32 - 1
    while di >= 0:
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NodeKind.NK_LET_DECL and self.ast.get_data0(decl) == sym:
            return decl as i32
        di = di - 1
    0

fn ComptimeEvaluator.find_decl_index(self: ComptimeEvaluator, decl_node: i32) -> i32:
    for di in 0..self.ast.decl_count():
        if self.ast.get_decl(di) == decl_node:
            return di
    0 - 1

fn ComptimeEvaluator.decl_file_id(self: ComptimeEvaluator, decl_node: i32) -> i32:
    let decl_idx = self.find_decl_index(decl_node)
    if decl_idx >= 0 and decl_idx < self.sema.decl_source_file_ids.len() as i32:
        return self.sema.decl_source_file_ids.get(decl_idx as i64)
    self.sema.local_file_id

fn ComptimeEvaluator.push_extra_value(self: ComptimeEvaluator, value: ComptimeValue):
    self.extra_values.push(value)

fn ComptimeEvaluator.node_type_or(self: ComptimeEvaluator, node: i32, fallback: i32) -> i32:
    if self.sema.typed_expr_types.contains(node):
        let typed = self.sema.typed_expr_types.get(node).unwrap()
        if typed != 0:
            return typed
    fallback

fn ComptimeEvaluator.static_receiver_type(self: ComptimeEvaluator, node: i32) -> i32:
    let typed = self.node_type_or(node, 0)
    if typed != 0:
        return typed
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT or kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.ast.get_data0(node)
        let prim = self.sema.primitive_type_by_sym(sym)
        if prim != 0:
            return prim
        if self.sema.named_types.contains(sym):
            return self.sema.named_types.get(sym).unwrap()
    0

fn ComptimeEvaluator.struct_field_index(self: ComptimeEvaluator, type_id: i32, field_sym: i32) -> i32:
    let field_count = self.sema.type_reflection_field_count(type_id)
    for fi in 0..field_count:
        if self.sema.type_reflection_field_name(type_id, fi) == field_sym:
            return fi
    0 - 1

fn ComptimeEvaluator.variant_payload_name(self: ComptimeEvaluator, type_id: i32, variant_index: i32) -> str:
    let payload_count = self.sema.type_reflection_variant_payload_count(type_id, variant_index)
    if payload_count <= 0:
        return ""
    if payload_count == 1:
        let payload_tid = self.sema.type_reflection_variant_payload_type(type_id, variant_index, 0)
        return self.sema.type_name(payload_tid)
    var out = "("
    for pi in 0..payload_count:
        if pi > 0:
            out = out ++ ", "
        let payload_tid = self.sema.type_reflection_variant_payload_type(type_id, variant_index, pi)
        out = out ++ self.sema.type_name(payload_tid)
    out ++ ")"

fn ComptimeEvaluator.eval_type_fields_array(self: ComptimeEvaluator, type_id: i32) -> ComptimeControl:
    let layout_sema = self.sema
    let field_count = self.sema.type_reflection_field_count(type_id)
    let array_tid = self.sema.ensure_exact_type(TypeKind.TY_ARRAY, self.sema.ty_field_info as i32, field_count, 0) as i32
    let arr_start = self.extra_values.len() as i32
    let payload_start = arr_start + field_count
    let payload_values: Vec[ComptimeValue] = Vec.new()
    for fi in 0..field_count:
        let row_start = payload_start + payload_values.len() as i32
        self.extra_values.push(comptime_value_struct(self.sema.ty_field_info as i32, row_start, 5))
        let field_sym = self.sema.type_reflection_field_name(type_id, fi)
        let field_tid = self.sema.type_reflection_field_type(type_id, fi)
        payload_values.push(comptime_value_str(self.pool.resolve(field_sym)))
        payload_values.push(comptime_value_str(self.sema.type_name(field_tid)))
        payload_values.push(comptime_value_int(self.sema.ty_usize as i32, layout_sema.type_layout_struct_field_offset(type_id, fi)))
        payload_values.push(comptime_value_int(self.sema.ty_usize as i32, layout_sema.type_layout_size_of(field_tid)))
        payload_values.push(comptime_value_bool(self.sema.type_is_ephemeral_value(field_tid)))
    for pi in 0..payload_values.len() as i32:
        self.extra_values.push(payload_values.get(pi as i64))
    comptime_control_value(comptime_value_array(array_tid, arr_start, field_count))

fn ComptimeEvaluator.eval_type_variants_array(self: ComptimeEvaluator, type_id: i32) -> ComptimeControl:
    let variant_count = self.sema.type_reflection_variant_count(type_id)
    let array_tid = self.sema.ensure_exact_type(TypeKind.TY_ARRAY, self.sema.ty_variant_info as i32, variant_count, 0) as i32
    let arr_start = self.extra_values.len() as i32
    let payload_start = arr_start + variant_count
    let payload_values: Vec[ComptimeValue] = Vec.new()
    for vi in 0..variant_count:
        let row_start = payload_start + payload_values.len() as i32
        self.extra_values.push(comptime_value_struct(self.sema.ty_variant_info as i32, row_start, 4))
        let variant_sym = self.sema.type_reflection_variant_name(type_id, vi)
        let payload_count = self.sema.type_reflection_variant_payload_count(type_id, vi)
        payload_values.push(comptime_value_str(self.pool.resolve(variant_sym)))
        payload_values.push(comptime_value_int(self.sema.ty_i64 as i32, self.sema.type_reflection_variant_discriminant(type_id, vi)))
        payload_values.push(comptime_value_bool(if payload_count > 0: 1 else: 0))
        payload_values.push(comptime_value_str(self.variant_payload_name(type_id, vi)))
    for pi in 0..payload_values.len() as i32:
        self.extra_values.push(payload_values.get(pi as i64))
    comptime_control_value(comptime_value_array(array_tid, arr_start, variant_count))

fn ComptimeEvaluator.eval_static_type_method_call(self: ComptimeEvaluator, diags: &mut DiagnosticList, recv_type: i32, field: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let layout_sema = self.sema
    let method = self.pool.resolve(field)
    if method == "name":
        if arg_count != 0:
            return self.fail(diags, node, "type.name() takes no arguments")
        return comptime_control_value(comptime_value_str(self.sema.type_name(recv_type)))
    if method == "size":
        if arg_count != 0:
            return self.fail(diags, node, "type.size() takes no arguments")
        return comptime_control_value(comptime_value_int(self.sema.ty_usize as i32, layout_sema.type_layout_size_of(recv_type)))
    if method == "align":
        if arg_count != 0:
            return self.fail(diags, node, "type.align() takes no arguments")
        return comptime_control_value(comptime_value_int(self.sema.ty_usize as i32, layout_sema.type_layout_align_of(recv_type)))
    if method == "is_copy":
        if arg_count != 0:
            return self.fail(diags, node, "type.is_copy() takes no arguments")
        return comptime_control_value(comptime_value_bool(self.sema.is_copy(recv_type)))
    if method == "implements":
        if arg_count != 1:
            return self.fail(diags, node, "type.implements() expects exactly one trait argument")
        let trait_node = self.ast.get_extra(extra_start)
        if trait_node == 0:
            return self.fail(diags, node, "type.implements() requires a trait name")
        let trait_kind = self.ast.kind(trait_node)
        if trait_kind != NodeKind.NK_IDENT and trait_kind != NodeKind.NK_TYPE_NAMED:
            return self.fail(diags, trait_node, "type.implements() requires a trait name")
        let trait_sym = self.ast.get_data0(trait_node)
        if not self.sema.lang_trait_syms.contains(trait_sym) and not self.sema.trait_lookup.contains(trait_sym):
            return self.fail(diags, trait_node, "unknown trait '" ++ self.pool.resolve(trait_sym) ++ "'")
        return comptime_control_value(comptime_value_bool(self.sema.type_implements_trait(recv_type, trait_sym)))
    if method == "fields":
        if arg_count != 0:
            return self.fail(diags, node, "type.fields() takes no arguments")
        let resolved = self.sema.resolve_alias(recv_type)
        let tk = self.sema.get_type_kind(resolved)
        if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_GENERIC_INST:
            return self.fail(diags, node, "type.fields() requires a struct type")
        return self.eval_type_fields_array(recv_type)
    if method == "variants":
        if arg_count != 0:
            return self.fail(diags, node, "type.variants() takes no arguments")
        if self.sema.type_reflection_variant_base(recv_type) == 0:
            return self.fail(diags, node, "type.variants() requires an enum type")
        return self.eval_type_variants_array(recv_type)
    self.fail(diags, node, "method is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_module_let_decl(self: ComptimeEvaluator, diags: &mut DiagnosticList, decl: i32, use_node: i32) -> ComptimeControl:
    let sym = self.ast.get_data0(decl)
    for i in 0..self.active_global_syms.len() as i32:
        if self.active_global_syms.get(i as i64) == sym:
            return self.fail(diags, use_node, "cyclic comptime constant dependency")
    let value_node = self.ast.get_data1(decl)
    if value_node == 0:
        return self.fail(diags, use_node, "missing constant value")

    let saved_file = self.sema.local_file_id
    self.sema.local_file_id = self.decl_file_id(decl)
    self.active_global_syms.push(sym)
    let result = self.eval_expr(diags, value_node)
    self.active_global_syms.pop()
    self.sema.local_file_id = saved_file
    result

fn ComptimeEvaluator.eval_array(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let extra_start = self.ast.get_data0(node)
    let count = self.ast.get_data1(node)
    let start = self.extra_values.len() as i32
    for i in 0..count:
        let elem_signal = self.eval_expr(diags, self.ast.get_extra(extra_start + i))
        if elem_signal.kind != ComptimeControlKind.CTL_VALUE:
            return elem_signal
        self.push_extra_value(elem_signal.value)
    comptime_control_value(comptime_value_array(self.node_type_or(node, 0), start, count))

fn ComptimeEvaluator.eval_tuple(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let extra_start = self.ast.get_data0(node)
    let count = self.ast.get_data1(node)
    let start = self.extra_values.len() as i32
    for i in 0..count:
        let elem_signal = self.eval_expr(diags, self.ast.get_extra(extra_start + i))
        if elem_signal.kind != ComptimeControlKind.CTL_VALUE:
            return elem_signal
        self.push_extra_value(elem_signal.value)
    comptime_control_value(comptime_value_tuple(self.node_type_or(node, 0), start, count))

fn ComptimeEvaluator.eval_range(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let start_node = self.ast.get_data0(node)
    let end_node = self.ast.get_data1(node)
    let inclusive = self.ast.get_data2(node)
    if start_node == 0 or end_node == 0:
        return self.fail(diags, node, "open-ended ranges are not supported in comptime")
    let start_signal = self.eval_expr(diags, start_node)
    if start_signal.kind != ComptimeControlKind.CTL_VALUE:
        return start_signal
    let end_signal = self.eval_expr(diags, end_node)
    if end_signal.kind != ComptimeControlKind.CTL_VALUE:
        return end_signal
    if comptime_value_is_intlike(start_signal.value) == 0 or comptime_value_is_intlike(end_signal.value) == 0:
        return self.fail(diags, node, "range bounds must be integers in comptime")
    comptime_control_value(
        comptime_value_range(
            self.node_type_or(node, 0),
            comptime_value_intlike(start_signal.value),
            comptime_value_intlike(end_signal.value),
            inclusive
        )
    )

fn ComptimeEvaluator.eval_disc_variant_sym(self: ComptimeEvaluator, diags: &mut DiagnosticList, sym: i32, node: i32) -> ComptimeControl:
    if not self.sema.variant_lookup.contains(sym):
        return self.unsupported(diags, node)
    let enum_tid = self.sema.variant_type_ids.get(sym).unwrap()
    let enum_resolved = self.sema.resolve_alias(enum_tid as TypeId)
    if not self.sema.disc_repr_types.contains(enum_resolved) or self.sema.disc_has_payload.contains(enum_resolved):
        return self.unsupported(diags, node)
    let disc = if self.sema.disc_values.contains(sym): self.sema.disc_values.get(sym).unwrap() else: self.sema.variant_lookup.get(sym).unwrap()
    let repr_ty = self.sema.disc_repr_types.get(enum_resolved).unwrap()
    comptime_control_value(comptime_value_int(self.node_type_or(node, repr_ty), disc as i64))

fn ComptimeEvaluator.eval_ident(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let sym = self.ast.get_data0(node)
    let idx = self.lookup_slot_index(sym)
    if idx >= 0:
        return comptime_control_value(self.slot_values.get(idx as i64))
    let decl = self.find_module_let_decl(sym)
    if decl != 0:
        if self.ast.get_data2(decl) % 2 != 0:
            return self.fail(diags, node, "mutable global access is not allowed in comptime")
        return self.eval_module_let_decl(diags, decl, node)
    if self.sema.variant_lookup.contains(sym):
        return self.eval_disc_variant_sym(diags, sym, node)
    self.fail(diags, node, "runtime value is not available at comptime")

fn ComptimeEvaluator.eval_field_access(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let base = self.ast.get_data0(node)
    let field = self.ast.get_data1(node)
    if self.ast.kind(base) == NodeKind.NK_IDENT:
        let base_sym = self.ast.get_data0(base)
        if self.sema.named_types.contains(base_sym):
            let base_tid = self.sema.named_types.get(base_sym).unwrap()
            let base_resolved = self.sema.resolve_alias(base_tid as TypeId)
            if self.sema.get_type_kind(base_resolved) == TypeKind.TY_ENUM and self.sema.enum_has_variant(base_resolved as i32, field) != 0:
                let qual_name = self.pool.resolve(base_sym) ++ "." ++ self.pool.resolve(field)
                let qual_sym = self.pool.intern(qual_name)
                if self.sema.variant_lookup.contains(qual_sym):
                    return self.eval_disc_variant_sym(diags, qual_sym, node)
                return self.eval_disc_variant_sym(diags, field, node)
    let base_signal = self.eval_expr(diags, base)
    if base_signal.kind != ComptimeControlKind.CTL_VALUE:
        return base_signal
    if base_signal.value.kind == ComptimeValueKind.CV_STRUCT:
        let field_index = self.struct_field_index(base_signal.value.type_id, field)
        if field_index < 0:
            return self.fail(diags, node, "unknown comptime struct field")
        return comptime_control_value(self.extra_values.get((base_signal.value.extra_start + field_index) as i64))
    self.unsupported(diags, node)

fn ComptimeEvaluator.eval_unary(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let inner = self.eval_expr(diags, self.ast.get_data1(node))
    if inner.kind != ComptimeControlKind.CTL_VALUE:
        return inner
    let op = self.ast.get_data0(node)
    let result_ty = self.node_type_or(node, inner.value.type_id)
    if op == UnaryOp.UOP_NEGATE:
        if comptime_value_is_intlike(inner.value) == 0:
            return self.fail(diags, node, "unary '-' requires integer comptime values")
        return comptime_control_value(comptime_value_int(result_ty, 0 - comptime_value_intlike(inner.value)))
    if op == UnaryOp.UOP_BIT_NOT:
        if comptime_value_is_intlike(inner.value) == 0:
            return self.fail(diags, node, "bitwise not requires integer comptime values")
        return comptime_control_value(comptime_value_int(result_ty, 0 - comptime_value_intlike(inner.value) - 1))
    if op == UnaryOp.UOP_NOT:
        let truthy = comptime_value_truthy(inner.value)
        if truthy < 0:
            return self.fail(diags, node, "logical not requires bool or integer comptime values")
        return comptime_control_value(comptime_value_bool(if truthy == 0: 1 else: 0))
    self.unsupported(diags, node)

fn ComptimeEvaluator.eval_binary_compare(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32, op: i32, lhs: ComptimeValue, rhs: ComptimeValue) -> ComptimeControl:
    if comptime_value_is_intlike(lhs) != 0 and comptime_value_is_intlike(rhs) != 0:
        let lv = comptime_value_intlike(lhs)
        let rv = comptime_value_intlike(rhs)
        if op == BinaryOp.OP_EQ: return comptime_control_value(comptime_value_bool(if lv == rv: 1 else: 0))
        if op == BinaryOp.OP_NEQ: return comptime_control_value(comptime_value_bool(if lv != rv: 1 else: 0))
        if op == BinaryOp.OP_LT: return comptime_control_value(comptime_value_bool(if lv < rv: 1 else: 0))
        if op == BinaryOp.OP_GT: return comptime_control_value(comptime_value_bool(if lv > rv: 1 else: 0))
        if op == BinaryOp.OP_LTE: return comptime_control_value(comptime_value_bool(if lv <= rv: 1 else: 0))
        if op == BinaryOp.OP_GTE: return comptime_control_value(comptime_value_bool(if lv >= rv: 1 else: 0))
    if lhs.kind == ComptimeValueKind.CV_STR and rhs.kind == ComptimeValueKind.CV_STR:
        if op == BinaryOp.OP_EQ:
            return comptime_control_value(comptime_value_bool(comptime_values_equal(lhs, rhs, self.extra_values)))
        if op == BinaryOp.OP_NEQ:
            return comptime_control_value(comptime_value_bool(if comptime_values_equal(lhs, rhs, self.extra_values) != 0: 0 else: 1))
    if lhs.kind == ComptimeValueKind.CV_BOOL and rhs.kind == ComptimeValueKind.CV_BOOL:
        let lv = lhs.data0
        let rv = rhs.data0
        if op == BinaryOp.OP_EQ: return comptime_control_value(comptime_value_bool(if lv == rv: 1 else: 0))
        if op == BinaryOp.OP_NEQ: return comptime_control_value(comptime_value_bool(if lv != rv: 1 else: 0))
    self.fail(diags, node, "comparison requires comptime scalar values")

fn ComptimeEvaluator.eval_binary_membership(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32, lhs: ComptimeValue, rhs: ComptimeValue, negate: i32) -> ComptimeControl:
    var matched = 0
    if rhs.kind == ComptimeValueKind.CV_ARRAY or rhs.kind == ComptimeValueKind.CV_TUPLE:
        for i in 0..rhs.extra_count:
            let item = self.extra_values.get((rhs.extra_start + i) as i64)
            if comptime_values_equal(lhs, item, self.extra_values) != 0:
                matched = 1
                break
    else if rhs.kind == ComptimeValueKind.CV_RANGE and comptime_value_is_intlike(lhs) != 0:
        let value = comptime_value_intlike(lhs)
        if rhs.extra_start != 0:
            matched = if value >= rhs.data0 and value <= rhs.data1: 1 else: 0
        else:
            matched = if value >= rhs.data0 and value < rhs.data1: 1 else: 0
    else:
        return self.fail(diags, node, "'in' requires an array, tuple, or range in comptime")
    if negate != 0:
        matched = if matched != 0: 0 else: 1
    comptime_control_value(comptime_value_bool(matched))

fn ComptimeEvaluator.eval_binary(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let op = self.ast.get_data0(node)
    if op == BinaryOp.OP_AND or op == BinaryOp.OP_OR:
        let lhs_signal = self.eval_expr(diags, self.ast.get_data1(node))
        if lhs_signal.kind != ComptimeControlKind.CTL_VALUE:
            return lhs_signal
        let lhs_truthy = comptime_value_truthy(lhs_signal.value)
        if lhs_truthy < 0:
            return self.fail(diags, node, "logical operators require bool or integer comptime values")
        if op == BinaryOp.OP_AND and lhs_truthy == 0:
            return comptime_control_value(comptime_value_bool(0))
        if op == BinaryOp.OP_OR and lhs_truthy != 0:
            return comptime_control_value(comptime_value_bool(1))
        let rhs_signal = self.eval_expr(diags, self.ast.get_data2(node))
        if rhs_signal.kind != ComptimeControlKind.CTL_VALUE:
            return rhs_signal
        let rhs_truthy = comptime_value_truthy(rhs_signal.value)
        if rhs_truthy < 0:
            return self.fail(diags, node, "logical operators require bool or integer comptime values")
        return comptime_control_value(comptime_value_bool(rhs_truthy))

    let lhs_signal = self.eval_expr(diags, self.ast.get_data1(node))
    if lhs_signal.kind != ComptimeControlKind.CTL_VALUE:
        return lhs_signal
    let rhs_signal = self.eval_expr(diags, self.ast.get_data2(node))
    if rhs_signal.kind != ComptimeControlKind.CTL_VALUE:
        return rhs_signal
    let lhs = lhs_signal.value
    let rhs = rhs_signal.value

    if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE:
        return self.eval_binary_compare(diags, node, op, lhs, rhs)
    if op == BinaryOp.OP_IN:
        return self.eval_binary_membership(diags, node, lhs, rhs, 0)
    if op == BinaryOp.OP_NOT_IN:
        return self.eval_binary_membership(diags, node, lhs, rhs, 1)
    if op == BinaryOp.OP_CONCAT or (op == BinaryOp.OP_ADD and lhs.kind == ComptimeValueKind.CV_STR and rhs.kind == ComptimeValueKind.CV_STR):
        if lhs.kind != ComptimeValueKind.CV_STR or rhs.kind != ComptimeValueKind.CV_STR:
            return self.fail(diags, node, "string concatenation requires comptime strings")
        return comptime_control_value(comptime_value_str(lhs.text ++ rhs.text))

    if comptime_value_is_intlike(lhs) == 0 or comptime_value_is_intlike(rhs) == 0:
        return self.fail(diags, node, "operator requires integer comptime values")
    let lv = comptime_value_intlike(lhs)
    let rv = comptime_value_intlike(rhs)
    let result_ty = self.node_type_or(node, if lhs.type_id != 0: lhs.type_id else: rhs.type_id)
    if op == BinaryOp.OP_ADD or op == BinaryOp.OP_ADD_WRAP:
        return comptime_control_value(comptime_value_int(result_ty, lv + rv))
    if op == BinaryOp.OP_SUB or op == BinaryOp.OP_SUB_WRAP:
        return comptime_control_value(comptime_value_int(result_ty, lv - rv))
    if op == BinaryOp.OP_MUL or op == BinaryOp.OP_MUL_WRAP:
        return comptime_control_value(comptime_value_int(result_ty, lv * rv))
    if op == BinaryOp.OP_DIV:
        if rv == 0:
            return self.fail(diags, node, "division by zero in comptime")
        return comptime_control_value(comptime_value_int(result_ty, lv / rv))
    if op == BinaryOp.OP_MOD:
        if rv == 0:
            return self.fail(diags, node, "modulo by zero in comptime")
        return comptime_control_value(comptime_value_int(result_ty, lv % rv))
    if op == BinaryOp.OP_SHL:
        return comptime_control_value(comptime_value_int(result_ty, lv << rv))
    if op == BinaryOp.OP_SHR:
        return comptime_control_value(comptime_value_int(result_ty, lv >> rv))
    if op == BinaryOp.OP_BIT_AND:
        return comptime_control_value(comptime_value_int(result_ty, lv & rv))
    if op == BinaryOp.OP_BIT_OR:
        return comptime_control_value(comptime_value_int(result_ty, lv | rv))
    if op == BinaryOp.OP_BIT_XOR:
        return comptime_control_value(comptime_value_int(result_ty, lv ^ rv))
    self.unsupported(diags, node)

fn ComptimeEvaluator.eval_let_binding(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let value_signal = self.eval_expr(diags, self.ast.get_data1(node))
    if value_signal.kind != ComptimeControlKind.CTL_VALUE:
        return value_signal
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2
    self.bind_value(self.ast.get_data0(node), value_signal.value, is_mut)
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.eval_assign(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let target = self.ast.get_data0(node)
    if self.ast.kind(target) != NodeKind.NK_IDENT:
        return self.fail(diags, node, "comptime assignment only supports local identifiers")
    let value_signal = self.eval_expr(diags, self.ast.get_data1(node))
    if value_signal.kind != ComptimeControlKind.CTL_VALUE:
        return value_signal
    self.assign_value(diags, self.ast.get_data0(target), value_signal.value, node)

fn ComptimeEvaluator.eval_if(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let cond_signal = self.eval_expr(diags, self.ast.get_data0(node))
    if cond_signal.kind != ComptimeControlKind.CTL_VALUE:
        return cond_signal
    let truthy = comptime_value_truthy(cond_signal.value)
    if truthy < 0:
        return self.fail(diags, node, "comptime if requires a bool or integer condition")
    if truthy != 0:
        return self.eval_expr(diags, self.ast.get_data1(node))
    let else_node = self.ast.get_data2(node)
    if else_node != 0:
        return self.eval_expr(diags, else_node)
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.match_pattern(self: ComptimeEvaluator, diags: &mut DiagnosticList, pat: i32, value: ComptimeValue, node: i32) -> i32:
    if pat == 0:
        return 1
    let kind = self.ast.kind(pat)
    if kind == NodeKind.NK_PAT_WILDCARD:
        return 1
    if kind == NodeKind.NK_PAT_IDENT:
        self.bind_value(self.ast.get_data0(pat), value, 0)
        return 1
    if kind == NodeKind.NK_PAT_TYPED_BIND:
        self.bind_value(self.ast.get_data0(pat), value, 0)
        return 1
    if kind == NodeKind.NK_PAT_INT:
        if comptime_value_is_intlike(value) == 0:
            return 0
        if comptime_value_intlike(value) == ast_int_from_parts(self.ast.get_data0(pat), self.ast.get_data1(pat), 0):
            return 1
        return 0
    if kind == NodeKind.NK_PAT_BOOL:
        if value.kind != ComptimeValueKind.CV_BOOL:
            return 0
        if value.data0 == self.ast.get_data0(pat) as i64:
            return 1
        return 0
    if kind == NodeKind.NK_PAT_STRING:
        if value.kind != ComptimeValueKind.CV_STR:
            return 0
        if value.text == self.pool.resolve(self.ast.get_data0(pat)):
            return 1
        return 0
    if kind == NodeKind.NK_PAT_RANGE:
        if comptime_value_is_intlike(value) == 0:
            return 0
        let v = comptime_value_intlike(value)
        let start_value = self.ast.get_data0(pat) as i64
        let end_value = self.ast.get_data1(pat) as i64
        if self.ast.get_data2(pat) != 0:
            return if v >= start_value and v <= end_value: 1 else: 0
        return if v >= start_value and v < end_value: 1 else: 0
    if kind == NodeKind.NK_PAT_AT_BINDING:
        self.bind_value(self.ast.get_data0(pat), value, 0)
        return self.match_pattern(diags, self.ast.get_data1(pat), value, node)
    if kind == NodeKind.NK_PAT_OR:
        let start = self.slot_syms.len() as i32
        let extra_start = self.ast.get_data0(pat)
        let count = self.ast.get_data1(pat)
        for i in 0..count:
            while self.slot_syms.len() as i32 > start:
                self.slot_syms.pop()
                self.slot_values.pop()
                self.slot_muts.pop()
            if self.match_pattern(diags, self.ast.get_extra(extra_start + i), value, node) != 0:
                return 1
        while self.slot_syms.len() as i32 > start:
            self.slot_syms.pop()
            self.slot_values.pop()
            self.slot_muts.pop()
        return 0
    if kind == NodeKind.NK_PAT_TUPLE:
        if value.kind != ComptimeValueKind.CV_TUPLE:
            return 0
        let count = self.ast.get_data1(pat)
        if value.extra_count != count:
            return 0
        let extra_start = self.ast.get_data0(pat)
        for i in 0..count:
            let elem_pat = self.ast.get_extra(extra_start + i)
            let elem_value = self.extra_values.get((value.extra_start + i) as i64)
            if self.match_pattern(diags, elem_pat, elem_value, node) == 0:
                return 0
        return 1
    if self.require_success != 0:
        let _ = self.fail(diags, pat, "pattern is not comptime-evaluable yet")
    0

fn ComptimeEvaluator.eval_match(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let subject_signal = self.eval_expr(diags, self.ast.get_data0(node))
    if subject_signal.kind != ComptimeControlKind.CTL_VALUE:
        return subject_signal
    let extra_start = self.ast.get_data1(node)
    let arm_count = self.ast.get_data2(node)
    for i in 0..arm_count:
        let arm = self.ast.get_extra(extra_start + i)
        self.push_scope()
        let pat = self.ast.get_data0(arm)
        if self.match_pattern(diags, pat, subject_signal.value, arm) != 0:
            let guard = self.ast.get_data2(arm)
            var guard_ok = 1
            if guard != 0:
                let guard_signal = self.eval_expr(diags, guard)
                if guard_signal.kind != ComptimeControlKind.CTL_VALUE:
                    self.pop_scope()
                    return guard_signal
                let truthy = comptime_value_truthy(guard_signal.value)
                if truthy < 0:
                    self.pop_scope()
                    return self.fail(diags, guard, "match guard must be bool or integer in comptime")
                guard_ok = truthy
            if guard_ok != 0:
                let body_signal = self.eval_expr(diags, self.ast.get_data1(arm))
                self.pop_scope()
                return body_signal
        self.pop_scope()
    self.fail(diags, node, "no comptime match arm matched")

fn ComptimeEvaluator.signal_matches_loop(self: ComptimeEvaluator, signal: ComptimeControl, loop_label: i32) -> i32:
    if signal.kind != ComptimeControlKind.CTL_BREAK and signal.kind != ComptimeControlKind.CTL_CONTINUE:
        return 0
    if signal.label == 0:
        return 1
    if signal.label == loop_label:
        return 1
    0

fn ComptimeEvaluator.eval_loop(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let loop_label = self.ast.get_data1(node)
    self.loop_labels.push(loop_label)
    while true:
        let body_signal = self.eval_expr(diags, self.ast.get_data0(node))
        if body_signal.kind == ComptimeControlKind.CTL_VALUE:
            continue
        if self.signal_matches_loop(body_signal, loop_label) != 0:
            if body_signal.kind == ComptimeControlKind.CTL_CONTINUE:
                continue
            self.loop_labels.pop()
            return comptime_control_value(body_signal.value)
        self.loop_labels.pop()
        return body_signal
    comptime_control_error()

fn ComptimeEvaluator.eval_while(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let loop_label = self.ast.get_data2(node)
    self.loop_labels.push(loop_label)
    while true:
        let cond_signal = self.eval_expr(diags, self.ast.get_data0(node))
        if cond_signal.kind != ComptimeControlKind.CTL_VALUE:
            self.loop_labels.pop()
            return cond_signal
        let truthy = comptime_value_truthy(cond_signal.value)
        if truthy < 0:
            self.loop_labels.pop()
            return self.fail(diags, node, "while condition must be bool or integer in comptime")
        if truthy == 0:
            self.loop_labels.pop()
            return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
        let body_signal = self.eval_expr(diags, self.ast.get_data1(node))
        if body_signal.kind == ComptimeControlKind.CTL_VALUE:
            continue
        if self.signal_matches_loop(body_signal, loop_label) != 0:
            if body_signal.kind == ComptimeControlKind.CTL_CONTINUE:
                continue
            self.loop_labels.pop()
            return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
        self.loop_labels.pop()
        return body_signal
    comptime_control_error()

fn ComptimeEvaluator.eval_for(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let iterable_signal = self.eval_expr(diags, self.ast.get_data1(node))
    if iterable_signal.kind != ComptimeControlKind.CTL_VALUE:
        return iterable_signal
    let binding = self.ast.get_data0(node)
    let body = self.ast.get_data2(node)
    var count = 0
    if iterable_signal.value.kind == ComptimeValueKind.CV_ARRAY or iterable_signal.value.kind == ComptimeValueKind.CV_TUPLE:
        count = iterable_signal.value.extra_count
    else if iterable_signal.value.kind == ComptimeValueKind.CV_RANGE:
        let start_value = iterable_signal.value.data0
        let end_value = iterable_signal.value.data1
        count = if iterable_signal.value.extra_start != 0: (end_value - start_value + 1) as i32 else: (end_value - start_value) as i32
        if count < 0:
            count = 0
    else:
        return self.fail(diags, node, "comptime for requires an array, tuple, or range")

    let for_meta = self.ast.find_for_meta(node)
    let index_binding = if for_meta >= 0: self.ast.for_meta_index_binding(for_meta) else: 0
    let loop_label = if for_meta >= 0: self.ast.for_meta_label(for_meta) else: 0
    self.loop_labels.push(loop_label)
    for i in 0..count:
        self.push_scope()
        if iterable_signal.value.kind == ComptimeValueKind.CV_RANGE:
            let step_value = iterable_signal.value.data0 + i as i64
            self.bind_value(binding, comptime_value_int(self.sema.ty_i64 as i32, step_value), 0)
        else:
            let elem = self.extra_values.get((iterable_signal.value.extra_start + i) as i64)
            self.bind_value(binding, elem, 0)
        if index_binding != 0:
            self.bind_value(index_binding, comptime_value_int(self.sema.ty_i64 as i32, i as i64), 0)
        let body_signal = self.eval_expr(diags, body)
        self.pop_scope()
        if body_signal.kind == ComptimeControlKind.CTL_VALUE:
            continue
        if self.signal_matches_loop(body_signal, loop_label) != 0:
            if body_signal.kind == ComptimeControlKind.CTL_CONTINUE:
                continue
            self.loop_labels.pop()
            return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
        self.loop_labels.pop()
        return body_signal
    self.loop_labels.pop()
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.eval_call(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let callee = self.ast.get_data0(node)
    if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
        let recv_node = self.ast.get_data0(callee)
        if self.sema.static_receiver_type_is_known(recv_node) != 0:
            let recv_type = self.static_receiver_type(recv_node)
            if recv_type != 0:
                return self.eval_static_type_method_call(diags, recv_type, self.ast.get_data1(callee), self.ast.get_data1(node), self.ast.get_data2(node), node)
        return self.fail(diags, node, "only type reflection method calls are comptime-evaluable yet")
    if self.ast.kind(callee) != NodeKind.NK_IDENT:
        return self.fail(diags, node, "only direct comptime function calls are supported")
    let fn_sym = self.ast.get_data0(callee)
    if self.sema.fn_symbol_is_comptime(fn_sym) == 0:
        return self.fail(diags, node, "comptime can only call comptime functions")
    if self.sema.generic_fn_nodes.contains(fn_sym):
        return self.fail(diags, node, "generic comptime functions are not supported yet")
    if not self.sema.fn_decl_nodes.contains(fn_sym):
        return self.fail(diags, node, "callee is not a comptime function body")
    if self.active_fn_syms.len() as i32 >= self.recursion_limit:
        return self.fail(diags, node, "comptime recursion limit exceeded")

    let extra_start = self.ast.get_data1(node)
    let arg_count = self.ast.get_data2(node)
    let fn_node = self.sema.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return self.fail(diags, node, "missing comptime function metadata")
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    if arg_count > param_count:
        return self.fail(diags, node, "wrong argument count in comptime call")

    let arg_values: Vec[ComptimeValue] = Vec.new()
    for i in 0..arg_count:
        let arg_signal = self.eval_expr(diags, self.ast.get_extra(extra_start + i))
        if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
            return arg_signal
        arg_values.push(arg_signal.value)

    let saved_file = self.sema.local_file_id
    self.sema.local_file_id = self.decl_file_id(fn_node)
    self.active_fn_syms.push(fn_sym)
    self.push_scope()

    for i in 0..param_count:
        let param_name = self.ast.fn_param_name(param_start, i)
        if i < arg_count:
            self.bind_value(param_name, arg_values.get(i as i64), 0)
        else:
            let default_node = self.ast.get_fn_param_default(param_start, i)
            if default_node == 0:
                self.pop_scope()
                self.active_fn_syms.pop()
                self.sema.local_file_id = saved_file
                return self.fail(diags, node, "wrong argument count in comptime call")
            let default_signal = self.eval_expr(diags, default_node)
            if default_signal.kind != ComptimeControlKind.CTL_VALUE:
                self.pop_scope()
                self.active_fn_syms.pop()
                self.sema.local_file_id = saved_file
                return default_signal
            self.bind_value(param_name, default_signal.value, 0)

    let pmeta = self.ast.find_fn_param_pattern_meta(fn_node)
    if pmeta >= 0:
        let ppat_start = self.ast.fn_param_pattern_meta_start(pmeta)
        let ppat_count = self.ast.fn_param_pattern_meta_count(pmeta)
        let apply_count = if ppat_count < param_count: ppat_count else: param_count
        for i in 0..apply_count:
            let ppat = self.ast.fn_param_pattern_value(ppat_start + i)
            if ppat != 0:
                let param_name = self.ast.fn_param_name(param_start, i)
                let param_idx = self.lookup_slot_index(param_name)
                if param_idx >= 0:
                    let param_value = self.slot_values.get(param_idx as i64)
                    if self.match_pattern(diags, ppat, param_value, ppat) == 0:
                        self.pop_scope()
                        self.active_fn_syms.pop()
                        self.sema.local_file_id = saved_file
                        return self.fail(diags, ppat, "comptime argument did not match parameter pattern")

    let body_signal = self.eval_expr(diags, self.ast.get_data1(fn_node))
    self.pop_scope()
    self.active_fn_syms.pop()
    self.sema.local_file_id = saved_file
    if body_signal.kind == ComptimeControlKind.CTL_RETURN:
        return comptime_control_value(body_signal.value)
    if body_signal.kind == ComptimeControlKind.CTL_BREAK or body_signal.kind == ComptimeControlKind.CTL_CONTINUE:
        return self.fail(diags, fn_node, "loop control escaped comptime function")
    body_signal

fn ComptimeEvaluator.eval_return(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let value_node = self.ast.get_data0(node)
    if value_node == 0:
        return comptime_control_return(comptime_value_void(self.sema.ty_void as i32))
    let value_signal = self.eval_expr(diags, value_node)
    if value_signal.kind != ComptimeControlKind.CTL_VALUE:
        return value_signal
    comptime_control_return(value_signal.value)

fn ComptimeEvaluator.eval_break(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let value_node = self.ast.get_data0(node)
    var value = comptime_value_void(self.sema.ty_void as i32)
    if value_node != 0:
        let value_signal = self.eval_expr(diags, value_node)
        if value_signal.kind != ComptimeControlKind.CTL_VALUE:
            return value_signal
        value = value_signal.value
    comptime_control_break(value, self.ast.get_data1(node))

fn ComptimeEvaluator.eval_continue(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    comptime_control_continue(self.ast.get_data0(node))

fn ComptimeEvaluator.eval_block(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let extra_start = self.ast.get_data0(node)
    let stmt_count = self.ast.get_data1(node)
    let tail = self.ast.get_data2(node)
    self.push_scope()
    for i in 0..stmt_count:
        let stmt_signal = self.eval_expr(diags, self.ast.get_extra(extra_start + i))
        if stmt_signal.kind != ComptimeControlKind.CTL_VALUE:
            self.pop_scope()
            return stmt_signal
    if tail != 0:
        let tail_signal = self.eval_expr(diags, tail)
        self.pop_scope()
        return tail_signal
    self.pop_scope()
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.eval_comptime_error(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    let msg_sym = self.ast.get_data0(node)
    self.fail(diags, node, self.pool.resolve(msg_sym))

fn ComptimeEvaluator.eval_expr(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    if node == 0:
        return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
    if self.step(diags, node) == 0:
        return comptime_control_error()

    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_INT_LIT:
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), self.ast.int_lit_value(node)))
    if kind == NodeKind.NK_BOOL_LIT:
        return comptime_control_value(comptime_value_bool(self.ast.get_data0(node)))
    if kind == NodeKind.NK_STRING_LIT:
        return comptime_control_value(comptime_value_str(self.pool.resolve(self.ast.get_data0(node))))
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_COMPTIME:
        return self.eval_expr(diags, self.ast.get_data0(node))
    if kind == NodeKind.NK_IDENT:
        return self.eval_ident(diags, node)
    if kind == NodeKind.NK_FIELD_ACCESS:
        return self.eval_field_access(diags, node)
    if kind == NodeKind.NK_UNARY:
        return self.eval_unary(diags, node)
    if kind == NodeKind.NK_BINARY:
        return self.eval_binary(diags, node)
    if kind == NodeKind.NK_BLOCK:
        return self.eval_block(diags, node)
    if kind == NodeKind.NK_LET_BINDING:
        return self.eval_let_binding(diags, node)
    if kind == NodeKind.NK_ASSIGN:
        return self.eval_assign(diags, node)
    if kind == NodeKind.NK_IF_EXPR:
        return self.eval_if(diags, node)
    if kind == NodeKind.NK_MATCH:
        return self.eval_match(diags, node)
    if kind == NodeKind.NK_FOR:
        return self.eval_for(diags, node)
    if kind == NodeKind.NK_WHILE:
        return self.eval_while(diags, node)
    if kind == NodeKind.NK_LOOP:
        return self.eval_loop(diags, node)
    if kind == NodeKind.NK_CALL:
        return self.eval_call(diags, node)
    if kind == NodeKind.NK_RETURN:
        return self.eval_return(diags, node)
    if kind == NodeKind.NK_BREAK:
        return self.eval_break(diags, node)
    if kind == NodeKind.NK_CONTINUE:
        return self.eval_continue(node)
    if kind == NodeKind.NK_ARRAY_LIT:
        return self.eval_array(diags, node)
    if kind == NodeKind.NK_TUPLE:
        return self.eval_tuple(diags, node)
    if kind == NodeKind.NK_RANGE:
        return self.eval_range(diags, node)
    if kind == NodeKind.NK_COMPTIME_ERROR:
        return self.eval_comptime_error(diags, node)
    self.unsupported(diags, node)

fn Sema.force_eval_comptime_expr(self: &mut Sema, node: i32) -> i32:
    let value = comptime_force_eval_expr(self as *mut Sema, &mut self.diags, self.ast, self.pool, node)
    comptime_value_is_valid(value)

fn Sema.check_top_level_comptime_let_values(self: &mut Sema):
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        let value = self.ast.get_data1(decl)
        if value == 0 or self.ast.kind(value) != NodeKind.NK_COMPTIME:
            continue

        let flags = self.ast.get_data2(decl)
        let ann_extra = self.top_level_let_type_ann_extra(flags)
        let ann_type = if ann_extra >= 0: self.resolve_type_expr(self.ast.get_extra(ann_extra)) else: (0) as TypeId
        let val_type = if ann_type != 0: self.check_expr_with_expected(value, ann_type) else: self.check_expr(value)
        if ann_type != 0 and val_type != 0:
            if self.types_compatible(ann_type as i32, val_type as i32) == 0:
                if self.arithmetic_result_type(ann_type, val_type) == 0:
                    self.emit_error("type mismatch in binding", decl)
        if val_type != 0 and ann_type == 0:
            self.typed_binding_types.insert(decl as i32, val_type as i32)
        let _ = self.force_eval_comptime_expr(value)
