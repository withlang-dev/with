// Compiler-integrated analysis over live Sema and MIR state. This is the
// semantic source of truth behind `with analyze`; standalone repository tools
// should call this surface rather than reconstruct compiler facts from text.

use AnalysisTypes
use Ast
use Diagnostic
use InternPool
use Mir
use Sema

extern fn with_str_clone_ref(s: &str) -> str

pub type CompilerAnalysisResult {
    text: str,
    status: i32,
    needs_codegen: bool,
    codegen_query: str,
    report: AnalysisReport,
}

fn analysis_line_for_offset(source: &str, offset: i32) -> i32:
    var line = 1
    let stop = if offset < source.len() as i32: offset else: source.len() as i32
    for i in 0..stop:
        if source.byte_at(i as i64) as i32 == 10:
            line = line + 1
    line

fn analysis_column_for_offset(source: &str, offset: i32) -> i32:
    var start = offset - 1
    while start >= 0 and source.byte_at(start as i64) as i32 != 10:
        start = start - 1
    offset - start

fn analysis_with_node_location(fact: AnalysisFact, sema: &Sema, node: i32, source_path: &str, source_text: &str) -> AnalysisFact:
    var located = fact
    located.node = node
    located.path = with_str_clone_ref(source_path)
    if node <= 0 or node >= sema.ast.node_count():
        return located
    let start = sema.ast.get_start(node)
    located.start = start
    located.end = sema.ast.get_end(node)
    located.line = analysis_line_for_offset(source_text, start)
    located.column = analysis_column_for_offset(source_text, start)
    located

fn analysis_sig_path(sema: &Sema, sym: i32, fallback: &str) -> str:
    let found = sema.fn_decl_source_paths.get(sym)
    if found.is_some(): with_str_clone_ref(found.unwrap()) else: with_str_clone_ref(fallback)

fn analysis_decl_path(sema: &Sema, decl_index: i32, fallback: &str) -> str:
    let path = sema.decl_source_path_for_index(decl_index)
    if path.len() > 0: path else: with_str_clone_ref(fallback)

fn analysis_decl_source(sema: &Sema, decl_index: i32, fallback: &str) -> str:
    let source = sema.source_text_for_file_id(sema.decl_source_file_id_for_index(decl_index))
    if source.len() > 0: source else: with_str_clone_ref(fallback)

fn analysis_receiver_mode_name(mode: ReceiverMode) -> str:
    if mode == ReceiverMode.Read: return "read"
    if mode == ReceiverMode.Mut: return "mut"
    if mode == ReceiverMode.Move: return "move"
    if mode == ReceiverMode.Missing: return "missing"
    "none"

fn analysis_param_class(sema: &Sema, sig: i32, param: i32) -> str:
    let ty = sema.sig_param_type(sig, param)
    if ty > 0 and sema.get_type_kind(sema.resolve_alias(ty as TypeId)) == TypeKind.TY_REF:
        return "borrowed"
    let copy_type = ty > 0 and sema.types_frozen != 0 and sema.is_copy_frozen(ty as TypeId) != 0
    if copy_type:
        return "copy"
    if sema.sig_param_uses_value_ref_abi(sig, param) != 0:
        return "share-place"
    "owned"

fn analysis_collect_declarations(report: &AnalysisReport, sema: &Sema, source_path: &str, source_text: &str):
    for di in 0..sema.ast.decl_count():
        let node = sema.ast.get_decl(di)
        if sema.ast.kind(node) != NodeKind.NK_FN_DECL:
            continue
        let meta = sema.ast.find_fn_meta(node)
        if meta < 0:
            continue
        let parsed = sema.ast.get_data0(node)
        let sym = sema.fn_decl_semantic_symbol_at(node, parsed, di)
        let sig = sema.get_sig(sym)
        let param_start = sema.ast.fn_meta_param_start(meta)
        let param_count = sema.ast.fn_meta_param_count(meta)
        let type_params = sema.ast.fn_meta_tp_count(meta)
        let mode = sema.receiver_mode_from_param(param_start, param_count)
        let receiver_type = if mode != ReceiverMode.None and param_count > 0: sema.ast.fn_param_type(param_start, 0) else: 0
        let receiver_flags = if mode != ReceiverMode.None and param_count > 0: sema.ast.fn_param_flags(param_start, 0) else: 0
        let synthetic_receiver = fn_param_is_synth_receiver(receiver_flags) != 0
        let explicit_receiver = mode != ReceiverMode.None and not synthetic_receiver
        let in_impl = sema.method_decl_impl_nodes.contains(di)
        let trait_impl = in_impl and sema.method_decl_origins.contains(di) and sema.method_decl_origins.get(di).unwrap() == 1
        let parsed_name = sema.extract_decl_name_after(node, "fn")
        let top_level_method = not in_impl and parsed_name.contains(".")
        var owner = if in_impl: sema.impl_owner_type_sym_for_decl(node) else: 0
        if owner == 0 and top_level_method:
            let dot = analysis_find_from(parsed_name, ".", 0)
            if dot > 0: owner = sema.pool_lookup_symbol(analysis_slice(parsed_name, 0, dot))
        var receiver_effects = if mode != ReceiverMode.None: sema.receiver_required_effect_for_decl(node) else: 0
        var receiver_proven = mode != ReceiverMode.None and sema.receiver_decl_has_effect_signature(node)
        if mode != ReceiverMode.None and not receiver_proven:
            let contract_effect = sema.receiver_trait_contract_effect_for_decl(di, node)
            if contract_effect >= 0:
                receiver_effects = contract_effect
                receiver_proven = true
        let source_file = sema.decl_source_file_id_for_index(di)
        let decl_path = analysis_decl_path(sema, di, source_path)
        let decl_source = analysis_decl_source(sema, di, source_text)
        var fact = AnalysisFact.new(AnalysisStage.Ast, AnalysisFactKind.Declaration)
        fact.id = di
        fact.parent = sig
        fact.symbol = sym
        fact.owner = owner
        fact.index = param_count
        fact.type_id = receiver_type
        fact.effects = receiver_effects
        fact.flags = (mode as i32) |
            (if explicit_receiver: AnalysisDeclarationFlag.ExplicitReceiver as i32 else: 0) |
            (if type_params > 0: AnalysisDeclarationFlag.Generic as i32 else: 0) |
            (if receiver_proven: AnalysisDeclarationFlag.ReceiverProven as i32 else: 0) |
            (if in_impl: AnalysisDeclarationFlag.InImpl as i32 else: 0) |
            (if trait_impl: AnalysisDeclarationFlag.TraitImpl as i32 else: 0) |
            (if top_level_method: AnalysisDeclarationFlag.TopLevelMethod as i32 else: 0) |
            (if synthetic_receiver: AnalysisDeclarationFlag.SyntheticReceiver as i32 else: 0)
        fact.source_file = source_file
        fact.name = with_str_clone_ref(sema.pool_resolve(sym))
        fact.detail = "receiver=" ++ analysis_receiver_mode_name(mode) ++ " required=" ++ receiver_required_mode_text(fact.effects) ++ f" params={param_count} type-params={type_params} sig={sig} owner={owner} proven={receiver_proven} source-file={source_file} explicit-receiver={explicit_receiver} synthetic-receiver={synthetic_receiver} in-impl={in_impl} trait-impl={trait_impl} top-level-method={top_level_method}"
        fact = analysis_with_node_location(move fact, sema, node, decl_path, decl_source)
        report.add(move fact)

fn analysis_extension_registration_index(sema: &Sema, owner: i32, method: i32, fn_sym: i32, sig: i32) -> i32:
    let count = sema.extension_method_owner_syms.len() as i32
    for i in 0..count:
        if i >= sema.extension_method_syms.len() as i32 or i >= sema.extension_method_fn_syms.len() as i32 or i >= sema.extension_method_sig_idxs.len() as i32:
            return -1
        if sema.extension_method_owner_syms.get(i as i64) != owner or sema.extension_method_syms.get(i as i64) != method:
            continue
        if sema.extension_method_fn_syms.get(i as i64) != fn_sym:
            continue
        if sig >= 0 and sema.extension_method_sig_idxs.get(i as i64) != sig:
            continue
        return i
    -1

// Canonical declaration -> semantic method identity -> registry provenance.
// This is intentionally derived from live Sema tables, not source spelling, so
// it catches parser/collector/lookup drift before a method call reaches checking.
fn analysis_collect_method_registrations(report: &AnalysisReport, sema: &Sema, source_path: &str, source_text: &str):
    for di in 0..sema.ast.decl_count():
        let node = sema.ast.get_decl(di)
        if sema.ast.kind(node) != NodeKind.NK_FN_DECL:
            continue
        let parsed = sema.ast.get_data0(node)
        let owner = sema.method_decl_owner_symbol(node, parsed)
        let method = sema.method_decl_name_symbol(parsed)
        if owner == 0 or method == 0:
            continue
        let base = sema.method_decl_base_symbol(node, parsed)
        let effective = sema.fn_decl_semantic_symbol_at(node, parsed, di)
        let sig = sema.get_sig(effective)
        let impl_node = sema.impl_node_for_method_decl(node)
        let trait_impl = impl_node != 0 and sema.ast.get_data2(impl_node) != 0
        let extension = sema.method_decl_is_extension(node) != 0
        let generic = sema.generic_fn_nodes.contains(effective)
        let key = sema_pair_key(owner, method)
        var exact = false
        var registry = "missing"
        var registry_index = -1

        if extension:
            registry_index = analysis_extension_registration_index(sema, owner, method, effective, sig)
            exact = registry_index >= 0 and (not generic or sema.generic_fn_registration_contains(effective, node) != 0)
            registry = "extension"
        else if generic:
            exact = sema.generic_fn_registration_contains(effective, node) != 0
            registry = "generic"
        else:
            let mapped_sig = sema.method_lookup.sig_lookup.get(key)
            let mapped_fn = sema.method_lookup.fn_lookup.get(key)
            exact = sig >= 0 and mapped_sig.is_some() and mapped_sig.unwrap() == sig and mapped_fn.is_some() and mapped_fn.unwrap() == effective
            registry = "inherent"

        if impl_node != 0:
            let mapped_impl = sema.method_impl_nodes.get(effective)
            if mapped_impl.is_none() or mapped_impl.unwrap() != impl_node:
                exact = false
                registry = registry ++ "+impl-mismatch"
        if not extension and effective != base:
            exact = false
            registry = registry ++ "+identity-mismatch"

        var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.MethodRegistration)
        fact.id = di
        fact.parent = sig
        fact.node = node
        fact.symbol = effective
        fact.owner = owner
        fact.index = method
        fact.flags =
            (if extension: AnalysisMethodRegistrationFlag.Extension as i32 else: AnalysisMethodRegistrationFlag.Inherent as i32) |
            (if generic: AnalysisMethodRegistrationFlag.Generic as i32 else: 0) |
            (if trait_impl: AnalysisMethodRegistrationFlag.TraitImpl as i32 else: 0) |
            (if extension: AnalysisMethodRegistrationFlag.Scoped as i32 else: 0) |
            (if exact: AnalysisMethodRegistrationFlag.Exact as i32 else: AnalysisMethodRegistrationFlag.Missing as i32)
        fact.source_file = sema.decl_source_file_id_for_index(di)
        fact.name = with_str_clone_ref(sema.pool_resolve(base))
        fact.detail = f"owner={sema.pool_resolve(owner)} method={sema.pool_resolve(method)} effective={sema.pool_resolve(effective)} sig={sig} registry={registry} registry-index={registry_index} generic={generic} trait-impl={trait_impl} scoped-extension={extension} exact={exact}"
        let fact_path = analysis_decl_path(sema, di, source_path)
        let fact_source = analysis_decl_source(sema, di, source_text)
        fact = analysis_with_node_location(move fact, sema, node, fact_path, fact_source)
        report.add(move fact)

// Trait methods live in the trait declaration's compact extra-data table, not
// in AstPool.decls as independent FN_DECL nodes. Emit them explicitly so tools
// see the complete receiver surface, including associated/static contracts.
fn analysis_collect_trait_declarations(report: &AnalysisReport, sema: &Sema, source_path: &str, source_text: &str):
    for di in 0..sema.ast.decl_count():
        let trait_node = sema.ast.get_decl(di)
        if sema.ast.kind(trait_node) != NodeKind.NK_TRAIT_DECL: continue
        let trait_sym = sema.ast.get_data0(trait_node)
        let trait_name = sema.pool_resolve(trait_sym)
        let source_file = sema.decl_source_file_id_for_index(di)
        let path = analysis_decl_path(sema, di, source_path)
        let source = analysis_decl_source(sema, di, source_text)
        let method_count = sema.ast.trait_method_count(trait_node)
        var pos = sema.ast.trait_method_start(trait_node)
        for mi in 0..method_count:
            let method_sym = sema.ast.get_extra(pos + TRAIT_METHOD_NAME)
            let param_start = sema.ast.get_extra(pos + TRAIT_METHOD_PARAM_START)
            let param_count = sema.ast.get_extra(pos + TRAIT_METHOD_PARAM_COUNT)
            let method_start = sema.ast.get_extra(pos + TRAIT_METHOD_SOURCE_START)
            let method_end = sema.ast.get_extra(pos + TRAIT_METHOD_SOURCE_END)
            let mode = sema.receiver_mode_from_param(param_start, param_count)
            let receiver_type = if mode != ReceiverMode.None and param_count > 0: sema.ast.fn_param_type(param_start, 0) else: 0
            let receiver_flags = if mode != ReceiverMode.None and param_count > 0: sema.ast.fn_param_flags(param_start, 0) else: 0
            let synthetic_receiver = fn_param_is_synth_receiver(receiver_flags) != 0
            let explicit_receiver = mode != ReceiverMode.None and not synthetic_receiver
            var effects = 0
            if mode == ReceiverMode.Read: effects = EFF_READ
            else if mode == ReceiverMode.Mut: effects = EFF_READ | EFF_WRITE
            else if mode == ReceiverMode.Move: effects = EFF_READ | EFF_CONSUME
            var fact = AnalysisFact.new(AnalysisStage.Ast, AnalysisFactKind.Declaration)
            fact.id = pos
            fact.parent = trait_node
            fact.node = trait_node
            fact.symbol = method_sym
            fact.owner = trait_sym
            fact.index = param_count
            fact.type_id = receiver_type
            fact.effects = effects
            fact.flags = (mode as i32) |
                (if explicit_receiver: AnalysisDeclarationFlag.ExplicitReceiver as i32 else: 0) |
                (if mode != ReceiverMode.None and mode != ReceiverMode.Missing: AnalysisDeclarationFlag.ReceiverProven as i32 else: 0) |
                (if synthetic_receiver: AnalysisDeclarationFlag.SyntheticReceiver as i32 else: 0) |
                AnalysisDeclarationFlag.TraitDeclaration as i32
            fact.source_file = source_file
            fact.start = method_start
            fact.end = method_end
            fact.line = analysis_line_for_offset(source, method_start)
            fact.column = analysis_column_for_offset(source, method_start)
            fact.path = with_str_clone_ref(path)
            fact.name = trait_name ++ "." ++ sema.pool_resolve(method_sym)
            fact.detail = "trait declaration receiver=" ++ analysis_receiver_mode_name(mode) ++ f" params={param_count} explicit-receiver={explicit_receiver} synthetic-receiver={synthetic_receiver} source-file={source_file}"
            report.add(move fact)
            pos = pos + TRAIT_METHOD_STRIDE

fn analysis_collect_types(report: &AnalysisReport, sema: &Sema):
    let type_count = sema.type_kinds.len() as i32
    for tid in 0..type_count:
        let kind = sema.get_type_kind(tid as TypeId)
        let d0 = sema.get_type_d0(tid as TypeId)
        let d1 = sema.get_type_d1(tid as TypeId)
        let d2 = sema.get_type_d2(tid as TypeId)
        let type_name = sema.type_name(tid)
        var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Type)
        fact.id = tid
        fact.index = kind
        fact.symbol = if kind == TypeKind.TY_STRUCT or kind == TypeKind.TY_ENUM or kind == TypeKind.TY_ALIAS: d0 else: 0
        fact.name = with_str_clone_ref(type_name)
        fact.detail = f"kind={kind} d0={d0} d1={d1} d2={d2}"
        report.add(move fact)

        if kind != TypeKind.TY_STRUCT:
            continue
        let field_start = d1
        let field_count = d2
        if field_start < 0 or field_count < 0 or field_start + field_count * 3 > sema.type_extra.len() as i32:
            var invalid = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Invariant)
            invalid.id = tid
            invalid.name = type_name ++ ".fields"
            invalid.detail = f"invalid struct field table start={field_start} count={field_count} extra={sema.type_extra.len() as i32}"
            report.add(move invalid)
            continue
        for fi in 0..field_count:
            let base = field_start + fi * 3
            let field_sym = sema.type_extra.get(base as i64)
            let field_ty = sema.type_extra.get((base + 1) as i64)
            let default_node = sema.type_extra.get((base + 2) as i64)
            var field = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Field)
            field.id = base
            field.parent = tid
            field.symbol = field_sym
            field.index = fi
            field.type_id = field_ty
            field.name = type_name ++ "." ++ sema.pool_resolve(field_sym)
            field.detail = "owner=" ++ type_name ++ " field-type=" ++ sema.type_name(field_ty) ++ f" default-node={default_node}"
            report.add(move field)

fn analysis_collect_expressions(report: &AnalysisReport, sema: &Sema):
    for node in 1..sema.ast.node_count():
        if not sema.typed_expr_types.contains(node):
            continue
        let tid = sema.typed_expr_types.get(node).unwrap()
        var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Expression)
        fact.id = node
        fact.node = node
        fact.index = sema.ast.kind(node)
        fact.type_id = tid
        fact.name = f"node:{node}"
        fact.detail = f"node-kind={fact.index} type-name={sema.type_name(tid)} start={sema.ast.get_start(node)} end={sema.ast.get_end(node)}"
        report.add(move fact)

fn analysis_parse_node_id(text: &str) -> i32:
    if text.len() == 0:
        return -1
    var value = 0
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64) as i32
        if ch < 48 or ch > 57:
            return -1
        value = value * 10 + ch - 48
    value

fn analysis_ast_node_kind_name(kind: i32) -> str:
    if kind == NodeKind.NK_IDENT: return "ident"
    if kind == NodeKind.NK_FIELD_ACCESS: return "field-access"
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS: return "computed-field-access"
    if kind == NodeKind.NK_CALL: return "call"
    if kind == NodeKind.NK_BINARY: return "binary"
    if kind == NodeKind.NK_UNARY: return "unary"
    if kind == NodeKind.NK_ASSIGN: return "assign"
    if kind == NodeKind.NK_INDEX: return "index"
    if kind == NodeKind.NK_GROUPED: return "grouped"
    if kind == NodeKind.NK_CAST: return "cast"
    if kind == NodeKind.NK_OPTIONAL_CHAIN: return "optional-chain"
    if kind == NodeKind.NK_TYPE_NAMED: return "type-named"
    if kind == NodeKind.NK_TYPE_GENERIC: return "type-generic"
    if kind == NodeKind.NK_TYPE_REF: return "type-ref"
    if kind == NodeKind.NK_TYPE_PTR: return "type-ptr"
    if kind == NodeKind.NK_TYPE_TYPEOF: return "type-typeof"
    if kind == NodeKind.NK_FN_DECL: return "fn-decl"
    if kind == NodeKind.NK_INTERFACE_BODY: return "interface-body"
    if kind == NodeKind.NK_INTERFACE_PROVIDED: return "interface-provided"
    if kind == NodeKind.NK_TYPE_DECL: return "type-decl"
    if kind == NodeKind.NK_LET_BINDING: return "let-binding"
    if kind == NodeKind.NK_BLOCK: return "block"
    if kind == NodeKind.NK_RETURN: return "return"
    f"node-kind-{kind}"

fn analysis_ast_child_count(sema: &Sema, node: i32) -> i32:
    let kind = sema.ast.kind(node)
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_TYPEOF:
        return 1
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_BINARY or kind == NodeKind.NK_ASSIGN or kind == NodeKind.NK_CAST:
        return 2
    if kind == NodeKind.NK_UNARY:
        return 1
    if kind == NodeKind.NK_INDEX:
        return if sema.ast.get_data2(node) != 0: 3 else: 2
    if kind == NodeKind.NK_CALL:
        return 1 + sema.ast.get_data2(node)
    0

fn analysis_ast_child(sema: &Sema, node: i32, child_index: i32) -> i32:
    let kind = sema.ast.kind(node)
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_TYPEOF:
        return sema.ast.get_data0(node)
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_ASSIGN or kind == NodeKind.NK_CAST:
        return if child_index == 0: sema.ast.get_data0(node) else: sema.ast.get_data1(node)
    if kind == NodeKind.NK_BINARY:
        return if child_index == 0: sema.ast.get_data1(node) else: sema.ast.get_data2(node)
    if kind == NodeKind.NK_UNARY:
        return sema.ast.get_data1(node)
    if kind == NodeKind.NK_INDEX:
        if child_index == 0: return sema.ast.get_data0(node)
        if child_index == 1: return sema.ast.get_data1(node)
        return sema.ast.get_data2(node)
    if kind == NodeKind.NK_CALL:
        if child_index == 0:
            return sema.ast.get_data0(node)
        let extra = sema.ast.get_data1(node) + child_index - 1
        if extra >= 0 and extra < sema.ast.extra_len():
            return sema.ast.get_extra(extra)
    0

fn analysis_ast_child_role(sema: &Sema, node: i32, child_index: i32) -> str:
    let kind = sema.ast.kind(node)
    if kind == NodeKind.NK_FIELD_ACCESS: return "base"
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS: return if child_index == 0: "base" else: "field"
    if kind == NodeKind.NK_CALL: return if child_index == 0: "callee" else: f"arg[{child_index - 1}]"
    if kind == NodeKind.NK_BINARY: return if child_index == 0: "lhs" else: "rhs"
    if kind == NodeKind.NK_UNARY: return "operand"
    if kind == NodeKind.NK_ASSIGN: return if child_index == 0: "target" else: "value"
    if kind == NodeKind.NK_INDEX: return if child_index == 0: "base" else if child_index == 1: "index[0]" else: "index[1]"
    if kind == NodeKind.NK_CAST: return if child_index == 0: "value" else: "target-type"
    if kind == NodeKind.NK_GROUPED: return "inner"
    if kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_PTR: return "pointee"
    if kind == NodeKind.NK_TYPE_TYPEOF: return "expression"
    f"child[{child_index}]"

fn analysis_node_subject(sema: &Sema, node: i32, fallback_path: &str, fallback_source: &str) -> Vec[str]:
    let result: Vec[str] = Vec.new()
    var path = fallback_path
    var source = with_str_clone_ref(fallback_source)
    for i in 0..sema.diags.items.len() as i32:
        let diag = &sema.diags.items[i as i64]
        if diag.origin_node != node:
            continue
        let exact_source = sema.source_text_for_file_id(diag.primary.file)
        if exact_source.len() > 0:
            source = exact_source
        for si in 0..sema.source_text_file_ids.len() as i32:
            if sema.source_text_file_ids.get(si as i64) == diag.primary.file:
                path = sema.source_text_names.get(si as i64)
                break
        break
    result.push(with_str_clone_ref(path))
    result.push(source)
    result

fn analysis_collect_ast_node_tree(report: &AnalysisReport, sema: &Sema, node: i32, parent: i32, role: &str, depth: i32, source_path: &str, source_text: &str):
    if node <= 0 or node >= sema.ast.node_count():
        report.fail(f"AST node {node} is outside 1..{sema.ast.node_count() - 1}")
        return
    let kind = sema.ast.kind(node)
    let d0 = sema.ast.get_data0(node)
    let d1 = sema.ast.get_data1(node)
    let d2 = sema.ast.get_data2(node)
    let typed = sema.typed_expr_types.get(node)
    let resolved = sema.comp_resolved.get(node)
    var symbol = 0
    if kind == NodeKind.NK_IDENT or kind == NodeKind.NK_TYPE_NAMED:
        symbol = d0
    else if kind == NodeKind.NK_FIELD_ACCESS:
        symbol = d1
    else if resolved.is_some():
        symbol = resolved.unwrap()
    let subject = analysis_node_subject(sema, node, source_path, source_text)
    let path = subject.get(0)
    let source = subject.get(1)
    var fact = AnalysisFact.new(AnalysisStage.Ast, AnalysisFactKind.AstNode)
    fact.id = node
    fact.parent = parent
    fact.node = node
    fact.symbol = symbol
    fact.index = kind
    fact.type_id = if typed.is_some(): typed.unwrap() else: 0
    fact.flags = depth
    fact.name = f"node:{node}"
    let symbol_name = if symbol != 0: with_str_clone_ref(sema.pool_resolve(symbol)) else: ""
    let type_name = if typed.is_some(): sema.type_name(typed.unwrap()) else: "<untyped>"
    fact.detail = f"role={role} kind={analysis_ast_node_kind_name(kind)} raw=[{d0},{d1},{d2}] type={type_name} resolved={if resolved.is_some(): resolved.unwrap() else: 0} symbol={symbol_name} start={sema.ast.get_start(node)} end={sema.ast.get_end(node)}"
    fact = analysis_with_node_location(move fact, sema, node, path, source)
    report.add(move fact)
    if depth <= 0:
        return
    for ci in 0..analysis_ast_child_count(sema, node):
        let child = analysis_ast_child(sema, node, ci)
        if child <= 0 or child >= sema.ast.node_count():
            var invalid = AnalysisFact.new(AnalysisStage.Ast, AnalysisFactKind.Invariant)
            invalid.id = node
            invalid.parent = node
            invalid.index = ci
            invalid.name = f"node:{node}"
            invalid.detail = f"invalid structural child role={analysis_ast_child_role(sema, node, ci)} child={child}"
            report.add(move invalid)
            continue
        analysis_collect_ast_node_tree(report, sema, child, node, analysis_ast_child_role(sema, node, ci), depth - 1, path, source)

fn analysis_collect_requested_node(report: &AnalysisReport, sema: &Sema, request: &str, source_path: &str, source_text: &str):
    if not request.starts_with("explain:node:"):
        return
    let node = analysis_parse_node_id(analysis_slice(request, 13, request.len() as i32))
    if node < 0:
        report.fail("explain:node requires a non-negative AST node id")
        return
    analysis_collect_ast_node_tree(report, sema, node, -1, "root", 4, source_path, source_text)

fn analysis_collect_signatures(report: &AnalysisReport, sema: &Sema, source_path: &str):
    for si in 0..sema.sig_names.len() as i32:
        let sym = sema.sig_names.get(si as i64)
        let name = sema.pool_resolve(sym)
        var sig = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Signature)
        sig.id = si
        sig.symbol = sym
        sig.type_id = sema.sig_ret_types.get(si as i64)
        sig.index = sema.sig_get_param_count(si)
        sig.flags = if sema.sig_variadic.get(si as i64) != 0: 1 else: 0
        sig.path = analysis_sig_path(sema, sym, source_path)
        sig.name = with_str_clone_ref(name)
        sig.detail = f"params={sig.index} return={sig.type_id} variadic={sig.flags}"
        report.add(sig.owned_copy())

        for pi in 0..sema.sig_get_param_count(si):
            var param = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Parameter)
            param.id = sema.sig_param_eff_starts.get(si as i64) + pi
            param.parent = si
            param.symbol = sym
            param.index = pi
            param.type_id = sema.sig_param_type(si, pi)
            param.effects = sema.sig_param_effect(si, pi)
            param.flags = if sema.sig_param_uses_value_ref_abi(si, pi) != 0: 1 else: 0
            param.path = with_str_clone_ref(sig.path)
            param.name = with_str_clone_ref(name)
            param.detail = analysis_param_class(sema, si, pi) ++ f" direct={sema.sig_param_direct_effect(si, pi)} final={param.effects} value-ref={param.flags}"
            report.add(param.owned_copy())

            var abi = move param
            abi.stage = AnalysisStage.Abi
            report.add(move abi)
        let receiver = sema.sig_receiver_mode(si)
        if receiver != ReceiverMode.None:
            var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Receiver)
            fact.id = si
            fact.parent = si
            fact.symbol = sym
            fact.index = 0
            fact.type_id = if sema.sig_get_param_count(si) > 0: sema.sig_param_type(si, 0) else: 0
            fact.effects = if si < sema.sig_receiver_required_effects.len() as i32: sema.sig_receiver_required_effects.get(si as i64) else: 0
            fact.flags = receiver as i32
            fact.path = with_str_clone_ref(sig.path)
            fact.name = with_str_clone_ref(name)
            fact.detail = "declared=" ++ analysis_receiver_mode_name(receiver) ++ " required=" ++ receiver_required_mode_text(fact.effects)
            report.add(move fact)

fn analysis_collect_effect_edges(report: &AnalysisReport, sema: &Sema):
    var at = 0
    var edge = 0
    while at + 3 < sema.effect_flow_edges.len() as i32:
        let caller_sig = sema.effect_flow_edges.get(at as i64)
        let caller_pi = sema.effect_flow_edges.get((at + 1) as i64)
        let callee_sig = sema.effect_flow_edges.get((at + 2) as i64)
        let callee_pi = sema.effect_flow_edges.get((at + 3) as i64)
        let projection = if edge < sema.effect_flow_projections.len() as i32: sema.effect_flow_projections.get(edge as i64) else: -1
        var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.EffectEdge)
        fact.id = edge
        fact.parent = caller_sig
        fact.symbol = if callee_sig >= 0 and callee_sig < sema.sig_names.len() as i32: sema.sig_names.get(callee_sig as i64) else: 0
        fact.index = caller_pi
        fact.type_id = callee_pi
        fact.effects = if callee_sig >= 0: sema.sig_param_effect(callee_sig, callee_pi) else: 0
        fact.flags = projection
        let caller = if caller_sig >= 0 and caller_sig < sema.sig_names.len() as i32: with_str_clone_ref(sema.pool_resolve(sema.sig_names.get(caller_sig as i64))) else: "<invalid>"
        let callee = if callee_sig >= 0 and callee_sig < sema.sig_names.len() as i32: with_str_clone_ref(sema.pool_resolve(sema.sig_names.get(callee_sig as i64))) else: "<invalid>"
        fact.name = caller
        fact.detail = f"param[{caller_pi}] -> {callee} param[{callee_pi}] projection={projection}"
        report.add(move fact)
        at = at + 4
        edge = edge + 1

fn analysis_collect_specializations(report: &AnalysisReport, sema: &Sema, source_path: &str):
    for si in 0..sema.concrete_specialization_nodes.len() as i32:
        let node = sema.concrete_specialization_nodes.get(si as i64)
        let mono = sema.concrete_specialization_syms.get(si as i64)
        let sig = sema.concrete_specialization_sigs.get(si as i64)
        let subst_start = sema.concrete_specialization_subst_starts.get(si as i64)
        let subst_count = sema.concrete_specialization_subst_counts.get(si as i64)
        let parts: Vec[str] = Vec.new()
        for ti in 0..subst_count:
            if ti > 0: parts.push(", ")
            let param = sema.concrete_specialization_subst_syms.get((subst_start + ti) as i64)
            let ty = sema.concrete_specialization_subst_types.get((subst_start + ti) as i64)
            parts.push(with_str_clone_ref(sema.pool_resolve(param)))
            parts.push("=ty")
            parts.push(f"{ty}")
        var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Specialization)
        fact.id = si
        fact.parent = sig
        fact.node = node
        fact.symbol = mono
        fact.index = subst_count
        fact.path = analysis_sig_path(sema, mono, source_path)
        fact.name = with_str_clone_ref(sema.pool_resolve(mono))
        fact.detail = parts.join("")
        report.add(move fact)

fn analysis_collect_resolved_calls(report: &AnalysisReport, sema: &Sema, source_path: &str, source_text: &str):
    for node in 1..sema.ast.node_count():
        let sig_opt = sema.resolved_call_sigs.get(node)
        if sig_opt.is_none():
            continue
        let sig = sig_opt.unwrap()
        let mono_opt = sema.resolved_call_mono_syms.get(node)
        let mono = if mono_opt.is_some(): mono_opt.unwrap() else if sig >= 0 and sig < sema.sig_names.len() as i32: sema.sig_names.get(sig as i64) else: 0
        var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Call)
        fact.id = node
        fact.parent = sig
        fact.symbol = mono
        fact.index = if sema.has_resolved_call_args(node) != 0: sema.get_resolved_call_arg_count(node) else: sema.ast.get_data2(node)
        fact.name = if mono != 0: with_str_clone_ref(sema.pool_resolve(mono)) else: "<unresolved>"
        fact.detail = f"resolved-call sig={sig} mono={mono} args={fact.index}"
        fact = analysis_with_node_location(move fact, sema, node, source_path, source_text)
        report.add(move fact)

// Tool Gap #2 — production method-resolution decisions, one fact per checked
// method call: receiver type, owner, method, inherent-vs-extension source,
// candidate/visibility counts, and the selected signature/function. The
// verdict text names the rejection reason for misses so lookup failures are
// diagnosable without re-deriving resolution from source.
fn analysis_collect_method_resolutions(report: &AnalysisReport, sema: &Sema, source_path: &str, source_text: &str):
    for i in 0..sema.mres_nodes.len() as i32:
        let owner = sema.mres_owner_syms.get(i as i64)
        let method = sema.mres_method_syms.get(i as i64)
        let sig = sema.mres_sigs.get(i as i64)
        let fn_sym = sema.mres_fn_syms.get(i as i64)
        let flags = sema.mres_flags.get(i as i64)
        let total = sema.mres_cands_total.get(i as i64)
        let visible = sema.mres_cands_visible.get(i as i64)
        let inherent = (flags & 1) != 0
        let via_extension = (flags & 2) != 0
        // The recorder captured the direct owner-registry probe; builtin,
        // generic, and trait-routed methods resolve later. Join against the
        // final resolved-call sidecar so the verdict reflects the selection
        // the program actually got, and keep the probe fields as the
        // inherent/extension diagnostics.
        let mres_node = sema.mres_nodes.get(i as i64)
        let final_sig_opt = sema.resolved_call_sigs.get(mres_node)
        let final_sig = if final_sig_opt.is_some(): final_sig_opt.unwrap() else: sig
        let final_mono_opt = sema.resolved_call_mono_syms.get(mres_node)
        let final_mono = if final_mono_opt.is_some(): final_mono_opt.unwrap() else: fn_sym
        let verdict = if sig >= 0:
            if inherent: "inherent" else: "extension"
        else if final_sig >= 0:
            "late-resolved"
        else if (flags & 4) != 0:
            "ambiguous-extensions"
        else if (flags & 8) != 0:
            "candidates-not-visible"
        else:
            // The compile succeeded, so a miss in both the registry probe and
            // the resolved-call sidecar means the method resolved through a
            // surface outside the signature registry (builtin containers,
            // trait dispatch, deref chains, language machinery like
            // scope.track) — not an unknown method.
            "outside-registry"
        var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.MethodResolution)
        fact.id = i
        fact.parent = final_sig
        fact.node = mres_node
        fact.symbol = method
        fact.owner = owner
        fact.index = if final_mono != 0: final_mono else: fn_sym
        fact.type_id = sema.mres_recv_types.get(i as i64)
        fact.flags = flags
        fact.name = sema.pool_resolve(owner) ++ "." ++ sema.pool_resolve(method)
        fact.detail = f"sig={final_sig} fn={fact.index} verdict={verdict} probe-sig={sig} inherent={inherent} via-extension={via_extension} candidates={total} visible={visible} recv-type={fact.type_id}"
        fact = analysis_with_node_location(move fact, sema, mres_node, source_path, source_text)
        report.add(move fact)

fn analysis_collect_diagnostics(report: &AnalysisReport, sema: &Sema):
    for i in 0..sema.diags.items.len() as i32:
        let diag = &sema.diags.items[i as i64]
        var fact = AnalysisFact.new(AnalysisStage.Diagnostic, AnalysisFactKind.Diagnostic)
        fact.id = i
        fact.node = diag.origin_node
        fact.flags = diag.severity
        fact.source_file = diag.primary.file
        fact.start = diag.primary.start
        fact.end = diag.primary.end
        fact.name = if diag.code.len() > 0: diag.code else: diag.message
        var subject = ""
        for si in 0..sema.source_text_file_ids.len() as i32:
            if sema.source_text_file_ids.get(si as i64) == diag.primary.file:
                subject = with_str_clone_ref(sema.source_text_names.get(si as i64))
                break
        if subject.len() == 0:
            for di in 0..sema.decl_source_file_ids.len() as i32:
                if sema.decl_source_file_ids.get(di as i64) == diag.primary.file:
                subject = sema.decl_source_path_for_index(di)
                break
        let subject_source = sema.source_text_for_file_id(diag.primary.file)
        if subject_source.len() > 0:
            fact.line = analysis_line_for_offset(subject_source, diag.primary.start)
            fact.column = analysis_column_for_offset(subject_source, diag.primary.start)
        fact.path = if subject.len() > 0: subject else: diag.origin_file
        fact.detail = diag.origin_fn ++ ": " ++ diag.message ++ f" subject-file={diag.primary.file}"
        report.add(move fact)

fn analysis_collect_phase(report: &AnalysisReport, sema: &Sema):
    var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Phase)
    fact.id = 0
    fact.flags = (if sema.symbols_frozen != 0: 1 else: 0) | (if sema.types_frozen != 0: 2 else: 0)
    fact.index = sema.type_kinds.len() as i32
    fact.name = "sema-freeze"
    fact.detail = f"symbols={sema.symbols_frozen} types={sema.types_frozen} type-count={fact.index}"
    report.add(move fact)

fn analysis_collect_sema(report: &AnalysisReport, sema: &Sema, source_path: &str, source_text: &str):
    analysis_collect_phase(report, sema)
    analysis_collect_declarations(report, sema, source_path, source_text)
    analysis_collect_method_registrations(report, sema, source_path, source_text)
    analysis_collect_trait_declarations(report, sema, source_path, source_text)
    analysis_collect_types(report, sema)
    analysis_collect_expressions(report, sema)
    analysis_collect_signatures(report, sema, source_path)
    analysis_collect_effect_edges(report, sema)
    analysis_collect_specializations(report, sema, source_path)
    analysis_collect_resolved_calls(report, sema, source_path, source_text)
    analysis_collect_method_resolutions(report, sema, source_path, source_text)
    analysis_collect_diagnostics(report, sema)

fn analysis_operand_kind_name(kind: i32) -> str:
    if kind == OperandKind.OK_COPY: return "copy"
    if kind == OperandKind.OK_MOVE: return "move"
    if kind == OperandKind.OK_CONSTANT: return "constant"
    f"unknown({kind})"

fn analysis_source_for_path(sema: &Sema, path: &str, fallback: &str) -> str:
    for i in 0..sema.source_text_names.len() as i32:
        if sema.source_text_names.get(i as i64) == path: return with_str_clone_ref(sema.source_texts.get(i as i64))
    with_str_clone_ref(fallback)

fn analysis_call_receiver_node(sema: &Sema, call_node: i32) -> i32:
    if call_node <= 0 or call_node >= sema.ast.node_count() or sema.ast.kind(call_node) != NodeKind.NK_CALL: return 0
    let callee = sema.ast.get_data0(call_node)
    if callee <= 0 or callee >= sema.ast.node_count(): return 0
    let kind = sema.ast.kind(callee)
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS: return sema.ast.get_data0(callee)
    0

fn analysis_call_argument_node(sema: &Sema, call_node: i32, arg_index: i32, mir_count: i32) -> i32:
    if call_node <= 0 or call_node >= sema.ast.node_count() or sema.ast.kind(call_node) != NodeKind.NK_CALL: return 0
    let resolved = sema.has_resolved_call_args(call_node) != 0
    let source_count = if resolved: sema.get_resolved_call_arg_count(call_node) else: sema.ast.get_data2(call_node)
    let receiver_offset = if source_count + 1 == mir_count: 1 else: 0
    if receiver_offset == 1 and arg_index == 0: return analysis_call_receiver_node(sema, call_node)
    let source_index = arg_index - receiver_offset
    if source_index < 0 or source_index >= source_count: return 0
    if resolved: return sema.get_resolved_call_arg(call_node, source_index)
    sema.ast.get_extra(sema.ast.get_data1(call_node) + source_index)

fn analysis_collect_mir_call(report: &AnalysisReport, mir_mod: &MirModule, body: &MirBody, sema: &Sema, pool: &InternPool, call_id: i32, source_path: &str, source_text: &str):
    let sig = body.call_sig_index(call_id)
    let mono = body.call_mono_sym(call_id)
    let start = body.call_arg_starts.get(call_id as i64)
    let count = body.call_arg_counts.get(call_id as i64)
    let intrinsic = body.call_intrinsic(call_id)
    let required = body.call_requires_contract(call_id)
    let name = if mono != 0: with_str_clone_ref(pool.resolve(mono)) else if sig >= 0 and sig < sema.sig_names.len() as i32: with_str_clone_ref(sema.pool_resolve(sema.sig_names.get(sig as i64))) else: "<unresolved>"
    var call = AnalysisFact.new(AnalysisStage.Mir, AnalysisFactKind.Call)
    call.id = call_id
    call.parent = sig
    call.node = body.call_ast_node(call_id)
    call.body_sym = body.fn_sym
    call.symbol = mono
    call.index = count
    call.flags = (if required: 1 else: 0) | ((intrinsic as i32) << 8)
    call.name = with_str_clone_ref(name)
    call.detail = f"sig={sig} mono={mono} args={count} required={required} intrinsic={intrinsic as i32}"
    let caller_path = analysis_sig_path(sema, body.fn_sym, source_path)
    let caller_source = analysis_source_for_path(sema, caller_path, source_text)
    let call_node = call.node
    call = analysis_with_node_location(move call, sema, call_node, caller_path, caller_source)
    report.add(call.owned_copy())
    for ai in 0..count:
        let operand = body.call_arg_operands.get((start + ai) as i64)
        let kind = if operand >= 0 and operand < body.operand_kinds.len() as i32: body.operand_kinds.get(operand as i64) else: -1
        let share = sig >= 0 and ai < sema.sig_get_param_count(sig) and sema.sig_param_uses_value_ref_abi(sig, ai) != 0
        var arg = AnalysisFact.new(AnalysisStage.Mir, AnalysisFactKind.CallArgument)
        arg.id = operand
        arg.parent = call_id
        arg.node = analysis_call_argument_node(sema, call.node, ai, count)
        arg.body_sym = body.fn_sym
        arg.symbol = mono
        arg.index = ai
        arg.type_id = mir_validate_operand_type(mir_mod, body, operand)
        arg.effects = if sig >= 0 and ai < sema.sig_get_param_count(sig): sema.sig_param_effect(sig, ai) else: 0
        arg.flags = (kind & 255) | (if share: 256 else: 0)
        arg.name = with_str_clone_ref(name)
        arg.detail = analysis_operand_kind_name(kind) ++ " " ++ mir_operand_text(body, operand, pool, sema) ++ if share: " -> share-place" else: ""
        let arg_node = arg.node
        arg = analysis_with_node_location(move arg, sema, arg_node, caller_path, caller_source)
        report.add(move arg)

fn analysis_collect_mir(report: &AnalysisReport, mir_mod: &MirModule, sema: &Sema, pool: &InternPool, source_path: &str, source_text: &str):
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi as i64]
        var body_fact = AnalysisFact.new(AnalysisStage.Mir, AnalysisFactKind.Body)
        body_fact.id = bi
        body_fact.body_sym = body.fn_sym
        body_fact.symbol = body.fn_sym
        body_fact.index = body.block_count()
        body_fact.name = with_str_clone_ref(pool.resolve(body.fn_sym))
        body_fact.detail = f"locals={body.local_count()} blocks={body.block_count()} calls={body.call_arg_starts.len() as i32} failed={body.lowering_failed}"
        report.add(body_fact.owned_copy())
        for li in 0..body.local_count():
            var local = AnalysisFact.new(AnalysisStage.Mir, AnalysisFactKind.Local)
            local.id = li
            local.parent = bi
            local.body_sym = body.fn_sym
            local.symbol = body.local_names.get(li as i64)
            local.index = li
            local.type_id = body.local_type_ids.get(li as i64)
            local.flags = body.local_mutables.get(li as i64) | (body.local_is_user_var.get(li as i64) << 1)
            local.name = with_str_clone_ref(body_fact.name)
            local.detail = f"_{li} ty={local.type_id} mut={body.local_mutables.get(li as i64)}"
            report.add(move local)
        for pi in 0..body.place_locals.len() as i32:
            var place = AnalysisFact.new(AnalysisStage.Mir, AnalysisFactKind.Place)
            place.id = pi
            place.parent = body.place_locals.get(pi as i64)
            place.body_sym = body.fn_sym
            place.index = body.place_proj_counts.get(pi as i64)
            place.type_id = body.place_sema_types.get(pi as i64)
            place.name = with_str_clone_ref(body_fact.name)
            place.detail = mir_place_text(body, pi)
            report.add(move place)
        for ci in 0..body.call_arg_starts.len() as i32:
            analysis_collect_mir_call(report, mir_mod, body, sema, pool, ci, source_path, source_text)

fn analysis_audit_call_contracts(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule):
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi as i64]
        let calls = body.call_arg_starts.len() as i32
        if body.call_arg_counts.len() as i32 != calls or body.call_intrinsic_kinds.len() as i32 != calls or body.call_ast_nodes.len() as i32 != calls or body.call_sig_indices.len() as i32 != calls or body.call_mono_syms.len() as i32 != calls or body.call_contract_required.len() as i32 != calls or body.call_pipeline_receiver_places.len() as i32 != calls:
            report.fail(f"body {body.fn_sym}: MIR call tables are not parallel")
            continue
        for ci in 0..calls:
            let sig = body.call_sig_index(ci)
            let mono = body.call_mono_sym(ci)
            let required = body.call_requires_contract(ci)
            let argc = body.call_arg_counts.get(ci as i64)
            if required and (sig < 0 or sig >= sema.sig_names.len() as i32 or mono == 0):
                report.fail(f"body {body.fn_sym} call {ci}: required concrete contract is incomplete sig={sig} mono={mono}")
                continue
            if sig < 0:
                continue
            if sig >= sema.sig_names.len() as i32:
                report.fail(f"body {body.fn_sym} call {ci}: signature {sig} is out of range")
                continue
            if mono != 0 and sema.sig_names.get(sig as i64) != mono:
                report.fail(f"body {body.fn_sym} call {ci}: signature/symbol mismatch sig={sig} mono={mono}")
            let params = sema.sig_get_param_count(sig)
            if argc != params and sema.sig_variadic.get(sig as i64) == 0:
                report.fail(f"body {body.fn_sym} call {ci}: argument/signature mismatch args={argc} params={params}")
            let start = body.call_arg_starts.get(ci as i64)
            for ai in 0..argc:
                let operand = body.call_arg_operands.get((start + ai) as i64)
                let ty = mir_validate_operand_type(mir_mod, body, operand)
                if ty == 0:
                    report.fail(f"body {body.fn_sym} call {ci} arg {ai}: operand has no concrete MIR type")
        
fn analysis_audit_effects(report: &AnalysisReport, sema: &Sema):
    if sema.sig_param_effects.len() as i32 != sema.sig_param_direct_effects.len() as i32:
        report.fail("effect tables are not parallel")
    for si in 0..sema.sig_names.len() as i32:
        let count = sema.sig_get_param_count(si)
        let mode = sema.sig_receiver_mode(si)
        if mode == ReceiverMode.None or count == 0:
            continue
        let required = sema.sig_param_effect(si, 0) & EFF_DECLARED_MASK
        if si >= sema.sig_receiver_required_effects.len() as i32 or sema.sig_receiver_required_effects.get(si as i64) != required:
            report.fail(f"sig {si}: receiver requirement is not the finalized param[0] effect")
        if mode == ReceiverMode.Missing:
            report.fail(f"sig {si}: receiver mode is missing")
        else if mode == ReceiverMode.Read and (required & (EFF_WRITE | EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0:
            report.fail(f"sig {si}: read receiver requires {receiver_required_mode_text(required)}")
        else if mode == ReceiverMode.Mut and (required & (EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0:
            report.fail(f"sig {si}: mut receiver requires move")
    var at = 0
    var edge_index = 0
    while at + 3 < sema.effect_flow_edges.len() as i32:
        let caller_sig = sema.effect_flow_edges.get(at as i64)
        let caller_pi = sema.effect_flow_edges.get((at + 1) as i64)
        let callee_sig = sema.effect_flow_edges.get((at + 2) as i64)
        let callee_pi = sema.effect_flow_edges.get((at + 3) as i64)
        let projection = sema.effect_edge_projection(edge_index)
        at = at + 4
        edge_index = edge_index + 1
        if caller_sig < 0 or callee_sig < 0 or caller_pi < 0 or callee_pi < 0:
            report.fail("effect edge contains a negative signature or parameter")
            continue
        let caller_ty = sema.sig_param_type(caller_sig, caller_pi)
        let caller_kind = if caller_ty > 0: sema.get_type_kind(sema.resolve_alias(caller_ty as TypeId)) else: TypeKind.TY_ERR
        if caller_kind == TypeKind.TY_REF or caller_kind == TypeKind.TY_PTR:
            continue
        // #927: the same transfer the fixpoint applies — projection edges demote
        // consume/escape to write (D17) — so the audit checks the rule, not a
        // stronger restatement of it.
        let callee_ty = sema.sig_param_type(callee_sig, callee_pi)
        let callee_is_copy = if callee_ty > 0: sema.is_copy_frozen(callee_ty as TypeId) else: 1
        let propagated = sema.effect_edge_transfer(callee_sig, callee_pi, projection, callee_is_copy)
        let caller = sema.sig_param_effect(caller_sig, caller_pi)
        if (caller & propagated) != propagated:
            report.fail(f"effect edge sig {caller_sig}:{caller_pi} -> {callee_sig}:{callee_pi} is not at fixpoint; missing={propagated & ~caller}")

// audit:pool — structural integrity of the parser/pool tier: parallel SoA
// columns, stride tables, map/vec mirrors, and the cross-module positional
// seams (#660/#661/#664 class). The census found ~57 parallel families with
// 3 guarded; this guards the highest-risk ones generically.
fn analysis_audit_pool(report: &AnalysisReport, sema: &Sema):
    let ast = sema.ast
    let n = ast.node_count() as i64
    if ast.state.starts.len() != n or ast.state.ends.len() != n or ast.state.data0.len() != n or ast.state.data1.len() != n or ast.state.data2.len() != n or ast.state.files.len() != n:
        report.fail("pool: node SoA columns diverge from kinds length")
    if ast.state.fn_meta.len() as i32 % 7 != 0:
        report.fail("pool: fn_meta stride (7) broken")
    if ast.state.for_meta.len() as i32 % 3 != 0:
        report.fail("pool: for_meta stride (3) broken")
    if ast.state.type_meta.len() as i32 % 3 != 0:
        report.fail("pool: type_meta stride (3) broken")
    if ast.state.block_meta.len() as i32 % 2 != 0:
        report.fail("pool: block_meta stride (2) broken")
    if ast.state.pattern_qualifiers.len() as i32 % 2 != 0:
        report.fail("pool: pattern_qualifiers stride (2) broken")
    if ast.state.where_meta.len() as i32 % 3 != 0:
        report.fail("pool: where_meta stride (3) broken")
    if ast.state.fn_param_pattern_meta.len() as i32 % 3 != 0:
        report.fail("pool: fn_param_pattern_meta stride (3) broken")

    var fmi = 0
    while fmi < ast.state.for_meta.len() as i32:
        let for_node = ast.state.for_meta.get(fmi as i64)
        if for_node <= 0 or for_node >= ast.node_count() or ast.kind(for_node as NodeId) != NodeKind.NK_FOR:
            report.fail(f"pool: for_meta[{fmi}] does not reference an NK_FOR node (node={for_node})")
        fmi = fmi + 3

    var fni = 0
    while fni < ast.state.fn_meta.len() as i32:
        let fn_node = ast.state.fn_meta.get(fni as i64)
        if fn_node <= 0 or fn_node >= ast.node_count():
            report.fail(f"pool: fn_meta[{fni}] node out of range (node={fn_node})")
        else:
            let mapped = ast.state.fn_meta_map.get(fn_node)
            if mapped.is_some() and mapped.unwrap() != fni:
                report.fail(f"pool: fn_meta_map[{fn_node}] points at {mapped.unwrap()}, record lives at {fni}")
        fni = fni + 7

    // Map/vec mirror integrity: a pool clone that copies one side but not
    // the other silently breaks either the discriminator or fixpoint
    // determinism (#660 clone-carry seam).
    if ast.state.pattern_binding_pairs.len() != ast.state.pattern_binding_keys.len():
        report.fail(f"pool: pattern_binding mirror diverged (vec={ast.state.pattern_binding_pairs.len() as i32} map={ast.state.pattern_binding_keys.len() as i32})")
    for pbi in 0..ast.state.pattern_binding_pairs.len() as i32:
        if not ast.state.pattern_binding_keys.contains(ast.state.pattern_binding_pairs.get(pbi as i64)):
            report.fail(f"pool: pattern_binding pair[{pbi}] missing from key map")

    // Sema scope-stack family: 9 members, all pushed by scope_insert_at.
    // A partial save/swap/restore (the #664 bug) diverges these lengths.
    let binds = sema.bind_names.len()
    if sema.bind_types.len() != binds or sema.bind_muts.len() != binds or sema.bind_states.len() != binds or sema.bind_is_task.len() != binds or sema.bind_task_used.len() != binds or sema.bind_is_scoped_task.len() != binds or sema.bind_is_view_bound.len() != binds or sema.bind_provenance.len() != binds:
        report.fail("families: bind_* scope-stack lengths diverge (partial environment swap)")
    if sema.generic_subst_param_syms.len() != sema.generic_subst_type_ids.len():
        report.fail("families: generic substitution pair diverged")
    if sema.autoderef_step_fns.len() != sema.autoderef_step_tys.len():
        report.fail("families: autoderef step family diverged")
    if sema.moved_field_base_syms.len() != sema.moved_field_path_starts.len() or sema.moved_field_path_starts.len() != sema.moved_field_path_counts.len():
        report.fail("families: moved_field family diverged")
    if sema.dyn_impl_flat_method_names.len() != sema.dyn_impl_flat_sigs.len() or sema.dyn_impl_flat_sigs.len() != sema.dyn_impl_flat_mono_syms.len():
        report.fail("families: dyn_impl flat rows diverged")

    // The #661 seam: decl-source attribution tables must mirror ast.decls.
    if sema.decl_source_paths.len() > 0 and sema.decl_source_paths.len() as i32 != ast.decl_count():
        report.fail(f"families: decl_source tables ({sema.decl_source_paths.len() as i32}) diverge from ast.decls ({ast.decl_count()})")
    if sema.decl_source_paths.len() != sema.decl_source_file_ids.len():
        report.fail("families: decl_source_paths/file_ids diverged")

    report.note(f"pool-audit: nodes={ast.node_count()} fn_meta={ast.state.fn_meta.len() as i32 / 7} for_meta={ast.state.for_meta.len() as i32 / 3} pattern-bindings={ast.state.pattern_binding_pairs.len() as i32} decls={ast.decl_count()}")

fn analysis_audit_storage(report: &AnalysisReport, sema: &Sema):
    let node_count = sema.ast.node_count()
    var resolved_calls = 0
    var resolved_args = 0
    for node in 1..node_count:
        let has_start = sema.call_resolved_arg_starts.contains(node)
        let has_count = sema.call_resolved_arg_counts.contains(node)
        if has_start != has_count:
            report.fail(f"resolved call {node}: start/count tables are not parallel")
            continue
        if not has_start: continue
        resolved_calls = resolved_calls + 1
        let start = sema.call_resolved_arg_starts.get(node).unwrap()
        let count = sema.call_resolved_arg_counts.get(node).unwrap()
        if start < 0 or count < 0 or start + count > sema.call_resolved_args_data.len() as i32:
            report.fail(f"resolved call {node}: invalid arg range start={start} count={count} data={sema.call_resolved_args_data.len() as i32}")
            continue
        for ai in 0..count:
            resolved_args = resolved_args + 1
            let arg_node = sema.call_resolved_args_data.get((start + ai) as i64)
            if arg_node < 0 or arg_node >= node_count:
                report.fail(f"resolved call {node} arg {ai}: AST node {arg_node} is out of range")
            let key = sema.resolved_call_arg_key(node, ai)
            let expected = (node as i64) * 4294967296 + ai as i64
            if key != expected:
                report.fail(f"resolved call {node} arg {ai}: key={key} expected={expected}")
    if node_count > 65537 and sema.resolved_call_arg_key(1, 0) == sema.resolved_call_arg_key(65537, 0):
        report.fail("resolved-call argument keys collide across the former 16-bit node boundary")
    var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.Invariant)
    fact.id = node_count
    fact.index = resolved_calls
    fact.flags = if node_count > 65535: 1 else: 0
    fact.name = "resolved-call-storage"
    fact.detail = f"nodes={node_count} calls={resolved_calls} args={resolved_args} start-count=separate default-key=i64x32 large-node-proof={fact.flags}"
    report.note(fact.detail)
    report.add(move fact)

    var trait_count = 0
    var trait_methods = 0
    for di in 0..sema.ast.decl_count():
        let trait_node = sema.ast.get_decl(di)
        if sema.ast.kind(trait_node) != NodeKind.NK_TRAIT_DECL: continue
        trait_count = trait_count + 1
        let method_start = sema.ast.trait_method_start(trait_node)
        let method_count = sema.ast.trait_method_count(trait_node)
        trait_methods = trait_methods + method_count
        if method_start < 0 or method_count < 0 or method_start + method_count * TRAIT_METHOD_STRIDE > sema.ast.extra_len():
            report.fail(f"trait {trait_node}: invalid method table start={method_start} count={method_count} extra={sema.ast.extra_len()}")
            continue
        var previous_end = sema.ast.get_start(trait_node)
        for mi in 0..method_count:
            let name = sema.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_NAME)
            let param_start = sema.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_PARAM_START)
            let param_count = sema.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_PARAM_COUNT)
            let source_start = sema.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_SOURCE_START)
            let source_end = sema.ast.trait_method_field(trait_node, mi, TRAIT_METHOD_SOURCE_END)
            if name == 0: report.fail(f"trait {trait_node} method {mi}: missing name symbol")
            if param_start < 0 or param_count < 0 or param_start + param_count * FN_PARAM_STRIDE > sema.ast.extra_len():
                report.fail(f"trait {trait_node} method {mi}: invalid param range start={param_start} count={param_count}")
            if source_start < sema.ast.get_start(trait_node) or source_end < source_start or source_end > sema.ast.get_end(trait_node):
                report.fail(f"trait {trait_node} method {mi}: invalid source span {source_start}..{source_end}")
            if source_start < previous_end:
                report.fail(f"trait {trait_node} method {mi}: source spans overlap or are out of order")
            previous_end = source_end
    var trait_fact = AnalysisFact.new(AnalysisStage.Ast, AnalysisFactKind.Invariant)
    trait_fact.id = trait_count
    trait_fact.index = trait_methods
    trait_fact.name = "trait-method-storage"
    trait_fact.detail = f"traits={trait_count} methods={trait_methods} stride={TRAIT_METHOD_STRIDE} source-spans=parser-owned"
    report.note(trait_fact.detail)
    report.add(move trait_fact)

    var impl_count = 0
    var extend_count = 0
    for di in 0..sema.ast.decl_count():
        let impl_node = sema.ast.get_decl(di)
        if sema.ast.kind(impl_node) != NodeKind.NK_IMPL_DECL:
            continue
        impl_count = impl_count + 1
        let marked_extend = sema.ast.is_extend_impl_node(impl_node as NodeId) != 0
        if marked_extend: extend_count = extend_count + 1
        let source = sema.source_text_for_file_id(sema.decl_source_file_id_for_index(di))
        let start = sema.ast.get_start(impl_node)
        var finish = start + 16
        if finish > source.len() as i32: finish = source.len() as i32
        let prefix = if start >= 0 and start < finish: analysis_slice(source, start, finish) else: ""
        let spelled_extend = prefix.starts_with("extend") or prefix.starts_with("pub extend")
        if marked_extend != spelled_extend:
            report.fail(f"impl declaration {impl_node}: parser kind metadata disagrees with source prefix '{prefix}'")
    var impl_kind_fact = AnalysisFact.new(AnalysisStage.Ast, AnalysisFactKind.Invariant)
    impl_kind_fact.id = impl_count
    impl_kind_fact.index = extend_count
    impl_kind_fact.name = "impl-kind-storage"
    impl_kind_fact.detail = f"impl-blocks={impl_count} extend-blocks={extend_count} provenance=parser-owned"
    report.note(impl_kind_fact.detail)
    report.add(move impl_kind_fact)

fn analysis_audit_method_registrations(report: &AnalysisReport, sema: &Sema):
    let ext_count = sema.extension_method_owner_syms.len() as i32
    if sema.extension_method_syms.len() as i32 != ext_count or sema.extension_method_fn_syms.len() as i32 != ext_count or
            sema.extension_method_sig_idxs.len() as i32 != ext_count or sema.extension_method_paths.len() as i32 != ext_count:
        report.fail(f"extension registry tables are not parallel: owners={ext_count} methods={sema.extension_method_syms.len() as i32} fns={sema.extension_method_fn_syms.len() as i32} sigs={sema.extension_method_sig_idxs.len() as i32} paths={sema.extension_method_paths.len() as i32}")
    var methods = 0
    var inherent = 0
    var extensions = 0
    var generic = 0
    var missing = 0
    for i in 0..report.facts.len() as i32:
        let fact = report.facts.get(i as i64)
        if fact.kind != AnalysisFactKind.MethodRegistration:
            continue
        methods = methods + 1
        if fact.flags & (AnalysisMethodRegistrationFlag.Extension as i32) != 0: extensions = extensions + 1
        else: inherent = inherent + 1
        if fact.flags & (AnalysisMethodRegistrationFlag.Generic as i32) != 0: generic = generic + 1
        if fact.flags & (AnalysisMethodRegistrationFlag.Missing as i32) != 0:
            missing = missing + 1
            report.fail(f"method registration missing at {fact.path}:{fact.line}: {fact.name} ({fact.detail})")
    report.note(f"method-registration: methods={methods} inherent={inherent} extensions={extensions} generic={generic} missing={missing}")

fn analysis_is_frozen_consumer(path: &str) -> bool:
    path.contains("/Codegen.w") or path.contains("/CodegenDispatch.w") or
        path.contains("/CodegenTraits.w") or path.contains("/CCodegen.w") or
        path.contains("/AsyncMir.w") or path.contains("/MirSuspendCheck.w")

fn analysis_audit_frozen_calls(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule):
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi as i64]
        let caller_path = analysis_sig_path(sema, body.fn_sym, "")
        if not analysis_is_frozen_consumer(caller_path):
            continue
        for ci in 0..body.call_arg_starts.len() as i32:
            let sig = body.call_sig_index(ci)
            if sig < 0 or sig >= sema.sig_names.len() as i32:
                continue
            let callee_sym = sema.sig_names.get(sig as i64)
            let callee = sema.pool_resolve(callee_sym)
            if not callee.starts_with("Sema."):
                continue
            let mode = sema.sig_receiver_mode(sig)
            if mode != ReceiverMode.Mut and mode != ReceiverMode.Move:
                continue
            var fact = AnalysisFact.new(AnalysisStage.Mir, AnalysisFactKind.Invariant)
            fact.id = ci
            fact.parent = sig
            fact.node = body.call_ast_node(ci)
            fact.body_sym = body.fn_sym
            fact.symbol = callee_sym
            fact.flags = mode as i32
            fact.path = with_str_clone_ref(caller_path)
            fact.name = with_str_clone_ref(callee)
            fact.detail = "frozen caller " ++ sema.pool_resolve(body.fn_sym) ++ " reaches " ++ analysis_receiver_mode_name(mode) ++ " semantic method"
            report.add(move fact)
            report.fail("frozen phase " ++ sema.pool_resolve(body.fn_sym) ++ " -> " ++ callee ++ ": mutable Sema re-entry")

fn analysis_audit_mir(report: &AnalysisReport, mir_mod: &MirModule, pool: &InternPool):
    let err = validate_all_mir_module(mir_mod)
    if err.len() > 0:
        report.fail(err)
    // #719 class: reading a local after StorageDead / after its reset-on-move
    // blank. Guards ordinary bodies here; the synthesized const initializers are
    // checked where they are built (they never enter this module).
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi as i64]
        if body.lowering_failed != 0:
            continue
        let uak = validate_use_after_kill(body, pool)
        if uak.len() > 0:
            report.fail("use-after-kill: " ++ uak)

// Return-consistency: two detectors for the silent-undef class (#653).
// (1) A call terminator whose destination place carries a concrete non-void
// type while the callee's finalized signature returns Unit — the caller
// reads a value the callee never produces. Never-returning callees are
// exempt: their destinations are typed but unreachable.
// (2) A switchInt whose subject operand is Unit-typed — branching on a value
// that cannot exist. This is how a wrongly Unit-inferred callee detonates at
// its call sites (`if f(x):` lowers to a switch on the unit result).
fn analysis_audit_return_consistency(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule):
    var mismatches = 0
    var checked = 0
    var unit_switches = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi as i64]
        if body.lowering_failed != 0:
            continue
        for bb in 0..body.block_count():
            if body.term_kind(bb) == TermKind.TK_SWITCH_INT:
                let subject_ty = mir_validate_operand_type(mir_mod, body, body.term_data0(bb))
                if subject_ty > 0 and sema.get_type_kind(sema.resolve_alias(subject_ty as TypeId)) == TypeKind.TY_VOID:
                    unit_switches = unit_switches + 1
                    report.fail(f"return-consistency: fn sym{body.fn_sym} bb{bb}: switchInt subject is Unit-typed — branch on a value that cannot exist")
                continue
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let args_id = body.term_data1(bb)
            if args_id < 0 or args_id >= body.call_arg_counts.len() as i32:
                continue
            if body.call_intrinsic(args_id) != MirIntrinsic.NONE:
                continue
            let sig = body.call_sig_index(args_id)
            if sig < 0 or sig >= sema.sig_names.len() as i32:
                continue
            let sig_ret = sema.sig_return_type(sig)
            if sig_ret <= 0:
                continue
            if sema.get_type_kind(sema.resolve_alias(sig_ret as TypeId)) != TypeKind.TY_VOID:
                continue
            checked = checked + 1
            let dest_ty = mir_validate_place_type(mir_mod, body, body.term_data2(bb))
            if dest_ty <= 0:
                continue
            let dest_kind = sema.get_type_kind(sema.resolve_alias(dest_ty as TypeId))
            if dest_kind == TypeKind.TY_VOID or dest_kind == TypeKind.TY_NEVER:
                continue
            mismatches = mismatches + 1
            report.fail(f"return-consistency: fn sym{body.fn_sym} bb{bb} call {sema.pool_resolve(sema.sig_names.get(sig as i64))}: destination place type {dest_ty} but callee signature returns Unit")
    report.note(f"return-consistency: unit-return calls checked={checked} dest-mismatches={mismatches} unit-switches={unit_switches}")

fn analysis_audit_receivers(report: &AnalysisReport, sema: &Sema):
    for di in 0..sema.ast.decl_count():
        let node = sema.ast.get_decl(di)
        if sema.ast.kind(node) != NodeKind.NK_FN_DECL:
            continue
        let meta = sema.ast.find_fn_meta(node)
        if meta < 0:
            continue
        let start = sema.ast.fn_meta_param_start(meta)
        let count = sema.ast.fn_meta_param_count(meta)
        let mode = sema.receiver_mode_from_param(start, count)
        if mode == ReceiverMode.Missing:
            let sym = sema.fn_decl_semantic_symbol_at(node, sema.ast.get_data0(node), di)
            report.fail("declaration " ++ sema.pool_resolve(sym) ++ ": receiver mode is missing")
    let errors = sema.receiver_contract_error_count()
    if errors != 0:
        report.fail(f"receiver contracts: {errors} error(s)")
    report.note(sema.audit_receiver_projection_origins())

// D7 source-surface completion. Receiver contract correctness and source
// migration are separate invariants: an explicit receiver can have the right
// mode while still violating the self-less surface.
//
// #727: the D7 trait carve-out is CONFORMING, not a violation — inside a
// trait block, location cannot discriminate instance from associated
// contracts, so a READ instance contract keeps its explicit `self: &Self`
// ("Do not re-open this by flipping trait plain-fn to implicit-instance;
// that makes associated contracts unspellable", decisions.md D7). Only the
// unambiguous keyword forms synthesise in trait bodies, so an explicit
// `mut self: Self` / `move self: Self` in a trait DECLARATION is still a
// violation (it has a keyword spelling), as is every explicit self in
// impls, extends, and top-level methods.
fn analysis_audit_receiver_surface(report: &AnalysisReport, sema: &Sema):
    analysis_audit_receivers(report, sema)
    var explicit = 0
    var explicit_in_impl = 0
    var explicit_trait_impl = 0
    var explicit_top_level = 0
    var explicit_trait_decl = 0
    var conforming_trait_decl = 0
    var synthetic = 0
    for i in 0..report.facts.len() as i32:
        let fact = report.facts.get(i as i64)
        if fact.kind != AnalysisFactKind.Declaration: continue
        let mode = fact.flags & 255
        if mode == AnalysisReceiverMode.None as i32: continue
        if fact.flags & (AnalysisDeclarationFlag.SyntheticReceiver as i32) != 0:
            synthetic = synthetic + 1
            continue
        if fact.flags & (AnalysisDeclarationFlag.TraitDeclaration as i32) != 0 and mode == AnalysisReceiverMode.Read as i32:
            conforming_trait_decl = conforming_trait_decl + 1
            continue
        explicit = explicit + 1
        if fact.flags & (AnalysisDeclarationFlag.InImpl as i32) != 0:
            explicit_in_impl = explicit_in_impl + 1
            if fact.flags & (AnalysisDeclarationFlag.TraitImpl as i32) != 0:
                explicit_trait_impl = explicit_trait_impl + 1
        if fact.flags & (AnalysisDeclarationFlag.TopLevelMethod as i32) != 0:
            explicit_top_level = explicit_top_level + 1
        if fact.flags & (AnalysisDeclarationFlag.TraitDeclaration as i32) != 0:
            explicit_trait_decl = explicit_trait_decl + 1
    report.note(f"receiver-surface: explicit={explicit} in-impl={explicit_in_impl} trait-impl={explicit_trait_impl} trait-decl-nonread={explicit_trait_decl} top-level={explicit_top_level} carve-out={conforming_trait_decl} synthetic={synthetic}")
    if explicit != 0:
        report.fail(f"receiver surface still contains {explicit} explicit `self` parameter(s) outside the D7 trait read carve-out; query kind=declaration,flags&={AnalysisDeclarationFlag.ExplicitReceiver as i32}")

fn analysis_audit_phase(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule):
    if sema.symbols_frozen == 0:
        report.fail("symbols are not frozen at the MIR analysis boundary")
    if sema.types_frozen == 0:
        report.fail("types are not frozen at the MIR analysis boundary")
    for ti in 0..sema.type_kinds.len() as i32:
        if not sema.layout_size_cache.contains(ti): report.fail(f"type {ti}: layout-size cache miss")
        if not sema.layout_align_cache.contains(ti): report.fail(f"type {ti}: layout-align cache miss")
        if not sema.is_copy_cache.contains(ti): report.fail(f"type {ti}: is-copy cache miss")
        if not sema.needs_drop_result_cache.contains(ti): report.fail(f"type {ti}: needs-drop cache miss")
        if not sema.unwrapped_type_cache.contains(ti): report.fail(f"type {ti}: unwrapped-type cache miss")
        if not sema.for_element_type_cache.contains(ti): report.fail(f"type {ti}: for-element cache miss")
        let field_count = sema.type_reflection_field_count(ti)
        for fi in 0..field_count:
            if not sema.layout_field_offset_cache.contains(sema_pair_key(ti, fi)):
                report.fail(f"type {ti} field {fi}: layout-offset cache miss")
            if sema.get_type_kind(ti as TypeId) == TypeKind.TY_GENERIC_INST and not sema.generic_struct_field_index_type_cache.contains(sema_pair_key(ti, fi)):
                report.fail(f"type {ti} field {fi}: generic field-type cache miss")
        if sema.get_type_kind(ti as TypeId) == TypeKind.TY_ENUM and sema.disc_repr_types.contains(ti):
            let variant_count = sema.type_reflection_variant_count(ti)
            let type_sym = sema.get_type_d0(ti as TypeId)
            for vi in 0..variant_count:
                let variant_sym = sema.type_reflection_variant_name(ti, vi)
                let qualified = sema.pool_resolve(type_sym) ++ "." ++ sema.pool_resolve(variant_sym)
                let qualified_sym = sema.pool_lookup_symbol(qualified)
                if qualified_sym == 0 or not sema.disc_values.contains(qualified_sym):
                    report.fail(f"type {ti} variant {vi}: qualified discriminant lookup miss")
    for si in 0..sema.concrete_specialization_syms.len() as i32:
        let mono = sema.concrete_specialization_syms.get(si as i64)
        let sig = sema.concrete_specialization_sigs.get(si as i64)
        if sig < 0 or sig >= sema.sig_names.len() as i32 or sema.sig_names.get(sig as i64) != mono:
            report.fail(f"specialization {si}: signature/symbol mismatch sig={sig} mono={mono}")
        if mir_mod.find_body(mono) < 0:
            report.fail(f"specialization {si}: no prelowered MIR body for mono={mono}")
    analysis_audit_frozen_calls(report, sema, mir_mod)

// move-sites (docs/deep-debugging-tools.md): classify every recorded
// plain-arg-to-owned-param site from the live Sema state. Semantic-snapshot
// request — its primary use is partitioning an ERROR worklist.
fn analysis_move_site_file_name(sema: &Sema, file_id: i32, root_path: &str) -> str:
    for i in 0..sema.source_text_file_ids.len() as i32:
        if sema.source_text_file_ids.get(i as i64) == file_id:
            return with_str_clone_ref(sema.source_text_names.get(i as i64))
    with_str_clone_ref(root_path)

fn analysis_move_site_shape(sema: &Sema, node: i32) -> str:
    var n = node
    while n > 0 and (sema.ast.kind(n) == NodeKind.NK_GROUPED or sema.ast.kind(n) == NodeKind.NK_NO_SUSPEND):
        n = sema.ast.get_data0(n)
    if n <= 0: return "other"
    let k = sema.ast.kind(n)
    if k == NodeKind.NK_IDENT: return "ident"
    if k == NodeKind.NK_FIELD_ACCESS: return "field"
    "other"

fn analysis_move_sites(sema: &Sema, source_path: &str) -> str:
    var out = "file:line:col\troot\tshape\tspellable\tliveness\tloop\tcallee\tparam\n"
    var total = 0
    var design = 0
    var keyword = 0
    var unknown = 0
    let n = sema.consume_call_sites.len() as i32
    var i = 0
    while i + 8 < n:
        let arg_node = sema.consume_call_sites.get(i as i64)
        let callee_sig = sema.consume_call_sites.get((i + 1) as i64)
        let callee_pi = sema.consume_call_sites.get((i + 2) as i64)
        let file_id = sema.consume_call_sites.get((i + 3) as i64)
        let root_sym = sema.consume_call_sites.get((i + 4) as i64)
        let loop_depth = sema.consume_call_sites.get((i + 7) as i64)
        let liveness = sema.consume_call_sites.get((i + 8) as i64)
        i = i + 9
        // Mirror finalize_call_site_ownership: only OWNED params are transfer
        // sites; share-place callees keep the caller's ownership.
        if sema.sig_param_uses_value_ref_abi(callee_sig, callee_pi) != 0:
            continue
        total = total + 1
        let file_name = analysis_move_site_file_name(sema, file_id, source_path)
        let text = sema.source_text_for_file_id(file_id)
        let start = sema.ast.get_start(arg_node)
        let line = analysis_line_for_offset(text, start)
        let col = analysis_column_for_offset(text, start)
        let root = if root_sym != 0: with_str_clone_ref(sema.pool_resolve(root_sym)) else: "<rvalue>"
        let shape = analysis_move_site_shape(sema, arg_node)
        let spellable = if shape == "ident" or shape == "field": "yes" else: "no"
        // In-loop sites are design-flagged regardless of textual liveness: a
        // next-iteration use is not textually "after" the call.
        let live_text = if loop_depth > 0:
            design = design + 1
            "in-loop"
        else: if liveness == 1:
            keyword = keyword + 1
            "last-use"
        else: if liveness == 2:
            design = design + 1
            "live-after"
        else:
            unknown = unknown + 1
            "unknown"
        let loop_text = if loop_depth > 0: "in-loop" else: "-"
        let callee = sema.pool_resolve(sema.sig_names.get(callee_sig as i64))
        out = out ++ f"{file_name}:{line}:{col}\t{root}\t{shape}\t{spellable}\t{live_text}\t{loop_text}\t{callee}\t{callee_pi}\n"
    out ++ f"move-sites: {total} owned-param sites — {keyword} last-use (keyword), {design} design (live-after/in-loop), {unknown} unknown\n"

// seam-sites (docs/deep-debugging-tools.md): inventory the ownership-seam
// classes behind the #691-flip double-free/leak family from live MIR facts,
// before they detonate at runtime. Report-mode like move-sites: the output is
// a burn-down worklist for migrator clients and the future #715/§15.6 gates;
// it never fails the run. Classes:
//   move-through-ref    OK_MOVE of a subplace behind a &T root — blanks a
//                       place the borrow's owner still drops (the Zcu class).
//   move-raw-deref      OK_MOVE through a raw-pointer root — blanks the
//                       pointee behind the compiler's back (*sema_ptr class).
//   copy-elem-drop      OK_COPY of a Drop, non-Copy value through an index
//                       projection — an aliasing element copy; stored copies
//                       double-free, locals leak (#715, BuildGraphTarget class).
//   copy-view-drop      OK_COPY of a Drop, non-Copy value through a &T root —
//                       an aliasing materialization (capability-record class).
//   copy-raw-deref-drop OK_COPY of a Drop, non-Copy value through a raw
//                       pointer root (Sema handoff class).
//   escape-view-consume EFF_ESCAPE_VIEW recorded on a consuming (plain-T)
//                       parameter — a returned view of a dying place (#718).
fn analysis_seam_place_class(sema: &Sema, body: &MirBody, place_id: i32, is_move: i32) -> str:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return ""
    let local = body.place_locals.get(place_id as i64)
    if local < 0 or local >= body.local_type_ids.len() as i32:
        return ""
    let proj_start = body.place_proj_starts.get(place_id as i64)
    let proj_count = body.place_proj_counts.get(place_id as i64)
    let root_ty = body.local_type_ids.get(local as i64)
    let root_kind = if root_ty > 0: sema.get_type_kind(sema.resolve_alias(root_ty as TypeId)) else: TypeKind.TY_ERR
    let deref_root = proj_count > 0 and body.proj_kinds.get(proj_start as i64) == ProjKind.PK_DEREF
    var has_index = 0
    for pi in 0..proj_count:
        if body.proj_kinds.get((proj_start + pi) as i64) == ProjKind.PK_INDEX:
            has_index = 1
    if is_move != 0:
        // A whole `_k.*` move is the reborrow-materialize shape; only a
        // SUBPLACE move behind the ref blanks another owner's storage.
        if deref_root and proj_count > 1 and root_kind == TypeKind.TY_REF:
            return "move-through-ref"
        if deref_root and root_kind == TypeKind.TY_PTR:
            return "move-raw-deref"
        return ""
    let place_ty = body.place_sema_types.get(place_id as i64)
    if place_ty <= 0:
        return ""
    if sema.type_needs_drop_frozen(place_ty) == 0 or sema.is_copy_frozen(place_ty as TypeId) != 0:
        return ""
    if has_index != 0:
        return "copy-elem-drop"
    if deref_root and root_kind == TypeKind.TY_REF:
        return "copy-view-drop"
    if deref_root and root_kind == TypeKind.TY_PTR:
        return "copy-raw-deref-drop"
    ""

// Emit one row per SITE (statement or terminator), so every finding carries a
// source location and the context that consumes the operand. A migrator client
// needs both: the location to edit, and the context to choose the fix
// (`store` = the copy is retained -> clone/view; `read` = transient -> view).
// Pure classification of one operand use; the caller owns accumulation so
// nothing mutates through a borrow (the very class this tool reports).
type SeamRow { ok: i32, class_idx: i32, key: str, row: str, actionable: i32 }

// A copy only matters when the COPY is retained — stored, aggregated, or
// handed to a consuming callee — because only then does a second owner drop
// it. A copy consumed as an operand of a non-storing rvalue (a length read, a
// comparison) never drops, so it is observed, not actionable. Moves are always
// actionable: they blank a place another owner still drops.
fn analysis_seam_context_is_actionable(context: &str, is_move: i32) -> i32:
    if is_move != 0:
        return 1
    if context == "read":
        return 0
    1

fn analysis_seam_row(sema: &Sema, body: &MirBody, fn_name: &str, path: &str, span: i32, operand: i32, context: &str) -> SeamRow:
    let none = SeamRow { ok: 0, class_idx: 0, key: "", row: "", actionable: 0 }
    if operand < 0 or operand >= body.operand_kinds.len() as i32:
        return none
    let okind = body.operand_kinds.get(operand as i64)
    if okind != OperandKind.OK_COPY and okind != OperandKind.OK_MOVE:
        return none
    let place_id = body.operand_d0.get(operand as i64)
    let class = analysis_seam_place_class(sema, body, place_id, if okind == OperandKind.OK_MOVE: 1 else: 0)
    if class.len() == 0:
        return none
    let place_text = mir_place_text(body, place_id)
    let class_idx = if class == "move-through-ref": 0
        else if class == "move-raw-deref": 1
        else if class == "copy-elem-drop": 2
        else if class == "copy-view-drop": 3
        else: 4
    let place_ty = body.place_sema_types.get(place_id as i64)
    let actionable = analysis_seam_context_is_actionable(context, if okind == OperandKind.OK_MOVE: 1 else: 0)
    let tier = if actionable != 0: "actionable" else: "observed"
    SeamRow {
        ok: 1,
        class_idx,
        key: fn_name ++ "\t" ++ class ++ "\t" ++ place_text ++ "\t" ++ f"{span}",
        row: path ++ f"\t{span}\t{fn_name}\t{class}\t{tier}\t{context}\t{place_text}\t" ++ sema.type_name(place_ty) ++ "\n",
        actionable,
    }

// The retention class (#715 / BuildGraphTarget / capability-record shape):
// a Drop, non-Copy value is READ out of a container the function does not own
// (receiver rooted in a borrow, a raw pointer, or a `self` field), and the
// result is then RETAINED — pushed into another container or stored into an
// aggregate. Both owners later free the same buffers.
//
// The copy is laundered through the accessor's RETURN VALUE, so it carries no
// place projection; keying on projections (as the place classifier does) misses
// it entirely. This walk keys on the call destination instead, then proves
// retention with a second pass over the same body.
fn analysis_seam_place_is_unowned_root(sema: &Sema, body: &MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    let local = body.place_locals.get(place_id as i64)
    if local < 0 or local >= body.local_type_ids.len() as i32:
        return 0
    let proj_count = body.place_proj_counts.get(place_id as i64)
    let root_ty = body.local_type_ids.get(local as i64)
    let root_kind = if root_ty > 0: sema.get_type_kind(sema.resolve_alias(root_ty as TypeId)) else: TypeKind.TY_ERR
    // A borrowed/raw root, or any projection off local 0 (`self`/first param).
    if root_kind == TypeKind.TY_REF or root_kind == TypeKind.TY_PTR:
        return 1
    if local == 1 and proj_count > 0:
        return 1
    0

fn analysis_seam_retention_rows(sema: &Sema, body: &MirBody, fn_name: &str, path: &str) -> Vec[str]:
    let rows: Vec[str] = Vec.new()
    let candidate_locals: Vec[i32] = Vec.new()
    let candidate_spans: Vec[i32] = Vec.new()
    let candidate_types: Vec[i32] = Vec.new()
    // Pass 1: calls whose result is a Drop non-Copy value read from an unowned container.
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        let dest = body.term_data2(bb)
        if dest < 0 or dest >= body.place_locals.len() as i32:
            continue
        let dest_ty = body.place_sema_types.get(dest as i64)
        if dest_ty <= 0 or sema.type_needs_drop_frozen(dest_ty) == 0 or sema.is_copy_frozen(dest_ty as TypeId) != 0:
            continue
        let args_id = body.term_data1(bb)
        if args_id < 0 or args_id >= body.call_arg_starts.len() as i32:
            continue
        // Only a BUILTIN container accessor returns a bitwise element copy that
        // aliases the receiver's interior. A user callee returning a Drop value
        // built it (clone/constructor) — flagging those reports every correct
        // `clone_str_vec(&self.field)` as a bug. (A user fn that hands back a
        // view is caught by the escape-view class instead.)
        if body.call_sig_index(args_id) >= 0:
            continue
        let start = body.call_arg_starts.get(args_id as i64)
        let count = body.call_arg_counts.get(args_id as i64)
        if count <= 0 or start < 0 or start >= body.call_arg_operands.len() as i32:
            continue
        let recv_op = body.call_arg_operands.get(start as i64)
        if recv_op < 0 or recv_op >= body.operand_kinds.len() as i32:
            continue
        if body.operand_kinds.get(recv_op as i64) == OperandKind.OK_MOVE:
            continue
        if analysis_seam_place_is_unowned_root(sema, body, body.operand_d0.get(recv_op as i64)) == 0:
            continue
        candidate_locals.push(body.place_locals.get(dest as i64))
        candidate_spans.push(body.bb_term_spans.get(bb as i64))
        candidate_types.push(dest_ty)
    if candidate_locals.len() == 0:
        return rows
    // Pass 2: is a candidate retained (aggregate field, or an owned call arg)?
    for ci in 0..candidate_locals.len() as i32:
        let want = candidate_locals.get(ci as i64)
        var retained_by = ""
        for si in 0..body.stmt_kinds.len() as i32:
            if retained_by.len() > 0: break
            if body.stmt_kinds.get(si as i64) != StmtKind.Assign: continue
            let rv = body.stmt_d1.get(si as i64)
            if rv < 0 or rv >= body.rval_kinds.len() as i32: continue
            if body.rval_kinds.get(rv as i64) != RvalueKind.RK_AGGREGATE: continue
            let fid = body.rval_d1.get(rv as i64)
            if fid < 0 or fid >= body.agg_field_starts.len() as i32: continue
            let fstart = body.agg_field_starts.get(fid as i64)
            let fcount = body.agg_field_counts.get(fid as i64)
            for fi in 0..fcount:
                let opi = fstart + fi
                if opi < 0 or opi >= body.agg_field_operands.len() as i32: continue
                let op = body.agg_field_operands.get(opi as i64)
                if op < 0 or op >= body.operand_kinds.len() as i32: continue
                let opl = body.operand_d0.get(op as i64)
                if opl >= 0 and opl < body.place_locals.len() as i32 and body.place_locals.get(opl as i64) == want:
                    retained_by = "store-aggregate"
        for bb2 in 0..body.block_count():
            if retained_by.len() > 0: break
            if body.term_kind(bb2) != TermKind.TK_CALL: continue
            let aid = body.term_data1(bb2)
            if aid < 0 or aid >= body.call_arg_starts.len() as i32: continue
            let s2 = body.call_arg_starts.get(aid as i64)
            let c2 = body.call_arg_counts.get(aid as i64)
            let sig2 = body.call_sig_index(aid)
            for ai in 1..c2:
                let opi = s2 + ai
                if opi < 0 or opi >= body.call_arg_operands.len() as i32: continue
                let op = body.call_arg_operands.get(opi as i64)
                if op < 0 or op >= body.operand_kinds.len() as i32: continue
                let opl = body.operand_d0.get(op as i64)
                if opl < 0 or opl >= body.place_locals.len() as i32: continue
                if body.place_locals.get(opl as i64) != want: continue
                if sig2 >= 0 and ai < sema.sig_get_param_count(sig2):
                    let pty = sema.sig_param_type(sig2, ai)
                    let pk = if pty > 0: sema.get_type_kind(sema.resolve_alias(pty as TypeId)) else: TypeKind.TY_ERR
                    if pk == TypeKind.TY_REF or pk == TypeKind.TY_PTR: continue
                retained_by = "retained-call-arg"
        if retained_by.len() > 0:
            let span = candidate_spans.get(ci as i64)
            rows.push(path ++ f"\t{span}\t{fn_name}\tretained-unowned-copy\t{retained_by}\t_{want}\t" ++ sema.type_name(candidate_types.get(ci as i64)) ++ "\n")
    rows

fn analysis_seam_sites(sema: &Sema, mir_mod: &MirModule, source_path: &str, source_text: &str) -> str:
    let _ = source_path
    var out = "path\toffset\tfn\tclass\ttier\tcontext\tplace\ttype\n"
    let report_lines: Vec[str] = Vec.new()
    let counts: Vec[i32] = Vec.new()
    for _ci in 0..7:
        counts.push(0)
    var escapes = 0
    let seen: HashMap[str, i32] = HashMap.new()
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi as i64]
        if body.lowering_failed != 0:
            continue
        let fn_name = sema.pool_resolve(body.fn_sym)
        let fn_path = analysis_sig_path(sema, body.fn_sym, source_path)
        let ret_rows = analysis_seam_retention_rows(sema, body, fn_name, fn_path)
        for ri in 0..ret_rows.len() as i32:
            report_lines.push(with_str_clone_ref(ret_rows.get(ri as i64)))
            counts.set_i32(5, counts.get(5) + 1)
        // Statements: an operand inside an aggregate or a plain assign is
        // RETAINED by the destination; anything else is a transient read.
        for si in 0..body.stmt_kinds.len() as i32:
            if body.stmt_kinds.get(si as i64) != StmtKind.Assign:
                continue
            let span = body.stmt_spans.get(si as i64)
            let rv = body.stmt_d1.get(si as i64)
            if rv < 0 or rv >= body.rval_kinds.len() as i32:
                continue
            let rk = body.rval_kinds.get(rv as i64)
            let pending: Vec[i32] = Vec.new()
            let contexts: Vec[str] = Vec.new()
            if rk == RvalueKind.RK_AGGREGATE:
                let fid = body.rval_d1.get(rv as i64)
                if fid >= 0 and fid < body.agg_field_starts.len() as i32:
                    let fstart = body.agg_field_starts.get(fid as i64)
                    let fcount = body.agg_field_counts.get(fid as i64)
                    for fi in 0..fcount:
                        let opi = fstart + fi
                        if opi >= 0 and opi < body.agg_field_operands.len() as i32:
                            pending.push(body.agg_field_operands.get(opi as i64))
                            contexts.push("store-aggregate")
            else if rk == RvalueKind.RK_USE:
                pending.push(body.rval_d0.get(rv as i64))
                contexts.push("store-assign")
            else:
                pending.push(body.rval_d0.get(rv as i64))
                contexts.push("read")
            for pi in 0..pending.len() as i32:
                var r = analysis_seam_row(sema, body, fn_name, fn_path, span, pending.get(pi as i64), contexts.get(pi as i64))
                if r.ok != 0 and not seen.contains(r.key):
                    seen.insert(move r.key, 1)
                    counts.set_i32(r.class_idx as i64, counts.get(r.class_idx as i64) + 1)
                    if r.actionable != 0:
                        counts.set_i32(6, counts.get(6) + 1)
                    report_lines.push(move r.row)
        // Call arguments: retained when the callee consumes them.
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let args_id = body.term_data1(bb)
            if args_id < 0 or args_id >= body.call_arg_starts.len() as i32:
                continue
            let start = body.call_arg_starts.get(args_id as i64)
            let count = body.call_arg_counts.get(args_id as i64)
            let sig = body.call_sig_index(args_id)
            let term_span = body.bb_term_spans.get(bb as i64)
            for ai in 0..count:
                let opi = start + ai
                if opi < 0 or opi >= body.call_arg_operands.len() as i32:
                    continue
                var context = "call-arg"
                // Builtin callee (no signature): its receiver is still a place,
                // not a copy — but its real arguments (Vec.push's element) do
                // retain, so only the receiver slot is exempt.
                if sig < 0 and ai == 0:
                    continue
                if sig >= 0 and ai < sema.sig_get_param_count(sig):
                    // Receiver slot: compiler-modeled place passing, not a copy.
                    if ai == 0 and sema.sig_receiver_mode(sig) != ReceiverMode.None:
                        continue
                    let pty = sema.sig_param_type(sig, ai)
                    let pkind = if pty > 0: sema.get_type_kind(sema.resolve_alias(pty as TypeId)) else: TypeKind.TY_ERR
                    // A view passed to a BORROWED parameter is not a seam: the
                    // callee never retains it. Only owned params retain.
                    if pkind == TypeKind.TY_REF or pkind == TypeKind.TY_PTR:
                        continue
                    context = "call-arg-owned"
                var cr = analysis_seam_row(sema, body, fn_name, fn_path, term_span, body.call_arg_operands.get(opi as i64), context)
                if cr.ok != 0 and not seen.contains(cr.key):
                    seen.insert(move cr.key, 1)
                    counts.set_i32(cr.class_idx as i64, counts.get(cr.class_idx as i64) + 1)
                    if cr.actionable != 0:
                        counts.set_i32(6, counts.get(6) + 1)
                    report_lines.push(move cr.row)
    for li in 0..report_lines.len() as i32:
        out = out ++ report_lines.get(li as i64)
    let moves_ref = counts.get(0)
    let moves_raw = counts.get(1)
    let copies_elem = counts.get(2)
    let copies_view = counts.get(3)
    let copies_raw = counts.get(4)
    let retained = counts.get(5)
    for si in 0..sema.sig_names.len() as i32:
        for pi in 0..sema.sig_get_param_count(si):
            if (sema.sig_param_effect(si, pi) & EFF_ESCAPE_VIEW) == 0:
                continue
            let param_ty = sema.sig_param_type(si, pi)
            let param_kind = if param_ty > 0: sema.get_type_kind(sema.resolve_alias(param_ty as TypeId)) else: TypeKind.TY_ERR
            if param_kind == TypeKind.TY_REF or param_kind == TypeKind.TY_PTR:
                continue
            // Receiver slots use compiler-modeled place passing, not a dying copy.
            if pi == 0 and sema.sig_receiver_mode(si) != ReceiverMode.None:
                continue
            escapes = escapes + 1
            out = out ++ sema.pool_resolve(sema.sig_names.get(si as i64)) ++ "\tescape-view-consume\tparam " ++ f"{pi}" ++ "\t" ++ sema.type_name(param_ty) ++ "\n"
    // ACTIONABLE is the number that matters: a copy is only a latent
    // double-free when the copy is retained (stored/aggregated/consumed by a
    // callee). Read-position copies are operands that never drop — reported
    // as observed so the inventory does not cry wolf. escape-view-consume is
    // always actionable.
    let actionable = counts.get(6) + escapes
    let total = moves_ref + moves_raw + copies_elem + copies_view + copies_raw + escapes
    out ++ f"seam-sites: {total} findings ({actionable} actionable, {total - actionable} observed) — move-through-ref={moves_ref} move-raw-deref={moves_raw} copy-elem-drop={copies_elem} copy-view-drop={copies_view} copy-raw-deref-drop={copies_raw} retained-unowned-copy={retained} escape-view-consume={escapes}\n"

// explain:effect (docs/deep-debugging-tools.md): walk the first-setter
// provenance chain for each ownership-forcing bit of a parameter, from the
// queried signature down to the direct seed. Packing lives in Sema
// (effect_prov_key / effect_prov_val_*) — the encoder and this decoder share
// one definition.
fn analysis_effect_bit_name(bit_idx: i32) -> str:
    if bit_idx == 0: return "consume"
    if bit_idx == 1: return "escape_value"
    "write"

fn analysis_explain_effect_chain(sema: &Sema, sig: i32, pi: i32, bit_idx: i32, source_path: &str) -> str:
    var out = ""
    var cur_sig = sig
    var cur_pi = pi
    var depth = 0
    while depth < 32:
        depth = depth + 1
        let key = effect_prov_key(cur_sig, cur_pi, bit_idx)
        let prov = sema.effect_prov.get(key)
        if not prov.is_some():
            out = out ++ "    (no provenance recorded for this hop)\n"
            return out
        let packed = prov.unwrap()
        let kind = effect_prov_val_kind(packed)
        let a = effect_prov_val_a(packed)
        let b = effect_prov_val_b(packed)
        if kind == 1:
            let text = sema.source_text_for_file_id(b)
            let file_name = analysis_move_site_file_name(sema, b, source_path)
            let start = if a > 0 and a < sema.ast.node_count(): sema.ast.get_start(a) else: 0
            let line = analysis_line_for_offset(text, start)
            out = out ++ f"    direct seed at {file_name}:{line} (node {a})\n"
            return out
        let callee = sema.pool_resolve(sema.sig_names.get(a as i64))
        out = out ++ f"    via argument to {callee} param {b}\n"
        cur_sig = a
        cur_pi = b
    out ++ "    (chain depth limit reached)\n"

fn analysis_explain_effect(sema: &Sema, target: &str, source_path: &str) -> str:
    var fn_name = with_str_clone_ref(target)
    var want_pi = 0 - 1
    let colon = analysis_find_from(target, ":", 0)
    if colon >= 0:
        fn_name = analysis_slice(target, 0, colon)
        let pi_text = analysis_slice(target, colon + 1, target.len() as i32)
        if pi_text == "self":
            want_pi = 0
        else:
            want_pi = analysis_parse_i32(pi_text)
    var out = f"explain:effect {fn_name}\n"
    var found = 0
    for si in 0..sema.sig_names.len() as i32:
        if sema.pool_resolve(sema.sig_names.get(si as i64)) != fn_name:
            continue
        found = found + 1
        let pc = sema.sig_get_param_count(si)
        for pi in 0..pc:
            if want_pi >= 0 and pi != want_pi:
                continue
            let eff = sema.sig_param_effect(si, pi)
            out = out ++ f"  sig={si} param[{pi}] eff=[" ++ sema_effect_bits_text(eff) ++ "]\n"
            if (eff & EFF_CONSUME) != 0:
                out = out ++ "  consume:\n" ++ analysis_explain_effect_chain(sema, si, pi, 0, source_path)
            if (eff & EFF_ESCAPE_VALUE) != 0:
                out = out ++ "  escape_value:\n" ++ analysis_explain_effect_chain(sema, si, pi, 1, source_path)
            if (eff & EFF_WRITE) != 0:
                out = out ++ "  write:\n" ++ analysis_explain_effect_chain(sema, si, pi, 2, source_path)
    if found == 0:
        out = out ++ "  (no signature matched; use the exact finalized name, e.g. Type.method)\n"
    out

fn analysis_fact_explain_query(kind: &str, wanted: &str) -> str:
    if kind == "call": return "kind=call,name~" ++ wanted
    if kind == "value": return "kind=place,detail~" ++ wanted
    if kind == "specialization": return "kind=specialization,name~" ++ wanted
    if kind == "diagnostic": return "kind=diagnostic,detail~" ++ wanted
    if kind == "effect": return "kind=effect-edge,detail~" ++ wanted
    if kind == "type": return "kind=type,name~" ++ wanted
    if kind == "field": return "kind=field,name~" ++ wanted
    if kind == "expression": return "kind=expression,detail~" ++ wanted
    if kind == "node": return "kind=ast-node"
    if kind == "method": return "kind=method-registration,name~" ++ wanted
    if kind == "resolution": return "kind=method-resolution,name~" ++ wanted
    with_str_clone_ref(wanted)

fn analysis_explain_request(request: &str) -> str:
    let first = analysis_find_from(request, ":", 0)
    if first < 0:
        return with_str_clone_ref(request)
    let rest = analysis_slice(request, first + 1, request.len() as i32)
    let second = analysis_find_from(rest, ":", 0)
    if second < 0:
        return rest
    let kind = analysis_slice(rest, 0, second)
    let wanted = analysis_slice(rest, second + 1, rest.len() as i32)
    analysis_fact_explain_query(kind, wanted)

fn analysis_lldb_recipe(report: &AnalysisReport, query: &str) -> str:
    let lines: Vec[str] = Vec.new()
    lines.push("# Generated from live compiler-analysis facts.\n")
    var hits = 0
    for i in 0..report.facts.len() as i32:
        let fact = report.facts.get(i as i64)
        if not analysis_fact_matches(fact, query):
            continue
        if fact.kind == AnalysisFactKind.Diagnostic and fact.path.len() > 0 and fact.line > 0:
            lines.push("breakpoint set --file '")
            lines.push(with_str_clone_ref(fact.path))
            lines.push(f"' --line {fact.line}\n")
            hits = hits + 1
        else if fact.kind == AnalysisFactKind.Call or fact.kind == AnalysisFactKind.CallArgument:
            lines.push("breakpoint set --name 'Codegen.marshal_mir_call_arg'\n")
            lines.push("breakpoint set --name 'MirBuilder.lower_call_arg'\n")
            hits = hits + 1
        else if fact.kind == AnalysisFactKind.EffectEdge or fact.kind == AnalysisFactKind.Receiver:
            lines.push("breakpoint set --name 'Sema.record_effect_edge'\n")
            lines.push("breakpoint set --name 'Sema.note_place_effect'\n")
            hits = hits + 1
        else if fact.kind == AnalysisFactKind.MethodRegistration:
            lines.push("breakpoint set --name 'Sema.collect_fn_decl'\n")
            lines.push("breakpoint set --name 'Sema.register_method_sig_alias'\n")
            lines.push("breakpoint set --name 'Sema.lookup_method_sig'\n")
            hits = hits + 1
    if hits == 0:
        lines.push("# No facts matched; refusing to invent a breakpoint.\n")
    lines.join("")

fn analysis_symbol_name(report: &AnalysisReport, sym: i32) -> str:
    for i in 0..report.facts.len() as i32:
        let fact = report.facts.get(i as i64)
        if fact.symbol == sym and (fact.kind == AnalysisFactKind.Signature or fact.kind == AnalysisFactKind.Body or fact.kind == AnalysisFactKind.Declaration):
            return fact.name.clone()
    f"sym{sym}"

fn analysis_find_symbol(report: &AnalysisReport, name: &str) -> i32:
    for i in 0..report.facts.len() as i32:
        let fact = report.facts.get(i as i64)
        if fact.symbol != 0 and fact.name == name and
           (fact.kind == AnalysisFactKind.Signature or fact.kind == AnalysisFactKind.Body or fact.kind == AnalysisFactKind.Declaration):
            return fact.symbol
    0

fn analysis_call_path(report: &AnalysisReport, from: &str, to: &str) -> str:
    let start = analysis_find_symbol(report, from)
    let target = analysis_find_symbol(report, to)
    if start == 0 or target == 0:
        return f"call-path: unresolved endpoint from={from} to={to}\n"
    let queue: Vec[i32] = Vec.new()
    let pred: HashMap[i32, i32] = HashMap.new()
    queue.push(start)
    pred.insert(start, 0)
    var qi = 0
    while qi < queue.len() as i32 and not pred.contains(target):
        let caller = queue.get(qi as i64)
        qi = qi + 1
        for i in 0..report.facts.len() as i32:
            let fact = report.facts.get(i as i64)
            if fact.kind != AnalysisFactKind.Call or fact.body_sym != caller or fact.symbol == 0 or pred.contains(fact.symbol):
                continue
            pred.insert(fact.symbol, caller)
            queue.push(fact.symbol)
    if not pred.contains(target):
        return f"call-path: no path from {from} to {to}\n"
    let reverse: Vec[i32] = Vec.new()
    var at = target
    while at != 0:
        reverse.push(at)
        at = pred.get(at).unwrap()
    let lines: Vec[str] = Vec.new()
    lines.push(f"call-path: {from} -> {to}\n")
    var i = reverse.len() as i32 - 1
    while i >= 0:
        lines.push("  ")
        lines.push(analysis_symbol_name(report, reverse.get(i as i64)))
        lines.push("\n")
        i = i - 1
    lines.join("")

fn analysis_call_closure(report: &AnalysisReport, root: &str) -> str:
    let start = analysis_find_symbol(report, root)
    if start == 0:
        return f"call-closure: unresolved root {root}\n"
    let queue: Vec[i32] = Vec.new()
    let pred: HashMap[i32, i32] = HashMap.new()
    queue.push(start)
    pred.insert(start, 0)
    var qi = 0
    while qi < queue.len() as i32:
        let caller = queue.get(qi as i64)
        qi = qi + 1
        for i in 0..report.facts.len() as i32:
            let fact = report.facts.get(i as i64)
            if fact.kind != AnalysisFactKind.Call or fact.body_sym != caller or fact.symbol == 0 or pred.contains(fact.symbol):
                continue
            pred.insert(fact.symbol, caller)
            queue.push(fact.symbol)
    let lines: Vec[str] = Vec.new()
    lines.push(f"call-closure: root={root} reachable={queue.len() as i32}\n")
    for i in 0..queue.len() as i32:
        let sym = queue.get(i as i64)
        let parent = pred.get(sym).unwrap()
        lines.push(analysis_symbol_name(report, sym))
        lines.push("\t")
        lines.push(if parent == 0: "<root>" else: analysis_symbol_name(report, parent))
        lines.push("\n")
    lines.join("")

fn analysis_help() -> str:
    "with analyze <file.w> <request>\n" ++
        "  facts | snapshot                         stable TSV facts from Sema + MIR\n" ++
        "  select:<query>                          filter facts (=, !=, ~, numeric bitmask &=)\n" ++
        "  summary[:<query>]                       counts by live compiler stage/kind\n" ++
        "  matrix:<query>                          compact cross-stage fact matrix\n" ++
        "  explain:call|value|effect|specialization|diagnostic|type|field|expression|method:<text>\n" ++
        "  explain:node:<id>                       bounded AST + Sema type/resolution tree\n" ++
        "  audit:calls|effects|storage|methods|mir|returns|receivers|receiver-surface|phase|codegen|trait-tables|all\n" ++
        "  move-sites | seam-sites                 ownership worklists (owned-param call sites; aliasing/blanking seams)\n" ++
        "  path:call:<from>:<to>                   shortest live MIR call path\n" ++
        "  closure:call:<root>                     live MIR call closure\n" ++
        "  lldb:<query>                            breakpoints derived from matching facts\n" ++
        "  after-mir:<request>                     query the MIR-preparation Sema snapshot, even on failure\n" ++
        "Queries are comma-separated predicates over stage, kind, id, parent, node, body,\n" ++
        "symbol, owner, index, type, effects, flags, source-file, start, end, line,\n" ++
        "column, path, name, and detail.\n"

fn compiler_analysis_render(report: &AnalysisReport, request: &str) -> str:
    if request == "help": return analysis_help()
    if request == "" or request == "facts" or request == "snapshot": return report.render_facts("")
    if request.starts_with("select:"): return report.render_facts(analysis_slice(request, 7, request.len() as i32))
    if request == "summary": return report.render_summary("")
    if request.starts_with("summary:"): return report.render_summary(analysis_slice(request, 8, request.len() as i32))
    if request.starts_with("matrix:"): return report.render_matrix(analysis_slice(request, 7, request.len() as i32)) ++ report.render_verdict("compiler-analysis")
    if request.starts_with("explain:"): return report.render_facts(analysis_explain_request(request)) ++ report.render_verdict("compiler-analysis")
    if request == "audit:calls": return report.render_verdict("call-contract-audit")
    if request == "audit:effects": return report.render_verdict("effect-audit")
    if request == "audit:storage": return report.render_verdict("storage-audit")
    if request == "audit:pool": return report.render_verdict("pool-audit")
    if request == "audit:methods": return report.render_verdict("method-registration-audit")
    if request == "audit:phase": return report.render_verdict("phase-audit")
    if request == "audit:mir": return report.render_verdict("mir-audit")
    if request == "audit:returns": return report.render_verdict("return-consistency-audit")
    if request == "audit:receivers": return report.render_verdict("receiver-audit")
    if request == "audit:receiver-surface": return report.render_verdict("receiver-surface-audit")
    if request == "audit:codegen": return report.render_verdict("codegen-contract-audit")
    if request == "audit:trait-tables": return report.render_verdict("trait-table-audit")
    if request == "audit:all": return report.render_verdict("compiler-analysis-audit")
    if request.starts_with("path:call:"):
        let endpoints = analysis_slice(request, 10, request.len() as i32)
        let split = analysis_find_from(endpoints, ":", 0)
        if split < 0: return "error: path:call requires <from>:<to>\n"
        return analysis_call_path(report, analysis_slice(endpoints, 0, split), analysis_slice(endpoints, split + 1, endpoints.len() as i32))
    if request.starts_with("closure:call:"): return analysis_call_closure(report, analysis_slice(request, 13, request.len() as i32))
    if request.starts_with("lldb:"): return analysis_lldb_recipe(report, analysis_slice(request, 5, request.len() as i32))
    "error: unknown analysis request '" ++ request ++ "'\n"

fn compiler_analysis_run(sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str, request: &str) -> CompilerAnalysisResult:
    let report = AnalysisReport.init()
    analysis_collect_sema(&report, sema, source_path, source_text)
    analysis_collect_requested_node(&report, sema, request, source_path, source_text)
    analysis_collect_mir(&report, mir_mod, sema, pool, source_path, source_text)
    var text = ""
    var status = 0
    var needs_codegen = false
    var codegen_query = ""

    if request == "move-sites":
        return CompilerAnalysisResult { text: analysis_move_sites(sema, source_path), status: 0, needs_codegen: false, codegen_query: "", report }
    if request == "seam-sites":
        return CompilerAnalysisResult { text: analysis_seam_sites(sema, mir_mod, source_path, source_text), status: 0, needs_codegen: false, codegen_query: "", report }
    if request.starts_with("explain:effect:"):
        let ee_target = analysis_slice(request, 15, request.len() as i32)
        return CompilerAnalysisResult { text: analysis_explain_effect(sema, ee_target, source_path), status: 0, needs_codegen: false, codegen_query: "", report }
    if request.starts_with("matrix:"):
        let query = analysis_slice(request, 7, request.len() as i32)
        if query.contains("name"):
            needs_codegen = true
            codegen_query = "matrix:" ++ query
    else if request.starts_with("explain:call:"):
        needs_codegen = true
        codegen_query = "name~" ++ analysis_slice(request, 13, request.len() as i32)
    else if request == "audit:calls":
        analysis_audit_call_contracts(&report, sema, mir_mod)
    else if request == "audit:effects":
        analysis_audit_effects(&report, sema)
    else if request == "audit:storage":
        analysis_audit_storage(&report, sema)
    else if request == "audit:pool":
        analysis_audit_pool(&report, sema)
    else if request == "audit:methods":
        analysis_audit_method_registrations(&report, sema)
    else if request == "audit:phase":
        analysis_audit_phase(&report, sema, mir_mod)
    else if request == "audit:mir":
        analysis_audit_mir(&report, mir_mod, pool)
    else if request == "audit:returns":
        analysis_audit_return_consistency(&report, sema, mir_mod)
    else if request == "audit:receivers":
        analysis_audit_receivers(&report, sema)
    else if request == "audit:receiver-surface":
        analysis_audit_receiver_surface(&report, sema)
    else if request == "audit:codegen":
        needs_codegen = true
        codegen_query = "audit"
    else if request == "audit:trait-tables":
        needs_codegen = true
        codegen_query = "audit"
    else if request == "audit:all":
        analysis_audit_call_contracts(&report, sema, mir_mod)
        analysis_audit_effects(&report, sema)
        analysis_audit_storage(&report, sema)
        analysis_audit_pool(&report, sema)
        analysis_audit_method_registrations(&report, sema)
        analysis_audit_mir(&report, mir_mod, pool)
        analysis_audit_return_consistency(&report, sema, mir_mod)
        analysis_audit_receivers(&report, sema)
        analysis_audit_phase(&report, sema, mir_mod)
        needs_codegen = true
        codegen_query = "audit"
    else if request.starts_with("lldb:"):
        if analysis_lldb_recipe(&report, analysis_slice(request, 5, request.len() as i32)).contains("No facts matched"):
            status = 1
    else if request != "help" and request != "" and request != "facts" and request != "snapshot" and
            request != "summary" and not request.starts_with("summary:") and not request.starts_with("select:") and
            not request.starts_with("explain:") and not request.starts_with("path:call:") and not request.starts_with("closure:call:"):
        status = 1
    text = compiler_analysis_render(&report, request)
    if not report.ok():
        status = 1
    CompilerAnalysisResult { text, status, needs_codegen, codegen_query, report }
