// CImport — C header import via libclang bridge.
//
// Parses C headers using libclang (via clang_bridge.c) and generates
// synthetic extern fn / type declarations as .w source text.
// Falls back gracefully when libclang is unavailable.

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
extern fn with_cimport_fn_is_variadic(session: i64, idx: i32) -> i32
extern fn with_cimport_struct_field_count(session: i64, idx: i32) -> i32
extern fn with_cimport_struct_field_name(session: i64, idx: i32, field: i32) -> str
extern fn with_cimport_struct_field_type(session: i64, idx: i32, field: i32) -> str
extern fn with_cimport_struct_is_opaque(session: i64, idx: i32) -> i32
extern fn with_cimport_enum_const_count(session: i64, idx: i32) -> i32
extern fn with_cimport_enum_const_name(session: i64, idx: i32, ci: i32) -> str
extern fn with_cimport_enum_const_value(session: i64, idx: i32, ci: i32) -> i64
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
extern fn int_to_string(n: i32) -> str
extern fn i64_to_string(n: i64) -> str
extern fn with_eprintln(s: str) -> void

// CXCursorKind constants
let CK_STRUCT: i32 = 2
let CK_UNION: i32 = 3
let CK_ENUM: i32 = 5
let CK_FUNCTION: i32 = 8
let CK_TYPEDEF: i32 = 20

// Process a c_import header spec and return synthetic .w source text.
// Returns "" if the bridge is unavailable or parsing fails.
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

    // Track translated struct names for typedef resolution
    var translated_structs = ""

    var i = 0
    while i < count:
        let kind = with_cimport_decl_kind(session, i)
        if kind == CK_FUNCTION:
            output = output ++ ci_translate_function(session, i)
        else if kind == CK_STRUCT or kind == CK_UNION:
            let struct_result = ci_translate_struct(session, i, kind == CK_UNION)
            output = output ++ struct_result
            // Track struct name for typedef resolution
            let sname = with_cimport_decl_name(session, i)
            if sname.len() > 0 and sname.byte_at(0) != 95:
                translated_structs = translated_structs ++ "|" ++ sname ++ "|"
        else if kind == CK_ENUM:
            output = output ++ ci_translate_enum(session, i)
        else if kind == CK_TYPEDEF:
            output = output ++ ci_translate_typedef(session, i, translated_structs)
        i = i + 1

    with_cimport_dispose(session)
    output

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

// ── Function translation ────────────────────────────────────

fn ci_translate_function(session: i64, idx: i32) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip internal names (starting with _)
    if name.byte_at(0) == 95:
        return ""

    // Skip already-emitted names (dedup across c_import calls)
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    let safe_name = ci_escape_reserved(name)
    let param_count = with_cimport_fn_param_count(session, idx)
    let is_variadic = with_cimport_fn_is_variadic(session, idx)

    var params = ""
    for pi in 0..param_count:
        if pi > 0:
            params = params ++ ", "
        let pname = with_cimport_fn_param_name(session, idx, pi)
        let ptype_raw = with_cimport_fn_param_type(session, idx, pi)
        let ptype = ci_map_c_type(ptype_raw)

        if pname.len() > 0:
            params = params ++ ci_escape_reserved(pname) ++ ": " ++ ptype
        else:
            params = params ++ "p" ++ int_to_string(pi) ++ ": " ++ ptype

    if is_variadic != 0:
        if param_count > 0:
            params = params ++ ", ..."
        else:
            params = params ++ "..."

    let ret_raw = with_cimport_fn_return_type(session, idx)
    let ret = ci_map_c_type(ret_raw)

    with_cimport_mark_name_emitted(name)
    "extern fn " ++ safe_name ++ "(" ++ params ++ ") -> " ++ ret ++ "\n"

// ── Struct/Union translation ────────────────────────────────

fn ci_translate_struct(session: i64, idx: i32, is_union: bool) -> str:
    let name = with_cimport_decl_name(session, idx)
    if name.len() == 0:
        return ""

    // Skip internal names
    if name.byte_at(0) == 95:
        return ""

    // Skip already-emitted names
    if with_cimport_is_name_emitted(name) != 0:
        return ""

    if with_cimport_struct_is_opaque(session, idx) != 0:
        return ""

    let field_count = with_cimport_struct_field_count(session, idx)
    if field_count == 0:
        return ""

    with_cimport_mark_name_emitted(name)
    let safe_name = ci_escape_reserved(name)
    let field_str = ci_build_struct_fields(session, idx, field_count)
    let part1 = "type " ++ safe_name
    let part2 = part1 ++ " = \{ "
    let part3 = part2 ++ field_str
    let decl = part3 ++ " }\n"
    if is_union:
        return "// union\n" ++ decl
    decl

fn ci_build_struct_fields(session: i64, idx: i32, field_count: i32) -> str:
    if field_count == 0:
        return ""
    if field_count == 1:
        return ci_build_one_field(session, idx, 0)
    // Build fields iteratively using a helper to avoid mutable var in loop
    var result = ci_build_one_field(session, idx, 0)
    var fi = 1
    while fi < field_count:
        result = result ++ ", " ++ ci_build_one_field(session, idx, fi)
        fi = fi + 1
    result

fn ci_build_one_field(session: i64, idx: i32, fi: i32) -> str:
    let fname = with_cimport_struct_field_name(session, idx, fi)
    let ftype_raw = with_cimport_struct_field_type(session, idx, fi)
    let ftype = ci_map_c_type(ftype_raw)
    let safe_fname = ci_escape_reserved(fname)
    safe_fname ++ ": " ++ ftype

// ── Enum translation ────────────────────────────────────────

fn ci_translate_enum(session: i64, idx: i32) -> str:
    let const_count = with_cimport_enum_const_count(session, idx)
    if const_count == 0:
        return ""

    var output = ""
    for ci in 0..const_count:
        let cname = with_cimport_enum_const_name(session, idx, ci)
        let cvalue = with_cimport_enum_const_value(session, idx, ci)
        if cname.len() == 0:
            continue
        // Skip internal names
        if cname.byte_at(0) == 95:
            continue
        // Skip already-emitted names (dedup across c_import calls)
        if with_cimport_is_name_emitted(cname) != 0:
            continue
        with_cimport_mark_name_emitted(cname)
        let safe_cname = ci_escape_reserved(cname)
        output = output ++ "let " ++ safe_cname ++ ": i32 = " ++ i64_to_string(cvalue) ++ "\n"
    output

// ── Typedef translation ─────────────────────────────────────

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

    let underlying = with_cimport_typedef_underlying(session, idx)

    // Emit type alias for struct typedefs
    if ci_starts_with(underlying, "struct "):
        let struct_name = underlying.slice(7, underlying.len())
        // Remove trailing space if any
        let clean_name = ci_trim(struct_name)
        if ci_str_contains(translated_structs, clean_name):
            let safe_name = ci_escape_reserved(name)
            let safe_struct = ci_escape_reserved(clean_name)
            return "type " ++ safe_name ++ " = " ++ safe_struct ++ "\n"

    // Transparent typedef — don't emit anything
    ""

// ── Macro translation ───────────────────────────────────────

fn ci_translate_macros(session: i64) -> str:
    let count = with_cimport_macro_count(session)
    var output = ""
    for i in 0..count:
        let name = with_cimport_macro_name(session, i)
        let value = with_cimport_macro_value(session, i)
        let fn_like = with_cimport_macro_is_fn_like(session, i)

        // Skip function-like macros
        if fn_like != 0:
            continue

        // Skip empty macros (flag defines)
        if value.len() == 0:
            continue

        // Skip internal names
        if name.len() == 0:
            continue
        if name.byte_at(0) == 95:
            continue

        // Only translate simple integer and string literals
        if ci_is_int_literal(value):
            let safe_name = ci_escape_reserved(name)
            let clean_value = ci_strip_int_suffix(value)
            output = output ++ "let " ++ safe_name ++ ": i32 = " ++ clean_value ++ "\n"
        else if ci_is_string_literal(value):
            let safe_name = ci_escape_reserved(name)
            output = output ++ "let " ++ safe_name ++ " = " ++ value ++ "\n"
    output

// ── Type mapping ────────────────────────────────────────────

fn ci_map_c_type(spelling: str) -> str:
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
        let mapped_base = ci_map_c_type(base)
        return "*" ++ mapped_base

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

    // Map base type
    let is_known = ci_is_known_base_type(base)
    var mapped = ci_map_base_type(base)

    // For pointer to unknown type (struct, etc.), use opaque *const i8
    if ptr_depth > 0 and not is_known:
        return "*const i8"

    // Apply pointer wrapping
    if ptr_depth > 0:
        // void * → *const i8
        if mapped == "void":
            mapped = "i8"
            is_const = true
        // char * → *const i8 (C strings)
        if mapped == "i8":
            is_const = true

    if ptr_depth == 0:
        return mapped

    var result = mapped
    var pi = 0
    while pi < ptr_depth:
        if is_const:
            result = "*const " ++ result
        else:
            result = "*" ++ result
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
    if name == "float": return true
    if name == "double": return true
    if name == "long double": return true
    if ci_starts_with(name, "enum "): return true
    false

fn ci_map_base_type(name: str) -> str:
    if name == "void": return "void"
    if name == "_Bool": return "bool"
    if name == "char": return "i8"
    if name == "signed char": return "i8"
    if name == "unsigned char": return "u8"
    if name == "short": return "i16"
    if name == "unsigned short": return "u16"
    if name == "int": return "i32"
    if name == "unsigned int": return "u32"
    if name == "long": return "i64"
    if name == "unsigned long": return "u64"
    if name == "long long": return "i64"
    if name == "unsigned long long": return "u64"
    if name == "float": return "f32"
    if name == "double": return "f64"
    if name == "long double": return "f64"
    // enum E → i32 (C enums are integers)
    if ci_starts_with(name, "enum "):
        return "i32"
    // Unknown type → i32 (best we can do without struct support)
    "i32"

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
    name

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

fn ci_is_string_literal(s: str) -> bool:
    if s.len() < 2:
        return false
    s.byte_at(0) == 34 and s.byte_at(s.len() - 1) == 34
