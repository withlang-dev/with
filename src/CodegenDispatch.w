use Codegen
use Ast
use Mir
use Sema
use InternPool
use Diagnostic
use Source

extern fn with_eprint(s: str) -> void

// ── gen_function_dispatch: MIR-first, AST fallback for unsupported patterns ──

fn Codegen.fail_mir_codegen_for_function(self: Codegen, fn_node: i32, reason: str):
    let fn_sym = self.pool.get_data0(fn_node)
    let fn_name = self.function_symbol_name(fn_sym)
    let decl_index = self.find_decl_index(fn_node)
    let source_path =
        if decl_index >= 0: self.decl_source_path(decl_index)
        else: self.current_decl_source_file
    var msg =
        if reason == "lowering-failed":
            "error: MIR lowering failed for function '" ++ fn_name ++ "'"
        else if reason == "no-blocks":
            "error: MIR produced no basic blocks for function '" ++ fn_name ++ "'"
        else:
            "error: missing MIR body for function '" ++ fn_name ++ "'"
    if source_path.len() > 0 and source_path != "<unknown>":
        msg = msg ++ " in " ++ source_path
    msg = msg ++ "; AST codegen was removed, so this function cannot be compiled"
    if reason == "lowering-failed":
        msg = msg ++ " (re-run with WITH_MIR_AUDIT=1 to inspect unsupported nodes)"
    with_eprint(msg)
    self.had_error = 1

fn Codegen.gen_function_dispatch(self: Codegen, fn_node: i32):
    let flags = self.pool.get_data2(fn_node)
    let fn_sym = self.pool.get_data0(fn_node)
    // Skip functions with fn-level type params — compiled via monomorphization
    let meta = self.pool.find_fn_meta(fn_node)
    if meta >= 0 and self.pool.fn_meta_tp_count(meta) > 0:
        return
    // Skip generic struct methods without fn_values — compiled via monomorphization
    if self.sema.generic_fn_nodes.contains(fn_sym):
        if not self.fn_values.get(fn_sym).is_some():
            return
    let body_idx = self.mir_input.find_body(fn_sym)
    if body_idx >= 0:
        let body = self.mir_input.bodies.get(body_idx as i64)
        if body.lowering_failed == 0 and body.block_count() > 0:
            if self.debug_mir_codegen_enabled():
                let fn_name = self.intern.resolve(fn_sym)
                with_eprint("[mir-dispatch] using MIR for: " ++ fn_name)
            let fv = self.fn_values.get(fn_sym)
            if fv.is_some():
                self.current_function_name_sym = fn_sym
                self.debug_enter_function(fn_node, fn_sym, fv.unwrap() as i64)
                let fn_span = self.pool.get_start(fn_node)
                self.debug_set_location(fn_span)
            self.gen_function_mir(fn_node, body)
            self.debug_clear_location()
            return
        let reason = if body.lowering_failed != 0: "lowering-failed" else: "no-blocks"
        self.fail_mir_codegen_for_function(fn_node, reason)
        return
    self.fail_mir_codegen_for_function(fn_node, "no-body")

fn Codegen.mir_sema_type_to_llvm(self: Codegen, sema_ty: i32) -> i64:
    // Use MIR module's snapshot of sema type tables — the original sema's
    // type Vecs may have been freed by MirLower's by-value copy realloc.
    // For types created after snapshot (e.g. by check_fn_body_concrete),
    // fall back to reading from sema directly.
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    var tk = self.mir_input.mir_get_type_kind(resolved)
    if tk == 0 and resolved >= self.mir_input.sema_type_kinds.len() as i32 and resolved > 0:
        // Type was created after snapshot — read from sema directly
        return self.sema_type_to_llvm(resolved)
    if tk == TypeKind.TY_INT:
        let bits = self.mir_input.mir_get_type_d0(resolved)
        if bits == 8: return wl_i8_type(self.context)
        if bits == 16: return wl_i16_type(self.context)
        if bits == 64: return wl_i64_type(self.context)
        if bits == 128: return wl_i128_type(self.context)
        if bits > 0 and bits != 32: return wl_int_type_n(self.context, bits)
        return wl_i32_type(self.context)
    if tk == TypeKind.TY_FLOAT:
        let bits = self.mir_input.mir_get_type_d0(resolved)
        if bits == 32: return wl_f32_type(self.context)
        return wl_f64_type(self.context)
    if tk == TypeKind.TY_BOOL:
        return wl_i1_type(self.context)
    if tk == TypeKind.TY_STR:
        let str_sym = self.intern.intern("str")
        return self.resolve_named_type(str_sym)
    if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM:
        let name_sym = self.mir_input.mir_get_type_d0(resolved)
        if name_sym != 0:
            // Distinct types are transparent at LLVM level — resolve to inner type
            if tk == TypeKind.TY_STRUCT and self.sema.distinct_type_names.contains(name_sym):
                let dt_te_start = self.mir_input.mir_get_type_d1(resolved)
                let inner_tid = self.mir_input.mir_get_type_extra(dt_te_start + 1)
                return self.mir_sema_type_to_llvm(inner_tid)
            // Translate sema pool sym to codegen intern pool sym
            var cg_sym = name_sym
            let sema_text = self.sema_symbol_text(name_sym)
            if sema_text.len() > 0:
                cg_sym = self.intern.intern(sema_text)
            let named_ty = self.resolve_named_type(cg_sym)
            if named_ty != 0:
                return named_ty
            // Disc enum without payloads: return repr type
            if tk == TypeKind.TY_ENUM:
                let de_opt = self.disc_enum_type_map.get(cg_sym)
                if de_opt.is_some():
                    return self.disc_enum_repr_types.get(de_opt.unwrap() as i64)
    if tk == TypeKind.TY_GENERIC_INST:
        return self.sema_type_to_llvm(resolved)
    if tk == TypeKind.TY_TUPLE:
        let te_start = self.mir_input.mir_get_type_d0(resolved)
        let te_count = self.mir_input.mir_get_type_d1(resolved)
        let elem_types: Vec[i64] = Vec.new()
        for i in 0..te_count:
            let elem_tid = self.mir_input.mir_get_type_extra(te_start + i)
            var elem_llvm = self.mir_sema_type_to_llvm(elem_tid)
            if elem_llvm == 0:
                elem_llvm = self.type_fallback()
            elem_types.push(elem_llvm)
        if te_count > 0:
            return wl_struct_type(self.context, vec_data_i64(&elem_types), te_count, 0)
        return wl_i32_type(self.context)
    if tk == TypeKind.TY_RANGE:
        let range_elem_tid = self.mir_input.mir_get_type_d0(resolved)
        var range_elem_llvm = self.mir_sema_type_to_llvm(range_elem_tid)
        if range_elem_llvm == 0:
            range_elem_llvm = wl_i32_type(self.context)
        // Range struct: {start: Elem, end: Elem, inclusive: i8}
        let range_fields: Vec[i64] = Vec.new()
        range_fields.push(range_elem_llvm)
        range_fields.push(range_elem_llvm)
        range_fields.push(wl_i8_type(self.context))
        return wl_struct_type(self.context, vec_data_i64(&range_fields), 3, 0)
    if tk == TypeKind.TY_ARRAY:
        let arr_elem_tid = self.mir_input.mir_get_type_d0(resolved)
        let arr_len = self.mir_input.mir_get_type_d1(resolved)
        var arr_elem_llvm = self.mir_sema_type_to_llvm(arr_elem_tid)
        if arr_elem_llvm == 0:
            arr_elem_llvm = self.type_fallback()
        return wl_array_type(arr_elem_llvm, arr_len as i64)
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return wl_ptr_type(self.context)
    if tk == TypeKind.TY_FN:
        let ptr_ty = wl_ptr_type(self.context)
        let fat_types: Vec[i64] = Vec.new()
        fat_types.push(ptr_ty)
        fat_types.push(ptr_ty)
        return wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)
    if tk == TypeKind.TY_SLICE:
        let body_types: Vec[i64] = Vec.new()
        body_types.push(wl_ptr_type(self.context))
        body_types.push(wl_i64_type(self.context))
        return wl_struct_type(self.context, vec_data_i64(&body_types), 2, 0)
    0

fn codegen_regex_flag_options(flags: str) -> i32:
    var options: i32 = 0
    var i: i64 = 0
    while i < flags.len():
        let flag_byte = flags.byte_at(i)
        if flag_byte == 105:
            options = options | 8
        else if flag_byte == 109:
            options = options | 1024
        else if flag_byte == 115:
            options = options | 32
        else if flag_byte == 120:
            options = options | 128
        else if flag_byte == 85:
            options = options | 262144
        else if flag_byte == 117:
            options = options | 524288 | 131072
        i = i + 1
    options

fn codegen_regex_state_flags(flags: str) -> i32:
    var state_flags: i32 = 0
    var i: i64 = 0
    while i < flags.len():
        if flags.byte_at(i) == 103:
            state_flags = state_flags | 1
        i = i + 1
    state_flags

fn Codegen.ensure_regex_runtime_fn(self: Codegen, name: str, ret_ty: i64, params: Vec[i64]) -> i64:
    var fn_val = wl_get_named_function(self.llmod, name)
    if fn_val != 0:
        return fn_val
    let fn_ty = wl_function_type(ret_ty, vec_data_i64(&params), params.len() as i32, 0)
    wl_add_function(self.llmod, name, fn_ty)

fn Codegen.regex_literal_code_fn(self: Codegen) -> i64:
    let helper_sym = self.intern.intern("Regex.__literal_code")
    let fn_opt = self.fn_values.get(helper_sym)
    if fn_opt.is_some():
        return fn_opt.unwrap() as i64
    let helper_name = self.function_link_name_for_sym(helper_sym)
    let found = wl_get_named_function(self.llmod, helper_name)
    if found != 0:
        return found
    with_eprint("error: regex literal helper Regex.__literal_code was not generated")
    self.had_error = 1
    0

fn Codegen.regex_literal_global(self: Codegen, name: str, ty: i64, init: i64) -> i64:
    var gv = wl_get_named_global(self.llmod, name)
    if gv != 0:
        return gv
    gv = wl_add_global(self.llmod, ty, name)
    wl_set_linkage(gv, wl_private_linkage())
    wl_set_initializer(gv, init)
    gv

fn Codegen.gen_regex_literal_value(self: Codegen, body: MirBody, const_id: i32, regex_ty: i64) -> i64:
    let ptr_ty = wl_ptr_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let str_ty = self.resolve_named_type(self.intern.intern("str"))
    let pat_sym = body.const_d0.get(const_id as i64)
    let flags_sym = body.const_d1.get(const_id as i64)
    let node = body.const_d2.get(const_id as i64)
    let raw_pattern = if pat_sym != 0: self.intern.resolve(pat_sym) else: ""
    let raw_flags = if flags_sym != 0: self.intern.resolve(flags_sym) else: ""
    let pattern = self.decode_string_escapes(raw_pattern)
    let flags = self.decode_string_escapes(raw_flags)
    let options = codegen_regex_flag_options(flags)
    let state_flags = codegen_regex_state_flags(flags)
    let base_name = f"__regex_lit_{node}"
    let code_global = self.regex_literal_global(base_name, ptr_ty, wl_const_null(ptr_ty))
    let pos_global = self.regex_literal_global(base_name ++ "_pos", i32_ty, wl_const_int(i32_ty, 0, 0))
    let subject_ptr_global = self.regex_literal_global(base_name ++ "_subject_ptr", i64_ty, wl_const_int(i64_ty, 0, 0))
    let subject_len_global = self.regex_literal_global(base_name ++ "_subject_len", i64_ty, wl_const_int(i64_ty, -1, 1))

    let literal_fn = self.regex_literal_code_fn()
    if literal_fn == 0:
        return self.build_default_value(regex_ty)
    let literal_ft = wl_global_get_value_type(literal_fn)
    let literal_args: Vec[i64] = Vec.new()
    literal_args.push(code_global)
    literal_args.push(self.gen_string_literal_raw(pattern))
    literal_args.push(wl_const_int(i32_ty, options as i64, 0))
    let code_ptr = wl_build_call(self.builder, literal_ft, literal_fn, vec_data_i64(&literal_args), 3)
    let cap_params: Vec[i64] = Vec.new()
    cap_params.push(ptr_ty)
    let cap_fn = self.ensure_regex_runtime_fn("with_regex_capture_count", i32_ty, cap_params)
    let cap_ft = wl_global_get_value_type(cap_fn)
    let cap_args: Vec[i64] = Vec.new()
    cap_args.push(code_ptr)
    let capture_count = wl_build_call(self.builder, cap_ft, cap_fn, vec_data_i64(&cap_args), 1)

    var result = self.build_default_value(regex_ty)
    result = wl_build_insert_value(self.builder, result, code_ptr, 0)
    result = wl_build_insert_value(self.builder, result, self.gen_string_literal_raw(pattern), 1)
    result = wl_build_insert_value(self.builder, result, self.gen_string_literal_raw(flags), 2)
    result = wl_build_insert_value(self.builder, result, wl_const_int(i32_ty, options as i64, 0), 3)
    result = wl_build_insert_value(self.builder, result, wl_const_int(i32_ty, state_flags as i64, 0), 4)
    result = wl_build_insert_value(self.builder, result, capture_count, 5)
    result = wl_build_insert_value(self.builder, result, wl_const_int(i32_ty, 0, 0), 6)
    result = wl_build_insert_value(self.builder, result, if state_flags != 0: pos_global else: wl_const_null(ptr_ty), 7)
    result = wl_build_insert_value(self.builder, result, if state_flags != 0: subject_ptr_global else: wl_const_null(ptr_ty), 8)
    result = wl_build_insert_value(self.builder, result, if state_flags != 0: subject_len_global else: wl_const_null(ptr_ty), 9)
    result

fn Codegen.mir_build_closure_fn_type(self: Codegen, sema_ty: i32) -> i64:
    var resolved = self.mir_input.mir_resolve_alias(sema_ty)
    var tk = self.mir_input.mir_get_type_kind(resolved)
    // Type created after MIR snapshot — read from sema directly
    if tk == 0 and resolved >= self.mir_input.sema_type_kinds.len() as i32 and resolved > 0:
        resolved = self.sema.resolve_alias(resolved) as i32
        tk = self.sema.get_type_kind(resolved)
    if tk != TypeKind.TY_FN:
        return 0
    var extra_start = self.mir_input.mir_get_type_d0(resolved)
    var param_count = self.mir_input.mir_get_type_d1(resolved)
    var ret_ty_id = self.mir_input.mir_get_type_d2(resolved)
    // Fallback to sema for types beyond snapshot
    if resolved >= self.mir_input.sema_type_kinds.len() as i32:
        extra_start = self.sema.get_type_d0(resolved)
        param_count = self.sema.get_type_d1(resolved)
        ret_ty_id = self.sema.get_type_d2(resolved)
    let ret_ty = self.mir_sema_type_to_llvm(ret_ty_id)
    let llvm_ret = if ret_ty != 0: ret_ty else: wl_void_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(wl_ptr_type(self.context))
    for pi in 0..param_count:
        var p_sema_ty = self.mir_input.mir_get_type_extra(extra_start + pi)
        if resolved >= self.mir_input.sema_type_kinds.len() as i32:
            let te_idx = extra_start + pi
            if te_idx >= 0 and te_idx < self.sema.type_extra.len() as i32:
                p_sema_ty = self.sema.type_extra.get(te_idx as i64)
        let p_llvm_ty = self.mir_sema_type_to_llvm(p_sema_ty)
        if p_llvm_ty != 0:
            param_types.push(p_llvm_ty)
        else:
            param_types.push(self.type_fallback())
    wl_function_type(llvm_ret, vec_data_i64(&param_types), param_count + 1, 0)

fn Codegen.mir_build_raw_fn_type(self: Codegen, sema_ty: i32) -> i64:
    var resolved = self.mir_input.mir_resolve_alias(sema_ty)
    var tk = self.mir_input.mir_get_type_kind(resolved)
    if tk == 0 and resolved >= self.mir_input.sema_type_kinds.len() as i32 and resolved > 0:
        resolved = self.sema.resolve_alias(resolved) as i32
        tk = self.sema.get_type_kind(resolved)

    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        let pointee = if resolved >= self.mir_input.sema_type_kinds.len() as i32: self.sema.get_type_d0(resolved) else: self.mir_input.mir_get_type_d0(resolved)
        resolved = self.mir_input.mir_resolve_alias(pointee)
        tk = self.mir_input.mir_get_type_kind(resolved)
        if tk == 0 and resolved >= self.mir_input.sema_type_kinds.len() as i32 and resolved > 0:
            resolved = self.sema.resolve_alias(resolved) as i32
            tk = self.sema.get_type_kind(resolved)

    if tk != TypeKind.TY_FN:
        return 0

    var extra_start = self.mir_input.mir_get_type_d0(resolved)
    var param_count = self.mir_input.mir_get_type_d1(resolved)
    var ret_ty_id = self.mir_input.mir_get_type_d2(resolved)
    if resolved >= self.mir_input.sema_type_kinds.len() as i32:
        extra_start = self.sema.get_type_d0(resolved)
        param_count = self.sema.get_type_d1(resolved)
        ret_ty_id = self.sema.get_type_d2(resolved)
    let ret_ty = self.mir_sema_type_to_llvm(ret_ty_id)
    let llvm_ret = if ret_ty != 0: ret_ty else: wl_void_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        var p_sema_ty = self.mir_input.mir_get_type_extra(extra_start + pi)
        if resolved >= self.mir_input.sema_type_kinds.len() as i32:
            let te_idx = extra_start + pi
            if te_idx >= 0 and te_idx < self.sema.type_extra.len() as i32:
                p_sema_ty = self.sema.type_extra.get(te_idx as i64)
        let p_llvm_ty = self.mir_sema_type_to_llvm(p_sema_ty)
        if p_llvm_ty != 0:
            param_types.push(p_llvm_ty)
        else:
            param_types.push(self.type_fallback())
    wl_function_type(llvm_ret, vec_data_i64(&param_types), param_count, 0)

fn Codegen.mir_get_or_create_local_ptr(self: Codegen, local_id: i32, ty: i64) -> i64:
    let existing = self.mir_local_ptrs.get(local_id)
    if existing.is_some():
        return existing.unwrap() as i64
    let alloc_ty = if ty != 0: ty else: self.type_fallback()
    let ptr = self.create_entry_alloca(alloc_ty)
    self.mir_local_ptrs.insert(local_id, ptr)
    ptr

fn Codegen.mir_local_llvm_type(self: Codegen, body: MirBody, local_id: i32) -> i64:
    let known = self.mir_local_types.get(local_id)
    if known.is_some():
        return known.unwrap() as i64
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    let sema_ty = body.local_type_ids.get(local_id as i64)
    if sema_ty <= 0:
        return 0
    let llvm_ty = self.mir_sema_type_to_llvm(sema_ty)
    if llvm_ty != 0:
        self.mir_local_types.insert(local_id, llvm_ty)
    llvm_ty

fn Codegen.mir_try_init_const_local(self: Codegen, body: MirBody, local_id: i32, ptr: i64, llvm_ty: i64) -> bool:
    if local_id < 0 or local_id >= body.local_names.len() as i32:
        return false
    let sym = body.local_names.get(local_id as i64)
    if sym == 0:
        return false
    let decl_index = self.find_module_let_decl_index(sym)
    if decl_index < 0:
        return false
    let decl = self.pool.get_decl(decl_index)
    let flags = self.pool.get_data2(decl)
    if flags % 2 != 0:
        return false
    var value_node = self.pool.get_data1(decl)
    if value_node == 0:
        return false
    if self.pool.kind(value_node) == NodeKind.NK_COMPTIME:
        value_node = self.pool.get_data0(value_node)
    let value = self.try_eval_const_string(value_node, self.decl_source_path(decl_index), 0)
    if not value.ok:
        return false
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some():
        return false
    let str_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
    if llvm_ty != str_ty:
        return false
    wl_build_store(self.builder, self.gen_string_literal_raw(value.text), ptr)
    true


fn Codegen.mir_resolve_field_index(self: Codegen, agg_ty: i64, field_token: i32) -> i32:
    // Arrays use direct numeric index
    if wl_get_type_kind(agg_ty) == wl_array_type_kind():
        if field_token >= 0 and field_token < wl_get_array_length(agg_ty) as i32:
            return field_token
        return -1
    // Bitpacked structs: look up field by name in the struct registry
    if self.is_bitpacked_struct(agg_ty):
        let bp_idx = self.find_bitpacked_index_by_type(agg_ty)
        if bp_idx >= 0:
            let bp_sym = self.struct_index_syms.get(bp_idx as i64)
            if bp_sym != 0:
                return self.find_field_index(bp_sym, field_token)
        return -1
    if wl_get_type_kind(agg_ty) != wl_struct_type_kind():
        return -1
    let elem_count = wl_count_struct_elem_types(agg_ty)
    let struct_idx = self.find_struct_index_by_type(agg_ty)
    let source_field_count = if struct_idx >= 0: self.struct_field_counts.get(struct_idx as i64) else: elem_count
    let is_union = self.is_union_struct_index(struct_idx)

    // Try symbol-based lookup first (for named struct fields from MIR field projections).
    // MIR stores field *symbols* as projection data, not numeric indices.
    // Must do this before the raw range check, because a symbol value (e.g. 132 for "ast")
    // can accidentally pass field_token < elem_count on large structs.
    var normalized_field = field_token
    var field_text = self.intern.resolve(field_token)
    if field_text.len() == 0:
        field_text = self.sema_symbol_text(field_token)
    if field_text.len() > 0:
        normalized_field = self.intern.intern(field_text)
    let st_sym = self.find_struct_type_by_llvm(agg_ty)
    if st_sym != 0:
        var fi = self.find_field_index(st_sym, field_token)
        if fi < 0 and normalized_field != field_token:
            fi = self.find_field_index(st_sym, normalized_field)
        if fi >= 0 and ((is_union and fi < source_field_count) or ((not is_union) and fi < elem_count)):
            return fi

    // Vec types are created dynamically and not registered in the struct field
    // registry. Resolve their field names by layout: {ptr, len, cap, elem_size}.
    if self.vec_is_vec.contains(agg_ty):
        if normalized_field == self.sym_ptr: return 0
        if normalized_field == self.sym_len: return 1
        if normalized_field == self.sym_cap: return 2
        if normalized_field == self.sym_elem_size: return 3

    // Fall back to direct numeric index (for tuple fields, match bindings)
    if field_token >= 0 and ((is_union and field_token < source_field_count) or ((not is_union) and field_token < elem_count)):
        return field_token

    let field_name = field_text
    if field_name.len() == 1:
        let ch = field_name.byte_at(0)
        if ch >= 48 and ch <= 57:
            let idx = (ch - 48) as i32
            if idx >= 0 and idx < elem_count:
                return idx

    -1

fn Codegen.mir_place_projected_type(self: Codegen, body: MirBody, place_id: i32) -> i64:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    let base_local = body.place_locals.get(place_id as i64)
    let p_count = body.place_proj_counts.get(place_id as i64)
    if p_count == 0:
        return 0
    var cur_ty: i64 = 0
    var cur_sema_ty: i32 = 0
    let cur_ty_opt = self.mir_local_types.get(base_local)
    if cur_ty_opt.is_some():
        cur_ty = cur_ty_opt.unwrap() as i64
    if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
        cur_sema_ty = body.local_type_ids.get(base_local as i64)
    if cur_ty == 0 and base_local >= 0 and base_local < body.local_type_ids.len() as i32:
        if cur_sema_ty > 0:
            cur_ty = self.mir_sema_type_to_llvm(cur_sema_ty)
    if cur_ty == 0:
        return 0
    let p_start = body.place_proj_starts.get(place_id as i64)
    var active_variant_idx = -1
    for i in 0..p_count:
        let pk = body.proj_kinds.get((p_start + i) as i64)
        let pd = body.proj_d0.get((p_start + i) as i64)
        if pk == 0: // ProjKind.PK_FIELD
            if wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                let pointee_sema = self.mir_unwrap_ref_like_sema_type(cur_sema_ty)
                if pointee_sema > 0 and pointee_sema != cur_sema_ty:
                    let pointee_ty = self.mir_sema_type_to_llvm(pointee_sema)
                    if pointee_ty != 0:
                        cur_sema_ty = pointee_sema
                        cur_ty = pointee_ty
                if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
                    let sema_ty = body.local_type_ids.get(base_local as i64)
                    if sema_ty > 0:
                        let type_name_sym = self.mir_input.mir_get_type_name(sema_ty)
                        if type_name_sym != 0:
                            cur_ty = self.resolve_named_type(self.sema_sym_to_codegen_sym(type_name_sym))
                // Fallback: use method owner type for self parameter
                if (cur_ty == 0 or wl_get_type_kind(cur_ty) == wl_pointer_type_kind()) and self.current_method_owner_sym != 0:
                    let proj_owner_ty = self.resolve_named_type(self.current_method_owner_sym)
                    if proj_owner_ty != 0:
                        cur_ty = proj_owner_ty
            let field_sema_ty = if active_variant_idx >= 0:
                self.mir_enum_payload_sema_type(cur_sema_ty, active_variant_idx, pd)
            else:
                self.mir_project_field_sema_type(cur_sema_ty, pd)
            if field_sema_ty > 0:
                cur_sema_ty = field_sema_ty
            let fi = self.mir_resolve_field_index(cur_ty, pd)
            if fi < 0:
                return 0
            let union_idx = self.find_struct_index_by_type(cur_ty)
            if self.is_union_struct_index(union_idx):
                let union_field_ty = self.struct_source_field_type(union_idx, fi)
                if union_field_ty == 0:
                    return 0
                cur_ty = union_field_ty
            else if self.is_bitpacked_struct(cur_ty):
                // Bitpacked: field type is the sub-byte integer
                let bp_pinfo = self.get_bitpacked_field_info(cur_ty, fi)
                if bp_pinfo >= 0:
                    let bp_pw = bp_pinfo % 65536
                    cur_ty = wl_int_type_n(self.context, bp_pw)
                else:
                    return 0
            else if wl_get_type_kind(cur_ty) == wl_array_type_kind():
                cur_ty = wl_get_element_type(cur_ty)
            else if fi < wl_count_struct_elem_types(cur_ty):
                cur_ty = wl_struct_get_type_at(cur_ty, fi)
            else:
                return 0
            active_variant_idx = -1
        else if pk == 2: // ProjKind.PK_DEREF
            // Resolve pointee type from base local's sema type (via MIR snapshot)
            var deref_ty: i64 = 0
            if cur_sema_ty > 0:
                var deref_resolved = self.mir_input.mir_resolve_alias(cur_sema_ty)
                var deref_tk = self.mir_input.mir_get_type_kind(deref_resolved)
                if deref_tk == 0 and deref_resolved >= self.mir_input.sema_type_kinds.len() as i32 and deref_resolved > 0:
                    deref_resolved = self.sema.resolve_alias(deref_resolved as TypeId) as i32
                    deref_tk = self.sema.get_type_kind(deref_resolved)
                if deref_tk == TypeKind.TY_PTR or deref_tk == TypeKind.TY_REF:
                    let pointee_sema = if deref_resolved >= self.mir_input.sema_type_kinds.len() as i32:
                        self.sema.get_type_d0(deref_resolved)
                    else:
                        self.mir_input.mir_get_type_d0(deref_resolved)
                    if pointee_sema > 0:
                        cur_sema_ty = pointee_sema
                        deref_ty = self.mir_sema_type_to_llvm(pointee_sema)
            if deref_ty != 0:
                cur_ty = deref_ty
            else:
                return 0
            active_variant_idx = -1
        else if pk == 1: // ProjKind.PK_INDEX
            let idx_elem_ty = self.mir_index_elem_llvm_type(cur_sema_ty, cur_ty)
            let idx_elem_sema = self.mir_index_elem_sema_type(cur_sema_ty)
            if idx_elem_sema > 0:
                cur_sema_ty = idx_elem_sema
            if idx_elem_ty != 0:
                cur_ty = idx_elem_ty
            else:
                return 0
            active_variant_idx = -1
        else if pk == 3: // ProjKind.PK_DOWNCAST
            // For projected_type, we need the variant's payload struct type.
            var dc_found = false
            if wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                let wrap: Vec[i64] = Vec.new()
                wrap.push(cur_ty)
                cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                dc_found = true
            if not dc_found:
                let builtin_payload = self.mir_builtin_variant_payload_llvm_type(cur_sema_ty, pd)
                if builtin_payload != 0:
                    let wrap: Vec[i64] = Vec.new()
                    wrap.push(builtin_payload)
                    cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                    dc_found = true
            // Check disc enums first
            let enum_sym_opt = self.enum_by_llvm.get(cur_ty)
            if enum_sym_opt.is_some():
                let dc_enum_sym = enum_sym_opt.unwrap()
                let dc_et_opt = self.enum_type_map.get(dc_enum_sym)
                if dc_et_opt.is_some():
                    let dc_idx = dc_et_opt.unwrap()
                    let dc_v_start = self.enum_variant_starts.get(dc_idx as i64)
                    if pd >= 0 and dc_v_start + pd < self.enum_variant_payloads.len() as i32:
                        let payload_ty = self.enum_variant_payloads.get((dc_v_start + pd) as i64)
                        if payload_ty != 0:
                            cur_ty = payload_ty
                            dc_found = true
            // Check Option/Result via sema variant payload
            if not dc_found:
                let dc_sema_payload = self.mir_builtin_variant_payload_sema_type(cur_sema_ty, pd)
                if dc_sema_payload > 0:
                    let dc_sema_llvm = self.mir_sema_type_to_llvm(dc_sema_payload)
                    if dc_sema_llvm != 0:
                        let wrap: Vec[i64] = Vec.new()
                        wrap.push(dc_sema_llvm)
                        cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                        dc_found = true
            active_variant_idx = pd
        else:
            return 0
    cur_ty

fn Codegen.mir_place_ptr(self: Codegen, body: MirBody, place_id: i32, create_base: bool, create_type: i64) -> i64:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0

    let base_local = body.place_locals.get(place_id as i64)
    let p_count = body.place_proj_counts.get(place_id as i64)
    let base_opt = self.mir_local_ptrs.get(base_local)
    var cur_ptr: i64 = 0
    if base_opt.is_some():
        cur_ptr = base_opt.unwrap() as i64
    if cur_ptr == 0:
        if create_base:
            cur_ptr = self.mir_get_or_create_local_ptr(base_local, create_type)
            let alloc_ty = if create_type != 0: create_type else: self.type_fallback()
            self.mir_local_types.insert(base_local, alloc_ty)
            let _ = self.mir_try_init_const_local(body, base_local, cur_ptr, alloc_ty)
        else:
            return 0

    if p_count == 0:
        return cur_ptr

    // Walk projections: field access, index, deref
    let p_start = body.place_proj_starts.get(place_id as i64)
    var cur_ty: i64 = 0
    var cur_sema_ty: i32 = 0
    let cur_ty_opt = self.mir_local_types.get(base_local)
    if cur_ty_opt.is_some():
        cur_ty = cur_ty_opt.unwrap() as i64
    if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
        cur_sema_ty = body.local_type_ids.get(base_local as i64)
    // Resolve the base storage type via sema snapshot if LLVM type is not yet known.
    // For pointer globals this must remain ptr; field projection code resolves the pointee.
    if cur_ty == 0 and base_local >= 0 and base_local < body.local_type_ids.len() as i32:
        if cur_sema_ty > 0:
            cur_ty = self.mir_sema_type_to_llvm(cur_sema_ty)
            if cur_ty != 0:
                self.mir_local_types.insert(base_local, cur_ty)
    var active_variant_idx = -1
    for i in 0..p_count:
        let pk = body.proj_kinds.get((p_start + i) as i64)
        let pd = body.proj_d0.get((p_start + i) as i64)
        if pk == 0: // ProjKind.PK_FIELD
            if cur_ty == 0 or wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                // Base is a pointer (e.g., self param) — load the pointer first
                if cur_ty == 0:
                    cur_ptr = wl_build_load(self.builder, wl_ptr_type(self.context), cur_ptr)
                else:
                    cur_ptr = wl_build_load(self.builder, cur_ty, cur_ptr)
                let pointee_sema = self.mir_unwrap_ref_like_sema_type(cur_sema_ty)
                if pointee_sema > 0 and pointee_sema != cur_sema_ty:
                    let pointee_ty = self.mir_sema_type_to_llvm(pointee_sema)
                    if pointee_ty != 0:
                        cur_sema_ty = pointee_sema
                        cur_ty = pointee_ty
                // Resolve the pointee struct type via sema snapshot
                if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
                    let sema_ty = body.local_type_ids.get(base_local as i64)
                    if sema_ty > 0:
                        let type_name_sym = self.mir_input.mir_get_type_name(sema_ty)
                        if type_name_sym != 0:
                            cur_ty = self.resolve_named_type(self.sema_sym_to_codegen_sym(type_name_sym))
                        if cur_ty == 0:
                            cur_ty = self.mir_sema_type_to_llvm(sema_ty)
                // Fallback: use method owner type for self parameter
                if (cur_ty == 0 or wl_get_type_kind(cur_ty) == wl_pointer_type_kind()) and self.current_method_owner_sym != 0:
                    let owner_ty = self.resolve_named_type(self.current_method_owner_sym)
                    if owner_ty != 0:
                        cur_ty = owner_ty
            let field_sema_ty = if active_variant_idx >= 0:
                self.mir_enum_payload_sema_type(cur_sema_ty, active_variant_idx, pd)
            else:
                self.mir_project_field_sema_type(cur_sema_ty, pd)
            if field_sema_ty > 0:
                cur_sema_ty = field_sema_ty
            let fi = self.mir_resolve_field_index(cur_ty, pd)
            if fi < 0:
                return 0
            let union_idx = self.find_struct_index_by_type(cur_ty)
            if self.is_union_struct_index(union_idx):
                let union_field_ty = self.struct_source_field_type(union_idx, fi)
                if union_field_ty == 0:
                    return 0
                cur_ty = union_field_ty
            else if self.is_bitpacked_struct(cur_ty):
                // Bitpacked field: don't GEP — record bit offset/width for later shift+mask.
                // cur_ptr stays pointing to the backing iN, cur_ty stays as iN.
                let bp_info = self.get_bitpacked_field_info(cur_ty, fi)
                if bp_info >= 0:
                    self.bitpacked_place_proj.insert(place_id, bp_info)
                // cur_ty becomes the field's type (for subsequent use)
                let bp_bit_width = bp_info % 65536
                cur_ty = wl_int_type_n(self.context, bp_bit_width)
            else if wl_get_type_kind(cur_ty) == wl_array_type_kind():
                // Array field access: GEP with [0, index]
                let arr_elem_ty = wl_get_element_type(cur_ty)
                let gep_indices: Vec[i64] = Vec.new()
                gep_indices.push(wl_const_int(wl_i32_type(self.context), 0, 0))
                gep_indices.push(wl_const_int(wl_i32_type(self.context), fi as i64, 0))
                cur_ptr = wl_build_gep(self.builder, cur_ty, cur_ptr, vec_data_i64(&gep_indices), 2)
                cur_ty = arr_elem_ty
            else:
                let llvm_fi = self.get_llvm_field_index(cur_ty, fi)
                cur_ptr = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, llvm_fi)
                if llvm_fi < wl_count_struct_elem_types(cur_ty):
                    cur_ty = wl_struct_get_type_at(cur_ty, llvm_fi)
                else:
                    cur_ty = 0
            active_variant_idx = -1
        else if pk == 2: // ProjKind.PK_DEREF
            // Load the pointer value, then use it as the new base
            cur_ptr = wl_build_load(self.builder, wl_ptr_type(self.context), cur_ptr)
            // Resolve pointee type from base local's sema type (via snapshot)
            var deref_ptr_ty: i64 = 0
            if cur_sema_ty > 0:
                var deref_resolved = self.mir_input.mir_resolve_alias(cur_sema_ty)
                var deref_tk = self.mir_input.mir_get_type_kind(deref_resolved)
                if deref_tk == 0 and deref_resolved >= self.mir_input.sema_type_kinds.len() as i32 and deref_resolved > 0:
                    deref_resolved = self.sema.resolve_alias(deref_resolved as TypeId) as i32
                    deref_tk = self.sema.get_type_kind(deref_resolved)
                if deref_tk == TypeKind.TY_PTR or deref_tk == TypeKind.TY_REF:
                    let pointee_sema = if deref_resolved >= self.mir_input.sema_type_kinds.len() as i32:
                        self.sema.get_type_d0(deref_resolved)
                    else:
                        self.mir_input.mir_get_type_d0(deref_resolved)
                    if pointee_sema > 0:
                        cur_sema_ty = pointee_sema
                        deref_ptr_ty = self.mir_sema_type_to_llvm(pointee_sema)
            if deref_ptr_ty != 0:
                cur_ty = deref_ptr_ty
            else:
                cur_ty = 0
            active_variant_idx = -1
        else if pk == 1: // ProjKind.PK_INDEX
            // pd is a local_id holding the index value
            let idx_ptr_opt = self.mir_local_ptrs.get(pd)
            var idx_val: i64 = wl_const_int(wl_i64_type(self.context), 0, 0)
            // Track the index's sema type so we can pick zext vs sext when widening.
            // Default to a signed type so that without info we behave like the
            // old code (i32, sign-extending).
            var idx_sema_ty: i32 = body.local_type_ids.get(pd as i64)
            if idx_ptr_opt.is_some():
                let idx_ty_opt = self.mir_local_types.get(pd)
                var idx_ty = wl_i32_type(self.context)
                if idx_ty_opt.is_some():
                    idx_ty = idx_ty_opt.unwrap() as i64
                idx_val = wl_build_load(self.builder, idx_ty, idx_ptr_opt.unwrap() as i64)
            if wl_get_type_kind(wl_type_of(idx_val)) != wl_integer_type_kind():
                with_eprint("error: code generation failed: index operand is not an integer")
                self.had_error = 1
                return 0
            // LLVM GEP treats integer indices as SIGNED. For unsigned index
            // types narrower than i64 we must zero-extend explicitly — otherwise
            // a u8 value of 137 (= 0x89) sign-extends to -119 and the GEP reads
            // from before the start of the array. (This bit `_pcre2_OP_lengths_8[*code]`
            // in PCRE2: OP_BRA = 137, was indexing the table at offset -119.)
            let idx_bits = wl_get_int_type_width(wl_type_of(idx_val))
            if idx_bits < 64:
                let i64_ty = wl_i64_type(self.context)
                if idx_sema_ty != 0 and self.sema.is_unsigned_int_type(idx_sema_ty):
                    idx_val = wl_build_zext(self.builder, idx_val, i64_ty)
                else:
                    idx_val = wl_build_sext(self.builder, idx_val, i64_ty)
            let elem_llvm = self.mir_index_elem_llvm_type(cur_sema_ty, cur_ty)
            let elem_sema = self.mir_index_elem_sema_type(cur_sema_ty)
            if elem_sema > 0:
                cur_sema_ty = elem_sema
            if wl_get_type_kind(cur_ty) == wl_array_type_kind():
                let indices: Vec[i64] = Vec.new()
                indices.push(idx_val)
                cur_ptr = wl_build_gep(self.builder, elem_llvm, cur_ptr, vec_data_i64(&indices), 1)
                cur_ty = elem_llvm
            else if wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                // Raw pointer indexing: load the pointer, then GEP.
                if elem_llvm == 0:
                    return 0
                let raw_ptr = wl_build_load(self.builder, wl_ptr_type(self.context), cur_ptr)
                let indices: Vec[i64] = Vec.new()
                indices.push(idx_val)
                cur_ptr = wl_build_gep(self.builder, elem_llvm, raw_ptr, vec_data_i64(&indices), 1)
                cur_ty = elem_llvm
            else:
                // Vec, str, and slices all store their data pointer in field 0.
                if elem_llvm == 0:
                    return 0
                let data_gep = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, 0)
                let raw_ptr = wl_build_load(self.builder, wl_ptr_type(self.context), data_gep)
                let indices: Vec[i64] = Vec.new()
                indices.push(idx_val)
                cur_ptr = wl_build_gep(self.builder, elem_llvm, raw_ptr, vec_data_i64(&indices), 1)
                cur_ty = elem_llvm
            active_variant_idx = -1
        else if pk == 3: // ProjKind.PK_DOWNCAST
            // GEP to field 1 of enum/option/result struct for payload access.
            var dc_handled = false
            if wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                let wrap: Vec[i64] = Vec.new()
                wrap.push(cur_ty)
                cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                dc_handled = true
            if not dc_handled:
                let builtin_payload = self.mir_builtin_variant_payload_llvm_type(cur_sema_ty, pd)
                if builtin_payload != 0:
                    if wl_count_struct_elem_types(cur_ty) > 1:
                        cur_ptr = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, 1)
                    let wrap: Vec[i64] = Vec.new()
                    wrap.push(builtin_payload)
                    cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                    dc_handled = true
            // Disc enums: { repr_type, [max_payload x i8] }
            let dc_enum_sym_opt = self.enum_by_llvm.get(cur_ty)
            if dc_enum_sym_opt.is_some():
                let dc_enum_sym = dc_enum_sym_opt.unwrap()
                let dc_et_opt = self.enum_type_map.get(dc_enum_sym)
                if dc_et_opt.is_some():
                    let dc_idx = dc_et_opt.unwrap()
                    let dc_v_start = self.enum_variant_starts.get(dc_idx as i64)
                    var dc_payload_ty: i64 = 0
                    if pd >= 0 and dc_v_start + pd < self.enum_variant_payloads.len() as i32:
                        dc_payload_ty = self.enum_variant_payloads.get((dc_v_start + pd) as i64)
                    if wl_count_struct_elem_types(cur_ty) > 1:
                        cur_ptr = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, 1)
                    if dc_payload_ty != 0:
                        cur_ty = dc_payload_ty
                    else:
                        cur_ty = 0
                    dc_handled = true
            // Option/Result types via sema variant payload
            if not dc_handled:
                let dc_pp_sema = self.mir_builtin_variant_payload_sema_type(cur_sema_ty, pd)
                if dc_pp_sema > 0:
                    let dc_pp_llvm = self.mir_sema_type_to_llvm(dc_pp_sema)
                    if wl_count_struct_elem_types(cur_ty) > 1:
                        cur_ptr = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, 1)
                    if dc_pp_llvm != 0:
                        let wrap: Vec[i64] = Vec.new()
                        wrap.push(dc_pp_llvm)
                        cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                    else:
                        cur_ty = 0
                    dc_handled = true
            if not dc_handled:
                cur_ty = 0
            active_variant_idx = pd
        else:
            return 0

    cur_ptr

fn Codegen.mir_const_value(self: Codegen, body: MirBody, const_id: i32, expected_ty: i64) -> i64:
    var materialize_ty = expected_ty
    if materialize_ty == 0 and const_id >= 0 and const_id < body.const_types.len() as i32:
        let const_sema_ty = body.const_types.get(const_id as i64)
        if const_sema_ty > 0:
            materialize_ty = self.mir_sema_type_to_llvm(const_sema_ty)
    let fallback_ty = if materialize_ty != 0: materialize_ty else: wl_i32_type(self.context)
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        if self.debug_fallback_enabled():
            with_eprint(f"warning: [fallback] mir_const_value: invalid const_id={const_id}")
        return wl_get_undef(fallback_ty)

    let ck = body.const_kinds.get(const_id as i64)
    let cd = body.const_d0.get(const_id as i64)

    if ck == ConstKind.CK_INT:
        let int_value = mir_const_int_value(body, const_id)
        // Null pointer: ConstKind.CK_INT 0 with pointer expected type
        if int_value == 0 and materialize_ty != 0 and wl_get_type_kind(materialize_ty) == wl_pointer_type_kind():
            return wl_const_null(materialize_ty)
        if materialize_ty != 0:
            let ek = wl_get_type_kind(materialize_ty)
            if ek == wl_float_type_kind() or ek == wl_double_type_kind():
                return wl_const_real(materialize_ty, int_value as f64)
        var int_ty = materialize_ty
        if int_ty == 0 or wl_get_type_kind(int_ty) != wl_integer_type_kind():
            int_ty = if int_value < -2147483648 or int_value > 2147483647: wl_i64_type(self.context) else: wl_i32_type(self.context)
        return wl_const_int(int_ty, int_value, 1)

    if ck == ConstKind.CK_INT_EXACT:
        if materialize_ty != 0:
            let ek = wl_get_type_kind(materialize_ty)
            if ek == wl_float_type_kind() or ek == wl_double_type_kind():
                return wl_const_real(materialize_ty, self.exact_int_expr_to_f64(cd))
        let exact = self.exact_int_const_llvm(cd, body.const_types.get(const_id as i64))
        if exact != 0:
            return exact
        return wl_get_undef(fallback_ty)

    if ck == ConstKind.CK_BOOL:
        return wl_const_int(wl_i1_type(self.context), cd as i64, 0)

    if ck == ConstKind.CK_STR:
        var text = ""
        if cd != 0:
            let raw = self.intern.resolve(cd)
            if raw.len() >= 5 and raw.byte_at(0) == 1 and raw.byte_at(1) == 114 and raw.byte_at(2) == 97 and raw.byte_at(3) == 119 and raw.byte_at(4) == 1:
                text = raw.slice(5, raw.len())
            else:
                text = self.decode_string_escapes(raw)
        return self.gen_string_literal_raw(text)

    if ck == ConstKind.CK_UNIT:
        if materialize_ty != 0 and materialize_ty != wl_void_type(self.context):
            return self.build_default_value(materialize_ty)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    if ck == ConstKind.CK_FLOAT:
        var float_ty = materialize_ty
        if float_ty == 0:
            float_ty = wl_f64_type(self.context)
        let fk = wl_get_type_kind(float_ty)
        if fk != wl_float_type_kind() and fk != wl_double_type_kind():
            float_ty = wl_f64_type(self.context)
        var fval: f64 = 0.0
        // ConstKind.CK_FLOAT d0 is an AstPool string table index (from Parser.add_string)
        if cd >= 0 and cd < self.pool.state.strings.len() as i32:
            let float_text = self.pool.get_string(cd)
            if float_text.len() > 0:
                fval = with_parse_float(float_text)
        return wl_const_real(float_ty, fval)

    if ck == ConstKind.CK_ZERO_SIZED:
        if materialize_ty != 0:
            return self.build_default_value(materialize_ty)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    if ck == ConstKind.CK_REGEX_LIT:
        let regex_ty = if materialize_ty != 0: materialize_ty else: self.resolve_named_type(self.intern.intern("Regex"))
        return self.gen_regex_literal_value(body, const_id, regex_ty)

    if ck == ConstKind.CK_CLOSURE:
        // Populate local_allocas/local_types/local_sema_types from MIR locals
        // so gen_closure can find captured variables and their types.
        let closure_node = cd
        if closure_node <= 0 or closure_node >= self.pool.node_count():
            with_eprint(f"warning: [ck-closure] invalid node={closure_node}")
            return wl_get_undef(fallback_ty)
        for li in 0..body.local_count():
            let name_sym = body.local_names.get(li as i64)
            if name_sym != 0:
                let ptr_opt = self.mir_local_ptrs.get(li)
                if ptr_opt.is_some():
                    self.local_allocas.insert(name_sym, ptr_opt.unwrap())
                    let ty_opt = self.mir_local_types.get(li)
                    if ty_opt.is_some():
                        self.local_types.insert(name_sym, ty_opt.unwrap())
                let sema_ty = body.local_type_ids.get(li as i64)
                if sema_ty != 0:
                    self.local_sema_types.insert(name_sym, sema_ty)
        let closure_result = self.gen_closure(closure_node)
        return closure_result

    if ck == ConstKind.CK_ASYNC_BLOCK:
        // Same preamble as CK_CLOSURE: populate local_allocas/local_types from MIR locals
        let ab_node = cd
        if ab_node <= 0 or ab_node >= self.pool.node_count():
            return wl_get_undef(fallback_ty)
        for ab_li in 0..body.local_count():
            let ab_name_sym = body.local_names.get(ab_li as i64)
            if ab_name_sym != 0:
                let ab_ptr_opt = self.mir_local_ptrs.get(ab_li)
                if ab_ptr_opt.is_some():
                    self.local_allocas.insert(ab_name_sym, ab_ptr_opt.unwrap())
                    let ab_ty_opt = self.mir_local_types.get(ab_li)
                    if ab_ty_opt.is_some():
                        self.local_types.insert(ab_name_sym, ab_ty_opt.unwrap())
                let ab_sema_ty = body.local_type_ids.get(ab_li as i64)
                if ab_sema_ty != 0:
                    self.local_sema_types.insert(ab_name_sym, ab_sema_ty)
        return self.gen_async_block(ab_node)

    if ck == ConstKind.CK_FN:
        let fn_sym = cd
        // ConstKind.CK_FN sym from MirLower is in sema pool — must translate to codegen pool.
        // Direct fn_values lookup would return wrong function (pool ID collision).
        var translated_sym = fn_sym
        let sema_text = self.sema_symbol_text(fn_sym)
        if sema_text.len() > 0:
            translated_sym = self.intern.intern(sema_text)
        let fv_opt = self.fn_values.get(translated_sym)
        if fv_opt.is_some():
            if self.debug_mir_codegen_enabled():
                let fn_name = self.function_symbol_name(translated_sym)
                with_eprint(f"[ck-fn] sym={fn_sym} -> {fn_name}")
            return fv_opt.unwrap() as i64
        let fn_name = self.function_link_name_for_sym(translated_sym)
        let found = wl_get_named_function(self.llmod, fn_name)
        if found != 0:
            if self.debug_mir_codegen_enabled():
                with_eprint(f"[ck-fn] sym={fn_sym} -> {fn_name} (llmod)")
            return found
        with_eprint(f"warning: [ck-fn] NOT FOUND sym={fn_sym} name={fn_name}")
        return wl_get_undef(fallback_ty)

    wl_get_undef(fallback_ty)

fn Codegen.mir_eval_operand(self: Codegen, body: MirBody, operand_id: i32, expected_ty: i64) -> i64:
    let fallback_ty = if expected_ty != 0: expected_ty else: wl_i32_type(self.context)
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        if self.debug_fallback_enabled():
            with_eprint(f"warning: [fallback] mir_eval_operand: invalid operand_id={operand_id}")
        return wl_get_undef(fallback_ty)

    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        if od < 0 or od >= body.place_locals.len() as i32:
            return wl_get_undef(fallback_ty)
        let local_id = body.place_locals.get(od as i64)
        var ptr = self.mir_place_ptr(body, od, false, 0)
        // Lazy-create alloca using sema type when local not yet allocated
        if ptr == 0 and local_id >= 0 and local_id < body.local_type_ids.len() as i32:
            let sema_ty_id = body.local_type_ids.get(local_id as i64)
            if sema_ty_id > 0:
                let sema_llvm_ty = self.mir_sema_type_to_llvm(sema_ty_id)
                if sema_llvm_ty != 0:
                    ptr = self.mir_place_ptr(body, od, true, sema_llvm_ty)
        if ptr == 0:
            return wl_get_undef(fallback_ty)
        var ptr_ty: i64 = 0
        let p_count = body.place_proj_counts.get(od as i64)
        if p_count > 0:
            // Place has projections — walk them to get the final field type
            ptr_ty = self.mir_place_projected_type(body, od)
        if ptr_ty == 0:
            let ptr_ty_opt = self.mir_local_types.get(local_id)
            if ptr_ty_opt.is_some():
                ptr_ty = ptr_ty_opt.unwrap() as i64
        // Fall back to sema type resolution when LLVM type not yet known
        if ptr_ty == 0 and local_id >= 0 and local_id < body.local_type_ids.len() as i32:
            let sema_ty = body.local_type_ids.get(local_id as i64)
            if sema_ty > 0:
                ptr_ty = self.mir_sema_type_to_llvm(sema_ty)
        if ptr_ty == 0:
            return wl_get_undef(fallback_ty)
        // Bitpacked field extraction: if this place has a bitpacked projection,
        // load the full backing integer, then apply shift+mask to extract the field.
        let bp_proj = self.bitpacked_place_proj.get(od)
        if bp_proj.is_some():
            // Override ptr_ty to the backing integer type (the alloca type)
            ptr_ty = wl_get_allocated_type(ptr)
        var loaded: i64 = 0
        if p_count == 0 and wl_get_type_kind(ptr_ty) == wl_pointer_type_kind():
            let indirect_value_ty_opt = self.mir_indirect_value_local_types.get(local_id)
            if indirect_value_ty_opt.is_some():
                let indirect_value_ty = indirect_value_ty_opt.unwrap() as i64
                if indirect_value_ty != 0 and wl_get_type_kind(indirect_value_ty) != wl_pointer_type_kind():
                    let indirect_ptr = wl_build_load(self.builder, ptr_ty, ptr)
                    loaded = wl_build_load(self.builder, indirect_value_ty, indirect_ptr)
                    ptr_ty = indirect_value_ty
        if loaded == 0:
            loaded = wl_build_load(self.builder, ptr_ty, ptr)
        if bp_proj.is_some():
            let bp_info = bp_proj.unwrap() as i32
            let bp_bit_offset = bp_info / 65536
            let bp_bit_width = bp_info % 65536
            let bp_total_bits = wl_get_int_type_width(ptr_ty)
            // MSB-first: shift right by (total - offset - width)
            let bp_shift_amt = bp_total_bits - bp_bit_offset - bp_bit_width
            if bp_shift_amt > 0:
                let bp_shift = wl_const_int(ptr_ty, bp_shift_amt as i64, 0)
                loaded = wl_build_lshr(self.builder, loaded, bp_shift)
            // Mask to field width
            if bp_bit_width < bp_total_bits:
                let bp_mask = wl_const_int(ptr_ty, ((1 as i64) << (bp_bit_width as u32)) - 1, 0)
                loaded = wl_build_and(self.builder, loaded, bp_mask)
            // Truncate to field type
            let bp_field_ty = wl_int_type_n(self.context, bp_bit_width)
            if bp_bit_width < bp_total_bits:
                loaded = wl_build_trunc(self.builder, loaded, bp_field_ty)
            self.bitpacked_place_proj.remove(od)
        if expected_ty != 0:
            // Don't coerce between incompatible struct types — the local's
            // LLVM type (from a prior store, e.g. intrinsic result) is
            // authoritative over sema type hints that may differ
            // (e.g., VecIter.next() stores Option[T] but sema says T).
            let lk = wl_get_type_kind(ptr_ty)
            let ek = wl_get_type_kind(expected_ty)
            if lk == wl_struct_type_kind() and ek == wl_struct_type_kind() and ptr_ty != expected_ty:
                return loaded
            return self.coerce_value_to_type(loaded, expected_ty)
        return loaded

    if ok == OperandKind.OK_CONSTANT:
        return self.mir_const_value(body, od, expected_ty)

    wl_get_undef(fallback_ty)

fn Codegen.mir_operand_is_unsigned(self: Codegen, body: MirBody, operand_id: i32) -> bool:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return false
    let sema_ty = self.mir_operand_sema_type(body, operand_id)
    self.mir_sema_type_is_unsigned(sema_ty)

fn Codegen.mir_sema_type_is_unsigned(self: Codegen, sema_ty: i32) -> bool:
    if sema_ty <= 0: return false
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    if self.mir_input.mir_get_type_kind(resolved) == TypeKind.TY_INT:
        return self.mir_input.mir_get_type_d1(resolved) == 0
    false

fn Codegen.mir_coerce_value_to_sema_type(self: Codegen, val: i64, target_ty: i64, target_sema_ty: i32, src_unsigned: bool) -> i64:
    if val == 0 or target_ty == 0:
        return val
    let val_ty = wl_type_of(val)
    if val_ty == target_ty:
        return val
    let vk = wl_get_type_kind(val_ty)
    let tk = wl_get_type_kind(target_ty)
    if vk == wl_integer_type_kind() and tk == wl_integer_type_kind():
        return self.coerce_int_ext(val, target_ty, src_unsigned or self.mir_sema_type_is_unsigned(target_sema_ty))
    self.coerce_value_to_type(val, target_ty)

fn Codegen.mir_compare_dispatch_kind(self: Codegen, sema_ty: i32) -> i32:
    if sema_ty <= 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    let tk = self.mir_input.mir_get_type_kind(resolved)
    if tk == TypeKind.TY_STR:
        return 1
    if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM or tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_TUPLE or tk == TypeKind.TY_GENERIC_INST or tk == TypeKind.TY_SLICE:
        return 2
    if tk == TypeKind.TY_FLOAT:
        return 3
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_FN or tk == TypeKind.TY_GENERIC_FN:
        return 4
    if tk == TypeKind.TY_INT or tk == TypeKind.TY_BOOL:
        return 5
    0

fn Codegen.mir_coerce_compare_operand(self: Codegen, val: i64, sema_ty: i32) -> i64:
    if sema_ty <= 0:
        return val
    let llvm_ty = self.mir_sema_type_to_llvm(sema_ty)
    if llvm_ty == 0 or wl_type_of(val) == llvm_ty:
        return val
    self.coerce_value_to_type(val, llvm_ty)

fn Codegen.mir_build_eq_from_sema(self: Codegen, op: i32, lhs: i64, rhs: i64, lhs_sema: i32, rhs_sema: i32) -> i64:
    let lhs_kind = self.mir_compare_dispatch_kind(lhs_sema)
    let rhs_kind = self.mir_compare_dispatch_kind(rhs_sema)
    if lhs_kind == 0 or rhs_kind == 0 or lhs_kind != rhs_kind:
        return 0

    let lhs_cmp = self.mir_coerce_compare_operand(lhs, lhs_sema)
    let rhs_cmp = self.mir_coerce_compare_operand(rhs, rhs_sema)
    let lhs_ty = wl_type_of(lhs_cmp)
    let rhs_ty = wl_type_of(rhs_cmp)
    if lhs_ty == 0 or rhs_ty == 0 or lhs_ty != rhs_ty:
        return 0

    if lhs_kind == 1 and self.is_str_type(lhs_ty):
        return self.compare_str_eq(lhs_cmp, rhs_cmp, op)

    if lhs_kind == 2:
        let cmp_kind = wl_get_type_kind(lhs_ty)
        if cmp_kind == wl_struct_type_kind() or cmp_kind == wl_array_type_kind():
            return self.compare_aggregate_eq(lhs_cmp, rhs_cmp, op)

    0

fn Codegen.coerce_float_operand_to(self: Codegen, val: i64, target_ty: i64, is_unsigned: bool) -> i64:
    let val_ty = wl_type_of(val)
    if val_ty == target_ty or target_ty == 0:
        return val
    let vk = wl_get_type_kind(val_ty)
    let tk = wl_get_type_kind(target_ty)
    if vk == wl_integer_type_kind() and (tk == wl_float_type_kind() or tk == wl_double_type_kind()):
        if is_unsigned:
            return wl_build_ui_to_fp(self.builder, val, target_ty)
        return wl_build_si_to_fp(self.builder, val, target_ty)
    if (vk == wl_float_type_kind() or vk == wl_double_type_kind()) and (tk == wl_float_type_kind() or tk == wl_double_type_kind()):
        return wl_build_fp_cast(self.builder, val, target_ty)
    val

fn Codegen.mir_build_raw_shift(self: Codegen, op: i32, l: i64, r: i64, is_unsigned: bool) -> i64:
    if op == BinaryOp.OP_SHL:
        return wl_build_shl(self.builder, l, r)
    if is_unsigned:
        return wl_build_lshr(self.builder, l, r)
    wl_build_ashr(self.builder, l, r)

fn Codegen.mir_build_total_shift(self: Codegen, op: i32, lhs: i64, rhs: i64, is_unsigned: bool) -> i64:
    let shift_ty = wl_type_of(lhs)
    let rhs_ty = wl_type_of(rhs)
    if wl_get_type_kind(shift_ty) != wl_integer_type_kind() or wl_get_type_kind(rhs_ty) != wl_integer_type_kind():
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    let width = wl_get_int_type_width(shift_ty)
    if width <= 0:
        self.had_error = 1
        return wl_get_undef(shift_ty)

    let rhs_width = wl_get_int_type_width(rhs_ty)
    if rhs_width <= 0:
        self.had_error = 1
        return wl_get_undef(shift_ty)

    let cmp_ty = if rhs_width > width: rhs_ty else: shift_ty
    let rhs_for_cmp = self.coerce_int_ext(rhs, cmp_ty, true)
    let too_big = wl_build_icmp(self.builder, wl_int_uge(), rhs_for_cmp, wl_const_int(cmp_ty, width as i64, 0))
    let rhs_for_shift = self.coerce_int_ext(rhs, shift_ty, true)
    let masked_count = wl_build_and(self.builder, rhs_for_shift, wl_const_int(shift_ty, (width - 1) as i64, 0))
    let shifted = self.mir_build_raw_shift(op, lhs, masked_count, is_unsigned)

    if op == BinaryOp.OP_SHL or is_unsigned:
        return wl_build_select(self.builder, too_big, wl_const_int(shift_ty, 0, 0), shifted)

    let sign_count = wl_const_int(shift_ty, (width - 1) as i64, 0)
    let sign_fill = wl_build_ashr(self.builder, lhs, sign_count)
    wl_build_select(self.builder, too_big, sign_fill, shifted)

fn Codegen.mir_build_bin_op(self: Codegen, op: i32, lhs: i64, rhs: i64, is_unsigned: bool, lhs_sema: i32, rhs_sema: i32) -> i64:
    let lk = wl_get_type_kind(wl_type_of(lhs))
    let rk = wl_get_type_kind(wl_type_of(rhs))

    // Pointer arithmetic: ptr +/- int → GEP
    if lk == wl_pointer_type_kind() and rk == wl_integer_type_kind():
        if op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB:
            let idx_val = if op == BinaryOp.OP_SUB: wl_build_neg(self.builder, rhs) else: rhs
            let indices: Vec[i64] = Vec.new()
            indices.push(idx_val)
            return wl_build_gep(self.builder, wl_i8_type(self.context), lhs, vec_data_i64(&indices), 1)

    if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ:
        let sema_cmp = self.mir_build_eq_from_sema(op, lhs, rhs, lhs_sema, rhs_sema)
        if sema_cmp != 0:
            return sema_cmp
        if lk == wl_pointer_type_kind() and rk == wl_integer_type_kind():
            if self.is_const_int_value(rhs) and wl_const_int_sext_val(rhs) == 0:
                let cmp_rhs = wl_const_null(wl_type_of(lhs))
                return wl_build_icmp(self.builder, if op == BinaryOp.OP_EQ: wl_int_eq() else: wl_int_ne(), lhs, cmp_rhs)
        if rk == wl_pointer_type_kind() and lk == wl_integer_type_kind():
            if self.is_const_int_value(lhs) and wl_const_int_sext_val(lhs) == 0:
                let cmp_lhs = wl_const_null(wl_type_of(rhs))
                return wl_build_icmp(self.builder, if op == BinaryOp.OP_EQ: wl_int_eq() else: wl_int_ne(), cmp_lhs, rhs)

    let is_float = lk == wl_float_type_kind() or lk == wl_double_type_kind() or rk == wl_float_type_kind() or rk == wl_double_type_kind()
    if is_float:
        let common_float_ty =
            if lk == wl_double_type_kind() or rk == wl_double_type_kind():
                wl_f64_type(self.context)
            else:
                wl_f32_type(self.context)
        let lhs_float = self.coerce_float_operand_to(lhs, common_float_ty, self.mir_sema_type_is_unsigned(lhs_sema))
        let rhs_float = self.coerce_float_operand_to(rhs, common_float_ty, self.mir_sema_type_is_unsigned(rhs_sema))
        if op == BinaryOp.OP_ADD or op == BinaryOp.OP_ADD_WRAP: return wl_build_fadd(self.builder, lhs_float, rhs_float)
        if op == BinaryOp.OP_SUB or op == BinaryOp.OP_SUB_WRAP: return wl_build_fsub(self.builder, lhs_float, rhs_float)
        if op == BinaryOp.OP_MUL or op == BinaryOp.OP_MUL_WRAP: return wl_build_fmul(self.builder, lhs_float, rhs_float)
        if op == BinaryOp.OP_DIV: return wl_build_fdiv(self.builder, lhs_float, rhs_float)
        if op == BinaryOp.OP_MOD: return wl_build_frem(self.builder, lhs_float, rhs_float)
        if op == BinaryOp.OP_EQ: return wl_build_fcmp(self.builder, wl_real_oeq(), lhs_float, rhs_float)
        if op == BinaryOp.OP_NEQ: return wl_build_fcmp(self.builder, wl_real_one(), lhs_float, rhs_float)
        if op == BinaryOp.OP_LT: return wl_build_fcmp(self.builder, wl_real_olt(), lhs_float, rhs_float)
        if op == BinaryOp.OP_GT: return wl_build_fcmp(self.builder, wl_real_ogt(), lhs_float, rhs_float)
        if op == BinaryOp.OP_LTE: return wl_build_fcmp(self.builder, wl_real_ole(), lhs_float, rhs_float)
        if op == BinaryOp.OP_GTE: return wl_build_fcmp(self.builder, wl_real_oge(), lhs_float, rhs_float)
        return wl_get_undef(wl_i32_type(self.context))

    if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ:
        let lhs_ty = wl_type_of(lhs)
        let rhs_ty = wl_type_of(rhs)
        if lhs_ty == rhs_ty:
            let cmp_kind = wl_get_type_kind(lhs_ty)
            if cmp_kind == wl_struct_type_kind() or cmp_kind == wl_array_type_kind():
                return self.compare_aggregate_eq(lhs, rhs, op)

    if op == BinaryOp.OP_SHL or op == BinaryOp.OP_SHR:
        return self.mir_build_total_shift(op, lhs, rhs, is_unsigned)

    // Coerce both operands to the wider integer type (never truncate)
    let lty = wl_type_of(lhs)
    let rty = wl_type_of(rhs)
    var wider_ty = lty
    if wl_get_type_kind(lty) == wl_integer_type_kind() and wl_get_type_kind(rty) == wl_integer_type_kind():
        if wl_get_int_type_width(rty) > wl_get_int_type_width(lty):
            wider_ty = rty
    let lhs_unsigned = is_unsigned or self.mir_sema_type_is_unsigned(lhs_sema)
    let rhs_unsigned = is_unsigned or self.mir_sema_type_is_unsigned(rhs_sema)
    let l = self.coerce_int_ext(lhs, wider_ty, lhs_unsigned)
    let r = self.coerce_int_ext(rhs, wider_ty, rhs_unsigned)
    if op == BinaryOp.OP_ADD_WRAP: return wl_build_add(self.builder, l, r)
    if op == BinaryOp.OP_SUB_WRAP: return wl_build_sub(self.builder, l, r)
    if op == BinaryOp.OP_MUL_WRAP: return wl_build_mul(self.builder, l, r)
    if op == BinaryOp.OP_ADD_SAT or op == BinaryOp.OP_SUB_SAT:
        let sat_width = wl_get_int_type_width(wider_ty)
        let sat_prefix = if op == BinaryOp.OP_ADD_SAT: if is_unsigned: "llvm.uadd.sat.i" else: "llvm.sadd.sat.i" else if is_unsigned: "llvm.usub.sat.i" else: "llvm.ssub.sat.i"
        let sat_fn_name = if sat_width == 8: sat_prefix ++ "8" else if sat_width == 16: sat_prefix ++ "16" else if sat_width == 32: sat_prefix ++ "32" else: sat_prefix ++ "64"
        let sat_sym = self.intern.intern(sat_fn_name)
        let sat_fv = self.fn_values.get(sat_sym)
        let sat_ft = self.fn_fn_types.get(sat_sym)
        if sat_fv.is_some() and sat_ft.is_some():
            let sat_args: Vec[i64] = Vec.new()
            sat_args.push(l)
            sat_args.push(r)
            return wl_build_call(self.builder, sat_ft.unwrap() as i64, sat_fv.unwrap() as i64, vec_data_i64(&sat_args), 2)
        else:
            let sat_pts: Vec[i64] = Vec.new()
            sat_pts.push(wider_ty)
            sat_pts.push(wider_ty)
            let sat_fnt = wl_function_type(wider_ty, vec_data_i64(&sat_pts), 2, 0)
            let sat_func = wl_add_function(self.llmod, sat_fn_name, sat_fnt)
            self.fn_values.insert(sat_sym, sat_func)
            self.fn_fn_types.insert(sat_sym, sat_fnt)
            let sat_args: Vec[i64] = Vec.new()
            sat_args.push(l)
            sat_args.push(r)
            return wl_build_call(self.builder, sat_fnt, sat_func, vec_data_i64(&sat_args), 2)
    if op == BinaryOp.OP_MUL_SAT:
        // Widening multiply + clamp: multiply in 2x width, clamp to [MIN, MAX], truncate
        let ms_width = wl_get_int_type_width(wider_ty)
        let ms_dbl_width = ms_width * 2
        let ms_dbl_ty = if ms_dbl_width == 16: wl_i16_type(self.context) else if ms_dbl_width == 32: wl_i32_type(self.context) else if ms_dbl_width == 64: wl_i64_type(self.context) else: wl_i128_type(self.context)
        let ms_wide_l = if is_unsigned: wl_build_zext(self.builder, l, ms_dbl_ty) else: wl_build_sext(self.builder, l, ms_dbl_ty)
        let ms_wide_r = if is_unsigned: wl_build_zext(self.builder, r, ms_dbl_ty) else: wl_build_sext(self.builder, r, ms_dbl_ty)
        let ms_wide_result = wl_build_mul(self.builder, ms_wide_l, ms_wide_r)
        // Clamp using saturating add of 0 in the original width (truncate + sat)
        // Actually: just truncate and check for overflow with icmp
        if is_unsigned:
            let ms_max_val = wl_const_int(ms_dbl_ty, ((1 as i64) << (ms_width as u32)) - 1, 0)
            let ms_overflow = wl_build_icmp(self.builder, wl_int_ugt(), ms_wide_result, ms_max_val)
            let ms_clamped = wl_build_select(self.builder, ms_overflow, ms_max_val, ms_wide_result)
            return wl_build_trunc(self.builder, ms_clamped, wider_ty)
        else:
            let ms_half = ms_width as i64 - 1
            let ms_max_val = wl_const_int(ms_dbl_ty, ((1 as i64) << (ms_half as u32)) - 1, 0)
            let ms_min_val = wl_const_int(ms_dbl_ty, -((1 as i64) << (ms_half as u32)), 1)
            let ms_too_big = wl_build_icmp(self.builder, wl_int_sgt(), ms_wide_result, ms_max_val)
            let ms_too_small = wl_build_icmp(self.builder, wl_int_slt(), ms_wide_result, ms_min_val)
            let ms_clamped_hi = wl_build_select(self.builder, ms_too_big, ms_max_val, ms_wide_result)
            let ms_clamped = wl_build_select(self.builder, ms_too_small, ms_min_val, ms_clamped_hi)
            return wl_build_trunc(self.builder, ms_clamped, wider_ty)
    if op == BinaryOp.OP_ADD:
        if is_unsigned: return wl_build_add(self.builder, l, r)
        return wl_build_nsw_add(self.builder, l, r)
    if op == BinaryOp.OP_SUB:
        if is_unsigned: return wl_build_sub(self.builder, l, r)
        return wl_build_nsw_sub(self.builder, l, r)
    if op == BinaryOp.OP_MUL:
        if is_unsigned: return wl_build_mul(self.builder, l, r)
        return wl_build_nsw_mul(self.builder, l, r)
    if op == BinaryOp.OP_DIV:
        if is_unsigned: return wl_build_udiv(self.builder, l, r)
        return wl_build_sdiv(self.builder, l, r)
    if op == BinaryOp.OP_MOD:
        if is_unsigned: return wl_build_urem(self.builder, l, r)
        return wl_build_srem(self.builder, l, r)
    if op == BinaryOp.OP_EQ: return wl_build_icmp(self.builder, wl_int_eq(), l, r)
    if op == BinaryOp.OP_NEQ: return wl_build_icmp(self.builder, wl_int_ne(), l, r)
    if op == BinaryOp.OP_LT:
        if is_unsigned: return wl_build_icmp(self.builder, wl_int_ult(), l, r)
        return wl_build_icmp(self.builder, wl_int_slt(), l, r)
    if op == BinaryOp.OP_GT:
        if is_unsigned: return wl_build_icmp(self.builder, wl_int_ugt(), l, r)
        return wl_build_icmp(self.builder, wl_int_sgt(), l, r)
    if op == BinaryOp.OP_LTE:
        if is_unsigned: return wl_build_icmp(self.builder, wl_int_ule(), l, r)
        return wl_build_icmp(self.builder, wl_int_sle(), l, r)
    if op == BinaryOp.OP_GTE:
        if is_unsigned: return wl_build_icmp(self.builder, wl_int_uge(), l, r)
        return wl_build_icmp(self.builder, wl_int_sge(), l, r)
    if op == BinaryOp.OP_AND or op == BinaryOp.OP_BIT_AND: return wl_build_and(self.builder, l, r)
    if op == BinaryOp.OP_OR or op == BinaryOp.OP_BIT_OR: return wl_build_or(self.builder, l, r)
    if op == BinaryOp.OP_BIT_XOR: return wl_build_xor(self.builder, l, r)
    if op == BinaryOp.OP_CONCAT: return self.mir_str_concat(lhs, rhs)
    with_eprint("error: unsupported MIR binary op '" ++ mir_binop_name(op) ++ "' reached LLVM codegen")
    self.had_error = 1
    wl_get_undef(wl_i32_type(self.context))

fn Codegen.mir_str_concat(self: Codegen, lhs: i64, rhs: i64) -> i64:
    let str_ty = self.resolve_named_type(self.intern.intern("str"))
    let lhs_v = lhs
    let rhs_v = rhs
    let concat_sym = self.intern.intern("with_str_concat")
    let fv = self.fn_values.get(concat_sym)
    let ft = self.fn_fn_types.get(concat_sym)
    if fv.is_some() and ft.is_some():
        let args: Vec[i64] = Vec.new()
        args.push(lhs_v)
        args.push(rhs_v)
        return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&args), 2)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(str_ty)
    param_types.push(str_ty)
    let fn_type = wl_function_type(str_ty, vec_data_i64(&param_types), 2, 0)
    let func = wl_add_function(self.llmod, "with_str_concat", fn_type)
    self.fn_values.insert(concat_sym, func)
    self.fn_fn_types.insert(concat_sym, fn_type)
    let args: Vec[i64] = Vec.new()
    args.push(lhs_v)
    args.push(rhs_v)
    wl_build_call(self.builder, fn_type, func, vec_data_i64(&args), 2)

fn Codegen.mir_display_resolved_type(self: Codegen, sema_ty: i32) -> i32:
    if sema_ty <= 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    if resolved > 0:
        return resolved
    self.sema.resolve_alias(sema_ty as TypeId) as i32

fn Codegen.mir_display_type_kind(self: Codegen, resolved: i32) -> i32:
    if resolved <= 0:
        return 0
    let tk = self.mir_input.mir_get_type_kind(resolved)
    if tk != 0:
        return tk
    self.sema.get_type_kind(resolved)

fn Codegen.mir_struct_field_sema_type(self: Codegen, struct_sema_ty: i32, field_idx: i32) -> i32:
    if struct_sema_ty <= 0 or field_idx < 0:
        return 0
    let resolved = self.mir_display_resolved_type(struct_sema_ty)
    let tk = self.mir_display_type_kind(resolved)
    if tk == TypeKind.TY_STRUCT:
        let field_start = self.mir_input.mir_get_type_d1(resolved)
        let field_count = self.mir_input.mir_get_type_d2(resolved)
        if field_idx < field_count:
            return self.mir_input.mir_get_type_extra(field_start + field_idx * 3 + 1)
        return 0
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.mir_input.mir_get_type_d0(resolved)
        if base_sym > 0 and self.sema.named_types.contains(base_sym):
            let base_tid = self.sema.named_types.get(base_sym).unwrap()
            if self.sema.get_type_kind(base_tid) == TypeKind.TY_STRUCT:
                let field_start = self.sema.get_type_d1(base_tid)
                let field_count = self.sema.get_type_d2(base_tid)
                if field_idx < field_count:
                    return self.sema.type_extra.get((field_start + field_idx * 3 + 1) as i64)
    0

fn Codegen.mir_enum_variant_count(self: Codegen, enum_sema_ty: i32) -> i32:
    if enum_sema_ty <= 0:
        return 0
    let resolved = self.mir_display_resolved_type(enum_sema_ty)
    let tk = self.mir_display_type_kind(resolved)
    if tk == TypeKind.TY_ENUM:
        return self.mir_input.mir_get_type_d2(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.mir_input.mir_get_type_d0(resolved)
        if base_sym > 0 and self.sema.named_types.contains(base_sym):
            let base_tid = self.sema.named_types.get(base_sym).unwrap()
            if self.sema.get_type_kind(base_tid) == TypeKind.TY_ENUM:
                return self.sema.get_type_d2(base_tid)
    0

fn Codegen.mir_enum_variant_name(self: Codegen, enum_sema_ty: i32, variant_idx: i32) -> str:
    if enum_sema_ty <= 0 or variant_idx < 0:
        return "<invalid>"
    let resolved = self.mir_display_resolved_type(enum_sema_ty)
    let tk = self.mir_display_type_kind(resolved)
    if tk == TypeKind.TY_ENUM:
        let te_start = self.mir_input.mir_get_type_d1(resolved)
        let variant_count = self.mir_input.mir_get_type_d2(resolved)
        var pos = te_start
        for vi in 0..variant_count:
            let variant_name = self.mir_input.mir_get_type_extra(pos)
            let payload_count = self.mir_input.mir_get_type_extra(pos + 1)
            if vi == variant_idx:
                return self.sema_symbol_text(variant_name)
            pos = pos + 2 + payload_count
        return "<invalid>"
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.mir_input.mir_get_type_d0(resolved)
        if base_sym > 0 and self.sema.named_types.contains(base_sym):
            let base_tid = self.sema.named_types.get(base_sym).unwrap()
            if self.sema.get_type_kind(base_tid) == TypeKind.TY_ENUM:
                let te_start = self.sema.get_type_d1(base_tid)
                let variant_count = self.sema.get_type_d2(base_tid)
                var pos = te_start
                for vi in 0..variant_count:
                    let variant_name = self.sema.type_extra.get(pos as i64)
                    let payload_count = self.sema.type_extra.get((pos + 1) as i64)
                    if vi == variant_idx:
                        return self.sema_symbol_text(variant_name)
                    pos = pos + 2 + payload_count
    "<invalid>"

fn Codegen.mir_enum_variant_payload_count(self: Codegen, enum_sema_ty: i32, variant_idx: i32) -> i32:
    if enum_sema_ty <= 0 or variant_idx < 0:
        return 0
    let resolved = self.mir_display_resolved_type(enum_sema_ty)
    let tk = self.mir_display_type_kind(resolved)
    if tk == TypeKind.TY_ENUM:
        let te_start = self.mir_input.mir_get_type_d1(resolved)
        let variant_count = self.mir_input.mir_get_type_d2(resolved)
        var pos = te_start
        for vi in 0..variant_count:
            let payload_count = self.mir_input.mir_get_type_extra(pos + 1)
            if vi == variant_idx:
                return payload_count
            pos = pos + 2 + payload_count
        return 0
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.mir_input.mir_get_type_d0(resolved)
        if base_sym > 0 and self.sema.named_types.contains(base_sym):
            let base_tid = self.sema.named_types.get(base_sym).unwrap()
            if self.sema.get_type_kind(base_tid) == TypeKind.TY_ENUM:
                let te_start = self.sema.get_type_d1(base_tid)
                let variant_count = self.sema.get_type_d2(base_tid)
                var pos = te_start
                for vi in 0..variant_count:
                    let payload_count = self.sema.type_extra.get((pos + 1) as i64)
                    if vi == variant_idx:
                        return payload_count
                    pos = pos + 2 + payload_count
    0

fn Codegen.mir_enum_variant_discriminant(self: Codegen, enum_sema_ty: i32, variant_idx: i32) -> i64:
    if enum_sema_ty <= 0 or variant_idx < 0:
        return 0
    let resolved = self.mir_display_resolved_type(enum_sema_ty)
    let tk = self.mir_display_type_kind(resolved)
    var enum_sym = 0
    if tk == TypeKind.TY_ENUM:
        enum_sym = self.mir_input.mir_get_type_d0(resolved)
    else if tk == TypeKind.TY_GENERIC_INST:
        enum_sym = self.mir_input.mir_get_type_d0(resolved)
    let cg_sym = self.sema_sym_to_codegen_sym(enum_sym)
    if cg_sym > 0:
        let de_opt = self.disc_enum_type_map.get(cg_sym)
        if de_opt.is_some():
            let de_idx = de_opt.unwrap()
            let v_start = self.disc_enum_variant_starts.get(de_idx as i64)
            let v_count = self.disc_enum_variant_counts.get(de_idx as i64)
            if variant_idx < v_count:
                return self.disc_enum_variant_values.get((v_start + variant_idx) as i64) as i64
    variant_idx as i64

fn Codegen.mir_enum_tag_value(self: Codegen, val: i64) -> i64:
    let val_ty = wl_type_of(val)
    let vk = wl_get_type_kind(val_ty)
    if vk == wl_integer_type_kind():
        return val
    if vk == wl_struct_type_kind() and wl_count_struct_elem_types(val_ty) > 0:
        return wl_build_extract_value(self.builder, val, 0)
    wl_const_int(wl_i32_type(self.context), 0, 0)

fn Codegen.gen_enum_payload_field_value(self: Codegen, enum_val: i64, enum_sema_ty: i32, variant_idx: i32, field_idx: i32) -> i64:
    if field_idx < 0:
        return 0
    let payload_ty = self.mir_enum_variant_payload_llvm_type(enum_sema_ty, variant_idx)
    if payload_ty == 0:
        return 0
    let enum_ty = wl_type_of(enum_val)
    if wl_get_type_kind(enum_ty) != wl_struct_type_kind() or wl_count_struct_elem_types(enum_ty) < 2:
        return 0
    let enum_ptr = self.create_entry_alloca(enum_ty)
    wl_build_store(self.builder, enum_val, enum_ptr)
    let data_ptr = wl_build_struct_gep(self.builder, enum_ty, enum_ptr, 1)
    let payload_ptr = wl_build_bitcast(self.builder, data_ptr, wl_ptr_type(self.context))
    if wl_get_type_kind(payload_ty) == wl_struct_type_kind():
        let field_count = wl_count_struct_elem_types(payload_ty)
        if field_idx >= field_count:
            return 0
        let field_ty = wl_struct_get_type_at(payload_ty, field_idx)
        let field_ptr = wl_build_struct_gep(self.builder, payload_ty, payload_ptr, field_idx)
        return wl_build_load(self.builder, field_ty, field_ptr)
    if field_idx == 0:
        return wl_build_load(self.builder, payload_ty, payload_ptr)
    0

fn Codegen.coerce_val_to_str(self: Codegen, val: i64, str_ty: i64) -> i64:
    let val_ty = wl_type_of(val)
    let vk = wl_get_type_kind(val_ty)
    var fn_name = "with_fmt_i32"
    var coerced = val
    var arg_ty = wl_i32_type(self.context)
    if vk == wl_integer_type_kind():
        let bit_w = wl_get_int_type_width(val_ty)
        if bit_w == 1:
            // Bool (i1) → with_fmt_bool
            fn_name = "with_fmt_bool"
            coerced = self.coerce_int_ext(val, wl_i32_type(self.context), false)
        else if bit_w <= 32:
            fn_name = "with_fmt_i32"
            coerced = self.coerce_int_ext(val, wl_i32_type(self.context), false)
        else:
            fn_name = "with_fmt_i64"
            arg_ty = wl_i64_type(self.context)
            coerced = self.coerce_int_ext(val, arg_ty, false)
    else:
        if vk == wl_float_type_kind() or vk == wl_double_type_kind():
            fn_name = "with_fmt_f64"
            arg_ty = wl_f64_type(self.context)
            coerced = if vk == wl_float_type_kind(): wl_build_fp_cast(self.builder, val, arg_ty) else: val
        else:
            if val_ty == str_ty:
                return val
            if vk == wl_pointer_type_kind():
                return self.coerce_ptr_to_str(val)
            return self.gen_string_literal_raw("<unsupported>")
    let sym = self.intern.intern(fn_name)
    let fv = self.fn_values.get(sym)
    let ft = self.fn_fn_types.get(sym)
    if fv.is_some() and ft.is_some():
        let a: Vec[i64] = Vec.new()
        a.push(coerced)
        return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&a), 1)
    let pts: Vec[i64] = Vec.new()
    pts.push(arg_ty)
    let fnt = wl_function_type(str_ty, vec_data_i64(&pts), 1, 0)
    let func = wl_add_function(self.llmod, fn_name, fnt)
    self.fn_values.insert(sym, func)
    self.fn_fn_types.insert(sym, fnt)
    let a: Vec[i64] = Vec.new()
    a.push(coerced)
    wl_build_call(self.builder, fnt, func, vec_data_i64(&a), 1)

fn Codegen.call_runtime_str_fn(self: Codegen, fn_name: str, arg: i64, str_ty: i64) -> i64:
    let sym = self.intern.intern(fn_name)
    let fv = self.fn_values.get(sym)
    let ft = self.fn_fn_types.get(sym)
    if fv.is_some() and ft.is_some():
        let a: Vec[i64] = Vec.new()
        a.push(arg)
        return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&a), 1)
    let pts: Vec[i64] = Vec.new()
    pts.push(wl_type_of(arg))
    let fnt = wl_function_type(str_ty, vec_data_i64(&pts), 1, 0)
    let func = wl_add_function(self.llmod, fn_name, fnt)
    self.fn_values.insert(sym, func)
    self.fn_fn_types.insert(sym, fnt)
    let a: Vec[i64] = Vec.new()
    a.push(arg)
    wl_build_call(self.builder, fnt, func, vec_data_i64(&a), 1)

fn Codegen.coerce_typed_val_to_str(self: Codegen, val: i64, sema_ty: i32, str_ty: i64) -> i64:
    var effective_sema_ty = sema_ty
    var resolved = self.mir_display_resolved_type(effective_sema_ty)
    var tk = self.mir_display_type_kind(resolved)
    let val_ty = wl_type_of(val)
    if wl_get_type_kind(val_ty) == wl_struct_type_kind():
        let enum_sym = self.enum_by_llvm.get(val_ty)
        if enum_sym.is_some() and (tk == 0 or (tk != TypeKind.TY_ENUM and tk != TypeKind.TY_GENERIC_INST and tk != TypeKind.TY_STRUCT)):
            let recovered = self.mir_find_named_type_text(self.intern.resolve(enum_sym.unwrap()))
            if recovered > 0:
                effective_sema_ty = recovered
                resolved = recovered
                tk = self.mir_display_type_kind(resolved)
    if tk == TypeKind.TY_STR:
        if val_ty == str_ty:
            return val
        return self.call_runtime_str_fn("with_fmt_str", val, str_ty)
    if tk == TypeKind.TY_STRUCT:
        return self.gen_debug_struct(val, resolved, str_ty)
    if tk == TypeKind.TY_ENUM:
        return self.gen_display_enum(val, effective_sema_ty, str_ty)
    if tk == TypeKind.TY_GENERIC_INST and self.mir_enum_variant_count(effective_sema_ty) > 0:
        return self.gen_display_enum(val, effective_sema_ty, str_ty)
    self.coerce_val_to_str(val, str_ty)

fn Codegen.gen_debug_format(self: Codegen, val: i64, sema_ty: i32, str_ty: i64) -> i64:
    // Generate debug formatting based on sema type.
    let resolved = self.mir_display_resolved_type(sema_ty)
    let tk = self.mir_display_type_kind(resolved)

    // str → quoted
    if resolved == self.sema.ty_str or tk == TypeKind.TY_STR:
        return self.call_runtime_str_fn("with_fmt_str_debug", val, str_ty)

    // Struct → "TypeName { field: val, field: val }"
    if tk == TypeKind.TY_STRUCT:
        return self.gen_debug_struct(val, resolved, str_ty)

    // Enums use their compiler-generated variant formatter for now.
    if tk == TypeKind.TY_ENUM or (tk == TypeKind.TY_GENERIC_INST and self.mir_enum_variant_count(sema_ty) > 0):
        return self.gen_debug_enum(val, sema_ty, str_ty)

    // Primitives (int, float, bool) → same as default display
    self.coerce_typed_val_to_str(val, sema_ty, str_ty)

fn Codegen.gen_debug_struct(self: Codegen, val: i64, sema_ty: i32, str_ty: i64) -> i64:
    // Generate "TypeName { field1: val1, field2: val2 }"
    let type_name_sym = self.mir_input.mir_get_type_d0(sema_ty)
    var type_name = ""
    if type_name_sym > 0:
        type_name = self.sema_symbol_text(type_name_sym)

    // Find struct index in codegen tables
    let cg_sym = self.intern.intern(type_name)
    let st_opt = self.struct_type_map.get(cg_sym)
    if not st_opt.is_some():
        // Unknown struct — return type name only
        return self.gen_string_literal_raw(type_name ++ " " ++ lbrace() ++ " ... " ++ rbrace())

    let struct_idx = st_opt.unwrap()
    let f_start = self.struct_field_starts.get(struct_idx as i64)
    let f_count = self.struct_field_counts.get(struct_idx as i64)

    // Build: "TypeName { "
    var result = self.gen_string_literal_raw(type_name ++ " " ++ lbrace() ++ " ")

    var fi = 0
    while fi < f_count:
        let f_name_sym = self.struct_field_names.get((f_start + fi) as i64)
        let f_name = self.intern.resolve(f_name_sym)

        // Separator
        if fi > 0:
            result = self.mir_str_concat(result, self.gen_string_literal_raw(", "))

        // "field_name: "
        result = self.mir_str_concat(result, self.gen_string_literal_raw(f_name ++ ": "))

        // Extract field value and format it
        let field_val = wl_build_extract_value(self.builder, val, fi)
        let field_sema_ty = self.mir_struct_field_sema_type(sema_ty, fi)
        let field_str = self.coerce_typed_val_to_str(field_val, field_sema_ty, str_ty)
        result = self.mir_str_concat(result, field_str)
        fi = fi + 1

    // Close " }"
    result = self.mir_str_concat(result, self.gen_string_literal_raw(" " ++ rbrace()))
    result

fn Codegen.gen_debug_enum(self: Codegen, val: i64, sema_ty: i32, str_ty: i64) -> i64:
    self.gen_display_enum(val, sema_ty, str_ty)

fn Codegen.gen_display_enum_variant(self: Codegen, val: i64, enum_sema_ty: i32, variant_idx: i32, str_ty: i64) -> i64:
    let variant_name = self.mir_enum_variant_name(enum_sema_ty, variant_idx)
    var result = self.gen_string_literal_raw(variant_name)
    let payload_count = self.mir_enum_variant_payload_count(enum_sema_ty, variant_idx)
    if payload_count <= 0:
        return result
    result = self.mir_str_concat(result, self.gen_string_literal_raw("("))
    for pi in 0..payload_count:
        if pi > 0:
            result = self.mir_str_concat(result, self.gen_string_literal_raw(", "))
        let payload_val = self.gen_enum_payload_field_value(val, enum_sema_ty, variant_idx, pi)
        let payload_sema_ty = self.mir_enum_payload_sema_type(enum_sema_ty, variant_idx, pi)
        let payload_str = self.coerce_typed_val_to_str(payload_val, payload_sema_ty, str_ty)
        result = self.mir_str_concat(result, payload_str)
    result = self.mir_str_concat(result, self.gen_string_literal_raw(")"))
    result

fn Codegen.gen_display_enum(self: Codegen, val: i64, enum_sema_ty: i32, str_ty: i64) -> i64:
    let variant_count = self.mir_enum_variant_count(enum_sema_ty)
    if variant_count <= 0:
        return self.coerce_val_to_str(val, str_ty)
    let tag_val = self.mir_enum_tag_value(val)
    let tag_ty = wl_type_of(tag_val)
    let result_ptr = self.create_entry_alloca(str_ty)
    let merge_bb = wl_append_bb(self.context, self.current_function, "fmt.enum.merge")
    let default_bb = wl_append_bb(self.context, self.current_function, "fmt.enum.default")
    var vi = 0
    while vi < variant_count:
        let case_bb = wl_append_bb(self.context, self.current_function, "fmt.enum.case")
        let else_bb = if vi + 1 < variant_count: wl_append_bb(self.context, self.current_function, "fmt.enum.next") else: default_bb
        let disc = self.mir_enum_variant_discriminant(enum_sema_ty, vi)
        let cond = wl_build_icmp(self.builder, wl_int_eq(), tag_val, wl_const_int(tag_ty, disc, 0))
        wl_build_cond_br(self.builder, cond, case_bb, else_bb)
        wl_position_at_end(self.builder, case_bb)
        let case_str = self.gen_display_enum_variant(val, enum_sema_ty, vi, str_ty)
        wl_build_store(self.builder, case_str, result_ptr)
        wl_build_br(self.builder, merge_bb)
        if vi + 1 < variant_count:
            wl_position_at_end(self.builder, else_bb)
        vi = vi + 1
    wl_position_at_end(self.builder, default_bb)
    wl_build_store(self.builder, self.gen_string_literal_raw("<invalid enum>"), result_ptr)
    wl_build_br(self.builder, merge_bb)
    wl_position_at_end(self.builder, merge_bb)
    wl_build_load(self.builder, str_ty, result_ptr)

fn Codegen.gen_fmt_with_spec(self: Codegen, val: i64, flags: i32, width: i32, precision: i32, mode: i32, str_ty: i64) -> i64:
    // Dispatch to runtime with_fmt_*_spec based on LLVM value type.
    let val_ty = wl_type_of(val)
    let vk = wl_get_type_kind(val_ty)
    let i32_ty = wl_i32_type(self.context)
    let i64_ty = wl_i64_type(self.context)

    if vk == wl_integer_type_kind():
        let bit_w = wl_get_int_type_width(val_ty)
        // Integer spec: with_fmt_int_spec(val, is_unsigned, flags, width, precision, mode)
        var coerced_val = self.coerce_int_ext(val, i64_ty, false)
        let is_unsigned = 0
        let fn_name = "with_fmt_int_spec"
        let sym = self.intern.intern(fn_name)
        let fv = self.fn_values.get(sym)
        let ft = self.fn_fn_types.get(sym)
        if fv.is_some() and ft.is_some():
            let a: Vec[i64] = Vec.new()
            a.push(coerced_val)
            a.push(wl_const_int(i32_ty, is_unsigned as i64, 0))
            a.push(wl_const_int(i64_ty, flags as i64, 0))
            a.push(wl_const_int(i32_ty, width as i64, 0))
            a.push(wl_const_int(i32_ty, precision as i64, 0))
            a.push(wl_const_int(i32_ty, mode as i64, 0))
            return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&a), 6)
        let pts: Vec[i64] = Vec.new()
        pts.push(i64_ty)
        pts.push(i32_ty)
        pts.push(i64_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        let fnt = wl_function_type(str_ty, vec_data_i64(&pts), 6, 0)
        let func = wl_add_function(self.llmod, fn_name, fnt)
        self.fn_values.insert(sym, func)
        self.fn_fn_types.insert(sym, fnt)
        let a: Vec[i64] = Vec.new()
        a.push(coerced_val)
        a.push(wl_const_int(i32_ty, is_unsigned as i64, 0))
        a.push(wl_const_int(i64_ty, flags as i64, 0))
        a.push(wl_const_int(i32_ty, width as i64, 0))
        a.push(wl_const_int(i32_ty, precision as i64, 0))
        a.push(wl_const_int(i32_ty, mode as i64, 0))
        return wl_build_call(self.builder, fnt, func, vec_data_i64(&a), 6)

    if vk == wl_float_type_kind() or vk == wl_double_type_kind():
        // Float spec: with_fmt_f64_spec(val, flags, width, precision, mode)
        let f64_ty = wl_f64_type(self.context)
        var coerced_val = if vk == wl_float_type_kind(): wl_build_fp_cast(self.builder, val, f64_ty) else: val
        let fn_name = "with_fmt_f64_spec"
        let sym = self.intern.intern(fn_name)
        let fv = self.fn_values.get(sym)
        let ft = self.fn_fn_types.get(sym)
        if fv.is_some() and ft.is_some():
            let a: Vec[i64] = Vec.new()
            a.push(coerced_val)
            a.push(wl_const_int(i64_ty, flags as i64, 0))
            a.push(wl_const_int(i32_ty, width as i64, 0))
            a.push(wl_const_int(i32_ty, precision as i64, 0))
            a.push(wl_const_int(i32_ty, mode as i64, 0))
            return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&a), 5)
        let pts: Vec[i64] = Vec.new()
        pts.push(f64_ty)
        pts.push(i64_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        let fnt = wl_function_type(str_ty, vec_data_i64(&pts), 5, 0)
        let func = wl_add_function(self.llmod, fn_name, fnt)
        self.fn_values.insert(sym, func)
        self.fn_fn_types.insert(sym, fnt)
        let a: Vec[i64] = Vec.new()
        a.push(coerced_val)
        a.push(wl_const_int(i64_ty, flags as i64, 0))
        a.push(wl_const_int(i32_ty, width as i64, 0))
        a.push(wl_const_int(i32_ty, precision as i64, 0))
        a.push(wl_const_int(i32_ty, mode as i64, 0))
        return wl_build_call(self.builder, fnt, func, vec_data_i64(&a), 5)

    // String spec: with_fmt_str_spec(val, flags, width, precision)
    if val_ty == str_ty:
        let fn_name = "with_fmt_str_spec"
        let sym = self.intern.intern(fn_name)
        let fv = self.fn_values.get(sym)
        let ft = self.fn_fn_types.get(sym)
        if fv.is_some() and ft.is_some():
            let a: Vec[i64] = Vec.new()
            a.push(val)
            a.push(wl_const_int(i64_ty, flags as i64, 0))
            a.push(wl_const_int(i32_ty, width as i64, 0))
            a.push(wl_const_int(i32_ty, precision as i64, 0))
            return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&a), 4)
        let pts: Vec[i64] = Vec.new()
        pts.push(str_ty)
        pts.push(i64_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        let fnt = wl_function_type(str_ty, vec_data_i64(&pts), 4, 0)
        let func = wl_add_function(self.llmod, fn_name, fnt)
        self.fn_values.insert(sym, func)
        self.fn_fn_types.insert(sym, fnt)
        let a: Vec[i64] = Vec.new()
        a.push(val)
        a.push(wl_const_int(i64_ty, flags as i64, 0))
        a.push(wl_const_int(i32_ty, width as i64, 0))
        a.push(wl_const_int(i32_ty, precision as i64, 0))
        return wl_build_call(self.builder, fnt, func, vec_data_i64(&a), 4)

    // Fallback: default format
    self.coerce_val_to_str(val, str_ty)

// ── LLVM math intrinsic recognition ──────────────────────────────
//
// When codegen sees a call to sqrt, sin, cos, etc., emit the LLVM
// intrinsic (e.g., @llvm.sqrt.f64) instead of a library call. This
// compiles to hardware instructions where available (fsqrt on ARM64)
// and eliminates the libm dependency for these functions.

fn Codegen.try_emit_llvm_math_intrinsic(self: Codegen, fn_sym: i32, args: Vec[i64], dest_place: i32, body: MirBody, next_bb: i32) -> bool:
    if fn_sym == 0 or args.len() == 0:
        return false
    let name = self.intern.resolve(fn_sym)
    if name.len() == 0:
        return false

    // Determine LLVM intrinsic name. Only f64 variants for now.
    var intrinsic_name = ""
    var arg_count: i32 = 1
    if name == "sqrt":   intrinsic_name = "llvm.sqrt.f64"
    if name == "sin":    intrinsic_name = "llvm.sin.f64"
    if name == "cos":    intrinsic_name = "llvm.cos.f64"
    if name == "exp":    intrinsic_name = "llvm.exp.f64"
    if name == "exp2":   intrinsic_name = "llvm.exp2.f64"
    if name == "log":    intrinsic_name = "llvm.log.f64"
    if name == "log2":   intrinsic_name = "llvm.log2.f64"
    if name == "log10":  intrinsic_name = "llvm.log10.f64"
    if name == "fabs":   intrinsic_name = "llvm.fabs.f64"
    if name == "floor":  intrinsic_name = "llvm.floor.f64"
    if name == "ceil":   intrinsic_name = "llvm.ceil.f64"
    if name == "round":  intrinsic_name = "llvm.round.f64"
    if name == "pow":
        intrinsic_name = "llvm.pow.f64"
        arg_count = 2
    if name == "fma":
        intrinsic_name = "llvm.fma.f64"
        arg_count = 3

    if intrinsic_name.len() == 0:
        return false

    // Verify the first argument is f64
    let first_arg = args.get(0)
    let arg_ty = wl_type_of(first_arg)
    if wl_get_type_kind(arg_ty) != wl_double_type_kind():
        return false

    let f64_ty = wl_f64_type(self.context)

    // Get or create the LLVM intrinsic declaration
    let isym = self.intern.intern(intrinsic_name)
    var func = 0 as i64
    let cached = self.fn_values.get(isym)
    if cached.is_some():
        func = cached.unwrap() as i64
    else:
        let pts: Vec[i64] = Vec.new()
        for i in 0..arg_count:
            pts.push(f64_ty)
        let ft = wl_function_type(f64_ty, vec_data_i64(&pts), arg_count, 0)
        func = wl_add_function(self.llmod, intrinsic_name, ft)
        self.fn_values.insert(isym, func)
        self.fn_fn_types.insert(isym, ft)

    let ft = self.fn_fn_types.get(isym).unwrap() as i64

    // Build call args (cast to f64 if needed)
    let call_args: Vec[i64] = Vec.new()
    for i in 0..arg_count:
        let a = args.get(i as i64)
        let ak = wl_get_type_kind(wl_type_of(a))
        if ak == wl_float_type_kind():
            call_args.push(wl_build_fp_cast(self.builder, a, f64_ty))
        else:
            call_args.push(a)

    let result = wl_build_call(self.builder, ft, func, vec_data_i64(&call_args), arg_count)

    // Store result to dest
    if dest_place >= 0 and result != 0:
        let dst_local = body.place_locals.get(dest_place as i64)
        let dst_ty = wl_type_of(result)
        let dst_ptr = self.mir_place_ptr(body, dest_place, true, dst_ty)
        if dst_ptr != 0:
            wl_build_store(self.builder, result, dst_ptr)
        self.mir_local_types.insert(dst_local, dst_ty)

    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
        let next_val = self.mir_bb_values.get(next_bb as i64)
        wl_build_br(self.builder, next_val)
    true

// ── FmtBuffer codegen helpers ────────────────────────────────────

fn Codegen.ensure_fmt_buf_fn(self: Codegen, name: str, param_types: Vec[i64], param_count: i32, ret_ty: i64) -> i64:
    let sym = self.intern.intern(name)
    let fv = self.fn_values.get(sym)
    if fv.is_some():
        return fv.unwrap() as i64
    let ft = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count, 0)
    let func = wl_add_function(self.llmod, name, ft)
    self.fn_values.insert(sym, func)
    self.fn_fn_types.insert(sym, ft)
    func

fn Codegen.gen_fmt_buf_new(self: Codegen) -> i64:
    let ptr_ty = wl_ptr_type(self.context)
    let pts: Vec[i64] = Vec.new()
    let func = self.ensure_fmt_buf_fn("with_fmt_buf_new", pts, 0, ptr_ty)
    let ft_sym = self.intern.intern("with_fmt_buf_new")
    let ft = self.fn_fn_types.get(ft_sym).unwrap() as i64
    wl_build_call(self.builder, ft, func, 0, 0)

fn Codegen.gen_fmt_buf_write_str(self: Codegen, buf: i64, s: i64):
    let ptr_ty = wl_ptr_type(self.context)
    let str_ty = self.resolve_named_type(self.intern.intern("str"))
    let pts: Vec[i64] = Vec.new()
    pts.push(ptr_ty)
    pts.push(str_ty)
    let func = self.ensure_fmt_buf_fn("with_fmt_buf_write_str", pts, 2, wl_void_type(self.context))
    let ft_sym = self.intern.intern("with_fmt_buf_write_str")
    let ft = self.fn_fn_types.get(ft_sym).unwrap() as i64
    let args: Vec[i64] = Vec.new()
    args.push(buf)
    args.push(s)
    wl_build_call(self.builder, ft, func, vec_data_i64(&args), 2)

fn Codegen.gen_fmt_buf_write_fmt(self: Codegen, buf: i64, val: i64, flags: i32, width: i32, precision: i32, mode: i32):
    // Dispatch by LLVM type: integer → i64_spec, float → f64_spec, string → str_spec
    let val_ty = wl_type_of(val)
    let vk = wl_get_type_kind(val_ty)
    let ptr_ty = wl_ptr_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let i64_ty = wl_i64_type(self.context)

    if vk == wl_integer_type_kind():
        // Integer: with_fmt_buf_write_i64_spec(buf, val, is_unsigned, flags, width, precision, mode)
        let coerced = self.coerce_int_ext(val, i64_ty, false)
        let pts: Vec[i64] = Vec.new()
        pts.push(ptr_ty)
        pts.push(i64_ty)
        pts.push(i32_ty)
        pts.push(i64_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        let func = self.ensure_fmt_buf_fn("with_fmt_buf_write_i64_spec", pts, 7, wl_void_type(self.context))
        let ft_sym = self.intern.intern("with_fmt_buf_write_i64_spec")
        let ft = self.fn_fn_types.get(ft_sym).unwrap() as i64
        let args: Vec[i64] = Vec.new()
        args.push(buf)
        args.push(coerced)
        args.push(wl_const_int(i32_ty, 0, 0))  // is_unsigned
        args.push(wl_const_int(i64_ty, flags as i64, 0))
        args.push(wl_const_int(i32_ty, width as i64, 0))
        args.push(wl_const_int(i32_ty, precision as i64, 0))
        args.push(wl_const_int(i32_ty, mode as i64, 0))
        wl_build_call(self.builder, ft, func, vec_data_i64(&args), 7)

    else if vk == wl_float_type_kind() or vk == wl_double_type_kind():
        // Float: with_fmt_buf_write_f64_spec(buf, val, flags, width, precision, mode)
        let f64_ty = wl_f64_type(self.context)
        let coerced = if vk == wl_float_type_kind(): wl_build_fp_cast(self.builder, val, f64_ty) else: val
        let pts: Vec[i64] = Vec.new()
        pts.push(ptr_ty)
        pts.push(f64_ty)
        pts.push(i64_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        let func = self.ensure_fmt_buf_fn("with_fmt_buf_write_f64_spec", pts, 6, wl_void_type(self.context))
        let ft_sym = self.intern.intern("with_fmt_buf_write_f64_spec")
        let ft = self.fn_fn_types.get(ft_sym).unwrap() as i64
        let args: Vec[i64] = Vec.new()
        args.push(buf)
        args.push(coerced)
        args.push(wl_const_int(i64_ty, flags as i64, 0))
        args.push(wl_const_int(i32_ty, width as i64, 0))
        args.push(wl_const_int(i32_ty, precision as i64, 0))
        args.push(wl_const_int(i32_ty, mode as i64, 0))
        wl_build_call(self.builder, ft, func, vec_data_i64(&args), 6)

    else:
        // String or other: with_fmt_buf_write_str_spec(buf, val, flags, width, precision)
        let str_ty = self.resolve_named_type(self.intern.intern("str"))
        let pts: Vec[i64] = Vec.new()
        pts.push(ptr_ty)
        pts.push(str_ty)
        pts.push(i64_ty)
        pts.push(i32_ty)
        pts.push(i32_ty)
        let func = self.ensure_fmt_buf_fn("with_fmt_buf_write_str_spec", pts, 5, wl_void_type(self.context))
        let ft_sym = self.intern.intern("with_fmt_buf_write_str_spec")
        let ft = self.fn_fn_types.get(ft_sym).unwrap() as i64
        let args: Vec[i64] = Vec.new()
        args.push(buf)
        args.push(val)
        args.push(wl_const_int(i64_ty, flags as i64, 0))
        args.push(wl_const_int(i32_ty, width as i64, 0))
        args.push(wl_const_int(i32_ty, precision as i64, 0))
        wl_build_call(self.builder, ft, func, vec_data_i64(&args), 5)

fn Codegen.gen_fmt_buf_finish(self: Codegen, buf: i64) -> i64:
    let ptr_ty = wl_ptr_type(self.context)
    let str_ty = self.resolve_named_type(self.intern.intern("str"))
    let pts: Vec[i64] = Vec.new()
    pts.push(ptr_ty)
    let func = self.ensure_fmt_buf_fn("with_fmt_buf_finish", pts, 1, str_ty)
    let ft_sym = self.intern.intern("with_fmt_buf_finish")
    let ft = self.fn_fn_types.get(ft_sym).unwrap() as i64
    let args: Vec[i64] = Vec.new()
    args.push(buf)
    wl_build_call(self.builder, ft, func, vec_data_i64(&args), 1)

fn Codegen.mir_pointer_elem_llvm_type(self: Codegen, sema_ty: i32) -> i64:
    if sema_ty <= 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    let tk = self.mir_input.mir_get_type_kind(resolved)
    if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
        return 0
    let pointee = self.mir_input.mir_get_type_d0(resolved)
    if pointee <= 0:
        return 0
    self.mir_sema_type_to_llvm(pointee)

fn Codegen.mir_enum_variant_payload_llvm_type(self: Codegen, enum_sema_ty: i32, variant_idx: i32) -> i64:
    let builtin_payload = self.mir_builtin_variant_payload_llvm_type(enum_sema_ty, variant_idx)
    if builtin_payload != 0:
        return builtin_payload
    if enum_sema_ty <= 0 or variant_idx < 0:
        return 0
    let enum_sym = self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_name(enum_sema_ty))
    if enum_sym <= 0:
        return 0
    let et_opt = self.enum_type_map.get(enum_sym)
    if not et_opt.is_some():
        return 0
    let enum_idx = et_opt.unwrap()
    let v_start = self.enum_variant_starts.get(enum_idx as i64)
    if v_start + variant_idx < 0 or v_start + variant_idx >= self.enum_variant_payloads.len() as i32:
        return 0
    self.enum_variant_payloads.get((v_start + variant_idx) as i64)

fn Codegen.mir_eval_rvalue(self: Codegen, body: MirBody, rval_id: i32, dest_ty: i64, dest_sema_ty: i32) -> i64:
    let fallback_ty = if dest_ty != 0: dest_ty else: wl_i32_type(self.context)
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        if self.debug_fallback_enabled():
            with_eprint(f"warning: [fallback] mir_eval_rvalue: invalid rval_id={rval_id}")
        return wl_get_undef(fallback_ty)

    let rk = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)

    if rk == RvalueKind.RK_USE:
        let val = self.mir_eval_operand(body, d0, 0)
        if dest_ty != 0:
            return self.mir_coerce_value_to_sema_type(val, dest_ty, dest_sema_ty, self.mir_operand_is_unsigned(body, d0))
        return val

    if rk == RvalueKind.RK_BIN_OP:
        let lhs = self.mir_eval_operand(body, d1, 0)
        let rhs = self.mir_eval_operand(body, d2, 0)
        let lhs_sema = self.mir_operand_sema_type(body, d1)
        let rhs_sema = self.mir_operand_sema_type(body, d2)
        let lhs_resolved = if lhs_sema > 0: self.mir_input.mir_resolve_alias(lhs_sema) else: 0
        let rhs_resolved = if rhs_sema > 0: self.mir_input.mir_resolve_alias(rhs_sema) else: 0
        let lhs_tk = if lhs_resolved > 0: self.mir_input.mir_get_type_kind(lhs_resolved) else: 0
        let rhs_tk = if rhs_resolved > 0: self.mir_input.mir_get_type_kind(rhs_resolved) else: 0
        let lhs_llvm_tk = wl_get_type_kind(wl_type_of(lhs))
        let rhs_llvm_tk = wl_get_type_kind(wl_type_of(rhs))
        if d0 == BinaryOp.OP_ADD or d0 == BinaryOp.OP_SUB:
            if d0 == BinaryOp.OP_SUB and (lhs_tk == TypeKind.TY_PTR or lhs_tk == TypeKind.TY_REF) and (rhs_tk == TypeKind.TY_PTR or rhs_tk == TypeKind.TY_REF) and lhs_llvm_tk == wl_pointer_type_kind() and rhs_llvm_tk == wl_pointer_type_kind():
                let i64_ty = wl_i64_type(self.context)
                let lhs_i = wl_build_ptr_to_int(self.builder, lhs, i64_ty)
                let rhs_i = wl_build_ptr_to_int(self.builder, rhs, i64_ty)
                let byte_diff = wl_build_sub(self.builder, lhs_i, rhs_i)
                let elem_ty = self.mir_pointer_elem_llvm_type(lhs_sema)
                var elem_size: i64 = 1
                if elem_ty != 0:
                    let abi_size = self.abi_size_of(elem_ty)
                    if abi_size > 0:
                        elem_size = abi_size
                return wl_build_sdiv(self.builder, byte_diff, wl_const_int(i64_ty, elem_size, 0))
            if (lhs_tk == TypeKind.TY_PTR or lhs_tk == TypeKind.TY_REF) and lhs_llvm_tk == wl_pointer_type_kind() and rhs_llvm_tk == wl_integer_type_kind():
                let elem_ty = self.mir_pointer_elem_llvm_type(lhs_sema)
                let indices: Vec[i64] = Vec.new()
                indices.push(if d0 == BinaryOp.OP_SUB: wl_build_neg(self.builder, rhs) else: rhs)
                return wl_build_gep(self.builder, if elem_ty != 0: elem_ty else: wl_i8_type(self.context), lhs, vec_data_i64(&indices), 1)
            if d0 == BinaryOp.OP_ADD and (rhs_tk == TypeKind.TY_PTR or rhs_tk == TypeKind.TY_REF) and rhs_llvm_tk == wl_pointer_type_kind() and lhs_llvm_tk == wl_integer_type_kind():
                let elem_ty = self.mir_pointer_elem_llvm_type(rhs_sema)
                let indices: Vec[i64] = Vec.new()
                indices.push(lhs)
                return wl_build_gep(self.builder, if elem_ty != 0: elem_ty else: wl_i8_type(self.context), rhs, vec_data_i64(&indices), 1)
        let is_unsigned = self.mir_operand_is_unsigned(body, d1)
        let out = self.mir_build_bin_op(d0, lhs, rhs, is_unsigned, lhs_sema, rhs_sema)
        if d0 == BinaryOp.OP_CONCAT:
            return out
        if dest_ty != 0:
            return self.coerce_value_to_type(out, dest_ty)
        return out

    if rk == RvalueKind.RK_UN_OP:
        let arg = self.mir_eval_operand(body, d1, dest_ty)
        if d0 == UnaryOp.UOP_NEGATE:
            let ak = wl_get_type_kind(wl_type_of(arg))
            if ak == wl_float_type_kind() or ak == wl_double_type_kind():
                return wl_build_fneg(self.builder, arg)
            return wl_build_neg(self.builder, arg)
        if d0 == UnaryOp.UOP_BIT_NOT:
            return wl_build_not(self.builder, arg)
        if d0 == UnaryOp.UOP_NOT:
            let ak = wl_get_type_kind(wl_type_of(arg))
            if ak == wl_integer_type_kind() and wl_get_int_type_width(wl_type_of(arg)) == 1:
                return wl_build_xor(self.builder, arg, wl_const_int(wl_i1_type(self.context), 1, 0))
            return wl_build_icmp(self.builder, wl_int_eq(), arg, wl_const_int(wl_type_of(arg), 0, 0))
        return arg

    if rk == RvalueKind.RK_REF:
        let ptr = self.mir_place_ptr(body, d1, false, 0)
        if ptr == 0:
            return wl_get_undef(fallback_ty)
        if dest_ty != 0 and wl_type_of(ptr) != dest_ty and wl_get_type_kind(dest_ty) == wl_pointer_type_kind():
            return wl_build_bitcast(self.builder, ptr, dest_ty)
        return ptr

    if rk == RvalueKind.RK_ADDR_OF:
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr == 0:
            return wl_get_undef(fallback_ty)
        if dest_ty != 0 and wl_type_of(ptr) != dest_ty and wl_get_type_kind(dest_ty) == wl_pointer_type_kind():
            return wl_build_bitcast(self.builder, ptr, dest_ty)
        return ptr

    if rk == RvalueKind.RK_DISCRIMINANT:
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr == 0:
            return wl_get_undef(wl_i32_type(self.context))
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return wl_get_undef(wl_i32_type(self.context))
        var place_ty = self.mir_place_projected_type(body, d0)
        if place_ty == 0:
            let local_id = body.place_locals.get(d0 as i64)
            let place_ty_opt = self.mir_local_types.get(local_id)
            if not place_ty_opt.is_some():
                return wl_get_undef(wl_i32_type(self.context))
            place_ty = place_ty_opt.unwrap() as i64
        if wl_get_type_kind(place_ty) == wl_struct_type_kind() and wl_count_struct_elem_types(place_ty) > 0:
            let loaded = wl_build_load(self.builder, place_ty, ptr)
            return wl_build_extract_value(self.builder, loaded, 0)
        if wl_get_type_kind(place_ty) == wl_pointer_type_kind():
            let loaded_ptr = wl_build_load(self.builder, place_ty, ptr)
            let is_none = wl_build_icmp(self.builder, wl_int_eq(), loaded_ptr, wl_const_null(place_ty))
            return self.coerce_int(is_none, wl_i32_type(self.context))
        // Disc enum without payload: the value IS the discriminant
        if wl_get_type_kind(place_ty) == wl_integer_type_kind():
            return wl_build_load(self.builder, place_ty, ptr)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    if rk == RvalueKind.RK_AGGREGATE:
        // d1 = fields_id — index into agg_field_starts/counts/operands
        let agg_fields_id = d1
        if agg_fields_id >= 0 and agg_fields_id < body.agg_field_starts.len() as i32:
            let agg_start = body.agg_field_starts.get(agg_fields_id as i64)
            let agg_count = body.agg_field_counts.get(agg_fields_id as i64)
            var struct_ty = dest_ty
            if struct_ty == 0 and dest_sema_ty > 0:
                struct_ty = self.mir_sema_type_to_llvm(dest_sema_ty)
            if struct_ty == 0 and self.current_ret_type != 0 and wl_get_type_kind(self.current_ret_type) == wl_struct_type_kind():
                struct_ty = self.current_ret_type
            if self.debug_mir_codegen_enabled():
                with_eprint(f"[mir-agg] fn={self.intern.resolve(self.current_function_name_sym)} count={agg_count} dest_ty_kind={if dest_ty != 0: wl_get_type_kind(dest_ty) else: -1} dest_ty_fields={if dest_ty != 0 and wl_get_type_kind(dest_ty) == wl_struct_type_kind(): wl_count_struct_elem_types(dest_ty) else: -1}")
            if agg_count == 0 and d0 != 1:
                if struct_ty == 0:
                    with_eprint(f"error: aggregate rvalue missing destination type fn={self.intern.resolve(self.current_function_name_sym)} count={agg_count}")
                    self.had_error = 1
                    return wl_get_undef(fallback_ty)
                return self.build_default_value(struct_ty)
            if struct_ty != 0 and wl_get_type_kind(struct_ty) == wl_array_type_kind():
                // Array aggregate: [N x T]
                let alloca = self.create_entry_alloca(struct_ty)
                wl_build_store(self.builder, self.build_default_value(struct_ty), alloca)
                let elem_ty = wl_get_element_type(struct_ty)
                for i in 0..agg_count:
                    let op_id = body.agg_field_operands.get((agg_start + i) as i64)
                    let val = self.mir_eval_operand(body, op_id, elem_ty)
                    let indices: Vec[i64] = Vec.new()
                    indices.push(wl_const_int(wl_i32_type(self.context), 0, 0))
                    indices.push(wl_const_int(wl_i32_type(self.context), i as i64, 0))
                    let gep = wl_build_gep(self.builder, struct_ty, alloca, vec_data_i64(&indices), 2)
                    wl_build_store(self.builder, self.coerce_value_to_type(val, elem_ty), gep)
                return wl_build_load(self.builder, struct_ty, alloca)
            if d0 == 1 and struct_ty != 0 and wl_get_type_kind(struct_ty) == wl_pointer_type_kind():
                if agg_count > 0:
                    let first_op = body.agg_field_operands.get(agg_start as i64)
                    let first_val = self.mir_eval_operand(body, first_op, struct_ty)
                    return self.coerce_value_to_type(first_val, struct_ty)
                return wl_const_null(struct_ty)
            // d0 == 1: enum variant construction; d2 = variant index
            if d0 == 1 and struct_ty != 0 and wl_get_type_kind(struct_ty) == wl_struct_type_kind():
                let ev_tag = d2
                let ev_alloca = self.create_entry_alloca(struct_ty)
                wl_build_store(self.builder, self.build_default_value(struct_ty), ev_alloca)
                // Store tag in field 0
                let ev_tag_ty = wl_struct_get_type_at(struct_ty, 0)
                let ev_tag_ptr = wl_build_struct_gep(self.builder, struct_ty, ev_alloca, 0)
                wl_build_store(self.builder, wl_const_int(ev_tag_ty, ev_tag as i64, 0), ev_tag_ptr)
                // Store payload in field 1 if any
                if agg_count > 0 and wl_count_struct_elem_types(struct_ty) > 1:
                    let ev_payload_ty = self.mir_enum_variant_payload_llvm_type(dest_sema_ty, ev_tag)
                    if ev_payload_ty == 0:
                        with_eprint(f"error: aggregate enum payload missing destination payload type fn={self.intern.resolve(self.current_function_name_sym)} variant={ev_tag}")
                        self.had_error = 1
                        return wl_get_undef(fallback_ty)
                    let ev_data_ptr = wl_build_struct_gep(self.builder, struct_ty, ev_alloca, 1)
                    if agg_count > 1 and wl_get_type_kind(ev_payload_ty) == wl_struct_type_kind():
                        let ev_payload_ptr = wl_build_bitcast(self.builder, ev_data_ptr, wl_ptr_type(self.context))
                        let ev_field_count = wl_count_struct_elem_types(ev_payload_ty)
                        for evi in 0..agg_count:
                            if evi >= ev_field_count:
                                continue
                            let ev_op = body.agg_field_operands.get((agg_start + evi) as i64)
                            let ev_field_ty = wl_struct_get_type_at(ev_payload_ty, evi)
                            let ev_val = self.mir_eval_operand(body, ev_op, ev_field_ty)
                            let ev_field_ptr = wl_build_struct_gep(self.builder, ev_payload_ty, ev_payload_ptr, evi)
                            wl_build_store(self.builder, self.coerce_value_to_type(ev_val, ev_field_ty), ev_field_ptr)
                    else:
                        let ev_op = body.agg_field_operands.get(agg_start as i64)
                        let ev_val = self.mir_eval_operand(body, ev_op, ev_payload_ty)
                        wl_build_store(self.builder, self.coerce_value_to_type(ev_val, ev_payload_ty), ev_data_ptr)
                return wl_build_load(self.builder, struct_ty, ev_alloca)
            // Check if this struct is bitpacked (stored as iN) — must check before rejecting non-struct types
            if struct_ty != 0 and self.is_bitpacked_struct(struct_ty):
                // Fall through to bitpacked handler below
                0
            else if struct_ty == 0 or wl_get_type_kind(struct_ty) != wl_struct_type_kind():
                with_eprint(f"error: aggregate rvalue missing destination struct type fn={self.intern.resolve(self.current_function_name_sym)} count={agg_count}")
                self.had_error = 1
                return wl_get_undef(fallback_ty)
            // Check if this struct is bitpacked (stored as iN)
            if self.is_bitpacked_struct(struct_ty):
                // Bitpacked struct literal: OR-shift fields into backing integer
                var bp_result = wl_const_int(struct_ty, 0, 0)
                let bp_total_bits = wl_get_int_type_width(struct_ty)
                for i in 0..agg_count:
                    let op_id = body.agg_field_operands.get((agg_start + i) as i64)
                    var fi = i
                    if (agg_start + i) < body.agg_field_name_syms.len() as i32:
                        let name_sym = body.agg_field_name_syms.get((agg_start + i) as i64)
                        if name_sym != 0:
                            let resolved_fi = self.mir_resolve_field_index(struct_ty, name_sym)
                            if resolved_fi >= 0:
                                fi = resolved_fi
                    let bp_info = self.get_bitpacked_field_info(struct_ty, fi)
                    if bp_info < 0: continue
                    let bp_bit_offset = bp_info / 65536
                    let bp_bit_width = bp_info % 65536
                    let val = self.mir_eval_operand(body, op_id, 0)
                    // Zero-extend or truncate field value to backing type width
                    var field_val = val
                    let val_width = wl_get_int_type_width(wl_type_of(val))
                    if val_width < bp_total_bits:
                        field_val = wl_build_zext(self.builder, val, struct_ty)
                    else if val_width > bp_total_bits:
                        field_val = wl_build_trunc(self.builder, val, struct_ty)
                    // Mask to field width, shift to position (MSB-first layout)
                    let bp_shift_amt = bp_total_bits - bp_bit_offset - bp_bit_width
                    if bp_bit_width < bp_total_bits:
                        let bp_mask = wl_const_int(struct_ty, ((1 as i64) << (bp_bit_width as u32)) - 1, 0)
                        field_val = wl_build_and(self.builder, field_val, bp_mask)
                    if bp_shift_amt > 0:
                        let bp_shift = wl_const_int(struct_ty, bp_shift_amt as i64, 0)
                        field_val = wl_build_shl(self.builder, field_val, bp_shift)
                    bp_result = wl_build_or(self.builder, bp_result, field_val)
                return bp_result

            let alloca = self.create_entry_alloca(struct_ty)
            wl_build_store(self.builder, self.build_default_value(struct_ty), alloca)
            let struct_field_count = wl_count_struct_elem_types(struct_ty)
            for i in 0..agg_count:
                let op_id = body.agg_field_operands.get((agg_start + i) as i64)
                // Resolve field index from name sym if available
                var fi = i
                if (agg_start + i) < body.agg_field_name_syms.len() as i32:
                    let name_sym = body.agg_field_name_syms.get((agg_start + i) as i64)
                    if name_sym != 0:
                        let resolved_fi = self.mir_resolve_field_index(struct_ty, name_sym)
                        if resolved_fi >= 0:
                            fi = resolved_fi
                let union_idx = self.find_struct_index_by_type(struct_ty)
                if self.is_union_struct_index(union_idx):
                    let field_ty = self.struct_source_field_type(union_idx, fi)
                    if field_ty == 0:
                        continue
                    let val = self.mir_eval_operand(body, op_id, field_ty)
                    let coerced_val = self.coerce_value_to_type(val, field_ty)
                    wl_build_store(self.builder, coerced_val, alloca)
                else:
                    let llvm_fi = self.get_llvm_field_index(struct_ty, fi)
                    if llvm_fi >= struct_field_count:
                        continue
                    let field_ty = wl_struct_get_type_at(struct_ty, llvm_fi)
                    let val = self.mir_eval_operand(body, op_id, field_ty)
                    let coerced_val = self.coerce_value_to_type(val, field_ty)
                    let gep = wl_build_struct_gep(self.builder, struct_ty, alloca, llvm_fi)
                    wl_build_store(self.builder, coerced_val, gep)
            return wl_build_load(self.builder, struct_ty, alloca)
        return wl_get_undef(fallback_ty)

    if rk == RvalueKind.RK_CAST:
        let val = self.mir_eval_operand(body, d0, 0)
        var src_unsigned = self.mir_operand_is_unsigned(body, d0)
        // Fallback: if operand lookup failed, check the sema type stored in d2
        // (MirLower stores the source sema type in rval_d2 for casts)
        if not src_unsigned and d2 > 0:
            let cast_src_resolved = self.mir_input.mir_resolve_alias(d2)
            if self.mir_input.mir_get_type_kind(cast_src_resolved) == TypeKind.TY_INT:
                src_unsigned = self.mir_input.mir_get_type_d1(cast_src_resolved) == 0
        // d1 = sema target type id
        var cast_ty = dest_ty
        if d1 > 0:
            let resolved_cast_ty = self.mir_sema_type_to_llvm(d1)
            if resolved_cast_ty != 0:
                cast_ty = resolved_cast_ty
        if cast_ty != 0 and wl_type_of(val) != cast_ty:
            let vk = wl_get_type_kind(wl_type_of(val))
            let ck = wl_get_type_kind(cast_ty)
            // Float → Int
            if (vk == wl_float_type_kind() or vk == wl_double_type_kind()) and ck == wl_integer_type_kind():
                if src_unsigned:
                    return wl_build_fp_to_ui(self.builder, val, cast_ty)
                return wl_build_fp_to_si(self.builder, val, cast_ty)
            // Int → Float
            if vk == wl_integer_type_kind() and (ck == wl_float_type_kind() or ck == wl_double_type_kind()):
                if src_unsigned:
                    return wl_build_ui_to_fp(self.builder, val, cast_ty)
                return wl_build_si_to_fp(self.builder, val, cast_ty)
            // Float → Float
            if (vk == wl_float_type_kind() or vk == wl_double_type_kind()) and (ck == wl_float_type_kind() or ck == wl_double_type_kind()):
                return wl_build_fp_cast(self.builder, val, cast_ty)
            // Ptr → Int
            if vk == wl_pointer_type_kind() and ck == wl_integer_type_kind():
                return wl_build_ptr_to_int(self.builder, val, cast_ty)
            // Int → Ptr
            if vk == wl_integer_type_kind() and ck == wl_pointer_type_kind():
                return wl_build_int_to_ptr(self.builder, val, cast_ty)
            // Int → Int: use zext for unsigned source OR unsigned target
            if vk == wl_integer_type_kind() and ck == wl_integer_type_kind():
                let dst_unsigned = if d1 > 0: self.mir_sema_type_is_unsigned(d1) else: false
                return self.coerce_int_ext(val, cast_ty, src_unsigned or dst_unsigned)
            return self.coerce_value_to_type(val, cast_ty)
        return val

    if rk == RvalueKind.RK_LEN:
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr == 0:
            return wl_const_int(wl_i64_type(self.context), 0, 0)
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return wl_const_int(wl_i64_type(self.context), 0, 0)
        let local_id = body.place_locals.get(d0 as i64)
        let place_ty_opt = self.mir_local_types.get(local_id)
        if not place_ty_opt.is_some():
            return wl_const_int(wl_i64_type(self.context), 0, 0)
        let place_ty = place_ty_opt.unwrap() as i64
        if wl_get_type_kind(place_ty) == wl_array_type_kind():
            return wl_const_int(wl_i64_type(self.context), wl_get_array_length(place_ty), 0)
        if wl_get_type_kind(place_ty) == wl_struct_type_kind() and wl_count_struct_elem_types(place_ty) > 1:
            let loaded = wl_build_load(self.builder, place_ty, ptr)
            return wl_build_extract_value(self.builder, loaded, 1)
        return wl_const_int(wl_i64_type(self.context), 0, 0)

    wl_get_undef(fallback_ty)

fn Codegen.mir_emit_drop_ptr(self: Codegen, ptr: i64, ty: i64) -> void:
    if ptr == 0 or ty == 0:
        return

    var type_sym = self.find_struct_type_by_llvm(ty)
    if type_sym == 0:
        let enum_sym = self.enum_by_llvm.get(ty)
        if enum_sym.is_some():
            type_sym = enum_sym.unwrap()
    if type_sym == 0:
        return

    let dfv = self.drop_fn_values.get(type_sym)
    let dft = self.drop_fn_types.get(type_sym)
    if not dfv.is_some() or not dft.is_some():
        return

    // Drop methods take self by value in the spec, but the compiler lowers
    // struct self params as pointers. Pass pointer for struct types.
    let drop_fn_ty = dft.unwrap() as i64
    let args: Vec[i64] = Vec.new()
    if wl_get_type_kind(ty) == wl_struct_type_kind():
        args.push(ptr)
    else:
        let value = wl_build_load(self.builder, ty, ptr)
        args.push(value)
    let _ = wl_build_call(self.builder, drop_fn_ty, dfv.unwrap() as i64, vec_data_i64(&args), 1)

fn Codegen.mir_emit_stmt(self: Codegen, body: MirBody, stmt_id: i32) -> bool:
    if stmt_id < 0 or stmt_id >= body.stmt_kinds.len() as i32:
        return false
    let sk = body.stmt_kinds.get(stmt_id as i64)
    let d0 = body.stmt_d0.get(stmt_id as i64)
    let d1 = body.stmt_d1.get(stmt_id as i64)

    if sk == StmtKind.Assign:
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let dst_local = body.place_locals.get(d0 as i64)
        var dst_ptr = self.mir_place_ptr(body, d0, false, 0)
        let has_projections = body.place_proj_counts.get(d0 as i64) > 0
        let dst_sema_ty = self.mir_place_sema_type(body, d0)
        var dst_ty = self.mir_dest_llvm_type(body, d0)
        if dst_ty == 0:
            let dst_ty_opt = self.mir_local_types.get(dst_local)
            if dst_ptr != 0 and dst_ty_opt.is_some():
                dst_ty = dst_ty_opt.unwrap() as i64
        let value = self.mir_eval_rvalue(body, d1, dst_ty, dst_sema_ty)
        if dst_ptr == 0:
            if has_projections:
                return false
            let value_ty = wl_type_of(value)
            // When sema type is str but value is a pointer (c_import coercion),
            // use the str type for the alloca so the coerced struct fits.
            let alloca_ty = if dst_ty != 0 and self.is_str_type(dst_ty) and wl_get_type_kind(value_ty) == wl_pointer_type_kind(): dst_ty else: value_ty
            dst_ptr = self.mir_get_or_create_local_ptr(dst_local, alloca_ty)
            self.mir_local_types.insert(dst_local, alloca_ty)
        var final_ty = dst_ty
        if final_ty == 0:
            let final_ty_opt = self.mir_local_types.get(dst_local)
            if final_ty_opt.is_some():
                final_ty = final_ty_opt.unwrap() as i64
        if final_ty == 0: return false
        var coerced = value
        if wl_type_of(value) != final_ty:
            var src_unsigned = false
            let rv_kind = if d1 >= 0 and d1 < body.rval_kinds.len() as i32: body.rval_kinds.get(d1 as i64) else: -1
            if rv_kind == RvalueKind.RK_USE:
                let operand_id = body.rval_d0.get(d1 as i64)
                src_unsigned = self.mir_operand_is_unsigned(body, operand_id)
            coerced = self.mir_coerce_value_to_sema_type(value, final_ty, dst_sema_ty, src_unsigned)
        // Bitpacked field store: read-modify-write the backing integer
        let bp_store_proj = self.bitpacked_place_proj.get(d0)
        if bp_store_proj.is_some():
            let bp_si = bp_store_proj.unwrap() as i32
            let bp_sbit_offset = bp_si / 65536
            let bp_sbit_width = bp_si % 65536
            let bp_sbacking_ty = wl_get_allocated_type(dst_ptr)
            let bp_stotal_bits = wl_get_int_type_width(bp_sbacking_ty)
            let bp_sshift_amt = bp_stotal_bits - bp_sbit_offset - bp_sbit_width
            // Load current backing value
            let bp_sold = wl_build_load(self.builder, bp_sbacking_ty, dst_ptr)
            // Clear field bits
            let bp_sfield_mask = ((1 as i64) << (bp_sbit_width as u32)) - 1
            let bp_sclear_mask_val = (bp_sfield_mask << (bp_sshift_amt as u32)) ^ (-1 as i64)
            let bp_sclear_mask = wl_const_int(bp_sbacking_ty, bp_sclear_mask_val, 0)
            let bp_scleared = wl_build_and(self.builder, bp_sold, bp_sclear_mask)
            // Extend new value to backing width and shift into position
            var bp_snew_val = coerced
            let bp_snew_width = wl_get_int_type_width(wl_type_of(coerced))
            if bp_snew_width < bp_stotal_bits:
                bp_snew_val = wl_build_zext(self.builder, coerced, bp_sbacking_ty)
            else if bp_snew_width > bp_stotal_bits:
                bp_snew_val = wl_build_trunc(self.builder, coerced, bp_sbacking_ty)
            // Mask to field width
            let bp_sval_mask = wl_const_int(bp_sbacking_ty, bp_sfield_mask, 0)
            bp_snew_val = wl_build_and(self.builder, bp_snew_val, bp_sval_mask)
            if bp_sshift_amt > 0:
                let bp_sshift = wl_const_int(bp_sbacking_ty, bp_sshift_amt as i64, 0)
                bp_snew_val = wl_build_shl(self.builder, bp_snew_val, bp_sshift)
            // OR new value in
            let bp_sfinal = wl_build_or(self.builder, bp_scleared, bp_snew_val)
            wl_build_store(self.builder, bp_sfinal, dst_ptr)
            self.bitpacked_place_proj.remove(d0)
        else:
            wl_build_store(self.builder, coerced, dst_ptr)
        return true

    if sk == StmtKind.StorageLive:
        // d1 != 0 signals zero-init: create alloca and store zeroinitializer
        if d1 != 0:
            let local_id = d0
            let sema_ty = d1
            let llvm_ty = self.sema_type_to_llvm(sema_ty)
            if llvm_ty != 0:
                let ptr = self.mir_get_or_create_local_ptr(local_id, llvm_ty)
                self.mir_local_types.insert(local_id, llvm_ty)
                let zero = wl_const_null(llvm_ty)
                wl_build_store(self.builder, zero, ptr)
        return true

    if sk == StmtKind.StorageDead:
        return true

    if sk == StmtKind.Drop:
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let local_id = body.place_locals.get(d0 as i64)
        let drop_ty = self.mir_local_llvm_type(body, local_id)
        var ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr == 0 and drop_ty != 0:
            ptr = self.mir_place_ptr(body, d0, true, drop_ty)
        if ptr != 0:
            if drop_ty != 0:
                self.mir_emit_drop_ptr(ptr, drop_ty)
        return true

    if sk == StmtKind.Nop:
        return true

    false

fn Codegen.mir_default_unreachable_bb_value(self: Codegen) -> i64:
    if self.mir_default_unreachable_bbs.len() as i32 > 0:
        return self.mir_default_unreachable_bbs.get(0)
    let bb = wl_append_bb(self.context, self.current_function, "mir.default.unreachable")
    self.mir_default_unreachable_bbs.push(bb)
    bb

fn Codegen.mir_try_place_ptr_for_ref(self: Codegen, body: MirBody, operand_id: i32) -> i64:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return 0
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if (ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE) and od >= 0 and od < body.place_locals.len() as i32:
        let ptr = self.mir_place_ptr(body, od, false, 0)
        if ptr == 0:
            return 0
        let local_id = body.place_locals.get(od as i64)
        let p_count = body.place_proj_counts.get(od as i64)
        if p_count == 0:
            let alloc_ty = wl_get_allocated_type(ptr)
            if alloc_ty != 0 and wl_get_type_kind(alloc_ty) == wl_pointer_type_kind():
                return wl_build_load(self.builder, alloc_ty, ptr)
            let ptr_ty_opt = self.mir_local_types.get(local_id)
            if ptr_ty_opt.is_some():
                let ptr_ty = ptr_ty_opt.unwrap() as i64
                if ptr_ty != 0 and wl_get_type_kind(ptr_ty) == wl_pointer_type_kind():
                    return wl_build_load(self.builder, ptr_ty, ptr)
        var is_indirect_value_local = self.mir_indirect_value_local_types.get(local_id).is_some()
        if not is_indirect_value_local and p_count == 0 and local_id >= 0 and local_id < body.local_names.len() as i32:
            let local_name = body.local_names.get(local_id as i64)
            if local_name == self.sym_self:
                is_indirect_value_local = true
            else:
                let local_text = self.sema_symbol_text(local_name)
                if local_text == "self":
                    is_indirect_value_local = true
        if not is_indirect_value_local and p_count == 0 and local_id >= 0 and local_id < body.local_type_ids.len() as i32:
            let local_sema_ty = body.local_type_ids.get(local_id as i64)
            if local_sema_ty > 0:
                let semantic_ty = self.mir_sema_type_to_llvm(local_sema_ty)
                if semantic_ty != 0 and wl_get_type_kind(semantic_ty) != wl_pointer_type_kind():
                    is_indirect_value_local = true
        if p_count == 0 and is_indirect_value_local:
            let ptr_ty_opt = self.mir_local_types.get(local_id)
            if ptr_ty_opt.is_some():
                let ptr_ty = ptr_ty_opt.unwrap() as i64
                if ptr_ty != 0 and wl_get_type_kind(ptr_ty) == wl_pointer_type_kind():
                    return wl_build_load(self.builder, ptr_ty, ptr)
        return ptr
    0

fn Codegen.mir_eval_call_operand(self: Codegen, body: MirBody, operand_id: i32, expected_ty: i64, call_context: str, arg_index: i32) -> i64:
    var eval_expected_ty = expected_ty
    if expected_ty != 0 and wl_get_type_kind(expected_ty) == wl_pointer_type_kind():
        eval_expected_ty = 0
    let val = self.mir_eval_operand(body, operand_id, eval_expected_ty)
    var out = val
    if out != 0 and expected_ty != 0:
        let expected_kind = wl_get_type_kind(expected_ty)
        let actual_kind = wl_get_type_kind(wl_type_of(out))
        if expected_kind == wl_pointer_type_kind() and actual_kind == wl_struct_type_kind():
            let place_ptr = self.mir_try_place_ptr_for_ref(body, operand_id)
            if place_ptr != 0:
                out = place_ptr
    let had_error_before = self.had_error
    let coerced = self.enforce_coerced_type(out, expected_ty, "wrong argument type")
    if self.had_error != had_error_before:
        self.debug_call_coerce_failure(call_context, 0, arg_index, 0, out, expected_ty)
    coerced

fn Codegen.mir_unwrap_ref_like_sema_type(self: Codegen, sema_ty: i32) -> i32:
    var current = sema_ty
    for _ in 0..4:
        if current <= 0:
            return 0
        var resolved = self.mir_input.mir_resolve_alias(current)
        var tk = self.mir_input.mir_get_type_kind(resolved)
        if tk == 0 and resolved >= self.mir_input.sema_type_kinds.len() as i32 and resolved > 0:
            resolved = self.sema.resolve_alias(resolved as TypeId) as i32
            tk = self.sema.get_type_kind(resolved)
        if tk != TypeKind.TY_REF and tk != TypeKind.TY_PTR:
            return resolved
        current = if resolved >= self.mir_input.sema_type_kinds.len() as i32:
            self.sema.get_type_d0(resolved)
        else:
            self.mir_input.mir_get_type_d0(resolved)
    current

fn Codegen.mir_intrinsic_recv_ptr(self: Codegen, body: MirBody, args_id: i32) -> i64:
    // Get a pointer to the receiver (arg 0) for instance method intrinsics.
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let recv_op = body.call_arg_operands.get(arg_start as i64)
    let ok = body.operand_kinds.get(recv_op as i64)
    let od = body.operand_d0.get(recv_op as i64)
    // If operand is a place (Copy/Move), get its address directly. This must
    // happen before the reference shortcut below; field places like
    // `self.xs` may have reference-like sema during projection, but Vec
    // intrinsics need the field address, not an evaluated pointer-shaped value.
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        let ptr = self.mir_place_ptr(body, od, false, 0)
        if ptr != 0:
            let local_id0 = body.place_locals.get(od as i64)
            let p_count0 = body.place_proj_counts.get(od as i64)
            if p_count0 == 0 and local_id0 >= 0 and local_id0 < body.local_type_ids.len() as i32:
                let local_sema0 = body.local_type_ids.get(local_id0 as i64)
                let local_resolved0 = self.mir_input.mir_resolve_alias(local_sema0)
                let local_kind0 = self.mir_input.mir_get_type_kind(local_resolved0)
                if local_kind0 == TypeKind.TY_REF or local_kind0 == TypeKind.TY_PTR:
                    let alloc_ty0 = wl_get_allocated_type(ptr)
                    if alloc_ty0 != 0 and wl_get_type_kind(alloc_ty0) == wl_pointer_type_kind():
                        return wl_build_load(self.builder, alloc_ty0, ptr)
            return ptr
        // Lazy-create alloca
        let local_id = body.place_locals.get(od as i64)
        if local_id >= 0 and local_id < body.local_type_ids.len() as i32:
            let sema_ty = body.local_type_ids.get(local_id as i64)
            if sema_ty > 0:
                let llvm_ty = self.mir_sema_type_to_llvm(sema_ty)
                if llvm_ty != 0:
                    let ptr2 = self.mir_place_ptr(body, od, true, llvm_ty)
                    if ptr2 != 0:
                        return ptr2
    let recv_sema = self.mir_operand_sema_type(body, recv_op)
    let recv_resolved = self.mir_unwrap_ref_like_sema_type(recv_sema)
    if recv_sema > 0 and recv_resolved != recv_sema:
        let recv_val = self.mir_eval_operand(body, recv_op, 0)
        if wl_get_type_kind(wl_type_of(recv_val)) == wl_pointer_type_kind():
            return recv_val
    // Fallback: evaluate, alloca, store
    let val = self.mir_eval_operand(body, recv_op, 0)
    let alloca = wl_build_alloca(self.builder, wl_type_of(val))
    wl_build_store(self.builder, val, alloca)
    alloca

fn Codegen.mir_intrinsic_recv_vec_value(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let recv_op = body.call_arg_operands.get(arg_start as i64)
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
    if wl_get_type_kind(wl_type_of(recv)) == wl_struct_type_kind():
        return recv
    let ok = body.operand_kinds.get(recv_op as i64)
    let od = body.operand_d0.get(recv_op as i64)
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        let place_ty = self.mir_place_projected_type(body, od)
        if place_ty != 0 and wl_get_type_kind(place_ty) == wl_struct_type_kind():
            let recv_ptr = self.mir_place_ptr(body, od, false, 0)
            if recv_ptr != 0 and wl_get_type_kind(wl_type_of(recv_ptr)) == wl_pointer_type_kind():
                return wl_build_load(self.builder, place_ty, recv_ptr)
    let recv_sema = self.mir_operand_sema_type(body, recv_op)
    let recv_unwrapped = self.mir_unwrap_ref_like_sema_type(recv_sema)
    if recv_unwrapped > 0:
        let recv_llvm_ty = self.mir_sema_type_to_llvm(recv_unwrapped)
        if recv_llvm_ty != 0 and wl_get_type_kind(recv_llvm_ty) == wl_struct_type_kind():
            let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
            if recv_ptr != 0 and wl_get_type_kind(wl_type_of(recv_ptr)) == wl_pointer_type_kind():
                return wl_build_load(self.builder, recv_llvm_ty, recv_ptr)
    recv

fn Codegen.mir_intrinsic_arg(self: Codegen, body: MirBody, args_id: i32, idx: i32) -> i64:
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let op_id = body.call_arg_operands.get((arg_start + idx) as i64)
    self.mir_eval_operand(body, op_id, 0)

fn Codegen.mir_extract_map_ptr(self: Codegen, recv: i64) -> i64:
    // HashMap value is either { ptr } struct or raw ptr (from field access).
    let recv_ty = wl_type_of(recv)
    if wl_get_type_kind(recv_ty) == wl_pointer_type_kind():
        let pointee_ty = wl_get_element_type(recv_ty)
        if pointee_ty != 0 and wl_get_type_kind(pointee_ty) == wl_struct_type_kind():
            let loaded = wl_build_load(self.builder, pointee_ty, recv)
            return wl_build_extract_value(self.builder, loaded, 0)
        return recv
    if wl_get_type_kind(recv_ty) == wl_struct_type_kind():
        return wl_build_extract_value(self.builder, recv, 0)
    recv

fn Codegen.mir_intrinsic_map_handle(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let recv_op = body.call_arg_operands.get(arg_start as i64)
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
    let recv_sema = self.mir_operand_sema_type(body, recv_op)
    if recv_sema > 0:
        let recv_resolved = self.mir_input.mir_resolve_alias(recv_sema)
        let recv_tk = self.mir_input.mir_get_type_kind(recv_resolved)
        if recv_tk == TypeKind.TY_REF or recv_tk == TypeKind.TY_PTR:
            let pointee_sema = self.mir_input.mir_get_type_d0(recv_resolved)
            if pointee_sema > 0:
                let pointee_resolved = self.mir_input.mir_resolve_alias(pointee_sema)
                if self.mir_input.mir_get_type_kind(pointee_resolved) == TypeKind.TY_GENERIC_INST:
                    let base_sym = self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_d0(pointee_resolved))
                    if base_sym == self.sym_hashmap or base_sym == self.sym_hashset:
                        let pointee_ty = self.mir_sema_type_to_llvm(pointee_resolved)
                        if pointee_ty != 0 and wl_get_type_kind(wl_type_of(recv)) == wl_pointer_type_kind():
                            let loaded = wl_build_load(self.builder, pointee_ty, recv)
                            if wl_get_type_kind(wl_type_of(loaded)) == wl_struct_type_kind():
                                return wl_build_extract_value(self.builder, loaded, 0)
    self.mir_extract_map_ptr(recv)

fn Codegen.mir_intrinsic_dest_sema_type(self: Codegen, body: MirBody, dest_place: i32) -> i32:
    if dest_place < 0 or dest_place >= body.place_locals.len() as i32:
        return 0
    let local_id = body.place_locals.get(dest_place as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    body.local_type_ids.get(local_id as i64)

fn Codegen.mir_vec_elem_size(self: Codegen, body: MirBody, dest_place: i32) -> i64:
    // Determine Vec element size from dest place sema type (TypeKind.TY_GENERIC_INST).
    let sema_ty = self.mir_intrinsic_dest_sema_type(body, dest_place)
    if sema_ty > 0:
        let resolved = self.mir_input.mir_resolve_alias(sema_ty)
        let tk = self.mir_input.mir_get_type_kind(resolved)
        if tk == TypeKind.TY_GENERIC_INST:
            let arg_count = self.mir_input.mir_get_type_d2(resolved)
            if arg_count > 0:
                let te_start = self.mir_input.mir_get_type_d1(resolved)
                let elem_tid = self.mir_input.mir_get_type_extra(te_start)
                if elem_tid > 0:
                    let elem_llvm = self.mir_sema_type_to_llvm(elem_tid)
                    if elem_llvm != 0:
                        return self.abi_size_of(elem_llvm)
    8 // default — safe for pointers, i64, str

fn Codegen.mir_index_elem_sema_type(self: Codegen, sema_ty: i32) -> i32:
    if sema_ty <= 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    let tk = self.mir_input.mir_get_type_kind(resolved)
    if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
        return self.mir_input.mir_get_type_d0(resolved)
    if tk == TypeKind.TY_STR:
        return self.sema.ty_i32 as i32
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        // d0 = pointee type id
        return self.mir_input.mir_get_type_d0(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_d0(resolved))
        let arg_count = self.mir_input.mir_get_type_d2(resolved)
        if base_sym == self.sym_vec and arg_count > 0:
            let te_start = self.mir_input.mir_get_type_d1(resolved)
            return self.mir_input.mir_get_type_extra(te_start)
    0

fn Codegen.mir_index_elem_llvm_type(self: Codegen, sema_ty: i32, cur_ty: i64) -> i64:
    if cur_ty != 0 and wl_get_type_kind(cur_ty) == wl_array_type_kind():
        return wl_get_element_type(cur_ty)
    if sema_ty > 0:
        let resolved = self.mir_input.mir_resolve_alias(sema_ty)
        if self.mir_input.mir_get_type_kind(resolved) == TypeKind.TY_STR:
            return wl_i8_type(self.context)
        let elem_sema = self.mir_index_elem_sema_type(sema_ty)
        if elem_sema > 0:
            let elem_llvm = self.mir_sema_type_to_llvm(elem_sema)
            if elem_llvm != 0:
                return elem_llvm
    if cur_ty != 0:
        if self.is_str_type(cur_ty):
            return wl_i8_type(self.context)
    0

fn Codegen.mir_find_named_type(self: Codegen, type_sym: i32) -> i32:
    if type_sym <= 0:
        return 0
    for ti in 0..self.mir_input.sema_type_kinds.len() as i32:
        let tk = self.mir_input.sema_type_kinds.get(ti as i64)
        if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_ENUM:
            continue
        if self.mir_input.sema_type_d0.get(ti as i64) == type_sym:
            return ti
    0

fn Codegen.mir_find_named_type_text(self: Codegen, type_name: str) -> i32:
    if type_name.len() == 0:
        return 0
    for ti in 0..self.mir_input.sema_type_kinds.len() as i32:
        let tk = self.mir_input.sema_type_kinds.get(ti as i64)
        if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_ENUM:
            continue
        let sym = self.mir_input.sema_type_d0.get(ti as i64)
        if self.sema_symbol_text(sym) == type_name:
            return ti
    0

fn Codegen.mir_builtin_variant_payload_sema_type(self: Codegen, sema_ty: i32, variant_idx: i32) -> i32:
    if sema_ty <= 0 or variant_idx < 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    if self.mir_input.mir_get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    let base_sym = self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_d0(resolved))
    if base_sym <= 0:
        return 0
    let arg_count = self.mir_input.mir_get_type_d2(resolved)
    let args_start = self.mir_input.mir_get_type_d1(resolved)
    if base_sym == self.sym_option:
        if variant_idx == 0 and arg_count > 0:
            return self.mir_input.mir_get_type_extra(args_start)
        return 0
    if base_sym == self.sym_result:
        if variant_idx == 0 and arg_count > 0:
            return self.mir_input.mir_get_type_extra(args_start)
        if variant_idx == 1 and arg_count > 1:
            return self.mir_input.mir_get_type_extra(args_start + 1)
    0

fn Codegen.mir_builtin_variant_payload_llvm_type(self: Codegen, sema_ty: i32, variant_idx: i32) -> i64:
    let payload_sema = self.mir_builtin_variant_payload_sema_type(sema_ty, variant_idx)
    if payload_sema <= 0:
        return 0
    self.mir_sema_type_to_llvm(payload_sema)

fn Codegen.mir_enum_payload_sema_type(self: Codegen, enum_sema_ty: i32, variant_idx: i32, field_idx: i32) -> i32:
    if enum_sema_ty <= 0 or variant_idx < 0 or field_idx < 0:
        return 0
    let builtin_payload = self.mir_builtin_variant_payload_sema_type(enum_sema_ty, variant_idx)
    if builtin_payload > 0:
        if field_idx == 0:
            return builtin_payload
        return 0

    let resolved = self.mir_input.mir_resolve_alias(enum_sema_ty)
    let tk = self.mir_input.mir_get_type_kind(resolved)

    if tk == TypeKind.TY_ENUM:
        let te_start = self.mir_input.mir_get_type_d1(resolved)
        let variant_count = self.mir_input.mir_get_type_d2(resolved)
        var pos = te_start
        for vi in 0..variant_count:
            let payload_count = self.mir_input.mir_get_type_extra(pos + 1)
            if vi == variant_idx:
                if field_idx < payload_count:
                    return self.mir_input.mir_get_type_extra(pos + 2 + field_idx)
                return 0
            pos = pos + 2 + payload_count
        return 0

    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.mir_input.mir_get_type_d0(resolved)
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

fn Codegen.mir_project_field_sema_type(self: Codegen, agg_ty: i32, field_token: i32) -> i32:
    if agg_ty <= 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(agg_ty)
    let tk = self.mir_input.mir_get_type_kind(resolved)
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        let inner = self.mir_input.mir_get_type_d0(resolved)
        return self.mir_project_field_sema_type(inner, field_token)
    if tk == TypeKind.TY_TUPLE:
        let elem_start = self.mir_input.mir_get_type_d0(resolved)
        let elem_count = self.mir_input.mir_get_type_d1(resolved)
        if field_token >= 0 and field_token < elem_count:
            return self.mir_input.mir_get_type_extra(elem_start + field_token)
        return 0
    if tk == TypeKind.TY_GENERIC_INST:
        // Preserve generic substitutions when projecting fields through a
        // specialized struct like Outer[Entry] -> wrapped: Wrapper[Entry].
        let generic_field_ty = self.sema.struct_field_type(resolved, field_token)
        if generic_field_ty > 0:
            return generic_field_ty
        let base_sym = self.mir_input.mir_get_type_d0(resolved)
        let base_tid = self.mir_find_named_type(base_sym)
        if base_tid > 0:
            return self.mir_project_field_sema_type(base_tid, field_token)
        return 0
    if tk != TypeKind.TY_STRUCT:
        return 0
    let extra_start = self.mir_input.mir_get_type_d1(resolved)
    let field_count = self.mir_input.mir_get_type_d2(resolved)
    for fi in 0..field_count:
        let name_sym = self.mir_input.mir_get_type_extra(extra_start + fi * 3)
        if name_sym == field_token:
            return self.mir_input.mir_get_type_extra(extra_start + fi * 3 + 1)
    0

fn Codegen.mir_operand_sema_type(self: Codegen, body: MirBody, operand_id: i32) -> i32:
    // Get the sema type for a MIR operand, handling projected places.
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OperandKind.OK_CONSTANT:
        if od >= 0 and od < body.const_types.len() as i32:
            return body.const_types.get(od as i64)
        return 0
    if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
        return 0
    if od < 0 or od >= body.place_locals.len() as i32:
        return 0
    self.mir_place_sema_type(body, od)

fn Codegen.mir_place_sema_type(self: Codegen, body: MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    let local_id = body.place_locals.get(place_id as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    let p_count = body.place_proj_counts.get(place_id as i64)
    let local_ty = body.local_type_ids.get(local_id as i64)
    if p_count <= 0:
        if local_ty > 0:
            return local_ty
        if place_id < body.place_sema_types.len() as i32:
            let stored = body.place_sema_types.get(place_id as i64)
            if stored > 0:
                return stored
        return 0
    // Projected places can carry a more precise cached sema type.
    if place_id < body.place_sema_types.len() as i32:
        let stored = body.place_sema_types.get(place_id as i64)
        if stored > 0:
            return stored
    // Fallback: walk projections using sema snapshot
    var ty = local_ty
    var active_variant_idx = -1
    let p_start = body.place_proj_starts.get(place_id as i64)
    for pi in 0..p_count:
        let pk = body.proj_kinds.get((p_start + pi) as i64)
        let pd = body.proj_d0.get((p_start + pi) as i64)
        if pk == ProjKind.PK_FIELD:
            let field_ty = if active_variant_idx >= 0:
                self.mir_enum_payload_sema_type(ty, active_variant_idx, pd)
            else:
                self.mir_project_field_sema_type(ty, pd)
            if field_ty > 0:
                ty = field_ty
            active_variant_idx = -1
        else if pk == ProjKind.PK_DEREF:
            let d_resolved = self.mir_input.mir_resolve_alias(ty)
            let d_tk = self.mir_input.mir_get_type_kind(d_resolved)
            if d_tk == TypeKind.TY_PTR or d_tk == TypeKind.TY_REF:
                ty = self.mir_input.mir_get_type_d0(d_resolved)
            active_variant_idx = -1
        else if pk == ProjKind.PK_INDEX:
            let elem_ty = self.mir_index_elem_sema_type(ty)
            if elem_ty > 0:
                ty = elem_ty
            active_variant_idx = -1
        else if pk == ProjKind.PK_DOWNCAST:
            active_variant_idx = pd
    ty

fn Codegen.mir_dest_llvm_type(self: Codegen, body: MirBody, dest_place: i32) -> i64:
    // Get the LLVM type for a destination place from its sema type.
    if dest_place < 0 or dest_place >= body.place_locals.len() as i32:
        return 0
    let sema_ty = self.mir_place_sema_type(body, dest_place)
    if sema_ty <= 0:
        return 0
    self.mir_sema_type_to_llvm(sema_ty)

fn Codegen.mir_struct_sym_from_sema_type(self: Codegen, sema_ty: i32) -> i32:
    if sema_ty <= 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    let snapshot_len = self.mir_input.sema_type_kinds.len() as i32
    var tk = self.mir_input.mir_get_type_kind(resolved)
    if tk == 0 and resolved >= snapshot_len and resolved > 0:
        let live_resolved = self.sema.resolve_alias(resolved)
        let live_tk = self.sema.get_type_kind(live_resolved)
        if live_tk == TypeKind.TY_STRUCT:
            let live_name_sym = self.sema.get_type_d0(live_resolved)
            let live_cg_sym = self.sema_sym_to_codegen_sym(live_name_sym)
            if live_cg_sym != 0 and self.struct_type_map.get(live_cg_sym).is_some():
                return live_cg_sym
            if self.struct_type_map.get(live_name_sym).is_some():
                return live_name_sym
            return 0
        if live_tk == TypeKind.TY_GENERIC_INST:
            let live_base_sym = self.sema_sym_to_codegen_sym(self.sema.get_type_d0(live_resolved))
            if live_base_sym == 0 or not self.generic_structs.contains(live_base_sym):
                return 0
            let _ = self.sema_type_to_llvm(live_resolved)
            var live_mangled = self.intern.resolve(live_base_sym)
            let live_arg_count = self.sema.get_generic_inst_arg_count(live_resolved)
            for ai in 0..live_arg_count:
                let arg_tid = self.sema.get_generic_inst_arg(live_resolved, ai)
                var arg_llvm = self.sema_type_to_llvm(arg_tid)
                if arg_llvm == 0:
                    arg_llvm = self.type_fallback()
                live_mangled = live_mangled ++ "__" ++ self.llvm_type_mangle(arg_llvm)
            let live_mono_sym = self.intern.intern(live_mangled)
            if self.struct_type_map.get(live_mono_sym).is_some():
                return live_mono_sym
        return 0
    if tk == TypeKind.TY_STRUCT:
        let name_sym = self.mir_input.mir_get_type_d0(resolved)
        let cg_sym = self.sema_sym_to_codegen_sym(name_sym)
        if cg_sym != 0 and self.struct_type_map.get(cg_sym).is_some():
            return cg_sym
        if self.struct_type_map.get(name_sym).is_some():
            return name_sym
        return 0
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_d0(resolved))
        if base_sym == 0 or not self.generic_structs.contains(base_sym):
            return 0
        let _ = self.mir_sema_type_to_llvm(resolved)
        var mangled = self.intern.resolve(base_sym)
        let arg_count = self.mir_input.mir_get_type_d2(resolved)
        let te_start = self.mir_input.mir_get_type_d1(resolved)
        for ai in 0..arg_count:
            let arg_tid = self.mir_input.mir_get_type_extra(te_start + ai)
            var arg_llvm = self.mir_sema_type_to_llvm(arg_tid)
            if arg_llvm == 0:
                arg_llvm = self.type_fallback()
            mangled = mangled ++ "__" ++ self.llvm_type_mangle(arg_llvm)
        let mono_sym = self.intern.intern(mangled)
        if self.struct_type_map.get(mono_sym).is_some():
            return mono_sym
    0

fn Codegen.mir_vec_elem_type(self: Codegen, body: MirBody, recv_op_id: i32) -> i64:
    // Infer Vec element LLVM type from the receiver's sema type (using snapshot).
    let sema_ty = self.mir_operand_sema_type(body, recv_op_id)
    if sema_ty > 0:
        let resolved = self.mir_unwrap_ref_like_sema_type(sema_ty)
        let tk = self.mir_input.mir_get_type_kind(resolved)
        if tk == TypeKind.TY_GENERIC_INST:
            let arg_count = self.mir_input.mir_get_type_d2(resolved)
            if arg_count > 0:
                let te_start = self.mir_input.mir_get_type_d1(resolved)
                let elem_tid = self.mir_input.mir_get_type_extra(te_start)
                if elem_tid > 0:
                    return self.mir_sema_type_to_llvm(elem_tid)
    0

fn Codegen.mir_hashmap_key_type(self: Codegen, body: MirBody, recv_op_id: i32) -> i64:
    let sema_ty = self.mir_operand_sema_type(body, recv_op_id)
    if sema_ty > 0:
        let resolved = self.mir_unwrap_ref_like_sema_type(sema_ty)
        let tk = self.mir_input.mir_get_type_kind(resolved)
        if tk == TypeKind.TY_GENERIC_INST:
            let base_sym = self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_d0(resolved))
            let arg_count = self.mir_input.mir_get_type_d2(resolved)
            if (base_sym == self.sym_hashmap or base_sym == self.sym_hashset) and arg_count > 0:
                let te_start = self.mir_input.mir_get_type_d1(resolved)
                let key_tid = self.mir_input.mir_get_type_extra(te_start)
                if key_tid > 0:
                    return self.mir_sema_type_to_llvm(key_tid)
    0

fn Codegen.mir_hashmap_value_type(self: Codegen, body: MirBody, recv_op_id: i32) -> i64:
    let sema_ty = self.mir_operand_sema_type(body, recv_op_id)
    if sema_ty > 0:
        let resolved = self.mir_unwrap_ref_like_sema_type(sema_ty)
        let tk = self.mir_input.mir_get_type_kind(resolved)
        if tk == TypeKind.TY_GENERIC_INST:
            let base_sym = self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_d0(resolved))
            let arg_count = self.mir_input.mir_get_type_d2(resolved)
            if base_sym == self.sym_hashmap and arg_count > 1:
                let te_start = self.mir_input.mir_get_type_d1(resolved)
                let value_tid = self.mir_input.mir_get_type_extra(te_start + 1)
                if value_tid > 0:
                    return self.mir_sema_type_to_llvm(value_tid)
    0

fn Codegen.mir_map_recv_base_sym(self: Codegen, body: MirBody, recv_op_id: i32) -> i32:
    let sema_ty = self.mir_operand_sema_type(body, recv_op_id)
    if sema_ty > 0:
        let resolved = self.mir_unwrap_ref_like_sema_type(sema_ty)
        if self.mir_input.mir_get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
            return self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_d0(resolved))
    0

fn Codegen.ast_static_type_expr(self: Codegen, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.pool.kind(node)
    if kind == NodeKind.NK_IDENT:
        let local_ty = self.sema_type_of_node(node)
        if local_ty != 0:
            return local_ty
    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = self.pool.get_data0(node)
        let field = self.pool.get_data1(node)
        var base_ty = self.ast_static_type_expr(base)
        if base_ty == 0:
            base_ty = self.sema_type_of_node(base)
        if base_ty == 0 and self.current_method_owner_sym != 0 and self.pool.kind(base) == NodeKind.NK_IDENT and self.pool.get_data0(base) == self.sym_self:
            base_ty = self.mono_struct_sema_type(self.current_method_owner_sym)
        if base_ty != 0:
            var resolved = self.sema.resolve_alias(base_ty as TypeId) as i32
            let tk = self.sema.get_type_kind(resolved as TypeId)
            if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
                resolved = self.sema.resolve_alias(self.sema.get_type_d0(resolved as TypeId) as TypeId) as i32
            var field_text = self.intern.resolve(field)
            if field_text.len() == 0:
                field_text = self.sema_symbol_text(field)
            let sema_field = if field_text.len() > 0: self.sema.pool_lookup_symbol(field_text) else: 0
            var field_ty = self.sema.struct_field_type(resolved, if sema_field != 0: sema_field else: field)
            if field_ty != 0:
                return field_ty
    if self.sema.typed_expr_types.contains(node):
        let typed = self.sema.typed_expr_types.get(node).unwrap()
        if typed != 0:
            return typed
    if kind == NodeKind.NK_IDENT or kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.pool.get_data0(node)
        let prim = self.sema.primitive_type_by_sym(sym)
        if prim != 0:
            return prim as i32
        if self.sema.named_types.contains(sym):
            return self.sema.named_types.get(sym).unwrap() as i32
        return 0
    if kind == NodeKind.NK_TYPE_GENERIC or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_TUPLE or kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        return self.sema.resolve_type_expr(node) as i32
    if kind == NodeKind.NK_INDEX:
        let base = self.pool.get_data0(node)
        let base_sym =
            if self.pool.kind(base) == NodeKind.NK_IDENT or self.pool.kind(base) == NodeKind.NK_TYPE_NAMED:
                self.pool.get_data0(base)
            else:
                0
        if base_sym == 0:
            return 0
        let arg1 = self.ast_static_type_expr(self.pool.get_data1(node))
        if arg1 == 0:
            return 0
        let args: Vec[i32] = Vec.new()
        args.push(arg1)
        var arg_count = 1
        if self.pool.get_data2(node) != 0:
            let arg2 = self.ast_static_type_expr(self.pool.get_data2(node))
            if arg2 == 0:
                return 0
            args.push(arg2)
            arg_count = 2
        return self.sema.find_generic_inst_type(base_sym, args, arg_count) as i32
    0

fn Codegen.classify_generic_call_intrinsic(self: Codegen, recv_type: i32, method_sym: i32) -> i32:
    if recv_type == 0 or method_sym == 0:
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let resolved = self.sema.resolve_alias(recv_type as TypeId)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_STR:
        if method_sym == self.sym_len:
            return MirIntrinsic.MIR_INTRINSIC_STR_LEN
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if tk == TypeKind.TY_ARRAY:
        if method_sym == self.sym_len:
            return MirIntrinsic.MIR_INTRINSIC_ARR_LEN
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym == 0:
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let type_name = self.intern.resolve(type_name_sym)
    let method_name = self.intern.resolve(method_sym)
    if type_name == "Vec":
        if method_name == "new": return MirIntrinsic.MIR_INTRINSIC_VEC_NEW
        if method_name == "with_capacity": return MirIntrinsic.MIR_INTRINSIC_VEC_WITH_CAPACITY
        if method_name == "push": return MirIntrinsic.MIR_INTRINSIC_VEC_PUSH
        if method_name == "get": return MirIntrinsic.MIR_INTRINSIC_VEC_GET
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_VEC_LEN
        if method_name == "set_i32": return MirIntrinsic.MIR_INTRINSIC_VEC_SET
        if method_name == "remove": return MirIntrinsic.MIR_INTRINSIC_VEC_REMOVE
        if method_name == "clear": return MirIntrinsic.MIR_INTRINSIC_VEC_CLEAR
        if method_name == "pop": return MirIntrinsic.MIR_INTRINSIC_VEC_POP
        if method_name == "iter": return MirIntrinsic.MIR_INTRINSIC_VEC_ITER
        if method_name == "iter_ref": return MirIntrinsic.MIR_INTRINSIC_VEC_ITER_REF
        if method_name == "slot": return MirIntrinsic.MIR_INTRINSIC_VEC_SLOT
        if method_name == "get_disjoint": return MirIntrinsic.MIR_INTRINSIC_VEC_GET_DISJOINT
        if method_name == "range": return MirIntrinsic.MIR_INTRINSIC_VEC_RANGE
        if method_name == "iter_place": return MirIntrinsic.MIR_INTRINSIC_VEC_ITER_PLACE
        if method_name == "map": return MirIntrinsic.MIR_INTRINSIC_VEC_MAP
        if method_name == "filter": return MirIntrinsic.MIR_INTRINSIC_VEC_FILTER
        if method_name == "fold": return MirIntrinsic.MIR_INTRINSIC_VEC_FOLD
        if method_name == "contains": return MirIntrinsic.MIR_INTRINSIC_VEC_CONTAINS
        if method_name == "join": return MirIntrinsic.MIR_INTRINSIC_VEC_JOIN
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "VecIter":
        if method_name == "next":
            return MirIntrinsic.MIR_INTRINSIC_VECITER_NEXT
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "VecIterRef":
        if method_name == "next":
            return MirIntrinsic.MIR_INTRINSIC_VECITERREF_NEXT
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "VecSlot":
        if method_name == "get": return MirIntrinsic.MIR_INTRINSIC_VECSLOT_GET
        if method_name == "set": return MirIntrinsic.MIR_INTRINSIC_VECSLOT_SET
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "VecRange":
        if method_name == "get": return MirIntrinsic.MIR_INTRINSIC_VECRANGE_GET
        if method_name == "set": return MirIntrinsic.MIR_INTRINSIC_VECRANGE_SET
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_VECRANGE_LEN
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "VecIterPlace":
        if method_name == "next": return MirIntrinsic.MIR_INTRINSIC_VECITERPLACE_NEXT
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "HashMap":
        if method_name == "new": return MirIntrinsic.MIR_INTRINSIC_MAP_NEW
        if method_name == "insert": return MirIntrinsic.MIR_INTRINSIC_MAP_INSERT
        if method_name == "get": return MirIntrinsic.MIR_INTRINSIC_MAP_GET
        if method_name == "contains": return MirIntrinsic.MIR_INTRINSIC_MAP_CONTAINS
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_MAP_LEN
        if method_name == "remove": return MirIntrinsic.MIR_INTRINSIC_MAP_REMOVE
        if method_name == "clear": return MirIntrinsic.MIR_INTRINSIC_MAP_CLEAR
        if method_name == "increment": return MirIntrinsic.MIR_INTRINSIC_MAP_INCREMENT
        if method_name == "keys": return MirIntrinsic.MIR_INTRINSIC_MAP_KEYS
        if method_name == "entry": return MirIntrinsic.MIR_INTRINSIC_MAP_ENTRY
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "HashMapEntry":
        if method_name == "or_insert": return MirIntrinsic.MIR_INTRINSIC_ENTRY_OR_INSERT
        if method_name == "get": return MirIntrinsic.MIR_INTRINSIC_ENTRY_GET
        if method_name == "set": return MirIntrinsic.MIR_INTRINSIC_ENTRY_SET
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "HashSet":
        if method_name == "new": return MirIntrinsic.MIR_INTRINSIC_MAP_NEW
        if method_name == "insert": return MirIntrinsic.MIR_INTRINSIC_MAP_INSERT
        if method_name == "contains": return MirIntrinsic.MIR_INTRINSIC_MAP_CONTAINS
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_MAP_LEN
        if method_name == "remove": return MirIntrinsic.MIR_INTRINSIC_MAP_REMOVE
        if method_name == "clear": return MirIntrinsic.MIR_INTRINSIC_MAP_CLEAR
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "Option":
        if method_name == "unwrap": return MirIntrinsic.MIR_INTRINSIC_OPT_UNWRAP
        if method_name == "is_some": return MirIntrinsic.MIR_INTRINSIC_OPT_IS_SOME
        if method_name == "is_none": return MirIntrinsic.MIR_INTRINSIC_OPT_IS_NONE
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "Channel":
        if method_name == "new": return MirIntrinsic.MIR_INTRINSIC_CHAN_CREATE
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "Sender":
        if method_name == "send": return MirIntrinsic.MIR_INTRINSIC_CHAN_SEND
        if method_name == "close": return MirIntrinsic.MIR_INTRINSIC_CHAN_CLOSE
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "Receiver":
        if method_name == "recv": return MirIntrinsic.MIR_INTRINSIC_CHAN_RECV
        if method_name == "close": return MirIntrinsic.MIR_INTRINSIC_CHAN_CLOSE
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "Atomic":
        if method_name == "load": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_LOAD
        if method_name == "store": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_STORE
        if method_name == "swap": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_SWAP
        if method_name == "fetch_add": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_ADD
        if method_name == "fetch_sub": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_SUB
        if method_name == "fetch_and": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_AND
        if method_name == "fetch_or": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_OR
        if method_name == "fetch_xor": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_XOR
        if method_name == "fetch_min": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_MIN
        if method_name == "fetch_max": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_MAX
        if method_name == "compare_exchange": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_CAS
        if method_name == "compare_exchange_weak": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_CAS_WEAK
        return MirIntrinsic.MIR_INTRINSIC_NONE
    MirIntrinsic.MIR_INTRINSIC_NONE

fn Codegen.classify_generic_call_intrinsic_by_llvm(self: Codegen, recv_ty: i64, method_sym: i32) -> i32:
    if recv_ty == 0 or method_sym == 0:
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let method_name = self.intern.resolve(method_sym)
    if self.vec_is_vec.contains(recv_ty):
        if method_name == "push": return MirIntrinsic.MIR_INTRINSIC_VEC_PUSH
        if method_name == "get": return MirIntrinsic.MIR_INTRINSIC_VEC_GET
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_VEC_LEN
        if method_name == "set_i32": return MirIntrinsic.MIR_INTRINSIC_VEC_SET
        if method_name == "remove": return MirIntrinsic.MIR_INTRINSIC_VEC_REMOVE
        if method_name == "clear": return MirIntrinsic.MIR_INTRINSIC_VEC_CLEAR
        if method_name == "pop": return MirIntrinsic.MIR_INTRINSIC_VEC_POP
        if method_name == "iter": return MirIntrinsic.MIR_INTRINSIC_VEC_ITER
        if method_name == "iter_ref": return MirIntrinsic.MIR_INTRINSIC_VEC_ITER_REF
        if method_name == "slot": return MirIntrinsic.MIR_INTRINSIC_VEC_SLOT
        if method_name == "range": return MirIntrinsic.MIR_INTRINSIC_VEC_RANGE
    MirIntrinsic.MIR_INTRINSIC_NONE

fn Codegen.mir_emit_intrinsic_call(self: Codegen, body: MirBody, intrinsic: i32, args_id: i32, dest_place: i32, next_bb: i32) -> bool:
    let byte_ty = wl_i8_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let void_ty = wl_void_type(self.context)
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let arg_count = body.call_arg_counts.get(args_id as i64)
    var result: i64 = 0

    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_NEW:
        var vec_elem_ty = wl_i64_type(self.context)
        let dest_sema_new = self.mir_intrinsic_dest_sema_type(body, dest_place)
        if dest_sema_new > 0:
            let resolved_new = self.mir_input.mir_resolve_alias(dest_sema_new)
            if self.mir_input.mir_get_type_kind(resolved_new) == TypeKind.TY_GENERIC_INST:
                let arg_count_new = self.mir_input.mir_get_type_d2(resolved_new)
                if arg_count_new > 0:
                    let te_start_new = self.mir_input.mir_get_type_d1(resolved_new)
                    let elem_tid_new = self.mir_input.mir_get_type_extra(te_start_new)
                    if elem_tid_new > 0:
                        let elem_llvm_new = self.mir_sema_type_to_llvm(elem_tid_new)
                        if elem_llvm_new != 0:
                            vec_elem_ty = elem_llvm_new
        let elem_size = self.abi_size_of(vec_elem_ty)
        let vec_ty = self.get_or_create_vec_type(0, vec_elem_ty)
        let alloca = wl_build_alloca(self.builder, vec_ty)
        wl_build_store(self.builder, self.build_default_value(vec_ty), alloca)
        let new_fn = self.ensure_vec_runtime_fn("with_vec_new_out", void_ty, 2)
        let new_ty = self.get_vec_fn_type("with_vec_new_out", void_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(alloca)
        args.push(wl_const_int(i64_ty, elem_size, 0))
        let _ = wl_build_call(self.builder, new_ty, new_fn, vec_data_i64(&args), 2)
        result = wl_build_load(self.builder, vec_ty, alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_WITH_CAPACITY:
        let wc_cap = self.mir_intrinsic_arg(body, args_id, 0)
        let wc_cap64 = self.coerce_int_ext(wc_cap, i64_ty, false)
        var wc_elem_ty = i64_ty
        let wc_dst_ty = self.mir_intrinsic_dest_sema_type(body, dest_place)
        if wc_dst_ty > 0:
            let wc_res = self.mir_input.mir_resolve_alias(wc_dst_ty)
            if self.mir_input.mir_get_type_kind(wc_res) == TypeKind.TY_GENERIC_INST:
                let wc_ac = self.mir_input.mir_get_type_d2(wc_res)
                if wc_ac > 0:
                    let wc_te = self.mir_input.mir_get_type_d1(wc_res)
                    let wc_et = self.mir_input.mir_get_type_extra(wc_te)
                    if wc_et > 0:
                        let wc_ll = self.mir_sema_type_to_llvm(wc_et)
                        if wc_ll != 0:
                            wc_elem_ty = wc_ll
        let wc_esz = self.abi_size_of(wc_elem_ty)
        let wc_vty = self.get_or_create_vec_type(0, wc_elem_ty)
        let wc_al = wl_build_alloca(self.builder, wc_vty)
        wl_build_store(self.builder, self.build_default_value(wc_vty), wc_al)
        let wc_fn = self.ensure_vec_runtime_fn("with_vec_new_with_capacity_out", void_ty, 3)
        let wc_ft = self.get_vec_fn_type("with_vec_new_with_capacity_out", void_ty, 3)
        let wc_args: Vec[i64] = Vec.new()
        wc_args.push(wc_al)
        wc_args.push(wl_const_int(i64_ty, wc_esz, 0))
        wc_args.push(wc_cap64)
        let _ = wl_build_call(self.builder, wc_ft, wc_fn, vec_data_i64(&wc_args), 3)
        result = wl_build_load(self.builder, wc_vty, wc_al)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_PUSH:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let elem_raw = self.mir_intrinsic_arg(body, args_id, 1)
        // Coerce element to match Vec's element type (e.g. f64 literal → f32 for Vec[f32])
        var elem = elem_raw
        let push_arg_start = body.call_arg_starts.get(args_id as i64)
        let push_recv_op = body.call_arg_operands.get(push_arg_start as i64)
        let push_elem_ty = self.mir_vec_elem_type(body, push_recv_op)
        if push_elem_ty != 0 and wl_type_of(elem_raw) != push_elem_ty:
            elem = self.coerce_value_to_type(elem_raw, push_elem_ty)
        let elem_alloca = wl_build_alloca(self.builder, wl_type_of(elem))
        wl_build_store(self.builder, elem, elem_alloca)
        let push_fn = self.ensure_vec_runtime_fn("with_vec_push", void_ty, 2)
        let push_ty = self.get_vec_fn_type("with_vec_push", void_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        args.push(elem_alloca)
        result = wl_build_call(self.builder, push_ty, push_fn, vec_data_i64(&args), 2)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_GET:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let idx = self.mir_intrinsic_arg(body, args_id, 1)
        let idx64 = self.coerce_int(idx, i64_ty)
        var elem_ty = self.mir_dest_llvm_type(body, dest_place)
        if elem_ty == 0:
            let recv_op = body.call_arg_operands.get(arg_start as i64)
            elem_ty = self.mir_vec_elem_type(body, recv_op)
        if elem_ty == 0:
            elem_ty = i64_ty
        let get_fn = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
        let get_ty = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        args.push(idx64)
        let raw_ptr = wl_build_call(self.builder, get_ty, get_fn, vec_data_i64(&args), 2)
        result = wl_build_load(self.builder, elem_ty, raw_ptr)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_GET_REF:
        let gr_recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let gr_idx = self.mir_intrinsic_arg(body, args_id, 1)
        let gr_idx64 = self.coerce_int(gr_idx, i64_ty)
        let gr_fn = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
        let gr_ty = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
        let gr_args: Vec[i64] = Vec.new()
        gr_args.push(gr_recv_ptr)
        gr_args.push(gr_idx64)
        result = wl_build_call(self.builder, gr_ty, gr_fn, vec_data_i64(&gr_args), 2)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_LEN:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let len_fn = self.ensure_vec_runtime_fn("with_vec_len", i64_ty, 1)
        let len_ty = self.get_vec_fn_type("with_vec_len", i64_ty, 1)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        result = wl_build_call(self.builder, len_ty, len_fn, vec_data_i64(&args), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_SET:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let idx = self.mir_intrinsic_arg(body, args_id, 1)
        let val = self.mir_intrinsic_arg(body, args_id, 2)
        let idx64 = self.coerce_int(idx, i64_ty)
        let val32 = self.coerce_int(val, i32_ty)
        let set_fn_name = "with_vec_set_i32"
        var set_fn = wl_get_named_function(self.llmod, set_fn_name)
        let param_types: Vec[i64] = Vec.new()
        param_types.push(ptr_ty)
        param_types.push(i64_ty)
        param_types.push(i32_ty)
        let set_ty = wl_function_type(void_ty, vec_data_i64(&param_types), 3, 0)
        if set_fn == 0:
            set_fn = wl_add_function(self.llmod, set_fn_name, set_ty)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        args.push(idx64)
        args.push(val32)
        result = wl_build_call(self.builder, set_ty, set_fn, vec_data_i64(&args), 3)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_REMOVE:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let idx = self.mir_intrinsic_arg(body, args_id, 1)
        let idx64 = self.coerce_int(idx, i64_ty)
        let remove_fn = self.ensure_vec_runtime_fn("with_vec_remove", void_ty, 2)
        let remove_ty = self.get_vec_fn_type("with_vec_remove", void_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        args.push(idx64)
        result = wl_build_call(self.builder, remove_ty, remove_fn, vec_data_i64(&args), 2)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_CLEAR:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let clear_fn = self.ensure_vec_runtime_fn("with_vec_clear", void_ty, 1)
        let clear_ty = self.get_vec_fn_type("with_vec_clear", void_ty, 1)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        result = wl_build_call(self.builder, clear_ty, clear_fn, vec_data_i64(&args), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_POP:
        // Pop: get last element, remove it. Simplified: just return default.
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let recv = self.mir_intrinsic_recv_vec_value(body, args_id)
        let len = wl_build_extract_value(self.builder, recv, 1)
        let last_idx = wl_build_sub(self.builder, len, wl_const_int(i64_ty, 1, 0))
        let get_fn = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
        let get_ty = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
        let get_args: Vec[i64] = Vec.new()
        get_args.push(recv_ptr)
        get_args.push(last_idx)
        let raw_ptr = wl_build_call(self.builder, get_ty, get_fn, vec_data_i64(&get_args), 2)
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        let elem_ty = self.mir_vec_elem_type(body, recv_op)
        if elem_ty != 0:
            result = wl_build_load(self.builder, elem_ty, raw_ptr)
        else:
            result = wl_build_load(self.builder, i64_ty, raw_ptr)
        let remove_fn = self.ensure_vec_runtime_fn("with_vec_remove", void_ty, 2)
        let remove_ty = self.get_vec_fn_type("with_vec_remove", void_ty, 2)
        let rm_args: Vec[i64] = Vec.new()
        rm_args.push(recv_ptr)
        rm_args.push(last_idx)
        let _ = wl_build_call(self.builder, remove_ty, remove_fn, vec_data_i64(&rm_args), 2)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_NEW:
        // Determine key/val sizes from dest sema type (TypeKind.TY_GENERIC_INST).
        var hm_key_size: i64 = 8
        var hm_val_size: i64 = 8
        var hm_ty: i64 = 0
        var hm_base_sym = 0
        let dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        if dest_sema > 0:
            let resolved = self.mir_input.mir_resolve_alias(dest_sema)
            let tk = self.mir_input.mir_get_type_kind(resolved)
            if tk == TypeKind.TY_GENERIC_INST:
                hm_base_sym = self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_d0(resolved))
                let gi_arg_count = self.mir_input.mir_get_type_d2(resolved)
                if hm_base_sym == self.sym_hashmap and gi_arg_count == 2:
                    let args_start = self.mir_input.mir_get_type_d1(resolved)
                    let key_sema = self.mir_input.mir_get_type_extra(args_start)
                    let val_sema = self.mir_input.mir_get_type_extra(args_start + 1)
                    let key_llvm = self.sema_type_to_llvm(key_sema)
                    let val_llvm = self.sema_type_to_llvm(val_sema)
                    if key_llvm != 0 and val_llvm != 0:
                        hm_key_size = self.abi_size_of(key_llvm)
                        hm_val_size = self.abi_size_of(val_llvm)
                        hm_ty = self.get_or_create_hashmap_type(dest_sema, key_llvm, val_llvm)
                else if hm_base_sym == self.sym_hashset and gi_arg_count > 0:
                    let args_start = self.mir_input.mir_get_type_d1(resolved)
                    let elem_sema = self.mir_input.mir_get_type_extra(args_start)
                    let elem_llvm = self.sema_type_to_llvm(elem_sema)
                    if elem_llvm != 0:
                        hm_key_size = self.abi_size_of(elem_llvm)
                        hm_val_size = 1
                        hm_ty = self.get_or_create_hashset_type(dest_sema, elem_llvm)
        let new_fn = self.ensure_hashmap_new_declared()
        let fn_ty = self.get_hashmap_new_fn_type()
        let new_args: Vec[i64] = Vec.new()
        new_args.push(wl_const_int(i64_ty, hm_key_size, 0))
        new_args.push(wl_const_int(i64_ty, hm_val_size, 0))
        let handle = wl_build_call(self.builder, fn_ty, new_fn, vec_data_i64(&new_args), 2)
        // Wrap handle in HashMap struct { ptr }.
        if hm_ty == 0:
            if hm_base_sym == self.sym_hashset:
                hm_ty = self.get_or_create_hashset_type(0, i64_ty)
            else:
                hm_ty = self.get_or_create_hashmap_type(0, i64_ty, i64_ty)
        let empty = self.build_default_value(hm_ty)
        result = wl_build_insert_value(self.builder, empty, handle, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_INSERT:
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        let recv_base_sym = self.mir_map_recv_base_sym(body, recv_op)
        let map_ptr = self.mir_intrinsic_map_handle(body, args_id)
        let key_raw = self.mir_intrinsic_arg(body, args_id, 1)
        let key_ty = self.mir_hashmap_key_type(body, recv_op)
        let key = if key_ty != 0 and wl_type_of(key_raw) != key_ty: self.coerce_value_to_type(key_raw, key_ty) else: key_raw
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        let val_alloca =
            if recv_base_sym == self.sym_hashset:
                let set_present = wl_const_int(byte_ty, 1, 0)
                let set_val_alloca = wl_build_alloca(self.builder, byte_ty)
                wl_build_store(self.builder, set_present, set_val_alloca)
                set_val_alloca
            else:
                let val_raw = self.mir_intrinsic_arg(body, args_id, 2)
                let val_ty = self.mir_hashmap_value_type(body, recv_op)
                let val = if val_ty != 0 and wl_type_of(val_raw) != val_ty: self.coerce_value_to_type(val_raw, val_ty) else: val_raw
                let map_val_alloca = wl_build_alloca(self.builder, wl_type_of(val))
                wl_build_store(self.builder, val, map_val_alloca)
                map_val_alloca
        let is_str_val = wl_const_int(i64_ty, if self.is_str_type(wl_type_of(key)): 1 else: 0, 0)
        let fn_val = self.ensure_hm_fn("with_hashmap_insert", void_ty)
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(void_ty, vec_data_i64(&params), 4, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(val_alloca)
        args.push(is_str_val)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 4)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_GET:
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        let map_ptr = self.mir_intrinsic_map_handle(body, args_id)
        let key_raw = self.mir_intrinsic_arg(body, args_id, 1)
        let key_ty = self.mir_hashmap_key_type(body, recv_op)
        let key = if key_ty != 0 and wl_type_of(key_raw) != key_ty: self.coerce_value_to_type(key_raw, key_ty) else: key_raw
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        // Determine value type for the output buffer.
        // Sema gives us V (the value type), not Option[V].
        let dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        var val_ty = self.mir_sema_type_to_llvm(dest_sema)
        if val_ty == 0:
            val_ty = i64_ty
        let out_alloca = wl_build_alloca(self.builder, val_ty)
        let is_str_val = wl_const_int(i64_ty, if self.is_str_type(wl_type_of(key)): 1 else: 0, 0)
        let fn_val = self.ensure_hm_fn("with_hashmap_get", i64_ty)
        let get_params: Vec[i64] = Vec.new()
        get_params.push(ptr_ty)
        get_params.push(ptr_ty)
        get_params.push(ptr_ty)
        get_params.push(i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&get_params), 4, 0)
        let get_args: Vec[i64] = Vec.new()
        get_args.push(map_ptr)
        get_args.push(key_alloca)
        get_args.push(out_alloca)
        get_args.push(is_str_val)
        let found = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&get_args), 4)
        let val = wl_build_load(self.builder, val_ty, out_alloca)
        // Always wrap in Option[V].
        var dest_llvm = self.get_or_create_option_type(0, val_ty)
        if dest_llvm != 0:
            let is_found = wl_build_icmp(self.builder, wl_int_ne(), found, wl_const_int(i64_ty, 0, 0))
            let some_val = self.build_option_some(val, dest_llvm)
            let none_val = self.build_option_none(dest_llvm)
            result = wl_build_select(self.builder, is_found, some_val, none_val)
        else:
            result = val

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_CONTAINS:
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        let map_ptr = self.mir_intrinsic_map_handle(body, args_id)
        let key_raw = self.mir_intrinsic_arg(body, args_id, 1)
        let key_ty = self.mir_hashmap_key_type(body, recv_op)
        let key = if key_ty != 0 and wl_type_of(key_raw) != key_ty: self.coerce_value_to_type(key_raw, key_ty) else: key_raw
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        let is_str_val = wl_const_int(i64_ty, if self.is_str_type(wl_type_of(key)): 1 else: 0, 0)
        let fn_val = self.ensure_hm_fn("with_hashmap_contains", i64_ty)
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&params), 3, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(is_str_val)
        let raw = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 3)
        result = wl_build_icmp(self.builder, wl_int_ne(), raw, wl_const_int(i64_ty, 0, 0))

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_LEN:
        let map_ptr = self.mir_intrinsic_map_handle(body, args_id)
        let fn_val = self.ensure_hm_fn("with_hashmap_len", i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&self.make_ptr_vec()), 1, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_REMOVE:
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        let map_ptr = self.mir_intrinsic_map_handle(body, args_id)
        let key_raw = self.mir_intrinsic_arg(body, args_id, 1)
        let key_ty = self.mir_hashmap_key_type(body, recv_op)
        let key = if key_ty != 0 and wl_type_of(key_raw) != key_ty: self.coerce_value_to_type(key_raw, key_ty) else: key_raw
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        let is_str_val = wl_const_int(i64_ty, if self.is_str_type(wl_type_of(key)): 1 else: 0, 0)
        let recv_base_sym = self.mir_map_recv_base_sym(body, recv_op)
        let fn_val = self.ensure_hm_fn("with_hashmap_remove", i64_ty)
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&params), 4, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        if recv_base_sym == self.sym_hashmap:
            var val_ty = self.mir_hashmap_value_type(body, recv_op)
            if val_ty == 0:
                val_ty = i64_ty
            let out_alloca = wl_build_alloca(self.builder, val_ty)
            args.push(out_alloca)
            args.push(is_str_val)
            let found = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 4)
            let val = wl_build_load(self.builder, val_ty, out_alloca)
            var dest_llvm = self.get_or_create_option_type(0, val_ty)
            if dest_llvm != 0:
                let is_found = wl_build_icmp(self.builder, wl_int_ne(), found, wl_const_int(i64_ty, 0, 0))
                let some_val = self.build_option_some(val, dest_llvm)
                let none_val = self.build_option_none(dest_llvm)
                result = wl_build_select(self.builder, is_found, some_val, none_val)
            else:
                result = val
        else:
            args.push(wl_const_null(ptr_ty))
            args.push(is_str_val)
            let raw = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 4)
            result = wl_build_icmp(self.builder, wl_int_ne(), raw, wl_const_int(i64_ty, 0, 0))

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_CLEAR:
        let map_ptr = self.mir_intrinsic_map_handle(body, args_id)
        let fn_val = self.ensure_hm_fn("with_hashmap_clear", void_ty)
        let fn_ty = wl_function_type(void_ty, vec_data_i64(&self.make_ptr_vec()), 1, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_KEYS:
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        let map_ptr = self.mir_intrinsic_map_handle(body, args_id)
        var key_ty = self.mir_hashmap_key_type(body, recv_op)
        if key_ty == 0:
            key_ty = i64_ty
        let key_size = self.abi_size_of(key_ty)
        var vec_ty = self.mir_dest_llvm_type(body, dest_place)
        if vec_ty == 0:
            vec_ty = self.get_or_create_vec_type(0, key_ty)
        let out_alloca = wl_build_alloca(self.builder, vec_ty)
        wl_build_store(self.builder, self.build_default_value(vec_ty), out_alloca)
        let keys_name = "with_hashmap_keys_out"
        var keys_fn = wl_get_named_function(self.llmod, keys_name)
        let keys_params: Vec[i64] = Vec.new()
        keys_params.push(ptr_ty)
        keys_params.push(ptr_ty)
        keys_params.push(i64_ty)
        let keys_ty = wl_function_type(void_ty, vec_data_i64(&keys_params), 3, 0)
        if keys_fn == 0:
            keys_fn = wl_add_function(self.llmod, keys_name, keys_ty)
        let keys_args: Vec[i64] = Vec.new()
        keys_args.push(out_alloca)
        keys_args.push(map_ptr)
        keys_args.push(wl_const_int(i64_ty, key_size, 0))
        let _ = wl_build_call(self.builder, keys_ty, keys_fn, vec_data_i64(&keys_args), 3)
        result = wl_build_load(self.builder, vec_ty, out_alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_ENTRY:
        // HashMap.entry(key) → HashMapEntry { map_ptr, key }
        let me_map_ptr = self.mir_intrinsic_map_handle(body, args_id)
        let me_recv_op = body.call_arg_operands.get(arg_start as i64)
        let me_key_raw = self.mir_intrinsic_arg(body, args_id, 1)
        var me_key_ty = self.mir_hashmap_key_type(body, me_recv_op)
        if me_key_ty == 0:
            me_key_ty = wl_type_of(me_key_raw)
        let me_key = if me_key_ty != 0 and wl_type_of(me_key_raw) != me_key_ty: self.coerce_value_to_type(me_key_raw, me_key_ty) else: me_key_raw
        let me_fields: Vec[i64] = Vec.new()
        me_fields.push(ptr_ty)
        me_fields.push(me_key_ty)
        let me_struct_ty = wl_struct_type(self.context, vec_data_i64(&me_fields), 2, 0)
        let me_alloca = wl_build_alloca(self.builder, me_struct_ty)
        let me_f0 = wl_build_struct_gep(self.builder, me_struct_ty, me_alloca, 0)
        wl_build_store(self.builder, me_map_ptr, me_f0)
        let me_f1 = wl_build_struct_gep(self.builder, me_struct_ty, me_alloca, 1)
        wl_build_store(self.builder, me_key, me_f1)
        result = wl_build_load(self.builder, me_struct_ty, me_alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ENTRY_OR_INSERT:
        // HashMapEntry.or_insert(default) → contains? get : insert+get
        let oi_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let oi_default = self.mir_intrinsic_arg(body, args_id, 1)
        let oi_recv_op = body.call_arg_operands.get(arg_start as i64)
        let oi_recv_sema = self.mir_operand_sema_type(body, oi_recv_op)
        var oi_key_ty: i64 = i64_ty
        var oi_val_ty: i64 = wl_type_of(oi_default)
        if oi_recv_sema > 0:
            let oi_resolved = self.mir_input.mir_resolve_alias(oi_recv_sema)
            if self.mir_input.mir_get_type_kind(oi_resolved) == TypeKind.TY_GENERIC_INST:
                let oi_te_start = self.mir_input.mir_get_type_d1(oi_resolved)
                let oi_key_tid = self.mir_input.mir_get_type_extra(oi_te_start)
                if oi_key_tid > 0:
                    let oi_kt = self.mir_sema_type_to_llvm(oi_key_tid)
                    if oi_kt != 0:
                        oi_key_ty = oi_kt
                let oi_val_tid = self.mir_input.mir_get_type_extra(oi_te_start + 1)
                if oi_val_tid > 0:
                    let oi_vt = self.mir_sema_type_to_llvm(oi_val_tid)
                    if oi_vt != 0:
                        oi_val_ty = oi_vt
        let oi_entry_fields: Vec[i64] = Vec.new()
        oi_entry_fields.push(ptr_ty)
        oi_entry_fields.push(oi_key_ty)
        let oi_entry_ty = wl_struct_type(self.context, vec_data_i64(&oi_entry_fields), 2, 0)
        let oi_mp = wl_build_struct_gep(self.builder, oi_entry_ty, oi_ptr, 0)
        let oi_map_ptr = wl_build_load(self.builder, ptr_ty, oi_mp)
        let oi_kp = wl_build_struct_gep(self.builder, oi_entry_ty, oi_ptr, 1)
        let oi_key = wl_build_load(self.builder, oi_key_ty, oi_kp)
        let oi_is_str = wl_const_int(i64_ty, if self.is_str_type(oi_key_ty): 1 else: 0, 0)
        let oi_key_alloca = wl_build_alloca(self.builder, oi_key_ty)
        wl_build_store(self.builder, oi_key, oi_key_alloca)
        // contains?
        let oi_contains_fn = self.ensure_hm_fn("with_hashmap_contains", i64_ty)
        let oi_c_params: Vec[i64] = Vec.new()
        oi_c_params.push(ptr_ty)
        oi_c_params.push(ptr_ty)
        oi_c_params.push(i64_ty)
        let oi_c_fn_ty = wl_function_type(i64_ty, vec_data_i64(&oi_c_params), 3, 0)
        let oi_c_args: Vec[i64] = Vec.new()
        oi_c_args.push(oi_map_ptr)
        oi_c_args.push(oi_key_alloca)
        oi_c_args.push(oi_is_str)
        let oi_found = wl_build_call(self.builder, oi_c_fn_ty, oi_contains_fn, vec_data_i64(&oi_c_args), 3)
        let oi_cond = wl_build_icmp(self.builder, wl_int_eq(), oi_found, wl_const_int(i64_ty, 0, 0))
        let oi_insert_bb = wl_append_bb(self.context, self.current_function, "entry.insert")
        let oi_get_bb = wl_append_bb(self.context, self.current_function, "entry.get")
        wl_build_cond_br(self.builder, oi_cond, oi_insert_bb, oi_get_bb)
        // insert default
        wl_position_at_end(self.builder, oi_insert_bb)
        let oi_val_alloca = wl_build_alloca(self.builder, oi_val_ty)
        wl_build_store(self.builder, oi_default, oi_val_alloca)
        let oi_ins_fn = self.ensure_hm_fn("with_hashmap_insert", void_ty)
        let oi_i_params: Vec[i64] = Vec.new()
        oi_i_params.push(ptr_ty)
        oi_i_params.push(ptr_ty)
        oi_i_params.push(ptr_ty)
        oi_i_params.push(i64_ty)
        let oi_i_fn_ty = wl_function_type(void_ty, vec_data_i64(&oi_i_params), 4, 0)
        let oi_i_args: Vec[i64] = Vec.new()
        oi_i_args.push(oi_map_ptr)
        oi_i_args.push(oi_key_alloca)
        oi_i_args.push(oi_val_alloca)
        oi_i_args.push(oi_is_str)
        let _ = wl_build_call(self.builder, oi_i_fn_ty, oi_ins_fn, vec_data_i64(&oi_i_args), 4)
        wl_build_br(self.builder, oi_get_bb)
        // get value
        wl_position_at_end(self.builder, oi_get_bb)
        let oi_out_alloca = wl_build_alloca(self.builder, oi_val_ty)
        let oi_get_fn = self.ensure_hm_fn("with_hashmap_get", i64_ty)
        let oi_g_params: Vec[i64] = Vec.new()
        oi_g_params.push(ptr_ty)
        oi_g_params.push(ptr_ty)
        oi_g_params.push(ptr_ty)
        oi_g_params.push(i64_ty)
        let oi_g_fn_ty = wl_function_type(i64_ty, vec_data_i64(&oi_g_params), 4, 0)
        let oi_g_args: Vec[i64] = Vec.new()
        oi_g_args.push(oi_map_ptr)
        oi_g_args.push(oi_key_alloca)
        oi_g_args.push(oi_out_alloca)
        oi_g_args.push(oi_is_str)
        let _ = wl_build_call(self.builder, oi_g_fn_ty, oi_get_fn, vec_data_i64(&oi_g_args), 4)
        result = wl_build_load(self.builder, oi_val_ty, oi_out_alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ENTRY_GET:
        // HashMapEntry.get() → hashmap_get(map_ptr, &key)
        let eg_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let eg_recv_op = body.call_arg_operands.get(arg_start as i64)
        let eg_recv_sema = self.mir_operand_sema_type(body, eg_recv_op)
        var eg_key_ty: i64 = i64_ty
        var eg_val_ty: i64 = i64_ty
        if eg_recv_sema > 0:
            let eg_resolved = self.mir_input.mir_resolve_alias(eg_recv_sema)
            if self.mir_input.mir_get_type_kind(eg_resolved) == TypeKind.TY_GENERIC_INST:
                let eg_te_start = self.mir_input.mir_get_type_d1(eg_resolved)
                let eg_key_tid = self.mir_input.mir_get_type_extra(eg_te_start)
                if eg_key_tid > 0:
                    let eg_kt = self.mir_sema_type_to_llvm(eg_key_tid)
                    if eg_kt != 0:
                        eg_key_ty = eg_kt
                let eg_val_tid = self.mir_input.mir_get_type_extra(eg_te_start + 1)
                if eg_val_tid > 0:
                    let eg_vt = self.mir_sema_type_to_llvm(eg_val_tid)
                    if eg_vt != 0:
                        eg_val_ty = eg_vt
        let eg_dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        if eg_dest_sema > 0:
            let eg_dt = self.mir_sema_type_to_llvm(self.mir_input.mir_resolve_alias(eg_dest_sema))
            if eg_dt != 0:
                eg_val_ty = eg_dt
        let eg_entry_fields: Vec[i64] = Vec.new()
        eg_entry_fields.push(ptr_ty)
        eg_entry_fields.push(eg_key_ty)
        let eg_entry_ty = wl_struct_type(self.context, vec_data_i64(&eg_entry_fields), 2, 0)
        let eg_mp = wl_build_struct_gep(self.builder, eg_entry_ty, eg_ptr, 0)
        let eg_map_ptr = wl_build_load(self.builder, ptr_ty, eg_mp)
        let eg_kp = wl_build_struct_gep(self.builder, eg_entry_ty, eg_ptr, 1)
        let eg_key = wl_build_load(self.builder, eg_key_ty, eg_kp)
        let eg_is_str = wl_const_int(i64_ty, if self.is_str_type(eg_key_ty): 1 else: 0, 0)
        let eg_key_alloca = wl_build_alloca(self.builder, eg_key_ty)
        wl_build_store(self.builder, eg_key, eg_key_alloca)
        let eg_out_alloca = wl_build_alloca(self.builder, eg_val_ty)
        let eg_get_fn = self.ensure_hm_fn("with_hashmap_get", i64_ty)
        let eg_g_params: Vec[i64] = Vec.new()
        eg_g_params.push(ptr_ty)
        eg_g_params.push(ptr_ty)
        eg_g_params.push(ptr_ty)
        eg_g_params.push(i64_ty)
        let eg_g_fn_ty = wl_function_type(i64_ty, vec_data_i64(&eg_g_params), 4, 0)
        let eg_g_args: Vec[i64] = Vec.new()
        eg_g_args.push(eg_map_ptr)
        eg_g_args.push(eg_key_alloca)
        eg_g_args.push(eg_out_alloca)
        eg_g_args.push(eg_is_str)
        let _ = wl_build_call(self.builder, eg_g_fn_ty, eg_get_fn, vec_data_i64(&eg_g_args), 4)
        result = wl_build_load(self.builder, eg_val_ty, eg_out_alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ENTRY_SET:
        // HashMapEntry.set(value) → hashmap_insert(map_ptr, &key, &value)
        let es_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let es_val = self.mir_intrinsic_arg(body, args_id, 1)
        let es_recv_op = body.call_arg_operands.get(arg_start as i64)
        let es_recv_sema = self.mir_operand_sema_type(body, es_recv_op)
        var es_key_ty: i64 = i64_ty
        if es_recv_sema > 0:
            let es_resolved = self.mir_input.mir_resolve_alias(es_recv_sema)
            if self.mir_input.mir_get_type_kind(es_resolved) == TypeKind.TY_GENERIC_INST:
                let es_te_start = self.mir_input.mir_get_type_d1(es_resolved)
                let es_key_tid = self.mir_input.mir_get_type_extra(es_te_start)
                if es_key_tid > 0:
                    let es_kt = self.mir_sema_type_to_llvm(es_key_tid)
                    if es_kt != 0:
                        es_key_ty = es_kt
        let es_entry_fields: Vec[i64] = Vec.new()
        es_entry_fields.push(ptr_ty)
        es_entry_fields.push(es_key_ty)
        let es_entry_ty = wl_struct_type(self.context, vec_data_i64(&es_entry_fields), 2, 0)
        let es_mp = wl_build_struct_gep(self.builder, es_entry_ty, es_ptr, 0)
        let es_map_ptr = wl_build_load(self.builder, ptr_ty, es_mp)
        let es_kp = wl_build_struct_gep(self.builder, es_entry_ty, es_ptr, 1)
        let es_key = wl_build_load(self.builder, es_key_ty, es_kp)
        let es_is_str = wl_const_int(i64_ty, if self.is_str_type(es_key_ty): 1 else: 0, 0)
        let es_key_alloca = wl_build_alloca(self.builder, es_key_ty)
        wl_build_store(self.builder, es_key, es_key_alloca)
        let es_val_alloca = wl_build_alloca(self.builder, wl_type_of(es_val))
        wl_build_store(self.builder, es_val, es_val_alloca)
        let es_ins_fn = self.ensure_hm_fn("with_hashmap_insert", void_ty)
        let es_i_params: Vec[i64] = Vec.new()
        es_i_params.push(ptr_ty)
        es_i_params.push(ptr_ty)
        es_i_params.push(ptr_ty)
        es_i_params.push(i64_ty)
        let es_i_fn_ty = wl_function_type(void_ty, vec_data_i64(&es_i_params), 4, 0)
        let es_i_args: Vec[i64] = Vec.new()
        es_i_args.push(es_map_ptr)
        es_i_args.push(es_key_alloca)
        es_i_args.push(es_val_alloca)
        es_i_args.push(es_is_str)
        result = wl_build_call(self.builder, es_i_fn_ty, es_ins_fn, vec_data_i64(&es_i_args), 4)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_OPT_IS_SOME:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let recv_tk = wl_get_type_kind(wl_type_of(recv))
        if recv_tk == wl_struct_type_kind():
            let disc = wl_build_extract_value(self.builder, recv, 0)
            // Some = tag 0, None = tag 1. is_some → tag == 0.
            result = wl_build_icmp(self.builder, wl_int_eq(), disc, wl_const_int(wl_type_of(disc), 0, 0))
        else if recv_tk == wl_pointer_type_kind():
            result = wl_build_icmp(self.builder, wl_int_ne(), recv, wl_const_null(wl_type_of(recv)))
        else:
            // Non-struct Option (e.g., raw value) — treat as always Some
            result = wl_const_int(wl_i1_type(self.context), 1, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_OPT_UNWRAP:
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        let recv_sema = self.mir_operand_sema_type(body, recv_op)
        let recv_resolved = if recv_sema > 0: self.mir_input.mir_resolve_alias(recv_sema) else: 0
        var recv_is_result = false
        if recv_resolved > 0 and self.mir_input.mir_get_type_kind(recv_resolved) == TypeKind.TY_GENERIC_INST:
            let recv_name_sym = self.mir_input.mir_get_type_d0(recv_resolved)
            if recv_name_sym > 0:
                recv_is_result = recv_name_sym == self.sym_result
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let recv_ty = wl_type_of(recv)
        let recv_tk = wl_get_type_kind(recv_ty)
        if recv_tk == wl_struct_type_kind():
            if recv_is_result:
                let dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
                var payload_ty = self.mir_sema_type_to_llvm(dest_sema)
                if payload_ty == 0:
                    payload_ty = self.mir_builtin_variant_payload_llvm_type(recv_sema, 0)
                if payload_ty == 0:
                    let res_ok_sema = self.mir_builtin_variant_payload_sema_type(recv_sema, 0)
                    if res_ok_sema > 0:
                        payload_ty = self.mir_sema_type_to_llvm(res_ok_sema)
                result = self.extract_result_payload(recv, payload_ty)
            else:
                result = wl_build_extract_value(self.builder, recv, 1)
        else if recv_tk == wl_pointer_type_kind():
            result = recv
        else:
            // Non-struct Option — return the raw value
            result = recv

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_LEN:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        if self.debug_mir_codegen_enabled():
            with_eprint(f"[mir-str-len] recv_ty_kind={wl_get_type_kind(wl_type_of(recv))}")
        result = wl_build_extract_value(self.builder, recv, 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_BYTE_AT:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let index = self.mir_intrinsic_arg(body, args_id, 1)
        let index64 = self.coerce_int(index, i64_ty)
        let fn_val = self.ensure_c_fn("with_str_byte_at", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(index64)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_byte_at", i32_ty, 2), fn_val, vec_data_i64(&args), 2)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_SLICE:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let str_ptr = wl_build_extract_value(self.builder, recv, 0)
        let start = self.mir_intrinsic_arg(body, args_id, 1)
        let end = self.mir_intrinsic_arg(body, args_id, 2)
        let start64 = self.coerce_int(start, i64_ty)
        let end64 = self.coerce_int(end, i64_ty)
        let i8_ty = wl_i8_type(self.context)
        let indices: Vec[i64] = Vec.new()
        indices.push(start64)
        let new_ptr = wl_build_gep(self.builder, i8_ty, str_ptr, vec_data_i64(&indices), 1)
        let new_len = wl_build_sub(self.builder, end64, start64)
        result = self.build_str_value(new_ptr, new_len)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_CONTAINS:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let needle = self.mir_intrinsic_arg(body, args_id, 1)
        let fn_val = self.ensure_c_fn("with_str_contains", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(needle)
        let raw = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_contains", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
        result = wl_build_icmp(self.builder, wl_int_ne(), raw, wl_const_int(i32_ty, 0, 0))

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_STARTS_WITH:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let prefix = self.mir_intrinsic_arg(body, args_id, 1)
        let fn_val = self.ensure_c_fn("with_str_starts_with", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(prefix)
        let raw = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_starts_with", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
        result = wl_build_icmp(self.builder, wl_int_ne(), raw, wl_const_int(i32_ty, 0, 0))

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_ENDS_WITH:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let suffix = self.mir_intrinsic_arg(body, args_id, 1)
        let fn_val = self.ensure_c_fn("with_str_ends_with", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(suffix)
        let raw = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_ends_with", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
        result = wl_build_icmp(self.builder, wl_int_ne(), raw, wl_const_int(i32_ty, 0, 0))

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_FIND:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let needle = self.mir_intrinsic_arg(body, args_id, 1)
        let fn_val = self.ensure_c_fn("with_str_index_of", i64_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(needle)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_index_of", i64_ty, 2), fn_val, vec_data_i64(&args), 2)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VECITER_NEXT:
        // VecIter[T].next() — advance iterator, return Option[T]
        // VecIter = { data_ptr: i64, len: i64, idx: i64 }
        let iter_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        // Determine element type from the destination type.
        // Newer sema correctly types next() as Option[T], but older MIR/seed
        // paths may still surface the raw payload type T here.
        let dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        var elem_ty: i64 = 0
        if dest_sema > 0:
            let resolved_dest = self.mir_input.mir_resolve_alias(dest_sema)
            let dest_tk = self.mir_input.mir_get_type_kind(resolved_dest)
            if dest_tk == TypeKind.TY_GENERIC_INST:
                let dest_name_sym = self.sema_sym_to_codegen_sym(self.mir_input.mir_get_type_name(resolved_dest))
                if dest_name_sym != 0:
                    if dest_name_sym == self.sym_option and self.mir_input.mir_get_type_d2(resolved_dest) > 0:
                        let te_start = self.mir_input.mir_get_type_d1(resolved_dest)
                        let payload_tid = self.mir_input.mir_get_type_extra(te_start)
                        if payload_tid > 0:
                            elem_ty = self.mir_sema_type_to_llvm(payload_tid)
            if elem_ty == 0:
                elem_ty = self.mir_sema_type_to_llvm(resolved_dest)
        // Fall back to receiver's generic type argument.
        if elem_ty == 0:
            elem_ty = self.mir_vec_elem_type(body, recv_op)
        if elem_ty == 0:
            elem_ty = i32_ty
        let iter_fields: Vec[i64] = Vec.new()
        iter_fields.push(i64_ty)
        iter_fields.push(i64_ty)
        iter_fields.push(i64_ty)
        let iter_struct_ty = wl_struct_type(self.context, vec_data_i64(&iter_fields), 3, 0)
        let data_ptr_ptr = wl_build_struct_gep(self.builder, iter_struct_ty, iter_ptr, 0)
        let data_ptr = wl_build_load(self.builder, i64_ty, data_ptr_ptr)
        let len_ptr = wl_build_struct_gep(self.builder, iter_struct_ty, iter_ptr, 1)
        let len = wl_build_load(self.builder, i64_ty, len_ptr)
        let idx_ptr = wl_build_struct_gep(self.builder, iter_struct_ty, iter_ptr, 2)
        let idx = wl_build_load(self.builder, i64_ty, idx_ptr)
        let cond = wl_build_icmp(self.builder, wl_int_slt(), idx, len)
        let opt_type = self.get_or_create_option_type(0, elem_ty)
        let some_bb = wl_append_bb(self.context, self.current_function, "veciter.some")
        let none_bb = wl_append_bb(self.context, self.current_function, "veciter.none")
        let merge_bb = wl_append_bb(self.context, self.current_function, "veciter.merge")
        wl_build_cond_br(self.builder, cond, some_bb, none_bb)
        wl_position_at_end(self.builder, some_bb)
        let typed_ptr = wl_build_int_to_ptr(self.builder, data_ptr, ptr_ty)
        let gep_indices: Vec[i64] = Vec.new()
        gep_indices.push(idx)
        let elem_ptr = wl_build_gep(self.builder, elem_ty, typed_ptr, vec_data_i64(&gep_indices), 1)
        let val = wl_build_load(self.builder, elem_ty, elem_ptr)
        let next_idx = wl_build_add(self.builder, idx, wl_const_int(i64_ty, 1, 0))
        wl_build_store(self.builder, next_idx, idx_ptr)
        let some_val = self.build_option_some(val, opt_type)
        wl_build_br(self.builder, merge_bb)
        let some_bb_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, none_bb)
        let none_val = self.build_option_none(opt_type)
        wl_build_br(self.builder, merge_bb)
        let none_bb_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, merge_bb)
        let phi = wl_build_phi(self.builder, opt_type)
        let phi_vals: Vec[i64] = Vec.new()
        let phi_bbs: Vec[i64] = Vec.new()
        phi_vals.push(some_val)
        phi_vals.push(none_val)
        phi_bbs.push(some_bb_end)
        phi_bbs.push(none_bb_end)
        wl_add_incoming(phi, vec_data_i64(&phi_vals), vec_data_i64(&phi_bbs), 2)
        result = phi

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_ITER:
        // Vec.iter() — create VecIter[T] from Vec
        // VecIter = { data_ptr: i64, len: i64, idx: i64 }
        let recv = self.mir_intrinsic_recv_vec_value(body, args_id)
        let iter_fields: Vec[i64] = Vec.new()
        iter_fields.push(i64_ty)
        iter_fields.push(i64_ty)
        iter_fields.push(i64_ty)
        let iter_struct_ty = wl_struct_type(self.context, vec_data_i64(&iter_fields), 3, 0)
        let iter_alloca = wl_build_alloca(self.builder, iter_struct_ty)
        let data_raw = wl_build_extract_value(self.builder, recv, 0)
        let data_i64 = wl_build_ptr_to_int(self.builder, data_raw, i64_ty)
        let f0 = wl_build_struct_gep(self.builder, iter_struct_ty, iter_alloca, 0)
        wl_build_store(self.builder, data_i64, f0)
        let vlen = wl_build_extract_value(self.builder, recv, 1)
        let f1 = wl_build_struct_gep(self.builder, iter_struct_ty, iter_alloca, 1)
        wl_build_store(self.builder, vlen, f1)
        let f2 = wl_build_struct_gep(self.builder, iter_struct_ty, iter_alloca, 2)
        wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), f2)
        result = wl_build_load(self.builder, iter_struct_ty, iter_alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_ITER_REF:
        // Vec.iter_ref() — create VecIterRef[T] from Vec (same layout as VecIter)
        let iref_recv = self.mir_intrinsic_recv_vec_value(body, args_id)
        let iref_fields: Vec[i64] = Vec.new()
        iref_fields.push(i64_ty)
        iref_fields.push(i64_ty)
        iref_fields.push(i64_ty)
        let iref_struct_ty = wl_struct_type(self.context, vec_data_i64(&iref_fields), 3, 0)
        let iref_alloca = wl_build_alloca(self.builder, iref_struct_ty)
        let iref_data_raw = wl_build_extract_value(self.builder, iref_recv, 0)
        let iref_data_i64 = wl_build_ptr_to_int(self.builder, iref_data_raw, i64_ty)
        let iref_f0 = wl_build_struct_gep(self.builder, iref_struct_ty, iref_alloca, 0)
        wl_build_store(self.builder, iref_data_i64, iref_f0)
        let iref_vlen = wl_build_extract_value(self.builder, iref_recv, 1)
        let iref_f1 = wl_build_struct_gep(self.builder, iref_struct_ty, iref_alloca, 1)
        wl_build_store(self.builder, iref_vlen, iref_f1)
        let iref_f2 = wl_build_struct_gep(self.builder, iref_struct_ty, iref_alloca, 2)
        wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), iref_f2)
        result = wl_build_load(self.builder, iref_struct_ty, iref_alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VECITERREF_NEXT:
        // VecIterRef[T].next() — advance iterator, return Option[&T] (nullable pointer)
        let irn_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let irn_fields: Vec[i64] = Vec.new()
        irn_fields.push(i64_ty)
        irn_fields.push(i64_ty)
        irn_fields.push(i64_ty)
        let irn_struct_ty = wl_struct_type(self.context, vec_data_i64(&irn_fields), 3, 0)
        let irn_dp_ptr = wl_build_struct_gep(self.builder, irn_struct_ty, irn_ptr, 0)
        let irn_dp = wl_build_load(self.builder, i64_ty, irn_dp_ptr)
        let irn_len_ptr = wl_build_struct_gep(self.builder, irn_struct_ty, irn_ptr, 1)
        let irn_len = wl_build_load(self.builder, i64_ty, irn_len_ptr)
        let irn_idx_ptr = wl_build_struct_gep(self.builder, irn_struct_ty, irn_ptr, 2)
        let irn_idx = wl_build_load(self.builder, i64_ty, irn_idx_ptr)
        let irn_cond = wl_build_icmp(self.builder, wl_int_slt(), irn_idx, irn_len)
        let irn_some_bb = wl_append_bb(self.context, self.current_function, "iterref.some")
        let irn_none_bb = wl_append_bb(self.context, self.current_function, "iterref.none")
        let irn_merge_bb = wl_append_bb(self.context, self.current_function, "iterref.merge")
        wl_build_cond_br(self.builder, irn_cond, irn_some_bb, irn_none_bb)
        wl_position_at_end(self.builder, irn_some_bb)
        let irn_recv_op = body.call_arg_operands.get(arg_start as i64)
        var irn_elem_ty = self.mir_vec_elem_type(body, irn_recv_op)
        if irn_elem_ty == 0:
            irn_elem_ty = i32_ty
        let irn_typed_ptr = wl_build_int_to_ptr(self.builder, irn_dp, ptr_ty)
        let irn_gep: Vec[i64] = Vec.new()
        irn_gep.push(irn_idx)
        let irn_elem_ptr = wl_build_gep(self.builder, irn_elem_ty, irn_typed_ptr, vec_data_i64(&irn_gep), 1)
        let irn_next_idx = wl_build_add(self.builder, irn_idx, wl_const_int(i64_ty, 1, 0))
        wl_build_store(self.builder, irn_next_idx, irn_idx_ptr)
        wl_build_br(self.builder, irn_merge_bb)
        let irn_some_bb_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, irn_none_bb)
        let irn_null = wl_const_null(ptr_ty)
        wl_build_br(self.builder, irn_merge_bb)
        let irn_none_bb_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, irn_merge_bb)
        let irn_phi = wl_build_phi(self.builder, ptr_ty)
        let irn_phi_vals: Vec[i64] = Vec.new()
        let irn_phi_bbs: Vec[i64] = Vec.new()
        irn_phi_vals.push(irn_elem_ptr)
        irn_phi_vals.push(irn_null)
        irn_phi_bbs.push(irn_some_bb_end)
        irn_phi_bbs.push(irn_none_bb_end)
        wl_add_incoming(irn_phi, vec_data_i64(&irn_phi_vals), vec_data_i64(&irn_phi_bbs), 2)
        result = irn_phi

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_SLOT:
        // Vec.slot(index) — create VecSlot[T] from Vec
        // VecSlot = { data_ptr: i64, index: i64 }
        let vs_recv = self.mir_intrinsic_recv_vec_value(body, args_id)
        let vs_index = self.mir_intrinsic_arg(body, args_id, 1)
        let slot_fields: Vec[i64] = Vec.new()
        slot_fields.push(i64_ty)
        slot_fields.push(i64_ty)
        let slot_struct_ty = wl_struct_type(self.context, vec_data_i64(&slot_fields), 2, 0)
        let slot_alloca = wl_build_alloca(self.builder, slot_struct_ty)
        let vs_data_raw = wl_build_extract_value(self.builder, vs_recv, 0)
        let vs_data_i64 = wl_build_ptr_to_int(self.builder, vs_data_raw, i64_ty)
        let sf0 = wl_build_struct_gep(self.builder, slot_struct_ty, slot_alloca, 0)
        wl_build_store(self.builder, vs_data_i64, sf0)
        let sf1 = wl_build_struct_gep(self.builder, slot_struct_ty, slot_alloca, 1)
        wl_build_store(self.builder, vs_index, sf1)
        result = wl_build_load(self.builder, slot_struct_ty, slot_alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_GET_DISJOINT:
        // Vec.get_disjoint(i, j) — return (VecSlot[T], VecSlot[T])
        // Panics if indices out of bounds or equal
        let gd_recv = self.mir_intrinsic_recv_vec_value(body, args_id)
        let gd_i = self.mir_intrinsic_arg(body, args_id, 1)
        let gd_j = self.mir_intrinsic_arg(body, args_id, 2)
        let gd_i64 = self.coerce_int(gd_i, i64_ty)
        let gd_j64 = self.coerce_int(gd_j, i64_ty)
        let gd_len = wl_build_extract_value(self.builder, gd_recv, 1)
        let gd_oob_i = wl_build_icmp(self.builder, wl_int_sge(), gd_i64, gd_len)
        let gd_oob_j = wl_build_icmp(self.builder, wl_int_sge(), gd_j64, gd_len)
        let gd_oob = wl_build_or(self.builder, gd_oob_i, gd_oob_j)
        let gd_neg_i = wl_build_icmp(self.builder, wl_int_slt(), gd_i64, wl_const_int(i64_ty, 0, 0))
        let gd_neg_j = wl_build_icmp(self.builder, wl_int_slt(), gd_j64, wl_const_int(i64_ty, 0, 0))
        let gd_neg = wl_build_or(self.builder, gd_neg_i, gd_neg_j)
        let gd_bad_bounds = wl_build_or(self.builder, gd_oob, gd_neg)
        let gd_same = wl_build_icmp(self.builder, wl_int_eq(), gd_i64, gd_j64)
        let gd_fail = wl_build_or(self.builder, gd_bad_bounds, gd_same)
        let gd_panic_bb = wl_append_bb(self.context, self.current_function, "gd.panic")
        let gd_ok_bb = wl_append_bb(self.context, self.current_function, "gd.ok")
        wl_build_cond_br(self.builder, gd_fail, gd_panic_bb, gd_ok_bb)
        wl_position_at_end(self.builder, gd_panic_bb)
        let _ = wl_build_unreachable(self.builder)
        wl_position_at_end(self.builder, gd_ok_bb)
        let gd_data_raw = wl_build_extract_value(self.builder, gd_recv, 0)
        let gd_data_i64 = wl_build_ptr_to_int(self.builder, gd_data_raw, i64_ty)
        let gd_slot_fields: Vec[i64] = Vec.new()
        gd_slot_fields.push(i64_ty)
        gd_slot_fields.push(i64_ty)
        let gd_slot_ty = wl_struct_type(self.context, vec_data_i64(&gd_slot_fields), 2, 0)
        let gd_sa = wl_build_alloca(self.builder, gd_slot_ty)
        let gd_sa0 = wl_build_struct_gep(self.builder, gd_slot_ty, gd_sa, 0)
        wl_build_store(self.builder, gd_data_i64, gd_sa0)
        let gd_sa1 = wl_build_struct_gep(self.builder, gd_slot_ty, gd_sa, 1)
        wl_build_store(self.builder, gd_i64, gd_sa1)
        let gd_slot_a = wl_build_load(self.builder, gd_slot_ty, gd_sa)
        let gd_sb = wl_build_alloca(self.builder, gd_slot_ty)
        let gd_sb0 = wl_build_struct_gep(self.builder, gd_slot_ty, gd_sb, 0)
        wl_build_store(self.builder, gd_data_i64, gd_sb0)
        let gd_sb1 = wl_build_struct_gep(self.builder, gd_slot_ty, gd_sb, 1)
        wl_build_store(self.builder, gd_j64, gd_sb1)
        let gd_slot_b = wl_build_load(self.builder, gd_slot_ty, gd_sb)
        let gd_tup_fields: Vec[i64] = Vec.new()
        gd_tup_fields.push(gd_slot_ty)
        gd_tup_fields.push(gd_slot_ty)
        let gd_tup_ty = wl_struct_type(self.context, vec_data_i64(&gd_tup_fields), 2, 0)
        let gd_tup = wl_build_alloca(self.builder, gd_tup_ty)
        let gd_tf0 = wl_build_struct_gep(self.builder, gd_tup_ty, gd_tup, 0)
        wl_build_store(self.builder, gd_slot_a, gd_tf0)
        let gd_tf1 = wl_build_struct_gep(self.builder, gd_tup_ty, gd_tup, 1)
        wl_build_store(self.builder, gd_slot_b, gd_tf1)
        result = wl_build_load(self.builder, gd_tup_ty, gd_tup)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_RANGE:
        // Vec.range(start..end) — create VecRange[T] = { data_ptr: i64, offset: i64, len: i64 }
        let vr_recv = self.mir_intrinsic_recv_vec_value(body, args_id)
        let vr_range = self.mir_intrinsic_arg(body, args_id, 1)
        let vr_range_ty = wl_type_of(vr_range)
        let vr_range_alloca = wl_build_alloca(self.builder, vr_range_ty)
        wl_build_store(self.builder, vr_range, vr_range_alloca)
        let vr_elem_ty = wl_struct_get_type_at(vr_range_ty, 0)
        let vr_start_ptr = wl_build_struct_gep(self.builder, vr_range_ty, vr_range_alloca, 0)
        let vr_start_raw = wl_build_load(self.builder, vr_elem_ty, vr_start_ptr)
        let vr_start = self.coerce_int(vr_start_raw, i64_ty)
        let vr_end_ptr = wl_build_struct_gep(self.builder, vr_range_ty, vr_range_alloca, 1)
        let vr_end_raw = wl_build_load(self.builder, vr_elem_ty, vr_end_ptr)
        let vr_end = self.coerce_int(vr_end_raw, i64_ty)
        let vr_vec_len = wl_build_extract_value(self.builder, vr_recv, 1)
        let vr_bad_start = wl_build_icmp(self.builder, wl_int_slt(), vr_start, wl_const_int(i64_ty, 0, 0))
        let vr_bad_end = wl_build_icmp(self.builder, wl_int_sgt(), vr_end, vr_vec_len)
        let vr_bad_order = wl_build_icmp(self.builder, wl_int_sgt(), vr_start, vr_end)
        let vr_bad1 = wl_build_or(self.builder, vr_bad_start, vr_bad_end)
        let vr_bad2 = wl_build_or(self.builder, vr_bad1, vr_bad_order)
        let vr_panic_bb = wl_append_bb(self.context, self.current_function, "vr.panic")
        let vr_ok_bb = wl_append_bb(self.context, self.current_function, "vr.ok")
        wl_build_cond_br(self.builder, vr_bad2, vr_panic_bb, vr_ok_bb)
        wl_position_at_end(self.builder, vr_panic_bb)
        let _ = wl_build_unreachable(self.builder)
        wl_position_at_end(self.builder, vr_ok_bb)
        let vr_range_len = wl_build_sub(self.builder, vr_end, vr_start)
        let vr_data_raw = wl_build_extract_value(self.builder, vr_recv, 0)
        let vr_data_i64 = wl_build_ptr_to_int(self.builder, vr_data_raw, i64_ty)
        let vr_fields: Vec[i64] = Vec.new()
        vr_fields.push(i64_ty)
        vr_fields.push(i64_ty)
        vr_fields.push(i64_ty)
        let vr_struct_ty = wl_struct_type(self.context, vec_data_i64(&vr_fields), 3, 0)
        let vr_alloca = wl_build_alloca(self.builder, vr_struct_ty)
        let vr_f0 = wl_build_struct_gep(self.builder, vr_struct_ty, vr_alloca, 0)
        wl_build_store(self.builder, vr_data_i64, vr_f0)
        let vr_f1 = wl_build_struct_gep(self.builder, vr_struct_ty, vr_alloca, 1)
        wl_build_store(self.builder, vr_start, vr_f1)
        let vr_f2 = wl_build_struct_gep(self.builder, vr_struct_ty, vr_alloca, 2)
        wl_build_store(self.builder, vr_range_len, vr_f2)
        result = wl_build_load(self.builder, vr_struct_ty, vr_alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VECRANGE_GET:
        // VecRange[T].get(i) — load element at data_ptr[offset + i]
        let vrg_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let vrg_idx = self.mir_intrinsic_arg(body, args_id, 1)
        let vrg_idx64 = self.coerce_int(vrg_idx, i64_ty)
        let vrg_dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        var vrg_elem_ty: i64 = 0
        if vrg_dest_sema > 0:
            vrg_elem_ty = self.mir_sema_type_to_llvm(self.mir_input.mir_resolve_alias(vrg_dest_sema))
        if vrg_elem_ty == 0:
            vrg_elem_ty = i32_ty
        let vrg_fields: Vec[i64] = Vec.new()
        vrg_fields.push(i64_ty)
        vrg_fields.push(i64_ty)
        vrg_fields.push(i64_ty)
        let vrg_struct_ty = wl_struct_type(self.context, vec_data_i64(&vrg_fields), 3, 0)
        let vrg_dp = wl_build_struct_gep(self.builder, vrg_struct_ty, vrg_ptr, 0)
        let vrg_data = wl_build_load(self.builder, i64_ty, vrg_dp)
        let vrg_off_ptr = wl_build_struct_gep(self.builder, vrg_struct_ty, vrg_ptr, 1)
        let vrg_off = wl_build_load(self.builder, i64_ty, vrg_off_ptr)
        let vrg_len_ptr = wl_build_struct_gep(self.builder, vrg_struct_ty, vrg_ptr, 2)
        let vrg_len = wl_build_load(self.builder, i64_ty, vrg_len_ptr)
        let vrg_oob = wl_build_icmp(self.builder, wl_int_sge(), vrg_idx64, vrg_len)
        let vrg_neg = wl_build_icmp(self.builder, wl_int_slt(), vrg_idx64, wl_const_int(i64_ty, 0, 0))
        let vrg_bad = wl_build_or(self.builder, vrg_oob, vrg_neg)
        let vrg_panic_bb = wl_append_bb(self.context, self.current_function, "vrg.panic")
        let vrg_ok_bb = wl_append_bb(self.context, self.current_function, "vrg.ok")
        wl_build_cond_br(self.builder, vrg_bad, vrg_panic_bb, vrg_ok_bb)
        wl_position_at_end(self.builder, vrg_panic_bb)
        let _ = wl_build_unreachable(self.builder)
        wl_position_at_end(self.builder, vrg_ok_bb)
        let vrg_abs = wl_build_add(self.builder, vrg_off, vrg_idx64)
        let vrg_typed_ptr = wl_build_int_to_ptr(self.builder, vrg_data, ptr_ty)
        let vrg_gep: Vec[i64] = Vec.new()
        vrg_gep.push(vrg_abs)
        let vrg_elem_ptr = wl_build_gep(self.builder, vrg_elem_ty, vrg_typed_ptr, vec_data_i64(&vrg_gep), 1)
        result = wl_build_load(self.builder, vrg_elem_ty, vrg_elem_ptr)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VECRANGE_SET:
        // VecRange[T].set(i, value) — store value at data_ptr[offset + i]
        let vrs_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let vrs_idx = self.mir_intrinsic_arg(body, args_id, 1)
        let vrs_val = self.mir_intrinsic_arg(body, args_id, 2)
        let vrs_idx64 = self.coerce_int(vrs_idx, i64_ty)
        let vrs_elem_ty = wl_type_of(vrs_val)
        let vrs_fields: Vec[i64] = Vec.new()
        vrs_fields.push(i64_ty)
        vrs_fields.push(i64_ty)
        vrs_fields.push(i64_ty)
        let vrs_struct_ty = wl_struct_type(self.context, vec_data_i64(&vrs_fields), 3, 0)
        let vrs_dp = wl_build_struct_gep(self.builder, vrs_struct_ty, vrs_ptr, 0)
        let vrs_data = wl_build_load(self.builder, i64_ty, vrs_dp)
        let vrs_off_ptr = wl_build_struct_gep(self.builder, vrs_struct_ty, vrs_ptr, 1)
        let vrs_off = wl_build_load(self.builder, i64_ty, vrs_off_ptr)
        let vrs_len_ptr = wl_build_struct_gep(self.builder, vrs_struct_ty, vrs_ptr, 2)
        let vrs_len = wl_build_load(self.builder, i64_ty, vrs_len_ptr)
        let vrs_oob = wl_build_icmp(self.builder, wl_int_sge(), vrs_idx64, vrs_len)
        let vrs_neg = wl_build_icmp(self.builder, wl_int_slt(), vrs_idx64, wl_const_int(i64_ty, 0, 0))
        let vrs_bad = wl_build_or(self.builder, vrs_oob, vrs_neg)
        let vrs_panic_bb = wl_append_bb(self.context, self.current_function, "vrs.panic")
        let vrs_ok_bb = wl_append_bb(self.context, self.current_function, "vrs.ok")
        wl_build_cond_br(self.builder, vrs_bad, vrs_panic_bb, vrs_ok_bb)
        wl_position_at_end(self.builder, vrs_panic_bb)
        let _ = wl_build_unreachable(self.builder)
        wl_position_at_end(self.builder, vrs_ok_bb)
        let vrs_abs = wl_build_add(self.builder, vrs_off, vrs_idx64)
        let vrs_typed_ptr = wl_build_int_to_ptr(self.builder, vrs_data, ptr_ty)
        let vrs_gep: Vec[i64] = Vec.new()
        vrs_gep.push(vrs_abs)
        let vrs_elem_ptr = wl_build_gep(self.builder, vrs_elem_ty, vrs_typed_ptr, vec_data_i64(&vrs_gep), 1)
        wl_build_store(self.builder, vrs_val, vrs_elem_ptr)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VECRANGE_LEN:
        // VecRange[T].len() — return len field (field 2 of {i64,i64,i64})
        let vrl_recv = self.mir_intrinsic_arg(body, args_id, 0)
        if wl_get_type_kind(wl_type_of(vrl_recv)) == wl_struct_type_kind():
            result = wl_build_extract_value(self.builder, vrl_recv, 2)
        else:
            let vrl_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
            let vrl_fields: Vec[i64] = Vec.new()
            vrl_fields.push(i64_ty)
            vrl_fields.push(i64_ty)
            vrl_fields.push(i64_ty)
            let vrl_struct_ty = wl_struct_type(self.context, vec_data_i64(&vrl_fields), 3, 0)
            let vrl_len_ptr = wl_build_struct_gep(self.builder, vrl_struct_ty, vrl_ptr, 2)
            result = wl_build_load(self.builder, i64_ty, vrl_len_ptr)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_ITER_PLACE:
        // Vec.iter_place() — create VecIterPlace[T] from Vec
        // VecIterPlace = { data_ptr: i64, len: i64, idx: i64 }
        let vip_recv = self.mir_intrinsic_recv_vec_value(body, args_id)
        let vip_fields: Vec[i64] = Vec.new()
        vip_fields.push(i64_ty)
        vip_fields.push(i64_ty)
        vip_fields.push(i64_ty)
        let vip_struct_ty = wl_struct_type(self.context, vec_data_i64(&vip_fields), 3, 0)
        let vip_alloca = wl_build_alloca(self.builder, vip_struct_ty)
        let vip_data_raw = wl_build_extract_value(self.builder, vip_recv, 0)
        let vip_data_i64 = wl_build_ptr_to_int(self.builder, vip_data_raw, i64_ty)
        let vip_f0 = wl_build_struct_gep(self.builder, vip_struct_ty, vip_alloca, 0)
        wl_build_store(self.builder, vip_data_i64, vip_f0)
        let vip_len = wl_build_extract_value(self.builder, vip_recv, 1)
        let vip_f1 = wl_build_struct_gep(self.builder, vip_struct_ty, vip_alloca, 1)
        wl_build_store(self.builder, vip_len, vip_f1)
        let vip_f2 = wl_build_struct_gep(self.builder, vip_struct_ty, vip_alloca, 2)
        wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), vip_f2)
        result = wl_build_load(self.builder, vip_struct_ty, vip_alloca)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VECITERPLACE_NEXT:
        // VecIterPlace[T].next() — advance iterator, return Option[VecSlot[T]]
        // VecIterPlace = { data_ptr: i64, len: i64, idx: i64 }
        // VecSlot = { data_ptr: i64, index: i64 }
        let ipn_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let ipn_fields: Vec[i64] = Vec.new()
        ipn_fields.push(i64_ty)
        ipn_fields.push(i64_ty)
        ipn_fields.push(i64_ty)
        let ipn_struct_ty = wl_struct_type(self.context, vec_data_i64(&ipn_fields), 3, 0)
        let ipn_dp_ptr = wl_build_struct_gep(self.builder, ipn_struct_ty, ipn_ptr, 0)
        let ipn_data = wl_build_load(self.builder, i64_ty, ipn_dp_ptr)
        let ipn_len_ptr = wl_build_struct_gep(self.builder, ipn_struct_ty, ipn_ptr, 1)
        let ipn_len = wl_build_load(self.builder, i64_ty, ipn_len_ptr)
        let ipn_idx_ptr = wl_build_struct_gep(self.builder, ipn_struct_ty, ipn_ptr, 2)
        let ipn_idx = wl_build_load(self.builder, i64_ty, ipn_idx_ptr)
        let ipn_cond = wl_build_icmp(self.builder, wl_int_slt(), ipn_idx, ipn_len)
        let ipn_slot_fields: Vec[i64] = Vec.new()
        ipn_slot_fields.push(i64_ty)
        ipn_slot_fields.push(i64_ty)
        let ipn_slot_ty = wl_struct_type(self.context, vec_data_i64(&ipn_slot_fields), 2, 0)
        let ipn_opt_type = self.get_or_create_option_type(0, ipn_slot_ty)
        let ipn_some_bb = wl_append_bb(self.context, self.current_function, "iterplace.some")
        let ipn_none_bb = wl_append_bb(self.context, self.current_function, "iterplace.none")
        let ipn_merge_bb = wl_append_bb(self.context, self.current_function, "iterplace.merge")
        wl_build_cond_br(self.builder, ipn_cond, ipn_some_bb, ipn_none_bb)
        wl_position_at_end(self.builder, ipn_some_bb)
        let ipn_slot_alloca = wl_build_alloca(self.builder, ipn_slot_ty)
        let ipn_s0 = wl_build_struct_gep(self.builder, ipn_slot_ty, ipn_slot_alloca, 0)
        wl_build_store(self.builder, ipn_data, ipn_s0)
        let ipn_s1 = wl_build_struct_gep(self.builder, ipn_slot_ty, ipn_slot_alloca, 1)
        wl_build_store(self.builder, ipn_idx, ipn_s1)
        let ipn_slot_val = wl_build_load(self.builder, ipn_slot_ty, ipn_slot_alloca)
        let ipn_next_idx = wl_build_add(self.builder, ipn_idx, wl_const_int(i64_ty, 1, 0))
        wl_build_store(self.builder, ipn_next_idx, ipn_idx_ptr)
        let ipn_some_val = self.build_option_some(ipn_slot_val, ipn_opt_type)
        wl_build_br(self.builder, ipn_merge_bb)
        let ipn_some_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, ipn_none_bb)
        let ipn_none_val = self.build_option_none(ipn_opt_type)
        wl_build_br(self.builder, ipn_merge_bb)
        let ipn_none_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, ipn_merge_bb)
        let ipn_phi = wl_build_phi(self.builder, ipn_opt_type)
        let ipn_phi_vals: Vec[i64] = Vec.new()
        let ipn_phi_bbs: Vec[i64] = Vec.new()
        ipn_phi_vals.push(ipn_some_val)
        ipn_phi_vals.push(ipn_none_val)
        ipn_phi_bbs.push(ipn_some_end)
        ipn_phi_bbs.push(ipn_none_end)
        wl_add_incoming(ipn_phi, vec_data_i64(&ipn_phi_vals), vec_data_i64(&ipn_phi_bbs), 2)
        result = ipn_phi

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VECSLOT_GET:
        // VecSlot[T].get() — load element from data_ptr[index]
        // VecSlot = { data_ptr: i64, index: i64 }
        let sg_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let sg_dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        var sg_elem_ty: i64 = 0
        if sg_dest_sema > 0:
            sg_elem_ty = self.mir_sema_type_to_llvm(self.mir_input.mir_resolve_alias(sg_dest_sema))
        if sg_elem_ty == 0:
            sg_elem_ty = i32_ty
        let sg_fields: Vec[i64] = Vec.new()
        sg_fields.push(i64_ty)
        sg_fields.push(i64_ty)
        let sg_struct_ty = wl_struct_type(self.context, vec_data_i64(&sg_fields), 2, 0)
        let sg_dp = wl_build_struct_gep(self.builder, sg_struct_ty, sg_ptr, 0)
        let sg_data = wl_build_load(self.builder, i64_ty, sg_dp)
        let sg_ip = wl_build_struct_gep(self.builder, sg_struct_ty, sg_ptr, 1)
        let sg_idx = wl_build_load(self.builder, i64_ty, sg_ip)
        let sg_typed_ptr = wl_build_int_to_ptr(self.builder, sg_data, ptr_ty)
        let sg_gep_indices: Vec[i64] = Vec.new()
        sg_gep_indices.push(sg_idx)
        let sg_elem_ptr = wl_build_gep(self.builder, sg_elem_ty, sg_typed_ptr, vec_data_i64(&sg_gep_indices), 1)
        result = wl_build_load(self.builder, sg_elem_ty, sg_elem_ptr)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VECSLOT_SET:
        // VecSlot[T].set(value) — store value at data_ptr[index]
        let ss_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let ss_val = self.mir_intrinsic_arg(body, args_id, 1)
        let ss_elem_ty = wl_type_of(ss_val)
        let ss_fields: Vec[i64] = Vec.new()
        ss_fields.push(i64_ty)
        ss_fields.push(i64_ty)
        let ss_struct_ty = wl_struct_type(self.context, vec_data_i64(&ss_fields), 2, 0)
        let ss_dp = wl_build_struct_gep(self.builder, ss_struct_ty, ss_ptr, 0)
        let ss_data = wl_build_load(self.builder, i64_ty, ss_dp)
        let ss_ip = wl_build_struct_gep(self.builder, ss_struct_ty, ss_ptr, 1)
        let ss_idx = wl_build_load(self.builder, i64_ty, ss_ip)
        let ss_typed_ptr = wl_build_int_to_ptr(self.builder, ss_data, ptr_ty)
        let ss_gep_indices: Vec[i64] = Vec.new()
        ss_gep_indices.push(ss_idx)
        let ss_elem_ptr = wl_build_gep(self.builder, ss_elem_ty, ss_typed_ptr, vec_data_i64(&ss_gep_indices), 1)
        wl_build_store(self.builder, ss_val, ss_elem_ptr)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_LOAD:
        // Atomic[T].load(order) — atomic load from field 0 (val)
        let al_recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let al_order_raw = self.mir_intrinsic_arg(body, args_id, 1)
        // Get the element type from the Atomic struct (field 0)
        let al_recv_ty = wl_get_allocated_type(al_recv_ptr)
        let al_elem_ty = wl_struct_get_type_at(al_recv_ty, 0)
        // GEP to field 0 (val)
        let al_val_ptr = wl_build_struct_gep(self.builder, al_recv_ty, al_recv_ptr, 0)
        // Extract ordering constant (default to seq_cst = 4)
        let al_order = if self.is_const_int_value(al_order_raw): wl_const_int_sext_val(al_order_raw) as i32 else: AtomicOrdering.SEQ_CST
        result = wl_build_atomic_load(self.builder, al_elem_ty, al_val_ptr, al_order)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_STORE:
        // Atomic[T].store(val, order) — atomic store to field 0
        let as_recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let as_val = self.mir_intrinsic_arg(body, args_id, 1)
        let as_order_raw = self.mir_intrinsic_arg(body, args_id, 2)
        let as_recv_ty = wl_get_allocated_type(as_recv_ptr)
        let as_val_ptr = wl_build_struct_gep(self.builder, as_recv_ty, as_recv_ptr, 0)
        let as_order = if self.is_const_int_value(as_order_raw): wl_const_int_sext_val(as_order_raw) as i32 else: AtomicOrdering.SEQ_CST
        wl_build_atomic_store(self.builder, as_val, as_val_ptr, as_order)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_SWAP or intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_ADD or intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_SUB or intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_AND or intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_OR or intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_XOR or intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_MIN or intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_MAX:
        // Atomic[T].fetch_*(val, order) — atomicrmw on field 0
        let ar_recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let ar_val = self.mir_intrinsic_arg(body, args_id, 1)
        let ar_order_raw = self.mir_intrinsic_arg(body, args_id, 2)
        let ar_recv_ty = wl_get_allocated_type(ar_recv_ptr)
        let ar_val_ptr = wl_build_struct_gep(self.builder, ar_recv_ty, ar_recv_ptr, 0)
        let ar_order = if self.is_const_int_value(ar_order_raw): wl_const_int_sext_val(ar_order_raw) as i32 else: AtomicOrdering.SEQ_CST
        let ar_rmw_op = if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_SWAP: AtomicRmwOp.XCHG
            else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_ADD: AtomicRmwOp.ADD
            else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_SUB: AtomicRmwOp.SUB
            else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_AND: AtomicRmwOp.AND
            else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_OR: AtomicRmwOp.OR
            else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_XOR: AtomicRmwOp.XOR
            else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_MIN: AtomicRmwOp.MIN
            else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_MAX: AtomicRmwOp.MAX
            else: AtomicRmwOp.XCHG
        result = wl_build_atomic_rmw(self.builder, ar_rmw_op, ar_val_ptr, ar_val, ar_order)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_CAS or intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_CAS_WEAK:
        // compare_exchange(expected, desired, success_order, failure_order)
        let cas_recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let cas_expected = self.mir_intrinsic_arg(body, args_id, 1)
        let cas_desired = self.mir_intrinsic_arg(body, args_id, 2)
        let cas_success_raw = self.mir_intrinsic_arg(body, args_id, 3)
        let cas_failure_raw = self.mir_intrinsic_arg(body, args_id, 4)
        let cas_recv_ty = wl_get_allocated_type(cas_recv_ptr)
        let cas_val_ptr = wl_build_struct_gep(self.builder, cas_recv_ty, cas_recv_ptr, 0)
        let cas_success_order = if self.is_const_int_value(cas_success_raw): wl_const_int_sext_val(cas_success_raw) as i32 else: AtomicOrdering.SEQ_CST
        let cas_failure_order = if self.is_const_int_value(cas_failure_raw): wl_const_int_sext_val(cas_failure_raw) as i32 else: AtomicOrdering.SEQ_CST
        let cas_is_weak = if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_CAS_WEAK: 1 else: 0
        let cas_result = wl_build_cmpxchg(self.builder, cas_val_ptr, cas_expected, cas_desired, cas_success_order, cas_failure_order, cas_is_weak)
        // Extract old value (index 0) from {T, i1} result
        result = wl_extract_value(self.builder, cas_result, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ATOMIC_FENCE:
        let fence_order_raw = self.mir_intrinsic_arg(body, args_id, 0)
        let fence_order = if self.is_const_int_value(fence_order_raw): wl_const_int_sext_val(fence_order_raw) as i32 else: AtomicOrdering.SEQ_CST
        wl_build_fence(self.builder, fence_order)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ASM:
        // Inline assembly: read template, constraints, and operands from AST node
        let asm_node = body.call_ast_node(args_id)
        if asm_node != 0:
            let asm_tmpl_sym = self.pool.get_data0(asm_node)
            let asm_constr_sym = self.pool.get_data1(asm_node)
            let asm_packed_d2 = self.pool.get_data2(asm_node)
            let asm_flags = asm_packed_d2 & 0xFF
            let asm_extra_start = asm_packed_d2 >> 8
            let asm_tmpl = self.intern.resolve(asm_tmpl_sym)
            let asm_constr = self.intern.resolve(asm_constr_sym)
            let asm_is_volatile = (asm_flags & 1) != 0
            let asm_has_output = (asm_flags & 2) != 0
            // Determine return type and collect input values
            var asm_ret_ty = wl_void_type(self.context)
            let asm_input_vals: Vec[i64] = Vec.new()
            let asm_param_tys: Vec[i64] = Vec.new()
            if asm_extra_start > 0:
                let asm_out_type_node = self.pool.get_extra(asm_extra_start)
                let asm_input_count = self.pool.get_extra(asm_extra_start + 1)
                if asm_has_output and asm_out_type_node != 0:
                    asm_ret_ty = self.resolve_type(asm_out_type_node)
                    if asm_ret_ty == 0:
                        asm_ret_ty = wl_i64_type(self.context)
                // Collect input values from MIR args
                for asm_ii in 0..asm_input_count:
                    let asm_in_val = self.mir_intrinsic_arg(body, args_id, asm_ii)
                    asm_input_vals.push(asm_in_val)
                    asm_param_tys.push(wl_type_of(asm_in_val))
                // Read-write constraint ("+r"): infer return type from the
                // input value type when no explicit output type was given.
                if asm_has_output and asm_out_type_node == 0 and asm_input_vals.len() > 0:
                    asm_ret_ty = wl_type_of(asm_input_vals.get(0))
            let asm_fn_ty = wl_function_type(asm_ret_ty, vec_data_i64(&asm_param_tys), asm_param_tys.len() as i32, 0)
            let asm_val = wl_get_inline_asm(asm_fn_ty, asm_tmpl, asm_constr, if asm_is_volatile: 1 else: 0, 0)
            let asm_call_result = wl_build_call(self.builder, asm_fn_ty, asm_val, vec_data_i64(&asm_input_vals), asm_input_vals.len() as i32)
            if asm_has_output:
                result = asm_call_result
        // Branch to next bb
        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
            wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
        return true

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MULTI_INDEX:
        let mi_node = body.call_ast_node(args_id)
        if mi_node != 0:
            let base_val = self.mir_intrinsic_arg(body, args_id, 0)
            let mi_specs_start = self.pool.get_data1(mi_node)
            let mi_specs_count = self.pool.get_data2(mi_node)
            // Build IndexSpec LLVM struct type: {i32, i64, i64, i64, i1, i1, i1}
            let mi_ctx = self.context
            let mi_spec_fields: Vec[i64] = Vec.new()
            mi_spec_fields.push(wl_i32_type(mi_ctx))   // kind
            mi_spec_fields.push(wl_i64_type(mi_ctx))   // start
            mi_spec_fields.push(wl_i64_type(mi_ctx))   // stop
            mi_spec_fields.push(wl_i64_type(mi_ctx))   // step
            mi_spec_fields.push(wl_i1_type(mi_ctx))    // has_start
            mi_spec_fields.push(wl_i1_type(mi_ctx))    // has_stop
            mi_spec_fields.push(wl_i1_type(mi_ctx))    // has_step
            let mi_spec_ty = wl_struct_type(mi_ctx, vec_data_i64(&mi_spec_fields), 7, 0)
            // Allocate IndexSpec[N] on stack
            let mi_arr_ty = wl_array_type(mi_spec_ty, mi_specs_count as i64)
            let mi_arr_ptr = self.create_entry_alloca(mi_arr_ty)
            // Populate each spec from MIR args (base at arg 0, specs at 1+si*3)
            for mi_si in 0..mi_specs_count:
                let mi_spec_node = self.pool.get_extra(mi_specs_start + mi_si)
                let mi_d2 = self.pool.get_data2(mi_spec_node)
                let mi_kind = mi_d2 / INDEX_KIND_SHIFT
                let mi_step_node = mi_d2 - mi_kind * INDEX_KIND_SHIFT
                let mi_d0 = self.pool.get_data0(mi_spec_node)
                let mi_d1 = self.pool.get_data1(mi_spec_node)
                // GEP to array element
                let mi_elem_ptr = wl_build_struct_gep(self.builder, mi_arr_ty, mi_arr_ptr, mi_si)
                // Store kind
                wl_build_store(self.builder, wl_const_int(wl_i32_type(mi_ctx), mi_kind as i64, 0), wl_build_struct_gep(self.builder, mi_spec_ty, mi_elem_ptr, 0))
                // Store start/stop/step from MIR args
                let mi_arg_base = 1 + mi_si * 3
                wl_build_store(self.builder, self.mir_intrinsic_arg(body, args_id, mi_arg_base), wl_build_struct_gep(self.builder, mi_spec_ty, mi_elem_ptr, 1))
                wl_build_store(self.builder, self.mir_intrinsic_arg(body, args_id, mi_arg_base + 1), wl_build_struct_gep(self.builder, mi_spec_ty, mi_elem_ptr, 2))
                wl_build_store(self.builder, self.mir_intrinsic_arg(body, args_id, mi_arg_base + 2), wl_build_struct_gep(self.builder, mi_spec_ty, mi_elem_ptr, 3))
                // Store has_start/has_stop/has_step booleans
                wl_build_store(self.builder, wl_const_int(wl_i1_type(mi_ctx), if mi_d0 != 0: 1 else: 0, 0), wl_build_struct_gep(self.builder, mi_spec_ty, mi_elem_ptr, 4))
                wl_build_store(self.builder, wl_const_int(wl_i1_type(mi_ctx), if mi_d1 != 0: 1 else: 0, 0), wl_build_struct_gep(self.builder, mi_spec_ty, mi_elem_ptr, 5))
                wl_build_store(self.builder, wl_const_int(wl_i1_type(mi_ctx), if mi_step_node != 0: 1 else: 0, 0), wl_build_struct_gep(self.builder, mi_spec_ty, mi_elem_ptr, 6))
            // Look up multi_index method on base type and call it
            // For now: pass through base value (method call dispatch deferred
            // until a concrete MultiIndex impl is available to test against)
            result = base_val
        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
            wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
        return true

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MULTI_INDEX_SET:
        let mis_node = body.call_ast_node(args_id)
        if mis_node != 0:
            let mis_base = self.mir_intrinsic_arg(body, args_id, 0)
            let mis_value = self.mir_intrinsic_arg(body, args_id, 1)
            // IndexSpec construction same as MULTI_INDEX above.
            // Method call to multi_index_set deferred until impl available.
            result = mis_value
        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
            wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
        return true

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FIBER_AWAIT or intrinsic == MirIntrinsic.MIR_INTRINSIC_FIBER_CLEANUP_AWAIT:
        // Await: extract fiber_id and result_buf from Task struct,
        // call with_fiber_await(fiber_id), load result from buffer, free buffer.
        // Cancellation checks are at MIR level (IS_CANCELLED / WAS_CANCELLED_RETURN
        // intrinsics emitted by MirLower, with defers in the unwind BB).
        let task_op = self.mir_intrinsic_arg(body, args_id, 0)
        let task_ty = wl_type_of(task_op)
        // Find the MIR local for the Task to look up its result type
        var task_mir_local: i32 = -1
        let await_arg_start = body.call_arg_starts.get(args_id as i64)
        let await_op_id = body.call_arg_operands.get(await_arg_start as i64)
        if await_op_id >= 0 and await_op_id < body.operand_d0.len() as i32:
            let await_place_id = body.operand_d0.get(await_op_id as i64)
            if await_place_id >= 0 and await_place_id < body.place_locals.len() as i32:
                task_mir_local = body.place_locals.get(await_place_id as i64)
        // Task = { i32 fiber_id, i8* result_buf }
        let task_alloca = self.create_entry_alloca(task_ty)
        wl_build_store(self.builder, task_op, task_alloca)
        let fid_ptr = wl_build_struct_gep(self.builder, task_ty, task_alloca, 0)
        let fid = wl_build_load(self.builder, wl_i32_type(self.context), fid_ptr)
        let rbuf_ptr = wl_build_struct_gep(self.builder, task_ty, task_alloca, 1)
        let rbuf = wl_build_load(self.builder, wl_ptr_type(self.context), rbuf_ptr)
        // Call the appropriate runtime await helper.
        let await_fn_name = if intrinsic == MirIntrinsic.MIR_INTRINSIC_FIBER_CLEANUP_AWAIT: "with_fiber_cleanup_await" else: "with_fiber_await"
        var await_fn = wl_get_named_function(self.llmod, await_fn_name)
        if await_fn == 0:
            let ap: Vec[i64] = Vec.new()
            ap.push(wl_i32_type(self.context))
            let aft = wl_function_type(wl_void_type(self.context), vec_data_i64(&ap), 1, 0)
            await_fn = wl_add_function(self.llmod, await_fn_name, aft)
        let await_ft = wl_global_get_value_type(await_fn)
        let aa: Vec[i64] = Vec.new()
        aa.push(fid)
        wl_build_call(self.builder, await_ft, await_fn, vec_data_i64(&aa), 1)
        // Load result from buffer unless MIR marked this await as cleanup-only.
        var ignore_result = false
        if dest_place >= 0 and dest_place < body.place_locals.len() as i32:
            let dst_local = body.place_locals.get(dest_place as i64)
            if dst_local >= 0 and dst_local < body.local_type_ids.len() as i32:
                let dst_sema_ty = body.local_type_ids.get(dst_local as i64)
                let dst_resolved = self.mir_input.mir_resolve_alias(dst_sema_ty)
                if dst_resolved > 0 and self.mir_input.mir_get_type_kind(dst_resolved) == TypeKind.TY_VOID:
                    ignore_result = true
        // Load result from buffer, free buffer, store to dest
        if not ignore_result and dest_place >= 0 and dest_place < body.place_locals.len() as i32:
            var dst_llvm_ty: i64 = 0
            if task_mir_local >= 0:
                let trt_opt = self.async_task_result_types.get(task_mir_local)
                if trt_opt.is_some():
                    dst_llvm_ty = trt_opt.unwrap() as i64
            if dst_llvm_ty == 0 or dst_llvm_ty == wl_void_type(self.context):
                let dst_local = body.place_locals.get(dest_place as i64)
                let dst_sema_ty = body.local_type_ids.get(dst_local as i64)
                dst_llvm_ty = self.mir_sema_type_to_llvm(dst_sema_ty)
            if dst_llvm_ty == 0 or dst_llvm_ty == wl_void_type(self.context):
                if self.last_async_spawn_ret_ty != 0:
                    dst_llvm_ty = self.last_async_spawn_ret_ty
            if dst_llvm_ty == 0 or dst_llvm_ty == wl_void_type(self.context):
                dst_llvm_ty = wl_i32_type(self.context)
            let result_val = wl_build_load(self.builder, dst_llvm_ty, rbuf)
            let dst_alloca = self.create_entry_alloca(dst_llvm_ty)
            wl_build_store(self.builder, result_val, dst_alloca)
            let dst_local = body.place_locals.get(dest_place as i64)
            self.mir_local_ptrs.insert(dst_local, dst_alloca)
            self.mir_local_types.insert(dst_local, dst_llvm_ty)
        // Free result buffer
        var free_fn = wl_get_named_function(self.llmod, "with_free")
        if free_fn == 0:
            let fp: Vec[i64] = Vec.new()
            fp.push(wl_ptr_type(self.context))
            let fft = wl_function_type(wl_void_type(self.context), vec_data_i64(&fp), 1, 0)
            free_fn = wl_add_function(self.llmod, "with_free", fft)
        let free_ft = wl_global_get_value_type(free_fn)
        let fa: Vec[i64] = Vec.new()
        fa.push(rbuf)
        wl_build_call(self.builder, free_ft, free_fn, vec_data_i64(&fa), 1)
        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
            wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
        return true

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FIBER_SELECT:
        // Select: extract fiber_ids from all Task operands, pack into array,
        // call with_fiber_select(ids, count, &winner_index), store winner index.

        // Allocate array of fiber IDs on stack
        let arr_ty = wl_array_type(i32_ty, arg_count as i64)
        let ids_alloca = self.create_entry_alloca(arr_ty)

        // Extract fiber_id from each Task and store into array
        for ti in 0..arg_count:
            let task_op = self.mir_intrinsic_arg(body, args_id, ti)
            let task_ty = wl_type_of(task_op)
            let task_alloca = self.create_entry_alloca(task_ty)
            wl_build_store(self.builder, task_op, task_alloca)
            let fid_ptr = wl_build_struct_gep(self.builder, task_ty, task_alloca, 0)
            let fid = wl_build_load(self.builder, i32_ty, fid_ptr)
            let indices: Vec[i64] = Vec.new()
            indices.push(wl_const_int(i32_ty, 0, 0))
            indices.push(wl_const_int(i32_ty, ti as i64, 0))
            let slot = wl_build_gep(self.builder, arr_ty, ids_alloca, vec_data_i64(&indices), 2)
            wl_build_store(self.builder, fid, slot)

        // Allocate winner_index on stack
        let winner_alloca = self.create_entry_alloca(i32_ty)

        // Call with_fiber_select(ids_ptr, count, &winner_index)
        let select_fn_name = "with_fiber_select"
        var select_fn = wl_get_named_function(self.llmod, select_fn_name)
        if select_fn == 0:
            let sp: Vec[i64] = Vec.new()
            sp.push(ptr_ty)    // ids
            sp.push(i32_ty)    // count
            sp.push(ptr_ty)    // result_index
            let sel_ft = wl_function_type(wl_void_type(self.context), vec_data_i64(&sp), 3, 0)
            select_fn = wl_add_function(self.llmod, select_fn_name, sel_ft)
        let sel_ft2 = wl_global_get_value_type(select_fn)
        let sa: Vec[i64] = Vec.new()
        let zero_idx: Vec[i64] = Vec.new()
        zero_idx.push(wl_const_int(i32_ty, 0, 0))
        zero_idx.push(wl_const_int(i32_ty, 0, 0))
        let ids_ptr = wl_build_gep(self.builder, arr_ty, ids_alloca, vec_data_i64(&zero_idx), 2)
        sa.push(ids_ptr)
        sa.push(wl_const_int(i32_ty, arg_count as i64, 0))
        sa.push(winner_alloca)
        wl_build_call(self.builder, sel_ft2, select_fn, vec_data_i64(&sa), 3)

        // Load winner index and store to dest
        let winner_idx = wl_build_load(self.builder, i32_ty, winner_alloca)
        if dest_place >= 0 and dest_place < body.place_locals.len() as i32:
            let dst_local = body.place_locals.get(dest_place as i64)
            let dst_alloca = self.create_entry_alloca(i32_ty)
            wl_build_store(self.builder, winner_idx, dst_alloca)
            self.mir_local_ptrs.insert(dst_local, dst_alloca)
            self.mir_local_types.insert(dst_local, i32_ty)

        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
            wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
        return true

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FIBER_CANCEL:
        // Cancel: extract fiber_id from Task and request cancellation.
        // The caller is responsible for later awaiting/draining the Task and
        // freeing its result buffer once the fiber has actually unwound.
        let task_op = self.mir_intrinsic_arg(body, args_id, 0)
        let task_ty = wl_type_of(task_op)
        let task_alloca = self.create_entry_alloca(task_ty)
        wl_build_store(self.builder, task_op, task_alloca)
        let fid_ptr = wl_build_struct_gep(self.builder, task_ty, task_alloca, 0)
        let fid = wl_build_load(self.builder, wl_i32_type(self.context), fid_ptr)

        // Call with_fiber_cancel(fiber_id)
        let cancel_fn_name = "with_fiber_cancel"
        var cancel_fn = wl_get_named_function(self.llmod, cancel_fn_name)
        if cancel_fn == 0:
            let cp: Vec[i64] = Vec.new()
            cp.push(wl_i32_type(self.context))
            let cft = wl_function_type(wl_i32_type(self.context), vec_data_i64(&cp), 1, 0)
            cancel_fn = wl_add_function(self.llmod, cancel_fn_name, cft)
        let cft = wl_global_get_value_type(cancel_fn)
        let ca: Vec[i64] = Vec.new()
        ca.push(fid)
        result = wl_build_call(self.builder, cft, cancel_fn, vec_data_i64(&ca), 1)

        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
            wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
        return true

    else:
        return self.mir_emit_intrinsic_call_ext(body, intrinsic, args_id, dest_place, next_bb)

    // Store result to dest place (skip for void-returning intrinsics).
    if dest_place >= 0 and result != 0:
        let result_ty = wl_type_of(result)
        if result_ty != wl_void_type(self.context):
            let dest_ptr = self.mir_place_ptr(body, dest_place, true, result_ty)
            if dest_ptr != 0:
                wl_build_store(self.builder, result, dest_ptr)

    // Branch to next bb.
    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
    true

fn Codegen.mir_emit_intrinsic_call_ext(self: Codegen, body: MirBody, intrinsic: i32, args_id: i32, dest_place: i32, next_bb: i32) -> bool:
    let i64_ty = wl_i64_type(self.context)
    var result: i64 = 0

    if intrinsic == MirIntrinsic.MIR_INTRINSIC_OPT_IS_NONE:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let tk = wl_get_type_kind(wl_type_of(recv))
        if tk == wl_struct_type_kind():
            let disc = wl_build_extract_value(self.builder, recv, 0)
            // None = tag 1. is_none → tag != 0.
            result = wl_build_icmp(self.builder, wl_int_ne(), disc, wl_const_int(wl_type_of(disc), 0, 0))
        else if tk == wl_pointer_type_kind():
            result = wl_build_icmp(self.builder, wl_int_eq(), recv, wl_const_null(wl_type_of(recv)))
        else:
            result = wl_const_int(wl_i1_type(self.context), 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_TRIM:
        let r1 = self.mir_intrinsic_arg(body, args_id, 0)
        let t1 = wl_type_of(r1)
        let f1 = self.ensure_c_fn("with_str_trim", t1, 1)
        let a1: Vec[i64] = Vec.new()
        a1.push(r1)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_trim", t1, 1), f1, vec_data_i64(&a1), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_TO_UPPER:
        let r2 = self.mir_intrinsic_arg(body, args_id, 0)
        let t2 = wl_type_of(r2)
        let f2 = self.ensure_c_fn("with_str_to_upper", t2, 1)
        let a2: Vec[i64] = Vec.new()
        a2.push(r2)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_to_upper", t2, 1), f2, vec_data_i64(&a2), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_TO_LOWER:
        let r3 = self.mir_intrinsic_arg(body, args_id, 0)
        let t3 = wl_type_of(r3)
        let f3 = self.ensure_c_fn("with_str_to_lower", t3, 1)
        let a3: Vec[i64] = Vec.new()
        a3.push(r3)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_to_lower", t3, 1), f3, vec_data_i64(&a3), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_REPLACE:
        let r4 = self.mir_intrinsic_arg(body, args_id, 0)
        let t4 = wl_type_of(r4)
        let s4a = self.mir_intrinsic_arg(body, args_id, 1)
        let s4b = self.mir_intrinsic_arg(body, args_id, 2)
        let f4 = self.ensure_c_fn("with_str_replace", t4, 3)
        let a4: Vec[i64] = Vec.new()
        a4.push(r4)
        a4.push(s4a)
        a4.push(s4b)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_replace", t4, 3), f4, vec_data_i64(&a4), 3)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_SPLIT:
        let r6 = self.mir_intrinsic_arg(body, args_id, 0)
        let t6 = wl_type_of(r6)
        let d6 = self.mir_intrinsic_arg(body, args_id, 1)
        let vt6 = self.get_or_create_vec_type(0, t6)
        let out6 = self.create_entry_alloca(vt6)
        let f6 = self.ensure_c_fn("with_str_split_vec", wl_void_type(self.context), 3)
        let p6: Vec[i64] = Vec.new()
        p6.push(wl_ptr_type(self.context))
        p6.push(t6)
        p6.push(t6)
        let ft6 = wl_function_type(wl_void_type(self.context), vec_data_i64(&p6), 3, 0)
        let a6: Vec[i64] = Vec.new()
        a6.push(out6)
        a6.push(r6)
        a6.push(d6)
        let _ = wl_build_call(self.builder, ft6, f6, vec_data_i64(&a6), 3)
        result = wl_build_load(self.builder, vt6, out6)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_INDEX_OF:
        let r5 = self.mir_intrinsic_arg(body, args_id, 0)
        let n5 = self.mir_intrinsic_arg(body, args_id, 1)
        let f5 = self.ensure_c_fn("with_str_index_of", i64_ty, 2)
        let a5: Vec[i64] = Vec.new()
        a5.push(r5)
        a5.push(n5)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_index_of", i64_ty, 2), f5, vec_data_i64(&a5), 2)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_INCREMENT:
        let r7 = self.mir_intrinsic_arg(body, args_id, 0)
        let mp7 = self.mir_extract_map_ptr(r7)
        let k7 = self.mir_intrinsic_arg(body, args_id, 1)
        let ka7 = wl_build_alloca(self.builder, wl_type_of(k7))
        wl_build_store(self.builder, k7, ka7)
        let is7 = wl_const_int(i64_ty, if self.is_str_type(wl_type_of(k7)): 1 else: 0, 0)
        let f7 = self.ensure_hm_fn("with_hashmap_increment", wl_void_type(self.context))
        let p7: Vec[i64] = Vec.new()
        p7.push(wl_ptr_type(self.context))
        p7.push(wl_ptr_type(self.context))
        p7.push(i64_ty)
        let ft7 = wl_function_type(wl_void_type(self.context), vec_data_i64(&p7), 3, 0)
        let a7: Vec[i64] = Vec.new()
        a7.push(mp7)
        a7.push(ka7)
        a7.push(is7)
        let _ = wl_build_call(self.builder, ft7, f7, vec_data_i64(&a7), 3)
        result = 0

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_REPEAT:
        let sr_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let sr_n = self.mir_intrinsic_arg(body, args_id, 1)
        let sr_n64 = self.coerce_int(sr_n, i64_ty)
        let sr_ty = wl_type_of(sr_recv)
        let sr_fn = self.ensure_c_fn("with_str_repeat", sr_ty, 2)
        let sr_args: Vec[i64] = Vec.new()
        sr_args.push(sr_recv)
        sr_args.push(sr_n64)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_repeat", sr_ty, 2), sr_fn, vec_data_i64(&sr_args), 2)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ARR_LEN:
        // Array.len() returns the compile-time length of the array type
        let al_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let al_ty = wl_type_of(al_recv)
        var al_len = 0
        if wl_get_type_kind(al_ty) == wl_array_type_kind():
            al_len = wl_get_array_length(al_ty) as i32
        result = wl_const_int(wl_i32_type(self.context), al_len as i64, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ROTATE_LEFT or intrinsic == MirIntrinsic.MIR_INTRINSIC_ROTATE_RIGHT:
        let rot_val = self.mir_intrinsic_arg(body, args_id, 0)
        let rot_amt = self.mir_intrinsic_arg(body, args_id, 1)
        let rot_ty = wl_type_of(rot_val)
        let rot_width = wl_get_int_type_width(rot_ty)
        let rot_w_const = wl_const_int(rot_ty, rot_width as i64, 0)
        // Coerce shift amount to same type as value
        let rot_n = self.coerce_value_to_type(rot_amt, rot_ty)
        if intrinsic == MirIntrinsic.MIR_INTRINSIC_ROTATE_LEFT:
            // (x << n) | (x >> (W - n))
            let shl = wl_build_shl(self.builder, rot_val, rot_n)
            let sub = wl_build_sub(self.builder, rot_w_const, rot_n)
            let shr = wl_build_lshr(self.builder, rot_val, sub)
            result = wl_build_or(self.builder, shl, shr)
        else:
            // (x >> n) | (x << (W - n))
            let shr = wl_build_lshr(self.builder, rot_val, rot_n)
            let sub = wl_build_sub(self.builder, rot_w_const, rot_n)
            let shl = wl_build_shl(self.builder, rot_val, sub)
            result = wl_build_or(self.builder, shr, shl)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_INT_SWAP_BYTES:
        let sb_val = self.mir_intrinsic_arg(body, args_id, 0)
        let sb_ty = wl_type_of(sb_val)
        let sb_width = wl_get_int_type_width(sb_ty)
        if sb_width <= 8:
            // Byte swap on i8/u8 is identity
            result = sb_val
        else:
            // Call @llvm.bswap.i{16,32,64}
            let sb_fn_name = if sb_width == 16: "llvm.bswap.i16" else if sb_width == 32: "llvm.bswap.i32" else: "llvm.bswap.i64"
            let sb_sym = self.intern.intern(sb_fn_name)
            let sb_fv = self.fn_values.get(sb_sym)
            let sb_ft = self.fn_fn_types.get(sb_sym)
            if sb_fv.is_some() and sb_ft.is_some():
                let sb_args: Vec[i64] = Vec.new()
                sb_args.push(sb_val)
                result = wl_build_call(self.builder, sb_ft.unwrap() as i64, sb_fv.unwrap() as i64, vec_data_i64(&sb_args), 1)
            else:
                let sb_pts: Vec[i64] = Vec.new()
                sb_pts.push(sb_ty)
                let sb_fnt = wl_function_type(sb_ty, vec_data_i64(&sb_pts), 1, 0)
                let sb_func = wl_add_function(self.llmod, sb_fn_name, sb_fnt)
                self.fn_values.insert(sb_sym, sb_func)
                self.fn_fn_types.insert(sb_sym, sb_fnt)
                let sb_args: Vec[i64] = Vec.new()
                sb_args.push(sb_val)
                result = wl_build_call(self.builder, sb_fnt, sb_func, vec_data_i64(&sb_args), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_POPCOUNT:
        let pc_val = self.mir_intrinsic_arg(body, args_id, 0)
        let pc_ty = wl_type_of(pc_val)
        let pc_width = wl_get_int_type_width(pc_ty)
        let pc_fn_name = if pc_width == 8: "llvm.ctpop.i8" else if pc_width == 16: "llvm.ctpop.i16" else if pc_width == 32: "llvm.ctpop.i32" else: "llvm.ctpop.i64"
        let pc_sym = self.intern.intern(pc_fn_name)
        let pc_fv = self.fn_values.get(pc_sym)
        let pc_ft = self.fn_fn_types.get(pc_sym)
        if pc_fv.is_some() and pc_ft.is_some():
            let pc_args: Vec[i64] = Vec.new()
            pc_args.push(pc_val)
            let pc_raw = wl_build_call(self.builder, pc_ft.unwrap() as i64, pc_fv.unwrap() as i64, vec_data_i64(&pc_args), 1)
            result = if pc_width == 32: pc_raw else: wl_build_zext(self.builder, pc_raw, wl_i32_type(self.context))
        else:
            let pc_pts: Vec[i64] = Vec.new()
            pc_pts.push(pc_ty)
            let pc_fnt = wl_function_type(pc_ty, vec_data_i64(&pc_pts), 1, 0)
            let pc_func = wl_add_function(self.llmod, pc_fn_name, pc_fnt)
            self.fn_values.insert(pc_sym, pc_func)
            self.fn_fn_types.insert(pc_sym, pc_fnt)
            let pc_args: Vec[i64] = Vec.new()
            pc_args.push(pc_val)
            let pc_raw = wl_build_call(self.builder, pc_fnt, pc_func, vec_data_i64(&pc_args), 1)
            result = if pc_width == 32: pc_raw else: wl_build_zext(self.builder, pc_raw, wl_i32_type(self.context))

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_CLZ or intrinsic == MirIntrinsic.MIR_INTRINSIC_CTZ:
        let ct_val = self.mir_intrinsic_arg(body, args_id, 0)
        let ct_ty = wl_type_of(ct_val)
        let ct_width = wl_get_int_type_width(ct_ty)
        let ct_prefix = if intrinsic == MirIntrinsic.MIR_INTRINSIC_CLZ: "llvm.ctlz.i" else: "llvm.cttz.i"
        let ct_fn_name = if ct_width == 8: ct_prefix ++ "8" else if ct_width == 16: ct_prefix ++ "16" else if ct_width == 32: ct_prefix ++ "32" else: ct_prefix ++ "64"
        let ct_sym = self.intern.intern(ct_fn_name)
        let ct_fv = self.fn_values.get(ct_sym)
        let ct_ft = self.fn_fn_types.get(ct_sym)
        let ct_i1_ty = wl_i1_type(self.context)
        let ct_false = wl_const_int(ct_i1_ty, 0, 0)
        if ct_fv.is_some() and ct_ft.is_some():
            let ct_args: Vec[i64] = Vec.new()
            ct_args.push(ct_val)
            ct_args.push(ct_false)
            let ct_raw = wl_build_call(self.builder, ct_ft.unwrap() as i64, ct_fv.unwrap() as i64, vec_data_i64(&ct_args), 2)
            result = if ct_width == 32: ct_raw else: wl_build_zext(self.builder, ct_raw, wl_i32_type(self.context))
        else:
            let ct_pts: Vec[i64] = Vec.new()
            ct_pts.push(ct_ty)
            ct_pts.push(ct_i1_ty)
            let ct_fnt = wl_function_type(ct_ty, vec_data_i64(&ct_pts), 2, 0)
            let ct_func = wl_add_function(self.llmod, ct_fn_name, ct_fnt)
            self.fn_values.insert(ct_sym, ct_func)
            self.fn_fn_types.insert(ct_sym, ct_fnt)
            let ct_args: Vec[i64] = Vec.new()
            ct_args.push(ct_val)
            ct_args.push(ct_false)
            let ct_raw = wl_build_call(self.builder, ct_fnt, ct_func, vec_data_i64(&ct_args), 2)
            result = if ct_width == 32: ct_raw else: wl_build_zext(self.builder, ct_raw, wl_i32_type(self.context))

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_BITREVERSE:
        let br_val = self.mir_intrinsic_arg(body, args_id, 0)
        let br_ty = wl_type_of(br_val)
        let br_width = wl_get_int_type_width(br_ty)
        let br_fn_name = if br_width == 8: "llvm.bitreverse.i8" else if br_width == 16: "llvm.bitreverse.i16" else if br_width == 32: "llvm.bitreverse.i32" else: "llvm.bitreverse.i64"
        let br_sym = self.intern.intern(br_fn_name)
        let br_fv = self.fn_values.get(br_sym)
        let br_ft = self.fn_fn_types.get(br_sym)
        if br_fv.is_some() and br_ft.is_some():
            let br_args: Vec[i64] = Vec.new()
            br_args.push(br_val)
            result = wl_build_call(self.builder, br_ft.unwrap() as i64, br_fv.unwrap() as i64, vec_data_i64(&br_args), 1)
        else:
            let br_pts: Vec[i64] = Vec.new()
            br_pts.push(br_ty)
            let br_fnt = wl_function_type(br_ty, vec_data_i64(&br_pts), 1, 0)
            let br_func = wl_add_function(self.llmod, br_fn_name, br_fnt)
            self.fn_values.insert(br_sym, br_func)
            self.fn_fn_types.insert(br_sym, br_fnt)
            let br_args: Vec[i64] = Vec.new()
            br_args.push(br_val)
            result = wl_build_call(self.builder, br_fnt, br_func, vec_data_i64(&br_args), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MIN or intrinsic == MirIntrinsic.MIR_INTRINSIC_MAX:
        let mm_a = self.mir_intrinsic_arg(body, args_id, 0)
        let mm_b = self.mir_intrinsic_arg(body, args_id, 1)
        let mm_ty = wl_type_of(mm_a)
        let mm_tk = wl_get_type_kind(mm_ty)
        let mm_is_float = mm_tk == wl_float_type_kind() or mm_tk == wl_double_type_kind()
        if mm_is_float:
            let mm_fn_prefix = if intrinsic == MirIntrinsic.MIR_INTRINSIC_MIN: "llvm.minnum." else: "llvm.maxnum."
            let mm_suffix = if mm_tk == wl_float_type_kind(): "f32" else: "f64"
            let mm_fn_name = mm_fn_prefix ++ mm_suffix
            let mm_sym = self.intern.intern(mm_fn_name)
            let mm_fv = self.fn_values.get(mm_sym)
            let mm_ft = self.fn_fn_types.get(mm_sym)
            if mm_fv.is_some() and mm_ft.is_some():
                let mm_args: Vec[i64] = Vec.new()
                mm_args.push(mm_a)
                mm_args.push(mm_b)
                result = wl_build_call(self.builder, mm_ft.unwrap() as i64, mm_fv.unwrap() as i64, vec_data_i64(&mm_args), 2)
            else:
                let mm_pts: Vec[i64] = Vec.new()
                mm_pts.push(mm_ty)
                mm_pts.push(mm_ty)
                let mm_fnt = wl_function_type(mm_ty, vec_data_i64(&mm_pts), 2, 0)
                let mm_func = wl_add_function(self.llmod, mm_fn_name, mm_fnt)
                self.fn_values.insert(mm_sym, mm_func)
                self.fn_fn_types.insert(mm_sym, mm_fnt)
                let mm_args: Vec[i64] = Vec.new()
                mm_args.push(mm_a)
                mm_args.push(mm_b)
                result = wl_build_call(self.builder, mm_fnt, mm_func, vec_data_i64(&mm_args), 2)
        else:
            // Integer min/max: icmp + select
            let mm_is_min = intrinsic == MirIntrinsic.MIR_INTRINSIC_MIN
            let mm_pred = if mm_is_min: wl_int_slt() else: wl_int_sgt()
            let mm_cmp = wl_build_icmp(self.builder, mm_pred, mm_a, mm_b)
            result = wl_build_select(self.builder, mm_cmp, mm_a, mm_b)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_ABS:
        let abs_val = self.mir_intrinsic_arg(body, args_id, 0)
        let abs_ty = wl_type_of(abs_val)
        let abs_tk = wl_get_type_kind(abs_ty)
        let abs_is_float = abs_tk == wl_float_type_kind() or abs_tk == wl_double_type_kind()
        if abs_is_float:
            let abs_fn_name = if abs_tk == wl_float_type_kind(): "llvm.fabs.f32" else: "llvm.fabs.f64"
            let abs_sym = self.intern.intern(abs_fn_name)
            let abs_fv = self.fn_values.get(abs_sym)
            let abs_ft = self.fn_fn_types.get(abs_sym)
            if abs_fv.is_some() and abs_ft.is_some():
                let abs_args: Vec[i64] = Vec.new()
                abs_args.push(abs_val)
                result = wl_build_call(self.builder, abs_ft.unwrap() as i64, abs_fv.unwrap() as i64, vec_data_i64(&abs_args), 1)
            else:
                let abs_pts: Vec[i64] = Vec.new()
                abs_pts.push(abs_ty)
                let abs_fnt = wl_function_type(abs_ty, vec_data_i64(&abs_pts), 1, 0)
                let abs_func = wl_add_function(self.llmod, abs_fn_name, abs_fnt)
                self.fn_values.insert(abs_sym, abs_func)
                self.fn_fn_types.insert(abs_sym, abs_fnt)
                let abs_args: Vec[i64] = Vec.new()
                abs_args.push(abs_val)
                result = wl_build_call(self.builder, abs_fnt, abs_func, vec_data_i64(&abs_args), 1)
        else:
            // Integer abs: negate + select on sign
            let abs_zero = wl_const_int(abs_ty, 0, 0)
            let abs_neg = wl_build_sub(self.builder, abs_zero, abs_val)
            let abs_is_neg = wl_build_icmp(self.builder, wl_int_slt(), abs_val, abs_zero)
            result = wl_build_select(self.builder, abs_is_neg, abs_neg, abs_val)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMA:
        let fma_a = self.mir_intrinsic_arg(body, args_id, 0)
        let fma_b = self.mir_intrinsic_arg(body, args_id, 1)
        let fma_c = self.mir_intrinsic_arg(body, args_id, 2)
        let fma_ty = wl_type_of(fma_a)
        let fma_tk = wl_get_type_kind(fma_ty)
        let fma_fn_name = if fma_tk == wl_float_type_kind(): "llvm.fma.f32" else: "llvm.fma.f64"
        let fma_sym = self.intern.intern(fma_fn_name)
        let fma_fv = self.fn_values.get(fma_sym)
        let fma_ft = self.fn_fn_types.get(fma_sym)
        if fma_fv.is_some() and fma_ft.is_some():
            let fma_args: Vec[i64] = Vec.new()
            fma_args.push(fma_a)
            fma_args.push(fma_b)
            fma_args.push(fma_c)
            result = wl_build_call(self.builder, fma_ft.unwrap() as i64, fma_fv.unwrap() as i64, vec_data_i64(&fma_args), 3)
        else:
            let fma_pts: Vec[i64] = Vec.new()
            fma_pts.push(fma_ty)
            fma_pts.push(fma_ty)
            fma_pts.push(fma_ty)
            let fma_fnt = wl_function_type(fma_ty, vec_data_i64(&fma_pts), 3, 0)
            let fma_func = wl_add_function(self.llmod, fma_fn_name, fma_fnt)
            self.fn_values.insert(fma_sym, fma_func)
            self.fn_fn_types.insert(fma_sym, fma_fnt)
            let fma_args: Vec[i64] = Vec.new()
            fma_args.push(fma_a)
            fma_args.push(fma_b)
            fma_args.push(fma_c)
            result = wl_build_call(self.builder, fma_fnt, fma_func, vec_data_i64(&fma_args), 3)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_OPT_FILTER:
        result = self.mir_emit_opt_filter(body, args_id)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_MAP:
        result = self.mir_emit_vec_map(body, args_id)
    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_FILTER:
        result = self.mir_emit_vec_filter(body, args_id)
    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_FOLD:
        result = self.mir_emit_vec_fold(body, args_id)
    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_CONTAINS:
        result = self.mir_emit_vec_contains(body, args_id)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_JOIN:
        let vj_recv = self.mir_intrinsic_recv_vec_value(body, args_id)
        let vj_sep = self.mir_intrinsic_arg(body, args_id, 1)
        let vj_str_sym = self.intern.intern("str")
        let vj_str_ty = self.struct_llvm_types.get(self.struct_type_map.get(vj_str_sym).unwrap() as i64)
        let vj_ptr_ty = wl_ptr_type(self.context)
        let vj_fn = self.ensure_c_fn("with_vec_str_join", vj_str_ty, 2)
        let vj_alloca = wl_build_alloca(self.builder, wl_type_of(vj_recv))
        wl_build_store(self.builder, vj_recv, vj_alloca)
        let vj_params: Vec[i64] = Vec.new()
        vj_params.push(vj_ptr_ty)
        vj_params.push(vj_str_ty)
        let vj_ft = wl_function_type(vj_str_ty, vec_data_i64(&vj_params), 2, 0)
        let vj_args: Vec[i64] = Vec.new()
        vj_args.push(vj_alloca)
        vj_args.push(vj_sep)
        result = wl_build_call(self.builder, vj_ft, vj_fn, vec_data_i64(&vj_args), 2)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_DYN_DOWNCAST:
        // Extract concrete value from dyn trait object.
        // Args: (fat_ptr, type_sym_as_int)
        let dd_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let dd_type_sym_val = self.mir_intrinsic_arg(body, args_id, 1)
        let dd_type_sym = wl_const_int_sext_val(dd_type_sym_val) as i32
        // Translate AST pool sym to codegen intern pool sym
        var dd_cg_type_sym = dd_type_sym
        let dd_text = self.sema_symbol_text(dd_type_sym)
        if dd_text.len() > 0:
            dd_cg_type_sym = self.intern.intern(dd_text)
        // Extract data_ptr from fat pointer (field 0)
        let dd_data_ptr = wl_build_extract_value(self.builder, dd_recv, 0)
        // Load concrete struct from data_ptr
        let dd_st = self.struct_type_map.get(dd_cg_type_sym)
        if dd_st.is_some():
            let dd_concrete_ty = self.struct_llvm_types.get(dd_st.unwrap() as i64)
            result = wl_build_load(self.builder, dd_concrete_ty, dd_data_ptr)
        else:
            result = wl_build_load(self.builder, wl_i32_type(self.context), dd_data_ptr)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_DYN_VTABLE_CMP:
        // Compare vtable pointer of dyn trait object against expected vtable.
        // Args: (fat_ptr, type_sym_as_int, trait_sym_as_int)
        let dv_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let dv_type_sym_val = self.mir_intrinsic_arg(body, args_id, 1)
        let dv_trait_sym_val = self.mir_intrinsic_arg(body, args_id, 2)
        // Extract type_sym and trait_sym from constant int values
        let dv_type_sym = wl_const_int_sext_val(dv_type_sym_val) as i32
        let dv_trait_sym = wl_const_int_sext_val(dv_trait_sym_val) as i32
        // Translate AST pool syms to codegen intern pool syms
        var dv_cg_type_sym = dv_type_sym
        let dv_text = self.sema_symbol_text(dv_type_sym)
        if dv_text.len() > 0:
            dv_cg_type_sym = self.intern.intern(dv_text)
        var dv_cg_trait_sym = dv_trait_sym
        let dv_tt = self.sema_symbol_text(dv_trait_sym)
        if dv_tt.len() > 0:
            dv_cg_trait_sym = self.intern.intern(dv_tt)
        // Look up vtable global
        let dv_key = codegen_hash_type_trait_key(dv_cg_type_sym, dv_cg_trait_sym)
        let dv_vt_opt = self.vtable_globals.get(dv_key)
        if dv_vt_opt.is_some():
            let dv_expected_vt = dv_vt_opt.unwrap() as i64
            // Extract vtable_ptr from fat pointer (field 1)
            let dv_vtable_ptr = wl_build_extract_value(self.builder, dv_recv, 1)
            // Compare: ptr_to_int(vtable_ptr) == ptr_to_int(expected)
            let dv_vt_int = wl_build_ptr_to_int(self.builder, dv_vtable_ptr, i64_ty)
            let dv_exp_int = wl_build_ptr_to_int(self.builder, dv_expected_vt, i64_ty)
            result = wl_build_icmp(self.builder, wl_int_eq(), dv_vt_int, dv_exp_int)
        else:
            result = wl_const_int(wl_i1_type(self.context), 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_TO_STR:
        let fmt_val = self.mir_intrinsic_arg(body, args_id, 0)
        let fmt_arg_start = body.call_arg_starts.get(args_id as i64)
        let fmt_op = body.call_arg_operands.get(fmt_arg_start as i64)
        let fmt_sema_ty = self.mir_operand_sema_type(body, fmt_op)
        let fmt_str_ty = self.resolve_named_type(self.intern.intern("str"))
        result = self.coerce_typed_val_to_str(fmt_val, fmt_sema_ty, fmt_str_ty)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_DEBUG_STR:
        let dbg_val = self.mir_intrinsic_arg(body, args_id, 0)
        let dbg_str_ty = self.resolve_named_type(self.intern.intern("str"))
        result = self.call_runtime_str_fn("with_fmt_str_debug", dbg_val, dbg_str_ty)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_DEBUG:
        let dbg_val = self.mir_intrinsic_arg(body, args_id, 0)
        let dbg_type_val = self.mir_intrinsic_arg(body, args_id, 1)
        let dbg_sema_ty = wl_const_int_sext_val(dbg_type_val) as i32
        let dbg_str_ty = self.resolve_named_type(self.intern.intern("str"))
        result = self.gen_debug_format(dbg_val, dbg_sema_ty, dbg_str_ty)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_SPEC:
        // args: [value, flags, width, precision, sema_type_id]
        let sp_val = self.mir_intrinsic_arg(body, args_id, 0)
        let sp_flags_v = self.mir_intrinsic_arg(body, args_id, 1)
        let sp_width_v = self.mir_intrinsic_arg(body, args_id, 2)
        let sp_prec_v = self.mir_intrinsic_arg(body, args_id, 3)
        let sp_type_v = self.mir_intrinsic_arg(body, args_id, 4)
        let sp_str_ty = self.resolve_named_type(self.intern.intern("str"))
        let sp_flags = wl_const_int_sext_val(sp_flags_v) as i32
        let sp_width = wl_const_int_sext_val(sp_width_v) as i32
        let sp_prec = wl_const_int_sext_val(sp_prec_v) as i32
        let sp_mode = sp_flags & 255
        result = self.gen_fmt_with_spec(sp_val, sp_flags, sp_width, sp_prec, sp_mode, sp_str_ty)

    // ── FmtBuffer intrinsics (f-string formatting via buffer) ────
    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_BUF_NEW:
        result = self.gen_fmt_buf_new()

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_BUF_WRITE_STR:
        let fb_buf = self.mir_intrinsic_arg(body, args_id, 0)
        let fb_str = self.mir_intrinsic_arg(body, args_id, 1)
        self.gen_fmt_buf_write_str(fb_buf, fb_str)
        result = wl_const_int(wl_i32_type(self.context), 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_BUF_WRITE_FMT:
        // args: [buf, value, flags, width, precision, sema_type_id]
        let fb_buf = self.mir_intrinsic_arg(body, args_id, 0)
        let fb_val = self.mir_intrinsic_arg(body, args_id, 1)
        let fb_flags_v = self.mir_intrinsic_arg(body, args_id, 2)
        let fb_width_v = self.mir_intrinsic_arg(body, args_id, 3)
        let fb_prec_v = self.mir_intrinsic_arg(body, args_id, 4)
        let fb_type_v = self.mir_intrinsic_arg(body, args_id, 5)
        let fb_flags = wl_const_int_sext_val(fb_flags_v) as i32
        let fb_width = wl_const_int_sext_val(fb_width_v) as i32
        let fb_prec = wl_const_int_sext_val(fb_prec_v) as i32
        let fb_mode = fb_flags & 255
        self.gen_fmt_buf_write_fmt(fb_buf, fb_val, fb_flags, fb_width, fb_prec, fb_mode)
        result = wl_const_int(wl_i32_type(self.context), 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_BUF_FINISH:
        let fb_buf = self.mir_intrinsic_arg(body, args_id, 0)
        result = self.gen_fmt_buf_finish(fb_buf)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_CHAN_SEND:
        // Sender.send(value): extract handle, alloca value, store, call with_channel_send
        let send_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let send_val = self.mir_intrinsic_arg(body, args_id, 1)
        let send_val_ty = wl_type_of(send_val)
        // Extract handle (field 0) from Sender struct
        let send_handle = wl_build_extract_value(self.builder, send_recv, 0)
        // Alloca for the value
        let send_slot = self.create_entry_alloca(send_val_ty)
        wl_build_store(self.builder, send_val, send_slot)
        // Call with_channel_send(handle, slot_ptr)
        let cs_fn_name = "with_channel_send"
        var cs_fn = wl_get_named_function(self.llmod, cs_fn_name)
        if cs_fn == 0:
            let csp: Vec[i64] = Vec.new()
            csp.push(wl_i64_type(self.context))   // handle
            csp.push(wl_ptr_type(self.context))    // value_ptr
            let csft = wl_function_type(wl_void_type(self.context), vec_data_i64(&csp), 2, 0)
            cs_fn = wl_add_function(self.llmod, cs_fn_name, csft)
        let csft2 = wl_global_get_value_type(cs_fn)
        let csa: Vec[i64] = Vec.new()
        csa.push(send_handle)
        csa.push(send_slot)
        wl_build_call(self.builder, csft2, cs_fn, vec_data_i64(&csa), 2)
        result = wl_const_int(wl_i32_type(self.context), 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_CHAN_CREATE:
        // Channel[T].new(capacity): extract elem_size from generic T arg, call with_channel_create
        let create_cap = self.mir_intrinsic_arg(body, args_id, 0)
        // Determine element size from destination type (Channel[T])
        var chan_elem_size: i64 = 8  // default for i64
        let dest_sema_ch = self.mir_intrinsic_dest_sema_type(body, dest_place)
        if dest_sema_ch > 0:
            let resolved_ch = self.mir_input.mir_resolve_alias(dest_sema_ch)
            if self.mir_input.mir_get_type_kind(resolved_ch) == TypeKind.TY_GENERIC_INST:
                let gi_argc = self.mir_input.mir_get_type_d2(resolved_ch)
                if gi_argc > 0:
                    let args_start_ch = self.mir_input.mir_get_type_d1(resolved_ch)
                    let elem_tid = self.mir_input.mir_get_type_extra(args_start_ch)
                    if elem_tid > 0:
                        let elem_llvm = self.mir_sema_type_to_llvm(elem_tid)
                        if elem_llvm != 0:
                            chan_elem_size = self.abi_size_of(elem_llvm)
        // Call with_channel_create(capacity, elem_size) -> i64
        let ccr_fn_name = "with_channel_create"
        var ccr_fn = wl_get_named_function(self.llmod, ccr_fn_name)
        if ccr_fn == 0:
            let ccrp: Vec[i64] = Vec.new()
            ccrp.push(wl_i32_type(self.context))   // capacity
            ccrp.push(wl_i32_type(self.context))   // elem_size
            let ccrft = wl_function_type(wl_i64_type(self.context), vec_data_i64(&ccrp), 2, 0)
            ccr_fn = wl_add_function(self.llmod, ccr_fn_name, ccrft)
        let ccrft2 = wl_global_get_value_type(ccr_fn)
        let ccra: Vec[i64] = Vec.new()
        ccra.push(create_cap)
        ccra.push(wl_const_int(wl_i32_type(self.context), chan_elem_size, 0))
        let chan_handle = wl_build_call(self.builder, ccrft2, ccr_fn, vec_data_i64(&ccra), 2)
        // Wrap in Channel { handle } struct
        let chan_struct_fields: Vec[i64] = Vec.new()
        chan_struct_fields.push(wl_i64_type(self.context))
        let chan_struct_ty = wl_struct_type(self.context, vec_data_i64(&chan_struct_fields), 1, 0)
        let empty_chan = self.build_default_value(chan_struct_ty)
        result = wl_build_insert_value(self.builder, empty_chan, chan_handle, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_CHAN_RECV:
        // Receiver.recv(): extract handle, alloca for result, call with_channel_recv, load result
        let recv_self = self.mir_intrinsic_arg(body, args_id, 0)
        // Extract handle from Receiver struct
        let recv_handle = wl_build_extract_value(self.builder, recv_self, 0)
        // Determine element type from dest place
        var recv_elem_ty = wl_i32_type(self.context)
        if dest_place >= 0 and dest_place < body.place_locals.len() as i32:
            let dst_local = body.place_locals.get(dest_place as i64)
            let dst_sema_ty = body.local_type_ids.get(dst_local as i64)
            let dst_ll = self.mir_sema_type_to_llvm(dst_sema_ty)
            if dst_ll != 0:
                recv_elem_ty = dst_ll
        // Alloca for the received value
        let recv_slot = self.create_entry_alloca(recv_elem_ty)
        // Call with_channel_recv(handle, &slot) → i32 status
        let cr_fn_name = "with_channel_recv"
        var cr_fn = wl_get_named_function(self.llmod, cr_fn_name)
        if cr_fn == 0:
            let crp: Vec[i64] = Vec.new()
            crp.push(wl_i64_type(self.context))   // handle
            crp.push(wl_ptr_type(self.context))    // out_ptr
            let crft = wl_function_type(wl_i32_type(self.context), vec_data_i64(&crp), 2, 0)
            cr_fn = wl_add_function(self.llmod, cr_fn_name, crft)
        let crft2 = wl_global_get_value_type(cr_fn)
        let cra: Vec[i64] = Vec.new()
        cra.push(recv_handle)
        cra.push(recv_slot)
        wl_build_call(self.builder, crft2, cr_fn, vec_data_i64(&cra), 2)
        // Load the received value
        result = wl_build_load(self.builder, recv_elem_ty, recv_slot)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_CHAN_CLOSE:
        // .close(): extract handle, call with_channel_close(handle)
        let close_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let close_handle = wl_build_extract_value(self.builder, close_recv, 0)
        let cc_fn_name = "with_channel_close"
        var cc_fn = wl_get_named_function(self.llmod, cc_fn_name)
        if cc_fn == 0:
            let ccp: Vec[i64] = Vec.new()
            ccp.push(wl_i64_type(self.context))
            let ccft = wl_function_type(wl_void_type(self.context), vec_data_i64(&ccp), 1, 0)
            cc_fn = wl_add_function(self.llmod, cc_fn_name, ccft)
        let ccft2 = wl_global_get_value_type(cc_fn)
        let cca: Vec[i64] = Vec.new()
        cca.push(close_handle)
        wl_build_call(self.builder, ccft2, cc_fn, vec_data_i64(&cca), 1)
        result = wl_const_int(wl_i32_type(self.context), 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_SCOPE_CREATE:
        // with_scope_create() -> i64
        var sc_fn = wl_get_named_function(self.llmod, "with_scope_create")
        if sc_fn == 0:
            let scft = wl_function_type(wl_i64_type(self.context), 0, 0, 0)
            sc_fn = wl_add_function(self.llmod, "with_scope_create", scft)
        let scft2 = wl_global_get_value_type(sc_fn)
        result = wl_build_call(self.builder, scft2, sc_fn, 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_SCOPE_AWAIT_ALL:
        // with_scope_await_all(handle: i64)
        let sa_handle = self.mir_intrinsic_arg(body, args_id, 0)
        var sa_fn = wl_get_named_function(self.llmod, "with_scope_await_all")
        if sa_fn == 0:
            let sap: Vec[i64] = Vec.new()
            sap.push(wl_i64_type(self.context))
            let saft = wl_function_type(wl_void_type(self.context), vec_data_i64(&sap), 1, 0)
            sa_fn = wl_add_function(self.llmod, "with_scope_await_all", saft)
        let saft2 = wl_global_get_value_type(sa_fn)
        let saa: Vec[i64] = Vec.new()
        saa.push(sa_handle)
        wl_build_call(self.builder, saft2, sa_fn, vec_data_i64(&saa), 1)
        result = wl_const_int(wl_i32_type(self.context), 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_SCOPE_DESTROY:
        // with_scope_destroy(handle: i64)
        let sd_handle = self.mir_intrinsic_arg(body, args_id, 0)
        var sd_fn = wl_get_named_function(self.llmod, "with_scope_destroy")
        if sd_fn == 0:
            let sdp: Vec[i64] = Vec.new()
            sdp.push(wl_i64_type(self.context))
            let sdft = wl_function_type(wl_void_type(self.context), vec_data_i64(&sdp), 1, 0)
            sd_fn = wl_add_function(self.llmod, "with_scope_destroy", sdft)
        let sdft2 = wl_global_get_value_type(sd_fn)
        let sda: Vec[i64] = Vec.new()
        sda.push(sd_handle)
        wl_build_call(self.builder, sdft2, sd_fn, vec_data_i64(&sda), 1)
        result = wl_const_int(wl_i32_type(self.context), 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FIBER_IS_CANCELLED:
        var ic_fn = wl_get_named_function(self.llmod, "with_fiber_is_cancelled")
        if ic_fn == 0:
            let icft = wl_function_type(wl_i32_type(self.context), 0, 0, 0)
            ic_fn = wl_add_function(self.llmod, "with_fiber_is_cancelled", icft)
        let icft2 = wl_global_get_value_type(ic_fn)
        result = wl_build_call(self.builder, icft2, ic_fn, 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FIBER_WAS_CANCELLED_RETURN:
        let wcr_fid = self.mir_intrinsic_arg(body, args_id, 0)
        var wcr_fn = wl_get_named_function(self.llmod, "with_fiber_was_cancelled_return")
        if wcr_fn == 0:
            let wcrp: Vec[i64] = Vec.new()
            wcrp.push(wl_i32_type(self.context))
            let wcrft = wl_function_type(wl_i32_type(self.context), vec_data_i64(&wcrp), 1, 0)
            wcr_fn = wl_add_function(self.llmod, "with_fiber_was_cancelled_return", wcrft)
        let wcrft2 = wl_global_get_value_type(wcr_fn)
        let wcra: Vec[i64] = Vec.new()
        wcra.push(wcr_fid)
        result = wl_build_call(self.builder, wcrft2, wcr_fn, vec_data_i64(&wcra), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_FIBER_SET_CANCELLED_RETURN:
        var scr_fn = wl_get_named_function(self.llmod, "with_fiber_set_cancelled_return")
        if scr_fn == 0:
            let scrft = wl_function_type(wl_void_type(self.context), 0, 0, 0)
            scr_fn = wl_add_function(self.llmod, "with_fiber_set_cancelled_return", scrft)
        let scrft2 = wl_global_get_value_type(scr_fn)
        wl_build_call(self.builder, scrft2, scr_fn, 0, 0)
        result = wl_const_int(wl_i32_type(self.context), 0, 0)

    else:
        return false

    if dest_place >= 0 and result != 0:
        let rt = wl_type_of(result)
        if rt != wl_void_type(self.context):
            let dp = self.mir_place_ptr(body, dest_place, true, rt)
            if dp != 0:
                wl_build_store(self.builder, result, dp)
    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
    true

fn Codegen.mir_emit_opt_filter(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let ptr_ty = wl_ptr_type(self.context)
    let i1_ty = wl_i1_type(self.context)
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
    let obj_ty = wl_type_of(recv)
    let recv_tk = wl_get_type_kind(obj_ty)
    if recv_tk != wl_struct_type_kind() and recv_tk != wl_pointer_type_kind():
        return recv
    // Get payload type: sema first, then LLVM struct field fallback
    var payload_ty: i64 = 0
    if recv_tk == wl_pointer_type_kind():
        payload_ty = obj_ty
    else:
        let arg_start_of = body.call_arg_starts.get(args_id as i64)
        let recv_op_id = body.call_arg_operands.get(arg_start_of as i64)
        let recv_sema = self.mir_operand_sema_type(body, recv_op_id)
        payload_ty = self.mir_builtin_variant_payload_llvm_type(recv_sema, 0)
        if payload_ty == 0 and wl_count_struct_elem_types(obj_ty) > 1:
            payload_ty = wl_struct_get_type_at(obj_ty, 1)
    let elem_ty = if payload_ty != 0: payload_ty else: self.type_fallback()
    let is_some = if recv_tk == wl_pointer_type_kind():
        wl_build_icmp(self.builder, wl_int_ne(), recv, wl_const_null(obj_ty))
    else:
        let disc = wl_build_extract_value(self.builder, recv, 0)
        wl_build_icmp(self.builder, wl_int_eq(), disc, wl_const_int(wl_type_of(disc), 0, 0))
    let fn_val = self.mir_intrinsic_arg(body, args_id, 1)
    let cty = wl_type_of(fn_val)
    var fn_ptr = fn_val
    var ctx_ptr: i64 = 0
    var is_fat = 0
    if wl_get_type_kind(cty) == wl_struct_type_kind() and wl_count_struct_elem_types(cty) == 2:
        fn_ptr = wl_build_extract_value(self.builder, fn_val, 0)
        ctx_ptr = wl_build_extract_value(self.builder, fn_val, 1)
        is_fat = 1
    var fn_ty: i64 = 0
    if is_fat != 0:
        let fp: Vec[i64] = Vec.new()
        fp.push(ptr_ty)
        fp.push(elem_ty)
        fn_ty = wl_function_type(i1_ty, vec_data_i64(&fp), 2, 0)
    else:
        fn_ty = wl_global_get_value_type(fn_ptr)
    let filt_then = wl_append_bb(self.context, self.current_function, "of.some")
    let filt_else = wl_append_bb(self.context, self.current_function, "of.none")
    let filt_check = wl_append_bb(self.context, self.current_function, "of.check")
    let filt_merge = wl_append_bb(self.context, self.current_function, "of.merge")
    wl_build_cond_br(self.builder, is_some, filt_then, filt_else)
    wl_position_at_end(self.builder, filt_then)
    let payload = if recv_tk == wl_pointer_type_kind(): recv else: wl_build_extract_value(self.builder, recv, 1)
    let filt_args: Vec[i64] = Vec.new()
    if is_fat != 0:
        filt_args.push(ctx_ptr)
    filt_args.push(payload)
    let filt_arg_count = if is_fat != 0: 2 else: 1
    let pred_result = wl_build_call(self.builder, fn_ty, fn_ptr, vec_data_i64(&filt_args), filt_arg_count)
    var filt_bool = pred_result
    if wl_type_of(pred_result) != wl_i1_type(self.context):
        filt_bool = wl_build_icmp(self.builder, wl_int_ne(), pred_result, wl_const_int(wl_type_of(pred_result), 0, 0))
    wl_build_cond_br(self.builder, filt_bool, filt_check, filt_else)
    wl_position_at_end(self.builder, filt_check)
    wl_build_br(self.builder, filt_merge)
    let check_end = wl_get_insert_block(self.builder)
    wl_position_at_end(self.builder, filt_else)
    let filt_none = if recv_tk == wl_pointer_type_kind(): wl_const_null(obj_ty) else: self.build_option_none(obj_ty)
    wl_build_br(self.builder, filt_merge)
    let else_end = wl_get_insert_block(self.builder)
    wl_position_at_end(self.builder, filt_merge)
    let filt_phi = wl_build_phi(self.builder, obj_ty)
    let phi_vals: Vec[i64] = Vec.new()
    let phi_bbs: Vec[i64] = Vec.new()
    phi_vals.push(recv)
    phi_bbs.push(check_end)
    phi_vals.push(filt_none)
    phi_bbs.push(else_end)
    wl_add_incoming(filt_phi, vec_data_i64(&phi_vals), vec_data_i64(&phi_bbs), 2)
    filt_phi

fn Codegen.mir_emit_vec_map(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let void_ty = wl_void_type(self.context)
    let recv = self.mir_intrinsic_recv_vec_value(body, args_id)
    let fn_val = self.mir_intrinsic_arg(body, args_id, 1)
    let cty = wl_type_of(fn_val)
    var fn_ptr = fn_val
    var ctx_ptr: i64 = 0
    var is_fat = 0
    if wl_get_type_kind(cty) == wl_struct_type_kind() and wl_count_struct_elem_types(cty) == 2:
        fn_ptr = wl_build_extract_value(self.builder, fn_val, 0)
        ctx_ptr = wl_build_extract_value(self.builder, fn_val, 1)
        is_fat = 1
    var elem_ty = i32_ty
    var fn_ty: i64 = 0
    var ret_ty: i64 = 0
    if is_fat != 0:
        // Fat pointer closure: fn_ptr is extract_value, not a global.
        // Build fn_ty from closure calling convention: fn(ptr, elem) -> i32
        let fp: Vec[i64] = Vec.new()
        fp.push(ptr_ty)
        fp.push(elem_ty)
        fn_ty = wl_function_type(i32_ty, vec_data_i64(&fp), 2, 0)
        ret_ty = i32_ty
    else:
        fn_ty = wl_global_get_value_type(fn_ptr)
        ret_ty = wl_get_return_type(fn_ty)
    let len = wl_build_extract_value(self.builder, recv, 1)
    let rvt = self.get_or_create_vec_type(0, ret_ty)
    let ra = self.create_entry_alloca(rvt)
    wl_build_store(self.builder, self.build_default_value(rvt), ra)
    let nf = self.ensure_vec_runtime_fn("with_vec_new_out", void_ty, 2)
    let nt = self.get_vec_fn_type("with_vec_new_out", void_ty, 2)
    let na: Vec[i64] = Vec.new()
    na.push(ra)
    na.push(wl_const_int(i64_ty, self.abi_size_of(ret_ty), 0))
    let _ = wl_build_call(self.builder, nt, nf, vec_data_i64(&na), 2)
    let sa = self.create_entry_alloca(wl_type_of(recv))
    wl_build_store(self.builder, recv, sa)
    let ctr = self.create_entry_alloca(i64_ty)
    wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), ctr)
    let tmp = self.create_entry_alloca(ret_ty)
    let cb = wl_append_bb(self.context, self.current_function, "m.c")
    let bb = wl_append_bb(self.context, self.current_function, "m.b")
    let ib = wl_append_bb(self.context, self.current_function, "m.i")
    let eb = wl_append_bb(self.context, self.current_function, "m.e")
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, cb)
    let cv = wl_build_load(self.builder, i64_ty, ctr)
    wl_build_cond_br(self.builder, wl_build_icmp(self.builder, wl_int_slt(), cv, len), bb, eb)
    wl_position_at_end(self.builder, bb)
    let gf = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
    let gt = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
    let ga: Vec[i64] = Vec.new()
    ga.push(sa)
    ga.push(wl_build_load(self.builder, i64_ty, ctr))
    let ep = wl_build_call(self.builder, gt, gf, vec_data_i64(&ga), 2)
    let el = wl_build_load(self.builder, elem_ty, ep)
    let ca: Vec[i64] = Vec.new()
    if is_fat != 0: ca.push(ctx_ptr)
    ca.push(el)
    let cc = if is_fat != 0: 2 else: 1
    let rv = wl_build_call(self.builder, fn_ty, fn_ptr, vec_data_i64(&ca), cc)
    wl_build_store(self.builder, rv, tmp)
    let pf = self.ensure_vec_runtime_fn("with_vec_push", void_ty, 2)
    let pt = self.get_vec_fn_type("with_vec_push", void_ty, 2)
    let pa: Vec[i64] = Vec.new()
    pa.push(ra)
    pa.push(tmp)
    let _ = wl_build_call(self.builder, pt, pf, vec_data_i64(&pa), 2)
    wl_build_br(self.builder, ib)
    wl_position_at_end(self.builder, ib)
    wl_build_store(self.builder, wl_build_add(self.builder, wl_build_load(self.builder, i64_ty, ctr), wl_const_int(i64_ty, 1, 0)), ctr)
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, eb)
    wl_build_load(self.builder, rvt, ra)

fn Codegen.mir_emit_vec_filter(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let void_ty = wl_void_type(self.context)
    let recv = self.mir_intrinsic_recv_vec_value(body, args_id)
    let fn_val = self.mir_intrinsic_arg(body, args_id, 1)
    let cty = wl_type_of(fn_val)
    var fn_ptr = fn_val
    var ctx_ptr: i64 = 0
    var is_fat = 0
    if wl_get_type_kind(cty) == wl_struct_type_kind() and wl_count_struct_elem_types(cty) == 2:
        fn_ptr = wl_build_extract_value(self.builder, fn_val, 0)
        ctx_ptr = wl_build_extract_value(self.builder, fn_val, 1)
        is_fat = 1
    var elem_ty = i32_ty
    var fn_ty: i64 = 0
    if is_fat != 0:
        let fp: Vec[i64] = Vec.new()
        fp.push(ptr_ty)
        fp.push(elem_ty)
        fn_ty = wl_function_type(i32_ty, vec_data_i64(&fp), 2, 0)
    else:
        fn_ty = wl_global_get_value_type(fn_ptr)
    let len = wl_build_extract_value(self.builder, recv, 1)
    let vt = self.get_or_create_vec_type(0, elem_ty)
    let ra = self.create_entry_alloca(vt)
    wl_build_store(self.builder, self.build_default_value(vt), ra)
    let nf = self.ensure_vec_runtime_fn("with_vec_new_out", void_ty, 2)
    let nt = self.get_vec_fn_type("with_vec_new_out", void_ty, 2)
    let na: Vec[i64] = Vec.new()
    na.push(ra)
    na.push(wl_const_int(i64_ty, self.abi_size_of(elem_ty), 0))
    let _ = wl_build_call(self.builder, nt, nf, vec_data_i64(&na), 2)
    let sa = self.create_entry_alloca(wl_type_of(recv))
    wl_build_store(self.builder, recv, sa)
    let ctr = self.create_entry_alloca(i64_ty)
    wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), ctr)
    let tmp = self.create_entry_alloca(elem_ty)
    let cb = wl_append_bb(self.context, self.current_function, "f.c")
    let bb = wl_append_bb(self.context, self.current_function, "f.b")
    let pb = wl_append_bb(self.context, self.current_function, "f.p")
    let ib = wl_append_bb(self.context, self.current_function, "f.i")
    let eb = wl_append_bb(self.context, self.current_function, "f.e")
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, cb)
    let cv = wl_build_load(self.builder, i64_ty, ctr)
    wl_build_cond_br(self.builder, wl_build_icmp(self.builder, wl_int_slt(), cv, len), bb, eb)
    wl_position_at_end(self.builder, bb)
    let gf = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
    let gt = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
    let ga: Vec[i64] = Vec.new()
    ga.push(sa)
    ga.push(wl_build_load(self.builder, i64_ty, ctr))
    let ep = wl_build_call(self.builder, gt, gf, vec_data_i64(&ga), 2)
    let el = wl_build_load(self.builder, elem_ty, ep)
    let ca: Vec[i64] = Vec.new()
    if is_fat != 0: ca.push(ctx_ptr)
    ca.push(el)
    let cc = if is_fat != 0: 2 else: 1
    let pred = wl_build_call(self.builder, fn_ty, fn_ptr, vec_data_i64(&ca), cc)
    wl_build_cond_br(self.builder, wl_build_icmp(self.builder, wl_int_ne(), pred, wl_const_int(wl_type_of(pred), 0, 0)), pb, ib)
    wl_position_at_end(self.builder, pb)
    wl_build_store(self.builder, el, tmp)
    let pf = self.ensure_vec_runtime_fn("with_vec_push", void_ty, 2)
    let pt = self.get_vec_fn_type("with_vec_push", void_ty, 2)
    let pa: Vec[i64] = Vec.new()
    pa.push(ra)
    pa.push(tmp)
    let _ = wl_build_call(self.builder, pt, pf, vec_data_i64(&pa), 2)
    wl_build_br(self.builder, ib)
    wl_position_at_end(self.builder, ib)
    wl_build_store(self.builder, wl_build_add(self.builder, wl_build_load(self.builder, i64_ty, ctr), wl_const_int(i64_ty, 1, 0)), ctr)
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, eb)
    wl_build_load(self.builder, vt, ra)

fn Codegen.mir_emit_vec_contains(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i1_ty = wl_i1_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let recv = self.mir_intrinsic_recv_vec_value(body, args_id)
    let needle_raw = self.mir_intrinsic_arg(body, args_id, 1)
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let recv_op = body.call_arg_operands.get(arg_start as i64)
    var elem_ty = self.mir_vec_elem_type(body, recv_op)
    if elem_ty == 0:
        elem_ty = wl_type_of(needle_raw)
    if elem_ty == 0:
        elem_ty = i64_ty
    let needle = if wl_type_of(needle_raw) != elem_ty: self.coerce_value_to_type(needle_raw, elem_ty) else: needle_raw
    let len = wl_build_extract_value(self.builder, recv, 1)
    let sa = self.create_entry_alloca(wl_type_of(recv))
    wl_build_store(self.builder, recv, sa)
    let ctr = self.create_entry_alloca(i64_ty)
    wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), ctr)
    let found = self.create_entry_alloca(i1_ty)
    wl_build_store(self.builder, wl_const_int(i1_ty, 0, 0), found)
    let cb = wl_append_bb(self.context, self.current_function, "vc.c")
    let bb = wl_append_bb(self.context, self.current_function, "vc.b")
    let ib = wl_append_bb(self.context, self.current_function, "vc.i")
    let fb = wl_append_bb(self.context, self.current_function, "vc.f")
    let eb = wl_append_bb(self.context, self.current_function, "vc.e")
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, cb)
    let cv = wl_build_load(self.builder, i64_ty, ctr)
    wl_build_cond_br(self.builder, wl_build_icmp(self.builder, wl_int_slt(), cv, len), bb, eb)
    wl_position_at_end(self.builder, bb)
    let gf = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
    let gt = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
    let ga: Vec[i64] = Vec.new()
    ga.push(sa)
    ga.push(wl_build_load(self.builder, i64_ty, ctr))
    let ep = wl_build_call(self.builder, gt, gf, vec_data_i64(&ga), 2)
    let cur = wl_build_load(self.builder, elem_ty, ep)
    let eq = self.compare_value_eq(cur, needle, elem_ty, BinaryOp.OP_EQ)
    wl_build_cond_br(self.builder, eq, fb, ib)
    wl_position_at_end(self.builder, fb)
    wl_build_store(self.builder, wl_const_int(i1_ty, 1, 0), found)
    wl_build_br(self.builder, eb)
    wl_position_at_end(self.builder, ib)
    wl_build_store(self.builder, wl_build_add(self.builder, wl_build_load(self.builder, i64_ty, ctr), wl_const_int(i64_ty, 1, 0)), ctr)
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, eb)
    wl_build_load(self.builder, i1_ty, found)

fn Codegen.mir_emit_vec_fold(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let recv = self.mir_intrinsic_recv_vec_value(body, args_id)
    let init = self.mir_intrinsic_arg(body, args_id, 1)
    let fn_val = self.mir_intrinsic_arg(body, args_id, 2)
    let cty = wl_type_of(fn_val)
    var fn_ptr = fn_val
    var ctx_ptr: i64 = 0
    var is_fat = 0
    if wl_get_type_kind(cty) == wl_struct_type_kind() and wl_count_struct_elem_types(cty) == 2:
        fn_ptr = wl_build_extract_value(self.builder, fn_val, 0)
        ctx_ptr = wl_build_extract_value(self.builder, fn_val, 1)
        is_fat = 1
    var fn_ty: i64 = 0
    if is_fat != 0:
        // Fat pointer closure: fn(ptr, acc, elem) -> i32
        let fp: Vec[i64] = Vec.new()
        fp.push(ptr_ty)
        fp.push(i32_ty)
        fp.push(i32_ty)
        fn_ty = wl_function_type(i32_ty, vec_data_i64(&fp), 3, 0)
    else:
        fn_ty = wl_global_get_value_type(fn_ptr)
    let at = wl_type_of(init)
    var elem_ty = i32_ty
    let len = wl_build_extract_value(self.builder, recv, 1)
    let sa = self.create_entry_alloca(wl_type_of(recv))
    wl_build_store(self.builder, recv, sa)
    let aa = self.create_entry_alloca(at)
    wl_build_store(self.builder, init, aa)
    let ctr = self.create_entry_alloca(i64_ty)
    wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), ctr)
    let cb = wl_append_bb(self.context, self.current_function, "o.c")
    let bb = wl_append_bb(self.context, self.current_function, "o.b")
    let ib = wl_append_bb(self.context, self.current_function, "o.i")
    let eb = wl_append_bb(self.context, self.current_function, "o.e")
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, cb)
    let cv = wl_build_load(self.builder, i64_ty, ctr)
    wl_build_cond_br(self.builder, wl_build_icmp(self.builder, wl_int_slt(), cv, len), bb, eb)
    wl_position_at_end(self.builder, bb)
    let gf = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
    let gt = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
    let ga: Vec[i64] = Vec.new()
    ga.push(sa)
    ga.push(wl_build_load(self.builder, i64_ty, ctr))
    let ep = wl_build_call(self.builder, gt, gf, vec_data_i64(&ga), 2)
    let el = wl_build_load(self.builder, elem_ty, ep)
    let ca_val = wl_build_load(self.builder, at, aa)
    let ca: Vec[i64] = Vec.new()
    if is_fat != 0: ca.push(ctx_ptr)
    ca.push(ca_val)
    ca.push(el)
    let cc = if is_fat != 0: 3 else: 2
    let nv = wl_build_call(self.builder, fn_ty, fn_ptr, vec_data_i64(&ca), cc)
    wl_build_store(self.builder, nv, aa)
    wl_build_br(self.builder, ib)
    wl_position_at_end(self.builder, ib)
    wl_build_store(self.builder, wl_build_add(self.builder, wl_build_load(self.builder, i64_ty, ctr), wl_const_int(i64_ty, 1, 0)), ctr)
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, eb)
    wl_build_load(self.builder, at, aa)

fn Codegen.mir_emit_call_term(self: Codegen, body: MirBody, callee_operand: i32, args_id: i32, dest_place: i32, next_bb: i32) -> bool:
    // Check for intrinsic-tagged calls (Vec/HashMap/Option builtins).
    // These have meaningless ConstKind.CK_FN syms — dispatch by intrinsic kind instead.
    let mir_intrinsic = body.call_intrinsic(args_id)
    if self.debug_mir_codegen_enabled():
        with_eprint(f"[mir-call-pre] intrinsic={mir_intrinsic} callee_op={callee_operand} args_id={args_id} dest={dest_place}")
    if mir_intrinsic == MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL:
        let gc_node = body.call_ast_node(args_id)
        if gc_node > 0:
            // Extract callee sym from ConstKind.CK_FN constant
            let gc_co_k = body.operand_kinds.get(callee_operand as i64)
            let gc_co_d = body.operand_d0.get(callee_operand as i64)
            var gc_callee_sym = 0
            if gc_co_k == OperandKind.OK_CONSTANT and gc_co_d >= 0 and gc_co_d < body.const_kinds.len() as i32:
                gc_callee_sym = body.const_d0.get(gc_co_d as i64)

            // Generic function call — eval MIR args, call monomorphize directly
            let gc_gf = self.generic_fns.get(gc_callee_sym)
            if gc_gf.is_some() and gc_callee_sym > 0:
                let gc_mir_start = body.call_arg_starts.get(args_id as i64)
                let gc_mir_count = body.call_arg_counts.get(args_id as i64)
                let gc_as = self.pool.get_data1(gc_node)
                let gc_arg_vals: Vec[i64] = Vec.new()
                let gc_arg_tys: Vec[i64] = Vec.new()
                let gc_arg_nodes: Vec[i32] = Vec.new()
                for gc_ai in 0..gc_mir_count:
                    let gc_arg_nd = self.pool.get_extra(gc_as + gc_ai)
                    gc_arg_nodes.push(gc_arg_nd)
                    let gc_op = body.call_arg_operands.get((gc_mir_start + gc_ai) as i64)
                    let gc_val = self.mir_eval_operand(body, gc_op, 0)
                    gc_arg_vals.push(gc_val)
                    gc_arg_tys.push(wl_type_of(gc_val))
                let gc_result = self.monomorphize_generic_call_core(gc_callee_sym, gc_gf.unwrap(), gc_as, gc_mir_count, gc_node, gc_arg_vals, gc_arg_tys, gc_arg_nodes)
                if dest_place >= 0 and gc_result != 0:
                    let gc_ret_ty = wl_type_of(gc_result)
                    if gc_ret_ty != wl_void_type(self.context):
                        let gc_local = body.place_locals.get(dest_place as i64)
                        let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                        wl_build_store(self.builder, gc_result, gc_alloca)
                        self.mir_local_ptrs.insert(gc_local, gc_alloca)
                        self.mir_local_types.insert(gc_local, gc_ret_ty)
                if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                    let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                    wl_build_br(self.builder, gc_next_val)
                return true

            // Handle builtins directly (no gen_expr needed)
            if gc_callee_sym > 0:
                let gc_arg_count = self.pool.get_data2(gc_node)
                if gc_callee_sym == self.sym_todo or gc_callee_sym == self.sym_unreachable:
                    let _ = wl_build_unreachable(self.builder)
                    return true
                if gc_callee_sym == self.sym_src and gc_arg_count == 0:
                    let gc_result = self.gen_src_intrinsic(gc_node)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true
                if gc_callee_sym == self.sym_transmute:
                    let gc_result = self.gen_transmute(gc_node, body, args_id)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true
                if gc_callee_sym == self.sym_sizeof or gc_callee_sym == self.sym_size_of or gc_callee_sym == self.sym_alignof or gc_callee_sym == self.sym_align_of:
                    let gc_result = self.gen_sizeof_alignof(gc_callee_sym, gc_node)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true
                if gc_callee_sym == self.sym_nameof or gc_callee_sym == self.sym_type_name:
                    let gc_result = self.gen_nameof(gc_node)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true
                if gc_callee_sym == self.sym_embed_file and gc_arg_count == 1:
                    let gc_result = self.gen_embed_file(gc_node)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true

                // chan[T](capacity) → (Sender[T], Receiver[T])
                if gc_callee_sym == self.sym_chan:
                    self.ensure_async_runtime_declared()
                    // Extract element type from generic call's type argument
                    var chan_elem_size: i64 = 4  // default for i32
                    let chan_gc_node = gc_node
                    let chan_type_args_node = self.pool.get_data0(chan_gc_node)
                    if chan_type_args_node > 0:
                        let chan_ta_kind = self.pool.kind(chan_type_args_node)
                        if chan_ta_kind == NodeKind.NK_INDEX:
                            let chan_type_node = self.pool.get_data1(chan_type_args_node)
                            if chan_type_node > 0:
                                let chan_type_llvm = self.resolve_type(chan_type_node)
                                if chan_type_llvm != 0:
                                    chan_elem_size = self.abi_size_of(chan_type_llvm)
                    // Also try sema typed_expr_types for the call node
                    let chan_dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
                    if chan_dest_sema > 0:
                        let chan_resolved = self.mir_input.mir_resolve_alias(chan_dest_sema)
                        if self.mir_input.mir_get_type_kind(chan_resolved) == TypeKind.TY_TUPLE:
                            let chan_tc = self.mir_input.mir_get_type_d2(chan_resolved)
                            if chan_tc > 0:
                                let chan_ts = self.mir_input.mir_get_type_d1(chan_resolved)
                                let chan_elem_tid = self.mir_input.mir_get_type_extra(chan_ts)
                                if chan_elem_tid > 0:
                                    // This is Sender[T] — extract T
                                    let chan_sender_resolved = self.mir_input.mir_resolve_alias(chan_elem_tid)
                                    if self.mir_input.mir_get_type_kind(chan_sender_resolved) == TypeKind.TY_GENERIC_INST:
                                        let chan_gi_argc = self.mir_input.mir_get_type_d2(chan_sender_resolved)
                                        if chan_gi_argc > 0:
                                            let chan_gi_start = self.mir_input.mir_get_type_d1(chan_sender_resolved)
                                            let chan_t_tid = self.mir_input.mir_get_type_extra(chan_gi_start)
                                            if chan_t_tid > 0:
                                                let chan_t_llvm = self.mir_sema_type_to_llvm(chan_t_tid)
                                                if chan_t_llvm != 0:
                                                    chan_elem_size = self.abi_size_of(chan_t_llvm)
                    // Get capacity argument
                    let chan_cap_val = self.mir_intrinsic_arg(body, args_id, 0)
                    // Call with_channel_create(capacity, elem_size)
                    var chan_create_fn = wl_get_named_function(self.llmod, "with_channel_create")
                    if chan_create_fn == 0:
                        let ccp: Vec[i64] = Vec.new()
                        ccp.push(wl_i32_type(self.context))
                        ccp.push(wl_i32_type(self.context))
                        let ccft = wl_function_type(wl_i64_type(self.context), vec_data_i64(&ccp), 2, 0)
                        chan_create_fn = wl_add_function(self.llmod, "with_channel_create", ccft)
                    let ccft2 = wl_global_get_value_type(chan_create_fn)
                    let cca: Vec[i64] = Vec.new()
                    cca.push(chan_cap_val)
                    cca.push(wl_const_int(wl_i32_type(self.context), chan_elem_size, 0))
                    let chan_handle = wl_build_call(self.builder, ccft2, chan_create_fn, vec_data_i64(&cca), 2)
                    // Construct tuple (Sender{handle}, Receiver{handle})
                    // Sender = { i64 }, Receiver = { i64 }
                    // Tuple = { {i64}, {i64} }
                    let chan_inner_fields: Vec[i64] = Vec.new()
                    chan_inner_fields.push(wl_i64_type(self.context))
                    let chan_sender_ty = wl_struct_type(self.context, vec_data_i64(&chan_inner_fields), 1, 0)
                    let chan_receiver_ty = chan_sender_ty  // same layout
                    let chan_tuple_fields: Vec[i64] = Vec.new()
                    chan_tuple_fields.push(chan_sender_ty)
                    chan_tuple_fields.push(chan_receiver_ty)
                    let chan_tuple_ty = wl_struct_type(self.context, vec_data_i64(&chan_tuple_fields), 2, 0)
                    // Build sender = { handle }
                    var chan_sender_val = wl_get_undef(chan_sender_ty)
                    chan_sender_val = wl_build_insert_value(self.builder, chan_sender_val, chan_handle, 0)
                    // Build receiver = { handle }
                    var chan_receiver_val = wl_get_undef(chan_receiver_ty)
                    chan_receiver_val = wl_build_insert_value(self.builder, chan_receiver_val, chan_handle, 0)
                    // Build tuple = { sender, receiver }
                    var chan_tuple_val = wl_get_undef(chan_tuple_ty)
                    chan_tuple_val = wl_build_insert_value(self.builder, chan_tuple_val, chan_sender_val, 0)
                    chan_tuple_val = wl_build_insert_value(self.builder, chan_tuple_val, chan_receiver_val, 1)
                    if dest_place >= 0:
                        let chan_local = body.place_locals.get(dest_place as i64)
                        let chan_alloca = self.create_entry_alloca(chan_tuple_ty)
                        wl_build_store(self.builder, chan_tuple_val, chan_alloca)
                        self.mir_local_ptrs.insert(chan_local, chan_alloca)
                        self.mir_local_types.insert(chan_local, chan_tuple_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                    return true

                // Channel builtins: Channel(cap), send(ch, val), recv(ch), close(ch)
                if gc_callee_sym == self.sym_channel:
                    self.ensure_async_runtime_declared()
                    let ch_fn = wl_get_named_function(self.llmod, "with_channel_create")
                    if ch_fn != 0 and gc_arg_count >= 1:
                        let gc_mir_s = body.call_arg_starts.get(args_id as i64)
                        let cap_op = body.call_arg_operands.get(gc_mir_s as i64)
                        let cap_val = self.mir_eval_operand(body, cap_op, wl_i32_type(self.context))
                        let ch_args: Vec[i64] = Vec.new()
                        ch_args.push(self.coerce_int(cap_val, wl_i32_type(self.context)))
                        let ch_result = wl_build_call(self.builder, wl_global_get_value_type(ch_fn), ch_fn, vec_data_i64(&ch_args), 1)
                        if dest_place >= 0:
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(wl_type_of(ch_result))
                            wl_build_store(self.builder, ch_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, wl_type_of(ch_result))
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                    return true
                if gc_callee_sym == self.sym_send and gc_arg_count >= 2:
                    self.ensure_async_runtime_declared()
                    let send_fn = wl_get_named_function(self.llmod, "with_channel_send")
                    if send_fn != 0:
                        let gc_mir_s = body.call_arg_starts.get(args_id as i64)
                        let ch_op = body.call_arg_operands.get(gc_mir_s as i64)
                        let val_op = body.call_arg_operands.get((gc_mir_s + 1) as i64)
                        let ch_val = self.mir_eval_operand(body, ch_op, wl_ptr_type(self.context))
                        let send_val = self.mir_eval_operand(body, val_op, wl_i64_type(self.context))
                        let send_args: Vec[i64] = Vec.new()
                        send_args.push(ch_val)
                        send_args.push(self.coerce_int(send_val, wl_i64_type(self.context)))
                        let _ = wl_build_call(self.builder, wl_global_get_value_type(send_fn), send_fn, vec_data_i64(&send_args), 2)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                    return true
                if gc_callee_sym == self.sym_recv and gc_arg_count >= 1:
                    self.ensure_async_runtime_declared()
                    let recv_fn = wl_get_named_function(self.llmod, "with_channel_recv")
                    if recv_fn != 0:
                        let gc_mir_s = body.call_arg_starts.get(args_id as i64)
                        let ch_op = body.call_arg_operands.get(gc_mir_s as i64)
                        let ch_val = self.mir_eval_operand(body, ch_op, wl_ptr_type(self.context))
                        let recv_args: Vec[i64] = Vec.new()
                        recv_args.push(ch_val)
                        let gc_result = wl_build_call(self.builder, wl_global_get_value_type(recv_fn), recv_fn, vec_data_i64(&recv_args), 1)
                        if dest_place >= 0:
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(wl_i64_type(self.context))
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, wl_i64_type(self.context))
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                    return true
                if gc_callee_sym == self.sym_close and gc_arg_count >= 1:
                    self.ensure_async_runtime_declared()
                    let close_fn = wl_get_named_function(self.llmod, "with_channel_close")
                    if close_fn != 0:
                        let gc_mir_s = body.call_arg_starts.get(args_id as i64)
                        let ch_op = body.call_arg_operands.get(gc_mir_s as i64)
                        let ch_val = self.mir_eval_operand(body, ch_op, wl_ptr_type(self.context))
                        let close_args: Vec[i64] = Vec.new()
                        close_args.push(ch_val)
                        let _ = wl_build_call(self.builder, wl_global_get_value_type(close_fn), close_fn, vec_data_i64(&close_args), 1)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                    return true

            let gc_callee_field = self.pool.get_data0(gc_node)

            // Static generic struct methods: Cell.wrap(v) needs the concrete
            // owner instantiation before its signature can be lowered.
            if self.pool.kind(gc_callee_field) == NodeKind.NK_FIELD_ACCESS:
                let gc_static_self = self.pool.get_data0(gc_callee_field)
                let gc_static_method_sym = self.pool.get_data1(gc_callee_field)
                var gc_static_owner_sym = 0
                let gc_static_self_kind = self.pool.kind(gc_static_self)
                if gc_static_self_kind == NodeKind.NK_IDENT or gc_static_self_kind == NodeKind.NK_TYPE_NAMED:
                    gc_static_owner_sym = self.pool.get_data0(gc_static_self)
                else if gc_static_self_kind == NodeKind.NK_INDEX or gc_static_self_kind == NodeKind.NK_TYPE_GENERIC:
                    let gc_static_base = self.pool.get_data0(gc_static_self)
                    let gc_static_base_kind = self.pool.kind(gc_static_base)
                    if gc_static_base_kind == NodeKind.NK_IDENT or gc_static_base_kind == NodeKind.NK_TYPE_NAMED:
                        gc_static_owner_sym = self.pool.get_data0(gc_static_base)
                if gc_static_owner_sym != 0 and self.generic_structs.contains(gc_static_owner_sym):
                    let gc_static_owner_name = self.intern.resolve(gc_static_owner_sym)
                    let gc_static_method_name = self.intern.resolve(gc_static_method_sym)
                    let gc_static_qualified = gc_static_owner_name ++ "." ++ gc_static_method_name
                    let gc_static_fn_sym = self.intern.intern(gc_static_qualified)
                    let gc_static_decl = self.generic_struct_methods.get(gc_static_fn_sym)
                    if gc_static_decl.is_some():
                        let gc_static_mir_start = body.call_arg_starts.get(args_id as i64)
                        let gc_static_mir_count = body.call_arg_counts.get(args_id as i64)
                        let gc_static_call_args_start = self.pool.get_data1(gc_node)
                        let gc_static_args: Vec[i64] = Vec.new()
                        let gc_static_arg_tys: Vec[i64] = Vec.new()
                        let gc_static_arg_nodes: Vec[i32] = Vec.new()
                        for gc_static_ai in 0..gc_static_mir_count:
                            let gc_static_arg_node = self.pool.get_extra(gc_static_call_args_start + gc_static_ai)
                            let gc_static_op = body.call_arg_operands.get((gc_static_mir_start + gc_static_ai) as i64)
                            let gc_static_val = self.mir_eval_operand(body, gc_static_op, 0)
                            gc_static_arg_nodes.push(gc_static_arg_node)
                            gc_static_args.push(gc_static_val)
                            gc_static_arg_tys.push(wl_type_of(gc_static_val))
                        var gc_static_mono_sym = 0
                        if dest_place >= 0 and dest_place < body.place_locals.len() as i32:
                            let gc_static_local_id = body.place_locals.get(dest_place as i64)
                            if gc_static_local_id >= 0 and gc_static_local_id < body.local_type_ids.len() as i32:
                                gc_static_mono_sym = self.mir_struct_sym_from_sema_type(body.local_type_ids.get(gc_static_local_id as i64))
                        var gc_static_llvm_ty = self.mir_dest_llvm_type(body, dest_place)
                        var gc_static_call_type = self.ast_static_type_expr(gc_node)
                        if gc_static_call_type == 0:
                            gc_static_call_type = self.ast_static_type_expr(gc_static_self)
                        if gc_static_mono_sym == 0 and gc_static_call_type > 0:
                            gc_static_mono_sym = self.mir_struct_sym_from_sema_type(gc_static_call_type)
                        if gc_static_mono_sym == 0:
                            gc_static_mono_sym = self.infer_static_generic_struct_mono_sym(gc_static_owner_sym, gc_static_decl.unwrap(), gc_static_self, gc_static_arg_tys, gc_static_arg_nodes, gc_static_call_type)
                        if gc_static_llvm_ty == 0 and gc_static_call_type > 0:
                            gc_static_llvm_ty = self.sema_type_to_llvm(gc_static_call_type)
                        if gc_static_mono_sym == 0 and gc_static_llvm_ty != 0:
                            gc_static_mono_sym = self.find_struct_type_by_llvm(gc_static_llvm_ty)
                        if gc_static_mono_sym != 0:
                            let gc_static_result = self.monomorphize_struct_static_method_core(gc_static_mono_sym, gc_static_method_name, gc_static_decl.unwrap(), gc_static_call_args_start, gc_static_mir_count, gc_node, gc_static_args)
                            if dest_place >= 0 and gc_static_result != 0:
                                let gc_static_ret_ty = wl_type_of(gc_static_result)
                                if gc_static_ret_ty != wl_void_type(self.context):
                                    let gc_static_local = body.place_locals.get(dest_place as i64)
                                    let gc_static_alloca = self.create_entry_alloca(gc_static_ret_ty)
                                    wl_build_store(self.builder, gc_static_result, gc_static_alloca)
                                    self.mir_local_ptrs.insert(gc_static_local, gc_static_alloca)
                                    self.mir_local_types.insert(gc_static_local, gc_static_ret_ty)
                            if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                                let gc_static_next_val = self.mir_bb_values.get(next_bb as i64)
                                wl_build_br(self.builder, gc_static_next_val)
                            return true

            // Try method call dispatch for generic struct methods
            if self.pool.kind(gc_callee_field) == NodeKind.NK_FIELD_ACCESS:
                let gc_self_expr_node = self.pool.get_data0(gc_callee_field)
                let gc_method_sym = self.pool.get_data1(gc_callee_field)
                let gc_mir_start = body.call_arg_starts.get(args_id as i64)
                let gc_mir_count = body.call_arg_counts.get(args_id as i64)
                var gc_recv_type = self.ast_static_type_expr(gc_self_expr_node)
                if gc_recv_type == 0 and gc_mir_count > 0:
                    let gc_recv_op = body.call_arg_operands.get(gc_mir_start as i64)
                    gc_recv_type = self.mir_operand_sema_type(body, gc_recv_op)
                // Unwrap reference/pointer to get the underlying type for dispatch.
                // When the receiver is &mut Vec[T], we need to dispatch on Vec[T].
                var gc_recv_type_unwrapped = gc_recv_type
                if gc_recv_type_unwrapped > 0:
                    let gc_recv_tk = self.mir_input.mir_get_type_kind(self.mir_input.mir_resolve_alias(gc_recv_type_unwrapped))
                    if gc_recv_tk == TypeKind.TY_REF or gc_recv_tk == TypeKind.TY_PTR:
                        gc_recv_type_unwrapped = self.mir_input.mir_get_type_d0(self.mir_input.mir_resolve_alias(gc_recv_type_unwrapped))
                let gc_intrinsic = self.classify_generic_call_intrinsic(gc_recv_type_unwrapped, gc_method_sym)
                if gc_intrinsic != MirIntrinsic.MIR_INTRINSIC_NONE:
                    return self.mir_emit_intrinsic_call(body, gc_intrinsic, args_id, dest_place, next_bb)
                let gc_method_name = self.intern.resolve(gc_method_sym)
                // Eval receiver from MIR operand 0
                if gc_mir_count > 0:
                    let gc_recv_op = body.call_arg_operands.get(gc_mir_start as i64)
                    let gc_recv_val = self.mir_eval_operand(body, gc_recv_op, 0)
                    let gc_recv_ty = wl_type_of(gc_recv_val)
                    let gc_llvm_intrinsic = self.classify_generic_call_intrinsic_by_llvm(gc_recv_ty, gc_method_sym)
                    if gc_llvm_intrinsic != MirIntrinsic.MIR_INTRINSIC_NONE:
                        return self.mir_emit_intrinsic_call(body, gc_llvm_intrinsic, args_id, dest_place, next_bb)
                    var gc_recv_type_sym = self.mir_struct_sym_from_sema_type(gc_recv_type_unwrapped)
                    if gc_recv_type_sym == 0:
                        gc_recv_type_sym = self.find_struct_type_by_llvm(gc_recv_ty)
                    // Generic struct method: receiver is monomorphized generic struct
                    let gc_base_opt = self.mono_struct_base.get(gc_recv_type_sym)
                    if gc_base_opt.is_some():
                        let gc_base_sym = gc_base_opt.unwrap()
                        let gc_base_name = self.intern.resolve(gc_base_sym)
                        let gc_qualified = gc_base_name ++ "." ++ gc_method_name
                        let gc_fn_sym_early = self.intern.intern(gc_qualified)
                        let gc_gsm = self.generic_struct_methods.get(gc_fn_sym_early)
                        // Build pre-evaluated args (method args only, not self)
                        let gc_call_args_start = self.pool.get_data1(gc_node)
                        let gc_method_arg_count = gc_mir_count - 1
                        let gc_pre_args: Vec[i64] = Vec.new()
                        for gc_mai in 0..gc_method_arg_count:
                            let gc_ma_op = body.call_arg_operands.get((gc_mir_start + 1 + gc_mai) as i64)
                            gc_pre_args.push(self.mir_eval_operand(body, gc_ma_op, 0))
                        if gc_gsm.is_some():
                            let gc_result = self.monomorphize_struct_method_core(gc_recv_type_sym, gc_method_name, gc_gsm.unwrap(), gc_recv_val, gc_self_expr_node, gc_recv_ty, gc_call_args_start, gc_method_arg_count, gc_node, gc_pre_args)
                            if dest_place >= 0 and gc_result != 0:
                                let gc_ret_ty = wl_type_of(gc_result)
                                if gc_ret_ty != wl_void_type(self.context):
                                    let gc_local = body.place_locals.get(dest_place as i64)
                                    let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                    wl_build_store(self.builder, gc_result, gc_alloca)
                                    self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                    self.mir_local_types.insert(gc_local, gc_ret_ty)
                            if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                                let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                                wl_build_br(self.builder, gc_next_val)
                            return true
                        // Direct method on base struct (non-generic method on generic struct)
                        let gc_direct_fv = self.fn_values.get(gc_fn_sym_early)
                        let gc_direct_ft = self.fn_fn_types.get(gc_fn_sym_early)
                        if gc_direct_fv.is_some() and gc_direct_ft.is_some():
                            let gc_call_args: Vec[i64] = Vec.new()
                            let gc_is_ref = self.fn_ref_param_starts.get(gc_fn_sym_early).is_some()
                            if gc_is_ref:
                                gc_call_args.push(self.get_mutable_receiver_ptr(gc_self_expr_node, gc_recv_val, gc_recv_ty))
                            else:
                                gc_call_args.push(gc_recv_val)
                            for gc_dai in 0..gc_method_arg_count:
                                gc_call_args.push(gc_pre_args.get(gc_dai as i64))
                            let gc_coerced = self.coerce_call_args_for_fn_value(gc_fn_sym_early, gc_direct_fv.unwrap() as i64, gc_call_args_start, 1, gc_call_args, gc_method_arg_count + 1, "method " ++ gc_qualified, gc_node)
                            let gc_result = wl_build_call(self.builder, gc_direct_ft.unwrap() as i64, gc_direct_fv.unwrap() as i64, vec_data_i64(&gc_coerced), gc_method_arg_count + 1)
                            if dest_place >= 0 and gc_result != 0:
                                let gc_ret_ty = wl_type_of(gc_result)
                                if gc_ret_ty != wl_void_type(self.context):
                                    let gc_local = body.place_locals.get(dest_place as i64)
                                    let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                    wl_build_store(self.builder, gc_result, gc_alloca)
                                    self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                    self.mir_local_types.insert(gc_local, gc_ret_ty)
                            if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                                let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                                wl_build_br(self.builder, gc_next_val)
                            return true

            // Disc enum static methods: Direction.from_int(n)
            if self.pool.kind(gc_callee_field) == NodeKind.NK_FIELD_ACCESS:
                let gc_de_self = self.pool.get_data0(gc_callee_field)
                let gc_de_method_sym = self.pool.get_data1(gc_callee_field)
                if gc_de_method_sym == self.sym_from_int and self.pool.kind(gc_de_self) == NodeKind.NK_IDENT:
                    let gc_de_type_sym = self.pool.get_data0(gc_de_self)
                    let gc_de_opt = self.disc_enum_type_map.get(gc_de_type_sym)
                    if gc_de_opt.is_some():
                        let gc_de_mir_start = body.call_arg_starts.get(args_id as i64)
                        let gc_de_mir_count = body.call_arg_counts.get(args_id as i64)
                        if gc_de_mir_count > 0:
                            let gc_de_arg_op = body.call_arg_operands.get(gc_de_mir_start as i64)
                            let gc_de_arg_val = self.mir_eval_operand(body, gc_de_arg_op, 0)
                            let gc_result = self.gen_disc_enum_from_int_val(gc_de_opt.unwrap(), gc_de_arg_val)
                            if dest_place >= 0 and gc_result != 0:
                                let gc_ret_ty = wl_type_of(gc_result)
                                if gc_ret_ty != wl_void_type(self.context):
                                    let gc_local = body.place_locals.get(dest_place as i64)
                                    let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                    wl_build_store(self.builder, gc_result, gc_alloca)
                                    self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                    self.mir_local_types.insert(gc_local, gc_ret_ty)
                            if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                                let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                                wl_build_br(self.builder, gc_next_val)
                            return true

            // Disc enum variant constructor with payload: Msg.Move(10, 20)
            if self.pool.kind(gc_callee_field) == NodeKind.NK_FIELD_ACCESS:
                let gc_vc_self = self.pool.get_data0(gc_callee_field)
                let gc_vc_variant_sym = self.pool.get_data1(gc_callee_field)
                if self.pool.kind(gc_vc_self) == NodeKind.NK_IDENT:
                    let gc_vc_type_sym = self.pool.get_data0(gc_vc_self)
                    var gc_vc_is_enum = false
                    let gc_vc_de_opt = self.disc_enum_type_map.get(gc_vc_type_sym)
                    if gc_vc_de_opt.is_some():
                        let gc_vc_de_idx = gc_vc_de_opt.unwrap()
                        let gc_vc_hp = self.disc_enum_has_payload.get(gc_vc_de_idx as i64)
                        if gc_vc_hp != 0:
                            gc_vc_is_enum = true
                    if not gc_vc_is_enum:
                        let gc_vc_e_opt = self.enum_type_map.get(gc_vc_type_sym)
                        if gc_vc_e_opt.is_some():
                            gc_vc_is_enum = true
                    if gc_vc_is_enum:
                        let gc_vc_mir_start = body.call_arg_starts.get(args_id as i64)
                        let gc_vc_mir_count = body.call_arg_counts.get(args_id as i64)
                        let gc_vc_args: Vec[i64] = Vec.new()
                        for gc_vc_i in 0..gc_vc_mir_count:
                            let gc_vc_op = body.call_arg_operands.get((gc_vc_mir_start + gc_vc_i) as i64)
                            gc_vc_args.push(self.mir_eval_operand(body, gc_vc_op, 0))
                        let gc_result = self.gen_enum_variant_call_val(gc_vc_type_sym, gc_vc_variant_sym, gc_vc_args, gc_vc_mir_count)
                        if dest_place >= 0 and gc_result != 0:
                            let gc_ret_ty = wl_type_of(gc_result)
                            if gc_ret_ty != wl_void_type(self.context):
                                let gc_local = body.place_locals.get(dest_place as i64)
                                let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                wl_build_store(self.builder, gc_result, gc_alloca)
                                self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                self.mir_local_types.insert(gc_local, gc_ret_ty)
                        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                            let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                            wl_build_br(self.builder, gc_next_val)
                        return true

            // Fallback: trait method call on concrete type (e.g. self.show() in blanket impl)
            if self.pool.kind(gc_callee_field) == NodeKind.NK_FIELD_ACCESS:
                let gc_fb_method_sym = self.pool.get_data1(gc_callee_field)
                let gc_fb_method = self.intern.resolve(gc_fb_method_sym)
                let gc_fb_mir_start = body.call_arg_starts.get(args_id as i64)
                let gc_fb_mir_count = body.call_arg_counts.get(args_id as i64)
                // Try qualified name lookups: OwnerType.method, then TraitName.method
                var gc_fb_fn_sym = 0
                let gc_fb_recv = self.pool.get_data0(gc_callee_field)
                let gc_fb_is_direct_self =
                    self.pool.kind(gc_fb_recv) == NodeKind.NK_IDENT and self.pool.get_data0(gc_fb_recv) == self.sym_self
                if self.current_method_owner_sym != 0 and gc_fb_is_direct_self:
                    let gc_fb_owner = self.intern.resolve(self.current_method_owner_sym)
                    let gc_fb_q1 = gc_fb_owner ++ "." ++ gc_fb_method
                    gc_fb_fn_sym = self.intern.intern(gc_fb_q1)
                    if not self.fn_values.get(gc_fb_fn_sym).is_some():
                        gc_fb_fn_sym = 0
                // Search all traits for a method with this name
                if gc_fb_fn_sym == 0:
                    for gc_fb_ti in 0..self.trait_idx_syms.len() as i32:
                        let gc_fb_t_sym = self.trait_idx_syms.get(gc_fb_ti as i64)
                        let gc_fb_m_start = self.trait_method_starts.get(gc_fb_ti as i64)
                        let gc_fb_m_count = self.trait_method_counts.get(gc_fb_ti as i64)
                        for gc_fb_mi in 0..gc_fb_m_count:
                            let gc_fb_m_name = self.trait_method_names.get((gc_fb_m_start + gc_fb_mi) as i64)
                            if gc_fb_m_name == gc_fb_method_sym:
                                let gc_fb_t_name = self.intern.resolve(gc_fb_t_sym)
                                let gc_fb_q2 = gc_fb_t_name ++ "." ++ gc_fb_method
                                let gc_fb_try_sym = self.intern.intern(gc_fb_q2)
                                if self.fn_values.get(gc_fb_try_sym).is_some():
                                    gc_fb_fn_sym = gc_fb_try_sym
                if gc_fb_fn_sym != 0 and gc_fb_mir_count > 0:
                    let gc_fb_fv = self.fn_values.get(gc_fb_fn_sym)
                    let gc_fb_ft = self.fn_fn_types.get(gc_fb_fn_sym)
                    if gc_fb_fv.is_some() and gc_fb_ft.is_some():
                        let gc_fb_is_ref = self.fn_ref_param_starts.get(gc_fb_fn_sym).is_some()
                        let gc_fb_args: Vec[i64] = Vec.new()
                        for gc_fb_i in 0..gc_fb_mir_count:
                            let gc_fb_op = body.call_arg_operands.get((gc_fb_mir_start + gc_fb_i) as i64)
                            if gc_fb_i == 0 and gc_fb_is_ref:
                                let gc_fb_ref_ptr = self.mir_try_place_ptr_for_ref(body, gc_fb_op)
                                if gc_fb_ref_ptr != 0:
                                    gc_fb_args.push(gc_fb_ref_ptr)
                                    continue
                            let gc_fb_val = self.mir_eval_operand(body, gc_fb_op, 0)
                            if gc_fb_i == 0 and gc_fb_is_ref:
                                if wl_get_type_kind(wl_type_of(gc_fb_val)) != wl_pointer_type_kind():
                                    let gc_fb_alloca = self.create_entry_alloca(wl_type_of(gc_fb_val))
                                    wl_build_store(self.builder, gc_fb_val, gc_fb_alloca)
                                    gc_fb_args.push(gc_fb_alloca)
                                    continue
                            gc_fb_args.push(gc_fb_val)
                        let gc_result = wl_build_call(self.builder, gc_fb_ft.unwrap() as i64, gc_fb_fv.unwrap() as i64, vec_data_i64(&gc_fb_args), gc_fb_mir_count)
                        if dest_place >= 0 and gc_result != 0:
                            let gc_ret_ty = wl_type_of(gc_result)
                            if gc_ret_ty != wl_void_type(self.context):
                                let gc_local = body.place_locals.get(dest_place as i64)
                                let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                wl_build_store(self.builder, gc_result, gc_alloca)
                                self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                self.mir_local_types.insert(gc_local, gc_ret_ty)
                        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                            let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                            wl_build_br(self.builder, gc_next_val)
                        return true

            // async scope s.track(task_expr) — register task with scope
            let gc_name = if gc_callee_sym > 0: self.intern.resolve(gc_callee_sym) else: "?"
            if gc_name == "track":
                let gc_mir_start2 = body.call_arg_starts.get(args_id as i64)
                let gc_mir_count2 = body.call_arg_counts.get(args_id as i64)
                if gc_mir_count2 > 1:
                    // Evaluate receiver (scope handle) and argument (Task value)
                    let gc_recv_op = body.call_arg_operands.get(gc_mir_start2 as i64)
                    let gc_recv_val = self.mir_eval_operand(body, gc_recv_op, 0)
                    let gc_arg_op = body.call_arg_operands.get((gc_mir_start2 + gc_mir_count2 - 1) as i64)
                    let gc_arg_val = self.mir_eval_operand(body, gc_arg_op, 0)
                    // Extract fiber_id from Task { i32, ptr }
                    let gc_task_ty = wl_type_of(gc_arg_val)
                    let gc_task_alloca = self.create_entry_alloca(gc_task_ty)
                    wl_build_store(self.builder, gc_arg_val, gc_task_alloca)
                    let gc_fid_ptr = wl_build_struct_gep(self.builder, gc_task_ty, gc_task_alloca, 0)
                    let gc_fid = wl_build_load(self.builder, wl_i32_type(self.context), gc_fid_ptr)
                    // Call with_scope_track(scope_handle, fiber_id)
                    var gc_track_fn = wl_get_named_function(self.llmod, "with_scope_track")
                    if gc_track_fn == 0:
                        let gtp: Vec[i64] = Vec.new()
                        gtp.push(wl_i64_type(self.context))
                        gtp.push(wl_i32_type(self.context))
                        let gtft = wl_function_type(wl_void_type(self.context), vec_data_i64(&gtp), 2, 0)
                        gc_track_fn = wl_add_function(self.llmod, "with_scope_track", gtft)
                    let gtft2 = wl_global_get_value_type(gc_track_fn)
                    let gta: Vec[i64] = Vec.new()
                    gta.push(gc_recv_val)
                    gta.push(gc_fid)
                    wl_build_call(self.builder, gtft2, gc_track_fn, vec_data_i64(&gta), 2)
                    // Store Task value to dest (so caller can still use it)
                    if dest_place >= 0 and gc_arg_val != 0:
                        let gc_dst_ptr = self.mir_place_ptr(body, dest_place, false, 0)
                        if gc_dst_ptr != 0:
                            wl_build_store(self.builder, gc_arg_val, gc_dst_ptr)
                if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                    wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                return true

            // All patterns should be handled above. If we reach here, it's a genuine error
            // (unless we're in a blanket impl body where T-method calls can't be resolved).
            var gc_is_blanket = false
            if self.current_method_owner_sym != 0:
                let gc_owner_name = self.intern.resolve(self.current_method_owner_sym)
                if gc_owner_name.len() <= 2:
                    // Single-letter type params (T, K, V) indicate blanket impl context
                    if not self.struct_type_map.get(self.current_method_owner_sym).is_some():
                        if not self.enum_type_map.get(self.current_method_owner_sym).is_some():
                            gc_is_blanket = true
            if not gc_is_blanket:
                let fatal_callee_field = self.pool.get_data0(gc_node)
                let fatal_recv =
                    if self.pool.kind(fatal_callee_field) == NodeKind.NK_FIELD_ACCESS:
                        self.pool.get_data0(fatal_callee_field)
                    else:
                        0
                var fatal_recv_ty = self.ast_static_type_expr(fatal_recv)
                let fatal_mir_start = body.call_arg_starts.get(args_id as i64)
                let fatal_mir_count = body.call_arg_counts.get(args_id as i64)
                if fatal_recv_ty == 0 and fatal_mir_count > 0:
                    let fatal_recv_op = body.call_arg_operands.get(fatal_mir_start as i64)
                    fatal_recv_ty = self.mir_operand_sema_type(body, fatal_recv_op)
                if self.debug_method_dispatch_enabled() and fatal_recv != 0:
                    let fatal_base =
                        if self.pool.kind(fatal_recv) == NodeKind.NK_FIELD_ACCESS:
                            self.pool.get_data0(fatal_recv)
                        else:
                            0
                    let fatal_base_ty = if fatal_base != 0: self.ast_static_type_expr(fatal_base) else: 0
                    let fatal_base_local_ty = if fatal_base != 0: self.sema_type_of_node(fatal_base) else: 0
                    let fatal_field =
                        if self.pool.kind(fatal_recv) == NodeKind.NK_FIELD_ACCESS:
                            self.pool.get_data1(fatal_recv)
                        else:
                            0
                    with_eprint(f"[generic-call-unhandled] recv_ast_ty={self.ast_static_type_expr(fatal_recv)} recv_mir_ty={fatal_recv_ty} base_ast_ty={fatal_base_ty} base_local_ty={fatal_base_local_ty} owner={self.function_symbol_name(self.current_method_owner_sym)} field_sym={fatal_field} field_text={if fatal_field != 0: self.intern.resolve(fatal_field) else: \"\"}")
                with_eprint(f"FATAL: unhandled MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL sym={gc_name} node_kind={self.pool.kind(gc_node)} recv_ty={fatal_recv_ty} recv_kind={if fatal_recv != 0: self.pool.kind(fatal_recv) else: -1} arg_count={fatal_mir_count}")
                self.had_error = 1
            if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                wl_build_br(self.builder, gc_next_val)
            return true
    if mir_intrinsic != MirIntrinsic.MIR_INTRINSIC_NONE:
        return self.mir_emit_intrinsic_call(body, mir_intrinsic, args_id, dest_place, next_bb)
    let callee = self.mir_eval_operand(body, callee_operand, 0)
    if self.debug_mir_codegen_enabled():
        // Debug: show callee operand info for crash diagnosis
        let co_k = body.operand_kinds.get(callee_operand as i64)
        let co_d = body.operand_d0.get(callee_operand as i64)
        var dbg_name = "?"
        if co_k == OperandKind.OK_CONSTANT and co_d >= 0 and co_d < body.const_kinds.len() as i32:
            if body.const_kinds.get(co_d as i64) == ConstKind.CK_FN:
                let raw_sym = body.const_d0.get(co_d as i64)
                dbg_name = self.sema_symbol_text(raw_sym)
        with_eprint(f"[mir-call] callee={dbg_name} callee_ty_kind={wl_get_type_kind(wl_type_of(callee))}")
    let call_context = self.mir_call_context(body, callee_operand)
    var call_ft: i64 = 0
    var is_indirect = false
    var fn_ptr_val: i64 = 0
    var ctx_ptr_val: i64 = 0
    let callee_sema_ty = self.mir_operand_sema_type(body, callee_operand)
    let callee_ty = wl_type_of(callee)
    if wl_get_type_kind(callee_ty) == wl_function_type_kind():
        call_ft = callee_ty
    else if wl_get_type_kind(callee_ty) == wl_pointer_type_kind():
        let pointee = wl_get_element_type(callee_ty)
        if wl_get_type_kind(pointee) == wl_function_type_kind():
            call_ft = pointee
        else:
            let gvt = wl_global_get_value_type(callee)
            if gvt != 0 and wl_get_type_kind(gvt) == wl_function_type_kind():
                call_ft = gvt
    else if wl_get_type_kind(callee_ty) == wl_struct_type_kind():
        let nfields = wl_count_struct_elem_types(callee_ty)
        if nfields == 2:
            let f0 = wl_struct_get_type_at(callee_ty, 0)
            let f1 = wl_struct_get_type_at(callee_ty, 1)
            if wl_get_type_kind(f0) == wl_pointer_type_kind() and wl_get_type_kind(f1) == wl_pointer_type_kind():
                is_indirect = true
                fn_ptr_val = wl_build_extract_value(self.builder, callee, 0)
                ctx_ptr_val = wl_build_extract_value(self.builder, callee, 1)
                if callee_sema_ty > 0:
                    call_ft = self.mir_build_closure_fn_type(callee_sema_ty)
    else:
        let gvt2 = wl_global_get_value_type(callee)
        if gvt2 != 0 and wl_get_type_kind(gvt2) == wl_function_type_kind():
            call_ft = gvt2
    if call_ft == 0 and callee_sema_ty > 0:
        call_ft = self.mir_build_raw_fn_type(callee_sema_ty)
    if call_ft == 0:
        return false

    var arg_start = 0
    var arg_count = 0
    if args_id >= 0 and args_id < body.call_arg_starts.len() as i32:
        arg_start = body.call_arg_starts.get(args_id as i64)
        arg_count = body.call_arg_counts.get(args_id as i64)

    let param_count = wl_count_param_types(call_ft)
    let param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        param_types.push(wl_i32_type(self.context))
    if param_count > 0:
        wl_get_param_types(call_ft, vec_data_i64(&param_types))

    // Resolve callee fn_sym for dyn trait parameter lookup.
    // ConstKind.CK_FN syms are from sema pool — translate to codegen intern pool.
    var callee_fn_sym: i32 = 0
    if callee_operand >= 0 and callee_operand < body.operand_kinds.len() as i32:
        let co_k = body.operand_kinds.get(callee_operand as i64)
        let co_d = body.operand_d0.get(callee_operand as i64)
        if co_k == OperandKind.OK_CONSTANT and co_d >= 0 and co_d < body.const_kinds.len() as i32:
            if body.const_kinds.get(co_d as i64) == ConstKind.CK_FN:
                let raw_sym = body.const_d0.get(co_d as i64)
                // Translate sema pool sym to codegen intern pool sym
                let sym_text = self.sema_symbol_text(raw_sym)
                if sym_text.len() > 0:
                    callee_fn_sym = self.intern.intern(sym_text)

    // Check for extern fn ABI transformations (sret/byval for large structs)
    var abi_has_sret = 0
    var abi_byval_mask: i64 = 0
    var abi_sret_ty: i64 = 0
    var abi_sret_buf: i64 = 0
    if callee_fn_sym != 0:
        let sret_opt = self.extern_fn_has_sret.get(callee_fn_sym)
        if sret_opt.is_some():
            abi_has_sret = sret_opt.unwrap()
        let bv_opt = self.extern_fn_byval_params.get(callee_fn_sym)
        if bv_opt.is_some():
            abi_byval_mask = bv_opt.unwrap() as i64
        let srt_opt = self.extern_fn_sret_type.get(callee_fn_sym)
        if srt_opt.is_some():
            abi_sret_ty = srt_opt.unwrap() as i64

    let args: Vec[i64] = Vec.new()
    if is_indirect:
        args.push(ctx_ptr_val)

    // If sret, allocate return buffer and prepend as first arg
    if abi_has_sret != 0 and abi_sret_ty != 0:
        abi_sret_buf = self.create_entry_alloca(abi_sret_ty)
        args.push(abi_sret_buf)

    for ai in 0..arg_count:
        let operand_id = body.call_arg_operands.get((arg_start + ai) as i64)
        var expected_ty: i64 = 0
        let param_offset = if is_indirect: ai + 1 else: ai
        // Account for sret param shift when looking up expected types
        let abi_param_offset = param_offset + (if abi_has_sret != 0: 1 else: 0)
        if abi_param_offset < param_count:
            expected_ty = param_types.get(abi_param_offset as i64)

        // Byval: large struct param → alloca + store + pass pointer
        if (abi_byval_mask & ((1 as i64) << (ai as u32))) != 0:
            let val = self.mir_eval_operand(body, operand_id, 0)
            let val_ty = wl_type_of(val)
            if wl_get_type_kind(val_ty) == wl_pointer_type_kind():
                args.push(val)
            else:
                let tmp = self.create_entry_alloca(val_ty)
                wl_build_store(self.builder, val, tmp)
                args.push(tmp)
            continue

        // Ref param check: pass pointer to place instead of loading value.
        // This handles struct self params where the ABI uses pointer-passing.
        var needs_ref = false
        if callee_fn_sym != 0 and expected_ty != 0:
            if wl_get_type_kind(expected_ty) == wl_pointer_type_kind():
                needs_ref = self.is_ref_param(callee_fn_sym, param_offset)

        // Check for dyn param BEFORE evaluating operand — coercion would
        // mangle the concrete struct into the fat-pointer shape.
        var dyn_trait_sym: i32 = 0
        if callee_fn_sym != 0:
            dyn_trait_sym = self.get_fn_dyn_param_trait(callee_fn_sym, ai)
        var arg_val: i64 = 0
        if needs_ref:
            // Evaluate first to check if operand is already a pointer.
            // Ref params (&T) are already pointers — don't wrap them again.
            let val = self.mir_eval_operand(body, operand_id, 0)
            let val_ty = wl_type_of(val)
            if wl_get_type_kind(val_ty) == wl_pointer_type_kind():
                // Already a pointer — pass directly
                arg_val = val
            else:
                // Struct value needs pointer-passing. Try place ptr first.
                arg_val = self.mir_try_place_ptr_for_ref(body, operand_id)
                if arg_val == 0:
                    // Fallback: alloca in entry block, store, pass ptr
                    let tmp = self.create_entry_alloca(val_ty)
                    wl_build_store(self.builder, val, tmp)
                    arg_val = tmp
        else if dyn_trait_sym != 0:
            // Evaluate without coercion so we get the raw concrete value.
            arg_val = self.mir_eval_operand(body, operand_id, 0)
            let arg_ty = wl_type_of(arg_val)
            var concrete_sym: i32 = 0
            for si in 0..self.struct_llvm_types.len() as i32:
                if self.struct_llvm_types.get(si as i64) == arg_ty:
                    if si < self.struct_index_syms.len() as i32:
                        concrete_sym = self.struct_index_syms.get(si as i64)
                    break
            if concrete_sym != 0:
                arg_val = self.build_dyn_trait_value(arg_val, concrete_sym, dyn_trait_sym)
        else:
            arg_val = self.mir_eval_call_operand(body, operand_id, expected_ty, call_context, ai)
        args.push(arg_val)

    let actual_callee = if is_indirect: fn_ptr_val else: callee
    let actual_arg_count = args.len() as i32
    if self.debug_mir_codegen_enabled():
        with_eprint(f"[mir-call] building call arg_count={actual_arg_count} ft_params={wl_count_param_types(call_ft)}")
        for di in 0..args.len() as i32:
            let a = args.get(di as i64)
            with_eprint(f"[mir-call]   arg[{di}] ty_kind={wl_get_type_kind(wl_type_of(a))}")
    // LLVM intrinsic recognition: emit hardware instructions for known math functions.
    let llvm_intrinsic_result = self.try_emit_llvm_math_intrinsic(callee_fn_sym, args, dest_place, body, next_bb)
    if llvm_intrinsic_result:
        return true

    // Async function call → fiber spawn.
    // When the callee is an async fn, package args into a heap struct,
    // generate a trampoline, heap-allocate result buffer, and call
    // with_fiber_spawn. Return Task { fiber_id, result_buf }.
    if callee_fn_sym != 0 and self.sema.task_fns.contains(callee_fn_sym):
        return self.emit_async_fn_spawn(callee_fn_sym, callee, call_ft, args, dest_place, body, next_bb)

    let call_val = wl_build_call(self.builder, call_ft, actual_callee, vec_data_i64(&args), actual_arg_count)
    // Guaranteed mutual @[tailrec] edges are emitted as musttail.
    if self.mir_emit_mutual_tail_call != 0 and call_val != 0:
        wl_set_musttail_call(call_val)

    // Handle sret: load result from the sret buffer instead of using call_val
    if abi_has_sret != 0 and abi_sret_buf != 0 and abi_sret_ty != 0:
        if dest_place >= 0 and dest_place < body.place_locals.len() as i32:
            let dst_local = body.place_locals.get(dest_place as i64)
            self.mir_local_ptrs.insert(dst_local, abi_sret_buf)
            self.mir_local_types.insert(dst_local, abi_sret_ty)
        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
            let nv = self.mir_bb_values.get(next_bb as i64)
            wl_build_br(self.builder, nv)
        return true

    let ret_ty = wl_get_return_type(call_ft)
    if ret_ty != wl_void_type(self.context):
        if dest_place < 0 or dest_place >= body.place_locals.len() as i32:
            return false
        let dst_local = body.place_locals.get(dest_place as i64)
        // Resolve destination type before creating the place alloca.
        // The sema type may differ from the C return type (e.g. void* → str).
        var dst_ty = ret_ty
        let dst_ty_opt = self.mir_local_types.get(dst_local)
        if dst_ty_opt.is_some():
            dst_ty = dst_ty_opt.unwrap() as i64
        else:
            if dst_local >= 0 and dst_local < body.local_type_ids.len() as i32:
                let sema_ty = body.local_type_ids.get(dst_local as i64)
                if sema_ty > 0:
                    let resolved_llvm = self.mir_sema_type_to_llvm(sema_ty)
                    if resolved_llvm != 0:
                        dst_ty = resolved_llvm
            self.mir_local_types.insert(dst_local, dst_ty)
        if self.debug_mir_codegen_enabled():
            with_eprint(f"[mir-call-ret] dst_local={dst_local} ret_ty_kind={wl_get_type_kind(ret_ty)} dst_ty_kind={wl_get_type_kind(dst_ty)} is_str={if self.is_str_type(dst_ty): 1 else: 0}")
        let dst_ptr = self.mir_place_ptr(body, dest_place, true, dst_ty)
        if dst_ptr == 0:
            return false
        if dst_ty == 0:
            return false
        let stored = self.enforce_coerced_type(call_val, dst_ty, "return type mismatch at call site")
        wl_build_store(self.builder, stored, dst_ptr)

    if next_bb < 0 or next_bb >= self.mir_bb_values.len() as i32:
        return false
    let next_val = self.mir_bb_values.get(next_bb as i64)
    wl_build_br(self.builder, next_val)
    true

fn Codegen.mir_emit_term(self: Codegen, body: MirBody, bb: i32) -> bool:
    if bb < 0 or bb >= body.bb_term_kinds.len() as i32:
        return false
    let tk = body.bb_term_kinds.get(bb as i64)
    let d0 = body.bb_term_d0.get(bb as i64)
    let d1 = body.bb_term_d1.get(bb as i64)
    let d2 = body.bb_term_d2.get(bb as i64)
    let d3 = body.bb_term_d3.get(bb as i64)
    if self.debug_mir_codegen_enabled():
        with_eprint(f"[mir-term] bb={bb} tk={tk}")

    if tk == TermKind.TK_GOTO:
        if d0 < 0 or d0 >= self.mir_bb_values.len() as i32:
            return false
        let target_bb = self.mir_bb_values.get(d0 as i64)
        wl_build_br(self.builder, target_bb)
        return true

    if tk == TermKind.TK_RETURN:
        // Async block trampoline: store result into rbuf (with write guard), ret void
        if self.async_block_rbuf != 0:
            let ab_ret_ptr_opt = self.mir_local_ptrs.get(0)
            if ab_ret_ptr_opt.is_some():
                var ab_ret_ty = self.current_ret_type
                let ab_ret_ty_opt = self.mir_local_types.get(0)
                if ab_ret_ty_opt.is_some():
                    ab_ret_ty = ab_ret_ty_opt.unwrap() as i64
                if ab_ret_ty != 0 and ab_ret_ty != wl_void_type(self.context):
                    // Write guard: skip store if cancelled
                    var ab_wg_fn = wl_get_named_function(self.llmod, "with_fiber_is_cancelled")
                    if ab_wg_fn == 0:
                        let ab_wg_ft = wl_function_type(wl_i32_type(self.context), 0, 0, 0)
                        ab_wg_fn = wl_add_function(self.llmod, "with_fiber_is_cancelled", ab_wg_ft)
                    let ab_wg_ft2 = wl_global_get_value_type(ab_wg_fn)
                    let ab_wg_cancel = wl_build_call(self.builder, ab_wg_ft2, ab_wg_fn, 0, 0)
                    let ab_wg_is_cancel = wl_build_icmp(self.builder, wl_int_ne(), ab_wg_cancel, wl_const_int(wl_i32_type(self.context), 0, 0))
                    let ab_wg_do = wl_append_bb(self.context, self.current_function, "ab.do_store")
                    let ab_wg_after = wl_append_bb(self.context, self.current_function, "ab.after_store")
                    wl_build_cond_br(self.builder, ab_wg_is_cancel, ab_wg_after, ab_wg_do)
                    wl_position_at_end(self.builder, ab_wg_do)
                    let ab_ret_val = wl_build_load(self.builder, ab_ret_ty, ab_ret_ptr_opt.unwrap() as i64)
                    wl_build_store(self.builder, ab_ret_val, self.async_block_rbuf)
                    wl_build_br(self.builder, ab_wg_after)
                    wl_position_at_end(self.builder, ab_wg_after)
            let _ = wl_build_ret_void(self.builder)
            return true
        if self.current_ret_type == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
            return true
        let fn_has_sret_opt = self.extern_fn_has_sret.get(self.current_function_name_sym)
        let fn_has_sret = if fn_has_sret_opt.is_some(): fn_has_sret_opt.unwrap() else: 0
        let ret_ptr_opt = self.mir_local_ptrs.get(0)
        if fn_has_sret != 0:
            let sret_ptr = wl_get_param(self.current_function, 0)
            var sret_val = self.build_default_value(self.current_ret_type)
            if ret_ptr_opt.is_some():
                let ret_ptr = ret_ptr_opt.unwrap() as i64
                var ret_ptr_ty = self.current_ret_type
                let ret_ptr_ty_opt = self.mir_local_types.get(0)
                if ret_ptr_ty_opt.is_some():
                    ret_ptr_ty = ret_ptr_ty_opt.unwrap() as i64
                if ret_ptr_ty != 0:
                    let ret_val = wl_build_load(self.builder, ret_ptr_ty, ret_ptr)
                    sret_val = self.enforce_coerced_type(ret_val, self.current_ret_type, "return type mismatch")
            wl_build_store(self.builder, sret_val, sret_ptr)
            let _ = wl_build_ret_void(self.builder)
            return true
        if not ret_ptr_opt.is_some():
            let _ = wl_build_ret(self.builder, self.build_default_value(self.current_ret_type))
            return true
        let ret_ptr = ret_ptr_opt.unwrap() as i64
        var ret_ptr_ty = self.current_ret_type
        let ret_ptr_ty_opt = self.mir_local_types.get(0)
        if ret_ptr_ty_opt.is_some():
            ret_ptr_ty = ret_ptr_ty_opt.unwrap() as i64
        if ret_ptr_ty == 0:
            let _ = wl_build_ret(self.builder, self.build_default_value(self.current_ret_type))
            return true
        let ret_val = wl_build_load(self.builder, ret_ptr_ty, ret_ptr)
        let _ = wl_build_ret(self.builder, self.enforce_coerced_type(ret_val, self.current_ret_type, "return type mismatch"))
        return true

    if tk == TermKind.TK_UNREACHABLE:
        wl_build_unreachable(self.builder)
        return true

    if tk == TermKind.TK_SWITCH_INT:
        let cond = self.mir_eval_operand(body, d0, 0)
        var default_bb = self.mir_default_unreachable_bb_value()
        if d2 >= 0:
            if d2 >= 0 and d2 < self.mir_bb_values.len() as i32:
                default_bb = self.mir_bb_values.get(d2 as i64)
        var case_start = 0
        var case_count = 0
        if d1 >= 0 and d1 < body.switch_table_starts.len() as i32:
            case_start = body.switch_table_starts.get(d1 as i64)
            case_count = body.switch_table_counts.get(d1 as i64)
        // For i1 conditions with exactly 1 case, emit br i1 instead of switch i1.
        // LLVM's optimizer has known issues with switch i1 (non-canonical form).
        let cond_ty = wl_type_of(cond)
        if wl_get_int_type_width(cond_ty) == 1 and case_count == 1:
            let target_bb = body.switch_table_targets.get(case_start as i64)
            if target_bb >= 0 and target_bb < self.mir_bb_values.len() as i32:
                let case_target = self.mir_bb_values.get(target_bb as i64)
                let val = body.switch_table_vals.get(case_start as i64)
                if val != 0:
                    wl_build_cond_br(self.builder, cond, case_target, default_bb)
                else:
                    wl_build_cond_br(self.builder, cond, default_bb, case_target)
            return true
        let sw = wl_build_switch(self.builder, cond, default_bb, case_count)
        var int_ty = wl_i32_type(self.context)
        if wl_get_type_kind(cond_ty) == wl_integer_type_kind():
            int_ty = cond_ty
        for ci in 0..case_count:
            let target_bb = body.switch_table_targets.get((case_start + ci) as i64)
            if target_bb >= 0 and target_bb < self.mir_bb_values.len() as i32:
                let val = body.switch_table_vals.get((case_start + ci) as i64)
                let case_target = self.mir_bb_values.get(target_bb as i64)
                wl_add_case(sw, wl_const_int(int_ty, val as i64, 1), case_target)
        return true

    if tk == TermKind.TK_CALL:
        // Check if this is a mutual tail call (marked by mutual TCO pass)
        for mti in 0..body.mutual_tail_bbs.len() as i32:
            if body.mutual_tail_bbs.get(mti as i64) == bb:
                self.mir_emit_mutual_tail_call = 1
                break
        let call_ok = self.mir_emit_call_term(body, d0, d1, d2, d3)
        self.mir_emit_mutual_tail_call = 0
        return call_ok

    if tk == TermKind.TK_DROP_AND_GOTO:
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let local_id = body.place_locals.get(d0 as i64)
        let drop_ty = self.mir_local_llvm_type(body, local_id)
        var ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr == 0 and drop_ty != 0:
            ptr = self.mir_place_ptr(body, d0, true, drop_ty)
        if ptr != 0:
            if drop_ty != 0:
                self.mir_emit_drop_ptr(ptr, drop_ty)
        if d1 < 0 or d1 >= self.mir_bb_values.len() as i32:
            return false
        let target_bb = self.mir_bb_values.get(d1 as i64)
        wl_build_br(self.builder, target_bb)
        return true

    false

fn Codegen.gen_function_mir(self: Codegen, fn_node: i32, body: MirBody):
    let name_sym = self.pool.get_data0(fn_node)
    let resolved_name = self.intern.resolve(name_sym)
    let name_str = if resolved_name.len() > 0: resolved_name else: self.fn_decl_name_from_node(fn_node)
    if name_sym == 0:
        return
    let fv = self.fn_values.get(name_sym)
    if not fv.is_some():
        with_eprint("error: no fn_value for MIR function: " ++ name_str)
        return
    let function = fv.unwrap() as i64
    let ft = self.fn_fn_types.get(name_sym)
    if not ft.is_some():
        with_eprint("error: no fn_type for MIR function: " ++ name_str)
        return
    let fn_type = ft.unwrap() as i64
    if self.debug_mir_codegen_enabled():
        with_eprint(f"[mir-cg] fn={name_str} blocks={body.block_count()}")

    self.current_function = function
    self.current_function_name_sym = name_sym
    self.current_ret_type = wl_get_return_type(fn_type)
    let fn_has_sret_opt = self.extern_fn_has_sret.get(name_sym)
    let fn_has_sret = if fn_has_sret_opt.is_some(): fn_has_sret_opt.unwrap() else: 0
    if fn_has_sret != 0:
        let fn_sret_ty_opt = self.extern_fn_sret_type.get(name_sym)
        if fn_sret_ty_opt.is_some():
            self.current_ret_type = fn_sret_ty_opt.unwrap() as i64
    self.current_method_owner_sym = 0

    let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
    let fresh_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
    let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
    let fresh_local_pointee_structs: HashMap[i32, i32] = HashMap.new()
    let fresh_local_sema_types: HashMap[i32, i32] = HashMap.new()
    let fresh_task_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_defer_stack: Vec[i32] = Vec.new()
    let fresh_errdefer_stack: Vec[i32] = Vec.new()
    let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_local_concrete_types: HashMap[i32, i32] = HashMap.new()
    let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
    self.local_allocas = fresh_local_allocas
    self.local_types = fresh_local_types
    self.local_muts = fresh_local_muts
    self.local_fn_sigs = fresh_local_fn_sigs
    self.local_pointee_structs = fresh_local_pointee_structs
    self.local_sema_types = fresh_local_sema_types
    self.task_locals = fresh_task_locals
    self.defer_stack = fresh_defer_stack
    self.errdefer_stack = fresh_errdefer_stack
    self.trait_locals = fresh_trait_locals
    self.trait_local_concrete_types = fresh_trait_local_concrete_types
    self.enum_local_types = fresh_enum_local_types
    self.scope_local_count = 0

    let saved_expected = self.expected_type
    let saved_expected_node = self.expected_type_node
    self.expected_type = self.current_ret_type
    self.expected_type_node = 0
    let saved_result_err = self.current_result_err_symbol
    let saved_returns_result = self.current_fn_returns_result
    let saved_saw_return = self.current_fn_saw_explicit_return
    self.current_result_err_symbol = 0
    self.current_fn_returns_result = false
    self.current_fn_saw_explicit_return = false
    let saved_tailrec_bb = self.tailrec_body_bb
    let saved_tailrec_sym = self.tailrec_fn_sym
    self.tailrec_body_bb = 0
    self.tailrec_fn_sym = 0

    let fresh_mir_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_indirect_value_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_bbs: Vec[i64] = Vec.new()
    let fresh_mir_default_unreachable_bbs: Vec[i64] = Vec.new()
    self.mir_local_ptrs = fresh_mir_locals
    self.mir_local_types = fresh_mir_local_types
    self.mir_indirect_value_local_types = fresh_mir_indirect_value_local_types
    self.mir_bb_values = fresh_mir_bbs
    self.mir_default_unreachable_bbs = fresh_mir_default_unreachable_bbs

    let entry = wl_append_bb(self.context, function, "entry")
    wl_position_at_end(self.builder, entry)

    let ret_store_ty = if self.current_ret_type != wl_void_type(self.context): self.current_ret_type else: wl_i32_type(self.context)
    let ret_alloca = self.create_entry_alloca(ret_store_ty)
    self.mir_local_ptrs.insert(0, ret_alloca)
    self.mir_local_types.insert(0, ret_store_ty)

    // Pre-populate mir_local_ptrs for global variable proxy locals
    for gli in 0..body.local_names.len() as i32:
        let gl_name = body.local_names.get(gli as i64)
        if gl_name != 0:
            let gl_mc = self.module_constants.get(gl_name)
            if gl_mc.is_some():
                self.mir_local_ptrs.insert(gli, gl_mc.unwrap() as i64)

    let meta = self.pool.find_fn_meta(fn_node)
    var param_start = 0
    var param_count = 0
    if meta >= 0:
        param_start = self.pool.fn_meta_param_start(meta)
        param_count = self.pool.fn_meta_param_count(meta)
    let fn_byval_mask_opt = self.extern_fn_byval_params.get(name_sym)
    let fn_byval_mask = if fn_byval_mask_opt.is_some(): fn_byval_mask_opt.unwrap() as i64 else: 0
    var fn_byval_types: Vec[i64] = Vec.new()
    let fn_byval_types_opt = self.extern_fn_byval_types.get(name_sym)
    if fn_byval_types_opt.is_some():
        fn_byval_types = fn_byval_types_opt.unwrap()

    var method_owner_sym = 0
    for di in 0..name_str.len() as i32:
        if name_str.byte_at(di as i64) == 46:
            method_owner_sym = self.intern.intern(name_str.slice(0, di as i64))
            break
    self.current_method_owner_sym = method_owner_sym

    let max_params = param_count
    for pi in 0..max_params:
        let p_name = self.pool.fn_param_name(param_start, pi)
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        let actual_pi = pi + (if fn_has_sret != 0: 1 else: 0)
        let param_val = wl_get_param(function, actual_pi)
        var param_type = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_type)
        if (fn_byval_mask & ((1 as i64) << (pi as u32))) != 0:
            if pi < fn_byval_types.len() as i32 and fn_byval_types.get(pi as i64) != 0:
                param_type = fn_byval_types.get(pi as i64)
            let byval_alloca = self.create_entry_alloca(param_type)
            let loaded = wl_build_load(self.builder, param_type, param_val)
            wl_build_store(self.builder, loaded, byval_alloca)
            self.record_local(p_name, byval_alloca, param_type, 1)
            var p_sema_ty = if pi + 1 < body.local_type_ids.len() as i32: body.local_type_ids.get((pi + 1) as i64) else: 0
            if p_type_node != 0:
                let resolved_p_sema = self.sema.resolve_type_expr(p_type_node)
                if resolved_p_sema != 0:
                    p_sema_ty = resolved_p_sema as i32
            self.record_local_sema_type(p_name, p_sema_ty)
            self.mir_local_ptrs.insert(pi + 1, byval_alloca)
            self.mir_local_types.insert(pi + 1, param_type)
            if p_type_node != 0:
                let pk = self.pool.kind(p_type_node)
                if pk == NodeKind.NK_TYPE_FN:
                    let fn_sig = self.build_fn_type_from_ast(p_type_node)
                    self.record_local_fn_sig(p_name, fn_sig)
                if pk == NodeKind.NK_TYPE_PTR or pk == NodeKind.NK_TYPE_REF:
                    let pointee_node = self.pool.get_data0(p_type_node)
                    if self.pool.kind(pointee_node) == NodeKind.NK_TYPE_NAMED:
                        let ps = self.pool.get_data0(pointee_node)
                        if self.struct_type_map.get(ps).is_some():
                            self.record_local_pointee_struct(p_name, ps)
                if pk == NodeKind.NK_TYPE_NAMED:
                    let p_sym = self.pool.get_data0(p_type_node)
                    if method_owner_sym == 0 and p_name == self.sym_self and self.struct_type_map.get(p_sym).is_some():
                        if p_sym != self.sym_str:
                            method_owner_sym = p_sym
                            self.current_method_owner_sym = method_owner_sym
            continue
        wl_build_store(self.builder, param_val, alloca)

        self.record_local(p_name, alloca, param_type, 1)
        var p_sema_ty2 = if pi + 1 < body.local_type_ids.len() as i32: body.local_type_ids.get((pi + 1) as i64) else: 0
        if p_type_node != 0:
            let resolved_p_sema2 = self.sema.resolve_type_expr(p_type_node)
            if resolved_p_sema2 != 0:
                p_sema_ty2 = resolved_p_sema2 as i32
        self.record_local_sema_type(p_name, p_sema_ty2)

        self.mir_local_ptrs.insert(pi + 1, alloca)
        self.mir_local_types.insert(pi + 1, param_type)
        if wl_get_type_kind(param_type) == wl_pointer_type_kind() and pi + 1 < body.local_type_ids.len() as i32:
            let local_sema_ty = body.local_type_ids.get((pi + 1) as i64)
            if local_sema_ty > 0:
                let semantic_ty = self.mir_sema_type_to_llvm(local_sema_ty)
                if semantic_ty != 0 and wl_get_type_kind(semantic_ty) != wl_pointer_type_kind():
                    self.mir_indirect_value_local_types.insert(pi + 1, semantic_ty)

        if p_type_node != 0:
            let pk = self.pool.kind(p_type_node)
            if pk == NodeKind.NK_TYPE_FN:
                let fn_sig = self.build_fn_type_from_ast(p_type_node)
                self.record_local_fn_sig(p_name, fn_sig)
            if pk == NodeKind.NK_TYPE_PTR or pk == NodeKind.NK_TYPE_REF:
                let pointee_node = self.pool.get_data0(p_type_node)
                if self.pool.kind(pointee_node) == NodeKind.NK_TYPE_NAMED:
                    let ps = self.pool.get_data0(pointee_node)
                    if self.struct_type_map.get(ps).is_some():
                        self.record_local_pointee_struct(p_name, ps)
            if pk == NodeKind.NK_TYPE_NAMED:
                let p_sym = self.pool.get_data0(p_type_node)
                if method_owner_sym == 0 and p_name == self.sym_self and self.struct_type_map.get(p_sym).is_some():
                    // str is in struct_type_map but passes by value, not pointer
                    if p_sym != self.sym_str:
                        method_owner_sym = p_sym
                        self.current_method_owner_sym = method_owner_sym
                if method_owner_sym != 0 and (p_sym == self.sym_Self or p_sym == method_owner_sym):
                    if method_owner_sym != self.sym_str:
                        self.record_local_pointee_struct(p_name, method_owner_sym)
                        var owner_ty: i64 = 0
                        if pi + 1 < body.local_type_ids.len() as i32:
                            let local_sema_ty = body.local_type_ids.get((pi + 1) as i64)
                            if local_sema_ty > 0:
                                owner_ty = self.mir_sema_type_to_llvm(local_sema_ty)
                        if owner_ty == 0:
                            owner_ty = self.resolve_named_type(method_owner_sym)
                        if owner_ty != 0 and wl_get_type_kind(param_type) == wl_pointer_type_kind():
                            self.mir_indirect_value_local_types.insert(pi + 1, owner_ty)
            if method_owner_sym != 0:
                if p_name == self.sym_self:
                    if method_owner_sym != self.sym_str:
                        self.record_local_pointee_struct(p_name, method_owner_sym)
                        var owner_ty: i64 = 0
                        if pi + 1 < body.local_type_ids.len() as i32:
                            let local_sema_ty = body.local_type_ids.get((pi + 1) as i64)
                            if local_sema_ty > 0:
                                owner_ty = self.mir_sema_type_to_llvm(local_sema_ty)
                        if owner_ty == 0:
                            owner_ty = self.resolve_named_type(method_owner_sym)
                        if owner_ty != 0 and wl_get_type_kind(param_type) == wl_pointer_type_kind():
                            self.mir_indirect_value_local_types.insert(pi + 1, owner_ty)
            let trait_sym = self.dyn_trait_from_type_node(p_type_node)
            if trait_sym != 0:
                self.record_trait_local(p_name, trait_sym)

    for bb in 0..body.block_count():
        let bb_name = f"mir.bb{bb}"
        let llbb = wl_append_bb(self.context, function, bb_name)
        self.mir_bb_values.push(llbb)

    if self.mir_bb_values.len() as i32 > 0:
        wl_build_br(self.builder, self.mir_bb_values.get(0))
    else:
        let fallthrough_has_sret_opt = self.extern_fn_has_sret.get(name_sym)
        let fallthrough_has_sret = if fallthrough_has_sret_opt.is_some(): fallthrough_has_sret_opt.unwrap() else: 0
        if fallthrough_has_sret != 0:
            wl_build_store(self.builder, self.build_default_value(self.current_ret_type), wl_get_param(function, 0))
            let _ = wl_build_ret_void(self.builder)
        else if self.current_ret_type == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
        else:
            let _ = wl_build_ret(self.builder, self.build_default_value(self.current_ret_type))

    let saved_fn_scope = self.di_current_scope
    for bb in 0..body.block_count():
        if bb < 0 or bb >= self.mir_bb_values.len() as i32:
            continue
        let llbb = self.mir_bb_values.get(bb as i64)
        if self.debug_mir_codegen_enabled():
            with_eprint(f"[mir-cg] fn={name_str} bb={bb} llbb={llbb}")
        wl_position_at_end(self.builder, llbb)
        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let stmt_count = body.bb_stmt_counts.get(bb as i64)
        // Push a lexical block scope for non-entry BBs
        if bb > 0 and stmt_count > 0:
            let first_span = body.stmt_spans.get(stmt_start as i64)
            if first_span > 0:
                self.di_current_scope = saved_fn_scope
                self.debug_push_lexical_block(first_span)
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            let stmt_span = body.stmt_spans.get(stmt_id as i64)
            if stmt_span > 0:
                self.debug_set_location(stmt_span)
            if not self.mir_emit_stmt(body, stmt_id):
                if self.debug_mir_codegen_enabled():
                    with_eprint(f"[mir-cg] fn={name_str} bb={bb} stmt_fail={stmt_id}")
                if wl_get_bb_terminator(llbb) == 0:
                    wl_build_unreachable(self.builder)
                break
        if wl_get_bb_terminator(llbb) == 0:
            let term_span = body.bb_term_spans.get(bb as i64)
            if term_span > 0:
                self.debug_set_location(term_span)
            let ok = self.mir_emit_term(body, bb)
            if self.debug_mir_codegen_enabled():
                var ok_i = 0
                if ok:
                    ok_i = 1
                with_eprint(f"[mir-cg] fn={name_str} bb={bb} term_ok={ok_i}")
            if not ok and wl_get_bb_terminator(llbb) == 0:
                wl_build_unreachable(self.builder)

    self.di_current_scope = saved_fn_scope

    if self.mir_default_unreachable_bbs.len() as i32 > 0:
        let ubb = self.mir_default_unreachable_bbs.get(0)
        if wl_get_bb_terminator(ubb) == 0:
            wl_position_at_end(self.builder, ubb)
            wl_build_unreachable(self.builder)


    // Run mem2reg to promote allocas to SSA, reducing stack frame sizes.
    // DISABLED: investigating whether mem2reg causes argument setup issues
    // wl_promote_allocas(function, self.target_machine)

    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    self.current_result_err_symbol = saved_result_err
    self.current_fn_returns_result = saved_returns_result
    self.current_fn_saw_explicit_return = saved_saw_return
    self.tailrec_body_bb = saved_tailrec_bb
    self.tailrec_fn_sym = saved_tailrec_sym

// ── gen_function_mir_mono: MIR codegen for monomorphized generic fn ──
// Like gen_function_mir but uses mono_sym for fn_values/fn_fn_types lookup
// instead of extracting the name from the AST node (which has the generic name).

fn Codegen.gen_function_mir_mono(self: Codegen, mono_sym: i32, fn_node: i32, body: MirBody):
    let name_str = self.intern.resolve(mono_sym)
    let fv = self.fn_values.get(mono_sym)
    if not fv.is_some():
        with_eprint("error: no fn_value for MIR mono function: " ++ name_str)
        return
    let function = fv.unwrap() as i64
    let ft = self.fn_fn_types.get(mono_sym)
    if not ft.is_some():
        with_eprint("error: no fn_type for MIR mono function: " ++ name_str)
        return
    let fn_type = ft.unwrap() as i64

    // Save all codegen state (will be restored at end)
    let saved_fn = self.current_function
    let saved_fn_name_sym = self.current_function_name_sym
    let saved_ret = self.current_ret_type
    let saved_owner = self.current_method_owner_sym
    let saved_allocas = self.local_allocas
    let saved_types = self.local_types
    let saved_muts = self.local_muts
    let saved_fn_sigs = self.local_fn_sigs
    let saved_pointees = self.local_pointee_structs
    let saved_task_locals = self.task_locals
    let saved_trait_locals = self.trait_locals
    let saved_trait_concrete = self.trait_local_concrete_types
    let saved_scope_syms = self.scope_local_syms
    let saved_scope_allocas = self.scope_local_allocas
    let saved_scope_types = self.scope_local_types
    let saved_scope_count = self.scope_local_count
    let saved_defer = self.defer_stack
    let saved_errdefer = self.errdefer_stack
    let saved_enum_local_types = self.enum_local_types
    let saved_sema_local_types = self.local_sema_types
    let saved_expected = self.expected_type
    let saved_expected_node = self.expected_type_node
    let saved_result_err = self.current_result_err_symbol
    let saved_returns_result = self.current_fn_returns_result
    let saved_saw_return = self.current_fn_saw_explicit_return
    let saved_tail_bb = self.tailrec_body_bb
    let saved_tail_sym = self.tailrec_fn_sym
    let saved_tail_allocas = self.tailrec_param_allocas
    let saved_loops = self.capture_loop_state()
    let saved_bb = wl_get_insert_block(self.builder)

    // Set up fresh function state
    self.current_function = function
    self.current_function_name_sym = mono_sym
    self.current_ret_type = wl_get_return_type(fn_type)
    let fn_has_sret_opt = self.extern_fn_has_sret.get(mono_sym)
    let fn_has_sret = if fn_has_sret_opt.is_some(): fn_has_sret_opt.unwrap() else: 0
    if fn_has_sret != 0:
        let fn_sret_ty_opt = self.extern_fn_sret_type.get(mono_sym)
        if fn_sret_ty_opt.is_some():
            self.current_ret_type = fn_sret_ty_opt.unwrap() as i64
    self.current_method_owner_sym = 0

    let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
    let fresh_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
    let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
    let fresh_local_pointee_structs: HashMap[i32, i32] = HashMap.new()
    let fresh_local_sema_types: HashMap[i32, i32] = HashMap.new()
    let fresh_task_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_defer_stack: Vec[i32] = Vec.new()
    let fresh_errdefer_stack: Vec[i32] = Vec.new()
    let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_local_concrete_types: HashMap[i32, i32] = HashMap.new()
    let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
    let fresh_scope_syms: Vec[i32] = Vec.new()
    let fresh_scope_allocas: Vec[i64] = Vec.new()
    let fresh_scope_types: Vec[i64] = Vec.new()
    let fresh_tail_allocas: Vec[i64] = Vec.new()
    self.local_allocas = fresh_local_allocas
    self.local_types = fresh_local_types
    self.local_muts = fresh_local_muts
    self.local_fn_sigs = fresh_local_fn_sigs
    self.local_pointee_structs = fresh_local_pointee_structs
    self.local_sema_types = fresh_local_sema_types
    self.task_locals = fresh_task_locals
    self.defer_stack = fresh_defer_stack
    self.errdefer_stack = fresh_errdefer_stack
    self.trait_locals = fresh_trait_locals
    self.trait_local_concrete_types = fresh_trait_local_concrete_types
    self.enum_local_types = fresh_enum_local_types
    self.scope_local_syms = fresh_scope_syms
    self.scope_local_allocas = fresh_scope_allocas
    self.scope_local_types = fresh_scope_types
    self.scope_local_count = 0
    self.expected_type = self.current_ret_type
    self.expected_type_node = 0
    self.current_result_err_symbol = 0
    self.current_fn_returns_result = false
    self.current_fn_saw_explicit_return = false
    self.tailrec_body_bb = 0
    self.tailrec_fn_sym = 0
    self.tailrec_param_allocas = fresh_tail_allocas
    self.reset_loop_state()

    let saved_mir_locals = self.mir_local_ptrs
    let saved_mir_local_types = self.mir_local_types
    let saved_mir_indirect_value_local_types = self.mir_indirect_value_local_types
    let saved_mir_bbs = self.mir_bb_values
    let saved_mir_default_unreachable_bbs = self.mir_default_unreachable_bbs
    let fresh_mir_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_indirect_value_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_bbs: Vec[i64] = Vec.new()
    let fresh_mir_default_unreachable_bbs: Vec[i64] = Vec.new()
    self.mir_local_ptrs = fresh_mir_locals
    self.mir_local_types = fresh_mir_local_types
    self.mir_indirect_value_local_types = fresh_mir_indirect_value_local_types
    self.mir_bb_values = fresh_mir_bbs
    self.mir_default_unreachable_bbs = fresh_mir_default_unreachable_bbs

    let entry = wl_append_bb(self.context, function, "entry")
    wl_position_at_end(self.builder, entry)

    let ret_store_ty = if self.current_ret_type != wl_void_type(self.context): self.current_ret_type else: wl_i32_type(self.context)
    let ret_alloca = self.create_entry_alloca(ret_store_ty)
    self.mir_local_ptrs.insert(0, ret_alloca)
    self.mir_local_types.insert(0, ret_store_ty)

    let meta = self.pool.find_fn_meta(fn_node)
    var param_start = 0
    var param_count = 0
    if meta >= 0:
        param_start = self.pool.fn_meta_param_start(meta)
        param_count = self.pool.fn_meta_param_count(meta)
    let fn_byval_mask_opt = self.extern_fn_byval_params.get(mono_sym)
    let fn_byval_mask = if fn_byval_mask_opt.is_some(): fn_byval_mask_opt.unwrap() as i64 else: 0
    var fn_byval_types: Vec[i64] = Vec.new()
    let fn_byval_types_opt = self.extern_fn_byval_types.get(mono_sym)
    if fn_byval_types_opt.is_some():
        fn_byval_types = fn_byval_types_opt.unwrap()

    // Detect method owner from mangled name (e.g. "Vec__i32.push")
    var method_owner_sym = 0
    for di in 0..name_str.len() as i32:
        if name_str.byte_at(di as i64) == 46:
            method_owner_sym = self.intern.intern(name_str.slice(0, di as i64))
            break
    self.current_method_owner_sym = method_owner_sym

    let max_params = param_count
    for pi in 0..max_params:
        let p_name = self.pool.fn_param_name(param_start, pi)
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        let actual_pi = pi + (if fn_has_sret != 0: 1 else: 0)
        let param_val = wl_get_param(function, actual_pi)
        var param_type = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_type)
        if (fn_byval_mask & ((1 as i64) << (pi as u32))) != 0:
            if pi < fn_byval_types.len() as i32 and fn_byval_types.get(pi as i64) != 0:
                param_type = fn_byval_types.get(pi as i64)
            let byval_alloca = self.create_entry_alloca(param_type)
            let loaded = wl_build_load(self.builder, param_type, param_val)
            wl_build_store(self.builder, loaded, byval_alloca)
            self.record_local(p_name, byval_alloca, param_type, 1)
            var p_sema_ty = if pi + 1 < body.local_type_ids.len() as i32: body.local_type_ids.get((pi + 1) as i64) else: 0
            if p_type_node != 0:
                let resolved_p_sema = self.sema.resolve_type_expr(p_type_node)
                if resolved_p_sema != 0:
                    p_sema_ty = resolved_p_sema as i32
            self.record_local_sema_type(p_name, p_sema_ty)
            self.mir_local_ptrs.insert(pi + 1, byval_alloca)
            self.mir_local_types.insert(pi + 1, param_type)
            if p_type_node != 0:
                let pk = self.pool.kind(p_type_node)
                if pk == NodeKind.NK_TYPE_FN:
                    let fn_sig = self.build_fn_type_from_ast(p_type_node)
                    self.record_local_fn_sig(p_name, fn_sig)
                if pk == NodeKind.NK_TYPE_PTR or pk == NodeKind.NK_TYPE_REF:
                    let pointee_node = self.pool.get_data0(p_type_node)
                    if self.pool.kind(pointee_node) == NodeKind.NK_TYPE_NAMED:
                        let ps = self.pool.get_data0(pointee_node)
                        if self.struct_type_map.get(ps).is_some():
                            self.record_local_pointee_struct(p_name, ps)
                if pk == NodeKind.NK_TYPE_NAMED:
                    let p_sym = self.pool.get_data0(p_type_node)
                    if method_owner_sym == 0 and p_name == self.sym_self and self.struct_type_map.get(p_sym).is_some():
                        if p_sym != self.sym_str:
                            method_owner_sym = p_sym
                            self.current_method_owner_sym = method_owner_sym
            continue
        wl_build_store(self.builder, param_val, alloca)

        self.record_local(p_name, alloca, param_type, 1)
        var p_sema_ty2 = if pi + 1 < body.local_type_ids.len() as i32: body.local_type_ids.get((pi + 1) as i64) else: 0
        if p_type_node != 0:
            let resolved_p_sema2 = self.sema.resolve_type_expr(p_type_node)
            if resolved_p_sema2 != 0:
                p_sema_ty2 = resolved_p_sema2 as i32
        self.record_local_sema_type(p_name, p_sema_ty2)

        self.mir_local_ptrs.insert(pi + 1, alloca)
        self.mir_local_types.insert(pi + 1, param_type)
        if wl_get_type_kind(param_type) == wl_pointer_type_kind() and pi + 1 < body.local_type_ids.len() as i32:
            let local_sema_ty = body.local_type_ids.get((pi + 1) as i64)
            if local_sema_ty > 0:
                let semantic_ty = self.mir_sema_type_to_llvm(local_sema_ty)
                if semantic_ty != 0 and wl_get_type_kind(semantic_ty) != wl_pointer_type_kind():
                    self.mir_indirect_value_local_types.insert(pi + 1, semantic_ty)

        if p_type_node != 0:
            let pk = self.pool.kind(p_type_node)
            if pk == NodeKind.NK_TYPE_FN:
                let fn_sig = self.build_fn_type_from_ast(p_type_node)
                self.record_local_fn_sig(p_name, fn_sig)
            if pk == NodeKind.NK_TYPE_PTR or pk == NodeKind.NK_TYPE_REF:
                let pointee_node = self.pool.get_data0(p_type_node)
                if self.pool.kind(pointee_node) == NodeKind.NK_TYPE_NAMED:
                    let ps = self.pool.get_data0(pointee_node)
                    if self.struct_type_map.get(ps).is_some():
                        self.record_local_pointee_struct(p_name, ps)
            if pk == NodeKind.NK_TYPE_NAMED:
                let p_sym = self.pool.get_data0(p_type_node)
                if method_owner_sym == 0 and p_name == self.sym_self and self.struct_type_map.get(p_sym).is_some():
                    if p_sym != self.sym_str:
                        method_owner_sym = p_sym
                        self.current_method_owner_sym = method_owner_sym
                if method_owner_sym != 0 and (p_sym == self.sym_Self or p_sym == method_owner_sym):
                    if method_owner_sym != self.sym_str:
                        self.record_local_pointee_struct(p_name, method_owner_sym)
                        var owner_ty: i64 = 0
                        if pi + 1 < body.local_type_ids.len() as i32:
                            let local_sema_ty = body.local_type_ids.get((pi + 1) as i64)
                            if local_sema_ty > 0:
                                owner_ty = self.mir_sema_type_to_llvm(local_sema_ty)
                        if owner_ty == 0:
                            owner_ty = self.resolve_named_type(method_owner_sym)
                        if owner_ty != 0 and wl_get_type_kind(param_type) == wl_pointer_type_kind():
                            self.mir_indirect_value_local_types.insert(pi + 1, owner_ty)
            if method_owner_sym != 0:
                if p_name == self.sym_self:
                    if method_owner_sym != self.sym_str:
                        self.record_local_pointee_struct(p_name, method_owner_sym)
                        var owner_ty: i64 = 0
                        if pi + 1 < body.local_type_ids.len() as i32:
                            let local_sema_ty = body.local_type_ids.get((pi + 1) as i64)
                            if local_sema_ty > 0:
                                owner_ty = self.mir_sema_type_to_llvm(local_sema_ty)
                        if owner_ty == 0:
                            owner_ty = self.resolve_named_type(method_owner_sym)
                        if owner_ty != 0 and wl_get_type_kind(param_type) == wl_pointer_type_kind():
                            self.mir_indirect_value_local_types.insert(pi + 1, owner_ty)
            let trait_sym = self.dyn_trait_from_type_node(p_type_node)
            if trait_sym != 0:
                self.record_trait_local(p_name, trait_sym)

    for bb in 0..body.block_count():
        let bb_name = f"mir.bb{bb}"
        let llbb = wl_append_bb(self.context, function, bb_name)
        self.mir_bb_values.push(llbb)

    if self.mir_bb_values.len() as i32 > 0:
        wl_build_br(self.builder, self.mir_bb_values.get(0))
    else:
        let fallthrough_has_sret_opt = self.extern_fn_has_sret.get(mono_sym)
        let fallthrough_has_sret = if fallthrough_has_sret_opt.is_some(): fallthrough_has_sret_opt.unwrap() else: 0
        if fallthrough_has_sret != 0:
            wl_build_store(self.builder, self.build_default_value(self.current_ret_type), wl_get_param(function, 0))
            let _ = wl_build_ret_void(self.builder)
        else if self.current_ret_type == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
        else:
            let _ = wl_build_ret(self.builder, self.build_default_value(self.current_ret_type))

    for bb in 0..body.block_count():
        if bb < 0 or bb >= self.mir_bb_values.len() as i32:
            continue
        let llbb = self.mir_bb_values.get(bb as i64)
        wl_position_at_end(self.builder, llbb)
        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let stmt_count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            if not self.mir_emit_stmt(body, stmt_id):
                if wl_get_bb_terminator(llbb) == 0:
                    wl_build_unreachable(self.builder)
                break
        if wl_get_bb_terminator(llbb) == 0:
            let ok = self.mir_emit_term(body, bb)
            if not ok and wl_get_bb_terminator(llbb) == 0:
                wl_build_unreachable(self.builder)

    if self.mir_default_unreachable_bbs.len() as i32 > 0:
        let ubb = self.mir_default_unreachable_bbs.get(0)
        if wl_get_bb_terminator(ubb) == 0:
            wl_position_at_end(self.builder, ubb)
            wl_build_unreachable(self.builder)

    // Restore all codegen state
    self.current_function = saved_fn
    self.current_function_name_sym = saved_fn_name_sym
    self.current_ret_type = saved_ret
    self.current_method_owner_sym = saved_owner
    self.local_allocas = saved_allocas
    self.local_types = saved_types
    self.local_muts = saved_muts
    self.local_fn_sigs = saved_fn_sigs
    self.local_pointee_structs = saved_pointees
    self.task_locals = saved_task_locals
    self.trait_locals = saved_trait_locals
    self.trait_local_concrete_types = saved_trait_concrete
    self.enum_local_types = saved_enum_local_types
    self.local_sema_types = saved_sema_local_types
    self.scope_local_syms = saved_scope_syms
    self.scope_local_allocas = saved_scope_allocas
    self.scope_local_types = saved_scope_types
    self.scope_local_count = saved_scope_count
    self.defer_stack = saved_defer
    self.errdefer_stack = saved_errdefer
    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    self.current_result_err_symbol = saved_result_err
    self.current_fn_returns_result = saved_returns_result
    self.current_fn_saw_explicit_return = saved_saw_return
    self.tailrec_body_bb = saved_tail_bb
    self.tailrec_fn_sym = saved_tail_sym
    self.tailrec_param_allocas = saved_tail_allocas
    self.restore_loop_state(saved_loops)
    self.mir_local_ptrs = saved_mir_locals
    self.mir_local_types = saved_mir_local_types
    self.mir_indirect_value_local_types = saved_mir_indirect_value_local_types
    self.mir_bb_values = saved_mir_bbs
    self.mir_default_unreachable_bbs = saved_mir_default_unreachable_bbs
    if saved_bb != 0:
        wl_position_at_end(self.builder, saved_bb)

fn Codegen.find_struct_type_by_llvm(self: Codegen, llvm_ty: i64) -> i32:
    for i in 0..self.struct_llvm_types.len() as i32:
        if self.struct_llvm_types.get(i as i64) == llvm_ty:
            if i < self.struct_index_syms.len() as i32:
                return self.struct_index_syms.get(i as i64)
            return self.reverse_struct_lookup(i)
    0

fn Codegen.reverse_struct_lookup(self: Codegen, idx: i32) -> i32:
    // Slow reverse lookup: scan all known type syms
    // This is O(n) but only called for field access
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NodeKind.NK_TYPE_DECL:
            let sym = self.pool.get_data0(decl)
            let st = self.struct_type_map.get(sym)
            if st.is_some() and st.unwrap() == idx:
                return sym
    // Check built-in str
    let str_sym = self.intern.intern("str")
    let st = self.struct_type_map.get(str_sym)
    if st.is_some() and st.unwrap() == idx: return str_sym
    0

fn Codegen.find_struct_decl_node(self: Codegen, type_sym: i32) -> NodeId:
    for di in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(di)
        if self.pool.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        if self.pool.get_data0(decl) != type_sym:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind == TypeDeclKind.Struct:
            return decl
    0 as NodeId

fn Codegen.find_field_index_from_ast(self: Codegen, type_sym: i32, field_sym: i32) -> i32:
    let decl = self.find_struct_decl_node(type_sym)
    if (decl as i32) == 0:
        return -1
    let extra_start = self.pool.get_data1(decl)
    let field_count = self.pool.get_extra(extra_start)
    let want_text = self.intern.resolve(field_sym)
    for fi in 0..field_count:
        let offset = extra_start + 1 + fi * 3
        let stored_sym = self.pool.get_extra(offset)
        if stored_sym == field_sym:
            return fi
        if want_text.len() > 0 and self.intern.resolve(stored_sym) == want_text:
            return fi
    -1

fn Codegen.find_field_index(self: Codegen, type_sym: i32, field_sym: i32) -> i32:
    let st_opt = self.struct_type_map.get(type_sym)
    if not st_opt.is_some():
        return self.find_field_index_from_ast(type_sym, field_sym)
    let idx = st_opt.unwrap()
    let start = self.struct_field_starts.get(idx as i64)
    let count = self.struct_field_counts.get(idx as i64)
    let want_text = self.intern.resolve(field_sym)
    for i in 0..count:
        let stored_sym = self.struct_field_names.get((start + i) as i64)
        if stored_sym == field_sym:
            return i
        if want_text.len() > 0 and self.intern.resolve(stored_sym) == want_text:
            return i
    self.find_field_index_from_ast(type_sym, field_sym)

fn Codegen.find_binding_type(self: Codegen, syms: Vec[i32], tys: Vec[i64], sym: i32) -> i64:
    for i in 0..syms.len() as i32:
        if syms.get(i as i64) == sym:
            return tys.get(i as i64)
    0

fn Codegen.infer_static_generic_struct_mono_sym(self: Codegen, owner_sym: i32, decl: i32, owner_expr_node: i32, arg_tys: Vec[i64], arg_nodes: Vec[i32], call_sema_ty: i32) -> i32:
    let owner_decl_opt = self.generic_structs.get(owner_sym)
    if not owner_decl_opt.is_some():
        return 0
    let owner_decl = owner_decl_opt.unwrap()
    let tp_count = self.type_decl_tp_count(owner_decl)
    if tp_count <= 0:
        return owner_sym

    let tp_syms: Vec[i32] = Vec.new()
    var tp_pos = self.type_decl_tp_start(owner_decl)
    for ti in 0..tp_count:
        tp_syms.push(self.pool.get_extra(tp_pos))
        let bound_count = self.pool.get_extra(tp_pos + 1)
        tp_pos = tp_pos + 2 + bound_count

    let bind_syms: Vec[i32] = Vec.new()
    let bind_tys: Vec[i64] = Vec.new()
    let bind_sema_tys: Vec[i32] = Vec.new()

    if call_sema_ty > 0:
        let call_resolved = self.sema.resolve_alias(call_sema_ty)
        if self.sema.get_type_kind(call_resolved) == TypeKind.TY_GENERIC_INST:
            let call_base = self.sema_sym_to_codegen_sym(self.sema.get_type_d0(call_resolved))
            if call_base == owner_sym:
                let call_arg_count = self.sema.get_generic_inst_arg_count(call_resolved)
                for ai in 0..call_arg_count:
                    if ai >= tp_syms.len() as i32:
                        break
                    let arg_tid = self.sema.get_generic_inst_arg(call_resolved, ai)
                    var arg_llvm = self.sema_type_to_llvm(arg_tid)
                    if arg_llvm == 0:
                        arg_llvm = self.type_fallback()
                    let tp_sym = tp_syms.get(ai as i64)
                    var already_bound = false
                    for bi in 0..bind_syms.len() as i32:
                        if bind_syms.get(bi as i64) == tp_sym:
                            already_bound = true
                            break
                    if not already_bound:
                        bind_syms.push(tp_sym)
                        bind_tys.push(arg_llvm)
                        bind_sema_tys.push(arg_tid)

    let owner_kind = self.pool.kind(owner_expr_node)
    if owner_kind == NodeKind.NK_INDEX or owner_kind == NodeKind.NK_TYPE_GENERIC:
        let owner_args_start = self.pool.get_data1(owner_expr_node)
        let owner_arg_count = self.pool.get_data2(owner_expr_node)
        for ai in 0..owner_arg_count:
            if ai >= tp_syms.len() as i32:
                break
            let arg_node = self.pool.get_extra(owner_args_start + ai)
            let arg_sema_ty = self.ast_static_type_expr(arg_node)
            var arg_llvm = self.sema_type_to_llvm(arg_sema_ty)
            if arg_llvm == 0:
                arg_llvm = self.type_fallback()
            let tp_sym = tp_syms.get(ai as i64)
            var already_bound = false
            for bi in 0..bind_syms.len() as i32:
                if bind_syms.get(bi as i64) == tp_sym:
                    already_bound = true
                    break
            if not already_bound:
                bind_syms.push(tp_sym)
                bind_tys.push(arg_llvm)
                bind_sema_tys.push(arg_sema_ty)

    let meta = self.pool.find_fn_meta(decl)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)
    for pi in 0..param_count:
        if pi >= arg_tys.len() as i32:
            break
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if p_type_node == 0:
            continue

        let arg_ty = arg_tys.get(pi as i64)
        let arg_node = arg_nodes.get(pi as i64)
        let p_kind = self.pool.kind(p_type_node)

        if p_kind == NodeKind.NK_TYPE_NAMED or p_kind == NodeKind.NK_IDENT:
            let p_sym = self.pool.get_data0(p_type_node)
            let arg_sema = self.sema_type_of_node(arg_node)
            var canonical_tp_sym = 0
            let want_text = self.intern.resolve(p_sym)
            for ti in 0..tp_syms.len() as i32:
                let candidate = tp_syms.get(ti as i64)
                if candidate == p_sym:
                    canonical_tp_sym = candidate
                    break
                if want_text.len() > 0 and self.intern.resolve(candidate) == want_text:
                    canonical_tp_sym = candidate
                    break
            if canonical_tp_sym != 0:
                var already_bound = false
                for bi in 0..bind_syms.len() as i32:
                    if bind_syms.get(bi as i64) == canonical_tp_sym:
                        already_bound = true
                        break
                if not already_bound:
                    bind_syms.push(canonical_tp_sym)
                    bind_tys.push(arg_ty)
                    bind_sema_tys.push(if arg_sema > 0: arg_sema else: self.llvm_type_to_sema_type(arg_ty))
            continue

        if p_kind == NodeKind.NK_TYPE_GENERIC:
            let g_extra = self.pool.get_data1(p_type_node)
            let g_count = self.pool.get_data2(p_type_node)
            let arg_sema_tid = self.sema_type_of_node(arg_node)
            if arg_sema_tid > 0 and self.sema.get_type_kind(arg_sema_tid) == TypeKind.TY_GENERIC_INST:
                for gi in 0..g_count:
                    let inner_node = self.pool.get_extra(g_extra + gi)
                    let inner_kind = self.pool.kind(inner_node)
                    if inner_kind != NodeKind.NK_TYPE_NAMED and inner_kind != NodeKind.NK_IDENT:
                        continue
                    let inner_sym = self.pool.get_data0(inner_node)
                    let inner_llvm = self.sema_generic_arg_llvm(arg_sema_tid, gi)
                    if inner_llvm == 0:
                        continue
                    let inner_sema = self.sema.get_generic_inst_arg(arg_sema_tid, gi)
                    var canonical_inner_sym = 0
                    let inner_text = self.intern.resolve(inner_sym)
                    for ti in 0..tp_syms.len() as i32:
                        let candidate = tp_syms.get(ti as i64)
                        if candidate == inner_sym:
                            canonical_inner_sym = candidate
                            break
                        if inner_text.len() > 0 and self.intern.resolve(candidate) == inner_text:
                            canonical_inner_sym = candidate
                            break
                    if canonical_inner_sym != 0:
                        var already_bound = false
                        for bi in 0..bind_syms.len() as i32:
                            if bind_syms.get(bi as i64) == canonical_inner_sym:
                                already_bound = true
                                break
                        if not already_bound:
                            bind_syms.push(canonical_inner_sym)
                            bind_tys.push(inner_llvm)
                            bind_sema_tys.push(inner_sema)

    for ti in 0..tp_syms.len() as i32:
        if self.find_binding_type(bind_syms, bind_tys, tp_syms.get(ti as i64)) == 0:
            return 0

    let saved_bind_syms = self.type_binding_syms
    let saved_bind_tys = self.type_binding_types
    let saved_bind_len = self.type_bindings_len
    let fresh_bind_syms: Vec[i32] = Vec.new()
    let fresh_bind_tys: Vec[i64] = Vec.new()
    self.type_binding_syms = fresh_bind_syms
    self.type_binding_types = fresh_bind_tys
    self.type_bindings_len = 0
    for ti in 0..tp_syms.len() as i32:
        let tp_sym = tp_syms.get(ti as i64)
        let bty = self.find_binding_type(bind_syms, bind_tys, tp_sym)
        self.type_binding_syms.push(tp_sym)
        self.type_binding_types.push(bty)
        self.type_bindings_len = self.type_bindings_len + 1
    let mono_ty = self.monomorphize_struct(owner_sym, 0, 0)
    self.type_binding_syms = saved_bind_syms
    self.type_binding_types = saved_bind_tys
    self.type_bindings_len = saved_bind_len

    let mono_sym = self.find_struct_type_by_llvm(mono_ty)
    if mono_sym != 0:
        return mono_sym

    let base_name = self.intern.resolve(owner_sym)
    var mangled = base_name
    for ti in 0..tp_syms.len() as i32:
        let tp_sym = tp_syms.get(ti as i64)
        let bty = self.find_binding_type(bind_syms, bind_tys, tp_sym)
        var sema_mangle = "unknown"
        for bi in 0..bind_syms.len() as i32:
            if bind_syms.get(bi as i64) == tp_sym:
                let sema_ty = bind_sema_tys.get(bi as i64)
                if sema_ty > 0:
                    sema_mangle = self.sema_type_mangle(sema_ty)
                break
        if sema_mangle == "unknown":
            sema_mangle = self.llvm_type_mangle(bty)
        mangled = mangled ++ "__" ++ sema_mangle
    let inferred_sym = self.intern.intern(mangled)
    if self.struct_type_map.get(inferred_sym).is_some():
        return inferred_sym
    0


fn Codegen.sema_type_mangle(self: Codegen, sema_ty: i32) -> str:
    if sema_ty <= 0:
        return "unknown"
    let resolved = self.sema.resolve_alias(sema_ty)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_INT:
        return "i32"
    if tk == TypeKind.TY_FLOAT:
        return "f64"
    if tk == TypeKind.TY_BOOL:
        return "bool"
    if tk == TypeKind.TY_STR:
        return "str"
    if tk == TypeKind.TY_VOID:
        return "void"
    if tk == TypeKind.TY_STRUCT:
        let name_sym = self.sema.get_type_d0(resolved)
        if name_sym != 0:
            return self.intern.resolve(name_sym)
        return "struct"
    if tk == TypeKind.TY_ENUM:
        let name_sym = self.sema.get_type_d0(resolved)
        if name_sym != 0:
            return self.intern.resolve(name_sym)
        return "enum"
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return "ptr"
    if tk == TypeKind.TY_ARRAY:
        return "array"
    if tk == TypeKind.TY_SLICE:
        return "slice"
    if tk == TypeKind.TY_TUPLE:
        return "tuple"
    if tk == TypeKind.TY_RANGE:
        return "range"
    if tk == TypeKind.TY_GENERIC_INST:
        let name_sym = self.sema.get_type_d0(resolved)
        if name_sym != 0:
            return self.intern.resolve(name_sym)
        return "generic"
    if tk == TypeKind.TY_NEVER:
        return "never"
    "unknown"

fn Codegen.llvm_type_mangle(self: Codegen, ty: i64) -> str:
    if ty == 0:
        return "unknown"
    let tk = wl_get_type_kind(ty)
    if tk == wl_void_type_kind():
        return "void"
    if tk == wl_integer_type_kind():
        let w = wl_get_int_type_width(ty)
        if w == 1: return "bool"
        if w == 8: return "i8"
        if w == 16: return "i16"
        if w == 32: return "i32"
        if w == 64: return "i64"
        if w == 128: return "i128"
        return "int"
    if tk == wl_float_type_kind():
        return "f32"
    if tk == wl_double_type_kind():
        return "f64"
    if tk == wl_pointer_type_kind():
        return "ptr"
    if self.is_str_type(ty):
        return "str"
    if tk == wl_struct_type_kind():
        let st_sym = self.find_struct_type_by_llvm(ty)
        if st_sym != 0:
            return self.intern.resolve(st_sym)
        let es = self.enum_by_llvm.get(ty)
        if es.is_some():
            return self.intern.resolve(es.unwrap())
        return "struct"
    if tk == wl_array_type_kind():
        return "array"
    "unknown"

fn Codegen.monomorphize_generic_call_core(self: Codegen, fn_sym: i32, fn_node: i32, args_start: i32, arg_count: i32, call_node: i32, arg_vals: Vec[i64], arg_tys: Vec[i64], arg_nodes: Vec[i32]) -> i64:
    var generic_node = fn_node
    var meta = self.pool.find_fn_meta(generic_node)
    if self.pool.kind(generic_node) != NodeKind.NK_FN_DECL or self.pool.get_data0(generic_node) != fn_sym or meta < 0 or self.pool.fn_meta_tp_count(meta) <= 0:
        for di in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(di)
            if self.pool.kind(decl) != NodeKind.NK_FN_DECL:
                continue
            if self.pool.get_data0(decl) != fn_sym:
                continue
            let dmeta = self.pool.find_fn_meta(decl)
            if dmeta >= 0 and self.pool.fn_meta_tp_count(dmeta) > 0:
                generic_node = decl as i32
                meta = dmeta
                break

    if meta < 0:
        with_eprint("warning: [optional-chain] chain resolution failed")
        return wl_get_undef(wl_i32_type(self.context))

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)
    let tp_start = self.pool.fn_meta_tp_start(meta)
    let tp_count = self.pool.fn_meta_tp_count(meta)
    let body_node = self.pool.get_data1(generic_node)
    if param_count < 0 or param_count > 64:
        with_eprint("warning: [optional-chain] chain resolution failed")
        return wl_get_undef(wl_i32_type(self.context))

    let tp_syms: Vec[i32] = Vec.new()
    var tp_pos = tp_start
    for ti in 0..tp_count:
        let tp_sym = self.pool.get_extra(tp_pos)
        tp_syms.push(tp_sym)
        let bound_count = self.pool.get_extra(tp_pos + 1)
        tp_pos = tp_pos + 2 + bound_count

    let bind_syms: Vec[i32] = Vec.new()
    let bind_tys: Vec[i64] = Vec.new()
    let bind_sema_tys: Vec[i32] = Vec.new()
    for pi in 0..param_count:
        if pi >= arg_count:
            break
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if p_type_node == 0:
            continue

        let arg_ty = arg_tys.get(pi as i64)
        let p_kind = self.pool.kind(p_type_node)

        if p_kind == NodeKind.NK_TYPE_NAMED:
            let p_sym = self.pool.get_data0(p_type_node)
            var is_tp = false
            for ti in 0..tp_syms.len() as i32:
                if tp_syms.get(ti as i64) == p_sym:
                    is_tp = true
                    break
            if is_tp:
                var exists = false
                for bi in 0..bind_syms.len() as i32:
                    if bind_syms.get(bi as i64) == p_sym:
                        exists = true
                        break
                if not exists:
                    bind_syms.push(p_sym)
                    bind_tys.push(arg_ty)
                    // Get sema type for this binding
                    let arg_sema = self.sema_type_of_node(arg_nodes.get(pi as i64))
                    if arg_sema > 0:
                        bind_sema_tys.push(arg_sema)
                    else:
                        bind_sema_tys.push(self.llvm_type_to_sema_type(arg_ty))
            continue

        if p_kind == NodeKind.NK_TYPE_GENERIC:
            let g_name_sym = self.pool.get_data0(p_type_node)
            let g_name = self.intern.resolve(g_name_sym)
            let g_extra = self.pool.get_data1(p_type_node)
            let g_count = self.pool.get_data2(p_type_node)

            // Sema-based generic type param binding: infer from sema types first
            let mg_arg_sema_tid = self.sema_type_of_node(arg_nodes.get(pi as i64))
            if mg_arg_sema_tid > 0 and self.sema.get_type_kind(mg_arg_sema_tid) == TypeKind.TY_GENERIC_INST:
                var mg_sema_bound = true
                for gi in 0..g_count:
                    let mg_inner_node = self.pool.get_extra(g_extra + gi)
                    if self.pool.kind(mg_inner_node) != NodeKind.NK_TYPE_NAMED:
                        mg_sema_bound = false
                        break
                    let mg_inner_sym = self.pool.get_data0(mg_inner_node)
                    var mg_is_tp = false
                    for ti in 0..tp_syms.len() as i32:
                        if tp_syms.get(ti as i64) == mg_inner_sym:
                            mg_is_tp = true
                            break
                    if not mg_is_tp:
                        mg_sema_bound = false
                        break
                    let mg_inner_ty = self.sema_generic_arg_llvm(mg_arg_sema_tid, gi)
                    if mg_inner_ty == 0:
                        mg_sema_bound = false
                        break
                    var mg_exists = false
                    for bi in 0..bind_syms.len() as i32:
                        if bind_syms.get(bi as i64) == mg_inner_sym:
                            mg_exists = true
                            break
                    if not mg_exists:
                        bind_syms.push(mg_inner_sym)
                        bind_tys.push(mg_inner_ty)
                        // Get sema type from generic inst arg
                        bind_sema_tys.push(self.sema.get_generic_inst_arg(mg_arg_sema_tid, gi))
                if mg_sema_bound:
                    continue

    let base_name = self.intern.resolve(fn_sym)
    var mangled = base_name
    for ti in 0..tp_syms.len() as i32:
        let tp_sym = tp_syms.get(ti as i64)
        let bty = self.find_binding_type(bind_syms, bind_tys, tp_sym)
        if bty == 0:
            with_eprint("error: unknown type")
            self.had_error = 1
            return wl_get_undef(wl_i32_type(self.context))
        // Use sema type for mangling when available (LLVM types lose struct identity)
        var sema_mangle = "unknown"
        for bi in 0..bind_syms.len() as i32:
            if bind_syms.get(bi as i64) == tp_sym:
                let sema_ty = bind_sema_tys.get(bi as i64)
                if sema_ty > 0:
                    sema_mangle = self.sema_type_mangle(sema_ty)
                break
        if sema_mangle == "unknown":
            sema_mangle = self.llvm_type_mangle(bty)
        mangled = mangled ++ "__" ++ sema_mangle

    let mono_sym = self.intern.intern(mangled)
    let mono_key = mono_sym as i64
    let mono_cached_fv = self.mono_values.get(mono_key)
    let mono_cached_ft = self.mono_types.get(mono_key)
    if mono_cached_fv.is_some() and mono_cached_ft.is_some():
        let coerced = self.coerce_call_args_for_fn_value(mono_sym, mono_cached_fv.unwrap() as i64, args_start, 0, arg_vals, arg_count, "call " ++ mangled, call_node)
        return wl_build_call(self.builder, mono_cached_ft.unwrap() as i64, mono_cached_fv.unwrap() as i64, vec_data_i64(&coerced), arg_count)

    let cached_fv = self.fn_values.get(mono_sym)
    let cached_ft = self.fn_fn_types.get(mono_sym)
    if cached_fv.is_some() and cached_ft.is_some():
        self.mono_values.insert(mono_key, cached_fv.unwrap() as i64)
        self.mono_types.insert(mono_key, cached_ft.unwrap() as i64)
        let coerced = self.coerce_call_args_for_fn_value(mono_sym, cached_fv.unwrap() as i64, args_start, 0, arg_vals, arg_count, "call " ++ mangled, call_node)
        return wl_build_call(self.builder, cached_ft.unwrap() as i64, cached_fv.unwrap() as i64, vec_data_i64(&coerced), arg_count)

    let saved_bind_syms = self.type_binding_syms
    let saved_bind_tys = self.type_binding_types
    let saved_bind_len = self.type_bindings_len
    let fresh_bind_syms: Vec[i32] = Vec.new()
    let fresh_bind_tys: Vec[i64] = Vec.new()
    self.type_binding_syms = fresh_bind_syms
    self.type_binding_types = fresh_bind_tys
    self.type_bindings_len = 0
    for bi in 0..bind_syms.len() as i32:
        self.type_binding_syms.push(bind_syms.get(bi as i64))
        // Use sema-derived LLVM type for correct struct identity (wl_type_of may flatten)
        let sema_ty_for_bind = bind_sema_tys.get(bi as i64)
        var llvm_ty_for_bind = bind_tys.get(bi as i64)
        if sema_ty_for_bind > 0:
            let sema_llvm = self.sema_type_to_llvm(sema_ty_for_bind)
            if sema_llvm != 0:
                llvm_ty_for_bind = sema_llvm
        self.type_binding_types.push(llvm_ty_for_bind)
        self.type_bindings_len = self.type_bindings_len + 1

    let mono_param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if p_type_node != 0:
            let p_ty = self.resolve_type(p_type_node)
            if p_ty == 0:
                self.type_binding_syms = saved_bind_syms
                self.type_binding_types = saved_bind_tys
                self.type_bindings_len = saved_bind_len
                with_eprint("error: unknown type")
                self.had_error = 1
                return wl_get_undef(wl_i32_type(self.context))
            mono_param_types.push(p_ty)
        else if pi < arg_count:
            mono_param_types.push(arg_tys.get(pi as i64))
        else:
            mono_param_types.push(self.type_fallback())
    let mono_ret_ty = if ret_type_node != 0: self.resolve_type(ret_type_node) else: self.type_fallback()
    if mono_ret_ty == 0:
        self.type_binding_syms = saved_bind_syms
        self.type_binding_types = saved_bind_tys
        self.type_bindings_len = saved_bind_len
        with_eprint("error: unknown type")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    let mono_ft = wl_function_type(mono_ret_ty, vec_data_i64(&mono_param_types), param_count, 0)
    let mono_fn = wl_add_function(self.llmod, mangled, mono_ft)
    self.apply_noalias_param_attrs(mono_fn, param_start, param_count)
    self.mono_values.insert(mono_key, mono_fn)
    self.mono_types.insert(mono_key, mono_ft)
    self.fn_values.insert(mono_sym, mono_fn)
    self.fn_fn_types.insert(mono_sym, mono_ft)

    // Build sema type bindings for each type param
    let tp_sema_tys: Vec[i32] = Vec.new()
    for ti in 0..tp_syms.len() as i32:
        let tp_sym = tp_syms.get(ti as i64)
        var sema_ty = 0
        for bi in 0..bind_syms.len() as i32:
            if bind_syms.get(bi as i64) == tp_sym:
                sema_ty = bind_sema_tys.get(bi as i64)
                break
        tp_sema_tys.push(sema_ty)

    // 1. Type-check body with concrete types
    let sig_idx = self.sema.check_fn_body_concrete(generic_node, tp_syms, tp_sema_tys, mono_sym)

    let saved_sema_named: Vec[i32] = Vec.new()
    let saved_sema_had: Vec[i32] = Vec.new()
    for ti2 in 0..tp_syms.len() as i32:
        let tp_sym2 = tp_syms.get(ti2 as i64)
        if self.sema.named_types.contains(tp_sym2):
            saved_sema_had.push(1)
            saved_sema_named.push(self.sema.named_types.get(tp_sym2).unwrap())
        else:
            saved_sema_had.push(0)
            saved_sema_named.push(0)
        self.sema.named_types.insert(tp_sym2, tp_sema_tys.get(ti2 as i64))

    // 2. Lower to MIR
    var mir_builder = MirBuilder.init(self.sema, self.pool, self.intern, mono_sym)
    let mir_body = lower_fn_with_sig(mir_builder, generic_node, sig_idx)

    // 3. Codegen via MIR (saves/restores all codegen state internally)
    self.gen_function_mir_mono(mono_sym, generic_node, mir_body)

    for ti3 in 0..tp_syms.len() as i32:
        let tp_sym3 = tp_syms.get(ti3 as i64)
        if saved_sema_had.get(ti3 as i64) == 1:
            self.sema.named_types.insert(tp_sym3, saved_sema_named.get(ti3 as i64))
        else:
            self.sema.named_types.remove(tp_sym3)

    self.type_binding_syms = saved_bind_syms
    self.type_binding_types = saved_bind_tys
    self.type_bindings_len = saved_bind_len

    let coerced = self.coerce_call_args_for_fn_value(mono_sym, mono_fn, args_start, 0, arg_vals, arg_count, "call " ++ mangled, call_node)
    wl_build_call(self.builder, mono_ft, mono_fn, vec_data_i64(&coerced), arg_count)

// ── Call expression ───────────────────────────────────────────────

fn Codegen.get_mutable_receiver_ptr(self: Codegen, recv_node: i32, recv_val: i64, recv_ty: i64) -> i64:
    let rk = self.pool.kind(recv_node)
    if rk == NodeKind.NK_IDENT:
        let sym = self.pool.get_data0(recv_node)
        let alloca = self.lookup_local_alloca(sym)
        if alloca != 0:
            let local_ty = self.lookup_local_type(sym)
            if local_ty != 0:
                if wl_get_type_kind(local_ty) == wl_pointer_type_kind():
                    return wl_build_load(self.builder, local_ty, alloca)
            return alloca
    if wl_get_type_kind(recv_ty) == wl_pointer_type_kind():
        return recv_val
    let alloca = wl_build_alloca(self.builder, recv_ty)
    wl_build_store(self.builder, recv_val, alloca)
    alloca

// ── While loop ────────────────────────────────────────────────────

fn Codegen.build_variant_payload_val(self: Codegen, payload_ty: i64, args: Vec[i64], arg_count: i32) -> i64:
    if arg_count <= 0:
        return wl_get_undef(wl_i32_type(self.context))
    if payload_ty == 0:
        return args.get(0)
    if arg_count == 1:
        return self.coerce_value_to_type(args.get(0), payload_ty)
    if wl_get_type_kind(payload_ty) == wl_struct_type_kind():
        var payload = wl_get_undef(payload_ty)
        let field_count = wl_count_struct_elem_types(payload_ty)
        var ai = 0
        while ai < arg_count and ai < field_count:
            let field_ty = wl_struct_get_type_at(payload_ty, ai)
            let coerced = self.coerce_value_to_type(args.get(ai as i64), field_ty)
            payload = wl_build_insert_value(self.builder, payload, coerced, ai)
            ai = ai + 1
        return payload
    self.coerce_value_to_type(args.get(0), payload_ty)

fn Codegen.gen_enum_variant_call_val(self: Codegen, enum_owner_sym: i32, variant_sym: i32, args: Vec[i64], arg_count: i32) -> i64:
    let variant_name = self.intern.resolve(variant_sym)
    for ei in 0..self.enum_llvm_types.len() as i32:
        let enum_ty = self.enum_llvm_types.get(ei as i64)
        let enum_sym_opt = self.enum_by_llvm.get(enum_ty)
        if enum_owner_sym > 0:
            if not enum_sym_opt.is_some() or enum_sym_opt.unwrap() != enum_owner_sym:
                continue
        let v_start = self.enum_variant_starts.get(ei as i64)
        let v_count = self.enum_variant_counts.get(ei as i64)
        for vi in 0..v_count:
            let stored_sym = self.enum_variant_names.get((v_start + vi) as i64)
            if stored_sym != variant_sym:
                let stored_name = self.intern.resolve(stored_sym)
                if stored_name != variant_name:
                    continue
            let alloca = wl_build_alloca(self.builder, enum_ty)
            wl_build_store(self.builder, self.build_default_value(enum_ty), alloca)
            let tag_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 0)
            var tag_val: i64 = 0
            var is_disc = false
            if enum_sym_opt.is_some():
                let de_opt = self.disc_enum_type_map.get(enum_sym_opt.unwrap())
                if de_opt.is_some():
                    is_disc = true
                    let de_idx = de_opt.unwrap()
                    let dv_start = self.disc_enum_variant_starts.get(de_idx as i64)
                    let disc_val = self.disc_enum_variant_values.get((dv_start + vi) as i64)
                    let repr_ty = self.disc_enum_repr_types.get(de_idx as i64)
                    tag_val = wl_const_int(repr_ty, disc_val as i64, 1)
            if not is_disc:
                tag_val = wl_const_int(wl_i32_type(self.context), vi as i64, 0)
            wl_build_store(self.builder, tag_val, tag_ptr)
            if arg_count > 0:
                let payload_ty = self.enum_variant_payloads.get((v_start + vi) as i64)
                let elem_count = wl_count_struct_elem_types(enum_ty)
                if payload_ty != 0 and elem_count > 1:
                    let payload = self.build_variant_payload_val(payload_ty, args, arg_count)
                    let payload_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 1)
                    let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
                    wl_build_store(self.builder, payload, cast_ptr)
            return wl_build_load(self.builder, enum_ty, alloca)
    0

// ── Struct literal ────────────────────────────────────────────────

fn Codegen.gen_closure(self: Codegen, node: i32) -> i64:
    // Closure: create an anonymous function and return fat pointer {fn_ptr, ctx_ptr}
    // Calling convention: fn(ctx_ptr, params...) -> ret_ty
    // NodeKind.NK_CLOSURE layout: d0=body, d1=extra_start, d2=param_count
    let body_node = self.pool.get_data0(node)
    let extra_start = self.pool.get_data1(node)
    let param_count = self.pool.get_data2(node)
    let ptr_ty = wl_ptr_type(self.context)
    let i32_ty = wl_i32_type(self.context)

    // Collect captured variables from enclosing scope
    // First, temporarily mark closure params so collect_captures skips them
    let param_syms: Vec[i32] = Vec.new()
    for i in 0..param_count:
        param_syms.push(self.pool.get_extra(extra_start + i * 2))
    let fresh_captures: Vec[i32] = Vec.new()
    self.async_block_captures = fresh_captures
    self.collect_captures(body_node)
    // Remove closure params from captures (they are not free variables)
    let captures: Vec[i32] = Vec.new()
    for ci in 0..self.async_block_captures.len() as i32:
        let sym = self.async_block_captures.get(ci as i64)
        var is_param = 0
        for pi in 0..param_count:
            if param_syms.get(pi as i64) == sym:
                is_param = 1
        if is_param == 0:
            captures.push(sym)
    let capture_count = captures.len() as i32

    // Determine if this is a non-escaping closure (reference capture)
    let is_ref_capture = self.pool.is_non_escaping_closure(node) == 1 and self.pool.is_move_closure(node) == 0

    // Build capture struct type from captured variable types
    let cap_types: Vec[i64] = Vec.new()
    for ci in 0..capture_count:
        let sym = captures.get(ci as i64)
        if is_ref_capture:
            cap_types.push(ptr_ty)
        else:
            let ty_opt = self.local_types.get(sym)
            if ty_opt.is_some():
                cap_types.push(ty_opt.unwrap() as i64)
            else:
                cap_types.push(i32_ty)
    // Collect original types for ref capture (needed inside closure body)
    let cap_orig_types: Vec[i64] = Vec.new()
    if is_ref_capture:
        for ci in 0..capture_count:
            let sym = captures.get(ci as i64)
            let ty_opt = self.local_types.get(sym)
            if ty_opt.is_some():
                cap_orig_types.push(ty_opt.unwrap() as i64)
            else:
                cap_orig_types.push(i32_ty)
    var cap_struct_type: i64 = 0
    if capture_count > 0:
        cap_struct_type = wl_struct_type(self.context, vec_data_i64(&cap_types), capture_count, 0)

    // Build parameter types: context ptr first, then user params
    let param_types: Vec[i64] = Vec.new()
    param_types.push(ptr_ty)
    for i in 0..param_count:
        let p_type = self.pool.get_extra(extra_start + i * 2 + 1)
        if p_type != 0:
            param_types.push(self.resolve_type(p_type))
        else:
            param_types.push(i32_ty)
    // Determine return type (infer from context or use i32)
    let ret_ty = i32_ty
    let fn_ty = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count + 1, 0)
    let closure_fn = wl_add_function(self.llmod, "__closure", fn_ty)
    // Save current state
    let saved_fn = self.current_function
    let saved_ret = self.current_ret_type
    let saved_bb = wl_get_insert_block(self.builder)
    let saved_allocas = self.local_allocas
    let saved_types = self.local_types
    let saved_muts = self.local_muts
    let saved_loops = self.capture_loop_state()
    let fresh_closure_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_closure_types: HashMap[i32, i64] = HashMap.new()
    let fresh_closure_muts: HashMap[i32, i32] = HashMap.new()
    self.local_allocas = fresh_closure_locals
    self.local_types = fresh_closure_types
    self.local_muts = fresh_closure_muts
    self.reset_loop_state()
    // Build closure body
    self.current_function = closure_fn
    self.current_ret_type = ret_ty
    let entry = wl_append_bb(self.context, closure_fn, "entry")
    wl_position_at_end(self.builder, entry)

    // Load captured values from context pointer (param 0)
    if capture_count > 0:
        let cap_ptr = wl_get_param(closure_fn, 0)
        for ci in 0..capture_count:
            let sym = captures.get(ci as i64)
            let cap_ty = cap_types.get(ci as i64)
            let indices: Vec[i64] = Vec.new()
            indices.push(wl_const_int(i32_ty, 0, 0))
            indices.push(wl_const_int(i32_ty, ci as i64, 0))
            let gep = wl_build_gep(self.builder, cap_struct_type, cap_ptr, vec_data_i64(&indices), 2)
            if is_ref_capture:
                // Reference capture: load the pointer to outer alloca, use directly
                let outer_ptr = wl_build_load(self.builder, ptr_ty, gep)
                let orig_ty = cap_orig_types.get(ci as i64)
                // Look up outer mutability
                let outer_mut_opt = saved_muts.get(sym)
                let outer_mut = if outer_mut_opt.is_some(): outer_mut_opt.unwrap() else: 0
                self.record_local(sym, outer_ptr, orig_ty, outer_mut)
            else:
                // Value capture: load value, create fresh alloca
                let loaded = wl_build_load(self.builder, cap_ty, gep)
                let alloca = self.create_entry_alloca(cap_ty)
                wl_build_store(self.builder, loaded, alloca)
                self.record_local(sym, alloca, cap_ty, 0)

    // Add params as locals (skip param 0 which is context ptr)
    for i in 0..param_count:
        let p_name = self.pool.get_extra(extra_start + i * 2)
        let param_val = wl_get_param(closure_fn, i + 1)
        let param_ty = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_ty)
        wl_build_store(self.builder, param_val, alloca)
        self.record_local(p_name, alloca, param_ty, 1)
    // ── MIR-based closure body compilation ──────────────────────
    // Save outer MIR state (gen_closure is called from within MIR codegen)
    let saved_mir_locals = self.mir_local_ptrs
    let saved_mir_local_types = self.mir_local_types
    let saved_mir_indirect_value_local_types = self.mir_indirect_value_local_types
    let saved_mir_bbs = self.mir_bb_values
    let saved_mir_unreachable = self.mir_default_unreachable_bbs
    let fresh_cl_mir_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_cl_mir_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_cl_mir_indirect_value_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_cl_mir_bbs: Vec[i64] = Vec.new()
    let fresh_cl_mir_unreachable: Vec[i64] = Vec.new()
    self.mir_local_ptrs = fresh_cl_mir_locals
    self.mir_local_types = fresh_cl_mir_local_types
    self.mir_indirect_value_local_types = fresh_cl_mir_indirect_value_local_types
    self.mir_bb_values = fresh_cl_mir_bbs
    self.mir_default_unreachable_bbs = fresh_cl_mir_unreachable

    // Create MirBuilder for the closure body
    var closure_builder = MirBuilder.init(self.sema, self.pool, self.intern, 0)
    // Set return type (try sema inference, default to i32)
    let ret_sema_ty = self.sema_type_of_node(body_node)
    if ret_sema_ty != 0 and ret_sema_ty != self.sema.ty_void:
        closure_builder.body.local_type_ids.set_i32(0, ret_sema_ty)
    else:
        closure_builder.body.local_type_ids.set_i32(0, self.sema.ty_i32)

    closure_builder.push_scope()

    // Register captures as MIR locals (locals 1..capture_count)
    for cl_ci in 0..capture_count:
        let cl_cap_sym = captures.get(cl_ci as i64)
        var cl_cap_sema_ty = self.sema.ty_i32 as i32
        let cl_cap_sema_opt = self.local_sema_types.get(cl_cap_sym)
        if cl_cap_sema_opt.is_some():
            cl_cap_sema_ty = cl_cap_sema_opt.unwrap()
        let cl_cap_local = closure_builder.body.new_local(cl_cap_sema_ty, 0, cl_cap_sym, 1)
        closure_builder.bind_local(cl_cap_sym, cl_cap_local)

    // Register params as MIR locals (locals capture_count+1..)
    for cl_pi in 0..param_count:
        let cl_p_name = self.pool.get_extra(extra_start + cl_pi * 2)
        let cl_p_type_node = self.pool.get_extra(extra_start + cl_pi * 2 + 1)
        var cl_p_sema_ty = self.sema.ty_i32 as i32
        if cl_p_type_node > 0:
            if self.sema.typed_expr_types.contains(cl_p_type_node):
                let cl_tt = self.sema.typed_expr_types.get(cl_p_type_node).unwrap()
                if cl_tt > 0:
                    cl_p_sema_ty = cl_tt
            if cl_p_sema_ty == self.sema.ty_i32:
                let cl_pk = self.pool.kind(cl_p_type_node)
                if cl_pk == NodeKind.NK_TYPE_NAMED or cl_pk == NodeKind.NK_IDENT:
                    let cl_type_sym = self.pool.get_data0(cl_p_type_node)
                    let cl_prim = self.sema.primitive_type_by_sym(cl_type_sym)
                    if cl_prim != 0:
                        cl_p_sema_ty = cl_prim as i32
                    else if self.sema.named_types.contains(cl_type_sym):
                        cl_p_sema_ty = self.sema.named_types.get(cl_type_sym).unwrap()
        let cl_p_local = closure_builder.body.new_local(cl_p_sema_ty, 1, cl_p_name, 1)
        closure_builder.bind_local(cl_p_name, cl_p_local)

    closure_builder.expected_type = closure_builder.body.local_type_ids.get(0)

    // Lower the closure body expression to MIR
    let cl_result = closure_builder.lower_expr(body_node)
    let cl_ret_place = closure_builder.place_for_local(0)
    closure_builder.assign_operand_to_place(cl_ret_place, cl_result, self.pool.get_end(body_node))
    closure_builder.pop_scope_inline()
    closure_builder.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)
    let closure_body = closure_builder.body

    // Set up return alloca (MIR local 0)
    let cl_ret_alloca = self.create_entry_alloca(ret_ty)
    self.mir_local_ptrs.insert(0, cl_ret_alloca)
    self.mir_local_types.insert(0, ret_ty)

    // Map capture MIR locals to existing LLVM allocas
    for cl_mi in 0..capture_count:
        let cl_m_sym = captures.get(cl_mi as i64)
        let cl_m_local_id = cl_mi + 1
        let cl_m_alloca_opt = self.local_allocas.get(cl_m_sym)
        if cl_m_alloca_opt.is_some():
            self.mir_local_ptrs.insert(cl_m_local_id, cl_m_alloca_opt.unwrap())
            let cl_m_ty_opt = self.local_types.get(cl_m_sym)
            if cl_m_ty_opt.is_some():
                self.mir_local_types.insert(cl_m_local_id, cl_m_ty_opt.unwrap())

    // Map param MIR locals to existing LLVM allocas
    for cl_pmi in 0..param_count:
        let cl_pm_name = self.pool.get_extra(extra_start + cl_pmi * 2)
        let cl_pm_local_id = capture_count + cl_pmi + 1
        let cl_pm_alloca_opt = self.local_allocas.get(cl_pm_name)
        if cl_pm_alloca_opt.is_some():
            self.mir_local_ptrs.insert(cl_pm_local_id, cl_pm_alloca_opt.unwrap())
            let cl_pm_ty_opt = self.local_types.get(cl_pm_name)
            if cl_pm_ty_opt.is_some():
                self.mir_local_types.insert(cl_pm_local_id, cl_pm_ty_opt.unwrap())

    // Pre-populate globals
    for cl_gli in 0..closure_body.local_names.len() as i32:
        let cl_gl_name = closure_body.local_names.get(cl_gli as i64)
        if cl_gl_name != 0:
            let cl_gl_mc = self.module_constants.get(cl_gl_name)
            if cl_gl_mc.is_some():
                self.mir_local_ptrs.insert(cl_gli, cl_gl_mc.unwrap() as i64)

    // Create LLVM basic blocks for MIR blocks
    for cl_bb in 0..closure_body.block_count():
        let cl_bb_name = f"mir.bb{cl_bb}"
        let cl_llbb = wl_append_bb(self.context, closure_fn, cl_bb_name)
        self.mir_bb_values.push(cl_llbb)

    // Branch from entry to first MIR BB
    if self.mir_bb_values.len() as i32 > 0:
        wl_build_br(self.builder, self.mir_bb_values.get(0))
    else:
        let _ = wl_build_ret(self.builder, wl_const_int(ret_ty, 0, 0))

    // Emit MIR statements and terminators
    for cl_bb in 0..closure_body.block_count():
        if cl_bb < 0 or cl_bb >= self.mir_bb_values.len() as i32:
            continue
        let cl_llbb = self.mir_bb_values.get(cl_bb as i64)
        wl_position_at_end(self.builder, cl_llbb)
        let cl_stmt_start = closure_body.bb_stmt_starts.get(cl_bb as i64)
        let cl_stmt_count = closure_body.bb_stmt_counts.get(cl_bb as i64)
        for cl_si in 0..cl_stmt_count:
            let cl_stmt_id = cl_stmt_start + cl_si
            if not self.mir_emit_stmt(closure_body, cl_stmt_id):
                if wl_get_bb_terminator(cl_llbb) == 0:
                    wl_build_unreachable(self.builder)
        if wl_get_bb_terminator(cl_llbb) == 0:
            if not self.mir_emit_term(closure_body, cl_bb):
                if wl_get_bb_terminator(cl_llbb) == 0:
                    let _ = wl_build_ret(self.builder, wl_const_int(ret_ty, 0, 0))

    // Restore outer MIR state
    self.mir_local_ptrs = saved_mir_locals
    self.mir_local_types = saved_mir_local_types
    self.mir_indirect_value_local_types = saved_mir_indirect_value_local_types
    self.mir_bb_values = saved_mir_bbs
    self.mir_default_unreachable_bbs = saved_mir_unreachable
    // Restore state
    self.current_function = saved_fn
    self.current_ret_type = saved_ret
    wl_position_at_end(self.builder, saved_bb)
    self.local_allocas = saved_allocas
    self.local_types = saved_types
    self.local_muts = saved_muts
    self.restore_loop_state(saved_loops)

    // Build capture struct on stack and store captured values
    var ctx_ptr = wl_const_null(ptr_ty)
    if capture_count > 0:
        let cap_alloca = wl_build_alloca(self.builder, cap_struct_type)
        for ci in 0..capture_count:
            let sym = captures.get(ci as i64)
            let cap_ty = cap_types.get(ci as i64)
            let alloca_opt = self.local_allocas.get(sym)
            if alloca_opt.is_some():
                let indices: Vec[i64] = Vec.new()
                indices.push(wl_const_int(i32_ty, 0, 0))
                indices.push(wl_const_int(i32_ty, ci as i64, 0))
                let gep = wl_build_gep(self.builder, cap_struct_type, cap_alloca, vec_data_i64(&indices), 2)
                if is_ref_capture:
                    // Store pointer to outer alloca (not the value)
                    wl_build_store(self.builder, alloca_opt.unwrap() as i64, gep)
                else:
                    // Store the value
                    let val = wl_build_load(self.builder, cap_ty, alloca_opt.unwrap() as i64)
                    wl_build_store(self.builder, val, gep)
        ctx_ptr = cap_alloca

    // Build fat pointer {fn_ptr, ctx_ptr}
    let fat_types: Vec[i64] = Vec.new()
    fat_types.push(ptr_ty)
    fat_types.push(ptr_ty)
    let fat_ty = wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)
    var fat_val = wl_get_undef(fat_ty)
    fat_val = wl_build_insert_value(self.builder, fat_val, closure_fn, 0)
    fat_val = wl_build_insert_value(self.builder, fat_val, ctx_ptr, 1)
    fat_val

// ── Pipeline ──────────────────────────────────────────────────────

fn Codegen.ensure_async_runtime_declared(self: Codegen):
    let i32_ty = wl_i32_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let void_ty = wl_void_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)

    // void with_runtime_init(void)
    if wl_get_named_function(self.llmod, "with_runtime_init") == 0:
        let no_params: Vec[i64] = Vec.new()
        let ft = wl_function_type(void_ty, vec_data_i64(&no_params), 0, 0)
        wl_add_function(self.llmod, "with_runtime_init", ft)

    // void with_runtime_run(void)
    if wl_get_named_function(self.llmod, "with_runtime_run") == 0:
        let no_params: Vec[i64] = Vec.new()
        let ft = wl_function_type(void_ty, vec_data_i64(&no_params), 0, 0)
        wl_add_function(self.llmod, "with_runtime_run", ft)

    // void with_runtime_shutdown(void)
    if wl_get_named_function(self.llmod, "with_runtime_shutdown") == 0:
        let no_params: Vec[i64] = Vec.new()
        let ft = wl_function_type(void_ty, vec_data_i64(&no_params), 0, 0)
        wl_add_function(self.llmod, "with_runtime_shutdown", ft)

    // i32 with_fiber_spawn(entry: ptr, arg: ptr, result_buf: ptr, result_size: i32, stack_size: i32)
    if wl_get_named_function(self.llmod, "with_fiber_spawn") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i32_ty)
        params.push(i32_ty)
        let ft = wl_function_type(i32_ty, vec_data_i64(&params), 5, 0)
        wl_add_function(self.llmod, "with_fiber_spawn", ft)

    // void with_fiber_await(fiber_id: i32)
    if wl_get_named_function(self.llmod, "with_fiber_await") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(i32_ty)
        let ft = wl_function_type(void_ty, vec_data_i64(&params), 1, 0)
        wl_add_function(self.llmod, "with_fiber_await", ft)

    // i32 with_fiber_cancel(task_id: i32) -> i32
    if wl_get_named_function(self.llmod, "with_fiber_cancel") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(i32_ty)
        let ft = wl_function_type(i32_ty, vec_data_i64(&params), 1, 0)
        wl_add_function(self.llmod, "with_fiber_cancel", ft)

    // void with_fiber_set_result(value: i64)
    if wl_get_named_function(self.llmod, "with_fiber_set_result") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(i64_ty)
        let ft = wl_function_type(void_ty, vec_data_i64(&params), 1, 0)
        wl_add_function(self.llmod, "with_fiber_set_result", ft)

    // void with_fiber_yield(void)
    if wl_get_named_function(self.llmod, "with_fiber_yield") == 0:
        let no_params: Vec[i64] = Vec.new()
        let ft = wl_function_type(void_ty, vec_data_i64(&no_params), 0, 0)
        wl_add_function(self.llmod, "with_fiber_yield", ft)

    // i32 with_fiber_select(ids: ptr, count: i32, result_out: ptr) -> i32
    if wl_get_named_function(self.llmod, "with_fiber_select") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(i32_ty)
        params.push(ptr_ty)
        let ft = wl_function_type(i32_ty, vec_data_i64(&params), 3, 0)
        wl_add_function(self.llmod, "with_fiber_select", ft)

    self.uses_async = true

fn Codegen.ensure_malloc_declared(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "malloc")
    if existing != 0: return existing
    let ptr_ty = wl_ptr_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let params: Vec[i64] = Vec.new()
    params.push(i64_ty)
    let ft = wl_function_type(ptr_ty, vec_data_i64(&params), 1, 0)
    wl_add_function(self.llmod, "malloc", ft)

fn Codegen.pack_result_to_i64(self: Codegen, val: i64, val_ty: i64) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let void_ty = wl_void_type(self.context)
    if val_ty == void_ty:
        return wl_const_int(i64_ty, 0, 0)
    if val_ty == i64_ty:
        return val
    let kind = wl_get_type_kind(val_ty)
    // Integer types: zext to i64
    if kind == wl_integer_type_kind():
        return wl_build_zext(self.builder, val, i64_ty)
    // Pointer types: ptrtoint
    if kind == wl_pointer_type_kind():
        return wl_build_ptr_to_int(self.builder, val, i64_ty)
    // Fallback: bitcast via alloca
    let alloca = wl_build_alloca(self.builder, i64_ty)
    wl_build_store(self.builder, val, alloca)
    wl_build_load(self.builder, i64_ty, alloca)

fn Codegen.unpack_result_from_i64(self: Codegen, val: i64, target_ty: i64) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    if target_ty == i64_ty:
        return val
    if target_ty == i32_ty:
        return wl_build_trunc(self.builder, val, i32_ty)
    let kind = wl_get_type_kind(target_ty)
    if kind == wl_integer_type_kind():
        return wl_build_trunc(self.builder, val, target_ty)
    if kind == wl_pointer_type_kind():
        return wl_build_int_to_ptr(self.builder, val, target_ty)
    // Fallback: bitcast via alloca
    let alloca = wl_build_alloca(self.builder, i64_ty)
    wl_build_store(self.builder, val, alloca)
    wl_build_load(self.builder, target_ty, alloca)

// ── Async function declaration ────────────────────────────────────

fn Codegen.declare_async_function(self: Codegen, fn_node: i32):
    self.ensure_async_runtime_declared()

    let name_sym = self.pool.get_data0(fn_node)
    if name_sym == 0: return

    let meta = self.pool.find_fn_meta(fn_node)
    if meta < 0: return

    let i32_ty = wl_i32_type(self.context)

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)

    // Resolve return type (default to i32 when no annotation, matching non-async functions)
    let ret_ty = if ret_type_node != 0: self.resolve_type(ret_type_node) else: i32_ty
    self.async_fn_ret_types.insert(name_sym, ret_ty)
    let cc_name = self.fn_callconv_name(meta)

    // Resolve param types
    let param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        var p_ty = self.resolve_type(p_type_node)
        if p_ty == 0:
            p_ty = i32_ty
        param_types.push(p_ty)

    let spawn_fn_type = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count, 0)
    var effective_name = self.function_symbol_name(name_sym)
    if self.module_object_mode != 0:
        if not (cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:"):
            effective_name = self.current_decl_module_link_name(effective_name)
    let existing_spawn = wl_get_named_function(self.llmod, effective_name)
    let spawn_fn =
        if existing_spawn != 0:
            existing_spawn
        else:
            wl_add_function(self.llmod, effective_name, spawn_fn_type)
    self.apply_noalias_param_attrs(spawn_fn, param_start, param_count)
    self.fn_values.insert(name_sym, spawn_fn)
    self.fn_fn_types.insert(name_sym, spawn_fn_type)
    if self.current_decl_is_imported_module_symbol():
        return

    // Keep only the metadata the current async spawn path still consumes.
    var args_struct_type = wl_struct_type(self.context, vec_data_i64(&param_types), param_count, 0)
    self.async_fn_args_struct_types.insert(name_sym, args_struct_type)

// ── Async expressions ─────────────────────────────────────────────

fn Codegen.collect_captures(self: Codegen, node: i32):
    // Walk the AST and collect captured locals into self.async_block_captures.
    if node == 0: return
    let kind = self.pool.kind(node)
    if kind == NodeKind.NK_IDENT:
        let sym = self.pool.get_data0(node)
        if self.local_allocas.get(sym).is_some():
            for ci in 0..self.async_block_captures.len() as i32:
                if self.async_block_captures.get(ci as i64) == sym:
                    return
            self.async_block_captures.push(sym)
        return
    if kind == NodeKind.NK_BINARY:
        self.collect_captures(self.pool.get_data1(node))
        self.collect_captures(self.pool.get_data2(node))
        return
    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NodeKind.NK_UNARY:
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NodeKind.NK_CALL:
        self.collect_captures(self.pool.get_data0(node))
        let args_start = self.pool.get_data1(node)
        let arg_count = self.pool.get_data2(node)
        for ai in 0..arg_count:
            self.collect_captures(self.pool.get_extra(args_start + ai))
        return
    if kind == NodeKind.NK_BLOCK:
        let extra_start = self.pool.get_data0(node)
        let stmt_count = self.pool.get_data1(node)
        for si in 0..stmt_count:
            self.collect_captures(self.pool.get_extra(extra_start + si))
        self.collect_captures(self.pool.get_data2(node))
        return
    if kind == NodeKind.NK_LABEL:
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NodeKind.NK_GOTO:
        return
    if kind == NodeKind.NK_IF_EXPR:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        self.collect_captures(self.pool.get_data2(node))
        return
    if kind == NodeKind.NK_LET_BINDING:
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NodeKind.NK_RETURN:
        self.collect_captures(self.pool.get_data0(node))
        return
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_SPAWN:
        self.collect_captures(self.pool.get_data0(node))
        return
    if kind == NodeKind.NK_FIELD_ACCESS:
        self.collect_captures(self.pool.get_data0(node))
        return
    if kind == NodeKind.NK_CAST:
        self.collect_captures(self.pool.get_data0(node))
        return
    if kind == NodeKind.NK_WHILE:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NodeKind.NK_DO_WHILE:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NodeKind.NK_FOR:
        self.collect_captures(self.pool.get_data1(node))
        self.collect_captures(self.pool.get_data2(node))
        return
    if kind == NodeKind.NK_ASSIGN:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NodeKind.NK_TUPLE:
        let extra_start = self.pool.get_data0(node)
        let count = self.pool.get_data1(node)
        for ti in 0..count:
            self.collect_captures(self.pool.get_extra(extra_start + ti))
        return
    if kind == NodeKind.NK_INDEX:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        return

fn Codegen.decode_string_escapes(self: Codegen, text: str) -> str:
    var out = ""
    let len = text.len() as i32
    var i = 0
    while i < len:
        let ch = text[i]
        if ch == 92 and i + 1 < len:
            i = i + 1
            let esc = text[i]
            if esc == 120 and i + 2 < len:
                let hi = self.hex_digit_value(text[i + 1])
                let lo = self.hex_digit_value(text[i + 2])
                if hi >= 0 and lo >= 0:
                    out = out ++ str_from_byte(hi * 16 + lo)
                    i = i + 2
                else:
                    out = out ++ text.slice(i as i64, i as i64 + 1)
            else if esc == 110:
                out = out ++ "\n"
            else if esc == 116:
                out = out ++ "\t"
            else if esc == 114:
                out = out ++ "\r"
            else if esc == 48:
                out = out ++ str_from_byte(0)
            else if esc == 92:
                out = out ++ "\\"
            else if esc == 34:
                out = out ++ "\""
            else:
                out = out ++ text.slice(i as i64, i as i64 + 1)
        else:
            out = out ++ text.slice(i as i64, i as i64 + 1)
        i = i + 1
    out

fn Codegen.hex_digit_value(self: Codegen, ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return ch - 48
    if ch >= 97 and ch <= 102:
        return ch - 87
    if ch >= 65 and ch <= 70:
        return ch - 55
    -1

fn Codegen.gen_string_literal_raw(self: Codegen, text: str) -> i64:
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some():
        with_eprint("warning: [string-lit] str struct type not found")
        return wl_get_undef(wl_i32_type(self.context))
    let str_type = self.struct_llvm_types.get(st_opt.unwrap() as i64)
    let global_str = wl_build_global_string_ptr(self.builder, text)
    let alloca = wl_build_alloca(self.builder, str_type)
    let ptr_gep = wl_build_struct_gep(self.builder, str_type, alloca, 0)
    wl_build_store(self.builder, global_str, ptr_gep)
    let len_gep = wl_build_struct_gep(self.builder, str_type, alloca, 1)
    wl_build_store(self.builder, wl_const_int(wl_i64_type(self.context), text.len(), 1), len_gep)
    wl_build_load(self.builder, str_type, alloca)

fn Codegen.gen_src_intrinsic(self: Codegen, node: i32) -> i64:
    let span_start = self.pool.get_start(node)
    // Compute line and column from byte offset
    var line = 1
    var col = 1
    var i = 0
    while i < span_start and i < self.source_text.len() as i32:
        if self.source_text.byte_at(i as i64) == 10:
            line = line + 1
            col = 1
        else:
            col = col + 1
        i = i + 1
    let loc_str = f"{self.source_file}:{line}:{col}"
    self.gen_string_literal_raw(loc_str)

fn Codegen.gen_embed_file(self: Codegen, node: i32) -> i64:
    let args_start = self.pool.get_data1(node)
    let arg_node = self.pool.get_extra(args_start)
    let path_value = self.try_eval_const_string(arg_node, self.current_decl_source_file, 0)
    if not path_value.ok:
        with_eprint("error: embed_file() argument must be a compile-time string")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    let base_path = if self.current_decl_source_file.len() > 0 and self.current_decl_source_file != "<unknown>":
        self.current_decl_source_file
    else:
        self.source_file
    let path = self.resolve_embed_file_path(base_path, path_value.text)
    if with_fs_file_exists(path) == 0:
        with_eprint("error: embed_file: could not read '" ++ path ++ "'")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    self.gen_string_literal_raw(with_fs_read_file(path))

fn Codegen.extract_str_ptr(self: Codegen, str_val: i64) -> i64:
    // Extract ptr (field 0) from str struct
    wl_build_extract_value(self.builder, str_val, 0)

fn Codegen.is_str_type(self: Codegen, ty: i64) -> bool:
    if wl_get_type_kind(ty) != wl_struct_type_kind(): return false
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some(): return false
    let str_type = self.struct_llvm_types.get(st_opt.unwrap() as i64)
    ty == str_type

fn Codegen.build_str_value(self: Codegen, ptr: i64, len: i64) -> i64:
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some():
        with_eprint("warning: [build-str] str struct type not found")
        return wl_get_undef(wl_i32_type(self.context))
    let str_type = self.struct_llvm_types.get(st_opt.unwrap() as i64)
    var result = wl_get_undef(str_type)
    result = wl_build_insert_value(self.builder, result, ptr, 0)
    result = wl_build_insert_value(self.builder, result, len, 1)
    result

fn Codegen.coerce_ptr_to_str(self: Codegen, ptr_val: i64) -> i64:
    // c_import return coercion: *void / *u8 → str with null safety.
    // Calls with_str_from_cstr which handles null internally (returns {null,0}).
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some():
        return self.build_str_value(ptr_val, wl_const_int(wl_i64_type(self.context), 0, 0))
    let str_type = self.struct_llvm_types.get(st_opt.unwrap() as i64)
    var fn_val = wl_get_named_function(self.llmod, "with_str_from_cstr")
    if fn_val == 0:
        // Declare with_str_from_cstr if not already in the module
        let ptr_ty = wl_ptr_type(self.context)
        var param_types: Vec[i64] = Vec.new()
        param_types.push(ptr_ty)
        let fn_ty = wl_function_type(str_type, vec_data_i64(&param_types), 1, 0)
        fn_val = wl_add_function(self.llmod, "with_str_from_cstr", fn_ty)
    if fn_val == 0:
        return self.build_str_value(ptr_val, wl_const_int(wl_i64_type(self.context), 0, 0))
    let fn_type = wl_global_get_value_type(fn_val)
    var args: Vec[i64] = Vec.new()
    args.push(ptr_val)
    wl_build_call(self.builder, fn_type, fn_val, vec_data_i64(&args), 1)

fn Codegen.ensure_c_fn(self: Codegen, name: str, ret_ty: i64, param_count: i32) -> i64:
    let existing = wl_get_named_function(self.llmod, name)
    if existing != 0: return existing
    let fn_ty = self.get_runtime_fn_type(name, ret_ty, param_count)
    wl_add_function(self.llmod, name, fn_ty)

fn Codegen.get_runtime_fn_type(self: Codegen, name: str, ret_ty: i64, param_count: i32) -> i64:
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    let str_type = if st_opt.is_some(): self.struct_llvm_types.get(st_opt.unwrap() as i64) else: wl_i64_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let params: Vec[i64] = Vec.new()
    if name == "with_str_contains" or
       name == "with_str_starts_with" or
       name == "with_str_ends_with" or
       name == "with_str_index_of" or
       name == "with_str_trim" or
       name == "with_str_to_upper" or
       name == "with_str_to_lower" or
       name == "with_str_replace":
        for i in 0..param_count:
            params.push(str_type)
    else if name == "with_str_byte_at":
        params.push(str_type)
        params.push(i64_ty)
    else if name == "with_str_repeat":
        params.push(str_type)
        params.push(i64_ty)
    else:
        for i in 0..param_count:
            params.push(i64_ty)
    wl_function_type(ret_ty, vec_data_i64(&params), param_count, 0)

// ── VecIter.next() codegen intrinsic ──────────────────────────────
// VecIter[T] = { data_ptr: i64, len: i64, idx: i64 }
// next() returns Option[T]: checks idx < len, loads T from data_ptr, increments idx.

fn Codegen.ensure_vec_runtime_fn(self: Codegen, name: str, ret_ty: i64, param_count: i32) -> i64:
    let existing = wl_get_named_function(self.llmod, name)
    if existing != 0: return existing
    let fn_ty = self.get_vec_fn_type(name, ret_ty, param_count)
    wl_add_function(self.llmod, name, fn_ty)

fn Codegen.get_vec_fn_type(self: Codegen, name: str, ret_ty: i64, param_count: i32) -> i64:
    let ptr_ty = wl_ptr_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let params: Vec[i64] = Vec.new()
    // First param is always ptr (to Vec struct)
    params.push(ptr_ty)
    var i = 1
    while i < param_count:
        if i == 1 and name == "with_vec_push":
            params.push(ptr_ty)
        else:
            params.push(i64_ty)
        i = i + 1
    wl_function_type(ret_ty, vec_data_i64(&params), param_count, 0)

// ── HashMap method dispatch ───────────────────────────────────────

fn Codegen.ensure_hm_fn(self: Codegen, name: str, ret_ty: i64) -> i64:
    let existing = wl_get_named_function(self.llmod, name)
    if existing != 0: return existing
    let ptr_ty = wl_ptr_type(self.context)
    let params: Vec[i64] = Vec.new()
    params.push(ptr_ty)
    let fn_ty = wl_function_type(ret_ty, vec_data_i64(&params), 1, 0)
    wl_add_function(self.llmod, name, fn_ty)

fn Codegen.make_ptr_vec(self: Codegen) -> Vec[i64]:
    let v: Vec[i64] = Vec.new()
    v.push(wl_ptr_type(self.context))
    v

// ── transmute intrinsic ───────────────────────────────────────────

fn Codegen.gen_transmute(self: Codegen, node: i32, body: MirBody, args_id: i32) -> i64:
    // transmute[T](value) — reinterpret bits as type T
    let callee_node = self.pool.get_data0(node)
    let callee_kind = self.pool.kind(callee_node)
    if callee_kind != NodeKind.NK_TYPE_GENERIC and callee_kind != NodeKind.NK_INDEX:
        return wl_get_undef(wl_i32_type(self.context))
    let tp_node = if callee_kind == NodeKind.NK_TYPE_GENERIC:
        let tp_start = self.pool.get_data1(callee_node)
        let tp_count = self.pool.get_data2(callee_node)
        if tp_count == 0:
            return wl_get_undef(wl_i32_type(self.context))
        self.pool.get_extra(tp_start)
    else:
        self.pool.get_data1(callee_node)
    let target_ty = self.resolve_type(tp_node)
    if target_ty == 0:
        return wl_get_undef(wl_i32_type(self.context))
    // Evaluate the argument
    let mir_start = body.call_arg_starts.get(args_id as i64)
    let mir_count = body.call_arg_counts.get(args_id as i64)
    if mir_count == 0:
        return wl_get_undef(target_ty)
    let arg_op = body.call_arg_operands.get(mir_start as i64)
    let arg_val = self.mir_eval_operand(body, arg_op, 0)
    // Use alloca + store + load to reinterpret the bits
    let src_alloca = self.create_entry_alloca(wl_type_of(arg_val))
    wl_build_store(self.builder, arg_val, src_alloca)
    wl_build_load(self.builder, target_ty, src_alloca)

// ── sizeof/alignof intrinsics ─────────────────────────────────────

fn Codegen.gen_sizeof_alignof(self: Codegen, name_sym: i32, node: i32) -> i64:
    let callee_node = self.pool.get_data0(node)
    let callee_kind = self.pool.kind(callee_node)
    if callee_kind != NodeKind.NK_TYPE_GENERIC and callee_kind != NodeKind.NK_INDEX:
        return wl_const_int(wl_i64_type(self.context), 0, 0)
    let tp_node = if callee_kind == NodeKind.NK_TYPE_GENERIC:
        let tp_start = self.pool.get_data1(callee_node)
        let tp_count = self.pool.get_data2(callee_node)
        if tp_count == 0:
            return wl_const_int(wl_i64_type(self.context), 0, 0)
        self.pool.get_extra(tp_start)
    else:
        self.pool.get_data1(callee_node)
    let type_val = self.resolve_type(tp_node)
    if type_val == 0:
        return wl_const_int(wl_i64_type(self.context), 0, 0)
    let dl = wl_get_module_data_layout(self.llmod)
    if name_sym == self.sym_sizeof or name_sym == self.sym_size_of:
        return wl_const_int(wl_i64_type(self.context), wl_abi_size_of(dl, type_val), 0)
    wl_const_int(wl_i64_type(self.context), wl_abi_align_of(dl, type_val) as i64, 0)

// ── nameof/type_name intrinsic ─────────────────────────────────────

fn Codegen.gen_nameof(self: Codegen, node: i32) -> i64:
    let callee_node = self.pool.get_data0(node)
    let callee_kind = self.pool.kind(callee_node)
    if callee_kind != NodeKind.NK_TYPE_GENERIC and callee_kind != NodeKind.NK_INDEX:
        return self.gen_string_literal_raw("")
    let tp_node = if callee_kind == NodeKind.NK_TYPE_GENERIC:
        let tp_start = self.pool.get_data1(callee_node)
        let tp_count = self.pool.get_data2(callee_node)
        if tp_count == 0:
            return self.gen_string_literal_raw("")
        self.pool.get_extra(tp_start)
    else:
        self.pool.get_data1(callee_node)
    // Get the type name from the AST node
    var type_name = ""
    if self.pool.kind(tp_node) == NodeKind.NK_IDENT or self.pool.kind(tp_node) == NodeKind.NK_TYPE_NAMED:
        type_name = self.intern.resolve(self.pool.get_data0(tp_node))
    else:
        type_name = "unknown"
    self.gen_string_literal_raw(type_name)

// ── Async function spawn codegen ──────────────────────────────────

fn Codegen.emit_async_fn_spawn(self: Codegen, fn_sym: i32, callee: i64, call_ft: i64, args: Vec[i64], dest_place: i32, body: MirBody, next_bb: i32) -> bool:
    let ctx = self.context
    let ptr_ty = wl_ptr_type(ctx)
    let i32_ty = wl_i32_type(ctx)
    let i64_ty = wl_i64_type(ctx)
    let void_ty = wl_void_type(ctx)
    let arg_count = args.len() as i32
    // Use actual async fn return type for result buffer sizing.
    // call_ft is the spawn wrapper type (returns i32), not the real return type.
    var ret_ty = wl_get_return_type(call_ft)
    let actual_ret_opt = self.async_fn_ret_types.get(fn_sym)
    if actual_ret_opt.is_some():
        ret_ty = actual_ret_opt.unwrap() as i64

    // 1. Build args struct type: { arg0_ty, arg1_ty, ... }
    let arg_types: Vec[i64] = Vec.new()
    for ai in 0..arg_count:
        arg_types.push(wl_type_of(args.get(ai as i64)))
    let args_struct_ty = if arg_count > 0:
        wl_struct_type(ctx, vec_data_i64(&arg_types), arg_count, 0)
    else:
        wl_struct_type(ctx, 0, 0, 0)

    // 2. Heap-allocate args struct
    let args_size = if arg_count > 0: wl_abi_size_of(wl_get_module_data_layout(self.llmod),args_struct_ty) else: 8
    let alloc_fn_name = "with_alloc"
    var alloc_fn = wl_get_named_function(self.llmod, alloc_fn_name)
    if alloc_fn == 0:
        let alloc_params: Vec[i64] = Vec.new()
        alloc_params.push(i64_ty)
        let alloc_ft = wl_function_type(ptr_ty, vec_data_i64(&alloc_params), 1, 0)
        alloc_fn = wl_add_function(self.llmod, alloc_fn_name, alloc_ft)
    let alloc_ft = wl_global_get_value_type(alloc_fn)
    let alloc_args: Vec[i64] = Vec.new()
    alloc_args.push(wl_const_int(i64_ty, args_size, 0))
    let env_ptr = wl_build_call(self.builder, alloc_ft, alloc_fn, vec_data_i64(&alloc_args), 1)

    // 3. Store args into heap struct
    for ai in 0..arg_count:
        let field_ptr = wl_build_struct_gep(self.builder, args_struct_ty, env_ptr, ai)
        wl_build_store(self.builder, args.get(ai as i64), field_ptr)

    // 4. Heap-allocate result buffer
    let result_size = if ret_ty != void_ty: wl_abi_size_of(wl_get_module_data_layout(self.llmod),ret_ty) else: 0
    let rbuf_alloc_args: Vec[i64] = Vec.new()
    rbuf_alloc_args.push(wl_const_int(i64_ty, if result_size > 0: result_size else: 1, 0))
    let result_buf = wl_build_call(self.builder, alloc_ft, alloc_fn, vec_data_i64(&rbuf_alloc_args), 1)

    // 5. Get or generate trampoline
    var trampoline = 0 as i64
    if self.async_trampolines.contains(fn_sym):
        trampoline = self.async_trampolines.get(fn_sym).unwrap() as i64
    else:
        trampoline = self.generate_async_trampoline(fn_sym, callee, call_ft, args_struct_ty, arg_types)
        self.async_trampolines.insert(fn_sym, trampoline)

    // 6. Call with_fiber_spawn(trampoline, env, result_buf, result_size, stack_size)
    let spawn_fn_name = "with_fiber_spawn"
    var spawn_fn = wl_get_named_function(self.llmod, spawn_fn_name)
    if spawn_fn == 0:
        let spawn_params: Vec[i64] = Vec.new()
        spawn_params.push(ptr_ty)   // entry fn
        spawn_params.push(ptr_ty)   // arg
        spawn_params.push(ptr_ty)   // result_buf
        spawn_params.push(i32_ty)   // result_size
        spawn_params.push(i32_ty)   // stack_size
        let spawn_ft = wl_function_type(i32_ty, vec_data_i64(&spawn_params), 5, 0)
        spawn_fn = wl_add_function(self.llmod, spawn_fn_name, spawn_ft)
    let spawn_ft = wl_global_get_value_type(spawn_fn)
    let spawn_args: Vec[i64] = Vec.new()
    spawn_args.push(trampoline)
    spawn_args.push(env_ptr)
    spawn_args.push(result_buf)
    spawn_args.push(wl_const_int(i32_ty, result_size, 0))
    // Use @[stack_size(N)] if annotated, else: 0 (runtime default)
    var spawn_stack_size = 0
    if self.sema.fn_stack_sizes.contains(fn_sym):
        spawn_stack_size = self.sema.fn_stack_sizes.get(fn_sym).unwrap()
    spawn_args.push(wl_const_int(i32_ty, spawn_stack_size as i64, 0))
    let fiber_id = wl_build_call(self.builder, spawn_ft, spawn_fn, vec_data_i64(&spawn_args), 5)

    // 7. Construct Task { fiber_id, result_buf }
    if dest_place >= 0 and dest_place < body.place_locals.len() as i32:
        let dst_local = body.place_locals.get(dest_place as i64)
        // Task = { i32, ptr }
        let task_fields: Vec[i64] = Vec.new()
        task_fields.push(i32_ty)
        task_fields.push(ptr_ty)
        let task_ty = wl_struct_type(ctx, vec_data_i64(&task_fields), 2, 0)
        let task_alloca = self.create_entry_alloca(task_ty)
        let fid_ptr = wl_build_struct_gep(self.builder, task_ty, task_alloca, 0)
        wl_build_store(self.builder, fiber_id, fid_ptr)
        let rbuf_ptr = wl_build_struct_gep(self.builder, task_ty, task_alloca, 1)
        wl_build_store(self.builder, result_buf, rbuf_ptr)
        self.mir_local_ptrs.insert(dst_local, task_alloca)
        self.mir_local_types.insert(dst_local, task_ty)
        // Store result type for FIBER_AWAIT to load correctly
        self.async_task_result_types.insert(dst_local as i32, ret_ty)
        self.last_async_spawn_ret_ty = ret_ty

    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
    true

fn Codegen.generate_async_trampoline(self: Codegen, fn_sym: i32, callee: i64, call_ft: i64, args_struct_ty: i64, arg_types: Vec[i64]) -> i64:
    let ctx = self.context
    let ptr_ty = wl_ptr_type(ctx)
    let void_ty = wl_void_type(ctx)
    // Use actual async fn return type, not the spawn wrapper's i32 return.
    // call_ft is the spawn wrapper type (returns i32), but we need the real
    // return type for the result buffer. Look it up from async_fn_ret_types.
    var ret_ty = wl_get_return_type(call_ft)
    let actual_ret_opt = self.async_fn_ret_types.get(fn_sym)
    if actual_ret_opt.is_some():
        ret_ty = actual_ret_opt.unwrap() as i64
    let param_count = arg_types.len() as i32

    // Trampoline signature: void(i8* env, i8* result_buf)
    let tramp_params: Vec[i64] = Vec.new()
    tramp_params.push(ptr_ty)
    tramp_params.push(ptr_ty)
    let tramp_ft = wl_function_type(void_ty, vec_data_i64(&tramp_params), 2, 0)
    let fn_name = self.intern.resolve(fn_sym)
    let tramp_name = "__async_tramp_" ++ fn_name
    let tramp_fn = wl_add_function(self.llmod, tramp_name, tramp_ft)

    // Save current builder position
    let saved_bb = wl_get_insert_block(self.builder)

    // Build trampoline body
    let entry_bb = wl_append_bb(ctx, tramp_fn, "entry")
    wl_position_at_end(self.builder, entry_bb)

    let env_arg = wl_get_param(tramp_fn, 0)
    let rbuf_arg = wl_get_param(tramp_fn, 1)

    // Unpack args from env struct
    let call_args: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let field_ptr = wl_build_struct_gep(self.builder, args_struct_ty, env_arg, pi)
        let param_ty = arg_types.get(pi as i64)
        let val = wl_build_load(self.builder, param_ty, field_ptr)
        call_args.push(val)

    // Free env struct
    let free_fn_name = "with_free"
    var free_fn = wl_get_named_function(self.llmod, free_fn_name)
    if free_fn == 0:
        let free_params: Vec[i64] = Vec.new()
        free_params.push(ptr_ty)
        let free_ft = wl_function_type(void_ty, vec_data_i64(&free_params), 1, 0)
        free_fn = wl_add_function(self.llmod, free_fn_name, free_ft)
    let free_ft = wl_global_get_value_type(free_fn)
    let free_args: Vec[i64] = Vec.new()
    free_args.push(env_arg)
    wl_build_call(self.builder, free_ft, free_fn, vec_data_i64(&free_args), 1)

    // Call the actual async function
    let result = wl_build_call(self.builder, call_ft, callee, vec_data_i64(&call_args), param_count)

    // Write guard: check cancel_requested before storing result.
    // If cancelled, skip the write — buffer may be freed by parent's unwind.
    if ret_ty != void_ty:
        var wg_fn = wl_get_named_function(self.llmod, "with_fiber_is_cancelled")
        if wg_fn == 0:
            let wg_ft = wl_function_type(wl_i32_type(ctx), 0, 0, 0)
            wg_fn = wl_add_function(self.llmod, "with_fiber_is_cancelled", wg_ft)
        let wg_ft2 = wl_global_get_value_type(wg_fn)
        let wg_cancel = wl_build_call(self.builder, wg_ft2, wg_fn, 0, 0)
        let wg_is_cancel = wl_build_icmp(self.builder, wl_int_ne(), wg_cancel, wl_const_int(wl_i32_type(ctx), 0, 0))
        let wg_do_store = wl_append_bb(ctx, tramp_fn, "do_store")
        let wg_after = wl_append_bb(ctx, tramp_fn, "after_store")
        wl_build_cond_br(self.builder, wg_is_cancel, wg_after, wg_do_store)
        wl_position_at_end(self.builder, wg_do_store)
        wl_build_store(self.builder, result, rbuf_arg)
        wl_build_br(self.builder, wg_after)
        wl_position_at_end(self.builder, wg_after)
    let _ = wl_build_ret_void(self.builder)

    // Restore builder position
    if saved_bb != 0:
        wl_position_at_end(self.builder, saved_bb)

    tramp_fn

// ── Async block codegen ──────────────────────────────────────────

fn Codegen.gen_async_block(self: Codegen, node: i32) -> i64:
    let body_node = self.pool.get_data0(node)
    let ctx = self.context
    let ptr_ty = wl_ptr_type(ctx)
    let i32_ty = wl_i32_type(ctx)
    let i64_ty = wl_i64_type(ctx)
    let void_ty = wl_void_type(ctx)

    // 1. Collect captures (local_allocas populated by CK_ASYNC_BLOCK preamble)
    let fresh_captures: Vec[i32] = Vec.new()
    self.async_block_captures = fresh_captures
    self.collect_captures(body_node)
    let captures = self.async_block_captures
    let capture_count = captures.len() as i32

    // 2. Build capture struct type
    let cap_types: Vec[i64] = Vec.new()
    for ci in 0..capture_count:
        let sym = captures.get(ci as i64)
        let ty_opt = self.local_types.get(sym)
        if ty_opt.is_some():
            cap_types.push(ty_opt.unwrap() as i64)
        else:
            cap_types.push(i32_ty)
    var cap_struct_type: i64 = 0
    if capture_count > 0:
        cap_struct_type = wl_struct_type(ctx, vec_data_i64(&cap_types), capture_count, 0)

    // Determine result type from sema (unwrap Task[T] → T for result buffer)
    var ret_sema_ty_id = self.sema.ty_i32 as i32
    let node_sema_ty = self.sema_type_of_node(node)
    if node_sema_ty != 0:
        let unwrapped = self.sema.unwrap_task_type(node_sema_ty) as i32
        if unwrapped > 0:
            ret_sema_ty_id = unwrapped
    var ret_ty = self.sema_type_to_llvm(ret_sema_ty_id)
    if ret_ty == 0:
        ret_ty = i32_ty

    // 3. Create anonymous trampoline: void(ptr env, ptr result_buf)
    self.async_block_counter = self.async_block_counter + 1
    let tramp_name = "__async_block_" ++ int_to_string(self.async_block_counter)
    let tramp_params: Vec[i64] = Vec.new()
    tramp_params.push(ptr_ty)  // env
    tramp_params.push(ptr_ty)  // result_buf
    let tramp_ft = wl_function_type(void_ty, vec_data_i64(&tramp_params), 2, 0)
    let tramp_fn = wl_add_function(self.llmod, tramp_name, tramp_ft)

    // 4. Save codegen state
    let saved_fn = self.current_function
    let saved_ret = self.current_ret_type
    let saved_bb = wl_get_insert_block(self.builder)
    let saved_allocas = self.local_allocas
    let saved_types = self.local_types
    let saved_muts = self.local_muts
    let saved_loops = self.capture_loop_state()
    let saved_mir_locals = self.mir_local_ptrs
    let saved_mir_types = self.mir_local_types
    let saved_mir_indirect_value_local_types = self.mir_indirect_value_local_types
    let saved_mir_bbs = self.mir_bb_values

    // 5. Fresh context for trampoline body
    self.current_function = tramp_fn
    self.current_ret_type = ret_ty
    self.local_allocas = HashMap.new()
    self.local_types = HashMap.new()
    self.local_muts = HashMap.new()

    let entry_bb = wl_append_bb(ctx, tramp_fn, "entry")
    wl_position_at_end(self.builder, entry_bb)

    let env_arg = wl_get_param(tramp_fn, 0)
    let rbuf_arg = wl_get_param(tramp_fn, 1)

    // Load captures from env struct
    if capture_count > 0 and cap_struct_type != 0:
        for ci in 0..capture_count:
            let sym = captures.get(ci as i64)
            let cap_ty = cap_types.get(ci as i64)
            let field_ptr = wl_build_struct_gep(self.builder, cap_struct_type, env_arg, ci)
            let val = wl_build_load(self.builder, cap_ty, field_ptr)
            let alloca = wl_build_alloca(self.builder, cap_ty)
            wl_build_store(self.builder, val, alloca)
            self.local_allocas.insert(sym, alloca)
            self.local_types.insert(sym, cap_ty)

    // Free env struct
    var free_fn = wl_get_named_function(self.llmod, "with_free")
    if free_fn == 0:
        let fp: Vec[i64] = Vec.new()
        fp.push(ptr_ty)
        let fft = wl_function_type(void_ty, vec_data_i64(&fp), 1, 0)
        free_fn = wl_add_function(self.llmod, "with_free", fft)
    if capture_count > 0:
        let free_ft = wl_global_get_value_type(free_fn)
        let free_args: Vec[i64] = Vec.new()
        free_args.push(env_arg)
        wl_build_call(self.builder, free_ft, free_fn, vec_data_i64(&free_args), 1)

    // 6. Lower body via MirBuilder (same pattern as gen_closure)
    var ab_builder = MirBuilder.init(self.sema, self.pool, self.intern, 0)
    if ret_sema_ty_id != 0 and ret_sema_ty_id != self.sema.ty_void as i32:
        ab_builder.body.local_type_ids.set_i32(0, ret_sema_ty_id)
    else:
        ab_builder.body.local_type_ids.set_i32(0, self.sema.ty_i32 as i32)
    ab_builder.push_scope()
    // Register captures as MIR locals
    for ci in 0..capture_count:
        let sym = captures.get(ci as i64)
        var cap_sema_ty = self.sema.ty_i32 as i32
        let cap_sema_opt = self.local_sema_types.get(sym)
        if cap_sema_opt.is_some():
            cap_sema_ty = cap_sema_opt.unwrap()
        let cap_local = ab_builder.body.new_local(cap_sema_ty, 0, sym, 1)
        ab_builder.bind_local(sym, cap_local)
    // Lower body expression
    let ab_result = ab_builder.lower_expr(body_node)
    let ab_ret_place = ab_builder.place_for_local(0)
    ab_builder.assign_operand_to_place(ab_ret_place, ab_result, self.pool.get_end(body_node))
    ab_builder.pop_scope_inline()
    ab_builder.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)
    let ab_body = ab_builder.body

    // Set rbuf flag so TK_RETURN stores result into result_buf
    self.async_block_rbuf = rbuf_arg

    // Create return alloca for MIR local 0
    let ret_alloca = wl_build_alloca(self.builder, ret_ty)
    self.mir_local_ptrs = HashMap.new()
    self.mir_local_types = HashMap.new()
    self.mir_indirect_value_local_types = HashMap.new()
    // Map capture MIR locals
    for ci in 0..capture_count:
        let sym = captures.get(ci as i64)
        let cap_alloca_opt = self.local_allocas.get(sym)
        if cap_alloca_opt.is_some():
            // MIR locals: 0 = return, 1..N = captures
            self.mir_local_ptrs.insert(ci + 1, cap_alloca_opt.unwrap())
            self.mir_local_types.insert(ci + 1, cap_types.get(ci as i64))
    self.mir_local_ptrs.insert(0, ret_alloca)
    self.mir_local_types.insert(0, ret_ty)

    // Create LLVM BBs for MIR blocks
    self.mir_bb_values = Vec.new()
    let bb_count = ab_body.block_count()
    for bi in 0..bb_count:
        let bb = wl_append_bb(ctx, tramp_fn, "bb")
        self.mir_bb_values.push(bb)
    if bb_count > 0:
        wl_build_br(self.builder, self.mir_bb_values.get(0))

    // Emit MIR statements and terminators
    for bi in 0..bb_count:
        let bb = self.mir_bb_values.get(bi as i64)
        wl_position_at_end(self.builder, bb)
        let stmt_start = ab_body.bb_stmt_starts.get(bi as i64)
        let stmt_count = ab_body.bb_stmt_counts.get(bi as i64)
        for si in 0..stmt_count:
            self.mir_emit_stmt(ab_body, stmt_start + si)
        let term = ab_body.term_kind(bi)
        if term == TermKind.TK_RETURN:
            // TK_RETURN intercept handles store to rbuf + ret void
            if not self.mir_emit_term(ab_body, bi):
                let _ = wl_build_unreachable(self.builder)
        else:
            if not self.mir_emit_term(ab_body, bi):
                let _ = wl_build_unreachable(self.builder)

    // 7. Restore codegen state
    self.async_block_rbuf = 0
    self.mir_local_ptrs = saved_mir_locals
    self.mir_local_types = saved_mir_types
    self.mir_indirect_value_local_types = saved_mir_indirect_value_local_types
    self.mir_bb_values = saved_mir_bbs
    self.current_function = saved_fn
    self.current_ret_type = saved_ret
    self.local_allocas = saved_allocas
    self.local_types = saved_types
    self.local_muts = saved_muts
    self.restore_loop_state(saved_loops)
    if saved_bb != 0:
        wl_position_at_end(self.builder, saved_bb)

    // 8. Back in outer function: heap-allocate capture struct and fill it
    self.ensure_async_runtime_declared()
    var env_ptr = wl_const_null(ptr_ty)
    if capture_count > 0 and cap_struct_type != 0:
        let cap_size = self.abi_size_of(cap_struct_type)
        var alloc_fn = wl_get_named_function(self.llmod, "with_alloc")
        if alloc_fn == 0:
            let ap: Vec[i64] = Vec.new()
            ap.push(i64_ty)
            let aft = wl_function_type(ptr_ty, vec_data_i64(&ap), 1, 0)
            alloc_fn = wl_add_function(self.llmod, "with_alloc", aft)
        let alloc_ft = wl_global_get_value_type(alloc_fn)
        let alloc_args: Vec[i64] = Vec.new()
        alloc_args.push(wl_const_int(i64_ty, cap_size, 0))
        env_ptr = wl_build_call(self.builder, alloc_ft, alloc_fn, vec_data_i64(&alloc_args), 1)
        // Store captures into heap struct
        for ci in 0..capture_count:
            let sym = captures.get(ci as i64)
            let src_opt = self.local_allocas.get(sym)
            if src_opt.is_some():
                let cap_ty = cap_types.get(ci as i64)
                let val = wl_build_load(self.builder, cap_ty, src_opt.unwrap() as i64)
                let fld = wl_build_struct_gep(self.builder, cap_struct_type, env_ptr, ci)
                wl_build_store(self.builder, val, fld)

    // 9. Heap-allocate result buffer
    let result_size = self.abi_size_of(ret_ty)
    var alloc_fn2 = wl_get_named_function(self.llmod, "with_alloc")
    if alloc_fn2 == 0:
        let ap2: Vec[i64] = Vec.new()
        ap2.push(i64_ty)
        let aft2 = wl_function_type(ptr_ty, vec_data_i64(&ap2), 1, 0)
        alloc_fn2 = wl_add_function(self.llmod, "with_alloc", aft2)
    let alloc_ft2 = wl_global_get_value_type(alloc_fn2)
    let rbuf_args: Vec[i64] = Vec.new()
    rbuf_args.push(wl_const_int(i64_ty, if result_size > 0: result_size else: 1, 0))
    let result_buf = wl_build_call(self.builder, alloc_ft2, alloc_fn2, vec_data_i64(&rbuf_args), 1)

    // 10. Call with_fiber_spawn(trampoline, env, result_buf, result_size, 0)
    var spawn_fn = wl_get_named_function(self.llmod, "with_fiber_spawn")
    if spawn_fn == 0:
        let sp: Vec[i64] = Vec.new()
        sp.push(ptr_ty)
        sp.push(ptr_ty)
        sp.push(ptr_ty)
        sp.push(i32_ty)
        sp.push(i32_ty)
        let sft = wl_function_type(i32_ty, vec_data_i64(&sp), 5, 0)
        spawn_fn = wl_add_function(self.llmod, "with_fiber_spawn", sft)
    let spawn_ft = wl_global_get_value_type(spawn_fn)
    let spawn_args: Vec[i64] = Vec.new()
    spawn_args.push(tramp_fn)
    spawn_args.push(env_ptr)
    spawn_args.push(result_buf)
    spawn_args.push(wl_const_int(i32_ty, result_size, 0))
    spawn_args.push(wl_const_int(i32_ty, 0, 0))
    let fiber_id = wl_build_call(self.builder, spawn_ft, spawn_fn, vec_data_i64(&spawn_args), 5)

    // 11. Construct Task { fiber_id, result_buf }
    let task_fields: Vec[i64] = Vec.new()
    task_fields.push(i32_ty)
    task_fields.push(ptr_ty)
    let task_ty = wl_struct_type(ctx, vec_data_i64(&task_fields), 2, 0)
    var task_val = wl_get_undef(task_ty)
    task_val = wl_build_insert_value(self.builder, task_val, fiber_id, 0)
    task_val = wl_build_insert_value(self.builder, task_val, result_buf, 1)
    task_val

// ── Option method dispatch ────────────────────────────────────────
