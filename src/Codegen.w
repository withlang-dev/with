// Codegen — LLVM IR code generation from the With AST.
//
// Translates parsed AST nodes into LLVM IR using the LLVM-C API
// via the wl_* bridge functions (runtime/llvm_bridge.c), then emits
// object files via the LLVM target machine.
//
// Direct port of bootstrap/src/Codegen.zig to With.

use Ast
use InternPool
use Span
use Mir
use MirLower
use Sema
use Diagnostic
use Source

extern fn exit(code: i32) -> void
extern fn with_fs_read_file(path: str) -> str
extern fn with_parse_float(s: str) -> f64
extern fn with_eprintln(s: str) -> void
extern fn with_getenv_str(name: str) -> str
extern fn int_to_string(n: i32) -> str
extern fn str_from_byte(b: i32) -> str
extern fn with_codegen_loop_set_break(idx: i32, bb: i64) -> void
extern fn with_codegen_loop_set_continue(idx: i32, bb: i64) -> void
extern fn with_codegen_loop_set_result(idx: i32, value: i64) -> void
extern fn with_codegen_loop_get_break(idx: i32) -> i64
extern fn with_codegen_loop_get_continue(idx: i32) -> i64
extern fn with_codegen_loop_get_result(idx: i32) -> i64

// ── Bridge function declarations (runtime/llvm_bridge.c) ────────

// Lifecycle
extern fn wl_context_create() -> i64
extern fn wl_context_dispose(c: i64) -> void
extern fn wl_module_create(name: str, ctx: i64) -> i64
extern fn wl_module_dispose(m: i64) -> void
extern fn wl_builder_create(ctx: i64) -> i64
extern fn wl_builder_dispose(b: i64) -> void

// Target
extern fn wl_init_native_target() -> i32
extern fn wl_init_native_asm_printer() -> i32
extern fn wl_init_target_machine(m: i64, level: i32) -> i64
extern fn wl_dispose_target_machine(tm: i64) -> void

// Types
extern fn wl_i1_type(c: i64) -> i64
extern fn wl_i8_type(c: i64) -> i64
extern fn wl_i16_type(c: i64) -> i64
extern fn wl_i32_type(c: i64) -> i64
extern fn wl_i64_type(c: i64) -> i64
extern fn wl_i128_type(c: i64) -> i64
extern fn wl_f32_type(c: i64) -> i64
extern fn wl_f64_type(c: i64) -> i64
extern fn wl_void_type(c: i64) -> i64
extern fn wl_ptr_type(c: i64) -> i64
extern fn wl_array_type(elem: i64, size: i64) -> i64
extern fn wl_function_type(ret: i64, params_ptr: i64, count: i32, is_vararg: i32) -> i64
extern fn wl_struct_type(ctx: i64, elems_ptr: i64, count: i32, packed: i32) -> i64
extern fn wl_struct_create_named(ctx: i64, name: str) -> i64
extern fn wl_struct_set_body(ty: i64, elems_ptr: i64, count: i32, packed: i32) -> void
extern fn wl_struct_set_body_2(ty: i64, t0: i64, t1: i64, packed: i32) -> void
extern fn wl_struct_get_type_at(ty: i64, idx: i32) -> i64
extern fn wl_count_struct_elem_types(ty: i64) -> i32
extern fn wl_get_element_type(ty: i64) -> i64
extern fn wl_get_array_length(ty: i64) -> i64

// Type queries
extern fn wl_type_of(v: i64) -> i64
extern fn wl_get_type_kind(ty: i64) -> i32
extern fn wl_get_return_type(ft: i64) -> i64
extern fn wl_count_params(f: i64) -> i32
extern fn wl_count_param_types(ft: i64) -> i32
extern fn wl_get_fn_param_type(ft: i64, index: i32) -> i64
extern fn wl_global_get_value_type(v: i64) -> i64
extern fn wl_get_param(f: i64, i: i32) -> i64
extern fn wl_get_int_type_width(ty: i64) -> i32
extern fn wl_is_fn_var_arg(ft: i64) -> i32
extern fn wl_global_get_value_type(v: i64) -> i64
extern fn wl_get_allocated_type(v: i64) -> i64

// Type kind constants
extern fn wl_void_type_kind() -> i32
extern fn wl_float_type_kind() -> i32
extern fn wl_double_type_kind() -> i32
extern fn wl_integer_type_kind() -> i32
extern fn wl_function_type_kind() -> i32
extern fn wl_struct_type_kind() -> i32
extern fn wl_array_type_kind() -> i32
extern fn wl_pointer_type_kind() -> i32
extern fn wl_function_value_kind() -> i32

// Constants
extern fn wl_const_int(ty: i64, val: i64, sign_ext: i32) -> i64
extern fn wl_const_real(ty: i64, val: f64) -> i64
extern fn wl_const_null(ty: i64) -> i64
extern fn wl_get_undef(ty: i64) -> i64
extern fn wl_const_string(ctx: i64, s: str, dont_null: i32) -> i64
extern fn wl_const_struct(ctx: i64, vals_ptr: i64, count: i32, packed: i32) -> i64
extern fn wl_const_named_struct(ty: i64, vals_ptr: i64, count: i32) -> i64
extern fn wl_const_bitcast(val: i64, ty: i64) -> i64
extern fn wl_const_int_sext_val(v: i64) -> i64
extern fn wl_is_constant(v: i64) -> i32
extern fn wl_size_of(ty: i64) -> i64

// ICmp predicates
extern fn wl_int_eq() -> i32
extern fn wl_int_ne() -> i32
extern fn wl_int_slt() -> i32
extern fn wl_int_sgt() -> i32
extern fn wl_int_sle() -> i32
extern fn wl_int_sge() -> i32
extern fn wl_int_ult() -> i32
extern fn wl_int_ule() -> i32
extern fn wl_int_uge() -> i32
extern fn wl_int_ugt() -> i32

// FCmp predicates
extern fn wl_real_oeq() -> i32
extern fn wl_real_one() -> i32
extern fn wl_real_olt() -> i32
extern fn wl_real_ogt() -> i32
extern fn wl_real_ole() -> i32
extern fn wl_real_oge() -> i32

// Functions
extern fn wl_add_function(m: i64, name: str, fn_type: i64) -> i64
extern fn wl_get_named_function(m: i64, name: str) -> i64
extern fn wl_get_named_global(m: i64, name: str) -> i64
extern fn wl_get_first_function(m: i64) -> i64
extern fn wl_get_next_function(v: i64) -> i64
extern fn wl_is_declaration(v: i64) -> i32
extern fn wl_add_fn_attr(ctx: i64, f: i64, attr_name: str) -> void
extern fn wl_add_param_attr(ctx: i64, f: i64, param_idx: i32, attr_name: str) -> void

// Basic blocks
extern fn wl_append_bb(ctx: i64, f: i64, name: str) -> i64
extern fn wl_position_at_end(b: i64, bb: i64) -> void
extern fn wl_position_before(b: i64, instr: i64) -> void
extern fn wl_get_insert_block(b: i64) -> i64
extern fn wl_get_bb_terminator(bb: i64) -> i64
extern fn wl_get_entry_bb(f: i64) -> i64
extern fn wl_get_first_instr(bb: i64) -> i64
extern fn wl_bb_as_value(bb: i64) -> i64

// Builder: binary arithmetic
extern fn wl_build_add(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_sub(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_mul(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_nsw_add(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_nsw_sub(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_nsw_mul(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_sdiv(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_srem(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_udiv(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_urem(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_fadd(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_fsub(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_fmul(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_fdiv(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_frem(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_and(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_or(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_xor(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_shl(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_ashr(b: i64, l: i64, r: i64) -> i64
extern fn wl_build_lshr(b: i64, l: i64, r: i64) -> i64

// Builder: unary
extern fn wl_build_neg(b: i64, v: i64) -> i64
extern fn wl_build_not(b: i64, v: i64) -> i64
extern fn wl_build_fneg(b: i64, v: i64) -> i64

// Builder: comparison
extern fn wl_build_icmp(b: i64, pred: i32, l: i64, r: i64) -> i64
extern fn wl_build_fcmp(b: i64, pred: i32, l: i64, r: i64) -> i64

// Builder: memory
extern fn wl_build_alloca(b: i64, ty: i64) -> i64
extern fn wl_build_alloca_named(b: i64, ty: i64, name: str) -> i64
extern fn wl_build_load(b: i64, ty: i64, ptr: i64) -> i64
extern fn wl_build_store(b: i64, val: i64, ptr: i64) -> i64
extern fn wl_build_gep(b: i64, ty: i64, ptr: i64, idx_ptr: i64, cnt: i32) -> i64
extern fn wl_build_struct_gep(b: i64, ty: i64, ptr: i64, idx: i32) -> i64
extern fn wl_build_global_string_ptr(b: i64, s: str) -> i64

// Builder: globals
extern fn wl_add_global(m: i64, ty: i64, name: str) -> i64
extern fn wl_set_initializer(g: i64, v: i64) -> void
extern fn wl_set_global_constant(g: i64, c: i32) -> void
extern fn wl_set_linkage(g: i64, link: i32) -> void
extern fn wl_set_call_conv(f: i64, cc: i32) -> void
extern fn wl_cc_c() -> i32
extern fn wl_cc_fast() -> i32
extern fn wl_cc_x86_stdcall() -> i32
extern fn wl_cc_x86_fastcall() -> i32
extern fn wl_cc_x86_thiscall() -> i32
extern fn wl_cc_win64() -> i32
extern fn wl_cc_aarch64_vfabi() -> i32
extern fn wl_internal_linkage() -> i32
extern fn wl_private_linkage() -> i32

// Builder: control flow
extern fn wl_build_br(b: i64, bb: i64) -> i64
extern fn wl_build_cond_br(b: i64, cond: i64, then_bb: i64, else_bb: i64) -> i64
extern fn wl_build_ret(b: i64, val: i64) -> i64
extern fn wl_build_ret_void(b: i64) -> i64
extern fn wl_build_unreachable(b: i64) -> i64
extern fn wl_build_switch(b: i64, val: i64, else_bb: i64, n: i32) -> i64
extern fn wl_add_case(sw: i64, val: i64, bb: i64) -> void

// Builder: cast
extern fn wl_build_zext(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_sext(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_trunc(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_si_to_fp(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_ui_to_fp(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_fp_to_si(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_fp_to_ui(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_bitcast(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_int_to_ptr(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_ptr_to_int(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_fp_cast(b: i64, v: i64, ty: i64) -> i64
extern fn wl_build_fp_ext(b: i64, v: i64, ty: i64) -> i64

// Builder: phi / select / extract / insert
extern fn wl_build_phi(b: i64, ty: i64) -> i64
extern fn wl_add_incoming(phi: i64, vals_ptr: i64, bbs_ptr: i64, count: i32) -> void
extern fn wl_build_select(b: i64, cond: i64, then_v: i64, else_v: i64) -> i64
extern fn wl_build_extract_value(b: i64, agg: i64, idx: i32) -> i64
extern fn wl_build_insert_value(b: i64, agg: i64, val: i64, idx: i32) -> i64

// Builder: call
extern fn wl_build_call(b: i64, fn_ty: i64, f: i64, args_ptr: i64, cnt: i32) -> i64

// Misc
extern fn wl_instruction_erase(v: i64) -> void
extern fn wl_get_value_kind(v: i64) -> i32
extern fn wl_get_first_use(v: i64) -> i64
extern fn wl_set_value_name(v: i64, name: str) -> void

// Intrinsics
extern fn wl_lookup_intrinsic_id(name: str) -> i32
extern fn wl_get_intrinsic_decl(m: i64, id: i32, tys_ptr: i64, cnt: i32) -> i64
extern fn wl_intrinsic_get_type(ctx: i64, id: i32, tys_ptr: i64, cnt: i32) -> i64

// Data layout
extern fn wl_get_module_data_layout(m: i64) -> i64
extern fn wl_abi_size_of(dl: i64, ty: i64) -> i64
extern fn wl_abi_align_of(dl: i64, ty: i64) -> i32

// Struct name
extern fn wl_get_struct_name(ty: i64) -> str

// Param types
extern fn wl_get_param_types(fn_ty: i64, out_ptr: i64) -> void

// Verification / emission
extern fn wl_verify_module(m: i64) -> i32
extern fn wl_emit_object(tm: i64, m: i64, path: str) -> i32
extern fn wl_optimize(m: i64, tm: i64, level: i32) -> void
extern fn wl_promote_allocas(fn_val: i64, tm: i64) -> void
extern fn wl_print_ir(m: i64) -> void

// Vec data pointer
extern fn wl_vec_data_ptr(v: &Vec[i64]) -> i64

// Entry alloca helper
extern fn wl_create_entry_alloca(builder: i64, f: i64, ty: i64) -> i64

// Debug info (DWARF)
extern fn wl_di_create_builder(m: i64) -> i64
extern fn wl_di_dispose_builder(b: i64) -> void
extern fn wl_di_finalize(b: i64) -> void
extern fn wl_debug_metadata_version() -> i32
extern fn wl_add_module_flag_int(m: i64, key: str, val: i32) -> void
extern fn wl_di_create_file(b: i64, filename: str, directory: str) -> i64
extern fn wl_di_create_compile_unit(b: i64, file: i64, producer: str, is_optimized: i32, dwarf_version: i32, lang: i32) -> i64
extern fn wl_dwarf_lang_with() -> i32
extern fn wl_di_create_subroutine_type(b: i64, file: i64, param_types_ptr: i64, count: i32) -> i64
extern fn wl_di_create_function(b: i64, scope: i64, name: str, linkage_name: str, file: i64, line: i32, ty: i64, is_definition: i32, scope_line: i32, is_optimized: i32) -> i64
extern fn wl_di_set_subprogram(f: i64, subprogram: i64) -> void
extern fn wl_di_create_debug_location(ctx: i64, line: i32, col: i32, scope: i64) -> i64
extern fn wl_di_set_current_location(b: i64, location: i64) -> void
extern fn wl_di_clear_current_location(b: i64) -> void
extern fn wl_dwarf_ate_boolean() -> i32
extern fn wl_dwarf_ate_float() -> i32
extern fn wl_dwarf_ate_signed() -> i32
extern fn wl_dwarf_ate_unsigned() -> i32
extern fn wl_di_create_basic_type(b: i64, name: str, size_in_bits: i64, encoding: i32) -> i64
extern fn wl_di_create_pointer_type(b: i64, pointee_ty: i64, size_in_bits: i64) -> i64
extern fn wl_di_create_struct_type(b: i64, scope: i64, name: str, file: i64, line: i32, size_in_bits: i64, align_in_bits: i32, elements: i64, num_elements: i32) -> i64
extern fn wl_di_create_member_type(b: i64, scope: i64, name: str, file: i64, line: i32, size_in_bits: i64, align_in_bits: i32, offset_in_bits: i64, ty: i64) -> i64
extern fn wl_di_create_unspecified_type(b: i64, name: str) -> i64
extern fn wl_di_create_auto_variable(b: i64, scope: i64, name: str, file: i64, line: i32, ty: i64) -> i64
extern fn wl_di_create_parameter_variable(b: i64, scope: i64, name: str, file: i64, line: i32, ty: i64, arg_no: i32) -> i64
extern fn wl_di_create_expression(b: i64) -> i64
extern fn wl_di_insert_declare_at_end(b: i64, storage: i64, var_info: i64, expr: i64, loc: i64, block: i64) -> void
extern fn wl_di_create_lexical_block(b: i64, scope: i64, file: i64, line: i32, col: i32) -> i64

// Runtime helpers
extern fn with_str_concat(a: str, b: str) -> str
extern fn with_str_eq(a: str, b: str) -> i32
extern fn int_to_string(n: i32) -> str
extern fn i64_to_string(n: i64) -> str
extern fn print(s: str) -> void
extern fn eprintln(s: str) -> void

// ── Codegen state ─────────────────────────────────────────────────

type Codegen = {
    // LLVM handles
    context: i64,
    llmod: i64,
    builder: i64,
    target_machine: i64,

    // AST access
    pool: AstPool,
    intern: InternPool,
    sema: Sema,

    // Current function state
    current_ret_type: i64,
    current_function: i64,
    current_function_name_sym: i32,
    current_method_owner_sym: i32,

    // Local variables: sym → alloca/type/flags
    local_allocas: HashMap[i32, i64],
    local_types: HashMap[i32, i64],
    local_muts: HashMap[i32, i32],
    local_fn_sigs: HashMap[i32, i64],
    local_pointee_structs: HashMap[i32, i32],

    // Sema type annotations: sym → sema TypeId (for generic type dispatch)
    local_sema_types: HashMap[i32, i32],

    // Declared functions: sym → value/type
    fn_values: HashMap[i32, i64],
    fn_fn_types: HashMap[i32, i64],

    // Struct types: sym → index into struct_type_* arrays
    struct_type_map: HashMap[i32, i32],
    struct_llvm_types: Vec[i64],
    struct_index_syms: Vec[i32],
    struct_field_starts: Vec[i32],
    struct_field_counts: Vec[i32],
    struct_field_names: Vec[i32],
    struct_field_types: Vec[i64],
    struct_field_type_nodes: Vec[i32],
    struct_field_defaults: Vec[i32],
    struct_llvm_field_indices: Vec[i32],

    // Enum types: sym → index into enum_* arrays
    enum_type_map: HashMap[i32, i32],
    enum_llvm_types: Vec[i64],
    enum_variant_starts: Vec[i32],
    enum_variant_counts: Vec[i32],
    enum_variant_names: Vec[i32],
    enum_variant_payloads: Vec[i64],

    // Enum by LLVM type (for match lookups)
    enum_by_llvm: HashMap[i64, i32],

    // Discriminant enums: sym → index into disc_enum_* arrays
    disc_enum_type_map: HashMap[i32, i32],
    disc_enum_name_syms: Vec[i32],
    disc_enum_repr_types: Vec[i64],
    disc_enum_variant_starts: Vec[i32],
    disc_enum_variant_counts: Vec[i32],
    disc_enum_variant_names: Vec[i32],
    disc_enum_variant_values: Vec[i32],
    disc_enum_has_payload: Vec[i32],
    disc_enum_variant_payloads: Vec[i64],

    // Generic functions/structs: sym → node
    generic_fns: HashMap[i32, i32],
    generic_structs: HashMap[i32, i32],
    generic_struct_methods: HashMap[i32, i32],
    mono_struct_base: HashMap[i32, i32],
    mono_struct_tp_starts: HashMap[i32, i32],
    mono_struct_tp_counts: HashMap[i32, i32],
    mono_struct_tp_flat_syms: Vec[i32],
    mono_struct_tp_flat_types: Vec[i64],

    // Monomorphization cache: mangled_hash → value/type
    mono_values: HashMap[i64, i64],
    mono_types: HashMap[i64, i64],

    // Type aliases: sym → LLVM type
    type_aliases: HashMap[i32, i64],

    // Module constants: sym → LLVM global
    module_constants: HashMap[i32, i64],
    // Constant integer values: parallel arrays for sym → i64 value lookup
    const_int_syms: Vec[i32],
    const_int_vals: Vec[i64],
    decl_source_paths: Vec[str],
    current_decl_source_file: str,

    // Loop stack (fixed-size arrays via Vec)
    loop_break_bbs: Vec[i64],
    loop_continue_bbs: Vec[i64],
    loop_result_allocas: Vec[i64],
    loop_labels: Vec[i32],
    loop_depth: i32,

    // Tail recursion
    tailrec_body_bb: i64,
    tailrec_fn_sym: i32,
    tailrec_param_allocas: Vec[i64],

    // Closures
    closure_counter: i32,

    // Defer stack
    defer_stack: Vec[i32],
    errdefer_stack: Vec[i32],

    // Reference pointee types
    ref_pointee_types: HashMap[i32, i64],

    // Expected type context
    expected_type: i64,
    expected_type_node: i32,

    // Option type cache: payload_type → index
    option_cache_map: HashMap[i64, i32],
    option_llvm_types: Vec[i64],
    option_payload_types: Vec[i64],
    option_err_types: Vec[i64],
    option_enum_syms: Vec[i32],

    // Result type cache: hash → index
    result_cache_map: HashMap[i64, i32],
    result_llvm_types: Vec[i64],
    result_ok_types: Vec[i64],
    result_err_types: Vec[i64],
    result_enum_syms: Vec[i32],

    // Slice element types: sym → elem LLVM type
    slice_elem_types: HashMap[i32, i64],

    // Enum-typed locals: sym → enum sym
    enum_local_types: HashMap[i32, i32],

    // Drop functions: type_sym → fn value/type
    drop_fn_values: HashMap[i32, i64],
    drop_fn_types: HashMap[i32, i64],

    // Trait info: sym → index into trait_* arrays
    trait_map: HashMap[i32, i32],
    trait_idx_syms: Vec[i32],
    trait_vtable_types: Vec[i64],
    trait_method_starts: Vec[i32],
    trait_method_counts: Vec[i32],
    trait_method_names: Vec[i32],
    trait_method_ret_types: Vec[i64],
    trait_method_param_counts: Vec[i32],
    trait_method_param_starts: Vec[i32],
    trait_method_ret_nodes: Vec[i32],
    trait_method_default_bodies: Vec[i32],

    // Trait decl nodes: sym → trait_decl_node
    trait_decl_nodes: HashMap[i32, i32],

    // Trait type params: trait name_sym → flat start/count in trait_tp_flat_syms
    trait_tp_starts: HashMap[i32, i32],
    trait_tp_counts: HashMap[i32, i32],
    trait_tp_flat_syms: Vec[i32],

    // VTable globals: hash(type,trait) → global
    vtable_globals: HashMap[i32, i64],

    // Trait-typed locals
    trait_locals: HashMap[i32, i32],
    trait_local_concrete_types: HashMap[i32, i32],
    dyn_fat_ptr_type: i64,

    // Fn dyn params: fn_sym → start/count in flat array
    fn_dyn_param_starts: HashMap[i32, i32],
    fn_dyn_param_data: Vec[i32],

    // Fn ref params: fn_sym → start/count in flat array
    fn_ref_param_starts: HashMap[i32, i32],
    fn_ref_param_data: Vec[i32],

    // Result return tracking
    fn_result_err_symbols: HashMap[i32, i32],
    fn_returns_result: HashMap[i32, i32],
    fn_result_unit_returns: HashMap[i32, i32],
    current_result_err_symbol: i32,
    current_fn_returns_result: bool,
    current_fn_saw_explicit_return: bool,

    // Async
    async_fn_symbols: HashMap[i32, i32],
    async_fn_ret_types: HashMap[i32, i64],
    async_fn_args_struct_types: HashMap[i32, i64],
    task_locals: HashMap[i32, i32],
    uses_async: bool,
    async_block_counter: i32,
    async_block_captures: Vec[i32],

    // Scope locals for drop
    scope_local_syms: Vec[i32],
    scope_local_allocas: Vec[i64],
    scope_local_types: Vec[i64],
    scope_local_count: i32,

    // Error messages
    comptime_error_msg: str,
    codegen_error_detail: str,
    had_error: i32,

    // Monomorphization context (for duck-typing error messages)
    mono_inst_name: i32,
    mono_inst_node: i32,

    // Generator state
    gen_state_ptr: i64,
    gen_state_type: i64,
    gen_field_indices: HashMap[i32, i32],
    gen_done_bb: i64,
    gen_option_type: i64,
    gen_payload_type: i64,
    gen_yield_count: i32,
    gen_current_yield: i32,

    // Vec type cache
    // Vec type cache: forward (elem → vec) and reverse (vec → elem) maps
    vec_cache_map: HashMap[i64, i64],
    vec_type_to_elem: HashMap[i64, i64],
    // HashMap type cache
    hm_cache_map: HashMap[i64, i64],
    hm_type_to_key: HashMap[i64, i64],
    hm_type_to_val: HashMap[i64, i64],
    hm_type_to_is_str: HashMap[i64, i32],

    // HashSet type cache (elem LLVM type → HashSet LLVM struct type)
    hs_cache_map: HashMap[i64, i64],

    // Active type bindings (for monomorphization)
    type_binding_syms: Vec[i32],
    type_binding_types: Vec[i64],
    type_bindings_len: i32,

    // Fn param defaults: fn_sym → start/count in flat array
    fn_default_starts: HashMap[i32, i32],
    fn_default_counts: HashMap[i32, i32],

    // Source info
    source_file: str,
    source_text: str,

    // Debug info (DWARF)
    debug_info: i32,
    di_builder: i64,
    di_compile_unit: i64,
    di_file: i64,
    di_source: Source,
    di_fn_subprograms: HashMap[i32, i64],
    di_type_cache: HashMap[i32, i64],
    di_current_scope: i64,

    // Wave 10 MIR backend input (optional).
    mir_dispatch_count: i32,
    mir_input: MirModule,
    mir_local_ptrs: HashMap[i32, i64],
    mir_local_types: HashMap[i32, i64],
    mir_bb_values: Vec[i64],
    mir_default_unreachable_bbs: Vec[i64],
}

type DynArgInfo = {
    type_sym: i32,
    use_ptr: i32,
}

type LoopState = {
    break_bbs: Vec[i64],
    continue_bbs: Vec[i64],
    result_allocas: Vec[i64],
    labels: Vec[i32],
    depth: i32,
}

// ── Codegen lifecycle ─────────────────────────────────────────────

fn Codegen.init(module_name: str) -> Codegen:
    Codegen.init_with_opt(module_name, 0)

fn Codegen.init_with_opt_and_intern(module_name: str, opt_level: i32, intern: InternPool, sema: Sema) -> Codegen:
    var cg = Codegen.init_with_opt(module_name, opt_level)
    cg.intern = intern
    cg.sema = sema
    cg

fn Codegen.init_with_opt(module_name: str, opt_level: i32) -> Codegen:
    wl_init_native_target()
    wl_init_native_asm_printer()
    let ctx = wl_context_create()
    let mod = wl_module_create(module_name, ctx)
    let bld = wl_builder_create(ctx)
    let tm = wl_init_target_machine(mod, opt_level)
    Codegen {
        context: ctx,
        llmod: mod,
        builder: bld,
        target_machine: tm,
        pool: AstPool.new(),
        intern: InternPool.init(),
        sema: Sema.init(InternPool.init(), DiagnosticList.init(), AstPool.new()),
        current_ret_type: 0,
        current_function: 0,
        current_function_name_sym: 0,
        current_method_owner_sym: 0,
        local_allocas: HashMap.new(),
        local_types: HashMap.new(),
        local_muts: HashMap.new(),
        local_fn_sigs: HashMap.new(),
        local_pointee_structs: HashMap.new(),
        local_sema_types: HashMap.new(),
        fn_values: HashMap.new(),
        fn_fn_types: HashMap.new(),
        struct_type_map: HashMap.new(),
        struct_llvm_types: Vec.new(),
        struct_index_syms: Vec.new(),
        struct_field_starts: Vec.new(),
        struct_field_counts: Vec.new(),
        struct_field_names: Vec.new(),
        struct_field_types: Vec.new(),
        struct_field_type_nodes: Vec.new(),
        struct_field_defaults: Vec.new(),
        struct_llvm_field_indices: Vec.new(),
        enum_type_map: HashMap.new(),
        enum_llvm_types: Vec.new(),
        enum_variant_starts: Vec.new(),
        enum_variant_counts: Vec.new(),
        enum_variant_names: Vec.new(),
        enum_variant_payloads: Vec.new(),
        enum_by_llvm: HashMap.new(),
        disc_enum_type_map: HashMap.new(),
        disc_enum_name_syms: Vec.new(),
        disc_enum_repr_types: Vec.new(),
        disc_enum_variant_starts: Vec.new(),
        disc_enum_variant_counts: Vec.new(),
        disc_enum_variant_names: Vec.new(),
        disc_enum_variant_values: Vec.new(),
        disc_enum_has_payload: Vec.new(),
        disc_enum_variant_payloads: Vec.new(),
        generic_fns: HashMap.new(),
        generic_structs: HashMap.new(),
        generic_struct_methods: HashMap.new(),
        mono_struct_base: HashMap.new(),
        mono_struct_tp_starts: HashMap.new(),
        mono_struct_tp_counts: HashMap.new(),
        mono_struct_tp_flat_syms: Vec.new(),
        mono_struct_tp_flat_types: Vec.new(),
        mono_values: HashMap.new(),
        mono_types: HashMap.new(),
        type_aliases: HashMap.new(),
        module_constants: HashMap.new(),
        const_int_syms: Vec.new(),
        const_int_vals: Vec.new(),
        decl_source_paths: Vec.new(),
        current_decl_source_file: "<unknown>",
        loop_break_bbs: Vec.new(),
        loop_continue_bbs: Vec.new(),
        loop_result_allocas: Vec.new(),
        loop_labels: Vec.new(),
        loop_depth: 0,
        tailrec_body_bb: 0,
        tailrec_fn_sym: 0,
        tailrec_param_allocas: Vec.new(),
        closure_counter: 0,
        defer_stack: Vec.new(),
        errdefer_stack: Vec.new(),
        ref_pointee_types: HashMap.new(),
        expected_type: 0,
        expected_type_node: 0,
        option_cache_map: HashMap.new(),
        option_llvm_types: Vec.new(),
        option_payload_types: Vec.new(),
        option_err_types: Vec.new(),
        option_enum_syms: Vec.new(),
        result_cache_map: HashMap.new(),
        result_llvm_types: Vec.new(),
        result_ok_types: Vec.new(),
        result_err_types: Vec.new(),
        result_enum_syms: Vec.new(),
        slice_elem_types: HashMap.new(),
        enum_local_types: HashMap.new(),
        drop_fn_values: HashMap.new(),
        drop_fn_types: HashMap.new(),
        trait_map: HashMap.new(),
        trait_idx_syms: Vec.new(),
        trait_vtable_types: Vec.new(),
        trait_method_starts: Vec.new(),
        trait_method_counts: Vec.new(),
        trait_method_names: Vec.new(),
        trait_method_ret_types: Vec.new(),
        trait_method_param_counts: Vec.new(),
        trait_method_param_starts: Vec.new(),
        trait_method_ret_nodes: Vec.new(),
        trait_method_default_bodies: Vec.new(),
        trait_decl_nodes: HashMap.new(),
        trait_tp_starts: HashMap.new(),
        trait_tp_counts: HashMap.new(),
        trait_tp_flat_syms: Vec.new(),
        vtable_globals: HashMap.new(),
        trait_locals: HashMap.new(),
        trait_local_concrete_types: HashMap.new(),
        dyn_fat_ptr_type: 0,
        fn_dyn_param_starts: HashMap.new(),
        fn_dyn_param_data: Vec.new(),
        fn_ref_param_starts: HashMap.new(),
        fn_ref_param_data: Vec.new(),
        fn_result_err_symbols: HashMap.new(),
        fn_returns_result: HashMap.new(),
        fn_result_unit_returns: HashMap.new(),
        current_result_err_symbol: 0,
        current_fn_returns_result: false,
        current_fn_saw_explicit_return: false,
        async_fn_symbols: HashMap.new(),
        async_fn_ret_types: HashMap.new(),
        async_fn_args_struct_types: HashMap.new(),
        task_locals: HashMap.new(),
        uses_async: false,
        async_block_counter: 0,
        async_block_captures: Vec.new(),
        scope_local_syms: Vec.new(),
        scope_local_allocas: Vec.new(),
        scope_local_types: Vec.new(),
        scope_local_count: 0,
        comptime_error_msg: "",
        codegen_error_detail: "",
        had_error: 0,
        gen_state_ptr: 0,
        gen_state_type: 0,
        gen_field_indices: HashMap.new(),
        gen_done_bb: 0,
        gen_option_type: 0,
        gen_payload_type: 0,
        gen_yield_count: 0,
        gen_current_yield: 0,
        vec_cache_map: HashMap.new(),
        vec_type_to_elem: HashMap.new(),
        hm_cache_map: HashMap.new(),
        hm_type_to_key: HashMap.new(),
        hm_type_to_val: HashMap.new(),
        hm_type_to_is_str: HashMap.new(),
        hs_cache_map: HashMap.new(),
        type_binding_syms: Vec.new(),
        type_binding_types: Vec.new(),
        type_bindings_len: 0,
        fn_default_starts: HashMap.new(),
        fn_default_counts: HashMap.new(),
        source_file: "<unknown>",
        source_text: "",
        mir_dispatch_count: 0,
        mir_input: MirModule.init(),
        mir_local_ptrs: HashMap.new(),
        mir_local_types: HashMap.new(),
        mir_bb_values: Vec.new(),
        mir_default_unreachable_bbs: Vec.new(),
        debug_info: 1,
        di_builder: 0,
        di_compile_unit: 0,
        di_file: 0,
        di_source: Source.from_string("<unknown>", "", 0),
        di_fn_subprograms: HashMap.new(),
        di_type_cache: HashMap.new(),
        di_current_scope: 0,
    }

fn Codegen.deinit(self: Codegen):
    wl_builder_dispose(self.builder)
    wl_module_dispose(self.llmod)
    wl_context_dispose(self.context)
    wl_dispose_target_machine(self.target_machine)

// ── Public API (called by Driver) ─────────────────────────────────

fn Codegen.optimize(self: Codegen, level: i32):
    wl_optimize(self.llmod, self.target_machine, level)

fn Codegen.emit_object_file(self: Codegen, path: str) -> i32:
    wl_emit_object(self.target_machine, self.llmod, path)

fn Codegen.print_ir(self: Codegen):
    wl_print_ir(self.llmod)

fn Codegen.verify(self: Codegen) -> i32:
    wl_verify_module(self.llmod)

// ── Debug info helpers ────────────────────────────────────────────

fn Codegen.debug_init_module(self: Codegen):
    if self.debug_info == 0:
        return
    self.di_source = Source.from_string(self.source_file, self.source_text, 0)
    self.di_builder = wl_di_create_builder(self.llmod)

    // Split source path into directory and filename
    var last_slash = 0 - 1
    for i in 0..self.source_file.len() as i32:
        if self.source_file.byte_at(i as i64) == 47:
            last_slash = i

    var dir = "."
    var file = self.source_file
    if last_slash >= 0:
        dir = self.source_file.slice(0, last_slash as i64)
        file = self.source_file.slice((last_slash + 1) as i64, self.source_file.len())

    self.di_file = wl_di_create_file(self.di_builder, file, dir)

    wl_add_module_flag_int(self.llmod, "Debug Info Version", wl_debug_metadata_version())
    wl_add_module_flag_int(self.llmod, "Dwarf Version", 5)

    let is_opt = 0
    self.di_compile_unit = wl_di_create_compile_unit(
        self.di_builder, self.di_file, "with", is_opt, 5, wl_dwarf_lang_with())

fn Codegen.debug_finalize_module(self: Codegen):
    if self.di_builder != 0:
        wl_di_finalize(self.di_builder)

fn Codegen.debug_enter_function(self: Codegen, fn_node: i32, fn_sym: i32, function: i64):
    if self.di_builder == 0:
        return
    let fn_name = self.intern.resolve(fn_sym)
    if fn_name.len() == 0:
        return

    var fn_line = 1
    let span = self.pool.get_start(fn_node)
    if span > 0:
        let loc = self.di_source.offset_to_location(span)
        fn_line = loc.line + 1

    let sub_type = wl_di_create_subroutine_type(self.di_builder, self.di_file, 0, 0)
    let subprogram = wl_di_create_function(
        self.di_builder, self.di_file, fn_name, fn_name,
        self.di_file, fn_line, sub_type, 1, fn_line, 0)
    wl_di_set_subprogram(function, subprogram)
    self.di_fn_subprograms.insert(fn_sym, subprogram)
    self.di_current_scope = subprogram

fn Codegen.debug_set_location(self: Codegen, byte_offset: i32):
    if self.di_builder == 0:
        return
    if byte_offset <= 0:
        wl_di_clear_current_location(self.builder)
        return
    let loc = self.di_source.offset_to_location(byte_offset)
    let line = loc.line + 1
    let col = loc.col + 1
    var scope = self.di_current_scope
    if scope == 0:
        let sp = self.di_fn_subprograms.get(self.current_function_name_sym)
        if not sp.is_some():
            return
        scope = sp.unwrap() as i64
    let di_loc = wl_di_create_debug_location(self.context, line, col, scope)
    wl_di_set_current_location(self.builder, di_loc)

fn Codegen.debug_clear_location(self: Codegen):
    if self.di_builder == 0:
        return
    wl_di_clear_current_location(self.builder)

fn Codegen.debug_push_lexical_block(self: Codegen, byte_offset: i32):
    if self.di_builder == 0:
        return
    if self.di_current_scope == 0:
        return
    var line = 1
    var col = 0
    if byte_offset > 0:
        let loc = self.di_source.offset_to_location(byte_offset)
        line = loc.line + 1
        col = loc.col + 1
    let block = wl_di_create_lexical_block(self.di_builder, self.di_current_scope, self.di_file, line, col)
    self.di_current_scope = block

fn Codegen.debug_get_di_type(self: Codegen, sema_tid: i32) -> i64:
    let cached = self.di_type_cache.get(sema_tid)
    if cached.is_some():
        return cached.unwrap() as i64
    let di_ty = self.debug_create_di_type(sema_tid)
    self.di_type_cache.insert(sema_tid, di_ty)
    di_ty

fn Codegen.debug_create_di_type(self: Codegen, sema_tid: i32) -> i64:
    let kind = self.sema.get_type_kind(sema_tid)
    if kind == 3:
        // TY_BOOL
        return wl_di_create_basic_type(self.di_builder, "bool", 8, wl_dwarf_ate_boolean())
    if kind == 1:
        // TY_INT: d0 = width, d1 = signed, d2 = ptr_width flag
        let width = self.sema.get_type_d0(sema_tid)
        let is_signed = self.sema.get_type_d1(sema_tid)
        let is_ptr_width = self.sema.get_type_d2(sema_tid)
        if is_ptr_width != 0:
            let name = if is_signed == 1: "isize" else: "usize"
            let encoding = if is_signed == 1: wl_dwarf_ate_signed() else: wl_dwarf_ate_unsigned()
            return wl_di_create_basic_type(self.di_builder, name, width as i64, encoding)
        if is_signed == 1:
            return wl_di_create_basic_type(self.di_builder, "i" ++ int_to_string(width), width as i64, wl_dwarf_ate_signed())
        else:
            return wl_di_create_basic_type(self.di_builder, "u" ++ int_to_string(width), width as i64, wl_dwarf_ate_unsigned())
    if kind == 2:
        // TY_FLOAT: d0 = width
        let width = self.sema.get_type_d0(sema_tid)
        return wl_di_create_basic_type(self.di_builder, "f" ++ int_to_string(width), width as i64, wl_dwarf_ate_float())
    if kind == 5:
        // TY_STR
        return wl_di_create_unspecified_type(self.di_builder, "str")
    if kind == 4:
        // TY_VOID
        return wl_di_create_unspecified_type(self.di_builder, "void")
    if kind == 13 or kind == 14:
        // TY_PTR / TY_REF: d0 = pointee tid
        let pointee_tid = self.sema.get_type_d0(sema_tid)
        let pointee_di = self.debug_get_di_type(pointee_tid)
        return wl_di_create_pointer_type(self.di_builder, pointee_di, 64)
    if kind == 6 or kind == 7:
        // TY_STRUCT / TY_ENUM: d0 = name sym
        let name_sym = self.sema.get_type_d0(sema_tid)
        let name = self.intern.resolve(name_sym)
        return wl_di_create_unspecified_type(self.di_builder, name)
    wl_di_create_unspecified_type(self.di_builder, "unknown")

fn Codegen.abi_size_of(self: Codegen, ty: i64) -> i64:
    if ty == 0:
        self.had_error = 1
        return 0
    let dl = wl_get_module_data_layout(self.llmod)
    if dl == 0:
        self.had_error = 1
        return 0
    wl_abi_size_of(dl, ty)

fn Codegen.gen_module_from_mir(self: Codegen, mir_mod: MirModule, pool: AstPool) -> i32:
    let mir_err = validate_mir_module(mir_mod)
    if mir_err.len() > 0:
        with_eprintln("error: invalid MIR input for LLVM backend: " ++ mir_err)
        self.had_error = 1
        return 1
    self.mir_input = mir_mod
    self.gen_module(pool)

// ── Helper: is method symbol ──────────────────────────────────────

fn Codegen.is_method_symbol(self: Codegen, sym: i32) -> bool:
    let name = self.intern.resolve(sym)
    for i in 0..name.len() as i32:
        if name.byte_at(i as i64) == 46:  // '.'
            return true
    false

fn Codegen.dyn_trait_from_type_node(self: Codegen, type_node: i32) -> i32:
    if type_node == 0:
        return 0
    let tk = self.pool.kind(type_node)
    if tk == NK_TYPE_TRAIT_OBJ:
        return self.pool.get_data0(type_node)
    if tk == NK_TYPE_REF or tk == NK_TYPE_PTR:
        return self.dyn_trait_from_type_node(self.pool.get_data0(type_node))
    if tk == NK_TYPE_GENERIC:
        let name_sym = self.pool.get_data0(type_node)
        let name = self.intern.resolve(name_sym)
        let g_extra = self.pool.get_data1(type_node)
        let g_count = self.pool.get_data2(type_node)
        if name == "Box" and g_count == 1:
            return self.dyn_trait_from_type_node(self.pool.get_extra(g_extra))
    0

fn codegen_hash_type_trait_key(type_sym: i32, trait_sym: i32) -> i32:
    type_sym * 10007 + trait_sym

fn Codegen.get_dyn_fat_ptr_type(self: Codegen) -> i64:
    if self.dyn_fat_ptr_type != 0:
        return self.dyn_fat_ptr_type
    let ptr_ty = wl_ptr_type(self.context)
    let fat_types: Vec[i64] = Vec.new()
    fat_types.push(ptr_ty)
    fat_types.push(ptr_ty)
    self.dyn_fat_ptr_type = wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)
    self.dyn_fat_ptr_type

fn Codegen.get_fn_dyn_param_trait(self: Codegen, fn_sym: i32, param_idx: i32) -> i32:
    let base_opt = self.fn_dyn_param_starts.get(fn_sym)
    if not base_opt.is_some():
        return 0
    if param_idx < 0:
        return 0
    let base = base_opt.unwrap()
    let slot = base + param_idx
    if slot < 0 or slot >= self.fn_dyn_param_data.len() as i32:
        return 0
    self.fn_dyn_param_data.get(slot as i64)

fn Codegen.coerce_value_to_type(self: Codegen, val: i64, target_ty: i64) -> i64:
    if val == 0 or target_ty == 0:
        return val
    let val_ty = wl_type_of(val)
    if val_ty == target_ty:
        return val

    let vk = wl_get_type_kind(val_ty)
    let tk = wl_get_type_kind(target_ty)

    if tk == wl_pointer_type_kind() and self.is_str_type(val_ty):
        return self.extract_str_ptr(val)
    if vk == wl_integer_type_kind() and tk == wl_pointer_type_kind():
        if wl_is_constant(val) != 0 and wl_const_int_sext_val(val) == 0:
            return wl_const_null(target_ty)
    if tk == wl_pointer_type_kind() and vk == wl_pointer_type_kind():
        return wl_build_bitcast(self.builder, val, target_ty)
    if vk == wl_struct_type_kind() and tk == wl_struct_type_kind():
        let coerced_agg = self.coerce_struct_value(val, target_ty)
        if wl_type_of(coerced_agg) == target_ty:
            return coerced_agg

    if vk == wl_integer_type_kind() and tk == wl_integer_type_kind():
        return self.coerce_int(val, target_ty)

    // Function pointer → fat pointer coercion: create thunk wrapper
    // Regular fn(params...) → closure fn(ctx, params...) with ctx ignored
    if vk == wl_pointer_type_kind() and tk == wl_struct_type_kind():
        let target_fields = wl_count_struct_elem_types(target_ty)
        if target_fields == 2:
            let f0 = wl_struct_get_type_at(target_ty, 0)
            let f1 = wl_struct_get_type_at(target_ty, 1)
            if f0 != 0 and f1 != 0:
                if wl_get_type_kind(f0) == wl_pointer_type_kind() and wl_get_type_kind(f1) == wl_pointer_type_kind():
                    return self.gen_fn_to_fat_ptr_thunk(val, target_ty)

    val

fn Codegen.gen_fn_to_fat_ptr_thunk(self: Codegen, fn_val: i64, fat_ty: i64) -> i64:
    // Create a thunk: fn __fn_thunk_N(ctx: ptr, params...) -> ret that calls fn_val(params...)
    let ptr_ty = wl_ptr_type(self.context)
    // Get the original function's type to determine params and return type
    let orig_fn_ty = wl_global_get_value_type(fn_val)
    if orig_fn_ty == 0:
        // Can't determine function type — fall back to direct wrap (may mismatch)
        var fat = wl_get_undef(fat_ty)
        fat = wl_build_insert_value(self.builder, fat, fn_val, 0)
        fat = wl_build_insert_value(self.builder, fat, wl_const_null(ptr_ty), 1)
        return fat
    let orig_param_count = wl_count_param_types(orig_fn_ty)
    let orig_ret_ty = wl_get_return_type(orig_fn_ty)
    // Build thunk function type: fn(ptr, original_params...) -> original_ret
    let thunk_params: Vec[i64] = Vec.new()
    thunk_params.push(ptr_ty)
    for pi in 0..orig_param_count:
        thunk_params.push(wl_get_fn_param_type(orig_fn_ty, pi))
    let thunk_fn_ty = wl_function_type(orig_ret_ty, vec_data_i64(&thunk_params), orig_param_count + 1, 0)
    let thunk_id = self.closure_counter
    self.closure_counter = thunk_id + 1
    let thunk_name = "__fn_thunk_" ++ int_to_string(thunk_id)
    let thunk_fn = wl_add_function(self.llmod, thunk_name, thunk_fn_ty)
    // Generate thunk body
    let saved_bb = wl_get_insert_block(self.builder)
    let entry = wl_append_bb(self.context, thunk_fn, "entry")
    wl_position_at_end(self.builder, entry)
    // Call original function with params (skip ctx at index 0)
    let call_args: Vec[i64] = Vec.new()
    for pi in 0..orig_param_count:
        call_args.push(wl_get_param(thunk_fn, pi + 1))
    let result = wl_build_call(self.builder, orig_fn_ty, fn_val, vec_data_i64(&call_args), orig_param_count)
    if wl_get_type_kind(orig_ret_ty) == wl_void_type_kind():
        wl_build_ret_void(self.builder)
    else:
        wl_build_ret(self.builder, result)
    // Restore insertion point
    wl_position_at_end(self.builder, saved_bb)
    // Build fat pointer { thunk_fn, null_ctx }
    var fat = wl_get_undef(fat_ty)
    fat = wl_build_insert_value(self.builder, fat, thunk_fn, 0)
    fat = wl_build_insert_value(self.builder, fat, wl_const_null(ptr_ty), 1)
    fat

fn Codegen.coerce_struct_value(self: Codegen, val: i64, target_ty: i64) -> i64:
    if val == 0 or target_ty == 0:
        return val
    let val_ty = wl_type_of(val)
    if val_ty == target_ty:
        return val
    if wl_get_type_kind(val_ty) != wl_struct_type_kind() or wl_get_type_kind(target_ty) != wl_struct_type_kind():
        return val
    let val_fields = wl_count_struct_elem_types(val_ty)
    let target_fields = wl_count_struct_elem_types(target_ty)
    if val_fields <= 0 or target_fields <= 0 or val_fields != target_fields:
        return val
    // If both are named struct types with the same name, or all fields have
    // identical LLVM types, reinterpret through memory (different type identity, same layout).
    let val_name = wl_get_struct_name(val_ty)
    let target_name = wl_get_struct_name(target_ty)
    var same_layout = val_name.len() > 0 and val_name == target_name
    if not same_layout:
        same_layout = true
        for fi in 0..val_fields:
            if wl_struct_get_type_at(val_ty, fi) != wl_struct_get_type_at(target_ty, fi):
                same_layout = false
                break
    if same_layout:
        let alloca = self.create_entry_alloca(val_ty)
        wl_build_store(self.builder, val, alloca)
        return wl_build_load(self.builder, target_ty, alloca)
    // Both are named structs with different names — these are different types.
    // Don't coerce; return unchanged. The caller should fix the type mismatch.
    val

fn Codegen.debug_call_coerce_enabled(self: Codegen) -> bool:
    let raw = with_getenv_str("WITH_DEBUG_CALL_COERCE")
    raw.len() > 0 and raw != "0"

fn Codegen.debug_mir_codegen_enabled(self: Codegen) -> bool:
    let raw = with_getenv_str("WITH_DEBUG_MIR_CODEGEN")
    raw.len() > 0 and raw != "0"

fn Codegen.debug_local_flow_enabled(self: Codegen) -> bool:
    let raw = with_getenv_str("WITH_DEBUG_LOCAL_FLOW")
    raw.len() > 0 and raw != "0"

fn Codegen.debug_method_dispatch_enabled(self: Codegen) -> bool:
    let raw = with_getenv_str("WITH_DEBUG_METHOD_DISPATCH")
    raw.len() > 0 and raw != "0"

fn Codegen.debug_pool_flow_enabled(self: Codegen) -> bool:
    let _ = self
    let raw = with_getenv_str("WITH_DEBUG_POOL_FLOW")
    raw.len() > 0 and raw != "0"

fn Codegen.debug_type_layout_enabled(self: Codegen) -> bool:
    let _ = self
    let raw = with_getenv_str("WITH_DEBUG_TYPE_LAYOUT")
    raw.len() > 0 and raw != "0"

fn Codegen.debug_fallback_enabled(self: Codegen) -> bool:
    let _ = self
    let raw = with_getenv_str("WITH_DEBUG_FALLBACK")
    raw.len() > 0 and raw != "0"

fn Codegen.debug_type_layout_field(self: Codegen, owner_name: str, field_index: i32, field_name: i32, type_node: i32, resolved_ty: i64):
    if not self.debug_type_layout_enabled():
        return
    let node_kind = if type_node != 0: self.pool.kind(type_node) else: 0 - 1
    var msg = "[type-layout] owner=" ++ owner_name
    msg = msg ++ " field=" ++ int_to_string(field_index)
    msg = msg ++ " name=" ++ self.intern.resolve(field_name)
    msg = msg ++ " type_node=" ++ int_to_string(type_node)
    msg = msg ++ " node_kind=" ++ int_to_string(node_kind)
    if type_node != 0:
        let start = self.pool.get_start(type_node)
        let end = self.pool.get_end(type_node)
        msg = msg ++ " span=" ++ int_to_string(start) ++ ".." ++ int_to_string(end)
        if node_kind == NK_TYPE_NAMED or node_kind == NK_TYPE_GENERIC:
            let type_name_sym = self.pool.get_data0(type_node)
            msg = msg ++ " type_name=" ++ self.intern.resolve(type_name_sym)
        if node_kind == NK_TYPE_GENERIC:
            msg = msg ++ " arg_count=" ++ int_to_string(self.pool.get_data2(type_node))
    msg = msg ++ " resolved=" ++ self.llvm_type_mangle(resolved_ty)
    if resolved_ty != 0:
        msg = msg ++ " llvm_kind=" ++ int_to_string(wl_get_type_kind(resolved_ty))
        msg = msg ++ " size=" ++ i64_to_string(wl_size_of(resolved_ty))
        let struct_name = wl_get_struct_name(resolved_ty)
        if struct_name.len() > 0:
            msg = msg ++ " llvm_name=" ++ struct_name
    with_eprintln(msg)

fn Codegen.capture_loop_state(self: Codegen) -> LoopState:
    LoopState {
        break_bbs: self.loop_break_bbs,
        continue_bbs: self.loop_continue_bbs,
        result_allocas: self.loop_result_allocas,
        labels: self.loop_labels,
        depth: self.loop_depth,
    }

fn Codegen.reset_loop_state(self: Codegen):
    self.loop_break_bbs = Vec.new()
    self.loop_continue_bbs = Vec.new()
    self.loop_result_allocas = Vec.new()
    self.loop_labels = Vec.new()
    self.loop_depth = 0

fn Codegen.restore_loop_state(self: Codegen, state: LoopState):
    self.loop_break_bbs = state.break_bbs
    self.loop_continue_bbs = state.continue_bbs
    self.loop_result_allocas = state.result_allocas
    self.loop_labels = state.labels
    self.loop_depth = state.depth

fn Codegen.push_loop_context(self: Codegen, break_bb: i64, continue_bb: i64, result_alloca: i64, label_sym: i32):
    let idx = self.loop_depth
    let mut labels: Vec[i32] = self.loop_labels
    with_codegen_loop_set_break(idx, break_bb)
    with_codegen_loop_set_continue(idx, continue_bb)
    with_codegen_loop_set_result(idx, result_alloca)
    labels.push(label_sym)
    self.loop_labels = labels
    self.loop_depth = idx + 1

fn Codegen.pop_loop_context(self: Codegen):
    let mut labels: Vec[i32] = self.loop_labels
    let _ = labels.pop()
    self.loop_labels = labels
    self.loop_depth = self.loop_depth - 1

fn Codegen.loop_break_target(self: Codegen, idx: i32) -> i64:
    with_codegen_loop_get_break(idx)

fn Codegen.loop_continue_target(self: Codegen, idx: i32) -> i64:
    with_codegen_loop_get_continue(idx)

fn Codegen.loop_result_alloca_at(self: Codegen, idx: i32) -> i64:
    with_codegen_loop_get_result(idx)

fn Codegen.debug_call_coerce_failure(self: Codegen, context: str, call_node: i32, arg_index: i32, arg_node: i32, actual_val: i64, expected_ty: i64) -> void:
    if not self.debug_call_coerce_enabled():
        return
    var msg = "[call-coerce] " ++ context
    if self.current_function_name_sym != 0:
        msg = msg ++ " fn=" ++ self.function_symbol_name(self.current_function_name_sym)
    msg = msg ++ " arg=" ++ int_to_string(arg_index)
    var line = 0 - 1
    if arg_node != 0:
        line = self.span_to_line(arg_node)
    else if call_node != 0:
        line = self.span_to_line(call_node)
    if line >= 0:
        msg = msg ++ " line=" ++ int_to_string(line)
    var actual_ty: i64 = 0
    if actual_val != 0:
        actual_ty = wl_type_of(actual_val)
    msg = msg ++ " actual=" ++ self.llvm_type_mangle(actual_ty)
    msg = msg ++ " expected=" ++ self.llvm_type_mangle(expected_ty)
    if arg_node != 0:
        msg = msg ++ " node_kind=" ++ int_to_string(self.pool.kind(arg_node))
        let arg_text = self.ident_text_from_node(arg_node)
        if arg_text.len() > 0:
            msg = msg ++ " arg_text=" ++ arg_text
    with_eprintln(msg)

fn Codegen.enforce_coerced_type(self: Codegen, value: i64, expected_ty: i64, context: str) -> i64:
    if value == 0 or expected_ty == 0:
        return value

    var out = if wl_type_of(value) != expected_ty: self.coerce_value_to_type(value, expected_ty) else: value
    if out != 0 and wl_type_of(out) == expected_ty:
        return out

    if out != 0 and wl_get_type_kind(expected_ty) == wl_pointer_type_kind() and wl_get_type_kind(wl_type_of(out)) == wl_pointer_type_kind():
        out = wl_build_bitcast(self.builder, out, expected_ty)
        if wl_type_of(out) == expected_ty:
            return out

    self.had_error = 1
    with_eprintln("error: " ++ context)
    self.build_default_value(expected_ty)

fn Codegen.canonical_local_sym(self: Codegen, sym: i32) -> i32:
    if sym <= 0:
        return sym
    let text = self.intern.resolve(sym)
    if text.len() == 0:
        return sym
    self.intern.intern(text)

fn Codegen.record_local(self: Codegen, sym: i32, local_ptr: i64, ty: i64, is_mut: i32):
    self.local_allocas.insert(sym, local_ptr)
    self.local_types.insert(sym, ty)
    self.local_muts.insert(sym, is_mut)
    let canon = self.canonical_local_sym(sym)
    if canon != 0 and canon != sym:
        self.local_allocas.insert(canon, local_ptr)
        self.local_types.insert(canon, ty)
        self.local_muts.insert(canon, is_mut)
    if self.debug_local_flow_enabled():
        let sym_text = self.intern.resolve(sym)
        var msg = "[local-bind]"
        if self.current_function_name_sym != 0:
            msg = msg ++ " fn=" ++ self.function_symbol_name(self.current_function_name_sym)
        msg = msg ++ " sym=" ++ int_to_string(sym)
        if sym_text.len() > 0:
            msg = msg ++ " name=" ++ sym_text
        msg = msg ++ " ty=" ++ self.llvm_type_mangle(ty)
        with_eprintln(msg)

fn Codegen.record_local_fn_sig(self: Codegen, sym: i32, fn_sig: i64):
    self.local_fn_sigs.insert(sym, fn_sig)
    let canon = self.canonical_local_sym(sym)
    if canon != 0 and canon != sym:
        self.local_fn_sigs.insert(canon, fn_sig)

fn Codegen.record_local_pointee_struct(self: Codegen, sym: i32, pointee_sym: i32):
    self.local_pointee_structs.insert(sym, pointee_sym)
    let canon = self.canonical_local_sym(sym)
    if canon != 0 and canon != sym:
        self.local_pointee_structs.insert(canon, pointee_sym)

fn Codegen.record_trait_local(self: Codegen, sym: i32, trait_sym: i32):
    self.trait_locals.insert(sym, trait_sym)
    let canon = self.canonical_local_sym(sym)
    if canon != 0 and canon != sym:
        self.trait_locals.insert(canon, trait_sym)

fn Codegen.record_trait_local_concrete(self: Codegen, sym: i32, type_sym: i32):
    self.trait_local_concrete_types.insert(sym, type_sym)
    let canon = self.canonical_local_sym(sym)
    if canon != 0 and canon != sym:
        self.trait_local_concrete_types.insert(canon, type_sym)

fn Codegen.lookup_local_alloca(self: Codegen, sym: i32) -> i64:
    let direct = self.local_allocas.get(sym)
    if direct.is_some():
        return direct.unwrap() as i64
    let canon = self.canonical_local_sym(sym)
    if canon != 0 and canon != sym:
        let alias = self.local_allocas.get(canon)
        if alias.is_some():
            return alias.unwrap() as i64
    0

fn Codegen.lookup_local_type(self: Codegen, sym: i32) -> i64:
    let direct = self.local_types.get(sym)
    if direct.is_some():
        return direct.unwrap() as i64
    let canon = self.canonical_local_sym(sym)
    if canon != 0 and canon != sym:
        let alias = self.local_types.get(canon)
        if alias.is_some():
            return alias.unwrap() as i64
    0

fn Codegen.lookup_local_pointee_struct(self: Codegen, sym: i32) -> i32:
    let direct = self.local_pointee_structs.get(sym)
    if direct.is_some():
        return direct.unwrap()
    let canon = self.canonical_local_sym(sym)
    if canon != 0 and canon != sym:
        let alias = self.local_pointee_structs.get(canon)
        if alias.is_some():
            return alias.unwrap()
    0

fn Codegen.lookup_trait_local_concrete(self: Codegen, sym: i32) -> i32:
    let direct = self.trait_local_concrete_types.get(sym)
    if direct.is_some():
        return direct.unwrap()
    let canon = self.canonical_local_sym(sym)
    if canon != 0 and canon != sym:
        let alias = self.trait_local_concrete_types.get(canon)
        if alias.is_some():
            return alias.unwrap()
    0

fn Codegen.arg_lvalue_ptr_for_autoref(self: Codegen, arg_node: i32, arg_ty: i64, arg_val: i64) -> i64:
    if arg_node != 0 and self.pool.kind(arg_node) == NK_IDENT:
        let sym = self.pool.get_data0(arg_node)
        let alloca = self.lookup_local_alloca(sym)
        if alloca != 0:
            return alloca

    let tmp = self.create_entry_alloca(arg_ty)
    wl_build_store(self.builder, arg_val, tmp)
    tmp

fn Codegen.coerce_call_arg_to_param(self: Codegen, arg_node: i32, arg_val: i64, param_ty: i64, call_context: str, call_node: i32, arg_index: i32) -> i64:
    if arg_val == 0 or param_ty == 0:
        return arg_val

    var out = arg_val
    let arg_ty = wl_type_of(out)
    let param_kind = wl_get_type_kind(param_ty)
    if param_kind == wl_pointer_type_kind() and wl_get_type_kind(arg_ty) == wl_struct_type_kind():
        let ptr = self.arg_lvalue_ptr_for_autoref(arg_node, arg_ty, out)
        if ptr != 0:
            out = ptr

    let had_error_before = self.had_error
    let coerced = self.enforce_coerced_type(out, param_ty, "wrong argument type")
    if self.had_error != had_error_before:
        self.debug_call_coerce_failure(call_context, call_node, arg_index, arg_node, out, param_ty)
    coerced

fn Codegen.find_dyn_concrete_arg(self: Codegen, arg_node: i32, arg_ty: i64) -> DynArgInfo:
    if wl_get_type_kind(arg_ty) == wl_struct_type_kind():
        let st_sym = self.find_struct_type_by_llvm(arg_ty)
        if st_sym != 0:
            return DynArgInfo { type_sym: st_sym, use_ptr: 0 }

    if wl_get_type_kind(arg_ty) != wl_pointer_type_kind():
        return DynArgInfo { type_sym: 0, use_ptr: 0 }

    if arg_node != 0 and self.pool.kind(arg_node) == NK_UNARY:
        let uop = self.pool.get_data0(arg_node)
        if uop == UOP_REF or uop == UOP_MUT_REF:
            let inner = self.pool.get_data1(arg_node)
            if self.pool.kind(inner) == NK_IDENT:
                let base_sym = self.pool.get_data0(inner)
                let known = self.lookup_trait_local_concrete(base_sym)
                if known != 0:
                    return DynArgInfo { type_sym: known, use_ptr: 1 }
                let base_ty = self.lookup_local_type(base_sym)
                if base_ty != 0:
                    let st_sym = self.find_struct_type_by_llvm(base_ty)
                    if st_sym != 0:
                        return DynArgInfo { type_sym: st_sym, use_ptr: 1 }
                let base_name = self.ident_text_from_node(inner)
                if base_name.len() > 0:
                    let alias_sym = self.intern.intern(base_name)
                    let alias_known = self.trait_local_concrete_types.get(alias_sym)
                    if alias_known.is_some():
                        return DynArgInfo { type_sym: alias_known.unwrap(), use_ptr: 1 }
                    let aps = self.local_pointee_structs.get(alias_sym)
                    if aps.is_some():
                        return DynArgInfo { type_sym: aps.unwrap(), use_ptr: 1 }
                    let alt = self.local_types.get(alias_sym)
                    if alt.is_some():
                        let st_sym = self.find_struct_type_by_llvm(alt.unwrap() as i64)
                        if st_sym != 0:
                            return DynArgInfo { type_sym: st_sym, use_ptr: 1 }

    if arg_node != 0 and self.pool.kind(arg_node) == NK_IDENT:
        let sym = self.pool.get_data0(arg_node)
        let known = self.lookup_trait_local_concrete(sym)
        if known != 0:
            return DynArgInfo { type_sym: known, use_ptr: 1 }
        let ps = self.lookup_local_pointee_struct(sym)
        if ps != 0:
            return DynArgInfo { type_sym: ps, use_ptr: 1 }
        let sym_ty = self.lookup_local_type(sym)
        if sym_ty != 0:
            let st_sym = self.find_struct_type_by_llvm(sym_ty)
            if st_sym != 0:
                return DynArgInfo { type_sym: st_sym, use_ptr: 1 }
        let name = self.ident_text_from_node(arg_node)
        if name.len() > 0:
            let alias_sym = self.intern.intern(name)
            let alias_known = self.trait_local_concrete_types.get(alias_sym)
            if alias_known.is_some():
                return DynArgInfo { type_sym: alias_known.unwrap(), use_ptr: 1 }
            let aps = self.local_pointee_structs.get(alias_sym)
            if aps.is_some():
                return DynArgInfo { type_sym: aps.unwrap(), use_ptr: 1 }
            let alt = self.local_types.get(alias_sym)
            if alt.is_some():
                let st_sym = self.find_struct_type_by_llvm(alt.unwrap() as i64)
                if st_sym != 0:
                    return DynArgInfo { type_sym: st_sym, use_ptr: 1 }

    // Symbol lookup can miss when parser/resolver symbol IDs diverge; fall
    // back to pointee LLVM type to recover concrete dyn coercions.
    let pointee_ty = wl_get_element_type(arg_ty)
    if pointee_ty != 0:
        let st_sym = self.find_struct_type_by_llvm(pointee_ty)
        if st_sym != 0:
            return DynArgInfo { type_sym: st_sym, use_ptr: 1 }

    DynArgInfo { type_sym: 0, use_ptr: 0 }

fn Codegen.build_dyn_trait_value(self: Codegen, concrete_val: i64, type_sym: i32, trait_sym: i32) -> i64:
    let key = codegen_hash_type_trait_key(type_sym, trait_sym)
    let vg = self.vtable_globals.get(key)
    if not vg.is_some():
        return concrete_val

    let alloca = wl_build_alloca(self.builder, wl_type_of(concrete_val))
    wl_build_store(self.builder, concrete_val, alloca)

    let fat_ty = self.get_dyn_fat_ptr_type()
    var fat = wl_get_undef(fat_ty)
    fat = wl_build_insert_value(self.builder, fat, alloca, 0)
    fat = wl_build_insert_value(self.builder, fat, vg.unwrap() as i64, 1)
    fat

fn Codegen.build_dyn_trait_value_from_ptr(self: Codegen, data_ptr: i64, type_sym: i32, trait_sym: i32) -> i64:
    let key = codegen_hash_type_trait_key(type_sym, trait_sym)
    let vg = self.vtable_globals.get(key)
    if not vg.is_some():
        return data_ptr

    let ptr_ty = wl_ptr_type(self.context)
    let fat_ty = self.get_dyn_fat_ptr_type()
    let erased = wl_build_bitcast(self.builder, data_ptr, ptr_ty)
    var fat = wl_get_undef(fat_ty)
    fat = wl_build_insert_value(self.builder, fat, erased, 0)
    fat = wl_build_insert_value(self.builder, fat, vg.unwrap() as i64, 1)
    fat

fn Codegen.infer_local_pointee_struct(self: Codegen, value_node: i32, declared_type_node: i32, storage_ty: i64) -> i32:
    if wl_get_type_kind(storage_ty) != wl_pointer_type_kind():
        return 0

    if declared_type_node != 0:
        let dk = self.pool.kind(declared_type_node)
        if dk == NK_TYPE_REF or dk == NK_TYPE_PTR:
            let pointee = self.pool.get_data0(declared_type_node)
            if self.pool.kind(pointee) == NK_TYPE_NAMED:
                let sym = self.pool.get_data0(pointee)
                if self.intern.resolve(sym) == "Self" and self.current_method_owner_sym != 0:
                    return self.current_method_owner_sym
                if self.struct_type_map.get(sym).is_some():
                    return sym

    if value_node != 0 and self.pool.kind(value_node) == NK_UNARY:
        let uop = self.pool.get_data0(value_node)
        if uop == UOP_REF or uop == UOP_MUT_REF:
            let inner = self.pool.get_data1(value_node)
            if self.pool.kind(inner) == NK_IDENT:
                let base_sym = self.pool.get_data0(inner)
                let ps = self.lookup_local_pointee_struct(base_sym)
                if ps != 0:
                    return ps
                let base_ty = self.lookup_local_type(base_sym)
                if base_ty != 0:
                    let st_sym = self.find_struct_type_by_llvm(base_ty)
                    if st_sym != 0:
                        return st_sym

    if value_node != 0 and self.pool.kind(value_node) == NK_IDENT:
        let src_sym = self.pool.get_data0(value_node)
        let ps = self.lookup_local_pointee_struct(src_sym)
        if ps != 0:
            return ps

    0

fn Codegen.infer_local_concrete_struct(self: Codegen, value_node: i32, storage_ty: i64) -> i32:
    let by_ty = self.find_struct_type_by_llvm(storage_ty)
    if by_ty != 0:
        return by_ty
    if value_node == 0:
        return 0
    let vk = self.pool.kind(value_node)
    if vk == NK_STRUCT_LIT:
        let lit_sym = self.pool.get_data0(value_node)
        if lit_sym != 0:
            return lit_sym
    if vk == NK_IDENT:
        let sym = self.pool.get_data0(value_node)
        let known = self.lookup_trait_local_concrete(sym)
        if known != 0:
            return known
        let name = self.ident_text_from_node(value_node)
        if name.len() > 0:
            let alias_sym = self.intern.intern(name)
            let alias_known = self.lookup_trait_local_concrete(alias_sym)
            if alias_known != 0:
                return alias_known
    if vk == NK_UNARY:
        let uop = self.pool.get_data0(value_node)
        if uop == UOP_REF or uop == UOP_MUT_REF:
            let inner = self.pool.get_data1(value_node)
            if self.pool.kind(inner) == NK_IDENT:
                let sym = self.pool.get_data0(inner)
                let known = self.lookup_trait_local_concrete(sym)
                if known != 0:
                    return known
                let name = self.ident_text_from_node(inner)
                if name.len() > 0:
                    let alias_sym = self.intern.intern(name)
                    let alias_known = self.trait_local_concrete_types.get(alias_sym)
                    if alias_known.is_some():
                        return alias_known.unwrap()
    0

fn Codegen.coerce_call_args_for_fn_value(self: Codegen, fn_sym: i32, fn_val: i64, args_start: i32, arg_node_base_index: i32, args: Vec[i64], arg_count: i32, call_context: str, call_node: i32) -> Vec[i64]:
    let out: Vec[i64] = Vec.new()
    let param_count = wl_count_params(fn_val)
    for ai in 0..arg_count:
        var arg_val = args.get(ai as i64)
        if ai < param_count:
            let param_ty = wl_type_of(wl_get_param(fn_val, ai))
            let arg_node = if args_start >= 0 and ai >= arg_node_base_index:
                self.pool.get_extra(args_start + ai - arg_node_base_index)
            else:
                0
            let trait_sym = self.get_fn_dyn_param_trait(fn_sym, ai)
            if trait_sym != 0:
                let info = self.find_dyn_concrete_arg(arg_node, wl_type_of(arg_val))
                if info.type_sym != 0:
                    if info.use_ptr != 0:
                        arg_val = self.build_dyn_trait_value_from_ptr(arg_val, info.type_sym, trait_sym)
                    else:
                        arg_val = self.build_dyn_trait_value(arg_val, info.type_sym, trait_sym)
            arg_val = self.coerce_call_arg_to_param(arg_node, arg_val, param_ty, call_context, call_node, ai)
        out.push(arg_val)
    out

fn Codegen.mir_call_context(self: Codegen, body: MirBody, callee_operand: i32) -> str:
    var out = "mir " ++ self.function_symbol_name(body.fn_sym) ++ " -> "
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() as i32:
        return out ++ "<callee?>"
    let ok = body.operand_kinds.get(callee_operand as i64)
    let od = body.operand_d0.get(callee_operand as i64)
    if ok == OK_CONSTANT and od >= 0 and od < body.const_kinds.len() as i32:
        if body.const_kinds.get(od as i64) == CK_FN:
            return out ++ self.function_symbol_name(body.const_d0.get(od as i64))
    if (ok == OK_COPY or ok == OK_MOVE) and od >= 0 and od < body.place_locals.len() as i32:
        return out ++ "place_" ++ int_to_string(body.place_locals.get(od as i64))
    out ++ "indirect"

// ── Helper: find struct/enum type symbol from LLVM type ───────────

fn Codegen.find_type_symbol(self: Codegen, llvm_ty: i64) -> i32:
    // Search struct types
    for i in 0..self.struct_llvm_types.len() as i32:
        if self.struct_llvm_types.get(i as i64) == llvm_ty:
            // Find the symbol that maps to this index
            // We need to iterate the hashmap — just check all entries
            for j in 0..self.struct_field_counts.len() as i32:
                // struct_type_map maps sym → index, we want reverse
                0
            // Fallback: return 0
            return 0
    0

fn Codegen.find_struct_index_by_type(self: Codegen, llvm_ty: i64) -> i32:
    for i in 0..self.struct_llvm_types.len() as i32:
        if self.struct_llvm_types.get(i as i64) == llvm_ty:
            return i
    0 - 1

// Map source field index to LLVM struct field index (accounting for padding).
// Returns source_fi unchanged if no alignment padding exists for this struct.
fn Codegen.get_llvm_field_index(self: Codegen, llvm_ty: i64, source_fi: i32) -> i32:
    let struct_idx = self.find_struct_index_by_type(llvm_ty)
    if struct_idx < 0:
        return source_fi
    let f_start = self.struct_field_starts.get(struct_idx as i64)
    let f_count = self.struct_field_counts.get(struct_idx as i64)
    if source_fi < 0 or source_fi >= f_count:
        return source_fi
    let map_idx = (f_start + source_fi) as i64
    if map_idx >= self.struct_llvm_field_indices.len() as i64:
        return source_fi
    self.struct_llvm_field_indices.get(map_idx)

fn Codegen.vec_contains_i32(self: Codegen, values: Vec[i32], needle: i32) -> bool:
    for i in 0..values.len() as i32:
        if values.get(i as i64) == needle:
            return true
    false

fn Codegen.struct_reaches_type(self: Codegen, start_idx: i32, target_ty: i64) -> bool:
    var queue: Vec[i32] = Vec.new()
    var visited: Vec[i32] = Vec.new()
    queue.push(start_idx)
    visited.push(start_idx)

    var qi = 0
    while qi < queue.len() as i32:
        let cur = queue.get(qi as i64)
        qi = qi + 1

        let f_start = self.struct_field_starts.get(cur as i64)
        let f_count = self.struct_field_counts.get(cur as i64)
        for fi in 0..f_count:
            let f_ty = self.struct_field_types.get((f_start + fi) as i64)
            if f_ty == target_ty:
                return true
            let next_idx = self.find_struct_index_by_type(f_ty)
            if next_idx >= 0 and not self.vec_contains_i32(visited, next_idx):
                visited.push(next_idx)
                queue.push(next_idx)
    false

// ── Helper: span to line number ───────────────────────────────────

fn Codegen.span_to_line(self: Codegen, node: i32) -> i32:
    let start = self.pool.get_start(node)
    if start <= 0: return 1
    let src = self.source_text
    var line = 1
    for i in 0..start:
        if i < src.len() as i32:
            if src.byte_at(i as i64) == 10:
                line = line + 1
    line

// ── Helper: coerce integer widths ─────────────────────────────────

fn Codegen.coerce_int(self: Codegen, val: i64, target_ty: i64) -> i64:
    self.coerce_int_ext(val, target_ty, false)

fn Codegen.coerce_int_ext(self: Codegen, val: i64, target_ty: i64, is_unsigned: bool) -> i64:
    if val == 0: return val
    let val_ty = wl_type_of(val)
    if val_ty == target_ty: return val
    let vk = wl_get_type_kind(val_ty)
    let tk = wl_get_type_kind(target_ty)
    if vk == wl_integer_type_kind() and tk == wl_integer_type_kind():
        let vw = wl_get_int_type_width(val_ty)
        let tw = wl_get_int_type_width(target_ty)
        if vw < tw:
            if vw == 1 or is_unsigned:
                return wl_build_zext(self.builder, val, target_ty)
            return wl_build_sext(self.builder, val, target_ty)
        if vw > tw:
            return wl_build_trunc(self.builder, val, target_ty)
    val

// ── Helper: build default value for a type ────────────────────────

fn Codegen.build_default_value(self: Codegen, ty: i64) -> i64:
    let kind = wl_get_type_kind(ty)
    if kind == wl_integer_type_kind():
        return wl_const_int(ty, 0, 0)
    if kind == wl_float_type_kind() or kind == wl_double_type_kind():
        return wl_const_real(ty, 0.0)
    if kind == wl_pointer_type_kind():
        return wl_const_null(ty)
    if kind == wl_struct_type_kind():
        return wl_const_null(ty)
    wl_const_int(wl_i32_type(self.context), 0, 0)

fn Codegen.get_with_str_eq_fn_type(self: Codegen) -> i64:
    let str_ty = self.resolve_named_type(self.intern.intern("str"))
    let param_types: Vec[i64] = Vec.new()
    param_types.push(str_ty)
    param_types.push(str_ty)
    wl_function_type(wl_i32_type(self.context), vec_data_i64(&param_types), 2, 0)

fn Codegen.ensure_with_str_eq_declared(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "with_str_eq")
    if existing != 0:
        return existing
    let fn_ty = self.get_with_str_eq_fn_type()
    let fn_val = wl_add_function(self.llmod, "with_str_eq", fn_ty)
    let fn_sym = self.intern.intern("with_str_eq")
    self.fn_values.insert(fn_sym, fn_val)
    self.fn_fn_types.insert(fn_sym, fn_ty)
    fn_val

fn Codegen.compare_str_eq(self: Codegen, lhs: i64, rhs: i64, op: i32) -> i64:
    let fn_val = self.ensure_with_str_eq_declared()
    let fn_ty = self.get_with_str_eq_fn_type()
    let args: Vec[i64] = Vec.new()
    args.push(lhs)
    args.push(rhs)
    let cmp = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 2)
    let zero = wl_const_int(wl_i32_type(self.context), 0, 0)
    if op == OP_EQ:
        return wl_build_icmp(self.builder, wl_int_ne(), cmp, zero)
    wl_build_icmp(self.builder, wl_int_eq(), cmp, zero)

fn Codegen.get_memcmp_fn_type(self: Codegen) -> i64:
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(ptr_ty)
    param_types.push(ptr_ty)
    param_types.push(i64_ty)
    wl_function_type(i32_ty, vec_data_i64(&param_types), 3, 0)

fn Codegen.ensure_memcmp_declared(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "memcmp")
    if existing != 0:
        return existing
    let fn_ty = self.get_memcmp_fn_type()
    wl_add_function(self.llmod, "memcmp", fn_ty)

fn Codegen.compare_aggregate_eq(self: Codegen, lhs: i64, rhs: i64, op: i32) -> i64:
    let lhs_ty = wl_type_of(lhs)
    let rhs_ty = wl_type_of(rhs)
    let i1_ty = wl_i1_type(self.context)
    if lhs_ty == 0 or rhs_ty == 0 or lhs_ty != rhs_ty:
        return wl_get_undef(i1_ty)
    if self.is_str_type(lhs_ty):
        return self.compare_str_eq(lhs, rhs, op)

    let byte_size = self.abi_size_of(lhs_ty)
    if byte_size <= 0:
        if op == OP_EQ:
            return wl_const_int(i1_ty, 1, 0)
        return wl_const_int(i1_ty, 0, 0)

    // Field-wise comparison for structs to avoid padding byte mismatches.
    let ty_kind = wl_get_type_kind(lhs_ty)
    if ty_kind == wl_struct_type_kind():
        let field_count = wl_count_struct_elem_types(lhs_ty)
        if field_count == 0:
            if op == OP_EQ:
                return wl_const_int(i1_ty, 1, 0)
            return wl_const_int(i1_ty, 0, 0)
        var result = wl_const_int(i1_ty, 1, 0)
        var fi = 0
        while fi < field_count:
            let lf = wl_build_extract_value(self.builder, lhs, fi)
            let rf = wl_build_extract_value(self.builder, rhs, fi)
            let fk = wl_get_type_kind(wl_struct_get_type_at(lhs_ty, fi))
            var field_eq: i64 = 0
            if fk == wl_struct_type_kind():
                field_eq = self.compare_aggregate_eq(lf, rf, OP_EQ)
            else if self.is_str_type(wl_struct_get_type_at(lhs_ty, fi)):
                field_eq = self.compare_str_eq(lf, rf, OP_EQ)
            else:
                if fk == wl_float_type_kind() or fk == wl_double_type_kind():
                    field_eq = wl_build_fcmp(self.builder, wl_real_oeq(), lf, rf)
                else:
                    field_eq = wl_build_icmp(self.builder, wl_int_eq(), lf, rf)
            result = wl_build_and(self.builder, result, field_eq)
            fi = fi + 1
        if op == OP_EQ:
            return result
        return wl_build_not(self.builder, result)

    // Fallback: memcmp for arrays and other non-struct aggregates.
    let lhs_slot = self.create_entry_alloca(lhs_ty)
    let rhs_slot = self.create_entry_alloca(rhs_ty)
    wl_build_store(self.builder, lhs, lhs_slot)
    wl_build_store(self.builder, rhs, rhs_slot)

    let ptr_ty = wl_ptr_type(self.context)
    let lhs_ptr = wl_build_bitcast(self.builder, lhs_slot, ptr_ty)
    let rhs_ptr = wl_build_bitcast(self.builder, rhs_slot, ptr_ty)
    let args: Vec[i64] = Vec.new()
    args.push(lhs_ptr)
    args.push(rhs_ptr)
    args.push(wl_const_int(wl_i64_type(self.context), byte_size, 0))

    let memcmp_fn = self.ensure_memcmp_declared()
    let memcmp_ty = self.get_memcmp_fn_type()
    let cmp = wl_build_call(self.builder, memcmp_ty, memcmp_fn, vec_data_i64(&args), 3)
    let zero = wl_const_int(wl_i32_type(self.context), 0, 0)
    if op == OP_EQ:
        return wl_build_icmp(self.builder, wl_int_eq(), cmp, zero)
    wl_build_icmp(self.builder, wl_int_ne(), cmp, zero)

// ── Helper: create entry alloca ───────────────────────────────────

fn Codegen.create_entry_alloca(self: Codegen, ty: i64) -> i64:
    wl_create_entry_alloca(self.builder, self.current_function, ty)

fn vec_data_i64(v: &Vec[i64]) -> i64:
    wl_vec_data_ptr(v)

// ── Resolve type expression → LLVM type ───────────────────────────

fn Codegen.resolve_type(self: Codegen, type_node: i32) -> i64:
    if type_node == 0: return wl_void_type(self.context)
    let kind = self.pool.kind(type_node)

    // with_eprintln("[codegen] resolve_type node=" ++ int_to_string(type_node) ++ " kind=" ++ int_to_string(kind))

    if kind == NK_IDENT:
        let sym = self.pool.get_data0(type_node)
        return self.resolve_named_type(sym)

    if kind == NK_TYPE_NAMED:
        let sym = self.pool.get_data0(type_node)
        return self.resolve_named_type(sym)

    if kind == NK_TYPE_PTR:
        // Check for dyn trait pointer
        let pointee = self.pool.get_data0(type_node)
        if self.pool.kind(pointee) == NK_TYPE_TRAIT_OBJ:
            // Fat pointer {data_ptr, vtable_ptr}
            return self.get_dyn_fat_ptr_type()
        return wl_ptr_type(self.context)

    if kind == NK_TYPE_REF:
        let pointee = self.pool.get_data0(type_node)
        if self.pool.kind(pointee) == NK_TYPE_TRAIT_OBJ:
            return self.get_dyn_fat_ptr_type()
        return wl_ptr_type(self.context)

    if kind == NK_TYPE_FN:
        // Function type → fat pointer {fn_ptr, ctx_ptr}
        let ptr_ty = wl_ptr_type(self.context)
        let fat_types: Vec[i64] = Vec.new()
        fat_types.push(ptr_ty)
        fat_types.push(ptr_ty)
        return wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)

    if kind == NK_TYPE_ARRAY:
        let elem_node = self.pool.get_data0(type_node)
        let size_lo = self.pool.get_data1(type_node)
        let elem_ty = self.resolve_type(elem_node)
        return wl_array_type(elem_ty, size_lo as i64)

    if kind == NK_TYPE_SLICE:
        let elem_node = self.pool.get_data0(type_node)
        self.resolve_type(elem_node)
        // Slice is {ptr, i64} like str
        let body_types: Vec[i64] = Vec.new()
        body_types.push(wl_ptr_type(self.context))
        body_types.push(wl_i64_type(self.context))
        return wl_struct_type(self.context, vec_data_i64(&body_types), 2, 0)

    if kind == NK_TYPE_OPTIONAL:
        let inner_node = self.pool.get_data0(type_node)
        let payload_ty = self.resolve_type(inner_node)
        let opt = self.get_or_create_option_type(payload_ty)
        return opt

    if kind == NK_TYPE_TUPLE:
        let extra_start = self.pool.get_data0(type_node)
        let elem_count = self.pool.get_data1(type_node)
        let elem_types: Vec[i64] = Vec.new()
        for i in 0..elem_count:
            let et_node = self.pool.get_extra(extra_start + i)
            elem_types.push(self.resolve_type(et_node))
        return wl_struct_type(self.context, vec_data_i64(&elem_types), elem_count, 0)

    if kind == NK_TYPE_GENERIC:
        let name_sym = self.pool.get_data0(type_node)
        let g_extra = self.pool.get_data1(type_node)
        let g_count = self.pool.get_data2(type_node)
        let name = self.intern.resolve(name_sym)
        // Box[T] is always a pointer (fat pointer for Box[dyn Trait])
        if name == "Box" and g_count == 1:
            let inner_node = self.pool.get_extra(g_extra)
            if self.pool.kind(inner_node) == NK_TYPE_TRAIT_OBJ:
                return self.get_dyn_fat_ptr_type()
            return wl_ptr_type(self.context)
        // ContextError[E] = { str, E }
        if name == "ContextError" and g_count == 1:
            let src_node = self.pool.get_extra(g_extra)
            let src_ty = self.resolve_type(src_node)
            return self.get_or_create_context_error_type(src_ty)
        // Sema-based path for builtin containers (Vec, HashMap, HashSet, Option, Result)
        let sema_tid = self.sema.resolve_type_expr(type_node)
        if sema_tid > 0:
            let llvm_ty = self.sema_type_to_llvm(sema_tid)
            if llvm_ty != 0:
                return llvm_ty
        // Codegen-level resolution when sema fails (e.g. type bindings active)
        if name == "Option" and g_count == 1:
            let opt_arg = self.resolve_type(self.pool.get_extra(g_extra))
            if opt_arg != 0:
                return self.get_or_create_option_type(opt_arg)
        if name == "Vec" and g_count == 1:
            let vec_arg = self.resolve_type(self.pool.get_extra(g_extra))
            if vec_arg != 0:
                return self.get_or_create_vec_type(vec_arg)
        if name == "Result" and g_count == 2:
            let res_ok = self.resolve_type(self.pool.get_extra(g_extra))
            let res_err = self.resolve_type(self.pool.get_extra(g_extra + 1))
            if res_ok != 0 and res_err != 0:
                return self.get_or_create_result_type(res_ok, res_err)
        // Monomorphize user-defined generic structs
        let gs_opt = self.generic_structs.get(name_sym)
        if gs_opt.is_some():
            return self.monomorphize_struct(name_sym, g_extra, g_count)
        return 0

    if kind == NK_TYPE_TRAIT_OBJ:
        // dyn Trait → fat pointer {data_ptr, vtable_ptr}
        return self.get_dyn_fat_ptr_type()

    if kind == NK_TYPE_INFERRED:
        return 0  // Cannot resolve inferred types

    if kind == NK_TYPE_ASSOC:
        // Self.Name — resolve associated type from current impl
        let base_sym = self.pool.get_data0(type_node)
        let assoc_sym = self.pool.get_data1(type_node)
        if self.intern.resolve(base_sym) == "Self" and self.current_function_name_sym != 0:
            let impl_opt = self.sema.method_impl_nodes.get(self.current_function_name_sym)
            if impl_opt.is_some():
                let impl_nd = impl_opt.unwrap()
                let impl_ex = self.pool.get_data1(impl_nd)
                let impl_ac = self.pool.get_extra(impl_ex)
                for iai in 0..impl_ac:
                    let at_name = self.pool.get_extra(impl_ex + 1 + iai * 2)
                    if at_name == assoc_sym:
                        let at_type_nd = self.pool.get_extra(impl_ex + 1 + iai * 2 + 1)
                        return self.resolve_type(at_type_nd)
        // Type parameter: check type_binding_syms for base_sym → resolve via sema
        for tbi in 0..self.type_bindings_len:
            if self.type_binding_syms.get(tbi as i64) == base_sym:
                // base_sym is a bound type param — use sema to resolve assoc type
                let sema_resolved = self.sema.resolve_type_expr(type_node)
                if sema_resolved > 0:
                    let llvm_ty = self.sema_type_to_llvm(sema_resolved)
                    if llvm_ty != 0:
                        return llvm_ty
                break
        return wl_i32_type(self.context)

    // Fallback — always warn so silent miscompilation is visible
    var msg = "warning: [type-resolve] unhandled type node kind=" ++ int_to_string(kind)
    msg = msg ++ " node=" ++ int_to_string(type_node)
    msg = msg ++ " span=" ++ int_to_string(self.pool.get_start(type_node)) ++ ".." ++ int_to_string(self.pool.get_end(type_node))
    with_eprintln(msg)
    wl_i32_type(self.context)

fn Codegen.resolve_primitive_named_type(self: Codegen, name: str) -> i64:
    if name == "i32": return wl_i32_type(self.context)
    if name == "i64": return wl_i64_type(self.context)
    if name == "i128": return wl_i128_type(self.context)
    if name == "i16": return wl_i16_type(self.context)
    if name == "i8": return wl_i8_type(self.context)
    if name == "u8": return wl_i8_type(self.context)
    if name == "u16": return wl_i16_type(self.context)
    if name == "u32": return wl_i32_type(self.context)
    if name == "u64": return wl_i64_type(self.context)
    if name == "u128": return wl_i128_type(self.context)
    if name == "bool": return wl_i1_type(self.context)
    if name == "f64": return wl_f64_type(self.context)
    if name == "f32": return wl_f32_type(self.context)
    // Pointer-width integers are currently 64-bit on supported targets.
    if name == "usize": return wl_i64_type(self.context)
    if name == "isize": return wl_i64_type(self.context)
    if name == "void": return wl_void_type(self.context)
    if name == "Never": return wl_void_type(self.context)
    if name == "Unit": return wl_i32_type(self.context)
    0

fn Codegen.resolve_user_named_type(self: Codegen, sym: i32) -> i64:
    // User-defined struct types
    let st_opt = self.struct_type_map.get(sym)
    if st_opt.is_some():
        let idx = st_opt.unwrap()
        return self.struct_llvm_types.get(idx as i64)
    // User-defined enum types
    let et_opt = self.enum_type_map.get(sym)
    if et_opt.is_some():
        let idx = et_opt.unwrap()
        return self.enum_llvm_types.get(idx as i64)
    // Type aliases
    let al_opt = self.type_aliases.get(sym)
    if al_opt.is_some():
        return al_opt.unwrap() as i64
    // Check active type bindings (monomorphization)
    for i in 0..self.type_bindings_len:
        if self.type_binding_syms.get(i as i64) == sym:
            return self.type_binding_types.get(i as i64)
    // Unsupported
    0

fn Codegen.resolve_named_type(self: Codegen, sym: i32) -> i64:
    let name = self.intern.resolve(sym)
    // Resolve Self to current method owner type
    if name == "Self" and self.current_method_owner_sym != 0:
        return self.resolve_user_named_type(self.current_method_owner_sym)
    let prim = self.resolve_primitive_named_type(name)
    if prim != 0:
        return prim
    self.resolve_user_named_type(sym)

// Get sema TypeId for an expression node. Uses local_sema_types for idents.
fn Codegen.sema_type_of_node(self: Codegen, node: i32) -> i32:
    if node == 0:
        return 0
    let nk = self.pool.kind(node)
    if nk == NK_IDENT:
        let sym = self.pool.get_data0(node)
        let opt = self.local_sema_types.get(sym)
        if opt.is_some():
            return opt.unwrap()
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            let canon_opt = self.local_sema_types.get(canon)
            if canon_opt.is_some():
                return canon_opt.unwrap()
    // Literal types
    if nk == NK_STRING_LIT:
        return self.sema.ty_str
    if nk == NK_INT_LIT:
        return self.sema.ty_i32
    if nk == NK_FLOAT_LIT:
        return self.sema.ty_f64
    if nk == NK_BOOL_LIT:
        return self.sema.ty_bool
    // Fall back to sema's typed_expr_types (populated by check_ident)
    if self.sema.typed_expr_types.contains(node):
        let typed = self.sema.typed_expr_types.get(node).unwrap()
        if typed > 0:
            return typed
    0

// Extract LLVM type of the i'th generic arg from a sema TY_GENERIC_INST type.
fn Codegen.sema_generic_arg_llvm(self: Codegen, sema_tid: i32, arg_idx: i32) -> i64:
    if sema_tid <= 0:
        return 0
    if self.sema.get_type_kind(sema_tid) != TY_GENERIC_INST:
        return 0
    let ac = self.sema.get_generic_inst_arg_count(sema_tid)
    if arg_idx >= ac:
        return 0
    let inner_tid = self.sema.get_generic_inst_arg(sema_tid, arg_idx)
    self.sema_type_to_llvm(inner_tid)

// Map sema TypeId to LLVM type. Handles TY_GENERIC_INST for builtin containers.
fn Codegen.sema_type_to_llvm(self: Codegen, tid: i32) -> i64:
    if tid <= 0:
        return 0
    let tk = self.sema.get_type_kind(tid)
    if tk == TY_GENERIC_INST:
        let base_name = self.intern.resolve(self.sema.get_type_d0(tid))
        let arg_count = self.sema.get_generic_inst_arg_count(tid)
        if base_name == "Vec" and arg_count > 0:
            let elem_tid = self.sema.get_generic_inst_arg(tid, 0)
            let elem_ty = self.sema_type_to_llvm(elem_tid)
            if elem_ty != 0:
                return self.get_or_create_vec_type(elem_ty)
        if base_name == "HashMap" and arg_count > 1:
            let key_tid = self.sema.get_generic_inst_arg(tid, 0)
            let val_tid = self.sema.get_generic_inst_arg(tid, 1)
            let key_ty = self.sema_type_to_llvm(key_tid)
            let val_ty = self.sema_type_to_llvm(val_tid)
            if key_ty != 0 and val_ty != 0:
                return self.get_or_create_hashmap_type(key_ty, val_ty)
        if base_name == "HashSet" and arg_count > 0:
            let elem_tid = self.sema.get_generic_inst_arg(tid, 0)
            let elem_ty = self.sema_type_to_llvm(elem_tid)
            if elem_ty != 0:
                return self.get_or_create_hashset_type(elem_ty)
        if base_name == "Option" and arg_count > 0:
            let payload_tid = self.sema.get_generic_inst_arg(tid, 0)
            let payload_ty = self.sema_type_to_llvm(payload_tid)
            if payload_ty != 0:
                return self.get_or_create_option_type(payload_ty)
        if base_name == "Result" and arg_count > 1:
            let ok_tid = self.sema.get_generic_inst_arg(tid, 0)
            let err_tid = self.sema.get_generic_inst_arg(tid, 1)
            let ok_ty = self.sema_type_to_llvm(ok_tid)
            let err_ty = self.sema_type_to_llvm(err_tid)
            if ok_ty != 0 and err_ty != 0:
                return self.get_or_create_result_type(ok_ty, err_ty)
        // User-defined generic structs: monomorphize via type bindings
        let base_sym = self.sema.get_type_d0(tid)
        if base_sym != 0 and self.generic_structs.contains(base_sym):
            let saved_len = self.type_bindings_len
            let saved_syms = self.type_binding_syms
            let saved_types = self.type_binding_types
            let tp_syms: Vec[i32] = Vec.new()
            let tp_types: Vec[i64] = Vec.new()
            let gs_node = self.generic_structs.get(base_sym).unwrap()
            let tp_count = self.type_decl_tp_count(gs_node)
            var tp_pos = self.type_decl_tp_start(gs_node)
            for ti in 0..tp_count:
                let tp_sym = self.pool.get_extra(tp_pos)
                tp_syms.push(tp_sym)
                let bc = self.pool.get_extra(tp_pos + 1)
                tp_pos = tp_pos + 2 + bc
                var arg_ty: i64 = 0
                if ti < arg_count:
                    arg_ty = self.sema_type_to_llvm(self.sema.get_generic_inst_arg(tid, ti))
                if arg_ty == 0:
                    arg_ty = wl_i32_type(self.context)
                tp_types.push(arg_ty)
            self.type_binding_syms = tp_syms
            self.type_binding_types = tp_types
            self.type_bindings_len = tp_count
            let mono_ty = self.monomorphize_struct(base_sym, 0, 0)
            self.type_bindings_len = saved_len
            self.type_binding_syms = saved_syms
            self.type_binding_types = saved_types
            return mono_ty
        return 0
    if tk == TY_INT:
        let bits = self.sema.get_type_d0(tid)
        if bits == 1:
            return wl_i1_type(self.context)
        if bits == 8:
            return wl_i8_type(self.context)
        if bits == 16:
            return wl_i16_type(self.context)
        if bits == 32:
            return wl_i32_type(self.context)
        if bits == 64:
            return wl_i64_type(self.context)
        if bits == 128:
            return wl_i128_type(self.context)
        return wl_i32_type(self.context)
    if tk == TY_BOOL:
        return wl_i1_type(self.context)
    if tk == TY_STR:
        let str_sym = self.intern.intern("str")
        return self.resolve_named_type(str_sym)
    if tk == TY_VOID:
        return wl_void_type(self.context)
    if tk == TY_STRUCT or tk == TY_ENUM:
        let sym = self.sema.get_type_d0(tid)
        return self.resolve_named_type(sym)
    if tk == TY_PTR or tk == TY_REF:
        return wl_ptr_type(self.context)
    0

// Reverse map: LLVM type → sema TypeId (for primitives and str)
fn Codegen.llvm_type_to_sema_type(self: Codegen, ty: i64) -> i32:
    if ty == wl_i32_type(self.context): return self.sema.ty_i32
    if ty == wl_i64_type(self.context): return self.sema.ty_i64
    if ty == wl_i128_type(self.context): return self.sema.ty_i128
    if ty == wl_i1_type(self.context): return self.sema.ty_bool
    if ty == wl_i8_type(self.context): return self.sema.ty_i8
    if ty == wl_i16_type(self.context): return self.sema.ty_i16
    if ty == wl_f64_type(self.context): return self.sema.ty_f64
    if ty == wl_f32_type(self.context): return self.sema.ty_f32
    if ty == wl_ptr_type(self.context):
        // Could be str, ptr, or struct-by-ref — default to str
        return self.sema.ty_str
    0

// ── Builtin str type ──────────────────────────────────────────────

fn Codegen.declare_builtin_str_type(self: Codegen):
    let str_sym = self.intern.intern("str")
    // str = { i8*, i64 }
    let str_type = wl_struct_create_named(self.context, "str")
    wl_struct_set_body_2(str_type, wl_ptr_type(self.context), wl_i64_type(self.context), 0)

    let idx = self.struct_llvm_types.len() as i32
    self.struct_llvm_types.push(str_type)
    self.struct_index_syms.push(str_sym)
    self.struct_field_starts.push(self.struct_field_names.len() as i32)
    self.struct_field_counts.push(2)

    let ptr_sym = self.intern.intern("ptr")
    let len_sym = self.intern.intern("len")
    self.struct_field_names.push(ptr_sym)
    self.struct_field_names.push(len_sym)
    self.struct_field_types.push(wl_ptr_type(self.context))
    self.struct_field_types.push(wl_i64_type(self.context))
    self.struct_field_type_nodes.push(0)
    self.struct_field_type_nodes.push(0)
    self.struct_field_defaults.push(0)
    self.struct_field_defaults.push(0)
    self.struct_llvm_field_indices.push(0)
    self.struct_llvm_field_indices.push(1)

    self.struct_type_map.insert(str_sym, idx)

fn Codegen.predeclare_struct_type(self: Codegen, name_sym: i32):
    if self.struct_type_map.get(name_sym).is_some():
        return
    let name_str = self.intern.resolve(name_sym)
    let st_type = wl_struct_create_named(self.context, name_str)
    let idx = self.struct_llvm_types.len() as i32
    self.struct_llvm_types.push(st_type)
    self.struct_index_syms.push(name_sym)
    self.struct_field_starts.push(0)
    self.struct_field_counts.push(0)
    self.struct_type_map.insert(name_sym, idx)

fn Codegen.predeclare_enum_type(self: Codegen, name_sym: i32):
    if self.enum_type_map.get(name_sym).is_some():
        return
    let name_str = self.intern.resolve(name_sym)
    let enum_type = wl_struct_create_named(self.context, name_str)
    let idx = self.enum_llvm_types.len() as i32
    self.enum_llvm_types.push(enum_type)
    self.enum_variant_starts.push(0)
    self.enum_variant_counts.push(0)
    self.enum_type_map.insert(name_sym, idx)
    self.enum_by_llvm.insert(enum_type, name_sym)

fn Codegen.type_decl_tp_meta_start(self: Codegen, type_node: i32) -> i32:
    let extra_start = self.pool.get_data1(type_node)
    let sub_kind = type_decl_sub_kind(self.pool.get_data2(type_node))
    if sub_kind == TDK_STRUCT:
        let field_count = self.pool.get_extra(extra_start)
        return extra_start + 1 + field_count * 4 + 1
    if sub_kind == TDK_ENUM:
        let variant_count = self.pool.get_extra(extra_start)
        var pos = extra_start + 1
        for vi in 0..variant_count:
            pos = pos + 1 // variant name
            let payload_count = self.pool.get_extra(pos)
            pos = pos + 1 + payload_count
        return pos + 1
    if sub_kind == TDK_DISC_ENUM:
        let variant_count = self.pool.get_extra(extra_start + 1)
        var pos = extra_start + 2
        for vi in 0..variant_count:
            pos = pos + 1 // variant name
            pos = pos + 1 // disc value
            let payload_count = self.pool.get_extra(pos)
            pos = pos + 1 + payload_count
        return pos + 1
    if sub_kind == TDK_ALIAS or sub_kind == TDK_DISTINCT:
        return extra_start + 2
    0 - 1

fn Codegen.type_decl_tp_start(self: Codegen, type_node: i32) -> i32:
    let meta_start = self.type_decl_tp_meta_start(type_node)
    if meta_start < 0:
        return 0
    if meta_start >= self.pool.extra_len():
        return 0
    self.pool.get_extra(meta_start)

fn Codegen.type_decl_tp_count(self: Codegen, type_node: i32) -> i32:
    let meta_start = self.type_decl_tp_meta_start(type_node)
    if meta_start < 0:
        return 0
    if meta_start + 1 >= self.pool.extra_len():
        return 0
    self.pool.get_extra(meta_start + 1)

// ── Declare struct type ───────────────────────────────────────────

fn Codegen.declare_struct_type(self: Codegen, name_sym: i32, type_node: i32):
    // type_node is the NK_TYPE_DECL node with TDK_STRUCT
    let extra_start = self.pool.get_data1(type_node)
    let field_count = self.pool.get_extra(extra_start)

    let name_str = self.intern.resolve(name_sym)
    if not self.struct_type_map.get(name_sym).is_some():
        self.predeclare_struct_type(name_sym)
    let idx = self.struct_type_map.get(name_sym).unwrap()
    let st_type = self.struct_llvm_types.get(idx as i64)
    self.struct_field_starts.set_i32(idx as i64, self.struct_field_names.len() as i32)
    self.struct_field_counts.set_i32(idx as i64, field_count)

    // Parse fields: [field_name, field_type, field_default]*
    let ft_vec: Vec[i64] = Vec.new()
    var invalid_layout = 0
    for fi in 0..field_count:
        let offset = extra_start + 1 + fi * 3
        let f_name = self.pool.get_extra(offset)
        let f_type_node = self.pool.get_extra(offset + 1)
        let f_default = self.pool.get_extra(offset + 2)
        let f_ty = self.resolve_type(f_type_node)
        self.debug_type_layout_field(name_str, fi, f_name, f_type_node, f_ty)

        if f_ty == 0:
            with_eprintln("error: unresolved type for field '" ++ self.intern.resolve(f_name) ++ "' in struct '" ++ name_str ++ "'")
            invalid_layout = 1
            self.had_error = 1
        if f_ty == st_type:
            with_eprintln("error: recursive value field '" ++ self.intern.resolve(f_name) ++ "' in struct '" ++ name_str ++ "' (use pointer or reference)")
            invalid_layout = 1
            self.had_error = 1
        let dep_idx = self.find_struct_index_by_type(f_ty)
        if dep_idx >= 0 and dep_idx != idx and self.struct_reaches_type(dep_idx, st_type):
            with_eprintln("error: recursive value-cycle detected while lowering struct '" ++ name_str ++ "'")
            invalid_layout = 1
            self.had_error = 1

        self.struct_field_names.push(f_name)
        self.struct_field_types.push(f_ty)
        self.struct_field_type_nodes.push(f_type_node)
        self.struct_field_defaults.push(f_default)
        ft_vec.push(f_ty)

    if invalid_layout != 0:
        // Push identity mapping for error case
        for fi in 0..field_count:
            self.struct_llvm_field_indices.push(fi)
        return

    // Read alignment array from AST extras
    let align_base = extra_start + 1 + field_count * 3
    var has_alignment = false
    for fi in 0..field_count:
        if self.pool.get_extra(align_base + fi) != 0:
            has_alignment = true
            break

    let packed_kind = self.pool.get_data2(type_node)
    let is_packed = type_decl_is_packed(packed_kind)

    if has_alignment and not is_packed:
        // Build padded LLVM struct type (Zig-style approach).
        // Walk fields, insert [N x i8] padding arrays between fields
        // to match the C ABI layout specified by @[align(N)] annotations.
        let dl = wl_get_module_data_layout(self.llmod)
        let padded_types: Vec[i64] = Vec.new()
        var byte_offset: i64 = 0
        var use_packed = false
        var max_align: i64 = 1

        for fi in 0..field_count:
            let f_ty = ft_vec.get(fi as i64)
            let explicit_align = self.pool.get_extra(align_base + fi) as i64
            let natural_align = if dl != 0: wl_abi_align_of(dl, f_ty) as i64 else: 1
            let field_align = if explicit_align > 0: explicit_align else: natural_align
            if field_align > max_align:
                max_align = field_align

            // If explicit alignment is less than natural, LLVM struct must be packed
            if explicit_align > 0 and explicit_align < natural_align:
                use_packed = true

            // Insert padding to reach aligned offset
            if field_align > 1 and byte_offset > 0:
                let remainder = byte_offset % field_align
                if remainder != 0:
                    let pad_size = field_align - remainder
                    padded_types.push(wl_array_type(wl_i8_type(self.context), pad_size))
                    byte_offset = byte_offset + pad_size

            // Record LLVM field index for this source field
            self.struct_llvm_field_indices.push(padded_types.len() as i32)

            padded_types.push(f_ty)
            let f_size = if dl != 0: wl_abi_size_of(dl, f_ty) else: wl_size_of(f_ty)
            byte_offset = byte_offset + f_size

        // Tail padding to align struct size to max alignment
        if max_align > 1:
            let remainder = byte_offset % max_align
            if remainder != 0:
                let pad_size = max_align - remainder
                padded_types.push(wl_array_type(wl_i8_type(self.context), pad_size))

        let packed_flag = if use_packed: 1 else: 0
        wl_struct_set_body(st_type, vec_data_i64(&padded_types), padded_types.len() as i32, packed_flag)
    else:
        // No alignment annotations — identity mapping, direct field types
        for fi in 0..field_count:
            self.struct_llvm_field_indices.push(fi)
        wl_struct_set_body(st_type, vec_data_i64(&ft_vec), field_count, is_packed)

// ── Declare union type ────────────────────────────────────────────

fn Codegen.declare_union_type(self: Codegen, name_sym: i32, type_node: i32):
    // Union layout: {[max_size x i8]} — all fields overlap at offset 0.
    // Field access uses bitcast of pointer to field type.
    let extra_start = self.pool.get_data1(type_node)
    let field_count = self.pool.get_extra(extra_start)
    let name_str = self.intern.resolve(name_sym)

    if not self.struct_type_map.get(name_sym).is_some():
        self.predeclare_struct_type(name_sym)
    let idx = self.struct_type_map.get(name_sym).unwrap()
    let st_type = self.struct_llvm_types.get(idx as i64)
    self.struct_field_starts.set_i32(idx as i64, self.struct_field_names.len() as i32)
    self.struct_field_counts.set_i32(idx as i64, field_count)

    // Find max size among all fields
    var max_size: i64 = 0
    for fi in 0..field_count:
        let offset = extra_start + 1 + fi * 3
        let f_name = self.pool.get_extra(offset)
        let f_type_node = self.pool.get_extra(offset + 1)
        let f_default = self.pool.get_extra(offset + 2)
        let f_ty = self.resolve_type(f_type_node)
        self.struct_field_names.push(f_name)
        self.struct_field_types.push(f_ty)
        self.struct_field_type_nodes.push(f_type_node)
        self.struct_field_defaults.push(f_default)
        self.struct_llvm_field_indices.push(fi)
        let f_size = wl_size_of(f_ty)
        if f_size > max_size:
            max_size = f_size

    // Union body = single array of i8 with max field size
    if max_size == 0:
        max_size = 1
    let arr_ty = wl_array_type(wl_i8_type(self.context), max_size)
    let body: Vec[i64] = Vec.new()
    body.push(arr_ty)
    wl_struct_set_body(st_type, vec_data_i64(&body), 1, 0)

// ── Declare enum type ─────────────────────────────────────────────

fn Codegen.declare_enum_type(self: Codegen, name_sym: i32, type_node: i32):
    let extra_start = self.pool.get_data1(type_node)
    let variant_count = self.pool.get_extra(extra_start)
    let enum_name = self.intern.resolve(name_sym)

    // Find the largest payload to determine enum struct size.
    // Enum is { i32 tag, [N x i8] payload }.
    var max_payload_size: i64 = 0
    var invalid_layout = 0
    let v_starts = self.enum_variant_names.len() as i32
    var offset = extra_start + 1
    for vi in 0..variant_count:
        let v_name = self.pool.get_extra(offset)
        let v_payload_count = self.pool.get_extra(offset + 1)
        offset = offset + 2
        var payload_ty: i64 = 0
        if v_payload_count > 0:
            // Build all payload field types into a struct
            let payload_fields: Vec[i64] = Vec.new()
            for pi in 0..v_payload_count:
                let payload_type_node = self.pool.get_extra(offset + pi)
                let field_ty = self.resolve_type(payload_type_node)
                if field_ty == 0:
                    with_eprintln("error: unresolved payload type for enum variant '" ++ self.intern.resolve(v_name) ++ "' in '" ++ enum_name ++ "'")
                    self.had_error = 1
                    invalid_layout = 1
                payload_fields.push(field_ty)
            if invalid_layout == 0:
                payload_ty = wl_struct_type(self.context, vec_data_i64(&payload_fields), v_payload_count, 0)
            if payload_ty != 0:
                let sz = self.abi_size_of(payload_ty)
                if sz > max_payload_size:
                    max_payload_size = sz
            offset = offset + v_payload_count
        self.enum_variant_names.push(v_name)
        self.enum_variant_payloads.push(payload_ty)

    if invalid_layout != 0:
        return

    // Build enum struct: { i32, [N x i8] }
    if not self.enum_type_map.get(name_sym).is_some():
        self.predeclare_enum_type(name_sym)
    let idx = self.enum_type_map.get(name_sym).unwrap()
    let enum_type = self.enum_llvm_types.get(idx as i64)
    let body: Vec[i64] = Vec.new()
    body.push(wl_i32_type(self.context))
    if max_payload_size > 0:
        body.push(wl_array_type(wl_i8_type(self.context), max_payload_size))
    wl_struct_set_body(enum_type, vec_data_i64(&body), body.len() as i32, 0)

    self.enum_variant_starts.set_i32(idx as i64, v_starts)
    self.enum_variant_counts.set_i32(idx as i64, variant_count)

fn Codegen.declare_disc_enum_type(self: Codegen, name_sym: i32, type_node: i32):
    let extra_start = self.pool.get_data1(type_node)
    let repr_type_node = self.pool.get_extra(extra_start)
    let variant_count = self.pool.get_extra(extra_start + 1)
    let repr_ty = self.resolve_type(repr_type_node)
    if repr_ty == 0:
        return

    let idx = self.disc_enum_repr_types.len() as i32
    self.disc_enum_name_syms.push(name_sym)
    self.disc_enum_repr_types.push(repr_ty)
    let v_start = self.disc_enum_variant_names.len() as i32
    self.disc_enum_variant_starts.push(v_start)
    self.disc_enum_variant_counts.push(variant_count)
    self.disc_enum_type_map.insert(name_sym, idx)

    // First pass: collect variant info and compute max payload size
    var max_payload_size: i64 = 0
    var any_has_payload = 0
    var offset = extra_start + 2
    for vi in 0..variant_count:
        let v_name = self.pool.get_extra(offset)
        let disc_value = self.pool.get_extra(offset + 1)
        let payload_count = self.pool.get_extra(offset + 2)
        var payload_ty: i64 = 0
        if payload_count > 0:
            any_has_payload = 1
            let payload_fields: Vec[i64] = Vec.new()
            for pi in 0..payload_count:
                let payload_type_node = self.pool.get_extra(offset + 3 + pi)
                let field_ty = self.resolve_type(payload_type_node)
                if field_ty != 0:
                    payload_fields.push(field_ty)
            if payload_fields.len() as i32 == payload_count:
                payload_ty = wl_struct_type(self.context, vec_data_i64(&payload_fields), payload_count, 0)
                let sz = self.abi_size_of(payload_ty)
                if sz > max_payload_size:
                    max_payload_size = sz
        offset = offset + 3 + payload_count
        self.disc_enum_variant_names.push(v_name)
        self.disc_enum_variant_values.push(disc_value)
        self.disc_enum_variant_payloads.push(payload_ty)

    self.disc_enum_has_payload.push(any_has_payload)

    // If any variant has payload, also register in the regular enum tables
    // so the existing match payload extraction code can find the type info.
    if any_has_payload != 0:
        if not self.enum_type_map.get(name_sym).is_some():
            self.predeclare_enum_type(name_sym)
        let enum_idx = self.enum_type_map.get(name_sym).unwrap()
        let enum_type = self.enum_llvm_types.get(enum_idx as i64)
        // Build struct: { repr_type, [max_payload_size x i8] }
        let body: Vec[i64] = Vec.new()
        body.push(repr_ty)
        if max_payload_size > 0:
            body.push(wl_array_type(wl_i8_type(self.context), max_payload_size))
        wl_struct_set_body(enum_type, vec_data_i64(&body), body.len() as i32, 0)
        // Register variant info in regular enum tables for payload extraction
        let enum_v_start = self.enum_variant_names.len() as i32
        let dv_start = v_start
        for vi in 0..variant_count:
            self.enum_variant_names.push(self.disc_enum_variant_names.get((dv_start + vi) as i64))
            self.enum_variant_payloads.push(self.disc_enum_variant_payloads.get((dv_start + vi) as i64))
        self.enum_variant_starts.set_i32(enum_idx as i64, enum_v_start)
        self.enum_variant_counts.set_i32(enum_idx as i64, variant_count)

fn Codegen.gen_disc_enum_from_int_val(self: Codegen, de_idx: i32, arg_val: i64) -> i64:
    let repr_ty = self.disc_enum_repr_types.get(de_idx as i64)
    let v_start = self.disc_enum_variant_starts.get(de_idx as i64)
    let v_count = self.disc_enum_variant_counts.get(de_idx as i64)
    let input = self.coerce_int(arg_val, repr_ty)
    // Return Option[repr_type]: Some(disc_val) or None
    // Use insertvalue to build Option values directly (no allocas in case blocks)
    let i32_ty = wl_i32_type(self.context)
    let opt_ty = self.get_or_create_option_type(repr_ty)
    // None = { tag=1, payload=0 }
    var none_val = wl_get_undef(opt_ty)
    none_val = wl_build_insert_value(self.builder, none_val, wl_const_int(i32_ty, 1, 0), 0)
    none_val = wl_build_insert_value(self.builder, none_val, wl_const_int(repr_ty, 0, 0), 1)
    let result_alloca = self.create_entry_alloca(opt_ty)
    wl_build_store(self.builder, none_val, result_alloca)
    let default_bb = wl_append_bb(self.context, self.current_function, "from_int.default")
    let end_bb = wl_append_bb(self.context, self.current_function, "from_int.end")
    let sw = wl_build_switch(self.builder, input, default_bb, v_count)
    for vi in 0..v_count:
        let disc_val = self.disc_enum_variant_values.get((v_start + vi) as i64)
        let case_bb = wl_append_bb(self.context, self.current_function, "from_int.case")
        wl_add_case(sw, wl_const_int(repr_ty, disc_val as i64, 1), case_bb)
        wl_position_at_end(self.builder, case_bb)
        // Some(disc_val) = { tag=0, payload=disc_val }
        var some_val = wl_get_undef(opt_ty)
        some_val = wl_build_insert_value(self.builder, some_val, wl_const_int(i32_ty, 0, 0), 0)
        some_val = wl_build_insert_value(self.builder, some_val, wl_const_int(repr_ty, disc_val as i64, 1), 1)
        wl_build_store(self.builder, some_val, result_alloca)
        wl_build_br(self.builder, end_bb)
    wl_position_at_end(self.builder, default_bb)
    wl_build_br(self.builder, end_bb)
    wl_position_at_end(self.builder, end_bb)
    wl_build_load(self.builder, opt_ty, result_alloca)

fn Codegen.find_disc_enum_sym_by_idx(self: Codegen, de_idx: i32) -> i32:
    if de_idx >= 0 and de_idx < self.disc_enum_name_syms.len() as i32:
        return self.disc_enum_name_syms.get(de_idx as i64)
    0

// ── Declare function ──────────────────────────────────────────────

fn Codegen.function_symbol_name(self: Codegen, sym: i32) -> str:
    let name = self.intern.resolve(sym)
    if name.len() > 0:
        return name
    "__fn_" ++ int_to_string(sym)

fn Codegen.ident_text_from_node(self: Codegen, node: i32) -> str:
    if node == 0:
        return ""
    let start = self.pool.get_start(node)
    let end = self.pool.get_end(node)
    if start < 0 or end <= start:
        return ""
    if end > self.source_text.len() as i32:
        return ""
    self.source_text.slice(start as i64, end as i64)

fn Codegen.method_text_from_field_access(self: Codegen, node: i32) -> str:
    if node == 0 or self.pool.kind(node) != NK_FIELD_ACCESS:
        return ""
    let text = self.ident_text_from_node(node)
    if text.len() == 0:
        return ""
    var dot = 0 - 1
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 46:
            dot = i
    if dot < 0 or dot + 1 >= text.len() as i32:
        return ""
    text.slice((dot + 1) as i64, text.len())

fn Codegen.get_hashmap_new_fn_type(self: Codegen) -> i64:
    let params: Vec[i64] = Vec.new()
    params.push(wl_i64_type(self.context))
    params.push(wl_i64_type(self.context))
    wl_function_type(wl_ptr_type(self.context), vec_data_i64(&params), 2, 0)

fn Codegen.ensure_hashmap_new_declared(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "with_hashmap_new")
    if existing != 0:
        return existing
    let fn_ty = self.get_hashmap_new_fn_type()
    wl_add_function(self.llmod, "with_hashmap_new", fn_ty)

fn Codegen.fn_decl_name_from_node(self: Codegen, node: i32) -> str:
    let text = self.ident_text_from_node(node)
    if text.len() < 3:
        return ""
    var i = 0
    while i < text.len() as i32 and text.byte_at(i as i64) <= 32:
        i = i + 1
    if i + 1 >= text.len() as i32:
        return ""
    if text.byte_at(i as i64) != 102 or text.byte_at((i + 1) as i64) != 110:
        return ""
    i = i + 2
    while i < text.len() as i32 and text.byte_at(i as i64) <= 32:
        i = i + 1
    let start = i
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        let is_alpha = (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122)
        let is_digit = ch >= 48 and ch <= 57
        if is_alpha or is_digit or ch == 95 or ch == 46:
            i = i + 1
            continue
        break
    if i <= start:
        return ""
    text.slice(start as i64, i as i64)

fn Codegen.let_binding_name_from_node(self: Codegen, node: i32) -> str:
    let text = self.ident_text_from_node(node)
    if text.len() < 4:
        return ""
    var i = 0
    while i < text.len() as i32 and text.byte_at(i as i64) <= 32:
        i = i + 1
    if i + 2 >= text.len() as i32:
        return ""
    if text.byte_at(i as i64) != 108 or text.byte_at((i + 1) as i64) != 101 or text.byte_at((i + 2) as i64) != 116:
        return ""
    i = i + 3
    while i < text.len() as i32 and text.byte_at(i as i64) <= 32:
        i = i + 1
    if i + 2 < text.len() as i32 and text.byte_at(i as i64) == 109 and text.byte_at((i + 1) as i64) == 117 and text.byte_at((i + 2) as i64) == 116:
        i = i + 3
        while i < text.len() as i32 and text.byte_at(i as i64) <= 32:
            i = i + 1
    let start = i
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        let is_alpha = (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122)
        let is_digit = ch >= 48 and ch <= 57
        if is_alpha or is_digit or ch == 95:
            i = i + 1
            continue
        break
    if i <= start:
        return ""
    text.slice(start as i64, i as i64)

fn Codegen.declare_function(self: Codegen, fn_node: i32):
    let name_sym = self.pool.get_data0(fn_node)
    let name_str = self.intern.resolve(name_sym)
    if name_sym == 0:
        return
    let parsed_name = if name_str.len() == 0: self.fn_decl_name_from_node(fn_node) else: ""
    let alias_sym = if parsed_name.len() > 0: self.intern.intern(parsed_name) else: 0
    let flags = self.pool.get_data2(fn_node)
    let meta = self.pool.find_fn_meta(fn_node)
    if meta < 0: return

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)

    // Resolve param types
    let param_types: Vec[i64] = Vec.new()

    // Check if method (has dot in name); for missing symbol text, infer owner
    // from `self: Type` in param 0.
    var method_owner_sym = 0
    var method_key_sym: i32 = 0
    for di in 0..name_str.len() as i32:
        if name_str.byte_at(di as i64) == 46:
            method_owner_sym = self.intern.intern(name_str.slice(0, di as i64))
            let short_method_name = name_str.slice((di + 1) as i64, name_str.len() as i64)
            if short_method_name.len() > 0:
                let short_method_sym = self.intern.intern(short_method_name)
                let mk_str = "$m$" ++ int_to_string(method_owner_sym) ++ "|" ++ int_to_string(short_method_sym)
                method_key_sym = self.intern.intern(mk_str)
            break

    // Defer methods on generic structs that use struct type params
    if method_owner_sym != 0:
        let gs_decl_opt = self.generic_structs.get(method_owner_sym)
        if gs_decl_opt.is_some():
            let struct_decl = gs_decl_opt.unwrap()
            let stp_count = self.type_decl_tp_count(struct_decl)
            if stp_count > 0 and param_count > 0:
                let p0_tn = self.pool.fn_param_type(param_start, 0)
                if p0_tn != 0 and self.pool.kind(p0_tn) == NK_TYPE_GENERIC:
                    let p0_extra = self.pool.get_data1(p0_tn)
                    let p0_count = self.pool.get_data2(p0_tn)
                    var stp_pos = self.type_decl_tp_start(struct_decl)
                    var has_struct_tp = false
                    for sti in 0..stp_count:
                        let stp_sym = self.pool.get_extra(stp_pos)
                        for gi in 0..p0_count:
                            let arg_nd = self.pool.get_extra(p0_extra + gi)
                            if self.pool.kind(arg_nd) == NK_TYPE_NAMED and self.pool.get_data0(arg_nd) == stp_sym:
                                has_struct_tp = true
                        let bc = self.pool.get_extra(stp_pos + 1)
                        stp_pos = stp_pos + 2 + bc
                    if has_struct_tp:
                        self.generic_struct_methods.insert(name_sym, fn_node)
                        return

    // Set method owner before resolving return type so Self can resolve
    let saved_owner = self.current_method_owner_sym
    if method_owner_sym != 0:
        self.current_method_owner_sym = method_owner_sym

    let ret_ty_raw = self.resolve_type(ret_type_node)
    let ret_ty = if ret_ty_raw != 0: ret_ty_raw else: wl_i32_type(self.context)

    // Check if this returns Result
    if self.is_result_return_type(ret_type_node):
        self.fn_returns_result.insert(name_sym, 1)
        let err_sym = self.result_err_symbol_from_return(ret_type_node)
        if err_sym != 0:
            self.fn_result_err_symbols.insert(name_sym, err_sym)
        if self.is_result_unit_return(ret_type_node):
            self.fn_result_unit_returns.insert(name_sym, 1)

    var has_ref_param = false
    var pi = 0
    while pi < param_count:
        let p_name = self.pool.fn_param_name(param_start, pi)
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if p_type_node == 0:
            param_types.push(wl_i32_type(self.context))
            pi = pi + 1
            continue

        let p_kind = self.pool.kind(p_type_node)

        // Method owner-type parameter: lower as pointer for struct types.
        // Applies to self (pi==0) AND any other param of the same owner type.
        if p_kind == NK_TYPE_NAMED:
            let p_sym = self.pool.get_data0(p_type_node)
            let p_type_name = self.intern.resolve(p_sym)
            let p_name_text = self.intern.resolve(p_name)
            if method_owner_sym == 0 and p_name_text == "self" and self.struct_type_map.get(p_sym).is_some():
                method_owner_sym = p_sym
            if method_owner_sym != 0 and (p_type_name == "Self" or p_sym == method_owner_sym):
                // Only lower as pointer for struct/enum types; primitives and str pass by value.
                // str is in struct_type_map but has special value semantics (==, compare_str_eq).
                let owner_name = self.intern.resolve(method_owner_sym)
                let is_str_owner = owner_name == "str"
                if not is_str_owner and (self.struct_type_map.get(method_owner_sym).is_some() or self.enum_type_map.get(method_owner_sym).is_some()):
                    param_types.push(wl_ptr_type(self.context))
                    has_ref_param = true
                    self.record_ref_param(name_sym, pi, param_count)
                    if alias_sym != 0:
                        self.record_ref_param(alias_sym, pi, param_count)
                    if method_key_sym != 0:
                        self.record_ref_param(method_key_sym, pi, param_count)
                    pi = pi + 1
                    continue

        // fn type params → fat pointer
        if p_kind == NK_TYPE_FN:
            let ptr_ty = wl_ptr_type(self.context)
            let fat: Vec[i64] = Vec.new()
            fat.push(ptr_ty)
            fat.push(ptr_ty)
            param_types.push(wl_struct_type(self.context, vec_data_i64(&fat), 2, 0))
            pi = pi + 1
            continue

        // dyn Trait params (plain or wrapped forms: &dyn, *dyn, Box[dyn]).
        let trait_sym = self.dyn_trait_from_type_node(p_type_node)
        if trait_sym != 0:
            var dyn_ty = self.resolve_type(p_type_node)
            if dyn_ty == 0:
                dyn_ty = wl_i32_type(self.context)
            param_types.push(dyn_ty)
            self.record_dyn_param(name_sym, pi, param_count, trait_sym)
            if alias_sym != 0:
                self.record_dyn_param(alias_sym, pi, param_count, trait_sym)
            if method_key_sym != 0:
                self.record_dyn_param(method_key_sym, pi, param_count, trait_sym)
            pi = pi + 1
            continue

        // Reference params
        if p_kind == NK_TYPE_REF:
            var ref_ty = self.resolve_type(p_type_node)
            if ref_ty == 0:
                ref_ty = wl_ptr_type(self.context)
            param_types.push(ref_ty)
            has_ref_param = true
            self.record_ref_param(name_sym, pi, param_count)
            if alias_sym != 0:
                self.record_ref_param(alias_sym, pi, param_count)
            if method_key_sym != 0:
                self.record_ref_param(method_key_sym, pi, param_count)
            pi = pi + 1
            continue

        var p_ty = self.resolve_type(p_type_node)
        if p_ty == 0:
            p_ty = wl_i32_type(self.context)
        param_types.push(p_ty)
        pi = pi + 1

    let fn_type = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count, 0)

    // Use "main" for @[entry] functions
    var effective_name = self.function_symbol_name(name_sym)
    if parsed_name.len() > 0:
        effective_name = parsed_name
    if (flags / FN_FLAG_ENTRY) % 2 == 1:
        effective_name = "main"

    let function = wl_add_function(self.llmod, effective_name, fn_type)
    self.apply_noalias_param_attrs(function, param_start, param_count)

    // Mark non-main functions internal so the linker can dead-strip them.
    if effective_name != "main":
        wl_set_linkage(function, wl_internal_linkage())

    // Apply attributes
    if (flags / FN_FLAG_INLINE) % 2 == 1:
        wl_add_fn_attr(self.context, function, "alwaysinline")
    if (flags / FN_FLAG_NOINLINE) % 2 == 1:
        wl_add_fn_attr(self.context, function, "noinline")

    self.fn_values.insert(name_sym, function)
    self.fn_fn_types.insert(name_sym, fn_type)
    if alias_sym != 0:
        self.fn_values.insert(alias_sym, function)
        self.fn_fn_types.insert(alias_sym, fn_type)
    if method_key_sym != 0:
        self.fn_values.insert(method_key_sym, function)
        self.fn_fn_types.insert(method_key_sym, fn_type)

    self.current_method_owner_sym = saved_owner

fn Codegen.is_ref_param(self: Codegen, fn_sym: i32, param_idx: i32) -> bool:
    let start_opt = self.fn_ref_param_starts.get(fn_sym)
    if not start_opt.is_some():
        return false
    let start = start_opt.unwrap()
    let slot = start + param_idx
    if slot < 0 or slot >= self.fn_ref_param_data.len() as i32:
        return false
    self.fn_ref_param_data.get(slot as i64) != 0

fn Codegen.record_ref_param(self: Codegen, fn_sym: i32, idx: i32, count: i32):
    if not self.fn_ref_param_starts.get(fn_sym).is_some():
        let start = self.fn_ref_param_data.len() as i32
        self.fn_ref_param_starts.insert(fn_sym, start)
        for j in 0..count:
            self.fn_ref_param_data.push(0)
    let base = self.fn_ref_param_starts.get(fn_sym).unwrap()
    self.fn_ref_param_data.set_i32((base + idx) as i64, 1)

fn Codegen.apply_noalias_param_attrs(self: Codegen, function: i64, param_start: i32, param_count: i32):
    if function == 0 or param_start < 0 or param_count <= 0:
        return
    let fn_type = wl_global_get_value_type(function)
    for pi in 0..param_count:
        let flags = self.pool.fn_param_flags(param_start, pi)
        if fn_param_is_noalias(flags) == 0:
            continue
        var param_ty = if fn_type != 0: wl_get_fn_param_type(fn_type, pi) else: 0
        if param_ty == 0:
            let param = wl_get_param(function, pi)
            if param == 0:
                continue
            param_ty = wl_type_of(param)
        if wl_get_type_kind(param_ty) != wl_pointer_type_kind():
            continue
        wl_add_param_attr(self.context, function, pi, "noalias")

fn Codegen.record_dyn_param(self: Codegen, fn_sym: i32, idx: i32, count: i32, trait_sym: i32):
    if not self.fn_dyn_param_starts.get(fn_sym).is_some():
        let start = self.fn_dyn_param_data.len() as i32
        self.fn_dyn_param_starts.insert(fn_sym, start)
        for j in 0..count:
            self.fn_dyn_param_data.push(0)
    let base = self.fn_dyn_param_starts.get(fn_sym).unwrap()
    self.fn_dyn_param_data.set_i32((base + idx) as i64, trait_sym)

// ── Declare extern fn ─────────────────────────────────────────────

fn Codegen.declare_extern_fn(self: Codegen, ext_node: i32):
    let name_sym = self.pool.get_data0(ext_node)

    let ext_flags = self.pool.get_data2(ext_node)
    let is_variadic = ext_flags % 2

    let meta = self.pool.find_fn_meta(ext_node)
    if meta < 0: return

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)

    let ret_ty = self.resolve_type(ret_type_node)

    let param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        param_types.push(self.resolve_type(p_type_node))

    let fn_type = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count, is_variadic)

    let name_str = self.intern.resolve(name_sym)
    let link_name = self.canonical_extern_name(name_str)

    // Check if already declared
    let existing = wl_get_named_function(self.llmod, link_name)
    var function = existing
    if existing == 0:
        function = wl_add_function(self.llmod, link_name, fn_type)
    self.apply_noalias_param_attrs(function, param_start, param_count)

    // Apply calling convention or c_export if specified
    let cc_sym = self.pool.fn_meta_tp_start(meta)
    if cc_sym != 0:
        let cc_name = self.intern.resolve(cc_sym)
        if cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:":
            // @[c_export("name")] — set external linkage for C visibility
            // External linkage = 0 in LLVM (default for non-internal functions)
            wl_set_linkage(function, 0)
        else:
            let cc_id = self.resolve_callconv(cc_name)
            if cc_id >= 0:
                wl_set_call_conv(function, cc_id)

    let actual_fn_type = wl_global_get_value_type(function)
    self.fn_values.insert(name_sym, function)
    self.fn_fn_types.insert(name_sym, actual_fn_type)

    // Also register canonical name if different
    if link_name != name_str:
        let canonical_sym = self.intern.intern(link_name)
        if not self.fn_values.get(canonical_sym).is_some():
            self.fn_values.insert(canonical_sym, function)
            self.fn_fn_types.insert(canonical_sym, actual_fn_type)

fn Codegen.resolve_callconv(self: Codegen, name: str) -> i32:
    if name == "c": return wl_cc_c()
    if name == "stdcall": return wl_cc_x86_stdcall()
    if name == "fastcall": return wl_cc_x86_fastcall()
    if name == "thiscall": return wl_cc_x86_thiscall()
    if name == "win64": return wl_cc_win64()
    if name == "vectorcall": return wl_cc_x86_fastcall()
    if name == "aarch64_vfabi": return wl_cc_aarch64_vfabi()
    if name == "fast": return wl_cc_fast()
    -1

fn Codegen.declare_extern_var(self: Codegen, node: i32):
    // NK_EXTERN_VAR: d0=name(sym), d1=type_node, d2=flags(bit0=mut)
    let name_sym = self.pool.get_data0(node)
    let type_node = self.pool.get_data1(node)
    let flags = self.pool.get_data2(node)
    let is_mut = flags % 2

    let var_ty = self.resolve_type(type_node)
    if var_ty == 0:
        return
    let name_str = self.intern.resolve(name_sym)
    let link_name = self.canonical_extern_name(name_str)

    let existing = wl_get_named_global(self.llmod, link_name)
    var global = existing
    if existing == 0:
        global = wl_add_global(self.llmod, var_ty, link_name)
    // External linkage is the default — no need to set it
    if is_mut == 0:
        wl_set_global_constant(global, 1)
    self.module_constants.insert(name_sym, global)

fn Codegen.canonical_extern_name(self: Codegen, name: str) -> str:
    // c_import may suffix C symbols as "name.<n>" — strip the suffix for linking.
    var dot_pos = 0 - 1
    for i in 0..name.len() as i32:
        if name.byte_at(i as i64) == 46:
            dot_pos = i
    if dot_pos > 0 and dot_pos + 1 < name.len() as i32:
        var all_digits = true
        var j = dot_pos + 1
        while j < name.len() as i32:
            let ch = name.byte_at(j as i64)
            if ch < 48 or ch > 57:
                all_digits = false
                break
            j = j + 1
        if all_digits:
            return name.slice(0, dot_pos as i64)
    name

// ── Detect drop functions ─────────────────────────────────────────

fn Codegen.detect_drop_functions(self: Codegen):
    // Scan declared functions for "Type.drop" patterns
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NK_FN_DECL:
            let sym = self.pool.get_data0(decl)
            let name = self.intern.resolve(sym)
            if name.len() > 5:
                let suffix = name.slice(name.len() - 5, name.len())
                if suffix == ".drop":
                    let type_name = name.slice(0, name.len() - 5)
                    if type_name.len() > 0:
                        let type_sym = self.intern.intern(type_name)
                        if self.struct_type_map.get(type_sym).is_some() or self.enum_type_map.get(type_sym).is_some():
                            let fv = self.fn_values.get(sym)
                            let ft = self.fn_fn_types.get(sym)
                            if fv.is_some() and ft.is_some():
                                self.drop_fn_values.insert(type_sym, fv.unwrap() as i64)
                                self.drop_fn_types.insert(type_sym, ft.unwrap() as i64)

// ── Result return type helpers ────────────────────────────────────

fn Codegen.is_result_return_type(self: Codegen, ret_node: i32) -> bool:
    if ret_node == 0: return false
    if self.pool.kind(ret_node) != NK_TYPE_GENERIC: return false
    let name_sym = self.pool.get_data0(ret_node)
    let arg_count = self.pool.get_data2(ret_node)
    if arg_count != 2: return false
    let name = self.intern.resolve(name_sym)
    name == "Result"

fn Codegen.result_err_symbol_from_return(self: Codegen, ret_node: i32) -> i32:
    if not self.is_result_return_type(ret_node): return 0
    let extra_start = self.pool.get_data1(ret_node)
    let err_node = self.pool.get_extra(extra_start + 1)
    if self.pool.kind(err_node) == NK_TYPE_NAMED:
        return self.pool.get_data0(err_node)
    0

fn Codegen.is_result_unit_return(self: Codegen, ret_node: i32) -> bool:
    if not self.is_result_return_type(ret_node): return false
    let extra_start = self.pool.get_data1(ret_node)
    let ok_node = self.pool.get_extra(extra_start)
    if self.pool.kind(ok_node) == NK_TYPE_NAMED:
        let ok_name = self.intern.resolve(self.pool.get_data0(ok_node))
        return ok_name == "Unit"
    false

// ── Option/Result type construction ───────────────────────────────

fn Codegen.get_or_create_option_type(self: Codegen, payload_ty: i64) -> i64:
    // Optional pointers are represented as the pointer itself: null = None.
    if payload_ty != 0 and wl_get_type_kind(payload_ty) == wl_pointer_type_kind():
        return payload_ty

    let cached = self.option_cache_map.get(payload_ty)
    if cached.is_some():
        let idx = cached.unwrap()
        return self.option_llvm_types.get(idx as i64)

    // Option[T] = { i32 tag, T payload }
    let body: Vec[i64] = Vec.new()
    body.push(wl_i32_type(self.context))
    if payload_ty != 0:
        body.push(payload_ty)
    let opt_type = wl_struct_type(self.context, vec_data_i64(&body), body.len() as i32, 0)

    let idx = self.option_llvm_types.len() as i32
    self.option_llvm_types.push(opt_type)
    self.option_payload_types.push(payload_ty)
    self.option_err_types.push(0)
    let opt_sym = self.intern.intern("Option")
    self.option_enum_syms.push(opt_sym)
    self.option_cache_map.insert(payload_ty, idx)
    opt_type

fn Codegen.get_or_create_result_type(self: Codegen, ok_ty: i64, err_ty: i64) -> i64:
    let hash = ok_ty * 65537 + err_ty
    let cached = self.result_cache_map.get(hash)
    if cached.is_some():
        let idx = cached.unwrap()
        return self.result_llvm_types.get(idx as i64)

    let ok_size = self.abi_size_of(ok_ty)
    let err_size = self.abi_size_of(err_ty)
    var max_size = ok_size
    if err_size > max_size: max_size = err_size

    let body: Vec[i64] = Vec.new()
    body.push(wl_i32_type(self.context))
    if max_size > 0:
        body.push(wl_array_type(wl_i8_type(self.context), max_size))
    let res_type = wl_struct_type(self.context, vec_data_i64(&body), body.len() as i32, 0)

    let idx = self.result_llvm_types.len() as i32
    self.result_llvm_types.push(res_type)
    self.result_ok_types.push(ok_ty)
    self.result_err_types.push(err_ty)
    let res_sym = self.intern.intern("Result")
    self.result_enum_syms.push(res_sym)
    self.result_cache_map.insert(hash, idx)
    res_type

fn Codegen.get_or_create_context_error_type(self: Codegen, source_ty: i64) -> i64:
    // ContextError[E] = { str, E }
    let body: Vec[i64] = Vec.new()
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if st_opt.is_some():
        let str_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
        body.push(str_ty)
    else:
        body.push(wl_i32_type(self.context))
    body.push(source_ty)
    wl_struct_type(self.context, vec_data_i64(&body), 2, 0)

// ── Vec/HashMap/HashSet type construction ─────────────────────────

fn Codegen.deterministic_type_tag(self: Codegen, ty: i64) -> str:
    let kind = wl_get_type_kind(ty)
    if kind == wl_integer_type_kind():
        return "i" ++ int_to_string(wl_get_int_type_width(ty))
    if kind == wl_float_type_kind() or kind == wl_double_type_kind():
        return "f64"
    if kind == wl_pointer_type_kind():
        return "ptr"
    if kind == wl_struct_type_kind():
        let sn = wl_get_struct_name(ty)
        if sn.len() > 0:
            return sn
        return "s" ++ int_to_string(wl_count_struct_elem_types(ty))
    "t" ++ i64_to_string(ty)

fn Codegen.collection_wrapper_name_1(self: Codegen, prefix: str, t0: i64) -> str:
    prefix ++ "." ++ self.deterministic_type_tag(t0)

fn Codegen.collection_wrapper_name_2(self: Codegen, prefix: str, t0: i64, t1: i64) -> str:
    prefix ++ "." ++ self.deterministic_type_tag(t0) ++ "." ++ self.deterministic_type_tag(t1)

fn Codegen.get_or_create_vec_type(self: Codegen, elem_ty: i64) -> i64:
    let cached = self.vec_cache_map.get(elem_ty)
    if cached.is_some():
        return cached.unwrap()
    // Vec[T] = { ptr, i64, i64 } — ptr, len, cap (elem_size at runtime)
    let body: Vec[i64] = Vec.new()
    body.push(wl_ptr_type(self.context))
    body.push(wl_i64_type(self.context))
    body.push(wl_i64_type(self.context))
    body.push(wl_i64_type(self.context))
    let name = self.collection_wrapper_name_1("__with.Vec", elem_ty)
    let vec_ty = wl_struct_create_named(self.context, name)
    wl_struct_set_body(vec_ty, vec_data_i64(&body), 4, 0)
    self.cache_vec_type(elem_ty, vec_ty)
    vec_ty

fn Codegen.cache_vec_type(self: Codegen, elem_ty: i64, vec_ty: i64) -> i64:
    let cached = self.vec_cache_map.get(elem_ty)
    if cached.is_some():
        return cached.unwrap()
    self.vec_cache_map.insert(elem_ty, vec_ty)
    self.vec_type_to_elem.insert(vec_ty, elem_ty)
    vec_ty

fn Codegen.get_or_create_hashmap_type(self: Codegen, key_ty: i64, val_ty: i64) -> i64:
    let hash = key_ty * 65537 + val_ty
    let cached = self.hm_cache_map.get(hash)
    if cached.is_some():
        let existing = cached.unwrap() as i64
        if self.hm_type_to_key.contains(existing):
            return existing
    // HashMap is opaque { ptr }
    let body: Vec[i64] = Vec.new()
    body.push(wl_ptr_type(self.context))
    let name = self.collection_wrapper_name_2("__with.HashMap", key_ty, val_ty)
    let hm_ty = wl_struct_create_named(self.context, name)
    wl_struct_set_body(hm_ty, vec_data_i64(&body), 1, 0)
    self.cache_hashmap_type(key_ty, val_ty, hm_ty)
    hm_ty

fn Codegen.cache_hashmap_type(self: Codegen, key_ty: i64, val_ty: i64, hm_ty: i64) -> i64:
    let hash = key_ty * 65537 + val_ty
    let cached = self.hm_cache_map.get(hash)
    if cached.is_some():
        let existing = cached.unwrap()
        if self.hm_type_to_key.contains(existing):
            return existing
    if self.hm_type_to_key.contains(hm_ty):
        self.hm_cache_map.insert(hash, hm_ty)
        return hm_ty
    self.hm_type_to_key.insert(hm_ty, key_ty)
    self.hm_type_to_val.insert(hm_ty, val_ty)
    // Check if str key
    let str_sym = self.intern.intern("str")
    let str_opt = self.struct_type_map.get(str_sym)
    var is_str = 0
    if str_opt.is_some():
        if key_ty == self.struct_llvm_types.get(str_opt.unwrap() as i64):
            is_str = 1
    self.hm_type_to_is_str.insert(hm_ty, is_str)
    self.hm_cache_map.insert(hash, hm_ty)
    hm_ty

fn Codegen.get_or_create_hashset_type(self: Codegen, elem_ty: i64) -> i64:
    let cached = self.hs_cache_map.get(elem_ty)
    if cached.is_some():
        return cached.unwrap()
    let body: Vec[i64] = Vec.new()
    body.push(wl_ptr_type(self.context))
    let name = self.collection_wrapper_name_1("__with.HashSet", elem_ty)
    let hs_ty = wl_struct_create_named(self.context, name)
    wl_struct_set_body(hs_ty, vec_data_i64(&body), 1, 0)
    self.hs_cache_map.insert(elem_ty, hs_ty)
    hs_ty

// ── Monomorphize struct (stub) ────────────────────────────────────

fn Codegen.monomorphize_struct(self: Codegen, name_sym: i32, extra_start: i32, arg_count: i32) -> i64:
    let gs_opt = self.generic_structs.get(name_sym)
    if not gs_opt.is_some():
        return 0
    let type_node = gs_opt.unwrap()
    let tp_count = self.type_decl_tp_count(type_node)
    if tp_count <= 0:
        let st_opt = self.struct_type_map.get(name_sym)
        if st_opt.is_some():
            return self.struct_llvm_types.get(st_opt.unwrap() as i64)
        return 0

    let tp_syms: Vec[i32] = Vec.new()
    var tp_pos = self.type_decl_tp_start(type_node)
    for ti in 0..tp_count:
        let tp_sym = self.pool.get_extra(tp_pos)
        tp_syms.push(tp_sym)
        let bound_count = self.pool.get_extra(tp_pos + 1)
        tp_pos = tp_pos + 2 + bound_count

    let arg_types: Vec[i64] = Vec.new()
    if arg_count > 0:
        for ai in 0..arg_count:
            let arg_node = self.pool.get_extra(extra_start + ai)
            let arg_ty = self.resolve_type(arg_node)
            if arg_ty != 0:
                arg_types.push(arg_ty)
            else:
                arg_types.push(wl_i32_type(self.context))
    else:
        for ti in 0..tp_count:
            let tp_sym = tp_syms.get(ti as i64)
            var bound_ty: i64 = 0
            for bi in 0..self.type_bindings_len:
                if self.type_binding_syms.get(bi as i64) == tp_sym:
                    bound_ty = self.type_binding_types.get(bi as i64)
                    break
            if bound_ty == 0:
                bound_ty = wl_i32_type(self.context)
            arg_types.push(bound_ty)
    while arg_types.len() as i32 < tp_count:
        arg_types.push(wl_i32_type(self.context))

    let base_name = self.intern.resolve(name_sym)
    var mangled = base_name
    for ti in 0..tp_count:
        let arg_ty = arg_types.get(ti as i64)
        mangled = mangled ++ "__" ++ self.llvm_type_mangle(arg_ty)
    let mono_sym = self.intern.intern(mangled)

    let mono_idx_opt = self.struct_type_map.get(mono_sym)
    if mono_idx_opt.is_some():
        return self.struct_llvm_types.get(mono_idx_opt.unwrap() as i64)

    self.predeclare_struct_type(mono_sym)
    self.mono_struct_base.insert(mono_sym, name_sym)
    let tp_flat_start = self.mono_struct_tp_flat_syms.len() as i32
    for ti in 0..tp_count:
        self.mono_struct_tp_flat_syms.push(tp_syms.get(ti as i64))
        self.mono_struct_tp_flat_types.push(arg_types.get(ti as i64))
    self.mono_struct_tp_starts.insert(mono_sym, tp_flat_start)
    self.mono_struct_tp_counts.insert(mono_sym, tp_count)
    let mono_idx = self.struct_type_map.get(mono_sym).unwrap()
    let mono_ty = self.struct_llvm_types.get(mono_idx as i64)

    let saved_bind_syms = self.type_binding_syms
    let saved_bind_tys = self.type_binding_types
    let saved_bind_len = self.type_bindings_len
    let fresh_bind_syms: Vec[i32] = Vec.new()
    let fresh_bind_tys: Vec[i64] = Vec.new()
    self.type_binding_syms = fresh_bind_syms
    self.type_binding_types = fresh_bind_tys
    self.type_bindings_len = 0
    for ti in 0..tp_count:
        self.type_binding_syms.push(tp_syms.get(ti as i64))
        self.type_binding_types.push(arg_types.get(ti as i64))
        self.type_bindings_len = self.type_bindings_len + 1

    let decl_extra_start = self.pool.get_data1(type_node)
    let field_count = self.pool.get_extra(decl_extra_start)
    self.struct_field_starts.set_i32(mono_idx as i64, self.struct_field_names.len() as i32)
    self.struct_field_counts.set_i32(mono_idx as i64, field_count)

    let ft_vec: Vec[i64] = Vec.new()
    var invalid_layout = 0
    for fi in 0..field_count:
        let offset = decl_extra_start + 1 + fi * 3
        let f_name = self.pool.get_extra(offset)
        let f_type_node = self.pool.get_extra(offset + 1)
        let f_default = self.pool.get_extra(offset + 2)
        var f_ty = self.resolve_type(f_type_node)
        self.debug_type_layout_field(mangled, fi, f_name, f_type_node, f_ty)
        if f_ty == 0:
            with_eprintln("error: unresolved type for field '" ++ self.intern.resolve(f_name) ++ "' in struct '" ++ base_name ++ "'")
            invalid_layout = 1
            self.had_error = 1
            f_ty = wl_i32_type(self.context)
        self.struct_field_names.push(f_name)
        self.struct_field_types.push(f_ty)
        self.struct_field_type_nodes.push(f_type_node)
        self.struct_field_defaults.push(f_default)
        ft_vec.push(f_ty)

    // Push identity field index mapping (generic structs don't have alignment)
    for fi in 0..field_count:
        self.struct_llvm_field_indices.push(fi)

    if invalid_layout == 0:
        wl_struct_set_body(mono_ty, vec_data_i64(&ft_vec), field_count, 0)

    self.type_binding_syms = saved_bind_syms
    self.type_binding_types = saved_bind_tys
    self.type_bindings_len = saved_bind_len

    mono_ty

// ── Monomorphize generic struct method ───────────────────────────
// Compiles a method body with the struct's type params bound to concrete types.
// Called lazily when the method is first invoked on a monomorphized struct.

fn Codegen.monomorphize_struct_method_core(self: Codegen, mono_type_sym: i32, method_name: str, decl: i32, obj: i64, obj_node: i32, obj_ty: i64, args_start: i32, arg_count: i32, call_node: i32, pre_args: Vec[i64]) -> i64:
    let tp_start_opt = self.mono_struct_tp_starts.get(mono_type_sym)
    if not tp_start_opt.is_some():
        with_eprintln("error: no type param bindings for monomorphized struct")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    let tp_flat_start = tp_start_opt.unwrap()
    let tp_count = self.mono_struct_tp_counts.get(mono_type_sym).unwrap()

    let mono_type_name = self.intern.resolve(mono_type_sym)
    let mangled = mono_type_name ++ "." ++ method_name
    let mono_sym = self.intern.intern(mangled)

    // Check cache — method already monomorphized for this struct instantiation
    let cached_fv = self.fn_values.get(mono_sym)
    let cached_ft = self.fn_fn_types.get(mono_sym)
    if cached_fv.is_some() and cached_ft.is_some():
        let args: Vec[i64] = Vec.new()
        let is_ref = self.fn_ref_param_starts.get(mono_sym).is_some()
        if is_ref:
            args.push(self.get_mutable_receiver_ptr(obj_node, obj, obj_ty))
        else:
            args.push(obj)
        for ai in 0..arg_count:
            args.push(pre_args.get(ai as i64))
        let coerced = self.coerce_call_args_for_fn_value(mono_sym, cached_fv.unwrap() as i64, args_start, 1, args, arg_count + 1, "method " ++ mangled, call_node)
        return wl_build_call(self.builder, cached_ft.unwrap() as i64, cached_fv.unwrap() as i64, vec_data_i64(&coerced), arg_count + 1)

    // Set up type bindings from the monomorphized struct
    let saved_bind_syms = self.type_binding_syms
    let saved_bind_tys = self.type_binding_types
    let saved_bind_len = self.type_bindings_len
    let fresh_bind_syms: Vec[i32] = Vec.new()
    let fresh_bind_tys: Vec[i64] = Vec.new()
    self.type_binding_syms = fresh_bind_syms
    self.type_binding_types = fresh_bind_tys
    self.type_bindings_len = 0
    for ti in 0..tp_count:
        self.type_binding_syms.push(self.mono_struct_tp_flat_syms.get((tp_flat_start + ti) as i64))
        self.type_binding_types.push(self.mono_struct_tp_flat_types.get((tp_flat_start + ti) as i64))
        self.type_bindings_len = self.type_bindings_len + 1

    let meta = self.pool.find_fn_meta(decl)
    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)
    let body_node = self.pool.get_data1(decl)

    // Resolve param and return types with type bindings active
    let mono_param_types: Vec[i64] = Vec.new()
    var has_ref_self = false
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if p_type_node != 0:
            var p_ty = self.resolve_type(p_type_node)
            if p_ty == 0:
                p_ty = wl_i32_type(self.context)
            // Methods pass struct self as pointer
            if pi == 0:
                let p_kind = self.pool.kind(p_type_node)
                if p_kind == NK_TYPE_GENERIC or p_kind == NK_TYPE_NAMED:
                    let p_name_sym = self.pool.get_data0(p_type_node)
                    let st_opt = self.struct_type_map.get(p_name_sym)
                    if not st_opt.is_some():
                        // Check for monomorphized struct
                        let base = self.mono_struct_base.get(p_name_sym)
                        if not base.is_some():
                            // It's a generic self param — use the monomorphized struct type as pointer
                            has_ref_self = true
                            p_ty = wl_ptr_type(self.context)
                    else:
                        has_ref_self = true
                        p_ty = wl_ptr_type(self.context)
            mono_param_types.push(p_ty)
        else:
            mono_param_types.push(wl_i32_type(self.context))

    let mono_ret_ty_raw = self.resolve_type(ret_type_node)
    let mono_ret_ty = if mono_ret_ty_raw != 0: mono_ret_ty_raw else: wl_i32_type(self.context)

    let mono_ft = wl_function_type(mono_ret_ty, vec_data_i64(&mono_param_types), param_count, 0)
    let mono_fn = wl_add_function(self.llmod, mangled, mono_ft)
    self.apply_noalias_param_attrs(mono_fn, param_start, param_count)
    self.fn_values.insert(mono_sym, mono_fn)
    self.fn_fn_types.insert(mono_sym, mono_ft)
    if has_ref_self:
        self.fn_ref_param_starts.insert(mono_sym, 0)

    // Build sema type bindings for struct type params
    let sm_tp_syms: Vec[i32] = Vec.new()
    let sm_tp_sema_tys: Vec[i32] = Vec.new()
    for ti in 0..tp_count:
        let tp_sym = self.mono_struct_tp_flat_syms.get((tp_flat_start + ti) as i64)
        let tp_llvm = self.mono_struct_tp_flat_types.get((tp_flat_start + ti) as i64)
        sm_tp_syms.push(tp_sym)
        sm_tp_sema_tys.push(self.llvm_type_to_sema_type(tp_llvm))

    // 1. Type-check body with concrete types
    let sig_idx = self.sema.check_fn_body_concrete(decl, sm_tp_syms, sm_tp_sema_tys, mono_sym)

    // 2. Lower to MIR
    var mir_builder = MirBuilder.init(self.sema, self.pool, self.intern, mono_sym)
    let mir_body = lower_fn_with_sig(mir_builder, decl, sig_idx)

    // 3. Codegen via MIR (saves/restores all codegen state internally)
    self.gen_function_mir_mono(mono_sym, decl, mir_body)

    self.type_binding_syms = saved_bind_syms
    self.type_binding_types = saved_bind_tys
    self.type_bindings_len = saved_bind_len

    // Now call the monomorphized method
    let call_args: Vec[i64] = Vec.new()
    if has_ref_self:
        call_args.push(self.get_mutable_receiver_ptr(obj_node, obj, obj_ty))
    else:
        call_args.push(obj)
    for ai in 0..arg_count:
        call_args.push(pre_args.get(ai as i64))
    let coerced = self.coerce_call_args_for_fn_value(mono_sym, mono_fn, args_start, 1, call_args, arg_count + 1, "method " ++ mangled, call_node)
    wl_build_call(self.builder, mono_ft, mono_fn, vec_data_i64(&coerced), arg_count + 1)

// ── Build Option Some/None ────────────────────────────────────────

fn Codegen.build_option_some(self: Codegen, payload: i64, opt_type: i64) -> i64:
    if wl_get_type_kind(opt_type) == wl_pointer_type_kind():
        return self.coerce_value_to_type(payload, opt_type)
    let alloca = wl_build_alloca(self.builder, opt_type)
    // Fully initialize to avoid undef/poison in padding bytes.
    wl_build_store(self.builder, self.build_default_value(opt_type), alloca)
    // Store tag = 0 (Some)
    let tag_ptr = wl_build_struct_gep(self.builder, opt_type, alloca, 0)
    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), 0, 0), tag_ptr)
    // Store payload
    let elem_count = wl_count_struct_elem_types(opt_type)
    if elem_count > 1:
        let payload_ptr = wl_build_struct_gep(self.builder, opt_type, alloca, 1)
        let payload_ty = self.find_option_payload_type_by_llvm(opt_type)
        let payload_val = if payload_ty != 0: self.coerce_value_to_type(payload, payload_ty) else: payload
        wl_build_store(self.builder, payload_val, payload_ptr)
    wl_build_load(self.builder, opt_type, alloca)

fn Codegen.build_option_none(self: Codegen, opt_type: i64) -> i64:
    if wl_get_type_kind(opt_type) == wl_pointer_type_kind():
        return wl_const_null(opt_type)
    let alloca = wl_build_alloca(self.builder, opt_type)
    wl_build_store(self.builder, self.build_default_value(opt_type), alloca)
    let tag_ptr = wl_build_struct_gep(self.builder, opt_type, alloca, 0)
    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), 1, 0), tag_ptr)
    wl_build_load(self.builder, opt_type, alloca)

fn Codegen.build_result_ok(self: Codegen, val: i64, res_type: i64) -> i64:
    let alloca = wl_build_alloca(self.builder, res_type)
    wl_build_store(self.builder, self.build_default_value(res_type), alloca)
    let tag_ptr = wl_build_struct_gep(self.builder, res_type, alloca, 0)
    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), 0, 0), tag_ptr)
    let elem_count = wl_count_struct_elem_types(res_type)
    if elem_count > 1:
        let payload_ptr = wl_build_struct_gep(self.builder, res_type, alloca, 1)
        let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
        wl_build_store(self.builder, val, cast_ptr)
    wl_build_load(self.builder, res_type, alloca)

fn Codegen.build_result_err(self: Codegen, val: i64, res_type: i64) -> i64:
    let alloca = wl_build_alloca(self.builder, res_type)
    wl_build_store(self.builder, self.build_default_value(res_type), alloca)
    let tag_ptr = wl_build_struct_gep(self.builder, res_type, alloca, 0)
    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), 1, 0), tag_ptr)
    let elem_count = wl_count_struct_elem_types(res_type)
    if elem_count > 1:
        let payload_ptr = wl_build_struct_gep(self.builder, res_type, alloca, 1)
        let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
        wl_build_store(self.builder, val, cast_ptr)
    wl_build_load(self.builder, res_type, alloca)

// ── Emit drops / defers ───────────────────────────────────────────

fn Codegen.emit_drops(self: Codegen, watermark: i32):
    // Drop scoped locals above watermark in reverse order
    var i = self.scope_local_count - 1
    while i >= watermark:
        let sym = self.scope_local_syms.get(i as i64)
        let alloca = self.scope_local_allocas.get(i as i64)
        let ty = self.scope_local_types.get(i as i64)
        // Check for drop function
        let type_sym = self.find_type_symbol(ty)
        if type_sym != 0:
            let dfv = self.drop_fn_values.get(type_sym)
            let dft = self.drop_fn_types.get(type_sym)
            if dfv.is_some() and dft.is_some():
                let val = wl_build_load(self.builder, ty, alloca)
                let args: Vec[i64] = Vec.new()
                args.push(val)
                wl_build_call(self.builder, dft.unwrap() as i64, dfv.unwrap() as i64, vec_data_i64(&args), 1)
        i = i - 1
    self.scope_local_count = watermark

fn Codegen.build_fn_type_from_ast(self: Codegen, fn_type_node: i32) -> i64:
    // NK_TYPE_FN: d0=extra_start, d1=param_count, d2=return_type(node)
    let extra_start = self.pool.get_data0(fn_type_node)
    let param_count = self.pool.get_data1(fn_type_node)
    let ret_node = self.pool.get_data2(fn_type_node)

    let ptr_ty = wl_ptr_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(ptr_ty)  // context pointer (closure convention)
    for i in 0..param_count:
        let p_node = self.pool.get_extra(extra_start + i)
        param_types.push(self.resolve_type(p_node))
    let ret_ty = self.resolve_type(ret_node)
    wl_function_type(ret_ty, vec_data_i64(&param_types), param_count + 1, 0)

// ── gen_module: multi-pass entry point ────────────────────────────

fn Codegen.gen_module(self: Codegen, pool: AstPool) -> i32:
    if self.debug_pool_flow_enabled():
        with_eprintln("[llvm-cg] gen_module input.decls=" ++ int_to_string(pool.decl_count()) ++
            " input.nodes=" ++ int_to_string(pool.node_count()))
    self.pool = pool
    if self.debug_pool_flow_enabled():
        with_eprintln("[llvm-cg] gen_module self.decls=" ++ int_to_string(self.pool.decl_count()) ++
            " self.nodes=" ++ int_to_string(self.pool.node_count()))

    self.debug_init_module()

    // Declare built-in str type before user types
    self.declare_builtin_str_type()

    // Pass 0a: predeclare all struct/enum names so forward references resolve.
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind != NK_TYPE_DECL:
            continue
        let name_sym = self.pool.get_data0(decl)
        let name_str = self.intern.resolve(name_sym)
        if name_sym == 0 or name_str.len() == 0:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind == TDK_STRUCT or sub_kind == TDK_DISTINCT:
            if self.type_decl_tp_count(decl) > 0:
                self.generic_structs.insert(name_sym, decl)
            else:
                self.predeclare_struct_type(name_sym)
            continue
        if sub_kind == TDK_ENUM:
            if self.type_decl_tp_count(decl) > 0:
                continue
            self.predeclare_enum_type(name_sym)

        if sub_kind == TDK_DISC_ENUM:
            continue
        if sub_kind == TDK_OPAQUE:
            self.predeclare_struct_type(name_sym)
            continue

    // Pass 0b: define struct/enum bodies and type aliases.
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind != NK_TYPE_DECL:
            continue
        let name_sym = self.pool.get_data0(decl)
        let name_str = self.intern.resolve(name_sym)
        if name_sym == 0 or name_str.len() == 0:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind == TDK_STRUCT:
            if self.type_decl_tp_count(decl) == 0:
                self.declare_struct_type(name_sym, decl)
            continue
        if sub_kind == TDK_ENUM:
            if self.type_decl_tp_count(decl) > 0:
                continue
            self.declare_enum_type(name_sym, decl)
            continue
        if sub_kind == TDK_DISC_ENUM:
            self.declare_disc_enum_type(name_sym, decl)
            continue
        if sub_kind == TDK_OPAQUE:
            // Opaque type: predeclared in pass 0a, no body set (stays opaque)
            continue
        if sub_kind == TDK_UNION:
            self.declare_union_type(name_sym, decl)
            continue
        if sub_kind == TDK_DISTINCT:
            // Distinct type: single-field struct wrapping the inner type
            let dt_extra_start = self.pool.get_data1(decl)
            let dt_inner_node = self.pool.get_extra(dt_extra_start)
            let dt_inner_ty = self.resolve_type(dt_inner_node)
            if not self.struct_type_map.get(name_sym).is_some():
                self.predeclare_struct_type(name_sym)
            let dt_idx = self.struct_type_map.get(name_sym).unwrap()
            let dt_st_type = self.struct_llvm_types.get(dt_idx as i64)
            self.struct_field_starts.set_i32(dt_idx as i64, self.struct_field_names.len() as i32)
            self.struct_field_counts.set_i32(dt_idx as i64, 1)
            let dt_val_sym = self.intern.intern("value")
            self.struct_field_names.push(dt_val_sym)
            self.struct_field_types.push(dt_inner_ty)
            self.struct_field_type_nodes.push(dt_inner_node)
            self.struct_field_defaults.push(0)
            self.struct_llvm_field_indices.push(0)
            let dt_ft: Vec[i64] = Vec.new()
            dt_ft.push(dt_inner_ty)
            wl_struct_set_body(dt_st_type, vec_data_i64(&dt_ft), 1, 0)
            continue
        if sub_kind == TDK_ALIAS:
            let extra_start = self.pool.get_data1(decl)
            let aliased_node = self.pool.get_extra(extra_start)
            let resolved = self.resolve_type(aliased_node)
            self.type_aliases.insert(name_sym, resolved)

    if self.had_error != 0:
        return 1

    // Pass 0.5: collect trait declarations
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NK_TRAIT_DECL:
            self.collect_trait_info(decl)

    // Pass 0.6: process top-level let declarations as module constants
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NK_LET_DECL:
            self.current_decl_source_file = self.decl_source_path(i)
            self.gen_module_constant(decl)

    // Pass 1: declare all functions and externs (forward declarations)
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NK_EXTERN_FN:
            self.declare_extern_fn(decl)
            continue
        if kind == NK_EXTERN_VAR:
            self.declare_extern_var(decl)
            continue
        if kind != NK_FN_DECL:
            continue
        let name_sym = self.pool.get_data0(decl)
        if name_sym == 0:
            continue
        let flags = self.pool.get_data2(decl)
        let meta = self.pool.find_fn_meta(decl)
        // Skip generic functions (store for monomorphization)
        if meta >= 0:
            let tp_count = self.pool.fn_meta_tp_count(meta)
            if tp_count > 0:
                self.generic_fns.insert(name_sym, decl)
            else if (flags / FN_FLAG_ASYNC) % 2 == 1:
                self.declare_async_function(decl)
            else:
                self.declare_function(decl)

    // Pass 1.3: synthesize missing impl methods from trait defaults.
    self.generate_default_trait_methods()

    // Pass 1.35: generate derive(Clone) methods.
    self.generate_clone_derives()

    // Pass 1.25: synthesize trait vtables after all method declarations exist.
    self.generate_trait_vtables()

    // Pass 1.5: detect drop functions
    self.detect_drop_functions()

    // Pass 2: generate function bodies
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NK_FN_DECL:
            let name_sym = self.pool.get_data0(decl)
            if name_sym == 0:
                continue
            let flags = self.pool.get_data2(decl)
            let meta = self.pool.find_fn_meta(decl)
            if meta >= 0:
                let tp_count = self.pool.fn_meta_tp_count(meta)
                if tp_count == 0:
                    self.current_decl_source_file = self.decl_source_path(i)
                    self.gen_function_dispatch(decl)

    if self.had_error != 0:
        return 1

    // Wrap main for exit
    self.wrap_main_for_exit()

    // Finalize debug info before verification
    self.debug_finalize_module()

    // Verify
    self.verify()

// ── Collect trait info ────────────────────────────────────────────

fn Codegen.collect_trait_info(self: Codegen, trait_node: i32):
    let name_sym = self.pool.get_data0(trait_node)
    let extra_start = self.pool.get_data1(trait_node)
    if self.trait_map.get(name_sym).is_some():
        return

    var pos = extra_start
    let tp_count = self.pool.get_extra(pos)
    let tp_start_ast = self.pool.get_extra(pos + 1)
    pos = pos + 2
    let tp_flat_start = self.trait_tp_flat_syms.len() as i32
    self.trait_tp_starts.insert(name_sym, tp_flat_start)
    self.trait_tp_counts.insert(name_sym, tp_count)
    var tp_pos = tp_start_ast
    for tpi in 0..tp_count:
        self.trait_tp_flat_syms.push(self.pool.get_extra(tp_pos))
        let bc = self.pool.get_extra(tp_pos + 1)
        tp_pos = tp_pos + 2 + bc
    let assoc_count = self.pool.get_extra(pos)
    pos = pos + 1
    for ai in 0..assoc_count:
        let _assoc_name = self.pool.get_extra(pos)
        pos = pos + 1
        let bound_count = self.pool.get_extra(pos)
        pos = pos + 1 + bound_count
        pos = pos + 1 // default type

    let method_count = self.pool.get_extra(pos)
    pos = pos + 1

    let method_start = self.trait_method_names.len() as i32
    let ptr_ty = wl_ptr_type(self.context)
    let vtable_fields: Vec[i64] = Vec.new()

    for mi in 0..method_count:
        let method_sym = self.pool.get_extra(pos)
        pos = pos + 1
        let _method_flags = self.pool.get_extra(pos)
        pos = pos + 1
        let method_param_start = self.pool.get_extra(pos)
        pos = pos + 1
        let method_param_count = self.pool.get_extra(pos)
        pos = pos + 1
        let method_ret_node = self.pool.get_extra(pos)
        pos = pos + 1
        let method_default_body = self.pool.get_extra(pos)
        pos = pos + 1

        self.trait_method_names.push(method_sym)
        self.trait_method_param_starts.push(method_param_start)
        if method_ret_node != 0:
            var trait_ret_ty = self.resolve_type(method_ret_node)
            if trait_ret_ty == 0:
                trait_ret_ty = wl_i32_type(self.context)
            self.trait_method_ret_types.push(trait_ret_ty)
        else:
            self.trait_method_ret_types.push(wl_void_type(self.context))
        self.trait_method_ret_nodes.push(method_ret_node)
        self.trait_method_param_counts.push(method_param_count)
        self.trait_method_default_bodies.push(method_default_body)
        vtable_fields.push(ptr_ty)

    let vtable_ty = wl_struct_type(self.context, vec_data_i64(&vtable_fields), method_count, 0)
    let trait_idx = self.trait_vtable_types.len() as i32
    self.trait_vtable_types.push(vtable_ty)
    self.trait_method_starts.push(method_start)
    self.trait_method_counts.push(method_count)
    self.trait_map.insert(name_sym, trait_idx)
    self.trait_idx_syms.push(name_sym)
    self.trait_decl_nodes.insert(name_sym, trait_node)

fn Codegen.find_trait_method_offset(self: Codegen, trait_idx: i32, method_sym: i32) -> i32:
    let start = self.trait_method_starts.get(trait_idx as i64)
    let count = self.trait_method_counts.get(trait_idx as i64)
    for i in 0..count:
        if self.trait_method_names.get((start + i) as i64) == method_sym:
            return i
    0 - 1

fn Codegen.find_decl_index(self: Codegen, node: i32) -> i32:
    for i in 0..self.pool.decl_count():
        if self.pool.get_decl(i) == node:
            return i
    0 - 1

fn Codegen.lookup_impl_method_symbol_by_slot(self: Codegen, impl_node: i32, slot: i32) -> i32:
    if slot < 0:
        return 0
    let impl_extra = self.pool.get_data1(impl_node)
    if impl_extra < 0 or impl_extra >= self.pool.extra_len():
        return 0
    // Skip past associated type entries: [assoc_count, [name, type]*, method_count]
    let assoc_count = self.pool.get_extra(impl_extra)
    let method_count = self.pool.get_extra(impl_extra + 1 + assoc_count * 2)
    if method_count <= 0 or slot >= method_count:
        return 0
    let decl_idx = self.find_decl_index(impl_node)
    if decl_idx <= 0:
        return 0
    let rev_syms: Vec[i32] = Vec.new()
    var di = decl_idx - 1
    while di >= 0 and rev_syms.len() as i32 < method_count:
        let decl = self.pool.get_decl(di)
        if self.pool.kind(decl) == NK_FN_DECL:
            rev_syms.push(self.pool.get_data0(decl))
        di = di - 1
    if rev_syms.len() as i32 != method_count:
        return 0
    let rev_idx = method_count - 1 - slot
    if rev_idx < 0 or rev_idx >= rev_syms.len() as i32:
        return 0
    rev_syms.get(rev_idx as i64)

fn Codegen.create_dyn_wrapper(self: Codegen, impl_type_sym: i32, method_sym: i32, method_fn: i64, method_ft: i64) -> i64:
    let type_name = self.intern.resolve(impl_type_sym)
    let method_name = self.intern.resolve(method_sym)
    let wrapper_name = "__dynwrap_" ++ type_name ++ "_" ++ method_name
    let existing = wl_get_named_function(self.llmod, wrapper_name)
    if existing != 0:
        return existing

    let ptr_ty = wl_ptr_type(self.context)
    let orig_param_count = wl_count_param_types(method_ft)
    if orig_param_count <= 0:
        return method_fn
    let wrapper_param_types: Vec[i64] = Vec.new()
    wrapper_param_types.push(ptr_ty)
    var pi = 1
    while pi < orig_param_count:
        let pval = wl_get_param(method_fn, pi)
        wrapper_param_types.push(wl_type_of(pval))
        pi = pi + 1
    let ret_ty = wl_get_return_type(method_ft)
    let wrapper_ft = wl_function_type(ret_ty, vec_data_i64(&wrapper_param_types), orig_param_count, 0)
    let wrapper_fn = wl_add_function(self.llmod, wrapper_name, wrapper_ft)
    wl_set_linkage(wrapper_fn, wl_internal_linkage())

    let saved_fn = self.current_function
    let saved_ret = self.current_ret_type
    let saved_bb = wl_get_insert_block(self.builder)
    self.current_function = wrapper_fn
    self.current_ret_type = ret_ty

    let entry = wl_append_bb(self.context, wrapper_fn, "entry")
    wl_position_at_end(self.builder, entry)

    let data_ptr = wl_get_param(wrapper_fn, 0)
    let self_param_ty = if orig_param_count > 0: wl_type_of(wl_get_param(method_fn, 0)) else: ptr_ty
    let self_arg = if wl_get_type_kind(self_param_ty) == wl_pointer_type_kind():
        wl_build_bitcast(self.builder, data_ptr, self_param_ty)
    else:
        wl_build_load(self.builder, self_param_ty, data_ptr)

    let call_args: Vec[i64] = Vec.new()
    call_args.push(self_arg)
    pi = 1
    while pi < orig_param_count:
        let p = wl_get_param(wrapper_fn, pi)
        let target_ty = wl_type_of(wl_get_param(method_fn, pi))
        call_args.push(self.coerce_value_to_type(p, target_ty))
        pi = pi + 1

    let call_val = wl_build_call(self.builder, method_ft, method_fn, vec_data_i64(&call_args), orig_param_count)
    if ret_ty == wl_void_type(self.context):
        let _ = wl_build_ret_void(self.builder)
    else:
        let _ = wl_build_ret(self.builder, call_val)

    self.current_function = saved_fn
    self.current_ret_type = saved_ret
    if saved_bb != 0:
        wl_position_at_end(self.builder, saved_bb)

    wrapper_fn

fn Codegen.resolve_trait_method_type_for_impl(self: Codegen, type_node: i32, impl_type_sym: i32) -> i64:
    return self.resolve_trait_method_type_for_impl_with_trait(type_node, impl_type_sym, 0, 0)

fn Codegen.resolve_trait_method_type_for_impl_with_trait(self: Codegen, type_node: i32, impl_type_sym: i32, trait_sym: i32, impl_node: i32) -> i64:
    if type_node == 0:
        return 0
    var concrete_ty = 0
    let st = self.struct_type_map.get(impl_type_sym)
    if st.is_some():
        concrete_ty = self.struct_llvm_types.get(st.unwrap() as i64)
    else:
        let et = self.enum_type_map.get(impl_type_sym)
        if et.is_some():
            concrete_ty = self.enum_llvm_types.get(et.unwrap() as i64)
    if concrete_ty == 0:
        return self.resolve_type(type_node)

    let saved_syms = self.type_binding_syms
    let saved_tys = self.type_binding_types
    let saved_len = self.type_bindings_len
    let fresh_syms: Vec[i32] = Vec.new()
    let fresh_tys: Vec[i64] = Vec.new()
    self.type_binding_syms = fresh_syms
    self.type_binding_types = fresh_tys
    self.type_bindings_len = 0
    let self_sym = self.intern.intern("Self")
    var found_self = false
    for i in 0..saved_len:
        let sym = saved_syms.get(i as i64)
        var ty = saved_tys.get(i as i64)
        if sym == self_sym:
            ty = concrete_ty
            found_self = true
        self.type_binding_syms.push(sym)
        self.type_binding_types.push(ty)
        self.type_bindings_len = self.type_bindings_len + 1
    if not found_self:
        self.type_binding_syms.push(self_sym)
        self.type_binding_types.push(concrete_ty)
        self.type_bindings_len = self.type_bindings_len + 1

    // Bind trait type params from impl trait type args
    if trait_sym != 0 and impl_node != 0:
        let tp_count_opt = self.trait_tp_counts.get(trait_sym)
        if tp_count_opt.is_some():
            let tp_count = tp_count_opt.unwrap()
            let tp_start = self.trait_tp_starts.get(trait_sym).unwrap()
            let tta_idx = self.pool.find_impl_trait_type_args(impl_node)
            if tta_idx >= 0:
                let arg_start = self.pool.impl_trait_type_args.get((tta_idx + 1) as i64)
                let arg_count = self.pool.impl_trait_type_args.get((tta_idx + 2) as i64)
                var ti = 0
                while ti < tp_count and ti < arg_count:
                    let tp_sym = self.trait_tp_flat_syms.get((tp_start + ti) as i64)
                    let arg_node = self.pool.get_extra(arg_start + ti)
                    let arg_ty = self.resolve_type(arg_node)
                    if arg_ty != 0:
                        self.type_binding_syms.push(tp_sym)
                        self.type_binding_types.push(arg_ty)
                        self.type_bindings_len = self.type_bindings_len + 1
                    ti = ti + 1

    let resolved = self.resolve_type(type_node)
    self.type_binding_syms = saved_syms
    self.type_binding_types = saved_tys
    self.type_bindings_len = saved_len
    resolved

fn Codegen.generate_default_trait_method_for_impl_ext(self: Codegen, impl_type_sym: i32, method_idx: i32, trait_sym: i32, impl_node: i32):
    // Set up trait type param bindings before generating the method
    let saved_syms = self.type_binding_syms
    let saved_tys = self.type_binding_types
    let saved_len = self.type_bindings_len

    if trait_sym != 0 and impl_node != 0:
        let tp_count_opt = self.trait_tp_counts.get(trait_sym)
        if tp_count_opt.is_some():
            let tp_count = tp_count_opt.unwrap()
            let tp_start = self.trait_tp_starts.get(trait_sym).unwrap()
            // Try to bind from explicit trait type args (impl Trait[i32] for Type)
            let tta_idx = self.pool.find_impl_trait_type_args(impl_node)
            if tta_idx >= 0:
                let arg_start = self.pool.impl_trait_type_args.get((tta_idx + 1) as i64)
                let arg_count = self.pool.impl_trait_type_args.get((tta_idx + 2) as i64)
                var ti = 0
                while ti < tp_count and ti < arg_count:
                    let tp_sym = self.trait_tp_flat_syms.get((tp_start + ti) as i64)
                    let arg_node = self.pool.get_extra(arg_start + ti)
                    let arg_ty = self.resolve_type(arg_node)
                    if arg_ty != 0:
                        self.type_binding_syms.push(tp_sym)
                        self.type_binding_types.push(arg_ty)
                        self.type_bindings_len = self.type_bindings_len + 1
                    ti = ti + 1

    self.generate_default_trait_method_for_impl(impl_type_sym, method_idx)

    self.type_binding_syms = saved_syms
    self.type_binding_types = saved_tys
    self.type_bindings_len = saved_len

fn Codegen.generate_default_trait_method_for_impl(self: Codegen, impl_type_sym: i32, method_idx: i32):
    let body_node = self.trait_method_default_bodies.get(method_idx as i64)
    if body_node == 0:
        return

    let method_sym = self.trait_method_names.get(method_idx as i64)
    let method_name = self.intern.resolve(method_sym)
    let type_name = self.intern.resolve(impl_type_sym)
    let mangled = type_name ++ "." ++ method_name
    let fn_sym = self.intern.intern(mangled)
    if self.fn_values.get(fn_sym).is_some():
        return

    let param_start = self.trait_method_param_starts.get(method_idx as i64)
    let param_count = self.trait_method_param_counts.get(method_idx as i64)
    let ret_node = self.trait_method_ret_nodes.get(method_idx as i64)
    if param_start < 0:
        return
    if param_count < 0 or param_count > 64:
        return

    let param_types: Vec[i64] = Vec.new()
    var has_ref_param = false
    for pi in 0..param_count:
        let type_slot = param_start + pi * FN_PARAM_STRIDE + 1
        if type_slot < 0 or type_slot >= self.pool.extra_len():
            return
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if pi == 0 and p_type_node != 0 and self.pool.kind(p_type_node) == NK_TYPE_NAMED:
            let p_sym = self.pool.get_data0(p_type_node)
            if p_sym == impl_type_sym or self.intern.resolve(p_sym) == "Self":
                let p_ty = wl_ptr_type(self.context)
                has_ref_param = true
                param_types.push(p_ty)
                continue
        var p_ty = self.resolve_trait_method_type_for_impl(p_type_node, impl_type_sym)
        if p_ty == 0:
            p_ty = wl_i32_type(self.context)
        param_types.push(p_ty)

    let ret_ty = if ret_node != 0:
        self.resolve_trait_method_type_for_impl(ret_node, impl_type_sym)
    else:
        wl_void_type(self.context)
    let final_ret_ty = if ret_ty != 0: ret_ty else: wl_void_type(self.context)
    let fn_ty = wl_function_type(final_ret_ty, vec_data_i64(&param_types), param_count, 0)
    if fn_ty == 0 or wl_get_type_kind(fn_ty) != wl_function_type_kind():
        return
    let function = wl_add_function(self.llmod, mangled, fn_ty)
    self.apply_noalias_param_attrs(function, param_start, param_count)
    if function == 0 or wl_get_value_kind(function) != wl_function_value_kind():
        return
    self.fn_values.insert(fn_sym, function)
    self.fn_fn_types.insert(fn_sym, fn_ty)
    if has_ref_param:
        self.record_ref_param(fn_sym, 0, param_count)

    let saved_fn = self.current_function
    let saved_ret = self.current_ret_type
    let saved_owner = self.current_method_owner_sym
    let saved_allocas = self.local_allocas
    let saved_types = self.local_types
    let saved_muts = self.local_muts
    let saved_fn_sigs = self.local_fn_sigs
    let saved_pointees = self.local_pointee_structs
    let saved_task_locals = self.task_locals
    let saved_trait_locals = self.trait_locals
    let saved_trait_concrete = self.trait_local_concrete_types
    let saved_scope_syms = self.scope_local_syms
    let saved_scope_allocas = self.scope_local_allocas
    let saved_scope_types = self.scope_local_types
    let saved_scope_count = self.scope_local_count
    let saved_defer = self.defer_stack
    let saved_errdefer = self.errdefer_stack
    let saved_enum_local_types = self.enum_local_types
    let saved_sema_local_types = self.local_sema_types
    let saved_expected = self.expected_type
    let saved_expected_node = self.expected_type_node
    let saved_result_err = self.current_result_err_symbol
    let saved_returns_result = self.current_fn_returns_result
    let saved_saw_return = self.current_fn_saw_explicit_return
    let saved_tail_bb = self.tailrec_body_bb
    let saved_tail_sym = self.tailrec_fn_sym
    let saved_tail_allocas = self.tailrec_param_allocas
    let saved_loops = self.capture_loop_state()
    let saved_bb = wl_get_insert_block(self.builder)

    self.current_function = function
    self.current_ret_type = final_ret_ty
    self.current_method_owner_sym = impl_type_sym
    let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
    let fresh_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
    let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
    let fresh_local_pointees: HashMap[i32, i32] = HashMap.new()
    let fresh_task_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_concrete: HashMap[i32, i32] = HashMap.new()
    let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
    let fresh_scope_syms: Vec[i32] = Vec.new()
    let fresh_scope_allocas: Vec[i64] = Vec.new()
    let fresh_scope_types: Vec[i64] = Vec.new()
    let fresh_defer_stack: Vec[i32] = Vec.new()
    let fresh_errdefer_stack: Vec[i32] = Vec.new()
    let fresh_tail_allocas: Vec[i64] = Vec.new()
    self.local_allocas = fresh_local_allocas
    self.local_types = fresh_local_types
    self.local_muts = fresh_local_muts
    self.local_fn_sigs = fresh_local_fn_sigs
    self.local_pointee_structs = fresh_local_pointees
    self.task_locals = fresh_task_locals
    self.trait_locals = fresh_trait_locals
    self.trait_local_concrete_types = fresh_trait_concrete
    self.enum_local_types = fresh_enum_local_types
    self.scope_local_syms = fresh_scope_syms
    self.scope_local_allocas = fresh_scope_allocas
    self.scope_local_types = fresh_scope_types
    self.scope_local_count = 0
    self.defer_stack = fresh_defer_stack
    self.errdefer_stack = fresh_errdefer_stack
    self.expected_type = final_ret_ty
    self.expected_type_node = 0
    self.current_result_err_symbol = 0
    self.current_fn_returns_result = false
    self.current_fn_saw_explicit_return = false
    self.tailrec_body_bb = 0
    self.tailrec_fn_sym = 0
    self.tailrec_param_allocas = fresh_tail_allocas
    self.reset_loop_state()

    let entry = wl_append_bb(self.context, function, "entry")
    wl_position_at_end(self.builder, entry)
    var lowered_param_count = param_count
    let actual_param_count = wl_count_params(function)
    if actual_param_count >= 0 and actual_param_count < lowered_param_count:
        lowered_param_count = actual_param_count
    if lowered_param_count < 0:
        lowered_param_count = 0
    var pi = 0
    while pi < lowered_param_count:
        let name_slot = param_start + pi * FN_PARAM_STRIDE
        let type_slot = param_start + pi * FN_PARAM_STRIDE + 1
        if name_slot < 0 or type_slot < 0 or type_slot >= self.pool.extra_len():
            break
        let p_name = self.pool.fn_param_name(param_start, pi)
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        let p_val = wl_get_param(function, pi)
        let p_ty = wl_type_of(p_val)
        let p_alloca = wl_build_alloca(self.builder, p_ty)
        wl_build_store(self.builder, p_val, p_alloca)
        self.record_local(p_name, p_alloca, p_ty, 1)

        if pi == 0 and wl_get_type_kind(p_ty) == wl_pointer_type_kind():
            self.record_local_pointee_struct(p_name, impl_type_sym)
        if pi == 0 and p_type_node != 0 and self.pool.kind(p_type_node) == NK_TYPE_NAMED:
            let psym = self.pool.get_data0(p_type_node)
            if self.intern.resolve(psym) == "Self" and wl_get_type_kind(p_ty) == wl_pointer_type_kind():
                self.record_local_pointee_struct(p_name, impl_type_sym)
        pi = pi + 1

    // ── MIR-based default trait method body compilation ──
    let saved_mir_locals = self.mir_local_ptrs
    let saved_mir_local_types = self.mir_local_types
    let saved_mir_bbs = self.mir_bb_values
    let saved_mir_unreachable = self.mir_default_unreachable_bbs
    let dtm_fresh_mir_locals: HashMap[i32, i64] = HashMap.new()
    let dtm_fresh_mir_types: HashMap[i32, i64] = HashMap.new()
    let dtm_fresh_mir_bbs: Vec[i64] = Vec.new()
    let dtm_fresh_mir_unr: Vec[i64] = Vec.new()
    self.mir_local_ptrs = dtm_fresh_mir_locals
    self.mir_local_types = dtm_fresh_mir_types
    self.mir_bb_values = dtm_fresh_mir_bbs
    self.mir_default_unreachable_bbs = dtm_fresh_mir_unr

    var dtm_builder = MirBuilder.init(self.sema, self.pool, self.intern, fn_sym)
    // Set return type
    let dtm_ret_sema = self.sema_type_of_node(body_node)
    if dtm_ret_sema != 0 and dtm_ret_sema != self.sema.ty_void:
        dtm_builder.body.local_type_ids.set_i32(0, dtm_ret_sema)
    else:
        dtm_builder.body.local_type_ids.set_i32(0, self.sema.ty_i32)

    dtm_builder.push_scope()

    // Register params as MIR locals
    for dtm_pi in 0..param_count:
        let dtm_p_name = self.pool.fn_param_name(param_start, dtm_pi)
        let dtm_p_type_node = self.pool.fn_param_type(param_start, dtm_pi)
        var dtm_p_sema_ty = self.sema.ty_i32
        if dtm_p_type_node > 0:
            if self.sema.typed_expr_types.contains(dtm_p_type_node):
                let dtm_tt = self.sema.typed_expr_types.get(dtm_p_type_node).unwrap()
                if dtm_tt > 0:
                    dtm_p_sema_ty = dtm_tt
            if dtm_p_sema_ty == self.sema.ty_i32:
                let dtm_pk = self.pool.kind(dtm_p_type_node)
                if dtm_pk == NK_TYPE_NAMED or dtm_pk == NK_IDENT:
                    let dtm_type_sym = self.pool.get_data0(dtm_p_type_node)
                    let dtm_prim = self.sema.primitive_type_by_sym(dtm_type_sym)
                    if dtm_prim != 0:
                        dtm_p_sema_ty = dtm_prim
                    else if self.sema.named_types.contains(dtm_type_sym):
                        dtm_p_sema_ty = self.sema.named_types.get(dtm_type_sym).unwrap()
        let dtm_p_local = dtm_builder.body.new_local(dtm_p_sema_ty, 1, dtm_p_name, 1)
        dtm_builder.bind_local(dtm_p_name, dtm_p_local)

    dtm_builder.expected_type = dtm_builder.body.local_type_ids.get(0)

    // Lower body to MIR
    let dtm_result = dtm_builder.lower_expr(body_node)
    let dtm_ret_place = dtm_builder.place_for_local(0)
    dtm_builder.assign_operand_to_place(dtm_ret_place, dtm_result, self.pool.get_end(body_node))
    dtm_builder.pop_scope_inline()
    dtm_builder.terminate(TK_RETURN, 0, 0, 0, 0)
    let dtm_body = dtm_builder.body

    // Set up return alloca (MIR local 0)
    let dtm_ret_alloca = self.create_entry_alloca(final_ret_ty)
    self.mir_local_ptrs.insert(0, dtm_ret_alloca)
    self.mir_local_types.insert(0, final_ret_ty)

    // Map param MIR locals to existing LLVM allocas
    for dtm_mi in 0..param_count:
        let dtm_m_name = self.pool.fn_param_name(param_start, dtm_mi)
        let dtm_m_local_id = dtm_mi + 1
        let dtm_m_alloca_opt = self.local_allocas.get(dtm_m_name)
        if dtm_m_alloca_opt.is_some():
            self.mir_local_ptrs.insert(dtm_m_local_id, dtm_m_alloca_opt.unwrap())
            let dtm_m_ty_opt = self.local_types.get(dtm_m_name)
            if dtm_m_ty_opt.is_some():
                self.mir_local_types.insert(dtm_m_local_id, dtm_m_ty_opt.unwrap())

    // Pre-populate globals
    for dtm_gli in 0..dtm_body.local_names.len() as i32:
        let dtm_gl_name = dtm_body.local_names.get(dtm_gli as i64)
        if dtm_gl_name != 0:
            let dtm_gl_mc = self.module_constants.get(dtm_gl_name)
            if dtm_gl_mc.is_some():
                self.mir_local_ptrs.insert(dtm_gli, dtm_gl_mc.unwrap() as i64)

    // Create LLVM basic blocks
    for dtm_bb in 0..dtm_body.block_count():
        let dtm_bb_name = "mir.bb" ++ int_to_string(dtm_bb)
        let dtm_llbb = wl_append_bb(self.context, function, dtm_bb_name)
        self.mir_bb_values.push(dtm_llbb)

    // Branch from entry to first MIR BB
    if self.mir_bb_values.len() as i32 > 0:
        wl_build_br(self.builder, self.mir_bb_values.get(0))
    else:
        let _ = wl_build_ret(self.builder, wl_const_int(final_ret_ty, 0, 0))

    // Emit MIR statements and terminators
    for dtm_bb in 0..dtm_body.block_count():
        if dtm_bb < 0 or dtm_bb >= self.mir_bb_values.len() as i32:
            continue
        let dtm_llbb = self.mir_bb_values.get(dtm_bb as i64)
        wl_position_at_end(self.builder, dtm_llbb)
        let dtm_stmt_start = dtm_body.bb_stmt_starts.get(dtm_bb as i64)
        let dtm_stmt_count = dtm_body.bb_stmt_counts.get(dtm_bb as i64)
        for dtm_si in 0..dtm_stmt_count:
            let dtm_stmt_id = dtm_stmt_start + dtm_si
            if not self.mir_emit_stmt(dtm_body, dtm_stmt_id):
                if wl_get_bb_terminator(dtm_llbb) == 0:
                    wl_build_unreachable(self.builder)
        if wl_get_bb_terminator(dtm_llbb) == 0:
            if not self.mir_emit_term(dtm_body, dtm_bb):
                if wl_get_bb_terminator(dtm_llbb) == 0:
                    if final_ret_ty == wl_void_type(self.context):
                        let _ = wl_build_ret_void(self.builder)
                    else:
                        let _ = wl_build_ret(self.builder, wl_const_int(final_ret_ty, 0, 0))

    // Restore MIR state
    self.mir_local_ptrs = saved_mir_locals
    self.mir_local_types = saved_mir_local_types
    self.mir_bb_values = saved_mir_bbs
    self.mir_default_unreachable_bbs = saved_mir_unreachable

    self.current_function = saved_fn
    self.current_ret_type = saved_ret
    self.current_method_owner_sym = saved_owner
    self.local_allocas = saved_allocas
    self.local_types = saved_types
    self.local_muts = saved_muts
    self.local_fn_sigs = saved_fn_sigs
    self.local_pointee_structs = saved_pointees
    self.task_locals = saved_task_locals
    self.trait_locals = saved_trait_locals
    self.trait_local_concrete_types = saved_trait_concrete
    self.enum_local_types = saved_enum_local_types
    self.local_sema_types = saved_sema_local_types
    self.scope_local_syms = saved_scope_syms
    self.scope_local_allocas = saved_scope_allocas
    self.scope_local_types = saved_scope_types
    self.scope_local_count = saved_scope_count
    self.defer_stack = saved_defer
    self.errdefer_stack = saved_errdefer
    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    self.current_result_err_symbol = saved_result_err
    self.current_fn_returns_result = saved_returns_result
    self.current_fn_saw_explicit_return = saved_saw_return
    self.tailrec_body_bb = saved_tail_bb
    self.tailrec_fn_sym = saved_tail_sym
    self.tailrec_param_allocas = saved_tail_allocas
    self.restore_loop_state(saved_loops)
    if saved_bb != 0:
        wl_position_at_end(self.builder, saved_bb)

fn Codegen.generate_default_trait_methods_for_impl(self: Codegen, impl_node: i32):
    let impl_type_sym = self.pool.get_data0(impl_node)
    let trait_sym = self.pool.get_data2(impl_node)
    if trait_sym == 0:
        return
    let trait_idx_opt = self.trait_map.get(trait_sym)
    if not trait_idx_opt.is_some():
        return
    let trait_idx = trait_idx_opt.unwrap()
    let method_start = self.trait_method_starts.get(trait_idx as i64)
    let method_count = self.trait_method_counts.get(trait_idx as i64)
    for mi in 0..method_count:
        self.generate_default_trait_method_for_impl_ext(impl_type_sym, method_start + mi, trait_sym, impl_node)

fn Codegen.generate_default_trait_methods(self: Codegen):
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NK_IMPL_DECL:
            self.generate_default_trait_methods_for_impl(decl)

fn Codegen.generate_trait_vtable_for_impl(self: Codegen, impl_node: i32):
    let impl_type_sym = self.pool.get_data0(impl_node)
    let trait_sym = self.pool.get_data2(impl_node)
    if trait_sym == 0:
        return

    let trait_idx_opt = self.trait_map.get(trait_sym)
    if not trait_idx_opt.is_some():
        return
    let trait_idx = trait_idx_opt.unwrap()
    let method_start = self.trait_method_starts.get(trait_idx as i64)
    let method_count = self.trait_method_counts.get(trait_idx as i64)
    let vtable_ty = self.trait_vtable_types.get(trait_idx as i64)

    let entries: Vec[i64] = Vec.new()
    for mi in 0..method_count:
        let method_sym = self.trait_method_names.get((method_start + mi) as i64)
        let method_name = self.intern.resolve(method_sym)
        let type_name = self.intern.resolve(impl_type_sym)
        let mangled = type_name ++ "." ++ method_name
        var impl_fn_sym = self.intern.intern(mangled)
        var fv = self.fn_values.get(impl_fn_sym)
        var ft = self.fn_fn_types.get(impl_fn_sym)
        if not fv.is_some() or not ft.is_some():
            let slot_sym = self.lookup_impl_method_symbol_by_slot(impl_node, mi)
            if slot_sym != 0:
                impl_fn_sym = slot_sym
                fv = self.fn_values.get(impl_fn_sym)
                ft = self.fn_fn_types.get(impl_fn_sym)
        if fv.is_some() and ft.is_some():
            let wrapper = self.create_dyn_wrapper(impl_type_sym, method_sym, fv.unwrap() as i64, ft.unwrap() as i64)
            entries.push(wrapper)
        else:
            entries.push(wl_const_null(wl_ptr_type(self.context)))

    let key = codegen_hash_type_trait_key(impl_type_sym, trait_sym)
    if self.vtable_globals.get(key).is_some():
        return

    let trait_name = self.intern.resolve(trait_sym)
    let type_name = self.intern.resolve(impl_type_sym)
    let global_name = "__vtable_" ++ type_name ++ "_" ++ trait_name
    let vg = wl_add_global(self.llmod, vtable_ty, global_name)
    let vconst = wl_const_named_struct(vtable_ty, vec_data_i64(&entries), method_count)
    wl_set_initializer(vg, vconst)
    wl_set_global_constant(vg, 1)
    wl_set_linkage(vg, wl_internal_linkage())
    self.vtable_globals.insert(key, vg)

fn Codegen.generate_trait_vtables(self: Codegen):
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NK_IMPL_DECL:
            self.generate_trait_vtable_for_impl(decl)

fn CONST_EVAL_FAIL -> i64: -9223372036854775807

type ConstStringEval = {
    ok: bool,
    text: str,
}

fn const_string_eval_fail -> ConstStringEval:
    ConstStringEval {
        ok: false,
        text: "",
    }

fn const_string_eval_ok(text: str) -> ConstStringEval:
    ConstStringEval {
        ok: true,
        text,
    }

fn Codegen.decl_source_path(self: Codegen, decl_index: i32) -> str:
    if decl_index >= 0 and decl_index < self.decl_source_paths.len() as i32:
        let path = self.decl_source_paths.get(decl_index as i64)
        if path.len() > 0:
            return path
    if self.current_decl_source_file.len() > 0 and self.current_decl_source_file != "<unknown>":
        return self.current_decl_source_file
    self.source_file

fn Codegen.find_module_let_decl_index(self: Codegen, sym: i32) -> i32:
    for di in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(di)
        if self.pool.kind(decl) != NK_LET_DECL:
            continue
        if self.pool.get_data0(decl) == sym:
            return di
    0 - 1

fn codegen_dirname(path: str) -> str:
    var last_slash = 0 - 1
    for di in 0..path.len() as i32:
        if path.byte_at(di as i64) == 47:
            last_slash = di
    if last_slash < 0:
        return ""
    path.slice(0, last_slash as i64)

fn Codegen.resolve_embed_file_path(self: Codegen, source_path: str, raw_path: str) -> str:
    let _ = self
    if raw_path.len() > 0 and raw_path.byte_at(0) == 47:
        return raw_path
    let dir = codegen_dirname(source_path)
    if dir.len() == 0:
        return raw_path
    dir ++ "/" ++ raw_path

fn Codegen.try_eval_const_string(self: Codegen, node: i32, source_path: str, depth: i32) -> ConstStringEval:
    if node == 0 or depth > 32:
        return const_string_eval_fail()

    let kind = self.pool.kind(node)
    if kind == NK_STRING_LIT or kind == NK_C_STRING_LIT:
        let sym = self.pool.get_data0(node)
        return const_string_eval_ok(self.decode_string_escapes(self.intern.resolve(sym)))

    if kind == NK_COMPTIME or kind == NK_GROUPED:
        return self.try_eval_const_string(self.pool.get_data0(node), source_path, depth + 1)

    if kind == NK_BINARY:
        let op = self.pool.get_data0(node)
        if op == OP_CONCAT or op == OP_ADD:
            let lhs = self.try_eval_const_string(self.pool.get_data1(node), source_path, depth + 1)
            if not lhs.ok:
                return lhs
            let rhs = self.try_eval_const_string(self.pool.get_data2(node), source_path, depth + 1)
            if not rhs.ok:
                return rhs
            return const_string_eval_ok(lhs.text ++ rhs.text)

    if kind == NK_IDENT:
        let sym = self.pool.get_data0(node)
        let decl_index = self.find_module_let_decl_index(sym)
        if decl_index < 0:
            return const_string_eval_fail()
        let decl = self.pool.get_decl(decl_index)
        let flags = self.pool.get_data2(decl)
        if flags % 2 != 0:
            return const_string_eval_fail()
        var value_node = self.pool.get_data1(decl)
        if value_node == 0:
            return const_string_eval_fail()
        if self.pool.kind(value_node) == NK_COMPTIME:
            value_node = self.pool.get_data0(value_node)
        return self.try_eval_const_string(value_node, self.decl_source_path(decl_index), depth + 1)

    if kind == NK_CALL:
        let callee = self.pool.get_data0(node)
        if self.pool.kind(callee) != NK_IDENT:
            return const_string_eval_fail()
        let callee_sym = self.pool.get_data0(callee)
        if callee_sym != self.sema.sym_embed_file or self.pool.get_data2(node) != 1:
            return const_string_eval_fail()
        let args_start = self.pool.get_data1(node)
        let path_value = self.try_eval_const_string(self.pool.get_extra(args_start), source_path, depth + 1)
        if not path_value.ok:
            return path_value
        let path = self.resolve_embed_file_path(source_path, path_value.text)
        let content = with_fs_read_file(path)
        if content.len() == 0:
            with_eprintln("error: embed_file: could not read '" ++ path ++ "'")
            self.had_error = 1
            return const_string_eval_fail()
        return const_string_eval_ok(content)

    const_string_eval_fail()

fn Codegen.try_resolve_vec_new_global_type(self: Codegen, value_node: i32, flags: i32) -> i32:
    if value_node == 0 or self.pool.kind(value_node) != NK_CALL:
        return 0
    if self.pool.get_data2(value_node) != 0:
        return 0
    let callee = self.pool.get_data0(value_node)
    if self.pool.kind(callee) != NK_FIELD_ACCESS:
        return 0
    let recv = self.pool.get_data0(callee)
    let method_sym = self.pool.get_data1(callee)
    if self.intern.resolve(method_sym) != "new":
        return 0

    var recv_is_vec = false
    if self.pool.kind(recv) == NK_IDENT:
        recv_is_vec = self.intern.resolve(self.pool.get_data0(recv)) == "Vec"
    else if self.pool.kind(recv) == NK_INDEX:
        let recv_base = self.pool.get_data0(recv)
        if self.pool.kind(recv_base) == NK_IDENT:
            recv_is_vec = self.intern.resolve(self.pool.get_data0(recv_base)) == "Vec"
    if not recv_is_vec:
        return 0

    let type_extra_packed = flags / 4
    if type_extra_packed > 0:
        let type_ann_node = self.pool.get_extra(type_extra_packed - 1)
        let annotated = self.sema.resolve_type_expr(type_ann_node)
        if annotated > 0:
            return annotated
    if self.sema.typed_expr_types.contains(value_node):
        let inferred = self.sema.typed_expr_types.get(value_node).unwrap()
        if inferred > 0:
            return inferred
    0

fn Codegen.emit_vec_new_global(self: Codegen, name_sym: i32, vec_tid: i32, is_mut: i32) -> bool:
    let resolved = self.sema.resolve_alias(vec_tid)
    if self.sema.get_type_kind(resolved) != TY_GENERIC_INST:
        return false
    let base_sym = self.sema.get_type_d0(resolved)
    if self.intern.resolve(base_sym) != "Vec":
        return false
    if self.sema.get_type_d2(resolved) != 1:
        return false

    let elem_tid = self.sema.get_generic_inst_arg(resolved, 0)
    let elem_llvm = self.sema_type_to_llvm(elem_tid)
    let vec_llvm = self.sema_type_to_llvm(resolved)
    if elem_llvm == 0 or vec_llvm == 0:
        return false

    let i64_ty = wl_i64_type(self.context)
    let fields: Vec[i64] = Vec.new()
    fields.push(wl_const_null(wl_ptr_type(self.context)))
    fields.push(wl_const_int(i64_ty, 0, 0))
    fields.push(wl_const_int(i64_ty, 0, 0))
    // Vec.new() is logically { null, 0, 0, sizeof(T) } for globals.
    fields.push(wl_const_int(i64_ty, self.abi_size_of(elem_llvm), 0))
    let init = wl_const_named_struct(vec_llvm, vec_data_i64(&fields), 4)

    let name_str = self.intern.resolve(name_sym)
    let global = wl_add_global(self.llmod, vec_llvm, name_str)
    wl_set_initializer(global, init)
    if is_mut == 0:
        wl_set_global_constant(global, 1)
    wl_set_linkage(global, wl_internal_linkage())
    self.module_constants.insert(name_sym, global)
    true

fn Codegen.try_eval_const_int(self: Codegen, node: i32) -> i64:
    let kind = self.pool.kind(node)
    if kind == NK_INT_LIT:
        return self.pool.int_lit_value(node)
    if kind == NK_COMPTIME:
        return self.try_eval_const_int(self.pool.get_data0(node))
    if kind == NK_GROUPED:
        return self.try_eval_const_int(self.pool.get_data0(node))
    if kind == NK_BOOL_LIT:
        return self.pool.get_data0(node) as i64
    if kind == NK_UNARY:
        let op = self.pool.get_data0(node)
        let inner_val = self.try_eval_const_int(self.pool.get_data1(node))
        if inner_val == CONST_EVAL_FAIL(): return CONST_EVAL_FAIL()
        if op == UOP_NEGATE: return -inner_val
        if op == UOP_NOT:
            if inner_val == 0: return 1
            return 0
        return CONST_EVAL_FAIL()
    if kind == NK_BINARY:
        let op = self.pool.get_data0(node)
        let lv = self.try_eval_const_int(self.pool.get_data1(node))
        if lv == CONST_EVAL_FAIL(): return CONST_EVAL_FAIL()
        let rv = self.try_eval_const_int(self.pool.get_data2(node))
        if rv == CONST_EVAL_FAIL(): return CONST_EVAL_FAIL()
        if op == OP_ADD: return lv + rv
        if op == OP_SUB: return lv - rv
        if op == OP_MUL: return lv * rv
        if op == OP_DIV:
            if rv == 0: return CONST_EVAL_FAIL()
            return lv / rv
        if op == OP_MOD:
            if rv == 0: return CONST_EVAL_FAIL()
            return lv % rv
        // Bitwise ops: handled when the compiler can parse them in this context
        return CONST_EVAL_FAIL()
    if kind == NK_IDENT:
        let sym = self.pool.get_data0(node)
        // Linear search for known constant
        for ci in 0..self.const_int_syms.len() as i32:
            if self.const_int_syms.get(ci as i64) == sym:
                return self.const_int_vals.get(ci as i64)
        return CONST_EVAL_FAIL()
    CONST_EVAL_FAIL()

fn Codegen.gen_module_constant(self: Codegen, let_node: i32):
    let name_sym = self.pool.get_data0(let_node)
    var value_node = self.pool.get_data1(let_node)
    if value_node == 0: return

    // Unwrap comptime wrapper (const desugars to comptime)
    if self.pool.kind(value_node) == NK_COMPTIME:
        value_node = self.pool.get_data0(value_node)

    let flags = self.pool.get_data2(let_node)
    let is_mut = flags % 2
    let val = self.try_eval_const_int(value_node)
    if val != CONST_EVAL_FAIL():
        if is_mut == 0:
            self.const_int_syms.push(name_sym)
            self.const_int_vals.push(val)
        // Respect type annotation: if declared as i64, always use i64
        var global_ty = if val < -2147483648 or val > 2147483647: wl_i64_type(self.context) else: wl_i32_type(self.context)
        let type_extra_packed = flags / 4
        if type_extra_packed > 0:
            let type_ann_node = self.pool.get_extra(type_extra_packed - 1)
            if self.pool.kind(type_ann_node) == NK_TYPE_NAMED:
                let type_name = self.intern.resolve(self.pool.get_data0(type_ann_node))
                if type_name == "i64":
                    global_ty = wl_i64_type(self.context)
                else if type_name == "i128" or type_name == "u128":
                    global_ty = wl_i128_type(self.context)
        let name_str = self.intern.resolve(name_sym)
        let global = wl_add_global(self.llmod, global_ty, name_str)
        wl_set_initializer(global, wl_const_int(global_ty, val, 1))
        if is_mut == 0:
            wl_set_global_constant(global, 1)
        wl_set_linkage(global, wl_internal_linkage())
        self.module_constants.insert(name_sym, global)
        return

    let str_value = self.try_eval_const_string(value_node, self.current_decl_source_file, 0)
    if str_value.ok:
        let str_sym = self.intern.intern("str")
        let st_opt = self.struct_type_map.get(str_sym)
        if not st_opt.is_some():
            with_eprintln("warning: [string-global] str struct type not found")
            return
        let str_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
        let name_str = self.intern.resolve(name_sym)
        let bytes_name = name_str ++ ".__bytes"
        let bytes_ty = wl_array_type(wl_i8_type(self.context), str_value.text.len() + 1)
        let bytes_global = wl_add_global(self.llmod, bytes_ty, bytes_name)
        wl_set_initializer(bytes_global, wl_const_string(self.context, str_value.text, 0))
        wl_set_global_constant(bytes_global, 1)
        wl_set_linkage(bytes_global, wl_private_linkage())

        let fields: Vec[i64] = Vec.new()
        fields.push(wl_const_bitcast(bytes_global, wl_ptr_type(self.context)))
        fields.push(wl_const_int(wl_i64_type(self.context), str_value.text.len(), 1))
        let str_init = wl_const_named_struct(str_ty, vec_data_i64(&fields), 2)

        let global = wl_add_global(self.llmod, str_ty, name_str)
        wl_set_initializer(global, str_init)
        if is_mut == 0:
            wl_set_global_constant(global, 1)
        wl_set_linkage(global, wl_internal_linkage())
        self.module_constants.insert(name_sym, global)
        return

    let vec_tid = self.try_resolve_vec_new_global_type(value_node, flags)
    if vec_tid > 0:
        if self.emit_vec_new_global(name_sym, vec_tid, is_mut):
            return

    // Float constant: NK_FLOAT_LIT or unary negate of one
    var float_node = value_node
    var float_negate = false
    if self.pool.kind(float_node) == NK_UNARY:
        if self.pool.get_data0(float_node) == UOP_NEGATE:
            float_node = self.pool.get_data1(float_node)
            float_negate = true
    if self.pool.kind(float_node) == NK_FLOAT_LIT:
        let str_idx = self.pool.get_data0(float_node)
        var fval: f64 = 0.0
        if str_idx >= 0 and str_idx < self.pool.strings.len() as i32:
            let float_text = self.pool.get_string(str_idx)
            if float_text.len() > 0:
                fval = with_parse_float(float_text)
        if float_negate:
            fval = -fval
        // Determine f32 vs f64 from type annotation
        var global_ty = wl_f64_type(self.context)
        let type_extra_packed = flags / 4
        if type_extra_packed > 0:
            let type_ann_node = self.pool.get_extra(type_extra_packed - 1)
            if self.pool.kind(type_ann_node) == NK_TYPE_NAMED:
                let type_name = self.intern.resolve(self.pool.get_data0(type_ann_node))
                if type_name == "f32":
                    global_ty = wl_f32_type(self.context)
        let name_str = self.intern.resolve(name_sym)
        let global = wl_add_global(self.llmod, global_ty, name_str)
        wl_set_initializer(global, wl_const_real(global_ty, fval))
        if is_mut == 0:
            wl_set_global_constant(global, 1)
        wl_set_linkage(global, wl_internal_linkage())
        self.module_constants.insert(name_sym, global)

// ── Wrap main for exit ────────────────────────────────────────────

fn Codegen.wrap_main_for_exit(self: Codegen) -> void:
    // Create an OS-facing wrapper that preserves argv/runtime setup before
    // calling the user's `main`.
    let main_fn = wl_get_named_function(self.llmod, "main")
    if main_fn == 0: return
    let main_ft = wl_global_get_value_type(main_fn)
    let ret_ty = wl_get_return_type(main_ft)
    // Rename user main to __with_main.
    wl_set_value_name(main_fn, "__with_main")

    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let wrapper_params: Vec[i64] = Vec.new()
    wrapper_params.push(i32_ty)
    wrapper_params.push(ptr_ty)
    let wrapper_ft = wl_function_type(i32_ty, vec_data_i64(&wrapper_params), 2, 0)
    let wrapper = wl_add_function(self.llmod, "main", wrapper_ft)
    let bb = wl_append_bb(self.context, wrapper, "entry")
    wl_position_at_end(self.builder, bb)

    let argc_val = wl_get_param(wrapper, 0)
    let argv_val = wl_get_param(wrapper, 1)

    var set_argv_fn = wl_get_named_function(self.llmod, "with_runtime_set_argv")
    if set_argv_fn == 0:
        let set_argv_params: Vec[i64] = Vec.new()
        set_argv_params.push(i32_ty)
        set_argv_params.push(ptr_ty)
        let set_argv_ft = wl_function_type(wl_void_type(self.context), vec_data_i64(&set_argv_params), 2, 0)
        set_argv_fn = wl_add_function(self.llmod, "with_runtime_set_argv", set_argv_ft)
    let set_argv_ft = wl_global_get_value_type(set_argv_fn)
    let set_argv_args: Vec[i64] = Vec.new()
    set_argv_args.push(argc_val)
    set_argv_args.push(argv_val)
    wl_build_call(self.builder, set_argv_ft, set_argv_fn, vec_data_i64(&set_argv_args), 2)

    var runtime_init_fn = wl_get_named_function(self.llmod, "with_runtime_init")
    if runtime_init_fn == 0:
        let runtime_init_ft_new = wl_function_type(wl_void_type(self.context), 0, 0, 0)
        runtime_init_fn = wl_add_function(self.llmod, "with_runtime_init", runtime_init_ft_new)
    let runtime_init_ft = wl_global_get_value_type(runtime_init_fn)
    wl_build_call(self.builder, runtime_init_ft, runtime_init_fn, 0, 0)

    let main_call = wl_build_call(self.builder, main_ft, main_fn, 0, 0)

    var runtime_shutdown_fn = wl_get_named_function(self.llmod, "with_runtime_shutdown")
    if runtime_shutdown_fn == 0:
        let runtime_shutdown_ft_new = wl_function_type(wl_void_type(self.context), 0, 0, 0)
        runtime_shutdown_fn = wl_add_function(self.llmod, "with_runtime_shutdown", runtime_shutdown_ft_new)
    let runtime_shutdown_ft = wl_global_get_value_type(runtime_shutdown_fn)
    wl_build_call(self.builder, runtime_shutdown_ft, runtime_shutdown_fn, 0, 0)

    if ret_ty == wl_void_type(self.context):
        let _ = wl_build_ret(self.builder, wl_const_int(i32_ty, 0, 0))
        return

    let exit_val =
        if ret_ty == i32_ty:
            main_call
        else:
            self.coerce_int(main_call, i32_ty)
    let _ = wl_build_ret(self.builder, exit_val)

// ── gen_function_dispatch: MIR-first, AST fallback for unsupported patterns ──

fn Codegen.gen_function_dispatch(self: Codegen, fn_node: i32):
    let flags = self.pool.get_data2(fn_node)
    let fn_sym = self.pool.get_data0(fn_node)
    // Skip functions with fn-level type params — compiled via monomorphization
    let meta = self.pool.find_fn_meta(fn_node)
    if meta >= 0 and self.pool.fn_meta_tp_count(meta) > 0:
        return
    // Skip generic struct methods without fn_values — compiled via monomorphization
    if self.sema.generic_fn_nodes.contains(fn_sym):
        if not self.fn_values.get(fn_sym).is_some():
            return
    let body_idx = self.mir_input.find_body(fn_sym)
    if body_idx >= 0:
        let body = self.mir_input.bodies.get(body_idx as i64)
        if body.lowering_failed == 0 and body.block_count() > 0:
            if self.debug_mir_codegen_enabled():
                let fn_name = self.intern.resolve(fn_sym)
                with_eprintln("[mir-dispatch] using MIR for: " ++ fn_name)
            let fv = self.fn_values.get(fn_sym)
            if fv.is_some():
                self.current_function_name_sym = fn_sym
                self.debug_enter_function(fn_node, fn_sym, fv.unwrap() as i64)
                let fn_span = self.pool.get_start(fn_node)
                self.debug_set_location(fn_span)
            self.gen_function_mir(fn_node, body)
            self.debug_clear_location()
            return
    // No MIR body — emit unreachable stub
    let fv_fb = self.fn_values.get(fn_sym)
    if fv_fb.is_some():
        let fb_fn = fv_fb.unwrap() as i64
        let fb_entry = wl_append_bb(self.context, fb_fn, "entry")
        wl_position_at_end(self.builder, fb_entry)
        let _ = wl_build_unreachable(self.builder)

fn Codegen.mir_sema_type_to_llvm(self: Codegen, sema_ty: i32) -> i64:
    // Use MIR module's snapshot of sema type tables — the original sema's
    // type Vecs may have been freed by MirLower's by-value copy realloc.
    // For types created after snapshot (e.g. by check_fn_body_concrete),
    // fall back to reading from sema directly.
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    var tk = self.mir_input.mir_get_type_kind(resolved)
    if tk == 0 and resolved >= self.mir_input.sema_type_kinds.len() as i32 and resolved > 0:
        // Type was created after snapshot — read from sema directly
        return self.sema_type_to_llvm(resolved)
    if tk == TY_INT:
        let bits = self.mir_input.mir_get_type_d0(resolved)
        if bits == 8: return wl_i8_type(self.context)
        if bits == 16: return wl_i16_type(self.context)
        if bits == 64: return wl_i64_type(self.context)
        if bits == 128: return wl_i128_type(self.context)
        return wl_i32_type(self.context)
    if tk == TY_FLOAT:
        let bits = self.mir_input.mir_get_type_d0(resolved)
        if bits == 32: return wl_f32_type(self.context)
        return wl_f64_type(self.context)
    if tk == TY_BOOL:
        return wl_i1_type(self.context)
    if tk == TY_STR:
        let str_sym = self.intern.intern("str")
        return self.resolve_named_type(str_sym)
    if tk == TY_STRUCT or tk == TY_ENUM:
        let name_sym = self.mir_input.mir_get_type_d0(resolved)
        if name_sym != 0:
            // Translate sema pool sym to codegen intern pool sym
            var cg_sym = name_sym
            if name_sym > 0 and name_sym < self.sema.pool.symbol_texts.len() as i32:
                let sema_text = self.sema.pool.symbol_texts.get(name_sym as i64)
                if sema_text.len() > 0:
                    cg_sym = self.intern.intern(sema_text)
            let named_ty = self.resolve_named_type(cg_sym)
            if named_ty != 0:
                return named_ty
            // Disc enum without payloads: return repr type
            if tk == TY_ENUM:
                let de_opt = self.disc_enum_type_map.get(cg_sym)
                if de_opt.is_some():
                    return self.disc_enum_repr_types.get(de_opt.unwrap() as i64)
    if tk == TY_GENERIC_INST:
        return self.sema_type_to_llvm(resolved)
    if tk == TY_TUPLE:
        let te_start = self.mir_input.mir_get_type_d0(resolved)
        let te_count = self.mir_input.mir_get_type_d1(resolved)
        let elem_types: Vec[i64] = Vec.new()
        for i in 0..te_count:
            let elem_tid = self.mir_input.mir_get_type_extra(te_start + i)
            var elem_llvm = self.mir_sema_type_to_llvm(elem_tid)
            if elem_llvm == 0:
                elem_llvm = wl_i32_type(self.context)
            elem_types.push(elem_llvm)
        if te_count > 0:
            return wl_struct_type(self.context, vec_data_i64(&elem_types), te_count, 0)
        return wl_i32_type(self.context)
    if tk == TY_ARRAY:
        let arr_elem_tid = self.mir_input.mir_get_type_d0(resolved)
        let arr_len = self.mir_input.mir_get_type_d1(resolved)
        var arr_elem_llvm = self.mir_sema_type_to_llvm(arr_elem_tid)
        if arr_elem_llvm == 0:
            arr_elem_llvm = wl_i32_type(self.context)
        return wl_array_type(arr_elem_llvm, arr_len as i64)
    if tk == TY_PTR or tk == TY_REF:
        return wl_ptr_type(self.context)
    if tk == TY_FN:
        let ptr_ty = wl_ptr_type(self.context)
        let fat_types: Vec[i64] = Vec.new()
        fat_types.push(ptr_ty)
        fat_types.push(ptr_ty)
        return wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)
    if tk == TY_SLICE:
        let body_types: Vec[i64] = Vec.new()
        body_types.push(wl_ptr_type(self.context))
        body_types.push(wl_i64_type(self.context))
        return wl_struct_type(self.context, vec_data_i64(&body_types), 2, 0)
    0

fn Codegen.mir_build_closure_fn_type(self: Codegen, sema_ty: i32) -> i64:
    var resolved = self.mir_input.mir_resolve_alias(sema_ty)
    var tk = self.mir_input.mir_get_type_kind(resolved)
    // Type created after MIR snapshot — read from sema directly
    if tk == 0 and resolved >= self.mir_input.sema_type_kinds.len() as i32 and resolved > 0:
        resolved = self.sema.resolve_alias(resolved)
        tk = self.sema.get_type_kind(resolved)
    if tk != TY_FN:
        return 0
    var extra_start = self.mir_input.mir_get_type_d0(resolved)
    var param_count = self.mir_input.mir_get_type_d1(resolved)
    var ret_ty_id = self.mir_input.mir_get_type_d2(resolved)
    // Fallback to sema for types beyond snapshot
    if resolved >= self.mir_input.sema_type_kinds.len() as i32:
        extra_start = self.sema.get_type_d0(resolved)
        param_count = self.sema.get_type_d1(resolved)
        ret_ty_id = self.sema.get_type_d2(resolved)
    let ret_ty = self.mir_sema_type_to_llvm(ret_ty_id)
    let llvm_ret = if ret_ty != 0: ret_ty else: wl_void_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(wl_ptr_type(self.context))
    for pi in 0..param_count:
        var p_sema_ty = self.mir_input.mir_get_type_extra(extra_start + pi)
        if resolved >= self.mir_input.sema_type_kinds.len() as i32:
            let te_idx = extra_start + pi
            if te_idx >= 0 and te_idx < self.sema.type_extra.len() as i32:
                p_sema_ty = self.sema.type_extra.get(te_idx as i64)
        let p_llvm_ty = self.mir_sema_type_to_llvm(p_sema_ty)
        if p_llvm_ty != 0:
            param_types.push(p_llvm_ty)
        else:
            param_types.push(wl_i32_type(self.context))
    wl_function_type(llvm_ret, vec_data_i64(&param_types), param_count + 1, 0)

fn Codegen.mir_get_or_create_local_ptr(self: Codegen, local_id: i32, ty: i64) -> i64:
    let existing = self.mir_local_ptrs.get(local_id)
    if existing.is_some():
        return existing.unwrap() as i64
    let alloc_ty = if ty != 0: ty else: wl_i32_type(self.context)
    let ptr = self.create_entry_alloca(alloc_ty)
    self.mir_local_ptrs.insert(local_id, ptr)
    ptr

fn Codegen.mir_try_init_const_local(self: Codegen, body: MirBody, local_id: i32, ptr: i64, llvm_ty: i64) -> bool:
    if local_id < 0 or local_id >= body.local_names.len() as i32:
        return false
    let sym = body.local_names.get(local_id as i64)
    if sym == 0:
        return false
    let decl_index = self.find_module_let_decl_index(sym)
    if decl_index < 0:
        return false
    let decl = self.pool.get_decl(decl_index)
    let flags = self.pool.get_data2(decl)
    if flags % 2 != 0:
        return false
    var value_node = self.pool.get_data1(decl)
    if value_node == 0:
        return false
    if self.pool.kind(value_node) == NK_COMPTIME:
        value_node = self.pool.get_data0(value_node)
    let value = self.try_eval_const_string(value_node, self.decl_source_path(decl_index), 0)
    if not value.ok:
        return false
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some():
        return false
    let str_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
    if llvm_ty != str_ty:
        return false
    wl_build_store(self.builder, self.gen_string_literal_raw(value.text), ptr)
    true


fn Codegen.mir_resolve_field_index(self: Codegen, agg_ty: i64, field_token: i32) -> i32:
    // Arrays use direct numeric index
    if wl_get_type_kind(agg_ty) == wl_array_type_kind():
        if field_token >= 0 and field_token < wl_get_array_length(agg_ty) as i32:
            return field_token
        return 0 - 1
    if wl_get_type_kind(agg_ty) != wl_struct_type_kind():
        return 0 - 1
    let elem_count = wl_count_struct_elem_types(agg_ty)

    // Try symbol-based lookup first (for named struct fields from MIR field projections).
    // MIR stores field *symbols* as projection data, not numeric indices.
    // Must do this before the raw range check, because a symbol value (e.g. 132 for "ast")
    // can accidentally pass field_token < elem_count on large structs.
    let st_sym = self.find_struct_type_by_llvm(agg_ty)
    if st_sym != 0:
        let fi = self.find_field_index(st_sym, field_token)
        if fi >= 0 and fi < elem_count:
            return fi

    // Vec types are created dynamically and not registered in the struct field
    // registry. Resolve their field names by layout: {ptr, len, cap, elem_size}.
    if self.vec_type_to_elem.contains(agg_ty):
        let field_name = self.intern.resolve(field_token)
        if field_name == "ptr": return 0
        if field_name == "len": return 1
        if field_name == "cap": return 2
        if field_name == "elem_size": return 3

    // Fall back to direct numeric index (for tuple fields, match bindings)
    if field_token >= 0 and field_token < elem_count:
        return field_token

    let field_name = self.intern.resolve(field_token)
    if field_name.len() == 1:
        let ch = field_name.byte_at(0)
        if ch >= 48 and ch <= 57:
            let idx = (ch - 48) as i32
            if idx >= 0 and idx < elem_count:
                return idx

    0 - 1

fn Codegen.mir_place_projected_type(self: Codegen, body: MirBody, place_id: i32) -> i64:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    let base_local = body.place_locals.get(place_id as i64)
    let p_count = body.place_proj_counts.get(place_id as i64)
    if p_count == 0:
        return 0
    var cur_ty: i64 = 0
    var cur_sema_ty: i32 = 0
    let cur_ty_opt = self.mir_local_types.get(base_local)
    if cur_ty_opt.is_some():
        cur_ty = cur_ty_opt.unwrap() as i64
    if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
        cur_sema_ty = body.local_type_ids.get(base_local as i64)
    if cur_ty == 0 and base_local >= 0 and base_local < body.local_type_ids.len() as i32:
        if cur_sema_ty > 0:
            let type_name_sym = self.mir_input.mir_get_type_name(cur_sema_ty)
            if type_name_sym != 0:
                cur_ty = self.resolve_named_type(type_name_sym)
            if cur_ty == 0:
                cur_ty = self.mir_sema_type_to_llvm(cur_sema_ty)
    if cur_ty == 0:
        return 0
    let p_start = body.place_proj_starts.get(place_id as i64)
    for i in 0..p_count:
        let pk = body.proj_kinds.get((p_start + i) as i64)
        let pd = body.proj_d0.get((p_start + i) as i64)
        if pk == 0: // PK_FIELD
            if wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
                    let sema_ty = body.local_type_ids.get(base_local as i64)
                    if sema_ty > 0:
                        let type_name_sym = self.mir_input.mir_get_type_name(sema_ty)
                        if type_name_sym != 0:
                            cur_ty = self.resolve_named_type(type_name_sym)
                // Fallback: use method owner type for self parameter
                if (cur_ty == 0 or wl_get_type_kind(cur_ty) == wl_pointer_type_kind()) and self.current_method_owner_sym != 0:
                    let proj_owner_ty = self.resolve_named_type(self.current_method_owner_sym)
                    if proj_owner_ty != 0:
                        cur_ty = proj_owner_ty
            let fi = self.mir_resolve_field_index(cur_ty, pd)
            if fi < 0:
                return 0
            if wl_get_type_kind(cur_ty) == wl_array_type_kind():
                cur_ty = wl_get_element_type(cur_ty)
            else if fi < wl_count_struct_elem_types(cur_ty):
                cur_ty = wl_struct_get_type_at(cur_ty, fi)
            else:
                return 0
        else if pk == 2: // PK_DEREF
            // Resolve pointee type from base local's sema type (via MIR snapshot)
            var deref_ty: i64 = 0
            if cur_sema_ty > 0:
                let deref_resolved = self.mir_input.mir_resolve_alias(cur_sema_ty)
                let deref_tk = self.mir_input.mir_get_type_kind(deref_resolved)
                if deref_tk == TY_PTR or deref_tk == TY_REF:
                    let pointee_sema = self.mir_input.mir_get_type_d0(deref_resolved)
                    if pointee_sema > 0:
                        cur_sema_ty = pointee_sema
                        deref_ty = self.mir_sema_type_to_llvm(pointee_sema)
            if deref_ty != 0:
                cur_ty = deref_ty
            else:
                return 0
        else if pk == 1: // PK_INDEX
            let idx_elem_ty = self.mir_index_elem_llvm_type(cur_sema_ty, cur_ty)
            let idx_elem_sema = self.mir_index_elem_sema_type(cur_sema_ty)
            if idx_elem_sema > 0:
                cur_sema_ty = idx_elem_sema
            if idx_elem_ty != 0:
                cur_ty = idx_elem_ty
            else:
                return 0
        else if pk == 3: // PK_DOWNCAST
            // For projected_type, we need the variant's payload struct type.
            var dc_found = false
            if wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                let wrap: Vec[i64] = Vec.new()
                wrap.push(cur_ty)
                cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                dc_found = true
            // Check disc enums first
            let enum_sym_opt = self.enum_by_llvm.get(cur_ty)
            if enum_sym_opt.is_some():
                let dc_enum_sym = enum_sym_opt.unwrap()
                let dc_et_opt = self.enum_type_map.get(dc_enum_sym)
                if dc_et_opt.is_some():
                    let dc_idx = dc_et_opt.unwrap()
                    let dc_v_start = self.enum_variant_starts.get(dc_idx as i64)
                    if pd >= 0 and dc_v_start + pd < self.enum_variant_payloads.len() as i32:
                        let payload_ty = self.enum_variant_payloads.get((dc_v_start + pd) as i64)
                        if payload_ty != 0:
                            cur_ty = payload_ty
                            dc_found = true
            // Check Option types: {i32, T} → wrap payload in {T} for PK_FIELD access
            if not dc_found:
                let opt_idx = self.find_option_idx_by_llvm(cur_ty)
                if opt_idx >= 0:
                    let opt_payload = self.option_payload_types.get(opt_idx as i64)
                    if opt_payload != 0:
                        let wrap: Vec[i64] = Vec.new()
                        wrap.push(opt_payload)
                        cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                        dc_found = true
            // Check Result types: {i32, [N x i8]} → wrap ok/err payload in {T} for PK_FIELD
            if not dc_found:
                let res_idx = self.find_result_idx_by_llvm(cur_ty)
                if res_idx >= 0:
                    var res_payload: i64 = 0
                    if pd == 0:
                        res_payload = self.result_ok_types.get(res_idx as i64)
                    else if pd == 1:
                        res_payload = self.result_err_types.get(res_idx as i64)
                    if res_payload != 0:
                        let wrap: Vec[i64] = Vec.new()
                        wrap.push(res_payload)
                        cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                        dc_found = true
        else:
            return 0
    cur_ty

fn Codegen.mir_place_ptr(self: Codegen, body: MirBody, place_id: i32, create_base: bool, create_type: i64) -> i64:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0

    let base_local = body.place_locals.get(place_id as i64)
    let p_count = body.place_proj_counts.get(place_id as i64)
    let base_opt = self.mir_local_ptrs.get(base_local)
    var cur_ptr: i64 = 0
    if base_opt.is_some():
        cur_ptr = base_opt.unwrap() as i64
    if cur_ptr == 0:
        if create_base:
            cur_ptr = self.mir_get_or_create_local_ptr(base_local, create_type)
            let alloc_ty = if create_type != 0: create_type else: wl_i32_type(self.context)
            self.mir_local_types.insert(base_local, alloc_ty)
            let _ = self.mir_try_init_const_local(body, base_local, cur_ptr, alloc_ty)
        else:
            return 0

    if p_count == 0:
        return cur_ptr

    // Walk projections: field access, index, deref
    let p_start = body.place_proj_starts.get(place_id as i64)
    var cur_ty: i64 = 0
    var cur_sema_ty: i32 = 0
    let cur_ty_opt = self.mir_local_types.get(base_local)
    if cur_ty_opt.is_some():
        cur_ty = cur_ty_opt.unwrap() as i64
    if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
        cur_sema_ty = body.local_type_ids.get(base_local as i64)
    // Resolve type via sema snapshot if LLVM type not yet known
    if cur_ty == 0 and base_local >= 0 and base_local < body.local_type_ids.len() as i32:
        if cur_sema_ty > 0:
            let type_name_sym = self.mir_input.mir_get_type_name(cur_sema_ty)
            if type_name_sym != 0:
                cur_ty = self.resolve_named_type(type_name_sym)
            if cur_ty == 0:
                cur_ty = self.mir_sema_type_to_llvm(cur_sema_ty)
            if cur_ty != 0:
                self.mir_local_types.insert(base_local, cur_ty)
    for i in 0..p_count:
        let pk = body.proj_kinds.get((p_start + i) as i64)
        let pd = body.proj_d0.get((p_start + i) as i64)
        if pk == 0: // PK_FIELD
            if cur_ty == 0 or wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                // Base is a pointer (e.g., self param) — load the pointer first
                if cur_ty == 0:
                    cur_ptr = wl_build_load(self.builder, wl_ptr_type(self.context), cur_ptr)
                else:
                    cur_ptr = wl_build_load(self.builder, cur_ty, cur_ptr)
                // Resolve the pointee struct type via sema snapshot
                if base_local >= 0 and base_local < body.local_type_ids.len() as i32:
                    let sema_ty = body.local_type_ids.get(base_local as i64)
                    if sema_ty > 0:
                        let type_name_sym = self.mir_input.mir_get_type_name(sema_ty)
                        if type_name_sym != 0:
                            cur_ty = self.resolve_named_type(type_name_sym)
                        if cur_ty == 0:
                            cur_ty = self.mir_sema_type_to_llvm(sema_ty)
                // Fallback: use method owner type for self parameter
                if (cur_ty == 0 or wl_get_type_kind(cur_ty) == wl_pointer_type_kind()) and self.current_method_owner_sym != 0:
                    let owner_ty = self.resolve_named_type(self.current_method_owner_sym)
                    if owner_ty != 0:
                        cur_ty = owner_ty
            let fi = self.mir_resolve_field_index(cur_ty, pd)
            if fi < 0:
                return 0
            if wl_get_type_kind(cur_ty) == wl_array_type_kind():
                // Array field access: GEP with [0, index]
                let arr_elem_ty = wl_get_element_type(cur_ty)
                let gep_indices: Vec[i64] = Vec.new()
                gep_indices.push(wl_const_int(wl_i32_type(self.context), 0, 0))
                gep_indices.push(wl_const_int(wl_i32_type(self.context), fi as i64, 0))
                cur_ptr = wl_build_gep(self.builder, cur_ty, cur_ptr, vec_data_i64(&gep_indices), 2)
                cur_ty = arr_elem_ty
            else:
                let llvm_fi = self.get_llvm_field_index(cur_ty, fi)
                cur_ptr = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, llvm_fi)
                if llvm_fi < wl_count_struct_elem_types(cur_ty):
                    cur_ty = wl_struct_get_type_at(cur_ty, llvm_fi)
                else:
                    cur_ty = 0
        else if pk == 2: // PK_DEREF
            // Load the pointer value, then use it as the new base
            cur_ptr = wl_build_load(self.builder, wl_ptr_type(self.context), cur_ptr)
            // Resolve pointee type from base local's sema type (via snapshot)
            var deref_ptr_ty: i64 = 0
            if cur_sema_ty > 0:
                let deref_resolved = self.mir_input.mir_resolve_alias(cur_sema_ty)
                let deref_tk = self.mir_input.mir_get_type_kind(deref_resolved)
                if deref_tk == TY_PTR or deref_tk == TY_REF:
                    let pointee_sema = self.mir_input.mir_get_type_d0(deref_resolved)
                    if pointee_sema > 0:
                        cur_sema_ty = pointee_sema
                        deref_ptr_ty = self.mir_sema_type_to_llvm(pointee_sema)
            if deref_ptr_ty != 0:
                cur_ty = deref_ptr_ty
            else:
                cur_ty = 0
        else if pk == 1: // PK_INDEX
            // pd is a local_id holding the index value
            let idx_ptr_opt = self.mir_local_ptrs.get(pd)
            var idx_val: i64 = wl_const_int(wl_i64_type(self.context), 0, 0)
            if idx_ptr_opt.is_some():
                let idx_ty_opt = self.mir_local_types.get(pd)
                var idx_ty = wl_i32_type(self.context)
                if idx_ty_opt.is_some():
                    idx_ty = idx_ty_opt.unwrap() as i64
                idx_val = wl_build_load(self.builder, idx_ty, idx_ptr_opt.unwrap() as i64)
            let elem_llvm = self.mir_index_elem_llvm_type(cur_sema_ty, cur_ty)
            let elem_sema = self.mir_index_elem_sema_type(cur_sema_ty)
            if elem_sema > 0:
                cur_sema_ty = elem_sema
            if wl_get_type_kind(cur_ty) == wl_array_type_kind():
                let indices: Vec[i64] = Vec.new()
                indices.push(idx_val)
                cur_ptr = wl_build_gep(self.builder, elem_llvm, cur_ptr, vec_data_i64(&indices), 1)
                cur_ty = elem_llvm
            else:
                // Vec, str, and slices all store their data pointer in field 0.
                if elem_llvm == 0:
                    return 0
                let data_gep = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, 0)
                let raw_ptr = wl_build_load(self.builder, wl_ptr_type(self.context), data_gep)
                let indices: Vec[i64] = Vec.new()
                indices.push(idx_val)
                cur_ptr = wl_build_gep(self.builder, elem_llvm, raw_ptr, vec_data_i64(&indices), 1)
                cur_ty = elem_llvm
        else if pk == 3: // PK_DOWNCAST
            // GEP to field 1 of enum/option/result struct for payload access.
            var dc_handled = false
            if wl_get_type_kind(cur_ty) == wl_pointer_type_kind():
                let wrap: Vec[i64] = Vec.new()
                wrap.push(cur_ty)
                cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                dc_handled = true
            // Disc enums: { repr_type, [max_payload x i8] }
            let dc_enum_sym_opt = self.enum_by_llvm.get(cur_ty)
            if dc_enum_sym_opt.is_some():
                let dc_enum_sym = dc_enum_sym_opt.unwrap()
                let dc_et_opt = self.enum_type_map.get(dc_enum_sym)
                if dc_et_opt.is_some():
                    let dc_idx = dc_et_opt.unwrap()
                    let dc_v_start = self.enum_variant_starts.get(dc_idx as i64)
                    var dc_payload_ty: i64 = 0
                    if pd >= 0 and dc_v_start + pd < self.enum_variant_payloads.len() as i32:
                        dc_payload_ty = self.enum_variant_payloads.get((dc_v_start + pd) as i64)
                    if wl_count_struct_elem_types(cur_ty) > 1:
                        cur_ptr = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, 1)
                    if dc_payload_ty != 0:
                        cur_ty = dc_payload_ty
                    else:
                        cur_ty = 0
                    dc_handled = true
            // Option types: { i32, T } → GEP to field 1, wrap T in {T}
            if not dc_handled:
                let dc_opt_idx = self.find_option_idx_by_llvm(cur_ty)
                if dc_opt_idx >= 0:
                    let dc_opt_payload = self.option_payload_types.get(dc_opt_idx as i64)
                    if wl_count_struct_elem_types(cur_ty) > 1:
                        cur_ptr = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, 1)
                    if dc_opt_payload != 0:
                        let wrap: Vec[i64] = Vec.new()
                        wrap.push(dc_opt_payload)
                        cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                    else:
                        cur_ty = 0
                    dc_handled = true
            // Result types: { i32, [N x i8] } → GEP to field 1, wrap ok/err in {T}
            if not dc_handled:
                let dc_res_idx = self.find_result_idx_by_llvm(cur_ty)
                if dc_res_idx >= 0:
                    var dc_res_payload: i64 = 0
                    if pd == 0:
                        dc_res_payload = self.result_ok_types.get(dc_res_idx as i64)
                    else if pd == 1:
                        dc_res_payload = self.result_err_types.get(dc_res_idx as i64)
                    if wl_count_struct_elem_types(cur_ty) > 1:
                        cur_ptr = wl_build_struct_gep(self.builder, cur_ty, cur_ptr, 1)
                    if dc_res_payload != 0:
                        let wrap: Vec[i64] = Vec.new()
                        wrap.push(dc_res_payload)
                        cur_ty = wl_struct_type(self.context, vec_data_i64(&wrap), 1, 0)
                    else:
                        cur_ty = 0
                    dc_handled = true
            if not dc_handled:
                cur_ty = 0
        else:
            return 0

    cur_ptr

fn Codegen.mir_const_value(self: Codegen, body: MirBody, const_id: i32, expected_ty: i64) -> i64:
    let fallback_ty = if expected_ty != 0: expected_ty else: wl_i32_type(self.context)
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        if self.debug_fallback_enabled():
            with_eprintln("warning: [fallback] mir_const_value: invalid const_id=" ++ int_to_string(const_id))
        return wl_get_undef(fallback_ty)

    let ck = body.const_kinds.get(const_id as i64)
    let cd = body.const_d0.get(const_id as i64)

    if ck == CK_INT:
        let int_value = mir_const_int_value(body, const_id)
        // Null pointer: CK_INT 0 with pointer expected type
        if int_value == 0 and expected_ty != 0 and wl_get_type_kind(expected_ty) == wl_pointer_type_kind():
            return wl_const_null(expected_ty)
        var int_ty = expected_ty
        if int_ty == 0 or wl_get_type_kind(int_ty) != wl_integer_type_kind():
            int_ty = if int_value < -2147483648 or int_value > 2147483647: wl_i64_type(self.context) else: wl_i32_type(self.context)
        return wl_const_int(int_ty, int_value, 1)

    if ck == CK_BOOL:
        return wl_const_int(wl_i1_type(self.context), cd as i64, 0)

    if ck == CK_STR:
        let text = if cd != 0: self.decode_string_escapes(self.intern.resolve(cd)) else: ""
        return self.gen_string_literal_raw(text)

    if ck == CK_UNIT:
        if expected_ty != 0 and expected_ty != wl_void_type(self.context):
            return self.build_default_value(expected_ty)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    if ck == CK_FLOAT:
        var float_ty = expected_ty
        if float_ty == 0:
            float_ty = wl_f64_type(self.context)
        let fk = wl_get_type_kind(float_ty)
        if fk != wl_float_type_kind() and fk != wl_double_type_kind():
            float_ty = wl_f64_type(self.context)
        var fval: f64 = 0.0
        // CK_FLOAT d0 is an AstPool string table index (from Parser.add_string)
        if cd >= 0 and cd < self.pool.strings.len() as i32:
            let float_text = self.pool.get_string(cd)
            if float_text.len() > 0:
                fval = with_parse_float(float_text)
        return wl_const_real(float_ty, fval)

    if ck == CK_ZERO_SIZED:
        if expected_ty != 0:
            return self.build_default_value(expected_ty)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    if ck == CK_CLOSURE:
        // Populate local_allocas/local_types/local_sema_types from MIR locals
        // so gen_closure can find captured variables and their types.
        let closure_node = cd
        if closure_node <= 0 or closure_node >= self.pool.node_count():
            with_eprintln("warning: [ck-closure] invalid node=" ++ int_to_string(closure_node))
            return wl_get_undef(fallback_ty)
        for li in 0..body.local_count():
            let name_sym = body.local_names.get(li as i64)
            if name_sym != 0:
                let ptr_opt = self.mir_local_ptrs.get(li)
                if ptr_opt.is_some():
                    self.local_allocas.insert(name_sym, ptr_opt.unwrap())
                    let ty_opt = self.mir_local_types.get(li)
                    if ty_opt.is_some():
                        self.local_types.insert(name_sym, ty_opt.unwrap())
                let sema_ty = body.local_type_ids.get(li as i64)
                if sema_ty != 0:
                    self.local_sema_types.insert(name_sym, sema_ty)
        let closure_result = self.gen_closure(closure_node)
        return closure_result

    if ck == CK_FN:
        let fn_sym = cd
        // CK_FN sym from MirLower is in sema pool — must translate to codegen pool.
        // Direct fn_values lookup would return wrong function (pool ID collision).
        var translated_sym = fn_sym
        if fn_sym > 0 and fn_sym < self.sema.pool.symbol_texts.len() as i32:
            let sema_text = self.sema.pool.symbol_texts.get(fn_sym as i64)
            if sema_text.len() > 0:
                translated_sym = self.intern.intern(sema_text)
        let fv_opt = self.fn_values.get(translated_sym)
        if fv_opt.is_some():
            if self.debug_mir_codegen_enabled():
                let fn_name = self.function_symbol_name(translated_sym)
                with_eprintln("[ck-fn] sym=" ++ int_to_string(fn_sym) ++ " -> " ++ fn_name)
            return fv_opt.unwrap() as i64
        let fn_name = self.function_symbol_name(translated_sym)
        let found = wl_get_named_function(self.llmod, fn_name)
        if found != 0:
            if self.debug_mir_codegen_enabled():
                with_eprintln("[ck-fn] sym=" ++ int_to_string(fn_sym) ++ " -> " ++ fn_name ++ " (llmod)")
            return found
        with_eprintln("warning: [ck-fn] NOT FOUND sym=" ++ int_to_string(fn_sym) ++ " name=" ++ fn_name)
        return wl_get_undef(fallback_ty)

    wl_get_undef(fallback_ty)

fn Codegen.mir_eval_operand(self: Codegen, body: MirBody, operand_id: i32, expected_ty: i64) -> i64:
    let fallback_ty = if expected_ty != 0: expected_ty else: wl_i32_type(self.context)
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        if self.debug_fallback_enabled():
            with_eprintln("warning: [fallback] mir_eval_operand: invalid operand_id=" ++ int_to_string(operand_id))
        return wl_get_undef(fallback_ty)

    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OK_COPY or ok == OK_MOVE:
        if od < 0 or od >= body.place_locals.len() as i32:
            return wl_get_undef(fallback_ty)
        let local_id = body.place_locals.get(od as i64)
        var ptr = self.mir_place_ptr(body, od, false, 0)
        // Lazy-create alloca using sema type when local not yet allocated
        if ptr == 0 and local_id >= 0 and local_id < body.local_type_ids.len() as i32:
            let sema_ty_id = body.local_type_ids.get(local_id as i64)
            if sema_ty_id > 0:
                let sema_llvm_ty = self.mir_sema_type_to_llvm(sema_ty_id)
                if sema_llvm_ty != 0:
                    ptr = self.mir_place_ptr(body, od, true, sema_llvm_ty)
        if ptr == 0:
            return wl_get_undef(fallback_ty)
        var ptr_ty: i64 = 0
        let p_count = body.place_proj_counts.get(od as i64)
        if p_count > 0:
            // Place has projections — walk them to get the final field type
            ptr_ty = self.mir_place_projected_type(body, od)
        if ptr_ty == 0:
            let ptr_ty_opt = self.mir_local_types.get(local_id)
            if ptr_ty_opt.is_some():
                ptr_ty = ptr_ty_opt.unwrap() as i64
        // Fall back to sema type resolution when LLVM type not yet known
        if ptr_ty == 0 and local_id >= 0 and local_id < body.local_type_ids.len() as i32:
            let sema_ty = body.local_type_ids.get(local_id as i64)
            if sema_ty > 0:
                ptr_ty = self.mir_sema_type_to_llvm(sema_ty)
        if ptr_ty == 0:
            return wl_get_undef(fallback_ty)
        let loaded = wl_build_load(self.builder, ptr_ty, ptr)
        if expected_ty != 0:
            // Don't coerce between incompatible struct types — the local's
            // LLVM type (from a prior store, e.g. intrinsic result) is
            // authoritative over sema type hints that may differ
            // (e.g., VecIter.next() stores Option[T] but sema says T).
            let lk = wl_get_type_kind(ptr_ty)
            let ek = wl_get_type_kind(expected_ty)
            if lk == wl_struct_type_kind() and ek == wl_struct_type_kind() and ptr_ty != expected_ty:
                return loaded
            return self.coerce_value_to_type(loaded, expected_ty)
        return loaded

    if ok == OK_CONSTANT:
        return self.mir_const_value(body, od, expected_ty)

    wl_get_undef(fallback_ty)

fn Codegen.mir_operand_is_unsigned(self: Codegen, body: MirBody, operand_id: i32) -> bool:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return false
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OK_COPY or ok == OK_MOVE:
        if od >= 0 and od < body.place_locals.len() as i32:
            let local_id = body.place_locals.get(od as i64)
            if local_id >= 0 and local_id < body.local_type_ids.len() as i32:
                let sema_ty = body.local_type_ids.get(local_id as i64)
                if sema_ty > 0:
                    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
                    if self.mir_input.mir_get_type_kind(resolved) == TY_INT:
                        return self.mir_input.mir_get_type_d1(resolved) == 0
    false

fn Codegen.coerce_float_operand_to(self: Codegen, val: i64, target_ty: i64) -> i64:
    let val_ty = wl_type_of(val)
    if val_ty == target_ty or target_ty == 0:
        return val
    let vk = wl_get_type_kind(val_ty)
    let tk = wl_get_type_kind(target_ty)
    if (vk == wl_float_type_kind() or vk == wl_double_type_kind()) and (tk == wl_float_type_kind() or tk == wl_double_type_kind()):
        return wl_build_fp_cast(self.builder, val, target_ty)
    val

fn Codegen.mir_build_bin_op(self: Codegen, op: i32, lhs: i64, rhs: i64, is_unsigned: bool) -> i64:
    let lk = wl_get_type_kind(wl_type_of(lhs))
    let rk = wl_get_type_kind(wl_type_of(rhs))

    // Pointer arithmetic: ptr +/- int → GEP
    if lk == wl_pointer_type_kind() and rk == wl_integer_type_kind():
        if op == OP_ADD or op == OP_SUB:
            let idx_val = if op == OP_SUB: wl_build_neg(self.builder, rhs) else: rhs
            let indices: Vec[i64] = Vec.new()
            indices.push(idx_val)
            return wl_build_gep(self.builder, wl_i8_type(self.context), lhs, vec_data_i64(&indices), 1)

    if op == OP_EQ or op == OP_NEQ:
        if lk == wl_pointer_type_kind() and rk == wl_integer_type_kind():
            if wl_is_constant(rhs) != 0 and wl_const_int_sext_val(rhs) == 0:
                let cmp_rhs = wl_const_null(wl_type_of(lhs))
                return wl_build_icmp(self.builder, if op == OP_EQ: wl_int_eq() else: wl_int_ne(), lhs, cmp_rhs)
        if rk == wl_pointer_type_kind() and lk == wl_integer_type_kind():
            if wl_is_constant(lhs) != 0 and wl_const_int_sext_val(lhs) == 0:
                let cmp_lhs = wl_const_null(wl_type_of(rhs))
                return wl_build_icmp(self.builder, if op == OP_EQ: wl_int_eq() else: wl_int_ne(), cmp_lhs, rhs)

    let is_float = lk == wl_float_type_kind() or lk == wl_double_type_kind() or rk == wl_float_type_kind() or rk == wl_double_type_kind()
    if is_float:
        let common_float_ty =
            if lk == wl_double_type_kind() or rk == wl_double_type_kind():
                wl_f64_type(self.context)
            else:
                wl_f32_type(self.context)
        let lhs_float = self.coerce_float_operand_to(lhs, common_float_ty)
        let rhs_float = self.coerce_float_operand_to(rhs, common_float_ty)
        if op == OP_ADD or op == OP_ADD_WRAP: return wl_build_fadd(self.builder, lhs_float, rhs_float)
        if op == OP_SUB or op == OP_SUB_WRAP: return wl_build_fsub(self.builder, lhs_float, rhs_float)
        if op == OP_MUL or op == OP_MUL_WRAP: return wl_build_fmul(self.builder, lhs_float, rhs_float)
        if op == OP_DIV: return wl_build_fdiv(self.builder, lhs_float, rhs_float)
        if op == OP_MOD: return wl_build_frem(self.builder, lhs_float, rhs_float)
        if op == OP_EQ: return wl_build_fcmp(self.builder, wl_real_oeq(), lhs_float, rhs_float)
        if op == OP_NEQ: return wl_build_fcmp(self.builder, wl_real_one(), lhs_float, rhs_float)
        if op == OP_LT: return wl_build_fcmp(self.builder, wl_real_olt(), lhs_float, rhs_float)
        if op == OP_GT: return wl_build_fcmp(self.builder, wl_real_ogt(), lhs_float, rhs_float)
        if op == OP_LTE: return wl_build_fcmp(self.builder, wl_real_ole(), lhs_float, rhs_float)
        if op == OP_GTE: return wl_build_fcmp(self.builder, wl_real_oge(), lhs_float, rhs_float)
        return wl_get_undef(wl_i32_type(self.context))

    if op == OP_EQ or op == OP_NEQ:
        let lhs_ty = wl_type_of(lhs)
        let rhs_ty = wl_type_of(rhs)
        if lhs_ty == rhs_ty:
            let cmp_kind = wl_get_type_kind(lhs_ty)
            if cmp_kind == wl_struct_type_kind() or cmp_kind == wl_array_type_kind():
                return self.compare_aggregate_eq(lhs, rhs, op)

    // Coerce both operands to the wider integer type (never truncate)
    let lty = wl_type_of(lhs)
    let rty = wl_type_of(rhs)
    var wider_ty = lty
    if wl_get_type_kind(lty) == wl_integer_type_kind() and wl_get_type_kind(rty) == wl_integer_type_kind():
        if wl_get_int_type_width(rty) > wl_get_int_type_width(lty):
            wider_ty = rty
    let l = self.coerce_int_ext(lhs, wider_ty, is_unsigned)
    let r = self.coerce_int_ext(rhs, wider_ty, is_unsigned)
    if op == OP_ADD_WRAP: return wl_build_add(self.builder, l, r)
    if op == OP_SUB_WRAP: return wl_build_sub(self.builder, l, r)
    if op == OP_MUL_WRAP: return wl_build_mul(self.builder, l, r)
    if op == OP_ADD:
        if is_unsigned: return wl_build_add(self.builder, l, r)
        return wl_build_nsw_add(self.builder, l, r)
    if op == OP_SUB:
        if is_unsigned: return wl_build_sub(self.builder, l, r)
        return wl_build_nsw_sub(self.builder, l, r)
    if op == OP_MUL:
        if is_unsigned: return wl_build_mul(self.builder, l, r)
        return wl_build_nsw_mul(self.builder, l, r)
    if op == OP_DIV:
        if is_unsigned: return wl_build_udiv(self.builder, l, r)
        return wl_build_sdiv(self.builder, l, r)
    if op == OP_MOD:
        if is_unsigned: return wl_build_urem(self.builder, l, r)
        return wl_build_srem(self.builder, l, r)
    if op == OP_EQ: return wl_build_icmp(self.builder, wl_int_eq(), l, r)
    if op == OP_NEQ: return wl_build_icmp(self.builder, wl_int_ne(), l, r)
    if op == OP_LT:
        if is_unsigned: return wl_build_icmp(self.builder, wl_int_ult(), l, r)
        return wl_build_icmp(self.builder, wl_int_slt(), l, r)
    if op == OP_GT:
        if is_unsigned: return wl_build_icmp(self.builder, wl_int_ugt(), l, r)
        return wl_build_icmp(self.builder, wl_int_sgt(), l, r)
    if op == OP_LTE:
        if is_unsigned: return wl_build_icmp(self.builder, wl_int_ule(), l, r)
        return wl_build_icmp(self.builder, wl_int_sle(), l, r)
    if op == OP_GTE:
        if is_unsigned: return wl_build_icmp(self.builder, wl_int_uge(), l, r)
        return wl_build_icmp(self.builder, wl_int_sge(), l, r)
    if op == OP_AND or op == OP_BIT_AND: return wl_build_and(self.builder, l, r)
    if op == OP_OR or op == OP_BIT_OR: return wl_build_or(self.builder, l, r)
    if op == OP_BIT_XOR: return wl_build_xor(self.builder, l, r)
    if op == OP_SHL: return wl_build_shl(self.builder, l, r)
    if op == OP_SHR:
        if is_unsigned: return wl_build_lshr(self.builder, l, r)
        return wl_build_ashr(self.builder, l, r)
    if op == OP_CONCAT: return self.mir_str_concat(lhs, rhs)
    with_eprintln("warning: [mir-binop] unhandled binary op")
    wl_get_undef(wl_i32_type(self.context))

fn Codegen.mir_str_concat(self: Codegen, lhs: i64, rhs: i64) -> i64:
    let concat_sym = self.intern.intern("with_str_concat")
    let fv = self.fn_values.get(concat_sym)
    let ft = self.fn_fn_types.get(concat_sym)
    if fv.is_some() and ft.is_some():
        let args: Vec[i64] = Vec.new()
        args.push(lhs)
        args.push(rhs)
        return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&args), 2)
    let str_ty = self.resolve_named_type(self.intern.intern("str"))
    let param_types: Vec[i64] = Vec.new()
    param_types.push(str_ty)
    param_types.push(str_ty)
    let fn_type = wl_function_type(str_ty, vec_data_i64(&param_types), 2, 0)
    let func = wl_add_function(self.llmod, "with_str_concat", fn_type)
    self.fn_values.insert(concat_sym, func)
    self.fn_fn_types.insert(concat_sym, fn_type)
    let args: Vec[i64] = Vec.new()
    args.push(lhs)
    args.push(rhs)
    wl_build_call(self.builder, fn_type, func, vec_data_i64(&args), 2)

fn Codegen.mir_pointer_elem_llvm_type(self: Codegen, sema_ty: i32) -> i64:
    if sema_ty <= 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    let tk = self.mir_input.mir_get_type_kind(resolved)
    if tk != TY_PTR and tk != TY_REF:
        return 0
    let pointee = self.mir_input.mir_get_type_d0(resolved)
    if pointee <= 0:
        return 0
    self.mir_sema_type_to_llvm(pointee)

fn Codegen.mir_eval_rvalue(self: Codegen, body: MirBody, rval_id: i32, dest_ty: i64) -> i64:
    let fallback_ty = if dest_ty != 0: dest_ty else: wl_i32_type(self.context)
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        if self.debug_fallback_enabled():
            with_eprintln("warning: [fallback] mir_eval_rvalue: invalid rval_id=" ++ int_to_string(rval_id))
        return wl_get_undef(fallback_ty)

    let rk = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)

    if rk == RK_USE:
        return self.mir_eval_operand(body, d0, dest_ty)

    if rk == RK_BIN_OP:
        let lhs = self.mir_eval_operand(body, d1, 0)
        let rhs = self.mir_eval_operand(body, d2, 0)
        let lhs_sema = self.mir_operand_sema_type(body, d1)
        let rhs_sema = self.mir_operand_sema_type(body, d2)
        let lhs_resolved = if lhs_sema > 0: self.mir_input.mir_resolve_alias(lhs_sema) else: 0
        let rhs_resolved = if rhs_sema > 0: self.mir_input.mir_resolve_alias(rhs_sema) else: 0
        let lhs_tk = if lhs_resolved > 0: self.mir_input.mir_get_type_kind(lhs_resolved) else: 0
        let rhs_tk = if rhs_resolved > 0: self.mir_input.mir_get_type_kind(rhs_resolved) else: 0
        if d0 == OP_ADD or d0 == OP_SUB:
            if (lhs_tk == TY_PTR or lhs_tk == TY_REF) and wl_get_type_kind(wl_type_of(rhs)) == wl_integer_type_kind():
                let elem_ty = self.mir_pointer_elem_llvm_type(lhs_sema)
                let indices: Vec[i64] = Vec.new()
                indices.push(if d0 == OP_SUB: wl_build_neg(self.builder, rhs) else: rhs)
                return wl_build_gep(self.builder, if elem_ty != 0: elem_ty else: wl_i8_type(self.context), lhs, vec_data_i64(&indices), 1)
            if d0 == OP_ADD and (rhs_tk == TY_PTR or rhs_tk == TY_REF) and wl_get_type_kind(wl_type_of(lhs)) == wl_integer_type_kind():
                let elem_ty = self.mir_pointer_elem_llvm_type(rhs_sema)
                let indices: Vec[i64] = Vec.new()
                indices.push(lhs)
                return wl_build_gep(self.builder, if elem_ty != 0: elem_ty else: wl_i8_type(self.context), rhs, vec_data_i64(&indices), 1)
        let is_unsigned = self.mir_operand_is_unsigned(body, d1)
        let out = self.mir_build_bin_op(d0, lhs, rhs, is_unsigned)
        if dest_ty != 0:
            return self.coerce_value_to_type(out, dest_ty)
        return out

    if rk == RK_UN_OP:
        let arg = self.mir_eval_operand(body, d1, dest_ty)
        if d0 == UOP_NEGATE:
            let ak = wl_get_type_kind(wl_type_of(arg))
            if ak == wl_float_type_kind() or ak == wl_double_type_kind():
                return wl_build_fneg(self.builder, arg)
            return wl_build_neg(self.builder, arg)
        if d0 == UOP_NOT:
            let ak = wl_get_type_kind(wl_type_of(arg))
            if ak == wl_integer_type_kind() and wl_get_int_type_width(wl_type_of(arg)) == 1:
                return wl_build_xor(self.builder, arg, wl_const_int(wl_i1_type(self.context), 1, 0))
            return wl_build_icmp(self.builder, wl_int_eq(), arg, wl_const_int(wl_type_of(arg), 0, 0))
        return arg

    if rk == RK_REF:
        let ptr = self.mir_place_ptr(body, d1, false, 0)
        if ptr == 0:
            return wl_get_undef(fallback_ty)
        if dest_ty != 0 and wl_type_of(ptr) != dest_ty and wl_get_type_kind(dest_ty) == wl_pointer_type_kind():
            return wl_build_bitcast(self.builder, ptr, dest_ty)
        return ptr

    if rk == RK_ADDR_OF:
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr == 0:
            return wl_get_undef(fallback_ty)
        if dest_ty != 0 and wl_type_of(ptr) != dest_ty and wl_get_type_kind(dest_ty) == wl_pointer_type_kind():
            return wl_build_bitcast(self.builder, ptr, dest_ty)
        return ptr

    if rk == RK_DISCRIMINANT:
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr == 0:
            return wl_get_undef(wl_i32_type(self.context))
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return wl_get_undef(wl_i32_type(self.context))
        let local_id = body.place_locals.get(d0 as i64)
        let place_ty_opt = self.mir_local_types.get(local_id)
        if not place_ty_opt.is_some():
            return wl_get_undef(wl_i32_type(self.context))
        let place_ty = place_ty_opt.unwrap() as i64
        if wl_get_type_kind(place_ty) == wl_struct_type_kind() and wl_count_struct_elem_types(place_ty) > 0:
            let loaded = wl_build_load(self.builder, place_ty, ptr)
            return wl_build_extract_value(self.builder, loaded, 0)
        if wl_get_type_kind(place_ty) == wl_pointer_type_kind():
            let loaded_ptr = wl_build_load(self.builder, place_ty, ptr)
            let is_none = wl_build_icmp(self.builder, wl_int_eq(), loaded_ptr, wl_const_null(place_ty))
            return self.coerce_int(is_none, wl_i32_type(self.context))
        // Disc enum without payload: the value IS the discriminant
        if wl_get_type_kind(place_ty) == wl_integer_type_kind():
            return wl_build_load(self.builder, place_ty, ptr)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    if rk == RK_AGGREGATE:
        // d1 = fields_id — index into agg_field_starts/counts/operands
        let agg_fields_id = d1
        if agg_fields_id >= 0 and agg_fields_id < body.agg_field_starts.len() as i32:
            let agg_start = body.agg_field_starts.get(agg_fields_id as i64)
            let agg_count = body.agg_field_counts.get(agg_fields_id as i64)
            var struct_ty = dest_ty
            if self.debug_mir_codegen_enabled():
                with_eprintln("[mir-agg] fn=" ++ self.intern.resolve(self.current_function_name_sym) ++ " count=" ++ int_to_string(agg_count) ++ " dest_ty_kind=" ++ int_to_string(if dest_ty != 0: wl_get_type_kind(dest_ty) else: -1) ++ " dest_ty_fields=" ++ int_to_string(if dest_ty != 0 and wl_get_type_kind(dest_ty) == wl_struct_type_kind(): wl_count_struct_elem_types(dest_ty) else: -1))
            if struct_ty != 0 and wl_get_type_kind(struct_ty) == wl_array_type_kind():
                // Array aggregate: [N x T]
                let alloca = self.create_entry_alloca(struct_ty)
                wl_build_store(self.builder, self.build_default_value(struct_ty), alloca)
                let elem_ty = wl_get_element_type(struct_ty)
                for i in 0..agg_count:
                    let op_id = body.agg_field_operands.get((agg_start + i) as i64)
                    let val = self.mir_eval_operand(body, op_id, elem_ty)
                    let indices: Vec[i64] = Vec.new()
                    indices.push(wl_const_int(wl_i32_type(self.context), 0, 0))
                    indices.push(wl_const_int(wl_i32_type(self.context), i as i64, 0))
                    let gep = wl_build_gep(self.builder, struct_ty, alloca, vec_data_i64(&indices), 2)
                    wl_build_store(self.builder, self.coerce_value_to_type(val, elem_ty), gep)
                return wl_build_load(self.builder, struct_ty, alloca)
            if d0 == 1 and struct_ty != 0 and wl_get_type_kind(struct_ty) == wl_pointer_type_kind():
                if agg_count > 0:
                    let first_op = body.agg_field_operands.get(agg_start as i64)
                    let first_val = self.mir_eval_operand(body, first_op, struct_ty)
                    return self.coerce_value_to_type(first_val, struct_ty)
                return wl_const_null(struct_ty)
            // d0 == 1: enum variant construction; d2 = variant index
            if d0 == 1 and struct_ty != 0 and wl_get_type_kind(struct_ty) == wl_struct_type_kind():
                let ev_tag = d2
                let ev_alloca = self.create_entry_alloca(struct_ty)
                wl_build_store(self.builder, self.build_default_value(struct_ty), ev_alloca)
                // Store tag in field 0
                let ev_tag_ty = wl_struct_get_type_at(struct_ty, 0)
                let ev_tag_ptr = wl_build_struct_gep(self.builder, struct_ty, ev_alloca, 0)
                wl_build_store(self.builder, wl_const_int(ev_tag_ty, ev_tag as i64, 0), ev_tag_ptr)
                // Store payload in field 1 if any
                if agg_count > 0 and wl_count_struct_elem_types(struct_ty) > 1:
                    // Build payload struct type from operand types
                    let ev_payload_types: Vec[i64] = Vec.new()
                    let ev_payload_vals: Vec[i64] = Vec.new()
                    for evi in 0..agg_count:
                        let ev_op = body.agg_field_operands.get((agg_start + evi) as i64)
                        let ev_val = self.mir_eval_operand(body, ev_op, 0)
                        ev_payload_types.push(wl_type_of(ev_val))
                        ev_payload_vals.push(ev_val)
                    let ev_payload_ty = wl_struct_type(self.context, vec_data_i64(&ev_payload_types), agg_count, 0)
                    let ev_data_ptr = wl_build_struct_gep(self.builder, struct_ty, ev_alloca, 1)
                    for evi in 0..agg_count:
                        let ev_field_ptr = wl_build_struct_gep(self.builder, ev_payload_ty, ev_data_ptr, evi)
                        wl_build_store(self.builder, ev_payload_vals.get(evi as i64), ev_field_ptr)
                return wl_build_load(self.builder, struct_ty, ev_alloca)
            if struct_ty == 0 or wl_get_type_kind(struct_ty) != wl_struct_type_kind():
                // Try to construct type from operands
                if agg_count > 0:
                    let first_op = body.agg_field_operands.get(agg_start as i64)
                    let first_val = self.mir_eval_operand(body, first_op, 0)
                    let elem_types: Vec[i64] = Vec.new()
                    elem_types.push(wl_type_of(first_val))
                    for i in 1..agg_count:
                        let oi = body.agg_field_operands.get((agg_start + i) as i64)
                        let vi = self.mir_eval_operand(body, oi, 0)
                        elem_types.push(wl_type_of(vi))
                    struct_ty = wl_struct_type(self.context, vec_data_i64(&elem_types), agg_count, 0)
                    let alloca = self.create_entry_alloca(struct_ty)
                    wl_build_store(self.builder, self.build_default_value(struct_ty), alloca)
                    // Re-store the already-evaluated values
                    let gep0 = wl_build_struct_gep(self.builder, struct_ty, alloca, 0)
                    wl_build_store(self.builder, first_val, gep0)
                    for i in 1..agg_count:
                        let oi = body.agg_field_operands.get((agg_start + i) as i64)
                        let vi = self.mir_eval_operand(body, oi, 0)
                        let gepi = wl_build_struct_gep(self.builder, struct_ty, alloca, i)
                        wl_build_store(self.builder, vi, gepi)
                    return wl_build_load(self.builder, struct_ty, alloca)
                with_eprintln("error: RK_AGGREGATE with unknown dest type fn=" ++ self.intern.resolve(self.current_function_name_sym) ++ " count=" ++ int_to_string(agg_count))
                return wl_get_undef(fallback_ty)
            let alloca = self.create_entry_alloca(struct_ty)
            wl_build_store(self.builder, self.build_default_value(struct_ty), alloca)
            let struct_field_count = wl_count_struct_elem_types(struct_ty)
            for i in 0..agg_count:
                let op_id = body.agg_field_operands.get((agg_start + i) as i64)
                // Resolve field index from name sym if available
                var fi = i
                if (agg_start + i) < body.agg_field_name_syms.len() as i32:
                    let name_sym = body.agg_field_name_syms.get((agg_start + i) as i64)
                    if name_sym != 0:
                        let resolved_fi = self.mir_resolve_field_index(struct_ty, name_sym)
                        if resolved_fi >= 0:
                            fi = resolved_fi
                let llvm_fi = self.get_llvm_field_index(struct_ty, fi)
                if llvm_fi >= struct_field_count:
                    continue
                let field_ty = wl_struct_get_type_at(struct_ty, llvm_fi)
                let val = self.mir_eval_operand(body, op_id, field_ty)
                let gep = wl_build_struct_gep(self.builder, struct_ty, alloca, llvm_fi)
                wl_build_store(self.builder, self.coerce_value_to_type(val, field_ty), gep)
            return wl_build_load(self.builder, struct_ty, alloca)
        return wl_get_undef(fallback_ty)

    if rk == RK_CAST:
        let val = self.mir_eval_operand(body, d0, 0)
        let src_unsigned = self.mir_operand_is_unsigned(body, d0)
        // d1 = sema target type id
        var cast_ty = dest_ty
        if d1 > 0:
            let resolved_cast_ty = self.mir_sema_type_to_llvm(d1)
            if resolved_cast_ty != 0:
                cast_ty = resolved_cast_ty
        if cast_ty != 0 and wl_type_of(val) != cast_ty:
            let vk = wl_get_type_kind(wl_type_of(val))
            let ck = wl_get_type_kind(cast_ty)
            // Float → Int
            if (vk == wl_float_type_kind() or vk == wl_double_type_kind()) and ck == wl_integer_type_kind():
                if src_unsigned:
                    return wl_build_fp_to_ui(self.builder, val, cast_ty)
                return wl_build_fp_to_si(self.builder, val, cast_ty)
            // Int → Float
            if vk == wl_integer_type_kind() and (ck == wl_float_type_kind() or ck == wl_double_type_kind()):
                if src_unsigned:
                    return wl_build_ui_to_fp(self.builder, val, cast_ty)
                return wl_build_si_to_fp(self.builder, val, cast_ty)
            // Float → Float
            if (vk == wl_float_type_kind() or vk == wl_double_type_kind()) and (ck == wl_float_type_kind() or ck == wl_double_type_kind()):
                return wl_build_fp_cast(self.builder, val, cast_ty)
            // Ptr → Int
            if vk == wl_pointer_type_kind() and ck == wl_integer_type_kind():
                return wl_build_ptr_to_int(self.builder, val, cast_ty)
            // Int → Ptr
            if vk == wl_integer_type_kind() and ck == wl_pointer_type_kind():
                return wl_build_int_to_ptr(self.builder, val, cast_ty)
            // Int → Int: use zext for unsigned source
            if vk == wl_integer_type_kind() and ck == wl_integer_type_kind():
                return self.coerce_int_ext(val, cast_ty, src_unsigned)
            return self.coerce_value_to_type(val, cast_ty)
        return val

    if rk == RK_LEN:
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr == 0:
            return wl_const_int(wl_i64_type(self.context), 0, 0)
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return wl_const_int(wl_i64_type(self.context), 0, 0)
        let local_id = body.place_locals.get(d0 as i64)
        let place_ty_opt = self.mir_local_types.get(local_id)
        if not place_ty_opt.is_some():
            return wl_const_int(wl_i64_type(self.context), 0, 0)
        let place_ty = place_ty_opt.unwrap() as i64
        if wl_get_type_kind(place_ty) == wl_array_type_kind():
            return wl_const_int(wl_i64_type(self.context), wl_get_array_length(place_ty), 0)
        if wl_get_type_kind(place_ty) == wl_struct_type_kind() and wl_count_struct_elem_types(place_ty) > 1:
            let loaded = wl_build_load(self.builder, place_ty, ptr)
            return wl_build_extract_value(self.builder, loaded, 1)
        return wl_const_int(wl_i64_type(self.context), 0, 0)

    wl_get_undef(fallback_ty)

fn Codegen.mir_emit_drop_ptr(self: Codegen, ptr: i64, ty: i64) -> void:
    if ptr == 0 or ty == 0:
        return

    var type_sym = self.find_struct_type_by_llvm(ty)
    if type_sym == 0:
        let enum_sym = self.enum_by_llvm.get(ty)
        if enum_sym.is_some():
            type_sym = enum_sym.unwrap()
    if type_sym == 0:
        return

    let dfv = self.drop_fn_values.get(type_sym)
    let dft = self.drop_fn_types.get(type_sym)
    if not dfv.is_some() or not dft.is_some():
        return

    let value = wl_build_load(self.builder, ty, ptr)
    let args: Vec[i64] = Vec.new()
    args.push(value)
    let _ = wl_build_call(self.builder, dft.unwrap() as i64, dfv.unwrap() as i64, vec_data_i64(&args), 1)

fn Codegen.mir_emit_stmt(self: Codegen, body: MirBody, stmt_id: i32) -> bool:
    if stmt_id < 0 or stmt_id >= body.stmt_kinds.len() as i32:
        return false
    let sk = body.stmt_kinds.get(stmt_id as i64)
    let d0 = body.stmt_d0.get(stmt_id as i64)
    let d1 = body.stmt_d1.get(stmt_id as i64)

    if sk == SK_ASSIGN:
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let dst_local = body.place_locals.get(d0 as i64)
        var dst_ptr = self.mir_place_ptr(body, d0, false, 0)
        let has_projections = body.place_proj_counts.get(d0 as i64) > 0
        var dst_ty: i64 = 0
        // For projected places (field access), use the projected field's sema type
        // to get the correct LLVM type. Using the base local's type is wrong —
        // e.g., storing i32 to self.field would get ptr type from self instead of i32.
        if has_projections:
            let proj_sema = self.mir_place_sema_type(body, d0)
            if proj_sema > 0:
                dst_ty = self.mir_sema_type_to_llvm(proj_sema)
        if dst_ty == 0:
            let dst_ty_opt = self.mir_local_types.get(dst_local)
            if dst_ptr != 0 and dst_ty_opt.is_some():
                dst_ty = dst_ty_opt.unwrap() as i64
        // Resolve type via sema when LLVM type is not yet known
        if dst_ty == 0 and dst_local >= 0 and dst_local < body.local_type_ids.len() as i32:
            let sema_ty = body.local_type_ids.get(dst_local as i64)
            if sema_ty > 0:
                dst_ty = self.mir_sema_type_to_llvm(sema_ty)
            // For RK_AGGREGATE (struct construction), if sema type didn't resolve,
            // fall back to the function's return type (local 0).
            if dst_ty == 0 and d1 >= 0 and d1 < body.rval_kinds.len() as i32:
                if body.rval_kinds.get(d1 as i64) == RK_AGGREGATE:
                    let ret_ty_opt = self.mir_local_types.get(0)
                    if ret_ty_opt.is_some():
                        let ret_ty = ret_ty_opt.unwrap() as i64
                        if wl_get_type_kind(ret_ty) == wl_struct_type_kind():
                            dst_ty = ret_ty
        let value = self.mir_eval_rvalue(body, d1, dst_ty)
        if dst_ptr == 0:
            if has_projections:
                return false
            let value_ty = wl_type_of(value)
            dst_ptr = self.mir_get_or_create_local_ptr(dst_local, value_ty)
            self.mir_local_types.insert(dst_local, value_ty)
        var final_ty = dst_ty
        if final_ty == 0:
            let final_ty_opt = self.mir_local_types.get(dst_local)
            if final_ty_opt.is_some():
                final_ty = final_ty_opt.unwrap() as i64
        if final_ty == 0: return false
        var coerced = value
        if wl_type_of(value) != final_ty:
            coerced = self.coerce_value_to_type(value, final_ty)
        wl_build_store(self.builder, coerced, dst_ptr)
        return true

    if sk == SK_STORAGE_LIVE:
        // Storage markers do not require dedicated IR in this backend.
        return true

    if sk == SK_STORAGE_DEAD:
        return true

    if sk == SK_DROP:
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let local_id = body.place_locals.get(d0 as i64)
        let ty_opt = self.mir_local_types.get(local_id)
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr != 0:
            if ty_opt.is_some():
                self.mir_emit_drop_ptr(ptr, ty_opt.unwrap() as i64)
        return true

    if sk == SK_NOP:
        return true

    false

fn Codegen.mir_default_unreachable_bb_value(self: Codegen) -> i64:
    if self.mir_default_unreachable_bbs.len() as i32 > 0:
        return self.mir_default_unreachable_bbs.get(0)
    let bb = wl_append_bb(self.context, self.current_function, "mir.default.unreachable")
    self.mir_default_unreachable_bbs.push(bb)
    bb

fn Codegen.mir_try_place_ptr_for_ref(self: Codegen, body: MirBody, operand_id: i32) -> i64:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return 0
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if (ok == OK_COPY or ok == OK_MOVE) and od >= 0 and od < body.place_locals.len() as i32:
        return self.mir_place_ptr(body, od, false, 0)
    0

fn Codegen.mir_eval_call_operand(self: Codegen, body: MirBody, operand_id: i32, expected_ty: i64, call_context: str, arg_index: i32) -> i64:
    let val = self.mir_eval_operand(body, operand_id, expected_ty)
    let had_error_before = self.had_error
    let coerced = self.enforce_coerced_type(val, expected_ty, "wrong argument type")
    if self.had_error != had_error_before:
        self.debug_call_coerce_failure(call_context, 0, arg_index, 0, val, expected_ty)
    coerced

fn Codegen.mir_intrinsic_recv_ptr(self: Codegen, body: MirBody, args_id: i32) -> i64:
    // Get a pointer to the receiver (arg 0) for instance method intrinsics.
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let recv_op = body.call_arg_operands.get(arg_start as i64)
    let ok = body.operand_kinds.get(recv_op as i64)
    let od = body.operand_d0.get(recv_op as i64)
    // If operand is a place (Copy/Move), try to get its pointer directly.
    if ok == OK_COPY or ok == OK_MOVE:
        let ptr = self.mir_place_ptr(body, od, false, 0)
        if ptr != 0:
            return ptr
        // Lazy-create alloca
        let local_id = body.place_locals.get(od as i64)
        if local_id >= 0 and local_id < body.local_type_ids.len() as i32:
            let sema_ty = body.local_type_ids.get(local_id as i64)
            if sema_ty > 0:
                let llvm_ty = self.mir_sema_type_to_llvm(sema_ty)
                if llvm_ty != 0:
                    let ptr2 = self.mir_place_ptr(body, od, true, llvm_ty)
                    if ptr2 != 0:
                        return ptr2
    // Fallback: evaluate, alloca, store
    let val = self.mir_eval_operand(body, recv_op, 0)
    let alloca = wl_build_alloca(self.builder, wl_type_of(val))
    wl_build_store(self.builder, val, alloca)
    alloca

fn Codegen.mir_intrinsic_arg(self: Codegen, body: MirBody, args_id: i32, idx: i32) -> i64:
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let op_id = body.call_arg_operands.get((arg_start + idx) as i64)
    self.mir_eval_operand(body, op_id, 0)

fn Codegen.mir_extract_map_ptr(self: Codegen, recv: i64) -> i64:
    // HashMap value is either { ptr } struct or raw ptr (from field access).
    let recv_ty = wl_type_of(recv)
    if wl_get_type_kind(recv_ty) == wl_pointer_type_kind():
        return recv
    if wl_get_type_kind(recv_ty) == wl_struct_type_kind():
        return wl_build_extract_value(self.builder, recv, 0)
    recv

fn Codegen.mir_intrinsic_dest_sema_type(self: Codegen, body: MirBody, dest_place: i32) -> i32:
    if dest_place < 0 or dest_place >= body.place_locals.len() as i32:
        return 0
    let local_id = body.place_locals.get(dest_place as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    body.local_type_ids.get(local_id as i64)

fn Codegen.mir_vec_elem_size(self: Codegen, body: MirBody, dest_place: i32) -> i64:
    // Determine Vec element size from dest place sema type (TY_GENERIC_INST).
    let sema_ty = self.mir_intrinsic_dest_sema_type(body, dest_place)
    if sema_ty > 0:
        let resolved = self.mir_input.mir_resolve_alias(sema_ty)
        let tk = self.mir_input.mir_get_type_kind(resolved)
        if tk == TY_GENERIC_INST:
            let arg_count = self.mir_input.mir_get_type_d2(resolved)
            if arg_count > 0:
                let te_start = self.mir_input.mir_get_type_d1(resolved)
                let elem_tid = self.mir_input.mir_get_type_extra(te_start)
                if elem_tid > 0:
                    let elem_llvm = self.mir_sema_type_to_llvm(elem_tid)
                    if elem_llvm != 0:
                        return self.abi_size_of(elem_llvm)
    8 // default — safe for pointers, i64, str

fn Codegen.mir_index_elem_sema_type(self: Codegen, sema_ty: i32) -> i32:
    if sema_ty <= 0:
        return 0
    let resolved = self.mir_input.mir_resolve_alias(sema_ty)
    let tk = self.mir_input.mir_get_type_kind(resolved)
    if tk == TY_ARRAY or tk == TY_SLICE:
        return self.mir_input.mir_get_type_d0(resolved)
    if tk == TY_STR:
        return self.sema.ty_i32
    if tk == TY_GENERIC_INST:
        let base_sym = self.mir_input.mir_get_type_d0(resolved)
        let arg_count = self.mir_input.mir_get_type_d2(resolved)
        if base_sym > 0 and arg_count > 0 and base_sym < self.sema.pool.symbol_texts.len() as i32:
            let base_name = self.sema.pool.symbol_texts.get(base_sym as i64)
            if base_name == "Vec":
                let te_start = self.mir_input.mir_get_type_d1(resolved)
                return self.mir_input.mir_get_type_extra(te_start)
    0

fn Codegen.mir_index_elem_llvm_type(self: Codegen, sema_ty: i32, cur_ty: i64) -> i64:
    if cur_ty != 0 and wl_get_type_kind(cur_ty) == wl_array_type_kind():
        return wl_get_element_type(cur_ty)
    if sema_ty > 0:
        let resolved = self.mir_input.mir_resolve_alias(sema_ty)
        if self.mir_input.mir_get_type_kind(resolved) == TY_STR:
            return wl_i8_type(self.context)
        let elem_sema = self.mir_index_elem_sema_type(sema_ty)
        if elem_sema > 0:
            let elem_llvm = self.mir_sema_type_to_llvm(elem_sema)
            if elem_llvm != 0:
                return elem_llvm
    if cur_ty != 0:
        let vec_elem = self.find_vec_elem_type_by_llvm(cur_ty)
        if vec_elem != 0:
            return vec_elem
        if self.is_str_type(cur_ty):
            return wl_i8_type(self.context)
    0

fn Codegen.mir_operand_sema_type(self: Codegen, body: MirBody, operand_id: i32) -> i32:
    // Get the sema type for a MIR operand, handling projected places.
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok != OK_COPY and ok != OK_MOVE:
        return 0
    if od < 0 or od >= body.place_locals.len() as i32:
        return 0
    let local_id = body.place_locals.get(od as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    var ty = body.local_type_ids.get(local_id as i64)
    // Walk projections to resolve through struct fields (using sema snapshot).
    let p_count = body.place_proj_counts.get(od as i64)
    if p_count > 0:
        let p_start = body.place_proj_starts.get(od as i64)
        for pi in 0..p_count:
            let pk = body.proj_kinds.get((p_start + pi) as i64)
            let pd = body.proj_d0.get((p_start + pi) as i64)
            if pk == PK_FIELD:
                let f_resolved = self.mir_input.mir_resolve_alias(ty)
                let f_tk = self.mir_input.mir_get_type_kind(f_resolved)
                if f_tk == TY_STRUCT:
                    let f_extra = self.mir_input.mir_get_type_d1(f_resolved)
                    let f_count = self.mir_input.mir_get_type_d2(f_resolved)
                    if pd >= 0 and pd < f_count:
                        ty = self.mir_input.mir_get_type_extra(f_extra + pd * 3 + 1)
                else if f_tk == TY_GENERIC_INST:
                    let base_sym = self.mir_input.mir_get_type_name(f_resolved)
                    if base_sym != 0 and self.sema.named_types.contains(base_sym):
                        let base_tid = self.sema.named_types.get(base_sym).unwrap()
                        let b_resolved = self.mir_input.mir_resolve_alias(base_tid)
                        let b_extra = self.mir_input.mir_get_type_d1(b_resolved)
                        let b_count = self.mir_input.mir_get_type_d2(b_resolved)
                        if pd >= 0 and pd < b_count:
                            ty = self.mir_input.mir_get_type_extra(b_extra + pd * 3 + 1)
            else if pk == PK_DEREF:
                let d_resolved = self.mir_input.mir_resolve_alias(ty)
                let d_tk = self.mir_input.mir_get_type_kind(d_resolved)
                if d_tk == TY_PTR or d_tk == TY_REF:
                    ty = self.mir_input.mir_get_type_d0(d_resolved)
            else if pk == PK_INDEX:
                let elem_ty = self.mir_index_elem_sema_type(ty)
                if elem_ty > 0:
                    ty = elem_ty
            else if pk == PK_DOWNCAST:
                continue
    ty

fn Codegen.mir_place_sema_type(self: Codegen, body: MirBody, place_id: i32) -> i32:
    // Get the sema type for a MIR place, walking through field projections (using sema snapshot).
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    let local_id = body.place_locals.get(place_id as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    var ty = body.local_type_ids.get(local_id as i64)
    let p_count = body.place_proj_counts.get(place_id as i64)
    if p_count > 0:
        let p_start = body.place_proj_starts.get(place_id as i64)
        for pi in 0..p_count:
            let pk = body.proj_kinds.get((p_start + pi) as i64)
            let pd = body.proj_d0.get((p_start + pi) as i64)
            if pk == PK_FIELD:
                let f_resolved = self.mir_input.mir_resolve_alias(ty)
                let f_tk = self.mir_input.mir_get_type_kind(f_resolved)
                if f_tk == TY_STRUCT:
                    let f_extra = self.mir_input.mir_get_type_d1(f_resolved)
                    let f_count = self.mir_input.mir_get_type_d2(f_resolved)
                    if pd >= 0 and pd < f_count:
                        ty = self.mir_input.mir_get_type_extra(f_extra + pd * 3 + 1)
                else if f_tk == TY_GENERIC_INST:
                    let base_sym = self.mir_input.mir_get_type_name(f_resolved)
                    if base_sym != 0 and self.sema.named_types.contains(base_sym):
                        let base_tid = self.sema.named_types.get(base_sym).unwrap()
                        let b_resolved = self.mir_input.mir_resolve_alias(base_tid)
                        let b_extra = self.mir_input.mir_get_type_d1(b_resolved)
                        let b_count = self.mir_input.mir_get_type_d2(b_resolved)
                        if pd >= 0 and pd < b_count:
                            ty = self.mir_input.mir_get_type_extra(b_extra + pd * 3 + 1)
            else if pk == PK_DEREF:
                let d_resolved = self.mir_input.mir_resolve_alias(ty)
                let d_tk = self.mir_input.mir_get_type_kind(d_resolved)
                if d_tk == TY_PTR or d_tk == TY_REF:
                    ty = self.mir_input.mir_get_type_d0(d_resolved)
            else if pk == PK_INDEX:
                let elem_ty = self.mir_index_elem_sema_type(ty)
                if elem_ty > 0:
                    ty = elem_ty
            else if pk == PK_DOWNCAST:
                continue
    ty

fn Codegen.mir_dest_llvm_type(self: Codegen, body: MirBody, dest_place: i32) -> i64:
    // Get the LLVM type for a destination place from its sema type.
    if dest_place < 0 or dest_place >= body.place_locals.len() as i32:
        return 0
    let local_id = body.place_locals.get(dest_place as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    let sema_ty = body.local_type_ids.get(local_id as i64)
    if sema_ty <= 0:
        return 0
    self.mir_sema_type_to_llvm(sema_ty)

fn Codegen.mir_vec_elem_type(self: Codegen, body: MirBody, recv_op_id: i32) -> i64:
    // Infer Vec element LLVM type from the receiver's sema type (using snapshot).
    let sema_ty = self.mir_operand_sema_type(body, recv_op_id)
    if sema_ty > 0:
        let resolved = self.mir_input.mir_resolve_alias(sema_ty)
        let tk = self.mir_input.mir_get_type_kind(resolved)
        if tk == TY_GENERIC_INST:
            let arg_count = self.mir_input.mir_get_type_d2(resolved)
            if arg_count > 0:
                let te_start = self.mir_input.mir_get_type_d1(resolved)
                let elem_tid = self.mir_input.mir_get_type_extra(te_start)
                if elem_tid > 0:
                    return self.mir_sema_type_to_llvm(elem_tid)
    0

fn Codegen.mir_emit_intrinsic_call(self: Codegen, body: MirBody, intrinsic: i32, args_id: i32, dest_place: i32, next_bb: i32) -> bool:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let void_ty = wl_void_type(self.context)
    let arg_start = body.call_arg_starts.get(args_id as i64)
    let arg_count = body.call_arg_counts.get(args_id as i64)
    var result: i64 = 0

    if intrinsic == MIR_INTRINSIC_VEC_NEW:
        let elem_size = self.mir_vec_elem_size(body, dest_place)
        var vec_elem_ty = wl_i64_type(self.context)
        let dest_sema_new = self.mir_intrinsic_dest_sema_type(body, dest_place)
        if dest_sema_new > 0:
            let resolved_new = self.mir_input.mir_resolve_alias(dest_sema_new)
            if self.mir_input.mir_get_type_kind(resolved_new) == TY_GENERIC_INST:
                let arg_count_new = self.mir_input.mir_get_type_d2(resolved_new)
                if arg_count_new > 0:
                    let te_start_new = self.mir_input.mir_get_type_d1(resolved_new)
                    let elem_tid_new = self.mir_input.mir_get_type_extra(te_start_new)
                    if elem_tid_new > 0:
                        let elem_llvm_new = self.mir_sema_type_to_llvm(elem_tid_new)
                        if elem_llvm_new != 0:
                            vec_elem_ty = elem_llvm_new
        let vec_ty = self.get_or_create_vec_type(vec_elem_ty)
        let alloca = wl_build_alloca(self.builder, vec_ty)
        wl_build_store(self.builder, self.build_default_value(vec_ty), alloca)
        let new_fn = self.ensure_vec_runtime_fn("with_vec_new_out", void_ty, 2)
        let new_ty = self.get_vec_fn_type("with_vec_new_out", void_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(alloca)
        args.push(wl_const_int(i64_ty, elem_size, 0))
        let _ = wl_build_call(self.builder, new_ty, new_fn, vec_data_i64(&args), 2)
        result = wl_build_load(self.builder, vec_ty, alloca)

    else if intrinsic == MIR_INTRINSIC_VEC_PUSH:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let elem = self.mir_intrinsic_arg(body, args_id, 1)
        let elem_alloca = wl_build_alloca(self.builder, wl_type_of(elem))
        wl_build_store(self.builder, elem, elem_alloca)
        let push_fn = self.ensure_vec_runtime_fn("with_vec_push", void_ty, 2)
        let push_ty = self.get_vec_fn_type("with_vec_push", void_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        args.push(elem_alloca)
        result = wl_build_call(self.builder, push_ty, push_fn, vec_data_i64(&args), 2)

    else if intrinsic == MIR_INTRINSIC_VEC_GET:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let idx = self.mir_intrinsic_arg(body, args_id, 1)
        let idx64 = self.coerce_int(idx, i64_ty)
        let get_fn = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
        let get_ty = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        args.push(idx64)
        let raw_ptr = wl_build_call(self.builder, get_ty, get_fn, vec_data_i64(&args), 2)
        // Use destination place's sema type to determine element type.
        var elem_ty = self.mir_dest_llvm_type(body, dest_place)
        if elem_ty == 0:
            let recv_op = body.call_arg_operands.get(arg_start as i64)
            elem_ty = self.mir_vec_elem_type(body, recv_op)
        if elem_ty == 0:
            elem_ty = i64_ty
        result = wl_build_load(self.builder, elem_ty, raw_ptr)

    else if intrinsic == MIR_INTRINSIC_VEC_LEN:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        result = wl_build_extract_value(self.builder, recv, 1)

    else if intrinsic == MIR_INTRINSIC_VEC_SET:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let idx = self.mir_intrinsic_arg(body, args_id, 1)
        let val = self.mir_intrinsic_arg(body, args_id, 2)
        let idx64 = self.coerce_int(idx, i64_ty)
        let val32 = self.coerce_int(val, i32_ty)
        let set_fn_name = "with_vec_set_i32"
        var set_fn = wl_get_named_function(self.llmod, set_fn_name)
        let param_types: Vec[i64] = Vec.new()
        param_types.push(ptr_ty)
        param_types.push(i64_ty)
        param_types.push(i32_ty)
        let set_ty = wl_function_type(void_ty, vec_data_i64(&param_types), 3, 0)
        if set_fn == 0:
            set_fn = wl_add_function(self.llmod, set_fn_name, set_ty)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        args.push(idx64)
        args.push(val32)
        result = wl_build_call(self.builder, set_ty, set_fn, vec_data_i64(&args), 3)

    else if intrinsic == MIR_INTRINSIC_VEC_REMOVE:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let idx = self.mir_intrinsic_arg(body, args_id, 1)
        let idx64 = self.coerce_int(idx, i64_ty)
        let remove_fn = self.ensure_vec_runtime_fn("with_vec_remove", void_ty, 2)
        let remove_ty = self.get_vec_fn_type("with_vec_remove", void_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        args.push(idx64)
        result = wl_build_call(self.builder, remove_ty, remove_fn, vec_data_i64(&args), 2)

    else if intrinsic == MIR_INTRINSIC_VEC_CLEAR:
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let clear_fn = self.ensure_vec_runtime_fn("with_vec_clear", void_ty, 1)
        let clear_ty = self.get_vec_fn_type("with_vec_clear", void_ty, 1)
        let args: Vec[i64] = Vec.new()
        args.push(recv_ptr)
        result = wl_build_call(self.builder, clear_ty, clear_fn, vec_data_i64(&args), 1)

    else if intrinsic == MIR_INTRINSIC_VEC_POP:
        // Pop: get last element, remove it. Simplified: just return default.
        let recv_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let len = wl_build_extract_value(self.builder, recv, 1)
        let last_idx = wl_build_sub(self.builder, len, wl_const_int(i64_ty, 1, 0))
        let get_fn = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
        let get_ty = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
        let get_args: Vec[i64] = Vec.new()
        get_args.push(recv_ptr)
        get_args.push(last_idx)
        let raw_ptr = wl_build_call(self.builder, get_ty, get_fn, vec_data_i64(&get_args), 2)
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        let elem_ty = self.mir_vec_elem_type(body, recv_op)
        if elem_ty != 0:
            result = wl_build_load(self.builder, elem_ty, raw_ptr)
        else:
            result = wl_build_load(self.builder, i64_ty, raw_ptr)
        let remove_fn = self.ensure_vec_runtime_fn("with_vec_remove", void_ty, 2)
        let remove_ty = self.get_vec_fn_type("with_vec_remove", void_ty, 2)
        let rm_args: Vec[i64] = Vec.new()
        rm_args.push(recv_ptr)
        rm_args.push(last_idx)
        let _ = wl_build_call(self.builder, remove_ty, remove_fn, vec_data_i64(&rm_args), 2)

    else if intrinsic == MIR_INTRINSIC_MAP_NEW:
        // Determine key/val sizes from dest sema type (TY_GENERIC_INST).
        var hm_key_size: i64 = 8
        var hm_val_size: i64 = 8
        var hm_ty: i64 = 0
        let dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        if dest_sema > 0:
            let resolved = self.mir_input.mir_resolve_alias(dest_sema)
            let tk = self.mir_input.mir_get_type_kind(resolved)
            if tk == TY_GENERIC_INST:
                let gi_arg_count = self.mir_input.mir_get_type_d2(resolved)
                if gi_arg_count == 2:
                    let args_start = self.mir_input.mir_get_type_d1(resolved)
                    let key_sema = self.mir_input.mir_get_type_extra(args_start)
                    let val_sema = self.mir_input.mir_get_type_extra(args_start + 1)
                    let key_llvm = self.sema_type_to_llvm(key_sema)
                    let val_llvm = self.sema_type_to_llvm(val_sema)
                    if key_llvm != 0 and val_llvm != 0:
                        hm_key_size = self.abi_size_of(key_llvm)
                        hm_val_size = self.abi_size_of(val_llvm)
                        hm_ty = self.get_or_create_hashmap_type(key_llvm, val_llvm)
        let new_fn = self.ensure_hashmap_new_declared()
        let fn_ty = self.get_hashmap_new_fn_type()
        let new_args: Vec[i64] = Vec.new()
        new_args.push(wl_const_int(i64_ty, hm_key_size, 0))
        new_args.push(wl_const_int(i64_ty, hm_val_size, 0))
        let handle = wl_build_call(self.builder, fn_ty, new_fn, vec_data_i64(&new_args), 2)
        // Wrap handle in HashMap struct { ptr }.
        if hm_ty == 0:
            hm_ty = self.get_or_create_hashmap_type(i64_ty, i64_ty)
        let empty = self.build_default_value(hm_ty)
        result = wl_build_insert_value(self.builder, empty, handle, 0)

    else if intrinsic == MIR_INTRINSIC_MAP_INSERT:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let key = self.mir_intrinsic_arg(body, args_id, 1)
        let val = self.mir_intrinsic_arg(body, args_id, 2)
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        let val_alloca = wl_build_alloca(self.builder, wl_type_of(val))
        wl_build_store(self.builder, key, key_alloca)
        wl_build_store(self.builder, val, val_alloca)
        let is_str_val = wl_const_int(i64_ty, if self.is_str_type(wl_type_of(key)): 1 else: 0, 0)
        let fn_val = self.ensure_hm_fn("with_hashmap_insert", void_ty)
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(void_ty, vec_data_i64(&params), 4, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(val_alloca)
        args.push(is_str_val)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 4)

    else if intrinsic == MIR_INTRINSIC_MAP_GET:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let key = self.mir_intrinsic_arg(body, args_id, 1)
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        // Determine value type for the output buffer.
        // Sema gives us V (the value type), not Option[V].
        let dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        var val_ty = self.mir_sema_type_to_llvm(dest_sema)
        if val_ty == 0:
            val_ty = i64_ty
        let out_alloca = wl_build_alloca(self.builder, val_ty)
        let is_str_val = wl_const_int(i64_ty, if self.is_str_type(wl_type_of(key)): 1 else: 0, 0)
        let fn_val = self.ensure_hm_fn("with_hashmap_get", i64_ty)
        let get_params: Vec[i64] = Vec.new()
        get_params.push(ptr_ty)
        get_params.push(ptr_ty)
        get_params.push(ptr_ty)
        get_params.push(i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&get_params), 4, 0)
        let get_args: Vec[i64] = Vec.new()
        get_args.push(map_ptr)
        get_args.push(key_alloca)
        get_args.push(out_alloca)
        get_args.push(is_str_val)
        let found = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&get_args), 4)
        let val = wl_build_load(self.builder, val_ty, out_alloca)
        // Always wrap in Option[V].
        var dest_llvm = self.get_or_create_option_type(val_ty)
        if dest_llvm != 0:
            let is_found = wl_build_icmp(self.builder, wl_int_ne(), found, wl_const_int(i64_ty, 0, 0))
            let some_val = self.build_option_some(val, dest_llvm)
            let none_val = self.build_option_none(dest_llvm)
            result = wl_build_select(self.builder, is_found, some_val, none_val)
        else:
            result = val

    else if intrinsic == MIR_INTRINSIC_MAP_CONTAINS:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let key = self.mir_intrinsic_arg(body, args_id, 1)
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        let is_str_val = wl_const_int(i64_ty, if self.is_str_type(wl_type_of(key)): 1 else: 0, 0)
        let fn_val = self.ensure_hm_fn("with_hashmap_contains", i64_ty)
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&params), 3, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(is_str_val)
        let raw = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 3)
        result = wl_build_icmp(self.builder, wl_int_ne(), raw, wl_const_int(i64_ty, 0, 0))

    else if intrinsic == MIR_INTRINSIC_MAP_LEN:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let fn_val = self.ensure_hm_fn("with_hashmap_len", i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&self.make_ptr_vec()), 1, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 1)

    else if intrinsic == MIR_INTRINSIC_MAP_REMOVE:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let key = self.mir_intrinsic_arg(body, args_id, 1)
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        let is_str_val = wl_const_int(i64_ty, 0, 0)
        let fn_val = self.ensure_hm_fn("with_hashmap_remove", i64_ty)
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&params), 3, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(is_str_val)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 3)

    else if intrinsic == MIR_INTRINSIC_MAP_CLEAR:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let map_ptr = self.mir_extract_map_ptr(recv)
        let fn_val = self.ensure_hm_fn("with_hashmap_clear", void_ty)
        let fn_ty = wl_function_type(void_ty, vec_data_i64(&self.make_ptr_vec()), 1, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 1)

    else if intrinsic == MIR_INTRINSIC_OPT_IS_SOME:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let recv_tk = wl_get_type_kind(wl_type_of(recv))
        if recv_tk == wl_struct_type_kind():
            let disc = wl_build_extract_value(self.builder, recv, 0)
            // Some = tag 0, None = tag 1. is_some → tag == 0.
            result = wl_build_icmp(self.builder, wl_int_eq(), disc, wl_const_int(wl_type_of(disc), 0, 0))
        else if recv_tk == wl_pointer_type_kind():
            result = wl_build_icmp(self.builder, wl_int_ne(), recv, wl_const_null(wl_type_of(recv)))
        else:
            // Non-struct Option (e.g., raw value) — treat as always Some
            result = wl_const_int(wl_i1_type(self.context), 1, 0)

    else if intrinsic == MIR_INTRINSIC_OPT_UNWRAP:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let recv_tk = wl_get_type_kind(wl_type_of(recv))
        if recv_tk == wl_struct_type_kind():
            result = wl_build_extract_value(self.builder, recv, 1)
        else if recv_tk == wl_pointer_type_kind():
            result = recv
        else:
            // Non-struct Option — return the raw value
            result = recv

    else if intrinsic == MIR_INTRINSIC_STR_LEN:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        if self.debug_mir_codegen_enabled():
            with_eprintln("[mir-str-len] recv_ty_kind=" ++ int_to_string(wl_get_type_kind(wl_type_of(recv))))
        result = wl_build_extract_value(self.builder, recv, 1)

    else if intrinsic == MIR_INTRINSIC_STR_BYTE_AT:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let index = self.mir_intrinsic_arg(body, args_id, 1)
        let index64 = self.coerce_int(index, i64_ty)
        let fn_val = self.ensure_c_fn("with_str_byte_at", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(index64)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_byte_at", i32_ty, 2), fn_val, vec_data_i64(&args), 2)

    else if intrinsic == MIR_INTRINSIC_STR_SLICE:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let str_ptr = wl_build_extract_value(self.builder, recv, 0)
        let start = self.mir_intrinsic_arg(body, args_id, 1)
        let end = self.mir_intrinsic_arg(body, args_id, 2)
        let start64 = self.coerce_int(start, i64_ty)
        let end64 = self.coerce_int(end, i64_ty)
        let i8_ty = wl_i8_type(self.context)
        let indices: Vec[i64] = Vec.new()
        indices.push(start64)
        let new_ptr = wl_build_gep(self.builder, i8_ty, str_ptr, vec_data_i64(&indices), 1)
        let new_len = wl_build_sub(self.builder, end64, start64)
        result = self.build_str_value(new_ptr, new_len)

    else if intrinsic == MIR_INTRINSIC_STR_CONTAINS:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let needle = self.mir_intrinsic_arg(body, args_id, 1)
        let fn_val = self.ensure_c_fn("with_str_contains", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(needle)
        let raw = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_contains", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
        result = wl_build_icmp(self.builder, wl_int_ne(), raw, wl_const_int(i32_ty, 0, 0))

    else if intrinsic == MIR_INTRINSIC_STR_STARTS_WITH:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let prefix = self.mir_intrinsic_arg(body, args_id, 1)
        let fn_val = self.ensure_c_fn("with_str_starts_with", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(prefix)
        let raw = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_starts_with", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
        result = wl_build_icmp(self.builder, wl_int_ne(), raw, wl_const_int(i32_ty, 0, 0))

    else if intrinsic == MIR_INTRINSIC_STR_ENDS_WITH:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let suffix = self.mir_intrinsic_arg(body, args_id, 1)
        let fn_val = self.ensure_c_fn("with_str_ends_with", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(suffix)
        let raw = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_ends_with", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
        result = wl_build_icmp(self.builder, wl_int_ne(), raw, wl_const_int(i32_ty, 0, 0))

    else if intrinsic == MIR_INTRINSIC_STR_FIND:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let needle = self.mir_intrinsic_arg(body, args_id, 1)
        let fn_val = self.ensure_c_fn("with_str_index_of", i64_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(recv)
        args.push(needle)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_index_of", i64_ty, 2), fn_val, vec_data_i64(&args), 2)

    else if intrinsic == MIR_INTRINSIC_VECITER_NEXT:
        // VecIter[T].next() — advance iterator, return Option[T]
        // VecIter = { data_ptr: i64, len: i64, idx: i64 }
        let iter_ptr = self.mir_intrinsic_recv_ptr(body, args_id)
        let recv_op = body.call_arg_operands.get(arg_start as i64)
        // Determine element type from dest place (sema returns T, not Option[T]).
        let dest_sema = self.mir_intrinsic_dest_sema_type(body, dest_place)
        var elem_ty: i64 = 0
        if dest_sema > 0:
            let resolved_dest = self.mir_input.mir_resolve_alias(dest_sema)
            elem_ty = self.sema_type_to_llvm(resolved_dest)
        // Fall back to receiver's generic type argument.
        if elem_ty == 0:
            elem_ty = self.mir_vec_elem_type(body, recv_op)
        if elem_ty == 0:
            elem_ty = i32_ty
        let iter_fields: Vec[i64] = Vec.new()
        iter_fields.push(i64_ty)
        iter_fields.push(i64_ty)
        iter_fields.push(i64_ty)
        let iter_struct_ty = wl_struct_type(self.context, vec_data_i64(&iter_fields), 3, 0)
        let data_ptr_ptr = wl_build_struct_gep(self.builder, iter_struct_ty, iter_ptr, 0)
        let data_ptr = wl_build_load(self.builder, i64_ty, data_ptr_ptr)
        let len_ptr = wl_build_struct_gep(self.builder, iter_struct_ty, iter_ptr, 1)
        let len = wl_build_load(self.builder, i64_ty, len_ptr)
        let idx_ptr = wl_build_struct_gep(self.builder, iter_struct_ty, iter_ptr, 2)
        let idx = wl_build_load(self.builder, i64_ty, idx_ptr)
        let cond = wl_build_icmp(self.builder, wl_int_slt(), idx, len)
        let opt_type = self.get_or_create_option_type(elem_ty)
        let some_bb = wl_append_bb(self.context, self.current_function, "veciter.some")
        let none_bb = wl_append_bb(self.context, self.current_function, "veciter.none")
        let merge_bb = wl_append_bb(self.context, self.current_function, "veciter.merge")
        wl_build_cond_br(self.builder, cond, some_bb, none_bb)
        wl_position_at_end(self.builder, some_bb)
        let typed_ptr = wl_build_int_to_ptr(self.builder, data_ptr, ptr_ty)
        let gep_indices: Vec[i64] = Vec.new()
        gep_indices.push(idx)
        let elem_ptr = wl_build_gep(self.builder, elem_ty, typed_ptr, vec_data_i64(&gep_indices), 1)
        let val = wl_build_load(self.builder, elem_ty, elem_ptr)
        let next_idx = wl_build_add(self.builder, idx, wl_const_int(i64_ty, 1, 0))
        wl_build_store(self.builder, next_idx, idx_ptr)
        let some_val = self.build_option_some(val, opt_type)
        wl_build_br(self.builder, merge_bb)
        let some_bb_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, none_bb)
        let none_val = self.build_option_none(opt_type)
        wl_build_br(self.builder, merge_bb)
        let none_bb_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, merge_bb)
        let phi = wl_build_phi(self.builder, opt_type)
        let phi_vals: Vec[i64] = Vec.new()
        let phi_bbs: Vec[i64] = Vec.new()
        phi_vals.push(some_val)
        phi_vals.push(none_val)
        phi_bbs.push(some_bb_end)
        phi_bbs.push(none_bb_end)
        wl_add_incoming(phi, vec_data_i64(&phi_vals), vec_data_i64(&phi_bbs), 2)
        result = phi

    else if intrinsic == MIR_INTRINSIC_VEC_ITER:
        // Vec.iter() — create VecIter[T] from Vec
        // VecIter = { data_ptr: i64, len: i64, idx: i64 }
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let iter_fields: Vec[i64] = Vec.new()
        iter_fields.push(i64_ty)
        iter_fields.push(i64_ty)
        iter_fields.push(i64_ty)
        let iter_struct_ty = wl_struct_type(self.context, vec_data_i64(&iter_fields), 3, 0)
        let iter_alloca = wl_build_alloca(self.builder, iter_struct_ty)
        let data_raw = wl_build_extract_value(self.builder, recv, 0)
        let data_i64 = wl_build_ptr_to_int(self.builder, data_raw, i64_ty)
        let f0 = wl_build_struct_gep(self.builder, iter_struct_ty, iter_alloca, 0)
        wl_build_store(self.builder, data_i64, f0)
        let vlen = wl_build_extract_value(self.builder, recv, 1)
        let f1 = wl_build_struct_gep(self.builder, iter_struct_ty, iter_alloca, 1)
        wl_build_store(self.builder, vlen, f1)
        let f2 = wl_build_struct_gep(self.builder, iter_struct_ty, iter_alloca, 2)
        wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), f2)
        result = wl_build_load(self.builder, iter_struct_ty, iter_alloca)

    else:
        return self.mir_emit_intrinsic_call_ext(body, intrinsic, args_id, dest_place, next_bb)

    // Store result to dest place (skip for void-returning intrinsics).
    if dest_place >= 0 and result != 0:
        let result_ty = wl_type_of(result)
        if result_ty != wl_void_type(self.context):
            let dest_ptr = self.mir_place_ptr(body, dest_place, true, result_ty)
            if dest_ptr != 0:
                wl_build_store(self.builder, result, dest_ptr)

    // Branch to next bb.
    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
    true

fn Codegen.mir_emit_intrinsic_call_ext(self: Codegen, body: MirBody, intrinsic: i32, args_id: i32, dest_place: i32, next_bb: i32) -> bool:
    let i64_ty = wl_i64_type(self.context)
    var result: i64 = 0

    if intrinsic == MIR_INTRINSIC_OPT_IS_NONE:
        let recv = self.mir_intrinsic_arg(body, args_id, 0)
        let tk = wl_get_type_kind(wl_type_of(recv))
        if tk == wl_struct_type_kind():
            let disc = wl_build_extract_value(self.builder, recv, 0)
            // None = tag 1. is_none → tag != 0.
            result = wl_build_icmp(self.builder, wl_int_ne(), disc, wl_const_int(wl_type_of(disc), 0, 0))
        else if tk == wl_pointer_type_kind():
            result = wl_build_icmp(self.builder, wl_int_eq(), recv, wl_const_null(wl_type_of(recv)))
        else:
            result = wl_const_int(wl_i1_type(self.context), 0, 0)

    else if intrinsic == MIR_INTRINSIC_STR_TRIM:
        let r1 = self.mir_intrinsic_arg(body, args_id, 0)
        let t1 = wl_type_of(r1)
        let f1 = self.ensure_c_fn("with_str_trim", t1, 1)
        let a1: Vec[i64] = Vec.new()
        a1.push(r1)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_trim", t1, 1), f1, vec_data_i64(&a1), 1)

    else if intrinsic == MIR_INTRINSIC_STR_TO_UPPER:
        let r2 = self.mir_intrinsic_arg(body, args_id, 0)
        let t2 = wl_type_of(r2)
        let f2 = self.ensure_c_fn("with_str_to_upper", t2, 1)
        let a2: Vec[i64] = Vec.new()
        a2.push(r2)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_to_upper", t2, 1), f2, vec_data_i64(&a2), 1)

    else if intrinsic == MIR_INTRINSIC_STR_TO_LOWER:
        let r3 = self.mir_intrinsic_arg(body, args_id, 0)
        let t3 = wl_type_of(r3)
        let f3 = self.ensure_c_fn("with_str_to_lower", t3, 1)
        let a3: Vec[i64] = Vec.new()
        a3.push(r3)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_to_lower", t3, 1), f3, vec_data_i64(&a3), 1)

    else if intrinsic == MIR_INTRINSIC_STR_REPLACE:
        let r4 = self.mir_intrinsic_arg(body, args_id, 0)
        let t4 = wl_type_of(r4)
        let s4a = self.mir_intrinsic_arg(body, args_id, 1)
        let s4b = self.mir_intrinsic_arg(body, args_id, 2)
        let f4 = self.ensure_c_fn("with_str_replace", t4, 3)
        let a4: Vec[i64] = Vec.new()
        a4.push(r4)
        a4.push(s4a)
        a4.push(s4b)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_replace", t4, 3), f4, vec_data_i64(&a4), 3)

    else if intrinsic == MIR_INTRINSIC_STR_SPLIT:
        let r6 = self.mir_intrinsic_arg(body, args_id, 0)
        let t6 = wl_type_of(r6)
        let d6 = self.mir_intrinsic_arg(body, args_id, 1)
        let vt6 = self.get_or_create_vec_type(t6)
        let out6 = self.create_entry_alloca(vt6)
        let f6 = self.ensure_c_fn("with_str_split_vec", wl_void_type(self.context), 3)
        let p6: Vec[i64] = Vec.new()
        p6.push(wl_ptr_type(self.context))
        p6.push(t6)
        p6.push(t6)
        let ft6 = wl_function_type(wl_void_type(self.context), vec_data_i64(&p6), 3, 0)
        let a6: Vec[i64] = Vec.new()
        a6.push(out6)
        a6.push(r6)
        a6.push(d6)
        let _ = wl_build_call(self.builder, ft6, f6, vec_data_i64(&a6), 3)
        result = wl_build_load(self.builder, vt6, out6)

    else if intrinsic == MIR_INTRINSIC_STR_INDEX_OF:
        let r5 = self.mir_intrinsic_arg(body, args_id, 0)
        let n5 = self.mir_intrinsic_arg(body, args_id, 1)
        let f5 = self.ensure_c_fn("with_str_index_of", i64_ty, 2)
        let a5: Vec[i64] = Vec.new()
        a5.push(r5)
        a5.push(n5)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_index_of", i64_ty, 2), f5, vec_data_i64(&a5), 2)

    else if intrinsic == MIR_INTRINSIC_MAP_INCREMENT:
        let r7 = self.mir_intrinsic_arg(body, args_id, 0)
        let mp7 = self.mir_extract_map_ptr(r7)
        let k7 = self.mir_intrinsic_arg(body, args_id, 1)
        let ka7 = wl_build_alloca(self.builder, wl_type_of(k7))
        wl_build_store(self.builder, k7, ka7)
        let is7 = wl_const_int(i64_ty, if self.is_str_type(wl_type_of(k7)): 1 else: 0, 0)
        let f7 = self.ensure_hm_fn("with_hashmap_increment", wl_void_type(self.context))
        let p7: Vec[i64] = Vec.new()
        p7.push(wl_ptr_type(self.context))
        p7.push(wl_ptr_type(self.context))
        p7.push(i64_ty)
        let ft7 = wl_function_type(wl_void_type(self.context), vec_data_i64(&p7), 3, 0)
        let a7: Vec[i64] = Vec.new()
        a7.push(mp7)
        a7.push(ka7)
        a7.push(is7)
        let _ = wl_build_call(self.builder, ft7, f7, vec_data_i64(&a7), 3)
        result = 0

    else if intrinsic == MIR_INTRINSIC_STR_REPEAT:
        let sr_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let sr_n = self.mir_intrinsic_arg(body, args_id, 1)
        let sr_n64 = self.coerce_int(sr_n, i64_ty)
        let sr_ty = wl_type_of(sr_recv)
        let sr_fn = self.ensure_c_fn("with_str_repeat", sr_ty, 2)
        let sr_args: Vec[i64] = Vec.new()
        sr_args.push(sr_recv)
        sr_args.push(sr_n64)
        result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_repeat", sr_ty, 2), sr_fn, vec_data_i64(&sr_args), 2)

    else if intrinsic == MIR_INTRINSIC_ARR_LEN:
        // Array.len() returns the compile-time length of the array type
        let al_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let al_ty = wl_type_of(al_recv)
        var al_len = 0
        if wl_get_type_kind(al_ty) == wl_array_type_kind():
            al_len = wl_get_array_length(al_ty) as i32
        result = wl_const_int(wl_i32_type(self.context), al_len as i64, 0)

    else if intrinsic == MIR_INTRINSIC_OPT_FILTER:
        result = self.mir_emit_opt_filter(body, args_id)

    else if intrinsic == MIR_INTRINSIC_VEC_MAP:
        result = self.mir_emit_vec_map(body, args_id)
    else if intrinsic == MIR_INTRINSIC_VEC_FILTER:
        result = self.mir_emit_vec_filter(body, args_id)
    else if intrinsic == MIR_INTRINSIC_VEC_FOLD:
        result = self.mir_emit_vec_fold(body, args_id)
    else if intrinsic == MIR_INTRINSIC_VEC_CONTAINS:
        result = wl_const_int(wl_i1_type(self.context), 0, 0)

    else if intrinsic == MIR_INTRINSIC_VEC_JOIN:
        let vj_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let vj_sep = self.mir_intrinsic_arg(body, args_id, 1)
        let vj_str_sym = self.intern.intern("str")
        let vj_str_ty = self.struct_llvm_types.get(self.struct_type_map.get(vj_str_sym).unwrap() as i64)
        let vj_ptr_ty = wl_ptr_type(self.context)
        let vj_fn = self.ensure_c_fn("with_vec_str_join", vj_str_ty, 2)
        let vj_alloca = wl_build_alloca(self.builder, wl_type_of(vj_recv))
        wl_build_store(self.builder, vj_recv, vj_alloca)
        let vj_params: Vec[i64] = Vec.new()
        vj_params.push(vj_ptr_ty)
        vj_params.push(vj_str_ty)
        let vj_ft = wl_function_type(vj_str_ty, vec_data_i64(&vj_params), 2, 0)
        let vj_args: Vec[i64] = Vec.new()
        vj_args.push(vj_alloca)
        vj_args.push(vj_sep)
        result = wl_build_call(self.builder, vj_ft, vj_fn, vec_data_i64(&vj_args), 2)

    else if intrinsic == MIR_INTRINSIC_DYN_DOWNCAST:
        // Extract concrete value from dyn trait object.
        // Args: (fat_ptr, type_sym_as_int)
        let dd_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let dd_type_sym_val = self.mir_intrinsic_arg(body, args_id, 1)
        let dd_type_sym = wl_const_int_sext_val(dd_type_sym_val) as i32
        // Translate AST pool sym to codegen intern pool sym
        var dd_cg_type_sym = dd_type_sym
        if dd_type_sym > 0 and dd_type_sym < self.sema.pool.symbol_texts.len() as i32:
            let dd_text = self.sema.pool.symbol_texts.get(dd_type_sym as i64)
            if dd_text.len() > 0:
                dd_cg_type_sym = self.intern.intern(dd_text)
        // Extract data_ptr from fat pointer (field 0)
        let dd_data_ptr = wl_build_extract_value(self.builder, dd_recv, 0)
        // Load concrete struct from data_ptr
        let dd_st = self.struct_type_map.get(dd_cg_type_sym)
        if dd_st.is_some():
            let dd_concrete_ty = self.struct_llvm_types.get(dd_st.unwrap() as i64)
            result = wl_build_load(self.builder, dd_concrete_ty, dd_data_ptr)
        else:
            result = wl_build_load(self.builder, wl_i32_type(self.context), dd_data_ptr)

    else if intrinsic == MIR_INTRINSIC_DYN_VTABLE_CMP:
        // Compare vtable pointer of dyn trait object against expected vtable.
        // Args: (fat_ptr, type_sym_as_int, trait_sym_as_int)
        let dv_recv = self.mir_intrinsic_arg(body, args_id, 0)
        let dv_type_sym_val = self.mir_intrinsic_arg(body, args_id, 1)
        let dv_trait_sym_val = self.mir_intrinsic_arg(body, args_id, 2)
        // Extract type_sym and trait_sym from constant int values
        let dv_type_sym = wl_const_int_sext_val(dv_type_sym_val) as i32
        let dv_trait_sym = wl_const_int_sext_val(dv_trait_sym_val) as i32
        // Translate AST pool syms to codegen intern pool syms
        var dv_cg_type_sym = dv_type_sym
        if dv_type_sym > 0 and dv_type_sym < self.sema.pool.symbol_texts.len() as i32:
            let dv_text = self.sema.pool.symbol_texts.get(dv_type_sym as i64)
            if dv_text.len() > 0:
                dv_cg_type_sym = self.intern.intern(dv_text)
        var dv_cg_trait_sym = dv_trait_sym
        if dv_trait_sym > 0 and dv_trait_sym < self.sema.pool.symbol_texts.len() as i32:
            let dv_tt = self.sema.pool.symbol_texts.get(dv_trait_sym as i64)
            if dv_tt.len() > 0:
                dv_cg_trait_sym = self.intern.intern(dv_tt)
        // Look up vtable global
        let dv_key = codegen_hash_type_trait_key(dv_cg_type_sym, dv_cg_trait_sym)
        let dv_vt_opt = self.vtable_globals.get(dv_key)
        if dv_vt_opt.is_some():
            let dv_expected_vt = dv_vt_opt.unwrap() as i64
            // Extract vtable_ptr from fat pointer (field 1)
            let dv_vtable_ptr = wl_build_extract_value(self.builder, dv_recv, 1)
            // Compare: ptr_to_int(vtable_ptr) == ptr_to_int(expected)
            let dv_vt_int = wl_build_ptr_to_int(self.builder, dv_vtable_ptr, i64_ty)
            let dv_exp_int = wl_build_ptr_to_int(self.builder, dv_expected_vt, i64_ty)
            result = wl_build_icmp(self.builder, wl_int_eq(), dv_vt_int, dv_exp_int)
        else:
            result = wl_const_int(wl_i1_type(self.context), 0, 0)

    else:
        return false

    if dest_place >= 0 and result != 0:
        let rt = wl_type_of(result)
        if rt != wl_void_type(self.context):
            let dp = self.mir_place_ptr(body, dest_place, true, rt)
            if dp != 0:
                wl_build_store(self.builder, result, dp)
    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
    true

fn Codegen.mir_emit_opt_filter(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let ptr_ty = wl_ptr_type(self.context)
    let i1_ty = wl_i1_type(self.context)
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
    let obj_ty = wl_type_of(recv)
    let recv_tk = wl_get_type_kind(obj_ty)
    if recv_tk != wl_struct_type_kind() and recv_tk != wl_pointer_type_kind():
        return recv
    let payload_ty = if recv_tk == wl_pointer_type_kind(): obj_ty else: self.find_option_payload_type_by_llvm(obj_ty)
    let elem_ty = if payload_ty != 0: payload_ty else: wl_i32_type(self.context)
    let is_some = if recv_tk == wl_pointer_type_kind():
        wl_build_icmp(self.builder, wl_int_ne(), recv, wl_const_null(obj_ty))
    else:
        let disc = wl_build_extract_value(self.builder, recv, 0)
        wl_build_icmp(self.builder, wl_int_eq(), disc, wl_const_int(wl_type_of(disc), 0, 0))
    let fn_val = self.mir_intrinsic_arg(body, args_id, 1)
    let cty = wl_type_of(fn_val)
    var fn_ptr = fn_val
    var ctx_ptr: i64 = 0
    var is_fat = 0
    if wl_get_type_kind(cty) == wl_struct_type_kind() and wl_count_struct_elem_types(cty) == 2:
        fn_ptr = wl_build_extract_value(self.builder, fn_val, 0)
        ctx_ptr = wl_build_extract_value(self.builder, fn_val, 1)
        is_fat = 1
    var fn_ty: i64 = 0
    if is_fat != 0:
        let fp: Vec[i64] = Vec.new()
        fp.push(ptr_ty)
        fp.push(elem_ty)
        fn_ty = wl_function_type(i1_ty, vec_data_i64(&fp), 2, 0)
    else:
        fn_ty = wl_global_get_value_type(fn_ptr)
    let filt_then = wl_append_bb(self.context, self.current_function, "of.some")
    let filt_else = wl_append_bb(self.context, self.current_function, "of.none")
    let filt_check = wl_append_bb(self.context, self.current_function, "of.check")
    let filt_merge = wl_append_bb(self.context, self.current_function, "of.merge")
    wl_build_cond_br(self.builder, is_some, filt_then, filt_else)
    wl_position_at_end(self.builder, filt_then)
    let payload = if recv_tk == wl_pointer_type_kind(): recv else: wl_build_extract_value(self.builder, recv, 1)
    let filt_args: Vec[i64] = Vec.new()
    if is_fat != 0:
        filt_args.push(ctx_ptr)
    filt_args.push(payload)
    let filt_arg_count = if is_fat != 0: 2 else: 1
    let pred_result = wl_build_call(self.builder, fn_ty, fn_ptr, vec_data_i64(&filt_args), filt_arg_count)
    var filt_bool = pred_result
    if wl_type_of(pred_result) != wl_i1_type(self.context):
        filt_bool = wl_build_icmp(self.builder, wl_int_ne(), pred_result, wl_const_int(wl_type_of(pred_result), 0, 0))
    wl_build_cond_br(self.builder, filt_bool, filt_check, filt_else)
    wl_position_at_end(self.builder, filt_check)
    wl_build_br(self.builder, filt_merge)
    let check_end = wl_get_insert_block(self.builder)
    wl_position_at_end(self.builder, filt_else)
    let filt_none = if recv_tk == wl_pointer_type_kind(): wl_const_null(obj_ty) else: self.build_option_none(obj_ty)
    wl_build_br(self.builder, filt_merge)
    let else_end = wl_get_insert_block(self.builder)
    wl_position_at_end(self.builder, filt_merge)
    let filt_phi = wl_build_phi(self.builder, obj_ty)
    let phi_vals: Vec[i64] = Vec.new()
    let phi_bbs: Vec[i64] = Vec.new()
    phi_vals.push(recv)
    phi_bbs.push(check_end)
    phi_vals.push(filt_none)
    phi_bbs.push(else_end)
    wl_add_incoming(filt_phi, vec_data_i64(&phi_vals), vec_data_i64(&phi_bbs), 2)
    filt_phi

fn Codegen.mir_emit_vec_map(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let void_ty = wl_void_type(self.context)
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
    let fn_val = self.mir_intrinsic_arg(body, args_id, 1)
    let cty = wl_type_of(fn_val)
    var fn_ptr = fn_val
    var ctx_ptr: i64 = 0
    var is_fat = 0
    if wl_get_type_kind(cty) == wl_struct_type_kind() and wl_count_struct_elem_types(cty) == 2:
        fn_ptr = wl_build_extract_value(self.builder, fn_val, 0)
        ctx_ptr = wl_build_extract_value(self.builder, fn_val, 1)
        is_fat = 1
    var elem_ty = i32_ty
    var fn_ty: i64 = 0
    var ret_ty: i64 = 0
    if is_fat != 0:
        // Fat pointer closure: fn_ptr is extract_value, not a global.
        // Build fn_ty from closure calling convention: fn(ptr, elem) -> i32
        let fp: Vec[i64] = Vec.new()
        fp.push(ptr_ty)
        fp.push(elem_ty)
        fn_ty = wl_function_type(i32_ty, vec_data_i64(&fp), 2, 0)
        ret_ty = i32_ty
    else:
        fn_ty = wl_global_get_value_type(fn_ptr)
        ret_ty = wl_get_return_type(fn_ty)
    let len = wl_build_extract_value(self.builder, recv, 1)
    let rvt = self.get_or_create_vec_type(ret_ty)
    let ra = self.create_entry_alloca(rvt)
    wl_build_store(self.builder, self.build_default_value(rvt), ra)
    let nf = self.ensure_vec_runtime_fn("with_vec_new_out", void_ty, 2)
    let nt = self.get_vec_fn_type("with_vec_new_out", void_ty, 2)
    let na: Vec[i64] = Vec.new()
    na.push(ra)
    na.push(wl_const_int(i64_ty, self.abi_size_of(ret_ty), 0))
    let _ = wl_build_call(self.builder, nt, nf, vec_data_i64(&na), 2)
    let sa = self.create_entry_alloca(wl_type_of(recv))
    wl_build_store(self.builder, recv, sa)
    let ctr = self.create_entry_alloca(i64_ty)
    wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), ctr)
    let tmp = self.create_entry_alloca(ret_ty)
    let cb = wl_append_bb(self.context, self.current_function, "m.c")
    let bb = wl_append_bb(self.context, self.current_function, "m.b")
    let ib = wl_append_bb(self.context, self.current_function, "m.i")
    let eb = wl_append_bb(self.context, self.current_function, "m.e")
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, cb)
    let cv = wl_build_load(self.builder, i64_ty, ctr)
    wl_build_cond_br(self.builder, wl_build_icmp(self.builder, wl_int_slt(), cv, len), bb, eb)
    wl_position_at_end(self.builder, bb)
    let gf = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
    let gt = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
    let ga: Vec[i64] = Vec.new()
    ga.push(sa)
    ga.push(wl_build_load(self.builder, i64_ty, ctr))
    let ep = wl_build_call(self.builder, gt, gf, vec_data_i64(&ga), 2)
    let el = wl_build_load(self.builder, elem_ty, ep)
    let ca: Vec[i64] = Vec.new()
    if is_fat != 0: ca.push(ctx_ptr)
    ca.push(el)
    let cc = if is_fat != 0: 2 else: 1
    let rv = wl_build_call(self.builder, fn_ty, fn_ptr, vec_data_i64(&ca), cc)
    wl_build_store(self.builder, rv, tmp)
    let pf = self.ensure_vec_runtime_fn("with_vec_push", void_ty, 2)
    let pt = self.get_vec_fn_type("with_vec_push", void_ty, 2)
    let pa: Vec[i64] = Vec.new()
    pa.push(ra)
    pa.push(tmp)
    let _ = wl_build_call(self.builder, pt, pf, vec_data_i64(&pa), 2)
    wl_build_br(self.builder, ib)
    wl_position_at_end(self.builder, ib)
    wl_build_store(self.builder, wl_build_add(self.builder, wl_build_load(self.builder, i64_ty, ctr), wl_const_int(i64_ty, 1, 0)), ctr)
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, eb)
    wl_build_load(self.builder, rvt, ra)

fn Codegen.mir_emit_vec_filter(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let void_ty = wl_void_type(self.context)
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
    let fn_val = self.mir_intrinsic_arg(body, args_id, 1)
    let cty = wl_type_of(fn_val)
    var fn_ptr = fn_val
    var ctx_ptr: i64 = 0
    var is_fat = 0
    if wl_get_type_kind(cty) == wl_struct_type_kind() and wl_count_struct_elem_types(cty) == 2:
        fn_ptr = wl_build_extract_value(self.builder, fn_val, 0)
        ctx_ptr = wl_build_extract_value(self.builder, fn_val, 1)
        is_fat = 1
    var elem_ty = i32_ty
    var fn_ty: i64 = 0
    if is_fat != 0:
        let fp: Vec[i64] = Vec.new()
        fp.push(ptr_ty)
        fp.push(elem_ty)
        fn_ty = wl_function_type(i32_ty, vec_data_i64(&fp), 2, 0)
    else:
        fn_ty = wl_global_get_value_type(fn_ptr)
    let len = wl_build_extract_value(self.builder, recv, 1)
    let vt = self.get_or_create_vec_type(elem_ty)
    let ra = self.create_entry_alloca(vt)
    wl_build_store(self.builder, self.build_default_value(vt), ra)
    let nf = self.ensure_vec_runtime_fn("with_vec_new_out", void_ty, 2)
    let nt = self.get_vec_fn_type("with_vec_new_out", void_ty, 2)
    let na: Vec[i64] = Vec.new()
    na.push(ra)
    na.push(wl_const_int(i64_ty, self.abi_size_of(elem_ty), 0))
    let _ = wl_build_call(self.builder, nt, nf, vec_data_i64(&na), 2)
    let sa = self.create_entry_alloca(wl_type_of(recv))
    wl_build_store(self.builder, recv, sa)
    let ctr = self.create_entry_alloca(i64_ty)
    wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), ctr)
    let tmp = self.create_entry_alloca(elem_ty)
    let cb = wl_append_bb(self.context, self.current_function, "f.c")
    let bb = wl_append_bb(self.context, self.current_function, "f.b")
    let pb = wl_append_bb(self.context, self.current_function, "f.p")
    let ib = wl_append_bb(self.context, self.current_function, "f.i")
    let eb = wl_append_bb(self.context, self.current_function, "f.e")
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, cb)
    let cv = wl_build_load(self.builder, i64_ty, ctr)
    wl_build_cond_br(self.builder, wl_build_icmp(self.builder, wl_int_slt(), cv, len), bb, eb)
    wl_position_at_end(self.builder, bb)
    let gf = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
    let gt = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
    let ga: Vec[i64] = Vec.new()
    ga.push(sa)
    ga.push(wl_build_load(self.builder, i64_ty, ctr))
    let ep = wl_build_call(self.builder, gt, gf, vec_data_i64(&ga), 2)
    let el = wl_build_load(self.builder, elem_ty, ep)
    let ca: Vec[i64] = Vec.new()
    if is_fat != 0: ca.push(ctx_ptr)
    ca.push(el)
    let cc = if is_fat != 0: 2 else: 1
    let pred = wl_build_call(self.builder, fn_ty, fn_ptr, vec_data_i64(&ca), cc)
    wl_build_cond_br(self.builder, wl_build_icmp(self.builder, wl_int_ne(), pred, wl_const_int(wl_type_of(pred), 0, 0)), pb, ib)
    wl_position_at_end(self.builder, pb)
    wl_build_store(self.builder, el, tmp)
    let pf = self.ensure_vec_runtime_fn("with_vec_push", void_ty, 2)
    let pt = self.get_vec_fn_type("with_vec_push", void_ty, 2)
    let pa: Vec[i64] = Vec.new()
    pa.push(ra)
    pa.push(tmp)
    let _ = wl_build_call(self.builder, pt, pf, vec_data_i64(&pa), 2)
    wl_build_br(self.builder, ib)
    wl_position_at_end(self.builder, ib)
    wl_build_store(self.builder, wl_build_add(self.builder, wl_build_load(self.builder, i64_ty, ctr), wl_const_int(i64_ty, 1, 0)), ctr)
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, eb)
    wl_build_load(self.builder, vt, ra)

fn Codegen.mir_emit_vec_fold(self: Codegen, body: MirBody, args_id: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let recv = self.mir_intrinsic_arg(body, args_id, 0)
    let init = self.mir_intrinsic_arg(body, args_id, 1)
    let fn_val = self.mir_intrinsic_arg(body, args_id, 2)
    let cty = wl_type_of(fn_val)
    var fn_ptr = fn_val
    var ctx_ptr: i64 = 0
    var is_fat = 0
    if wl_get_type_kind(cty) == wl_struct_type_kind() and wl_count_struct_elem_types(cty) == 2:
        fn_ptr = wl_build_extract_value(self.builder, fn_val, 0)
        ctx_ptr = wl_build_extract_value(self.builder, fn_val, 1)
        is_fat = 1
    var fn_ty: i64 = 0
    if is_fat != 0:
        // Fat pointer closure: fn(ptr, acc, elem) -> i32
        let fp: Vec[i64] = Vec.new()
        fp.push(ptr_ty)
        fp.push(i32_ty)
        fp.push(i32_ty)
        fn_ty = wl_function_type(i32_ty, vec_data_i64(&fp), 3, 0)
    else:
        fn_ty = wl_global_get_value_type(fn_ptr)
    let at = wl_type_of(init)
    var elem_ty = i32_ty
    let len = wl_build_extract_value(self.builder, recv, 1)
    let sa = self.create_entry_alloca(wl_type_of(recv))
    wl_build_store(self.builder, recv, sa)
    let aa = self.create_entry_alloca(at)
    wl_build_store(self.builder, init, aa)
    let ctr = self.create_entry_alloca(i64_ty)
    wl_build_store(self.builder, wl_const_int(i64_ty, 0, 0), ctr)
    let cb = wl_append_bb(self.context, self.current_function, "o.c")
    let bb = wl_append_bb(self.context, self.current_function, "o.b")
    let ib = wl_append_bb(self.context, self.current_function, "o.i")
    let eb = wl_append_bb(self.context, self.current_function, "o.e")
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, cb)
    let cv = wl_build_load(self.builder, i64_ty, ctr)
    wl_build_cond_br(self.builder, wl_build_icmp(self.builder, wl_int_slt(), cv, len), bb, eb)
    wl_position_at_end(self.builder, bb)
    let gf = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
    let gt = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
    let ga: Vec[i64] = Vec.new()
    ga.push(sa)
    ga.push(wl_build_load(self.builder, i64_ty, ctr))
    let ep = wl_build_call(self.builder, gt, gf, vec_data_i64(&ga), 2)
    let el = wl_build_load(self.builder, elem_ty, ep)
    let ca_val = wl_build_load(self.builder, at, aa)
    let ca: Vec[i64] = Vec.new()
    if is_fat != 0: ca.push(ctx_ptr)
    ca.push(ca_val)
    ca.push(el)
    let cc = if is_fat != 0: 3 else: 2
    let nv = wl_build_call(self.builder, fn_ty, fn_ptr, vec_data_i64(&ca), cc)
    wl_build_store(self.builder, nv, aa)
    wl_build_br(self.builder, ib)
    wl_position_at_end(self.builder, ib)
    wl_build_store(self.builder, wl_build_add(self.builder, wl_build_load(self.builder, i64_ty, ctr), wl_const_int(i64_ty, 1, 0)), ctr)
    wl_build_br(self.builder, cb)
    wl_position_at_end(self.builder, eb)
    wl_build_load(self.builder, at, aa)

fn Codegen.mir_emit_call_term(self: Codegen, body: MirBody, callee_operand: i32, args_id: i32, dest_place: i32, next_bb: i32) -> bool:
    // Check for intrinsic-tagged calls (Vec/HashMap/Option builtins).
    // These have meaningless CK_FN syms — dispatch by intrinsic kind instead.
    let mir_intrinsic = body.call_intrinsic(args_id)
    if self.debug_mir_codegen_enabled():
        with_eprintln("[mir-call-pre] intrinsic=" ++ int_to_string(mir_intrinsic) ++ " callee_op=" ++ int_to_string(callee_operand) ++ " args_id=" ++ int_to_string(args_id) ++ " dest=" ++ int_to_string(dest_place))
    if mir_intrinsic == MIR_INTRINSIC_GENERIC_CALL:
        let gc_node = body.call_ast_node(args_id)
        if gc_node > 0:
            // Extract callee sym from CK_FN constant
            let gc_co_k = body.operand_kinds.get(callee_operand as i64)
            let gc_co_d = body.operand_d0.get(callee_operand as i64)
            var gc_callee_sym = 0
            if gc_co_k == OK_CONSTANT and gc_co_d >= 0 and gc_co_d < body.const_kinds.len() as i32:
                gc_callee_sym = body.const_d0.get(gc_co_d as i64)

            // Generic function call — eval MIR args, call monomorphize directly
            let gc_gf = self.generic_fns.get(gc_callee_sym)
            if gc_gf.is_some() and gc_callee_sym > 0:
                let gc_mir_start = body.call_arg_starts.get(args_id as i64)
                let gc_mir_count = body.call_arg_counts.get(args_id as i64)
                let gc_as = self.pool.get_data1(gc_node)
                let gc_arg_vals: Vec[i64] = Vec.new()
                let gc_arg_tys: Vec[i64] = Vec.new()
                let gc_arg_nodes: Vec[i32] = Vec.new()
                for gc_ai in 0..gc_mir_count:
                    let gc_arg_nd = self.pool.get_extra(gc_as + gc_ai)
                    gc_arg_nodes.push(gc_arg_nd)
                    let gc_op = body.call_arg_operands.get((gc_mir_start + gc_ai) as i64)
                    let gc_val = self.mir_eval_operand(body, gc_op, 0)
                    gc_arg_vals.push(gc_val)
                    gc_arg_tys.push(wl_type_of(gc_val))
                let gc_result = self.monomorphize_generic_call_core(gc_callee_sym, gc_gf.unwrap(), gc_as, gc_mir_count, gc_node, gc_arg_vals, gc_arg_tys, gc_arg_nodes)
                if dest_place >= 0 and gc_result != 0:
                    let gc_ret_ty = wl_type_of(gc_result)
                    if gc_ret_ty != wl_void_type(self.context):
                        let gc_local = body.place_locals.get(dest_place as i64)
                        let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                        wl_build_store(self.builder, gc_result, gc_alloca)
                        self.mir_local_ptrs.insert(gc_local, gc_alloca)
                        self.mir_local_types.insert(gc_local, gc_ret_ty)
                if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                    let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                    wl_build_br(self.builder, gc_next_val)
                return true

            // Handle builtins directly (no gen_expr needed)
            if gc_callee_sym > 0:
                let gc_fn_name = self.intern.resolve(gc_callee_sym)
                let gc_arg_count = self.pool.get_data2(gc_node)
                if gc_fn_name == "src" and gc_arg_count == 0:
                    let gc_result = self.gen_src_intrinsic(gc_node)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true
                if gc_fn_name == "transmute":
                    let gc_result = self.gen_transmute(gc_node, body, args_id)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true
                if gc_fn_name == "sizeof" or gc_fn_name == "size_of" or gc_fn_name == "alignof" or gc_fn_name == "align_of":
                    let gc_result = self.gen_sizeof_alignof(gc_fn_name, gc_node)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true
                if gc_fn_name == "nameof" or gc_fn_name == "type_name":
                    let gc_result = self.gen_nameof(gc_node)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true
                if gc_fn_name == "embed_file" and gc_arg_count == 1:
                    let gc_result = self.gen_embed_file(gc_node)
                    if dest_place >= 0 and gc_result != 0:
                        let gc_ret_ty = wl_type_of(gc_result)
                        if gc_ret_ty != wl_void_type(self.context):
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, gc_ret_ty)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                        wl_build_br(self.builder, gc_next_val)
                    return true

                // Channel builtins: Channel(cap), send(ch, val), recv(ch), close(ch)
                if gc_fn_name == "Channel":
                    self.ensure_async_runtime_declared()
                    let ch_fn = wl_get_named_function(self.llmod, "with_channel_create")
                    if ch_fn != 0 and gc_arg_count >= 1:
                        let gc_mir_s = body.call_arg_starts.get(args_id as i64)
                        let cap_op = body.call_arg_operands.get(gc_mir_s as i64)
                        let cap_val = self.mir_eval_operand(body, cap_op, wl_i32_type(self.context))
                        let ch_args: Vec[i64] = Vec.new()
                        ch_args.push(self.coerce_int(cap_val, wl_i32_type(self.context)))
                        let ch_result = wl_build_call(self.builder, wl_global_get_value_type(ch_fn), ch_fn, vec_data_i64(&ch_args), 1)
                        if dest_place >= 0:
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(wl_type_of(ch_result))
                            wl_build_store(self.builder, ch_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, wl_type_of(ch_result))
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                    return true
                if gc_fn_name == "send" and gc_arg_count >= 2:
                    self.ensure_async_runtime_declared()
                    let send_fn = wl_get_named_function(self.llmod, "with_channel_send")
                    if send_fn != 0:
                        let gc_mir_s = body.call_arg_starts.get(args_id as i64)
                        let ch_op = body.call_arg_operands.get(gc_mir_s as i64)
                        let val_op = body.call_arg_operands.get((gc_mir_s + 1) as i64)
                        let ch_val = self.mir_eval_operand(body, ch_op, wl_ptr_type(self.context))
                        let send_val = self.mir_eval_operand(body, val_op, wl_i64_type(self.context))
                        let send_args: Vec[i64] = Vec.new()
                        send_args.push(ch_val)
                        send_args.push(self.coerce_int(send_val, wl_i64_type(self.context)))
                        let _ = wl_build_call(self.builder, wl_global_get_value_type(send_fn), send_fn, vec_data_i64(&send_args), 2)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                    return true
                if gc_fn_name == "recv" and gc_arg_count >= 1:
                    self.ensure_async_runtime_declared()
                    let recv_fn = wl_get_named_function(self.llmod, "with_channel_recv")
                    if recv_fn != 0:
                        let gc_mir_s = body.call_arg_starts.get(args_id as i64)
                        let ch_op = body.call_arg_operands.get(gc_mir_s as i64)
                        let ch_val = self.mir_eval_operand(body, ch_op, wl_ptr_type(self.context))
                        let recv_args: Vec[i64] = Vec.new()
                        recv_args.push(ch_val)
                        let gc_result = wl_build_call(self.builder, wl_global_get_value_type(recv_fn), recv_fn, vec_data_i64(&recv_args), 1)
                        if dest_place >= 0:
                            let gc_local = body.place_locals.get(dest_place as i64)
                            let gc_alloca = self.create_entry_alloca(wl_i64_type(self.context))
                            wl_build_store(self.builder, gc_result, gc_alloca)
                            self.mir_local_ptrs.insert(gc_local, gc_alloca)
                            self.mir_local_types.insert(gc_local, wl_i64_type(self.context))
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                    return true
                if gc_fn_name == "close" and gc_arg_count >= 1:
                    self.ensure_async_runtime_declared()
                    let close_fn = wl_get_named_function(self.llmod, "with_channel_close")
                    if close_fn != 0:
                        let gc_mir_s = body.call_arg_starts.get(args_id as i64)
                        let ch_op = body.call_arg_operands.get(gc_mir_s as i64)
                        let ch_val = self.mir_eval_operand(body, ch_op, wl_ptr_type(self.context))
                        let close_args: Vec[i64] = Vec.new()
                        close_args.push(ch_val)
                        let _ = wl_build_call(self.builder, wl_global_get_value_type(close_fn), close_fn, vec_data_i64(&close_args), 1)
                    if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                        wl_build_br(self.builder, self.mir_bb_values.get(next_bb as i64))
                    return true

            // Try method call dispatch for generic struct methods
            let gc_callee_field = self.pool.get_data0(gc_node)
            if self.pool.kind(gc_callee_field) == NK_FIELD_ACCESS:
                let gc_self_expr_node = self.pool.get_data0(gc_callee_field)
                let gc_method_sym = self.pool.get_data1(gc_callee_field)
                let gc_method_name = self.intern.resolve(gc_method_sym)
                let gc_mir_start = body.call_arg_starts.get(args_id as i64)
                let gc_mir_count = body.call_arg_counts.get(args_id as i64)
                // Eval receiver from MIR operand 0
                if gc_mir_count > 0:
                    let gc_recv_op = body.call_arg_operands.get(gc_mir_start as i64)
                    let gc_recv_val = self.mir_eval_operand(body, gc_recv_op, 0)
                    let gc_recv_ty = wl_type_of(gc_recv_val)
                    let gc_recv_type_sym = self.find_struct_type_by_llvm(gc_recv_ty)
                    // Generic struct method: receiver is monomorphized generic struct
                    let gc_base_opt = self.mono_struct_base.get(gc_recv_type_sym)
                    if gc_base_opt.is_some():
                        let gc_base_sym = gc_base_opt.unwrap()
                        let gc_base_name = self.intern.resolve(gc_base_sym)
                        let gc_qualified = gc_base_name ++ "." ++ gc_method_name
                        let gc_fn_sym_early = self.intern.intern(gc_qualified)
                        let gc_gsm = self.generic_struct_methods.get(gc_fn_sym_early)
                        // Build pre-evaluated args (method args only, not self)
                        let gc_call_args_start = self.pool.get_data1(gc_node)
                        let gc_method_arg_count = gc_mir_count - 1
                        let gc_pre_args: Vec[i64] = Vec.new()
                        for gc_mai in 0..gc_method_arg_count:
                            let gc_ma_op = body.call_arg_operands.get((gc_mir_start + 1 + gc_mai) as i64)
                            gc_pre_args.push(self.mir_eval_operand(body, gc_ma_op, 0))
                        if gc_gsm.is_some():
                            let gc_result = self.monomorphize_struct_method_core(gc_recv_type_sym, gc_method_name, gc_gsm.unwrap(), gc_recv_val, gc_self_expr_node, gc_recv_ty, gc_call_args_start, gc_method_arg_count, gc_node, gc_pre_args)
                            if dest_place >= 0 and gc_result != 0:
                                let gc_ret_ty = wl_type_of(gc_result)
                                if gc_ret_ty != wl_void_type(self.context):
                                    let gc_local = body.place_locals.get(dest_place as i64)
                                    let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                    wl_build_store(self.builder, gc_result, gc_alloca)
                                    self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                    self.mir_local_types.insert(gc_local, gc_ret_ty)
                            if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                                let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                                wl_build_br(self.builder, gc_next_val)
                            return true
                        // Direct method on base struct (non-generic method on generic struct)
                        let gc_direct_fv = self.fn_values.get(gc_fn_sym_early)
                        let gc_direct_ft = self.fn_fn_types.get(gc_fn_sym_early)
                        if gc_direct_fv.is_some() and gc_direct_ft.is_some():
                            let gc_call_args: Vec[i64] = Vec.new()
                            let gc_is_ref = self.fn_ref_param_starts.get(gc_fn_sym_early).is_some()
                            if gc_is_ref:
                                gc_call_args.push(self.get_mutable_receiver_ptr(gc_self_expr_node, gc_recv_val, gc_recv_ty))
                            else:
                                gc_call_args.push(gc_recv_val)
                            for gc_dai in 0..gc_method_arg_count:
                                gc_call_args.push(gc_pre_args.get(gc_dai as i64))
                            let gc_coerced = self.coerce_call_args_for_fn_value(gc_fn_sym_early, gc_direct_fv.unwrap() as i64, gc_call_args_start, 1, gc_call_args, gc_method_arg_count + 1, "method " ++ gc_qualified, gc_node)
                            let gc_result = wl_build_call(self.builder, gc_direct_ft.unwrap() as i64, gc_direct_fv.unwrap() as i64, vec_data_i64(&gc_coerced), gc_method_arg_count + 1)
                            if dest_place >= 0 and gc_result != 0:
                                let gc_ret_ty = wl_type_of(gc_result)
                                if gc_ret_ty != wl_void_type(self.context):
                                    let gc_local = body.place_locals.get(dest_place as i64)
                                    let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                    wl_build_store(self.builder, gc_result, gc_alloca)
                                    self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                    self.mir_local_types.insert(gc_local, gc_ret_ty)
                            if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                                let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                                wl_build_br(self.builder, gc_next_val)
                            return true

            // Disc enum static methods: Direction.from_int(n)
            if self.pool.kind(gc_callee_field) == NK_FIELD_ACCESS:
                let gc_de_self = self.pool.get_data0(gc_callee_field)
                let gc_de_method_sym = self.pool.get_data1(gc_callee_field)
                let gc_de_method = self.intern.resolve(gc_de_method_sym)
                if gc_de_method == "from_int" and self.pool.kind(gc_de_self) == NK_IDENT:
                    let gc_de_type_sym = self.pool.get_data0(gc_de_self)
                    let gc_de_opt = self.disc_enum_type_map.get(gc_de_type_sym)
                    if gc_de_opt.is_some():
                        let gc_de_mir_start = body.call_arg_starts.get(args_id as i64)
                        let gc_de_mir_count = body.call_arg_counts.get(args_id as i64)
                        if gc_de_mir_count > 0:
                            let gc_de_arg_op = body.call_arg_operands.get(gc_de_mir_start as i64)
                            let gc_de_arg_val = self.mir_eval_operand(body, gc_de_arg_op, 0)
                            let gc_result = self.gen_disc_enum_from_int_val(gc_de_opt.unwrap(), gc_de_arg_val)
                            if dest_place >= 0 and gc_result != 0:
                                let gc_ret_ty = wl_type_of(gc_result)
                                if gc_ret_ty != wl_void_type(self.context):
                                    let gc_local = body.place_locals.get(dest_place as i64)
                                    let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                    wl_build_store(self.builder, gc_result, gc_alloca)
                                    self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                    self.mir_local_types.insert(gc_local, gc_ret_ty)
                            if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                                let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                                wl_build_br(self.builder, gc_next_val)
                            return true

            // Disc enum variant constructor with payload: Msg.Move(10, 20)
            if self.pool.kind(gc_callee_field) == NK_FIELD_ACCESS:
                let gc_vc_self = self.pool.get_data0(gc_callee_field)
                let gc_vc_variant_sym = self.pool.get_data1(gc_callee_field)
                if self.pool.kind(gc_vc_self) == NK_IDENT:
                    let gc_vc_type_sym = self.pool.get_data0(gc_vc_self)
                    var gc_vc_is_enum = false
                    let gc_vc_de_opt = self.disc_enum_type_map.get(gc_vc_type_sym)
                    if gc_vc_de_opt.is_some():
                        let gc_vc_de_idx = gc_vc_de_opt.unwrap()
                        let gc_vc_hp = self.disc_enum_has_payload.get(gc_vc_de_idx as i64)
                        if gc_vc_hp != 0:
                            gc_vc_is_enum = true
                    if not gc_vc_is_enum:
                        let gc_vc_e_opt = self.enum_type_map.get(gc_vc_type_sym)
                        if gc_vc_e_opt.is_some():
                            gc_vc_is_enum = true
                    if gc_vc_is_enum:
                        let gc_vc_mir_start = body.call_arg_starts.get(args_id as i64)
                        let gc_vc_mir_count = body.call_arg_counts.get(args_id as i64)
                        let gc_vc_args: Vec[i64] = Vec.new()
                        for gc_vc_i in 0..gc_vc_mir_count:
                            let gc_vc_op = body.call_arg_operands.get((gc_vc_mir_start + gc_vc_i) as i64)
                            gc_vc_args.push(self.mir_eval_operand(body, gc_vc_op, 0))
                        let gc_result = self.gen_enum_variant_call_val(gc_vc_variant_sym, gc_vc_args, gc_vc_mir_count)
                        if dest_place >= 0 and gc_result != 0:
                            let gc_ret_ty = wl_type_of(gc_result)
                            if gc_ret_ty != wl_void_type(self.context):
                                let gc_local = body.place_locals.get(dest_place as i64)
                                let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                wl_build_store(self.builder, gc_result, gc_alloca)
                                self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                self.mir_local_types.insert(gc_local, gc_ret_ty)
                        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                            let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                            wl_build_br(self.builder, gc_next_val)
                        return true

            // Fallback: trait method call on concrete type (e.g. self.show() in blanket impl)
            if self.pool.kind(gc_callee_field) == NK_FIELD_ACCESS:
                let gc_fb_method_sym = self.pool.get_data1(gc_callee_field)
                let gc_fb_method = self.intern.resolve(gc_fb_method_sym)
                let gc_fb_mir_start = body.call_arg_starts.get(args_id as i64)
                let gc_fb_mir_count = body.call_arg_counts.get(args_id as i64)
                // Try qualified name lookups: OwnerType.method, then TraitName.method
                var gc_fb_fn_sym = 0
                if self.current_method_owner_sym != 0:
                    let gc_fb_owner = self.intern.resolve(self.current_method_owner_sym)
                    let gc_fb_q1 = gc_fb_owner ++ "." ++ gc_fb_method
                    gc_fb_fn_sym = self.intern.intern(gc_fb_q1)
                    if not self.fn_values.get(gc_fb_fn_sym).is_some():
                        gc_fb_fn_sym = 0
                // Search all traits for a method with this name
                if gc_fb_fn_sym == 0:
                    for gc_fb_ti in 0..self.trait_idx_syms.len() as i32:
                        let gc_fb_t_sym = self.trait_idx_syms.get(gc_fb_ti as i64)
                        let gc_fb_m_start = self.trait_method_starts.get(gc_fb_ti as i64)
                        let gc_fb_m_count = self.trait_method_counts.get(gc_fb_ti as i64)
                        for gc_fb_mi in 0..gc_fb_m_count:
                            let gc_fb_m_name = self.trait_method_names.get((gc_fb_m_start + gc_fb_mi) as i64)
                            if self.intern.resolve(gc_fb_m_name) == gc_fb_method:
                                let gc_fb_t_name = self.intern.resolve(gc_fb_t_sym)
                                let gc_fb_q2 = gc_fb_t_name ++ "." ++ gc_fb_method
                                let gc_fb_try_sym = self.intern.intern(gc_fb_q2)
                                if self.fn_values.get(gc_fb_try_sym).is_some():
                                    gc_fb_fn_sym = gc_fb_try_sym
                if gc_fb_fn_sym != 0 and gc_fb_mir_count > 0:
                    let gc_fb_fv = self.fn_values.get(gc_fb_fn_sym)
                    let gc_fb_ft = self.fn_fn_types.get(gc_fb_fn_sym)
                    if gc_fb_fv.is_some() and gc_fb_ft.is_some():
                        let gc_fb_is_ref = self.fn_ref_param_starts.get(gc_fb_fn_sym).is_some()
                        let gc_fb_args: Vec[i64] = Vec.new()
                        for gc_fb_i in 0..gc_fb_mir_count:
                            let gc_fb_op = body.call_arg_operands.get((gc_fb_mir_start + gc_fb_i) as i64)
                            let gc_fb_val = self.mir_eval_operand(body, gc_fb_op, 0)
                            if gc_fb_i == 0 and gc_fb_is_ref:
                                if wl_get_type_kind(wl_type_of(gc_fb_val)) != wl_pointer_type_kind():
                                    let gc_fb_alloca = self.create_entry_alloca(wl_type_of(gc_fb_val))
                                    wl_build_store(self.builder, gc_fb_val, gc_fb_alloca)
                                    gc_fb_args.push(gc_fb_alloca)
                                    continue
                            gc_fb_args.push(gc_fb_val)
                        let gc_result = wl_build_call(self.builder, gc_fb_ft.unwrap() as i64, gc_fb_fv.unwrap() as i64, vec_data_i64(&gc_fb_args), gc_fb_mir_count)
                        if dest_place >= 0 and gc_result != 0:
                            let gc_ret_ty = wl_type_of(gc_result)
                            if gc_ret_ty != wl_void_type(self.context):
                                let gc_local = body.place_locals.get(dest_place as i64)
                                let gc_alloca = self.create_entry_alloca(gc_ret_ty)
                                wl_build_store(self.builder, gc_result, gc_alloca)
                                self.mir_local_ptrs.insert(gc_local, gc_alloca)
                                self.mir_local_types.insert(gc_local, gc_ret_ty)
                        if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                            let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                            wl_build_br(self.builder, gc_next_val)
                        return true

            // Try derive-generated method calls (e.g., clone)
            if gc_callee_sym > 0 and gc_node > 0:
                let dv_callee = self.pool.get_data0(gc_node)
                if self.pool.kind(dv_callee) == NK_FIELD_ACCESS:
                    let dv_method = self.pool.get_data1(dv_callee)
                    let dv_ms = body.call_arg_starts.get(args_id as i64)
                    let dv_mc = body.call_arg_counts.get(args_id as i64)
                    if dv_mc > 0:
                        let dv_rop = body.call_arg_operands.get(dv_ms as i64)
                        let dv_rv = self.mir_eval_operand(body, dv_rop, 0)
                        let dv_rt = wl_type_of(dv_rv)
                        let dv_ts = self.find_struct_type_by_llvm(dv_rt)
                        if dv_ts != 0:
                            let dv_mn = self.intern.resolve(dv_method)
                            let dv_qn = self.intern.resolve(dv_ts) ++ "." ++ dv_mn
                            let dv_qs = self.intern.intern(dv_qn)
                            let dv_fv = self.fn_values.get(dv_qs)
                            let dv_ft = self.fn_fn_types.get(dv_qs)
                            if dv_fv.is_some() and dv_ft.is_some():
                                let dv_args: Vec[i64] = Vec.new()
                                dv_args.push(self.get_mutable_receiver_ptr(self.pool.get_data0(dv_callee), dv_rv, dv_rt))
                                let dv_result = wl_build_call(self.builder, dv_ft.unwrap() as i64, dv_fv.unwrap() as i64, vec_data_i64(&dv_args), 1)
                                if dest_place >= 0 and dv_result != 0:
                                    let dv_ret_ty = wl_type_of(dv_result)
                                    if dv_ret_ty != wl_void_type(self.context):
                                        let dv_local = body.place_locals.get(dest_place as i64)
                                        let dv_alloca = self.create_entry_alloca(dv_ret_ty)
                                        wl_build_store(self.builder, dv_result, dv_alloca)
                                        self.mir_local_ptrs.insert(dv_local, dv_alloca)
                                        self.mir_local_types.insert(dv_local, dv_ret_ty)
                                if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                                    let dv_next = self.mir_bb_values.get(next_bb as i64)
                                    wl_build_br(self.builder, dv_next)
                                return true

            // All patterns should be handled above. If we reach here, it's a genuine error
            // (unless we're in a blanket impl body where T-method calls can't be resolved).
            let gc_name = if gc_callee_sym > 0: self.intern.resolve(gc_callee_sym) else: "?"
            var gc_is_blanket = false
            if self.current_method_owner_sym != 0:
                let gc_owner_name = self.intern.resolve(self.current_method_owner_sym)
                if gc_owner_name.len() <= 2:
                    // Single-letter type params (T, K, V) indicate blanket impl context
                    if not self.struct_type_map.get(self.current_method_owner_sym).is_some():
                        if not self.enum_type_map.get(self.current_method_owner_sym).is_some():
                            gc_is_blanket = true
            if not gc_is_blanket:
                with_eprintln("FATAL: unhandled MIR_INTRINSIC_GENERIC_CALL sym=" ++ gc_name ++ " node_kind=" ++ int_to_string(self.pool.kind(gc_node)))
                self.had_error = 1
            if next_bb >= 0 and next_bb < self.mir_bb_values.len() as i32:
                let gc_next_val = self.mir_bb_values.get(next_bb as i64)
                wl_build_br(self.builder, gc_next_val)
            return true
    if mir_intrinsic != MIR_INTRINSIC_NONE:
        return self.mir_emit_intrinsic_call(body, mir_intrinsic, args_id, dest_place, next_bb)
    let callee = self.mir_eval_operand(body, callee_operand, 0)
    if self.debug_mir_codegen_enabled():
        // Debug: show callee operand info for crash diagnosis
        let co_k = body.operand_kinds.get(callee_operand as i64)
        let co_d = body.operand_d0.get(callee_operand as i64)
        var dbg_name = "?"
        if co_k == OK_CONSTANT and co_d >= 0 and co_d < body.const_kinds.len() as i32:
            if body.const_kinds.get(co_d as i64) == CK_FN:
                let raw_sym = body.const_d0.get(co_d as i64)
                if raw_sym > 0 and raw_sym < self.sema.pool.symbol_texts.len() as i32:
                    dbg_name = self.sema.pool.symbol_texts.get(raw_sym as i64)
        with_eprintln("[mir-call] callee=" ++ dbg_name ++ " callee_ty_kind=" ++ int_to_string(wl_get_type_kind(wl_type_of(callee))))
    let call_context = self.mir_call_context(body, callee_operand)
    var call_ft: i64 = 0
    var is_indirect = false
    var fn_ptr_val: i64 = 0
    var ctx_ptr_val: i64 = 0
    let callee_ty = wl_type_of(callee)
    if wl_get_type_kind(callee_ty) == wl_function_type_kind():
        call_ft = callee_ty
    else if wl_get_type_kind(callee_ty) == wl_pointer_type_kind():
        let pointee = wl_get_element_type(callee_ty)
        if wl_get_type_kind(pointee) == wl_function_type_kind():
            call_ft = pointee
        else:
            let gvt = wl_global_get_value_type(callee)
            if gvt != 0 and wl_get_type_kind(gvt) == wl_function_type_kind():
                call_ft = gvt
    else if wl_get_type_kind(callee_ty) == wl_struct_type_kind():
        let nfields = wl_count_struct_elem_types(callee_ty)
        if nfields == 2:
            let f0 = wl_struct_get_type_at(callee_ty, 0)
            let f1 = wl_struct_get_type_at(callee_ty, 1)
            if wl_get_type_kind(f0) == wl_pointer_type_kind() and wl_get_type_kind(f1) == wl_pointer_type_kind():
                is_indirect = true
                fn_ptr_val = wl_build_extract_value(self.builder, callee, 0)
                ctx_ptr_val = wl_build_extract_value(self.builder, callee, 1)
                let co_ok = body.operand_kinds.get(callee_operand as i64)
                let co_od = body.operand_d0.get(callee_operand as i64)
                if (co_ok == OK_COPY or co_ok == OK_MOVE) and co_od >= 0 and co_od < body.place_locals.len() as i32:
                    let co_local = body.place_locals.get(co_od as i64)
                    if co_local >= 0 and co_local < body.local_type_ids.len() as i32:
                        let co_sema_ty = body.local_type_ids.get(co_local as i64)
                        if co_sema_ty > 0:
                            call_ft = self.mir_build_closure_fn_type(co_sema_ty)
    else:
        let gvt2 = wl_global_get_value_type(callee)
        if gvt2 != 0 and wl_get_type_kind(gvt2) == wl_function_type_kind():
            call_ft = gvt2
    if call_ft == 0:
        return false

    var arg_start = 0
    var arg_count = 0
    if args_id >= 0 and args_id < body.call_arg_starts.len() as i32:
        arg_start = body.call_arg_starts.get(args_id as i64)
        arg_count = body.call_arg_counts.get(args_id as i64)

    let param_count = wl_count_param_types(call_ft)
    let param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        param_types.push(wl_i32_type(self.context))
    if param_count > 0:
        wl_get_param_types(call_ft, vec_data_i64(&param_types))

    // Resolve callee fn_sym for dyn trait parameter lookup.
    // CK_FN syms are from sema pool — translate to codegen intern pool.
    var callee_fn_sym: i32 = 0
    if callee_operand >= 0 and callee_operand < body.operand_kinds.len() as i32:
        let co_k = body.operand_kinds.get(callee_operand as i64)
        let co_d = body.operand_d0.get(callee_operand as i64)
        if co_k == OK_CONSTANT and co_d >= 0 and co_d < body.const_kinds.len() as i32:
            if body.const_kinds.get(co_d as i64) == CK_FN:
                let raw_sym = body.const_d0.get(co_d as i64)
                // Translate sema pool sym to codegen intern pool sym
                if raw_sym > 0 and raw_sym < self.sema.pool.symbol_texts.len() as i32:
                    let sym_text = self.sema.pool.symbol_texts.get(raw_sym as i64)
                    if sym_text.len() > 0:
                        callee_fn_sym = self.intern.intern(sym_text)

    let args: Vec[i64] = Vec.new()
    if is_indirect:
        args.push(ctx_ptr_val)
    for ai in 0..arg_count:
        let operand_id = body.call_arg_operands.get((arg_start + ai) as i64)
        var expected_ty: i64 = 0
        let param_offset = if is_indirect: ai + 1 else: ai
        if param_offset < param_count:
            expected_ty = param_types.get(param_offset as i64)

        // Ref param check: pass pointer to place instead of loading value.
        // This handles struct self params where the ABI uses pointer-passing.
        var needs_ref = false
        if callee_fn_sym != 0 and expected_ty != 0:
            if wl_get_type_kind(expected_ty) == wl_pointer_type_kind():
                needs_ref = self.is_ref_param(callee_fn_sym, param_offset)

        // Check for dyn param BEFORE evaluating operand — coercion would
        // mangle the concrete struct into the fat-pointer shape.
        var dyn_trait_sym: i32 = 0
        if callee_fn_sym != 0:
            dyn_trait_sym = self.get_fn_dyn_param_trait(callee_fn_sym, ai)
        var arg_val: i64 = 0
        if needs_ref:
            // Evaluate first to check if operand is already a pointer.
            // Ref params (&T) are already pointers — don't wrap them again.
            let val = self.mir_eval_operand(body, operand_id, 0)
            let val_ty = wl_type_of(val)
            if wl_get_type_kind(val_ty) == wl_pointer_type_kind():
                // Already a pointer — pass directly
                arg_val = val
            else:
                // Struct value needs pointer-passing. Try place ptr first.
                arg_val = self.mir_try_place_ptr_for_ref(body, operand_id)
                if arg_val == 0:
                    // Fallback: alloca in entry block, store, pass ptr
                    let tmp = self.create_entry_alloca(val_ty)
                    wl_build_store(self.builder, val, tmp)
                    arg_val = tmp
        else if dyn_trait_sym != 0:
            // Evaluate without coercion so we get the raw concrete value.
            arg_val = self.mir_eval_operand(body, operand_id, 0)
            let arg_ty = wl_type_of(arg_val)
            var concrete_sym: i32 = 0
            for si in 0..self.struct_llvm_types.len() as i32:
                if self.struct_llvm_types.get(si as i64) == arg_ty:
                    if si < self.struct_index_syms.len() as i32:
                        concrete_sym = self.struct_index_syms.get(si as i64)
                    break
            if concrete_sym != 0:
                arg_val = self.build_dyn_trait_value(arg_val, concrete_sym, dyn_trait_sym)
        else:
            arg_val = self.mir_eval_call_operand(body, operand_id, expected_ty, call_context, ai)
        args.push(arg_val)

    let actual_callee = if is_indirect: fn_ptr_val else: callee
    let actual_arg_count = if is_indirect: arg_count + 1 else: arg_count
    if self.debug_mir_codegen_enabled():
        with_eprintln("[mir-call] building call arg_count=" ++ int_to_string(actual_arg_count) ++ " ft_params=" ++ int_to_string(wl_count_param_types(call_ft)))
        for di in 0..args.len() as i32:
            let a = args.get(di as i64)
            with_eprintln("[mir-call]   arg[" ++ int_to_string(di) ++ "] ty_kind=" ++ int_to_string(wl_get_type_kind(wl_type_of(a))))
    let call_val = wl_build_call(self.builder, call_ft, actual_callee, vec_data_i64(&args), actual_arg_count)
    let ret_ty = wl_get_return_type(call_ft)
    if ret_ty != wl_void_type(self.context):
        if dest_place < 0 or dest_place >= body.place_locals.len() as i32:
            return false
        let dst_local = body.place_locals.get(dest_place as i64)
        let dst_ptr = self.mir_place_ptr(body, dest_place, true, ret_ty)
        if dst_ptr == 0:
            return false
        var dst_ty = ret_ty
        let dst_ty_opt = self.mir_local_types.get(dst_local)
        if dst_ty_opt.is_some():
            dst_ty = dst_ty_opt.unwrap() as i64
        else:
            self.mir_local_types.insert(dst_local, ret_ty)
        if dst_ty == 0:
            return false
        let stored = self.enforce_coerced_type(call_val, dst_ty, "return type mismatch at call site")
        wl_build_store(self.builder, stored, dst_ptr)

    if next_bb < 0 or next_bb >= self.mir_bb_values.len() as i32:
        return false
    let next_val = self.mir_bb_values.get(next_bb as i64)
    wl_build_br(self.builder, next_val)
    true

fn Codegen.mir_emit_term(self: Codegen, body: MirBody, bb: i32) -> bool:
    if bb < 0 or bb >= body.bb_term_kinds.len() as i32:
        return false
    let tk = body.bb_term_kinds.get(bb as i64)
    let d0 = body.bb_term_d0.get(bb as i64)
    let d1 = body.bb_term_d1.get(bb as i64)
    let d2 = body.bb_term_d2.get(bb as i64)
    let d3 = body.bb_term_d3.get(bb as i64)
    if self.debug_mir_codegen_enabled():
        with_eprintln("[mir-term] bb=" ++ int_to_string(bb) ++ " tk=" ++ int_to_string(tk))

    if tk == TK_GOTO:
        if d0 < 0 or d0 >= self.mir_bb_values.len() as i32:
            return false
        let target_bb = self.mir_bb_values.get(d0 as i64)
        wl_build_br(self.builder, target_bb)
        return true

    if tk == TK_RETURN:
        if self.current_ret_type == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
            return true
        let ret_ptr_opt = self.mir_local_ptrs.get(0)
        if not ret_ptr_opt.is_some():
            let _ = wl_build_ret(self.builder, self.build_default_value(self.current_ret_type))
            return true
        let ret_ptr = ret_ptr_opt.unwrap() as i64
        var ret_ptr_ty = self.current_ret_type
        let ret_ptr_ty_opt = self.mir_local_types.get(0)
        if ret_ptr_ty_opt.is_some():
            ret_ptr_ty = ret_ptr_ty_opt.unwrap() as i64
        if ret_ptr_ty == 0:
            let _ = wl_build_ret(self.builder, self.build_default_value(self.current_ret_type))
            return true
        let ret_val = wl_build_load(self.builder, ret_ptr_ty, ret_ptr)
        let _ = wl_build_ret(self.builder, self.enforce_coerced_type(ret_val, self.current_ret_type, "return type mismatch"))
        return true

    if tk == TK_UNREACHABLE:
        wl_build_unreachable(self.builder)
        return true

    if tk == TK_SWITCH_INT:
        let cond = self.mir_eval_operand(body, d0, 0)
        var default_bb = self.mir_default_unreachable_bb_value()
        if d2 >= 0:
            if d2 >= 0 and d2 < self.mir_bb_values.len() as i32:
                default_bb = self.mir_bb_values.get(d2 as i64)
        var case_start = 0
        var case_count = 0
        if d1 >= 0 and d1 < body.switch_table_starts.len() as i32:
            case_start = body.switch_table_starts.get(d1 as i64)
            case_count = body.switch_table_counts.get(d1 as i64)
        let sw = wl_build_switch(self.builder, cond, default_bb, case_count)
        let cond_ty = wl_type_of(cond)
        var int_ty = wl_i32_type(self.context)
        if wl_get_type_kind(cond_ty) == wl_integer_type_kind():
            int_ty = cond_ty
        for ci in 0..case_count:
            let target_bb = body.switch_table_targets.get((case_start + ci) as i64)
            if target_bb >= 0 and target_bb < self.mir_bb_values.len() as i32:
                let val = body.switch_table_vals.get((case_start + ci) as i64)
                let case_target = self.mir_bb_values.get(target_bb as i64)
                wl_add_case(sw, wl_const_int(int_ty, val as i64, 1), case_target)
        return true

    if tk == TK_CALL:
        return self.mir_emit_call_term(body, d0, d1, d2, d3)

    if tk == TK_DROP_AND_GOTO:
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let local_id = body.place_locals.get(d0 as i64)
        let ty_opt = self.mir_local_types.get(local_id)
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr != 0:
            if ty_opt.is_some():
                self.mir_emit_drop_ptr(ptr, ty_opt.unwrap() as i64)
        if d1 < 0 or d1 >= self.mir_bb_values.len() as i32:
            return false
        let target_bb = self.mir_bb_values.get(d1 as i64)
        wl_build_br(self.builder, target_bb)
        return true

    false

fn Codegen.gen_function_mir(self: Codegen, fn_node: i32, body: MirBody):
    let name_sym = self.pool.get_data0(fn_node)
    let resolved_name = self.intern.resolve(name_sym)
    let name_str = if resolved_name.len() > 0: resolved_name else: self.fn_decl_name_from_node(fn_node)
    if name_sym == 0:
        return
    let fv = self.fn_values.get(name_sym)
    if not fv.is_some():
        with_eprintln("error: no fn_value for MIR function: " ++ name_str)
        return
    let function = fv.unwrap() as i64
    let ft = self.fn_fn_types.get(name_sym)
    if not ft.is_some():
        with_eprintln("error: no fn_type for MIR function: " ++ name_str)
        return
    let fn_type = ft.unwrap() as i64
    if self.debug_mir_codegen_enabled():
        with_eprintln("[mir-cg] fn=" ++ name_str ++ " blocks=" ++ int_to_string(body.block_count()))

    self.current_function = function
    self.current_function_name_sym = name_sym
    self.current_ret_type = wl_get_return_type(fn_type)
    self.current_method_owner_sym = 0

    let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
    let fresh_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
    let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
    let fresh_local_pointee_structs: HashMap[i32, i32] = HashMap.new()
    let fresh_task_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_defer_stack: Vec[i32] = Vec.new()
    let fresh_errdefer_stack: Vec[i32] = Vec.new()
    let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_local_concrete_types: HashMap[i32, i32] = HashMap.new()
    let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
    self.local_allocas = fresh_local_allocas
    self.local_types = fresh_local_types
    self.local_muts = fresh_local_muts
    self.local_fn_sigs = fresh_local_fn_sigs
    self.local_pointee_structs = fresh_local_pointee_structs
    self.task_locals = fresh_task_locals
    self.defer_stack = fresh_defer_stack
    self.errdefer_stack = fresh_errdefer_stack
    self.trait_locals = fresh_trait_locals
    self.trait_local_concrete_types = fresh_trait_local_concrete_types
    self.enum_local_types = fresh_enum_local_types
    self.scope_local_count = 0

    let saved_expected = self.expected_type
    let saved_expected_node = self.expected_type_node
    self.expected_type = self.current_ret_type
    self.expected_type_node = 0
    let saved_result_err = self.current_result_err_symbol
    let saved_returns_result = self.current_fn_returns_result
    let saved_saw_return = self.current_fn_saw_explicit_return
    self.current_result_err_symbol = 0
    self.current_fn_returns_result = false
    self.current_fn_saw_explicit_return = false
    let saved_tailrec_bb = self.tailrec_body_bb
    let saved_tailrec_sym = self.tailrec_fn_sym
    self.tailrec_body_bb = 0
    self.tailrec_fn_sym = 0

    let fresh_mir_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_bbs: Vec[i64] = Vec.new()
    let fresh_mir_default_unreachable_bbs: Vec[i64] = Vec.new()
    self.mir_local_ptrs = fresh_mir_locals
    self.mir_local_types = fresh_mir_local_types
    self.mir_bb_values = fresh_mir_bbs
    self.mir_default_unreachable_bbs = fresh_mir_default_unreachable_bbs

    let entry = wl_append_bb(self.context, function, "entry")
    wl_position_at_end(self.builder, entry)

    let ret_store_ty = if self.current_ret_type != wl_void_type(self.context): self.current_ret_type else: wl_i32_type(self.context)
    let ret_alloca = self.create_entry_alloca(ret_store_ty)
    self.mir_local_ptrs.insert(0, ret_alloca)
    self.mir_local_types.insert(0, ret_store_ty)

    // Pre-populate mir_local_ptrs for global variable proxy locals
    for gli in 0..body.local_names.len() as i32:
        let gl_name = body.local_names.get(gli as i64)
        if gl_name != 0:
            let gl_mc = self.module_constants.get(gl_name)
            if gl_mc.is_some():
                self.mir_local_ptrs.insert(gli, gl_mc.unwrap() as i64)

    let meta = self.pool.find_fn_meta(fn_node)
    var param_start = 0
    var param_count = 0
    if meta >= 0:
        param_start = self.pool.fn_meta_param_start(meta)
        param_count = self.pool.fn_meta_param_count(meta)

    var method_owner_sym = 0
    for di in 0..name_str.len() as i32:
        if name_str.byte_at(di as i64) == 46:
            method_owner_sym = self.intern.intern(name_str.slice(0, di as i64))
            break
    self.current_method_owner_sym = method_owner_sym

    let max_params = param_count
    for pi in 0..max_params:
        let p_name = self.pool.fn_param_name(param_start, pi)
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        let param_val = wl_get_param(function, pi)
        let param_type = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_type)
        wl_build_store(self.builder, param_val, alloca)

        self.record_local(p_name, alloca, param_type, 1)

        self.mir_local_ptrs.insert(pi + 1, alloca)
        self.mir_local_types.insert(pi + 1, param_type)

        if p_type_node != 0:
            let pk = self.pool.kind(p_type_node)
            if pk == NK_TYPE_FN:
                let fn_sig = self.build_fn_type_from_ast(p_type_node)
                self.record_local_fn_sig(p_name, fn_sig)
            if pk == NK_TYPE_PTR or pk == NK_TYPE_REF:
                let pointee_node = self.pool.get_data0(p_type_node)
                if self.pool.kind(pointee_node) == NK_TYPE_NAMED:
                    let ps = self.pool.get_data0(pointee_node)
                    if self.struct_type_map.get(ps).is_some():
                        self.record_local_pointee_struct(p_name, ps)
            if pk == NK_TYPE_NAMED:
                let p_sym = self.pool.get_data0(p_type_node)
                let p_n = self.intern.resolve(p_sym)
                let p_name_text = self.intern.resolve(p_name)
                if method_owner_sym == 0 and p_name_text == "self" and self.struct_type_map.get(p_sym).is_some():
                    // str is in struct_type_map but passes by value, not pointer
                    if self.intern.resolve(p_sym) != "str":
                        method_owner_sym = p_sym
                        self.current_method_owner_sym = method_owner_sym
                if method_owner_sym != 0 and (p_n == "Self" or p_sym == method_owner_sym):
                    let owner_n = self.intern.resolve(method_owner_sym)
                    if owner_n != "str":
                        self.record_local_pointee_struct(p_name, method_owner_sym)
            if method_owner_sym != 0:
                let p_n = self.intern.resolve(p_name)
                if p_n == "self":
                    let owner_n2 = self.intern.resolve(method_owner_sym)
                    if owner_n2 != "str":
                        self.record_local_pointee_struct(p_name, method_owner_sym)
            let trait_sym = self.dyn_trait_from_type_node(p_type_node)
            if trait_sym != 0:
                self.record_trait_local(p_name, trait_sym)

    for bb in 0..body.block_count():
        let bb_name = "mir.bb" ++ int_to_string(bb)
        let llbb = wl_append_bb(self.context, function, bb_name)
        self.mir_bb_values.push(llbb)

    if self.mir_bb_values.len() as i32 > 0:
        wl_build_br(self.builder, self.mir_bb_values.get(0))
    else:
        if self.current_ret_type == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
        else:
            let _ = wl_build_ret(self.builder, self.build_default_value(self.current_ret_type))

    let saved_fn_scope = self.di_current_scope
    for bb in 0..body.block_count():
        if bb < 0 or bb >= self.mir_bb_values.len() as i32:
            continue
        let llbb = self.mir_bb_values.get(bb as i64)
        if self.debug_mir_codegen_enabled():
            with_eprintln("[mir-cg] fn=" ++ name_str ++ " bb=" ++ int_to_string(bb) ++ " llbb=" ++ i64_to_string(llbb))
        wl_position_at_end(self.builder, llbb)
        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let stmt_count = body.bb_stmt_counts.get(bb as i64)
        // Push a lexical block scope for non-entry BBs
        if bb > 0 and stmt_count > 0:
            let first_span = body.stmt_spans.get(stmt_start as i64)
            if first_span > 0:
                self.di_current_scope = saved_fn_scope
                self.debug_push_lexical_block(first_span)
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            let stmt_span = body.stmt_spans.get(stmt_id as i64)
            if stmt_span > 0:
                self.debug_set_location(stmt_span)
            if not self.mir_emit_stmt(body, stmt_id):
                if self.debug_mir_codegen_enabled():
                    with_eprintln("[mir-cg] fn=" ++ name_str ++ " bb=" ++ int_to_string(bb) ++ " stmt_fail=" ++ int_to_string(stmt_id))
                if wl_get_bb_terminator(llbb) == 0:
                    wl_build_unreachable(self.builder)
                break
        if wl_get_bb_terminator(llbb) == 0:
            let term_span = body.bb_term_spans.get(bb as i64)
            if term_span > 0:
                self.debug_set_location(term_span)
            let ok = self.mir_emit_term(body, bb)
            if self.debug_mir_codegen_enabled():
                var ok_i = 0
                if ok:
                    ok_i = 1
                with_eprintln("[mir-cg] fn=" ++ name_str ++ " bb=" ++ int_to_string(bb) ++ " term_ok=" ++ int_to_string(ok_i))
            if not ok and wl_get_bb_terminator(llbb) == 0:
                wl_build_unreachable(self.builder)

    self.di_current_scope = saved_fn_scope

    if self.mir_default_unreachable_bbs.len() as i32 > 0:
        let ubb = self.mir_default_unreachable_bbs.get(0)
        if wl_get_bb_terminator(ubb) == 0:
            wl_position_at_end(self.builder, ubb)
            wl_build_unreachable(self.builder)


    // Run mem2reg to promote allocas to SSA, reducing stack frame sizes.
    // DISABLED: investigating whether mem2reg causes argument setup issues
    // wl_promote_allocas(function, self.target_machine)

    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    self.current_result_err_symbol = saved_result_err
    self.current_fn_returns_result = saved_returns_result
    self.current_fn_saw_explicit_return = saved_saw_return
    self.tailrec_body_bb = saved_tailrec_bb
    self.tailrec_fn_sym = saved_tailrec_sym

// ── gen_function_mir_mono: MIR codegen for monomorphized generic fn ──
// Like gen_function_mir but uses mono_sym for fn_values/fn_fn_types lookup
// instead of extracting the name from the AST node (which has the generic name).

fn Codegen.gen_function_mir_mono(self: Codegen, mono_sym: i32, fn_node: i32, body: MirBody):
    let name_str = self.intern.resolve(mono_sym)
    let fv = self.fn_values.get(mono_sym)
    if not fv.is_some():
        with_eprintln("error: no fn_value for MIR mono function: " ++ name_str)
        return
    let function = fv.unwrap() as i64
    let ft = self.fn_fn_types.get(mono_sym)
    if not ft.is_some():
        with_eprintln("error: no fn_type for MIR mono function: " ++ name_str)
        return
    let fn_type = ft.unwrap() as i64

    // Save all codegen state (will be restored at end)
    let saved_fn = self.current_function
    let saved_fn_name_sym = self.current_function_name_sym
    let saved_ret = self.current_ret_type
    let saved_owner = self.current_method_owner_sym
    let saved_allocas = self.local_allocas
    let saved_types = self.local_types
    let saved_muts = self.local_muts
    let saved_fn_sigs = self.local_fn_sigs
    let saved_pointees = self.local_pointee_structs
    let saved_task_locals = self.task_locals
    let saved_trait_locals = self.trait_locals
    let saved_trait_concrete = self.trait_local_concrete_types
    let saved_scope_syms = self.scope_local_syms
    let saved_scope_allocas = self.scope_local_allocas
    let saved_scope_types = self.scope_local_types
    let saved_scope_count = self.scope_local_count
    let saved_defer = self.defer_stack
    let saved_errdefer = self.errdefer_stack
    let saved_enum_local_types = self.enum_local_types
    let saved_sema_local_types = self.local_sema_types
    let saved_expected = self.expected_type
    let saved_expected_node = self.expected_type_node
    let saved_result_err = self.current_result_err_symbol
    let saved_returns_result = self.current_fn_returns_result
    let saved_saw_return = self.current_fn_saw_explicit_return
    let saved_tail_bb = self.tailrec_body_bb
    let saved_tail_sym = self.tailrec_fn_sym
    let saved_tail_allocas = self.tailrec_param_allocas
    let saved_loops = self.capture_loop_state()
    let saved_bb = wl_get_insert_block(self.builder)

    // Set up fresh function state
    self.current_function = function
    self.current_function_name_sym = mono_sym
    self.current_ret_type = wl_get_return_type(fn_type)
    self.current_method_owner_sym = 0

    let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
    let fresh_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
    let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
    let fresh_local_pointee_structs: HashMap[i32, i32] = HashMap.new()
    let fresh_task_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_defer_stack: Vec[i32] = Vec.new()
    let fresh_errdefer_stack: Vec[i32] = Vec.new()
    let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_local_concrete_types: HashMap[i32, i32] = HashMap.new()
    let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
    let fresh_scope_syms: Vec[i32] = Vec.new()
    let fresh_scope_allocas: Vec[i64] = Vec.new()
    let fresh_scope_types: Vec[i64] = Vec.new()
    let fresh_tail_allocas: Vec[i64] = Vec.new()
    self.local_allocas = fresh_local_allocas
    self.local_types = fresh_local_types
    self.local_muts = fresh_local_muts
    self.local_fn_sigs = fresh_local_fn_sigs
    self.local_pointee_structs = fresh_local_pointee_structs
    self.task_locals = fresh_task_locals
    self.defer_stack = fresh_defer_stack
    self.errdefer_stack = fresh_errdefer_stack
    self.trait_locals = fresh_trait_locals
    self.trait_local_concrete_types = fresh_trait_local_concrete_types
    self.enum_local_types = fresh_enum_local_types
    self.scope_local_syms = fresh_scope_syms
    self.scope_local_allocas = fresh_scope_allocas
    self.scope_local_types = fresh_scope_types
    self.scope_local_count = 0
    self.expected_type = self.current_ret_type
    self.expected_type_node = 0
    self.current_result_err_symbol = 0
    self.current_fn_returns_result = false
    self.current_fn_saw_explicit_return = false
    self.tailrec_body_bb = 0
    self.tailrec_fn_sym = 0
    self.tailrec_param_allocas = fresh_tail_allocas
    self.reset_loop_state()

    let saved_mir_locals = self.mir_local_ptrs
    let saved_mir_local_types = self.mir_local_types
    let saved_mir_bbs = self.mir_bb_values
    let saved_mir_default_unreachable_bbs = self.mir_default_unreachable_bbs
    let fresh_mir_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_mir_bbs: Vec[i64] = Vec.new()
    let fresh_mir_default_unreachable_bbs: Vec[i64] = Vec.new()
    self.mir_local_ptrs = fresh_mir_locals
    self.mir_local_types = fresh_mir_local_types
    self.mir_bb_values = fresh_mir_bbs
    self.mir_default_unreachable_bbs = fresh_mir_default_unreachable_bbs

    let entry = wl_append_bb(self.context, function, "entry")
    wl_position_at_end(self.builder, entry)

    let ret_store_ty = if self.current_ret_type != wl_void_type(self.context): self.current_ret_type else: wl_i32_type(self.context)
    let ret_alloca = self.create_entry_alloca(ret_store_ty)
    self.mir_local_ptrs.insert(0, ret_alloca)
    self.mir_local_types.insert(0, ret_store_ty)

    let meta = self.pool.find_fn_meta(fn_node)
    var param_start = 0
    var param_count = 0
    if meta >= 0:
        param_start = self.pool.fn_meta_param_start(meta)
        param_count = self.pool.fn_meta_param_count(meta)

    // Detect method owner from mangled name (e.g. "Vec__i32.push")
    var method_owner_sym = 0
    for di in 0..name_str.len() as i32:
        if name_str.byte_at(di as i64) == 46:
            method_owner_sym = self.intern.intern(name_str.slice(0, di as i64))
            break
    self.current_method_owner_sym = method_owner_sym

    let max_params = param_count
    for pi in 0..max_params:
        let p_name = self.pool.fn_param_name(param_start, pi)
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        let param_val = wl_get_param(function, pi)
        let param_type = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_type)
        wl_build_store(self.builder, param_val, alloca)

        self.record_local(p_name, alloca, param_type, 1)

        self.mir_local_ptrs.insert(pi + 1, alloca)
        self.mir_local_types.insert(pi + 1, param_type)

        if p_type_node != 0:
            let pk = self.pool.kind(p_type_node)
            if pk == NK_TYPE_FN:
                let fn_sig = self.build_fn_type_from_ast(p_type_node)
                self.record_local_fn_sig(p_name, fn_sig)
            if pk == NK_TYPE_PTR or pk == NK_TYPE_REF:
                let pointee_node = self.pool.get_data0(p_type_node)
                if self.pool.kind(pointee_node) == NK_TYPE_NAMED:
                    let ps = self.pool.get_data0(pointee_node)
                    if self.struct_type_map.get(ps).is_some():
                        self.record_local_pointee_struct(p_name, ps)
            if pk == NK_TYPE_NAMED:
                let p_sym = self.pool.get_data0(p_type_node)
                let p_n = self.intern.resolve(p_sym)
                let p_name_text = self.intern.resolve(p_name)
                if method_owner_sym == 0 and p_name_text == "self" and self.struct_type_map.get(p_sym).is_some():
                    if self.intern.resolve(p_sym) != "str":
                        method_owner_sym = p_sym
                        self.current_method_owner_sym = method_owner_sym
                if method_owner_sym != 0 and (p_n == "Self" or p_sym == method_owner_sym):
                    let owner_n = self.intern.resolve(method_owner_sym)
                    if owner_n != "str":
                        self.record_local_pointee_struct(p_name, method_owner_sym)
            if method_owner_sym != 0:
                let p_n = self.intern.resolve(p_name)
                if p_n == "self":
                    let owner_n2 = self.intern.resolve(method_owner_sym)
                    if owner_n2 != "str":
                        self.record_local_pointee_struct(p_name, method_owner_sym)
            let trait_sym = self.dyn_trait_from_type_node(p_type_node)
            if trait_sym != 0:
                self.record_trait_local(p_name, trait_sym)

    for bb in 0..body.block_count():
        let bb_name = "mir.bb" ++ int_to_string(bb)
        let llbb = wl_append_bb(self.context, function, bb_name)
        self.mir_bb_values.push(llbb)

    if self.mir_bb_values.len() as i32 > 0:
        wl_build_br(self.builder, self.mir_bb_values.get(0))
    else:
        if self.current_ret_type == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
        else:
            let _ = wl_build_ret(self.builder, self.build_default_value(self.current_ret_type))

    for bb in 0..body.block_count():
        if bb < 0 or bb >= self.mir_bb_values.len() as i32:
            continue
        let llbb = self.mir_bb_values.get(bb as i64)
        wl_position_at_end(self.builder, llbb)
        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let stmt_count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            if not self.mir_emit_stmt(body, stmt_id):
                if wl_get_bb_terminator(llbb) == 0:
                    wl_build_unreachable(self.builder)
                break
        if wl_get_bb_terminator(llbb) == 0:
            let ok = self.mir_emit_term(body, bb)
            if not ok and wl_get_bb_terminator(llbb) == 0:
                wl_build_unreachable(self.builder)

    if self.mir_default_unreachable_bbs.len() as i32 > 0:
        let ubb = self.mir_default_unreachable_bbs.get(0)
        if wl_get_bb_terminator(ubb) == 0:
            wl_position_at_end(self.builder, ubb)
            wl_build_unreachable(self.builder)

    // Restore all codegen state
    self.current_function = saved_fn
    self.current_function_name_sym = saved_fn_name_sym
    self.current_ret_type = saved_ret
    self.current_method_owner_sym = saved_owner
    self.local_allocas = saved_allocas
    self.local_types = saved_types
    self.local_muts = saved_muts
    self.local_fn_sigs = saved_fn_sigs
    self.local_pointee_structs = saved_pointees
    self.task_locals = saved_task_locals
    self.trait_locals = saved_trait_locals
    self.trait_local_concrete_types = saved_trait_concrete
    self.enum_local_types = saved_enum_local_types
    self.local_sema_types = saved_sema_local_types
    self.scope_local_syms = saved_scope_syms
    self.scope_local_allocas = saved_scope_allocas
    self.scope_local_types = saved_scope_types
    self.scope_local_count = saved_scope_count
    self.defer_stack = saved_defer
    self.errdefer_stack = saved_errdefer
    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    self.current_result_err_symbol = saved_result_err
    self.current_fn_returns_result = saved_returns_result
    self.current_fn_saw_explicit_return = saved_saw_return
    self.tailrec_body_bb = saved_tail_bb
    self.tailrec_fn_sym = saved_tail_sym
    self.tailrec_param_allocas = saved_tail_allocas
    self.restore_loop_state(saved_loops)
    self.mir_local_ptrs = saved_mir_locals
    self.mir_local_types = saved_mir_local_types
    self.mir_bb_values = saved_mir_bbs
    self.mir_default_unreachable_bbs = saved_mir_default_unreachable_bbs
    if saved_bb != 0:
        wl_position_at_end(self.builder, saved_bb)

fn Codegen.find_struct_type_by_llvm(self: Codegen, llvm_ty: i64) -> i32:
    for i in 0..self.struct_llvm_types.len() as i32:
        if self.struct_llvm_types.get(i as i64) == llvm_ty:
            if i < self.struct_index_syms.len() as i32:
                return self.struct_index_syms.get(i as i64)
            return self.reverse_struct_lookup(i)
    0

fn Codegen.reverse_struct_lookup(self: Codegen, idx: i32) -> i32:
    // Slow reverse lookup: scan all known type syms
    // This is O(n) but only called for field access
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NK_TYPE_DECL:
            let sym = self.pool.get_data0(decl)
            let st = self.struct_type_map.get(sym)
            if st.is_some() and st.unwrap() == idx:
                return sym
    // Check built-in str
    let str_sym = self.intern.intern("str")
    let st = self.struct_type_map.get(str_sym)
    if st.is_some() and st.unwrap() == idx: return str_sym
    0

fn Codegen.find_struct_decl_node(self: Codegen, type_sym: i32) -> i32:
    for di in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(di)
        if self.pool.kind(decl) != NK_TYPE_DECL:
            continue
        if self.pool.get_data0(decl) != type_sym:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind == TDK_STRUCT:
            return decl
    0

fn Codegen.find_field_index_from_ast(self: Codegen, type_sym: i32, field_sym: i32) -> i32:
    let decl = self.find_struct_decl_node(type_sym)
    if decl == 0:
        return 0 - 1
    let extra_start = self.pool.get_data1(decl)
    let field_count = self.pool.get_extra(extra_start)
    let want_text = self.intern.resolve(field_sym)
    for fi in 0..field_count:
        let offset = extra_start + 1 + fi * 3
        let stored_sym = self.pool.get_extra(offset)
        if stored_sym == field_sym:
            return fi
        if want_text.len() > 0 and self.intern.resolve(stored_sym) == want_text:
            return fi
    0 - 1

fn Codegen.find_field_index(self: Codegen, type_sym: i32, field_sym: i32) -> i32:
    let st_opt = self.struct_type_map.get(type_sym)
    if not st_opt.is_some():
        return self.find_field_index_from_ast(type_sym, field_sym)
    let idx = st_opt.unwrap()
    let start = self.struct_field_starts.get(idx as i64)
    let count = self.struct_field_counts.get(idx as i64)
    let want_text = self.intern.resolve(field_sym)
    for i in 0..count:
        let stored_sym = self.struct_field_names.get((start + i) as i64)
        if stored_sym == field_sym:
            return i
        if want_text.len() > 0 and self.intern.resolve(stored_sym) == want_text:
            return i
    self.find_field_index_from_ast(type_sym, field_sym)

fn Codegen.find_binding_type(self: Codegen, syms: Vec[i32], tys: Vec[i64], sym: i32) -> i64:
    for i in 0..syms.len() as i32:
        if syms.get(i as i64) == sym:
            return tys.get(i as i64)
    0

fn Codegen.find_vec_elem_type_by_llvm(self: Codegen, vec_ty: i64) -> i64:
    let elem = self.vec_type_to_elem.get(vec_ty)
    if elem.is_some():
        return elem.unwrap()
    0



fn Codegen.find_option_payload_type_by_llvm(self: Codegen, opt_ty: i64) -> i64:
    for i in 0..self.option_llvm_types.len() as i32:
        if self.option_llvm_types.get(i as i64) == opt_ty:
            return self.option_payload_types.get(i as i64)
    0

fn Codegen.find_option_idx_by_llvm(self: Codegen, opt_ty: i64) -> i32:
    for i in 0..self.option_llvm_types.len() as i32:
        if self.option_llvm_types.get(i as i64) == opt_ty:
            return i
    0 - 1

fn Codegen.find_result_idx_by_llvm(self: Codegen, res_ty: i64) -> i32:
    for i in 0..self.result_llvm_types.len() as i32:
        if self.result_llvm_types.get(i as i64) == res_ty:
            return i
    0 - 1

fn Codegen.sema_type_mangle(self: Codegen, sema_ty: i32) -> str:
    if sema_ty <= 0:
        return "unknown"
    let resolved = self.sema.resolve_alias(sema_ty)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TY_INT:
        return "i32"
    if tk == TY_FLOAT:
        return "f64"
    if tk == TY_BOOL:
        return "bool"
    if tk == TY_STR:
        return "str"
    if tk == TY_VOID:
        return "void"
    if tk == TY_STRUCT:
        let name_sym = self.sema.get_type_d0(resolved)
        if name_sym != 0:
            return self.intern.resolve(name_sym)
        return "struct"
    if tk == TY_ENUM:
        let name_sym = self.sema.get_type_d0(resolved)
        if name_sym != 0:
            return self.intern.resolve(name_sym)
        return "enum"
    if tk == TY_PTR or tk == TY_REF:
        return "ptr"
    if tk == TY_ARRAY:
        return "array"
    if tk == TY_SLICE:
        return "slice"
    if tk == TY_TUPLE:
        return "tuple"
    if tk == TY_RANGE:
        return "range"
    if tk == TY_GENERIC_INST:
        let name_sym = self.sema.get_type_d0(resolved)
        if name_sym != 0:
            return self.intern.resolve(name_sym)
        return "generic"
    if tk == TY_NEVER:
        return "never"
    "unknown"

fn Codegen.llvm_type_mangle(self: Codegen, ty: i64) -> str:
    if ty == 0:
        return "unknown"
    let tk = wl_get_type_kind(ty)
    if tk == wl_void_type_kind():
        return "void"
    if tk == wl_integer_type_kind():
        let w = wl_get_int_type_width(ty)
        if w == 1: return "bool"
        if w == 8: return "i8"
        if w == 16: return "i16"
        if w == 32: return "i32"
        if w == 64: return "i64"
        if w == 128: return "i128"
        return "int"
    if tk == wl_float_type_kind():
        return "f32"
    if tk == wl_double_type_kind():
        return "f64"
    if tk == wl_pointer_type_kind():
        return "ptr"
    if self.is_str_type(ty):
        return "str"
    if tk == wl_struct_type_kind():
        let st_sym = self.find_struct_type_by_llvm(ty)
        if st_sym != 0:
            return self.intern.resolve(st_sym)
        let es = self.enum_by_llvm.get(ty)
        if es.is_some():
            return self.intern.resolve(es.unwrap())
        return "struct"
    if tk == wl_array_type_kind():
        return "array"
    "unknown"

fn Codegen.monomorphize_generic_call_core(self: Codegen, fn_sym: i32, fn_node: i32, args_start: i32, arg_count: i32, call_node: i32, arg_vals: Vec[i64], arg_tys: Vec[i64], arg_nodes: Vec[i32]) -> i64:
    var generic_node = fn_node
    var meta = self.pool.find_fn_meta(generic_node)
    if self.pool.kind(generic_node) != NK_FN_DECL or self.pool.get_data0(generic_node) != fn_sym or meta < 0 or self.pool.fn_meta_tp_count(meta) <= 0:
        for di in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(di)
            if self.pool.kind(decl) != NK_FN_DECL:
                continue
            if self.pool.get_data0(decl) != fn_sym:
                continue
            let dmeta = self.pool.find_fn_meta(decl)
            if dmeta >= 0 and self.pool.fn_meta_tp_count(dmeta) > 0:
                generic_node = decl
                meta = dmeta
                break

    if meta < 0:
        with_eprintln("warning: [optional-chain] chain resolution failed")
        return wl_get_undef(wl_i32_type(self.context))

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)
    let tp_start = self.pool.fn_meta_tp_start(meta)
    let tp_count = self.pool.fn_meta_tp_count(meta)
    let body_node = self.pool.get_data1(generic_node)
    if param_count < 0 or param_count > 64:
        with_eprintln("warning: [optional-chain] chain resolution failed")
        return wl_get_undef(wl_i32_type(self.context))

    let tp_syms: Vec[i32] = Vec.new()
    var tp_pos = tp_start
    for ti in 0..tp_count:
        let tp_sym = self.pool.get_extra(tp_pos)
        tp_syms.push(tp_sym)
        let bound_count = self.pool.get_extra(tp_pos + 1)
        tp_pos = tp_pos + 2 + bound_count

    let bind_syms: Vec[i32] = Vec.new()
    let bind_tys: Vec[i64] = Vec.new()
    let bind_sema_tys: Vec[i32] = Vec.new()
    for pi in 0..param_count:
        if pi >= arg_count:
            break
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if p_type_node == 0:
            continue

        let arg_ty = arg_tys.get(pi as i64)
        let p_kind = self.pool.kind(p_type_node)

        if p_kind == NK_TYPE_NAMED:
            let p_sym = self.pool.get_data0(p_type_node)
            var is_tp = false
            for ti in 0..tp_syms.len() as i32:
                if tp_syms.get(ti as i64) == p_sym:
                    is_tp = true
                    break
            if is_tp:
                var exists = false
                for bi in 0..bind_syms.len() as i32:
                    if bind_syms.get(bi as i64) == p_sym:
                        exists = true
                        break
                if not exists:
                    bind_syms.push(p_sym)
                    bind_tys.push(arg_ty)
                    // Get sema type for this binding
                    let arg_sema = self.sema_type_of_node(arg_nodes.get(pi as i64))
                    if arg_sema > 0:
                        bind_sema_tys.push(arg_sema)
                    else:
                        bind_sema_tys.push(self.llvm_type_to_sema_type(arg_ty))
            continue

        if p_kind == NK_TYPE_GENERIC:
            let g_name_sym = self.pool.get_data0(p_type_node)
            let g_name = self.intern.resolve(g_name_sym)
            let g_extra = self.pool.get_data1(p_type_node)
            let g_count = self.pool.get_data2(p_type_node)

            // Sema-based generic type param binding: infer from sema types first
            let mg_arg_sema_tid = self.sema_type_of_node(arg_nodes.get(pi as i64))
            if mg_arg_sema_tid > 0 and self.sema.get_type_kind(mg_arg_sema_tid) == TY_GENERIC_INST:
                var mg_sema_bound = true
                for gi in 0..g_count:
                    let mg_inner_node = self.pool.get_extra(g_extra + gi)
                    if self.pool.kind(mg_inner_node) != NK_TYPE_NAMED:
                        mg_sema_bound = false
                        break
                    let mg_inner_sym = self.pool.get_data0(mg_inner_node)
                    var mg_is_tp = false
                    for ti in 0..tp_syms.len() as i32:
                        if tp_syms.get(ti as i64) == mg_inner_sym:
                            mg_is_tp = true
                            break
                    if not mg_is_tp:
                        mg_sema_bound = false
                        break
                    let mg_inner_ty = self.sema_generic_arg_llvm(mg_arg_sema_tid, gi)
                    if mg_inner_ty == 0:
                        mg_sema_bound = false
                        break
                    var mg_exists = false
                    for bi in 0..bind_syms.len() as i32:
                        if bind_syms.get(bi as i64) == mg_inner_sym:
                            mg_exists = true
                            break
                    if not mg_exists:
                        bind_syms.push(mg_inner_sym)
                        bind_tys.push(mg_inner_ty)
                        // Get sema type from generic inst arg
                        bind_sema_tys.push(self.sema.get_generic_inst_arg(mg_arg_sema_tid, gi))
                if mg_sema_bound:
                    continue

    let base_name = self.intern.resolve(fn_sym)
    var mangled = base_name
    for ti in 0..tp_syms.len() as i32:
        let tp_sym = tp_syms.get(ti as i64)
        let bty = self.find_binding_type(bind_syms, bind_tys, tp_sym)
        if bty == 0:
            with_eprintln("error: unknown type")
            self.had_error = 1
            return wl_get_undef(wl_i32_type(self.context))
        // Use sema type for mangling when available (LLVM types lose struct identity)
        var sema_mangle = "unknown"
        for bi in 0..bind_syms.len() as i32:
            if bind_syms.get(bi as i64) == tp_sym:
                let sema_ty = bind_sema_tys.get(bi as i64)
                if sema_ty > 0:
                    sema_mangle = self.sema_type_mangle(sema_ty)
                break
        if sema_mangle == "unknown":
            sema_mangle = self.llvm_type_mangle(bty)
        mangled = mangled ++ "__" ++ sema_mangle

    let mono_sym = self.intern.intern(mangled)
    let mono_key = mono_sym as i64
    let mono_cached_fv = self.mono_values.get(mono_key)
    let mono_cached_ft = self.mono_types.get(mono_key)
    if mono_cached_fv.is_some() and mono_cached_ft.is_some():
        let coerced = self.coerce_call_args_for_fn_value(mono_sym, mono_cached_fv.unwrap() as i64, args_start, 0, arg_vals, arg_count, "call " ++ mangled, call_node)
        return wl_build_call(self.builder, mono_cached_ft.unwrap() as i64, mono_cached_fv.unwrap() as i64, vec_data_i64(&coerced), arg_count)

    let cached_fv = self.fn_values.get(mono_sym)
    let cached_ft = self.fn_fn_types.get(mono_sym)
    if cached_fv.is_some() and cached_ft.is_some():
        self.mono_values.insert(mono_key, cached_fv.unwrap() as i64)
        self.mono_types.insert(mono_key, cached_ft.unwrap() as i64)
        let coerced = self.coerce_call_args_for_fn_value(mono_sym, cached_fv.unwrap() as i64, args_start, 0, arg_vals, arg_count, "call " ++ mangled, call_node)
        return wl_build_call(self.builder, cached_ft.unwrap() as i64, cached_fv.unwrap() as i64, vec_data_i64(&coerced), arg_count)

    let saved_bind_syms = self.type_binding_syms
    let saved_bind_tys = self.type_binding_types
    let saved_bind_len = self.type_bindings_len
    let fresh_bind_syms: Vec[i32] = Vec.new()
    let fresh_bind_tys: Vec[i64] = Vec.new()
    self.type_binding_syms = fresh_bind_syms
    self.type_binding_types = fresh_bind_tys
    self.type_bindings_len = 0
    for bi in 0..bind_syms.len() as i32:
        self.type_binding_syms.push(bind_syms.get(bi as i64))
        // Use sema-derived LLVM type for correct struct identity (wl_type_of may flatten)
        let sema_ty_for_bind = bind_sema_tys.get(bi as i64)
        var llvm_ty_for_bind = bind_tys.get(bi as i64)
        if sema_ty_for_bind > 0:
            let sema_llvm = self.sema_type_to_llvm(sema_ty_for_bind)
            if sema_llvm != 0:
                llvm_ty_for_bind = sema_llvm
        self.type_binding_types.push(llvm_ty_for_bind)
        self.type_bindings_len = self.type_bindings_len + 1

    let mono_param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if p_type_node != 0:
            let p_ty = self.resolve_type(p_type_node)
            if p_ty == 0:
                self.type_binding_syms = saved_bind_syms
                self.type_binding_types = saved_bind_tys
                self.type_bindings_len = saved_bind_len
                with_eprintln("error: unknown type")
                self.had_error = 1
                return wl_get_undef(wl_i32_type(self.context))
            mono_param_types.push(p_ty)
        else if pi < arg_count:
            mono_param_types.push(arg_tys.get(pi as i64))
        else:
            mono_param_types.push(wl_i32_type(self.context))
    let mono_ret_ty = if ret_type_node != 0: self.resolve_type(ret_type_node) else: wl_i32_type(self.context)
    if mono_ret_ty == 0:
        self.type_binding_syms = saved_bind_syms
        self.type_binding_types = saved_bind_tys
        self.type_bindings_len = saved_bind_len
        with_eprintln("error: unknown type")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    let mono_ft = wl_function_type(mono_ret_ty, vec_data_i64(&mono_param_types), param_count, 0)
    let mono_fn = wl_add_function(self.llmod, mangled, mono_ft)
    self.apply_noalias_param_attrs(mono_fn, param_start, param_count)
    self.mono_values.insert(mono_key, mono_fn)
    self.mono_types.insert(mono_key, mono_ft)
    self.fn_values.insert(mono_sym, mono_fn)
    self.fn_fn_types.insert(mono_sym, mono_ft)

    // Build sema type bindings for each type param
    let tp_sema_tys: Vec[i32] = Vec.new()
    for ti in 0..tp_syms.len() as i32:
        let tp_sym = tp_syms.get(ti as i64)
        var sema_ty = 0
        for bi in 0..bind_syms.len() as i32:
            if bind_syms.get(bi as i64) == tp_sym:
                sema_ty = bind_sema_tys.get(bi as i64)
                break
        tp_sema_tys.push(sema_ty)

    // 1. Type-check body with concrete types
    let sig_idx = self.sema.check_fn_body_concrete(generic_node, tp_syms, tp_sema_tys, mono_sym)

    // 2. Lower to MIR
    var mir_builder = MirBuilder.init(self.sema, self.pool, self.intern, mono_sym)
    let mir_body = lower_fn_with_sig(mir_builder, generic_node, sig_idx)

    // 3. Codegen via MIR (saves/restores all codegen state internally)
    self.gen_function_mir_mono(mono_sym, generic_node, mir_body)

    self.type_binding_syms = saved_bind_syms
    self.type_binding_types = saved_bind_tys
    self.type_bindings_len = saved_bind_len

    let coerced = self.coerce_call_args_for_fn_value(mono_sym, mono_fn, args_start, 0, arg_vals, arg_count, "call " ++ mangled, call_node)
    wl_build_call(self.builder, mono_ft, mono_fn, vec_data_i64(&coerced), arg_count)

// ── Call expression ───────────────────────────────────────────────

fn Codegen.get_mutable_receiver_ptr(self: Codegen, recv_node: i32, recv_val: i64, recv_ty: i64) -> i64:
    let rk = self.pool.kind(recv_node)
    if rk == NK_IDENT:
        let sym = self.pool.get_data0(recv_node)
        let alloca = self.lookup_local_alloca(sym)
        if alloca != 0:
            let local_ty = self.lookup_local_type(sym)
            if local_ty != 0:
                let pointee_sym = self.lookup_local_pointee_struct(sym)
                if wl_get_type_kind(local_ty) == wl_pointer_type_kind() and pointee_sym != 0:
                    return wl_build_load(self.builder, local_ty, alloca)
            return alloca
    if wl_get_type_kind(recv_ty) == wl_pointer_type_kind():
        return recv_val
    let alloca = wl_build_alloca(self.builder, recv_ty)
    wl_build_store(self.builder, recv_val, alloca)
    alloca

// ── While loop ────────────────────────────────────────────────────

fn Codegen.build_variant_payload_val(self: Codegen, payload_ty: i64, args: Vec[i64], arg_count: i32) -> i64:
    if arg_count <= 0:
        return wl_get_undef(wl_i32_type(self.context))
    if payload_ty == 0:
        return args.get(0)
    if arg_count == 1:
        return self.coerce_value_to_type(args.get(0), payload_ty)
    if wl_get_type_kind(payload_ty) == wl_struct_type_kind():
        var payload = wl_get_undef(payload_ty)
        let field_count = wl_count_struct_elem_types(payload_ty)
        var ai = 0
        while ai < arg_count and ai < field_count:
            let field_ty = wl_struct_get_type_at(payload_ty, ai)
            let coerced = self.coerce_value_to_type(args.get(ai as i64), field_ty)
            payload = wl_build_insert_value(self.builder, payload, coerced, ai)
            ai = ai + 1
        return payload
    self.coerce_value_to_type(args.get(0), payload_ty)

fn Codegen.gen_enum_variant_call_val(self: Codegen, variant_sym: i32, args: Vec[i64], arg_count: i32) -> i64:
    let variant_name = self.intern.resolve(variant_sym)
    for ei in 0..self.enum_llvm_types.len() as i32:
        let v_start = self.enum_variant_starts.get(ei as i64)
        let v_count = self.enum_variant_counts.get(ei as i64)
        for vi in 0..v_count:
            let stored_sym = self.enum_variant_names.get((v_start + vi) as i64)
            if stored_sym != variant_sym:
                let stored_name = self.intern.resolve(stored_sym)
                if stored_name != variant_name:
                    continue
            let enum_ty = self.enum_llvm_types.get(ei as i64)
            let alloca = wl_build_alloca(self.builder, enum_ty)
            wl_build_store(self.builder, self.build_default_value(enum_ty), alloca)
            let tag_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 0)
            var tag_val: i64 = 0
            let enum_sym_opt = self.enum_by_llvm.get(enum_ty)
            var is_disc = false
            if enum_sym_opt.is_some():
                let de_opt = self.disc_enum_type_map.get(enum_sym_opt.unwrap())
                if de_opt.is_some():
                    is_disc = true
                    let de_idx = de_opt.unwrap()
                    let dv_start = self.disc_enum_variant_starts.get(de_idx as i64)
                    let disc_val = self.disc_enum_variant_values.get((dv_start + vi) as i64)
                    let repr_ty = self.disc_enum_repr_types.get(de_idx as i64)
                    tag_val = wl_const_int(repr_ty, disc_val as i64, 1)
            if not is_disc:
                tag_val = wl_const_int(wl_i32_type(self.context), vi as i64, 0)
            wl_build_store(self.builder, tag_val, tag_ptr)
            if arg_count > 0:
                let payload_ty = self.enum_variant_payloads.get((v_start + vi) as i64)
                let elem_count = wl_count_struct_elem_types(enum_ty)
                if payload_ty != 0 and elem_count > 1:
                    let payload = self.build_variant_payload_val(payload_ty, args, arg_count)
                    let payload_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 1)
                    let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
                    wl_build_store(self.builder, payload, cast_ptr)
            return wl_build_load(self.builder, enum_ty, alloca)
    0

// ── Struct literal ────────────────────────────────────────────────

fn Codegen.gen_closure(self: Codegen, node: i32) -> i64:
    // Closure: create an anonymous function and return fat pointer {fn_ptr, ctx_ptr}
    // Calling convention: fn(ctx_ptr, params...) -> ret_ty
    // NK_CLOSURE layout: d0=body, d1=extra_start, d2=param_count
    let body_node = self.pool.get_data0(node)
    let extra_start = self.pool.get_data1(node)
    let param_count = self.pool.get_data2(node)
    let ptr_ty = wl_ptr_type(self.context)
    let i32_ty = wl_i32_type(self.context)

    // Collect captured variables from enclosing scope
    // First, temporarily mark closure params so collect_captures skips them
    let param_syms: Vec[i32] = Vec.new()
    for i in 0..param_count:
        param_syms.push(self.pool.get_extra(extra_start + i * 2))
    let fresh_captures: Vec[i32] = Vec.new()
    self.async_block_captures = fresh_captures
    self.collect_captures(body_node)
    // Remove closure params from captures (they are not free variables)
    let captures: Vec[i32] = Vec.new()
    for ci in 0..self.async_block_captures.len() as i32:
        let sym = self.async_block_captures.get(ci as i64)
        var is_param = 0
        for pi in 0..param_count:
            if param_syms.get(pi as i64) == sym:
                is_param = 1
        if is_param == 0:
            captures.push(sym)
    let capture_count = captures.len() as i32

    // Determine if this is a non-escaping closure (reference capture)
    let is_ref_capture = self.pool.is_non_escaping_closure(node) == 1 and self.pool.is_move_closure(node) == 0

    // Build capture struct type from captured variable types
    let cap_types: Vec[i64] = Vec.new()
    for ci in 0..capture_count:
        let sym = captures.get(ci as i64)
        if is_ref_capture:
            cap_types.push(ptr_ty)
        else:
            let ty_opt = self.local_types.get(sym)
            if ty_opt.is_some():
                cap_types.push(ty_opt.unwrap() as i64)
            else:
                cap_types.push(i32_ty)
    // Collect original types for ref capture (needed inside closure body)
    let cap_orig_types: Vec[i64] = Vec.new()
    if is_ref_capture:
        for ci in 0..capture_count:
            let sym = captures.get(ci as i64)
            let ty_opt = self.local_types.get(sym)
            if ty_opt.is_some():
                cap_orig_types.push(ty_opt.unwrap() as i64)
            else:
                cap_orig_types.push(i32_ty)
    var cap_struct_type: i64 = 0
    if capture_count > 0:
        cap_struct_type = wl_struct_type(self.context, vec_data_i64(&cap_types), capture_count, 0)

    // Build parameter types: context ptr first, then user params
    let param_types: Vec[i64] = Vec.new()
    param_types.push(ptr_ty)
    for i in 0..param_count:
        let p_type = self.pool.get_extra(extra_start + i * 2 + 1)
        if p_type != 0:
            param_types.push(self.resolve_type(p_type))
        else:
            param_types.push(i32_ty)
    // Determine return type (infer from context or use i32)
    let ret_ty = i32_ty
    let fn_ty = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count + 1, 0)
    let closure_fn = wl_add_function(self.llmod, "__closure", fn_ty)
    // Save current state
    let saved_fn = self.current_function
    let saved_ret = self.current_ret_type
    let saved_bb = wl_get_insert_block(self.builder)
    let saved_allocas = self.local_allocas
    let saved_types = self.local_types
    let saved_muts = self.local_muts
    let saved_loops = self.capture_loop_state()
    let fresh_closure_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_closure_types: HashMap[i32, i64] = HashMap.new()
    let fresh_closure_muts: HashMap[i32, i32] = HashMap.new()
    self.local_allocas = fresh_closure_locals
    self.local_types = fresh_closure_types
    self.local_muts = fresh_closure_muts
    self.reset_loop_state()
    // Build closure body
    self.current_function = closure_fn
    self.current_ret_type = ret_ty
    let entry = wl_append_bb(self.context, closure_fn, "entry")
    wl_position_at_end(self.builder, entry)

    // Load captured values from context pointer (param 0)
    if capture_count > 0:
        let cap_ptr = wl_get_param(closure_fn, 0)
        for ci in 0..capture_count:
            let sym = captures.get(ci as i64)
            let cap_ty = cap_types.get(ci as i64)
            let indices: Vec[i64] = Vec.new()
            indices.push(wl_const_int(i32_ty, 0, 0))
            indices.push(wl_const_int(i32_ty, ci as i64, 0))
            let gep = wl_build_gep(self.builder, cap_struct_type, cap_ptr, vec_data_i64(&indices), 2)
            if is_ref_capture:
                // Reference capture: load the pointer to outer alloca, use directly
                let outer_ptr = wl_build_load(self.builder, ptr_ty, gep)
                let orig_ty = cap_orig_types.get(ci as i64)
                // Look up outer mutability
                let outer_mut_opt = saved_muts.get(sym)
                let outer_mut = if outer_mut_opt.is_some(): outer_mut_opt.unwrap() else: 0
                self.record_local(sym, outer_ptr, orig_ty, outer_mut)
            else:
                // Value capture: load value, create fresh alloca
                let loaded = wl_build_load(self.builder, cap_ty, gep)
                let alloca = self.create_entry_alloca(cap_ty)
                wl_build_store(self.builder, loaded, alloca)
                self.record_local(sym, alloca, cap_ty, 0)

    // Add params as locals (skip param 0 which is context ptr)
    for i in 0..param_count:
        let p_name = self.pool.get_extra(extra_start + i * 2)
        let param_val = wl_get_param(closure_fn, i + 1)
        let param_ty = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_ty)
        wl_build_store(self.builder, param_val, alloca)
        self.record_local(p_name, alloca, param_ty, 1)
    // ── MIR-based closure body compilation ──────────────────────
    // Save outer MIR state (gen_closure is called from within MIR codegen)
    let saved_mir_locals = self.mir_local_ptrs
    let saved_mir_local_types = self.mir_local_types
    let saved_mir_bbs = self.mir_bb_values
    let saved_mir_unreachable = self.mir_default_unreachable_bbs
    let fresh_cl_mir_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_cl_mir_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_cl_mir_bbs: Vec[i64] = Vec.new()
    let fresh_cl_mir_unreachable: Vec[i64] = Vec.new()
    self.mir_local_ptrs = fresh_cl_mir_locals
    self.mir_local_types = fresh_cl_mir_local_types
    self.mir_bb_values = fresh_cl_mir_bbs
    self.mir_default_unreachable_bbs = fresh_cl_mir_unreachable

    // Create MirBuilder for the closure body
    var closure_builder = MirBuilder.init(self.sema, self.pool, self.intern, 0)
    // Set return type (try sema inference, default to i32)
    let ret_sema_ty = self.sema_type_of_node(body_node)
    if ret_sema_ty != 0 and ret_sema_ty != self.sema.ty_void:
        closure_builder.body.local_type_ids.set_i32(0, ret_sema_ty)
    else:
        closure_builder.body.local_type_ids.set_i32(0, self.sema.ty_i32)

    closure_builder.push_scope()

    // Register captures as MIR locals (locals 1..capture_count)
    for cl_ci in 0..capture_count:
        let cl_cap_sym = captures.get(cl_ci as i64)
        var cl_cap_sema_ty = self.sema.ty_i32
        let cl_cap_sema_opt = self.local_sema_types.get(cl_cap_sym)
        if cl_cap_sema_opt.is_some():
            cl_cap_sema_ty = cl_cap_sema_opt.unwrap()
        let cl_cap_local = closure_builder.body.new_local(cl_cap_sema_ty, 0, cl_cap_sym, 1)
        closure_builder.bind_local(cl_cap_sym, cl_cap_local)

    // Register params as MIR locals (locals capture_count+1..)
    for cl_pi in 0..param_count:
        let cl_p_name = self.pool.get_extra(extra_start + cl_pi * 2)
        let cl_p_type_node = self.pool.get_extra(extra_start + cl_pi * 2 + 1)
        var cl_p_sema_ty = self.sema.ty_i32
        if cl_p_type_node > 0:
            if self.sema.typed_expr_types.contains(cl_p_type_node):
                let cl_tt = self.sema.typed_expr_types.get(cl_p_type_node).unwrap()
                if cl_tt > 0:
                    cl_p_sema_ty = cl_tt
            if cl_p_sema_ty == self.sema.ty_i32:
                let cl_pk = self.pool.kind(cl_p_type_node)
                if cl_pk == NK_TYPE_NAMED or cl_pk == NK_IDENT:
                    let cl_type_sym = self.pool.get_data0(cl_p_type_node)
                    let cl_prim = self.sema.primitive_type_by_sym(cl_type_sym)
                    if cl_prim != 0:
                        cl_p_sema_ty = cl_prim
                    else if self.sema.named_types.contains(cl_type_sym):
                        cl_p_sema_ty = self.sema.named_types.get(cl_type_sym).unwrap()
        let cl_p_local = closure_builder.body.new_local(cl_p_sema_ty, 1, cl_p_name, 1)
        closure_builder.bind_local(cl_p_name, cl_p_local)

    closure_builder.expected_type = closure_builder.body.local_type_ids.get(0)

    // Lower the closure body expression to MIR
    let cl_result = closure_builder.lower_expr(body_node)
    let cl_ret_place = closure_builder.place_for_local(0)
    closure_builder.assign_operand_to_place(cl_ret_place, cl_result, self.pool.get_end(body_node))
    closure_builder.pop_scope_inline()
    closure_builder.terminate(TK_RETURN, 0, 0, 0, 0)
    let closure_body = closure_builder.body

    // Set up return alloca (MIR local 0)
    let cl_ret_alloca = self.create_entry_alloca(ret_ty)
    self.mir_local_ptrs.insert(0, cl_ret_alloca)
    self.mir_local_types.insert(0, ret_ty)

    // Map capture MIR locals to existing LLVM allocas
    for cl_mi in 0..capture_count:
        let cl_m_sym = captures.get(cl_mi as i64)
        let cl_m_local_id = cl_mi + 1
        let cl_m_alloca_opt = self.local_allocas.get(cl_m_sym)
        if cl_m_alloca_opt.is_some():
            self.mir_local_ptrs.insert(cl_m_local_id, cl_m_alloca_opt.unwrap())
            let cl_m_ty_opt = self.local_types.get(cl_m_sym)
            if cl_m_ty_opt.is_some():
                self.mir_local_types.insert(cl_m_local_id, cl_m_ty_opt.unwrap())

    // Map param MIR locals to existing LLVM allocas
    for cl_pmi in 0..param_count:
        let cl_pm_name = self.pool.get_extra(extra_start + cl_pmi * 2)
        let cl_pm_local_id = capture_count + cl_pmi + 1
        let cl_pm_alloca_opt = self.local_allocas.get(cl_pm_name)
        if cl_pm_alloca_opt.is_some():
            self.mir_local_ptrs.insert(cl_pm_local_id, cl_pm_alloca_opt.unwrap())
            let cl_pm_ty_opt = self.local_types.get(cl_pm_name)
            if cl_pm_ty_opt.is_some():
                self.mir_local_types.insert(cl_pm_local_id, cl_pm_ty_opt.unwrap())

    // Pre-populate globals
    for cl_gli in 0..closure_body.local_names.len() as i32:
        let cl_gl_name = closure_body.local_names.get(cl_gli as i64)
        if cl_gl_name != 0:
            let cl_gl_mc = self.module_constants.get(cl_gl_name)
            if cl_gl_mc.is_some():
                self.mir_local_ptrs.insert(cl_gli, cl_gl_mc.unwrap() as i64)

    // Create LLVM basic blocks for MIR blocks
    for cl_bb in 0..closure_body.block_count():
        let cl_bb_name = "mir.bb" ++ int_to_string(cl_bb)
        let cl_llbb = wl_append_bb(self.context, closure_fn, cl_bb_name)
        self.mir_bb_values.push(cl_llbb)

    // Branch from entry to first MIR BB
    if self.mir_bb_values.len() as i32 > 0:
        wl_build_br(self.builder, self.mir_bb_values.get(0))
    else:
        let _ = wl_build_ret(self.builder, wl_const_int(ret_ty, 0, 0))

    // Emit MIR statements and terminators
    for cl_bb in 0..closure_body.block_count():
        if cl_bb < 0 or cl_bb >= self.mir_bb_values.len() as i32:
            continue
        let cl_llbb = self.mir_bb_values.get(cl_bb as i64)
        wl_position_at_end(self.builder, cl_llbb)
        let cl_stmt_start = closure_body.bb_stmt_starts.get(cl_bb as i64)
        let cl_stmt_count = closure_body.bb_stmt_counts.get(cl_bb as i64)
        for cl_si in 0..cl_stmt_count:
            let cl_stmt_id = cl_stmt_start + cl_si
            if not self.mir_emit_stmt(closure_body, cl_stmt_id):
                if wl_get_bb_terminator(cl_llbb) == 0:
                    wl_build_unreachable(self.builder)
        if wl_get_bb_terminator(cl_llbb) == 0:
            if not self.mir_emit_term(closure_body, cl_bb):
                if wl_get_bb_terminator(cl_llbb) == 0:
                    let _ = wl_build_ret(self.builder, wl_const_int(ret_ty, 0, 0))

    // Restore outer MIR state
    self.mir_local_ptrs = saved_mir_locals
    self.mir_local_types = saved_mir_local_types
    self.mir_bb_values = saved_mir_bbs
    self.mir_default_unreachable_bbs = saved_mir_unreachable
    // Restore state
    self.current_function = saved_fn
    self.current_ret_type = saved_ret
    wl_position_at_end(self.builder, saved_bb)
    self.local_allocas = saved_allocas
    self.local_types = saved_types
    self.local_muts = saved_muts
    self.restore_loop_state(saved_loops)

    // Build capture struct on stack and store captured values
    var ctx_ptr = wl_const_null(ptr_ty)
    if capture_count > 0:
        let cap_alloca = wl_build_alloca(self.builder, cap_struct_type)
        for ci in 0..capture_count:
            let sym = captures.get(ci as i64)
            let cap_ty = cap_types.get(ci as i64)
            let alloca_opt = saved_allocas.get(sym)
            if alloca_opt.is_some():
                let indices: Vec[i64] = Vec.new()
                indices.push(wl_const_int(i32_ty, 0, 0))
                indices.push(wl_const_int(i32_ty, ci as i64, 0))
                let gep = wl_build_gep(self.builder, cap_struct_type, cap_alloca, vec_data_i64(&indices), 2)
                if is_ref_capture:
                    // Store pointer to outer alloca (not the value)
                    wl_build_store(self.builder, alloca_opt.unwrap() as i64, gep)
                else:
                    // Store the value
                    let val = wl_build_load(self.builder, cap_ty, alloca_opt.unwrap() as i64)
                    wl_build_store(self.builder, val, gep)
        ctx_ptr = cap_alloca

    // Build fat pointer {fn_ptr, ctx_ptr}
    let fat_types: Vec[i64] = Vec.new()
    fat_types.push(ptr_ty)
    fat_types.push(ptr_ty)
    let fat_ty = wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)
    var fat_val = wl_get_undef(fat_ty)
    fat_val = wl_build_insert_value(self.builder, fat_val, closure_fn, 0)
    fat_val = wl_build_insert_value(self.builder, fat_val, ctx_ptr, 1)
    fat_val

// ── Pipeline ──────────────────────────────────────────────────────

fn Codegen.ensure_async_runtime_declared(self: Codegen):
    let i32_ty = wl_i32_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let void_ty = wl_void_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)

    // void with_runtime_init(void)
    if wl_get_named_function(self.llmod, "with_runtime_init") == 0:
        let no_params: Vec[i64] = Vec.new()
        let ft = wl_function_type(void_ty, vec_data_i64(&no_params), 0, 0)
        wl_add_function(self.llmod, "with_runtime_init", ft)

    // void with_runtime_run(void)
    if wl_get_named_function(self.llmod, "with_runtime_run") == 0:
        let no_params: Vec[i64] = Vec.new()
        let ft = wl_function_type(void_ty, vec_data_i64(&no_params), 0, 0)
        wl_add_function(self.llmod, "with_runtime_run", ft)

    // void with_runtime_shutdown(void)
    if wl_get_named_function(self.llmod, "with_runtime_shutdown") == 0:
        let no_params: Vec[i64] = Vec.new()
        let ft = wl_function_type(void_ty, vec_data_i64(&no_params), 0, 0)
        wl_add_function(self.llmod, "with_runtime_shutdown", ft)

    // i32 with_fiber_spawn(fn_ptr: ptr, arg: ptr) -> i32
    if wl_get_named_function(self.llmod, "with_fiber_spawn") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        let ft = wl_function_type(i32_ty, vec_data_i64(&params), 2, 0)
        wl_add_function(self.llmod, "with_fiber_spawn", ft)

    // i64 with_fiber_await(task_id: i32) -> i64
    if wl_get_named_function(self.llmod, "with_fiber_await") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(i32_ty)
        let ft = wl_function_type(i64_ty, vec_data_i64(&params), 1, 0)
        wl_add_function(self.llmod, "with_fiber_await", ft)

    // i32 with_fiber_cancel(task_id: i32) -> i32
    if wl_get_named_function(self.llmod, "with_fiber_cancel") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(i32_ty)
        let ft = wl_function_type(i32_ty, vec_data_i64(&params), 1, 0)
        wl_add_function(self.llmod, "with_fiber_cancel", ft)

    // void with_fiber_set_result(value: i64)
    if wl_get_named_function(self.llmod, "with_fiber_set_result") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(i64_ty)
        let ft = wl_function_type(void_ty, vec_data_i64(&params), 1, 0)
        wl_add_function(self.llmod, "with_fiber_set_result", ft)

    // void with_fiber_yield(void)
    if wl_get_named_function(self.llmod, "with_fiber_yield") == 0:
        let no_params: Vec[i64] = Vec.new()
        let ft = wl_function_type(void_ty, vec_data_i64(&no_params), 0, 0)
        wl_add_function(self.llmod, "with_fiber_yield", ft)

    // i32 with_fiber_select(ids: ptr, count: i32, result_out: ptr) -> i32
    if wl_get_named_function(self.llmod, "with_fiber_select") == 0:
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(i32_ty)
        params.push(ptr_ty)
        let ft = wl_function_type(i32_ty, vec_data_i64(&params), 3, 0)
        wl_add_function(self.llmod, "with_fiber_select", ft)

    self.uses_async = true

fn Codegen.ensure_malloc_declared(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "malloc")
    if existing != 0: return existing
    let ptr_ty = wl_ptr_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let params: Vec[i64] = Vec.new()
    params.push(i64_ty)
    let ft = wl_function_type(ptr_ty, vec_data_i64(&params), 1, 0)
    wl_add_function(self.llmod, "malloc", ft)

fn Codegen.pack_result_to_i64(self: Codegen, val: i64, val_ty: i64) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let void_ty = wl_void_type(self.context)
    if val_ty == void_ty:
        return wl_const_int(i64_ty, 0, 0)
    if val_ty == i64_ty:
        return val
    let kind = wl_get_type_kind(val_ty)
    // Integer types: zext to i64
    if kind == wl_integer_type_kind():
        return wl_build_zext(self.builder, val, i64_ty)
    // Pointer types: ptrtoint
    if kind == wl_pointer_type_kind():
        return wl_build_ptr_to_int(self.builder, val, i64_ty)
    // Fallback: bitcast via alloca
    let alloca = wl_build_alloca(self.builder, i64_ty)
    wl_build_store(self.builder, val, alloca)
    wl_build_load(self.builder, i64_ty, alloca)

fn Codegen.unpack_result_from_i64(self: Codegen, val: i64, target_ty: i64) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    if target_ty == i64_ty:
        return val
    if target_ty == i32_ty:
        return wl_build_trunc(self.builder, val, i32_ty)
    let kind = wl_get_type_kind(target_ty)
    if kind == wl_integer_type_kind():
        return wl_build_trunc(self.builder, val, target_ty)
    if kind == wl_pointer_type_kind():
        return wl_build_int_to_ptr(self.builder, val, target_ty)
    // Fallback: bitcast via alloca
    let alloca = wl_build_alloca(self.builder, i64_ty)
    wl_build_store(self.builder, val, alloca)
    wl_build_load(self.builder, target_ty, alloca)

// ── Async function declaration ────────────────────────────────────

fn Codegen.declare_async_function(self: Codegen, fn_node: i32):
    self.ensure_async_runtime_declared()

    let name_sym = self.pool.get_data0(fn_node)
    let name_str = self.intern.resolve(name_sym)
    if name_sym == 0: return

    let meta = self.pool.find_fn_meta(fn_node)
    if meta < 0: return

    let i32_ty = wl_i32_type(self.context)
    let void_ty = wl_void_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)

    // Resolve return type (default to i32 when no annotation, matching non-async functions)
    let ret_ty = if ret_type_node != 0: self.resolve_type(ret_type_node) else: i32_ty
    self.async_fn_ret_types.insert(name_sym, ret_ty)

    // Resolve param types
    let param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        var p_ty = self.resolve_type(p_type_node)
        if p_ty == 0:
            p_ty = i32_ty
        param_types.push(p_ty)

    // 1. Declare implementation function: name_async(params) -> ret_type
    let impl_fn_type = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count, 0)
    let impl_name = name_str ++ "_async"
    let impl_fn = wl_add_function(self.llmod, impl_name, impl_fn_type)
    self.apply_noalias_param_attrs(impl_fn, param_start, param_count)
    let impl_sym = self.intern.intern(impl_name)
    self.fn_values.insert(impl_sym, impl_fn)
    self.fn_fn_types.insert(impl_sym, impl_fn_type)

    // 2. Create args struct type
    var args_struct_type = wl_struct_type(self.context, vec_data_i64(&param_types), param_count, 0)
    self.async_fn_args_struct_types.insert(name_sym, args_struct_type)

    // 3. Declare fiber trampoline: name_fiber(arg: *void) -> void
    let tramp_params: Vec[i64] = Vec.new()
    tramp_params.push(ptr_ty)
    let tramp_fn_type = wl_function_type(void_ty, vec_data_i64(&tramp_params), 1, 0)
    let tramp_name = name_str ++ "_fiber"
    wl_add_function(self.llmod, tramp_name, tramp_fn_type)

    // 4. Declare the public spawn wrapper: name(params) -> i32 (Task ID)
    let spawn_fn_type = wl_function_type(i32_ty, vec_data_i64(&param_types), param_count, 0)
    let effective_name = self.function_symbol_name(name_sym)
    let spawn_fn = wl_add_function(self.llmod, effective_name, spawn_fn_type)
    self.apply_noalias_param_attrs(spawn_fn, param_start, param_count)
    self.fn_values.insert(name_sym, spawn_fn)
    self.fn_fn_types.insert(name_sym, spawn_fn_type)

// ── Async expressions ─────────────────────────────────────────────

fn Codegen.collect_captures(self: Codegen, node: i32):
    // Walk the AST and collect captured locals into self.async_block_captures.
    if node == 0: return
    let kind = self.pool.kind(node)
    if kind == NK_IDENT:
        let sym = self.pool.get_data0(node)
        if self.local_allocas.get(sym).is_some():
            for ci in 0..self.async_block_captures.len() as i32:
                if self.async_block_captures.get(ci as i64) == sym:
                    return
            self.async_block_captures.push(sym)
        return
    if kind == NK_BINARY:
        self.collect_captures(self.pool.get_data1(node))
        self.collect_captures(self.pool.get_data2(node))
        return
    if kind == NK_UNARY:
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NK_CALL:
        self.collect_captures(self.pool.get_data0(node))
        let args_start = self.pool.get_data1(node)
        let arg_count = self.pool.get_data2(node)
        for ai in 0..arg_count:
            self.collect_captures(self.pool.get_extra(args_start + ai))
        return
    if kind == NK_BLOCK:
        let extra_start = self.pool.get_data0(node)
        let stmt_count = self.pool.get_data1(node)
        for si in 0..stmt_count:
            self.collect_captures(self.pool.get_extra(extra_start + si))
        self.collect_captures(self.pool.get_data2(node))
        return
    if kind == NK_IF_EXPR:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        self.collect_captures(self.pool.get_data2(node))
        return
    if kind == NK_LET_BINDING:
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NK_RETURN:
        self.collect_captures(self.pool.get_data0(node))
        return
    if kind == NK_GROUPED or kind == NK_AWAIT or kind == NK_SPAWN:
        self.collect_captures(self.pool.get_data0(node))
        return
    if kind == NK_FIELD_ACCESS:
        self.collect_captures(self.pool.get_data0(node))
        return
    if kind == NK_CAST:
        self.collect_captures(self.pool.get_data0(node))
        return
    if kind == NK_WHILE:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NK_FOR:
        self.collect_captures(self.pool.get_data1(node))
        self.collect_captures(self.pool.get_data2(node))
        return
    if kind == NK_ASSIGN:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        return
    if kind == NK_TUPLE:
        let extra_start = self.pool.get_data0(node)
        let count = self.pool.get_data1(node)
        for ti in 0..count:
            self.collect_captures(self.pool.get_extra(extra_start + ti))
        return
    if kind == NK_INDEX:
        self.collect_captures(self.pool.get_data0(node))
        self.collect_captures(self.pool.get_data1(node))
        return

fn Codegen.decode_string_escapes(self: Codegen, text: str) -> str:
    var out = ""
    let len = text.len() as i32
    var i = 0
    while i < len:
        let ch = text[i]
        if ch == 92 and i + 1 < len:
            i = i + 1
            let esc = text[i]
            if esc == 120 and i + 2 < len:
                let hi = self.hex_digit_value(text[i + 1])
                let lo = self.hex_digit_value(text[i + 2])
                if hi >= 0 and lo >= 0:
                    out = out ++ str_from_byte(hi * 16 + lo)
                    i = i + 2
                else:
                    out = out ++ text.slice(i as i64, i as i64 + 1)
            else if esc == 110:
                out = out ++ "\n"
            else if esc == 116:
                out = out ++ "\t"
            else if esc == 114:
                out = out ++ "\r"
            else if esc == 48:
                out = out ++ str_from_byte(0)
            else if esc == 92:
                out = out ++ "\\"
            else if esc == 34:
                out = out ++ "\""
            else:
                out = out ++ text.slice(i as i64, i as i64 + 1)
        else:
            out = out ++ text.slice(i as i64, i as i64 + 1)
        i = i + 1
    out

fn Codegen.hex_digit_value(self: Codegen, ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return ch - 48
    if ch >= 97 and ch <= 102:
        return ch - 87
    if ch >= 65 and ch <= 70:
        return ch - 55
    0 - 1

fn Codegen.gen_string_literal_raw(self: Codegen, text: str) -> i64:
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some():
        with_eprintln("warning: [string-lit] str struct type not found")
        return wl_get_undef(wl_i32_type(self.context))
    let str_type = self.struct_llvm_types.get(st_opt.unwrap() as i64)
    let global_str = wl_build_global_string_ptr(self.builder, text)
    let alloca = wl_build_alloca(self.builder, str_type)
    let ptr_gep = wl_build_struct_gep(self.builder, str_type, alloca, 0)
    wl_build_store(self.builder, global_str, ptr_gep)
    let len_gep = wl_build_struct_gep(self.builder, str_type, alloca, 1)
    wl_build_store(self.builder, wl_const_int(wl_i64_type(self.context), text.len(), 1), len_gep)
    wl_build_load(self.builder, str_type, alloca)

fn Codegen.gen_src_intrinsic(self: Codegen, node: i32) -> i64:
    let span_start = self.pool.get_start(node)
    // Compute line and column from byte offset
    var line = 1
    var col = 1
    var i = 0
    while i < span_start and i < self.source_text.len() as i32:
        if self.source_text.byte_at(i as i64) == 10:
            line = line + 1
            col = 1
        else:
            col = col + 1
        i = i + 1
    let loc_str = self.source_file ++ ":" ++ int_to_string(line) ++ ":" ++ int_to_string(col)
    self.gen_string_literal_raw(loc_str)

fn Codegen.gen_embed_file(self: Codegen, node: i32) -> i64:
    let args_start = self.pool.get_data1(node)
    let arg_node = self.pool.get_extra(args_start)
    let path_value = self.try_eval_const_string(arg_node, self.current_decl_source_file, 0)
    if not path_value.ok:
        with_eprintln("error: embed_file() argument must be a compile-time string")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    let base_path = if self.current_decl_source_file.len() > 0 and self.current_decl_source_file != "<unknown>":
        self.current_decl_source_file
    else:
        self.source_file
    let path = self.resolve_embed_file_path(base_path, path_value.text)
    let content = with_fs_read_file(path)
    if content.len() == 0:
        with_eprintln("error: embed_file: could not read '" ++ path ++ "'")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    self.gen_string_literal_raw(content)

fn Codegen.extract_str_ptr(self: Codegen, str_val: i64) -> i64:
    // Extract ptr (field 0) from str struct
    wl_build_extract_value(self.builder, str_val, 0)

fn Codegen.is_str_type(self: Codegen, ty: i64) -> bool:
    if wl_get_type_kind(ty) != wl_struct_type_kind(): return false
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some(): return false
    let str_type = self.struct_llvm_types.get(st_opt.unwrap() as i64)
    ty == str_type

fn Codegen.build_str_value(self: Codegen, ptr: i64, len: i64) -> i64:
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some():
        with_eprintln("warning: [build-str] str struct type not found")
        return wl_get_undef(wl_i32_type(self.context))
    let str_type = self.struct_llvm_types.get(st_opt.unwrap() as i64)
    var result = wl_get_undef(str_type)
    result = wl_build_insert_value(self.builder, result, ptr, 0)
    result = wl_build_insert_value(self.builder, result, len, 1)
    result

fn Codegen.ensure_c_fn(self: Codegen, name: str, ret_ty: i64, param_count: i32) -> i64:
    let existing = wl_get_named_function(self.llmod, name)
    if existing != 0: return existing
    let fn_ty = self.get_runtime_fn_type(name, ret_ty, param_count)
    wl_add_function(self.llmod, name, fn_ty)

fn Codegen.get_runtime_fn_type(self: Codegen, name: str, ret_ty: i64, param_count: i32) -> i64:
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    let str_type = if st_opt.is_some(): self.struct_llvm_types.get(st_opt.unwrap() as i64) else wl_i64_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let params: Vec[i64] = Vec.new()
    if name == "with_str_contains" or
       name == "with_str_starts_with" or
       name == "with_str_ends_with" or
       name == "with_str_index_of" or
       name == "with_str_trim" or
       name == "with_str_to_upper" or
       name == "with_str_to_lower" or
       name == "with_str_replace":
        for i in 0..param_count:
            params.push(str_type)
    else if name == "with_str_byte_at":
        params.push(str_type)
        params.push(i64_ty)
    else if name == "with_str_repeat":
        params.push(str_type)
        params.push(i64_ty)
    else:
        for i in 0..param_count:
            params.push(i64_ty)
    wl_function_type(ret_ty, vec_data_i64(&params), param_count, 0)

// ── VecIter.next() codegen intrinsic ──────────────────────────────
// VecIter[T] = { data_ptr: i64, len: i64, idx: i64 }
// next() returns Option[T]: checks idx < len, loads T from data_ptr, increments idx.

fn Codegen.ensure_vec_runtime_fn(self: Codegen, name: str, ret_ty: i64, param_count: i32) -> i64:
    let existing = wl_get_named_function(self.llmod, name)
    if existing != 0: return existing
    let fn_ty = self.get_vec_fn_type(name, ret_ty, param_count)
    wl_add_function(self.llmod, name, fn_ty)

fn Codegen.get_vec_fn_type(self: Codegen, name: str, ret_ty: i64, param_count: i32) -> i64:
    let ptr_ty = wl_ptr_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let params: Vec[i64] = Vec.new()
    // First param is always ptr (to Vec struct)
    params.push(ptr_ty)
    var i = 1
    while i < param_count:
        if i == 1 and name == "with_vec_push":
            params.push(ptr_ty)
        else:
            params.push(i64_ty)
        i = i + 1
    wl_function_type(ret_ty, vec_data_i64(&params), param_count, 0)

// ── HashMap method dispatch ───────────────────────────────────────

fn Codegen.ensure_hm_fn(self: Codegen, name: str, ret_ty: i64) -> i64:
    let existing = wl_get_named_function(self.llmod, name)
    if existing != 0: return existing
    let ptr_ty = wl_ptr_type(self.context)
    let params: Vec[i64] = Vec.new()
    params.push(ptr_ty)
    let fn_ty = wl_function_type(ret_ty, vec_data_i64(&params), 1, 0)
    wl_add_function(self.llmod, name, fn_ty)

fn Codegen.make_ptr_vec(self: Codegen) -> Vec[i64]:
    let v: Vec[i64] = Vec.new()
    v.push(wl_ptr_type(self.context))
    v

// ── derive(Clone) generation ──────────────────────────────────────

fn Codegen.generate_clone_derives(self: Codegen):
    let clone_sym = self.intern.intern("Clone")
    for di in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(di)
        if self.pool.kind(decl) != NK_TYPE_DECL:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind != TDK_STRUCT:
            continue
        let meta = self.pool.find_type_meta(decl)
        if meta < 0:
            continue
        let d_start = self.pool.type_meta_derive_start(meta)
        let d_count = self.pool.type_meta_derive_count(meta)
        var has_clone = 0
        for ci in 0..d_count:
            if self.pool.get_extra(d_start + ci) == clone_sym:
                has_clone = 1
        if has_clone == 0:
            continue
        let name_sym = self.pool.get_data0(decl)
        let name_str = self.intern.resolve(name_sym)
        // Only generate if not already declared
        let clone_name = name_str ++ ".clone"
        let clone_fn_sym = self.intern.intern(clone_name)
        if self.fn_values.get(clone_fn_sym).is_some():
            continue
        // Get struct LLVM type
        let st_idx_opt = self.struct_type_map.get(name_sym)
        if not st_idx_opt.is_some():
            continue
        let st_idx = st_idx_opt.unwrap()
        let st_type = self.struct_llvm_types.get(st_idx as i64)
        // Create fn: clone(self: *Type) -> Type { return load(self) }
        let params: Vec[i64] = Vec.new()
        params.push(wl_ptr_type(self.context))
        let fn_type = wl_function_type(st_type, vec_data_i64(&params), 1, 0)
        let function = wl_add_function(self.llmod, clone_name, fn_type)
        wl_set_linkage(function, wl_internal_linkage())
        let entry = wl_append_bb(self.context, function, "entry")
        wl_position_at_end(self.builder, entry)
        let self_ptr = wl_get_param(function, 0)
        let loaded = wl_build_load(self.builder, st_type, self_ptr)
        wl_build_ret(self.builder, loaded)
        self.fn_values.insert(clone_fn_sym, function)
        self.fn_fn_types.insert(clone_fn_sym, fn_type)
        self.record_ref_param(clone_fn_sym, 0, 1)

// ── transmute intrinsic ───────────────────────────────────────────

fn Codegen.gen_transmute(self: Codegen, node: i32, body: MirBody, args_id: i32) -> i64:
    // transmute[T](value) — reinterpret bits as type T
    let callee_node = self.pool.get_data0(node)
    let callee_kind = self.pool.kind(callee_node)
    if callee_kind != NK_TYPE_GENERIC and callee_kind != NK_INDEX:
        return wl_get_undef(wl_i32_type(self.context))
    let tp_node = if callee_kind == NK_TYPE_GENERIC:
        let tp_start = self.pool.get_data1(callee_node)
        let tp_count = self.pool.get_data2(callee_node)
        if tp_count == 0:
            return wl_get_undef(wl_i32_type(self.context))
        self.pool.get_extra(tp_start)
    else:
        self.pool.get_data1(callee_node)
    let target_ty = self.resolve_type(tp_node)
    if target_ty == 0:
        return wl_get_undef(wl_i32_type(self.context))
    // Evaluate the argument
    let mir_start = body.call_arg_starts.get(args_id as i64)
    let mir_count = body.call_arg_counts.get(args_id as i64)
    if mir_count == 0:
        return wl_get_undef(target_ty)
    let arg_op = body.call_arg_operands.get(mir_start as i64)
    let arg_val = self.mir_eval_operand(body, arg_op, 0)
    // Use alloca + store + load to reinterpret the bits
    let src_alloca = self.create_entry_alloca(wl_type_of(arg_val))
    wl_build_store(self.builder, arg_val, src_alloca)
    wl_build_load(self.builder, target_ty, src_alloca)

// ── sizeof/alignof intrinsics ─────────────────────────────────────

fn Codegen.gen_sizeof_alignof(self: Codegen, name: str, node: i32) -> i64:
    let callee_node = self.pool.get_data0(node)
    let callee_kind = self.pool.kind(callee_node)
    if callee_kind != NK_TYPE_GENERIC and callee_kind != NK_INDEX:
        return wl_const_int(wl_i64_type(self.context), 0, 0)
    let tp_node = if callee_kind == NK_TYPE_GENERIC:
        let tp_start = self.pool.get_data1(callee_node)
        let tp_count = self.pool.get_data2(callee_node)
        if tp_count == 0:
            return wl_const_int(wl_i64_type(self.context), 0, 0)
        self.pool.get_extra(tp_start)
    else:
        self.pool.get_data1(callee_node)
    let type_val = self.resolve_type(tp_node)
    if type_val == 0:
        return wl_const_int(wl_i64_type(self.context), 0, 0)
    let dl = wl_get_module_data_layout(self.llmod)
    if name == "sizeof" or name == "size_of":
        return wl_const_int(wl_i64_type(self.context), wl_abi_size_of(dl, type_val), 0)
    wl_const_int(wl_i64_type(self.context), wl_abi_align_of(dl, type_val) as i64, 0)

// ── nameof/type_name intrinsic ─────────────────────────────────────

fn Codegen.gen_nameof(self: Codegen, node: i32) -> i64:
    let callee_node = self.pool.get_data0(node)
    let callee_kind = self.pool.kind(callee_node)
    if callee_kind != NK_TYPE_GENERIC and callee_kind != NK_INDEX:
        return self.gen_string_literal_raw("")
    let tp_node = if callee_kind == NK_TYPE_GENERIC:
        let tp_start = self.pool.get_data1(callee_node)
        let tp_count = self.pool.get_data2(callee_node)
        if tp_count == 0:
            return self.gen_string_literal_raw("")
        self.pool.get_extra(tp_start)
    else:
        self.pool.get_data1(callee_node)
    // Get the type name from the AST node
    var type_name = ""
    if self.pool.kind(tp_node) == NK_IDENT or self.pool.kind(tp_node) == NK_TYPE_NAMED:
        type_name = self.intern.resolve(self.pool.get_data0(tp_node))
    else:
        type_name = "unknown"
    self.gen_string_literal_raw(type_name)

// ── Option method dispatch ────────────────────────────────────────
