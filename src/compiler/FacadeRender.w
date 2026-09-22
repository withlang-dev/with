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
//             if self.live: d(self.repr)
//     impl R:
//         move fn k(<args after the representation>) -> <ret>:
//             self.live = false
//             k(self.repr, <args>)
//     fn R.p(<args>) -> R:
//         R { repr: p(<args>), live: true }
//
// `live` is the Drop arming bit (ruling §13.2): a `move fn` destroyer consumes
// `self`, and With has no spelling that forgets a consumed value's Drop — a
// destroyer that read `self.repr` and let `self` drop destroyed twice (the
// counting test in behav_c_facade_resource_destroys_once.w) — so the
// destroyer clears the bit and Drop checks it, the way std.regex's Regex arms
// its pcre2 free. Stage 4b's in-place resources arm the same bit from `init`.
//
// A raw call is spelled bare: the facade covers the destroyer's first
// parameter and the producer's return (SemaFacade.w facade_covers_*), so the
// c_import extern is not raw there, and an `unsafe` block around a call that
// needs none is itself an error. A translated `static inline` body that
// c_import marked `unsafe fn` is the one callee that still demands `unsafe`,
// and that is read off its AST. A `*const i8` parameter is presented as `str`:
// the c_import extern lends a `str` to a `const char *` (§16.3c, D47), and
// the resource's constructor passes the `str` straight through.
//
// An operation that takes a pointer to the representation (the in-place
// shape, `inflateEnd(z_stream *)`, or a by-value token whose destroyer takes
// its address) is handed `&raw mut self.repr`; an in-place resource's `init`
// constructor is facade_render_init below (stage 4b).
//
// Not rendered here: an out-parameter producer's constructor (stage 5; its
// Drop and destroyers are rendered). Nothing is ever rendered as a
// placeholder: a resource the renderer cannot express yields no text, the
// facade-level diagnostic names it, and Sema's verify_facade_resources
// reports a resource that passed every check without becoming a type.

use Ast
use InternPool
use render

pub fn facade_render_block(pool: AstPool, intern: InternPool, facade: i32) -> str:
    var out = ""
    let extra_start = pool.get_data1(facade as NodeId)
    let count = pool.get_data2(facade as NodeId)
    for i in 0..count:
        let item = pool.get_extra(extra_start + i)
        if pool.kind(item as NodeId) == NodeKind.NK_FACADE_RESOURCE:
            out = out ++ facade_render_resource(pool, intern, item)
    out

fn facade_render_resource(pool: AstPool, intern: InternPool, item: i32) -> str:
    let name: str = intern.resolve(pool.get_data0(item as NodeId))
    let extra_start = pool.get_data1(item as NodeId)
    let clause_count = pool.get_data2(item as NodeId)
    let repr_text = render_type_expr(pool, intern, pool.get_extra(extra_start) as NodeId)
    var producer = 0
    var out_param = 0
    var drop_fn = 0
    var init_fn = 0
    var preinit_fn = 0
    var ok_sym = 0
    let destroyers: Vec[i32] = Vec.new()
    for ci in 0..clause_count:
        let clause = pool.get_extra(extra_start + 1 + ci)
        let kind = pool.get_data0(clause as NodeId)
        let ops = pool.get_data1(clause as NodeId)
        if kind == FACADE_CLAUSE_FROM:
            producer = facade_render_find_fn(pool, intern, pool.get_extra(ops))
            out_param = pool.get_extra(ops + 1)
        else if kind == FACADE_CLAUSE_INIT:
            init_fn = facade_render_find_fn(pool, intern, pool.get_extra(ops))
        else if kind == FACADE_CLAUSE_PREINIT:
            preinit_fn = facade_render_find_fn(pool, intern, pool.get_extra(ops))
        else if kind == FACADE_CLAUSE_OK:
            ok_sym = pool.get_extra(ops)
        else if kind == FACADE_CLAUSE_DROP:
            drop_fn = facade_render_find_fn(pool, intern, pool.get_extra(ops))
        else if kind == FACADE_CLAUSE_DESTROYS:
            destroyers.push(facade_render_find_fn(pool, intern, pool.get_extra(ops)))
    // A name that is not a declaration, a resource with no `drop` (a
    // producer with nothing to destroy it; `destroys` operations alone would
    // leak a value dropped while live), a destroyer that takes neither the
    // representation nor a pointer to it: Sema's facade diagnostics name the
    // resource; nothing is rendered.
    if drop_fn == 0:
        return ""
    for di in 0..destroyers.len() as i32:
        if destroyers[di] == 0 or facade_render_repr_arg(pool, intern, destroyers[di], repr_text, "self.repr").len() == 0:
            return ""
    if drop_fn != 0 and (facade_render_param_count(pool, drop_fn) != 1 or facade_render_repr_arg(pool, intern, drop_fn, repr_text, "self.repr").len() == 0):
        return ""
    var out = "type " ++ name ++ " { repr: " ++ repr_text ++ ", live: bool }\n"
    if drop_fn != 0:
        out = out ++ "impl Drop for " ++ name ++ ":\n    move fn drop():\n        if self.live: " ++ facade_render_call(pool, intern, drop_fn, facade_render_repr_arg(pool, intern, drop_fn, repr_text, "self.repr")) ++ "\n"
    if destroyers.len() > 0:
        out = out ++ "impl " ++ name ++ ":\n"
        for di in 0..destroyers.len() as i32:
            let d = destroyers[di]
            let dname: str = intern.resolve(pool.get_data0(d as NodeId))
            let (params, args) = facade_render_params(pool, intern, d, 1)
            let repr_arg = facade_render_repr_arg(pool, intern, d, repr_text, "self.repr")
            let call_args = if args.len() > 0: repr_arg ++ ", " ++ args else: repr_arg
            out = out ++ "    move fn " ++ dname ++ "(" ++ params ++ ")" ++ facade_render_return(pool, intern, d) ++ ":\n        self.live = false\n        " ++ facade_render_call(pool, intern, d, call_args) ++ "\n"
    if producer != 0 and out_param == 0:
        let pname: str = intern.resolve(pool.get_data0(producer as NodeId))
        let (params, args) = facade_render_params(pool, intern, producer, 0)
        out = out ++ "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ") -> " ++ name ++ ":\n    " ++ name ++ " { repr: " ++ facade_render_call(pool, intern, producer, args) ++ ", live: true }\n"
    if init_fn != 0:
        let ctor = facade_render_init(pool, intern, name, repr_text, init_fn, preinit_fn, ok_sym)
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
//     fn R.init(<preinit args>, <init args after self>) -> (c_int, R):
//         var repr = Repr {}                      // or preinit(<preinit args>)
//         let status = init(&raw mut repr, <args>)
//         (status, R { repr, live: status == OK })  // `live: true` without ok
fn facade_render_init(pool: AstPool, intern: InternPool, name: &str, repr_text: &str, init_fn: i32, preinit_fn: i32, ok_sym: i32) -> str:
    let iname: str = intern.resolve(pool.get_data0(init_fn as NodeId))
    let storage_arg = facade_render_repr_arg(pool, intern, init_fn, repr_text, "repr")
    if not storage_arg.starts_with("&raw"):
        return ""
    let (iparams, iargs) = facade_render_params(pool, intern, init_fn, 1)
    var params = iparams
    var storage = repr_text ++ " {}"
    if preinit_fn != 0:
        let (pparams, pargs) = facade_render_params(pool, intern, preinit_fn, 0)
        if pparams.len() > 0:
            params = if params.len() > 0: pparams ++ ", " ++ params else: pparams
        storage = facade_render_call(pool, intern, preinit_fn, pargs)
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
// (`inflateEnd(z_stream *)` over `z_stream`). Empty when the parameter is
// none of these — Sema names it.
fn facade_render_repr_arg(pool: AstPool, intern: InternPool, decl: i32, repr_text: &str, place: &str) -> str:
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0 or pool.fn_meta_param_count(meta) == 0:
        return ""
    let p0 = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(pool.fn_meta_param_start(meta), 0) as NodeId))
    let repr = facade_render_unalias(pool, intern, repr_text)
    if p0 == repr: return place.clone()
    if (p0 == "*mut c_void" or p0 == "*const c_void") and repr.starts_with("*"): return place ++ " as " ++ p0
    if p0 == "*mut " ++ repr: return "&raw mut " ++ place
    if p0 == "*const " ++ repr: return "&raw const " ++ place
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

// The call, inside `unsafe { }` only when the callee is a translated inline
// body that c_import marked `unsafe fn`; a covered extern is not raw and an
// `unsafe` block with nothing unsafe in it is an error.
fn facade_render_call(pool: AstPool, intern: InternPool, decl: i32, args: &str) -> str:
    let fname: str = intern.resolve(pool.get_data0(decl as NodeId))
    let call = fname ++ "(" ++ args ++ ")"
    if pool.kind(decl as NodeId) == NodeKind.NK_FN_DECL:
        let body = pool.get_data1(decl as NodeId)
        if body != 0 and pool.kind(body as NodeId) == NodeKind.NK_UNSAFE_BLOCK and pool.get_data2(body as NodeId) == UNSAFE_ORIGIN_FN_BODY:
            return "unsafe { " ++ call ++ " }"
    call
