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
extern fn with_cimport_param_is_restrict(session: i64, idx: i32, param: i32) -> i32
extern fn with_cimport_fn_is_variadic(session: i64, idx: i32) -> i32
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
extern fn with_cimport_fn_storage_class(session: i64, idx: i32) -> i32
extern fn with_cimport_fn_is_inline(session: i64, idx: i32) -> i32
extern fn with_cimport_fn_calling_conv(session: i64, idx: i32) -> str
extern fn with_cimport_macro_param_count(session: i64, idx: i32) -> i32
extern fn with_cimport_macro_param_name(session: i64, idx: i32, param: i32) -> str
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

// CX_StorageClass constants
let CX_SC_STATIC: i32 = 3

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

    // Emit c_void opaque type for void pointer translation
    if with_cimport_is_name_emitted("c_void") == 0:
        output = "type c_void = opaque\n"
        with_cimport_mark_name_emitted("c_void")

    // Emit Complex32/Complex64 for _Complex float/double
    if with_cimport_is_name_emitted("Complex32") == 0:
        output = output ++ "type Complex32 = \{ real: f32, imag: f32 }\n"
        output = output ++ "type Complex64 = \{ real: f64, imag: f64 }\n"
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
    // Forward declaration (no definition)
    if with_cimport_struct_is_opaque(session, idx) != 0:
        return true
    let field_count = with_cimport_struct_field_count(session, idx)
    // Bitfield in any field
    var fi = 0
    while fi < field_count:
        if with_cimport_struct_field_is_bitfield(session, idx, fi) != 0:
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
    if storage == CX_SC_STATIC:
        if is_inline != 0:
            // Static inline — emit comptime_error stub
            let safe_name = ci_escape_reserved(name)
            with_cimport_mark_name_emitted(name)
            return "fn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"static inline function — wrap in C shim\")\n"
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
        if ci_should_keep_raw_pointer_param(pname, pi) == 0:
            ptype = ci_wrap_nullable_pointer_type(ptype)

        if ci_starts_with(ptype, "__UNSUPPORTED:"):
            has_unsupported = true
            unsupported_reason = ptype.slice(14, ptype.len())

        if pname.len() > 0:
            params = params ++ ci_escape_reserved(pname) ++ ": " ++ ptype
        else:
            params = params ++ "p" ++ int_to_string(pi) ++ ": " ++ ptype

    if is_variadic != 0:
        if param_count > 0:
            params = params ++ ", ..."
        else:
            params = params ++ "..."

    let ret = ci_wrap_nullable_pointer_type(ci_pointer_type_explicit_mut(with_cimport_fn_return_type_translated(session, idx)))
    if ci_starts_with(ret, "__UNSUPPORTED:"):
        has_unsupported = true
        unsupported_reason = ret.slice(14, ret.len())

    with_cimport_mark_name_emitted(name)

    if has_unsupported:
        return "fn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"untranslatable: " ++ unsupported_reason ++ "\")\n"

    let cc = with_cimport_fn_calling_conv(session, idx)
    let cc_prefix = if cc != "c" and cc.len() > 0: "@[callconv(\"" ++ cc ++ "\")]\n" else: ""
    cc_prefix ++ "extern fn " ++ safe_name ++ "(" ++ params ++ ") -> " ++ ret ++ "\n"

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

fn ci_wrap_nullable_pointer_type(ty: str) -> str:
    if ci_starts_with(ty, "__UNSUPPORTED:"):
        return ty
    if not ci_starts_with(ty, "*"):
        return ty
    "Option[" ++ ty ++ "]"

fn ci_should_keep_raw_pointer_param(name: str, param_idx: i32) -> i32:
    if param_idx != 0:
        return 0
    if name == "self" or name == "self_" or name == "this":
        return 1
    0

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

    // Check if pre-scan marked this type as demoted (bitfield, forward decl,
    // unsupported field, or cascaded from a field whose type was demoted)
    if ci_str_contains(demoted_types, "|" ++ name ++ "|"):
        with_cimport_mark_name_emitted(name)
        let safe_name = ci_escape_reserved(name)
        return "type " ++ safe_name ++ " = opaque\n"

    let field_count = with_cimport_struct_field_count(session, idx)
    if field_count == 0:
        // Empty struct definition → emit with padding byte for ABI compatibility
        with_cimport_mark_name_emitted(name)
        let safe_name = ci_escape_reserved(name)
        if is_union:
            return "// union\ntype " ++ safe_name ++ " = \{ __pad0: u8 = 0 }\n"
        return "type " ++ safe_name ++ " = \{ __pad0: u8 = 0 }\n"

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
            let synth_name = if fname.len() > 0: name ++ "_" ++ fname else: name ++ "_anon_" ++ int_to_string(anon_idx)
            let sub_count = with_cimport_struct_field_anon_field_count(session, idx, afi)
            if sub_count > 0:
                var sub_fields = ""
                var sfi = 0
                while sfi < sub_count:
                    if sfi > 0:
                        sub_fields = sub_fields ++ ", "
                    let sf_name = with_cimport_struct_field_anon_field_name(session, idx, afi, sfi)
                    let sf_type = with_cimport_struct_field_anon_field_type(session, idx, afi, sfi)
                    let actual_sf_name = if sf_name.len() == 0: "field_" ++ int_to_string(sfi) else: sf_name
                    sub_fields = sub_fields ++ ci_escape_reserved(actual_sf_name) ++ ": " ++ sf_type
                    sfi = sfi + 1
                if anon_kind == 2:
                    anon_decls = anon_decls ++ "// union\n"
                anon_decls = anon_decls ++ "type " ++ ci_escape_reserved(synth_name) ++ " = \{ " ++ sub_fields ++ " }\n"
                with_cimport_mark_name_emitted(synth_name)
            anon_idx = anon_idx + 1
        afi = afi + 1

    // Build field list with layout-aware padding.
    // Check if C layout requires non-natural alignment (packed, aligned attributes).
    // If so, emit as @[packed] with explicit padding byte arrays.
    let needs_layout = ci_struct_needs_explicit_layout(session, idx, field_count, is_union)
    var field_str = ""
    var anon_idx2 = 0
    var cur_offset: i64 = 0
    var pad_idx = 0
    var fi = 0
    while fi < field_count:
        // Insert padding if layout requires it
        if needs_layout and not is_union:
            let field_offset = with_cimport_struct_field_offset(session, idx, fi)
            if field_offset >= 0 and field_offset > cur_offset:
                let pad_size = field_offset - cur_offset
                if pad_size > 0:
                    if field_str.len() > 0:
                        field_str = field_str ++ ", "
                    field_str = field_str ++ "__pad" ++ int_to_string(pad_idx) ++ ": [" ++ i64_to_string(pad_size) ++ "]u8"
                    pad_idx = pad_idx + 1
                cur_offset = field_offset

        if field_str.len() > 0:
            field_str = field_str ++ ", "
        let anon_kind = with_cimport_struct_field_is_anonymous_record(session, idx, fi)
        if anon_kind != 0:
            let fname = with_cimport_struct_field_name(session, idx, fi)
            let synth_name = if fname.len() > 0: name ++ "_" ++ fname else: name ++ "_anon_" ++ int_to_string(anon_idx2)
            let actual_name = if fname.len() > 0: fname else: "anon_" ++ int_to_string(anon_idx2)
            field_str = field_str ++ ci_escape_reserved(actual_name) ++ ": " ++ ci_escape_reserved(synth_name)
            anon_idx2 = anon_idx2 + 1
        else:
            field_str = field_str ++ ci_build_one_field(session, idx, fi, known_structs)

        // Advance offset past this field by its size
        if needs_layout and not is_union:
            let field_offset = with_cimport_struct_field_offset(session, idx, fi)
            let ftype = with_cimport_struct_field_type_translated(session, idx, fi)
            cur_offset = field_offset + ci_estimate_type_size(ftype)
        fi = fi + 1

    // Tail padding to match struct size
    if needs_layout and not is_union:
        let struct_size = with_cimport_struct_size(session, idx)
        if struct_size > cur_offset:
            let tail_pad = struct_size - cur_offset
            if tail_pad > 0:
                field_str = field_str ++ ", __pad" ++ int_to_string(pad_idx) ++ ": [" ++ i64_to_string(tail_pad) ++ "]u8"

    let is_packed = needs_layout or with_cimport_struct_is_packed(session, idx) != 0
    let packed_prefix = if is_packed: "@[packed]\n" else: ""
    let part1 = "type " ++ safe_name
    let part2 = part1 ++ " = \{ "
    let part3 = part2 ++ field_str
    let decl = part3 ++ " }\n"
    if is_union:
        return anon_decls ++ "// union\n" ++ packed_prefix ++ decl
    anon_decls ++ packed_prefix ++ decl

fn ci_struct_needs_explicit_layout(session: i64, idx: i32, field_count: i32, is_union: bool) -> bool:
    if is_union:
        return false
    if with_cimport_struct_is_packed(session, idx) != 0:
        return true
    // Compare actual C layout offsets against LLVM's default (non-packed) layout.
    // If any field's actual offset differs from what LLVM would naturally place,
    // we need explicit padding (via @[packed] + padding byte arrays).
    var natural_offset: i64 = 0
    var fi = 0
    while fi < field_count:
        let actual_offset = with_cimport_struct_field_offset(session, idx, fi)
        if actual_offset < 0:
            return false  // can't determine layout
        let ftype = with_cimport_struct_field_type_translated(session, idx, fi)
        let field_size = ci_estimate_type_size(ftype)
        let field_align = if field_size > 0: field_size else: 1
        // Natural alignment: round up to field's natural alignment
        let align_mask = field_align - 1
        natural_offset = (natural_offset + align_mask) / field_align * field_align
        if actual_offset != natural_offset:
            return true
        natural_offset = natural_offset + field_size
        fi = fi + 1
    false

fn ci_estimate_type_size(ty: str) -> i64:
    if ty == "i8" or ty == "u8" or ty == "bool": return 1
    if ty == "i16" or ty == "u16": return 2
    if ty == "i32" or ty == "u32" or ty == "f32": return 4
    if ty == "i64" or ty == "u64" or ty == "f64" or ty == "isize" or ty == "usize": return 8
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
    let actual_name = if fname.len() == 0: "unnamed_" ++ int_to_string(fi) else: fname
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
    if ty == "f32" or ty == "f64": return "0.0"
    if ty == "bool": return "false"
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
                return "type " ++ ci_escape_reserved(fwd_name) ++ " = opaque\n"
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
        output = output ++ "let " ++ safe_cname ++ ": " ++ int_type ++ " = " ++ i64_to_string(cvalue) ++ "\n"
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
        return "fn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"untranslatable: " ++ reason ++ "\")\n"

    let is_const = with_cimport_var_is_const(session, idx)
    let safe_name = ci_escape_reserved(name)
    with_cimport_mark_name_emitted(name)
    if is_const != 0:
        "extern let " ++ safe_name ++ ": " ++ var_type ++ "\n"
    else:
        "extern var " ++ safe_name ++ ": " ++ var_type ++ "\n"

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

fn ci_translate_macros(session: i64) -> str:
    let count = with_cimport_macro_count(session)
    var output = ""
    var known_values = ""
    for i in 0..count:
        let name = with_cimport_macro_name(session, i)
        let value = with_cimport_macro_value(session, i)
        let fn_like = with_cimport_macro_is_fn_like(session, i)

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
                    // DISCARD pattern: (void)(X) or ((void)(X)) — discard value
                    if ci_is_discard_pattern(value, param_names):
                        translated = ci_translate_discard_pattern(value, param_names, known_values)
                    // Token paste (##) translation
                    if translated.len() == 0 and ci_str_contains(value, "##"):
                        translated = ci_try_translate_token_paste(value, param_names)
                    if translated.len() == 0:
                        translated = ci_translate_c_expr(value, param_names, known_values)
                    if translated.len() > 0:
                        output = output ++ "fn " ++ safe_name ++ type_params ++ "(" ++ param_decl ++ ") -> " ++ ret_type ++ ":\n    " ++ translated ++ "\n"
                    else:
                        output = output ++ "fn " ++ safe_name ++ "() -> Never:\n    comptime_error(\"untranslatable C macro: " ++ name ++ "\")\n"
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
        else if ci_is_char_literal(stripped):
            let char_val = ci_char_to_int(stripped)
            if char_val.len() > 0:
                let safe_name = ci_escape_reserved(name)
                with_cimport_mark_name_emitted(name)
                known_values = known_values ++ name ++ "=" ++ char_val ++ "|"
                output = output ++ "let " ++ safe_name ++ ": i32 = " ++ char_val ++ "\n"
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
                output = output ++ "let " ++ safe_name ++ ": i32 = " ++ eval_result ++ "\n"
    output

// ── C expression → With source translator ────────────────────
// Translates a C macro body to With source code.
// params: pipe-delimited parameter names "|a|b|"
// known: pipe-delimited known constant values "NAME=val|"
// Returns "" on failure (triggers comptime_error fallback).

fn ci_translate_c_expr(s: str, params: str, known: str) -> str:
    let trimmed = ci_strip_parens(ci_trim(s))
    if trimmed.len() == 0:
        return ""

    // Integer literal
    if ci_is_int_literal(trimmed):
        return ci_strip_int_suffix(trimmed)

    // Float literal
    if ci_is_float_literal(trimmed):
        return ci_strip_float_suffix(trimmed)

    // String literal
    if ci_is_string_literal(trimmed):
        return trimmed

    // Char literal
    if ci_is_char_literal(trimmed):
        let cv = ci_char_to_int(trimmed)
        if cv.len() > 0:
            return cv
        return ""

    // Unary negation: -expr
    if trimmed.byte_at(0) == 45:
        let inner = ci_translate_c_expr(trimmed.slice(1, trimmed.len()), params, known)
        if inner.len() > 0:
            return "(0 - " ++ inner ++ ")"
        return ""

    // Logical NOT: !expr
    if trimmed.byte_at(0) == 33:
        let inner = ci_translate_c_expr(trimmed.slice(1, trimmed.len()), params, known)
        if inner.len() > 0:
            return "(if " ++ inner ++ " != 0: 0 else: 1)"
        return ""

    // Bitwise NOT: ~expr
    if trimmed.byte_at(0) == 126:
        let inner = ci_translate_c_expr(trimmed.slice(1, trimmed.len()), params, known)
        if inner.len() > 0:
            return "(0 - " ++ inner ++ " - 1)"
        return ""

    // sizeof(T) — translatable for type names and parameter names
    if ci_starts_with(trimmed, "sizeof"):
        let rest = ci_trim(trimmed.slice(6, trimmed.len()))
        if rest.len() > 0 and rest.byte_at(0) == 40:
            let close = ci_find_matching_paren(rest, 0)
            if close > 0:
                let inner = ci_trim(rest.slice(1, close as i64))
                // Parameter names in generic macros: sizeof(param) → sizeof[T]()
                if ci_str_contains(params, "|" ++ inner ++ "|"):
                    return "sizeof[T]()"
                let mapped = ci_map_sizeof_type(inner)
                if mapped.len() > 0:
                    return "sizeof[" ++ mapped ++ "]()"
        return ""

    // Cast: (type)expr  OR  CAST_OR_CALL: (X)(Y)  OR  comma operator: (expr1, expr2) → expr2
    if trimmed.byte_at(0) == 40:
        let cast_end = ci_find_matching_paren(trimmed, 0)
        if cast_end > 0 and cast_end as i64 + 1 < trimmed.len():
            let inside = trimmed.slice(1, cast_end as i64)
            let after_str = trimmed.slice(cast_end as i64 + 1, trimmed.len())
            if ci_is_c_type_name(inside):
                let after = ci_translate_c_expr(after_str, params, known)
                if after.len() > 0:
                    let mapped = ci_map_base_type(ci_trim(inside))
                    return "(" ++ after ++ " as " ++ mapped ++ ")"
                return ""
            // CAST_OR_CALL: (X)(Y) where X is a param or known identifier
            if ci_is_c_ident(ci_trim(inside)):
                let callee = ci_translate_c_expr(ci_trim(inside), params, known)
                if callee.len() > 0:
                    let call_args = ci_translate_c_expr(ci_strip_parens(after_str), params, known)
                    if call_args.len() > 0:
                        return callee ++ "(" ++ call_args ++ ")"
        // Comma operator: (a, b) at top level — translate last expression
        if cast_end == trimmed.len() as i32 - 1:
            let inside = trimmed.slice(1, cast_end as i64)
            let comma_pos = ci_find_last_comma_at_depth0(inside)
            if comma_pos >= 0:
                let last_expr = ci_trim(inside.slice(comma_pos as i64 + 1, inside.len()))
                return ci_translate_c_expr(last_expr, params, known)

    // Ternary: cond ? then : else
    let ternary_pos = ci_find_ternary(trimmed)
    if ternary_pos >= 0:
        let cond = ci_translate_c_expr(trimmed.slice(0, ternary_pos as i64), params, known)
        if cond.len() > 0:
            let rest = trimmed.slice(ternary_pos as i64 + 1, trimmed.len())
            let colon_pos = ci_find_ternary_colon(rest)
            if colon_pos >= 0:
                let then_e = ci_translate_c_expr(rest.slice(0, colon_pos as i64), params, known)
                let else_e = ci_translate_c_expr(rest.slice(colon_pos as i64 + 1, rest.len()), params, known)
                if then_e.len() > 0 and else_e.len() > 0:
                    // C ternary condition is truthy (nonzero), wrap non-comparison
                    let cond_expr = if ci_str_contains(cond, " == ") or ci_str_contains(cond, " != ") or ci_str_contains(cond, " < ") or ci_str_contains(cond, " > ") or ci_str_contains(cond, " and ") or ci_str_contains(cond, " or "): cond else: cond ++ " != 0"
                    return "(if " ++ cond_expr ++ ": " ++ then_e ++ " else: " ++ else_e ++ ")"
        return ""

    // Function call: ident(args) — check for known builtins
    if ci_is_c_ident_prefix(trimmed):
        let call_paren = ci_find_call_paren(trimmed)
        if call_paren > 0:
            let fn_name = trimmed.slice(0, call_paren as i64)
            let args_str = trimmed.slice(call_paren as i64 + 1, trimmed.len() - 1)
            let builtin_result = ci_translate_builtin_call(fn_name, args_str, params, known)
            if builtin_result.len() > 0:
                return builtin_result
            // Non-builtin function call with known name — emit as-is if name is a param or known
            if ci_str_contains(params, "|" ++ fn_name ++ "|") or with_cimport_is_name_emitted(fn_name) != 0:
                let translated_args = ci_translate_call_args(args_str, params, known)
                if translated_args.len() > 0:
                    return fn_name ++ "(" ++ translated_args ++ ")"
            return ""

    // Binary operator
    let op_info = ci_find_binary_op_ext(trimmed)
    if op_info >= 0:
        let op_pos = op_info / 256
        let op_len = op_info % 256
        let lhs = ci_translate_c_expr(trimmed.slice(0, op_pos as i64), params, known)
        let rhs = ci_translate_c_expr(trimmed.slice((op_pos + op_len) as i64, trimmed.len()), params, known)
        if lhs.len() > 0 and rhs.len() > 0:
            let c_op = trimmed.slice(op_pos as i64, (op_pos + op_len) as i64)
            let w_op = ci_map_c_op(c_op)
            if w_op.len() > 0:
                if ci_is_comparison_op(w_op):
                    return "(if " ++ lhs ++ " " ++ w_op ++ " " ++ rhs ++ ": 1 else: 0)"
                return "(" ++ lhs ++ " " ++ w_op ++ " " ++ rhs ++ ")"
        return ""

    // Identifier: parameter reference or known constant
    if ci_is_c_ident(trimmed):
        // Reject compiler builtins (__builtin_*, __inline_*, etc.)
        if trimmed.len() >= 2 and trimmed.byte_at(0) == 95 and trimmed.byte_at(1) == 95:
            return ""
        if ci_str_contains(params, "|" ++ trimmed ++ "|"):
            return trimmed
        // Known constant from earlier macro definitions
        let kv = ci_lookup_known(trimmed, known)
        if kv.len() > 0:
            return trimmed
        // Accept only if already emitted as a With declaration
        if with_cimport_is_name_emitted(trimmed) != 0:
            return trimmed
        return ""

    ""

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
    if name == "__builtin_expect":
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
        // Type compatibility check — can't translate
        return ""

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
        // __builtin___memcpy_chk(dst, src, n, objsize) → memcpy(dst, src, n)
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return "memcpy(" ++ ci_first_n_args(translated_args, 3) ++ ")"
        return ""

    if name == "__builtin___memset_chk":
        // __builtin___memset_chk(dst, val, n, objsize) → memset(dst, val, n)
        let translated_args = ci_translate_call_args(args, params, known)
        if translated_args.len() > 0:
            return "memset(" ++ ci_first_n_args(translated_args, 3) ++ ")"
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
            let prec = ci_op_prec_ext(s, idx, slen)
            if prec >= 0 and prec <= best_prec:
                best_pos = idx
                best_prec = prec
                best_len = ci_op_length_ext(s, idx, slen)
        idx = idx + 1
    if best_pos > 0:
        return best_pos * 256 + best_len
    0 - 1

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
    // Pointer types
    if t.len() > 0 and t.byte_at(t.len() - 1) == 42:
        return "*const i8"
    // Struct/type name — pass through
    if ci_is_c_ident(t):
        return t
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
            return i64_to_string(nv)
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
    // Identifier: look up in known values
    if ci_is_c_ident(trimmed):
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
    // Common typedefs
    if ci_map_builtin_typedef(t).len() > 0: return true
    false

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
    if name == "__int128": return "i128"
    if name == "unsigned __int128": return "u128"
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
    int_to_string(s.byte_at(1))

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
