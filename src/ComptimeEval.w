use ComptimeValue
use Sema
use Ast
use Span
use Diagnostic
use InternPool
use TypeLayout

extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_file_exists(path: str) -> i32

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
    last_error_msg: str,
}

type ComptimeEvalResult {
    value: ComptimeValue,
    extras: Vec[ComptimeValue],
    error_msg: str,
}

type ComptimeSourceLoc {
    line: i32,
    col: i32,
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
        last_error_msg: "",
    }

fn comptime_dirname(path: str) -> str:
    var last_slash = 0 - 1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return ""
    path.slice(0, last_slash as i64)

fn comptime_resolve_embed_file_path(source_path: str, raw_path: str) -> str:
    if raw_path.len() > 0 and raw_path.byte_at(0) == 47:
        return raw_path
    let dir = comptime_dirname(source_path)
    if dir.len() == 0:
        return raw_path
    dir ++ "/" ++ raw_path

fn comptime_source_loc(text: str, offset: i32) -> ComptimeSourceLoc:
    var line = 1
    var col = 1
    var i = 0
    while i < offset and i < text.len() as i32:
        if text.byte_at(i as i64) == 10:
            line = line + 1
            col = 1
        else:
            col = col + 1
        i = i + 1
    ComptimeSourceLoc { line: line, col: col }

fn comptime_type_name_has_base(type_name: str, base_name: str) -> i32:
    if type_name == base_name:
        return 1
    if type_name.len() <= base_name.len():
        return 0
    if type_name.slice(0, base_name.len()) != base_name:
        return 0
    if type_name.byte_at(base_name.len() as i64) == 91:
        return 1
    0

fn comptime_eval_result_invalid() -> ComptimeEvalResult:
    ComptimeEvalResult {
        value: comptime_value_invalid(),
        extras: Vec.new(),
        error_msg: "",
    }

fn comptime_try_eval_expr_result(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ast: AstPool, pool: InternPool, node: i32) -> ComptimeEvalResult:
    var sema = unsafe: *sema_ptr
    sema.ast = ast
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 0)
    let value = evaluator.eval_root(diags, node)
    ComptimeEvalResult {
        value,
        extras: evaluator.extra_values,
        error_msg: evaluator.last_error_msg,
    }

fn comptime_force_eval_expr_result(sema_ptr: *mut Sema, diags: &mut DiagnosticList, ast: AstPool, pool: InternPool, node: i32) -> ComptimeEvalResult:
    var sema = unsafe: *sema_ptr
    sema.ast = ast
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 1)
    let value = evaluator.eval_root(diags, node)
    ComptimeEvalResult {
        value,
        extras: evaluator.extra_values,
        error_msg: evaluator.last_error_msg,
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
    self.last_error_msg = msg
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

fn ComptimeEvaluator.decl_path(self: ComptimeEvaluator, decl_node: i32) -> str:
    let decl_idx = self.find_decl_index(decl_node)
    if decl_idx >= 0 and decl_idx < self.sema.decl_source_paths.len() as i32:
        let path = self.sema.decl_source_paths.get(decl_idx as i64)
        if path.len() > 0:
            return path
    if self.sema.current_module_path.len() > 0:
        return self.sema.current_module_path
    ""

fn ComptimeEvaluator.current_source_path(self: ComptimeEvaluator) -> str:
    if self.sema.current_module_path.len() > 0:
        return self.sema.current_module_path
    "<unknown>"

fn ComptimeEvaluator.current_source_text(self: ComptimeEvaluator) -> str:
    let path = self.current_source_path()
    if path != "<unknown>":
        let text = with_fs_read_file(path)
        if text.len() > 0 or with_fs_file_exists(path) != 0:
            return text
    self.sema.source_text

fn ComptimeEvaluator.push_extra_value(self: ComptimeEvaluator, value: ComptimeValue):
    self.extra_values.push(value)

fn ComptimeEvaluator.binding_sym(self: ComptimeEvaluator, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        return self.ast.get_data0(node)
    if kind == NodeKind.NK_GROUPED:
        return self.binding_sym(self.ast.get_data0(node))
    0

fn ComptimeEvaluator.copy_extra_slice(self: ComptimeEvaluator, start: i32, count: i32) -> i32:
    let new_start = self.extra_values.len() as i32
    for i in 0..count:
        self.extra_values.push(self.extra_values.get((start + i) as i64))
    new_start

fn ComptimeEvaluator.copy_vec_snapshot(self: ComptimeEvaluator, value: ComptimeValue) -> i32:
    self.copy_extra_slice(value.extra_start, value.extra_count)

fn ComptimeEvaluator.copy_map_snapshot(self: ComptimeEvaluator, value: ComptimeValue) -> i32:
    self.copy_extra_slice(value.extra_start, value.extra_count * 2)

fn ComptimeEvaluator.rebind_collection_receiver(self: ComptimeEvaluator, diags: &mut DiagnosticList, recv_node: i32, value: ComptimeValue, node: i32) -> ComptimeControl:
    let sym = self.binding_sym(recv_node)
    if sym == 0:
        return self.fail(diags, node, "comptime collection mutation requires a local identifier receiver")
    let idx = self.lookup_slot_index(sym)
    if idx < 0:
        return self.fail(diags, node, "comptime collection mutation requires a local identifier receiver")
    self.bind_value(sym, value, self.slot_muts.get(idx as i64))
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.node_type_or(self: ComptimeEvaluator, node: i32, fallback: i32) -> i32:
    if self.sema.typed_expr_types.contains(node):
        let typed = self.sema.typed_expr_types.get(node).unwrap()
        if typed != 0:
            return typed
    fallback

fn ComptimeEvaluator.static_type_expr(self: ComptimeEvaluator, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_GENERIC or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_TUPLE or kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        return self.sema.resolve_type_expr(node) as i32
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        let prim = self.sema.primitive_type_by_sym(sym)
        if prim != 0:
            return prim
        if self.sema.named_types.contains(sym):
            return self.sema.named_types.get(sym).unwrap()
        return 0
    if kind == NodeKind.NK_INDEX:
        let base = self.ast.get_data0(node)
        let base_sym =
            if self.ast.kind(base) == NodeKind.NK_IDENT or self.ast.kind(base) == NodeKind.NK_TYPE_NAMED:
                self.ast.get_data0(base)
            else:
                0
        if base_sym == 0:
            return 0
        let arg1 = self.static_type_expr(self.ast.get_data1(node))
        if arg1 == 0:
            return 0
        let args: Vec[i32] = Vec.new()
        args.push(arg1)
        var arg_count = 1
        if self.ast.get_data2(node) != 0:
            let arg2 = self.static_type_expr(self.ast.get_data2(node))
            if arg2 == 0:
                return 0
            args.push(arg2)
            arg_count = 2
        return self.sema.find_generic_inst_type(base_sym, args, arg_count) as i32
    0

fn ComptimeEvaluator.static_receiver_type(self: ComptimeEvaluator, node: i32) -> i32:
    let sym = self.binding_sym(node)
    if sym != 0:
        if self.lookup_slot_index(sym) >= 0:
            return 0
        if self.find_module_let_decl(sym) != 0:
            return 0
    self.static_type_expr(node)

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

fn ComptimeEvaluator.eval_static_collection_new(self: ComptimeEvaluator, diags: &mut DiagnosticList, result_type: i32, node: i32, arg_count: i32) -> ComptimeControl:
    if arg_count != 0:
        return self.fail(diags, node, "collection.new() takes no arguments in comptime")
    let resolved = self.sema.resolve_alias(result_type)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return self.fail(diags, node, "collection.new() requires a concrete generic type")
    let type_name = self.sema.type_name(result_type)
    let empty_start = self.extra_values.len() as i32
    if comptime_type_name_has_base(type_name, "Vec") != 0:
        return comptime_control_value(comptime_value_vec(result_type, empty_start, 0))
    if comptime_type_name_has_base(type_name, "HashMap") != 0:
        return comptime_control_value(comptime_value_map(result_type, empty_start, 0))
    self.fail(diags, node, "static method is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_vec_method_call(self: ComptimeEvaluator, diags: &mut DiagnosticList, recv_node: i32, recv_value: ComptimeValue, field: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let method = self.pool.resolve(field)

    if method == "push":
        if arg_count != 1:
            return self.fail(diags, node, "Vec.push() expects exactly one argument")
        let arg_signal = self.eval_expr(diags, self.ast.get_extra(extra_start))
        if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
            return arg_signal
        let new_start = self.copy_vec_snapshot(recv_value)
        self.extra_values.push(arg_signal.value)
        let updated = comptime_value_vec(recv_value.type_id, new_start, recv_value.extra_count + 1)
        return self.rebind_collection_receiver(diags, recv_node, updated, node)

    if method == "len":
        if arg_count != 0:
            return self.fail(diags, node, "Vec.len() takes no arguments")
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), recv_value.extra_count as i64))

    if method == "contains":
        if arg_count != 1:
            return self.fail(diags, node, "Vec.contains() expects exactly one argument")
        let needle_signal = self.eval_expr(diags, self.ast.get_extra(extra_start))
        if needle_signal.kind != ComptimeControlKind.CTL_VALUE:
            return needle_signal
        for i in 0..recv_value.extra_count:
            let item = self.extra_values.get((recv_value.extra_start + i) as i64)
            if comptime_values_equal(item, needle_signal.value, self.extra_values) != 0:
                return comptime_control_value(comptime_value_bool(1))
        return comptime_control_value(comptime_value_bool(0))

    if method == "get":
        if arg_count != 1:
            return self.fail(diags, node, "Vec.get() expects exactly one argument")
        let index_signal = self.eval_expr(diags, self.ast.get_extra(extra_start))
        if index_signal.kind != ComptimeControlKind.CTL_VALUE:
            return index_signal
        if comptime_value_is_intlike(index_signal.value) == 0:
            return self.fail(diags, node, "Vec.get() index must be an integer")
        let index = comptime_value_intlike(index_signal.value)
        if index < 0 or index >= recv_value.extra_count as i64:
            return self.fail(diags, node, "Vec.get() index out of bounds in comptime")
        return comptime_control_value(self.extra_values.get((recv_value.extra_start + index as i32) as i64))

    if method == "clear":
        if arg_count != 0:
            return self.fail(diags, node, "Vec.clear() takes no arguments")
        let updated = comptime_value_vec(recv_value.type_id, self.extra_values.len() as i32, 0)
        return self.rebind_collection_receiver(diags, recv_node, updated, node)

    if method == "pop":
        if arg_count != 0:
            return self.fail(diags, node, "Vec.pop() takes no arguments")
        if recv_value.extra_count <= 0:
            return self.fail(diags, node, "Vec.pop() on empty comptime vector")
        let removed = self.extra_values.get((recv_value.extra_start + recv_value.extra_count - 1) as i64)
        let new_start = self.copy_extra_slice(recv_value.extra_start, recv_value.extra_count - 1)
        let updated = comptime_value_vec(recv_value.type_id, new_start, recv_value.extra_count - 1)
        let rebind = self.rebind_collection_receiver(diags, recv_node, updated, node)
        if rebind.kind != ComptimeControlKind.CTL_VALUE:
            return rebind
        return comptime_control_value(removed)

    if method == "remove":
        if arg_count != 1:
            return self.fail(diags, node, "Vec.remove() expects exactly one argument")
        let index_signal = self.eval_expr(diags, self.ast.get_extra(extra_start))
        if index_signal.kind != ComptimeControlKind.CTL_VALUE:
            return index_signal
        if comptime_value_is_intlike(index_signal.value) == 0:
            return self.fail(diags, node, "Vec.remove() index must be an integer")
        let index = comptime_value_intlike(index_signal.value) as i32
        if index < 0 or index >= recv_value.extra_count:
            return self.fail(diags, node, "Vec.remove() index out of bounds in comptime")
        let removed = self.extra_values.get((recv_value.extra_start + index) as i64)
        let new_start = self.extra_values.len() as i32
        for i in 0..recv_value.extra_count:
            if i == index:
                continue
            self.extra_values.push(self.extra_values.get((recv_value.extra_start + i) as i64))
        let updated = comptime_value_vec(recv_value.type_id, new_start, recv_value.extra_count - 1)
        let rebind = self.rebind_collection_receiver(diags, recv_node, updated, node)
        if rebind.kind != ComptimeControlKind.CTL_VALUE:
            return rebind
        return comptime_control_value(removed)

    self.fail(diags, node, "Vec method is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_map_method_call(self: ComptimeEvaluator, diags: &mut DiagnosticList, recv_node: i32, recv_value: ComptimeValue, field: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let method = self.pool.resolve(field)

    if method == "insert":
        if arg_count != 2:
            return self.fail(diags, node, "HashMap.insert() expects exactly two arguments")
        let key_signal = self.eval_expr(diags, self.ast.get_extra(extra_start))
        if key_signal.kind != ComptimeControlKind.CTL_VALUE:
            return key_signal
        let value_signal = self.eval_expr(diags, self.ast.get_extra(extra_start + 1))
        if value_signal.kind != ComptimeControlKind.CTL_VALUE:
            return value_signal
        let new_start = self.extra_values.len() as i32
        var replaced = 0
        for i in 0..recv_value.extra_count:
            let base = recv_value.extra_start + i * 2
            let old_key = self.extra_values.get(base as i64)
            self.extra_values.push(old_key)
            if comptime_values_equal(old_key, key_signal.value, self.extra_values) != 0:
                self.extra_values.push(value_signal.value)
                replaced = 1
            else:
                self.extra_values.push(self.extra_values.get((base + 1) as i64))
        if replaced == 0:
            self.extra_values.push(key_signal.value)
            self.extra_values.push(value_signal.value)
        let new_count = if replaced != 0: recv_value.extra_count else: recv_value.extra_count + 1
        let updated = comptime_value_map(recv_value.type_id, new_start, new_count)
        return self.rebind_collection_receiver(diags, recv_node, updated, node)

    if method == "len":
        if arg_count != 0:
            return self.fail(diags, node, "HashMap.len() takes no arguments")
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), recv_value.extra_count as i64))

    if method == "contains":
        if arg_count != 1:
            return self.fail(diags, node, "HashMap.contains() expects exactly one argument")
        let key_signal = self.eval_expr(diags, self.ast.get_extra(extra_start))
        if key_signal.kind != ComptimeControlKind.CTL_VALUE:
            return key_signal
        for i in 0..recv_value.extra_count:
            let base = recv_value.extra_start + i * 2
            let old_key = self.extra_values.get(base as i64)
            if comptime_values_equal(old_key, key_signal.value, self.extra_values) != 0:
                return comptime_control_value(comptime_value_bool(1))
        return comptime_control_value(comptime_value_bool(0))

    if method == "get":
        if arg_count != 1:
            return self.fail(diags, node, "HashMap.get() expects exactly one argument")
        let key_signal = self.eval_expr(diags, self.ast.get_extra(extra_start))
        if key_signal.kind != ComptimeControlKind.CTL_VALUE:
            return key_signal
        for i in 0..recv_value.extra_count:
            let base = recv_value.extra_start + i * 2
            let old_key = self.extra_values.get(base as i64)
            if comptime_values_equal(old_key, key_signal.value, self.extra_values) != 0:
                return comptime_control_value(self.extra_values.get((base + 1) as i64))
        return self.fail(diags, node, "HashMap.get() missing key in comptime")

    if method == "clear":
        if arg_count != 0:
            return self.fail(diags, node, "HashMap.clear() takes no arguments")
        let updated = comptime_value_map(recv_value.type_id, self.extra_values.len() as i32, 0)
        return self.rebind_collection_receiver(diags, recv_node, updated, node)

    if method == "remove":
        if arg_count != 1:
            return self.fail(diags, node, "HashMap.remove() expects exactly one argument")
        let key_signal = self.eval_expr(diags, self.ast.get_extra(extra_start))
        if key_signal.kind != ComptimeControlKind.CTL_VALUE:
            return key_signal
        let new_start = self.extra_values.len() as i32
        var found = 0
        var removed = comptime_value_invalid()
        for i in 0..recv_value.extra_count:
            let base = recv_value.extra_start + i * 2
            let old_key = self.extra_values.get(base as i64)
            let old_value = self.extra_values.get((base + 1) as i64)
            if comptime_values_equal(old_key, key_signal.value, self.extra_values) != 0:
                found = 1
                removed = old_value
                continue
            self.extra_values.push(old_key)
            self.extra_values.push(old_value)
        if found == 0:
            return self.fail(diags, node, "HashMap.remove() missing key in comptime")
        let updated = comptime_value_map(recv_value.type_id, new_start, recv_value.extra_count - 1)
        let rebind = self.rebind_collection_receiver(diags, recv_node, updated, node)
        if rebind.kind != ComptimeControlKind.CTL_VALUE:
            return rebind
        return comptime_control_value(removed)

    self.fail(diags, node, "HashMap method is not comptime-evaluable yet")

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
    self.fail(diags, node, "type method '" ++ method ++ "' is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_module_let_decl(self: ComptimeEvaluator, diags: &mut DiagnosticList, decl: i32, use_node: i32) -> ComptimeControl:
    let sym = self.ast.get_data0(decl)
    for i in 0..self.active_global_syms.len() as i32:
        if self.active_global_syms.get(i as i64) == sym:
            return self.fail(diags, use_node, "cyclic comptime constant dependency")
    let value_node = self.ast.get_data1(decl)
    if value_node == 0:
        return self.fail(diags, use_node, "missing constant value")

    let saved_file = self.sema.local_file_id
    let saved_path = self.sema.current_module_path
    self.sema.local_file_id = self.decl_file_id(decl)
    self.sema.current_module_path = self.decl_path(decl)
    self.active_global_syms.push(sym)
    let result = self.eval_expr(diags, value_node)
    self.active_global_syms.pop()
    self.sema.local_file_id = saved_file
    self.sema.current_module_path = saved_path
    result

fn ComptimeEvaluator.eval_src_call(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32, arg_count: i32) -> ComptimeControl:
    if arg_count != 0:
        return self.fail(diags, node, "src() takes no arguments")
    let path = self.current_source_path()
    let text = self.current_source_text()
    let loc = comptime_source_loc(text, self.ast.get_start(node))
    comptime_control_value(comptime_value_str(f"{path}:{loc.line}:{loc.col}"))

fn ComptimeEvaluator.eval_embed_file_call(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32, arg_count: i32) -> ComptimeControl:
    if arg_count != 1:
        return self.fail(diags, node, "embed_file() takes exactly one string argument")
    let args_start = self.ast.get_data1(node)
    let arg_signal = self.eval_expr(diags, self.ast.get_extra(args_start))
    if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
        return arg_signal
    if arg_signal.value.kind != ComptimeValueKind.CV_STR:
        return self.fail(diags, node, "embed_file() argument must be a comptime string")
    let path = comptime_resolve_embed_file_path(self.current_source_path(), arg_signal.value.text)
    if with_fs_file_exists(path) == 0:
        return self.fail(diags, node, "embed_file: could not read '" ++ path ++ "'")
    comptime_control_value(comptime_value_str(with_fs_read_file(path)))

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

fn ComptimeEvaluator.eval_struct_lit(self: ComptimeEvaluator, diags: &mut DiagnosticList, node: i32) -> ComptimeControl:
    var type_id = self.node_type_or(node, 0)
    if type_id == 0:
        let name = self.ast.get_data0(node)
        if self.sema.named_types.contains(name):
            type_id = self.sema.named_types.get(name).unwrap()
    if type_id == 0:
        return self.fail(diags, node, "comptime struct literal is missing type information")

    let resolved = self.sema.resolve_alias(type_id)
    let tk = self.sema.get_type_kind(resolved)
    if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_GENERIC_INST:
        return self.fail(diags, node, "comptime struct literal requires a struct type")

    let field_total = self.sema.type_reflection_field_count(type_id)
    let extra_start = self.ast.get_data1(node)
    let init_count = self.ast.get_data2(node)
    let init_syms: Vec[i32] = Vec.new()
    let init_values: Vec[ComptimeValue] = Vec.new()

    for fi in 0..init_count:
        let field_sym = self.ast.get_extra(extra_start + fi * 2)
        if self.struct_field_index(type_id, field_sym) < 0:
            return self.fail(diags, node, "unknown comptime struct field '" ++ self.pool.resolve(field_sym) ++ "' for '" ++ self.sema.type_name(type_id) ++ "'")
        for pi in 0..init_syms.len() as i32:
            if init_syms.get(pi as i64) == field_sym:
                return self.fail(diags, node, "duplicate comptime struct field '" ++ self.pool.resolve(field_sym) ++ "'")
        let field_signal = self.eval_expr(diags, self.ast.get_extra(extra_start + fi * 2 + 1))
        if field_signal.kind != ComptimeControlKind.CTL_VALUE:
            return field_signal
        init_syms.push(field_sym)
        init_values.push(field_signal.value)

    let start = self.extra_values.len() as i32
    for fi in 0..field_total:
        let field_sym = self.sema.type_reflection_field_name(type_id, fi)
        var found = 0 - 1
        for pi in 0..init_syms.len() as i32:
            if init_syms.get(pi as i64) == field_sym:
                found = pi
                break
        if found < 0:
            return self.fail(diags, node, "missing comptime struct field '" ++ self.pool.resolve(field_sym) ++ "'")
        self.push_extra_value(init_values.get(found as i64))
    comptime_control_value(comptime_value_struct(type_id, start, field_total))

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
    if not self.sema.disc_repr_types.contains(enum_resolved as i32) or self.sema.disc_has_payload.contains(enum_resolved as i32):
        return self.unsupported(diags, node)
    let disc = if self.sema.disc_values.contains(sym): self.sema.disc_values.get(sym).unwrap() else: self.sema.variant_lookup.get(sym).unwrap()
    let repr_ty = self.sema.disc_repr_types.get(enum_resolved as i32).unwrap()
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
    if rhs.kind == ComptimeValueKind.CV_ARRAY or rhs.kind == ComptimeValueKind.CV_TUPLE or rhs.kind == ComptimeValueKind.CV_VEC:
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
    if op == BinaryOp.OP_ADD or op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_ADD_SAT:
        return comptime_control_value(comptime_value_int(result_ty, lv + rv))
    if op == BinaryOp.OP_SUB or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_SUB_SAT:
        return comptime_control_value(comptime_value_int(result_ty, lv - rv))
    if op == BinaryOp.OP_MUL or op == BinaryOp.OP_MUL_WRAP or op == BinaryOp.OP_MUL_SAT:
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
        if comptime_value_intlike(value) == self.ast.int_lit_value(pat):
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
    if iterable_signal.value.kind == ComptimeValueKind.CV_ARRAY or iterable_signal.value.kind == ComptimeValueKind.CV_TUPLE or iterable_signal.value.kind == ComptimeValueKind.CV_VEC:
        count = iterable_signal.value.extra_count
    else if iterable_signal.value.kind == ComptimeValueKind.CV_RANGE:
        let start_value = iterable_signal.value.data0
        let end_value = iterable_signal.value.data1
        count = if iterable_signal.value.extra_start != 0: (end_value - start_value + 1) as i32 else: (end_value - start_value) as i32
        if count < 0:
            count = 0
    else:
        return self.fail(diags, node, "comptime for requires an array, tuple, vec, or range")

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
    let arg_count = self.ast.get_data2(node)
    if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
        let recv_node = self.ast.get_data0(callee)
        let field = self.ast.get_data1(callee)
        let method_name = self.pool.resolve(field)
        let recv_type = self.static_receiver_type(recv_node)
        if recv_type != 0:
            if method_name == "new":
                let result_type = self.node_type_or(node, recv_type)
                if result_type != 0:
                    let resolved_result = self.sema.resolve_alias(result_type)
                    let result_name = self.sema.type_name(resolved_result)
                    if comptime_type_name_has_base(result_name, "Vec") != 0 or comptime_type_name_has_base(result_name, "HashMap") != 0:
                        return self.eval_static_collection_new(diags, result_type, node, arg_count)
            return self.eval_static_type_method_call(diags, recv_type, field, self.ast.get_data1(node), arg_count, node)
        let recv_signal = self.eval_expr(diags, recv_node)
        if recv_signal.kind != ComptimeControlKind.CTL_VALUE:
            return recv_signal
        if recv_signal.value.kind == ComptimeValueKind.CV_VEC:
            return self.eval_vec_method_call(diags, recv_node, recv_signal.value, field, self.ast.get_data1(node), arg_count, node)
        if recv_signal.value.kind == ComptimeValueKind.CV_MAP:
            return self.eval_map_method_call(diags, recv_node, recv_signal.value, field, self.ast.get_data1(node), arg_count, node)
        return self.fail(diags, node, "method '" ++ self.pool.resolve(field) ++ "' is not comptime-evaluable yet")
    if self.ast.kind(callee) != NodeKind.NK_IDENT:
        return self.fail(diags, node, "only direct comptime function calls are supported")
    let fn_sym = self.ast.get_data0(callee)
    if fn_sym == self.sema.syms.src:
        return self.eval_src_call(diags, node, arg_count)
    if fn_sym == self.sema.syms.embed_file:
        return self.eval_embed_file_call(diags, node, arg_count)
    if self.sema.fn_symbol_is_comptime(fn_sym) == 0:
        return self.fail(diags, node, "comptime can only call comptime functions")
    if self.sema.generic_fn_nodes.contains(fn_sym):
        return self.fail(diags, node, "generic comptime functions are not supported yet")
    if not self.sema.fn_decl_nodes.contains(fn_sym):
        return self.fail(diags, node, "callee is not a comptime function body")
    if self.active_fn_syms.len() as i32 >= self.recursion_limit:
        return self.fail(diags, node, "comptime recursion limit exceeded")

    let extra_start = self.ast.get_data1(node)
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
    let saved_path = self.sema.current_module_path
    self.sema.local_file_id = self.decl_file_id(fn_node)
    self.sema.current_module_path = self.decl_path(fn_node)
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
                self.sema.current_module_path = saved_path
                return self.fail(diags, node, "wrong argument count in comptime call")
            let default_signal = self.eval_expr(diags, default_node)
            if default_signal.kind != ComptimeControlKind.CTL_VALUE:
                self.pop_scope()
                self.active_fn_syms.pop()
                self.sema.local_file_id = saved_file
                self.sema.current_module_path = saved_path
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
                        self.sema.current_module_path = saved_path
                        return self.fail(diags, ppat, "comptime argument did not match parameter pattern")

    let body_signal = self.eval_expr(diags, self.ast.get_data1(fn_node))
    self.pop_scope()
    self.active_fn_syms.pop()
    self.sema.local_file_id = saved_file
    self.sema.current_module_path = saved_path
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
        let fast = self.ast.int_literal_fast_i64(node as NodeId)
        if fast.ok == 0:
            let exact = self.ast.int_literal_exact_value(node as NodeId)
            if exact.ok == 0 or exact.overflow != 0:
                return self.fail(diags, node, "comptime integer literal too large")
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), exact.lo))
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), fast.value))
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
    if kind == NodeKind.NK_STRUCT_LIT:
        return self.eval_struct_lit(diags, node)
    if kind == NodeKind.NK_RANGE:
        return self.eval_range(diags, node)
    if kind == NodeKind.NK_COMPTIME_ERROR:
        return self.eval_comptime_error(diags, node)
    self.unsupported(diags, node)

fn Sema.force_eval_comptime_expr(self: &mut Sema, node: i32) -> i32:
    let value = comptime_force_eval_expr(self as *mut Sema, &mut self.diags, self.ast, self.pool, node)
    comptime_value_is_valid(value)

fn Sema.check_top_level_comptime_let_values(self: &mut Sema):
    if self.diags.has_errors():
        return
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
        let ann_type = if ann_extra >= 0: self.resolve_type_expr(self.ast.get_extra(ann_extra)) else: 0 as TypeId
        let val_type = if ann_type != 0: self.check_expr_with_expected(value, ann_type) else: self.check_expr(value)
        if ann_type != 0 and val_type != 0:
            if self.types_compatible(ann_type as i32, val_type as i32) == 0:
                if self.arithmetic_result_type(ann_type, val_type) == 0:
                    self.emit_error("type mismatch in binding", decl)
        if val_type != 0 and ann_type == 0:
            self.typed_binding_types.insert(decl as i32, val_type as i32)
        if self.diags.has_errors():
            return
        let _ = self.force_eval_comptime_expr(value)
        if self.diags.has_errors():
            return
