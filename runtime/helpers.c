// With Language Runtime Helpers
// Residual C functions that cannot be implemented in With:
//   - c_import stubs (wrap libclang, need C headers)
//   - fiber yield/in_fiber stubs (weak symbols overridden by fiber.o)
//
// All other runtime functions have migrated to rt/rt_core.w.

#include <stdlib.h>
#include <stdint.h>

typedef struct {
    const char *ptr;
    int64_t len;
} with_str;

// ---- Fiber stubs (weak, overridden by fiber.o when async is linked) ----

__attribute__((weak)) void with_fiber_yield(void) {
}

__attribute__((weak)) int32_t with_fiber_in_fiber(void) {
    return 0;
}

// ---- c_import stubs (weak, overridden by clang_bridge.o when libclang is available) ----

__attribute__((weak)) int32_t  with_cimport_available(void) { return 0; }
__attribute__((weak)) int64_t  with_cimport_parse(with_str h) { (void)h; return 0; }
__attribute__((weak)) void     with_cimport_dispose(int64_t s) { (void)s; }
__attribute__((weak)) with_str with_cimport_error(int64_t s) { (void)s; with_str e={"",0}; return e; }
__attribute__((weak)) int32_t  with_cimport_decl_count(int64_t s) { (void)s; return 0; }
__attribute__((weak)) int32_t  with_cimport_decl_kind(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) with_str with_cimport_decl_name(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"",0}; return e; }
__attribute__((weak)) with_str with_cimport_fn_return_type(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"",0}; return e; }
__attribute__((weak)) int32_t  with_cimport_fn_param_count(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) with_str with_cimport_fn_param_name(int64_t s, int32_t i, int32_t p) { (void)s;(void)i;(void)p; with_str e={"",0}; return e; }
__attribute__((weak)) with_str with_cimport_fn_param_type(int64_t s, int32_t i, int32_t p) { (void)s;(void)i;(void)p; with_str e={"",0}; return e; }
__attribute__((weak)) int32_t  with_cimport_param_is_restrict(int64_t s, int32_t i, int32_t p) { (void)s;(void)i;(void)p; return 0; }
__attribute__((weak)) int32_t  with_cimport_fn_is_variadic(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) int32_t  with_cimport_struct_field_count(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) with_str with_cimport_struct_field_name(int64_t s, int32_t i, int32_t f) { (void)s;(void)i;(void)f; with_str e={"",0}; return e; }
__attribute__((weak)) with_str with_cimport_struct_field_type(int64_t s, int32_t i, int32_t f) { (void)s;(void)i;(void)f; with_str e={"",0}; return e; }
__attribute__((weak)) int32_t  with_cimport_struct_is_opaque(int64_t s, int32_t i) { (void)s;(void)i; return 1; }
__attribute__((weak)) int32_t  with_cimport_enum_const_count(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) with_str with_cimport_enum_const_name(int64_t s, int32_t i, int32_t c) { (void)s;(void)i;(void)c; with_str e={"",0}; return e; }
__attribute__((weak)) int64_t  with_cimport_enum_const_value(int64_t s, int32_t i, int32_t c) { (void)s;(void)i;(void)c; return 0; }
__attribute__((weak)) with_str with_cimport_typedef_underlying(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"",0}; return e; }
__attribute__((weak)) with_str with_cimport_var_type(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"",0}; return e; }
__attribute__((weak)) int32_t  with_cimport_var_is_const(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) int64_t  with_cimport_parse_macros(with_str h) { (void)h; return 0; }
__attribute__((weak)) int32_t  with_cimport_macro_count(int64_t s) { (void)s; return 0; }
__attribute__((weak)) with_str with_cimport_macro_name(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"",0}; return e; }
__attribute__((weak)) with_str with_cimport_macro_value(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"",0}; return e; }
__attribute__((weak)) int32_t  with_cimport_macro_is_fn_like(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) void     with_cimport_dispose_macros(int64_t s) { (void)s; }
__attribute__((weak)) int32_t  with_cimport_is_name_emitted(with_str n) { (void)n; return 0; }
__attribute__((weak)) void     with_cimport_mark_name_emitted(with_str n) { (void)n; }
__attribute__((weak)) void     with_cimport_reset_names(void) { }
__attribute__((weak)) int32_t  with_cimport_struct_field_is_bitfield(int64_t s, int32_t i, int32_t f) { (void)s;(void)i;(void)f; return 0; }
__attribute__((weak)) with_str with_cimport_enum_int_type(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"int",3}; return e; }
__attribute__((weak)) with_str with_cimport_fn_param_type_translated(int64_t s, int32_t i, int32_t p) { (void)s;(void)i;(void)p; with_str e={"i32",3}; return e; }
__attribute__((weak)) with_str with_cimport_fn_return_type_translated(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"void",4}; return e; }
__attribute__((weak)) with_str with_cimport_struct_field_type_translated(int64_t s, int32_t i, int32_t f) { (void)s;(void)i;(void)f; with_str e={"i32",3}; return e; }
__attribute__((weak)) with_str with_cimport_var_type_translated(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"i32",3}; return e; }
__attribute__((weak)) with_str with_cimport_typedef_underlying_translated(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"i32",3}; return e; }
__attribute__((weak)) int32_t  with_cimport_struct_field_is_anonymous_record(int64_t s, int32_t i, int32_t f) { (void)s;(void)i;(void)f; return 0; }
__attribute__((weak)) int32_t  with_cimport_struct_field_anon_field_count(int64_t s, int32_t i, int32_t f) { (void)s;(void)i;(void)f; return 0; }
__attribute__((weak)) with_str with_cimport_struct_field_anon_field_name(int64_t s, int32_t i, int32_t f, int32_t sf) { (void)s;(void)i;(void)f;(void)sf; with_str e={"",0}; return e; }
__attribute__((weak)) with_str with_cimport_struct_field_anon_field_type(int64_t s, int32_t i, int32_t f, int32_t sf) { (void)s;(void)i;(void)f;(void)sf; with_str e={"i32",3}; return e; }
__attribute__((weak)) int32_t  with_cimport_struct_is_packed(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) int32_t  with_cimport_fn_storage_class(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) int32_t  with_cimport_fn_is_inline(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) int32_t  with_cimport_macro_param_count(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) with_str with_cimport_macro_param_name(int64_t s, int32_t i, int32_t p) { (void)s;(void)i;(void)p; with_str e={"",0}; return e; }
__attribute__((weak)) int64_t  with_cimport_struct_field_offset(int64_t s, int32_t i, int32_t f) { (void)s;(void)i;(void)f; return -1; }
__attribute__((weak)) int64_t  with_cimport_struct_size(int64_t s, int32_t i) { (void)s;(void)i; return 0; }
__attribute__((weak)) with_str with_cimport_fn_calling_conv(int64_t s, int32_t i) { (void)s;(void)i; with_str e={"c",1}; return e; }
__attribute__((weak)) void with_cimport_add_include_path(with_str path) { (void)path; }
__attribute__((weak)) void with_cimport_clear_include_paths(void) { }
