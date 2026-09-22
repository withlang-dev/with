// SemaFacade — D51 §16.2b stage 2: facade facts with provenance and the
// ruling's §61 verification (docs/modeled-c-implementation-plan.md).
//
// A `c facade` block is collected after pass 3, when every signature exists:
// domains and resources first (an fn clause may name either, in any order),
// then fn items. Each record keeps the node that stated it (provenance).
// Every mechanically checkable statement is verified here and each failure
// prints the resolved C parameter (§57: `param 4: *mut u8 pApp`), because C
// documentation counts from one and the facade counts from zero. Nothing
// consumes the facts yet: stage 3 makes raw classification consult them.
// `retains … by` writes the same retained-parameter mask the `retains:`
// c_import option writes, so both spellings are one fact.

use Sema
use Ast
use InternPool

impl Sema:
    mut fn collect_c_facades():
        for di in 0..self.ast.decl_count():
            if self.decl_is_lazy_skipped(di):
                continue
            self.update_decl_source_context(di)
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) == NodeKind.NK_C_FACADE:
                self.collect_c_facade(decl)
        self.verify_facade_resources()

    // Stage 4a: the facade-level checks that need every facade's facts (an fn
    // item may describe a destroyer from a block declared after the resource).
    // Each is "never half-model unsafely" (ruling §9, §16.2b.3) or an honest
    // "not rendered yet" — a resource the renderer (compiler/FacadeRender.w)
    // cannot express is reported here, never emitted as a placeholder.
    mut fn verify_facade_resources():
        for ri in 0..self.facade_resources.len() as i32:
            let rname: str = self.pool_resolve(self.facade_resources[ri].name)
            let node = self.facade_resources[ri].node
            let producer = self.facade_resources[ri].producer
            let drop_fn = self.facade_resources[ri].drop
            let destroyer_count = self.facade_resources[ri].destroyers.len() as i32
            if self.facade_resources[ri].init != 0 or self.facade_resources[ri].preinit != 0:
                self.emit_error(f"resource '{rname}' is an in-place resource (init/preinit); the compiler does not render in-place resources yet, so no With type is generated for it (§16.2b.3)", node)
                continue
            if producer != 0 and drop_fn == 0 and destroyer_count == 0:
                let pn: str = self.pool_resolve(producer)
                self.emit_error(f"resource '{rname}': producer '{pn}' with no 'drop' and no 'destroys' — never half-model unsafely: a safe constructor needs a destruction contract (§16.2b.3)", node)
                continue
            if drop_fn == 0 and destroyer_count > 0:
                // Ruling (Eric, 2026-09-22): a value dropped while live would
                // leak silently. Must-consume linear resources are a future
                // ruling, not modeled here.
                var unary = ""
                var unary_count = 0
                for di in 0..destroyer_count:
                    let d = self.facade_resources[ri].destroyers[di]
                    let dsig = self.get_sig(d)
                    if dsig >= 0 and self.sig_get_param_count(dsig) == 1:
                        let dn: str = self.pool_resolve(d)
                        unary = unary ++ (if unary_count > 0: ", " else: "") ++ f"'drop {dn}'"
                        unary_count = unary_count + 1
                if unary_count == 0:
                    self.emit_error(f"resource '{rname}' has 'destroys' operations but no 'drop'; every destroyer takes further arguments, so name a 'drop' operation or model the representation differently — never half-model unsafely: a value dropped while live would leak silently (§16.2b.3)", node)
                else if unary_count == 1:
                    self.emit_error_with_help(f"resource '{rname}' has 'destroys' operations but no 'drop' — never half-model unsafely: a value dropped while live would leak silently (§16.2b.3)", node, f"name the unary destroyer as the drop operation: {unary}")
                else:
                    self.emit_error_with_help(f"resource '{rname}' has 'destroys' operations but no 'drop' — never half-model unsafely: a value dropped while live would leak silently (§16.2b.3)", node, f"name one unary destroyer as the drop operation: {unary}")
                continue
            if drop_fn != 0:
                // Drop has nothing but the representation to pass.
                let dsig = self.get_sig(drop_fn)
                if dsig >= 0 and self.sig_get_param_count(dsig) != 1:
                    let dn: str = self.pool_resolve(drop_fn)
                    let n = self.sig_get_param_count(dsig)
                    self.emit_error(f"resource '{rname}': 'drop {dn}' takes {n} parameters; the drop operation takes only the representation — an operation with further arguments is a 'destroys' (§16.2b.3)", node)
                    continue
                self.verify_facade_destroyer(ri, drop_fn)
            for di in 0..destroyer_count:
                self.verify_facade_destroyer(ri, self.facade_resources[ri].destroyers[di])
            if producer != 0 and self.facade_resources[ri].out_param < 0 and self.ci_function_requires_raw_abi(producer) != 0:
                let pn: str = self.pool_resolve(producer)
                self.emit_error(f"resource '{rname}': producer '{pn}' is still a raw call after the facade covers its return (a variadic, a raw return, or a raw pointer parameter the facade does not describe); describe it with an fn item (§16.2b.5)", node)

    mut fn verify_facade_destroyer(ri: i32, f: i32):
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let node = self.facade_resources[ri].node
        let fname: str = self.pool_resolve(f)
        // A destroyer taking a pointer to the representation is the in-place
        // shape (`inflateEnd(z_stream *)`); the by-value and pointer renderings
        // pass the representation itself.
        let sig = self.get_sig(f)
        if sig >= 0 and self.sig_get_param_count(sig) > 0:
            let p0 = self.resolve_alias(self.sig_param_type(sig, 0) as TypeId)
            let repr = self.resolve_alias(self.facade_resources[ri].repr_tid as TypeId)
            if p0 != repr and self.get_type_kind(p0) == TypeKind.TY_PTR and not self.facade_void_ptr_accepts(p0, repr):
                self.emit_error(f"resource '{rname}': '{fname}' takes a pointer to the representation, the in-place shape; the compiler does not render in-place resources yet, so no With type is generated for it (§16.2b.3)", node)
                return
        // A destroying operation callable as a lend (§16.2b.3): an fn item
        // describing the same function lends its parameters unless it says
        // `destroys` or consumes the representation.
        let ci = self.facade_contract_for(f)
        if ci >= 0 and self.foreign_contracts[ci].destroys == 0:
            var consumes_repr = false
            for k in 0..self.foreign_contracts[ci].consumes.len() as i32:
                if self.foreign_contracts[ci].consumes[k] == 0:
                    consumes_repr = true
            if not consumes_repr:
                self.emit_error(f"resource '{rname}': '{fname}' destroys the resource but the fn item describing it lends its parameters; a destroying operation must not be callable as a lend — state 'destroys' on the fn item (§16.2b.3)", node)
                return
        if self.ci_function_requires_raw_abi(f) != 0:
            self.emit_error(f"resource '{rname}': '{fname}' is still a raw call after the facade covers the representation (a variadic, a raw return, or a raw pointer parameter the facade does not describe); describe it with an fn item (§16.2b.5)", node)

    mut fn collect_c_facade(node: i32):
        let facade = self.ast.get_data0(node)
        let extra_start = self.ast.get_data1(node)
        let count = self.ast.get_data2(node)
        for i in 0..count:
            let item = self.ast.get_extra(extra_start + i)
            let kind = self.ast.kind(item)
            if kind == NodeKind.NK_FACADE_DOMAIN:
                self.collect_facade_domain(item)
            else if kind == NodeKind.NK_FACADE_CONVENTION:
                self.facade_convention_nodes.push(item)
        for i in 0..count:
            let item = self.ast.get_extra(extra_start + i)
            if self.ast.kind(item) == NodeKind.NK_FACADE_RESOURCE:
                self.collect_facade_resource(facade, item)
        for i in 0..count:
            let item = self.ast.get_extra(extra_start + i)
            if self.ast.kind(item) == NodeKind.NK_FACADE_FN:
                self.collect_facade_fn(facade, item)

    mut fn collect_facade_domain(item: i32):
        let name = self.ast.get_data0(item)
        if self.facade_domains.contains(name):
            let dn: str = self.pool_resolve(name)
            self.emit_error(f"domain '{dn}' is declared twice (§16.2b.7)", item)
            return
        self.facade_domains.insert(name, self.ast.get_data1(item))

    // ── resources ────────────────────────────────────────────────────────

    mut fn collect_facade_resource(facade: i32, item: i32):
        let name = self.ast.get_data0(item)
        let rname: str = self.pool_resolve(name)
        if self.facade_resource_index.contains(name):
            self.emit_error(f"resource '{rname}' is declared twice (§16.2b.3)", item)
            return
        let extra_start = self.ast.get_data1(item)
        let clause_count = self.ast.get_data2(item)
        let repr_node = self.ast.get_extra(extra_start)
        let repr_tid = self.resolve_type_expr(repr_node) as i32
        if repr_tid == 0:
            return
        var r = FacadeResource { name, facade, node: item, repr_tid, producer: 0, out_param: -1, init: 0, preinit: 0, drop: 0, destroyers: Vec.new(), ok_const: 0, borrows: Vec.new(), independent: 0, thread_caps: 0 }
        for ci in 0..clause_count:
            let clause = self.ast.get_extra(extra_start + 1 + ci)
            r = self.collect_resource_clause(rname, move r, clause)
        self.facade_resource_index.insert(name, self.facade_resources.len() as i32)
        self.facade_resources.push(r)

    mut fn collect_resource_clause(rname: &str, r0: FacadeResource, clause: i32) -> FacadeResource:
        var r = r0
        let kind = self.ast.get_data0(clause)
        let ops = self.ast.get_data1(clause)
        if kind == FACADE_CLAUSE_FROM:
            let producer = self.ast.get_extra(ops)
            let sig = self.facade_fn_sig(producer, clause)
            if sig < 0:
                return r
            r.producer = producer
            let out_ref = self.ast.get_extra(ops + 1)
            if out_ref != 0:
                let pi = self.facade_resolve_param(out_ref, producer, sig)
                if pi < 0:
                    return r
                let pty = self.resolve_alias(self.sig_param_type(sig, pi) as TypeId)
                if self.get_type_kind(pty) != TypeKind.TY_PTR or self.resolve_alias(self.get_type_d0(pty) as TypeId) != self.resolve_alias(r.repr_tid as TypeId):
                    let shown = self.facade_param_display(producer, sig, pi)
                    self.emit_error(f"resource '{rname}': the out parameter {shown} is not a pointer to the representation (§16.2b.13)", clause)
                    return r
                r.out_param = pi
            else:
                let ret = self.resolve_alias(self.sig_return_type(sig) as TypeId)
                if ret != self.resolve_alias(r.repr_tid as TypeId):
                    let rt: str = self.type_name(self.sig_return_type(sig))
                    let pn: str = self.pool_resolve(producer)
                    self.emit_error(f"resource '{rname}': producer '{pn}' returns {rt}, not the representation (§16.2b.13)", clause)
            return r
        if kind == FACADE_CLAUSE_INIT or kind == FACADE_CLAUSE_PREINIT or kind == FACADE_CLAUSE_DROP or kind == FACADE_CLAUSE_DESTROYS:
            let f = self.ast.get_extra(ops)
            let sig = self.facade_fn_sig(f, clause)
            if sig < 0:
                return r
            if not self.facade_accepts_repr(sig, r.repr_tid):
                let fnm: str = self.pool_resolve(f)
                self.emit_error(f"resource '{rname}': '{fnm}' does not take the representation as its first parameter (§16.2b.13)", clause)
                return r
            if kind == FACADE_CLAUSE_INIT: r.init = f
            else if kind == FACADE_CLAUSE_PREINIT: r.preinit = f
            else if kind == FACADE_CLAUSE_DROP: r.drop = f
            else: r.destroyers.push(f)
            return r
        if kind == FACADE_CLAUSE_OK:
            let c = self.ast.get_extra(ops)
            if not self.facade_status_constant_ok(c):
                let cn: str = self.pool_resolve(c)
                self.emit_error(f"resource '{rname}': '{cn}' is not an imported compile-time constant (§16.2b.4, §16.2b.13)", clause)
                return r
            r.ok_const = c
            return r
        if kind == FACADE_CLAUSE_BORROWS:
            if r.producer == 0:
                self.emit_error(f"resource '{rname}': 'borrows' names a parameter of the producer; state 'from <producer>' first (§16.2b.6)", clause)
                return r
            let sig = self.get_sig(r.producer)
            let pi = self.facade_resolve_param(self.ast.get_extra(ops), r.producer, sig)
            if pi >= 0:
                r.borrows.push(pi)
            return r
        if kind == FACADE_CLAUSE_INDEPENDENT:
            r.independent = 1
            return r
        if kind == FACADE_CLAUSE_THREAD:
            let cap_count = self.ast.get_data2(clause)
            for i in 0..cap_count:
                let cap: str = self.pool_resolve(self.ast.get_extra(ops + i))
                if cap == "creator": r.thread_caps = r.thread_caps | 1
                else if cap == "send": r.thread_caps = r.thread_caps | 2
                else if cap == "share": r.thread_caps = r.thread_caps | 4
                else: r.thread_caps = r.thread_caps | 8
            if (r.thread_caps & 2) != 0 and (r.thread_caps & 8) == 0:
                self.emit_error(f"resource '{rname}': 'send' requires 'drop_any_thread' — With v1 does not marshal destruction back to the creator thread (§16.2b.10)", clause)
            return r
        let cname = facade_clause_name(kind)
        self.emit_error(f"resource '{rname}': clause '{cname}' applies to an fn item, not a resource (§16.2b)", clause)
        r

    // ── fn items ─────────────────────────────────────────────────────────

    mut fn collect_facade_fn(facade: i32, item: i32):
        let fn_sym = self.ast.get_data0(item)
        let fname: str = self.pool_resolve(fn_sym)
        let sig = self.facade_fn_sig(fn_sym, item)
        if sig < 0:
            return
        if self.foreign_contract_index.contains(fn_sym):
            self.emit_error(f"fn '{fname}' is described twice in this facade (§16.2b)", item)
            return
        var c = ForeignContract { fn_sym, facade, node: item, lend: 0, destroys: 0, consumes: Vec.new(), consumes_destroyed_by: Vec.new(), retains: Vec.new(), retains_by: Vec.new(), returns_borrow_resource: 0, returns_borrow_from: -1, returns_static_tid: 0, preserves_params: Vec.new(), preserves_domains: Vec.new(), of_resource: 0, rename: 0, callback_thread_any: 0, callback_consumes: Vec.new() }
        let extra_start = self.ast.get_data1(item)
        let clause_count = self.ast.get_data2(item)
        for ci in 0..clause_count:
            let clause = self.ast.get_extra(extra_start + ci)
            c = self.collect_fn_clause(fname, move c, sig, clause)
        self.foreign_contract_index.insert(fn_sym, self.foreign_contracts.len() as i32)
        self.foreign_contracts.push(c)

    mut fn collect_fn_clause(fname: &str, c0: ForeignContract, sig: i32, clause: i32) -> ForeignContract:
        var c = c0
        let fn_sym = c.fn_sym
        let kind = self.ast.get_data0(clause)
        let ops = self.ast.get_data1(clause)
        if kind == FACADE_CLAUSE_LEND:
            c.lend = 1
            return c
        if kind == FACADE_CLAUSE_DESTROYS:
            if self.sig_get_param_count(sig) == 0:
                self.emit_error(f"fn '{fname}': a destroyer takes the resource it destroys; this fn has no parameters (§16.2b.5)", clause)
                return c
            c.destroys = 1
            return c
        if kind == FACADE_CLAUSE_CONSUMES:
            let pi = self.facade_resolve_param(self.ast.get_extra(ops), fn_sym, sig)
            if pi < 0:
                return c
            let pk = self.get_type_kind(self.resolve_alias(self.sig_param_type(sig, pi) as TypeId))
            if pk != TypeKind.TY_PTR:
                let shown = self.facade_param_display(fn_sym, sig, pi)
                self.emit_error(f"fn '{fname}': consumes {shown}: not a pointer, there is nothing to transfer (§16.2b.5, §16.2b.13)", clause)
                return c
            var by = -1
            let by_ref = self.ast.get_extra(ops + 1)
            if by_ref != 0:
                by = self.facade_resolve_param(by_ref, fn_sym, sig)
                if by < 0:
                    return c
                if not self.facade_param_is_callable(sig, by):
                    let shown = self.facade_param_display(fn_sym, sig, by)
                    self.emit_error(f"fn '{fname}': destroyed_by {shown} is not callable (§16.2b.9, §16.2b.13)", clause)
                    return c
                if not self.facade_callable_accepts(sig, by, pi):
                    let shown = self.facade_param_display(fn_sym, sig, by)
                    let consumed = self.facade_param_display(fn_sym, sig, pi)
                    self.emit_error(f"fn '{fname}': destroyed_by {shown} does not take the consumed {consumed} as its first parameter (§16.2b.9, §16.2b.13)", clause)
                    return c
            c.consumes.push(pi)
            c.consumes_destroyed_by.push(by)
            return c
        if kind == FACADE_CLAUSE_RETAINS:
            let a = self.facade_resolve_param(self.ast.get_extra(ops), fn_sym, sig)
            if a < 0:
                return c
            let b = self.facade_resolve_param(self.ast.get_extra(ops + 1), fn_sym, sig)
            if b < 0:
                return c
            c.retains.push(a)
            c.retains_by.push(b)
            self.mark_param_retained(fn_sym, a)
            return c
        if kind == FACADE_CLAUSE_RETURNS_BORROW:
            let res = self.ast.get_extra(ops)
            if not self.facade_resource_index.contains(res):
                let rn: str = self.pool_resolve(res)
                self.emit_error(f"fn '{fname}': unknown resource '{rn}' (§16.2b.6)", clause)
                return c
            let from = self.facade_resolve_param(self.ast.get_extra(ops + 1), fn_sym, sig)
            if from < 0:
                return c
            let ri: i32 = self.facade_resource_index.get(res).unwrap()
            let repr = self.facade_resources[ri].repr_tid
            if self.resolve_alias(self.sig_return_type(sig) as TypeId) != self.resolve_alias(repr as TypeId):
                let rn: str = self.pool_resolve(res)
                let rt: str = self.type_name(self.sig_return_type(sig))
                self.emit_error(f"fn '{fname}' returns {rt}, not the representation of '{rn}' (§16.2b.13)", clause)
                return c
            c.returns_borrow_resource = res
            c.returns_borrow_from = from
            return c
        if kind == FACADE_CLAUSE_RETURNS_STATIC:
            let tid = self.resolve_type_expr(self.ast.get_extra(ops)) as i32
            if tid == 0:
                return c
            c.returns_static_tid = tid
            return c
        if kind == FACADE_CLAUSE_PRESERVES:
            let ref_node = self.ast.get_extra(ops)
            if ref_node != 0:
                let pi = self.facade_resolve_param(ref_node, fn_sym, sig)
                if pi >= 0:
                    c.preserves_params.push(pi)
                return c
            let d = self.ast.get_extra(ops + 1)
            if not self.facade_domains.contains(d):
                let dn: str = self.pool_resolve(d)
                self.emit_error(f"fn '{fname}': unknown domain '{dn}'; declare it with 'domain {dn} process|thread|resource|static' (§16.2b.7)", clause)
                return c
            c.preserves_domains.push(d)
            return c
        if kind == FACADE_CLAUSE_OF:
            let res = self.ast.get_extra(ops)
            if not self.facade_resource_index.contains(res):
                let rn: str = self.pool_resolve(res)
                self.emit_error(f"fn '{fname}': unknown resource '{rn}' (§16.2b.3)", clause)
                return c
            c.of_resource = res
            return c
        if kind == FACADE_CLAUSE_RENAME:
            c.rename = self.ast.get_extra(ops)
            return c
        if kind == FACADE_CLAUSE_CALLBACK_THREAD:
            c.callback_thread_any = 1
            return c
        if kind == FACADE_CLAUSE_CALLBACK_CONSUMES:
            let pi = self.facade_resolve_param(self.ast.get_extra(ops), fn_sym, sig)
            if pi >= 0:
                c.callback_consumes.push(pi)
            return c
        let cname = facade_clause_name(kind)
        self.emit_error(f"fn '{fname}': clause '{cname}' applies to a resource, not an fn item (§16.2b)", clause)
        c

    // ── verification helpers ─────────────────────────────────────────────

    mut fn facade_fn_sig(sym: i32, at: i32) -> i32:
        let sig = self.get_sig(sym)
        if sig < 0:
            let n: str = self.pool_resolve(sym)
            self.emit_error(f"'{n}' is not a declaration in scope: a facade describes imported declarations (§16.2b.13)", at)
        sig

    // The name of parameter `pi` as the declaration spells it, or 0 — read
    // through the fn meta record, as named-argument matching does, so a
    // c_import wrapper `fn` and a plain `extern fn` answer alike.
    fn facade_decl_param_name(fn_sym: i32, pi: i32) -> i32:
        let decl = self.facade_fn_decl_node(fn_sym)
        if decl == 0:
            return 0
        let meta = self.ast.find_fn_meta(decl)
        if meta < 0:
            return 0
        self.ast.fn_param_name(self.ast.fn_meta_param_start(meta), pi)

    // The declaring node of a function the facade names. Imported modules are
    // parsed with their own InternPool, so a c_import declaration's symbol is
    // not the facade's symbol for the same name: when the symbol lookup
    // misses, find the declaration by its text, as the raw-ABI classifier does.
    fn facade_fn_decl_node(fn_sym: i32) -> i32:
        let direct = self.fn_symbol_decl_node(fn_sym)
        if direct != 0:
            return direct
        let want: str = self.safe_symbol_text(fn_sym)
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            let kind = self.ast.kind(decl)
            if kind != NodeKind.NK_EXTERN_FN and kind != NodeKind.NK_FN_DECL:
                continue
            if self.safe_symbol_text(self.ast.get_data0(decl)) == want:
                return decl
        0

    // The C spelling of a parameter name: c_import declares `p` as
    // `__param_p` (CImport.w) so no C name can collide with a With keyword;
    // a facade names the parameter as the header does.
    fn facade_param_c_name(fn_sym: i32, pi: i32) -> str:
        let sym = self.facade_decl_param_name(fn_sym, pi)
        if sym == 0:
            return ""
        let spelled: str = self.pool_resolve(sym)
        if spelled.starts_with("__param_"):
            return spelled.slice(8, spelled.len())
        spelled

    // §57: every positional diagnostic prints the resolved C parameter.
    fn facade_param_display(fn_sym: i32, sig: i32, pi: i32) -> str:
        let pname = self.facade_param_c_name(fn_sym, pi)
        let tn: str = self.type_name(self.sig_param_type(sig, pi))
        f"param {pi}: {tn} {pname}"

    // `param name`, `param N` (zero-based) or `param type T`: one parameter,
    // or -1 after the diagnostic.
    mut fn facade_resolve_param(ref_node: i32, fn_sym: i32, sig: i32) -> i32:
        let rk = self.ast.get_data0(ref_node)
        let count = self.sig_get_param_count(sig)
        let fname: str = self.pool_resolve(fn_sym)
        if rk == FACADE_PARAM_REF_INDEX:
            let digits: str = self.pool_resolve(self.ast.get_data1(ref_node))
            var idx = 0
            for i in 0..digits.len() as i32:
                idx = idx * 10 + ((digits[i] as i32) - 48)
            if idx >= count:
                self.emit_error(f"'{fname}' has {count} parameter(s); param {idx} does not exist (parameters count from zero, §16.2b.5)", ref_node)
                return -1
            return idx
        if rk == FACADE_PARAM_REF_NAME:
            let want = self.ast.get_data1(ref_node)
            let wn: str = self.pool_resolve(want)
            var names = ""
            for pi in 0..count:
                let cn = self.facade_param_c_name(fn_sym, pi)
                if cn == wn:
                    return pi
                names = names ++ (if pi > 0: ", " else: "") ++ f"{pi}: {cn}"
            self.emit_error(f"'{fname}' has no parameter named '{wn}'; its parameters are {names} (§16.2b.5)", ref_node)
            return -1
        let tid = self.resolve_type_expr(self.ast.get_data1(ref_node)) as i32
        if tid == 0:
            return -1
        var found = -1
        var matches = 0
        for pi in 0..count:
            if self.resolve_alias(self.sig_param_type(sig, pi) as TypeId) == self.resolve_alias(tid as TypeId):
                matches = matches + 1
                found = pi
        if matches != 1:
            let tn: str = self.type_name(tid)
            self.emit_error(f"'{fname}': param type {tn} matches {matches} parameter(s); a type reference must match exactly one (§16.2b.5)", ref_node)
            return -1
        found

    // A destroyer, initializer or drop takes the representation first: the
    // value itself (a pointer resource), a `void *` that C converts it to, or
    // a pointer to it (in-place).
    fn facade_accepts_repr(sig: i32, repr_tid: i32) -> bool:
        if self.sig_get_param_count(sig) == 0:
            return false
        let p0 = self.resolve_alias(self.sig_param_type(sig, 0) as TypeId)
        let repr = self.resolve_alias(repr_tid as TypeId)
        if p0 == repr or self.facade_void_ptr_accepts(p0, repr):
            return true
        self.get_type_kind(p0) == TypeKind.TY_PTR and self.resolve_alias(self.get_type_d0(p0) as TypeId) == repr

    // Ruling §61 "the destroyer accepts the representation" is C's own
    // conversion rule (Eric, 2026-09-22): a `void *` parameter (`*mut c_void`
    // or `*const c_void` after c_import) accepts every object pointer
    // representation, typedefs chased through their aliases — never a
    // function pointer (C does not convert one to `void *`) and never a
    // by-value representation. Otherwise the type is exact.
    fn facade_void_ptr_accepts(p0: i32, repr: i32) -> bool:
        if self.get_type_kind(p0) != TypeKind.TY_PTR or self.is_c_void_like_type(self.get_type_d0(p0)) == 0:
            return false
        if self.get_type_kind(repr) != TypeKind.TY_PTR:
            return false
        let pointee = self.resolve_alias(self.get_type_d0(repr) as TypeId)
        let k = self.get_type_kind(pointee)
        k != TypeKind.TY_FN and k != TypeKind.TY_EXTERN_FN

    fn facade_param_is_callable(sig: i32, pi: i32) -> bool:
        self.callable_type_resolved(self.sig_param_type(sig, pi)) != 0

    // The callable parameter `by` (a `destroyed_by`) takes the consumed
    // parameter `pi` first, under the destroyer rule (facade_accepts_repr).
    fn facade_callable_accepts(sig: i32, by: i32, pi: i32) -> bool:
        let callable = self.callable_type_resolved(self.sig_param_type(sig, by))
        if self.get_type_d1(callable) == 0:
            return false
        let p0 = self.resolve_alias(self.type_extra[self.get_type_d0(callable)] as TypeId)
        let consumed = self.resolve_alias(self.sig_param_type(sig, pi) as TypeId)
        p0 == consumed or self.facade_void_ptr_accepts(p0, consumed)

    // A status constant is a c_import `let` (or a `const`) with a literal
    // initializer: a materialized compile-time value, never a runtime read.
    fn facade_status_constant_ok(sym: i32) -> bool:
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_LET_DECL or self.ast.get_data0(decl) != sym:
                continue
            var value = self.ast.get_data1(decl)
            if value != 0 and self.ast.kind(value) == NodeKind.NK_COMPTIME:
                value = self.ast.get_data0(value)
            if value != 0 and self.ast.kind(value) == NodeKind.NK_UNARY:
                value = self.ast.get_data1(value)
            return value != 0 and self.ast.kind(value) == NodeKind.NK_INT_LIT
        false

fn facade_clause_name(kind: i32) -> str:
    if kind == FACADE_CLAUSE_FROM: return "from"
    if kind == FACADE_CLAUSE_INIT: return "init"
    if kind == FACADE_CLAUSE_PREINIT: return "preinit"
    if kind == FACADE_CLAUSE_DROP: return "drop"
    if kind == FACADE_CLAUSE_DESTROYS: return "destroys"
    if kind == FACADE_CLAUSE_OK: return "ok"
    if kind == FACADE_CLAUSE_BORROWS: return "borrows"
    if kind == FACADE_CLAUSE_INDEPENDENT: return "independent"
    if kind == FACADE_CLAUSE_LEND: return "lend"
    if kind == FACADE_CLAUSE_CONSUMES: return "consumes"
    if kind == FACADE_CLAUSE_RETAINS: return "retains"
    if kind == FACADE_CLAUSE_RETURNS_BORROW: return "returns borrow"
    if kind == FACADE_CLAUSE_RETURNS_STATIC: return "returns static"
    if kind == FACADE_CLAUSE_PRESERVES: return "preserves"
    if kind == FACADE_CLAUSE_OF: return "of"
    if kind == FACADE_CLAUSE_RENAME: return "rename"
    if kind == FACADE_CLAUSE_THREAD: return "thread"
    if kind == FACADE_CLAUSE_CALLBACK_THREAD: return "callback_thread"
    "callback consumes"

// ── stage 3: raw classification consults the facts ──────────────────────
//
// A facade covers a declaration's surface: a described fn lends every
// parameter by default (§16.2b.5 — the facade's assertion, recorded as
// review), and `consumes`/`destroys`/`retains` are stronger statements of
// the same coverage; a resource's producer covers its return (direct) or
// its out parameter, and a resource's drop/destroys/init/preinit covers the
// parameter that takes the representation. A covered surface is not raw
// (ci_function_requires_raw_abi), so the call needs no `unsafe`. Nothing is
// inferred from a name: an undescribed pointer return stays raw. Symbols
// are matched by text — the facade's symbols live in the user's pool, the
// c_import declaration's in its own.

impl Sema:
    fn facade_contract_for(fn_sym: i32) -> i32:
        if self.foreign_contract_index.contains(fn_sym):
            return self.foreign_contract_index.get(fn_sym).unwrap()
        if self.foreign_contracts.len() == 0:
            return -1
        let want: str = self.safe_symbol_text(fn_sym)
        for i in 0..self.foreign_contracts.len() as i32:
            if self.safe_symbol_text(self.foreign_contracts[i].fn_sym) == want:
                return i
        -1

    fn facade_same_fn(a: i32, b: i32) -> bool:
        if a == 0 or b == 0:
            return false
        a == b or self.safe_symbol_text(a) == self.safe_symbol_text(b)

    fn facade_covers_return(fn_sym: i32) -> bool:
        let ci = self.facade_contract_for(fn_sym)
        if ci >= 0:
            if self.foreign_contracts[ci].returns_borrow_resource != 0 or self.foreign_contracts[ci].returns_static_tid != 0:
                return true
        for i in 0..self.facade_resources.len() as i32:
            if self.facade_resources[i].out_param < 0 and self.facade_same_fn(self.facade_resources[i].producer, fn_sym):
                return true
        false

    fn facade_covers_param(fn_sym: i32, pi: i32) -> bool:
        if self.facade_contract_for(fn_sym) >= 0:
            return true
        for i in 0..self.facade_resources.len() as i32:
            if self.facade_resources[i].out_param == pi and self.facade_same_fn(self.facade_resources[i].producer, fn_sym):
                return true
            if pi == 0:
                if self.facade_same_fn(self.facade_resources[i].drop, fn_sym) or self.facade_same_fn(self.facade_resources[i].init, fn_sym) or self.facade_same_fn(self.facade_resources[i].preinit, fn_sym):
                    return true
                for di in 0..self.facade_resources[i].destroyers.len() as i32:
                    if self.facade_same_fn(self.facade_resources[i].destroyers[di], fn_sym):
                        return true
        false
