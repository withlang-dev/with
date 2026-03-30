// SemaDecl — Pass 1: declaration collection, type registration, trait/impl resolution.

use Sema
use Ast
use Span
use Diagnostic
use InternPool
use render

extern fn with_eprint(s: str) -> void
extern fn with_str_eq(a: str, b: str) -> i32
extern fn int_to_string(n: i32) -> str

// ── Pass 1: Declaration collection ───────────────────────────────

fn Sema.compute_method_origins(self: Sema):
    let dc = self.ast.decl_count()
    for di in 0..dc:
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NodeKind.NK_IMPL_DECL:
            let trait_sym = self.ast.get_data2(decl)
            var origin = 0
            if trait_sym != 0:
                origin = 1
            // Walk backwards finding method fn_decls
            let impl_extra = self.ast.get_data1(decl)
            // Methods are added as decls before the impl_decl
            var j = di
            while j > 0:
                j = j - 1
                let md = self.ast.get_decl(j)
                if self.ast.kind(md) != NodeKind.NK_FN_DECL:
                    break
                let fn_name = self.ast.get_data0(md)
                self.method_decl_origins.insert(j, origin)
                self.method_impl_nodes.insert(fn_name, decl as i32)
                self.method_symbol_flags.insert(fn_name, 1)
                if origin == 0:
                    self.method_has_inherent.insert(fn_name, 1)

    // Top-level method syntax
    for di in 0..dc:
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NodeKind.NK_FN_DECL:
            let fn_name = self.ast.get_data0(decl)
            let parsed_fn_name = self.extract_decl_name_after(decl, "fn")
            if sema_str_contains_char(parsed_fn_name, 46) != 0:
                self.method_symbol_flags.insert(fn_name, 1)
                if not self.method_decl_origins.contains(di):
                    self.method_has_inherent.insert(fn_name, 1)

fn Sema.is_method_symbol(self: Sema, sym: i32) -> i32:
    if sym <= 0:
        return 0
    if self.method_symbol_flags.contains(sym):
        return 1
    return 0

fn Sema.should_skip_trait_method(self: Sema, decl_idx: i32, fn_sym: i32) -> i32:
    if self.is_method_symbol(fn_sym) == 0:
        return 0
    if self.method_decl_origins.contains(decl_idx):
        let origin = self.method_decl_origins.get(decl_idx).unwrap()
        if origin == 1:
            if self.method_has_inherent.contains(fn_sym):
                return 1
    0

fn Sema.collect_declarations(self: Sema):
    self.collecting_types = 1
    // Pass 1: collect named types and traits first so functions can refer
    // to imported or forward-declared types regardless of declaration order.
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        let is_local = self.is_local_decl(di)
        if kind == NodeKind.NK_TYPE_DECL:
            self.collect_type_decl(decl, is_local)
        if kind == NodeKind.NK_TRAIT_DECL:
            self.collect_trait_decl(decl, is_local)

    // Check for circular type dependencies before proceeding.
    self.check_type_cycles()

    // Pass 2: collect impl declarations once trait/type tables exist.
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NodeKind.NK_IMPL_DECL:
            let impl_is_local = self.is_local_decl(di)
            self.collect_impl_decl(decl, impl_is_local)

    self.collecting_types = 0
    self.resolve_deferred_non_generic_type_decls()

    // Pass 3: collect function signatures and top-level let decls.
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        let is_local = self.is_local_decl(di)
        if kind == NodeKind.NK_FN_DECL:
            let fn_name = self.ast.get_data0(decl)
            if self.should_skip_trait_method(di, fn_name) == 0:
                self.collect_fn_decl(decl, is_local)
        if kind == NodeKind.NK_EXTERN_FN:
            self.collect_extern_fn(decl, is_local)
        if kind == NodeKind.NK_EXTERN_VAR:
            self.collect_extern_var(decl, is_local)
        if kind == NodeKind.NK_LET_DECL:
            self.collect_let_decl(decl, is_local)

    // Hardcode Result and Task as must_use types
    let sym_result = self.pool_intern("Result")
    let sym_task = self.pool_intern("Task")
    if sym_result != 0:
        self.must_use_types.insert(sym_result, 1)
    if sym_task != 0:
        self.must_use_types.insert(sym_task, 1)

fn Sema.resolve_deferred_non_generic_type_decls(self: Sema):
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        if self.type_decl_tp_count(decl) != 0:
            continue
        self.resolve_deferred_non_generic_type_decl(decl)

fn Sema.resolve_deferred_non_generic_type_decl(self: Sema, decl: i32):
    let name = self.ast.get_data0(decl)
    if not self.named_types.contains(name):
        return

    let tid = self.named_types.get(name).unwrap()
    let extra_start = self.ast.get_data1(decl)
    let sub_kind = type_decl_sub_kind(self.ast.get_data2(decl))
    let resolved = self.resolve_alias(tid)

    if sub_kind == TypeDeclKind.Struct or sub_kind == TypeDeclKind.Union:
        if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return
        let te_start = self.get_type_d1(resolved)
        let field_count = self.ast.get_extra(extra_start)
        for fi in 0..field_count:
            let field_slot = te_start + fi * 3 + 1
            if self.type_extra.get(field_slot as i64) != 0:
                continue
            let field_base = extra_start + 1 + fi * 3
            let field_type_node = self.ast.get_extra(field_base + 1)
            let field_tid = self.resolve_type_expr(field_type_node)
            if field_tid != 0:
                if self.is_opaque_value_type(field_tid) != 0:
                    self.emit_error("opaque types cannot be stored in struct fields; use a pointer or reference", field_type_node)
                self.type_extra.set_i32(field_slot as i64, field_tid)
        return

    if sub_kind == TypeDeclKind.Enum:
        if self.get_type_kind(resolved) != TypeKind.TY_ENUM:
            return
        let te_start = self.get_type_d1(resolved)
        let variant_count = self.ast.get_extra(extra_start)
        var ast_pos = extra_start + 1
        var type_pos = te_start
        for _ in 0..variant_count:
            ast_pos = ast_pos + 1
            let payload_count = self.ast.get_extra(ast_pos)
            ast_pos = ast_pos + 1
            type_pos = type_pos + 2
            for pi in 0..payload_count:
                let payload_slot = type_pos + pi
                if self.type_extra.get(payload_slot as i64) == 0:
                    let payload_type_node = self.ast.get_extra(ast_pos + pi)
                    let payload_tid = self.resolve_type_expr(payload_type_node)
                    if payload_tid != 0:
                        if self.is_opaque_value_type(payload_tid) != 0:
                            self.emit_error("opaque types cannot be stored in enum payloads by value; use a pointer or reference", payload_type_node)
                        self.type_extra.set_i32(payload_slot as i64, payload_tid)
            ast_pos = ast_pos + payload_count
            type_pos = type_pos + payload_count
        return

    if sub_kind == TypeDeclKind.DiscEnum:
        if self.get_type_kind(resolved) != TypeKind.TY_ENUM:
            return
        let repr_type_node = self.ast.get_extra(extra_start)
        let repr_opt = self.disc_repr_types.get(tid)
        if not repr_opt.is_some() or repr_opt.unwrap() == 0:
            let repr_tid = self.resolve_type_expr(repr_type_node)
            if repr_tid != 0:
                self.disc_repr_types.insert(tid, repr_tid as i32)
        let te_start = self.get_type_d1(resolved)
        let variant_count = self.ast.get_extra(extra_start + 1)
        var ast_pos = extra_start + 2
        var type_pos = te_start
        for _ in 0..variant_count:
            ast_pos = ast_pos + 2
            let payload_count = self.ast.get_extra(ast_pos)
            ast_pos = ast_pos + 1
            type_pos = type_pos + 2
            for pi in 0..payload_count:
                let payload_slot = type_pos + pi
                if self.type_extra.get(payload_slot as i64) == 0:
                    let payload_type_node = self.ast.get_extra(ast_pos + pi)
                    let payload_tid = self.resolve_type_expr(payload_type_node)
                    if payload_tid != 0:
                        if self.is_opaque_value_type(payload_tid) != 0:
                            self.emit_error("opaque types cannot be stored in enum payloads by value; use a pointer or reference", payload_type_node)
                        self.type_extra.set_i32(payload_slot as i64, payload_tid)
            ast_pos = ast_pos + payload_count
            type_pos = type_pos + payload_count
        return

    if sub_kind == TypeDeclKind.Alias:
        if self.get_type_d0(tid) != 0:
            return
        let aliased_node = self.ast.get_extra(extra_start)
        let target_tid = self.resolve_type_expr(aliased_node)
        if target_tid != 0:
            self.type_d0.set_i32(tid as i64, target_tid)
        return

    if sub_kind == TypeDeclKind.Distinct:
        if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return
        let te_start = self.get_type_d1(resolved)
        let value_slot = te_start + 1
        if self.type_extra.get(value_slot as i64) != 0:
            return
        let inner_node = self.ast.get_extra(extra_start)
        let inner_tid = self.resolve_type_expr(inner_node)
        if inner_tid != 0:
            if self.is_opaque_value_type(inner_tid) != 0:
                self.emit_error("opaque types cannot be wrapped by value in distinct types; use a pointer or reference", inner_node)
            self.type_extra.set_i32(value_slot as i64, inner_tid)

fn Sema.is_local_decl(self: Sema, decl_index: i32) -> i32:
    let limit = self.ast.local_decl_count()
    if limit < 0:
        return 1
    // After import merging, decl order is: prelude → user imports → root.
    // Root (local) decls are the last `limit` entries in the merged pool.
    let total = self.ast.decl_count()
    if decl_index >= total - limit:
        return 1
    0

fn Sema.is_local_or_prelude_decl(self: Sema, decl_index: i32) -> i32:
    if self.is_local_decl(decl_index) != 0:
        return 1
    // Prelude decls are also "ours" for orphan rule purposes
    let prelude_limit = self.ast.prelude_decl_count()
    if prelude_limit < 0:
        return 0
    let total = self.ast.decl_count()
    if decl_index >= total - prelude_limit:
        return 1
    0

fn Sema.build_ci_scoping(self: Sema):
    // Build c_import scoping data. Scoping is active when there are multiple
    // distinct module paths AND at least one c_import-origin declaration exists.
    if self.decl_source_paths.len() == 0 or self.decl_is_c_import.len() == 0:
        return
    var has_ci = 0
    var module_count = 0
    var prev_path_sym = 0 - 1
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NodeKind.NK_C_IMPORT and di < self.decl_source_paths.len() as i32:
            let mp_direct = self.pool_intern(self.decl_source_paths.get(di as i64))
            self.ci_modules.insert(mp_direct, 1)
            has_ci = 1
        if di < self.decl_is_c_import.len() as i32 and self.decl_is_c_import.get(di as i64) != 0:
            has_ci = 1
            // Record which module owns this c_import declaration
            if di < self.decl_source_paths.len() as i32:
                let mp = self.pool_intern(self.decl_source_paths.get(di as i64))
                self.ci_modules.insert(mp, 1)
        if di < self.decl_source_paths.len() as i32:
            let ps = self.pool_intern(self.decl_source_paths.get(di as i64))
            if ps != prev_path_sym:
                module_count = module_count + 1
                prev_path_sym = ps
    if has_ci == 0:
        return
    // Scoping (visibility filtering) only activates with multiple modules.
    if module_count >= 2:
        self.scoping_active = 1
    // Always record c_import-origin symbols (needed for auto-coercion).
    for di in 0..self.ast.decl_count():
        if di >= self.decl_is_c_import.len() as i32:
            break
        if self.decl_is_c_import.get(di as i64) == 0:
            continue
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NodeKind.NK_TYPE_DECL or kind == NodeKind.NK_TRAIT_DECL or kind == NodeKind.NK_FN_DECL or kind == NodeKind.NK_EXTERN_FN or kind == NodeKind.NK_EXTERN_VAR or kind == NodeKind.NK_LET_DECL:
            let sym = self.ast.get_data0(decl)
            self.ci_syms.insert(sym, 1)
        // For enum types, also record variant symbols.
        // Disc enums store [repr_type_node, variant_count, ...variants...],
        // so the variant walk must skip the repr node and respect variable
        // payload lengths instead of assuming a fixed stride.
        if kind == NodeKind.NK_TYPE_DECL:
            let packed_kind = self.ast.get_data2(decl)
            let sub_kind = type_decl_sub_kind(packed_kind)
            if sub_kind == TypeDeclKind.Enum or sub_kind == TypeDeclKind.DiscEnum:
                let extra_start = self.ast.get_data1(decl)
                var pos = if sub_kind == TypeDeclKind.DiscEnum: extra_start + 1 else: extra_start
                let variant_count = self.ast.get_extra(pos)
                pos = pos + 1
                for vi in 0..variant_count:
                    let v_sym = self.ast.get_extra(pos)
                    self.ci_syms.insert(v_sym, 1)
                    pos = pos + 1
                    if sub_kind == TypeDeclKind.DiscEnum:
                        pos = pos + 1
                    let payload_count = self.ast.get_extra(pos)
                    pos = pos + 1 + payload_count

fn Sema.is_ci_visible(self: Sema, sym: i32) -> i32:
    // Check if a symbol is visible from the current module context.
    // Returns 1 if visible, 0 if hidden by c_import scoping.
    if self.scoping_active == 0:
        return 1
    if not self.ci_syms.contains(sym):
        return 1
    // Symbol is c_import-origin. It's visible only if the current module
    // itself has c_import declarations (meaning it directly uses c_import).
    if self.current_module_has_ci != 0:
        return 1
    // Also visible if the user explicitly declared it (extern fn, fn, type, etc.)
    // in a non-c_import context. User declarations override c_import scoping.
    var di = 0
    while di < self.ast.decl_count():
        if di < self.decl_is_c_import.len() as i32:
            if self.decl_is_c_import.get(di as i64) != 0:
                di = di + 1
                continue
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NodeKind.NK_FN_DECL or kind == NodeKind.NK_EXTERN_FN or kind == NodeKind.NK_EXTERN_VAR or kind == NodeKind.NK_LET_DECL or kind == NodeKind.NK_TYPE_DECL:
            if self.ast.get_data0(decl) == sym:
                return 1
        di = di + 1
    0

fn Sema.build_ci_destructor_map(self: Sema):
    // Scan function signatures for c_import destructor patterns.
    // A destructor is a method "Type.free" / "Type.destroy" / etc.
    // where the function is c_import-origin.
    for si in 0..self.sig_names.len() as i32:
        let fn_sym = self.sig_names.get(si as i64)
        if not self.ci_syms.contains(fn_sym):
            continue
        let fn_name = self.pool_resolve_symbol(fn_sym)
        // Find dot position
        var dot_pos = -1
        for ci in 0..fn_name.len() as i32:
            if fn_name.byte_at(ci as i64) == 46:
                dot_pos = ci
                break
        if dot_pos <= 0:
            continue
        let method = fn_name.slice((dot_pos + 1) as i64, fn_name.len())
        if method == "free" or method == "destroy" or method == "close" or method == "unref" or method == "release":
            let type_name = fn_name.slice(0, dot_pos as i64)
            let type_sym = self.pool_intern(type_name)
            if self.type_decl_nodes.contains(type_sym):
                if not self.ci_type_destructors.contains(type_sym):
                    self.ci_type_destructors.insert(type_sym, fn_sym)

fn Sema.collect_type_decl(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    if is_local != 0:
        self.set_pretty_symbol(name, self.extract_decl_name_after(node, "type"))
    self.type_decl_nodes.insert(name, node)
    let extra_start = self.ast.get_data1(node)
    let packed_kind = self.ast.get_data2(node)
    let sub_kind = type_decl_sub_kind(packed_kind)
    let is_ephemeral = type_decl_is_ephemeral(packed_kind)

    if sub_kind == TypeDeclKind.Struct:
        let field_count = self.ast.get_extra(extra_start)
        // Resolve all field types first — resolve_type_expr can push to type_extra
        // (e.g. for generic instances), so we must capture te_start AFTER resolving.
        let field_names: Vec[i32] = Vec.new()
        let field_tids: Vec[i32] = Vec.new()
        let field_defaults: Vec[i32] = Vec.new()
        for fi in 0..field_count:
            let base = extra_start + 1 + fi * 3
            let f_name = self.ast.get_extra(base)
            let f_type_node = self.ast.get_extra(base + 1)
            let f_default = self.ast.get_extra(base + 2)
            if not is_ephemeral:
                if self.type_expr_contains_ref(f_type_node) != 0:
                    self.emit_error("ephemeral references cannot be stored in structs", f_type_node)
                if self.type_expr_is_collection_with_ref(f_type_node) != 0:
                    self.emit_error("ephemeral references cannot be stored in generic containers", f_type_node)
                // Check if field type is a user-defined ephemeral type
                if self.ast.kind(f_type_node) == NodeKind.NK_IDENT or self.ast.kind(f_type_node) == NodeKind.NK_TYPE_NAMED:
                    let f_type_sym = self.ast.get_data0(f_type_node)
                    if self.ephemeral_types.contains(f_type_sym):
                        self.emit_error("ephemeral type '" ++ self.pool_resolve(f_type_sym) ++ "' cannot be stored in non-ephemeral struct", f_type_node)
            let f_tid = self.resolve_type_expr(f_type_node)
            if self.is_opaque_value_type(f_tid) != 0:
                self.emit_error("opaque types cannot be stored in struct fields; use a pointer or reference", f_type_node)
            field_names.push(f_name)
            field_tids.push(f_tid as i32)
            field_defaults.push(f_default)
        let te_start = self.type_extra.len() as i32
        for fi in 0..field_count:
            self.type_extra.push(field_names.get(fi as i64))
            self.type_extra.push(field_tids.get(fi as i64))
            self.type_extra.push(field_defaults.get(fi as i64))
        // Alignment array: stored after field triples in AST
        let align_base = extra_start + 1 + field_count * 3
        for fi in 0..field_count:
            self.type_extra.push(self.ast.get_extra(align_base + fi))
        let tid = self.add_type(TypeKind.TY_STRUCT, name, te_start, field_count)
        self.named_types.insert(name, tid as i32)

    if sub_kind == TypeDeclKind.Enum:
        let variant_count = self.ast.get_extra(extra_start)
        let te_start = self.type_extra.len() as i32
        var epos = extra_start + 1
        for vi in 0..variant_count:
            let v_name = self.ast.get_extra(epos)
            epos = epos + 1
            let payload_count = self.ast.get_extra(epos)
            epos = epos + 1
            self.type_extra.push(v_name)
            self.type_extra.push(payload_count)
            for pi in 0..payload_count:
                let pt_node = self.ast.get_extra(epos)
                epos = epos + 1
                let pt_tid = self.resolve_type_expr(pt_node)
                if self.is_opaque_value_type(pt_tid) != 0:
                    self.emit_error("opaque types cannot be stored in enum payloads by value; use a pointer or reference", pt_node)
                self.type_extra.push(pt_tid as i32)
            // Register variant lookup
            self.variant_lookup.insert(v_name, vi)
        let tid = self.add_type(TypeKind.TY_ENUM, name, te_start, variant_count)
        self.named_types.insert(name, tid as i32)
        // Re-register variants with actual enum TypeId (bare + qualified names)
        let plain_type_name_str = self.pool_resolve(name)
        var vpos = te_start
        for vi in 0..variant_count:
            let v_name = self.type_extra.get(vpos as i64)
            self.variant_lookup.insert(v_name, vi)
            self.variant_type_ids.insert(v_name, tid as i32)
            let v_name_str = self.pool_resolve(v_name)
            let qual_name = plain_type_name_str ++ "." ++ v_name_str
            let qual_sym = self.pool_intern(qual_name)
            self.variant_lookup.insert(qual_sym, vi)
            self.variant_type_ids.insert(qual_sym, tid as i32)
            let pc = self.type_extra.get((vpos + 1) as i64)
            vpos = vpos + 2 + pc

    if sub_kind == TypeDeclKind.DiscEnum:
        let repr_type_node = self.ast.get_extra(extra_start)
        let repr_type_tid = self.resolve_type_expr(repr_type_node)
        let variant_count = self.ast.get_extra(extra_start + 1)
        let te_start = self.type_extra.len() as i32
        var epos = extra_start + 2
        var disc_vals: Vec[i32] = Vec.new()
        for vi in 0..variant_count:
            let v_name = self.ast.get_extra(epos)
            epos = epos + 1
            let disc_value = self.ast.get_extra(epos)
            epos = epos + 1
            let payload_count = self.ast.get_extra(epos)
            epos = epos + 1
            self.type_extra.push(v_name)
            self.type_extra.push(payload_count)
            // Check for duplicate discriminant values
            for prev in 0..disc_vals.len() as i32:
                if disc_vals.get(prev as i64) == disc_value:
                    self.emit_error(f"duplicate discriminant value {disc_value}", node)
            // Check discriminant fits in repr type range
            if repr_type_tid == self.ty_i8:
                if disc_value < (0 - 128) or disc_value > 127:
                    self.emit_error(f"discriminant value {disc_value} out of range for i8", node)
            if repr_type_tid == self.ty_i16:
                if disc_value < (0 - 32768) or disc_value > 32767:
                    self.emit_error(f"discriminant value {disc_value} out of range for i16", node)
            disc_vals.push(disc_value)
            for pi in 0..payload_count:
                let pt_node = self.ast.get_extra(epos)
                epos = epos + 1
                let pt_tid = self.resolve_type_expr(pt_node)
                if self.is_opaque_value_type(pt_tid) != 0:
                    self.emit_error("opaque types cannot be stored in enum payloads by value; use a pointer or reference", pt_node)
                self.type_extra.push(pt_tid as i32)
            self.variant_lookup.insert(v_name, vi)
        let tid = self.add_type(TypeKind.TY_ENUM, name, te_start, variant_count)
        self.named_types.insert(name, tid as i32)
        self.disc_repr_types.insert(tid as i32, repr_type_tid as i32)
        // Check if any variant has payloads
        var any_payload = 0
        var check_pos = te_start
        for cv in 0..variant_count:
            check_pos = check_pos + 1  // v_name
            let pc = self.type_extra.get(check_pos as i64)
            check_pos = check_pos + 1 + pc
            if pc > 0:
                any_payload = 1
        if any_payload != 0:
            self.disc_has_payload.insert(tid as i32, 1)
        // Re-register variants with actual enum TypeId and store disc values.
        // Register BOTH bare name (for unqualified pattern matching) and
        // qualified name "TypeName.Variant" (for explicit EnumType.Variant access).
        let type_name_str = self.pool_resolve(name)
        var vpos = te_start
        for vi in 0..variant_count:
            let v_name = self.type_extra.get(vpos as i64)
            let disc_val = disc_vals.get(vi as i64)
            self.variant_lookup.insert(v_name, vi)
            self.variant_type_ids.insert(v_name, tid as i32)
            self.disc_values.insert(v_name, disc_val)
            // Also register qualified name for EnumType.Variant lookup
            let v_name_str = self.pool_resolve(v_name)
            let qual_name = type_name_str ++ "." ++ v_name_str
            let qual_sym = self.pool_intern(qual_name)
            self.variant_lookup.insert(qual_sym, vi)
            self.variant_type_ids.insert(qual_sym, tid as i32)
            self.disc_values.insert(qual_sym, disc_val)
            let pc = self.type_extra.get((vpos + 1) as i64)
            vpos = vpos + 2 + pc

    if sub_kind == TypeDeclKind.Alias:
        let aliased_node = self.ast.get_extra(extra_start)
        let target = self.resolve_type_expr(aliased_node)
        let tid = self.add_type(TypeKind.TY_ALIAS, target as i32, 0, 0)
        self.named_types.insert(name, tid as i32)

    if sub_kind == TypeDeclKind.Distinct:
        let inner_node = self.ast.get_extra(extra_start)
        let inner = self.resolve_type_expr(inner_node)
        if self.is_opaque_value_type(inner) != 0:
            self.emit_error("opaque types cannot be wrapped by value in distinct types; use a pointer or reference", inner_node)
        // Distinct type: treat as single-field struct
        let te_start = self.type_extra.len() as i32
        let val_sym = self.pool_intern("value")
        self.type_extra.push(val_sym)
        self.type_extra.push(inner as i32)
        self.type_extra.push(0)
        let tid = self.add_type(TypeKind.TY_STRUCT, name, te_start, 1)
        self.named_types.insert(name, tid as i32)
        self.distinct_type_names.insert(name, tid as i32)

    if sub_kind == TypeDeclKind.Opaque:
        // Opaque type: register as struct with 0 fields
        let te_start = self.type_extra.len() as i32
        let tid = self.add_type(TypeKind.TY_STRUCT, name, te_start, 0)
        self.named_types.insert(name, tid as i32)

    if sub_kind == TypeDeclKind.Union:
        // Union type: register fields like a struct (codegen handles layout)
        let field_count = self.ast.get_extra(extra_start)
        let field_names: Vec[i32] = Vec.new()
        let field_tids: Vec[i32] = Vec.new()
        let field_defaults: Vec[i32] = Vec.new()
        for fi in 0..field_count:
            let base = extra_start + 1 + fi * 3
            let f_name = self.ast.get_extra(base)
            let f_type_node = self.ast.get_extra(base + 1)
            let f_default = self.ast.get_extra(base + 2)
            let f_tid = self.resolve_type_expr(f_type_node)
            if self.is_opaque_value_type(f_tid) != 0:
                self.emit_error("opaque types cannot be stored in union fields; use a pointer or reference", f_type_node)
            field_names.push(f_name)
            field_tids.push(f_tid as i32)
            field_defaults.push(f_default)
        let te_start = self.type_extra.len() as i32
        for fi in 0..field_count:
            self.type_extra.push(field_names.get(fi as i64))
            self.type_extra.push(field_tids.get(fi as i64))
            self.type_extra.push(field_defaults.get(fi as i64))
        // Alignment array for unions
        let align_base = extra_start + 1 + field_count * 3
        for fi in 0..field_count:
            self.type_extra.push(self.ast.get_extra(align_base + fi))
        let tid = self.add_type(TypeKind.TY_STRUCT, name, te_start, field_count)
        self.named_types.insert(name, tid as i32)

    if is_ephemeral != 0:
        self.ephemeral_types.insert(name, 1)

    if self.ast.is_must_use_type_node(node) != 0:
        self.must_use_types.insert(name, 1)

    if is_local != 0:
        self.local_type_names.insert(name, 1)

// ── Type dependency cycle detection ──────────────────────────────

// Collect named types that a type expression directly embeds (by value).
// Pointers, references, and slices are indirections — not followed.
// Collect named types that a type expression directly embeds (by value).
// Results are accumulated in self.cycle_dep_syms / self.cycle_dep_nodes.
// Pointers, references, and slices are indirections — not followed.
fn Sema.collect_value_type_deps(self: Sema, type_node: i32):
    if type_node == 0:
        return
    let kind = self.ast.kind(type_node)
    if kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.ast.get_data0(type_node)
        // Only track user-declared types, not primitives.
        if self.type_decl_nodes.contains(sym):
            self.cycle_dep_syms.push(sym)
            self.cycle_dep_nodes.push(type_node)
        return
    if kind == NodeKind.NK_TYPE_ARRAY:
        // Arrays embed their element type by value.
        self.collect_value_type_deps(self.ast.get_data0(type_node))
        return
    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(type_node)
        let elem_count = self.ast.get_data1(type_node)
        for ei in 0..elem_count:
            let e_node = self.ast.get_extra(extra_start + ei)
            self.collect_value_type_deps(e_node)
        return
    if kind == NodeKind.NK_TYPE_OPTIONAL:
        // Option embeds the inner type by value.
        self.collect_value_type_deps(self.ast.get_data0(type_node))
        return
    // NodeKind.NK_TYPE_PTR, NodeKind.NK_TYPE_REF, NodeKind.NK_TYPE_SLICE, NodeKind.NK_TYPE_GENERIC,
    // NodeKind.NK_TYPE_FN: all provide indirection — do not follow.

fn Sema.check_type_cycles(self: Sema):
    // Build directed graph: for each type decl, find value-type deps.
    // Use self.cycle_dep_syms/cycle_dep_nodes as accumulators (must go through
    // self for mutation to be visible — Vec params are pass-by-value).

    // Accumulate all edges into cycle_dep_syms (flat: [from, to, from, to, ...])
    // and cycle_dep_nodes (flat: [edge_node, edge_node, ...]) using a stride of 2.
    // Actually, use three separate Sema-level Vecs to avoid complexity.
    // Re-purpose cycle_dep_syms for dep_from and cycle_dep_nodes for dep_to.
    // Add edge node info separately.

    // Instead, accumulate edges directly. For each field type, call
    // collect_value_type_deps which pushes to self.cycle_dep_syms/nodes,
    // then read them back.
    self.cycle_dep_syms = Vec.new()
    self.cycle_dep_nodes = Vec.new()

    // Phase 1: collect all edges. Each edge is 3 consecutive entries:
    // cycle_dep_syms: [from_sym, to_sym, from_sym, to_sym, ...]
    // cycle_dep_nodes: [0, edge_node, 0, edge_node, ...]
    // We'll use a simpler scheme: collect into flat arrays indexed by edge.
    // dep_edge_count tracks how many edges we've collected.

    // Actually simplest: save len before collect, push owner info after.
    var edge_from: Vec[i32] = Vec.new()
    var edge_to: Vec[i32] = Vec.new()
    var edge_node: Vec[i32] = Vec.new()

    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        let name = self.ast.get_data0(decl)
        let extra_start = self.ast.get_data1(decl)
        let packed_kind = self.ast.get_data2(decl)
        let sub_kind = type_decl_sub_kind(packed_kind)

        if sub_kind == TypeDeclKind.Struct:
            let field_count = self.ast.get_extra(extra_start)
            for fi in 0..field_count:
                let base = extra_start + 1 + fi * 3
                let f_type_node = self.ast.get_extra(base + 1)
                let before = self.cycle_dep_syms.len() as i32
                self.collect_value_type_deps(f_type_node)
                let after = self.cycle_dep_syms.len() as i32
                for di2 in before..after:
                    edge_from.push(name)
                    edge_to.push(self.cycle_dep_syms.get(di2 as i64))
                    edge_node.push(self.cycle_dep_nodes.get(di2 as i64))

        if sub_kind == TypeDeclKind.Enum or sub_kind == TypeDeclKind.DiscEnum:
            let variant_start = if sub_kind == TypeDeclKind.DiscEnum: extra_start + 2 else: extra_start + 1
            let variant_count = if sub_kind == TypeDeclKind.DiscEnum: self.ast.get_extra(extra_start + 1) else: self.ast.get_extra(extra_start)
            var epos = variant_start
            for vi in 0..variant_count:
                epos = epos + 1  // v_name
                if sub_kind == TypeDeclKind.DiscEnum:
                    epos = epos + 1  // disc_value
                let payload_count = self.ast.get_extra(epos)
                epos = epos + 1
                for pi in 0..payload_count:
                    let pt_node = self.ast.get_extra(epos)
                    epos = epos + 1
                    let before = self.cycle_dep_syms.len() as i32
                    self.collect_value_type_deps(pt_node)
                    let after = self.cycle_dep_syms.len() as i32
                    for di2 in before..after:
                        edge_from.push(name)
                        edge_to.push(self.cycle_dep_syms.get(di2 as i64))
                        edge_node.push(self.cycle_dep_nodes.get(di2 as i64))

        if sub_kind == TypeDeclKind.Alias:
            let aliased_node = self.ast.get_extra(extra_start)
            let before = self.cycle_dep_syms.len() as i32
            self.collect_value_type_deps(aliased_node)
            let after = self.cycle_dep_syms.len() as i32
            for di2 in before..after:
                edge_from.push(name)
                edge_to.push(self.cycle_dep_syms.get(di2 as i64))
                edge_node.push(self.cycle_dep_nodes.get(di2 as i64))

        if sub_kind == TypeDeclKind.Distinct:
            let inner_node = self.ast.get_extra(extra_start)
            let before = self.cycle_dep_syms.len() as i32
            self.collect_value_type_deps(inner_node)
            let after = self.cycle_dep_syms.len() as i32
            for di2 in before..after:
                edge_from.push(name)
                edge_to.push(self.cycle_dep_syms.get(di2 as i64))
                edge_node.push(self.cycle_dep_nodes.get(di2 as i64))

    if edge_from.len() == 0:
        return

    // DFS cycle detection with coloring.
    // 0=white, 1=gray (in path), 2=black (done)
    var color: HashMap[i32, i32] = sema_new_map_i32_i32()
    // Parent tracking for cycle path reconstruction.
    var parent_sym: HashMap[i32, i32] = sema_new_map_i32_i32()
    var parent_edge: HashMap[i32, i32] = sema_new_map_i32_i32()

    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        let name = self.ast.get_data0(decl)
        if color.contains(name) and color.get(name).unwrap() != 0:
            continue
        // Iterative DFS using explicit stack.
        var stack: Vec[i32] = Vec.new()
        stack.push(name)
        while stack.len() > 0:
            let cur = stack.get(stack.len() - 1)
            let cur_color = if color.contains(cur): color.get(cur).unwrap() else: 0
            if cur_color == 0:
                // First visit: mark gray.
                color.insert(cur, 1)
                // Push neighbors.
                for ei in 0..edge_from.len() as i32:
                    if edge_from.get(ei as i64) != cur:
                        continue
                    let neighbor = edge_to.get(ei as i64)
                    let n_color = if color.contains(neighbor): color.get(neighbor).unwrap() else: 0
                    if n_color == 0:
                        parent_sym.insert(neighbor, cur)
                        parent_edge.insert(neighbor, edge_node.get(ei as i64))
                        stack.push(neighbor)
                    if n_color == 1:
                        // Cycle found! Reconstruct the loop.
                        self.emit_type_cycle_error(neighbor, cur, edge_node.get(ei as i64), parent_sym, parent_edge)
                        return
            else:
                // Already visited (gray revisit or black). Pop and mark black.
                let _ = stack.pop()
                color.insert(cur, 2)

fn Sema.emit_type_cycle_error(self: Sema, cycle_start: i32, cycle_end: i32, closing_edge_node: i32, parent_sym: HashMap[i32, i32], parent_edge: HashMap[i32, i32]):
    // Reconstruct cycle path: cycle_start → ... → cycle_end → cycle_start
    var path_syms: Vec[i32] = Vec.new()
    var path_edges: Vec[i32] = Vec.new()

    // Walk from cycle_end back to cycle_start via parent chain.
    var cur = cycle_end
    while cur != cycle_start:
        path_syms.push(cur)
        if parent_edge.contains(cur):
            path_edges.push(parent_edge.get(cur).unwrap())
        else:
            path_edges.push(0)
        if not parent_sym.contains(cur):
            break
        cur = parent_sym.get(cur).unwrap()
    path_syms.push(cycle_start)

    // Reverse to get forward order: cycle_start → ... → cycle_end
    var fwd_syms: Vec[i32] = Vec.new()
    var fwd_edges: Vec[i32] = Vec.new()
    for i in 0..path_syms.len() as i32:
        fwd_syms.push(path_syms.get((path_syms.len() as i32 - 1 - i) as i64))
    for i in 0..path_edges.len() as i32:
        fwd_edges.push(path_edges.get((path_edges.len() as i32 - 1 - i) as i64))
    // Add closing edge: cycle_end → cycle_start
    fwd_edges.push(closing_edge_node)

    let loop_len = fwd_syms.len() as i32

    // Build diagnostic with primary span at first type decl.
    let first_sym = fwd_syms.get(0)
    let first_node = if self.type_decl_nodes.contains(first_sym): self.type_decl_nodes.get(first_sym).unwrap() else: 0
    let primary_start = self.ast.get_start(first_node)
    let primary_end = self.ast.get_end(first_node)
    var diag = Diagnostic.err(f"dependency loop with length {loop_len}", Span { file: self.local_file_id, start: primary_start, end: primary_end })

    // Add a label for each edge in the loop.
    for i in 0..loop_len:
        let from_sym = fwd_syms.get(i as i64)
        let to_sym = if i + 1 < loop_len: fwd_syms.get((i + 1) as i64) else: fwd_syms.get(0)
        let edge_node = fwd_edges.get(i as i64)
        if edge_node != 0:
            let from_name = self.pool_resolve_symbol(from_sym)
            let to_name = self.pool_resolve_symbol(to_sym)
            let e_start = self.ast.get_start(edge_node)
            let e_end = self.ast.get_end(edge_node)
            diag.add_label(Span { file: self.local_file_id, start: e_start, end: e_end }, "type `" ++ from_name ++ "` depends on `" ++ to_name ++ "` here")

    diag.add_help("break the cycle by using a pointer (`*" ++ self.pool_resolve_symbol(fwd_syms.get(0)) ++ "`) or reference (`&" ++ self.pool_resolve_symbol(fwd_syms.get(0)) ++ "`) for one field")
    self.diags.emit(diag)

fn Sema.collect_fn_decl(self: Sema, node: i32, is_local: i32):
    let fn_name = self.ast.get_data0(node)
    if is_local != 0:
        self.set_pretty_symbol(fn_name, self.extract_decl_name_after(node, "fn"))
    self.fn_decl_nodes.insert(fn_name, node)

    // Look up fn_meta for parameter info
    let meta = self.ast.find_fn_meta(node)
    if meta < 0:
        // No meta available — register with no params
        let fn_tid = self.add_type(TypeKind.TY_FN, 0, 0, self.ty_void)
        self.add_sig(fn_name, fn_tid, self.ty_void, 0, 0, 0)
        return

    let flags = self.ast.fn_meta_flags(meta)
    let ret_node = self.ast.fn_meta_ret(meta)
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let tp_count = self.ast.fn_meta_tp_count(meta)

    // Bind Self to method owner type for dot-name methods
    let self_sym = self.pool_intern("Self")
    var self_type_id = 0
    let fn_name_str = self.pool_resolve(fn_name)
    for ci in 0..fn_name_str.len() as i32:
        if fn_name_str.byte_at(ci as i64) == 46:
            let owner_name = fn_name_str.slice(0, ci as i64)
            let owner_sym = self.pool_intern(owner_name)
            if self.named_types.contains(owner_sym):
                self_type_id = self.named_types.get(owner_sym).unwrap()
                self.named_types.insert(self_sym, self_type_id)
            break

    // Set up associated type bindings if inside a trait impl
    self.assoc_type_bindings.clear()
    if self.method_impl_nodes.contains(fn_name):
        let impl_nd = self.method_impl_nodes.get(fn_name).unwrap()
        let impl_ex = self.ast.get_data1(impl_nd)
        let impl_ac = self.ast.get_extra(impl_ex)
        for iai in 0..impl_ac:
            let at_name = self.ast.get_extra(impl_ex + 1 + iai * 2)
            let at_type_nd = self.ast.get_extra(impl_ex + 1 + iai * 2 + 1)
            let at_tid = self.resolve_type_expr(at_type_nd)
            if at_tid != 0:
                self.assoc_type_bindings.insert(at_name, at_tid as i32)

    // Methods in blanket impls: treat as generic (type params come from impl)
    if tp_count == 0 and self.method_impl_nodes.contains(fn_name):
        let bi_impl = self.method_impl_nodes.get(fn_name).unwrap()
        let bi_tp_meta = self.ast.find_impl_type_params(bi_impl)
        if bi_tp_meta >= 0:
            self.generic_fn_nodes.insert(fn_name, node)
            if self_type_id != 0:
                self.named_types.remove(self_sym)
            return

    // Methods on generic structs: treat as generic (type params come from struct)
    if tp_count == 0 and self_type_id != 0:
        for cfi in 0..fn_name_str.len() as i32:
            if fn_name_str.byte_at(cfi as i64) == 46:
                let cf_owner = fn_name_str.slice(0, cfi as i64)
                let cf_owner_sym = self.pool_intern(cf_owner)
                if self.type_decl_nodes.contains(cf_owner_sym):
                    let cf_td = self.type_decl_nodes.get(cf_owner_sym).unwrap()
                    if self.type_decl_tp_count(cf_td) > 0:
                        self.generic_fn_nodes.insert(fn_name, node)
                        self.named_types.remove(self_sym)
                        return
                break

    // Generic functions: store for later monomorphization
    if tp_count > 0:
        self.generic_fn_nodes.insert(fn_name, node)
        for pi in 0..param_count:
            let p_type_node = self.ast.fn_param_type(param_start, pi)
            self.validate_type_expr_with_type_params(p_type_node, self.ast.fn_meta_tp_start(meta), tp_count)
        self.validate_type_expr_with_type_params(ret_node, self.ast.fn_meta_tp_start(meta), tp_count)
        // Validate where clause references
        self.validate_where_clause(node, self.ast.fn_meta_tp_start(meta), tp_count)
        if self_type_id != 0:
            self.named_types.remove(self_sym)
        return

    // Resolve param types
    let sig_param_start = self.sig_params.len() as i32
    for pi in 0..param_count:
        let p_name_sym = self.ast.fn_param_name(param_start, pi)
        if is_local != 0:
            self.set_pretty_symbol(p_name_sym, self.extract_fn_param_name(node, pi))
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        let p_tid = self.resolve_type_expr(p_type_node)
        if self.is_opaque_value_type(p_tid) != 0:
            self.emit_error("opaque types cannot be passed by value; use a pointer or reference", p_type_node)
        self.sig_params.push(p_tid as i32)

    let ret_type = self.resolve_type_expr(ret_node)
    if self.is_opaque_value_type(ret_type) != 0:
        self.emit_error("opaque types cannot be returned by value; use a pointer or reference", ret_node)
    if ret_node != 0:
        if self.type_expr_contains_ref(ret_node) != 0:
            self.emit_error("ephemeral references cannot be returned from functions", ret_node)
        let ret_kind = self.ast.kind(ret_node)
        if ret_kind == NodeKind.NK_TYPE_NAMED:
            let ret_sym = self.ast.get_data0(ret_node)
            if self.ephemeral_types.contains(ret_sym):
                self.emit_error("ephemeral types cannot be returned from functions", ret_node)
    let actual_ret = ret_type
    if actual_ret == 0 and ret_node == 0:
        // no return type annotation → void
        let _ = 0

    // Build fn type
    let fn_extra_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
    let fn_tid = self.add_type(TypeKind.TY_FN, fn_extra_start, param_count, ret_type)

    self.add_sig(fn_name, fn_tid, ret_type, sig_param_start, param_count, 0)
    let fn_sig_idx = self.get_sig(fn_name)
    self.register_method_sig_alias(node, fn_name, fn_sig_idx)

    // Track must_use
    if (flags / FnFlags.MUST_USE) % 2 == 1:
        self.must_use_fns.insert(fn_name, 1)
    // Track async fns
    if (flags / FnFlags.ASYNC) % 2 == 1:
        self.task_fns.insert(fn_name, 1)

    // Unbind Self
    if self_type_id != 0:
        self.named_types.remove(self_sym)

fn Sema.collect_extern_fn(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    if is_local != 0:
        self.set_pretty_symbol(name, self.extract_decl_name_after(node, "fn"))
    let flags = self.ast.get_data2(node)
    let is_variadic = flags % 2

    let meta = self.ast.find_fn_meta(node)
    if meta < 0:
        let fn_tid = self.add_type(TypeKind.TY_FN, 0, 0, self.ty_void)
        self.add_sig(name, fn_tid, self.ty_void, 0, 0, is_variadic)
        self.extern_fn_names.insert(name, 1)
        return

    let ret_node = self.ast.fn_meta_ret(meta)
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)

    let sig_param_start = self.sig_params.len() as i32
    for pi in 0..param_count:
        let p_name_sym = self.ast.fn_param_name(param_start, pi)
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        if is_local != 0:
            self.set_pretty_symbol(p_name_sym, self.extract_fn_param_name(node, pi))
        let p_tid = self.resolve_type_expr(p_type_node)
        if self.is_opaque_value_type(p_tid) != 0:
            self.emit_error("opaque types cannot be passed by value; use a pointer or reference", p_type_node)
        self.sig_params.push(p_tid as i32)

    let ret_type = self.resolve_type_expr(ret_node)
    if self.is_opaque_value_type(ret_type) != 0:
        self.emit_error("opaque types cannot be returned by value; use a pointer or reference", ret_node)

    let fn_extra_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
    let fn_tid = self.add_type(TypeKind.TY_FN, fn_extra_start, param_count, ret_type)

    self.add_sig(name, fn_tid, ret_type, sig_param_start, param_count, is_variadic)
    self.extern_fn_names.insert(name, 1)

fn Sema.collect_extern_var(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    let type_node = self.ast.get_data1(node)
    let tid = self.resolve_type_expr(type_node)
    if self.is_opaque_value_type(tid) != 0:
        self.emit_error("opaque types cannot be declared as extern values; use a pointer or reference", type_node)
    // Register the extern var for scope lookup
    let is_mut = if self.ast.get_data2(node) != 0: 1 else: 0
    self.scope_put_at(name, tid, is_mut, node)

fn sema_str_find_char(text: str, needle: i32) -> i32:
    for i in 0..text.len() as i32:
        if text[i] == needle:
            return i
    return 0 - 1

fn Sema.impl_owner_type_sym_for_decl(self: Sema, decl: i32) -> i32:
    let start = self.ast.get_start(decl)
    let end = self.ast.get_end(decl)
    var best_span = 0
    var best_sym = 0
    for di in 0..self.ast.decl_count():
        let cand = self.ast.get_decl(di)
        if self.ast.kind(cand) != NodeKind.NK_IMPL_DECL:
            continue
        let impl_start = self.ast.get_start(cand)
        let impl_end = self.ast.get_end(cand)
        if impl_start <= start and end <= impl_end:
            let span = impl_end - impl_start
            if best_sym == 0 or span < best_span:
                best_span = span
                best_sym = self.ast.get_data0(cand)
    best_sym

fn Sema.register_method_sig_alias(self: Sema, node: i32, fn_sym: i32, sig_idx: i32):
    if sig_idx < 0:
        return

    let qualified = self.pool_resolve(fn_sym)
    if qualified.len() == 0:
        return
    let dot = sema_str_find_char(qualified, 46)
    if dot < 0:
        return
    let owner_name = qualified.slice(0, dot as i64)
    let method_name = qualified.slice((dot + 1) as i64, qualified.len() as i64)
    if owner_name.len() == 0 or method_name.len() == 0:
        return

    let owner_sym = self.pool_intern(owner_name)
    let method_sym = self.pool_intern(method_name)
    let key_sym = self.method_key(owner_sym, method_sym)
    self.sig_lookup.insert(key_sym, sig_idx)
    self.method_symbol_flags.insert(fn_sym, 1)

fn Sema.top_level_let_type_ann_extra(self: Sema, flags: i32) -> i32:
    let packed = flags / 4
    if packed <= 0:
        return -1
    packed - 1

fn Sema.local_let_type_ann_extra(self: Sema, flags: i32) -> i32:
    let packed = flags / 2
    if packed <= 0:
        return -1
    packed - 1

fn Sema.collect_let_decl(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    if is_local != 0:
        var bind_name = self.extract_decl_name_after(node, "let")
        if bind_name.len() == 0:
            bind_name = self.extract_decl_name_after(node, "var")
        self.set_pretty_symbol(name, bind_name)
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2
    if is_mut != 0:
        self.mutable_global_syms.insert(name, 1)
    var bind_ty: TypeId = 0 as TypeId
    let type_extra = self.top_level_let_type_ann_extra(flags)
    if type_extra >= 0:
        let type_node = self.ast.get_extra(type_extra)
        bind_ty = self.resolve_type_expr(type_node)
        if self.is_opaque_value_type(bind_ty) != 0:
            self.emit_error("opaque values cannot be stored by value; use a pointer or reference", type_node)
        if self.type_expr_is_collection_with_ref(type_node) != 0:
            self.emit_error("ephemeral references cannot be stored in generic containers", node)
    self.scope_put_at(name, bind_ty as i32, is_mut, node)
    self.typed_binding_types.insert(node, bind_ty as i32)
    self.typed_binding_names.insert(node, name)
    self.typed_binding_muts.insert(node, is_mut)

fn Sema.collect_trait_decl(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    if is_local != 0:
        self.set_pretty_symbol(name, self.extract_decl_name_after(node, "trait"))
    let extra_start = self.ast.get_data1(node)
    // Store trait info
    let trait_idx = self.trait_name_syms.len() as i32
    self.trait_name_syms.push(name)
    self.trait_method_starts.push(self.trait_method_names.len() as i32)
    // Trait extra layout:
    // [tp_count, tp_start,
    //  assoc_count,
    //   [assoc_name, bound_count, bounds..., default_type]*,
    //  method_count,
    //   [method_name, method_flags, param_start, param_count, ret_type, default_body]*]
    var pos = extra_start
    let tp_count = self.ast.get_extra(pos)
    let tp_start_ast = self.ast.get_extra(pos + 1)
    pos = pos + 2
    self.trait_tp_starts.push(self.trait_tp_syms.len() as i32)
    self.trait_tp_counts.push(tp_count)
    var tp_pos = tp_start_ast
    for tpi in 0..tp_count:
        self.trait_tp_syms.push(self.ast.get_extra(tp_pos))
        let bc = self.ast.get_extra(tp_pos + 1)
        tp_pos = tp_pos + 2 + bc
    let assoc_count = self.ast.get_extra(pos)
    pos = pos + 1
    // Store associated type declarations for this trait
    self.trait_assoc_starts.push(self.trait_assoc_names.len() as i32)
    self.trait_assoc_counts.push(assoc_count)
    for ai in 0..assoc_count:
        let at_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        self.trait_assoc_bound_starts.push(self.trait_assoc_bound_syms.len() as i32)
        self.trait_assoc_bound_counts.push(bound_count)
        for bi in 0..bound_count:
            self.trait_assoc_bound_syms.push(self.ast.get_extra(pos + 2 + bi))
        pos = pos + 2 + bound_count
        let default_type = self.ast.get_extra(pos)
        pos = pos + 1
        self.trait_assoc_names.push(at_name)
        self.trait_assoc_defaults.push(default_type)

    let method_count = self.ast.get_extra(pos)
    pos = pos + 1
    for i in 0..method_count:
        self.trait_method_names.push(self.ast.get_extra(pos))
        pos = pos + 6
    self.trait_method_counts.push(method_count)
    self.trait_lookup.insert(name, trait_idx)
    if self.ast.is_sealed_trait_node(node) != 0:
        self.sealed_traits.insert(name, 1)
    if is_local != 0:
        self.local_trait_names.insert(name, 1)

// Check if a new direct impl overlaps with any existing blanket impl
fn Sema.check_direct_overlap(self: Sema, type_name: i32, trait_sym: i32, node: i32):
    for bi in 0..self.blanket_trait_syms.len() as i32:
        if self.blanket_trait_syms.get(bi as i64) != trait_sym:
            continue
        let b_start = self.blanket_bound_starts.get(bi as i64)
        let b_count = self.blanket_bound_counts.get(bi as i64)
        var all_ok = 1
        for bj in 0..b_count:
            let bound_trait = self.blanket_bound_syms.get((b_start + bj) as i64)
            if self.select_trait_impl(type_name, bound_trait) == 0:
                all_ok = 0
        if all_ok != 0:
            let tn = self.pool_resolve(trait_sym)
            self.emit_error("overlapping implementations of '" ++ tn ++ "'", node)

// Check if a new blanket impl overlaps with any existing direct impl
fn Sema.check_blanket_overlap(self: Sema, trait_sym: i32, bound_start: i32, bound_count: i32, node: i32):
    for ti in 0..self.impl_type_syms.len() as i32:
        let t_sym = self.impl_type_syms.get(ti as i64)
        let t_start = self.impl_starts.get(ti as i64)
        let t_count = self.impl_counts.get(ti as i64)
        var has_trait = 0
        for i in 0..t_count:
            if self.impl_extra.get((t_start + i) as i64) == trait_sym:
                has_trait = 1
        if has_trait == 0:
            continue
        // This type has a direct impl of the same trait — check bounds
        var all_ok = 1
        for bj in 0..bound_count:
            let bound_trait = self.blanket_bound_syms.get((bound_start + bj) as i64)
            if self.select_trait_impl(t_sym, bound_trait) == 0:
                all_ok = 0
        if all_ok != 0:
            let tn = self.pool_resolve(trait_sym)
            self.emit_error("overlapping implementations of '" ++ tn ++ "'", node)

fn Sema.collect_impl_decl(self: Sema, node: i32, is_local_impl: i32):
    let type_name = self.ast.get_data0(node)
    let trait_sym = self.ast.get_data2(node)
    if trait_sym == 0:
        return

    let trait_name = self.pool_resolve(trait_sym)
    let is_lang_trait = self.lang_trait_syms.contains(trait_sym)
    if not is_lang_trait and not self.trait_lookup.contains(trait_sym):
        self.emit_error("unknown trait", node)
        return

    // Orphan rule: only enforced for local (user) impls, not prelude/imported
    if is_local_impl != 0:
        let trait_is_local = self.local_trait_names.contains(trait_sym) or is_lang_trait
        let type_is_local = self.local_type_names.contains(type_name)
        if not trait_is_local and not type_is_local:
            self.emit_error("orphan rule violation: impl requires a local trait or local type", node)
            return

    // Sealed trait check: only the defining module can impl
    let trait_is_local_for_sealed = self.local_trait_names.contains(trait_sym) or is_lang_trait
    if self.sealed_traits.contains(trait_sym) and not trait_is_local_for_sealed:
        self.emit_error("cannot implement sealed trait '" ++ self.pool_resolve(trait_sym) ++ "' outside its defining module", node)
        return

    // Copy trait validation: all fields must be Copy, type must not implement Drop
    if trait_name == "Copy":
        // Check if this type already has a Drop impl (via impl_extra, since
        // Drop methods aren't collected yet at this point in Pass 2)
        let drop_sym = self.pool_intern("Drop")
        if self.impl_lookup.contains(type_name):
            let drop_idx = self.impl_lookup.get(type_name).unwrap()
            let drop_start = self.impl_starts.get(drop_idx as i64)
            let drop_count = self.impl_counts.get(drop_idx as i64)
            for di in 0..drop_count:
                if self.impl_extra.get((drop_start + di) as i64) == drop_sym:
                    self.emit_error("type '" ++ self.pool_resolve(type_name) ++ "' cannot implement Copy because it implements Drop", node)
                    return
        let type_tid = if self.named_types.contains(type_name): self.named_types.get(type_name).unwrap() else: 0
        if type_tid > 0:
            let tk = self.get_type_kind(self.resolve_alias(type_tid))
            if tk == TypeKind.TY_STRUCT:
                let resolved = self.resolve_alias(type_tid)
                let te_start = self.get_type_d1(resolved)
                let field_count = self.get_type_d2(resolved)
                for fi in 0..field_count:
                    let ft = self.type_extra.get((te_start + fi * 3 + 1) as i64)
                    if self.is_copy(ft) == 0:
                        let field_name = self.type_extra.get((te_start + fi * 3) as i64)
                        self.emit_error("type '" ++ self.pool_resolve(type_name) ++ "' cannot implement Copy: field '" ++ self.pool_resolve(field_name) ++ "' is not Copy", node)
                        return

    // Validate associated types: impl must provide all required (no-default) associated types
    if not is_lang_trait and self.trait_lookup.contains(trait_sym):
        let trait_idx = self.trait_lookup.get(trait_sym).unwrap()
        let at_start = self.trait_assoc_starts.get(trait_idx as i64)
        let at_count = self.trait_assoc_counts.get(trait_idx as i64)
        if at_count > 0:
            // Read impl's associated type bindings from AST extra
            let impl_extra_start = self.ast.get_data1(node)
            let impl_at_count = self.ast.get_extra(impl_extra_start)
            for ati in 0..at_count:
                let required_name = self.trait_assoc_names.get((at_start + ati) as i64)
                let default_type = self.trait_assoc_defaults.get((at_start + ati) as i64)
                if default_type != 0:
                    continue
                // Check if impl provides this associated type
                var found = 0
                for iai in 0..impl_at_count:
                    let impl_at_name = self.ast.get_extra(impl_extra_start + 1 + iai * 2)
                    if impl_at_name == required_name:
                        found = 1
                if found == 0:
                    self.emit_error("impl missing required associated type '" ++ self.pool_resolve(required_name) ++ "'", node)
                    return
            // Validate associated type bounds
            for ati in 0..at_count:
                let at_global_idx = at_start + ati
                if at_global_idx < self.trait_assoc_bound_starts.len() as i32:
                    let ab_start = self.trait_assoc_bound_starts.get(at_global_idx as i64)
                    let ab_count = self.trait_assoc_bound_counts.get(at_global_idx as i64)
                    if ab_count > 0:
                        let at_name_sym = self.trait_assoc_names.get(at_global_idx as i64)
                        // Find the concrete type from impl's associated type bindings
                        var impl_at_type_node = 0
                        for iai in 0..impl_at_count:
                            let impl_at_name = self.ast.get_extra(impl_extra_start + 1 + iai * 2)
                            if impl_at_name == at_name_sym:
                                impl_at_type_node = self.ast.get_extra(impl_extra_start + 1 + iai * 2 + 1)
                        if impl_at_type_node != 0:
                            let impl_at_tid = self.resolve_type_expr(impl_at_type_node)
                            if impl_at_tid > 0:
                                let impl_at_type_sym = self.get_type_d0(impl_at_tid)
                                if impl_at_type_sym != 0:
                                    for bi in 0..ab_count:
                                        let bound_sym = self.trait_assoc_bound_syms.get((ab_start + bi) as i64)
                                        if self.select_trait_impl(impl_at_type_sym, bound_sym) == 0:
                                            let tname = self.pool_resolve(at_name_sym)
                                            let bname = self.pool_resolve(bound_sym)
                                            self.emit_error("associated type '" ++ tname ++ "' does not satisfy bound '" ++ bname ++ "'", node)
                                            return

    // Check for blanket impl (impl-level type params)
    let tp_meta_idx = self.ast.find_impl_type_params(node)
    if tp_meta_idx >= 0:
        // Blanket impl: collect bounds and register
        let tp_start = self.ast.impl_type_params.get((tp_meta_idx + 1) as i64)
        let tp_count = self.ast.impl_type_params.get((tp_meta_idx + 2) as i64)
        let bound_start = self.blanket_bound_syms.len() as i32
        var total_bounds = 0
        var tp_off = tp_start
        for tpi in 0..tp_count:
            let bound_count = self.ast.get_extra(tp_off + 1)
            tp_off = tp_off + 2
            for bi in 0..bound_count:
                let bound_sym = self.ast.get_extra(tp_off + bi)
                self.blanket_bound_syms.push(bound_sym)
                total_bounds = total_bounds + 1
            tp_off = tp_off + bound_count
        self.blanket_trait_syms.push(trait_sym)
        self.blanket_bound_starts.push(bound_start)
        self.blanket_bound_counts.push(total_bounds)
        // Store target base sym for generic blanket impls (e.g., impl[T] Trait for Vec[T])
        let target_type_nd = self.ast.find_impl_target_type_node(node)
        if target_type_nd != 0 and self.ast.kind(target_type_nd) == NodeKind.NK_TYPE_GENERIC:
            self.blanket_target_base_syms.push(self.ast.get_data0(target_type_nd))
        else:
            self.blanket_target_base_syms.push(0)
        // Overlap check: blanket vs existing direct impls
        self.check_blanket_overlap(trait_sym, bound_start, total_bounds, node)
        return

    // If the impl target is a generic type (e.g., impl Trait for Vec[i32]),
    // resolve the full type and record it for exact-match trait selection.
    let target_type_node = self.ast.find_impl_target_type_node(node)
    if target_type_node != 0:
        let target_tid = self.resolve_type_expr(target_type_node)
        if target_tid != 0 and self.get_type_kind(target_tid) == TypeKind.TY_GENERIC_INST:
            let gi_key = i64_to_string(target_tid as i64) ++ ":" ++ i64_to_string(trait_sym as i64)
            self.impl_generic_inst.insert(gi_key, 1)

    // Overlap check: direct impl vs existing blanket impls
    self.check_direct_overlap(type_name, trait_sym, node)

    // Record direct impl
    // When appending to an existing type, relocate all entries to keep them
    // contiguous (the flat impl_extra vec is shared across all types).
    if self.impl_lookup.contains(type_name):
        let idx = self.impl_lookup.get(type_name).unwrap()
        let old_start = self.impl_starts.get(idx as i64)
        let old_count = self.impl_counts.get(idx as i64)
        for i in 0..old_count:
            if self.impl_extra.get((old_start + i) as i64) == trait_sym:
                self.emit_error("duplicate implementation of trait for type", node)
                return
        // Copy existing entries to end for contiguity
        let new_start = self.impl_extra.len() as i32
        for i in 0..old_count:
            self.impl_extra.push(self.impl_extra.get((old_start + i) as i64))
        self.impl_extra.push(trait_sym)
        self.impl_starts.set_i32(idx as i64, new_start)
        self.impl_counts.set_i32(idx as i64, old_count + 1)
    else:
        let idx = self.impl_type_syms.len() as i32
        self.impl_type_syms.push(type_name)
        self.impl_starts.push(self.impl_extra.len() as i32)
        self.impl_counts.push(1)
        self.impl_extra.push(trait_sym)
        self.impl_lookup.insert(type_name, idx)

    // Track sealed trait implementors
    if self.sealed_traits.contains(trait_sym):
        if self.sealed_impl_starts.contains(trait_sym):
            let si_start = self.sealed_impl_starts.get(trait_sym).unwrap()
            let si_count = self.sealed_impl_counts.get(trait_sym).unwrap()
            // Check for duplicate
            var already = false
            for si in 0..si_count:
                if self.sealed_impl_types.get((si_start + si) as i64) == type_name:
                    already = true
                    break
            if not already:
                // Relocate to end for contiguity
                let new_start = self.sealed_impl_types.len() as i32
                for si in 0..si_count:
                    self.sealed_impl_types.push(self.sealed_impl_types.get((si_start + si) as i64))
                self.sealed_impl_types.push(type_name)
                self.sealed_impl_starts.insert(trait_sym, new_start)
                self.sealed_impl_counts.insert(trait_sym, si_count + 1)
        else:
            self.sealed_impl_starts.insert(trait_sym, self.sealed_impl_types.len() as i32)
            self.sealed_impl_counts.insert(trait_sym, 1)
            self.sealed_impl_types.push(type_name)

fn sema_trait_method_flag_generic -> i32: 4

fn Sema.type_is_dyn_object(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_TRAIT_OBJ:
        return 1
    if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
        return self.type_is_dyn_object(self.get_type_d0(resolved))
    0

fn Sema.find_trait_decl_node(self: Sema, trait_sym: i32) -> NodeId:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NodeKind.NK_TRAIT_DECL and self.ast.get_data0(decl) == trait_sym:
            return decl
    0 as NodeId

fn Sema.emit_trait_object_safety_error(self: Sema, trait_sym: i32, method_sym: i32, reason: str, node: i32):
    let trait_name = self.pool_resolve(trait_sym)
    let method_name = self.pool_resolve(method_sym)
    self.emit_error("trait '" ++ trait_name ++ "' is not object-safe: method '" ++ method_name ++ "' " ++ reason, node)

fn Sema.ensure_trait_object_safe(self: Sema, trait_sym: i32, node: i32) -> i32:
    let trait_node = self.find_trait_decl_node(trait_sym)
    if trait_node == 0:
        return 1

    let extra_start = self.ast.get_data1(trait_node)
    var pos = extra_start
    pos = pos + 2  // skip tp_count and tp_start
    let assoc_count = self.ast.get_extra(pos)
    pos = pos + 1
    for ai in 0..assoc_count:
        let bound_count = self.ast.get_extra(pos + 1)
        pos = pos + 2 + bound_count + 1

    let method_count = self.ast.get_extra(pos)
    pos = pos + 1

    let self_name_sym = self.pool_intern("self")
    let self_type_sym = self.pool_intern("Self")
    for mi in 0..method_count:
        let method_sym = self.ast.get_extra(pos)
        pos = pos + 1
        let method_flags = self.ast.get_extra(pos)
        pos = pos + 1
        let param_start = self.ast.get_extra(pos)
        pos = pos + 1
        let param_count = self.ast.get_extra(pos)
        pos = pos + 1
        let ret_node = self.ast.get_extra(pos)
        pos = pos + 1
        pos = pos + 1 // default body

        if param_count <= 0:
            self.emit_trait_object_safety_error(trait_sym, method_sym, "has no self parameter", node)
            return 0

        let first_param_name = self.ast.fn_param_name(param_start, 0)
        if first_param_name != self_name_sym:
            self.emit_trait_object_safety_error(trait_sym, method_sym, "has no self parameter", node)
            return 0

        if (method_flags / sema_trait_method_flag_generic()) % 2 == 1:
            self.emit_trait_object_safety_error(trait_sym, method_sym, "is generic", node)
            return 0

        if ret_node != 0 and self.ast.kind(ret_node) == NodeKind.NK_TYPE_NAMED and self.ast.get_data0(ret_node) == self_type_sym:
            self.emit_trait_object_safety_error(trait_sym, method_sym, "returns Self", node)
            return 0

    1

fn Sema.validate_type_expr_with_type_params(self: Sema, node: i32, tp_start: i32, tp_count: i32):
    if node == 0:
        return

    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.ast.get_data0(node)
        if self.primitive_type_by_sym(sym) != 0:
            return
        if self.named_types.contains(sym):
            return
        if self.type_param_exists(tp_start, tp_count, sym) != 0:
            return
        // Allow Self in method contexts (resolved at codegen time)
        if self.pool_resolve(sym) == "Self":
            return
        self.debug_unknown_type(sym, node, "validate_type_expr")
        self.emit_unknown_type_error(sym, node)
        return

    if kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_OPTIONAL or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_ARRAY:
        self.validate_type_expr_with_type_params(self.ast.get_data0(node), tp_start, tp_count)
        return

    if kind == NodeKind.NK_TYPE_FN:
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        let ret_node = self.ast.get_data2(node)
        for pi in 0..param_count:
            self.validate_type_expr_with_type_params(self.ast.get_extra(extra_start + pi), tp_start, tp_count)
        self.validate_type_expr_with_type_params(ret_node, tp_start, tp_count)
        return

    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            self.validate_type_expr_with_type_params(self.ast.get_extra(extra_start + ei), tp_start, tp_count)
        return

    if kind == NodeKind.NK_TYPE_GENERIC:
        let base_sym = self.ast.get_data0(node)
        let base_prim = self.primitive_type_by_sym(base_sym)
        if base_prim == 0 and not self.named_types.contains(base_sym) and self.type_param_exists(tp_start, tp_count, base_sym) == 0:
            self.debug_unknown_type(base_sym, node, "validate_type_generic")
            self.emit_unknown_type_error(base_sym, node)
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            self.validate_type_expr_with_type_params(self.ast.get_extra(extra_start + ai), tp_start, tp_count)
        return

    if kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        let trait_sym = self.ast.get_data0(node)
        if not self.lang_trait_syms.contains(trait_sym) and not self.trait_lookup.contains(trait_sym):
            self.emit_error("unknown trait", node)
            return
        let _ok = self.ensure_trait_object_safe(trait_sym, node)
        return

fn Sema.validate_where_clause(self: Sema, fn_node: i32, tp_start: i32, tp_count: i32):
    let where_idx = self.ast.find_where_meta(fn_node)
    if where_idx < 0:
        return
    let where_start = self.ast.where_meta.get((where_idx + 1) as i64)
    let where_count = self.ast.where_meta.get((where_idx + 2) as i64)
    var pos = where_start
    for wi in 0..where_count:
        let wp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        // Validate type param references a known type parameter
        if self.type_param_exists(tp_start, tp_count, wp_name) == 0:
            let wp_str = self.pool_resolve(wp_name)
            self.emit_error("where clause references unknown type parameter '" ++ wp_str ++ "'", fn_node)
        // Validate each bound references a known trait
        for bi in 0..bound_count:
            let trait_sym = self.ast.get_extra(pos + 2 + bi)
            let trait_name = self.pool_resolve(trait_sym)
            if trait_name == "type":
                continue
            if not self.lang_trait_syms.contains(trait_sym) and not self.trait_lookup.contains(trait_sym):
                self.emit_error("where clause references unknown trait '" ++ trait_name ++ "'", fn_node)
        pos = pos + 2 + bound_count

fn Sema.type_decl_enum_tail_index(self: Sema, extra_start: i32) -> i32:
    var pos = extra_start
    let variant_count = self.ast.get_extra(pos)
    pos = pos + 1
    for vi in 0..variant_count:
        pos = pos + 1 // variant name
        let payload_count = self.ast.get_extra(pos)
        pos = pos + 1 + payload_count
    pos

fn Sema.type_decl_disc_enum_tail_index(self: Sema, extra_start: i32) -> i32:
    var pos = extra_start + 1 // skip repr_type_node
    let variant_count = self.ast.get_extra(pos)
    pos = pos + 1
    for vi in 0..variant_count:
        pos = pos + 1 // variant name
        pos = pos + 1 // disc value
        let payload_count = self.ast.get_extra(pos)
        pos = pos + 1 + payload_count
    pos

fn Sema.type_decl_tp_start(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data1(node)
    let sub_kind = type_decl_sub_kind(self.ast.get_data2(node))
    if sub_kind == TypeDeclKind.Struct:
        let field_count = self.ast.get_extra(extra_start)
        return self.ast.get_extra(extra_start + 1 + field_count * 4 + 1)
    if sub_kind == TypeDeclKind.Enum:
        let tail = self.type_decl_enum_tail_index(extra_start)
        return self.ast.get_extra(tail + 1)
    if sub_kind == TypeDeclKind.DiscEnum:
        let tail = self.type_decl_disc_enum_tail_index(extra_start)
        return self.ast.get_extra(tail + 1)
    if sub_kind == TypeDeclKind.Alias or sub_kind == TypeDeclKind.Distinct:
        return self.ast.get_extra(extra_start + 2)
    0

fn Sema.type_decl_tp_count(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data1(node)
    let sub_kind = type_decl_sub_kind(self.ast.get_data2(node))
    if sub_kind == TypeDeclKind.Struct:
        let field_count = self.ast.get_extra(extra_start)
        return self.ast.get_extra(extra_start + 1 + field_count * 4 + 2)
    if sub_kind == TypeDeclKind.Enum:
        let tail = self.type_decl_enum_tail_index(extra_start)
        return self.ast.get_extra(tail + 2)
    if sub_kind == TypeDeclKind.DiscEnum:
        let tail = self.type_decl_disc_enum_tail_index(extra_start)
        return self.ast.get_extra(tail + 2)
    if sub_kind == TypeDeclKind.Alias or sub_kind == TypeDeclKind.Distinct:
        return self.ast.get_extra(extra_start + 3)
    0

fn Sema.type_decl_has_derive(self: Sema, node: i32, trait_sym: i32) -> i32:
    let meta = self.ast.find_type_meta(node)
    if meta < 0:
        return 0
    let derive_start = self.ast.type_meta_derive_start(meta)
    let derive_count = self.ast.type_meta_derive_count(meta)
    for i in 0..derive_count:
        if self.ast.get_extra(derive_start + i) == trait_sym:
            return 1
    0

fn Sema.validate_copy_derives(self: Sema):
    let copy_sym = self.pool_intern("Copy")
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        if self.type_decl_has_derive(decl, copy_sym) == 0:
            continue

        let type_name = self.ast.get_data0(decl)
        if self.has_drop_method(type_name) != 0:
            self.emit_error("type cannot be both Copy and Drop", decl)
            continue

        if not self.named_types.contains(type_name):
            continue
        let tid = self.named_types.get(type_name).unwrap()
        let resolved = self.resolve_alias(tid)
        if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            continue

        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        var has_noncopy_field = 0
        for fi in 0..field_count:
            let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
            if field_tid == 0 or self.is_copy(field_tid) == 0:
                has_noncopy_field = 1
                break
        if has_noncopy_field != 0:
            self.emit_error("cannot derive Copy for a type with non-Copy fields", decl)

fn Sema.validate_generic_type_decls(self: Sema):
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue

        let tp_count = self.type_decl_tp_count(decl)
        if tp_count <= 0:
            continue
        let tp_start = self.type_decl_tp_start(decl)
        let extra_start = self.ast.get_data1(decl)
        let sub_kind = type_decl_sub_kind(self.ast.get_data2(decl))

        if sub_kind == TypeDeclKind.Struct:
            let field_count = self.ast.get_extra(extra_start)
            for fi in 0..field_count:
                let field_type = self.ast.get_extra(extra_start + 1 + fi * 3 + 1)
                self.validate_type_expr_with_type_params(field_type, tp_start, tp_count)
            continue

        if sub_kind == TypeDeclKind.Enum:
            var pos = extra_start
            let variant_count = self.ast.get_extra(pos)
            pos = pos + 1
            for vi in 0..variant_count:
                pos = pos + 1 // variant name
                let payload_count = self.ast.get_extra(pos)
                pos = pos + 1
                for pi in 0..payload_count:
                    let payload_ty = self.ast.get_extra(pos + pi)
                    self.validate_type_expr_with_type_params(payload_ty, tp_start, tp_count)
                pos = pos + payload_count
            continue

        if sub_kind == TypeDeclKind.DiscEnum:
            var pos = extra_start + 1 // skip repr_type_node
            let variant_count = self.ast.get_extra(pos)
            pos = pos + 1
            for vi in 0..variant_count:
                pos = pos + 1 // variant name
                pos = pos + 1 // disc value
                let payload_count = self.ast.get_extra(pos)
                pos = pos + 1
                for pi in 0..payload_count:
                    let payload_ty = self.ast.get_extra(pos + pi)
                    self.validate_type_expr_with_type_params(payload_ty, tp_start, tp_count)
                pos = pos + payload_count
            continue

        if sub_kind == TypeDeclKind.Alias or sub_kind == TypeDeclKind.Distinct:
            self.validate_type_expr_with_type_params(self.ast.get_extra(extra_start), tp_start, tp_count)

fn Sema.type_expr_mentions_type_param(self: Sema, type_node: i32, tp_sym: i32) -> i32:
    if type_node == 0:
        return 0
    let kind = self.ast.kind(type_node)
    if kind == NodeKind.NK_TYPE_NAMED:
        return if self.ast.get_data0(type_node) == tp_sym: 1 else: 0
    if kind == NodeKind.NK_TYPE_GENERIC:
        if self.ast.get_data0(type_node) == tp_sym:
            return 1
        let extra_start = self.ast.get_data1(type_node)
        let arg_count = self.ast.get_data2(type_node)
        for ai in 0..arg_count:
            if self.type_expr_mentions_type_param(self.ast.get_extra(extra_start + ai), tp_sym) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_OPTIONAL or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_ARRAY:
        return self.type_expr_mentions_type_param(self.ast.get_data0(type_node), tp_sym)
    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(type_node)
        let elem_count = self.ast.get_data1(type_node)
        for ei in 0..elem_count:
            if self.type_expr_mentions_type_param(self.ast.get_extra(extra_start + ei), tp_sym) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_TYPE_FN:
        let extra_start = self.ast.get_data0(type_node)
        let param_count = self.ast.get_data1(type_node)
        for pi in 0..param_count:
            if self.type_expr_mentions_type_param(self.ast.get_extra(extra_start + pi), tp_sym) != 0:
                return 1
        return self.type_expr_mentions_type_param(self.ast.get_data2(type_node), tp_sym)
    0

fn Sema.type_param_mentions_any_param_type(self: Sema, tp_sym: i32, param_start: i32, param_count: i32) -> i32:
    for pi in 0..param_count:
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        if self.type_expr_mentions_type_param(p_type_node, tp_sym) != 0:
            return 1
    0

fn Sema.ensure_generic_substitutions(self: Sema, tp_start: i32, tp_count: i32, param_start: i32, param_count: i32, call_node: i32):
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        if self.lookup_generic_subst(tp_name) == 0:
            if self.type_param_mentions_any_param_type(tp_name, param_start, param_count) != 0:
                self.put_generic_subst(tp_name, self.ty_i32, call_node)
            else:
                self.emit_error("unknown type", call_node)
                return
        pos = pos + 2 + bound_count

fn Sema.primitive_type_by_sym(self: Sema, sym: i32) -> i32:
    let name = self.pool_resolve_symbol(sym)
    if with_str_eq(name, "i8") != 0: return self.ty_i8 as i32
    if with_str_eq(name, "i16") != 0: return self.ty_i16 as i32
    if with_str_eq(name, "i32") != 0: return self.ty_i32 as i32
    if with_str_eq(name, "i64") != 0: return self.ty_i64 as i32
    if with_str_eq(name, "i128") != 0: return self.ty_i128 as i32
    if with_str_eq(name, "u8") != 0: return self.ty_u8 as i32
    if with_str_eq(name, "u16") != 0: return self.ty_u16 as i32
    if with_str_eq(name, "u32") != 0: return self.ty_u32 as i32
    if with_str_eq(name, "u64") != 0: return self.ty_u64 as i32
    if with_str_eq(name, "u128") != 0: return self.ty_u128 as i32
    if with_str_eq(name, "f32") != 0: return self.ty_f32 as i32
    if with_str_eq(name, "f64") != 0: return self.ty_f64 as i32
    if with_str_eq(name, "bool") != 0: return self.ty_bool as i32
    if with_str_eq(name, "void") != 0: return self.ty_void as i32
    if with_str_eq(name, "Never") != 0: return self.ty_never as i32
    if with_str_eq(name, "str") != 0: return self.ty_str as i32
    if with_str_eq(name, "String") != 0: return self.ty_str as i32
    if with_str_eq(name, "StrView") != 0: return self.ty_str_view as i32
    if with_str_eq(name, "usize") != 0: return self.ty_usize as i32
    if with_str_eq(name, "isize") != 0: return self.ty_isize as i32
    0
