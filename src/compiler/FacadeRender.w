// FacadeRender — D51 §16.2b stage 4a: a `c facade` block's resources rendered
// as ordinary With (docs/modeled-c-implementation-plan.md, stage 4).
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
// Not rendered here: an out-parameter producer's constructor (stage 5; its
// Drop and destroyers are rendered). Nothing is ever rendered as a
// placeholder: a resource the renderer cannot express yields no text, the
// facade-level diagnostic names it, and Sema's verify_facade_resources
// reports a resource that passed every check without becoming a type.

use Ast
use InternPool
use render

// A pinned resource's cell is a `Box` (D54): Resolve makes the facade block
// that declares one this module's import of std.box (the D29 gate), since
// the rendering is spliced after resolution.
pub fn facade_render_block(pool: AstPool, intern: InternPool, facade: i32) -> str:
    var out = ""
    let extra_start = pool.get_data1(facade as NodeId)
    let count = pool.get_data2(facade as NodeId)
    for i in 0..count:
        let item = pool.get_extra(extra_start + i)
        if pool.kind(item as NodeId) == NodeKind.NK_FACADE_RESOURCE:
            out = out ++ facade_render_resource(pool, intern, item, facade_render_lend_methods(pool, intern, facade, item))
    out

// A lend operation on a pointer resource, rendered as a `&self` method of the
// resource (§16.2b.5: "once a resource is modeled, its facade-exposed
// operations borrow it"; With proves the receiver live, unmoved and
// undestroyed, which it cannot prove of a raw pointer — so the C name stays
// raw, SemaFacade.w facade_covers_param). An fn item whose first parameter
// takes the representation of exactly one pointer resource of this block —
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
fn facade_render_lend_methods(pool: AstPool, intern: InternPool, facade: i32, resource: i32) -> str:
    let rname: str = intern.resolve(pool.get_data0(resource as NodeId))
    let repr = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.get_extra(pool.get_data1(resource as NodeId)) as NodeId))
    if not repr.starts_with("*"):
        return ""
    let extra_start = pool.get_data1(facade as NodeId)
    let count = pool.get_data2(facade as NodeId)
    var out = ""
    for i in 0..count:
        let item = pool.get_extra(extra_start + i)
        if pool.kind(item as NodeId) != NodeKind.NK_FACADE_FN:
            continue
        var of_sym = 0
        var rename = 0
        var lends = true
        let cstart = pool.get_data1(item as NodeId)
        for ci in 0..pool.get_data2(item as NodeId):
            let clause = pool.get_extra(cstart + ci)
            let kind = pool.get_data0(clause as NodeId)
            let ops = pool.get_data1(clause as NodeId)
            if kind == FACADE_CLAUSE_OF: of_sym = pool.get_extra(ops)
            else if kind == FACADE_CLAUSE_RENAME: rename = pool.get_extra(ops)
            else if kind != FACADE_CLAUSE_LEND and kind != FACADE_CLAUSE_PRESERVES: lends = false
        if not lends:
            continue
        let decl = facade_render_find_fn(pool, intern, pool.get_data0(item as NodeId))
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
        else if facade_render_resources_wrapping(pool, intern, facade, repr) != 1:
            continue
        let fname: str = intern.resolve(pool.get_data0(decl as NodeId))
        var mname: str = fname.clone()
        if rename != 0:
            mname = intern.resolve(rename)
        let (params, args) = facade_render_params(pool, intern, decl, 1)
        let call_args = if args.len() > 0: "self.repr, " ++ args else: "self.repr"
        out = out ++ "    fn " ++ mname ++ "(" ++ params ++ ")" ++ facade_render_return(pool, intern, decl) ++ ":\n        " ++ facade_render_call(pool, intern, decl, call_args) ++ "\n"
    out

fn facade_render_resources_wrapping(pool: AstPool, intern: InternPool, facade: i32, repr: &str) -> i32:
    let extra_start = pool.get_data1(facade as NodeId)
    var n = 0
    for i in 0..pool.get_data2(facade as NodeId):
        let item = pool.get_extra(extra_start + i)
        if pool.kind(item as NodeId) == NodeKind.NK_FACADE_RESOURCE:
            let r = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.get_extra(pool.get_data1(item as NodeId)) as NodeId))
            if r == repr: n = n + 1
    n

fn facade_render_resource(pool: AstPool, intern: InternPool, item: i32, methods: &str) -> str:
    let name: str = intern.resolve(pool.get_data0(item as NodeId))
    let extra_start = pool.get_data1(item as NodeId)
    let clause_count = pool.get_data2(item as NodeId)
    let repr_text = render_type_expr(pool, intern, pool.get_extra(extra_start) as NodeId)
    let producers: Vec[i32] = Vec.new()
    var drop_fn = 0
    var init_fn = 0
    var preinit_fn = 0
    var ok_sym = 0
    var movable = false
    let destroyers: Vec[i32] = Vec.new()
    for ci in 0..clause_count:
        let clause = pool.get_extra(extra_start + 1 + ci)
        let kind = pool.get_data0(clause as NodeId)
        let ops = pool.get_data1(clause as NodeId)
        if kind == FACADE_CLAUSE_FROM:
            // An out-parameter producer's constructor is stage 5.
            if pool.get_extra(ops + 1) == 0:
                producers.push(facade_render_find_fn(pool, intern, pool.get_extra(ops)))
        else if kind == FACADE_CLAUSE_INIT:
            init_fn = facade_render_find_fn(pool, intern, pool.get_extra(ops))
        else if kind == FACADE_CLAUSE_PREINIT:
            preinit_fn = facade_render_find_fn(pool, intern, pool.get_extra(ops))
        else if kind == FACADE_CLAUSE_OK:
            ok_sym = pool.get_extra(ops)
        else if kind == FACADE_CLAUSE_MOVABLE:
            movable = true
        else if kind == FACADE_CLAUSE_DROP:
            drop_fn = facade_render_find_fn(pool, intern, pool.get_extra(ops))
        else if kind == FACADE_CLAUSE_DESTROYS:
            destroyers.push(facade_render_find_fn(pool, intern, pool.get_extra(ops)))
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
    let field = if pinned: "Box[" ++ repr_text ++ "]" else: repr_text.clone()
    var out = "type " ++ name ++ " { repr: " ++ field ++ ", live: bool }\n"
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
    for pi in 0..producers.len() as i32:
        let producer = producers[pi]
        if producer == 0:
            continue
        let pname: str = intern.resolve(pool.get_data0(producer as NodeId))
        let (params, args) = facade_render_params(pool, intern, producer, 0)
        let call = facade_render_call(pool, intern, producer, args)
        if facade_render_unalias(pool, intern, repr_text).starts_with("*"):
            // Unknown nullability is nullable, never silently non-null
            // (§16.2b.8): a pointer producer yields `Option[R]`, and a NULL
            // produced nothing — no Drop is armed over it (§16.2b.4).
            out = out ++ "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ") -> Option[" ++ name ++ "]:\n    let repr = " ++ call ++ "\n    if repr == null: None else: Some(" ++ name ++ " { repr, live: true })\n"
        else:
            out = out ++ "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ") -> " ++ name ++ ":\n    " ++ name ++ " { repr: " ++ call ++ ", live: true }\n"
    if init_fn != 0:
        let ctor = facade_render_init(pool, intern, name, repr_text, init_fn, preinit_fn, ok_sym, pinned)
        if ctor.len() == 0:
            return ""
        out = out ++ ctor
    out

// The in-place constructor (ruling §13, spec §16.2b.4): storage first — the
// representation's ordinary zeroed construction `Repr {}` (every field of an
// imported struct carries its zero default; ruling §67 consumes that rule)
// or the `preinit` operation's result — then the C initializer over a
// pointer to it, then the arming bit. `live` is set only when initialization
// establishes production (§13.2): with `ok CONST` a status other than the
// constant leaves Drop unarmed and the storage still cleans up as ordinary
// With; without `ok` the status is uninterpreted (§16.2b.4), so the resource
// is live and the status is handed back unread. A status-returning init
// yields `(status, R)`, the low-level model every projection sits over; a
// void init yields `R`.
//
// Pinned (the default, D54): the storage is a Box cell the value owns, so
// the cell exists — with its one address — from the construction of R,
// before `live`; every pointer handed to C points into it; and on drop the
// destruction operation runs in R's own Drop before the field's Drop frees
// the cell (the cell outlives the C state, never the reverse).
//
//     fn R.init(<preinit args>, <init args after self>) -> (c_int, R):
//         var repr = Box.new(Repr {})                     // or Box.new(preinit(<preinit args>))
//         let status = init(repr.as_mut_ptr(), <args>)
//         (status, R { repr, live: status == OK })         // `live: true` without ok
//
// `movable`: the same over a by-value field — `var repr = Repr {}` and
// `init(&raw mut repr, <args>)`.
fn facade_render_init(pool: AstPool, intern: InternPool, name: &str, repr_text: &str, init_fn: i32, preinit_fn: i32, ok_sym: i32, pinned: bool) -> str:
    let iname: str = intern.resolve(pool.get_data0(init_fn as NodeId))
    let storage_arg = facade_render_repr_arg(pool, intern, init_fn, repr_text, "repr", pinned)
    if storage_arg.len() == 0 or storage_arg == "repr":
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
    var out = "fn " ++ name ++ "." ++ iname ++ "(" ++ params ++ ")"
    if ret.len() == 0:
        if ok_sym != 0:
            return ""
        return out ++ " -> " ++ name ++ ":\n    var repr = " ++ storage ++ "\n    " ++ call ++ "\n    " ++ name ++ " { repr, live: true }\n"
    let armed = if ok_sym != 0: "status == " ++ intern.resolve(ok_sym) else: "true"
    out ++ " -> (" ++ ret.slice(4, ret.len()) ++ ", " ++ name ++ "):\n    var repr = " ++ storage ++ "\n    let status = " ++ call ++ "\n    (status, " ++ name ++ " { repr, live: " ++ armed ++ " })\n"

// The declaring node of a function the facade names, by text: a c_import
// translation and the facade may hold the same name under different symbols.
fn facade_render_find_fn(pool: AstPool, intern: InternPool, sym: i32) -> i32:
    let want: str = intern.resolve(sym)
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        if kind != NodeKind.NK_EXTERN_FN and kind != NodeKind.NK_FN_DECL:
            continue
        let have: str = intern.resolve(pool.get_data0(decl))
        if have == want:
            return decl as i32
    0

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
fn facade_render_unalias(pool: AstPool, intern: InternPool, text: &str) -> str:
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
        if target.len() == 0:
            return t
        t = target
    t

// `(<params>, <args>)` of the declaration's parameters from index `skip`:
// c_import spells a C parameter `p` as `__param_p` so no C name collides
// with a With keyword; the resource spells it as the header does.
fn facade_render_params(pool: AstPool, intern: InternPool, decl: i32, skip: i32) -> (str, str):
    let meta = pool.find_fn_meta(decl as NodeId)
    var params = ""
    var args = ""
    if meta < 0:
        return (params, args)
    let start = pool.fn_meta_param_start(meta)
    for pi in skip..pool.fn_meta_param_count(meta):
        var pname: str = intern.resolve(pool.fn_param_name(start, pi))
        if pname.starts_with("__param_"):
            pname = pname.slice(8, pname.len())
        let ptype = render_type_expr(pool, intern, pool.fn_param_type(start, pi) as NodeId)
        let shown = if ptype == "*const i8" or ptype == "*const c_char": "str" else: ptype
        if params.len() > 0:
            params = params ++ ", "
            args = args ++ ", "
        params = params ++ pname ++ ": " ++ shown
        args = args ++ pname
    (params, args)

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
