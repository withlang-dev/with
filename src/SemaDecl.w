// SemaDecl — Pass 1: declaration collection, type registration, trait/impl resolution.

use Sema
use Ast
use Span
use Diagnostic
use InternPool
use CapabilityRegistry
use render
use std.collections.HashMap

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_eprint(s: &str) -> Unit

// ── Pass 1: Declaration collection ───────────────────────────────

impl Sema:
    mut fn compute_method_origins():
        let dc = self.ast.decl_count()
        for di in 0..dc:
            let decl = self.ast.get_decl(di)
            let kind = self.ast.kind(decl)
            if kind == NodeKind.NK_IMPL_DECL:
                let trait_sym = self.ast.get_data2(decl)
                var origin = 0
                if trait_sym != 0:
                    origin = 1
                let impl_start = self.ast.get_start(decl)
                let impl_end = self.ast.get_end(decl)
                // Walk backwards finding method fn_decls
                let impl_extra = self.ast.get_data1(decl)
                // Methods are added as decls before the impl_decl
                var j = di
                while j > 0:
                    j = j - 1
                    let md = self.ast.get_decl(j)
                    if self.ast.kind(md) != NodeKind.NK_FN_DECL:
                        break
                    // #756: spans are per-file byte offsets — nesting is only
                    // meaningful within one file. Without this guard the walk
                    // crossed module boundaries and adopted a foreign file's
                    // free fn as a method whenever its byte range happened to
                    // nest inside this impl's range (#754's defect class).
                    if self.decls_share_source_file(j, di) == 0:
                        break
                    if self.ast.get_start(md) < impl_start or self.ast.get_end(md) > impl_end:
                        break
                    self.method_decl_origins.insert(j, origin)
                    self.method_decl_impl_nodes.insert(j, decl as i32)
                    let parsed_fn_name = self.ast.get_data0(md)
                    let fn_name = self.intern_method_decl_base_symbol(md, parsed_fn_name)
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

    fn is_method_symbol(sym: i32) -> i32:
        if sym <= 0:
            return 0
        if self.method_symbol_flags.contains(sym):
            return 1
        return 0

    fn should_skip_trait_method(decl_idx: i32, fn_sym: i32) -> i32:
        let decl = self.ast.get_decl(decl_idx)
        let semantic = self.method_decl_base_symbol(decl, fn_sym)
        if self.is_method_symbol(semantic) == 0:
            return 0
        if self.method_decl_origins.contains(decl_idx):
            let origin = self.method_decl_origins.get(decl_idx).unwrap()
            if origin == 1:
                if self.method_has_inherent.contains(semantic):
                    return 1
        0

    mut fn collect_declarations():
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
        self.collect_enum_constructor_imports()

        // Pass 3: collect function signatures and top-level let decls.
        for di in 0..self.ast.decl_count():
            self.update_decl_source_context(di)
            let decl = self.ast.get_decl(di)
            let kind = self.ast.kind(decl)
            let is_local = self.is_local_decl(di)
            if kind == NodeKind.NK_FN_DECL:
                let fn_name = self.ast.get_data0(decl)
                if self.should_skip_trait_method(di, fn_name) == 0:
                    self.collect_fn_decl(decl, is_local, di)
            if kind == NodeKind.NK_EXTERN_FN:
                self.collect_extern_fn(decl, is_local)
            if kind == NodeKind.NK_EXTERN_VAR:
                self.collect_extern_var(decl, is_local)
            if kind == NodeKind.NK_C_IMPORT:
                self.read_c_import_retentions(decl)
            if kind == NodeKind.NK_LET_DECL:
                self.collect_let_decl(decl, is_local)

        self.check_trait_default_method_bodies()

    mut fn collect_enum_constructor_imports():
        for di in 0..self.ast.decl_count():
            self.update_decl_source_context(di)
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_USE_DECL:
                continue
            let selector_count = self.ast.get_data2(decl)
            if selector_count <= 0:
                continue
            let path_start = self.ast.get_data0(decl)
            let path_count = self.ast.get_data1(decl)
            if path_count <= 0:
                continue
            let type_sym = self.ast.get_extra(path_start + path_count - 1)
            let type_tid = self.lookup_named_type_visible(type_sym)
            if type_tid == 0:
                continue
            let enum_tid = self.enum_variant_decl_type(type_tid)
            if enum_tid == 0:
                continue
            for si in 0..selector_count:
                let variant_sym = self.ast.get_extra(path_start + path_count + si)
                if self.enum_has_variant(enum_tid, variant_sym) == 0:
                    self.emit_error("variant '" ++ self.pool_resolve(variant_sym) ++ "' does not belong to enum '" ++ self.pool_resolve(type_sym) ++ "'", decl)
                    continue
                let existing = self.imported_variant_owners.get(variant_sym)
                if existing.is_some() and existing.unwrap() != enum_tid:
                    self.emit_error("ambiguous enum constructor import '" ++ self.pool_resolve(variant_sym) ++ "'", decl)
                    continue
                self.imported_variant_owners.insert(variant_sym, enum_tid)

    mut fn resolve_deferred_non_generic_type_decls():
        for di in 0..self.ast.decl_count():
            self.update_decl_source_context(di)
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_TYPE_DECL:
                continue
            if self.type_decl_tp_count(decl) != 0:
                continue
            self.resolve_deferred_non_generic_type_decl(decl)

    fn type_has_unresolved_parts(tid: i32) -> i32:
        if tid <= 0:
            return 1
        let resolved = self.resolve_alias(tid as TypeId)
        if (resolved as i32) <= 0:
            return 1
        let kind = self.get_type_kind(resolved)

        if kind == TypeKind.TY_PTR or kind == TypeKind.TY_REF or kind == TypeKind.TY_ARRAY or kind == TypeKind.TY_SLICE:
            return self.type_has_unresolved_parts(self.get_type_d0(resolved))

        if kind == TypeKind.TY_TUPLE:
            let extra_start = self.get_type_d0(resolved)
            let elem_count = self.get_type_d1(resolved)
            for ei in 0..elem_count:
                if self.type_has_unresolved_parts(self.type_extra.get((extra_start + ei) as i64)) != 0:
                    return 1
            return 0

        if kind == TypeKind.TY_FN or kind == TypeKind.TY_EXTERN_FN:
            let extra_start = self.get_type_d0(resolved)
            let param_count = self.get_type_d1(resolved)
            for pi in 0..param_count:
                if self.type_has_unresolved_parts(self.type_extra.get((extra_start + pi) as i64)) != 0:
                    return 1
            return self.type_has_unresolved_parts(self.get_type_d2(resolved))

        if kind == TypeKind.TY_GENERIC_INST:
            let arg_count = self.get_type_d2(resolved)
            for ai in 0..arg_count:
                if self.type_has_unresolved_parts(self.get_generic_inst_arg(resolved as i32, ai)) != 0:
                    return 1
            return 0

        0

    mut fn resolve_deferred_value_type_slot(slot: i32, type_node: i32, opaque_message: &str):
        let current: i32 = self.type_extra.get(slot as i64)
        if current != 0 and self.type_has_unresolved_parts(current) == 0:
            return
        let resolved = self.resolve_type_expr(type_node)
        if resolved != 0:
            if self.is_opaque_value_type(resolved) != 0:
                self.emit_error(opaque_message, type_node)
            self.type_extra.set_i32(slot as i64, resolved)

    mut fn resolve_deferred_non_generic_type_decl(decl: i32):
        let name = self.ast.get_data0(decl)
        let tid = if self.type_decl_tids.contains(decl): self.type_decl_tids.get(decl).unwrap() else: self.lookup_named_type_visible(name)
        if tid == 0:
            return

        let extra_start = self.ast.get_data1(decl)
        let packed_kind = self.ast.get_data2(decl)
        let sub_kind = type_decl_sub_kind(packed_kind)
        let is_ephemeral = type_decl_is_ephemeral(packed_kind)
        let resolved = self.resolve_alias(tid)

        if sub_kind == TypeDeclKind.Struct or sub_kind == TypeDeclKind.Union:
            if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
                return
            let te_start = self.get_type_d1(resolved)
            let field_count = self.ast.get_extra(extra_start)
            for fi in 0..field_count:
                let field_slot = te_start + fi * 3 + 1
                let field_base = extra_start + 1 + fi * 3
                let field_type_node = self.ast.get_extra(field_base + 1)
                self.resolve_deferred_value_type_slot(field_slot, field_type_node, "opaque types cannot be stored in struct fields; use a pointer or reference")
                let field_tid = self.type_extra.get(field_slot as i64)
                if is_ephemeral == 0 and field_tid != 0 and self.type_is_ephemeral_value(field_tid) != 0:
                    let msg = if sub_kind == TypeDeclKind.Union: "ephemeral values cannot be stored in non-ephemeral unions" else: "ephemeral values cannot be stored in non-ephemeral structs"
                    self.emit_error(msg, field_type_node)
            // Validate bitpacked field types: must be integer, bool, or nested bitpacked
            if type_decl_is_bitpacked(packed_kind) != 0:
                for fi in 0..field_count:
                    let bp_field_slot = te_start + fi * 3 + 1
                    let bp_field_tid = self.type_extra.get(bp_field_slot as i64)
                    if bp_field_tid > 0:
                        let bp_resolved = self.resolve_alias(bp_field_tid as TypeId)
                        let bp_tk = self.get_type_kind(bp_resolved)
                        if bp_tk != TypeKind.TY_INT and bp_tk != TypeKind.TY_BOOL:
                            if bp_tk != TypeKind.TY_STRUCT or not self.bitpacked_types.contains(bp_resolved as i32):
                                let bp_field_base = extra_start + 1 + fi * 3
                                let bp_field_type_node = self.ast.get_extra(bp_field_base + 1)
                                self.emit_error("bitpacked fields must be integer, bool, or bitpacked struct type", bp_field_type_node)
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
                    let payload_type_node = self.ast.get_extra(ast_pos + pi)
                    self.resolve_deferred_value_type_slot(payload_slot, payload_type_node, "opaque types cannot be stored in enum payloads by value; use a pointer or reference")
                    let payload_tid = self.type_extra.get(payload_slot as i64)
                    if is_ephemeral == 0 and payload_tid != 0 and self.type_is_ephemeral_value(payload_tid) != 0:
                        self.emit_error("ephemeral values cannot be stored in enum payloads", payload_type_node)
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
                    let payload_type_node = self.ast.get_extra(ast_pos + pi)
                    self.resolve_deferred_value_type_slot(payload_slot, payload_type_node, "opaque types cannot be stored in enum payloads by value; use a pointer or reference")
                    let payload_tid = self.type_extra.get(payload_slot as i64)
                    if is_ephemeral == 0 and payload_tid != 0 and self.type_is_ephemeral_value(payload_tid) != 0:
                        self.emit_error("ephemeral values cannot be stored in enum payloads", payload_type_node)
                ast_pos = ast_pos + payload_count
                type_pos = type_pos + payload_count
            return

        if sub_kind == TypeDeclKind.Alias:
            if self.get_type_d0(tid) != 0 and self.type_has_unresolved_parts(self.get_type_d0(tid)) == 0:
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
            let inner_node = self.ast.get_extra(extra_start)
            self.resolve_deferred_value_type_slot(value_slot, inner_node, "opaque types cannot be wrapped by value in distinct types; use a pointer or reference")
            let inner_tid = self.type_extra.get(value_slot as i64)
            if is_ephemeral == 0 and inner_tid != 0 and self.type_is_ephemeral_value(inner_tid) != 0:
                self.emit_error("ephemeral values cannot be stored in non-ephemeral distinct types", inner_node)

    fn is_local_decl(decl_index: i32) -> i32:
        let limit = self.ast.local_decl_count()
        if limit < 0:
            return 1
        // After import merging, decl order is: prelude → user imports → root.
        // Root (local) decls are the last `limit` entries in the merged pool.
        let total = self.ast.decl_count()
        if decl_index >= total - limit:
            return 1
        0

    fn is_local_or_prelude_decl(decl_index: i32) -> i32:
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

    mut fn rebuild_decl_index():
        self.decl_index_by_node = sema_new_map_i32_i32()
        for di in 0..self.ast.decl_count():
            let node = self.ast.get_decl(di) as i32
            if not self.decl_index_by_node.contains(node):
                self.decl_index_by_node.insert(node, di)

    fn find_decl_index(node: i32) -> i32:
        if self.decl_index_by_node.contains(node):
            return self.decl_index_by_node.get(node).unwrap()
        // Comptime transformation can append generated declarations after
        // Sema construction. Preserve the old lookup behavior for those
        // uncommon misses without making every established lookup O(decls).
        for di in 0..self.ast.decl_count():
            if self.ast.get_decl(di) == node:
                return di
        -1

    fn decl_index_source_path(di: i32) -> str:
        if di < 0 or di >= self.decl_source_paths.len() as i32:
            return ""
        with_str_clone_ref(self.decl_source_paths.get(di as i64))

    fn decls_share_source_file(a: i32, b: i32) -> i32:
        if a < 0 or b < 0:
            return 0
        // #754: c_import-synthesized decls carry the importing file's id, but
        // their spans index the synthetic generated source — byte-range
        // reasoning across the two coordinate spaces is meaningless (a
        // generated impl's span can "contain" an unrelated root fn and adopt
        // it as a method, erasing its signature). Different origin classes
        // never share a source file.
        let a_ci = if a < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(a as i64) else: 0
        let b_ci = if b < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(b as i64) else: 0
        if a_ci != b_ci:
            return 0
        if a < self.decl_source_file_ids.len() as i32 and b < self.decl_source_file_ids.len() as i32:
            if self.decl_source_file_ids.get(a as i64) == self.decl_source_file_ids.get(b as i64):
                return 1
            return 0
        if a < self.decl_source_paths.len() as i32 and b < self.decl_source_paths.len() as i32:
            if self.decl_source_paths.get(a as i64) == self.decl_source_paths.get(b as i64):
                return 1
            return 0
        if self.ast.local_decl_count() < 0:
            return 1
        0

    mut fn build_ci_scoping():
        // Build c_import scoping data. Scoping is active when there are multiple
        // distinct module paths AND at least one c_import-origin declaration exists.
        if self.decl_source_paths.len() == 0 or self.decl_is_c_import.len() == 0:
            return
        var has_ci = 0
        var module_count = 0
        var prev_path_sym = -1
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
                if kind == NodeKind.NK_FN_DECL or kind == NodeKind.NK_EXTERN_FN:
                    if self.ci_function_requires_raw_abi(sym) != 0:
                        self.ci_raw_syms.insert(sym, 1)
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

    fn is_ci_visible(sym: i32) -> i32:
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

    fn ci_type_requires_raw_contract(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid as TypeId)
        let kind = self.get_type_kind(resolved)
        if kind == TypeKind.TY_PTR or kind == TypeKind.TY_REF or kind == TypeKind.TY_SLICE:
            return 1
        if kind == TypeKind.TY_FN or kind == TypeKind.TY_EXTERN_FN:
            return 1
        if kind == TypeKind.TY_GENERIC_INST:
            let arg_start = self.get_type_d1(resolved)
            let arg_count = self.get_type_d2(resolved)
            for ai in 0..arg_count:
                if self.ci_type_requires_raw_contract(self.type_extra.get((arg_start + ai) as i64)) != 0:
                    return 1
        0

    fn ci_type_is_const_c_string_input(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid as TypeId)
        if self.get_type_kind(resolved) != TypeKind.TY_PTR:
            return 0
        if self.get_type_d1(resolved) != 0:
            return 0
        let pointee = self.resolve_alias(self.get_type_d0(resolved) as TypeId)
        if pointee == self.ty_i8:
            return 1
        0

// Curated libc contract overlay (#379). Evidence, not exemptions: a
// `const char*` parameter is modeled as a NUL-terminated, borrowed string
// input (`cstr_in`) only when this overlay vouches for the specific function.
// There is NO blanket `const char*` assumption — that would be the "strlen
// guessing" / context reinterpretation §16.3c forbids. Functions absent here
// import with raw surfaces (callable only under `unsafe`).
//
// Returns the number of leading parameters that are `cstr_in` (all remaining
// parameters and the return are plain value types for these entries), or -1
// when the function is not curated. Every curated entry here has its char*
// parameters in leading position, so a count is sufficient.
fn ci_overlay_cstr_in_param_count(name: &str) -> i32:
    if name == "atof": return 1
    if name == "atoi": return 1
    if name == "atol": return 1
    if name == "atoll": return 1
    if name == "getenv": return 1
    if name == "strcasecmp": return 2
    if name == "strchr": return 1
    if name == "strcmp": return 2
    if name == "strcspn": return 2
    if name == "strlen": return 1
    if name == "strncasecmp": return 2
    if name == "strncmp": return 2
    if name == "strpbrk": return 2
    if name == "strrchr": return 1
    if name == "strspn": return 2
    if name == "strstr": return 2
    -1

// #379: curated functions whose pointer RETURN is a borrowed, nullable handle.
// Raw C pointers (`*T`) are natively nullable in With — `== None` and
// `.unwrap()` work directly (e.g. malloc returns a plain `*mut c_void`), so the
// return is left as a raw pointer and NOT wrapped in `Option`. This fact only
// says the *call* is safe; the returned pointer is borrowed (non-owning) and
// dereferencing it stays `unsafe`. Owning constructors (fopen, strdup) are NOT
// here — they belong to #357's owning-wrapper mechanism.
fn ci_overlay_return_is_borrowed_ptr(name: &str) -> i32:
    if name == "getenv": return 1
    if name == "strchr": return 1
    if name == "strpbrk": return 1
    if name == "strrchr": return 1
    if name == "strstr": return 1
    0

impl Sema:
    fn ci_function_requires_raw_abi(fn_sym: i32) -> i32:
        let sig_idx = self.get_sig(fn_sym)
        if sig_idx < 0:
            let fn_node = self.fn_symbol_decl_node(fn_sym)
            if fn_node == 0:
                return 0
            let body = self.ast.get_data1(fn_node)
            if body != 0 and self.ast.kind(body) == NodeKind.NK_UNSAFE_BLOCK and self.ast.get_data2(body) == UNSAFE_ORIGIN_FN_BODY:
                return 1
            return 0
        if self.sig_is_variadic(sig_idx) != 0:
            return 1
        // A generated buf_in/buf_out wrapper (#379) is the only c_import function
        // with a slice parameter — C has no slices, so the bridge never produces
        // one. Such a wrapper is a safe abstraction over a renamed raw extern;
        // never classify it raw regardless of its slice params or pointer return.
        let param_count = self.sig_get_param_count(sig_idx)
        for spi in 0..param_count:
            if self.get_type_kind(self.resolve_alias(self.sig_param_type(sig_idx, spi) as TypeId)) == TypeKind.TY_SLICE:
                return 0
        let name = self.safe_symbol_text(fn_sym)
        // A pointer/fn return is raw unless the overlay vouches a borrowed nullable
        // pointer return. Such a return stays a raw (natively nullable) pointer;
        // calling is safe and the deref stays unsafe.
        if self.ci_type_requires_raw_contract(self.sig_return_type(sig_idx)) != 0:
            if ci_overlay_return_is_borrowed_ptr(name) == 0:
                return 1
        let cstr_n = ci_overlay_cstr_in_param_count(name)
        for pi in 0..param_count:
            let pty = self.sig_param_type(sig_idx, pi)
            if self.ci_type_requires_raw_contract(pty) != 0:
                // A pointer parameter is modeled as a C-string input (`cstr_in`)
                // only when the curated overlay vouches for it, OR (#602) when a
                // `retains:` annotation vouches for it: a retained `const char*`
                // param is a modeled C-string input whose retention is enforced at
                // the call site. No evidence -> raw.
                if (pi < cstr_n or self.param_is_retained(fn_sym, pi) != 0) and self.ci_type_is_const_c_string_input(pty) != 0:
                    continue
                return 1
        0

    // D29 scaffolding (#750): registration-time tier provenance. The mask marks
    // a sym shadowed (bit 1 std, bit 2 user) so tier-discriminating queries stay
    // dormant everywhere else; the tid maps let frozen-phase queries recover the
    // declaring node and tier without symbol re-resolution.
    mut fn record_type_decl_tier(name: i32):
        let bit = if sema_tier_path_is_std_implementation(self.current_module_path) != 0: 1 else: 2
        let old = if self.type_sym_tier_mask.contains(name): self.type_sym_tier_mask.get(name).unwrap() else: 0
        self.type_sym_tier_mask.insert(name, old | bit)

    mut fn record_type_decl_tid(node: i32, tid: i32):
        self.type_decl_tids.insert(node, tid)
        let resolved = self.resolve_alias(tid as TypeId) as i32
        self.type_decl_nodes_by_tid.insert(resolved, node)
        let is_std = if sema_tier_path_is_std_implementation(self.current_module_path) != 0: 1 else: 0
        self.type_tid_is_std.insert(resolved, is_std)

    mut fn collect_type_decl(node: i32, is_local: i32):
        let name = self.ast.get_data0(node)
        if is_local != 0:
            self.set_pretty_symbol(name, self.extract_decl_name_after(node, "type"))
        self.type_decl_nodes.insert(name, node)
        // Generic decls stay OUT of the shadow tier mask: a tiered lookup
        // returning the other tier's generic base would mint fresh generic
        // insts after freeze (is_copy_frozen misses). Generic name reuse
        // keeps flat behavior until #751 carries identity through
        // instantiation.
        if self.type_decl_tp_count(node) == 0:
            self.record_type_decl_tier(name)
        let extra_start = self.ast.get_data1(node)
        let packed_kind = self.ast.get_data2(node)
        let sub_kind = type_decl_sub_kind(packed_kind)
        let decl_is_pub = if type_decl_is_pub(self.ast, extra_start, sub_kind): 1 else: 0
        self.record_decl_visibility(name, node, decl_is_pub)
        let is_ephemeral = type_decl_is_ephemeral(packed_kind)
        let is_generic_decl = if self.type_decl_tp_count(node) != 0: 1 else: 0
        if is_ephemeral != 0:
            self.ephemeral_types.insert(name, 1)

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
                if is_generic_decl != 0 and not is_ephemeral and f_tid != 0 and self.type_is_ephemeral_value(f_tid as i32) != 0:
                    self.emit_error("ephemeral values cannot be stored in non-ephemeral structs", f_type_node)
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
            self.record_named_type_with_pub(name, tid as i32, decl_is_pub)
            self.record_type_decl_tid(node, tid as i32)
            if type_decl_is_bitpacked(packed_kind) != 0:
                self.bitpacked_types.insert(tid as i32, 1)
            if type_decl_is_packed(packed_kind) != 0:
                self.packed_types.insert(tid as i32, 1)
            if type_decl_is_repr_c(packed_kind) != 0:
                self.repr_c_types.insert(tid as i32, 1)
            // §16.4 @[align(N)] validation: power of two, ≤ 65536, ≥ natural.
            for fi in 0..field_count:
                let f_align = self.ast.get_extra(align_base + fi)
                if f_align != 0:
                    let f_loc_node = self.ast.get_extra(extra_start + 1 + fi * 3 + 1)
                    if f_align < 0 or (f_align & (f_align - 1)) != 0:
                        self.emit_error("alignment must be a power of two", f_loc_node)
                    else if f_align > 65536:
                        self.emit_error("alignment exceeds maximum 65536", f_loc_node)
                    else:
                        let natural = self.type_layout_align_of(field_tids.get(fi as i64)) as i32
                        if natural > 0 and f_align < natural:
                            self.emit_error("alignment is less than natural alignment of type", f_loc_node)

        if sub_kind == TypeDeclKind.Enum:
            let variant_count = self.ast.get_extra(extra_start)
            let variant_names: Vec[i32] = Vec.new()
            let payload_counts: Vec[i32] = Vec.new()
            let payload_tids: Vec[i32] = Vec.new()
            var epos = extra_start + 1
            for vi in 0..variant_count:
                let v_name = self.ast.get_extra(epos)
                epos = epos + 1
                let payload_count = self.ast.get_extra(epos)
                epos = epos + 1
                variant_names.push(v_name)
                payload_counts.push(payload_count)
                for pi in 0..payload_count:
                    let pt_node = self.ast.get_extra(epos)
                    epos = epos + 1
                    let pt_tid = self.resolve_type_expr(pt_node)
                    if self.is_opaque_value_type(pt_tid) != 0:
                        self.emit_error("opaque types cannot be stored in enum payloads by value; use a pointer or reference", pt_node)
                    if is_generic_decl != 0 and not is_ephemeral and pt_tid != 0 and self.type_is_ephemeral_value(pt_tid as i32) != 0:
                        self.emit_error("ephemeral values cannot be stored in enum payloads", pt_node)
                    payload_tids.push(pt_tid as i32)
            let te_start = self.type_extra.len() as i32
            var payload_cursor = 0
            for vi in 0..variant_count:
                self.type_extra.push(variant_names.get(vi as i64))
                let payload_count = payload_counts.get(vi as i64)
                self.type_extra.push(payload_count)
                for pi in 0..payload_count:
                    self.type_extra.push(payload_tids.get(payload_cursor as i64))
                    payload_cursor = payload_cursor + 1
            let tid = self.add_type(TypeKind.TY_ENUM, name, te_start, variant_count)
            self.record_named_type_with_pub(name, tid as i32, decl_is_pub)
            self.record_type_decl_tid(node, tid as i32)
            // Re-register variants with actual enum TypeId (bare + qualified names)
            let plain_type_name_str: str = with_str_clone_ref(self.pool_resolve(name))
            var vpos = te_start
            for vi in 0..variant_count:
                let v_name: i32 = self.type_extra.get(vpos as i64)
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
            let variant_names: Vec[i32] = Vec.new()
            let payload_counts: Vec[i32] = Vec.new()
            let payload_tids: Vec[i32] = Vec.new()
            var epos = extra_start + 2
            var disc_vals: Vec[i32] = Vec.new()
            for vi in 0..variant_count:
                let v_name = self.ast.get_extra(epos)
                epos = epos + 1
                let disc_value = self.ast.get_extra(epos)
                epos = epos + 1
                let payload_count = self.ast.get_extra(epos)
                epos = epos + 1
                variant_names.push(v_name)
                payload_counts.push(payload_count)
                // Check for duplicate discriminant values
                for prev in 0..disc_vals.len() as i32:
                    if disc_vals.get(prev as i64) == disc_value:
                        self.emit_error(f"duplicate discriminant value {disc_value}", node)
                // Check discriminant fits in repr type range
                if repr_type_tid == self.ty_i8:
                    if disc_value < (-128) or disc_value > 127:
                        self.emit_error(f"discriminant value {disc_value} out of range for i8", node)
                if repr_type_tid == self.ty_i16:
                    if disc_value < (-32768) or disc_value > 32767:
                        self.emit_error(f"discriminant value {disc_value} out of range for i16", node)
                disc_vals.push(disc_value)
                for pi in 0..payload_count:
                    let pt_node = self.ast.get_extra(epos)
                    epos = epos + 1
                    let pt_tid = self.resolve_type_expr(pt_node)
                    if self.is_opaque_value_type(pt_tid) != 0:
                        self.emit_error("opaque types cannot be stored in enum payloads by value; use a pointer or reference", pt_node)
                    payload_tids.push(pt_tid as i32)
            let te_start = self.type_extra.len() as i32
            var payload_cursor = 0
            for vi in 0..variant_count:
                self.type_extra.push(variant_names.get(vi as i64))
                let payload_count = payload_counts.get(vi as i64)
                self.type_extra.push(payload_count)
                for pi in 0..payload_count:
                    self.type_extra.push(payload_tids.get(payload_cursor as i64))
                    payload_cursor = payload_cursor + 1
            let tid = self.add_type(TypeKind.TY_ENUM, name, te_start, variant_count)
            self.record_named_type_with_pub(name, tid as i32, decl_is_pub)
            self.record_type_decl_tid(node, tid as i32)
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
            let type_name_str: str = with_str_clone_ref(self.pool_resolve(name))
            var vpos = te_start
            for vi in 0..variant_count:
                let v_name: i32 = self.type_extra.get(vpos as i64)
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
            self.record_named_type_with_pub(name, tid as i32, decl_is_pub)
            self.record_type_decl_tid(node, tid as i32)

        if sub_kind == TypeDeclKind.Distinct:
            let inner_node = self.ast.get_extra(extra_start)
            let inner = self.resolve_type_expr(inner_node)
            if self.is_opaque_value_type(inner) != 0:
                self.emit_error("opaque types cannot be wrapped by value in distinct types; use a pointer or reference", inner_node)
            if is_generic_decl != 0 and not is_ephemeral and inner != 0 and self.type_is_ephemeral_value(inner as i32) != 0:
                self.emit_error("ephemeral values cannot be stored in non-ephemeral distinct types", inner_node)
            // Distinct type: treat as single-field struct
            let te_start = self.type_extra.len() as i32
            let val_sym = self.pool_intern("value")
            self.type_extra.push(val_sym)
            self.type_extra.push(inner as i32)
            self.type_extra.push(0)
            let tid = self.add_type(TypeKind.TY_STRUCT, name, te_start, 1)
            self.record_named_type_with_pub(name, tid as i32, decl_is_pub)
            self.record_type_decl_tid(node, tid as i32)
            self.distinct_type_names.insert(name, tid as i32)

        if sub_kind == TypeDeclKind.Opaque:
            // Opaque type: register as struct with 0 fields
            let te_start = self.type_extra.len() as i32
            let tid = self.add_type(TypeKind.TY_STRUCT, name, te_start, 0)
            self.record_named_type_with_pub(name, tid as i32, decl_is_pub)
            self.record_type_decl_tid(node, tid as i32)

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
                if is_generic_decl != 0 and not is_ephemeral and f_tid != 0 and self.type_is_ephemeral_value(f_tid as i32) != 0:
                    self.emit_error("ephemeral values cannot be stored in non-ephemeral unions", f_type_node)
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
            self.record_named_type_with_pub(name, tid as i32, decl_is_pub)
            self.record_type_decl_tid(node, tid as i32)

        if self.ast.is_must_use_type_node(node) != 0:
            self.must_use_types.insert(name, 1)
        if self.ast.is_no_await_guard_type_node(node) != 0:
            self.no_await_guard_types.insert(name, 1)

        if is_local != 0:
            self.local_type_names.insert(name, 1)

    // ── Type dependency cycle detection ──────────────────────────────

    // Collect named types that a type expression directly embeds (by value).
    // Pointers, references, and slices are indirections — not followed.
    // Collect named types that a type expression directly embeds (by value).
    // Results are accumulated in self.cycle_dep_syms / self.cycle_dep_nodes.
    // Pointers, references, and slices are indirections — not followed.
    fn collect_value_type_deps(type_node: i32):
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
        // NodeKind.NK_TYPE_FN, NodeKind.NK_TYPE_EXTERN_FN: all provide indirection — do not follow.

    mut fn check_type_cycles():
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

    mut fn emit_type_cycle_error(cycle_start: i32, cycle_end: i32, closing_edge_node: i32, parent_sym: &HashMap[i32, i32], parent_edge: &HashMap[i32, i32]):
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
        self.diags.emit(move diag)

    fn fn_param_uses_value_ref_abi(param_start: i32, param_idx: i32, method_owner_sym: i32, self_type_id: i32) -> i32:
        // D12 receivers occupy parameter 0 only. Matching later params by
        // owner type name made `other: i32` in `impl Eq for i32` share-place
        // (#732) — and post-D5 there is no effects sweep to co-decide, so the
        // positional rule is the whole rule.
        if param_idx != 0:
            return 0
        if method_owner_sym == 0 or self_type_id == 0:
            return 0
        if self.pool_resolve(method_owner_sym) == "str":
            // D12/#678: `mut self` on a str owner is share-place over the fat
            // pointer — the callee rewrites the caller's {ptr,len} pair, so
            // `self = self.slice(1, self.len())` reaches the caller. Read and
            // plain self stay by-value: a read borrow of a Copy fat pointer
            // is observationally a copy, and str reads are the hottest
            // stdlib path — no reason to tax them with indirection.
            if fn_param_is_mut_self(self.ast.fn_param_flags(param_start, param_idx)) == 0:
                return 0
        let owner_resolved = self.resolve_alias(self_type_id as TypeId)
        let owner_kind = self.get_type_kind(owner_resolved)
        // D12 (§9.5): the receiver MODE decides share-place, not the owner's
        // type — scalar primitive owners included (#677). A non-`move` self on
        // an i32 is a borrow of the caller's place, exactly as for a struct;
        // `x.bump()` mutates `x`. str stays excluded (fat pointer, #678).
        if owner_kind != TypeKind.TY_STRUCT and owner_kind != TypeKind.TY_GENERIC_INST and owner_kind != TypeKind.TY_ENUM and
           owner_kind != TypeKind.TY_INT and owner_kind != TypeKind.TY_FLOAT and owner_kind != TypeKind.TY_BOOL and
           owner_kind != TypeKind.TY_STR:
            return 0

        let p_type_node = self.ast.fn_param_type(param_start, param_idx)
        if p_type_node == 0:
            return 0
        var p_sym = 0
        let p_kind = self.ast.kind(p_type_node)
        if p_kind == NodeKind.NK_TYPE_NAMED:
            p_sym = self.ast.get_data0(p_type_node)
        else if p_kind == NodeKind.NK_TYPE_GENERIC:
            // NK_TYPE_GENERIC d0 IS the base symbol (Parser.add_node passes
            // type_name directly), not a base type node. The old node-deref
            // read garbage and never matched, so generic receivers
            // (`mut self: Atomic[i64]`) only ever got share-place from the
            // deleted D5 effects sweep — Atomic.add lost its in-place
            // receiver when that sweep died.
            p_sym = self.ast.get_data0(p_type_node)
        else:
            return 0
        // Per-module interning can give the declared receiver type and the
        // mono-name-derived owner different symbol ids for the same text
        // (Atomic.add's mut self lost share-place this way once the D5 sweep
        // no longer re-covered it); compare canonically.
        if with_getenv_str("WITH_DEBUG_SUBST").len() > 0:
            with_eprint(f"[vra-decl] p_kind={p_kind} p_sym={p_sym} p_text={self.pool_resolve(p_sym)} owner={method_owner_sym} owner_text={self.pool_resolve(method_owner_sym)}")
        var p_is_owner = p_sym == method_owner_sym
        if not p_is_owner and p_sym != 0 and method_owner_sym != 0:
            p_is_owner = self.pool_resolve(p_sym) == self.pool_resolve(method_owner_sym)
        if p_sym == self.syms.self_type or p_is_owner:
            // §9.5/G2 (D6): a `move self` receiver is CONSUMED (owned) — it is dropped
            // by the callee, so it does NOT use the value-ref (IndirectPlace /
            // share-place) ABI. `mut self` / `&self` / plain `self` remain share-place
            // borrows of the caller's place.
            if fn_param_is_move_self(self.ast.fn_param_flags(param_start, param_idx)) != 0:
                return 0
            return 1
        0

    mut fn ensure_generator_state_type(fn_sym: i32, yield_ty: i32) -> i32:
        if self.generator_fn_state_types.contains(fn_sym):
            return self.generator_fn_state_types.get(fn_sym).unwrap()

        let state_name = f"__with_generator_state_{fn_sym}"
        let state_sym = self.pool_intern(state_name)
        let state_tid = self.add_type(TypeKind.TY_STRUCT, state_sym, 0, 0)
        self.record_named_type(state_sym, state_tid as i32)
        self.pretty_symbol_names.insert(state_sym, sema_owned_text(state_name))
        self.generator_fn_yield_types.insert(fn_sym, yield_ty)
        self.generator_fn_state_types.insert(fn_sym, state_tid as i32)
        self.generator_fn_state_syms.insert(fn_sym, state_sym)
        self.generator_state_yield_types.insert(state_tid as i32, yield_ty)
        state_tid as i32

    fn mark_generator_state_ephemeral(state_tid: i32):
        if state_tid <= 0:
            return
        let resolved = self.resolve_alias(state_tid as TypeId)
        if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return
        let state_sym = self.get_type_d0(resolved)
        if state_sym != 0:
            self.ephemeral_types.insert(state_sym, 1)

    mut fn register_generator_next_method(fn_sym: i32, state_sym: i32, state_tid: i32, yield_ty: i32):
        if self.generator_fn_next_syms.contains(fn_sym):
            return

        let next_fn_name = f"__with_generator_next_{fn_sym}"
        let next_fn_sym = self.pool_intern(next_fn_name)
        let opt_yield_ty = self.ensure_option_type_for(yield_ty)

        let next_param_start = self.sig_params.len() as i32
        self.sig_params.push(state_tid)
        let next_fn_extra = self.type_extra.len() as i32
        self.type_extra.push(state_tid)
        let next_fn_tid = self.add_type(TypeKind.TY_FN, next_fn_extra, 1, opt_yield_ty)
        self.add_sig(next_fn_sym, next_fn_tid as i32, opt_yield_ty, next_param_start, 1, 0)
        let next_sig_idx = self.get_sig(next_fn_sym)
        if next_sig_idx >= 0:
            self.set_sig_param_value_ref_abi(next_sig_idx, 0, 1)
            let key = sema_pair_key(state_sym, self.syms.next)
            self.method_lookup.sig_lookup.insert(key, next_sig_idx)
            self.method_lookup.fn_lookup.insert(key, next_fn_sym)

        self.generator_fn_next_syms.insert(fn_sym, next_fn_sym)
        self.generator_next_fn_syms.insert(next_fn_sym, fn_sym)
        self.method_symbol_flags.insert(next_fn_sym, 1)
        self.fn_decl_source_paths.insert(next_fn_sym, with_str_clone_ref(self.current_module_path))

    fn fn_decl_has_refutable_param_pattern(node: i32) -> i32:
        let meta = self.ast.find_fn_meta(node)
        if meta < 0:
            return 0
        let param_count = self.ast.fn_meta_param_count(meta)
        let pmeta = self.ast.find_fn_param_pattern_meta(node)
        if pmeta < 0:
            return 0
        let start = self.ast.fn_param_pattern_meta_start(pmeta)
        let count = self.ast.fn_param_pattern_meta_count(pmeta)
        let apply_count = if count < param_count: count else: param_count
        for pi in 0..apply_count:
            let pat = self.ast.fn_param_pattern_value(start + pi)
            if pat != 0 and self.pattern_is_refutable(pat) != 0:
                return 1
        0

    // Clause body symbols are minted from the clause's ORDINAL within its
    // group (source order) — stable across collect/check passes. Minting from
    // decl_index drifted: prelude injection shifts the decl table between
    // passes, so the same clause minted a fresh symbol per pass and the
    // index-keyed lookup missed in the shifted space — check_fn then saw the
    // dispatch symbol and rejected a valid clause group ("refutable parameter
    // pattern requires another function clause or an else").
    mut fn fn_clause_body_symbol_for(dispatch_sym: i32, node: i32) -> i32:
        self.register_fn_clause_decl(dispatch_sym, node)
        let group = self.fn_clause_group_index(dispatch_sym)
        var ordinal = 0
        for i in 0..self.fn_clause_group_clause_count(group):
            if self.fn_clause_group_clause(group, i) == node:
                ordinal = i
                break
        let base: str = with_str_clone_ref(self.pool_resolve(dispatch_sym))
        self.pool_intern(base ++ "$clause$" ++ f"{ordinal}")

    mut fn prepare_fn_clause(dispatch_sym: i32, node: i32, decl_index: i32) -> i32:
        let body_sym = self.fn_clause_body_symbol_for(dispatch_sym, node)
        if self.fn_clause_body_dispatch.contains(body_sym) and self.fn_decl_semantic_symbol(node, 0) == body_sym:
            return body_sym
        self.fn_decl_effective_syms.insert(node, body_sym)
        self.fn_decl_nodes.insert(body_sym, node)
        self.fn_decl_source_paths.insert(body_sym, self.decl_source_path_for_index(decl_index))
        self.fn_clause_body_dispatch.insert(body_sym, dispatch_sym)
        let dispatch_sig = self.get_sig(dispatch_sym)
        if dispatch_sig >= 0:
            self.copy_sig_alias(body_sym, dispatch_sig)
        if self.no_alloc_fns.contains(dispatch_sym):
            self.no_alloc_fns.insert(body_sym, 1)
        body_sym

    mut fn fn_signature_return_type(flags: i32, declared_ret_type: TypeId) -> TypeId:
        if (flags / FnFlags.ASYNC) % 2 == 0:
            return declared_ret_type
        let task_args: Vec[i32] = Vec.new()
        task_args.push(declared_ret_type as i32)
        let task_ty = self.ensure_generic_inst_type(self.pool_intern("Task"), task_args, 1)
        if task_ty != 0: task_ty else: declared_ret_type

    fn record_fn_behavior_metadata(fn_name: i32, node: i32, flags: i32):
        if (flags / FnFlags.MUST_USE) % 2 == 1:
            self.must_use_fns.insert(fn_name, 1)
        if (flags / FnFlags.ASYNC) % 2 == 1:
            self.task_fns.insert(fn_name, 1)
        if self.ast.state.fn_stack_sizes.contains(node):
            self.fn_stack_sizes.insert(fn_name, self.ast.state.fn_stack_sizes.get(node).unwrap())

    mut fn collect_fn_decl(node: i32, is_local: i32, decl_index: i32):
        let parsed_fn_name = self.ast.get_data0(node)
        let method_owner_sym = self.method_decl_owner_symbol(node, parsed_fn_name)
        let method_base_sym = self.method_decl_base_symbol(node, parsed_fn_name)
        var fn_name = method_base_sym
        var dispatch_fn_name = 0
        if method_owner_sym != 0 and self.method_decl_is_extension(node) != 0:
            fn_name = self.extension_method_unique_symbol_at(decl_index, method_base_sym)
        // Record the authoritative Sema-pool identity for every declaration.
        // A parsed symbol belongs to the AST's InternPool; returning that raw
        // integer as a semantic symbol is ambiguous once combined modules use
        // distinct pools and the same slot names unrelated declarations.
        self.fn_decl_effective_syms.insert(node, fn_name)
        if method_owner_sym != 0:
            // Only methods need their enclosing impl. Computing it eagerly for
            // every fn scanned all decls (O(n) miss) for non-methods and threw
            // the result away — O(n^2) over the decl table.
            let method_impl_node = self.impl_node_for_method_decl(node)
            if method_impl_node != 0:
                self.method_impl_nodes.insert(fn_name, method_impl_node)
            self.method_symbol_flags.insert(fn_name, 1)
        if is_local != 0:
            self.set_pretty_symbol(fn_name, self.extract_decl_name_after(node, "fn"))
        let fn_flags = self.ast.get_data2(node)
        let decl_is_pub = if (fn_flags / FnFlags.PUB) % 2 == 1: 1 else: 0
        self.record_decl_visibility(fn_name, node, decl_is_pub)
        if self.fn_decl_nodes.contains(fn_name):
            let existing_node: i32 = self.fn_decl_nodes.get(fn_name).unwrap()
            if existing_node != node:
                let existing_di = self.find_decl_index(existing_node)
                let current_di = self.find_decl_index(node)
                if self.decls_share_source_file(existing_di, current_di) != 0:
                    let is_clause_group = if self.fn_clause_group_index(fn_name) >= 0: 1 else:
                        if self.fn_decl_has_refutable_param_pattern(existing_node) != 0 or self.fn_decl_has_refutable_param_pattern(node) != 0: 1 else: 0
                    if is_clause_group != 0:
                        dispatch_fn_name = fn_name
                        self.prepare_fn_clause(dispatch_fn_name, existing_node, existing_di)
                        fn_name = self.prepare_fn_clause(dispatch_fn_name, node, current_di)
                    else:
                        let fn_name_str = self.pool_resolve(fn_name)
                        self.emit_error(f"function '{fn_name_str}' is already defined", node)
                        return
        if self.ast.is_no_alloc_fn_node(node as NodeId) != 0:
            self.no_alloc_fns.insert(fn_name, 1)

        // Look up fn_meta for parameter info
        let meta = self.ast.find_fn_meta(node)
        if meta < 0:
            // No meta available — register with no params
            self.fn_decl_nodes.insert(fn_name, node)
            self.fn_decl_source_paths.insert(fn_name, with_str_clone_ref(self.current_module_path))
            let fn_tid = self.add_type(TypeKind.TY_FN, 0, 0, self.ty_void)
            self.add_sig(fn_name, fn_tid, self.ty_void, 0, 0, 0)
            return

        let flags = self.ast.fn_meta_flags(meta)
        let ret_node = self.ast.fn_meta_ret(meta)
        let param_start = self.ast.fn_meta_param_start(meta)
        let param_count = self.ast.fn_meta_param_count(meta)
        let tp_count = self.ast.fn_meta_tp_count(meta)
        if (flags / FnFlags.ASYNC) % 2 == 1:
            self.require_async_runtime(node, "async fn")
        self.record_fn_behavior_metadata(fn_name, node, flags)

        // Record receiver flags here. D7 enforcement runs after body checking and
        // effect fixed point so a missing mode can report the compiler-derived
        // read/mut/move answer, including concrete generic specializations.
        if param_count > 0:
            let p0_name = self.ast.fn_param_name(param_start, 0)
            if self.pool_resolve(p0_name) == "self":
                let p0_flags = self.ast.fn_param_flags(param_start, 0)
                // §2.4/#642: a destructor always consumes — Drop.drop must take
                // `move self: Self`. Catch other forms here at check time (they
                // previously died in codegen with no source location).
                let decl_name_for_drop = self.pool_resolve(fn_name)
                if fn_param_is_move_self(p0_flags) == 0 and (decl_name_for_drop == "drop" or decl_name_for_drop.ends_with(".drop")):
                    let encl_impl = self.impl_node_for_method_decl(node)
                    if encl_impl != 0 and self.pool_resolve(self.ast.get_data2(encl_impl)) == "Drop":
                        self.emit_error("Drop.drop receiver must be 'move self: Self' — a destructor always consumes (§2.4)", node)

        // Bind Self to method owner type for dot-name methods
        let self_sym = self.syms.self_type
        var self_type_id = 0
        let fn_name_str = self.pool_resolve(method_base_sym)
        if method_owner_sym != 0:
            self_type_id = self.lookup_named_type_visible(method_owner_sym)
            if self_type_id != 0:
                self.named_types.insert(self_sym, self_type_id)

        // #584: an impl method for a CONCRETE generic instantiation
        // (impl Trait for Box[i32]) binds Self to the INSTANTIATION, not the
        // generic base the dot-split found — the base's T-typed field tids are 0
        // (spurious "unknown field") and its layout is wrong (by-ref receivers
        // reading concrete fields returned ABI garbage).
        if self_type_id != 0 and self.method_impl_nodes.contains(fn_name):
            let sb_impl: i32 = self.method_impl_nodes.get(fn_name).unwrap()
            if self.ast.find_impl_type_params(sb_impl) < 0 and self.impl_target_has_bare_type_params(sb_impl) == 0:
                let sb_target = self.ast.find_impl_target_type_node(sb_impl as NodeId)
                if sb_target != 0:
                    let sb_kind = self.ast.kind(sb_target)
                    if sb_kind == NodeKind.NK_INDEX or sb_kind == NodeKind.NK_TYPE_GENERIC:
                        let sb_inst_tid = self.resolve_type_expr(sb_target)
                        if sb_inst_tid != 0 and self.get_type_kind(self.resolve_alias(sb_inst_tid)) == TypeKind.TY_GENERIC_INST:
                            self_type_id = sb_inst_tid as i32
                            self.named_types.insert(self_sym, self_type_id)

        // Set up associated type bindings if inside a trait impl
        self.assoc_type_bindings.clear()
        if self.method_impl_nodes.contains(fn_name):
            let impl_nd: i32 = self.method_impl_nodes.get(fn_name).unwrap()
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
            let bi_impl: i32 = self.method_impl_nodes.get(fn_name).unwrap()
            let bi_tp_meta = self.ast.find_impl_type_params(bi_impl)
            if bi_tp_meta >= 0:
                let bi_tp_count: i32 = self.ast.state.impl_type_params.get((bi_tp_meta + 2) as i64)
                if bi_tp_count > 0:
                    self.register_generic_fn_node(fn_name, node)
                    self.fn_decl_source_paths.insert(fn_name, with_str_clone_ref(self.current_module_path))
                    let _ = self.register_extension_method_candidate(node, fn_name, parsed_fn_name, -1, decl_index)
                    for pi in 0..param_count:
                        self.validate_type_expr_with_impl_type_params(self.ast.fn_param_type(param_start, pi), self.ast.state.impl_type_params.get((bi_tp_meta + 1) as i64), bi_tp_count, bi_impl)
                    self.validate_type_expr_with_impl_type_params(ret_node, self.ast.state.impl_type_params.get((bi_tp_meta + 1) as i64), bi_tp_count, bi_impl)
                    if self_type_id != 0:
                        self.named_types.remove(self_sym)
                    return
            else if self.impl_target_has_bare_type_params(bi_impl) != 0:
                self.register_generic_fn_node(fn_name, node)
                self.fn_decl_source_paths.insert(fn_name, with_str_clone_ref(self.current_module_path))
                let _ = self.register_extension_method_candidate(node, fn_name, parsed_fn_name, -1, decl_index)
                for pi2 in 0..param_count:
                    self.validate_type_expr_with_impl_type_params(self.ast.fn_param_type(param_start, pi2), 0, 0, bi_impl)
                self.validate_type_expr_with_impl_type_params(ret_node, 0, 0, bi_impl)
                if self_type_id != 0:
                    self.named_types.remove(self_sym)
                return

        // Methods on generic structs: treat as generic (type params come from struct)
        if tp_count == 0 and self_type_id != 0:
            var concrete_inst_impl_method = false
            if self.method_impl_nodes.contains(fn_name):
                let inst_impl = self.method_impl_nodes.get(fn_name).unwrap()
                if self.ast.find_impl_type_params(inst_impl) < 0:
                    let inst_target = self.ast.find_impl_target_type_node(inst_impl as NodeId)
                    if inst_target != 0:
                        let inst_target_kind = self.ast.kind(inst_target)
                        if inst_target_kind == NodeKind.NK_INDEX or inst_target_kind == NodeKind.NK_TYPE_GENERIC:
                            concrete_inst_impl_method = true
            for cfi in 0..fn_name_str.len() as i32:
                if fn_name_str.byte_at(cfi as i64) == 46:
                    let cf_owner = fn_name_str.slice(0, cfi as i64)
                    let cf_owner_sym = self.pool_intern(cf_owner)
                    if concrete_inst_impl_method == 0 and self.type_decl_nodes.contains(cf_owner_sym):
                        let cf_td: i32 = self.type_decl_nodes.get(cf_owner_sym).unwrap()
                        if self.type_decl_tp_count(cf_td) > 0:
                            self.register_generic_fn_node(fn_name, node)
                            self.fn_decl_source_paths.insert(fn_name, with_str_clone_ref(self.current_module_path))
                            let _ = self.register_extension_method_candidate(node, fn_name, parsed_fn_name, -1, decl_index)
                            self.named_types.remove(self_sym)
                            return
                    break

        // Generic functions: store for later monomorphization
        if tp_count > 0:
            self.register_generic_fn_node(fn_name, node)
            self.fn_decl_source_paths.insert(fn_name, with_str_clone_ref(self.current_module_path))
            let _ = self.register_extension_method_candidate(node, fn_name, parsed_fn_name, -1, decl_index)
            for pi in 0..param_count:
                let p_type_node = self.ast.fn_param_type(param_start, pi)
                self.validate_type_expr_with_type_params(p_type_node, self.ast.fn_meta_tp_start(meta), tp_count)
            self.validate_type_expr_with_type_params(ret_node, self.ast.fn_meta_tp_start(meta), tp_count)
            // Validate where clause references
            self.validate_where_clause(node, self.ast.fn_meta_tp_start(meta), tp_count)
            if self_type_id != 0:
                self.named_types.remove(self_sym)
            return

        self.fn_decl_nodes.insert(fn_name, node)
        self.fn_decl_source_paths.insert(fn_name, with_str_clone_ref(self.current_module_path))

        // Resolve param types
        let sig_param_start = self.sig_params.len() as i32
        let implicit_type_ids: Vec[i32] = Vec.new()
        for pi in 0..param_count:
            let p_name_sym = self.ast.fn_param_name(param_start, pi)
            if is_local != 0:
                self.set_pretty_symbol(p_name_sym, self.extract_fn_param_name(node, pi))
            let p_type_node = self.ast.fn_param_type(param_start, pi)
            // #604 stage 1: `[]mut T` is legal only here (signature param types).
            self.in_param_type_position = self.in_param_type_position + 1
            let p_tid = self.resolve_type_expr(p_type_node)
            self.in_param_type_position = self.in_param_type_position - 1
            let p_flags = self.ast.fn_param_flags(param_start, pi)
            // A D7 mut receiver spells `Self` but uses the share-place ABI: the
            // caller passes an address, so no opaque value is materialized.
            if self.is_opaque_value_type(p_tid) != 0 and self.fn_param_uses_value_ref_abi(param_start, pi, method_owner_sym, self_type_id) == 0:
                self.emit_error("opaque types cannot be passed by value; use a pointer or reference", p_type_node)
            // Check for duplicate implicit parameter types (spec §F6)
            if fn_param_is_implicit(p_flags) != 0:
                for prev in 0..implicit_type_ids.len() as i32:
                    if implicit_type_ids.get(prev as i64) == p_tid as i32:
                        self.emit_error("function has multiple implicit parameters of the same type", p_type_node)
                implicit_type_ids.push(p_tid as i32)
            self.sig_params.push(p_tid as i32)

        var ret_type = self.resolve_type_expr(ret_node)
        if self.is_opaque_value_type(ret_type) != 0:
            self.emit_error("opaque types cannot be returned by value; use a pointer or reference", ret_node)
        if ret_node == 0:
            ret_type = self.ty_void

        var sig_ret_type = ret_type

        // For generator functions, the public call returns an internal state value.
        // The declared return type remains the yield type tracked for `yield expr`.
        if (flags / FnFlags.GEN) % 2 == 1:
            if (flags / FnFlags.ASYNC) % 2 == 1:
                self.emit_error("gen fn cannot also be async", node)
            if ret_node == 0:
                self.emit_error("generator function requires a yield type", node)
            let state_tid = self.ensure_generator_state_type(fn_name, ret_type as i32)
            for pi in 0..param_count:
                let p_ty = self.sig_params.get((sig_param_start + pi) as i64)
                if self.type_is_ephemeral_value(p_ty) != 0:
                    self.mark_generator_state_ephemeral(state_tid)
            let state_sym: i32 = self.generator_fn_state_syms.get(fn_name).unwrap()
            self.register_generator_next_method(fn_name, state_sym, state_tid, ret_type as i32)
            sig_ret_type = state_tid as TypeId

        sig_ret_type = self.fn_signature_return_type(flags, sig_ret_type)

        // Build fn type
        let fn_extra_start = self.type_extra.len() as i32
        for pi in 0..param_count:
            self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
        let fn_tid = self.add_type(TypeKind.TY_FN, fn_extra_start, param_count, sig_ret_type)

        let is_variadic = (flags / FnFlags.VARIADIC) % 2
        self.add_sig(fn_name, fn_tid, sig_ret_type, sig_param_start, param_count, is_variadic)
        let fn_sig_idx = self.get_sig(fn_name)
        if fn_sig_idx >= 0:
            self.set_sig_receiver_mode(fn_sig_idx, self.receiver_mode_from_param(param_start, param_count))
            for pi in 0..param_count:
                if self.fn_param_uses_value_ref_abi(param_start, pi, method_owner_sym, self_type_id) != 0:
                    self.set_sig_param_value_ref_abi(fn_sig_idx, pi, 1)
        if dispatch_fn_name != 0:
            let dispatch_sig = self.get_sig(dispatch_fn_name)
            let clause_sig = self.get_sig(fn_name)
            if dispatch_sig >= 0 and clause_sig >= 0 and self.signatures_match(dispatch_sig, clause_sig) == 0:
                self.emit_error("function clause signature mismatch for '" ++ self.pool_resolve(dispatch_fn_name) ++ "'", node)
        self.register_method_sig_alias(node, fn_name, parsed_fn_name, fn_sig_idx, decl_index)

        // Unbind Self
        if self_type_id != 0:
            self.named_types.remove(self_sym)

    mut fn collect_extern_fn(node: i32, is_local: i32):
        let name = self.ast.get_data0(node)
        if is_local != 0:
            self.set_pretty_symbol(name, self.extract_decl_name_after(node, "fn"))
        self.record_decl_visibility(name, node, 1)
        self.fn_decl_source_paths.insert(name, with_str_clone_ref(self.current_module_path))

        // Error if this extern fn shadows a regular function from the same file or
        // the prelude. An extern fn silently replaces the existing signature with an
        // unresolved C symbol, producing a cryptic linker error instead of a clear
        // sema diagnostic.
        //
        // Only fire for same-file or prelude functions. Functions from other imported
        // modules are intentional C interop (e.g. a library wrapping C's abs()).
        // Extern-to-extern re-declarations are harmless (same C symbol) and allowed.
        if self.fn_decl_nodes.contains(name):
            let existing_node: i32 = self.fn_decl_nodes.get(name).unwrap()
            if existing_node != node:
                // Find the decl index of the existing function to check its origin
                for edi in 0..self.ast.decl_count():
                    if self.ast.get_decl(edi) == existing_node:
                        if self.is_local_or_prelude_decl(edi) != 0:
                            let fn_name_str = self.pool_resolve(name)
                            self.emit_error(f"'{fn_name_str}' is already defined as a function; extern fn would shadow it", node)
                            return
                        break

        // Cross-module check: imported functions (prelude or use'd modules) may
        // have a different symbol ID for the same name string (imports are parsed
        // with separate InternPools). Scan non-local fn_decls by string name.
        // Only error if the extern is a local (user-file) declaration shadowing
        // an imported function — the user likely didn't intend to override it.
        // Cross-module shadow detection (prelude fn shadowed by user extern fn)
        // is handled in the import merger (Frontend.w) where it can see both
        // declarations before the prelude version is dropped from the decl list.

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

        // No return annotation means Unit, same as the no-meta branch above —
        // resolve_type_expr(0) is TY_ERR and would leak an untyped MIR call
        // destination for every `extern fn f(...)` without `->`.
        let ret_type = if ret_node != 0: self.resolve_type_expr(ret_node) else: self.ty_void
        if self.is_opaque_value_type(ret_type) != 0:
            self.emit_error("opaque types cannot be returned by value; use a pointer or reference", ret_node)

        let fn_extra_start = self.type_extra.len() as i32
        for pi in 0..param_count:
            self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
        let fn_tid = self.add_type(TypeKind.TY_FN, fn_extra_start, param_count, ret_type)

        self.add_sig(name, fn_tid, ret_type, sig_param_start, param_count, is_variadic)
        let sig_idx = self.get_sig(name)
        if sig_idx >= 0:
            self.apply_declared_effects_to_extern_sig(node, sig_idx, param_start, param_count)
        self.extern_fn_names.insert(name, 1)

    mut fn collect_extern_var(node: i32, is_local: i32):
        let name = self.ast.get_data0(node)
        self.record_decl_visibility(name, node, 1)
        let type_node = self.ast.get_data1(node)
        let tid = self.resolve_type_expr(type_node)
        if self.is_opaque_value_type(tid) != 0:
            self.emit_error("opaque types cannot be declared as extern values; use a pointer or reference", type_node)
        // Register the extern var for scope lookup
        let is_mut = if self.ast.get_data2(node) != 0: 1 else: 0
        if is_mut != 0:
            self.mutable_global_syms.insert(name, 1)
        self.register_top_level_global_decl(name, tid, is_mut, node, GLOBAL_VALUE_DECL_EXTERN)

fn sema_str_find_char(text: &str, needle: i32) -> i32:
    for i in 0..text.len() as i32:
        if text[i] == needle:
            return i
    return -1

impl Sema:
    fn impl_owner_type_sym_for_decl(decl: i32) -> i32:
        let impl_node = self.impl_node_for_method_decl(decl)
        if impl_node != 0:
            return self.ast.get_data0(impl_node)
        0

    fn method_decl_owner_symbol(decl: i32, parsed_fn_sym: i32) -> i32:
        let impl_owner = self.impl_owner_type_sym_for_decl(decl)
        if impl_owner != 0:
            return impl_owner
        let parsed = self.pool_resolve(parsed_fn_sym)
        let dot = sema_str_find_char(parsed, 46)
        if dot <= 0:
            return 0
        self.pool_lookup_symbol(parsed.slice(0, dot as i64))

    fn method_decl_name_symbol(parsed_fn_sym: i32) -> i32:
        let parsed = self.pool_resolve(parsed_fn_sym)
        let dot = sema_str_find_char(parsed, 46)
        if dot < 0:
            return parsed_fn_sym
        if dot + 1 >= parsed.len() as i32:
            return 0
        self.pool_lookup_symbol(parsed.slice((dot + 1) as i64, parsed.len()))

    fn method_decl_base_symbol(decl: i32, parsed_fn_sym: i32) -> i32:
        if self.impl_owner_type_sym_for_decl(decl) == 0:
            return parsed_fn_sym
        let owner = self.method_decl_owner_symbol(decl, parsed_fn_sym)
        let method = self.method_decl_name_symbol(parsed_fn_sym)
        if owner == 0 or method == 0:
            return 0
        self.pool_lookup_symbol(self.pool_resolve(owner) ++ "." ++ self.pool_resolve(method))

    mut fn intern_method_decl_base_symbol(decl: i32, parsed_fn_sym: i32) -> i32:
        if self.impl_owner_type_sym_for_decl(decl) == 0:
            return parsed_fn_sym
        let owner = self.method_decl_owner_symbol(decl, parsed_fn_sym)
        let method = self.method_decl_name_symbol(parsed_fn_sym)
        if owner == 0 or method == 0:
            return 0
        self.pool_intern(self.pool_resolve(owner) ++ "." ++ self.pool_resolve(method))

    fn impl_node_for_method_decl(decl: i32) -> i32:
        let decl_index = self.find_decl_index(decl)
        if decl_index >= 0 and self.method_decl_impl_nodes.contains(decl_index):
            return self.method_decl_impl_nodes.get(decl_index).unwrap()
        // method_decl_impl_nodes is authoritative: compute_method_origins walks
        // every impl's contiguous in-span method FN_DECLs (impl bodies hold only
        // methods, so the backward-walk is complete) and records each method's
        // enclosing impl. A cache miss therefore means `decl` has no enclosing
        // impl. The former O(n) decl-order span-containment scan never resolved
        // an impl the cache lacked over a full self-compile — it only re-derived
        // the 0 at whole-program cost.
        0

fn sema_extension_path_hash(path: &str) -> i64:
    var h: i64 = 17
    for i in 0..path.len() as i32:
        h = (h * 131 + path.byte_at(i as i64) as i64) % 2147483647
    h

impl Sema:
    fn decl_source_path_for_node(node: i32) -> str:
        let di = self.find_decl_index(node)
        if di >= 0 and di < self.decl_source_paths.len() as i32:
            return with_str_clone_ref(self.decl_source_paths.get(di as i64))
        self.current_module_path.clone()

    fn decl_source_path_for_index(decl_index: i32) -> str:
        if decl_index >= 0 and decl_index < self.decl_source_paths.len() as i32:
            return with_str_clone_ref(self.decl_source_paths.get(decl_index as i64))
        self.current_module_path.clone()

    fn decl_source_file_id_for_index(decl_index: i32) -> i32:
        if decl_index >= 0 and decl_index < self.decl_source_file_ids.len() as i32:
            return self.decl_source_file_ids.get(decl_index as i64)
        0

    mut fn extension_method_unique_symbol_at(decl_index: i32, qualified_sym: i32) -> i32:
        let qualified: str = with_str_clone_ref(self.pool_resolve(qualified_sym))
        if qualified.len() == 0:
            return qualified_sym
        self.pool_intern(qualified ++ "$ext$" ++ f"{sema_extension_path_hash(self.decl_source_path_for_index(decl_index))}")

    fn fn_decl_semantic_symbol(node: i32, fallback: i32) -> i32:
        if self.fn_decl_effective_syms.contains(node):
            return self.fn_decl_effective_syms.get(node).unwrap()
        fallback

    // Node identity is the stable key — the decl table's index space shifts
    // between passes (prelude injection), so decl_index must never key a
    // lookup that outlives one pass.
    fn fn_decl_semantic_symbol_at(node: i32, fallback: i32, decl_index: i32) -> i32:
        self.fn_decl_semantic_symbol(node, fallback)

    fn method_decl_is_extension(node: i32) -> i32:
        let impl_node = self.impl_node_for_method_decl(node)
        if impl_node == 0:
            return 0
        self.ast.is_extend_impl_node(impl_node as NodeId)

    mut fn register_extension_method_candidate(node: i32, fn_sym: i32, parsed_fn_sym: i32, sig_idx: i32, decl_index: i32) -> i32:
        let owner_sym = self.method_decl_owner_symbol(node, parsed_fn_sym)
        let method_sym = self.method_decl_name_symbol(parsed_fn_sym)
        if owner_sym == 0 or method_sym == 0:
            return 0
        if self.method_decl_is_extension(node) != 0:
            // Registration runs once per check pass; without the identity
            // guard the same extension appears N times and a SINGLE
            // extension reports itself as ambiguous (behav_extension_
            // coherence: "candidates: w.label, w.label, w.label"). Keyed by
            // source PATH: fn syms differ across passes for the same decl.
            let reg_path = sema_owned_text(self.decl_source_path_for_index(decl_index))
            for ei in 0..self.extension_method_owner_syms.len() as i32:
                if self.extension_method_owner_syms.get(ei as i64) == owner_sym and self.extension_method_syms.get(ei as i64) == method_sym and self.extension_method_paths.get(ei as i64) == reg_path:
                    // Refresh the row so later passes' fn/sig win (they are
                    // the finalized ones).
                    self.extension_method_fn_syms.set_i32(ei as i64, fn_sym)
                    self.extension_method_sig_idxs.set_i32(ei as i64, sig_idx)
                    self.method_symbol_flags.insert(fn_sym, 1)
                    return 1
            self.extension_method_owner_syms.push(owner_sym)
            self.extension_method_syms.push(method_sym)
            self.extension_method_fn_syms.push(fn_sym)
            self.extension_method_sig_idxs.push(sig_idx)
            self.extension_method_paths.push(reg_path)
            self.method_symbol_flags.insert(fn_sym, 1)
            return 1
        0

    mut fn register_method_sig_alias(node: i32, fn_sym: i32, parsed_fn_sym: i32, sig_idx: i32, decl_index: i32):
        if sig_idx < 0:
            return

        if self.register_extension_method_candidate(node, fn_sym, parsed_fn_sym, sig_idx, decl_index) != 0:
            return

        let owner_sym = self.method_decl_owner_symbol(node, parsed_fn_sym)
        let method_sym = self.method_decl_name_symbol(parsed_fn_sym)
        if owner_sym == 0 or method_sym == 0:
            return
        let key = sema_pair_key(owner_sym, method_sym)
        self.method_lookup.sig_lookup.insert(key, sig_idx)
        self.method_lookup.fn_lookup.insert(key, fn_sym)
        self.method_symbol_flags.insert(fn_sym, 1)

    fn type_decl_source_path(type_sym: i32) -> str:
        if type_sym == 0 or not self.type_decl_nodes.contains(type_sym):
            return ""
        let node = self.type_decl_nodes.get(type_sym).unwrap()
        let di = self.find_decl_index(node)
        if di >= 0 and di < self.decl_source_paths.len() as i32:
            return with_str_clone_ref(self.decl_source_paths.get(di as i64))
        ""

    fn type_decl_source_file_id(type_sym: i32) -> i32:
        if type_sym == 0 or not self.type_decl_nodes.contains(type_sym):
            return 0
        let node = self.type_decl_nodes.get(type_sym).unwrap()
        let di = self.find_decl_index(node)
        if di >= 0 and di < self.decl_source_file_ids.len() as i32:
            return self.decl_source_file_ids.get(di as i64)
        0

    fn impl_decl_has_method(impl_node: i32, method_sym: i32) -> i32:
        let start = self.ast.get_start(impl_node)
        let end = self.ast.get_end(impl_node)
        // Same-file guard: spans are per-file offsets, so containment alone is
        // not membership in a multi-module pool (#734, see
        // impl_decl_method_node).
        let impl_path = self.decl_index_source_path(self.find_decl_index(impl_node))
        let method_name = self.pool_resolve(method_sym)
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_FN_DECL:
                continue
            let decl_start = self.ast.get_start(decl)
            let decl_end = self.ast.get_end(decl)
            if decl_start < start or decl_end > end:
                continue
            let decl_path = self.decl_index_source_path(di)
            if impl_path.len() > 0 and decl_path.len() > 0 and decl_path != impl_path:
                continue
            let fn_sym = self.ast.get_data0(decl)
            let fn_name = self.pool_resolve(fn_sym)
            let dot = sema_str_find_char(fn_name, 46)
            if dot < 0:
                if fn_name == method_name:
                    return 1
            else:
                let bare = fn_name.slice((dot + 1) as i64, fn_name.len() as i64)
                if bare == method_name:
                    return 1
        0

    fn trait_default_method_sig_exists(type_sym: i32, method_sym: i32) -> i32:
        if self.lookup_method_sig(type_sym, method_sym) >= 0:
            return 1
        0

    mut fn install_trait_default_type_args(trait_sym: i32, impl_node: i32):
        if trait_sym == 0 or impl_node == 0 or not self.trait_lookup.contains(trait_sym):
            return
        let trait_idx: i32 = self.trait_lookup.get(trait_sym).unwrap()
        let tp_count = self.trait_tp_counts.get(trait_idx as i64)
        if tp_count <= 0:
            return
        let tta_idx = self.ast.find_impl_trait_type_args(impl_node as NodeId)
        if tta_idx < 0:
            return
        let arg_start = self.ast.state.impl_trait_type_args.get((tta_idx + 1) as i64)
        let arg_count = self.ast.state.impl_trait_type_args.get((tta_idx + 2) as i64)
        let tp_start = self.trait_tp_starts.get(trait_idx as i64)
        var ti = 0
        while ti < tp_count and ti < arg_count:
            let tp_sym: i32 = self.trait_tp_syms.get((tp_start + ti) as i64)
            let arg_node = self.ast.get_extra(arg_start + ti)
            let arg_tid = self.resolve_type_expr(arg_node)
            if arg_tid != 0:
                self.put_generic_subst(tp_sym, arg_tid as i32, arg_node)
            ti = ti + 1

    mut fn resolve_trait_default_method_type(type_node: i32, impl_type_sym: i32, impl_type_tid: i32, trait_sym: i32, impl_node: i32) -> i32:
        if type_node == 0:
            return self.ty_void as i32
        let saved_self = if self.named_types.contains(self.syms.self_type): self.named_types.get(self.syms.self_type).unwrap() else: 0
        let saved_subst_syms = self.generic_subst_param_syms
        let saved_subst_tys = self.generic_subst_type_ids
        self.generic_subst_param_syms = Vec.new()
        self.generic_subst_type_ids = Vec.new()
        if impl_type_tid != 0:
            self.named_types.insert(self.syms.self_type, impl_type_tid)
        self.install_trait_default_type_args(trait_sym, impl_node)
        let resolved = self.resolve_type_expr(type_node) as i32
        if impl_type_tid != 0:
            if saved_self != 0:
                self.named_types.insert(self.syms.self_type, saved_self)
            else:
                self.named_types.remove(self.syms.self_type)
        self.generic_subst_param_syms = saved_subst_syms
        self.generic_subst_type_ids = saved_subst_tys
        resolved

    mut fn register_trait_default_method_for_impl(trait_sym: i32, impl_node: i32):
        if not self.trait_lookup.contains(trait_sym):
            return
        let impl_type_sym = self.ast.get_data0(impl_node)
        if impl_type_sym == 0:
            return
        let trait_idx: i32 = self.trait_lookup.get(trait_sym).unwrap()
        let mt_start = self.trait_method_starts.get(trait_idx as i64)
        let mt_count = self.trait_method_counts.get(trait_idx as i64)
        let impl_type_tid = self.lookup_named_type_visible(impl_type_sym)
        for mi in 0..mt_count:
            let mt_idx = mt_start + mi
            let default_body = self.trait_method_default_bodies.get(mt_idx as i64)
            if default_body == 0:
                continue
            let method_sym: i32 = self.trait_method_names.get(mt_idx as i64)
            if self.impl_decl_has_method(impl_node, method_sym) != 0:
                continue
            if self.trait_default_method_sig_exists(impl_type_sym, method_sym) != 0:
                continue

            let type_name: str = with_str_clone_ref(self.pool_resolve(impl_type_sym))
            let method_name: str = with_str_clone_ref(self.pool_resolve(method_sym))
            let fn_sym = self.pool_intern(type_name ++ "." ++ method_name)
            let param_start = self.trait_method_param_starts.get(mt_idx as i64)
            let param_count = self.trait_method_param_counts.get(mt_idx as i64)
            let sig_param_start = self.sig_params.len() as i32
            for pi in 0..param_count:
                let p_type_node = self.ast.fn_param_type(param_start, pi)
                let p_tid = self.resolve_trait_default_method_type(p_type_node, impl_type_sym, impl_type_tid, trait_sym, impl_node)
                self.sig_params.push(p_tid)
            let ret_node: i32 = self.trait_method_ret_nodes.get(mt_idx as i64)
            let ret_tid = self.resolve_trait_default_method_type(ret_node, impl_type_sym, impl_type_tid, trait_sym, impl_node)
            let fn_extra_start = self.type_extra.len() as i32
            for pi in 0..param_count:
                self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
            let fn_tid = self.add_type(TypeKind.TY_FN, fn_extra_start, param_count, ret_tid)
            self.add_sig(fn_sym, fn_tid, ret_tid, sig_param_start, param_count, 0)
            let sig_idx = self.get_sig(fn_sym)
            if sig_idx >= 0:
                for pi in 0..param_count:
                    if self.fn_param_uses_value_ref_abi(param_start, pi, impl_type_sym, impl_type_tid) != 0:
                        self.set_sig_param_value_ref_abi(sig_idx, pi, 1)
                let key = sema_pair_key(impl_type_sym, method_sym)
                self.method_lookup.sig_lookup.insert(key, sig_idx)
                self.method_lookup.fn_lookup.insert(key, fn_sym)
                self.method_symbol_flags.insert(fn_sym, 1)

    fn top_level_let_type_ann_extra(flags: i32) -> i32:
        let packed = flags / 16
        if packed <= 0:
            return -1
        packed - 1

    fn local_let_type_ann_extra(flags: i32) -> i32:
        let packed = flags / 2
        if packed <= 0:
            return -1
        packed - 1

    mut fn collect_let_decl(node: i32, is_local: i32):
        let name = self.ast.get_data0(node)
        if is_local != 0:
            var bind_name = self.extract_decl_name_after(node, "let")
            if bind_name.len() == 0:
                bind_name = self.extract_decl_name_after(node, "var")
            self.set_pretty_symbol(name, bind_name)
        let flags = self.ast.get_data2(node)
        let decl_is_pub = if (flags / 2) % 2 == 1: 1 else: 0
        self.record_decl_visibility(name, node, decl_is_pub)
        let is_mut = flags % 2
        if is_mut != 0:
            self.mutable_global_syms.insert(name, 1)
        // docs/mut.md Rev 8 §12 / §15.12 — register stable globals so
        // check_assign can emit the §15.12 diagnostic on rebind attempts
        // with a more helpful message than the generic immutable-binding error.
        if let_decl_is_global(flags) != 0 and let_decl_is_global_var(flags) == 0:
            self.stable_global_syms.insert(name, 1)
        var bind_ty: TypeId = 0 as TypeId
        let type_extra = self.top_level_let_type_ann_extra(flags)
        if type_extra >= 0:
            let type_node = self.ast.get_extra(type_extra)
            bind_ty = self.resolve_type_expr(type_node)
            if self.is_opaque_value_type(bind_ty) != 0:
                self.emit_error("opaque values cannot be stored by value; use a pointer or reference", type_node)
            if bind_ty != 0 and self.type_is_ephemeral_value(bind_ty as i32) != 0:
                self.emit_error("ephemeral values cannot be stored in global storage", type_node)
            if self.type_expr_is_collection_with_ref(type_node) != 0:
                self.emit_error("ephemeral references cannot be stored in generic containers", node)
        let decl_kind = if self.ast.let_decl_is_interface_provided(node): GLOBAL_VALUE_DECL_INTERFACE else: GLOBAL_VALUE_DECL_DEF
        self.register_top_level_global_decl(name, bind_ty as i32, is_mut, node, decl_kind)
        self.typed_binding_types.insert(node, bind_ty as i32)
        self.typed_binding_names.insert(node, name)
        self.typed_binding_muts.insert(node, is_mut)

    mut fn collect_trait_decl(node: i32, is_local: i32):
        let name = self.ast.get_data0(node)
        // First-wins, matching find_trait_decl_node's decl-order scan; decl
        // node ids are stable within a Sema instance so the memo never stales.
        if not self.trait_decl_node_cache.contains(name):
            self.trait_decl_node_cache.insert(name, node)
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
        //   [method_name, method_flags, param_start, param_count, ret_type,
        //    default_body, source_start, source_end]*]
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

        let method_count = self.ast.trait_method_count(node)
        pos = self.ast.trait_method_start(node)
        for i in 0..method_count:
            let mt_name = self.ast.get_extra(pos + TRAIT_METHOD_NAME)
            let mt_flags = self.ast.get_extra(pos + TRAIT_METHOD_FLAGS)
            let mt_param_start = self.ast.get_extra(pos + TRAIT_METHOD_PARAM_START)
            let mt_param_count = self.ast.get_extra(pos + TRAIT_METHOD_PARAM_COUNT)
            let mt_ret_node = self.ast.get_extra(pos + TRAIT_METHOD_RETURN_TYPE)
            let mt_default_body = self.ast.get_extra(pos + TRAIT_METHOD_DEFAULT_BODY)
            if (mt_flags / FnFlags.ASYNC) % 2 == 1:
                self.require_async_runtime(node, "async trait method")
            // docs/mutability.md — trait method must declare explicit receiver mode.
            if mt_param_count > 0:
                let p0_name = self.ast.get_extra(mt_param_start)
                if self.pool_resolve(p0_name) == "self":
                    let p0_type = self.ast.get_extra(mt_param_start + 1)
                    let p0_flags = self.ast.get_extra(mt_param_start + 2)
                    let has_mode = fn_param_is_mut_self(p0_flags) + fn_param_is_ref_self(p0_flags) + fn_param_is_move_self(p0_flags)
                    if has_mode == 0 and p0_type != 0 and self.ast.kind(p0_type as NodeId) == NodeKind.NK_TYPE_NAMED:
                        let p0_ty_sym = self.ast.get_data0(p0_type as NodeId)
                        if self.pool_resolve(p0_ty_sym) == "Self":
                            let mt_name_str = self.pool_resolve(mt_name)
                            self.emit_error(f"trait method '{mt_name_str}' requires an explicit receiver mode: use 'self: &Self', 'mut self: Self', or 'move self: Self'", node)
            self.trait_method_names.push(mt_name)
            self.trait_method_flags.push(mt_flags)
            self.trait_method_param_starts.push(mt_param_start)
            self.trait_method_param_counts.push(mt_param_count)
            self.trait_method_ret_nodes.push(mt_ret_node)
            self.trait_method_default_bodies.push(mt_default_body)
            pos = pos + TRAIT_METHOD_STRIDE
        self.trait_method_counts.push(method_count)
        self.trait_lookup.insert(name, trait_idx)
        if self.ast.is_sealed_trait_node(node) != 0:
            self.sealed_traits.insert(name, 1)
        if is_local != 0:
            self.local_trait_names.insert(name, 1)

    fn type_decl_type_param_count(type_name: i32) -> i32:
        if not self.type_decl_nodes.contains(type_name):
            return 0
        let td_node = self.type_decl_nodes.get(type_name).unwrap()
        let td_extra_start = self.ast.get_data1(td_node)
        let td_packed = self.ast.get_data2(td_node)
        let td_sub_kind = type_decl_sub_kind(td_packed)
        if td_sub_kind == TypeDeclKind.Struct:
            let field_count = self.ast.get_extra(td_extra_start)
            let after_fields = td_extra_start + 1 + field_count * 4
            return self.ast.get_extra(after_fields + 2)
        if td_sub_kind == TypeDeclKind.Alias or td_sub_kind == TypeDeclKind.Distinct:
            return self.ast.get_extra(td_extra_start + 3)
        if td_sub_kind == TypeDeclKind.Enum:
            let variant_count = self.ast.get_extra(td_extra_start)
            var epos = td_extra_start + 1
            for vi in 0..variant_count:
                epos = epos + 1
                let payload_count = self.ast.get_extra(epos)
                epos = epos + 1 + payload_count
            return self.ast.get_extra(epos + 2)
        0

    // Check if a new direct impl overlaps with any existing blanket impl
    mut fn check_direct_overlap(type_name: i32, trait_sym: i32, node: i32):
        for bi in 0..self.blanket_trait_syms.len() as i32:
            if self.blanket_trait_syms.get(bi as i64) != trait_sym:
                continue
            // If the blanket targets a specific type (e.g. impl[T] Trait for Vec[T]),
            // it only overlaps if this direct impl is for that same base type.
            let target_base = self.blanket_target_base_syms.get(bi as i64)
            if target_base != 0 and target_base != type_name:
                continue
            if target_base != 0 and self.type_decl_type_param_count(type_name) == 0:
                continue
            let b_start = self.blanket_bound_starts.get(bi as i64)
            let b_count = self.blanket_bound_counts.get(bi as i64)
            var all_ok = 1
            for bj in 0..b_count:
                let bound_trait = self.blanket_bound_syms.get((b_start + bj) as i64)
                if self.select_trait_impl(type_name, bound_trait) == 0:
                    all_ok = 0
            if all_ok != 0:
                let tn: str = with_str_clone_ref(self.pool_resolve(trait_sym))
                self.emit_error_code("overlapping implementations of '" ++ tn ++ "'", node, "E1201")

    // Check if a new blanket impl overlaps with any existing direct impl
    mut fn check_blanket_overlap(trait_sym: i32, bound_start: i32, bound_count: i32, target_base: i32, node: i32):
        for ti in 0..self.impl_type_syms.len() as i32:
            let t_sym = self.impl_type_syms.get(ti as i64)
            // If the blanket targets a specific type, only check that type.
            if target_base != 0 and target_base != t_sym:
                continue
            if target_base != 0 and self.type_decl_type_param_count(t_sym) == 0:
                continue
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
                let tn: str = with_str_clone_ref(self.pool_resolve(trait_sym))
                self.emit_error_code("overlapping implementations of '" ++ tn ++ "'", node, "E1201")

    mut fn warn_large_copy_type(type_name: i32, type_tid: i32, node: i32):
        if self.emit_config_warnings == 0:
            return
        let threshold = self.copy_warn_threshold
        if threshold <= 0 or type_tid <= 0:
            return
        if self.ast.kind(node) == NodeKind.NK_IMPL_DECL and self.ast.find_impl_type_params(node) >= 0:
            return
        if self.type_decl_type_param_count(type_name) != 0:
            return
        if self.type_has_unresolved_parts(type_tid) != 0:
            return
        let size = self.type_layout_size_of(type_tid)
        if size > threshold:
            let name = self.pool_resolve(type_name)
            self.emit_warning(f"large Copy type '{name}' is {size} bytes; implicit copies may be expensive (copy_warn_threshold={threshold})", node)

    mut fn collect_impl_decl(node: i32, is_local_impl: i32) -> Unit:
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
                self.emit_error_code("orphan rule violation: impl requires a local trait or local type", node, "E1101")
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
            let drop_sym = self.syms.drop
            // D29 scaffolding (#750): for a shadowed sym the conflict must be
            // judged against the impl target's own tier — this impl attaches to
            // whichever decl the (gated) lookup resolves from this module.
            let conflict_shadowed = self.type_sym_is_shadowed(type_name)
            let conflict_want_std = if conflict_shadowed != 0: self.type_tid_std_tier(self.resolve_alias(self.lookup_named_type_visible(type_name) as TypeId) as i32) else: 0
            if self.impl_lookup.contains(type_name):
                let drop_idx: i32 = self.impl_lookup.get(type_name).unwrap()
                let drop_start = self.impl_starts.get(drop_idx as i64)
                let drop_count = self.impl_counts.get(drop_idx as i64)
                for di in 0..drop_count:
                    let record_idx = drop_start + di
                    if conflict_shadowed != 0 and self.impl_record_matches_tier(record_idx, conflict_want_std) == 0:
                        continue
                    if self.impl_extra.get(record_idx as i64) == drop_sym:
                        self.emit_error("type '" ++ self.pool_resolve(type_name) ++ "' cannot implement Copy because it implements Drop", node)
                        return
            let type_tid = self.lookup_named_type_visible(type_name)
            if type_tid > 0:
                let tk = self.get_type_kind(self.resolve_alias(type_tid))
                if tk == TypeKind.TY_STRUCT:
                    let resolved = self.resolve_alias(type_tid)
                    let te_start = self.get_type_d1(resolved)
                    let field_count = self.get_type_d2(resolved)
                    for fi in 0..field_count:
                        let ft: i32 = self.type_extra.get((te_start + fi * 3 + 1) as i64)
                        if self.is_copy(ft) == 0:
                            let field_name: i32 = self.type_extra.get((te_start + fi * 3) as i64)
                            self.emit_error("type '" ++ self.pool_resolve(type_name) ++ "' cannot implement Copy: field '" ++ self.pool_resolve(field_name) ++ "' is not Copy", node)
                            return
                    self.warn_large_copy_type(type_name, type_tid, node)

        if trait_name == "Drop":
            let drop_conflict = if self.type_sym_is_shadowed(type_name) != 0:
                let want_std = self.type_tid_std_tier(self.resolve_alias(self.lookup_named_type_visible(type_name) as TypeId) as i32)
                self.select_trait_impl_tiered(type_name, self.syms.copy_trait, want_std)
            else:
                self.select_trait_impl(type_name, self.syms.copy_trait)
            if drop_conflict != 0:
                self.emit_error("type '" ++ self.pool_resolve(type_name) ++ "' cannot implement Drop because it implements Copy", node)
                return

        // Validate associated types: impl must provide all required (no-default) associated types
        if not is_lang_trait and self.trait_lookup.contains(trait_sym):
            let trait_idx: i32 = self.trait_lookup.get(trait_sym).unwrap()
            let at_start = self.trait_assoc_starts.get(trait_idx as i64)
            let at_count = self.trait_assoc_counts.get(trait_idx as i64)
            if at_count > 0:
                // Read impl's associated type bindings from AST extra
                let impl_extra_start = self.ast.get_data1(node)
                let impl_at_count = self.ast.get_extra(impl_extra_start)
                for ati in 0..at_count:
                    let required_name: i32 = self.trait_assoc_names.get((at_start + ati) as i64)
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
                        let ab_start: i32 = self.trait_assoc_bound_starts.get(at_global_idx as i64)
                        let ab_count: i32 = self.trait_assoc_bound_counts.get(at_global_idx as i64)
                        if ab_count > 0:
                            let at_name_sym: i32 = self.trait_assoc_names.get(at_global_idx as i64)
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
                                                let tname: str = with_str_clone_ref(self.pool_resolve(at_name_sym))
                                                let bname: str = with_str_clone_ref(self.pool_resolve(bound_sym))
                                                self.emit_error("associated type '" ++ tname ++ "' does not satisfy bound '" ++ bname ++ "'", node)
                                                return

        // Check for blanket impl (impl-level type params)
        let tp_meta_idx = self.ast.find_impl_type_params(node)
        if tp_meta_idx >= 0:
            // Blanket impl: collect bounds and register
            let tp_start = self.ast.state.impl_type_params.get((tp_meta_idx + 1) as i64)
            let tp_count = self.ast.state.impl_type_params.get((tp_meta_idx + 2) as i64)
            let bound_start = self.blanket_bound_syms.len() as i32
            var total_bounds = 0
            var tp_off: i32 = tp_start
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
            var target_base_sym = 0
            if target_type_nd != 0 and self.ast.kind(target_type_nd) == NodeKind.NK_TYPE_GENERIC:
                target_base_sym = self.ast.get_data0(target_type_nd)
            self.blanket_target_base_syms.push(target_base_sym)
            self.blanket_impl_nodes.push(node)
            // Overlap check: blanket vs existing direct impls
            self.check_blanket_overlap(trait_sym, bound_start, total_bounds, target_base_sym, node)
            return

        // If the impl target is a generic type (e.g., impl Trait for Vec[i32]),
        // resolve the full type and record it for exact-match trait selection.
        let target_type_node = self.ast.find_impl_target_type_node(node)
        var exact_generic_impl = 0
        if target_type_node != 0:
            let target_tid = self.resolve_type_expr(target_type_node)
            if target_tid != 0 and self.get_type_kind(target_tid) == TypeKind.TY_GENERIC_INST:
                let gi_key = sema_pair_key(target_tid as i32, trait_sym)
                if self.impl_generic_inst.contains(gi_key):
                    self.emit_error_code("duplicate implementation of trait for type", node, "E1102")
                    return
                self.impl_generic_inst.insert(gi_key, 1)
                exact_generic_impl = 1

        // Overlap check: direct impl vs existing blanket impls
        self.check_direct_overlap(type_name, trait_sym, node)

        if exact_generic_impl != 0:
            return

        // Record direct impl
        // D29 scaffolding (#750): E1102 keys on the RESOLVED impl target, not
        // the bare name. For a shadowed sym, a prior record collides only when
        // it belongs to the tier this impl attaches to (the decl the gated
        // lookup resolves from this module) — std's impl and the user's impl
        // of the same trait for same-named types coexist; a true same-tier
        // duplicate still errors.
        let dup_shadowed = self.type_sym_is_shadowed(type_name)
        let dup_want_std = if dup_shadowed != 0: self.type_tid_std_tier(self.resolve_alias(self.lookup_named_type_visible(type_name) as TypeId) as i32) else: 0
        // When appending to an existing type, relocate all entries to keep them
        // contiguous (the flat impl_extra vec is shared across all types).
        if self.impl_lookup.contains(type_name):
            let idx: i32 = self.impl_lookup.get(type_name).unwrap()
            let old_start = self.impl_starts.get(idx as i64)
            let old_count = self.impl_counts.get(idx as i64)
            for i in 0..old_count:
                if dup_shadowed != 0 and self.impl_record_matches_tier(old_start + i, dup_want_std) == 0:
                    continue
                if self.impl_extra.get((old_start + i) as i64) == trait_sym:
                    self.emit_error_code("duplicate implementation of trait for type", node, "E1102")
                    return
            // Copy existing entries to end for contiguity
            let new_start = self.impl_extra.len() as i32
            for i in 0..old_count:
                self.impl_extra.push(self.impl_extra.get((old_start + i) as i64))
                self.impl_extra_is_std.push(self.impl_extra_is_std.get((old_start + i) as i64))
            self.impl_extra.push(trait_sym)
            self.impl_extra_is_std.push(sema_tier_path_is_std_implementation(self.current_module_path))
            self.impl_starts.set_i32(idx as i64, new_start)
            self.impl_counts.set_i32(idx as i64, old_count + 1)
        else:
            let idx = self.impl_type_syms.len() as i32
            self.impl_type_syms.push(type_name)
            self.impl_starts.push(self.impl_extra.len() as i32)
            self.impl_counts.push(1)
            self.impl_extra.push(trait_sym)
            self.impl_extra_is_std.push(sema_tier_path_is_std_implementation(self.current_module_path))
            self.impl_lookup.insert(type_name, idx)

        // Track sealed trait implementors
        if self.sealed_traits.contains(trait_sym):
            if self.sealed_impl_starts.contains(trait_sym):
                let si_start: i32 = self.sealed_impl_starts.get(trait_sym).unwrap()
                let si_count: i32 = self.sealed_impl_counts.get(trait_sym).unwrap()
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

        self.register_trait_default_method_for_impl(trait_sym, node)

fn sema_trait_method_flag_generic -> i32: 4

impl Sema:
    fn type_is_dyn_object(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid)
        let tk = self.get_type_kind(resolved)
        if tk == TypeKind.TY_TRAIT_OBJ:
            return 1
        if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
            return self.type_is_dyn_object(self.get_type_d0(resolved))
        0

    fn find_trait_decl_node(trait_sym: i32) -> NodeId:
        if self.trait_decl_node_cache.contains(trait_sym):
            return self.trait_decl_node_cache.get(trait_sym).unwrap() as NodeId
        // trait_decl_node_cache is authoritative: collect_trait_decl inserts
        // every NK_TRAIT_DECL keyed by the same data0 symbol this lookup uses,
        // so a cache miss means `trait_sym` is not a trait. (The former O(n)
        // decl-order fallback scan never matched over a full self-compile — it
        // only re-derived the miss at whole-program cost.)
        0 as NodeId

    mut fn emit_trait_object_safety_error(trait_sym: i32, method_sym: i32, reason: &str, node: i32):
        let trait_name: str = with_str_clone_ref(self.pool_resolve(trait_sym))
        let method_name: str = with_str_clone_ref(self.pool_resolve(method_sym))
        self.emit_error("trait '" ++ trait_name ++ "' is not object-safe: method '" ++ method_name ++ "' " ++ reason, node)

    fn type_node_mentions_self(type_node: i32) -> i32:
        if type_node == 0:
            return 0
        let kind = self.ast.kind(type_node)
        if kind == NodeKind.NK_TYPE_NAMED:
            return if self.ast.get_data0(type_node) == self.syms.self_type: 1 else: 0
        if kind == NodeKind.NK_TYPE_ASSOC:
            return if self.ast.get_data0(type_node) == self.syms.self_type: 1 else: 0
        if kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_OPTIONAL or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_ARRAY:
            return self.type_node_mentions_self(self.ast.get_data0(type_node))
        if kind == NodeKind.NK_TYPE_TUPLE:
            let extra_start = self.ast.get_data0(type_node)
            let elem_count = self.ast.get_data1(type_node)
            for ei in 0..elem_count:
                if self.type_node_mentions_self(self.ast.get_extra(extra_start + ei)) != 0:
                    return 1
            return 0
        if kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_EXTERN_FN:
            let extra_start = self.ast.get_data0(type_node)
            let param_count = self.ast.get_data1(type_node)
            let ret_node = self.ast.get_data2(type_node)
            for pi in 0..param_count:
                if self.type_node_mentions_self(self.ast.get_extra(extra_start + pi)) != 0:
                    return 1
            return self.type_node_mentions_self(ret_node)
        if kind == NodeKind.NK_TYPE_GENERIC:
            if self.ast.get_data0(type_node) == self.syms.self_type:
                return 1
            let extra_start = self.ast.get_data1(type_node)
            let arg_count = self.ast.get_data2(type_node)
            for ai in 0..arg_count:
                if self.type_node_mentions_self(self.ast.get_extra(extra_start + ai)) != 0:
                    return 1
        0

    mut fn ensure_trait_object_safe(trait_sym: i32, node: i32) -> i32:
        let trait_node = self.find_trait_decl_node(trait_sym)
        if trait_node == 0:
            return 1
        let method_count = self.ast.trait_method_count(trait_node)
        let self_name_sym = self.pool_intern("self")
        for mi in 0..method_count:
            let method_sym = self.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_NAME)
            let method_flags = self.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_FLAGS)
            let param_start = self.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_PARAM_START)
            let param_count = self.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_PARAM_COUNT)
            let ret_node = self.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_RETURN_TYPE)

            if param_count <= 0:
                self.emit_trait_object_safety_error(trait_sym, method_sym, "has no self parameter", node)
                return 0

            let first_param_name = self.ast.fn_param_name(param_start, 0)
            if first_param_name != self_name_sym:
                self.emit_trait_object_safety_error(trait_sym, method_sym, "has no self parameter", node)
                return 0

            let first_param_flags = self.ast.fn_param_flags(param_start, 0)
            if fn_param_is_ref_self(first_param_flags) == 0 and fn_param_is_mut_self(first_param_flags) == 0 and fn_param_is_move_self(first_param_flags) == 0:
                self.emit_trait_object_safety_error(trait_sym, method_sym, "receiver is not object-safe; use 'self: &Self', 'mut self: Self', or Box[dyn Trait] for 'move self: Self'", node)
                return 0

            if (method_flags / sema_trait_method_flag_generic()) % 2 == 1:
                self.emit_trait_object_safety_error(trait_sym, method_sym, "is generic", node)
                return 0

            for pi in 1..param_count:
                let p_type_node = self.ast.fn_param_type(param_start, pi)
                if self.type_node_mentions_self(p_type_node) != 0:
                    self.emit_trait_object_safety_error(trait_sym, method_sym, "parameter mentions Self outside the receiver", node)
                    return 0

            if self.type_node_mentions_self(ret_node) != 0:
                self.emit_trait_object_safety_error(trait_sym, method_sym, "return type mentions Self", node)
                return 0

        1

    mut fn validate_type_expr_with_type_params(node: i32, tp_start: i32, tp_count: i32):
        self.validate_type_expr_with_impl_type_params(node, tp_start, tp_count, 0)

    mut fn validate_type_expr_with_impl_type_params(node: i32, tp_start: i32, tp_count: i32, impl_node: i32):
        if node == 0:
            return

        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_TYPE_NAMED:
            let sym = self.ast.get_data0(node)
            if self.primitive_type_by_sym(sym) != 0:
                return
            if self.has_named_type_visible(sym) != 0:
                return
            if self.type_param_exists_in_impl_context(tp_start, tp_count, impl_node, sym) != 0:
                return
            // Allow Self in method contexts (resolved at codegen time)
            if self.pool_resolve(sym) == "Self":
                return
            self.debug_unknown_type(sym, node, "validate_type_expr")
            self.emit_unknown_type_error(sym, node)
            return

        if kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_OPTIONAL or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_ARRAY:
            self.validate_type_expr_with_impl_type_params(self.ast.get_data0(node), tp_start, tp_count, impl_node)
            return

        if kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_EXTERN_FN:
            let extra_start = self.ast.get_data0(node)
            let param_count = self.ast.get_data1(node)
            let ret_node = self.ast.get_data2(node)
            for pi in 0..param_count:
                self.validate_type_expr_with_impl_type_params(self.ast.get_extra(extra_start + pi), tp_start, tp_count, impl_node)
            self.validate_type_expr_with_impl_type_params(ret_node, tp_start, tp_count, impl_node)
            return

        if kind == NodeKind.NK_TYPE_TUPLE:
            let extra_start = self.ast.get_data0(node)
            let elem_count = self.ast.get_data1(node)
            for ei in 0..elem_count:
                self.validate_type_expr_with_impl_type_params(self.ast.get_extra(extra_start + ei), tp_start, tp_count, impl_node)
            return

        if kind == NodeKind.NK_TYPE_GENERIC:
            let base_sym = self.ast.get_data0(node)
            let base_prim = self.primitive_type_by_sym(base_sym)
            if base_prim == 0 and self.has_named_type_visible(base_sym) == 0 and self.type_param_exists_in_impl_context(tp_start, tp_count, impl_node, base_sym) == 0:
                self.debug_unknown_type(base_sym, node, "validate_type_generic")
                self.emit_unknown_type_error(base_sym, node)
            let extra_start = self.ast.get_data1(node)
            let arg_count = self.ast.get_data2(node)
            for ai in 0..arg_count:
                self.validate_type_expr_with_impl_type_params(self.ast.get_extra(extra_start + ai), tp_start, tp_count, impl_node)
            return

        if kind == NodeKind.NK_TYPE_TRAIT_OBJ:
            let trait_sym = self.ast.get_data0(node)
            if not self.lang_trait_syms.contains(trait_sym) and not self.trait_lookup.contains(trait_sym):
                self.emit_error("unknown trait", node)
                return
            if self.ast.get_data1(node) != TYPE_TRAIT_OBJECT_IMPL:
                let _ok = self.ensure_trait_object_safe(trait_sym, node)
            return

    mut fn validate_where_clause(fn_node: i32, tp_start: i32, tp_count: i32):
        let where_idx = self.ast.find_where_meta(fn_node)
        if where_idx < 0:
            return
        let where_start = self.ast.state.where_meta.get((where_idx + 1) as i64)
        let where_count = self.ast.state.where_meta.get((where_idx + 2) as i64)
        var pos: i32 = where_start
        for wi in 0..where_count:
            let wp_name = self.ast.get_extra(pos)
            let bound_count = self.ast.get_extra(pos + 1)
            // Validate type param references a known type parameter
            if self.type_param_exists(tp_start, tp_count, wp_name) == 0:
                let wp_str: str = with_str_clone_ref(self.pool_resolve(wp_name))
                self.emit_error("where clause references unknown type parameter '" ++ wp_str ++ "'", fn_node)
            // Validate each bound references a known trait
            for bi in 0..bound_count:
                let trait_sym = self.ast.get_extra(pos + 2 + bi)
                let trait_name: str = with_str_clone_ref(self.pool_resolve(trait_sym))
                if trait_name == "type":
                    continue
                if not self.lang_trait_syms.contains(trait_sym) and not self.trait_lookup.contains(trait_sym):
                    self.emit_error("where clause references unknown trait '" ++ trait_name ++ "'", fn_node)
            pos = pos + 2 + bound_count

    fn type_decl_enum_tail_index(extra_start: i32) -> i32:
        var pos = extra_start
        let variant_count = self.ast.get_extra(pos)
        pos = pos + 1
        for vi in 0..variant_count:
            pos = pos + 1 // variant name
            let payload_count = self.ast.get_extra(pos)
            pos = pos + 1 + payload_count
        pos

    fn type_decl_disc_enum_tail_index(extra_start: i32) -> i32:
        var pos = extra_start + 1 // skip repr_type_node
        let variant_count = self.ast.get_extra(pos)
        pos = pos + 1
        for vi in 0..variant_count:
            pos = pos + 1 // variant name
            pos = pos + 1 // disc value
            let payload_count = self.ast.get_extra(pos)
            pos = pos + 1 + payload_count
        pos

    fn type_decl_tp_start(node: i32) -> i32:
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

    fn type_decl_tp_count(node: i32) -> i32:
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

    fn type_decl_has_derive(node: i32, trait_sym: i32) -> i32:
        let meta = self.ast.find_type_meta(node)
        if meta < 0:
            return 0
        let derive_start = self.ast.type_meta_derive_start(meta)
        let derive_count = self.ast.type_meta_derive_count(meta)
        for i in 0..derive_count:
            if self.ast.get_extra(derive_start + i) == trait_sym:
                return 1
        0

    mut fn validate_copy_derives():
        let copy_sym = self.syms.copy_trait
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

            let tid = self.lookup_named_type_visible(type_name)
            if tid == 0:
                continue
            let resolved = self.resolve_alias(tid)
            if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
                continue

            let te_start = self.get_type_d1(resolved)
            let field_count = self.get_type_d2(resolved)
            var has_noncopy_field = 0
            for fi in 0..field_count:
                let field_tid: i32 = self.type_extra.get((te_start + fi * 3 + 1) as i64)
                if field_tid == 0 or self.is_copy(field_tid) == 0:
                    has_noncopy_field = 1
                    break
            if has_noncopy_field != 0:
                self.emit_error("cannot derive Copy for a type with non-Copy fields", decl)
            else:
                self.warn_large_copy_type(type_name, tid, decl)

    mut fn validate_compiler_hooks():
        for hi in 0..self.ast.compiler_hook_count():
            let hook_node = self.ast.compiler_hook_node(hi)
            let phase_sym = self.ast.compiler_hook_phase_at(hi)
            let phase_name: str = with_str_clone_ref(self.pool_resolve_symbol(phase_sym))
            if phase_name != "after_typecheck":
                self.emit_error("unknown compiler_hook phase '" ++ phase_name ++ "'", hook_node)
            let meta = self.ast.find_fn_meta(hook_node)
            if meta < 0:
                continue
            let param_start = self.ast.fn_meta_param_start(meta)
            let param_count = self.ast.fn_meta_param_count(meta)
            for pi in 0..param_count:
                let param_type = self.ast.fn_param_type(param_start, pi)
                if self.compiler_hook_param_is_supported(param_type) == 0:
                    self.emit_error("compiler_hook parameter must be ProjectInfo, Diagnostics, or SourceEmitter from std.compiler", hook_node)

    mut fn compiler_hook_param_is_supported(type_node: i32) -> i32:
        if type_node == 0:
            return 0
        let tid = self.resolve_type_expr(type_node)
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid)
        if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return 0
        let type_sym = self.get_type_d0(resolved)
        let type_name = self.pool_resolve(type_sym)
        let type_path = self.named_type_path_for(type_sym, resolved)
        if capability_registry_compiler_hook_param_supported(type_path, type_name):
            return 1
        0

    mut fn validate_generic_type_decls():
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

    fn type_expr_mentions_type_param(type_node: i32, tp_sym: i32) -> i32:
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
        if kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_EXTERN_FN:
            let extra_start = self.ast.get_data0(type_node)
            let param_count = self.ast.get_data1(type_node)
            for pi in 0..param_count:
                if self.type_expr_mentions_type_param(self.ast.get_extra(extra_start + pi), tp_sym) != 0:
                    return 1
            return self.type_expr_mentions_type_param(self.ast.get_data2(type_node), tp_sym)
        0

    fn type_param_mentions_any_param_type(tp_sym: i32, param_start: i32, param_count: i32) -> i32:
        for pi in 0..param_count:
            let p_type_node = self.ast.fn_param_type(param_start, pi)
            if self.type_expr_mentions_type_param(p_type_node, tp_sym) != 0:
                return 1
        0

    mut fn ensure_generic_substitutions(tp_start: i32, tp_count: i32, param_start: i32, param_count: i32, call_node: i32):
        var pos: i32 = tp_start
        for ti in 0..tp_count:
            let tp_name = self.ast.get_extra(pos)
            let bound_count = self.ast.get_extra(pos + 1)
            if self.lookup_generic_subst(tp_name) == 0:
                if self.type_param_mentions_any_param_type(tp_name, param_start, param_count) != 0:
                    // #738: a mentioned-but-unbound param means inference
                    // FAILED (mismatched argument shape) — say so instead of
                    // silently substituting i32, which manufactures
                    // diagnostics about types the user never wrote. The i32
                    // default survives only as cascade suppression when the
                    // arguments already errored.
                    if self.diags.count_by_severity(DiagSeverity.Error) == 0:
                        let mb_name = self.pool_resolve(tp_name)
                        self.emit_error(f"cannot infer type parameter '{mb_name}' for this call; the argument's shape does not match the parameter type that mentions '{mb_name}'", call_node)
                        return
                    self.put_generic_subst(tp_name, self.ty_i32, call_node)
                else:
                    // #598 (ruled: no turbofish): teach the restructure instead of
                    // a bare "unknown type" cascade.
                    let ug_name = self.pool_resolve(tp_name)
                    self.emit_error(f"cannot infer type parameter '{ug_name}' for this call; annotate the result binding or pass an argument that mentions '{ug_name}'", call_node)
                    return
            pos = pos + 2 + bound_count

    fn primitive_type_by_sym(sym: i32) -> i32:
        let named_tid = self.lookup_named_type_visible(sym)
        if named_tid != 0:
            let named_resolved = self.resolve_alias(named_tid)
            let named_kind = self.get_type_kind(named_resolved)
            if named_kind == TypeKind.TY_INT or named_kind == TypeKind.TY_FLOAT or named_kind == TypeKind.TY_BOOL or named_kind == TypeKind.TY_VOID or named_kind == TypeKind.TY_STR or named_kind == TypeKind.TY_NEVER:
                return named_tid
            if named_tid == self.ty_str_view:
                return named_tid
        let name = self.pool_resolve_symbol(sym)
        if sema_str_has_data(name) == 0:
            return 0
        if name == "i8": return self.ty_i8 as i32
        if name == "i16": return self.ty_i16 as i32
        if name == "i32": return self.ty_i32 as i32
        if name == "i64": return self.ty_i64 as i32
        if name == "i128": return self.ty_i128 as i32
        if name == "u8": return self.ty_u8 as i32
        if name == "u16": return self.ty_u16 as i32
        if name == "u32": return self.ty_u32 as i32
        if name == "u64": return self.ty_u64 as i32
        if name == "u128": return self.ty_u128 as i32
        if name == "f32": return self.ty_f32 as i32
        if name == "f64": return self.ty_f64 as i32
        if name == "bool": return self.ty_bool as i32
        if name == "Unit": return self.ty_void as i32
        if name == "Never": return self.ty_never as i32
        if name == "str": return self.ty_str as i32
        if name == "usize": return self.ty_usize as i32
        // #627 (option D, split ruling 2026-07-05): Int/UInt/String/StrView are
        // NOT resolution-first here — they resolve via their register_prim
        // (empty-path, prelude-tier) named-type entries when unshadowed, but a user
        // declaration of the same name shadows them (lookup_named_type_visible
        // returns the visible user type first). CStr is likewise a plain named
        // type. Unit/Never stay compiler-reserved (core types, ~331 uses).
        if name == "isize": return self.ty_isize as i32
        // Sub-byte and non-standard integer widths: u1-u7, i1-i7, u12, u21, u24
        let nlen = name.len()
        if nlen >= 2 and nlen <= 3:
            let first = name.byte_at(0)
            if first == 117 or first == 105:  // 'u' or 'i'
                let is_signed = if first == 105: 1 else: 0
                var width: i32 = 0
                var all_digits = true
                for di in 1..nlen as i32:
                    let ch = name.byte_at(di as i64)
                    if ch >= 48 and ch <= 57:
                        width = width * 10 + (ch - 48)
                    else:
                        all_digits = false
                if all_digits and width > 0 and width < 128:
                    // Already handled standard widths above
                    if width != 8 and width != 16 and width != 32 and width != 64 and width != 128:
                        // Search pre-registered sub-byte types
                        for ti in 0..self.type_kinds.len() as i32:
                            if self.type_kinds.get(ti as i64) == TypeKind.TY_INT:
                                if self.type_d0.get(ti as i64) == width and self.type_d1.get(ti as i64) == is_signed:
                                    return ti
        0

    // Return the unsigned counterpart of a signed integer type (i32→u32, etc.).
    // Returns the input type unchanged if already unsigned or not an integer.
    fn unsigned_counterpart(tid: i32) -> i32:
        let resolved = self.resolve_alias(tid as TypeId)
        let tk = self.get_type_kind(resolved)
        if tk != TypeKind.TY_INT: return tid
        let is_signed = self.get_type_d1(resolved)
        if is_signed == 0: return tid  // already unsigned
        let width = self.get_type_d0(resolved)
        // Search for unsigned type with same width
        for ti in 0..self.type_kinds.len() as i32:
            if self.type_kinds.get(ti as i64) == TypeKind.TY_INT:
                if self.type_d0.get(ti as i64) == width and self.type_d1.get(ti as i64) == 0 and self.type_d2.get(ti as i64) == 0:
                    return ti
        tid  // fallback: return original

    // Resolve the Order enum type for Atomic[T] method argument type propagation.
    fn resolve_atomic_order_type(obj_type: i32) -> i32:
        if obj_type == 0: return 0
        let resolved = self.resolve_alias(obj_type as TypeId)
        let name_sym = self.get_type_name(resolved as i32)
        if name_sym == 0: return 0
        let name = self.pool_resolve_symbol(name_sym)
        if name == "Atomic":
            let order_sym = self.pool_lookup_symbol("Order")
            if order_sym == 0:
                return 0
            return self.lookup_named_type_visible(order_sym)
        0

    // Determine expected argument type for an Atomic method call.
    fn atomic_method_expected_arg_type(order_type: i32, method_sym: i32, arg_index: i32) -> i32:
        if order_type == 0: return 0
        let method_name = self.pool_resolve_symbol(method_sym)
        if method_name == "load" and arg_index == 0: return order_type
        if method_name == "store" and arg_index == 1: return order_type
        if method_name == "compare_exchange" and (arg_index == 2 or arg_index == 3): return order_type
        if method_name == "compare_exchange_weak" and (arg_index == 2 or arg_index == 3): return order_type
        // swap, fetch_add, fetch_sub, etc.: arg 1 is the ordering
        if arg_index == 1 and method_name != "load" and method_name != "store" and method_name != "compare_exchange" and method_name != "compare_exchange_weak":
            return order_type
        0

    fn atomic_order_stronger_than(left: i32, right: i32) -> i32:
        if left < 0 or right < 0:
            return 0
        let left_rank =
            if left == 0: 0
            else if left == 1 or left == 2: 1
            else if left == 3: 2
            else: 3
        let right_rank =
            if right == 0: 0
            else if right == 1 or right == 2: 1
            else if right == 3: 2
            else: 3
        if left_rank > right_rank: 1 else: 0

    // Validate ordering constraints for Atomic methods.
    // Checks disc enum variant value at sema time.
    mut fn validate_atomic_ordering(method_sym: i32, extra_start: i32, arg_count: i32, node: i32):
        let method_name = self.pool_resolve_symbol(method_sym)
        // store cannot use Acquire(1) or AcqRel(3)
        if method_name == "store" and arg_count >= 2:
            let order_node = self.ast.get_extra(extra_start + 1)
            let order_val = self.try_resolve_disc_enum_value(order_node)
            if order_val == 1 or order_val == 3:
                self.emit_error("store cannot use Acquire or AcqRel ordering", order_node)
        // load cannot use Release(2) or AcqRel(3)
        if method_name == "load" and arg_count >= 1:
            let order_node = self.ast.get_extra(extra_start)
            let order_val = self.try_resolve_disc_enum_value(order_node)
            if order_val == 2 or order_val == 3:
                self.emit_error("load cannot use Release or AcqRel ordering", order_node)
        if (method_name == "compare_exchange" or method_name == "compare_exchange_weak") and arg_count >= 4:
            let success_node = self.ast.get_extra(extra_start + 2)
            let failure_node = self.ast.get_extra(extra_start + 3)
            let success_val = self.try_resolve_disc_enum_value(success_node)
            let failure_val = self.try_resolve_disc_enum_value(failure_node)
            if failure_val == 2 or failure_val == 3:
                self.emit_error("compare_exchange failure ordering cannot be Release or AcqRel", failure_node)
            if self.atomic_order_stronger_than(failure_val, success_val) != 0:
                self.emit_error("compare_exchange failure ordering cannot be stronger than success ordering", failure_node)

    // Try to resolve the discriminant value of a disc enum variant expression.
    // Returns -1 if the node is not a resolvable variant.
    fn try_resolve_disc_enum_value(node: i32) -> i32:
        if node == 0: return -1
        let kind = self.ast.kind(node)
        // Order.Acquire → NK_FIELD_ACCESS on Order type
        if kind == NodeKind.NK_FIELD_ACCESS:
            let field_sym = self.ast.get_data1(node)
            let field_name = self.pool_resolve_symbol(field_sym)
            if field_name == "Relaxed": return 0
            if field_name == "Acquire": return 1
            if field_name == "Release": return 2
            if field_name == "AcqRel": return 3
            if field_name == "SeqCst": return 4
        // .Acquire → NK_VARIANT_SHORTHAND
        if kind == NodeKind.NK_VARIANT_SHORTHAND:
            let var_sym = self.ast.get_data0(node)
            let var_name = self.pool_resolve_symbol(var_sym)
            if var_name == "Relaxed": return 0
            if var_name == "Acquire": return 1
            if var_name == "Release": return 2
            if var_name == "AcqRel": return 3
            if var_name == "SeqCst": return 4
        -1
