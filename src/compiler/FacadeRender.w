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
// Not rendered here, each reported by Sema at the resource: an in-place
// resource (`init`/`preinit`, or a destroyer taking a pointer to the
// representation — stage 4b) and an out-parameter producer's constructor
// (stage 5; its Drop and destroyers are rendered). Nothing is ever rendered
// as a placeholder: a resource the renderer cannot express yields no text and
// the facade-level diagnostic names it.

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
    let destroyers: Vec[i32] = Vec.new()
    for ci in 0..clause_count:
        let clause = pool.get_extra(extra_start + 1 + ci)
        let kind = pool.get_data0(clause as NodeId)
        let ops = pool.get_data1(clause as NodeId)
        if kind == FACADE_CLAUSE_INIT or kind == FACADE_CLAUSE_PREINIT:
            // In-place resource: stage 4b (Sema reports it).
            return ""
        if kind == FACADE_CLAUSE_FROM:
            producer = facade_render_find_fn(pool, intern, pool.get_extra(ops))
            out_param = pool.get_extra(ops + 1)
        else if kind == FACADE_CLAUSE_DROP:
            drop_fn = facade_render_find_fn(pool, intern, pool.get_extra(ops))
        else if kind == FACADE_CLAUSE_DESTROYS:
            destroyers.push(facade_render_find_fn(pool, intern, pool.get_extra(ops)))
    // A name that is not a declaration, or a producer with nothing to destroy
    // it: Sema's facade diagnostics name the resource; nothing is rendered.
    if drop_fn == 0 and destroyers.len() == 0:
        return ""
    for di in 0..destroyers.len() as i32:
        if destroyers[di] == 0:
            return ""
    if drop_fn != 0 and (facade_render_param_count(pool, drop_fn) != 1 or facade_render_takes_repr_pointer(pool, intern, drop_fn, repr_text)):
        return ""
    for di in 0..destroyers.len() as i32:
        if facade_render_takes_repr_pointer(pool, intern, destroyers[di], repr_text):
            return ""
    var out = "type " ++ name ++ " { repr: " ++ repr_text ++ ", live: bool }\n"
    if drop_fn != 0:
        out = out ++ "impl Drop for " ++ name ++ ":\n    move fn drop():\n        if self.live: " ++ facade_render_call(pool, intern, drop_fn, "self.repr") ++ "\n"
    if destroyers.len() > 0:
        out = out ++ "impl " ++ name ++ ":\n"
        for di in 0..destroyers.len() as i32:
            let d = destroyers[di]
            let dname: str = intern.resolve(pool.get_data0(d as NodeId))
            let (params, args) = facade_render_params(pool, intern, d, 1)
            let call_args = if args.len() > 0: "self.repr, " ++ args else: "self.repr"
            out = out ++ "    move fn " ++ dname ++ "(" ++ params ++ ")" ++ facade_render_return(pool, intern, d) ++ ":\n        self.live = false\n        " ++ facade_render_call(pool, intern, d, call_args) ++ "\n"
    if producer != 0 and out_param == 0:
        let pname: str = intern.resolve(pool.get_data0(producer as NodeId))
        let (params, args) = facade_render_params(pool, intern, producer, 0)
        out = out ++ "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ") -> " ++ name ++ ":\n    " ++ name ++ " { repr: " ++ facade_render_call(pool, intern, producer, args) ++ ", live: true }\n"
    out

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

// A destroyer whose first parameter is a pointer to the representation is the
// in-place shape (`inflateEnd(z_stream *)`): stage 4b.
fn facade_render_takes_repr_pointer(pool: AstPool, intern: InternPool, decl: i32, repr_text: &str) -> bool:
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0 or pool.fn_meta_param_count(meta) == 0:
        return false
    let p0 = render_type_expr(pool, intern, pool.fn_param_type(pool.fn_meta_param_start(meta), 0) as NodeId)
    p0 == "*mut " ++ repr_text or p0 == "*const " ++ repr_text

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
