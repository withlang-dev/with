// D39 bundle interfaces (docs/spec/toolchain/wo_bundles.md, decisions.md D39): the `.wi`
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
use SemaCheck
use SemaDecl
use FnAbi
use compiler.BundleInterfaces
use std.string.StringBuilder
use std.collections.HashMap
use SemaTypes
use render

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
    modules: List[str],
    module_sources: List[str],
    exports: List[BundleExport],
    errors: List[str],
    // source pass only: a declaration whose body-inferred effects disagree
    // with what it declares (D39: the boundary exposes the mistaken
    // declaration)
    warnings: List[str],
    // D39 Level 0: generic functions stay corpus-internal — omitted from the
    // interface, named here ("<module>\t<name>\tgeneric-fn") for the
    // manifest's `omitted` lines
    omitted: List[str],
    // "<module>\t<canonical path>" per module OUTSIDE the corpus whose type a
    // declaration of <module> names: the only non-corpus `use` lines a
    // section carries (a body's imports are implementation, never interface)
    needed_imports: List[str],
}

type BundleEmitter {
    corpus: str,
    // "<canonical module>\t<name>" per owned global codegen could not fold
    // to data (Codegen.bundle_unlowered_globals); empty on the .wi pass
    unlowered_globals: List[str],
    errors: List[str],
    warnings: List[str],
    // canonical module path per decl index ("" outside the corpus)
    decl_modules: List[str],
    modules: List[str],
    module_sources: List[str],
    // corpus type declarations: name symbol → decl index
    type_decl_index: HashMap[i32, i32],
    // impl blocks in the corpus: target type symbol and decl index, parallel
    impl_type_syms: List[i32],
    impl_decl_indices: List[i32],
    // the type closure worklist: name symbols a printed declaration named
    named_type_syms: List[i32],
    named_type_seen: HashMap[i32, i32],
    // every type declaration in the compilation: name symbol → canonical
    // module path, so a named non-corpus type finds the `use` it needs
    type_decl_paths: HashMap[i32, str],
    // the module whose declaration is being printed, and per module the
    // type symbols its declarations named ("<module>\t<sym>" deduped)
    current_module: str,
    named_in_module_paths: List[str],
    named_in_module_syms: List[i32],
    named_in_module_seen: HashMap[str, i32],
    exports: List[BundleExport],
    // "<module>: <declaration>" for messages
    context: str,
    // a refusal fired inside the current declaration
    failed: bool,
    // the fingerprint row of the method fn_text last printed for an impl
    last_fn_row: str,
    omitted: List[str],
    // Sema's call graph by caller, for each function's global effects
    // (fn_global_effects; D39 / §21.1 rule 1)
    call_index: SemaGlobalCallIndex,
    // every global the corpus declares, exported or private, by name
    // (check_declared_global_writes)
    corpus_global_names: HashMap[str, i32],
    // §21.1 rule 6 (#1903, Eric 2026-10-03): every global a corpus
    // function's `from` clause names, by name — part of the interface even
    // when private: the `.wi` declares it without `pub` (an identity a
    // consumer cannot name), and every exported function that writes it
    // declares the write (check_declared_global_writes).
    origin_global_names: HashMap[str, i32],
}

pub type BundleInterfaceText {
    text: str,
    errors: List[str],
}

fn bx_new_emitter(corpus: &str, unlowered_globals: &List[str]) -> BundleEmitter:
    BundleEmitter {
        corpus: with_str_clone_ref(corpus),
        unlowered_globals: sema_clone_str_list(unlowered_globals),
        errors: List.new(),
        warnings: List.new(),
        decl_modules: List.new(),
        modules: List.new(),
        module_sources: List.new(),
        type_decl_index: HashMap.new(),
        impl_type_syms: List.new(),
        impl_decl_indices: List.new(),
        named_type_syms: List.new(),
        named_type_seen: HashMap.new(),
        type_decl_paths: HashMap.new(),
        current_module: "",
        named_in_module_paths: List.new(),
        named_in_module_syms: List.new(),
        named_in_module_seen: HashMap.new(),
        exports: List.new(),
        context: "",
        failed: false,
        last_fn_row: "",
        omitted: List.new(),
        call_index: SemaGlobalCallIndex { head: HashMap.new(), next: List.new() },
        corpus_global_names: HashMap.new(),
        origin_global_names: HashMap.new(),
    }

fn bx_str_less(a: &str, b: &str) -> bool: with_str_cmp_ref(a, b) < 0

// Insertion-sorted copy (bytewise); the model is small.
fn bx_sorted_strings(items: &List[str]) -> List[str]:
    var sorted: List[str] = List.new()
    for i in 0..items.len() as i32:
        let item = items[i]
        var out: List[str] = List.new()
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
        if sym == 0:
            return
        if self.current_module.len() > 0:
            let key = self.current_module ++ "\t" ++ f"{sym}"
            if not self.named_in_module_seen.contains(key):
                self.named_in_module_seen.insert(with_str_clone_ref(key), 1)
                self.named_in_module_paths.push(with_str_clone_ref(self.current_module))
                self.named_in_module_syms.push(sym)
        if self.named_type_seen.contains(sym):
            return
        self.named_type_seen.insert(sym, 1)
        self.named_type_syms.push(sym)

    // The non-corpus `use` lines each section needs: a module outside the
    // corpus is imported by a section only when one of that section's
    // declarations names a type it declares.
    fn needed_imports() -> List[str]:
        var out: List[str] = List.new()
        for ni in 0..self.named_in_module_syms.len() as i32:
            let sym = self.named_in_module_syms[ni]
            if not self.type_decl_paths.contains(sym):
                continue
            let path = self.type_decl_paths.get(sym).unwrap()
            if bundle_corpus_contains(self.corpus, path):
                continue
            let row = self.named_in_module_paths[ni] ++ "\t" ++ path
            if not out.contains(row):
                out.push(row)
        out

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
        if tk == TypeKind.TY_VA_LIST:
            return "c_va_list"
        // §4.3d: the parameterized spelling, which every shape has.
        if tk == TypeKind.TY_VECTOR:
            return f"Vector[{sema.get_type_d1(resolved)}, " ++ self.spell(sema, sema.get_type_d0(resolved)) ++ "]"
        if tk == TypeKind.TY_MASK:
            return f"Mask[{sema.get_type_d1(resolved)}, {sema.get_type_d0(resolved)}]"
        if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM:
            let name_sym = sema.get_type_d0(resolved)
            let name = with_str_clone_ref(sema.pool_resolve(name_sym))
            if name.len() == 0:
                self.refuse("names an anonymous type")
                return ""
            self.note_named_type(name_sym)
            return name
        if tk == TypeKind.TY_ARRAY:
            // D119: `[T; 2, 3]`, the dimensions in index order.
            var dims = f"{sema.get_type_d1(resolved)}"
            var elem = sema.get_type_d0(resolved)
            while sema.get_type_kind(sema.resolve_alias(elem as TypeId)) == TypeKind.TY_ARRAY:
                let inner = sema.resolve_alias(elem as TypeId)
                dims = dims ++ f", {sema.get_type_d1(inner)}"
                elem = sema.get_type_d0(inner)
            return "[" ++ self.spell(sema, elem) ++ "; " ++ dims ++ "]"
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
            // #1832: a C variadic function pointer.
            if sema.variadic_fn_type_set.contains(resolved as i32):
                out = out ++ (if param_count > 0: ", ..." else: "...")
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
        let name = with_str_clone_ref(sema.pool_resolve(ast.get_data0(node)))
        let is_const = ast.is_const_decl_node(node) != 0
        // A private global is printed only as a returned view's origin.
        let is_pub = (flags / 2) % 2 != 0
        if not is_pub and (is_const or not self.origin_global_names.contains(name)):
            return
        let mod_path = with_str_clone_ref(self.decl_modules[di])
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
        let keyword = (if is_pub: "pub " else: "") ++ (if is_mut: "var " else: "let ")
        let mut_text = if is_mut: "1" else: "0"
        let vis_text = if is_pub: "" else: "\tpriv"
        self.push_export(BX_GLOBAL, mod_path, name, keyword ++ name ++ ": " ++ spelling ++ "\n", "global\t" ++ mod_path ++ "\t" ++ name ++ "\t" ++ spelling ++ "\t" ++ mut_text ++ vis_text ++ "\n")

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
            self.refuse("is async, gen or comptime; a bundle boundary is Level 0 (docs/spec/abi/abi_roadmap.md)")
            return ""
        // A variadic function crosses the boundary spelled as in source
        // (`..., ...`): §18.5c makes a .wi ordinary declaration syntax, and
        // Sema gives the declaration a variadic signature exactly as it gives
        // one to the source (a migrated C corpus keeps its C-shaped entries,
        // zlib's gzprintf). The fingerprint row carries the marker.
        let is_variadic = (flags / FnFlags.VARIADIC) % 2 != 0
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
                self.refuse("is @[c_export]; a bundle exports a With surface, never a C one (docs/spec/toolchain/wo_bundles.md)")
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
        // §21.1 rule 6 (#1903): a `from` clause states the origins, in place
        // of elision; its parameters are the ones that escape as views.
        let from_entries = sema.declared_view_origin_entries(node)
        let has_from = ast.fn_view_origin_count(node) > 0
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
                self.note_effect_disagreement(sema, node, sig, pi, full, pname, eff, if has_from: (if from_entries.contains(-1 - pi): pi else: DECLARED_ORIGIN_NONE) else: origin)
                continue
            let spelling = self.spell(sema, ptid)
            if self.failed:
                return ""
            if printed > 0:
                params = params ++ ", "
            let noalias = fn_param_is_noalias(pflags) != 0
            // §12.4 (D75): the bundle interface records `once` — a consumer
            // may pass a consuming closure only to such a parameter.
            let once = fn_param_is_once(pflags)
            params = params ++ (if noalias: "@[noalias] " else: "") ++ pname ++ ": " ++ (if once: "once " else: "") ++ spelling
            params_row = params_row ++ pname ++ ":" ++ spelling ++ f":{vra}:{eff}" ++ (if noalias: ":noalias" else: "") ++ (if once: ":once" else: "") ++ ";"
            printed = printed + 1
            // A `once` callable is consumed by its one invocation: the
            // declared consume is the contract, not a mistaken `&T`.
            if not once:
                self.note_effect_disagreement(sema, node, sig, pi, full, pname, eff, if has_from: (if from_entries.contains(-1 - pi): pi else: DECLARED_ORIGIN_NONE) else: origin)
        if is_variadic:
            params = params ++ (if printed > 0: ", ..." else: "...")
            params_row = params_row ++ "...;"
        // §21.1 rule 1 (D39, Eric 2026-09-29): an exported function's writes
        // of exported globals are a declared, checked contract — never an
        // inferred fact in the interface. The declared set is the function's
        // `writes` clause (declared_global_writes); no clause declares none.
        // From a source body the bundle build checks it against Sema's
        // transitive write set (check_declared_global_writes). The `.wi`
        // prints the clause exactly as written; its twin reprints the parsed
        // clause, and the fingerprint carries the resolved set, so the two
        // agree only when the printed contract is the declared one.
        let declared = self.declared_global_writes(sema, node)
        if self.failed:
            return ""
        let written_clause = self.written_writes_clause(sema, node)
        if not ast.fn_decl_body_is_interface(node):
            self.check_declared_global_writes(sema, sig, &declared, full, written_clause.len() > 0)
            if self.failed:
                return ""
        var writes_row = ""
        for wi in 0..declared.len() as i32:
            writes_row = writes_row ++ declared[wi] ++ ";"
        let ret = self.spell(sema, sema.sig_return_type(sig))
        if self.failed:
            return ""
        // A returned view of a global crosses the boundary only as a stated
        // origin: the interface carries no body-inferred fact (D39), and
        // elision names a parameter, never a global (§21.1 rule 6).
        if not has_from and not ast.fn_decl_body_is_interface(node):
            let derived_globals = sema.sig_derived_global_origins(sig)
            if derived_globals.len() > 0:
                var clause = ""
                for pi in 0..param_count:
                    if (sema.sig_param_effect(sig, pi) & EFF_ESCAPE_VIEW) != 0:
                        clause = clause ++ (if clause.len() == 0: "from " else: ", ") ++ sema.pool_resolve(ast.fn_param_name(param_start, pi))
                for gi in 0..derived_globals.len() as i32:
                    clause = clause ++ (if clause.len() == 0: "from " else: ", ") ++ sema.pool_resolve(derived_globals[gi])
                self.refuse("returns a view of the global `" ++ sema.pool_resolve(derived_globals[0]) ++ "`, an origin its declaration does not state: a bundle interface states every origin of a returned view (§21.1 rule 6, D39); write `" ++ clause ++ "` after the return type")
                return ""
            // "An absent clause means the §21.1 elision (the receiver, else
            // the single borrowed parameter)": a body that returns a view of
            // another parameter states it, or a consumer would tie the result
            // to the wrong argument.
            if origin != DECLARED_ORIGIN_AMBIGUOUS:
                var clause = ""
                var stray = ""
                for pi in 0..param_count:
                    if (sema.sig_param_effect(sig, pi) & EFF_ESCAPE_VIEW) == 0:
                        continue
                    let pname: str = with_str_clone_ref(sema.pool_resolve(ast.fn_param_name(param_start, pi)))
                    clause = clause ++ (if clause.len() == 0: "from " else: ", ") ++ pname
                    if pi != origin and stray.len() == 0:
                        stray = pname
                if stray.len() > 0:
                    let elided = if origin >= 0: "`" ++ sema.pool_resolve(ast.fn_param_name(param_start, origin)) ++ "`" else: "none"
                    self.refuse("returns a view derived from `" ++ stray ++ "`, but with no `from` clause its origin at a bundle boundary is the §21.1 elision (" ++ elided ++ ": the receiver, else the single borrowed parameter); write `" ++ clause ++ "` after the return type")
                    return ""
        if origin == DECLARED_ORIGIN_AMBIGUOUS and not has_from:
            self.refuse("returns a reference with no unambiguous origin: name the origin in the source signature (D39 elision: receiver, else the single borrowed parameter), or write `from static` for a view of static data (§21.1 rule 6)")
            return ""
        var from_text = ""
        var from_row = ""
        if has_from:
            from_text = " " ++ self.written_from_clause(sema, node)
            for ei in 0..from_entries.len() as i32:
                let entry = from_entries[ei]
                if entry == FROM_STATIC_ENTRY:
                    from_row = from_row ++ "static;"
                else if entry < 0:
                    from_row = from_row ++ "param:" ++ sema.pool_resolve(ast.fn_param_name(param_start, -1 - entry)) ++ ";"
                else:
                    let entries = self.exported_global_entries(sema, entry)
                    if entries.len() == 0:
                        self.refuse("`from " ++ sema.pool_resolve(entry) ++ "` names a global outside this bundle that is no bundle export; a returned view's global origin is this bundle's global or an exported one (§21.1 rule 6)")
                        return ""
                    for xi in 0..entries.len() as i32:
                        from_row = from_row ++ "global:" ++ entries[xi] ++ ";"
        let is_unsafe = sema.fn_symbol_is_unsafe(fn_sym) != 0
        let must_use = (flags / FnFlags.MUST_USE) % 2 != 0
        var printed_name = with_str_clone_ref(full)
        if in_impl:
            let dot = sema_str_find_char(full, '.')
            if dot >= 0:
                printed_name = with_str_clone_ref(full.slice((dot + 1) as i64, full.len()))
        // The `writes` clause is the declaration's last clause (§21.1 rule 1).
        let writes_text = if written_clause.len() > 0: " " ++ written_clause else: ""
        var head = if must_use: "@[must_use]\n" else: ""
        head = head ++ (if is_pub: "pub " else: "") ++ (if is_unsafe: "unsafe " else: "") ++ receiver ++ "fn " ++ printed_name ++ "(" ++ params ++ ") -> " ++ ret ++ from_text ++ writes_text ++ "\n"
        let vis = if is_pub: "pub" else: "priv"
        let unsafe_text = if is_unsafe: "1" else: "0"
        let must_use_text = if must_use: "must_use" else: "-"
        let row = "fn\t" ++ mod_path ++ "\t" ++ full ++ "\t" ++ unsafe_text ++ "\t" ++ receiver_row ++ "\t" ++ must_use_text ++ "\tparams:" ++ params_row ++ "\tret:" ++ ret ++ (if has_from: "\torigin:from:" ++ from_row else: f"\torigin:{origin}") ++ "\tvis:" ++ vis ++ "\twrites:" ++ writes_row ++ "\n"
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

    // §21.1 rule 1 (Eric 2026-09-29): the exported globals a function's
    // `writes` clause declares (Sema.resolve_declared_global_writes), as
    // sorted "<module>#<name>" entries — empty for no clause. A clause
    // naming a global that is no bundle export is refused: only exported
    // globals are part of the interface, and a consumer could not resolve it.
    mut fn declared_global_writes(sema: &Sema, node: i32) -> List[str]:
        var out: List[str] = List.new()
        let syms = sema.declared_global_write_syms(node)
        for si in 0..syms.len() as i32:
            let entries = self.exported_global_entries(sema, syms[si])
            if entries.len() == 0:
                self.refuse("`writes " ++ sema.pool_resolve(syms[si]) ++ "` names a global that is no bundle export: only a bundle's exported globals are part of its interface (§21.1 rule 1)")
            for ei in 0..entries.len() as i32:
                if not out.contains(entries[ei]):
                    out.push(with_str_clone_ref(entries[ei]))
        bx_sorted_strings(&out)

    // The clause as its author wrote it (`writes COUNTER, other.TOTAL`), in
    // source order, "" for none: the `.wi` prints exactly that spelling.
    fn written_writes_clause(sema: &Sema, node: i32) -> str:
        let ast = sema.ast
        var out = ""
        for wi in 0..ast.fn_global_write_count(node):
            let qualifier = ast.fn_global_write_path(node, wi)
            let name = with_str_clone_ref(sema.pool_resolve(ast.fn_global_write_name(node, wi)))
            let entry = if qualifier != 0: sema.pool_resolve(qualifier) ++ "." ++ name else: name
            out = out ++ (if wi == 0: "writes " else: ", ") ++ entry
        out

    // The `from` clause as its author wrote it (`from p, other.G`), in source
    // order; the `.wi` prints exactly that spelling (§21.1 rule 6).
    fn written_from_clause(sema: &Sema, node: i32) -> str:
        let ast = sema.ast
        var out = ""
        for oi in 0..ast.fn_view_origin_count(node):
            let qualifier = ast.fn_view_origin_path(node, oi)
            let name = with_str_clone_ref(sema.pool_resolve(ast.fn_view_origin_name(node, oi)))
            let entry = if qualifier != 0: sema.pool_resolve(qualifier) ++ "." ++ name else: name
            out = out ++ (if oi == 0: "from " else: ", ") ++ entry
        out

    // The exported globals `sym` names, as "<module>#<name>": this corpus's
    // exports of that name (a write record names a global by its symbol,
    // so every export of the name is listed — over-requiring a declaration
    // only fails the build loudly, never lets a view dangle), else another
    // bundle's interface global a `use` brought in (§21.1 rule 1, D39: a
    // call of that bundle's function wrote it through its declared set).
    fn exported_global_entries(sema: &Sema, sym: i32) -> List[str]:
        let name = with_str_clone_ref(sema.pool_resolve(sym))
        var out: List[str] = List.new()
        for xi in 0..self.exports.len() as i32:
            let export = self.exports[xi]
            if export.kind == BX_GLOBAL and export.name == name:
                out.push(export.mod_path ++ "#" ++ name)
        if out.len() == 0 and sema.interface_global_index.contains(sym):
            out.push(sema.interface_global_paths.get(sym).unwrap() ++ "#" ++ name)
        out

    // Whether this corpus exports a global named `name` with `pub` (an
    // origin global is printed without it, emit_let).
    fn global_is_pub_export(name: &str) -> bool:
        for xi in 0..self.exports.len() as i32:
            if self.exports[xi].kind == BX_GLOBAL and self.exports[xi].name == name and self.exports[xi].wi.starts_with("pub "):
                return true
        false

    // §21.1 rule 1 (D39, Eric 2026-09-29): an exported function's
    // transitive writes of exported globals — this bundle's, and another
    // bundle's through its functions' declared sets — must be a subset of
    // its declared set, and no clause declares none: a write outside it
    // fails the bundle build, naming the function, the global and the call
    // path that writes it. A declared global the body does not write is a
    // lint (a conservative contract reserving a future write). A private
    // global is not part of the interface.
    // The refusal offers the literal fix: "add 'writes COUNTER' to bump's
    // declaration", or the name to append to an existing clause.
    mut fn check_declared_global_writes(sema: &Sema, sig: i32, declared: &List[str], fn_name: &str, has_clause: bool):
        let written = sema.fn_global_effects(sig, &self.call_index)
        var actual: List[str] = List.new()
        for wi in 0..written.len() as i32:
            let sym = written[wi]
            let name = with_str_clone_ref(sema.pool_resolve(sym))
            let entries = self.exported_global_entries(sema, sym)
            if entries.len() == 0:
                // Neither an export of this bundle nor of another: a private
                // corpus global, or a global of a module compiled from source
                // beside the bundle — named, since a consumer can view it.
                if not self.corpus_global_names.contains(name):
                    self.warnings.push(self.context ++ ": writes `" ++ name ++ "` (" ++ sema.fn_global_write_chain(sig, sym, &self.call_index) ++ "), a global outside this bundle that is no bundle export: the write contract covers only exported globals (§21.1 rule 1)")
                continue
            for ei in 0..entries.len() as i32:
                if actual.contains(entries[ei]):
                    continue
                actual.push(with_str_clone_ref(entries[ei]))
                if not declared.contains(entries[ei]):
                    let fix = if has_clause: "add '" ++ name ++ "' to " ++ fn_name ++ "'s `writes` clause" else: "add 'writes " ++ name ++ "' to " ++ fn_name ++ "'s declaration"
                    let what = if self.origin_global_names.contains(name) and not self.global_is_pub_export(name): "global `" ++ name ++ "`, an origin of an exported function's returned view," else: "exported global `" ++ name ++ "`"
                    self.refuse("writes " ++ what ++ " (" ++ sema.fn_global_write_chain(sig, sym, &self.call_index) ++ ") but its declaration does not say so: a bundle function's global writes are a declared, checked contract, and no clause declares none (§21.1 rules 1 and 6, D39, D79); " ++ fix)
        for di in 0..declared.len() as i32:
            if not actual.contains(declared[di]):
                self.warnings.push(self.context ++ ": declares a write of `" ++ declared[di] ++ "` its body never makes (a conservative contract: every caller treats it as written)")


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
                self.refuse("is generic; a bundle boundary is Level 0 (docs/spec/abi/abi_roadmap.md)")
                continue
            if ast.find_impl_target_type_node(impl_node) != 0:
                self.refuse("targets a generic instantiation; a bundle boundary is Level 0 (docs/spec/abi/abi_roadmap.md)")
                continue
            // methods: every fn decl Sema associated with this impl, by name
            var method_names: List[str] = List.new()
            var method_decls: List[i32] = List.new()
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
            let export_name = type_name ++ "." ++ (if trait_sym != 0: trait_name.clone() else: "")
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
            self.refuse("is generic; a bundle boundary is Level 0 (docs/spec/abi/abi_roadmap.md)")
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
        let pack_cap = type_decl_pack_cap(packed)
        if type_decl_is_repr_c(packed) != 0 and type_decl_is_packed(packed) == 0 and pack_cap == 0:
            attrs = attrs ++ "@[repr(C)]\n"
            flags_row = flags_row ++ "repr-c,"
        if type_decl_is_packed(packed) != 0:
            attrs = attrs ++ "@[packed]\n"
            flags_row = flags_row ++ "packed,"
        if pack_cap != 0:
            attrs = attrs ++ f"@[repr(packed({pack_cap}))]\n"
            flags_row = flags_row ++ f"packed({pack_cap}),"
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
                // D100 (§18.3): an exported field stays exported to the
                // bundle's consumers.
                if sema.pub_field_keys.contains(sema_field_key(node, sema.type_extra[(te_start + fi * 3)])):
                    fields = fields ++ "pub "
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
                    // An unsigned repr's value is its bits read unsigned: a
                    // u64 value above i64::MAX spells as itself (#1452).
                    let disc = sema.type_reflection_variant_discriminant(resolved as i32, vi)
                    let repr_ty: i32 = sema.disc_repr_types.get(resolved as i32).unwrap()
                    let disc_spelling = if disc < 0 and sema.is_unsigned_int_type(repr_ty): f"{disc as u64}" else: f"{disc}"
                    line = line ++ " = " ++ disc_spelling
                    disc_row = disc_spelling
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
            let decl = ast.get_decl(di) as i32
            let kind = ast.kind(decl)
            if kind == NodeKind.NK_TYPE_DECL and not self.type_decl_paths.contains(ast.get_data0(decl)):
                self.type_decl_paths.insert(ast.get_data0(decl), with_str_clone_ref(canonical))
            if bundle_corpus_contains(self.corpus, canonical):
                self.decl_modules.push(with_str_clone_ref(canonical))
                self.add_module(canonical, path)
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
        // The storage first: a function's write contract is checked against
        // the exported globals (check_declared_global_writes), so every
        // global export is known before the first function prints.
        self.call_index = sema.global_call_index()
        // §21.1 rule 6 (#1903): the globals a corpus function's `from`
        // clause names are interface material before any storage prints.
        for di in 0..dc:
            let decl = ast.get_decl(di) as i32
            if self.decl_modules[di].len() == 0 or ast.kind(decl) != NodeKind.NK_FN_DECL:
                continue
            let fn_flags = ast.get_data2(decl)
            if fn_flags % 2 == 0 and sema.impl_node_for_method_decl(decl) == 0:
                continue
            let origin_entries = sema.declared_view_origin_entries(decl)
            for oi in 0..origin_entries.len() as i32:
                if origin_entries[oi] > 0:
                    self.origin_global_names.insert(with_str_clone_ref(sema.pool_resolve(origin_entries[oi])), 1)
        for di in 0..dc:
            let mod_path = with_str_clone_ref(self.decl_modules[di])
            let decl = ast.get_decl(di) as i32
            if mod_path.len() > 0 and ast.kind(decl) == NodeKind.NK_LET_DECL:
                self.corpus_global_names.insert(with_str_clone_ref(sema.pool_resolve(ast.get_data0(decl))), 1)
                self.current_module = with_str_clone_ref(mod_path)
                self.emit_let(sema, di, decl)
        for di in 0..dc:
            let mod_path = with_str_clone_ref(self.decl_modules[di])
            if mod_path.len() == 0:
                continue
            self.current_module = with_str_clone_ref(mod_path)
            let decl = ast.get_decl(di) as i32
            let kind = ast.kind(decl)
            if kind == NodeKind.NK_USE_DECL:
                if ast.get_data2(decl) > 0:
                    self.context = mod_path ++ ": use"
                    self.refuse("is a selector import (`use a.b.{x}`); no interface spelling (Level 0)")
                continue
            if kind == NodeKind.NK_LET_DECL:
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
            self.current_module = with_str_clone_ref(self.decl_modules[di])
            self.emit_type(sema, di, ast.get_decl(di) as i32)
        self.current_module = ""

// Build the exported-declaration model of the corpus modules in `sema`.
pub fn bundle_interface_build(sema: &Sema, corpus: &str, unlowered_globals: &List[str]) -> BundleInterfaceModel:
    var em = bx_new_emitter(corpus, unlowered_globals)
    em.walk(sema)
    let ordered = bx_sorted_strings(&em.modules)
    var sources: List[str] = List.new()
    for oi in 0..ordered.len() as i32:
        for mi in 0..em.modules.len() as i32:
            if em.modules[mi] == ordered[oi]:
                sources.push(with_str_clone_ref(em.module_sources[mi]))
    let needed_imports = em.needed_imports()
    BundleInterfaceModel {
        ok: em.errors.len() == 0,
        corpus: with_str_clone_ref(corpus),
        modules: ordered,
        module_sources: sources,
        exports: move em.exports,
        errors: move em.errors,
        warnings: move em.warnings,
        omitted: move em.omitted,
        needed_imports,
    }

// The export indices of one module in canonical order: kind, then name.
fn bx_module_export_order(model: &BundleInterfaceModel, mod_path: &str) -> List[i32]:
    var order: List[i32] = List.new()
    for kind in 0..7:
        var names: List[str] = List.new()
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
    var errors: List[str] = List.new()
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
        // The section imports its corpus siblings, and a module outside the
        // corpus only when a declaration names one of its types (D39: a
        // body's `use` is implementation — pcre2_maketables' std.libc would
        // otherwise reach every program through the prelude's std.regex).
        for ei in 0..edge_count:
            let import_path = sema.module_import_paths[(edge_start + ei)]
            if import_path == "std.prelude" or import_path == "std.prelude_core" or import_path == "std.prelude_alloc":
                continue
            let target_index = sema.module_import_targets[(edge_start + ei) as i64]
            let target = codegen_canonical_module_path(sema.module_paths[target_index])
            if not bundle_corpus_contains(model.corpus, target) and not model.needed_imports.contains(mod_path ++ "\t" ++ target):
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
