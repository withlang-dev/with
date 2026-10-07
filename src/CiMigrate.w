// CiMigrate — C-to-With source migration (PCRE2 and similar codebases).
//
// Split out of CImport.w in D3. Contains the directory-migration
// shared-defs (C3) + width-slice (C2) subsystems.
//
// Shared translation helpers (ci_translate_struct, ci_translate_typedef,
// ci_translate_macros, the C expression parser, the statement translator,
// goto elimination, etc.) remain in CImport.w and are called from here.

use CiIR
use CiPrint
use CImport
use Lexer
use Token
use Parser
use std.string.StringBuilder

extern fn with_write_stdout(s: &str) -> Unit
extern fn with_flush_stdout() -> Unit
extern fn with_fs_list_files(path: &str) -> str
extern fn with_str_clone_ref(s: &str) -> str

// Width-slice mode: when > 0, skip declarations belonging to
// non-target PCRE2 width families during migration.
// Value is the target code-unit width (e.g. 8). Widths != target
// are pruned. Set via migrate_set_width_slice().
var g_migrate_width_slice: i32 = 0

pub fn migrate_set_width_slice(val: i32):
    g_migrate_width_slice = val

// Check whether a C declaration name belongs to a width family
// that should be pruned. Matches the same patterns as the former
// prune_width_family_decls shell function:
//   - PCRE2_UCHAR16, PCRE2_UCHAR32, PCRE2_SPTR16, PCRE2_SPTR32
//   - Any identifier ending in _16 or _32
pub fn ci_migrate_is_width_family_name(name: &str) -> bool:
    if g_migrate_width_slice == 0:
        return false
    let len = name.len() as i32
    if len < 3:
        return false
    // Check explicit non-underscore-prefixed width types
    if name == "PCRE2_UCHAR16" or name == "PCRE2_UCHAR32":
        return true
    if name == "PCRE2_SPTR16" or name == "PCRE2_SPTR32":
        return true
    // Check identifiers ending in _16 or _32
    if len >= 3 and name[(len - 3)] == 95:
        let d1 = name[(len - 2)]
        let d2 = name[(len - 1)]
        // _16: d1='1'(49), d2='6'(54)
        if d1 == 49 and d2 == 54:
            return true
        // _32: d1='3'(51), d2='2'(50)
        if d1 == 51 and d2 == 50:
            return true
    false

// C3: Shared-defs mode. When prefix is non-empty, the migrator:
//   1. Skips the preamble in individual modules, emits `use <prefix>` instead
//   2. Redirects duplicated top-level declarations to a shared buffer
//   3. After all files, emits a defs.w containing preamble + shared decls
var g_migrate_shared_defs_prefix: str = ""
var g_migrate_shared_decl_buf: Vec[str] = Vec.new()
var g_migrate_shared_decl_keys: str = ""
var g_migrate_shared_decl_records: Vec[str] = Vec.new()
var g_migrate_directory_one_basename: str = ""
var g_migrate_shared_fragment_path: str = ""
var g_migrate_include_paths: Vec[str] = Vec.new()
var g_migrate_forced_includes: Vec[str] = Vec.new()
var g_migrate_directory_input_dir: str = ""

type CiMigratePendingSharedExternVar {
    kind: str = "",
    name: str = "",
    rendered: str = "",
}

var g_migrate_shared_pending_extern_vars: Vec[CiMigratePendingSharedExternVar] = Vec.new()
var g_migrate_shared_usage_idents: str = ""
var g_migrate_libc_symbols_used: str = ""
// D29 (#750): discriminates migrate translation from in-place c_import. The
// std.libc record dedup is only sound for migrate output, whose preamble
// imports std.libc; a c_import expansion has no importer, so it keeps
// emitting the record itself.
var g_ci_translate_migrate_mode: i32 = 0

pub fn ci_translate_in_migrate_mode -> bool: g_ci_translate_migrate_mode != 0
var g_migrate_unsafe_extern_fn_names: str = ""

fn ci_migrate_text_is_blank(text: &str) -> bool:
    var i: i64 = 0
    while i < text.len():
        let ch = text[i]
        if ch != 32 and ch != 9 and ch != 10 and ch != 13:
            return false
        i = i + 1
    true

pub fn migrate_set_shared_defs(prefix: &str):
    g_migrate_shared_defs_prefix = with_str_clone_ref(prefix)

pub fn migrate_set_directory_one_basename(basename: &str):
    g_migrate_directory_one_basename = with_str_clone_ref(basename)

pub fn migrate_set_shared_fragment_path(path: &str):
    g_migrate_shared_fragment_path = with_str_clone_ref(path)

pub fn migrate_add_include_path(path: &str) -> Unit:
    g_migrate_include_paths.push(ci_migrate_fs_path(path))

pub fn migrate_add_forced_include(path: &str) -> Unit:
    g_migrate_forced_includes.push(ci_migrate_fs_path(path))

pub fn migrate_reset_options():
    g_migrate_width_slice = 0
    g_migrate_shared_defs_prefix = ""
    ci_migrate_shared_defs_reset()
    g_migrate_directory_one_basename = ""
    g_migrate_shared_fragment_path = ""
    g_migrate_include_paths = Vec.new()
    g_migrate_forced_includes = Vec.new()
    g_migrate_directory_input_dir = ""
    g_migrate_defines = ""
    g_migrate_file_error = ""
    g_migrate_no_c_export = 0
    g_migrate_export_function_defs = 0
    g_migrate_block_style = 0
    g_migrate_convert_goto_to_structured = 0
    g_migrate_prelude_free = 0
    g_migrate_fn_translated = 0
    g_migrate_fn_translated_total = 0

pub fn ci_migrate_shared_defs_active() -> bool:
    g_migrate_shared_defs_prefix.len() > 0

// True when the output compiles without the prelude: a .wo bundle corpus
// (build/wo.w builds every corpus `--no-prelude`), or `with migrate
// --no-prelude`. The preamble then carries the prelude-only vocabulary the
// translation reaches for (c_void, unreachable) — see ci_migrate_preamble_text.
pub fn ci_migrate_output_is_prelude_free() -> bool:
    g_migrate_prelude_free != 0

// Sema classifies extern declarations in every lib/std module as compiler
// implementation bindings (sema_extern_is_compiler_implementation). Match
// that declaration policy for every corpus, without a library-name exception.
pub fn ci_migrate_shared_defs_targets_std_zone() -> bool:
    ci_starts_with(g_migrate_shared_defs_prefix, "std.")

fn ci_migrate_shared_defs_reset:
    g_migrate_shared_decl_buf = Vec.new()
    g_migrate_shared_decl_keys = ""
    g_migrate_shared_decl_records = Vec.new()
    g_migrate_shared_pending_extern_vars = Vec.new()
    g_migrate_shared_usage_idents = ""

fn ci_migrate_shared_decl_key(kind: &str, name: &str) -> str:
    "|" ++ kind ++ ":" ++ name ++ "|"

fn ci_migrate_type_render_has_concrete_body(name: &str, rendered: &str) -> bool:
    let safe_name = ci_escape_reserved(name)
    ci_str_contains(rendered, "type " ++ safe_name ++ " {") or ci_str_contains(rendered, "type " ++ safe_name ++ " = union {")

// Single dedup entry point for every declaration kind that the migrator
// emits into a shared buffer. `kind` is a short disambiguating prefix
// ("let", "type", "fn", "extern_fn", "extern_var", "extern_let");
// `name` is the declaration's identifier; `rendered` is the exact With
// source line(s) to emit on first sighting. Returns true if the
// declaration was redirected to the shared buffer (caller must skip
// per-file emit). Returns false when shared-defs mode is off OR when
// the declaration was already seen (caller's per-file emit is a no-op).
fn ci_migrate_shared_decl_upgrade_opaque_type(name: &str, rendered: &str):
    let opaque_marker = "type " ++ ci_escape_reserved(name) ++ " = opaque"
    var i = 0
    while i < g_migrate_shared_decl_buf.len() as i32:
        if ci_str_contains(g_migrate_shared_decl_buf[i], opaque_marker):
            let idx = i as i64
            with g_migrate_shared_decl_buf.slot(idx) as mut entry:
                entry.set(rendered ++ "\n")
            break
        i = i + 1
    var j = 0
    while j < g_migrate_shared_decl_records.len() as i32:
        let rec = g_migrate_shared_decl_records[j]
        if ci_str_contains(rec, "@@DECL|type|" ++ name ++ "\n") and ci_str_contains(rec, opaque_marker):
            let idx = j as i64
            with g_migrate_shared_decl_records.slot(idx) as mut entry:
                entry.set(f"@@DECL|type|{name}\n{rendered}\n@@END\n")
            break
        j = j + 1

pub fn ci_migrate_shared_decl_add(kind: &str, name: &str, rendered: &str) -> bool:
    if not ci_migrate_shared_defs_active():
        return false
    let key = ci_migrate_shared_decl_key(kind, name)
    if ci_find_str(g_migrate_shared_decl_keys, key) >= 0:
        if kind == "type" and ci_migrate_type_render_has_concrete_body(name, rendered):
            ci_migrate_shared_decl_upgrade_opaque_type(name, rendered)
        return true
    g_migrate_shared_decl_keys = g_migrate_shared_decl_keys ++ key
    g_migrate_shared_decl_buf.push(rendered ++ "\n")
    g_migrate_shared_decl_records.push(f"@@DECL|{kind}|{name}\n{rendered}\n@@END\n")
    true

fn ci_migrate_shared_ownerless_extern_add(kind: &str, name: &str, rendered: &str) -> bool:
    if not ci_migrate_shared_defs_active():
        return false
    let key = ci_migrate_shared_decl_key(kind, name)
    if ci_find_str(g_migrate_shared_decl_keys, key) >= 0:
        return true
    g_migrate_shared_decl_keys = g_migrate_shared_decl_keys ++ key
    g_migrate_shared_pending_extern_vars.push(CiMigratePendingSharedExternVar { kind: ci_ir_owned_text(kind), name: ci_ir_owned_text(name), rendered: ci_ir_owned_text(rendered) })
    true

fn ci_migrate_text_mentions_ident(text: &str, name: &str) -> bool:
    if name.len() == 0 or name.len() > text.len():
        return false
    let tlen = text.len()
    let nlen = name.len()
    var start: i64 = 0
    while start <= tlen - nlen:
        let rel = ci_find_str(text.slice(start, tlen), name)
        if rel < 0:
            return false
        let pos = start + rel as i64
        let before_ok = pos == 0 or not ci_is_ident_char(text[pos - 1])
        let after_pos = pos + nlen
        let after_ok = after_pos >= tlen or not ci_is_ident_char(text[after_pos])
        if before_ok and after_ok:
            return true
        start = pos + 1
    false

fn ci_migrate_shared_note_ident(name: &str):
    if name.len() == 0:
        return
    let key = "|" ++ name ++ "|"
    if ci_find_str(g_migrate_shared_usage_idents, key) < 0:
        g_migrate_shared_usage_idents = g_migrate_shared_usage_idents ++ key

fn ci_migrate_shared_note_output_uses(output: &str):
    if not ci_migrate_shared_defs_active():
        return
    var i = 0
    let n = output.len() as i32
    while i < n:
        let ch = output[i]
        if ci_is_ident_char(ch):
            let start = i
            i = i + 1
            while i < n and ci_is_ident_char(output[i]):
                i = i + 1
            ci_migrate_shared_note_ident(output.slice(start as i64, i as i64))
            continue
        i = i + 1

fn ci_migrate_libc_reset:
    g_migrate_libc_symbols_used = ""
    return

pub fn ci_migrate_note_libc_symbol(name: &str):
    if name.len() == 0:
        return
    let key = "|" ++ name ++ "|"
    if ci_find_str(g_migrate_libc_symbols_used, key) < 0:
        g_migrate_libc_symbols_used = g_migrate_libc_symbols_used ++ key
    return

fn ci_migrate_needs_libc -> bool:
    g_migrate_libc_symbols_used.len() > 0

fn ci_migrate_reset_unsafe_extern_fns():
    g_migrate_unsafe_extern_fn_names = ""
    return

fn ci_migrate_note_unsafe_extern_fn(name: &str):
    if name.len() == 0:
        return
    let key = "|" ++ name ++ "|"
    if ci_find_str(g_migrate_unsafe_extern_fn_names, key) < 0:
        g_migrate_unsafe_extern_fn_names = g_migrate_unsafe_extern_fn_names ++ key
    return

pub fn ci_migrate_extern_fn_call_requires_unsafe(name: &str) -> bool:
    if name.len() == 0:
        return false
    ci_find_str(g_migrate_unsafe_extern_fn_names, "|" ++ name ++ "|") >= 0

fn ci_migrate_type_is_raw_pointer(ty: &str) -> bool:
    let t = ci_trim(ci_pointer_type_explicit_mut(ty))
    ci_starts_with(t, "*")

// A migrated definition is `unsafe fn` when a raw pointer crosses it or
// when it is defined with `...` (D75, §16.2b.5: unsafe to call).
fn ci_migrate_fn_is_unsafe_to_call(session: i64, idx: i32) -> bool:
    ci_migrate_fn_has_raw_pointer_param(session, idx) or with_cimport_fn_is_variadic(session, idx) != 0

fn ci_migrate_fn_has_raw_pointer_param(session: i64, idx: i32) -> bool:
    let param_count = with_cimport_fn_param_count(session, idx)
    for pi in 0..param_count:
        if ci_migrate_type_is_raw_pointer(with_cimport_fn_param_type_translated(session, idx, pi)):
            return true
    false

fn ci_migrate_insert_libc_use(output: &str) -> str:
    if not ci_migrate_needs_libc():
        return with_str_clone_ref(output)
    if ci_find_str(output, "\nuse std.libc\n") >= 0:
        return with_str_clone_ref(output)
    let header_end = ci_find_str(output, "\n\n")
    if header_end >= 0:
        output.slice(0, header_end as i64) ++ "\nuse std.libc" ++ output.slice(header_end as i64, output.len())
    else:
        "use std.libc\n\n" ++ output

// D102 (§16.6): a migrated module names `Option`, `Some` and `None` for its
// nullable function pointers; a corpus module has no prelude, so it imports
// them as std's own modules do.
fn ci_migrate_insert_option_use(output: &str) -> str:
    if ci_find_str(output, "Option[") < 0 and ci_find_str(output, "Some(") < 0:
        return with_str_clone_ref(output)
    if ci_find_str(output, "\nuse std.option\n") >= 0 or ci_starts_with(output, "use std.option\n"):
        return with_str_clone_ref(output)
    let header_end = ci_find_str(output, "\n\n")
    if header_end >= 0:
        output.slice(0, header_end as i64) ++ "\nuse std.option" ++ output.slice(header_end as i64, output.len())
    else:
        "use std.option\n\n" ++ output

fn ci_migrate_shared_module_prefix() -> str:
    if g_migrate_shared_defs_prefix.ends_with(".defs"):
        return g_migrate_shared_defs_prefix.slice(0, g_migrate_shared_defs_prefix.len() - 5)
    g_migrate_shared_defs_prefix.clone()

// Physical output paths and imports must use the same identifier spelling.
// A C filename may contain punctuation that is not valid in a With module.
fn ci_migrate_module_relative_path(input_dir: &str, path: &str) -> str:
    var rel = path.clone()
    if input_dir.len() > 0 and ci_starts_with(path, input_dir):
        rel = path.slice(input_dir.len(), path.len())
    while rel.len() > 0 and rel[0] == 47:
        rel = rel.slice(1, rel.len())
    if rel.ends_with(".c"):
        rel = rel.slice(0, rel.len() - 2)
    var out = ""
    let segments = rel.split("/")
    for segment in segments:
        var identifier = ""
        for i in 0..segment.len():
            let ch = segment[i] as i32
            if i == 0 and ch >= 48 and ch <= 57: identifier = identifier ++ "_"
            identifier = identifier ++ (if ci_is_ident_char(ch): segment.slice(i, i + 1) else: "_")
        if out.len() > 0: out = out ++ "/"
        out = out ++ ci_escape_reserved(identifier)
    out

fn ci_migrate_source_module_suffix(path: &str):
    ci_migrate_module_relative_path(g_migrate_directory_input_dir, path).replace("/", ".")

fn ci_migrate_source_module_path(path: &str) -> str:
    let prefix = ci_migrate_shared_module_prefix()
    let suffix = ci_migrate_source_module_suffix(path)
    if prefix.len() == 0:
        return suffix
    if suffix.len() == 0:
        return prefix
    prefix ++ "." ++ suffix

fn ci_migrate_pipe_i32_contains(items: &str, want: i32) -> bool:
    let needle = "|" ++ i64_to_string(want as i64) ++ "|"
    ci_find_str(items, needle) >= 0

fn ci_migrate_add_import_once(imports: &str, module_path: &str) -> str:
    if module_path.len() == 0:
        return with_str_clone_ref(imports)
    let line = "use " ++ module_path ++ "\n"
    if ci_find_str(imports, line) >= 0:
        return with_str_clone_ref(imports)
    imports ++ line

fn ci_migrate_project_imports_for_file(project_active: bool, project: &CiProject, input_path: &str) -> str:
    if not project_active or not ci_migrate_shared_defs_active() or g_migrate_directory_input_dir.len() == 0:
        return ""
    let current_module = project.ensure_module(input_path)
    var imports = ""
    for si in 0..project.symbols.len() as i32:
        let symbol = project.symbols[si]
        if symbol.owner_module < 0 or symbol.owner_module == current_module:
            continue
        if not ci_migrate_pipe_i32_contains(symbol.consumers, current_module):
            continue
        if symbol.owner_module >= project.module_paths.len() as i32:
            continue
        imports = ci_migrate_add_import_once(imports, ci_migrate_source_module_path(project.module_paths[symbol.owner_module]))
    imports

// Replace all occurrences of needle with replacement, assuming few matches.
// Unlike ci_str_replace (O(n²) char-by-char concatenation), this is O(n * k)
// where k = number of matches, suitable for large outputs with sparse matches.
fn ci_replace_sparse(text: &str, needle: &str, replacement: &str) -> str:
    if needle.len() == 0 or needle.len() > text.len():
        return with_str_clone_ref(text)
    var result = ""
    var start: i64 = 0
    let tlen = text.len()
    let nlen = needle.len()
    while start < tlen:
        let tail = text.slice(start, tlen)
        let rel = ci_find_str(tail, needle)
        if rel < 0:
            result = result ++ tail
            return result
        let abs_idx = start + rel as i64
        result = result ++ text.slice(start, abs_idx) ++ replacement
        start = abs_idx + nlen
    result

fn ci_comment_prefix_lines(text: &str) -> str:
    var result = ""
    var start: i64 = 0
    let tlen = text.len()
    while start < tlen:
        var end = start
        while end < tlen and text[end] != 10:
            end = end + 1
        let line = text.slice(start, end)
        if line.len() > 0:
            result = result ++ "// " ++ line ++ "\n"
        else:
            result = result ++ "//\n"
        if end < tlen:
            end = end + 1
        start = end
    result

fn ci_migrate_normalize_output(text: &str) -> str:
    if text.len() == 0:
        return ""
    var end = text.len()
    while end > 0 and text[end - 1] == 10:
        end = end - 1
    ci_str_replace(text.slice(0, end), "-> void", "-> Unit") ++ "\n"

// A migrated module's types are its public API: C has no type visibility,
// and every `pub fn` the migrator emits names them (§18.1 rejects a private
// type behind a pub signature — the preamble's `c_int`, a header's struct).
// The shared defs module publishes everything else it holds too.
fn ci_migrate_publicize_line(line: &str, types_only: bool) -> str:
    if line.starts_with("pub "):
        return with_str_clone_ref(line)
    if line.starts_with("type "):
        return "pub " ++ line
    if not types_only and (line.starts_with("let ") or line.starts_with("var ") or line.starts_with("fn ") or line.starts_with("unsafe fn ") or line.starts_with("extern fn ") or line.starts_with("extern let ") or line.starts_with("extern var ")):
        return "pub " ++ line
    with_str_clone_ref(line)

fn ci_migrate_publicize_lines(text: &str, types_only: bool) -> str:
    var out = ""
    var start: i64 = 0
    let n = text.len()
    while start < n:
        var end = start
        while end < n and text[end] != 10:
            end = end + 1
        out = out ++ ci_migrate_publicize_line(text.slice(start, end), types_only)
        if end < n:
            out = out ++ "\n"
            end = end + 1
        start = end
    out

fn ci_migrate_publicize_shared_defs(text: &str) -> str: ci_migrate_publicize_lines(text, false)

fn ci_migrate_publicize_types(text: &str) -> str: ci_migrate_publicize_lines(text, true)

// The migrator's own helpers share a module with the C program's globals,
// and a global named `a`, `b`, `c` or `out` made every helper parameter of
// that name a refused shadow (#1933). Their parameters and locals take the
// reserved `__with_` prefix, which C code does not spell.
const CI_MIGRATE_HELPER_LOCALS: [15]str = ["a", "b", "c", "out", "result", "a_hi", "b_hi", "a_lo", "b_lo", "cross", "low", "neg", "ua", "ub", "limit"]

fn ci_migrate_hygienic(text: &str) -> str:
    var out = StringBuilder.new()
    var i = 0
    while i < text.len() as i32:
        let ch = text[i]
        if ci_is_ident_start(ch):
            var end = i + 1
            while end < text.len() as i32 and ci_is_ident_char(text[end]): end += 1
            let word = text.slice(i as i64, end as i64)
            for local in CI_MIGRATE_HELPER_LOCALS:
                if word == local:
                    out.push_str("__with_")
                    break
            out.push_str(word)
            i = end
        else:
            out.push_str(text.slice(i as i64, (i + 1) as i64))
            i += 1
    out.to_str()

fn ci_migrate_render_preamble_fn(signature: &str, colon_expr: &str, brace_expr: &str) -> str:
    if migrate_prefer_brace():
        return ci_migrate_hygienic(signature ++ " {\n    " ++ brace_expr ++ "\n}\n")
    ci_migrate_hygienic(signature ++ ": " ++ colon_expr ++ "\n")

// The helper a `__builtin_<op>_overflow` call names. The migrator's preamble
// defines `__with_builtin_<op>_overflow_<ty>` for every width; a c_import
// translation defines the same name beside the bodies that call it (#1877).
// The `.wo` bundles' shared defs (lib/std/re/defs.w) reach every
// compilation over the prelude edge with their own definitions of these
// names; an import's definition is its importer's, displaced to the
// importer's identity when another owner holds the name
// (Frontend.displace_colliding_c_import_fns, #1882), so neither captures
// the other's calls.
pub fn ci_overflow_helper_name(op: &str, ty: &str): "__with_builtin_" ++ op ++ "_overflow_" ++ ty

pub fn ci_u128_mul_helper_name(): "u128_mul_would_overflow"

fn ci_migrate_render_overflow_helper(name: &str, op: &str, ty: &str, is_signed: bool):
    let token = if op == "add": "+%" else if op == "sub": "-%" else: "*%"
    let overflow = if op == "add":
        if is_signed: "((result ^ a) & (result ^ b)) < 0" else: "result < a"
    else if op == "sub":
        if is_signed: "((a ^ b) & (result ^ a)) < 0" else: "a < b"
    else if is_signed:
        "if a == 0 or b == 0: false else if a == -1: result == b else if b == -1: result == a else: result / b != a"
    else:
        "if b == 0: false else: result / b != a"
    let signature = "unsafe fn " ++ name ++ "(a: " ++ ty ++ ", b: " ++ ty ++ ", out: *mut " ++ ty ++ ") -> bool"
    let body = "    let result = a " ++ token ++ " b\n    unsafe { (*out = result) }\n    " ++ overflow ++ "\n"
    ci_migrate_hygienic(ci_migrate_render_fn_with_body(signature, body))

fn ci_migrate_render_fn_with_body(signature: &str, body: &str) -> str:
    if migrate_prefer_brace():
        return signature ++ " {\n" ++ body ++ "}\n"
    signature ++ ":\n" ++ body

// The 128-bit multiply checks are division-free (#941): `/` on i128/u128
// lowers to the __divti3/__udivti3 compiler-rt libcalls, which a freestanding
// runtime object's COFF link has no builtins library to resolve. Limb
// decomposition keeps the check to multiplies and shifts, inline on every
// target at every -O level. The shared helper is emitted once, before the
// i128 multiply that first needs it.
pub fn ci_migrate_render_u128_mul_would_overflow(name: &str) -> str:
    let comment = "// The 128-bit overflow checks stay division-free on purpose: `/` on i128/u128\n// lowers to the __divti3/__udivti3 compiler-rt libcalls, and this shim is\n// compiled into freestanding runtime objects whose COFF link has no builtins\n// library to resolve them from. Limb decomposition keeps the check to multiplies\n// and shifts, which lower inline on every target and at every -O level.\n"
    let body = "    let a_hi = (a >> 64) as u64\n    let b_hi = (b >> 64) as u64\n    if a_hi != 0 and b_hi != 0: return true\n    let a_lo = (a as u64) as u128\n    let b_lo = (b as u64) as u128\n    let cross = (a_hi as u128) *% b_lo +% (b_hi as u128) *% a_lo\n    if (cross >> 64) != 0: return true\n    let low = a_lo *% b_lo\n    ((low >> 64) +% cross) >> 64 != 0\n"
    comment ++ ci_migrate_hygienic(ci_migrate_render_fn_with_body("fn " ++ name ++ "(a: u128, b: u128) -> bool", body))

fn ci_migrate_render_mul_overflow_128(name: &str, shared: &str, ty: &str, is_signed: bool) -> str:
    let signature = "unsafe fn " ++ name ++ "(a: " ++ ty ++ ", b: " ++ ty ++ ", out: *mut " ++ ty ++ ") -> bool"
    let body = if is_signed:
        "    unsafe { (*out = a *% b) }\n    if a == 0 or b == 0: return false\n    let neg = (a < 0) != (b < 0)\n    let ua = if a < 0: (0 as u128) -% (a as u128) else: a as u128\n    let ub = if b < 0: (0 as u128) -% (b as u128) else: b as u128\n    if " ++ shared ++ "(ua, ub): return true\n    let limit = if neg: (1 as u128) << 127 else: ((1 as u128) << 127) -% 1\n    ua *% ub > limit\n"
    else:
        "    unsafe { (*out = a *% b) }\n    " ++ shared ++ "(a, b)\n"
    ci_migrate_hygienic(ci_migrate_render_fn_with_body(signature, body))

// One overflow helper definition for a c_import translation that names it
// (#1877): the migrator's preamble defines every width up front; a header
// import defines only the ones its inline bodies call, under the c_import
// spelling (ci_overflow_helper_name). The 128-bit multiply's shared limb
// check is rendered once by the caller (ci_migrate_render_u128_mul_would_overflow).
pub fn ci_migrate_render_overflow_helper_for(op: &str, ty: &str) -> str:
    let is_signed = ty[0] == 'i'
    let name = ci_overflow_helper_name(op, ty)
    if op == "mul" and (ty == "i128" or ty == "u128"):
        return ci_migrate_render_mul_overflow_128(name, ci_u128_mul_helper_name(), ty, is_signed)
    ci_migrate_render_overflow_helper(name, op, ty, is_signed)

fn ci_migrate_render_overflow_helpers(ty: &str, is_signed: bool):
    let wide = ty == "i128" or ty == "u128"
    let shared = if ty == "i128": ci_migrate_render_u128_mul_would_overflow("u128_mul_would_overflow") else: ""
    let mul = if wide: ci_migrate_render_mul_overflow_128("__with_builtin_mul_overflow_" ++ ty, "u128_mul_would_overflow", ty, is_signed) else: ci_migrate_render_overflow_helper("__with_builtin_mul_overflow_" ++ ty, "mul", ty, is_signed)
    ci_migrate_render_overflow_helper("__with_builtin_add_overflow_" ++ ty, "add", ty, is_signed) ++
    ci_migrate_render_overflow_helper("__with_builtin_sub_overflow_" ++ ty, "sub", ty, is_signed) ++
    shared ++ mul

// Write the shared defs module (defs.w) to output_dir.
// Contains: preamble + hardcoded extras + shared declarations.
fn ci_migrate_write_shared_defs(output_dir: &str):
    var defs = StringBuilder.new()
    defs.push_str("// ")
    defs.push_str(g_migrate_shared_defs_prefix)
    defs.push_str(" — shared definitions for migrated PCRE2\n\n")
    defs.push_str(ci_migrate_preamble_text())
    // (STRING_MARK/DEFINE/VERSION/WEIRD_STARTWORD/WEIRD_ENDWORD were once
    // hardcoded here as pointer forms. The general macro path now emits them as
    // c_char arrays, so hardcoding a second pointer declaration shadowed it.)
    // Shared declarations collected during migration.
    if g_migrate_shared_decl_buf.len() > 0:
        defs.push_str("\n")
        for di in 0..g_migrate_shared_decl_buf.len() as i32:
            defs.push_str(g_migrate_shared_decl_buf[di])
    var pending_i = 0
    while pending_i < g_migrate_shared_pending_extern_vars.len() as i32:
        let pending = g_migrate_shared_pending_extern_vars[pending_i]
        if ci_find_str(g_migrate_shared_usage_idents, "|" ++ pending.name ++ "|") >= 0:
            defs.push_str(pending.rendered)
            defs.push_str("\n")
        pending_i = pending_i + 1
    let defs_path = output_dir ++ "/defs.w"
    let rc = with_fs_write_file(defs_path, ci_migrate_insert_option_use(ci_migrate_publicize_shared_defs(ci_migrate_normalize_output(defs.to_str()))))
    if rc != 0:
        eprint("migrate: failed to write shared defs: " ++ defs_path)
    else:
        ci_migrate_writes_note_path(defs_path)
        eprint("migrate: wrote shared defs: " ++ defs_path)

fn ci_migrate_write_shared_fragment(path: &str):
    let fragment = ci_migrate_shared_fragment_text()
    if with_fs_write_file(path, fragment) != 0:
        eprint(f"migrate: failed to write shared fragment: {path}")

fn ci_migrate_shared_fragment_text() -> str:
    var fragment = StringBuilder.new()
    for di in 0..g_migrate_shared_decl_records.len() as i32:
        fragment.push_str(g_migrate_shared_decl_records[di])
    var pending_i = 0
    while pending_i < g_migrate_shared_pending_extern_vars.len() as i32:
        let pending = g_migrate_shared_pending_extern_vars[pending_i]
        fragment.push_str(f"@@PENDING|{pending.kind}|{pending.name}\n{pending.rendered}\n@@END\n")
        pending_i = pending_i + 1
    fragment.push_str(f"@@USES\n{g_migrate_shared_usage_idents}\n@@END\n")
    fragment.to_str()

fn ci_migrate_merge_usage_keys(keys: &str):
    var i = 0
    let n = keys.len() as i32
    while i < n:
        while i < n and keys[i] != 124:
            i = i + 1
        if i >= n:
            return
        let start = i + 1
        i = start
        while i < n and keys[i] != 124:
            i = i + 1
        if i > start:
            ci_migrate_shared_note_ident(keys.slice(start as i64, i as i64))
        i = i + 1

fn ci_migrate_merge_shared_fragment_text(text: &str):
    var pos = 0
    let n = text.len() as i32
    while pos < n:
        var line_end = pos
        while line_end < n and text[line_end] != 10:
            line_end = line_end + 1
        let line = text.slice(pos as i64, line_end as i64)
        let body_start = line_end + 1
        let rest = text.slice(body_start as i64, text.len())
        let rel_end = ci_find_str(rest, "\n@@END\n")
        if rel_end < 0:
            return
        let body_end = body_start + rel_end
        let body = text.slice(body_start as i64, body_end as i64)
        if ci_starts_with(line, "@@DECL|"):
            let marker = line.slice(7, line.len())
            let sep = ci_find_str(marker, "|")
            if sep > 0:
                let kind = marker.slice(0, sep as i64)
                let name = marker.slice((sep + 1) as i64, marker.len())
                let _ = ci_migrate_shared_decl_add(kind, name, body)
        else if ci_starts_with(line, "@@PENDING|"):
            let marker = line.slice(10, line.len())
            let sep = ci_find_str(marker, "|")
            if sep > 0:
                let kind = marker.slice(0, sep as i64)
                let name = marker.slice((sep + 1) as i64, marker.len())
                let _ = ci_migrate_shared_ownerless_extern_add(kind, name, body)
        else if line == "@@USES":
            ci_migrate_merge_usage_keys(body)
        pos = body_end + 7

fn ci_migrate_merge_shared_fragment_texts(output_dir: &str, fragments: &Vec[str]):
    ci_migrate_shared_defs_reset()
    var i = 0
    while i < fragments.len() as i32:
        ci_migrate_merge_shared_fragment_text(fragments[i])
        i = i + 1
    ci_migrate_write_shared_defs(output_dir)

// The pointer spellings of the runtime alloc/mem family, as the rt defines
// them (rt/rt_core.w: with_alloc/realloc/free/memcpy/memmove/memset/memcmp).
// ONE source for the preamble decls, the structural IR lowering, the text
// mapper, and CiPrint's struct init/copy — a second derivation anywhere is
// #880's bug (and #761's corruption class: one symbol, two contracts).
pub fn ci_rt_ptr_mut() -> str: "*mut u8"
pub fn ci_rt_ptr_const() -> str: "*const u8"

// Generate the self-contained preamble that every migrated file needs.
// In shared-defs mode this goes into defs.w; otherwise into each file.
fn ci_migrate_preamble_text() -> str:
    var p = ""
    // Inline ctype helpers (pure functions, no dependencies).
    p = p ++ ci_migrate_render_preamble_fn("fn is_alpha(c: i32) -> bool", "(c >= 65 and c <= 90) or (c >= 97 and c <= 122)", "(c >= 65 and c <= 90) or (c >= 97 and c <= 122)")
    p = p ++ ci_migrate_render_preamble_fn("fn is_digit(c: i32) -> bool", "c >= 48 and c <= 57", "c >= 48 and c <= 57")
    p = p ++ ci_migrate_render_preamble_fn("fn is_space(c: i32) -> bool", "c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11", "c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11")
    p = p ++ ci_migrate_render_preamble_fn("fn is_alnum(c: i32) -> bool", "is_alpha(c) or is_digit(c)", "is_alpha(c) or is_digit(c)")
    p = p ++ ci_migrate_render_preamble_fn("fn is_upper(c: i32) -> bool", "c >= 65 and c <= 90", "c >= 65 and c <= 90")
    p = p ++ ci_migrate_render_preamble_fn("fn is_lower(c: i32) -> bool", "c >= 97 and c <= 122", "c >= 97 and c <= 122")
    p = p ++ ci_migrate_render_preamble_fn("fn is_xdigit(c: i32) -> bool", "(c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)", "(c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)")
    p = p ++ ci_migrate_render_preamble_fn("fn is_print(c: i32) -> bool", "c >= 32 and c <= 126", "c >= 32 and c <= 126")
    p = p ++ ci_migrate_render_preamble_fn("fn to_lower(c: i32) -> i32", "if c >= 65 and c <= 90: c + 32 else: c", "if c >= 65 and c <= 90 { c + 32 } else { c }")
    p = p ++ ci_migrate_render_preamble_fn("fn to_upper(c: i32) -> i32", "if c >= 97 and c <= 122: c - 32 else: c", "if c >= 97 and c <= 122 { c - 32 } else { c }")
    // String functions from libc
    p = p ++ "extern fn strlen(s: *const i8) -> i64\n"
    p = p ++ "extern fn strcmp(a: *const i8, b: *const i8) -> i32\n"
    p = p ++ "extern fn strncmp(a: *const i8, b: *const i8, n: i64) -> i32\n"
    p = p ++ "extern fn strchr(s: *const i8, c: i32) -> *mut i8\n"
    p = p ++ "extern fn memchr(s: *const c_void, c: i32, n: i64) -> *mut c_void\n"
    p = p ++ "extern fn isalpha(c: i32) -> i32\n"
    p = p ++ "extern fn isdigit(c: i32) -> i32\n"
    p = p ++ "extern fn isalnum(c: i32) -> i32\n"
    p = p ++ "extern fn isspace(c: i32) -> i32\n"
    p = p ++ "extern fn isupper(c: i32) -> i32\n"
    p = p ++ "extern fn islower(c: i32) -> i32\n"
    p = p ++ "extern fn isxdigit(c: i32) -> i32\n"
    p = p ++ "extern fn isprint(c: i32) -> i32\n"
    p = p ++ "extern fn isgraph(c: i32) -> i32\n"
    p = p ++ "extern fn ispunct(c: i32) -> i32\n"
    p = p ++ "extern fn iscntrl(c: i32) -> i32\n"
    p = p ++ "extern fn tolower(c: i32) -> i32\n"
    p = p ++ "extern fn toupper(c: i32) -> i32\n"
    p = p ++ "extern fn sqrt(x: f64) -> f64\n"
    p = p ++ "extern fn pow(base: f64, exp: f64) -> f64\n"
    p = p ++ "extern fn floor(x: f64) -> f64\n"
    p = p ++ "extern fn ceil(x: f64) -> f64\n"
    p = p ++ "extern fn round(x: f64) -> f64\n"
    p = p ++ "extern fn sin(x: f64) -> f64\n"
    p = p ++ "extern fn cos(x: f64) -> f64\n"
    p = p ++ "extern fn tan(x: f64) -> f64\n"
    p = p ++ "extern fn log(x: f64) -> f64\n"
    p = p ++ "extern fn log10(x: f64) -> f64\n"
    p = p ++ "extern fn exp(x: f64) -> f64\n"
    p = p ++ "extern fn fabs(x: f64) -> f64\n"
    p = p ++ "extern fn fmod(x: f64, y: f64) -> f64\n"
    p = p ++ "extern fn asin(x: f64) -> f64\n"
    p = p ++ "extern fn acos(x: f64) -> f64\n"
    p = p ++ "extern fn atan(x: f64) -> f64\n"
    p = p ++ "extern fn atan2(y: f64, x: f64) -> f64\n"
    // c_void comes from the prelude's builtins; re-declaring it here would
    // shadow the foundation module out of the program (#750).
    //
    // Exception (#880, generalized for every .wo corpus): output that
    // compiles WITHOUT the prelude — a bundled corpus (build/wo.w builds
    // std.re, std.zl, ... `--no-prelude`) — has no builtin c_void, so its
    // preamble must carry the declaration, as the pre-#750 promotion always
    // did (both modes built green with it for months). Keyed on the migrate
    // workspace's prelude mode, never on a corpus name, so ordinary
    // migrations keep #750's protection and a new corpus needs no new rule.
    if ci_migrate_output_is_prelude_free():
        p = p ++ "\ntype c_void = opaque\n"
        // `unreachable()` is also prelude-only; give the output a
        // self-contained Never shim (abort matches the builtin's crash-loudly
        // semantics).
        p = p ++ "extern fn abort() -> Never\n"
        p = p ++ "fn __ci_unreachable() -> Never: abort()\n"
    // #2176: the C model's aliases (`--c-target`), the host's when none is named.
    p = p ++ "\n" ++ ci_c_type_aliases(with_cimport_target_triple())
    // Clang's overflow builtins both store the wrapped result and report the
    // overflow bit. Keep both effects: the structural call lowerer selects
    // the helper from the result-pointer type and rejects mixed types loudly.
    p = p ++ ci_migrate_render_overflow_helpers("i8", true)
    p = p ++ ci_migrate_render_overflow_helpers("u8", false)
    p = p ++ ci_migrate_render_overflow_helpers("i16", true)
    p = p ++ ci_migrate_render_overflow_helpers("u16", false)
    p = p ++ ci_migrate_render_overflow_helpers("i32", true)
    p = p ++ ci_migrate_render_overflow_helpers("u32", false)
    p = p ++ ci_migrate_render_overflow_helpers("i64", true)
    p = p ++ ci_migrate_render_overflow_helpers("u64", false)
    p = p ++ ci_migrate_render_overflow_helpers("i128", true)
    p = p ++ ci_migrate_render_overflow_helpers("u128", false)
    // Builtin and runtime wrappers
    p = p ++ "extern fn with_clz(x: i32) -> i32\n"
    p = p ++ "extern fn with_ctz(x: i32) -> i32\n"
    p = p ++ "extern fn with_popcount(x: i32) -> i32\n"
    p = p ++ "extern fn with_bswap16(x: u16) -> u16\n"
    p = p ++ "extern fn with_bswap32(x: u32) -> u32\n"
    p = p ++ "extern fn with_bswap64(x: u64) -> u64\n"
    // (bswap: unsigned like __builtin_bswapN; rt/rt_core.w defines them so.)
    p = p ++ "extern fn with_clzl(x: i64) -> i32\n"
    p = p ++ "extern fn with_clzll(x: i64) -> i32\n"
    p = p ++ "extern fn with_ctzl(x: i64) -> i32\n"
    p = p ++ "extern fn with_ctzll(x: i64) -> i32\n"
    p = p ++ "extern fn with_abs(x: i32) -> i32\n"
    let pm = ci_rt_ptr_mut()
    let pc = ci_rt_ptr_const()
    p = p ++ "extern fn with_alloc(size: i64) -> " ++ pm ++ "\n"
    p = p ++ "extern fn with_alloc_zeroed(count: i64, size: i64) -> " ++ pm ++ "\n"
    p = p ++ "extern fn with_realloc(ptr: " ++ pm ++ ", old_size: i64, new_size: i64) -> " ++ pm ++ "\n"
    p = p ++ "extern fn with_free(ptr: " ++ pm ++ ")\n"
    p = p ++ "extern fn with_memcpy(dst: " ++ pm ++ ", src: " ++ pc ++ ", n: i64) -> " ++ pm ++ "\n"
    p = p ++ "extern fn with_memmove(dst: " ++ pm ++ ", src: " ++ pc ++ ", n: i64) -> " ++ pm ++ "\n"
    p = p ++ "extern fn with_memset(dst: " ++ pm ++ ", c: i32, n: i64) -> " ++ pm ++ "\n"
    p = p ++ "extern fn with_memcmp(a: " ++ pc ++ ", b: " ++ pc ++ ", n: i64) -> i32\n\n"
    p

// The with_* runtime externs the preamble above declares. A C prototype for
// one of these names is a redeclaration of the same flat-namespace symbol —
// the preamble's spelling is the one every migrator-generated call matches.
fn ci_migrate_preamble_declares_runtime_extern(name: &str) -> bool:
    name == "with_clz" or name == "with_ctz" or name == "with_popcount" or
    name == "with_bswap16" or name == "with_bswap32" or name == "with_bswap64" or
    name == "with_clzl" or name == "with_clzll" or name == "with_ctzl" or
    name == "with_ctzll" or name == "with_abs" or name == "with_alloc" or
    name == "with_alloc_zeroed" or name == "with_realloc" or name == "with_free" or
    name == "with_memcpy" or name == "with_memmove" or name == "with_memset" or
    name == "with_memcmp"

fn ci_migrate_is_runtime_cabi_function(name: &str) -> bool:
    if ci_starts_with(name, "with_"):
        return true
    name == "i32_to_str" or name == "i64_to_string" or name == "str_from_byte"

// The compiler's emitted C ABI uses with_* names plus three legacy conversion
// names and C-layout types such as with_str. Migrated source also embeds std,
// whose canonical declarations use the same physical symbols with humane With
// types (`str`, `Never`, and so on). Keep those two type surfaces out of With's
// flat namespace while preserving the original linker symbol. The fixed
// preamble externs are already canonical migrator declarations, so their names
// remain unchanged.
pub fn ci_migrate_c_function_name(name: &str) -> str:
    let safe_name = ci_escape_reserved(name)
    if ci_translate_in_migrate_mode() and ci_migrate_is_runtime_cabi_function(name) and not ci_migrate_preamble_declares_runtime_extern(name):
        return "__with_cabi_" ++ safe_name
    safe_name

// A runtime function's borrowed `&str` parameter (with_str_len,
// with_println_str, with_eprint, with_write, with_ewrite) is a `{ptr, len}`
// view passed by value (ABI v8, D71 §4.8a, #1810): the same physical shape
// as the emitted C's by-value `with_str`, so the C declaration links to the
// runtime's symbol directly. The pre-v8 bridge that re-declared the symbol
// with a `&with_str` (one place address) and wrapped it passed a pointer
// where the callee now reads the view's two words.

// ── Migrate entry points (moved from CImport.w in D3) ─────────
// D43: the then arm can fall through as Unit, while the else assignment
// has a str value. Unit deliberately discards that mixed branching tail.
pub fn migrate_add_define(define: &str) -> Unit:
    // define is "NAME=VALUE" or just "NAME"
    if ci_str_contains(define, "="):
        let eq_pos = ci_find_substr(define, "=")
        if eq_pos > 0:
            let name = define.slice(0, eq_pos as i64)
            let value = define.slice((eq_pos + 1) as i64, define.len())
            g_migrate_defines = g_migrate_defines ++ "#define " ++ name ++ " " ++ value ++ "\n"
    else:
        g_migrate_defines = g_migrate_defines ++ "#define " ++ define ++ "\n"

// What precedes a migrated unit. It names no platform and includes no
// header: a libc header included here would fix the feature set before the
// unit's own feature-test macros (#2071: glibc then never declares what a
// later `_LARGEFILE64_SOURCE` asks for), and the unit is to be parsed as a
// C compiler on that target parses it.
//   - `_FORTIFY_SOURCE 0`: a libc that fortifies the copy and format
//     functions does it with macros over compiler builtins; off, a call to
//     memcpy is a call to memcpy on every libc.
//   - `HAVE_UNISTD_H`: migrate often sees a config.h template instead of a
//     configured header, so the one probe a unit most often gates on is
//     answered by asking the target's headers.
fn migrate_host_compat_preamble() -> str:
    "#if !defined(_FORTIFY_SOURCE)\n#define _FORTIFY_SOURCE 0\n#endif\n" ++
    "#if !defined(HAVE_UNISTD_H)\n#ifdef __has_include\n#if __has_include(<unistd.h>)\n#define HAVE_UNISTD_H 1\n#endif\n#endif\n#endif\n"

// D90: the object-like macros a system header defines, and the shape of
// an object-like macro's body as a use of it parses: `leaf` (one token),
// `paren` (one parenthesized expression), `other`. A one-token body that
// names another macro has that macro's shape.
var g_migrate_system_object_macros: HashMap[str, i32] = HashMap.new()
// Each object-like macro's last definition: the one a use after the
// includes expands. A header may define a name twice (clang's <limits.h>
// redefines ULONG_MAX after including the libc's), and the first is not
// the one in effect.
var g_migrate_macro_last_values: HashMap[str, str] = HashMap.new()

pub fn ci_migrate_system_object_macro(name: &str) -> bool: g_migrate_system_object_macros.contains(name)

// The replacement list of `name`'s definition in effect, without the comment
// a header puts after it; "" for a name that is no object-like macro.
pub fn ci_migrate_object_macro_body(name: &str) -> str:
    if not g_migrate_macro_last_values.contains(name): return ""
    var text = g_migrate_macro_last_values.get(name).unwrap().clone()
    let block_comment = text.find("/*")
    if block_comment >= 0: text = text.slice(0, block_comment)
    let line_comment = text.find("//")
    if line_comment >= 0: text = text.slice(0, line_comment)
    ci_trim(text)

pub fn ci_migrate_object_macro_shape(name: &str, depth: i32) -> str:
    let body = ci_migrate_object_macro_body(name)
    if depth > 16 or body.len() == 0: return "other"
    var one_token = true
    for i in 0..body.len():
        let c = body[i]
        if not ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_' or c == '.'): one_token = false
    if one_token:
        if g_migrate_macro_last_values.contains(body) and body != name: return ci_migrate_object_macro_shape(body, depth + 1)
        return "leaf"
    if body[0] != '(': return "other"
    var nesting = 0
    for i in 0..body.len():
        if body[i] == '(': nesting += 1
        if body[i] == ')':
            nesting -= 1
            if nesting == 0: return if i == body.len() - 1: "paren" else: "other"
    "other"

fn ci_capture_macro_values(session: i64):
    g_migrate_macro_values = HashMap.new()
    g_migrate_system_object_macros = HashMap.new()
    g_migrate_macro_last_values = HashMap.new()
    g_migrate_macro_miss_names = HashMap.new()
    let count = with_cimport_macro_count(session)
    var i = 0
    while i < count:
        if with_cimport_macro_is_fn_like(session, i) == 0:
            let name = with_cimport_macro_name(session, i)
            let value = with_cimport_macro_value(session, i)
            if name.len() > 0 and value.len() > 0:
                g_migrate_macro_last_values.remove(name)
                g_migrate_macro_last_values.insert(ci_ir_owned_text(name), ci_ir_owned_text(value))
            if name.len() > 0 and value.len() > 0 and not g_migrate_macro_values.contains(name):
                g_migrate_macro_values.insert(ci_ir_owned_text(name), ci_ir_owned_text(value))
                if with_cimport_macro_is_system(session, i) != 0: g_migrate_system_object_macros.insert(ci_ir_owned_text(name), 1)
        i = i + 1

pub fn ci_collect_macro_type_names(session: i64) -> str:
    let count = with_cimport_decl_count(session)
    var names = ""
    var i = 0
    while i < count:
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_TYPEDEF or kind == CK_STRUCT or kind == CK_UNION or kind == CK_ENUM:
            let name = with_cimport_decl_name(session, i)
            if name.len() > 0 and name[0] != 95:
                names = names ++ "|" ++ name ++ "|"
        i = i + 1
    names

pub fn ci_collect_macro_type_aliases(session: i64) -> str:
    let count = with_cimport_decl_count(session)
    var aliases = ""
    var i = 0
    while i < count:
        if with_cimport_decl_kind(session, i) == CK_TYPEDEF:
            let name = with_cimport_decl_name(session, i)
            let translated = with_cimport_typedef_underlying_translated(session, i)
            if name.len() > 0 and name[0] != 95 and translated.len() > 0:
                aliases = aliases ++ "|" ++ name ++ "=" ++ translated ++ "|"
        i = i + 1
    aliases

fn ci_migrate_prepare_include_path(input_path: &str):
    with_cimport_clear_include_paths()
    var dir_end = input_path.len() as i32 - 1
    while dir_end > 0 and input_path[dir_end] != 47:  // '/'
        dir_end = dir_end - 1
    if dir_end > 0:
        with_cimport_add_include_path(input_path.slice(0, dir_end as i64))
    for i in 0..g_migrate_include_paths.len() as i32:
        with_cimport_add_include_path(g_migrate_include_paths[i])

// Portable-baseline migration preamble: undefine host CPU-feature macros so C
// libraries select their generic, portable code path instead of host-specific
// SIMD / inline-asm fast paths (e.g. zlib's __ARM_FEATURE_CRC32 hardware-CRC
// path, which is inline ARM assembly with no portable With representation).
// Migration targets a portable baseline, not the host CPU; mandatory baseline
// features (SSE2 on x86-64, NEON on aarch64) are intentionally left defined.
// `#undef` of an undefined macro is a legal no-op, so this block is uniform and
// architecture-agnostic. Emitted before the file's #line directive, so it never
// shifts source line numbers.
fn ci_migrate_portable_baseline_preamble() -> str:
    "#undef __ARM_FEATURE_CRC32\n" ++
    "#undef __ARM_FEATURE_CRYPTO\n" ++
    "#undef __ARM_FEATURE_AES\n" ++
    "#undef __ARM_FEATURE_SHA2\n" ++
    "#undef __ARM_FEATURE_SHA3\n" ++
    "#undef __ARM_FEATURE_SHA512\n" ++
    "#undef __ARM_FEATURE_SVE\n" ++
    "#undef __ARM_FEATURE_SVE2\n" ++
    "#undef __SSE3__\n" ++
    "#undef __SSSE3__\n" ++
    "#undef __SSE4_1__\n" ++
    "#undef __SSE4_2__\n" ++
    "#undef __AVX__\n" ++
    "#undef __AVX2__\n" ++
    "#undef __AVX512F__\n" ++
    "#undef __PCLMUL__\n" ++
    "#undef __VPCLMULQDQ__\n"

fn ci_migrate_source_prefix() -> str:
    let compat_preamble = migrate_host_compat_preamble()
    var prefix = ci_migrate_portable_baseline_preamble() ++ g_migrate_defines ++ compat_preamble
    for i in 0..g_migrate_forced_includes.len() as i32:
        prefix = prefix ++ "#include \"" ++ g_migrate_forced_includes[i] ++ "\"\n"
    prefix

fn ci_migrate_wrapped_source(input_path: &str) -> str:
    let raw_source = with_fs_read_file(input_path)
    if raw_source.len() == 0:
        return ""
    let source_prefix = ci_migrate_source_prefix()
    let line_directive = "#line 1 \"" ++ input_path ++ "\"\n"
    source_prefix ++ line_directive ++ raw_source

fn ci_migrate_project_var_owner_rank(definition_kind: i32) -> i32:
    if definition_kind == CI_VAR_FULL_DEF:
        return 2
    if definition_kind == CI_VAR_TENTATIVE_DEF:
        return 1
    0

impl CiProject:
    fn migrate_var_type_id(session: i64, idx: i32, owner_type: &str) -> CiTypeId:
        let cursor = with_cimport_decl_cursor(session, idx)
        if cursor < 0:
            return 0 as CiTypeId
        var ty_id = self.types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
        if owner_type.len() == 0:
            return ty_id
        if (ty_id as i32) == 0 or ci_print_type(self.types, ty_id) != owner_type:
            ty_id = self.types.type_from_translated_text(owner_type)
        ty_id

    // The module that owns a header's inline definitions: the registered
    // unit whose stem equals the header's (`dir/tommyhashdyn.h:12:1` ->
    // the module for `.../tommyhashdyn.c`), or -1 when no unit has it.
    fn header_owner_module(location: &str) -> i32:
        // Only a HEADER's definition is API; a unit's own `static inline`
        // helpers (tommyhashdyn.c's hashdyn_grow_step) stay private.
        if not ci_migrate_location_is_header(location): return -1
        let stem = ci_migrate_location_stem(location)
        if stem.len() == 0: return -1
        for i in 0..self.module_paths.len() as i32:
            if ci_migrate_path_stem(ci_migrate_path_basename(self.module_paths[i])) == stem: return i
        -1

    // Every unit of the migration is a module before any file is scanned,
    // so a header's owner resolves whatever the scan order.
    mut fn register_modules(files: &Vec[str]):
        for path in files: let _ = self.ensure_module(path)

    mut fn migrate_scan_file(input_path: &str) -> i32:
        ci_migrate_prepare_include_path(input_path)
        ci_prepare_clang_resource_dir()
        let source = ci_migrate_wrapped_source(input_path)
        if source.len() == 0:
            eprint("migrate: cannot read " ++ input_path)
            return 1

        let session = with_cimport_parse(source)
        if session == 0:
            eprint("migrate: failed to parse " ++ input_path)
            return 1
        with_cimport_session_set_migration(session)

        let err_msg = with_cimport_error(session)
        if err_msg.len() > 0:
            eprint("migrate: parse error: " ++ err_msg)
            with_cimport_dispose(session)
            return 1

        let module_id = self.ensure_module(input_path)
        let count = with_cimport_decl_count(session)
        var i = 0
        while i < count:
            if with_cimport_decl_kind(session, i) == CK_VAR:
                let name = with_cimport_decl_name(session, i)
                let cursor = with_cimport_decl_cursor(session, i)
                let loc = if cursor >= 0: with_ci_cursor_location(session, cursor) else: ""
                if name.len() == 0 or ci_is_system_decl(name) or (loc.len() > 0 and ci_is_system_path(loc)):
                    i = i + 1
                    continue
                if with_cimport_var_storage_class(session, i) == CX_SC_STATIC:
                    i = i + 1
                    continue
                let symbol_id = self.ensure_symbol(CiProjectSymbolKind.CIPS_VAR, name)
                self.symbols[symbol_id].add_consumer(module_id)

                let owner_kind = ci_migrate_var_definition_kind(session, i)
                if cursor < 0 or owner_kind == CI_VAR_DECL_ONLY:
                    i = i + 1
                    continue

                let owner_type = ci_migrate_var_owner_type(session, i)
                if owner_type.len() == 0 or ci_starts_with(owner_type, "__UNSUPPORTED:"):
                    eprint("migrate: unsupported global owner type for " ++ name ++ " in " ++ input_path)
                    with_cimport_dispose(session)
                    return 1

                let owner_rank = ci_migrate_project_var_owner_rank(owner_kind)
                if self.symbols[symbol_id].owner_module < 0:
                    self.symbols[symbol_id].owner_module = module_id
                    self.symbols[symbol_id].owner_rank = owner_rank
                    self.symbols[symbol_id].owner_definition_kind = owner_kind
                    // owner_type's bytes live in THIS FILE's cimport session,
                    // which is disposed before emission — store an owned copy.
                    self.symbols[symbol_id].resolved_ty_text = ci_ir_owned_text(owner_type)
                    self.symbols[symbol_id].resolved_ty = self.migrate_var_type_id(session, i, owner_type)
                    i = i + 1
                    continue

                let existing_path = self.owner_module_path(symbol_id)
                if self.symbols[symbol_id].owner_rank == owner_rank:
                    if self.symbols[symbol_id].owner_definition_kind == CI_VAR_FULL_DEF and owner_kind == CI_VAR_FULL_DEF and existing_path != input_path:
                        eprint("migrate: duplicate full global definition for " ++ name ++ " in " ++ existing_path ++ " and " ++ input_path)
                        with_cimport_dispose(session)
                        return 1
                    if self.symbols[symbol_id].resolved_ty_text.len() > 0 and self.symbols[symbol_id].resolved_ty_text != owner_type:
                        eprint("migrate: conflicting global owner type for " ++ name ++ " in " ++ existing_path ++ " and " ++ input_path)
                        with_cimport_dispose(session)
                        return 1
                if owner_rank > self.symbols[symbol_id].owner_rank or (owner_rank == self.symbols[symbol_id].owner_rank and ci_str_compare(input_path, existing_path) < 0):
                    self.symbols[symbol_id].owner_module = module_id
                    self.symbols[symbol_id].owner_rank = owner_rank
                    self.symbols[symbol_id].owner_definition_kind = owner_kind
                    self.symbols[symbol_id].resolved_ty_text = ci_ir_owned_text(owner_type)
                    self.symbols[symbol_id].resolved_ty = self.migrate_var_type_id(session, i, owner_type)
            else if with_cimport_decl_kind(session, i) == CK_FUNCTION:
                let name = with_cimport_decl_name(session, i)
                let cursor = with_cimport_decl_cursor(session, i)
                let loc = if cursor >= 0: with_ci_cursor_location(session, cursor) else: ""
                if name.len() == 0 or ci_is_system_decl(name) or (loc.len() > 0 and ci_is_system_path(loc)):
                    i = i + 1
                    continue
                if with_cimport_fn_storage_class(session, i) == CX_SC_STATIC:
                    // D107: a static definition's NULL arguments are corpus
                    // caller evidence even though it is no project symbol,
                    // and its own body is the evidence for ITS fn-pointer
                    // parameters (a static callee passed NULL by its unit
                    // was rendered non-null and its NULL test folded, #2230
                    // smoke). The table is name-keyed: a second static of the
                    // same name in another unit keeps the first's evidence.
                    if cursor >= 0 and with_ci_cursor_is_definition(session, cursor) != 0:
                        self.record_call_evidence(session, cursor, name)
                        let static_symbol = self.ensure_symbol(CiProjectSymbolKind.CIPS_FN, name)
                        if self.symbols[static_symbol].has_definition == 0:
                            self.record_fn_evidence(session, i, cursor, static_symbol)
                    // A `static inline` function DEFINED in a header is the
                    // header's API: every includer compiles a private copy,
                    // and the unit of the same name (tommyhashdyn.c for
                    // tommyhashdyn.h) is where the library keeps that
                    // header's code. That unit publishes the one definition;
                    // includers import it. A header no unit owns keeps a
                    // private copy per includer (tommytypes.h's tommy_ilog2).
                    let header_owner = if with_cimport_fn_is_inline(session, i) != 0 and cursor >= 0 and with_ci_cursor_is_definition(session, cursor) != 0: self.header_owner_module(loc) else: -1
                    if header_owner >= 0:
                        let symbol_id = self.ensure_symbol(CiProjectSymbolKind.CIPS_FN, name)
                        self.symbols[symbol_id].add_consumer(module_id)
                        self.symbols[symbol_id].owner_module = header_owner
                        self.symbols[symbol_id].owner_rank = 1
                        self.symbols[symbol_id].owner_definition_kind = 1
                        // D107: a header-owned inline definition is a corpus
                        // definition; its evidence counts once.
                        if self.symbols[symbol_id].has_definition == 0:
                            self.record_fn_evidence(session, i, cursor, symbol_id)
                    i = i + 1
                    continue
                let symbol_id = self.ensure_symbol(CiProjectSymbolKind.CIPS_FN, name)
                self.symbols[symbol_id].add_consumer(module_id)
                if cursor < 0 or with_ci_cursor_is_definition(session, cursor) == 0:
                    i = i + 1
                    continue
                let existing_path = self.owner_module_path(symbol_id)
                if self.symbols[symbol_id].owner_module >= 0 and existing_path != input_path:
                    eprint("migrate: duplicate function definition for " ++ name ++ " in " ++ existing_path ++ " and " ++ input_path)
                    with_cimport_dispose(session)
                    return 1
                self.symbols[symbol_id].owner_module = module_id
                self.symbols[symbol_id].owner_rank = 1
                self.symbols[symbol_id].owner_definition_kind = 1
                // D107: the evidence this definition's body gives.
                self.record_fn_evidence(session, i, cursor, symbol_id)
            i = i + 1

        with_cimport_dispose(session)
        0

// #2060: the location is the declaration's own. A record that only a type
// names (glibc's `struct __locale_data *` inside __locale_struct; ClangBridge
// collect_undefined_record_type) has no top-level cursor, so the by-name
// index has no location for it and it was emitted into the migration as
// `type __locale_data = opaque`: a libc-internal name in the output.
fn ci_migrate_decl_is_filtered(session: i64, idx: i32, name: &str):
    if name.len() == 0 or ci_is_system_decl(name):
        return true
    var loc = ci_get_decl_location(session, name)
    if loc.len() == 0:
        let cursor = with_cimport_decl_cursor(session, idx)
        if cursor >= 0: loc = with_ci_cursor_location(session, cursor)
    if loc.len() > 0 and ci_is_system_path(loc):
        return true
    ci_migrate_is_width_family_name(name)

// Migrate mode is a property of translating a .c file, not of which entry
// point asked for it. Before this wrapper only the single-file CLI path set
// the flag; migrate_c_directory (the build-driven pcre2/zlib migrations) ran
// every mode-gated rule with it off — e.g. the c_import-only #799 callee
// filter then killed zlib on its static adler32_combine_.
fn ci_migrate_file_inner(input_path: &str, output_path: &str, project_active: bool, project: &CiProject) -> i32:
    g_ci_translate_migrate_mode = 1
    let rc = ci_migrate_file_body(input_path, output_path, project_active, project)
    g_ci_translate_migrate_mode = 0
    rc

fn ci_migrate_file_body(input_path: &str, output_path: &str, project_active: bool, project: &CiProject) -> i32:
    if with_cimport_available() == 0:
        eprint("migrate: libclang not available")
        return 1

    ci_migrate_prepare_include_path(input_path)
    ci_prepare_clang_resource_dir()

    g_migrate_file_error = ""
    g_migrate_macro_values = HashMap.new()
    g_migrate_macro_miss_names = HashMap.new()
    g_migrate_macro_session = 0
    ci_migrate_reset_fn_counts()
    ci_migrate_libc_reset()
    ci_migrate_reset_unsafe_extern_fns()
    g_migrate_raw_source = ""
    g_migrate_current_input_path = ""

    // Reset name tracking state for fresh migration
    with_cimport_reset_names()

    // Read source and prepend defines. Preserve the original file path in
    // libclang locations so migrate's system-header filter does not discard
    // declarations from the temp wrapper file used by cimport_parse().
    let source = ci_migrate_wrapped_source(input_path)
    if source.len() == 0:
        eprint("migrate: cannot read " ++ input_path)
        return 1
    let source_prefix = ci_migrate_source_prefix()
    g_migrate_current_input_path = with_str_clone_ref(input_path)
    g_migrate_raw_source = with_str_clone_ref(source)

    // Pass to libclang via cimport_parse
    let session = with_cimport_parse(source)
    if session != 0:
        with_cimport_session_set_migration(session)
    if session == 0:
        g_migrate_raw_source = ""
        g_migrate_current_input_path = ""
        eprint("migrate: failed to parse " ++ input_path)
        return 1

    let err_msg = with_cimport_error(session)
    if err_msg.len() > 0:
        g_migrate_raw_source = ""
        g_migrate_current_input_path = ""
        eprint("migrate: parse error: " ++ err_msg)
        with_cimport_dispose(session)
        return 1

    let abs_input = with_cimport_realpath(input_path)
    if abs_input.len() == 0:
        eprint("migrate: fatal: realpath failed for '" ++ input_path ++ "' — cannot collect macros with relative path")
        return 1
    let macro_include = source_prefix ++ "#include \"" ++ abs_input ++ "\"\n"
    let macro_session = with_cimport_parse_macros(macro_include)
    if macro_session != 0:
        g_migrate_macro_session = macro_session
        ci_capture_macro_values(macro_session)

    let output_parts: Vec[str] = Vec.new()

    // C3: in shared-defs mode, skip the preamble and emit `use <prefix>` instead.
    // The preamble goes into defs.w (written by ci_migrate_write_shared_defs).
    if ci_migrate_shared_defs_active():
        output_parts.push("// Migrated from C\nuse " ++ g_migrate_shared_defs_prefix ++ "\n")
        output_parts.push(ci_migrate_project_imports_for_file(project_active, project, input_path))
        output_parts.push("\n")
    else:
        output_parts.push("// Generated by: with migrate " ++ input_path ++ "\n\n")
        output_parts.push(ci_migrate_preamble_text())

    let count = with_cimport_decl_count(session)
    ci_migrate_collect_unsafe_extern_fns(session, count, input_path, project_active, project)

    // Pre-scan: collect demoted types and prepopulate names
    let demoted_types = ci_collect_demoted_types(session, count)
    let typedef_shadowed = ci_prepopulate_names(session, count)
    g_macro_type_names = ci_collect_macro_type_names(session)
    g_macro_type_aliases = ci_collect_macro_type_aliases(session)

    // Track emitted structs for typedef resolution
    var translated_structs = ""

    // Translate declarations (skip system header noise).
    // Use declaration source location to filter: only emit declarations
    // that originate from the user's file or from PCRE2 headers.
    var i = 0
    while i < count:
        let decl_name = with_cimport_decl_name(session, i)
        if ci_migrate_decl_is_filtered(session, i, decl_name):
            i = i + 1
            continue
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_FUNCTION:
            output_parts.push(ci_migrate_translate_function(session, i, translated_structs, input_path, project_active, project))
        else if kind == CK_STRUCT or kind == CK_UNION:
            let struct_result = ci_translate_struct(session, i, kind == CK_UNION, translated_structs, demoted_types, count)
            let struct_result_len = struct_result.len()
            output_parts.push(struct_result)
            if struct_result_len > 0:
                let sname = with_cimport_decl_name(session, i)
                if sname.len() > 0 and sname[0] != 95:
                    translated_structs = translated_structs ++ "|" ++ sname ++ "|"
                    if ci_str_contains(typedef_shadowed, "|" ++ sname ++ "|"):
                        let alias_name = "struct_" ++ sname
                        if with_cimport_is_name_emitted(alias_name) == 0:
                            with_cimport_mark_name_emitted(alias_name)
                            output_parts.push("type " ++ alias_name ++ " = " ++ ci_escape_reserved(sname) ++ "\n")
        else if kind == CK_ENUM:
            output_parts.push(ci_translate_enum(session, i))
        else if kind == CK_TYPEDEF:
            let td_result = ci_translate_typedef(session, i, count)
            let td_result_len = td_result.len()
            output_parts.push(td_result)
            if td_result_len > 0:
                let td_name = with_cimport_decl_name(session, i)
                if td_name.len() > 0 and td_name[0] != 95:
                    translated_structs = translated_structs ++ "|" ++ td_name ++ "|"
        else if kind == CK_STATIC_ASSERT:
            let sa_name = with_cimport_decl_name(session, i)
            if sa_name.len() > 0:
                output_parts.push("// static_assert: " ++ sa_name ++ "\n")
        i = i + 1

    output_parts.push(ci_migrate_translate_vars(session, count, input_path, project_active, project))
    if g_migrate_file_error.len() > 0:
        eprint(g_migrate_file_error)
        g_macro_type_names = ci_collect_macro_type_names(session)
        g_macro_type_aliases = ci_collect_macro_type_aliases(session)
        with_cimport_dispose(session)
        if macro_session != 0:
            with_cimport_dispose_macros(macro_session)
        g_migrate_macro_values = HashMap.new()
        g_migrate_macro_miss_names = HashMap.new()
        g_migrate_macro_session = 0
        g_migrate_raw_source = ""
        g_migrate_current_input_path = ""
        g_macro_type_names = ""
        g_macro_type_aliases = ""
        g_migrate_file_error = ""
        return 1

    // Member function detection
    output_parts.push(ci_detect_member_functions(session, count, translated_structs))
    // Macro translation via separate preprocessor pass
    if macro_session != 0:
        output_parts.push(ci_translate_macros(macro_session, session, macro_include))
        with_cimport_dispose_macros(macro_session)
    with_cimport_dispose(session)
    g_migrate_macro_values = HashMap.new()
    g_migrate_macro_miss_names = HashMap.new()
    g_migrate_macro_session = 0
    g_migrate_raw_source = ""
    g_migrate_current_input_path = ""
    g_macro_type_names = ""
    g_macro_type_aliases = ""
    g_migrate_file_error = ""

    var output = output_parts.join("")
    output = ci_migrate_insert_libc_use(output)
    output = ci_migrate_insert_option_use(output)

    ci_migrate_shared_note_output_uses(output)
    output = ci_migrate_publicize_types(ci_migrate_normalize_output(output))

    // Write output
    let write_result = with_fs_write_file(output_path, output)
    if write_result == 0:
        ci_migrate_writes_note_path(output_path)
    if write_result != 0:
        eprint("migrate: failed to write " ++ output_path)
        g_migrate_macro_values = HashMap.new()
        g_migrate_macro_miss_names = HashMap.new()
        g_migrate_macro_session = 0
        g_migrate_raw_source = ""
        g_migrate_current_input_path = ""
        return 1

    // Print stats
    let goto_count = ci_count_substring(with_fs_read_file(input_path), "goto ")
    let unsafe_count = ci_count_substring(output, "unsafe")
    eprint(f"migrate: {input_path} -> {output_path} ({goto_count} gotos, {unsafe_count} unsafe)")
    g_migrate_fn_translated_total = g_migrate_fn_translated_total + g_migrate_fn_translated
    0

pub fn migrate_c_file(input_path_arg: &str, output_path_arg: &str) -> i32:
    let input_path = ci_migrate_fs_path(input_path_arg)
    let output_path = ci_migrate_fs_path(output_path_arg)
    var project = CiProject.new()
    ci_migrate_writes_reset()
    // D107: a lone unit is its own corpus — its definitions' body evidence
    // and NULL callers decide their function-pointer parameters.
    var one: Vec[str] = Vec.new()
    one.push(input_path.clone())
    project.register_modules(&one)
    if project.migrate_scan_file(input_path) != 0: return 1
    project.resolve_fn_ptr_nullability()
    project.export_fn_ptr_nullability(true)
    let rc = ci_migrate_file_inner(input_path, output_path, false, &project)
    if rc != 0: return rc
    ci_migrate_apply_writes_clauses()

// Every path the migrator handles is spelled with `/`: the Clang bridge
// rewrites every location and file name it hands up (its path boundary),
// the runtime's directory listing joins with `/`, and the CLI paths are
// rewritten once at entry (ci_migrate_fs_path). No helper here looks for
// `\`.
fn ci_migrate_fs_path(path: &str) -> str: path.replace("\\", "/")

fn ci_migrate_path_basename(path: &str) -> str:
    var end = path.len() as i32
    while end > 0 and path[(end - 1)] == '/':
        end = end - 1
    var start = end - 1
    while start >= 0 and path[start] != '/':
        start = start - 1
    path.slice((start + 1) as i64, end as i64)

// `name.c` -> `name`; a name without a dot is its own stem.
fn ci_migrate_path_stem(basename: &str) -> str:
    var end = basename.len() as i32
    while end > 0 and basename[(end - 1)] != '.':
        end = end - 1
    if end == 0: basename.clone() else: basename.slice(0, (end - 1) as i64)

// The file of a cursor location (`path:line:col`), "" when absent.
fn ci_migrate_location_file(location: &str) -> str:
    var end = location.len() as i32
    var colons = 0
    while end > 0 and colons < 2:
        end = end - 1
        if location[end] == ':': colons = colons + 1
    if colons < 2: "" else: location.slice(0, end as i64)

fn ci_migrate_location_is_header(location: &str) -> bool:
    ci_migrate_location_file(location).ends_with(".h")

// The file stem of a cursor location (`path:line:col`), "" when absent.
fn ci_migrate_location_stem(location: &str) -> str:
    let file = ci_migrate_location_file(location)
    if file.len() == 0: return ""
    ci_migrate_path_stem(ci_migrate_path_basename(file))

fn ci_migrate_excludes_contains(excludes: &str, basename: &str) -> bool:
    if excludes.len() == 0 or basename.len() == 0:
        return false
    let needle = "|" ++ basename ++ "|"
    ci_find_str(excludes, needle) >= 0

fn ci_migrate_pcre2_order_rank(basename: &str) -> i32:
    if basename == "pcre2_chkdint.c": return 10
    if basename == "pcre2_chartables.c": return 20
    if basename == "pcre2_tables.c": return 30
    if basename == "pcre2_ucd.c": return 40
    if basename == "pcre2_config.c": return 50
    if basename == "pcre2_context.c": return 60
    if basename == "pcre2_error.c": return 70
    if basename == "pcre2_newline.c": return 80
    if basename == "pcre2_string_utils.c": return 90
    if basename == "pcre2_ord2utf.c": return 100
    if basename == "pcre2_extuni.c": return 110
    if basename == "pcre2_valid_utf.c": return 120
    if basename == "pcre2_xclass.c": return 130
    if basename == "pcre2_find_bracket.c": return 140
    if basename == "pcre2_convert.c": return 150
    if basename == "pcre2_compile_cgroup.c": return 160
    if basename == "pcre2_compile_class.c": return 170
    if basename == "pcre2_auto_possess.c": return 180
    if basename == "pcre2_compile.c": return 190
    if basename == "pcre2_maketables.c": return 200
    if basename == "pcre2_match_data.c": return 210
    if basename == "pcre2_pattern_info.c": return 220
    if basename == "pcre2_dfa_match.c": return 230
    if basename == "pcre2_match_next.c": return 240
    if basename == "pcre2_match.c": return 250
    if basename == "pcre2_serialize.c": return 260
    if basename == "pcre2_substring.c": return 270
    if basename == "pcre2_substitute.c": return 280
    if basename == "pcre2_study.c": return 290
    if basename == "pcre2_script_run.c": return 300
    if basename == "pcre2posix.c": return 310
    if basename == "pcre2test.c": return 320
    1000

fn ci_migrate_file_before(a: &str, b: &str) -> bool:
    let abase = ci_migrate_path_basename(a)
    let bbase = ci_migrate_path_basename(b)
    let arank = ci_migrate_pcre2_order_rank(abase)
    let brank = ci_migrate_pcre2_order_rank(bbase)
    if arank != brank:
        return arank < brank
    ci_str_compare(abase, bbase) < 0

fn ci_migrate_sorted_files(files: &Vec[str]) -> Vec[str]:
    let sorted: Vec[str] = Vec.new()
    var rank = 10
    while rank <= 320:
        var i = 0
        while i < files.len() as i32:
            let path = files[i]
            if ci_migrate_pcre2_order_rank(ci_migrate_path_basename(path)) == rank:
                sorted.push(with_str_clone_ref(path))
            i = i + 1
        rank = rank + 10
    var i = 0
    while i < files.len() as i32:
        let path = files[i]
        if ci_migrate_pcre2_order_rank(ci_migrate_path_basename(path)) == 1000:
            sorted.push(with_str_clone_ref(path))
        i = i + 1
    sorted

fn ci_migrate_directory_output_path(input_dir: &str, output_dir: &str, file_path: &str):
    output_dir ++ "/" ++ ci_migrate_module_relative_path(input_dir, file_path) ++ ".w"

fn ci_migrate_validate_module_paths(input_dir: &str, files: &Vec[str]):
    var owners: HashMap[str, str] = HashMap.new()
    for path in files:
        let module_path = ci_migrate_module_relative_path(input_dir, path)
        if ci_migrate_shared_defs_active() and module_path == "defs":
            eprint("migrate: source " ++ path ++ " collides with the shared definitions module")
            return false
        if owners.contains(module_path):
            eprint("migrate: module path collision: " ++ owners.get(module_path).unwrap() ++ " and " ++ path ++ " both map to " ++ module_path)
            return false
        owners.insert(module_path, path.clone())
    true

fn ci_migrate_print_progress(file_path: &str, current: i32, total: i32):
    let base = ci_migrate_path_basename(file_path)
    var percent = 0
    if total > 0:
        percent = (current * 100) / total
    with_write_stdout(f"migrate: processing {base} - {current}/{total}, {percent}% completed\n")
    with_flush_stdout()

fn ci_migrate_ensure_parent_dir(path: &str):
    var dir_end = path.len() as i32 - 1
    while dir_end > 0 and path[dir_end] != 47:
        dir_end = dir_end - 1
    if dir_end > 0:
        with_fs_mkdir_p(path.slice(0, dir_end as i64))

fn ci_migrate_path_is_c_file(path: &str) -> bool:
    path.len() > 2 and path.slice(path.len() - 2, path.len()) == ".c"

fn ci_migrate_basename_is_hidden(path: &str) -> bool:
    let base = ci_migrate_path_basename(path)
    base.len() > 0 and base[0] == 46

fn ci_migrate_sorted_insert(files: &Vec[str], path: &str) -> Vec[str]:
    let sorted: Vec[str] = Vec.new()
    var inserted = false
    var i = 0
    while i < files.len() as i32:
        let existing = files[i]
        if not inserted and ci_str_compare(path, existing) < 0:
            sorted.push(with_str_clone_ref(path))
            inserted = true
        sorted.push(with_str_clone_ref(existing))
        i = i + 1
    if not inserted:
        sorted.push(with_str_clone_ref(path))
    sorted

fn ci_migrate_collect_c_files(input_dir: &str, exclude_basenames: &str) -> Vec[str]:
    var files: Vec[str] = Vec.new()
    let listing = with_fs_list_files(input_dir)
    var pos = 0
    let n = listing.len() as i32
    while pos < n:
        var line_end = pos
        while line_end < n and listing[line_end] != 10:
            line_end = line_end + 1
        if line_end > pos:
            let file_path = listing.slice(pos as i64, line_end as i64)
            let base = ci_migrate_path_basename(file_path)
            if ci_migrate_path_is_c_file(file_path) and not ci_migrate_basename_is_hidden(file_path) and not ci_migrate_excludes_contains(exclude_basenames, base):
                files = ci_migrate_sorted_insert(files, file_path)
        pos = line_end + 1
    files

// ── D107 (#2240): nullable-by-evidence function-pointer parameters ──────
//
// The verdicts the last `resolve_fn_ptr_nullability` drew, exported for
// CImport: one entry per corpus function, `bits` holding one char per
// parameter ('1' Option, '0' non-null, '?' not a function pointer) and
// `reasons` the one-line reason per parameter, `|`-separated.
var g_migrate_fn_nullable_names: Vec[str] = Vec.new()
var g_migrate_fn_nullable_bits: Vec[str] = Vec.new()
var g_migrate_fn_nullable_reasons: Vec[str] = Vec.new()

fn ci_migrate_fn_nullable_index(name: &str) -> i32:
    for i in 0..g_migrate_fn_nullable_names.len() as i32:
        if g_migrate_fn_nullable_names[i] == name: return i
    -1

/// D107: 1 when parameter `index` of corpus function `name` is `Option`,
/// 0 when the corpus decided it non-null, -1 when the corpus has no
/// verdict (not a corpus definition: D102's declaration rules apply).
pub fn ci_migrate_fn_param_nullable(name: &str, index: i32) -> i32:
    let i = ci_migrate_fn_nullable_index(name)
    if i < 0: return -1
    let bits = g_migrate_fn_nullable_bits[i]
    if index < 0 or index >= bits.len() as i32: return -1
    let c = bits[index]
    if c == '1': 1 else if c == '0': 0 else: -1

/// The reason behind `ci_migrate_fn_param_nullable`'s verdict, or "".
pub fn ci_migrate_fn_param_reason(name: &str, index: i32) -> str:
    let i = ci_migrate_fn_nullable_index(name)
    if i < 0: return ""
    let parts = g_migrate_fn_nullable_reasons[i].split("|")
    if index < 0 or index >= parts.len() as i32: return ""
    parts[index].to_owned()

impl CiProject:
    // The evidence definition `decl_idx` (cursor `cursor`) gives: which
    // parameters are function pointers, whether the body tests each for
    // NULL (and how), the NULL literals it passes to corpus callees, and
    // where it passes or stores its own parameters.
    mut fn record_fn_evidence(session: i64, decl_idx: i32, cursor: i32, symbol_id: i32):
        let count = with_cimport_fn_param_count(session, decl_idx)
        var names: Vec[str] = Vec.new()
        for pi in 0..count:
            names.push(ci_escape_reserved(with_cimport_fn_param_name(session, decl_idx, pi)))
        self.symbols[symbol_id].grow_params(count)
        self.symbols[symbol_id].has_definition = 1
        for pi in 0..count:
            let ptype = with_cimport_fn_param_type_translated(session, decl_idx, pi)
            if not ci_type_text_is_fn_ptr(ptype): continue
            self.symbols[symbol_id].param_fn_ptr[pi] = 1
            if names[pi].len() == 0:
                self.symbols[symbol_id].unanalyzable = 1
                continue
            let test = ci_body_null_test_evidence(session, cursor, names[pi])
            if test == 1: self.symbols[symbol_id].param_tested[pi] = 1
            else if test == -1: self.symbols[symbol_id].param_aborting[pi] = 1
        let fname = with_str_clone_ref(self.symbols[symbol_id].name)
        for line in ci_body_call_evidence(session, cursor, &names).split("\n"):
            if line.len() == 0: continue
            let parts = line.split(":")
            if parts[0] == "null" and parts.len() == 3:
                let callee = self.ensure_symbol(CiProjectSymbolKind.CIPS_FN, parts[1])
                let index = parse(parts[2])
                self.symbols[callee].grow_params(index + 1)
                if self.symbols[callee].param_null_caller[index].len() == 0:
                    self.symbols[callee].param_null_caller[index] = fname.clone()
            else if parts[0] == "sink" and parts.len() == 4:
                let pi = ci_index_of_name(&names, parts[3])
                if pi >= 0: self.symbols[symbol_id].param_sinks[pi] = self.symbols[symbol_id].param_sinks[pi] ++ parts[1] ++ ":" ++ parts[2] ++ ";"
            else if (parts[0] == "field" or parts[0] == "global") and parts.len() == 2:
                let pi = ci_index_of_name(&names, parts[1])
                if pi >= 0: self.symbols[symbol_id].param_sinks[pi] = self.symbols[symbol_id].param_sinks[pi] ++ parts[0] ++ ";"

    // A static definition is not a project symbol, but its calls are corpus
    // calls: a NULL it passes to a corpus function is caller evidence
    // (pcre2test's `pcre2_jit_stack_assign(ctx, NULL, NULL)`).
    mut fn record_call_evidence(session: i64, cursor: i32, fname: &str):
        let none: Vec[str] = Vec.new()
        for line in ci_body_call_evidence(session, cursor, &none).split("\n"):
            let parts = line.split(":")
            if parts.len() != 3 or parts[0] != "null": continue
            let callee = self.ensure_symbol(CiProjectSymbolKind.CIPS_FN, parts[1])
            let index = parse(parts[2])
            self.symbols[callee].grow_params(index + 1)
            if self.symbols[callee].param_null_caller[index].len() == 0:
                self.symbols[callee].param_null_caller[index] = fname.to_owned()

    // The least fixed point over the corpus (D107): a parameter is Option
    // when its body tests it with a continuing NULL branch, a corpus caller
    // passes NULL, it is stored into a field or a global, it is passed to a
    // corpus parameter that is Option, or it is passed to a corpus function
    // with no definition here (an unresolved dependency); a cycle of
    // sinks with no other evidence is Option for every member. The order
    // of units never enters: the result is a function of the evidence.
    mut fn resolve_fn_ptr_nullability():
        let n = self.symbols.len() as i32
        for si in 0..n:
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN: continue
            let count = self.symbols[si].param_fn_ptr.len() as i32
            self.symbols[si].grow_params(count)
            for pi in 0..count:
                if self.symbols[si].param_fn_ptr[pi] == 0: continue
                if self.symbols[si].unanalyzable != 0:
                    self.symbols[si].param_nullable[pi] = 1
                    self.symbols[si].param_reason[pi] = "Option: body not analyzable"
                else if self.symbols[si].param_tested[pi] != 0:
                    self.symbols[si].param_nullable[pi] = 1
                    self.symbols[si].param_reason[pi] = "Option: body tests it for NULL and continues"
                else if self.symbols[si].param_null_caller[pi].len() > 0:
                    self.symbols[si].param_nullable[pi] = 1
                    self.symbols[si].param_reason[pi] = "Option: caller " ++ self.symbols[si].param_null_caller[pi] ++ " passes NULL"
                else if self.symbols[si].param_sinks[pi].contains("field;"):
                    self.symbols[si].param_nullable[pi] = 1
                    self.symbols[si].param_reason[pi] = "Option: stored into a record field"
                else if self.symbols[si].param_sinks[pi].contains("global;"):
                    self.symbols[si].param_nullable[pi] = 1
                    self.symbols[si].param_reason[pi] = "Option: assigned to a global"
        // Propagate through sinks to closure.
        var changed = true
        while changed:
            changed = false
            for si in 0..n:
                if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN: continue
                let count = self.symbols[si].param_fn_ptr.len() as i32
                for pi in 0..count:
                    if self.symbols[si].param_fn_ptr[pi] == 0 or self.symbols[si].param_nullable[pi] != 0: continue
                    for sink in self.symbols[si].param_sinks[pi].split(";"):
                        if not sink.contains(":"): continue
                        let kv = sink.split(":")
                        let callee = self.find_symbol(CiProjectSymbolKind.CIPS_FN, kv[0])
                        let index = parse(kv[1])
                        if callee < 0: continue   // not declared by the project: a system prototype, D102 non-null
                        if self.symbols[callee].has_definition == 0:
                            self.symbols[si].param_nullable[pi] = 1
                            self.symbols[si].param_reason[pi] = "Option: passed to " ++ kv[0] ++ ", defined outside the corpus"
                            changed = true
                            break
                        if index < self.symbols[callee].param_nullable.len() as i32 and self.symbols[callee].param_nullable[index] != 0:
                            self.symbols[si].param_nullable[pi] = 1
                            self.symbols[si].param_reason[pi] = "Option: passed to " ++ kv[0] ++ f" param {index}, which is Option"
                            changed = true
                            break
        // A cycle with no other evidence: Option for every member. A
        // parameter still non-null whose sink chain reaches itself is one.
        for si in 0..n:
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN: continue
            let count = self.symbols[si].param_fn_ptr.len() as i32
            for pi in 0..count:
                if self.symbols[si].param_fn_ptr[pi] == 0 or self.symbols[si].param_nullable[pi] != 0: continue
                if self.sink_chain_reaches(si, pi, si, pi, 0):
                    self.symbols[si].param_nullable[pi] = 1
                    self.symbols[si].param_reason[pi] = "Option: part of a cycle of forwarded parameters"
        for si in 0..n:
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN: continue
            let count = self.symbols[si].param_fn_ptr.len() as i32
            for pi in 0..count:
                if self.symbols[si].param_fn_ptr[pi] != 0 and self.symbols[si].param_nullable[pi] == 0:
                    self.symbols[si].param_reason[pi] = if self.symbols[si].param_aborting[pi] != 0: "non-null: the NULL branch aborts (a contract), no NULL callers" else: "non-null: called unconditionally, no NULL callers"

    fn sink_chain_reaches(from_si: i32, from_pi: i32, target_si: i32, target_pi: i32, depth: i32) -> bool:
        if depth > 64: return false
        for sink in self.symbols[from_si].param_sinks[from_pi].split(";"):
            if not sink.contains(":"): continue
            let kv = sink.split(":")
            let callee = self.find_symbol(CiProjectSymbolKind.CIPS_FN, kv[0])
            if callee < 0: continue
            let index = parse(kv[1])
            if index >= self.symbols[callee].param_fn_ptr.len() as i32: continue
            if callee == target_si and index == target_pi: return true
            if self.sink_chain_reaches(callee, index, target_si, target_pi, depth + 1): return true
        false

    // Export the verdicts for CImport and say each one once.
    fn export_fn_ptr_nullability(verbose: bool):
        g_migrate_fn_nullable_names = Vec.new()
        g_migrate_fn_nullable_bits = Vec.new()
        g_migrate_fn_nullable_reasons = Vec.new()
        for si in 0..self.symbols.len() as i32:
            if self.symbols[si].kind != CiProjectSymbolKind.CIPS_FN or self.symbols[si].has_definition == 0: continue
            var bits = ""
            var reasons = ""
            let count = self.symbols[si].param_fn_ptr.len() as i32
            for pi in 0..count:
                if pi > 0: reasons = reasons ++ "|"
                if self.symbols[si].param_fn_ptr[pi] == 0:
                    bits = bits ++ "?"
                    continue
                bits = bits ++ (if self.symbols[si].param_nullable[pi] != 0: "1" else: "0")
                reasons = reasons ++ self.symbols[si].param_reason[pi]
                if verbose: eprint("migrate: " ++ self.symbols[si].name ++ f" param {pi}: " ++ self.symbols[si].param_reason[pi])
            g_migrate_fn_nullable_names.push(self.symbols[si].name.clone())
            g_migrate_fn_nullable_bits.push(bits)
            g_migrate_fn_nullable_reasons.push(reasons)

fn ci_index_of_name(names: &Vec[str], name: &str) -> i32:
    for i in 0..names.len() as i32:
        if names[i] == name: return i
    -1

fn ci_migrate_directory_filewise(input_dir: &str, output_dir: &str, files: &Vec[str]) -> i32:
    let fragments: Vec[str] = Vec.new()
    with_fs_mkdir_p(output_dir)
    var migrated = 0
    var i = 0
    let total = files.len() as i32
    while i < files.len() as i32:
        let file_path = files[i]
        let base = ci_migrate_path_basename(file_path)
        let out_path = ci_migrate_directory_output_path(input_dir, output_dir, file_path)
        ci_migrate_ensure_parent_dir(out_path)
        ci_migrate_print_progress(file_path, i + 1, total)

        ci_migrate_shared_defs_reset()
        var project = CiProject.new()
        project.register_modules(files)
        var scan_i = 0
        while scan_i < files.len() as i32:
            if project.migrate_scan_file(files[scan_i]) != 0:
                eprint(f"migrate: failed while scanning project for {base}")
                return 1
            scan_i = scan_i + 1

        // D107: the corpus-wide nullability verdicts, drawn once the whole
        // project is scanned; said once per directory.
        project.resolve_fn_ptr_nullability()
        project.export_fn_ptr_nullability(i == 0)
        let rc = ci_migrate_file_inner(file_path, out_path, true, &project)
        if rc != 0:
            eprint(f"migrate: failed while migrating {base}")
            return rc
        migrated = migrated + 1
        fragments.push(ci_migrate_shared_fragment_text())
        i = i + 1
    ci_migrate_merge_shared_fragment_texts(output_dir, fragments)
    eprint(f"migrate: {migrated}/{files.len() as i32} files translated from {input_dir} -> {output_dir}")
    if migrated == 0: 1 else: ci_migrate_apply_writes_clauses()

// Translate a directory of .c files to .w files.
pub fn migrate_c_directory(input_dir_arg: &str, output_dir_arg: &str, exclude_basenames: &str) -> i32:
    let input_dir = ci_migrate_fs_path(input_dir_arg)
    let output_dir = ci_migrate_fs_path(output_dir_arg)
    g_migrate_fn_translated_total = 0
    g_migrate_directory_input_dir = with_str_clone_ref(input_dir)
    ci_migrate_writes_reset()
    if ci_migrate_shared_defs_active():
        ci_migrate_shared_defs_reset()
    // Create output directory
    with_fs_mkdir_p(output_dir)

    let files = ci_migrate_collect_c_files(input_dir, exclude_basenames)
    if files.len() == 0:
        eprint("migrate: no .c files found in " ++ input_dir)
        return 1

    let sorted_files = ci_migrate_sorted_files(files)
    if not ci_migrate_validate_module_paths(input_dir, sorted_files): return 1
    let files_scanned = sorted_files.len() as i32
    var files_migrated = 0

    if ci_migrate_shared_defs_active() and g_migrate_directory_one_basename.len() == 0:
        return ci_migrate_directory_filewise(input_dir, output_dir, sorted_files)

    var project = CiProject.new()
    project.register_modules(&sorted_files)
    var scan_i = 0
    while scan_i < sorted_files.len() as i32:
        if project.migrate_scan_file(sorted_files[scan_i]) != 0:
            return 1
        scan_i = scan_i + 1
    // D107: the corpus-wide nullability verdicts, drawn once, said once.
    project.resolve_fn_ptr_nullability()
    project.export_fn_ptr_nullability(true)

    var fi = 0
    let total_files = sorted_files.len() as i32
    while fi < sorted_files.len() as i32:
        let file_path = sorted_files[fi]
        if g_migrate_directory_one_basename.len() > 0 and ci_migrate_path_basename(file_path) != g_migrate_directory_one_basename:
            fi = fi + 1
            continue
        // Compute output path: replace input_dir prefix with output_dir, .c → .w
        let out_path = ci_migrate_directory_output_path(input_dir, output_dir, file_path)
        ci_migrate_ensure_parent_dir(out_path)

        if g_migrate_directory_one_basename.len() == 0:
            ci_migrate_print_progress(file_path, fi + 1, total_files)
        let rc = ci_migrate_file_inner(file_path, out_path, true, &project)
        if rc == 0:
            files_migrated = files_migrated + 1
        fi = fi + 1

    // C3: emit shared defs module after all files are translated
    if ci_migrate_shared_defs_active():
        if g_migrate_shared_fragment_path.len() > 0:
            ci_migrate_write_shared_fragment(g_migrate_shared_fragment_path)
        else:
            ci_migrate_write_shared_defs(output_dir)

    var files_expected = files_scanned
    if g_migrate_directory_one_basename.len() > 0:
        files_expected = 1
    let files_failed = files_expected - files_migrated
    ci_dump_raw_fallback_stats()
    let fn_total = g_migrate_fn_translated_total
    if files_failed > 0:
        let file_note = f" ({files_failed} file errors)"
        eprint(f"migrate: {files_migrated}/{files_scanned} files, {g_migrate_fn_translated_total}/{fn_total} functions translated{file_note}")
        return 1
    eprint(f"migrate: {files_migrated}/{files_scanned} files, {fn_total} functions translated from {input_dir} -> {output_dir}")
    // #2230: the rewrite rules applied, by function, for migrate_diff.
    let rules = ci_take_rule_sites()
    if files_migrated > 0 and with_fs_write_file(output_dir ++ "/rules.tsv", rules) != 0:
        eprint("migrate: could not write " ++ output_dir ++ "/rules.tsv")
        return 1
    if files_migrated == 0: 1 else: ci_migrate_apply_writes_clauses()

// ── `writes` clauses (§21.1 rule 1, Eric 2026-09-29) ────────────
//
// An exported function's writes of exported globals are its declared,
// checked contract: `pub fn f() -> T writes G {`, the declaration's last
// clause, and a bundle build refuses one whose body writes an exported
// global its clause omits. The migrator writes that clause for every
// exported function that writes an exported global, itself or through the
// corpus functions it calls. Whether it does is known only once the whole
// corpus is printed (a caller's file may come first), so each exported
// signature carries a marker, and ci_migrate_apply_writes_clauses replaces
// it once every file is written. The facts come from the migrator's own
// output, read with the compiler's Lexer: a write is an exported global
// (`pub var` in the output) that roots an assignment's target
// (`G = …`, `G.f[i] += …`; parser_compound_assign_op) or is taken by
// `&raw mut` — what Sema counts as a write of the forms the migrator prints;
// migrated locals and parameters are prefixed (`__local_`, `__param_`), so
// no local shadows a global. A write the scan misses is no hazard: the
// bundle build refuses the function with the literal fix-it. A
// one-file migration (migrate_one) sees only that file's callees.
var g_migrate_writes_fn_names: Vec[str] = Vec.new()
var g_migrate_writes_fn_bodies: Vec[str] = Vec.new()
var g_migrate_writes_paths: Vec[str] = Vec.new()

fn ci_migrate_writes_mark(name: &str) -> str: "@@with-writes:" ++ name ++ "@@"

fn ci_migrate_writes_reset():
    g_migrate_writes_fn_names = Vec.new()
    g_migrate_writes_fn_bodies = Vec.new()
    g_migrate_writes_paths = Vec.new()

fn ci_migrate_writes_note_path(path: &str):
    if not g_migrate_writes_paths.contains(path):
        g_migrate_writes_paths.push(with_str_clone_ref(path))

fn ci_migrate_token_text(text: &str, tokens: &TokenList, i: i32) -> str:
    text.slice(tokens.get_start(i) as i64, tokens.get_end(i) as i64)

// The token after a place's projections from `k` (`.f`, `.F`, `[…]`).
fn ci_migrate_skip_place_projections(tokens: &TokenList, k0: i32) -> i32:
    var k = k0
    let n = tokens.len()
    while k < n:
        let tag = tokens.get_tag(k)
        if tag == TokenKind.TK_DOT_IDENT:
            k = k + 1
        else if tag == TokenKind.TK_DOT and k + 1 < n and tokens.get_tag(k + 1) == TokenKind.TK_IDENT:
            k = k + 2
        else if tag == TokenKind.TK_L_BRACKET:
            var depth = 0
            while k < n:
                let t = tokens.get_tag(k)
                if t == TokenKind.TK_L_BRACKET: depth = depth + 1
                if t == TokenKind.TK_R_BRACKET:
                    depth = depth - 1
                    if depth == 0:
                        break
                k = k + 1
            k = k + 1
        else:
            break
    k

// Whether token `i` (a global's name) is taken by `&raw mut`, through
// grouping parentheses.
fn ci_migrate_taken_raw_mut(text: &str, tokens: &TokenList, i: i32) -> bool:
    var j = i - 1
    while j >= 0 and tokens.get_tag(j) == TokenKind.TK_L_PAREN:
        j = j - 1
    j >= 2 and tokens.get_tag(j) == TokenKind.TK_KW_MUT and tokens.get_tag(j - 1) == TokenKind.TK_IDENT and ci_migrate_token_text(text, tokens, j - 1) == "raw" and tokens.get_tag(j - 2) == TokenKind.TK_AMPERSAND

// Replace every exported signature's marker with its `writes` clause (or
// nothing), over every file this migration wrote. 0 on success.
fn ci_migrate_apply_writes_clauses() -> i32:
    // The exported globals: `pub var` in the output.
    var globals: HashMap[str, i32] = HashMap.new()
    for pi in 0..g_migrate_writes_paths.len() as i32:
        let text = with_fs_read_file(g_migrate_writes_paths[pi])
        var lexer = Lexer.init(text, 0)
        let tokens = lexer.tokenize()
        for i in 0..tokens.len() - 2:
            if tokens.get_tag(i) == TokenKind.TK_KW_PUB and tokens.get_tag(i + 1) == TokenKind.TK_KW_VAR and tokens.get_tag(i + 2) == TokenKind.TK_IDENT:
                globals.insert(ci_migrate_token_text(text, &tokens, i + 2), 1)
    var fn_index: HashMap[str, i32] = HashMap.new()
    for fi in 0..g_migrate_writes_fn_names.len() as i32:
        fn_index.insert(with_str_clone_ref(g_migrate_writes_fn_names[fi]), fi)
    // Each function's direct writes and corpus callees, "|a|b|" sets.
    var writes: Vec[str] = Vec.new()
    var callees: Vec[str] = Vec.new()
    for fi in 0..g_migrate_writes_fn_bodies.len() as i32:
        let body = g_migrate_writes_fn_bodies[fi]
        var lexer = Lexer.init(body, 0)
        let tokens = lexer.tokenize()
        var w = "|"
        var c = "|"
        for i in 0..tokens.len():
            if tokens.get_tag(i) != TokenKind.TK_IDENT or (i > 0 and tokens.get_tag(i - 1) == TokenKind.TK_DOT):
                continue
            let name = ci_migrate_token_text(body, &tokens, i)
            if globals.contains(name):
                let after = ci_migrate_skip_place_projections(&tokens, i + 1)
                let assigned = after < tokens.len() and (tokens.get_tag(after) == TokenKind.TK_EQ or parser_compound_assign_op(tokens.get_tag(after)) >= 0)
                if (assigned or ci_migrate_taken_raw_mut(body, &tokens, i)) and ci_find_str(w, "|" ++ name ++ "|") < 0:
                    w = w ++ name ++ "|"
            else if fn_index.contains(name) and i + 1 < tokens.len() and tokens.get_tag(i + 1) == TokenKind.TK_L_PAREN and ci_find_str(c, "|" ++ name ++ "|") < 0:
                c = c ++ name ++ "|"
        writes.push(w)
        callees.push(c)
    // Transitively: a function writes what every corpus callee writes.
    var changed = true
    while changed:
        changed = false
        for fi in 0..writes.len() as i32:
            let calls = callees[fi].split("|")
            for ci in 0..calls.len() as i32:
                if calls[ci].len() == 0 or not fn_index.contains(calls[ci]):
                    continue
                let callee_writes = writes[fn_index.get(calls[ci]).unwrap()].split("|")
                for wi in 0..callee_writes.len() as i32:
                    let g = callee_writes[wi]
                    if g.len() > 0 and ci_find_str(writes[fi], "|" ++ g ++ "|") < 0:
                        writes[fi] = writes[fi] ++ g ++ "|"
                        changed = true
    // The markers, replaced.
    for pi in 0..g_migrate_writes_paths.len() as i32:
        let path = g_migrate_writes_paths[pi]
        var text = with_fs_read_file(path)
        if ci_find_str(text, "@@with-writes:") < 0:
            continue
        for fi in 0..g_migrate_writes_fn_names.len() as i32:
            let mark = ci_migrate_writes_mark(g_migrate_writes_fn_names[fi])
            if ci_find_str(text, mark) < 0:
                continue
            // Sorted by name, so the clause is deterministic.
            let parts = writes[fi].split("|")
            var used: Vec[bool] = Vec.new()
            for wi in 0..parts.len() as i32:
                used.push(parts[wi].len() == 0)
            var clause = ""
            var printed = 0
            while true:
                var pick = -1
                for wi in 0..parts.len() as i32:
                    if not used[wi] and (pick < 0 or ci_str_compare(parts[wi], parts[pick]) < 0):
                        pick = wi
                if pick < 0:
                    break
                used[pick] = true
                clause = clause ++ (if printed == 0: " writes " else: ", ") ++ parts[pick]
                printed = printed + 1
            text = text.replace(mark, clause)
        if ci_find_str(text, "@@with-writes:") >= 0:
            eprint("migrate: " ++ path ++ ": a `writes` clause marker has no recorded function (the migrator lost a definition)")
            return 1
        if with_fs_write_file(path, text) != 0:
            eprint("migrate: failed to write " ++ path)
            return 1
    0

// Translate a function with body — key difference from ci_translate_function:
// 1. Translates ALL functions, not just static inline
// 2. Non-static functions get @[c_export]
// 3. Goto-containing functions use state-variable transform
// 4. Never silently demotes to extern or emits callable failure stubs.
fn ci_migrate_translate_function(session: i64, idx: i32, known_structs: &str, primary_path: &str, project_active: bool, project: &CiProject) -> str:
    // B9: every function gets a fresh per-function temp counter
    // so temp names are `__ci_expr_TAG_0`, `__ci_expr_TAG_1`, ...
    // rather than source-offset-keyed. The counter is cursor-
    // memoized so re-entering the same cursor returns the same id.
    ci_temp_reset()
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // The declaration walk already filters actual system declarations through
    // ci_is_system_decl and their source paths. Do not repeat a spelling-only
    // filter here: emit-C deliberately owns the reserved __with_* namespace.

    // Skip libc functions that are mapped to With equivalents
    if ci_is_mapped_libc_fn(name):
        return ""

    // #749: a system-header declaration whose name collides with the With
    // prelude (unistd's `write` against prelude `write`) must not emit an
    // extern — the same filter the c_import flow applies.
    if ci_is_system_prelude_collision_decl(session, idx, name):
        ci_record_omitted_symbol(name, "system declaration collides with With prelude")
        return ""

    // Skip already-emitted names
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    let storage = with_cimport_fn_storage_class(session, idx)
    let safe_name = ci_migrate_c_function_name(name)
    let param_count = with_cimport_fn_param_count(session, idx)
    let is_variadic = with_cimport_fn_is_variadic(session, idx)

    // Build parameter list — use cursor API for real param names
    // (the old decl API returns "" for many PCRE2 functions)
    var cursor_param_names = ""
    var fn_body_cursor = -1
    let fn_cursor = ci_find_fn_cursor(session, name)
    if fn_cursor >= 0:
        // Find the CompoundStmt body for param mutation detection
        let fnc = with_ci_num_children(session, fn_cursor)
        var fci = 0
        while fci < fnc:
            if with_ci_cursor_kind(session, with_ci_child(session, fn_cursor, fci)) == CXK_COMPOUND_STMT:
                fn_body_cursor = with_ci_child(session, fn_cursor, fci)
                break
            fci = fci + 1
        let fn_nc = with_ci_num_children(session, fn_cursor)
        var cpi = 0
        while cpi < fn_nc:
            let child = with_ci_child(session, fn_cursor, cpi)
            if with_ci_cursor_kind(session, child) == 10:  // CXCursor_ParmDecl
                let cpname = with_ci_cursor_spelling(session, child)
                cursor_param_names = cursor_param_names ++ "|" ++ cpname ++ "|"
            cpi = cpi + 1

    // §13.5b: setjmp/longjmp are unsupported for migration. Reject the
    // whole function loudly before any body translation — never emit a
    // placeholder, extern fallback, TODO, or partial output for it.
    if fn_body_cursor >= 0:
        let sj_cursor = ci_find_setjmp_longjmp_call(session, fn_body_cursor)
        if sj_cursor >= 0:
            let sj_name = ci_call_callee_name(session, sj_cursor)
            let sj_loc = with_ci_cursor_location(session, sj_cursor)
            let loc_suffix = if sj_loc.len() > 0: " at " ++ sj_loc else: ""
            let msg = f"migrate: untranslatable function '{name}': setjmp/longjmp (call to '{sj_name}') is not supported{loc_suffix}"
            return ci_migrate_fail_function(msg)
    var params = ""
    var has_unsupported = false
    var unsupported_reason = ""

    for pi in 0..param_count:
        if pi > 0:
            params = params ++ ", "
        let raw_ptype = ci_migrated_param_type(session, idx, pi)   // D107: the corpus verdict
        var ptype = ci_pointer_type_explicit_mut(raw_ptype)

        if ci_starts_with(ptype, "__UNSUPPORTED:"):
            has_unsupported = true
            unsupported_reason = ptype.slice(14, ptype.len())

        // Definition param names are authoritative: the translated body
        // references the DEFINITION's spellings, and a -include'd prototype
        // may name the same params differently — naming the signature from
        // the registry cursor then skews it against every body reference
        // (#740 census: `__param_c` signature vs `__param__1` body).
        var pname = ci_get_nth_pipe_entry(cursor_param_names, pi)
        if pname.len() == 0:
            pname = with_cimport_fn_param_name(session, idx, pi)
        let escaped_pname = if pname.len() > 0: ci_escape_reserved(pname) else: ""
        let sig_pname = ci_param_signature_name(escaped_pname, pi)
        params = params ++ sig_pname ++ ": " ++ ci_unsafe_fn_ptr_type(ptype)

    if is_variadic != 0:
        if param_count > 0:
            params = params ++ ", ..."
        else:
            params = params ++ "..."

    var ret = ci_pointer_type_explicit_mut(with_cimport_fn_return_type_translated(session, idx))
    if with_cimport_fn_is_noreturn(session, idx) != 0:
        ret = "Never"
    if ci_starts_with(ret, "__UNSUPPORTED:"):
        has_unsupported = true
        unsupported_reason = ret.slice(14, ret.len())

    // Unsupported types make the whole migration fail; partial output lies.
    if has_unsupported:
        let fn_loc = if fn_cursor >= 0: with_ci_cursor_location(session, fn_cursor) else: ""
        let loc_suffix = if fn_loc.len() > 0: " at " ++ fn_loc else: ""
        return ci_migrate_fail_function(f"migrate: untranslatable function '{name}': unsupported type ({unsupported_reason}){loc_suffix}")

    if fn_cursor < 0 or with_ci_cursor_is_definition(session, fn_cursor) == 0:
        if storage == CX_SC_STATIC:
            return ""
        // #740 census class 2: the migrate preamble already declares the fixed
        // with_* runtime externs (with_memcpy & co, *mut u8-shaped). Re-emitting a
        // C prototype for the same symbol under its C spelling (`void*` →
        // *mut c_void) leaves one flat extern name with two signatures and
        // every preamble-shaped call mismatched. Prototype-only redeclarations
        // skip; definitions still translate (and collide loudly).
        if ci_migrate_preamble_declares_runtime_extern(name):
            return ""
        // #1848: a declaration without a prototype (the fact #1831's
        // with_cimport_fn_is_unprototyped states). Migrated source is
        // ordinary With, which has no spelling for an unprototyped call, and
        // `(...)` is the variadic convention — wrong. C passes each call's
        // promoted arguments with the fixed-argument convention, so the
        // declaration is the prototype every call in the unit agrees on.
        if with_cimport_fn_is_unprototyped(session, idx) != 0:
            let shape = ci_migrate_unprototyped_call_shape(session, name)
            if shape.starts_with("!"):
                return ci_migrate_fail_function(f"migrate: '{name}' is declared without a prototype and {shape.slice(1, shape.len())}, so no prototype describes its calls; declare it with its parameters (C11 6.5.2.2p6)")
            if shape.len() == 0:
                return ""
            params = ci_migrate_unprototyped_params(shape)
        let owner_path = ci_migrate_project_fn_owner_path(project_active, project, name)
        if ci_migrate_shared_defs_active() and g_migrate_no_c_export != 0 and owner_path.len() > 0:
            return ""
        with_cimport_mark_name_emitted(name)
        g_migrate_fn_translated = g_migrate_fn_translated + 1
        let cc = with_cimport_fn_calling_conv(session, idx)
        let cc_prefix = if cc != "c" and cc.len() > 0: "@[callconv(\"" ++ cc ++ "\")]\n" else: ""
        let ret_render = ci_unsafe_fn_ptr_type(ret)
        // A renamed extern (keyword or prelude collision) keeps its C
        // linkage through the original symbol.
        let link_prefix = if safe_name != name: "@[link_name(\"" ++ name ++ "\")]\n" else: ""
        return link_prefix ++ cc_prefix ++ "extern fn " ++ safe_name ++ "(" ++ params ++ ")" ++ ci_ret_suffix(ret_render) ++ "\n"

    // A header's `static inline` definition is published once, by the unit
    // that owns the header (the project scan's header_owner_module); every
    // other unit imports it instead of keeping a private copy.
    let header_owner = if storage == CX_SC_STATIC and with_cimport_fn_is_inline(session, idx) != 0: ci_migrate_project_fn_owner_path(project_active, project, name) else: ""
    if header_owner.len() > 0 and header_owner != g_migrate_current_input_path:
        return ""

    // @[c_export] for non-static functions (preserves C ABI)
    let export_prefix = if (g_migrate_no_c_export != 0 and g_migrate_export_function_defs == 0) or storage == CX_SC_STATIC: "" else: "@[c_export(\"" ++ name ++ "\")]\n"

    // Try to translate the function body. Unsafe migrated functions already
    // provide the required unsafe context for extern/runtime calls, so the
    // expression lowerer should not wrap those calls in nested unsafe blocks.
    let body_is_unsafe_context = ci_migrate_extern_fn_call_requires_unsafe(safe_name)
    ci_migrate_set_unsafe_function_body_context(body_is_unsafe_context)
    let body = ci_try_translate_fn_body(session, idx)
    let body_tail_unit = ci_take_body_tail_unit()
    ci_migrate_set_unsafe_function_body_context(false)
    // #1878: the declarations the body's locals need, beside the function.
    let hoisted_decls = ci_take_body_hoisted_decls()
    // A genuinely empty C body ({}) translates to the empty string — that is a
    // successful translation of a no-op function (common: feature-gated stubs
    // such as zlib's tr_static_init once STDC selects the precomputed tables),
    // not a translation failure. Detect it via the body compound having no
    // statements and emit an empty `return` body (handled by body_for_emit).
    let empty_c_body = ret == "Unit" and fn_body_cursor >= 0 and with_ci_num_children(session, fn_body_cursor) == 0
    let unrendered = ci_print_take_unknowns()
    if unrendered.len() > 0:
        let where_loc = if fn_cursor >= 0: with_ci_cursor_location(session, fn_cursor) else: ""
        let where_suffix = if where_loc.len() > 0: " at " ++ where_loc else: ""
        return ci_migrate_fail_function(f"migrate: untranslatable function '{name}': no rendering for {unrendered[0]}{where_suffix}")
    if body.len() > 0 or empty_c_body:
        with_cimport_mark_name_emitted(name)
        g_migrate_fn_translated = g_migrate_fn_translated + 1
        let ret_render = ci_unsafe_fn_ptr_type(ret)
        // A blank body is emitted as `return`, whose tail is Unit.
        let ret_suffix = ci_def_ret_suffix(ret_render, body_tail_unit or ci_migrate_text_is_blank(body))
        let body_for_emit = if ret == "Unit" and ci_migrate_text_is_blank(body): "    return\n" else: body
        let visibility = if g_migrate_no_c_export != 0 and (storage != CX_SC_STATIC or header_owner.len() > 0): "pub " else: ""
        let fn_keyword = visibility ++ if ci_migrate_extern_fn_call_requires_unsafe(safe_name): "unsafe fn " else: "fn "
        // §21.1 rule 1: every function is recorded for the transitive write
        // scan; an exported one's `writes` clause, its last clause, is
        // filled in once the whole corpus is printed
        // (ci_migrate_apply_writes_clauses).
        g_migrate_writes_fn_names.push(with_str_clone_ref(safe_name))
        g_migrate_writes_fn_bodies.push(with_str_clone_ref(body_for_emit))
        let writes_mark = if visibility.len() > 0: ci_migrate_writes_mark(safe_name) else: ""
        if migrate_prefer_brace():
            return hoisted_decls ++ export_prefix ++ fn_keyword ++ safe_name ++ "(" ++ params ++ ")" ++ ret_suffix ++ writes_mark ++ " {\n" ++ body_for_emit ++ "}\n\n"
        return hoisted_decls ++ export_prefix ++ fn_keyword ++ safe_name ++ "(" ++ params ++ ")" ++ ret_suffix ++ writes_mark ++ ":\n" ++ body_for_emit ++ "\n"

    // Any body translation failure is fatal. Never emit partial output that
    // merely comments out the source function.
    if fn_cursor >= 0 and ci_str_contains(with_ci_cursor_source_text(session, fn_cursor), "goto *"):
        let bail_loc0 = ci_get_bail_location()
        let fn_loc0 = with_ci_cursor_location(session, fn_cursor)
        let loc0 = if bail_loc0.len() > 0: bail_loc0 else: fn_loc0
        let loc_suffix0 = if loc0.len() > 0: " at " ++ loc0 else: ""
        let msg0 = f"migrate: untranslatable function '{name}': computed goto is not supported{loc_suffix0}"
        return ci_migrate_fail_function(msg0)

    let loud_bail = ci_get_bail_message()
    if loud_bail.len() > 0:
        let bail_loc = ci_get_bail_location()
        let loc_suffix = if bail_loc.len() > 0: " at " ++ bail_loc else: ""
        let msg = f"migrate: untranslatable function '{name}': {loud_bail}{loc_suffix}"
        return ci_migrate_fail_function(msg)

    let bail_loc = ci_get_bail_location()
    let bail_k = ci_get_bail_kind()
    let fn_loc = if fn_cursor >= 0: with_ci_cursor_location(session, fn_cursor) else: ""
    // reason first: the loc conditional MOVES bail_loc (blank-on-move), so
    // any later len() check would always take the generic branch.
    let reason = if bail_loc.len() > 0: "bailed at " ++ ci_cursor_kind_name(bail_k) else: "body translation failed"
    let loc = if bail_loc.len() > 0: bail_loc else: fn_loc
    let loc_suffix = if loc.len() > 0: " at " ++ loc else: ""
    ci_migrate_fail_function(f"migrate: untranslatable function '{name}': {reason}{loc_suffix}")


// ── ci_migrate_var_* helpers (moved from CImport.w in D3) ─────
pub fn ci_migrate_set_error(msg: &str):
    if g_migrate_file_error.len() == 0:
        g_migrate_file_error = with_str_clone_ref(msg)

fn ci_migrate_fail_function(msg: &str) -> str:
    eprint(with_str_clone_ref(msg))
    ci_migrate_set_error(msg)
    ""

fn ci_migrate_var_definition_kind(session: i64, idx: i32) -> i32:
    with_cimport_var_definition_kind(session, idx)

fn ci_migrate_var_is_definition(session: i64, idx: i32) -> bool:
    ci_migrate_var_definition_kind(session, idx) != CI_VAR_DECL_ONLY

fn ci_migrate_project_var_symbol(project_active: bool, project: &CiProject, name: &str) -> i32:
    if not project_active or name.len() == 0:
        return -1
    project.find_symbol(CiProjectSymbolKind.CIPS_VAR, name)

fn ci_migrate_project_var_owner_path(project_active: bool, project: &CiProject, name: &str) -> str:
    let symbol_id = ci_migrate_project_var_symbol(project_active, project, name)
    if symbol_id < 0:
        return ""
    project.owner_module_path(symbol_id)

fn ci_migrate_project_var_resolved_type(project_active: bool, project: &CiProject, name: &str) -> str:
    let symbol_id = ci_migrate_project_var_symbol(project_active, project, name)
    if symbol_id < 0:
        return ""
    let symbol = project.symbols[symbol_id]
    if symbol.resolved_ty_text.len() > 0:
        return symbol.resolved_ty_text.clone()
    if (symbol.resolved_ty as i32) != 0:
        return ci_print_type(project.types, symbol.resolved_ty)
    ""

fn ci_migrate_project_fn_symbol(project_active: bool, project: &CiProject, name: &str) -> i32:
    if not project_active or name.len() == 0:
        return -1
    project.find_symbol(CiProjectSymbolKind.CIPS_FN, name)

fn ci_migrate_project_fn_owner_path(project_active: bool, project: &CiProject, name: &str) -> str:
    let symbol_id = ci_migrate_project_fn_symbol(project_active, project, name)
    if symbol_id < 0:
        return ""
    project.owner_module_path(symbol_id)

fn ci_migrate_collect_unsafe_extern_fns(session: i64, count: i32, primary_path: &str, project_active: bool, project: &CiProject):
    ci_migrate_reset_unsafe_extern_fns()
    var i = 0
    while i < count:
        if with_cimport_decl_kind(session, i) != CK_FUNCTION:
            i = i + 1
            continue
        let name = with_cimport_decl_name(session, i)
        if ci_migrate_decl_is_filtered(session, i, name):
            i = i + 1
            continue
        let owner_path = ci_migrate_project_fn_owner_path(project_active, project, name)
        let local_def = ci_find_fn_cursor(session, name)
        if local_def >= 0 and (owner_path.len() == 0 or owner_path == primary_path) and ci_migrate_fn_is_unsafe_to_call(session, i):
            ci_migrate_note_unsafe_extern_fn(ci_migrate_c_function_name(name))
        // A static function stays local unless it is a header's inline
        // definition another unit publishes (owner_path): then its calls
        // here need the same unsafe context as any imported raw function.
        if with_cimport_fn_storage_class(session, i) == CX_SC_STATIC and owner_path.len() == 0:
            i = i + 1
            continue
        if (owner_path.len() > 0 and owner_path != primary_path) and ci_migrate_fn_is_unsafe_to_call(session, i):
            ci_migrate_note_unsafe_extern_fn(ci_migrate_c_function_name(name))
        if owner_path.len() == 0 and local_def < 0:
            ci_migrate_note_unsafe_extern_fn(ci_migrate_c_function_name(name))
        i = i + 1
    return

fn ci_migrate_var_emits_definition(session: i64, idx: i32, primary_path: &str, project_active: bool, project: &CiProject) -> bool:
    if ci_migrate_var_definition_kind(session, idx) == CI_VAR_DECL_ONLY:
        return false
    if project_active and with_cimport_var_storage_class(session, idx) != CX_SC_STATIC:
        let name = with_cimport_decl_name(session, idx)
        let owner_path = ci_migrate_project_var_owner_path(project_active, project, name)
        if owner_path.len() > 0:
            return owner_path == primary_path
    true

fn ci_migrate_var_in_primary_file(session: i64, idx: i32, primary_path: &str) -> bool:
    if primary_path.len() == 0:
        return false
    let cursor = with_cimport_decl_cursor(session, idx)
    if cursor < 0:
        return false
    with_ci_cursor_in_file(session, cursor, primary_path) != 0

fn ci_migrate_var_priority(session: i64, idx: i32, primary_path: &str) -> i32:
    let kind = ci_migrate_var_definition_kind(session, idx)
    if kind == CI_VAR_FULL_DEF:
        if ci_migrate_var_in_primary_file(session, idx, primary_path):
            return 6
        return 5
    if kind == CI_VAR_TENTATIVE_DEF:
        if ci_migrate_var_in_primary_file(session, idx, primary_path):
            return 4
        return 3
    if ci_migrate_var_in_primary_file(session, idx, primary_path):
        return 2
    1

fn ci_migrate_find_best_var_decl(session: i64, count: i32, name: &str, primary_path: &str) -> i32:
    var best = -1
    var best_priority = -1
    var i = 0
    while i < count:
        if with_cimport_decl_kind(session, i) == CK_VAR and with_cimport_decl_name(session, i) == name:
            let priority = ci_migrate_var_priority(session, i, primary_path)
            if priority > best_priority:
                best = i
                best_priority = priority
        i = i + 1
    best

fn ci_migrate_var_owner_type(session: i64, idx: i32) -> str:
    var actual_type = with_cimport_var_storage_type_translated(session, idx)
    if actual_type.len() == 0:
        return ci_unsafe_fn_ptr_type(with_cimport_var_type_translated(session, idx))
    if ci_starts_with(actual_type, "[0]"):
        let cursor = with_cimport_decl_cursor(session, idx)
        if cursor >= 0:
            let init_cursor = with_ci_var_initializer(session, cursor)
            if init_cursor >= 0:
                let init_type = with_ci_type_translated(session, with_ci_cursor_type(session, init_cursor))
                if init_type.len() > 0 and init_type[0] == 91:
                    let actual_elem = ci_array_elem_type(actual_type)
                    let init_elem = ci_array_elem_type(init_type)
                    if actual_elem.len() > 0 and actual_elem == init_elem:
                        actual_type = init_type
    ci_unsafe_fn_ptr_type(actual_type)

fn ci_migrate_var_resolved_type(session: i64, idx: i32, count: i32, primary_path: &str, project_active: bool, project: &CiProject) -> str:
    let name = with_cimport_decl_name(session, idx)
    if with_cimport_var_storage_class(session, idx) != CX_SC_STATIC:
        let shared_type = ci_migrate_project_var_resolved_type(project_active, project, name)
        if shared_type.len() > 0:
            return shared_type
    let best = ci_migrate_find_best_var_decl(session, count, name, primary_path)
    if best >= 0 and ci_migrate_var_definition_kind(session, best) != CI_VAR_DECL_ONLY:
        let owner_type = ci_migrate_var_owner_type(session, best)
        if owner_type.len() > 0:
            return owner_type
    let decl_type = with_cimport_var_type_translated(session, idx)
    if decl_type.len() > 0:
        return ci_unsafe_fn_ptr_type(decl_type)
    ci_migrate_var_owner_type(session, idx)

// ── ci_migrate_translate_var/s (moved from CImport.w in D3) ─────
fn ci_migrate_translate_var(session: i64, idx: i32, count: i32, primary_path: &str, want_definitions: bool, project_active: bool, project: &CiProject) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // The declaration walk already filters actual system declarations through
    // ci_is_system_decl and their source paths. Do not repeat a spelling-only
    // filter here: emit-C deliberately owns the reserved __with_* namespace.

    if ci_migrate_find_best_var_decl(session, count, name, primary_path) != idx:
        return ""

    let resolved_type = ci_migrate_var_resolved_type(session, idx, count, primary_path, project_active, project)
    if resolved_type.len() == 0:
        return ""
    if ci_starts_with(resolved_type, "__UNSUPPORTED:"):
        let cursor = with_cimport_decl_cursor(session, idx)
        let loc = if cursor >= 0: with_ci_cursor_location(session, cursor) else: ""
        ci_migrate_set_error("migrate: unsupported global variable type for " ++ name ++ if loc.len() > 0: " at " ++ loc else: "")
        return ""

    let definition_kind = ci_migrate_var_definition_kind(session, idx)
    let emits_definition = ci_migrate_var_emits_definition(session, idx, primary_path, project_active, project)
    let is_static = with_cimport_var_storage_class(session, idx) == CX_SC_STATIC
    let already_emitted = with_cimport_is_name_emitted(name) != 0
    if already_emitted:
        if ci_migrate_shared_defs_active() and not is_static and not want_definitions and not emits_definition:
            let owner_path = ci_migrate_project_var_owner_path(project_active, project, name)
            if owner_path.len() == 0:
                let is_const = with_cimport_var_is_const(session, idx)
                let is_threadlocal = with_cimport_var_is_threadlocal(session, idx)
                let safe_name = ci_escape_reserved(name)
                let tl_attr = if is_threadlocal != 0: "@[threadlocal]\n" else: ""
                if is_const != 0:
                    let rendered = tl_attr ++ "extern let " ++ safe_name ++ ": " ++ resolved_type ++ "\n"
                    let _ = ci_migrate_shared_ownerless_extern_add("extern_let", safe_name, rendered)
                else:
                    let rendered = tl_attr ++ "extern var " ++ safe_name ++ ": " ++ resolved_type ++ "\n"
                    let _ = ci_migrate_shared_ownerless_extern_add("extern_var", safe_name, rendered)
        return ""
    if want_definitions and not emits_definition:
        return ""
    if not want_definitions and emits_definition:
        return ""

    let is_const = with_cimport_var_is_const(session, idx)
    let is_threadlocal = with_cimport_var_is_threadlocal(session, idx)
    let safe_name = ci_escape_reserved(name)
    let tl_attr = if is_threadlocal != 0: "@[threadlocal]\n" else: ""
    let cursor = with_cimport_decl_cursor(session, idx)

    with_cimport_mark_name_emitted(name)

    if emits_definition:
        var rendered = ""
        if definition_kind == CI_VAR_FULL_DEF:
            let init_val = ci_try_eval_var_init_for_type(session, idx, resolved_type)
            if init_val.len() == 0:
                let loc = if cursor >= 0: with_ci_cursor_location(session, cursor) else: ""
                ci_migrate_set_error("migrate: untranslatable global initializer for " ++ name ++ if loc.len() > 0: " at " ++ loc else: "")
                return ""
            if is_const != 0:
                rendered = tl_attr ++ "let " ++ safe_name ++ ": " ++ resolved_type ++ " = " ++ init_val ++ "\n"
            else:
                rendered = tl_attr ++ "var " ++ safe_name ++ ": " ++ resolved_type ++ " = " ++ init_val ++ "\n"
        else:
            // Tentative definitions own storage in C and are zero-initialized.
            let default_val = ci_default_for_type(resolved_type)
            if is_const != 0:
                if default_val.len() == 0:
                    let loc = if cursor >= 0: with_ci_cursor_location(session, cursor) else: ""
                    ci_migrate_set_error("migrate: no default initializer for tentative const global " ++ name ++ if loc.len() > 0: " at " ++ loc else: "")
                    return ""
                rendered = tl_attr ++ "let " ++ safe_name ++ ": " ++ resolved_type ++ " = " ++ default_val ++ "\n"
            else if default_val.len() > 0:
                rendered = tl_attr ++ "var " ++ safe_name ++ ": " ++ resolved_type ++ " = " ++ default_val ++ "\n"
            else:
                rendered = tl_attr ++ "var " ++ safe_name ++ ": " ++ resolved_type ++ "\n"
        let kind = if is_const != 0: "let" else: "var"
        if not is_static:
            if ci_migrate_shared_decl_add(kind, safe_name, rendered):
                return ""
        return rendered

    var shared_ownerless_extern = false
    if ci_migrate_shared_defs_active() and not is_static:
        let owner_path = ci_migrate_project_var_owner_path(project_active, project, name)
        if owner_path.len() > 0:
            return ""
        shared_ownerless_extern = true
    if is_const != 0:
        let rendered = tl_attr ++ "extern let " ++ safe_name ++ ": " ++ resolved_type ++ "\n"
        if shared_ownerless_extern:
            if ci_migrate_shared_ownerless_extern_add("extern_let", safe_name, rendered):
                return ""
        if not is_static:
            if ci_migrate_shared_decl_add("extern_let", safe_name, rendered):
                return ""
        return rendered
    let rendered = tl_attr ++ "extern var " ++ safe_name ++ ": " ++ resolved_type ++ "\n"
    if shared_ownerless_extern:
        if ci_migrate_shared_ownerless_extern_add("extern_var", safe_name, rendered):
            return ""
    if not is_static:
        if ci_migrate_shared_decl_add("extern_var", safe_name, rendered):
            return ""
    rendered

fn ci_migrate_translate_vars(session: i64, count: i32, primary_path: &str, project_active: bool, project: &CiProject) -> str:
    var output = StringBuilder.new()
    var i = 0
    while i < count:
        if with_cimport_decl_kind(session, i) == CK_VAR:
            let name = with_cimport_decl_name(session, i)
            if not ci_migrate_is_width_family_name(name):
                let cursor = with_cimport_decl_cursor(session, i)
                let loc = if cursor >= 0: with_ci_cursor_location(session, cursor) else: ""
                if not ci_is_system_decl(name) and not (loc.len() > 0 and ci_is_system_path(loc)):
                    output.push_str(ci_migrate_translate_var(session, i, count, primary_path, true, project_active, project))
        i = i + 1
    i = 0
    while i < count:
        if with_cimport_decl_kind(session, i) == CK_VAR:
            let name = with_cimport_decl_name(session, i)
            if not ci_migrate_is_width_family_name(name):
                let cursor = with_cimport_decl_cursor(session, i)
                let loc = if cursor >= 0: with_ci_cursor_location(session, cursor) else: ""
                if not ci_is_system_decl(name) and not (loc.len() > 0 and ci_is_system_path(loc)):
                    output.push_str(ci_migrate_translate_var(session, i, count, primary_path, false, project_active, project))
        i = i + 1
    output.to_str()

// ── Migrate-only globals and setters (moved from CImport.w in D3) ─────

// Module-level defines to prepend to migrated C source.
// Set via migrate_add_define() before calling migrate_c_file().
var g_migrate_defines: str = ""
var g_migrate_file_error: str = ""

// When true, skip @[c_export] attributes and extern fn declarations
// for functions defined in the same translation unit.
// Set via migrate_set_no_c_export().
pub var g_migrate_no_c_export: i32 = 0

pub fn migrate_set_no_c_export(val: i32):
    g_migrate_no_c_export = val

// When true, the output compiles without the prelude (a .wo bundle corpus,
// or `with migrate --no-prelude`): the preamble carries the prelude-only
// vocabulary (c_void, the unreachable shim). Set from the migrate
// workspace's prelude_mode (ComptimeEval) or the CLI flag.
var g_migrate_prelude_free: i32 = 0

pub fn migrate_set_prelude_free(val: i32) -> Unit:
    g_migrate_prelude_free = val

// Keep local-definition behavior for globals while preserving C ABI symbols
// for translated function definitions. Used by promoted migrated libraries
// that are compiled as std modules but still expose C-compatible entrypoints.
var g_migrate_export_function_defs: i32 = 0

pub fn migrate_set_export_function_defs(val: i32):
    g_migrate_export_function_defs = val

// Block style preference for migrated output.
// 0 = colon-form (default), 2 = brace-form (--prefer-brace).
var g_migrate_block_style: i32 = 0

pub fn migrate_set_block_style(val: i32):
    g_migrate_block_style = val

pub fn migrate_prefer_brace() -> bool:
    g_migrate_block_style == 2

var g_migrate_convert_goto_to_structured: i32 = 0

pub fn migrate_set_convert_goto_to_structured(val: i32):
    g_migrate_convert_goto_to_structured = val

pub fn migrate_convert_goto_to_structured() -> bool:
    g_migrate_convert_goto_to_structured != 0

// Per-file and cumulative counters for translated functions.
var g_migrate_fn_translated: i32 = 0
var g_migrate_fn_translated_total: i32 = 0

fn ci_migrate_reset_fn_counts(): g_migrate_fn_translated = 0

fn ci_cursor_kind_name(kind: i32) -> str:
    if kind == 2: return "StructDecl"
    if kind == 3: return "UnionDecl"
    if kind == 4: return "ClassDecl"
    if kind == 103: return "CallExpr"
    if kind == 114: return "BinaryOperator"
    if kind == 117: return "CStyleCastExpr"
    if kind == 201: return "LabelStmt"
    if kind == 202: return "CompoundStmt"
    if kind == 203: return "CaseStmt"
    if kind == 204: return "DefaultStmt"
    if kind == 205: return "IfStmt"
    if kind == 206: return "SwitchStmt"
    if kind == 207: return "WhileStmt"
    if kind == 208: return "DoStmt"
    if kind == 209: return "ForStmt"
    if kind == 210: return "GotoStmt"
    if kind == 212: return "ContinueStmt"
    if kind == 213: return "BreakStmt"
    if kind == 214: return "ReturnStmt"
    if kind == 215: return "GCCAsmStmt"
    if kind == 230: return "NullStmt"
    if kind == 231: return "DeclStmt"
    f"kind={kind}"
