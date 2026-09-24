// FacadeProfile — D51 stage 11 (ruling §7, §59, §62; spec §16.2b.12): a
// convention profile applied to the facade that adopts it.
//
// A profile is `c convention pkg.vN:` in the package `use convention pkg.vN`
// resolves to (Parser.w parse_c_convention). Adopting it is the explicit act
// that makes its rules trusted facade evidence, so inside the adopted profile
// a rule may state from a name what core With never infers: `unref: drop
// *_unref` is a destruction contract. Every capability-granting match is
// unique-or-nothing (ruling §7.1): a rule that finds one valid candidate for
// a subject states the clause; zero or several contribute nothing, and the
// compiler never picks. An explicit clause on the subject shadows the
// profile's (ruling §7.2): the facade expresses the exceptions.
//
// The pass runs in the frontend once every `<c_import …>` translation is in
// the pool and before the facades render (Frontend.w
// apply_convention_profiles_frontend), because the renderer reads clauses
// off the AST: a profile-stated `drop` must be a clause on the resource item
// by then. Each stated clause carries its rule as a trailing operand
// (Ast.w facade_clause_profile_rule) — the provenance Sema's diagnostics and
// the contract view print — and every outcome, applied or not, is an
// NK_FACADE_PROFILE_MATCH record on the `use convention` item, so the audit
// reports the ambiguous and the shadowed (ruling §63) from the same facts.
//
// Candidates are judged by the shape the renderer and Sema's verification
// read (facade_accepts_repr, verify_facade_resource): a `drop` takes the
// representation alone, a `destroys`/`init` takes it first, a `from` returns
// it or fills an out parameter pointing at it. Sema verifies the stated
// clause again afterwards as it verifies any clause.

use Ast
use InternPool
use render
use compiler.FacadeRender

extern fn with_str_clone_ref(s: &str) -> str

// `*` matches any run of characters; everything else matches itself.
pub fn facade_profile_glob(pattern: &str, name: &str) -> bool:
    facade_profile_glob_at(pattern, 0, name, 0)

fn facade_profile_glob_at(pattern: &str, pi: i32, name: &str, ni: i32) -> bool:
    let pn = pattern.len() as i32
    let nn = name.len() as i32
    if pi == pn: return ni == nn
    if pattern[pi] == '*':
        var k = ni
        while k <= nn:
            if facade_profile_glob_at(pattern, pi + 1, name, k): return true
            k = k + 1
        return false
    if ni == nn or pattern[pi] != name[ni]: return false
    facade_profile_glob_at(pattern, pi + 1, name, ni + 1)

// The `c convention` block named `dotted`, or 0.
pub fn facade_profile_find(pool: AstPool, intern: InternPool, dotted: &str) -> i32:
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_C_CONVENTION: continue
        let have: str = intern.resolve(pool.get_data0(decl))
        if have == dotted: return decl as i32
    0

pub fn facade_profile_dotted(pool: AstPool, intern: InternPool, item: i32) -> str:
    let start = pool.get_data0(item as NodeId)
    var dotted = ""
    for i in 0..pool.get_data1(item as NodeId):
        if i > 0: dotted = dotted ++ "."
        dotted = dotted ++ intern.resolve(pool.get_extra(start + i))
    dotted

// The imported C functions in the pool, one declaring node per name (a
// c_import may declare a name as both the extern and its wrapper; the
// first is the one the facade's own clauses resolve, facade_render_find_fn).
fn facade_profile_imported_fns(pool: AstPool, intern: InternPool, ci: &Vec[i32]) -> (Vec[str], Vec[i32]):
    let names: Vec[str] = Vec.new()
    let decls: Vec[i32] = Vec.new()
    for di in 0..pool.decl_count():
        if di >= ci.len() as i32 or ci[di] == 0: continue
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        if kind != NodeKind.NK_EXTERN_FN and kind != NodeKind.NK_FN_DECL: continue
        if pool.find_fn_meta(decl) < 0: continue
        let name: str = with_str_clone_ref(intern.resolve(pool.get_data0(decl)))
        var seen = false
        for k in 0..names.len() as i32:
            if names[k] == name: seen = true
        if seen: continue
        names.push(name)
        decls.push(decl as i32)
    (names, decls)

fn facade_profile_p0(pool: AstPool, intern: InternPool, decl: i32) -> str:
    if facade_render_param_count(pool, decl) == 0: return ""
    facade_render_unalias(pool, intern, facade_render_param_type(pool, intern, decl, 0))

// Sema's facade_accepts_repr, read off the AST text: the representation
// itself, a `void *` for an object pointer, or a pointer to it (the
// in-place shape).
fn facade_profile_accepts(p0: &str, repr: &str) -> bool:
    if p0.len() == 0: return false
    if p0 == repr: return true
    if (p0 == "*mut c_void" or p0 == "*const c_void") and repr.starts_with("*"): return true
    p0 == "*mut " ++ repr

fn facade_profile_return(pool: AstPool, intern: InternPool, decl: i32) -> str:
    let meta = pool.find_fn_meta(decl as NodeId)
    let ret = pool.fn_meta_ret(meta)
    if ret == 0: return ""
    facade_render_unalias(pool, intern, render_type_expr(pool, intern, ret as NodeId))

// Whether `decl` has the shape a resource-rule template of `kind` states
// over a resource wrapping `repr`.
fn facade_profile_shape_fits(pool: AstPool, intern: InternPool, decl: i32, kind: i32, out_ref: i32, repr: &str) -> bool:
    if kind == FACADE_CLAUSE_FROM:
        if out_ref == 0: return facade_profile_return(pool, intern, decl) == repr
        let pi = facade_render_param_ref(pool, intern, decl, out_ref)
        if pi < 0: return false
        return facade_render_unalias(pool, intern, facade_render_param_type(pool, intern, decl, pi)) == "*mut " ++ repr
    let p0 = facade_profile_p0(pool, intern, decl)
    if kind == FACADE_CLAUSE_DROP: return facade_render_param_count(pool, decl) == 1 and facade_profile_accepts(p0, repr)
    facade_profile_accepts(p0, repr)

// The explicit (or earlier-profile) clause on `resource` that states the
// fact class `kind` would: `drop` is one fact; production (`from`/`init`) is
// one shape (verify_facade_resource refuses both); a `destroys` is shadowed
// by any destroy clause naming the same function.
fn facade_profile_shadowing_clause(pool: AstPool, intern: InternPool, resource: i32, kind: i32, fn_name: &str) -> i32:
    let extra_start = pool.get_data1(resource as NodeId)
    for k in 0..pool.get_data2(resource as NodeId):
        let clause = pool.get_extra(extra_start + 1 + k)
        let have = pool.get_data0(clause as NodeId)
        if kind == FACADE_CLAUSE_DROP and have == FACADE_CLAUSE_DROP: return clause
        if (kind == FACADE_CLAUSE_FROM or kind == FACADE_CLAUSE_INIT) and (have == FACADE_CLAUSE_FROM or have == FACADE_CLAUSE_INIT): return clause
        if kind == FACADE_CLAUSE_DESTROYS and (have == FACADE_CLAUSE_DROP or have == FACADE_CLAUSE_DESTROYS):
            let named: str = intern.resolve(pool.get_extra(pool.get_data1(clause as NodeId)))
            if named == fn_name: return clause
    0

// An fn item anywhere describing `fn_name` (the facade's exception to the
// profile, ruling §7.2), or 0.
fn facade_profile_explicit_fn_item(pool: AstPool, intern: InternPool, fn_name: &str) -> i32:
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        let have: str = intern.resolve(pool.get_data0(items[i] as NodeId))
        if have == fn_name: return items[i]
    0

fn facade_profile_record(pool: AstPool, at: i32, rule: i32, status: i32, subject: i32, candidates: &Vec[i32]) -> i32:
    let extra_start = pool.extra_len()
    pool.add_extra(subject)
    pool.add_extra(candidates.len() as i32)
    for i in 0..candidates.len() as i32: pool.add_extra(candidates[i])
    pool.add_node(NodeKind.NK_FACADE_PROFILE_MATCH, pool.get_start(at as NodeId), pool.get_end(at as NodeId), rule, status, extra_start) as i32

// The clause a rule states on a subject: the template's operands with the
// pattern replaced by the matched function, the rule appended, the span the
// `use convention` item's (a diagnostic about the clause points at the
// adoption, in the facade's own file).
fn facade_profile_clause(pool: AstPool, at: i32, template: i32, fn_sym: i32, rule: i32) -> i32:
    let kind = pool.get_data0(template as NodeId)
    let ops = pool.get_data1(template as NodeId)
    let count = pool.get_data2(template as NodeId)
    let extra_start = pool.extra_len()
    for i in 0..count:
        let op = pool.get_extra(ops + i)
        pool.add_extra(if i == 0 and kind != FACADE_CLAUSE_LEND: fn_sym else: op)
    pool.add_extra(rule)
    pool.add_node(NodeKind.NK_FACADE_CLAUSE, pool.get_start(at as NodeId), pool.get_end(at as NodeId), kind, extra_start, count + 1) as i32

// Rewrites a node's extra list as `head ++ tail`.
fn facade_profile_append_extras(pool: AstPool, node: i32, head_start: i32, head_count: i32, tail: &Vec[i32]) -> i32:
    let extra_start = pool.extra_len()
    for i in 0..head_count: pool.add_extra(pool.get_extra(head_start + i))
    for i in 0..tail.len() as i32: pool.add_extra(tail[i])
    extra_start

// Applies `profile` to `facade` for its `use convention` item `at`: states
// every uniquely matched rule and records every outcome on the item.
pub fn facade_profile_apply(pool: AstPool, intern: InternPool, ci: &Vec[i32], facade: i32, at: i32, profile: i32) -> AstPool:
    var p = pool
    let records: Vec[i32] = Vec.new()
    let (names, decls) = facade_profile_imported_fns(p, intern, ci)
    let rule_start = p.get_data1(profile as NodeId)
    let rule_count = p.get_data2(profile as NodeId)
    // Resource rules, per resource of the adopting facade.
    let item_start = p.get_data1(facade as NodeId)
    let item_count = p.get_data2(facade as NodeId)
    for ii in 0..item_count:
        let resource = p.get_extra(item_start + ii)
        if p.kind(resource as NodeId) != NodeKind.NK_FACADE_RESOURCE: continue
        let repr = facade_render_unalias(p, intern, render_type_expr(p, intern, p.get_extra(p.get_data1(resource as NodeId)) as NodeId))
        for ri in 0..rule_count:
            let rule = p.get_extra(rule_start + ri)
            let rx = p.get_data1(rule as NodeId)
            if p.get_extra(rx + 2) != 0: continue
            let pattern: str = with_str_clone_ref(intern.resolve(p.get_extra(rx)))
            let template = p.get_extra(rx + 1)
            let kind = p.get_data0(template as NodeId)
            let out_ref = if kind == FACADE_CLAUSE_FROM: p.get_extra(p.get_data1(template as NodeId) + 1) else: 0
            let candidates: Vec[i32] = Vec.new()
            for k in 0..names.len() as i32:
                if not facade_profile_glob(pattern, names[k]): continue
                if not facade_profile_shape_fits(p, intern, decls[k], kind, out_ref, repr): continue
                candidates.push(p.get_data0(decls[k] as NodeId))
            if candidates.len() == 0:
                records.push(facade_profile_record(p, at, rule, FACADE_PROFILE_NONE, resource, &candidates))
                continue
            if candidates.len() > 1:
                records.push(facade_profile_record(p, at, rule, FACADE_PROFILE_AMBIGUOUS, resource, &candidates))
                continue
            let fn_name: str = with_str_clone_ref(intern.resolve(candidates[0]))
            let shadow = facade_profile_shadowing_clause(p, intern, resource, kind, fn_name)
            if shadow != 0:
                let by: Vec[i32] = Vec.new()
                by.push(candidates[0])
                by.push(shadow)
                records.push(facade_profile_record(p, at, rule, FACADE_PROFILE_SHADOWED, resource, &by))
                continue
            let clause = facade_profile_clause(p, at, template, candidates[0], rule)
            let tail: Vec[i32] = Vec.new()
            tail.push(clause)
            let new_start = facade_profile_append_extras(p, resource, p.get_data1(resource as NodeId), 1 + p.get_data2(resource as NodeId), &tail)
            p.set_data1(resource as NodeId, new_start)
            p.set_data2(resource as NodeId, p.get_data2(resource as NodeId) + 1)
            records.push(facade_profile_record(p, at, rule, FACADE_PROFILE_APPLIED, resource, &candidates))
    // Fn rules, per imported function whose first parameter receives a
    // resource of this facade and that no resource clause assigns: the
    // rules that match it are its candidates.
    let reprs: Vec[str] = Vec.new()
    for ii in 0..item_count:
        let resource = p.get_extra(item_start + ii)
        if p.kind(resource as NodeId) != NodeKind.NK_FACADE_RESOURCE: continue
        reprs.push(facade_render_unalias(p, intern, render_type_expr(p, intern, p.get_extra(p.get_data1(resource as NodeId)) as NodeId)))
    let new_items: Vec[i32] = Vec.new()
    let matched_rules: Vec[i32] = Vec.new()
    for k in 0..names.len() as i32:
        let p0 = facade_profile_p0(p, intern, decls[k])
        var received = false
        for r in 0..reprs.len() as i32:
            if p0 == reprs[r] or p0 == "*mut " ++ reprs[r]: received = true
        if not received: continue
        if facade_render_is_resource_op(p, intern, names[k]): continue
        let candidates: Vec[i32] = Vec.new()
        var rule_of = 0
        for ri in 0..rule_count:
            let rule = p.get_extra(rule_start + ri)
            let rx = p.get_data1(rule as NodeId)
            if p.get_extra(rx + 2) == 0: continue
            let pattern: str = with_str_clone_ref(intern.resolve(p.get_extra(rx)))
            if not facade_profile_glob(pattern, names[k]): continue
            candidates.push(p.get_data0(rule as NodeId))
            rule_of = rule
            var noted = false
            for m in 0..matched_rules.len() as i32:
                if matched_rules[m] == rule: noted = true
            if not noted: matched_rules.push(rule)
        if candidates.len() == 0: continue
        let fn_sym = p.get_data0(decls[k] as NodeId)
        if candidates.len() > 1:
            records.push(facade_profile_record(p, at, rule_of, FACADE_PROFILE_AMBIGUOUS, fn_sym, &candidates))
            continue
        let explicit = facade_profile_explicit_fn_item(p, intern, names[k])
        if explicit != 0:
            let by: Vec[i32] = Vec.new()
            by.push(candidates[0])
            by.push(explicit)
            records.push(facade_profile_record(p, at, rule_of, FACADE_PROFILE_SHADOWED, fn_sym, &by))
            continue
        let template = p.get_extra(p.get_data1(rule_of as NodeId) + 1)
        let clause = facade_profile_clause(p, at, template, fn_sym, rule_of)
        let clause_start = p.extra_len()
        p.add_extra(clause)
        new_items.push(p.add_node(NodeKind.NK_FACADE_FN, p.get_start(at as NodeId), p.get_end(at as NodeId), fn_sym, clause_start, 1) as i32)
        records.push(facade_profile_record(p, at, rule_of, FACADE_PROFILE_APPLIED, fn_sym, &candidates))
    for ri in 0..rule_count:
        let rule = p.get_extra(rule_start + ri)
        if p.get_extra(p.get_data1(rule as NodeId) + 2) == 0: continue
        var noted = false
        for m in 0..matched_rules.len() as i32:
            if matched_rules[m] == rule: noted = true
        if noted: continue
        let none: Vec[i32] = Vec.new()
        records.push(facade_profile_record(p, at, rule, FACADE_PROFILE_NONE, 0, &none))
    if new_items.len() > 0:
        let new_start = facade_profile_append_extras(p, facade, p.get_data1(facade as NodeId), p.get_data2(facade as NodeId), &new_items)
        p.set_data1(facade as NodeId, new_start)
        p.set_data2(facade as NodeId, p.get_data2(facade as NodeId) + new_items.len() as i32)
    let path_count = p.get_data1(at as NodeId)
    let at_start = facade_profile_append_extras(p, at, p.get_data0(at as NodeId), path_count, &records)
    p.set_data0(at as NodeId, at_start)
    p.set_data2(at as NodeId, records.len() as i32)
    p
