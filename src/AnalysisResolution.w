// AnalysisResolution — D65 phase 1 (#1647): `audit:resolution`, in
// `audit:all`. Every MIR call must agree with Sema's resolution of the call
// it lowers: Sema decides what a call invokes (a signature, a generic
// template, a builtin, a callable value); MIR materializes it. A MIR callee
// Sema knows no function for was re-derived from an AST spelling after
// Sema — #1635's `let r = c.run; r(21)` became a GENERIC_CALL to a function
// named `r` with the argument dropped, and every validator stayed silent
// (#1639).
//
// Reads both producers' facts and re-derives nothing: Sema's tables
// (get_sig, generic_fn_node_for_symbol, call_callable_types,
// call_callee_is_builtin, resolved_call_sigs) and the MIR call tables. The
// comparison itself (mir_resolution_check_call, MirCore) takes Sema's
// answer as a record, so test/internals plants a body and an answer and
// exercises the rule without a Sema.
//
// Phase 1 covers callees and argument counts: a `const fn` callee, a place
// callee, the argument count against the same Sema fact, the call node's
// own resolution, and a call Sema resolved inside a lowered body that MIR
// never lowered. Phase 3 covers places and bindings: every place lowered
// from a source field access (its projection, its type, its base after
// Sema's autoderef) and every immutable non-Copy `let` (alias of a place
// iff Sema bound a view). Phase 4 covers call-argument transfer: a named
// owned binding moves only into a parameter Sema consumes and is copied
// only into one it borrows. Phase 5 covers resolved calls: a direct call
// lowered from a source call calls the function Sema resolved it to and
// hands its value to the conversion Sema recorded (MIR knows nothing about
// facades: a C name's bridge, case or presented view reaches MIR only as
// those records). Phase 2 (codegen mode provenance) is
// audit:codegen's; the plan is docs/spec/implementation/mir-sema-hardening.md.

use AnalysisTypes
use Ast
use InternPool
use Mir
use Sema
use MirCore
use SemaTypes
use std.collections.HashMap

extern fn with_str_clone_ref(s: &str) -> str

fn resolution_line(source: &str, offset: i32) -> i32:
    var line = 1
    let stop = if offset < source.len() as i32: offset else: source.len() as i32
    for i in 0..stop:
        if source[i] == '\n': line = line + 1
    line

fn resolution_column(source: &str, offset: i32) -> i32:
    var start: i32 = if offset - 1 < source.len(): offset - 1 else: source.len() as i32 - 1
    while start >= 0 and source[start] != '\n':
        start = start - 1
    offset - start

// The Sema symbol a MIR-pool symbol names, by text: ids belong to their pool.
fn resolution_sema_sym(sema: &Sema, pool: &InternPool, mir_sym: i32) -> i32:
    if mir_sym == 0: return 0
    sema.pool_lookup_symbol(pool.resolve(mir_sym))

// A body's source: the declaration's own file and text (an imported module
// is not at the main file's offsets).
type ResolutionSite { path: str, source: str }

fn resolution_site(sema: &Sema, pool: &InternPool, body: &MirBody, fallback_path: &str, fallback_source: &str) -> ResolutionSite:
    let sema_sym = resolution_sema_sym(sema, pool, body.fn_sym)
    let found = sema.fn_decl_source_paths.get(sema_sym)
    if found.is_none():
        return ResolutionSite { path: with_str_clone_ref(fallback_path), source: with_str_clone_ref(fallback_source) }
    let path = with_str_clone_ref(found.unwrap())
    for i in 0..sema.source_text_names.len() as i32:
        if sema.source_text_names[i] == path:
            return ResolutionSite { path, source: with_str_clone_ref(sema.source_texts[i]) }
    ResolutionSite { path, source: with_str_clone_ref(fallback_source) }

fn resolution_where(sema: &Sema, site: &ResolutionSite, node: i32) -> str:
    if node <= 0 or node >= sema.ast.node_count(): return site.path ++ " (no AST node)"
    let start = sema.ast.get_start(node)
    site.path ++ f":{resolution_line(site.source, start)}:{resolution_column(site.source, start)} node {node}"

// Sema's answer for the call terminating `bb`, as the record the comparison
// takes. Order: a callable type Sema recorded for the call node is the
// resolution whatever the callee spells (D29: a callable binding preempts a
// module-level function of the same name); then the callee symbol's
// signature, its generic template, Sema's builtin classification of the
// call node, a body of this module; else unresolved.
fn resolution_sema_answer(sema: &Sema, mir_mod: &MirModule, pool: &InternPool, body: &MirBody, bb: i32) -> CalleeResolution:
    let callee_operand = body.term_data0(bb)
    let call_id = body.term_data1(bb)
    let node = body.call_ast_node(call_id)
    var answer = callee_resolution_unknown()
    let node_valid = node > 0 and node < sema.ast.node_count()
    if node_valid:
        let node_sig = sema.resolved_call_sigs.get(node)
        if node_sig.is_some(): answer.node_sig = node_sig.unwrap()
        let callable = sema.call_callable_types.get(node)
        if callable.is_some():
            let fn_tid = sema.callable_any_fn_type(callable.unwrap() as TypeId)
            if fn_tid != 0:
                let resolved = sema.resolve_alias(fn_tid as TypeId)
                answer.kind = CalleeResolutionKind.Callable
                answer.param_count = if sema.get_type_kind(resolved) == TypeKind.TY_EXTERN_FN: -1 else: sema.get_type_d1(resolved)
                return answer
    let sym = mir_call_const_fn_sym(body, callee_operand)
    if sym == 0:
        // A desugared combinator (`opt.map(f)`, `res.or_else(f)`, `filter`)
        // invokes an ARGUMENT's value and carries the combinator call as its
        // node: the callable Sema typed that argument with is the callee's
        // fact. Any other place callee has no Sema resolution and is judged.
        if node_valid and sema.ast.kind(node) == NodeKind.NK_CALL and sema.typed_expr_types.contains(node):
            let argc = body.call_arg_counts[call_id]
            let resolved = sema.has_resolved_call_args(node) != 0
            let count = if resolved: sema.get_resolved_call_arg_count(node) else: sema.ast.get_data2(node)
            var first_callable = 0
            for ai in 0..count:
                let arg = if resolved: sema.get_resolved_call_arg(node, ai) else: sema.ast.get_extra(sema.ast.get_data1(node) + ai)
                if arg <= 0 or arg >= sema.ast.node_count(): continue
                let arg_ty = sema.typed_expr_types.get(arg)
                if arg_ty.is_none(): continue
                let fn_tid = sema.callable_any_fn_type(arg_ty.unwrap() as TypeId)
                if fn_tid == 0: continue
                let resolved_fn = sema.resolve_alias(fn_tid as TypeId)
                let params = if sema.get_type_kind(resolved_fn) == TypeKind.TY_EXTERN_FN: -1 else: sema.get_type_d1(resolved_fn)
                if first_callable == 0: first_callable = resolved_fn
                if params == argc or params < 0:
                    answer.kind = CalleeResolutionKind.Callable
                    answer.param_count = params
                    return answer
            if first_callable != 0:
                answer.kind = CalleeResolutionKind.Callable
                answer.param_count = sema.get_type_d1(first_callable)
        return answer
    answer.name = with_str_clone_ref(pool.resolve(sym))
    let sema_sym = resolution_sema_sym(sema, pool, sym)
    answer.sym = sema_sym
    if sema_sym != 0:
        var sig = sema.get_sig(sema_sym)
        if sig < 0: sig = sema.get_visible_sig(sema_sym)
        if sig >= 0:
            answer.kind = CalleeResolutionKind.Signature
            answer.sig = sig
            answer.param_count = if sig < sema.sig_variadic.len() as i32 and sema.sig_variadic[sig] != 0: -1 else: sema.sig_get_param_count(sig)
            return answer
        if sema.generic_fn_node_for_symbol(sema_sym) != 0:
            answer.kind = CalleeResolutionKind.Generic
            return answer
    if node_valid and sema.call_callee_is_builtin(node) != 0:
        answer.kind = CalleeResolutionKind.Intrinsic
        return answer
    if mir_mod.find_body(sym) >= 0:
        answer.kind = CalleeResolutionKind.Body
        return answer
    answer

fn resolution_violation(report: &AnalysisReport, sema: &Sema, site: &ResolutionSite, body: &MirBody, bb: i32, node: i32, fn_name: &str, message: &str):
    var fact = AnalysisFact.new(AnalysisStage.Mir, AnalysisFactKind.Invariant)
    fact.id = bb
    fact.node = node
    fact.body_sym = body.fn_sym
    fact.symbol = body.fn_sym
    fact.path = site.path.clone()
    fact.name = with_str_clone_ref(fn_name)
    fact.detail = "resolution: " ++ message
    if node > 0 and node < sema.ast.node_count():
        fact.start = sema.ast.get_start(node)
        fact.end = sema.ast.get_end(node)
        fact.line = resolution_line(site.source, fact.start)
        fact.column = resolution_column(site.source, fact.start)
    report.add(move fact)
    report.fail("resolution: " ++ fn_name ++ " at " ++ resolution_where(sema, site, node) ++ ": " ++ message)

// Rule 1–4: every MIR call terminator against Sema's answer for its node.
fn resolution_audit_calls(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    var checked = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0: continue
        let fn_name = with_str_clone_ref(pool.resolve(body.fn_sym))
        var site_ready = false
        var site = ResolutionSite { path: "", source: "" }
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL: continue
            checked = checked + 1
            let answer = resolution_sema_answer(sema, mir_mod, pool, body, bb)
            let message = mir_resolution_check_call(mir_mod, body, bb, &answer)
            if message.len() == 0: continue
            if not site_ready:
                site = resolution_site(sema, pool, body, source_path, source_text)
                site_ready = true
            resolution_violation(report, sema, &site, body, bb, body.call_ast_node(body.term_data1(bb)), fn_name, message)
    checked

// The indices 0..keys.len() ordered by key (heap sort). The stdlib has no
// sort yet; this is the analyzer's own and stays here.
fn resolution_sorted_by_key(keys: &Vec[i64]):
    var order: Vec[i32] = Vec.new()
    let n = keys.len() as i32
    for i in 0..n: order.push(i)
    // Empty and singleton inputs have no heap parent (n / 2 - 1 is -1).
    if n < 2: return order
    // sift(root, heap_size): every pass is the same loop.
    var root = n / 2 - 1
    var heap = n
    var building = true
    while true:
        var r = root
        while r * 2 + 1 < heap:
            var child = r * 2 + 1
            if child + 1 < heap and keys[order[child + 1]] > keys[order[child]]: child = child + 1
            if keys[order[r]] >= keys[order[child]]: break
            let tmp: i32 = order[r]
            order[r] = order[child]
            order[child] = tmp
            r = child
        if building:
            root = root - 1
            if root < 0:
                building = false
                heap = n - 1
                if heap <= 0: break
                let top: i32 = order[0]
                order[0] = order[heap]
                order[heap] = top
                root = 0
        else:
            heap = heap - 1
            if heap <= 0: break
            let top: i32 = order[0]
            order[0] = order[heap]
            order[heap] = top
            root = 0
    order

fn resolution_span_key(file: i32, offset: i32) -> i64: ((file as i64) << 32) | (offset as i64)

// Rule 5: a call Sema resolved (resolved_call_sigs) inside a function MIR
// lowered must have a MIR call fact carrying its node; otherwise MIR
// dropped or re-spelled a call Sema accepted. Spans of the lowered
// declarations locate the enclosing body (uninstantiated generic templates
// have no body and are not judged); the nodes of a body's closures are
// inside its span and their calls are in the module's call facts.
fn resolution_audit_unlowered_calls(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    let lowered_nodes: HashMap[i32, i32] = HashMap.new()
    let elided_nodes: HashMap[i32, i32] = HashMap.new()
    var elided = 0
    let span_keys: Vec[i64] = Vec.new()
    let span_end_keys: Vec[i64] = Vec.new()
    let span_bodies: Vec[i32] = Vec.new()
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        for ci in 0..body.call_ast_nodes.len() as i32:
            let node = body.call_ast_nodes[ci]
            if node > 0: lowered_nodes.insert(node, bi)
        for ei in 0..body.elided_call_nodes.len() as i32:
            elided_nodes.insert(body.elided_call_nodes[ei], bi)
        if body.lowering_failed != 0: continue
        let sema_sym = resolution_sema_sym(sema, pool, body.fn_sym)
        if sema_sym == 0: continue
        let decl = sema.fn_decl_nodes.get(sema_sym)
        if decl.is_none(): continue
        let decl_node = decl.unwrap()
        if decl_node <= 0 or decl_node >= sema.ast.node_count(): continue
        let file = sema.ast.file(decl_node as NodeId) as i32
        span_keys.push(resolution_span_key(file, sema.ast.get_start(decl_node)))
        span_end_keys.push(resolution_span_key(file, sema.ast.get_end(decl_node)))
        span_bodies.push(bi)
    let order = resolution_sorted_by_key(span_keys)
    // prefix_max_end[i]: the greatest end key among order[0..=i], so the
    // backward walk from a binary-search hit stops as soon as no earlier
    // span can still contain the node.
    let prefix_max_end: Vec[i64] = Vec.new()
    var running: i64 = -1
    for i in 0..order.len() as i32:
        let e = span_end_keys[order[i]]
        if e > running: running = e
        prefix_max_end.push(running)
    var checked = 0
    var drop_calls = 0
    let resolved_nodes = sema.resolved_call_sigs.keys()
    for ri in 0..resolved_nodes.len() as i32:
        let node = resolved_nodes[ri]
        if node <= 0 or node >= sema.ast.node_count(): continue
        if sema.ast.kind(node) != NodeKind.NK_CALL: continue
        if lowered_nodes.contains(node): continue
        // MIR stated it materialized this call without a call (the index
        // loop of `for x in v.iter()`).
        if elided_nodes.contains(node):
            elided = elided + 1
            continue
        // An explicit `x.drop()` Sema resolved to the type's Drop impl is
        // materialized by MIR as the drop operation (glue plus field drops),
        // not a call: the same facts MirLower's gate reads (the `drop`
        // method symbol, type_has_drop_impl on the receiver, no argument).
        if resolution_is_drop_impl_call(sema, node):
            drop_calls = drop_calls + 1
            continue
        let file = sema.ast.file(node as NodeId) as i32
        let node_key = resolution_span_key(file, sema.ast.get_start(node))
        let node_end_key = resolution_span_key(file, sema.ast.get_end(node))
        // Last span starting at or before the node.
        var lo = 0
        var hi = order.len() as i32
        while lo < hi:
            let mid = (lo + hi) / 2
            if span_keys[order[mid]] <= node_key: lo = mid + 1
            else: hi = mid
        var i = lo - 1
        var enclosing = -1
        while i >= 0 and prefix_max_end[i] >= node_end_key:
            if span_keys[order[i]] <= node_key and span_end_keys[order[i]] >= node_end_key:
                enclosing = span_bodies[order[i]]
                break
            i = i - 1
        if enclosing < 0: continue
        checked = checked + 1
        let body = &mir_mod.bodies[enclosing]
        let site = resolution_site(sema, pool, body, source_path, source_text)
        let sig = sema.resolved_call_sigs.get(node).unwrap()
        let callee = if sig >= 0 and sig < sema.sig_names.len() as i32: with_str_clone_ref(sema.pool_resolve(sema.sig_names[sig])) else: "<unresolved>"
        let fn_name = with_str_clone_ref(pool.resolve(body.fn_sym))
        resolution_violation(report, sema, &site, body, -1, node, fn_name, "Sema resolved this call node to `" ++ callee ++ f"` (signature {sig}) inside a lowered body, MIR lowered no call carrying the node (D65: a call Sema accepted has exactly one MIR call fact)")
    report.note(f"resolution-audit: drop-impl-calls-materialized-as-drops={drop_calls} calls-mir-states-elided={elided}")
    checked

fn resolution_is_drop_impl_call(sema: &Sema, node: i32) -> bool:
    if sema.ast.get_data2(node) != 0: return false
    let callee = sema.ast.get_data0(node)
    if callee <= 0 or callee >= sema.ast.node_count() or sema.ast.kind(callee) != NodeKind.NK_FIELD_ACCESS: return false
    if sema.ast.get_data1(callee) != sema.syms.drop_items: return false
    let recv_ty = sema.typed_expr_types.get(sema.ast.get_data0(callee))
    recv_ty.is_some() and sema.type_has_drop_impl(recv_ty.unwrap()) != 0

// D65 phase 3 (#1647): a type with its references and raw pointers peeled,
// the nominal a field projection reads through.
fn resolution_peeled(sema: &Sema, tid: i32) -> i32:
    var cur = if tid > 0: sema.resolve_alias(tid as TypeId) as i32 else: 0
    for _ in 0..8:
        let kind = sema.get_type_kind(cur as TypeId)
        if kind != TypeKind.TY_REF and kind != TypeKind.TY_PTR: return cur
        cur = sema.resolve_alias(sema.get_type_d0(cur as TypeId)) as i32
    cur

// Sema's type of a field access's base after its recorded autoderef steps.
fn resolution_field_base_type(sema: &Sema, base_expr: i32) -> i32:
    let count = sema.autoderef_step_counts.get(base_expr) ?? 0
    if count > 0:
        return sema.autoderef_step_tys[(sema.autoderef_step_starts.get(base_expr).unwrap() + count - 1)]
    sema.typed_expr_types.get(base_expr) ?? 0

// Every place lowered from a source field access agrees with Sema's facts
// for that node: it projects the field the node names, its type is the
// type Sema gave the node, and its base is the declaration Sema's base
// expression has after Sema's autoderef (the module-identity and payload
// class of #1446/#1442). A disagreement means MIR picked a place from its
// own lookup.
fn resolution_audit_field_places(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    var checked = 0
    var decls = 0
    var unrecorded = 0
    var in_specializations = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0: continue
        let site = resolution_site(sema, pool, body, source_path, source_text)
        for fi in 0..body.field_place_nodes.len() as i32:
            let node = body.field_place_nodes[fi]
            let place = body.field_place_places[fi]
            let base = body.field_place_bases[fi]
            if node <= 0 or node >= sema.ast.node_count() or place < 0 or place >= body.place_locals.len() as i32: continue
            checked = checked + 1
            if body.instance_sym != 0: in_specializations = in_specializations + 1
            let fn_name = with_str_clone_ref(pool.resolve(body.fn_sym))
            let count = body.place_proj_counts[place]
            let last = body.place_proj_starts[place] + count - 1
            let kind = if count > 0: body.proj_kinds[last] else: -1
            let proj_field = if count > 0: body.proj_d0[last] else: 0
            // Sema's facts for the node in this body's instance: a
            // template's node carries one type in typed_expr_types, the
            // last instance checked (#1647).
            let inst_ty = sema.field_access_type_in_body(body.instance_sym, node)
            if inst_ty <= 0 and body.instance_sym != 0:
                unrecorded = unrecorded + 1
                report.fail(f"resolution: {fn_name} at {resolution_where(sema, &site, node)}: MIR lowered a field place Sema never checked in this instance (field `{pool.resolve(sema.ast.get_data1(node))}`)")
                continue
            let sema_ty = if inst_ty > 0: inst_ty else: sema.typed_expr_types.get(node) ?? 0
            let mir_ty = body.place_sema_types[place]
            let inst_owner = sema.field_access_owner_in_body(body.instance_sym, node)
            // A positional owner (a tuple, a payload) records no owner: in a
            // specialization its base is judged through the field's type.
            let sema_base = if inst_owner > 0: resolution_peeled(sema, inst_owner) else if body.instance_sym != 0: 0 else: resolution_peeled(sema, resolution_field_base_type(sema, sema.ast.get_data0(node)))
            let mir_base = if base >= 0 and base < body.place_sema_types.len() as i32: resolution_peeled(sema, body.place_sema_types[base]) else: 0
            let verdict = mir_field_place_verdict(kind, proj_field, sema.ast.get_data1(node), if mir_ty > 0: sema.resolve_alias(mir_ty as TypeId) as i32 else: 0, if sema_ty > 0: sema.resolve_alias(sema_ty as TypeId) as i32 else: 0, mir_base, sema_base)
            if verdict.len() > 0:
                report.fail(f"resolution: {fn_name} at {resolution_where(sema, &site, node)}: {verdict} (field `{pool.resolve(sema.ast.get_data1(node))}`, MIR {sema.type_name(mir_ty)}, Sema {sema.type_name(sema_ty)})")
            // The projection carries the declaration index Sema resolved the
            // node to in this body's instance (#1647: not a name lookup).
            let sema_decl = sema.field_decl_index_in_body(body.instance_sym, node)
            if kind == ProjKind.PK_FIELD and sema_decl >= 0:
                decls = decls + 1
                let decl_verdict = mir_field_decl_verdict(body.proj_decl_index(last), sema_decl)
                if decl_verdict.len() > 0:
                    report.fail(f"resolution: {fn_name} at {resolution_where(sema, &site, node)}: {decl_verdict} (field `{pool.resolve(sema.ast.get_data1(node))}`)")
    report.note(f"resolution-audit: field-places judged={checked} in-specialization-bodies={in_specializations} declaration-indexes={decls} unrecorded={unrecorded}")
    checked

// Every immutable non-Copy `let` is materialized in Sema's category: a
// binding Sema made a view of a place (D22/D27: a binding names what is
// there) aliases that place in MIR, and one Sema made an owner owns a local.
// An owning local over a view is a second owner of the place's value (the
// #747 field move); an alias over an owner leaves a value nobody drops.
fn resolution_audit_let_bindings(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    var checked = 0
    var aliases = 0
    var views = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0: continue
        let site = resolution_site(sema, pool, body, source_path, source_text)
        for li in 0..body.let_binding_nodes.len() as i32:
            let node = body.let_binding_nodes[li]
            if node <= 0 or node >= sema.ast.node_count(): continue
            if (sema.typed_binding_muts.get(node) ?? 0) != 0: continue
            let bind_ty = sema.typed_binding_types.get(node) ?? 0
            if bind_ty <= 0 or sema.is_copy_frozen(bind_ty as TypeId) != 0: continue
            if sema.drop_consumed_binding_values.contains(sema.ast.get_data1(node)): continue
            checked = checked + 1
            if body.let_binding_aliases[li] != 0: aliases = aliases + 1
            if (sema.view_bound_let_nodes.get(node) ?? 0) == 2: views = views + 1
            let verdict = mir_let_binding_verdict(body.let_binding_aliases[li] != 0, (sema.view_bound_let_nodes.get(node) ?? 0) == 2)
            if verdict.len() > 0:
                report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: `{pool.resolve(sema.ast.get_data0(node))}`: {verdict}")
    report.note(f"resolution-audit: let-bindings judged={checked} mir-aliases={aliases} sema-place-views={views}")
    checked

// Every place lowered from a source index expression agrees with Sema's
// facts for the node in the body's instance (#1647): it is an index
// projection, its type is the element place type Sema checked, and the base
// it indexes is the type Sema's base expression had. A specialization's
// body reads its own instance's record (index_element_in_body), never the
// one type per node typed_expr_types keeps; a node Sema never checked as a
// positional index in that body is itself a violation.
fn resolution_audit_index_places(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    var checked = 0
    var in_specializations = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0: continue
        let site = resolution_site(sema, pool, body, source_path, source_text)
        for ii in 0..body.index_place_nodes.len() as i32:
            let node = body.index_place_nodes[ii]
            let place = body.index_place_places[ii]
            let base = body.index_place_bases[ii]
            if node <= 0 or node >= sema.ast.node_count() or place < 0 or place >= body.place_locals.len() as i32: continue
            checked = checked + 1
            if body.instance_sym != 0: in_specializations = in_specializations + 1
            let count = body.place_proj_counts[place]
            let kind = if count > 0: body.proj_kinds[(body.place_proj_starts[place] + count - 1)] else: -1
            let sema_elem = sema.index_element_in_body(body.instance_sym, node)
            if sema_elem <= 0:
                report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: MIR lowered an index place Sema never checked as a positional index in this body")
                continue
            let sema_ty = sema.resolve_alias(sema_elem as TypeId) as i32
            let mir_ty_raw = body.place_sema_types[place]
            let mir_ty = if mir_ty_raw > 0: sema.resolve_alias(mir_ty_raw as TypeId) as i32 else: 0
            let sema_base = resolution_peeled(sema, sema.index_base_in_body(body.instance_sym, node))
            let mir_base = if base >= 0 and base < body.place_sema_types.len() as i32: resolution_peeled(sema, body.place_sema_types[base]) else: 0
            let verdict = mir_index_place_verdict(kind, mir_ty, sema_ty, sema_ty, mir_base, sema_base)
            if verdict.len() > 0:
                report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: {verdict} (MIR {sema.type_name(mir_ty)}, Sema {sema.type_name(sema_ty)})")
    report.note(f"resolution-audit: index-places judged={checked} in-specialization-bodies={in_specializations} unjudged=0")
    checked

// Every aliasing `let` names a place rooted at a binding Sema recorded as
// an origin of the view it binds (expr_view_dep_*): MIR materializes the
// view Sema proved, it does not pick another place by its own lookup.
fn resolution_audit_view_origins(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    var checked = 0
    var with_origins = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0: continue
        let site = resolution_site(sema, pool, body, source_path, source_text)
        for li in 0..body.let_binding_nodes.len() as i32:
            let place = body.let_binding_places[li]
            if place < 0 or place >= body.place_locals.len() as i32: continue
            let node = body.let_binding_nodes[li]
            if node <= 0 or node >= sema.ast.node_count(): continue
            checked = checked + 1
            let value = sema.ast.get_data1(node)
            let origins = sema.expr_view_dep_count(value)
            if origins > 0: with_origins = with_origins + 1
            let local = body.place_locals[place]
            let root_sym = if local >= 0 and local < body.local_names.len() as i32: body.local_names[local] else: 0
            let root_text = if root_sym != 0: with_str_clone_ref(pool.resolve(root_sym)) else: ""
            var in_origins = false
            for oi in 0..origins:
                if sema.pool_resolve(sema.expr_view_dep_at(value, oi)) == root_text: in_origins = true
            let verdict = mir_view_origin_verdict(origins > 0, root_text.len() > 0 and not root_text.starts_with("$"), in_origins)
            if verdict.len() > 0:
                report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: `{pool.resolve(sema.ast.get_data0(node))}`: {verdict} (MIR root `{root_text}`)")
    report.note(f"resolution-audit: alias-lets judged={checked} with-sema-origins={with_origins}")
    checked

// Every closure capture MIR materialized as a snapshot or as a reference
// to an alias place agrees with Sema's capture mode, and a closure has the
// captures Sema recorded (D62/D63: the capture record is Sema's).
fn resolution_audit_captures(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    var checked = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0: continue
        for ci in 0..body.const_kinds.len() as i32:
            if body.const_kinds[ci] != ConstKind.CK_CLOSURE: continue
            let node = body.const_d0[ci]
            if node <= 0 or node >= sema.ast.node_count() or sema.ast.kind(node) != NodeKind.NK_CLOSURE: continue
            let child_idx = mir_mod.find_body(body.const_d1[ci])
            if child_idx < 0: continue
            let child = &mir_mod.bodies[child_idx]
            let site = resolution_site(sema, pool, body, source_path, source_text)
            let sema_count = sema.closure_capture_summary_count(node)
            var mir_count = 0
            for k in 0..child.anonymous_capture_kinds.len() as i32:
                if child.anonymous_capture_kinds[k] != MIR_CAPTURE_PROTOCOL: mir_count = mir_count + 1
            if mir_count != sema_count:
                report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: the closure has {mir_count} captures in MIR, {sema_count} in Sema's capture record")
                continue
            for k in 0..sema_count:
                if k >= child.anonymous_capture_kinds.len() as i32: break
                checked = checked + 1
                let verdict = mir_capture_verdict(child.anonymous_capture_kinds[k], sema.closure_capture_by_place(node, k))
                if verdict.len() > 0:
                    report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: capture {k} `{sema.pool_resolve(sema.closure_capture_summary_sym(node, k))}`: {verdict}")
    checked

// Phase 4: every call argument that reads a named owned binding transfers
// it the way Sema's signature says (D5/D65): a share-place parameter or an
// extern bit-copy parameter borrows, any other non-Copy parameter consumes.
fn resolution_audit_call_effects(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    var checked = 0
    var judged = 0
    var judged_borrows = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0: continue
        let site = resolution_site(sema, pool, body, source_path, source_text)
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL: continue
            let call_id = body.term_data1(bb)
            if call_id < 0 or call_id >= body.call_arg_starts.len() as i32: continue
            if body.call_intrinsic(call_id) != MirIntrinsic.NONE: continue
            let sig = body.call_sig_index(call_id)
            if sig < 0 or sig >= sema.sig_names.len() as i32: continue
            let argc = body.call_arg_counts[call_id]
            if argc != sema.sig_get_param_count(sig): continue
            let callee = sema.sig_names[sig]
            for ai in 0..argc:
                let op = body.call_arg_operands[(body.call_arg_starts[call_id] + ai)]
                if op < 0 or op >= body.operand_kinds.len() as i32: continue
                let kind = body.operand_kinds[op]
                if kind != OperandKind.OK_MOVE and kind != OperandKind.OK_COPY: continue
                let place = body.operand_d0[op]
                if place < 0 or place >= body.place_locals.len() as i32: continue
                let local = body.place_locals[place]
                let named = local >= 0 and local < body.local_names.len() as i32 and body.local_names[local] != 0
                let param_ty = sema.sig_param_type(sig, ai)
                let owned = param_ty > 0 and sema.is_copy_frozen(param_ty as TypeId) == 0
                let place_ty = body.place_sema_types[place]
                let place_owned = place_ty > 0 and sema.is_copy_frozen(place_ty as TypeId) == 0 and sema.get_type_kind(sema.resolve_alias(place_ty as TypeId)) != TypeKind.TY_REF
                let borrows = sema.sig_param_uses_value_ref_abi(sig, ai) != 0 or sema.extern_param_is_bit_copy(callee, sig, ai) != 0
                checked = checked + 1
                if named and place_owned:
                    judged = judged + 1
                    if borrows: judged_borrows = judged_borrows + 1
                let verdict = mir_call_arg_transfer_verdict(kind, named and place_owned, borrows, owned and not borrows)
                if verdict.len() > 0:
                    report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, body.call_ast_node(call_id))}: call to `{sema.pool_resolve(callee)}` argument {ai}: {verdict}")
    report.note(f"resolution-audit: call-arguments named-owned={judged} into-borrowing-params={judged_borrows}")
    checked

// D65 phase 5 (#1647): every call MIR lowered from a source call whose
// callee is a bare name carries Sema's record of what the name resolved to
// (CallCalleeKind); MirLower dispatches on it and nothing else. A call with
// no record is a call MIR lowered by its own reading of the name.
fn resolution_audit_callee_kinds(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    var checked = 0
    var builtins = 0
    var method_builtins = 0
    var method_intrinsics = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0: continue
        let site = resolution_site(sema, pool, body, source_path, source_text)
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL: continue
            let call_id = body.term_data1(bb)
            if call_id < 0 or call_id >= body.call_arg_starts.len() as i32: continue
            let node = body.call_ast_node(call_id)
            if node <= 0 or node >= sema.ast.node_count() or sema.ast.kind(node) != NodeKind.NK_CALL: continue
            let callee = sema.ast.get_data0(node)
            // #2043: a builtin call carries Sema's record of which builtin
            // it is; codegen's builtin dispatch switches on that record.
            let any_kind = sema.call_callee_kind(node)
            // #2043: a builtin method call carries Sema's intrinsic; a MIR call
            // that names an intrinsic names Sema's (MIR reads it, never decides).
            let sema_intrinsic = sema.method_intrinsic_in_body(body.instance_sym, node)
            if sema_intrinsic != MirIntrinsic.NONE:
                method_intrinsics = method_intrinsics + 1
                let mir_intrinsic = body.call_intrinsic(call_id)
                if mir_intrinsic != MirIntrinsic.NONE and mir_intrinsic != MirIntrinsic.GENERIC_CALL and mir_intrinsic != sema_intrinsic:
                    report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: MIR call intrinsic {mir_intrinsic as i32} disagrees with Sema's {sema_intrinsic as i32}")
            if (sema.call_builtins.get(node) ?? 0) >= CallBuiltin.BoxNew as i32:
                method_builtins = method_builtins + 1
            if any_kind == CallCalleeKind.TypeLevelBuiltin or any_kind == CallCalleeKind.Intrinsic or any_kind == CallCalleeKind.SourceLocation:
                builtins = builtins + 1
                if sema.call_builtin(node) == CallBuiltin.None and not sema.math_builtin_calls.contains(node) and not sema.va_start_calls.contains(node):
                    report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: builtin call carries no Sema builtin kind")
            if sema.ast.kind(callee) != NodeKind.NK_IDENT: continue
            checked = checked + 1
            let kind = sema.call_callee_kind(node)
            if kind == CallCalleeKind.None:
                report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: MIR lowered a call of `{pool.resolve(sema.ast.get_data0(callee))}` Sema recorded no callee kind for")
            // #2043: a builtin's arguments are its MIR operands; a call that
            // carries fewer leaves codegen reading another call's operands.
            if kind == CallCalleeKind.Intrinsic:
                let source_argc = if sema.has_resolved_call_args(node) != 0: sema.get_resolved_call_arg_count(node) else: sema.ast.get_data2(node)
                if body.call_arg_counts[call_id] != source_argc:
                    report.fail(f"resolution: {pool.resolve(body.fn_sym)} at {resolution_where(sema, &site, node)}: builtin `{pool.resolve(sema.ast.get_data0(callee))}` lowered with {body.call_arg_counts[call_id]} MIR operands for {source_argc} arguments")
    report.note(f"resolution-audit: name-callee-kinds judged={checked} builtin-calls={builtins} method-builtin-calls={method_builtins} method-intrinsic-calls={method_intrinsics}")
    checked

// The source call a MIR call lowers: the call node itself, or a pipeline
// stage's call (`x |> f(a)` carries the pipeline node). 0 for anything else.
fn resolution_source_call(sema: &Sema, node: i32) -> i32:
    if node <= 0 or node >= sema.ast.node_count(): return 0
    let kind = sema.ast.kind(node)
    if kind == NodeKind.NK_CALL: return node
    if kind == NodeKind.NK_PIPELINE:
        let stage = sema.ast.get_data1(node)
        if stage > 0 and sema.ast.kind(stage) == NodeKind.NK_CALL: return stage
    0

// Whether some call in `body` hands the value in `place`'s local to
// `conv` (a Sema symbol) as its first argument.
fn resolution_converted(sema: &Sema, pool: &InternPool, body: &MirBody, place: i32, conv: i32) -> bool:
    if place < 0 or place >= body.place_locals.len() as i32: return false
    let local = body.place_locals[place]
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL: continue
        if resolution_sema_sym(sema, pool, mir_call_const_fn_sym(body, body.term_data0(bb))) != conv: continue
        let call_id = body.term_data1(bb)
        if call_id < 0 or call_id >= body.call_arg_starts.len() as i32 or body.call_arg_counts[call_id] < 1: continue
        let op = body.call_arg_operands[body.call_arg_starts[call_id]]
        if op < 0 or op >= body.operand_kinds.len() as i32: continue
        let ok = body.operand_kinds[op]
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE: continue
        let arg_place = body.operand_d0[op]
        if arg_place >= 0 and arg_place < body.place_locals.len() as i32 and body.place_locals[arg_place] == local: return true
    false

// D65 phase 5 (#2043): facade rendering is ordinary calls plus effects, and
// MIR knows nothing about facades. Every direct MIR call lowered from a
// source call is the call Sema resolved: a name Sema resolved to a
// function calls that function (comp_resolved — a facade's C name is its
// bridge or its variadic case, D64/D66), a method call Sema resolved to
// another method than it spells calls Sema's (method_call_fields), and a
// call whose value Sema converts (call_value_conversions — a presented text
// view, §16.2b.8) hands its result to the conversion. A call MIR lowered by
// its own reading of the spelling — the raw C declaration, the pointer as
// the value — disagrees here (red before: a facade call in a pipeline
// stage, which MirLower's facade tables never reached).
fn resolution_audit_resolved_calls(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str) -> i32:
    var checked = 0
    var foreign = 0
    var redirected = 0
    var methods = 0
    var conversions = 0
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0: continue
        var site_ready = false
        var site = ResolutionSite { path: "", source: "" }
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL: continue
            let call_id = body.term_data1(bb)
            if call_id < 0 or call_id >= body.call_arg_starts.len() as i32: continue
            let node = body.call_ast_node(call_id)
            let call = resolution_source_call(sema, node)
            if call == 0: continue
            let callee = sema.ast.get_data0(call)
            var verdict = ""
            let mir_sym = mir_call_const_fn_sym(body, body.term_data0(bb))
            if mir_sym != 0 and body.call_intrinsic(call_id) == MirIntrinsic.NONE:
                let mir_sema_sym = resolution_sema_sym(sema, pool, mir_sym)
                let resolved: i32 = sema.comp_resolved.get(call) ?? 0
                if sema.ast.kind(callee) == NodeKind.NK_IDENT and sema.call_callee_kind(call) == CallCalleeKind.Function:
                    checked = checked + 1
                    let spelled = resolution_sema_sym(sema, pool, sema.ast.get_data0(callee))
                    if resolved != 0 and resolved != spelled: redirected = redirected + 1
                    if sema.ci_syms.contains(resolved) or sema.ci_syms.contains(spelled): foreign = foreign + 1
                    verdict = mir_resolved_callee_verdict(mir_sema_sym, resolved, spelled)
                else if sema.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS and sema.method_call_fields.contains(call):
                    checked = checked + 1
                    methods = methods + 1
                    let spelled = resolution_sema_sym(sema, pool, sema.ast.get_data1(callee))
                    verdict = mir_resolved_callee_verdict(mir_sema_sym, resolved, spelled)
            let conv: i32 = sema.call_value_conversions.get(call) ?? 0
            if verdict.len() == 0 and conv != 0 and (mir_sym == 0 or resolution_sema_sym(sema, pool, mir_sym) != conv):
                conversions = conversions + 1
                verdict = mir_value_conversion_verdict(resolution_converted(sema, pool, body, body.term_data2(bb), conv))
            if verdict.len() == 0: continue
            if not site_ready:
                site = resolution_site(sema, pool, body, source_path, source_text)
                site_ready = true
            let mir_name = if mir_sym != 0: with_str_clone_ref(pool.resolve(mir_sym)) else: "a place"
            let want: i32 = sema.comp_resolved.get(call) ?? 0
            resolution_violation(report, sema, &site, body, bb, call, with_str_clone_ref(pool.resolve(body.fn_sym)), verdict ++ f" (MIR calls `{mir_name}`, Sema resolved `{sema.pool_resolve(want)}`" ++ (if conv != 0: f", converted by `{sema.pool_resolve(conv)}`)" else: ")"))
    report.note(f"resolution-audit: resolved-calls judged={checked} foreign={foreign} redirected={redirected} retargeted-methods={methods} value-conversions={conversions}")
    checked

pub fn analysis_audit_resolution(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str):
    let calls = resolution_audit_calls(report, sema, mir_mod, pool, source_path, source_text)
    let field_places = resolution_audit_field_places(report, sema, mir_mod, pool, source_path, source_text)
    let lets = resolution_audit_let_bindings(report, sema, mir_mod, pool, source_path, source_text)
    let effects = resolution_audit_call_effects(report, sema, mir_mod, pool, source_path, source_text)
    let index_places = resolution_audit_index_places(report, sema, mir_mod, pool, source_path, source_text)
    let view_origins = resolution_audit_view_origins(report, sema, mir_mod, pool, source_path, source_text)
    let captures = resolution_audit_captures(report, sema, mir_mod, pool, source_path, source_text)
    resolution_audit_callee_kinds(report, sema, mir_mod, pool, source_path, source_text)
    resolution_audit_resolved_calls(report, sema, mir_mod, pool, source_path, source_text)
    report.note(f"resolution-audit: field-places={field_places} let-bindings={lets} call-arguments={effects} index-places={index_places} alias-lets={view_origins} closure-captures={captures}")
    let unlowered = resolution_audit_unlowered_calls(report, sema, mir_mod, pool, source_path, source_text)
    report.note(f"resolution-audit: mir-calls={calls} sema-calls-in-lowered-bodies-without-mir-call={unlowered}")
