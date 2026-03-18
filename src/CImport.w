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
extern fn with_cimport_var_type(session: i64, idx: i32) -> str
extern fn with_cimport_var_is_const(session: i64, idx: i32) -> i32
extern fn int_to_string(n: i32) -> str
extern fn i64_to_string(n: i64) -> str
extern fn with_eprintln(s: str) -> void

// CXCursorKind constants
let CK_STRUCT: i32 = 2
let CK_UNION: i32 = 3
let CK_ENUM: i32 = 5
let CK_FUNCTION: i32 = 8
let CK_VAR: i32 = 9
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
            output = output ++ ci_translate_function(session, i, translated_structs)
        else if kind == CK_STRUCT or kind == CK_UNION:
            let struct_result = ci_translate_struct(session, i, kind == CK_UNION, translated_structs)
            output = output ++ struct_result
            // Track struct name for typedef resolution (only if actually translated)
            if struct_result.len() > 0:
                let sname = with_cimport_decl_name(session, i)
                if sname.len() > 0 and sname.byte_at(0) != 95:
                    translated_structs = translated_structs ++ "|" ++ sname ++ "|"
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
        i = i + 1

    with_cimport_dispose(session)

    // Extract macros using a separate preprocessor pass
    let macro_session = with_cimport_parse_macros(include_text)
    if macro_session != 0:
        output = output ++ ci_translate_macros(macro_session)
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
        let candidate = name ++ "_" ++ int_to_string(suffix)
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

    let safe_name = ci_escape_reserved(name)
    let param_count = with_cimport_fn_param_count(session, idx)
    let is_variadic = with_cimport_fn_is_variadic(session, idx)

    var params = ""
    for pi in 0..param_count:
        if pi > 0:
            params = params ++ ", "
        let pname = with_cimport_fn_param_name(session, idx, pi)
        let ptype_raw = with_cimport_fn_param_type(session, idx, pi)
        let ptype = ci_map_c_type_ctx(ptype_raw, known_structs)

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
    let ret = ci_map_c_type_ctx(ret_raw, known_structs)

    with_cimport_mark_name_emitted(name)
    "extern fn " ++ safe_name ++ "(" ++ params ++ ") -> " ++ ret ++ "\n"

// ── Struct/Union translation ────────────────────────────────

fn ci_translate_struct(session: i64, idx: i32, is_union: bool, known_structs: str) -> str:
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
        with_cimport_mark_name_emitted(name)
        let safe_name = ci_escape_reserved(name)
        return "// opaque: " ++ safe_name ++ "\n"

    let field_count = with_cimport_struct_field_count(session, idx)
    if field_count == 0:
        return ""

    with_cimport_mark_name_emitted(name)
    let safe_name = ci_escape_reserved(name)
    let field_str = ci_build_struct_fields(session, idx, field_count, known_structs)
    let part1 = "type " ++ safe_name
    let part2 = part1 ++ " = \{ "
    let part3 = part2 ++ field_str
    let decl = part3 ++ " }\n"
    if is_union:
        return "// union\n" ++ decl
    decl

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
    let ftype_raw = with_cimport_struct_field_type(session, idx, fi)
    let ftype = ci_map_c_type_ctx(ftype_raw, known_structs)
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
        // Mangle colliding enum constant names instead of skipping
        let unique_cname = ci_unique_name(cname)
        with_cimport_mark_name_emitted(unique_cname)
        let safe_cname = ci_escape_reserved(unique_cname)
        output = output ++ "let " ++ safe_cname ++ ": i32 = " ++ i64_to_string(cvalue) ++ "\n"
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

    let var_type_raw = with_cimport_var_type(session, idx)
    let var_type = ci_map_c_type_ctx(var_type_raw, known_structs)

    let is_const = with_cimport_var_is_const(session, idx)
    let safe_name = ci_escape_reserved(name)
    with_cimport_mark_name_emitted(name)
    if is_const != 0:
        "extern let " ++ safe_name ++ ": " ++ var_type ++ "\n"
    else:
        "extern var " ++ safe_name ++ ": " ++ var_type ++ "\n"

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
    var known_values = ""
    for i in 0..count:
        let name = with_cimport_macro_name(session, i)
        let value = with_cimport_macro_value(session, i)
        let fn_like = with_cimport_macro_is_fn_like(session, i)

        // Emit function-like macros as comptime_error stubs
        if fn_like != 0:
            if name.len() > 0 and name.byte_at(0) != 95:
                if with_cimport_is_name_emitted(name) == 0:
                    with_cimport_mark_name_emitted(name)
                    let safe_name = ci_escape_reserved(name)
                    output = output ++ "fn " ++ safe_name ++ "() -> i32:\n    comptime_error(\"untranslatable C macro: " ++ name ++ "\")\n"
            continue

        // Skip empty macros (flag defines)
        if value.len() == 0:
            continue

        // Skip internal names
        if name.len() == 0:
            continue
        if name.byte_at(0) == 95:
            continue

        // Skip already-emitted names (dedup across c_import calls)
        if with_cimport_is_name_emitted(name) != 0:
            continue

        // Strip outer parentheses for macro values like (-1)
        let stripped = ci_strip_parens(value)

        if ci_is_int_literal(stripped):
            let safe_name = ci_escape_reserved(name)
            let clean_value = ci_strip_int_suffix(stripped)
            with_cimport_mark_name_emitted(name)
            known_values = known_values ++ name ++ "=" ++ clean_value ++ "|"
            output = output ++ "let " ++ safe_name ++ ": i32 = " ++ clean_value ++ "\n"
        else if ci_is_float_literal(stripped):
            let safe_name = ci_escape_reserved(name)
            let float_ty = ci_float_type_from_suffix(stripped)
            let clean_value = ci_strip_float_suffix(stripped)
            with_cimport_mark_name_emitted(name)
            output = output ++ "let " ++ safe_name ++ ": " ++ float_ty ++ " = " ++ clean_value ++ "\n"
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
                output = output ++ "let " ++ safe_name ++ ": i32 = " ++ eval_result ++ "\n"
    output

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
            return i64_to_string(nv)
        return ""
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
    // Identifier: look up in known values
    if ci_is_c_ident(trimmed):
        return ci_lookup_known(trimmed, known)
    ""

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
    if op == "+": return i64_to_string(lhs + rhs)
    if op == "-": return i64_to_string(lhs - rhs)
    if op == "*": return i64_to_string(lhs * rhs)
    if op == "/":
        if rhs == 0: return ""
        return i64_to_string(lhs / rhs)
    if op == "%":
        if rhs == 0: return ""
        return i64_to_string(lhs % rhs)
    // For bitwise ops, work on i32 (C macros are typically 32-bit)
    let li = lhs as i32
    let ri = rhs as i32
    if op == "<<": return int_to_string(ci_shl(li, ri))
    if op == ">>": return int_to_string(ci_shr(li, ri))
    if op == "|": return int_to_string(ci_bitor(li, ri))
    if op == "&": return int_to_string(ci_bitand(li, ri))
    if op == "^": return int_to_string(ci_bitxor(li, ri))
    ""

fn ci_parse_i64(s: str) -> i64:
    if s.len() == 0: return 0
    var is_neg = false
    var si = 0
    if s.byte_at(0) == 45:
        is_neg = true
        si = 1
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

    // Handle struct/union types — use name if translated, else opaque
    if ci_starts_with(base, "struct "):
        let sname = ci_escape_reserved(ci_trim(base.slice(7, base.len())))
        if ci_str_contains(known_structs, "|" ++ sname ++ "|"):
            if ptr_depth == 0:
                return sname
            var sr = sname
            var spi = 0
            while spi < ptr_depth:
                sr = "*" ++ sr
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
                ur = "*" ++ ur
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
                    tr = "*" ++ tr
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

fn ci_strip_parens(s: str) -> str:
    var result = s
    while result.len() >= 2 and result.byte_at(0) == 40 and result.byte_at(result.len() - 1) == 41:
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
    // Must start with digit or decimal point
    let first = s.byte_at(start as i64)
    if not ((first >= 48 and first <= 57) or first == 46):
        return false
    // Scan for decimal point or exponent — if found, it's a float
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

fn ci_float_type_from_suffix(s: str) -> str:
    if s.len() == 0:
        return "f64"
    let last = s.byte_at(s.len() - 1)
    if last == 102 or last == 70:  // f, F
        return "f32"
    // l, L → treat as f64 (With doesn't have long double)
    "f64"

fn ci_strip_float_suffix(s: str) -> str:
    var end = s.len() as i32
    while end > 0:
        let c = s.byte_at((end - 1) as i64)
        if c == 102 or c == 70 or c == 108 or c == 76:  // f, F, l, L
            end = end - 1
        else:
            break
    s.slice(0, end as i64)

fn ci_is_string_literal(s: str) -> bool:
    if s.len() < 2:
        return false
    s.byte_at(0) == 34 and s.byte_at(s.len() - 1) == 34
