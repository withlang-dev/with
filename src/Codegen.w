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
use Resolve

extern fn exit(code: i32) -> void
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_parse_float(s: str) -> f64
extern fn with_eprint(s: str) -> void
extern fn with_getenv_str(name: str) -> str
extern fn with_str_hash(s: str) -> i64
extern fn with_str_clone(s: str) -> str
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
extern fn wl_init_native_asm_parser() -> i32
extern fn wl_init_target_machine(m: i64, level: i32) -> i64
extern fn wl_dispose_target_machine(tm: i64) -> void

// Types
extern fn wl_i1_type(c: i64) -> i64
extern fn wl_i8_type(c: i64) -> i64
extern fn wl_i16_type(c: i64) -> i64
extern fn wl_i32_type(c: i64) -> i64
extern fn wl_i64_type(c: i64) -> i64
extern fn wl_i128_type(c: i64) -> i64
extern fn wl_int_type_n(c: i64, bits: i32) -> i64
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
extern fn wl_const_int_words(ty: i64, lo: i64, hi: i64, word_count: i32) -> i64
extern fn wl_const_real(ty: i64, val: f64) -> i64
extern fn wl_const_null(ty: i64) -> i64
extern fn wl_get_undef(ty: i64) -> i64
extern fn wl_const_string(ctx: i64, s: str, dont_null: i32) -> i64
extern fn wl_const_struct(ctx: i64, vals_ptr: i64, count: i32, packed: i32) -> i64
extern fn wl_const_named_struct(ty: i64, vals_ptr: i64, count: i32) -> i64
extern fn wl_const_array(elem_ty: i64, vals_ptr: i64, count: i32) -> i64
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
extern fn wl_add_param_byval_attr(ctx: i64, f: i64, param_idx: i32, ty: i64) -> void
extern fn wl_add_sret_attr(ctx: i64, f: i64, param_idx: i32, ty: i64) -> void

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
extern fn wl_set_tail_call(call_inst: i64) -> void
extern fn wl_set_musttail_call(call_inst: i64) -> void

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

// Atomic operations
enum AtomicRmwOp: i32:
    XCHG = 0
    ADD = 1
    SUB = 2
    AND = 3
    OR = 4
    XOR = 5
    MIN = 6
    MAX = 7
    UMIN = 8
    UMAX = 9

enum AtomicOrdering: i32:
    RELAXED = 0
    ACQUIRE = 1
    RELEASE = 2
    ACQ_REL = 3
    SEQ_CST = 4

extern fn wl_build_atomic_load(b: i64, ty: i64, ptr: i64, order: i32) -> i64
extern fn wl_build_atomic_store(b: i64, val: i64, ptr: i64, order: i32) -> void
extern fn wl_build_atomic_rmw(b: i64, rmw_op: i32, ptr: i64, val: i64, order: i32) -> i64
extern fn wl_build_cmpxchg(b: i64, ptr: i64, expected: i64, desired: i64, success_order: i32, failure_order: i32, is_weak: i32) -> i64
extern fn wl_extract_value(b: i64, agg: i64, index: i32) -> i64
extern fn wl_build_fence(b: i64, order: i32) -> void

// Inline assembly
extern fn wl_get_inline_asm(fn_ty: i64, asm_str: str, constraints: str, has_side_effects: i32, is_align_stack: i32) -> i64

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
extern fn with_write(s: str) -> void

// ── Codegen state ─────────────────────────────────────────────────

type Codegen {
    // LLVM handles
    context: i64,
    llmod: i64,
    builder: i64,
    target_machine: i64,

    // AST access
    pool: AstPool,
    intern: InternPool,
    sema: Sema,
    sema_symbol_texts: Vec[str],

    // Current function state
    current_ret_type: i64,
    mir_emit_mutual_tail_call: i32,
    // Async trampolines: fn_sym → LLVM trampoline function value
    async_trampolines: HashMap[i32, i64],
    current_function: i64,
    current_function_name_sym: i32,
    current_method_owner_sym: i32,

    // Pre-interned symbols for O(1) dispatch (avoid string comparisons)
    sym_vec: i32,
    sym_option: i32,
    sym_result: i32,
    sym_hashmap: i32,
    sym_hashset: i32,
    sym_box: i32,
    sym_context_error: i32,
    sym_Self: i32,
    sym_self: i32,
    sym_unit: i32,
    sym_bool: i32,
    sym_usize: i32,
    sym_isize: i32,
    sym_void: i32,
    sym_never: i32,
    sym_str: i32,
    sym_sizeof: i32,
    sym_size_of: i32,
    sym_alignof: i32,
    sym_align_of: i32,
    sym_chan: i32,
    sym_todo: i32,
    sym_unreachable: i32,
    sym_src: i32,
    sym_transmute: i32,
    sym_nameof: i32,
    sym_type_name: i32,
    sym_embed_file: i32,
    sym_channel: i32,
    sym_send: i32,
    sym_recv: i32,
    sym_close: i32,
    sym_from_int: i32,
    sym_ptr: i32,
    sym_len: i32,
    sym_cap: i32,
    sym_elem_size: i32,
    sym_new: i32,

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
    // C ABI: fns with large struct params/returns transformed for C ABI.
    // Maps fn sym → 1 if the fn has an sret return (first param is hidden sret ptr).
    extern_fn_has_sret: HashMap[i32, i32],
    // Maps fn sym → bitmask of param indices that are byval (after sret shift).
    extern_fn_byval_params: HashMap[i32, i64],
    // Maps fn sym → original struct types for byval params (parallel arrays).
    extern_fn_byval_types: HashMap[i32, Vec[i64]],
    // Maps fn sym → original return struct type (for sret).
    extern_fn_sret_type: HashMap[i32, i64],

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

    // Bitpacked struct tracking: which struct indices are bitpacked,
    // and per-field bit offsets/widths for shift/mask codegen
    bitpacked_structs: HashMap[i32, i32],  // struct_idx → bp_info_start (index into bitpacked_field_* Vecs)
    bitpacked_total_bits: HashMap[i32, i32],  // struct_idx → total_bits
    bitpacked_backing_types: HashMap[i32, i64],  // struct_idx → LLVM iN type (64-bit pointer)
    bitpacked_by_llvm_type: HashMap[i64, i32],  // LLVM iN type → struct_idx (reverse lookup)
    bitpacked_field_bit_offsets: Vec[i32],  // indexed by bp_info_start + field_idx
    bitpacked_field_bit_widths: Vec[i32],   // indexed by bp_info_start + field_idx
    // Per-place bitpacked projection: when a place resolves to a bitpacked field,
    // stores (bit_offset << 16 | bit_width) keyed by place_id.
    // mir_eval_operand checks this after loading to apply shift+mask extraction.
    bitpacked_place_proj: HashMap[i32, i32],

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
    mono_struct_tp_flat_sema_types: Vec[i32],

    // Monomorphization cache: mangled_hash → value/type
    mono_values: HashMap[i64, i64],
    mono_types: HashMap[i64, i64],

    // Type aliases: sym → LLVM type
    type_aliases: HashMap[i32, i64],

    // Module constants: sym → LLVM global
    module_constants: HashMap[i32, i64],
    // Module constants that require runtime reconstruction before user main.
    module_runtime_init_syms: Vec[i32],
    module_runtime_init_nodes: Vec[i32],
    module_runtime_init_type_ids: Vec[i32],
    module_runtime_init_globals: Vec[i64],
    module_runtime_init_fns: Vec[i64],
    module_runtime_init_types: Vec[i64],
    // Constant integer values: parallel arrays for sym → i64 value lookup
    const_int_syms: Vec[i32],
    const_int_vals: Vec[i64],
    decl_source_paths: Vec[str],
    current_decl_source_file: str,
    module_object_mode: i32,

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

    // Option type cache: sema_tid/payload_ty → LLVM type
    option_cache_map: HashMap[i64, i64],

    // Result type cache: "sema_tid" or "ok_ty:err_ty" → LLVM type
    result_cache_map: HashMap[str, i64],

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
    async_task_result_types: HashMap[i32, i64],
    last_async_spawn_ret_ty: i64,
    async_fn_args_struct_types: HashMap[i32, i64],
    task_locals: HashMap[i32, i32],
    uses_async: bool,
    async_block_counter: i32,
    async_block_captures: Vec[i32],
    async_block_rbuf: i64,

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
    // Vec type cache
    vec_cache_map: HashMap[i64, i64],
    vec_is_vec: HashMap[i64, i32],
    // HashMap type cache
    hm_cache_map: HashMap[i64, i64],
    hm_is_hm: HashMap[i64, i32],

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

type DynArgInfo {
    type_sym: i32,
    use_ptr: i32,
}

type LoopState {
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
    cg.capture_sema_symbol_texts()
    // Pre-intern dispatch symbols for O(1) comparisons
    cg.sym_vec = cg.intern.intern("Vec")
    cg.sym_option = cg.intern.intern("Option")
    cg.sym_result = cg.intern.intern("Result")
    cg.sym_hashmap = cg.intern.intern("HashMap")
    cg.sym_hashset = cg.intern.intern("HashSet")
    cg.sym_box = cg.intern.intern("Box")
    cg.sym_context_error = cg.intern.intern("ContextError")
    cg.sym_Self = cg.intern.intern("Self")
    cg.sym_self = cg.intern.intern("self")
    cg.sym_unit = cg.intern.intern("Unit")
    cg.sym_bool = cg.intern.intern("bool")
    cg.sym_usize = cg.intern.intern("usize")
    cg.sym_isize = cg.intern.intern("isize")
    cg.sym_void = cg.intern.intern("void")
    cg.sym_never = cg.intern.intern("Never")
    cg.sym_str = cg.intern.intern("str")
    cg.sym_sizeof = cg.intern.intern("sizeof")
    cg.sym_size_of = cg.intern.intern("size_of")
    cg.sym_alignof = cg.intern.intern("alignof")
    cg.sym_align_of = cg.intern.intern("align_of")
    cg.sym_chan = cg.intern.intern("chan")
    cg.sym_todo = cg.intern.intern("todo")
    cg.sym_unreachable = cg.intern.intern("unreachable")
    cg.sym_src = cg.intern.intern("src")
    cg.sym_transmute = cg.intern.intern("transmute")
    cg.sym_nameof = cg.intern.intern("nameof")
    cg.sym_type_name = cg.intern.intern("type_name")
    cg.sym_embed_file = cg.intern.intern("embed_file")
    cg.sym_channel = cg.intern.intern("Channel")
    cg.sym_send = cg.intern.intern("send")
    cg.sym_recv = cg.intern.intern("recv")
    cg.sym_close = cg.intern.intern("close")
    cg.sym_from_int = cg.intern.intern("from_int")
    cg.sym_ptr = cg.intern.intern("ptr")
    cg.sym_len = cg.intern.intern("len")
    cg.sym_cap = cg.intern.intern("cap")
    cg.sym_elem_size = cg.intern.intern("elem_size")
    cg.sym_new = cg.intern.intern("new")
    cg

fn Codegen.init_with_opt(module_name: str, opt_level: i32) -> Codegen:
    wl_init_native_target()
    wl_init_native_asm_printer()
    wl_init_native_asm_parser()
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
        sema_symbol_texts: Vec.new(),
        current_ret_type: 0,
        mir_emit_mutual_tail_call: 0,
        async_trampolines: HashMap.new(),
        current_function: 0,
        current_function_name_sym: 0,
        current_method_owner_sym: 0,
        sym_vec: 0, sym_option: 0, sym_result: 0, sym_hashmap: 0,
        sym_hashset: 0, sym_box: 0, sym_context_error: 0,
        sym_Self: 0, sym_self: 0, sym_unit: 0,
        sym_bool: 0, sym_usize: 0, sym_isize: 0, sym_void: 0,
        sym_never: 0, sym_str: 0,
        sym_sizeof: 0, sym_size_of: 0, sym_alignof: 0, sym_align_of: 0, sym_chan: 0,
        sym_todo: 0, sym_unreachable: 0, sym_src: 0, sym_transmute: 0,
        sym_nameof: 0, sym_type_name: 0, sym_embed_file: 0,
        sym_channel: 0, sym_send: 0, sym_recv: 0, sym_close: 0,
        sym_from_int: 0,
        sym_ptr: 0, sym_len: 0, sym_cap: 0, sym_elem_size: 0,
        sym_new: 0,
        local_allocas: HashMap.new(),
        local_types: HashMap.new(),
        local_muts: HashMap.new(),
        local_fn_sigs: HashMap.new(),
        local_pointee_structs: HashMap.new(),
        local_sema_types: HashMap.new(),
        fn_values: HashMap.new(),
        fn_fn_types: HashMap.new(),
        extern_fn_has_sret: HashMap.new(),
        extern_fn_byval_params: HashMap.new(),
        extern_fn_byval_types: HashMap.new(),
        extern_fn_sret_type: HashMap.new(),
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
        bitpacked_structs: HashMap.new(),
        bitpacked_total_bits: HashMap.new(),
        bitpacked_backing_types: HashMap.new(),
        bitpacked_by_llvm_type: HashMap.new(),
        bitpacked_field_bit_offsets: Vec.new(),
        bitpacked_field_bit_widths: Vec.new(),
        bitpacked_place_proj: HashMap.new(),
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
        mono_struct_tp_flat_sema_types: Vec.new(),
        mono_values: HashMap.new(),
        mono_types: HashMap.new(),
        type_aliases: HashMap.new(),
        module_constants: HashMap.new(),
        module_runtime_init_syms: Vec.new(),
        module_runtime_init_nodes: Vec.new(),
        module_runtime_init_type_ids: Vec.new(),
        module_runtime_init_globals: Vec.new(),
        module_runtime_init_fns: Vec.new(),
        module_runtime_init_types: Vec.new(),
        const_int_syms: Vec.new(),
        const_int_vals: Vec.new(),
        decl_source_paths: Vec.new(),
        current_decl_source_file: "<unknown>",
        module_object_mode: 0,
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
        result_cache_map: HashMap.new(),
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
        async_task_result_types: HashMap.new(),
        last_async_spawn_ret_ty: 0,
        async_fn_args_struct_types: HashMap.new(),
        task_locals: HashMap.new(),
        uses_async: false,
        async_block_counter: 0,
        async_block_captures: Vec.new(),
        async_block_rbuf: 0,
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
        vec_is_vec: HashMap.new(),
        hm_cache_map: HashMap.new(),
        hm_is_hm: HashMap.new(),
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
    let dump_pre = with_getenv_str("WITH_DUMP_LLIR_PRE")
    if dump_pre.len() > 0:
        with_eprint("===== PRE-OPTIMIZE LLVM IR =====\n")
        wl_print_ir(self.llmod)
        with_eprint("===== END PRE-OPTIMIZE LLVM IR =====\n")
    wl_optimize(self.llmod, self.target_machine, level)
    let dump_post = with_getenv_str("WITH_DUMP_LLIR_POST")
    if dump_post.len() > 0:
        with_eprint("===== POST-OPTIMIZE LLVM IR =====\n")
        wl_print_ir(self.llmod)
        with_eprint("===== END POST-OPTIMIZE LLVM IR =====\n")

fn Codegen.emit_object_file(self: Codegen, path: str) -> i32:
    wl_emit_object(self.target_machine, self.llmod, path)

fn Codegen.print_ir(self: Codegen):
    wl_print_ir(self.llmod)

fn Codegen.verify(self: Codegen) -> i32:
    wl_verify_module(self.llmod)

// ── Type fallback helper ─────────────────────────────────────────

// Returns i32 type as a fallback when type resolution fails.
// Sets had_error so the compilation is marked as failed.
fn Codegen.type_fallback(self: Codegen) -> i64:
    self.had_error = 1
    wl_i32_type(self.context)

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
        // TypeKind.TY_BOOL
        return wl_di_create_basic_type(self.di_builder, "bool", 8, wl_dwarf_ate_boolean())
    if kind == 1:
        // TypeKind.TY_INT: d0 = width, d1 = signed, d2 = ptr_width flag
        let width = self.sema.get_type_d0(sema_tid)
        let is_signed = self.sema.get_type_d1(sema_tid)
        let is_ptr_width = self.sema.get_type_d2(sema_tid)
        if is_ptr_width != 0:
            let name = if is_signed == 1: "isize" else: "usize"
            let encoding = if is_signed == 1: wl_dwarf_ate_signed() else: wl_dwarf_ate_unsigned()
            return wl_di_create_basic_type(self.di_builder, name, width as i64, encoding)
        if is_signed == 1:
            return wl_di_create_basic_type(self.di_builder, f"i{width}", width as i64, wl_dwarf_ate_signed())
        else:
            return wl_di_create_basic_type(self.di_builder, f"u{width}", width as i64, wl_dwarf_ate_unsigned())
    if kind == 2:
        // TypeKind.TY_FLOAT: d0 = width
        let width = self.sema.get_type_d0(sema_tid)
        return wl_di_create_basic_type(self.di_builder, f"f{width}", width as i64, wl_dwarf_ate_float())
    if kind == 5:
        // TypeKind.TY_STR
        return wl_di_create_unspecified_type(self.di_builder, "str")
    if kind == 4:
        // TypeKind.TY_VOID
        return wl_di_create_unspecified_type(self.di_builder, "void")
    if kind == 13 or kind == 14:
        // TypeKind.TY_PTR / TypeKind.TY_REF: d0 = pointee tid
        let pointee_tid = self.sema.get_type_d0(sema_tid)
        let pointee_di = self.debug_get_di_type(pointee_tid)
        return wl_di_create_pointer_type(self.di_builder, pointee_di, 64)
    if kind == 6 or kind == 7:
        // TypeKind.TY_STRUCT / TypeKind.TY_ENUM: d0 = name sym
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
        with_eprint("error: invalid MIR input for LLVM backend: " ++ mir_err)
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
    if tk == NodeKind.NK_TYPE_TRAIT_OBJ:
        return self.pool.get_data0(type_node)
    if tk == NodeKind.NK_TYPE_REF or tk == NodeKind.NK_TYPE_PTR:
        return self.dyn_trait_from_type_node(self.pool.get_data0(type_node))
    if tk == NodeKind.NK_TYPE_GENERIC:
        let name_sym = self.pool.get_data0(type_node)
        let g_extra = self.pool.get_data1(type_node)
        let g_count = self.pool.get_data2(type_node)
        if name_sym == self.sym_box and g_count == 1:
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

    if (vk == wl_float_type_kind() or vk == wl_double_type_kind()) and (tk == wl_float_type_kind() or tk == wl_double_type_kind()):
        return wl_build_fp_cast(self.builder, val, target_ty)

    // c_import return coercion: pointer → str (null-safe)
    if vk == wl_pointer_type_kind() and self.is_str_type(target_ty):
        return self.coerce_ptr_to_str(val)

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
    let thunk_name = f"__fn_thunk_{thunk_id}"
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
    var msg = f"[type-layout] owner={owner_name} field={field_index} name={self.intern.resolve(field_name)} type_node={type_node} node_kind={node_kind}"
    if type_node != 0:
        let start = self.pool.get_start(type_node)
        let end = self.pool.get_end(type_node)
        msg = msg ++ f" span={start}..{end}"
        if node_kind == NodeKind.NK_TYPE_NAMED or node_kind == NodeKind.NK_TYPE_GENERIC:
            let type_name_sym = self.pool.get_data0(type_node)
            msg = msg ++ f" type_name={self.intern.resolve(type_name_sym)}"
        if node_kind == NodeKind.NK_TYPE_GENERIC:
            msg = msg ++ f" arg_count={self.pool.get_data2(type_node)}"
    msg = msg ++ f" resolved={self.llvm_type_mangle(resolved_ty)}"
    if resolved_ty != 0:
        msg = msg ++ f" llvm_kind={wl_get_type_kind(resolved_ty)} size={wl_size_of(resolved_ty)}"
        let struct_name = wl_get_struct_name(resolved_ty)
        if struct_name.len() > 0:
            msg = msg ++ f" llvm_name={struct_name}"
    with_eprint(msg)

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
    var labels: Vec[i32] = self.loop_labels
    with_codegen_loop_set_break(idx, break_bb)
    with_codegen_loop_set_continue(idx, continue_bb)
    with_codegen_loop_set_result(idx, result_alloca)
    labels.push(label_sym)
    self.loop_labels = labels
    self.loop_depth = idx + 1

fn Codegen.pop_loop_context(self: Codegen):
    var labels: Vec[i32] = self.loop_labels
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
    msg = msg ++ f" arg={arg_index}"
    var line = 0 - 1
    if arg_node != 0:
        line = self.span_to_line(arg_node)
    else if call_node != 0:
        line = self.span_to_line(call_node)
    if line >= 0:
        msg = msg ++ f" line={line}"
    var actual_ty: i64 = 0
    if actual_val != 0:
        actual_ty = wl_type_of(actual_val)
    msg = msg ++ f" actual={self.llvm_type_mangle(actual_ty)}"
    msg = msg ++ f" expected={self.llvm_type_mangle(expected_ty)}"
    if arg_node != 0:
        msg = msg ++ f" node_kind={self.pool.kind(arg_node)}"
        let arg_text = self.ident_text_from_node(arg_node)
        if arg_text.len() > 0:
            msg = msg ++ f" arg_text={arg_text}"
    with_eprint(msg)

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

    // Auto-coerce numeric to str (for f-string interpolation)
    let str_ty = self.resolve_named_type(self.intern.intern("str"))
    if expected_ty == str_ty and out != 0:
        let coerced_str = self.coerce_val_to_str(out, str_ty)
        if wl_type_of(coerced_str) == str_ty:
            return coerced_str

    self.had_error = 1
    with_eprint("error: " ++ context)
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
        msg = msg ++ f" sym={sym}"
        if sym_text.len() > 0:
            msg = msg ++ f" name={sym_text}"
        msg = msg ++ f" ty={self.llvm_type_mangle(ty)}"
        with_eprint(msg)

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
    if arg_node != 0 and self.pool.kind(arg_node) == NodeKind.NK_IDENT:
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

    if arg_node != 0 and self.pool.kind(arg_node) == NodeKind.NK_UNARY:
        let uop = self.pool.get_data0(arg_node)
        if uop == UnaryOp.UOP_REF or uop == UnaryOp.UOP_MUT_REF:
            let inner = self.pool.get_data1(arg_node)
            if self.pool.kind(inner) == NodeKind.NK_IDENT:
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

    if arg_node != 0 and self.pool.kind(arg_node) == NodeKind.NK_IDENT:
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
        if dk == NodeKind.NK_TYPE_REF or dk == NodeKind.NK_TYPE_PTR:
            let pointee = self.pool.get_data0(declared_type_node)
            if self.pool.kind(pointee) == NodeKind.NK_TYPE_NAMED:
                let sym = self.pool.get_data0(pointee)
                if sym == self.sym_Self and self.current_method_owner_sym != 0:
                    return self.current_method_owner_sym
                if self.struct_type_map.get(sym).is_some():
                    return sym

    if value_node != 0 and self.pool.kind(value_node) == NodeKind.NK_UNARY:
        let uop = self.pool.get_data0(value_node)
        if uop == UnaryOp.UOP_REF or uop == UnaryOp.UOP_MUT_REF:
            let inner = self.pool.get_data1(value_node)
            if self.pool.kind(inner) == NodeKind.NK_IDENT:
                let base_sym = self.pool.get_data0(inner)
                let ps = self.lookup_local_pointee_struct(base_sym)
                if ps != 0:
                    return ps
                let base_ty = self.lookup_local_type(base_sym)
                if base_ty != 0:
                    let st_sym = self.find_struct_type_by_llvm(base_ty)
                    if st_sym != 0:
                        return st_sym

    if value_node != 0 and self.pool.kind(value_node) == NodeKind.NK_IDENT:
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
    if vk == NodeKind.NK_STRUCT_LIT:
        let lit_sym = self.pool.get_data0(value_node)
        if lit_sym != 0:
            return lit_sym
    if vk == NodeKind.NK_IDENT:
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
    if vk == NodeKind.NK_UNARY:
        let uop = self.pool.get_data0(value_node)
        if uop == UnaryOp.UOP_REF or uop == UnaryOp.UOP_MUT_REF:
            let inner = self.pool.get_data1(value_node)
            if self.pool.kind(inner) == NodeKind.NK_IDENT:
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
    if ok == OperandKind.OK_CONSTANT and od >= 0 and od < body.const_kinds.len() as i32:
        if body.const_kinds.get(od as i64) == ConstKind.CK_FN:
            return out ++ self.function_symbol_name(body.const_d0.get(od as i64))
    if (ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE) and od >= 0 and od < body.place_locals.len() as i32:
        return out ++ f"place_{body.place_locals.get(od as i64)}"
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

fn Codegen.is_union_struct_index(self: Codegen, struct_idx: i32) -> bool:
    if struct_idx < 0 or struct_idx >= self.struct_index_syms.len() as i32:
        return false
    let name_sym = self.struct_index_syms.get(struct_idx as i64)
    if name_sym == 0:
        return false
    self.sema.type_layout_struct_sub_kind(name_sym) == TypeDeclKind.Union

fn Codegen.is_union_struct_type(self: Codegen, llvm_ty: i64) -> bool:
    self.is_union_struct_index(self.find_struct_index_by_type(llvm_ty))

fn Codegen.struct_source_field_type(self: Codegen, struct_idx: i32, source_fi: i32) -> i64:
    if struct_idx < 0 or struct_idx >= self.struct_field_counts.len() as i32:
        return 0
    let f_count = self.struct_field_counts.get(struct_idx as i64)
    if source_fi < 0 or source_fi >= f_count:
        return 0
    let f_start = self.struct_field_starts.get(struct_idx as i64)
    self.struct_field_types.get((f_start + source_fi) as i64)

fn Codegen.is_bitpacked_struct(self: Codegen, llvm_ty: i64) -> bool:
    self.bitpacked_by_llvm_type.contains(llvm_ty)

fn Codegen.find_bitpacked_index_by_type(self: Codegen, llvm_ty: i64) -> i32:
    let opt = self.bitpacked_by_llvm_type.get(llvm_ty)
    if opt.is_some(): return opt.unwrap() as i32
    -1

fn Codegen.get_bitpacked_field_info(self: Codegen, llvm_ty: i64, field_idx: i32) -> i32:
    // Returns bit_offset * 65536 + bit_width, or -1 if not bitpacked
    let struct_idx = self.find_bitpacked_index_by_type(llvm_ty)
    if struct_idx < 0: return -1
    let bp_start_opt = self.bitpacked_structs.get(struct_idx)
    if not bp_start_opt.is_some(): return -1
    let bp_base = bp_start_opt.unwrap() as i32
    let f_count = self.struct_field_counts.get(struct_idx as i64)
    if field_idx < 0 or field_idx >= f_count: return -1
    let bit_offset = self.bitpacked_field_bit_offsets.get((bp_base + field_idx) as i64)
    let bit_width = self.bitpacked_field_bit_widths.get((bp_base + field_idx) as i64)
    bit_offset * 65536 + bit_width

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
    if self.is_union_struct_index(struct_idx):
        return 0
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
    if kind == wl_array_type_kind():
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
    if op == BinaryOp.OP_EQ:
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

fn Codegen.compare_value_eq(self: Codegen, lhs: i64, rhs: i64, val_ty: i64, op: i32) -> i64:
    let kind = wl_get_type_kind(val_ty)
    if self.is_str_type(val_ty):
        return self.compare_str_eq(lhs, rhs, op)
    if kind == wl_struct_type_kind() or kind == wl_array_type_kind():
        return self.compare_aggregate_eq(lhs, rhs, op)
    if kind == wl_float_type_kind() or kind == wl_double_type_kind():
        if op == BinaryOp.OP_EQ:
            return wl_build_fcmp(self.builder, wl_real_oeq(), lhs, rhs)
        return wl_build_fcmp(self.builder, wl_real_one(), lhs, rhs)
    if op == BinaryOp.OP_EQ:
        return wl_build_icmp(self.builder, wl_int_eq(), lhs, rhs)
    wl_build_icmp(self.builder, wl_int_ne(), lhs, rhs)

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
        if op == BinaryOp.OP_EQ:
            return wl_const_int(i1_ty, 1, 0)
        return wl_const_int(i1_ty, 0, 0)

    // Field-wise comparison for structs to avoid padding byte mismatches.
    let ty_kind = wl_get_type_kind(lhs_ty)
    if ty_kind == wl_struct_type_kind():
        let field_count = wl_count_struct_elem_types(lhs_ty)
        if field_count == 0:
            if op == BinaryOp.OP_EQ:
                return wl_const_int(i1_ty, 1, 0)
            return wl_const_int(i1_ty, 0, 0)
        var result = wl_const_int(i1_ty, 1, 0)
        var fi = 0
        while fi < field_count:
            let lf = wl_build_extract_value(self.builder, lhs, fi)
            let rf = wl_build_extract_value(self.builder, rhs, fi)
            let field_ty = wl_struct_get_type_at(lhs_ty, fi)
            let field_eq = self.compare_value_eq(lf, rf, field_ty, BinaryOp.OP_EQ)
            result = wl_build_and(self.builder, result, field_eq)
            fi = fi + 1
        if op == BinaryOp.OP_EQ:
            return result
        return wl_build_not(self.builder, result)

    if ty_kind == wl_array_type_kind():
        let elem_count = wl_get_array_length(lhs_ty) as i32
        if elem_count == 0:
            if op == BinaryOp.OP_EQ:
                return wl_const_int(i1_ty, 1, 0)
            return wl_const_int(i1_ty, 0, 0)
        let elem_ty = wl_get_element_type(lhs_ty)
        var result = wl_const_int(i1_ty, 1, 0)
        var ai = 0
        while ai < elem_count:
            let lf = wl_build_extract_value(self.builder, lhs, ai)
            let rf = wl_build_extract_value(self.builder, rhs, ai)
            let elem_eq = self.compare_value_eq(lf, rf, elem_ty, BinaryOp.OP_EQ)
            result = wl_build_and(self.builder, result, elem_eq)
            ai = ai + 1
        if op == BinaryOp.OP_EQ:
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
    if op == BinaryOp.OP_EQ:
        return wl_build_icmp(self.builder, wl_int_eq(), cmp, zero)
    wl_build_icmp(self.builder, wl_int_ne(), cmp, zero)

// ── Helper: create entry alloca ───────────────────────────────────

fn Codegen.create_entry_alloca(self: Codegen, ty: i64) -> i64:
    wl_create_entry_alloca(self.builder, self.current_function, ty)

fn vec_data_i64(v: &Vec[i64]) -> i64:
    wl_vec_data_ptr(v)

fn codegen_owned_text(text: str) -> str:
    if text.len() == 0:
        return ""
    with_str_clone(text)

fn Codegen.capture_sema_symbol_texts(self: &mut Codegen):
    let texts: Vec[str] = Vec.new()
    for i in 0..self.sema.pool.state.symbol_texts.len() as i32:
        texts.push(codegen_owned_text(self.sema.pool.state.symbol_texts.get(i as i64)))
    self.sema_symbol_texts = texts

fn Codegen.sema_symbol_text(self: Codegen, sym: i32) -> str:
    if sym > 0 and sym < self.sema_symbol_texts.len() as i32:
        return self.sema_symbol_texts.get(sym as i64)
    if sym > 0 and sym < self.sema.pool.state.symbol_texts.len() as i32:
        return self.sema.pool.state.symbol_texts.get(sym as i64)
    self.sema.pool_resolve(sym)

// ── Resolve type expression → LLVM type ───────────────────────────

fn Codegen.resolve_type(self: Codegen, type_node: i32) -> i64:
    if type_node == 0: return wl_void_type(self.context)
    let kind = self.pool.kind(type_node)

    // with_eprint(f"[codegen] resolve_type node={type_node} kind={kind}")

    if kind == NodeKind.NK_IDENT:
        let sym = self.pool.get_data0(type_node)
        let named = self.resolve_named_type(sym)
        if named != 0:
            return named
        let sema_tid = self.sema.resolve_type_expr(type_node)
        if sema_tid > 0:
            let sema_ty = self.sema_type_to_llvm(sema_tid)
            if sema_ty != 0:
                return sema_ty
        return 0

    if kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.pool.get_data0(type_node)
        let named = self.resolve_named_type(sym)
        if named != 0:
            return named
        let sema_tid = self.sema.resolve_type_expr(type_node)
        if sema_tid > 0:
            let sema_ty = self.sema_type_to_llvm(sema_tid)
            if sema_ty != 0:
                return sema_ty
        return 0

    if kind == NodeKind.NK_TYPE_PTR:
        // Check for dyn trait pointer
        let pointee = self.pool.get_data0(type_node)
        if self.pool.kind(pointee) == NodeKind.NK_TYPE_TRAIT_OBJ:
            // Fat pointer {data_ptr, vtable_ptr}
            return self.get_dyn_fat_ptr_type()
        return wl_ptr_type(self.context)

    if kind == NodeKind.NK_TYPE_REF:
        let pointee = self.pool.get_data0(type_node)
        if self.pool.kind(pointee) == NodeKind.NK_TYPE_TRAIT_OBJ:
            return self.get_dyn_fat_ptr_type()
        return wl_ptr_type(self.context)

    if kind == NodeKind.NK_TYPE_FN:
        // Function type → fat pointer {fn_ptr, ctx_ptr}
        let ptr_ty = wl_ptr_type(self.context)
        let fat_types: Vec[i64] = Vec.new()
        fat_types.push(ptr_ty)
        fat_types.push(ptr_ty)
        return wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)

    if kind == NodeKind.NK_TYPE_ARRAY:
        let elem_node = self.pool.get_data0(type_node)
        let size_lo = self.pool.get_data1(type_node)
        let elem_ty = self.resolve_type(elem_node)
        return wl_array_type(elem_ty, size_lo as i64)

    if kind == NodeKind.NK_TYPE_SLICE:
        let elem_node = self.pool.get_data0(type_node)
        self.resolve_type(elem_node)
        // Slice is {ptr, i64} like str
        let body_types: Vec[i64] = Vec.new()
        body_types.push(wl_ptr_type(self.context))
        body_types.push(wl_i64_type(self.context))
        return wl_struct_type(self.context, vec_data_i64(&body_types), 2, 0)

    if kind == NodeKind.NK_TYPE_OPTIONAL:
        let inner_node = self.pool.get_data0(type_node)
        let payload_ty = self.resolve_type(inner_node)
        let opt = self.get_or_create_option_type(0, payload_ty)
        return opt

    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = self.pool.get_data0(type_node)
        let elem_count = self.pool.get_data1(type_node)
        let elem_types: Vec[i64] = Vec.new()
        for i in 0..elem_count:
            let et_node = self.pool.get_extra(extra_start + i)
            elem_types.push(self.resolve_type(et_node))
        return wl_struct_type(self.context, vec_data_i64(&elem_types), elem_count, 0)

    if kind == NodeKind.NK_TYPE_GENERIC:
        let name_sym = self.pool.get_data0(type_node)
        let g_extra = self.pool.get_data1(type_node)
        let g_count = self.pool.get_data2(type_node)
        // Box[T] is always a pointer (fat pointer for Box[dyn Trait])
        if name_sym == self.sym_box and g_count == 1:
            let inner_node = self.pool.get_extra(g_extra)
            if self.pool.kind(inner_node) == NodeKind.NK_TYPE_TRAIT_OBJ:
                return self.get_dyn_fat_ptr_type()
            return wl_ptr_type(self.context)
        // ContextError[E] = { str, E }
        if name_sym == self.sym_context_error and g_count == 1:
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
        if name_sym == self.sym_option and g_count == 1:
            let opt_arg = self.resolve_type(self.pool.get_extra(g_extra))
            if opt_arg != 0:
                return self.get_or_create_option_type(0, opt_arg)
        if name_sym == self.sym_vec and g_count == 1:
            let vec_arg = self.resolve_type(self.pool.get_extra(g_extra))
            if vec_arg != 0:
                return self.get_or_create_vec_type(0, vec_arg)
        if name_sym == self.sym_result and g_count == 2:
            let res_ok = self.resolve_type(self.pool.get_extra(g_extra))
            let res_err = self.resolve_type(self.pool.get_extra(g_extra + 1))
            if res_ok != 0 and res_err != 0:
                return self.get_or_create_result_type(0, res_ok, res_err)
        // Monomorphize user-defined generic structs
        let gs_opt = self.generic_structs.get(name_sym)
        if gs_opt.is_some():
            return self.monomorphize_struct(name_sym, g_extra, g_count)
        return 0

    if kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        // dyn Trait → fat pointer {data_ptr, vtable_ptr}
        return self.get_dyn_fat_ptr_type()

    if kind == NodeKind.NK_TYPE_INFERRED:
        return 0  // Cannot resolve inferred types

    if kind == NodeKind.NK_TYPE_ASSOC:
        // Self.Name — resolve associated type from current impl
        let base_sym = self.pool.get_data0(type_node)
        let assoc_sym = self.pool.get_data1(type_node)
        if base_sym == self.sym_Self and self.current_function_name_sym != 0:
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
    with_eprint(f"warning: [type-resolve] unhandled type node kind={kind} node={type_node} span={self.pool.get_start(type_node)}..{self.pool.get_end(type_node)}")
    self.type_fallback()

fn Codegen.resolve_primitive_named_type(self: Codegen, sym: i32) -> i64:
    if sym == self.sym_bool: return wl_i1_type(self.context)
    if sym == self.sym_usize: return wl_i64_type(self.context)
    if sym == self.sym_isize: return wl_i64_type(self.context)
    if sym == self.sym_void: return wl_void_type(self.context)
    if sym == self.sym_never: return wl_void_type(self.context)
    if sym == self.sym_unit: return wl_i32_type(self.context)
    let name = self.intern.resolve(sym)
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
    if name == "f64": return wl_f64_type(self.context)
    if name == "f32": return wl_f32_type(self.context)
    0

fn Codegen.resolve_user_named_type(self: Codegen, sym: i32) -> i64:
    let de_opt = self.disc_enum_type_map.get(sym)
    if de_opt.is_some():
        let de_idx = de_opt.unwrap()
        if de_idx >= 0 and de_idx < self.disc_enum_has_payload.len() as i32:
            if self.disc_enum_has_payload.get(de_idx as i64) == 0:
                return self.disc_enum_repr_types.get(de_idx as i64)
    // User-defined struct types
    let st_opt = self.struct_type_map.get(sym)
    if st_opt.is_some():
        let idx = st_opt.unwrap()
        // Bitpacked structs: return the iN backing type
        let bp_ty = self.bitpacked_backing_types.get(idx)
        if bp_ty.is_some():
            return bp_ty.unwrap()
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
    // Resolve Self to current method owner type
    if sym == self.sym_Self and self.current_method_owner_sym != 0:
        return self.resolve_user_named_type(self.current_method_owner_sym)
    let prim = self.resolve_primitive_named_type(sym)
    if prim != 0:
        return prim
    self.resolve_user_named_type(sym)

// Get sema TypeId for an expression node. Uses local_sema_types for idents.
fn Codegen.sema_type_of_node(self: Codegen, node: i32) -> i32:
    if node == 0:
        return 0
    let nk = self.pool.kind(node)
    if self.sema.typed_expr_types.contains(node):
        let typed = self.sema.typed_expr_types.get(node).unwrap()
        if typed > 0:
            return typed
    if nk == NodeKind.NK_IDENT:
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
    if nk == NodeKind.NK_STRING_LIT:
        return self.sema.ty_str as i32
    if nk == NodeKind.NK_FSTRING:
        return self.sema.ty_str as i32
    if nk == NodeKind.NK_INT_LIT:
        let suffix_ty = self.sema.literal_suffix_type(self.pool.literal_suffix(node as NodeId))
        if suffix_ty != 0:
            return suffix_ty
        let fast = self.pool.int_literal_fast_i64(node as NodeId)
        if fast.ok != 0 and (fast.value < -2147483648 or fast.value > 2147483647):
            return self.sema.ty_i64 as i32
        return self.sema.ty_i32 as i32
    if nk == NodeKind.NK_FLOAT_LIT:
        return self.sema.ty_f64 as i32
    if nk == NodeKind.NK_BOOL_LIT:
        return self.sema.ty_bool as i32
    0

// Extract LLVM type of the i'th generic arg from a sema TypeKind.TY_GENERIC_INST type.
fn Codegen.sema_generic_arg_llvm(self: Codegen, sema_tid: i32, arg_idx: i32) -> i64:
    if sema_tid <= 0:
        return 0
    if self.sema.get_type_kind(sema_tid) != TypeKind.TY_GENERIC_INST:
        return 0
    let ac = self.sema.get_generic_inst_arg_count(sema_tid)
    if arg_idx >= ac:
        return 0
    let inner_tid = self.sema.get_generic_inst_arg(sema_tid, arg_idx)
    self.sema_type_to_llvm(inner_tid)

fn Codegen.sema_sym_to_codegen_sym(self: Codegen, sym: i32) -> i32:
    if sym <= 0:
        return 0
    let sema_text = self.sema_symbol_text(sym)
    if sema_text.len() > 0:
        return self.intern.intern(sema_text)
    0

// Map sema TypeId to LLVM type. Handles TypeKind.TY_GENERIC_INST for builtin containers.
fn Codegen.sema_type_to_llvm(self: Codegen, tid: i32) -> i64:
    if tid <= 0:
        return 0
    let resolved_tid = self.sema.resolve_alias(tid)
    let tk = self.sema.get_type_kind(resolved_tid)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.sema.get_type_d0(resolved_tid)
        let cg_base_sym = self.sema_sym_to_codegen_sym(base_sym)
        let arg_count = self.sema.get_generic_inst_arg_count(resolved_tid)
        if cg_base_sym == self.sym_vec and arg_count > 0:
            let elem_tid = self.sema.get_generic_inst_arg(resolved_tid, 0)
            let elem_ty = self.sema_type_to_llvm(elem_tid)
            if elem_ty != 0:
                return self.get_or_create_vec_type(resolved_tid, elem_ty)
        if cg_base_sym == self.sym_hashmap and arg_count > 1:
            let key_tid = self.sema.get_generic_inst_arg(resolved_tid, 0)
            let val_tid = self.sema.get_generic_inst_arg(resolved_tid, 1)
            let key_ty = self.sema_type_to_llvm(key_tid)
            let val_ty = self.sema_type_to_llvm(val_tid)
            if key_ty != 0 and val_ty != 0:
                return self.get_or_create_hashmap_type(resolved_tid, key_ty, val_ty)
        if cg_base_sym == self.sym_hashset and arg_count > 0:
            let elem_tid = self.sema.get_generic_inst_arg(resolved_tid, 0)
            let elem_ty = self.sema_type_to_llvm(elem_tid)
            if elem_ty != 0:
                return self.get_or_create_hashset_type(resolved_tid, elem_ty)
        if cg_base_sym == self.sym_option and arg_count > 0:
            let payload_tid = self.sema.get_generic_inst_arg(resolved_tid, 0)
            let payload_ty = self.sema_type_to_llvm(payload_tid)
            if payload_ty != 0:
                return self.get_or_create_option_type(resolved_tid, payload_ty)
        if cg_base_sym == self.sym_result and arg_count > 1:
            let ok_tid = self.sema.get_generic_inst_arg(resolved_tid, 0)
            let err_tid = self.sema.get_generic_inst_arg(resolved_tid, 1)
            let ok_ty = self.sema_type_to_llvm(ok_tid)
            let err_ty = self.sema_type_to_llvm(err_tid)
            if ok_ty != 0 and err_ty != 0:
                return self.get_or_create_result_type(resolved_tid, ok_ty, err_ty)
        // User-defined generic structs: monomorphize via type bindings
        if cg_base_sym != 0 and self.generic_structs.contains(cg_base_sym):
            let saved_len = self.type_bindings_len
            let saved_syms = self.type_binding_syms
            let saved_types = self.type_binding_types
            let tp_syms: Vec[i32] = Vec.new()
            let tp_types: Vec[i64] = Vec.new()
            let gs_node = self.generic_structs.get(cg_base_sym).unwrap()
            let tp_count = self.type_decl_tp_count(gs_node)
            var tp_pos = self.type_decl_tp_start(gs_node)
            for ti in 0..tp_count:
                let tp_sym = self.pool.get_extra(tp_pos)
                tp_syms.push(tp_sym)
                let bc = self.pool.get_extra(tp_pos + 1)
                tp_pos = tp_pos + 2 + bc
                var arg_ty: i64 = 0
                if ti < arg_count:
                    arg_ty = self.sema_type_to_llvm(self.sema.get_generic_inst_arg(resolved_tid, ti))
                if arg_ty == 0:
                    arg_ty = self.type_fallback()
                tp_types.push(arg_ty)
            self.type_binding_syms = tp_syms
            self.type_binding_types = tp_types
            self.type_bindings_len = tp_count
            let mono_ty = self.monomorphize_struct(cg_base_sym, 0, 0)
            self.type_bindings_len = saved_len
            self.type_binding_syms = saved_syms
            self.type_binding_types = saved_types
            return mono_ty
        return 0
    if tk == TypeKind.TY_FLOAT:
        let width = self.sema.get_type_d0(resolved_tid)
        if width == 32: return wl_f32_type(self.context)
        if width == 64: return wl_f64_type(self.context)
        return wl_f64_type(self.context)
    if tk == TypeKind.TY_INT:
        let bits = self.sema.get_type_d0(resolved_tid)
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
        if bits > 0:
            // Non-standard bit width (sub-byte or custom): use LLVM arbitrary-width int
            return wl_int_type_n(self.context, bits)
        // bits == 0 means default-width int, which is i32
        return wl_i32_type(self.context)
    if tk == TypeKind.TY_BOOL:
        return wl_i1_type(self.context)
    if tk == TypeKind.TY_STR:
        let str_sym = self.intern.intern("str")
        return self.resolve_named_type(str_sym)
    if tk == TypeKind.TY_VOID:
        return wl_void_type(self.context)
    if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM:
        let sym = self.sema.get_type_d0(resolved_tid)
        // Distinct types are transparent: same LLVM type as inner type
        if self.sema.distinct_type_names.contains(sym):
            let inner_tid = self.sema.type_extra.get((self.sema.get_type_d1(resolved_tid) + 1) as i64)
            return self.sema_type_to_llvm(inner_tid)
        let cg_sym = self.sema_sym_to_codegen_sym(sym)
        if cg_sym != 0:
            return self.resolve_named_type(cg_sym)
        return self.resolve_named_type(sym)
    if tk == TypeKind.TY_ARRAY:
        let elem_tid = self.sema.get_type_d0(resolved_tid)
        let arr_len = self.sema.get_type_d1(resolved_tid)
        var elem_ty = self.sema_type_to_llvm(elem_tid)
        if elem_ty == 0:
            elem_ty = self.type_fallback()
        return wl_array_type(elem_ty, arr_len as i64)
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return wl_ptr_type(self.context)
    0

// Reverse map: LLVM type → sema TypeId (for primitives and str)
fn Codegen.llvm_type_to_sema_type(self: Codegen, ty: i64) -> i32:
    if ty == wl_i32_type(self.context): return self.sema.ty_i32 as i32
    if ty == wl_i64_type(self.context): return self.sema.ty_i64 as i32
    if ty == wl_i128_type(self.context): return self.sema.ty_i128 as i32
    if ty == wl_i1_type(self.context): return self.sema.ty_bool as i32
    if ty == wl_i8_type(self.context): return self.sema.ty_i8 as i32
    if ty == wl_i16_type(self.context): return self.sema.ty_i16 as i32
    if ty == wl_f64_type(self.context): return self.sema.ty_f64 as i32
    if ty == wl_f32_type(self.context): return self.sema.ty_f32 as i32
    if self.is_str_type(ty): return self.sema.ty_str as i32
    if ty == wl_ptr_type(self.context):
        // Could be str, ptr, or struct-by-ref — default to str
        return self.sema.ty_str as i32
    if wl_get_type_kind(ty) == wl_struct_type_kind():
        let st_sym = self.find_struct_type_by_llvm(ty)
        if st_sym == self.sym_str:
            return self.sema.ty_str as i32
        if st_sym != 0:
            if self.sema.named_types.contains(st_sym):
                return self.sema.named_types.get(st_sym).unwrap() as i32
            let mono_base_opt = self.mono_struct_base.get(st_sym)
            let tp_start_opt = self.mono_struct_tp_starts.get(st_sym)
            let tp_count_opt = self.mono_struct_tp_counts.get(st_sym)
            if mono_base_opt.is_some() and tp_start_opt.is_some() and tp_count_opt.is_some():
                let tp_flat_start = tp_start_opt.unwrap()
                let tp_count = tp_count_opt.unwrap()
                let sema_args: Vec[i32] = Vec.new()
                for ti in 0..tp_count:
                    var arg_sema = 0
                    if tp_flat_start + ti < self.mono_struct_tp_flat_sema_types.len() as i32:
                        arg_sema = self.mono_struct_tp_flat_sema_types.get((tp_flat_start + ti) as i64)
                    if arg_sema == 0 and tp_flat_start + ti < self.mono_struct_tp_flat_types.len() as i32:
                        let arg_llvm = self.mono_struct_tp_flat_types.get((tp_flat_start + ti) as i64)
                        arg_sema = self.llvm_type_to_sema_type(arg_llvm)
                    if arg_sema == 0:
                        return 0
                    sema_args.push(arg_sema)
                let found = self.sema.ensure_generic_inst_type(mono_base_opt.unwrap(), sema_args, tp_count)
                if found != 0:
                    return found as i32
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
    if sub_kind == TypeDeclKind.Struct:
        let field_count = self.pool.get_extra(extra_start)
        return extra_start + 1 + field_count * 4 + 1
    if sub_kind == TypeDeclKind.Enum:
        let variant_count = self.pool.get_extra(extra_start)
        var pos = extra_start + 1
        for vi in 0..variant_count:
            pos = pos + 1 // variant name
            let payload_count = self.pool.get_extra(pos)
            pos = pos + 1 + payload_count
        return pos + 1
    if sub_kind == TypeDeclKind.DiscEnum:
        let variant_count = self.pool.get_extra(extra_start + 1)
        var pos = extra_start + 2
        for vi in 0..variant_count:
            pos = pos + 1 // variant name
            pos = pos + 1 // disc value
            let payload_count = self.pool.get_extra(pos)
            pos = pos + 1 + payload_count
        return pos + 1
    if sub_kind == TypeDeclKind.Alias or sub_kind == TypeDeclKind.Distinct:
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
    // type_node is the NodeKind.NK_TYPE_DECL node with TypeDeclSubKind.TDK_STRUCT
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
            with_eprint("error: unresolved type for field '" ++ self.intern.resolve(f_name) ++ "' in struct '" ++ name_str ++ "'")
            invalid_layout = 1
            self.had_error = 1
        if f_ty == st_type:
            with_eprint("error: recursive value field '" ++ self.intern.resolve(f_name) ++ "' in struct '" ++ name_str ++ "' (use pointer or reference)")
            invalid_layout = 1
            self.had_error = 1
        let dep_idx = self.find_struct_index_by_type(f_ty)
        if dep_idx >= 0 and dep_idx != idx and self.struct_reaches_type(dep_idx, st_type):
            with_eprint("error: recursive value-cycle detected while lowering struct '" ++ name_str ++ "'")
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
    let is_bitpacked = type_decl_is_bitpacked(packed_kind)

    if is_bitpacked:
        // Bitpacked struct: store as iN where N = sum of field bit widths.
        // Fields are packed MSB-first with no gaps.
        var total_bits: i32 = 0
        let bp_field_start = self.bitpacked_field_bit_offsets.len() as i32
        for fi in 0..field_count:
            let f_ty = ft_vec.get(fi as i64)
            var field_bits: i32 = 0
            let f_tk = wl_get_type_kind(f_ty)
            if f_tk == wl_integer_type_kind():
                field_bits = wl_get_int_type_width(f_ty)
            else if self.is_bitpacked_struct(f_ty):
                // Nested bitpacked struct: inline its bits
                let nested_idx = self.find_bitpacked_index_by_type(f_ty)
                let nested_bits = self.bitpacked_total_bits.get(nested_idx)
                field_bits = if nested_bits.is_some(): nested_bits.unwrap() as i32 else: (self.abi_size_of(f_ty) * 8) as i32
            else:
                // Non-integer field: use 8 bits per byte of ABI size
                field_bits = (self.abi_size_of(f_ty) * 8) as i32
            self.bitpacked_field_bit_offsets.push(total_bits)
            self.bitpacked_field_bit_widths.push(field_bits)
            total_bits = total_bits + field_bits
        // Use iN as the backing type
        let backing_ty = wl_int_type_n(self.context, total_bits)
        self.bitpacked_structs.insert(idx, bp_field_start)
        self.bitpacked_total_bits.insert(idx, total_bits)
        // Store the backing integer type separately (struct_llvm_types keeps the named struct)
        self.bitpacked_backing_types.insert(idx, backing_ty)
        self.bitpacked_by_llvm_type.insert(backing_ty, idx)
        // Identity field index mapping (not used for GEP but needed for bookkeeping)
        for fi in 0..field_count:
            self.struct_llvm_field_indices.push(fi)
        return

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

    // Find max ABI size/alignment among all fields. LLVMSizeOf returns an
    // LLVM constant value, not a host integer, so use Sema's layout model here.
    var max_size: i64 = 0
    var max_align: i64 = 1
    var max_align_ty: i64 = 0
    var max_align_size: i64 = 0
    var invalid_layout = 0
    for fi in 0..field_count:
        let offset = extra_start + 1 + fi * 3
        let f_name = self.pool.get_extra(offset)
        let f_type_node = self.pool.get_extra(offset + 1)
        let f_default = self.pool.get_extra(offset + 2)
        let f_ty = self.resolve_type(f_type_node)
        if f_ty == 0:
            with_eprint("error: unresolved type for field '" ++ self.intern.resolve(f_name) ++ "' in union '" ++ name_str ++ "'")
            invalid_layout = 1
            self.had_error = 1
        self.struct_field_names.push(f_name)
        self.struct_field_types.push(f_ty)
        self.struct_field_type_nodes.push(f_type_node)
        self.struct_field_defaults.push(f_default)
        self.struct_llvm_field_indices.push(0)
        let f_tid = self.sema.resolve_type_expr(f_type_node)
        let f_size = if f_tid > 0: self.sema.type_layout_size_of(f_tid) else: self.abi_size_of(f_ty)
        let f_align = if f_tid > 0: self.sema.type_layout_align_of(f_tid) else: 1
        if f_size > max_size:
            max_size = f_size
        if f_align > max_align:
            max_align = f_align
            max_align_ty = f_ty
            max_align_size = f_size

    if invalid_layout != 0:
        return

    if max_align_ty == 0:
        max_align_ty = wl_i8_type(self.context)
        max_align_size = 1
    if max_align_size <= 0:
        max_align_size = 1
    if max_align <= 0:
        max_align = 1
    if max_size <= 0:
        max_size = 1

    let rem = max_size % max_align
    if rem != 0:
        max_size = max_size + (max_align - rem)

    let body: Vec[i64] = Vec.new()
    body.push(max_align_ty)
    if max_size > max_align_size:
        body.push(wl_array_type(wl_i8_type(self.context), max_size - max_align_size))
    wl_struct_set_body(st_type, vec_data_i64(&body), body.len() as i32, 0)

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
                    with_eprint("error: unresolved payload type for enum variant '" ++ self.intern.resolve(v_name) ++ "' in '" ++ enum_name ++ "'")
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
    let opt_ty = self.get_or_create_option_type(0, repr_ty)
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
    f"__fn_{sym}"

fn codegen_hash_name_component(value: i64) -> str:
    if value < 0:
        return "n" ++ f"{0 - value}"
    f"{value}"

fn codegen_canonical_module_path(path: str) -> str:
    if path.len() == 0 or path == "<unknown>":
        return path
    if path.byte_at(0) == 60:
        return path
    if path.byte_at(0) == 47:
        return resolve_normalize_path(path)
    let cwd = with_getenv_str("PWD")
    if cwd.len() == 0:
        return resolve_normalize_path(path)
    resolve_join(cwd, path)

fn Codegen.module_link_name_for_path(self: Codegen, source_path: str, base_name: str) -> str:
    if self.module_object_mode == 0:
        return base_name
    let canonical_path = codegen_canonical_module_path(source_path)
    if canonical_path.len() == 0 or canonical_path == "<unknown>":
        return base_name
    "__with_mod_" ++ codegen_hash_name_component(with_str_hash(canonical_path)) ++ "__" ++ base_name

fn Codegen.current_decl_module_link_name(self: Codegen, base_name: str) -> str:
    self.module_link_name_for_path(self.current_decl_source_file, base_name)

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
    if node == 0 or self.pool.kind(node) != NodeKind.NK_FIELD_ACCESS:
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
                let mk_str = f"$m${method_owner_sym}|{short_method_sym}"
                method_key_sym = self.intern.intern(mk_str)
            break

    // Methods owned by generic structs are always compiled lazily against a
    // concrete owner instantiation. Even "static" methods like Foo.wrap(x: T)
    // or methods returning Self need the owner bindings before their LLVM
    // signature can be resolved correctly.
    if method_owner_sym != 0:
        let gs_decl_opt = self.generic_structs.get(method_owner_sym)
        if gs_decl_opt.is_some():
            self.generic_struct_methods.insert(name_sym, fn_node)
            return

    // Set method owner before resolving return type so Self can resolve
    let saved_owner = self.current_method_owner_sym
    if method_owner_sym != 0:
        self.current_method_owner_sym = method_owner_sym

    let ret_ty_raw = self.resolve_type(ret_type_node)
    let ret_ty = if ret_ty_raw != 0: ret_ty_raw else: self.type_fallback()

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
            param_types.push(self.type_fallback())
            pi = pi + 1
            continue

        let p_kind = self.pool.kind(p_type_node)

        // Method owner-type parameter: lower as pointer for struct types.
        // Applies to self (pi==0) AND any other param of the same owner type.
        if p_kind == NodeKind.NK_TYPE_NAMED:
            let p_sym = self.pool.get_data0(p_type_node)
            if method_owner_sym == 0 and p_name == self.sym_self and self.struct_type_map.get(p_sym).is_some():
                method_owner_sym = p_sym
            if method_owner_sym != 0 and (p_sym == self.sym_Self or p_sym == method_owner_sym):
                // Only lower as pointer for struct/enum types; primitives and str pass by value.
                // str is in struct_type_map but has special value semantics (==, compare_str_eq).
                let is_str_owner = method_owner_sym == self.sym_str
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
        if p_kind == NodeKind.NK_TYPE_FN:
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
                dyn_ty = self.type_fallback()
            param_types.push(dyn_ty)
            self.record_dyn_param(name_sym, pi, param_count, trait_sym)
            if alias_sym != 0:
                self.record_dyn_param(alias_sym, pi, param_count, trait_sym)
            if method_key_sym != 0:
                self.record_dyn_param(method_key_sym, pi, param_count, trait_sym)
            pi = pi + 1
            continue

        // Reference params
        if p_kind == NodeKind.NK_TYPE_REF:
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

    let cc_name = self.fn_callconv_name(meta)
    let uses_c_abi = self.fn_uses_c_abi(cc_name)
    let actual_param_types: Vec[i64] = Vec.new()
    let byval_types: Vec[i64] = Vec.new()
    let ptr_ty = wl_ptr_type(self.context)
    var actual_ret_ty = ret_ty
    var has_sret = 0
    var sret_ty: i64 = 0
    var byval_mask: i64 = 0
    if uses_c_abi:
        if ret_ty != 0 and wl_get_type_kind(ret_ty) == wl_struct_type_kind():
            let ret_size = self.abi_size_of(ret_ty)
            if ret_size > 16:
                has_sret = 1
                sret_ty = ret_ty
                actual_ret_ty = wl_void_type(self.context)
        if has_sret != 0:
            actual_param_types.push(ptr_ty)
        for abi_pi in 0..param_count:
            let source_ty = param_types.get(abi_pi as i64)
            if wl_get_type_kind(source_ty) == wl_struct_type_kind():
                let p_size = self.abi_size_of(source_ty)
                if p_size > 16:
                    actual_param_types.push(ptr_ty)
                    byval_mask = byval_mask | ((1 as i64) << (abi_pi as u32))
                    byval_types.push(source_ty)
                    continue
            actual_param_types.push(source_ty)
            byval_types.push(0)
    else:
        for abi_pi in 0..param_count:
            actual_param_types.push(param_types.get(abi_pi as i64))
    let actual_param_count = actual_param_types.len() as i32
    let fn_type = wl_function_type(actual_ret_ty, vec_data_i64(&actual_param_types), actual_param_count, 0)

    // Use "main" for @[entry] functions
    var effective_name = self.function_symbol_name(name_sym)
    if parsed_name.len() > 0:
        effective_name = parsed_name
    if (flags / FnFlags.ENTRY) % 2 == 1:
        effective_name = "main"
    else if self.module_object_mode != 0:
        if not (cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:"):
            effective_name = self.current_decl_module_link_name(effective_name)

    let function = wl_add_function(self.llmod, effective_name, fn_type)
    if has_sret != 0:
        wl_add_sret_attr(self.context, function, 0, sret_ty)
    self.apply_noalias_param_attrs_with_offset(function, param_start, param_count, if has_sret != 0: 1 else: 0)

    // Whole-program codegen internalizes non-prelude functions because imported
    // modules are duplicated into the current AST. In module-object mode we must
    // keep owner definitions externally linkable and let importers reference them.
    if self.module_object_mode == 0:
        let is_prelude = self.current_decl_source_file.contains("lib/std/")
        if effective_name != "main" and not is_prelude:
            wl_set_linkage(function, wl_internal_linkage())

    // @[weak] — set weak linkage (LLVMWeakAnyLinkage = 5)
    // Must be checked before c_export which also sets linkage.
    let is_weak = self.pool.fn_weak_flags.contains(fn_node)

    // @[c_export] overrides internal linkage to external for C/linker visibility
    if cc_name.len() > 0:
        if cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:":
            if is_weak:
                wl_set_linkage(function, 5)  // LLVMWeakAnyLinkage
            else:
                wl_set_linkage(function, 0)
            let export_name = cc_name.slice(9, cc_name.len() as i64)
            if export_name.len() > 0 and export_name != effective_name:
                wl_set_value_name(function, export_name)
            wl_set_call_conv(function, wl_cc_c())
        else:
            let cc_id = self.resolve_callconv(cc_name)
            if cc_id >= 0:
                wl_set_call_conv(function, cc_id)

    // Apply attributes
    if (flags / FnFlags.INLINE) % 2 == 1:
        wl_add_fn_attr(self.context, function, "alwaysinline")
    if (flags / FnFlags.NOINLINE) % 2 == 1:
        wl_add_fn_attr(self.context, function, "noinline")

    if has_sret != 0 or byval_mask != 0:
        self.extern_fn_has_sret.insert(name_sym, has_sret)
        self.extern_fn_byval_params.insert(name_sym, byval_mask)
        self.extern_fn_byval_types.insert(name_sym, byval_types)
        if has_sret != 0:
            self.extern_fn_sret_type.insert(name_sym, sret_ty)
        if alias_sym != 0:
            self.extern_fn_has_sret.insert(alias_sym, has_sret)
            self.extern_fn_byval_params.insert(alias_sym, byval_mask)
            if has_sret != 0:
                self.extern_fn_sret_type.insert(alias_sym, sret_ty)
        if method_key_sym != 0:
            self.extern_fn_has_sret.insert(method_key_sym, has_sret)
            self.extern_fn_byval_params.insert(method_key_sym, byval_mask)
            if has_sret != 0:
                self.extern_fn_sret_type.insert(method_key_sym, sret_ty)

    self.fn_values.insert(name_sym, function)
    self.fn_fn_types.insert(name_sym, fn_type)
    if alias_sym != 0:
        self.fn_values.insert(alias_sym, function)
        self.fn_fn_types.insert(alias_sym, fn_type)
    if method_key_sym != 0:
        self.fn_values.insert(method_key_sym, function)
        self.fn_fn_types.insert(method_key_sym, fn_type)

    self.current_method_owner_sym = saved_owner

fn Codegen.is_method_on_generic_struct(self: Codegen, name_sym: i32) -> bool:
    if name_sym <= 0:
        return false
    let name_str = self.intern.resolve(name_sym)
    if name_str.len() == 0:
        return false
    for di in 0..name_str.len() as i32:
        if name_str.byte_at(di as i64) == 46:
            let owner_sym = self.intern.intern(name_str.slice(0, di as i64))
            return self.generic_structs.contains(owner_sym)
    false

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
    self.apply_noalias_param_attrs_with_offset(function, param_start, param_count, 0)

fn Codegen.apply_noalias_param_attrs_with_offset(self: Codegen, function: i64, param_start: i32, param_count: i32, param_offset: i32):
    if function == 0 or param_start < 0 or param_count <= 0:
        return
    let fn_type = wl_global_get_value_type(function)
    for pi in 0..param_count:
        let flags = self.pool.fn_param_flags(param_start, pi)
        if fn_param_is_noalias(flags) == 0:
            continue
        let actual_idx = pi + param_offset
        var param_ty = if fn_type != 0: wl_get_fn_param_type(fn_type, actual_idx) else: 0
        if param_ty == 0:
            let param = wl_get_param(function, actual_idx)
            if param == 0:
                continue
            param_ty = wl_type_of(param)
        if wl_get_type_kind(param_ty) != wl_pointer_type_kind():
            continue
        wl_add_param_attr(self.context, function, actual_idx, "noalias")

fn Codegen.record_dyn_param(self: Codegen, fn_sym: i32, idx: i32, count: i32, trait_sym: i32):
    if not self.fn_dyn_param_starts.get(fn_sym).is_some():
        let start = self.fn_dyn_param_data.len() as i32
        self.fn_dyn_param_starts.insert(fn_sym, start)
        for j in 0..count:
            self.fn_dyn_param_data.push(0)
    let base = self.fn_dyn_param_starts.get(fn_sym).unwrap()
    self.fn_dyn_param_data.set_i32((base + idx) as i64, trait_sym)

fn Codegen.fn_callconv_name(self: Codegen, meta: i32) -> str:
    if meta < 0:
        return ""
    let cc_sym = self.pool.fn_meta_tp_start(meta)
    if cc_sym == 0:
        return ""
    let cc_name = self.intern.resolve(cc_sym)
    if cc_name.len() >= 2 and cc_name.byte_at(0) == 34 and cc_name.byte_at(cc_name.len() - 1) == 34:
        return cc_name.slice(1, cc_name.len() - 1)
    cc_name

fn Codegen.fn_uses_c_abi(self: Codegen, cc_name: str) -> bool:
    cc_name == "c" or (cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:")

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

    // Resolve original param types
    let orig_param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        orig_param_types.push(self.resolve_type(p_type_node))

    // ABI transformation for C interop on aarch64:
    // - Struct params > 16 bytes → ptr (caller passes pointer to copy)
    // - Struct returns > 16 bytes → void return + hidden sret ptr first param
    let ptr_ty = wl_ptr_type(self.context)
    var has_sret = 0
    var sret_ty: i64 = 0
    var byval_mask: i64 = 0
    let byval_types: Vec[i64] = Vec.new()

    // Check return type: struct > 16 bytes → sret
    var actual_ret_ty = ret_ty
    if ret_ty != 0 and wl_get_type_kind(ret_ty) == wl_struct_type_kind():
        let ret_size = self.abi_size_of(ret_ty)
        if ret_size > 16:
            has_sret = 1
            sret_ty = ret_ty
            actual_ret_ty = wl_void_type(self.context)

    // Build final param list with ABI transformations
    let param_types: Vec[i64] = Vec.new()
    if has_sret != 0:
        param_types.push(ptr_ty)  // hidden sret param at index 0

    for pi in 0..param_count:
        let orig_ty = orig_param_types.get(pi as i64)
        if wl_get_type_kind(orig_ty) == wl_struct_type_kind():
            let p_size = self.abi_size_of(orig_ty)
            if p_size > 16:
                param_types.push(ptr_ty)
                byval_mask = byval_mask | ((1 as i64) << (pi as u32))
                byval_types.push(orig_ty)
                continue
        param_types.push(orig_ty)
        byval_types.push(0)

    let actual_param_count = param_types.len() as i32
    let fn_type = wl_function_type(actual_ret_ty, vec_data_i64(&param_types), actual_param_count, is_variadic)

    let name_str = self.intern.resolve(name_sym)
    let link_name = self.canonical_extern_name(name_str)

    // Check if already declared
    let existing = wl_get_named_function(self.llmod, link_name)
    var function = existing
    if existing == 0:
        function = wl_add_function(self.llmod, link_name, fn_type)

    // Add sret attribute to first param if needed
    if has_sret != 0:
        wl_add_sret_attr(self.context, function, 0, sret_ty)

    // No byval attribute needed — clang on aarch64 uses plain ptr for indirect
    // struct params. The caller copies the struct to an alloca and passes a pointer.

    // Record ABI transformations for call sites
    if has_sret != 0 or byval_mask != 0:
        self.extern_fn_has_sret.insert(name_sym, has_sret)
        self.extern_fn_byval_params.insert(name_sym, byval_mask)
        self.extern_fn_byval_types.insert(name_sym, byval_types)
        if has_sret != 0:
            self.extern_fn_sret_type.insert(name_sym, sret_ty)

    self.apply_noalias_param_attrs_with_offset(function, param_start, param_count, if has_sret != 0: 1 else: 0)

    // Apply calling convention or c_export if specified
    let cc_name = self.fn_callconv_name(meta)
    if cc_name.len() > 0:
        if cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:":
            // @[c_export("name")] — set external linkage for C visibility
            // External linkage = 0 in LLVM (default for non-internal functions)
            wl_set_linkage(function, 0)
        else:
            let cc_id = self.resolve_callconv(cc_name)
            if cc_id >= 0:
                wl_set_call_conv(function, cc_id)

    // (weak linkage applied earlier, near function creation)

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
    // NodeKind.NK_EXTERN_VAR: d0=name(sym), d1=type_node, d2=flags(bit0=mut)
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
        if kind == NodeKind.NK_FN_DECL:
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
    if self.pool.kind(ret_node) != NodeKind.NK_TYPE_GENERIC: return false
    let name_sym = self.pool.get_data0(ret_node)
    let arg_count = self.pool.get_data2(ret_node)
    if arg_count != 2: return false
    name_sym == self.sym_result

fn Codegen.result_err_symbol_from_return(self: Codegen, ret_node: i32) -> i32:
    if not self.is_result_return_type(ret_node): return 0
    let extra_start = self.pool.get_data1(ret_node)
    let err_node = self.pool.get_extra(extra_start + 1)
    if self.pool.kind(err_node) == NodeKind.NK_TYPE_NAMED:
        return self.pool.get_data0(err_node)
    0

fn Codegen.is_result_unit_return(self: Codegen, ret_node: i32) -> bool:
    if not self.is_result_return_type(ret_node): return false
    let extra_start = self.pool.get_data1(ret_node)
    let ok_node = self.pool.get_extra(extra_start)
    if self.pool.kind(ok_node) == NodeKind.NK_TYPE_NAMED:
        return self.pool.get_data0(ok_node) == self.sym_unit
    false

// ── Option/Result type construction ───────────────────────────────

fn Codegen.get_or_create_option_type(self: Codegen, sema_tid: i32, payload_ty: i64) -> i64:
    // Optional pointers are represented as the pointer itself: null = None.
    if payload_ty != 0 and wl_get_type_kind(payload_ty) == wl_pointer_type_kind():
        return payload_ty

    let cache_key = if sema_tid > 0: sema_tid as i64 else: payload_ty
    let cached = self.option_cache_map.get(cache_key)
    if cached.is_some():
        return cached.unwrap()

    // Option[T] = { i32 tag, T payload }
    let body: Vec[i64] = Vec.new()
    body.push(wl_i32_type(self.context))
    if payload_ty != 0:
        body.push(payload_ty)
    let opt_type = wl_struct_type(self.context, vec_data_i64(&body), body.len() as i32, 0)
    self.option_cache_map.insert(cache_key, opt_type)
    opt_type

fn Codegen.get_or_create_result_type(self: Codegen, sema_tid: i32, ok_ty: i64, err_ty: i64) -> i64:
    let cache_key = if sema_tid > 0: f"{sema_tid}" else: f"{ok_ty}:{err_ty}"
    let cached = self.result_cache_map.get(cache_key)
    if cached.is_some():
        return cached.unwrap()

    let ok_size = self.abi_size_of(ok_ty)
    let err_size = self.abi_size_of(err_ty)
    var max_size = ok_size
    if err_size > max_size: max_size = err_size

    let body: Vec[i64] = Vec.new()
    body.push(wl_i32_type(self.context))
    if max_size > 0:
        body.push(wl_array_type(wl_i8_type(self.context), max_size))
    let res_type = wl_struct_type(self.context, vec_data_i64(&body), body.len() as i32, 0)
    self.result_cache_map.insert(cache_key, res_type)
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
        body.push(self.type_fallback())
    body.push(source_ty)
    wl_struct_type(self.context, vec_data_i64(&body), 2, 0)

// ── Vec/HashMap/HashSet type construction ─────────────────────────

fn Codegen.deterministic_type_tag(self: Codegen, ty: i64) -> str:
    let kind = wl_get_type_kind(ty)
    if kind == wl_integer_type_kind():
        return f"i{wl_get_int_type_width(ty)}"
    if kind == wl_float_type_kind() or kind == wl_double_type_kind():
        return "f64"
    if kind == wl_pointer_type_kind():
        return "ptr"
    if kind == wl_struct_type_kind():
        let sn = wl_get_struct_name(ty)
        if sn.len() > 0:
            return sn
        return f"s{wl_count_struct_elem_types(ty)}"
    f"t{ty}"

fn Codegen.collection_wrapper_name_1(self: Codegen, prefix: str, t0: i64) -> str:
    prefix ++ "." ++ self.deterministic_type_tag(t0)

fn Codegen.collection_wrapper_name_2(self: Codegen, prefix: str, t0: i64, t1: i64) -> str:
    prefix ++ "." ++ self.deterministic_type_tag(t0) ++ "." ++ self.deterministic_type_tag(t1)

fn Codegen.get_or_create_vec_type(self: Codegen, sema_tid: i32, elem_ty: i64) -> i64:
    // Use sema type ID as cache key when available (preserves generic identity).
    // Fall back to LLVM element type pointer for MIR intrinsic contexts where
    // sema type is not available (sema_tid == 0).
    let cache_key = if sema_tid > 0: sema_tid as i64 else: elem_ty
    let cached = self.vec_cache_map.get(cache_key)
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
    self.cache_vec_type(sema_tid, elem_ty, vec_ty)
    vec_ty

fn Codegen.cache_vec_type(self: Codegen, sema_tid: i32, elem_ty: i64, vec_ty: i64) -> i64:
    let cache_key = if sema_tid > 0: sema_tid as i64 else: elem_ty
    let cached = self.vec_cache_map.get(cache_key)
    if cached.is_some():
        return cached.unwrap()
    self.vec_cache_map.insert(cache_key, vec_ty)
    self.vec_is_vec.insert(vec_ty, 1)
    vec_ty

fn Codegen.get_or_create_hashmap_type(self: Codegen, sema_tid: i32, key_ty: i64, val_ty: i64) -> i64:
    let hash = if sema_tid > 0: sema_tid as i64 else: key_ty * 65537 + val_ty
    let cached = self.hm_cache_map.get(hash)
    if cached.is_some():
        let existing = cached.unwrap() as i64
        if self.hm_is_hm.contains(existing):
            return existing
    // HashMap is opaque { ptr }
    let body: Vec[i64] = Vec.new()
    body.push(wl_ptr_type(self.context))
    let name = self.collection_wrapper_name_2("__with.HashMap", key_ty, val_ty)
    let hm_ty = wl_struct_create_named(self.context, name)
    wl_struct_set_body(hm_ty, vec_data_i64(&body), 1, 0)
    self.cache_hashmap_type(sema_tid, key_ty, val_ty, hm_ty)
    hm_ty

fn Codegen.cache_hashmap_type(self: Codegen, sema_tid: i32, key_ty: i64, val_ty: i64, hm_ty: i64) -> i64:
    let hash = if sema_tid > 0: sema_tid as i64 else: key_ty * 65537 + val_ty
    let cached = self.hm_cache_map.get(hash)
    if cached.is_some():
        let existing = cached.unwrap()
        if self.hm_is_hm.contains(existing):
            return existing
    if self.hm_is_hm.contains(hm_ty):
        self.hm_cache_map.insert(hash, hm_ty)
        return hm_ty
    self.hm_is_hm.insert(hm_ty, 1)
    self.hm_cache_map.insert(hash, hm_ty)
    hm_ty

fn Codegen.get_or_create_hashset_type(self: Codegen, sema_tid: i32, elem_ty: i64) -> i64:
    let cache_key = if sema_tid > 0: sema_tid as i64 else: elem_ty
    let cached = self.hs_cache_map.get(cache_key)
    if cached.is_some():
        return cached.unwrap()
    let body: Vec[i64] = Vec.new()
    body.push(wl_ptr_type(self.context))
    let name = self.collection_wrapper_name_1("__with.HashSet", elem_ty)
    let hs_ty = wl_struct_create_named(self.context, name)
    wl_struct_set_body(hs_ty, vec_data_i64(&body), 1, 0)
    self.hs_cache_map.insert(cache_key, hs_ty)
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
    let arg_sema_types: Vec[i32] = Vec.new()
    if arg_count > 0:
        for ai in 0..arg_count:
            let arg_node = self.pool.get_extra(extra_start + ai)
            let arg_sema = self.sema.resolve_type_expr(arg_node) as i32
            let arg_ty = self.resolve_type(arg_node)
            if arg_ty != 0:
                arg_types.push(arg_ty)
            else:
                arg_types.push(wl_i32_type(self.context))
            if arg_sema != 0:
                arg_sema_types.push(arg_sema)
            else:
                arg_sema_types.push(self.llvm_type_to_sema_type(arg_types.get(ai as i64)))
    else:
        for ti in 0..tp_count:
            let tp_sym = tp_syms.get(ti as i64)
            var bound_ty: i64 = 0
            for bi in 0..self.type_bindings_len:
                if self.type_binding_syms.get(bi as i64) == tp_sym:
                    bound_ty = self.type_binding_types.get(bi as i64)
                    break
            if bound_ty == 0:
                bound_ty = self.type_fallback()
            arg_types.push(bound_ty)
            arg_sema_types.push(self.llvm_type_to_sema_type(bound_ty))
    while arg_types.len() as i32 < tp_count:
        let fallback_ty = self.type_fallback()
        arg_types.push(fallback_ty)
        arg_sema_types.push(self.llvm_type_to_sema_type(fallback_ty))

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
        self.mono_struct_tp_flat_sema_types.push(arg_sema_types.get(ti as i64))
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
            with_eprint("error: unresolved type for field '" ++ self.intern.resolve(f_name) ++ "' in struct '" ++ base_name ++ "'")
            invalid_layout = 1
            self.had_error = 1
            f_ty = self.type_fallback()
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
        with_eprint("error: no type param bindings for monomorphized struct")
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
    let saved_owner = self.current_method_owner_sym
    self.current_method_owner_sym = mono_type_sym

    // Resolve param and return types with type bindings active
    let mono_param_types: Vec[i64] = Vec.new()
    var has_ref_self = false
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if p_type_node != 0:
            var p_ty = self.resolve_type(p_type_node)
            if p_ty == 0:
                p_ty = self.type_fallback()
            // Methods pass struct self as pointer
            if pi == 0:
                let p_kind = self.pool.kind(p_type_node)
                if p_kind == NodeKind.NK_TYPE_GENERIC or p_kind == NodeKind.NK_TYPE_NAMED:
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
            mono_param_types.push(self.type_fallback())

    let mono_ret_ty_raw = self.resolve_type(ret_type_node)
    let mono_ret_ty = if mono_ret_ty_raw != 0: mono_ret_ty_raw else: self.type_fallback()

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
        sm_tp_syms.push(tp_sym)
        var tp_sema = 0
        if tp_flat_start + ti < self.mono_struct_tp_flat_sema_types.len() as i32:
            tp_sema = self.mono_struct_tp_flat_sema_types.get((tp_flat_start + ti) as i64)
        if tp_sema == 0:
            let tp_llvm = self.mono_struct_tp_flat_types.get((tp_flat_start + ti) as i64)
            tp_sema = self.llvm_type_to_sema_type(tp_llvm)
        sm_tp_sema_tys.push(tp_sema)

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
    self.current_method_owner_sym = saved_owner

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

fn Codegen.monomorphize_struct_static_method_core(self: Codegen, mono_type_sym: i32, method_name: str, decl: i32, args_start: i32, arg_count: i32, call_node: i32, pre_args: Vec[i64]) -> i64:
    let tp_start_opt = self.mono_struct_tp_starts.get(mono_type_sym)
    if not tp_start_opt.is_some():
        with_eprint("error: no type param bindings for monomorphized struct")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))
    let tp_flat_start = tp_start_opt.unwrap()
    let tp_count = self.mono_struct_tp_counts.get(mono_type_sym).unwrap()

    let mono_type_name = self.intern.resolve(mono_type_sym)
    let mangled = mono_type_name ++ "." ++ method_name
    let mono_sym = self.intern.intern(mangled)

    let cached_fv = self.fn_values.get(mono_sym)
    let cached_ft = self.fn_fn_types.get(mono_sym)
    if cached_fv.is_some() and cached_ft.is_some():
        let coerced = self.coerce_call_args_for_fn_value(mono_sym, cached_fv.unwrap() as i64, args_start, 0, pre_args, arg_count, "method " ++ mangled, call_node)
        return wl_build_call(self.builder, cached_ft.unwrap() as i64, cached_fv.unwrap() as i64, vec_data_i64(&coerced), arg_count)

    let saved_bind_syms = self.type_binding_syms
    let saved_bind_tys = self.type_binding_types
    let saved_bind_len = self.type_bindings_len
    let saved_owner = self.current_method_owner_sym
    let fresh_bind_syms: Vec[i32] = Vec.new()
    let fresh_bind_tys: Vec[i64] = Vec.new()
    self.type_binding_syms = fresh_bind_syms
    self.type_binding_types = fresh_bind_tys
    self.type_bindings_len = 0
    self.current_method_owner_sym = mono_type_sym
    for ti in 0..tp_count:
        self.type_binding_syms.push(self.mono_struct_tp_flat_syms.get((tp_flat_start + ti) as i64))
        self.type_binding_types.push(self.mono_struct_tp_flat_types.get((tp_flat_start + ti) as i64))
        self.type_bindings_len = self.type_bindings_len + 1

    let meta = self.pool.find_fn_meta(decl)
    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)
    let mono_param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let p_type_node = self.pool.fn_param_type(param_start, pi)
        if p_type_node != 0:
            var p_ty = self.resolve_type(p_type_node)
            if p_ty == 0:
                p_ty = self.type_fallback()
            mono_param_types.push(p_ty)
        else:
            mono_param_types.push(self.type_fallback())

    let mono_ret_ty_raw = self.resolve_type(ret_type_node)
    let mono_ret_ty = if mono_ret_ty_raw != 0: mono_ret_ty_raw else: self.type_fallback()

    let mono_ft = wl_function_type(mono_ret_ty, vec_data_i64(&mono_param_types), param_count, 0)
    let mono_fn = wl_add_function(self.llmod, mangled, mono_ft)
    self.apply_noalias_param_attrs(mono_fn, param_start, param_count)
    self.fn_values.insert(mono_sym, mono_fn)
    self.fn_fn_types.insert(mono_sym, mono_ft)

    let sm_tp_syms: Vec[i32] = Vec.new()
    let sm_tp_sema_tys: Vec[i32] = Vec.new()
    for ti in 0..tp_count:
        let tp_sym = self.mono_struct_tp_flat_syms.get((tp_flat_start + ti) as i64)
        sm_tp_syms.push(tp_sym)
        var tp_sema = 0
        if tp_flat_start + ti < self.mono_struct_tp_flat_sema_types.len() as i32:
            tp_sema = self.mono_struct_tp_flat_sema_types.get((tp_flat_start + ti) as i64)
        if tp_sema == 0:
            let tp_llvm = self.mono_struct_tp_flat_types.get((tp_flat_start + ti) as i64)
            tp_sema = self.llvm_type_to_sema_type(tp_llvm)
        sm_tp_sema_tys.push(tp_sema)

    let sig_idx = self.sema.check_fn_body_concrete(decl, sm_tp_syms, sm_tp_sema_tys, mono_sym)
    var mir_builder = MirBuilder.init(self.sema, self.pool, self.intern, mono_sym)
    let mir_body = lower_fn_with_sig(mir_builder, decl, sig_idx)
    self.gen_function_mir_mono(mono_sym, decl, mir_body)

    self.type_binding_syms = saved_bind_syms
    self.type_binding_types = saved_bind_tys
    self.type_bindings_len = saved_bind_len
    self.current_method_owner_sym = saved_owner

    let coerced = self.coerce_call_args_for_fn_value(mono_sym, mono_fn, args_start, 0, pre_args, arg_count, "method " ++ mangled, call_node)
    wl_build_call(self.builder, mono_ft, mono_fn, vec_data_i64(&coerced), arg_count)

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
        let payload_ty = wl_struct_get_type_at(opt_type, 1)
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

fn Codegen.extract_result_payload(self: Codegen, recv: i64, payload_ty: i64) -> i64:
    if payload_ty == 0:
        return wl_get_undef(wl_i32_type(self.context))
    if self.abi_size_of(payload_ty) == 0:
        return self.build_default_value(payload_ty)
    let recv_ty = wl_type_of(recv)
    if recv_ty == 0 or wl_get_type_kind(recv_ty) != wl_struct_type_kind():
        return self.build_default_value(payload_ty)
    if wl_count_struct_elem_types(recv_ty) <= 1:
        return self.build_default_value(payload_ty)
    let alloca = wl_build_alloca(self.builder, recv_ty)
    wl_build_store(self.builder, recv, alloca)
    let payload_ptr = wl_build_struct_gep(self.builder, recv_ty, alloca, 1)
    let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
    wl_build_load(self.builder, payload_ty, cast_ptr)

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
    // NodeKind.NK_TYPE_FN: d0=extra_start, d1=param_count, d2=return_type(node)
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
        with_eprint(f"[llvm-cg] gen_module input.decls={pool.decl_count()} input.nodes={pool.node_count()}")
    self.pool = pool
    if self.debug_pool_flow_enabled():
        with_eprint(f"[llvm-cg] gen_module self.decls={self.pool.decl_count()} self.nodes={self.pool.node_count()}")

    self.debug_init_module()

    // Declare built-in str type before user types
    self.declare_builtin_str_type()

    // Pass 0a: predeclare all struct/enum names so forward references resolve.
    for i in 0..self.pool.decl_count():
        self.sync_decl_context(i)
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind != NodeKind.NK_TYPE_DECL:
            continue
        let name_sym = self.pool.get_data0(decl)
        let name_str = self.intern.resolve(name_sym)
        if name_sym == 0 or name_str.len() == 0:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind == TypeDeclKind.Distinct:
            continue
        if sub_kind == TypeDeclKind.Struct:
            if self.type_decl_tp_count(decl) > 0:
                self.generic_structs.insert(name_sym, decl as i32)
            else:
                self.predeclare_struct_type(name_sym)
            continue
        if sub_kind == TypeDeclKind.Enum:
            if self.type_decl_tp_count(decl) > 0:
                continue
            self.predeclare_enum_type(name_sym)

        if sub_kind == TypeDeclKind.DiscEnum:
            self.predeclare_enum_type(name_sym)
            continue
        if sub_kind == TypeDeclKind.Opaque:
            self.predeclare_struct_type(name_sym)
            continue

    // Pass 0b: define struct/enum bodies and type aliases.
    for i in 0..self.pool.decl_count():
        self.sync_decl_context(i)
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind != NodeKind.NK_TYPE_DECL:
            continue
        let name_sym = self.pool.get_data0(decl)
        let name_str = self.intern.resolve(name_sym)
        if name_sym == 0 or name_str.len() == 0:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind == TypeDeclKind.Struct:
            if self.type_decl_tp_count(decl) == 0:
                self.declare_struct_type(name_sym, decl)
            continue
        if sub_kind == TypeDeclKind.Enum:
            if self.type_decl_tp_count(decl) > 0:
                continue
            self.declare_enum_type(name_sym, decl)
            continue
        if sub_kind == TypeDeclKind.DiscEnum:
            self.declare_disc_enum_type(name_sym, decl)
            continue
        if sub_kind == TypeDeclKind.Opaque:
            // Opaque type: predeclared in pass 0a, no body set (stays opaque)
            continue
        if sub_kind == TypeDeclKind.Union:
            self.declare_union_type(name_sym, decl)
            continue
        if sub_kind == TypeDeclKind.Distinct:
            // Distinct type: transparent — same LLVM type as inner type.
            // Type safety enforced by sema, not by LLVM types.
            continue
            continue
        if sub_kind == TypeDeclKind.Alias:
            let extra_start = self.pool.get_data1(decl)
            let aliased_node = self.pool.get_extra(extra_start)
            let resolved = self.resolve_type(aliased_node)
            self.type_aliases.insert(name_sym, resolved)

    if self.had_error != 0:
        return 1

    // Pass 0.5: collect trait declarations
    for i in 0..self.pool.decl_count():
        self.sync_decl_context(i)
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NodeKind.NK_TRAIT_DECL:
            self.collect_trait_info(decl)

    // Pass 1: declare all functions and externs (forward declarations)
    for i in 0..self.pool.decl_count():
        self.sync_decl_context(i)
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NodeKind.NK_EXTERN_FN:
            self.declare_extern_fn(decl)
            continue
        if kind == NodeKind.NK_EXTERN_VAR:
            self.declare_extern_var(decl)
            continue
        if kind != NodeKind.NK_FN_DECL:
            continue
        let name_sym = self.pool.get_data0(decl)
        if name_sym == 0:
            continue
        let flags = self.pool.get_data2(decl)
        let meta = self.pool.find_fn_meta(decl)
        let is_sema_generic = self.sema.generic_fn_nodes.contains(name_sym)
        let is_generic_struct_method = self.is_method_on_generic_struct(name_sym)
        // Skip sema-generic functions unless they use the generic-struct
        // lazy path in declare_function(). Blanket impl methods borrow type
        // params from impl context, so eager declaration resolves unbound names.
        if meta >= 0:
            let tp_count = self.pool.fn_meta_tp_count(meta)
            if tp_count > 0:
                self.generic_fns.insert(name_sym, decl as i32)
            else if is_sema_generic and not is_generic_struct_method:
                continue
            else if (flags / FnFlags.ASYNC) % 2 == 1:
                self.declare_async_function(decl)
            else:
                self.declare_function(decl)

    // Pass 1.3: synthesize missing impl methods from trait defaults.
    self.generate_default_trait_methods()

    // Pass 1.25: synthesize trait vtables after all method declarations exist.
    self.generate_trait_vtables()

    // Pass 1.4: process top-level let declarations as module constants.
    // Function declarations must exist first so global struct initializers can
    // contain function-pointer fields.
    for i in 0..self.pool.decl_count():
        self.sync_decl_context(i)
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NodeKind.NK_LET_DECL:
            self.gen_module_constant(decl)

    // Pass 1.5: detect drop functions
    self.detect_drop_functions()

    // Pass 2: generate function bodies
    for i in 0..self.pool.decl_count():
        if self.had_error != 0:
            break
        self.sync_decl_context(i)
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NodeKind.NK_FN_DECL:
            if self.current_decl_is_imported_module_symbol():
                continue
            let name_sym = self.pool.get_data0(decl)
            if name_sym == 0:
                continue
            let flags = self.pool.get_data2(decl)
            let meta = self.pool.find_fn_meta(decl)
            if meta >= 0:
                let tp_count = self.pool.fn_meta_tp_count(meta)
                if tp_count == 0 and not self.sema.generic_fn_nodes.contains(name_sym):
                    self.gen_function_dispatch(decl)

    if self.had_error != 0:
        return 1

    self.emit_module_runtime_init_helpers()
    if self.had_error != 0:
        return 1

    // Wrap main for exit
    self.wrap_main_for_exit()

    // Finalize debug info before verification
    self.debug_finalize_module()

    // Verify
    self.verify()

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

    for i in 0..self.module_runtime_init_fns.len() as i32:
        let init_fn = self.module_runtime_init_fns.get(i as i64)
        let init_ty = self.module_runtime_init_types.get(i as i64)
        let init_global = self.module_runtime_init_globals.get(i as i64)
        if init_fn == 0 or init_ty == 0 or init_global == 0:
            continue
        let init_ft = wl_global_get_value_type(init_fn)
        let init_value = wl_build_call(self.builder, init_ft, init_fn, 0, 0)
        wl_build_store(self.builder, init_value, init_global)

    let main_call = wl_build_call(self.builder, main_ft, main_fn, 0, 0)

    // Drain pending fibers after main returns
    var runtime_run_fn = wl_get_named_function(self.llmod, "with_runtime_run")
    if runtime_run_fn == 0:
        let runtime_run_ft_new = wl_function_type(wl_void_type(self.context), 0, 0, 0)
        runtime_run_fn = wl_add_function(self.llmod, "with_runtime_run", runtime_run_ft_new)
    let runtime_run_ft = wl_global_get_value_type(runtime_run_fn)
    wl_build_call(self.builder, runtime_run_ft, runtime_run_fn, 0, 0)

    var runtime_shutdown_fn = wl_get_named_function(self.llmod, "with_runtime_shutdown")
    if runtime_shutdown_fn == 0:
        let runtime_shutdown_ft_new = wl_function_type(wl_void_type(self.context), 0, 0, 0)
        runtime_shutdown_fn = wl_add_function(self.llmod, "with_runtime_shutdown", runtime_shutdown_ft_new)
    let runtime_shutdown_ft = wl_global_get_value_type(runtime_shutdown_fn)
    wl_build_call(self.builder, runtime_shutdown_ft, runtime_shutdown_fn, 0, 0)

    // For void or async main, return 0.
    // Async main's spawn wrapper returns fiber_id (i32), not a meaningful exit code.
    let main_sym = self.intern.intern("main")
    let main_is_async = self.sema.task_fns.contains(main_sym)
    if ret_ty == wl_void_type(self.context) or wl_get_type_kind(ret_ty) == wl_struct_type_kind() or main_is_async:
        let _ = wl_build_ret(self.builder, wl_const_int(i32_ty, 0, 0))
        return

    let exit_val =
        if ret_ty == i32_ty:
            main_call
        else:
            self.coerce_int(main_call, i32_ty)
    let _ = wl_build_ret(self.builder, exit_val)
