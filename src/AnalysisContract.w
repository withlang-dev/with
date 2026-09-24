// AnalysisContract — D51 stage 10 (ruling §63, §2.3; spec §16.2b.2, §18.5):
// the effective modeled foreign contract as analysis facts, the
// suspicious-configuration audit (`audit:contract`, in `audit:all`) and the
// `contract` view.
//
// Read-only over what Sema already holds — facade_resources,
// foreign_contracts, facade_domain_list, facade_call_effects and the
// facade AST items that stated them. Nothing here changes a verdict:
// tooling may be aggressive in proposing, the compiler stays conservative
// in believing (ruling §2.3), so a heuristic below is a report line, never
// a classification. Every fact row carries its provenance (§16.2b.2): the
// facade clause with its file and line, or `default:` with the rule that
// supplied the conservative value.
//
// Facts: one subject row per resource, fn item, domain, callback parameter
// and `use convention` (flags: the CONTRACT_* class), and under it one row
// per effective fact (flags |= CONTRACT_FACT; `parent` is the subject row;
// `index` the parameter it concerns, or -1). `detail` is
// `<key>: <value>  [<provenance>]` on a fact row and the subject's summary
// on a subject row, so the `contract` view is the same rows printed in
// order and a `select:kind=foreign-contract` query reads the same text.

use AnalysisTypes
use Ast
use InternPool
use Sema
use SemaFacade

extern fn with_str_clone_ref(s: &str) -> str

const CONTRACT_RESOURCE: i32 = 1
const CONTRACT_FN: i32 = 2
const CONTRACT_DOMAIN: i32 = 4
const CONTRACT_CALLBACK: i32 = 8
const CONTRACT_CONVENTION: i32 = 16
const CONTRACT_FACT: i32 = 32
const CONTRACT_DEFAULT: i32 = 64

// Where a facade block's nodes are read: its own file's path and text (a
// facade in an imported module is not at the main file's offsets).
type ContractSite {
    path: str,
    source: str,
}

fn contract_site(sema: &Sema, decl: i32, source_path: &str, source_text: &str) -> ContractSite:
    let path = sema.decl_source_path_for_index(decl)
    let source = sema.source_text_for_file_id(sema.decl_source_file_id_for_index(decl))
    ContractSite {
        path: if path.len() > 0: path else: with_str_clone_ref(source_path),
        source: if source.len() > 0: source else: with_str_clone_ref(source_text),
    }

fn contract_line(source: &str, offset: i32) -> i32:
    var line = 1
    let stop = if offset < source.len() as i32: offset else: source.len() as i32
    for i in 0..stop:
        if source[i] == '\n': line = line + 1
    line

fn contract_column(source: &str, offset: i32) -> i32:
    var start: i32 = if offset - 1 < source.len(): offset - 1 else: source.len() as i32 - 1
    while start >= 0 and source[start] != '\n':
        start = start - 1
    offset - start

fn contract_node_line(sema: &Sema, site: &ContractSite, node: i32) -> i32:
    if node <= 0 or node >= sema.ast.node_count(): return 0
    contract_line(site.source, sema.ast.get_start(node))

// `clause:<name>@<path>:<line>` — the facade clause that stated a fact; or
// `profile:<pkg.vN>:<rule>@<path>:<line>` when an adopted convention
// profile's rule stated it (stage 11, §16.2b.12): the rule, in the
// profile's own file.
fn contract_clause_at(sema: &Sema, site: &ContractSite, clause: i32) -> str:
    let rule = facade_clause_profile_rule(sema.ast, clause)
    if rule != 0: return contract_rule_at(sema, rule)
    let name = facade_clause_name(sema.ast.get_data0(clause))
    f"clause:{name}@{site.path}:{contract_node_line(sema, site, clause)}"

fn contract_rule_at(sema: &Sema, rule: i32) -> str:
    let di = sema.facade_rule_profile_decl(rule)
    let site = contract_site(sema, di, "", "")
    f"profile:{sema.facade_rule_profile_name(rule)}:{sema.facade_rule_name(rule)}@{site.path}:{contract_node_line(sema, &site, rule)}"

// The rule that stated an fn item (every clause of a profile's item carries
// it), or 0 for an item the facade wrote.
fn contract_item_profile_rule(sema: &Sema, item: i32) -> i32:
    if sema.ast.kind(item) != NodeKind.NK_FACADE_FN or sema.ast.get_data2(item) == 0: return 0
    facade_clause_profile_rule(sema.ast, sema.ast.get_extra(sema.ast.get_data1(item)))

fn contract_item_at(sema: &Sema, site: &ContractSite, what: &str, item: i32) -> str:
    f"clause:{what}@{site.path}:{contract_node_line(sema, site, item)}"

// The nth clause of `kind` on a facade item (a resource's extra list starts
// with its `wraps` type), or 0. Sema's vectors are filled in clause order,
// so the i-th `consumes` record is the i-th `consumes` clause.
fn contract_clause(sema: &Sema, item: i32, kind: i32, nth: i32) -> i32:
    let start = sema.ast.get_data1(item) + (if sema.ast.kind(item) == NodeKind.NK_FACADE_RESOURCE: 1 else: 0)
    var seen = 0
    for k in 0..sema.ast.get_data2(item):
        let clause = sema.ast.get_extra(start + k)
        if sema.ast.get_data0(clause) != kind: continue
        if seen == nth: return clause
        seen = seen + 1
    0

// The `from` clause naming producer `p`, by its position among the `from`
// clauses (parallel to FacadeResource.producers).
fn contract_from_clause(sema: &Sema, item: i32, pi: i32) -> i32: contract_clause(sema, item, FACADE_CLAUSE_FROM, pi)

fn contract_fact(report: &AnalysisReport, sema: &Sema, site: &ContractSite, parent: i32, flags: i32, node: i32, symbol: i32, owner: i32, index: i32, name: &str, detail: &str) -> i32:
    var fact = AnalysisFact.new(AnalysisStage.Sema, AnalysisFactKind.ForeignContract)
    fact.id = report.facts.len() as i32
    fact.parent = parent
    fact.flags = flags
    fact.symbol = symbol
    fact.owner = owner
    fact.index = index
    fact.node = node
    fact.path = site.path.clone()
    fact.name = with_str_clone_ref(name)
    fact.detail = with_str_clone_ref(detail)
    if node > 0 and node < sema.ast.node_count():
        fact.start = sema.ast.get_start(node)
        fact.end = sema.ast.get_end(node)
        fact.line = contract_line(site.source, fact.start)
        fact.column = contract_column(site.source, fact.start)
    let id = fact.id
    report.add(move fact)
    id

// A fact row: `key: value  [provenance]`, flagged CONTRACT_DEFAULT when the
// provenance is a conservative default rather than a clause.
fn contract_row(report: &AnalysisReport, sema: &Sema, site: &ContractSite, parent: i32, class: i32, node: i32, symbol: i32, owner: i32, index: i32, key: &str, value: &str, provenance: &str) -> i32:
    let flags = class | CONTRACT_FACT | (if provenance.starts_with("default:"): CONTRACT_DEFAULT else: 0)
    contract_fact(report, sema, site, parent, flags, node, symbol, owner, index, key, key ++ ": " ++ value ++ "  [" ++ provenance ++ "]")

fn contract_join(parts: &Vec[str], sep: &str) -> str:
    var out = ""
    for i in 0..parts.len() as i32:
        out = out ++ (if i > 0: with_str_clone_ref(sep) else: "") ++ parts[i].clone()
    out

fn contract_push_unique(xs0: Vec[str], x: &str) -> Vec[str]:
    var xs = xs0
    for i in 0..xs.len() as i32:
        if xs[i] == x: return xs
    xs.push(with_str_clone_ref(x))
    xs

// A list of operations for the view. Compiler runtime seams (`with_*`, which
// no user program calls) are counted, not named, so a library's own
// operations stay readable.
fn contract_list(names: &Vec[str], empty: &str) -> str:
    let shown: Vec[str] = Vec.new()
    var seams = 0
    for i in 0..names.len() as i32:
        if names[i].starts_with("with_"): seams = seams + 1
        else: shown.push(names[i].clone())
    var out = if shown.len() > 0: contract_join(&shown, ", ") else: with_str_clone_ref(empty)
    if seams > 0: out = out ++ f" (and {seams} compiler runtime seams)"
    out

// §57: a parameter is shown as the C header spells it.
fn contract_param(sema: &Sema, fn_sym: i32, pi: i32) -> str:
    let sig = sema.get_sig(fn_sym)
    if sig < 0 or pi < 0 or pi >= sema.sig_get_param_count(sig): return f"param {pi}"
    sema.facade_param_display(fn_sym, sig, pi)

fn contract_resource_name(sema: &Sema, ri: i32) -> str: sema.safe_symbol_text(sema.facade_resources[ri].name)

// The resources a parameter receives, as `Database` / `Database|Statement`.
fn contract_received(sema: &Sema, fn_sym: i32, pi: i32) -> str:
    let recv = sema.facade_param_receives(fn_sym, pi)
    let names: Vec[str] = Vec.new()
    for i in 0..recv.len() as i32: names.push(contract_resource_name(sema, recv[i]))
    contract_join(&names, "|")

fn contract_thread_caps(caps: i32) -> str:
    if caps == 0: return "creator"
    let parts: Vec[str] = Vec.new()
    if (caps & 1) != 0: parts.push("creator")
    if (caps & 2) != 0: parts.push("send")
    if (caps & 4) != 0: parts.push("share")
    if (caps & 8) != 0: parts.push("drop_any_thread")
    contract_join(&parts, " ")

// ── resources ────────────────────────────────────────────────────────────

fn contract_collect_resource(report: &AnalysisReport, sema: &Sema, ri: i32, source_path: &str, source_text: &str):
    let r = &sema.facade_resources[ri]
    let site = contract_site(sema, r.decl, source_path, source_text)
    let rname = contract_resource_name(sema, ri)
    let facade = sema.safe_symbol_text(r.facade)
    let repr = sema.type_name(r.repr_tid)
    let is_ptr = sema.get_type_kind(sema.resolve_alias(r.repr_tid as TypeId)) == TypeKind.TY_PTR
    let shape = if r.init != 0: (if r.movable != 0: "in-place, movable" else: "in-place, pinned") else if is_ptr: "pointer" else: "by-value"
    let facade_id = f"facade:{facade}@{site.path}"
    let at = contract_item_at(sema, &site, "resource", r.node)
    let subject = contract_fact(report, sema, &site, -1, CONTRACT_RESOURCE, r.node, r.name, r.facade, -1, rname,
        f"resource {rname} wraps {repr}; representation: {shape}; {facade_id}; {at}")
    let node = r.node
    let owner = r.facade
    // Production and initialization state (§16.2b.4).
    for pi in 0..r.producers.len() as i32:
        let p = sema.safe_symbol_text(r.producers[pi])
        let clause = contract_from_clause(sema, node, pi)
        let slot = r.out_params[pi]
        let how = if slot >= 0: f"out parameter ({contract_param(sema, r.producers[pi], slot)}); the slot starts NULL and is inspected after the call" else: "direct return; NULL is None"
        let presented = sema.facade_presented(ri, p)
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, clause, r.producers[pi], owner, slot, "producer", f"{p} -> {rname}.{presented}; production: {how}", contract_clause_at(sema, &site, clause))
    if r.preinit != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_PREINIT, 0)
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, clause, r.preinit, owner, -1, "preinit", sema.safe_symbol_text(r.preinit) ++ " constructs the storage", contract_clause_at(sema, &site, clause))
    if r.init != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_INIT, 0)
        let init = sema.safe_symbol_text(r.init)
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, clause, r.init, owner, 0, "init", f"{init} -> {rname}.{sema.facade_presented(ri, init)}; production: in place, Drop armed by init", contract_clause_at(sema, &site, clause))
    if r.producers.len() == 0 and r.init == 0:
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, node, 0, owner, -1, "producer", "none; nothing constructs this resource safely", "default:no from/init clause")
    if r.ok_const != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_OK, 0)
        let c = sema.safe_symbol_text(r.ok_const)
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, clause, r.ok_const, owner, -1, "status", f"ok {c}; a status-returning producer is Result[{rname}, {rname}Error]", contract_clause_at(sema, &site, clause))
    else:
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, node, 0, owner, -1, "status", "none; a producer's failure is None, or (status, None) through an out parameter", "default:no status convention is inferred (§16.2b.4)")
    // Destroy paths (§16.2b.3, §16.2b.5).
    if r.drop != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_DROP, 0)
        let d = sema.safe_symbol_text(r.drop)
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, clause, r.drop, owner, 0, "destroyer", f"{d}; automatic: Drop calls it while the value is live", contract_clause_at(sema, &site, clause))
    for di in 0..r.destroyers.len() as i32:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_DESTROYS, di)
        let d = sema.safe_symbol_text(r.destroyers[di])
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, clause, r.destroyers[di], owner, 0, "destroyer", f"{d} -> move fn {rname}.{sema.facade_presented(ri, d)}; alternate: consumes the value and disarms Drop", contract_clause_at(sema, &site, clause))
    if r.drop == 0 and r.destroyers.len() == 0:
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, node, 0, owner, -1, "destroyer", "none; no destroy path", "default:no drop/destroys clause")
    // Dependency (§16.2b.6).
    if r.independent != 0:
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, r.independent_node, 0, owner, -1, "dependency", "none; independent of every resource its producers receive", contract_clause_at(sema, &site, r.independent_node))
    let owners = sema.facade_owners(ri)
    for oi in 0..owners.len() as i32:
        let o = owners[oi]
        let f = sema.facade_owner_fn(ri, o)
        let fname = sema.safe_symbol_text(f)
        let parents = sema.facade_producer_parents(ri, o)
        var stated = -1
        for bi in 0..r.borrows.len() as i32:
            if r.borrows_owner[bi] == o: stated = bi
        if r.independent != 0:
            continue
        if parents.len() == 0:
            contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, node, f, owner, -1, "dependency", f"none via {fname}; it receives no modeled resource", "default:no resource parameter (§16.2b.6)")
            continue
        for k in 0..parents.len() as i32:
            let pi = parents[k]
            var clause = 0
            for bi in 0..r.borrows.len() as i32:
                if r.borrows_owner[bi] == o and r.borrows[bi] == pi: clause = r.borrows_nodes[bi]
            let prov = if clause != 0: contract_clause_at(sema, &site, clause) else: "default:unknown independence is dependency (§16.2b.6)"
            contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, if clause != 0: clause else: node, f, owner, pi, "dependency", f"parent {contract_received(sema, f, pi)} via {fname} {contract_param(sema, f, pi)}; the product cannot outlive it", prov)
    // Thread capabilities (§16.2b.10).
    if r.thread_caps != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_THREAD, 0)
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, clause, 0, owner, -1, "thread", contract_thread_caps(r.thread_caps), contract_clause_at(sema, &site, clause))
    else:
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, node, 0, owner, -1, "thread", "creator; operations and destruction on the creating thread, ownership stays there", "default:thread creator (§16.2b.10)")
    // Views borrowed from the resource and the operations that invalidate or
    // preserve them (§16.2b.6-7): the relationships the view shows.
    for ci in 0..sema.foreign_contracts.len() as i32:
        let c = &sema.foreign_contracts[ci]
        let fname = sema.safe_symbol_text(c.fn_sym)
        if c.returns_borrow_resource == r.name:
            contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, c.node, c.fn_sym, owner, c.returns_borrow_from, "view", f"Borrowed{rname} from {fname}, dependent on {contract_param(sema, c.fn_sym, c.returns_borrow_from)}", contract_item_at(sema, &site, "fn", c.node))
        else if c.returns_borrow_resource != 0 and c.returns_borrow_domain == 0 and c.returns_borrow_from >= 0 and sema.safe_symbol_text(c.returns_borrow_resource) == "CStr":
            let recv = sema.facade_param_receives(c.fn_sym, c.returns_borrow_from)
            if recv.len() == 1 and recv[0] == ri:
                contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, c.node, c.fn_sym, owner, c.returns_borrow_from, "view", f"CStr from {fname}, dependent on {contract_param(sema, c.fn_sym, c.returns_borrow_from)}", contract_item_at(sema, &site, "fn", c.node))
    var invalidators: Vec[str] = Vec.new()
    var preservers: Vec[str] = Vec.new()
    for ei in 0..sema.facade_call_effects.len() as i32:
        let e = &sema.facade_call_effects[ei]
        let sig = sema.get_sig(e.fn_sym)
        // The raw C signature's entry; a rendered method or constructor
        // entry indexes its parameters without the receiver or out slot.
        if sig < 0 or sig != e.sig: continue
        for pi in 0..sema.sig_get_param_count(sig):
            let recv = sema.facade_param_receives(e.fn_sym, pi)
            if recv.len() != 1 or recv[0] != ri: continue
            if (e.touch_params & sema_param_origin_bit(pi)) != 0: invalidators = contract_push_unique(move invalidators, sema.safe_symbol_text(e.fn_sym))
            else: preservers = contract_push_unique(move preservers, sema.safe_symbol_text(e.fn_sym))
    if sema.facade_call_effects.len() == 0 and sema.diags.has_errors():
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, node, 0, owner, -1, "invalidation", "not indexed; diagnostics stopped the call-effect index", "default:diagnostics present")
    else:
        contract_row(report, sema, &site, subject, CONTRACT_RESOURCE, node, 0, owner, -1, "invalidation", "views invalidated by: " ++ contract_list(&invalidators, "no operation") ++ "; preserved across: " ++ contract_list(&preservers, "none"), "default:unknown effect is invalidate; `preserves param N` states otherwise (§16.2b.7)")

// ── fn items ─────────────────────────────────────────────────────────────

fn contract_collect_fn(report: &AnalysisReport, sema: &Sema, ci: i32, source_path: &str, source_text: &str):
    let c = &sema.foreign_contracts[ci]
    let site = contract_site(sema, c.decl, source_path, source_text)
    let fname = sema.safe_symbol_text(c.fn_sym)
    let facade = sema.safe_symbol_text(c.facade)
    let sig = sema.get_sig(c.fn_sym)
    let node = c.node
    let owner = c.facade
    let count = if sig >= 0: sema.sig_get_param_count(sig) else: 0
    let rule = contract_item_profile_rule(sema, node)
    let at = if rule != 0: contract_rule_at(sema, rule) else: contract_item_at(sema, &site, "fn", node)
    let subject = contract_fact(report, sema, &site, -1, CONTRACT_FN, node, c.fn_sym, owner, -1, fname,
        f"fn {fname}; facade:{facade}@{site.path}; {at}")
    if sig < 0:
        contract_row(report, sema, &site, subject, CONTRACT_FN, node, c.fn_sym, owner, -1, "declaration", "not in scope; the facade names no imported declaration", "default:unverified item (§16.2b.13)")
        return
    // Resource-clause roles: the item describes an operation a resource names.
    for ri in 0..sema.facade_resources.len() as i32:
        let r = &sema.facade_resources[ri]
        let rname = contract_resource_name(sema, ri)
        if sema.facade_same_fn(r.drop, c.fn_sym): contract_row(report, sema, &site, subject, CONTRACT_FN, r.node, r.name, owner, 0, "role", f"automatic destroyer of {rname}", contract_item_at(sema, &site, "resource", r.node))
        for di in 0..r.destroyers.len() as i32:
            if sema.facade_same_fn(r.destroyers[di], c.fn_sym): contract_row(report, sema, &site, subject, CONTRACT_FN, r.node, r.name, owner, 0, "role", f"alternate destroyer of {rname}", contract_item_at(sema, &site, "resource", r.node))
        for pi in 0..r.producers.len() as i32:
            if sema.facade_same_fn(r.producers[pi], c.fn_sym): contract_row(report, sema, &site, subject, CONTRACT_FN, r.node, r.name, owner, -1, "role", f"producer of {rname}", contract_item_at(sema, &site, "resource", r.node))
        if sema.facade_same_fn(r.init, c.fn_sym): contract_row(report, sema, &site, subject, CONTRACT_FN, r.node, r.name, owner, 0, "role", f"in-place initializer of {rname}", contract_item_at(sema, &site, "resource", r.node))
    // Parameter effects (§16.2b.5): the strongest clause naming each
    // parameter, else the described-fn lend.
    let lend_clause = contract_clause(sema, node, FACADE_CLAUSE_LEND, 0)
    let destroys_clause = contract_clause(sema, node, FACADE_CLAUSE_DESTROYS, 0)
    for pi in 0..count:
        let shown = contract_param(sema, c.fn_sym, pi)
        let received = contract_received(sema, c.fn_sym, pi)
        let recv_note = if received.len() > 0: f"; receives {received}" else: ""
        var stated = false
        if pi == 0 and c.destroys != 0:
            contract_row(report, sema, &site, subject, CONTRACT_FN, destroys_clause, c.fn_sym, owner, pi, "effect", f"{shown}: destroys{recv_note}", contract_clause_at(sema, &site, destroys_clause))
            stated = true
        for k in 0..c.consumes.len() as i32:
            if c.consumes[k] != pi: continue
            let clause = contract_clause(sema, node, FACADE_CLAUSE_CONSUMES, k)
            let by = c.consumes_destroyed_by[k]
            let path = if by >= 0: f"; destroyed by the callback {contract_param(sema, c.fn_sym, by)}" else: "; C owns it from the call on"
            contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, pi, "effect", f"{shown}: consumes{path}{recv_note}", contract_clause_at(sema, &site, clause))
            stated = true
        for k in 0..c.retains.len() as i32:
            if c.retains[k] != pi: continue
            let clause = contract_clause(sema, node, FACADE_CLAUSE_RETAINS, k)
            let by = c.retains_by[k]
            let holder = contract_received(sema, c.fn_sym, by)
            let held = if holder.len() > 0: f"retained by {holder} ({contract_param(sema, c.fn_sym, by)})" else: f"retained by {contract_param(sema, c.fn_sym, by)}, which receives no modeled resource"
            contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, pi, "effect", f"{shown}: {held}{recv_note}", contract_clause_at(sema, &site, clause))
            stated = true
        for k in 0..c.callback_consumes.len() as i32:
            if c.callback_consumes[k] != pi: continue
            let clause = contract_clause(sema, node, FACADE_CLAUSE_CALLBACK_CONSUMES, k)
            contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, pi, "effect", f"{shown}: the callback receives ownership of what C passes it", contract_clause_at(sema, &site, clause))
            stated = true
        for k in 0..c.consumes_destroyed_by.len() as i32:
            if c.consumes_destroyed_by[k] != pi: continue
            let clause = contract_clause(sema, node, FACADE_CLAUSE_CONSUMES, k)
            contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, pi, "effect", f"{shown}: callback, the destroy path of the consumed {contract_param(sema, c.fn_sym, c.consumes[k])}", contract_clause_at(sema, &site, clause))
            stated = true
        for ri in 0..sema.facade_resources.len() as i32:
            let r = &sema.facade_resources[ri]
            for k in 0..r.producers.len() as i32:
                if sema.facade_same_fn(r.producers[k], c.fn_sym) and r.out_params[k] == pi:
                    let produced = contract_resource_name(sema, ri)
                    contract_row(report, sema, &site, subject, CONTRACT_FN, r.node, c.fn_sym, owner, pi, "effect", f"{shown}: out parameter producing {produced}", contract_item_at(sema, &site, "from", contract_from_clause(sema, r.node, k)))
                    stated = true
        if stated: continue
        if sema.facade_param_is_callable(sig, pi):
            contract_row(report, sema, &site, subject, CONTRACT_FN, node, c.fn_sym, owner, pi, "effect", f"{shown}: callback, borrowed for the call's scope; what C passes it cannot escape", "default:callback-scope borrow (§16.2b.9)")
        else if lend_clause != 0:
            contract_row(report, sema, &site, subject, CONTRACT_FN, lend_clause, c.fn_sym, owner, pi, "effect", f"{shown}: lend, an assertion about foreign behavior{recv_note}", contract_clause_at(sema, &site, lend_clause))
        else:
            contract_row(report, sema, &site, subject, CONTRACT_FN, node, c.fn_sym, owner, pi, "effect", f"{shown}: lend, the described fn's assertion{recv_note}", "default:a described fn lends its parameters (§16.2b.5)")
    // The result (§16.2b.6-8).
    let ret = sema.type_name(sema.sig_return_type(sig))
    if c.returns_borrow_resource != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_RETURNS_BORROW, 0)
        let what = sema.safe_symbol_text(c.returns_borrow_resource)
        let origin = if c.returns_borrow_domain != 0: "domain " ++ sema.safe_symbol_text(c.returns_borrow_domain) else: contract_param(sema, c.fn_sym, c.returns_borrow_from) ++ (if contract_received(sema, c.fn_sym, c.returns_borrow_from).len() > 0: " (" ++ contract_received(sema, c.fn_sym, c.returns_borrow_from) ++ ")" else: ", a lent C string")
        let shape = if what == "CStr": "Option[CStr], nullable" else: f"Option[Borrowed{what}], nullable, no Drop"
        contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, c.returns_borrow_from, "returns", f"borrow {what} from {origin}; {shape}", contract_clause_at(sema, &site, clause))
    else if c.returns_borrow_record != 0:
        // D66 (§16.2b.6): a view of an imported record, from a resource
        // parameter or a foreign-state domain.
        let clause = contract_clause(sema, node, FACADE_CLAUSE_RETURNS_BORROW, 0)
        let what = sema.safe_symbol_text(c.returns_borrow_record)
        let origin = if c.returns_borrow_domain != 0: "domain " ++ sema.safe_symbol_text(c.returns_borrow_domain) else: contract_param(sema, c.fn_sym, c.returns_borrow_from) ++ " (" ++ contract_received(sema, c.fn_sym, c.returns_borrow_from) ++ ")"
        contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, c.returns_borrow_from, "returns", f"borrow {what} from {origin}; Option[&{what}], nullable, a view of the record, no Drop; its pointer fields stay raw", contract_clause_at(sema, &site, clause))
    else if c.returns_static_tid != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_RETURNS_STATIC, 0)
        contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, -1, "returns", "static CStr; valid for the whole program, no origin", contract_clause_at(sema, &site, clause))
    else if sema.ci_type_requires_raw_contract(sema.sig_return_type(sig)) != 0:
        contract_row(report, sema, &site, subject, CONTRACT_FN, node, c.fn_sym, owner, -1, "returns", f"{ret}; raw: no origin is stated, so the pointer stays unsafe and nullable", "default:unknown origin is not invented (§16.2b.7)")
    else:
        contract_row(report, sema, &site, subject, CONTRACT_FN, node, c.fn_sym, owner, -1, "returns", ret, "default:as declared")
    // Invalidation and preservation (§16.2b.7).
    for k in 0..c.preserves_params.len() as i32:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_PRESERVES, k)
        contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, c.preserves_params[k], "preserves", contract_param(sema, c.fn_sym, c.preserves_params[k]) ++ "; views of it survive this call", contract_clause_at(sema, &site, clause))
    for k in 0..c.preserves_domains.len() as i32:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_PRESERVES, c.preserves_params.len() as i32 + k)
        contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, -1, "preserves", "domain " ++ sema.safe_symbol_text(c.preserves_domains[k]), contract_clause_at(sema, &site, clause))
    let touched: Vec[str] = Vec.new()
    for pi in 0..count:
        if sema.facade_param_receives(c.fn_sym, pi).len() != 1: continue
        var kept = false
        for k in 0..c.preserves_params.len() as i32:
            if c.preserves_params[k] == pi: kept = true
        if not kept: touched.push(f"{contract_received(sema, c.fn_sym, pi)} ({contract_param(sema, c.fn_sym, pi)})")
    let domains = sema.facade_domains_touched(sema.facade_fn_file(c.fn_sym), ci)
    for k in 0..domains.len() as i32:
        touched.push("domain " ++ sema.safe_symbol_text(sema.facade_domain_list[domains[k]].name))
    if touched.len() > 0:
        contract_row(report, sema, &site, subject, CONTRACT_FN, node, c.fn_sym, owner, -1, "invalidates", contract_join(&touched, ", "), "default:unknown effect is invalidate (§16.2b.7)")
    // Presentation (§16.2b.11).
    let hosts = sema.facade_method_host(c.fn_sym)
    if c.of_resource != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_OF, 0)
        contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.of_resource, owner, 0, "presentation", "of " ++ sema.safe_symbol_text(c.of_resource), contract_clause_at(sema, &site, clause))
    if c.rename != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_RENAME, 0)
        contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.rename, owner, -1, "presentation", "rename " ++ sema.safe_symbol_text(c.rename), contract_clause_at(sema, &site, clause))
    // The failed state (§16.2b.4, #1612).
    if c.valid_on_failed != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_VALID_ON_FAILED, 0)
        contract_row(report, sema, &site, subject, CONTRACT_FN, clause, c.fn_sym, owner, -1, "failed-state", "valid on the failed-state resource too (presented on Failed<R>)", contract_clause_at(sema, &site, clause))
    if hosts.len() == 1 and not sema.facade_fn_is_resource_op(c.fn_sym):
        let host = contract_resource_name(sema, hosts[0])
        let presented = sema.facade_presented(hosts[0], fname)
        let surface = if c.destroys != 0: f"move fn {host}.{presented}" else: f"{host}.{presented}"
        contract_row(report, sema, &site, subject, CONTRACT_FN, node, c.fn_sym, owner, 0, "presentation", f"{surface}" ++ (if presented == fname: "; the C name is kept, no unambiguous shortening" else: ""), if c.rename != 0: "clause:rename" else: "default:presentation sugar from the resource prefix (§16.2b.11)")
    else if hosts.len() > 1:
        contract_row(report, sema, &site, subject, CONTRACT_FN, node, c.fn_sym, owner, 0, "presentation", "not presented; param 0 receives a representation several resources wrap and no `of` assigns it", "default:ambiguous assignment fails closed (§16.2b.3)")
    else if count == 0 or hosts.len() == 0:
        contract_row(report, sema, &site, subject, CONTRACT_FN, node, c.fn_sym, owner, -1, "presentation", "the C name is the surface; no resource receives param 0", "default:presentation sugar only groups by resource (§16.2b.11)")
    // Callback parameters (§16.2b.9-10): a subject of their own.
    for pi in 0..count:
        if not sema.facade_param_is_callable(sig, pi): continue
        contract_collect_callback(report, sema, ci, pi, &site)

fn contract_collect_callback(report: &AnalysisReport, sema: &Sema, ci: i32, pi: i32, site: &ContractSite):
    let c = &sema.foreign_contracts[ci]
    let fname = sema.safe_symbol_text(c.fn_sym)
    let node = c.node
    let owner = c.facade
    let shown = contract_param(sema, c.fn_sym, pi)
    let at = contract_item_at(sema, site, "fn", node)
    let subject = contract_fact(report, sema, site, -1, CONTRACT_CALLBACK, node, c.fn_sym, owner, pi, f"{fname}:{pi}", f"callback {shown} of {fname}; {at}")
    var role_stated = false
    for k in 0..c.consumes_destroyed_by.len() as i32:
        if c.consumes_destroyed_by[k] != pi: continue
        let clause = contract_clause(sema, node, FACADE_CLAUSE_CONSUMES, k)
        contract_row(report, sema, site, subject, CONTRACT_CALLBACK, clause, c.fn_sym, owner, pi, "role", f"destroy path of the consumed {contract_param(sema, c.fn_sym, c.consumes[k])}; With destroys it through no other path", contract_clause_at(sema, site, clause))
        role_stated = true
    for k in 0..c.retains.len() as i32:
        if c.retains[k] != pi: continue
        let clause = contract_clause(sema, node, FACADE_CLAUSE_RETAINS, k)
        let holder = contract_received(sema, c.fn_sym, c.retains_by[k])
        contract_row(report, sema, site, subject, CONTRACT_CALLBACK, clause, c.fn_sym, owner, pi, "role", "retained by " ++ (if holder.len() > 0: holder else: "no modeled resource") ++ f" ({contract_param(sema, c.fn_sym, c.retains_by[k])}); it lives as long as its owner", contract_clause_at(sema, site, clause))
        role_stated = true
    for k in 0..c.callback_consumes.len() as i32:
        if c.callback_consumes[k] != pi: continue
        let clause = contract_clause(sema, node, FACADE_CLAUSE_CALLBACK_CONSUMES, k)
        contract_row(report, sema, site, subject, CONTRACT_CALLBACK, clause, c.fn_sym, owner, pi, "ownership", "the callback owns what C passes it", contract_clause_at(sema, site, clause))
    if not role_stated:
        contract_row(report, sema, site, subject, CONTRACT_CALLBACK, node, c.fn_sym, owner, pi, "role", "used during this call only; not retained", "default:callback-scope borrow (§16.2b.9)")
    // Nullability (§16.2b.8, #1618): the paired callback, absent with its
    // userdata.
    for k in 0..c.nullable_params.len() as i32:
        if c.nullable_params[k] != pi: continue
        let clause = contract_clause(sema, node, FACADE_CLAUSE_NULLABLE, k)
        contract_row(report, sema, site, subject, CONTRACT_CALLBACK, clause, c.fn_sym, owner, pi, "nullability", "nullable; None for the callback is None for its userdata", contract_clause_at(sema, site, clause))
    if c.callback_thread_any != 0:
        let clause = contract_clause(sema, node, FACADE_CLAUSE_CALLBACK_THREAD, 0)
        contract_row(report, sema, site, subject, CONTRACT_CALLBACK, clause, c.fn_sym, owner, pi, "thread", "any; captured With state must be Send and Sync", contract_clause_at(sema, site, clause))
    else:
        contract_row(report, sema, site, subject, CONTRACT_CALLBACK, node, c.fn_sym, owner, pi, "thread", "the registering thread", "default:callback executes where it was registered (§16.2b.10)")
    contract_row(report, sema, site, subject, CONTRACT_CALLBACK, node, c.fn_sym, owner, pi, "reentrancy", "the call may invoke it; its captures' origins are affected as their capture modes allow", "default:absent a facade assertion the call is reentrant (§16.2b.9)")

// ── domains and conventions ──────────────────────────────────────────────

fn contract_collect_domain(report: &AnalysisReport, sema: &Sema, di: i32, source_path: &str, source_text: &str):
    let d = &sema.facade_domain_list[di]
    // A domain's block is the facade it was declared in; find that block's
    // declaration through a resource or item of the same facade, else the
    // main file.
    var decl = -1
    for ri in 0..sema.facade_resources.len() as i32:
        if sema.facade_resources[ri].facade == d.facade: decl = sema.facade_resources[ri].decl
    for ci in 0..sema.foreign_contracts.len() as i32:
        if decl < 0 and sema.foreign_contracts[ci].facade == d.facade: decl = sema.foreign_contracts[ci].decl
    let site = if decl >= 0: contract_site(sema, decl, source_path, source_text) else: ContractSite { path: with_str_clone_ref(source_path), source: with_str_clone_ref(source_text) }
    let dname = sema.safe_symbol_text(d.name)
    let kind = sema.safe_symbol_text(d.kind)
    let facade = sema.safe_symbol_text(d.facade)
    let at = contract_item_at(sema, &site, "domain", d.node)
    let origin = sema.safe_symbol_text(d.origin_sym)
    let subject = contract_fact(report, sema, &site, -1, CONTRACT_DOMAIN, d.node, d.name, d.facade, -1, dname,
        f"domain {dname} {kind}; origin {origin}; facade:{facade}@{site.path}; {at}")
    let scope = if kind == "thread": "views inherit the thread restriction" else if kind == "static": "static data does not participate in invalidation" else if kind == "process": "process-wide state" else: "state of a resource"
    contract_row(report, sema, &site, subject, CONTRACT_DOMAIN, d.node, d.name, d.facade, -1, "scope", f"{kind}; {scope}", contract_item_at(sema, &site, "domain", d.node))
    contract_row(report, sema, &site, subject, CONTRACT_DOMAIN, d.node, d.name, d.facade, -1, "library", f"{d.files.len() as i32} imported translation unit(s) whose every operation touches it unless it preserves it", "default:the coarse library domain (§16.2b.7)")
    let views: Vec[str] = Vec.new()
    var preservers: Vec[str] = Vec.new()
    for ci in 0..sema.foreign_contracts.len() as i32:
        let c = &sema.foreign_contracts[ci]
        if c.returns_borrow_domain == d.name: views.push(sema.safe_symbol_text(c.fn_sym))
        for k in 0..c.preserves_domains.len() as i32:
            if c.preserves_domains[k] == d.name: preservers = contract_push_unique(move preservers, sema.safe_symbol_text(c.fn_sym))
    var invalidators: Vec[str] = Vec.new()
    for ei in 0..sema.facade_call_effects.len() as i32:
        let e = &sema.facade_call_effects[ei]
        if e.sig != sema.get_sig(e.fn_sym): continue
        for k in 0..e.touch_domains.len() as i32:
            if e.touch_domains[k] == di: invalidators = contract_push_unique(move invalidators, sema.safe_symbol_text(e.fn_sym))
    let borrowed = if views.len() > 0: "CStr borrowed by " ++ contract_join(&views, ", ") else: "none borrowed"
    contract_row(report, sema, &site, subject, CONTRACT_DOMAIN, d.node, d.name, d.facade, -1, "views", borrowed, "default:a view names its domain with `returns borrow CStr from domain` (§16.2b.7)")
    if sema.facade_call_effects.len() == 0 and sema.diags.has_errors():
        contract_row(report, sema, &site, subject, CONTRACT_DOMAIN, d.node, d.name, d.facade, -1, "invalidation", "not indexed; diagnostics stopped the call-effect index", "default:diagnostics present")
    else:
        contract_row(report, sema, &site, subject, CONTRACT_DOMAIN, d.node, d.name, d.facade, -1, "invalidation", "invalidated by: " ++ contract_list(&invalidators, "no operation") ++ "; preserved across: " ++ contract_list(&preservers, "none"), "default:unknown effect is invalidate; `preserves domain D` states otherwise (§16.2b.7)")

// A `use convention` item is read in its facade block's file.
fn contract_convention_site(sema: &Sema, item: i32, source_path: &str, source_text: &str) -> ContractSite:
    let di = sema.facade_convention_decl(item)
    if di >= 0: return contract_site(sema, di, source_path, source_text)
    ContractSite { path: with_str_clone_ref(source_path), source: with_str_clone_ref(source_text) }

fn contract_collect_conventions(report: &AnalysisReport, sema: &Sema, source_path: &str, source_text: &str):
    for k in 0..sema.facade_convention_nodes.len() as i32:
        let node = sema.facade_convention_nodes[k]
        let site = contract_convention_site(sema, node, source_path, source_text)
        let start = sema.ast.get_data0(node)
        let parts: Vec[str] = Vec.new()
        for i in 0..sema.ast.get_data1(node): parts.push(sema.safe_symbol_text(sema.ast.get_extra(start + i)))
        let path = contract_join(&parts, ".")
        let at = contract_item_at(sema, &site, "use convention", node)
        let subject = contract_fact(report, sema, &site, -1, CONTRACT_CONVENTION, node, 0, 0, -1, path, f"use convention {path}; {at}")
        // One row per outcome of the profile's rules (stage 11, §16.2b.12):
        // what each contributed, and why the others did not.
        let recs = sema.facade_profile_matches(node)
        if recs.len() == 0:
            contract_row(report, sema, &site, subject, CONTRACT_CONVENTION, node, 0, 0, -1, "profile", "adopted; no rule was applied (the profile did not resolve, or has no rules)", "default:no profile fact exists")
        for m in 0..recs.len() as i32:
            let (rule, status, subject_node, cands) = sema.facade_profile_match(recs[m])
            let rname = sema.facade_rule_name(rule)
            let template = sema.facade_rule_template_text(rule)
            let what = sema.facade_profile_subject_text(rule, subject_node)
            let prov = contract_rule_at(sema, rule)
            if status == FACADE_PROFILE_APPLIED:
                let named = if sema.facade_rule_is_fn(rule): "" else: ": " ++ sema.facade_profile_names(&cands)
                contract_row(report, sema, &site, subject, CONTRACT_CONVENTION, recs[m], rule, 0, -1, "rule", f"{rname} ({template}) applied to {what}{named}", prov)
            else if status == FACADE_PROFILE_AMBIGUOUS:
                let who = if sema.facade_rule_is_fn(rule): f"rules {sema.facade_profile_names(&cands)} all match {what}" else: f"{rname} ({template}) matches {cands.len() as i32} candidates for {what}: {sema.facade_profile_names(&cands)}"
                contract_row(report, sema, &site, subject, CONTRACT_CONVENTION, recs[m], rule, 0, -1, "rule", f"{who}; ambiguous, contributes nothing (§16.2b.12)", prov)
            else if status == FACADE_PROFILE_SHADOWED:
                let by = if sema.facade_rule_is_fn(rule): "an fn item" else: "clause `" ++ facade_clause_name(sema.ast.get_data0(cands[1])) ++ "`"
                let matched = if sema.facade_rule_is_fn(rule): what else: f"{sema.safe_symbol_text(cands[0])} for {what}"
                contract_row(report, sema, &site, subject, CONTRACT_CONVENTION, recs[m], rule, 0, -1, "rule", f"{rname} ({template}) matched {matched}; shadowed by {by} at {contract_where(&site, sema, cands[1])}, the facade's explicit statement wins (§16.2b.2)", prov)
            else:
                contract_row(report, sema, &site, subject, CONTRACT_CONVENTION, recs[m], rule, 0, -1, "rule", f"{rname} ({template}) matched nothing" ++ (if subject_node != 0 and not sema.facade_rule_is_fn(rule): " for " ++ what else: ""), prov)

fn analysis_collect_foreign_contracts(report: &AnalysisReport, sema: &Sema, source_path: &str, source_text: &str):
    for di in 0..sema.facade_domain_list.len() as i32:
        contract_collect_domain(report, sema, di, source_path, source_text)
    for ri in 0..sema.facade_resources.len() as i32:
        contract_collect_resource(report, sema, ri, source_path, source_text)
    for ci in 0..sema.foreign_contracts.len() as i32:
        contract_collect_fn(report, sema, ci, source_path, source_text)
    contract_collect_conventions(report, sema, source_path, source_text)

// ── audit:contract (ruling §63) ──────────────────────────────────────────
//
// Each violation names the clause and line it reads, and the clause that
// resolves it. The last check is the ruling's advisory: a name and shape
// that resemble a destroying operation, exposed as a lend. It proposes and
// decides nothing — the contract, the classification and the capability
// are unchanged — and an explicit `lend` records the author's review and
// silences it.

fn contract_destroy_words() -> Vec[str]:
    let words: Vec[str] = Vec.new()
    for w in ["close", "free", "destroy", "release", "finalize", "delete", "unref", "dispose", "dealloc", "shutdown", "terminate", "term", "fini", "deinit", "teardown", "cleanup", "kill", "end", "finish", "exit"]:
        words.push(with_str_clone_ref(w))
    words

// Whether a C name has a segment (between `_`, digits aside) that begins
// with a destroy word: `sqlite3_close_v2`, `closedir`, `db_free_all`.
fn contract_name_resembles_destroyer(name: &str) -> str:
    let words = contract_destroy_words()
    var seg = ""
    var i = 0
    let n = name.len() as i32
    while i <= n:
        if i == n or name[i] == '_':
            if seg.len() > 0:
                for w in 0..words.len() as i32:
                    if seg.starts_with(words[w]): return words[w].clone()
            seg = ""
        else:
            seg = seg ++ name.slice(i, i + 1)
        i = i + 1
    ""

fn contract_where(site: &ContractSite, sema: &Sema, node: i32) -> str: f"{site.path}:{contract_node_line(sema, site, node)}"

fn analysis_audit_contract(report: &AnalysisReport, sema: &Sema, source_path: &str, source_text: &str):
    var advisories = 0
    for ri in 0..sema.facade_resources.len() as i32:
        let r = &sema.facade_resources[ri]
        let site = contract_site(sema, r.decl, source_path, source_text)
        let rname = contract_resource_name(sema, ri)
        let at = contract_where(&site, sema, r.node)
        // Producer with no valid destroy path (§63, §16.2b.3).
        if (r.producers.len() > 0 or r.init != 0) and r.drop == 0:
            let p = sema.safe_symbol_text(if r.init != 0: r.init else: r.producers[0])
            let clause = if r.init != 0: contract_clause(sema, r.node, FACADE_CLAUSE_INIT, 0) else: contract_from_clause(sema, r.node, 0)
            let pat = contract_where(&site, sema, clause)
            if r.destroyers.len() == 0:
                report.fail(f"contract: resource '{rname}' ({at}): producer '{p}' (`from`/`init` at {pat}) has no destroy path; resolve: state `drop <fn>` (automatic) or `destroys <fn>` on the resource (§63, §16.2b.3)")
            else:
                report.fail(f"contract: resource '{rname}' ({at}): producer '{p}' (`from`/`init` at {pat}) has only `destroys` operations and no automatic path, so a value dropped while live leaks; resolve: name a unary destroyer as `drop <fn>` (§63, §16.2b.3)")
        // Illegal thread capability combination (§16.2b.10, ruling §48-§50).
        if r.thread_caps != 0:
            let clause = contract_clause(sema, r.node, FACADE_CLAUSE_THREAD, 0)
            let tat = contract_where(&site, sema, clause)
            let caps = contract_thread_caps(r.thread_caps)
            if (r.thread_caps & 2) != 0 and (r.thread_caps & 8) == 0:
                report.fail(f"contract: resource '{rname}' (`thread {caps}` at {tat}): `send` without `drop_any_thread` — With v1 does not marshal destruction back to the creator thread; resolve: `thread send drop_any_thread`, or drop `send` (§63, §16.2b.10)")
            if (r.thread_caps & 1) != 0 and (r.thread_caps & 6) != 0:
                report.fail(f"contract: resource '{rname}' (`thread {caps}` at {tat}): `creator` binds operations, destruction and ownership to the creating thread, which `send`/`share` contradict; resolve: state the capabilities without `creator`, or `creator` alone (§63, §16.2b.10)")
    for ci in 0..sema.foreign_contracts.len() as i32:
        let c = &sema.foreign_contracts[ci]
        let site = contract_site(sema, c.decl, source_path, source_text)
        let fname = sema.safe_symbol_text(c.fn_sym)
        let at = contract_where(&site, sema, c.node)
        let sig = sema.get_sig(c.fn_sym)
        if sig < 0: continue
        // Destroying operation still presented as a borrow (§63).
        var destroyer_of = ""
        for ri in 0..sema.facade_resources.len() as i32:
            let r = &sema.facade_resources[ri]
            if sema.facade_same_fn(r.drop, c.fn_sym): destroyer_of = contract_resource_name(sema, ri)
            for di in 0..r.destroyers.len() as i32:
                if sema.facade_same_fn(r.destroyers[di], c.fn_sym): destroyer_of = contract_resource_name(sema, ri)
        if c.lend != 0 and (c.destroys != 0 or destroyer_of.len() > 0):
            let lat = contract_where(&site, sema, contract_clause(sema, c.node, FACADE_CLAUSE_LEND, 0))
            let which = if destroyer_of.len() > 0: f"a destroyer of {destroyer_of}" else: "declared `destroys`"
            report.fail(f"contract: fn '{fname}' ({at}): `lend` at {lat} presents {which} as a borrow; a destroying operation consumes the resource; resolve: remove `lend` (the `destroys` clause or the resource's `drop`/`destroys` already states it) (§63, §16.2b.5)")
        // Retained parameter with no lifetime owner (§63, §16.2b.9).
        for k in 0..c.retains.len() as i32:
            let by = c.retains_by[k]
            if sema.facade_param_receives(c.fn_sym, by).len() == 1: continue
            let clause = contract_clause(sema, c.node, FACADE_CLAUSE_RETAINS, k)
            let rat = contract_where(&site, sema, clause)
            let kind = if sema.facade_param_is_callable(sig, c.retains[k]): "callback" else: "parameter"
            report.fail(f"contract: fn '{fname}' (`retains` at {rat}): the retained {kind} {contract_param(sema, c.fn_sym, c.retains[k])} has no lifetime owner — `by {contract_param(sema, c.fn_sym, by)}` receives no modeled resource; resolve: name the resource parameter that keeps it, `retains param {c.retains[k]} by param <resource>` (§63, §16.2b.9)")
        // Advisory: destroyer-shaped name and signature, exposed as a lend.
        if c.lend == 0 and c.destroys == 0 and c.consumes.len() == 0 and destroyer_of.len() == 0 and not sema.facade_fn_is_resource_op(c.fn_sym):
            let recv = sema.facade_param_receives(c.fn_sym, 0)
            let word = contract_name_resembles_destroyer(fname)
            if recv.len() > 0 and word.len() > 0:
                let host = contract_resource_name(sema, recv[0])
                advisories = advisories + 1
                report.fail(f"contract: advisory: {fname} ({at}) is exposed as a borrow of {host}\n  = heuristic: name segment `{word}` and a signature taking {host}'s representation resemble a destroying operation\n  = this warning does not establish destruction semantics; the contract, the classification and the capability are unchanged\n  = help: declare `destroys` if it destroys the resource, or explicitly declare `lend` to confirm borrowing semantics (§63)")
    // Profile checks (§63; stage 11, §16.2b.12): an ambiguous match is a
    // rule that contributed nothing where the facade may have counted on it
    // — a violation naming the profile, the rule, the item and the clause
    // that resolves it. A profile fact shadowed by an explicit clause is the
    // facade expressing its exception (ruling §7.2): a note, so the reader
    // sees which of the profile's facts the facade replaced.
    let conventions = sema.facade_convention_nodes.len() as i32
    var ambiguous = 0
    var shadowed = 0
    for k in 0..conventions:
        let item = sema.facade_convention_nodes[k]
        let site = contract_convention_site(sema, item, source_path, source_text)
        let recs = sema.facade_profile_matches(item)
        for m in 0..recs.len() as i32:
            let (rule, status, subject_node, cands) = sema.facade_profile_match(recs[m])
            let profile = sema.facade_rule_profile_name(rule)
            let rname = sema.facade_rule_name(rule)
            let template = sema.facade_rule_template_text(rule)
            let what = sema.facade_profile_subject_text(rule, subject_node)
            let rat = contract_rule_at(sema, rule)
            if status == FACADE_PROFILE_AMBIGUOUS:
                ambiguous = ambiguous + 1
                if sema.facade_rule_is_fn(rule):
                    report.fail(f"contract: ambiguous profile match: profile {profile} rules {sema.facade_profile_names(&cands)} all match {what} ({rat}); a profile fact must resolve uniquely, so none applies; resolve: describe '{sema.safe_symbol_text(subject_node)}' with an fn item stating its contract (§63, §16.2b.12)")
                else:
                    let kind = sema.ast.get_data0(sema.ast.get_extra(sema.ast.get_data1(rule) + 1))
                    report.fail(f"contract: ambiguous profile match: profile {profile} rule {rname} ({template}, {rat}) matches {cands.len() as i32} candidates for {what}: {sema.facade_profile_names(&cands)}; a profile fact must resolve uniquely, so the rule contributes nothing; resolve: state `{facade_clause_name(kind)} <fn>` on the resource to choose (§63, §16.2b.12)")
            else if status == FACADE_PROFILE_SHADOWED:
                shadowed = shadowed + 1
                let by = if sema.facade_rule_is_fn(rule): "the fn item" else: "`" ++ facade_clause_name(sema.ast.get_data0(cands[1])) ++ "`"
                let matched = if sema.facade_rule_is_fn(rule): what else: f"{sema.safe_symbol_text(cands[0])} for {what}"
                report.note(f"contract-audit: profile fact shadowed: profile {profile} rule {rname} ({template}, {rat}) matched {matched}, and {by} at {contract_where(&site, sema, cands[1])} states the fact explicitly; the facade's statement wins (§16.2b.2)")
    report.note(f"contract-audit: resources={sema.facade_resources.len() as i32} items={sema.foreign_contracts.len() as i32} domains={sema.facade_domain_list.len() as i32} conventions={conventions} advisories={advisories} profile-ambiguous={ambiguous} profile-shadowed={shadowed}")

// ── the `contract` view ──────────────────────────────────────────────────
//
// The foreign-contract facts printed in order: a subject row as a heading,
// its fact rows indented beneath it. What a reader sees is exactly the row
// text a `select:kind=foreign-contract` query returns.

fn contract_view_render(report: &AnalysisReport) -> str:
    let lines: Vec[str] = Vec.new()
    lines.push("foreign-contract view\tv1\n")
    var subjects = 0
    for i in 0..report.facts.len() as i32:
        let fact = &report.facts[i]
        if fact.kind != AnalysisFactKind.ForeignContract: continue
        if (fact.flags & CONTRACT_FACT) != 0:
            lines.push("    ")
            lines.push(fact.detail.clone())
            lines.push("\n")
            continue
        subjects = subjects + 1
        lines.push(fact.detail.clone())
        lines.push("\n")
    if subjects == 0:
        lines.push("no `c facade` block describes this program; the contract view is empty\n")
    // The audit's verdict without the report's fact count, so a checked-in
    // snapshot of the view does not move with the prelude.
    for i in 0..report.notes.len() as i32:
        lines.push("note: " ++ report.notes[i].clone() ++ "\n")
    for i in 0..report.violations.len() as i32:
        lines.push("violation: " ++ report.violations[i].clone() ++ "\n")
    lines.push(f"contract-audit: violations={report.violations.len() as i32}" ++ (if report.ok(): " ok\n" else: " FAILED\n"))
    lines.join("")
