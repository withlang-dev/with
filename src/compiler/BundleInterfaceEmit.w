// D39 bundle interfaces (docs/wo_bundles.md, decisions.md D39): the `.wi`
// emitter and the exported-declaration model the fingerprint hashes.
//
// After full Sema — the Sema codegen hands back, or the one `check` froze —
// the bundle build prints, per corpus module, the module's `use` lines and
// every exported declaration from Sema's FINALIZED tables: never source
// text (span-derived names differ between a `.w` and its `.wi`), never a
// placeholder (a declaration the emitter cannot state exactly is a loud
// refusal naming it, and the run fails). Exported: every `pub` type, const,
// storage global, extern fn, fn and impl block, plus every corpus type a
// printed declaration names, with its own visibility — a layout needs its
// field types, and a std-tier consumer sees private std declarations from
// source through Sema's internal-implementation boundary, so it must see
// the same ones from the interface. Callable semantics are the declaration
// (D39): no effect, origin or body fact is written; the fingerprint rows
// carry declared effects computed by Sema's own rule
// (SemaCheck.declared_param_effect / declared_view_origin).
//
// Definition-side attributes (`@[inline]`, `@[noinline]`, `@[tailrec]`)
// are not part of a declaration's contract and are not printed.
use Ast
use Sema
use FnAbi
use compiler.BundleInterfaces
use std.string.StringBuilder
use std.collections.HashMap

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_str_cmp_ref(a: &str, b: &str) -> i32

pub const BX_TYPE: i32 = 0
pub const BX_CONST: i32 = 1
pub const BX_GLOBAL: i32 = 2
pub const BX_EXTERN: i32 = 3
pub const BX_FN: i32 = 4
pub const BX_IMPL: i32 = 5
// a note line in the .wi (no fingerprint row): a declaration the boundary
// cannot carry at Level 0, named so a reader sees why it is absent
pub const BX_NOTE: i32 = 6

// One exported declaration: its `.wi` text (newline-terminated, attribute
// lines included) and its fingerprint row(s).
pub type BundleExport {
    kind: i32,
    mod_path: str,
    name: str,
    wi: str,
    row: str,
}

pub type BundleInterfaceModel {
    ok: bool,
    corpus: str,
    // canonical corpus module paths, sorted bytewise, and the resolver's
    // spelling of each (the module-graph key)
    modules: Vec[str],
    module_sources: Vec[str],
    exports: Vec[BundleExport],
    errors: Vec[str],
    // source pass only: a declaration whose body-inferred effects disagree
    // with what it declares (D39: the boundary exposes the mistaken
    // declaration)
    warnings: Vec[str],
    // D39 Level 0: generic functions stay corpus-internal — omitted from the
    // interface, named here ("<module>\t<name>\tgeneric-fn") for the
    // manifest's `omitted` lines
    omitted: Vec[str],
}

type BundleEmitter {
    corpus: str,
    // "<canonical module>\t<name>" per owned global codegen could not fold
    // to data (Codegen.bundle_unlowered_globals); empty on the .wi pass
    unlowered_globals: Vec[str],
    errors: Vec[str],
    warnings: Vec[str],
    // canonical module path per decl index ("" outside the corpus)
    decl_modules: Vec[str],
    modules: Vec[str],
    module_sources: Vec[str],
    // corpus type declarations: name symbol → decl index
    type_decl_index: HashMap[i32, i32],
    // impl blocks in the corpus: target type symbol and decl index, parallel
    impl_type_syms: Vec[i32],
    impl_decl_indices: Vec[i32],
    // the type closure worklist: name symbols a printed declaration named
    named_type_syms: Vec[i32],
    named_type_seen: HashMap[i32, i32],
    exports: Vec[BundleExport],
    // "<module>: <declaration>" for messages
    context: str,
    // a refusal fired inside the current declaration
    failed: bool,
    // the fingerprint row of the method fn_text last printed for an impl
    last_fn_row: str,
    omitted: Vec[str],
}

pub type BundleInterfaceText {
    text: str,
    errors: Vec[str],
}

fn bx_new_emitter(corpus: &str, unlowered_globals: &Vec[str]) -> BundleEmitter:
    BundleEmitter {
        corpus: with_str_clone_ref(corpus),
        unlowered_globals: sema_clone_str_vec(unlowered_globals),
        errors: Vec.new(),
        warnings: Vec.new(),
        decl_modules: Vec.new(),
        modules: Vec.new(),
        module_sources: Vec.new(),
        type_decl_index: HashMap.new(),
        impl_type_syms: Vec.new(),
        impl_decl_indices: Vec.new(),
        named_type_syms: Vec.new(),
        named_type_seen: HashMap.new(),
        exports: Vec.new(),
        context: "",
        failed: false,
        last_fn_row: "",
        omitted: Vec.new(),
    }

fn bx_str_less(a: &str, b: &str) -> bool: with_str_cmp_ref(a, b) < 0

// Insertion-sorted copy (bytewise); the model is small.
fn bx_sorted_strings(items: &Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items[i]
        var out: Vec[str] = Vec.new()
        var inserted = false
        for j in 0..sorted.len() as i32:
            let existing = sorted[j]
            if not inserted and bx_str_less(item, existing):
                out.push(with_str_clone_ref(item))
                inserted = true
            out.push(with_str_clone_ref(existing))
        if not inserted:
            out.push(with_str_clone_ref(item))
        sorted = out
    sorted

fn bx_string_escape_byte(b: i32) -> str:
    if b == '\\': return "\\\\"
    if b == '"': return "\\\""
    if b == '\n': return "\\n"
    if b == '\t': return "\\t"
    if b == '\r': return "\\r"
    if b == 0: return "\\0"
    ""

fn bx_node_kind_name(kind: i32) -> str: f"node kind {kind}"

impl BundleEmitter:
    mut fn refuse(message: &str):
        self.errors.push(self.context ++ ": " ++ message)
        self.failed = true

    mut fn refuse_global(message: &str):
        self.errors.push(with_str_clone_ref(message))
        self.failed = true

    // D39 Level 0: a generic function cannot cross the boundary (its body
    // instantiates at each use site, and an interface carries no bodies).
    // It stays corpus-internal: omitted from the interface, named in the
    // section as a note and in the manifest's `omitted` lines. Not a
    // refusal — migrated C corpora export their macro helpers this way.
    mut fn omit_generic_fn(mod_path: &str, name: &str):
        self.omitted.push(mod_path ++ "\t" ++ name ++ "\tgeneric-fn")
        self.push_export(BX_NOTE, mod_path, name, "// not exported at Level 0 (generic): fn " ++ name ++ "\n", "")

    mut fn add_module(canonical: &str, source_path: &str):
        if not self.modules.contains(canonical):
            self.modules.push(with_str_clone_ref(canonical))
            self.module_sources.push(with_str_clone_ref(source_path))

    mut fn note_named_type(sym: i32):
        if sym == 0 or self.named_type_seen.contains(sym):
            return
        self.named_type_seen.insert(sym, 1)
        self.named_type_syms.push(sym)

    mut fn push_export(kind: i32, mod_path: &str, name: &str, wi: &str, row: &str):
        self.exports.push(BundleExport {
            kind,
            mod_path: with_str_clone_ref(mod_path),
            name: with_str_clone_ref(name),
            wi: with_str_clone_ref(wi),
            row: with_str_clone_ref(row),
        })

    // ── Type spelling ─────────────────────────────────────────────────
    // The canonical, re-readable spelling of a type: aliases resolved,
    // every named type bare (visibility in the .wi section follows the same
    // `use` lines the source had), never a placeholder.
    mut fn spell(sema: &Sema, tid: i32) -> str:
        let resolved = sema.resolve_alias(tid)
        let tk = sema.get_type_kind(resolved)
        if tk == TypeKind.TY_INT:
            let bits = sema.get_type_d0(resolved)
            let signed = sema.get_type_d1(resolved) != 0
            if sema.get_type_d2(resolved) != 0:
                return if signed: "isize" else: "usize"
            if bits <= 0 or bits > 128:
                self.refuse(f"integer type of width {bits} has no spelling")
                return ""
            let prefix = if signed: "i" else: "u"
            return prefix ++ f"{bits}"
        if tk == TypeKind.TY_FLOAT:
            return if sema.get_type_d0(resolved) == 32: "f32" else: "f64"
        if tk == TypeKind.TY_BOOL:
            return "bool"
        if tk == TypeKind.TY_VOID:
            return "Unit"
        if tk == TypeKind.TY_NEVER:
            return "Never"
        if tk == TypeKind.TY_STR:
            return "str"
        if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM:
            let name_sym = sema.get_type_d0(resolved)
            let name = with_str_clone_ref(sema.pool_resolve(name_sym))
            if name.len() == 0:
                self.refuse("names an anonymous type")
                return ""
            self.note_named_type(name_sym)
            return name
        if tk == TypeKind.TY_ARRAY:
            let size = sema.get_type_d1(resolved)
            return f"[{size}]" ++ self.spell(sema, sema.get_type_d0(resolved))
        if tk == TypeKind.TY_SLICE:
            let mut_text = if sema.get_type_d1(resolved) != 0: "mut " else: ""
            return "[]" ++ mut_text ++ self.spell(sema, sema.get_type_d0(resolved))
        if tk == TypeKind.TY_TUPLE:
            let te_start = sema.get_type_d0(resolved)
            let elem_count = sema.get_type_d1(resolved)
            var out = "("
            for ei in 0..elem_count:
                if ei > 0:
                    out = out ++ ", "
                out = out ++ self.spell(sema, sema.type_extra[(te_start + ei)])
            if elem_count == 1:
                out = out ++ ","
            return out ++ ")"
        if tk == TypeKind.TY_FN or tk == TypeKind.TY_EXTERN_FN:
            let te_start = sema.get_type_d0(resolved)
            let param_count = sema.get_type_d1(resolved)
            var out = if sema.unsafe_fn_type_set.contains(resolved as i32): "unsafe " else: ""
            out = out ++ (if tk == TypeKind.TY_EXTERN_FN: "extern \"C\" fn(" else: "fn(")
            for pi in 0..param_count:
                if pi > 0:
                    out = out ++ ", "
                out = out ++ self.spell(sema, sema.type_extra[(te_start + pi)])
            return out ++ ") -> " ++ self.spell(sema, sema.get_type_d2(resolved))
        if tk == TypeKind.TY_PTR:
            let pointee = self.spell(sema, sema.get_type_d0(resolved))
            return (if sema.get_type_d1(resolved) != 0: "*mut " else: "*const ") ++ pointee
        if tk == TypeKind.TY_REF:
            let pointee = self.spell(sema, sema.get_type_d0(resolved))
            return (if sema.get_type_d1(resolved) != 0: "&mut " else: "&") ++ pointee
        if tk == TypeKind.TY_GENERIC_INST:
            let base_sym = sema.get_type_d0(resolved)
            let base = with_str_clone_ref(sema.pool_resolve(base_sym))
            self.note_named_type(base_sym)
            let arg_count = sema.get_type_d2(resolved)
            let extra_start = sema.get_type_d1(resolved)
            var out = base ++ "["
            for ai in 0..arg_count:
                if ai > 0:
                    out = out ++ ", "
                out = out ++ self.spell(sema, sema.type_extra[(extra_start + ai)])
            return out ++ "]"
        if tk == TypeKind.TY_RANGE:
            self.refuse("a Range type is not a bundle interface surface")
            return ""
        if tk == TypeKind.TY_TRAIT_OBJ:
            self.refuse("a trait object type is not a bundle interface surface (Level 0)")
            return ""
        if tk == TypeKind.TY_ERR:
            self.refuse("has an unresolved (error) type")
            return ""
        self.refuse(f"type kind {tk} has no interface spelling")
        ""

    // ── Literals ──────────────────────────────────────────────────────
    // `decoded`: the text of a comptime-folded string is the decoded value
    // (re-escaped here); a parsed literal's text is its raw source content
    // between the quotes, printed as is.
    mut fn string_literal_text(sema: &Sema, sym: i32, decoded: bool) -> str:
        var text = with_str_clone_ref(sema.pool_resolve(sym))
        let raw_marker = "\x01raw\x01"
        var is_raw = false
        if text.starts_with(raw_marker):
            is_raw = true
            text = with_str_clone_ref(text.slice(raw_marker.len(), text.len()))
        if not decoded and not is_raw:
            return "\"" ++ text ++ "\""
        var out = StringBuilder.new()
        out.push_str("\"")
        for i in 0..text.len():
            let b = text[i]
            let escaped = bx_string_escape_byte(b)
            if escaped.len() > 0:
                out.push_str(escaped)
            else if b < 32:
                self.refuse(f"string constant holds control byte {b}, which has no literal spelling")
                return ""
            else:
                out.push_str(text.slice(i, i + 1))
        out.push_str("\"")
        out.to_str()

    mut fn literal_text(sema: &Sema, node: i32, decoded: bool) -> str:
        let ast = sema.ast
        if node == 0:
            self.refuse("constant has no value")
            return ""
        let kind = ast.kind(node)
        if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_COMPTIME:
            return self.literal_text(sema, ast.get_data0(node), decoded)
        if kind == NodeKind.NK_INT_LIT:
            if ast.has_int_literal_exact(node):
                let digits = ast.int_literal_digits(node)
                let radix = ast.int_literal_radix(node)
                let prefix = if radix == 16: "0x" else if radix == 8: "0o" else if radix == 2: "0b" else: ""
                return prefix ++ digits
            return f"{ast.int_lit_value(node)}"
        if kind == NodeKind.NK_FLOAT_LIT:
            return with_str_clone_ref(ast.get_string(ast.get_data0(node)))
        if kind == NodeKind.NK_BOOL_LIT:
            return if ast.get_data0(node) != 0: "true" else: "false"
        if kind == NodeKind.NK_NULL_LIT:
            return "null"
        if kind == NodeKind.NK_STRING_LIT:
            return self.string_literal_text(sema, ast.get_data0(node), decoded)
        if kind == NodeKind.NK_C_STRING_LIT:
            return "c" ++ self.string_literal_text(sema, ast.get_data0(node), decoded)
        if kind == NodeKind.NK_UNARY and ast.get_data0(node) == UnaryOp.UOP_NEGATE:
            let inner = self.literal_text(sema, ast.get_data1(node), decoded)
            return if inner.len() > 0: "-" ++ inner else: ""
        if kind == NodeKind.NK_CAST:
            // `0 as c_ulong`: the target is the declared type node — a
            // declaration-level fact, printed as declared.
            let inner = self.literal_text(sema, ast.get_data0(node), decoded)
            if self.failed:
                return ""
            let target = self.type_node_text(sema, ast.get_data1(node))
            return if self.failed: "" else: inner ++ " as " ++ target
        if kind == NodeKind.NK_ARRAY_LIT or kind == NodeKind.NK_TUPLE:
            let extra_start = ast.get_data0(node)
            let count = ast.get_data1(node)
            // `[value; N]` parses to N references to one node; print it back.
            var repeated = kind == NodeKind.NK_ARRAY_LIT and count > 1
            for ri in 1..count:
                if ast.get_extra(extra_start + ri) != ast.get_extra(extra_start):
                    repeated = false
            if repeated:
                let elem = self.literal_text(sema, ast.get_extra(extra_start), decoded)
                return if self.failed: "" else: "[" ++ elem ++ f"; {count}]"
            var out = if kind == NodeKind.NK_ARRAY_LIT: "[" else: "("
            for i in 0..count:
                if i > 0:
                    out = out ++ ", "
                out = out ++ self.literal_text(sema, ast.get_extra(extra_start + i), decoded)
                if self.failed:
                    return ""
            if kind == NodeKind.NK_TUPLE and count == 1:
                out = out ++ ","
            return out ++ (if kind == NodeKind.NK_ARRAY_LIT: "]" else: ")")
        self.refuse("constant does not fold to a literal (" ++ bx_node_kind_name(kind) ++ ")")
        ""

    // A declared type expression inside a literal (a cast target), printed as
    // declared; only the shapes a field default can carry.
    mut fn type_node_text(sema: &Sema, node: i32) -> str:
        let ast = sema.ast
        if node == 0:
            self.refuse("cast has no target type")
            return ""
        let kind = ast.kind(node)
        if kind == NodeKind.NK_TYPE_NAMED:
            return with_str_clone_ref(sema.pool_resolve(ast.get_data0(node)))
        if kind == NodeKind.NK_TYPE_PTR:
            let inner = self.type_node_text(sema, ast.get_data0(node))
            return (if ast.get_data1(node) != 0: "*mut " else: "*const ") ++ inner
        self.refuse("cast target (" ++ bx_node_kind_name(kind) ++ ") has no literal spelling")
        ""

    // ── Declarations ──────────────────────────────────────────────────
    fn decl_is_pub_type(sema: &Sema, node: i32) -> bool:
        let ast = sema.ast
        let extra_start = ast.get_data1(node)
        let sub_kind = type_decl_sub_kind(ast.get_data2(node))
        type_decl_is_pub(ast, extra_start, sub_kind)

    mut fn emit_let(sema: &Sema, di: i32, node: i32):
        let ast = sema.ast
        let flags = ast.get_data2(node)
        if (flags / 2) % 2 == 0:
            return
        let mod_path = with_str_clone_ref(self.decl_modules[di])
        let name = with_str_clone_ref(sema.pool_resolve(ast.get_data0(node)))
        let is_const = ast.is_const_decl_node(node) != 0
        self.context = mod_path ++ ": " ++ (if is_const: "const " else: "global ") ++ name
        self.failed = false
        let tid_opt = sema.typed_binding_types.get(node)
        let tid: i32 = if tid_opt.is_some(): tid_opt.unwrap() else: 0
        if tid == 0:
            self.refuse("has no finalized type")
            return
        let spelling = self.spell(sema, tid)
        if self.failed:
            return
        if is_const:
            let value = self.literal_text(sema, ast.get_data1(node), true)
            if self.failed:
                return
            if spelling.starts_with("u") and value.starts_with("-"):
                self.refuse("unsigned constant value does not fit an i64 literal")
                return
            self.push_export(BX_CONST, mod_path, name, "pub const " ++ name ++ ": " ++ spelling ++ " = " ++ value ++ "\n", "const\t" ++ mod_path ++ "\t" ++ name ++ "\t" ++ spelling ++ "\t" ++ value ++ "\n")
            return
        let is_mut = flags % 2 != 0
        if is_mut and sema.type_needs_drop_frozen(tid) != 0:
            self.refuse("is a mutable global of a droppable type (" ++ spelling ++ "); nobody drops bundle storage (Level 0)")
            return
        // D38 Level 0: codegen could not fold this global's initializer to
        // data, so the object does not define it — corpus-internal, omitted
        // like a generic function (a migrated C corpus's `INTMAX_C(…)` macro
        // values), named here and in the manifest's `omitted` lines.
        if self.unlowered_globals.contains(mod_path ++ "\t" ++ name):
            self.omitted.push(mod_path ++ "\t" ++ name ++ "\truntime-init-global")
            self.push_export(BX_NOTE, mod_path, name, "// not exported at Level 0 (no compile-time initializer): " ++ (if is_mut: "var " else: "let ") ++ name ++ "\n", "")
            return
        let keyword = if is_mut: "pub var " else: "pub let "
        let mut_text = if is_mut: "1" else: "0"
        self.push_export(BX_GLOBAL, mod_path, name, keyword ++ name ++ ": " ++ spelling ++ "\n", "global\t" ++ mod_path ++ "\t" ++ name ++ "\t" ++ spelling ++ "\t" ++ mut_text ++ "\n")

    // The `.wi` line(s) of one function declaration ("" when refused or
    // skipped); pushes the export itself unless `in_impl` (the impl block
    // collects its methods and reads the row from last_fn_row).
    // `all_visibilities` prints a non-pub method too (a trait impl's methods
    // are the trait's contract).
    mut fn fn_text(sema: &Sema, di: i32, node: i32, in_impl: bool, all_visibilities: bool) -> str:
        self.last_fn_row = ""
        let ast = sema.ast
        let mod_path = with_str_clone_ref(self.decl_modules[di])
        let parsed = ast.get_data0(node)
        let fn_sym = sema.fn_decl_semantic_symbol_at(node, parsed, di)
        let full = with_str_clone_ref(sema.pool_resolve(fn_sym))
        let flags = ast.get_data2(node)
        let is_pub = flags % 2 != 0
        self.context = mod_path ++ ": fn " ++ full
        self.failed = false
        if not is_pub and not all_visibilities:
            return ""
        if full.contains("$ext$") or sema.method_decl_is_extension(node) != 0:
            self.refuse("is an extension method; extensions do not cross a bundle boundary")
            return ""
        if (flags / FnFlags.ASYNC) % 2 != 0 or (flags / FnFlags.GEN) % 2 != 0 or (flags / FnFlags.COMPTIME) % 2 != 0:
            self.refuse("is async, gen or comptime; a bundle boundary is Level 0 (docs/abi_roadmap.md)")
            return ""
        if (flags / FnFlags.VARIADIC) % 2 != 0:
            self.refuse("is variadic; no interface spelling")
            return ""
        if (flags / FnFlags.ENTRY) % 2 != 0 or (flags / FnFlags.PANIC_HANDLER) % 2 != 0 or (flags / FnFlags.NO_MAIN) % 2 != 0 or (flags / FnFlags.TEST) % 2 != 0 or (flags / FnFlags.BEFORE) % 2 != 0 or (flags / FnFlags.AFTER) % 2 != 0 or (flags / FnFlags.BENCH) % 2 != 0:
            self.refuse("carries an entry/test/panic-handler attribute; not interface material")
            return ""
        let meta = ast.find_fn_meta(node)
        if meta < 0:
            self.refuse("has no function metadata")
            return ""
        if ast.fn_meta_tp_count(meta) > 0 or sema.fn_node_is_generic_template(node, fn_sym) != 0:
            self.omit_generic_fn(mod_path, full)
            return ""
        let cc_sym = ast.fn_meta_tp_start(meta)
        if cc_sym != 0:
            let cc = with_str_clone_ref(sema.pool_resolve(cc_sym))
            if cc.starts_with("c_export:"):
                self.refuse("is @[c_export]; a bundle exports a With surface, never a C one (docs/wo_bundles.md)")
            else:
                self.refuse("carries calling-convention attribute '" ++ cc ++ "', which has no interface spelling")
            return ""
        if sema.fn_clause_group_lookup.contains(fn_sym):
            self.refuse("has multiple clauses; no interface spelling")
            return ""
        let sig = sema.get_sig(fn_sym)
        if sig < 0:
            self.refuse("has no finalized signature")
            return ""
        let pattern_meta = ast.find_fn_param_pattern_meta(node)
        if pattern_meta >= 0:
            let pattern_start = ast.fn_param_pattern_meta_start(pattern_meta)
            for ppi in 0..ast.fn_param_pattern_meta_count(pattern_meta):
                if ast.fn_param_pattern_value(pattern_start + ppi) != 0:
                    self.refuse("destructures a parameter; no interface spelling")
                    return ""
        let param_start = ast.fn_meta_param_start(meta)
        let param_count = ast.fn_meta_param_count(meta)
        if sema.sig_get_param_count(sig) != param_count:
            self.refuse(f"declares {param_count} parameters but its signature has {sema.sig_get_param_count(sig)}")
            return ""
        let receiver_mode = sema.sig_receiver_mode(sig)
        var receiver = ""
        var receiver_row = "-"
        var params = ""
        var params_row = ""
        var printed = 0
        let origin = sema.declared_view_origin(sig)
        for pi in 0..param_count:
            let name_sym = ast.fn_param_name(param_start, pi)
            let pflags = ast.fn_param_flags(param_start, pi)
            let pname = with_str_clone_ref(sema.pool_resolve(name_sym))
            if ast.get_fn_param_default(param_start, pi) != 0:
                self.refuse("parameter '" ++ pname ++ "' has a default value; no interface spelling (Level 0)")
                return ""
            if fn_param_is_implicit(pflags) != 0:
                self.refuse("parameter '" ++ pname ++ "' is an implicit capability parameter; not interface material")
                return ""
            let ptid = sema.sig_param_type(sig, pi)
            let eff = sema.declared_param_effect(pi, ptid, receiver_mode, sema.is_copy_frozen(ptid))
            let vra = sema.sig_param_uses_value_ref_abi(sig, pi)
            if pname == "self":
                if pi != 0 or fn_param_is_synth_receiver(pflags) == 0:
                    self.refuse("has an explicit self parameter; no interface spelling")
                    return ""
                if not in_impl:
                    self.refuse("has a receiver outside an impl block")
                    return ""
                receiver = if fn_param_is_move_self(pflags) != 0: "move " else if fn_param_is_mut_self(pflags) != 0: "mut " else: ""
                receiver_row = if receiver_mode == ReceiverMode.Move: "move" else if receiver_mode == ReceiverMode.Mut: "mut" else if receiver_mode == ReceiverMode.Read: "read" else: "missing"
                params_row = params_row ++ f"self:-:{vra}:{eff};"
                self.note_effect_disagreement(sema, node, sig, pi, full, pname, eff, origin)
                continue
            let spelling = self.spell(sema, ptid)
            if self.failed:
                return ""
            if printed > 0:
                params = params ++ ", "
            let noalias = fn_param_is_noalias(pflags) != 0
            params = params ++ (if noalias: "@[noalias] " else: "") ++ pname ++ ": " ++ spelling
            params_row = params_row ++ pname ++ ":" ++ spelling ++ f":{vra}:{eff}" ++ (if noalias: ":noalias" else: "") ++ ";"
            printed = printed + 1
            self.note_effect_disagreement(sema, node, sig, pi, full, pname, eff, origin)
        let ret = self.spell(sema, sema.sig_return_type(sig))
        if self.failed:
            return ""
        if origin == DECLARED_ORIGIN_AMBIGUOUS:
            self.refuse("returns a reference with no unambiguous origin: name the origin in the source signature (D39 elision: receiver, else the single borrowed parameter)")
            return ""
        let is_unsafe = sema.fn_symbol_is_unsafe(fn_sym) != 0
        let must_use = (flags / FnFlags.MUST_USE) % 2 != 0
        var printed_name = with_str_clone_ref(full)
        if in_impl:
            let dot = sema_str_find_char(full, '.')
            if dot >= 0:
                printed_name = with_str_clone_ref(full.slice((dot + 1) as i64, full.len()))
        var head = if must_use: "@[must_use]\n" else: ""
        head = head ++ (if is_pub: "pub " else: "") ++ (if is_unsafe: "unsafe " else: "") ++ receiver ++ "fn " ++ printed_name ++ "(" ++ params ++ ") -> " ++ ret ++ "\n"
        let vis = if is_pub: "pub" else: "priv"
        let unsafe_text = if is_unsafe: "1" else: "0"
        let must_use_text = if must_use: "must_use" else: "-"
        let row = "fn\t" ++ mod_path ++ "\t" ++ full ++ "\t" ++ unsafe_text ++ "\t" ++ receiver_row ++ "\t" ++ must_use_text ++ "\tparams:" ++ params_row ++ "\tret:" ++ ret ++ f"\torigin:{origin}\tvis:" ++ vis ++ "\n"
        if in_impl:
            self.last_fn_row = row
        else:
            self.push_export(BX_FN, mod_path, full, head, row)
        head

    // Source pass: a body whose inferred effects disagree with the
    // declaration is the D39 signal ("the boundary exposing that mistake is a
    // feature"). The fingerprint carries the declared effects either way.
    mut fn note_effect_disagreement(sema: &Sema, node: i32, sig: i32, pi: i32, full: &str, pname: &str, declared: i32, origin: i32):
        if sema.ast.fn_decl_body_is_interface(node):
            return
        // A raw pointer carries no With ownership by declaration (D39);
        // whatever the body does through it is not a declaration mistake.
        if sema.get_type_kind(sema.resolve_alias(sema.sig_param_type(sig, pi))) == TypeKind.TY_PTR:
            return
        // The D39 case: a plain `T` declares a consume, but the body only
        // reads it — it should have said `&T`. An unused parameter or a body
        // that stores what it consumes is not a mistaken declaration.
        let declared_full = if origin == pi: declared | EFF_ESCAPE_VIEW else: declared
        let inferred = sema.sig_param_effect(sig, pi) & EFF_DECLARED_MASK
        if (declared_full & EFF_CONSUME) == 0 or (inferred & (EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0:
            return
        self.warnings.push(self.context ++ ": parameter '" ++ pname ++ "' declares [" ++ sema_effect_bits_text(declared_full) ++ "] but its body only [" ++ sema_effect_bits_text(inferred) ++ "]; declare it `&T` — the declaration is the contract (D39)")

    mut fn emit_extern(sema: &Sema, di: i32, node: i32):
        let ast = sema.ast
        let mod_path = with_str_clone_ref(self.decl_modules[di])
        let name_sym = ast.get_data0(node)
        let name = with_str_clone_ref(sema.pool_resolve(name_sym))
        self.context = mod_path ++ ": extern fn " ++ name
        self.failed = false
        let meta = ast.find_fn_meta(node)
        if meta < 0:
            self.refuse("has no function metadata")
            return
        if ast.fn_effect_pin_count(node) > 0:
            self.refuse("carries @[effect] pins; no interface spelling")
            return
        var attrs = ""
        var cc_row = "-"
        let cc_sym = ast.fn_meta_tp_start(meta)
        if cc_sym != 0:
            let cc = with_str_clone_ref(sema.pool_resolve(cc_sym))
            if cc.starts_with("link_name:"):
                attrs = "@[link_name(\"" ++ cc.slice(10, cc.len()) ++ "\")]\n"
            else if cc.starts_with("c_export:"):
                self.refuse("is @[c_export]; not interface material")
                return
            else:
                attrs = "@[callconv(\"" ++ cc ++ "\")]\n"
            cc_row = cc
        let sig = sema.get_sig(name_sym)
        if sig < 0:
            self.refuse("has no finalized signature")
            return
        let param_start = ast.fn_meta_param_start(meta)
        let param_count = ast.fn_meta_param_count(meta)
        if sema.sig_get_param_count(sig) != param_count:
            self.refuse(f"declares {param_count} parameters but its signature has {sema.sig_get_param_count(sig)}")
            return
        var params = ""
        var params_row = ""
        for pi in 0..param_count:
            let pname = with_str_clone_ref(sema.pool_resolve(ast.fn_param_name(param_start, pi)))
            if pname.len() == 0:
                self.refuse(f"parameter {pi} has no name")
                return
            let spelling = self.spell(sema, sema.sig_param_type(sig, pi))
            if self.failed:
                return
            if pi > 0:
                params = params ++ ", "
            params = params ++ pname ++ ": " ++ spelling
            params_row = params_row ++ pname ++ ":" ++ spelling ++ ";"
        let variadic = sema.sig_is_variadic(sig) != 0
        if variadic:
            params = params ++ (if param_count > 0: ", ..." else: "...")
        let ret = self.spell(sema, sema.sig_return_type(sig))
        if self.failed:
            return
        let variadic_text = if variadic: "1" else: "0"
        self.push_export(BX_EXTERN, mod_path, name, attrs ++ "pub extern fn " ++ name ++ "(" ++ params ++ ") -> " ++ ret ++ "\n", "extern\t" ++ mod_path ++ "\t" ++ name ++ "\t" ++ variadic_text ++ "\t" ++ cc_row ++ "\tparams:" ++ params_row ++ "\tret:" ++ ret ++ "\n")

    // The impl blocks of an exported type, printed with their methods nested
    // (impl→method association is span-based in Sema; nesting reproduces it).
    mut fn emit_impls_of(sema: &Sema, type_sym: i32, type_name: &str):
        let ast = sema.ast
        for ii in 0..self.impl_type_syms.len() as i32:
            if self.impl_type_syms[ii] != type_sym:
                continue
            let idi = self.impl_decl_indices[ii]
            let impl_node = ast.get_decl(idi) as i32
            let mod_path = with_str_clone_ref(self.decl_modules[idi])
            let trait_sym = ast.get_data2(impl_node)
            let trait_name = if trait_sym != 0: with_str_clone_ref(sema.pool_resolve(trait_sym)) else: ""
            self.context = mod_path ++ ": impl " ++ (if trait_sym != 0: trait_name ++ " for " else: "") ++ type_name
            self.failed = false
            if trait_sym == sema.syms.copy_trait or trait_name == "Copy":
                // Copy-ness is printed with the type (from is_copy_frozen).
                continue
            if ast.is_extend_impl_node(impl_node) != 0:
                self.refuse("is an extension block; extensions do not cross a bundle boundary")
                continue
            if ast.get_extra(ast.get_data1(impl_node)) > 0:
                self.refuse("binds associated types; no interface spelling (Level 0)")
                continue
            let tp_meta = ast.find_impl_type_params(impl_node)
            if tp_meta >= 0 and ast.state.impl_type_params[(tp_meta + 2)] > 0:
                self.refuse("is generic; a bundle boundary is Level 0 (docs/abi_roadmap.md)")
                continue
            if ast.find_impl_target_type_node(impl_node) != 0:
                self.refuse("targets a generic instantiation; a bundle boundary is Level 0 (docs/abi_roadmap.md)")
                continue
            // methods: every fn decl Sema associated with this impl, by name
            var method_names: Vec[str] = Vec.new()
            var method_decls: Vec[i32] = Vec.new()
            for mdi in 0..ast.decl_count():
                if not sema.method_decl_impl_nodes.contains(mdi):
                    continue
                let owner: i32 = sema.method_decl_impl_nodes.get(mdi).unwrap()
                if owner != impl_node:
                    continue
                let mnode = ast.get_decl(mdi) as i32
                method_names.push(with_str_clone_ref(sema.pool_resolve(sema.fn_decl_semantic_symbol_at(mnode, ast.get_data0(mnode), mdi))))
                method_decls.push(mdi)
            let ordered = bx_sorted_strings(&method_names)
            var body = ""
            var rows = ""
            var method_count = 0
            for oi in 0..ordered.len() as i32:
                for mi in 0..method_names.len() as i32:
                    if method_names[mi] != ordered[oi]:
                        continue
                    let mdi = method_decls[mi]
                    let text = self.fn_text(sema, mdi, ast.get_decl(mdi) as i32, true, trait_sym != 0)
                    if text.len() == 0:
                        continue
                    let row = with_str_clone_ref(self.last_fn_row)
                    // indent every line of the method (attribute lines too)
                    var start: i64 = 0
                    while start < text.len():
                        var end = start
                        while end < text.len() and text[end] != '\n':
                            end = end + 1
                        body = body ++ "    " ++ text.slice(start, end) ++ "\n"
                        start = end + 1
                    rows = rows ++ row
                    method_count = method_count + 1
            if self.errors.len() > 0 and self.failed:
                continue
            if method_count == 0:
                if trait_sym == 0:
                    continue
                self.context = mod_path ++ ": impl " ++ trait_name ++ " for " ++ type_name
                self.refuse("has no methods to print; an empty trait impl has no interface spelling")
                continue
            let head = "impl " ++ (if trait_sym != 0: trait_name ++ " for " else: "") ++ type_name ++ ":\n"
            let export_name = type_name ++ "." ++ (if trait_sym != 0: trait_name else: "")
            self.push_export(BX_IMPL, mod_path, export_name, head ++ body, "impl\t" ++ mod_path ++ "\t" ++ type_name ++ "\t" ++ (if trait_sym != 0: trait_name else: "-") ++ "\n" ++ rows)

    mut fn emit_type(sema: &Sema, di: i32, node: i32):
        let ast = sema.ast
        let mod_path = with_str_clone_ref(self.decl_modules[di])
        let name_sym = ast.get_data0(node)
        let name = with_str_clone_ref(sema.pool_resolve(name_sym))
        let packed = ast.get_data2(node)
        let sub_kind = type_decl_sub_kind(packed)
        let extra_start = ast.get_data1(node)
        self.context = mod_path ++ ": type " ++ name
        self.failed = false
        let is_pub = self.decl_is_pub_type(sema, node)
        if type_decl_is_ephemeral(packed) != 0:
            self.refuse("is ephemeral; not a bundle interface surface")
            return
        if sema.type_decl_tp_count(node) > 0:
            self.refuse("is generic; a bundle boundary is Level 0 (docs/abi_roadmap.md)")
            return
        let type_meta = ast.find_type_meta(node)
        if type_meta >= 0:
            let derive_start = ast.type_meta_derive_start(type_meta)
            for dvi in 0..ast.type_meta_derive_count(type_meta):
                let derive_sym = ast.get_extra(derive_start + dvi)
                if sema.pool_resolve(derive_sym) != "Copy":
                    self.refuse("derives '" ++ sema.pool_resolve(derive_sym) ++ "'; a derived impl has no interface spelling")
                    return
        if not sema.type_decl_tids.contains(node):
            self.refuse("has no type id")
            return
        let tid: i32 = sema.type_decl_tids.get(node).unwrap()
        let resolved = sema.resolve_alias(tid)
        if sub_kind != TypeDeclKind.Alias and sema.has_drop_method(name_sym) != 0:
            self.refuse("has a drop method; a .wi carries no Drop impl and nobody drops bundle storage (Level 0)")
            return
        var attrs = ""
        var flags_row = ""
        if type_decl_is_repr_c(packed) != 0 and type_decl_is_packed(packed) == 0:
            attrs = attrs ++ "@[repr(C)]\n"
            flags_row = flags_row ++ "repr-c,"
        if type_decl_is_packed(packed) != 0:
            attrs = attrs ++ "@[packed]\n"
            flags_row = flags_row ++ "packed,"
        if type_decl_is_bitpacked(packed) != 0:
            attrs = attrs ++ "@[bitpacked]\n"
            flags_row = flags_row ++ "bitpacked,"
        if type_decl_is_specified(packed) != 0:
            attrs = attrs ++ "@[specified]\n"
            flags_row = flags_row ++ "specified,"
        let pub_text = if is_pub: "pub " else: ""
        let vis = if is_pub: "pub" else: "priv"
        var decl = ""
        var kind_row = ""
        var fields_row = ""
        var variants_row = ""
        var has_layout = true
        if sub_kind == TypeDeclKind.Struct or sub_kind == TypeDeclKind.Union:
            if sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
                self.refuse("is not a struct type in Sema")
                return
            kind_row = if sub_kind == TypeDeclKind.Union: "union" else: "struct"
            let te_start = sema.get_type_d1(resolved)
            let field_count = sema.get_type_d2(resolved)
            var fields = ""
            for fi in 0..field_count:
                let f_name = with_str_clone_ref(sema.pool_resolve(sema.type_extra[(te_start + fi * 3)]))
                let f_tid = sema.type_extra[(te_start + fi * 3 + 1)]
                let f_default = sema.type_extra[(te_start + fi * 3 + 2)]
                let align_slot = te_start + field_count * 3 + fi
                let f_align: i32 = if align_slot < sema.type_extra.len() as i32: sema.type_extra[align_slot] else: 0
                let f_spelling = self.spell(sema, f_tid)
                if self.failed:
                    return
                var f_default_text = ""
                if f_default != 0:
                    f_default_text = self.literal_text(sema, f_default, false)
                    if self.failed:
                        return
                if fi > 0:
                    fields = fields ++ ", "
                if f_align > 0:
                    fields = fields ++ f"@[align({f_align})] "
                fields = fields ++ f_name ++ ": " ++ f_spelling
                if f_default_text.len() > 0:
                    fields = fields ++ " = " ++ f_default_text
                let offset = sema.type_layout_struct_field_offset_frozen(resolved as i32, fi)
                fields_row = fields_row ++ f_name ++ ":" ++ f_spelling ++ f":{offset}:{f_align}:" ++ f_default_text ++ ";"
            let body = if field_count == 0: "{}" else: "{ " ++ fields ++ " }"
            decl = if sub_kind == TypeDeclKind.Union: pub_text ++ "type " ++ name ++ " = union " ++ body else: pub_text ++ "type " ++ name ++ " " ++ body
        else if sub_kind == TypeDeclKind.Opaque:
            kind_row = "opaque"
            has_layout = false
            decl = pub_text ++ "type " ++ name ++ " = opaque"
        else if sub_kind == TypeDeclKind.Distinct:
            kind_row = "distinct"
            let te_start = sema.get_type_d1(resolved)
            let inner = self.spell(sema, sema.type_extra[(te_start + 1)])
            if self.failed:
                return
            decl = pub_text ++ "type " ++ name ++ " = distinct " ++ inner
            fields_row = "inner:" ++ inner ++ ";"
        else if sub_kind == TypeDeclKind.Alias:
            kind_row = "alias"
            has_layout = false
            let target = self.spell(sema, sema.get_type_d0(tid))
            if self.failed:
                return
            decl = pub_text ++ "type " ++ name ++ " = " ++ target
            fields_row = "target:" ++ target ++ ";"
        else if sub_kind == TypeDeclKind.Enum or sub_kind == TypeDeclKind.DiscEnum:
            if sema.get_type_kind(resolved) != TypeKind.TY_ENUM:
                self.refuse("is not an enum type in Sema")
                return
            let is_disc = sema.disc_repr_types.contains(resolved as i32)
            kind_row = if is_disc: "disc-enum" else: "enum"
            var head = pub_text ++ "enum " ++ name ++ ":"
            if is_disc:
                let repr: i32 = sema.disc_repr_types.get(resolved as i32).unwrap()
                let repr_spelling = self.spell(sema, repr)
                if self.failed:
                    return
                head = pub_text ++ "enum " ++ name ++ ": " ++ repr_spelling ++ ":"
                variants_row = "repr:" ++ repr_spelling ++ "|"
            let variant_count = sema.type_reflection_variant_count(resolved as i32)
            if variant_count == 0:
                self.refuse("has no variants; no interface spelling")
                return
            var body = ""
            for vi in 0..variant_count:
                let v_name = with_str_clone_ref(sema.pool_resolve(sema.type_reflection_variant_name(resolved as i32, vi)))
                let payload_count = sema.type_reflection_variant_payload_count(resolved as i32, vi)
                let pos = sema.type_reflection_variant_position(resolved as i32, vi)
                var payloads = ""
                var payloads_row = ""
                for ppi in 0..payload_count:
                    let p_spelling = self.spell(sema, sema.type_extra[(pos + 2 + ppi)])
                    if self.failed:
                        return
                    if ppi > 0:
                        payloads = payloads ++ ", "
                        payloads_row = payloads_row ++ ","
                    payloads = payloads ++ p_spelling
                    payloads_row = payloads_row ++ p_spelling
                var line = "    " ++ v_name
                if payload_count > 0:
                    line = line ++ "(" ++ payloads ++ ")"
                var disc_row = "-"
                if is_disc:
                    let disc = sema.type_reflection_variant_discriminant(resolved as i32, vi)
                    line = line ++ f" = {disc}"
                    disc_row = f"{disc}"
                body = body ++ line ++ "\n"
                variants_row = variants_row ++ v_name ++ ":" ++ disc_row ++ ":" ++ payloads_row ++ ";"
            decl = head ++ "\n" ++ body
        else:
            self.refuse(f"type declaration kind {sub_kind} has no interface spelling")
            return
        if not decl.ends_with("\n"):
            decl = decl ++ "\n"
        var copy_line = ""
        var copy_row = "0"
        if sub_kind != TypeDeclKind.Alias and sub_kind != TypeDeclKind.Distinct and sema.is_copy_frozen(tid) != 0:
            copy_line = "impl Copy for " ++ name ++ "\n"
            copy_row = "1"
        if sub_kind == TypeDeclKind.Distinct and sema.is_copy_frozen(tid) != 0:
            copy_row = "1"
        var layout_row = "-\t-"
        if has_layout:
            let size = sema.type_layout_size_of_frozen(resolved as i32)
            let align = sema.type_layout_align_of_frozen(resolved as i32)
            layout_row = f"{size}\t{align}"
        let row = "type\t" ++ mod_path ++ "\t" ++ name ++ "\t" ++ kind_row ++ "\t" ++ layout_row ++ "\t" ++ copy_row ++ "\t" ++ flags_row ++ "\t" ++ vis ++ "\tfields:" ++ fields_row ++ "\tvariants:" ++ variants_row ++ "\n"
        self.push_export(BX_TYPE, mod_path, name, attrs ++ decl ++ copy_line, row)
        self.emit_impls_of(sema, name_sym, name)

    // ── The walk ──────────────────────────────────────────────────────
    mut fn walk(sema: &Sema):
        let ast = sema.ast
        let dc = ast.decl_count()
        if sema.decl_source_paths.len() as i32 != dc:
            self.refuse_global(f"bundle interface: decl_source_paths has {sema.decl_source_paths.len() as i32} entries for {dc} declarations (Analysis.w invariant)")
            return
        for di in 0..dc:
            let path = sema.decl_source_paths[di]
            let canonical = codegen_canonical_module_path(path)
            if bundle_corpus_contains(self.corpus, canonical):
                self.decl_modules.push(with_str_clone_ref(canonical))
                self.add_module(canonical, path)
                let decl = ast.get_decl(di) as i32
                let kind = ast.kind(decl)
                if kind == NodeKind.NK_TYPE_DECL:
                    self.type_decl_index.insert(ast.get_data0(decl), di)
                else if kind == NodeKind.NK_IMPL_DECL:
                    self.impl_type_syms.push(ast.get_data0(decl))
                    self.impl_decl_indices.push(di)
            else:
                self.decl_modules.push("")
        // Every corpus module in the module graph, declarations or not: a
        // module holding only `use` lines (pcre2's migrated table modules)
        // still needs a section, or a consumer's `use` of it resolves to
        // nothing once the source is not embedded.
        for mi in 0..sema.module_paths.len() as i32:
            let path = sema.module_paths[mi]
            let canonical = codegen_canonical_module_path(path)
            if bundle_corpus_contains(self.corpus, canonical):
                self.add_module(canonical, path)
        if self.modules.len() == 0:
            self.refuse_global("bundle interface: no module under corpus '" ++ self.corpus ++ "' in this compilation (--bundle-corpus names a path under the embedded std tree, e.g. std/re)")
            return
        for di in 0..dc:
            let mod_path = with_str_clone_ref(self.decl_modules[di])
            if mod_path.len() == 0:
                continue
            let decl = ast.get_decl(di) as i32
            let kind = ast.kind(decl)
            if kind == NodeKind.NK_USE_DECL:
                if ast.get_data2(decl) > 0:
                    self.context = mod_path ++ ": use"
                    self.refuse("is a selector import (`use a.b.{x}`); no interface spelling (Level 0)")
                continue
            if kind == NodeKind.NK_LET_DECL:
                self.emit_let(sema, di, decl)
                continue
            if kind == NodeKind.NK_FN_DECL:
                if sema.impl_node_for_method_decl(decl) != 0:
                    continue
                let _ = self.fn_text(sema, di, decl, false, false)
                continue
            if kind == NodeKind.NK_EXTERN_FN:
                self.emit_extern(sema, di, decl)
                continue
            if kind == NodeKind.NK_TYPE_DECL:
                if self.decl_is_pub_type(sema, decl):
                    self.note_named_type(ast.get_data0(decl))
                continue
            if kind == NodeKind.NK_IMPL_DECL:
                let type_sym = ast.get_data0(decl)
                if not self.type_decl_index.contains(type_sym):
                    self.context = mod_path ++ ": impl for " ++ sema.pool_resolve(type_sym)
                    self.refuse("targets a type declared outside the corpus; an orphan impl has no interface home")
                continue
            if kind == NodeKind.NK_TRAIT_DECL:
                self.context = mod_path ++ ": trait " ++ sema.pool_resolve(ast.get_data0(decl))
                self.refuse("traits are not a bundle interface surface (Level 0)")
                continue
            if kind == NodeKind.NK_C_IMPORT:
                self.context = mod_path ++ ": c_import"
                self.refuse("a bundle module cannot c_import (compiler-owned code uses extern)")
                continue
            if kind == NodeKind.NK_EXTERN_VAR:
                self.context = mod_path ++ ": extern var " ++ sema.pool_resolve(ast.get_data0(decl))
                self.refuse("extern storage has no interface spelling (Level 0)")
                continue
            self.context = mod_path ++ ": declaration"
            self.refuse(bx_node_kind_name(kind) ++ " has no interface spelling")
        // the type closure: pub types, then every corpus type a printed
        // declaration named (field, payload, parameter and return types)
        var ti = 0
        while ti < self.named_type_syms.len() as i32:
            let sym = self.named_type_syms[ti]
            ti = ti + 1
            if not self.type_decl_index.contains(sym):
                continue
            let di: i32 = self.type_decl_index.get(sym).unwrap()
            self.emit_type(sema, di, ast.get_decl(di) as i32)

// Build the exported-declaration model of the corpus modules in `sema`.
pub fn bundle_interface_build(sema: &Sema, corpus: &str, unlowered_globals: &Vec[str]) -> BundleInterfaceModel:
    var em = bx_new_emitter(corpus, unlowered_globals)
    em.walk(sema)
    let ordered = bx_sorted_strings(&em.modules)
    var sources: Vec[str] = Vec.new()
    for oi in 0..ordered.len() as i32:
        for mi in 0..em.modules.len() as i32:
            if em.modules[mi] == ordered[oi]:
                sources.push(with_str_clone_ref(em.module_sources[mi]))
    BundleInterfaceModel {
        ok: em.errors.len() == 0,
        corpus: with_str_clone_ref(corpus),
        modules: ordered,
        module_sources: sources,
        exports: move em.exports,
        errors: move em.errors,
        warnings: move em.warnings,
        omitted: move em.omitted,
    }

// The export indices of one module in canonical order: kind, then name.
fn bx_module_export_order(model: &BundleInterfaceModel, mod_path: &str) -> Vec[i32]:
    var order: Vec[i32] = Vec.new()
    for kind in 0..7:
        var names: Vec[str] = Vec.new()
        for ei in 0..model.exports.len() as i32:
            let e = model.exports[ei]
            if e.kind == kind and e.mod_path == mod_path:
                names.push(with_str_clone_ref(e.name))
        let sorted = bx_sorted_strings(&names)
        for si in 0..sorted.len() as i32:
            for ei in 0..model.exports.len() as i32:
                let e = model.exports[ei]
                if e.kind == kind and e.mod_path == mod_path and e.name == sorted[si] and not order.contains(ei):
                    order.push(ei)
                    break
    order

// The `.wi` text: one `module <path>` section per corpus module (sorted),
// the module's `use` lines in import order, then its exports.
pub fn bundle_interface_render(sema: &Sema, model: &BundleInterfaceModel) -> BundleInterfaceText:
    var out = StringBuilder.new()
    var errors: Vec[str] = Vec.new()
    for mi in 0..model.modules.len() as i32:
        let mod_path = model.modules[mi]
        let source_path = model.module_sources[mi]
        out.push_str("module " ++ mod_path ++ "\n")
        var line_count = 0
        if not sema.module_index_by_path.contains(with_str_clone_ref(source_path)):
            errors.push("bundle interface: " ++ mod_path ++ ": not in Sema's module graph (" ++ source_path ++ ")")
            continue
        let module_index: i32 = sema.module_index_by_path.get(with_str_clone_ref(source_path)).unwrap()
        let edge_start = sema.module_import_starts[module_index]
        let edge_count = sema.module_import_counts[module_index]
        for ei in 0..edge_count:
            let import_path = sema.module_import_paths[(edge_start + ei)]
            if import_path == "std.prelude" or import_path == "std.prelude_core" or import_path == "std.prelude_alloc":
                continue
            out.push_str("use " ++ import_path ++ "\n")
            line_count = line_count + 1
        let order = bx_module_export_order(model, mod_path)
        for oi in 0..order.len() as i32:
            out.push_str(model.exports[order[oi]].wi)
            line_count = line_count + 1
        if line_count == 0:
            // a section must be non-empty to count as bundle-provided
            out.push_str("// no exported declarations\n")
    BundleInterfaceText { text: out.to_str(), errors }
