// rt/cimport_stubs.w — weak fallback stubs for c_import (libclang) API.
//
// These are overridden by clang_bridge.o when libclang is available.
// Without libclang, c_import falls back to hardcoded header tables.

// Helpers for returning empty/default strings
fn empty_str() -> str: ""
fn str_int() -> str: "int"
fn str_i32() -> str: "i32"
fn str_void() -> str: "void"
fn str_c() -> str: "c"

@[weak] @[c_export("with_cimport_available")]
pub fn cimport_available() -> i32: 0

@[weak] @[c_export("with_cimport_parse")]
pub fn cimport_parse(h: str) -> i64:
    let _ = h
    0

@[weak] @[c_export("with_cimport_dispose")]
pub fn cimport_dispose(s: i64):
    let _ = s

@[weak] @[c_export("with_cimport_error")]
pub fn cimport_error(s: i64) -> str:
    let _ = s
    empty_str()

@[weak] @[c_export("with_cimport_decl_count")]
pub fn cimport_decl_count(s: i64) -> i32:
    let _ = s
    0

@[weak] @[c_export("with_cimport_decl_kind")]
pub fn cimport_decl_kind(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_decl_name")]
pub fn cimport_decl_name(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    empty_str()

@[weak] @[c_export("with_cimport_decl_cursor")]
pub fn cimport_decl_cursor(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    -1

@[weak] @[c_export("with_cimport_fn_return_type")]
pub fn cimport_fn_return_type(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    empty_str()

@[weak] @[c_export("with_cimport_fn_param_count")]
pub fn cimport_fn_param_count(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_fn_param_name")]
pub fn cimport_fn_param_name(s: i64, i: i32, p: i32) -> str:
    let _ = s
    let _ = i
    let _ = p
    empty_str()

@[weak] @[c_export("with_cimport_fn_param_type")]
pub fn cimport_fn_param_type(s: i64, i: i32, p: i32) -> str:
    let _ = s
    let _ = i
    let _ = p
    empty_str()

@[weak] @[c_export("with_cimport_param_is_restrict")]
pub fn cimport_param_is_restrict(s: i64, i: i32, p: i32) -> i32:
    let _ = s
    let _ = i
    let _ = p
    0

@[weak] @[c_export("with_cimport_fn_is_variadic")]
pub fn cimport_fn_is_variadic(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_fn_is_noreturn")]
pub fn cimport_fn_is_noreturn(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_struct_has_definition")]
pub fn cimport_struct_has_definition(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_var_alignment")]
pub fn cimport_var_alignment(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_hex_float_to_decimal")]
pub fn cimport_hex_float_to_decimal(hex_str: str) -> str:
    let _ = hex_str
    empty_str()

@[weak] @[c_export("with_cimport_struct_field_count")]
pub fn cimport_struct_field_count(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_struct_field_name")]
pub fn cimport_struct_field_name(s: i64, i: i32, f: i32) -> str:
    let _ = s
    let _ = i
    let _ = f
    empty_str()

@[weak] @[c_export("with_cimport_struct_field_type")]
pub fn cimport_struct_field_type(s: i64, i: i32, f: i32) -> str:
    let _ = s
    let _ = i
    let _ = f
    empty_str()

@[weak] @[c_export("with_cimport_struct_is_opaque")]
pub fn cimport_struct_is_opaque(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    1

@[weak] @[c_export("with_cimport_enum_const_count")]
pub fn cimport_enum_const_count(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_enum_const_name")]
pub fn cimport_enum_const_name(s: i64, i: i32, c: i32) -> str:
    let _ = s
    let _ = i
    let _ = c
    empty_str()

@[weak] @[c_export("with_cimport_enum_const_value")]
pub fn cimport_enum_const_value(s: i64, i: i32, c: i32) -> i64:
    let _ = s
    let _ = i
    let _ = c
    0

@[weak] @[c_export("with_cimport_typedef_underlying")]
pub fn cimport_typedef_underlying(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    empty_str()

@[weak] @[c_export("with_cimport_var_type")]
pub fn cimport_var_type(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    empty_str()

@[weak] @[c_export("with_cimport_var_is_const")]
pub fn cimport_var_is_const(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_var_storage_class")]
pub fn cimport_var_storage_class(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_var_definition_kind")]
pub fn cimport_var_definition_kind(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_var_is_threadlocal")]
pub fn cimport_var_is_threadlocal(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_realpath")]
pub fn cimport_realpath(path: str) -> str:
    path

@[weak] @[c_export("with_ci_root_cursor")]
pub fn ci_root_cursor(s: i64) -> i32:
    let _ = s
    -1

@[weak] @[c_export("with_ci_num_children")]
pub fn ci_num_children(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    0

@[weak] @[c_export("with_ci_child")]
pub fn ci_child(s: i64, c: i32, i: i32) -> i32:
    let _ = s
    let _ = c
    let _ = i
    -1

@[weak] @[c_export("with_ci_cursor_kind")]
pub fn ci_cursor_kind(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    0

@[weak] @[c_export("with_ci_cursor_spelling")]
pub fn ci_cursor_spelling(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_cursor_type")]
pub fn ci_cursor_type(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    -1

@[weak] @[c_export("with_ci_type_kind")]
pub fn ci_type_kind(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    0

@[weak] @[c_export("with_ci_type_array_element")]
pub fn ci_type_array_element(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    -1

@[weak] @[c_export("with_ci_type_array_size")]
pub fn ci_type_array_size(s: i64, t: i32) -> i64:
    let _ = s
    let _ = t
    -1

@[weak] @[c_export("with_ci_type_declaration")]
pub fn ci_type_declaration(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    -1

@[weak] @[c_export("with_ci_type_translated")]
pub fn ci_type_translated(s: i64, t: i32) -> str:
    let _ = s
    let _ = t
    empty_str()

@[weak] @[c_export("with_ci_type_pointee")]
pub fn ci_type_pointee(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    -1

@[weak] @[c_export("with_ci_type_is_const")]
pub fn ci_type_is_const(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    0

@[weak] @[c_export("with_ci_type_canonical")]
pub fn ci_type_canonical(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    t

@[weak] @[c_export("with_ci_type_result")]
pub fn ci_type_result(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    -1

@[weak] @[c_export("with_ci_type_arg_count")]
pub fn ci_type_arg_count(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    0

@[weak] @[c_export("with_ci_type_arg")]
pub fn ci_type_arg(s: i64, t: i32, i: i32) -> i32:
    let _ = s
    let _ = t
    let _ = i
    -1

@[weak] @[c_export("with_ci_cursor_is_definition")]
pub fn ci_cursor_is_definition(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    0

@[weak] @[c_export("with_ci_cursor_in_file")]
pub fn ci_cursor_in_file(s: i64, c: i32, path: str) -> i32:
    let _ = s
    let _ = c
    let _ = path
    0

@[weak] @[c_export("with_ci_cursor_location")]
pub fn ci_cursor_location(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_cursor_referenced_location")]
pub fn ci_cursor_referenced_location(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_cursor_source_text")]
pub fn ci_cursor_source_text(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_cursor_expansion_text")]
pub fn ci_cursor_expansion_text(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_cursor_spelling_text")]
pub fn ci_cursor_spelling_text(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_cursor_token_text")]
pub fn ci_cursor_token_text(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_cursor_start_offset")]
pub fn ci_cursor_start_offset(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    -1

@[weak] @[c_export("with_ci_binary_op")]
pub fn ci_binary_op(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    0

@[weak] @[c_export("with_ci_unary_op")]
pub fn ci_unary_op(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    0

@[weak] @[c_export("with_ci_eval_int_value")]
pub fn ci_eval_int_value(s: i64, c: i32) -> i64:
    let _ = s
    let _ = c
    0

@[weak] @[c_export("with_ci_eval_int_valid")]
pub fn ci_eval_int_valid(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    0

@[weak] @[c_export("with_ci_eval_int_is_unsigned")]
pub fn ci_eval_int_is_unsigned(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    0

@[weak] @[c_export("with_ci_eval_as_str")]
pub fn ci_eval_as_str(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_member_field_name")]
pub fn ci_member_field_name(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_cursor_expansion_location")]
pub fn ci_cursor_expansion_location(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_cursor_spelling_location")]
pub fn ci_cursor_spelling_location(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_ci_implicit_cast_kind")]
pub fn ci_implicit_cast_kind(s: i64, c: i32) -> i32:
    let _ = s
    let _ = c
    0

@[weak] @[c_export("with_ci_type_is_unsigned")]
pub fn ci_type_is_unsigned(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    0

@[weak] @[c_export("with_ci_type_is_pointer")]
pub fn ci_type_is_pointer(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    0

@[weak] @[c_export("with_ci_type_is_float")]
pub fn ci_type_is_float(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    0

@[weak] @[c_export("with_ci_type_is_bool")]
pub fn ci_type_is_bool(s: i64, t: i32) -> i32:
    let _ = s
    let _ = t
    0

@[weak] @[c_export("with_ci_cursor_pointee_type")]
pub fn ci_cursor_pointee_type(s: i64, c: i32) -> str:
    let _ = s
    let _ = c
    empty_str()

@[weak] @[c_export("with_cimport_parse_macros")]
pub fn cimport_parse_macros(h: str) -> i64:
    let _ = h
    0

@[weak] @[c_export("with_cimport_parse_macro_probe")]
pub fn cimport_parse_macro_probe(h: str, name: str) -> i64:
    let _ = h
    let _ = name
    0

@[weak] @[c_export("with_cimport_collect_object_macro_types")]
pub fn cimport_collect_object_macro_types(h: str, names: str) -> str:
    let _ = h
    let _ = names
    empty_str()

@[weak] @[c_export("with_cimport_preprocess_text")]
pub fn cimport_preprocess_text(h: str) -> str:
    let _ = h
    empty_str()

@[weak] @[c_export("with_cimport_macro_count")]
pub fn cimport_macro_count(s: i64) -> i32:
    let _ = s
    0

@[weak] @[c_export("with_cimport_macro_name")]
pub fn cimport_macro_name(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    empty_str()

@[weak] @[c_export("with_cimport_macro_value")]
pub fn cimport_macro_value(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    empty_str()

@[weak] @[c_export("with_cimport_macro_location")]
pub fn cimport_macro_location(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    empty_str()

@[weak] @[c_export("with_cimport_macro_is_system")]
pub fn cimport_macro_is_system(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_macro_is_fn_like")]
pub fn cimport_macro_is_fn_like(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_dispose_macros")]
pub fn cimport_dispose_macros(s: i64):
    let _ = s

@[weak] @[c_export("with_cimport_is_name_emitted")]
pub fn cimport_is_name_emitted(n: str) -> i32:
    let _ = n
    0

@[weak] @[c_export("with_cimport_mark_name_emitted")]
pub fn cimport_mark_name_emitted(n: str):
    let _ = n

@[weak] @[c_export("with_cimport_reset_names")]
pub fn cimport_reset_names():
    let _ = 0

@[weak] @[c_export("with_cimport_struct_field_is_bitfield")]
pub fn cimport_struct_field_is_bitfield(s: i64, i: i32, f: i32) -> i32:
    let _ = s
    let _ = i
    let _ = f
    0

@[weak] @[c_export("with_cimport_enum_int_type")]
pub fn cimport_enum_int_type(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    str_int()

@[weak] @[c_export("with_cimport_fn_param_type_translated")]
pub fn cimport_fn_param_type_translated(s: i64, i: i32, p: i32) -> str:
    let _ = s
    let _ = i
    let _ = p
    str_i32()

@[weak] @[c_export("with_cimport_fn_return_type_translated")]
pub fn cimport_fn_return_type_translated(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    str_void()

@[weak] @[c_export("with_cimport_struct_field_type_translated")]
pub fn cimport_struct_field_type_translated(s: i64, i: i32, f: i32) -> str:
    let _ = s
    let _ = i
    let _ = f
    str_i32()

@[weak] @[c_export("with_cimport_var_type_translated")]
pub fn cimport_var_type_translated(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    str_i32()

@[weak] @[c_export("with_cimport_var_storage_type_translated")]
pub fn cimport_var_storage_type_translated(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    str_i32()

@[weak] @[c_export("with_cimport_typedef_underlying_translated")]
pub fn cimport_typedef_underlying_translated(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    str_i32()

@[weak] @[c_export("with_cimport_struct_field_is_anonymous_record")]
pub fn cimport_struct_field_is_anonymous_record(s: i64, i: i32, f: i32) -> i32:
    let _ = s
    let _ = i
    let _ = f
    0

@[weak] @[c_export("with_cimport_struct_field_anon_field_count")]
pub fn cimport_struct_field_anon_field_count(s: i64, i: i32, f: i32) -> i32:
    let _ = s
    let _ = i
    let _ = f
    0

@[weak] @[c_export("with_cimport_struct_field_anon_field_name")]
pub fn cimport_struct_field_anon_field_name(s: i64, i: i32, f: i32, sf: i32) -> str:
    let _ = s
    let _ = i
    let _ = f
    let _ = sf
    empty_str()

@[weak] @[c_export("with_cimport_struct_field_anon_field_type")]
pub fn cimport_struct_field_anon_field_type(s: i64, i: i32, f: i32, sf: i32) -> str:
    let _ = s
    let _ = i
    let _ = f
    let _ = sf
    str_i32()

@[weak] @[c_export("with_cimport_struct_is_packed")]
pub fn cimport_struct_is_packed(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_fn_storage_class")]
pub fn cimport_fn_storage_class(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_fn_is_inline")]
pub fn cimport_fn_is_inline(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_macro_param_count")]
pub fn cimport_macro_param_count(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_macro_param_name")]
pub fn cimport_macro_param_name(s: i64, i: i32, p: i32) -> str:
    let _ = s
    let _ = i
    let _ = p
    empty_str()

@[weak] @[c_export("with_cimport_struct_field_offset")]
pub fn cimport_struct_field_offset(s: i64, i: i32, f: i32) -> i64:
    let _ = s
    let _ = i
    let _ = f
    -1

@[weak] @[c_export("with_cimport_record_field_offset_by_name")]
pub fn cimport_record_field_offset_by_name(s: i64, type_name: str, field_name: str) -> i64:
    let _ = s
    let _ = type_name
    let _ = field_name
    -1

@[weak] @[c_export("with_cimport_struct_size")]
pub fn cimport_struct_size(s: i64, i: i32) -> i64:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_struct_field_size")]
pub fn cimport_struct_field_size(s: i64, i: i32, f: i32) -> i64:
    let _ = s
    let _ = i
    let _ = f
    0

@[weak] @[c_export("with_cimport_struct_field_align")]
pub fn cimport_struct_field_align(s: i64, i: i32, f: i32) -> i64:
    let _ = s
    let _ = i
    let _ = f
    0

@[weak] @[c_export("with_cimport_struct_align")]
pub fn cimport_struct_align(s: i64, i: i32) -> i64:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_fn_calling_conv")]
pub fn cimport_fn_calling_conv(s: i64, i: i32) -> str:
    let _ = s
    let _ = i
    str_c()

@[weak] @[c_export("with_cimport_add_include_path")]
pub fn cimport_add_include_path(path: str):
    let _ = path

@[weak] @[c_export("with_cimport_clear_include_paths")]
pub fn cimport_clear_include_paths():
    let _ = 0

@[weak] @[c_export("with_cimport_typedef_anon_record_field_count")]
pub fn cimport_typedef_anon_record_field_count(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0

@[weak] @[c_export("with_cimport_typedef_anon_field_name")]
pub fn cimport_typedef_anon_field_name(s: i64, i: i32, f: i32) -> str:
    let _ = s
    let _ = i
    let _ = f
    empty_str()

@[weak] @[c_export("with_cimport_typedef_anon_field_type")]
pub fn cimport_typedef_anon_field_type(s: i64, i: i32, f: i32) -> str:
    let _ = s
    let _ = i
    let _ = f
    str_i32()

@[weak] @[c_export("with_cimport_typedef_anon_field_is_bitfield")]
pub fn cimport_typedef_anon_field_is_bitfield(s: i64, i: i32, f: i32) -> i32:
    let _ = s
    let _ = i
    let _ = f
    0

@[weak] @[c_export("with_cimport_typedef_anon_is_union")]
pub fn cimport_typedef_anon_is_union(s: i64, i: i32) -> i32:
    let _ = s
    let _ = i
    0
