// FacadeRender — D51 §16.2b stages 4-5: a `c facade` block's resources
// rendered as ordinary With (docs/modeled-c-implementation-plan.md).
//
// The Frontend calls facade_render_block after every source file and every
// `<c_import …>` translation is parsed and before Sema, and splices the text
// back in as a second synthetic file, `<facade NAME>`. Sema then sees a plain
// struct with a Drop impl, and collect_c_facades still verifies §61 against
// the same declarations, so a rendering that assumed something false is
// caught there — never silently.
//
// Per pointer or by-value resource `R wraps Repr` with drop `d`, destroyers
// `k…` and a direct-return producer `p`:
//
//     type R { repr: Repr, live: bool }
//     impl Drop for R:
//         move fn drop():
//             if self.live: unsafe { d(self.repr) }
//     impl R:
//         fn l(<args after the representation>) -> <ret>:      // a lend
//             unsafe { l(self.repr, <args>) }
//         move fn k(<args after the representation>) -> <ret>:
//             self.live = false
//             unsafe { k(self.repr, <args>) }
//     fn R.p(<args>) -> Option[R]:                           // one per `from`
//         let repr = unsafe { p(<args>) }
//         if repr == null: None else: Some(R { repr, live: true })
//
// (a by-value representation's producer yields `R` directly; `unsafe` only
// where the callee is raw).
//
// `live` is the Drop arming bit (ruling §13.2): a `move fn` destroyer consumes
// `self`, and With has no spelling that forgets a consumed value's Drop — a
// destroyer that read `self.repr` and let `self` drop destroyed twice (the
// counting test in behav_c_facade_resource_destroys_once.w) — so the
// destroyer clears the bit and Drop checks it, the way std.regex's Regex arms
// its pcre2 free. Stage 4b's in-place resources arm the same bit from `init`.
//
// The rendering is the safe surface of the representation; the C name stays
// raw (SemaFacade.w facade_covers_param: a safe `db_close(d.repr)` would
// destroy through C and let Drop destroy again, §16.2b.5). So each C call
// the rendering makes sits in an inner `unsafe {}` when the callee is raw
// (facade_render_call), and bare when it is not — an `unsafe` block around
// a call that needs none is itself an error. A `*const i8` parameter is presented as `str`:
// the c_import extern lends a `str` to a `const char *` (§16.3c, D47), and
// the resource's constructor passes the `str` straight through.
//
// An in-place resource (`init`) is pinned unless the facade says `movable`
// (spec §16.2b.3, D54): `repr` is a `Box[Repr]` cell the value owns, every
// pointer handed to C is `self.repr.as_mut_ptr()` (`.as_ptr()` for a const
// parameter), and R's own Drop runs the destroyer before the field's Drop
// frees the cell. A `movable` in-place resource, or a by-value token whose
// destroyer takes its address, is handed `&raw mut self.repr` over a
// by-value field. The `init` constructor is facade_render_init below.
//
// The three production forms (spec §16.2b.4, ruling §15): a direct return
// (above), a pointer out-parameter (facade_render_out_producer: NULL slot,
// call, inspect — `(status, Option[R])`), and in-place `init`
// (facade_render_init). With `ok CONST` a status-returning producer is
// projected onto `Result[R, <R>Error]` instead (facade_render_error_type).
// Constructors keep the C name (`Database.sqlite3_open`); presentation is
// §16.2b.11, the plan's stage 8.
//
// A producer that receives other resources produces a dependent resource
// (stage 6, spec §16.2b.6): the received resource is a borrow `&P` of the
// constructor, and the product is an ephemeral struct holding a view of each
// parent it depends on (facade_render_deps below):
//
//     type Statement = ephemeral { parent: &Database, repr: *mut st, live: bool }
//     fn Statement.db_prepare(d: &Database, sql: str) -> (c_int, Option[Statement]):
//         var slot: *mut st = null
//         let status = unsafe { db_prepare(d.repr, sql, &raw mut slot) }
//         (status, if slot == null: None else: Some(Statement { parent: d, repr: slot, live: true }))
//
// A dependent resource under `ok` (ruling §18: the error "may" own the
// failure-state resource "where required"): its `<R>Error` never owns the
// child, since an error escapes scopes and a dependent value cannot; a
// failure that still produced is destroyed in the constructor at once, and
// the error is `Failed | NothingProduced` (facade_render_out_producer).
// Nothing is ever rendered as a placeholder: a resource the renderer cannot
// express yields no text, the facade-level diagnostic names it, and Sema's
// verify_facade_resources reports a resource that passed every check without
// becoming a type, or a producer without its constructor.

use Ast
use InternPool
use render

// A pinned resource's cell is a `Box` (D54): Resolve makes the facade block
// that declares one this module's import of std.box (the D29 gate), since
// the rendering is spliced after resolution.
pub fn facade_render_block(pool: AstPool, intern: InternPool, facade: i32, ci: &Vec[i32]) -> str:
    var out = ""
    let extra_start = pool.get_data1(facade as NodeId)
    let count = pool.get_data2(facade as NodeId)
    for i in 0..count:
        let item = pool.get_extra(extra_start + i)
        if pool.kind(item as NodeId) == NodeKind.NK_FACADE_RESOURCE:
            out = out ++ facade_render_resource(pool, intern, ci, item, facade_render_lend_methods(pool, intern, ci, item, true), facade_render_lend_methods(pool, intern, ci, item, false))
    out

// A lend operation on a pointer resource, rendered as a `&self` method of the
// resource (§16.2b.5: "once a resource is modeled, its facade-exposed
// operations borrow it"; With proves the receiver live, unmoved and
// undestroyed, which it cannot prove of a raw pointer — so the C name stays
// raw, SemaFacade.w facade_covers_param). An fn item whose first parameter
// takes the representation of exactly one pointer resource of any block —
// or the one its `of` names (§16.2b.3) — and that states nothing stronger
// than a lend (`lend`, `of`, `rename`, `preserves`) becomes
//
//     impl R:
//         fn <name>(<args after the representation>) -> <ret>:
//             unsafe { <name>(self.repr, <args>) }
//
// under its C name, or its `rename`. Anything else stays as stated: a
// consuming, destroying or retaining item is not a lend, and an in-place or
// by-value representation is not reached through a pointer here.
fn facade_render_lend_methods(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32, with_borrowed_returns: bool) -> str:
    let rname: str = intern.resolve(pool.get_data0(resource as NodeId))
    let repr = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.get_extra(pool.get_data1(resource as NodeId)) as NodeId))
    if not repr.starts_with("*"):
        return ""
    var out = ""
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        let item = items[i]
        var of_sym = 0
        var rename = 0
        var lends = true
        var borrow_res = 0
        var borrow_from = 0
        let cstart = pool.get_data1(item as NodeId)
        for k in 0..pool.get_data2(item as NodeId):
            let clause = pool.get_extra(cstart + k)
            let kind = pool.get_data0(clause as NodeId)
            let ops = pool.get_data1(clause as NodeId)
            if kind == FACADE_CLAUSE_OF: of_sym = pool.get_extra(ops)
            else if kind == FACADE_CLAUSE_RENAME: rename = pool.get_extra(ops)
            else if kind == FACADE_CLAUSE_RETURNS_BORROW:
                borrow_res = pool.get_extra(ops)
                borrow_from = pool.get_extra(ops + 1)
            else if kind != FACADE_CLAUSE_LEND and kind != FACADE_CLAUSE_PRESERVES: lends = false
        if not lends:
            continue
        let decl = facade_render_find_fn(pool, intern, ci, pool.get_data0(item as NodeId))
        if decl == 0 or facade_render_param_count(pool, decl) == 0:
            continue
        let meta = pool.find_fn_meta(decl as NodeId)
        let p0 = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(pool.fn_meta_param_start(meta), 0) as NodeId))
        if p0 != repr:
            continue
        if of_sym != 0:
            let of_name: str = intern.resolve(of_sym)
            if of_name != rname:
                continue
        else if facade_render_resources_wrapping(pool, intern, repr) != 1:
            continue
        let fname: str = intern.resolve(pool.get_data0(decl as NodeId))
        var mname: str = fname.clone()
        if rename != 0:
            mname = intern.resolve(rename)
        let (params, args) = facade_render_params(pool, intern, decl, 1)
        let call_args = if args.len() > 0: "self.repr, " ++ args else: "self.repr"
        if borrow_res != 0:
            if not with_borrowed_returns:
                continue
            // `returns borrow R from param N` (ruling §26): the result is a
            // `Borrowed<R>` — no Drop, dependent on the parameter named —
            // and, unknown nullability being nullable (§16.2b.8), an Option
            // of it (facade_render_borrowed_type).
            let from = facade_render_param_ref(pool, intern, decl, borrow_from)
            if from < 0:
                continue
            let origin = if from == 0: "self" else: facade_render_param_name(pool, intern, pool.fn_meta_param_start(meta), from)
            let bname = facade_render_borrowed_name(intern.resolve(borrow_res))
            let handle = facade_render_fresh("repr", facade_render_param_names(pool, intern, decl))
            out = out ++ "    fn " ++ mname ++ "(" ++ params ++ ") -> Option[" ++ bname ++ "]:\n        let " ++ handle ++ " = " ++ facade_render_call(pool, intern, decl, call_args) ++ "\n        if " ++ handle ++ " == null: None else: Some(" ++ bname ++ " { origin: " ++ origin ++ ", repr: " ++ handle ++ " })\n"
            continue
        out = out ++ "    fn " ++ mname ++ "(" ++ params ++ ")" ++ facade_render_return(pool, intern, decl) ++ ":\n        " ++ facade_render_call(pool, intern, decl, call_args) ++ "\n"
    out

// The borrowed value a `returns borrow R from param N` operation yields
// (ruling §26, spec §16.2b.6): "no Drop; cannot outlive the named origin;
// cannot independently be consumed or destroyed". It is the distinct type
// `Borrowed<R>` (D59's precedent: a resource state with its own surface is
// its own type), ephemeral and holding a view of the origin resource — the
// one the operation's param N receives — so the ordinary origin analysis
// keeps it inside the origin's life; it carries R's lend methods (the
// non-destroying, non-consuming ones) over the same `repr` field, and none
// of R's destroyers or Drop:
//
//     type BorrowedDatabase = ephemeral { origin: &Statement, repr: *mut sqlite3 }
//     impl BorrowedDatabase:
//         fn sqlite3_errmsg() -> *const i8:
//             unsafe { sqlite3_errmsg(self.repr) }
//
// Rendered beside `R`, once, with the origin resource of the first item that
// borrows R; Sema refuses a second item borrowing R from another resource
// (one borrowed type, one origin type). "" when no item borrows R.
fn facade_render_borrowed_type(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32, repr_text: &str, methods: &str) -> str:
    let rname: str = intern.resolve(pool.get_data0(resource as NodeId))
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        let item = items[i]
        let cstart = pool.get_data1(item as NodeId)
        for k in 0..pool.get_data2(item as NodeId):
            let clause = pool.get_extra(cstart + k)
            if pool.get_data0(clause as NodeId) != FACADE_CLAUSE_RETURNS_BORROW:
                continue
            let ops = pool.get_data1(clause as NodeId)
            let res_name: str = intern.resolve(pool.get_extra(ops))
            if res_name != rname:
                continue
            let decl = facade_render_find_fn(pool, intern, ci, pool.get_data0(item as NodeId))
            if decl == 0:
                continue
            let from = facade_render_param_ref(pool, intern, decl, pool.get_extra(ops + 1))
            let meta = pool.find_fn_meta(decl as NodeId)
            if from < 0 or meta < 0:
                continue
            let origin = facade_render_received(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(pool.fn_meta_param_start(meta), from) as NodeId))
            if origin <= 0:
                continue
            let oname: str = intern.resolve(pool.get_data0(origin as NodeId))
            let bname = facade_render_borrowed_name(rname)
            var out = "type " ++ bname ++ " = ephemeral { origin: &" ++ oname ++ ", repr: " ++ repr_text ++ " }\n"
            if methods.len() > 0:
                out = out ++ "impl " ++ bname ++ ":\n" ++ methods
            return out
    ""

pub fn facade_render_borrowed_name(name: &str) -> str: "Borrowed" ++ name

fn facade_render_resources_wrapping(pool: AstPool, intern: InternPool, repr: &str) -> i32:
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_RESOURCE)
    var n = 0
    for i in 0..items.len() as i32:
        let r = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.get_extra(pool.get_data1(items[i] as NodeId)) as NodeId))
        if r == repr: n = n + 1
    n

// Every item of `kind` in every facade block of the compilation: a program's
// facade may describe an operation of a resource another block declares
// (its own `fn telldir` lending the toolchain libc facade's `CDir`).
fn facade_render_all_items(pool: AstPool, kind: NodeKind) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_C_FACADE:
            continue
        let extra_start = pool.get_data1(decl)
        for i in 0..pool.get_data2(decl):
            let item = pool.get_extra(extra_start + i)
            if pool.kind(item as NodeId) == kind:
                out.push(item)
    out

fn facade_render_resource(pool: AstPool, intern: InternPool, ci: &Vec[i32], item: i32, methods: &str, plain_methods: &str) -> str:
    let name: str = intern.resolve(pool.get_data0(item as NodeId))
    let extra_start = pool.get_data1(item as NodeId)
    let clause_count = pool.get_data2(item as NodeId)
    let repr_text = render_type_expr(pool, intern, pool.get_extra(extra_start) as NodeId)
    let producers: Vec[i32] = Vec.new()
    let out_refs: Vec[i32] = Vec.new()   // parallel to producers; 0 for a direct return
    // Each `borrows` clause names a parameter of the producer stated before
    // it (a `from`, or the `init`: FACADE_DEP_INIT).
    let borrow_refs: Vec[i32] = Vec.new()
    let borrow_owners: Vec[i32] = Vec.new()
    var last_producer = -2
    var independent = false
    var drop_fn = 0
    var init_fn = 0
    var preinit_fn = 0
    var ok_sym = 0
    var movable = false
    let destroyers: Vec[i32] = Vec.new()
    for k in 0..clause_count:
        let clause = pool.get_extra(extra_start + 1 + k)
        let kind = pool.get_data0(clause as NodeId)
        let ops = pool.get_data1(clause as NodeId)
        if kind == FACADE_CLAUSE_FROM:
            producers.push(facade_render_find_fn(pool, intern, ci, pool.get_extra(ops)))
            out_refs.push(pool.get_extra(ops + 1))
            last_producer = producers.len() as i32 - 1
        else if kind == FACADE_CLAUSE_BORROWS:
            borrow_refs.push(pool.get_extra(ops))
            borrow_owners.push(last_producer)
        else if kind == FACADE_CLAUSE_INDEPENDENT:
            independent = true
        else if kind == FACADE_CLAUSE_INIT:
            init_fn = facade_render_find_fn(pool, intern, ci, pool.get_extra(ops))
            last_producer = FACADE_DEP_INIT
        else if kind == FACADE_CLAUSE_PREINIT:
            preinit_fn = facade_render_find_fn(pool, intern, ci, pool.get_extra(ops))
        else if kind == FACADE_CLAUSE_OK:
            ok_sym = pool.get_extra(ops)
        else if kind == FACADE_CLAUSE_MOVABLE:
            movable = true
        else if kind == FACADE_CLAUSE_DROP:
            drop_fn = facade_render_find_fn(pool, intern, ci, pool.get_extra(ops))
        else if kind == FACADE_CLAUSE_DESTROYS:
            destroyers.push(facade_render_find_fn(pool, intern, ci, pool.get_extra(ops)))
    // An in-place resource is pinned unless the facade says `movable` (D54):
    // its representation lives in a Box cell the value owns, so the value
    // moves and the address does not.
    let pinned = init_fn != 0 and not movable
    // A name that is not a declaration, a resource with no `drop` (a
    // producer with nothing to destroy it; `destroys` operations alone would
    // leak a value dropped while live), a destroyer that takes neither the
    // representation nor a pointer to it: Sema's facade diagnostics name the
    // resource; nothing is rendered.
    if drop_fn == 0:
        return ""
    for di in 0..destroyers.len() as i32:
        if destroyers[di] == 0 or facade_render_repr_arg(pool, intern, destroyers[di], repr_text, "self.repr", pinned).len() == 0:
            return ""
    if drop_fn != 0 and (facade_render_param_count(pool, drop_fn) != 1 or facade_render_repr_arg(pool, intern, drop_fn, repr_text, "self.repr", pinned).len() == 0):
        return ""
    // Stage 6 (spec §16.2b.6, ruling §26-§30): what each producer's result
    // depends on. A producer whose received resources the renderer cannot
    // hand to C, or whose parent no one resource wraps, renders nothing;
    // Sema names it.
    let deps = facade_render_deps(pool, intern, producers, out_refs, init_fn, preinit_fn, &borrow_refs, &borrow_owners, independent)
    if not deps.ok:
        return ""
    let field = if pinned: "Box[" ++ repr_text ++ "]" else: repr_text.clone()
    // A dependent resource is an ephemeral struct carrying a view of each
    // parent (the plan's `ephemeral { parent: &P, repr }`): the ordinary
    // origin and ephemeral-value analysis (§21.1, §22) then keeps it from
    // outliving, or being stored past, what it depends on, drops it before
    // its parents, and refuses a parent's move or destruction while it lives.
    // No reference count or generation check is added (ruling §29).
    var out = if deps.slot_res.len() > 0: "type " ++ name ++ " = ephemeral { " ++ facade_render_dep_fields(pool, intern, &deps) ++ "repr: " ++ field ++ ", live: bool }\n" else: "type " ++ name ++ " { repr: " ++ field ++ ", live: bool }\n"
    if drop_fn != 0:
        out = out ++ "impl Drop for " ++ name ++ ":\n    move fn drop():\n        if self.live: " ++ facade_render_call(pool, intern, drop_fn, facade_render_repr_arg(pool, intern, drop_fn, repr_text, "self.repr", pinned)) ++ "\n"
    if destroyers.len() > 0 or methods.len() > 0:
        out = out ++ "impl " ++ name ++ ":\n" ++ methods
        for di in 0..destroyers.len() as i32:
            let d = destroyers[di]
            let dname: str = intern.resolve(pool.get_data0(d as NodeId))
            let (params, args) = facade_render_params(pool, intern, d, 1)
            let repr_arg = facade_render_repr_arg(pool, intern, d, repr_text, "self.repr", pinned)
            let call_args = if args.len() > 0: repr_arg ++ ", " ++ args else: repr_arg
            out = out ++ "    move fn " ++ dname ++ "(" ++ params ++ ")" ++ facade_render_return(pool, intern, d) ++ ":\n        self.live = false\n        " ++ facade_render_call(pool, intern, d, call_args) ++ "\n"
    // `ok CONST` projects every status-returning producer — an out-parameter
    // producer or the in-place `init` — onto `Result[R, <R>Error]`
    // (facade_render_error_type); only out-parameter production can still
    // produce on failure, so only it adds the failed-state resource.
    var status_type = ""
    var failed_state = false
    if ok_sym != 0:
        for pi in 0..producers.len() as i32:
            let ret = if producers[pi] != 0 and out_refs[pi] != 0: facade_render_return(pool, intern, producers[pi]) else: ""
            if ret.len() > 0:
                failed_state = true
                if status_type.len() == 0:
                    status_type = ret.slice(4, ret.len())
        if init_fn != 0:
            let ret = facade_render_return(pool, intern, init_fn)
            if ret.len() > 0:
                status_type = ret.slice(4, ret.len())
    // The generated error never owns a dependent child (ruling §18: the
    // error "may" own the failure-state resource "where required" — an
    // error escapes scopes, a dependent value cannot). A dependent
    // resource's failure that still produced is destroyed at once in the
    // constructor (facade_render_out_producer) and its error carries no
    // `FailedWithResource`.
    let dependent = deps.slot_res.len() > 0
    if status_type.len() > 0:
        out = out ++ facade_render_error_type(pool, intern, name, repr_text, status_type, failed_state, failed_state and not dependent, drop_fn)
    // Borrowed returns of this resource (ruling §26): `Borrowed<R>`.
    out = out ++ facade_render_borrowed_type(pool, intern, ci, item, repr_text, plain_methods)
    for pi in 0..producers.len() as i32:
        let producer = producers[pi]
        if producer == 0:
            continue
        let pname: str = intern.resolve(pool.get_data0(producer as NodeId))
        let made_deps = facade_render_dep_values(pool, intern, &deps, pi, producer)
        if out_refs[pi] != 0:
            let slot = facade_render_param_ref(pool, intern, producer, out_refs[pi])
            if slot < 0:
                continue
            out = out ++ facade_render_out_producer(pool, intern, name, repr_text, producer, slot, ok_sym, made_deps, drop_fn)
            continue
        let (params, args) = facade_render_params_but(pool, intern, producer, 0, -1, "")
        let call = facade_render_call(pool, intern, producer, args)
        if facade_render_unalias(pool, intern, repr_text).starts_with("*"):
            // Unknown nullability is nullable, never silently non-null
            // (§16.2b.8): a pointer producer yields `Option[R]`, and a NULL
            // produced nothing — no Drop is armed over it (§16.2b.4). The
            // facade's `from` is the trusted evidence that a non-null return
            // is the produced resource (§16.2b.4, ruling §19).
            let repr = facade_render_fresh("repr", facade_render_param_names(pool, intern, producer))
            out = out ++ "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ") -> Option[" ++ name ++ "]:\n    let " ++ repr ++ " = " ++ call ++ "\n    if " ++ repr ++ " == null: None else: Some(" ++ name ++ " { " ++ made_deps ++ "repr: " ++ repr ++ ", live: true })\n"
        else:
            out = out ++ "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ") -> " ++ name ++ ":\n    " ++ name ++ " { " ++ made_deps ++ "repr: " ++ call ++ ", live: true }\n"
    if init_fn != 0:
        let ctor = facade_render_init(pool, intern, name, repr_text, init_fn, preinit_fn, ok_sym, pinned, facade_render_dep_values(pool, intern, &deps, FACADE_DEP_INIT, init_fn))
        if ctor.len() == 0:
            return ""
        out = out ++ ctor
    out

// ── stage 6: dependency (ruling §26-§30, spec §16.2b.6) ─────────────────
//
// A producer that receives modeled resources produces a resource dependent
// on them unless the facade states otherwise (§16.2b.6: "unknown
// independence means dependency"): `independent` says the resource depends
// on nothing it was made from, and `borrows param N` names exactly the
// parameters a producer's result depends on (the producer stated before the
// clause, a `from` or the `init`). Every received resource — a parent or
// not — is presented to the constructor as a borrow `&P` of the resource
// that wraps its representation, and handed to C as `p.repr`; the raw
// representation is never a constructor parameter. SemaFacade.w
// facade_producer_parents makes the same classification from the
// signatures; the two agree, or Sema's net (verify_facade_dependency_shape)
// is loud.

// The owner index of the in-place `init` among a resource's producers (a
// `from` is its index).
pub const FACADE_DEP_INIT: i32 = -1

// A resource's parents: one entry per (owner, parameter) the owner's result
// depends on, with the resource item wrapping that parameter's
// representation and the parent slot it fills; the slots are the view
// fields the rendered type carries, one per parent a producer can have (a
// resource type with two producers depending on two Databases carries two).
type FacadeDeps {
    ok: bool,
    owners: Vec[i32],
    params: Vec[i32],
    resources: Vec[i32],
    slots: Vec[i32],
    slot_res: Vec[i32],
    slot_optional: Vec[bool],
}

fn facade_render_deps(pool: AstPool, intern: InternPool, producers: &Vec[i32], out_refs: &Vec[i32], init_fn: i32, preinit_fn: i32, borrow_refs: &Vec[i32], borrow_owners: &Vec[i32], independent: bool) -> FacadeDeps:
    var deps = FacadeDeps { ok: true, owners: Vec.new(), params: Vec.new(), resources: Vec.new(), slots: Vec.new(), slot_res: Vec.new(), slot_optional: Vec.new() }
    // Every owner: each `from`, then the `init`.
    let owners: Vec[i32] = Vec.new()
    let decls: Vec[i32] = Vec.new()
    let firsts: Vec[i32] = Vec.new()
    let skips: Vec[i32] = Vec.new()
    for pi in 0..producers.len() as i32:
        if producers[pi] == 0:
            continue
        owners.push(pi)
        decls.push(producers[pi])
        firsts.push(0)
        skips.push(if out_refs[pi] != 0: facade_render_param_ref(pool, intern, producers[pi], out_refs[pi]) else: -1)
    if init_fn != 0:
        owners.push(FACADE_DEP_INIT)
        decls.push(init_fn)
        firsts.push(1)
        skips.push(-1)
        // A resource the in-place resource depends on is received by its
        // `init`; preinit only constructs storage (Sema names a preinit that
        // receives one).
        if preinit_fn != 0 and facade_render_receives_any(pool, intern, preinit_fn, 0, -1):
            deps.ok = false
            return deps
    for oi in 0..owners.len() as i32:
        let owner = owners[oi]
        let decl = decls[oi]
        let meta = pool.find_fn_meta(decl as NodeId)
        if meta < 0:
            continue
        let start = pool.fn_meta_param_start(meta)
        // Every received resource must be presentable, parent or not.
        for pi in firsts[oi]..pool.fn_meta_param_count(meta):
            if pi == skips[oi]:
                continue
            let ptext = render_type_expr(pool, intern, pool.fn_param_type(start, pi) as NodeId)
            let res = facade_render_received(pool, intern, ptext)
            if res < 0 or (res > 0 and facade_render_received_arg(pool, intern, res, ptext, "p").len() == 0):
                deps.ok = false
                return deps
        if independent:
            continue
        var stated = false
        for bi in 0..borrow_refs.len() as i32:
            if borrow_owners[bi] != owner:
                continue
            stated = true
            let pi = facade_render_param_ref(pool, intern, decl, borrow_refs[bi])
            let res = if pi >= 0: facade_render_received(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(start, pi) as NodeId)) else: 0
            if res <= 0:
                deps.ok = false
                return deps
            deps.owners.push(owner)
            deps.params.push(pi)
            deps.resources.push(res)
        if stated:
            continue
        for pi in firsts[oi]..pool.fn_meta_param_count(meta):
            if pi == skips[oi]:
                continue
            let res = facade_render_received(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(start, pi) as NodeId))
            if res > 0:
                deps.owners.push(owner)
                deps.params.push(pi)
                deps.resources.push(res)
    // Slots: the k-th parent of resource P an owner has fills the k-th slot
    // of P; a slot some owner leaves empty is optional.
    for di in 0..deps.owners.len() as i32:
        var seen = 0
        for dj in 0..di:
            if deps.owners[dj] == deps.owners[di] and deps.resources[dj] == deps.resources[di]:
                seen = seen + 1
        var slot = -1
        var k = 0
        for si in 0..deps.slot_res.len() as i32:
            if deps.slot_res[si] == deps.resources[di]:
                if k == seen:
                    slot = si
                    break
                k = k + 1
        if slot < 0:
            slot = deps.slot_res.len() as i32
            deps.slot_res.push(deps.resources[di])
            deps.slot_optional.push(false)
        deps.slots.push(slot)
    for si in 0..deps.slot_res.len() as i32:
        for oi in 0..owners.len() as i32:
            var filled = false
            for di in 0..deps.owners.len() as i32:
                if deps.owners[di] == owners[oi] and deps.slots[di] == si:
                    filled = true
            if not filled:
                deps.slot_optional[si] = true
    deps

// A parent slot's field: `parent` when the type carries one, else
// `parent_<k>`.
fn facade_render_slot_field(deps: &FacadeDeps, si: i32) -> str: if deps.slot_res.len() == 1: "parent" else: f"parent_{si}"

// `parent: &Database, ` — each slot a view of its parent, `Option` when
// some producer has no parent to put there.
fn facade_render_dep_fields(pool: AstPool, intern: InternPool, deps: &FacadeDeps) -> str:
    var out = ""
    for si in 0..deps.slot_res.len() as i32:
        let pname: str = intern.resolve(pool.get_data0(deps.slot_res[si] as NodeId))
        let optional: bool = deps.slot_optional[si]
        let ty = if optional: "Option[&" ++ pname ++ "]" else: "&" ++ pname
        out = out ++ facade_render_slot_field(deps, si) ++ ": " ++ ty ++ ", "
    out

// `parent: db, ` — what owner `owner` puts in each slot: the parameter that
// received the parent (a `&P` in the constructor), or `None`.
fn facade_render_dep_values(pool: AstPool, intern: InternPool, deps: &FacadeDeps, owner: i32, decl: i32) -> str:
    var out = ""
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0:
        return out
    let start = pool.fn_meta_param_start(meta)
    for si in 0..deps.slot_res.len() as i32:
        var value = "None"
        for di in 0..deps.owners.len() as i32:
            if deps.owners[di] == owner and deps.slots[di] == si:
                let pname = facade_render_param_name(pool, intern, start, deps.params[di])
                let optional: bool = deps.slot_optional[si]
                value = if optional: "Some(" ++ pname ++ ")" else: pname
        out = out ++ facade_render_slot_field(deps, si) ++ ": " ++ value ++ ", "
    out

// The resource whose representation a parameter of type `ptext` receives:
// a pointer resource's handle, or an in-place resource's storage by address
// (or by value — never presentable while pinned), or — never presentable —
// a pointer to a pointer resource's handle. A by-value token is not
// recognized by its type: `int` is an `Fd` and every other integer alike, so
// a parameter of that type is not taken to be the resource (Sema's
// facade_param_takes_resource draws the same line). 0 when none; -1 when
// several resources wrap it, since the facade has not assigned it
// (§16.2b.3, Sema names the candidates).
fn facade_render_received(pool: AstPool, intern: InternPool, ptext: &str) -> i32:
    let p = facade_render_unalias(pool, intern, ptext)
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_RESOURCE)
    var found = 0
    for i in 0..items.len() as i32:
        let res = items[i]
        let repr = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.get_extra(pool.get_data1(res as NodeId)) as NodeId))
        if not repr.starts_with("*") and not facade_render_has_clause(pool, res, FACADE_CLAUSE_INIT):
            continue
        if p == repr or p == "*mut " ++ repr or p == "*const " ++ repr:
            if found != 0:
                return -1
            found = res
    found

fn facade_render_receives_any(pool: AstPool, intern: InternPool, decl: i32, first: i32, skip: i32) -> bool:
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0:
        return false
    let start = pool.fn_meta_param_start(meta)
    for pi in first..pool.fn_meta_param_count(meta):
        if pi != skip and facade_render_received(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(start, pi) as NodeId)) != 0:
            return true
    false

// How a constructor hands the received resource `place` (a `&P`) to a C
// parameter of type `ptext`: `place.repr` for the representation itself,
// the cell's address for a pinned in-place resource, `&raw const
// place.repr` for a movable one read through a const pointer. "" for a
// shape a borrow cannot present — a pointer to a pointer resource's handle
// (C could replace it), a pinned representation by value (a copy of storage
// whose address the library may keep), a movable one through `*mut` (a
// write through a shared borrow): Sema names it.
fn facade_render_received_arg(pool: AstPool, intern: InternPool, res: i32, ptext: &str, place: &str) -> str:
    let p = facade_render_unalias(pool, intern, ptext)
    let repr = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.get_extra(pool.get_data1(res as NodeId)) as NodeId))
    let in_place = facade_render_has_clause(pool, res, FACADE_CLAUSE_INIT)
    let pinned = in_place and not facade_render_has_clause(pool, res, FACADE_CLAUSE_MOVABLE)
    if p == repr:
        return if pinned: "" else: place ++ ".repr"
    if repr.starts_with("*"):
        return ""
    if pinned:
        return if p.starts_with("*mut "): place ++ ".repr.as_mut_ptr()" else: place ++ ".repr.as_ptr()"
    if p.starts_with("*const "):
        return "&raw const " ++ place ++ ".repr"
    ""

// The in-place constructor (ruling §13, spec §16.2b.4): storage first — the
// representation's ordinary zeroed construction `Repr {}` (every field of an
// imported struct carries its zero default; ruling §67 consumes that rule)
// or the `preinit` operation's result — then the C initializer over a
// pointer to it. A void init yields `R`. A status-returning init without
// `ok` yields `(status, R)`: the status is uninterpreted (§16.2b.4), the
// facade's `init` is the production evidence, and the status is handed back
// unread.
//
// With `ok CONST` the result is the Result projection (Eric, 2026-09-23, on
// #1426), `Result[R, <R>Error]`, where `<R>Error` has the one variant
// `Failed(status)` (a failed init produced nothing — §16.2b.3: "Drop is armed
// only when initialization establishes production"). A failed init returns
// `Err` before the storage becomes an `R`, so no `R` — armed or not — ever
// holds storage C did not initialize, and no destroyer can reach it. The
// storage is then dropped as ordinary With storage: for a pinned resource
// that is the one path on which the Box cell is freed with no destruction
// call, because nothing was produced to destroy (ruling §13.2: "the foreign
// destructor does not run … ordinary With storage cleanup still occurs").
//
// Pinned (the default, D54): the storage is a Box cell the value owns, so
// the cell exists — with its one address — from the construction of R,
// before `live`; every pointer handed to C points into it; and on drop the
// destruction operation runs in R's own Drop before the field's Drop frees
// the cell (the cell outlives the C state, never the reverse).
//
//     fn R.init(<preinit args>, <init args after self>) -> Result[R, RError]:
//         var repr = Box.new(Repr {})                     // or Box.new(preinit(<preinit args>))
//         let status = init(repr.as_mut_ptr(), <args>)
//         if status != OK: return Err(RError.Failed(status))   // the cell is freed; no destroyer
//         Ok(R { repr: repr, live: true })
//
// `movable`: the same over a by-value field — `var repr = Repr {}` and
// `init(&raw mut repr, <args>)`.
//
// The constructor is named after the C initializer (`Stream.inflateInit`):
// presentation — `Stream.init`, prefix shortening, `rename` — is §16.2b.11,
// the plan's stage 8; the C name is not the final spelling.
fn facade_render_init(pool: AstPool, intern: InternPool, name: &str, repr_text: &str, init_fn: i32, preinit_fn: i32, ok_sym: i32, pinned: bool, deps: &str) -> str:
    let iname: str = intern.resolve(pool.get_data0(init_fn as NodeId))
    // The storage and status locals are spelled apart from every parameter
    // the constructor takes (preinit's, then init's).
    var taken = facade_render_param_names(pool, intern, init_fn)
    if preinit_fn != 0:
        taken = taken ++ ", " ++ facade_render_param_names(pool, intern, preinit_fn)
    let repr = facade_render_fresh("repr", taken)
    let status = facade_render_fresh("status", taken)
    let storage_arg = facade_render_repr_arg(pool, intern, init_fn, repr_text, repr, pinned)
    if storage_arg.len() == 0 or storage_arg == repr:
        return ""
    let (iparams, iargs) = facade_render_params(pool, intern, init_fn, 1)
    var params = iparams
    var storage = repr_text ++ " {}"
    if preinit_fn != 0:
        let (pparams, pargs) = facade_render_params(pool, intern, preinit_fn, 0)
        if pparams.len() > 0:
            params = if params.len() > 0: pparams ++ ", " ++ params else: pparams
        storage = facade_render_call(pool, intern, preinit_fn, pargs)
    if pinned: storage = "Box.new(" ++ storage ++ ")"
    let ret = facade_render_return(pool, intern, init_fn)
    let call_args = if iargs.len() > 0: storage_arg ++ ", " ++ iargs else: storage_arg
    let call = facade_render_call(pool, intern, init_fn, call_args)
    let out = "fn " ++ name ++ "." ++ iname ++ "(" ++ params ++ ")"
    let made = name ++ " { " ++ deps ++ "repr: " ++ repr ++ ", live: true }"
    if ret.len() == 0:
        if ok_sym != 0:
            return ""
        return out ++ " -> " ++ name ++ ":\n    var " ++ repr ++ " = " ++ storage ++ "\n    " ++ call ++ "\n    " ++ made ++ "\n"
    if ok_sym == 0:
        return out ++ " -> (" ++ ret.slice(4, ret.len()) ++ ", " ++ name ++ "):\n    var " ++ repr ++ " = " ++ storage ++ "\n    let " ++ status ++ " = " ++ call ++ "\n    (" ++ status ++ ", " ++ made ++ ")\n"
    let err = facade_render_error_name(name)
    out ++ " -> Result[" ++ name ++ ", " ++ err ++ "]:\n    var " ++ repr ++ " = " ++ storage ++ "\n    let " ++ status ++ " = " ++ call ++ "\n    if " ++ status ++ " != " ++ intern.resolve(ok_sym) ++ ": return Err(" ++ err ++ ".Failed(" ++ status ++ "))\n    Ok(" ++ made ++ ")\n"

// An out-parameter producer's constructor (ruling §16, spec §16.2b.4). The
// physical commitment: initialize the slot to NULL, call, inspect the slot —
// non-null is a produced resource whose ownership begins at once, null is
// none. That is production, not success. With no status convention the
// status is uninterpreted and handed back unread beside it, so a failed call
// that still produced (a failed `sqlite3_open` hands back a handle that must
// be closed, ruling §18) yields `Some(R)`, whose Drop runs the destroyer
// exactly once:
//
//     fn R.p(<params but the slot>) -> (S, Option[R]):
//         var slot: Repr = null
//         let status = unsafe { p(<args>, &raw mut slot, <args>) }
//         (status, if slot == null: None else: Some(R { repr: slot, live: true }))
//
// With `ok CONST` the result is the Result projection instead (Eric,
// 2026-09-23, on #1426) — one call surface per production form, and the
// low-level pair is not rendered beside it. Every combination of status and
// slot stays distinct:
//
//     fn R.p(<params but the slot>) -> Result[R, RError]:
//         var slot: Repr = null
//         let status = unsafe { p(<args>, &raw mut slot, <args>) }
//         if status != OK:
//             if slot == null: return Err(RError.Failed(status))
//             return Err(RError.FailedWithResource(status, FailedR { repr: slot }))
//         if slot == null: return Err(RError.NothingProduced(status))
//         Ok(R { repr: slot, live: true })
//
// "Status OK, nothing produced" violates the C contract the facade states
// (`ok` says what success is; a success that produced nothing is not one it
// can hand back as an `R`), and it is its own variant: `Failed` with an OK
// status would read as a contradiction. A failure that produced is owned by
// the error (FailedWithResource), whose Drop destroys it exactly once.
//
// A producer returning nothing yields `Option[R]`. The locals are spelled
// apart from the parameters (facade_render_fresh). The constructor keeps the
// C name (`Database.sqlite3_open`): presentation — `Database.open`, prefix
// shortening, `rename` — is §16.2b.11, the plan's stage 8, so the C name is
// not the final spelling.
fn facade_render_out_producer(pool: AstPool, intern: InternPool, name: &str, repr_text: &str, producer: i32, slot: i32, ok_sym: i32, deps: &str, drop_fn: i32) -> str:
    let pname: str = intern.resolve(pool.get_data0(producer as NodeId))
    let taken = facade_render_param_names(pool, intern, producer)
    let slot_var = facade_render_fresh("slot", taken)
    let (params, args) = facade_render_params_but(pool, intern, producer, 0, slot, "&raw mut " ++ slot_var)
    let call = facade_render_call(pool, intern, producer, args)
    let made = name ++ " { " ++ deps ++ "repr: " ++ slot_var ++ ", live: true }"
    let head = "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ")"
    let null_slot = "    var " ++ slot_var ++ ": " ++ repr_text ++ " = null\n"
    let ret = facade_render_return(pool, intern, producer)
    if ret.len() == 0:
        return head ++ " -> Option[" ++ name ++ "]:\n" ++ null_slot ++ "    " ++ call ++ "\n    if " ++ slot_var ++ " == null: None else: Some(" ++ made ++ ")\n"
    let status = facade_render_fresh("status", taken)
    if ok_sym == 0:
        return head ++ " -> (" ++ ret.slice(4, ret.len()) ++ ", Option[" ++ name ++ "]):\n" ++ null_slot ++ "    let " ++ status ++ " = " ++ call ++ "\n    (" ++ status ++ ", if " ++ slot_var ++ " == null: None else: Some(" ++ made ++ "))\n"
    let err = facade_render_error_name(name)
    var out = head ++ " -> Result[" ++ name ++ ", " ++ err ++ "]:\n" ++ null_slot ++ "    let " ++ status ++ " = " ++ call ++ "\n"
    out = out ++ "    if " ++ status ++ " != " ++ intern.resolve(ok_sym) ++ ":\n"
    out = out ++ "        if " ++ slot_var ++ " == null: return Err(" ++ err ++ ".Failed(" ++ status ++ "))\n"
    if deps.len() > 0:
        // A dependent resource: the generated error never owns a child
        // (see facade_render_error_type), so a failure that still produced
        // is destroyed here, exactly once, and reported as `Failed`.
        out = out ++ "        " ++ facade_render_call(pool, intern, drop_fn, facade_render_repr_arg(pool, intern, drop_fn, repr_text, slot_var, false)) ++ "\n        return Err(" ++ err ++ ".Failed(" ++ status ++ "))\n"
    else:
        out = out ++ "        return Err(" ++ err ++ ".FailedWithResource(" ++ status ++ ", " ++ facade_render_failed_name(name) ++ " { repr: " ++ slot_var ++ " }))\n"
    out = out ++ "    if " ++ slot_var ++ " == null: return Err(" ++ err ++ ".NothingProduced(" ++ status ++ "))\n"
    out ++ "    Ok(" ++ made ++ ")\n"

// The names the Result projection renders beside a resource `R`: its error
// type and the type of a resource a failed producer still produced. Sema
// (SemaFacade.w facade_generated_type_names) refuses a program in which
// either name already denotes another type.
pub fn facade_render_error_name(name: &str) -> str: name ++ "Error"
pub fn facade_render_failed_name(name: &str) -> str: "Failed" ++ name

// `<R>Error` (Eric, 2026-09-23, on #1426): an `error` declaration, so it
// composes with §10.9 (`error AppError from DatabaseError`) and gets the
// generated Error/Debug/Display.
//
//     error DatabaseError =
//         | Failed(status: S)
//         | FailedWithResource(status: S, resource: FailedDatabase)
//         | NothingProduced(status: S)
//
// `FailedWithResource` and `NothingProduced` exist only when an
// out-parameter producer is projected, and `FailedWithResource` only when
// the resource is not dependent (a dependent one is destroyed in the
// constructor instead, ruling §18); a failed in-place init produced
// nothing, and a successful one produced, so its error type is `Failed`
// alone.
//
// The resource a failed producer still produced is `Failed<R>`, not `R`: the
// failure state admits only the operations the facade states are valid on
// it, the facade has no clause for that yet, and so it admits none — no lend
// methods, no destroyers, only raw access to its representation under the
// raw C rules. Its Drop runs the facade's `drop` exactly once: dropping the
// error, or whatever took the resource out of it, destroys it.
//
//     type FailedDatabase { repr: *mut sqlite3 }
//     impl Drop for FailedDatabase:
//         move fn drop():
//             unsafe { sqlite3_close(self.repr) }
fn facade_render_error_type(pool: AstPool, intern: InternPool, name: &str, repr_text: &str, status_type: &str, out_param: bool, failed_state: bool, drop_fn: i32) -> str:
    let err = facade_render_error_name(name)
    var out = ""
    if failed_state:
        let failed = facade_render_failed_name(name)
        out = "type " ++ failed ++ " { repr: " ++ repr_text ++ " }\nimpl Drop for " ++ failed ++ ":\n    move fn drop():\n        " ++ facade_render_call(pool, intern, drop_fn, facade_render_repr_arg(pool, intern, drop_fn, repr_text, "self.repr", false)) ++ "\n"
    out = out ++ "error " ++ err ++ " =\n    | Failed(status: " ++ status_type ++ ")\n"
    if failed_state:
        out = out ++ "    | FailedWithResource(status: " ++ status_type ++ ", resource: " ++ facade_render_failed_name(name) ++ ")\n"
    if out_param:
        out = out ++ "    | NothingProduced(status: " ++ status_type ++ ")\n"
    out

fn facade_render_has_clause(pool: AstPool, resource: i32, kind: i32) -> bool:
    let extra_start = pool.get_data1(resource as NodeId)
    for k in 0..pool.get_data2(resource as NodeId):
        if pool.get_data0(pool.get_extra(extra_start + 1 + k) as NodeId) == kind:
            return true
    false

// The declaring node of a function the facade names, by text: a c_import
// translation and the facade may hold the same name under different symbols.
// A facade describes imported declarations (§16.2b.13), so a c_import one
// (`ci[di]`) wins over a same-named With declaration elsewhere in the
// compilation — std.libc's hand-written `fclose(*mut c_void)` is not the
// `fclose(FILE *)` the program imported.
fn facade_render_find_fn(pool: AstPool, intern: InternPool, ci: &Vec[i32], sym: i32) -> i32:
    let want: str = intern.resolve(sym)
    var fallback = 0
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        if kind != NodeKind.NK_EXTERN_FN and kind != NodeKind.NK_FN_DECL:
            continue
        let have: str = intern.resolve(pool.get_data0(decl))
        if have == want:
            if di < ci.len() as i32 and ci[di] != 0:
                return decl as i32
            if fallback == 0:
                fallback = decl as i32
    fallback

fn facade_render_param_count(pool: AstPool, decl: i32) -> i32:
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0: 0 else: pool.fn_meta_param_count(meta)

// How `place` (the representation) is handed to an operation's first
// parameter: the value itself (`db_close(db *)` over `*mut db`, `tok_unload(Tok)`
// over `Tok`), the value cast to a `void *` parameter (`free`) that accepts
// every object pointer representation (ruling §61 under C's conversion rule;
// Sema verifies it in facade_void_ptr_accepts; With converts a `*const T` to
// `*mut c_void` only explicitly), or its address for the in-place shape
// (`inflateEnd(z_stream *)` over `z_stream`) — the cell's address when the
// resource is pinned, where a by-value parameter has nothing to receive.
// Empty when the parameter is none of these — Sema names it.
fn facade_render_repr_arg(pool: AstPool, intern: InternPool, decl: i32, repr_text: &str, place: &str, pinned: bool) -> str:
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0 or pool.fn_meta_param_count(meta) == 0:
        return ""
    let p0 = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(pool.fn_meta_param_start(meta), 0) as NodeId))
    let repr = facade_render_unalias(pool, intern, repr_text)
    if p0 == repr: return if pinned: "" else: place.clone()
    if (p0 == "*mut c_void" or p0 == "*const c_void") and repr.starts_with("*"): return place ++ " as " ++ p0
    if p0 == "*mut " ++ repr: return if pinned: place ++ ".as_mut_ptr()" else: "&raw mut " ++ place
    if p0 == "*const " ++ repr: return if pinned: place ++ ".as_ptr()" else: "&raw const " ++ place
    ""

// A type spelled through `type` aliases, chased to the spelling beneath
// (zlib's `z_streamp` is `*mut z_stream`): the same text comparison Sema's
// resolve_alias makes on TypeIds, so the renderer and the verifier agree on
// which operation takes the representation.
pub fn facade_render_unalias(pool: AstPool, intern: InternPool, text: &str) -> str:
    // A pointer's pointee is chased too (a header's `DIR *` translates to
    // `*mut __dirstream` where the facade names `*mut DIR`), as Sema's
    // facade_same_type compares them.
    if text.starts_with("*mut "):
        return "*mut " ++ facade_render_unalias(pool, intern, text.slice(5, text.len()))
    if text.starts_with("*const "):
        return "*const " ++ facade_render_unalias(pool, intern, text.slice(7, text.len()))
    var t: str = text.clone()
    for _ in 0..16:
        var target = ""
        for di in 0..pool.decl_count():
            let decl = pool.get_decl(di)
            if pool.kind(decl) != NodeKind.NK_TYPE_DECL or pool.get_data2(decl) % 8 != TypeDeclKind.Alias as i32:
                continue
            let have: str = intern.resolve(pool.get_data0(decl))
            if have == t:
                target = render_type_expr(pool, intern, pool.get_extra(pool.get_data1(decl)) as NodeId)
                break
        // `type _IO_FILE = opaque` declares a distinct opaque type, not an
        // alias of `void` (its target renders as c_void): stop at its name.
        if target.len() == 0 or target == "c_void" or target == "opaque":
            return t
        if target.starts_with("*"):
            return facade_render_unalias(pool, intern, target)
        t = target
    t

// `(<params>, <args>)` of the declaration's parameters from index `skip`:
// c_import spells a C parameter `p` as `__param_p` so no C name collides
// with a With keyword; the resource spells it as the header does.
fn facade_render_params(pool: AstPool, intern: InternPool, decl: i32, skip: i32) -> (str, str): facade_render_params_but(pool, intern, decl, skip, -1, "")

// The same with parameter `slot` withheld from `<params>` and passed as
// `slot_arg` in `<args>`: an out-parameter producer's slot is the
// constructor's own local, never the caller's (§16.2b.4).
//
// A parameter that receives another resource's representation is presented
// as a borrow of that resource, `p: &P`, and handed to C as `p.repr` (stage
// 6, facade_render_received_arg): a safe surface never takes the raw handle
// of a modeled resource, which could be one already destroyed. A shape a
// borrow cannot present stays as C declares it (a producer with one renders
// nothing — facade_render_deps).
fn facade_render_params_but(pool: AstPool, intern: InternPool, decl: i32, skip: i32, slot: i32, slot_arg: &str) -> (str, str):
    let meta = pool.find_fn_meta(decl as NodeId)
    var params = ""
    var args = ""
    if meta < 0:
        return (params, args)
    let start = pool.fn_meta_param_start(meta)
    for pi in skip..pool.fn_meta_param_count(meta):
        if args.len() > 0:
            args = args ++ ", "
        if pi == slot:
            args = args ++ slot_arg
            continue
        let pname = facade_render_param_name(pool, intern, start, pi)
        let ptype = render_type_expr(pool, intern, pool.fn_param_type(start, pi) as NodeId)
        var shown = if ptype == "*const i8" or ptype == "*const c_char": "str" else: ptype.clone()
        var arg = pname.clone()
        let res = facade_render_received(pool, intern, ptype)
        if res > 0:
            let received = facade_render_received_arg(pool, intern, res, ptype, pname)
            if received.len() > 0:
                let rname: str = intern.resolve(pool.get_data0(res as NodeId))
                shown = "&" ++ rname
                arg = received
        if params.len() > 0:
            params = params ++ ", "
        params = params ++ pname ++ ": " ++ shown
        args = args ++ arg
    (params, args)

fn facade_render_param_name(pool: AstPool, intern: InternPool, start: i32, pi: i32) -> str:
    let pname: str = intern.resolve(pool.fn_param_name(start, pi))
    if pname.starts_with("__param_"): pname.slice(8, pname.len()) else: pname.clone()

// Every parameter name of the declaration, ", "-separated.
fn facade_render_param_names(pool: AstPool, intern: InternPool, decl: i32) -> str:
    let meta = pool.find_fn_meta(decl as NodeId)
    var names = ""
    if meta < 0:
        return names
    let start = pool.fn_meta_param_start(meta)
    for pi in 0..pool.fn_meta_param_count(meta):
        if pi > 0:
            names = names ++ ", "
        names = names ++ facade_render_param_name(pool, intern, start, pi)
    names

// A local the rendering binds, spelled so it is none of `taken` (the
// constructor's parameter names, ", "-separated): With refuses shadowing, and
// a C parameter may well be named `repr`, `status` or `slot`.
fn facade_render_fresh(base: &str, taken: &str) -> str:
    let names = ", " ++ taken ++ ", "
    var name: str = base.clone()
    while names.contains(", " ++ name ++ ", "):
        name = name ++ "_"
    name

// The parameter index a facade `param` reference names (`param N`,
// `param name`, `param type T`), or -1: Sema's facade_resolve_param resolves
// the same reference against the signature and reports a miss.
fn facade_render_param_ref(pool: AstPool, intern: InternPool, decl: i32, ref_node: i32) -> i32:
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0 or ref_node == 0:
        return -1
    let count = pool.fn_meta_param_count(meta)
    let start = pool.fn_meta_param_start(meta)
    let rk = pool.get_data0(ref_node as NodeId)
    if rk == FACADE_PARAM_REF_INDEX:
        let digits: str = intern.resolve(pool.get_data1(ref_node as NodeId))
        var idx = 0
        for i in 0..digits.len() as i32:
            idx = idx * 10 + (digits[i] - '0') as i32
        return if idx < count: idx else: -1
    if rk == FACADE_PARAM_REF_NAME:
        let want: str = intern.resolve(pool.get_data1(ref_node as NodeId))
        for pi in 0..count:
            if facade_render_param_name(pool, intern, start, pi) == want:
                return pi
        return -1
    let want = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.get_data1(ref_node as NodeId) as NodeId))
    var found = -1
    var matches = 0
    for pi in 0..count:
        if facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(start, pi) as NodeId)) == want:
            matches = matches + 1
            found = pi
    if matches == 1: found else: -1

fn facade_render_return(pool: AstPool, intern: InternPool, decl: i32) -> str:
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0:
        return ""
    let ret = pool.fn_meta_ret(meta)
    if ret == 0:
        return ""
    let text = render_type_expr(pool, intern, ret as NodeId)
    if text == "Unit":
        return ""
    " -> " ++ text

// The call, inside `unsafe { }` exactly when the callee is raw: a translated
// inline body that c_import marked `unsafe fn`, a variadic, or a pointer in
// its signature other than a `const char *` input (SemaDecl.w
// ci_function_requires_raw_abi, read here off the AST). A resource never
// lifts the raw C name (SemaFacade.w facade_covers_param): its rendering is
// the safe surface, and an `unsafe` block with nothing unsafe in it is an
// error, so the two classifications must agree — a disagreement is loud.
fn facade_render_call(pool: AstPool, intern: InternPool, decl: i32, args: &str) -> str:
    let fname: str = intern.resolve(pool.get_data0(decl as NodeId))
    let call = fname ++ "(" ++ args ++ ")"
    if facade_render_is_raw(pool, intern, decl): "unsafe { " ++ call ++ " }" else: call

fn facade_render_is_raw(pool: AstPool, intern: InternPool, decl: i32) -> bool:
    let kind = pool.kind(decl as NodeId)
    if kind == NodeKind.NK_FN_DECL:
        let body = pool.get_data1(decl as NodeId)
        if body != 0 and pool.kind(body as NodeId) == NodeKind.NK_UNSAFE_BLOCK and pool.get_data2(body as NodeId) == UNSAFE_ORIGIN_FN_BODY:
            return true
    if kind == NodeKind.NK_EXTERN_FN and (pool.get_data2(decl as NodeId) & 1) != 0:
        return true
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0:
        return false
    let ret = pool.fn_meta_ret(meta)
    if ret != 0 and facade_render_type_is_raw(facade_render_unalias(pool, intern, render_type_expr(pool, intern, ret as NodeId))):
        return true
    let start = pool.fn_meta_param_start(meta)
    for pi in 0..pool.fn_meta_param_count(meta):
        let p = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(start, pi) as NodeId))
        if p != "*const i8" and p != "*const c_char" and facade_render_type_is_raw(p):
            return true
    false

fn facade_render_type_is_raw(text: &str) -> bool: text.starts_with("*") or text.starts_with("&") or text.starts_with("[") or text.starts_with("fn(") or text.starts_with("extern")

// The shape of the declaration a c_import translation made under `name`:
// whether there is one, and its return and first parameter types with
// aliases chased ("" when absent). The toolchain libc facade
// (compiler/LibcFacade.w) describes only declarations of libc's own shape.
pub fn facade_render_import_shape(pool: AstPool, intern: InternPool, ci: &Vec[i32], name: &str) -> (bool, str, str):
    for di in 0..pool.decl_count():
        if di >= ci.len() as i32 or ci[di] == 0:
            continue
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        if kind != NodeKind.NK_EXTERN_FN and kind != NodeKind.NK_FN_DECL:
            continue
        let have: str = intern.resolve(pool.get_data0(decl))
        if have != name:
            continue
        let meta = pool.find_fn_meta(decl)
        if meta < 0:
            return (true, "", "")
        let ret = pool.fn_meta_ret(meta)
        let ret_text = if ret == 0: "Unit" else: facade_render_unalias(pool, intern, render_type_expr(pool, intern, ret as NodeId))
        var p0 = ""
        if pool.fn_meta_param_count(meta) > 0:
            p0 = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(pool.fn_meta_param_start(meta), 0) as NodeId))
        return (true, ret_text, p0)
    (false, "", "")
