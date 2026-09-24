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
// Constructors, destroyers and lend methods are spelled by presentation
// (§16.2b.11, stage 8 below): `Database.open` for `sqlite3_open`, or the
// item's `rename`; the C name where the convention is ambiguous.
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
use CImport
use Token

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
            let text_view = facade_render_text_view(pool, intern, item)
            out = out ++ facade_render_hosted_fn_errors(pool, intern, ci, item)
            out = out ++ facade_render_resource(pool, intern, ci, item, facade_render_lend_methods(pool, intern, ci, item, true, false) ++ text_view ++ facade_render_callback_methods(pool, intern, ci, item), facade_render_lend_methods(pool, intern, ci, item, false, false) ++ text_view, facade_render_lend_methods(pool, intern, ci, item, false, true))
    // Free operations (D64): the block's own fn items presented with a
    // buffer pairing or a fixed argument and hosted by no resource.
    out = out ++ facade_render_free_ops(pool, intern, ci, facade)
    facade_render_public(out)

// The `<Fn>Error` types of the resource's lend methods that present a
// copied-back length under `ok` (D64): declared beside the resource, since
// an error type cannot live inside its impl.
fn facade_render_hosted_fn_errors(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32) -> str:
    let repr_text = render_type_expr(pool, intern, pool.get_extra(pool.get_data1(resource as NodeId)) as NodeId)
    let repr = facade_render_unalias(pool, intern, repr_text)
    var out = ""
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        let li = facade_render_lend_item(pool, intern, ci, items[i])
        if not li.bridged or li.text_view or li.borrow_res != 0 or not facade_render_lend_hosted(pool, intern, &li, resource, repr):
            continue
        let bridge = facade_render_bridge(pool, intern, li.decl, 1, -1, "")
        if not bridge.ok or bridge.cap_var.len() == 0 or facade_render_fn_ok(pool, intern, li.decl) == 0:
            continue
        let fname: str = intern.resolve(pool.get_data0(li.decl as NodeId))
        out = out ++ facade_render_fn_error_type(pool, intern, li.decl, facade_render_present(pool, intern, ci, resource, fname))
    out

// Everything a facade renders is its module's public surface (spec
// §16.2b.1: a facade is written in the importing project or shipped by a
// package, and its resource types are used wherever the module is
// imported — the SQLite facade lives in its own module, stage 12): every
// rendered type, error, constructor and method is `pub`. A Drop body is
// the type's own and stays as it is.
fn facade_render_public(text: &str) -> str:
    var out = ""
    var in_drop = false
    var start = 0
    while start < text.len() as i32:
        var end = start
        while end < text.len() as i32 and text[end] != '\n': end = end + 1
        let line = text.slice(start, end)
        if line.starts_with("impl Drop for "): in_drop = true
        else if line.starts_with("impl "): in_drop = false
        var shown = line.clone()
        if line.starts_with("type ") or line.starts_with("error ") or line.starts_with("fn "):
            shown = "pub " ++ line
        else if not in_drop and (line.starts_with("    fn ") or line.starts_with("    mut fn ") or line.starts_with("    move fn ")):
            shown = "    pub " ++ line.slice(4, line.len())
        out = out ++ shown ++ (if end < text.len() as i32: "\n" else: "")
        start = end + 1
    out

// Owned foreign text (ruling §42, spec §16.2b.8: "Caller-owned returned
// memory is a resource … It exposes a borrowed `CStr` view"): a pointer
// resource whose representation is a C string — `*mut c_char`, `*const
// c_char`, strdup's `*mut i8` — carries
//
//     fn as_cstr() -> CStr: unsafe { CStr.from_ptr(self.repr as *const i8) }
//
// a view of the bytes the resource owns, ephemeral like every `CStr`, and
// kept inside the resource's life by the declared summary Sema puts on it
// (SemaFacade.w verify_facade_text_views). The foreign allocator pairing is
// untouched: the view copies nothing, and `to_owned` is the explicit copy.
fn facade_render_text_view(pool: AstPool, intern: InternPool, resource: i32) -> str:
    let repr = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.get_extra(pool.get_data1(resource as NodeId)) as NodeId))
    if not facade_render_is_c_string_ptr(repr):
        return ""
    "    fn as_cstr() -> CStr: unsafe { CStr.from_ptr(self.repr as *const i8) }\n"

// A NUL-terminated C string's pointer type as c_import spells it, aliases
// chased: `char *` is `*mut i8`, `const char *` is `*const i8`.
pub fn facade_render_is_c_string_ptr(text: &str) -> bool:
    text == "*mut i8" or text == "*const i8" or text == "*mut c_char" or text == "*const c_char"

pub fn facade_render_text_view_name() -> str: "as_cstr"

// A lend operation on a pointer or in-place resource, rendered as a `&self`
// method of the resource (§16.2b.5: "once a resource is modeled, its
// facade-exposed operations borrow it"; With proves the receiver live,
// unmoved and undestroyed, which it cannot prove of a raw pointer — so the C
// name stays raw, SemaFacade.w facade_covers_param). An fn item whose first
// parameter takes the representation — a pointer resource's handle, or the
// address of an in-place resource's storage — of exactly one resource of
// any block, or the one its `of` names (§16.2b.3), and that states nothing
// stronger than a lend (`lend`, `of`, `rename`, `preserves`) becomes
//
//     impl R:
//         fn <presented name>(<args after the representation>) -> <ret>:
//             unsafe { <name>(self.repr, <args>) }
//
// under its presented name (facade_render_present: the C name less the
// representation's prefix, or its `rename`). A pinned resource hands C its
// cell's address; a movable one the address of its field, which through a
// mutable pointer is a `mut fn`. Anything else stays as stated: a
// consuming, destroying or retaining item is not a lend, a by-value token
// is not recognized by its type, and an item describing a resource's own
// producer, initializer or destroyer adds facts to that operation.
//
// `failed_only` (stage 12b, #1612; spec §16.2b.4): the lends and text
// views the facade marks `valid on failed`, rendered on the failed-state
// type `Failed<R>` — the same body over the same `repr` field — and
// nothing else (a borrowed-resource return holds a view of a live `R`;
// Sema refuses the mark on one).
fn facade_render_lend_methods(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32, with_borrowed_returns: bool, failed_only: bool) -> str:
    let repr_text = render_type_expr(pool, intern, pool.get_extra(pool.get_data1(resource as NodeId)) as NodeId)
    let repr = facade_render_unalias(pool, intern, repr_text)
    let in_place = not repr.starts_with("*") and facade_render_has_clause(pool, resource, FACADE_CLAUSE_INIT)
    if not repr.starts_with("*") and not in_place:
        return ""
    let pinned = in_place and not facade_render_has_clause(pool, resource, FACADE_CLAUSE_MOVABLE)
    var out = ""
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        let li = facade_render_lend_item(pool, intern, ci, items[i])
        if not facade_render_lend_hosted(pool, intern, &li, resource, repr):
            continue
        if failed_only and (not li.valid_on_failed or li.borrow_res != 0):
            continue
        let decl = li.decl
        let meta = pool.find_fn_meta(decl as NodeId)
        let fname: str = intern.resolve(pool.get_data0(decl as NodeId))
        let mname = facade_render_present(pool, intern, ci, resource, fname)
        // How `self` reaches C: the handle, the pinned cell's address, or
        // the address of a movable representation — which a mutable
        // pointer writes through, so that lend is a `mut fn`.
        let repr_arg = facade_render_repr_arg(pool, intern, decl, repr_text, "self.repr", pinned)
        if repr_arg.len() == 0:
            continue
        let head = if repr_arg.starts_with("&raw mut "): "    mut fn " else: "    fn "
        let bridge = facade_render_bridge(pool, intern, decl, 1, -1, "")
        if not bridge.ok:
            continue
        let params = bridge.params.clone()
        let args = bridge.args.clone()
        let pro = facade_render_indent(bridge.prologue, "        ")
        let call_args = if args.len() > 0: repr_arg ++ ", " ++ args else: repr_arg.clone()
        if li.text_view:
            // `returns borrow CStr from …` / `returns static CStr` (ruling
            // §32, §40, §41; spec §16.2b.8): the nullable foreign string is
            // `Option[CStr]` — the `CStr` value is the borrowed modeled text,
            // a view (Sema.w: `CStr` is ephemeral) — over the same bytes, no
            // copy; NULL is `None` (unknown nullability is nullable, §43).
            // What keeps it inside its origin — the resource `self`, a C
            // string parameter, a domain, or nothing for static — is the
            // declared summary Sema puts on this method
            // (SemaFacade.w verify_facade_borrowed_returns).
            let handle = facade_render_fresh("repr", facade_render_param_names(pool, intern, decl))
            out = out ++ head ++ mname ++ "(" ++ params ++ ") -> Option[CStr]:\n" ++ pro ++ "        let " ++ handle ++ " = " ++ facade_render_call(pool, intern, decl, call_args) ++ "\n        if " ++ handle ++ " == null: None else: Some(unsafe { CStr.from_ptr(" ++ handle ++ " as *const i8) })\n"
            continue
        if li.borrow_res != 0:
            if not with_borrowed_returns:
                continue
            // `returns borrow R from param N` (ruling §26): the result is a
            // `Borrowed<R>` — no Drop, dependent on the parameter named —
            // and, unknown nullability being nullable (§16.2b.8), an Option
            // of it (facade_render_borrowed_type).
            let from = facade_render_param_ref(pool, intern, decl, li.borrow_from)
            if from < 0:
                continue
            let origin = if from == 0: "self" else: facade_render_param_name(pool, intern, pool.fn_meta_param_start(meta), from)
            let bname = facade_render_borrowed_name(intern.resolve(li.borrow_res))
            let handle = facade_render_fresh("repr", facade_render_param_names(pool, intern, decl))
            out = out ++ head ++ mname ++ "(" ++ params ++ ") -> Option[" ++ bname ++ "]:\n" ++ pro ++ "        let " ++ handle ++ " = " ++ facade_render_call(pool, intern, decl, call_args) ++ "\n        if " ++ handle ++ " == null: None else: Some(" ++ bname ++ " { origin: " ++ origin ++ ", repr: " ++ handle ++ " })\n"
            continue
        let (ret, body) = facade_render_bridge_body(pool, intern, decl, &bridge, facade_render_call(pool, intern, decl, call_args), mname, "        ")
        out = out ++ head ++ mname ++ "(" ++ params ++ ")" ++ ret ++ ":\n" ++ pro ++ body
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

// ── stage 8: presentation (ruling §53-§55, spec §16.2b.11) ──────────────
//
// Every operation a resource's rendering exposes is spelled on the resource
// type by the naming convention §16.2a already applies to raw imports: the
// C name less the representation's snake-case prefix (`db_count` on
// `Database wraps *mut db` is `d.count()`, `sqlite3_prepare_v2` on `*mut
// sqlite3` is `prepare_v2`) or less the library prefix the struct name
// carries (`sqlite3_step` on `*mut sqlite3_stmt` is `step`,
// facade_render_shorten), or the `rename` an fn item states. A producer
// whose first parameter receives another resource is presented as a method
// of that resource too (`db.prepare(sql)` beside `Statement.prepare(db,
// sql)`, facade_render_receiver_method), and the constructor of a resource
// made from a parent is shortened by the parent's prefix when its own does
// not match. Being wrong here changes a spelling, never a contract (§54:
// "being wrong changes API presentation, not ownership or lifetime
// behavior"), so the convention applies silently.
//
// An ambiguity never guesses (§55: "If automatic grouping is ambiguous,
// method sugar may simply be omitted while the underlying modeled foreign
// operation remains available"): when two operations of one resource
// shorten to one name, or a shortened name is another operation's imported
// or renamed name, the shortened ones keep their imported names, and Sema
// notes the candidates and the `rename` that would settle it (SemaFacade.w
// verify_facade_presentation). A shortened name that is a With keyword, or
// `drop` (the resource's Drop), is likewise not taken. A `rename` is
// explicit and never yields; two renames to one name are an error (Sema).
type FacadeSurface {
    cnames: Vec[str],      // the C name of each operation presented on the resource ("" for a rendered fixture such as Drop)
    names: Vec[str],       // the name it is presented under, before ambiguity is settled
    explicit: Vec[bool],   // renamed, or under its imported name: never yields
    roles: Vec[str],       // what it is, for the ambiguity note
}

// The name operation `cname` is presented under on `resource`: its
// `rename`, its shortened name when that is unambiguous, else the C name.
pub fn facade_render_present(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32, cname: &str) -> str:
    let s = facade_render_surface(pool, intern, ci, resource)
    for i in 0..s.cnames.len() as i32:
        if s.cnames[i] != cname:
            continue
        let explicit: bool = s.explicit[i]
        if explicit:
            return s.names[i].clone()
        for j in 0..s.cnames.len() as i32:
            if j != i and s.names[j] == s.names[i]:
                return cname.clone()
        return s.names[i].clone()
    cname.clone()

// Why `cname` keeps its imported name on `resource` — the other operations
// its shortened name would also spell, as "'db_get' (a lend method), the
// resource's Drop" — or "" when its presentation is not ambiguous.
pub fn facade_render_presentation_clash(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32, cname: &str) -> str:
    let s = facade_render_surface(pool, intern, ci, resource)
    for i in 0..s.cnames.len() as i32:
        let explicit: bool = s.explicit[i]
        if s.cnames[i] != cname or explicit:
            continue
        var others = ""
        for j in 0..s.cnames.len() as i32:
            if j == i or s.names[j] != s.names[i]:
                continue
            let cn = s.cnames[j]
            let role = s.roles[j]
            let shown = if cn.len() == 0: role.clone() else: f"'{cn}' ({role})"
            others = others ++ (if others.len() > 0: ", " else: "") ++ shown
        return others
    ""

// The C names of every operation presented on `resource`, each once.
pub fn facade_render_presented_ops(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32) -> Vec[str]:
    let s = facade_render_surface(pool, intern, ci, resource)
    let out: Vec[str] = Vec.new()
    for i in 0..s.cnames.len() as i32:
        let cn = s.cnames[i]
        if cn.len() == 0:
            continue
        var seen = false
        for k in 0..out.len() as i32:
            if out[k] == cn: seen = true
        if not seen:
            out.push(cn.clone())
    out

// Those of them an fn item renames.
pub fn facade_render_renamed_ops(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32) -> Vec[str]:
    let ops = facade_render_presented_ops(pool, intern, ci, resource)
    let out: Vec[str] = Vec.new()
    for i in 0..ops.len() as i32:
        if facade_render_item_rename(pool, intern, ops[i]).len() > 0:
            out.push(ops[i].clone())
    out

// The shortened name of `cname` on `resource`, ambiguity aside ("" when no
// prefix matches): what an ambiguity note names as the spelling both
// operations would take.
pub fn facade_render_shortened(pool: AstPool, intern: InternPool, resource: i32, cname: &str) -> str:
    facade_render_shorten(cname, &facade_render_prefix_names(pool, intern, resource))

// The presented surface of a resource: its constructors (`from`, `init`),
// destroying methods, Drop, text view, hosted lend methods, and the
// producers of other resources its value is the receiver of.
fn facade_render_surface(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32) -> FacadeSurface:
    var s = FacadeSurface { cnames: Vec.new(), names: Vec.new(), explicit: Vec.new(), roles: Vec.new() }
    let repr_text = render_type_expr(pool, intern, pool.get_extra(pool.get_data1(resource as NodeId)) as NodeId)
    let repr = facade_render_unalias(pool, intern, repr_text)
    let prefixes = facade_render_prefix_names(pool, intern, resource)
    let extra_start = pool.get_data1(resource as NodeId)
    for k in 0..pool.get_data2(resource as NodeId):
        let clause = pool.get_extra(extra_start + 1 + k)
        let kind = pool.get_data0(clause as NodeId)
        let ops = pool.get_data1(clause as NodeId)
        if kind != FACADE_CLAUSE_FROM and kind != FACADE_CLAUSE_INIT and kind != FACADE_CLAUSE_DESTROYS:
            continue
        let cname: str = intern.resolve(pool.get_extra(ops))
        var names = prefixes.clone()
        if kind == FACADE_CLAUSE_FROM:
            // A resource made from a parent: the parent's prefix too.
            let decl = facade_render_find_fn(pool, intern, ci, pool.get_extra(ops))
            let parent = if decl != 0: facade_render_receiver(pool, intern, decl) else: 0
            if parent > 0:
                let more = facade_render_prefix_names(pool, intern, parent)
                for mi in 0..more.len() as i32:
                    names.push(more[mi].clone())
        let role = if kind == FACADE_CLAUSE_DESTROYS: "a destroying method" else: "a constructor"
        s = facade_render_surface_add(s, cname, &names, facade_render_item_rename(pool, intern, cname), role)
    s = facade_render_surface_push(s, "", "drop", true, "the resource's Drop")
    if facade_render_is_c_string_ptr(repr):
        s = facade_render_surface_push(s, "", facade_render_text_view_name(), true, "the text view")
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        let li = facade_render_lend_item(pool, intern, ci, items[i])
        if not facade_render_lend_hosted(pool, intern, &li, resource, repr):
            continue
        let cname: str = intern.resolve(pool.get_data0(li.decl as NodeId))
        var rename: str = ""
        if li.rename != 0: rename = intern.resolve(li.rename)
        s = facade_render_surface_add(s, cname, &prefixes, rename, "a lend method")
    for i in 0..items.len() as i32:
        let cb = facade_render_callback_item(pool, intern, ci, items[i])
        if not facade_render_callback_hosted(pool, intern, &cb, resource, repr):
            continue
        let cname: str = intern.resolve(pool.get_data0(cb.decl as NodeId))
        var rename: str = ""
        if cb.rename != 0: rename = intern.resolve(cb.rename)
        s = facade_render_surface_add(s, cname, &prefixes, rename, "a callback method")
    let resources = facade_render_all_items(pool, NodeKind.NK_FACADE_RESOURCE)
    for ri in 0..resources.len() as i32:
        let other = resources[ri]
        if other == resource:
            continue
        let ostart = pool.get_data1(other as NodeId)
        for k in 0..pool.get_data2(other as NodeId):
            let clause = pool.get_extra(ostart + 1 + k)
            if pool.get_data0(clause as NodeId) != FACADE_CLAUSE_FROM:
                continue
            let psym = pool.get_extra(pool.get_data1(clause as NodeId))
            let decl = facade_render_find_fn(pool, intern, ci, psym)
            if decl == 0 or facade_render_receiver(pool, intern, decl) != resource:
                continue
            let child: str = intern.resolve(pool.get_data0(other as NodeId))
            let cname: str = intern.resolve(psym)
            s = facade_render_surface_add(s, cname, &prefixes, facade_render_item_rename(pool, intern, cname), f"the producer of '{child}'")
    s

fn facade_render_surface_add(s0: FacadeSurface, cname: &str, prefixes: &Vec[str], rename: &str, role: &str) -> FacadeSurface:
    if rename.len() > 0:
        return facade_render_surface_push(s0, cname, rename, true, role)
    let short = facade_render_shorten(cname, prefixes)
    if short.len() == 0:
        return facade_render_surface_push(s0, cname, cname, true, role)
    facade_render_surface_push(s0, cname, short, false, role)

fn facade_render_surface_push(s0: FacadeSurface, cname: &str, name: &str, explicit: bool, role: &str) -> FacadeSurface:
    var s = s0
    s.cnames.push(cname.clone())
    s.names.push(name.clone())
    s.explicit.push(explicit)
    s.roles.push(role.clone())
    s

// The struct names a resource's operations may be shortened by: the
// representation as the facade spells it and as c_import declares it
// beneath its aliases (zlib's `z_streamp` names `z_stream`).
fn facade_render_prefix_names(pool: AstPool, intern: InternPool, resource: i32) -> Vec[str]:
    let spelled = render_type_expr(pool, intern, pool.get_extra(pool.get_data1(resource as NodeId)) as NodeId)
    let out: Vec[str] = Vec.new()
    let a = facade_render_struct_name(spelled)
    if a.len() > 0:
        out.push(a)
    let b = facade_render_struct_name(facade_render_unalias(pool, intern, spelled))
    if b.len() > 0 and (out.len() == 0 or out[0] != b):
        out.push(b)
    out

// The struct name beneath one level of pointer, or "" for a shape with no
// name to shorten by (a C string, a pointer to a pointer, `void *`).
fn facade_render_struct_name(text: &str) -> str:
    var t: str = text.clone()
    if t.starts_with("*mut "): t = t.slice(5, t.len())
    else if t.starts_with("*const "): t = t.slice(7, t.len())
    if t.starts_with("*") or t.starts_with("[") or t.starts_with("fn(") or t == "c_void" or t == "i8" or t == "c_char" or t == "u8":
        return ""
    t

// `cname` less the longest matching prefix (§16.2a: the struct name in
// snake case, `GHashTable` → `g_hash_table_`, or case-insensitively as
// `Struct_`), or "" when none matches, the remainder is not an identifier,
// or it is a With keyword or `drop`.
//
// The library prefix (#1610): a C library names its types and its
// functions under one prefix, and an operation of a resource carries the
// library's, not the struct's — `sqlite3_step(sqlite3_stmt *)`,
// `curl_easy_perform(CURL *)`, `inflate(z_streamp)`. So each snake-case
// component prefix of the struct name is tried too (`sqlite3_stmt` →
// `sqlite3_`; `g_hash_table` → `g_hash_`, `g_`), and the longest matching
// prefix wins. Being wrong here changes a spelling (§54), and a clash
// between two operations still fails closed (facade_render_present).
fn facade_render_shorten(cname: &str, names: &Vec[str]) -> str:
    var best = ""
    for i in 0..names.len() as i32:
        let sname = names[i]
        let snake = ci_compute_snake_prefix(sname)
        var m = ci_strip_snake_prefix(cname, snake)
        if m.len() == 0:
            m = ci_strip_struct_prefix(cname, sname)
        if m.len() > 0 and (best.len() == 0 or m.len() < best.len()):
            best = m
        // `snake` ends with the `_` that closes the struct name; every
        // earlier `_` closes a library prefix.
        var end = snake.len() as i32 - 1
        while end > 0:
            end = end - 1
            if snake[end] != '_':
                continue
            let lib = ci_strip_snake_prefix(cname, snake.slice(0, end + 1))
            if lib.len() > 0 and (best.len() == 0 or lib.len() < best.len()):
                best = lib
    if best.len() == 0 or keyword_lookup(best) >= 0:
        return ""
    let c0 = best[0]
    if not ((c0 >= 'a' and c0 <= 'z') or (c0 >= 'A' and c0 <= 'Z') or c0 == '_'):
        return ""
    best

// The `rename` an fn item states for the C function `cname`, or "".
fn facade_render_item_rename(pool: AstPool, intern: InternPool, cname: &str) -> str:
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        let item = items[i]
        let have: str = intern.resolve(pool.get_data0(item as NodeId))
        if have != cname:
            continue
        let cstart = pool.get_data1(item as NodeId)
        for k in 0..pool.get_data2(item as NodeId):
            let clause = pool.get_extra(cstart + k)
            if pool.get_data0(clause as NodeId) == FACADE_CLAUSE_RENAME:
                let renamed: str = intern.resolve(pool.get_extra(pool.get_data1(clause as NodeId)))
                return renamed
    ""

// The resource an operation's first parameter receives — one resource a
// borrow `&P` can hand to C (facade_render_received_arg) — or 0: the
// receiver of `db.prepare(sql)`.
fn facade_render_receiver(pool: AstPool, intern: InternPool, decl: i32) -> i32:
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0 or pool.fn_meta_param_count(meta) == 0:
        return 0
    let p0 = render_type_expr(pool, intern, pool.fn_param_type(pool.fn_meta_param_start(meta), 0) as NodeId)
    let res = facade_render_received(pool, intern, p0)
    if res <= 0 or facade_render_received_arg(pool, intern, res, p0, "self").len() == 0:
        return 0
    res

// A producer received through a parent, presented as a method of the parent
// (ruling §54: `sqlite3_prepare_v2(db, …)` "may be presented as
// `db.prepare(...)`"), delegating to the constructor so the two spellings
// share one body:
//
//     impl Database:
//         fn prepare(sql: &str) -> Result[Statement, StatementError]: Statement.prepare(self, sql)
//
// `slot` is the out parameter withheld from the constructor (-1 for a direct
// return). Sema puts the constructor's declared dependency summary on this
// method too (apply_facade_dependency_effects).
fn facade_render_receiver_method(pool: AstPool, intern: InternPool, ci: &Vec[i32], child: i32, producer: i32, slot: i32, ctor: &str, result: &str) -> str:
    let parent = facade_render_receiver(pool, intern, producer)
    if parent <= 0:
        return ""
    let pname: str = intern.resolve(pool.get_data0(parent as NodeId))
    let cname: str = intern.resolve(pool.get_data0(producer as NodeId))
    let mname = facade_render_present(pool, intern, ci, parent, cname)
    let (params, _) = facade_render_params_but(pool, intern, producer, 1, slot, "")
    let meta = pool.find_fn_meta(producer as NodeId)
    let start = pool.fn_meta_param_start(meta)
    var args = "self"
    for pi in 1..pool.fn_meta_param_count(meta):
        // A fixed argument (D64) is the constructor's literal, not a
        // parameter the receiver method forwards.
        if pi != slot and facade_render_fixed_literal(pool, intern, producer, pi).len() == 0:
            args = args ++ ", " ++ facade_render_param_name(pool, intern, start, pi)
    let child_name: str = intern.resolve(pool.get_data0(child as NodeId))
    "impl " ++ pname ++ ":\n    fn " ++ mname ++ "(" ++ params ++ ") -> " ++ result ++ ": " ++ child_name ++ "." ++ ctor ++ "(" ++ args ++ ")\n"

// Whether `cname` is an operation some resource clause names (`from`,
// `init`, `preinit`, `drop`, `destroys`): an fn item describing one adds
// facts to that operation and is not a lend method beside its constructor.
fn facade_render_is_resource_op(pool: AstPool, intern: InternPool, cname: &str) -> bool:
    let resources = facade_render_all_items(pool, NodeKind.NK_FACADE_RESOURCE)
    for ri in 0..resources.len() as i32:
        let res = resources[ri]
        let extra_start = pool.get_data1(res as NodeId)
        for k in 0..pool.get_data2(res as NodeId):
            let clause = pool.get_extra(extra_start + 1 + k)
            let kind = pool.get_data0(clause as NodeId)
            if kind != FACADE_CLAUSE_FROM and kind != FACADE_CLAUSE_INIT and kind != FACADE_CLAUSE_PREINIT and kind != FACADE_CLAUSE_DROP and kind != FACADE_CLAUSE_DESTROYS:
                continue
            let have: str = intern.resolve(pool.get_extra(pool.get_data1(clause as NodeId)))
            if have == cname:
                return true
    false

// An fn item read as a lend: its declaration (0 when none), its `of` and
// `rename`, whether it states nothing stronger than a lend, and what it
// returns borrowed.
type FacadeLendItem {
    decl: i32,
    of_sym: i32,
    rename: i32,
    lends: bool,
    borrow_res: i32,
    borrow_from: i32,
    text_view: bool,
    valid_on_failed: bool,   // rendered on `Failed<R>` too (#1612)
    bridged: bool,           // states a buffer pairing, a fixed argument or an `ok` (D64)
}

fn facade_render_lend_item(pool: AstPool, intern: InternPool, ci: &Vec[i32], item: i32) -> FacadeLendItem:
    var li = FacadeLendItem { decl: 0, of_sym: 0, rename: 0, lends: true, borrow_res: 0, borrow_from: 0, text_view: false, valid_on_failed: false, bridged: false }
    let cstart = pool.get_data1(item as NodeId)
    for k in 0..pool.get_data2(item as NodeId):
        let clause = pool.get_extra(cstart + k)
        let kind = pool.get_data0(clause as NodeId)
        let ops = pool.get_data1(clause as NodeId)
        if kind == FACADE_CLAUSE_OF: li.of_sym = pool.get_extra(ops)
        else if kind == FACADE_CLAUSE_RENAME: li.rename = pool.get_extra(ops)
        else if kind == FACADE_CLAUSE_RETURNS_BORROW:
            li.borrow_res = pool.get_extra(ops)
            li.borrow_from = pool.get_extra(ops + 1)
            if intern.resolve(li.borrow_res) == "CStr":
                li.text_view = true
                li.borrow_res = 0
        else if kind == FACADE_CLAUSE_RETURNS_STATIC:
            // `returns static CStr` (ruling §40): a text view of static
            // storage, no origin to keep it inside.
            if render_type_expr(pool, intern, pool.get_extra(ops) as NodeId) == "CStr": li.text_view = true
            else: li.lends = false
        else if kind == FACADE_CLAUSE_VALID_ON_FAILED: li.valid_on_failed = true
        // A buffer pairing, a fixed argument and the status contract of a
        // copied-back length (D64) describe the lend's presented call
        // (facade_render_bridge); they make nothing stronger than a lend.
        else if kind == FACADE_CLAUSE_BUFFER or kind == FACADE_CLAUSE_FIXED or kind == FACADE_CLAUSE_OK: li.bridged = true
        else if kind != FACADE_CLAUSE_LEND and kind != FACADE_CLAUSE_PRESERVES: li.lends = false
    if not li.lends:
        return li
    let cname: str = intern.resolve(pool.get_data0(item as NodeId))
    if facade_render_is_resource_op(pool, intern, cname):
        li.lends = false
        return li
    li.decl = facade_render_find_fn(pool, intern, ci, pool.get_data0(item as NodeId))
    li

// Whether the lend item is a method of `resource` (whose unaliased
// representation is `repr`): its first parameter takes the representation —
// a pointer resource's handle, or an in-place resource's storage by address
// — and the resource is the one its `of` names, or the only one wrapping
// the representation (§16.2b.3; an unassigned item on a representation
// several resources wrap is Sema's error, verify_facade_assignments).
fn facade_render_lend_hosted(pool: AstPool, intern: InternPool, li: &FacadeLendItem, resource: i32, repr: &str) -> bool:
    if not li.lends or li.decl == 0 or facade_render_param_count(pool, li.decl) == 0:
        return false
    let meta = pool.find_fn_meta(li.decl as NodeId)
    let p0 = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.fn_param_type(pool.fn_meta_param_start(meta), 0) as NodeId))
    let in_place = not repr.starts_with("*") and facade_render_has_clause(pool, resource, FACADE_CLAUSE_INIT)
    if repr.starts_with("*"):
        if p0 != repr and not facade_render_const_of(p0, repr):
            return false
    else if in_place:
        if p0 != "*mut " ++ repr and p0 != "*const " ++ repr:
            return false
    else:
        return false
    if li.of_sym != 0:
        let of_name: str = intern.resolve(li.of_sym)
        let rname: str = intern.resolve(pool.get_data0(resource as NodeId))
        return of_name == rname
    facade_render_resources_wrapping(pool, intern, repr) == 1

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

fn facade_render_resource(pool: AstPool, intern: InternPool, ci: &Vec[i32], item: i32, methods: &str, plain_methods: &str, failed_methods: &str) -> str:
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
    // Stage 9 (ruling §45, spec §16.2b.9): userdata a callback method
    // retains is kept by the resource — each value in its own Box cell,
    // handed to C as the pointer, and released after the resource is
    // destroyed (facade_render_callback_methods) — in two parallel Vecs:
    // the cells and the one destroy fn per cell that knows its type.
    let keeps = facade_render_resource_keeps_userdata(pool, intern, ci, item, facade_render_unalias(pool, intern, repr_text))
    let keep_fields = if keeps: ", retained_ptrs: Vec[*mut c_void], retained_frees: Vec[extern \"C\" fn(*mut c_void) -> Unit]" else: ""
    let keep_init = if keeps: "retained_ptrs: Vec.new(), retained_frees: Vec.new(), " else: ""
    // A dependent resource is an ephemeral struct carrying a view of each
    // parent (the plan's `ephemeral { parent: &P, repr }`): the ordinary
    // origin and ephemeral-value analysis (§21.1, §22) then keeps it from
    // outliving, or being stored past, what it depends on, drops it before
    // its parents, and refuses a parent's move or destruction while it lives.
    // No reference count or generation check is added (ruling §29).
    var out = if deps.slot_res.len() > 0: "type " ++ name ++ " = ephemeral { " ++ facade_render_dep_fields(pool, intern, &deps) ++ "repr: " ++ field ++ ", live: bool" ++ keep_fields ++ " }\n" else: "type " ++ name ++ " { repr: " ++ field ++ ", live: bool" ++ keep_fields ++ " }\n"
    if drop_fn != 0:
        out = out ++ "impl Drop for " ++ name ++ ":\n    move fn drop():\n        if self.live: " ++ facade_render_call(pool, intern, drop_fn, facade_render_repr_arg(pool, intern, drop_fn, repr_text, "self.repr", pinned)) ++ "\n"
        if keeps:
            // The retaining origin never outlives what it retains (§25):
            // the destroyer has run; now the retained values are released.
            out = out ++ "        for facade_i in 0..self.retained_ptrs.len():\n            let facade_free = self.retained_frees.get(facade_i)\n            facade_free(self.retained_ptrs[facade_i])\n"
    if destroyers.len() > 0 or methods.len() > 0:
        out = out ++ "impl " ++ name ++ ":\n" ++ methods
        for di in 0..destroyers.len() as i32:
            let d = destroyers[di]
            let dname = facade_render_present(pool, intern, ci, item, intern.resolve(pool.get_data0(d as NodeId)))
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
        out = out ++ facade_render_error_type(pool, intern, name, repr_text, status_type, failed_state, failed_state and not dependent, drop_fn, failed_methods)
    // Borrowed returns of this resource (ruling §26): `Borrowed<R>`.
    out = out ++ facade_render_borrowed_type(pool, intern, ci, item, repr_text, plain_methods)
    for pi in 0..producers.len() as i32:
        let producer = producers[pi]
        if producer == 0:
            continue
        // The constructor's presented name (§16.2b.11): the C name less the
        // resource's prefix, or the parent's for a resource made from one.
        let pname = facade_render_present(pool, intern, ci, item, intern.resolve(pool.get_data0(producer as NodeId)))
        let made_deps = facade_render_dep_values(pool, intern, &deps, pi, producer) ++ keep_init
        if out_refs[pi] != 0:
            let slot = facade_render_param_ref(pool, intern, producer, out_refs[pi])
            if slot < 0:
                continue
            let (ctor, result) = facade_render_out_producer(pool, intern, name, repr_text, producer, pname, slot, ok_sym, made_deps, drop_fn)
            out = out ++ ctor ++ facade_render_receiver_method(pool, intern, ci, item, producer, slot, pname, result)
            continue
        let (params, args) = facade_render_params_but(pool, intern, producer, 0, -1, "")
        let call = facade_render_call(pool, intern, producer, args)
        var result = name.clone()
        if facade_render_unalias(pool, intern, repr_text).starts_with("*"):
            // Unknown nullability is nullable, never silently non-null
            // (§16.2b.8): a pointer producer yields `Option[R]`, and a NULL
            // produced nothing — no Drop is armed over it (§16.2b.4). The
            // facade's `from` is the trusted evidence that a non-null return
            // is the produced resource (§16.2b.4, ruling §19).
            result = "Option[" ++ name ++ "]"
            let repr = facade_render_fresh("repr", facade_render_param_names(pool, intern, producer))
            out = out ++ "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ") -> " ++ result ++ ":\n    let " ++ repr ++ " = " ++ call ++ "\n    if " ++ repr ++ " == null: None else: Some(" ++ name ++ " { " ++ made_deps ++ "repr: " ++ repr ++ ", live: true })\n"
        else:
            out = out ++ "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ") -> " ++ result ++ ":\n    " ++ name ++ " { " ++ made_deps ++ "repr: " ++ call ++ ", live: true }\n"
        out = out ++ facade_render_receiver_method(pool, intern, ci, item, producer, -1, pname, result)
    if init_fn != 0:
        let iname = facade_render_present(pool, intern, ci, item, intern.resolve(pool.get_data0(init_fn as NodeId)))
        let ctor = facade_render_init(pool, intern, name, repr_text, init_fn, iname, preinit_fn, ok_sym, pinned, facade_render_dep_values(pool, intern, &deps, FACADE_DEP_INIT, init_fn) ++ keep_init)
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
        if p == repr or p == "*mut " ++ repr or p == "*const " ++ repr or facade_render_const_of(p, repr):
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
    if facade_render_const_of(p, repr):
        return place ++ ".repr as " ++ p
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
// The constructor is named after the C initializer under its presented name
// `iname` (§16.2b.11, facade_render_present: `Counter.init` for
// `counter_init` on `Counter`, `Stream.inflateInit` where no prefix matches,
// or its `rename`).
fn facade_render_init(pool: AstPool, intern: InternPool, name: &str, repr_text: &str, init_fn: i32, iname: &str, preinit_fn: i32, ok_sym: i32, pinned: bool, deps: &str) -> str:
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
// apart from the parameters (facade_render_fresh). The constructor is
// `R.<pname>`, the producer's presented name (§16.2b.11: `Database.open`
// for `sqlite3_open`, or its `rename`). Returns the constructor and its
// result type, which the receiver method repeats.
fn facade_render_out_producer(pool: AstPool, intern: InternPool, name: &str, repr_text: &str, producer: i32, pname: &str, slot: i32, ok_sym: i32, deps: &str, drop_fn: i32) -> (str, str):
    let taken = facade_render_param_names(pool, intern, producer)
    let slot_var = facade_render_fresh("slot", taken)
    let (params, args) = facade_render_params_but(pool, intern, producer, 0, slot, "&raw mut " ++ slot_var)
    let call = facade_render_call(pool, intern, producer, args)
    let made = name ++ " { " ++ deps ++ "repr: " ++ slot_var ++ ", live: true }"
    let head = "fn " ++ name ++ "." ++ pname ++ "(" ++ params ++ ")"
    let null_slot = "    var " ++ slot_var ++ ": " ++ repr_text ++ " = null\n"
    let ret = facade_render_return(pool, intern, producer)
    if ret.len() == 0:
        let result = "Option[" ++ name ++ "]"
        return (head ++ " -> " ++ result ++ ":\n" ++ null_slot ++ "    " ++ call ++ "\n    if " ++ slot_var ++ " == null: None else: Some(" ++ made ++ ")\n", result)
    let status = facade_render_fresh("status", taken)
    if ok_sym == 0:
        let result = "(" ++ ret.slice(4, ret.len()) ++ ", Option[" ++ name ++ "])"
        return (head ++ " -> " ++ result ++ ":\n" ++ null_slot ++ "    let " ++ status ++ " = " ++ call ++ "\n    (" ++ status ++ ", if " ++ slot_var ++ " == null: None else: Some(" ++ made ++ "))\n", result)
    let err = facade_render_error_name(name)
    let result = "Result[" ++ name ++ ", " ++ err ++ "]"
    var out = head ++ " -> " ++ result ++ ":\n" ++ null_slot ++ "    let " ++ status ++ " = " ++ call ++ "\n"
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
    (out ++ "    Ok(" ++ made ++ ")\n", result)

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
// failure state admits only the operations the facade marks `valid on
// failed` (stage 12b, #1612; spec §16.2b.4) — the lends and text views of
// `R` so marked, rendered here over the same `repr` field under the names
// they have on `R` — and otherwise only raw access to its representation
// under the raw C rules: no destroyers, no callbacks, no unmarked lend. Its
// Drop runs the facade's `drop` exactly once: dropping the error, or
// whatever took the resource out of it, destroys it.
//
//     type FailedDatabase { repr: *mut sqlite3 }
//     impl Drop for FailedDatabase:
//         move fn drop():
//             unsafe { sqlite3_close(self.repr) }
//     impl FailedDatabase:
//         fn errmsg() -> Option[CStr]: …                 // `valid on failed`
fn facade_render_error_type(pool: AstPool, intern: InternPool, name: &str, repr_text: &str, status_type: &str, out_param: bool, failed_state: bool, drop_fn: i32, failed_methods: &str) -> str:
    let err = facade_render_error_name(name)
    var out = ""
    if failed_state:
        let failed = facade_render_failed_name(name)
        out = "type " ++ failed ++ " { repr: " ++ repr_text ++ " }\nimpl Drop for " ++ failed ++ ":\n    move fn drop():\n        " ++ facade_render_call(pool, intern, drop_fn, facade_render_repr_arg(pool, intern, drop_fn, repr_text, "self.repr", false)) ++ "\n"
        if failed_methods.len() > 0:
            out = out ++ "impl " ++ failed ++ ":\n" ++ failed_methods
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
    if facade_render_const_of(p0, repr): return place ++ " as " ++ p0
    if (p0 == "*mut c_void" or p0 == "*const c_void") and repr.starts_with("*"): return place ++ " as " ++ p0
    if p0 == "*mut " ++ repr: return if pinned: place ++ ".as_mut_ptr()" else: "&raw mut " ++ place
    if p0 == "*const " ++ repr: return if pinned: place ++ ".as_ptr()" else: "&raw const " ++ place
    ""

// C converts a `T *` to a `const T *` on its own: a `*const T` parameter
// receives a `*mut T` handle (Sema: facade_param_matches_repr).
fn facade_render_const_of(p: &str, repr: &str) -> bool: repr.starts_with("*mut ") and not facade_render_is_c_string_ptr(repr) and p == "*const " ++ repr.slice(5, repr.len())

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
    let bridge = facade_render_bridge(pool, intern, decl, skip, slot, slot_arg)
    (bridge.params.clone(), bridge.args.clone())

// ── D64: buffer pairing and fixed arguments (§16.2b.8, §16.2b.11) ──────
//
// The presented call's parameters, arguments and the prologue that makes
// them: a fixed argument (`param N fixed <literal>`) leaves the parameter
// list and its literal is passed; a buffer pairing (`buffer param P len
// param L`) presents P and L as one `[]u8` — `[]mut u8` for `capacity …
// inout` — passing the slice's pointer (null for an empty slice) and its
// byte length; an inout capacity is a local the bridge initializes to the
// slice's length and hands C the address of (`cap_var`), so the caller's
// slice is never modified (D64). The body around the call is
// facade_render_bridge_body. `ok` is false when a clause names a parameter
// the declaration does not have — Sema's error — and the item renders
// nothing.
type FacadeBridge {
    ok: bool,
    params: str,
    args: str,
    prologue: str,     // lines, each newline-terminated, unindented
    cap_var: str,      // the inout capacity local, or ""
    cap_type: str,     // its C integer type
    cap_of: str,       // the []mut u8 parameter it is the capacity of
}

// The fn item describing the C function the declaration `decl` names, in
// any facade block, or 0.
fn facade_render_fn_item(pool: AstPool, intern: InternPool, decl: i32) -> i32:
    let want: str = intern.resolve(pool.get_data0(decl as NodeId))
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        if intern.resolve(pool.get_data0(items[i] as NodeId)) == want:
            return items[i]
    0

// The literal `param N fixed <literal>` binds to parameter `pi`, as source
// text, or "" when the parameter is not fixed.
fn facade_render_fixed_literal(pool: AstPool, intern: InternPool, decl: i32, pi: i32) -> str:
    let item = facade_render_fn_item(pool, intern, decl)
    if item == 0:
        return ""
    let cstart = pool.get_data1(item as NodeId)
    for k in 0..pool.get_data2(item as NodeId):
        let clause = pool.get_extra(cstart + k)
        if pool.get_data0(clause as NodeId) != FACADE_CLAUSE_FIXED:
            continue
        let ops = pool.get_data1(clause as NodeId)
        if facade_render_param_ref(pool, intern, decl, pool.get_extra(ops)) != pi:
            continue
        return facade_render_literal(pool, pool.get_extra(ops + 1))
    ""

fn facade_render_literal(pool: AstPool, node: i32) -> str:
    let kind = pool.kind(node as NodeId)
    if kind == NodeKind.NK_NULL_LIT: return "null"
    if kind == NodeKind.NK_BOOL_LIT: return if pool.get_data0(node as NodeId) != 0: "true" else: "false"
    if kind == NodeKind.NK_INT_LIT: return f"{pool.int_lit_value(node as NodeId)}"
    if kind == NodeKind.NK_UNARY and pool.get_data0(node as NodeId) == UnaryOp.UOP_NEGATE: return "-" ++ facade_render_literal(pool, pool.get_data1(node as NodeId))
    ""

// The buffer pairing parameter `pi` takes part in: (the pointer parameter,
// the length parameter, inout), or (-1, -1, 0).
fn facade_render_buffer_of(pool: AstPool, intern: InternPool, decl: i32, pi: i32) -> (i32, i32, i32):
    let item = facade_render_fn_item(pool, intern, decl)
    if item == 0:
        return (-1, -1, 0)
    let cstart = pool.get_data1(item as NodeId)
    for k in 0..pool.get_data2(item as NodeId):
        let clause = pool.get_extra(cstart + k)
        if pool.get_data0(clause as NodeId) != FACADE_CLAUSE_BUFFER:
            continue
        let ops = pool.get_data1(clause as NodeId)
        let p = facade_render_param_ref(pool, intern, decl, pool.get_extra(ops))
        let l = facade_render_param_ref(pool, intern, decl, pool.get_extra(ops + 1))
        if p == pi or l == pi:
            return (p, l, pool.get_extra(ops + 2))
    (-1, -1, 0)

fn facade_render_bridge(pool: AstPool, intern: InternPool, decl: i32, skip: i32, slot: i32, slot_arg: &str) -> FacadeBridge:
    var b = FacadeBridge { ok: true, params: "", args: "", prologue: "", cap_var: "", cap_type: "", cap_of: "" }
    let meta = pool.find_fn_meta(decl as NodeId)
    if meta < 0:
        return b
    let start = pool.fn_meta_param_start(meta)
    let taken = facade_render_param_names(pool, intern, decl)
    for pi in skip..pool.fn_meta_param_count(meta):
        if b.args.len() > 0:
            b.args = b.args ++ ", "
        if pi == slot:
            b.args = b.args ++ slot_arg
            continue
        let fixed = facade_render_fixed_literal(pool, intern, decl, pi)
        if fixed.len() > 0:
            b.args = b.args ++ fixed
            continue
        let pname = facade_render_param_name(pool, intern, start, pi)
        let ptype = render_type_expr(pool, intern, pool.fn_param_type(start, pi) as NodeId)
        let (bp, bl, inout) = facade_render_buffer_of(pool, intern, decl, pi)
        if bp < 0 and bl >= 0 or bl < 0 and bp >= 0:
            b.ok = false
            return b
        if bp == pi:
            // The pointer: one slice parameter, whose address C receives.
            let slicety = if inout != 0: "[]mut u8" else: "[]u8"
            let addr = if inout != 0: "&raw mut " ++ pname ++ "[0]" else: "&raw const " ++ pname ++ "[0]"
            let local = facade_render_fresh(pname ++ "_ptr", taken)
            b.prologue = b.prologue ++ "let " ++ local ++ ": " ++ ptype ++ " = if " ++ pname ++ ".len() == 0: null else: " ++ addr ++ " as " ++ ptype ++ "\n"
            if b.params.len() > 0:
                b.params = b.params ++ ", "
            b.params = b.params ++ pname ++ ": " ++ slicety
            b.args = b.args ++ local
            continue
        if bl == pi:
            let bname = facade_render_param_name(pool, intern, start, bp)
            if inout == 0:
                b.args = b.args ++ "(" ++ bname ++ ".len() as " ++ ptype ++ ")"
                continue
            // The capacity C reads and writes back: the bridge's own local,
            // never the caller's slice length.
            let unaliased = facade_render_unalias(pool, intern, ptype)
            if not unaliased.starts_with("*mut "):
                b.ok = false
                return b
            let cap_type = unaliased.slice(5, unaliased.len())
            b.cap_var = facade_render_fresh("capacity", taken)
            b.cap_type = cap_type.clone()
            b.cap_of = bname.clone()
            b.prologue = b.prologue ++ "var " ++ b.cap_var ++ ": " ++ cap_type ++ " = " ++ bname ++ ".len() as " ++ cap_type ++ "\n"
            b.args = b.args ++ "&raw mut " ++ b.cap_var
            continue
        // A `const char *` input is lent (§16.3c, D47), so the rendering
        // observes it as `&str` (§3.8: a function that observes takes `&T`);
        // a plain `str` would consume the caller's string. A text view
        // borrowed from it (`returns borrow CStr from param N`) depends on
        // the caller's string through that borrow.
        var shown = if ptype == "*const i8" or ptype == "*const c_char": "&str" else: ptype.clone()
        var arg = pname.clone()
        let res = facade_render_received(pool, intern, ptype)
        if res > 0:
            let received = facade_render_received_arg(pool, intern, res, ptype, pname)
            if received.len() > 0:
                let rname: str = intern.resolve(pool.get_data0(res as NodeId))
                shown = "&" ++ rname
                arg = received
        if b.params.len() > 0:
            b.params = b.params ++ ", "
        b.params = b.params ++ pname ++ ": " ++ shown
        b.args = b.args ++ arg
    b

// Each line of `text` prefixed with `indent`.
fn facade_render_indent(text: &str, indent: &str) -> str:
    var out = ""
    var start = 0
    while start < text.len() as i32:
        var end = start
        while end < text.len() as i32 and text[end] != '\n': end = end + 1
        out = out ++ indent ++ text.slice(start, end) ++ "\n"
        start = end + 1
    out

// The lines around the presented call `call` (D64, §16.2b.8), each indented
// by `indent`, and the rendered return type. Without an inout capacity the
// call is the body, returning what C returns. With one, the length C wrote
// back is bounds-checked against the capacity before it becomes a With
// value, and presented as the `usize` result — on success only: under the
// item's `ok CONST` the status is read first and a failure is
// `Err(<Fn>Error.Failed(status))`; an operation returning nothing always
// succeeded. A length beyond the capacity is C breaking its contract, and
// a runtime failure naming the operation and the length, never a trust.
fn facade_render_bridge_body(pool: AstPool, intern: InternPool, decl: i32, b: &FacadeBridge, call: &str, presented: &str, indent: &str) -> (str, str):
    if b.cap_var.len() == 0:
        return (facade_render_return(pool, intern, decl), indent ++ call ++ "\n")
    let ok_sym = facade_render_fn_ok(pool, intern, decl)
    let check = indent ++ "if " ++ b.cap_var ++ " > " ++ b.cap_of ++ ".len() as " ++ b.cap_type ++ ": panic(f\"" ++ presented ++ ": C reported {" ++ b.cap_var ++ "} bytes written into a buffer of {" ++ b.cap_of ++ ".len()} bytes (§16.2b.8)\")\n"
    let result = indent ++ b.cap_var ++ " as usize\n"
    if ok_sym == 0:
        return (" -> usize", indent ++ call ++ "\n" ++ check ++ result)
    let err = facade_render_fn_error_name(presented)
    let status = facade_render_fresh("status", facade_render_param_names(pool, intern, decl))
    var body = indent ++ "let " ++ status ++ " = " ++ call ++ "\n"
    body = body ++ indent ++ "if " ++ status ++ " != " ++ intern.resolve(ok_sym) ++ ": return Err(" ++ err ++ ".Failed(" ++ status ++ "))\n"
    (" -> Result[usize, " ++ err ++ "]", body ++ check ++ result)

// The `ok CONST` an fn item states for the declaration, or 0.
fn facade_render_fn_ok(pool: AstPool, intern: InternPool, decl: i32) -> i32:
    let item = facade_render_fn_item(pool, intern, decl)
    if item == 0:
        return 0
    let cstart = pool.get_data1(item as NodeId)
    for k in 0..pool.get_data2(item as NodeId):
        let clause = pool.get_extra(cstart + k)
        if pool.get_data0(clause as NodeId) == FACADE_CLAUSE_OK:
            return pool.get_extra(pool.get_data1(clause as NodeId))
    0

// The rendered name of a free operation presented under its C name.
pub fn facade_render_bridge_name(cname: &str) -> str: "__with_facade_" ++ cname

// `<Fn>Error`: the error type of a presented operation's `ok` projection,
// named after its presented name (`compress` → `CompressError`).
pub fn facade_render_fn_error_name(presented: &str) -> str:
    if presented.len() == 0: return "Error"
    presented.slice(0, 1).to_upper() ++ presented.slice(1, presented.len()) ++ "Error"

// The error type an inout operation under `ok` returns: `Failed` alone —
// nothing is produced, so there is no resource to own.
fn facade_render_fn_error_type(pool: AstPool, intern: InternPool, decl: i32, presented: &str) -> str:
    let ret = facade_render_return(pool, intern, decl)
    if ret.len() == 0:
        return ""
    "error " ++ facade_render_fn_error_name(presented) ++ " =\n    | Failed(status: " ++ ret.slice(4, ret.len()) ++ ")\n"

// The free operations a facade block presents (D64): each fn item stating a
// buffer pairing or a fixed argument whose first parameter takes no
// resource's representation is rendered as an ordinary function — under
// its `rename`, or, presented under the C name, as `__with_facade_<name>`,
// which a call to the C name reaches wherever the rendering is visible
// (SemaFacade.w facade_bridge_redirect). The raw declaration stays what C
// declared: the bridge's own body calls it, and a module that imports the
// header without the facade has the raw operation, under the raw rules.
//
//     error CompressError =
//         | Failed(status: c_int)
//     fn __with_facade_compress(dest: []mut u8, source: []u8) -> Result[usize, CompressError]:
//         let dest_ptr: *mut Bytef = if dest.len() == 0: null else: &raw mut dest[0] as *mut Bytef
//         var capacity: uLongf = dest.len() as uLongf
//         let source_ptr: *const Bytef = if source.len() == 0: null else: &raw const source[0] as *const Bytef
//         let status = unsafe { compress(dest_ptr, &raw mut capacity, source_ptr, (source.len() as uLong)) }
//         if status != Z_OK: return Err(CompressError.Failed(status))
//         if capacity > dest.len() as uLongf: panic(...)
//         capacity as usize
fn facade_render_free_ops(pool: AstPool, intern: InternPool, ci: &Vec[i32], facade: i32) -> str:
    var out = ""
    let extra_start = pool.get_data1(facade as NodeId)
    let resources = facade_render_all_items(pool, NodeKind.NK_FACADE_RESOURCE)
    for i in 0..pool.get_data2(facade as NodeId):
        let item = pool.get_extra(extra_start + i)
        if pool.kind(item as NodeId) != NodeKind.NK_FACADE_FN:
            continue
        let li = facade_render_lend_item(pool, intern, ci, item)
        if not li.lends or not li.bridged or li.decl == 0 or li.text_view or li.borrow_res != 0:
            continue
        var hosted = false
        for ri in 0..resources.len() as i32:
            let repr = facade_render_unalias(pool, intern, render_type_expr(pool, intern, pool.get_extra(pool.get_data1(resources[ri] as NodeId)) as NodeId))
            if facade_render_lend_hosted(pool, intern, &li, resources[ri], repr):
                hosted = true
        if hosted:
            continue
        let decl = li.decl
        let cname: str = intern.resolve(pool.get_data0(decl as NodeId))
        let presented: str = intern.resolve(if li.rename != 0: li.rename else: pool.get_data0(decl as NodeId))
        let bridge = facade_render_bridge(pool, intern, decl, 0, -1, "")
        if not bridge.ok:
            continue
        if bridge.cap_var.len() > 0 and facade_render_fn_ok(pool, intern, decl) != 0:
            out = out ++ facade_render_fn_error_type(pool, intern, decl, presented)
        let rendered = if li.rename != 0: presented.clone() else: facade_render_bridge_name(cname)
        let (result, body) = facade_render_bridge_body(pool, intern, decl, &bridge, facade_render_call(pool, intern, decl, bridge.args), presented, "    ")
        out = out ++ "fn " ++ rendered ++ "(" ++ bridge.params ++ ")" ++ result ++ ":\n" ++ facade_render_indent(bridge.prologue, "    ") ++ body
    out

// The C parameter's name as a With parameter: less the translation's
// `__param_` mark, and escaped as the c_import wrappers escape it — an
// uppercase-initial name (sqlite3_column_name's `N`) is a pattern in a
// parameter list, so it is spelled `p_N` (ci_escape_param_name).
fn facade_render_param_name(pool: AstPool, intern: InternPool, start: i32, pi: i32) -> str:
    let pname: str = intern.resolve(pool.fn_param_name(start, pi))
    let bare: str = if pname.starts_with("__param_"): pname.slice(8, pname.len()) else: pname.clone()
    ci_escape_param_name(bare)

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

fn facade_render_type_is_raw(text: &str) -> bool: text.starts_with("*") or text.starts_with("&") or text.starts_with("[") or text.starts_with("fn(") or text.starts_with("extern") or text.starts_with("unsafe ")

// ── stage 9: callbacks (ruling §44-§47, spec §16.2b.9) ──────────────────
//
// A callback contract — an fn item that retains a callback or its userdata
// (`retains param N by param 0`), consumes userdata with a destroy callback
// (`consumes param N destroyed_by param M`), types a callback's userdata
// (`callback param N userdata param M`), or says `callback_thread any` — is
// a method of the resource its first parameter receives, generic in the
// userdata type `U` when the item names a userdata. For
//
//     int db_exec(db *d, db_cb cb, void *ud, int n);        // db_cb: int (*)(void *, int)
//     fn db_exec
//         callback param 1 userdata param 2
//
// the userdata is borrowed for the call (§44) and the callback receives it
// typed — captureless (§12.4: C receives the code pointer alone), so a
// closure's state lives in `U`:
//
//     fn exec[U](cb: extern "C" fn(&U, c_int) -> c_int, ud: &U, n: c_int) -> c_int:
//         unsafe { db_exec(self.repr, transmute[extern "C" fn(*mut c_void, c_int) -> c_int](cb), ud as *const U as *mut c_void, n) }
//
// Retained userdata (`retains param 2 by param 0`) is owned by the resource
// until it is destroyed (§45): boxed, handed to C as the cell's pointer,
// and released by the resource's Drop after its destroyer ran, through a
// destroy fn that knows `U` (a captureless closure over the type parameter):
//
//     mut fn register[U](cb: extern "C" fn(&U, c_int) -> c_int, app: U) -> c_int:
//         let facade_cell = Box.new(app)
//         let facade_ptr = facade_cell.into_raw() as *mut c_void
//         let facade_free: extern "C" fn(*mut c_void) -> Unit = facade_q => { let facade_b = (facade_q as *mut U) as Box[U]; drop(facade_b) }
//         self.retained_ptrs.push(facade_ptr)
//         self.retained_frees.push(facade_free)
//         unsafe { db_register(self.repr, transmute[…](cb), facade_ptr) }
//
// Consumed userdata (`consumes param 1 destroyed_by param 2`) moves into C
// (§24): boxed, handed over, and the destroy callback the contract names is
// withheld from the method — the compiler supplies the one that knows `U`.
// With never destroys it; C does, through that callback, exactly once:
//
//     fn set_owned[U](owned: U) -> c_int:
//         let facade_cell = Box.new(owned)
//         let facade_free: extern "C" fn(*mut c_void) -> Unit = …
//         unsafe { db_set_owned(self.repr, facade_cell.into_raw() as *mut c_void, facade_free) }
//
// A callback parameter the item does not pair with a userdata keeps C's
// type; a `void *` the item does not name stays `*mut c_void`. Reentrancy
// (§47) is by construction: the callback holds no captures, and reaches
// the userdata as `&U` — a read view for the call, or of a value the
// resource owns. What the generic method cannot state — under
// `callback_thread any` the userdata is Send and Sync (§51) — Sema checks
// at each call (SemaFacade.w facade_check_callback_arg). The rendered
// locals are spelled `facade_*` and apart from the C parameters: a local
// named `free` would resolve to libc's.

type FacadeCallbackItem {
    decl: i32,        // 0 when the item is not a callback contract
    of_sym: i32,
    rename: i32,
    userdata: i32,    // the userdata parameter (C index), or -1
    callback: i32,    // the callback parameter paired with cbi, or -1
    destroy: i32,     // the destroy callback a `consumes … destroyed_by` names (withheld), or -1
    retained: bool,
    consumed: bool,
    nullable: bool,   // the paired callback is `nullable` (#1618): `Option[extern "C" fn(&U, …)]`, its userdata `Option[&U]`
}

fn facade_render_callback_item(pool: AstPool, intern: InternPool, ci: &Vec[i32], item: i32) -> FacadeCallbackItem:
    var cbi = FacadeCallbackItem { decl: 0, of_sym: 0, rename: 0, userdata: -1, callback: -1, destroy: -1, retained: false, consumed: false, nullable: false }
    let cname: str = intern.resolve(pool.get_data0(item as NodeId))
    if facade_render_is_resource_op(pool, intern, cname):
        return cbi
    let decl = facade_render_find_fn(pool, intern, ci, pool.get_data0(item as NodeId))
    if decl == 0:
        return cbi
    var is_callback = false
    var nullable_pi = -1
    let cstart = pool.get_data1(item as NodeId)
    for k in 0..pool.get_data2(item as NodeId):
        let clause = pool.get_extra(cstart + k)
        let kind = pool.get_data0(clause as NodeId)
        let ops = pool.get_data1(clause as NodeId)
        if kind == FACADE_CLAUSE_OF: cbi.of_sym = pool.get_extra(ops)
        else if kind == FACADE_CLAUSE_RENAME: cbi.rename = pool.get_extra(ops)
        // A fixed argument (D64) leaves the presented signature; the
        // parameter loop below passes its literal (facade_render_fixed_literal).
        else if kind == FACADE_CLAUSE_LEND or kind == FACADE_CLAUSE_PRESERVES or kind == FACADE_CLAUSE_FIXED: continue
        else if kind == FACADE_CLAUSE_NULLABLE:
            // Rendered for the paired callback alone (Sema refuses the
            // rest, verify_facade_callback_items).
            let npi = facade_render_param_ref(pool, intern, decl, pool.get_extra(ops))
            if npi < 0 or nullable_pi >= 0:
                return cbi
            nullable_pi = npi
        else if kind == FACADE_CLAUSE_CALLBACK_THREAD: is_callback = true
        else if kind == FACADE_CLAUSE_CALLBACK_USERDATA:
            let cb = facade_render_param_ref(pool, intern, decl, pool.get_extra(ops))
            let ud = facade_render_param_ref(pool, intern, decl, pool.get_extra(ops + 1))
            if cb < 0 or ud < 0 or (cbi.userdata >= 0 and cbi.userdata != ud) or (cbi.callback >= 0 and cbi.callback != cb):
                return cbi
            cbi.userdata = ud
            cbi.callback = cb
            is_callback = true
        else if kind == FACADE_CLAUSE_RETAINS:
            let a = facade_render_param_ref(pool, intern, decl, pool.get_extra(ops))
            let by = facade_render_param_ref(pool, intern, decl, pool.get_extra(ops + 1))
            if a < 0 or by != 0:
                return cbi
            let ptext = facade_render_param_type(pool, intern, decl, a)
            if facade_render_is_userdata_type(pool, intern, ptext):
                if cbi.userdata >= 0 and cbi.userdata != a:
                    return cbi
                cbi.userdata = a
                cbi.retained = true
                is_callback = true
            else if facade_render_is_callable_type(facade_render_unalias(pool, intern, ptext)):
                is_callback = true
            else:
                return cbi
        else if kind == FACADE_CLAUSE_CONSUMES:
            let a = facade_render_param_ref(pool, intern, decl, pool.get_extra(ops))
            let by_ref = pool.get_extra(ops + 1)
            if by_ref == 0:
                return cbi
            let by = facade_render_param_ref(pool, intern, decl, by_ref)
            if a < 0 or by < 0 or (cbi.userdata >= 0 and cbi.userdata != a) or not facade_render_is_userdata_type(pool, intern, facade_render_param_type(pool, intern, decl, a)):
                return cbi
            cbi.userdata = a
            cbi.destroy = by
            cbi.consumed = true
            is_callback = true
        else:
            return cbi
    if not is_callback or (cbi.retained and cbi.consumed):
        return cbi
    if nullable_pi >= 0:
        if nullable_pi != cbi.callback or cbi.retained or cbi.consumed:
            return cbi
        cbi.nullable = true
    cbi.decl = decl
    cbi

// Whether the callback item is a method of `resource` (whose unaliased
// representation is `repr`): the lend rule (facade_render_lend_hosted).
fn facade_render_callback_hosted(pool: AstPool, intern: InternPool, cbi: &FacadeCallbackItem, resource: i32, repr: &str) -> bool:
    if cbi.decl == 0:
        return false
    let li = FacadeLendItem { decl: cbi.decl, of_sym: cbi.of_sym, rename: cbi.rename, lends: true, borrow_res: 0, borrow_from: 0, text_view: false, valid_on_failed: false, bridged: false }
    facade_render_lend_hosted(pool, intern, &li, resource, repr)

// Whether some callback method of `resource` retains userdata: the
// resource carries the retained cells.
fn facade_render_resource_keeps_userdata(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32, repr: &str) -> bool:
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        let cbi = facade_render_callback_item(pool, intern, ci, items[i])
        if cbi.retained and facade_render_callback_hosted(pool, intern, &cbi, resource, repr):
            return true
    false

fn facade_render_param_type(pool: AstPool, intern: InternPool, decl: i32, pi: i32) -> str:
    let meta = pool.find_fn_meta(decl as NodeId)
    render_type_expr(pool, intern, pool.fn_param_type(pool.fn_meta_param_start(meta), pi) as NodeId)

// A `void *` no resource wraps: a userdata slot.
fn facade_render_is_userdata_type(pool: AstPool, intern: InternPool, ptext: &str) -> bool:
    let p = facade_render_unalias(pool, intern, ptext)
    (p == "*mut c_void" or p == "*const c_void") and facade_render_received(pool, intern, ptext) == 0

fn facade_render_is_callable_type(text: &str) -> bool:
    text.starts_with("fn(") or text.starts_with("extern \"C\" fn(") or text.starts_with("unsafe extern \"C\" fn(")

// The C callback type less `unsafe` — what the typed callback is
// transmuted to (a safe extern fn passes where C declares an unsafe one).
fn facade_render_callback_raw_type(text: &str) -> str:
    if text.starts_with("unsafe "): text.slice(7, text.len()) else: text.clone()

// The typed callback: the C signature with its one `void *` parameter —
// where the userdata arrives — spelled `&U`. "" when the signature has
// none or several (Sema refuses the pairing).
fn facade_render_callback_type(pool: AstPool, intern: InternPool, text: &str) -> str:
    let raw = facade_render_callback_raw_type(text)
    let open = raw.find("(")
    if open < 0:
        return ""
    // The parameter list ends at the parenthesis matching the first.
    var depth = 0
    var close: i64 = -1
    var i = open
    while i < raw.len() as i32:
        if raw[i] == '(': depth = depth + 1
        else if raw[i] == ')':
            depth = depth - 1
            if depth == 0:
                close = i
                break
        i = i + 1
    if close < 0:
        return ""
    let params = raw.slice(open + 1, close)
    // Split at top-level commas.
    let parts: Vec[str] = Vec.new()
    var start = 0
    depth = 0
    var k = 0
    while k < params.len() as i32:
        if params[k] == '(' or params[k] == '[': depth = depth + 1
        else if params[k] == ')' or params[k] == ']': depth = depth - 1
        else if params[k] == ',' and depth == 0:
            parts.push(params.slice(start, k).trim())
            start = k + 1
        k = k + 1
    if params.trim().len() > 0:
        parts.push(params.slice(start, params.len()).trim())
    var slots = 0
    var out = ""
    for pi in 0..parts.len() as i32:
        let p = facade_render_unalias(pool, intern, parts[pi])
        var shown = parts[pi].clone()
        if p == "*mut c_void" or p == "*const c_void":
            slots = slots + 1
            shown = "&U"
        out = out ++ (if pi > 0: ", " else: "") ++ shown
    if slots != 1:
        return ""
    raw.slice(0, open + 1) ++ out ++ raw.slice(close, raw.len())

// Every callback method of `resource` (see the section comment).
fn facade_render_callback_methods(pool: AstPool, intern: InternPool, ci: &Vec[i32], resource: i32) -> str:
    let repr_text = render_type_expr(pool, intern, pool.get_extra(pool.get_data1(resource as NodeId)) as NodeId)
    let repr = facade_render_unalias(pool, intern, repr_text)
    let in_place = not repr.starts_with("*") and facade_render_has_clause(pool, resource, FACADE_CLAUSE_INIT)
    if not repr.starts_with("*") and not in_place:
        return ""
    let pinned = in_place and not facade_render_has_clause(pool, resource, FACADE_CLAUSE_MOVABLE)
    var out = ""
    let items = facade_render_all_items(pool, NodeKind.NK_FACADE_FN)
    for i in 0..items.len() as i32:
        let cbi = facade_render_callback_item(pool, intern, ci, items[i])
        if not facade_render_callback_hosted(pool, intern, &cbi, resource, repr):
            continue
        let decl = cbi.decl
        let meta = pool.find_fn_meta(decl as NodeId)
        let fname: str = intern.resolve(pool.get_data0(decl as NodeId))
        let mname = facade_render_present(pool, intern, ci, resource, fname)
        let repr_arg = facade_render_repr_arg(pool, intern, decl, repr_text, "self.repr", pinned)
        if repr_arg.len() == 0:
            continue
        let taken = facade_render_param_names(pool, intern, decl)
        let cell = facade_render_fresh("facade_cell", taken)
        let ptr = facade_render_fresh("facade_ptr", taken)
        let free = facade_render_fresh("facade_free", taken)
        let q = facade_render_fresh("facade_q", taken)
        let b = facade_render_fresh("facade_b", taken)
        let ncb = facade_render_fresh("facade_cb", taken)
        let nud = facade_render_fresh("facade_ud", taken)
        let nf = facade_render_fresh("facade_f", taken)
        let nu = facade_render_fresh("facade_u", taken)
        let generic = cbi.userdata >= 0
        let kept = cbi.retained or cbi.consumed
        let start = pool.fn_meta_param_start(meta)
        var cb_type = ""
        if cbi.callback >= 0:
            cb_type = facade_render_callback_type(pool, intern, facade_render_param_type(pool, intern, decl, cbi.callback))
            if cb_type.len() == 0:
                continue
        var params = ""
        var args = repr_arg.clone()
        var ud_name = ""
        var cb_name = ""
        for pi in 1..pool.fn_meta_param_count(meta):
            args = args ++ ", "
            if pi == cbi.destroy:
                args = args ++ free
                continue
            let fixed = facade_render_fixed_literal(pool, intern, decl, pi)
            if fixed.len() > 0:
                args = args ++ fixed
                continue
            let pname = facade_render_param_name(pool, intern, start, pi)
            let ptype = facade_render_param_type(pool, intern, decl, pi)
            var shown = if ptype == "*const i8" or ptype == "*const c_char": "&str" else: ptype.clone()
            var arg = pname.clone()
            if pi == cbi.userdata:
                ud_name = pname.clone()
                if kept:
                    shown = "U"
                    arg = ptr.clone()
                else if cbi.nullable:
                    // A nullable callback's userdata (#1618): absent with
                    // it — `Option[&U]`, NULL to C for None.
                    shown = "Option[&U]"
                    arg = nud.clone()
                else:
                    shown = "&U"
                    arg = pname ++ " as *const U as " ++ facade_render_unalias(pool, intern, ptype)
            else if pi == cbi.callback:
                cb_name = pname.clone()
                if cbi.nullable:
                    // `nullable param N` on the paired callback (ruling
                    // §43, spec §16.2b.8): `Option` of the typed callback,
                    // NULL to C for None.
                    shown = "Option[" ++ cb_type ++ "]"
                    arg = ncb.clone()
                else:
                    shown = cb_type.clone()
                    arg = "transmute[" ++ facade_render_callback_raw_type(facade_render_unalias(pool, intern, ptype)) ++ "](" ++ pname ++ ")"
            else:
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
        let head = (if cbi.retained: "    mut fn " else: "    fn ") ++ mname ++ (if generic: "[U]" else: "") ++ "(" ++ params ++ ")" ++ facade_render_return(pool, intern, decl) ++ ":\n"
        var body = ""
        if cbi.nullable:
            // The pair is present or absent together (Sema checks each
            // call, SemaCheck.w check_method_call): each maps to its C
            // value, NULL for None.
            let raw_cb = facade_render_callback_raw_type(facade_render_unalias(pool, intern, facade_render_param_type(pool, intern, decl, cbi.callback)))
            let ud_type = facade_render_unalias(pool, intern, facade_render_param_type(pool, intern, decl, cbi.userdata))
            body = body ++ "        let " ++ ncb ++ ": " ++ raw_cb ++ " = match " ++ cb_name ++ ":\n            Some(" ++ nf ++ ") => unsafe { transmute[" ++ raw_cb ++ "](" ++ nf ++ ") }\n            None => null\n"
            // The userdata by transmute, not `as *const U as …`: with no
            // callback `U` is Unit, and a cast to `*const Unit` traps
            // codegen (#1626), which a pointer-to-pointer transmute of the
            // same representation does not.
            body = body ++ "        let " ++ nud ++ ": " ++ ud_type ++ " = match " ++ ud_name ++ ":\n            Some(" ++ nu ++ ") => unsafe { transmute[" ++ ud_type ++ "](" ++ nu ++ ") }\n            None => null\n"
        if generic and kept:
            let ud_type = facade_render_unalias(pool, intern, facade_render_param_type(pool, intern, decl, cbi.userdata))
            body = body ++ "        let " ++ cell ++ " = Box.new(" ++ ud_name ++ ")\n"
            body = body ++ "        let " ++ ptr ++ " = " ++ cell ++ ".into_raw() as " ++ ud_type ++ "\n"
            body = body ++ "        let " ++ free ++ ": extern \"C\" fn(*mut c_void) -> Unit = " ++ q ++ " => { let " ++ b ++ " = (" ++ q ++ " as *mut U) as Box[U]; drop(" ++ b ++ ") }\n"
            if cbi.retained:
                body = body ++ "        self.retained_ptrs.push(" ++ ptr ++ " as *mut c_void)\n        self.retained_frees.push(" ++ free ++ ")\n"
        out = out ++ head ++ body ++ "        " ++ facade_render_call(pool, intern, decl, args) ++ "\n"
    out

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
