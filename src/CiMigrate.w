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
fn ci_migrate_is_width_family_name(name: str) -> bool:
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
    if len >= 3 and name.byte_at((len - 3) as i64) == 95:
        let d1 = name.byte_at((len - 2) as i64)
        let d2 = name.byte_at((len - 1) as i64)
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
var g_migrate_shared_decl_buf: str = ""
var g_migrate_shared_decl_keys: str = ""

type CiMigratePendingSharedExternVar {
    kind: str = "",
    name: str = "",
    rendered: str = "",
}

var g_migrate_shared_pending_extern_vars: Vec[CiMigratePendingSharedExternVar] = Vec.new()
var g_migrate_shared_usage_text: str = ""
var g_migrate_libc_symbols_used: str = ""

pub fn migrate_set_shared_defs(prefix: str):
    g_migrate_shared_defs_prefix = prefix

fn ci_migrate_shared_defs_active() -> bool:
    g_migrate_shared_defs_prefix.len() > 0

fn ci_migrate_shared_defs_reset:
    g_migrate_shared_decl_buf = ""
    g_migrate_shared_decl_keys = ""
    g_migrate_shared_pending_extern_vars = Vec.new()
    g_migrate_shared_usage_text = ""

fn ci_migrate_shared_decl_key(kind: str, name: str) -> str:
    "|" ++ kind ++ ":" ++ name ++ "|"

// Single dedup entry point for every declaration kind that the migrator
// emits into a shared buffer. `kind` is a short disambiguating prefix
// ("let", "type", "fn", "extern_fn", "extern_var", "extern_let");
// `name` is the declaration's identifier; `rendered` is the exact With
// source line(s) to emit on first sighting. Returns true if the
// declaration was redirected to the shared buffer (caller must skip
// per-file emit). Returns false when shared-defs mode is off OR when
// the declaration was already seen (caller's per-file emit is a no-op).
fn ci_migrate_shared_decl_add(kind: str, name: str, rendered: str) -> bool:
    if not ci_migrate_shared_defs_active():
        return false
    let key = ci_migrate_shared_decl_key(kind, name)
    if ci_find_str(g_migrate_shared_decl_keys, key) >= 0:
        return true
    g_migrate_shared_decl_keys = g_migrate_shared_decl_keys ++ key
    g_migrate_shared_decl_buf = g_migrate_shared_decl_buf ++ rendered ++ "\n"
    true

fn ci_migrate_shared_ownerless_extern_add(kind: str, name: str, rendered: str) -> bool:
    if not ci_migrate_shared_defs_active():
        return false
    let key = ci_migrate_shared_decl_key(kind, name)
    if ci_find_str(g_migrate_shared_decl_keys, key) >= 0:
        return true
    g_migrate_shared_decl_keys = g_migrate_shared_decl_keys ++ key
    g_migrate_shared_pending_extern_vars.push(CiMigratePendingSharedExternVar { kind: kind, name: name, rendered: rendered })
    true

fn ci_migrate_text_mentions_ident(text: str, name: str) -> bool:
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
        let before_ok = pos == 0 or not ci_is_ident_char(text.byte_at(pos - 1))
        let after_pos = pos + nlen
        let after_ok = after_pos >= tlen or not ci_is_ident_char(text.byte_at(after_pos))
        if before_ok and after_ok:
            return true
        start = pos + 1
    false

fn ci_migrate_shared_note_output_uses(output: str):
    if not ci_migrate_shared_defs_active():
        return
    g_migrate_shared_usage_text = g_migrate_shared_usage_text ++ "\n" ++ output

fn ci_migrate_libc_reset:
    g_migrate_libc_symbols_used = ""
    return

fn ci_migrate_note_libc_symbol(name: str):
    if name.len() == 0:
        return
    let key = "|" ++ name ++ "|"
    if ci_find_str(g_migrate_libc_symbols_used, key) < 0:
        g_migrate_libc_symbols_used = g_migrate_libc_symbols_used ++ key
    return

fn ci_migrate_needs_libc -> bool:
    g_migrate_libc_symbols_used.len() > 0

fn ci_migrate_insert_libc_use(output: str) -> str:
    if not ci_migrate_needs_libc():
        return output
    if ci_find_str(output, "\nuse std.libc\n") >= 0:
        return output
    let header_end = ci_find_str(output, "\n\n")
    if header_end >= 0:
        output.slice(0, header_end as i64) ++ "\nuse std.libc" ++ output.slice(header_end as i64, output.len())
    else:
        "use std.libc\n\n" ++ output

// Replace all occurrences of needle with replacement, assuming few matches.
// Unlike ci_str_replace (O(n²) char-by-char concatenation), this is O(n * k)
// where k = number of matches, suitable for large outputs with sparse matches.
fn ci_replace_sparse(text: str, needle: str, replacement: str) -> str:
    if needle.len() == 0 or needle.len() > text.len():
        return text
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

fn ci_comment_prefix_lines(text: str) -> str:
    var result = ""
    var start: i64 = 0
    let tlen = text.len()
    while start < tlen:
        var end = start
        while end < tlen and text.byte_at(end) != 10:
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

fn ci_migrate_normalize_output(text: str) -> str:
    if text.len() == 0:
        return ""
    var end = text.len()
    while end > 0 and text.byte_at(end - 1) == 10:
        end = end - 1
    text.slice(0, end) ++ "\n"

fn ci_migrate_render_stub(name: str, safe_name: str, params: str, ret: str, source_file: str, fn_cursor: i32, session: i64, bail_loc: str, bail_kind_name: str) -> str:
    let ret_suffix = if ret == "void" or ret.len() == 0: "" else: " -> " ++ ret
    var comment = "// [MIGRATOR_UNTRANSLATED]\n"
    if source_file.len() > 0 and fn_cursor >= 0:
        let fn_loc = with_ci_cursor_location(session, fn_cursor)
        if fn_loc.len() > 0:
            comment = comment ++ "// Source: " ++ fn_loc ++ "\n"
    if bail_loc.len() > 0:
        comment = comment ++ "// Bail: " ++ bail_kind_name ++ " at " ++ bail_loc ++ "\n"
    else if bail_kind_name.len() > 0 and bail_kind_name != "unknown":
        comment = comment ++ "// Reason: " ++ bail_kind_name ++ "\n"
    if fn_cursor >= 0:
        let c_source = with_ci_cursor_source_text(session, fn_cursor)
        if c_source.len() > 0:
            comment = comment ++ "//\n// Original C:\n"
            comment = comment ++ ci_comment_prefix_lines(c_source)
    let body_line = "    comptime_error(\"migrator: untranslatable function '" ++ name ++ "'\")\n"
    if migrate_prefer_brace():
        comment ++ "fn " ++ safe_name ++ "(" ++ params ++ ")" ++ ret_suffix ++ " {\n" ++ body_line ++ "}\n\n"
    else:
        comment ++ "fn " ++ safe_name ++ "(" ++ params ++ ")" ++ ret_suffix ++ ":\n" ++ body_line ++ "\n"

fn ci_migrate_render_preamble_fn(signature: str, colon_expr: str, brace_expr: str) -> str:
    if migrate_prefer_brace():
        return signature ++ " {\n    " ++ brace_expr ++ "\n}\n"
    signature ++ ": " ++ colon_expr ++ "\n"

// Write the shared defs module (defs.w) to output_dir.
// Contains: preamble + hardcoded extras + shared declarations.
fn ci_migrate_write_shared_defs(output_dir: str):
    var defs = "// " ++ g_migrate_shared_defs_prefix ++ " — shared definitions for migrated PCRE2\n\n"
    defs = defs ++ ci_migrate_preamble_text()
    // Hardcoded extras from pcre2_internal.h
    defs = defs ++ "// PCRE2 string constants (from pcre2_internal.h macros)\n"
    defs = defs ++ "let STRING_MARK: *const u8 = \"MARK\"\n"
    defs = defs ++ "let STRING_DEFINE: *const u8 = \"DEFINE\"\n"
    defs = defs ++ "let STRING_VERSION: *const u8 = \"VERSION\"\n"
    defs = defs ++ "let STRING_WEIRD_STARTWORD: *const u8 = \"[:<:]]\"\n"
    defs = defs ++ "let STRING_WEIRD_ENDWORD: *const u8 = \"[:>:]]\"\n"
    // Shared declarations collected during migration.
    if g_migrate_shared_decl_buf.len() > 0:
        defs = defs ++ "\n" ++ g_migrate_shared_decl_buf
    var pending_i = 0
    while pending_i < g_migrate_shared_pending_extern_vars.len() as i32:
        let pending = g_migrate_shared_pending_extern_vars.get(pending_i as i64)
        if ci_migrate_text_mentions_ident(g_migrate_shared_usage_text, pending.name):
            defs = defs ++ pending.rendered ++ "\n"
        pending_i = pending_i + 1
    let defs_path = output_dir ++ "/defs.w"
    let rc = with_fs_write_file(defs_path, ci_migrate_normalize_output(defs))
    if rc != 0:
        eprint("migrate: failed to write shared defs: " ++ defs_path)
    else:
        eprint("migrate: wrote shared defs: " ++ defs_path)

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
    p = p ++ "extern fn memchr(s: *const c_void, c: i32, n: i64) -> *mut c_void\n"
    p = p ++ ci_migrate_render_preamble_fn("fn string_len(s: *const i8) -> i64", "strlen(s)", "strlen(s)")
    p = p ++ ci_migrate_render_preamble_fn("fn string_cmp(a: *const i8, b: *const i8) -> i32", "strcmp(a, b)", "strcmp(a, b)")
    p = p ++ ci_migrate_render_preamble_fn("fn string_find_char(s: *const i8, c: i32) -> *const i8", "(memchr((s as *const c_void), c, strlen(s)) as *const i8)", "(memchr((s as *const c_void), c, strlen(s)) as *const i8)")
    p = p ++ "\ntype c_void = opaque\n"
    p = p ++ "type c_char = i8\n"
    p = p ++ "type c_short = i16\n"
    p = p ++ "type c_ushort = u16\n"
    p = p ++ "type c_int = i32\n"
    p = p ++ "type c_uint = u32\n"
    p = p ++ "type c_long = i64\n"
    p = p ++ "type c_ulong = u64\n"
    p = p ++ "type c_longlong = i64\n"
    p = p ++ "type c_ulonglong = u64\n"
    p = p ++ "type c_longdouble = f64\n"
    // Builtin and runtime wrappers
    p = p ++ "extern fn with_clz(x: i32) -> i32\n"
    p = p ++ "extern fn with_ctz(x: i32) -> i32\n"
    p = p ++ "extern fn with_popcount(x: i32) -> i32\n"
    p = p ++ "extern fn with_bswap16(x: u16) -> u16\n"
    p = p ++ "extern fn with_bswap32(x: u32) -> u32\n"
    p = p ++ "extern fn with_bswap64(x: u64) -> u64\n"
    p = p ++ "extern fn with_clzl(x: i64) -> i32\n"
    p = p ++ "extern fn with_clzll(x: i64) -> i32\n"
    p = p ++ "extern fn with_ctzl(x: i64) -> i32\n"
    p = p ++ "extern fn with_ctzll(x: i64) -> i32\n"
    p = p ++ "extern fn with_abs(x: i32) -> i32\n"
    p = p ++ "extern fn with_alloc(size: i64) -> *i8\n"
    p = p ++ "extern fn with_free(ptr: *i8) -> void\n"
    p = p ++ "extern fn with_memcpy(dst: *i8, src: *i8, n: i64) -> void\n"
    p = p ++ "extern fn with_memmove(dst: *i8, src: *i8, n: i64) -> void\n"
    p = p ++ "extern fn with_memset(ptr: *i8, c: i32, n: i64) -> void\n"
    p = p ++ "extern fn with_memcmp(a: *i8, b: *i8, n: i64) -> i32\n\n"
    p

// ── Migrate entry points (moved from CImport.w in D3) ─────────
pub fn migrate_add_define(define: str):
    // define is "NAME=VALUE" or just "NAME"
    if ci_str_contains(define, "="):
        let eq_pos = ci_find_substr(define, "=")
        if eq_pos > 0:
            let name = define.slice(0, eq_pos as i64)
            let value = define.slice((eq_pos + 1) as i64, define.len())
            g_migrate_defines = g_migrate_defines ++ "#define " ++ name ++ " " ++ value ++ "\n"
    else:
        g_migrate_defines = g_migrate_defines ++ "#define " ++ define ++ "\n"

fn migrate_host_compat_preamble() -> str:
    // Migrate often sees config.h templates instead of configured headers.
    // Provide a minimal host parse environment before the original source.
    "#if !defined(_POSIX_C_SOURCE)\n#define _POSIX_C_SOURCE 200809L\n#endif\n" ++
    "#if defined(__APPLE__) && !defined(_DARWIN_C_SOURCE)\n#define _DARWIN_C_SOURCE 1\n#endif\n" ++
    "#if !defined(HAVE_UNISTD_H)\n#ifdef __has_include\n#if __has_include(<unistd.h>)\n#define HAVE_UNISTD_H 1\n#endif\n#endif\n#endif\n" ++
    "#include <string.h>\n#include <stdio.h>\n" ++
    "#undef memcpy\n#undef memmove\n#undef memset\n" ++
    "#undef strcpy\n#undef strncpy\n#undef strcat\n#undef strncat\n" ++
    "#undef snprintf\n#undef sprintf\n#undef vsnprintf\n#undef vsprintf\n" ++
    "#undef stpcpy\n#undef stpncpy\n"

fn ci_capture_macro_values(session: i64):
    g_migrate_macro_values = ""
    let count = with_cimport_macro_count(session)
    var i = 0
    while i < count:
        if with_cimport_macro_is_fn_like(session, i) == 0:
            let name = with_cimport_macro_name(session, i)
            let value = with_cimport_macro_value(session, i)
            if name.len() > 0 and value.len() > 0:
                g_migrate_macro_values = g_migrate_macro_values ++ "|" ++ name ++ "=" ++ value ++ "|"
        i = i + 1

fn ci_collect_macro_type_names(session: i64) -> str:
    let count = with_cimport_decl_count(session)
    var names = ""
    var i = 0
    while i < count:
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_TYPEDEF or kind == CK_STRUCT or kind == CK_UNION or kind == CK_ENUM:
            let name = with_cimport_decl_name(session, i)
            if name.len() > 0 and name.byte_at(0) != 95:
                names = names ++ "|" ++ name ++ "|"
        i = i + 1
    names

fn ci_collect_macro_type_aliases(session: i64) -> str:
    let count = with_cimport_decl_count(session)
    var aliases = ""
    var i = 0
    while i < count:
        if with_cimport_decl_kind(session, i) == CK_TYPEDEF:
            let name = with_cimport_decl_name(session, i)
            let translated = with_cimport_typedef_underlying_translated(session, i)
            if name.len() > 0 and name.byte_at(0) != 95 and translated.len() > 0:
                aliases = aliases ++ "|" ++ name ++ "=" ++ translated ++ "|"
        i = i + 1
    aliases

fn ci_migrate_prepare_include_path(input_path: str):
    with_cimport_clear_include_paths()
    var dir_end = input_path.len() as i32 - 1
    while dir_end > 0 and input_path.byte_at(dir_end as i64) != 47:  // '/'
        dir_end = dir_end - 1
    if dir_end > 0:
        with_cimport_add_include_path(input_path.slice(0, dir_end as i64))

fn ci_migrate_source_prefix() -> str:
    let compat_preamble = migrate_host_compat_preamble()
    if g_migrate_defines.len() > 0:
        return g_migrate_defines ++ compat_preamble
    compat_preamble

fn ci_migrate_wrapped_source(input_path: str) -> str:
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

fn ci_migrate_project_var_type_id(session: i64, idx: i32, owner_type: str, project: &mut CiProject) -> CiTypeId:
    let cursor = with_cimport_decl_cursor(session, idx)
    if cursor < 0:
        return 0 as CiTypeId
    var ty_id = ci_type_from_libclang(session, with_ci_cursor_type(session, cursor), &mut project.types)
    if owner_type.len() == 0:
        return ty_id
    if (ty_id as i32) == 0 or ci_print_type(project.types, ty_id) != owner_type:
        ty_id = ci_type_from_translated_text(&mut project.types, owner_type)
    ty_id

fn ci_migrate_project_scan_file(input_path: str, project: &mut CiProject) -> i32:
    ci_migrate_prepare_include_path(input_path)
    let source = ci_migrate_wrapped_source(input_path)
    if source.len() == 0:
        eprint("migrate: cannot read " ++ input_path)
        return 1

    let session = with_cimport_parse(source)
    if session == 0:
        eprint("migrate: failed to parse " ++ input_path)
        return 1

    let err_msg = with_cimport_error(session)
    if err_msg.len() > 0:
        eprint("migrate: parse error: " ++ err_msg)
        with_cimport_dispose(session)
        return 1

    let module_id = project.ensure_module(input_path)
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
            let symbol_id = project.ensure_symbol(CiProjectSymbolKind.CIPS_VAR, name)
            var symbol = project.symbols.get(symbol_id as i64)
            symbol.add_consumer(module_id)
            project.update_symbol(symbol_id, symbol)

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
            if symbol.owner_module < 0:
                symbol.owner_module = module_id
                symbol.owner_rank = owner_rank
                symbol.owner_definition_kind = owner_kind
                symbol.resolved_ty_text = owner_type
                symbol.resolved_ty = ci_migrate_project_var_type_id(session, i, owner_type, project)
                project.update_symbol(symbol_id, symbol)
                i = i + 1
                continue

            let existing_path = project.owner_module_path(symbol_id)
            if symbol.owner_rank == owner_rank:
                if symbol.owner_definition_kind == CI_VAR_FULL_DEF and owner_kind == CI_VAR_FULL_DEF and existing_path != input_path:
                    eprint("migrate: duplicate full global definition for " ++ name ++ " in " ++ existing_path ++ " and " ++ input_path)
                    with_cimport_dispose(session)
                    return 1
                if symbol.resolved_ty_text.len() > 0 and symbol.resolved_ty_text != owner_type:
                    eprint("migrate: conflicting global owner type for " ++ name ++ " in " ++ existing_path ++ " and " ++ input_path)
                    with_cimport_dispose(session)
                    return 1
            if owner_rank > symbol.owner_rank or (owner_rank == symbol.owner_rank and ci_str_compare(input_path, existing_path) < 0):
                symbol.owner_module = module_id
                symbol.owner_rank = owner_rank
                symbol.owner_definition_kind = owner_kind
                symbol.resolved_ty_text = owner_type
                symbol.resolved_ty = ci_migrate_project_var_type_id(session, i, owner_type, project)
                project.update_symbol(symbol_id, symbol)
        i = i + 1

    with_cimport_dispose(session)
    0

fn ci_migrate_file_inner(input_path: str, output_path: str, project_active: bool, project: &CiProject) -> i32:
    if with_cimport_available() == 0:
        eprint("migrate: libclang not available")
        return 1

    ci_migrate_prepare_include_path(input_path)

    g_migrate_file_error = ""
    g_migrate_macro_values = ""
    g_migrate_macro_session = 0
    ci_migrate_reset_fn_counts()
    ci_migrate_libc_reset()
    g_migrate_preprocessed_source = ""
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
    g_migrate_current_input_path = input_path
    g_migrate_preprocessed_source = with_cimport_preprocess_text(source)

    // Pass to libclang via cimport_parse
    let session = with_cimport_parse(source)
    if session == 0:
        g_migrate_preprocessed_source = ""
        g_migrate_current_input_path = ""
        eprint("migrate: failed to parse " ++ input_path)
        return 1

    let err_msg = with_cimport_error(session)
    if err_msg.len() > 0:
        g_migrate_preprocessed_source = ""
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

    var output = ""

    // C3: in shared-defs mode, skip the preamble and emit `use <prefix>` instead.
    // The preamble goes into defs.w (written by ci_migrate_write_shared_defs).
    if ci_migrate_shared_defs_active():
        output = "// Migrated from PCRE2\nuse " ++ g_migrate_shared_defs_prefix ++ "\n\n"
    else:
        output = "// Generated by: with migrate " ++ input_path ++ "\n\n"
        output = output ++ ci_migrate_preamble_text()

    let count = with_cimport_decl_count(session)

    // Pre-scan: collect demoted types and prepopulate names
    let demoted_types = ci_collect_demoted_types(session, count)
    let typedef_shadowed = ci_prepopulate_names(session, count)

    // Collect extern var names for macro reference detection
    var extern_vars = ""
    var evi = 0
    while evi < count:
        if with_cimport_decl_kind(session, evi) == CK_VAR:
            let evname = with_cimport_decl_name(session, evi)
            if evname.len() > 0 and evname.byte_at(0) != 95:
                extern_vars = extern_vars ++ "|" ++ evname ++ "|"
        evi = evi + 1

    // Track emitted structs for typedef resolution
    var translated_structs = ""

    // Translate declarations (skip system header noise).
    // Use declaration source location to filter: only emit declarations
    // that originate from the user's file or from PCRE2 headers.
    var i = 0
    while i < count:
        let decl_name = with_cimport_decl_name(session, i)
        // Skip system types/functions by name pattern
        if ci_is_system_decl(decl_name):
            i = i + 1
            continue
        // Skip declarations from system headers (check source location)
        let decl_loc = ci_get_decl_location(session, decl_name)
        if decl_loc.len() > 0 and ci_is_system_path(decl_loc):
            i = i + 1
            continue
        // C2: skip width-family declarations when width slicing is active
        if ci_migrate_is_width_family_name(decl_name):
            i = i + 1
            continue
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_FUNCTION:
            output = output ++ ci_migrate_translate_function(session, i, translated_structs)
        else if kind == CK_STRUCT or kind == CK_UNION:
            let struct_result = ci_translate_struct(session, i, kind == CK_UNION, translated_structs, demoted_types)
            output = output ++ struct_result
            if struct_result.len() > 0:
                let sname = with_cimport_decl_name(session, i)
                if sname.len() > 0 and sname.byte_at(0) != 95:
                    translated_structs = translated_structs ++ "|" ++ sname ++ "|"
                    if ci_str_contains(typedef_shadowed, "|" ++ sname ++ "|"):
                        let alias_name = "struct_" ++ sname
                        if with_cimport_is_name_emitted(alias_name) == 0:
                            with_cimport_mark_name_emitted(alias_name)
                            output = output ++ "type " ++ alias_name ++ " = " ++ ci_escape_reserved(sname) ++ "\n"
        else if kind == CK_ENUM:
            output = output ++ ci_translate_enum(session, i)
        else if kind == CK_TYPEDEF:
            let td_result = ci_translate_typedef(session, i)
            output = output ++ td_result
            if td_result.len() > 0:
                let td_name = with_cimport_decl_name(session, i)
                if td_name.len() > 0 and td_name.byte_at(0) != 95:
                    translated_structs = translated_structs ++ "|" ++ td_name ++ "|"
        else if kind == CK_STATIC_ASSERT:
            let sa_name = with_cimport_decl_name(session, i)
            if sa_name.len() > 0:
                output = output ++ "// static_assert: " ++ sa_name ++ "\n"
        i = i + 1

    output = output ++ ci_migrate_translate_vars(session, count, input_path, project_active, project)
    if g_migrate_file_error.len() > 0:
        eprint(g_migrate_file_error)
        g_macro_type_names = ci_collect_macro_type_names(session)
        g_macro_type_aliases = ci_collect_macro_type_aliases(session)
        with_cimport_dispose(session)
        if macro_session != 0:
            with_cimport_dispose_macros(macro_session)
        g_migrate_macro_values = ""
        g_migrate_macro_session = 0
        g_migrate_preprocessed_source = ""
        g_migrate_current_input_path = ""
        g_macro_type_names = ""
        g_macro_type_aliases = ""
        g_migrate_file_error = ""
        return 1

    // Member function detection
    output = output ++ ci_detect_member_functions(session, count, translated_structs)
    g_macro_type_names = ci_collect_macro_type_names(session)
    g_macro_type_aliases = ci_collect_macro_type_aliases(session)
    with_cimport_dispose(session)

    // Macro translation via separate preprocessor pass
    if macro_session != 0:
        output = output ++ ci_translate_macros(macro_session, extern_vars, macro_include)
        with_cimport_dispose_macros(macro_session)
    g_migrate_macro_values = ""
    g_migrate_macro_session = 0
    g_migrate_preprocessed_source = ""
    g_migrate_current_input_path = ""
    g_macro_type_names = ""
    g_macro_type_aliases = ""
    g_migrate_file_error = ""

    // C4: post-process output — unsigned -1 in assignment/binding context.
    // ~(size_t)0 evaluates to -1 as a signed constant, but in unsigned context
    // it represents ULONG_MAX. Replace "= (-1" and "else: (-1" with wrapping form.
    if ci_migrate_shared_defs_active():
        output = ci_replace_sparse(output, "= (-1", "= ((0 -% 1)")
        output = ci_replace_sparse(output, "else: (-1", "else: ((0 -% 1)")

    output = ci_migrate_insert_libc_use(output)

    // File-level summary for untranslated functions
    if g_migrate_fn_untranslatable > 0:
        let summary = f"// [MIGRATOR STATUS] This file contains {g_migrate_fn_untranslatable} untranslated functions.\n// Search for [MIGRATOR_UNTRANSLATED] to find each one.\n// The original C is included in comments.\n\n"
        let header_end = ci_find_str(output, "\n\n")
        if header_end >= 0:
            let insert_pos = header_end as i64 + 2
            output = output.slice(0, insert_pos) ++ summary ++ output.slice(insert_pos, output.len())
        else:
            output = summary ++ output

    ci_migrate_shared_note_output_uses(output)
    output = ci_migrate_normalize_output(output)

    // Write output
    let write_result = with_fs_write_file(output_path, output)
    if write_result != 0:
        eprint("migrate: failed to write " ++ output_path)
        g_migrate_macro_values = ""
        g_migrate_macro_session = 0
        g_migrate_preprocessed_source = ""
        g_migrate_current_input_path = ""
        return 1

    // Print stats
    let goto_count = ci_count_substring(output, "__pc =")
    let unsafe_count = ci_count_substring(output, "unsafe")
    let fn_total = g_migrate_fn_translated + g_migrate_fn_untranslatable
    if g_migrate_fn_untranslatable > 0:
        eprint(f"migrate: {input_path} -> {output_path} ({g_migrate_fn_translated}/{fn_total} functions, {goto_count} gotos, {unsafe_count} unsafe, {g_migrate_fn_untranslatable} untranslatable)")
    else:
        eprint(f"migrate: {input_path} -> {output_path} ({goto_count} gotos, {unsafe_count} unsafe)")
    g_migrate_fn_translated_total = g_migrate_fn_translated_total + g_migrate_fn_translated
    g_migrate_fn_untranslatable_total = g_migrate_fn_untranslatable_total + g_migrate_fn_untranslatable
    0

pub fn migrate_c_file(input_path: str, output_path: str) -> i32:
    var project = CiProject.new()
    ci_migrate_file_inner(input_path, output_path, false, &project)

fn ci_migrate_path_basename(path: str) -> str:
    var end = path.len() as i32
    while end > 0 and path.byte_at((end - 1) as i64) == 47:
        end = end - 1
    var start = end - 1
    while start >= 0 and path.byte_at(start as i64) != 47:
        start = start - 1
    path.slice((start + 1) as i64, end as i64)

fn ci_migrate_excludes_contains(excludes: str, basename: str) -> bool:
    if excludes.len() == 0 or basename.len() == 0:
        return false
    let needle = "|" ++ basename ++ "|"
    ci_find_str(excludes, needle) >= 0

// Translate a directory of .c files to .w files.
pub fn migrate_c_directory(input_dir: str, output_dir: str, exclude_basenames: str) -> i32:
    g_migrate_fn_translated_total = 0
    g_migrate_fn_untranslatable_total = 0
    if ci_migrate_shared_defs_active():
        ci_migrate_shared_defs_reset()
    // Create output directory
    with_fs_mkdir_p(output_dir)

    // Find all .c files using shell
    let find_cmd = "find '" ++ ci_shell_escape(input_dir) ++ "' -name '*.c' -not -name '.*' -type f 2>/dev/null"
    let find_result = with_fs_read_file_cmd(find_cmd)
    if find_result.len() == 0:
        eprint("migrate: no .c files found in " ++ input_dir)
        return 1

    // Parse the file list (newline-separated)
    let files: Vec[str] = Vec.new()
    var files_scanned = 0
    var files_migrated = 0
    var pos = 0
    let flen = find_result.len() as i32
    while pos < flen:
        // Find end of line
        var line_end = pos
        while line_end < flen and find_result.byte_at(line_end as i64) != 10:
            line_end = line_end + 1
        if line_end > pos:
            let file_path = find_result.slice(pos as i64, line_end as i64)
            if file_path.len() > 2:
                let base = ci_migrate_path_basename(file_path)
                if ci_migrate_excludes_contains(exclude_basenames, base):
                    pos = line_end + 1
                    continue
                files_scanned = files_scanned + 1
                files.push(file_path)
        pos = line_end + 1

    var project = CiProject.new()

    var fi = 0
    while fi < files.len() as i32:
        if ci_migrate_project_scan_file(files.get(fi as i64), &mut project) != 0:
            return 1
        fi = fi + 1

    fi = 0
    while fi < files.len() as i32:
        let file_path = files.get(fi as i64)
        // Compute output path: replace input_dir prefix with output_dir, .c → .w
        var out_path = ""
        if ci_starts_with(file_path, input_dir):
            let relative = file_path.slice(input_dir.len(), file_path.len())
            if relative.len() > 2 and relative.slice(relative.len() - 2, relative.len()) == ".c":
                out_path = output_dir ++ relative.slice(0, relative.len() - 2) ++ ".w"
            else:
                out_path = output_dir ++ relative ++ ".w"
        else:
            out_path = output_dir ++ "/" ++ file_path ++ ".w"

        // Create subdirectories if needed
        var dir_end = out_path.len() as i32 - 1
        while dir_end > 0 and out_path.byte_at(dir_end as i64) != 47:
            dir_end = dir_end - 1
        if dir_end > 0:
            with_fs_mkdir_p(out_path.slice(0, dir_end as i64))

        let rc = ci_migrate_file_inner(file_path, out_path, true, &project)
        if rc == 0:
            files_migrated = files_migrated + 1
        fi = fi + 1

    // C3: emit shared defs module after all files are translated
    if ci_migrate_shared_defs_active():
        ci_migrate_write_shared_defs(output_dir)

    let files_failed = files_scanned - files_migrated
    ci_dump_raw_fallback_stats()
    let fn_total = g_migrate_fn_translated_total + g_migrate_fn_untranslatable_total
    if files_failed > 0 or g_migrate_fn_untranslatable_total > 0:
        let file_note = if files_failed > 0: f" ({files_failed} file errors)" else: ""
        eprint(f"migrate: {files_migrated}/{files_scanned} files, {g_migrate_fn_translated_total}/{fn_total} functions translated, {g_migrate_fn_untranslatable_total} untranslatable{file_note}")
        return 1
    eprint(f"migrate: {files_migrated}/{files_scanned} files, {fn_total} functions translated from {input_dir} -> {output_dir}")
    if files_migrated == 0: 1 else: 0

// Run a shell command and capture stdout (for find, ls, etc.)
fn with_fs_read_file_cmd(cmd: str) -> str:
    // Write command output to temp file, read it back
    let tmp = ".with_migrate_cmd_output"
    with_system(cmd ++ " > " ++ tmp)
    let result = with_fs_read_file(tmp)
    with_system("rm -f " ++ tmp)
    result

// Translate a function with body — key difference from ci_translate_function:
// 1. Translates ALL functions, not just static inline
// 2. Non-static functions get @[c_export]
// 3. Goto-containing functions use state-variable transform
// 4. Never silently demotes to extern — emits comptime_error on failure
fn ci_migrate_translate_function(session: i64, idx: i32, known_structs: str) -> str:
    // B9: every function gets a fresh per-function temp counter
    // so temp names are `__ci_expr_TAG_0`, `__ci_expr_TAG_1`, ...
    // rather than source-offset-keyed. The counter is cursor-
    // memoized so re-entering the same cursor returns the same id.
    ci_temp_reset()
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip system internal names (__ prefix or _[A-Z] prefix)
    // but keep application-internal names like _pcre2_*
    if name.len() >= 2 and name.byte_at(0) == 95:
        let second = name.byte_at(1)
        if second == 95 or (second >= 65 and second <= 90):
            return ""

    // Skip libc functions that are mapped to With equivalents
    if ci_is_mapped_libc_fn(name):
        return ""

    // Skip already-emitted names
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    let storage = with_cimport_fn_storage_class(session, idx)
    let safe_name = ci_escape_reserved(name)
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

    if is_variadic != 0 and fn_cursor >= 0 and with_ci_cursor_is_definition(session, fn_cursor) != 0:
        if name == "cfprintf" and ci_str_contains(g_migrate_current_input_path, "pcre2test.c"):
            with_cimport_mark_name_emitted(name)
            g_migrate_fn_translated = g_migrate_fn_translated + 1
            return "// Variadic C helper cfprintf is inlined at statement call sites.\n\n"

    var params = ""
    var has_unsupported = false
    var unsupported_reason = ""

    for pi in 0..param_count:
        if pi > 0:
            params = params ++ ", "
        let raw_ptype = with_cimport_fn_param_type_translated(session, idx, pi)
        var ptype = ci_pointer_type_explicit_mut(raw_ptype)

        if ci_starts_with(ptype, "__UNSUPPORTED:"):
            has_unsupported = true
            unsupported_reason = ptype.slice(14, ptype.len())

        // Use cursor API name if available, fall back to old API
        var pname = with_cimport_fn_param_name(session, idx, pi)
        if pname.len() == 0:
            pname = ci_get_nth_pipe_entry(cursor_param_names, pi)
        let escaped_pname = if pname.len() > 0: ci_escape_reserved(pname) else: f"p{pi}"
        // If this param is mutated in the body, rename it in the signature
        // to avoid shadowing when the body emits `var pname = __param_pname`
        var sig_pname = escaped_pname
        if fn_body_cursor >= 0 and ci_body_assigns_to(session, fn_body_cursor, escaped_pname):
            sig_pname = "__param_" ++ escaped_pname
        params = params ++ sig_pname ++ ": " ++ ptype

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

    with_cimport_mark_name_emitted(name)

    // Unsupported types — emit stub with original C
    if has_unsupported:
        g_migrate_fn_untranslatable = g_migrate_fn_untranslatable + 1
        eprint(f"migrate: untranslatable function '{name}': unsupported type ({unsupported_reason})")
        return ci_migrate_render_stub(name, safe_name, "", "Never", g_migrate_current_input_path, fn_cursor, session, "", "unsupported type: " ++ unsupported_reason)

    // @[c_export] for non-static functions (preserves C ABI)
    let export_prefix = if g_migrate_no_c_export != 0 or storage == CX_SC_STATIC: "" else: "@[c_export(\"" ++ name ++ "\")]\n"

    // Try to translate the function body.
    let body = ci_try_translate_fn_body(session, idx)
    if body.len() > 0:
        g_migrate_fn_translated = g_migrate_fn_translated + 1
        let ret_suffix = if ret == "void": "" else: " -> " ++ ret
        if migrate_prefer_brace():
            return export_prefix ++ "fn " ++ safe_name ++ "(" ++ params ++ ")" ++ ret_suffix ++ " {\n" ++ body ++ "}\n\n"
        return export_prefix ++ "fn " ++ safe_name ++ "(" ++ params ++ ")" ++ ret_suffix ++ ":\n" ++ body ++ "\n"

    // Body translation failed — emit stub with original C
    if g_migrate_no_c_export != 0:
        let is_definition = with_ci_cursor_is_definition(session, ci_find_fn_cursor(session, name))
        if is_definition != 0:
            g_migrate_fn_untranslatable = g_migrate_fn_untranslatable + 1
            let bail_loc = ci_get_bail_location()
            let bail_k = ci_get_bail_kind()
            let bail_kind_name = if bail_loc.len() > 0: ci_cursor_kind_name(bail_k) else: "unknown"
            if bail_loc.len() > 0:
                eprint(f"migrate: untranslatable function '{name}': bailed at {bail_kind_name} ({bail_loc})")
            else:
                eprint(f"migrate: untranslatable function '{name}': body translation failed")
            return ci_migrate_render_stub(name, safe_name, params, ret, g_migrate_current_input_path, fn_cursor, session, bail_loc, bail_kind_name)
    let cc = with_cimport_fn_calling_conv(session, idx)
    let cc_prefix = if cc != "c" and cc.len() > 0: "@[callconv(\"" ++ cc ++ "\")]\n" else: ""
    let rendered = cc_prefix ++ "extern fn " ++ safe_name ++ "(" ++ params ++ ") -> " ++ ret ++ "\n"
    if ci_migrate_shared_decl_add("extern_fn", safe_name, rendered):
        return ""
    rendered


// ── ci_migrate_var_* helpers (moved from CImport.w in D3) ─────
fn ci_migrate_set_error(msg: str):
    if g_migrate_file_error.len() == 0:
        g_migrate_file_error = msg

fn ci_migrate_var_definition_kind(session: i64, idx: i32) -> i32:
    with_cimport_var_definition_kind(session, idx)

fn ci_migrate_var_is_definition(session: i64, idx: i32) -> bool:
    ci_migrate_var_definition_kind(session, idx) != CI_VAR_DECL_ONLY

fn ci_migrate_project_var_symbol(project_active: bool, project: &CiProject, name: str) -> i32:
    if not project_active or name.len() == 0:
        return 0 - 1
    project.find_symbol(CiProjectSymbolKind.CIPS_VAR, name)

fn ci_migrate_project_var_owner_path(project_active: bool, project: &CiProject, name: str) -> str:
    let symbol_id = ci_migrate_project_var_symbol(project_active, project, name)
    if symbol_id < 0:
        return ""
    project.owner_module_path(symbol_id)

fn ci_migrate_project_var_resolved_type(project_active: bool, project: &CiProject, name: str) -> str:
    let symbol_id = ci_migrate_project_var_symbol(project_active, project, name)
    if symbol_id < 0:
        return ""
    let symbol = project.symbols.get(symbol_id as i64)
    if symbol.resolved_ty_text.len() > 0:
        return symbol.resolved_ty_text
    if (symbol.resolved_ty as i32) != 0:
        return ci_print_type(project.types, symbol.resolved_ty)
    ""

fn ci_migrate_var_emits_definition(session: i64, idx: i32, primary_path: str, project_active: bool, project: &CiProject) -> bool:
    if ci_migrate_var_definition_kind(session, idx) == CI_VAR_DECL_ONLY:
        return false
    if project_active and with_cimport_var_storage_class(session, idx) != CX_SC_STATIC:
        let name = with_cimport_decl_name(session, idx)
        let owner_path = ci_migrate_project_var_owner_path(project_active, project, name)
        if owner_path.len() > 0:
            return owner_path == primary_path
    true

fn ci_migrate_var_in_primary_file(session: i64, idx: i32, primary_path: str) -> bool:
    if primary_path.len() == 0:
        return false
    let cursor = with_cimport_decl_cursor(session, idx)
    if cursor < 0:
        return false
    with_ci_cursor_in_file(session, cursor, primary_path) != 0

fn ci_migrate_var_priority(session: i64, idx: i32, primary_path: str) -> i32:
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

fn ci_migrate_find_best_var_decl(session: i64, count: i32, name: str, primary_path: str) -> i32:
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
        return with_cimport_var_type_translated(session, idx)
    if ci_starts_with(actual_type, "[0]"):
        let cursor = with_cimport_decl_cursor(session, idx)
        if cursor >= 0:
            let init_cursor = ci_find_var_init_cursor(session, cursor)
            if init_cursor >= 0:
                let init_type = with_ci_type_translated(session, with_ci_cursor_type(session, init_cursor))
                if init_type.len() > 0 and init_type.byte_at(0) == 91:
                    let actual_elem = ci_array_elem_type(actual_type)
                    let init_elem = ci_array_elem_type(init_type)
                    if actual_elem.len() > 0 and actual_elem == init_elem:
                        actual_type = init_type
    actual_type

fn ci_migrate_var_resolved_type(session: i64, idx: i32, count: i32, primary_path: str, project_active: bool, project: &CiProject) -> str:
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
        return decl_type
    ci_migrate_var_owner_type(session, idx)

// ── ci_migrate_translate_var/s (moved from CImport.w in D3) ─────
fn ci_migrate_translate_var(session: i64, idx: i32, count: i32, primary_path: str, want_definitions: bool, project_active: bool, project: &CiProject) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip reserved C internal names (__foo or _Uppercase), keep _lowercase (e.g., _pcre2_*)
    if name.len() >= 2 and name.byte_at(0) == 95:
        let second = name.byte_at(1)
        if second == 95 or (second >= 65 and second <= 90):
            return ""

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
    let already_emitted = with_cimport_is_name_emitted(name) != 0
    if already_emitted:
        if ci_migrate_shared_defs_active() and not want_definitions and not emits_definition:
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
        if ci_migrate_shared_decl_add(kind, safe_name, rendered):
            return ""
        return rendered

    var shared_ownerless_extern = false
    if ci_migrate_shared_defs_active():
        let owner_path = ci_migrate_project_var_owner_path(project_active, project, name)
        if owner_path.len() > 0:
            return ""
        shared_ownerless_extern = true
    if is_const != 0:
        let rendered = tl_attr ++ "extern let " ++ safe_name ++ ": " ++ resolved_type ++ "\n"
        if shared_ownerless_extern:
            if ci_migrate_shared_ownerless_extern_add("extern_let", safe_name, rendered):
                return ""
        if ci_migrate_shared_decl_add("extern_let", safe_name, rendered):
            return ""
        return rendered
    let rendered = tl_attr ++ "extern var " ++ safe_name ++ ": " ++ resolved_type ++ "\n"
    if shared_ownerless_extern:
        if ci_migrate_shared_ownerless_extern_add("extern_var", safe_name, rendered):
            return ""
    if ci_migrate_shared_decl_add("extern_var", safe_name, rendered):
        return ""
    rendered

fn ci_migrate_translate_vars(session: i64, count: i32, primary_path: str, project_active: bool, project: &CiProject) -> str:
    var output = ""
    var i = 0
    while i < count:
        if with_cimport_decl_kind(session, i) == CK_VAR:
            let name = with_cimport_decl_name(session, i)
            if not ci_migrate_is_width_family_name(name):
                let cursor = with_cimport_decl_cursor(session, i)
                let loc = if cursor >= 0: with_ci_cursor_location(session, cursor) else: ""
                if not ci_is_system_decl(name) and not (loc.len() > 0 and ci_is_system_path(loc)):
                    output = output ++ ci_migrate_translate_var(session, i, count, primary_path, true, project_active, project)
        i = i + 1
    i = 0
    while i < count:
        if with_cimport_decl_kind(session, i) == CK_VAR:
            let name = with_cimport_decl_name(session, i)
            if not ci_migrate_is_width_family_name(name):
                let cursor = with_cimport_decl_cursor(session, i)
                let loc = if cursor >= 0: with_ci_cursor_location(session, cursor) else: ""
                if not ci_is_system_decl(name) and not (loc.len() > 0 and ci_is_system_path(loc)):
                    output = output ++ ci_migrate_translate_var(session, i, count, primary_path, false, project_active, project)
        i = i + 1
    output

// ── Migrate-only globals and setters (moved from CImport.w in D3) ─────

// Module-level defines to prepend to migrated C source.
// Set via migrate_add_define() before calling migrate_c_file().
var g_migrate_defines: str = ""
var g_migrate_file_error: str = ""

// When true, skip @[c_export] attributes and extern fn declarations
// for functions defined in the same translation unit.
// Set via migrate_set_no_c_export().
var g_migrate_no_c_export: i32 = 0

pub fn migrate_set_no_c_export(val: i32):
    g_migrate_no_c_export = val

// Block style preference for migrated output.
// 0 = colon-form (default), 2 = brace-form (--prefer-brace).
var g_migrate_block_style: i32 = 0

pub fn migrate_set_block_style(val: i32):
    g_migrate_block_style = val

pub fn migrate_prefer_brace() -> bool:
    g_migrate_block_style == 2

// Per-file and cumulative counters for translated vs untranslatable functions.
var g_migrate_fn_translated: i32 = 0
var g_migrate_fn_untranslatable: i32 = 0
var g_migrate_fn_translated_total: i32 = 0
var g_migrate_fn_untranslatable_total: i32 = 0

fn ci_migrate_reset_fn_counts():
    g_migrate_fn_translated = 0
    g_migrate_fn_untranslatable = 0

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
    if kind == 230: return "NullStmt"
    if kind == 231: return "DeclStmt"
    f"kind={kind}"
