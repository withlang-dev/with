// CImport — C header import via libclang bridge.
//
// Parses C headers using libclang (via clang_bridge.c) and generates
// synthetic extern fn / type declarations as .w source text.
// Falls back gracefully when libclang is unavailable.

use CiIR
use CiPrint
use CiMigrate
use std.cfg.stackify

extern fn with_cimport_add_include_path(path: str) -> void
extern fn with_cimport_clear_include_paths() -> void
extern fn with_cimport_available() -> i32
extern fn with_cimport_parse(header_code: str) -> i64
extern fn with_cimport_dispose(session: i64) -> void
extern fn with_cimport_error(session: i64) -> str
extern fn with_cimport_decl_count(session: i64) -> i32
extern fn with_cimport_decl_kind(session: i64, idx: i32) -> i32
extern fn with_cimport_decl_name(session: i64, idx: i32) -> str
extern fn with_cimport_decl_cursor(session: i64, idx: i32) -> i32
extern fn with_cimport_fn_return_type(session: i64, idx: i32) -> str
extern fn with_cimport_fn_param_count(session: i64, idx: i32) -> i32
extern fn with_cimport_fn_param_name(session: i64, idx: i32, param: i32) -> str
extern fn with_cimport_fn_param_type(session: i64, idx: i32, param: i32) -> str
extern fn with_cimport_param_is_restrict(session: i64, idx: i32, param: i32) -> i32
extern fn with_cimport_fn_is_variadic(session: i64, idx: i32) -> i32
extern fn with_cimport_fn_is_noreturn(session: i64, idx: i32) -> i32
extern fn with_cimport_struct_has_definition(session: i64, idx: i32) -> i32
extern fn with_cimport_var_alignment(session: i64, idx: i32) -> i32
extern fn with_cimport_hex_float_to_decimal(hex_str: str) -> str
extern fn with_cimport_struct_field_count(session: i64, idx: i32) -> i32
extern fn with_cimport_struct_field_name(session: i64, idx: i32, field: i32) -> str
extern fn with_cimport_struct_field_type(session: i64, idx: i32, field: i32) -> str
extern fn with_cimport_struct_is_opaque(session: i64, idx: i32) -> i32
extern fn with_cimport_struct_field_is_bitfield(session: i64, idx: i32, field: i32) -> i32
extern fn with_cimport_enum_const_count(session: i64, idx: i32) -> i32
extern fn with_cimport_enum_const_name(session: i64, idx: i32, ci: i32) -> str
extern fn with_cimport_enum_const_value(session: i64, idx: i32, ci: i32) -> i64
extern fn with_cimport_enum_int_type(session: i64, idx: i32) -> str
extern fn with_cimport_typedef_underlying(session: i64, idx: i32) -> str
extern fn with_cimport_parse_macros(header_code: str) -> i64
extern fn with_cimport_realpath(path: str) -> str
extern fn with_cimport_collect_object_macro_types(header_code: str, macro_names: str) -> str
extern fn with_cimport_preprocess_text(header_code: str) -> str
extern fn with_cimport_macro_count(session: i64) -> i32
extern fn with_cimport_macro_name(session: i64, idx: i32) -> str
extern fn with_cimport_macro_value(session: i64, idx: i32) -> str
extern fn with_cimport_macro_is_fn_like(session: i64, idx: i32) -> i32
extern fn with_cimport_dispose_macros(session: i64) -> void
extern fn with_cimport_is_name_emitted(name: str) -> i32
extern fn with_cimport_mark_name_emitted(name: str) -> void
extern fn with_cimport_reset_names() -> void
extern fn with_cimport_var_type(session: i64, idx: i32) -> str
extern fn with_cimport_var_is_const(session: i64, idx: i32) -> i32
extern fn with_cimport_var_storage_class(session: i64, idx: i32) -> i32
extern fn with_cimport_var_definition_kind(session: i64, idx: i32) -> i32
extern fn with_cimport_var_is_threadlocal(session: i64, idx: i32) -> i32
extern fn with_cimport_fn_param_type_translated(session: i64, idx: i32, param: i32) -> str
extern fn with_cimport_fn_return_type_translated(session: i64, idx: i32) -> str
extern fn with_cimport_struct_field_type_translated(session: i64, idx: i32, field: i32) -> str
extern fn with_cimport_var_type_translated(session: i64, idx: i32) -> str
extern fn with_cimport_var_storage_type_translated(session: i64, idx: i32) -> str
extern fn with_cimport_typedef_underlying_translated(session: i64, idx: i32) -> str
extern fn with_cimport_struct_field_is_anonymous_record(session: i64, idx: i32, field: i32) -> i32
extern fn with_cimport_struct_field_anon_field_count(session: i64, idx: i32, field: i32) -> i32
extern fn with_cimport_struct_field_anon_field_name(session: i64, idx: i32, field: i32, sub_field: i32) -> str
extern fn with_cimport_struct_field_anon_field_type(session: i64, idx: i32, field: i32, sub_field: i32) -> str
extern fn with_cimport_struct_is_packed(session: i64, idx: i32) -> i32
extern fn with_cimport_struct_field_offset(session: i64, idx: i32, field: i32) -> i64

var g_ci_realpath_cache_paths: Vec[str] = Vec.new()
var g_ci_realpath_cache_values: Vec[str] = Vec.new()
var g_cimport_last_error: str = ""
var g_cimport_untranslated_macros: str = ""
var g_cimport_report_untranslated_macros: i32 = 0
extern fn with_cimport_record_field_offset_by_name(session: i64, type_name: str, field_name: str) -> i64
extern fn with_cimport_struct_size(session: i64, idx: i32) -> i64
extern fn with_cimport_struct_field_size(session: i64, idx: i32, field: i32) -> i64
extern fn with_cimport_fn_storage_class(session: i64, idx: i32) -> i32
extern fn with_cimport_fn_is_inline(session: i64, idx: i32) -> i32
extern fn with_cimport_fn_calling_conv(session: i64, idx: i32) -> str
extern fn with_cimport_macro_param_count(session: i64, idx: i32) -> i32
extern fn with_cimport_macro_param_name(session: i64, idx: i32, param: i32) -> str
extern fn with_cimport_typedef_anon_record_field_count(session: i64, idx: i32) -> i32
extern fn with_cimport_typedef_anon_field_name(session: i64, idx: i32, field: i32) -> str
extern fn with_cimport_typedef_anon_field_type(session: i64, idx: i32, field: i32) -> str
extern fn with_cimport_typedef_anon_field_is_bitfield(session: i64, idx: i32, field: i32) -> i32
extern fn with_cimport_typedef_anon_is_union(session: i64, idx: i32) -> i32
// ── AST traversal API (Phase 1) ─────────────────────────────
extern fn with_ci_root_cursor(session: i64) -> i32
extern fn with_ci_num_children(session: i64, cursor: i32) -> i32
extern fn with_ci_child(session: i64, cursor: i32, index: i32) -> i32
extern fn with_ci_cursor_kind(session: i64, cursor: i32) -> i32
extern fn with_ci_cursor_spelling(session: i64, cursor: i32) -> str
extern fn with_ci_cursor_type(session: i64, cursor: i32) -> i32
extern fn with_ci_type_kind(session: i64, ty: i32) -> i32
extern fn with_ci_type_array_element(session: i64, ty: i32) -> i32
extern fn with_ci_type_array_size(session: i64, ty: i32) -> i64
extern fn with_ci_type_declaration(session: i64, ty: i32) -> i32
extern fn with_ci_type_translated(session: i64, ty: i32) -> str
extern fn with_ci_type_pointee(session: i64, ty: i32) -> i32
extern fn with_ci_type_is_const(session: i64, ty: i32) -> i32
extern fn with_ci_type_canonical(session: i64, ty: i32) -> i32
extern fn with_ci_type_result(session: i64, ty: i32) -> i32
extern fn with_ci_type_arg_count(session: i64, ty: i32) -> i32
extern fn with_ci_type_arg(session: i64, ty: i32, idx: i32) -> i32
extern fn with_ci_cursor_is_definition(session: i64, cursor: i32) -> i32
extern fn with_ci_cursor_in_file(session: i64, cursor: i32, path: str) -> i32
extern fn with_ci_cursor_location(session: i64, cursor: i32) -> str
extern fn with_ci_cursor_referenced_location(session: i64, cursor: i32) -> str
extern fn with_ci_cursor_source_text(session: i64, cursor: i32) -> str
extern fn with_ci_cursor_expansion_text(session: i64, cursor: i32) -> str
extern fn with_ci_cursor_spelling_text(session: i64, cursor: i32) -> str
extern fn with_ci_cursor_token_text(session: i64, cursor: i32) -> str
extern fn with_ci_cursor_start_offset(session: i64, cursor: i32) -> i32
extern fn with_ci_binary_op(session: i64, cursor: i32) -> i32
extern fn with_ci_unary_op(session: i64, cursor: i32) -> i32
extern fn with_ci_eval_int_value(session: i64, cursor: i32) -> i64
extern fn with_ci_eval_int_valid(session: i64, cursor: i32) -> i32
extern fn with_ci_eval_int_is_unsigned(session: i64, cursor: i32) -> i32
extern fn with_ci_eval_as_str(session: i64, cursor: i32) -> str
extern fn with_ci_member_field_name(session: i64, cursor: i32) -> str
extern fn with_getenv_str(name: str) -> str
extern fn with_ci_cursor_expansion_location(session: i64, cursor: i32) -> str
extern fn with_ci_cursor_spelling_location(session: i64, cursor: i32) -> str
extern fn with_ci_implicit_cast_kind(session: i64, cursor: i32) -> i32
extern fn with_ci_type_is_unsigned(session: i64, cursor: i32) -> i32
extern fn with_ci_type_is_pointer(session: i64, cursor: i32) -> i32
extern fn with_ci_type_is_float(session: i64, cursor: i32) -> i32
extern fn with_ci_type_is_bool(session: i64, cursor: i32) -> i32
extern fn with_ci_cursor_pointee_type(session: i64, cursor: i32) -> str
extern fn with_cimport_struct_field_align(session: i64, idx: i32, field: i32) -> i64
extern fn with_cimport_struct_align(session: i64, idx: i32) -> i64

extern fn i64_to_string(n: i64) -> str
extern fn with_eprint(s: str) -> void
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32

// CXCursorKind constants (old API — decl-level)
let CK_STRUCT: i32 = 2
let CK_UNION: i32 = 3
let CK_ENUM: i32 = 5
let CK_FIELD: i32 = 6
let CK_FUNCTION: i32 = 8
let CK_VAR: i32 = 9
let CK_TYPEDEF: i32 = 20
let CK_STATIC_ASSERT: i32 = 602

// CX_StorageClass constants
let CX_SC_EXTERN: i32 = 2
let CX_SC_STATIC: i32 = 3

// Global variable definition kinds.
let CI_VAR_DECL_ONLY: i32 = 0
let CI_VAR_TENTATIVE_DEF: i32 = 1
let CI_VAR_FULL_DEF: i32 = 2

// CXCursorKind constants (new API — cursor-level, LLVM 22 values)
let CXK_LABEL_STMT: i32 = 201
let CXK_COMPOUND_STMT: i32 = 202
let CXK_CASE_STMT: i32 = 203
let CXK_DEFAULT_STMT: i32 = 204
let CXK_IF_STMT: i32 = 205
let CXK_SWITCH_STMT: i32 = 206
let CXK_WHILE_STMT: i32 = 207
let CXK_DO_STMT: i32 = 208
let CXK_FOR_STMT: i32 = 209
let CXK_GOTO_STMT: i32 = 210
let CXK_CONTINUE_STMT: i32 = 212
let CXK_BREAK_STMT: i32 = 213
let CXK_RETURN_STMT: i32 = 214
let CXK_NULL_STMT: i32 = 230
let CXK_DECL_STMT: i32 = 231
let CXK_INT_LITERAL: i32 = 106
let CXK_FLOAT_LITERAL: i32 = 107
let CXK_STRING_LITERAL: i32 = 109
let CXK_CHAR_LITERAL: i32 = 110
let CXK_PAREN_EXPR: i32 = 111
let CXK_UNARY_OP: i32 = 112
let CXK_BINARY_OP: i32 = 114
let CXK_COMPOUND_ASSIGN_OP: i32 = 115
let CXK_COND_OP: i32 = 116
let CXK_CSTYLE_CAST: i32 = 117
let CXK_IMPLICIT_CAST: i32 = 124
let CXK_DECL_REF: i32 = 101
let CXK_MEMBER_REF: i32 = 102
let CXK_CALL_EXPR: i32 = 103
let CXK_ARRAY_SUBSCRIPT: i32 = 113
let CXK_INIT_LIST: i32 = 119
let CXK_UNARY_EXPR: i32 = 136
let CXK_COMPOUND_LITERAL: i32 = 118
let CXK_VAR_DECL: i32 = 9
let CXK_UNEXPOSED_STMT: i32 = 200

// Binary operator constants
let BO_ADD: i32 = 1
let BO_SUB: i32 = 2
let BO_MUL: i32 = 3
let BO_DIV: i32 = 4
let BO_REM: i32 = 5
let BO_AND: i32 = 6
let BO_OR: i32 = 7
let BO_XOR: i32 = 8
let BO_SHL: i32 = 9
let BO_SHR: i32 = 10
let BO_EQ: i32 = 11
let BO_NE: i32 = 12
let BO_LT: i32 = 13
let BO_GT: i32 = 14
let BO_LE: i32 = 15
let BO_GE: i32 = 16
let BO_LAND: i32 = 17
let BO_LOR: i32 = 18
let BO_ASSIGN: i32 = 19
let BO_ADD_ASSIGN: i32 = 20
let BO_SUB_ASSIGN: i32 = 21
let BO_MUL_ASSIGN: i32 = 22
let BO_DIV_ASSIGN: i32 = 23
let BO_REM_ASSIGN: i32 = 24
let BO_AND_ASSIGN: i32 = 25
let BO_OR_ASSIGN: i32 = 26
let BO_XOR_ASSIGN: i32 = 27
let BO_SHL_ASSIGN: i32 = 28
let BO_SHR_ASSIGN: i32 = 29
let BO_COMMA: i32 = 30

// Implicit cast kind constants
// CI_CAST_* values must match the CIC_* constants in
// rt/clang_bridge.w — with_ci_implicit_cast_kind returns CIC_*
// values and CImport.w dispatches on them. Kinds the bridge
// does not emit are set to distinct sentinels < 0 so they never
// accidentally match a real return value.
let CI_CAST_NOOP: i32 = 0
let CI_CAST_NULL_TO_PTR: i32 = 2
let CI_CAST_BOOL_TO_INT: i32 = 3
let CI_CAST_INT_TO_BOOL: i32 = 5
let CI_CAST_PTR_TO_BOOL: i32 = 7
let CI_CAST_INT_TO_FLOAT: i32 = 9
let CI_CAST_FLOAT_TO_INT: i32 = 10
let CI_CAST_TO_VOID: i32 = 15
let CI_CAST_INT_TRUNC: i32 = 16
let CI_CAST_INT_WIDEN: i32 = 17
let CI_CAST_ARRAY_TO_PTR: i32 = 20
let CI_CAST_INT_TO_PTR: i32 = 21
let CI_CAST_PTR_TO_INT: i32 = 22
let CI_CAST_PTR_CAST: i32 = 23
let CI_CAST_FLOAT_CAST: i32 = 24
let CI_CAST_FLOAT_TO_BOOL: i32 = 25
let CI_CAST_BOOL_TO_FLOAT: i32 = 26
let CI_CAST_BITCAST: i32 = 28
let CI_CAST_INT_WIDEN_SIGN: i32 = 29
// Kinds the bridge does not emit — distinct negative sentinels
// so `cast_kind == CI_CAST_*` comparisons never match anything
// the bridge returns.
let CI_CAST_UNKNOWN: i32 = -1
let CI_CAST_LVALUE_TO_RVALUE: i32 = -2
let CI_CAST_FUNCTION_TO_PTR: i32 = -3
let CI_CAST_FLOAT_WIDEN: i32 = CI_CAST_FLOAT_CAST
let CI_CAST_FLOAT_TRUNC: i32 = CI_CAST_FLOAT_CAST

// Unary operator constants
let UO_MINUS: i32 = 1
let UO_NOT: i32 = 2
let UO_LNOT: i32 = 3
let UO_ADDR: i32 = 4
let UO_DEREF: i32 = 5
let UO_PLUS: i32 = 6
let UO_PRE_INC: i32 = 7
let UO_PRE_DEC: i32 = 8
let UO_POST_INC: i32 = 9
let UO_POST_DEC: i32 = 10

// Process a c_import header spec and return synthetic .w source text.
// Returns "" if the bridge is unavailable or parsing fails.
fn ci_set_include_paths(paths: Vec[str]):
    with_cimport_clear_include_paths()
    for i in 0..paths.len() as i32:
        with_cimport_add_include_path(paths.get(i as i64))

fn ci_build_define_prefix(defines: Vec[str]) -> str:
    var out = ""
    for i in 0..defines.len() as i32:
        let define = defines.get(i as i64)
        if define.len() > 0:
            var rendered = define
            for di in 0..define.len() as i32:
                if define.byte_at(di as i64) == 61:
                    rendered = define.slice(0, di as i64) ++ " " ++ define.slice((di + 1) as i64, define.len())
                    break
            out = out ++ "#define " ++ rendered ++ "\n"
    out

fn c_import_last_error_clear():
    g_cimport_last_error = ""
    return

fn c_import_last_error() -> str:
    g_cimport_last_error

fn c_import_untranslated_macros_clear():
    g_cimport_untranslated_macros = ""
    return

fn c_import_untranslated_macros() -> str:
    g_cimport_untranslated_macros

fn ci_record_untranslated_macro(name: str):
    if g_cimport_report_untranslated_macros == 0:
        return
    if name.len() == 0:
        return
    let needle = "|" ++ name ++ "|"
    if ci_str_contains(g_cimport_untranslated_macros, needle):
        return
    g_cimport_untranslated_macros = g_cimport_untranslated_macros ++ needle
    return

fn ci_should_report_untranslated_macros(header_spec: str) -> i32:
    if ci_str_contains(header_spec, "#define"):
        return 1
    0

fn ci_is_implicit_compiler_macro(name: str) -> bool:
    if name == "va_start": return true
    if name == "va_arg": return true
    if name == "va_end": return true
    if name == "va_copy": return true
    if name == "__va_copy": return true
    false

fn process_c_import(header_spec: str) -> str:
    let defines: Vec[str] = Vec.new()
    process_c_import_with_defines(header_spec, defines)

fn process_c_import_with_defines(header_spec: str, defines: Vec[str]) -> str:
    c_import_last_error_clear()
    c_import_untranslated_macros_clear()
    g_cimport_report_untranslated_macros = ci_should_report_untranslated_macros(header_spec)
    if with_cimport_available() == 0:
        return ""

    let include_text = ci_build_define_prefix(defines) ++ ci_build_include_text(header_spec)
    let session = with_cimport_parse(include_text)
    if session == 0:
        g_cimport_last_error = "failed to create c_import parse session"
        return ""

    let err_msg = with_cimport_error(session)
    if err_msg.len() > 0:
        g_cimport_last_error = err_msg
        with_cimport_dispose(session)
        return ""

    var output = ""
    let count = with_cimport_decl_count(session)

    // Emit c_void opaque type for void pointer translation
    if with_cimport_is_name_emitted("c_void") == 0:
        output = "type c_void = opaque\n"
        with_cimport_mark_name_emitted("c_void")

    // Emit platform-specific C type aliases (matching Zig's c_int, c_long, etc.)
    if with_cimport_is_name_emitted("c_char") == 0:
        // arm64 macOS: char=signed, int=32, long=64, short=16
        output = output ++ "type c_char = i8\n"
        output = output ++ "type c_short = i16\n"
        output = output ++ "type c_ushort = u16\n"
        output = output ++ "type c_int = i32\n"
        output = output ++ "type c_uint = u32\n"
        output = output ++ "type c_long = i64\n"
        output = output ++ "type c_ulong = u64\n"
        output = output ++ "type c_longlong = i64\n"
        output = output ++ "type c_ulonglong = u64\n"
        output = output ++ "type c_longdouble = f64\n"
        with_cimport_mark_name_emitted("c_char")
        with_cimport_mark_name_emitted("c_short")
        with_cimport_mark_name_emitted("c_ushort")
        with_cimport_mark_name_emitted("c_int")
        with_cimport_mark_name_emitted("c_uint")
        with_cimport_mark_name_emitted("c_long")
        with_cimport_mark_name_emitted("c_ulong")
        with_cimport_mark_name_emitted("c_longlong")
        with_cimport_mark_name_emitted("c_ulonglong")
        with_cimport_mark_name_emitted("c_longdouble")

    // Emit Complex32/Complex64 for _Complex float/double
    if with_cimport_is_name_emitted("Complex32") == 0:
        output = output ++ "type Complex32 \{ real: f32, imag: f32 }\n"
        output = output ++ "type Complex64 \{ real: f64, imag: f64 }\n"
        with_cimport_mark_name_emitted("Complex32")
        with_cimport_mark_name_emitted("Complex64")

    // Emit runtime wrappers for __builtin_* bit manipulation
    if with_cimport_is_name_emitted("with_clz") == 0:
        output = output ++ "extern fn with_clz(x: i32) -> i32\n"
        output = output ++ "extern fn with_ctz(x: i32) -> i32\n"
        output = output ++ "extern fn with_popcount(x: i32) -> i32\n"
        output = output ++ "extern fn with_bswap16(x: u16) -> u16\n"
        output = output ++ "extern fn with_bswap32(x: u32) -> u32\n"
        output = output ++ "extern fn with_bswap64(x: u64) -> u64\n"
        output = output ++ "extern fn with_clzl(x: i64) -> i32\n"
        output = output ++ "extern fn with_clzll(x: i64) -> i32\n"
        output = output ++ "extern fn with_ctzl(x: i64) -> i32\n"
        output = output ++ "extern fn with_ctzll(x: i64) -> i32\n"
        output = output ++ "extern fn with_abs(x: i32) -> i32\n"
        with_cimport_mark_name_emitted("with_clz")
        with_cimport_mark_name_emitted("with_ctz")
        with_cimport_mark_name_emitted("with_popcount")
        with_cimport_mark_name_emitted("with_bswap16")
        with_cimport_mark_name_emitted("with_bswap32")
        with_cimport_mark_name_emitted("with_bswap64")
        with_cimport_mark_name_emitted("with_clzl")
        with_cimport_mark_name_emitted("with_clzll")
        with_cimport_mark_name_emitted("with_ctzl")
        with_cimport_mark_name_emitted("with_ctzll")
        with_cimport_mark_name_emitted("with_abs")

    if with_cimport_is_name_emitted("with_alloc") == 0:
        output = output ++ "extern fn with_alloc(size: i64) -> *mut u8\n"
        output = output ++ "extern fn with_alloc_zeroed(count: i64, size: i64) -> *mut u8\n"
        output = output ++ "extern fn with_realloc(ptr: *mut u8, old_size: i64, new_size: i64) -> *mut u8\n"
        output = output ++ "extern fn with_free(ptr: *mut u8) -> void\n"
        with_cimport_mark_name_emitted("with_alloc")
        with_cimport_mark_name_emitted("with_alloc_zeroed")
        with_cimport_mark_name_emitted("with_realloc")
        with_cimport_mark_name_emitted("with_free")

    output = output ++ ci_render_missing_pointer_opaques(session, count)

    // Pre-scan: collect extern var names for macro reference detection
    var extern_vars = ""
    var evi = 0
    while evi < count:
        if with_cimport_decl_kind(session, evi) == CK_VAR:
            let evname = with_cimport_decl_name(session, evi)
            if evname.len() > 0 and evname.byte_at(0) != 95:
                extern_vars = extern_vars ++ "|" ++ evname ++ "|"
        evi = evi + 1

    let macro_session = with_cimport_parse_macros(include_text)
    if macro_session != 0:
        g_migrate_macro_values = ci_collect_object_macro_values(macro_session)
        g_migrate_macro_miss_names = Vec.new()

    // Pre-scan: collect all opaque-demoted types (bitfield, forward decl, unsupported)
    // then cascade through field references until fixpoint
    let demoted_types = ci_collect_demoted_types(session, count)

    // Pass 1: Pre-populate name table (Zig-style two-pass).
    // Strong names (functions, variables, typedefs) get priority.
    // Weak names (structs, unions, enums) can be overridden by typedefs.
    // This prevents collisions in the common C pattern: typedef struct Foo { ... } Foo;
    var translated_structs = ""
    let typedef_shadowed = ci_prepopulate_names(session, count)
    g_macro_type_names = ci_collect_macro_type_names(session)
    g_macro_type_aliases = ci_collect_macro_type_aliases(session)

    var i = 0
    while i < count:
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_FUNCTION:
            output = output ++ ci_translate_function(session, i, translated_structs)
        else if kind == CK_STRUCT or kind == CK_UNION:
            let struct_result = ci_translate_struct(session, i, kind == CK_UNION, translated_structs, demoted_types, count)
            output = output ++ struct_result
            // Track struct name for typedef resolution (only if actually translated)
            if struct_result.len() > 0:
                let sname = with_cimport_decl_name(session, i)
                if sname.len() > 0 and sname.byte_at(0) != 95:
                    translated_structs = translated_structs ++ "|" ++ sname ++ "|"
                    // Emit struct_Foo alias when Foo has a typedef twin
                    if ci_str_contains(typedef_shadowed, "|" ++ sname ++ "|"):
                        let alias_name = "struct_" ++ sname
                        if with_cimport_is_name_emitted(alias_name) == 0:
                            with_cimport_mark_name_emitted(alias_name)
                            output = output ++ "type " ++ alias_name ++ " = " ++ ci_escape_reserved(sname) ++ "\n"
        else if kind == CK_ENUM:
            output = output ++ ci_translate_enum(session, i)
        else if kind == CK_VAR:
            output = output ++ ci_translate_var(session, i, translated_structs)
        else if kind == CK_TYPEDEF:
            let td_result = ci_translate_typedef(session, i, count)
            output = output ++ td_result
            // Track typedef name if it aliases a translated struct
            if td_result.len() > 0:
                let td_name = with_cimport_decl_name(session, i)
                if td_name.len() > 0 and td_name.byte_at(0) != 95:
                    translated_structs = translated_structs ++ "|" ++ td_name ++ "|"
        else if kind == CK_STATIC_ASSERT:
            let sa_name = with_cimport_decl_name(session, i)
            if sa_name.len() > 0:
                output = output ++ "// static_assert: " ++ sa_name ++ "\n"
        i = i + 1

    // Member function detection (Zig-style): attach C functions whose first
    // parameter is *StructType as methods of that struct.
    output = output ++ ci_detect_member_functions(session, count, translated_structs)
    // Extract macros using a separate preprocessor pass
    if macro_session != 0:
        output = output ++ ci_translate_macros(macro_session, session, extern_vars, include_text)
        with_cimport_dispose_macros(macro_session)
    with_cimport_dispose(session)
    g_macro_type_names = ""
    g_macro_type_aliases = ""
    g_migrate_macro_values = ""
    g_migrate_macro_miss_names = Vec.new()

    output

// Mark all declaration names from cached text as emitted in the global dedup table.
// This ensures that fs-cached c_import results don't conflict with subsequent c_imports.
fn ci_mark_cached_names(text: str):
    var pos = 0
    let len = text.len() as i32
    while pos < len:
        // Find start of line
        var line_start = pos
        // Find end of line
        var line_end = pos
        while line_end < len and text.byte_at(line_end as i64) != 10:
            line_end = line_end + 1
        let line = text.slice(line_start as i64, line_end as i64)
        // Extract name from "extern fn NAME(" or "let NAME:" or "let NAME =" or "type NAME "
        if ci_starts_with(line, "extern fn "):
            let rest = line.slice(10, line.len())
            let name = ci_extract_ident(rest)
            if name.len() > 0:
                with_cimport_mark_name_emitted(name)
        else if ci_starts_with(line, "fn "):
            let rest = line.slice(3, line.len())
            let name = ci_extract_ident(rest)
            if name.len() > 0:
                with_cimport_mark_name_emitted(name)
        else if ci_starts_with(line, "extern let "):
            let rest = line.slice(11, line.len())
            let name = ci_extract_ident(rest)
            if name.len() > 0:
                with_cimport_mark_name_emitted(name)
        else if ci_starts_with(line, "extern var "):
            let rest = line.slice(11, line.len())
            let name = ci_extract_ident(rest)
            if name.len() > 0:
                with_cimport_mark_name_emitted(name)
        else if ci_starts_with(line, "let "):
            let rest = line.slice(4, line.len())
            let name = ci_extract_ident(rest)
            if name.len() > 0:
                with_cimport_mark_name_emitted(name)
        else if ci_starts_with(line, "type "):
            let rest = line.slice(5, line.len())
            let name = ci_extract_ident(rest)
            if name.len() > 0:
                with_cimport_mark_name_emitted(name)
        pos = line_end + 1

// Escape a string for use inside single quotes in a shell command.
// Replaces ' with '\'' (end quote, escaped quote, start quote).
fn ci_shell_escape(s: str) -> str:
    var result = ""
    var i = 0
    while i as i64 < s.len():
        if s.byte_at(i as i64) == 39:  // '\''
            result = result ++ "'\\''"
        else:
            result = result ++ s.slice(i as i64, i as i64 + 1)
        i = i + 1
    result

fn ci_extract_ident(s: str) -> str:
    var end = 0
    while end as i64 < s.len():
        let c = s.byte_at(end as i64)
        if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95 or (c >= 48 and c <= 57):
            end = end + 1
        else:
            break
    s.slice(0, end as i64)

// ── Collision mangling ───────────────────────────────────────

fn ci_unique_name(name: str) -> str:
    // If name is not yet emitted, return it as-is.
    // Otherwise append _2, _3, ... until unique.
    if with_cimport_is_name_emitted(name) == 0:
        return name
    var suffix = 2
    while suffix < 100:
        let candidate = f"{name}_{suffix}"
        if with_cimport_is_name_emitted(candidate) == 0:
            return candidate
        suffix = suffix + 1
    name ++ "_99"

// ── Include text construction ───────────────────────────────

fn ci_build_include_text(header_spec: str) -> str:
    // c_import also accepts raw C snippets used by tests and generated bindings.
    if header_spec.len() > 0:
        if header_spec.byte_at(0) == 35 or ci_str_contains(header_spec, "\n") or ci_str_contains(header_spec, ";"):
            return header_spec
    // Already has #include directive
    if header_spec.len() >= 8:
        if header_spec.slice(0, 8) == "#include":
            return header_spec
    // Has angle brackets
    if header_spec.len() > 2 and header_spec.byte_at(0) == 60:
        return "#include " ++ header_spec
    // Has quotes
    if header_spec.len() > 2 and header_spec.byte_at(0) == 34:
        return "#include " ++ header_spec
    // Bare header name
    "#include <" ++ header_spec ++ ">"

// ── Opaque demotion pre-scan ─────────────────────────────────
// ── Name pre-population (Zig-style two-pass) ────────────────
// Pre-register all declaration names before translating any.
// Strong names (functions, variables, typedefs) take priority.
// Weak names (structs, unions, enums) can be overridden by typedefs.
// This prevents the common C collision: typedef struct Foo { ... } Foo;

// Returns pipe-delimited string of struct/union names shadowed by typedefs.
fn ci_prepopulate_names(session: i64, count: i32) -> str:
    // For the common C pattern: typedef struct Foo { ... } Foo;
    // The struct "Foo" should be skipped so the typedef "Foo" wins.
    var shadowed = ""
    var i = 0
    while i < count:
        let name = with_cimport_decl_name(session, i)
        if name.len() > 0 and name.byte_at(0) != 95:
            let kind = with_cimport_decl_kind(session, i)
            if kind == CK_STRUCT or kind == CK_UNION:
                var j = 0
                while j < count:
                    if j != i:
                        let jname = with_cimport_decl_name(session, j)
                        if jname == name and with_cimport_decl_kind(session, j) == CK_TYPEDEF:
                            shadowed = shadowed ++ "|" ++ name ++ "|"
                            break
                    j = j + 1
        i = i + 1
    shadowed

fn ci_record_definition_exists(session: i64, name: str, is_union: bool, count: i32) -> bool:
    if name.len() == 0:
        return false
    let target_kind = if is_union: CK_UNION else: CK_STRUCT
    var i = 0
    while i < count:
        if with_cimport_decl_kind(session, i) == target_kind:
            if with_cimport_decl_name(session, i) == name and with_cimport_struct_is_opaque(session, i) == 0:
                return true
        i = i + 1
    false

fn ci_decl_name_exists(session: i64, name: str, count: i32) -> bool:
    if name.len() == 0:
        return false
    var i = 0
    while i < count:
        let decl_name = with_cimport_decl_name(session, i)
        if decl_name == name or ci_escape_reserved(decl_name) == name:
            return true
        i = i + 1
    false

fn ci_translated_builtin_type_name(name: str) -> bool:
    if name == "c_void": return true
    if name == "c_char": return true
    if name == "c_short": return true
    if name == "c_ushort": return true
    if name == "c_int": return true
    if name == "c_uint": return true
    if name == "c_long": return true
    if name == "c_ulong": return true
    if name == "c_longlong": return true
    if name == "c_ulonglong": return true
    if name == "c_longdouble": return true
    if name == "Complex32": return true
    if name == "Complex64": return true
    if name == "i8" or name == "u8": return true
    if name == "i16" or name == "u16": return true
    if name == "i32" or name == "u32": return true
    if name == "i64" or name == "u64": return true
    if name == "i128" or name == "u128": return true
    if name == "f32" or name == "f64": return true
    if name == "bool" or name == "void": return true
    false

fn ci_pointer_pointee_name(translated_type: str) -> str:
    var t = ci_trim(translated_type)
    var saw_pointer = false
    while ci_starts_with(t, "*mut ") or ci_starts_with(t, "*const ") or ci_starts_with(t, "*volatile "):
        saw_pointer = true
        if ci_starts_with(t, "*mut "):
            t = ci_trim(t.slice(5, t.len()))
        else if ci_starts_with(t, "*const "):
            t = ci_trim(t.slice(7, t.len()))
        else:
            t = ci_trim(t.slice(10, t.len()))
    if not saw_pointer:
        return ""
    if t.len() == 0:
        return ""
    if ci_str_contains(t, " ") or ci_str_contains(t, "(") or ci_str_contains(t, ")") or ci_str_contains(t, "[") or ci_str_contains(t, "]"):
        return ""
    if ci_translated_builtin_type_name(t):
        return ""
    t

fn ci_missing_pointer_opaque_add(session: i64, count: i32, names: str, translated_type: str) -> str:
    let name = ci_pointer_pointee_name(translated_type)
    if name.len() == 0:
        return names
    if ci_decl_name_exists(session, name, count):
        return names
    if ci_str_contains(names, "|" ++ name ++ "|"):
        return names
    names ++ "|" ++ name ++ "|"

fn ci_collect_missing_pointer_opaques(session: i64, count: i32) -> str:
    var names = ""
    var i = 0
    while i < count:
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_STRUCT or kind == CK_UNION:
            let field_count = with_cimport_struct_field_count(session, i)
            var fi = 0
            while fi < field_count:
                names = ci_missing_pointer_opaque_add(session, count, names, with_cimport_struct_field_type_translated(session, i, fi))
                fi = fi + 1
        else if kind == CK_FUNCTION:
            names = ci_missing_pointer_opaque_add(session, count, names, with_cimport_fn_return_type_translated(session, i))
            let param_count = with_cimport_fn_param_count(session, i)
            var pi = 0
            while pi < param_count:
                names = ci_missing_pointer_opaque_add(session, count, names, with_cimport_fn_param_type_translated(session, i, pi))
                pi = pi + 1
        else if kind == CK_VAR:
            names = ci_missing_pointer_opaque_add(session, count, names, with_cimport_var_type_translated(session, i))
        i = i + 1
    names

fn ci_render_missing_pointer_opaques(session: i64, count: i32) -> str:
    let names = ci_collect_missing_pointer_opaques(session, count)
    if names.len() == 0:
        return ""
    var out = ""
    var start = 0
    var i = 0
    while i <= names.len() as i32:
        if i == names.len() as i32 or names.byte_at(i as i64) == 124:
            if i > start:
                let name = names.slice(start as i64, i as i64)
                if name.len() > 0 and with_cimport_is_name_emitted(name) == 0:
                    with_cimport_mark_name_emitted(name)
                    out = out ++ "type " ++ ci_escape_reserved(name) ++ " = opaque\n"
            start = i + 1
        i = i + 1
    out

fn ci_find_decl_cursor(session: i64, kind: i32, name: str) -> i32:
    if name.len() == 0:
        return -1
    let root = with_ci_root_cursor(session)
    let n = with_ci_num_children(session, root)
    var i = 0
    while i < n:
        let child = with_ci_child(session, root, i)
        if with_ci_cursor_kind(session, child) == kind:
            if with_ci_cursor_spelling(session, child) == name:
                return child
        i = i + 1
    -1

fn ci_find_decl_cursor_for_idx(session: i64, idx: i32) -> i32:
    let kind = with_cimport_decl_kind(session, idx)
    if kind != CK_STRUCT and kind != CK_UNION:
        return -1
    with_cimport_decl_cursor(session, idx)

fn ci_find_child_of_kind(session: i64, cursor: i32, kind: i32) -> i32:
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        let child = with_ci_child(session, cursor, i)
        if with_ci_cursor_kind(session, child) == kind:
            return child
        i = i + 1
    -1

fn ci_decl_field_cursor(session: i64, decl_cursor: i32, field_idx: i32) -> i32:
    if decl_cursor < 0 or field_idx < 0:
        return -1
    let nc = with_ci_num_children(session, decl_cursor)
    var seen = 0
    var i = 0
    while i < nc:
        let child = with_ci_child(session, decl_cursor, i)
        if with_ci_cursor_kind(session, child) == CK_FIELD:
            if seen == field_idx:
                return child
            seen = seen + 1
        i = i + 1
    -1

fn ci_field_cursor_anon_record_decl(session: i64, field_cursor: i32) -> i32:
    if field_cursor < 0:
        return -1
    let field_ty = with_ci_cursor_type(session, field_cursor)
    if field_ty < 0:
        return -1
    let decl_cursor = with_ci_type_declaration(session, field_ty)
    if decl_cursor < 0:
        return -1
    let kind = with_ci_cursor_kind(session, decl_cursor)
    if kind == CK_STRUCT or kind == CK_UNION:
        let decl_name = with_ci_cursor_spelling(session, decl_cursor)
        let field_ty_str = with_ci_type_translated(session, field_ty)
        if decl_name.len() == 0 or ci_str_contains(field_ty_str, "(unnamed at ") or ci_str_contains(field_ty_str, "::("):
            return decl_cursor
    -1

fn ci_record_decl_directly_demoted_cursor(session: i64, decl_cursor: i32) -> bool:
    if decl_cursor < 0:
        return true
    if with_ci_cursor_is_definition(session, decl_cursor) == 0:
        return true
    let nc = with_ci_num_children(session, decl_cursor)
    var i = 0
    while i < nc:
        let child = with_ci_child(session, decl_cursor, i)
        if with_ci_cursor_kind(session, child) == CK_FIELD:
            let anon_decl = ci_field_cursor_anon_record_decl(session, child)
            if anon_decl >= 0:
                if ci_record_decl_directly_demoted_cursor(session, anon_decl):
                    return true
            else:
                let field_ty = with_ci_type_translated(session, with_ci_cursor_type(session, child))
                if ci_starts_with(field_ty, "__UNSUPPORTED:") or field_ty == "c_void":
                    return true
        i = i + 1
    false

fn ci_record_decl_has_demoted_field_cursor(session: i64, decl_cursor: i32, demoted: str) -> bool:
    if decl_cursor < 0:
        return false
    let nc = with_ci_num_children(session, decl_cursor)
    var i = 0
    while i < nc:
        let child = with_ci_child(session, decl_cursor, i)
        if with_ci_cursor_kind(session, child) == CK_FIELD:
            let anon_decl = ci_field_cursor_anon_record_decl(session, child)
            if anon_decl >= 0:
                if ci_record_decl_has_demoted_field_cursor(session, anon_decl, demoted):
                    return true
            else:
                let field_ty = with_ci_type_translated(session, with_ci_cursor_type(session, child))
                if ci_field_type_is_demoted(field_ty, demoted):
                    return true
        i = i + 1
    false

fn ci_translate_anon_record_cursor(session: i64, decl_cursor: i32, synth_name: str) -> str:
    if decl_cursor < 0 or synth_name.len() == 0:
        return ""
    if with_cimport_is_name_emitted(synth_name) != 0:
        return ""
    with_cimport_mark_name_emitted(synth_name)
    if ci_record_decl_directly_demoted_cursor(session, decl_cursor):
        return "type " ++ ci_escape_reserved(synth_name) ++ " = opaque\n"

    let is_union = with_ci_cursor_kind(session, decl_cursor) == CK_UNION
    var nested_decls = ""
    var fields = ""
    var anon_idx = 0
    let nc = with_ci_num_children(session, decl_cursor)
    var field_count = 0
    var i = 0
    while i < nc:
        let child = with_ci_child(session, decl_cursor, i)
        if with_ci_cursor_kind(session, child) == CK_FIELD:
            let raw_name = with_ci_cursor_spelling(session, child)
            var actual_name = if raw_name.len() > 0: raw_name else: f"anon_{anon_idx}"
            var field_ty = with_ci_type_translated(session, with_ci_cursor_type(session, child))
            let anon_decl = ci_field_cursor_anon_record_decl(session, child)
            if anon_decl >= 0:
                let nested_name = if raw_name.len() > 0: synth_name ++ "_" ++ raw_name else: f"{synth_name}_anon_{anon_idx}"
                nested_decls = nested_decls ++ ci_translate_anon_record_cursor(session, anon_decl, nested_name)
                field_ty = ci_escape_reserved(nested_name)
                actual_name = if raw_name.len() > 0: raw_name else: f"anon_{anon_idx}"
                anon_idx = anon_idx + 1
            else if ci_starts_with(field_ty, "__UNSUPPORTED:") or field_ty == "c_void":
                return "type " ++ ci_escape_reserved(synth_name) ++ " = opaque\n"

            if field_count > 0:
                fields = fields ++ ", "
            let default_val = ci_default_for_type(field_ty)
            if default_val.len() > 0:
                fields = fields ++ ci_escape_reserved(actual_name) ++ ": " ++ field_ty ++ " = " ++ default_val
            else:
                fields = fields ++ ci_escape_reserved(actual_name) ++ ": " ++ field_ty
            field_count = field_count + 1
        i = i + 1

    if field_count == 0:
        if is_union:
            return nested_decls ++ "type " ++ ci_escape_reserved(synth_name) ++ " = union { __pad0: u8 = 0 }\n"
        return nested_decls ++ "type " ++ ci_escape_reserved(synth_name) ++ " { __pad0: u8 = 0 }\n"

    if is_union:
        return nested_decls ++ "type " ++ ci_escape_reserved(synth_name) ++ " = union { " ++ fields ++ " }\n"
    nested_decls ++ "type " ++ ci_escape_reserved(synth_name) ++ " { " ++ fields ++ " }\n"

// ── Opaque demotion pre-scan ─────────────────────────────────
// Two-pass analysis: first collect directly demoted types (bitfield, forward
// decl, unsupported fields), then cascade through field references until
// fixpoint. Follows Zig's approach where any struct embedding an opaque
// type is itself demoted to opaque.

fn ci_collect_demoted_types(session: i64, count: i32) -> str:
    // Pass 1: collect directly demoted structs/unions
    var demoted = ""
    var i = 0
    while i < count:
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_STRUCT or kind == CK_UNION:
            let name = with_cimport_decl_name(session, i)
            if name.len() > 0 and name.byte_at(0) != 95:
                if ci_is_directly_demoted(session, i, count):
                    demoted = demoted ++ "|" ++ name ++ "|"
        i = i + 1

    // Fixpoint: cascade demotions through field embedding
    var changed = true
    while changed:
        changed = false
        i = 0
        while i < count:
            let kind = with_cimport_decl_kind(session, i)
            if kind == CK_STRUCT or kind == CK_UNION:
                let name = with_cimport_decl_name(session, i)
                if name.len() > 0 and name.byte_at(0) != 95:
                    if not ci_str_contains(demoted, "|" ++ name ++ "|"):
                        if ci_has_demoted_field(session, i, demoted):
                            demoted = demoted ++ "|" ++ name ++ "|"
                            changed = true
            i = i + 1
    demoted

fn ci_is_directly_demoted(session: i64, idx: i32, count: i32) -> bool:
    // Forward declaration — don't demote if a concrete definition exists elsewhere in the TU.
    if with_cimport_struct_is_opaque(session, idx) != 0:
        let name = with_cimport_decl_name(session, idx)
        let is_union = with_cimport_decl_kind(session, idx) == CK_UNION
        if ci_record_definition_exists(session, name, is_union, count):
            return false
        return true
    let decl_cursor = ci_find_decl_cursor_for_idx(session, idx)
    let field_count = with_cimport_struct_field_count(session, idx)
    // Bitfield in any field
    var fi = 0
    while fi < field_count:
        if with_cimport_struct_field_is_bitfield(session, idx, fi) != 0:
            return true
        let field_cursor = ci_decl_field_cursor(session, decl_cursor, fi)
        let anon_decl = ci_field_cursor_anon_record_decl(session, field_cursor)
        if anon_decl >= 0:
            if ci_record_decl_directly_demoted_cursor(session, anon_decl):
                return true
        fi = fi + 1
    // Unsupported or opaque field type
    fi = 0
    while fi < field_count:
        let field_cursor = ci_decl_field_cursor(session, decl_cursor, fi)
        let anon_decl = ci_field_cursor_anon_record_decl(session, field_cursor)
        if anon_decl >= 0:
            fi = fi + 1
            continue
        let ft = with_cimport_struct_field_type_translated(session, idx, fi)
        if ci_starts_with(ft, "__UNSUPPORTED:"):
            return true
        if ft == "c_void":
            return true
        fi = fi + 1
    false

fn ci_has_demoted_field(session: i64, idx: i32, demoted: str) -> bool:
    if with_cimport_struct_is_opaque(session, idx) != 0:
        return false
    let decl_cursor = ci_find_decl_cursor_for_idx(session, idx)
    let field_count = with_cimport_struct_field_count(session, idx)
    var fi = 0
    while fi < field_count:
        let field_cursor = ci_decl_field_cursor(session, decl_cursor, fi)
        let anon_decl = ci_field_cursor_anon_record_decl(session, field_cursor)
        if anon_decl >= 0:
            if ci_record_decl_has_demoted_field_cursor(session, anon_decl, demoted):
                return true
        else:
            let ft = with_cimport_struct_field_type_translated(session, idx, fi)
            if ci_field_type_is_demoted(ft, demoted):
                return true
        fi = fi + 1
    false

fn ci_field_type_is_demoted(ftype: str, demoted: str) -> bool:
    if ftype.len() == 0:
        return false
    // Direct embedding: field type exactly matches a demoted name
    if ci_str_contains(demoted, "|" ++ ftype ++ "|"):
        return true
    // Array of demoted type: [N]DemotedName
    if ftype.byte_at(0) == 91:
        var i = 1
        while i < ftype.len() as i32:
            if ftype.byte_at(i as i64) == 93:
                let elem = ftype.slice(i as i64 + 1, ftype.len())
                if ci_str_contains(demoted, "|" ++ elem ++ "|"):
                    return true
                break
            i = i + 1
    // Pointer to demoted type is OK — pointers have fixed size
    false

// ── Function translation ────────────────────────────────────

fn ci_render_generated_fn_body(header: str, body: str) -> str:
    if migrate_prefer_brace():
        return header ++ " {\n" ++ body ++ "\n}"
    header ++ ":\n" ++ body

fn ci_param_signature_name(escaped: str, idx: i32) -> str:
    if escaped.len() > 0:
        return f"__param_{escaped}"
    f"p{idx}"

fn ci_param_local_name(escaped: str, idx: i32) -> str:
    if escaped.len() > 0:
        return f"__local_{escaped}"
    f"__local_p{idx}"

fn ci_local_storage_name(escaped: str, cursor: i32) -> str:
    if escaped.len() > 0:
        return f"__local_{escaped}"
    f"__local_{cursor}"

fn ci_translate_function(session: i64, idx: i32, known_structs: str) -> str:
    // B9: fresh per-function temp counter.
    ci_temp_reset()
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip internal names (starting with _)
    if name.byte_at(0) == 95:
        return ""

    // Skip already-emitted names (dedup across c_import calls)
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    // Skip static functions — no external linkage
    let storage = with_cimport_fn_storage_class(session, idx)
    let is_inline = with_cimport_fn_is_inline(session, idx)
    let needs_body_translation = (storage == CX_SC_STATIC and is_inline != 0) or (is_inline != 0 and storage != CX_SC_STATIC)
    if needs_body_translation:
        // Static inline or always-inline — try to translate the body
        let body = ci_try_translate_fn_body(session, idx)
        if body.len() > 0:
            let safe_name = ci_escape_reserved(name)
            with_cimport_mark_name_emitted(name)
            let si_param_count = with_cimport_fn_param_count(session, idx)
            var si_params = ""
            for spi in 0..si_param_count:
                if spi > 0:
                    si_params = si_params ++ ", "
                let spname = with_cimport_fn_param_name(session, idx, spi)
                let sptype = with_cimport_fn_param_type_translated(session, idx, spi)
                let actual_pname = ci_param_signature_name(ci_escape_reserved(spname), spi)
                si_params = si_params ++ actual_pname ++ ": " ++ sptype
            let si_ret = with_cimport_fn_return_type_translated(session, idx)
            return ci_render_generated_fn_body("fn " ++ safe_name ++ "(" ++ si_params ++ ") -> " ++ si_ret, body)
        // Fallback: demote to extern declaration (matching Zig's graceful demotion)
        // The function is still callable — just without the inline body.
        // Fall through to the normal extern fn emission below.
    if storage == CX_SC_STATIC and is_inline == 0:
        return ""

    let safe_name = ci_escape_reserved(name)
    let param_count = with_cimport_fn_param_count(session, idx)
    let is_variadic = with_cimport_fn_is_variadic(session, idx)

    // Check for unsupported types — emit comptime_error stub if found
    var has_unsupported = false
    var unsupported_reason = ""

    var params = ""
    for pi in 0..param_count:
        if pi > 0:
            params = params ++ ", "
        let pname = with_cimport_fn_param_name(session, idx, pi)
        let raw_ptype = with_cimport_fn_param_type_translated(session, idx, pi)
        let is_restrict = with_cimport_param_is_restrict(session, idx, pi)
        var ptype = ci_pointer_type_explicit_mut(raw_ptype)

        if ci_starts_with(ptype, "__UNSUPPORTED:"):
            has_unsupported = true
            unsupported_reason = ptype.slice(14, ptype.len())

        params = params ++ ci_param_signature_name(ci_escape_reserved(pname), pi) ++ ": " ++ ptype

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

    if has_unsupported:
        let fn_loc = ci_get_decl_location(session, name)
        let fn_loc_comment = if fn_loc.len() > 0: "// " ++ fn_loc ++ "\n" else: ""
        return fn_loc_comment ++ ci_render_generated_fn_body("fn " ++ safe_name ++ "() -> Never", "    comptime_error(\"untranslatable: " ++ unsupported_reason ++ "\")") ++ "\n"

    let cc = with_cimport_fn_calling_conv(session, idx)
    let cc_prefix = if cc != "c" and cc.len() > 0: "@[callconv(\"" ++ cc ++ "\")]\n" else: ""
    cc_prefix ++ "extern fn " ++ safe_name ++ "(" ++ params ++ ") -> " ++ ret ++ "\n"

// ── Member function detection (Zig-style) ───────────────────
// Scan all functions. If a function's first parameter is *StructType (pointer
// to a known struct), and the function name starts with StructName_ or
// structname_, emit a method wrapper: fn StructName.short_name(self, ...) = fn_name(self, ...)
fn ci_detect_member_functions(session: i64, count: i32, known_structs: str) -> str:
    var output = ""
    var emitted_methods = ""
    // Pre-compute snake_case prefixes for all known structs.
    // known_structs is pipe-delimited: "|Foo||Bar||Baz|"
    var struct_names: Vec[str] = Vec.new()
    var struct_prefixes: Vec[str] = Vec.new()
    var si = 0
    while si < known_structs.len() as i32:
        if known_structs.byte_at(si as i64) == 124:
            var se = si + 1
            while se < known_structs.len() as i32 and known_structs.byte_at(se as i64) != 124:
                se = se + 1
            if se > si + 1:
                let sname = known_structs.slice((si + 1) as i64, se as i64)
                struct_names.push(sname)
                struct_prefixes.push(ci_compute_snake_prefix(sname))
            si = se
        else:
            si = si + 1

    var i = 0
    while i < count:
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_FUNCTION:
            let name = with_cimport_decl_name(session, i)
            if name.len() > 0 and name.byte_at(0) != 95:
                let param_count = with_cimport_fn_param_count(session, i)
                let ret_type = with_cimport_fn_return_type_translated(session, i)
                // Try first-param-based matching (existing logic)
                var matched = false
                if param_count > 0:
                    let first_param_type = with_cimport_fn_param_type_translated(session, i, 0)
                    let struct_name = ci_extract_struct_name_from_ptr(first_param_type)
                    if struct_name.len() > 0 and ci_str_contains(known_structs, "|" ++ struct_name ++ "|"):
                        // Try snake_case prefix first, fall back to case-insensitive
                        var method_name = ""
                        var sj = 0
                        while sj < struct_names.len() as i32:
                            if struct_names.get(sj as i64) == struct_name:
                                method_name = ci_strip_snake_prefix(name, struct_prefixes.get(sj as i64))
                                break
                            sj = sj + 1
                        if method_name.len() == 0:
                            method_name = ci_strip_struct_prefix(name, struct_name)
                        if method_name.len() > 0:
                            let method_key = "|" ++ struct_name ++ "." ++ method_name ++ "|"
                            if not ci_str_contains(emitted_methods, method_key):
                                emitted_methods = emitted_methods ++ method_key
                                let wrapper = ci_emit_member_fn_wrapper(session, i, struct_name, method_name, first_param_type)
                                if wrapper.len() > 0:
                                    output = output ++ wrapper
                                    matched = true
                // Constructor detection: returns *S without self param
                if not matched:
                    let ret_struct = ci_extract_struct_name_from_ptr(ret_type)
                    if ret_struct.len() > 0 and ci_str_contains(known_structs, "|" ++ ret_struct ++ "|"):
                        var method_name = ""
                        var sj = 0
                        while sj < struct_names.len() as i32:
                            if struct_names.get(sj as i64) == ret_struct:
                                method_name = ci_strip_snake_prefix(name, struct_prefixes.get(sj as i64))
                                break
                            sj = sj + 1
                        if method_name.len() == 0:
                            method_name = ci_strip_struct_prefix(name, ret_struct)
                        if method_name.len() > 0:
                            let method_key = "|" ++ ret_struct ++ "." ++ method_name ++ "|"
                            if not ci_str_contains(emitted_methods, method_key):
                                emitted_methods = emitted_methods ++ method_key
                                let wrapper = ci_emit_constructor_wrapper(session, i, ret_struct, method_name)
                                if wrapper.len() > 0:
                                    output = output ++ wrapper
        i = i + 1
    output

// Extract struct name from pointer type: "*mut Foo" → "Foo", "*const Foo" → "Foo"
fn ci_extract_struct_name_from_ptr(ty: str) -> str:
    if ci_starts_with(ty, "*mut "):
        return ci_trim(ty.slice(5, ty.len()))
    if ci_starts_with(ty, "*const "):
        return ci_trim(ty.slice(7, ty.len()))
    if ci_starts_with(ty, "*"):
        return ci_trim(ty.slice(1, ty.len()))
    ""

// Compute snake_case prefix from a CamelCase struct name.
// GHashTable → "g_hash_table_", sqlite3 → "sqlite3_", SDL_Window → "sdl_window_"
fn ci_compute_snake_prefix(name: str) -> str:
    let len = name.len() as i32
    if len == 0:
        return ""
    var result = ""
    var prev_lower = false
    var prev_upper = false
    var i = 0
    while i < len:
        let ch = name.byte_at(i as i64)
        let is_upper = ch >= 65 and ch <= 90
        let is_lower_ch = ch >= 97 and ch <= 122
        let is_digit = ch >= 48 and ch <= 57
        if is_upper:
            if prev_lower:
                result = result ++ "_"
            else if prev_upper and i + 1 < len:
                let next = name.byte_at((i + 1) as i64)
                if next >= 97 and next <= 122:
                    if result.len() > 0:
                        result = result ++ "_"
            result = result ++ ci_char_lower(ch)
            prev_upper = true
            prev_lower = false
        else if is_lower_ch:
            result = result ++ name.slice(i as i64, (i + 1) as i64)
            prev_upper = false
            prev_lower = true
        else if is_digit:
            result = result ++ name.slice(i as i64, (i + 1) as i64)
            prev_upper = false
            prev_lower = false
        else if ch == 95:
            result = result ++ "_"
            prev_upper = false
            prev_lower = false
        else:
            result = result ++ name.slice(i as i64, (i + 1) as i64)
            prev_upper = false
            prev_lower = false
        i = i + 1
    result ++ "_"

fn ci_char_lower(ch: i32) -> str:
    if ch >= 65 and ch <= 90:
        return str_from_byte(ch + 32)
    str_from_byte(ch)

// Check if fn_name starts with the given snake_case prefix.
// Returns the method name (suffix after prefix) or "" if no match.
fn ci_strip_snake_prefix(fn_name: str, prefix: str) -> str:
    let plen = prefix.len() as i32
    let flen = fn_name.len() as i32
    if flen <= plen:
        return ""
    if fn_name.slice(0, plen as i64) == prefix:
        return fn_name.slice(plen as i64, flen as i64)
    ""

// Strip struct name prefix from function name.
// "MyStruct_init" with struct "MyStruct" → "init"
// "mystruct_init" with struct "MyStruct" → "init" (case-insensitive prefix match)
fn ci_strip_struct_prefix(fn_name: str, struct_name: str) -> str:
    let slen = struct_name.len() as i32
    let flen = fn_name.len() as i32
    // Need at least prefix + '_' + one char
    if flen <= slen + 1:
        return ""
    // Check for exact prefix match + '_'
    if fn_name.slice(0, slen as i64) == struct_name and fn_name.byte_at(slen as i64) == 95:
        return fn_name.slice((slen + 1) as i64, flen as i64)
    // Check for lowercase prefix match + '_'
    var matches = true
    var ci = 0
    while ci < slen:
        let fc = fn_name.byte_at(ci as i64)
        let sc = struct_name.byte_at(ci as i64)
        // Case-insensitive compare
        let fc_lower = if fc >= 65 and fc <= 90: fc + 32 else: fc
        let sc_lower = if sc >= 65 and sc <= 90: sc + 32 else: sc
        if fc_lower != sc_lower:
            matches = false
            break
        ci = ci + 1
    if matches and fn_name.byte_at(slen as i64) == 95:
        return fn_name.slice((slen + 1) as i64, flen as i64)
    ""

// Emit a method wrapper: fn StructName.method(self: *mut Struct, ...) -> Ret: fn_name(self, ...)
fn ci_emit_member_fn_wrapper(session: i64, idx: i32, struct_name: str, method_name: str, first_param_type: str) -> str:
    let fn_name = with_cimport_decl_name(session, idx)
    let safe_fn_name = ci_escape_reserved(fn_name)
    let safe_struct = ci_escape_reserved(struct_name)
    let safe_method = ci_escape_reserved(method_name)
    let param_count = with_cimport_fn_param_count(session, idx)
    let ret = ci_pointer_type_explicit_mut(with_cimport_fn_return_type_translated(session, idx))

    // Check for unsupported types — skip wrapper if so
    var pi = 0
    while pi < param_count:
        let pt = with_cimport_fn_param_type_translated(session, idx, pi)
        if ci_starts_with(pt, "__UNSUPPORTED:"):
            return ""
        pi = pi + 1
    if ci_starts_with(ret, "__UNSUPPORTED:"):
        return ""

    // Build parameter list: self + remaining params
    let self_type = ci_pointer_type_explicit_mut(first_param_type)
    var params = "self: " ++ self_type
    var call_args = "self"
    pi = 1
    while pi < param_count:
        let pname = with_cimport_fn_param_name(session, idx, pi)
        let ptype = ci_pointer_type_explicit_mut(with_cimport_fn_param_type_translated(session, idx, pi))
        let actual_name = if pname.len() > 0: ci_escape_reserved(pname) else: f"p{pi}"
        params = params ++ ", " ++ actual_name ++ ": " ++ ptype
        call_args = call_args ++ ", " ++ actual_name
        pi = pi + 1

    let ret_prefix = if ret == "void": "" else: "return "
    ci_render_generated_fn_body("fn " ++ safe_struct ++ "." ++ safe_method ++ "(" ++ params ++ ") -> " ++ ret, "    " ++ ret_prefix ++ safe_fn_name ++ "(" ++ call_args ++ ")") ++ "\n"

// Emit a constructor wrapper: fn StructName.new(params...) -> Ret: fn_name(params...)
fn ci_emit_constructor_wrapper(session: i64, idx: i32, struct_name: str, method_name: str) -> str:
    let fn_name = with_cimport_decl_name(session, idx)
    let safe_fn_name = ci_escape_reserved(fn_name)
    let safe_struct = ci_escape_reserved(struct_name)
    let safe_method = ci_escape_reserved(method_name)
    let param_count = with_cimport_fn_param_count(session, idx)
    let ret = ci_pointer_type_explicit_mut(with_cimport_fn_return_type_translated(session, idx))
    // Check for unsupported types
    var pi = 0
    while pi < param_count:
        let pt = with_cimport_fn_param_type_translated(session, idx, pi)
        if ci_starts_with(pt, "__UNSUPPORTED:"):
            return ""
        pi = pi + 1
    if ci_starts_with(ret, "__UNSUPPORTED:"):
        return ""
    // Build parameter list (no self — this is a static constructor)
    var params = ""
    var call_args = ""
    pi = 0
    while pi < param_count:
        let pname = with_cimport_fn_param_name(session, idx, pi)
        let ptype = ci_pointer_type_explicit_mut(with_cimport_fn_param_type_translated(session, idx, pi))
        let actual_name = if pname.len() > 0: ci_escape_reserved(pname) else: f"p{pi}"
        if pi > 0:
            params = params ++ ", "
            call_args = call_args ++ ", "
        params = params ++ actual_name ++ ": " ++ ptype
        call_args = call_args ++ actual_name
        pi = pi + 1
    ci_render_generated_fn_body("fn " ++ safe_struct ++ "." ++ safe_method ++ "(" ++ params ++ ") -> " ++ ret, "    " ++ safe_fn_name ++ "(" ++ call_args ++ ")") ++ "\n"

fn ci_pointer_type_explicit_mut(ty: str) -> str:
    if ci_starts_with(ty, "*const "):
        return ty
    if ci_starts_with(ty, "*mut "):
        return ty
    if ci_starts_with(ty, "*volatile "):
        return ty
    if ci_starts_with(ty, "*"):
        return "*mut " ++ ci_trim(ty.slice(1, ty.len()))
    ty

// ── Struct/Union translation ────────────────────────────────

fn ci_translate_struct(session: i64, idx: i32, is_union: bool, known_structs: str, demoted_types: str, count: i32) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip reserved C internal names (__foo or _Uppercase), keep _lowercase (e.g., _pcre2_*)
    if name.len() >= 2 and name.byte_at(0) == 95:
        let second = name.byte_at(1)
        if second == 95 or (second >= 65 and second <= 90):
            return ""

    // Skip already-emitted names
    // Note: structs shadowed by typedefs (typedef struct Foo {} Foo;) are NOT skipped.
    // The struct emits normally; the typedef detects the self-reference and skips.
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    // Skip forward declarations that have a definition elsewhere in the TU —
    // the definition cursor will be processed later with the actual fields.
    if with_cimport_struct_is_opaque(session, idx) != 0 and ci_record_definition_exists(session, name, is_union, count):
        return ""

    // Check if pre-scan marked this type as demoted (bitfield, forward decl,
    // unsupported field, or cascaded from a field whose type was demoted)
    if ci_str_contains(demoted_types, "|" ++ name ++ "|"):
        with_cimport_mark_name_emitted(name)
        let safe_name = ci_escape_reserved(name)
        let loc = ci_get_decl_location(session, name)
        let loc_comment = if loc.len() > 0: "// " ++ loc ++ ": demoted to opaque\n" else: ""
        let rendered = loc_comment ++ "type " ++ safe_name ++ " = opaque\n"
        if ci_migrate_shared_decl_add("type", name, rendered):
            return ""
        return rendered

    let field_count = with_cimport_struct_field_count(session, idx)
    if field_count == 0:
        // Empty struct definition → emit with padding byte for ABI compatibility
        with_cimport_mark_name_emitted(name)
        let safe_name = ci_escape_reserved(name)
        let empty_rendered = if is_union: "type " ++ safe_name ++ " = union \{ __pad0: u8 = 0 }\n" else: "type " ++ safe_name ++ " \{ __pad0: u8 = 0 }\n"
        if ci_migrate_shared_decl_add("type", name, empty_rendered):
            return ""
        return empty_rendered

    with_cimport_mark_name_emitted(name)
    let safe_name = ci_escape_reserved(name)
    let decl_cursor = ci_find_decl_cursor_for_idx(session, idx)

    // Emit anonymous sub-record types before the parent.
    // Naming: Parent_anon_N for unnamed fields, Parent_fieldname for named fields.
    var anon_decls = ""
    var anon_idx = 0
    var afi = 0
    while afi < field_count:
        let field_cursor = ci_decl_field_cursor(session, decl_cursor, afi)
        let anon_decl = ci_field_cursor_anon_record_decl(session, field_cursor)
        if anon_decl >= 0:
            let fname = with_cimport_struct_field_name(session, idx, afi)
            let synth_name = if fname.len() > 0: name ++ "_" ++ fname else: f"{name}_anon_{anon_idx}"
            anon_decls = anon_decls ++ ci_translate_anon_record_cursor(session, anon_decl, synth_name)
            anon_idx = anon_idx + 1
        afi = afi + 1

    // Build field list with per-field @[align(N)] annotations.
    // Compare each field's actual C offset against its natural alignment.
    // If a field is not naturally aligned, emit @[align(N)] before it.
    // Only fall back to @[packed]+padding for truly packed structs (align==1).
    let is_really_packed = with_cimport_struct_is_packed(session, idx) != 0
    var field_str = ""
    var anon_idx2 = 0
    var fi = 0
    while fi < field_count:
        if field_str.len() > 0:
            field_str = field_str ++ ", "

        // Compute per-field alignment annotation (non-packed non-union only)
        if not is_really_packed and not is_union:
            let align_n = ci_compute_field_alignment(session, idx, fi, field_count)
            if align_n > 0:
                field_str = field_str ++ f"@[align({align_n})] "

        let field_cursor = ci_decl_field_cursor(session, decl_cursor, fi)
        let anon_decl = ci_field_cursor_anon_record_decl(session, field_cursor)
        if anon_decl >= 0:
            let fname = with_cimport_struct_field_name(session, idx, fi)
            let synth_name = if fname.len() > 0: name ++ "_" ++ fname else: f"{name}_anon_{anon_idx2}"
            let actual_name = if fname.len() > 0: fname else: f"anon_{anon_idx2}"
            field_str = field_str ++ ci_escape_reserved(actual_name) ++ ": " ++ ci_escape_reserved(synth_name)
            anon_idx2 = anon_idx2 + 1
        else:
            field_str = field_str ++ ci_build_one_field(session, idx, fi, known_structs)
        fi = fi + 1

    // Detect flexible array member: last field is [0]T or [1]T (strict-flex-arrays=1)
    var flex_accessor = ""
    if field_count > 0 and not is_union:
        let last_ftype = with_cimport_struct_field_type_translated(session, idx, field_count - 1)
        if ci_starts_with(last_ftype, "[0]") or ci_starts_with(last_ftype, "[1]"):
            let elem_type = last_ftype.slice(3, last_ftype.len())
            let last_fname = with_cimport_struct_field_name(session, idx, field_count - 1)
            let accessor_name = if last_fname.len() > 0: last_fname else: "data"
            // Rename the field to _name in field_str by replacing the last occurrence
            field_str = ci_str_replace_last_field(field_str, ci_escape_reserved(accessor_name), "_" ++ ci_escape_reserved(accessor_name))
            // Emit accessor method
            let accessor_expr = "((&self._" ++ ci_escape_reserved(accessor_name) ++ ") as *" ++ elem_type ++ ")"
            let accessor_body = if migrate_prefer_brace(): "    unsafe { " ++ accessor_expr ++ " }" else: "    unsafe: " ++ accessor_expr
            flex_accessor = ci_render_generated_fn_body("fn " ++ ci_escape_reserved(accessor_name) ++ "(self: *" ++ safe_name ++ ") -> *" ++ elem_type, accessor_body) ++ "\n"

    let packed_prefix = if is_really_packed: "@[packed]\n" else: ""
    let part1 = "type " ++ safe_name
    let part2 = if is_union: part1 ++ " = union \{ " else: part1 ++ " \{ "
    let part3 = part2 ++ field_str
    let decl = part3 ++ " }\n"
    let rendered = anon_decls ++ packed_prefix ++ decl ++ flex_accessor
    if ci_migrate_shared_decl_add("type", name, rendered):
        return ""
    rendered

// Compute per-field alignment, ported from Zig's alignmentForField.
// Returns 0 if naturally aligned (no annotation needed), N if @[align(N)] needed.
fn ci_compute_field_alignment(session: i64, idx: i32, fi: i32, field_count: i32) -> i64:
    let field_offset = with_cimport_struct_field_offset(session, idx, fi)
    if field_offset < 0:
        return 0
    let field_size = with_cimport_struct_field_size(session, idx, fi)
    let natural_align = with_cimport_struct_field_align(session, idx, fi)
    if natural_align <= 0:
        return 0
    let parent_align = with_cimport_struct_align(session, idx)
    if parent_align <= 0:
        return 0
    // Zero-width fields always have alignment 1
    if field_size == 0:
        return 1
    // Fields at offset 0: check if struct pointer alignment differs from
    // max field natural alignment (headFieldAlignment from Zig)
    if field_offset == 0:
        return ci_head_field_alignment(session, idx, field_count, parent_align)
    // Check remainder: offset % natural_align
    let remainder = field_offset % natural_align
    if remainder > 0:
        if ci_is_power_of_two(remainder):
            let actual = if remainder < parent_align: remainder else: parent_align
            return actual
        return 1
    // Field is positioned at a naturally-aligned offset, but parent's pointer
    // alignment determines the actual alignment
    let possible = if parent_align < field_offset: parent_align else: field_offset
    if possible == natural_align:
        return 0
    if possible < natural_align:
        if ci_is_power_of_two(possible):
            return possible
        return 1
    // possible > natural_align — check padding from previous field
    if fi > 0:
        let prev_offset = with_cimport_struct_field_offset(session, idx, fi - 1)
        let prev_size = with_cimport_struct_field_size(session, idx, fi - 1)
        if prev_offset >= 0 and prev_size >= 0:
            let padding = (field_offset - prev_offset) - prev_size
            if padding < natural_align:
                return 0
            return possible
    0

fn ci_head_field_alignment(session: i64, idx: i32, field_count: i32, parent_align: i64) -> i64:
    var max_field_align: i64 = 0
    var fi = 0
    while fi < field_count:
        let fa = with_cimport_struct_field_align(session, idx, fi)
        if fa > max_field_align:
            max_field_align = fa
        fi = fi + 1
    if max_field_align != parent_align:
        return parent_align
    0

fn ci_is_power_of_two(n: i64) -> bool:
    n > 0 and (n & (n - 1)) == 0

fn ci_estimate_type_size(ty: str) -> i64:
    if ty == "i8" or ty == "u8" or ty == "bool" or ty == "c_char": return 1
    if ty == "i16" or ty == "u16" or ty == "c_short" or ty == "c_ushort": return 2
    if ty == "i32" or ty == "u32" or ty == "f32" or ty == "c_int" or ty == "c_uint": return 4
    if ty == "i64" or ty == "u64" or ty == "f64" or ty == "isize" or ty == "usize": return 8
    if ty == "c_long" or ty == "c_ulong" or ty == "c_longlong" or ty == "c_ulonglong": return 8
    if ty == "c_longdouble": return 8
    if ty == "i128" or ty == "u128": return 16
    if ci_starts_with(ty, "*"): return 8
    if ci_starts_with(ty, "Option["): return 8
    8  // default assumption

fn ci_build_struct_fields(session: i64, idx: i32, field_count: i32, known_structs: str) -> str:
    if field_count == 0:
        return ""
    if field_count == 1:
        return ci_build_one_field(session, idx, 0, known_structs)
    // Build fields iteratively using a helper to avoid mutable var in loop
    var result = ci_build_one_field(session, idx, 0, known_structs)
    var fi = 1
    while fi < field_count:
        result = result ++ ", " ++ ci_build_one_field(session, idx, fi, known_structs)
        fi = fi + 1
    result

fn ci_build_one_field(session: i64, idx: i32, fi: i32, known_structs: str) -> str:
    let fname = with_cimport_struct_field_name(session, idx, fi)
    let ftype = with_cimport_struct_field_type_translated(session, idx, fi)
    let actual_name = if fname.len() == 0: f"unnamed_{fi}" else: fname
    let safe_fname = ci_escape_reserved(actual_name)
    let default_val = ci_default_for_type(ftype)
    if default_val.len() > 0:
        safe_fname ++ ": " ++ ftype ++ " = " ++ default_val
    else:
        safe_fname ++ ": " ++ ftype

fn ci_default_for_type(ty: str) -> str:
    if ty == "i8" or ty == "u8" or ty == "i16" or ty == "u16": return "0"
    if ty == "i32" or ty == "u32" or ty == "i64" or ty == "u64": return "0"
    if ty == "i128" or ty == "u128" or ty == "isize" or ty == "usize": return "0"
    if ty == "c_char" or ty == "c_short" or ty == "c_ushort": return "0"
    if ty == "c_int" or ty == "c_uint": return "0"
    if ty == "c_long" or ty == "c_ulong": return "0"
    if ty == "c_longlong" or ty == "c_ulonglong": return "0"
    if ty == "f32" or ty == "f64": return "0.0"
    if ty == "c_longdouble": return "0.0"
    if ty == "bool": return "false"
    // Pointer types → null (matching Zig's createZeroValueNode)
    if ci_starts_with(ty, "*"): return "null"
    if ci_starts_with(ty, "Option["): return "null"
    // Enum type aliases (emitted by c_import as `type Foo = c_int/c_uint`) → 0
    // But NOT struct types — those need struct-literal defaults, not integer 0.
    // Check: if the type resolves to a primitive int alias, use 0.
    // Otherwise leave empty (no default) for struct/union/opaque types.
    if ci_starts_with(ty, "Vector("): return ""
    // Array types [N]T → emit [0 as T; N]
    if ty.len() > 0 and ty.byte_at(0) == 91:
        // Parse [N]T to get element type and count
        var close = 1
        while close as i64 < ty.len() and ty.byte_at(close as i64) != 93:
            close = close + 1
        if close as i64 < ty.len():
            let count = ty.slice(1, close as i64)
            let elem = ty.slice((close + 1) as i64, ty.len())
            let elem_default = ci_default_for_type(elem)
            if elem_default.len() > 0:
                return "[" ++ elem_default ++ " as " ++ elem ++ "; " ++ count ++ "]"
        return ""
    // Unknown types (struct/union/opaque) — no safe default
    ""

// ── Enum translation ────────────────────────────────────────

fn ci_translate_enum(session: i64, idx: i32) -> str:
    let const_count = with_cimport_enum_const_count(session, idx)
    if const_count == 0:
        // Forward-declared enum with no constants → emit as opaque
        let fwd_name = with_cimport_decl_name(session, idx)
        if fwd_name.len() > 0 and fwd_name.byte_at(0) != 95 and not ci_str_contains(fwd_name, "(unnamed") and not ci_str_contains(fwd_name, "(anonymous"):
            if with_cimport_is_name_emitted(fwd_name) == 0:
                with_cimport_mark_name_emitted(fwd_name)
                let enum_loc = ci_get_decl_location(session, fwd_name)
                let enum_loc_comment = if enum_loc.len() > 0: "// " ++ enum_loc ++ ": forward-declared enum\n" else: ""
                let fwd_rendered = enum_loc_comment ++ "type " ++ ci_escape_reserved(fwd_name) ++ " = opaque\n"
                if ci_migrate_shared_decl_add("type", fwd_name, fwd_rendered):
                    return ""
                return fwd_rendered
        return ""

    // Determine the integer type for this enum
    let int_type_raw = with_cimport_enum_int_type(session, idx)
    let int_type = ci_map_c_type(int_type_raw)

    var output = ""

    // Emit type alias for named enums (skip anonymous enums with synthetic names)
    let enum_name = with_cimport_decl_name(session, idx)
    let is_anonymous = enum_name.len() == 0 or enum_name.byte_at(0) == 95 or ci_str_contains(enum_name, "(unnamed") or ci_str_contains(enum_name, "(anonymous")
    if not is_anonymous:
        if with_cimport_is_name_emitted(enum_name) == 0:
            let safe_enum_name = ci_escape_reserved(enum_name)
            with_cimport_mark_name_emitted(enum_name)
            let type_line = "type " ++ safe_enum_name ++ " = " ++ int_type ++ "\n"
            if not ci_migrate_shared_decl_add("type", enum_name, type_line):
                output = output ++ type_line

    for ci in 0..const_count:
        let cname = with_cimport_enum_const_name(session, idx, ci)
        let cvalue = with_cimport_enum_const_value(session, idx, ci)
        if cname.len() == 0:
            continue
        // Skip internal names
        if cname.byte_at(0) == 95:
            continue
        // Mangle colliding enum constant names instead of skipping
        let unique_cname = ci_unique_name(cname)
        with_cimport_mark_name_emitted(unique_cname)
        let safe_cname = ci_escape_reserved(unique_cname)
        let let_line = f"let {safe_cname}: {int_type} = {cvalue}"
        if not ci_migrate_shared_decl_add("let", safe_cname, let_line):
            output = output ++ let_line ++ "\n"
    output

// ── Variable translation ────────────────────────────────────

fn ci_translate_var(session: i64, idx: i32, known_structs: str) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip reserved C internal names (__foo or _Uppercase), keep _lowercase (e.g., _pcre2_*)
    if name.len() >= 2 and name.byte_at(0) == 95:
        let second = name.byte_at(1)
        if second == 95 or (second >= 65 and second <= 90):
            return ""

    // Skip already-emitted names
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    let var_type = with_cimport_var_type_translated(session, idx)

    // Unsupported type — emit comptime_error stub
    if ci_starts_with(var_type, "__UNSUPPORTED:"):
        let reason = var_type.slice(14, var_type.len())
        let safe_name = ci_escape_reserved(name)
        with_cimport_mark_name_emitted(name)
        let var_loc = ci_get_decl_location(session, name)
        let var_loc_comment = if var_loc.len() > 0: "// " ++ var_loc ++ "\n" else: ""
        return var_loc_comment ++ ci_render_generated_fn_body("fn " ++ safe_name ++ "() -> Never", "    comptime_error(\"untranslatable: " ++ reason ++ "\")") ++ "\n"

    let is_const = with_cimport_var_is_const(session, idx)
    let is_threadlocal = with_cimport_var_is_threadlocal(session, idx)
    let safe_name = ci_escape_reserved(name)
    with_cimport_mark_name_emitted(name)

    // Convert incomplete arrays ([0]T) to pointer types
    var actual_type = var_type
    if ci_starts_with(var_type, "[0]"):
        actual_type = "*mut " ++ var_type.slice(3, var_type.len())

    let tl_attr = if is_threadlocal != 0: "@[threadlocal]\n" else: ""

    // For const variables, try to evaluate the initializer
    if is_const != 0:
        let init_val = ci_try_eval_var_init_for_type(session, idx, actual_type)
        if init_val.len() > 0:
            return tl_attr ++ "let " ++ safe_name ++ ": " ++ actual_type ++ " = " ++ init_val ++ "\n"
        // const without initializer is always extern (defined elsewhere)
        tl_attr ++ "extern let " ++ safe_name ++ ": " ++ actual_type ++ "\n"
    else:
        if g_migrate_no_c_export != 0:
            let init_val = ci_try_eval_var_init_for_type(session, idx, actual_type)
            if init_val.len() > 0:
                return tl_attr ++ "var " ++ safe_name ++ ": " ++ actual_type ++ " = " ++ init_val ++ "\n"
        // --no-c-export: mutable vars are module-local definitions
        let var_kw = if g_migrate_no_c_export != 0: "var " else: "extern var "
        tl_attr ++ var_kw ++ safe_name ++ ": " ++ actual_type ++ "\n"


// ── Typedef translation ─────────────────────────────────────

fn ci_map_builtin_typedef(name: str) -> str:
    if name == "uint8_t": return "u8"
    if name == "int8_t": return "i8"
    if name == "uint16_t": return "u16"
    if name == "int16_t": return "i16"
    if name == "uint32_t": return "u32"
    if name == "int32_t": return "i32"
    if name == "uint64_t": return "u64"
    if name == "int64_t": return "i64"
    if name == "__uint128_t": return "u128"
    if name == "__int128_t": return "i128"
    if name == "size_t": return "usize"
    if name == "ssize_t": return "isize"
    if name == "uintptr_t": return "usize"
    if name == "intptr_t": return "isize"
    if name == "ptrdiff_t": return "isize"
    if name == "pid_t": return "i32"
    if name == "uid_t": return "u32"
    if name == "gid_t": return "u32"
    if name == "mode_t": return "u16"
    if name == "off_t": return "i64"
    if name == "time_t": return "i64"
    if name == "wchar_t": return "i32"
    if name == "va_list": return "opaque"
    ""

fn ci_normalize_translated_type_name(name: str) -> str:
    let t = ci_trim(name)
    let builtin = ci_map_builtin_typedef(t)
    if builtin.len() > 0:
        return builtin
    let alias = ci_lookup_known(t, g_macro_type_aliases)
    if alias.len() > 0 and alias != t:
        let alias_builtin = ci_map_builtin_typedef(alias)
        if alias_builtin.len() > 0:
            return alias_builtin
        return alias
    t

fn ci_translate_typedef(session: i64, idx: i32, count: i32) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip reserved C internal names (__foo or _Uppercase), keep _lowercase (e.g., _pcre2_*)
    if name.len() >= 2 and name.byte_at(0) == 95:
        let second = name.byte_at(1)
        if second == 95 or (second >= 65 and second <= 90):
            return ""

    // Skip already-emitted names
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    // Check builtin typedef map first (short-circuits common types)
    let mapped = ci_map_builtin_typedef(name)
    if mapped.len() > 0:
        let safe_name = ci_escape_reserved(name)
        with_cimport_mark_name_emitted(name)
        let rendered = "type " ++ safe_name ++ " = " ++ mapped ++ "\n"
        if ci_migrate_shared_decl_add("type", name, rendered):
            return ""
        return rendered

    // Check if typedef aliases an anonymous struct/union — inline its fields
    let anon_field_count = with_cimport_typedef_anon_record_field_count(session, idx)
    if anon_field_count > 0:
        let anon_safe_name = ci_escape_reserved(name)
        // Check for bitfields or unsupported field types → demote to opaque
        var anon_has_bitfield = false
        var anon_has_unsupported = false
        var afi = 0
        while afi < anon_field_count:
            if with_cimport_typedef_anon_field_is_bitfield(session, idx, afi) != 0:
                anon_has_bitfield = true
            let ft = with_cimport_typedef_anon_field_type(session, idx, afi)
            if ci_starts_with(ft, "__UNSUPPORTED:") or ft == "c_void":
                anon_has_unsupported = true
            afi = afi + 1
        if anon_has_bitfield or anon_has_unsupported:
            with_cimport_mark_name_emitted(name)
            let opaque_rendered = "type " ++ anon_safe_name ++ " = opaque\n"
            if ci_migrate_shared_decl_add("type", name, opaque_rendered):
                return ""
            return opaque_rendered
        // Build field list
        var fields = ""
        afi = 0
        while afi < anon_field_count:
            if afi > 0:
                fields = fields ++ ", "
            let fname = with_cimport_typedef_anon_field_name(session, idx, afi)
            let ftype = with_cimport_typedef_anon_field_type(session, idx, afi)
            let actual_fname = if fname.len() == 0: f"unnamed_{afi}" else: fname
            let default_val = ci_default_for_type(ftype)
            if default_val.len() > 0:
                fields = fields ++ ci_escape_reserved(actual_fname) ++ ": " ++ ftype ++ " = " ++ default_val
            else:
                fields = fields ++ ci_escape_reserved(actual_fname) ++ ": " ++ ftype
            afi = afi + 1
        with_cimport_mark_name_emitted(name)
        let anon_rendered = if with_cimport_typedef_anon_is_union(session, idx) != 0:
            "type " ++ anon_safe_name ++ " = union \{ " ++ fields ++ " }\n"
        else:
            "type " ++ anon_safe_name ++ " \{ " ++ fields ++ " }\n"
        if ci_migrate_shared_decl_add("type", name, anon_rendered):
            return ""
        return anon_rendered

    // Use the recursive type translator for the underlying type
    let translated = with_cimport_typedef_underlying_translated(session, idx)
    let underlying = with_cimport_typedef_underlying(session, idx)

    // Unsupported underlying type — skip the typedef
    if ci_starts_with(translated, "__UNSUPPORTED:"):
        return ""

    // Don't emit trivial identity typedefs (typedef int → i32, but name isn't special)
    if translated == "i32":
        // Only emit if we know the underlying is actually an interesting type
        if not ci_is_known_base_type(underlying):
            if not ci_starts_with(underlying, "struct ") and not ci_starts_with(underlying, "union ") and not ci_starts_with(underlying, "enum "):
                return ""

    // If translated type name equals the typedef name (typedef struct Foo {} Foo;),
    // the typedef is redundant — the struct body was already emitted or needs
    // to be emitted under this name. Skip the self-referential alias.
    if translated == name or translated == ci_escape_reserved(name):
        let is_forward_struct = ci_starts_with(underlying, "struct ")
        let is_forward_union = ci_starts_with(underlying, "union ")
        if is_forward_struct or is_forward_union:
            if not ci_record_definition_exists(session, name, is_forward_union, count):
                let safe_name = ci_escape_reserved(name)
                with_cimport_mark_name_emitted(name)
                let rendered = "type " ++ safe_name ++ " = opaque\n"
                if ci_migrate_shared_decl_add("type", name, rendered):
                    return ""
                return rendered
        // The struct was shadowed, so emit nothing — the typedef name IS the struct.
        // Mark as emitted so nothing else: claims it.
        with_cimport_mark_name_emitted(name)
        return ""

    let safe_name = ci_escape_reserved(name)
    with_cimport_mark_name_emitted(name)
    let rendered = "type " ++ safe_name ++ " = " ++ translated ++ "\n"
    if ci_migrate_shared_decl_add("type", name, rendered):
        return ""
    rendered

// ── Macro translation ───────────────────────────────────────

fn ci_collect_object_macro_type_map(session: i64, macro_source: str) -> str:
    if macro_source.len() == 0:
        return ""
    let count = with_cimport_macro_count(session)
    var names = ""
    var i = 0
    while i < count:
        if with_cimport_macro_is_fn_like(session, i) == 0:
            let name = with_cimport_macro_name(session, i)
            let value = with_cimport_macro_value(session, i)
            if name.len() > 0 and name.byte_at(0) != 95 and value.len() > 0:
                names = names ++ "|" ++ name ++ "|"
        i = i + 1
    if names.len() == 0:
        return ""
    with_cimport_collect_object_macro_types(macro_source, names)

fn ci_collect_object_macro_values(session: i64) -> str:
    let count = with_cimport_macro_count(session)
    var values = ""
    for i in 0..count:
        if with_cimport_macro_is_fn_like(session, i) != 0:
            continue
        let name = with_cimport_macro_name(session, i)
        let value = with_cimport_macro_value(session, i)
        if name.len() == 0 or value.len() == 0 or value == name:
            continue
        if ci_str_contains(value, "|"):
            continue
        values = values ++ "|" ++ name ++ "=" ++ value
    values

fn ci_offsetof_record_type_name(raw_type: str) -> str:
    let t = ci_trim(raw_type)
    if ci_starts_with(t, "struct "):
        return ci_trim(t.slice(7, t.len()))
    if ci_starts_with(t, "union "):
        return ci_trim(t.slice(6, t.len()))
    t

fn ci_try_translate_offsetof_expr(session: i64, expr: str) -> str:
    let t = ci_trim(ci_strip_parens(expr))
    var fn_name = ""
    var args = ""
    var call_paren = 0
    while call_paren < t.len() as i32 and t.byte_at(call_paren as i64) != 40:
        call_paren = call_paren + 1
    if call_paren > 0 and call_paren < t.len() as i32:
        fn_name = ci_trim(t.slice(0, call_paren as i64))
        let close_paren = ci_find_matching_paren(t, call_paren)
        if close_paren == t.len() as i32 - 1 and t.len() > call_paren as i64 + 1:
            args = t.slice(call_paren as i64 + 1, t.len() - 1)
    if fn_name != "offsetof" and fn_name != "__builtin_offsetof":
        return ""
    let type_arg = ci_offsetof_record_type_name(ci_extract_first_arg(args))
    let field_arg = ci_trim(ci_after_first_arg(args))
    if type_arg.len() == 0 or field_arg.len() == 0:
        return ""
    let offset = with_cimport_record_field_offset_by_name(session, type_arg, field_arg)
    if offset < 0:
        return ""
    i64_to_string(offset)

fn ci_translate_macros(session: i64, type_session: i64, extern_vars: str, macro_source: str) -> str:
    let count = with_cimport_macro_count(session)
    var output = ""
    var known_values = ""
    var blank_macros = ""
    let object_macro_types = ci_collect_object_macro_type_map(session, macro_source)
    for i in 0..count:
        let name = with_cimport_macro_name(session, i)
        let value = with_cimport_macro_value(session, i)
        let fn_like = with_cimport_macro_is_fn_like(session, i)

        // Skip self-defined macros: #define FOO FOO (common feature-test pattern)
        if fn_like == 0 and value == name:
            continue

        // C2: skip width-family macros when width slicing is active
        if ci_migrate_is_width_family_name(name):
            continue

        // Try to translate function-like macros; record explicit omissions
        // instead of emitting placeholder functions.
        if fn_like != 0:
            if ci_libc_symbol_allowed_as(name, CI_LIBC_KIND_FN):
                continue
            if ci_is_implicit_compiler_macro(name):
                continue
            if name.len() > 0 and name.byte_at(0) != 95:
                if with_cimport_is_name_emitted(name) == 0:
                    with_cimport_mark_name_emitted(name)
                    let safe_name = ci_escape_reserved(name)
                    let param_count = with_cimport_macro_param_count(session, i)
                    // Detect variadic macros (... params or __VA_ARGS__ in body)
                    var is_variadic_macro = ci_str_contains(value, "__VA_ARGS__")
                    var vpi = 0
                    while vpi < param_count:
                        let vpname = with_cimport_macro_param_name(session, i, vpi)
                        if vpname == "..." or vpname == "__VA_ARGS__":
                            is_variadic_macro = true
                        vpi = vpi + 1
                    if is_variadic_macro:
                        ci_record_untranslated_macro(name)
                        continue
                    // Detect cleanup attribute macros
                    if ci_str_contains(value, "__attribute__((cleanup"):
                        ci_record_untranslated_macro(name)
                        continue
                    // Empty function-like macro: #define FOO(x) → void function
                    if ci_trim(value).len() == 0:
                        var empty_params = ""
                        var epi = 0
                        while epi < param_count:
                            if epi > 0:
                                empty_params = empty_params ++ ", "
                            let epname = ci_escape_reserved(with_cimport_macro_param_name(session, i, epi))
                            empty_params = empty_params ++ epname ++ ": i32"
                            epi = epi + 1
                        let r = ci_render_generated_fn_body("fn " ++ safe_name ++ "(" ++ empty_params ++ ") -> void", "    return")
                        if not ci_migrate_shared_decl_add("fn", safe_name, r):
                            output = output ++ r ++ "\n"
                        continue
                    // Build pipe-delimited param string: "|a|b|c|"
                    var param_names = ""
                    var param_decl = ""
                    var type_params = ""
                    var pi = 0
                    while pi < param_count:
                        let pname = ci_escape_reserved(with_cimport_macro_param_name(session, i, pi))
                        param_names = param_names ++ "|" ++ pname ++ "|"
                        if pi > 0:
                            param_decl = param_decl ++ ", "
                        param_decl = param_decl ++ pname ++ ": T"
                        pi = pi + 1
                    var ret_type = "i32"
                    if param_count > 0:
                        type_params = "[T]"
                        ret_type = "T"
                    // Try pattern matching before expression translation
                    var translated = ""

                    // Strip __extension__ wrapper (glibc uses this)
                    var work_value = value
                    if ci_starts_with(work_value, "__extension__"):
                        work_value = ci_trim(work_value.slice(13, work_value.len()))
                    if ci_starts_with(work_value, "(__extension__"):
                        work_value = "(" ++ ci_trim(work_value.slice(14, work_value.len()))

                    // Identity macro: #define CLITERAL(type) (type)
                    if translated.len() == 0 and param_count == 1:
                        let original_param = with_cimport_macro_param_name(session, i, 0)
                        let safe_param = ci_escape_reserved(original_param)
                        let stripped_identity = ci_strip_parens(ci_trim(work_value))
                        if stripped_identity == original_param:
                            let r = ci_render_generated_fn_body("fn " ++ safe_name ++ "[T](" ++ safe_param ++ ": T) -> T", "    " ++ safe_param)
                            if not ci_migrate_shared_decl_add("fn", safe_name, r):
                                output = output ++ r ++ "\n"
                            continue

                    // DISCARD pattern: (void)(X) or ((void)(X)) — discard value
                    if ci_is_discard_pattern(work_value, param_names):
                        translated = ci_translate_discard_pattern(work_value, param_names, known_values)
                    // (void)0 sentinel pattern (assert/NDEBUG)
                    if translated.len() == 0:
                        let stripped_v = ci_strip_parens(ci_trim(work_value))
                        if stripped_v == "(void)0" or stripped_v == "((void)0)":
                            translated = "0"
                    // Stringification: #param in body
                    if translated.len() == 0 and ci_has_stringify(work_value, param_names):
                        // Simple #x → identity function (returns the string of the expression)
                        if param_count == 1:
                            let p0 = ci_escape_reserved(with_cimport_macro_param_name(session, i, 0))
                            let body_trimmed = ci_trim(work_value)
                            if body_trimmed == "#" ++ p0 or body_trimmed == "(#" ++ p0 ++ ")":
                                let r = ci_render_generated_fn_body("fn " ++ safe_name ++ "(x: str) -> str", "    x")
                                if not ci_migrate_shared_decl_add("fn", safe_name, r):
                                    output = output ++ r ++ "\n"
                                continue
                        ci_record_untranslated_macro(name)
                        continue
                    // Token paste (##) translation
                    if translated.len() == 0 and ci_str_contains(work_value, "##"):
                        translated = ci_try_translate_token_paste(work_value, param_names)
                    if translated.len() == 0:
                        translated = ci_translate_c_expr(work_value, param_names, known_values)
                    if translated.len() > 0:
                        // Infer return type from cast expression: (x as c_int) → return c_int
                        var inferred_ret = ret_type
                        if ci_starts_with(translated, "with_free("):
                            inferred_ret = "void"
                        else if param_count > 0:
                            let cast_type = ci_infer_cast_return_type(translated)
                            if cast_type.len() > 0:
                                inferred_ret = cast_type
                        let r = ci_render_generated_fn_body("fn " ++ safe_name ++ type_params ++ "(" ++ param_decl ++ ") -> " ++ inferred_ret, "    " ++ translated)
                        if not ci_migrate_shared_decl_add("fn", safe_name, r):
                            output = output ++ r ++ "\n"
                    else:
                        ci_record_untranslated_macro(name)
            continue

        // Skip empty macros (flag defines) and track as blank
        if value.len() == 0:
            blank_macros = blank_macros ++ "|" ++ name ++ "|"
            continue

        // Skip internal names
        if name.len() == 0:
            continue
        if name.byte_at(0) == 95:
            continue

        // Detect macros whose value only references other blank macros
        if ci_is_blank_macro_ref(value, blank_macros):
            blank_macros = blank_macros ++ "|" ++ name ++ "|"
            continue

        // Skip already-emitted names (dedup across c_import calls)
        if with_cimport_is_name_emitted(name) != 0:
            continue

        // Strip __extension__ wrapper (glibc)
        var obj_value = value
        if ci_starts_with(obj_value, "__extension__"):
            obj_value = ci_trim(obj_value.slice(13, obj_value.len()))
        // Strip outer parentheses for macro values like (-1)
        let stripped = ci_strip_parens(obj_value)

        if ci_is_int_literal(stripped):
            let safe_name = ci_escape_reserved(name)
            let int_ty = ci_int_type_from_suffix(stripped)
            let clean_value = ci_strip_int_suffix(stripped)
            with_cimport_mark_name_emitted(name)
            known_values = known_values ++ name ++ "=" ++ clean_value ++ "|"
            let let_line = "let " ++ safe_name ++ ": " ++ int_ty ++ " = " ++ clean_value
            if not ci_migrate_shared_decl_add("let", safe_name, let_line):
                output = output ++ let_line ++ "\n"
        else if ci_is_char_literal(stripped):
            let char_val = ci_char_to_int(stripped)
            if char_val.len() > 0:
                let safe_name = ci_escape_reserved(name)
                with_cimport_mark_name_emitted(name)
                known_values = known_values ++ name ++ "=" ++ char_val ++ "|"
                let let_line = "let " ++ safe_name ++ ": c_int = " ++ char_val
                if not ci_migrate_shared_decl_add("let", safe_name, let_line):
                    output = output ++ let_line ++ "\n"
        else if ci_is_float_literal(stripped):
            let safe_name = ci_escape_reserved(name)
            let float_ty = ci_float_type_from_suffix(stripped)
            let clean_value = ci_strip_float_suffix(stripped)
            with_cimport_mark_name_emitted(name)
            let let_line = "let " ++ safe_name ++ ": " ++ float_ty ++ " = " ++ clean_value
            if not ci_migrate_shared_decl_add("let", safe_name, let_line):
                output = output ++ let_line ++ "\n"
        else if ci_is_concatenated_string(stripped) or ci_is_string_literal(stripped):
            let safe_name = ci_escape_reserved(name)
            let concat_value = ci_concat_strings(stripped)
            with_cimport_mark_name_emitted(name)
            let let_line = "let " ++ safe_name ++ " = " ++ concat_value
            if not ci_migrate_shared_decl_add("let", safe_name, let_line):
                output = output ++ let_line ++ "\n"
        else:
            let offsetof_result = ci_try_translate_offsetof_expr(type_session, stripped)
            let cast_expr_result = if offsetof_result.len() > 0: offsetof_result else: ci_translate_c_expr(stripped, "", known_values)
            let semantic_expr_ty = ci_lookup_known(name, object_macro_types)
            var cast_expr_ty = ""
            if offsetof_result.len() > 0:
                cast_expr_ty = "c_int"
            else if semantic_expr_ty.len() > 0:
                cast_expr_ty = semantic_expr_ty
            else:
                cast_expr_ty = ci_infer_cast_return_type(cast_expr_result)
            if cast_expr_result.len() > 0 and cast_expr_ty.len() > 0:
                let safe_name = ci_escape_reserved(name)
                with_cimport_mark_name_emitted(name)
                let let_line = "let " ++ safe_name ++ ": " ++ cast_expr_ty ++ " = " ++ cast_expr_result
                if not ci_migrate_shared_decl_add("let", safe_name, let_line):
                    output = output ++ let_line ++ "\n"
            else:
                let eval_result = ci_eval_const_expr_ctx(stripped, known_values)
                if eval_result.len() > 0:
                    let safe_name = ci_escape_reserved(name)
                    with_cimport_mark_name_emitted(name)
                    known_values = known_values ++ name ++ "=" ++ eval_result ++ "|"
                    let let_line = "let " ++ safe_name ++ ": c_int = " ++ eval_result
                    if not ci_migrate_shared_decl_add("let", safe_name, let_line):
                        output = output ++ let_line ++ "\n"
                else:
                    // Try expression translation — may reference extern vars
                    let expr_result = cast_expr_result
                    if expr_result.len() > 0:
                        let safe_name = ci_escape_reserved(name)
                        with_cimport_mark_name_emitted(name)
                        let expr_ty = if cast_expr_ty.len() > 0: cast_expr_ty else: "c_int"
                        if ci_expr_references_var(expr_result, extern_vars):
                            // References a mutable extern var — emit as function
                            output = output ++ ci_render_generated_fn_body("fn " ++ safe_name ++ "() -> " ++ expr_ty, "    " ++ expr_result) ++ "\n"
                        else:
                            let let_line = "let " ++ safe_name ++ ": " ++ expr_ty ++ " = " ++ expr_result
                            if not ci_migrate_shared_decl_add("let", safe_name, let_line):
                                output = output ++ let_line ++ "\n"
    g_macro_type_names = ""
    g_macro_type_aliases = ""
    output

// ── C expression → With source translator ────────────────────
// Translates a C macro body to With source code.
// params: pipe-delimited parameter names "|a|b|"
// known: pipe-delimited known constant values "NAME=val|"
// Returns "" on failure (triggers comptime_error fallback).

// ── Recursive descent C expression parser ──────────────────────────
// Follows Zig's MacroTranslator precedence structure exactly:
//   cond_expr → or → and → bit_or → bit_xor → bit_and →
//   eq → rel → shift → add → mul → cast → unary → postfix → primary
//
// Each level finds its own operators at paren depth 0,
// splitting into LHS (already parsed at this level) and
// RHS (parsed at the next higher precedence level).

fn ci_translate_c_expr(s: str, params: str, known: str) -> str:
    let trimmed = ci_strip_parens(ci_trim(s))
    if trimmed.len() == 0:
        return ""
    ci_parse_cond_expr(trimmed, params, known)

// Level 0: Ternary conditional  cond ? then : else
fn ci_parse_cond_expr(s: str, params: str, known: str) -> str:
    let t0 = ci_strip_parens(ci_trim(s))
    if t0.len() == 0:
        return ""
    let ternary_pos = ci_find_ternary(t0)
    if ternary_pos >= 0:
        let cond = ci_parse_or_expr(t0.slice(0, ternary_pos as i64), params, known)
        if cond.len() > 0:
            let rest = t0.slice(ternary_pos as i64 + 1, t0.len())
            let colon_pos = ci_find_ternary_colon(rest)
            if colon_pos >= 0:
                let then_e = ci_parse_cond_expr(ci_trim(rest.slice(0, colon_pos as i64)), params, known)
                let else_e = ci_parse_cond_expr(ci_trim(rest.slice(colon_pos as i64 + 1, rest.len())), params, known)
                if then_e.len() > 0 and else_e.len() > 0:
                    let cond_expr = ci_ensure_bool(cond)
                    return "(if " ++ cond_expr ++ ": " ++ then_e ++ " else: " ++ else_e ++ ")"
        return ""
    ci_parse_or_expr(t0, params, known)

// Level 1: Logical OR  ||
fn ci_parse_or_expr(s: str, params: str, known: str) -> str:
    let pos = ci_find_op_at_depth0(s, "||")
    if pos >= 0:
        let lhs = ci_parse_or_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_and_expr(ci_trim(s.slice((pos + 2) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ ci_ensure_bool(lhs) ++ " or " ++ ci_ensure_bool(rhs) ++ ")"
    ci_parse_and_expr(s, params, known)

// Level 2: Logical AND  &&
fn ci_parse_and_expr(s: str, params: str, known: str) -> str:
    let pos = ci_find_op_at_depth0(s, "&&")
    if pos >= 0:
        let lhs = ci_parse_and_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_bitor_expr(ci_trim(s.slice((pos + 2) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ ci_ensure_bool(lhs) ++ " and " ++ ci_ensure_bool(rhs) ++ ")"
    ci_parse_bitor_expr(s, params, known)

// Level 3: Bitwise OR  |  (not ||)
fn ci_parse_bitor_expr(s: str, params: str, known: str) -> str:
    let pos = ci_find_single_op_at_depth0(s, 124, 124)  // '|' but not '||'
    if pos >= 0:
        let lhs = ci_parse_bitor_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_bitxor_expr(ci_trim(s.slice((pos + 1) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ lhs ++ " | " ++ rhs ++ ")"
    ci_parse_bitxor_expr(s, params, known)

// Level 4: Bitwise XOR  ^
fn ci_parse_bitxor_expr(s: str, params: str, known: str) -> str:
    let pos = ci_find_char_op_at_depth0(s, 94)  // '^'
    if pos >= 0:
        let lhs = ci_parse_bitxor_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_bitand_expr(ci_trim(s.slice((pos + 1) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ lhs ++ " ^ " ++ rhs ++ ")"
    ci_parse_bitand_expr(s, params, known)

// Level 5: Bitwise AND  &  (not &&)
fn ci_parse_bitand_expr(s: str, params: str, known: str) -> str:
    let pos = ci_find_single_op_at_depth0(s, 38, 38)  // '&' but not '&&'
    if pos >= 0:
        let lhs = ci_parse_bitand_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_eq_expr(ci_trim(s.slice((pos + 1) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ lhs ++ " & " ++ rhs ++ ")"
    ci_parse_eq_expr(s, params, known)

// Level 6: Equality  == !=
fn ci_parse_eq_expr(s: str, params: str, known: str) -> str:
    let pos_eq = ci_find_op_at_depth0(s, "==")
    let pos_neq = ci_find_op_at_depth0(s, "!=")
    let pos = if pos_eq >= 0 and (pos_neq < 0 or pos_eq < pos_neq): pos_eq else: pos_neq
    if pos >= 0:
        let op_str = s.slice(pos as i64, (pos + 2) as i64)
        let lhs = ci_parse_eq_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_rel_expr(ci_trim(s.slice((pos + 2) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            let w_op = if op_str == "==": "==" else: "!="
            return "(" ++ lhs ++ " " ++ w_op ++ " " ++ rhs ++ ")"
    ci_parse_rel_expr(s, params, known)

// Level 7: Relational  < > <= >=
fn ci_parse_rel_expr(s: str, params: str, known: str) -> str:
    // Find rightmost relational op at depth 0 (to get left-to-right assoc)
    var best_pos = -1
    var best_len = 0
    var depth = 0
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if depth == 0 and i > 0:
            let prev = s.byte_at((i - 1) as i64)
            if c == 60 and i + 1 < s.len() as i32 and s.byte_at((i + 1) as i64) == 61 and prev != 60:  // <=
                best_pos = i
                best_len = 2
            else if c == 62 and i + 1 < s.len() as i32 and s.byte_at((i + 1) as i64) == 61 and prev != 62:  // >=
                best_pos = i
                best_len = 2
            else if c == 60 and (i + 1 >= s.len() as i32 or s.byte_at((i + 1) as i64) != 60) and prev != 60 and (i < 1 or prev != 60):  // < but not <<
                if i + 1 < s.len() as i32 and s.byte_at((i + 1) as i64) != 61:
                    best_pos = i
                    best_len = 1
            else if c == 62 and (i + 1 >= s.len() as i32 or s.byte_at((i + 1) as i64) != 62) and prev != 62:  // > but not >>
                if i + 1 < s.len() as i32 and s.byte_at((i + 1) as i64) != 61:
                    best_pos = i
                    best_len = 1
        i = i + 1
    if best_pos >= 0:
        let op_str = s.slice(best_pos as i64, (best_pos + best_len) as i64)
        let lhs = ci_parse_rel_expr(s.slice(0, best_pos as i64), params, known)
        let rhs = ci_parse_shift_expr(ci_trim(s.slice((best_pos + best_len) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ lhs ++ " " ++ op_str ++ " " ++ rhs ++ ")"
    ci_parse_shift_expr(s, params, known)

// Level 8: Shift  << >>
fn ci_parse_shift_expr(s: str, params: str, known: str) -> str:
    let pos_shl = ci_find_op_at_depth0(s, "<<")
    let pos_shr = ci_find_op_at_depth0(s, ">>")
    let pos = if pos_shl >= 0 and (pos_shr < 0 or pos_shl < pos_shr): pos_shl else: pos_shr
    if pos >= 0:
        let op_str = s.slice(pos as i64, (pos + 2) as i64)
        let lhs = ci_parse_shift_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_add_expr(ci_trim(s.slice((pos + 2) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            let w_op = ci_map_c_op(op_str)
            return "(" ++ lhs ++ " " ++ w_op ++ " " ++ rhs ++ ")"
    ci_parse_add_expr(s, params, known)

// Level 9: Additive  + -
fn ci_parse_add_expr(s: str, params: str, known: str) -> str:
    // Find rightmost + or - at depth 0, but not after another operator (unary)
    var best_pos = -1
    var depth = 0
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if depth == 0 and i > 0 and (c == 43 or c == 45):
            // Skip if preceded by another operator (unary context)
            let prev = ci_last_nonspace_char(s, i)
            if prev != 43 and prev != 45 and prev != 42 and prev != 47 and prev != 37 and prev != 40 and prev != 44 and prev != 124 and prev != 38 and prev != 94 and prev != 60 and prev != 62 and prev != 33 and prev != 126 and prev != 63:
                best_pos = i
        i = i + 1
    if best_pos >= 0:
        let op_char = s.byte_at(best_pos as i64)
        let lhs = ci_parse_add_expr(s.slice(0, best_pos as i64), params, known)
        let rhs = ci_parse_mul_expr(ci_trim(s.slice((best_pos + 1) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            let op = if op_char == 43: "+" else: "-"
            return "(" ++ lhs ++ " " ++ op ++ " " ++ rhs ++ ")"
    ci_parse_mul_expr(s, params, known)

// Level 10: Multiplicative  * / %
fn ci_parse_mul_expr(s: str, params: str, known: str) -> str:
    // Find rightmost * / % at depth 0
    var best_pos = -1
    var depth = 0
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if depth == 0 and i > 0 and (c == 42 or c == 47 or c == 37):
            let prev = ci_last_nonspace_char(s, i)
            if prev != 40 and prev != 44 and prev != 42 and prev != 47 and prev != 37:
                best_pos = i
        i = i + 1
    if best_pos >= 0:
        let op_char = s.byte_at(best_pos as i64)
        let lhs = ci_parse_mul_expr(s.slice(0, best_pos as i64), params, known)
        let rhs = ci_parse_cast_expr(ci_trim(s.slice((best_pos + 1) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            let op = if op_char == 42: "*" else if op_char == 47: "/" else: "%"
            return "(" ++ lhs ++ " " ++ op ++ " " ++ rhs ++ ")"
    ci_parse_cast_expr(s, params, known)

// Level 11: Cast  (type)expr
fn ci_parse_cast_expr(s: str, params: str, known: str) -> str:
    let t = ci_trim(s)
    if t.len() > 0 and t.byte_at(0) == 40:
        let cast_end = ci_find_matching_paren(t, 0)
        if cast_end > 0 and cast_end as i64 + 1 < t.len():
            let inside = t.slice(1, cast_end as i64)
            let after_str = t.slice(cast_end as i64 + 1, t.len())
            if ci_is_c_type_name(inside):
                let mapped = ci_map_base_type(ci_trim(inside))
                let after_trimmed = ci_trim(after_str)
                // Cast-with-initializer: (type){ .field=val, ... }
                if after_trimmed.len() > 0 and after_trimmed.byte_at(0) == 123:
                    let init_result = ci_translate_c_expr(after_trimmed, params, known)
                    if init_result.len() > 0:
                        return mapped ++ " " ++ init_result
                    return ""
                let after = ci_parse_cast_expr(after_str, params, known)
                if after.len() > 0:
                    return "(" ++ after ++ " as " ++ mapped ++ ")"
                return ""
    ci_parse_unary_expr(s, params, known)

// Level 12: Unary  ! ~ - & * sizeof alignof
fn ci_parse_unary_expr(s: str, params: str, known: str) -> str:
    let t = ci_trim(s)
    if t.len() == 0:
        return ""
    let c0 = t.byte_at(0)
    // Negation: -expr
    if c0 == 45:
        let neg_rest = ci_trim(t.slice(1, t.len()))
        if ci_is_int_literal(neg_rest):
            return "-" ++ ci_strip_int_suffix(neg_rest)
        if ci_is_float_literal(neg_rest):
            return "-" ++ ci_strip_float_suffix(neg_rest)
        let inner = ci_parse_cast_expr(t.slice(1, t.len()), params, known)
        if inner.len() > 0:
            return "(0 - " ++ inner ++ ")"
        return ""
    // Logical NOT: !expr (but not !=)
    if c0 == 33 and (t.len() < 2 or t.byte_at(1) != 61):
        let inner = ci_parse_cast_expr(t.slice(1, t.len()), params, known)
        if inner.len() > 0:
            return "(if " ++ inner ++ " != 0: 0 else: 1)"
        return ""
    // Bitwise NOT: ~expr
    if c0 == 126:
        let inner = ci_parse_cast_expr(t.slice(1, t.len()), params, known)
        if inner.len() > 0:
            return "(0 - " ++ inner ++ " - 1)"
        return ""
    // Address-of: &expr (but not &&)
    if c0 == 38 and t.len() > 1 and t.byte_at(1) != 38:
        let inner = ci_parse_cast_expr(t.slice(1, t.len()), params, known)
        if inner.len() > 0:
            return "&" ++ inner
        return ""
    // Dereference: *expr
    if c0 == 42:
        let inner = ci_parse_cast_expr(t.slice(1, t.len()), params, known)
        if inner.len() > 0:
            return "(unsafe: *" ++ inner ++ ")"
        return ""
    // sizeof(T)
    if ci_starts_with(t, "sizeof"):
        let rest = ci_trim(t.slice(6, t.len()))
        if rest.len() > 0 and rest.byte_at(0) == 40:
            let close = ci_find_matching_paren(rest, 0)
            if close > 0:
                let inner = ci_trim(rest.slice(1, close as i64))
                if ci_str_contains(params, "|" ++ inner ++ "|"):
                    return "sizeof[T]()"
                let rendered = ci_render_sizeof_type(inner)
                if rendered.len() > 0:
                    return rendered
        return ""
    // alignof / _Alignof
    if ci_starts_with(t, "alignof") or ci_starts_with(t, "_Alignof") or ci_starts_with(t, "__alignof__") or ci_starts_with(t, "__alignof"):
        let prefix_len = if ci_starts_with(t, "__alignof__"): 11 else if ci_starts_with(t, "_Alignof"): 8 else if ci_starts_with(t, "__alignof"): 9 else: 7
        let rest = ci_trim(t.slice(prefix_len as i64, t.len()))
        if rest.len() > 0 and rest.byte_at(0) == 40:
            let close = ci_find_matching_paren(rest, 0)
            if close > 0:
                let inner = ci_trim(rest.slice(1, close as i64))
                let mapped = ci_map_sizeof_type(inner)
                if mapped.len() > 0:
                    return "alignof[" ++ mapped ++ "]()"
        return ""
    ci_parse_postfix_expr(s, params, known)

// Level 13: Postfix  .field ->field [idx] (args)  and primary
fn ci_parse_postfix_expr(s: str, params: str, known: str) -> str:
    let t = ci_strip_parens(ci_trim(s))
    if t.len() == 0:
        return ""
    // Designated initializer: { .field = val }
    if t.byte_at(0) == 123:
        let close_brace = ci_find_matching_brace(t, 0)
        if close_brace > 0:
            let inner = ci_trim(t.slice(1, close_brace as i64))
            if inner.len() > 0 and inner.byte_at(0) == 46:
                let fields_result = ci_translate_designated_init(inner, params, known)
                if fields_result.len() > 0:
                    return ".{ " ++ fields_result ++ " }"
        return ""
    // Function call: ident(args)
    if ci_is_c_ident_prefix(t):
        let call_paren = ci_find_call_paren(t)
        if call_paren > 0:
            let fn_name = t.slice(0, call_paren as i64)
            let args_str = t.slice(call_paren as i64 + 1, t.len() - 1)
            let builtin_result = ci_translate_builtin_call(fn_name, args_str, params, known)
            if builtin_result.len() > 0:
                return builtin_result
            let translated_libc_args = ci_translate_call_args(args_str, params, known)
            if translated_libc_args.len() > 0:
                let libc_result = ci_map_libc_call(fn_name, translated_libc_args)
                if libc_result.len() > 0:
                    return libc_result
            if ci_str_contains(params, "|" ++ fn_name ++ "|") or with_cimport_is_name_emitted(fn_name) != 0:
                let translated_args = ci_translate_call_args(args_str, params, known)
                if translated_args.len() > 0:
                    return fn_name ++ "(" ++ translated_args ++ ")"
            return ""
    // Comma operator in parens: (a, b, c) — handled by strip_parens + recursion
    // Literal values
    if ci_is_int_literal(t):
        return ci_strip_int_suffix(t)
    if ci_is_float_literal(t):
        return ci_strip_float_suffix(t)
    if ci_is_string_literal(t):
        return t
    if ci_is_char_literal(t):
        let cv = ci_char_to_int(t)
        if cv.len() > 0:
            return cv
        return ""
    // Identifier with optional postfix
    let ident_end = ci_scan_ident(t)
    if ident_end > 0:
        let base_ident = t.slice(0, ident_end as i64)
        let postfix = t.slice(ident_end as i64, t.len())
        var base_resolved = ""
        let builtin_val = ci_map_compiler_builtin(base_ident)
        if builtin_val.len() > 0:
            base_resolved = builtin_val
        else if base_ident.len() >= 2 and base_ident.byte_at(0) == 95 and base_ident.byte_at(1) == 95:
            base_resolved = ""
        else if ci_str_contains(params, "|" ++ base_ident ++ "|"):
            base_resolved = base_ident
        else:
            let kv = ci_lookup_known(base_ident, known)
            if kv.len() > 0:
                base_resolved = base_ident
            else if with_cimport_is_name_emitted(base_ident) != 0 and not ci_str_contains(g_macro_type_names, "|" ++ base_ident ++ "|"):
                base_resolved = base_ident
        if base_resolved.len() > 0:
            if postfix.len() == 0:
                return base_resolved
            let result = ci_translate_postfix(base_resolved, postfix, params, known)
            if result.len() > 0:
                return result
        return ""
    ""

// Helper: ensure expression is boolean (add != 0 if not already a comparison)
fn ci_ensure_bool(expr: str) -> str:
    if ci_is_bool_expr(expr):
        return expr
    expr ++ " != 0"

// Helper: find a two-char operator at paren depth 0 (leftmost occurrence)
fn ci_find_op_at_depth0(s: str, op: str) -> i32:
    if op.len() != 2:
        return -1
    let c0 = op.byte_at(0)
    let c1 = op.byte_at(1)
    var depth = 0
    var i = 0
    while i < s.len() as i32 - 1:
        let c = s.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if depth == 0 and c == c0 and s.byte_at((i + 1) as i64) == c1:
            // For << and >>, make sure we don't match <=, >=
            if c0 == 60 and c1 == 60:  // <<
                if i > 0 and s.byte_at((i - 1) as i64) == 60: // <<<
                    i = i + 1
                    continue
                return i
            if c0 == 62 and c1 == 62:  // >>
                return i
            return i
        i = i + 1
    -1

// Helper: find single-char operator at depth 0, excluding doubled version
fn ci_find_single_op_at_depth0(s: str, ch: i32, doubled: i32) -> i32:
    var depth = 0
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if depth == 0 and c == ch:
            // Skip doubled operator (|| or &&)
            if i + 1 < s.len() as i32 and s.byte_at((i + 1) as i64) == doubled:
                i = i + 2
                continue
            // Skip if preceded by same char (already part of double)
            if i > 0 and s.byte_at((i - 1) as i64) == ch:
                i = i + 1
                continue
            return i
        i = i + 1
    -1

// Helper: find single char at depth 0
fn ci_find_char_op_at_depth0(s: str, ch: i32) -> i32:
    var depth = 0
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if depth == 0 and c == ch:
            return i
        i = i + 1
    -1

// Scan identifier length at start of string. Returns 0 if no ident.
fn ci_scan_ident(s: str) -> i32:
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95 or (i > 0 and c >= 48 and c <= 57):
            i = i + 1
        else:
            break
    i

// Translate postfix chain: .field, ->field, [expr]
fn ci_translate_postfix(base: str, rest: str, params: str, known: str) -> str:
    var result = base
    var pos = 0
    let slen = rest.len() as i32
    while pos < slen:
        let c = rest.byte_at(pos as i64)
        // Arrow ->field → .field
        if c == 45 and pos + 1 < slen and rest.byte_at((pos + 1) as i64) == 62:
            pos = pos + 2
            let field_len = ci_scan_ident(rest.slice(pos as i64, rest.len()))
            if field_len == 0:
                return ""
            let field = rest.slice(pos as i64, (pos + field_len) as i64)
            result = result ++ "." ++ ci_escape_reserved(field)
            pos = pos + field_len
        // Dot .field
        else if c == 46:
            pos = pos + 1
            let field_len = ci_scan_ident(rest.slice(pos as i64, rest.len()))
            if field_len == 0:
                return ""
            let field = rest.slice(pos as i64, (pos + field_len) as i64)
            result = result ++ "." ++ ci_escape_reserved(field)
            pos = pos + field_len
        // Subscript [expr]
        else if c == 91:
            let close = ci_find_matching_bracket(rest, pos)
            if close < 0:
                return ""
            let idx_expr = ci_translate_c_expr(rest.slice((pos + 1) as i64, close as i64), params, known)
            if idx_expr.len() == 0:
                return ""
            result = result ++ "[" ++ idx_expr ++ "]"
            pos = close + 1
        else:
            return ""
    result

// Check if expression references any extern var from the pipe-delimited list
fn ci_expr_references_var(expr: str, extern_vars: str) -> bool:
    if extern_vars.len() == 0:
        return false
    // Scan extern_vars for |name| patterns and check if expr contains each name
    var pos = 0
    let vlen = extern_vars.len() as i32
    while pos < vlen:
        if extern_vars.byte_at(pos as i64) == 124:  // '|'
            let name_start = pos + 1
            var name_end = name_start
            while name_end < vlen and extern_vars.byte_at(name_end as i64) != 124:
                name_end = name_end + 1
            if name_end > name_start:
                let var_name = extern_vars.slice(name_start as i64, name_end as i64)
                if ci_str_contains(expr, var_name):
                    return true
            pos = name_end
        else:
            pos = pos + 1
    false

// Check if expression is already boolean (comparison, logical, or != 0)
fn ci_is_bool_expr(s: str) -> bool:
    if ci_str_contains(s, " == ") or ci_str_contains(s, " != "): return true
    if ci_str_contains(s, " < ") or ci_str_contains(s, " > "): return true
    if ci_str_contains(s, " <= ") or ci_str_contains(s, " >= "): return true
    if ci_str_contains(s, " and ") or ci_str_contains(s, " or "): return true
    false

fn ci_find_matching_bracket(s: str, start: i32) -> i32:
    var depth = 0
    var i = start
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 91: depth = depth + 1
        if c == 93:
            depth = depth - 1
            if depth == 0:
                return i
        i = i + 1
    -1

// Find the opening paren of a function call: ident(...)
// Returns position of '(' or -1.
fn ci_find_call_paren(s: str) -> i32:
    var i = 0
    // Skip identifier chars
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95:
            i = i + 1
        else:
            break
    if i > 0 and i < s.len() as i32 and s.byte_at(i as i64) == 40:
        // Verify closing paren matches at end
        let close = ci_find_matching_paren(s, i)
        if close == s.len() as i32 - 1:
            return i
    -1

// Translate comma-separated call arguments
fn ci_translate_call_args(args: str, params: str, known: str) -> str:
    var result = ""
    var depth = 0
    var start = 0
    var i = 0
    let slen = args.len() as i32
    while i <= slen:
        let at_end = i == slen
        var c = 0
        if not at_end:
            c = args.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if (c == 44 and depth == 0) or at_end:
            let arg = ci_trim(args.slice(start as i64, i as i64))
            let translated = ci_translate_c_expr(arg, params, known)
            if translated.len() == 0:
                return ""
            if result.len() > 0:
                result = result ++ ", "
            result = result ++ translated
            start = i + 1
        i = i + 1
    result

// Translate known __builtin_* function calls
fn ci_translate_builtin_call(name: str, args: str, params: str, known: str) -> str:
    // Tier 1: Essential builtins
    if name == "__builtin_expect" or name == "__builtin_expect_with_probability":
        // __builtin_expect(x, v) → x (hint only)
        let first_arg = ci_extract_first_arg(args)
        return ci_translate_c_expr(first_arg, params, known)

    if name == "__builtin_unreachable":
        return "unreachable()"

    if name == "__builtin_trap":
        return "abort()"

    if name == "__builtin_memcpy" or name == "__builtin_memmove" or name == "__builtin_memset" or name == "__builtin_strlen":
        let stdlib_name = name.slice(10, name.len())  // strip "__builtin_"
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return stdlib_name ++ "(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_abs":
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return "with_abs(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_constant_p":
        // Compile-time constant check — always false at runtime
        return "0"

    if name == "__builtin_types_compatible_p":
        return "comptime_error(\"__builtin_types_compatible_p\")"

    if name == "__builtin_choose_expr":
        // __builtin_choose_expr(const_cond, true_val, false_val)
        let ce_cond = ci_trim(ci_extract_first_arg(args))
        let ce_rest1 = ci_after_first_arg(args)
        let ce_true_val = ci_trim(ci_extract_first_arg(ce_rest1))
        let ce_rest2 = ci_after_first_arg(ce_rest1)
        let ce_false_val = ci_trim(ci_extract_first_arg(ce_rest2))
        if ce_cond == "1" or ce_cond == "true":
            return ci_translate_c_expr(ce_true_val, params, known)
        if ce_cond == "0" or ce_cond == "false":
            return ci_translate_c_expr(ce_false_val, params, known)
        let c = ci_translate_c_expr(ce_cond, params, known)
        let t = ci_translate_c_expr(ce_true_val, params, known)
        let f = ci_translate_c_expr(ce_false_val, params, known)
        if c.len() > 0 and t.len() > 0 and f.len() > 0:
            return "(if " ++ c ++ " != 0: " ++ t ++ " else: " ++ f ++ ")"
        return "comptime_error(\"__builtin_choose_expr\")"

    if name == "__builtin_convertvector":
        return "comptime_error(\"__builtin_convertvector\")"

    if name == "__builtin_shufflevector":
        return "comptime_error(\"__builtin_shufflevector\")"

    // Tier 2: Bit manipulation — map to runtime wrappers
    if name == "__builtin_clz" or name == "__builtin_ctz" or name == "__builtin_popcount":
        let wrapper = "with_" ++ name.slice(10, name.len())  // "__builtin_clz" → "with_clz"
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return wrapper ++ "(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_bswap16" or name == "__builtin_bswap32" or name == "__builtin_bswap64":
        let wrapper = "with_" ++ name.slice(10, name.len())  // "__builtin_bswap32" → "with_bswap32"
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return wrapper ++ "(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_clzl" or name == "__builtin_clzll" or name == "__builtin_ctzl" or name == "__builtin_ctzll":
        let wrapper = "with_" ++ name.slice(10, name.len())
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return wrapper ++ "(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_offsetof":
        // __builtin_offsetof(type, field) — type argument, not translatable generically
        return ""

    // Tier 3: Math builtins — strip __builtin_ prefix, emit stdlib name
    if name == "__builtin_ceil" or name == "__builtin_floor" or name == "__builtin_sqrt" or name == "__builtin_fabs" or name == "__builtin_sin" or name == "__builtin_cos" or name == "__builtin_log" or name == "__builtin_exp" or name == "__builtin_round" or name == "__builtin_trunc" or name == "__builtin_log2" or name == "__builtin_log10" or name == "__builtin_pow" or name == "__builtin_fmin" or name == "__builtin_fmax":
        let stdlib_name = name.slice(10, name.len())
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return stdlib_name ++ "(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_ceilf" or name == "__builtin_floorf" or name == "__builtin_sqrtf" or name == "__builtin_fabsf" or name == "__builtin_sinf" or name == "__builtin_cosf" or name == "__builtin_logf" or name == "__builtin_expf" or name == "__builtin_roundf" or name == "__builtin_truncf" or name == "__builtin_log2f" or name == "__builtin_log10f" or name == "__builtin_powf" or name == "__builtin_fminf" or name == "__builtin_fmaxf":
        let stdlib_name = name.slice(10, name.len())
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return stdlib_name ++ "(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_isnan" or name == "__builtin_isinf" or name == "__builtin_isinf_sign":
        let stdlib_name = name.slice(10, name.len())
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return stdlib_name ++ "(" ++ translated_args ++ ")"
        return ""

    // Tier 4: Additional builtins
    if name == "__builtin_exp2" or name == "__builtin_exp2f":
        let stdlib_name = name.slice(10, name.len())
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return stdlib_name ++ "(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_signbit" or name == "__builtin_signbitf":
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return "signbit(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_labs":
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return "labs(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_llabs":
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return "llabs(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin_strcmp":
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return "strcmp(" ++ translated_args ++ ")"
        return ""

    if name == "__builtin___memcpy_chk":
        // __builtin___memcpy_chk(dst, src, n, objsize) → with_memcpy(dst, src, n)
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return "with_memcpy(" ++ ci_first_n_args(translated_args, 3) ++ ")"
        return ""

    if name == "__builtin___memset_chk":
        // __builtin___memset_chk(dst, val, n, objsize) → with_memset(dst, val, n)
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return "with_memset(" ++ ci_first_n_args(translated_args, 3) ++ ")"
        return ""

    if name == "__builtin_huge_valf":
        return "HUGE_VALF"

    if name == "__builtin_inff":
        return "INFINITY"

    if name == "__builtin_nanf":
        // __builtin_nanf("") → NAN
        return "NAN"

    if name == "__builtin_object_size":
        // __builtin_object_size(ptr, type) → (-1) as usize  (unknown size)
        return "-1"

    if name == "__builtin_mul_overflow":
        // __builtin_mul_overflow(a, b, result) — can't translate inline
        return ""

    if name == "__builtin_assume":
        // __builtin_assume(cond) — hint only, no effect at runtime
        return ""

    if name == "__has_builtin":
        // __has_builtin(x) → always true at compile time
        return "1"

    // Tier 5: Variadic helpers — not translatable inline
    if name == "__builtin_va_start" or name == "__builtin_va_end" or name == "__builtin_va_copy" or name == "__builtin_va_arg":
        return ""

    ""

fn ci_first_n_args(args: str, n: i32) -> str:
    // Extract first N comma-separated arguments from a translated arg string
    var depth = 0
    var count = 0
    var i = 0
    while i < args.len() as i32:
        let c = args.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if c == 44 and depth == 0:
            count = count + 1
            if count >= n:
                return args.slice(0, i as i64)
        i = i + 1
    args

fn ci_after_first_arg(args: str) -> str:
    var depth = 0
    var i = 0
    while i < args.len() as i32:
        let c = args.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if c == 44 and depth == 0:
            return ci_trim(args.slice((i + 1) as i64, args.len()))
        i = i + 1
    ""

fn ci_extract_first_arg(args: str) -> str:
    var depth = 0
    var i = 0
    while i < args.len() as i32:
        let c = args.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if c == 44 and depth == 0:
            return ci_trim(args.slice(0, i as i64))
        i = i + 1
    ci_trim(args)

// ── DISCARD pattern: (void)(X) ───────────────────────────────
// Matches: (void)(X), ((void)(X)), (const void)(X), (volatile void)(X), etc.
// Infer return type from a macro translation that's a cast expression.
// If translated is "(x as c_int)" or similar, extract "c_int".
fn ci_infer_cast_return_type(translated: str) -> str:
    // Look for pattern: "(...) as TYPE)" at outermost level
    // The translated expression for a cast macro is "(param as TYPE)"
    let t = ci_trim(translated)
    if t.len() < 5:
        return ""
    // Check for trailing " as TYPE)" pattern
    var i = t.len() as i32 - 2
    // Find last " as " in the string
    while i >= 4:
        if t.byte_at((i - 3) as i64) == 32 and t.byte_at((i - 2) as i64) == 97 and t.byte_at((i - 1) as i64) == 115 and t.byte_at(i as i64) == 32:
            // Found " as " at position i-3
            let type_start = (i + 1) as i64
            let type_end = if t.byte_at(t.len() - 1) == 41: t.len() - 1 else: t.len()
            let cast_type = ci_trim(t.slice(type_start, type_end))
            // Verify it's a known type name
            if cast_type == "c_int" or cast_type == "c_uint" or cast_type == "c_long" or cast_type == "c_ulong" or cast_type == "c_longlong" or cast_type == "c_ulonglong" or cast_type == "c_short" or cast_type == "c_ushort" or cast_type == "c_char" or cast_type == "i8" or cast_type == "i16" or cast_type == "i32" or cast_type == "i64" or cast_type == "u8" or cast_type == "u16" or cast_type == "u32" or cast_type == "u64" or cast_type == "f32" or cast_type == "f64" or cast_type == "isize" or cast_type == "usize" or cast_type == "bool" or ci_starts_with(cast_type, "*"):
                return cast_type
            return ""
        i = i - 1
    ""

// Check if a macro body contains # (stringification) of a parameter.
// # followed by a param name (not ##) indicates stringification.
fn ci_has_stringify(body: str, params: str) -> bool:
    var i = 0
    while i < body.len() as i32 - 1:
        if body.byte_at(i as i64) == 35:  // '#'
            // Skip ## (token paste)
            if i + 1 < body.len() as i32 and body.byte_at((i + 1) as i64) == 35:
                i = i + 2
                continue
            // Check if followed by a parameter name
            let rest = ci_trim(body.slice((i + 1) as i64, body.len()))
            var end = 0
            while end < rest.len() as i32 and ci_is_ident_char(rest.byte_at(end as i64)):
                end = end + 1
            if end > 0:
                let tok = rest.slice(0, end as i64)
                if ci_str_contains(params, "|" ++ tok ++ "|"):
                    return true
        i = i + 1
    false

// Parse [N]T and return the byte offset of T (after the ']').
// Returns 0 if not an array type.
// Check if a string is a decimal integer > 2147483647 (i32 max)
// Returns true if `ty_str` denotes a small integer type (u8/u16/i8/i16,
// or the C-typedef forms c_uchar/c_schar/c_ushort/c_short). C integer
// promotion rules promote these to `int` before arithmetic and
// bitwise operations; without the cast, `uint16_t * 128` can stay
// as i16 and then sign-extend into a negative array index.
fn ci_type_is_small_int(ty_str: str) -> bool:
    if ty_str == "u8" or ty_str == "i8": return true
    if ty_str == "u16" or ty_str == "i16": return true
    if ty_str == "uint8_t" or ty_str == "int8_t": return true
    if ty_str == "uint16_t" or ty_str == "int16_t": return true
    if ty_str == "c_uchar" or ty_str == "c_schar": return true
    if ty_str == "c_ushort" or ty_str == "c_short": return true
    if ty_str == "PCRE2_UCHAR8": return true
    false

fn ci_type_is_unsigned_small_int(ty_str: str) -> bool:
    if ty_str == "u8" or ty_str == "u16": return true
    if ty_str == "uint8_t" or ty_str == "uint16_t": return true
    if ty_str == "c_uchar" or ty_str == "c_ushort": return true
    if ty_str == "PCRE2_UCHAR8": return true
    false

fn ci_shift_lhs_needs_integer_promotion(lhs_ty_str: str, lhs_peeled_ty: str, lhs_expr_ty_str: str) -> bool:
    ci_type_is_small_int(lhs_ty_str) or ci_type_is_small_int(lhs_peeled_ty) or ci_type_is_small_int(lhs_expr_ty_str)

fn ci_binary_op_uses_c_integer_promotions(op: i32) -> bool:
    op == BO_ADD or op == BO_SUB or op == BO_MUL or op == BO_DIV or op == BO_REM or op == BO_AND or op == BO_OR or op == BO_XOR

fn ci_type_is_integer_shift_anchor(ty_str: str) -> bool:
    if ci_type_is_small_int(ty_str): return true
    if ty_str == "i32" or ty_str == "u32": return true
    if ty_str == "i64" or ty_str == "u64": return true
    if ty_str == "i128" or ty_str == "u128": return true
    if ty_str == "isize" or ty_str == "usize": return true
    if ty_str == "c_int" or ty_str == "c_uint": return true
    if ty_str == "c_long" or ty_str == "c_ulong": return true
    if ty_str == "c_longlong" or ty_str == "c_ulonglong": return true
    false

fn ci_index_expr_element_type_is_small_int(exprs: CiExprPool, types: CiTypePool, id: CiExprId) -> bool:
    var cur = id
    var depth = 0
    while depth < 8 and exprs.kind(cur) == CiExprKind.CIE_PAREN:
        cur = (exprs.get_d0(cur)) as CiExprId
        depth = depth + 1
    if exprs.kind(cur) != CiExprKind.CIE_INDEX:
        return false
    let base = (exprs.get_d0(cur)) as CiExprId
    let base_ty = exprs.get_type(base)
    if (base_ty as i32) == 0:
        return false
    var elem_ty = 0 as CiTypeId
    let base_kind = types.kind(base_ty)
    if base_kind == CiTypeKind.CT_POINTER or base_kind == CiTypeKind.CT_ARRAY:
        elem_ty = (types.get_d0(base_ty)) as CiTypeId
    if (elem_ty as i32) == 0:
        return false
    ci_type_is_small_int(ci_print_type(types, elem_ty))

fn ci_array_subscript_element_type_is_small_int(session: i64, cursor: i32) -> bool:
    let peeled = ci_peel_transparent(session, cursor)
    if with_ci_cursor_kind(session, peeled) != CXK_ARRAY_SUBSCRIPT:
        return false
    if with_ci_num_children(session, peeled) < 1:
        return false
    let base_cursor = with_ci_child(session, peeled, 0)
    let base_peeled = ci_peel_transparent(session, base_cursor)
    let pointee = with_ci_cursor_pointee_type(session, base_cursor)
    if ci_type_is_small_int(pointee):
        return true
    let peeled_pointee = with_ci_cursor_pointee_type(session, base_peeled)
    if ci_type_is_small_int(peeled_pointee):
        return true
    let elem_ty = ci_array_elem_type_from_cursor(session, base_peeled)
    ci_type_is_small_int(elem_ty)

fn ci_array_subscript_element_type_is_unsigned_small_int(session: i64, cursor: i32) -> bool:
    let peeled = ci_peel_transparent(session, cursor)
    if with_ci_cursor_kind(session, peeled) != CXK_ARRAY_SUBSCRIPT:
        return false
    if with_ci_num_children(session, peeled) < 1:
        return false
    let base_cursor = with_ci_child(session, peeled, 0)
    let base_peeled = ci_peel_transparent(session, base_cursor)
    let pointee = with_ci_cursor_pointee_type(session, base_cursor)
    if ci_type_is_unsigned_small_int(pointee):
        return true
    let peeled_pointee = with_ci_cursor_pointee_type(session, base_peeled)
    if ci_type_is_unsigned_small_int(peeled_pointee):
        return true
    let elem_ty = ci_array_elem_type_from_cursor(session, base_peeled)
    ci_type_is_unsigned_small_int(elem_ty)

fn ci_expr_tree_contains_small_int(exprs: CiExprPool, types: CiTypePool, id: CiExprId, depth: i32) -> bool:
    if (id as i32) == 0 or depth > 24:
        return false
    let expr_ty = exprs.get_type(id)
    if (expr_ty as i32) != 0 and ci_type_is_small_int(ci_print_type(types, expr_ty)):
        return true
    let kind = exprs.kind(id)
    if kind == CiExprKind.CIE_PAREN:
        return ci_expr_tree_contains_small_int(exprs, types, (exprs.get_d0(id)) as CiExprId, depth + 1)
    if kind == CiExprKind.CIE_CAST:
        let target_ty = (exprs.get_d0(id)) as CiTypeId
        return (target_ty as i32) != 0 and ci_type_is_small_int(ci_print_type(types, target_ty))
    if kind == CiExprKind.CIE_INDEX:
        if ci_index_expr_element_type_is_small_int(exprs, types, id):
            return true
        return ci_expr_tree_contains_small_int(exprs, types, (exprs.get_d0(id)) as CiExprId, depth + 1)
    if kind == CiExprKind.CIE_DEREF:
        let operand = (exprs.get_d0(id)) as CiExprId
        let operand_ty = exprs.get_type(operand)
        if (operand_ty as i32) != 0 and types.kind(operand_ty) == CiTypeKind.CT_POINTER:
            let pointee = (types.get_d0(operand_ty)) as CiTypeId
            if (pointee as i32) != 0 and ci_type_is_small_int(ci_print_type(types, pointee)):
                return true
        return ci_expr_tree_contains_small_int(exprs, types, operand, depth + 1)
    if kind == CiExprKind.CIE_BINARY:
        return ci_expr_tree_contains_small_int(exprs, types, (exprs.get_d1(id)) as CiExprId, depth + 1) or ci_expr_tree_contains_small_int(exprs, types, (exprs.get_d2(id)) as CiExprId, depth + 1)
    if kind == CiExprKind.CIE_UNARY:
        return ci_expr_tree_contains_small_int(exprs, types, (exprs.get_d1(id)) as CiExprId, depth + 1)
    if kind == CiExprKind.CIE_FIELD:
        return false
    false

fn ci_operand_needs_c_int_promotion(session: i64, cursor: i32, peeled_cursor: i32, exprs: CiExprPool, types: CiTypePool, id: CiExprId) -> bool:
    let ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
    if ci_type_is_small_int(ty_str):
        return true
    let peeled_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, peeled_cursor))
    if ci_type_is_small_int(peeled_ty_str):
        return true
    let expr_ty = exprs.get_type(id)
    if (expr_ty as i32) != 0 and ci_type_is_small_int(ci_print_type(types, expr_ty)):
        return true
    ci_index_expr_element_type_is_small_int(exprs, types, id) or ci_array_subscript_element_type_is_small_int(session, cursor) or ci_expr_tree_contains_small_int(exprs, types, id, 0)

fn CiExprPool.promote_c_small_int_operand(self: CiExprPool, session: i64, cursor: i32, peeled_cursor: i32, value: CiExprId, types: CiTypePool) -> CiExprId:
    if not ci_operand_needs_c_int_promotion(session, cursor, peeled_cursor, self.val(), types, value):
        return value
    let c_int_ty = types.named_type_from_text("c_int")
    if (c_int_ty as i32) == 0:
        return 0 as CiExprId
    self.cast(c_int_ty, value)

fn ci_is_large_decimal(s: str) -> bool:
    if s.len() == 0: return false
    var i = 0
    while i as i64 < s.len():
        let c = s.byte_at(i as i64)
        if c < 48 or c > 57: return false
        i = i + 1
    // 11+ digits is always > i32 max; <10 digits is always <= i32 max
    if s.len() as i32 > 10: return true
    if s.len() as i32 < 10: return false
    // Exactly 10 digits — compare char by char against "2147483647"
    let threshold = "2147483647"
    i = 0
    while i < 10:
        let sc = s.byte_at(i as i64)
        let tc = threshold.byte_at(i as i64)
        if sc > tc: return true
        if sc < tc: return false
        i = i + 1
    false  // equal = not large

fn ci_binary_op_allows_uint_literal_cast(op: i32, operand_unsigned: bool) -> bool:
    op == BO_SHL or op == BO_SHR or op == BO_AND or op == BO_OR or op == BO_XOR or
    (operand_unsigned and (op == BO_ADD or op == BO_SUB or op == BO_MUL))

fn ci_binary_large_decimal_cast_type(session: i64, cursor: i32, op: i32, is_rhs: bool, types: CiTypePool) -> CiTypeId:
    let c_uint_ty = types.named_type_from_text("c_uint")
    if (op == BO_SHL or op == BO_SHR) and is_rhs:
        return c_uint_ty
    if with_ci_type_is_unsigned(session, cursor) != 0:
        let result_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
        if (result_ty as i32) != 0:
            return result_ty
    c_uint_ty

fn ci_non_literal_operand_is_unsigned(session: i64, lhs_cursor: i32, rhs_cursor: i32, lhs_large: bool, rhs_large: bool) -> bool:
    if lhs_large and rhs_large: return true
    if rhs_large: return with_ci_type_is_unsigned(session, lhs_cursor) != 0
    if lhs_large: return with_ci_type_is_unsigned(session, rhs_cursor) != 0
    false

// Pure decimal literal (no operators, no idents). Used by the
// unsigned-arithmetic emit logic to decide whether to wrap an
// operand in `(... as c_uint)` — With's literal type inference
// defaults to signed, so an unsigned wrap op like `+%` rejects a
// bare decimal literal that doesn't fit i32 silently and a
// fitting-but-untagged literal as type-mismatched against the
// other unsigned operand.
fn ci_is_decimal_literal(s: str) -> bool:
    if s.len() == 0: return false
    var i = 0
    while i as i64 < s.len():
        let c = s.byte_at(i as i64)
        if c < 48 or c > 57: return false
        i = i + 1
    true

fn ci_find_array_elem_start(ty: str) -> i32:
    if ty.len() == 0 or ty.byte_at(0) != 91: return 0
    var i = 1
    while i as i64 < ty.len() and ty.byte_at(i as i64) != 93:
        i = i + 1
    if i as i64 < ty.len():
        return i + 1  // skip past ']'
    0

fn ci_is_ident_start(c: i32) -> bool:
    (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95

fn ci_is_ident_char(c: i32) -> bool:
    (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95

// Translates to just evaluating X (discarding the result)

fn ci_is_discard_pattern(body: str, params: str) -> bool:
    let stripped = ci_strip_parens(ci_trim(body))
    // Must be (void)(X) or (const void)(X) etc.
    if stripped.len() < 8:
        return false
    if stripped.byte_at(0) != 40:  // '('
        return false
    let close = ci_find_matching_paren(stripped, 0)
    if close < 0:
        return false
    let cast_type = ci_trim(stripped.slice(1, close as i64))
    // Check if cast type is void, const void, volatile void, etc.
    let is_void_cast = cast_type == "void" or cast_type == "const void" or cast_type == "volatile void" or cast_type == "const volatile void" or cast_type == "volatile const void"
    if not is_void_cast:
        return false
    // Rest must be (X) where X is a param
    let rest = ci_trim(stripped.slice(close as i64 + 1, stripped.len()))
    if rest.len() < 3 or rest.byte_at(0) != 40:
        return false
    true

fn ci_translate_discard_pattern(body: str, params: str, known: str) -> str:
    let stripped = ci_strip_parens(ci_trim(body))
    let close = ci_find_matching_paren(stripped, 0)
    if close < 0:
        return ""
    let rest = ci_trim(stripped.slice(close as i64 + 1, stripped.len()))
    // rest is (X) — extract X
    let inner = ci_strip_parens(rest)
    ci_translate_c_expr(inner, params, known)

// ── Token pasting (##) translation ───────────────────────────
// Handles macros like: (v ## ULL), (v ## U), (v ## L)
// Translates param##SUFFIX → (param as target_type)

fn ci_try_translate_token_paste(body: str, params: str) -> str:
    let stripped = ci_strip_parens(ci_trim(body))
    let paste_pos = ci_find_str(stripped, "##")
    if paste_pos < 0:
        return ""
    let before = ci_trim(stripped.slice(0, paste_pos as i64))
    let after = ci_trim(stripped.slice(paste_pos as i64 + 2, stripped.len()))
    // Case: param##SUFFIX (e.g., v##U, v##ULL)
    if ci_str_contains(params, "|" ++ before ++ "|"):
        let target_type = ci_token_paste_suffix(after)
        if target_type.len() > 0:
            return "(" ++ before ++ " as " ++ target_type ++ ")"
    // Case: SUFFIX##param — rare, not translatable
    ""

fn ci_token_paste_suffix(suffix: str) -> str:
    if suffix == "U" or suffix == "u": return "u32"
    if suffix == "UL" or suffix == "ul" or suffix == "Ul" or suffix == "uL": return "u64"
    if suffix == "ULL" or suffix == "ull" or suffix == "Ull" or suffix == "uLL": return "u64"
    if suffix == "L" or suffix == "l": return "i64"
    if suffix == "LL" or suffix == "ll": return "i64"
    if suffix == "F" or suffix == "f": return "f32"
    ""

fn ci_find_str(text: str, needle: str) -> i32:
    if needle.len() > text.len():
        return -1
    let limit = text.len() - needle.len()
    for i in 0..limit as i32 + 1:
        if ci_str_matches_at(text, i, needle):
            return i
    -1

fn ci_find_binary_op_ext(s: str) -> i32:
    // Like ci_find_binary_op but also handles comparison and logical ops
    var best_pos = -1
    var best_prec = 100
    var best_len = 0
    var paren_depth = 0
    var idx = 0
    let slen = s.len() as i32
    while idx < slen:
        let c = s.byte_at(idx as i64)
        if c == 40:
            paren_depth = paren_depth + 1
        else if c == 41:
            paren_depth = paren_depth - 1
        else if paren_depth == 0 and idx > 0:
            // Skip operators preceded by another operator (handles unary after binary like a * -b)
            let prev = ci_last_nonspace_char(s, idx)
            if prev != 43 and prev != 45 and prev != 42 and prev != 47 and prev != 37 and prev != 40 and prev != 44 and prev != 124 and prev != 38 and prev != 94 and prev != 60 and prev != 62 and prev != 33 and prev != 126:
                let prec = ci_op_prec_ext(s, idx, slen)
                if prec >= 0 and prec <= best_prec:
                    best_pos = idx
                    best_prec = prec
                    best_len = ci_op_length_ext(s, idx, slen)
        idx = idx + 1
    if best_pos > 0:
        return best_pos * 256 + best_len
    -1

fn ci_last_nonspace_char(s: str, idx: i32) -> i32:
    var i = idx - 1
    while i >= 0:
        let c = s.byte_at(i as i64)
        if c != 32 and c != 9:
            return c
        i = i - 1
    0

fn ci_is_c_ident_prefix(s: str) -> bool:
    if s.len() == 0:
        return false
    let c0 = s.byte_at(0)
    (c0 >= 65 and c0 <= 90) or (c0 >= 97 and c0 <= 122) or c0 == 95

fn ci_op_prec_ext(s: str, idx: i32, slen: i32) -> i32:
    let c = s.byte_at(idx as i64)
    var nx = 0
    if idx + 1 < slen:
        nx = s.byte_at(idx as i64 + 1)
    // Logical OR
    if c == 124 and nx == 124: return 0
    // Logical AND
    if c == 38 and nx == 38: return 1
    // Bitwise OR
    if c == 124 and nx != 124: return 2
    // Bitwise XOR
    if c == 94: return 3
    // Bitwise AND
    if c == 38 and nx != 38: return 4
    // Equality
    if c == 61 and nx == 61: return 5
    if c == 33 and nx == 61: return 5
    // Relational
    if c == 60 and nx == 61: return 6
    if c == 62 and nx == 61: return 6
    if c == 60 and nx != 60: return 6
    if c == 62 and nx != 62: return 6
    // Shift
    if c == 60 and nx == 60: return 7
    if c == 62 and nx == 62: return 7
    // Additive
    if c == 43: return 8
    if c == 45: return 8
    // Multiplicative
    if c == 42: return 9
    if c == 47: return 9
    if c == 37: return 9
    -1

fn ci_op_length_ext(s: str, idx: i32, slen: i32) -> i32:
    if idx + 1 < slen:
        let c = s.byte_at(idx as i64)
        let nx = s.byte_at(idx as i64 + 1)
        if c == 124 and nx == 124: return 2
        if c == 38 and nx == 38: return 2
        if c == 60 and nx == 60: return 2
        if c == 62 and nx == 62: return 2
        if c == 61 and nx == 61: return 2
        if c == 33 and nx == 61: return 2
        if c == 60 and nx == 61: return 2
        if c == 62 and nx == 61: return 2
    1

fn ci_map_c_op(op: str) -> str:
    if op == "+": return "+"
    if op == "-": return "-"
    if op == "*": return "*"
    if op == "/": return "/"
    if op == "%": return "%"
    if op == "==": return "=="
    if op == "!=": return "!="
    if op == "<": return "<"
    if op == ">": return ">"
    if op == "<=": return "<="
    if op == ">=": return ">="
    if op == "&&": return "and"
    if op == "||": return "or"
    if op == "&": return "&"
    if op == "|": return "|"
    if op == "^": return "^"
    if op == "<<": return "<<"
    if op == ">>": return ">>"
    ""

fn ci_is_comparison_op(op: str) -> bool:
    op == "==" or op == "!=" or op == "<" or op == ">" or op == "<=" or op == ">=" or op == "and" or op == "or"

fn ci_map_sizeof_type(c_type: str) -> str:
    let t = ci_trim(c_type)
    // Try builtin typedef first
    let mapped = ci_map_builtin_typedef(t)
    if mapped.len() > 0:
        return mapped
    // Try base type
    if ci_is_known_base_type(t):
        return ci_map_base_type(t)
    // Pointer types — sizeof(void*) etc. → all pointers are same size as usize
    if t.len() > 0 and t.byte_at(t.len() - 1) == 42:
        return "usize"
    // Struct/type name — pass through
    if ci_is_c_ident(t):
        let translated_typedef = ci_lookup_known(t, g_macro_type_aliases)
        if translated_typedef.len() > 0:
            return ci_normalize_translated_type_name(translated_typedef)
        let macro_value = ci_trim(ci_lookup_macro_value(0, t))
        if macro_value.len() > 0 and ci_is_c_ident(macro_value):
            let normalized_macro_value = ci_normalize_translated_type_name(macro_value)
            if normalized_macro_value != macro_value:
                return normalized_macro_value
            if ci_str_contains(g_macro_type_names, "|" ++ macro_value ++ "|"):
                return ci_escape_reserved(macro_value)
        if ci_str_contains(g_macro_type_names, "|" ++ t ++ "|"):
            return ci_escape_reserved(t)
    ""

fn ci_render_sizeof_type(c_type: str) -> str:
    let t = ci_trim(c_type)
    if t.len() == 0:
        return ""
    if t.byte_at(0) == 91:
        let close = ci_find_matching_bracket(t, 0)
        if close > 0 and close < t.len() as i32 - 1:
            let count = ci_trim(t.slice(1, close as i64))
            let elem = ci_trim(t.slice(close as i64 + 1, t.len()))
            let inner = ci_render_sizeof_type(elem)
            if count.len() > 0 and inner.len() > 0:
                return "(" ++ count ++ " * " ++ inner ++ ")"
        return ""
    let mapped = ci_map_sizeof_type(t)
    if mapped.len() > 0:
        return "sizeof[" ++ mapped ++ "]()"
    ""

// ── Constant expression evaluator ────────────────────────────

fn ci_eval_const_expr(s: str) -> str:
    ci_eval_const_expr_ctx(s, "")

fn ci_eval_const_expr_ctx(s: str, known: str) -> str:
    let trimmed = ci_trim(ci_strip_parens(s))
    if trimmed.len() == 0:
        return ""
    if ci_is_int_literal(trimmed):
        return ci_strip_int_suffix(trimmed)
    // Unary negation
    if trimmed.byte_at(0) == 45:
        let inner = ci_eval_const_expr_ctx(trimmed.slice(1, trimmed.len()), known)
        if inner.len() > 0:
            if inner.byte_at(0) == 45:
                return inner.slice(1, inner.len())
            return "-" ++ inner
        return ""
    // Unary bitwise NOT (~)
    if trimmed.byte_at(0) == 126:
        let inner = ci_eval_const_expr_ctx(trimmed.slice(1, trimmed.len()), known)
        if inner.len() > 0:
            let iv = ci_parse_i64(inner)
            let nv = 0 - iv - 1
            return f"{nv}"
        return ""
    // Logical NOT (!)
    if trimmed.byte_at(0) == 33:
        let inner = ci_eval_const_expr_ctx(trimmed.slice(1, trimmed.len()), known)
        if inner.len() > 0:
            let iv = ci_parse_i64(inner)
            if iv == 0: return "1"
            return "0"
        return ""
    // C cast stripping: (type)expr — if parens contain a C type name, strip them
    if trimmed.byte_at(0) == 40:
        let cast_end = ci_find_matching_paren(trimmed, 0)
        if cast_end > 0 and cast_end as i64 + 1 < trimmed.len():
            let inside = trimmed.slice(1, cast_end as i64)
            if ci_is_c_type_name(inside):
                let after = ci_trim(trimmed.slice(cast_end as i64 + 1, trimmed.len()))
                return ci_eval_const_expr_ctx(after, known)
    // Ternary: find ? at paren depth 0
    let ternary_pos = ci_find_ternary(trimmed)
    if ternary_pos >= 0:
        let cond_str = ci_eval_const_expr_ctx(trimmed.slice(0, ternary_pos as i64), known)
        if cond_str.len() > 0:
            let rest = trimmed.slice(ternary_pos as i64 + 1, trimmed.len())
            let colon_pos = ci_find_ternary_colon(rest)
            if colon_pos >= 0:
                let then_str = rest.slice(0, colon_pos as i64)
                let else_str = rest.slice(colon_pos as i64 + 1, rest.len())
                let cv = ci_parse_i64(cond_str)
                if cv != 0:
                    return ci_eval_const_expr_ctx(then_str, known)
                return ci_eval_const_expr_ctx(else_str, known)
    // Binary: find lowest-precedence operator
    let op_info = ci_find_binary_op(trimmed)
    if op_info >= 0:
        let op_pos = op_info / 256
        let op_len = op_info % 256
        let lhs_str = ci_eval_const_expr_ctx(trimmed.slice(0, op_pos as i64), known)
        let rhs_str = ci_eval_const_expr_ctx(trimmed.slice((op_pos + op_len) as i64, trimmed.len()), known)
        if lhs_str.len() > 0 and rhs_str.len() > 0:
            let lhs = ci_parse_i64(lhs_str)
            let rhs = ci_parse_i64(rhs_str)
            let op = trimmed.slice(op_pos as i64, (op_pos + op_len) as i64)
            return ci_apply_op(lhs, rhs, op)
    // Identifier: look up in known values or compiler builtins
    if ci_is_c_ident(trimmed):
        let builtin_val = ci_map_compiler_builtin(trimmed)
        if builtin_val.len() > 0:
            return builtin_val
        return ci_lookup_known(trimmed, known)
    ""

fn ci_find_matching_paren(s: str, start: i32) -> i32:
    var depth = 0
    var i = start
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 40:
            depth = depth + 1
        else if c == 41:
            depth = depth - 1
            if depth == 0:
                return i
        i = i + 1
    -1

fn ci_find_matching_brace(s: str, start: i32) -> i32:
    var depth = 0
    var i = start
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 34 or c == 39:
            let quote = c
            i = i + 1
            while i < s.len() as i32:
                let inner = s.byte_at(i as i64)
                if inner == 92:
                    i = i + 2
                    continue
                if inner == quote:
                    break
                i = i + 1
            i = i + 1
            continue
        if c == 123: depth = depth + 1
        if c == 125:
            depth = depth - 1
            if depth == 0:
                return i
        i = i + 1
    -1

// Translate C designated initializer: .field = val, .field2 = val2
fn ci_translate_designated_init(s: str, params: str, known: str) -> str:
    var result = ""
    var pos = 0
    let slen = s.len() as i32
    while pos < slen:
        // Skip whitespace
        while pos < slen and (s.byte_at(pos as i64) == 32 or s.byte_at(pos as i64) == 9):
            pos = pos + 1
        if pos >= slen:
            break
        // Expect '.'
        if s.byte_at(pos as i64) != 46:
            return ""
        pos = pos + 1
        // Read field name
        let field_start = pos
        while pos < slen:
            let c = s.byte_at(pos as i64)
            if not ((c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95 or (pos > field_start and c >= 48 and c <= 57)):
                break
            pos = pos + 1
        if pos == field_start:
            return ""
        let field_name = s.slice(field_start as i64, pos as i64)
        // Skip whitespace
        while pos < slen and (s.byte_at(pos as i64) == 32 or s.byte_at(pos as i64) == 9):
            pos = pos + 1
        // Expect '='
        if pos >= slen or s.byte_at(pos as i64) != 61:
            return ""
        pos = pos + 1
        // Find value (until next comma at depth 0 or end)
        let val_start = pos
        var depth = 0
        while pos < slen:
            let c = s.byte_at(pos as i64)
            if c == 40 or c == 91 or c == 123: depth = depth + 1
            if c == 41 or c == 93 or c == 125: depth = depth - 1
            if c == 44 and depth == 0:
                break
            pos = pos + 1
        let val_str = ci_trim(s.slice(val_start as i64, pos as i64))
        let val = ci_translate_c_expr(val_str, params, known)
        if val.len() == 0:
            return ""
        if result.len() > 0:
            result = result ++ ", "
        result = result ++ "." ++ ci_escape_reserved(field_name) ++ " = " ++ val
        // Skip comma
        if pos < slen and s.byte_at(pos as i64) == 44:
            pos = pos + 1
    result

fn ci_is_c_type_name(s: str) -> bool:
    let t = ci_trim(s)
    if t.len() == 0: return false
    // Common C type keywords
    if t == "int": return true
    if t == "unsigned": return true
    if t == "unsigned int": return true
    if t == "long": return true
    if t == "unsigned long": return true
    if t == "long long": return true
    if t == "unsigned long long": return true
    if t == "__int128": return true
    if t == "unsigned __int128": return true
    if t == "short": return true
    if t == "unsigned short": return true
    if t == "char": return true
    if t == "unsigned char": return true
    if t == "signed char": return true
    if t == "void": return true
    if t == "float": return true
    if t == "double": return true
    if t == "long double": return true
    if t == "_Bool": return true
    // With C type aliases
    if t == "c_int": return true
    if t == "c_uint": return true
    if t == "c_long": return true
    if t == "c_ulong": return true
    if t == "c_longlong": return true
    if t == "c_ulonglong": return true
    if t == "c_short": return true
    if t == "c_ushort": return true
    if t == "c_char": return true
    // Common typedefs
    if ci_map_builtin_typedef(t).len() > 0: return true
    if ci_str_contains(g_macro_type_names, "|" ++ t ++ "|"): return true
    false

fn ci_map_compiler_builtin(name: str) -> str:
    // Common GCC/Clang predefined macros with known constant values
    if name == "__INT_MAX__": return "2147483647"
    if name == "__INT8_MAX__": return "127"
    if name == "__INT16_MAX__": return "32767"
    if name == "__INT32_MAX__": return "2147483647"
    if name == "__INT64_MAX__": return "9223372036854775807"
    if name == "__UINT8_MAX__": return "255"
    if name == "__UINT16_MAX__": return "65535"
    if name == "__UINT32_MAX__": return "4294967295"
    if name == "__LONG_MAX__": return "9223372036854775807"
    if name == "__LONG_LONG_MAX__": return "9223372036854775807"
    if name == "__SHRT_MAX__": return "32767"
    if name == "__SCHAR_MAX__": return "127"
    if name == "__CHAR_BIT__": return "8"
    if name == "__SIZEOF_INT__": return "4"
    if name == "__SIZEOF_LONG__": return "8"
    if name == "__SIZEOF_POINTER__": return "8"
    if name == "__SIZEOF_LONG_LONG__": return "8"
    if name == "__SIZEOF_SHORT__": return "2"
    if name == "__SIZEOF_FLOAT__": return "4"
    if name == "__SIZEOF_DOUBLE__": return "8"
    if name == "__INTPTR_MAX__": return "9223372036854775807"
    if name == "__UINTPTR_MAX__": return "18446744073709551615"
    if name == "__INTMAX_MAX__": return "9223372036854775807"
    if name == "__SIZE_MAX__": return "18446744073709551615"
    if name == "__PTRDIFF_MAX__": return "9223372036854775807"
    if name == "__FLT_MAX__": return "3.40282347e+38"
    if name == "__DBL_MAX__": return "1.7976931348623157e+308"
    if name == "__FLT_MIN__": return "1.17549435e-38"
    if name == "__DBL_MIN__": return "2.2250738585072014e-308"
    if name == "__FLT_EPSILON__": return "1.19209290e-7"
    if name == "__DBL_EPSILON__": return "2.2204460492503131e-16"
    ""

fn ci_translate_comma_block(s: str, params: str, known: str) -> str:
    // Split on commas at depth 0, translate each, return block
    var exprs = ""
    var expr_count = 0
    var depth = 0
    var start = 0
    var i = 0
    while i <= s.len() as i32:
        let at_end = i == s.len() as i32
        var c = 0
        if not at_end:
            c = s.byte_at(i as i64)
        if c == 40: depth = depth + 1
        if c == 41: depth = depth - 1
        if (c == 44 and depth == 0) or at_end:
            let part = ci_trim(s.slice(start as i64, i as i64))
            let translated = ci_translate_c_expr(part, params, known)
            if translated.len() == 0:
                return ""
            if exprs.len() > 0:
                exprs = exprs ++ "; "
            exprs = exprs ++ translated
            expr_count = expr_count + 1
            start = i + 1
        i = i + 1
    if expr_count <= 1:
        return exprs
    // Wrap in block: { expr1; expr2; ...; exprN }
    // The last expression is the value of the block
    "{ " ++ exprs ++ " }"

fn ci_find_last_comma_at_depth0(s: str) -> i32:
    var depth = 0
    var last_comma = -1
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 40: depth = depth + 1
        else if c == 41: depth = depth - 1
        else if c == 44 and depth == 0:
            last_comma = i
        i = i + 1
    last_comma

fn ci_find_ternary(s: str) -> i32:
    var depth = 0
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 40:
            depth = depth + 1
        else if c == 41:
            depth = depth - 1
        else if c == 63 and depth == 0:
            return i
        i = i + 1
    -1

fn ci_find_ternary_colon(s: str) -> i32:
    var depth = 0
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 40:
            depth = depth + 1
        else if c == 41:
            depth = depth - 1
        else if c == 58 and depth == 0:
            return i
        i = i + 1
    -1

fn ci_is_c_ident(s: str) -> bool:
    if s.len() == 0:
        return false
    let c0 = s.byte_at(0)
    if not ((c0 >= 65 and c0 <= 90) or (c0 >= 97 and c0 <= 122) or c0 == 95):
        return false
    var i = 1
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if not ((c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95):
            return false
        i = i + 1
    true

fn ci_lookup_known(name: str, known: str) -> str:
    // Search "name=value|name2=value2|..." for name
    let key = name ++ "="
    var pos = 0
    while pos < known.len() as i32:
        if ci_starts_with(known.slice(pos as i64, known.len()), key):
            let val_start = pos + key.len() as i32
            var val_end = val_start
            while val_end < known.len() as i32 and known.byte_at(val_end as i64) != 124:
                val_end = val_end + 1
            return known.slice(val_start as i64, val_end as i64)
        // Skip to next |
        while pos < known.len() as i32 and known.byte_at(pos as i64) != 124:
            pos = pos + 1
        pos = pos + 1
    ""

fn ci_find_binary_op(s: str) -> i32:
    var best_pos = -1
    var best_prec = 100
    var best_len = 0
    var paren_depth = 0
    var idx = 0
    let slen = s.len() as i32
    while idx < slen:
        let c = s.byte_at(idx as i64)
        if c == 40:
            paren_depth = paren_depth + 1
        else if c == 41:
            paren_depth = paren_depth - 1
        else if paren_depth == 0 and idx > 0:
            let prec = ci_op_prec(s, idx, slen)
            if prec >= 0 and prec <= best_prec:
                best_pos = idx
                best_prec = prec
                best_len = ci_op_length(s, idx, slen)
        idx = idx + 1
    if best_pos > 0:
        return best_pos * 256 + best_len
    -1

fn ci_op_prec(s: str, idx: i32, slen: i32) -> i32:
    let c = s.byte_at(idx as i64)
    var nx = 0
    if idx + 1 < slen:
        nx = s.byte_at(idx as i64 + 1)
    if c == 124 and nx != 124: return 0
    if c == 94: return 1
    if c == 38 and nx != 38: return 2
    if c == 60 and nx == 60: return 3
    if c == 62 and nx == 62: return 3
    if c == 43: return 4
    if c == 45: return 4
    if c == 42: return 5
    if c == 47: return 5
    if c == 37: return 5
    -1

fn ci_op_length(s: str, idx: i32, slen: i32) -> i32:
    if idx + 1 < slen:
        let c = s.byte_at(idx as i64)
        let nx = s.byte_at(idx as i64 + 1)
        if c == 60 and nx == 60: return 2
        if c == 62 and nx == 62: return 2
    1

fn ci_apply_op(lhs: i64, rhs: i64, op: str) -> str:
    if op == "+": return f"{lhs + rhs}"
    if op == "-": return f"{lhs - rhs}"
    if op == "*": return f"{lhs * rhs}"
    if op == "/":
        if rhs == 0: return ""
        return f"{lhs / rhs}"
    if op == "%":
        if rhs == 0: return ""
        return f"{lhs % rhs}"
    // For bitwise ops, work on i32 (C macros are typically 32-bit)
    let li = lhs as i32
    let ri = rhs as i32
    if op == "<<": return f"{ci_shl(li, ri)}"
    if op == ">>": return f"{ci_shr(li, ri)}"
    if op == "|": return f"{ci_bitor(li, ri)}"
    if op == "&": return f"{ci_bitand(li, ri)}"
    if op == "^": return f"{ci_bitxor(li, ri)}"
    ""

fn ci_parse_i64(s: str) -> i64:
    if s.len() == 0: return 0
    var is_neg = false
    var si = 0
    if s.byte_at(0) == 45:
        is_neg = true
        si = 1
    // Check for hex prefix 0x/0X
    if s.len() as i32 - si >= 2:
        if s.byte_at(si as i64) == 48:
            let nx = s.byte_at(si as i64 + 1)
            if nx == 120 or nx == 88:
                var n: i64 = 0
                var j = si + 2
                while j as i64 < s.len():
                    let c = s.byte_at(j as i64)
                    if c >= 48 and c <= 57:
                        n = n * 16 + (c - 48) as i64
                    else if c >= 97 and c <= 102:
                        n = n * 16 + (c - 97 + 10) as i64
                    else if c >= 65 and c <= 70:
                        n = n * 16 + (c - 65 + 10) as i64
                    else:
                        break
                    j = j + 1
                if is_neg: return 0 - n
                return n
    var n: i64 = 0
    var j = si
    while j as i64 < s.len():
        let c = s.byte_at(j as i64)
        if c >= 48 and c <= 57:
            n = n * 10 + (c - 48) as i64
        else:
            break
        j = j + 1
    if is_neg: 0 - n else: n

fn ci_shl(a: i32, b: i32) -> i32:
    var result = a
    var count = b
    while count > 0:
        result = result * 2
        count = count - 1
    result

fn ci_shr(a: i32, b: i32) -> i32:
    var result = a
    var count = b
    while count > 0:
        result = result / 2
        count = count - 1
    result

fn ci_bitor(a: i32, b: i32) -> i32:
    // Bit-by-bit OR using arithmetic
    var result = 0
    var aa = a
    var bb = b
    var bit = 1
    var count = 0
    while count < 32:
        let ab = aa - (aa / 2) * 2
        let bv = bb - (bb / 2) * 2
        if ab != 0 or bv != 0:
            result = result + bit
        aa = aa / 2
        bb = bb / 2
        bit = bit * 2
        count = count + 1
    result

fn ci_bitand(a: i32, b: i32) -> i32:
    var result = 0
    var aa = a
    var bb = b
    var bit = 1
    var count = 0
    while count < 32:
        let ab = aa - (aa / 2) * 2
        let bv = bb - (bb / 2) * 2
        if ab != 0 and bv != 0:
            result = result + bit
        aa = aa / 2
        bb = bb / 2
        bit = bit * 2
        count = count + 1
    result

fn ci_bitxor(a: i32, b: i32) -> i32:
    var result = 0
    var aa = a
    var bb = b
    var bit = 1
    var count = 0
    while count < 32:
        let ab = aa - (aa / 2) * 2
        let bv = bb - (bb / 2) * 2
        if ab != bv:
            result = result + bit
        aa = aa / 2
        bb = bb / 2
        bit = bit * 2
        count = count + 1
    result

// ── Type mapping ────────────────────────────────────────────

fn ci_map_c_type(spelling: str) -> str:
    ci_map_c_type_ctx(spelling, "")

fn ci_map_c_type_ctx(spelling: str, known_structs: str) -> str:
    var s = ci_trim(spelling)
    if s.len() == 0:
        return "i32"

    // Strip restrict qualifier
    if ci_str_contains(s, " restrict"):
        s = ci_str_replace(s, " restrict", "")
    if ci_str_contains(s, "restrict "):
        s = ci_str_replace(s, "restrict ", "")
    s = ci_trim(s)

    // Function pointer → opaque
    if ci_str_contains(s, "(*)"):
        return "*const i8"

    // Block pointer → opaque
    if ci_str_contains(s, "(^)"):
        return "*const i8"

    // Array → decay to pointer
    if ci_str_contains(s, "["):
        var bracket_pos = 0
        var bi = 0
        while bi < s.len() as i32:
            if s.byte_at(bi as i64) == 91:
                bracket_pos = bi
                break
            bi = bi + 1
        let base = ci_trim(s.slice(0, bracket_pos as i64))
        let mapped_base = ci_map_c_type_ctx(base, known_structs)
        return "*mut " ++ mapped_base

    // Count and strip trailing pointer markers
    var ptr_depth = 0
    var trimmed = s
    while trimmed.len() > 0 and trimmed.byte_at(trimmed.len() - 1) == 42:
        ptr_depth = ptr_depth + 1
        trimmed = ci_trim(trimmed.slice(0, trimmed.len() - 1))

    // Strip qualifiers
    var is_const = false
    var base = trimmed
    if ci_starts_with(base, "const "):
        is_const = true
        base = ci_trim(base.slice(6, base.len()))
    if ci_starts_with(base, "volatile "):
        base = ci_trim(base.slice(9, base.len()))

    // Handle struct/union types — use name if translated, else: opaque
    if ci_starts_with(base, "struct "):
        let sname = ci_escape_reserved(ci_trim(base.slice(7, base.len())))
        if ci_str_contains(known_structs, "|" ++ sname ++ "|"):
            if ptr_depth == 0:
                return sname
            var sr = sname
            var spi = 0
            while spi < ptr_depth:
                sr = "*mut " ++ sr
                spi = spi + 1
            return sr
        // Unknown struct → opaque
        if ptr_depth > 0:
            return "*const i8"
        return "i32"
    if ci_starts_with(base, "union "):
        let uname = ci_escape_reserved(ci_trim(base.slice(6, base.len())))
        if ci_str_contains(known_structs, "|" ++ uname ++ "|"):
            if ptr_depth == 0:
                return uname
            var ur = uname
            var upi = 0
            while upi < ptr_depth:
                ur = "*mut " ++ ur
                upi = upi + 1
            return ur
        // Unknown union → opaque
        if ptr_depth > 0:
            return "*const i8"
        return "i32"

    // Check if the bare type name is a known translated struct/typedef
    if known_structs.len() > 0:
        let escaped_base = ci_escape_reserved(base)
        if ci_str_contains(known_structs, "|" ++ escaped_base ++ "|"):
            if ptr_depth == 0:
                return escaped_base
            var tr = escaped_base
            var tpi = 0
            while tpi < ptr_depth:
                if is_const:
                    tr = "*const " ++ tr
                else:
                    tr = "*mut " ++ tr
                tpi = tpi + 1
            return tr

    // Map base type
    let is_known = ci_is_known_base_type(base)
    var mapped = ci_map_base_type(base)

    // For pointer to unknown type (typedef, etc.), use opaque *const i8
    if ptr_depth > 0 and not is_known:
        return "*const i8"

    // Apply pointer wrapping
    if ptr_depth > 0:
        // void * → *mut c_void / *const c_void
        if mapped == "void":
            mapped = "c_void"

    if ptr_depth == 0:
        return mapped

    var result = mapped
    var pi = 0
    while pi < ptr_depth:
        if is_const:
            result = "*const " ++ result
        else:
            result = "*mut " ++ result
        pi = pi + 1
    result

fn ci_is_known_base_type(name: str) -> bool:
    if name == "void": return true
    if name == "_Bool": return true
    if name == "char": return true
    if name == "signed char": return true
    if name == "unsigned char": return true
    if name == "short": return true
    if name == "unsigned short": return true
    if name == "int": return true
    if name == "unsigned int": return true
    if name == "long": return true
    if name == "unsigned long": return true
    if name == "long long": return true
    if name == "unsigned long long": return true
    if name == "__int128": return true
    if name == "unsigned __int128": return true
    if name == "float": return true
    if name == "double": return true
    if name == "long double": return true
    if ci_starts_with(name, "enum "): return true
    false

fn ci_map_base_type(name: str) -> str:
    let builtin_typedef = ci_map_builtin_typedef(name)
    if builtin_typedef.len() > 0: return builtin_typedef
    let translated_typedef = ci_lookup_known(name, g_macro_type_aliases)
    if translated_typedef.len() > 0: return ci_normalize_translated_type_name(translated_typedef)
    if name == "void": return "void"
    if name == "_Bool": return "bool"
    if name == "char": return "c_char"
    if name == "signed char": return "c_char"
    if name == "unsigned char": return "u8"
    if name == "short": return "c_short"
    if name == "unsigned short": return "c_ushort"
    if name == "int": return "c_int"
    if name == "unsigned int": return "c_uint"
    if name == "long": return "c_long"
    if name == "unsigned long": return "c_ulong"
    if name == "long long": return "c_longlong"
    if name == "unsigned long long": return "c_ulonglong"
    if name == "__int128": return "i128"
    if name == "unsigned __int128": return "u128"
    if name == "float": return "f32"
    if name == "double": return "f64"
    if name == "long double": return "c_longdouble"
    // enum E → c_int (C enums are integers)
    if ci_starts_with(name, "enum "):
        return "c_int"
    // User-defined typedefs/records already emitted in the current translation unit.
    if ci_str_contains(g_macro_type_names, "|" ++ name ++ "|"):
        return ci_escape_reserved(name)
    // Unknown type → c_int (best we can do without struct support)
    "c_int"

// ── Reserved word escaping ──────────────────────────────────

fn ci_escape_reserved(name: str) -> str:
    if name == "fn": return "fn_"
    if name == "type": return "type_"
    if name == "let": return "let_"
    if name == "use": return "use_"
    if name == "match": return "match_"
    if name == "for": return "for_"
    if name == "while": return "while_"
    if name == "if": return "if_"
    if name == "else": return "else_"
    if name == "return": return "return_"
    if name == "true": return "true_"
    if name == "false": return "false_"
    if name == "mut": return "mut_"
    if name == "pub": return "pub_"
    if name == "in": return "in_"
    if name == "self": return "self_"
    if name == "extern": return "extern_"
    if name == "const": return "const_"
    if name == "select": return "select_"
    if name == "import": return "import_"
    if name == "as": return "as_"
    if name == "is": return "is_"
    if name == "not": return "not_"
    if name == "and": return "and_"
    if name == "or": return "or_"
    if name == "break": return "break_"
    if name == "continue": return "continue_"
    if name == "var": return "var_"
    if name == "comptime": return "comptime_"
    if name == "where": return "where_"
    if name == "trait": return "trait_"
    if name == "impl": return "impl_"
    if name == "enum": return "enum_"
    if name == "struct": return "struct_"
    if name == "defer": return "defer_"
    if name == "async": return "async_"
    if name == "await": return "await_"
    if name == "spawn": return "spawn_"
    if name == "move": return "move_"
    if name == "yield": return "yield_"
    if name == "gen": return "gen_"
    if name == "with": return "with_"
    if name == "error": return "error_"
    name

// ── String helpers ──────────────────────────────────────────

// ═══════════════════════════════════════════════════════════
// AST-based expression and statement translators (Phase 4-5)
// These use the with_ci_* cursor-based API for full AST walking.
// ═══════════════════════════════════════════════════════════

type CiValueExprIR {
    setup_stmt: CiStmtId = 0 as CiStmtId,
    value_expr: CiExprId = 0 as CiExprId,
}

type CiScope {
    ptr: *mut CiScopeState,
}
impl Copy for CiScope

type CiScopeState {
    names: HashMap[str, str],
    types: HashMap[str, str],
    name_log_keys: Vec[str],
    name_log_values: Vec[str],
    name_log_had: Vec[i32],
    type_log_keys: Vec[str],
    type_log_values: Vec[str],
    type_log_had: Vec[i32],
    return_type: str,
}

type CiScopeMark {
    name_log_len: i64,
    type_log_len: i64,
}
impl Copy for CiScopeMark

fn CiScope.new(return_type: str) -> CiScope:
    let ptr = with_alloc(sizeof[CiScopeState]()) as *mut CiScopeState
    unsafe:
        *ptr = CiScopeState {
            names: HashMap.new(),
            types: HashMap.new(),
            name_log_keys: Vec.new(),
            name_log_values: Vec.new(),
            name_log_had: Vec.new(),
            type_log_keys: Vec.new(),
            type_log_values: Vec.new(),
            type_log_had: Vec.new(),
            return_type,
        }
    CiScope { ptr }

fn CiScopeState.empty() -> CiScopeState:
    CiScopeState {
        names: HashMap.new(),
        types: HashMap.new(),
        name_log_keys: Vec.new(),
        name_log_values: Vec.new(),
        name_log_had: Vec.new(),
        type_log_keys: Vec.new(),
        type_log_values: Vec.new(),
        type_log_had: Vec.new(),
        return_type: "",
    }

// Produced by
// ci_lower_decl_stmt_structural; consumed by ci_lower_stmt_ir
// compound-stmt, ci_lower_for_stmt_ir, and the goto-body
// structural handler. `stmt_id` is the CiStmtId to emit (may
// be 0 if the decl lowered to nothing), `updated_scope` is the
// scope after registering the decl's name(s).
type CiDeclLoweringIR {
    updated_scope: CiScope,
    stmt_id: CiStmtId = 0 as CiStmtId,
}

type CiHoistedVarDecl {
    name: str = "",
    ty: str = "",
}

fn ci_expr_temp_name(session: i64, cursor: i32, tag: str) -> str:
    let id = ci_temp_id_for_cursor(cursor)
    "__ci_expr_" ++ tag ++ "_" ++ i64_to_string(id as i64)

fn ci_value_ir_invalid -> CiValueExprIR:
    CiValueExprIR {}

fn ci_value_ir_plain(value_expr: CiExprId) -> CiValueExprIR:
    CiValueExprIR {
        setup_stmt: 0 as CiStmtId,
        value_expr,
    }

fn ci_value_ir_valid(lowered: CiValueExprIR) -> bool:
    (lowered.value_expr as i32) != 0

// docs/mut.md Rev 8 §5.1 — accumulator helper. Owned-by-value `out` Vec
// is threaded through the recursion; the underlying buffer is shared by
// reference but the {len, cap} triple is reassigned on push so we return
// the updated Vec to avoid losing growth on the caller side.
fn ci_stmt_collect_flat_ids(stmts: CiStmtPool, stmt_id: CiStmtId) -> Vec[i32]:
    var out: Vec[i32] = Vec.new()
    if (stmt_id as i32) == 0:
        return out
    if stmts.kind(stmt_id) == CiStmtKind.CIS_BLOCK:
        if stmts.get_d2(stmt_id) != 0:
            out.push(stmt_id as i32)
            return out
        let start = stmts.get_d0(stmt_id)
        let count = stmts.get_d1(stmt_id)
        var i: i32 = 0
        while i < count:
            let child = ci_stmt_collect_flat_ids(stmts, (stmts.get_extra(start + i)) as CiStmtId)
            var ci: i32 = 0
            while ci < child.len() as i32:
                out.push(child.get(ci as i64))
                ci = ci + 1
            i = i + 1
        return out
    out.push(stmt_id as i32)
    out

fn CiStmtPool.from_flat_ids(self: CiStmtPool, ids: &Vec[i32]) -> CiStmtId:
    if ids.len() == 0:
        return 0 as CiStmtId
    if ids.len() == 1:
        return (ids.get(0)) as CiStmtId
    let start = self.extra_len()
    var i: i64 = 0
    while i < ids.len():
        let _ = self.add_extra(ids.get(i))
        i = i + 1
    self.block(start, ids.len() as i32)

fn CiStmtPool.merge_ir(self: CiStmtPool, first: CiStmtId, second: CiStmtId) -> CiStmtId:
    if (first as i32) == 0:
        return second
    if (second as i32) == 0:
        return first
    var ids: Vec[i32] = ci_stmt_collect_flat_ids(self.val(), first)
    let ids2 = ci_stmt_collect_flat_ids(self.val(), second)
    var si: i32 = 0
    while si < ids2.len() as i32:
        ids.push(ids2.get(si as i64))
        si = si + 1
    self.from_flat_ids(&ids)

fn CiStmtPool.merge3_ir(self: CiStmtPool, first: CiStmtId, second: CiStmtId, third: CiStmtId) -> CiStmtId:
    let intermediate = self.merge_ir(first, second)
    self.merge_ir(intermediate, third)

fn CiStmtPool.for_continue_runs_inc_ir(self: CiStmtPool, stmt_id: CiStmtId, inc_stmt_id: CiStmtId) -> CiStmtId:
    if (stmt_id as i32) == 0 or (inc_stmt_id as i32) == 0:
        return stmt_id
    let kind = self.kind(stmt_id)
    if kind == CiStmtKind.CIS_CONTINUE:
        return self.merge_ir( inc_stmt_id, self.continue_())
    if kind == CiStmtKind.CIS_BLOCK:
        let extra_start = self.get_d0(stmt_id)
        let count = self.get_d1(stmt_id)
        var rewritten_ids: Vec[i32] = Vec.new()
        var i: i32 = 0
        while i < count:
            let child_id = (self.get_extra(extra_start + i)) as CiStmtId
            let rewritten = self.for_continue_runs_inc_ir(child_id, inc_stmt_id)
            rewritten_ids.push(rewritten as i32)
            i = i + 1
        let new_start = self.extra_len()
        var ri: i64 = 0
        while ri < rewritten_ids.len():
            let _ = self.add_extra(rewritten_ids.get(ri))
            ri = ri + 1
        return self.block(new_start, count)
    if kind == CiStmtKind.CIS_IF:
        let cond_id = (self.get_d0(stmt_id)) as CiExprId
        let then_id = (self.get_d1(stmt_id)) as CiStmtId
        let else_id = (self.get_d2(stmt_id)) as CiStmtId
        let rewritten_then = self.for_continue_runs_inc_ir(then_id, inc_stmt_id)
        var rewritten_else: CiStmtId = 0 as CiStmtId
        if (else_id as i32) != 0:
            rewritten_else = self.for_continue_runs_inc_ir(else_id, inc_stmt_id)
        return self.if_stmt(cond_id, rewritten_then, rewritten_else)
    if kind == CiStmtKind.CIS_MATCH:
        let subject_id = self.get_d0(stmt_id)
        let arms_start = self.get_d1(stmt_id)
        let arm_count = self.get_d2(stmt_id)
        var rewritten_records: Vec[i32] = Vec.new()
        var cursor = arms_start
        var ai: i32 = 0
        while ai < arm_count:
            let value_count = self.get_extra(cursor)
            rewritten_records.push(value_count)
            cursor = cursor + 1
            var vi: i32 = 0
            while vi < value_count:
                rewritten_records.push(self.get_extra(cursor))
                cursor = cursor + 1
                vi = vi + 1
            let body_id = (self.get_extra(cursor)) as CiStmtId
            cursor = cursor + 1
            let rewritten_body = self.for_continue_runs_inc_ir(body_id, inc_stmt_id)
            rewritten_records.push(rewritten_body as i32)
            ai = ai + 1
        let new_start = self.extra_len()
        var ri: i64 = 0
        while ri < rewritten_records.len():
            let _ = self.add_extra(rewritten_records.get(ri))
            ri = ri + 1
        return self.add(CiStmtKind.CIS_MATCH, subject_id, new_start, arm_count, 0)
    if kind == CiStmtKind.CIS_WHILE or kind == CiStmtKind.CIS_DO_WHILE or kind == CiStmtKind.CIS_FOR:
        return stmt_id
    stmt_id

fn CiExprPool.default_expr_from_text(self: CiExprPool, default_text: str) -> CiExprId:
    if default_text.len() == 0:
        return 0 as CiExprId
    if default_text == "0":
        let zero_idx = self.add_string("0")
        return self.int_lit(zero_idx, 0 as CiTypeId)
    if default_text == "0.0":
        let zero_idx = self.add_string("0.0")
        return self.add(CiExprKind.CIE_FLOAT_LIT, zero_idx, 0, 0, 0 as CiTypeId)
    if default_text == "false":
        return self.bool_lit(0, 0 as CiTypeId)
    if default_text == "true":
        return self.bool_lit(1, 0 as CiTypeId)
    if default_text == "null":
        return self.null_ptr(0 as CiTypeId)
    0 as CiExprId

fn ci_subtree_has_break_for_current_switch(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_BREAK_STMT:
        return true
    if kind == CXK_SWITCH_STMT or kind == CXK_FOR_STMT or kind == CXK_WHILE_STMT or kind == CXK_DO_STMT:
        return false
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        if ci_subtree_has_break_for_current_switch(session, with_ci_child(session, cursor, i)):
            return true
        i = i + 1
    false

fn ci_subtree_has_continue_for_current_loop(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_CONTINUE_STMT:
        return true
    if kind == CXK_FOR_STMT or kind == CXK_WHILE_STMT or kind == CXK_DO_STMT:
        return false
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        if ci_subtree_has_continue_for_current_loop(session, with_ci_child(session, cursor, i)):
            return true
        i = i + 1
    false

fn CiStmtPool.rewrite_switch_continues_ir(self: CiStmtPool, exprs: CiExprPool, stmt_id: CiStmtId, flag_expr_sym: i32, flag_ty: CiTypeId) -> CiStmtId:
    if (stmt_id as i32) == 0:
        return stmt_id
    let kind = self.kind(stmt_id)
    if kind == CiStmtKind.CIS_CONTINUE:
        let lhs = exprs.ident(flag_expr_sym, flag_ty)
        let one_idx = exprs.add_string("1")
        let one = exprs.int_lit(one_idx, flag_ty)
        return self.merge_ir( self.assign(lhs, one), self.break_())
    if kind == CiStmtKind.CIS_BLOCK:
        let start = self.get_d0(stmt_id)
        let count = self.get_d1(stmt_id)
        var ids: Vec[i32] = Vec.new()
        var i = 0
        while i < count:
            let child = (self.get_extra(start + i)) as CiStmtId
            let rewritten = self.rewrite_switch_continues_ir(exprs, child, flag_expr_sym, flag_ty)
            if (rewritten as i32) != 0:
                ids.push(rewritten as i32)
            i = i + 1
        return self.from_flat_ids(&ids)
    if kind == CiStmtKind.CIS_IF:
        let cond = (self.get_d0(stmt_id)) as CiExprId
        let then_id = self.rewrite_switch_continues_ir(exprs, (self.get_d1(stmt_id)) as CiStmtId, flag_expr_sym, flag_ty)
        let else_id = self.rewrite_switch_continues_ir(exprs, (self.get_d2(stmt_id)) as CiStmtId, flag_expr_sym, flag_ty)
        return self.if_stmt(cond, then_id, else_id)
    if kind == CiStmtKind.CIS_MATCH:
        let subject_id = self.get_d0(stmt_id)
        let arms_start = self.get_d1(stmt_id)
        let arm_count = self.get_d2(stmt_id)
        var rewritten_records: Vec[i32] = Vec.new()
        var cursor = arms_start
        var ai: i32 = 0
        while ai < arm_count:
            let value_count = self.get_extra(cursor)
            rewritten_records.push(value_count)
            cursor = cursor + 1
            var vi: i32 = 0
            while vi < value_count:
                rewritten_records.push(self.get_extra(cursor))
                cursor = cursor + 1
                vi = vi + 1
            let body_id = (self.get_extra(cursor)) as CiStmtId
            cursor = cursor + 1
            let rewritten_body = self.rewrite_switch_continues_ir(exprs, body_id, flag_expr_sym, flag_ty)
            rewritten_records.push(rewritten_body as i32)
            ai = ai + 1
        let new_start = self.extra_len()
        var ri: i64 = 0
        while ri < rewritten_records.len():
            let _ = self.add_extra(rewritten_records.get(ri))
            ri = ri + 1
        return self.add(CiStmtKind.CIS_MATCH, subject_id, new_start, arm_count, 0)
    stmt_id

fn CiStmtPool.wrap_switch_match_breaks_ir(self: CiStmtPool, session: i64, body_cursor: i32, exprs: CiExprPool, types: CiTypePool, match_id: CiStmtId, loop_depth: i32) -> CiStmtId:
    if (match_id as i32) == 0:
        return match_id
    let has_break = ci_subtree_has_break_for_current_switch(session, body_cursor)
    let has_continue = ci_subtree_has_continue_for_current_loop(session, body_cursor)
    if not has_break and not has_continue:
        return match_id
    let flag_ty = types.named_type_from_text("i32")
    if (flag_ty as i32) == 0:
        return 0 as CiStmtId
    let flag_name = ci_expr_temp_name(session, body_cursor, "switch_continue")
    let flag_stmt_sym = self.add_string(flag_name)
    let flag_expr_sym = exprs.add_string(flag_name)
    let zero_idx = exprs.add_string("0")
    let zero = exprs.int_lit(zero_idx, flag_ty)
    let flag_decl = self.var_decl(flag_stmt_sym, flag_ty, zero, 1)
    let rewritten_match = if has_continue:
        self.rewrite_switch_continues_ir(exprs, match_id, flag_expr_sym, flag_ty)
    else:
        match_id
    let true_cond = exprs.bool_lit(1, 0 as CiTypeId)
    let loop_body = self.merge_ir( rewritten_match, self.break_())
    let loop_id = self.while_stmt(true_cond, loop_body)
    if not has_continue:
        return loop_id
    let flag_read = exprs.ident(flag_expr_sym, flag_ty)
    let zero_cmp_idx = exprs.add_string("0")
    let zero_cmp = exprs.int_lit(zero_cmp_idx, flag_ty)
    let cond = exprs.binary(CiBinOp.CIBO_NEQ, flag_read, zero_cmp, 0 as CiTypeId)
    let continue_body = self.continue_()
    let continue_if = self.if_stmt(cond, continue_body, 0 as CiStmtId)
    self.merge3_ir( flag_decl, loop_id, continue_if)

fn CiExprPool.bool_expr_from_value_ir(self: CiExprPool, session: i64, cursor: i32, value_id: CiExprId, types: CiTypePool) -> CiExprId:
    if (value_id as i32) == 0:
        return 0 as CiExprId
    if with_ci_type_is_bool(session, cursor) != 0:
        return value_id
    if with_ci_type_is_pointer(session, cursor) != 0:
        let null_e = self.null_ptr(0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, value_id, null_e, 0 as CiTypeId)
    if with_ci_type_is_float(session, cursor) != 0:
        let zero_idx = self.add_string("0.0")
        let zero_e = self.add(CiExprKind.CIE_FLOAT_LIT, zero_idx, 0, 0, 0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, value_id, zero_e, 0 as CiTypeId)
    let zero_idx = self.add_string("0")
    let zero_e = self.int_lit(zero_idx, 0 as CiTypeId)
    self.binary(CiBinOp.CIBO_NEQ, value_id, zero_e, 0 as CiTypeId)

fn CiExprPool.bool_value_expr_ir(self: CiExprPool, session: i64, cursor: i32, bool_expr_id: CiExprId, types: CiTypePool) -> CiExprId:
    if (bool_expr_id as i32) == 0:
        return 0 as CiExprId
    let ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
    if ty_str == "bool":
        return bool_expr_id
    let one_idx = self.add_string("1")
    let zero_idx = self.add_string("0")
    let one_e = self.int_lit(one_idx, 0 as CiTypeId)
    let zero_e = self.int_lit(zero_idx, 0 as CiTypeId)
    let int_expr = self.add(CiExprKind.CIE_TERNARY, bool_expr_id as i32, one_e as i32, zero_e as i32, 0 as CiTypeId)
    if ty_str.len() == 0 or ty_str == "i32" or ty_str == "c_int":
        return int_expr
    let target_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
    if (target_ty as i32) == 0:
        return int_expr
    self.cast(target_ty, int_expr)

fn ci_print_compact_stmt(stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, id: CiStmtId, depth: i32) -> str:
    if (id as i32) == 0:
        return ""
    let kind = stmts.kind(id)
    let indent = ci_make_indent(depth)

    if kind == CiStmtKind.CIS_BLOCK:
        let start = stmts.get_d0(id)
        let count = stmts.get_d1(id)
        var out = ""
        var i: i32 = 0
        while i < count:
            out = out ++ ci_print_compact_stmt(stmts, exprs, types, (stmts.get_extra(start + i)) as CiStmtId, depth)
            i = i + 1
        return out

    if kind == CiStmtKind.CIS_EXPR:
        let e = (stmts.get_d0(id)) as CiExprId
        return indent ++ ci_print_expr(exprs, types, e, 0, 0) ++ "\n"

    if kind == CiStmtKind.CIS_RETURN:
        let e = (stmts.get_d0(id)) as CiExprId
        if (e as i32) == 0:
            return indent ++ "return\n"
        return indent ++ "return " ++ ci_print_expr(exprs, types, e, 0, 0) ++ "\n"

    if kind == CiStmtKind.CIS_IF:
        let cond = (stmts.get_d0(id)) as CiExprId
        let then_b = (stmts.get_d1(id)) as CiStmtId
        let else_b = (stmts.get_d2(id)) as CiStmtId
        let brace = migrate_prefer_brace()
        var out = indent ++ "if " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ (if brace: " {\n" else: ":\n")
        let then_text = ci_print_compact_stmt(stmts, exprs, types, then_b, depth + 4)
        if then_text.len() > 0:
            out = out ++ then_text
        else:
            out = out ++ ci_make_indent(depth + 4) ++ "0\n"
        if (else_b as i32) != 0:
            out = out ++ indent ++ (if brace: "} else {\n" else: "else:\n")
            let else_text = ci_print_compact_stmt(stmts, exprs, types, else_b, depth + 4)
            if else_text.len() > 0:
                out = out ++ else_text
            else:
                out = out ++ ci_make_indent(depth + 4) ++ "0\n"
        if brace:
            out = out ++ indent ++ "}\n"
        return out

    if kind == CiStmtKind.CIS_VAR_DECL:
        let name_sym = stmts.get_d0(id)
        let ty_id = (stmts.get_d1(id)) as CiTypeId
        let init = (stmts.get_d2(id)) as CiExprId
        let flags = stmts.get_flags(id)
        let is_mut = flags % 2
        let kw = if is_mut != 0: "var " else: "let "
        let name = stmts.get_string(name_sym)
        var out = indent ++ kw ++ name ++ ": " ++ ci_print_type(types, ty_id)
        if (init as i32) != 0:
            out = out ++ " = " ++ ci_print_expr(exprs, types, init, 0, 0)
        return out ++ "\n"

    if kind == CiStmtKind.CIS_ASSIGN:
        let lhs = (stmts.get_d0(id)) as CiExprId
        let rhs = (stmts.get_d1(id)) as CiExprId
        var rhs_str = ci_print_expr(exprs, types, rhs, 0, 0)
        if exprs.kind(rhs) == CiExprKind.CIE_CAST:
            rhs_str = "(" ++ rhs_str ++ ")"
        else if exprs.kind(rhs) == CiExprKind.CIE_BINARY:
            let op = exprs.get_d0(rhs)
            if op == CiBinOp.CIBO_ADD or op == CiBinOp.CIBO_SUB or op == CiBinOp.CIBO_MUL or op == CiBinOp.CIBO_DIV or op == CiBinOp.CIBO_MOD or op == CiBinOp.CIBO_BIT_AND or op == CiBinOp.CIBO_BIT_OR or op == CiBinOp.CIBO_BIT_XOR or op == CiBinOp.CIBO_SHL or op == CiBinOp.CIBO_SHR:
                rhs_str = ci_strip_one_outer_paren(rhs_str)
        return indent ++ "(" ++ ci_print_expr(exprs, types, lhs, 0, 0) ++ " = " ++ rhs_str ++ ")\n"

    if kind == CiStmtKind.CIS_BREAK:
        return indent ++ "break\n"
    if kind == CiStmtKind.CIS_CONTINUE:
        return indent ++ "continue\n"

    ci_print_stmt(stmts, exprs, types, id, depth)

fn ci_effect_expr_needs_terminal_stmt(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)

    if kind == CXK_UNEXPOSED_STMT:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return ci_effect_expr_needs_terminal_stmt(session, inner)
        return true

    if kind == CXK_PAREN_EXPR or kind == 100 or kind == CXK_IMPLICIT_CAST or kind == 122:
        if nc == 1:
            return ci_effect_expr_needs_terminal_stmt(session, with_ci_child(session, cursor, 0))
        if nc > 0:
            return ci_effect_expr_needs_terminal_stmt(session, with_ci_child(session, cursor, nc - 1))
        return true

    if kind == CXK_CSTYLE_CAST:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return ci_effect_expr_needs_terminal_stmt(session, inner)
        return true

    if kind == CXK_BINARY_OP:
        let op = with_ci_binary_op(session, cursor)
        if op == BO_ASSIGN or op == BO_LAND or op == BO_LOR or op == BO_COMMA:
            return false
        return true

    if kind == CXK_COMPOUND_ASSIGN_OP:
        return false

    if kind == CXK_UNARY_OP:
        let op = with_ci_unary_op(session, cursor)
        if op == UO_PRE_INC or op == UO_PRE_DEC or op == UO_POST_INC or op == UO_POST_DEC:
            return false
        return true

    if kind == CXK_COND_OP:
        return false

    true

fn CiStmtPool.lower_cfprintf_effect_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiStmtId:
    if with_ci_cursor_kind(session, cursor) != CXK_CALL_EXPR:
        return 0 as CiStmtId
    let callee_name = ci_call_name_from_source_text(with_ci_cursor_source_text(session, cursor))
    if callee_name != "cfprintf":
        return 0 as CiStmtId

    let nc = with_ci_num_children(session, cursor)
    let first_arg = 1
    let arg_count = nc - first_arg
    if arg_count < 3:
        return 0 as CiStmtId
    if not ci_note_filtered_system_symbol_ref(session, "fprintf", CI_LIBC_KIND_FN):
        return 0 as CiStmtId

    var setup = 0 as CiStmtId
    let arg_ids: Vec[i32] = Vec.new()
    var ai = first_arg
    while ai < nc:
        let lowered = self.lower_value_expr_ir(session, with_ci_child(session, cursor, ai), exprs, types, scope)
        if not ci_value_ir_valid(lowered):
            return 0 as CiStmtId
        setup = self.merge_ir( setup, lowered.setup_stmt)
        arg_ids.push(lowered.value_expr as i32)
        ai = ai + 1

    let begin_args: Vec[i32] = Vec.new()
    begin_args.push(arg_ids.get(0))
    begin_args.push(arg_ids.get(1))
    let begin_call = exprs.build_named_call_expr("colour_begin", &begin_args)

    let fprintf_args: Vec[i32] = Vec.new()
    var fi: i64 = 1
    while fi < arg_ids.len():
        fprintf_args.push(arg_ids.get(fi))
        fi = fi + 1
    let fprintf_call = exprs.build_named_call_expr("fprintf", &fprintf_args)

    let end_args: Vec[i32] = Vec.new()
    end_args.push(arg_ids.get(1))
    let end_call = exprs.build_named_call_expr("colour_end", &end_args)

    let begin_stmt = self.expr_stmt(begin_call)
    let fprintf_stmt = self.expr_stmt(fprintf_call)
    let end_stmt = self.expr_stmt(end_call)
    self.merge_ir( setup, self.merge3_ir( begin_stmt, fprintf_stmt, end_stmt))

fn CiStmtPool.lower_effect_expr_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiStmtId:
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)

    if kind == CXK_UNEXPOSED_STMT:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return self.lower_effect_expr_ir(session, inner, exprs, types, scope)
        return 0 as CiStmtId

    if kind == CXK_PAREN_EXPR or kind == CXK_IMPLICIT_CAST or kind == 100 or kind == 122:
        if nc == 1:
            return self.lower_effect_expr_ir(session, with_ci_child(session, cursor, 0), exprs, types, scope)
        if nc > 0:
            return self.lower_effect_expr_ir(session, with_ci_child(session, cursor, nc - 1), exprs, types, scope)
        return 0 as CiStmtId

    if kind == CXK_CSTYLE_CAST:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return self.lower_effect_expr_ir(session, inner, exprs, types, scope)
        return 0 as CiStmtId

    if kind == CXK_CALL_EXPR:
        let cfp = self.lower_cfprintf_effect_ir(session, cursor, exprs, types, scope)
        if (cfp as i32) != 0:
            return cfp

    if kind == CXK_BINARY_OP and nc >= 2 and with_ci_binary_op(session, cursor) == BO_COMMA:
        let lhs_stmt = self.lower_effect_expr_ir(session, with_ci_child(session, cursor, 0), exprs, types, scope)
        let rhs_stmt = self.lower_effect_expr_ir(session, with_ci_child(session, cursor, 1), exprs, types, scope)
        return self.merge_ir( lhs_stmt, rhs_stmt)

    if kind == CXK_UNARY_OP and nc >= 1:
        let op = with_ci_unary_op(session, cursor)
        if op == UO_PRE_INC or op == UO_PRE_DEC or op == UO_POST_INC or op == UO_POST_DEC:
            let operand_cursor = with_ci_child(session, cursor, 0)
            let operand = self.lower_lvalue_expr_ir(session, operand_cursor, exprs, types, scope)
            if not ci_value_ir_valid(operand):
                return 0 as CiStmtId
            let one_idx = exprs.add_string("1")
            let one = exprs.int_lit(one_idx, 0 as CiTypeId)
            let delta_op = if op == UO_PRE_INC or op == UO_POST_INC: CiBinOp.CIBO_ADD else: CiBinOp.CIBO_SUB
            let rhs_expr = exprs.binary(delta_op, operand.value_expr, one, 0 as CiTypeId)
            let assign_stmt = self.assign(operand.value_expr, rhs_expr)
            return self.merge_ir( operand.setup_stmt, assign_stmt)

    let lowered = self.lower_value_expr_ir(session, cursor, exprs, types, scope)
    if not ci_value_ir_valid(lowered):
        return 0 as CiStmtId

    var tail_stmt = 0 as CiStmtId
    if ci_effect_expr_needs_terminal_stmt(session, cursor):
        tail_stmt = self.expr_stmt(lowered.value_expr)
    self.merge_ir( lowered.setup_stmt, tail_stmt)

fn CiStmtPool.prepare_stmt_subject_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope, tag: str) -> CiValueExprIR:
    let lowered = self.lower_value_expr_ir(session, cursor, exprs, types, scope)
    if not ci_value_ir_valid(lowered):
        return ci_value_ir_invalid()
    if (lowered.setup_stmt as i32) == 0:
        return lowered
    let temp = ci_expr_temp_name(session, cursor, tag)
    let temp_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
    if (temp_ty as i32) == 0:
        return ci_value_ir_invalid()
    let temp_stmt_name = self.add_string(temp)
    let temp_expr_name = exprs.add_string(temp)
    let decl_id = self.var_decl(temp_stmt_name, temp_ty, lowered.value_expr, 1)
    return CiValueExprIR {
        setup_stmt: self.merge_ir( lowered.setup_stmt, decl_id),
        value_expr: exprs.ident(temp_expr_name, temp_ty),
    }

fn CiStmtPool.prepare_stmt_condition_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiValueExprIR:
    let lowered = self.lower_value_expr_ir(session, cursor, exprs, types, scope)
    if not ci_value_ir_valid(lowered):
        return ci_value_ir_invalid()
    let bool_id = exprs.bool_expr_from_value_ir(session, cursor, lowered.value_expr, types)
    if (bool_id as i32) == 0:
        return ci_value_ir_invalid()
    CiValueExprIR {
        setup_stmt: lowered.setup_stmt,
        value_expr: bool_id,
    }

fn CiStmtPool.build_if_not_break_ir(self: CiStmtPool, exprs: CiExprPool, cond_expr: CiExprId) -> CiStmtId:
    let not_cond_id = exprs.unary(CiUnaryOp.CIUO_LOGICAL_NOT, cond_expr, 0 as CiTypeId)
    let break_id = self.break_()
    self.if_stmt(not_cond_id, break_id, 0 as CiStmtId)

fn CiStmtPool.render_value_expr_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, lowered: CiValueExprIR) -> str:
    if not ci_value_ir_valid(lowered):
        return ""
    if (lowered.setup_stmt as i32) == 0:
        return ci_print_expr(exprs, types, lowered.value_expr, 0, 0)
    let seq_name = ci_expr_temp_name(session, cursor, "seq")
    let tail_stmt = self.expr_stmt(lowered.value_expr)
    let body_stmt = self.merge_ir( lowered.setup_stmt, tail_stmt)
    if migrate_prefer_brace():
        return "with 0 as " ++ seq_name ++ " {\n" ++ ci_print_compact_stmt(self.val(), exprs, types, body_stmt, 4) ++ "}"
    "with 0 as " ++ seq_name ++ ":\n" ++ ci_print_compact_stmt(self.val(), exprs, types, body_stmt, 4)

fn ci_cursor_is_simple_storage_ref(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)
    if kind == CXK_UNEXPOSED_STMT:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return ci_cursor_is_simple_storage_ref(session, inner)
        return false
    if (kind == CXK_PAREN_EXPR or kind == 100 or kind == CXK_IMPLICIT_CAST) and nc == 1:
        return ci_cursor_is_simple_storage_ref(session, with_ci_child(session, cursor, 0))
    if kind != CXK_DECL_REF:
        return false
    let operand_ty = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
    if ci_starts_with(operand_ty, "fn("):
        return false
    true

fn ci_cursor_is_function_ref(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)
    if kind == CXK_UNEXPOSED_STMT:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return ci_cursor_is_function_ref(session, inner)
        return false
    if (kind == CXK_PAREN_EXPR or kind == 100 or kind == CXK_IMPLICIT_CAST) and nc == 1:
        return ci_cursor_is_function_ref(session, with_ci_child(session, cursor, 0))
    if kind != CXK_DECL_REF:
        return false
    let operand_ty = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
    if ci_starts_with(operand_ty, "fn("):
        return true
    let cxtype = with_ci_cursor_type(session, cursor)
    let canon_kind = with_ci_type_kind(session, cxtype)
    canon_kind == CXT_FunctionProto or canon_kind == CXT_FunctionNoProto

fn ci_literal_token_text(session: i64, cursor: i32) -> str:
    let token_text = with_ci_cursor_token_text(session, cursor)
    if token_text.len() > 0:
        return token_text
    with_ci_cursor_source_text(session, cursor)

// ── Phase-B IR lowering ──────────────────────────────────────
//
// ci_lower_expr_ir is the recursive entry point. For supported
// cursor kinds it produces a real CiExpr node. Unsupported kinds
// return 0 so callers can bail transactionally without polluting
// the structural pools.
//
// B2 covered literals + DeclRef. B3a adds the recursive entry
// point and CXK_PAREN_EXPR (trivial wrapper). Subsequent B3
// sub-commits add binary, unary, and cast lowering.
//
// Returns 0 (the null sentinel) when structural lowering fails.

// ── libclang CXType kind constants (subset) ────────────────
// Mirror `rt/clang_bridge.w` CXType_* values; kept inline so
// ci_type_from_libclang can switch on them without re-importing
// the bridge's let-constants.
let CXT_Void: i32 = 2
let CXT_Bool: i32 = 3
let CXT_Char_U: i32 = 4
let CXT_UChar: i32 = 5
let CXT_UShort: i32 = 8
let CXT_UInt: i32 = 9
let CXT_ULong: i32 = 10
let CXT_ULongLong: i32 = 11
let CXT_UInt128: i32 = 12
let CXT_Char_S: i32 = 13
let CXT_SChar: i32 = 14
let CXT_Short: i32 = 16
let CXT_Int: i32 = 17
let CXT_Long: i32 = 18
let CXT_LongLong: i32 = 19
let CXT_Int128: i32 = 20
let CXT_Float: i32 = 21
let CXT_Double: i32 = 22
let CXT_LongDouble: i32 = 23
let CXT_Float128: i32 = 30
let CXT_Half: i32 = 31
let CXT_Float16: i32 = 32
let CXT_Pointer: i32 = 101
let CXT_Record: i32 = 105
let CXT_Enum: i32 = 106
let CXT_FunctionNoProto: i32 = 110
let CXT_FunctionProto: i32 = 111

fn ci_cxtype_kind_is_int(kind: i32) -> bool:
    kind == CXT_Char_U or kind == CXT_UChar or kind == CXT_UShort or kind == CXT_UInt or kind == CXT_ULong or kind == CXT_ULongLong or kind == CXT_UInt128 or kind == CXT_Char_S or kind == CXT_SChar or kind == CXT_Short or kind == CXT_Int or kind == CXT_Long or kind == CXT_LongLong or kind == CXT_Int128

fn ci_cxtype_kind_is_float(kind: i32) -> bool:
    kind == CXT_Float or kind == CXT_Double or kind == CXT_LongDouble or kind == CXT_Float128 or kind == CXT_Half or kind == CXT_Float16

// ci_type_from_libclang — walks a libclang CXType tree into
// CiType nodes, preserving structural decomposition for
// pointers / arrays / function pointers and using CT_NAMED at
// leaves with the bridge's `with_ci_type_translated` spelling
// so the printed text matches the legacy translator byte-for-byte.
//
// Returns 0 as CiTypeId when the type is unrepresentable (e.g.
// CXType_Invalid, empty translated name, unbounded recursion).
// Callers that hit this must abort the current structural lowering
// path transactionally.
//
// Structural recursion stops at leaves: integer/float/record/enum
// types produce CT_NAMED(spelling) rather than CT_INT(bits) so
// the printed output is `c_int` / `u8` / `f32` / `struct Foo`
// exactly as with_ci_type_translated would print them. The
// structural value is in the pointer/array/fn_ptr nesting.
fn CiTypePool.type_from_libclang(self: CiTypePool, session: i64, cxtype: i32) -> CiTypeId:
    if cxtype < 0:
        return 0 as CiTypeId
    let kind = with_ci_type_kind(session, cxtype)

    if kind == CXT_Void:
        ci_trace_port("STRUCTURAL[b11.3.ty_void]")
        return self.ty_void()

    if kind == CXT_Bool:
        ci_trace_port("STRUCTURAL[b11.3.ty_bool]")
        return self.ty_bool()

    if ci_cxtype_kind_is_int(kind):
        ci_trace_port("STRUCTURAL[b11.3.ty_int]")
        let name = ci_normalize_translated_type_name(with_ci_type_translated(session, cxtype))
        if name.len() == 0:
            return 0 as CiTypeId
        let name_idx = self.add_string(name)
        return self.ty_named(name_idx)

    if ci_cxtype_kind_is_float(kind):
        ci_trace_port("STRUCTURAL[b11.3.ty_float]")
        let name = ci_normalize_translated_type_name(with_ci_type_translated(session, cxtype))
        if name.len() == 0:
            return 0 as CiTypeId
        let name_idx = self.add_string(name)
        return self.ty_named(name_idx)

    if kind == CXT_Pointer:
        ci_trace_port("STRUCTURAL[b11.3.ty_ptr]")
        let pointee_idx = with_ci_type_pointee(session, cxtype)
        if pointee_idx < 0:
            return 0 as CiTypeId
        // is_const comes from the pointee's qualifiers, matching
        // translate_type_recursive's `clang_isConstQualifiedType(pointee)`.
        let is_const = with_ci_type_is_const(session, pointee_idx)
        // Void pointee special-case: legacy translate_type_recursive
        // emits `*const c_void` / `*mut c_void`, not `*mut void`. The
        // structural CT_VOID prints as "void" which isn't the legacy
        // spelling — build CT_NAMED("c_void") for the pointee so the
        // printed form matches.
        let pointee_kind = with_ci_type_kind(session, pointee_idx)
        if pointee_kind == CXT_Void:
            let c_void_idx = self.add_string("c_void")
            let c_void_ty = self.ty_named(c_void_idx)
            return self.ty_pointer(c_void_ty, is_const)
        let pointee_ty = self.type_from_libclang(session, pointee_idx)
        if (pointee_ty as i32) == 0:
            return 0 as CiTypeId
        return self.ty_pointer(pointee_ty, is_const)

    if kind == CXT_ConstantArray:
        ci_trace_port("STRUCTURAL[b11.3.ty_array]")
        let elem_idx = with_ci_type_array_element(session, cxtype)
        if elem_idx < 0:
            return 0 as CiTypeId
        let elem_ty = self.type_from_libclang(session, elem_idx)
        if (elem_ty as i32) == 0:
            return 0 as CiTypeId
        let size = (with_ci_type_array_size(session, cxtype)) as i32
        return self.ty_array(elem_ty, size)

    if kind == CXT_IncompleteArray or kind == CXT_VariableArray or kind == CXT_DependentSizedArray:
        ci_trace_port("STRUCTURAL[b11.3.ty_array]")
        let elem_idx = with_ci_type_array_element(session, cxtype)
        if elem_idx < 0:
            return 0 as CiTypeId
        let elem_ty = self.type_from_libclang(session, elem_idx)
        if (elem_ty as i32) == 0:
            return 0 as CiTypeId
        return self.ty_array(elem_ty, CI_SIZE_INCOMPLETE)

    if kind == CXT_Record:
        ci_trace_port("STRUCTURAL[b11.3.ty_struct]")
        let name = ci_normalize_translated_type_name(with_ci_type_translated(session, cxtype))
        if name.len() == 0:
            return 0 as CiTypeId
        let name_idx = self.add_string(name)
        return self.ty_struct(name_idx)

    if kind == CXT_Enum:
        ci_trace_port("STRUCTURAL[b11.3.ty_enum]")
        let name = ci_normalize_translated_type_name(with_ci_type_translated(session, cxtype))
        if name.len() == 0:
            return 0 as CiTypeId
        let name_idx = self.add_string(name)
        return self.ty_enum(name_idx)

    if kind == CXT_FunctionProto or kind == CXT_FunctionNoProto:
        ci_trace_port("STRUCTURAL[b11.3.ty_fn_ptr]")
        let ret_idx = with_ci_type_result(session, cxtype)
        if ret_idx < 0:
            return 0 as CiTypeId
        let ret_ty = self.type_from_libclang(session, ret_idx)
        if (ret_ty as i32) == 0:
            return 0 as CiTypeId
        let arg_count = with_ci_type_arg_count(session, cxtype)
        let params_start = self.state.extra.len() as i32
        var i: i32 = 0
        while i < arg_count:
            let arg_idx = with_ci_type_arg(session, cxtype, i)
            if arg_idx < 0:
                return 0 as CiTypeId
            let arg_ty = self.type_from_libclang(session, arg_idx)
            if (arg_ty as i32) == 0:
                return 0 as CiTypeId
            let _ = self.add_extra(arg_ty as i32)
            i = i + 1
        return self.ty_fn_ptr(ret_ty, params_start, arg_count)

    // Typedef, elaborated, atomic, and other named wrappers.
    // Normalize builtin typedef spellings so C names like size_t do
    // not leak into generated With type positions.
    ci_trace_port("STRUCTURAL[b11.3.ty_named]")
    let name = ci_normalize_translated_type_name(with_ci_type_translated(session, cxtype))
    if name.len() == 0:
        return 0 as CiTypeId
    let name_idx = self.add_string(name)
    self.ty_named(name_idx)

fn CiTypePool.type_from_translated_text(self: CiTypePool, ty: str) -> CiTypeId:
    if ty.len() == 0:
        return 0 as CiTypeId
    if ty == "void":
        return self.ty_void()
    if ci_starts_with(ty, "*const "):
        let pointee = self.type_from_translated_text(ty.slice(7, ty.len()))
        if (pointee as i32) == 0:
            return 0 as CiTypeId
        return self.ty_pointer(pointee, 1)
    if ci_starts_with(ty, "*mut "):
        let pointee = self.type_from_translated_text(ty.slice(5, ty.len()))
        if (pointee as i32) == 0:
            return 0 as CiTypeId
        return self.ty_pointer(pointee, 0)
    let name_idx = self.add_string(ty)
    self.ty_named(name_idx)

fn ci_expr_is_zero_int_lit(exprs: CiExprPool, id: CiExprId) -> bool:
    if (id as i32) == 0:
        return false
    if exprs.kind(id) != CiExprKind.CIE_INT_LIT:
        return false
    exprs.get_string(exprs.get_d0(id)) == "0"

fn ci_expr_strip_casts_and_parens(exprs: CiExprPool, id: CiExprId) -> CiExprId:
    var cur = id
    var depth = 0
    while (cur as i32) != 0 and depth < 16:
        let kind = exprs.kind(cur)
        if kind == CiExprKind.CIE_PAREN:
            cur = (exprs.get_d0(cur)) as CiExprId
        else if kind == CiExprKind.CIE_CAST:
            cur = (exprs.get_d1(cur)) as CiExprId
        else:
            return cur
        depth = depth + 1
    cur

fn ci_expr_is_int_lit_text(exprs: CiExprPool, id: CiExprId, text: str) -> bool:
    let cur = ci_expr_strip_casts_and_parens(exprs, id)
    if (cur as i32) == 0 or exprs.kind(cur) != CiExprKind.CIE_INT_LIT:
        return false
    exprs.get_string(exprs.get_d0(cur)) == text

fn ci_expr_is_signed_long_max_atom(exprs: CiExprPool, id: CiExprId) -> bool:
    let cur = ci_expr_strip_casts_and_parens(exprs, id)
    if (cur as i32) == 0:
        return false
    if exprs.kind(cur) == CiExprKind.CIE_INT_LIT:
        return exprs.get_string(exprs.get_d0(cur)) == "9223372036854775807"
    if exprs.kind(cur) == CiExprKind.CIE_IDENT:
        let name = exprs.get_string(exprs.get_d0(cur))
        return name == "LONG_MAX" or name == "__LONG_MAX__"
    false

fn ci_expr_is_mul_two_signed_long_max(exprs: CiExprPool, id: CiExprId) -> bool:
    let cur = ci_expr_strip_casts_and_parens(exprs, id)
    if (cur as i32) == 0 or exprs.kind(cur) != CiExprKind.CIE_BINARY:
        return false
    let op = exprs.get_d0(cur)
    if op != CiBinOp.CIBO_MUL and op != CiBinOp.CIBO_MUL_WRAP:
        return false
    let lhs = (exprs.get_d1(cur)) as CiExprId
    let rhs = (exprs.get_d2(cur)) as CiExprId
    (ci_expr_is_signed_long_max_atom(exprs, lhs) and ci_expr_is_int_lit_text(exprs, rhs, "2")) or
    (ci_expr_is_signed_long_max_atom(exprs, rhs) and ci_expr_is_int_lit_text(exprs, lhs, "2"))

fn ci_expr_is_unsigned_long_max_sum(exprs: CiExprPool, lhs: CiExprId, rhs: CiExprId) -> bool:
    (ci_expr_is_mul_two_signed_long_max(exprs, lhs) and ci_expr_is_int_lit_text(exprs, rhs, "1")) or
    (ci_expr_is_mul_two_signed_long_max(exprs, rhs) and ci_expr_is_int_lit_text(exprs, lhs, "1"))

fn ci_cursor_type_is_pointerish(session: i64, cursor: i32) -> bool:
    if cursor < 0:
        return false
    if with_ci_type_is_pointer(session, cursor) != 0:
        return true
    let ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
    ci_starts_with(ty_str, "*")

fn ci_cursor_type_text(session: i64, cursor: i32) -> str:
    if cursor < 0:
        return ""
    let ty = with_ci_cursor_type(session, cursor)
    if ty < 0:
        return ""
    with_ci_type_translated(session, ty)

fn ci_index_base_is_raw_pointer(session: i64, cursor: i32, base_id: CiExprId, exprs: CiExprPool, types: CiTypePool) -> i32:
    let expr_ty = exprs.get_type(base_id)
    if (expr_ty as i32) != 0:
        if types.kind(expr_ty) == CiTypeKind.CT_ARRAY:
            return 0
        if types.kind(expr_ty) == CiTypeKind.CT_POINTER:
            return 1
    let peeled = ci_peel_transparent(session, cursor)
    let cursor_ty = ci_cursor_type_text(session, cursor)
    let peeled_ty = ci_cursor_type_text(session, peeled)
    if ci_cursor_is_array_type(session, cursor) or ci_cursor_is_array_type(session, peeled):
        return 0
    if (cursor_ty.len() > 0 and cursor_ty.byte_at(0) == 91) or (peeled_ty.len() > 0 and peeled_ty.byte_at(0) == 91):
        return 0
    if ci_cursor_type_is_pointerish(session, cursor):
        return 1
    if ci_cursor_type_is_pointerish(session, peeled):
        return 1
    0

fn ci_expr_is_string_lit(exprs: CiExprPool, id: CiExprId) -> bool:
    if (id as i32) == 0:
        return false
    exprs.kind(id) == CiExprKind.CIE_STRING_LIT

fn CiExprPool.coerce_init_expr_to_type(self: CiExprPool, types: CiTypePool, value_id: CiExprId, ty: str) -> CiExprId:
    if (value_id as i32) == 0 or ty.len() == 0:
        return value_id
    if ci_expr_is_zero_int_lit(self.val(), value_id) and (ci_starts_with(ty, "*") or ci_starts_with(ty, "Option[")):
        let ty_id = types.type_from_translated_text(ty)
        return self.null_ptr(ty_id)
    if ci_expr_is_string_lit(self.val(), value_id) and ci_starts_with(ty, "*"):
        return value_id
    value_id

fn ci_record_decl_cursor_for_type(session: i64, ty: i32) -> i32:
    if ty < 0:
        return -1
    let decl = with_ci_type_declaration(session, ty)
    if decl >= 0:
        let found = ci_record_decl_cursor_from_decl(session, decl)
        if found >= 0:
            return found
    let canonical = with_ci_type_canonical(session, ty)
    if canonical >= 0 and canonical != ty:
        let canonical_decl = with_ci_type_declaration(session, canonical)
        if canonical_decl >= 0:
            let canonical_found = ci_record_decl_cursor_from_decl(session, canonical_decl)
            if canonical_found >= 0:
                return canonical_found
    -1

fn ci_record_decl_cursor_from_decl(session: i64, decl: i32) -> i32:
    if decl < 0:
        return -1
    let kind = with_ci_cursor_kind(session, decl)
    if kind == CK_STRUCT or kind == CK_UNION:
        return decl
    let nc = with_ci_num_children(session, decl)
    var i = 0
    while i < nc:
        let child = with_ci_child(session, decl, i)
        let child_kind = with_ci_cursor_kind(session, child)
        if child_kind == CK_STRUCT or child_kind == CK_UNION:
            return child
        i = i + 1
    -1

fn ci_record_type_field_count(session: i64, ty: i32) -> i32:
    let decl = ci_record_decl_cursor_for_type(session, ty)
    if decl < 0:
        return 0
    var count = 0
    while ci_decl_field_cursor(session, decl, count) >= 0:
        count = count + 1
    count

fn ci_record_type_field_name(session: i64, ty: i32, field_idx: i32) -> str:
    let decl = ci_record_decl_cursor_for_type(session, ty)
    let field = ci_decl_field_cursor(session, decl, field_idx)
    if field < 0:
        return ""
    let raw_name = with_ci_cursor_spelling(session, field)
    let name = if raw_name.len() > 0: raw_name else: f"unnamed_{field_idx}"
    ci_escape_reserved(name)

fn ci_record_type_field_type(session: i64, ty: i32, field_idx: i32) -> str:
    let decl = ci_record_decl_cursor_for_type(session, ty)
    let field = ci_decl_field_cursor(session, decl, field_idx)
    if field < 0:
        return ""
    with_ci_type_translated(session, with_ci_cursor_type(session, field))

fn ci_record_type_field_cxtype(session: i64, ty: i32, field_idx: i32) -> i32:
    let decl = ci_record_decl_cursor_for_type(session, ty)
    let field = ci_decl_field_cursor(session, decl, field_idx)
    if field < 0:
        return -1
    with_ci_cursor_type(session, field)

var g_ci_record_count_cache_keys: Vec[str] = Vec.new()
var g_ci_record_count_cache_values: Vec[i32] = Vec.new()
var g_ci_record_field_cache_keys: Vec[str] = Vec.new()
var g_ci_record_field_name_cache_values: Vec[str] = Vec.new()
var g_ci_record_field_type_cache_values: Vec[str] = Vec.new()

fn ci_record_cache_type_text(session: i64, ty_text: str, ty: i32) -> str:
    if ty_text.len() > 0:
        return ty_text
    if ty >= 0:
        let translated = with_ci_type_translated(session, ty)
        if translated.len() > 0:
            return translated
        let canonical = with_ci_type_canonical(session, ty)
        if canonical >= 0 and canonical != ty:
            let canonical_translated = with_ci_type_translated(session, canonical)
            if canonical_translated.len() > 0:
                return canonical_translated
    f"#tyid:{ty}"

fn ci_record_count_cache_key(session: i64, ty_key: str) -> str:
    f"{session}:{ty_key}"

fn ci_record_field_cache_key(session: i64, ty_key: str, field_idx: i32) -> str:
    f"{session}:{ty_key}:{field_idx}"

fn ci_record_count_cache_lookup(key: str) -> i32:
    var i = 0
    while i < g_ci_record_count_cache_keys.len() as i32:
        if g_ci_record_count_cache_keys.get(i as i64) == key:
            return g_ci_record_count_cache_values.get(i as i64)
        i = i + 1
    -1

fn ci_record_count_cache_store(key: str, value: i32) -> void:
    g_ci_record_count_cache_keys.push(key)
    g_ci_record_count_cache_values.push(value)

fn ci_record_field_cache_lookup_index(key: str) -> i32:
    var i = 0
    while i < g_ci_record_field_cache_keys.len() as i32:
        if g_ci_record_field_cache_keys.get(i as i64) == key:
            return i
        i = i + 1
    -1

fn ci_record_field_cache_store(key: str, name: str, ty: str) -> void:
    g_ci_record_field_cache_keys.push(key)
    g_ci_record_field_name_cache_values.push(name)
    g_ci_record_field_type_cache_values.push(ty)

fn ci_init_list_record_field_count(session: i64, ty_text: str, ty: i32) -> i32:
    let ty_key = ci_record_cache_type_text(session, ty_text, ty)
    let key = ci_record_count_cache_key(session, ty_key)
    let cached = ci_record_count_cache_lookup(key)
    if cached >= 0:
        return cached
    var count = ci_record_type_field_count(session, ty)
    if count <= 0:
        count = ci_type_field_count(session, ty_text)
    ci_record_count_cache_store(key, count)
    count

fn ci_init_list_record_field_name(session: i64, ty_text: str, ty: i32, field_idx: i32) -> str:
    let ty_key = ci_record_cache_type_text(session, ty_text, ty)
    let key = ci_record_field_cache_key(session, ty_key, field_idx)
    let cached = ci_record_field_cache_lookup_index(key)
    if cached >= 0:
        return g_ci_record_field_name_cache_values.get(cached as i64)
    var name = ci_record_type_field_name(session, ty, field_idx)
    var field_ty = ci_record_type_field_type(session, ty, field_idx)
    if name.len() == 0:
        name = ci_type_field_name(session, ty_text, field_idx)
    if field_ty.len() == 0:
        field_ty = ci_type_field_type(session, ty_text, field_idx)
    ci_record_field_cache_store(key, name, field_ty)
    name

fn ci_init_list_record_field_type(session: i64, ty_text: str, ty: i32, field_idx: i32) -> str:
    let ty_key = ci_record_cache_type_text(session, ty_text, ty)
    let key = ci_record_field_cache_key(session, ty_key, field_idx)
    let cached = ci_record_field_cache_lookup_index(key)
    if cached >= 0:
        return g_ci_record_field_type_cache_values.get(cached as i64)
    var name = ci_record_type_field_name(session, ty, field_idx)
    var field_ty = ci_record_type_field_type(session, ty, field_idx)
    if name.len() == 0:
        name = ci_type_field_name(session, ty_text, field_idx)
    if field_ty.len() == 0:
        field_ty = ci_type_field_type(session, ty_text, field_idx)
    ci_record_field_cache_store(key, name, field_ty)
    field_ty

fn ci_init_list_record_field_cxtype(session: i64, ty_text: str, ty: i32, field_idx: i32) -> i32:
    if ci_type_field_count(session, ty_text) > 0:
        return -1
    ci_record_type_field_cxtype(session, ty, field_idx)

fn CiExprPool.lower_init_list_ir(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let nc = with_ci_num_children(session, cursor)
    let init_ty = with_ci_cursor_type(session, cursor)
    let init_ty_id = types.type_from_libclang(session, init_ty)
    let ty_str = with_ci_type_translated(session, init_ty)

    if ty_str.len() > 0 and ty_str.byte_at(0) == 91:
        let elem_cxtype = with_ci_type_array_element(session, init_ty)
        let elem_ty_str = ci_array_element_type(ty_str)
        let elem_field_count = ci_init_list_record_field_count(session, elem_ty_str, elem_cxtype)
        let elem_ty_id = if elem_cxtype >= 0: types.type_from_libclang(session, elem_cxtype) else: 0 as CiTypeId
        var item_ids: Vec[i32] = Vec.new()
        var ai = 0
        while ai < nc:
            let child = with_ci_child(session, cursor, ai)
            let child_kind = with_ci_cursor_kind(session, ci_peel_transparent(session, child))
            var item_id: CiExprId = 0 as CiExprId
            if elem_field_count > 0 and (child_kind != CXK_INIT_LIST and child_kind != CXK_COMPOUND_LITERAL):
                if ai + elem_field_count > nc:
                    return 0 as CiExprId
                var field_names: Vec[i32] = Vec.new()
                var field_values: Vec[i32] = Vec.new()
                var fi = 0
                while fi < elem_field_count:
                    let field_name = ci_init_list_record_field_name(session, elem_ty_str, elem_cxtype, fi)
                    let field_type = ci_init_list_record_field_type(session, elem_ty_str, elem_cxtype, fi)
                    if field_name.len() == 0:
                        return 0 as CiExprId
                    let raw_id = self.lower_expr_ir(session, with_ci_child(session, cursor, ai + fi), types, scope)
                    if (raw_id as i32) == 0:
                        return 0 as CiExprId
                    let coerced_id = self.coerce_init_expr_to_type(types, raw_id, field_type)
                    let field_idx = self.add_string(field_name)
                    field_names.push(field_idx)
                    field_values.push(coerced_id as i32)
                    fi = fi + 1
                let fields_start = self.extra_len() as i32
                var fj: i64 = 0
                while fj < field_names.len():
                    let _ = self.add_extra(field_names.get(fj))
                    let _ = self.add_extra(field_values.get(fj))
                    fj = fj + 1
                item_id = self.designated_init(fields_start, elem_field_count, elem_ty_id)
                ai = ai + elem_field_count
            else:
                item_id = self.lower_expr_ir(session, child, types, scope)
                ai = ai + 1
            if (item_id as i32) == 0:
                return 0 as CiExprId
            item_ids.push(item_id as i32)
        ci_trace_port("STRUCTURAL[b11.11.init_list]")
        let items_start = self.extra_len() as i32
        var ii: i64 = 0
        while ii < item_ids.len():
            let _ = self.add_extra(item_ids.get(ii))
            ii = ii + 1
        return self.init_list(items_start, item_ids.len() as i32, init_ty_id)
    let aggregate_field_count = ci_init_list_record_field_count(session, ty_str, init_ty)
    if aggregate_field_count > 0:
        var field_names: Vec[i32] = Vec.new()
        var field_values: Vec[i32] = Vec.new()
        var fi = 0
        while fi < nc:
            let field_name = ci_init_list_record_field_name(session, ty_str, init_ty, fi)
            let field_type = ci_init_list_record_field_type(session, ty_str, init_ty, fi)
            if field_name.len() == 0:
                return 0 as CiExprId
            let item_id_raw = self.lower_expr_ir(session, with_ci_child(session, cursor, fi), types, scope)
            if (item_id_raw as i32) == 0:
                return 0 as CiExprId
            let item_id = self.coerce_init_expr_to_type(types, item_id_raw, field_type)
            let field_idx = self.add_string(field_name)
            field_names.push(field_idx)
            field_values.push(item_id as i32)
            fi = fi + 1
        let fields_start = self.extra_len() as i32
        var fj: i64 = 0
        while fj < field_names.len():
            let _ = self.add_extra(field_names.get(fj))
            let _ = self.add_extra(field_values.get(fj))
            fj = fj + 1
        ci_trace_port("STRUCTURAL[b11.11.init_list]")
        return self.designated_init(fields_start, nc, init_ty_id)
    if nc == 1:
        return self.lower_expr_ir(session, with_ci_child(session, cursor, 0), types, scope)
    var item_ids: Vec[i32] = Vec.new()
    var ii = 0
    while ii < nc:
        let item_id = self.lower_expr_ir(session, with_ci_child(session, cursor, ii), types, scope)
        if (item_id as i32) == 0:
            return 0 as CiExprId
        item_ids.push(item_id as i32)
        ii = ii + 1
    ci_trace_port("STRUCTURAL[b11.11.init_list]")
    let items_start = self.extra_len() as i32
    var ij: i64 = 0
    while ij < item_ids.len():
        let _ = self.add_extra(item_ids.get(ij))
        ij = ij + 1
    self.init_list(items_start, item_ids.len() as i32, init_ty_id)

fn CiExprPool.lower_expr_ir(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let kind = with_ci_cursor_kind(session, cursor)

    if kind == CXK_UNEXPOSED_STMT:
        let inner_cursor = ci_find_last_expr_child(session, cursor)
        if inner_cursor >= 0:
            return self.lower_expr_ir(session, inner_cursor, types, scope)
        return 0 as CiExprId

    // UnexposedExpr (kind 100) — libclang's transparent wrapper
    // used for ImplicitCastExpr in this libclang build. Const-foldable
    // cursors short-circuit to CIE_INT_LIT; everything else: dispatches
    // to ci_lower_implicit_cast, falling back to plain peel-and-recurse
    // if the cast handler bails.
    if kind == 100:
        let nc = with_ci_num_children(session, cursor)
        if with_ci_eval_int_valid(session, cursor) != 0 and not ci_expr_children_need_rvalue_lowering(session, cursor):
            let ival = with_ci_eval_int_value(session, cursor)
            let text_idx = self.add_string(i64_to_string(ival))
            return self.int_lit(text_idx, 0 as CiTypeId)
        let inner_cursor = ci_find_last_expr_child(session, cursor)
        if nc == 1:
            let cast_id = self.lower_implicit_cast(session, cursor, types, scope)
            if (cast_id as i32) != 0:
                return cast_id
        if inner_cursor >= 0:
            return self.lower_expr_ir(session, inner_cursor, types, scope)

    // Literal + DeclRef leaves (B2).
    if kind == CXK_INT_LITERAL or kind == CXK_FLOAT_LITERAL or kind == CXK_STRING_LITERAL or kind == CXK_CHAR_LITERAL or kind == CXK_DECL_REF:
        return self.lower_literal_or_ref(session, cursor, kind, types, scope)

    // Parenthesized expression — wraps a single inner expr.
    if kind == CXK_PAREN_EXPR:
        let nc = with_ci_num_children(session, cursor)
        if nc == 1:
            let inner_cursor = with_ci_child(session, cursor, 0)
            let inner_id = self.lower_expr_ir(session, inner_cursor, types, scope)
            if (inner_id as i32) != 0:
                return self.add(CiExprKind.CIE_PAREN, inner_id as i32, 0, 0, 0 as CiTypeId)
        return 0 as CiExprId

    // Binary operator.
    if kind == CXK_BINARY_OP:
        let glibc_ctype_mask_id = self.lower_glibc_ctype_mask_macro(session, cursor, types, scope)
        if (glibc_ctype_mask_id as i32) != 0:
            return glibc_ctype_mask_id
        let bin_id = self.lower_binary_simple(session, cursor, types, scope)
        if (bin_id as i32) != 0:
            return bin_id
        let cmp_id = self.lower_binary_comparison(session, cursor, types, scope)
        if (cmp_id as i32) != 0:
            return cmp_id
        let log_id = self.lower_binary_logical(session, cursor, types, scope)
        if (log_id as i32) != 0:
            return log_id
        let ptr_id = self.lower_binary_pointer(session, cursor, types, scope)
        if (ptr_id as i32) != 0:
            return ptr_id
        let shift_id = self.lower_binary_shift(session, cursor, types, scope)
        if (shift_id as i32) != 0:
            return shift_id
        let ptr_asgn_id = self.lower_binary_ptr_assign(session, cursor, types, scope)
        if (ptr_asgn_id as i32) != 0:
            return ptr_asgn_id
        if with_ci_eval_int_valid(session, cursor) != 0:
            let text_idx = self.add_string(ci_eval_int_text(session, cursor))
            return self.int_lit(text_idx, 0 as CiTypeId)
        return 0 as CiExprId

    // Unary operator.
    if kind == CXK_UNARY_OP:
        return self.lower_unary_simple(session, cursor, types, scope)

    // Implicit cast.
    if kind == CXK_IMPLICIT_CAST:
        return self.lower_implicit_cast(session, cursor, types, scope)

    // Member access — `base.field`.
    if kind == CXK_MEMBER_REF:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            let base_cursor = with_ci_child(session, cursor, 0)
            let base_id = self.lower_expr_ir(session, base_cursor, types, scope)
            let field = with_ci_member_field_name(session, cursor)
            if (base_id as i32) != 0 and field.len() > 0:
                let escaped = ci_escape_reserved(field)
                let field_idx = self.add_string(escaped)
                let field_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
                return self.add(CiExprKind.CIE_FIELD, base_id as i32, field_idx, 0, field_ty)
        return 0 as CiExprId

    // Array subscript — `base[idx]`.
    if kind == CXK_ARRAY_SUBSCRIPT:
        let glibc_ctype_case_id = self.lower_glibc_ctype_case_macro(session, cursor, types, scope)
        if (glibc_ctype_case_id as i32) != 0:
            return glibc_ctype_case_id
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let arr_cursor = with_ci_child(session, cursor, 0)
            let idx_cursor = with_ci_child(session, cursor, 1)
            let arr_id = self.lower_expr_ir(session, arr_cursor, types, scope)
            let idx_id = self.lower_expr_ir(session, idx_cursor, types, scope)
            if (arr_id as i32) != 0 and (idx_id as i32) != 0:
                let raw_ptr_index = ci_index_base_is_raw_pointer(session, arr_cursor, arr_id, self.val(), types)
                return self.add(CiExprKind.CIE_INDEX, arr_id as i32, idx_id as i32, raw_ptr_index, 0 as CiTypeId)
        return 0 as CiExprId

    // Call expression.
    if kind == CXK_CALL_EXPR:
        return self.lower_call_simple(session, cursor, types, scope)

    // Compound assignment.
    if kind == CXK_COMPOUND_ASSIGN_OP:
        return self.lower_compound_assign(session, cursor, types, scope)

    // Ternary / conditional operator.
    if kind == CXK_COND_OP:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 3:
            let cond_cursor = with_ci_child(session, cursor, 0)
            let then_cursor = with_ci_child(session, cursor, 1)
            let else_cursor = with_ci_child(session, cursor, 2)
            ci_trace_port("STRUCTURAL[b11.1.cond_op]")
            let cond_id = self.lower_bool_expr(session, cond_cursor, types, scope)
            if (cond_id as i32) != 0:
                let then_id = self.lower_expr_ir(session, then_cursor, types, scope)
                if (then_id as i32) != 0:
                    let else_id = self.lower_expr_ir(session, else_cursor, types, scope)
                    if (else_id as i32) != 0:
                        return self.add(CiExprKind.CIE_TERNARY, cond_id as i32, then_id as i32, else_id as i32, 0 as CiTypeId)
        if with_ci_eval_int_valid(session, cursor) != 0:
            let text_idx = self.add_string(ci_eval_int_text(session, cursor))
            return self.int_lit(text_idx, 0 as CiTypeId)
        return 0 as CiExprId

    // Compound literal.
    if kind == CXK_COMPOUND_LITERAL:
        let init_cursor = ci_find_child_of_kind(session, cursor, CXK_INIT_LIST)
        if init_cursor >= 0:
            return self.lower_init_list_ir(session, init_cursor, types, scope)
        return 0 as CiExprId

    // sizeof expression. Structurally builds CIE_SIZEOF_TYPE on
    // the argument's libclang type via ci_type_from_libclang.
    if kind == CXK_UNARY_EXPR:
        let src = with_ci_cursor_source_text(session, cursor)
        if ci_starts_with(src, "sizeof"):
            let rest = ci_trim(src.slice(6, src.len()))
            if rest.len() > 0 and rest.byte_at(0) == 40:
                let close = ci_find_matching_paren(rest, 0)
                if close > 0:
                    let inner = ci_trim(rest.slice(1, close as i64))
                    let mapped = ci_map_sizeof_type(inner)
                    if mapped.len() > 0:
                        let mapped_ty = types.named_type_from_text(mapped)
                        if (mapped_ty as i32) != 0:
                            return self.add(CiExprKind.CIE_SIZEOF_TYPE, mapped_ty as i32, 0, 0, 0 as CiTypeId)
            let nc = with_ci_num_children(session, cursor)
            if nc > 0:
                ci_trace_port("STRUCTURAL[b11.4.sizeof_ue]")
                let arg_ty = with_ci_cursor_type(session, with_ci_child(session, cursor, 0))
                let arg_ty_id = types.type_from_libclang(session, arg_ty)
                if (arg_ty_id as i32) != 0:
                    // Unwrap outer array layers: `sizeof([N][M]T)`
                    // → `(N * (M * sizeof[T]()))`.
                    var cur_ty = arg_ty_id
                    var accum_factor: i32 = 1
                    var saw_array = false
                    while types.kind(cur_ty) == CiTypeKind.CT_ARRAY:
                        let size = types.get_d1(cur_ty)
                        if size == CI_SIZE_INCOMPLETE:
                            break
                        accum_factor = accum_factor * size
                        cur_ty = (types.get_d0(cur_ty)) as CiTypeId
                        saw_array = true
                    let sizeof_id = self.add(CiExprKind.CIE_SIZEOF_TYPE, cur_ty as i32, 0, 0, 0 as CiTypeId)
                    if not saw_array:
                        return sizeof_id
                    let factor_text = i64_to_string(accum_factor as i64)
                    let factor_idx = self.add_string(factor_text)
                    let factor_id = self.int_lit(factor_idx, 0 as CiTypeId)
                    return self.binary(CiBinOp.CIBO_MUL, factor_id, sizeof_id, 0 as CiTypeId)
            else:
                if with_ci_eval_int_valid(session, cursor) != 0:
                    let text_idx = self.add_string(ci_eval_int_text(session, cursor))
                    return self.int_lit(text_idx, 0 as CiTypeId)
        return 0 as CiExprId

    // C-style cast.
    if kind == CXK_CSTYLE_CAST:
        let inner_child = ci_find_last_expr_child(session, cursor)
        if inner_child >= 0:
            let inner_id = self.lower_expr_ir(session, inner_child, types, scope)
            if (inner_id as i32) != 0:
                ci_trace_port("STRUCTURAL[b11.5.cstyle_cast]")
                let target_cxtype = with_ci_cursor_type(session, cursor)
                let target_ty_id = types.type_from_libclang(session, target_cxtype)
                if (target_ty_id as i32) != 0:
                    if types.kind(target_ty_id) == CiTypeKind.CT_POINTER:
                        let decayed_id = self.decay_array_value_expr(session, inner_child, inner_id, target_ty_id, types)
                        if (decayed_id as i32) != (inner_id as i32):
                            return decayed_id
                    return self.cast_if_needed(target_ty_id, inner_id, inner_child, session, types)
        return 0 as CiExprId

    if kind == CXK_INIT_LIST:
        return self.lower_init_list_ir(session, cursor, types, scope)

    // Every remaining kind (INIT_LIST, struct/union decl in expr
    // position, kind-100 with unusual child counts, anything not
    // otherwise handled) returns 0 so the caller can abort the
    // current structural lowering attempt transactionally.
    ci_record_raw_expr_kind(kind)
    0 as CiExprId

fn CiExprPool.lower_binary_simple(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        return 0 as CiExprId
    let op = with_ci_binary_op(session, cursor)

    // Arithmetic, bitwise non-shift, and plain assignment. Shift,
    // comparison, and logical ops need bigger structural work and
    // belong to later sub-commits.
    if op != BO_ADD and op != BO_SUB and op != BO_MUL and op != BO_DIV and op != BO_REM and op != BO_AND and op != BO_OR and op != BO_XOR and op != BO_ASSIGN:
        return 0 as CiExprId

    let lhs_cursor = with_ci_child(session, cursor, 0)
    let rhs_cursor = with_ci_child(session, cursor, 1)

    let lhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, lhs_cursor))
    let rhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, rhs_cursor))
    // Bail on pointer or array operands; legacy has dedicated arms
    // for pointer arith and array-decay handling.
    if op != BO_ASSIGN and ci_cursor_type_is_pointerish(session, lhs_cursor):
        return 0 as CiExprId
    if op != BO_ASSIGN and ci_cursor_type_is_pointerish(session, rhs_cursor):
        return 0 as CiExprId
    if lhs_ty_str.len() > 0 and lhs_ty_str.byte_at(0) == 91:
        return 0 as CiExprId
    if rhs_ty_str.len() > 0 and rhs_ty_str.byte_at(0) == 91:
        return 0 as CiExprId

    // Recursively lower operands. If either lowering bails we have
    // to bail too — we can't construct a partial CIE_BINARY.
    let lhs_id = self.lower_expr_ir(session, lhs_cursor, types, scope)
    if (lhs_id as i32) == 0:
        return 0 as CiExprId
    let rhs_id = self.lower_expr_ir(session, rhs_cursor, types, scope)
    if (rhs_id as i32) == 0:
        return 0 as CiExprId

    if op == BO_ASSIGN and ci_cursor_type_is_pointerish(session, lhs_cursor):
        let lhs_ty_id = types.type_from_libclang(session, with_ci_cursor_type(session, lhs_cursor))
        if (lhs_ty_id as i32) == 0:
            return 0 as CiExprId
        var rhs_value = self.coerce_value_expr_for_target(session, lhs_ty_id, rhs_cursor, rhs_id, types)
        if (rhs_value as i32) == 0:
            return 0 as CiExprId
        if lhs_ty_str != rhs_ty_str and ci_cursor_type_is_pointerish(session, rhs_cursor) and self.kind(rhs_value) != CiExprKind.CIE_CAST:
            rhs_value = self.cast(lhs_ty_id, rhs_value)
        return self.binary(CiBinOp.CIBO_ASSIGN, lhs_id, rhs_value, 0 as CiTypeId)

    // Pick the wrap variant for unsigned arithmetic on +, -, *.
    // Division, modulo, and bitwise ops never wrap in the legacy.
    let is_unsigned = with_ci_type_is_unsigned(session, cursor)
    var ci_op: i32 = 0
    if op == BO_ADD:
        if is_unsigned != 0:
            ci_op = CiBinOp.CIBO_ADD_WRAP
        else:
            ci_op = CiBinOp.CIBO_ADD
    if op == BO_SUB:
        if is_unsigned != 0:
            ci_op = CiBinOp.CIBO_SUB_WRAP
        else:
            ci_op = CiBinOp.CIBO_SUB
    if op == BO_MUL:
        if is_unsigned != 0:
            ci_op = CiBinOp.CIBO_MUL_WRAP
        else:
            ci_op = CiBinOp.CIBO_MUL
    if op == BO_DIV:
        ci_op = CiBinOp.CIBO_DIV
    if op == BO_REM:
        ci_op = CiBinOp.CIBO_MOD
    if op == BO_AND:
        ci_op = CiBinOp.CIBO_BIT_AND
    if op == BO_OR:
        ci_op = CiBinOp.CIBO_BIT_OR
    if op == BO_XOR:
        ci_op = CiBinOp.CIBO_BIT_XOR
    if op == BO_ASSIGN:
        ci_op = CiBinOp.CIBO_ASSIGN

    // Large-decimal coercion (B3r): the legacy wraps a bare-
    // integer-literal operand in `(... as c_uint)` when its source
    // text exceeds i32 max, so the arithmetic uses c_uint semantics.
    // Assignment is exempt (legacy doesn't apply the coercion there).
    var lhs_value = lhs_id
    var rhs_value = rhs_id
    if op != BO_ASSIGN:
        let lhs_str = ci_print_expr(self.val(), types, lhs_id, 0, 0)
        let rhs_str = ci_print_expr(self.val(), types, rhs_id, 0, 0)
        let lhs_large = ci_is_large_decimal(lhs_str)
        let rhs_large = ci_is_large_decimal(rhs_str)
        let operand_unsigned = ci_non_literal_operand_is_unsigned(session, lhs_cursor, rhs_cursor, lhs_large, rhs_large)
        if lhs_large and ci_binary_op_allows_uint_literal_cast(op, operand_unsigned):
            let cast_ty = ci_binary_large_decimal_cast_type(session, cursor, op, false, types)
            if (cast_ty as i32) == 0:
                return 0 as CiExprId
            lhs_value = self.cast(cast_ty, lhs_value)
        if rhs_large and ci_binary_op_allows_uint_literal_cast(op, operand_unsigned):
            let cast_ty = ci_binary_large_decimal_cast_type(session, cursor, op, true, types)
            if (cast_ty as i32) == 0:
                return 0 as CiExprId
            rhs_value = self.cast(cast_ty, rhs_value)

        if ci_binary_op_uses_c_integer_promotions(op):
            lhs_value = self.promote_c_small_int_operand(session, lhs_cursor, ci_peel_transparent(session, lhs_cursor), lhs_value, types)
            if (lhs_value as i32) == 0:
                return 0 as CiExprId
            rhs_value = self.promote_c_small_int_operand(session, rhs_cursor, ci_peel_transparent(session, rhs_cursor), rhs_value, types)
            if (rhs_value as i32) == 0:
                return 0 as CiExprId
            if with_ci_type_is_unsigned(session, cursor) != 0:
                let result_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
                if (result_ty as i32) == 0:
                    return 0 as CiExprId
                lhs_value = self.cast(result_ty, lhs_value)
                rhs_value = self.cast(result_ty, rhs_value)

    self.binary(ci_op, lhs_value, rhs_value, 0 as CiTypeId)

// Check if a cursor's canonical type is any form of C array —
// constant-size `[N]T`, incomplete `[]T`, or variable-length
// array. Used to detect decayed-array operands whose translated
// type may not render with a leading `[` (e.g. extern incomplete
// arrays whose size is unknown in the current TU).
let CXT_ConstantArray: i32 = 112
let CXT_IncompleteArray: i32 = 114
let CXT_VariableArray: i32 = 115
let CXT_DependentSizedArray: i32 = 116

fn ci_cursor_is_array_type(session: i64, cursor: i32) -> bool:
    let ty = with_ci_cursor_type(session, cursor)
    if ty < 0:
        return false
    let k = with_ci_type_kind(session, ty)
    k == CXT_ConstantArray or k == CXT_IncompleteArray or k == CXT_VariableArray or k == CXT_DependentSizedArray

// Return the array element type as a With type string, or ""
// if the cursor isn't an array. Handles extern incomplete arrays
// whose translated string doesn't have a leading `[N]` prefix
// (e.g. `*const ucd_record` from a decayed `extern ... []` ref).
fn ci_array_elem_type_from_cursor(session: i64, cursor: i32) -> str:
    let ty = with_ci_cursor_type(session, cursor)
    if ty < 0:
        return ""
    let k = with_ci_type_kind(session, ty)
    if k == CXT_ConstantArray or k == CXT_IncompleteArray or k == CXT_VariableArray or k == CXT_DependentSizedArray:
        let elem_ty = with_ci_type_array_element(session, ty)
        if elem_ty >= 0:
            let translated = with_ci_type_translated(session, elem_ty)
            if translated.len() > 0:
                return translated
    // Fallback: parse the translated string form `[N]T` or `[]T`
    // to recover `T`.
    let arr_ty = with_ci_type_translated(session, ty)
    let elem_start = ci_find_array_elem_start(arr_ty)
    if elem_start > 0:
        return arr_ty.slice(elem_start as i64, arr_ty.len())
    ""

// Peel through transparent wrappers (ImplicitCast, ParenExpr,
// UnexposedExpr) to reach the semantically meaningful operand.
// Used to detect array-to-pointer decay casts so the arithmetic
// handler can re-apply the decay in the output.
fn ci_peel_transparent(session: i64, cursor: i32) -> i32:
    var c = cursor
    var depth = 0
    while depth < 16:
        let k = with_ci_cursor_kind(session, c)
        if k != CXK_IMPLICIT_CAST and k != CXK_PAREN_EXPR and k != 100:
            return c
        let nc = with_ci_num_children(session, c)
        if nc != 1:
            return c
        c = with_ci_child(session, c, 0)
        depth = depth + 1
    c

fn ci_peel_transparent_and_cstyle(session: i64, cursor: i32) -> i32:
    var c = ci_peel_transparent(session, cursor)
    var depth = 0
    while depth < 16 and with_ci_cursor_kind(session, c) == CXK_CSTYLE_CAST and with_ci_num_children(session, c) == 1:
        c = ci_peel_transparent(session, with_ci_child(session, c, 0))
        depth = depth + 1
    c

fn ci_cursor_contains_decl_ref(session: i64, cursor: i32, name: str, depth: i32) -> bool:
    if depth > 32 or cursor < 0:
        return false
    if with_ci_cursor_kind(session, cursor) == CXK_DECL_REF and with_ci_cursor_spelling(session, cursor) == name:
        return true
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        if ci_cursor_contains_decl_ref(session, with_ci_child(session, cursor, i), name, depth + 1):
            return true
        i = i + 1
    false

fn ci_glibc_ctype_mask_function(mask_name: str) -> str:
    if mask_name == "_ISalpha": return "isalpha"
    if mask_name == "_ISdigit": return "isdigit"
    if mask_name == "_ISalnum": return "isalnum"
    if mask_name == "_ISspace": return "isspace"
    if mask_name == "_ISupper": return "isupper"
    if mask_name == "_ISlower": return "islower"
    if mask_name == "_ISxdigit": return "isxdigit"
    if mask_name == "_ISprint": return "isprint"
    if mask_name == "_ISgraph": return "isgraph"
    if mask_name == "_ISpunct": return "ispunct"
    if mask_name == "_IScntrl": return "iscntrl"
    ""

fn CiExprPool.lower_glibc_ctype_mask_macro(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let expr_cursor = ci_peel_transparent(session, cursor)
    if with_ci_cursor_kind(session, expr_cursor) != CXK_BINARY_OP or with_ci_binary_op(session, expr_cursor) != BO_AND:
        return 0 as CiExprId
    if with_ci_num_children(session, expr_cursor) < 2:
        return 0 as CiExprId
    let lhs_cursor = with_ci_child(session, expr_cursor, 0)
    let rhs_cursor = with_ci_child(session, expr_cursor, 1)
    let rhs_peeled = ci_peel_transparent_and_cstyle(session, rhs_cursor)
    if with_ci_cursor_kind(session, rhs_peeled) != CXK_DECL_REF:
        return 0 as CiExprId
    let ctype_fn = ci_glibc_ctype_mask_function(with_ci_cursor_spelling(session, rhs_peeled))
    if ctype_fn.len() == 0:
        return 0 as CiExprId
    let lhs_peeled = ci_peel_transparent_and_cstyle(session, lhs_cursor)
    if with_ci_cursor_kind(session, lhs_peeled) != CXK_ARRAY_SUBSCRIPT or with_ci_num_children(session, lhs_peeled) < 2:
        return 0 as CiExprId
    let table_cursor = with_ci_child(session, lhs_peeled, 0)
    if not ci_cursor_contains_decl_ref(session, table_cursor, "__ctype_b_loc", 0):
        return 0 as CiExprId
    let arg_cursor = ci_peel_transparent_and_cstyle(session, with_ci_child(session, lhs_peeled, 1))
    var arg_id = self.lower_expr_ir(session, arg_cursor, types, scope)
    if (arg_id as i32) == 0:
        return 0 as CiExprId
    let c_int_ty = types.named_type_from_text("c_int")
    if (c_int_ty as i32) != 0:
        arg_id = self.cast_if_needed(c_int_ty, arg_id, arg_cursor, session, types)
    let args: Vec[i32] = Vec.new()
    args.push(arg_id as i32)
    ci_migrate_note_libc_symbol(ctype_fn)
    self.build_named_call_expr(ctype_fn, &args)

fn ci_glibc_ctype_case_function(cursor_name: str) -> str:
    if cursor_name == "__ctype_tolower_loc": return "tolower"
    if cursor_name == "__ctype_toupper_loc": return "toupper"
    ""

fn CiExprPool.lower_glibc_ctype_case_macro(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let expr_cursor = ci_peel_transparent_and_cstyle(session, cursor)
    if with_ci_cursor_kind(session, expr_cursor) != CXK_ARRAY_SUBSCRIPT or with_ci_num_children(session, expr_cursor) < 2:
        return 0 as CiExprId
    let table_cursor = with_ci_child(session, expr_cursor, 0)
    var ctype_fn = ""
    if ci_cursor_contains_decl_ref(session, table_cursor, "__ctype_tolower_loc", 0):
        ctype_fn = "tolower"
    else if ci_cursor_contains_decl_ref(session, table_cursor, "__ctype_toupper_loc", 0):
        ctype_fn = "toupper"
    if ctype_fn.len() == 0:
        return 0 as CiExprId
    let arg_cursor = ci_peel_transparent_and_cstyle(session, with_ci_child(session, expr_cursor, 1))
    var arg_id = self.lower_expr_ir(session, arg_cursor, types, scope)
    if (arg_id as i32) == 0:
        return 0 as CiExprId
    let c_int_ty = types.named_type_from_text("c_int")
    if (c_int_ty as i32) != 0:
        arg_id = self.cast_if_needed(c_int_ty, arg_id, arg_cursor, session, types)
    let args: Vec[i32] = Vec.new()
    args.push(arg_id as i32)
    ci_migrate_note_libc_symbol(ctype_fn)
    self.build_named_call_expr(ctype_fn, &args)

fn CiExprPool.lower_binary_pointer(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    self.lower_plain_value_expr_ir(session, cursor, types, scope)

fn CiExprPool.lower_binary_ptr_assign(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let nc = with_ci_num_children(session, cursor)
    if nc < 2 or with_ci_binary_op(session, cursor) != BO_ASSIGN:
        return 0 as CiExprId
    let lhs_cursor = with_ci_child(session, cursor, 0)
    let rhs_cursor = with_ci_child(session, cursor, 1)
    if not ci_cursor_type_is_pointerish(session, lhs_cursor) or not ci_cursor_type_is_pointerish(session, rhs_cursor):
        return 0 as CiExprId
    let lhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, lhs_cursor))
    let rhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, rhs_cursor))
    if lhs_ty_str == rhs_ty_str:
        return 0 as CiExprId
    let lhs_id = self.lower_expr_ir(session, lhs_cursor, types, scope)
    let rhs_id = self.lower_expr_ir(session, rhs_cursor, types, scope)
    let lhs_ty_id = types.type_from_libclang(session, with_ci_cursor_type(session, lhs_cursor))
    if (lhs_id as i32) == 0 or (rhs_id as i32) == 0 or (lhs_ty_id as i32) == 0:
        return 0 as CiExprId
    let rhs_cast = self.cast(lhs_ty_id, rhs_id)
    let assign_id = self.add(CiExprKind.CIE_ASSIGN, lhs_id as i32, rhs_cast as i32, 0, 0 as CiTypeId)
    self.add(CiExprKind.CIE_PAREN, assign_id as i32, 0, 0, 0 as CiTypeId)

fn CiExprPool.lower_binary_shift(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    self.lower_plain_value_expr_ir(session, cursor, types, scope)

fn CiExprPool.lower_binary_comparison(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        return 0 as CiExprId
    let op = with_ci_binary_op(session, cursor)
    if op != BO_EQ and op != BO_NE and op != BO_LT and op != BO_GT and op != BO_LE and op != BO_GE:
        return 0 as CiExprId

    let lhs_cursor = with_ci_child(session, cursor, 0)
    let rhs_cursor = with_ci_child(session, cursor, 1)

    // Comparison lowering preserves the historical printed shape:
    // recursively lower both operands, print them, then assemble
    // the `(if lhs OP rhs: 1 else: 0)` expression directly so the
    // CIE_TERNARY printer does not introduce extra parens.
    var lhs_id = self.lower_expr_ir(session, lhs_cursor, types, scope)
    if (lhs_id as i32) == 0:
        return 0 as CiExprId
    var rhs_id = self.lower_expr_ir(session, rhs_cursor, types, scope)
    if (rhs_id as i32) == 0:
        return 0 as CiExprId
    lhs_id = self.decay_binary_comparison_array_operands(session, lhs_cursor, lhs_id, rhs_cursor, rhs_id, 1, types)
    if (lhs_id as i32) == 0:
        return 0 as CiExprId
    rhs_id = self.decay_binary_comparison_array_operands(session, lhs_cursor, lhs_id, rhs_cursor, rhs_id, 0, types)
    if (rhs_id as i32) == 0:
        return 0 as CiExprId
    let lhs_str = ci_print_expr(self.val(), types, lhs_id, 0, 0)
    let rhs_str = ci_print_expr(self.val(), types, rhs_id, 0, 0)

    // Large-decimal operands get the `(... as c_uint)` cast treatment
    // in the legacy's non-comparison path, but the comparison path
    // ignores them. Still, bail if either is a large decimal to stay
    // consistent with the non-comparison arm.
    if ci_is_large_decimal(lhs_str):
        return 0 as CiExprId
    if ci_is_large_decimal(rhs_str):
        return 0 as CiExprId

    let is_unsigned = with_ci_type_is_unsigned(session, cursor)
    var ci_cmp_op: i32 = 0
    if op == BO_EQ: ci_cmp_op = CiBinOp.CIBO_EQ
    if op == BO_NE: ci_cmp_op = CiBinOp.CIBO_NEQ
    if op == BO_LT: ci_cmp_op = CiBinOp.CIBO_LT
    if op == BO_GT: ci_cmp_op = CiBinOp.CIBO_GT
    if op == BO_LE: ci_cmp_op = CiBinOp.CIBO_LTE
    if op == BO_GE: ci_cmp_op = CiBinOp.CIBO_GTE
    let cond_id = self.binary(ci_cmp_op, lhs_id, rhs_id, 0 as CiTypeId)
    let one_s = self.add_string("1")
    let zero_s = self.add_string("0")
    let one = self.int_lit(one_s, 0 as CiTypeId)
    let zero = self.int_lit(zero_s, 0 as CiTypeId)
    self.add(CiExprKind.CIE_TERNARY, cond_id as i32, one as i32, zero as i32, 0 as CiTypeId)

fn CiExprPool.lower_binary_logical(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        return 0 as CiExprId
    let op = with_ci_binary_op(session, cursor)
    if op != BO_LAND and op != BO_LOR:
        return 0 as CiExprId

    // `(if bool_lhs and bool_rhs: 1 else: 0)` — the bool operands
    // come from ci_lower_bool_expr which unwraps parens/casts and
    // short-circuits on comparisons. The cond_id is a structural
    // CIE_BINARY(LOGICAL_AND/OR) node.
    let lhs_cursor = with_ci_child(session, cursor, 0)
    let rhs_cursor = with_ci_child(session, cursor, 1)
    ci_trace_port("STRUCTURAL[b11.1.binary_logical]")
    let bool_lhs = self.lower_bool_expr(session, lhs_cursor, types, scope)
    let bool_rhs = self.lower_bool_expr(session, rhs_cursor, types, scope)
    if (bool_lhs as i32) == 0 or (bool_rhs as i32) == 0:
        return 0 as CiExprId
    let ci_log_op = if op == BO_LAND: CiBinOp.CIBO_LOGICAL_AND else: CiBinOp.CIBO_LOGICAL_OR
    let cond_id = self.binary(ci_log_op, bool_lhs, bool_rhs, 0 as CiTypeId)
    let one_s = self.add_string("1")
    let zero_s = self.add_string("0")
    let one = self.int_lit(one_s, 0 as CiTypeId)
    let zero = self.int_lit(zero_s, 0 as CiTypeId)
    self.add(CiExprKind.CIE_TERNARY, cond_id as i32, one as i32, zero as i32, 0 as CiTypeId)

fn ci_compound_to_ci_binop(op: i32) -> i32:
    if op == BO_ADD_ASSIGN: return CiBinOp.CIBO_ADD
    if op == BO_SUB_ASSIGN: return CiBinOp.CIBO_SUB
    if op == BO_MUL_ASSIGN: return CiBinOp.CIBO_MUL
    if op == BO_DIV_ASSIGN: return CiBinOp.CIBO_DIV
    if op == BO_REM_ASSIGN: return CiBinOp.CIBO_MOD
    if op == BO_AND_ASSIGN: return CiBinOp.CIBO_BIT_AND
    if op == BO_OR_ASSIGN: return CiBinOp.CIBO_BIT_OR
    if op == BO_XOR_ASSIGN: return CiBinOp.CIBO_BIT_XOR
    if op == BO_SHL_ASSIGN: return CiBinOp.CIBO_SHL
    if op == BO_SHR_ASSIGN: return CiBinOp.CIBO_SHR
    -1

fn CiExprPool.cast_shift_count_expr(self: CiExprPool, types: CiTypePool, rhs: CiExprId) -> CiExprId:
    let c_uint_ty = types.named_type_from_text("c_uint")
    if (c_uint_ty as i32) == 0:
        return 0 as CiExprId
    self.cast(c_uint_ty, rhs)

fn CiExprPool.lower_compound_assign(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        return 0 as CiExprId
    let op = with_ci_binary_op(session, cursor)
    let base_op = ci_compound_to_ci_binop(op)
    if base_op < 0:
        return 0 as CiExprId
    let lhs_cursor = with_ci_child(session, cursor, 0)
    let rhs_cursor = with_ci_child(session, cursor, 1)
    let lhs_id = self.lower_expr_ir(session, lhs_cursor, types, scope)
    if (lhs_id as i32) == 0:
        return 0 as CiExprId
    let rhs_id = self.lower_expr_ir(session, rhs_cursor, types, scope)
    if (rhs_id as i32) == 0:
        return 0 as CiExprId
    var rhs_value = rhs_id
    let lhs_ty = self.get_type(lhs_id)
    let lhs_is_ptr = ci_cursor_type_is_pointerish(session, lhs_cursor) or ((lhs_ty as i32) != 0 and types.kind(lhs_ty) == CiTypeKind.CT_POINTER)
    if lhs_is_ptr and (base_op == CiBinOp.CIBO_ADD or base_op == CiBinOp.CIBO_SUB):
        rhs_value = self.cast_pointer_index_expr(session, rhs_cursor, rhs_value, types)
        if (rhs_value as i32) == 0:
            return 0 as CiExprId
    if base_op == CiBinOp.CIBO_SHL or base_op == CiBinOp.CIBO_SHR:
        rhs_value = self.cast_shift_count_expr(types, rhs_value)
        if (rhs_value as i32) == 0:
            return 0 as CiExprId
    self.add(CiExprKind.CIE_COMPOUND_ASSIGN, base_op, lhs_id as i32, rhs_value as i32, 0 as CiTypeId)

fn CiExprPool.lower_unary_simple(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let nc = with_ci_num_children(session, cursor)
    if nc < 1:
        return 0 as CiExprId
    let op = with_ci_unary_op(session, cursor)
    if op < 0:
        return 0 as CiExprId

    if op == UO_PRE_INC or op == UO_PRE_DEC or op == UO_POST_INC or op == UO_POST_DEC:
        let child_cursor = with_ci_child(session, cursor, 0)
        let child_id = self.lower_expr_ir(session, child_cursor, types, scope)
        if (child_id as i32) == 0:
            return 0 as CiExprId
        let one_idx = self.add_string("1")
        let one = self.int_lit(one_idx, 0 as CiTypeId)
        let delta_op = if op == UO_PRE_INC or op == UO_POST_INC: CiBinOp.CIBO_ADD else: CiBinOp.CIBO_SUB
        let rhs_id = self.binary(delta_op, child_id, one, 0 as CiTypeId)
        let assign_id = self.add(CiExprKind.CIE_ASSIGN, child_id as i32, rhs_id as i32, 0, 0 as CiTypeId)
        return self.add(CiExprKind.CIE_PAREN, assign_id as i32, 0, 0, 0 as CiTypeId)

    self.lower_plain_value_expr_ir(session, cursor, types, scope)

// Type-string-based implicit cast classifier. Returns a CI_CAST_*
// code determined from with_ci_type_* helpers + translated type
// strings, avoiding with_ci_implicit_cast_kind which calls the
// crash-prone `clang_Type_getSizeOf` on incomplete types.
// Int-to-int size distinction (WIDEN vs TRUNC) is collapsed into
// INT_WIDEN — both produce the same `(inner as dest)` output via
// CIE_CAST anyway.
fn ci_classify_implicit_cast_safe(session: i64, cursor: i32, inner_cursor: i32) -> i32:
    let outer_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
    let inner_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, inner_cursor))
    if outer_ty_str.len() == 0 or inner_ty_str.len() == 0:
        return CI_CAST_NOOP
    if outer_ty_str == inner_ty_str:
        return CI_CAST_NOOP
    if outer_ty_str == "void" or outer_ty_str == "unit":
        return CI_CAST_TO_VOID
    // Function-to-pointer decay: a function-typed operand being
    // used in pointer context (e.g. as a call callee or function-
    // pointer arg) is a no-op from the printer's perspective —
    // the bare name already parses as a callable identifier.
    // Check the inner translated spelling ("fn(..." for normal
    // function types), the raw CXType kind (CXT_FunctionProto /
    // CXT_FunctionNoProto for builtins), AND the outer translated
    // spelling ("*const fn(" / "*mut fn(" for the decayed pointer
    // target) to catch all the shapes libclang produces for builtin
    // function decls.
    if ci_starts_with(inner_ty_str, "fn("):
        return CI_CAST_NOOP
    let inner_cxtype = with_ci_cursor_type(session, inner_cursor)
    let inner_canon_kind = with_ci_type_kind(session, inner_cxtype)
    if inner_canon_kind == CXT_FunctionProto or inner_canon_kind == CXT_FunctionNoProto:
        return CI_CAST_NOOP
    if ci_starts_with(outer_ty_str, "*const fn(") or ci_starts_with(outer_ty_str, "*mut fn("):
        return CI_CAST_NOOP
    let outer_is_bool = with_ci_type_is_bool(session, cursor) != 0
    let inner_is_bool = with_ci_type_is_bool(session, inner_cursor) != 0
    let outer_is_ptr = with_ci_type_is_pointer(session, cursor) != 0
    let inner_is_ptr = with_ci_type_is_pointer(session, inner_cursor) != 0
    let outer_is_float = with_ci_type_is_float(session, cursor) != 0
    let inner_is_float = with_ci_type_is_float(session, inner_cursor) != 0
    // Array detection: CT_ConstantArray/IncompleteArray/Variable etc.
    // ci_cursor_is_array_type handles the incomplete-array case
    // where with_ci_type_translated emits `*T` instead of `[]T`.
    let inner_is_array = ci_cursor_is_array_type(session, inner_cursor) or (inner_ty_str.byte_at(0) == 91)
    if outer_is_bool:
        if inner_is_ptr:
            return CI_CAST_PTR_TO_BOOL
        if inner_is_float:
            return CI_CAST_FLOAT_TO_BOOL
        return CI_CAST_INT_TO_BOOL
    if inner_is_bool:
        if outer_is_float:
            return CI_CAST_BOOL_TO_FLOAT
        return CI_CAST_BOOL_TO_INT
    if outer_is_ptr and not inner_is_ptr and not inner_is_array:
        let inner_kind = with_ci_cursor_kind(session, inner_cursor)
        if inner_kind == CXK_INT_LITERAL and with_ci_eval_int_valid(session, inner_cursor) != 0:
            if with_ci_eval_int_value(session, inner_cursor) == 0:
                return CI_CAST_NULL_TO_PTR
    if outer_is_ptr and inner_is_array:
        return CI_CAST_ARRAY_TO_PTR
    if outer_is_ptr and inner_is_ptr:
        return CI_CAST_PTR_CAST
    if outer_is_ptr:
        return CI_CAST_INT_TO_PTR
    if inner_is_ptr:
        return CI_CAST_PTR_TO_INT
    if not outer_is_float and inner_is_float:
        return CI_CAST_FLOAT_TO_INT
    if outer_is_float and not inner_is_float:
        return CI_CAST_INT_TO_FLOAT
    if outer_is_float and inner_is_float:
        return CI_CAST_FLOAT_CAST
    // Fall-through: int-to-int conversion where size comparison
    // is unsafe (would call clang_Type_getSizeOf). Use INT_WIDEN;
    // the CIE_CAST output is the same either way.
    CI_CAST_INT_WIDEN

fn CiExprPool.lower_implicit_cast(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let nc = with_ci_num_children(session, cursor)
    if nc < 1:
        return 0 as CiExprId
    let inner_cursor = with_ci_child(session, cursor, 0)
    // Use the safe type-string classifier; the raw bridge fn
    // with_ci_implicit_cast_kind calls clang_Type_getSizeOf which
    // crashes on certain incomplete types in libclang.
    let cast_kind = ci_classify_implicit_cast_safe(session, cursor, inner_cursor)

    // NULL_TO_PTR — emit `null` verbatim (legacy: `return "null"`).
    // The child cursor isn't referenced by the legacy output.
    if cast_kind == CI_CAST_NULL_TO_PTR:
        return self.null_ptr(0 as CiTypeId)

    // NOOP / FUNCTION_TO_PTR / LVALUE_TO_RVALUE / UNKNOWN fall
    // through to the legacy's `return inner` tail — the cast is a
    // structural no-op, just return the child id.
    if cast_kind == CI_CAST_NOOP or cast_kind == CI_CAST_FUNCTION_TO_PTR or cast_kind == CI_CAST_LVALUE_TO_RVALUE or cast_kind == CI_CAST_UNKNOWN:
        return self.lower_expr_ir(session, inner_cursor, types, scope)

    // *_TO_BOOL variants: emit `(inner != 0)` / `(inner != null)` /
    // `(inner != 0.0)` via CIE_BINARY.
    if cast_kind == CI_CAST_INT_TO_BOOL:
        let inner_id = self.lower_expr_ir(session, inner_cursor, types, scope)
        if (inner_id as i32) == 0:
            return 0 as CiExprId
        let zero_s = self.add_string("0")
        let zero = self.int_lit(zero_s, 0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, inner_id, zero, 0 as CiTypeId)

    if cast_kind == CI_CAST_PTR_TO_BOOL:
        let inner_id = self.lower_expr_ir(session, inner_cursor, types, scope)
        if (inner_id as i32) == 0:
            return 0 as CiExprId
        let null_e = self.null_ptr(0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, inner_id, null_e, 0 as CiTypeId)

    if cast_kind == CI_CAST_FLOAT_TO_BOOL:
        let inner_id = self.lower_expr_ir(session, inner_cursor, types, scope)
        if (inner_id as i32) == 0:
            return 0 as CiExprId
        let zero_s = self.add_string("0.0")
        let zero = self.add(CiExprKind.CIE_FLOAT_LIT, zero_s, 0, 0, 0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, inner_id, zero, 0 as CiTypeId)

    // Remaining kinds (ARRAY_TO_PTR, INT_TO_PTR, PTR_TO_INT,
    // BITCAST/PTR_CAST, INT_WIDEN*, INT_TRUNC, FLOAT_WIDEN/TRUNC,
    // FLOAT_TO_INT, INT_TO_FLOAT) build structural CIE_CASTs
    // over the recursively-lowered inner operand, using
    // ci_type_from_libclang for the target CiTypeId.
    let inner_id = self.lower_expr_ir(session, inner_cursor, types, scope)
    if (inner_id as i32) == 0:
        return 0 as CiExprId

    if cast_kind == CI_CAST_INT_TO_PTR:
        ci_trace_port("STRUCTURAL[b11.5.int_to_ptr]")
        // `(inner as usize as *mut c_void)`
        let usize_idx = types.add_string("usize")
        let usize_ty = types.ty_named(usize_idx)
        let c_void_idx = types.add_string("c_void")
        let c_void_ty = types.ty_named(c_void_idx)
        let void_ptr_ty = types.ty_pointer(c_void_ty, 0)
        let to_usize = self.cast(usize_ty, inner_id)
        return self.cast(void_ptr_ty, to_usize)

    if cast_kind == CI_CAST_PTR_TO_INT:
        ci_trace_port("STRUCTURAL[b11.5.ptr_to_int]")
        // `(inner as usize as DEST)`
        let dest_cxtype = with_ci_cursor_type(session, cursor)
        let dest_ty_id = types.type_from_libclang(session, dest_cxtype)
        if (dest_ty_id as i32) == 0:
            return 0 as CiExprId
        let usize_idx = types.add_string("usize")
        let usize_ty = types.ty_named(usize_idx)
        let to_usize = self.cast(usize_ty, inner_id)
        return self.cast(dest_ty_id, to_usize)

    if cast_kind == CI_CAST_ARRAY_TO_PTR:
        ci_trace_port("STRUCTURAL[b11.5.array_to_ptr]")
        let scoped_inner_ty = ci_scope_type_for_cursor(session, inner_cursor, scope)
        // `(&inner[0] as DEST)` — DEST preserves pointee const
        // qualifiers from the cast's destination type. Structural:
        //   CIE_INDEX(inner, int_lit(0)) → unsafe pointer/array-param index
        //   CIE_ADDR_OF(idx_e, mut=0)    → &inner[0]
        //   CIE_CAST(dest_ty, addr_e)    → (&inner[0] as dest)
        let dest_cxtype = with_ci_cursor_type(session, cursor)
        let dest_ty_id = types.type_from_libclang(session, dest_cxtype)
        if (dest_ty_id as i32) == 0:
            return 0 as CiExprId
        if with_ci_cursor_kind(session, ci_peel_transparent(session, inner_cursor)) == CXK_STRING_LITERAL:
            return self.cast_if_needed(dest_ty_id, inner_id, inner_cursor, session, types)
        if ci_starts_with(scoped_inner_ty, "*"):
            return self.cast_if_needed(dest_ty_id, inner_id, inner_cursor, session, types)
        let zero_s = self.add_string("0")
        let zero_e = self.int_lit(zero_s, 0 as CiTypeId)
        let idx_e = self.add(CiExprKind.CIE_INDEX, inner_id as i32, zero_e as i32, 1, 0 as CiTypeId)
        let addr_e = self.add(CiExprKind.CIE_ADDR_OF, idx_e as i32, 0, 0, 0 as CiTypeId)
        return self.cast(dest_ty_id, addr_e)

    if cast_kind == CI_CAST_BITCAST or cast_kind == CI_CAST_PTR_CAST:
        ci_trace_port("STRUCTURAL[b11.5.bitcast]")
        let dest_cxtype = with_ci_cursor_type(session, cursor)
        let dest_ty_id = types.type_from_libclang(session, dest_cxtype)
        if (dest_ty_id as i32) == 0:
            return 0 as CiExprId
        return self.cast_if_needed(dest_ty_id, inner_id, inner_cursor, session, types)

    if cast_kind == CI_CAST_INT_WIDEN or cast_kind == CI_CAST_INT_WIDEN_SIGN:
        ci_trace_port("STRUCTURAL[b11.5.int_widen]")
        let dest_cxtype = with_ci_cursor_type(session, cursor)
        let dest_ty_id = types.type_from_libclang(session, dest_cxtype)
        if (dest_ty_id as i32) == 0:
            return 0 as CiExprId
        return self.cast_if_needed(dest_ty_id, inner_id, inner_cursor, session, types)

    if cast_kind == CI_CAST_INT_TRUNC:
        ci_trace_port("STRUCTURAL[b11.5.int_trunc]")
        let dest_cxtype = with_ci_cursor_type(session, cursor)
        let dest_ty_id = types.type_from_libclang(session, dest_cxtype)
        if (dest_ty_id as i32) == 0:
            return 0 as CiExprId
        return self.cast_if_needed(dest_ty_id, inner_id, inner_cursor, session, types)

    if cast_kind == CI_CAST_FLOAT_CAST:
        ci_trace_port("STRUCTURAL[b11.5.float_cast]")
        let dest_cxtype = with_ci_cursor_type(session, cursor)
        let dest_ty_id = types.type_from_libclang(session, dest_cxtype)
        if (dest_ty_id as i32) == 0:
            return 0 as CiExprId
        return self.cast_if_needed(dest_ty_id, inner_id, inner_cursor, session, types)

    if cast_kind == CI_CAST_FLOAT_TO_INT:
        ci_trace_port("STRUCTURAL[b11.5.float_to_int]")
        let dest_cxtype = with_ci_cursor_type(session, cursor)
        let dest_ty_id = types.type_from_libclang(session, dest_cxtype)
        if (dest_ty_id as i32) == 0:
            return 0 as CiExprId
        return self.cast_if_needed(dest_ty_id, inner_id, inner_cursor, session, types)

    if cast_kind == CI_CAST_INT_TO_FLOAT:
        ci_trace_port("STRUCTURAL[b11.5.int_to_float]")
        let dest_cxtype = with_ci_cursor_type(session, cursor)
        let dest_ty_id = types.type_from_libclang(session, dest_cxtype)
        if (dest_ty_id as i32) == 0:
            return 0 as CiExprId
        return self.cast_if_needed(dest_ty_id, inner_id, inner_cursor, session, types)

    0 as CiExprId

// Helper: if target type matches the inner operand's translated
// type string, return inner_id unchanged (matches legacy
// ci_render_cast_expr's no-op prune for inner_ty == target_str);
// otherwise wrap in CIE_CAST. Also returns inner_id unchanged
// when the target is CT_VOID (legacy: target=="void" → return
// inner). The comparison uses the PRINTED form of target_ty
// against libclang's with_ci_type_translated of the inner
// cursor — same strings both sides.
fn CiExprPool.cast_if_needed(self: CiExprPool, target_ty_id: CiTypeId, inner_id: CiExprId, inner_cursor: i32, session: i64, types: CiTypePool) -> CiExprId:
    if (target_ty_id as i32) == 0:
        return inner_id
    if types.kind(target_ty_id) == CiTypeKind.CT_VOID:
        return inner_id
    if types.kind(target_ty_id) == CiTypeKind.CT_POINTER and ci_expr_is_zero_int_lit(self.val(), inner_id):
        return self.null_ptr(target_ty_id)
    let target_str = ci_print_type(types, target_ty_id)
    let inner_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, inner_cursor))
    if target_str == inner_ty_str:
        return inner_id
    self.cast(target_ty_id, inner_id)

fn ci_call_name_from_source_text(src: str) -> str:
    let s = ci_trim(src)
    if s.len() == 0:
        return ""
    var i: i32 = 0
    while i < s.len() as i32 and (ci_is_ident_char(s.byte_at(i as i64))):
        i = i + 1
    if i <= 0 or i >= s.len() as i32:
        return ""
    if s.byte_at(i as i64) != 40:
        return ""
    s.slice(0, i as i64)

fn CiExprPool.coerce_value_expr_for_target(self: CiExprPool, session: i64, target_ty_id: CiTypeId, value_cursor: i32, value_id: CiExprId, types: CiTypePool) -> CiExprId:
    if (target_ty_id as i32) == 0 or (value_id as i32) == 0:
        return value_id
    if types.kind(target_ty_id) != CiTypeKind.CT_POINTER:
        return value_id
    // Skip if already coerced
    if self.kind(value_id) == CiExprKind.CIE_ARRAY_DECAY or self.kind(value_id) == CiExprKind.CIE_CAST:
        return value_id
    let peeled = ci_peel_transparent(session, value_cursor)
    if with_ci_cursor_kind(session, peeled) != CXK_STRING_LITERAL and ci_cursor_is_array_type(session, peeled):
        let elem_ty = types.named_type_from_text(ci_array_elem_type_from_cursor(session, peeled))
        if (elem_ty as i32) == 0:
            return 0 as CiExprId
        return self.add(CiExprKind.CIE_ARRAY_DECAY, value_id as i32, elem_ty as i32, 0, target_ty_id)
    let value_ty = self.get_type(value_id)
    if (value_ty as i32) != 0 and types.kind(value_ty) == CiTypeKind.CT_ARRAY:
        let elem_ty = (types.get_d0(value_ty)) as CiTypeId
        return self.add(CiExprKind.CIE_ARRAY_DECAY, value_id as i32, elem_ty as i32, 0, target_ty_id)
    if ci_cursor_type_is_pointerish(session, value_cursor) or ci_cursor_type_is_pointerish(session, peeled) or ((value_ty as i32) != 0 and types.kind(value_ty) == CiTypeKind.CT_POINTER):
        let target_str = ci_print_type(types, target_ty_id)
        let value_str = with_ci_type_translated(session, with_ci_cursor_type(session, peeled))
        if value_str.len() > 0 and value_str != target_str:
            return self.cast(target_ty_id, value_id)
    value_id

fn ci_call_callee_name(session: i64, cursor: i32) -> str:
    // Walk through transparent wrappers (IMPLICIT_CAST, PAREN_EXPR,
    // and libclang's kind-100 UnexposedExpr which is what CALL_EXPR
    // callees typically show up as) to find the DECL_REF at the
    // head of a call expression. Returns the (unescaped) name or
    // "" if the callee isn't a plain direct reference.
    //
    // When libclang reports kind 100 at any level, fall through to
    // with_ci_cursor_spelling — the unexposed cursor preserves the
    // function name even when the inner DECL_REF isn't visible.
    var c = cursor
    while with_ci_cursor_kind(session, c) == CXK_IMPLICIT_CAST or with_ci_cursor_kind(session, c) == CXK_PAREN_EXPR:
        if with_ci_num_children(session, c) < 1:
            return ""
        c = with_ci_child(session, c, 0)
    let final_kind = with_ci_cursor_kind(session, c)
    if final_kind == CXK_DECL_REF or final_kind == 100:
        return with_ci_cursor_spelling(session, c)
    ""

fn ci_note_unsupported_offsetof(session: i64, cursor: i32):
    if g_ci_bail_message.len() == 0:
        g_ci_bail_message = "unsupported __builtin_offsetof expression"
        g_ci_bail_location = with_ci_cursor_location(session, cursor)
        g_ci_bail_kind = with_ci_cursor_kind(session, cursor)

fn CiExprPool.lower_offsetof_value_expr(self: CiExprPool, session: i64, cursor: i32) -> CiExprId:
    if with_ci_eval_int_valid(session, cursor) != 0:
        let text_idx = self.add_string(ci_eval_int_text(session, cursor))
        return self.int_lit(text_idx, 0 as CiTypeId)
    let src = with_ci_cursor_source_text(session, cursor)
    let offset_text = ci_try_translate_offsetof_expr(session, src)
    if offset_text.len() > 0:
        let text_idx = self.add_string(offset_text)
        return self.int_lit(text_idx, 0 as CiTypeId)
    ci_note_unsupported_offsetof(session, cursor)
    0 as CiExprId

fn CiExprPool.lower_call_simple(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    self.lower_plain_value_expr_ir(session, cursor, types, scope)

fn CiExprPool.lower_literal_or_ref(self: CiExprPool, session: i64, cursor: i32, kind: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    if kind == CXK_INT_LITERAL:
        var text: str = ""
        if with_ci_eval_int_valid(session, cursor) != 0:
            text = ci_eval_int_text(session, cursor)
        else:
            text = with_ci_cursor_source_text(session, cursor)
        let s = self.add_string(text)
        return self.int_lit(s, 0 as CiTypeId)

    if kind == CXK_FLOAT_LITERAL:
        var src = with_ci_cursor_source_text(session, cursor)
        if src.len() > 0:
            let last = src.byte_at(src.len() - 1)
            if last == 102 or last == 70 or last == 108 or last == 76:
                src = src.slice(0, src.len() - 1)
        let s = self.add_string(src)
        return self.add(CiExprKind.CIE_FLOAT_LIT, s, 0, 0, 0 as CiTypeId)

    if kind == CXK_STRING_LITERAL:
        let literal_src = ci_literal_token_text(session, cursor)
        if ci_is_concatenated_string(literal_src):
            let s = self.add_string(ci_concat_strings(literal_src))
            return self.add(CiExprKind.CIE_STRING_LIT, s, 0, 0, 0 as CiTypeId)
        if ci_is_string_literal(literal_src):
            let s = self.add_string(literal_src)
            return self.add(CiExprKind.CIE_STRING_LIT, s, 0, 0, 0 as CiTypeId)

        let expansion_src = with_ci_cursor_expansion_text(session, cursor)
        let expansion_arg = ci_string_macro_arg_from_expansion(session, cursor)
        let spelling_src = with_ci_cursor_spelling_text(session, cursor)
        let source_src = with_ci_cursor_source_text(session, cursor)
        let eval_src = with_ci_eval_as_str(session, cursor)
        let eval_text = ci_quote_evaluated_c_string(eval_src)
        let eval_is_safe = eval_src.len() > 0 and not ci_string_text_mentions_null_escape(expansion_src) and not ci_string_text_mentions_null_escape(spelling_src) and not ci_string_text_mentions_null_escape(source_src) and not ci_string_text_mentions_null_escape(literal_src)
        if eval_is_safe:
            let s = self.add_string(eval_text)
            return self.add(CiExprKind.CIE_STRING_LIT, s, 0, 0, 0 as CiTypeId)

        let expansion_expanded = ci_expand_string_macro_sequence(session, expansion_src)
        let expansion_arg_expanded = ci_expand_string_macro_sequence(session, expansion_arg)
        let spelling_expanded = ci_expand_string_macro_sequence(session, spelling_src)
        let source_expanded = ci_expand_string_macro_sequence(session, source_src)
        var preprocessed_expanded = ""
        var text = literal_src
        if expansion_expanded.len() > 0:
            text = expansion_expanded
        else if expansion_arg_expanded.len() > 0:
            text = expansion_arg_expanded
        else if spelling_expanded.len() > 0:
            text = spelling_expanded
        else if source_expanded.len() > 0:
            text = source_expanded
        else if literal_src.len() > 0 and literal_src.byte_at(0) == 34:
            text = ci_concat_strings(literal_src)
        else if literal_src.len() > 0:
            let stringify_val = ci_try_expand_stringify_call(session, literal_src)
            if stringify_val.len() > 0:
                text = stringify_val
            else:
                let preprocessed_raw_src = if expansion_src.len() > 0: expansion_src else if source_src.len() > 0: source_src else: literal_src
                preprocessed_expanded = ci_expand_string_macro_sequence(session, ci_preprocessed_string_sequence_for_cursor(session, cursor, preprocessed_raw_src))
                if preprocessed_expanded.len() > 0:
                    text = preprocessed_expanded
                else:
                    return 0 as CiExprId
        else:
            return 0 as CiExprId
        if preprocessed_expanded.len() == 0 and ci_string_text_contains_macro_like_ident(text):
            let preprocessed_raw_src = if expansion_src.len() > 0: expansion_src else if source_src.len() > 0: source_src else: literal_src
            preprocessed_expanded = ci_expand_string_macro_sequence(session, ci_preprocessed_string_sequence_for_cursor(session, cursor, preprocessed_raw_src))
        if text != preprocessed_expanded and preprocessed_expanded.len() > 0 and ci_string_text_contains_macro_like_ident(text):
            text = preprocessed_expanded
        if eval_is_safe and text != eval_text and ci_string_text_contains_macro_like_ident(text):
            text = eval_text
        let s = self.add_string(text)
        return self.add(CiExprKind.CIE_STRING_LIT, s, 0, 0, 0 as CiTypeId)

    if kind == CXK_CHAR_LITERAL:
        let literal_src = with_ci_cursor_source_text(session, cursor)
        let parsed_text = ci_char_to_int(literal_src)
        var text: str = ""
        if literal_src.len() >= 4 and literal_src.byte_at(1) == 92 and parsed_text.len() > 0:
            text = parsed_text
        else if with_ci_eval_int_valid(session, cursor) != 0:
            text = ci_eval_int_text(session, cursor)
        else if parsed_text.len() > 0:
            text = parsed_text
        else:
            text = literal_src
        let s = self.add_string(text)
        return self.add(CiExprKind.CIE_CHAR_LIT, s, 0, 0, 0 as CiTypeId)

    if kind == CXK_DECL_REF:
        let name = with_ci_cursor_spelling(session, cursor)
        let escaped = ci_escape_reserved(name)
        let mangled = ci_scope_lookup(scope, escaped)
        if mangled.len() == 0 and not ci_has_value_libc_call_mapping(name):
            if ci_libc_symbol_allowed_as(name, CI_LIBC_KIND_FN):
                if not ci_note_filtered_system_symbol_ref_at(session, cursor, name, CI_LIBC_KIND_FN):
                    return 0 as CiExprId
            else:
                if not ci_note_filtered_system_symbol_ref_at(session, cursor, name, CI_LIBC_KIND_VAR):
                    return 0 as CiExprId
        var text = ""
        if mangled.len() > 0:
            text = mangled
        else:
            text = escaped
        let s = self.add_string(text)
        var ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
        let scoped_ty = ci_scope_lookup_type(scope, escaped)
        if scoped_ty.len() > 0:
            let scoped_ty_id = types.type_from_translated_text(scoped_ty)
            if (scoped_ty_id as i32) != 0:
                ty = scoped_ty_id
        return self.ident(s, ty)

    0 as CiExprId

fn ci_trans_expr_via_ir(session: i64, cursor: i32, scope: CiScope) -> str:
    var types = CiTypePool.new()
    var exprs = CiExprPool.new()
    var stmts = CiStmtPool.new()
    let lowered = stmts.lower_value_expr_ir(session, cursor, exprs, types, scope)
    if not ci_value_ir_valid(lowered):
        stmts.deinit()
        exprs.deinit()
        types.deinit()
        return ""
    let rendered = stmts.render_value_expr_ir(session, cursor, exprs, types, lowered)
    stmts.deinit()
    exprs.deinit()
    types.deinit()
    rendered

fn ci_rvalue_needs_lowering(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)

    if kind == CXK_UNEXPOSED_STMT:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return ci_rvalue_needs_lowering(session, inner)
        return false

    if kind == CXK_PAREN_EXPR or kind == 100 or kind == CXK_IMPLICIT_CAST or kind == CXK_CSTYLE_CAST or kind == 122:
        if nc == 1:
            return ci_rvalue_needs_lowering(session, with_ci_child(session, cursor, 0))
        if nc > 0:
            return ci_rvalue_needs_lowering(session, with_ci_child(session, cursor, nc - 1))
        return false

    if kind == CXK_BINARY_OP:
        let op = with_ci_binary_op(session, cursor)
        if op == BO_ASSIGN or op == BO_COMMA:
            return true
        var i = 0
        while i < nc:
            if ci_rvalue_needs_lowering(session, with_ci_child(session, cursor, i)):
                return true
            i = i + 1
        return false

    if kind == CXK_COMPOUND_ASSIGN_OP:
        return true

    if kind == CXK_UNARY_OP:
        let op = with_ci_unary_op(session, cursor)
        if op == UO_PRE_INC or op == UO_PRE_DEC or op == UO_POST_INC or op == UO_POST_DEC:
            return true
        if nc >= 1:
            return ci_rvalue_needs_lowering(session, with_ci_child(session, cursor, 0))
        return false

    if kind == CXK_COND_OP or kind == CXK_CALL_EXPR or kind == CXK_MEMBER_REF or kind == CXK_ARRAY_SUBSCRIPT or kind == CXK_COMPOUND_LITERAL or kind == CXK_INIT_LIST or kind == 135:
        var i = 0
        while i < nc:
            if ci_rvalue_needs_lowering(session, with_ci_child(session, cursor, i)):
                return true
            i = i + 1
        return false

    if kind == CXK_UNARY_EXPR:
        if ci_starts_with(with_ci_cursor_source_text(session, cursor), "sizeof"):
            return false
        var i = 0
        while i < nc:
            if ci_rvalue_needs_lowering(session, with_ci_child(session, cursor, i)):
                return true
            i = i + 1
        return false

    false

fn ci_bo_to_str(op: i32) -> str:
    if op == BO_ADD: return "+"
    if op == BO_SUB: return "-"
    if op == BO_MUL: return "*"
    if op == BO_DIV: return "/"
    if op == BO_REM: return "%"
    if op == BO_AND: return "&"
    if op == BO_OR: return "|"
    if op == BO_XOR: return "^"
    if op == BO_SHL: return "<<"
    if op == BO_SHR: return ">>"
    if op == BO_LAND: return "and"
    if op == BO_LOR: return "or"
    if op == BO_LT: return "<"
    if op == BO_GT: return ">"
    if op == BO_LE: return "<="
    if op == BO_GE: return ">="
    if op == BO_EQ: return "=="
    if op == BO_NE: return "!="
    if op == BO_ASSIGN: return "="
    ""

fn ci_bo_to_str_typed(op: i32, is_unsigned: i32) -> str:
    if is_unsigned != 0:
        if op == BO_ADD: return "+%"
        if op == BO_SUB: return "-%"
        if op == BO_MUL: return "*%"
    ci_bo_to_str(op)

fn ci_compound_to_base_op(op: i32) -> str:
    if op == BO_ADD_ASSIGN: return "+"
    if op == BO_SUB_ASSIGN: return "-"
    if op == BO_MUL_ASSIGN: return "*"
    if op == BO_DIV_ASSIGN: return "/"
    if op == BO_REM_ASSIGN: return "%"
    if op == BO_AND_ASSIGN: return "&"
    if op == BO_OR_ASSIGN: return "|"
    if op == BO_XOR_ASSIGN: return "^"
    if op == BO_SHL_ASSIGN: return "<<"
    if op == BO_SHR_ASSIGN: return ">>"
    "+"

fn CiTypePool.named_type_from_text(self: CiTypePool, text: str) -> CiTypeId:
    if text.len() == 0:
        return 0 as CiTypeId
    let idx = self.add_string(ci_normalize_translated_type_name(text))
    self.ty_named(idx)

fn CiExprPool.build_named_call_expr(self: CiExprPool, name: str, arg_ids: &Vec[i32]) -> CiExprId:
    let callee_idx = self.add_string(name)
    let callee_id = self.ident(callee_idx, 0 as CiTypeId)
    let args_start = self.extra_len() as i32
    var i: i64 = 0
    while i < arg_ids.len():
        let _ = self.add_extra(arg_ids.get(i))
        i = i + 1
    self.add(CiExprKind.CIE_CALL, callee_id as i32, args_start, arg_ids.len() as i32, 0 as CiTypeId)

fn CiExprPool.decay_array_value_expr(self: CiExprPool, session: i64, original_cursor: i32, value_id: CiExprId, target_ty: CiTypeId, types: CiTypePool) -> CiExprId:
    let peeled = ci_peel_transparent(session, original_cursor)
    if with_ci_cursor_kind(session, peeled) == CXK_STRING_LITERAL:
        return value_id
    if not ci_cursor_is_array_type(session, peeled):
        let value_ty = self.get_type(value_id)
        if (value_ty as i32) != 0 and types.kind(value_ty) == CiTypeKind.CT_ARRAY:
            let elem_ty = (types.get_d0(value_ty)) as CiTypeId
            if (target_ty as i32) == 0 and (elem_ty as i32) == 0:
                return 0 as CiExprId
            return self.add(CiExprKind.CIE_ARRAY_DECAY, value_id as i32, elem_ty as i32, 0, target_ty)
        return value_id
    var elem_ty = 0 as CiTypeId
    let elem_text = ci_array_elem_type_from_cursor(session, peeled)
    if elem_text.len() > 0:
        elem_ty = types.named_type_from_text(elem_text)
    if (target_ty as i32) == 0 and (elem_ty as i32) == 0:
        return 0 as CiExprId
    self.add(CiExprKind.CIE_ARRAY_DECAY, value_id as i32, elem_ty as i32, 0, target_ty)

fn CiExprPool.decay_binary_comparison_array_operands(self: CiExprPool, session: i64, lhs_cursor: i32, lhs_id: CiExprId, rhs_cursor: i32, rhs_id: CiExprId, want_lhs: i32, types: CiTypePool) -> CiExprId:
    let own_cursor = if want_lhs != 0: lhs_cursor else: rhs_cursor
    let peer_cursor = if want_lhs != 0: rhs_cursor else: lhs_cursor
    let own_id = if want_lhs != 0: lhs_id else: rhs_id
    let peer_id = if want_lhs != 0: rhs_id else: lhs_id
    let own_peeled = ci_peel_transparent(session, own_cursor)
    let peer_peeled = ci_peel_transparent(session, peer_cursor)
    let own_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, own_cursor))
    let own_peeled_ty = with_ci_type_translated(session, with_ci_cursor_type(session, own_peeled))
    let peer_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, peer_cursor))
    let peer_peeled_ty = with_ci_type_translated(session, with_ci_cursor_type(session, peer_peeled))
    let own_expr_ty = self.get_type(own_id)
    let peer_expr_ty = self.get_type(peer_id)
    let own_is_array = ci_cursor_is_array_type(session, own_peeled) or (own_ty_str.len() > 0 and own_ty_str.byte_at(0) == 91) or (own_peeled_ty.len() > 0 and own_peeled_ty.byte_at(0) == 91) or ((own_expr_ty as i32) != 0 and types.kind(own_expr_ty) == CiTypeKind.CT_ARRAY)
    let peer_is_ptr = ci_cursor_type_is_pointerish(session, peer_cursor) or ci_cursor_type_is_pointerish(session, peer_peeled) or ((peer_expr_ty as i32) != 0 and types.kind(peer_expr_ty) == CiTypeKind.CT_POINTER)
    let peer_is_array = ci_cursor_is_array_type(session, peer_peeled) or (peer_ty_str.len() > 0 and peer_ty_str.byte_at(0) == 91) or (peer_peeled_ty.len() > 0 and peer_peeled_ty.byte_at(0) == 91) or ((peer_expr_ty as i32) != 0 and types.kind(peer_expr_ty) == CiTypeKind.CT_ARRAY)
    if own_is_array and (peer_is_ptr or peer_is_array):
        var target_ty = 0 as CiTypeId
        if peer_is_ptr:
            target_ty = types.type_from_libclang(session, with_ci_cursor_type(session, peer_cursor))
            if ((target_ty as i32) == 0 or types.kind(target_ty) != CiTypeKind.CT_POINTER) and (peer_expr_ty as i32) != 0 and types.kind(peer_expr_ty) == CiTypeKind.CT_POINTER:
                target_ty = peer_expr_ty
        return self.decay_array_value_expr(session, own_cursor, own_id, target_ty, types)
    own_id

fn CiExprPool.cast_pointer_index_expr(self: CiExprPool, session: i64, idx_cursor: i32, idx_id: CiExprId, types: CiTypePool) -> CiExprId:
    let usize_ty = types.named_type_from_text("usize")
    if (usize_ty as i32) == 0:
        return 0 as CiExprId
    let idx_peeled = ci_peel_transparent(session, idx_cursor)
    let idx_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, idx_cursor))
    let peeled_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, idx_peeled))
    let idx_is_unsigned_small = ci_type_is_unsigned_small_int(idx_ty_str) or ci_type_is_unsigned_small_int(peeled_ty_str) or ci_array_subscript_element_type_is_unsigned_small_int(session, idx_cursor)
    if idx_is_unsigned_small:
        let c_uint_ty = types.named_type_from_text("c_uint")
        if (c_uint_ty as i32) == 0:
            return 0 as CiExprId
        let as_uint = self.cast(c_uint_ty, idx_id)
        return self.cast(usize_ty, as_uint)
    if with_ci_type_is_unsigned(session, idx_cursor) != 0 or with_ci_type_is_unsigned(session, idx_peeled) != 0:
        return self.cast(usize_ty, idx_id)
    let isize_ty = types.named_type_from_text("isize")
    if (isize_ty as i32) == 0:
        return 0 as CiExprId
    let as_isize = self.cast(isize_ty, idx_id)
    self.cast(usize_ty, as_isize)

fn CiExprPool.build_binary_value_expr_from_ids(self: CiExprPool, session: i64, cursor: i32, lhs_cursor: i32, lhs_id: CiExprId, rhs_cursor: i32, rhs_id: CiExprId, types: CiTypePool) -> CiExprId:
    let op = with_ci_binary_op(session, cursor)

    if op == BO_EQ or op == BO_NE or op == BO_LT or op == BO_GT or op == BO_LE or op == BO_GE:
        var ci_cmp_op: i32 = 0
        if op == BO_EQ: ci_cmp_op = CiBinOp.CIBO_EQ
        if op == BO_NE: ci_cmp_op = CiBinOp.CIBO_NEQ
        if op == BO_LT: ci_cmp_op = CiBinOp.CIBO_LT
        if op == BO_GT: ci_cmp_op = CiBinOp.CIBO_GT
        if op == BO_LE: ci_cmp_op = CiBinOp.CIBO_LTE
        if op == BO_GE: ci_cmp_op = CiBinOp.CIBO_GTE
        var lhs_cmp = self.decay_binary_comparison_array_operands(session, lhs_cursor, lhs_id, rhs_cursor, rhs_id, 1, types)
        if (lhs_cmp as i32) == 0:
            return 0 as CiExprId
        var rhs_cmp = self.decay_binary_comparison_array_operands(session, lhs_cursor, lhs_cmp, rhs_cursor, rhs_id, 0, types)
        if (rhs_cmp as i32) == 0:
            return 0 as CiExprId
        if self.kind(lhs_cmp) == CiExprKind.CIE_CAST:
            lhs_cmp = self.add(CiExprKind.CIE_PAREN, lhs_cmp as i32, 0, 0, 0 as CiTypeId)
        if self.kind(rhs_cmp) == CiExprKind.CIE_CAST:
            rhs_cmp = self.add(CiExprKind.CIE_PAREN, rhs_cmp as i32, 0, 0, 0 as CiTypeId)
        let cond_id = self.binary(ci_cmp_op, lhs_cmp, rhs_cmp, 0 as CiTypeId)
        let one_idx = self.add_string("1")
        let zero_idx = self.add_string("0")
        let one = self.int_lit(one_idx, 0 as CiTypeId)
        let zero = self.int_lit(zero_idx, 0 as CiTypeId)
        return self.add(CiExprKind.CIE_TERNARY, cond_id as i32, one as i32, zero as i32, 0 as CiTypeId)

    if op != BO_ADD and op != BO_SUB and op != BO_MUL and op != BO_DIV and op != BO_REM and op != BO_AND and op != BO_OR and op != BO_XOR and op != BO_SHL and op != BO_SHR:
        return 0 as CiExprId

    let lhs_peeled = ci_peel_transparent(session, lhs_cursor)
    let rhs_peeled = ci_peel_transparent(session, rhs_cursor)
    let lhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, lhs_cursor))
    let rhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, rhs_cursor))
    let lhs_peeled_ty = with_ci_type_translated(session, with_ci_cursor_type(session, lhs_peeled))
    let rhs_peeled_ty = with_ci_type_translated(session, with_ci_cursor_type(session, rhs_peeled))
    let lhs_expr_ty = self.get_type(lhs_id)
    let rhs_expr_ty = self.get_type(rhs_id)
    let lhs_expr_ty_str = if (lhs_expr_ty as i32) != 0: ci_print_type(types, lhs_expr_ty) else: ""
    let lhs_expr_is_ptr = (lhs_expr_ty as i32) != 0 and types.kind(lhs_expr_ty) == CiTypeKind.CT_POINTER
    let rhs_expr_is_ptr = (rhs_expr_ty as i32) != 0 and types.kind(rhs_expr_ty) == CiTypeKind.CT_POINTER
    let lhs_expr_is_array = (lhs_expr_ty as i32) != 0 and types.kind(lhs_expr_ty) == CiTypeKind.CT_ARRAY
    let rhs_expr_is_array = (rhs_expr_ty as i32) != 0 and types.kind(rhs_expr_ty) == CiTypeKind.CT_ARRAY
    let lhs_is_ptr = ci_cursor_type_is_pointerish(session, lhs_cursor) or ci_cursor_type_is_pointerish(session, lhs_peeled) or lhs_expr_is_ptr
    let rhs_is_ptr = ci_cursor_type_is_pointerish(session, rhs_cursor) or ci_cursor_type_is_pointerish(session, rhs_peeled) or rhs_expr_is_ptr
    let lhs_is_array = (lhs_ty_str.len() > 0 and lhs_ty_str.byte_at(0) == 91) or (lhs_peeled_ty.len() > 0 and lhs_peeled_ty.byte_at(0) == 91) or ci_cursor_is_array_type(session, lhs_peeled) or lhs_expr_is_array
    let rhs_is_array = (rhs_ty_str.len() > 0 and rhs_ty_str.byte_at(0) == 91) or (rhs_peeled_ty.len() > 0 and rhs_peeled_ty.byte_at(0) == 91) or ci_cursor_is_array_type(session, rhs_peeled) or rhs_expr_is_array

    if op == BO_ADD and (lhs_is_ptr or rhs_is_ptr or lhs_is_array or rhs_is_array):
        let ptr_on_lhs = lhs_is_ptr or lhs_is_array
        let ptr_cursor = if ptr_on_lhs: lhs_cursor else: rhs_cursor
        var ptr_value = if ptr_on_lhs: lhs_id else: rhs_id
        let idx_cursor = if ptr_on_lhs: rhs_cursor else: lhs_cursor
        var idx_value = if ptr_on_lhs: rhs_id else: lhs_id
        let result_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
        ptr_value = self.decay_array_value_expr(session, ptr_cursor, ptr_value, result_ty, types)
        if (ptr_value as i32) == 0:
            return 0 as CiExprId
        idx_value = self.cast_pointer_index_expr(session, idx_cursor, idx_value, types)
        if (idx_value as i32) == 0:
            return 0 as CiExprId
        return self.binary(CiBinOp.CIBO_ADD, ptr_value, idx_value, 0 as CiTypeId)

    if op == BO_SUB and (lhs_is_ptr or lhs_is_array):
        var lhs_ptr_value = self.decay_array_value_expr(session, lhs_cursor, lhs_id, types.type_from_libclang(session, with_ci_cursor_type(session, lhs_cursor)), types)
        if (lhs_ptr_value as i32) == 0:
            return 0 as CiExprId
        if rhs_is_ptr or rhs_is_array:
            var rhs_ptr_value = self.decay_array_value_expr(session, rhs_cursor, rhs_id, types.type_from_libclang(session, with_ci_cursor_type(session, rhs_cursor)), types)
            if (rhs_ptr_value as i32) == 0:
                return 0 as CiExprId
            let usize_ty = types.named_type_from_text("usize")
            var elem_ty = 0 as CiTypeId
            let lhs_pointee = with_ci_cursor_pointee_type(session, lhs_cursor)
            if lhs_pointee.len() > 0:
                elem_ty = types.named_type_from_text(lhs_pointee)
            if (usize_ty as i32) == 0 or (elem_ty as i32) == 0:
                return 0 as CiExprId
            let lhs_usize = self.cast(usize_ty, lhs_ptr_value)
            let rhs_usize = self.cast(usize_ty, rhs_ptr_value)
            let diff = self.binary(CiBinOp.CIBO_SUB_WRAP, lhs_usize, rhs_usize, 0 as CiTypeId)
            let sizeof_ty = self.add(CiExprKind.CIE_SIZEOF_TYPE, elem_ty as i32, 0, 0, 0 as CiTypeId)
            return self.binary(CiBinOp.CIBO_DIV, diff, sizeof_ty, 0 as CiTypeId)
        let rhs_index = self.cast_pointer_index_expr(session, rhs_cursor, rhs_id, types)
        if (rhs_index as i32) == 0:
            return 0 as CiExprId
        return self.binary(CiBinOp.CIBO_SUB, lhs_ptr_value, rhs_index, 0 as CiTypeId)

    if lhs_is_ptr or rhs_is_ptr or lhs_is_array or rhs_is_array:
        return 0 as CiExprId

    let lhs_text = ci_print_expr(self.val(), types, lhs_id, 0, 0)
    let rhs_text = ci_print_expr(self.val(), types, rhs_id, 0, 0)
    let lhs_large = ci_is_large_decimal(lhs_text)
    let rhs_large = ci_is_large_decimal(rhs_text)
    let operand_unsigned = ci_non_literal_operand_is_unsigned(session, lhs_cursor, rhs_cursor, lhs_large, rhs_large)
    var lhs_value = lhs_id
    var rhs_value = rhs_id
    if op == BO_SHL or op == BO_SHR:
        let shift_result_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
        var shift_lhs_anchor_ty_str = ""
        if ci_type_is_integer_shift_anchor(shift_result_ty_str):
            shift_lhs_anchor_ty_str = shift_result_ty_str
        else if ci_shift_lhs_needs_integer_promotion(lhs_ty_str, lhs_peeled_ty, lhs_expr_ty_str) or ci_index_expr_element_type_is_small_int(self.val(), types, lhs_id) or ci_array_subscript_element_type_is_small_int(session, lhs_cursor) or ci_expr_tree_contains_small_int(self.val(), types, lhs_id, 0):
            shift_lhs_anchor_ty_str = "c_int"
        if ci_type_is_small_int(shift_lhs_anchor_ty_str):
            shift_lhs_anchor_ty_str = "c_int"
        if shift_lhs_anchor_ty_str.len() > 0:
            let shift_lhs_anchor_ty = types.named_type_from_text(shift_lhs_anchor_ty_str)
            if (shift_lhs_anchor_ty as i32) == 0:
                return 0 as CiExprId
            lhs_value = self.cast(shift_lhs_anchor_ty, lhs_value)
        else if ci_shift_lhs_needs_integer_promotion(lhs_ty_str, lhs_peeled_ty, lhs_expr_ty_str) or ci_index_expr_element_type_is_small_int(self.val(), types, lhs_id) or ci_array_subscript_element_type_is_small_int(session, lhs_cursor) or ci_expr_tree_contains_small_int(self.val(), types, lhs_id, 0):
            let c_int_ty = types.named_type_from_text("c_int")
            if (c_int_ty as i32) == 0:
                return 0 as CiExprId
            lhs_value = self.cast(c_int_ty, lhs_value)
    if (op == BO_SHL or op == BO_SHR) and self.kind(lhs_value) != CiExprKind.CIE_CAST and ci_expr_tree_contains_small_int(self.val(), types, rhs_value, 0):
        let c_int_ty = types.named_type_from_text("c_int")
        if (c_int_ty as i32) == 0:
            return 0 as CiExprId
        lhs_value = self.cast(c_int_ty, lhs_value)
    if (lhs_large or rhs_large) and ci_binary_op_allows_uint_literal_cast(op, operand_unsigned):
        if lhs_large:
            let cast_ty = ci_binary_large_decimal_cast_type(session, cursor, op, false, types)
            if (cast_ty as i32) == 0:
                return 0 as CiExprId
            lhs_value = self.cast(cast_ty, lhs_value)
        if rhs_large:
            let cast_ty = ci_binary_large_decimal_cast_type(session, cursor, op, true, types)
            if (cast_ty as i32) == 0:
                return 0 as CiExprId
            rhs_value = self.cast(cast_ty, rhs_value)
    if ci_binary_op_uses_c_integer_promotions(op):
        lhs_value = self.promote_c_small_int_operand(session, lhs_cursor, lhs_peeled, lhs_value, types)
        if (lhs_value as i32) == 0:
            return 0 as CiExprId
        rhs_value = self.promote_c_small_int_operand(session, rhs_cursor, rhs_peeled, rhs_value, types)
        if (rhs_value as i32) == 0:
            return 0 as CiExprId
        if with_ci_type_is_unsigned(session, cursor) != 0:
            let result_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
            if (result_ty as i32) == 0:
                return 0 as CiExprId
            lhs_value = self.cast(result_ty, lhs_value)
            rhs_value = self.cast(result_ty, rhs_value)
    if op == BO_SHL or op == BO_SHR:
        rhs_value = self.cast_shift_count_expr(types, rhs_value)
        if (rhs_value as i32) == 0:
            return 0 as CiExprId

    let is_unsigned = with_ci_type_is_unsigned(session, cursor)
    var ci_op: i32 = 0
    if op == BO_ADD:
        if is_unsigned != 0:
            ci_op = CiBinOp.CIBO_ADD_WRAP
        else:
            ci_op = CiBinOp.CIBO_ADD
    if op == BO_SUB:
        if is_unsigned != 0:
            ci_op = CiBinOp.CIBO_SUB_WRAP
        else:
            ci_op = CiBinOp.CIBO_SUB
    if op == BO_MUL:
        if is_unsigned != 0:
            ci_op = CiBinOp.CIBO_MUL_WRAP
        else:
            ci_op = CiBinOp.CIBO_MUL
    if op == BO_DIV:
        ci_op = CiBinOp.CIBO_DIV
    if op == BO_REM:
        ci_op = CiBinOp.CIBO_MOD
    if op == BO_AND:
        ci_op = CiBinOp.CIBO_BIT_AND
    if op == BO_OR:
        ci_op = CiBinOp.CIBO_BIT_OR
    if op == BO_XOR:
        ci_op = CiBinOp.CIBO_BIT_XOR
    if op == BO_SHL:
        ci_op = CiBinOp.CIBO_SHL
    if op == BO_SHR:
        ci_op = CiBinOp.CIBO_SHR
    if op == BO_ADD and is_unsigned != 0 and ci_expr_is_unsigned_long_max_sum(self.val(), lhs_value, rhs_value):
        let result_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
        if (result_ty as i32) != 0:
            let zero = self.cast(result_ty, self.int_lit(self.add_string("0"), 0 as CiTypeId))
            let one = self.int_lit(self.add_string("1"), 0 as CiTypeId)
            return self.binary(CiBinOp.CIBO_SUB_WRAP, zero, one, result_ty)
    self.binary(ci_op, lhs_value, rhs_value, 0 as CiTypeId)

fn CiExprPool.build_unary_value_expr_from_id(self: CiExprPool, session: i64, cursor: i32, child_cursor: i32, child_id: CiExprId, types: CiTypePool) -> CiExprId:
    let op = with_ci_unary_op(session, cursor)

    if op == UO_PLUS:
        return child_id
    if op == UO_DEREF:
        var deref_ty = 0 as CiTypeId
        let child_ty = self.get_type(child_id)
        if (child_ty as i32) != 0 and types.kind(child_ty) == CiTypeKind.CT_POINTER:
            deref_ty = (types.get_d0(child_ty)) as CiTypeId
        return self.add(CiExprKind.CIE_DEREF, child_id as i32, 0, 0, deref_ty)

    if op == UO_MINUS:
        if with_ci_type_is_unsigned(session, cursor) == 0:
            if self.kind(child_id) == CiExprKind.CIE_INT_LIT:
                let lit = self.get_string(self.get_d0(child_id))
                let neg_idx = self.add_string("-" ++ lit)
                return self.int_lit(neg_idx, self.get_type(child_id))
            if self.kind(child_id) == CiExprKind.CIE_FLOAT_LIT:
                let lit = self.get_string(self.get_d0(child_id))
                let neg_idx = self.add_string("-" ++ lit)
                return self.add(CiExprKind.CIE_FLOAT_LIT, neg_idx, 0, 0, self.get_type(child_id))
        if with_ci_type_is_unsigned(session, cursor) != 0:
            let zero_idx = self.add_string("0")
            var zero = self.int_lit(zero_idx, 0 as CiTypeId)
            let result_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
            if (result_ty as i32) != 0:
                zero = self.cast(result_ty, zero)
            return self.binary(CiBinOp.CIBO_SUB_WRAP, zero, child_id, 0 as CiTypeId)
        let zero_idx = self.add_string("0")
        let zero = self.int_lit(zero_idx, 0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_SUB, zero, child_id, 0 as CiTypeId)

    if op == UO_LNOT:
        let truthy_id = self.bool_expr_from_value_ir(session, child_cursor, child_id, types)
        if (truthy_id as i32) == 0:
            return 0 as CiExprId
        let not_id = self.unary(CiUnaryOp.CIUO_LOGICAL_NOT, truthy_id, 0 as CiTypeId)
        return self.bool_value_expr_ir(session, cursor, not_id, types)

    if op == UO_NOT:
        return self.unary(CiUnaryOp.CIUO_BIT_NOT, child_id, 0 as CiTypeId)

    if op == UO_ADDR:
        let addr_cxtype = with_ci_cursor_type(session, cursor)
        let addr_ty_id = types.type_from_libclang(session, addr_cxtype)
        if ci_cursor_is_function_ref(session, child_cursor):
            return child_id
        if (addr_ty_id as i32) == 0:
            return self.add(CiExprKind.CIE_ADDR_OF, child_id as i32, 0, 0, 0 as CiTypeId)
        var is_mut_ptr = false
        if types.kind(addr_ty_id) == CiTypeKind.CT_POINTER and types.get_d1(addr_ty_id) == 0:
            is_mut_ptr = true
        if not is_mut_ptr:
            let addr_e = self.add(CiExprKind.CIE_ADDR_OF, child_id as i32, 0, 0, 0 as CiTypeId)
            return self.cast(addr_ty_id, addr_e)
        if ci_cursor_is_simple_storage_ref(session, child_cursor):
            let addr_e = self.add(CiExprKind.CIE_ADDR_OF, child_id as i32, 1, 0, 0 as CiTypeId)
            return self.cast(addr_ty_id, addr_e)
        let pointee_ty_id = (types.get_d0(addr_ty_id)) as CiTypeId
        let const_ty_id = types.ty_pointer(pointee_ty_id, 1)
        let addr_e = self.add(CiExprKind.CIE_ADDR_OF, child_id as i32, 0, 0, 0 as CiTypeId)
        let first_cast = self.cast(const_ty_id, addr_e)
        return self.cast(addr_ty_id, first_cast)

    0 as CiExprId

fn CiExprPool.lower_plain_value_expr_ir(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    var stmts = CiStmtPool.new()
    let lowered = stmts.lower_value_expr_ir(session, cursor, self.val(), types, scope)
    if not ci_value_ir_valid(lowered):
        stmts.deinit()
        return 0 as CiExprId
    if (lowered.setup_stmt as i32) != 0:
        stmts.deinit()
        return 0 as CiExprId
    let value_expr = lowered.value_expr
    stmts.deinit()
    value_expr

fn CiExprPool.apply_implicit_cast_to_value_id(self: CiExprPool, session: i64, cursor: i32, inner_cursor: i32, inner_id: CiExprId, types: CiTypePool, scope: CiScope) -> CiExprId:
    let cast_kind = ci_classify_implicit_cast_safe(session, cursor, inner_cursor)

    if cast_kind == CI_CAST_NULL_TO_PTR:
        return self.null_ptr(0 as CiTypeId)
    if cast_kind == CI_CAST_NOOP or cast_kind == CI_CAST_FUNCTION_TO_PTR or cast_kind == CI_CAST_LVALUE_TO_RVALUE or cast_kind == CI_CAST_UNKNOWN:
        return inner_id

    if cast_kind == CI_CAST_INT_TO_BOOL:
        let zero_idx = self.add_string("0")
        let zero = self.int_lit(zero_idx, 0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, inner_id, zero, 0 as CiTypeId)
    if cast_kind == CI_CAST_PTR_TO_BOOL:
        let null_e = self.null_ptr(0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, inner_id, null_e, 0 as CiTypeId)
    if cast_kind == CI_CAST_FLOAT_TO_BOOL:
        let zero_idx = self.add_string("0.0")
        let zero = self.add(CiExprKind.CIE_FLOAT_LIT, zero_idx, 0, 0, 0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, inner_id, zero, 0 as CiTypeId)

    if cast_kind == CI_CAST_INT_TO_PTR:
        let usize_ty = types.named_type_from_text("usize")
        let c_void_ty = types.named_type_from_text("c_void")
        if (usize_ty as i32) == 0 or (c_void_ty as i32) == 0:
            return 0 as CiExprId
        let void_ptr_ty = types.ty_pointer(c_void_ty, 0)
        let to_usize = self.cast(usize_ty, inner_id)
        return self.cast(void_ptr_ty, to_usize)

    if cast_kind == CI_CAST_PTR_TO_INT:
        let dest_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
        let usize_ty = types.named_type_from_text("usize")
        if (dest_ty as i32) == 0 or (usize_ty as i32) == 0:
            return 0 as CiExprId
        let to_usize = self.cast(usize_ty, inner_id)
        return self.cast(dest_ty, to_usize)

    if cast_kind == CI_CAST_ARRAY_TO_PTR:
        let dest_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
        if (dest_ty as i32) == 0:
            return 0 as CiExprId
        let scoped_inner_ty = ci_scope_type_for_cursor(session, inner_cursor, scope)
        if ci_starts_with(scoped_inner_ty, "*"):
            return self.cast_if_needed(dest_ty, inner_id, inner_cursor, session, types)
        let zero_idx = self.add_string("0")
        let zero = self.int_lit(zero_idx, 0 as CiTypeId)
        let idx_e = self.add(CiExprKind.CIE_INDEX, inner_id as i32, zero as i32, 1, 0 as CiTypeId)
        let addr_e = self.add(CiExprKind.CIE_ADDR_OF, idx_e as i32, 0, 0, 0 as CiTypeId)
        return self.cast(dest_ty, addr_e)
    if cast_kind == CI_CAST_BITCAST or cast_kind == CI_CAST_PTR_CAST or cast_kind == CI_CAST_INT_WIDEN or cast_kind == CI_CAST_INT_WIDEN_SIGN or cast_kind == CI_CAST_INT_TRUNC or cast_kind == CI_CAST_FLOAT_CAST or cast_kind == CI_CAST_FLOAT_TO_INT or cast_kind == CI_CAST_INT_TO_FLOAT:
        let dest_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
        if (dest_ty as i32) == 0:
            return 0 as CiExprId
        return self.cast_if_needed(dest_ty, inner_id, inner_cursor, session, types)
    inner_id

fn CiExprPool.build_libc_call_value_expr(self: CiExprPool, session: i64, cursor: i32, callee_text: str, arg_ids: &Vec[i32], types: CiTypePool) -> CiExprId:
    let renamed = ci_libc_simple_rename(callee_text)
    if renamed.len() > 0:
        return self.build_named_call_expr(renamed, arg_ids)
    if ci_is_libm_fn(callee_text):
        return self.build_named_call_expr(callee_text, arg_ids)
    if callee_text == "malloc":
        if arg_ids.len() != 1:
            return 0 as CiExprId
        let i64_ty = types.named_type_from_text("i64")
        let c_void_ty = types.named_type_from_text("c_void")
        if (i64_ty as i32) == 0 or (c_void_ty as i32) == 0:
            return 0 as CiExprId
        let arg_as_i64 = self.cast(i64_ty, (arg_ids.get(0)) as CiExprId)
        let wa_idx = self.add_string("with_alloc")
        let wa_callee = self.ident(wa_idx, 0 as CiTypeId)
        let args_start = self.extra_len() as i32
        let _ = self.add_extra(arg_as_i64 as i32)
        let call_id = self.add(CiExprKind.CIE_CALL, wa_callee as i32, args_start, 1, 0 as CiTypeId)
        let void_ptr_ty = types.ty_pointer(c_void_ty, 0)
        return self.cast(void_ptr_ty, call_id)
    if callee_text == "free":
        if arg_ids.len() != 1:
            return 0 as CiExprId
        let i8_ty = types.named_type_from_text("i8")
        if (i8_ty as i32) == 0:
            return 0 as CiExprId
        let i8_ptr_ty = types.ty_pointer(i8_ty, 0)
        let arg_cast = self.cast(i8_ptr_ty, (arg_ids.get(0)) as CiExprId)
        let wf_idx = self.add_string("with_free")
        let wf_callee = self.ident(wf_idx, 0 as CiTypeId)
        let args_start = self.extra_len() as i32
        let _ = self.add_extra(arg_cast as i32)
        return self.add(CiExprKind.CIE_CALL, wf_callee as i32, args_start, 1, 0 as CiTypeId)
    if callee_text == "calloc":
        return self.build_named_call_expr("alloc_zeroed", arg_ids)
    if callee_text == "realloc":
        if arg_ids.len() != 2:
            return 0 as CiExprId
        let i8_ty = types.named_type_from_text("i8")
        let i64_ty = types.named_type_from_text("i64")
        let c_void_ty = types.named_type_from_text("c_void")
        if (i8_ty as i32) == 0 or (i64_ty as i32) == 0 or (c_void_ty as i32) == 0:
            return 0 as CiExprId
        let i8_ptr_ty = types.ty_pointer(i8_ty, 0)
        let arg_ptr = self.cast(i8_ptr_ty, (arg_ids.get(0)) as CiExprId)
        let zero_idx = self.add_string("0")
        let zero_id = self.int_lit(zero_idx, 0 as CiTypeId)
        let old_size = self.cast(i64_ty, zero_id)
        let new_size = self.cast(i64_ty, (arg_ids.get(1)) as CiExprId)
        let realloc_args: Vec[i32] = Vec.new()
        realloc_args.push(arg_ptr as i32)
        realloc_args.push(old_size as i32)
        realloc_args.push(new_size as i32)
        let call_id = self.build_named_call_expr("with_realloc", &realloc_args)
        let void_ptr_ty = types.ty_pointer(c_void_ty, 0)
        return self.cast(void_ptr_ty, call_id)
    let i64_ty = types.named_type_from_text("i64")
    let i8_ptr_ty = types.named_type_from_text("*i8")
    if callee_text == "memcpy" or callee_text == "memmove":
        if arg_ids.len() != 3 or (i64_ty as i32) == 0 or (i8_ptr_ty as i32) == 0:
            return 0 as CiExprId
        let cast_args: Vec[i32] = Vec.new()
        cast_args.push((self.cast(i8_ptr_ty, (arg_ids.get(0)) as CiExprId)) as i32)
        cast_args.push((self.cast(i8_ptr_ty, (arg_ids.get(1)) as CiExprId)) as i32)
        cast_args.push((self.cast(i64_ty, (arg_ids.get(2)) as CiExprId)) as i32)
        return self.build_named_call_expr(if callee_text == "memcpy": "with_memcpy" else: "with_memmove", &cast_args)
    if callee_text == "memset":
        if arg_ids.len() != 3 or (i64_ty as i32) == 0 or (i8_ptr_ty as i32) == 0:
            return 0 as CiExprId
        let cast_args: Vec[i32] = Vec.new()
        cast_args.push((self.cast(i8_ptr_ty, (arg_ids.get(0)) as CiExprId)) as i32)
        cast_args.push(arg_ids.get(1))
        cast_args.push((self.cast(i64_ty, (arg_ids.get(2)) as CiExprId)) as i32)
        return self.build_named_call_expr("with_memset", &cast_args)
    if callee_text == "memcmp":
        if arg_ids.len() != 3 or (i64_ty as i32) == 0 or (i8_ptr_ty as i32) == 0:
            return 0 as CiExprId
        let cast_args: Vec[i32] = Vec.new()
        cast_args.push((self.cast(i8_ptr_ty, (arg_ids.get(0)) as CiExprId)) as i32)
        cast_args.push((self.cast(i8_ptr_ty, (arg_ids.get(1)) as CiExprId)) as i32)
        cast_args.push((self.cast(i64_ty, (arg_ids.get(2)) as CiExprId)) as i32)
        return self.build_named_call_expr("with_memcmp", &cast_args)
    if callee_text == "memchr":
        if arg_ids.len() != 3:
            return 0 as CiExprId
        let c_void_ty = types.named_type_from_text("c_void")
        if (c_void_ty as i32) == 0:
            return 0 as CiExprId
        let cvoid_ptr = types.ty_pointer(c_void_ty, 0)
        let cast_args: Vec[i32] = Vec.new()
        cast_args.push((self.cast(cvoid_ptr, (arg_ids.get(0)) as CiExprId)) as i32)
        cast_args.push(arg_ids.get(1))
        cast_args.push(arg_ids.get(2))
        let call_id = self.build_named_call_expr("memchr", &cast_args)
        let u8_ty = types.named_type_from_text("u8")
        let u8_ptr = types.ty_pointer(u8_ty, 1)
        return self.cast(u8_ptr, call_id)
    if callee_text == "isgraph":
        if arg_ids.len() != 1:
            return 0 as CiExprId
        let print_args: Vec[i32] = Vec.new()
        print_args.push(arg_ids.get(0))
        let print_call = self.build_named_call_expr("is_print", &print_args)
        let space_call = self.build_named_call_expr("is_space", &print_args)
        let not_space = self.unary(CiUnaryOp.CIUO_LOGICAL_NOT, space_call, 0 as CiTypeId)
        let cond = self.binary(CiBinOp.CIBO_LOGICAL_AND, print_call, not_space, 0 as CiTypeId)
        return self.bool_value_expr_ir(session, cursor, cond, types)
    if callee_text == "ispunct":
        if arg_ids.len() != 1:
            return 0 as CiExprId
        let shared_args: Vec[i32] = Vec.new()
        shared_args.push(arg_ids.get(0))
        let print_call = self.build_named_call_expr("is_print", &shared_args)
        let alnum_call = self.build_named_call_expr("is_alnum", &shared_args)
        let space_call = self.build_named_call_expr("is_space", &shared_args)
        let not_alnum = self.unary(CiUnaryOp.CIUO_LOGICAL_NOT, alnum_call, 0 as CiTypeId)
        let not_space = self.unary(CiUnaryOp.CIUO_LOGICAL_NOT, space_call, 0 as CiTypeId)
        let lhs_cond = self.binary(CiBinOp.CIBO_LOGICAL_AND, print_call, not_alnum, 0 as CiTypeId)
        let cond = self.binary(CiBinOp.CIBO_LOGICAL_AND, lhs_cond, not_space, 0 as CiTypeId)
        return self.bool_value_expr_ir(session, cursor, cond, types)
    if callee_text == "iscntrl":
        if arg_ids.len() != 1:
            return 0 as CiExprId
        let arg_id = (arg_ids.get(0)) as CiExprId
        let lit32 = self.int_lit(self.add_string("32"), 0 as CiTypeId)
        let lit127 = self.int_lit(self.add_string("127"), 0 as CiTypeId)
        let lt_32 = self.binary(CiBinOp.CIBO_LT, arg_id, lit32, 0 as CiTypeId)
        let eq_127 = self.binary(CiBinOp.CIBO_EQ, arg_id, lit127, 0 as CiTypeId)
        let cond = self.binary(CiBinOp.CIBO_LOGICAL_OR, lt_32, eq_127, 0 as CiTypeId)
        return self.bool_value_expr_ir(session, cursor, cond, types)
    if callee_text == "__builtin___memcpy_chk" or callee_text == "__builtin___memmove_chk":
        if arg_ids.len() != 4:
            return 0 as CiExprId
        let first_three: Vec[i32] = Vec.new()
        first_three.push(arg_ids.get(0))
        first_three.push(arg_ids.get(1))
        first_three.push(arg_ids.get(2))
        return self.build_libc_call_value_expr(session, cursor, if callee_text == "__builtin___memcpy_chk": "memcpy" else: "memmove", &first_three, types)
    if callee_text == "__builtin___memset_chk":
        if arg_ids.len() != 4:
            return 0 as CiExprId
        let first_three: Vec[i32] = Vec.new()
        first_three.push(arg_ids.get(0))
        first_three.push(arg_ids.get(1))
        first_three.push(arg_ids.get(2))
        return self.build_libc_call_value_expr(session, cursor, "memset", &first_three, types)
    if callee_text == "__builtin_object_size":
        let zero_idx = self.add_string("0")
        return self.int_lit(zero_idx, 0 as CiTypeId)
    if callee_text == "__builtin_offsetof":
        return self.lower_offsetof_value_expr(session, cursor)
    if ci_starts_with(callee_text, "__builtin"):
        let zero_idx = self.add_string("0")
        return self.int_lit(zero_idx, 0 as CiTypeId)
    0 as CiExprId

fn CiStmtPool.lower_lvalue_expr_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiValueExprIR:
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)

    if kind == CXK_UNEXPOSED_STMT:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return self.lower_lvalue_expr_ir(session, inner, exprs, types, scope)
        return ci_value_ir_invalid()

    if (kind == CXK_PAREN_EXPR or kind == 100 or kind == CXK_IMPLICIT_CAST) and nc == 1:
        return self.lower_lvalue_expr_ir(session, with_ci_child(session, cursor, 0), exprs, types, scope)

    if kind == CXK_DECL_REF:
        let expr_id = exprs.lower_expr_ir(session, cursor, types, scope)
        if (expr_id as i32) != 0:
            return ci_value_ir_plain(expr_id)
        return ci_value_ir_invalid()

    if kind == CXK_MEMBER_REF and nc > 0:
        let base = self.lower_value_expr_ir(session, with_ci_child(session, cursor, 0), exprs, types, scope)
        let field = with_ci_member_field_name(session, cursor)
        if ci_value_ir_valid(base) and field.len() > 0:
            let field_idx = exprs.add_string(ci_escape_reserved(field))
            let field_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
            let field_id = exprs.add(CiExprKind.CIE_FIELD, base.value_expr as i32, field_idx, 0, field_ty)
            return CiValueExprIR {
                setup_stmt: base.setup_stmt,
                value_expr: field_id,
            }
        return ci_value_ir_invalid()

    if kind == CXK_ARRAY_SUBSCRIPT and nc >= 2:
        let arr_cursor = with_ci_child(session, cursor, 0)
        let idx_cursor = with_ci_child(session, cursor, 1)
        let arr = self.lower_value_expr_ir(session, arr_cursor, exprs, types, scope)
        let idx = self.lower_value_expr_ir(session, idx_cursor, exprs, types, scope)
        if ci_value_ir_valid(arr) and ci_value_ir_valid(idx):
            let raw_ptr_index = ci_index_base_is_raw_pointer(session, arr_cursor, arr.value_expr, exprs, types)
            let index_id = exprs.add(CiExprKind.CIE_INDEX, arr.value_expr as i32, idx.value_expr as i32, raw_ptr_index, 0 as CiTypeId)
            return CiValueExprIR {
                setup_stmt: self.merge_ir( arr.setup_stmt, idx.setup_stmt),
                value_expr: index_id,
            }
        return ci_value_ir_invalid()

    if kind == CXK_UNARY_OP and nc > 0 and with_ci_unary_op(session, cursor) == UO_DEREF:
        let operand = self.lower_value_expr_ir(session, with_ci_child(session, cursor, 0), exprs, types, scope)
        if ci_value_ir_valid(operand):
            var deref_ty = 0 as CiTypeId
            let operand_ty = exprs.get_type(operand.value_expr)
            if (operand_ty as i32) != 0 and types.kind(operand_ty) == CiTypeKind.CT_POINTER:
                deref_ty = (types.get_d0(operand_ty)) as CiTypeId
            let deref_id = exprs.add(CiExprKind.CIE_DEREF, operand.value_expr as i32, 0, 0, deref_ty)
            return CiValueExprIR {
                setup_stmt: operand.setup_stmt,
                value_expr: deref_id,
            }
        return ci_value_ir_invalid()

    let expr_id = exprs.lower_expr_ir(session, cursor, types, scope)
    if (expr_id as i32) != 0:
        return ci_value_ir_plain(expr_id)
    ci_value_ir_invalid()

fn CiStmtPool.lower_value_expr_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiValueExprIR:
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)

    if kind == CXK_UNEXPOSED_STMT:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return self.lower_value_expr_ir(session, inner, exprs, types, scope)
        return ci_value_ir_invalid()

    if kind == 100:
        if with_ci_eval_int_valid(session, cursor) != 0 and not ci_expr_children_need_rvalue_lowering(session, cursor):
            let text_idx = exprs.add_string(ci_eval_int_text(session, cursor))
            return ci_value_ir_plain(exprs.int_lit(text_idx, 0 as CiTypeId))
        let inner_cursor = ci_find_last_expr_child(session, cursor)
        if inner_cursor >= 0:
            return self.lower_value_expr_ir(session, inner_cursor, exprs, types, scope)

    if kind == CXK_PAREN_EXPR:
        if nc == 1:
            return self.lower_value_expr_ir(session, with_ci_child(session, cursor, 0), exprs, types, scope)
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return self.lower_value_expr_ir(session, inner, exprs, types, scope)

    if kind == CXK_IMPLICIT_CAST:
        var inner_cursor = -1
        if nc == 1:
            inner_cursor = with_ci_child(session, cursor, 0)
        else if nc > 0:
            inner_cursor = ci_find_last_expr_child(session, cursor)
        if inner_cursor < 0:
            return ci_value_ir_invalid()
        let inner = self.lower_value_expr_ir(session, inner_cursor, exprs, types, scope)
        if ci_value_ir_valid(inner):
            let casted = exprs.apply_implicit_cast_to_value_id(session, cursor, inner_cursor, inner.value_expr, types, scope)
            if (casted as i32) != 0:
                return CiValueExprIR {
                    setup_stmt: inner.setup_stmt,
                    value_expr: casted,
                }
        return ci_value_ir_invalid()

    if kind == CXK_BINARY_OP and nc >= 2:
        let glibc_ctype_mask_id = exprs.lower_glibc_ctype_mask_macro(session, cursor, types, scope)
        if (glibc_ctype_mask_id as i32) != 0:
            return ci_value_ir_plain(glibc_ctype_mask_id)
        let lhs_cursor = with_ci_child(session, cursor, 0)
        let rhs_cursor = with_ci_child(session, cursor, 1)
        let op = with_ci_binary_op(session, cursor)

        if op == BO_ASSIGN:
            let lhs = self.lower_lvalue_expr_ir(session, lhs_cursor, exprs, types, scope)
            let rhs = self.lower_value_expr_ir(session, rhs_cursor, exprs, types, scope)
            if not ci_value_ir_valid(lhs):
                g_ci_bail_location = with_ci_cursor_location(session, lhs_cursor)
                g_ci_bail_kind = with_ci_cursor_kind(session, lhs_cursor)
                g_ci_bail_message = f"unsupported assignment lhs in goto CFG (kind={g_ci_bail_kind})"
                return ci_value_ir_invalid()
            if not ci_value_ir_valid(rhs):
                g_ci_bail_location = with_ci_cursor_location(session, rhs_cursor)
                g_ci_bail_kind = with_ci_cursor_kind(session, rhs_cursor)
                g_ci_bail_message = f"unsupported assignment rhs in goto CFG (kind={g_ci_bail_kind})"
                return ci_value_ir_invalid()
            if ci_value_ir_valid(lhs) and ci_value_ir_valid(rhs):
                var rhs_value = rhs.value_expr
                let lhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, lhs_cursor))
                let rhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, rhs_cursor))
                let rhs_peeled = ci_peel_transparent(session, rhs_cursor)
                let lhs_ty_id = types.type_from_libclang(session, with_ci_cursor_type(session, lhs_cursor))
                let lhs_is_ptr = ci_cursor_type_is_pointerish(session, lhs_cursor)
                let rhs_is_ptr = ci_cursor_type_is_pointerish(session, rhs_cursor) or ci_cursor_type_is_pointerish(session, rhs_peeled)
                if lhs_is_ptr and with_ci_cursor_kind(session, rhs_peeled) != CXK_STRING_LITERAL and ci_cursor_is_array_type(session, rhs_peeled):
                    if exprs.kind(rhs_value) != CiExprKind.CIE_ARRAY_DECAY and exprs.kind(rhs_value) != CiExprKind.CIE_CAST:
                        let elem_ty = types.named_type_from_text(ci_array_elem_type_from_cursor(session, rhs_peeled))
                        if (lhs_ty_id as i32) == 0 or (elem_ty as i32) == 0:
                            return ci_value_ir_invalid()
                        rhs_value = exprs.add(CiExprKind.CIE_ARRAY_DECAY, rhs_value as i32, elem_ty as i32, 0, lhs_ty_id)
                if lhs_is_ptr and (rhs_is_ptr or ci_starts_with(rhs_ty_str, "*")) and lhs_ty_str != rhs_ty_str:
                    if (lhs_ty_id as i32) == 0:
                        return ci_value_ir_invalid()
                    rhs_value = exprs.cast(lhs_ty_id, rhs_value)
                let coerced_rhs = exprs.coerce_value_expr_for_target(session, lhs_ty_id, rhs_cursor, rhs_value, types)
                if (coerced_rhs as i32) == 0:
                    return ci_value_ir_invalid()
                rhs_value = coerced_rhs
                let assign_stmt = self.assign(lhs.value_expr, rhs_value)
                return CiValueExprIR {
                    setup_stmt: self.merge3_ir( lhs.setup_stmt, rhs.setup_stmt, assign_stmt),
                    value_expr: lhs.value_expr,
                }
            return ci_value_ir_invalid()

        if op == BO_COMMA:
            let lhs = self.lower_value_expr_ir(session, lhs_cursor, exprs, types, scope)
            let rhs = self.lower_value_expr_ir(session, rhs_cursor, exprs, types, scope)
            if ci_value_ir_valid(lhs) and ci_value_ir_valid(rhs):
                var lhs_effect = lhs.setup_stmt
                if (lhs_effect as i32) == 0:
                    lhs_effect = self.lower_effect_expr_ir(session, lhs_cursor, exprs, types, scope)
                return CiValueExprIR {
                    setup_stmt: self.merge_ir( lhs_effect, rhs.setup_stmt),
                    value_expr: rhs.value_expr,
                }
            return ci_value_ir_invalid()

        if op == BO_LAND or op == BO_LOR:
            let lhs = self.lower_value_expr_ir(session, lhs_cursor, exprs, types, scope)
            let rhs = self.lower_value_expr_ir(session, rhs_cursor, exprs, types, scope)
            if ci_value_ir_valid(lhs) and ci_value_ir_valid(rhs):
                let result_name = ci_expr_temp_name(session, cursor, "logic")
                let result_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
                if (result_ty as i32) == 0:
                    return ci_value_ir_invalid()
                let result_stmt_name = self.add_string(result_name)
                let result_expr_name = exprs.add_string(result_name)
                let default_text = if op == BO_LAND: "0" else: "1"
                let default_expr = exprs.default_expr_from_text(default_text)
                let decl_id = self.var_decl(result_stmt_name, result_ty, default_expr, 1)
                let lhs_truthy = exprs.bool_expr_from_value_ir(session, lhs_cursor, lhs.value_expr, types)
                let rhs_truthy = exprs.bool_expr_from_value_ir(session, rhs_cursor, rhs.value_expr, types)
                if (lhs_truthy as i32) == 0 or (rhs_truthy as i32) == 0:
                    return ci_value_ir_invalid()
                let rhs_value = exprs.bool_value_expr_ir(session, cursor, rhs_truthy, types)
                if (rhs_value as i32) == 0:
                    return ci_value_ir_invalid()
                let result_ident = exprs.ident(result_expr_name, result_ty)
                let rhs_assign = self.assign(result_ident, rhs_value)
                let then_body = self.merge_ir( rhs.setup_stmt, rhs_assign)
                if op == BO_LAND:
                    let if_stmt = self.if_stmt(lhs_truthy, then_body, 0 as CiStmtId)
                    return CiValueExprIR {
                        setup_stmt: self.merge3_ir( decl_id, lhs.setup_stmt, if_stmt),
                        value_expr: exprs.ident(result_expr_name, result_ty),
                    }
                let true_value = exprs.bool_value_expr_ir(session, cursor, exprs.bool_lit(1, 0 as CiTypeId), types)
                let true_assign = self.assign(exprs.ident(result_expr_name, result_ty), true_value)
                let if_stmt = self.if_stmt(lhs_truthy, true_assign, then_body)
                return CiValueExprIR {
                    setup_stmt: self.merge3_ir( decl_id, lhs.setup_stmt, if_stmt),
                    value_expr: exprs.ident(result_expr_name, result_ty),
                }
            return ci_value_ir_invalid()

        let lhs = self.lower_value_expr_ir(session, lhs_cursor, exprs, types, scope)
        let rhs = self.lower_value_expr_ir(session, rhs_cursor, exprs, types, scope)
        if ci_value_ir_valid(lhs) and ci_value_ir_valid(rhs):
            let expr_id = exprs.build_binary_value_expr_from_ids(session, cursor, lhs_cursor, lhs.value_expr, rhs_cursor, rhs.value_expr, types)
            if (expr_id as i32) != 0:
                return CiValueExprIR {
                    setup_stmt: self.merge_ir( lhs.setup_stmt, rhs.setup_stmt),
                    value_expr: expr_id,
                }
        if with_ci_eval_int_valid(session, cursor) != 0:
            let text_idx = exprs.add_string(ci_eval_int_text(session, cursor))
            return ci_value_ir_plain(exprs.int_lit(text_idx, 0 as CiTypeId))
        return ci_value_ir_invalid()

    if kind == CXK_COMPOUND_ASSIGN_OP and nc >= 2:
        let lhs_cursor = with_ci_child(session, cursor, 0)
        let rhs_cursor = with_ci_child(session, cursor, 1)
        let lhs = self.lower_lvalue_expr_ir(session, lhs_cursor, exprs, types, scope)
        let rhs = self.lower_value_expr_ir(session, rhs_cursor, exprs, types, scope)
        let ci_op = ci_compound_to_ci_binop(with_ci_binary_op(session, cursor))
        if ci_value_ir_valid(lhs) and ci_value_ir_valid(rhs) and ci_op >= 0:
            var lhs_value = lhs.value_expr
            var rhs_value = rhs.value_expr
            let lhs_ty = exprs.get_type(lhs.value_expr)
            let lhs_is_ptr = ci_cursor_type_is_pointerish(session, lhs_cursor) or ((lhs_ty as i32) != 0 and types.kind(lhs_ty) == CiTypeKind.CT_POINTER)
            if lhs_is_ptr and (ci_op == CiBinOp.CIBO_ADD or ci_op == CiBinOp.CIBO_SUB):
                rhs_value = exprs.cast_pointer_index_expr(session, rhs_cursor, rhs_value, types)
                if (rhs_value as i32) == 0:
                    return ci_value_ir_invalid()
            if ci_op == CiBinOp.CIBO_SHL or ci_op == CiBinOp.CIBO_SHR:
                let lhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, lhs_cursor))
                let c_uint_ty = types.named_type_from_text("c_uint")
                if (c_uint_ty as i32) == 0:
                    return ci_value_ir_invalid()
                if ci_type_is_small_int(lhs_ty_str) or ci_is_large_decimal(ci_print_expr(exprs, types, lhs.value_expr, 0, 0)):
                    lhs_value = exprs.cast(c_uint_ty, lhs_value)
                rhs_value = exprs.cast(c_uint_ty, rhs_value)
            let rhs_expr = exprs.binary(ci_op, lhs_value, rhs_value, 0 as CiTypeId)
            let assign_stmt = self.assign(lhs.value_expr, rhs_expr)
            return CiValueExprIR {
                setup_stmt: self.merge3_ir( lhs.setup_stmt, rhs.setup_stmt, assign_stmt),
                value_expr: lhs.value_expr,
            }
        return ci_value_ir_invalid()

    if kind == CXK_UNARY_OP and nc >= 1:
        let operand_cursor = with_ci_child(session, cursor, 0)
        let op = with_ci_unary_op(session, cursor)
        if op == UO_PRE_INC or op == UO_PRE_DEC or op == UO_POST_INC or op == UO_POST_DEC:
            let operand = self.lower_lvalue_expr_ir(session, operand_cursor, exprs, types, scope)
            if ci_value_ir_valid(operand):
                let one_idx = exprs.add_string("1")
                let one = exprs.int_lit(one_idx, 0 as CiTypeId)
                let delta_op = if op == UO_PRE_INC or op == UO_POST_INC: CiBinOp.CIBO_ADD else: CiBinOp.CIBO_SUB
                let rhs_expr = exprs.binary(delta_op, operand.value_expr, one, 0 as CiTypeId)
                let assign_stmt = self.assign(operand.value_expr, rhs_expr)
                if op == UO_PRE_INC or op == UO_PRE_DEC:
                    return CiValueExprIR {
                        setup_stmt: self.merge_ir( operand.setup_stmt, assign_stmt),
                        value_expr: operand.value_expr,
                    }
                let old_name = ci_expr_temp_name(session, cursor, "old")
                var old_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
                if (old_ty as i32) == 0:
                    old_ty = types.type_from_libclang(session, with_ci_cursor_type(session, operand_cursor))
                if (old_ty as i32) == 0:
                    return ci_value_ir_invalid()
                let old_stmt_name = self.add_string(old_name)
                let old_expr_name = exprs.add_string(old_name)
                let decl_id = self.var_decl(old_stmt_name, old_ty, operand.value_expr, 1)
                return CiValueExprIR {
                    setup_stmt: self.merge3_ir( operand.setup_stmt, decl_id, assign_stmt),
                    value_expr: exprs.ident(old_expr_name, old_ty),
                }
            return ci_value_ir_invalid()
        let operand = self.lower_value_expr_ir(session, operand_cursor, exprs, types, scope)
        if ci_value_ir_valid(operand):
            let expr_id = exprs.build_unary_value_expr_from_id(session, cursor, operand_cursor, operand.value_expr, types)
            if (expr_id as i32) != 0:
                return CiValueExprIR {
                    setup_stmt: operand.setup_stmt,
                    value_expr: expr_id,
                }
        return ci_value_ir_invalid()

    if kind == CXK_COND_OP and nc >= 3:
        let cond_cursor = with_ci_child(session, cursor, 0)
        let then_cursor = with_ci_child(session, cursor, 1)
        let else_cursor = with_ci_child(session, cursor, 2)
        let cond = self.lower_value_expr_ir(session, cond_cursor, exprs, types, scope)
        let then_v = self.lower_value_expr_ir(session, then_cursor, exprs, types, scope)
        let else_v = self.lower_value_expr_ir(session, else_cursor, exprs, types, scope)
        if ci_value_ir_valid(cond) and ci_value_ir_valid(then_v) and ci_value_ir_valid(else_v):
            let result_name = ci_expr_temp_name(session, cursor, "ternary")
            let result_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
            if (result_ty as i32) == 0:
                return ci_value_ir_invalid()
            let result_stmt_name = self.add_string(result_name)
            let result_expr_name = exprs.add_string(result_name)
            let default_expr = exprs.default_expr_from_text(ci_default_for_type(with_ci_type_translated(session, with_ci_cursor_type(session, cursor))))
            let decl_id = self.var_decl(result_stmt_name, result_ty, default_expr, 1)
            let result_ident = exprs.ident(result_expr_name, result_ty)
            let then_value = exprs.coerce_value_expr_for_target(session, result_ty, then_cursor, then_v.value_expr, types)
            let else_value = exprs.coerce_value_expr_for_target(session, result_ty, else_cursor, else_v.value_expr, types)
            if (then_value as i32) == 0 or (else_value as i32) == 0:
                return ci_value_ir_invalid()
            let then_assign = self.assign(result_ident, then_value)
            let else_assign = self.assign(exprs.ident(result_expr_name, result_ty), else_value)
            let then_body = self.merge_ir( then_v.setup_stmt, then_assign)
            let else_body = self.merge_ir( else_v.setup_stmt, else_assign)
            let cond_truthy = exprs.bool_expr_from_value_ir(session, cond_cursor, cond.value_expr, types)
            if (cond_truthy as i32) == 0:
                return ci_value_ir_invalid()
            let if_stmt = self.if_stmt(cond_truthy, then_body, else_body)
            return CiValueExprIR {
                setup_stmt: self.merge3_ir( decl_id, cond.setup_stmt, if_stmt),
                value_expr: exprs.ident(result_expr_name, result_ty),
            }
        if with_ci_eval_int_valid(session, cursor) != 0:
            let text_idx = exprs.add_string(ci_eval_int_text(session, cursor))
            return ci_value_ir_plain(exprs.int_lit(text_idx, 0 as CiTypeId))
        return ci_value_ir_invalid()

    if kind == CXK_CSTYLE_CAST:
        let inner_child = ci_find_last_expr_child(session, cursor)
        if inner_child >= 0:
            let inner = self.lower_value_expr_ir(session, inner_child, exprs, types, scope)
            if ci_value_ir_valid(inner):
                let target_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
                if (target_ty as i32) == 0:
                    return ci_value_ir_invalid()
                var casted = inner.value_expr
                if types.kind(target_ty) == CiTypeKind.CT_POINTER:
                    casted = exprs.decay_array_value_expr(session, inner_child, inner.value_expr, target_ty, types)
                if (casted as i32) == (inner.value_expr as i32):
                    casted = exprs.cast_if_needed(target_ty, inner.value_expr, inner_child, session, types)
                return CiValueExprIR {
                    setup_stmt: inner.setup_stmt,
                    value_expr: casted,
                }
        return ci_value_ir_invalid()

    if kind == CXK_CALL_EXPR and nc > 0:
        var callee = self.lower_value_expr_ir(session, with_ci_child(session, cursor, 0), exprs, types, scope)
        var callee_text = ""
        var setup: CiStmtId = 0 as CiStmtId
        var first_arg = 1
        if ci_value_ir_valid(callee):
            callee_text = ci_print_expr(exprs, types, callee.value_expr, 0, 0)
            setup = callee.setup_stmt
            let source_callee = ci_call_name_from_source_text(with_ci_cursor_source_text(session, cursor))
            let cursor_callee = ci_call_callee_name(session, with_ci_child(session, cursor, 0))
            if source_callee.len() > 0 and source_callee == cursor_callee and not ci_is_c_ident(callee_text):
                let callee_idx = exprs.add_string(ci_escape_reserved(source_callee))
                callee = ci_value_ir_plain(exprs.ident(callee_idx, 0 as CiTypeId))
                callee_text = ci_escape_reserved(source_callee)
                setup = 0 as CiStmtId
                first_arg = 0
        else:
            let callee_name = ci_call_name_from_source_text(with_ci_cursor_source_text(session, cursor))
            if callee_name.len() == 0:
                return ci_value_ir_invalid()
            let callee_idx = exprs.add_string(ci_escape_reserved(callee_name))
            callee = ci_value_ir_plain(exprs.ident(callee_idx, 0 as CiTypeId))
            callee_text = ci_escape_reserved(callee_name)
            first_arg = 0
        if callee_text == "cfprintf":
            return ci_value_ir_invalid()
        if callee_text == "__builtin_offsetof" or callee_text == "offsetof":
            let offset_id = exprs.lower_offsetof_value_expr(session, cursor)
            if (offset_id as i32) != 0:
                return CiValueExprIR {
                    setup_stmt: setup,
                    value_expr: offset_id,
                }
            return ci_value_ir_invalid()
        var arg_ids: Vec[i32] = Vec.new()
        var ai = first_arg
        while ai < nc:
            let arg_cursor = with_ci_child(session, cursor, ai)
            let lowered_arg = self.lower_value_expr_ir(session, arg_cursor, exprs, types, scope)
            if not ci_value_ir_valid(lowered_arg):
                return ci_value_ir_invalid()
            setup = self.merge_ir( setup, lowered_arg.setup_stmt)
            var arg_id = lowered_arg.value_expr
            let arg_peeled = ci_peel_transparent(session, arg_cursor)
            if ci_cursor_is_array_type(session, arg_peeled):
                let arg_kind = with_ci_cursor_kind(session, arg_peeled)
                if arg_kind != CXK_STRING_LITERAL:
                    let elem_ty = types.named_type_from_text(ci_array_elem_type_from_cursor(session, arg_peeled))
                    if (elem_ty as i32) == 0:
                        return ci_value_ir_invalid()
                    arg_id = exprs.add(CiExprKind.CIE_ARRAY_DECAY, arg_id as i32, elem_ty as i32, 0, 0 as CiTypeId)
            let arg_src = with_ci_cursor_source_text(session, arg_cursor)
            if ci_expand_string_macro_sequence(session, arg_src).len() > 0 and exprs.kind(arg_id) != CiExprKind.CIE_STRING_LIT:
                return ci_value_ir_invalid()
            arg_ids.push(arg_id as i32)
            ai = ai + 1
        let has_mapped_call = callee_text.len() > 0 and ci_has_value_libc_call_mapping(callee_text)
        let mapped_id = if has_mapped_call:
            exprs.build_libc_call_value_expr(session, cursor, callee_text, &arg_ids, types)
        else:
            0 as CiExprId
        if (mapped_id as i32) != 0:
            return CiValueExprIR {
                setup_stmt: setup,
                value_expr: mapped_id,
            }
        if has_mapped_call:
            return ci_value_ir_invalid()
        if callee_text.len() > 0 and ci_is_c_ident(callee_text) and not ci_scope_contains(scope, callee_text):
            let callee_cursor = if nc > 0: with_ci_child(session, cursor, 0) else: cursor
            if not ci_note_filtered_system_symbol_ref_at(session, callee_cursor, callee_text, CI_LIBC_KIND_FN):
                return ci_value_ir_invalid()
        let args_start = exprs.extra_len()
        var j: i64 = 0
        while j < arg_ids.len():
            let _ = exprs.add_extra(arg_ids.get(j))
            j = j + 1
        return CiValueExprIR {
            setup_stmt: setup,
            value_expr: exprs.add(CiExprKind.CIE_CALL, callee.value_expr as i32, args_start, arg_ids.len() as i32, 0 as CiTypeId),
        }

    if kind == CXK_MEMBER_REF and nc > 0:
        let base = self.lower_value_expr_ir(session, with_ci_child(session, cursor, 0), exprs, types, scope)
        let field = with_ci_member_field_name(session, cursor)
        if ci_value_ir_valid(base) and field.len() > 0:
            let field_idx = exprs.add_string(ci_escape_reserved(field))
            let field_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
            return CiValueExprIR {
                setup_stmt: base.setup_stmt,
                value_expr: exprs.add(CiExprKind.CIE_FIELD, base.value_expr as i32, field_idx, 0, field_ty),
            }
        return ci_value_ir_invalid()

    if kind == CXK_ARRAY_SUBSCRIPT and nc >= 2:
        let glibc_ctype_case_id = exprs.lower_glibc_ctype_case_macro(session, cursor, types, scope)
        if (glibc_ctype_case_id as i32) != 0:
            return ci_value_ir_plain(glibc_ctype_case_id)
        let arr_cursor = with_ci_child(session, cursor, 0)
        let idx_cursor = with_ci_child(session, cursor, 1)
        let arr = self.lower_value_expr_ir(session, arr_cursor, exprs, types, scope)
        let idx = self.lower_value_expr_ir(session, idx_cursor, exprs, types, scope)
        if ci_value_ir_valid(arr) and ci_value_ir_valid(idx):
            let raw_ptr_index = ci_index_base_is_raw_pointer(session, arr_cursor, arr.value_expr, exprs, types)
            return CiValueExprIR {
                setup_stmt: self.merge_ir( arr.setup_stmt, idx.setup_stmt),
                value_expr: exprs.add(CiExprKind.CIE_INDEX, arr.value_expr as i32, idx.value_expr as i32, raw_ptr_index, 0 as CiTypeId),
            }
        return ci_value_ir_invalid()

    if kind == CXK_COMPOUND_LITERAL and nc > 0:
        let init_cursor = ci_find_child_of_kind(session, cursor, CXK_INIT_LIST)
        if init_cursor >= 0:
            let init_id = exprs.lower_init_list_ir(session, init_cursor, types, scope)
            if (init_id as i32) == 0:
                return ci_value_ir_invalid()
            let literal_ty = types.type_from_libclang(session, with_ci_cursor_type(session, cursor))
            if (literal_ty as i32) != 0 and exprs.get_type(init_id) != literal_ty:
                return ci_value_ir_plain(exprs.cast(literal_ty, init_id))
            return ci_value_ir_plain(init_id)
        return ci_value_ir_invalid()

    if kind == CXK_INIT_LIST:
        let init_id = exprs.lower_init_list_ir(session, cursor, types, scope)
        if (init_id as i32) != 0:
            return ci_value_ir_plain(init_id)
        return ci_value_ir_invalid()

    if kind == 122 and nc > 0:
        return self.lower_value_expr_ir(session, with_ci_child(session, cursor, nc - 1), exprs, types, scope)

    if kind != CXK_INIT_LIST and kind != CXK_COMPOUND_LITERAL:
        let raw_src = with_ci_cursor_source_text(session, cursor)
        var expanded_src = ci_expand_string_macro_sequence(session, raw_src)
        if expanded_src.len() > 0 and ci_string_text_contains_macro_like_ident(expanded_src):
            let preprocessed_src = ci_preprocessed_string_sequence_for_cursor(session, cursor, raw_src)
            let preprocessed_expanded = ci_expand_string_macro_sequence(session, preprocessed_src)
            if preprocessed_expanded.len() > 0:
                expanded_src = preprocessed_expanded
        if expanded_src.len() > 0:
            if ci_is_string_literal(expanded_src) or ci_is_concatenated_string(expanded_src):
                let str_idx = exprs.add_string(expanded_src)
                return ci_value_ir_plain(exprs.add(CiExprKind.CIE_STRING_LIT, str_idx, 0, 0, 0 as CiTypeId))
            return ci_value_ir_invalid()

    let expr_id = exprs.lower_expr_ir(session, cursor, types, scope)
    if (expr_id as i32) != 0:
        return ci_value_ir_plain(expr_id)
    ci_value_ir_invalid()

fn ci_unary_op_from_source(src: str) -> i32:
    let t = ci_trim(ci_strip_parens(ci_strip_c_comments(src)))
    if t.len() >= 2:
        if t.byte_at(0) == 43 and t.byte_at(1) == 43: return UO_PRE_INC
        if t.byte_at(0) == 45 and t.byte_at(1) == 45: return UO_PRE_DEC
        if t.byte_at(t.len() - 2) == 43 and t.byte_at(t.len() - 1) == 43: return UO_POST_INC
        if t.byte_at(t.len() - 2) == 45 and t.byte_at(t.len() - 1) == 45: return UO_POST_DEC
    if t.len() > 0:
        if t.byte_at(0) == 45: return UO_MINUS
        if t.byte_at(0) == 33: return UO_LNOT
        if t.byte_at(0) == 126: return UO_NOT
        if t.byte_at(0) == 38: return UO_ADDR
        if t.byte_at(0) == 42: return UO_DEREF
        if t.byte_at(0) == 43: return UO_PLUS
    -1

fn ci_condition_unwrap_cursor(session: i64, cursor: i32) -> i32:
    var c = cursor
    var depth = 0
    while depth < 8:
        let kind = with_ci_cursor_kind(session, c)
        if (kind == CXK_PAREN_EXPR or kind == 100 or kind == CXK_IMPLICIT_CAST) and with_ci_num_children(session, c) == 1:
            c = with_ci_child(session, c, 0)
            depth = depth + 1
        else:
            return c
    c

// Structural counterpart of ci_trans_bool_expr — produces a
// CiExprId representing a boolean expression. Mirrors the legacy
// peel / comparison / LAND / LOR / LNOT / ternary arms but builds
// CIE_BINARY(CIBO_EQ/NEQ/LT/…), CIE_UNARY(CIUO_LOGICAL_NOT),
// CIE_TERNARY, and truthy-fallback CIE_BINARY(CIBO_NEQ, x, 0/null/0.0).
//
// Returns 0 as CiExprId only when the inner expression itself can't
// be structurally lowered (ci_lower_expr_ir returns 0).
fn CiExprPool.lower_bool_expr(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    let kind = with_ci_cursor_kind(session, cursor)

    if kind == CXK_UNEXPOSED_STMT:
        let inner = ci_find_last_expr_child(session, cursor)
        if inner >= 0:
            return self.lower_bool_expr(session, inner, types, scope)
        return 0 as CiExprId

    // Transparent wrappers — peel and recurse.
    if (kind == CXK_PAREN_EXPR or kind == 100 or kind == CXK_IMPLICIT_CAST) and with_ci_num_children(session, cursor) == 1:
        return self.lower_bool_expr(session, with_ci_child(session, cursor, 0), types, scope)

    if kind == CXK_BINARY_OP:
        let op = with_ci_binary_op(session, cursor)
        let nc = with_ci_num_children(session, cursor)
        // Comparison: structural CIE_BINARY with comparison op.
        if (op == BO_EQ or op == BO_NE or op == BO_LT or op == BO_GT or op == BO_LE or op == BO_GE) and nc >= 2:
            let lhs_cursor = with_ci_child(session, cursor, 0)
            let rhs_cursor = with_ci_child(session, cursor, 1)
            let lhs_id = self.lower_expr_ir(session, lhs_cursor, types, scope)
            let rhs_id = self.lower_expr_ir(session, rhs_cursor, types, scope)
            if (lhs_id as i32) != 0 and (rhs_id as i32) != 0:
                var ci_op: i32 = 0
                if op == BO_EQ: ci_op = CiBinOp.CIBO_EQ
                if op == BO_NE: ci_op = CiBinOp.CIBO_NEQ
                if op == BO_LT: ci_op = CiBinOp.CIBO_LT
                if op == BO_GT: ci_op = CiBinOp.CIBO_GT
                if op == BO_LE: ci_op = CiBinOp.CIBO_LTE
                if op == BO_GE: ci_op = CiBinOp.CIBO_GTE
                return self.binary(ci_op, lhs_id, rhs_id, 0 as CiTypeId)
        // Logical and / or — recurse on each side as bool.
        if (op == BO_LAND or op == BO_LOR) and nc >= 2:
            let bool_lhs = self.lower_bool_expr(session, with_ci_child(session, cursor, 0), types, scope)
            let bool_rhs = self.lower_bool_expr(session, with_ci_child(session, cursor, 1), types, scope)
            if (bool_lhs as i32) != 0 and (bool_rhs as i32) != 0:
                let ci_op = if op == BO_LAND: CiBinOp.CIBO_LOGICAL_AND else: CiBinOp.CIBO_LOGICAL_OR
                return self.binary(ci_op, bool_lhs, bool_rhs, 0 as CiTypeId)

    if kind == CXK_UNARY_OP:
        let op = with_ci_unary_op(session, cursor)
        if op == UO_LNOT:
            let nc = with_ci_num_children(session, cursor)
            if nc >= 1:
                let inner = self.lower_bool_expr(session, with_ci_child(session, cursor, 0), types, scope)
                if (inner as i32) != 0:
                    return self.unary(CiUnaryOp.CIUO_LOGICAL_NOT, inner, 0 as CiTypeId)

    // Ternary: `cond ? then : else` used as a boolean. Recurse into
    // both arms with ci_lower_bool_expr so we don't wrap the whole
    // thing in `(... != 0)`.
    if kind == CXK_COND_OP:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 3:
            let cond_id = self.lower_bool_expr(session, with_ci_child(session, cursor, 0), types, scope)
            let then_id = self.lower_bool_expr(session, with_ci_child(session, cursor, 1), types, scope)
            let else_id = self.lower_bool_expr(session, with_ci_child(session, cursor, 2), types, scope)
            if (cond_id as i32) != 0 and (then_id as i32) != 0 and (else_id as i32) != 0:
                return self.add(CiExprKind.CIE_TERNARY, cond_id as i32, then_id as i32, else_id as i32, 0 as CiTypeId)

    // Fallback: lower as a regular expression and wrap in the
    // appropriate truthy comparison. Matches ci_bool_truthy_expr's
    // type-aware zero/null fallback.
    let inner_id = self.lower_expr_ir(session, cursor, types, scope)
    if (inner_id as i32) == 0:
        return 0 as CiExprId
    if with_ci_type_is_bool(session, cursor) != 0:
        return inner_id
    if with_ci_type_is_pointer(session, cursor) != 0:
        let null_e = self.null_ptr(0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, inner_id, null_e, 0 as CiTypeId)
    if with_ci_type_is_float(session, cursor) != 0:
        let zero_fs = self.add_string("0.0")
        let zero_f = self.add(CiExprKind.CIE_FLOAT_LIT, zero_fs, 0, 0, 0 as CiTypeId)
        return self.binary(CiBinOp.CIBO_NEQ, inner_id, zero_f, 0 as CiTypeId)
    let zero_is = self.add_string("0")
    let zero_i = self.int_lit(zero_is, 0 as CiTypeId)
    self.binary(CiBinOp.CIBO_NEQ, inner_id, zero_i, 0 as CiTypeId)

// ── Statement translator ────────────────────────────────────

// Strip a single trailing '\n' from `s` if present. Used by the
// ci_trans_stmt IR shim to match the legacy's no-trailing-newline
// convention for single-line statements — the CiPrint layer always
// emits a trailing newline for the sake of block composition, and
// the legacy's compound-stmt loop adds its own newline via
// ci_indent_block, so we strip the redundant one on the way out.
fn ci_strip_trailing_newline(s: str) -> str:
    if s.len() == 0:
        return s
    if s.byte_at(s.len() - 1) == 10:
        return s.slice(0, s.len() - 1)
    s

// Extract (init, cond, inc, body) cursors from a CXK_FOR_STMT
// cursor by finding the two `;` characters in the for header via
// source-text scan. libclang ForStmt skips NULL children so the
// child index doesn't identify roles directly. Returns the cursors
// as (init, cond, inc, body); any missing component is -1.
type CiForParts {
    init_cursor: i32 = -1
    cond_cursor: i32 = -1
    inc_cursor: i32 = -1
    body_cursor: i32 = -1
}

fn ci_extract_for_parts(session: i64, cursor: i32) -> CiForParts:
    var parts = CiForParts { init_cursor: -1, cond_cursor: -1, inc_cursor: -1, body_cursor: -1 }
    let nc = with_ci_num_children(session, cursor)
    if nc < 1:
        return parts
    let body_idx = nc - 1
    parts.body_cursor = with_ci_child(session, cursor, body_idx)
    if nc < 2:
        return parts
    let for_start = with_ci_cursor_start_offset(session, cursor)
    let body_start = with_ci_cursor_start_offset(session, parts.body_cursor)
    let for_src = with_ci_cursor_source_text(session, cursor)
    var sc1_off: i32 = -1
    var sc2_off: i32 = -1
    if for_start >= 0 and body_start > for_start and for_src.len() > 0:
        let header_len = body_start - for_start
        let limit = if header_len < for_src.len() as i32: header_len else: for_src.len() as i32
        var paren_depth = 0
        var i = 0
        while i < limit:
            let c = for_src.byte_at(i as i64)
            if c == 40:
                paren_depth = paren_depth + 1
            else if c == 41:
                paren_depth = paren_depth - 1
            else if c == 59 and paren_depth == 1:
                if sc1_off < 0:
                    sc1_off = for_start + i
                else if sc2_off < 0:
                    sc2_off = for_start + i
            i = i + 1
    if sc1_off >= 0 and sc2_off >= 0:
        var ci_idx = 0
        while ci_idx < body_idx:
            let child = with_ci_child(session, cursor, ci_idx)
            let off = with_ci_cursor_start_offset(session, child)
            if off >= 0:
                if off < sc1_off:
                    parts.init_cursor = child
                else if off < sc2_off:
                    parts.cond_cursor = child
                else:
                    parts.inc_cursor = child
            ci_idx = ci_idx + 1
    else:
        // Source text unavailable — fall back to positional heuristic.
        let child0 = with_ci_child(session, cursor, 0)
        let child0_kind = with_ci_cursor_kind(session, child0)
        if body_idx == 1:
            parts.cond_cursor = child0
        else if body_idx == 2:
            let child1 = with_ci_child(session, cursor, 1)
            if child0_kind == CXK_DECL_STMT:
                parts.init_cursor = child0
                parts.cond_cursor = child1
            else:
                parts.cond_cursor = child0
                parts.inc_cursor = child1
        else if body_idx == 3:
            parts.init_cursor = child0
            parts.cond_cursor = with_ci_child(session, cursor, 1)
            parts.inc_cursor = with_ci_child(session, cursor, 2)
    if parts.init_cursor >= 0:
        let init_kind = with_ci_cursor_kind(session, parts.init_cursor)
        if init_kind == CXK_NULL_STMT or (init_kind != CXK_DECL_STMT and not ci_cursor_kind_is_expression(init_kind)):
            parts.init_cursor = -1
    if parts.cond_cursor >= 0:
        let cond_kind = with_ci_cursor_kind(session, parts.cond_cursor)
        if cond_kind == CXK_NULL_STMT or not ci_cursor_kind_is_expression(cond_kind):
            parts.cond_cursor = -1
    if parts.inc_cursor >= 0:
        let inc_kind = with_ci_cursor_kind(session, parts.inc_cursor)
        if inc_kind == CXK_NULL_STMT or not ci_cursor_kind_is_expression(inc_kind):
            parts.inc_cursor = -1
    parts

// Structural lowering for CXK_FOR_STMT. Desugars to:
//     <init_stmt>
//     while <cond>:
//         <body>
//         <inc>
// where init becomes a leading statement in an enclosing CIS_BLOCK,
// cond becomes a structural boolean CiExpr, and inc becomes the
// last structural statement in the while body.
fn CiStmtPool.lower_for_stmt_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiStmtId:
    let parts = ci_extract_for_parts(session, cursor)
    let scope_mark = ci_scope_mark(scope)
    if parts.body_cursor < 0:
        if g_ci_bail_location.len() == 0:
            g_ci_bail_location = with_ci_cursor_location(session, cursor)
            g_ci_bail_kind = CXK_FOR_STMT
        return 0 as CiStmtId

    var inner_scope = scope
    var init_id: CiStmtId = 0 as CiStmtId
    if parts.init_cursor >= 0:
        if with_ci_cursor_kind(session, parts.init_cursor) == CXK_DECL_STMT:
            ci_trace_port("STRUCTURAL[b11.6.decl_for_init]")
            let decl_ir = self.lower_decl_stmt_structural(session, parts.init_cursor, inner_scope, false, exprs, types)
            if (decl_ir.stmt_id as i32) == 0:
                if g_ci_bail_location.len() == 0:
                    g_ci_bail_location = with_ci_cursor_location(session, parts.init_cursor)
                    g_ci_bail_kind = CXK_DECL_STMT
                let _ = ci_scope_restore(inner_scope, scope_mark)
                return 0 as CiStmtId
            inner_scope = decl_ir.updated_scope
            init_id = decl_ir.stmt_id
        else:
            init_id = self.lower_stmt_expr_ir(session, parts.init_cursor, exprs, types, inner_scope)
            if (init_id as i32) == 0:
                if g_ci_bail_location.len() == 0:
                    g_ci_bail_location = with_ci_cursor_location(session, parts.init_cursor)
                    g_ci_bail_kind = with_ci_cursor_kind(session, parts.init_cursor)
                let _ = ci_scope_restore(inner_scope, scope_mark)
                return 0 as CiStmtId

    var cond_setup_id: CiStmtId = 0 as CiStmtId
    var cond_id: CiExprId = 0 as CiExprId
    if parts.cond_cursor >= 0:
        let prepared_cond = self.prepare_stmt_condition_ir(session, parts.cond_cursor, exprs, types, inner_scope)
        if not ci_value_ir_valid(prepared_cond):
            if g_ci_bail_location.len() == 0:
                g_ci_bail_location = with_ci_cursor_location(session, parts.cond_cursor)
                g_ci_bail_kind = with_ci_cursor_kind(session, parts.cond_cursor)
            let _ = ci_scope_restore(inner_scope, scope_mark)
            return 0 as CiStmtId
        ci_trace_port("STRUCTURAL[b11.1.for_stmt_cond]")
        cond_setup_id = prepared_cond.setup_stmt
        cond_id = prepared_cond.value_expr
    else:
        cond_id = exprs.bool_lit(1, 0 as CiTypeId)

    var body_id = self.lower_stmt_ir(session, parts.body_cursor, exprs, types, 0, inner_scope)
    if (body_id as i32) == 0:
        if g_ci_bail_location.len() == 0:
            g_ci_bail_location = with_ci_cursor_location(session, parts.body_cursor)
            g_ci_bail_kind = with_ci_cursor_kind(session, parts.body_cursor)
        let _ = ci_scope_restore(inner_scope, scope_mark)
        return 0 as CiStmtId

    var inc_stmt_id: CiStmtId = 0 as CiStmtId
    if parts.inc_cursor >= 0:
        inc_stmt_id = self.lower_stmt_expr_ir(session, parts.inc_cursor, exprs, types, inner_scope)
        if (inc_stmt_id as i32) == 0:
            if g_ci_bail_location.len() == 0:
                g_ci_bail_location = with_ci_cursor_location(session, parts.inc_cursor)
                g_ci_bail_kind = with_ci_cursor_kind(session, parts.inc_cursor)
            let _ = ci_scope_restore(inner_scope, scope_mark)
            return 0 as CiStmtId
        body_id = self.for_continue_runs_inc_ir( body_id, inc_stmt_id)

    // Body + inc wrapped in a block (if we have an inc).
    var while_body_id: CiStmtId = body_id
    if (inc_stmt_id as i32) != 0:
        let bstart = self.extra_len()
        let _ = self.add_extra(body_id as i32)
        let _ = self.add_extra(inc_stmt_id as i32)
        while_body_id = self.block(bstart, 2)

    var while_id: CiStmtId = 0 as CiStmtId
    if (cond_setup_id as i32) == 0:
        while_id = self.while_stmt(cond_id, while_body_id)
    else:
        let if_break = self.build_if_not_break_ir(exprs, cond_id)
        let loop_body_id = self.merge3_ir( cond_setup_id, if_break, while_body_id)
        let true_cond = exprs.bool_lit(1, 0 as CiTypeId)
        while_id = self.while_stmt(true_cond, loop_body_id)

    // Final: wrap init + while in a block if init is non-empty.
    if (init_id as i32) != 0:
        let wstart = self.extra_len()
        let _ = self.add_extra(init_id as i32)
        let _ = self.add_extra(while_id as i32)
        let result = self.block(wstart, 2)
        let _ = ci_scope_restore(inner_scope, scope_mark)
        return result
    let _ = ci_scope_restore(inner_scope, scope_mark)
    while_id

// Structural lowering for expression cursors when the value is
// discarded (plain `expr;` and `for (...; ...; inc)`). This uses
// the same value-position lowering as ci_lower_value_expr_ir, then
// decides whether the terminal expression itself must still be
// evaluated for effect.
fn CiStmtPool.lower_stmt_expr_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiStmtId:
    self.lower_effect_expr_ir(session, cursor, exprs, types, scope)

// Strip trailing CIS_BREAK children from a structural CIS_BLOCK,
// returning a NEW CIS_BLOCK (or the original stmt_id when no
// break is trailing, or when the input isn't a CIS_BLOCK). Used
// by the structural switch arm-body lowering path to remove the
// `break` that terminates a case before emitting the arm body
// into a CIS_MATCH.
fn CiStmtPool.strip_trailing_break_ir(self: CiStmtPool, stmt_id: CiStmtId) -> CiStmtId:
    if (stmt_id as i32) == 0:
        return stmt_id
    if self.kind(stmt_id) != CiStmtKind.CIS_BLOCK:
        // Non-block: if it's directly a CIS_BREAK, return 0 (empty).
        if self.kind(stmt_id) == CiStmtKind.CIS_BREAK:
            return 0 as CiStmtId
        return stmt_id
    let extra_start = self.get_d0(stmt_id)
    let count = self.get_d1(stmt_id)
    if count == 0:
        return stmt_id
    let last_child_id = (self.get_extra(extra_start + count - 1)) as CiStmtId
    if self.kind(last_child_id) != CiStmtKind.CIS_BREAK:
        return stmt_id
    // Rebuild the block without the trailing CIS_BREAK.
    let new_count = count - 1
    if new_count == 0:
        return 0 as CiStmtId
    let new_start = self.extra_len()
    var i: i32 = 0
    while i < new_count:
        let _ = self.add_extra(self.get_extra(extra_start + i))
        i = i + 1
    self.block(new_start, new_count)

fn CiStmtPool.lower_switch_prong_forward_ir(self: CiStmtPool, session: i64, body_cursor: i32, start_idx: i32, total: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiStmtId:
    var part_ids: Vec[i32] = Vec.new()
    let start_child = with_ci_child(session, body_cursor, start_idx)
    let start_kind = with_ci_cursor_kind(session, start_child)
    if start_kind == CXK_CASE_STMT or start_kind == CXK_DEFAULT_STMT:
        let inner = ci_drill_innermost_case_substmt(session, start_child)
        if inner >= 0:
            let bk = with_ci_cursor_kind(session, inner)
            if bk == CXK_BREAK_STMT:
                return 0 as CiStmtId
            if bk != CXK_BREAK_STMT and not ci_is_null_like_stmt(session, inner):
                let inner_id = self.lower_stmt_ir(session, inner, exprs, types, 0, scope)
                if (inner_id as i32) == 0:
                    return 0 as CiStmtId
                part_ids.push(inner_id as i32)
            if ci_stmt_ends_with_terminator(session, inner):
                return self.from_flat_ids(&part_ids)
    var j = start_idx + 1
    while j < total:
        let next_child = with_ci_child(session, body_cursor, j)
        let next_kind = with_ci_cursor_kind(session, next_child)
        if next_kind == CXK_BREAK_STMT:
            return self.from_flat_ids(&part_ids)
        if next_kind == CXK_CASE_STMT or next_kind == CXK_DEFAULT_STMT:
            let dup_id = self.lower_switch_prong_forward_ir(session, body_cursor, j, total, exprs, types, scope)
            if (dup_id as i32) != 0:
                part_ids.push(dup_id as i32)
            return self.from_flat_ids(&part_ids)
        if not ci_is_null_like_stmt(session, next_child):
            let next_id = self.lower_stmt_ir(session, next_child, exprs, types, 0, scope)
            if (next_id as i32) != 0:
                part_ids.push(next_id as i32)
            if ci_stmt_ends_with_terminator(session, next_child):
                return self.from_flat_ids(&part_ids)
        j = j + 1
    self.from_flat_ids(&part_ids)

// Structural lowering for CXK_SWITCH_STMT. Builds a CIS_MATCH
// with structural subject and arm bodies. Mirrors the branching
// structure of the old switch lowering: simple per-case arms when
// there's no fallthrough, prong-duplicated arms otherwise.
//
// Arm records in self.extra: [value_count, value_exprs...,
// body_stmt_id]. Default arms have value_count == 0.
//
// Returns 0 when something in the switch body doesn't map cleanly
// so the enclosing structural lowering attempt can bail.
fn CiStmtPool.lower_switch_stmt_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiStmtId:
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        return 0 as CiStmtId
    // Fully-structural path only. When it bails, returning 0
    // makes ci_lower_stmt_ir fall through to the legacy
    // ci_trans_stmt text handler.
    self.lower_switch_stmt_ir_structural(session, cursor, exprs, types, scope)

// Fully-structural switch lowering. Uses ci_lower_expr_ir for
// subject and case values, ci_lower_stmt_ir for arm bodies,
// and ci_strip_trailing_break_ir to remove the terminating break
// from each case body. Bails (returns 0) on unsupported switch
// shapes so the enclosing structural lowering attempt can abort.
fn CiStmtPool.lower_switch_stmt_ir_structural(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, scope: CiScope) -> CiStmtId:
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        return 0 as CiStmtId
    let cond_cursor = with_ci_child(session, cursor, 0)
    let body_cursor = with_ci_child(session, cursor, 1)
    let body_nc = with_ci_num_children(session, body_cursor)

    let prepared_subject = self.prepare_stmt_subject_ir(session, cond_cursor, exprs, types, scope, "switch")
    if not ci_value_ir_valid(prepared_subject):
        if g_ci_bail_location.len() == 0:
            g_ci_bail_location = with_ci_cursor_location(session, cond_cursor)
            g_ci_bail_kind = with_ci_cursor_kind(session, cond_cursor)
        return 0 as CiStmtId
    ci_trace_port("STRUCTURAL[b11.7.switch_subject]")
    let subject_id = prepared_subject.value_expr

    var arm_records: Vec[i32] = Vec.new()
    var arm_count = 0
    var default_body_id: CiStmtId = 0 as CiStmtId
    var has_default_body = false
    var i = 0
    while i < body_nc:
        let child = with_ci_child(session, body_cursor, i)
        let ck = with_ci_cursor_kind(session, child)
        if ck == CXK_CASE_STMT:
            var value_ids: Vec[i32] = Vec.new()
            var chain = child
            while with_ci_cursor_kind(session, chain) == CXK_CASE_STMT:
                let cnc = with_ci_num_children(session, chain)
                if cnc < 2:
                    return 0 as CiStmtId
                let val_id = exprs.lower_case_value_ir(session, with_ci_child(session, chain, 0), types, scope)
                if (val_id as i32) == 0:
                    return 0 as CiStmtId
                value_ids.push(val_id as i32)
                chain = with_ci_child(session, chain, 1)
            var body_ids: Vec[i32] = Vec.new()
            let inner_kind = with_ci_cursor_kind(session, chain)
            if inner_kind != CXK_BREAK_STMT and not ci_is_null_like_stmt(session, chain):
                let inner_id = self.lower_stmt_ir(session, chain, exprs, types, 0, scope)
                if (inner_id as i32) == 0:
                    return 0 as CiStmtId
                body_ids.push(inner_id as i32)
            var hit_break = ci_stmt_ends_with_terminator(session, chain)
            var j = i + 1
            while j < body_nc:
                let sib = with_ci_child(session, body_cursor, j)
                let sk = with_ci_cursor_kind(session, sib)
                if sk == CXK_CASE_STMT or sk == CXK_DEFAULT_STMT:
                    break
                if sk == CXK_BREAK_STMT:
                    hit_break = true
                    j = j + 1
                    break
                if not ci_is_null_like_stmt(session, sib):
                    let sib_id = self.lower_stmt_ir(session, sib, exprs, types, 0, scope)
                    if (sib_id as i32) == 0:
                        return 0 as CiStmtId
                    body_ids.push(sib_id as i32)
                    if ci_stmt_ends_with_terminator(session, sib):
                        hit_break = true
                        j = j + 1
                        break
                j = j + 1
            if not hit_break and j < body_nc:
                let probe_kind = with_ci_cursor_kind(session, with_ci_child(session, body_cursor, j))
                if probe_kind == CXK_CASE_STMT or probe_kind == CXK_DEFAULT_STMT:
                    let fwd_id = self.lower_switch_prong_forward_ir(session, body_cursor, j, body_nc, exprs, types, scope)
                    if (fwd_id as i32) == 0 and g_ci_bail_location.len() > 0:
                        return 0 as CiStmtId
                    if (fwd_id as i32) != 0:
                        body_ids.push(fwd_id as i32)
            let raw_body = self.from_flat_ids(&body_ids)
            let body_id = self.strip_trailing_break_ir(raw_body)
            if (body_id as i32) == 0 and body_ids.len() > 0 and not hit_break:
                return 0 as CiStmtId
            if (body_id as i32) != 0 or hit_break:
                arm_records.push(value_ids.len() as i32)
                var vi: i64 = 0
                while vi < value_ids.len():
                    arm_records.push(value_ids.get(vi))
                    vi = vi + 1
                arm_records.push(body_id as i32)
                arm_count = arm_count + 1
            i = j
            continue
        else if ck == CXK_DEFAULT_STMT:
            let inner = ci_drill_innermost_case_substmt(session, child)
            var body_ids: Vec[i32] = Vec.new()
            var hit_break = false
            if inner >= 0:
                let inner_kind = with_ci_cursor_kind(session, inner)
                if inner_kind != CXK_BREAK_STMT and not ci_is_null_like_stmt(session, inner):
                    let inner_id = self.lower_stmt_ir(session, inner, exprs, types, 0, scope)
                    if (inner_id as i32) == 0:
                        return 0 as CiStmtId
                    body_ids.push(inner_id as i32)
                hit_break = ci_stmt_ends_with_terminator(session, inner)
            var j = i + 1
            while j < body_nc:
                let sib = with_ci_child(session, body_cursor, j)
                let sk = with_ci_cursor_kind(session, sib)
                if sk == CXK_CASE_STMT or sk == CXK_DEFAULT_STMT:
                    break
                if sk == CXK_BREAK_STMT:
                    hit_break = true
                    j = j + 1
                    break
                if not ci_is_null_like_stmt(session, sib):
                    let sib_id = self.lower_stmt_ir(session, sib, exprs, types, 0, scope)
                    if (sib_id as i32) == 0:
                        return 0 as CiStmtId
                    body_ids.push(sib_id as i32)
                    if ci_stmt_ends_with_terminator(session, sib):
                        hit_break = true
                        j = j + 1
                        break
                j = j + 1
            if not hit_break and j < body_nc:
                let probe_kind = with_ci_cursor_kind(session, with_ci_child(session, body_cursor, j))
                if probe_kind == CXK_CASE_STMT or probe_kind == CXK_DEFAULT_STMT:
                    let fwd_id = self.lower_switch_prong_forward_ir(session, body_cursor, j, body_nc, exprs, types, scope)
                    if (fwd_id as i32) == 0 and g_ci_bail_location.len() > 0:
                        return 0 as CiStmtId
                    if (fwd_id as i32) != 0:
                        body_ids.push(fwd_id as i32)
            let raw_body = self.from_flat_ids(&body_ids)
            let body_id = self.strip_trailing_break_ir(raw_body)
            if (body_id as i32) == 0 and body_ids.len() > 0 and not hit_break:
                return 0 as CiStmtId
            if (body_id as i32) != 0 or hit_break:
                default_body_id = body_id
                has_default_body = true
            i = j
            continue
        i = i + 1

    if has_default_body:
        arm_records.push(0)
        arm_records.push(default_body_id as i32)
        arm_count = arm_count + 1

    if arm_count == 0:
        return 0 as CiStmtId

    let arms_start = self.extra_len()
    var ri: i64 = 0
    while ri < arm_records.len():
        let _ = self.add_extra(arm_records.get(ri))
        ri = ri + 1
    let match_id = self.add(CiStmtKind.CIS_MATCH, subject_id as i32, arms_start, arm_count, 0)
    let switch_id = self.wrap_switch_match_breaks_ir(session, body_cursor, exprs, types, match_id, -1)
    if (switch_id as i32) == 0:
        return 0 as CiStmtId
    self.merge_ir( prepared_subject.setup_stmt, switch_id)

fn CiExprPool.lower_case_value_ir(self: CiExprPool, session: i64, cursor: i32, types: CiTypePool, scope: CiScope) -> CiExprId:
    if with_ci_eval_int_valid(session, cursor) != 0:
        let text_idx = self.add_string(ci_eval_int_text(session, cursor))
        return self.int_lit(text_idx, 0 as CiTypeId)
    self.lower_expr_ir(session, cursor, types, scope)

// Recursive statement lowering helper: produces a CiStmtId from a
// cursor. Specific handlers build real CIS_* nodes for kinds we
// own structurally; everything else: returns 0 so callers can bail
// transactionally. Returns 0 for the empty case (CXK_NULL_STMT).
fn CiStmtPool.lower_stmt_ir(self: CiStmtPool, session: i64, cursor: i32, exprs: CiExprPool, types: CiTypePool, indent: i32, scope: CiScope) -> CiStmtId:
    let kind = with_ci_cursor_kind(session, cursor)

    if kind == CXK_UNEXPOSED_STMT:
        let inner_expr = ci_find_last_expr_child(session, cursor)
        if inner_expr >= 0:
            return self.lower_stmt_expr_ir(session, cursor, exprs, types, scope)
        return 0 as CiStmtId

    if kind == CXK_BREAK_STMT:
        return self.break_()
    if kind == CXK_CONTINUE_STMT:
        return self.continue_()
    if kind == CXK_NULL_STMT:
        return 0 as CiStmtId

    if kind == CXK_RETURN_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc == 0:
            return self.return_(0 as CiExprId)
        let ret_child = with_ci_child(session, cursor, 0)
        let lowered_ret = self.lower_value_expr_ir(session, ret_child, exprs, types, scope)
        if ci_value_ir_valid(lowered_ret):
            var ret_value = lowered_ret.value_expr
            let ret_peeled = ci_peel_transparent(session, ret_child)
            if ci_cursor_is_array_type(session, ret_peeled):
                let elem_ty = ci_array_elem_type_from_cursor(session, ret_peeled)
                if elem_ty.len() > 0:
                    let elem_ty_id = types.named_type_from_text(elem_ty)
                    if (elem_ty_id as i32) == 0:
                        return 0 as CiStmtId
                    ret_value = exprs.add(CiExprKind.CIE_ARRAY_DECAY, ret_value as i32, elem_ty_id as i32, 0, 0 as CiTypeId)
            let return_id = self.return_(ret_value)
            return self.merge_ir( lowered_ret.setup_stmt, return_id)

    // Structural if statement. Sequenced conditions are emitted
    // as setup statements before the `if`.
    if kind == CXK_IF_STMT:
        let ifnc = with_ci_num_children(session, cursor)
        if ifnc >= 2:
            let cond_cursor = with_ci_child(session, cursor, 0)
            let then_child = with_ci_child(session, cursor, 1)
            let prepared_cond = self.prepare_stmt_condition_ir(session, cond_cursor, exprs, types, scope)
            if ci_value_ir_valid(prepared_cond):
                ci_trace_port("STRUCTURAL[b11.1.if_stmt_ir]")
                let then_id = self.lower_stmt_ir(session, then_child, exprs, types, 0, scope)
                if (then_id as i32) == 0:
                    ci_trace_port("STRUCTURAL[b11.1.if_stmt_ir] then lowering failed")
                else:
                    var then_empty = false
                    if self.kind(then_id) == CiStmtKind.CIS_BLOCK:
                        if self.get_d1(then_id) == 0:
                            then_empty = true
                    var else_id: CiStmtId = 0 as CiStmtId
                    if ifnc > 2:
                        let else_child = with_ci_child(session, cursor, 2)
                        else_id = self.lower_stmt_ir(session, else_child, exprs, types, 0, scope)
                    if then_empty and (else_id as i32) != 0:
                        let neg_cond = exprs.unary(CiUnaryOp.CIUO_LOGICAL_NOT, prepared_cond.value_expr, 0 as CiTypeId)
                        let if_id = self.if_stmt(neg_cond, else_id, 0 as CiStmtId)
                        return self.merge_ir( prepared_cond.setup_stmt, if_id)
                    if not then_empty:
                        let if_id = self.if_stmt(prepared_cond.value_expr, then_id, else_id)
                        return self.merge_ir( prepared_cond.setup_stmt, if_id)

    // Structural while statement. Sequenced conditions are
    // desugared to `while true: <setup>; if not cond: break; body`.
    if kind == CXK_WHILE_STMT:
        let wnc = with_ci_num_children(session, cursor)
        if wnc >= 2:
            let cond_cursor = with_ci_child(session, cursor, 0)
            let body_cursor = with_ci_child(session, cursor, 1)
            let prepared_cond = self.prepare_stmt_condition_ir(session, cond_cursor, exprs, types, scope)
            if ci_value_ir_valid(prepared_cond):
                ci_trace_port("STRUCTURAL[b11.1.while_stmt_ir]")
                let body_id = self.lower_stmt_ir(session, body_cursor, exprs, types, 0, scope)
                if (body_id as i32) != 0:
                    if (prepared_cond.setup_stmt as i32) == 0:
                        return self.while_stmt(prepared_cond.value_expr, body_id)
                    let if_break = self.build_if_not_break_ir(exprs, prepared_cond.value_expr)
                    let loop_body_id = self.merge3_ir( prepared_cond.setup_stmt, if_break, body_id)
                    let true_cond = exprs.bool_lit(1, 0 as CiTypeId)
                    return self.while_stmt(true_cond, loop_body_id)

    // Structural for statement. Desugars `for (init; cond; inc) body`
    // to a block containing the init statement plus a while loop
    // whose body ends with the inc statement.
    if kind == CXK_FOR_STMT:
        let for_id = self.lower_for_stmt_ir(session, cursor, exprs, types, scope)
        if (for_id as i32) != 0:
            return for_id

    // Structural switch statement. Builds a CIS_MATCH; handles
    // both simple (non-fallthrough) and prong-duplicated
    // fallthrough cases.
    if kind == CXK_SWITCH_STMT:
        let switch_id = self.lower_switch_stmt_ir(session, cursor, exprs, types, scope)
        if (switch_id as i32) != 0:
            return switch_id

    if kind == CXK_DO_STMT:
        let dnc = with_ci_num_children(session, cursor)
        if dnc >= 2:
            let body_cursor = with_ci_child(session, cursor, 0)
            let cond_cursor = with_ci_child(session, cursor, 1)
            let prepared_cond = self.prepare_stmt_condition_ir(session, cond_cursor, exprs, types, scope)
            if ci_value_ir_valid(prepared_cond):
                ci_trace_port("STRUCTURAL[b11.1.do_stmt_ir]")
                let body_id = self.lower_stmt_ir(session, body_cursor, exprs, types, 0, scope)
                if (body_id as i32) != 0:
                    return self.do_while_stmt(body_id, prepared_cond.value_expr, prepared_cond.setup_stmt)

    // Compound statement with gotos. Lower the whole function body
    // to a CFG, recover structured control with std.cfg.stackify,
    // and emit labeled With blocks/loops.
    if kind == CXK_COMPOUND_STMT and ci_has_goto(session, cursor):
        return self.lower_goto_body_stackify(session, cursor, scope, exprs, types)

    // Structural compound statement. Iterates children, threading
    // block_scope through decl_stmts. If ANY child fails to lower
    // structurally (decl bails, or a child stmt returns 0 for a
    // non-NULL kind), bail the whole block transactionally.
    if kind == CXK_COMPOUND_STMT:
        let ccn = with_ci_num_children(session, cursor)
        var child_ids: Vec[i32] = Vec.new()
        var block_scope = scope
        let block_mark = ci_scope_mark(block_scope)
        var bailed = false
        var ci = 0
        while ci < ccn and not bailed:
            let child = with_ci_child(session, cursor, ci)
            if with_ci_cursor_kind(session, child) == CXK_DECL_STMT:
                ci_trace_port("STRUCTURAL[b11.6.decl_compound]")
                let decl_ir = self.lower_decl_stmt_structural(session, child, block_scope, false, exprs, types)
                if (decl_ir.stmt_id as i32) != 0:
                    block_scope = decl_ir.updated_scope
                    child_ids.push(decl_ir.stmt_id as i32)
                else:
                    if g_ci_bail_location.len() == 0:
                        g_ci_bail_location = with_ci_cursor_location(session, child)
                        g_ci_bail_kind = CXK_DECL_STMT
                    bailed = true
            else:
                let child_id = self.lower_stmt_ir(session, child, exprs, types, 0, block_scope)
                if (child_id as i32) != 0:
                    child_ids.push(child_id as i32)
                else if not ci_is_null_like_stmt(session, child):
                    if g_ci_bail_location.len() == 0:
                        g_ci_bail_location = with_ci_cursor_location(session, child)
                        g_ci_bail_kind = with_ci_cursor_kind(session, child)
                    bailed = true
            ci = ci + 1

        if bailed:
            let _ = ci_scope_restore(block_scope, block_mark)
            return 0 as CiStmtId

        let extra_start = self.extra_len()
        let count = child_ids.len() as i32
        var cj: i64 = 0
        while cj < child_ids.len():
            let _ = self.add_extra(child_ids.get(cj))
            cj = cj + 1
        let block_id = self.block(extra_start, count)
        let _ = ci_scope_restore(block_scope, block_mark)
        return block_id

    // Expression-as-statement: same structural lowering as
    // ci_lower_expr_ir, plus statement-position-only handling for
    // top-level comma and inc/dec where the result value is
    // discarded. Unsupported statement-position expressions return
    // 0 here so the enclosing structural lowering attempt can bail.
    if ci_cursor_kind_is_expression(kind):
        return self.lower_stmt_expr_ir(session, cursor, exprs, types, scope)

    // Everything else: — struct/union decls at statement position or
    // any other unsupported stmt shape — returns 0 so the enclosing
    // structural lowering attempt can bail.
    if g_ci_bail_location.len() == 0:
        g_ci_bail_location = with_ci_cursor_location(session, cursor)
        g_ci_bail_kind = kind
    0 as CiStmtId

fn ci_cursor_kind_is_expression(kind: i32) -> bool:
    if kind == CXK_INT_LITERAL: return true
    if kind == CXK_FLOAT_LITERAL: return true
    if kind == CXK_STRING_LITERAL: return true
    if kind == CXK_CHAR_LITERAL: return true
    if kind == CXK_DECL_REF: return true
    if kind == CXK_MEMBER_REF: return true
    if kind == CXK_CALL_EXPR: return true
    if kind == CXK_ARRAY_SUBSCRIPT: return true
    if kind == CXK_PAREN_EXPR: return true
    if kind == CXK_UNARY_OP: return true
    if kind == CXK_BINARY_OP: return true
    if kind == CXK_COMPOUND_ASSIGN_OP: return true
    if kind == CXK_COND_OP: return true
    if kind == CXK_CSTYLE_CAST: return true
    if kind == CXK_IMPLICIT_CAST: return true
    if kind == CXK_INIT_LIST: return true
    if kind == CXK_COMPOUND_LITERAL: return true
    if kind == CXK_UNARY_EXPR: return true
    if kind == 100: return true
    false

fn ci_trans_stmt_via_ir(session: i64, cursor: i32, kind: i32, indent: i32, scope: CiScope) -> str:
    let saved_fn_var_names = g_ci_fn_var_names
    let saved_temp_cursor_len = g_ci_temp_cursors.len() as i32
    let saved_temp_id_len = g_ci_temp_ids.len() as i32
    let saved_temp_next = g_ci_temp_next
    var types = CiTypePool.new()
    var exprs = CiExprPool.new()
    var stmts = CiStmtPool.new()

    let id = stmts.lower_stmt_ir(session, cursor, exprs, types, indent, scope)
    if (id as i32) == 0:
        g_ci_fn_var_names = saved_fn_var_names
        while (g_ci_temp_cursors.len() as i32) > saved_temp_cursor_len:
            let _ = g_ci_temp_cursors.pop()
        while (g_ci_temp_ids.len() as i32) > saved_temp_id_len:
            let _ = g_ci_temp_ids.pop()
        g_ci_temp_next = saved_temp_next
        stmts.deinit()
        exprs.deinit()
        types.deinit()
        // CXK_NULL_STMT and empty-bypass map to empty string.
        return ""

    // Target depth is the caller's indent level converted to
    // spaces. For simple single-line stmt kinds (break / continue
    // / return), we print at depth 0 and strip the trailing
    // newline so the return matches the legacy's bare-string
    // convention — callers apply their own ci_indent_block. For
    // everything else, we print at the target depth so the
    // content lands at the caller's level.
    let sk = stmts.kind(id)
    var rendered = ""
    if sk == CiStmtKind.CIS_BREAK or sk == CiStmtKind.CIS_CONTINUE or sk == CiStmtKind.CIS_RETURN:
        rendered = ci_strip_trailing_newline(ci_print_stmt(stmts, exprs, types, id, 0))
    else:
        let target_depth = indent * 4
        rendered = ci_print_stmt(stmts, exprs, types, id, target_depth)
    stmts.deinit()
    exprs.deinit()
    types.deinit()
    rendered

fn ci_location_path(loc: str) -> str:
    if loc.len() == 0:
        return ""
    var last_colon = loc.len() as i32 - 1
    while last_colon >= 0 and loc.byte_at(last_colon as i64) != 58:
        last_colon = last_colon - 1
    if last_colon < 0:
        return loc
    var second_last = last_colon - 1
    while second_last >= 0 and loc.byte_at(second_last as i64) != 58:
        second_last = second_last - 1
    if second_last < 0:
        return loc
    loc.slice(0, second_last as i64)

fn ci_array_elem_type(ty: str) -> str:
    if ty.len() == 0 or ty.byte_at(0) != 91:
        return ""
    var close = 1
    while close as i64 < ty.len() and ty.byte_at(close as i64) != 93:
        close = close + 1
    if close as i64 >= ty.len():
        return ""
    ty.slice((close + 1) as i64, ty.len())


fn ci_try_eval_var_init(session: i64, idx: i32) -> str:
    ci_try_eval_var_init_for_type(session, idx, "")

fn ci_initializer_text_has_macro_reference(session: i64, text: str) -> bool:
    let s = ci_strip_c_comments(text)
    var i = 0
    let slen = s.len() as i32
    while i < slen:
        let c = s.byte_at(i as i64)
        if c == 34 or c == 39:
            let quote = c
            i = i + 1
            while i < slen:
                let inner = s.byte_at(i as i64)
                if inner == 92:
                    i = i + 2
                    continue
                if inner == quote:
                    break
                i = i + 1
            i = i + 1
            continue
        if ci_is_ident_start(c):
            var end = i + 1
            while end < slen and ci_is_ident_char(s.byte_at(end as i64)):
                end = end + 1
            let name = s.slice(i as i64, end as i64)
            let macro_value = ci_lookup_macro_value(session, name)
            if macro_value.len() > 0:
                return true
            i = end
            continue
        i = i + 1
    false

fn ci_try_eval_var_init_for_type(session: i64, idx: i32, target_type: str) -> str:
    // Evaluate a variable initializer using the actual declaration cursor,
    // not a name-based re-lookup that may bind a forward declaration.
    let var_cursor = with_cimport_decl_cursor(session, idx)
    if var_cursor >= 0:
        let cursor_type = with_ci_type_translated(session, with_ci_cursor_type(session, var_cursor))
        let init_type = if target_type.len() > 0: target_type else: cursor_type
        let init_cursor = ci_find_var_init_cursor(session, var_cursor)
        if init_cursor >= 0:
            let init_peeled = ci_peel_transparent(session, init_cursor)
            let init_kind = with_ci_cursor_kind(session, init_peeled)
            if init_kind == CXK_INIT_LIST or init_kind == CXK_COMPOUND_LITERAL:
                let init_child_count = with_ci_num_children(session, init_peeled)
                let init_src = ci_var_initializer_text_from_cursor(session, var_cursor)
                if init_src.len() > 0 and ci_initializer_text_has_macro_reference(session, init_src):
                    let from_decl_source = ci_var_init_expr_from_decl_source_for_type(session, var_cursor, init_type)
                    if from_decl_source.len() > 0:
                        return from_decl_source
                if init_child_count > 512:
                    let from_decl_source = ci_var_init_expr_from_decl_source_for_type(session, var_cursor, init_type)
                    if from_decl_source.len() > 0:
                        return from_decl_source
                let from_ast = ci_var_init_expr_for_type(session, var_cursor, CiScope.new(""), init_type)
                if from_ast.len() > 0:
                    return from_ast
                let from_decl_source = ci_var_init_expr_from_decl_source_for_type(session, var_cursor, init_type)
                if from_decl_source.len() > 0:
                    return from_decl_source
            if with_ci_eval_int_valid(session, init_cursor) != 0:
                return ci_eval_int_text(session, init_cursor)
        let expr = ci_var_init_expr_for_type(session, var_cursor, CiScope.new(""), init_type)
        if expr.len() > 0:
            return expr
    ""

fn ci_str_compare(a: str, b: str) -> i32:
    let alen = a.len() as i32
    let blen = b.len() as i32
    var i = 0
    while i < alen and i < blen:
        let ac = a.byte_at(i as i64)
        let bc = b.byte_at(i as i64)
        if ac < bc:
            return -1
        if ac > bc:
            return 1
        i = i + 1
    if alen < blen:
        return -1
    if alen > blen:
        return 1
    0

// Get source location for a declaration by matching name in AST
fn ci_get_decl_location(session: i64, name: str) -> str:
    let root = with_ci_root_cursor(session)
    let n = with_ci_num_children(session, root)
    var i = 0
    while i < n:
        let child = with_ci_child(session, root, i)
        let cname = with_ci_cursor_spelling(session, child)
        if cname == name:
            return with_ci_cursor_location(session, child)
        i = i + 1
    ""

fn ci_is_null_like_stmt(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_NULL_STMT: return true
    if kind == CXK_UNEXPOSED_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return with_ci_cursor_kind(session, with_ci_child(session, cursor, nc - 1)) == CXK_NULL_STMT
    false

// Drill through nested CaseStmt/DefaultStmt sub-statements to find the
// innermost non-case statement. Given a CaseStmt whose sub-stmt is another
// CaseStmt (the C `case A: case B: stmt;` pattern), follows the chain down
// to `stmt`. Returns -1 if there's no non-case statement to drill to.
fn ci_drill_innermost_case_substmt(session: i64, case_cursor: i32) -> i32:
    var cur = case_cursor
    while true:
        let ck = with_ci_cursor_kind(session, cur)
        let cnc = with_ci_num_children(session, cur)
        let body_idx = if ck == CXK_CASE_STMT: 1 else: 0
        if cnc <= body_idx: return -1
        let body_child = with_ci_child(session, cur, body_idx)
        let bk = with_ci_cursor_kind(session, body_child)
        if bk != CXK_CASE_STMT and bk != CXK_DEFAULT_STMT:
            return body_child
        cur = body_child
    -1

// True when a statement tail leaves the local statement by return/goto.
// This deliberately excludes break/continue because those may be local to
// wrapper constructs such as `do { ... } while (0)`.
fn ci_stmt_ends_with_nonlocal_terminator(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_RETURN_STMT or kind == CXK_GOTO_STMT:
        return true
    if kind == CXK_LABEL_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_nonlocal_terminator(session, with_ci_child(session, cursor, nc - 1))
    if kind == CXK_IF_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 3:
            return ci_stmt_ends_with_nonlocal_terminator(session, with_ci_child(session, cursor, 1)) and ci_stmt_ends_with_nonlocal_terminator(session, with_ci_child(session, cursor, 2))
        return false
    if kind == CXK_UNEXPOSED_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_nonlocal_terminator(session, with_ci_child(session, cursor, nc - 1))
    if kind == CXK_COMPOUND_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_nonlocal_terminator(session, with_ci_child(session, cursor, nc - 1))
    if kind == CXK_CASE_STMT or kind == CXK_DEFAULT_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_nonlocal_terminator(session, with_ci_child(session, cursor, nc - 1))
    if kind == CXK_DO_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_nonlocal_terminator(session, with_ci_child(session, cursor, 0))
    false

fn ci_subtree_has_break_for_current_loop(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_BREAK_STMT:
        return true
    if kind == CXK_SWITCH_STMT or kind == CXK_FOR_STMT or kind == CXK_WHILE_STMT or kind == CXK_DO_STMT:
        return false
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        if ci_subtree_has_break_for_current_loop(session, with_ci_child(session, cursor, i)):
            return true
        i = i + 1
    false

// Broader "is this case non-fallthrough" check: accepts any
// unconditional terminator (break, return, continue, goto) at
// the end of the case body. Used by the structural switch
// lowering to determine whether a case can safely become a
// distinct match arm without needing the legacy's
// prong-duplication.
fn ci_stmt_ends_with_terminator(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_BREAK_STMT or kind == CXK_RETURN_STMT or kind == CXK_CONTINUE_STMT or kind == CXK_GOTO_STMT:
        return true
    if kind == CXK_LABEL_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_terminator(session, with_ci_child(session, cursor, nc - 1))
    if kind == CXK_IF_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 3:
            return ci_stmt_ends_with_terminator(session, with_ci_child(session, cursor, 1)) and ci_stmt_ends_with_terminator(session, with_ci_child(session, cursor, 2))
        return false
    if kind == CXK_UNEXPOSED_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_terminator(session, with_ci_child(session, cursor, nc - 1))
    if kind == CXK_COMPOUND_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_terminator(session, with_ci_child(session, cursor, nc - 1))
    if kind == CXK_CASE_STMT or kind == CXK_DEFAULT_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_terminator(session, with_ci_child(session, cursor, nc - 1))
    if kind == CXK_DO_STMT:
        return ci_stmt_ends_with_nonlocal_terminator(session, cursor)
    if kind == CXK_FOR_STMT:
        let parts = ci_extract_for_parts(session, cursor)
        if parts.cond_cursor < 0 and parts.body_cursor >= 0 and not ci_subtree_has_break_for_current_loop(session, parts.body_cursor):
            return true
    false

fn ci_switch_case_is_terminated(session: i64, body_cursor: i32, case_index: i32) -> bool:
    let nc = with_ci_num_children(session, body_cursor)
    var end_idx = case_index + 1
    while end_idx < nc:
        let sib = with_ci_child(session, body_cursor, end_idx)
        let sk = with_ci_cursor_kind(session, sib)
        if sk == CXK_CASE_STMT or sk == CXK_DEFAULT_STMT:
            break
        end_idx = end_idx + 1
    if end_idx > case_index + 1:
        return ci_stmt_ends_with_terminator(session, with_ci_child(session, body_cursor, end_idx - 1))
    let child = with_ci_child(session, body_cursor, case_index)
    let inner = ci_drill_innermost_case_substmt(session, child)
    if inner >= 0:
        return ci_stmt_ends_with_terminator(session, inner)
    false

// ── Scope helpers ───────────────────────────────────────────

fn ci_scope_get_return_type(scope: CiScope) -> str:
    unsafe:
        if scope.ptr as i64 == 0:
            return ""
        (*scope.ptr).return_type

fn ci_scope_contains(scope: CiScope, name: str) -> bool:
    unsafe:
        if scope.ptr as i64 == 0:
            return false
        (*scope.ptr).names.get(name).is_some()

fn ci_scope_lookup(scope: CiScope, name: str) -> str:
    unsafe:
        if scope.ptr as i64 == 0:
            return ""
        let value = (*scope.ptr).names.get(name)
        if value.is_some():
            return value.unwrap()
    ""

fn ci_scope_mangle(scope: CiScope, name: str) -> str:
    if not ci_scope_contains(scope, name):
        return name
    var suffix = 1
    while suffix < 100:
        let candidate = f"{name}_{suffix}"
        if not ci_scope_contains(scope, candidate):
            return candidate
        suffix = suffix + 1
    name ++ "_99"

fn ci_scope_mark(scope: CiScope) -> CiScopeMark:
    unsafe:
        if scope.ptr as i64 == 0:
            return CiScopeMark { name_log_len: 0, type_log_len: 0 }
        CiScopeMark {
            name_log_len: (*scope.ptr).name_log_keys.len(),
            type_log_len: (*scope.ptr).type_log_keys.len(),
        }

fn ci_scope_note_name(scope: CiScope, key: str) -> CiScope:
    unsafe:
        if scope.ptr as i64 == 0:
            return scope
        let old = (*scope.ptr).names.get(key)
        (*scope.ptr).name_log_keys.push(key)
        if old.is_some():
            (*scope.ptr).name_log_values.push(old.unwrap())
            (*scope.ptr).name_log_had.push(1)
        else:
            (*scope.ptr).name_log_values.push("")
            (*scope.ptr).name_log_had.push(0)
    scope

fn ci_scope_note_type(scope: CiScope, key: str) -> CiScope:
    unsafe:
        if scope.ptr as i64 == 0:
            return scope
        let old = (*scope.ptr).types.get(key)
        (*scope.ptr).type_log_keys.push(key)
        if old.is_some():
            (*scope.ptr).type_log_values.push(old.unwrap())
            (*scope.ptr).type_log_had.push(1)
        else:
            (*scope.ptr).type_log_values.push("")
            (*scope.ptr).type_log_had.push(0)
    scope

fn ci_scope_restore(scope: CiScope, mark: CiScopeMark) -> CiScope:
    unsafe:
        if scope.ptr as i64 == 0:
            return scope
        while (*scope.ptr).name_log_keys.len() > mark.name_log_len:
            let idx = (*scope.ptr).name_log_keys.len() - 1
            let key = (*scope.ptr).name_log_keys.get(idx)
            let value = (*scope.ptr).name_log_values.get(idx)
            let had = (*scope.ptr).name_log_had.get(idx)
            let _ = (*scope.ptr).name_log_keys.pop()
            let _ = (*scope.ptr).name_log_values.pop()
            let _ = (*scope.ptr).name_log_had.pop()
            if had != 0:
                (*scope.ptr).names.insert(key, value)
            else:
                let _ = (*scope.ptr).names.remove(key)
        while (*scope.ptr).type_log_keys.len() > mark.type_log_len:
            let idx = (*scope.ptr).type_log_keys.len() - 1
            let key = (*scope.ptr).type_log_keys.get(idx)
            let value = (*scope.ptr).type_log_values.get(idx)
            let had = (*scope.ptr).type_log_had.get(idx)
            let _ = (*scope.ptr).type_log_keys.pop()
            let _ = (*scope.ptr).type_log_values.pop()
            let _ = (*scope.ptr).type_log_had.pop()
            if had != 0:
                (*scope.ptr).types.insert(key, value)
            else:
                let _ = (*scope.ptr).types.remove(key)
    scope

fn ci_scope_add(scope: CiScope, name: str) -> CiScope:
    if name.len() > 0:
        let _ = ci_scope_note_name(scope, name)
        unsafe:
            (*scope.ptr).names.insert(name, "")
    scope

fn ci_scope_add_mangled(scope: CiScope, original: str, mangled: str) -> CiScope:
    if original.len() == 0:
        return scope
    if original == mangled:
        let _ = ci_scope_note_name(scope, original)
        unsafe:
            (*scope.ptr).names.insert(original, "")
    else:
        let _ = ci_scope_note_name(scope, original)
        unsafe:
            (*scope.ptr).names.insert(original, mangled)
        if mangled.len() > 0:
            let _ = ci_scope_note_name(scope, mangled)
            unsafe:
                (*scope.ptr).names.insert(mangled, "")
    scope

fn ci_scope_add_type(scope: CiScope, name: str, ty: str) -> CiScope:
    if name.len() == 0 or ty.len() == 0:
        return scope
    let _ = ci_scope_note_type(scope, name)
    unsafe:
        (*scope.ptr).types.insert(name, ty)
    scope

fn ci_scope_lookup_type(scope: CiScope, name: str) -> str:
    if name.len() == 0:
        return ""
    unsafe:
        if scope.ptr as i64 == 0:
            return ""
        let value = (*scope.ptr).types.get(name)
        if value.is_some():
            return value.unwrap()
    ""

fn ci_scope_type_for_cursor(session: i64, cursor: i32, scope: CiScope) -> str:
    let peeled = ci_peel_transparent(session, cursor)
    if with_ci_cursor_kind(session, peeled) != CXK_DECL_REF:
        return ""
    let name = ci_escape_reserved(with_ci_cursor_spelling(session, peeled))
    ci_scope_lookup_type(scope, name)

fn ci_find_char(s: str, c: i32) -> i32:
    var i = 0
    while i < s.len() as i32:
        if s.byte_at(i as i64) == c:
            return i
        i = i + 1
    -1

fn ci_find_last_char(s: str, c: i32) -> i32:
    var i = s.len() as i32 - 1
    while i >= 0:
        if s.byte_at(i as i64) == c:
            return i
        i = i - 1
    -1

fn ci_realpath_cached(path: str) -> str:
    if path.len() == 0:
        return ""
    var i: i64 = 0
    while i < g_ci_realpath_cache_paths.len():
        if g_ci_realpath_cache_paths.get(i) == path:
            return g_ci_realpath_cache_values.get(i)
        i = i + 1
    let resolved = with_cimport_realpath(path)
    g_ci_realpath_cache_paths.push(path)
    g_ci_realpath_cache_values.push(resolved)
    resolved

fn ci_goto_decl_suffix(session: i64, var_cursor: i32) -> str:
    ci_goto_decl_suffix_from_location(with_ci_cursor_location(session, var_cursor), var_cursor)

fn ci_goto_decl_suffix_from_location(loc: str, fallback_id: i32) -> str:
    let last_colon = ci_find_last_char(loc, 58)
    if last_colon > 0:
        let prefix = loc.slice(0, last_colon as i64)
        let prev_colon = ci_find_last_char(prefix, 58)
        if prev_colon >= 0 and prev_colon + 1 < last_colon and last_colon + 1 < loc.len() as i32:
            let line = loc.slice((prev_colon + 1) as i64, last_colon as i64)
            let col = loc.slice((last_colon + 1) as i64, loc.len())
            if line.len() > 0 and col.len() > 0:
                return "__goto_" ++ line ++ "_" ++ col
    "__goto_" ++ i64_to_string(fallback_id as i64)

fn ci_goto_hoisted_var_name(session: i64, var_cursor: i32) -> str:
    ci_local_storage_name(ci_escape_reserved(with_ci_cursor_spelling(session, var_cursor)), var_cursor) ++ ci_goto_decl_suffix(session, var_cursor)

fn ci_goto_scope_add_decl_mappings(session: i64, cursor: i32, scope: CiScope) -> CiScope:
    if with_ci_cursor_kind(session, cursor) != CXK_DECL_STMT:
        return scope
    let nc = with_ci_num_children(session, cursor)
    var new_scope = scope
    var i = 0
    while i < nc:
        let child = with_ci_child(session, cursor, i)
        if with_ci_cursor_kind(session, child) == CXK_VAR_DECL:
            let raw_name = with_ci_cursor_spelling(session, child)
            let escaped = ci_escape_reserved(raw_name)
            let storage_name = ci_goto_hoisted_var_name(session, child)
            new_scope = ci_scope_add_mangled(new_scope, escaped, storage_name)
        i = i + 1
    new_scope

fn ci_goto_scope_after_label_stmt(session: i64, cursor: i32, scope: CiScope) -> CiScope:
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_UNEXPOSED_STMT and with_ci_num_children(session, cursor) == 1:
        return ci_goto_scope_after_label_stmt(session, with_ci_child(session, cursor, 0), scope)
    if kind != CXK_LABEL_STMT:
        return scope
    let nc = with_ci_num_children(session, cursor)
    if nc == 0:
        return scope
    let child = with_ci_child(session, cursor, 0)
    let ck = with_ci_cursor_kind(session, child)
    if ck == CXK_LABEL_STMT:
        return ci_goto_scope_after_label_stmt(session, child, scope)
    if ck == CXK_DECL_STMT:
        return ci_goto_scope_add_decl_mappings(session, child, scope)
    scope

fn ci_goto_switch_scope_after_case(session: i64, cursor: i32, scope: CiScope):
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)
    var next_scope = scope
    if kind == CXK_CASE_STMT:
        var i = 1
        while i < nc:
            let case_body = with_ci_child(session, cursor, i)
            let cbk = with_ci_cursor_kind(session, case_body)
            if cbk == CXK_CASE_STMT or cbk == CXK_DEFAULT_STMT:
                ci_goto_switch_scope_after_case(session, case_body, next_scope)
            else if cbk == CXK_DECL_STMT:
                next_scope = ci_goto_scope_add_decl_mappings(session, case_body, next_scope)
            else if cbk == CXK_LABEL_STMT:
                next_scope = ci_goto_scope_after_label_stmt(session, case_body, next_scope)
            i = i + 1
        return
    if kind == CXK_DEFAULT_STMT:
        var i = 0
        while i < nc:
            let default_body = with_ci_child(session, cursor, i)
            let dbk = with_ci_cursor_kind(session, default_body)
            if dbk == CXK_CASE_STMT or dbk == CXK_DEFAULT_STMT:
                ci_goto_switch_scope_after_case(session, default_body, next_scope)
            else if dbk == CXK_DECL_STMT:
                next_scope = ci_goto_scope_add_decl_mappings(session, default_body, next_scope)
            else if dbk == CXK_LABEL_STMT:
                next_scope = ci_goto_scope_after_label_stmt(session, default_body, next_scope)
            i = i + 1
        return

// Structural counterpart of ci_lower_decl_stmt. Builds a
// CIS_VAR_DECL for each VAR_DECL child, combining multiple
// decls into a CIS_BLOCK when needed. Returns 0 as stmt_id if
// the decl lowered to nothing. For `hoisted=true` (goto body
// interior), emits CIS_ASSIGN to an already-hoisted variable
// instead of a fresh CIS_VAR_DECL.
//
// Init expressions are lowered structurally via
// ci_lower_expr_ir and ci_lower_value_expr_ir. Type is built via
// ci_type_from_libclang.
fn CiStmtPool.lower_decl_stmt_structural(self: CiStmtPool, session: i64, cursor: i32, scope: CiScope, hoisted: bool, exprs: CiExprPool, types: CiTypePool) -> CiDeclLoweringIR:
    let nc = with_ci_num_children(session, cursor)
    var new_scope = scope
    var child_stmt_ids: Vec[i32] = Vec.new()
    var i = 0
    while i < nc:
        let child = with_ci_child(session, cursor, i)
        if with_ci_cursor_kind(session, child) == CXK_VAR_DECL:
            let raw_name = with_ci_cursor_spelling(session, child)
            let escaped = ci_escape_reserved(raw_name)
            let vty = with_ci_cursor_type(session, child)
            var storage_name = escaped
            if hoisted:
                storage_name = ci_goto_hoisted_var_name(session, child)
                new_scope = ci_scope_add_mangled(new_scope, escaped, storage_name)
                ci_fn_var_names_register(storage_name)
            else:
                let base_name = ci_local_storage_name(escaped, child)
                var mangled = ci_scope_mangle(new_scope, base_name)
                if mangled == base_name and ci_fn_var_names_contains(base_name):
                    mangled = ci_fn_var_names_unique(base_name)
                storage_name = mangled
                new_scope = ci_scope_add_mangled(new_scope, escaped, storage_name)
                ci_fn_var_names_register(storage_name)
            let init_cursor = ci_find_var_init_cursor(session, child)
            var init_id: CiExprId = 0 as CiExprId
            var init_setup_id: CiStmtId = 0 as CiStmtId
            if init_cursor >= 0:
                let init_src = ci_var_initializer_text_from_cursor(session, child)
                let init_has_macro = init_src.len() > 0 and ci_initializer_text_has_macro_reference(session, init_src)
                var source_init_expr = init_src
                if init_has_macro:
                    let preprocessed_init = ci_var_init_expr_from_preprocessed_cursor_for_type(session, child, with_ci_type_translated(session, vty))
                    if preprocessed_init.len() > 0:
                        source_init_expr = preprocessed_init
                if ci_is_concatenated_string(source_init_expr):
                    let str_idx = exprs.add_string(ci_concat_strings(source_init_expr))
                    init_id = exprs.add(CiExprKind.CIE_STRING_LIT, str_idx, 0, 0, 0 as CiTypeId)
                else if ci_is_string_literal(source_init_expr):
                    let str_idx = exprs.add_string(source_init_expr)
                    init_id = exprs.add(CiExprKind.CIE_STRING_LIT, str_idx, 0, 0, 0 as CiTypeId)
                if (init_id as i32) == 0 and init_has_macro:
                    let expanded_init = ci_expand_string_macro_sequence(session, init_src)
                    if expanded_init.len() > 0:
                        let str_idx = exprs.add_string(expanded_init)
                        init_id = exprs.add(CiExprKind.CIE_STRING_LIT, str_idx, 0, 0, 0 as CiTypeId)
                if (init_id as i32) == 0:
                    let lowered_init = self.lower_value_expr_ir(session, init_cursor, exprs, types, new_scope)
                    if not ci_value_ir_valid(lowered_init):
                        return CiDeclLoweringIR {
                            updated_scope: scope,
                            stmt_id: 0 as CiStmtId,
                        }
                    init_setup_id = lowered_init.setup_stmt
                    init_id = lowered_init.value_expr
            // Build structural CiTypeId for the var's libclang type.
            let vty_id = types.type_from_libclang(session, vty)
            if (vty_id as i32) == 0:
                return CiDeclLoweringIR {
                    updated_scope: scope,
                    stmt_id: 0 as CiStmtId,
                }
            // Var-type-directed init adjustments (matches the
            // legacy ci_var_init_expr post-processing for pointer
            // vars):
            //   var is *T, init is array T[N] → (&init[0] as *T)
            //   var is *T, init is *U (U != T) → (init as *T)
            if (init_id as i32) != 0 and init_cursor >= 0:
                if types.kind(vty_id) == CiTypeKind.CT_POINTER:
                    let init_peeled = ci_peel_transparent(session, init_cursor)
                    let init_peeled_kind = with_ci_cursor_kind(session, init_peeled)
                    if init_peeled_kind != CXK_STRING_LITERAL and ci_cursor_is_array_type(session, init_peeled):
                        let zero_s = exprs.add_string("0")
                        let zero_e = exprs.int_lit(zero_s, 0 as CiTypeId)
                        let idx_e = exprs.add(CiExprKind.CIE_INDEX, init_id as i32, zero_e as i32, 0, 0 as CiTypeId)
                        let addr_e = exprs.add(CiExprKind.CIE_ADDR_OF, idx_e as i32, 0, 0, 0 as CiTypeId)
                        init_id = exprs.cast(vty_id, addr_e)
                    else if ci_cursor_type_is_pointerish(session, init_cursor):
                        let init_peeled_ptr = ci_peel_transparent(session, init_cursor)
                        if ci_cursor_type_is_pointerish(session, init_peeled_ptr):
                            let init_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, init_peeled_ptr))
                            let vty_str = with_ci_type_translated(session, vty)
                            if init_ty_str.len() > 0 and init_ty_str != vty_str:
                                init_id = exprs.cast(vty_id, init_id)
                    let coerced_init = exprs.coerce_value_expr_for_target(session, vty_id, init_cursor, init_id, types)
                    if (coerced_init as i32) == 0:
                        return CiDeclLoweringIR {
                            updated_scope: scope,
                            stmt_id: 0 as CiStmtId,
                        }
                    init_id = coerced_init
            let name_idx = self.add_string(storage_name)
            if hoisted:
                // Emit `storage_name = init` as a CIS_ASSIGN.
                if (init_id as i32) != 0:
                    let lhs_idx = exprs.add_string(storage_name)
                    let lhs_id = exprs.ident(lhs_idx, 0 as CiTypeId)
                    let assign_id = self.assign(lhs_id, init_id)
                    child_stmt_ids.push((self.merge_ir( init_setup_id, assign_id)) as i32)
            else:
                if (init_setup_id as i32) == 0:
                    // Non-hoisted simple init: CIS_VAR_DECL with is_mut=1.
                    let decl_id = self.var_decl(name_idx, vty_id, init_id, 1)
                    child_stmt_ids.push(decl_id as i32)
                else:
                    let decl_id = self.var_decl(name_idx, vty_id, 0 as CiExprId, 1)
                    let lhs_idx = exprs.add_string(storage_name)
                    let lhs_id = exprs.ident(lhs_idx, vty_id)
                    let assign_id = self.assign(lhs_id, init_id)
                    child_stmt_ids.push((self.merge3_ir( decl_id, init_setup_id, assign_id)) as i32)
        i = i + 1

    let count = child_stmt_ids.len() as i32
    var stmt_id: CiStmtId = 0 as CiStmtId
    if count == 1:
        stmt_id = (child_stmt_ids.get(0)) as CiStmtId
    else if count > 1:
        let extra_start = self.extra_len()
        var cj: i64 = 0
        while cj < child_stmt_ids.len():
            let _ = self.add_extra(child_stmt_ids.get(cj))
            cj = cj + 1
        stmt_id = self.block(extra_start, count)
    CiDeclLoweringIR {
        updated_scope: new_scope,
        stmt_id,
    }

fn ci_indent_str(level: i32) -> str:
    if level <= 0: return ""
    if level == 1: return "    "
    if level == 2: return "        "
    if level == 3: return "            "
    if level == 4: return "                "
    var result = ""
    var i = 0
    while i < level:
        result = result ++ "    "
        i = i + 1
    result

// ── Function body translator ────────────────────────────────
// Tries to translate a static inline function body using AST walking.
// Returns "" on failure (caller falls back to comptime_error stub).

fn ci_try_translate_fn_body(session: i64, decl_idx: i32) -> str:
    ci_clear_bail_location()
    // B9: fresh per-function temp counter. This path is called
    // from ci_translate_function's static-inline branch — which
    // already resets — but also from other call sites for header
    // body translation, so reset here too.
    ci_temp_reset()
    // Use the new cursor-based API to find the function body.
    // Match by NAME first (reliable), fall back to index matching.
    let root = with_ci_root_cursor(session)
    let n = with_ci_num_children(session, root)
    let target_name = with_cimport_decl_name(session, decl_idx)

    // Name-based search (most reliable — handles system header functions correctly)
    var found_cursor = -1
    var i = 0
    while i < n:
        let child = with_ci_child(session, root, i)
        let ck = with_ci_cursor_kind(session, child)
        if ck == CK_FUNCTION:
            let cname = with_ci_cursor_spelling(session, child)
            if cname == target_name:
                // Prefer definitions over declarations
                if with_ci_cursor_is_definition(session, child) != 0:
                    found_cursor = child
                    break
                if found_cursor < 0:
                    found_cursor = child
        i = i + 1

    if found_cursor < 0:
        return ""

    // Check if this cursor is a definition (has a body)
    if with_ci_cursor_is_definition(session, found_cursor) == 0:
        return ""

    // Find the CompoundStmt child (the function body)
    let nc = with_ci_num_children(session, found_cursor)
    var body_cursor = -1
    i = 0
    while i < nc:
        let child = with_ci_child(session, found_cursor, i)
        if with_ci_cursor_kind(session, child) == CXK_COMPOUND_STMT:
            body_cursor = child
            break
        i = i + 1

    if body_cursor < 0:
        return ""

    // Build initial scope from parameter names + return type.
    // Use cursor API for param names (old API returns "" for many functions).
    let ret_type = with_cimport_fn_return_type_translated(session, decl_idx)
    var init_scope = CiScope.new(ret_type)

    // Get param names from cursor API (more reliable) and map each
    // original C parameter name to generated storage. Generated
    // parameter names avoid collisions with top-level names from
    // other migrated modules that are imported into the same build.
    var param_rebinds = ""
    let fn_nc = with_ci_num_children(session, found_cursor)
    var cpi = 0
    var param_index = 0
    while cpi < fn_nc:
        let child = with_ci_child(session, found_cursor, cpi)
        if with_ci_cursor_kind(session, child) == 10:  // CXCursor_ParmDecl
            let cpname = ci_escape_reserved(with_ci_cursor_spelling(session, child))
            if cpname.len() > 0:
                let sig_name = ci_param_signature_name(cpname, param_index)
                var storage_name = sig_name
                if ci_body_assigns_to(session, body_cursor, cpname):
                    storage_name = ci_param_local_name(cpname, param_index)
                    param_rebinds = param_rebinds ++ f"    var {storage_name} = {sig_name}\n"
                init_scope = ci_scope_add_mangled(init_scope, cpname, storage_name)
                let raw_ptype = with_cimport_fn_param_type_translated(session, decl_idx, param_index)
                let ptype = ci_pointer_type_explicit_mut(raw_ptype)
                init_scope = ci_scope_add_type(init_scope, cpname, ptype)
            param_index = param_index + 1
        cpi = cpi + 1

    // Goto-containing bodies are lowered by ci_lower_stmt_ir's
    // CXK_COMPOUND_STMT + ci_has_goto check, which builds a
    // CFG and emits stackified labeled blocks/loops.
    let body = ci_trans_stmt_via_ir(session, body_cursor, with_ci_cursor_kind(session, body_cursor), 1, init_scope)
    if body.len() == 0:
        return ""

    param_rebinds ++ body

// ── String helpers ──────────────────────────────────────────

fn ci_trim(s: str) -> str:
    var start = 0
    var end = s.len() as i32
    while start < end and ci_is_space(s.byte_at(start as i64)):
        start = start + 1
    while end > start and ci_is_space(s.byte_at((end - 1) as i64)):
        end = end - 1
    s.slice(start as i64, end as i64)

fn ci_is_space(c: i32) -> bool:
    c == 32 or c == 9 or c == 10 or c == 13

fn ci_starts_with(s: str, prefix: str) -> bool:
    ci_str_matches_at(s, 0, prefix)

fn ci_str_matches_at(text: str, pos: i32, needle: str) -> bool:
    if pos < 0:
        return false
    let start = pos as i64
    let nlen = needle.len()
    if start + nlen > text.len():
        return false
    var i: i64 = 0
    while i < nlen:
        if text.byte_at(start + i) != needle.byte_at(i):
            return false
        i = i + 1
    true

fn ci_str_contains(text: str, needle: str) -> bool:
    if needle.len() == 0:
        return true
    if needle.len() > text.len():
        return false
    let limit = text.len() - needle.len()
    for i in 0..limit as i32 + 1:
        if ci_str_matches_at(text, i, needle):
            return true
    false

// Replace field name `old_name` with `new_name` in last comma-separated field of a field_str
fn ci_str_replace_last_field(field_str: str, old_name: str, new_name: str) -> str:
    // Find last comma at depth 0
    var last_comma = -1
    var i = 0
    while i < field_str.len() as i32:
        if field_str.byte_at(i as i64) == 44:
            last_comma = i
        i = i + 1
    let start = if last_comma >= 0: last_comma + 1 else: 0
    let prefix = field_str.slice(0, start as i64)
    let last_field = field_str.slice(start as i64, field_str.len())
    // Replace old_name with new_name in last field segment
    let replaced = ci_str_replace(last_field, old_name, new_name)
    prefix ++ replaced

fn ci_str_replace(text: str, needle: str, replacement: str) -> str:
    if needle.len() == 0:
        return text
    if needle.len() > text.len():
        return text
    var result = ""
    var i = 0
    let limit = text.len() as i32
    while i < limit:
        if i as i64 + needle.len() <= text.len():
            if text.slice(i as i64, i as i64 + needle.len()) == needle:
                result = result ++ replacement
                i = i + needle.len() as i32
                continue
        result = result ++ text.slice(i as i64, i as i64 + 1)
        i = i + 1
    result

fn ci_indent_block(text: str, indent: i32) -> str:
    if text.len() == 0:
        return ""
    let prefix = ci_indent_str(indent)
    // Collect parts then join: avoids O(n²) string concatenation in the loop
    var parts: Vec[str] = Vec.new()
    var start = 0
    let len = text.len() as i32
    while start < len:
        var end = start
        while end < len and text.byte_at(end as i64) != 10:
            end = end + 1
        if end > start:
            parts.push(prefix)
        parts.push(text.slice(start as i64, end as i64))
        parts.push("\n")
        start = end + 1
    parts.join("")

// Check if a macro value only references other blank macros.
// Check if a macro value only references other blank macros (multi-token aware).
fn ci_is_blank_macro_ref(value: str, blank_macros: str) -> bool:
    let trimmed = ci_trim(value)
    if trimmed.len() == 0:
        return true
    var pos = 0
    let slen = trimmed.len() as i32
    var found_any = false
    while pos < slen:
        while pos < slen and (trimmed.byte_at(pos as i64) == 32 or trimmed.byte_at(pos as i64) == 9):
            pos = pos + 1
        if pos >= slen:
            break
        let tok_start = pos
        while pos < slen:
            let c = trimmed.byte_at(pos as i64)
            if not ((c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95 or (pos > tok_start and c >= 48 and c <= 57)):
                break
            pos = pos + 1
        if pos == tok_start:
            return false
        let tok = trimmed.slice(tok_start as i64, pos as i64)
        if not ci_str_contains(blank_macros, "|" ++ tok ++ "|"):
            return false
        found_any = true
    found_any

fn ci_eval_int_text(session: i64, cursor: i32) -> str:
    let val = with_ci_eval_int_value(session, cursor)
    if val < 0 and with_ci_eval_int_is_unsigned(session, cursor) != 0:
        let ty = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
        if ty.len() > 0:
            return "((0 as " ++ ty ++ ") -% " ++ i64_to_string(0 - val) ++ ")"
        return "(0 -% " ++ i64_to_string(0 - val) ++ ")"
    i64_to_string(val)

fn ci_is_int_literal(s: str) -> bool:
    if s.len() == 0:
        return false
    var start = 0
    // Allow leading minus
    if s.byte_at(0) == 45:
        start = 1
    if start as i64 >= s.len():
        return false
    // Check for hex prefix
    if s.len() as i32 - start >= 2:
        if s.byte_at(start as i64) == 48:
            let next = s.byte_at(start as i64 + 1)
            if next == 120 or next == 88:
                for i in start + 2..s.len() as i32:
                    let c = s.byte_at(i as i64)
                    if not ((c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)):
                        if c == 76 or c == 85 or c == 108 or c == 117:
                            continue
                        return false
                return true
    // Decimal digits
    for i in start..s.len() as i32:
        let c = s.byte_at(i as i64)
        if not (c >= 48 and c <= 57):
            if c == 76 or c == 85 or c == 108 or c == 117:
                continue
            return false
    true

fn ci_strip_int_suffix(s: str) -> str:
    var end = s.len() as i32
    while end > 0:
        let c = s.byte_at((end - 1) as i64)
        if c == 76 or c == 85 or c == 108 or c == 117:
            end = end - 1
        else:
            break
    s.slice(0, end as i64)

fn ci_strip_parens(s: str) -> str:
    var result = s
    while result.len() >= 2 and result.byte_at(0) == 40 and result.byte_at(result.len() - 1) == 41:
        // Verify the outer parens actually match (not just first/last chars)
        let match_pos = ci_find_matching_paren(result, 0)
        if match_pos != result.len() as i32 - 1:
            break
        result = result.slice(1, result.len() - 1)
    result

fn ci_is_float_literal(s: str) -> bool:
    if s.len() == 0:
        return false
    var start = 0
    if s.byte_at(0) == 45:
        start = 1
    if start as i64 >= s.len():
        return false
    let first = s.byte_at(start as i64)
    if not ((first >= 48 and first <= 57) or first == 46):
        return false
    // Hex float: 0x...p... (C99)
    if start as i64 + 1 < s.len() and first == 48:
        let second = s.byte_at((start + 1) as i64)
        if second == 120 or second == 88:
            for hi in (start + 2)..s.len() as i32:
                let hc = s.byte_at(hi as i64)
                if hc == 112 or hc == 80:
                    return true
            return false
    // Decimal float: scan for decimal point or e/E exponent
    var has_dot = false
    var has_exp = false
    for i in start..s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 46:
            has_dot = true
        else if c == 101 or c == 69:  // e, E
            has_exp = true
        else if c == 43 or c == 45:  // +, - in exponent
            continue
        else if c >= 48 and c <= 57:
            continue
        else if c == 102 or c == 70 or c == 108 or c == 76:  // f, F, l, L suffix
            continue
        else:
            return false
    has_dot or has_exp

fn ci_int_type_from_suffix(s: str) -> str:
    // Detect integer literal suffix to determine C type
    var end = s.len() as i32
    // Collect suffix chars (backwards)
    var has_u = false
    var l_count = 0
    var i = end - 1
    while i >= 0:
        let c = s.byte_at(i as i64)
        if c == 85 or c == 117:  // U, u
            has_u = true
            i = i - 1
        else if c == 76 or c == 108:  // L, l
            l_count = l_count + 1
            i = i - 1
        else:
            break
    if has_u:
        if l_count >= 2: return "c_ulonglong"
        if l_count == 1: return "c_ulong"
        return "c_uint"
    if l_count >= 2: return "c_longlong"
    if l_count == 1: return "c_long"
    "c_int"

fn ci_float_type_from_suffix(s: str) -> str:
    if s.len() == 0:
        return "f64"
    let last = s.byte_at(s.len() - 1)
    if last == 102 or last == 70:  // f, F
        return "f32"
    if last == 108 or last == 76:  // l, L
        return "c_longdouble"
    "f64"

fn ci_strip_float_suffix(s: str) -> str:
    // Hex float (0x...p...) — convert to decimal
    if s.len() > 2 and s.byte_at(0) == 48 and (s.byte_at(1) == 120 or s.byte_at(1) == 88):
        return with_cimport_hex_float_to_decimal(s)
    if s.len() > 3 and s.byte_at(0) == 45 and s.byte_at(1) == 48 and (s.byte_at(2) == 120 or s.byte_at(2) == 88):
        return with_cimport_hex_float_to_decimal(s)
    var end = s.len() as i32
    while end > 0:
        let c = s.byte_at((end - 1) as i64)
        if c == 102 or c == 70 or c == 108 or c == 76:  // f, F, l, L
            end = end - 1
        else:
            break
    s.slice(0, end as i64)

fn ci_i64_to_hex(val: i64) -> str:
    let hex_chars = "0123456789abcdef"
    var result = ""
    var v = val
    if v == 0: return "0x0"
    while v > 0:
        let digit = (v % 16) as i32
        result = hex_chars.slice(digit as i64, (digit + 1) as i64) ++ result
        v = v / 16
    "0x" ++ result

fn ci_is_integer_string(s: str) -> bool:
    if s.len() == 0: return false
    var i = 0
    // Allow hex prefix
    if s.len() as i32 > 2 and s.byte_at(0) == 48 and (s.byte_at(1) == 120 or s.byte_at(1) == 88):
        i = 2
    while i as i64 < s.len():
        let c = s.byte_at(i as i64)
        if c < 48 or c > 57:
            if c >= 97 and c <= 102: i = i + 1  // a-f for hex
            else if c >= 65 and c <= 70: i = i + 1  // A-F for hex
            else: return false
        else:
            i = i + 1
    true

fn ci_is_string_literal(s: str) -> bool:
    let t = ci_trim(s)
    if t.len() < 2:
        return false
    var i = 0
    if ci_starts_with(t, "u8\""):
        i = 2
    else if t.byte_at(0) == 76 or t.byte_at(0) == 85 or t.byte_at(0) == 117:  // L, U, u
        i = 1
    if i as i64 >= t.len() or t.byte_at(i as i64) != 34:
        return false
    i = i + 1
    while i as i64 < t.len():
        let c = t.byte_at(i as i64)
        if c == 92:
            i = i + 2
            continue
        if c == 34:
            return i as i64 == t.len() - 1
        i = i + 1
    false

// ── Character literal support ───────────────────────────────

fn ci_is_char_literal(s: str) -> bool:
    if s.len() < 3:
        return false
    if s.byte_at(0) != 39 or s.byte_at(s.len() - 1) != 39:
        return false
    // 'X' or '\X'
    true

fn ci_char_to_int(s: str) -> str:
    // Input is like 'X' or '\n' — extract the char value
    if s.len() < 3:
        return ""
    if s.byte_at(1) == 92:
        // Escape sequence
        if s.len() < 4:
            return ""
        let esc = s.byte_at(2)
        if esc == 120:
            var value: i64 = 0
            var i = 3
            var digits = 0
            while i < s.len() as i32 - 1:
                let d = s.byte_at(i as i64)
                if not ci_is_hex_digit(d):
                    break
                value = value * 16 + ci_hex_digit_value(d) as i64
                digits = digits + 1
                i = i + 1
            if digits > 0:
                return i64_to_string(value)
            return ""
        if esc >= 48 and esc <= 55:
            var value: i64 = 0
            var i = 2
            var digits = 0
            while i < s.len() as i32 - 1 and digits < 3:
                let d = s.byte_at(i as i64)
                if d < 48 or d > 55:
                    break
                value = value * 8 + (d - 48) as i64
                digits = digits + 1
                i = i + 1
            return i64_to_string(value)
        if esc == 110: return "10"    // \n
        if esc == 116: return "9"     // \t
        if esc == 48: return "0"      // \0
        if esc == 92: return "92"     // \\
        if esc == 39: return "39"     // \'
        if esc == 114: return "13"    // \r
        if esc == 97: return "7"      // \a
        if esc == 98: return "8"      // \b
        if esc == 102: return "12"    // \f
        if esc == 118: return "11"    // \v
        return ""
    // Plain character
    f"{s.byte_at(1)}"

// ── String concatenation support ────────────────────────────

fn ci_strip_c_comments(s: str) -> str:
    var parts: Vec[str] = Vec.new()
    var i = 0
    var segment_start = 0
    let slen = s.len() as i32
    while i < slen:
        let c = s.byte_at(i as i64)
        if c == 47 and i + 1 < slen:
            let next = s.byte_at((i + 1) as i64)
            if next == 42:
                if i > segment_start:
                    parts.push(s.slice(segment_start as i64, i as i64))
                parts.push(" ")
                i = i + 2
                while i + 1 < slen:
                    if s.byte_at(i as i64) == 42 and s.byte_at((i + 1) as i64) == 47:
                        i = i + 2
                        break
                    i = i + 1
                segment_start = i
                continue
            if next == 47:
                if i > segment_start:
                    parts.push(s.slice(segment_start as i64, i as i64))
                parts.push(" ")
                i = i + 2
                while i < slen and s.byte_at(i as i64) != 10:
                    i = i + 1
                segment_start = i
                continue
        if c == 34 or c == 39:
            let quote = c
            i = i + 1
            while i < slen:
                let inner = s.byte_at(i as i64)
                if inner == 92:
                    i = i + 2
                    continue
                if inner == quote:
                    i = i + 1
                    break
                i = i + 1
            continue
        i = i + 1
    if slen > segment_start:
        parts.push(s.slice(segment_start as i64, slen as i64))
    parts.join("")

fn ci_find_string_literal_end(s: str, start: i32) -> i32:
    let slen = s.len() as i32
    var i = start
    if i + 2 < slen and s.byte_at(i as i64) == 117 and s.byte_at((i + 1) as i64) == 56 and s.byte_at((i + 2) as i64) == 34:
        i = i + 2
    else if i + 1 < slen:
        let c = s.byte_at(i as i64)
        if (c == 76 or c == 85 or c == 117) and s.byte_at((i + 1) as i64) == 34:
            i = i + 1
    if i >= slen or s.byte_at(i as i64) != 34:
        return -1
    i = i + 1
    while i < slen:
        let c = s.byte_at(i as i64)
        if c == 92:
            i = i + 2
            continue
        if c == 34:
            return i + 1
        i = i + 1
    -1

fn ci_is_concatenated_string(s: str) -> bool:
    // Detect adjacent string literals: "foo" "bar"
    let t = ci_trim(s)
    if t.len() < 5:
        return false
    if t.byte_at(0) != 34:
        return false
    // Find closing quote of first string, then check for another opening quote
    var i = 1
    while i as i64 < t.len():
        let c = t.byte_at(i as i64)
        if c == 92:
            i = i + 2
            continue
        if c == 34:
            // Found end of first string — look for another
            var j = i + 1
            while j as i64 < t.len() and ci_is_space(t.byte_at(j as i64)):
                j = j + 1
            if j as i64 < t.len() and t.byte_at(j as i64) == 34:
                return true
            return false
        i = i + 1
    false

fn ci_byte_to_hex_escape(value: i32) -> str:
    let hex = "0123456789abcdef"
    let hi = (value >> 4) & 15
    let lo = value & 15
    "\\x" ++ hex.slice(hi as i64, (hi + 1) as i64) ++ hex.slice(lo as i64, (lo + 1) as i64)

fn ci_quote_evaluated_c_string(s: str) -> str:
    var result = "\""
    var i = 0
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 34:
            result = result ++ "\\\""
        else if c == 92:
            result = result ++ "\\\\"
        else if c == 10:
            result = result ++ "\\n"
        else if c == 9:
            result = result ++ "\\t"
        else if c == 13:
            result = result ++ "\\r"
        else if c >= 32 and c <= 126:
            result = result ++ s.slice(i as i64, (i + 1) as i64)
        else:
            result = result ++ ci_byte_to_hex_escape(c)
        i = i + 1
    result ++ "\""

fn ci_is_byte_array_element_type(elem_ty: str) -> bool:
    let t = ci_trim(elem_ty)
    t == "u8" or t == "i8" or t == "c_char" or t == "c_schar" or t == "c_uchar"

fn ci_byte_array_literal_value(byte: i32, elem_ty: str) -> str:
    let t = ci_trim(elem_ty)
    let b = byte & 255
    if (t == "i8" or t == "c_char" or t == "c_schar") and b >= 128:
        return i64_to_string((b - 256) as i64)
    i64_to_string(b as i64)

fn ci_is_hex_digit(c: i32) -> bool:
    (c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)

fn ci_hex_digit_value(c: i32) -> i32:
    if c >= 48 and c <= 57: return c - 48
    if c >= 65 and c <= 70: return c - 55
    if c >= 97 and c <= 102: return c - 87
    0

fn ci_render_string_literal_as_byte_array(value: str, ty: str) -> str:
    let elem_ty = ci_array_element_type(ty)
    if not ci_is_byte_array_element_type(elem_ty):
        return ""
    let target_len = ci_array_length_from_type(ty)
    var bytes: Vec[i32] = Vec.new()
    var i = 0
    let slen = value.len() as i32
    var saw_literal = false
    while i < slen:
        let c = value.byte_at(i as i64)
        if ci_is_space(c):
            i = i + 1
            continue
        var quote_pos = i
        if i + 2 < slen and value.slice(i as i64, (i + 2) as i64) == "u8":
            quote_pos = i + 2
        else if c == 76 or c == 85 or c == 117:
            quote_pos = i + 1
        if quote_pos >= slen or value.byte_at(quote_pos as i64) != 34:
            return ""
        saw_literal = true
        i = quote_pos + 1
        while i < slen:
            let cc = value.byte_at(i as i64)
            if cc == 34:
                i = i + 1
                break
            if cc != 92:
                bytes.push(cc & 255)
                i = i + 1
                continue
            if i + 1 >= slen:
                return ""
            let esc = value.byte_at((i + 1) as i64)
            if esc >= 48 and esc <= 55:
                var byte = 0
                var j = i + 1
                var digits = 0
                while j < slen and digits < 3:
                    let d = value.byte_at(j as i64)
                    if d < 48 or d > 55:
                        break
                    byte = byte * 8 + (d - 48)
                    digits = digits + 1
                    j = j + 1
                bytes.push(byte & 255)
                i = j
                continue
            if esc == 120 or esc == 88:
                var byte = 0
                var j = i + 2
                var digits = 0
                while j < slen and ci_is_hex_digit(value.byte_at(j as i64)):
                    byte = byte * 16 + ci_hex_digit_value(value.byte_at(j as i64))
                    digits = digits + 1
                    j = j + 1
                if digits == 0:
                    return ""
                bytes.push(byte & 255)
                i = j
                continue
            if esc == 110: bytes.push(10)
            else if esc == 116: bytes.push(9)
            else if esc == 114: bytes.push(13)
            else if esc == 97: bytes.push(7)
            else if esc == 98: bytes.push(8)
            else if esc == 102: bytes.push(12)
            else if esc == 118: bytes.push(11)
            else if esc == 92: bytes.push(92)
            else if esc == 34: bytes.push(34)
            else if esc == 39: bytes.push(39)
            else if esc == 63: bytes.push(63)
            else: bytes.push(esc & 255)
            i = i + 2
    if not saw_literal:
        return ""
    bytes.push(0)
    if target_len >= 0:
        if bytes.len() as i32 > target_len:
            if bytes.len() as i32 == target_len + 1 and bytes.get((bytes.len() - 1) as i64) == 0:
                let _ = bytes.pop()
            else:
                return ""
        while bytes.len() as i32 < target_len:
            bytes.push(0)
    var parts: Vec[str] = Vec.new()
    parts.push("[")
    var bi = 0
    while bi < bytes.len() as i32:
        if bi > 0:
            parts.push(", ")
        parts.push(ci_byte_array_literal_value(bytes.get(bi as i64), elem_ty))
        bi = bi + 1
    parts.push("]")
    parts.join("")

fn ci_is_byte_array_type(ty: str) -> bool:
    ty.len() > 0 and ty.byte_at(0) == 91 and ci_is_byte_array_element_type(ci_array_element_type(ty))

fn ci_concat_strings(s: str) -> str:
    // Concatenate adjacent string literals "foo" "bar" -> "foobar"
    var result = "\""
    var i = 0
    let slen = s.len() as i32
    while i < slen:
        let c = s.byte_at(i as i64)
        if c == 34:
            // Start of a string literal — copy contents
            i = i + 1
            while i < slen:
                let cc = s.byte_at(i as i64)
                if cc == 92:
                    if i + 1 >= slen:
                        result = result ++ "\\"
                        i = i + 1
                        continue
                    let next = s.byte_at((i + 1) as i64)
                    if next >= 48 and next <= 55:
                        var value = 0
                        var j = i + 1
                        var digits = 0
                        while j < slen and digits < 3:
                            let d = s.byte_at(j as i64)
                            if d < 48 or d > 55:
                                break
                            value = value * 8 + (d as i32 - 48)
                            digits = digits + 1
                            j = j + 1
                        if value == 0 and digits == 1:
                            result = result ++ "\\0"
                        else:
                            result = result ++ ci_byte_to_hex_escape(value & 255)
                        i = j
                        continue
                    if next == 120 or next == 88:
                        var value = 0
                        var j = i + 2
                        while j < slen:
                            let d = s.byte_at(j as i64)
                            if d >= 48 and d <= 57:
                                value = value * 16 + (d as i32 - 48)
                            else if d >= 65 and d <= 70:
                                value = value * 16 + (d as i32 - 55)
                            else if d >= 97 and d <= 102:
                                value = value * 16 + (d as i32 - 87)
                            else:
                                break
                            j = j + 1
                        result = result ++ ci_byte_to_hex_escape(value & 255)
                        i = j
                        continue
                    if next == 97:
                        result = result ++ "\\x07"
                        i = i + 2
                        continue
                    if next == 98:
                        result = result ++ "\\x08"
                        i = i + 2
                        continue
                    if next == 102:
                        result = result ++ "\\x0c"
                        i = i + 2
                        continue
                    if next == 118:
                        result = result ++ "\\x0b"
                        i = i + 2
                        continue
                    result = result ++ s.slice(i as i64, (i + 2) as i64)
                    i = i + 2
                    continue
                if cc == 34:
                    // End of this string segment
                    i = i + 1
                    break
                result = result ++ s.slice(i as i64, (i + 1) as i64)
                i = i + 1
        else:
            // Whitespace between string segments
            i = i + 1
    result ++ "\""

fn ci_lookup_macro_value(session: i64, name: str) -> str:
    if name.len() == 0:
        return ""
    let needle = "|" ++ name ++ "="
    let pos = ci_find_str(g_migrate_macro_values, needle)
    if pos >= 0:
        let start = pos + needle.len() as i32
        var end = start
        while end < g_migrate_macro_values.len() as i32 and g_migrate_macro_values.byte_at(end as i64) != 124:
            end = end + 1
        return g_migrate_macro_values.slice(start as i64, end as i64)
    if ci_macro_miss_contains(name):
        return ""
    let macro_session = if g_migrate_macro_session != 0: g_migrate_macro_session else: session
    let count = with_cimport_macro_count(macro_session)
    var i = 0
    while i < count:
        if with_cimport_macro_is_fn_like(macro_session, i) == 0:
            if with_cimport_macro_name(macro_session, i) == name:
                let value = with_cimport_macro_value(macro_session, i)
                if value.len() > 0 and value != name and not ci_str_contains(value, "|"):
                    g_migrate_macro_values = g_migrate_macro_values ++ needle ++ value
                return value
        i = i + 1
    g_migrate_macro_miss_names.push(ci_ir_owned_text(name))
    ""

fn ci_macro_miss_contains(name: str) -> bool:
    var i: i64 = 0
    while i < g_migrate_macro_miss_names.len():
        if g_migrate_macro_miss_names.get(i) == name:
            return true
        i = i + 1
    false

// Check if a fn-like macro is a stringify macro (has # in body) or
// calls another fn-like macro that stringifies (e.g. XSTRING -> STRING -> #a).
fn ci_is_stringify_macro(session: i64, name: str, depth: i32) -> bool:
    if depth > 5: return false
    let macro_session = if g_migrate_macro_session != 0: g_migrate_macro_session else: session
    let count = with_cimport_macro_count(macro_session)
    var i = 0
    while i < count:
        if with_cimport_macro_is_fn_like(macro_session, i) != 0:
            if with_cimport_macro_name(macro_session, i) == name:
                let value = with_cimport_macro_value(macro_session, i)
                // Direct stringify: body contains `#param` (a `#`
                // not part of a `##` token-paste pair). Walk byte
                // by byte and skip both `#`s when we see `##` so
                // we don't misread the second `#` as a stringify.
                var j = 0
                while j < value.len() as i32 - 1:
                    if value.byte_at(j as i64) == 35:
                        if value.byte_at((j + 1) as i64) == 35:
                            // `##` token paste — skip both
                            j = j + 2
                            continue
                        // `#` followed by non-`#` — stringify
                        return true
                    j = j + 1
                // Indirect: body calls another fn-like macro, e.g. STRING(s)
                var k = 0
                while k < value.len() as i32:
                    if ci_is_ident_start(value.byte_at(k as i64)):
                        var ke = k + 1
                        while ke < value.len() as i32 and ci_is_ident_char(value.byte_at(ke as i64)):
                            ke = ke + 1
                        if ke < value.len() as i32 and value.byte_at(ke as i64) == 40:
                            let callee = value.slice(k as i64, ke as i64)
                            if ci_is_stringify_macro(macro_session, callee, depth + 1):
                                return true
                        k = ke
                    else:
                        k = k + 1
                return false
        i = i + 1
	    false

fn ci_string_text_has_stringify_call(session: i64, s: str) -> bool:
    var i = 0
    let slen = s.len() as i32
    while i < slen:
        if ci_is_ident_start(s.byte_at(i as i64)):
            var end = i + 1
            while end < slen and ci_is_ident_char(s.byte_at(end as i64)):
                end = end + 1
            var j = end
            while j < slen and ci_is_space(s.byte_at(j as i64)):
                j = j + 1
            if j < slen and s.byte_at(j as i64) == 40:
                if ci_is_stringify_macro(session, s.slice(i as i64, end as i64), 0):
                    return true
            i = end
        else:
            i = i + 1
    false

fn ci_string_text_contains_macro_like_ident(s: str) -> bool:
    var i = 0
    let slen = s.len() as i32
    while i < slen:
        if ci_is_ident_start(s.byte_at(i as i64)):
            let start = i
            var has_lower = false
            var has_upper = false
            var has_macro_marker = false
            i = i + 1
            while i < slen and ci_is_ident_char(s.byte_at(i as i64)):
                i = i + 1
            var j = start
            while j < i:
                let c = s.byte_at(j as i64)
                if c >= 97 and c <= 122:
                    has_lower = true
                else if c >= 65 and c <= 90:
                    has_upper = true
                else if c == 95 or (c >= 48 and c <= 57):
                    has_macro_marker = true
                j = j + 1
            if has_upper and has_macro_marker and not has_lower:
                return true
        else:
            i = i + 1
    false

fn ci_string_text_mentions_null_escape(s: str) -> bool:
    var i = 0
    let slen = s.len() as i32
    while i + 1 < slen:
        if s.byte_at(i as i64) != 92:
            i = i + 1
            continue
        let c = s.byte_at((i + 1) as i64)
        if c >= 48 and c <= 55:
            return true
        if c == 120 or c == 88:
            var j = i + 2
            var value = 0
            var digits = 0
            while j < slen:
                let d = s.byte_at(j as i64)
                if d >= 48 and d <= 57:
                    value = value * 16 + (d as i32 - 48)
                else if d >= 65 and d <= 70:
                    value = value * 16 + (d as i32 - 55)
                else if d >= 97 and d <= 102:
                    value = value * 16 + (d as i32 - 87)
                else:
                    break
                digits = digits + 1
                j = j + 1
            if digits > 0 and value == 0:
                return true
            i = j
            continue
        i = i + 2
    false

fn ci_first_string_literal_token(s: str) -> str:
    var pos = 0
    let slen = s.len() as i32
    while pos < slen:
        if s.byte_at(pos as i64) == 34:
            let end = ci_find_string_literal_end(s, pos)
            if end > pos:
                return s.slice(pos as i64, end as i64)
            return ""
        pos = pos + 1
    ""

fn ci_string_sequence_at(s: str, start: i32) -> str:
    if start < 0 or start >= s.len() as i32 or s.byte_at(start as i64) != 34:
        return ""
    var pos = start
    let slen = s.len() as i32
    var result = ""
    while pos < slen:
        while pos < slen and ci_is_space(s.byte_at(pos as i64)):
            pos = pos + 1
        if pos >= slen or s.byte_at(pos as i64) != 34:
            break
        let end = ci_find_string_literal_end(s, pos)
        if end <= pos:
            break
        if result.len() > 0:
            result = result ++ " "
        result = result ++ s.slice(pos as i64, end as i64)
        pos = end
    result

fn ci_preprocessed_text_at_location(loc: str, raw_src: str) -> str:
    if g_migrate_preprocessed_source.len() == 0 or raw_src.len() == 0 or loc.len() == 0:
        return ""
    let last_colon = ci_find_last_char(loc, 58)
    if last_colon < 0:
        return ""
    let path_and_line = loc.slice(0, last_colon as i64)
    let second_colon = ci_find_last_char(path_and_line, 58)
    if second_colon < 0:
        return ""
    let target_file_raw = path_and_line.slice(0, second_colon as i64)
    let target_file_real = ci_realpath_cached(target_file_raw)
    let target_file = if target_file_real.len() > 0: target_file_real else: target_file_raw
    let start_line = ci_parse_i64(path_and_line.slice((second_colon + 1) as i64, path_and_line.len())) as i32
    if start_line <= 0:
        return ""
    let target_end_line = start_line + ci_count_substring(raw_src, "\n")

    var collected_parts: Vec[str] = Vec.new()
    var current_file = ""
    var current_file_real = ""
    var current_line = 1
    var pos = 0
    let plen = g_migrate_preprocessed_source.len() as i32
    while pos <= plen:
        var end = pos
        while end < plen and g_migrate_preprocessed_source.byte_at(end as i64) != 10:
            end = end + 1
        let line = g_migrate_preprocessed_source.slice(pos as i64, end as i64)
        let trimmed = ci_trim(line)
        if trimmed.len() > 0 and trimmed.byte_at(0) == 35:
            let marker_line = ci_parse_line_marker_number(trimmed)
            let marker_file = ci_parse_line_marker_file(trimmed)
            if marker_line > 0 and marker_file.len() > 0:
                current_line = marker_line
                current_file = marker_file
                let marker_real = ci_realpath_cached(marker_file)
                current_file_real = if marker_real.len() > 0: marker_real else: marker_file
        else:
            if (current_file == target_file or current_file_real == target_file) and current_line >= start_line and current_line <= target_end_line:
                collected_parts.push(line)
                collected_parts.push("\n")
            current_line = current_line + 1
        if end >= plen:
            break
        pos = end + 1
    ci_trim(collected_parts.join(""))

fn ci_preprocessed_text_for_cursor(session: i64, cursor: i32, raw_src: str) -> str:
    let expansion = ci_preprocessed_text_at_location(with_ci_cursor_expansion_location(session, cursor), raw_src)
    if expansion.len() > 0:
        return expansion
    let spelling = ci_preprocessed_text_at_location(with_ci_cursor_spelling_location(session, cursor), raw_src)
    if spelling.len() > 0:
        return spelling
    ci_preprocessed_text_at_location(with_ci_cursor_location(session, cursor), raw_src)

fn ci_preprocessed_string_sequence_for_cursor(session: i64, cursor: i32, raw_src: str) -> str:
    let preprocessed = ci_preprocessed_text_for_cursor(session, cursor, raw_src)
    if preprocessed.len() == 0:
        return ""
    let first_token = ci_first_string_literal_token(raw_src)
    var start = if first_token.len() > 0: ci_find_str(preprocessed, first_token) else: -1
    if start < 0:
        start = ci_find_str(preprocessed, "\"")
    if start < 0:
        return ""
    ci_string_sequence_at(preprocessed, start)


// Expand inner macro references in a stringify argument.
// For each identifier token, if it's a non-fn macro, substitute its value.
fn ci_expand_stringify_args(session: i64, args: str) -> str:
    var result = ""
    var pos = 0
    let alen = args.len() as i32
    while pos < alen:
        if ci_is_ident_start(args.byte_at(pos as i64)):
            var end = pos + 1
            while end < alen and ci_is_ident_char(args.byte_at(end as i64)):
                end = end + 1
            let ident = args.slice(pos as i64, end as i64)
            let val = ci_lookup_macro_value(session, ident)
            if val.len() > 0:
                result = result ++ val
            else:
                result = result ++ ident
            pos = end
        else:
            result = result ++ args.slice(pos as i64, (pos + 1) as i64)
            pos = pos + 1
    result

// Try to expand a stringify macro call like XSTRING(MAJOR.MINOR DATE)
// into a string literal. Returns "" if not a stringify macro call.
fn ci_try_expand_stringify_call(session: i64, s: str) -> str:
    let slen = s.len() as i32
    // Find the macro name (identifier before '(')
    var ne = 0
    while ne < slen and ci_is_ident_char(s.byte_at(ne as i64)):
        ne = ne + 1
    if ne == 0 or ne >= slen or s.byte_at(ne as i64) != 40:
        return ""
    let name = s.slice(0, ne as i64)
    if not ci_is_stringify_macro(session, name, 0):
        return ""
    // Extract argument (everything between outer parens)
    let arg_start = ne + 1
    var paren_depth = 1
    var arg_end = arg_start
    while arg_end < slen and paren_depth > 0:
        let c = s.byte_at(arg_end as i64)
        if c == 40: paren_depth = paren_depth + 1
        if c == 41: paren_depth = paren_depth - 1
        if paren_depth > 0: arg_end = arg_end + 1
    if paren_depth != 0:
        return ""
    let args = s.slice(arg_start as i64, arg_end as i64)
    // Expand inner macros in the argument, then stringify
    let expanded = ci_expand_stringify_args(session, args)
    "\"" ++ expanded ++ "\""

fn ci_expand_string_macro_token(session: i64, token: str, depth: i32) -> str:
    if depth > 12:
        return ""
    let stripped = ci_strip_parens(ci_trim(ci_strip_c_comments(token)))
    if stripped.len() == 0:
        return ""
    if ci_is_concatenated_string(stripped):
        return ci_concat_strings(stripped)
    if ci_is_string_literal(stripped):
        return ci_concat_strings(stripped)
    let stringify_result = ci_try_expand_stringify_call(session, stripped)
    if stringify_result.len() > 0:
        return stringify_result
    let macro_value = ci_lookup_macro_value(session, stripped)
    if macro_value.len() > 0 and macro_value != stripped:
        return ci_expand_string_macro_sequence_depth(session, macro_value, depth + 1)
    ""

fn ci_expand_string_macro_sequence(session: i64, s: str) -> str:
    ci_expand_string_macro_sequence_depth(session, s, 0)

fn ci_expand_string_macro_sequence_depth(session: i64, s: str, depth: i32) -> str:
    if depth > 12:
        return ""
    let cleaned = ci_strip_parens(ci_trim(ci_strip_c_comments(s)))
    if cleaned.len() == 0:
        return ""
    if ci_is_concatenated_string(cleaned):
        return ci_concat_strings(cleaned)
    if ci_is_string_literal(cleaned):
        return ci_concat_strings(cleaned)
    var segments = ""
    var pos = 0
    let slen = cleaned.len() as i32
    var found_any = false
    while pos < slen:
        while pos < slen and ci_is_space(cleaned.byte_at(pos as i64)):
            pos = pos + 1
        if pos >= slen:
            break
        var end = pos
        var token = ""
        let string_end = ci_find_string_literal_end(cleaned, pos)
        if string_end > pos:
            end = string_end
            token = cleaned.slice(pos as i64, end as i64)
        else:
            // Scan a token, respecting parentheses (for MACRO(args))
            var paren_depth = 0
            while end < slen:
                let c = cleaned.byte_at(end as i64)
                if c == 40: paren_depth = paren_depth + 1
                if c == 41:
                    paren_depth = paren_depth - 1
                    if paren_depth == 0:
                        end = end + 1
                        break
                if paren_depth == 0 and ci_is_space(c):
                    break
                end = end + 1
            token = ci_expand_string_macro_token(session, cleaned.slice(pos as i64, end as i64), depth)
            if token.len() == 0:
                return ""
        if ci_is_concatenated_string(token):
            token = ci_concat_strings(token)
        if not ci_is_string_literal(token):
            return ""
        if segments.len() > 0:
            segments = segments ++ " "
        segments = segments ++ token
        found_any = true
        pos = end
    if not found_any:
        return ""
    if ci_is_concatenated_string(segments):
        return ci_concat_strings(segments)
    if ci_is_string_literal(segments):
        return ci_concat_strings(segments)
    ""

fn ci_var_decl_has_initializer_text(s: str) -> bool:
    let text = ci_strip_c_comments(s)
    let slen = text.len() as i32
    var paren_depth = 0
    var bracket_depth = 0
    var brace_depth = 0
    var i = 0
    while i < slen:
        let c = text.byte_at(i as i64)
        if c == 34 or c == 39:
            let quote = c
            i = i + 1
            while i < slen:
                let inner = text.byte_at(i as i64)
                if inner == 92:
                    i = i + 2
                    continue
                if inner == quote:
                    break
                i = i + 1
            i = i + 1
            continue
        if c == 40: paren_depth = paren_depth + 1
        if c == 41 and paren_depth > 0: paren_depth = paren_depth - 1
        if c == 91: bracket_depth = bracket_depth + 1
        if c == 93 and bracket_depth > 0: bracket_depth = bracket_depth - 1
        if c == 123: brace_depth = brace_depth + 1
        if c == 125 and brace_depth > 0: brace_depth = brace_depth - 1
        if c == 61 and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
            let prev = if i > 0: text.byte_at((i - 1) as i64) else: 0
            let next = if i + 1 < slen: text.byte_at((i + 1) as i64) else: 0
            if prev != 61 and prev != 33 and prev != 60 and prev != 62 and next != 61:
                return true
        i = i + 1
    false

fn ci_extract_var_initializer_text(s: str) -> str:
    let text = ci_strip_c_comments(s)
    let slen = text.len() as i32
    var paren_depth = 0
    var bracket_depth = 0
    var brace_depth = 0
    var eq_pos = -1
    var i = 0
    while i < slen:
        let c = text.byte_at(i as i64)
        if c == 34 or c == 39:
            let quote = c
            i = i + 1
            while i < slen:
                let inner = text.byte_at(i as i64)
                if inner == 92:
                    i = i + 2
                    continue
                if inner == quote:
                    break
                i = i + 1
            i = i + 1
            continue
        if c == 40: paren_depth = paren_depth + 1
        if c == 41: paren_depth = paren_depth - 1
        if c == 91: bracket_depth = bracket_depth + 1
        if c == 93: bracket_depth = bracket_depth - 1
        if c == 123: brace_depth = brace_depth + 1
        if c == 125: brace_depth = brace_depth - 1
        if paren_depth == 0 and bracket_depth == 0 and brace_depth == 0 and c == 61:
            let prev = if i > 0: text.byte_at((i - 1) as i64) else: 0
            let next = if i + 1 < slen: text.byte_at((i + 1) as i64) else: 0
            if prev != 61 and next != 61:
                eq_pos = i
                break
        i = i + 1
    if eq_pos < 0:
        return ""
    var end = slen
    while end > eq_pos + 1 and ci_is_space(text.byte_at((end - 1) as i64)):
        end = end - 1
    if end > eq_pos + 1 and text.byte_at((end - 1) as i64) == 59:
        end = end - 1
    while end > eq_pos + 1 and ci_is_space(text.byte_at((end - 1) as i64)):
        end = end - 1
    ci_trim(text.slice((eq_pos + 1) as i64, end as i64))

fn ci_parse_line_marker_file(line: str) -> str:
    let first_quote = ci_find_substr(line, "\"")
    if first_quote < 0:
        return ""
    let rest = line.slice((first_quote + 1) as i64, line.len())
    let second_quote = ci_find_substr(rest, "\"")
    if second_quote < 0:
        return ""
    rest.slice(0, second_quote as i64)

fn ci_parse_line_marker_number(line: str) -> i32:
    var i = 0
    let slen = line.len() as i32
    while i < slen and ci_is_space(line.byte_at(i as i64)):
        i = i + 1
    if i < slen and line.byte_at(i as i64) == 35:
        i = i + 1
    while i < slen and ci_is_space(line.byte_at(i as i64)):
        i = i + 1
    if i + 4 <= slen and line.slice(i as i64, (i + 4) as i64) == "line":
        i = i + 4
    while i < slen and ci_is_space(line.byte_at(i as i64)):
        i = i + 1
    let start = i
    while i < slen and line.byte_at(i as i64) >= 48 and line.byte_at(i as i64) <= 57:
        i = i + 1
    if i <= start:
        return -1
    let num_str = line.slice(start as i64, i as i64)
    ci_parse_i64(num_str) as i32

fn ci_array_element_type(ty: str) -> str:
    if ty.len() == 0 or ty.byte_at(0) != 91:
        return ""
    let close = ci_find_substr(ty, "]")
    if close < 0 or close as i64 + 1 >= ty.len():
        return ""
    ci_trim(ty.slice((close + 1) as i64, ty.len()))

fn ci_array_length_from_type(ty: str) -> i32:
    if ty.len() == 0 or ty.byte_at(0) != 91:
        return -1
    let close = ci_find_substr(ty, "]")
    if close <= 1:
        return -1
    let len_text = ci_trim(ty.slice(1, close as i64))
    if len_text.len() == 0:
        return -1
    ci_parse_i64(len_text) as i32

fn ci_split_top_level_items(s: str) -> Vec[str]:
    var parts: Vec[str] = Vec.new()
    var paren_depth = 0
    var bracket_depth = 0
    var brace_depth = 0
    var start = 0
    var i = 0
    let slen = s.len() as i32
    while i <= slen:
        let at_end = i == slen
        var c = 0
        if not at_end:
            c = s.byte_at(i as i64)
        if not at_end and (c == 34 or c == 39):
            let quote = c
            i = i + 1
            while i < slen:
                let inner = s.byte_at(i as i64)
                if inner == 92:
                    i = i + 2
                    continue
                if inner == quote:
                    break
                i = i + 1
            i = i + 1
            continue
        if not at_end:
            if c == 40: paren_depth = paren_depth + 1
            if c == 41 and paren_depth > 0: paren_depth = paren_depth - 1
            if c == 91: bracket_depth = bracket_depth + 1
            if c == 93 and bracket_depth > 0: bracket_depth = bracket_depth - 1
            if c == 123: brace_depth = brace_depth + 1
            if c == 125 and brace_depth > 0: brace_depth = brace_depth - 1
        if at_end or (c == 44 and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0):
            let item = ci_trim(s.slice(start as i64, i as i64))
            if item.len() > 0:
                parts.push(item)
            start = i + 1
        i = i + 1
    parts

fn ci_translate_c_initializer_for_type(session: i64, init_src: str, ty: str) -> str:
    ci_translate_c_initializer_for_cursor_type(session, init_src, ty, -1)

fn ci_c_initializer_cast_type_is_void_ptr(cast_type: str) -> bool:
    var compact = ""
    var i = 0
    while i < cast_type.len() as i32:
        let c = cast_type.byte_at(i as i64)
        if not ci_is_space(c):
            compact = compact ++ cast_type.slice(i as i64, (i + 1) as i64)
        i = i + 1
    compact == "void*" or compact == "constvoid*" or compact == "voidconst*" or compact == "volatilevoid*" or compact == "voidvolatile*" or compact == "constvolatilevoid*" or compact == "volatileconstvoid*"

fn ci_c_initializer_is_null_pointer_cast(s: str) -> bool:
    let t = ci_trim(s)
    if t == "NULL" or t == "nullptr":
        return true
    if t.len() == 0 or t.byte_at(0) != 40:
        return false
    let cast_end = ci_find_matching_paren(t, 0)
    if cast_end <= 0 or cast_end as i64 + 1 >= t.len():
        return false
    let cast_type = t.slice(1, cast_end as i64)
    if not ci_c_initializer_cast_type_is_void_ptr(cast_type):
        return false
    ci_trim(t.slice((cast_end + 1) as i64, t.len())) == "0"

fn ci_c_initializer_is_identifier(s: str) -> bool:
    let t = ci_trim(s)
    if t.len() == 0 or not ci_is_ident_start(t.byte_at(0)):
        return false
    var i = 1
    while i < t.len() as i32:
        if not ci_is_ident_char(t.byte_at(i as i64)):
            return false
        i = i + 1
    true

fn ci_translate_c_initializer_for_cursor_type(session: i64, init_src: str, ty: str, cxtype: i32) -> str:
    let trimmed = ci_trim(init_src)
    if trimmed.len() == 0:
        return ""
    if ci_is_concatenated_string(trimmed):
        return ci_coerce_init_value_for_type(ci_concat_strings(trimmed), ty)
    if ci_is_string_literal(trimmed):
        return ci_coerce_init_value_for_type(trimmed, ty)
    if ci_c_initializer_is_null_pointer_cast(ci_strip_parens(trimmed)):
        if ty.len() > 0 and (ty.byte_at(0) == 42 or ci_starts_with(ty, "Option[")):
            return "null"
        return "0"
    if trimmed.byte_at(0) != 123:
        var translated = ci_translate_c_expr(trimmed, "", "")
        if translated.len() == 0 and ty.len() > 0 and ty.byte_at(0) == 42 and ci_c_initializer_is_identifier(trimmed):
            let decl = ci_find_var_cursor(session, trimmed)
            if decl >= 0 and ci_cursor_is_array_type(session, decl):
                translated = "(&" ++ trimmed ++ "[0] as " ++ ty ++ ")"
        if translated.len() == 0:
            return ""
        if ci_starts_with(translated, ".{") and ty.len() > 0 and ty.byte_at(0) != 91:
            translated = ty ++ " " ++ translated
        return ci_coerce_init_value_for_type(translated, ty)

    let close_brace = ci_find_matching_brace(trimmed, 0)
    if close_brace != trimmed.len() as i32 - 1:
        return ""
    let inner = ci_trim(trimmed.slice(1, close_brace as i64))
    if inner.len() == 0:
        if ty.len() > 0 and ty.byte_at(0) == 91:
            return "[]"
        if ty.len() > 0:
            return ty ++ " {}"
        return "{}"

    if inner.byte_at(0) == 46:
        let designated = ci_translate_c_expr(trimmed, "", "")
        if designated.len() == 0:
            return ""
        if ci_starts_with(designated, ".{") and ty.len() > 0 and ty.byte_at(0) != 91:
            return ty ++ " " ++ designated
        return designated

    if ty.len() > 0 and ty.byte_at(0) == 91:
        let elem_ty = ci_array_element_type(ty)
        if elem_ty.len() == 0:
            return ""
        let elem_cxtype = if cxtype >= 0: with_ci_type_array_element(session, cxtype) else: -1
        let items = ci_split_top_level_items(inner)
        var expanded_items: Vec[str] = Vec.new()
        var expand_i = 0
        while expand_i < items.len() as i32:
            let raw_item = items.get(expand_i as i64)
            var expanded_any = false
            if ci_c_initializer_is_identifier(raw_item):
                let macro_value = ci_lookup_macro_value(session, ci_trim(raw_item))
                if macro_value.len() > 0:
                    let macro_items = ci_split_top_level_items(macro_value)
                    if macro_items.len() > 1:
                        var mi: i64 = 0
                        while mi < macro_items.len():
                            expanded_items.push(macro_items.get(mi))
                            mi = mi + 1
                        expanded_any = true
            if not expanded_any:
                expanded_items.push(raw_item)
            expand_i = expand_i + 1
        var rendered_parts: Vec[str] = Vec.new()
        rendered_parts.push("[")
        var i = 0
        while i < expanded_items.len() as i32:
            let item = ci_translate_c_initializer_for_cursor_type(session, expanded_items.get(i as i64), elem_ty, elem_cxtype)
            if item.len() == 0:
                return ""
            if i > 0:
                rendered_parts.push(", ")
            rendered_parts.push(item)
            i = i + 1
        rendered_parts.push("]")
        return rendered_parts.join("")

    let field_count = ci_init_list_record_field_count(session, ty, cxtype)
    if field_count > 0:
        let items = ci_split_top_level_items(inner)
        var field_parts: Vec[str] = Vec.new()
        field_parts.push(ty)
        field_parts.push(" { ")
        var i = 0
        while i < items.len() as i32:
            if i >= field_count:
                return ""
            let field_name = ci_init_list_record_field_name(session, ty, cxtype, i)
            let field_ty = ci_init_list_record_field_type(session, ty, cxtype, i)
            let field_cxtype = ci_init_list_record_field_cxtype(session, ty, cxtype, i)
            if field_name.len() == 0 or field_ty.len() == 0:
                return ""
            let item = ci_translate_c_initializer_for_cursor_type(session, items.get(i as i64), field_ty, field_cxtype)
            if item.len() == 0:
                return ""
            if i > 0:
                field_parts.push(", ")
            field_parts.push(field_name)
            field_parts.push(": ")
            field_parts.push(item)
            i = i + 1
        field_parts.push(" }")
        return field_parts.join("")

    if ci_split_top_level_items(inner).len() == 1:
        return ci_translate_c_initializer_for_cursor_type(session, inner, ty, cxtype)
    ""

fn ci_preprocess_initializer_text(session: i64, var_cursor: i32, raw_decl_src: str) -> str:
    if g_migrate_preprocessed_source.len() == 0 or g_migrate_current_input_path.len() == 0 or raw_decl_src.len() == 0:
        return ""
    var loc = with_ci_cursor_expansion_location(session, var_cursor)
    if loc.len() == 0:
        loc = with_ci_cursor_location(session, var_cursor)
    let last_colon = ci_find_last_char(loc, 58)
    if last_colon < 0:
        return ""
    let path_and_line = loc.slice(0, last_colon as i64)
    let second_colon = ci_find_last_char(path_and_line, 58)
    if second_colon < 0:
        return ""
    let target_file_raw = path_and_line.slice(0, second_colon as i64)
    let target_file_real = ci_realpath_cached(target_file_raw)
    let target_file = if target_file_real.len() > 0: target_file_real else: target_file_raw
    let start_line = ci_parse_i64(path_and_line.slice((second_colon + 1) as i64, path_and_line.len())) as i32
    if start_line <= 0:
        return ""
    let target_end_line = start_line + ci_count_substring(raw_decl_src, "\n")

    var collected_parts: Vec[str] = Vec.new()
    var current_file = ""
    var current_file_real = ""
    var current_line = 1
    var pos = 0
    let plen = g_migrate_preprocessed_source.len() as i32
    while pos <= plen:
        var end = pos
        while end < plen and g_migrate_preprocessed_source.byte_at(end as i64) != 10:
            end = end + 1
        let line = g_migrate_preprocessed_source.slice(pos as i64, end as i64)
        let trimmed = ci_trim(line)
        if trimmed.len() > 0 and trimmed.byte_at(0) == 35:
            let marker_line = ci_parse_line_marker_number(trimmed)
            let marker_file = ci_parse_line_marker_file(trimmed)
            if marker_line > 0 and marker_file.len() > 0:
                current_line = marker_line
                current_file = marker_file
                let marker_real = ci_realpath_cached(marker_file)
                current_file_real = if marker_real.len() > 0: marker_real else: marker_file
        else:
            if (current_file == target_file or current_file_real == target_file) and current_line >= start_line and current_line <= target_end_line:
                collected_parts.push(line)
                collected_parts.push("\n")
            current_line = current_line + 1
        if end >= plen:
            break
        pos = end + 1
    let preprocessed_decl = ci_trim(collected_parts.join(""))
    if preprocessed_decl.len() == 0:
        return ""
    ci_extract_var_initializer_text(preprocessed_decl)

fn ci_preprocessed_var_initializer_by_name(var_name: str) -> str:
    if g_migrate_preprocessed_source.len() == 0 or var_name.len() == 0:
        return ""
    let s = g_migrate_preprocessed_source
    let slen = s.len() as i32
    let nlen = var_name.len() as i32
    var i = 0
    while i + nlen <= slen:
        let c = s.byte_at(i as i64)
        if c == 34 or c == 39:
            let quote = c
            i = i + 1
            while i < slen:
                let inner = s.byte_at(i as i64)
                if inner == 92:
                    i = i + 2
                    continue
                if inner == quote:
                    break
                i = i + 1
            i = i + 1
            continue
        if s.slice(i as i64, (i + nlen) as i64) == var_name:
            let before = if i > 0: s.byte_at((i - 1) as i64) else: 0
            let after = if i + nlen < slen: s.byte_at((i + nlen) as i64) else: 0
            if not ci_is_ident_char(before) and not ci_is_ident_char(after):
                var pos = i + nlen
                var paren_depth = 0
                var bracket_depth = 0
                var brace_depth = 0
                var eq_pos = -1
                while pos < slen:
                    let ch = s.byte_at(pos as i64)
                    if ch == 34 or ch == 39:
                        let quote = ch
                        pos = pos + 1
                        while pos < slen:
                            let inner = s.byte_at(pos as i64)
                            if inner == 92:
                                pos = pos + 2
                                continue
                            if inner == quote:
                                break
                            pos = pos + 1
                        pos = pos + 1
                        continue
                    if ch == 59 and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                        break
                    if ch == 40: paren_depth = paren_depth + 1
                    if ch == 41 and paren_depth > 0: paren_depth = paren_depth - 1
                    if ch == 91: bracket_depth = bracket_depth + 1
                    if ch == 93 and bracket_depth > 0: bracket_depth = bracket_depth - 1
                    if ch == 123: brace_depth = brace_depth + 1
                    if ch == 125 and brace_depth > 0: brace_depth = brace_depth - 1
                    if ch == 61 and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                        eq_pos = pos
                        break
                    pos = pos + 1
                if eq_pos >= 0:
                    var end = eq_pos + 1
                    paren_depth = 0
                    bracket_depth = 0
                    brace_depth = 0
                    while end < slen:
                        let ch = s.byte_at(end as i64)
                        if ch == 34 or ch == 39:
                            let quote = ch
                            end = end + 1
                            while end < slen:
                                let inner = s.byte_at(end as i64)
                                if inner == 92:
                                    end = end + 2
                                    continue
                                if inner == quote:
                                    break
                                end = end + 1
                            end = end + 1
                            continue
                        if ch == 59 and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                            return ci_trim(s.slice((eq_pos + 1) as i64, end as i64))
                        if ch == 40: paren_depth = paren_depth + 1
                        if ch == 41 and paren_depth > 0: paren_depth = paren_depth - 1
                        if ch == 91: bracket_depth = bracket_depth + 1
                        if ch == 93 and bracket_depth > 0: bracket_depth = bracket_depth - 1
                        if ch == 123: brace_depth = brace_depth + 1
                        if ch == 125 and brace_depth > 0: brace_depth = brace_depth - 1
                        end = end + 1
        i = i + 1
    ""

fn ci_source_line_at(path: str, line_no: i32) -> str:
    if path.len() == 0 or line_no <= 0:
        return ""
    var text = with_fs_read_file(path)
    if text.len() == 0:
        let real = ci_realpath_cached(path)
        if real.len() > 0:
            text = with_fs_read_file(real)
    if text.len() == 0:
        return ""
    var line = 1
    var start = 0
    let len = text.len() as i32
    var pos = 0
    while pos <= len:
        if pos == len or text.byte_at(pos as i64) == 10:
            if line == line_no:
                return text.slice(start as i64, pos as i64)
            line = line + 1
            start = pos + 1
        pos = pos + 1
    ""

fn ci_macro_arg_for_initializer_param(session: i64, var_cursor: i32, param_name: str) -> str:
    let param = ci_trim(param_name)
    if param.len() == 0 or not ci_c_initializer_is_identifier(param):
        return ""
    let loc = with_ci_cursor_expansion_location(session, var_cursor)
    let last_colon = ci_find_last_char(loc, 58)
    if last_colon < 0:
        return ""
    let path_and_line = loc.slice(0, last_colon as i64)
    let second_colon = ci_find_last_char(path_and_line, 58)
    if second_colon < 0:
        return ""
    let path = path_and_line.slice(0, second_colon as i64)
    let line_no = ci_parse_i64(path_and_line.slice((second_colon + 1) as i64, path_and_line.len())) as i32
    let col_no = ci_parse_i64(loc.slice((last_colon + 1) as i64, loc.len())) as i32
    let line = ci_source_line_at(path, line_no)
    if line.len() == 0:
        return ""
    var pos = if col_no > 0: col_no - 1 else: 0
    let llen = line.len() as i32
    while pos < llen and ci_is_space(line.byte_at(pos as i64)):
        pos = pos + 1
    if pos >= llen or not ci_is_ident_start(line.byte_at(pos as i64)):
        return ""
    var name_end = pos + 1
    while name_end < llen and ci_is_ident_char(line.byte_at(name_end as i64)):
        name_end = name_end + 1
    let macro_name = line.slice(pos as i64, name_end as i64)
    var paren = name_end
    while paren < llen and ci_is_space(line.byte_at(paren as i64)):
        paren = paren + 1
    if paren >= llen or line.byte_at(paren as i64) != 40:
        return ""
    let close = ci_find_matching_paren(line, paren)
    if close <= paren:
        return ""
    let macro_session = if g_migrate_macro_session != 0: g_migrate_macro_session else: session
    let count = with_cimport_macro_count(macro_session)
    var macro_idx = -1
    var i = 0
    while i < count:
        if with_cimport_macro_is_fn_like(macro_session, i) != 0 and with_cimport_macro_name(macro_session, i) == macro_name:
            macro_idx = i
            break
        i = i + 1
    if macro_idx < 0:
        return ""
    let param_count = with_cimport_macro_param_count(macro_session, macro_idx)
    var param_idx = -1
    var pi = 0
    while pi < param_count:
        if with_cimport_macro_param_name(macro_session, macro_idx, pi) == param:
            param_idx = pi
            break
        pi = pi + 1
    if param_idx < 0:
        return ""
    let arg_text = line.slice((paren + 1) as i64, close as i64)
    let args = ci_split_top_level_items(arg_text)
    if param_idx >= args.len() as i32:
        return ""
    ci_trim(args.get(param_idx as i64))

fn ci_string_macro_arg_from_expansion(session: i64, cursor: i32) -> str:
    let loc = with_ci_cursor_expansion_location(session, cursor)
    let last_colon = ci_find_last_char(loc, 58)
    if last_colon < 0:
        return ""
    let path_and_line = loc.slice(0, last_colon as i64)
    let second_colon = ci_find_last_char(path_and_line, 58)
    if second_colon < 0:
        return ""
    let path = path_and_line.slice(0, second_colon as i64)
    let line_no = ci_parse_i64(path_and_line.slice((second_colon + 1) as i64, path_and_line.len())) as i32
    let col_no = ci_parse_i64(loc.slice((last_colon + 1) as i64, loc.len())) as i32
    let line = ci_source_line_at(path, line_no)
    if line.len() == 0:
        return ""
    var pos = if col_no > 0: col_no - 1 else: 0
    let llen = line.len() as i32
    while pos < llen and ci_is_space(line.byte_at(pos as i64)):
        pos = pos + 1
    if pos >= llen or not ci_is_ident_start(line.byte_at(pos as i64)):
        return ""
    var name_end = pos + 1
    while name_end < llen and ci_is_ident_char(line.byte_at(name_end as i64)):
        name_end = name_end + 1
    var paren = name_end
    while paren < llen and ci_is_space(line.byte_at(paren as i64)):
        paren = paren + 1
    if paren >= llen or line.byte_at(paren as i64) != 40:
        return ""
    let close = ci_find_matching_paren(line, paren)
    if close <= paren:
        return ""
    let args = ci_split_top_level_items(line.slice((paren + 1) as i64, close as i64))
    var found = ""
    var found_count = 0
    var i = 0
    while i < args.len() as i32:
        let arg = ci_trim(args.get(i as i64))
        if ci_expand_string_macro_sequence(session, arg).len() > 0:
            found = arg
            found_count = found_count + 1
        i = i + 1
    if found_count == 1:
        return found
    ""

fn ci_macro_body_initializer_param_from_cursor(session: i64, var_cursor: i32) -> str:
    var loc = with_ci_cursor_spelling_location(session, var_cursor)
    if loc.len() == 0:
        loc = with_ci_cursor_location(session, var_cursor)
    let last_colon = ci_find_last_char(loc, 58)
    if last_colon < 0:
        return ""
    let path_and_line = loc.slice(0, last_colon as i64)
    let second_colon = ci_find_last_char(path_and_line, 58)
    if second_colon < 0:
        return ""
    let path = path_and_line.slice(0, second_colon as i64)
    let line_no = ci_parse_i64(path_and_line.slice((second_colon + 1) as i64, path_and_line.len())) as i32
    let line = ci_source_line_at(path, line_no)
    if line.len() == 0:
        return ""
    let init = ci_extract_var_initializer_text(line)
    if ci_c_initializer_is_identifier(init):
        return init
    ""

fn ci_var_init_expr_from_decl_source(session: i64, var_cursor: i32) -> str:
    ci_var_init_expr_from_decl_source_for_type(session, var_cursor, "")

fn ci_var_init_expr_from_preprocessed_cursor_for_type(session: i64, var_cursor: i32, target_type: str) -> str:
    let raw_decl_src = with_ci_cursor_expansion_text(session, var_cursor)
    let preprocessed = ci_preprocess_initializer_text(session, var_cursor, raw_decl_src)
    if preprocessed.len() == 0:
        return ""
    let cursor_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, var_cursor))
    let vty_str = if target_type.len() > 0: target_type else: cursor_ty_str
    let var_cxtype = with_ci_cursor_type(session, var_cursor)
    let translated = ci_translate_c_initializer_for_cursor_type(session, preprocessed, vty_str, var_cxtype)
    if ci_var_init_translation_is_valid(vty_str, translated):
        return translated
    ""

fn ci_var_initializer_text_from_cursor(session: i64, var_cursor: i32) -> str:
    var init_src = ci_extract_var_initializer_text(with_ci_cursor_expansion_text(session, var_cursor))
    if init_src.len() > 0:
        return init_src
    let expansion_src = ci_trim(with_ci_cursor_expansion_text(session, var_cursor))
    if ci_expand_string_macro_sequence(session, expansion_src).len() > 0:
        return expansion_src
    let macro_body_param = ci_macro_body_initializer_param_from_cursor(session, var_cursor)
    if macro_body_param.len() > 0:
        let macro_arg = ci_macro_arg_for_initializer_param(session, var_cursor, macro_body_param)
        if macro_arg.len() > 0:
            return macro_arg
    init_src = ci_extract_var_initializer_text(with_ci_cursor_spelling_text(session, var_cursor))
    if init_src.len() > 0:
        let macro_arg = ci_macro_arg_for_initializer_param(session, var_cursor, init_src)
        if macro_arg.len() > 0:
            return macro_arg
        return init_src
    init_src = ci_extract_var_initializer_text(with_ci_cursor_source_text(session, var_cursor))
    if init_src.len() > 0:
        let macro_arg = ci_macro_arg_for_initializer_param(session, var_cursor, init_src)
        if macro_arg.len() > 0:
            return macro_arg
    init_src

fn ci_var_init_expr_from_decl_source_for_type(session: i64, var_cursor: i32, target_type: str) -> str:
    let raw_decl_src = with_ci_cursor_source_text(session, var_cursor)
    var init_src = ci_var_initializer_text_from_cursor(session, var_cursor)
    let var_name = with_ci_cursor_spelling(session, var_cursor)
    if init_src.len() == 0:
        init_src = ci_preprocessed_var_initializer_by_name(var_name)
    if init_src.len() == 0:
        return ""
    let cursor_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, var_cursor))
    let vty_str = if target_type.len() > 0: target_type else: cursor_ty_str
    let var_cxtype = with_ci_cursor_type(session, var_cursor)
    let preprocessed = ci_preprocess_initializer_text(session, var_cursor, raw_decl_src)
    if preprocessed.len() > 0:
        let translated = ci_translate_c_initializer_for_cursor_type(session, preprocessed, vty_str, var_cxtype)
        if ci_var_init_translation_is_valid(vty_str, translated):
            return translated
    let expanded = ci_expand_string_macro_sequence(session, init_src)
    if expanded.len() > 0:
        let translated = ci_translate_c_initializer_for_cursor_type(session, expanded, vty_str, var_cxtype)
        if ci_var_init_translation_is_valid(vty_str, translated):
            return translated
    let translated = ci_translate_c_initializer_for_cursor_type(session, init_src, vty_str, var_cxtype)
    if ci_var_init_translation_is_valid(vty_str, translated):
        return translated
    let preprocessed_by_name = ci_preprocessed_var_initializer_by_name(var_name)
    if preprocessed_by_name.len() > 0 and preprocessed_by_name != init_src:
        let by_name_translated = ci_translate_c_initializer_for_cursor_type(session, preprocessed_by_name, vty_str, var_cxtype)
        if ci_var_init_translation_is_valid(vty_str, by_name_translated):
            return by_name_translated
    ""

fn ci_expr_has_unresolved_string_macro(s: str) -> bool:
    var i = 0
    let slen = s.len() as i32
    while i < slen:
        if ci_is_ident_start(s.byte_at(i as i64)):
            var end = i + 1
            while end < slen and ci_is_ident_char(s.byte_at(end as i64)):
                end = end + 1
            let ident = s.slice(i as i64, end as i64)
            if ci_starts_with(ident, "STR_") or ci_starts_with(ident, "STRING_"):
                return true
            i = end
            continue
        i = i + 1
    false

fn ci_var_init_translation_is_valid(vty_str: str, init_expr: str) -> bool:
    let trimmed = ci_trim(init_expr)
    if trimmed.len() == 0:
        return false
    if ci_str_contains(trimmed, "/*") or ci_str_contains(trimmed, "*/") or ci_str_contains(trimmed, "//"):
        return false
    if ci_expr_has_unresolved_string_macro(trimmed):
        return false
    if vty_str.len() > 0 and vty_str.byte_at(0) == 91:
        if ci_is_string_literal(trimmed) or ci_is_concatenated_string(trimmed):
            return false
        if trimmed.byte_at(0) != 91:
            return false
    true

fn ci_var_init_expr(session: i64, var_cursor: i32, scope: CiScope) -> str:
    ci_var_init_expr_for_type(session, var_cursor, scope, "")

fn ci_var_init_expr_for_type(session: i64, var_cursor: i32, scope: CiScope, target_type: str) -> str:
    let init_cursor = ci_find_var_init_cursor(session, var_cursor)
    if init_cursor >= 0:
        var types = CiTypePool.new()
        var exprs = CiExprPool.new()
        var stmts = CiStmtPool.new()
        let lowered = stmts.lower_value_expr_ir(session, init_cursor, exprs, types, scope)
        var init_expr = ""
        if ci_value_ir_valid(lowered):
            init_expr = stmts.render_value_expr_ir(session, init_cursor, exprs, types, lowered)
        stmts.deinit()
        exprs.deinit()
        types.deinit()
        let cursor_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, var_cursor))
        let vty_str = if target_type.len() > 0: target_type else: cursor_ty_str
        // Array-to-pointer decay in initializer context: when the
        // var's type is a pointer and the init is an array-typed
        // expression, insert the explicit `&init[0] as *T` decay.
        // C performs this implicitly; With doesn't.
        //
        // String literals are exempt — With accepts `*const i8 =
        // "literal"` directly without an explicit decay.
        if vty_str.len() > 0 and vty_str.byte_at(0) == 42:
            let init_peeled = ci_peel_transparent(session, init_cursor)
            let init_kind = with_ci_cursor_kind(session, init_peeled)
            if init_kind != CXK_STRING_LITERAL and ci_cursor_is_array_type(session, init_peeled):
                let elem_ty = ci_array_elem_type_from_cursor(session, init_peeled)
                if elem_ty.len() > 0:
                    init_expr = "(&" ++ init_expr ++ "[0] as " ++ vty_str ++ ")"
            // Pointer-type mismatch: when the var is `*T` and the
            // init expression's type is also a pointer but points
            // to a different type (e.g. `*c_void` from a malloc-
            // style call), emit an explicit `as *T` cast to bridge
            // the gap. C does this implicit conversion silently;
            // With requires it explicit.
            //
            // libclang wraps the call in an ImplicitCast whose
            // outer type matches the var, so checking outer-type
            // would always be a no-op. Peel through to the
            // underlying call cursor and compare its type.
            else if with_ci_type_is_pointer(session, init_cursor) != 0:
                let init_peeled_ptr = ci_peel_transparent(session, init_cursor)
                let init_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, init_peeled_ptr))
                if init_ty_str.len() > 0 and init_ty_str != vty_str and with_ci_type_is_pointer(session, init_peeled_ptr) != 0:
                    init_expr = "(" ++ init_expr ++ " as " ++ vty_str ++ ")"
        if vty_str.len() > 0 and vty_str.byte_at(0) == 91 and ci_is_string_literal(init_expr):
            init_expr = ci_coerce_init_value_for_type(init_expr, vty_str)
        if ci_var_init_translation_is_valid(vty_str, init_expr):
            return init_expr
    if ci_scope_get_return_type(scope).len() == 0:
        return ci_var_init_expr_from_decl_source_for_type(session, var_cursor, target_type)
    ""

// ── Migrate: shared helpers used by both c_import and migrate ─────
// (migrate entry points, translate_var/s, ci_migrate_var_* helpers,
//  width-slice + shared-defs + preamble text moved to src/CiMigrate.w
//  during D3 cleanup. Only globals used by shared CImport code remain
//  here, along with the macro type globals that aren't migrate-specific.)

var g_migrate_macro_values: str = ""
var g_migrate_macro_miss_names: Vec[str] = Vec.new()
var g_migrate_macro_session: i64 = 0
var g_migrate_preprocessed_source: str = ""
var g_migrate_current_input_path: str = ""
var g_macro_type_names: str = ""
var g_macro_type_aliases: str = ""

// Per-function temp counter state (B9). The same cursor can be
// visited multiple times during string-based lowering — the
// memoization map keeps the assigned id stable per cursor so
// re-entry returns the same name. Reset at the start of every
// ci_migrate_translate_function call.
var g_ci_temp_cursors: Vec[i32] = Vec.new()
var g_ci_temp_ids: Vec[i32] = Vec.new()
var g_ci_temp_next: i32 = 0

// Per-function var-name registry. The string holds `|name|`
// segments for every var declaration emitted in the current
// function. Used by ci_lower_decl_stmt to detect when a nested-
// scope decl would shadow an outer one (e.g. `for (int i = 0; ;)`
// in three different switch cases) and rename it. The legacy
// scope plumbing tracks per-block scope but loses the trail when
// switch arms reset to the function-entry scope; this registry
// is function-wide and survives those resets.
var g_ci_fn_var_names: str = ""

// Last bail location from structural lowering. Set when a compound
// statement, for-loop body, do-while body, or goto hoist bails.
// Read by the migrator to report which construct caused the failure.
var g_ci_bail_location: str = ""
var g_ci_bail_kind: i32 = 0
var g_ci_bail_message: str = ""

pub fn ci_get_bail_location() -> str:
    g_ci_bail_location

pub fn ci_get_bail_kind() -> i32:
    g_ci_bail_kind

pub fn ci_get_bail_message() -> str:
    g_ci_bail_message

pub fn ci_clear_bail_location():
    g_ci_bail_location = ""
    g_ci_bail_kind = 0
    g_ci_bail_message = ""
    return

fn ci_fn_var_names_contains(name: str) -> bool:
    let needle = "|" ++ name ++ "|"
    ci_str_contains(g_ci_fn_var_names, needle)

fn ci_fn_var_names_register(name: str):
    g_ci_fn_var_names = g_ci_fn_var_names ++ "|" ++ name ++ "|"

fn ci_fn_var_names_unique(base: str) -> str:
    if not ci_fn_var_names_contains(base):
        return base
    var suffix = 1
    while suffix < 100:
        let candidate = f"{base}_{suffix}"
        if not ci_fn_var_names_contains(candidate):
            return candidate
        suffix = suffix + 1
    base ++ "_99"

fn ci_temp_reset():
    g_ci_temp_cursors = Vec.new()
    g_ci_temp_ids = Vec.new()
    g_ci_temp_next = 0
    g_ci_fn_var_names = ""

fn ci_temp_id_for_cursor(cursor: i32) -> i32:
    var i: i32 = 0
    let n = g_ci_temp_cursors.len() as i32
    while i < n:
        if g_ci_temp_cursors.get(i as i64) == cursor:
            return g_ci_temp_ids.get(i as i64)
        i = i + 1
    let id = g_ci_temp_next
    g_ci_temp_next = g_ci_temp_next + 1
    g_ci_temp_cursors.push(cursor)
    g_ci_temp_ids.push(id)
    id

// Debug trace for CXK_ kinds that still reach the structural
// fallback accounting in ci_lower_expr_ir / ci_lower_stmt_ir.
// Gated behind
// `WITH_MIGRATE_RAW_STATS=1` — recording unconditionally on every
// fallback hit adds measurable overhead during large migrations
// (pcre2_match can trigger thousands of fallbacks per function).
// When the flag is off, ci_record_raw_{expr,stmt}_kind is a no-op
// and the aggregators at end of migration never fire.
var g_ci_raw_stats_enabled_cache: i32 = -1
var g_ci_raw_expr_kinds: Vec[i32] = Vec.new()
var g_ci_raw_stmt_kinds: Vec[i32] = Vec.new()

fn ci_raw_stats_enabled() -> bool:
    if g_ci_raw_stats_enabled_cache == -1:
        let v = with_getenv_str("WITH_MIGRATE_RAW_STATS")
        if v == "1":
            g_ci_raw_stats_enabled_cache = 1
        else:
            g_ci_raw_stats_enabled_cache = 0
    g_ci_raw_stats_enabled_cache != 0

// B11 port verification — each sub-port adds STRUCTURAL[b11.N.site]
// announcements at the call sites it replaces. Gated behind
// WITH_MIGRATE_TRACE_PORT=1 so it is off during normal compiles.
// Verification command for any commit:
//   WITH_MIGRATE_TRACE_PORT=1 out/bin/with migrate .reference/pcre2/src/pcre2_match.c \
//     -o /tmp/trace.w --no-c-export -I .reference/pcre2/src -D PCRE2_CODE_UNIT_WIDTH=8 \
//     2>&1 | grep -E "^(STRUCTURAL|LEGACY)\[b11\." | sort | uniq -c
// Every listed site for the commit must show STRUCTURAL[...] >= 1
// and must not show any LEGACY[...] line.
var g_ci_trace_port_cache: i32 = -1

fn ci_trace_port_enabled() -> bool:
    if g_ci_trace_port_cache == -1:
        let v = with_getenv_str("WITH_MIGRATE_TRACE_PORT")
        if v == "1":
            g_ci_trace_port_cache = 1
        else:
            g_ci_trace_port_cache = 0
    g_ci_trace_port_cache != 0

fn ci_trace_port(tag: str):
    if ci_trace_port_enabled():
        with_eprint(tag)

fn ci_record_raw_expr_kind(kind: i32) -> void:
    if ci_raw_stats_enabled():
        g_ci_raw_expr_kinds.push(kind)

fn ci_record_raw_stmt_kind(kind: i32) -> void:
    if ci_raw_stats_enabled():
        g_ci_raw_stmt_kinds.push(kind)

fn ci_aggregate_kind_vec(v: &Vec[i32], label: str):
    // Collect unique kinds into parallel vectors and count.
    var unique: Vec[i32] = Vec.new()
    var counts: Vec[i32] = Vec.new()
    var i: i64 = 0
    while i < v.len():
        let k = v.get(i)
        var j: i64 = 0
        var found = false
        while j < unique.len():
            if unique.get(j) == k:
                // Reconstruct-and-replace: push the current counts
                // then rebuild into a fresh vector. Avoids using
                // Vec.set which codegens poorly right now.
                found = true
                break
            j = j + 1
        if found:
            // bump by rebuilding counts
            var new_counts: Vec[i32] = Vec.new()
            var m: i64 = 0
            while m < counts.len():
                if m == j:
                    new_counts.push(counts.get(m) + 1)
                else:
                    new_counts.push(counts.get(m))
                m = m + 1
            counts = new_counts
        else:
            unique.push(k)
            counts.push(1)
        i = i + 1
    eprint(label)
    var u: i64 = 0
    while u < unique.len():
        let k = unique.get(u)
        let c = counts.get(u)
        eprint(f"  kind={k} count={c}")
        u = u + 1

pub fn ci_dump_raw_fallback_stats():
    if not ci_raw_stats_enabled():
        return
    ci_aggregate_kind_vec(&g_ci_raw_expr_kinds, "migrate: raw-expr fallback by cursor kind:")
    ci_aggregate_kind_vec(&g_ci_raw_stmt_kinds, "migrate: raw-stmt fallback by cursor kind:")

// (ci_ir_shim_stmt was removed in B5e — B5d's statement-level
// detour covers the same path at finer granularity, so the
// function-body-level shim is redundant.)

// Count occurrences of a substring in a string
// ── Goto elimination: state-variable transform ─────────────

// Check if a function body assigns to a variable with the given name.
// Used to detect which function parameters need var rebinding.
fn ci_body_assigns_to(session: i64, cursor: i32, name: str) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    // Binary assignment: lhs = rhs (kind 114 = BinaryOp)
    if kind == CXK_BINARY_OP:
        let op = with_ci_binary_op(session, cursor)
        if op >= BO_ASSIGN:  // BO_ASSIGN or compound assign
            let nc = with_ci_num_children(session, cursor)
            if nc >= 1:
                let lhs = with_ci_child(session, cursor, 0)
                // Check if LHS is a DeclRefExpr with the param name
                if with_ci_cursor_kind(session, lhs) == CXK_DECL_REF:
                    if with_ci_cursor_spelling(session, lhs) == name:
                        return true
    // Compound assignment (kind 115)
    if kind == CXK_COMPOUND_ASSIGN_OP:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 1:
            let lhs = with_ci_child(session, cursor, 0)
            if with_ci_cursor_kind(session, lhs) == CXK_DECL_REF:
                if with_ci_cursor_spelling(session, lhs) == name:
                    return true
    // Unary increment/decrement (pre/post)
    if kind == CXK_UNARY_OP:
        let op = with_ci_unary_op(session, cursor)
        if op >= UO_PRE_INC and op <= UO_POST_DEC:
            let nc = with_ci_num_children(session, cursor)
            if nc >= 1:
                let operand = with_ci_child(session, cursor, 0)
                if with_ci_cursor_kind(session, operand) == CXK_DECL_REF:
                    if with_ci_cursor_spelling(session, operand) == name:
                        return true
    // Recurse into children
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        if ci_body_assigns_to(session, with_ci_child(session, cursor, i), name):
            return true
        i = i + 1
    false

// Check if a function body (or any subtree) contains a goto statement.
fn ci_has_goto(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_GOTO_STMT:
        return true
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        if ci_has_goto(session, with_ci_child(session, cursor, i)):
            return true
        i = i + 1
    false

fn ci_subtree_has_labels(session: i64, cursor: i32) -> bool:
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        let child = with_ci_child(session, cursor, i)
        if with_ci_cursor_kind(session, child) == CXK_LABEL_STMT:
            return true
        if ci_subtree_has_labels(session, child):
            return true
        i = i + 1
    false

fn ci_find_substr(haystack: str, needle: str) -> i32:
    let hlen = haystack.len() as i32
    let nlen = needle.len() as i32
    if nlen > hlen: return -1
    var i = 0
    while i <= hlen - nlen:
        if haystack.slice(i as i64, (i + nlen) as i64) == needle:
            return i
        i = i + 1
    -1

// Collect all variable declarations in a goto-lowered function body.
// Names are made unique at the declaration site because all locals are hoisted
// into one With function scope.
fn ci_find_hoisted_var_decl_index(decls: Vec[CiHoistedVarDecl], name: str) -> i32:
    var i = 0
    while i < decls.len() as i32:
        if decls.get(i as i64).name == name:
            return i
        i = i + 1
    -1

fn ci_collect_var_decls(session: i64, cursor: i32, decls_in: Vec[CiHoistedVarDecl]) -> Vec[CiHoistedVarDecl]:
    var decls = decls_in
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_DECL_STMT:
        let nc = with_ci_num_children(session, cursor)
        var i = 0
        while i < nc:
            let child = with_ci_child(session, cursor, i)
            if with_ci_cursor_kind(session, child) == 9:  // CXK_VAR_DECL
                let vname = ci_goto_hoisted_var_name(session, child)
                let vty = with_ci_cursor_type(session, child)
                let vty_str = with_ci_type_translated(session, vty)
                if ci_find_hoisted_var_decl_index(decls, vname) < 0:
                    decls.push(CiHoistedVarDecl { name: vname, ty: vty_str })
            i = i + 1
    let nc = with_ci_num_children(session, cursor)
    var ci = 0
    while ci < nc:
        decls = ci_collect_var_decls(session, with_ci_child(session, cursor, ci), decls)
        ci = ci + 1
    decls

type CiGotoCfg {
    graph: StackifyGraph,
    stmt_blocks: Vec[i32],
    stmt_ids: Vec[i32],
}

type CiGotoCfgContext {
    cfg: CiGotoCfg,
    current: i32 = -1,
    ok: bool = true,
    message: str = "",
    location: str = "",
    label_names: Vec[str],
    label_blocks: Vec[i32],
    label_defined: Vec[i32],
    break_targets: Vec[i32],
    continue_targets: Vec[i32],
    switch_cases: CiGotoSwitchCase,
}

type CiGotoSwitchCaseState {
    values: Vec[i32],
    blocks: Vec[i32],
    has_default: bool = false,
    default_block: i32 = -1,
}

type CiGotoSwitchCase {
    state: *mut CiGotoSwitchCaseState,
}
impl Copy for CiGotoSwitchCase

type CiStackEmitFrame {
    kind: i32 = 0,
    label_sym: i32 = 0,
}

type CiStackEmitContext {
    cfg: CiGotoCfg,
    frames: Vec[CiStackEmitFrame],
    ok: bool = true,
    message: str = "",
}

let CI_STACK_FRAME_BLOCK: i32 = 1
let CI_STACK_FRAME_LOOP: i32 = 2
let CI_STACK_FRAME_IF: i32 = 3

fn ci_stackify_no_args() -> Vec[i32]:
    Vec.new()

fn ci_goto_cfg_new(entry_desc: str) -> CiGotoCfgContext:
    var graph = StackifyGraph.new(0)
    let entry = graph.add_block(entry_desc)
    CiGotoCfgContext {
        cfg: CiGotoCfg {
            graph,
            stmt_blocks: Vec.new(),
            stmt_ids: Vec.new(),
        },
        current: entry,
        ok: true,
        message: "",
        location: "",
        label_names: Vec.new(),
        label_blocks: Vec.new(),
        label_defined: Vec.new(),
        break_targets: Vec.new(),
        continue_targets: Vec.new(),
        switch_cases: CiGotoSwitchCase { state: 0 as *mut CiGotoSwitchCaseState },
    }

fn CiGotoCfgContext.fail(mut self: CiGotoCfgContext, msg: str, loc: str):
    if self.ok:
        self.ok = false
        self.message = msg
        self.location = loc
        g_ci_bail_message = msg
        g_ci_bail_location = loc
        g_ci_bail_kind = CXK_GOTO_STMT

fn CiGotoCfgContext.new_block(mut self: CiGotoCfgContext, desc: str) -> i32:
    self.cfg.graph.add_block(desc)

fn CiGotoCfgContext.block_has_term(self: &CiGotoCfgContext, block: i32) -> bool:
    if block < 0 or block >= self.cfg.graph.blocks.len() as i32:
        return true
    let b = self.cfg.graph.blocks.get(block as i64)
    b.term_kind == StackifyTermKind.Br or b.term_kind == StackifyTermKind.CondBr or b.term_kind == StackifyTermKind.Return or b.term_kind == StackifyTermKind.Unreachable or b.term_kind == StackifyTermKind.Select

fn CiGotoCfgContext.block_has_pred(self: &CiGotoCfgContext, target: i32) -> bool:
    if target < 0 or target >= self.cfg.graph.blocks.len() as i32:
        return false
    var bi = 0
    while bi < self.cfg.graph.blocks.len() as i32:
        let block = self.cfg.graph.blocks.get(bi as i64)
        var si = 0
        while si < block.succs_count:
            if self.cfg.graph.succs.get((block.succs_start + si) as i64) == target:
                return true
            si = si + 1
        bi = bi + 1
    false

fn CiGotoCfgContext.set_current(mut self: CiGotoCfgContext, block: i32):
    if not self.ok:
        return
    self.current = block

fn CiGotoCfgContext.append_stmt(mut self: CiGotoCfgContext, stmts: CiStmtPool, stmt_id: CiStmtId) -> void:
    if not self.ok or self.current < 0 or (stmt_id as i32) == 0:
        return
    let kind = stmts.kind(stmt_id)
    if kind == CiStmtKind.CIS_BLOCK and stmts.get_d2(stmt_id) == 0:
        let start = stmts.get_d0(stmt_id)
        let count = stmts.get_d1(stmt_id)
        var i = 0
        while i < count:
            self.append_stmt(stmts, (stmts.get_extra(start + i)) as CiStmtId)
            i = i + 1
        return
    self.cfg.stmt_blocks.push(self.current)
    self.cfg.stmt_ids.push(stmt_id as i32)

fn CiGotoCfgContext.branch_current(mut self: CiGotoCfgContext, target: i32, loc: str):
    if not self.ok:
        return
    if self.current < 0:
        return
    if self.block_has_term(self.current):
        self.current = -1
        return
    if target < 0:
        self.fail("goto CFG branch target is invalid", loc)
        return
    self.cfg.graph.set_br(self.current, target, ci_stackify_no_args())
    self.current = -1

fn CiGotoCfgContext.cond_current(mut self: CiGotoCfgContext, cond: CiExprId, true_block: i32, false_block: i32, loc: str):
    if not self.ok:
        return
    if self.current < 0:
        return
    if (cond as i32) == 0 or true_block < 0 or false_block < 0:
        self.fail("goto CFG conditional branch is invalid", loc)
        return
    self.cfg.graph.set_cond_br(self.current, cond as i32, true_block, ci_stackify_no_args(), false_block, ci_stackify_no_args())
    self.current = -1

fn CiGotoCfgContext.return_current(mut self: CiGotoCfgContext, values: Vec[i32]):
    if not self.ok or self.current < 0:
        return
    self.cfg.graph.set_return(self.current, values)
    self.current = -1

fn CiGotoCfgContext.unreachable_current(mut self: CiGotoCfgContext):
    if not self.ok or self.current < 0:
        return
    self.cfg.graph.set_unreachable(self.current)
    self.current = -1

fn CiGotoCfgContext.find_label(self: &CiGotoCfgContext, name: str) -> i32:
    var i = 0
    while i < self.label_names.len() as i32:
        if self.label_names.get(i as i64) == name:
            return i
        i = i + 1
    -1

fn CiGotoCfgContext.get_label_block(mut self: CiGotoCfgContext, name: str) -> i32:
    let found = self.find_label(name)
    if found >= 0:
        return self.label_blocks.get(found as i64)
    let block = self.new_block("label " ++ name)
    self.label_names.push(name)
    self.label_blocks.push(block)
    self.label_defined.push(0)
    block

fn CiGotoCfgContext.define_label(mut self: CiGotoCfgContext, name: str, loc: str) -> i32:
    let block = self.get_label_block(name)
    let idx = self.find_label(name)
    if idx >= 0:
        if self.label_defined.get(idx as i64) != 0:
            self.fail("duplicate C label '" ++ name ++ "'", loc)
            return block
        self.label_defined.set_i32(idx as i64, 1)
    block

fn ci_goto_cfg_target_label_from_goto(session: i64, cursor: i32) -> str:
    let nc = with_ci_num_children(session, cursor)
    if nc > 0:
        let child_name = with_ci_cursor_spelling(session, with_ci_child(session, cursor, 0))
        if child_name.len() > 0:
            return child_name
    with_ci_cursor_spelling(session, cursor)

fn CiGotoCfgContext.push_break_target(self: CiGotoCfgContext, target: i32) -> void:
    self.break_targets.push(target)

fn CiGotoCfgContext.pop_break_target(self: CiGotoCfgContext):
    if self.break_targets.len() > 0:
        let _ = self.break_targets.pop()

fn CiGotoCfgContext.push_continue_target(self: CiGotoCfgContext, target: i32) -> void:
    self.continue_targets.push(target)

fn CiGotoCfgContext.pop_continue_target(self: CiGotoCfgContext):
    if self.continue_targets.len() > 0:
        let _ = self.continue_targets.pop()

fn ci_goto_cfg_top_target(stack: &Vec[i32]) -> i32:
    if stack.len() == 0:
        return -1
    stack.get(stack.len() - 1)

fn CiGotoCfgContext.append_lowered_leaf(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope):
    if not self.ok or self.current < 0:
        return
    let stmt_id = stmts.lower_stmt_ir(session, cursor, exprs, types, 0, scope)
    if (stmt_id as i32) != 0:
        self.append_stmt(stmts, stmt_id)
        return
    if not ci_is_null_like_stmt(session, cursor):
        if g_ci_bail_message.len() > 0:
            self.fail(g_ci_bail_message, g_ci_bail_location)
        else:
            self.fail("unsupported statement in goto CFG", with_ci_cursor_location(session, cursor))

fn CiGotoCfgContext.lower_return(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope):
    if not self.ok or self.current < 0:
        return
    let nc = with_ci_num_children(session, cursor)
    let values: Vec[i32] = Vec.new()
    if nc == 0:
        self.return_current(values)
        return
    let ret_child = with_ci_child(session, cursor, 0)
    let lowered_ret = stmts.lower_value_expr_ir(session, ret_child, exprs, types, scope)
    if not ci_value_ir_valid(lowered_ret):
        self.fail("unsupported return expression in goto CFG", with_ci_cursor_location(session, ret_child))
        return
    self.append_stmt(stmts, lowered_ret.setup_stmt)
    var ret_value = lowered_ret.value_expr
    let ret_peeled = ci_peel_transparent(session, ret_child)
    if ci_cursor_is_array_type(session, ret_peeled):
        let elem_ty = ci_array_elem_type_from_cursor(session, ret_peeled)
        if elem_ty.len() > 0:
            let elem_ty_id = types.named_type_from_text(elem_ty)
            if (elem_ty_id as i32) == 0:
                self.fail("unsupported array return type in goto CFG", with_ci_cursor_location(session, ret_child))
                return
            ret_value = exprs.add(CiExprKind.CIE_ARRAY_DECAY, ret_value as i32, elem_ty_id as i32, 0, 0 as CiTypeId)
    values.push(ret_value as i32)
    self.return_current(values)

fn CiGotoCfgContext.lower_compound(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope):
    let nc = with_ci_num_children(session, cursor)
    var block_scope = scope
    let block_mark = ci_scope_mark(block_scope)
    var i = 0
    while i < nc and self.ok:
        let child = with_ci_child(session, cursor, i)
        let ck = with_ci_cursor_kind(session, child)
        if self.current < 0:
            if ck == CXK_DECL_STMT:
                block_scope = ci_goto_scope_add_decl_mappings(session, child, block_scope)
            else if ck == CXK_LABEL_STMT or ci_subtree_has_labels(session, child):
                self.lower_stmt(session, child, stmts, exprs, types, block_scope)
                if ck == CXK_LABEL_STMT:
                    block_scope = ci_goto_scope_after_label_stmt(session, child, block_scope)
            i = i + 1
            continue
        if ck == CXK_DECL_STMT:
            let decl_ir = stmts.lower_decl_stmt_structural(session, child, block_scope, true, exprs, types)
            block_scope = decl_ir.updated_scope
            self.append_stmt(stmts, decl_ir.stmt_id)
        else:
            self.lower_stmt(session, child, stmts, exprs, types, block_scope)
            if ck == CXK_LABEL_STMT:
                block_scope = ci_goto_scope_after_label_stmt(session, child, block_scope)
        i = i + 1
    let _ = ci_scope_restore(block_scope, block_mark)

fn CiGotoCfgContext.lower_if(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope):
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        self.fail("malformed if statement in goto CFG", with_ci_cursor_location(session, cursor))
        return
    if self.current < 0:
        if ci_subtree_has_labels(session, cursor):
            self.lower_stmt(session, with_ci_child(session, cursor, 1), stmts, exprs, types, scope)
            if nc > 2:
                self.lower_stmt(session, with_ci_child(session, cursor, 2), stmts, exprs, types, scope)
        return
    let cond_cursor = with_ci_child(session, cursor, 0)
    let prepared_cond = stmts.prepare_stmt_condition_ir(session, cond_cursor, exprs, types, scope)
    if not ci_value_ir_valid(prepared_cond):
        self.fail("unsupported if condition in goto CFG", with_ci_cursor_location(session, cond_cursor))
        return
    self.append_stmt(stmts, prepared_cond.setup_stmt)
    let then_block = self.new_block("if then")
    let else_block = if nc > 2: self.new_block("if else") else: self.new_block("if after")
    let after_block = if nc > 2: self.new_block("if after") else: else_block
    self.cond_current(prepared_cond.value_expr, then_block, else_block, with_ci_cursor_location(session, cursor))

    self.set_current(then_block)
    self.lower_stmt(session, with_ci_child(session, cursor, 1), stmts, exprs, types, scope)
    let then_alive = self.current >= 0
    if then_alive:
        self.branch_current(after_block, with_ci_cursor_location(session, cursor))

    var else_alive = false
    if nc > 2:
        self.set_current(else_block)
        self.lower_stmt(session, with_ci_child(session, cursor, 2), stmts, exprs, types, scope)
        else_alive = self.current >= 0
        if else_alive:
            self.branch_current(after_block, with_ci_cursor_location(session, cursor))
    else:
        else_alive = true

    self.set_current(after_block)
    if not (then_alive or else_alive):
        if not self.block_has_pred(after_block):
            self.unreachable_current()

fn CiGotoCfgContext.lower_while(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope):
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        self.fail("malformed while statement in goto CFG", with_ci_cursor_location(session, cursor))
        return
    let cond_block = self.new_block("while cond")
    let body_block = self.new_block("while body")
    let after_block = self.new_block("while after")
    self.branch_current(cond_block, with_ci_cursor_location(session, cursor))

    self.set_current(cond_block)
    let cond_cursor = with_ci_child(session, cursor, 0)
    let prepared_cond = stmts.prepare_stmt_condition_ir(session, cond_cursor, exprs, types, scope)
    if not ci_value_ir_valid(prepared_cond):
        self.fail("unsupported while condition in goto CFG", with_ci_cursor_location(session, cond_cursor))
        return
    self.append_stmt(stmts, prepared_cond.setup_stmt)
    self.cond_current(prepared_cond.value_expr, body_block, after_block, with_ci_cursor_location(session, cursor))

    self.push_break_target(after_block)
    self.push_continue_target(cond_block)
    self.set_current(body_block)
    self.lower_stmt(session, with_ci_child(session, cursor, 1), stmts, exprs, types, scope)
    if self.current >= 0:
        self.branch_current(cond_block, with_ci_cursor_location(session, cursor))
    self.pop_continue_target()
    self.pop_break_target()
    self.set_current(after_block)
    if not self.block_has_pred(after_block):
        self.unreachable_current()

fn CiGotoCfgContext.lower_do(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope):
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        self.fail("malformed do statement in goto CFG", with_ci_cursor_location(session, cursor))
        return
    let body_block = self.new_block("do body")
    let cond_block = self.new_block("do cond")
    let after_block = self.new_block("do after")
    self.branch_current(body_block, with_ci_cursor_location(session, cursor))
    self.push_break_target(after_block)
    self.push_continue_target(cond_block)
    self.set_current(body_block)
    self.lower_stmt(session, with_ci_child(session, cursor, 0), stmts, exprs, types, scope)
    if self.current >= 0:
        self.branch_current(cond_block, with_ci_cursor_location(session, cursor))
    self.pop_continue_target()
    self.pop_break_target()

    self.set_current(cond_block)
    let cond_cursor = with_ci_child(session, cursor, 1)
    let prepared_cond = stmts.prepare_stmt_condition_ir(session, cond_cursor, exprs, types, scope)
    if not ci_value_ir_valid(prepared_cond):
        self.fail("unsupported do condition in goto CFG", with_ci_cursor_location(session, cond_cursor))
        return
    self.append_stmt(stmts, prepared_cond.setup_stmt)
    self.cond_current(prepared_cond.value_expr, body_block, after_block, with_ci_cursor_location(session, cursor))
    self.set_current(after_block)
    if not self.block_has_pred(after_block):
        self.unreachable_current()

fn CiGotoCfgContext.lower_for(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope):
    let parts = ci_extract_for_parts(session, cursor)
    let scope_mark = ci_scope_mark(scope)
    if parts.body_cursor < 0:
        self.fail("malformed for statement in goto CFG", with_ci_cursor_location(session, cursor))
        return
    var loop_scope = scope
    if self.current >= 0 and parts.init_cursor >= 0:
        if with_ci_cursor_kind(session, parts.init_cursor) == CXK_DECL_STMT:
            let decl_ir = stmts.lower_decl_stmt_structural(session, parts.init_cursor, loop_scope, true, exprs, types)
            loop_scope = decl_ir.updated_scope
            self.append_stmt(stmts, decl_ir.stmt_id)
        else:
            let init_id = stmts.lower_stmt_expr_ir(session, parts.init_cursor, exprs, types, loop_scope)
            if (init_id as i32) == 0:
                self.fail("unsupported for initializer in goto CFG", with_ci_cursor_location(session, parts.init_cursor))
                let _ = ci_scope_restore(loop_scope, scope_mark)
                return
            self.append_stmt(stmts, init_id)

    let cond_block = self.new_block("for cond")
    let body_block = self.new_block("for body")
    let inc_block = self.new_block("for inc")
    let after_block = self.new_block("for after")
    self.branch_current(cond_block, with_ci_cursor_location(session, cursor))

    self.set_current(cond_block)
    if parts.cond_cursor >= 0:
        let prepared_cond = stmts.prepare_stmt_condition_ir(session, parts.cond_cursor, exprs, types, loop_scope)
        if not ci_value_ir_valid(prepared_cond):
            self.fail("unsupported for condition in goto CFG", with_ci_cursor_location(session, parts.cond_cursor))
            let _ = ci_scope_restore(loop_scope, scope_mark)
            return
        self.append_stmt(stmts, prepared_cond.setup_stmt)
        self.cond_current(prepared_cond.value_expr, body_block, after_block, with_ci_cursor_location(session, cursor))
    else:
        self.branch_current(body_block, with_ci_cursor_location(session, cursor))

    self.push_break_target(after_block)
    self.push_continue_target(inc_block)
    self.set_current(body_block)
    self.lower_stmt(session, parts.body_cursor, stmts, exprs, types, loop_scope)
    if self.current >= 0:
        self.branch_current(inc_block, with_ci_cursor_location(session, cursor))
    self.pop_continue_target()
    self.pop_break_target()

    self.set_current(inc_block)
    if parts.inc_cursor >= 0:
        let inc_id = stmts.lower_stmt_expr_ir(session, parts.inc_cursor, exprs, types, loop_scope)
        if (inc_id as i32) == 0:
            self.fail("unsupported for increment in goto CFG", with_ci_cursor_location(session, parts.inc_cursor))
            let _ = ci_scope_restore(loop_scope, scope_mark)
            return
        self.append_stmt(stmts, inc_id)
    self.branch_current(cond_block, with_ci_cursor_location(session, cursor))
    self.set_current(after_block)
    if not self.block_has_pred(after_block):
        self.unreachable_current()
    let _ = ci_scope_restore(loop_scope, scope_mark)

fn ci_goto_switch_case_new() -> CiGotoSwitchCase:
    let ptr = with_alloc(sizeof[CiGotoSwitchCaseState]()) as *mut CiGotoSwitchCaseState
    unsafe:
        *ptr = CiGotoSwitchCaseState {
            values: Vec.new(),
            blocks: Vec.new(),
            has_default: false,
            default_block: -1,
        }
    CiGotoSwitchCase { state: ptr }

fn CiGotoSwitchCase.record_case(self: CiGotoSwitchCase, value: CiExprId, block: i32) -> void:
    self.state.values.push(value as i32)
    self.state.blocks.push(block)

fn CiGotoCfgContext.lower_case_children(mut self: CiGotoCfgContext, session: i64, cursor: i32, first_child: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope, cases: CiGotoSwitchCase):
    let saved_cases = self.switch_cases
    self.switch_cases = cases
    let case_mark = ci_scope_mark(scope)
    var case_scope = scope
    let nc = with_ci_num_children(session, cursor)
    var i = first_child
    while i < nc and self.ok:
        let child = with_ci_child(session, cursor, i)
        let ck = with_ci_cursor_kind(session, child)
        if ck == CXK_CASE_STMT or ck == CXK_DEFAULT_STMT:
            self.lower_case_node(session, child, stmts, exprs, types, case_scope, cases)
            ci_goto_switch_scope_after_case(session, child, case_scope)
            i = i + 1
            continue
        if ck == CXK_DECL_STMT:
            if self.current >= 0:
                let decl_ir = stmts.lower_decl_stmt_structural(session, child, case_scope, true, exprs, types)
                case_scope = decl_ir.updated_scope
                self.append_stmt(stmts, decl_ir.stmt_id)
            else:
                case_scope = ci_goto_scope_add_decl_mappings(session, child, case_scope)
            i = i + 1
            continue
        self.lower_stmt(session, child, stmts, exprs, types, case_scope)
        if ck == CXK_LABEL_STMT:
            case_scope = ci_goto_scope_after_label_stmt(session, child, case_scope)
        i = i + 1
    let _ = ci_scope_restore(scope, case_mark)
    self.switch_cases = saved_cases

fn CiGotoCfgContext.lower_case_node(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope, cases: CiGotoSwitchCase):
    if not self.ok:
        return
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)
    if kind == CXK_CASE_STMT:
        if nc < 1:
            self.fail("malformed case label in goto CFG", with_ci_cursor_location(session, cursor))
            return
        let case_val = exprs.lower_case_value_ir(session, with_ci_child(session, cursor, 0), types, scope)
        if (case_val as i32) == 0:
            self.fail("unsupported case value in goto CFG", with_ci_cursor_location(session, cursor))
            return
        cases.record_case(case_val, self.current)
        if nc >= 2:
            self.lower_case_children(session, cursor, 1, stmts, exprs, types, scope, cases)
        return
    if kind == CXK_DEFAULT_STMT:
        cases.state.has_default = true
        cases.state.default_block = self.current
        if nc >= 1:
            self.lower_case_children(session, cursor, 0, stmts, exprs, types, scope, cases)
        return
    self.fail("expected switch case/default in goto CFG", with_ci_cursor_location(session, cursor))

fn CiGotoCfgContext.lower_switch_body(mut self: CiGotoCfgContext, session: i64, body_cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope, cases: CiGotoSwitchCase):
    let saved_cases = self.switch_cases
    self.switch_cases = cases
    let nc = with_ci_num_children(session, body_cursor)
    let switch_mark = ci_scope_mark(scope)
    var switch_scope = scope
    var i = 0
    while i < nc and self.ok:
        let child = with_ci_child(session, body_cursor, i)
        let ck = with_ci_cursor_kind(session, child)
        if ck == CXK_CASE_STMT or ck == CXK_DEFAULT_STMT:
            let case_block = self.new_block("switch case")
            if self.current >= 0:
                self.branch_current(case_block, with_ci_cursor_location(session, child))
            self.set_current(case_block)
            self.lower_case_node(session, child, stmts, exprs, types, switch_scope, cases)
            ci_goto_switch_scope_after_case(session, child, switch_scope)
            i = i + 1
            continue
        if self.current < 0:
            if ck == CXK_DECL_STMT:
                switch_scope = ci_goto_scope_add_decl_mappings(session, child, switch_scope)
            else if ck == CXK_LABEL_STMT or ci_subtree_has_labels(session, child):
                self.lower_stmt(session, child, stmts, exprs, types, switch_scope)
                if ck == CXK_LABEL_STMT:
                    switch_scope = ci_goto_scope_after_label_stmt(session, child, switch_scope)
            i = i + 1
            continue
        if ck == CXK_DECL_STMT:
            let decl_ir = stmts.lower_decl_stmt_structural(session, child, switch_scope, true, exprs, types)
            switch_scope = decl_ir.updated_scope
            self.append_stmt(stmts, decl_ir.stmt_id)
            i = i + 1
            continue
        self.lower_stmt(session, child, stmts, exprs, types, switch_scope)
        if ck == CXK_LABEL_STMT:
            switch_scope = ci_goto_scope_after_label_stmt(session, child, switch_scope)
        i = i + 1
    let _ = ci_scope_restore(scope, switch_mark)
    self.switch_cases = saved_cases

fn CiGotoCfgContext.emit_switch_dispatch(mut self: CiGotoCfgContext, exprs: CiExprPool, subject_id: CiExprId, dispatch_block: i32, after_block: i32, cases: CiGotoSwitchCase, loc: str):
    if not self.ok:
        return
    let value_count = cases.state.values.len() as i32
    if value_count == 0:
        let target = if cases.state.has_default: cases.state.default_block else: after_block
        self.current = dispatch_block
        self.branch_current(target, loc)
        return
    var chain_block = dispatch_block
    var i = 0
    while i < value_count and self.ok:
        let case_value = cases.state.values.get(i as i64) as CiExprId
        let case_block = cases.state.blocks.get(i as i64)
        let false_block = if i == value_count - 1:
            if cases.state.has_default: cases.state.default_block else: after_block
        else:
            self.new_block("switch dispatch")
        let cond = exprs.binary(CiBinOp.CIBO_EQ, subject_id, case_value, 0 as CiTypeId)
        self.current = chain_block
        self.cond_current(cond, case_block, false_block, loc)
        chain_block = false_block
        i = i + 1

fn CiGotoCfgContext.lower_switch(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope):
    let nc = with_ci_num_children(session, cursor)
    if nc < 2:
        self.fail("malformed switch statement in goto CFG", with_ci_cursor_location(session, cursor))
        return
    if self.current < 0:
        let body_cursor = with_ci_child(session, cursor, 1)
        if ci_subtree_has_labels(session, body_cursor):
            var dead_cases = ci_goto_switch_case_new()
            self.lower_switch_body(session, body_cursor, stmts, exprs, types, scope, dead_cases)
        return
    let subject_cursor = with_ci_child(session, cursor, 0)
    let body_cursor = with_ci_child(session, cursor, 1)
    let prepared_subject = stmts.prepare_stmt_subject_ir(session, subject_cursor, exprs, types, scope, "switch")
    if not ci_value_ir_valid(prepared_subject):
        self.fail("unsupported switch subject in goto CFG", with_ci_cursor_location(session, subject_cursor))
        return
    self.append_stmt(stmts, prepared_subject.setup_stmt)
    let dispatch_block = self.new_block("switch dispatch")
    let after_block = self.new_block("switch after")
    self.branch_current(dispatch_block, with_ci_cursor_location(session, cursor))

    self.push_break_target(after_block)
    var cases = ci_goto_switch_case_new()
    self.current = -1
    self.lower_switch_body(session, body_cursor, stmts, exprs, types, scope, cases)
    if self.current >= 0:
        self.branch_current(after_block, with_ci_cursor_location(session, cursor))
    self.pop_break_target()
    self.emit_switch_dispatch(exprs, prepared_subject.value_expr, dispatch_block, after_block, cases, with_ci_cursor_location(session, cursor))
    self.set_current(after_block)
    if not self.block_has_pred(after_block):
        self.unreachable_current()

fn CiGotoCfgContext.lower_stmt(mut self: CiGotoCfgContext, session: i64, cursor: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool, scope: CiScope):
    if not self.ok:
        return
    let kind = with_ci_cursor_kind(session, cursor)
    let nc = with_ci_num_children(session, cursor)
    if kind == CXK_UNEXPOSED_STMT:
        if nc == 1:
            self.lower_stmt(session, with_ci_child(session, cursor, 0), stmts, exprs, types, scope)
            return
        let inner_expr = ci_find_last_expr_child(session, cursor)
        if inner_expr >= 0 and self.current >= 0:
            self.append_lowered_leaf(session, cursor, stmts, exprs, types, scope)
        return
    if kind == CXK_NULL_STMT:
        return
    if kind == CXK_LABEL_STMT:
        let label_name = with_ci_cursor_spelling(session, cursor)
        if label_name.len() == 0:
            self.fail("empty C label in goto CFG", with_ci_cursor_location(session, cursor))
            return
        let label_block = self.define_label(label_name, with_ci_cursor_location(session, cursor))
        if self.current >= 0 and self.current != label_block:
            self.branch_current(label_block, with_ci_cursor_location(session, cursor))
        self.set_current(label_block)
        if nc > 0:
            var child_cursor = with_ci_child(session, cursor, 0)
            var child_kind = with_ci_cursor_kind(session, child_cursor)
            while child_kind == CXK_LABEL_STMT and self.ok:
                let inner_name = with_ci_cursor_spelling(session, child_cursor)
                if inner_name.len() == 0:
                    self.fail("empty C label in goto CFG", with_ci_cursor_location(session, child_cursor))
                    return
                let inner_block = self.define_label(inner_name, with_ci_cursor_location(session, child_cursor))
                if self.current >= 0 and self.current != inner_block:
                    self.branch_current(inner_block, with_ci_cursor_location(session, child_cursor))
                self.set_current(inner_block)
                if with_ci_num_children(session, child_cursor) == 0:
                    return
                child_cursor = with_ci_child(session, child_cursor, 0)
                child_kind = with_ci_cursor_kind(session, child_cursor)
            if (child_kind == CXK_CASE_STMT or child_kind == CXK_DEFAULT_STMT) and (self.switch_cases.state as i64) != 0:
                self.lower_case_node(session, child_cursor, stmts, exprs, types, scope, self.switch_cases)
            else:
                self.lower_stmt(session, child_cursor, stmts, exprs, types, scope)
        return
    if kind == CXK_GOTO_STMT:
        let target_label = ci_goto_cfg_target_label_from_goto(session, cursor)
        if target_label.len() == 0:
            self.fail("computed or unresolved goto in goto CFG", with_ci_cursor_location(session, cursor))
            return
        let target = self.get_label_block(target_label)
        self.branch_current(target, with_ci_cursor_location(session, cursor))
        return
    if kind == CXK_BREAK_STMT:
        let target = ci_goto_cfg_top_target(&self.break_targets)
        if target < 0:
            self.fail("break without active target in goto CFG", with_ci_cursor_location(session, cursor))
            return
        self.branch_current(target, with_ci_cursor_location(session, cursor))
        return
    if kind == CXK_CONTINUE_STMT:
        let target = ci_goto_cfg_top_target(&self.continue_targets)
        if target < 0:
            self.fail("continue without active loop in goto CFG", with_ci_cursor_location(session, cursor))
            return
        self.branch_current(target, with_ci_cursor_location(session, cursor))
        return
    if kind == CXK_RETURN_STMT:
        self.lower_return(session, cursor, stmts, exprs, types, scope)
        return
    if kind == CXK_COMPOUND_STMT:
        self.lower_compound(session, cursor, stmts, exprs, types, scope)
        return
    if kind == CXK_IF_STMT:
        self.lower_if(session, cursor, stmts, exprs, types, scope)
        return
    if kind == CXK_WHILE_STMT:
        self.lower_while(session, cursor, stmts, exprs, types, scope)
        return
    if kind == CXK_FOR_STMT:
        self.lower_for(session, cursor, stmts, exprs, types, scope)
        return
    if kind == CXK_DO_STMT:
        self.lower_do(session, cursor, stmts, exprs, types, scope)
        return
    if kind == CXK_SWITCH_STMT:
        self.lower_switch(session, cursor, stmts, exprs, types, scope)
        return
    if kind == CXK_DECL_STMT:
        if self.current >= 0:
            let decl_ir = stmts.lower_decl_stmt_structural(session, cursor, scope, true, exprs, types)
            self.append_stmt(stmts, decl_ir.stmt_id)
        return
    if kind == CXK_CASE_STMT or kind == CXK_DEFAULT_STMT:
        self.fail("case/default outside switch in goto CFG", with_ci_cursor_location(session, cursor))
        return
    if ci_cursor_kind_is_expression(kind):
        self.append_lowered_leaf(session, cursor, stmts, exprs, types, scope)
        return
    if self.current >= 0:
        self.fail("unsupported statement in goto CFG", with_ci_cursor_location(session, cursor))



fn CiStackEmitContext.fail(mut self: CiStackEmitContext, msg: str):
    if self.ok:
        self.ok = false
        self.message = msg
        g_ci_bail_message = msg
    return

fn CiStackEmitContext.push_frame(mut self: CiStackEmitContext, kind: i32, label_sym: i32):
    self.frames.push(CiStackEmitFrame { kind, label_sym })
    return

fn CiStackEmitContext.pop_frame(mut self: CiStackEmitContext):
    if self.frames.len() > 0:
        let _ = self.frames.pop()
    return

fn CiStackEmitContext.resolve_frame(mut self: CiStackEmitContext, depth: i32) -> CiStackEmitFrame:
    if depth < 0 or depth >= self.frames.len() as i32:
        self.fail("stackify emitter: branch depth out of range")
        return CiStackEmitFrame {}
    self.frames.get((self.frames.len() as i32 - 1 - depth) as i64)

fn CiStmtPool.stack_emit_stmt_block(self: CiStmtPool, ids: &Vec[i32]) -> CiStmtId:
    if ids.len() == 0:
        return 0 as CiStmtId
    if ids.len() == 1:
        return ids.get(0) as CiStmtId
    let start = self.extra_len()
    var i: i64 = 0
    while i < ids.len():
        let _ = self.add_extra(ids.get(i))
        i = i + 1
    self.block(start, ids.len() as i32)

fn CiStackEmitContext.leaf(mut self: CiStackEmitContext, stmts: CiStmtPool, block: i32) -> CiStmtId:
    let ids: Vec[i32] = Vec.new()
    var i: i64 = 0
    while i < self.cfg.stmt_ids.len():
        if self.cfg.stmt_blocks.get(i) == block:
            ids.push(self.cfg.stmt_ids.get(i))
        i = i + 1
    stmts.stack_emit_stmt_block(&ids)

fn CiStackEmitContext.children(mut self: CiStackEmitContext, tree: StackifyTree, start: i32, count: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool) -> CiStmtId:
    let ids: Vec[i32] = Vec.new()
    var i = 0
    while i < count and self.ok:
        let node_id = tree.children.get((start + i) as i64)
        let stmt_id = self.node(tree, node_id, stmts, exprs, types)
        if (stmt_id as i32) != 0:
            ids.push(stmt_id as i32)
        i = i + 1
    stmts.stack_emit_stmt_block(&ids)

fn CiStackEmitContext.param_transfer(mut self: CiStackEmitContext, tree: StackifyTree, node: StackifyNode, stmts: CiStmtPool) -> CiStmtId:
    if node.values_count == 0 and node.to_values_count == 0:
        return 0 as CiStmtId
    if node.values_count != node.to_values_count:
        self.fail("stackify emitter: parameter transfer arity mismatch")
        return 0 as CiStmtId
    let ids: Vec[i32] = Vec.new()
    var i = 0
    while i < node.values_count:
        let from_expr = tree.values.get((node.values_start + i) as i64) as CiExprId
        let to_expr = tree.values.get((node.to_values_start + i) as i64) as CiExprId
        ids.push(stmts.assign(to_expr, from_expr) as i32)
        i = i + 1
    stmts.stack_emit_stmt_block(&ids)

fn CiStackEmitContext.emit_return(mut self: CiStackEmitContext, tree: StackifyTree, node: StackifyNode, stmts: CiStmtPool) -> CiStmtId:
    if node.values_count == 0:
        return stmts.return_(0 as CiExprId)
    if node.values_count == 1:
        return stmts.return_(tree.values.get(node.values_start as i64) as CiExprId)
    self.fail("stackify emitter: multiple return values are not supported")
    0 as CiStmtId

fn CiStackEmitContext.node(mut self: CiStackEmitContext, tree: StackifyTree, node_id: i32, stmts: CiStmtPool, exprs: CiExprPool, types: CiTypePool) -> CiStmtId:
    if not self.ok:
        return 0 as CiStmtId
    let node = tree.nodes.get(node_id as i64)
    if node.kind == StackifyNodeKind.Leaf:
        return self.leaf(stmts, node.block)
    if node.kind == StackifyNodeKind.Block:
        let label_sym = stmts.add_string("__ci_s_" ++ i64_to_string(node_id as i64))
        self.push_frame(CI_STACK_FRAME_BLOCK, label_sym)
        let body = self.children(tree, node.first_child_start, node.first_child_count, stmts, exprs, types)
        self.pop_frame()
        var ids: Vec[i32] = if (body as i32) != 0: ci_stmt_collect_flat_ids(stmts, body) else: Vec.new()
        let start = stmts.extra_len()
        var i: i64 = 0
        while i < ids.len():
            let _ = stmts.add_extra(ids.get(i))
            i = i + 1
        return stmts.block_labeled(start, ids.len() as i32, label_sym)
    if node.kind == StackifyNodeKind.Loop:
        let label_sym = stmts.add_string("__ci_s_" ++ i64_to_string(node_id as i64))
        self.push_frame(CI_STACK_FRAME_LOOP, label_sym)
        let body = self.children(tree, node.first_child_start, node.first_child_count, stmts, exprs, types)
        self.pop_frame()
        let true_cond = exprs.bool_lit(1, 0 as CiTypeId)
        return stmts.while_labeled(true_cond, body, label_sym)
    if node.kind == StackifyNodeKind.Br:
        let frame = self.resolve_frame(node.label)
        if not self.ok:
            return 0 as CiStmtId
        if frame.kind == CI_STACK_FRAME_LOOP:
            return stmts.continue_label(frame.label_sym)
        if frame.kind == CI_STACK_FRAME_BLOCK:
            return stmts.break_label(frame.label_sym)
        self.fail("stackify emitter: branch resolved to non-label frame")
        return 0 as CiStmtId
    if node.kind == StackifyNodeKind.If:
        self.push_frame(CI_STACK_FRAME_IF, 0)
        let then_id = self.children(tree, node.first_child_start, node.first_child_count, stmts, exprs, types)
        let else_id = self.children(tree, node.second_child_start, node.second_child_count, stmts, exprs, types)
        self.pop_frame()
        return stmts.if_stmt(node.value as CiExprId, then_id, else_id)
    if node.kind == StackifyNodeKind.ParamTransfer:
        return self.param_transfer(tree, node, stmts)
    if node.kind == StackifyNodeKind.Return:
        return self.emit_return(tree, node, stmts)
    if node.kind == StackifyNodeKind.Unreachable:
        return 0 as CiStmtId
    self.fail("stackify emitter: unsupported stackify node")
    0 as CiStmtId

fn CiStmtPool.stack_emit_tree(self: CiStmtPool, tree: StackifyTree, cfg: CiGotoCfg, exprs: CiExprPool, types: CiTypePool) -> CiStmtId:
    var ctx = CiStackEmitContext {
        cfg,
        frames: Vec.new(),
        ok: true,
        message: "",
    }
    let ids: Vec[i32] = Vec.new()
    var i = 0
    while i < tree.roots_count and ctx.ok:
        let node_id = tree.children.get((tree.roots_start + i) as i64)
        let stmt_id = ctx.node(tree, node_id, self.val(), exprs, types)
        if (stmt_id as i32) != 0:
            ids.push(stmt_id as i32)
        i = i + 1
    if not ctx.ok:
        return 0 as CiStmtId
    self.stack_emit_stmt_block(&ids)

fn ci_native_goto_fail(msg: str) -> CiStmtId:
    g_ci_bail_kind = CXK_GOTO_STMT
    g_ci_bail_message = msg
    0 as CiStmtId

fn CiStmtPool.native_goto_label_syms(self: CiStmtPool, cfg: CiGotoCfg) -> Vec[i32]:
    let labels: Vec[i32] = Vec.new()
    var block: i32 = 0
    while block < cfg.graph.blocks.len() as i32:
        labels.push(self.add_string("__ci_bb_" ++ i64_to_string(block as i64)))
        block = block + 1
    labels

fn ci_native_goto_collect_leaf_ids(cfg: CiGotoCfg, block: i32) -> Vec[i32]:
    var out: Vec[i32] = Vec.new()
    var i: i64 = 0
    while i < cfg.stmt_ids.len():
        if cfg.stmt_blocks.get(i) == block:
            out.push(cfg.stmt_ids.get(i))
        i = i + 1
    out

fn ci_goto_cfg_reachable_blocks(cfg: CiGotoCfg) -> Vec[i32]:
    let reachable: Vec[i32] = Vec.new()
    let worklist: Vec[i32] = Vec.new()
    let block_count = cfg.graph.blocks.len() as i32
    var i = 0
    while i < block_count:
        reachable.push(0)
        i = i + 1

    if cfg.graph.entry < 0 or cfg.graph.entry >= block_count:
        return reachable

    let entry_i = cfg.graph.entry as i64
    with reachable.slot(entry_i) as mut entry_slot:
        entry_slot.set(1)
    worklist.push(cfg.graph.entry)

    var wi: i64 = 0
    while wi < worklist.len():
        let current = worklist.get(wi)
        let block = cfg.graph.blocks.get(current as i64)
        var si = 0
        while si < block.succs_count:
            let succ = cfg.graph.succs.get((block.succs_start + si) as i64)
            if succ >= 0 and succ < block_count and reachable.get(succ as i64) == 0:
                let succ_i = succ as i64
                with reachable.slot(succ_i) as mut succ_slot:
                    succ_slot.set(1)
                worklist.push(succ)
            si = si + 1
        wi = wi + 1
    reachable

fn CiStmtPool.native_goto_unreachable_stmt(self: CiStmtPool, exprs: CiExprPool) -> CiStmtId:
    let name = exprs.add_string("unreachable")
    let callee = exprs.ident(name, 0 as CiTypeId)
    let args_start = exprs.extra_len()
    let call = exprs.add(CiExprKind.CIE_CALL, callee as i32, args_start, 0, 0 as CiTypeId)
    self.expr_stmt(call)

fn CiStmtPool.native_goto_single_goto(self: CiStmtPool, label_sym: i32) -> CiStmtId:
    self.goto_label(label_sym)

fn CiStmtPool.native_goto_emit_terminator(self: CiStmtPool, cfg: CiGotoCfg, block: i32, labels: &Vec[i32], exprs: CiExprPool) -> CiStmtId:
    if block < 0 or block >= cfg.graph.blocks.len() as i32:
        return ci_native_goto_fail("native goto emitter: block out of range")
    let b = cfg.graph.blocks.get(block as i64)
    if b.term_kind == StackifyTermKind.Br:
        if b.targets_count != 1:
            return ci_native_goto_fail("native goto emitter: malformed branch terminator")
        let target = cfg.graph.targets.get(b.targets_start as i64).block
        if target < 0 or target >= labels.len() as i32:
            return ci_native_goto_fail("native goto emitter: branch target out of range")
        return self.native_goto_single_goto(labels.get(target as i64))

    if b.term_kind == StackifyTermKind.CondBr:
        if b.targets_count != 2 or b.cond_value == 0:
            return ci_native_goto_fail("native goto emitter: malformed conditional branch")
        let true_target = cfg.graph.targets.get(b.targets_start as i64).block
        let false_target = cfg.graph.targets.get((b.targets_start + 1) as i64).block
        if true_target < 0 or true_target >= labels.len() as i32 or false_target < 0 or false_target >= labels.len() as i32:
            return ci_native_goto_fail("native goto emitter: conditional target out of range")
        let then_id = self.native_goto_single_goto(labels.get(true_target as i64))
        let else_id = self.native_goto_single_goto(labels.get(false_target as i64))
        return self.if_stmt(b.cond_value as CiExprId, then_id, else_id)

    if b.term_kind == StackifyTermKind.Return:
        if b.return_values_count == 0:
            return self.return_(0 as CiExprId)
        if b.return_values_count == 1:
            return self.return_(cfg.graph.return_values.get(b.return_values_start as i64) as CiExprId)
        return ci_native_goto_fail("native goto emitter: multiple return values are not supported")

    if b.term_kind == StackifyTermKind.Unreachable:
        return self.native_goto_unreachable_stmt(exprs)

    if b.term_kind == StackifyTermKind.Select:
        return ci_native_goto_fail("native goto emitter: select terminator is not supported")

    ci_native_goto_fail("native goto emitter: block has no terminator: " ++ i64_to_string(block as i64) ++ " " ++ b.desc)

fn CiExprPool.default_for_ci_type(self: CiExprPool, ty_id: CiTypeId, types: CiTypePool) -> CiExprId:
    let tk = types.kind(ty_id)
    if tk == CiTypeKind.CT_POINTER or tk == CiTypeKind.CT_FN_PTR:
        return self.null_ptr(ty_id)
    if tk == CiTypeKind.CT_BOOL:
        return self.bool_lit(0, ty_id)
    if tk == CiTypeKind.CT_FLOAT:
        let idx = self.add_string("0.0")
        return self.add(CiExprKind.CIE_FLOAT_LIT, idx, 0, 0, ty_id)
    if tk == CiTypeKind.CT_STRUCT or tk == CiTypeKind.CT_ARRAY:
        return 0 as CiExprId
    if tk == CiTypeKind.CT_NAMED:
        let name = types.get_string(types.get_d0(ty_id))
        if ci_starts_with(name, "*"):
            return self.null_ptr(ty_id)
        if name == "bool":
            return self.bool_lit(0, ty_id)
        if name == "f32" or name == "f64" or name == "c_longdouble":
            let idx = self.add_string("0.0")
            return self.add(CiExprKind.CIE_FLOAT_LIT, idx, 0, 0, ty_id)
        if not ci_starts_with(name, "c_") and name != "u8" and name != "u16" and name != "u32" and name != "u64" and name != "i8" and name != "i16" and name != "i32" and name != "i64" and name != "usize" and name != "isize":
            return 0 as CiExprId
    let zero_idx = self.add_string("0")
    self.int_lit(zero_idx, ty_id)

fn CiStmtPool.native_goto_emit_cfg(self: CiStmtPool, cfg: CiGotoCfg, hoisted_stmt_ids: &Vec[i32], exprs: CiExprPool, types: CiTypePool) -> CiStmtId:
    let labels = self.native_goto_label_syms(cfg)
    if cfg.graph.entry < 0 or cfg.graph.entry >= labels.len() as i32:
        return ci_native_goto_fail("native goto emitter: entry block out of range")
    let reachable = ci_goto_cfg_reachable_blocks(cfg)

    let ids: Vec[i32] = Vec.new()
    var hi: i64 = 0
    while hi < hoisted_stmt_ids.len():
        ids.push(hoisted_stmt_ids.get(hi))
        hi = hi + 1

    let replace_ids: Vec[i32] = Vec.new()
    var ri: i64 = 0
    while ri < cfg.stmt_ids.len():
        let sid = cfg.stmt_ids.get(ri) as CiStmtId
        if self.kind(sid) == CiStmtKind.CIS_VAR_DECL:
            let name_sym = self.get_d0(sid)
            let ty_id = self.get_d1(sid) as CiTypeId
            let init_expr = self.get_d2(sid) as CiExprId
            let flags = self.get_flags(sid)
            let is_mut = flags & 1
            let zero = exprs.default_for_ci_type(ty_id, types)
            ids.push(self.var_decl(name_sym, ty_id, zero, is_mut) as i32)
            if (init_expr as i32) != 0:
                let name_str = self.get_string(name_sym)
                let lhs_sym = exprs.add_string(name_str)
                let lhs = exprs.ident(lhs_sym, ty_id)
                replace_ids.push(self.assign(lhs, init_expr) as i32)
            else:
                replace_ids.push(0)
        else:
            replace_ids.push(0)
        ri = ri + 1

    ids.push(self.goto_label(labels.get(cfg.graph.entry as i64)) as i32)

    var block: i32 = 0
    while block < cfg.graph.blocks.len() as i32:
        if reachable.get(block as i64) == 0:
            block = block + 1
            continue
        let block_ids: Vec[i32] = Vec.new()
        var li: i64 = 0
        while li < cfg.stmt_ids.len():
            if cfg.stmt_blocks.get(li) == block:
                let rep = replace_ids.get(li)
                if rep != 0:
                    block_ids.push(rep)
                else if self.kind(cfg.stmt_ids.get(li) as CiStmtId) != CiStmtKind.CIS_VAR_DECL:
                    block_ids.push(cfg.stmt_ids.get(li))
            li = li + 1
        let term = self.native_goto_emit_terminator(cfg, block, &labels, exprs)
        if (term as i32) == 0:
            return 0 as CiStmtId
        block_ids.push(term as i32)

        let start = self.extra_len()
        var bi: i64 = 0
        while bi < block_ids.len():
            let _ = self.add_extra(block_ids.get(bi))
            bi = bi + 1
        ids.push(self.block_labeled(start, block_ids.len() as i32, labels.get(block as i64)) as i32)
        block = block + 1

    self.from_flat_ids(&ids)

fn CiGotoCfgContext.verify_labels(mut self: CiGotoCfgContext):
    var i = 0
    while i < self.label_names.len() as i32 and self.ok:
        if self.label_defined.get(i as i64) == 0:
            self.fail("unresolved goto label '" ++ self.label_names.get(i as i64) ++ "'", "")
        i = i + 1

fn CiStmtPool.lower_goto_body_stackify(self: CiStmtPool, session: i64, body_cursor: i32, scope: CiScope, exprs: CiExprPool, types: CiTypePool) -> CiStmtId:
    var hoisted_decls: Vec[CiHoistedVarDecl] = Vec.new()
    hoisted_decls = ci_collect_var_decls(session, body_cursor, hoisted_decls)

    var hoisted_stmt_ids: Vec[i32] = Vec.new()
    var hvi: i32 = 0
    while hvi < hoisted_decls.len() as i32:
        let decl = hoisted_decls.get(hvi as i64)
        let default_val = ci_default_for_type(decl.ty)
        let name_idx = self.add_string(decl.name)
        let ty_id = types.named_type_from_text(decl.ty)
        if (ty_id as i32) == 0:
            g_ci_bail_location = with_ci_cursor_location(session, body_cursor)
            g_ci_bail_kind = CXK_COMPOUND_STMT
            g_ci_bail_message = "unsupported hoisted local type in goto CFG"
            return 0 as CiStmtId
        let init_id = exprs.default_expr_from_text(default_val)
        let decl_id = self.var_decl(name_idx, ty_id, init_id, 1)
        hoisted_stmt_ids.push(decl_id as i32)
        hvi = hvi + 1

    var ctx = ci_goto_cfg_new("entry")
    ctx.lower_compound(session, body_cursor, self.val(), exprs, types, scope)
    if ctx.ok and ctx.current >= 0:
        let reachable = ci_goto_cfg_reachable_blocks(ctx.cfg)
        if ctx.current < reachable.len() as i32 and reachable.get(ctx.current as i64) == 0:
            ctx.unreachable_current()
        else:
            let ret_ty = ci_scope_get_return_type(scope)
            if ret_ty == "void" or ret_ty.len() == 0:
                let values: Vec[i32] = Vec.new()
                ctx.return_current(values)
            else:
                ctx.fail("goto CFG function can fall through without returning", with_ci_cursor_location(session, body_cursor))
    ctx.verify_labels()
    if not ctx.ok:
        return 0 as CiStmtId

    if not migrate_convert_goto_to_structured():
        return self.native_goto_emit_cfg(ctx.cfg, &hoisted_stmt_ids, exprs, types)

    let result = stackify_graph(ctx.cfg.graph)
    if not result.ok:
        g_ci_bail_location = if ctx.location.len() > 0: ctx.location else: with_ci_cursor_location(session, body_cursor)
        g_ci_bail_message = "stackify: " ++ result.message
        g_ci_bail_kind = CXK_GOTO_STMT
        return 0 as CiStmtId
    let body_id = self.stack_emit_tree(result.tree, ctx.cfg, exprs, types)
    if (body_id as i32) == 0:
        if g_ci_bail_message.len() == 0:
            g_ci_bail_message = "stackify emitter produced no body"
        if g_ci_bail_location.len() == 0:
            g_ci_bail_location = with_ci_cursor_location(session, body_cursor)
        g_ci_bail_kind = CXK_GOTO_STMT
        return 0 as CiStmtId
    var ids: Vec[i32] = Vec.new()
    var hi: i64 = 0
    while hi < hoisted_stmt_ids.len():
        ids.push(hoisted_stmt_ids.get(hi))
        hi = hi + 1
    let body_ids = ci_stmt_collect_flat_ids(self.val(), body_id)
    var bi: i32 = 0
    while bi < body_ids.len() as i32:
        ids.push(body_ids.get(bi as i64))
        bi = bi + 1
    self.from_flat_ids(&ids)

// Find a function cursor in the cursor tree by name.
fn ci_find_var_cursor(session: i64, name: str) -> i32:
    let root = with_ci_root_cursor(session)
    let n = with_ci_num_children(session, root)
    var fallback = -1
    var i = 0
    while i < n:
        let child = with_ci_child(session, root, i)
        if with_ci_cursor_kind(session, child) == CXK_VAR_DECL:
            let cname = with_ci_cursor_spelling(session, child)
            if cname == name:
                if with_ci_num_children(session, child) > 0:
                    return child
                if fallback < 0:
                    fallback = child
        i = i + 1
    fallback

fn ci_cursor_kind_is_expr(kind: i32) -> bool:
    kind >= 100 and kind < 200

fn ci_find_var_init_cursor(session: i64, var_cursor: i32) -> i32:
    let has_init_text = ci_var_decl_has_initializer_text(with_ci_cursor_source_text(session, var_cursor))
    if not has_init_text:
        let var_ty = with_ci_type_translated(session, with_ci_cursor_type(session, var_cursor))
        if var_ty.len() > 0 and var_ty.byte_at(0) == 91:
            return -1
    let nc = with_ci_num_children(session, var_cursor)
    var i = nc - 1
    while i >= 0:
        let child = with_ci_child(session, var_cursor, i)
        if ci_cursor_kind_is_expr(with_ci_cursor_kind(session, child)):
            return child
        i = i - 1
    if not has_init_text:
        return -1
    -1

fn ci_find_last_expr_child(session: i64, cursor: i32) -> i32:
    let nc = with_ci_num_children(session, cursor)
    var i = nc - 1
    while i >= 0:
        let child = with_ci_child(session, cursor, i)
        if ci_cursor_kind_is_expr(with_ci_cursor_kind(session, child)):
            return child
        i = i - 1
    -1

fn ci_expr_children_need_rvalue_lowering(session: i64, cursor: i32) -> bool:
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        let child = with_ci_child(session, cursor, i)
        if ci_cursor_kind_is_expr(with_ci_cursor_kind(session, child)) and ci_rvalue_needs_lowering(session, child):
            return true
        i = i + 1
    false

fn ci_decl_name_matches_type(decl_name: str, ty_name: str) -> bool:
    decl_name == ty_name or ci_escape_reserved(decl_name) == ty_name

fn ci_struct_field_emitted_name(session: i64, idx: i32, fi: i32) -> str:
    let anon_kind = with_cimport_struct_field_is_anonymous_record(session, idx, fi)
    let fname = with_cimport_struct_field_name(session, idx, fi)
    if anon_kind != 0:
        if fname.len() > 0:
            return ci_escape_reserved(fname)
        var anon_idx = 0
        var ai = 0
        while ai <= fi:
            if with_cimport_struct_field_is_anonymous_record(session, idx, ai) != 0:
                if ai == fi:
                    return "anon_" ++ i64_to_string(anon_idx as i64)
                anon_idx = anon_idx + 1
            ai = ai + 1
    let actual_name = if fname.len() == 0: f"unnamed_{fi}" else: fname
    ci_escape_reserved(actual_name)

fn ci_type_field_count(session: i64, ty_name: str) -> i32:
    if ty_name.len() == 0:
        return 0
    let decl_count = with_cimport_decl_count(session)
    var i = 0
    while i < decl_count:
        let kind = with_cimport_decl_kind(session, i)
        let decl_name = with_cimport_decl_name(session, i)
        if (kind == CK_STRUCT or kind == CK_UNION) and ci_decl_name_matches_type(decl_name, ty_name):
            let count = with_cimport_struct_field_count(session, i)
            if count > 0:
                return count
        if kind == CK_TYPEDEF and ci_decl_name_matches_type(decl_name, ty_name):
            let anon_count = with_cimport_typedef_anon_record_field_count(session, i)
            if anon_count > 0:
                return anon_count
            let underlying = with_cimport_typedef_underlying_translated(session, i)
            if underlying.len() > 0 and underlying != ty_name:
                return ci_type_field_count(session, underlying)
            return 0
        i = i + 1
    0

fn ci_type_field_name(session: i64, ty_name: str, field_idx: i32) -> str:
    if ty_name.len() == 0 or field_idx < 0:
        return ""
    let decl_count = with_cimport_decl_count(session)
    var i = 0
    while i < decl_count:
        let kind = with_cimport_decl_kind(session, i)
        let decl_name = with_cimport_decl_name(session, i)
        if (kind == CK_STRUCT or kind == CK_UNION) and ci_decl_name_matches_type(decl_name, ty_name):
            let count = with_cimport_struct_field_count(session, i)
            if count == 0:
                i = i + 1
                continue
            if field_idx >= count:
                return ""
            return ci_struct_field_emitted_name(session, i, field_idx)
        if kind == CK_TYPEDEF and ci_decl_name_matches_type(decl_name, ty_name):
            let anon_count = with_cimport_typedef_anon_record_field_count(session, i)
            if anon_count > 0:
                if field_idx >= anon_count:
                    return ""
                let fname = with_cimport_typedef_anon_field_name(session, i, field_idx)
                let actual_fname = if fname.len() == 0: f"unnamed_{field_idx}" else: fname
                return ci_escape_reserved(actual_fname)
            let underlying = with_cimport_typedef_underlying_translated(session, i)
            if underlying.len() > 0 and underlying != ty_name:
                return ci_type_field_name(session, underlying, field_idx)
            return ""
        i = i + 1
    ""

fn ci_type_field_type(session: i64, ty_name: str, field_idx: i32) -> str:
    if ty_name.len() == 0 or field_idx < 0:
        return ""
    let decl_count = with_cimport_decl_count(session)
    var i = 0
    while i < decl_count:
        let kind = with_cimport_decl_kind(session, i)
        let decl_name = with_cimport_decl_name(session, i)
        if (kind == CK_STRUCT or kind == CK_UNION) and ci_decl_name_matches_type(decl_name, ty_name):
            let count = with_cimport_struct_field_count(session, i)
            if count == 0:
                i = i + 1
                continue
            if field_idx >= count:
                return ""
            return with_cimport_struct_field_type_translated(session, i, field_idx)
        if kind == CK_TYPEDEF and ci_decl_name_matches_type(decl_name, ty_name):
            let anon_count = with_cimport_typedef_anon_record_field_count(session, i)
            if anon_count > 0:
                if field_idx >= anon_count:
                    return ""
                return with_cimport_typedef_anon_field_type(session, i, field_idx)
            let underlying = with_cimport_typedef_underlying_translated(session, i)
            if underlying.len() > 0 and underlying != ty_name:
                return ci_type_field_type(session, underlying, field_idx)
            return ""
        i = i + 1
    ""

fn ci_coerce_init_value_for_type(value: str, ty: str) -> str:
    if value == "0" and (ci_starts_with(ty, "*") or ci_starts_with(ty, "Option[")):
        return "null"
    if ty.len() > 0 and ty.byte_at(0) == 91 and (ci_is_string_literal(value) or ci_is_concatenated_string(value)):
        let rendered = ci_render_string_literal_as_byte_array(value, ty)
        if rendered.len() > 0:
            return rendered
    if ci_starts_with(ty, "*") and ci_is_string_literal(value):
        return value
    value

fn ci_find_fn_cursor(session: i64, name: str) -> i32:
    let root = with_ci_root_cursor(session)
    let n = with_ci_num_children(session, root)
    var i = 0
    while i < n:
        let child = with_ci_child(session, root, i)
        if with_ci_cursor_kind(session, child) == CK_FUNCTION:
            let cname = with_ci_cursor_spelling(session, child)
            if cname == name:
                if with_ci_cursor_is_definition(session, child) != 0:
                    return child
        i = i + 1
    -1

// Cast memcpy args: (dst, src, n) → (dst as *i8, src as *i8, n as i64)
fn ci_cast_memcpy_args(args: str) -> str:
    let first_comma = ci_find_arg_comma(args, 0)
    if first_comma < 0: return args
    let second_comma = ci_find_arg_comma(args, first_comma + 1)
    if second_comma < 0: return args
    let dst = ci_trim(args.slice(0, first_comma as i64))
    let src = ci_trim(args.slice((first_comma + 1) as i64, second_comma as i64))
    let n = ci_trim(args.slice((second_comma + 1) as i64, args.len()))
    dst ++ " as *i8, " ++ src ++ " as *i8, " ++ n ++ " as i64"

// Cast memset args: (ptr, c, n) → (ptr as *i8, c, n as i64)
fn ci_cast_memset_args(args: str) -> str:
    let first_comma = ci_find_arg_comma(args, 0)
    if first_comma < 0: return args
    let second_comma = ci_find_arg_comma(args, first_comma + 1)
    if second_comma < 0: return args
    let ptr = ci_trim(args.slice(0, first_comma as i64))
    let c = ci_trim(args.slice((first_comma + 1) as i64, second_comma as i64))
    let n = ci_trim(args.slice((second_comma + 1) as i64, args.len()))
    ptr ++ " as *i8, " ++ c ++ ", " ++ n ++ " as i64"

// Cast memcmp args: (a, b, n) → (a as *i8, b as *i8, n as i64)
fn ci_cast_memcmp_args(args: str) -> str:
    let first_comma = ci_find_arg_comma(args, 0)
    if first_comma < 0: return args
    let second_comma = ci_find_arg_comma(args, first_comma + 1)
    if second_comma < 0: return args
    let a = ci_trim(args.slice(0, first_comma as i64))
    let b = ci_trim(args.slice((first_comma + 1) as i64, second_comma as i64))
    let n = ci_trim(args.slice((second_comma + 1) as i64, args.len()))
    a ++ " as *i8, " ++ b ++ " as *i8, " ++ n ++ " as i64"

// Find the Nth comma in args string at depth 0 (respecting parens)
fn ci_find_arg_comma(args: str, start: i32) -> i32:
    var depth = 0
    var i = start
    let alen = args.len() as i32
    while i < alen:
        let c = args.byte_at(i as i64)
        if c == 40: depth = depth + 1      // (
        else if c == 41: depth = depth - 1  // )
        else if c == 44 and depth == 0:     // ,
            return i
        i = i + 1
    -1

// Strip the last comma-separated argument from an args string.
// "a, b, c, d" → "a, b, c"
fn ci_strip_last_arg(args: str) -> str:
    var last_comma = -1
    var depth = 0
    var i = 0
    let alen = args.len() as i32
    while i < alen:
        let c = args.byte_at(i as i64)
        if c == 40: depth = depth + 1      // (
        else if c == 41: depth = depth - 1  // )
        else if c == 44 and depth == 0:     // ,
            last_comma = i
        i = i + 1
    if last_comma > 0:
        return args.slice(0, last_comma as i64)
    args

// Get the Nth pipe-delimited entry from a string like "|a||b||c|"
fn ci_get_nth_pipe_entry(entries: str, n: i32) -> str:
    if entries.len() == 0: return ""
    var idx = 0
    var pos = 1  // skip leading |
    let elen = entries.len() as i32
    while pos < elen:
        var end = pos
        while end < elen and entries.byte_at(end as i64) != 124:
            end = end + 1
        if idx == n:
            return entries.slice(pos as i64, end as i64)
        idx = idx + 1
        pos = end + 1
        if pos < elen and entries.byte_at(pos as i64) == 124:
            pos = pos + 1
    ""

// Check if a source location path is a system header.
fn ci_is_system_path(loc: str) -> bool:
    if ci_starts_with(loc, "/usr/"): return true
    if ci_starts_with(loc, "/Library/"): return true
    if ci_starts_with(loc, "/Applications/Xcode"): return true
    if ci_str_contains(loc, "/usr/include/"): return true
    if ci_str_contains(loc, "/SDKs/"): return true
    if ci_str_contains(loc, "/clang/"): return true
    false

let CI_LIBC_KIND_FN: i32 = 1
let CI_LIBC_KIND_VAR: i32 = 2
let CI_LIBC_KIND_TYPE: i32 = 4
let CI_LIBC_PLATFORM_DARWIN: i32 = 1

fn ci_libc_symbol_platforms(name: str) -> i32:
    if name == "__stdinp" or name == "__stdoutp" or name == "__stderrp": return CI_LIBC_PLATFORM_DARWIN
    if name == "__error": return CI_LIBC_PLATFORM_DARWIN
    CI_LIBC_PLATFORM_DARWIN

fn ci_is_libm_fn(name: str) -> bool:
    if name == "sqrt" or name == "pow": return true
    if name == "floor" or name == "ceil" or name == "round": return true
    if name == "sin" or name == "cos" or name == "tan": return true
    if name == "log" or name == "log10" or name == "exp": return true
    if name == "fabs" or name == "fmod": return true
    if name == "asin" or name == "acos" or name == "atan" or name == "atan2": return true
    false

fn ci_libc_symbol_kind_mask(name: str) -> i32:
    if name == "rlimit": return CI_LIBC_KIND_TYPE
    if name == "__stdinp" or name == "__stdoutp" or name == "__stderrp": return CI_LIBC_KIND_VAR
    if name == "fprintf" or name == "printf" or name == "snprintf" or name == "sprintf": return CI_LIBC_KIND_FN
    if name == "fopen" or name == "fclose" or name == "fflush" or name == "fileno": return CI_LIBC_KIND_FN
    if name == "fgets" or name == "fgetc" or name == "fputc" or name == "fputs": return CI_LIBC_KIND_FN
    if name == "putc" or name == "feof" or name == "fread" or name == "fwrite": return CI_LIBC_KIND_FN
    if name == "strcpy" or name == "strncpy" or name == "strstr" or name == "strerror": return CI_LIBC_KIND_FN
    if name == "strtol" or name == "strtoul" or name == "setlocale": return CI_LIBC_KIND_FN
    if name == "isalpha" or name == "isdigit" or name == "isalnum" or name == "isspace": return CI_LIBC_KIND_FN
    if name == "isupper" or name == "islower" or name == "isxdigit" or name == "isprint": return CI_LIBC_KIND_FN
    if name == "isgraph" or name == "ispunct" or name == "iscntrl": return CI_LIBC_KIND_FN
    if name == "tolower" or name == "toupper": return CI_LIBC_KIND_FN
    if ci_is_libm_fn(name): return CI_LIBC_KIND_FN
    if name == "exit" or name == "clock" or name == "time" or name == "isatty": return CI_LIBC_KIND_FN
    if name == "getrlimit" or name == "setrlimit" or name == "__error": return CI_LIBC_KIND_FN
    0

fn ci_libc_symbol_allowed_as(name: str, kind: i32) -> bool:
    (ci_libc_symbol_kind_mask(name) & kind) != 0

fn ci_libc_kind_name(kind: i32) -> str:
    if kind == CI_LIBC_KIND_FN: return "function"
    if kind == CI_LIBC_KIND_VAR: return "variable"
    if kind == CI_LIBC_KIND_TYPE: return "type"
    "symbol"

fn ci_note_filtered_system_symbol_ref(session: i64, name: str, kind: i32) -> bool:
    if name.len() == 0:
        return true
    if ci_libc_symbol_allowed_as(name, kind):
        ci_migrate_note_libc_symbol(name)
        return true
    let loc = ci_get_decl_location(session, name)
    let filtered = ci_is_system_decl(name) or (loc.len() > 0 and ci_is_system_path(loc))
    if not filtered:
        return true
    let loc_suffix = if loc.len() > 0: " from " ++ loc else: ""
    ci_migrate_set_error("migrate: unsupported filtered system " ++ ci_libc_kind_name(kind) ++ " '" ++ name ++ "'" ++ loc_suffix ++ "; add an explicit binding or extend std.libc")
    false

fn ci_note_filtered_system_symbol_ref_at(session: i64, cursor: i32, name: str, kind: i32) -> bool:
    if name.len() == 0:
        return true
    if ci_libc_symbol_allowed_as(name, kind):
        ci_migrate_note_libc_symbol(name)
        return true
    let loc = with_ci_cursor_referenced_location(session, cursor)
    let filtered = ci_is_system_decl(name) or (loc.len() > 0 and ci_is_system_path(loc))
    if not filtered:
        return true
    let loc_suffix = if loc.len() > 0: " from " ++ loc else: ""
    ci_migrate_set_error("migrate: unsupported filtered system " ++ ci_libc_kind_name(kind) ++ " '" ++ name ++ "'" ++ loc_suffix ++ "; add an explicit binding or extend std.libc")
    false

// Check if a declaration name is from a system header (not the user's code).
// This filters out the noise from stdlib.h, string.h, ctype.h, etc.
fn ci_is_system_decl(name: str) -> bool:
    if name.len() == 0: return true
    // Symbols emitted by With's C backend intentionally use reserved C
    // spelling to avoid collisions with user identifiers. They are still
    // source symbols owned by the translation unit, not system declarations.
    if ci_starts_with(name, "__with_"): return false
    // Skip system internal names (__ prefix or _[A-Z]) but keep _pcre2_* etc.
    if name.len() >= 2 and name.byte_at(0) == 95:
        let second = name.byte_at(1)
        if second == 95 or (second >= 65 and second <= 90):
            return true
    // Known system types
    if ci_starts_with(name, "malloc_type") or ci_starts_with(name, "malloc_zone"): return true
    if name == "malloc_zone_t" or name == "malloc_type_id_t": return true
    if name == "size_t" or name == "ssize_t" or name == "ptrdiff_t": return true
    if name == "wchar_t" or name == "wint_t" or name == "ct_rune_t" or name == "rune_t": return true
    if name == "imaxdiv_t" or name == "struct_imaxdiv_t": return true
    if name == "div_t" or name == "ldiv_t" or name == "lldiv_t": return true
    // Known system functions (libc)
    if ci_is_mapped_libc_fn(name): return true
    if ci_is_libm_fn(name): return true
    // Common system functions not in the mapped list
    if name == "alloca" or name == "reallocf" or name == "valloc": return true
    if name == "imaxabs" or name == "imaxdiv" or name == "strtoimax" or name == "strtoumax": return true
    if name == "wcstoimax" or name == "wcstoumax": return true
    if name == "bcmp" or name == "bcopy" or name == "bzero": return true
    if name == "index" or name == "rindex" or name == "ffs" or name == "ffsl" or name == "ffsll": return true
    if name == "fls" or name == "flsl" or name == "flsll": return true
    if name == "strcasecmp" or name == "strncasecmp": return true
    if name == "strsep" or name == "strmode" or name == "swab": return true
    if name == "timingsafe_bcmp" or name == "strsignal_r": return true
    // System type classification functions
    if name == "isascii" or name == "isblank" or name == "iscntrl" or name == "isgraph" or name == "ispunct": return true
    if name == "isalpha" or name == "isdigit" or name == "isalnum" or name == "isspace": return true
    if name == "isupper" or name == "islower" or name == "isxdigit" or name == "isprint": return true
    if name == "tolower" or name == "toupper" or name == "digittoint": return true
    if name == "ishexnumber" or name == "isideogram" or name == "isnumber": return true
    if name == "isphonogram" or name == "isrune" or name == "isspecial": return true
    // macOS target constants and signal/system constants
    if ci_starts_with(name, "TARGET_OS_") or ci_starts_with(name, "TARGET_IPHONE"): return true
    if ci_starts_with(name, "BUS_") or ci_starts_with(name, "CLD_"): return true
    if ci_starts_with(name, "FPE_") or ci_starts_with(name, "ILL_"): return true
    if ci_starts_with(name, "POLL_") or ci_starts_with(name, "SEGV_"): return true
    if ci_starts_with(name, "TRAP_") or ci_starts_with(name, "SA_"): return true
    if ci_starts_with(name, "SIG") or ci_starts_with(name, "SS_"): return true
    if ci_starts_with(name, "MINSIGSTKSZ") or ci_starts_with(name, "NSIG"): return true
    if ci_starts_with(name, "P_ALL") or ci_starts_with(name, "P_PID") or ci_starts_with(name, "P_PGID"): return true
    if ci_starts_with(name, "CAST_") or ci_starts_with(name, "MACH_"): return true
    if ci_starts_with(name, "W") and name.len() <= 12: return true  // WEXITSTATUS, WIFEXITED, etc.
    // __builtin functions
    if ci_starts_with(name, "__builtin"): return true
    // System types from sys/ headers
    if name == "idtype_t" or name == "pid_t" or name == "uid_t" or name == "gid_t": return true
    if name == "id_t" or name == "dev_t" or name == "mode_t" or name == "off_t": return true
    if name == "sig_atomic_t" or name == "sigset_t": return true
    false

// Check if a function name is a libc function that we map to With equivalents.
fn ci_is_mapped_libc_fn(name: str) -> bool:
    if name == "malloc" or name == "free" or name == "calloc" or name == "realloc": return true
    if name == "memcpy" or name == "memmove" or name == "memset" or name == "memcmp": return true
    if name == "strlen" or name == "strcmp" or name == "strncmp" or name == "strchr": return true
    if name == "abort" or name == "exit": return true
    // Also skip common system functions that leak from headers
    if name == "alloca" or name == "reallocf" or name == "valloc": return true
    if name == "aligned_alloc" or name == "posix_memalign": return true
    if name == "strlcpy" or name == "strlcat" or name == "strnstr": return true
    if name == "strtol" or name == "strtoul" or name == "strtod" or name == "atoi": return true
    if name == "snprintf" or name == "sprintf" or name == "printf" or name == "fprintf": return true
    if name == "qsort" or name == "bsearch" or name == "abs": return true
    if name == "memchr" or name == "strstr" or name == "strcpy" or name == "strncpy" or name == "strcat" or name == "strncat": return true
    false

// Map C standard library function calls to With equivalents.
// This enables migrated code to be pure With (no c_import needed).
// Return the structurally-mappable target identifier for a libc
// callee (e.g. "strlen" → "string_len"). Empty string means the
// callee isn't handled structurally and the caller should fall
// through to the text-based ci_map_libc_call.
fn ci_libc_simple_rename(callee: str) -> str:
    if callee == "strlen": return "string_len"
    if callee == "strcmp": return "string_cmp"
    if callee == "strncmp": return "strncmp"
    if callee == "strchr": return "string_find_char"
    ""

fn ci_has_value_libc_call_mapping(callee: str) -> bool:
    if ci_libc_simple_rename(callee).len() > 0:
        return true
    if ci_is_libm_fn(callee):
        return true
    if callee == "malloc" or callee == "free" or callee == "calloc" or callee == "realloc":
        return true
    if callee == "memcpy" or callee == "memmove" or callee == "memset" or callee == "memcmp" or callee == "memchr":
        return true
    if ci_starts_with(callee, "__builtin"):
        return true
    false

// Structural libc-call lowering. For simple-rename callees
// (strlen, strcmp, etc.) builds CIE_CALL with the renamed
// callee ident. For malloc, wraps in the required size cast +
// result *mut c_void cast. Returns 0 for callees that still need
// dedicated structural support (isgraph, ispunct, memcpy arg
// rewrites).
fn CiExprPool.lower_libc_call_structural(self: CiExprPool, session: i64, cursor: i32, callee_text: str, types: CiTypePool, scope: CiScope) -> CiExprId:
    let nc = with_ci_num_children(session, cursor)
    let arg_count = nc - 1
    let renamed = ci_libc_simple_rename(callee_text)
    if ci_is_libm_fn(callee_text):
        ci_trace_port("STRUCTURAL[b11.9.libm_call]")
        var math_args: Vec[i32] = Vec.new()
        var mai: i32 = 1
        while mai < nc:
            let arg_id = self.lower_expr_ir(session, with_ci_child(session, cursor, mai), types, scope)
            if (arg_id as i32) == 0:
                return 0 as CiExprId
            math_args.push(arg_id as i32)
            mai = mai + 1
        return self.build_named_call_expr(callee_text, &math_args)
    if renamed.len() > 0:
        ci_trace_port("STRUCTURAL[b11.9.libc_call]")
        // Lower each argument structurally.
        var arg_ids: Vec[i32] = Vec.new()
        var ai: i32 = 1
        while ai < nc:
            let arg_cursor = with_ci_child(session, cursor, ai)
            let arg_id = self.lower_expr_ir(session, arg_cursor, types, scope)
            if (arg_id as i32) == 0:
                return 0 as CiExprId
            arg_ids.push(arg_id as i32)
            ai = ai + 1
        // Build a new callee ident for the renamed fn.
        let renamed_idx = self.add_string(renamed)
        let renamed_callee = self.ident(renamed_idx, 0 as CiTypeId)
        // Push args into the self.val() pool's extra vec.
        let args_start = self.extra_len() as i32
        var j: i64 = 0
        while j < arg_ids.len():
            let _ = self.add_extra(arg_ids.get(j))
            j = j + 1
        return self.add(CiExprKind.CIE_CALL, renamed_callee as i32, args_start, arg_count, 0 as CiTypeId)
    // malloc(N) → (with_alloc(N as i64) as *mut c_void)
    if callee_text == "malloc":
        if arg_count != 1:
            return 0 as CiExprId
        ci_trace_port("STRUCTURAL[b11.9.libc_call]")
        let arg_cursor = with_ci_child(session, cursor, 1)
        let arg_id = self.lower_expr_ir(session, arg_cursor, types, scope)
        if (arg_id as i32) == 0:
            return 0 as CiExprId
        // Cast arg to i64.
        let i64_idx = types.add_string("i64")
        let i64_ty = types.ty_named(i64_idx)
        let arg_as_i64 = self.cast(i64_ty, arg_id)
        // Build callee ident "with_alloc".
        let wa_idx = self.add_string("with_alloc")
        let wa_callee = self.ident(wa_idx, 0 as CiTypeId)
        // Push arg.
        let args_start = self.extra_len() as i32
        let _ = self.add_extra(arg_as_i64 as i32)
        let call_id = self.add(CiExprKind.CIE_CALL, wa_callee as i32, args_start, 1, 0 as CiTypeId)
        // Wrap in *mut c_void cast.
        let cvoid_idx = types.add_string("c_void")
        let cvoid_ty = types.ty_named(cvoid_idx)
        let void_ptr_ty = types.ty_pointer(cvoid_ty, 0)
        return self.cast(void_ptr_ty, call_id)
    // free(p) → with_free(p as *i8)
    if callee_text == "free":
        if arg_count != 1:
            return 0 as CiExprId
        ci_trace_port("STRUCTURAL[b11.9.libc_call]")
        let arg_cursor = with_ci_child(session, cursor, 1)
        let arg_id = self.lower_expr_ir(session, arg_cursor, types, scope)
        if (arg_id as i32) == 0:
            return 0 as CiExprId
        let i8_idx = types.add_string("i8")
        let i8_ty = types.ty_named(i8_idx)
        let i8_ptr_ty = types.ty_pointer(i8_ty, 0)
        let arg_cast = self.cast(i8_ptr_ty, arg_id)
        let wf_idx = self.add_string("with_free")
        let wf_callee = self.ident(wf_idx, 0 as CiTypeId)
        let args_start = self.extra_len() as i32
        let _ = self.add_extra(arg_cast as i32)
        return self.add(CiExprKind.CIE_CALL, wf_callee as i32, args_start, 1, 0 as CiTypeId)
    // calloc / realloc / memcpy / memmove / memset / memcmp /
    // __builtin_* still need dedicated structural lowering.
    0 as CiExprId

fn ci_map_libc_call(callee: str, args: str) -> str:
    // Memory allocation — use runtime externs with pointer casts.
    // with_alloc returns *i8 but C malloc callers usually assign
    // to a void*-typed variable, so wrap the cast inline instead
    // of doing it as a post-process text rewrite (which can't
    // handle nested parens in the arg text).
    if callee == "malloc":
        return "(with_alloc((" ++ args ++ ") as i64) as *mut c_void)"
    if callee == "free":
        return "with_free((" ++ args ++ ") as *mut u8)"
    if callee == "calloc":
        let count_arg = ci_extract_first_arg(args)
        let size_arg = ci_after_first_arg(args)
        if count_arg.len() == 0 or size_arg.len() == 0:
            return ""
        return "(with_alloc_zeroed((" ++ count_arg ++ ") as i64, (" ++ size_arg ++ ") as i64) as *mut c_void)"
    if callee == "realloc":
        let ptr_arg = ci_extract_first_arg(args)
        let size_arg = ci_after_first_arg(args)
        if ptr_arg.len() == 0 or size_arg.len() == 0:
            return ""
        return "(with_realloc((" ++ ptr_arg ++ ") as *mut u8, 0, (" ++ size_arg ++ ") as i64) as *mut c_void)"

    // Memory operations — cast pointer args to *mut u8 / *const u8
    if callee == "memcpy":
        return "with_memcpy(" ++ ci_cast_memcpy_args(args) ++ ")"
    if callee == "memmove":
        return "with_memmove(" ++ ci_cast_memcpy_args(args) ++ ")"
    if callee == "memset":
        return "with_memset(" ++ ci_cast_memset_args(args) ++ ")"
    if callee == "memcmp":
        return "with_memcmp(" ++ ci_cast_memcmp_args(args) ++ ")"
    if callee == "memchr":
        let first = ci_extract_first_arg(args)
        let rest_start = first.len() as i32 + 1
        if rest_start < args.len() as i32:
            let rest = ci_trim(args.slice(rest_start as i64, args.len()))
            return "(memchr((" ++ first ++ " as *const c_void), " ++ rest ++ ") as *const u8)"
        return "(memchr((" ++ first ++ " as *const c_void)) as *const u8)"

    // String operations
    if callee == "strlen":
        return "string_len(" ++ args ++ ")"
    if callee == "strcmp":
        return "string_cmp(" ++ args ++ ")"
    if callee == "strncmp":
        return "strncmp(" ++ args ++ ")"
    if callee == "strchr":
        return "string_find_char(" ++ args ++ ")"

    // macOS builtin wrappers for memory functions
    // These have an extra bounds-checking arg: (dst, src, n, obj_size) → (dst, src, n)
    if callee == "__builtin___memcpy_chk":
        return "with_memcpy(" ++ ci_cast_memcpy_args(ci_strip_last_arg(args)) ++ ")"
    if callee == "__builtin___memmove_chk":
        return "with_memmove(" ++ ci_cast_memcpy_args(ci_strip_last_arg(args)) ++ ")"
    if callee == "__builtin___memset_chk":
        return "with_memset(" ++ ci_cast_memset_args(ci_strip_last_arg(args)) ++ ")"
    if callee == "__builtin_object_size":
        return "0"  // bounds check size — not needed in With
    // Skip other __builtin functions — emit as 0 or comptime_error
    if ci_starts_with(callee, "__builtin"):
        return "0 // " ++ callee ++ "(" ++ args ++ ")"

    // I/O (keep as extern — these truly need libc)
    // printf, fprintf, snprintf stay as-is (will need c_import for programs that use them)

    // Not a libc function we map
    ""

fn ci_count_substring(haystack: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    var count = 0
    var pos = 0
    let hlen = haystack.len() as i32
    let nlen = needle.len() as i32
    while pos <= hlen - nlen:
        if haystack.slice(pos as i64, (pos + nlen) as i64) == needle:
            count = count + 1
            pos = pos + nlen
        else:
            pos = pos + 1
    count
