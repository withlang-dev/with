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
use Diagnostic
use compiler.FacadeRender

impl Sema:
    mut fn collect_c_facades():
        for di in 0..self.ast.decl_count():
            if self.decl_is_lazy_skipped(di):
                continue
            self.update_decl_source_context(di)
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) == NodeKind.NK_C_FACADE:
                self.collect_c_facade(di, decl)
        self.verify_facade_resources()
        self.report_facade_layout_errors()
        self.verify_facade_assignments()
        self.verify_facade_buffer_params()
        self.verify_facade_presentation()
        self.verify_facade_failed_state_items()
        self.verify_facade_nullable_items()
        self.verify_facade_buffers()
        self.verify_facade_borrowed_returns()
        self.verify_facade_text_views()
        self.verify_facade_callback_items()
        self.facade_index_call_effects()

    // Stage 4a/4b: the facade-level checks that need every facade's facts (an
    // fn item may describe a destroyer from a block declared after the
    // resource). Each is "never half-model unsafely" (ruling §9, §16.2b.3) or
    // a shape the renderer (compiler/FacadeRender.w) cannot express, reported
    // here and never emitted as a placeholder. The last checks are the net
    // under the renderer itself: a resource that passed every check must
    // have become a With type, and each of its producers a constructor or a
    // reported pending one (verify_facade_constructors), or the renderer
    // stayed silent over a shape the checks did not name.
    mut fn verify_facade_resources():
        for ri in 0..self.facade_resources.len() as i32:
            // A diagnostic's span is read in the current source file: the
            // resource's own facade block, not the last declaration pass 3
            // visited (a rendered `<facade …>` file, whose lines it would
            // quote).
            self.update_decl_source_context(self.facade_resources[ri].decl)
            if self.verify_facade_resource(ri) and self.facade_resources[ri].drop != 0 and not self.diags.has_errors() and self.verify_facade_generated_names(ri):
                if not self.facade_resource_rendered(ri):
                    let rname: str = self.pool_resolve(self.facade_resources[ri].name)
                    self.emit_error(f"resource '{rname}' passed every facade check but no With type was rendered for it; the renderer cannot express this shape and did not say so — a compiler defect (§16.2b.3)", self.facade_resources[ri].node)
                else:
                    self.verify_facade_constructors(ri)

    mut fn verify_facade_resource(ri: i32) -> bool:
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let node = self.facade_resources[ri].node
        let producer_count = self.facade_resources[ri].producers.len() as i32
        let producer = if producer_count > 0: self.facade_resources[ri].producers[0] else: 0
        let init_fn = self.facade_resources[ri].init
        let preinit_fn = self.facade_resources[ri].preinit
        let drop_fn = self.facade_resources[ri].drop
        let destroyer_count = self.facade_resources[ri].destroyers.len() as i32
        if producer != 0 and init_fn != 0:
            self.emit_error(f"resource '{rname}' names both 'from' and 'init'; a resource is produced by direct return, by out parameter, or by in-place initialization — one shape (§16.2b.4)", node)
            return false
        if preinit_fn != 0 and init_fn == 0:
            self.emit_error(f"resource '{rname}': 'preinit' constructs storage for an 'init' operation; state 'init <fn>(self)' (§16.2b.4)", node)
            return false
        if self.facade_resources[ri].movable != 0 and init_fn == 0:
            self.emit_error(f"resource '{rname}': 'movable' releases the pinning of an in-place resource, and this resource has no 'init'; a pointer or by-value resource is already movable (§16.2b.3)", node)
            return false
        if (producer != 0 or init_fn != 0) and drop_fn == 0 and destroyer_count == 0:
            let pn: str = self.pool_resolve(if producer != 0: producer else: init_fn)
            self.emit_error(f"resource '{rname}': producer '{pn}' with no 'drop' and no 'destroys' — never half-model unsafely: a safe constructor needs a destruction contract (§16.2b.3)", node)
            return false
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
            return false
        if drop_fn != 0:
            // Drop has nothing but the representation to pass.
            let dsig = self.get_sig(drop_fn)
            if dsig >= 0 and self.sig_get_param_count(dsig) != 1:
                let dn: str = self.pool_resolve(drop_fn)
                let n = self.sig_get_param_count(dsig)
                self.emit_error(f"resource '{rname}': 'drop {dn}' takes {n} parameters; the drop operation takes only the representation — an operation with further arguments is a 'destroys' (§16.2b.3)", node)
                return false
            if not self.verify_facade_destroyer(ri, drop_fn):
                return false
        for di in 0..destroyer_count:
            if not self.verify_facade_destroyer(ri, self.facade_resources[ri].destroyers[di]):
                return false
        if not self.verify_facade_dependency(ri):
            return false
        for pi in 0..producer_count:
            let p = self.facade_resources[ri].producers[pi]
            let slot = self.facade_resources[ri].out_params[pi]
            let pn: str = self.pool_resolve(p)
            if slot < 0 and self.facade_op_raw_beyond(p, -1, true):
                self.emit_error(f"resource '{rname}': producer '{pn}' is still a raw call after the facade covers its return (a variadic, a raw return, or a raw pointer parameter the facade does not describe); describe it with an fn item (§16.2b.5)", node)
                return false
            if slot >= 0 and self.facade_op_raw_beyond(p, slot, false):
                self.emit_error(f"resource '{rname}': producer '{pn}' is still a raw call after the facade covers its out parameter (a variadic, a raw status return, or a raw pointer parameter the facade does not describe); describe it with an fn item (§16.2b.5)", node)
                return false
        if self.facade_resources[ri].ok_const != 0 and init_fn == 0 and not self.verify_facade_ok_producers(ri):
            return false
        if init_fn != 0 and not self.verify_facade_init(ri):
            return false
        true

    // `ok CONST` interprets a producer's status (§16.2b.4): an out-parameter
    // producer's return. A direct return is the resource itself and a void
    // producer returns nothing, so a resource none of whose producers returns
    // a status gives the clause nothing to read. The status is compared with
    // an imported integer constant, so it is an integer (a C enum is one).
    // Every status the clause reads is carried by the one `<R>Error` the
    // projection renders (FacadeRender.w facade_render_error_type), so the
    // producers it reads return one status type.
    mut fn verify_facade_ok_producers(ri: i32) -> bool:
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let node = self.facade_resources[ri].node
        let cn: str = self.pool_resolve(self.facade_resources[ri].ok_const)
        var statuses = 0
        var shapes = ""
        var first = 0
        var first_ret = 0
        for pi in 0..self.facade_resources[ri].producers.len() as i32:
            let p = self.facade_resources[ri].producers[pi]
            let pn: str = self.pool_resolve(p)
            let sig = self.get_sig(p)
            let ret = self.sig_return_type(sig)
            let void_ret = ret == 0 or self.get_type_kind(self.resolve_alias(ret as TypeId)) == TypeKind.TY_VOID
            if self.facade_resources[ri].out_params[pi] < 0:
                shapes = shapes ++ (if shapes.len() > 0: ", " else: "") ++ f"'{pn}' returns the resource itself"
                continue
            if void_ret:
                shapes = shapes ++ (if shapes.len() > 0: ", " else: "") ++ f"'{pn}' returns nothing"
                continue
            if self.get_type_kind(self.numeric_operand_type(ret)) != TypeKind.TY_INT:
                let rt: str = self.type_name(ret)
                self.emit_error(f"resource '{rname}': 'ok {cn}' compares an integer status, but producer '{pn}' returns {rt} (§16.2b.4)", node)
                return false
            if first == 0:
                first = p
                first_ret = ret
            else if self.resolve_alias(ret as TypeId) != self.resolve_alias(first_ret as TypeId):
                let fnm: str = self.pool_resolve(first)
                let ft: str = self.type_name(first_ret)
                let rt: str = self.type_name(ret)
                let err = facade_render_error_name(rname)
                self.emit_error(f"resource '{rname}': 'ok {cn}' reads producer '{fnm}''s status as {ft} and producer '{pn}''s as {rt}; the one error type '{err}' carries a status of one type (§16.2b.4)", node)
                return false
            statuses = statuses + 1
        if statuses == 0 and shapes.len() == 0:
            self.emit_error(f"resource '{rname}': 'ok {cn}' names a status, but '{rname}' has no producer to read one from (§16.2b.4)", node)
            return false
        if statuses == 0:
            self.emit_error(f"resource '{rname}': 'ok {cn}' names a status, but no producer returns one to compare it with: {shapes} (§16.2b.4)", node)
            return false
        true

    // Whether `ok` projects this resource onto `Result[R, <R>Error]` (a
    // status-returning out-parameter producer, or a status-returning `init`),
    // and whether that error can hold a failed-state resource `Failed<R>` (an
    // out-parameter producer: failure may still produce, ruling §18).
    fn facade_projects_status(ri: i32) -> bool:
        if self.facade_resources[ri].ok_const == 0:
            return false
        let init_fn = self.facade_resources[ri].init
        if init_fn != 0:
            let isig = self.get_sig(init_fn)
            return isig >= 0 and self.get_type_kind(self.resolve_alias(self.sig_return_type(isig) as TypeId)) != TypeKind.TY_VOID
        self.facade_has_failed_state(ri)

    // A dependent resource has no failed state to own: its error is
    // `Failed | NothingProduced`, and a failure that still produced is
    // destroyed in the constructor (ruling §18; FacadeRender.w).
    fn facade_has_failed_state(ri: i32) -> bool:
        if self.facade_resource_dependent(ri):
            return false
        if self.facade_resources[ri].ok_const == 0:
            return false
        for pi in 0..self.facade_resources[ri].producers.len() as i32:
            if self.facade_resources[ri].out_params[pi] < 0:
                continue
            let sig = self.get_sig(self.facade_resources[ri].producers[pi])
            let ret = if sig >= 0: self.sig_return_type(sig) else: 0
            if ret != 0 and self.get_type_kind(self.resolve_alias(ret as TypeId)) != TypeKind.TY_VOID:
                return true
        false

    // The resource whose failed state a type is (`FailedDatabase` of
    // `Database`), or -1: a failed-state resource admits only the operations
    // the facade states are valid on the failure state, and there is no
    // clause for that yet, so it admits none (method lookup names this).
    fn facade_failed_state_resource(type_name: &str) -> i32:
        for ri in 0..self.facade_resources.len() as i32:
            if self.facade_projects_status(ri) and self.facade_has_failed_state(ri):
                let rname: str = self.pool_resolve(self.facade_resources[ri].name)
                if facade_render_failed_name(rname) == type_name:
                    return ri
        -1

    // The types a resource's rendering declares — `R`, and under the `ok`
    // projection `<R>Error` and `Failed<R>` — are the resource's names. If
    // the facade's module declares, or can see through an import, another
    // type of one of those names, the compiler never picks between them
    // (the §10.9/D57 rule for a written variant that collides with a
    // generated one, at the type level; Eric, 2026-09-23 on #1426): an error
    // naming both. The prelude's implicit names are not imports (D29).
    mut fn verify_facade_generated_names(ri: i32) -> bool:
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        var names: Vec[str] = Vec.new()
        var roles: Vec[str] = Vec.new()
        names.push(rname.clone())
        roles.push("the resource type")
        if self.facade_projects_status(ri):
            let cn: str = self.pool_resolve(self.facade_resources[ri].ok_const)
            names.push(facade_render_error_name(rname))
            roles.push(f"the error type of its 'ok {cn}' projection")
            if self.facade_has_failed_state(ri):
                names.push(facade_render_failed_name(rname))
                roles.push("the type of a resource a failed producer still produced")
        for ci in 0..self.foreign_contracts.len() as i32:
            if self.foreign_contracts[ci].returns_borrow_resource == self.facade_resources[ri].name:
                let bfn: str = self.pool_resolve(self.foreign_contracts[ci].fn_sym)
                names.push(facade_render_borrowed_name(rname))
                roles.push(f"the type of the borrowed '{rname}' that '{bfn}' returns")
                break
        let fname: str = self.pool_resolve(self.facade_resources[ri].facade)
        let rendered_file = "<facade " ++ fname ++ ">"
        for ni in 0..names.len() as i32:
            let other = self.facade_generated_name_clash(names[ni], rendered_file, ri)
            if other.len() > 0:
                let n = names[ni]
                let role = roles[ni]
                self.emit_error(f"resource '{rname}' renders '{n}', {role}, and {other}; the compiler never picks between two types of one name — rename one (§16.2b.4)", self.facade_resources[ri].node)
                return false
        true

    // The other declaration of a type named `name` visible from the current
    // module — beyond the one the rendering `rendered_file` makes — described
    // for a diagnostic, or "" when the name is the rendering's alone.
    fn facade_generated_name_clash(name: &str, rendered_file: &str, except_ri: i32) -> str:
        let sym = self.pool_lookup_symbol(name)
        if sym == 0:
            return ""
        var own = 0
        var other = ""
        var i = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
        while i >= 0:
            let node = self.decl_visibility_nodes[i]
            let path = self.decl_visibility_paths[i]
            let is_pub = self.decl_visibility_pub[i]
            i = self.decl_visibility_prev[i]
            if node == 0 or self.ast.kind(node) != NodeKind.NK_TYPE_DECL:
                continue
            let same_module = path == self.current_module_path
            let imported = not same_module and (sema_tier_path_is_std_implementation(path) == 0 or self.module_visible_no_prelude(path) != 0) and self.decl_visible_from_current_gated(path, is_pub, sym) != 0
            if not same_module and not imported:
                continue
            let di = self.find_decl_index(node)
            let file = self.facade_decl_file_name(di)
            if file == rendered_file and own == 0:
                own = 1
                continue
            if other.len() == 0:
                // Another facade's rendering is named by the resource that
                // states it, at its own line, never by the rendered text.
                let owner = if file.starts_with("<facade "): self.facade_resource_named(name, except_ri) else: -1
                if owner >= 0:
                    let at = self.facade_decl_location(self.facade_resources[owner].decl, self.facade_resources[owner].node)
                    other = f"{at} declares the resource '{name}'"
                else:
                    let at = self.facade_decl_location(di, node)
                    other = if same_module: f"{at} declares a type '{name}' in the same module" else: f"{at} declares a type '{name}', which this module imports"
        other

    // A resource of that name other than `except` (another facade block,
    // perhaps in another module, may render the same name).
    fn facade_resource_named(name: &str, except: i32) -> i32:
        for ri in 0..self.facade_resources.len() as i32:
            let rn: str = self.pool_resolve(self.facade_resources[ri].name)
            if rn == name and ri != except:
                return ri
        -1

    // The display name of the file a top-level declaration came from
    // (`<facade dbl>` for a rendered one), "" when unknown.
    fn facade_decl_file_name(di: i32) -> str:
        if di < 0 or di >= self.decl_source_file_ids.len() as i32:
            return ""
        let file_id = self.decl_source_file_ids[di]
        for si in 0..self.source_text_file_ids.len() as i32:
            if self.source_text_file_ids[si] == file_id and si < self.source_text_names.len() as i32:
                return with_str_clone_ref(self.source_text_names[si])
        ""

    // `file:line:col` of a declaration, for a diagnostic that names a second
    // declaration beside the one it points at.
    fn facade_decl_location(di: i32, node: i32) -> str:
        var file = self.facade_decl_file_name(di)
        if file.len() == 0 and di >= 0 and di < self.decl_source_paths.len() as i32:
            file = with_str_clone_ref(self.decl_source_paths[di])
        // The text of the declaration's own file: `node` may be a node inside
        // it (a facade block's resource), which no decl-index lookup finds.
        let text = if di >= 0 and di < self.decl_source_file_ids.len() as i32: self.source_text_view_for_file_id(self.decl_source_file_ids[di]) else: self.source_text_for_decl_node(node)
        let start = self.ast.get_start(node)
        var line = 1
        var col = 1
        var k = 0
        while k < start and k < text.len() as i32:
            if text[k] == '\n':
                line = line + 1
                col = 1
            else:
                col = col + 1
            k = k + 1
        f"{file}:{line}:{col}"

    // The constructor net: every producer of a verified resource has its
    // rendered `R.<producer>`; one without is a renderer defect. The
    // rendered type's shape is checked against the dependency facts the same
    // way (verify_facade_dependency_shape), and the facade's dependency
    // facts become the constructors' declared summaries.
    mut fn verify_facade_constructors(ri: i32):
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let node = self.facade_resources[ri].node
        for pi in 0..self.facade_resources[ri].producers.len() as i32:
            let p = self.facade_resources[ri].producers[pi]
            let pn: str = self.pool_resolve(p)
            if not self.facade_constructor_rendered(ri, p):
                let mn = self.facade_presented(ri, pn)
                self.emit_error(f"resource '{rname}': producer '{pn}' passed every facade check but no constructor '{rname}.{mn}' was rendered; the renderer cannot express this shape and did not say so — a compiler defect (§16.2b.4)", node)
        self.verify_facade_dependency_shape(ri)
        self.apply_facade_dependency_effects(ri)

    // The name operation `cname` is presented under on resource `ri`
    // (compiler/FacadeRender.w facade_render_present, §16.2b.11): the
    // renderer's own rule, read here so every net looks for what was
    // rendered — the C name less the representation's prefix, or the item's
    // `rename`, or the C name itself where shortening is ambiguous.
    fn facade_presented(ri: i32, cname: &str) -> str:
        facade_render_present(self.ast, self.pool, &self.decl_is_c_import, self.facade_resources[ri].node, cname)

    // The resource a producer's first parameter receives when a borrow of it
    // can hand C the parameter (FacadeRender.w facade_render_receiver): the
    // receiver `db.prepare(sql)` is a method of, beside the constructor
    // `Statement.prepare(db, sql)` — or -1.
    fn facade_receiver_of(f: i32) -> i32:
        let recv = self.facade_param_receives(f, 0)
        if recv.len() != 1 or not self.facade_received_presentable(recv[0], f, 0):
            return -1
        recv[0]

    // The signatures a producer of `ri` was rendered under: its
    // constructor, and the receiver method on the parent its first
    // parameter receives (a `from` producer, never the in-place `init`).
    fn facade_producer_sigs(ri: i32, owner: i32, f: i32) -> Vec[i32]:
        let out: Vec[i32] = Vec.new()
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let pn: str = self.pool_resolve(f)
        let sig = self.facade_constructor_sig(rname ++ "." ++ self.facade_presented(ri, pn))
        if sig >= 0:
            out.push(sig)
        if owner == FACADE_DEP_INIT:
            return out
        let host = self.facade_receiver_of(f)
        if host < 0:
            return out
        let hn: str = self.pool_resolve(self.facade_resources[host].name)
        let wtext = hn ++ "." ++ self.facade_presented(host, pn)
        var wsig = self.facade_constructor_sig(wtext)
        // The receiver method is rendered inside `impl Host:`, so its
        // declaration is named by the method alone and its signature by the
        // qualified text (stage 12: `db.prepare(…)` let a statement outlive
        // its database while `Statement.prepare(db, …)` refused it).
        if wsig < 0 and self.sig_text_index.contains(wtext):
            wsig = self.sig_text_index.get(wtext).unwrap()
        if wsig >= 0:
            out.push(wsig)
        out

    fn facade_constructor_rendered(ri: i32, p: i32) -> bool:
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let pn: str = self.pool_resolve(p)
        let want = rname ++ "." ++ self.facade_presented(ri, pn)
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) == NodeKind.NK_FN_DECL and self.safe_symbol_text(self.ast.get_data0(decl)) == want:
                return true
        false

    // In-place initialization (ruling §13, §16.2b.4): `init` takes a pointer
    // to the storage — a by-value first parameter would initialize a copy —
    // and `preinit` returns the storage it constructs (it stands where
    // `Representation.zeroed()` would). `ok` reads the init's status, so a
    // void init has none to read. Either call must be safe once covered.
    mut fn verify_facade_init(ri: i32) -> bool:
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let node = self.facade_resources[ri].node
        let init_fn = self.facade_resources[ri].init
        let iname: str = self.pool_resolve(init_fn)
        let isig = self.get_sig(init_fn)
        if isig < 0:
            return false
        let repr = self.resolve_alias(self.facade_resources[ri].repr_tid as TypeId)
        if self.facade_same_type(self.sig_param_type(isig, 0), repr as i32):
            self.emit_error(f"resource '{rname}': 'init {iname}' takes the representation by value, so it would initialize a copy; an in-place initializer takes a pointer to the storage (§16.2b.4)", node)
            return false
        if self.facade_resources[ri].ok_const != 0 and self.get_type_kind(self.resolve_alias(self.sig_return_type(isig) as TypeId)) == TypeKind.TY_VOID:
            let cn: str = self.pool_resolve(self.facade_resources[ri].ok_const)
            self.emit_error(f"resource '{rname}': 'ok {cn}' names a status but 'init {iname}' returns nothing to compare it with (§16.2b.4)", node)
            return false
        if self.facade_resources[ri].ok_const != 0 and self.get_type_kind(self.numeric_operand_type(self.sig_return_type(isig))) != TypeKind.TY_INT:
            let cn: str = self.pool_resolve(self.facade_resources[ri].ok_const)
            let rt: str = self.type_name(self.sig_return_type(isig))
            self.emit_error(f"resource '{rname}': 'ok {cn}' compares an integer status, but 'init {iname}' returns {rt} (§16.2b.4)", node)
            return false
        if self.facade_op_raw_beyond(init_fn, 0, false):
            self.emit_error(f"resource '{rname}': 'init {iname}' is still a raw call after the facade covers the storage (a variadic, a raw return, or a raw pointer parameter the facade does not describe); describe it with an fn item (§16.2b.5)", node)
            return false
        // A pinned resource's representation lives in its cell (D54): every
        // operation reaches it by address. One taking it by value would act
        // on a copy of a representation whose address the library may keep.
        if self.facade_resources[ri].movable == 0:
            let drop_fn = self.facade_resources[ri].drop
            if drop_fn != 0 and not self.verify_facade_pinned_op(ri, drop_fn):
                return false
            for di in 0..self.facade_resources[ri].destroyers.len() as i32:
                if not self.verify_facade_pinned_op(ri, self.facade_resources[ri].destroyers[di]):
                    return false
        let preinit_fn = self.facade_resources[ri].preinit
        if preinit_fn != 0 and self.facade_op_raw_beyond(preinit_fn, -1, true):
            let pn: str = self.pool_resolve(preinit_fn)
            self.emit_error(f"resource '{rname}': 'preinit {pn}' is still a raw call after the facade covers its return (a variadic or a raw pointer parameter the facade does not describe); describe it with an fn item (§16.2b.5)", node)
            return false
        // The constructor takes preinit's parameters and then init's: a C
        // name both spell would be one With parameter with two meanings.
        if preinit_fn != 0:
            let psig = self.get_sig(preinit_fn)
            for pi in 0..self.sig_get_param_count(psig):
                let pname = self.facade_param_c_name(preinit_fn, pi)
                for ii in 1..self.sig_get_param_count(isig):
                    if self.facade_param_c_name(init_fn, ii) == pname:
                        let pn: str = self.pool_resolve(preinit_fn)
                        self.emit_error(f"resource '{rname}': 'preinit {pn}' and 'init {iname}' both take a parameter named '{pname}'; the constructor takes both operations' parameters and cannot tell them apart (§16.2b.4)", node)
                        return false
        true

    mut fn verify_facade_pinned_op(ri: i32, f: i32) -> bool:
        let sig = self.get_sig(f)
        if sig < 0 or not self.facade_same_type(self.sig_param_type(sig, 0), self.facade_resources[ri].repr_tid):
            return true
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let fname: str = self.pool_resolve(f)
        self.emit_error(f"resource '{rname}': '{fname}' takes the representation by value, but an in-place resource is pinned — its operations take the address of the representation; state 'movable' if no operation keeps that address (§16.2b.3)", self.facade_resources[ri].node)
        false

    // The rendered type: a struct declared under the resource's own name.
    fn facade_resource_rendered(ri: i32) -> bool:
        let name = self.facade_resources[ri].name
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) == NodeKind.NK_TYPE_DECL and self.ast.get_data0(decl) == name and self.ast.get_data2(decl) % 8 == TypeDeclKind.Struct as i32:
                return true
        false

    mut fn verify_facade_destroyer(ri: i32, f: i32) -> bool:
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let node = self.facade_resources[ri].node
        let fname: str = self.pool_resolve(f)
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
                return false
        if self.facade_op_raw_beyond(f, 0, false):
            self.emit_error(f"resource '{rname}': '{fname}' is still a raw call after the facade covers the representation (a variadic, a raw return, or a raw pointer parameter the facade does not describe); describe it with an fn item (§16.2b.5)", node)
            return false
        true

    mut fn collect_c_facade(di: i32, node: i32):
        let facade = self.ast.get_data0(node)
        let extra_start = self.ast.get_data1(node)
        let count = self.ast.get_data2(node)
        self.current_facade_sym = facade
        self.current_facade_node = node
        for i in 0..count:
            let item = self.ast.get_extra(extra_start + i)
            let kind = self.ast.kind(item)
            if kind == NodeKind.NK_FACADE_DOMAIN:
                self.collect_facade_domain(item)
            else if kind == NodeKind.NK_FACADE_CONVENTION:
                self.facade_convention_nodes.push(item)
                self.warn_facade_profile_ambiguities(item)
        for i in 0..count:
            let item = self.ast.get_extra(extra_start + i)
            if self.ast.kind(item) == NodeKind.NK_FACADE_RESOURCE:
                self.collect_facade_resource(di, facade, item)
        for i in 0..count:
            let item = self.ast.get_extra(extra_start + i)
            if self.ast.kind(item) == NodeKind.NK_FACADE_FN:
                self.collect_facade_fn(di, facade, item)

    // ── stage 11: convention profiles (ruling §7, §59; spec §16.2b.12) ──
    //
    // The frontend applied each adopted profile before the facades rendered
    // (compiler/FacadeProfile.w) and left one NK_FACADE_PROFILE_MATCH per
    // outcome on the `use convention` item. A clause it stated is collected
    // and verified above like any clause; its provenance is the rule it
    // carries (facade_clause_profile_rule). An ambiguous match contributed
    // nothing (ruling §7.1), and says so here: the resource may then fail
    // "never half-model" with no destroy path, and this warning names the
    // profile, the rule, the item and the clause that resolves it (§8).

    // The `c convention` block a rule belongs to, as a declaration index.
    fn facade_rule_profile_decl(rule: i32) -> i32:
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_C_CONVENTION: continue
            let start = self.ast.get_data1(decl)
            for k in 0..self.ast.get_data2(decl):
                if self.ast.get_extra(start + k) == rule: return di
        -1

    // The `c facade` block a `use convention` item sits in, as a declaration
    // index: the file a shadowing clause or fn item is read in.
    fn facade_convention_decl(item: i32) -> i32:
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_C_FACADE: continue
            let start = self.ast.get_data1(decl)
            for k in 0..self.ast.get_data2(decl):
                if self.ast.get_extra(start + k) == item: return di
        -1

    fn facade_rule_profile_name(rule: i32) -> str:
        let di = self.facade_rule_profile_decl(rule)
        if di < 0: return "?"
        self.safe_symbol_text(self.ast.get_data0(self.ast.get_decl(di)))

    fn facade_rule_name(rule: i32) -> str: self.safe_symbol_text(self.ast.get_data0(rule))

    // The rule's template as the profile spells it: `drop *_unref`,
    // `from *_open(out param 1)`, `fn *_get lend`.
    fn facade_rule_template_text(rule: i32) -> str:
        let rx = self.ast.get_data1(rule)
        let pattern = self.safe_symbol_text(self.ast.get_extra(rx))
        let template = self.ast.get_extra(rx + 1)
        let kind = self.ast.get_data0(template)
        if self.ast.get_extra(rx + 2) != 0: return f"fn {pattern} " ++ facade_clause_name(kind)
        var text = facade_clause_name(kind) ++ " " ++ pattern
        if kind == FACADE_CLAUSE_FROM and self.ast.get_extra(self.ast.get_data1(template) + 1) != 0: text = text ++ "(out param …)"
        if kind == FACADE_CLAUSE_INIT: text = text ++ "(self)"
        text

    fn facade_rule_is_fn(rule: i32) -> bool: self.ast.get_extra(self.ast.get_data1(rule) + 2) != 0

    // A match record's parts: (rule, status, subject, candidate syms). The
    // subject is the resource item for a resource rule and the function's
    // name symbol for an fn rule (0 when the rule matched nothing).
    fn facade_profile_match(rec: i32) -> (i32, i32, i32, Vec[i32]):
        let rx = self.ast.get_data2(rec)
        let cands: Vec[i32] = Vec.new()
        for i in 0..self.ast.get_extra(rx + 1): cands.push(self.ast.get_extra(rx + 2 + i))
        (self.ast.get_data0(rec), self.ast.get_data1(rec), self.ast.get_extra(rx), cands)

    fn facade_profile_matches(item: i32) -> Vec[i32]:
        let out: Vec[i32] = Vec.new()
        let start = self.ast.get_data0(item)
        let path_count = self.ast.get_data1(item)
        for m in 0..self.ast.get_data2(item): out.push(self.ast.get_extra(start + path_count + m))
        out

    fn facade_profile_subject_text(rule: i32, subject: i32) -> str:
        if subject == 0: return "no declaration"
        if self.facade_rule_is_fn(rule): return "'" ++ self.safe_symbol_text(subject) ++ "'"
        "resource '" ++ self.safe_symbol_text(self.ast.get_data0(subject)) ++ "'"

    fn facade_profile_names(syms: &Vec[i32]) -> str:
        var out = ""
        for i in 0..syms.len() as i32:
            out = out ++ (if i > 0: ", " else: "") ++ self.safe_symbol_text(syms[i])
        out

    mut fn warn_facade_profile_ambiguities(item: i32):
        let recs = self.facade_profile_matches(item)
        for m in 0..recs.len() as i32:
            let (rule, status, subject, cands) = self.facade_profile_match(recs[m])
            if status != FACADE_PROFILE_AMBIGUOUS: continue
            let profile = self.facade_rule_profile_name(rule)
            let rname = self.facade_rule_name(rule)
            let template = self.facade_rule_template_text(rule)
            let what = self.facade_profile_subject_text(rule, subject)
            if self.facade_rule_is_fn(rule):
                self.emit_warning(f"use convention {profile}: rules {self.facade_profile_names(&cands)} all match {what}; a profile fact must resolve uniquely, so none of them applies (§16.2b.12) — describe '{self.safe_symbol_text(subject)}' with an fn item to state its contract", item)
            else:
                let kind = self.ast.get_data0(self.ast.get_extra(self.ast.get_data1(rule) + 1))
                self.emit_warning(f"use convention {profile}: rule {rname} ({template}) matches {cands.len() as i32} candidates for {what}: {self.facade_profile_names(&cands)}; a profile fact must resolve uniquely, so the rule contributes nothing (§16.2b.12) — state '{facade_clause_name(kind)} <fn>' on the resource to choose", item)

    mut fn collect_facade_domain(item: i32):
        let name = self.ast.get_data0(item)
        if self.facade_domains.contains(name):
            let dn: str = self.pool_resolve(name)
            // Ruling §35: a facade "may also merge domains from distinct
            // imports when they refer to the same actual state" — two facades
            // declaring `domain errno thread` name one errno (the runtime's
            // own blocks and a program's libc facade in one unit, D30
            // rt-in-unit), so the second declaration joins the first: a call
            // either facade describes touches the one domain. The same
            // facade declaring it twice, or a different scope, is an error.
            let di: i32 = self.facade_domain_index.get(name).unwrap()
            if self.facade_domain_list[di].kind != self.ast.get_data1(item):
                let have: str = self.pool_resolve(self.facade_domain_list[di].kind)
                let want: str = self.pool_resolve(self.ast.get_data1(item))
                self.emit_error(f"domain '{dn}' is '{have}' in facade '{self.pool_resolve(self.facade_domain_list[di].facade)}' and '{want}' here; one state has one scope (§16.2b.7)", item)
                return
            // Identity is the block, not the name: the runtime's files each
            // carry a block named `libc`, and a program may spread one
            // facade over files too.
            for bi in 0..self.facade_domain_list[di].blocks.len() as i32:
                if self.facade_domain_list[di].blocks[bi] == self.current_facade_node:
                    self.emit_error(f"domain '{dn}' is declared twice (§16.2b.7)", item)
                    return
            self.facade_domain_list[di].blocks.push(self.current_facade_node)
            var known = false
            for fi in 0..self.facade_domain_list[di].facades.len() as i32:
                if self.facade_domain_list[di].facades[fi] == self.current_facade_sym: known = true
            if not known: self.facade_domain_list[di].facades.push(self.current_facade_sym)
            return
        self.facade_domains.insert(name, self.ast.get_data1(item))
        // The domain's origin symbol: what a view borrowed from it depends
        // on, the way a view of a binding depends on the binding's symbol
        // (spelled so no binding can be named it).
        let dn: str = self.pool_resolve(name)
        let origin_sym = self.pool_intern("<domain " ++ dn ++ ">")
        self.facade_domain_index.insert(name, self.facade_domain_list.len() as i32)
        self.facade_domain_origin_index.insert(origin_sym, self.facade_domain_list.len() as i32)
        let facades: Vec[i32] = Vec.new()
        facades.push(self.current_facade_sym)
        let blocks: Vec[i32] = Vec.new()
        blocks.push(self.current_facade_node)
        self.facade_domain_list.push(FacadeDomain { name, kind: self.ast.get_data1(item), facade: self.current_facade_sym, facades, blocks, node: item, origin_sym, files: Vec.new() })

    // ── resources ────────────────────────────────────────────────────────

    mut fn collect_facade_resource(decl: i32, facade: i32, item: i32):
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
        var r = FacadeResource { name, facade, node: item, decl, repr_tid, producers: Vec.new(), out_params: Vec.new(), init: 0, preinit: 0, drop: 0, destroyers: Vec.new(), ok_const: 0, borrows: Vec.new(), borrows_owner: Vec.new(), borrows_nodes: Vec.new(), last_producer: -2, independent: 0, independent_node: 0, movable: 0, thread_caps: 0 }
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
            // A resource may have several producers (fopen, fdopen and
            // tmpfile each produce the FILE that fclose destroys): each
            // `from` is one constructor over the same destruction contract.
            r.producers.push(producer)
            r.out_params.push(-1)
            r.last_producer = r.producers.len() as i32 - 1
            let out_ref = self.ast.get_extra(ops + 1)
            if out_ref != 0:
                let pi = self.facade_resolve_param(out_ref, producer, sig)
                if pi < 0:
                    return r
                // Out-parameter production initializes the slot to NULL and
                // inspects it after the call (ruling §16, spec §16.2b.4):
                // it produces a pointer resource. A by-value representation
                // has no NULL to inspect; C filling caller storage is the
                // in-place shape.
                if self.get_type_kind(self.resolve_alias(r.repr_tid as TypeId)) != TypeKind.TY_PTR:
                    let pn: str = self.pool_resolve(producer)
                    let rt: str = self.type_name(r.repr_tid)
                    self.emit_error_with_help(f"resource '{rname}': 'from {pn}(out param …)' produces through a pointer out parameter, which is initialized to NULL and inspected after the call; '{rname}' wraps {rt}, which has no NULL (§16.2b.4)", clause, f"a resource C initializes in caller storage is produced in place: 'init {pn}(self)'")
                    return r
                let pty = self.resolve_alias(self.sig_param_type(sig, pi) as TypeId)
                if self.get_type_kind(pty) != TypeKind.TY_PTR or not self.facade_same_type(self.get_type_d0(pty), r.repr_tid):
                    let shown = self.facade_param_display(producer, sig, pi)
                    self.emit_error(f"resource '{rname}': the out parameter {shown} is not a pointer to the representation (§16.2b.13)", clause)
                    return r
                if self.get_type_d1(pty) == 0:
                    let shown = self.facade_param_display(producer, sig, pi)
                    self.emit_error(f"resource '{rname}': the out parameter {shown} is a pointer to const; C cannot store the produced resource through it (§16.2b.4, §16.2b.13)", clause)
                    return r
                let last = r.out_params.len() as i32 - 1
                r.out_params[last] = pi
            else:
                if not self.facade_same_type(self.sig_return_type(sig), r.repr_tid):
                    let rt: str = self.type_name(self.sig_return_type(sig))
                    let pn: str = self.pool_resolve(producer)
                    self.emit_error(f"resource '{rname}': producer '{pn}' returns {rt}, not the representation (§16.2b.13)", clause)
            return r
        if kind == FACADE_CLAUSE_PREINIT:
            // `preinit` constructs the storage (ruling §13.1): it returns the
            // representation, standing where `Representation.zeroed()` would.
            let f = self.ast.get_extra(ops)
            let sig = self.facade_fn_sig(f, clause)
            if sig < 0:
                return r
            if not self.facade_same_type(self.sig_return_type(sig), r.repr_tid):
                let fnm: str = self.pool_resolve(f)
                let rt: str = self.type_name(self.sig_return_type(sig))
                self.emit_error(f"resource '{rname}': 'preinit {fnm}' returns {rt}, not the representation; preinit constructs the storage that init fills (§16.2b.4)", clause)
                return r
            r.preinit = f
            return r
        if kind == FACADE_CLAUSE_INIT or kind == FACADE_CLAUSE_DROP or kind == FACADE_CLAUSE_DESTROYS:
            let f = self.ast.get_extra(ops)
            let sig = self.facade_fn_sig(f, clause)
            if sig < 0:
                return r
            if not self.facade_accepts_repr(sig, r.repr_tid):
                let fnm: str = self.pool_resolve(f)
                self.emit_error(f"resource '{rname}': '{fnm}' does not take the representation as its first parameter (§16.2b.13)", clause)
                return r
            if kind == FACADE_CLAUSE_INIT:
                r.init = f
                r.last_producer = FACADE_DEP_INIT
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
            // `borrows` names a parameter of the producer stated before it:
            // a `from`, or the `init` (spec §16.2b.6 — "a facade may make the
            // relationship precise").
            if r.last_producer == -2:
                self.emit_error(f"resource '{rname}': 'borrows' names a parameter of the producer; state 'from <producer>' first, or 'init <fn>(self)' (§16.2b.6)", clause)
                return r
            let producer = if r.last_producer == FACADE_DEP_INIT: r.init else: r.producers[r.last_producer]
            let sig = self.get_sig(producer)
            if sig < 0:
                return r
            let pi = self.facade_resolve_param(self.ast.get_extra(ops), producer, sig)
            if pi < 0:
                return r
            let shown = self.facade_param_display(producer, sig, pi)
            let pn: str = self.pool_resolve(producer)
            let slot = if r.last_producer == FACADE_DEP_INIT: 0 else: r.out_params[r.last_producer]
            if pi == slot:
                let what = if r.last_producer == FACADE_DEP_INIT: "the storage 'init' initializes" else: "the out parameter the resource is produced through"
                self.emit_error(f"resource '{rname}': 'borrows' names {shown} of '{pn}', {what}; 'borrows' names a parent resource the producer receives (§16.2b.6)", clause)
                return r
            // That the parameter receives a modeled resource is verified once
            // every facade's resources are known (verify_facade_dependency).
            r.borrows.push(pi)
            r.borrows_owner.push(r.last_producer)
            r.borrows_nodes.push(clause)
            return r
        if kind == FACADE_CLAUSE_INDEPENDENT:
            r.independent = 1
            r.independent_node = clause
            return r
        if kind == FACADE_CLAUSE_MOVABLE:
            r.movable = 1
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

    mut fn collect_facade_fn(decl: i32, facade: i32, item: i32):
        let fn_sym = self.ast.get_data0(item)
        let fname: str = self.pool_resolve(fn_sym)
        let sig = self.facade_fn_sig(fn_sym, item)
        if sig < 0:
            return
        if self.foreign_contract_index.contains(fn_sym):
            let prev: i32 = self.foreign_contract_index.get(fn_sym).unwrap()
            if self.foreign_contracts[prev].decl == decl:
                self.emit_error(f"fn '{fname}' is described twice in this facade (§16.2b)", item)
                return
            // Another block describes it too. The same clauses restated are
            // the same facts — the runtime's files each carry a block naming
            // `rt_libc_exit` identically, and meet in one unit (D30
            // rt-in-unit) — so a word-for-word restatement is accepted;
            // different clauses are two contracts for one function, refused.
            if self.facade_item_words(self.foreign_contracts[prev].decl, self.foreign_contracts[prev].node) == self.facade_item_words(decl, item):
                return
            self.emit_error(f"fn '{fname}' is described by two facade blocks with different clauses; one function has one contract — restate it word for word or describe it once (§16.2b)", item)
            return
        var c = ForeignContract { fn_sym, decl, facade, node: item, lend: 0, destroys: 0, consumes: Vec.new(), consumes_destroyed_by: Vec.new(), retains: Vec.new(), retains_by: Vec.new(), returns_borrow_resource: 0, returns_borrow_from: -1, returns_borrow_domain: 0, returns_static_tid: 0, preserves_params: Vec.new(), preserves_domains: Vec.new(), of_resource: 0, rename: 0, callback_thread_any: 0, callback_consumes: Vec.new(), callback_userdata_cb: Vec.new(), callback_userdata_of: Vec.new(), valid_on_failed: 0, nullable_params: Vec.new(), buffer_ptr: Vec.new(), buffer_len: Vec.new(), buffer_inout: Vec.new(), fixed_params: Vec.new(), fixed_literals: Vec.new(), ok_const: 0 }
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
                // Ruling §24: transfer with a destructor callback is how
                // caller-owned userdata moves into C. A consumed resource
                // handle has its own destroyer (`destroys`, §16.2b.5).
                if not self.facade_param_is_userdata(fn_sym, sig, pi):
                    let shown = self.facade_param_display(fn_sym, sig, pi)
                    self.emit_error(f"fn '{fname}': consumes {shown} destroyed_by …: a destroy callback destroys userdata (a 'void *' no resource wraps); a consumed resource is destroyed by the operation its facade names (§16.2b.5, §16.2b.9)", clause)
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
            else if self.facade_param_is_userdata(fn_sym, sig, pi):
                // Never half-model (ruling §9, §24): a `void *` userdata
                // moved into C with no destruction path is a leak by
                // contract. A consumed resource handle has its own
                // destroyer; userdata has only the callback C promises.
                let shown = self.facade_param_display(fn_sym, sig, pi)
                self.emit_error_with_help(f"fn '{fname}': consumes {shown}, a 'void *' userdata, with no destroy contract; C would own a value nothing destroys — never half-model unsafely (§16.2b.5, §16.2b.9)", clause, "name the callback C invokes to destroy it: 'consumes param N destroyed_by param M'")
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
            // Ruling §25, §45: retention is by a resource, and lasts until
            // the retaining resource is destroyed (no release is modeled).
            if self.facade_param_receives(fn_sym, b).len() != 1:
                let shown = self.facade_param_display(fn_sym, sig, b)
                let why = if self.facade_param_receives(fn_sym, b).len() == 0: "receives no modeled resource" else: "receives a representation several resources wrap; the facade has not assigned it (§16.2b.3)"
                self.emit_error(f"fn '{fname}': 'retains … by' names {shown}, which {why}; a retained value is kept by a resource and released when that resource is destroyed (§16.2b.5, §16.2b.9)", clause)
                return c
            // What can be retained: a callback (a code pointer, nothing to
            // keep), its `void *` userdata (kept by the resource, ruling
            // §45), or a C string (the #602 raw-call rule, §16.3c).
            let userdata = self.facade_param_is_userdata(fn_sym, sig, a)
            let callable = self.facade_param_is_callable(sig, a)
            if not userdata and not callable and self.ci_type_is_const_c_string_input(self.sig_param_type(sig, a)) == 0:
                let shown = self.facade_param_display(fn_sym, sig, a)
                self.emit_error(f"fn '{fname}': retains {shown}; retention is modeled for a callback, its 'void *' userdata, and a C string — nothing else is kept by a resource (§16.2b.9)", clause)
                return c
            if (userdata or callable) and b != 0:
                let shown = self.facade_param_display(fn_sym, sig, b)
                self.emit_error(f"fn '{fname}': 'retains … by' names {shown}, but a retained callback or userdata is kept by the resource the operation is a method of, its first parameter; retention by another parameter is not modeled (§16.2b.9)", clause)
                return c
            c.retains.push(a)
            c.retains_by.push(b)
            self.mark_param_retained(fn_sym, a)
            return c
        if kind == FACADE_CLAUSE_CALLBACK_USERDATA:
            // `callback param N userdata param M` (spec §16.2b.9; the
            // spelling is this stage's — the ruling ties a destroy callback
            // to its userdata by position, §24, and says nothing for the
            // others): typing a `void *` as the userdata's With type is
            // capability-granting, so it is stated, never inferred from
            // there being one of each.
            let cb = self.facade_resolve_param(self.ast.get_extra(ops), fn_sym, sig)
            if cb < 0:
                return c
            let ud = self.facade_resolve_param(self.ast.get_extra(ops + 1), fn_sym, sig)
            if ud < 0:
                return c
            if not self.facade_param_is_callable(sig, cb):
                let shown = self.facade_param_display(fn_sym, sig, cb)
                self.emit_error(f"fn '{fname}': 'callback param {cb}' names {shown}, which is not callable (§16.2b.9, §16.2b.13)", clause)
                return c
            if not self.facade_param_is_userdata(fn_sym, sig, ud):
                let shown = self.facade_param_display(fn_sym, sig, ud)
                self.emit_error(f"fn '{fname}': 'userdata param {ud}' names {shown}, which is not a 'void *'; a callback's userdata is the untyped pointer C hands back to it (§16.2b.9)", clause)
                return c
            let slot = self.facade_callable_userdata_slot(sig, cb)
            if slot < 0:
                let shown = self.facade_param_display(fn_sym, sig, cb)
                let n = self.facade_callable_userdata_slot_count(sig, cb)
                self.emit_error(f"fn '{fname}': the callback {shown} has {n} 'void *' parameter(s); a callback receiving userdata has exactly one, which is where the userdata arrives (§16.2b.9)", clause)
                return c
            for k in 0..c.callback_userdata_cb.len() as i32:
                if c.callback_userdata_cb[k] == cb:
                    self.emit_error(f"fn '{fname}': 'callback param {cb}' is given its userdata twice (§16.2b.9)", clause)
                    return c
            c.callback_userdata_cb.push(cb)
            c.callback_userdata_of.push(ud)
            return c
        if kind == FACADE_CLAUSE_RETURNS_BORROW:
            let res = self.ast.get_extra(ops)
            let domain = self.ast.get_extra(ops + 2)
            // `returns borrow CStr from param N` / `from domain D` (ruling
            // §32, §33, §41; spec §16.2b.8): the borrowed modeled text. Its
            // origin is the resource or the C string the parameter receives,
            // or a declared foreign-state domain; With invents none (§31).
            if self.pool_resolve(res) == "CStr":
                if not self.facade_type_is_c_string_ptr(self.sig_return_type(sig)):
                    let rt: str = self.type_name(self.sig_return_type(sig))
                    self.emit_error(f"fn '{fname}' returns {rt}, not a C string ('char *' or 'unsigned char *'); 'returns borrow CStr' describes a NUL-terminated foreign string (§16.2b.8)", clause)
                    return c
                if domain != 0:
                    if not self.facade_domains.contains(domain):
                        let dn: str = self.pool_resolve(domain)
                        self.emit_error(f"fn '{fname}': unknown domain '{dn}'; declare it with 'domain {dn} process|thread|resource|static' (§16.2b.7)", clause)
                        return c
                    c.returns_borrow_domain = domain
                else:
                    let from = self.facade_resolve_param(self.ast.get_extra(ops + 1), fn_sym, sig)
                    if from < 0:
                        return c
                    let origin = self.facade_param_receives(fn_sym, from)
                    if origin.len() != 1 and self.ci_type_is_const_c_string_input(self.sig_param_type(sig, from)) == 0:
                        let shown = self.facade_param_display(fn_sym, sig, from)
                        let why = if origin.len() == 0: "receives no modeled resource and is not a C string" else: "receives a representation several resources wrap; the facade has not assigned it (§16.2b.3)"
                        self.emit_error(f"fn '{fname}': 'returns borrow CStr from param {from}' names {shown}, which {why}; a borrowed CStr is a view of the resource or the C string its origin parameter receives, or of a domain ('from domain <name>') — With does not invent an origin (§16.2b.7)", clause)
                        return c
                    c.returns_borrow_from = from
                c.returns_borrow_resource = res
                return c
            if domain != 0:
                let rn: str = self.pool_resolve(res)
                self.emit_error(f"fn '{fname}': 'returns borrow {rn} from domain' — a borrowed resource is a view of the resource a parameter receives ('from param <ref>'); a foreign-state domain is the origin of borrowed memory that no resource owns, a CStr (§16.2b.6, §16.2b.7)", clause)
                return c
            if not self.facade_resource_index.contains(res):
                let rn: str = self.pool_resolve(res)
                self.emit_error(f"fn '{fname}': unknown resource '{rn}' (§16.2b.6)", clause)
                return c
            let from = self.facade_resolve_param(self.ast.get_extra(ops + 1), fn_sym, sig)
            if from < 0:
                return c
            let ri: i32 = self.facade_resource_index.get(res).unwrap()
            let repr = self.facade_resources[ri].repr_tid
            if not self.facade_same_type(self.sig_return_type(sig), repr):
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
            // Ruling §40 states `returns static CStr`; static storage of
            // another type is not ruled and stays as C declares it.
            if self.resolve_alias(tid as TypeId) != self.ty_cstr:
                let tn: str = self.type_name(tid)
                self.emit_error(f"fn '{fname}': 'returns static {tn}' — only 'returns static CStr' is ruled (§16.2b.7); a static pointer of another type stays as C declares it", clause)
                return c
            if not self.facade_type_is_c_string_ptr(self.sig_return_type(sig)):
                let rt: str = self.type_name(self.sig_return_type(sig))
                self.emit_error(f"fn '{fname}' returns {rt}, not a C string ('char *' or 'unsigned char *'); 'returns static CStr' describes a NUL-terminated foreign string (§16.2b.8)", clause)
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
        if kind == FACADE_CLAUSE_VALID_ON_FAILED:
            // `valid on failed` (spec §16.2b.4: a failed-state resource
            // "admits raw access only, unless the facade marks an operation
            // as valid on the failure state"; ruling §18). The shape it may
            // mark is verified once every resource is known
            // (verify_facade_failed_state_items).
            c.valid_on_failed = 1
            return c
        if kind == FACADE_CLAUSE_NULLABLE:
            // `nullable param N` (ruling §43, spec §16.2b.8: "where safe
            // modeling requires nullability and the header does not
            // establish it, the facade … must"): NULL is a value the
            // parameter accepts. What the rendering makes of it is verified
            // once the pairing is known (verify_facade_callback_items): a
            // callback paired with userdata is `Option[extern "C" fn(&U, …)]`
            // and its userdata `Option[&U]` (#1618). A raw pointer parameter
            // accepts `null` as C declares it and the clause adds nothing.
            let pi = self.facade_resolve_param(self.ast.get_extra(ops), fn_sym, sig)
            if pi < 0:
                return c
            let pk = self.get_type_kind(self.resolve_alias(self.sig_param_type(sig, pi) as TypeId))
            if pk != TypeKind.TY_PTR and not self.facade_param_is_callable(sig, pi):
                let shown = self.facade_param_display(fn_sym, sig, pi)
                self.emit_error(f"fn '{fname}': nullable {shown}: not a pointer, NULL is not a value it can take (§16.2b.8, §16.2b.13)", clause)
                return c
            for k in 0..c.nullable_params.len() as i32:
                if c.nullable_params[k] == pi:
                    self.emit_error(f"fn '{fname}': 'nullable param {pi}' is stated twice (§16.2b.8)", clause)
                    return c
            c.nullable_params.push(pi)
            return c
        if kind == FACADE_CLAUSE_BUFFER:
            // `buffer param P len param L` / `buffer param P capacity param L
            // inout` (D64, §16.2b.8): P and L are one `[]u8` (`[]mut u8`)
            // parameter. The length counts bytes, so P points at bytes; L
            // is the integer C reads, or — inout — the pointer to the
            // integer C reads and writes back.
            let p = self.facade_resolve_param(self.ast.get_extra(ops), fn_sym, sig)
            if p < 0:
                return c
            let l = self.facade_resolve_param(self.ast.get_extra(ops + 1), fn_sym, sig)
            if l < 0:
                return c
            let inout = self.ast.get_extra(ops + 2)
            let ptype = self.resolve_alias(self.sig_param_type(sig, p) as TypeId)
            if self.get_type_kind(ptype) != TypeKind.TY_PTR or not self.facade_type_is_byte(self.get_type_d0(ptype)):
                let shown = self.facade_param_display(fn_sym, sig, p)
                self.emit_error(f"fn '{fname}': 'buffer param {p}' names {shown}, which is not a pointer to bytes ('char *', 'unsigned char *', 'void *' or a typedef of one); a buffer's length counts bytes, and the clause renders []u8, never an element slice of another type (§16.2b.8)", clause)
                return c
            if inout != 0 and self.get_type_d1(ptype) == 0:
                let shown = self.facade_param_display(fn_sym, sig, p)
                self.emit_error(f"fn '{fname}': 'buffer param {p} capacity … inout' names {shown}, a const pointer; C cannot write into it — a buffer C fills is 'T *', and an input buffer is paired with 'len' (§16.2b.8)", clause)
                return c
            if p == l:
                let shown = self.facade_param_display(fn_sym, sig, p)
                self.emit_error(f"fn '{fname}': 'buffer param {p}' pairs {shown} with itself; a pairing names the pointer and the distinct integer that carries its length (§16.2b.8)", clause)
                return c
            let ltype = self.resolve_alias(self.sig_param_type(sig, l) as TypeId)
            if inout == 0:
                if self.get_type_kind(self.numeric_operand_type(ltype as i32)) != TypeKind.TY_INT:
                    let shown = self.facade_param_display(fn_sym, sig, l)
                    self.emit_error(f"fn '{fname}': 'len param {l}' names {shown}, which is not an integer; the length parameter carries the byte count C reads (§16.2b.8)", clause)
                    return c
            else if self.get_type_kind(ltype) != TypeKind.TY_PTR or self.get_type_d1(ltype) == 0 or self.get_type_kind(self.numeric_operand_type(self.get_type_d0(ltype))) != TypeKind.TY_INT:
                let shown = self.facade_param_display(fn_sym, sig, l)
                self.emit_error(f"fn '{fname}': 'capacity param {l} inout' names {shown}, which is not a pointer to an integer; C reads the capacity through it and writes the produced length back (§16.2b.8)", clause)
                return c
            for k in 0..c.buffer_ptr.len() as i32:
                let taken = if c.buffer_ptr[k] == p or c.buffer_len[k] == p: p else if c.buffer_ptr[k] == l or c.buffer_len[k] == l: l else: -1
                if taken >= 0:
                    let shown = self.facade_param_display(fn_sym, sig, taken)
                    self.emit_error(f"fn '{fname}': {shown} is already part of a buffer pairing; a parameter is paired once (§16.2b.8)", clause)
                    return c
            for k in 0..c.fixed_params.len() as i32:
                if c.fixed_params[k] == p or c.fixed_params[k] == l:
                    let shown = self.facade_param_display(fn_sym, sig, c.fixed_params[k])
                    self.emit_error(f"fn '{fname}': {shown} is bound by 'fixed' and cannot also be a buffer or its length (§16.2b.8, §16.2b.11)", clause)
                    return c
            c.buffer_ptr.push(p)
            c.buffer_len.push(l)
            c.buffer_inout.push(inout)
            return c
        if kind == FACADE_CLAUSE_FIXED:
            // `param N fixed <literal>` (D64, §16.2b.11): the presented call
            // always passes the literal, which must be a value of the C
            // parameter's type — the raw operation stays available for any
            // other value.
            let pi = self.facade_resolve_param(self.ast.get_extra(ops), fn_sym, sig)
            if pi < 0:
                return c
            let lit = self.ast.get_extra(ops + 1)
            let ptype = self.resolve_alias(self.sig_param_type(sig, pi) as TypeId)
            let shown = self.facade_param_display(fn_sym, sig, pi)
            let lk = self.ast.kind(lit)
            let is_int = lk == NodeKind.NK_INT_LIT or (lk == NodeKind.NK_UNARY and self.ast.get_data0(lit) == UnaryOp.UOP_NEGATE)
            if lk == NodeKind.NK_NULL_LIT:
                if self.get_type_kind(ptype) != TypeKind.TY_PTR:
                    self.emit_error(f"fn '{fname}': 'param {pi} fixed null' binds {shown}, which is not a pointer (§16.2b.11)", clause)
                    return c
            else if lk == NodeKind.NK_BOOL_LIT:
                if self.resolve_alias(ptype) != self.ty_bool:
                    self.emit_error(f"fn '{fname}': 'param {pi} fixed' binds a boolean to {shown}, which is not a bool (§16.2b.11)", clause)
                    return c
            else if is_int:
                if self.get_type_kind(self.numeric_operand_type(ptype as i32)) != TypeKind.TY_INT:
                    self.emit_error(f"fn '{fname}': 'param {pi} fixed' binds an integer to {shown}, which is not an integer (§16.2b.11)", clause)
                    return c
                let negative = lk == NodeKind.NK_UNARY or self.ast.int_lit_value(lit) < 0
                if negative and self.is_unsigned_int_type(self.numeric_operand_type(ptype as i32)):
                    self.emit_error(f"fn '{fname}': 'param {pi} fixed' binds a negative literal to {shown}, an unsigned integer (§16.2b.11)", clause)
                    return c
            else:
                self.emit_error(f"fn '{fname}': a fixed argument is an integer literal, 'null', 'true' or 'false' (§16.2b.11)", clause)
                return c
            if self.facade_param_receives(fn_sym, pi).len() > 0:
                self.emit_error(f"fn '{fname}': 'param {pi} fixed' binds {shown}, which receives a modeled resource; a resource is passed by the value that owns it, never fixed (§16.2b.11)", clause)
                return c
            for k in 0..c.fixed_params.len() as i32:
                if c.fixed_params[k] == pi:
                    self.emit_error(f"fn '{fname}': {shown} is fixed twice (§16.2b.11)", clause)
                    return c
            for k in 0..c.buffer_ptr.len() as i32:
                if c.buffer_ptr[k] == pi or c.buffer_len[k] == pi:
                    self.emit_error(f"fn '{fname}': {shown} is part of a buffer pairing and cannot also be fixed (§16.2b.8, §16.2b.11)", clause)
                    return c
            c.fixed_params.push(pi)
            c.fixed_literals.push(lit)
            return c
        if kind == FACADE_CLAUSE_OK:
            // `ok CONST` on an fn item (D64, §16.2b.8): the status contract
            // under which a copied-back length is presented — on success
            // only. A resource's producer states `ok` on the resource
            // (§16.2b.4); an fn item's `ok` needs a length to present, which
            // verify_facade_buffers checks once every clause is collected.
            let const_sym = self.ast.get_extra(ops)
            let cn: str = self.pool_resolve(const_sym)
            if not self.facade_status_constant_ok(const_sym):
                self.emit_error(f"fn '{fname}': 'ok {cn}' names no imported integer constant; a status is compared with a compile-time constant the header declares (§16.2b.4)", clause)
                return c
            let ret = self.sig_return_type(sig)
            if ret == 0 or self.get_type_kind(self.numeric_operand_type(ret)) != TypeKind.TY_INT:
                let rt: str = if ret == 0: "nothing" else: self.type_name(ret)
                self.emit_error(f"fn '{fname}': 'ok {cn}' compares an integer status, but the function returns {rt} (§16.2b.4)", clause)
                return c
            if c.ok_const != 0:
                self.emit_error(f"fn '{fname}': 'ok' is stated twice (§16.2b.4)", clause)
                return c
            c.ok_const = const_sym
            return c
        let cname = facade_clause_name(kind)
        self.emit_error(f"fn '{fname}': clause '{cname}' applies to a resource, not an fn item (§16.2b)", clause)
        c

    // ── verification helpers ─────────────────────────────────────────────

    // A facade item's source, one space between words, so two blocks'
    // statements of the same item compare as facts and not as layout.
    fn facade_item_words(decl: i32, node: i32) -> str:
        let source = self.source_text_for_file_id(self.decl_source_file_id_for_index(decl))
        let start = self.ast.get_start(node)
        let end = self.ast.get_end(node)
        if start < 0 or end > source.len() as i32 or start >= end: return ""
        var out = ""
        var space = false
        for i in start..end:
            let c = source[i]
            if c == ' ' or c == '\t' or c == '\n' or c == '\r':
                space = out.len() > 0
            else:
                if space: out = out ++ " "
                space = false
                out = out ++ source.slice(i as i64, (i + 1) as i64)
        out

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
        if self.facade_same_type(p0 as i32, repr as i32) or self.facade_void_ptr_accepts(p0, repr):
            return true
        self.get_type_kind(p0) == TypeKind.TY_PTR and self.facade_same_type(self.get_type_d0(p0), repr as i32)

    // Ruling §61 "the destroyer accepts the representation" is C's own
    // conversion rule (Eric, 2026-09-22): a `void *` parameter (`*mut c_void`
    // or `*const c_void` after c_import) accepts every object pointer
    // representation, typedefs chased through their aliases — never a
    // function pointer (C does not convert one to `void *`) and never a
    // by-value representation. Otherwise the type is exact.
    // Two types the same through `type` aliases, pointees included: a
    // header's `DIR *` is `*mut __dirstream` where the facade says `*mut DIR`.
    fn facade_same_type(a: i32, b: i32) -> bool:
        let ra = self.resolve_alias(a as TypeId)
        let rb = self.resolve_alias(b as TypeId)
        if ra == rb:
            return true
        if self.get_type_kind(ra) != TypeKind.TY_PTR or self.get_type_kind(rb) != TypeKind.TY_PTR or self.get_type_d1(ra) != self.get_type_d1(rb):
            return false
        self.facade_same_type(self.get_type_d0(ra), self.get_type_d0(rb))

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

    // A `void *` parameter that receives no modeled resource: the untyped
    // userdata slot of a callback contract (ruling §24, §45).
    fn facade_param_is_userdata(fn_sym: i32, sig: i32, pi: i32) -> bool:
        self.facade_type_is_void_ptr(self.sig_param_type(sig, pi)) and self.facade_param_receives(fn_sym, pi).len() == 0

    fn facade_type_is_void_ptr(tid: i32) -> bool:
        let r = self.resolve_alias(tid as TypeId)
        self.get_type_kind(r) == TypeKind.TY_PTR and self.is_c_void_like_type(self.get_type_d0(r)) != 0

    // The one `void *` parameter of the callable parameter `pi`'s
    // signature — where its userdata arrives — or -1 when it has none or
    // several.
    fn facade_callable_userdata_slot(sig: i32, pi: i32) -> i32:
        if self.facade_callable_userdata_slot_count(sig, pi) != 1:
            return -1
        let callable = self.callable_type_resolved(self.sig_param_type(sig, pi))
        for k in 0..self.get_type_d1(callable):
            if self.facade_type_is_void_ptr(self.type_extra[self.get_type_d0(callable) + k]):
                return k
        -1

    fn facade_callable_userdata_slot_count(sig: i32, pi: i32) -> i32:
        let callable = self.callable_type_resolved(self.sig_param_type(sig, pi))
        var n = 0
        for k in 0..self.get_type_d1(callable):
            if self.facade_type_is_void_ptr(self.type_extra[self.get_type_d0(callable) + k]):
                n = n + 1
        n

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
    if kind == FACADE_CLAUSE_MOVABLE: return "movable"
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
    if kind == FACADE_CLAUSE_CALLBACK_USERDATA: return "callback … userdata"
    if kind == FACADE_CLAUSE_VALID_ON_FAILED: return "valid on failed"
    if kind == FACADE_CLAUSE_NULLABLE: return "nullable"
    if kind == FACADE_CLAUSE_BUFFER: return "buffer"
    if kind == FACADE_CLAUSE_FIXED: return "param … fixed"
    "callback consumes"

// ── stage 3: raw classification consults the facts ──────────────────────
//
// A facade covers a declaration's surface: a described fn lends every
// parameter by default (§16.2b.5 — the facade's assertion, recorded as
// review), and `consumes`/`retains` are stronger statements of the same
// coverage. A parameter that takes a resource's representation is not
// covered, nor the one a `destroys` item destroys: the resource is their
// safe surface, and its rendering calls the C operation inside `unsafe {}`.
// A covered surface is not raw (ci_function_requires_raw_abi), so the call
// needs no `unsafe`. Nothing is inferred from a name: an undescribed
// pointer return stays raw. Symbols are matched by text — the facade's
// symbols live in the user's pool, the c_import declaration's in its own.

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

    // A resource is the safe surface of its representation (§16.2b.5: "With
    // proves the resource is live, unmoved and undestroyed"): the rendered
    // constructor, Drop, destroyers and lend methods call the C operation in
    // an inner `unsafe {}` (compiler/FacadeRender.w). The raw C name is never
    // lifted by a resource clause — a safe `db_close(d.repr)` would destroy
    // through C and let Drop destroy again, which "is not expressible in safe
    // code" (§16.2b.5), and a safe raw producer call would hand back a
    // pointer nothing destroys. Raw access remains raw (ruling §14).
    fn facade_covers_return(fn_sym: i32) -> bool:
        let ci = self.facade_contract_for(fn_sym)
        ci >= 0 and (self.foreign_contracts[ci].returns_borrow_resource != 0 or self.foreign_contracts[ci].returns_static_tid != 0)

    // An fn item covers its parameters, except the one a `destroys` item
    // destroys and any that takes a resource's representation (or a pointer
    // to it): those are reached through the resource, never as a raw value.
    fn facade_covers_param(fn_sym: i32, pi: i32) -> bool:
        let ci = self.facade_contract_for(fn_sym)
        if ci < 0:
            return false
        if pi == 0 and self.foreign_contracts[ci].destroys != 0:
            return false
        // A buffer, its length and a fixed argument are reached through the
        // presented rendering alone (D64): the raw call, which takes a bare
        // pointer and a length nothing ties to it, stays raw.
        if self.facade_contract_pairs(ci, pi):
            return false
        not self.facade_param_takes_resource(fn_sym, pi)

    // Whether a parameter of type `p` receives the representation `repr`:
    // the same type, or — C's own qualification conversion, as the renderer
    // reads it (FacadeRender.w facade_render_repr_arg) — a `*const T`
    // parameter receiving a `*mut T` handle: a read-only lend of a pointer
    // resource (`counter_get(const Counter *)`).
    fn facade_param_matches_repr(p: i32, repr: i32) -> bool:
        if self.facade_same_type(p, repr):
            return true
        let rp = self.resolve_alias(p as TypeId)
        let rr = self.resolve_alias(repr as TypeId)
        if self.get_type_kind(rp) != TypeKind.TY_PTR or self.get_type_kind(rr) != TypeKind.TY_PTR:
            return false
        // A `const char *` input is a lent `str` (§16.3c), never the handle
        // of an owned-text resource (`CHeapStr wraps *mut i8`).
        if self.facade_type_is_c_string_ptr(repr):
            return false
        self.get_type_d1(rp) == 0 and self.get_type_d1(rr) != 0 and self.facade_same_type(self.get_type_d0(rp), self.get_type_d0(rr))

    // The fn item describing the C function named `cname`, or -1.
    fn facade_contract_named(cname: &str) -> i32:
        for i in 0..self.foreign_contracts.len() as i32:
            if self.safe_symbol_text(self.foreign_contracts[i].fn_sym) == cname:
                return i
        -1

    fn facade_param_takes_resource(fn_sym: i32, pi: i32) -> bool:
        let sig = self.get_sig(fn_sym)
        if sig < 0 or pi >= self.sig_get_param_count(sig):
            return false
        let p = self.resolve_alias(self.sig_param_type(sig, pi) as TypeId)
        let pointee = if self.get_type_kind(p) == TypeKind.TY_PTR: self.get_type_d0(p) else: 0
        for i in 0..self.facade_resources.len() as i32:
            let repr = self.resolve_alias(self.facade_resources[i].repr_tid as TypeId)
            if self.get_type_kind(repr) == TypeKind.TY_PTR or self.facade_resources[i].init != 0:
                if self.facade_param_matches_repr(p as i32, repr as i32) or (pointee != 0 and self.facade_same_type(pointee, repr as i32)):
                    return true
        false

    // Raw classification of an operation a resource calls, apart from the
    // parameter that receives the representation (`repr_param`, -1 for none)
    // and, for a producer, the return it produces: the rendered method or
    // constructor exposes every other parameter safely, so any of those that
    // is still raw is a shape the facade must describe (§16.2b.5).
    fn facade_op_raw_beyond(fn_sym: i32, repr_param: i32, skip_return: bool) -> bool:
        let sig = self.get_sig(fn_sym)
        if sig < 0:
            return self.ci_function_requires_raw_abi(fn_sym) != 0
        if self.sig_is_variadic(sig) != 0:
            return true
        if not skip_return and self.ci_type_requires_raw_contract(self.sig_return_type(sig)) != 0 and not self.facade_covers_return(fn_sym):
            return true
        let ci = self.facade_contract_for(fn_sym)
        for pi in 0..self.sig_get_param_count(sig):
            if pi == repr_param:
                continue
            // A parameter receiving another resource is presented as a
            // borrow of it (FacadeRender.w facade_render_params_but).
            if self.facade_param_presentable(fn_sym, pi):
                continue
            // A fixed argument is the rendering's literal, a paired buffer
            // its slice (D64): the rendered call supplies them.
            if ci >= 0 and self.facade_contract_pairs(ci, pi):
                continue
            let pty = self.sig_param_type(sig, pi)
            if self.ci_type_requires_raw_contract(pty) != 0 and self.ci_type_is_const_c_string_input(pty) == 0 and not self.facade_covers_param(fn_sym, pi):
                return true
        false

// ── stage 6: dependency (ruling §26-§30, spec §16.2b.6) ─────────────────
//
// A producer that receives modeled resources produces a resource dependent
// on them, unless the facade says otherwise: "unknown independence means
// dependency" (a wrong dependency only rejects programs, ruling §27).
// `independent` states the resource depends on nothing it was made from;
// `borrows param N` names exactly what one producer's result depends on
// (the producer stated before it, a `from` or the `init`). The renderer
// (compiler/FacadeRender.w facade_render_deps) makes the same
// classification from the AST and renders a dependent resource as an
// ephemeral struct holding a view of each parent, so the ordinary origin
// and ephemeral analysis (§21.1, §22) enforces it; nothing new is added to
// that analysis. What this section adds is the §61 verification, the net
// under the renderer, and the provenance every dependency diagnostic
// prints (§8, §57).

impl Sema:
    // The resources whose representation parameter `pi` of `fn_sym`
    // receives (FacadeRender.w facade_render_received): a pointer resource's
    // handle or an in-place resource's storage, by value or by address — the
    // line facade_param_takes_resource draws. A by-value token is not
    // recognized by its type (`int` is an `Fd` and every other integer).
    fn facade_param_receives(fn_sym: i32, pi: i32) -> Vec[i32]:
        let out: Vec[i32] = Vec.new()
        let sig = self.get_sig(fn_sym)
        if sig < 0 or pi < 0 or pi >= self.sig_get_param_count(sig):
            return out
        let p = self.resolve_alias(self.sig_param_type(sig, pi) as TypeId)
        let pointee = if self.get_type_kind(p) == TypeKind.TY_PTR: self.get_type_d0(p) else: 0
        for i in 0..self.facade_resources.len() as i32:
            let repr = self.resolve_alias(self.facade_resources[i].repr_tid as TypeId)
            if self.get_type_kind(repr) != TypeKind.TY_PTR and self.facade_resources[i].init == 0:
                continue
            if self.facade_param_matches_repr(p as i32, repr as i32) or (pointee != 0 and self.facade_same_type(pointee, repr as i32)):
                out.push(i)
        out

    // Whether a borrow `&R` of resource `ri` can hand parameter `pi` what C
    // declares (FacadeRender.w facade_render_received_arg): the
    // representation of a pointer resource or by-value token, the cell of a
    // pinned in-place resource, or a movable one through a const pointer.
    fn facade_received_presentable(ri: i32, fn_sym: i32, pi: i32) -> bool:
        let sig = self.get_sig(fn_sym)
        let p = self.resolve_alias(self.sig_param_type(sig, pi) as TypeId)
        let repr = self.resolve_alias(self.facade_resources[ri].repr_tid as TypeId)
        let pinned = self.facade_resources[ri].init != 0 and self.facade_resources[ri].movable == 0
        if self.facade_param_matches_repr(p as i32, repr as i32):
            return not pinned
        if self.get_type_kind(repr) == TypeKind.TY_PTR:
            return false
        if pinned:
            return true
        self.get_type_d1(p) == 0

    // Why a borrow cannot present that parameter, for the diagnostic.
    fn facade_received_unpresentable_reason(ri: i32, fn_sym: i32, pi: i32) -> str:
        let sig = self.get_sig(fn_sym)
        let p = self.resolve_alias(self.sig_param_type(sig, pi) as TypeId)
        let repr = self.resolve_alias(self.facade_resources[ri].repr_tid as TypeId)
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        if self.facade_same_type(p as i32, repr as i32):
            return f"'{rname}' is pinned in place, and a copy of its representation is not the resource (§16.2b.3)"
        if self.get_type_kind(repr) == TypeKind.TY_PTR:
            return f"it points at '{rname}''s handle, through which C could replace or release it"
        f"it is a mutable pointer to '{rname}''s movable representation, which a shared borrow cannot hand out"

    fn facade_param_presentable(fn_sym: i32, pi: i32) -> bool:
        let recv = self.facade_param_receives(fn_sym, pi)
        recv.len() == 1 and self.facade_received_presentable(recv[0], fn_sym, pi)

    // ── stage 8: assignment and presentation (ruling §14, §53-§55) ────────

    // The resources an operation may be a method of: those its first
    // parameter receives, narrowed to the one its fn item's `of` names when
    // it names one of them (§16.2b.3: "an operation is callable through a
    // resource only after the facade assigns it"). Several left means the
    // facade has not assigned it (verify_facade_assignments); an `of`
    // naming a resource the parameter does not receive is that error too.
    fn facade_method_host(fn_sym: i32) -> Vec[i32]:
        let recv = self.facade_param_receives(fn_sym, 0)
        let ci = self.facade_contract_for(fn_sym)
        if ci < 0 or self.foreign_contracts[ci].of_resource == 0 or recv.len() < 2:
            return recv
        let want: i32 = self.facade_resource_index.get(self.foreign_contracts[ci].of_resource).unwrap()
        for i in 0..recv.len() as i32:
            if recv[i] == want:
                let one: Vec[i32] = Vec.new()
                one.push(want)
                return one
        recv

    // Ruling §14: "When a foreign representation maps to multiple modeled
    // resources, an operation is callable through a modeled resource only
    // after resource assignment is known. An unassigned `z_stream *`
    // operation is rejected on both modeled resources, with a diagnostic
    // naming the candidates." An fn item whose first parameter receives a
    // representation several resources wrap states `of` naming one of them,
    // or it is not presented on any — and the raw call stays raw (§16.2b.5).
    // An item describing a resource's own clause operation (its producer,
    // initializer or destroyer) is assigned by that clause.
    mut fn verify_facade_assignments():
        for ci in 0..self.foreign_contracts.len() as i32:
            let fn_sym = self.foreign_contracts[ci].fn_sym
            let node = self.foreign_contracts[ci].node
            let fname: str = self.pool_resolve(fn_sym)
            let sig = self.get_sig(fn_sym)
            if sig < 0 or self.facade_fn_is_resource_op(fn_sym):
                continue
            let recv = self.facade_param_receives(fn_sym, 0)
            if recv.len() == 0:
                continue
            self.update_decl_source_context(self.foreign_contracts[ci].decl)
            let shown = self.facade_param_display(fn_sym, sig, 0)
            var names = ""
            var ofs = ""
            for k in 0..recv.len() as i32:
                let cn: str = self.pool_resolve(self.facade_resources[recv[k]].name)
                names = names ++ (if k > 0: ", " else: "") ++ f"'{cn}'"
                ofs = ofs ++ (if k > 0: " or " else: "") ++ f"'of {cn}'"
            let of_res = self.foreign_contracts[ci].of_resource
            if of_res != 0:
                let of_ri: i32 = self.facade_resource_index.get(of_res).unwrap()
                var received = false
                for k in 0..recv.len() as i32:
                    if recv[k] == of_ri: received = true
                if not received:
                    let on: str = self.pool_resolve(of_res)
                    self.emit_error(f"fn '{fname}': 'of {on}' assigns it to a resource {shown} does not receive; it receives {names} — state {ofs} (§16.2b.3)", node)
                continue
            if recv.len() > 1:
                self.emit_error_with_help(f"fn '{fname}': {shown} receives a representation several resources wrap ({names}); an operation is callable through a resource only after the facade assigns it, so '{fname}' is not presented on any of them (§16.2b.3)", node, f"state {ofs} on this fn item")

    // Whether a resource clause names `fn_sym` (`from`, `init`, `preinit`,
    // `drop`, `destroys`): the clause assigns it.
    fn facade_fn_is_resource_op(fn_sym: i32) -> bool:
        for ri in 0..self.facade_resources.len() as i32:
            let r = &self.facade_resources[ri]
            if self.facade_same_fn(r.init, fn_sym) or self.facade_same_fn(r.preinit, fn_sym) or self.facade_same_fn(r.drop, fn_sym):
                return true
            for k in 0..r.producers.len() as i32:
                if self.facade_same_fn(r.producers[k], fn_sym): return true
            for k in 0..r.destroyers.len() as i32:
                if self.facade_same_fn(r.destroyers[k], fn_sym): return true
        false

    // Ruling §55: "If automatic grouping is ambiguous, method sugar may
    // simply be omitted while the underlying modeled foreign operation
    // remains available." Two operations of one resource that shorten to
    // one name, or one that shortens to another's imported name, keep
    // their imported names (compiler/FacadeRender.w facade_render_present),
    // and this says so, naming the candidates and the `rename` that settles
    // it — a warning, since the program is valid and every operation is
    // reachable. Two explicit renames to one name, or a rename to another
    // operation's name, are an error: the facade said two things.
    mut fn verify_facade_presentation():
        for ri in 0..self.facade_resources.len() as i32:
            let rname: str = self.pool_resolve(self.facade_resources[ri].name)
            let rnode = self.facade_resources[ri].node
            let ops = facade_render_presented_ops(self.ast, self.pool, &self.decl_is_c_import, rnode)
            var noted: Vec[str] = Vec.new()
            for oi in 0..ops.len() as i32:
                let cname = ops[oi]
                let short = facade_render_shortened(self.ast, self.pool, rnode, cname)
                let clash = facade_render_presentation_clash(self.ast, self.pool, &self.decl_is_c_import, rnode, cname)
                if clash.len() == 0:
                    continue
                var seen = false
                for k in 0..noted.len() as i32:
                    if noted[k] == short: seen = true
                if seen:
                    continue
                noted.push(short.clone())
                let ci = self.facade_contract_named(cname)
                let node = if ci >= 0: self.foreign_contracts[ci].node else: rnode
                let decl = if ci >= 0: self.foreign_contracts[ci].decl else: self.facade_resources[ri].decl
                self.update_decl_source_context(decl)
                self.emit_warning(f"resource '{rname}': '{cname}' would be presented as '{short}', the name of {clash}; the compiler never picks, so '{cname}' keeps its imported name on '{rname}' — state 'rename' on an fn item describing it to settle the spelling (§16.2b.11)", node)
            // Two explicit spellings of one name: an error.
            let renamed = facade_render_renamed_ops(self.ast, self.pool, &self.decl_is_c_import, rnode)
            for a in 0..renamed.len() as i32:
                let ca = renamed[a]
                let na = facade_render_present(self.ast, self.pool, &self.decl_is_c_import, rnode, ca)
                for b in 0..ops.len() as i32:
                    let cb = ops[b]
                    if cb == ca:
                        continue
                    let nb = facade_render_present(self.ast, self.pool, &self.decl_is_c_import, rnode, cb)
                    if nb != na:
                        continue
                    let ci = self.facade_contract_named(ca)
                    let node = if ci >= 0: self.foreign_contracts[ci].node else: rnode
                    self.update_decl_source_context(if ci >= 0: self.foreign_contracts[ci].decl else: self.facade_resources[ri].decl)
                    self.emit_error(f"resource '{rname}': '{ca}' is renamed '{na}', and '{cb}' is presented as '{nb}' on '{rname}' too; two operations of one resource cannot share a name — rename one (§16.2b.11)", node)
                    break

    // ── D64: buffer pairing and fixed arguments (§16.2b.8, §16.2b.11) ────
    //
    // A pairing or a fixed argument is a fact about the presented call, so
    // an item carrying one is presented: a lend method of the resource its
    // first parameter receives, a free operation rendered under its
    // presented name (FacadeRender.w facade_render_free_ops), or — fixed
    // arguments only — a producer or callback item. The rendering computes
    // `capacity = dest.len`, calls C with its address, bounds-checks the
    // written value against that capacity and returns it as `usize`, on
    // success only; nothing here reinterprets a parameter. What is verified:
    // the shapes the rendering can express, the status contract an inout
    // length needs, the generated `<Fn>Error` name, and the refusal the
    // ruling states — a raw pointer parameter that no clause pairs is not a
    // buffer, and a lend or presentation clause on such a function renders
    // no call (the hole #1625 found: a bare `lend` on `compress`).
    mut fn verify_facade_buffers():
        for ci in 0..self.foreign_contracts.len() as i32:
            self.verify_facade_buffer_item(ci)

    fn facade_contract_presented(ci: i32) -> bool:
        let c = &self.foreign_contracts[ci]
        c.lend != 0 or c.rename != 0 or c.of_resource != 0 or c.buffer_ptr.len() > 0 or c.fixed_params.len() > 0 or c.ok_const != 0

    // Whether parameter `pi` is a buffer, a buffer's length, or fixed.
    fn facade_contract_pairs(ci: i32, pi: i32) -> bool:
        let c = &self.foreign_contracts[ci]
        for k in 0..c.buffer_ptr.len() as i32:
            if c.buffer_ptr[k] == pi or c.buffer_len[k] == pi: return true
        for k in 0..c.fixed_params.len() as i32:
            if c.fixed_params[k] == pi: return true
        false

    // Whether a callback, retention or consumption clause models `pi`.
    fn facade_contract_models_param(ci: i32, pi: i32) -> bool:
        let c = &self.foreign_contracts[ci]
        c.callback_userdata_cb.contains(pi) or c.callback_userdata_of.contains(pi) or c.retains.contains(pi) or c.consumes.contains(pi) or c.consumes_destroyed_by.contains(pi) or c.callback_consumes.contains(pi)

    // The index of the `capacity … inout` pairing, or -1.
    fn facade_contract_inout(ci: i32) -> i32:
        let c = &self.foreign_contracts[ci]
        for k in 0..c.buffer_ptr.len() as i32:
            if c.buffer_inout[k] != 0: return k
        -1

    // The out-parameter slot a resource's producer `fn_sym` writes, or -1.
    fn facade_fn_out_param(fn_sym: i32) -> i32:
        for ri in 0..self.facade_resources.len() as i32:
            let r = &self.facade_resources[ri]
            for k in 0..r.producers.len() as i32:
                if self.facade_same_fn(r.producers[k], fn_sym): return r.out_params[k]
        -1

    fn facade_fn_is_destroyer_or_init(fn_sym: i32) -> bool:
        for ri in 0..self.facade_resources.len() as i32:
            let r = &self.facade_resources[ri]
            if self.facade_same_fn(r.init, fn_sym) or self.facade_same_fn(r.preinit, fn_sym) or self.facade_same_fn(r.drop, fn_sym):
                return true
            for k in 0..r.destroyers.len() as i32:
                if self.facade_same_fn(r.destroyers[k], fn_sym): return true
        false

    // The name a free operation is presented under: its `rename`, or the C
    // name. Under the C name the rendering is `__with_facade_<name>`
    // (facade_render_bridge_name) and a call to the C name is redirected to
    // it where it is visible (facade_bridge_redirect); the raw declaration
    // stays what C declared, for the bridge's own call and for every module
    // that imports the header without the facade.
    fn facade_presented_free_name(ci: i32) -> str:
        let c = &self.foreign_contracts[ci]
        let name: str = self.pool_resolve(if c.rename != 0: c.rename else: c.fn_sym)
        name

    mut fn facade_bridge_redirect(fn_sym: i32) -> i32:
        if self.facade_bridge_of.len() == 0:
            return fn_sym
        let name: str = self.pool_resolve(fn_sym)
        if not self.facade_bridge_of.contains(name):
            return fn_sym
        let bname: str = self.facade_bridge_of.get(name).unwrap()
        let bsym = self.pool_lookup_symbol(bname)
        // The bridge's own body calls the C name: the raw operation.
        if bsym == 0 or bsym == self.current_fn_symbol or self.symbol_visible_from_current(bsym) == 0 or self.get_visible_sig(bsym) < 0:
            return fn_sym
        self.facade_bridge_syms.insert(bsym, 1)
        bsym

    fn facade_type_is_byte(tid: i32) -> bool:
        let r = self.resolve_alias(tid as TypeId)
        r == self.ty_u8 or r == self.ty_i8 or self.is_c_void_like_type(r as i32) != 0

    mut fn verify_facade_buffer_item(ci: i32):
        self.update_decl_source_context(self.foreign_contracts[ci].decl)
        let fn_sym = self.foreign_contracts[ci].fn_sym
        let node = self.foreign_contracts[ci].node
        let fname: str = self.pool_resolve(fn_sym)
        let sig = self.get_sig(fn_sym)
        if sig < 0:
            return
        let has_pairs = self.foreign_contracts[ci].buffer_ptr.len() > 0
        let has_fixed = self.foreign_contracts[ci].fixed_params.len() > 0
        let inout = self.facade_contract_inout(ci)
        let ok_const = self.foreign_contracts[ci].ok_const
        let resource_op = self.facade_fn_is_resource_op(fn_sym)
        let contract_item = self.foreign_contracts[ci].destroys != 0 or self.foreign_contracts[ci].consumes.len() > 0 or self.foreign_contracts[ci].retains.len() > 0 or self.foreign_contracts[ci].callback_userdata_cb.len() > 0 or self.foreign_contracts[ci].callback_consumes.len() > 0 or self.foreign_contracts[ci].callback_thread_any != 0
        if has_pairs and (resource_op or contract_item):
            let what = if resource_op: "a resource's own operation (its producer, initializer, drop or destroyer)" else: "a callback, retention or consumption contract"
            self.emit_error(f"fn '{fname}': a buffer pairing describes a lend or a free operation, and '{fname}' is {what}; a slice in that rendering is not modeled (§16.2b.8)", node)
            return
        if has_fixed and self.facade_fn_is_destroyer_or_init(fn_sym):
            self.emit_error(f"fn '{fname}': a destroyer, initializer or drop takes only what the resource passes it; a fixed argument on '{fname}' is not modeled (§16.2b.11)", node)
            return
        let ret = self.sig_return_type(sig)
        let void_ret = ret == 0 or self.get_type_kind(self.resolve_alias(ret as TypeId)) == TypeKind.TY_VOID
        if inout >= 0 and (self.foreign_contracts[ci].returns_borrow_resource != 0 or self.foreign_contracts[ci].returns_static_tid != 0):
            self.emit_error(f"fn '{fname}': 'capacity … inout' presents the length C writes back as the operation's result, and a 'returns' clause presents the return; one operation has one result (§16.2b.8)", node)
            return
        if inout >= 0 and not void_ret and ok_const == 0:
            let rt: str = self.type_name(ret)
            self.emit_error_with_help(f"fn '{fname}': 'capacity … inout' presents the length C writes back only on success (§16.2b.8), and '{fname}' returns {rt} with no status contract", node, "state the success status: 'ok <CONST>' (§16.2b.4)")
            return
        if ok_const != 0 and inout < 0:
            let cn: str = self.pool_resolve(ok_const)
            self.emit_error(f"fn '{fname}': 'ok {cn}' states the status contract a copied-back length is presented under, and '{fname}' pairs no 'capacity … inout' buffer, so there is no value to present on success; a producer's status is stated on its resource (§16.2b.4, §16.2b.8)", node)
            return
        // A resource's own operation renders as its constructor or destroyer,
        // a callback contract as its callback method (stage 9): their
        // parameters are those renderings' business, and a fixed argument on
        // one is the literal facade_render_bridge passes.
        if resource_op or contract_item or not self.facade_contract_presented(ci):
            return
        // The refusal: every raw pointer parameter of a presented operation
        // is reached through some clause — the receiver through its
        // resource, a C string through the text rule, an out slot through
        // the producer, a callback through its contract, a buffer through
        // its pairing, a fixed argument through its literal.
        let out_param = self.facade_fn_out_param(fn_sym)
        for pi in 0..self.sig_get_param_count(sig):
            if pi == out_param or self.facade_contract_pairs(ci, pi) or self.facade_contract_models_param(ci, pi):
                continue
            let pty = self.sig_param_type(sig, pi)
            if self.ci_type_requires_raw_contract(pty) == 0 or self.ci_type_is_const_c_string_input(pty) != 0:
                continue
            // A parameter that receives a modeled resource is reached through
            // the resource — the receiver, or a borrow `&P` (a shape a borrow
            // cannot present is verify_facade_dependency_shape's error).
            if self.facade_param_receives(fn_sym, pi).len() > 0:
                continue
            // A pointer to bytes, scalars, `void` or pointers is
            // verify_facade_buffer_params's (12b): it names the buffer. A
            // handle no resource wraps is refused here.
            let pty_r = self.resolve_alias(pty as TypeId)
            if self.get_type_kind(pty_r) == TypeKind.TY_PTR:
                let pk = self.get_type_kind(self.resolve_alias(self.get_type_d0(pty_r) as TypeId))
                if pk != TypeKind.TY_STRUCT and pk != TypeKind.TY_ENUM and pk != TypeKind.TY_GENERIC_INST:
                    continue
            let shown = self.facade_param_display(fn_sym, sig, pi)
            let pname = self.facade_param_c_name(fn_sym, pi)
            self.emit_error_with_help(f"fn '{fname}': {shown} is a raw pointer that no clause pairs, so it is not a buffer; a presented operation renders no call without a bounds contract (§16.2b.8)", node, f"pair it with 'buffer param {pname} len param <L>' or 'buffer param {pname} capacity param <L> inout', bind it with 'param {pname} fixed <literal>', or leave the operation raw")
            return
        if self.diags.has_errors():
            return
        let hosted = self.facade_method_host(fn_sym).len() == 1
        let presented_name = if hosted: self.facade_presented(self.facade_method_host(fn_sym)[0], fname) else: self.facade_presented_free_name(ci)
        let facade_name: str = self.pool_resolve(self.foreign_contracts[ci].facade)
        let rendered_file = "<facade " ++ facade_name ++ ">"
        if ok_const != 0:
            let err = facade_render_fn_error_name(presented_name)
            let other = self.facade_generated_name_clash(err, rendered_file, -1)
            if other.len() > 0:
                self.emit_error(f"fn '{fname}' renders '{err}', the error type of its 'ok' projection, and {other}; the compiler never picks between two types of one name — rename one (§16.2b.4)", node)
                return
        if hosted or not (has_pairs or has_fixed):
            return
        // A free operation passed every check: its rendering must exist, or
        // the presented call would silently be the raw one.
        let rendered_name = if self.foreign_contracts[ci].rename != 0: presented_name.clone() else: facade_render_bridge_name(fname)
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) == NodeKind.NK_FN_DECL and self.safe_symbol_text(self.ast.get_data0(decl)) == rendered_name and self.facade_decl_file_name(di) == rendered_file:
                if self.foreign_contracts[ci].rename == 0:
                    self.facade_bridge_of.insert(fname, rendered_name)
                return
        self.emit_error(f"fn '{fname}': its buffer pairing or fixed argument passed every facade check but no '{rendered_name}' was rendered — a compiler defect (§16.2b.8)", node)

    // A resource's producers, as owners of dependencies: each `from` by its
    // index, and the `init` as FACADE_DEP_INIT.
    fn facade_owners(ri: i32) -> Vec[i32]:
        let out: Vec[i32] = Vec.new()
        for pi in 0..self.facade_resources[ri].producers.len() as i32:
            out.push(pi)
        if self.facade_resources[ri].init != 0:
            out.push(FACADE_DEP_INIT)
        out

    fn facade_owner_fn(ri: i32, owner: i32) -> i32: if owner == FACADE_DEP_INIT: self.facade_resources[ri].init else: self.facade_resources[ri].producers[owner]

    // The parameter an owner never receives a parent through: the out slot,
    // or the storage `init` initializes.
    fn facade_owner_skip(ri: i32, owner: i32) -> i32: if owner == FACADE_DEP_INIT: 0 else: self.facade_resources[ri].out_params[owner]

    // The parameters producer `owner`'s result depends on (spec §16.2b.6):
    // none under `independent`, the ones its `borrows` clauses name, and
    // otherwise every parameter receiving a resource.
    fn facade_producer_parents(ri: i32, owner: i32) -> Vec[i32]:
        let out: Vec[i32] = Vec.new()
        if self.facade_resources[ri].independent != 0:
            return out
        var stated = false
        for bi in 0..self.facade_resources[ri].borrows.len() as i32:
            if self.facade_resources[ri].borrows_owner[bi] == owner:
                stated = true
                out.push(self.facade_resources[ri].borrows[bi])
        if stated:
            return out
        let f = self.facade_owner_fn(ri, owner)
        let sig = self.get_sig(f)
        if sig < 0:
            return out
        let skip = self.facade_owner_skip(ri, owner)
        for pi in 0..self.sig_get_param_count(sig):
            if pi != skip and self.facade_param_receives(f, pi).len() > 0:
                out.push(pi)
        out

    fn facade_resource_dependent(ri: i32) -> bool:
        let owners = self.facade_owners(ri)
        for oi in 0..owners.len() as i32:
            if self.facade_owner_fn(ri, owners[oi]) != 0 and self.facade_producer_parents(ri, owners[oi]).len() > 0:
                return true
        false

    // The clause that states producer `owner`'s dependency on parameter
    // `pi`, or 0 for the conservative default.
    fn facade_borrows_clause(ri: i32, owner: i32, pi: i32) -> i32:
        for bi in 0..self.facade_resources[ri].borrows.len() as i32:
            if self.facade_resources[ri].borrows_owner[bi] == owner and self.facade_resources[ri].borrows[bi] == pi:
                return self.facade_resources[ri].borrows_nodes[bi]
        0

    // Ruling §61 for dependency: the facts are consistent, every `borrows`
    // names a parameter receiving a resource, and every resource a producer
    // receives is one known resource a borrow can present — the constructor
    // takes `&P` for it (§16.2b.3: an unassigned representation is rejected,
    // naming the candidates).
    mut fn verify_facade_dependency(ri: i32) -> bool:
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let node = self.facade_resources[ri].node
        if self.facade_resources[ri].independent != 0 and self.facade_resources[ri].borrows.len() > 0:
            self.emit_error_with_help(f"resource '{rname}' states both 'independent' and 'borrows'; 'independent' says it depends on nothing its producers receive, 'borrows' names what it depends on (§16.2b.6)", self.facade_resources[ri].independent_node, "keep 'borrows' if the resource depends on the parameters it names, 'independent' if the C API guarantees it depends on nothing it was made from")
            return false
        for bi in 0..self.facade_resources[ri].borrows.len() as i32:
            let owner = self.facade_resources[ri].borrows_owner[bi]
            let f = self.facade_owner_fn(ri, owner)
            let pi = self.facade_resources[ri].borrows[bi]
            if self.facade_param_receives(f, pi).len() == 0:
                let sig = self.get_sig(f)
                let shown = self.facade_param_display(f, sig, pi)
                let pn: str = self.pool_resolve(f)
                self.emit_error(f"resource '{rname}': 'borrows' names {shown} of '{pn}', which receives no modeled resource; a resource depends on the parent resources its producer receives, and With does not invent an origin for anything else (§16.2b.6, §16.2b.7)", self.facade_resources[ri].borrows_nodes[bi])
                return false
        let owners = self.facade_owners(ri)
        for oi in 0..owners.len() as i32:
            let owner = owners[oi]
            let f = self.facade_owner_fn(ri, owner)
            let sig = self.get_sig(f)
            if f == 0 or sig < 0:
                continue
            let pn: str = self.pool_resolve(f)
            let skip = self.facade_owner_skip(ri, owner)
            for pi in 0..self.sig_get_param_count(sig):
                if pi == skip:
                    continue
                let recv = self.facade_param_receives(f, pi)
                if recv.len() == 0:
                    continue
                let shown = self.facade_param_display(f, sig, pi)
                if recv.len() > 1:
                    var names = ""
                    for k in 0..recv.len() as i32:
                        let cn: str = self.pool_resolve(self.facade_resources[recv[k]].name)
                        names = names ++ (if k > 0: ", " else: "") ++ f"'{cn}'"
                    self.emit_error(f"resource '{rname}': producer '{pn}' receives {shown}, a representation several resources wrap ({names}); the constructor cannot tell which resource it borrows (§16.2b.3)", node)
                    return false
                if not self.facade_received_presentable(recv[0], f, pi):
                    let why = self.facade_received_unpresentable_reason(recv[0], f, pi)
                    let cn: str = self.pool_resolve(self.facade_resources[recv[0]].name)
                    self.emit_error(f"resource '{rname}': producer '{pn}' receives {shown}, which a borrow of '{cn}' cannot hand to C: {why} (§16.2b.6)", node)
                    return false
        let preinit_fn = self.facade_resources[ri].preinit
        if preinit_fn != 0:
            let psig = self.get_sig(preinit_fn)
            for pi in 0..self.sig_get_param_count(psig):
                if self.facade_param_receives(preinit_fn, pi).len() > 0:
                    let shown = self.facade_param_display(preinit_fn, psig, pi)
                    let pn: str = self.pool_resolve(preinit_fn)
                    self.emit_error(f"resource '{rname}': 'preinit {pn}' receives {shown}; preinit only constructs storage, and a resource an in-place resource depends on is received by its 'init' (§16.2b.4, §16.2b.6)", node)
                    return false
        true

    // The plan's one gap: "the producer call publishes the parent origin onto
    // the binding". A constructor's call site ties its result to the
    // arguments through the constructor's effect summary (a parameter that
    // escapes as a view, and its origin — §21.1 Rule 6), and that summary is
    // inferred from the body when the body is checked. The rendered
    // constructors are spliced after every user declaration, so every call
    // is checked before the body it calls: the summary was empty and the
    // dependency unenforced. The facade states the dependency, so the
    // signature carries it as a declared summary, the way an interface
    // declaration's origin is declared (D39, apply_interface_declared_effects):
    // each parent parameter escapes as a view of itself. The body, checked
    // later, infers the same summary from `R { parent: p, … }`.
    mut fn apply_facade_dependency_effects(ri: i32):
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let owners = self.facade_owners(ri)
        for oi in 0..owners.len() as i32:
            let owner = owners[oi]
            let f = self.facade_owner_fn(ri, owner)
            let parents = self.facade_producer_parents(ri, owner)
            if f == 0 or parents.len() == 0:
                continue
            // The constructor's parameters are C's, less the out slot; an
            // in-place constructor's are preinit's, then init's after `self`.
            // The receiver method on a parent (`db.prepare(sql)`) has the
            // same indices: its `self` is C's first parameter.
            var shift = 0
            if owner == FACADE_DEP_INIT and self.facade_resources[ri].preinit != 0:
                shift = self.sig_get_param_count(self.get_sig(self.facade_resources[ri].preinit))
            let slot = self.facade_owner_skip(ri, owner)
            let sigs = self.facade_producer_sigs(ri, owner, f)
            for si in 0..sigs.len() as i32:
                let sig = sigs[si]
                for k in 0..parents.len() as i32:
                    let c_pi: i32 = parents[k]
                    var pi = c_pi
                    if owner == FACADE_DEP_INIT:
                        pi = shift + c_pi - 1
                    else if slot >= 0 and c_pi > slot:
                        pi = c_pi - 1
                    let eff = self.sig_param_effect(sig, pi) | EFF_ESCAPE_VIEW
                    self.set_sig_param_effect(sig, pi, eff)
                    self.set_sig_param_direct_effect(sig, pi, eff)
                    self.set_sig_param_view_origin(sig, pi, self.sig_param_view_origin(sig, pi) | sema_param_origin_bit(pi))

    // The signature of a rendered constructor `R.p`, or -1.
    fn facade_constructor_sig(want: &str) -> i32:
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) == NodeKind.NK_FN_DECL and self.safe_symbol_text(self.ast.get_data0(decl)) == want:
                return self.get_sig(self.fn_decl_semantic_symbol(decl, self.ast.get_data0(decl)))
        -1

    // The net under the renderer: a dependent resource was rendered as an
    // ephemeral struct, an independent one as an ordinary one. A
    // disagreement means the renderer and these facts classified the
    // producers differently, and the analysis would enforce the wrong thing.
    mut fn verify_facade_dependency_shape(ri: i32):
        let name = self.facade_resources[ri].name
        let dependent = self.facade_resource_dependent(ri)
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_TYPE_DECL or self.ast.get_data0(decl) != name:
                continue
            let packed = self.ast.get_data2(decl)
            if type_decl_sub_kind(packed) != TypeDeclKind.Struct as i32:
                continue
            let rendered_ephemeral = type_decl_is_ephemeral(packed) != 0
            if rendered_ephemeral != dependent:
                let rname: str = self.pool_resolve(name)
                let says = if dependent: "depends on what its producers receive" else: "depends on nothing its producers receive"
                self.emit_error(f"resource '{rname}' {says}, but its rendered type disagrees; the renderer and the dependency facts classified its producers differently — a compiler defect (§16.2b.6)", self.facade_resources[ri].node)
            return

    // The dependent resource a type carries — itself, or inside an
    // `Option`, `Result`, tuple, collection or reference — or -1.
    fn facade_dependent_resource_in(tid: i32, depth: i32) -> i32:
        if tid <= 0 or depth > 6 or self.facade_resources.len() == 0:
            return -1
        let r = self.resolve_alias(tid as TypeId)
        let kind = self.get_type_kind(r)
        let name = self.get_type_name(r)
        if name != 0 and self.facade_resource_index.contains(name):
            let ri: i32 = self.facade_resource_index.get(name).unwrap()
            if self.facade_resource_dependent(ri):
                return ri
        if kind == TypeKind.TY_GENERIC_INST:
            for ai in 0..self.get_generic_inst_arg_count(r as i32):
                let found = self.facade_dependent_resource_in(self.get_generic_inst_arg(r as i32, ai), depth + 1)
                if found >= 0:
                    return found
        else if kind == TypeKind.TY_TUPLE:
            let te_start = self.get_type_d0(r)
            for ei in 0..self.get_type_d1(r):
                let found = self.facade_dependent_resource_in(self.type_extra[(te_start + ei)], depth + 1)
                if found >= 0:
                    return found
        else if kind == TypeKind.TY_REF or kind == TypeKind.TY_ARRAY:
            return self.facade_dependent_resource_in(self.get_type_d0(r), depth + 1)
        -1

    // A facade `param` reference as written: `param 0`, `param db`,
    // `param type *mut sqlite3`.
    fn facade_param_ref_text(ref_node: i32, f: i32, pi: i32) -> str:
        let rk = self.ast.get_data0(ref_node)
        if rk == FACADE_PARAM_REF_INDEX or rk == FACADE_PARAM_REF_NAME:
            let t: str = self.pool_resolve(self.ast.get_data1(ref_node))
            return "param " ++ t
        "param type " ++ self.type_name(self.sig_param_type(self.get_sig(f), pi))

    // What a dependent resource depends on and why (§8, §57): for each
    // parent, the producer receiving it with the resolved C parameter, and
    // the evidence — the facade clause stating it, or the conservative
    // default.
    fn facade_dependency_notes(ri: i32) -> Vec[str]:
        let out: Vec[str] = Vec.new()
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let fname: str = self.pool_resolve(self.facade_resources[ri].facade)
        let owners = self.facade_owners(ri)
        for oi in 0..owners.len() as i32:
            let owner = owners[oi]
            let f = self.facade_owner_fn(ri, owner)
            let sig = self.get_sig(f)
            if f == 0 or sig < 0:
                continue
            let pn: str = self.pool_resolve(f)
            let parents = self.facade_producer_parents(ri, owner)
            for k in 0..parents.len() as i32:
                let pi = parents[k]
                let recv = self.facade_param_receives(f, pi)
                if recv.len() == 0:
                    continue
                let parent: str = self.pool_resolve(self.facade_resources[recv[0]].name)
                let shown = self.facade_param_display(f, sig, pi)
                let clause = self.facade_borrows_clause(ri, owner, pi)
                let evidence = if clause != 0: "stated by 'borrows " ++ self.facade_param_ref_text(self.ast.get_extra(self.ast.get_data1(clause)), f, pi) ++ f"' in facade {fname}" else: f"conservative default of facade {fname}: unknown independence means dependency"
                out.push(f"dependency: '{rname}' depends on '{parent}', which producer '{pn}' receives as {shown} — {evidence} (§16.2b.6)")
        out

    // The fix a conservative dependency admits (§8: "declare this producer
    // independent if the C API guarantees independence"), or "" when every
    // dependency is stated by `borrows`.
    fn facade_dependency_help(ri: i32) -> str:
        let owners = self.facade_owners(ri)
        for oi in 0..owners.len() as i32:
            let parents = self.facade_producer_parents(ri, owners[oi])
            for k in 0..parents.len() as i32:
                if self.facade_borrows_clause(ri, owners[oi], parents[k]) == 0:
                    let rname: str = self.pool_resolve(self.facade_resources[ri].name)
                    let fname: str = self.pool_resolve(self.facade_resources[ri].facade)
                    return f"if the C API guarantees '{rname}' does not depend on the resources its producers receive, state 'independent' on resource '{rname}' in facade {fname}; if it depends on only some of them, name those with 'borrows param N'"
        ""

    // Ruling §30 (spec §16.2b.6): an ephemeral value stored where it cannot
    // live is the general §5 error — unless its ephemerality comes from a
    // facade resource, which is the self-referential layout the ruling names
    // (`type App { db: Database, stmt: Statement }`). That one is reported
    // with the dependency's provenance and a fix, which needs the facade
    // facts, and declarations are checked before the facades are collected:
    // it waits for report_facade_layout_errors. `container` is the declaring
    // node (a type or a global), for the fix.
    mut fn emit_ephemeral_storage_error(msg: &str, node: i32, tid: i32, container: i32):
        if self.suppress_errors != 0:
            return
        if tid <= 0 or not self.type_mentions_facade_rendered(tid, 0):
            self.emit_error(msg, node)
            return
        for i in 0..self.facade_layout_nodes.len() as i32:
            if self.facade_layout_nodes[i] == node:
                return
        if self.facade_resources.len() > 0:
            // The facts exist already (a local declaration inside a body).
            self.emit_facade_layout_error(msg, node, tid, container)
            return
        self.facade_layout_nodes.push(node)
        self.facade_layout_tids.push(tid)
        self.facade_layout_containers.push(container)
        self.facade_layout_files.push(self.local_file_id)
        self.facade_layout_msgs.push(with_str_clone_ref(msg))

    // Whether a type is, or carries, one a facade block rendered (read from
    // the declarations' files, since the facade facts may not exist yet).
    fn type_mentions_facade_rendered(tid: i32, depth: i32) -> bool:
        if tid <= 0 or depth > 6:
            return false
        let r = self.resolve_alias(tid as TypeId)
        let kind = self.get_type_kind(r)
        let name = self.get_type_name(r)
        if name != 0:
            for di in 0..self.ast.decl_count():
                let decl = self.ast.get_decl(di)
                if self.ast.kind(decl) == NodeKind.NK_TYPE_DECL and self.ast.get_data0(decl) == name and self.facade_decl_file_name(di).starts_with("<facade "):
                    return true
        if kind == TypeKind.TY_GENERIC_INST:
            for ai in 0..self.get_generic_inst_arg_count(r as i32):
                if self.type_mentions_facade_rendered(self.get_generic_inst_arg(r as i32, ai), depth + 1):
                    return true
        else if kind == TypeKind.TY_TUPLE:
            let te_start = self.get_type_d0(r)
            for ei in 0..self.get_type_d1(r):
                if self.type_mentions_facade_rendered(self.type_extra[(te_start + ei)], depth + 1):
                    return true
        else if kind == TypeKind.TY_REF or kind == TypeKind.TY_ARRAY:
            return self.type_mentions_facade_rendered(self.get_type_d0(r), depth + 1)
        false

    mut fn report_facade_layout_errors():
        let saved_file = self.local_file_id
        for i in 0..self.facade_layout_nodes.len() as i32:
            self.local_file_id = self.facade_layout_files[i]
            self.emit_facade_layout_error(self.facade_layout_msgs[i], self.facade_layout_nodes[i], self.facade_layout_tids[i], self.facade_layout_containers[i])
        self.local_file_id = saved_file
        self.facade_layout_nodes.clear()

    // The §30 error: what the stored resource depends on and why, and — for
    // a struct — the fix that compiles: hold each parent by borrow in an
    // ephemeral struct, so the struct lives no longer than the parents.
    mut fn emit_facade_layout_error(msg: &str, node: i32, tid: i32, container: i32):
        let ri = self.facade_dependent_resource_in(tid, 0)
        if ri < 0:
            // Not a dependent resource after all (a facade that failed its
            // checks renders nothing it could depend on): the general error.
            self.emit_error(msg, node)
            return
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let parents = self.facade_parent_names(ri)
        var cname = ""
        var fix = ""
        var holds_parent = false
        if container != 0 and self.ast.kind(container) == NodeKind.NK_TYPE_DECL and type_decl_sub_kind(self.ast.get_data2(container)) == TypeDeclKind.Struct as i32:
            cname = with_str_clone_ref(self.pool_resolve(self.ast.get_data0(container)))
            let extra_start = self.ast.get_data1(container)
            let field_count = self.ast.get_extra(extra_start)
            var fields = ""
            for fi in 0..field_count:
                let base = extra_start + 1 + fi * 3
                let fname: str = self.pool_resolve(self.ast.get_extra(base))
                let ftid = self.resolve_type_expr(self.ast.get_extra(base + 1)) as i32
                var shown = self.type_name(ftid)
                let fname_sym = self.get_type_name(self.resolve_alias(ftid as TypeId))
                if fname_sym != 0 and self.facade_resource_index.contains(fname_sym):
                    let pri: i32 = self.facade_resource_index.get(fname_sym).unwrap()
                    if self.facade_is_parent_of(ri, pri):
                        shown = "&" ++ shown
                        holds_parent = true
                fields = fields ++ (if fi > 0: ", " else: "") ++ fname ++ ": " ++ shown
            fix = f"type {cname} = ephemeral {{ {fields} }}"
        let what = if cname.len() > 0: f"'{cname}' stores" else: "this stores"
        let layout = if holds_parent: f"; a type holding a {parents} and a '{rname}' that depends on it is a self-referential layout" else: ""
        var diag = Diagnostic.err(f"{what} a '{rname}', which depends on its {parents} and cannot be stored in a non-ephemeral type{layout} (§16.2b.6)", Span { file: self.local_file_id, start: self.ast.get_start(node), end: self.ast.get_end(node) })
        let notes = self.facade_dependency_notes(ri)
        for i in 0..notes.len() as i32:
            diag.add_note(notes[i])
        if fix.len() > 0:
            let how = if holds_parent: "borrow the parent instead of owning it, so " ++ cname ++ " lives no longer than it" else: "make " ++ cname ++ " ephemeral, so it lives no longer than the parent"
            diag.add_help(f"{how}: `{fix}`; or keep the '{rname}' in a local declared after its parent")
        else:
            diag.add_help(f"keep the '{rname}' in a local declared after its parent, or in an ephemeral value that borrows the parent")
        let independence = self.facade_dependency_help(ri)
        if independence.len() > 0:
            diag.add_help(independence)
        self.diags.emit(move diag)

    // `'Database'`, or `'Database' and 'Cache'`: the resources `ri` depends on.
    fn facade_parent_names(ri: i32) -> str:
        var out = ""
        let seen: Vec[i32] = Vec.new()
        let owners = self.facade_owners(ri)
        for oi in 0..owners.len() as i32:
            let f = self.facade_owner_fn(ri, owners[oi])
            let parents = self.facade_producer_parents(ri, owners[oi])
            for k in 0..parents.len() as i32:
                let recv = self.facade_param_receives(f, parents[k])
                if recv.len() == 0:
                    continue
                var dup = false
                for s in 0..seen.len() as i32:
                    if seen[s] == recv[0]:
                        dup = true
                if dup:
                    continue
                seen.push(recv[0])
                let pn: str = self.pool_resolve(self.facade_resources[recv[0]].name)
                out = out ++ (if out.len() > 0: " and " else: "") ++ "'" ++ pn ++ "'"
        out

    fn facade_is_parent_of(ri: i32, parent: i32) -> bool:
        let owners = self.facade_owners(ri)
        for oi in 0..owners.len() as i32:
            let f = self.facade_owner_fn(ri, owners[oi])
            let parents = self.facade_producer_parents(ri, owners[oi])
            for k in 0..parents.len() as i32:
                let recv = self.facade_param_receives(f, parents[k])
                if recv.len() > 0 and recv[0] == parent:
                    return true
        false

    // A diagnostic about a value of type `tid` gains the dependency facts of
    // the facade resource it carries, if any.
    fn with_facade_dependency_notes(diag0: Diagnostic, tid: i32) -> Diagnostic:
        var diag = diag0
        let ci = self.facade_borrowed_contract_in(tid, 0)
        if ci >= 0:
            diag.add_note(self.facade_borrowed_note(ci))
            return diag
        let ri = self.facade_dependent_resource_in(tid, 0)
        if ri < 0:
            return diag
        let notes = self.facade_dependency_notes(ri)
        for i in 0..notes.len() as i32:
            diag.add_note(notes[i])
        let help = self.facade_dependency_help(ri)
        if help.len() > 0:
            diag.add_help(help)
        diag

    // ── borrowed returns (ruling §26, spec §16.2b.6) ─────────────────────
    //
    // `returns borrow R from param N`: "The result: has no Drop; cannot
    // outlive the named origin; cannot independently be consumed or
    // destroyed. Nullable borrowed returns become Option of the borrowed
    // modeled value." The renderer (FacadeRender.w facade_render_borrowed_type)
    // makes that value the distinct type `Borrowed<R>` — ephemeral, holding a
    // view of the origin resource, carrying R's lend methods and none of its
    // destroyers — and the operation a method of the resource its param 0
    // receives, `Option[Borrowed<R>]`. Verified here (§61): the origin
    // parameter receives exactly one resource, the operation's first
    // parameter does (so it has a resource to be a method of), and every
    // item borrowing R names one origin resource, since `Borrowed<R>` holds
    // one view type. The net checks the type and the method were rendered,
    // and the method's signature gets the origin as a declared summary, as
    // the constructors do (apply_facade_dependency_effects).
    mut fn verify_facade_borrowed_returns():
        for ci in 0..self.foreign_contracts.len() as i32:
            let res = self.foreign_contracts[ci].returns_borrow_resource
            if self.foreign_contracts[ci].returns_static_tid != 0 or (res != 0 and self.pool_resolve(res) == "CStr"):
                self.verify_facade_text_return(ci)
                continue
            if res == 0:
                continue
            self.update_decl_source_context(self.foreign_contracts[ci].decl)
            let fn_sym = self.foreign_contracts[ci].fn_sym
            let node = self.foreign_contracts[ci].node
            let fname: str = self.pool_resolve(fn_sym)
            let rn: str = self.pool_resolve(res)
            let from = self.foreign_contracts[ci].returns_borrow_from
            let sig = self.get_sig(fn_sym)
            if sig < 0:
                continue
            let origin = self.facade_param_receives(fn_sym, from)
            let shown = self.facade_param_display(fn_sym, sig, from)
            if origin.len() != 1:
                let n = origin.len()
                let why = if n == 0: "receives no modeled resource, and With does not invent an origin (§16.2b.7)" else: "receives a representation several resources wrap; the facade has not assigned it (§16.2b.3)"
                self.emit_error(f"fn '{fname}': 'returns borrow {rn} from param {from}' names {shown}, which {why}; a borrowed '{rn}' is a view of the resource its origin parameter receives (§16.2b.6)", node)
                continue
            let recv0 = self.facade_method_host(fn_sym)
            let ci0 = self.facade_contract_for(fn_sym)
            if recv0.len() != 1 or self.foreign_contracts[ci0].destroys != 0 or self.foreign_contracts[ci0].consumes.len() > 0 or self.foreign_contracts[ci0].retains.len() > 0:
                let shown0 = self.facade_param_display(fn_sym, sig, 0)
                self.emit_error(f"fn '{fname}': 'returns borrow {rn}' is presented as a lend method of the resource its first parameter receives, and {shown0} receives none it can be a method of (one pointer resource, with nothing stronger than a lend stated) (§16.2b.6)", node)
                continue
            // One `Borrowed<R>`, one origin view type.
            var clash = false
            for cj in 0..ci:
                if self.foreign_contracts[cj].returns_borrow_resource != res:
                    continue
                let other = self.facade_param_receives(self.foreign_contracts[cj].fn_sym, self.foreign_contracts[cj].returns_borrow_from)
                if other.len() == 1 and other[0] != origin[0]:
                    let on: str = self.pool_resolve(self.facade_resources[origin[0]].name)
                    let oth: str = self.pool_resolve(self.facade_resources[other[0]].name)
                    let ofn: str = self.pool_resolve(self.foreign_contracts[cj].fn_sym)
                    let bn = facade_render_borrowed_name(rn)
                    self.emit_error(f"fn '{fname}' returns a borrowed '{rn}' from a '{on}', and fn '{ofn}' from a '{oth}'; '{bn}' holds a view of one origin resource, and a borrowed value with several origin types is not ruled (§16.2b.6)", node)
                    clash = true
                    break
            if clash or self.diags.has_errors():
                continue
            // The net: the type and the method exist.
            let bn = facade_render_borrowed_name(rn)
            let bsym = self.pool_lookup_symbol(bn)
            if bsym == 0 or not self.facade_ephemeral_struct_declared(bsym):
                self.emit_error(f"fn '{fname}': 'returns borrow {rn}' passed every facade check but no type '{bn}' was rendered; the renderer cannot express this shape and did not say so — a compiler defect (§16.2b.6)", node)
                continue
            let host: str = self.pool_resolve(self.facade_resources[recv0[0]].name)
            let mname = self.facade_presented(recv0[0], fname)
            let mtext = host ++ "." ++ mname
            let msig: i32 = if self.sig_text_index.contains(mtext): self.sig_text_index.get(mtext).unwrap() else: -1
            if msig < 0:
                self.emit_error(f"fn '{fname}': 'returns borrow {rn}' passed every facade check but no method '{host}.{mname}' was rendered — a compiler defect (§16.2b.6)", node)
                continue
            let eff = self.sig_param_effect(msig, from) | EFF_ESCAPE_VIEW
            self.set_sig_param_effect(msig, from, eff)
            self.set_sig_param_direct_effect(msig, from, eff)
            self.set_sig_param_view_origin(msig, from, self.sig_param_view_origin(msig, from) | sema_param_origin_bit(from))

    // ── text views (ruling §32, §40-§42; spec §16.2b.8) ──────────────────
    //
    // `returns borrow CStr from param N`, `returns borrow CStr from domain
    // D` and `returns static CStr`: the nullable foreign string is
    // `Option[CStr]`, the `CStr` value being the borrowed modeled text — a
    // view (Sema.w: `CStr` is ephemeral) of the resource, the C string
    // parameter, the domain, or static storage the facade names as its
    // origin. On an operation whose first parameter receives a resource the
    // renderer makes it a lend method of that resource (FacadeRender.w
    // facade_render_lend_methods), on `R` and on `Borrowed<R>`; this is the
    // net that both exist with that result, and the declared summary that
    // keeps the view inside its origin: escape_view from the origin
    // parameter — the receiver, or the `&str` it is lent (no summary is
    // inferable from a value built out of a raw pointer). Static storage
    // needs none.
    mut fn verify_facade_text_return(ci: i32):
        self.update_decl_source_context(self.foreign_contracts[ci].decl)
        let fn_sym = self.foreign_contracts[ci].fn_sym
        let node = self.foreign_contracts[ci].node
        let fname: str = self.pool_resolve(fn_sym)
        let sig = self.get_sig(fn_sym)
        if sig < 0:
            return
        let from = self.foreign_contracts[ci].returns_borrow_from
        let domain = self.foreign_contracts[ci].returns_borrow_domain
        let what = if self.foreign_contracts[ci].returns_static_tid != 0: "returns static CStr" else: "returns borrow CStr"
        let recv0 = self.facade_method_host(fn_sym)
        let hosted = recv0.len() == 1 and self.foreign_contracts[ci].destroys == 0 and self.foreign_contracts[ci].consumes.len() == 0 and self.foreign_contracts[ci].retains.len() == 0
        if self.diags.has_errors():
            return
        if not hosted:
            // No resource to be a method of: the C name itself is the
            // surface, as for every lend. The call is presented — its result
            // is `Option[CStr]` at each call site in a module that imported
            // it (SemaCheck.w check_call; MirLower.w lower_call turns the
            // pointer into the view) — and its declaration stays what C
            // declared, so a module with its own `strchr` extern (std.re)
            // is untouched; the origin goes on the call through the effect
            // record (facade_index_call_effects: the C string parameter or
            // the domain; static needs none).
            if self.foreign_contracts[ci].rename != 0:
                self.emit_error(f"fn '{fname}': '{what}' is presented under the C name at its call sites; 'rename' would need a second declaration, which a presented call does not get (§16.2b.8)", node)
                return
            self.facade_presented_syms.insert(fn_sym, 1)
            return
        let host: str = self.pool_resolve(self.facade_resources[recv0[0]].name)
        let mname = self.facade_presented(recv0[0], fname)
        let hosts: Vec[str] = Vec.new()
        hosts.push(host.clone())
        hosts.push(facade_render_borrowed_name(host))
        // `valid on failed`: the same view on the failed state (#1612).
        if self.foreign_contracts[ci].valid_on_failed != 0:
            hosts.push(facade_render_failed_name(host))
        for hi in 0..hosts.len() as i32:
            let mtext = hosts[hi] ++ "." ++ mname
            let msig: i32 = if self.sig_text_index.contains(mtext): self.sig_text_index.get(mtext).unwrap() else: -1
            if msig < 0:
                if hi == 0 or hi == 2:
                    self.emit_error(f"fn '{fname}': '{what}' passed every facade check but no method '{mtext}' was rendered — a compiler defect (§16.2b.8)", node)
                continue
            if not self.facade_sig_returns_option_cstr(msig):
                let rt: str = self.type_name(self.sig_return_type(msig))
                self.emit_error(f"fn '{fname}': '{what}' was rendered as '{mtext}' returning {rt}, not Option[CStr] — a compiler defect (§16.2b.8)", node)
                continue
            if from >= 0:
                self.facade_declare_view_of_param(msig, from)
            // A domain origin (`from domain D`) is put on the method by
            // facade_index_call_effects.
            let _ = domain

    // ── call effects (ruling §33-§38; spec §16.2b.7) ─────────────────────
    //
    // "For every origin touched by a foreign operation, the relevant view
    // effect is invalidate / preserve. The conservative default is: unknown
    // effect means invalidate." So a call to a facade operation — the
    // rendered method, constructor, or the raw C function — invalidates
    // every view borrowed from each resource it receives, unless its fn
    // item states `preserves param N`, and every view borrowed from each
    // foreign-state domain of its library, unless it states `preserves
    // domain D`. The library of a domain is coarse (§34): the `<c_import …>`
    // translations of the functions its facade describes. A result stated
    // `returns borrow CStr from domain D` depends on D's origin symbol.
    // Indexed per signature here; SemaCheck.w record_call_view_origins
    // applies it at each call.
    mut fn facade_index_call_effects():
        if self.diags.has_errors():
            return
        // The files each facade describes: its fn items and resource operations.
        for ci in 0..self.foreign_contracts.len() as i32:
            self.facade_domain_note_file(self.foreign_contracts[ci].facade, self.facade_fn_file(self.foreign_contracts[ci].fn_sym))
        for ri in 0..self.facade_resources.len() as i32:
            let facade = self.facade_resources[ri].facade
            for pi in 0..self.facade_resources[ri].producers.len() as i32:
                self.facade_domain_note_file(facade, self.facade_fn_file(self.facade_resources[ri].producers[pi]))
            let ops: Vec[i32] = Vec.new()
            ops.push(self.facade_resources[ri].init)
            ops.push(self.facade_resources[ri].preinit)
            ops.push(self.facade_resources[ri].drop)
            for oi in 0..ops.len() as i32:
                if ops[oi] != 0:
                    self.facade_domain_note_file(facade, self.facade_fn_file(ops[oi]))
            for di in 0..self.facade_resources[ri].destroyers.len() as i32:
                self.facade_domain_note_file(facade, self.facade_fn_file(self.facade_resources[ri].destroyers[di]))
        // Every c_import function: the raw call, and the fn item's rendered
        // method when it has one.
        for di in 0..self.ast.decl_count():
            if di >= self.decl_is_c_import.len() as i32 or self.decl_is_c_import[di] == 0:
                continue
            let decl = self.ast.get_decl(di)
            let kind = self.ast.kind(decl)
            if kind != NodeKind.NK_EXTERN_FN and kind != NodeKind.NK_FN_DECL:
                continue
            let fn_sym = self.ast.get_data0(decl)
            let sig = self.get_sig(fn_sym)
            if sig < 0:
                continue
            let ci = self.facade_contract_for(fn_sym)
            let file = self.decl_source_file_id_for_index(di)
            let domains = self.facade_domains_touched(file, ci)
            let borrow = if ci >= 0 and self.foreign_contracts[ci].returns_borrow_domain != 0: self.facade_domain_index.get(self.foreign_contracts[ci].returns_borrow_domain).unwrap() else: -1
            // A presented call (facade_presented_syms) borrows from the C
            // string parameter its item names, a by-value pointer the
            // ordinary origin rule skips.
            let borrow_param = if ci >= 0 and self.facade_presented_syms.contains(fn_sym): self.foreign_contracts[ci].returns_borrow_from else: -1
            if domains.len() == 0 and borrow < 0 and borrow_param < 0 and self.facade_touch_params_mask(fn_sym, ci, 0) == 0:
                continue
            self.facade_add_call_effect(sig, fn_sym, ci, self.facade_touch_params_mask(fn_sym, ci, 0), &domains, borrow, borrow_param)
            if ci < 0:
                continue
            // The rendered lend method of the resource param 0 receives: the
            // parameter indices are the C ones (self is 0).
            let recv0 = self.facade_method_host(fn_sym)
            if recv0.len() != 1:
                continue
            let mname = self.facade_presented(recv0[0], self.pool_resolve(fn_sym))
            let host: str = self.pool_resolve(self.facade_resources[recv0[0]].name)
            let hosts: Vec[str] = Vec.new()
            hosts.push(host ++ "." ++ mname)
            hosts.push(facade_render_borrowed_name(host) ++ "." ++ mname)
            if self.foreign_contracts[ci].valid_on_failed != 0:
                hosts.push(facade_render_failed_name(host) ++ "." ++ mname)
            for hi in 0..hosts.len() as i32:
                let htext = hosts[hi].clone()
                if self.sig_text_index.contains(htext):
                    self.facade_add_call_effect(self.sig_text_index.get(htext).unwrap(), fn_sym, ci, self.facade_touch_params_mask(fn_sym, ci, 0), &domains, borrow, -1)
        // Constructors: a producer receiving other resources touches them
        // (their views), with the out slot removed from the indices as
        // apply_facade_dependency_effects removes it.
        for ri in 0..self.facade_resources.len() as i32:
            let rname: str = self.pool_resolve(self.facade_resources[ri].name)
            let owners = self.facade_owners(ri)
            for oi in 0..owners.len() as i32:
                let owner = owners[oi]
                let f = self.facade_owner_fn(ri, owner)
                if f == 0:
                    continue
                let sigs = self.facade_producer_sigs(ri, owner, f)
                if sigs.len() == 0:
                    continue
                let ci = self.facade_contract_for(f)
                let domains = self.facade_domains_touched(self.facade_fn_file(f), ci)
                var shift = 0
                if owner == FACADE_DEP_INIT and self.facade_resources[ri].preinit != 0:
                    shift = self.sig_get_param_count(self.get_sig(self.facade_resources[ri].preinit))
                let slot = self.facade_owner_skip(ri, owner)
                let raw_mask = self.facade_touch_params_mask(f, ci, if owner == FACADE_DEP_INIT: 1 else: 0)
                var mask = 0
                for c_pi in 0..self.sig_get_param_count(self.get_sig(f)):
                    if (raw_mask & sema_param_origin_bit(c_pi)) == 0 or c_pi == slot:
                        continue
                    var pi = c_pi
                    if owner == FACADE_DEP_INIT:
                        pi = shift + c_pi - 1
                    else if slot >= 0 and c_pi > slot:
                        pi = c_pi - 1
                    mask = mask | sema_param_origin_bit(pi)
                if mask != 0 or domains.len() > 0:
                    for si in 0..sigs.len() as i32:
                        self.facade_add_call_effect(sigs[si], f, ci, mask, &domains, -1, -1)

    mut fn facade_add_call_effect(sig: i32, fn_sym: i32, ci: i32, mask: i32, domains: &Vec[i32], borrow: i32, borrow_param: i32):
        if self.facade_call_effect_index.contains(sig):
            return
        let touched: Vec[i32] = Vec.new()
        for i in 0..domains.len() as i32:
            touched.push(domains[i])
        self.facade_call_effect_index.insert(sig, self.facade_call_effects.len() as i32)
        self.facade_call_effects.push(FacadeCallEffect { sig, fn_sym, contract: ci, touch_params: mask, touch_domains: touched, borrow_domain: borrow, borrow_param })

    // The parameters of `fn_sym` (from `first`) that receive one modeled
    // resource and are not preserved by its fn item, as origin bits.
    fn facade_touch_params_mask(fn_sym: i32, ci: i32, first: i32) -> i32:
        let sig = self.get_sig(fn_sym)
        if sig < 0:
            return 0
        var mask = 0
        for pi in first..self.sig_get_param_count(sig):
            if self.facade_param_receives(fn_sym, pi).len() != 1:
                continue
            var preserved = false
            if ci >= 0:
                for k in 0..self.foreign_contracts[ci].preserves_params.len() as i32:
                    if self.foreign_contracts[ci].preserves_params[k] == pi: preserved = true
            if not preserved:
                mask = mask | sema_param_origin_bit(pi)
        mask

    // The domains a function declared in `file` touches: those of its
    // library, less the ones its fn item preserves.
    fn facade_domains_touched(file: i32, ci: i32) -> Vec[i32]:
        let out: Vec[i32] = Vec.new()
        for di in 0..self.facade_domain_list.len() as i32:
            var in_library = false
            for fi in 0..self.facade_domain_list[di].files.len() as i32:
                if self.facade_domain_list[di].files[fi] == file: in_library = true
            if not in_library:
                continue
            var preserved = false
            if ci >= 0:
                for k in 0..self.foreign_contracts[ci].preserves_domains.len() as i32:
                    if self.foreign_contracts[ci].preserves_domains[k] == self.facade_domain_list[di].name: preserved = true
            if not preserved:
                out.push(di)
        out

    mut fn facade_domain_note_file(facade: i32, file: i32):
        if file == 0:
            return
        for di in 0..self.facade_domain_list.len() as i32:
            var declared_by = false
            for fi in 0..self.facade_domain_list[di].facades.len() as i32:
                if self.facade_domain_list[di].facades[fi] == facade: declared_by = true
            if not declared_by:
                continue
            var seen = false
            for fi in 0..self.facade_domain_list[di].files.len() as i32:
                if self.facade_domain_list[di].files[fi] == file: seen = true
            if not seen:
                self.facade_domain_list[di].files.push(file)

    // The source file of the function's c_import declaration — the
    // `<c_import …>` translation that is its library (§34). A facade
    // describes imported declarations (§16.2b.13), so an import wins over a
    // same-named With extern elsewhere (std.libc's `strerror`), whose file
    // would put the domain in the wrong library.
    fn facade_fn_file(fn_sym: i32) -> i32:
        let want: str = self.safe_symbol_text(fn_sym)
        for di in 0..self.ast.decl_count():
            if di >= self.decl_is_c_import.len() as i32 or self.decl_is_c_import[di] == 0:
                continue
            let decl = self.ast.get_decl(di)
            let kind = self.ast.kind(decl)
            if (kind == NodeKind.NK_EXTERN_FN or kind == NodeKind.NK_FN_DECL) and self.safe_symbol_text(self.ast.get_data0(decl)) == want:
                return self.decl_source_file_id_for_index(di)
        let node = self.facade_fn_decl_node(fn_sym)
        if node == 0 or not self.decl_index_by_node.contains(node):
            return 0
        self.decl_source_file_id_for_index(self.decl_index_by_node.get(node).unwrap())

    // Whether a call to `fn_sym` from the module being checked is a
    // presented text-view call (spec §16.2b.8): the fn item presents it,
    // the symbol is the c_import's, and this module imported it — a module
    // with its own same-named extern (std.re's `strchr`) is not presented.
    fn facade_call_is_presented(fn_sym: i32) -> bool:
        self.facade_presented_syms.contains(fn_sym) and self.ci_syms.contains(fn_sym) and self.current_module_uses_c_import()

    fn facade_call_effect_for(sig: i32) -> i32:
        if self.facade_call_effect_index.contains(sig): self.facade_call_effect_index.get(sig).unwrap() else: -1

    // Whether a type holds a modeled resource — the resource itself, a
    // reference to one, a dependent child, an Option of either. Such a
    // binding is a resource, not a view of one's memory, and a foreign
    // operation's unknown effect does not invalidate it (§27 dependency is
    // lifetime; §38 invalidation is of views).
    fn facade_type_holds_resource(tid: i32, depth: i32) -> bool:
        if tid <= 0 or depth > 6 or self.facade_resources.len() == 0:
            return false
        let r = self.resolve_alias(tid as TypeId)
        let kind = self.get_type_kind(r)
        let name = self.get_type_name(r)
        if name != 0 and kind != TypeKind.TY_REF and kind != TypeKind.TY_PTR:
            if self.facade_resource_index.contains(name):
                return true
        if kind == TypeKind.TY_GENERIC_INST:
            for ai in 0..self.get_generic_inst_arg_count(r as i32):
                if self.facade_type_holds_resource(self.get_generic_inst_arg(r as i32, ai), depth + 1):
                    return true
        else if kind == TypeKind.TY_TUPLE:
            let te_start = self.get_type_d0(r)
            for ei in 0..self.get_type_d1(r):
                if self.facade_type_holds_resource(self.type_extra[(te_start + ei)], depth + 1):
                    return true
        else if kind == TypeKind.TY_REF or kind == TypeKind.TY_ARRAY or kind == TypeKind.TY_PTR:
            return self.facade_type_holds_resource(self.get_type_d0(r), depth + 1)
        false

    // The declared summary: the result of signature `sig` is a view of
    // parameter `pi` (its receiver when 0), as the constructors and
    // `Borrowed<R>` methods state theirs (apply_facade_dependency_effects).
    mut fn facade_declare_view_of_param(sig: i32, pi: i32):
        let eff = self.sig_param_effect(sig, pi) | EFF_ESCAPE_VIEW
        self.set_sig_param_effect(sig, pi, eff)
        self.set_sig_param_direct_effect(sig, pi, eff)
        self.set_sig_param_view_origin(sig, pi, self.sig_param_view_origin(sig, pi) | sema_param_origin_bit(pi))

    // ── caller-owned buffers (#1621; spec §16.2b.3, §16.2b.8) ─────────────
    //
    // A lend covers every parameter it does not name (facade_covers_param),
    // and so a `lend` on `compress(Bytef *dest, uLongf *destLen, const
    // Bytef *source, uLong sourceLen)` rendered a SAFE call over raw
    // pointers with no bounds contract: a caller passing a capacity larger
    // than its array corrupted memory in safe code — the partial model
    // §16.2b.3 forbids ("a partial model that could create unsafety is a
    // compile error"). No clause pairs a buffer with its length yet (a
    // ruling is pending on #1621), so until one exists a lend-shaped item
    // — one that states nothing stronger than a lend, hosted or not —
    // whose C signature has a pointer parameter the facade covers is
    // refused, naming the parameter. What is not a caller-owned buffer and
    // stays covered: a parameter receiving a modeled resource (reached
    // through the resource, §16.2b.5), a `const char *` input (a lent
    // `str`, §16.3c), and a code pointer (a callback, §16.2b.9). Every
    // other pointer — `T *`, `void *`, `unsigned char *`, `int *` — is a
    // buffer or an out slot With holds no contract for; leave the call raw.
    mut fn verify_facade_buffer_params():
        for ci in 0..self.foreign_contracts.len() as i32:
            if self.foreign_contracts[ci].destroys != 0 or self.foreign_contracts[ci].consumes.len() > 0 or self.foreign_contracts[ci].retains.len() > 0 or self.foreign_contracts[ci].callback_userdata_cb.len() > 0 or self.foreign_contracts[ci].callback_thread_any != 0 or self.foreign_contracts[ci].callback_consumes.len() > 0:
                continue
            let fn_sym = self.foreign_contracts[ci].fn_sym
            let decl = self.foreign_contracts[ci].decl
            let node = self.foreign_contracts[ci].node
            if self.facade_fn_is_resource_op(fn_sym):
                continue
            let sig = self.get_sig(fn_sym)
            if sig < 0:
                continue
            for pi in 0..self.sig_get_param_count(sig):
                let ptid = self.sig_param_type(sig, pi)
                let pty = self.resolve_alias(ptid as TypeId)
                if self.get_type_kind(pty) != TypeKind.TY_PTR:
                    continue
                if self.facade_param_receives(fn_sym, pi).len() > 0 or self.ci_type_is_const_c_string_input(ptid) != 0 or self.facade_param_is_callable(sig, pi):
                    continue
                // A paired buffer, its length or a fixed argument (D64) is
                // the rendering's: the slice, or the literal.
                if self.facade_contract_pairs(ci, pi):
                    continue
                // A pointer to a C record is a handle, not a buffer: no
                // length pairs with it, and a lend of one is the stage-3
                // default (a facade lends every parameter it does not
                // name). A buffer is a pointer to bytes, scalars, `void`
                // or pointers — what a (ptr, len) pair spans.
                let pointee = self.resolve_alias(self.get_type_d0(pty) as TypeId)
                let pk = self.get_type_kind(pointee)
                if pk == TypeKind.TY_STRUCT or pk == TypeKind.TY_ENUM or pk == TypeKind.TY_GENERIC_INST:
                    continue
                self.update_decl_source_context(decl)
                let fname: str = self.pool_resolve(fn_sym)
                let shown = self.facade_param_display(fn_sym, sig, pi)
                let pname = self.facade_param_c_name(fn_sym, pi)
                self.emit_error_with_help(f"fn '{fname}': a lend would make the call safe, but {shown} is a caller-owned buffer that no clause pairs; a safe call over a raw pointer with no bounds is the partial model §16.2b.3 forbids (§16.2b.5, §16.2b.8)", node, f"pair it with 'buffer param {pname} len param <L>' or 'buffer param {pname} capacity param <L> inout', bind it with 'param {pname} fixed <literal>', or leave the operation raw (D64)")
                break

    // ── the failed state (ruling §18; spec §16.2b.4; D59) ─────────────────
    //
    // "A resource owned by an error admits raw access only, unless the
    // facade marks an operation as valid on the failure state." `valid on
    // failed` is that mark (stage 12b, #1612): the operation is rendered on
    // `Failed<R>` too (FacadeRender.w facade_render_error_type), under the
    // name it has on `R`. What it may mark is a lend or a text view of a
    // resource that has a failed state — an out-parameter producer under
    // `ok`, of a resource that depends on nothing (a dependent one's failure
    // is destroyed in the constructor). A destroying, consuming, retaining
    // or callback operation, or one returning a borrowed resource, is
    // refused: the failed state is destroyed by its error's Drop and owns
    // nothing else, and `Borrowed<R>` holds a view of a live `R`.
    mut fn verify_facade_failed_state_items():
        for ci in 0..self.foreign_contracts.len() as i32:
            if self.foreign_contracts[ci].valid_on_failed == 0:
                continue
            self.update_decl_source_context(self.foreign_contracts[ci].decl)
            let fn_sym = self.foreign_contracts[ci].fn_sym
            let node = self.foreign_contracts[ci].node
            let fname: str = self.pool_resolve(fn_sym)
            let sig = self.get_sig(fn_sym)
            if sig < 0:
                continue
            let recv0 = self.facade_method_host(fn_sym)
            if recv0.len() != 1:
                let shown0 = self.facade_param_display(fn_sym, sig, 0)
                let why = if recv0.len() == 0: "receives no modeled resource" else: "receives a representation several resources wrap; the facade has not assigned it (§16.2b.3)"
                self.emit_error(f"fn '{fname}': 'valid on failed' marks an operation of the failed state of the resource its first parameter receives, and {shown0} {why} (§16.2b.4)", node)
                continue
            let ri = recv0[0]
            let rname: str = self.pool_resolve(self.facade_resources[ri].name)
            if not self.facade_has_failed_state(ri):
                self.emit_error(f"fn '{fname}': 'valid on failed', but '{rname}' has no failed state: a failure that still produced is owned by the error only for an out-parameter producer under 'ok' of a resource that depends on nothing (§16.2b.4)", node)
                continue
            let borrow_res = self.foreign_contracts[ci].returns_borrow_resource
            let borrows_resource = borrow_res != 0 and self.pool_resolve(borrow_res) != "CStr"
            let stronger = self.foreign_contracts[ci].destroys != 0 or self.foreign_contracts[ci].consumes.len() > 0 or self.foreign_contracts[ci].retains.len() > 0 or self.foreign_contracts[ci].callback_userdata_cb.len() > 0 or self.foreign_contracts[ci].callback_thread_any != 0 or self.foreign_contracts[ci].callback_consumes.len() > 0
            if stronger or borrows_resource or self.facade_fn_is_resource_op(fn_sym):
                self.emit_error(f"fn '{fname}': 'valid on failed' marks a lend or a text view of the failed '{rname}'; a failed state is destroyed by its error's Drop and owns nothing else, so a producing, destroying, consuming, retaining or callback operation, or one returning a borrowed resource, cannot be valid on it (§16.2b.4)", node)
                continue
            if self.diags.has_errors():
                continue
            // The net: the method exists on `Failed<R>`.
            let mtext = facade_render_failed_name(rname) ++ "." ++ self.facade_presented(ri, fname)
            if not self.sig_text_index.contains(mtext):
                self.emit_error(f"fn '{fname}': 'valid on failed' passed every facade check but no method '{mtext}' was rendered; the renderer cannot express this shape and did not say so — a compiler defect (§16.2b.4)", node)

    // Whether the failed state of resource `ri` carries operation `cname`:
    // its fn item states `valid on failed` (the unknown-method diagnostic
    // names the rule, SemaCheck.w).
    fn facade_resource_has_failed_state_items(ri: i32) -> bool:
        for ci in 0..self.foreign_contracts.len() as i32:
            if self.foreign_contracts[ci].valid_on_failed == 0:
                continue
            let recv0 = self.facade_method_host(self.foreign_contracts[ci].fn_sym)
            if recv0.len() == 1 and recv0[0] == ri:
                return true
        false

    // `nullable param N` (ruling §43, spec §16.2b.8) is rendered for one
    // shape in stage 12b: the callback of a `callback param N userdata param
    // M` pairing (#1618; verify_facade_callback_items checks the pairing). A
    // raw pointer parameter accepts `null` as C declares it and needs no
    // clause; a nullable C string (`Option[&str]`) or resource parameter
    // (`Option[&R]`) is not modeled, and saying so beats rendering the
    // clause as nothing.
    mut fn verify_facade_nullable_items():
        for ci in 0..self.foreign_contracts.len() as i32:
            if self.foreign_contracts[ci].nullable_params.len() == 0 or self.facade_contract_is_callback_item(ci):
                continue
            self.update_decl_source_context(self.foreign_contracts[ci].decl)
            let fn_sym = self.foreign_contracts[ci].fn_sym
            let fname: str = self.pool_resolve(fn_sym)
            let sig = self.get_sig(fn_sym)
            if sig < 0:
                continue
            let pi = self.foreign_contracts[ci].nullable_params[0]
            let shown = self.facade_param_display(fn_sym, sig, pi)
            self.emit_error(f"fn '{fname}': nullable {shown}; nullability is rendered for the callback of a 'callback param N userdata param M' pairing (an absent callback takes its userdata with it, §16.2b.9), and a raw pointer parameter accepts null as C declares it — a nullable C string or resource parameter is not modeled (§16.2b.8)", self.foreign_contracts[ci].node)

    // Owned foreign text (ruling §42): every rendered pointer resource over
    // a C string carries `as_cstr() -> CStr` (FacadeRender.w
    // facade_render_text_view), a view kept inside the resource's life by
    // this summary; the same on its `Borrowed<R>`.
    mut fn verify_facade_text_views():
        if self.diags.has_errors():
            return
        for ri in 0..self.facade_resources.len() as i32:
            if not self.facade_type_is_c_string_ptr(self.facade_resources[ri].repr_tid) or not self.facade_resource_rendered(ri):
                continue
            self.update_decl_source_context(self.facade_resources[ri].decl)
            let rname: str = self.pool_resolve(self.facade_resources[ri].name)
            let hosts: Vec[str] = Vec.new()
            hosts.push(rname.clone())
            hosts.push(facade_render_borrowed_name(rname))
            for hi in 0..hosts.len() as i32:
                let mtext = hosts[hi] ++ "." ++ facade_render_text_view_name()
                let msig: i32 = if self.sig_text_index.contains(mtext): self.sig_text_index.get(mtext).unwrap() else: -1
                if msig < 0:
                    if hi == 0:
                        self.emit_error(f"resource '{rname}' wraps a C string but no '{mtext}' view was rendered — a compiler defect (§16.2b.8)", self.facade_resources[ri].node)
                    continue
                self.facade_declare_view_of_param(msig, 0)

    // A NUL-terminated C string's pointer as c_import spells it: `char *`
    // and `const char *` alike (`*mut i8`, `*const i8`, aliases chased),
    // and `unsigned char *` (`*const u8`): sqlite3_column_text's spelling
    // of the same NUL-terminated bytes — `CStr` makes no claim about the
    // bytes (§16.2b.8), so their C signedness is not evidence of anything.
    fn facade_type_is_c_string_ptr(tid: i32) -> bool:
        if tid == 0:
            return false
        let r = self.resolve_alias(tid as TypeId)
        if self.get_type_kind(r) != TypeKind.TY_PTR:
            return false
        let pointee = self.resolve_alias(self.get_type_d0(r) as TypeId)
        pointee == self.ty_i8 or pointee == self.ty_u8

    fn facade_sig_returns_option_cstr(sig: i32) -> bool:
        let r = self.resolve_alias(self.sig_return_type(sig) as TypeId)
        if self.get_type_kind(r) != TypeKind.TY_GENERIC_INST or self.get_generic_inst_arg_count(r as i32) != 1:
            return false
        self.pool_resolve(self.get_type_d0(r)) == "Option" and self.resolve_alias(self.get_generic_inst_arg(r as i32, 0) as TypeId) == self.ty_cstr

    fn facade_ephemeral_struct_declared(sym: i32) -> bool:
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) == NodeKind.NK_TYPE_DECL and self.ast.get_data0(decl) == sym:
                let packed = self.ast.get_data2(decl)
                return type_decl_sub_kind(packed) == TypeDeclKind.Struct as i32 and type_decl_is_ephemeral(packed) != 0
        false

    // The contract whose `Borrowed<R>` a type carries, or -1.
    fn facade_borrowed_contract_in(tid: i32, depth: i32) -> i32:
        if tid <= 0 or depth > 6 or self.foreign_contracts.len() == 0:
            return -1
        let r = self.resolve_alias(tid as TypeId)
        let kind = self.get_type_kind(r)
        let name = self.get_type_name(r)
        if name != 0:
            let tn: str = self.pool_resolve(name)
            for ci in 0..self.foreign_contracts.len() as i32:
                let res = self.foreign_contracts[ci].returns_borrow_resource
                if res != 0 and facade_render_borrowed_name(self.pool_resolve(res)) == tn:
                    return ci
        if kind == TypeKind.TY_GENERIC_INST:
            for ai in 0..self.get_generic_inst_arg_count(r as i32):
                let found = self.facade_borrowed_contract_in(self.get_generic_inst_arg(r as i32, ai), depth + 1)
                if found >= 0:
                    return found
        else if kind == TypeKind.TY_TUPLE:
            let te_start = self.get_type_d0(r)
            for ei in 0..self.get_type_d1(r):
                let found = self.facade_borrowed_contract_in(self.type_extra[(te_start + ei)], depth + 1)
                if found >= 0:
                    return found
        else if kind == TypeKind.TY_REF or kind == TypeKind.TY_ARRAY:
            return self.facade_borrowed_contract_in(self.get_type_d0(r), depth + 1)
        -1

    // §8, §57: what a borrowed value is borrowed from, and the clause.
    fn facade_borrowed_note(ci: i32) -> str:
        let fn_sym = self.foreign_contracts[ci].fn_sym
        let fname: str = self.pool_resolve(fn_sym)
        let rn: str = self.pool_resolve(self.foreign_contracts[ci].returns_borrow_resource)
        let bn = facade_render_borrowed_name(rn)
        let from = self.foreign_contracts[ci].returns_borrow_from
        let facade: str = self.pool_resolve(self.foreign_contracts[ci].facade)
        let sig = self.get_sig(fn_sym)
        let shown = if sig >= 0: self.facade_param_display(fn_sym, sig, from) else: f"param {from}"
        let origin = self.facade_param_receives(fn_sym, from)
        let osym = if origin.len() > 0: self.facade_resources[origin[0]].name else: 0
        var on = "?"
        if osym != 0:
            on = self.pool_resolve(osym)
        f"borrowed: '{bn}' is borrowed from the '{on}' that '{fname}' receives as {shown} — stated by 'returns borrow {rn} from param {from}' in facade {facade}; it has no Drop and cannot outlive that origin (§16.2b.6)"

// ── stage 9: callbacks and threads (ruling §44-§51, spec §16.2b.9-10) ───
//
// A callback contract — an fn item that retains a callback or its userdata,
// consumes userdata with a destroy callback, types a callback's userdata
// (`callback param N userdata param M`), or says `callback_thread any` — is
// presented as a method of the resource its first parameter receives
// (compiler/FacadeRender.w facade_render_callback_methods). The method is
// generic in the userdata type `U`: the callback is `extern "C" fn(&U, …)`
// (captureless, §12.4 — C receives the code pointer alone) and the userdata
// `&U` for the call (§44: borrowed for callback scope), `U` owned by the
// resource until it is destroyed (§45), or `U` moved into C and destroyed
// by the callback the contract names (§24). What the rendered generic
// method cannot state is checked at its call sites (SemaCheck.w
// facade_check_callback_arg): under `callback_thread any` the userdata type
// is Send and Sync (§51). Thread capabilities (§48-§50) are the resource's
// (facade_thread_caps_for; SemaCheck.w type_satisfies_thread_trait): a
// resource is thread-bound unless its facade says `send` / `share`.

impl Sema:
    // Whether the fn item is a callback contract.
    fn facade_contract_is_callback_item(ci: i32) -> bool:
        if self.foreign_contracts[ci].destroys != 0:
            return false
        if self.foreign_contracts[ci].callback_userdata_cb.len() > 0 or self.foreign_contracts[ci].callback_thread_any != 0:
            return true
        for k in 0..self.foreign_contracts[ci].consumes.len() as i32:
            if self.foreign_contracts[ci].consumes_destroyed_by[k] >= 0:
                return true
        let fn_sym = self.foreign_contracts[ci].fn_sym
        let sig = self.get_sig(fn_sym)
        for k in 0..self.foreign_contracts[ci].retains.len() as i32:
            let a = self.foreign_contracts[ci].retains[k]
            if sig >= 0 and (self.facade_param_is_userdata(fn_sym, sig, a) or self.facade_param_is_callable(sig, a)):
                return true
        false

    // The userdata parameter of a callback contract (C index), or -1: the
    // one consumed with a destroy callback, retained, or paired with a
    // callback. One per item (a second is not modeled).
    fn facade_contract_userdata_param(ci: i32) -> i32:
        let fn_sym = self.foreign_contracts[ci].fn_sym
        let sig = self.get_sig(fn_sym)
        if sig < 0:
            return -1
        for k in 0..self.foreign_contracts[ci].consumes.len() as i32:
            if self.foreign_contracts[ci].consumes_destroyed_by[k] >= 0:
                return self.foreign_contracts[ci].consumes[k]
        for k in 0..self.foreign_contracts[ci].retains.len() as i32:
            if self.facade_param_is_userdata(fn_sym, sig, self.foreign_contracts[ci].retains[k]):
                return self.foreign_contracts[ci].retains[k]
        if self.foreign_contracts[ci].callback_userdata_of.len() > 0:
            return self.foreign_contracts[ci].callback_userdata_of[0]
        -1

    // Whether the item's userdata is retained by the resource / consumed.
    fn facade_contract_userdata_retained(ci: i32) -> bool:
        let fn_sym = self.foreign_contracts[ci].fn_sym
        let sig = self.get_sig(fn_sym)
        for k in 0..self.foreign_contracts[ci].retains.len() as i32:
            if sig >= 0 and self.facade_param_is_userdata(fn_sym, sig, self.foreign_contracts[ci].retains[k]):
                return true
        false

    fn facade_contract_userdata_consumed(ci: i32) -> bool:
        for k in 0..self.foreign_contracts[ci].consumes.len() as i32:
            if self.foreign_contracts[ci].consumes_destroyed_by[k] >= 0:
                return true
        false

    // The callback parameter paired with the item's userdata (C index), or
    // -1.
    fn facade_contract_callback_param(ci: i32) -> i32:
        if self.foreign_contracts[ci].callback_userdata_cb.len() > 0: self.foreign_contracts[ci].callback_userdata_cb[0] else: -1

    // Ruling §61 for callback contracts, and the net under the renderer.
    mut fn verify_facade_callback_items():
        for ci in 0..self.foreign_contracts.len() as i32:
            if not self.facade_contract_is_callback_item(ci):
                continue
            self.update_decl_source_context(self.foreign_contracts[ci].decl)
            let fn_sym = self.foreign_contracts[ci].fn_sym
            let node = self.foreign_contracts[ci].node
            let fname: str = self.pool_resolve(fn_sym)
            let sig = self.get_sig(fn_sym)
            if sig < 0:
                continue
            let recv0 = self.facade_method_host(fn_sym)
            if recv0.len() != 1 or not self.facade_received_presentable(recv0[0], fn_sym, 0):
                let shown0 = self.facade_param_display(fn_sym, sig, 0)
                let why = if recv0.len() == 0: "receives no modeled resource" else: if recv0.len() > 1: "receives a representation several resources wrap; the facade has not assigned it (§16.2b.3)" else: self.facade_received_unpresentable_reason(recv0[0], fn_sym, 0)
                self.emit_error(f"fn '{fname}': a callback contract is presented as a method of the resource its first parameter receives, and {shown0} {why} (§16.2b.9)", node)
                continue
            // §46: a callback receiving ownership is stated, never inferred
            // — and not yet modeled: the callback receives its userdata as
            // a borrow (`&U`), and a facade saying otherwise would have
            // With free what the callback took.
            if self.foreign_contracts[ci].callback_consumes.len() > 0:
                self.emit_error(f"fn '{fname}': 'callback consumes' is not modeled yet; a callback receives its userdata as a borrow for the callback's scope (§16.2b.9)", node)
                continue
            // A userdata is consumed by C (destroyed by the callback the
            // contract names) or retained by the resource — never both.
            if self.facade_contract_userdata_consumed(ci) and self.facade_contract_userdata_retained(ci):
                let cud = self.facade_contract_userdata_param(ci)
                let shown = self.facade_param_display(fn_sym, sig, cud)
                self.emit_error(f"fn '{fname}': {shown} is both consumed ('consumes … destroyed_by': C owns and destroys it) and retained ('retains … by': the resource owns and releases it); state one (§16.2b.5, §16.2b.9)", node)
                continue
            // One userdata per item: a consumed-with-destroy userdata, a
            // retained one and a paired one are the same parameter.
            let ud = self.facade_contract_userdata_param(ci)
            var second = -1
            for k in 0..self.foreign_contracts[ci].consumes.len() as i32:
                if self.foreign_contracts[ci].consumes_destroyed_by[k] >= 0 and self.foreign_contracts[ci].consumes[k] != ud: second = self.foreign_contracts[ci].consumes[k]
            for k in 0..self.foreign_contracts[ci].retains.len() as i32:
                let a = self.foreign_contracts[ci].retains[k]
                if self.facade_param_is_userdata(fn_sym, sig, a) and a != ud: second = a
            for k in 0..self.foreign_contracts[ci].callback_userdata_of.len() as i32:
                if self.foreign_contracts[ci].callback_userdata_of[k] != ud: second = self.foreign_contracts[ci].callback_userdata_of[k]
            if second >= 0:
                let s1 = self.facade_param_display(fn_sym, sig, ud)
                let s2 = self.facade_param_display(fn_sym, sig, second)
                self.emit_error(f"fn '{fname}' describes two userdata parameters, {s1} and {s2}; a callback contract with more than one userdata is not modeled (§16.2b.9)", node)
                continue
            // A retained callback's userdata, and a userdata consumed with
            // a destroy callback, are what the resource keeps or C
            // destroys: their type is the caller's `U`, which the callback
            // must be able to receive — so a callback that gets the userdata
            // says so (`callback param N userdata param M`), or the userdata
            // is opaque to it. Nothing to verify beyond the pairing.
            if self.foreign_contracts[ci].callback_thread_any != 0:
                var callable_count = 0
                for pi in 1..self.sig_get_param_count(sig):
                    if self.facade_param_is_callable(sig, pi): callable_count = callable_count + 1
                if callable_count == 0:
                    self.emit_error(f"fn '{fname}': 'callback_thread any' says the callback may run on any thread, but '{fname}' takes no callback (§16.2b.10)", node)
                    continue
            // `nullable param N` on a callback contract (#1618; ruling §43,
            // spec §16.2b.8-9): the paired callback is rendered
            // `Option[extern "C" fn(&U, …)]` and its userdata `Option[&U]`
            // — an absent callback takes its userdata with it, since the
            // userdata is what the callback receives. A retained or
            // consumed userdata's callback is kept by C past the call and
            // is not modeled nullable; nor is any other parameter here.
            let paired_cb = self.facade_contract_callback_param(ci)
            var nullable = 0
            var bad = -1
            for k in 0..self.foreign_contracts[ci].nullable_params.len() as i32:
                let npi = self.foreign_contracts[ci].nullable_params[k]
                if npi == paired_cb and paired_cb >= 0 and ud >= 0 and not self.facade_contract_userdata_retained(ci) and not self.facade_contract_userdata_consumed(ci): nullable = 1
                else: bad = npi
            if bad >= 0:
                let shown = self.facade_param_display(fn_sym, sig, bad)
                self.emit_error(f"fn '{fname}': nullable {shown}; on a callback contract, nullability is rendered for the callback of a 'callback param N userdata param M' pairing that C uses during the call only — an absent callback takes its userdata with it — and a raw pointer parameter accepts null as C declares it (§16.2b.8, §16.2b.9)", node)
                continue
            // A retained callback runs on the registering thread unless the
            // facade says otherwise (§51); a consumed userdata's destroy
            // callback likewise. Nothing more is inferred.
            if self.diags.has_errors():
                continue
            // The net: the method was rendered (a generic template when the
            // userdata is typed, a signature otherwise).
            let host: str = self.pool_resolve(self.facade_resources[recv0[0]].name)
            let mname = self.facade_presented(recv0[0], fname)
            let mtext = host ++ "." ++ mname
            let msym = self.pool_lookup_symbol(mtext)
            let rendered = self.sig_text_index.contains(mtext) or (msym != 0 and self.generic_fn_node_for_symbol(msym) != 0)
            if not rendered:
                self.emit_error(f"fn '{fname}': its callback contract passed every facade check but no method '{mtext}' was rendered; the renderer cannot express this shape and did not say so — a compiler defect (§16.2b.9)", node)
                continue
            // Rendered indices (`self` excluded): the destroy callback the
            // contract names is withheld from the method — the compiler
            // supplies it.
            var ud_r = -1
            var cb_r = -1
            var r = 0
            let cb = self.facade_contract_callback_param(ci)
            for pi in 1..self.sig_get_param_count(sig):
                var withheld = false
                for k in 0..self.foreign_contracts[ci].consumes.len() as i32:
                    if self.foreign_contracts[ci].consumes_destroyed_by[k] == pi: withheld = true
                if withheld:
                    continue
                if pi == ud: ud_r = r
                if pi == cb: cb_r = r
                r = r + 1
            // Indexed by the generic template's node: the call-site hooks
            // hold the method's symbol under whichever spelling the method
            // table registered, and the node is one. A method with no typed
            // userdata is not generic and has nothing to check at a call.
            let mnode = if msym != 0: self.generic_fn_node_for_symbol(msym) else: 0
            if mnode != 0:
                self.facade_callback_method_index.insert(mnode, self.facade_callback_methods.len() as i32)
            self.facade_callback_methods.push(FacadeCallbackMethod { contract: ci, userdata_param: ud_r, callback_param: cb_r, thread_any: self.foreign_contracts[ci].callback_thread_any, retained: if self.facade_contract_userdata_retained(ci): 1 else: 0, consumed: if self.facade_contract_userdata_consumed(ci): 1 else: 0, nullable })

    // The callback method a symbol names, or -1.
    fn facade_callback_method_for(fn_sym: i32) -> i32:
        if self.facade_callback_methods.len() == 0 or fn_sym == 0:
            return -1
        let node = self.generic_fn_node_for_symbol(fn_sym)
        if node != 0 and self.facade_callback_method_index.contains(node): self.facade_callback_method_index.get(node).unwrap() else: -1

    // Stage 7's call effects for a callback method's concrete signature
    // (a generic method has none until a call specializes it): the call
    // touches the receiver's views unless the item preserves it (§38).
    mut fn facade_note_callback_method_sig(fn_sym: i32, sig: i32):
        let mi = self.facade_callback_method_for(fn_sym)
        if mi < 0 or sig < 0:
            return
        let ci = self.facade_callback_methods[mi].contract
        let c_fn = self.foreign_contracts[ci].fn_sym
        let domains = self.facade_domains_touched(self.facade_fn_file(c_fn), ci)
        self.facade_add_call_effect(sig, c_fn, ci, self.facade_touch_params_mask(c_fn, ci, 0), &domains, -1, -1)

    // §51 at a callback method's call: under `callback_thread any` the
    // userdata type is Send and Sync — the callback reads it from whatever
    // thread C calls on. `pi` is the rendered index (`self` excluded).
    mut fn facade_check_callback_arg(fn_sym: i32, pi: i32, actual_ty: i32, arg_node: i32):
        let mi = self.facade_callback_method_for(fn_sym)
        if mi < 0 or pi != self.facade_callback_methods[mi].userdata_param or self.facade_callback_methods[mi].thread_any == 0:
            return
        var ud_ty = self.resolve_alias(actual_ty as TypeId)
        if self.get_type_kind(ud_ty) == TypeKind.TY_REF:
            ud_ty = self.resolve_alias(self.get_type_d0(ud_ty) as TypeId)
        let send = self.type_is_send(ud_ty as i32) != 0
        let sync = self.type_is_sync(ud_ty as i32) != 0
        if send and sync:
            return
        let ci = self.facade_callback_methods[mi].contract
        let fname: str = self.pool_resolve(self.foreign_contracts[ci].fn_sym)
        let facade: str = self.pool_resolve(self.foreign_contracts[ci].facade)
        let tn: str = self.type_name(ud_ty as i32)
        let lacks = if not send and not sync: "neither Send nor Sync" else: if not send: "not Send" else: "not Sync"
        self.emit_error(f"'{fname}' may invoke its callback from any thread ('callback_thread any' in facade {facade}), so the userdata type must be Send and Sync; '{tn}' is {lacks} (§16.2b.10)", arg_node)

    // Whether a call argument spells an absent Option: the `None` variant.
    fn facade_arg_is_none(node: i32) -> bool:
        let kind = self.ast.kind(node)
        (kind == NodeKind.NK_VARIANT_SHORTHAND or kind == NodeKind.NK_IDENT) and self.ast.get_data0(node) == self.syms.none

    // The callback method a method call `recv.field(…)` names, or -1.
    fn facade_callback_method_for_call(recv_type: i32, field: i32) -> i32:
        if self.facade_callback_methods.len() == 0 or recv_type == 0 or field == 0:
            return -1
        let resolved = self.auto_deref_ref_ptr_type(self.resolve_alias(recv_type as TypeId))
        let owner = self.get_type_name(resolved)
        if owner == 0:
            return -1
        self.facade_callback_method_for(self.lookup_generic_method_fn(owner, field))

    // The expected type of a callback method's callback argument: the
    // rendered `extern "C" fn(&U, …)` with `U` bound to the userdata
    // argument's type (the value's type, whether passed as `U` or `&U`).
    // A closure argument takes its parameter types from it and must be
    // captureless, and a bare fn coerces to it (§12.4) — which the generic
    // call path, binding `U` from every argument at once, cannot give it.
    mut fn facade_callback_expected_type(mi: i32, recv_type: i32, field: i32, ud_ty: i32) -> i32:
        self.facade_callback_param_expected_type(mi, recv_type, field, ud_ty, self.facade_callback_methods[mi].callback_param)

    // The userdata type `U` a userdata argument's type binds: the value's
    // type, whether passed as `U`, `&U` or — a nullable callback's userdata
    // (#1618) — `Option[&U]`.
    fn facade_callback_userdata_type(ud_ty: i32) -> i32:
        var u_ty = self.resolve_alias(ud_ty as TypeId)
        if self.get_type_kind(u_ty) == TypeKind.TY_GENERIC_INST and self.get_generic_inst_arg_count(u_ty as i32) == 1 and self.pool_resolve(self.get_type_d0(u_ty)) == "Option":
            u_ty = self.resolve_alias(self.get_generic_inst_arg(u_ty as i32, 0) as TypeId)
        if self.get_type_kind(u_ty) == TypeKind.TY_REF:
            u_ty = self.resolve_alias(self.get_type_d0(u_ty) as TypeId)
        u_ty as i32

    // The rendered type of parameter `r` (rendered index, `self` excluded)
    // of a callback method, with `U` bound to `ud_ty`'s userdata type.
    mut fn facade_callback_param_expected_type(mi: i32, recv_type: i32, field: i32, ud_ty: i32, r: i32) -> i32:
        let resolved = self.auto_deref_ref_ptr_type(self.resolve_alias(recv_type as TypeId))
        let owner = self.get_type_name(resolved)
        let fn_sym = self.lookup_generic_method_fn(owner, field)
        let fn_node = self.generic_fn_node_for_symbol(fn_sym)
        if fn_node == 0:
            return 0
        let meta = self.ast.find_fn_meta(fn_node)
        if meta < 0 or self.ast.fn_meta_tp_count(meta) != 1:
            return 0
        let u_sym = self.ast.get_extra(self.ast.fn_meta_tp_start(meta))
        let u_ty = self.facade_callback_userdata_type(ud_ty)
        let param_start = self.ast.fn_meta_param_start(meta)
        if r < 0 or r + 1 >= self.ast.fn_meta_param_count(meta):
            return 0
        let p_type_node = self.ast.fn_param_type(param_start, r + 1)
        let saved_syms = sema_clone_i32_vec(&self.generic_subst_param_syms)
        let saved_tys = sema_clone_i32_vec(&self.generic_subst_type_ids)
        self.clear_generic_substitution()
        self.put_generic_subst(u_sym, u_ty as i32, fn_node)
        let expected = self.resolve_type_node_with_current_subst(p_type_node, resolved as i32)
        self.generic_subst_param_syms = saved_syms
        self.generic_subst_type_ids = saved_tys
        expected

    // The thread capabilities of the facade resource a struct symbol names
    // (§48: bit1 send, bit2 share, bit3 drop_any_thread), or -1 for a type
    // no facade declares.
    fn facade_thread_caps_for(type_sym: i32) -> i32:
        if type_sym == 0 or self.facade_resources.len() == 0 or not self.facade_resource_index.contains(type_sym):
            return -1
        let ri: i32 = self.facade_resource_index.get(type_sym).unwrap()
        self.facade_resources[ri].thread_caps

    // §8, §57: why a facade resource is not Send/Sync, and the clause.
    fn facade_thread_note(type_sym: i32, trait_name: &str) -> str:
        let ri: i32 = self.facade_resource_index.get(type_sym).unwrap()
        let rname: str = self.pool_resolve(self.facade_resources[ri].name)
        let facade: str = self.pool_resolve(self.facade_resources[ri].facade)
        let caps = self.facade_resources[ri].thread_caps
        let stated = if caps == 0: "the default, 'thread creator'" else: "its 'thread' clause"
        let fix = if trait_name == "Sync": "'thread share'" else: "'thread send drop_any_thread'"
        f"resource '{rname}' is bound to the thread that created it — {stated} in facade {facade}; state {fix} on the resource if the C API allows it (§16.2b.10)"

// The resource a deprecated `owns: ["ctor -> dtor"]` c_import entry spells
// (compiler/Frontend.w project_owned_annotations_frontend): the producer's
// name in UpperCamelCase — `getcwd` → `Getcwd`, `my_buf_new` → `MyBufNew`.
pub fn facade_owns_resource_name(ctor: &str) -> str:
    var out = ""
    var upper = true
    for i in 0..ctor.len() as i32:
        let c = ctor.slice(i, i + 1)
        if c == "_":
            upper = true
            continue
        let b = ctor[i]
        if upper and b >= 'a' and b <= 'z':
            let k = (b - 'a') as i32
            out = out ++ "ABCDEFGHIJKLMNOPQRSTUVWXYZ".slice(k, k + 1)
        else:
            out = out ++ c
        upper = false
    out
