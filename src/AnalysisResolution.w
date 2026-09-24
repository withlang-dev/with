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
// never lowered. Places/origins (phase 3) and effects (phase 4) follow the
// plan in docs/mir-sema-hardening.md.

use AnalysisTypes
use Ast
use InternPool
use Mir
use Sema

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
fn resolution_sorted_by_key(keys: &Vec[i64]) -> Vec[i32]:
    var order: Vec[i32] = Vec.new()
    let n = keys.len() as i32
    for i in 0..n: order.push(i)
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
    let span_keys: Vec[i64] = Vec.new()
    let span_end_keys: Vec[i64] = Vec.new()
    let span_bodies: Vec[i32] = Vec.new()
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = &mir_mod.bodies[bi]
        for ci in 0..body.call_ast_nodes.len() as i32:
            let node = body.call_ast_nodes[ci]
            if node > 0: lowered_nodes.insert(node, bi)
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
    report.note(f"resolution-audit: drop-impl-calls-materialized-as-drops={drop_calls}")
    checked

fn resolution_is_drop_impl_call(sema: &Sema, node: i32) -> bool:
    if sema.ast.get_data2(node) != 0: return false
    let callee = sema.ast.get_data0(node)
    if callee <= 0 or callee >= sema.ast.node_count() or sema.ast.kind(callee) != NodeKind.NK_FIELD_ACCESS: return false
    if sema.ast.get_data1(callee) != sema.syms.drop_items: return false
    let recv_ty = sema.typed_expr_types.get(sema.ast.get_data0(callee))
    recv_ty.is_some() and sema.type_has_drop_impl(recv_ty.unwrap()) != 0

fn analysis_audit_resolution(report: &AnalysisReport, sema: &Sema, mir_mod: &MirModule, pool: &InternPool, source_path: &str, source_text: &str):
    let calls = resolution_audit_calls(report, sema, mir_mod, pool, source_path, source_text)
    let unlowered = resolution_audit_unlowered_calls(report, sema, mir_mod, pool, source_path, source_text)
    report.note(f"resolution-audit: mir-calls={calls} sema-calls-in-lowered-bodies-without-mir-call={unlowered}")
