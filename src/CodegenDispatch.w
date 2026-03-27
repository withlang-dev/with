use Codegen
use Ast
use Mir
use Sema
use InternPool
use Diagnostic
use Source

extern fn with_eprintln(s: str) -> void

// ── gen_function_dispatch: MIR-first, AST fallback for unsupported patterns ──

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
                with_eprintln("[mir-dispatch] using MIR for: " ++ fn_name)
            let fv = self.fn_values.get(fn_sym)
            if fv.is_some():
                self.current_function_name_sym = fn_sym
                self.debug_enter_function(fn_node, fn_sym, fv.unwrap() as i64)
                let fn_span = self.pool.get_start(fn_node)
                self.debug_set_location(fn_span)
            self.gen_function_mir(fn_node, body)
            self.debug_clear_location()
            return
    // No MIR body — emit unreachable stub
    let fv_fb = self.fn_values.get(fn_sym)
    if fv_fb.is_some():
        let fb_fn = fv_fb.unwrap() as i64
        let fb_entry = wl_append_bb(self.context, fb_fn, "entry")
        wl_position_at_end(self.builder, fb_entry)
        let _ = wl_build_unreachable(self.builder)

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
            if name_sym > 0 and name_sym < self.sema.pool.symbol_texts.len() as i32:
                let sema_text = self.sema.pool.symbol_texts.get(name_sym as i64)
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

fn Codegen.mir_get_or_create_local_ptr(self: Codegen, local_id: i32, ty: i64) -> i64:
    let existing = self.mir_local_ptrs.get(local_id)
    if existing.is_some():
        return existing.unwrap() as i64
    let alloc_ty = if ty != 0: ty else: self.type_fallback()
    let ptr = self.create_entry_alloca(alloc_ty)
    self.mir_local_ptrs.insert(local_id, ptr)
    ptr

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
        return 0 - 1
    if wl_get_type_kind(agg_ty) != wl_struct_type_kind():
        return 0 - 1
    let elem_count = wl_count_struct_elem_types(agg_ty)

    // Try symbol-based lookup first (for named struct fields from MIR field projections).
    // MIR stores field *symbols* as projection data, not numeric indices.
    // Must do this before the raw range check, because a symbol value (e.g. 132 for "ast")
    // can accidentally pass field_token < elem_count on large structs.
    let st_sym = self.find_struct_type_by_llvm(agg_ty)
    if st_sym != 0:
        let fi = self.find_field_index(st_sym, field_token)
        if fi >= 0 and fi < elem_count:
            return fi

    // Vec types are created dynamically and not registered in the struct field
    // registry. Resolve their field names by layout: {ptr, len, cap, elem_size}.
    if self.vec_is_vec.contains(agg_ty):
        if field_token == self.sym_ptr: return 0
        if field_token == self.sym_len: return 1
        if field_token == self.sym_cap: return 2
        if field_token == self.sym_elem_size: return 3

    // Fall back to direct numeric index (for tuple fields, match bindings)
    if field_token >= 0 and field_token < elem_count:
        return field_token

    let field_name = self.intern.resolve(field_token)
    if field_name.len() == 1:
        let ch = field_name.byte_at(0)
        if ch >= 48 and ch <= 57:
            let idx = (ch - 48) as i32
            if idx >= 0 and idx < elem_count:
                return idx

    0 - 1

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
            let type_name_sym = self.mir_input.mir_get_type_name(cur_sema_ty)
            if type_name_sym != 0:
                cur_ty = self.resolve_named_type(type_name_sym)
            if cur_ty == 0:
                cur_ty = self.mir_sema_type_to_llvm(cur_sema_ty)
    if cur_ty == 0:
        return 0
    let p_start = body.place_proj_starts.get(place_id as i64)
    for i in 0..p_count:
        let pk = body.proj_kinds.get((p_start + i) as i64)
        let pd = body.proj_d0.get((p_start + i) as i64)
        if pk == 0: // ProjKind.PK_FIELD
            if wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
                    let sema_ty = body.local_type_ids.get(base_local as i64)
                    if sema_ty > 0:
                        let type_name_sym = self.mir_input.mir_get_type_name(sema_ty)
                        if type_name_sym != 0:
                            cur_ty = self.resolve_named_type(type_name_sym)
                // Fallback: use method owner type for self parameter
                if (cur_ty == 0 or wl_get_type_kind(cur_ty) == wl_pointer_type_kind()) and self.current_method_owner_sym != 0:
                    let proj_owner_ty = self.resolve_named_type(self.current_method_owner_sym)
                    if proj_owner_ty != 0:
                        cur_ty = proj_owner_ty
            let fi = self.mir_resolve_field_index(cur_ty, pd)
            if fi < 0:
                return 0
            if wl_get_type_kind(cur_ty) == wl_array_type_kind():
                cur_ty = wl_get_element_type(cur_ty)
            else if fi < wl_count_struct_elem_types(cur_ty):
                cur_ty = wl_struct_get_type_at(cur_ty, fi)
            else:
                return 0
        else if pk == 2: // ProjKind.PK_DEREF
            // Resolve pointee type from base local's sema type (via MIR snapshot)
            var deref_ty: i64 = 0
            if cur_sema_ty > 0:
                let deref_resolved = self.mir_input.mir_resolve_alias(cur_sema_ty)
                let deref_tk = self.mir_input.mir_get_type_kind(deref_resolved)
                if deref_tk == TypeKind.TY_PTR or deref_tk == TypeKind.TY_REF:
                    let pointee_sema = self.mir_input.mir_get_type_d0(deref_resolved)
                    if pointee_sema > 0:
                        cur_sema_ty = pointee_sema
                        deref_ty = self.mir_sema_type_to_llvm(pointee_sema)
            if deref_ty != 0:
                cur_ty = deref_ty
            else:
                return 0
        else if pk == 1: // ProjKind.PK_INDEX
            let idx_elem_ty = self.mir_index_elem_llvm_type(cur_sema_ty, cur_ty)
            let idx_elem_sema = self.mir_index_elem_sema_type(cur_sema_ty)
            if idx_elem_sema > 0:
                cur_sema_ty = idx_elem_sema
            if idx_elem_ty != 0:
                cur_ty = idx_elem_ty
            else:
                return 0
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
    // Resolve type via sema snapshot if LLVM type not yet known
    if cur_ty == 0 and base_local >= 0 and base_local < body.local_type_ids.len() as i32:
        if cur_sema_ty > 0:
            let type_name_sym = self.mir_input.mir_get_type_name(cur_sema_ty)
            if type_name_sym != 0:
                cur_ty = self.resolve_named_type(type_name_sym)
            if cur_ty == 0:
                cur_ty = self.mir_sema_type_to_llvm(cur_sema_ty)
            if cur_ty != 0:
                self.mir_local_types.insert(base_local, cur_ty)
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
                // Resolve the pointee struct type via sema snapshot
                if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
                    let sema_ty = body.local_type_ids.get(base_local as i64)
                    if sema_ty > 0:
                        let type_name_sym = self.mir_input.mir_get_type_name(sema_ty)
                        if type_name_sym != 0:
                            cur_ty = self.resolve_named_type(type_name_sym)
                        if cur_ty == 0:
                            cur_ty = self.mir_sema_type_to_llvm(sema_ty)
                // Fallback: use method owner type for self parameter
                if (cur_ty == 0 or wl_get_type_kind(cur_ty) == wl_pointer_type_kind()) and self.current_method_owner_sym != 0:
                    let owner_ty = self.resolve_named_type(self.current_method_owner_sym)
                    if owner_ty != 0:
                        cur_ty = owner_ty
            let fi = self.mir_resolve_field_index(cur_ty, pd)
            if fi < 0:
                return 0
            if wl_get_type_kind(cur_ty) == wl_array_type_kind():
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
        else if pk == 2: // ProjKind.PK_DEREF
            // Load the pointer value, then use it as the new base
            cur_ptr = wl_build_load(self.builder, wl_ptr_type(self.context), cur_ptr)
            // Resolve pointee type from base local's sema type (via snapshot)
            var deref_ptr_ty: i64 = 0
            if cur_sema_ty > 0:
                let deref_resolved = self.mir_input.mir_resolve_alias(cur_sema_ty)
                let deref_tk = self.mir_input.mir_get_type_kind(deref_resolved)
                if deref_tk == TypeKind.TY_PTR or deref_tk == TypeKind.TY_REF:
                    let pointee_sema = self.mir_input.mir_get_type_d0(deref_resolved)
                    if pointee_sema > 0:
                        cur_sema_ty = pointee_sema
                        deref_ptr_ty = self.mir_sema_type_to_llvm(pointee_sema)
            if deref_ptr_ty != 0:
                cur_ty = deref_ptr_ty
            else:
                cur_ty = 0
        else if pk == 1: // ProjKind.PK_INDEX
            // pd is a local_id holding the index value
            let idx_ptr_opt = self.mir_local_ptrs.get(pd)
            var idx_val: i64 = wl_const_int(wl_i64_type(self.context), 0, 0)
            if idx_ptr_opt.is_some():
                let idx_ty_opt = self.mir_local_types.get(pd)
                var idx_ty = wl_i32_type(self.context)
                if idx_ty_opt.is_some():
                    idx_ty = idx_ty_opt.unwrap() as i64
                idx_val = wl_build_load(self.builder, idx_ty, idx_ptr_opt.unwrap() as i64)
            let elem_llvm = self.mir_index_elem_llvm_type(cur_sema_ty, cur_ty)
            let elem_sema = self.mir_index_elem_sema_type(cur_sema_ty)
            if elem_sema > 0:
                cur_sema_ty = elem_sema
            if wl_get_type_kind(cur_ty) == wl_array_type_kind():
                let indices: Vec[i64] = Vec.new()
                indices.push(idx_val)
                cur_ptr = wl_build_gep(self.builder, elem_llvm, cur_ptr, vec_data_i64(&indices), 1)
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
            with_eprintln(f"warning: [fallback] mir_const_value: invalid const_id={const_id}")
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

    if ck == ConstKind.CK_BOOL:
        return wl_const_int(wl_i1_type(self.context), cd as i64, 0)

    if ck == ConstKind.CK_STR:
        let text = if cd != 0: self.decode_string_escapes(self.intern.resolve(cd)) else: ""
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
        if cd >= 0 and cd < self.pool.strings.len() as i32:
            let float_text = self.pool.get_string(cd)
            if float_text.len() > 0:
                fval = with_parse_float(float_text)
        return wl_const_real(float_ty, fval)

    if ck == ConstKind.CK_ZERO_SIZED:
        if materialize_ty != 0:
            return self.build_default_value(materialize_ty)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    if ck == ConstKind.CK_CLOSURE:
        // Populate local_allocas/local_types/local_sema_types from MIR locals
        // so gen_closure can find captured variables and their types.
        let closure_node = cd
        if closure_node <= 0 or closure_node >= self.pool.node_count():
            with_eprintln(f"warning: [ck-closure] invalid node={closure_node}")
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

    if ck == ConstKind.CK_FN:
        let fn_sym = cd
        // ConstKind.CK_FN sym from MirLower is in sema pool — must translate to codegen pool.
        // Direct fn_values lookup would return wrong function (pool ID collision).
        var translated_sym = fn_sym
        if fn_sym > 0 and fn_sym < self.sema.pool.symbol_texts.len() as i32:
            let sema_text = self.sema.pool.symbol_texts.get(fn_sym as i64)
            if sema_text.len() > 0:
                translated_sym = self.intern.intern(sema_text)
        let fv_opt = self.fn_values.get(translated_sym)
        if fv_opt.is_some():
            if self.debug_mir_codegen_enabled():
                let fn_name = self.function_symbol_name(translated_sym)
                with_eprintln(f"[ck-fn] sym={fn_sym} -> {fn_name}")
            return fv_opt.unwrap() as i64
        let fn_name = self.function_symbol_name(translated_sym)
        let found = wl_get_named_function(self.llmod, fn_name)
        if found != 0:
            if self.debug_mir_codegen_enabled():
                with_eprintln(f"[ck-fn] sym={fn_sym} -> {fn_name} (llmod)")
            return found
        with_eprintln(f"warning: [ck-fn] NOT FOUND sym={fn_sym} name={fn_name}")
        return wl_get_undef(fallback_ty)

    wl_get_undef(fallback_ty)

fn Codegen.mir_eval_operand(self: Codegen, body: MirBody, operand_id: i32, expected_ty: i64) -> i64:
    let fallback_ty = if expected_ty != 0: expected_ty else: wl_i32_type(self.context)
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        if self.debug_fallback_enabled():
            with_eprintln(f"warning: [fallback] mir_eval_operand: invalid operand_id={operand_id}")
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
        let loaded = wl_build_load(self.builder, ptr_ty, ptr)
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
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        if od >= 0 and od < body.place_locals.len() as i32:
            let local_id = body.place_locals.get(od as i64)
            if local_id >= 0 and local_id < body.local_type_ids.len() as i32:
                let sema_ty = body.local_type_ids.get(local_id as i64)
                if sema_ty > 0:
                    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
                    if self.mir_input.mir_get_type_kind(resolved) == TypeKind.TY_INT:
                        return self.mir_input.mir_get_type_d1(resolved) == 0
    false

fn Codegen.mir_sema_type_is_unsigned(self: Codegen, sema_ty: i32) -> bool:
    if sema_ty <= 0: return false
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    if self.mir_input.mir_get_type_kind(resolved) == TypeKind.TY_INT:
        return self.mir_input.mir_get_type_d1(resolved) == 0
    false

fn Codegen.coerce_float_operand_to(self: Codegen, val: i64, target_ty: i64) -> i64:
    let val_ty = wl_type_of(val)
    if val_ty == target_ty or target_ty == 0:
        return val
    let vk = wl_get_type_kind(val_ty)
    let tk = wl_get_type_kind(target_ty)
    if (vk == wl_float_type_kind() or vk == wl_double_type_kind()) and (tk == wl_float_type_kind() or tk == wl_double_type_kind()):
        return wl_build_fp_cast(self.builder, val, target_ty)
    val

fn Codegen.mir_build_bin_op(self: Codegen, op: i32, lhs: i64, rhs: i64, is_unsigned: bool) -> i64:
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
        if lk == wl_pointer_type_kind() and rk == wl_integer_type_kind():
            if wl_is_constant(rhs) != 0 and wl_const_int_sext_val(rhs) == 0:
                let cmp_rhs = wl_const_null(wl_type_of(lhs))
                return wl_build_icmp(self.builder, if op == BinaryOp.OP_EQ: wl_int_eq() else: wl_int_ne(), lhs, cmp_rhs)
        if rk == wl_pointer_type_kind() and lk == wl_integer_type_kind():
            if wl_is_constant(lhs) != 0 and wl_const_int_sext_val(lhs) == 0:
                let cmp_lhs = wl_const_null(wl_type_of(rhs))
                return wl_build_icmp(self.builder, if op == BinaryOp.OP_EQ: wl_int_eq() else: wl_int_ne(), cmp_lhs, rhs)

    let is_float = lk == wl_float_type_kind() or lk == wl_double_type_kind() or rk == wl_float_type_kind() or rk == wl_double_type_kind()
    if is_float:
        let common_float_ty =
            if lk == wl_double_type_kind() or rk == wl_double_type_kind():
                wl_f64_type(self.context)
            else:
                wl_f32_type(self.context)
        let lhs_float = self.coerce_float_operand_to(lhs, common_float_ty)
        let rhs_float = self.coerce_float_operand_to(rhs, common_float_ty)
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

    // Coerce both operands to the wider integer type (never truncate)
    let lty = wl_type_of(lhs)
    let rty = wl_type_of(rhs)
    var wider_ty = lty
    if wl_get_type_kind(lty) == wl_integer_type_kind() and wl_get_type_kind(rty) == wl_integer_type_kind():
        if wl_get_int_type_width(rty) > wl_get_int_type_width(lty):
            wider_ty = rty
    let l = self.coerce_int_ext(lhs, wider_ty, is_unsigned)
    let r = self.coerce_int_ext(rhs, wider_ty, is_unsigned)
    if op == BinaryOp.OP_ADD_WRAP: return wl_build_add(self.builder, l, r)
    if op == BinaryOp.OP_SUB_WRAP: return wl_build_sub(self.builder, l, r)
    if op == BinaryOp.OP_MUL_WRAP: return wl_build_mul(self.builder, l, r)
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
    if op == BinaryOp.OP_SHL: return wl_build_shl(self.builder, l, r)
    if op == BinaryOp.OP_SHR:
        if is_unsigned: return wl_build_lshr(self.builder, l, r)
        return wl_build_ashr(self.builder, l, r)
    if op == BinaryOp.OP_CONCAT: return self.mir_str_concat(lhs, rhs)
    with_eprintln("warning: [mir-binop] unhandled binary op")
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
            return val
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

fn Codegen.gen_debug_format(self: Codegen, val: i64, sema_ty: i32, str_ty: i64) -> i64:
    // Generate debug formatting based on sema type.
    let resolved = if sema_ty > 0: self.mir_input.mir_resolve_alias(sema_ty) else: 0
    let tk = if resolved > 0: self.mir_input.mir_get_type_kind(resolved) else: 0

    // str → quoted
    if resolved == self.sema.ty_str or tk == TypeKind.TY_STR:
        return self.call_runtime_str_fn("with_fmt_str_debug", val, str_ty)

    // Struct → "TypeName { field: val, field: val }"
    if tk == TypeKind.TY_STRUCT:
        return self.gen_debug_struct(val, resolved, str_ty)

    // Enum → ".VariantName"
    if tk == TypeKind.TY_ENUM:
        return self.gen_debug_enum(val, resolved, str_ty)

    // Primitives (int, float, bool) → same as default display
    self.coerce_val_to_str(val, str_ty)

fn Codegen.gen_debug_struct(self: Codegen, val: i64, sema_ty: i32, str_ty: i64) -> i64:
    // Generate "TypeName { field1: val1, field2: val2 }"
    let type_name_sym = self.mir_input.mir_get_type_d0(sema_ty)
    var type_name = ""
    if type_name_sym > 0:
        type_name = self.sema.pool_resolve(type_name_sym)
        if type_name.len() == 0 and type_name_sym < self.sema.pool.symbol_texts.len() as i32:
            type_name = self.sema.pool.symbol_texts.get(type_name_sym as i64)

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
        let field_str = self.coerce_val_to_str(field_val, str_ty)
        result = self.mir_str_concat(result, field_str)
        fi = fi + 1

    // Close " }"
    result = self.mir_str_concat(result, self.gen_string_literal_raw(" " ++ rbrace()))
    result

fn Codegen.gen_debug_enum(self: Codegen, val: i64, sema_ty: i32, str_ty: i64) -> i64:
    // Simple enum debug: just format the value as default
    // Full enum variant names deferred to later task
    self.coerce_val_to_str(val, str_ty)

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

fn Codegen.mir_eval_rvalue(self: Codegen, body: MirBody, rval_id: i32, dest_ty: i64) -> i64:
    let fallback_ty = if dest_ty != 0: dest_ty else: wl_i32_type(self.context)
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        if self.debug_fallback_enabled():
            with_eprintln(f"warning: [fallback] mir_eval_rvalue: invalid rval_id={rval_id}")
        return wl_get_undef(fallback_ty)

    let rk = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)

    if rk == RvalueKind.RK_USE:
        return self.mir_eval_operand(body, d0, dest_ty)

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
        let out = self.mir_build_bin_op(d0, lhs, rhs, is_unsigned)
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
        let local_id = body.place_locals.get(d0 as i64)
        let place_ty_opt = self.mir_local_types.get(local_id)
        if not place_ty_opt.is_some():
            return wl_get_undef(wl_i32_type(self.context))
        let place_ty = place_ty_opt.unwrap() as i64
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
            if self.debug_mir_codegen_enabled():
                with_eprintln(f"[mir-agg] fn={self.intern.resolve(self.current_function_name_sym)} count={agg_count} dest_ty_kind={if dest_ty != 0: wl_get_type_kind(dest_ty) else: -1} dest_ty_fields={if dest_ty != 0 and wl_get_type_kind(dest_ty) == wl_struct_type_kind(): wl_count_struct_elem_types(dest_ty) else: -1}")
            if agg_count == 0 and d0 != 1:
                let zero_ty = if struct_ty != 0: struct_ty else: fallback_ty
                return self.build_default_value(zero_ty)
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
                    // Build payload struct type from operand types
                    let ev_payload_types: Vec[i64] = Vec.new()
                    let ev_payload_vals: Vec[i64] = Vec.new()
                    for evi in 0..agg_count:
                        let ev_op = body.agg_field_operands.get((agg_start + evi) as i64)
                        let ev_val = self.mir_eval_operand(body, ev_op, 0)
                        ev_payload_types.push(wl_type_of(ev_val))
                        ev_payload_vals.push(ev_val)
                    let ev_payload_ty = wl_struct_type(self.context, vec_data_i64(&ev_payload_types), agg_count, 0)
                    let ev_data_ptr = wl_build_struct_gep(self.builder, struct_ty, ev_alloca, 1)
                    for evi in 0..agg_count:
                        let ev_field_ptr = wl_build_struct_gep(self.builder, ev_payload_ty, ev_data_ptr, evi)
                        wl_build_store(self.builder, ev_payload_vals.get(evi as i64), ev_field_ptr)
                return wl_build_load(self.builder, struct_ty, ev_alloca)
            if struct_ty == 0 or wl_get_type_kind(struct_ty) != wl_struct_type_kind():
                // Try to construct type from operands
                if agg_count > 0:
                    let first_op = body.agg_field_operands.get(agg_start as i64)
                    let first_val = self.mir_eval_operand(body, first_op, 0)
                    let elem_types: Vec[i64] = Vec.new()
                    elem_types.push(wl_type_of(first_val))
                    for i in 1..agg_count:
                        let oi = body.agg_field_operands.get((agg_start + i) as i64)
                        let vi = self.mir_eval_operand(body, oi, 0)
                        elem_types.push(wl_type_of(vi))
                    struct_ty = wl_struct_type(self.context, vec_data_i64(&elem_types), agg_count, 0)
                    let alloca = self.create_entry_alloca(struct_ty)
                    wl_build_store(self.builder, self.build_default_value(struct_ty), alloca)
                    // Re-store the already-evaluated values
                    let gep0 = wl_build_struct_gep(self.builder, struct_ty, alloca, 0)
                    wl_build_store(self.builder, first_val, gep0)
                    for i in 1..agg_count:
                        let oi = body.agg_field_operands.get((agg_start + i) as i64)
                        let vi = self.mir_eval_operand(body, oi, 0)
                        let gepi = wl_build_struct_gep(self.builder, struct_ty, alloca, i)
                        wl_build_store(self.builder, vi, gepi)
                    return wl_build_load(self.builder, struct_ty, alloca)
                with_eprintln(f"error: RvalueKind.RK_AGGREGATE with unknown dest type fn={self.intern.resolve(self.current_function_name_sym)} count={agg_count}")
                return wl_get_undef(fallback_ty)
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
        var dst_ty: i64 = 0
        // For projected places (field access), use the projected field's sema type
        // to get the correct LLVM type. Using the base local's type is wrong —
        // e.g., storing i32 to self.field would get ptr type from self instead of i32.
        if has_projections:
            let proj_sema = self.mir_place_sema_type(body, d0)
            if proj_sema > 0:
                dst_ty = self.mir_sema_type_to_llvm(proj_sema)
        if dst_ty == 0:
            let dst_ty_opt = self.mir_local_types.get(dst_local)
            if dst_ptr != 0 and dst_ty_opt.is_some():
                dst_ty = dst_ty_opt.unwrap() as i64
        // Resolve type via sema when LLVM type is not yet known
        if dst_ty == 0 and dst_local >= 0 and dst_local < body.local_type_ids.len() as i32:
            let sema_ty = body.local_type_ids.get(dst_local as i64)
            if sema_ty > 0:
                dst_ty = self.mir_sema_type_to_llvm(sema_ty)
            // For RvalueKind.RK_AGGREGATE (struct construction), if sema type didn't resolve,
            // fall back to the function's return type (local 0).
            if dst_ty == 0 and d1 >= 0 and d1 < body.rval_kinds.len() as i32:
                if body.rval_kinds.get(d1 as i64) == RvalueKind.RK_AGGREGATE:
                    let ret_ty_opt = self.mir_local_types.get(0)
                    if ret_ty_opt.is_some():
                        let ret_ty = ret_ty_opt.unwrap() as i64
                        if wl_get_type_kind(ret_ty) == wl_struct_type_kind():
                            dst_ty = ret_ty
        let value = self.mir_eval_rvalue(body, d1, dst_ty)
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
            coerced = self.coerce_value_to_type(value, final_ty)
        wl_build_store(self.builder, coerced, dst_ptr)
        return true

    if sk == StmtKind.StorageLive:
        // Storage markers do not require dedicated IR in this backend.
        return true

    if sk == StmtKind.StorageDead:
        return true

    if sk == StmtKind.Drop:
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let local_id = body.place_locals.get(d0 as i64)
        let ty_opt = self.mir_local_types.get(local_id)
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr != 0:
            if ty_opt.is_some():
                self.mir_emit_drop_ptr(ptr, ty_opt.unwrap() as i64)
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
        return self.mir_place_ptr(body, od, false, 0)
    0

fn Codegen.mir_eval_call_operand(self: Codegen, body: MirBody, operand_id: i32, expected_ty: i64, call_context: str, arg_index: i32) -> i64:
    let val = self.mir_eval_operand(body, operand_id, expected_ty)
    let had_error_before = self.had_error
    let coerced = self.enforce_coerced_type(val, expected_ty, "wrong argument type")
    if self.had_error != had_error_before:
        self.debug_call_coerce_failure(call_context, 0, arg_index, 0, val, expected_ty)
    coerced

fn Codegen.mir_intrinsic_recv_ptr(self: Codegen, body: MirBody, args_id: i32) -> i64:
    // Get a pointer to the receiver (arg 0) for instance method intrinsics.
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let recv_op = body.call_arg_operands.get(arg_start as i64)
    let ok = body.operand_kinds.get(recv_op as i64)
    let od = body.operand_d0.get(recv_op as i64)
    // If operand is a place (Copy/Move), try to get its pointer directly.
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        let ptr = self.mir_place_ptr(body, od, false, 0)
        if ptr != 0:
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
    // Fallback: evaluate, alloca, store
    let val = self.mir_eval_operand(body, recv_op, 0)
    let alloca = wl_build_alloca(self.builder, wl_type_of(val))
    wl_build_store(self.builder, val, alloca)
    alloca

fn Codegen.mir_intrinsic_arg(self: Codegen, body: MirBody, args_id: i32, idx: i32) -> i64:
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let op_id = body.call_arg_operands.get((arg_start + idx) as i64)
    self.mir_eval_operand(body, op_id, 0)

fn Codegen.mir_extract_map_ptr(self: Codegen, recv: i64) -> i64:
    // HashMap value is either { ptr } struct or raw ptr (from field access).
    let recv_ty = wl_type_of(recv)
    if wl_get_type_kind(recv_ty) == wl_pointer_type_kind():
        return recv
    if wl_get_type_kind(recv_ty) == wl_struct_type_kind():
        return wl_build_extract_value(self.builder, recv, 0)
    recv

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
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.mir_input.mir_get_type_d0(resolved)
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

fn Codegen.mir_builtin_variant_payload_sema_type(self: Codegen, sema_ty: i32, variant_idx: i32) -> i32:
    if sema_ty <= 0 or variant_idx < 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    if self.mir_input.mir_get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    let base_sym = self.mir_input.mir_get_type_d0(resolved)
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

fn Codegen.mir_project_field_sema_type(self: Codegen, agg_ty: i32, field_token: i32) -> i32:
    if agg_ty <= 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(agg_ty)
    let tk = self.mir_input.mir_get_type_kind(resolved)
    if tk == TypeKind.TY_STRUCT:
        let extra = self.mir_input.mir_get_type_d1(resolved)
        let count = self.mir_input.mir_get_type_d2(resolved)
        if field_token >= 0 and field_token < count:
            return self.mir_input.mir_get_type_extra(extra + field_token * 3 + 1)
        for fi in 0..count:
            let name_sym = self.mir_input.mir_get_type_extra(extra + fi * 3)
            if name_sym == field_token:
                return self.mir_input.mir_get_type_extra(extra + fi * 3 + 1)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.mir_input.mir_get_type_name(resolved)
        if base_sym != 0 and self.sema.named_types.contains(base_sym):
            let base_tid = self.sema.named_types.get(base_sym).unwrap()
            return self.mir_project_field_sema_type(base_tid, field_token)
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
    let local_id = body.place_locals.get(od as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    var ty = body.local_type_ids.get(local_id as i64)
    // Walk projections to resolve through struct fields (using sema snapshot).
    let p_count = body.place_proj_counts.get(od as i64)
    if p_count > 0:
        let p_start = body.place_proj_starts.get(od as i64)
        for pi in 0..p_count:
            let pk = body.proj_kinds.get((p_start + pi) as i64)
            let pd = body.proj_d0.get((p_start + pi) as i64)
            if pk == ProjKind.PK_FIELD:
                let field_ty = self.mir_project_field_sema_type(ty, pd)
                if field_ty > 0:
                    ty = field_ty
            else if pk == ProjKind.PK_DEREF:
                let d_resolved = self.mir_input.mir_resolve_alias(ty)
                let d_tk = self.mir_input.mir_get_type_kind(d_resolved)
                if d_tk == TypeKind.TY_PTR or d_tk == TypeKind.TY_REF:
                    ty = self.mir_input.mir_get_type_d0(d_resolved)
            else if pk == ProjKind.PK_INDEX:
                let elem_ty = self.mir_index_elem_sema_type(ty)
                if elem_ty > 0:
                    ty = elem_ty
            else if pk == ProjKind.PK_DOWNCAST:
                continue
    ty

fn Codegen.mir_place_sema_type(self: Codegen, body: MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    // Use stored sema type if available (populated by MirLower)
    if place_id < body.place_sema_types.len() as i32:
        let stored = body.place_sema_types.get(place_id as i64)
        if stored > 0:
            return stored
    // Fallback: walk projections using sema snapshot
    let local_id = body.place_locals.get(place_id as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    var ty = body.local_type_ids.get(local_id as i64)
    let p_count = body.place_proj_counts.get(place_id as i64)
    if p_count > 0:
        let p_start = body.place_proj_starts.get(place_id as i64)
        for pi in 0..p_count:
            let pk = body.proj_kinds.get((p_start + pi) as i64)
            let pd = body.proj_d0.get((p_start + pi) as i64)
            if pk == ProjKind.PK_FIELD:
                let field_ty = self.mir_project_field_sema_type(ty, pd)
                if field_ty > 0:
                    ty = field_ty
            else if pk == ProjKind.PK_DEREF:
                let d_resolved = self.mir_input.mir_resolve_alias(ty)
                let d_tk = self.mir_input.mir_get_type_kind(d_resolved)
                if d_tk == TypeKind.TY_PTR or d_tk == TypeKind.TY_REF:
                    ty = self.mir_input.mir_get_type_d0(d_resolved)
            else if pk == ProjKind.PK_INDEX:
                let elem_ty = self.mir_index_elem_sema_type(ty)
                if elem_ty > 0:
                    ty = elem_ty
            else if pk == ProjKind.PK_DOWNCAST:
                continue
    ty

fn Codegen.mir_dest_llvm_type(self: Codegen, body: MirBody, dest_place: i32) -> i64:
    // Get the LLVM type for a destination place from its sema type.
    if dest_place < 0 or dest_place >= body.place_locals.len() as i32:
        return 0
    let local_id = body.place_locals.get(dest_place as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    let sema_ty = body.local_type_ids.get(local_id as i64)
    if sema_ty <= 0:
        return 0
    self.mir_sema_type_to_llvm(sema_ty)

fn Codegen.mir_vec_elem_type(self: Codegen, body: MirBody, recv_op_id: i32) -> i64:
    // Infer Vec element LLVM type from the receiver's sema type (using snapshot).
    let sema_ty = self.mir_operand_sema_type(body, recv_op_id)
    if sema_ty > 0:
        let resolved = self.mir_input.mir_resolve_alias(sema_ty)
        let tk = self.mir_input.mir_get_type_kind(resolved)
        if tk == TypeKind.TY_GENERIC_INST:
            let arg_count = self.mir_input.mir_get_type_d2(resolved)
            if arg_count > 0:
                let te_start = self.mir_input.mir_get_type_d1(resolved)
                let elem_tid = self.mir_input.mir_get_type_extra(te_start)
                if elem_tid > 0:
                    return self.mir_sema_type_to_llvm(elem_tid)
    0

fn Codegen.mir_emit_intrinsic_call(self: Codegen, body: MirBody, intrinsic: i32, args_id: i32, dest_place: i32, next_bb: i32) -> bool:
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
        let get_fn = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
        let get_ty = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        args.push(idx64)
        let raw_ptr = wl_build_call(self.builder, get_ty, get_fn, vec_data_i64(&args), 2)
        // Use destination place's sema type to determine element type.
        var elem_ty = self.mir_dest_llvm_type(body, dest_place)
        if elem_ty == 0:
            let recv_op = body.call_arg_operands.get(arg_start as i64)
            elem_ty = self.mir_vec_elem_type(body, recv_op)
        if elem_ty == 0:
            elem_ty = i64_ty
        result = wl_build_load(self.builder, elem_ty, raw_ptr)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_LEN:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        result = wl_build_extract_value(self.builder, recv, 1)

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
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
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
        let dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        if dest_sema > 0:
            let resolved = self.mir_input.mir_resolve_alias(dest_sema)
            let tk = self.mir_input.mir_get_type_kind(resolved)
            if tk == TypeKind.TY_GENERIC_INST:
                let gi_arg_count = self.mir_input.mir_get_type_d2(resolved)
                if gi_arg_count == 2:
                    let args_start = self.mir_input.mir_get_type_d1(resolved)
                    let key_sema = self.mir_input.mir_get_type_extra(args_start)
                    let val_sema = self.mir_input.mir_get_type_extra(args_start + 1)
                    let key_llvm = self.sema_type_to_llvm(key_sema)
                    let val_llvm = self.sema_type_to_llvm(val_sema)
                    if key_llvm != 0 and val_llvm != 0:
                        hm_key_size = self.abi_size_of(key_llvm)
                        hm_val_size = self.abi_size_of(val_llvm)
                        hm_ty = self.get_or_create_hashmap_type(0, key_llvm, val_llvm)
        let new_fn = self.ensure_hashmap_new_declared()
        let fn_ty = self.get_hashmap_new_fn_type()
        let new_args: Vec[i64] = Vec.new()
        new_args.push(wl_const_int(i64_ty, hm_key_size, 0))
        new_args.push(wl_const_int(i64_ty, hm_val_size, 0))
        let handle = wl_build_call(self.builder, fn_ty, new_fn, vec_data_i64(&new_args), 2)
        // Wrap handle in HashMap struct { ptr }.
        if hm_ty == 0:
            hm_ty = self.get_or_create_hashmap_type(0, i64_ty, i64_ty)
        let empty = self.build_default_value(hm_ty)
        result = wl_build_insert_value(self.builder, empty, handle, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_INSERT:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let key = self.mir_intrinsic_arg(body, args_id, 1)
        let val = self.mir_intrinsic_arg(body, args_id, 2)
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        let val_alloca = wl_build_alloca(self.builder, wl_type_of(val))
        wl_build_store(self.builder, key, key_alloca)
        wl_build_store(self.builder, val, val_alloca)
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
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let key = self.mir_intrinsic_arg(body, args_id, 1)
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
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let key = self.mir_intrinsic_arg(body, args_id, 1)
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
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let fn_val = self.ensure_hm_fn("with_hashmap_len", i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&self.make_ptr_vec()), 1, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 1)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_REMOVE:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let key = self.mir_intrinsic_arg(body, args_id, 1)
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        let is_str_val = wl_const_int(i64_ty, 0, 0)
        let fn_val = self.ensure_hm_fn("with_hashmap_remove", i64_ty)
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&params), 3, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(is_str_val)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 3)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_CLEAR:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let fn_val = self.ensure_hm_fn("with_hashmap_clear", void_ty)
        let fn_ty = wl_function_type(void_ty, vec_data_i64(&self.make_ptr_vec()), 1, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 1)

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
            with_eprintln(f"[mir-str-len] recv_ty_kind={wl_get_type_kind(wl_type_of(recv))}")
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
                let dest_name_sym = self.mir_input.mir_get_type_name(resolved_dest)
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
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
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
            let sb_fn_name = if sb_width == 16: "llvm.bswap.i16" else: if sb_width == 32: "llvm.bswap.i32" else: "llvm.bswap.i64"
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

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_OPT_FILTER:
        result = self.mir_emit_opt_filter(body, args_id)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_MAP:
        result = self.mir_emit_vec_map(body, args_id)
    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_FILTER:
        result = self.mir_emit_vec_filter(body, args_id)
    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_FOLD:
        result = self.mir_emit_vec_fold(body, args_id)
    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_CONTAINS:
        result = wl_const_int(wl_i1_type(self.context), 0, 0)

    else if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_JOIN:
        let vj_recv = self.mir_intrinsic_arg(body, args_id, 0)
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
        if dd_type_sym > 0 and dd_type_sym < self.sema.pool.symbol_texts.len() as i32:
            let dd_text = self.sema.pool.symbol_texts.get(dd_type_sym as i64)
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
        if dv_type_sym > 0 and dv_type_sym < self.sema.pool.symbol_texts.len() as i32:
            let dv_text = self.sema.pool.symbol_texts.get(dv_type_sym as i64)
            if dv_text.len() > 0:
                dv_cg_type_sym = self.intern.intern(dv_text)
        var dv_cg_trait_sym = dv_trait_sym
        if dv_trait_sym > 0 and dv_trait_sym < self.sema.pool.symbol_texts.len() as i32:
            let dv_tt = self.sema.pool.symbol_texts.get(dv_trait_sym as i64)
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
        let fmt_str_ty = self.resolve_named_type(self.intern.intern("str"))
        result = self.coerce_val_to_str(fmt_val, fmt_str_ty)

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
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
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
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
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

fn Codegen.mir_emit_vec_fold(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
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
        with_eprintln(f"[mir-call-pre] intrinsic={mir_intrinsic} callee_op={callee_operand} args_id={args_id} dest={dest_place}")
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

            // Try method call dispatch for generic struct methods
            let gc_callee_field = self.pool.get_data0(gc_node)
            if self.pool.kind(gc_callee_field) == NodeKind.NK_FIELD_ACCESS:
                let gc_self_expr_node = self.pool.get_data0(gc_callee_field)
                let gc_method_sym = self.pool.get_data1(gc_callee_field)
                let gc_method_name = self.intern.resolve(gc_method_sym)
                let gc_mir_start = body.call_arg_starts.get(args_id as i64)
                let gc_mir_count = body.call_arg_counts.get(args_id as i64)
                // Eval receiver from MIR operand 0
                if gc_mir_count > 0:
                    let gc_recv_op = body.call_arg_operands.get(gc_mir_start as i64)
                    let gc_recv_val = self.mir_eval_operand(body, gc_recv_op, 0)
                    let gc_recv_ty = wl_type_of(gc_recv_val)
                    let gc_recv_type_sym = self.find_struct_type_by_llvm(gc_recv_ty)
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
                        let gc_result = self.gen_enum_variant_call_val(gc_vc_variant_sym, gc_vc_args, gc_vc_mir_count)
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
                if self.current_method_owner_sym != 0:
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

            // Try derive-generated method calls (e.g., clone)
            if gc_callee_sym > 0 and gc_node > 0:
                let dv_callee = self.pool.get_data0(gc_node)
                if self.pool.kind(dv_callee) == NodeKind.NK_FIELD_ACCESS:
                    let dv_method = self.pool.get_data1(dv_callee)
                    let dv_ms = body.call_arg_starts.get(args_id as i64)
                    let dv_mc = body.call_arg_counts.get(args_id as i64)
                    if dv_mc > 0:
                        let dv_rop = body.call_arg_operands.get(dv_ms as i64)
                        let dv_rv = self.mir_eval_operand(body, dv_rop, 0)
                        let dv_rt = wl_type_of(dv_rv)
                        let dv_ts = self.find_struct_type_by_llvm(dv_rt)
                        if dv_ts != 0:
                            let dv_mn = self.intern.resolve(dv_method)
                            let dv_qn = self.intern.resolve(dv_ts) ++ "." ++ dv_mn
                            let dv_qs = self.intern.intern(dv_qn)
                            let dv_fv = self.fn_values.get(dv_qs)
                            let dv_ft = self.fn_fn_types.get(dv_qs)
                            if dv_fv.is_some() and dv_ft.is_some():
                                let dv_args: Vec[i64] = Vec.new()
                                dv_args.push(self.get_mutable_receiver_ptr(self.pool.get_data0(dv_callee), dv_rv, dv_rt))
                                let dv_result = wl_build_call(self.builder, dv_ft.unwrap() as i64, dv_fv.unwrap() as i64, vec_data_i64(&dv_args), 1)
                                if dest_place >= 0 and dv_result != 0:
                                    let dv_ret_ty = wl_type_of(dv_result)
                                    if dv_ret_ty != wl_void_type(self.context):
                                        let dv_local = body.place_locals.get(dest_place as i64)
                                        let dv_alloca = self.create_entry_alloca(dv_ret_ty)
                                        wl_build_store(self.builder, dv_result, dv_alloca)
                                        self.mir_local_ptrs.insert(dv_local, dv_alloca)
                                        self.mir_local_types.insert(dv_local, dv_ret_ty)
                                if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                                    let dv_next = self.mir_bb_values.get(next_bb as i64)
                                    wl_build_br(self.builder, dv_next)
                                return true

            // All patterns should be handled above. If we reach here, it's a genuine error
            // (unless we're in a blanket impl body where T-method calls can't be resolved).
            let gc_name = if gc_callee_sym > 0: self.intern.resolve(gc_callee_sym) else: "?"
            var gc_is_blanket = false
            if self.current_method_owner_sym != 0:
                let gc_owner_name = self.intern.resolve(self.current_method_owner_sym)
                if gc_owner_name.len() <= 2:
                    // Single-letter type params (T, K, V) indicate blanket impl context
                    if not self.struct_type_map.get(self.current_method_owner_sym).is_some():
                        if not self.enum_type_map.get(self.current_method_owner_sym).is_some():
                            gc_is_blanket = true
            if not gc_is_blanket:
                with_eprintln(f"FATAL: unhandled MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL sym={gc_name} node_kind={self.pool.kind(gc_node)}")
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
                if raw_sym > 0 and raw_sym < self.sema.pool.symbol_texts.len() as i32:
                    dbg_name = self.sema.pool.symbol_texts.get(raw_sym as i64)
        with_eprintln(f"[mir-call] callee={dbg_name} callee_ty_kind={wl_get_type_kind(wl_type_of(callee))}")
    let call_context = self.mir_call_context(body, callee_operand)
    var call_ft: i64 = 0
    var is_indirect = false
    var fn_ptr_val: i64 = 0
    var ctx_ptr_val: i64 = 0
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
                let co_ok = body.operand_kinds.get(callee_operand as i64)
                let co_od = body.operand_d0.get(callee_operand as i64)
                if (co_ok == OperandKind.OK_COPY or co_ok == OperandKind.OK_MOVE) and co_od >= 0 and co_od < body.place_locals.len() as i32:
                    let co_local = body.place_locals.get(co_od as i64)
                    if co_local >= 0 and co_local < body.local_type_ids.len() as i32:
                        let co_sema_ty = body.local_type_ids.get(co_local as i64)
                        if co_sema_ty > 0:
                            call_ft = self.mir_build_closure_fn_type(co_sema_ty)
    else:
        let gvt2 = wl_global_get_value_type(callee)
        if gvt2 != 0 and wl_get_type_kind(gvt2) == wl_function_type_kind():
            call_ft = gvt2
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
                if raw_sym > 0 and raw_sym < self.sema.pool.symbol_texts.len() as i32:
                    let sym_text = self.sema.pool.symbol_texts.get(raw_sym as i64)
                    if sym_text.len() > 0:
                        callee_fn_sym = self.intern.intern(sym_text)

    let args: Vec[i64] = Vec.new()
    if is_indirect:
        args.push(ctx_ptr_val)
    for ai in 0..arg_count:
        let operand_id = body.call_arg_operands.get((arg_start + ai) as i64)
        var expected_ty: i64 = 0
        let param_offset = if is_indirect: ai + 1 else: ai
        if param_offset < param_count:
            expected_ty = param_types.get(param_offset as i64)

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
    let actual_arg_count = if is_indirect: arg_count + 1 else: arg_count
    if self.debug_mir_codegen_enabled():
        with_eprintln(f"[mir-call] building call arg_count={actual_arg_count} ft_params={wl_count_param_types(call_ft)}")
        for di in 0..args.len() as i32:
            let a = args.get(di as i64)
            with_eprintln(f"[mir-call]   arg[{di}] ty_kind={wl_get_type_kind(wl_type_of(a))}")
    let call_val = wl_build_call(self.builder, call_ft, actual_callee, vec_data_i64(&args), actual_arg_count)
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
            with_eprintln(f"[mir-call-ret] dst_local={dst_local} ret_ty_kind={wl_get_type_kind(ret_ty)} dst_ty_kind={wl_get_type_kind(dst_ty)} is_str={if self.is_str_type(dst_ty): 1 else: 0}")
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
        with_eprintln(f"[mir-term] bb={bb} tk={tk}")

    if tk == TermKind.TK_GOTO:
        if d0 < 0 or d0 >= self.mir_bb_values.len() as i32:
            return false
        let target_bb = self.mir_bb_values.get(d0 as i64)
        wl_build_br(self.builder, target_bb)
        return true

    if tk == TermKind.TK_RETURN:
        if self.current_ret_type == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
            return true
        let ret_ptr_opt = self.mir_local_ptrs.get(0)
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
        let sw = wl_build_switch(self.builder, cond, default_bb, case_count)
        let cond_ty = wl_type_of(cond)
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
        return self.mir_emit_call_term(body, d0, d1, d2, d3)

    if tk == TermKind.TK_DROP_AND_GOTO:
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let local_id = body.place_locals.get(d0 as i64)
        let ty_opt = self.mir_local_types.get(local_id)
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr != 0:
            if ty_opt.is_some():
                self.mir_emit_drop_ptr(ptr, ty_opt.unwrap() as i64)
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
        with_eprintln("error: no fn_value for MIR function: " ++ name_str)
        return
    let function = fv.unwrap() as i64
    let ft = self.fn_fn_types.get(name_sym)
    if not ft.is_some():
        with_eprintln("error: no fn_type for MIR function: " ++ name_str)
        return
    let fn_type = ft.unwrap() as i64
    if self.debug_mir_codegen_enabled():
        with_eprintln(f"[mir-cg] fn={name_str} blocks={body.block_count()}")

    self.current_function = function
    self.current_function_name_sym = name_sym
    self.current_ret_type = wl_get_return_type(fn_type)
    self.current_method_owner_sym = 0

    let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
    let fresh_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
    let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
    let fresh_local_pointee_structs: HashMap[i32, i32] = HashMap.new()
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
    let fresh_mir_bbs: Vec[i64] = Vec.new()
    let fresh_mir_default_unreachable_bbs: Vec[i64] = Vec.new()
    self.mir_local_ptrs = fresh_mir_locals
    self.mir_local_types = fresh_mir_local_types
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
        let param_val = wl_get_param(function, pi)
        let param_type = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_type)
        wl_build_store(self.builder, param_val, alloca)

        self.record_local(p_name, alloca, param_type, 1)

        self.mir_local_ptrs.insert(pi + 1, alloca)
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
                    // str is in struct_type_map but passes by value, not pointer
                    if p_sym != self.sym_str:
                        method_owner_sym = p_sym
                        self.current_method_owner_sym = method_owner_sym
                if method_owner_sym != 0 and (p_sym == self.sym_Self or p_sym == method_owner_sym):
                    if method_owner_sym != self.sym_str:
                        self.record_local_pointee_struct(p_name, method_owner_sym)
            if method_owner_sym != 0:
                if p_name == self.sym_self:
                    if method_owner_sym != self.sym_str:
                        self.record_local_pointee_struct(p_name, method_owner_sym)
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
        if self.current_ret_type == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
        else:
            let _ = wl_build_ret(self.builder, self.build_default_value(self.current_ret_type))

    let saved_fn_scope = self.di_current_scope
    for bb in 0..body.block_count():
        if bb < 0 or bb >= self.mir_bb_values.len() as i32:
            continue
        let llbb = self.mir_bb_values.get(bb as i64)
        if self.debug_mir_codegen_enabled():
            with_eprintln(f"[mir-cg] fn={name_str} bb={bb} llbb={llbb}")
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
                    with_eprintln(f"[mir-cg] fn={name_str} bb={bb} stmt_fail={stmt_id}")
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
                with_eprintln(f"[mir-cg] fn={name_str} bb={bb} term_ok={ok_i}")
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
        with_eprintln("error: no fn_value for MIR mono function: " ++ name_str)
        return
    let function = fv.unwrap() as i64
    let ft = self.fn_fn_types.get(mono_sym)
    if not ft.is_some():
        with_eprintln("error: no fn_type for MIR mono function: " ++ name_str)
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
    self.current_method_owner_sym = 0

    let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
    let fresh_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
    let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
    let fresh_local_pointee_structs: HashMap[i32, i32] = HashMap.new()
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
    let saved_mir_bbs = self.mir_bb_values
    let saved_mir_default_unreachable_bbs = self.mir_default_unreachable_bbs
    let fresh_mir_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_bbs: Vec[i64] = Vec.new()
    let fresh_mir_default_unreachable_bbs: Vec[i64] = Vec.new()
    self.mir_local_ptrs = fresh_mir_locals
    self.mir_local_types = fresh_mir_local_types
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
        let param_val = wl_get_param(function, pi)
        let param_type = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_type)
        wl_build_store(self.builder, param_val, alloca)

        self.record_local(p_name, alloca, param_type, 1)

        self.mir_local_ptrs.insert(pi + 1, alloca)
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
                if method_owner_sym != 0 and (p_sym == self.sym_Self or p_sym == method_owner_sym):
                    if method_owner_sym != self.sym_str:
                        self.record_local_pointee_struct(p_name, method_owner_sym)
            if method_owner_sym != 0:
                if p_name == self.sym_self:
                    if method_owner_sym != self.sym_str:
                        self.record_local_pointee_struct(p_name, method_owner_sym)
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
        if self.current_ret_type == wl_void_type(self.context):
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
    (0) as NodeId

fn Codegen.find_field_index_from_ast(self: Codegen, type_sym: i32, field_sym: i32) -> i32:
    let decl = self.find_struct_decl_node(type_sym)
    if (decl as i32) == 0:
        return 0 - 1
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
    0 - 1

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
        with_eprintln("warning: [optional-chain] chain resolution failed")
        return wl_get_undef(wl_i32_type(self.context))

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)
    let tp_start = self.pool.fn_meta_tp_start(meta)
    let tp_count = self.pool.fn_meta_tp_count(meta)
    let body_node = self.pool.get_data1(generic_node)
    if param_count < 0 or param_count > 64:
        with_eprintln("warning: [optional-chain] chain resolution failed")
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
            with_eprintln("error: unknown type")
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
                with_eprintln("error: unknown type")
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
        with_eprintln("error: unknown type")
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

    // 2. Lower to MIR
    var mir_builder = MirBuilder.init(self.sema, self.pool, self.intern, mono_sym)
    let mir_body = lower_fn_with_sig(mir_builder, generic_node, sig_idx)

    // 3. Codegen via MIR (saves/restores all codegen state internally)
    self.gen_function_mir_mono(mono_sym, generic_node, mir_body)

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
                let pointee_sym = self.lookup_local_pointee_struct(sym)
                if wl_get_type_kind(local_ty) == wl_pointer_type_kind() and pointee_sym != 0:
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

fn Codegen.gen_enum_variant_call_val(self: Codegen, variant_sym: i32, args: Vec[i64], arg_count: i32) -> i64:
    let variant_name = self.intern.resolve(variant_sym)
    for ei in 0..self.enum_llvm_types.len() as i32:
        let v_start = self.enum_variant_starts.get(ei as i64)
        let v_count = self.enum_variant_counts.get(ei as i64)
        for vi in 0..v_count:
            let stored_sym = self.enum_variant_names.get((v_start + vi) as i64)
            if stored_sym != variant_sym:
                let stored_name = self.intern.resolve(stored_sym)
                if stored_name != variant_name:
                    continue
            let enum_ty = self.enum_llvm_types.get(ei as i64)
            let alloca = wl_build_alloca(self.builder, enum_ty)
            wl_build_store(self.builder, self.build_default_value(enum_ty), alloca)
            let tag_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 0)
            var tag_val: i64 = 0
            let enum_sym_opt = self.enum_by_llvm.get(enum_ty)
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
    let saved_mir_bbs = self.mir_bb_values
    let saved_mir_unreachable = self.mir_default_unreachable_bbs
    let fresh_cl_mir_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_cl_mir_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_cl_mir_bbs: Vec[i64] = Vec.new()
    let fresh_cl_mir_unreachable: Vec[i64] = Vec.new()
    self.mir_local_ptrs = fresh_cl_mir_locals
    self.mir_local_types = fresh_cl_mir_local_types
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
        var cl_cap_sema_ty = self.sema.ty_i32
        let cl_cap_sema_opt = self.local_sema_types.get(cl_cap_sym)
        if cl_cap_sema_opt.is_some():
            cl_cap_sema_ty = cl_cap_sema_opt.unwrap()
        let cl_cap_local = closure_builder.body.new_local(cl_cap_sema_ty, 0, cl_cap_sym, 1)
        closure_builder.bind_local(cl_cap_sym, cl_cap_local)

    // Register params as MIR locals (locals capture_count+1..)
    for cl_pi in 0..param_count:
        let cl_p_name = self.pool.get_extra(extra_start + cl_pi * 2)
        let cl_p_type_node = self.pool.get_extra(extra_start + cl_pi * 2 + 1)
        var cl_p_sema_ty = self.sema.ty_i32
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
                        cl_p_sema_ty = cl_prim as TypeId
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
            let alloca_opt = saved_allocas.get(sym)
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

    // i32 with_fiber_spawn(fn_ptr: ptr, arg: ptr) -> i32
    if wl_get_named_function(self.llmod, "with_fiber_spawn") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        let ft = wl_function_type(i32_ty, vec_data_i64(&params), 2, 0)
        wl_add_function(self.llmod, "with_fiber_spawn", ft)

    // i64 with_fiber_await(task_id: i32) -> i64
    if wl_get_named_function(self.llmod, "with_fiber_await") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(i32_ty)
        let ft = wl_function_type(i64_ty, vec_data_i64(&params), 1, 0)
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
    let name_str = self.intern.resolve(name_sym)
    if name_sym == 0: return

    let meta = self.pool.find_fn_meta(fn_node)
    if meta < 0: return

    let i32_ty = wl_i32_type(self.context)
    let void_ty = wl_void_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)

    // Resolve return type (default to i32 when no annotation, matching non-async functions)
    let ret_ty = if ret_type_node != 0: self.resolve_type(ret_type_node) else: i32_ty
    self.async_fn_ret_types.insert(name_sym, ret_ty)

    // Resolve param types
    let param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        var p_ty = self.resolve_type(p_type_node)
        if p_ty == 0:
            p_ty = i32_ty
        param_types.push(p_ty)

    // 1. Declare implementation function: name_async(params) -> ret_type
    let impl_fn_type = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count, 0)
    let impl_name = name_str ++ "_async"
    let impl_fn = wl_add_function(self.llmod, impl_name, impl_fn_type)
    self.apply_noalias_param_attrs(impl_fn, param_start, param_count)
    let impl_sym = self.intern.intern(impl_name)
    self.fn_values.insert(impl_sym, impl_fn)
    self.fn_fn_types.insert(impl_sym, impl_fn_type)

    // 2. Create args struct type
    var args_struct_type = wl_struct_type(self.context, vec_data_i64(&param_types), param_count, 0)
    self.async_fn_args_struct_types.insert(name_sym, args_struct_type)

    // 3. Declare fiber trampoline: name_fiber(arg: *void) -> void
    let tramp_params: Vec[i64] = Vec.new()
    tramp_params.push(ptr_ty)
    let tramp_fn_type = wl_function_type(void_ty, vec_data_i64(&tramp_params), 1, 0)
    let tramp_name = name_str ++ "_fiber"
    wl_add_function(self.llmod, tramp_name, tramp_fn_type)

    // 4. Declare the public spawn wrapper: name(params) -> i32 (Task ID)
    let spawn_fn_type = wl_function_type(i32_ty, vec_data_i64(&param_types), param_count, 0)
    let effective_name = self.function_symbol_name(name_sym)
    let spawn_fn = wl_add_function(self.llmod, effective_name, spawn_fn_type)
    self.apply_noalias_param_attrs(spawn_fn, param_start, param_count)
    self.fn_values.insert(name_sym, spawn_fn)
    self.fn_fn_types.insert(name_sym, spawn_fn_type)

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
    0 - 1

fn Codegen.gen_string_literal_raw(self: Codegen, text: str) -> i64:
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some():
        with_eprintln("warning: [string-lit] str struct type not found")
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
        with_eprintln("error: embed_file() argument must be a compile-time string")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    let base_path = if self.current_decl_source_file.len() > 0 and self.current_decl_source_file != "<unknown>":
        self.current_decl_source_file
    else:
        self.source_file
    let path = self.resolve_embed_file_path(base_path, path_value.text)
    let content = with_fs_read_file(path)
    if content.len() == 0:
        with_eprintln("error: embed_file: could not read '" ++ path ++ "'")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    self.gen_string_literal_raw(content)

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
        with_eprintln("warning: [build-str] str struct type not found")
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
    let str_type = if st_opt.is_some(): self.struct_llvm_types.get(st_opt.unwrap() as i64) else wl_i64_type(self.context)
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

// ── derive(Clone) generation ──────────────────────────────────────

fn Codegen.generate_clone_derives(self: Codegen):
    let clone_sym = self.intern.intern("Clone")
    for di in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(di)
        if self.pool.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind != TypeDeclKind.Struct:
            continue
        let meta = self.pool.find_type_meta(decl)
        if meta < 0:
            continue
        let d_start = self.pool.type_meta_derive_start(meta)
        let d_count = self.pool.type_meta_derive_count(meta)
        var has_clone = 0
        for ci in 0..d_count:
            if self.pool.get_extra(d_start + ci) == clone_sym:
                has_clone = 1
        if has_clone == 0:
            continue
        let name_sym = self.pool.get_data0(decl)
        let name_str = self.intern.resolve(name_sym)
        // Only generate if not already declared
        let clone_name = name_str ++ ".clone"
        let clone_fn_sym = self.intern.intern(clone_name)
        if self.fn_values.get(clone_fn_sym).is_some():
            continue
        // Get struct LLVM type
        let st_idx_opt = self.struct_type_map.get(name_sym)
        if not st_idx_opt.is_some():
            continue
        let st_idx = st_idx_opt.unwrap()
        let st_type = self.struct_llvm_types.get(st_idx as i64)
        // Create fn: clone(self: *Type) -> Type { return load(self) }
        let params: Vec[i64] = Vec.new()
        params.push(wl_ptr_type(self.context))
        let fn_type = wl_function_type(st_type, vec_data_i64(&params), 1, 0)
        let function = wl_add_function(self.llmod, clone_name, fn_type)
        wl_set_linkage(function, wl_internal_linkage())
        let entry = wl_append_bb(self.context, function, "entry")
        wl_position_at_end(self.builder, entry)
        let self_ptr = wl_get_param(function, 0)
        let loaded = wl_build_load(self.builder, st_type, self_ptr)
        wl_build_ret(self.builder, loaded)
        self.fn_values.insert(clone_fn_sym, function)
        self.fn_fn_types.insert(clone_fn_sym, fn_type)
        self.record_ref_param(clone_fn_sym, 0, 1)

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

// ── Option method dispatch ────────────────────────────────────────
