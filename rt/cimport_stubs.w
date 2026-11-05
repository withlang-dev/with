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

@[weak] pub fn with_cimport_available() -> i32: 0

// The stand-in the compiler link aliases LLVM's five
// LLVMInitializeWebAssembly* entry points to when the SDK was built without
// the WebAssembly backend (build/compiler.w comp_wasm_backend_alias_lines):
// registering the wasm target is then a no-op, and the driver refuses
// --target=wasm32 from the baked embedded_llvm_wasm_backend_linked() fact.
// Lives here because this object is always in the compiler link and rt/
// sources keep bare with_* link names.
pub fn with_llvm_wasm_backend_missing() {}

@[weak] pub fn with_cimport_parse(h: str) -> i64:
    0

@[weak] pub fn with_cimport_dispose(s: i64) {}

@[weak] pub fn with_cimport_error(s: i64) -> str:
    empty_str()

@[weak] pub fn with_cimport_decl_count(s: i64) -> i32:
    0

@[weak] pub fn with_cimport_decl_kind(s: i64, i: isize) -> i32:
    0

@[weak] pub fn with_cimport_decl_name(s: i64, i: isize) -> str:
    empty_str()

@[weak] pub fn with_cimport_decl_cursor(s: i64, i: isize) -> i32:
    -1

@[weak] pub fn with_cimport_fn_return_type(s: i64, i: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_fn_param_count(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_fn_param_name(s: i64, i: i32, p: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_fn_param_type(s: i64, i: i32, p: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_param_is_restrict(s: i64, i: i32, p: i32) -> i32:
    0

@[weak] pub fn with_cimport_fn_is_variadic(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_fn_is_noreturn(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_struct_has_definition(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_var_alignment(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_hex_float_to_decimal(hex_str: str) -> str:
    empty_str()

@[weak] pub fn with_cimport_struct_field_count(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_struct_field_name(s: i64, i: i32, f: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_struct_field_type(s: i64, i: i32, f: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_struct_is_opaque(s: i64, i: i32) -> i32:
    1

@[weak] pub fn with_cimport_enum_const_count(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_enum_const_name(s: i64, i: i32, c: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_enum_const_value(s: i64, i: i32, c: i32) -> i64:
    0

@[weak] pub fn with_cimport_typedef_underlying(s: i64, i: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_var_type(s: i64, i: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_var_is_const(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_var_storage_class(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_var_definition_kind(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_var_is_threadlocal(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_realpath(path: str) -> str:
    path

@[weak] pub fn with_ci_root_cursor(s: i64) -> i32:
    -1

@[weak] pub fn with_ci_num_children(s: i64, c: i32) -> i32:
    0

@[weak] pub fn with_ci_child(s: i64, c: i32, i: isize) -> i32:
    -1

@[weak] pub fn with_ci_cursor_kind(s: i64, c: i32) -> i32:
    0

@[weak] pub fn with_ci_cursor_spelling(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_type(s: i64, c: i32) -> i32:
    -1

@[weak] pub fn with_ci_type_kind(s: i64, t: i32) -> i32:
    0

@[weak] pub fn with_ci_type_array_element(s: i64, t: i32) -> i32:
    -1

@[weak] pub fn with_ci_type_array_size(s: i64, t: i32) -> i64:
    -1

@[weak] pub fn with_ci_type_declaration(s: i64, t: i32) -> i32:
    -1

@[weak] pub fn with_ci_type_translated(s: i64, t: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_type_pointee(s: i64, t: i32) -> i32:
    -1

@[weak] pub fn with_ci_type_is_const(s: i64, t: i32) -> i32:
    0

@[weak] pub fn with_ci_type_canonical(s: i64, t: i32) -> i32:
    t

@[weak] pub fn with_ci_type_result(s: i64, t: i32) -> i32:
    -1

@[weak] pub fn with_ci_type_arg_count(s: i64, t: i32) -> i32:
    0

@[weak] pub fn with_ci_type_arg(s: i64, t: i32, i: isize) -> i32:
    -1

@[weak] pub fn with_ci_cursor_is_definition(s: i64, c: i32) -> i32:
    0

@[weak] pub fn with_ci_cursor_in_file(s: i64, c: i32, path: str) -> i32:
    0

@[weak] pub fn with_ci_cursor_location(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_referenced_location(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_references_decl(s: i64, c: i32, d: i32) -> i32:
    0

@[weak] pub fn with_ci_cursors_equal(s: i64, a: i32, b: i32) -> i32:
    0

@[weak] pub fn with_ci_cursor_spelling_designator(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_semantic_parent(s: i64, c: i32) -> i32:
    -1

@[weak] pub fn with_ci_member_is_bitfield(s: i64, c: i32) -> i32:
    0

@[weak] pub fn with_ci_member_bit_width(s: i64, c: i32) -> i32:
    0

@[weak] pub fn with_ci_cursor_field_bit_offset(s: i64, c: i32) -> i64:
    -1

@[weak] pub fn with_ci_cursor_definition(s: i64, c: i32) -> i32:
    -1

@[weak] pub fn with_ci_cursor_source_text(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_expansion_text(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_spelling_text(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_token_text(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_start_offset(s: i64, c: i32) -> i32:
    -1

@[weak] pub fn with_ci_binary_op(s: i64, c: i32) -> i32:
    0

@[weak] pub fn with_ci_unary_op(s: i64, c: i32) -> i32:
    0

@[weak] pub fn with_ci_eval_int_value(s: i64, c: i32) -> i64:
    0

@[weak] pub fn with_ci_eval_int_valid(s: i64, c: i32) -> i32:
    0

@[weak] pub unsafe fn with_ci_eval_as_float(s: i64, c: i32, out: *mut f64) -> i32:
    0

@[weak] pub fn with_ci_eval_int_is_unsigned(s: i64, c: i32) -> i32:
    0

@[weak] pub fn with_ci_eval_as_str(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_member_field_name(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_expansion_location(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_cursor_spelling_location(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_ci_implicit_cast_kind(s: i64, c: i32) -> i32:
    0

@[weak] pub fn with_ci_type_is_unsigned(s: i64, t: i32) -> i32:
    0

@[weak] pub fn with_ci_type_is_pointer(s: i64, t: i32) -> i32:
    0

@[weak] pub fn with_ci_type_is_float(s: i64, t: i32) -> i32:
    0

@[weak] pub fn with_ci_type_is_bool(s: i64, t: i32) -> i32:
    0

@[weak] pub fn with_ci_cursor_pointee_type(s: i64, c: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_parse_macros(h: str) -> i64:
    0

@[weak] pub fn with_cimport_parse_macro_probe(h: str, name: str) -> i64:
    0

@[weak] pub fn with_cimport_collect_object_macro_types(h: str, names: str) -> str:
    empty_str()

@[weak] pub fn with_cimport_macro_count(s: i64) -> i32:
    0

@[weak] pub fn with_cimport_macro_name(s: i64, i: isize) -> str:
    empty_str()

@[weak] pub fn with_cimport_macro_value(s: i64, i: isize) -> str:
    empty_str()

@[weak] pub fn with_cimport_macro_location(s: i64, i: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_macro_is_system(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_macro_is_fn_like(s: i64, i: isize) -> i32:
    0

@[weak] pub fn with_cimport_dispose_macros(s: i64) {}

@[weak] pub fn with_cimport_is_name_emitted(n: str) -> i32:
    0

@[weak] pub fn with_cimport_mark_name_emitted(n: str) {}

@[weak] pub fn with_cimport_reset_names() {}

@[weak] pub fn with_cimport_struct_field_bit_width(s: i64, i: i32, f: i32) -> i32:
    0

@[weak] pub fn with_cimport_struct_field_is_bitfield(s: i64, i: i32, f: i32) -> i32:
    0

@[weak] pub fn with_cimport_enum_int_type(s: i64, i: i32) -> str:
    str_int()

@[weak] pub fn with_cimport_fn_param_type_translated(s: i64, i: isize, p: isize) -> str:
    str_i32()

@[weak] pub fn with_cimport_fn_return_type_translated(s: i64, i: i32) -> str:
    str_void()

@[weak] pub fn with_cimport_struct_field_type_translated(s: i64, i: isize, f: isize) -> str:
    str_i32()

@[weak] pub fn with_cimport_var_type_translated(s: i64, i: i32) -> str:
    str_i32()

@[weak] pub fn with_cimport_var_storage_type_translated(s: i64, i: i32) -> str:
    str_i32()

@[weak] pub fn with_cimport_typedef_underlying_translated(s: i64, i: i32) -> str:
    str_i32()

@[weak] pub fn with_cimport_struct_field_is_anonymous_record(s: i64, i: isize, f: isize) -> i32:
    0

@[weak] pub fn with_cimport_struct_field_anon_field_count(s: i64, i: i32, f: i32) -> i32:
    0

@[weak] pub fn with_cimport_struct_field_anon_field_name(s: i64, i: i32, f: i32, sf: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_struct_field_anon_field_type(s: i64, i: i32, f: i32, sf: i32) -> str:
    str_i32()

@[weak] pub fn with_cimport_struct_is_packed(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_fn_storage_class(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_fn_is_inline(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_macro_param_count(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_macro_param_name(s: i64, i: i32, p: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_struct_field_offset(s: i64, i: i32, f: i32) -> i64:
    -1

@[weak] pub fn with_cimport_record_field_offset_by_name(s: i64, type_name: str, field_name: str) -> i64:
    -1

@[weak] pub fn with_cimport_struct_size(s: i64, i: i32) -> i64:
    0

@[weak] pub fn with_cimport_struct_field_size(s: i64, i: i32, f: i32) -> i64:
    0

@[weak] pub fn with_cimport_struct_field_align(s: i64, i: i32, f: i32) -> i64:
    0

@[weak] pub fn with_cimport_struct_align(s: i64, i: i32) -> i64:
    0

@[weak] pub fn with_cimport_fn_calling_conv(s: i64, i: i32) -> str:
    str_c()

@[weak] pub fn with_cimport_add_include_path(path: str) {}

@[weak] pub fn with_cimport_add_clang_arg(arg: str):
    0

@[weak] pub fn with_cimport_clear_include_paths() {}

@[weak] pub fn with_cimport_typedef_anon_record_field_count(s: i64, i: i32) -> i32:
    0

@[weak] pub fn with_cimport_typedef_anon_field_name(s: i64, i: i32, f: i32) -> str:
    empty_str()

@[weak] pub fn with_cimport_typedef_anon_field_type(s: i64, i: i32, f: i32) -> str:
    str_i32()

@[weak] pub fn with_cimport_typedef_anon_field_is_bitfield(s: i64, i: i32, f: i32) -> i32:
    0

@[weak] pub fn with_cimport_typedef_anon_is_union(s: i64, i: i32) -> i32:
    0
