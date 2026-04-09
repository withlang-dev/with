// CImport — C header import via libclang bridge.
//
// Parses C headers using libclang (via clang_bridge.c) and generates
// synthetic extern fn / type declarations as .w source text.
// Falls back gracefully when libclang is unavailable.

extern fn with_cimport_add_include_path(path: str) -> void
extern fn with_cimport_clear_include_paths() -> void
extern fn with_cimport_available() -> i32
extern fn with_cimport_parse(header_code: str) -> i64
extern fn with_cimport_dispose(session: i64) -> void
extern fn with_cimport_error(session: i64) -> str
extern fn with_cimport_decl_count(session: i64) -> i32
extern fn with_cimport_decl_kind(session: i64, idx: i32) -> i32
extern fn with_cimport_decl_name(session: i64, idx: i32) -> str
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
extern fn with_cimport_var_is_threadlocal(session: i64, idx: i32) -> i32
extern fn with_cimport_fn_param_type_translated(session: i64, idx: i32, param: i32) -> str
extern fn with_cimport_fn_return_type_translated(session: i64, idx: i32) -> str
extern fn with_cimport_struct_field_type_translated(session: i64, idx: i32, field: i32) -> str
extern fn with_cimport_var_type_translated(session: i64, idx: i32) -> str
extern fn with_cimport_typedef_underlying_translated(session: i64, idx: i32) -> str
extern fn with_cimport_struct_field_is_anonymous_record(session: i64, idx: i32, field: i32) -> i32
extern fn with_cimport_struct_field_anon_field_count(session: i64, idx: i32, field: i32) -> i32
extern fn with_cimport_struct_field_anon_field_name(session: i64, idx: i32, field: i32, sub_field: i32) -> str
extern fn with_cimport_struct_field_anon_field_type(session: i64, idx: i32, field: i32, sub_field: i32) -> str
extern fn with_cimport_struct_is_packed(session: i64, idx: i32) -> i32
extern fn with_cimport_struct_field_offset(session: i64, idx: i32, field: i32) -> i64
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
extern fn with_ci_type_translated(session: i64, ty: i32) -> str
extern fn with_ci_cursor_is_definition(session: i64, cursor: i32) -> i32
extern fn with_ci_cursor_location(session: i64, cursor: i32) -> str
extern fn with_ci_cursor_source_text(session: i64, cursor: i32) -> str
extern fn with_ci_binary_op(session: i64, cursor: i32) -> i32
extern fn with_ci_unary_op(session: i64, cursor: i32) -> i32
extern fn with_ci_eval_int_value(session: i64, cursor: i32) -> i64
extern fn with_ci_eval_int_valid(session: i64, cursor: i32) -> i32
extern fn with_ci_member_field_name(session: i64, cursor: i32) -> str
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
extern fn with_system(cmd: str) -> i32

// CXCursorKind constants (old API — decl-level)
let CK_STRUCT: i32 = 2
let CK_UNION: i32 = 3
let CK_ENUM: i32 = 5
let CK_FUNCTION: i32 = 8
let CK_VAR: i32 = 9
let CK_TYPEDEF: i32 = 20
let CK_STATIC_ASSERT: i32 = 602

// CX_StorageClass constants
let CX_SC_STATIC: i32 = 3

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
let CXK_COMPOUND_LITERAL: i32 = 121
let CXK_VAR_DECL: i32 = 9

// Binary operator constants
let BO_ADD: i32 = 0
let BO_SUB: i32 = 1
let BO_MUL: i32 = 2
let BO_DIV: i32 = 3
let BO_REM: i32 = 4
let BO_AND: i32 = 5
let BO_OR: i32 = 6
let BO_XOR: i32 = 7
let BO_SHL: i32 = 8
let BO_SHR: i32 = 9
let BO_LAND: i32 = 10
let BO_LOR: i32 = 11
let BO_LT: i32 = 12
let BO_GT: i32 = 13
let BO_LE: i32 = 14
let BO_GE: i32 = 15
let BO_EQ: i32 = 16
let BO_NE: i32 = 17
let BO_ASSIGN: i32 = 18
let BO_COMMA: i32 = 19
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

// Implicit cast kind constants
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

// Unary operator constants
let UO_MINUS: i32 = 0
let UO_NOT: i32 = 1
let UO_LNOT: i32 = 2
let UO_ADDR: i32 = 3
let UO_DEREF: i32 = 4
let UO_PLUS: i32 = 5
let UO_PRE_INC: i32 = 6
let UO_PRE_DEC: i32 = 7
let UO_POST_INC: i32 = 8
let UO_POST_DEC: i32 = 9

// Process a c_import header spec and return synthetic .w source text.
// Returns "" if the bridge is unavailable or parsing fails.
fn ci_set_include_paths(paths: Vec[str]):
    with_cimport_clear_include_paths()
    for i in 0..paths.len() as i32:
        with_cimport_add_include_path(paths.get(i as i64))

fn process_c_import(header_spec: str) -> str:
    if with_cimport_available() == 0:
        return ""

    let include_text = ci_build_include_text(header_spec)
    let session = with_cimport_parse(include_text)
    if session == 0:
        return ""

    let err_msg = with_cimport_error(session)
    if err_msg.len() > 0:
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

    // Pre-scan: collect extern var names for macro reference detection
    var extern_vars = ""
    var evi = 0
    while evi < count:
        if with_cimport_decl_kind(session, evi) == CK_VAR:
            let evname = with_cimport_decl_name(session, evi)
            if evname.len() > 0 and evname.byte_at(0) != 95:
                extern_vars = extern_vars ++ "|" ++ evname ++ "|"
        evi = evi + 1

    // Pre-scan: collect all opaque-demoted types (bitfield, forward decl, unsupported)
    // then cascade through field references until fixpoint
    let demoted_types = ci_collect_demoted_types(session, count)

    // Pass 1: Pre-populate name table (Zig-style two-pass).
    // Strong names (functions, variables, typedefs) get priority.
    // Weak names (structs, unions, enums) can be overridden by typedefs.
    // This prevents collisions in the common C pattern: typedef struct Foo { ... } Foo;
    var translated_structs = ""
    let typedef_shadowed = ci_prepopulate_names(session, count)

    var i = 0
    while i < count:
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_FUNCTION:
            output = output ++ ci_translate_function(session, i, translated_structs)
        else if kind == CK_STRUCT or kind == CK_UNION:
            let struct_result = ci_translate_struct(session, i, kind == CK_UNION, translated_structs, demoted_types, typedef_shadowed)
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
            let td_result = ci_translate_typedef(session, i, translated_structs)
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

    with_cimport_dispose(session)

    // Extract macros using a separate preprocessor pass
    let macro_session = with_cimport_parse_macros(include_text)
    if macro_session != 0:
        output = output ++ ci_translate_macros(macro_session, extern_vars)
        with_cimport_dispose_macros(macro_session)

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
                if ci_is_directly_demoted(session, i):
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

fn ci_is_directly_demoted(session: i64, idx: i32) -> bool:
    // Forward declaration — don't demote if a definition exists elsewhere in the TU
    if with_cimport_struct_is_opaque(session, idx) != 0:
        if with_cimport_struct_has_definition(session, idx) != 0:
            return false
        return true
    let field_count = with_cimport_struct_field_count(session, idx)
    // Bitfield in any field
    var fi = 0
    while fi < field_count:
        if with_cimport_struct_field_is_bitfield(session, idx, fi) != 0:
            return true
        let anon_kind = with_cimport_struct_field_is_anonymous_record(session, idx, fi)
        if anon_kind != 0 and with_cimport_struct_field_anon_field_count(session, idx, fi) <= 0:
            return true
        fi = fi + 1
    // Unsupported or opaque field type
    fi = 0
    while fi < field_count:
        let ft = with_cimport_struct_field_type_translated(session, idx, fi)
        if ci_starts_with(ft, "__UNSUPPORTED:"):
            return true
        if ft == "opaque":
            return true
        fi = fi + 1
    false

fn ci_has_demoted_field(session: i64, idx: i32, demoted: str) -> bool:
    if with_cimport_struct_is_opaque(session, idx) != 0:
        return false
    let field_count = with_cimport_struct_field_count(session, idx)
    var fi = 0
    while fi < field_count:
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

fn ci_translate_function(session: i64, idx: i32, known_structs: str) -> str:
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
                let actual_pname = if spname.len() > 0: ci_escape_reserved(spname) else: f"p{spi}"
                si_params = si_params ++ actual_pname ++ ": " ++ sptype
            let si_ret = with_cimport_fn_return_type_translated(session, idx)
            return "fn " ++ safe_name ++ "(" ++ si_params ++ ") -> " ++ si_ret ++ ":\n" ++ body
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

        if pname.len() > 0:
            params = params ++ ci_escape_reserved(pname) ++ ": " ++ ptype
        else:
            params = params ++ f"p{pi}" ++ ": " ++ ptype

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
        return fn_loc_comment ++ "fn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"untranslatable: " ++ unsupported_reason ++ "\")\n"

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
    "fn " ++ safe_struct ++ "." ++ safe_method ++ "(" ++ params ++ ") -> " ++ ret ++ ":\n    " ++ ret_prefix ++ safe_fn_name ++ "(" ++ call_args ++ ")\n"

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
    "fn " ++ safe_struct ++ "." ++ safe_method ++ "(" ++ params ++ ") -> " ++ ret ++ ":\n    " ++ safe_fn_name ++ "(" ++ call_args ++ ")\n"

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

fn ci_translate_struct(session: i64, idx: i32, is_union: bool, known_structs: str, demoted_types: str, typedef_shadowed: str) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip internal names
    if name.byte_at(0) == 95:
        return ""

    // Skip already-emitted names
    // Note: structs shadowed by typedefs (typedef struct Foo {} Foo;) are NOT skipped.
    // The struct emits normally; the typedef detects the self-reference and skips.
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    // Skip forward declarations that have a definition elsewhere in the TU —
    // the definition cursor will be processed later with the actual fields.
    if with_cimport_struct_is_opaque(session, idx) != 0 and with_cimport_struct_has_definition(session, idx) != 0:
        return ""

    // Check if pre-scan marked this type as demoted (bitfield, forward decl,
    // unsupported field, or cascaded from a field whose type was demoted)
    if ci_str_contains(demoted_types, "|" ++ name ++ "|"):
        with_cimport_mark_name_emitted(name)
        let safe_name = ci_escape_reserved(name)
        let loc = ci_get_decl_location(session, name)
        let loc_comment = if loc.len() > 0: "// " ++ loc ++ ": demoted to opaque\n" else: ""
        return loc_comment ++ "type " ++ safe_name ++ " = opaque\n"

    let field_count = with_cimport_struct_field_count(session, idx)
    if field_count == 0:
        // Empty struct definition → emit with padding byte for ABI compatibility
        with_cimport_mark_name_emitted(name)
        let safe_name = ci_escape_reserved(name)
        if is_union:
            return "// union\ntype " ++ safe_name ++ " \{ __pad0: u8 = 0 }\n"
        return "type " ++ safe_name ++ " \{ __pad0: u8 = 0 }\n"

    with_cimport_mark_name_emitted(name)
    let safe_name = ci_escape_reserved(name)

    // Emit anonymous sub-record types before the parent.
    // Naming: Parent_anon_N for unnamed fields, Parent_fieldname for named fields.
    var anon_decls = ""
    var anon_idx = 0
    var afi = 0
    while afi < field_count:
        let anon_kind = with_cimport_struct_field_is_anonymous_record(session, idx, afi)
        if anon_kind != 0:
            let fname = with_cimport_struct_field_name(session, idx, afi)
            let synth_name = if fname.len() > 0: name ++ "_" ++ fname else: f"{name}_anon_{anon_idx}"
            let sub_count = with_cimport_struct_field_anon_field_count(session, idx, afi)
            if sub_count > 0:
                var sub_fields = ""
                var sfi = 0
                while sfi < sub_count:
                    if sfi > 0:
                        sub_fields = sub_fields ++ ", "
                    let sf_name = with_cimport_struct_field_anon_field_name(session, idx, afi, sfi)
                    let sf_type = with_cimport_struct_field_anon_field_type(session, idx, afi, sfi)
                    let actual_sf_name = if sf_name.len() == 0: f"field_{sfi}" else: sf_name
                    sub_fields = sub_fields ++ ci_escape_reserved(actual_sf_name) ++ ": " ++ sf_type
                    sfi = sfi + 1
                if anon_kind == 2:
                    anon_decls = anon_decls ++ "// union\n"
                anon_decls = anon_decls ++ "type " ++ ci_escape_reserved(synth_name) ++ " \{ " ++ sub_fields ++ " }\n"
                with_cimport_mark_name_emitted(synth_name)
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

        let anon_kind = with_cimport_struct_field_is_anonymous_record(session, idx, fi)
        if anon_kind != 0:
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
            flex_accessor = "fn " ++ ci_escape_reserved(accessor_name) ++ "(self: *" ++ safe_name ++ ") -> *" ++ elem_type ++ ":\n    unsafe: ((&self._" ++ ci_escape_reserved(accessor_name) ++ ") as *" ++ elem_type ++ ")\n"

    let packed_prefix = if is_really_packed: "@[packed]\n" else: ""
    let part1 = "type " ++ safe_name
    let part2 = part1 ++ " \{ "
    let part3 = part2 ++ field_str
    let decl = part3 ++ " }\n"
    if is_union:
        return anon_decls ++ "// union\n" ++ packed_prefix ++ decl ++ flex_accessor
    anon_decls ++ packed_prefix ++ decl ++ flex_accessor

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
                return enum_loc_comment ++ "type " ++ ci_escape_reserved(fwd_name) ++ " = opaque\n"
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
            output = output ++ "type " ++ safe_enum_name ++ " = " ++ int_type ++ "\n"

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
        output = output ++ f"let {safe_cname}: {int_type} = {cvalue}\n"
    output

// ── Variable translation ────────────────────────────────────

fn ci_translate_var(session: i64, idx: i32, known_structs: str) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip internal names
    if name.byte_at(0) == 95:
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
        return var_loc_comment ++ "fn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"untranslatable: " ++ reason ++ "\")\n"

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
        let init_val = ci_try_eval_var_init(session, idx)
        if init_val.len() > 0:
            return tl_attr ++ "let " ++ safe_name ++ ": " ++ actual_type ++ " = " ++ init_val ++ "\n"
        tl_attr ++ "extern let " ++ safe_name ++ ": " ++ actual_type ++ "\n"
    else:
        tl_attr ++ "extern var " ++ safe_name ++ ": " ++ actual_type ++ "\n"

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

fn ci_translate_typedef(session: i64, idx: i32, translated_structs: str) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip internal names
    if name.byte_at(0) == 95:
        return ""

    // Skip already-emitted names
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    // Check builtin typedef map first (short-circuits common types)
    let mapped = ci_map_builtin_typedef(name)
    if mapped.len() > 0:
        let safe_name = ci_escape_reserved(name)
        with_cimport_mark_name_emitted(name)
        return "type " ++ safe_name ++ " = " ++ mapped ++ "\n"

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
            if ci_starts_with(ft, "__UNSUPPORTED:") or ft == "opaque":
                anon_has_unsupported = true
            afi = afi + 1
        if anon_has_bitfield or anon_has_unsupported:
            with_cimport_mark_name_emitted(name)
            return "type " ++ anon_safe_name ++ " = opaque\n"
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
        let union_prefix = if with_cimport_typedef_anon_is_union(session, idx) != 0: "// union\n" else: ""
        return union_prefix ++ "type " ++ anon_safe_name ++ " \{ " ++ fields ++ " }\n"

    // Use the recursive type translator for the underlying type
    let translated = with_cimport_typedef_underlying_translated(session, idx)

    // Unsupported underlying type — skip the typedef
    if ci_starts_with(translated, "__UNSUPPORTED:"):
        return ""

    // Don't emit trivial identity typedefs (typedef int → i32, but name isn't special)
    if translated == "i32":
        // Only emit if we know the underlying is actually an interesting type
        let underlying = with_cimport_typedef_underlying(session, idx)
        if not ci_is_known_base_type(underlying):
            if not ci_starts_with(underlying, "struct ") and not ci_starts_with(underlying, "union ") and not ci_starts_with(underlying, "enum "):
                return ""

    // If translated type name equals the typedef name (typedef struct Foo {} Foo;),
    // the typedef is redundant — the struct body was already emitted or needs
    // to be emitted under this name. Skip the self-referential alias.
    if translated == name or translated == ci_escape_reserved(name):
        // The struct was shadowed, so emit nothing — the typedef name IS the struct.
        // Mark as emitted so nothing else claims it.
        with_cimport_mark_name_emitted(name)
        return ""

    let safe_name = ci_escape_reserved(name)
    with_cimport_mark_name_emitted(name)
    "type " ++ safe_name ++ " = " ++ translated ++ "\n"

// ── Macro translation ───────────────────────────────────────

fn ci_translate_macros(session: i64, extern_vars: str) -> str:
    let count = with_cimport_macro_count(session)
    var output = ""
    var known_values = ""
    var blank_macros = ""
    for i in 0..count:
        let name = with_cimport_macro_name(session, i)
        let value = with_cimport_macro_value(session, i)
        let fn_like = with_cimport_macro_is_fn_like(session, i)

        // Skip self-defined macros: #define FOO FOO (common feature-test pattern)
        if fn_like == 0 and value == name:
            continue

        // Try to translate function-like macros; fall back to comptime_error
        if fn_like != 0:
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
                        output = output ++ "fn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"variadic macro — use direct call\")\n"
                        continue
                    // Detect cleanup attribute macros
                    if ci_str_contains(value, "__attribute__((cleanup"):
                        output = output ++ "fn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"cleanup attribute — use defer\")\n"
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
                        output = output ++ "fn " ++ safe_name ++ "(" ++ empty_params ++ ") -> void:\n    return\n"
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
                                output = output ++ "fn " ++ safe_name ++ "(x: str) -> str:\n    x\n"
                                continue
                        output = output ++ "// stringify macro\nfn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"stringify macro: " ++ name ++ "\")\n"
                        continue
                    // Token paste (##) translation
                    if translated.len() == 0 and ci_str_contains(work_value, "##"):
                        translated = ci_try_translate_token_paste(work_value, param_names)
                    if translated.len() == 0:
                        translated = ci_translate_c_expr(work_value, param_names, known_values)
                    if translated.len() > 0:
                        // Infer return type from cast expression: (x as c_int) → return c_int
                        var inferred_ret = ret_type
                        if param_count > 0:
                            let cast_type = ci_infer_cast_return_type(translated)
                            if cast_type.len() > 0:
                                inferred_ret = cast_type
                        output = output ++ "fn " ++ safe_name ++ type_params ++ "(" ++ param_decl ++ ") -> " ++ inferred_ret ++ ":\n    " ++ translated ++ "\n"
                    else:
                        output = output ++ "// untranslatable fn-like macro\nfn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"untranslatable C macro: " ++ name ++ "\")\n"
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
            output = output ++ "let " ++ safe_name ++ ": " ++ int_ty ++ " = " ++ clean_value ++ "\n"
        else if ci_is_char_literal(stripped):
            let char_val = ci_char_to_int(stripped)
            if char_val.len() > 0:
                let safe_name = ci_escape_reserved(name)
                with_cimport_mark_name_emitted(name)
                known_values = known_values ++ name ++ "=" ++ char_val ++ "|"
                output = output ++ "let " ++ safe_name ++ ": c_int = " ++ char_val ++ "\n"
        else if ci_is_float_literal(stripped):
            let safe_name = ci_escape_reserved(name)
            let float_ty = ci_float_type_from_suffix(stripped)
            let clean_value = ci_strip_float_suffix(stripped)
            with_cimport_mark_name_emitted(name)
            output = output ++ "let " ++ safe_name ++ ": " ++ float_ty ++ " = " ++ clean_value ++ "\n"
        else if ci_is_concatenated_string(stripped):
            let safe_name = ci_escape_reserved(name)
            let concat_value = ci_concat_strings(stripped)
            with_cimport_mark_name_emitted(name)
            output = output ++ "let " ++ safe_name ++ " = " ++ concat_value ++ "\n"
        else if ci_is_string_literal(stripped):
            let safe_name = ci_escape_reserved(name)
            with_cimport_mark_name_emitted(name)
            output = output ++ "let " ++ safe_name ++ " = " ++ stripped ++ "\n"
        else:
            let eval_result = ci_eval_const_expr_ctx(stripped, known_values)
            if eval_result.len() > 0:
                let safe_name = ci_escape_reserved(name)
                with_cimport_mark_name_emitted(name)
                known_values = known_values ++ name ++ "=" ++ eval_result ++ "|"
                output = output ++ "let " ++ safe_name ++ ": c_int = " ++ eval_result ++ "\n"
            else:
                // Try expression translation — may reference extern vars
                let expr_result = ci_translate_c_expr(stripped, "", known_values)
                if expr_result.len() > 0:
                    let safe_name = ci_escape_reserved(name)
                    with_cimport_mark_name_emitted(name)
                    if ci_expr_references_var(expr_result, extern_vars):
                        // References a mutable extern var — emit as function
                        output = output ++ "fn " ++ safe_name ++ "() -> c_int:\n    " ++ expr_result ++ "\n"
                    else:
                        output = output ++ "let " ++ safe_name ++ ": c_int = " ++ expr_result ++ "\n"
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
        return ""
    ci_parse_and_expr(s, params, known)

// Level 2: Logical AND  &&
fn ci_parse_and_expr(s: str, params: str, known: str) -> str:
    let pos = ci_find_op_at_depth0(s, "&&")
    if pos >= 0:
        let lhs = ci_parse_and_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_bitor_expr(ci_trim(s.slice((pos + 2) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ ci_ensure_bool(lhs) ++ " and " ++ ci_ensure_bool(rhs) ++ ")"
        return ""
    ci_parse_bitor_expr(s, params, known)

// Level 3: Bitwise OR  |  (not ||)
fn ci_parse_bitor_expr(s: str, params: str, known: str) -> str:
    let pos = ci_find_single_op_at_depth0(s, 124, 124)  // '|' but not '||'
    if pos >= 0:
        let lhs = ci_parse_bitor_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_bitxor_expr(ci_trim(s.slice((pos + 1) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ lhs ++ " | " ++ rhs ++ ")"
        return ""
    ci_parse_bitxor_expr(s, params, known)

// Level 4: Bitwise XOR  ^
fn ci_parse_bitxor_expr(s: str, params: str, known: str) -> str:
    let pos = ci_find_char_op_at_depth0(s, 94)  // '^'
    if pos >= 0:
        let lhs = ci_parse_bitxor_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_bitand_expr(ci_trim(s.slice((pos + 1) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ lhs ++ " ^ " ++ rhs ++ ")"
        return ""
    ci_parse_bitand_expr(s, params, known)

// Level 5: Bitwise AND  &  (not &&)
fn ci_parse_bitand_expr(s: str, params: str, known: str) -> str:
    let pos = ci_find_single_op_at_depth0(s, 38, 38)  // '&' but not '&&'
    if pos >= 0:
        let lhs = ci_parse_bitand_expr(s.slice(0, pos as i64), params, known)
        let rhs = ci_parse_eq_expr(ci_trim(s.slice((pos + 1) as i64, s.len())), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            return "(" ++ lhs ++ " & " ++ rhs ++ ")"
        return ""
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
        return ""
    ci_parse_rel_expr(s, params, known)

// Level 7: Relational  < > <= >=
fn ci_parse_rel_expr(s: str, params: str, known: str) -> str:
    // Find rightmost relational op at depth 0 (to get left-to-right assoc)
    var best_pos = 0 - 1
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
        return ""
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
        return ""
    ci_parse_add_expr(s, params, known)

// Level 9: Additive  + -
fn ci_parse_add_expr(s: str, params: str, known: str) -> str:
    // Find rightmost + or - at depth 0, but not after another operator (unary)
    var best_pos = 0 - 1
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
        return ""
    ci_parse_mul_expr(s, params, known)

// Level 10: Multiplicative  * / %
fn ci_parse_mul_expr(s: str, params: str, known: str) -> str:
    // Find rightmost * / % at depth 0
    var best_pos = 0 - 1
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
        return ""
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
            else if with_cimport_is_name_emitted(base_ident) != 0:
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
        return 0 - 1
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
    0 - 1

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
    0 - 1

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
    0 - 1

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
    0 - 1

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
            return "abs(" ++ translated_args ++ ")"
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
        // __builtin_object_size(ptr, type) → (0 - 1) as usize  (unknown size)
        return "0 - 1"

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
            if cast_type == "c_int" or cast_type == "c_uint" or cast_type == "c_long" or cast_type == "c_ulong" or cast_type == "c_longlong" or cast_type == "c_ulonglong" or cast_type == "c_short" or cast_type == "c_ushort" or cast_type == "c_char" or cast_type == "i8" or cast_type == "i16" or cast_type == "i32" or cast_type == "i64" or cast_type == "u8" or cast_type == "u16" or cast_type == "u32" or cast_type == "u64" or cast_type == "f32" or cast_type == "f64" or cast_type == "isize" or cast_type == "usize" or cast_type == "bool":
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
        return 0 - 1
    let limit = text.len() - needle.len()
    for i in 0..limit as i32 + 1:
        if text.slice(i as i64, i as i64 + needle.len()) == needle:
            return i
    0 - 1

fn ci_find_binary_op_ext(s: str) -> i32:
    // Like ci_find_binary_op but also handles comparison and logical ops
    var best_pos = 0 - 1
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
    0 - 1

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
    0 - 1

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
        return t
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
    0 - 1

fn ci_find_matching_brace(s: str, start: i32) -> i32:
    var depth = 0
    var i = start
    while i < s.len() as i32:
        let c = s.byte_at(i as i64)
        if c == 123: depth = depth + 1
        if c == 125:
            depth = depth - 1
            if depth == 0:
                return i
        i = i + 1
    0 - 1

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
    var last_comma = 0 - 1
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
    0 - 1

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
    0 - 1

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
    var best_pos = 0 - 1
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
    0 - 1

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
    0 - 1

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

    // Handle struct/union types — use name if translated, else opaque
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

fn ci_trans_expr(session: i64, cursor: i32, scope: str) -> str:
    let kind = with_ci_cursor_kind(session, cursor)
    let src = with_ci_cursor_source_text(session, cursor)
    let expanded_src = ci_expand_string_macro_sequence(session, src)
    if expanded_src.len() > 0:
        return expanded_src

    // Integer literal
    if kind == CXK_INT_LITERAL:
        if with_ci_eval_int_valid(session, cursor) != 0:
            let ival = with_ci_eval_int_value(session, cursor)
            // Values > i32 max that fit in u32: emit as hex
            if ival > 2147483647 and ival <= 4294967295:
                return ci_i64_to_hex(ival)
            return f"{ival}"
        return with_ci_cursor_source_text(session, cursor)

    // Float literal
    if kind == CXK_FLOAT_LITERAL:
        // Strip C float suffixes (f, F, l, L)
        if src.len() > 0:
            let last = src.byte_at(src.len() - 1)
            if last == 102 or last == 70 or last == 108 or last == 76:
                return src.slice(0, src.len() - 1)
        return src

    // String literal
    if kind == CXK_STRING_LITERAL:
        if ci_is_concatenated_string(src):
            return ci_concat_strings(src)
        // Source text may be a stringify macro like XSTRING(...)
        if src.len() > 0 and src.byte_at(0) != 34:
            let stringify_val = ci_try_expand_stringify_call(session, src)
            if stringify_val.len() > 0:
                return stringify_val
        return src

    // Character literal
    if kind == CXK_CHAR_LITERAL:
        if with_ci_eval_int_valid(session, cursor) != 0:
            return f"{with_ci_eval_int_value(session, cursor)}"
        return with_ci_cursor_source_text(session, cursor)

    // Parenthesized expression
    if kind == CXK_PAREN_EXPR:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            let inner = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            if inner.len() > 0:
                return "(" ++ inner ++ ")"
        return ""

    // Implicit cast — dispatch by cast kind
    if kind == CXK_IMPLICIT_CAST:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            let cast_kind = with_ci_implicit_cast_kind(session, cursor)
            let inner = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            if inner.len() == 0:
                return ""
            if cast_kind == CI_CAST_INT_TO_BOOL:
                return "(" ++ inner ++ " != 0)"
            if cast_kind == CI_CAST_BOOL_TO_INT:
                return "(if " ++ inner ++ ": 1 else: 0)"
            if cast_kind == CI_CAST_PTR_TO_BOOL:
                return "(" ++ inner ++ " != null)"
            if cast_kind == CI_CAST_NULL_TO_PTR:
                return "null"
            if cast_kind == CI_CAST_INT_TO_FLOAT:
                let dest_ty = with_ci_cursor_type(session, cursor)
                let dest_str = with_ci_type_translated(session, dest_ty)
                return "(" ++ inner ++ " as " ++ dest_str ++ ")"
            if cast_kind == CI_CAST_FLOAT_TO_INT:
                let dest_ty = with_ci_cursor_type(session, cursor)
                let dest_str = with_ci_type_translated(session, dest_ty)
                return "(" ++ inner ++ " as " ++ dest_str ++ ")"
            if cast_kind == CI_CAST_INT_TRUNC:
                let dest_ty = with_ci_cursor_type(session, cursor)
                let dest_str = with_ci_type_translated(session, dest_ty)
                return "(" ++ inner ++ " as " ++ dest_str ++ ")"
            if cast_kind == CI_CAST_TO_VOID:
                return inner
            if cast_kind == CI_CAST_ARRAY_TO_PTR:
                let pointee = with_ci_cursor_pointee_type(session, cursor)
                if pointee.len() > 0:
                    return "(&" ++ inner ++ "[0] as *mut " ++ pointee ++ ")"
                return "&" ++ inner
            if cast_kind == CI_CAST_INT_TO_PTR:
                return "(" ++ inner ++ " as usize as *mut c_void)"
            if cast_kind == CI_CAST_PTR_TO_INT:
                let dest_ty = with_ci_cursor_type(session, cursor)
                let dest_str = with_ci_type_translated(session, dest_ty)
                return "(" ++ inner ++ " as usize as " ++ dest_str ++ ")"
            if cast_kind == CI_CAST_PTR_CAST:
                let dest_ty = with_ci_cursor_type(session, cursor)
                let dest_str = with_ci_type_translated(session, dest_ty)
                return "(" ++ inner ++ " as " ++ dest_str ++ ")"
            if cast_kind == CI_CAST_FLOAT_CAST:
                let dest_ty = with_ci_cursor_type(session, cursor)
                let dest_str = with_ci_type_translated(session, dest_ty)
                return "(" ++ inner ++ " as " ++ dest_str ++ ")"
            if cast_kind == CI_CAST_FLOAT_TO_BOOL:
                return "(" ++ inner ++ " != 0.0)"
            if cast_kind == CI_CAST_BOOL_TO_FLOAT:
                return "(if " ++ inner ++ ": 1.0 else: 0.0)"
            if cast_kind == CI_CAST_BITCAST:
                let dest_ty = with_ci_cursor_type(session, cursor)
                let dest_str = with_ci_type_translated(session, dest_ty)
                return "(" ++ inner ++ " as " ++ dest_str ++ ")"
            if cast_kind == CI_CAST_INT_WIDEN_SIGN:
                let dest_ty = with_ci_cursor_type(session, cursor)
                let dest_str = with_ci_type_translated(session, dest_ty)
                return "(" ++ inner ++ " as " ++ dest_str ++ ")"
            // NOOP, INT_WIDEN, etc. — unwrap
            return inner
        return ""

    // Declaration reference (identifier)
    if kind == CXK_DECL_REF:
        let name = with_ci_cursor_spelling(session, cursor)
        let escaped = ci_escape_reserved(name)
        // Check scope for mangled name
        let mangled = ci_scope_lookup(scope, escaped)
        if mangled.len() > 0:
            return mangled
        return escaped

    // Binary operator
    if kind == CXK_BINARY_OP:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let lhs_cursor = with_ci_child(session, cursor, 0)
            let rhs_cursor = with_ci_child(session, cursor, 1)
            let lhs = ci_trans_expr(session, lhs_cursor, scope)
            let rhs = ci_trans_expr(session, rhs_cursor, scope)
            if lhs.len() > 0 and rhs.len() > 0:
                let op = with_ci_binary_op(session, cursor)
                let lhs_is_ptr = with_ci_type_is_pointer(session, lhs_cursor) != 0
                let rhs_is_ptr = with_ci_type_is_pointer(session, rhs_cursor) != 0

                // Pointer arithmetic: ptr + idx, idx + ptr
                // Also handle array + idx (array decays to pointer)
                let lhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, lhs_cursor))
                let rhs_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, rhs_cursor))
                let lhs_is_array = lhs_ty_str.len() > 0 and lhs_ty_str.byte_at(0) == 91
                let rhs_is_array = rhs_ty_str.len() > 0 and rhs_ty_str.byte_at(0) == 91
                if op == BO_ADD and (lhs_is_ptr or rhs_is_ptr or lhs_is_array or rhs_is_array):
                    var ptr_e = if lhs_is_ptr or lhs_is_array: lhs else: rhs
                    let ptr_cursor = if lhs_is_ptr or lhs_is_array: lhs_cursor else: rhs_cursor
                    let is_array = if lhs_is_ptr or lhs_is_array: lhs_is_array else: rhs_is_array
                    let idx_cursor = if lhs_is_ptr or lhs_is_array: rhs_cursor else: lhs_cursor
                    let idx_e = if lhs_is_ptr or lhs_is_array: rhs else: lhs
                    // Array decay: &arr[0]
                    if is_array:
                        let arr_ty = with_ci_type_translated(session, with_ci_cursor_type(session, ptr_cursor))
                        let elem_start = ci_find_array_elem_start(arr_ty)
                        if elem_start > 0:
                            let elem_ty = arr_ty.slice(elem_start as i64, arr_ty.len())
                            ptr_e = "(&" ++ ptr_e ++ "[0] as *mut " ++ elem_ty ++ ")"
                    if with_ci_type_is_unsigned(session, idx_cursor) == 0:
                        return "(" ++ ptr_e ++ " + (" ++ idx_e ++ " as isize as usize))"
                    return "(" ++ ptr_e ++ " + " ++ idx_e ++ ")"

                // Pointer difference: ptr - ptr
                if op == BO_SUB and lhs_is_ptr and rhs_is_ptr:
                    let elem_ty = with_ci_cursor_pointee_type(session, lhs_cursor)
                    return "((" ++ lhs ++ " as usize -% " ++ rhs ++ " as usize) / sizeof[" ++ elem_ty ++ "]())"

                // Pointer - signed index
                if op == BO_SUB and lhs_is_ptr and not rhs_is_ptr:
                    if with_ci_type_is_unsigned(session, rhs_cursor) == 0:
                        return "(" ++ lhs ++ " - (" ++ rhs ++ " as isize as usize))"
                    return "(" ++ lhs ++ " - " ++ rhs ++ ")"

                let is_unsigned = with_ci_type_is_unsigned(session, cursor)
                // C logical ops (&&, ||) need bool operands in With
                if op == BO_LAND or op == BO_LOR:
                    let bool_lhs = ci_trans_bool_expr(session, lhs_cursor, scope)
                    let bool_rhs = ci_trans_bool_expr(session, rhs_cursor, scope)
                    let log_op = if op == BO_LAND: "and" else: "or"
                    return "(if " ++ bool_lhs ++ " " ++ log_op ++ " " ++ bool_rhs ++ ": 1 else: 0)"

                let op_str = ci_bo_to_str_typed(op, is_unsigned)
                if op_str.len() > 0:
                    // C comparisons return int, not bool.
                    // Wrap in (if cond: 1 else: 0) to match C semantics.
                    if op == BO_EQ or op == BO_NE or op == BO_LT or op == BO_GT or op == BO_LE or op == BO_GE:
                        return "(if " ++ lhs ++ " " ++ op_str ++ " " ++ rhs ++ ": 1 else: 0)"
                    return "(" ++ lhs ++ " " ++ op_str ++ " " ++ rhs ++ ")"
        return ""

    // Compound assignment
    if kind == CXK_COMPOUND_ASSIGN_OP:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let lhs = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            let rhs = ci_trans_expr(session, with_ci_child(session, cursor, 1), scope)
            if lhs.len() > 0 and rhs.len() > 0:
                let op = with_ci_binary_op(session, cursor)
                let base_op = ci_compound_to_base_op(op)
                if base_op.len() > 0:
                    return lhs ++ " = " ++ lhs ++ " " ++ base_op ++ " " ++ rhs
        return ""

    // Unary operator
    if kind == CXK_UNARY_OP:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            let operand = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            if operand.len() > 0:
                let op = with_ci_unary_op(session, cursor)
                if op == UO_MINUS:
                    // If operand is a plain integer literal, emit -N directly
                    if ci_is_integer_string(operand):
                        return "-" ++ operand
                    if with_ci_type_is_unsigned(session, cursor) != 0:
                        return "(0 -% " ++ operand ++ ")"
                    return "(0 - " ++ operand ++ ")"
                if op == UO_LNOT:
                    // C's ! on non-bool produces int (0 or 1), not bool
                    if not with_ci_type_is_bool(session, with_ci_child(session, cursor, 0)):
                        return "(if " ++ operand ++ " != 0: 0 else: 1)"
                    return "(not " ++ operand ++ ")"
                if op == UO_NOT: return "(0 - " ++ operand ++ " - 1)"
                if op == UO_PLUS: return operand
                if op == UO_DEREF: return "unsafe: *" ++ operand
                if op == UO_ADDR:
                    // C &var produces a raw pointer; translate to &mut var as *mut T
                    let addr_ty = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
                    if addr_ty.len() > 0:
                        return "(&mut " ++ operand ++ " as " ++ addr_ty ++ ")"
                    return "&" ++ operand
                if op == UO_PRE_INC:
                    return "(" ++ operand ++ " = " ++ operand ++ " + 1)"
                if op == UO_PRE_DEC:
                    return "(" ++ operand ++ " = " ++ operand ++ " - 1)"
                if op == UO_POST_INC:
                    // Post-increment: value before increment is used.
                    // With doesn't have block expressions, so emit as increment
                    // and note the semantic difference.
                    return "(" ++ operand ++ " = " ++ operand ++ " + 1)"
                if op == UO_POST_DEC:
                    return "(" ++ operand ++ " = " ++ operand ++ " - 1)"
        return ""

    // Conditional (ternary) operator
    if kind == CXK_COND_OP:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 3:
            let cond = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            let then_e = ci_trans_expr(session, with_ci_child(session, cursor, 1), scope)
            let else_e = ci_trans_expr(session, with_ci_child(session, cursor, 2), scope)
            if cond.len() > 0 and then_e.len() > 0 and else_e.len() > 0:
                return "(if " ++ cond ++ " != 0: " ++ then_e ++ " else: " ++ else_e ++ ")"
        return ""

    // C-style cast
    if kind == CXK_CSTYLE_CAST:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            let inner = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            if inner.len() > 0:
                let target_ty = with_ci_cursor_type(session, cursor)
                let target_str = with_ci_type_translated(session, target_ty)
                if target_str == "void":
                    return inner  // (void)expr → expr (discard)
                return "(" ++ inner ++ " as " ++ target_str ++ ")"
        return ""

    // Call expression
    if kind == CXK_CALL_EXPR:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            let callee = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            if callee.len() > 0:
                var args = ""
                var ai = 1
                while ai < nc:
                    if ai > 1:
                        args = args ++ ", "
                    let arg_cursor = with_ci_child(session, cursor, ai)
                    var arg = ci_trans_expr(session, arg_cursor, scope)
                    let arg_src = with_ci_cursor_source_text(session, arg_cursor)
                    let expanded_arg_src = ci_expand_string_macro_sequence(session, arg_src)
                    if expanded_arg_src.len() > 0:
                        arg = expanded_arg_src
                    else:
                        let expanded_arg = ci_expand_string_macro_sequence(session, arg)
                        if expanded_arg.len() > 0:
                            arg = expanded_arg
                    if arg.len() == 0:
                        return ""
                    // Array-to-pointer decay: if arg is array type, cast to pointer
                    let arg_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, arg_cursor))
                    if arg_ty_str.len() > 0 and arg_ty_str.byte_at(0) == 91:
                        // [N]T → (&arg[0] as *mut T)
                        let elem_start = ci_find_array_elem_start(arg_ty_str)
                        if elem_start > 0:
                            let elem_ty = arg_ty_str.slice(elem_start as i64, arg_ty_str.len())
                            arg = "(&" ++ arg ++ "[0] as *mut " ++ elem_ty ++ ")"
                    args = args ++ arg
                    ai = ai + 1
                // Map libc functions to With equivalents (pure With, no c_import)
                let mapped = ci_map_libc_call(callee, args)
                if mapped.len() > 0:
                    return mapped
                return callee ++ "(" ++ args ++ ")"
        return ""

    // Member reference (. or ->)
    if kind == CXK_MEMBER_REF:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            let base = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            let field = with_ci_member_field_name(session, cursor)
            if base.len() > 0 and field.len() > 0:
                return base ++ "." ++ ci_escape_reserved(field)
        return ""

    // Array subscript
    if kind == CXK_ARRAY_SUBSCRIPT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let arr = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            let idx = ci_trans_expr(session, with_ci_child(session, cursor, 1), scope)
            if arr.len() > 0 and idx.len() > 0:
                return arr ++ "[" ++ idx ++ "]"
        return ""

    // sizeof expression (CXK_UNARY_EXPR = 136 covers sizeof)
    if kind == CXK_UNARY_EXPR:
        if ci_starts_with(src, "sizeof"):
            let nc = with_ci_num_children(session, cursor)
            if nc > 0:
                let arg_ty = with_ci_cursor_type(session, with_ci_child(session, cursor, 0))
                let ty_str = with_ci_type_translated(session, arg_ty)
                return ci_render_sizeof_type(ty_str)
        return ""

    // Predefined expressions (__func__, __FUNCTION__, __PRETTY_FUNCTION__)
    if kind == 138:  // CXCursor_PredefinedExpr
        return "\"__func__\""

    // Compound literal — get the type and translate the inner init list
    if kind == CXK_COMPOUND_LITERAL:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            let child = with_ci_child(session, cursor, 0)
            let child_kind = with_ci_cursor_kind(session, child)
            if child_kind == CXK_INIT_LIST:
                // Struct/array compound literal: (Type){...}
                let lit_ty = with_ci_cursor_type(session, cursor)
                let ty_str = with_ci_type_translated(session, lit_ty)
                let inner = ci_trans_expr(session, child, scope)
                if inner.len() > 0 and ty_str.len() > 0 and not ci_starts_with(ty_str, "__UNSUPPORTED"):
                    // inner already has TypeName { ... } form from init list handler
                    // but use the compound literal's type which may be more specific
                    return inner
                return ci_trans_expr(session, child, scope)
            return ci_trans_expr(session, child, scope)
        return ""

    // Initializer list — { expr1, expr2, ... }
    if kind == CXK_INIT_LIST:
        let nc = with_ci_num_children(session, cursor)
        var items = ""
        var ii = 0
        while ii < nc:
            if ii > 0:
                items = items ++ ", "
            let item = ci_trans_expr(session, with_ci_child(session, cursor, ii), scope)
            if item.len() == 0:
                return ""
            items = items ++ item
            ii = ii + 1
        // Get the target type for struct init
        let init_ty = with_ci_cursor_type(session, cursor)
        let ty_str = with_ci_type_translated(session, init_ty)
        if ty_str != "i32" and not ci_starts_with(ty_str, "__UNSUPPORTED"):
            return ty_str ++ " { " ++ items ++ " }"
        return "{ " ++ items ++ " }"

    // Statement expression (GNU extension: ({...}))
    if kind == 135:  // CXCursor_StmtExpr
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            // Translate the compound statement as a block
            let body = ci_trans_stmt(session, with_ci_child(session, cursor, 0), 1, scope)
            if body.len() > 0:
                return "{\n" ++ body ++ "}"
        return ""

    // Offsetof expression
    if kind == 152:  // CXCursor_OffsetOfExpr  (approximate cursor kind)
        if ci_starts_with(src, "offsetof") or ci_starts_with(src, "__builtin_offsetof"):
            // Can't translate generically — return source text as fallback
            return ""
        return ""

    // _Generic selection — libclang resolves to the chosen association
    // CXCursor_GenericSelectionExpr = 122
    if kind == 122:
        let nc = with_ci_num_children(session, cursor)
        // The last child is the selected expression (after controlling expr + associations)
        if nc > 0:
            // Try to translate the result expression (last child)
            let result = ci_trans_expr(session, with_ci_child(session, cursor, nc - 1), scope)
            if result.len() > 0:
                return result
        return ""

    // VA_ARG expression — not directly translatable
    // CXCursor_UnexposedExpr can contain va_arg
    if kind == 100:  // CXCursor_UnexposedExpr — often an ImplicitCastExpr
        // Try to evaluate as constant
        if with_ci_eval_int_valid(session, cursor) != 0:
            let ival = with_ci_eval_int_value(session, cursor)
            if ival > 2147483647 and ival <= 4294967295:
                return ci_i64_to_hex(ival)
            return f"{ival}"
        // Check for implicit cast semantics using safe type-string comparison
        let nc = with_ci_num_children(session, cursor)
        if nc == 1:
            let child_0 = with_ci_child(session, cursor, 0)
            let outer_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, cursor))
            let inner_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, child_0))
            // Array-to-pointer decay: inner is [N]T, outer is pointer
            if inner_ty_str.len() > 0 and inner_ty_str.byte_at(0) == 91 and with_ci_type_is_pointer(session, cursor) != 0:
                let inner = ci_trans_expr(session, child_0, scope)
                if inner.len() > 0:
                    let pointee = with_ci_cursor_pointee_type(session, cursor)
                    if pointee.len() > 0:
                        return "(&" ++ inner ++ "[0] as *mut " ++ pointee ++ ")"
            // Pointer-to-pointer cast — only emit when converting TO a
            // concrete typed pointer (not void*). Casts to void* are C-isms
            // that don't help in With where function signatures use *i8.
            if with_ci_type_is_pointer(session, cursor) != 0 and with_ci_type_is_pointer(session, child_0) != 0 and outer_ty_str != inner_ty_str:
                if not ci_str_contains(outer_ty_str, "c_void"):
                    let inner = ci_trans_expr(session, child_0, scope)
                    if inner.len() > 0:
                        return "(" ++ inner ++ " as " ++ outer_ty_str ++ ")"
            return ci_trans_expr(session, child_0, scope)
        if nc > 0:
            return ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
        return ""

    // Fallback: try to use source text for simple expressions
    ""

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

// ── Bool coercion — type-aware condition translation ────────

fn ci_trans_bool_expr(session: i64, cursor: i32, scope: str) -> str:
    let expr = ci_trans_expr(session, cursor, scope)
    if expr.len() == 0:
        return ""
    // Check the type of the condition expression
    if with_ci_type_is_bool(session, cursor) != 0:
        return expr
    if with_ci_type_is_pointer(session, cursor) != 0:
        return expr ++ " != null"
    if with_ci_type_is_float(session, cursor) != 0:
        return expr ++ " != 0.0"
    // Default: integer comparison
    expr ++ " != 0"

// ── Statement translator ────────────────────────────────────

fn ci_trans_stmt(session: i64, cursor: i32, indent: i32, scope: str) -> str:
    let kind = with_ci_cursor_kind(session, cursor)

    // Compound statement (block) — new scope level
    if kind == CXK_COMPOUND_STMT:
        let nc = with_ci_num_children(session, cursor)
        var body = ""
        var block_scope = scope
        var i = 0
        while i < nc:
            let child = with_ci_child(session, cursor, i)
            // For decl stmts, register names and get updated scope
            if with_ci_cursor_kind(session, child) == CXK_DECL_STMT:
                let decl_result = ci_trans_decl_stmt_scoped(session, child, indent, block_scope)
                if decl_result.len() > 0:
                    // Extract scope update (first line is scope update prefixed with "SCOPE:")
                    if ci_starts_with(decl_result, "SCOPE:"):
                        let sep = ci_find_char(decl_result, 10)
                        if sep > 0:
                            block_scope = decl_result.slice(6, sep as i64)
                            let stmt_text = decl_result.slice((sep + 1) as i64, decl_result.len())
                            if stmt_text.len() > 0:
                                body = body ++ ci_indent_str(indent) ++ stmt_text ++ "\n"
                    else:
                        body = body ++ ci_indent_str(indent) ++ decl_result ++ "\n"
            else:
                let s = ci_trans_stmt(session, child, indent, block_scope)
                if s.len() > 0:
                    body = body ++ ci_indent_str(indent) ++ s ++ "\n"
            i = i + 1
        return body

    // Return statement
    if kind == CXK_RETURN_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc == 0:
            return "return"
        let ret_child = with_ci_child(session, cursor, 0)
        var expr = ci_trans_expr(session, ret_child, scope)
        if expr.len() > 0:
            // Array-to-pointer decay in return
            let ret_ty_str = with_ci_type_translated(session, with_ci_cursor_type(session, ret_child))
            if ret_ty_str.len() > 0 and ret_ty_str.byte_at(0) == 91:
                let elem_start = ci_find_array_elem_start(ret_ty_str)
                if elem_start > 0:
                    let elem_ty = ret_ty_str.slice(elem_start as i64, ret_ty_str.len())
                    expr = "(&" ++ expr ++ "[0] as *mut " ++ elem_ty ++ ")"
            return "return " ++ expr
        return ""

    // If statement
    if kind == CXK_IF_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let cond = ci_trans_bool_expr(session, with_ci_child(session, cursor, 0), scope)
            if cond.len() > 0:
                let then_child = with_ci_child(session, cursor, 1)
                let then_body = ci_trans_stmt(session, then_child, 0, scope)
                if then_body.len() > 0:
                    let then_text = ci_indent_block(then_body, indent + 1)
                    var result = "if " ++ cond ++ ":\n" ++ then_text
                    if nc > 2:
                        let else_child = with_ci_child(session, cursor, 2)
                        let else_body = ci_trans_stmt(session, else_child, 0, scope)
                        if else_body.len() > 0:
                            let else_text = ci_indent_block(else_body, indent + 1)
                            result = result ++ ci_indent_str(indent) ++ "else:\n" ++ else_text
                    return result
        return ""

    // While statement
    if kind == CXK_WHILE_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let cond = ci_trans_bool_expr(session, with_ci_child(session, cursor, 0), scope)
            if cond.len() > 0:
                let body = ci_trans_stmt(session, with_ci_child(session, cursor, 1), 0, scope)
                if body.len() > 0:
                    let body_text = ci_indent_block(body, indent + 1)
                    return "while " ++ cond ++ ":\n" ++ body_text
        return ""

    // For statement — translate to init + while + inc
    if kind == CXK_FOR_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 1:
            // libclang ForStmt children: the last child is always the body.
            // Preceding children are init, cond, inc — but any can be missing.
            // We identify them by cursor kind:
            //   - DeclStmt or expression = init
            //   - Last before body = inc (if not the cond)
            //   - The body is always CompoundStmt (or another stmt)
            let body_idx = nc - 1
            let body_cursor = with_ci_child(session, cursor, body_idx)
            let body_raw = ci_trans_stmt(session, body_cursor, 0, scope)
            if body_raw.len() == 0:
                return ""
            let body = ci_indent_block(body_raw, indent + 1)

            // Simple approach: try to translate each child before body
            var init_str = ""
            var cond_str = "true"
            var inc_str = ""
            if nc == 4:
                // All parts present: [init, cond, inc, body]
                init_str = ci_trans_stmt(session, with_ci_child(session, cursor, 0), indent, scope)
                let cond_e = ci_trans_bool_expr(session, with_ci_child(session, cursor, 1), scope)
                if cond_e.len() > 0:
                    cond_str = cond_e
                inc_str = ci_trans_expr(session, with_ci_child(session, cursor, 2), scope)
            else if nc == 3:
                // Two of init/cond/inc present + body
                // Heuristic: if first child is DeclStmt, it's init + (cond or inc)
                let first = with_ci_child(session, cursor, 0)
                let second = with_ci_child(session, cursor, 1)
                let first_kind = with_ci_cursor_kind(session, first)
                if first_kind == CXK_DECL_STMT:
                    init_str = ci_trans_stmt(session, first, indent, scope)
                    let cond_e = ci_trans_bool_expr(session, second, scope)
                    if cond_e.len() > 0:
                        cond_str = cond_e
                else:
                    let cond_e = ci_trans_bool_expr(session, first, scope)
                    if cond_e.len() > 0:
                        cond_str = cond_e
                    inc_str = ci_trans_expr(session, second, scope)
            else if nc == 2:
                // Only one of init/cond/inc + body — treat as cond
                let cond_e = ci_trans_bool_expr(session, with_ci_child(session, cursor, 0), scope)
                if cond_e.len() > 0:
                    cond_str = cond_e

            var result = ""
            if init_str.len() > 0:
                result = result ++ init_str ++ "\n" ++ ci_indent_str(indent)
            result = result ++ "while " ++ cond_str ++ ":\n" ++ body
            if inc_str.len() > 0:
                result = result ++ ci_indent_str(indent + 1) ++ inc_str ++ "\n"
            return result
        return ""

    // Do-while
    if kind == CXK_DO_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let body_raw = ci_trans_stmt(session, with_ci_child(session, cursor, 0), 0, scope)
            let cond = ci_trans_bool_expr(session, with_ci_child(session, cursor, 1), scope)
            if body_raw.len() > 0 and cond.len() > 0:
                let body_text = ci_indent_block(body_raw, indent + 1)
                return "while true:\n" ++ body_text ++ ci_indent_str(indent + 1) ++ "if not (" ++ cond ++ "):\n" ++ ci_indent_str(indent + 2) ++ "break\n"
        return ""

    // Break
    if kind == CXK_BREAK_STMT:
        return "break"

    // Continue
    if kind == CXK_CONTINUE_STMT:
        return "continue"

    // Null statement (empty ; in C)
    if kind == CXK_NULL_STMT:
        return "0"

    // Switch statement — translate to match expression
    if kind == CXK_SWITCH_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let cond = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            if cond.len() > 0:
                // Walk the compound body and extract case/default arms
                let body_cursor = with_ci_child(session, cursor, 1)
                return ci_trans_switch_body(session, body_cursor, cond, indent, scope)
        return ""

    // Static assert — untranslatable
    if kind == 602:  // CXCursor_StaticAssert
        return "comptime_error(\"static_assert\")"

    // GCC asm statement — untranslatable
    if kind == 215:  // CXCursor_GCCAsmStmt
        return "comptime_error(\"inline asm\")"

    // Goto — untranslatable, emit comptime_error
    if kind == CXK_GOTO_STMT:
        return "comptime_error(\"goto not supported\")"

    // Label — emit as comment
    if kind == CXK_LABEL_STMT:
        let lbl = with_ci_cursor_spelling(session, cursor)
        let nc = with_ci_num_children(session, cursor)
        var body = ""
        if nc > 0:
            body = ci_trans_stmt(session, with_ci_child(session, cursor, 0), indent, scope)
        return "// label: " ++ lbl ++ "\n" ++ body

    // Declaration statement (local variable)
    if kind == CXK_DECL_STMT:
        let nc = with_ci_num_children(session, cursor)
        var result = ""
        var i = 0
        while i < nc:
            let child = with_ci_child(session, cursor, i)
            if with_ci_cursor_kind(session, child) == CXK_VAR_DECL:
                let vname = ci_escape_reserved(with_ci_cursor_spelling(session, child))
                let vty = with_ci_cursor_type(session, child)
                let vty_str = with_ci_type_translated(session, vty)
                let child_nc = with_ci_num_children(session, child)
                if child_nc > 0:
                    let init = ci_trans_expr(session, with_ci_child(session, child, 0), scope)
                    if result.len() > 0:
                        result = result ++ "\n" ++ ci_indent_str(indent)
                    if init.len() > 0:
                        result = result ++ "var " ++ vname ++ ": " ++ vty_str ++ " = " ++ init
                    else:
                        // Can't translate initializer — use zero-init
                        result = result ++ "var " ++ vname ++ ": " ++ vty_str
                else:
                    if result.len() > 0:
                        result = result ++ "\n" ++ ci_indent_str(indent)
                    result = result ++ "var " ++ vname ++ ": " ++ vty_str
            i = i + 1
        return result

    // Chained assignment decomposition
    if kind == CXK_BINARY_OP:
        let bo = with_ci_binary_op(session, cursor)
        if bo == BO_ASSIGN:
            let nc = with_ci_num_children(session, cursor)
            if nc >= 2:
                let lhs_cursor = with_ci_child(session, cursor, 0)
                let rhs_cursor = with_ci_child(session, cursor, 1)
                // a = (b = c) → decompose RHS chain
                if with_ci_cursor_kind(session, rhs_cursor) == CXK_BINARY_OP and with_ci_binary_op(session, rhs_cursor) == BO_ASSIGN:
                    let inner_stmt = ci_trans_stmt(session, rhs_cursor, indent, scope)
                    let inner_lhs = ci_trans_expr(session, with_ci_child(session, rhs_cursor, 0), scope)
                    let outer_lhs = ci_trans_expr(session, lhs_cursor, scope)
                    if inner_stmt.len() > 0 and outer_lhs.len() > 0 and inner_lhs.len() > 0:
                        return inner_stmt ++ "\n" ++ ci_indent_str(indent) ++ "(" ++ outer_lhs ++ " = " ++ inner_lhs ++ ")"
                // *(ptr = ptr + 1) = value → decompose LHS deref-of-assign
                if with_ci_cursor_kind(session, lhs_cursor) == CXK_UNARY_OP and with_ci_unary_op(session, lhs_cursor) == UO_DEREF:
                    let deref_child = with_ci_child(session, lhs_cursor, 0)
                    // Skip implicit cast wrappers (kind 100)
                    var inner_assign_cursor = deref_child
                    if with_ci_cursor_kind(session, deref_child) == 100:
                        let icc = with_ci_num_children(session, deref_child)
                        if icc == 1:
                            inner_assign_cursor = with_ci_child(session, deref_child, 0)
                    if with_ci_cursor_kind(session, inner_assign_cursor) == CXK_BINARY_OP and with_ci_binary_op(session, inner_assign_cursor) == BO_ASSIGN:
                        // *(ptr_assign) = rhs → decompose to: (ptr_assign), then (unsafe: *ptr = rhs)
                        let ptr_stmt = ci_trans_stmt(session, inner_assign_cursor, indent, scope)
                        let ptr_lhs = ci_trans_expr(session, with_ci_child(session, inner_assign_cursor, 0), scope)
                        let rhs_val = ci_trans_expr(session, rhs_cursor, scope)
                        if ptr_stmt.len() > 0 and ptr_lhs.len() > 0 and rhs_val.len() > 0:
                            return ptr_stmt ++ "\n" ++ ci_indent_str(indent) ++ "(unsafe: *" ++ ptr_lhs ++ " = " ++ rhs_val ++ ")"

    // Expression statement — translate as expression
    let expr = ci_trans_expr(session, cursor, scope)
    if expr.len() > 0:
        return expr
    ""

fn ci_try_eval_var_init(session: i64, idx: i32) -> str:
    // Try to evaluate a variable's initializer using libclang's cursor eval API
    let root = with_ci_root_cursor(session)
    let n = with_ci_num_children(session, root)
    // Find the variable declaration cursor by matching name
    let target_name = with_cimport_decl_name(session, idx)
    var i = 0
    while i < n:
        let child = with_ci_child(session, root, i)
        let ck = with_ci_cursor_kind(session, child)
        if ck == CXK_VAR_DECL:
            let cname = with_ci_cursor_spelling(session, child)
            if cname == target_name:
                // Found the variable — check for initializer child
                let child_nc = with_ci_num_children(session, child)
                if child_nc > 0:
                    let init_cursor = with_ci_child(session, child, 0)
                    // Try integer evaluation
                    if with_ci_eval_int_valid(session, init_cursor) != 0:
                        return f"{with_ci_eval_int_value(session, init_cursor)}"
                    // Try expression translation
                    let expr = ci_trans_expr(session, init_cursor, "")
                    if expr.len() > 0:
                        return expr
                return ""
        i = i + 1
    ""

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

fn ci_trans_switch_body(session: i64, body_cursor: i32, cond: str, indent: i32, scope: str) -> str:
    // Walk compound stmt children, collect case/default arms.
    // Use match expression for non-fallthrough cases.
    // For fallthrough cases, use if/else chain with __fall flag.
    let nc = with_ci_num_children(session, body_cursor)

    // First pass: collect case values and detect fallthrough
    var has_fallthrough = false
    var case_count = 0
    var i = 0
    while i < nc:
        let child = with_ci_child(session, body_cursor, i)
        let ck = with_ci_cursor_kind(session, child)
        if ck == CXK_CASE_STMT or ck == CXK_DEFAULT_STMT:
            case_count = case_count + 1
            // Check if case body contains a break (no fallthrough)
            let case_nc = with_ci_num_children(session, child)
            if case_nc >= 2 and ck == CXK_CASE_STMT:
                let body_child = with_ci_child(session, child, 1)
                if not ci_stmt_ends_with_break(session, body_child):
                    has_fallthrough = true
            else if case_nc >= 1 and ck == CXK_DEFAULT_STMT:
                let body_child = with_ci_child(session, child, 0)
                if not ci_stmt_ends_with_break(session, body_child):
                    has_fallthrough = true
        i = i + 1

    // Generate match expression when no fallthrough
    if not has_fallthrough and case_count > 0:
        var result = "match " ++ cond ++ "\n"
        var default_body = ""
        i = 0
        while i < nc:
            let child = with_ci_child(session, body_cursor, i)
            let ck = with_ci_cursor_kind(session, child)
            if ck == CXK_CASE_STMT:
                let case_nc = with_ci_num_children(session, child)
                if case_nc >= 2:
                    let case_val = ci_trans_expr(session, with_ci_child(session, child, 0), scope)
                    let case_body = ci_trans_stmt_strip_break(session, with_ci_child(session, child, 1), indent + 2, scope)
                    if case_val.len() > 0 and case_body.len() > 0:
                        result = result ++ ci_indent_str(indent + 1) ++ case_val ++ " =>\n" ++ case_body
            else if ck == CXK_DEFAULT_STMT:
                let case_nc = with_ci_num_children(session, child)
                if case_nc >= 1:
                    let case_body = ci_trans_stmt_strip_break(session, with_ci_child(session, child, 0), indent + 2, scope)
                    if case_body.len() > 0:
                        default_body = ci_indent_str(indent + 1) ++ "_ =>\n" ++ case_body
            i = i + 1
        if default_body.len() > 0:
            result = result ++ default_body
        return result

    // Fallthrough handling: Zig-style statement duplication.
    // For each case, walk forward through the remaining switch body,
    // collecting all statements until break/return. This means a case
    // that falls through includes the next case's statements too.
    var result = "match " ++ cond ++ "\n"
    var has_default = false
    var default_prong = ""
    i = 0
    while i < nc:
        let child = with_ci_child(session, body_cursor, i)
        let ck = with_ci_cursor_kind(session, child)
        if ck == CXK_CASE_STMT:
            // Collect case value(s) — chase nested case/default chains
            let case_nc = with_ci_num_children(session, child)
            if case_nc >= 1:
                let case_val = ci_trans_expr(session, with_ci_child(session, child, 0), scope)
                if case_val.len() > 0:
                    // Walk forward from this case's body through remaining switch body
                    let prong_body = ci_trans_switch_prong_forward(session, body_cursor, i, nc, indent + 2, scope)
                    if prong_body.len() > 0:
                        result = result ++ ci_indent_str(indent + 1) ++ case_val ++ " =>\n" ++ prong_body
                    else:
                        result = result ++ ci_indent_str(indent + 1) ++ case_val ++ " => 0\n"
        else if ck == CXK_DEFAULT_STMT:
            has_default = true
            let prong_body = ci_trans_switch_prong_forward(session, body_cursor, i, nc, indent + 2, scope)
            if prong_body.len() > 0:
                default_prong = ci_indent_str(indent + 1) ++ "_ =>\n" ++ prong_body
            else:
                default_prong = ci_indent_str(indent + 1) ++ "_ => 0\n"
        i = i + 1
    if has_default:
        result = result ++ default_prong
    else:
        result = result ++ ci_indent_str(indent + 1) ++ "_ => 0\n"
    result

// Walk forward from case at position `start_idx` through the switch body,
// translating all statements until break/return (Zig-style duplication).
// In libclang's AST, case bodies and break statements are siblings in the
// switch's compound body. A CaseStmt's child[1] is just its first
// statement — subsequent statements (including break) are siblings.
fn ci_trans_switch_prong_forward(session: i64, body_cursor: i32, start_idx: i32, total: i32, indent: i32, scope: str) -> str:
    var output = ""

    // First: translate the case/default's own body child
    let start_child = with_ci_child(session, body_cursor, start_idx)
    let start_kind = with_ci_cursor_kind(session, start_child)
    if start_kind == CXK_CASE_STMT:
        let cnc = with_ci_num_children(session, start_child)
        if cnc >= 2:
            let body_child = with_ci_child(session, start_child, 1)
            let bk = with_ci_cursor_kind(session, body_child)
            if bk == CXK_BREAK_STMT:
                return output
            if bk == CXK_RETURN_STMT:
                let s = ci_trans_stmt(session, body_child, 0, scope)
                if s.len() > 0:
                    output = output ++ ci_indent_block(s, indent)
                return output
            // Chase nested case/default: skip (handled separately)
            if bk != CXK_CASE_STMT and bk != CXK_DEFAULT_STMT:
                let s = ci_trans_stmt(session, body_child, 0, scope)
                if s.len() > 0:
                    output = output ++ ci_indent_block(s, indent)
    else if start_kind == CXK_DEFAULT_STMT:
        let cnc = with_ci_num_children(session, start_child)
        if cnc >= 1:
            let body_child = with_ci_child(session, start_child, 0)
            let bk = with_ci_cursor_kind(session, body_child)
            if bk == CXK_BREAK_STMT:
                return output
            if bk == CXK_RETURN_STMT:
                let s = ci_trans_stmt(session, body_child, 0, scope)
                if s.len() > 0:
                    output = output ++ ci_indent_block(s, indent)
                return output
            if bk != CXK_CASE_STMT and bk != CXK_DEFAULT_STMT:
                let s = ci_trans_stmt(session, body_child, 0, scope)
                if s.len() > 0:
                    output = output ++ ci_indent_block(s, indent)

    // Now walk forward through siblings in the switch body
    var j = start_idx + 1
    while j < total:
        let next_child = with_ci_child(session, body_cursor, j)
        let next_kind = with_ci_cursor_kind(session, next_child)
        // Break ends this prong
        if next_kind == CXK_BREAK_STMT:
            return output
        // Return ends this prong
        if next_kind == CXK_RETURN_STMT:
            let s = ci_trans_stmt(session, next_child, 0, scope)
            if s.len() > 0:
                output = output ++ ci_indent_block(s, indent)
            return output
        // Next case/default: recurse for duplication (fallthrough)
        if next_kind == CXK_CASE_STMT or next_kind == CXK_DEFAULT_STMT:
            output = output ++ ci_trans_switch_prong_forward(session, body_cursor, j, total, indent, scope)
            return output
        // Regular statement
        let s = ci_trans_stmt(session, next_child, 0, scope)
        if s.len() > 0:
            output = output ++ ci_indent_block(s, indent)
        j = j + 1
    output

fn ci_trans_switch_body_goto(session: i64, body_cursor: i32, cond: str, indent: i32, scope: str, label_map: str, loop_depth: i32) -> str:
    let nc = with_ci_num_children(session, body_cursor)

    var has_fallthrough = false
    var case_count = 0
    var i = 0
    while i < nc:
        let child = with_ci_child(session, body_cursor, i)
        let ck = with_ci_cursor_kind(session, child)
        if ck == CXK_CASE_STMT or ck == CXK_DEFAULT_STMT:
            case_count = case_count + 1
            let case_nc = with_ci_num_children(session, child)
            if case_nc >= 2 and ck == CXK_CASE_STMT:
                let body_child = with_ci_child(session, child, 1)
                if not ci_stmt_ends_with_break(session, body_child):
                    has_fallthrough = true
            else if case_nc >= 1 and ck == CXK_DEFAULT_STMT:
                let body_child = with_ci_child(session, child, 0)
                if not ci_stmt_ends_with_break(session, body_child):
                    has_fallthrough = true
        i = i + 1

    if not has_fallthrough and case_count > 0:
        var result = "match " ++ cond ++ "\n"
        var default_body = ""
        i = 0
        while i < nc:
            let child = with_ci_child(session, body_cursor, i)
            let ck = with_ci_cursor_kind(session, child)
            if ck == CXK_CASE_STMT:
                let case_nc = with_ci_num_children(session, child)
                if case_nc >= 2:
                    let case_val = ci_trans_expr(session, with_ci_child(session, child, 0), scope)
                    let case_body = ci_trans_stmt_strip_break_goto(session, with_ci_child(session, child, 1), indent + 2, scope, label_map, loop_depth)
                    if case_val.len() > 0 and case_body.len() > 0:
                        result = result ++ ci_indent_str(indent + 1) ++ case_val ++ " =>\n" ++ case_body
            else if ck == CXK_DEFAULT_STMT:
                let case_nc = with_ci_num_children(session, child)
                if case_nc >= 1:
                    let case_body = ci_trans_stmt_strip_break_goto(session, with_ci_child(session, child, 0), indent + 2, scope, label_map, loop_depth)
                    if case_body.len() > 0:
                        default_body = ci_indent_str(indent + 1) ++ "_ =>\n" ++ case_body
            i = i + 1
        if default_body.len() > 0:
            result = result ++ default_body
        return result

    var result = "match " ++ cond ++ "\n"
    var has_default = false
    var default_prong = ""
    i = 0
    while i < nc:
        let child = with_ci_child(session, body_cursor, i)
        let ck = with_ci_cursor_kind(session, child)
        if ck == CXK_CASE_STMT:
            let case_nc = with_ci_num_children(session, child)
            if case_nc >= 1:
                let case_val = ci_trans_expr(session, with_ci_child(session, child, 0), scope)
                if case_val.len() > 0:
                    let prong_body = ci_trans_switch_prong_forward_goto(session, body_cursor, i, nc, indent + 2, scope, label_map, loop_depth)
                    if prong_body.len() > 0:
                        result = result ++ ci_indent_str(indent + 1) ++ case_val ++ " =>\n" ++ prong_body
                    else:
                        result = result ++ ci_indent_str(indent + 1) ++ case_val ++ " => 0\n"
        else if ck == CXK_DEFAULT_STMT:
            has_default = true
            let prong_body = ci_trans_switch_prong_forward_goto(session, body_cursor, i, nc, indent + 2, scope, label_map, loop_depth)
            if prong_body.len() > 0:
                default_prong = ci_indent_str(indent + 1) ++ "_ =>\n" ++ prong_body
            else:
                default_prong = ci_indent_str(indent + 1) ++ "_ => 0\n"
        i = i + 1
    if has_default:
        result = result ++ default_prong
    else:
        result = result ++ ci_indent_str(indent + 1) ++ "_ => 0\n"
    result

fn ci_trans_switch_prong_forward_goto(session: i64, body_cursor: i32, start_idx: i32, total: i32, indent: i32, scope: str, label_map: str, loop_depth: i32) -> str:
    var output = ""

    let start_child = with_ci_child(session, body_cursor, start_idx)
    let start_kind = with_ci_cursor_kind(session, start_child)
    if start_kind == CXK_CASE_STMT:
        let cnc = with_ci_num_children(session, start_child)
        if cnc >= 2:
            let body_child = with_ci_child(session, start_child, 1)
            let bk = with_ci_cursor_kind(session, body_child)
            if bk == CXK_BREAK_STMT:
                return output
            if bk == CXK_RETURN_STMT:
                let s = ci_trans_stmt_goto(session, body_child, 0, scope, label_map, loop_depth)
                if s.len() > 0:
                    output = output ++ ci_indent_block(s, indent)
                return output
            if bk != CXK_CASE_STMT and bk != CXK_DEFAULT_STMT:
                let s = ci_trans_stmt_goto(session, body_child, 0, scope, label_map, loop_depth)
                if s.len() > 0:
                    output = output ++ ci_indent_block(s, indent)
    else if start_kind == CXK_DEFAULT_STMT:
        let cnc = with_ci_num_children(session, start_child)
        if cnc >= 1:
            let body_child = with_ci_child(session, start_child, 0)
            let bk = with_ci_cursor_kind(session, body_child)
            if bk == CXK_BREAK_STMT:
                return output
            if bk == CXK_RETURN_STMT:
                let s = ci_trans_stmt_goto(session, body_child, 0, scope, label_map, loop_depth)
                if s.len() > 0:
                    output = output ++ ci_indent_block(s, indent)
                return output
            if bk != CXK_CASE_STMT and bk != CXK_DEFAULT_STMT:
                let s = ci_trans_stmt_goto(session, body_child, 0, scope, label_map, loop_depth)
                if s.len() > 0:
                    output = output ++ ci_indent_block(s, indent)

    var j = start_idx + 1
    while j < total:
        let next_child = with_ci_child(session, body_cursor, j)
        let next_kind = with_ci_cursor_kind(session, next_child)
        if next_kind == CXK_BREAK_STMT:
            return output
        if next_kind == CXK_RETURN_STMT:
            let s = ci_trans_stmt_goto(session, next_child, 0, scope, label_map, loop_depth)
            if s.len() > 0:
                output = output ++ ci_indent_block(s, indent)
            return output
        if next_kind == CXK_CASE_STMT or next_kind == CXK_DEFAULT_STMT:
            output = output ++ ci_trans_switch_prong_forward_goto(session, body_cursor, j, total, indent, scope, label_map, loop_depth)
            return output
        let s = ci_trans_stmt_goto(session, next_child, 0, scope, label_map, loop_depth)
        if s.len() > 0:
            output = output ++ ci_indent_block(s, indent)
        j = j + 1
    output

fn ci_trans_stmt_strip_break_goto(session: i64, cursor: i32, indent: i32, scope: str, label_map: str, loop_depth: i32) -> str:
    let result = ci_trans_stmt_goto(session, cursor, indent, scope, label_map, loop_depth)
    if result.len() == 0:
        return ""
    let break_needle = ci_indent_str(indent) ++ "break\n"
    if ci_ends_with(result, break_needle):
        return result.slice(0, result.len() - break_needle.len())
    result

fn ci_trans_stmt_strip_break(session: i64, cursor: i32, indent: i32, scope: str) -> str:
    // Translate stmt, then remove trailing "break\n" line
    let result = ci_trans_stmt(session, cursor, indent, scope)
    if result.len() == 0:
        return ""
    // Find last non-empty line; if it's "break", strip it
    let break_needle = ci_indent_str(indent) ++ "break\n"
    if ci_ends_with(result, break_needle):
        return result.slice(0, result.len() - break_needle.len())
    result

fn ci_ends_with(s: str, suffix: str) -> bool:
    if suffix.len() > s.len():
        return false
    s.slice(s.len() - suffix.len(), s.len()) == suffix

fn ci_stmt_ends_with_break(session: i64, cursor: i32) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_BREAK_STMT:
        return true
    // Check last child of compound statement
    if kind == CXK_COMPOUND_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_break(session, with_ci_child(session, cursor, nc - 1))
    // Check last child of case/default
    if kind == CXK_CASE_STMT or kind == CXK_DEFAULT_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc > 0:
            return ci_stmt_ends_with_break(session, with_ci_child(session, cursor, nc - 1))
    false

// ── Scope helpers ───────────────────────────────────────────
// Scope is a pipe-delimited string: "|name|" or "|name=mangled|"

fn ci_scope_get_return_type(scope: str) -> str:
    if ci_starts_with(scope, "RET:"):
        let end = ci_find_char(scope, 124)  // '|'
        if end > 4:
            return scope.slice(4, end as i64)
    ""

fn ci_scope_contains(scope: str, name: str) -> bool:
    ci_str_contains(scope, "|" ++ name ++ "|") or ci_str_contains(scope, "|" ++ name ++ "=")

fn ci_scope_lookup(scope: str, name: str) -> str:
    // Look for "|name=mangled|" pattern
    let needle = "|" ++ name ++ "="
    let pos = ci_find_str(scope, needle)
    if pos >= 0:
        let start = pos + needle.len() as i32
        var end = start
        while end < scope.len() as i32 and scope.byte_at(end as i64) != 124:
            end = end + 1
        return scope.slice(start as i64, end as i64)
    // If just "|name|" exists, return the name unchanged
    ""

fn ci_scope_mangle(scope: str, name: str) -> str:
    if not ci_scope_contains(scope, name):
        return name
    var suffix = 1
    while suffix < 100:
        let candidate = f"{name}_{suffix}"
        if not ci_scope_contains(scope, candidate):
            return candidate
        suffix = suffix + 1
    name ++ "_99"

fn ci_scope_add(scope: str, name: str) -> str:
    scope ++ "|" ++ name ++ "|"

fn ci_scope_add_mangled(scope: str, original: str, mangled: str) -> str:
    scope ++ "|" ++ original ++ "=" ++ mangled ++ "|"

fn ci_find_char(s: str, c: i32) -> i32:
    var i = 0
    while i < s.len() as i32:
        if s.byte_at(i as i64) == c:
            return i
        i = i + 1
    0 - 1

// Translate a DECL_STMT with scope tracking.
// Returns "SCOPE:<updated_scope>\n<stmt_text>" or just "<stmt_text>".
fn ci_trans_decl_stmt_scoped(session: i64, cursor: i32, indent: i32, scope: str) -> str:
    let nc = with_ci_num_children(session, cursor)
    var result = ""
    var new_scope = scope
    var i = 0
    while i < nc:
        let child = with_ci_child(session, cursor, i)
        if with_ci_cursor_kind(session, child) == CXK_VAR_DECL:
            let raw_name = with_ci_cursor_spelling(session, child)
            let escaped = ci_escape_reserved(raw_name)
            let mangled = ci_scope_mangle(new_scope, escaped)
            let vty = with_ci_cursor_type(session, child)
            let vty_str = with_ci_type_translated(session, vty)
            let child_nc = with_ci_num_children(session, child)
            if mangled != escaped:
                new_scope = ci_scope_add_mangled(new_scope, escaped, mangled)
            else:
                new_scope = ci_scope_add(new_scope, escaped)
            if result.len() > 0:
                result = result ++ "\n" ++ ci_indent_str(indent)
            if child_nc > 0:
                let init = ci_trans_expr(session, with_ci_child(session, child, 0), new_scope)
                if init.len() > 0:
                    result = result ++ "var " ++ mangled ++ ": " ++ vty_str ++ " = " ++ init
                else:
                    // Initializer failed to translate — use zero-init
                    result = result ++ "var " ++ mangled ++ ": " ++ vty_str
            else:
                // No initializer — zero-initialized by With semantics
                let default_val = ci_default_for_type(vty_str)
                if default_val.len() > 0:
                    result = result ++ "var " ++ mangled ++ ": " ++ vty_str ++ " = " ++ default_val
                else:
                    result = result ++ "var " ++ mangled ++ ": " ++ vty_str
        i = i + 1
    if new_scope != scope:
        return "SCOPE:" ++ new_scope ++ "\n" ++ result
    result

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
    var init_scope = "RET:" ++ ret_type ++ "|"

    // Get param names from cursor API (more reliable)
    var cursor_params = ""
    let fn_nc = with_ci_num_children(session, found_cursor)
    var cpi = 0
    while cpi < fn_nc:
        let child = with_ci_child(session, found_cursor, cpi)
        if with_ci_cursor_kind(session, child) == 10:  // CXCursor_ParmDecl
            let cpname = ci_escape_reserved(with_ci_cursor_spelling(session, child))
            if cpname.len() > 0:
                cursor_params = cursor_params ++ "|" ++ cpname ++ "|"
                init_scope = init_scope ++ "|" ++ cpname ++ "|"
        cpi = cpi + 1

    // C params are always mutable, With params are immutable.
    // Detect which params are assigned to in the body and rebind those.
    var param_rebinds = ""
    var prpos2 = 1
    let prlen2 = cursor_params.len() as i32
    while prpos2 < prlen2:
        var prend2 = prpos2
        while prend2 < prlen2 and cursor_params.byte_at(prend2 as i64) != 124:
            prend2 = prend2 + 1
        if prend2 > prpos2:
            let pname = cursor_params.slice(prpos2 as i64, prend2 as i64)
            // Check if this param is assigned to anywhere in the body.
            // The signature renames mutated params to __param_NAME.
            if ci_body_assigns_to(session, body_cursor, pname):
                param_rebinds = param_rebinds ++ "    var " ++ pname ++ " = __param_" ++ pname ++ "\n"
        prpos2 = prend2 + 1
        if prpos2 < prlen2 and cursor_params.byte_at(prpos2 as i64) == 124:
            prpos2 = prpos2 + 1

    // Check for gotos — use state machine transform if present
    if ci_has_goto(session, body_cursor):
        let body = ci_trans_goto_body(session, body_cursor, 1, init_scope)
        if body.len() == 0:
            return ""
        return param_rebinds ++ body

    // Normal structured translation
    let body = ci_trans_stmt(session, body_cursor, 1, init_scope)
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
    if prefix.len() > s.len():
        return false
    s.slice(0, prefix.len()) == prefix

fn ci_str_contains(text: str, needle: str) -> bool:
    if needle.len() == 0:
        return true
    if needle.len() > text.len():
        return false
    let limit = text.len() - needle.len()
    for i in 0..limit as i32 + 1:
        if text.slice(i as i64, i as i64 + needle.len()) == needle:
            return true
    false

// Replace field name `old_name` with `new_name` in last comma-separated field of a field_str
fn ci_str_replace_last_field(field_str: str, old_name: str, new_name: str) -> str:
    // Find last comma at depth 0
    var last_comma = 0 - 1
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
    var result = ""
    var start = 0
    let len = text.len() as i32
    while start < len:
        var end = start
        while end < len and text.byte_at(end as i64) != 10:
            end = end + 1
        result = result ++ prefix ++ text.slice(start as i64, end as i64) ++ "\n"
        start = end + 1
    result

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

fn ci_is_concatenated_string(s: str) -> bool:
    // Detect adjacent string literals: "foo" "bar"
    if s.len() < 5:
        return false
    if s.byte_at(0) != 34:
        return false
    // Find closing quote of first string, then check for another opening quote
    var i = 1
    while i as i64 < s.len():
        let c = s.byte_at(i as i64)
        if c == 92:
            i = i + 2
            continue
        if c == 34:
            // Found end of first string — look for another
            var j = i + 1
            while j as i64 < s.len() and ci_is_space(s.byte_at(j as i64)):
                j = j + 1
            if j as i64 < s.len() and s.byte_at(j as i64) == 34:
                return true
            return false
        i = i + 1
    false

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
                    // Escape sequence — copy both chars
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
    let count = with_cimport_macro_count(session)
    var i = 0
    while i < count:
        if with_cimport_macro_is_fn_like(session, i) == 0:
            if with_cimport_macro_name(session, i) == name:
                return with_cimport_macro_value(session, i)
        i = i + 1
    let needle = "|" ++ name ++ "="
    let pos = ci_find_str(g_migrate_macro_values, needle)
    if pos >= 0:
        let start = pos + needle.len() as i32
        var end = start
        while end < g_migrate_macro_values.len() as i32 and g_migrate_macro_values.byte_at(end as i64) != 124:
            end = end + 1
        return g_migrate_macro_values.slice(start as i64, end as i64)
    ""

// Check if a fn-like macro is a stringify macro (has # in body) or
// calls another fn-like macro that stringifies (e.g. XSTRING -> STRING -> #a).
fn ci_is_stringify_macro(session: i64, name: str, depth: i32) -> bool:
    if depth > 5: return false
    let count = with_cimport_macro_count(session)
    var i = 0
    while i < count:
        if with_cimport_macro_is_fn_like(session, i) != 0:
            if with_cimport_macro_name(session, i) == name:
                let value = with_cimport_macro_value(session, i)
                // Direct stringify: body contains #param
                var j = 0
                while j < value.len() as i32 - 1:
                    if value.byte_at(j as i64) == 35 and value.byte_at((j + 1) as i64) != 35:
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
                            if ci_is_stringify_macro(session, callee, depth + 1):
                                return true
                        k = ke
                    else:
                        k = k + 1
                return false
        i = i + 1
    false

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

fn ci_expand_string_macro_sequence(session: i64, s: str) -> str:
    var segments = ""
    var pos = 0
    let slen = s.len() as i32
    var found_any = false
    while pos < slen:
        while pos < slen and ci_is_space(s.byte_at(pos as i64)):
            pos = pos + 1
        if pos >= slen:
            break
        var end = pos
        var token = ""
        if s.byte_at(pos as i64) == 34:
            end = pos + 1
            while end < slen:
                let c = s.byte_at(end as i64)
                if c == 92:
                    end = end + 2
                    continue
                if c == 34:
                    end = end + 1
                    break
                end = end + 1
            token = s.slice(pos as i64, end as i64)
        else:
            // Scan a token, respecting parentheses (for MACRO(args))
            var paren_depth = 0
            while end < slen:
                let c = s.byte_at(end as i64)
                if c == 40: paren_depth = paren_depth + 1
                if c == 41:
                    paren_depth = paren_depth - 1
                    if paren_depth == 0:
                        end = end + 1
                        break
                if paren_depth == 0 and ci_is_space(c):
                    break
                end = end + 1
            token = s.slice(pos as i64, end as i64)
            // Try stringify macro call first (e.g. XSTRING(MAJOR.MINOR))
            let stringify_result = ci_try_expand_stringify_call(session, token)
            if stringify_result.len() > 0:
                token = stringify_result
            else:
                let macro_value = ci_lookup_macro_value(session, token)
                if macro_value.len() == 0:
                    return ""
                token = macro_value
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
        return segments
    ""

// ── Migrate: C-to-With source translator ────────────────────
// Translates a .c file into a .w file. Unlike c_import (which
// emits extern declarations), migrate translates ALL function
// bodies and emits @[c_export] for public functions.
//
// Reference: Zig translate-c (.reference/translate-c/src/Translator.zig)

// Module-level defines to prepend to migrated C source.
// Set via migrate_add_define() before calling migrate_c_file().
var g_migrate_defines: str = ""
var g_migrate_macro_values: str = ""

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

pub fn migrate_c_file(input_path: str, output_path: str) -> i32:
    if with_cimport_available() == 0:
        eprint("migrate: libclang not available")
        return 1

    // Clear accumulated include paths from prior files, then add
    // this file's directory as an include path
    with_cimport_clear_include_paths()
    var dir_end = input_path.len() as i32 - 1
    while dir_end > 0 and input_path.byte_at(dir_end as i64) != 47:  // '/'
        dir_end = dir_end - 1
    if dir_end > 0:
        with_cimport_add_include_path(input_path.slice(0, dir_end as i64))

    // Reset name tracking state for fresh migration
    with_cimport_reset_names()

    // Read source and prepend defines. Preserve the original file path in
    // libclang locations so migrate's system-header filter does not discard
    // declarations from the temp wrapper file used by cimport_parse().
    let raw_source = with_fs_read_file(input_path)
    if raw_source.len() == 0:
        eprint("migrate: cannot read " ++ input_path)
        return 1
    let line_directive = "#line 1 \"" ++ input_path ++ "\"\n"
    let source = if g_migrate_defines.len() > 0: g_migrate_defines ++ line_directive ++ raw_source else: line_directive ++ raw_source

    // Pass to libclang via cimport_parse
    let session = with_cimport_parse(source)
    if session == 0:
        eprint("migrate: failed to parse " ++ input_path)
        return 1

    let err_msg = with_cimport_error(session)
    if err_msg.len() > 0:
        eprint("migrate: parse error: " ++ err_msg)
        with_cimport_dispose(session)
        return 1

    g_migrate_macro_values = ""
    let macro_include = if g_migrate_defines.len() > 0:
        g_migrate_defines ++ "#include \"" ++ input_path ++ "\"\n"
    else:
        "#include \"" ++ input_path ++ "\"\n"
    let macro_session = with_cimport_parse_macros(macro_include)
    if macro_session != 0:
        ci_capture_macro_values(macro_session)

    var output = "// Generated by: with migrate " ++ input_path ++ "\n\n"

    // Self-contained preamble — no std imports.
    // Inline ctype helpers (pure functions, no dependencies).
    output = output ++ "fn is_alpha(c: i32) -> bool: (c >= 65 and c <= 90) or (c >= 97 and c <= 122)\n"
    output = output ++ "fn is_digit(c: i32) -> bool: c >= 48 and c <= 57\n"
    output = output ++ "fn is_space(c: i32) -> bool: c == 32 or c == 9 or c == 10 or c == 13 or c == 12 or c == 11\n"
    output = output ++ "fn is_alnum(c: i32) -> bool: is_alpha(c) or is_digit(c)\n"
    output = output ++ "fn is_upper(c: i32) -> bool: c >= 65 and c <= 90\n"
    output = output ++ "fn is_lower(c: i32) -> bool: c >= 97 and c <= 122\n"
    output = output ++ "fn is_xdigit(c: i32) -> bool: (c >= 48 and c <= 57) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)\n"
    output = output ++ "fn is_print(c: i32) -> bool: c >= 32 and c <= 126\n"
    output = output ++ "fn to_lower(c: i32) -> i32: if c >= 65 and c <= 90: c + 32 else: c\n"
    output = output ++ "fn to_upper(c: i32) -> i32: if c >= 97 and c <= 122: c - 32 else: c\n"
    // String functions from libc (linker has libSystem)
    output = output ++ "extern fn strlen(s: *const i8) -> i64\n"
    output = output ++ "extern fn strcmp(a: *const i8, b: *const i8) -> i32\n"
    output = output ++ "extern fn strncmp(a: *const i8, b: *const i8, n: i64) -> i32\n"
    output = output ++ "extern fn memchr(s: *const i8, c: i32, n: i64) -> *i8\n"
    output = output ++ "fn string_len(s: *const i8) -> i64: strlen(s)\n"
    output = output ++ "fn string_cmp(a: *const i8, b: *const i8) -> i32: strcmp(a, b)\n"
    output = output ++ "\n"

    let count = with_cimport_decl_count(session)

    // Emit c_void opaque type
    if with_cimport_is_name_emitted("c_void") == 0:
        output = output ++ "type c_void = opaque\n"
        with_cimport_mark_name_emitted("c_void")

    // Emit C type aliases
    if with_cimport_is_name_emitted("c_char") == 0:
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

    // Emit builtin and runtime wrappers
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
        // Memory operations from rt_core.o — all use *i8, cast at call site
        output = output ++ "extern fn with_alloc(size: i64) -> *i8\n"
        output = output ++ "extern fn with_free(ptr: *i8) -> void\n"
        output = output ++ "extern fn with_memcpy(dst: *i8, src: *i8, n: i64) -> void\n"
        output = output ++ "extern fn with_memmove(dst: *i8, src: *i8, n: i64) -> void\n"
        output = output ++ "extern fn with_memset(ptr: *i8, c: i32, n: i64) -> void\n"
        output = output ++ "extern fn with_memcmp(a: *i8, b: *i8, n: i64) -> i32\n"
        with_cimport_mark_name_emitted("with_clz")

    output = output ++ "\n"

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
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_FUNCTION:
            output = output ++ ci_migrate_translate_function(session, i, translated_structs)
        else if kind == CK_STRUCT or kind == CK_UNION:
            let struct_result = ci_translate_struct(session, i, kind == CK_UNION, translated_structs, demoted_types, typedef_shadowed)
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
        else if kind == CK_VAR:
            output = output ++ ci_translate_var(session, i, translated_structs)
        else if kind == CK_TYPEDEF:
            let td_result = ci_translate_typedef(session, i, translated_structs)
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

    // Member function detection
    output = output ++ ci_detect_member_functions(session, count, translated_structs)

    with_cimport_dispose(session)

    // Macro translation via separate preprocessor pass
    if macro_session != 0:
        output = output ++ ci_translate_macros(macro_session, extern_vars)
        with_cimport_dispose_macros(macro_session)
    g_migrate_macro_values = ""

    // Write output
    let write_result = with_fs_write_file(output_path, output)
    if write_result != 0:
        eprint("migrate: failed to write " ++ output_path)
        g_migrate_macro_values = ""
        return 1

    // Print stats
    let goto_count = ci_count_substring(output, "__pc =")
    let unsafe_count = ci_count_substring(output, "unsafe")
    eprint(f"migrate: {input_path} -> {output_path} ({goto_count} gotos, {unsafe_count} unsafe)")
    0

// Translate a directory of .c files to .w files.
pub fn migrate_c_directory(input_dir: str, output_dir: str) -> i32:
    // Create output directory
    with_fs_mkdir_p(output_dir)

    // Find all .c files using shell
    let find_cmd = "find '" ++ ci_shell_escape(input_dir) ++ "' -name '*.c' -not -name '.*' -type f 2>/dev/null"
    let find_result = with_fs_read_file_cmd(find_cmd)
    if find_result.len() == 0:
        eprint("migrate: no .c files found in " ++ input_dir)
        return 1

    // Parse the file list (newline-separated)
    var files_scanned = 0
    var files_migrated = 0
    var total_gotos = 0
    var total_unsafe = 0
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
                files_scanned = files_scanned + 1
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

                let rc = migrate_c_file(file_path, out_path)
                if rc == 0:
                    files_migrated = files_migrated + 1
        pos = line_end + 1

    let files_failed = files_scanned - files_migrated
    if files_failed > 0:
        eprint(f"migrate: {files_migrated}/{files_scanned} files migrated ({files_failed} failed) from {input_dir} -> {output_dir}")
        return 1
    eprint(f"migrate: {files_migrated}/{files_scanned} files migrated from {input_dir} -> {output_dir}")
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

    // Unsupported types — emit stub
    if has_unsupported:
        return "fn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"untranslatable: " ++ unsupported_reason ++ "\")\n\n"

    // @[c_export] for non-static functions (preserves C ABI)
    let export_prefix = if storage != CX_SC_STATIC: "@[c_export(\"" ++ name ++ "\")]\n" else: ""

    // Try to translate the function body
    let body = ci_try_translate_fn_body(session, idx)
    if body.len() > 0:
        let ret_suffix = if ret == "void": "" else: " -> " ++ ret
        return export_prefix ++ "fn " ++ safe_name ++ "(" ++ params ++ ")" ++ ret_suffix ++ ":\n" ++ body ++ "\n"

    // Body translation failed — emit as extern fn (system header function
    // or function with untranslatable body). This is the graceful demotion
    // pattern from Zig's translate-c.
    let cc = with_cimport_fn_calling_conv(session, idx)
    let cc_prefix = if cc != "c" and cc.len() > 0: "@[callconv(\"" ++ cc ++ "\")]\n" else: ""
    cc_prefix ++ "extern fn " ++ safe_name ++ "(" ++ params ++ ") -> " ++ ret ++ "\n"

// Count occurrences of a substring in a string
// ── Goto elimination: state-variable transform ─────────────

// Check if a function body assigns to a variable with the given name.
// Used to detect which function parameters need var rebinding.
fn ci_body_assigns_to(session: i64, cursor: i32, name: str) -> bool:
    let kind = with_ci_cursor_kind(session, cursor)
    // Binary assignment: lhs = rhs (kind 114 = BinaryOp)
    if kind == CXK_BINARY_OP:
        let op = with_ci_binary_op(session, cursor)
        if op >= 18:  // BO_ASSIGN or compound assign (18-29)
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
        if op >= 6 and op <= 9:  // UO_PRE_INC through UO_POST_DEC
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

// Collect all labels in a function body, assign state IDs.
// Returns pipe-delimited map: "|label1=1|label2=2|..."
// State 0 is the entry block (not a label).
fn ci_collect_labels(session: i64, cursor: i32) -> str:
    var result = ""
    var next_state = 1
    ci_collect_labels_rec(session, cursor, &mut result, &mut next_state)
    result

fn ci_collect_labels_rec(session: i64, cursor: i32, result: &mut str, next_state: &mut i32):
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_LABEL_STMT:
        let name = with_ci_cursor_spelling(session, cursor)
        *result = *result ++ "|" ++ name ++ "=" ++ i64_to_string(*next_state as i64) ++ "|"
        *next_state = *next_state + 1
    let nc = with_ci_num_children(session, cursor)
    var i = 0
    while i < nc:
        ci_collect_labels_rec(session, with_ci_child(session, cursor, i), result, next_state)
        i = i + 1

// Look up a label name in the label map, return its state ID.
fn ci_label_state(label_map: str, label_name: str) -> i32:
    let needle = "|" ++ label_name ++ "="
    let pos = ci_find_substr(label_map, needle)
    if pos < 0:
        return -1
    // Extract the number after "="
    let start = pos + needle.len() as i32
    var end = start
    let map_len = label_map.len() as i32
    while end < map_len and label_map.byte_at(end as i64) != 124:  // '|'
        end = end + 1
    if end > start:
        let num_str = label_map.slice(start as i64, end as i64)
        // Simple string-to-int
        var val = 0
        var di = 0
        while di < num_str.len() as i32:
            let c = num_str.byte_at(di as i64)
            if c >= 48 and c <= 57:
                val = val * 10 + (c - 48)
            di = di + 1
        return val
    -1

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

// Collect all variable declarations in a function body (for hoisting).
// Returns parallel pipe-delimited lists of names and types.
fn ci_collect_var_decls(session: i64, cursor: i32, names: &mut str, types: &mut str):
    let kind = with_ci_cursor_kind(session, cursor)
    if kind == CXK_DECL_STMT:
        let nc = with_ci_num_children(session, cursor)
        var i = 0
        while i < nc:
            let child = with_ci_child(session, cursor, i)
            if with_ci_cursor_kind(session, child) == 9:  // CXK_VAR_DECL
                let vname = ci_escape_reserved(with_ci_cursor_spelling(session, child))
                let vty = with_ci_cursor_type(session, child)
                let vty_str = with_ci_type_translated(session, vty)
                if not ci_str_contains(*names, "|" ++ vname ++ "|"):
                    *names = *names ++ "|" ++ vname ++ "|"
                    *types = *types ++ "|" ++ vty_str ++ "|"
            i = i + 1
    // Recurse into children
    let nc = with_ci_num_children(session, cursor)
    var ci = 0
    while ci < nc:
        ci_collect_var_decls(session, with_ci_child(session, cursor, ci), names, types)
        ci = ci + 1

// Translate a goto-containing function body as a state machine.
// Emits: hoisted vars, var __pc = 0, while true: match __pc: arms
fn ci_trans_goto_body(session: i64, body_cursor: i32, indent: i32, scope: str) -> str:
    let label_map = ci_collect_labels(session, body_cursor)

    // Collect and hoist variable declarations.
    // Skip vars that are already in the scope (param rebindings).
    var var_names = ""
    var var_types = ""
    ci_collect_var_decls(session, body_cursor, &mut var_names, &mut var_types)
    // Remove hoisted vars that are already param-rebound (in scope)
    var filtered_names = ""
    var filtered_types = ""
    var fvi = 1
    var ftype_idx = 0
    let flen = var_names.len() as i32
    while fvi < flen:
        var fve = fvi
        while fve < flen and var_names.byte_at(fve as i64) != 124:
            fve = fve + 1
        let vn = var_names.slice(fvi as i64, fve as i64)
        if not ci_str_contains(scope, "|" ++ vn ++ "|"):
            filtered_names = filtered_names ++ "|" ++ vn ++ "|"
            let vt = ci_get_nth_pipe_entry(var_types, ftype_idx)
            filtered_types = filtered_types ++ "|" ++ vt ++ "|"
        ftype_idx = ftype_idx + 1
        fvi = fve + 1
        if fvi < flen and var_names.byte_at(fvi as i64) == 124:
            fvi = fvi + 1
    var_names = filtered_names
    var_types = filtered_types

    var output = ""

    // Emit hoisted variable declarations
    var vi = 1  // skip leading |
    while vi < var_names.len() as i32:
        // Extract name
        var name_end = vi
        while name_end < var_names.len() as i32 and var_names.byte_at(name_end as i64) != 124:
            name_end = name_end + 1
        let vname = var_names.slice(vi as i64, name_end as i64)
        // Extract type at same position in var_types
        var ti = 1
        var type_idx = 0
        var target_idx = 0
        // Count which var index this is
        var count_vi = 1
        var var_index = 0
        while count_vi < vi:
            if var_names.byte_at(count_vi as i64) == 124:
                var_index = var_index + 1
            count_vi = count_vi + 1
        // Walk to the same index in var_types
        var cur_type_idx = 0
        while ti < var_types.len() as i32:
            if cur_type_idx == var_index:
                break
            if var_types.byte_at(ti as i64) == 124:
                cur_type_idx = cur_type_idx + 1
                ti = ti + 1
                continue
            ti = ti + 1
        var type_end = ti
        while type_end < var_types.len() as i32 and var_types.byte_at(type_end as i64) != 124:
            type_end = type_end + 1
        let vtype = var_types.slice(ti as i64, type_end as i64)
        let default_val = ci_default_for_type(vtype)
        if default_val.len() > 0:
            output = output ++ ci_indent_str(indent) ++ "var " ++ vname ++ ": " ++ vtype ++ " = " ++ default_val ++ "\n"
        else:
            // Zero-init: var x: T (no initializer — With zero-initializes)
            output = output ++ ci_indent_str(indent) ++ "var " ++ vname ++ ": " ++ vtype ++ "\n"

        vi = name_end + 1
        if vi < var_names.len() as i32 and var_names.byte_at(vi as i64) == 124:
            vi = vi + 1  // skip separator

    // Emit state machine dispatch loop
    output = output ++ ci_indent_str(indent) ++ "var __pc: i32 = 0\n"
    output = output ++ ci_indent_str(indent) ++ "var __goto_pending: i32 = 0\n"
    output = output ++ ci_indent_str(indent) ++ "while true:\n"
    output = output ++ ci_indent_str(indent + 1) ++ "match __pc\n"

    // Walk body children, assigning each label's block to its state
    let nc = with_ci_num_children(session, body_cursor)
    var current_state = 0
    var arm_has_content = false
    // Emit entry state arm
    output = output ++ ci_indent_str(indent + 2) ++ "0 =>\n"
    output = output ++ ci_indent_str(indent + 3) ++ "(__goto_pending = 0)\n"

    var i = 0
    while i < nc:
        let child = with_ci_child(session, body_cursor, i)
        let kind = with_ci_cursor_kind(session, child)

        if kind == CXK_LABEL_STMT:
            // Close current arm with fallthrough to next state
            let label_name = with_ci_cursor_spelling(session, child)
            let target_state = ci_label_state(label_map, label_name)
            if target_state >= 0:
                if not arm_has_content:
                    output = output ++ ci_indent_str(indent + 3) ++ "// empty\n"
                output = output ++ ci_indent_str(indent + 3) ++ "__pc = " ++ i64_to_string(target_state as i64) ++ "\n" ++ ci_indent_str(indent + 3) ++ "continue\n"
                // Start new arm for this label
                current_state = target_state
                output = output ++ ci_indent_str(indent + 2) ++ i64_to_string(target_state as i64) ++ " =>  // " ++ label_name ++ "\n"
                output = output ++ ci_indent_str(indent + 3) ++ "(__goto_pending = 0)\n"
                arm_has_content = false
            // Translate the label's body child (child[0] of LabelStmt)
            let lnc = with_ci_num_children(session, child)
            if lnc > 0:
                let label_body = with_ci_child(session, child, 0)
                let lbk = with_ci_cursor_kind(session, label_body)
                if lbk != CXK_LABEL_STMT:  // avoid double-processing nested labels
                    let s = ci_trans_stmt_goto(session, label_body, 0, scope, label_map, 0)
                    if s.len() > 0:
                        output = output ++ ci_indent_block(s, indent + 3)
                        output = output ++ ci_indent_str(indent + 3) ++ "if (if __goto_pending != 0: 1 else: 0) != 0:\n"
                        output = output ++ ci_indent_str(indent + 4) ++ "continue\n"
                        arm_has_content = true

        else if kind == CXK_GOTO_STMT:
            // LLVM 22: goto target label is in child[0] (CXCursor_LabelRef)
            var target_label = ""
            let gnc = with_ci_num_children(session, child)
            if gnc > 0:
                target_label = with_ci_cursor_spelling(session, with_ci_child(session, child, 0))
            if target_label.len() == 0:
                target_label = with_ci_cursor_spelling(session, child)
            let target_state = ci_label_state(label_map, target_label)
            if target_state >= 0:
                output = output ++ ci_indent_str(indent + 3) ++ "__pc = " ++ i64_to_string(target_state as i64) ++ "\n" ++ ci_indent_str(indent + 3) ++ "continue\n"
                arm_has_content = true

        else if kind == CXK_DECL_STMT:
            // Variable declarations: emit only the initializer assignment (var was hoisted)
            let dnc = with_ci_num_children(session, child)
            var di = 0
            while di < dnc:
                let dchild = with_ci_child(session, child, di)
                if with_ci_cursor_kind(session, dchild) == 9:  // VarDecl
                    let vname = ci_escape_reserved(with_ci_cursor_spelling(session, dchild))
                    let init_nc = with_ci_num_children(session, dchild)
                    if init_nc > 0:
                        let init_expr = ci_trans_expr(session, with_ci_child(session, dchild, 0), scope)
                        if init_expr.len() > 0:
                            output = output ++ ci_indent_str(indent + 3) ++ vname ++ " = " ++ init_expr ++ "\n"
                            arm_has_content = true
                di = di + 1

        else:
            let s = ci_trans_stmt_goto(session, child, 0, scope, label_map, 0)
            if s.len() > 0:
                output = output ++ ci_indent_block(s, indent + 3)
                output = output ++ ci_indent_str(indent + 3) ++ "if (if __goto_pending != 0: 1 else: 0) != 0:\n"
                output = output ++ ci_indent_str(indent + 4) ++ "continue\n"
                arm_has_content = true

        i = i + 1

    // Close the last arm
    if not arm_has_content:
        output = output ++ ci_indent_str(indent + 3) ++ "// empty\n"

    // Default arm
    output = output ++ ci_indent_str(indent + 2) ++ "_ => break\n"
    output

// Translate a statement inside a goto-containing function.
// Same as ci_trans_stmt but replaces goto with __pc = N; continue
// and labels with state transitions.
fn ci_trans_stmt_goto(session: i64, cursor: i32, indent: i32, scope: str, label_map: str, loop_depth: i32) -> str:
    let kind = with_ci_cursor_kind(session, cursor)

    // Goto → state transition
    // In LLVM 22, the goto target label is in the goto's child (CXCursor_LabelRef, kind 48)
    if kind == CXK_GOTO_STMT:
        var target_label = ""
        let gnc = with_ci_num_children(session, cursor)
        if gnc > 0:
            target_label = with_ci_cursor_spelling(session, with_ci_child(session, cursor, 0))
        if target_label.len() == 0:
            target_label = with_ci_cursor_spelling(session, cursor)
        let target_state = ci_label_state(label_map, target_label)
        if target_state >= 0:
            return "__pc = " ++ i64_to_string(target_state as i64) ++ "\n__goto_pending = 1"
        return "comptime_error(\"unknown goto target: " ++ target_label ++ "\")"

    // Label → just translate the body
    if kind == CXK_LABEL_STMT:
        let lnc = with_ci_num_children(session, cursor)
        if lnc > 0:
            return ci_trans_stmt_goto(session, with_ci_child(session, cursor, 0), indent, scope, label_map, loop_depth)
        return ""

    // Compound statement — recurse into children with goto awareness
    if kind == CXK_COMPOUND_STMT:
        let nc = with_ci_num_children(session, cursor)
        var body = ""
        var i = 0
        while i < nc:
            let child = with_ci_child(session, cursor, i)
            let s = ci_trans_stmt_goto(session, child, 0, scope, label_map, loop_depth)
            if s.len() > 0:
                body = body ++ ci_indent_block(s, indent)
                body = body ++ ci_indent_str(indent) ++ "if (if __goto_pending != 0: 1 else: 0) != 0:\n"
                body = body ++ ci_indent_str(indent + 1) ++ (if loop_depth > 0: "break" else: "continue") ++ "\n"
            i = i + 1
        return body

    // If statement — recurse into then/else with goto awareness
    if kind == CXK_IF_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let cond = ci_trans_bool_expr(session, with_ci_child(session, cursor, 0), scope)
            if cond.len() > 0:
                let then_child = with_ci_child(session, cursor, 1)
                let then_body = ci_trans_stmt_goto(session, then_child, 0, scope, label_map, loop_depth)
                if then_body.len() > 0:
                    let then_text = ci_indent_block(then_body, indent + 1)
                    var result = "if " ++ cond ++ ":\n" ++ then_text
                    if nc > 2:
                        let else_child = with_ci_child(session, cursor, 2)
                        let else_body = ci_trans_stmt_goto(session, else_child, 0, scope, label_map, loop_depth)
                        if else_body.len() > 0:
                            let else_text = ci_indent_block(else_body, indent + 1)
                            result = result ++ ci_indent_str(indent) ++ "else:\n" ++ else_text
                    return result
        return ""

    // While — recurse with goto awareness
    if kind == CXK_WHILE_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let cond = ci_trans_bool_expr(session, with_ci_child(session, cursor, 0), scope)
            if cond.len() > 0:
                let body = ci_trans_stmt_goto(session, with_ci_child(session, cursor, 1), 0, scope, label_map, loop_depth + 1)
                if body.len() > 0:
                    let body_text = ci_indent_block(body, indent + 1)
                    var result = "while " ++ cond ++ ":\n" ++ body_text
                    result = result ++ ci_indent_str(indent + 1) ++ "if (if __goto_pending != 0: 1 else: 0) != 0:\n"
                    result = result ++ ci_indent_str(indent + 2) ++ "break\n"
                    return result
        return ""

    // For statement — translate to init + while + inc
    if kind == CXK_FOR_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 1:
            let body_idx = nc - 1
            let body_cursor = with_ci_child(session, cursor, body_idx)
            let body = ci_trans_stmt_goto(session, body_cursor, 0, scope, label_map, loop_depth + 1)
            if body.len() == 0:
                return ""

            var init_str = ""
            var cond_str = "true"
            var inc_str = ""
            if nc == 4:
                // Use goto-aware handler so DeclStmt becomes assignment (var was hoisted)
                init_str = ci_trans_stmt_goto(session, with_ci_child(session, cursor, 0), indent, scope, label_map, loop_depth)
                let cond_e = ci_trans_bool_expr(session, with_ci_child(session, cursor, 1), scope)
                if cond_e.len() > 0:
                    cond_str = cond_e
                inc_str = ci_trans_expr(session, with_ci_child(session, cursor, 2), scope)
            else if nc == 3:
                let first = with_ci_child(session, cursor, 0)
                let second = with_ci_child(session, cursor, 1)
                let first_kind = with_ci_cursor_kind(session, first)
                if first_kind == CXK_DECL_STMT:
                    init_str = ci_trans_stmt_goto(session, first, indent, scope, label_map, loop_depth)
                    let cond_e = ci_trans_bool_expr(session, second, scope)
                    if cond_e.len() > 0:
                        cond_str = cond_e
                else:
                    let cond_e = ci_trans_bool_expr(session, first, scope)
                    if cond_e.len() > 0:
                        cond_str = cond_e
                    inc_str = ci_trans_expr(session, second, scope)
            else if nc == 2:
                let cond_e = ci_trans_bool_expr(session, with_ci_child(session, cursor, 0), scope)
                if cond_e.len() > 0:
                    cond_str = cond_e

            let body_text = ci_indent_block(body, indent + 1)
            var result = ""
            if init_str.len() > 0:
                result = result ++ init_str ++ "\n" ++ ci_indent_str(indent)
            result = result ++ "while " ++ cond_str ++ ":\n" ++ body_text
            if inc_str.len() > 0:
                result = result ++ ci_indent_str(indent + 1) ++ inc_str ++ "\n"
            result = result ++ ci_indent_str(indent + 1) ++ "if (if __goto_pending != 0: 1 else: 0) != 0:\n"
            result = result ++ ci_indent_str(indent + 2) ++ "break\n"
            return result
        return ""

    // Do-while — recurse with goto awareness
    if kind == CXK_DO_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let body = ci_trans_stmt_goto(session, with_ci_child(session, cursor, 0), 0, scope, label_map, loop_depth + 1)
            let cond = ci_trans_bool_expr(session, with_ci_child(session, cursor, 1), scope)
            if body.len() > 0 and cond.len() > 0:
                let body_text = ci_indent_block(body, indent + 1)
                var result = "while true:\n" ++ body_text
                result = result ++ ci_indent_str(indent + 1) ++ "if (if __goto_pending != 0: 1 else: 0) != 0:\n"
                result = result ++ ci_indent_str(indent + 2) ++ "break\n"
                result = result ++ ci_indent_str(indent + 1) ++ "if not (" ++ cond ++ "):\n"
                result = result ++ ci_indent_str(indent + 2) ++ "break\n"
                return result
        return ""

    // Switch statement — recurse into case/default prongs with goto awareness
    if kind == CXK_SWITCH_STMT:
        let nc = with_ci_num_children(session, cursor)
        if nc >= 2:
            let cond = ci_trans_expr(session, with_ci_child(session, cursor, 0), scope)
            if cond.len() > 0:
                let body_cursor = with_ci_child(session, cursor, 1)
                return ci_trans_switch_body_goto(session, body_cursor, cond, indent, scope, label_map, loop_depth)
        return ""

    // Declaration statement inside goto body — variable was hoisted,
    // so emit assignment instead of re-declaration to avoid shadowing.
    if kind == CXK_DECL_STMT:
        let nc = with_ci_num_children(session, cursor)
        var result = ""
        var di = 0
        while di < nc:
            let dchild = with_ci_child(session, cursor, di)
            if with_ci_cursor_kind(session, dchild) == CXK_VAR_DECL:
                let vname = ci_escape_reserved(with_ci_cursor_spelling(session, dchild))
                let init_nc = with_ci_num_children(session, dchild)
                if init_nc > 0:
                    let init_expr = ci_trans_expr(session, with_ci_child(session, dchild, 0), scope)
                    if init_expr.len() > 0:
                        if result.len() > 0:
                            result = result ++ "\n"
                        result = result ++ vname ++ " = " ++ init_expr
            di = di + 1
        return result

    // Everything else: use the normal translator (break, continue, return, etc.)
    ci_trans_stmt(session, cursor, indent, scope)

// Find a function cursor in the cursor tree by name.
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

// Check if a declaration name is from a system header (not the user's code).
// This filters out the noise from stdlib.h, string.h, ctype.h, etc.
fn ci_is_system_decl(name: str) -> bool:
    if name.len() == 0: return true
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
    if name == "isalpha" or name == "isdigit" or name == "isalnum" or name == "isspace": return true
    if name == "isupper" or name == "islower" or name == "isxdigit" or name == "isprint": return true
    if name == "tolower" or name == "toupper": return true
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
fn ci_map_libc_call(callee: str, args: str) -> str:
    // Memory allocation — use runtime externs with pointer casts
    if callee == "malloc":
        return "with_alloc(" ++ args ++ " as i64)"
    if callee == "free":
        return "with_free(" ++ args ++ " as *i8)"
    if callee == "calloc":
        return "alloc_zeroed(" ++ args ++ ")"
    if callee == "realloc":
        return "realloc_mem(" ++ args ++ ")"

    // Memory operations — cast pointer args to *mut u8 / *const u8
    if callee == "memcpy":
        return "with_memcpy(" ++ ci_cast_memcpy_args(args) ++ ")"
    if callee == "memmove":
        return "with_memmove(" ++ ci_cast_memcpy_args(args) ++ ")"
    if callee == "memset":
        return "with_memset(" ++ ci_cast_memset_args(args) ++ ")"
    if callee == "memcmp":
        return "with_memcmp(" ++ ci_cast_memcmp_args(args) ++ ")"

    // String operations
    if callee == "strlen":
        return "string_len(" ++ args ++ ")"
    if callee == "strcmp":
        return "string_cmp(" ++ args ++ ")"
    if callee == "strncmp":
        return "strncmp(" ++ args ++ ")"
    if callee == "strchr":
        return "string_find_char(" ++ args ++ ")"

    // Character classification (these are in std prelude)
    if callee == "isalpha":
        return "is_alpha(" ++ args ++ ")"
    if callee == "isdigit":
        return "is_digit(" ++ args ++ ")"
    if callee == "isalnum":
        return "is_alnum(" ++ args ++ ")"
    if callee == "isspace":
        return "is_space(" ++ args ++ ")"
    if callee == "isupper":
        return "is_upper(" ++ args ++ ")"
    if callee == "islower":
        return "is_lower(" ++ args ++ ")"
    if callee == "isxdigit":
        return "is_xdigit(" ++ args ++ ")"
    if callee == "isprint":
        return "is_print(" ++ args ++ ")"
    if callee == "tolower":
        return "to_lower(" ++ args ++ ")"
    if callee == "toupper":
        return "to_upper(" ++ args ++ ")"
    if callee == "isgraph":
        return "(if is_print(" ++ args ++ ") and not is_space(" ++ args ++ "): 1 else: 0)"
    if callee == "ispunct":
        return "(if is_print(" ++ args ++ ") and not is_alnum(" ++ args ++ ") and not is_space(" ++ args ++ "): 1 else: 0)"
    if callee == "iscntrl":
        return "(if (" ++ args ++ ") < 32 or (" ++ args ++ ") == 127: 1 else: 0)"

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
