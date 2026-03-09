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
extern fn wl_get_first_function(m: i64) -> i64
extern fn wl_get_next_function(v: i64) -> i64
extern fn wl_is_declaration(v: i64) -> i32
extern fn wl_add_fn_attr(ctx: i64, f: i64, attr_name: str) -> void

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
extern fn wl_build_fp_to_si(b: i64, v: i64, ty: i64) -> i64
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
extern fn wl_print_ir(m: i64) -> void

// Vec data pointer
extern fn wl_vec_data_ptr(v: &Vec[i64]) -> i64

// Entry alloca helper
extern fn wl_create_entry_alloca(builder: i64, f: i64, ty: i64) -> i64

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

    // Enum types: sym → index into enum_* arrays
    enum_type_map: HashMap[i32, i32],
    enum_llvm_types: Vec[i64],
    enum_variant_starts: Vec[i32],
    enum_variant_counts: Vec[i32],
    enum_variant_names: Vec[i32],
    enum_variant_payloads: Vec[i64],

    // Enum by LLVM type (for match lookups)
    enum_by_llvm: HashMap[i64, i32],

    // Generic functions/structs: sym → node
    generic_fns: HashMap[i32, i32],
    generic_structs: HashMap[i32, i32],

    // Monomorphization cache: mangled_hash → value/type
    mono_values: HashMap[i64, i64],
    mono_types: HashMap[i64, i64],

    // Type aliases: sym → LLVM type
    type_aliases: HashMap[i32, i64],

    // Module constants: sym → LLVM global
    module_constants: HashMap[i32, i64],

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

    // VTable globals: hash(type,trait) → global
    vtable_globals: HashMap[i64, i64],

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
    task_locals: HashMap[i32, i32],
    uses_async: bool,

    // Scope locals for drop
    scope_local_syms: Vec[i32],
    scope_local_allocas: Vec[i64],
    scope_local_types: Vec[i64],
    scope_local_count: i32,

    // Error messages
    comptime_error_msg: str,
    codegen_error_detail: str,
    had_error: i32,

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
    vec_cache_map: HashMap[i64, i32],
    vec_llvm_types: Vec[i64],
    vec_elem_types: Vec[i64],
    vec_local_types: HashMap[i32, i64],

    // HashMap type cache
    hm_cache_map: HashMap[i64, i32],
    hm_llvm_types: Vec[i64],
    hm_key_types: Vec[i64],
    hm_val_types: Vec[i64],
    hm_is_str_keys: Vec[i32],
    hm_local_types: HashMap[i32, i32],

    // HashSet type cache
    hs_cache_map: HashMap[i64, i32],
    hs_llvm_types: Vec[i64],
    hs_elem_types: Vec[i64],

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

    // Wave 10 MIR backend input (optional).
    mir_input_enabled: i32,
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

fn Codegen.init_with_opt_and_intern(module_name: str, opt_level: i32, intern: InternPool) -> Codegen:
    var cg = Codegen.init_with_opt(module_name, opt_level)
    cg.intern = intern
    cg

fn Codegen.init_with_opt(module_name: str, opt_level: i32) -> Codegen:
    with_eprintln("[codegen] NK_TYPE_GENERIC() = " ++ int_to_string(NK_TYPE_GENERIC()))
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
        current_ret_type: 0,
        current_function: 0,
        current_function_name_sym: 0,
        current_method_owner_sym: 0,
        local_allocas: HashMap.new(),
        local_types: HashMap.new(),
        local_muts: HashMap.new(),
        local_fn_sigs: HashMap.new(),
        local_pointee_structs: HashMap.new(),
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
        enum_type_map: HashMap.new(),
        enum_llvm_types: Vec.new(),
        enum_variant_starts: Vec.new(),
        enum_variant_counts: Vec.new(),
        enum_variant_names: Vec.new(),
        enum_variant_payloads: Vec.new(),
        enum_by_llvm: HashMap.new(),
        generic_fns: HashMap.new(),
        generic_structs: HashMap.new(),
        mono_values: HashMap.new(),
        mono_types: HashMap.new(),
        type_aliases: HashMap.new(),
        module_constants: HashMap.new(),
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
        task_locals: HashMap.new(),
        uses_async: false,
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
        vec_llvm_types: Vec.new(),
        vec_elem_types: Vec.new(),
        vec_local_types: HashMap.new(),
        hm_cache_map: HashMap.new(),
        hm_llvm_types: Vec.new(),
        hm_key_types: Vec.new(),
        hm_val_types: Vec.new(),
        hm_is_str_keys: Vec.new(),
        hm_local_types: HashMap.new(),
        hs_cache_map: HashMap.new(),
        hs_llvm_types: Vec.new(),
        hs_elem_types: Vec.new(),
        type_binding_syms: Vec.new(),
        type_binding_types: Vec.new(),
        type_bindings_len: 0,
        fn_default_starts: HashMap.new(),
        fn_default_counts: HashMap.new(),
        source_file: "<unknown>",
        source_text: "",
        mir_input_enabled: 0,
        mir_input: MirModule.init(),
        mir_local_ptrs: HashMap.new(),
        mir_local_types: HashMap.new(),
        mir_bb_values: Vec.new(),
        mir_default_unreachable_bbs: Vec.new(),
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

fn Codegen.abi_size_of(self: Codegen, ty: i64) -> i64:
    if ty == 0:
        self.had_error = 1
        return 0
    let dl = wl_get_module_data_layout(self.llmod)
    if dl == 0:
        self.had_error = 1
        return 0
    wl_abi_size_of(dl, ty)

fn Codegen.abi_align_of(self: Codegen, ty: i64) -> i32:
    if ty == 0:
        self.had_error = 1
        return 1
    let dl = wl_get_module_data_layout(self.llmod)
    if dl == 0:
        self.had_error = 1
        return 1
    wl_abi_align_of(dl, ty)

fn Codegen.gen_module_from_mir(self: Codegen, mir_mod: MirModule, pool: AstPool) -> i32:
    let mir_err = validate_mir_module(mir_mod)
    if mir_err.len() > 0:
        with_eprintln("error: invalid MIR input for LLVM backend: " ++ mir_err)
        self.had_error = 1
        return 1
    self.mir_input = mir_mod
    self.mir_input_enabled = 1
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
    if tk == NK_TYPE_TRAIT_OBJ():
        return self.pool.get_data0(type_node)
    if tk == NK_TYPE_REF() or tk == NK_TYPE_PTR():
        return self.dyn_trait_from_type_node(self.pool.get_data0(type_node))
    if tk == NK_TYPE_GENERIC():
        let name_sym = self.pool.get_data0(type_node)
        let name = self.intern.resolve(name_sym)
        let g_extra = self.pool.get_data1(type_node)
        let g_count = self.pool.get_data2(type_node)
        if name == "Box" and g_count == 1:
            return self.dyn_trait_from_type_node(self.pool.get_extra(g_extra))
    0

fn codegen_hash_type_trait_key(type_sym: i32, trait_sym: i32) -> i64:
    (type_sym as i64) * 4294967296 + (trait_sym as i64)

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

    val

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
    var out = wl_get_undef(target_ty)
    for fi in 0..target_fields:
        let field_val = wl_build_extract_value(self.builder, val, fi)
        let field_ty = wl_struct_get_type_at(target_ty, fi)
        let coerced_field = if field_ty != 0: self.coerce_value_to_type(field_val, field_ty) else: field_val
        out = wl_build_insert_value(self.builder, out, coerced_field, fi)
    out

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
        if node_kind == NK_TYPE_NAMED() or node_kind == NK_TYPE_GENERIC():
            let type_name_sym = self.pool.get_data0(type_node)
            msg = msg ++ " type_name=" ++ self.intern.resolve(type_name_sym)
        if node_kind == NK_TYPE_GENERIC():
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

fn Codegen.record_local_container_type(self: Codegen, sym: i32, type_node: i32):
    let vec_elem_ty = self.type_node_vec_elem_type(type_node)
    if vec_elem_ty != 0:
        self.vec_local_types.insert(sym, vec_elem_ty)
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            self.vec_local_types.insert(canon, vec_elem_ty)
    let hm_idx = self.type_node_hashmap_cache_index(type_node)
    if hm_idx >= 0:
        self.hm_local_types.insert(sym, hm_idx)
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            self.hm_local_types.insert(canon, hm_idx)

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
    if arg_node != 0 and self.pool.kind(arg_node) == NK_IDENT():
        let sym = self.pool.get_data0(arg_node)
        let alloca = self.lookup_local_alloca(sym)
        if alloca != 0:
            return alloca

    if arg_node != 0 and self.pool.kind(arg_node) == NK_FIELD_ACCESS():
        let base = self.pool.get_data0(arg_node)
        let field = self.pool.get_data1(arg_node)
        let ptr = self.gen_field_access_ptr(base, field)
        if ptr != 0:
            return ptr

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

    if arg_node != 0 and self.pool.kind(arg_node) == NK_UNARY():
        let uop = self.pool.get_data0(arg_node)
        if uop == UOP_REF() or uop == UOP_MUT_REF():
            let inner = self.pool.get_data1(arg_node)
            if self.pool.kind(inner) == NK_IDENT():
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

    if arg_node != 0 and self.pool.kind(arg_node) == NK_IDENT():
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
        if dk == NK_TYPE_REF() or dk == NK_TYPE_PTR():
            let pointee = self.pool.get_data0(declared_type_node)
            if self.pool.kind(pointee) == NK_TYPE_NAMED():
                let sym = self.pool.get_data0(pointee)
                if self.intern.resolve(sym) == "Self" and self.current_method_owner_sym != 0:
                    return self.current_method_owner_sym
                if self.struct_type_map.get(sym).is_some():
                    return sym

    if value_node != 0 and self.pool.kind(value_node) == NK_UNARY():
        let uop = self.pool.get_data0(value_node)
        if uop == UOP_REF() or uop == UOP_MUT_REF():
            let inner = self.pool.get_data1(value_node)
            if self.pool.kind(inner) == NK_IDENT():
                let base_sym = self.pool.get_data0(inner)
                let ps = self.lookup_local_pointee_struct(base_sym)
                if ps != 0:
                    return ps
                let base_ty = self.lookup_local_type(base_sym)
                if base_ty != 0:
                    let st_sym = self.find_struct_type_by_llvm(base_ty)
                    if st_sym != 0:
                        return st_sym

    if value_node != 0 and self.pool.kind(value_node) == NK_IDENT():
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
    if vk == NK_STRUCT_LIT():
        let lit_sym = self.pool.get_data0(value_node)
        if lit_sym != 0:
            return lit_sym
    if vk == NK_IDENT():
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
    if vk == NK_UNARY():
        let uop = self.pool.get_data0(value_node)
        if uop == UOP_REF() or uop == UOP_MUT_REF():
            let inner = self.pool.get_data1(value_node)
            if self.pool.kind(inner) == NK_IDENT():
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
    if ok == OK_CONSTANT() and od >= 0 and od < body.const_kinds.len() as i32:
        if body.const_kinds.get(od as i64) == CK_FN():
            return out ++ self.function_symbol_name(body.const_d0.get(od as i64))
    if (ok == OK_COPY() or ok == OK_MOVE()) and od >= 0 and od < body.place_locals.len() as i32:
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
    if val == 0: return val
    let val_ty = wl_type_of(val)
    if val_ty == target_ty: return val
    let vk = wl_get_type_kind(val_ty)
    let tk = wl_get_type_kind(target_ty)
    if vk == wl_integer_type_kind() and tk == wl_integer_type_kind():
        let vw = wl_get_int_type_width(val_ty)
        let tw = wl_get_int_type_width(target_ty)
        if vw < tw:
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
    if op == OP_EQ():
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
        if op == OP_EQ():
            return wl_const_int(i1_ty, 1, 0)
        return wl_const_int(i1_ty, 0, 0)

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
    if op == OP_EQ():
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

    if kind == NK_TYPE_NAMED():
        let sym = self.pool.get_data0(type_node)
        return self.resolve_named_type(sym)

    if kind == NK_TYPE_PTR():
        // Check for dyn trait pointer
        let pointee = self.pool.get_data0(type_node)
        if self.pool.kind(pointee) == NK_TYPE_TRAIT_OBJ():
            // Fat pointer {data_ptr, vtable_ptr}
            return self.get_dyn_fat_ptr_type()
        return wl_ptr_type(self.context)

    if kind == NK_TYPE_REF():
        let pointee = self.pool.get_data0(type_node)
        if self.pool.kind(pointee) == NK_TYPE_TRAIT_OBJ():
            return self.get_dyn_fat_ptr_type()
        return wl_ptr_type(self.context)

    if kind == NK_TYPE_FN():
        // Function type → fat pointer {fn_ptr, ctx_ptr}
        let ptr_ty = wl_ptr_type(self.context)
        let fat_types: Vec[i64] = Vec.new()
        fat_types.push(ptr_ty)
        fat_types.push(ptr_ty)
        return wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)

    if kind == NK_TYPE_ARRAY():
        let elem_node = self.pool.get_data0(type_node)
        let size_lo = self.pool.get_data1(type_node)
        let elem_ty = self.resolve_type(elem_node)
        return wl_array_type(elem_ty, size_lo as i64)

    if kind == NK_TYPE_SLICE():
        let elem_node = self.pool.get_data0(type_node)
        self.resolve_type(elem_node)
        // Slice is {ptr, i64} like str
        let body_types: Vec[i64] = Vec.new()
        body_types.push(wl_ptr_type(self.context))
        body_types.push(wl_i64_type(self.context))
        return wl_struct_type(self.context, vec_data_i64(&body_types), 2, 0)

    if kind == NK_TYPE_OPTIONAL():
        let inner_node = self.pool.get_data0(type_node)
        let payload_ty = self.resolve_type(inner_node)
        let opt = self.get_or_create_option_type(payload_ty)
        return opt

    if kind == NK_TYPE_TUPLE():
        let extra_start = self.pool.get_data0(type_node)
        let elem_count = self.pool.get_data1(type_node)
        let elem_types: Vec[i64] = Vec.new()
        for i in 0..elem_count:
            let et_node = self.pool.get_extra(extra_start + i)
            elem_types.push(self.resolve_type(et_node))
        return wl_struct_type(self.context, vec_data_i64(&elem_types), elem_count, 0)

    if kind == NK_TYPE_GENERIC():
        let name_sym = self.pool.get_data0(type_node)
        let g_extra = self.pool.get_data1(type_node)
        let g_count = self.pool.get_data2(type_node)
        return self.resolve_generic_type(name_sym, g_extra, g_count)

    if kind == NK_TYPE_TRAIT_OBJ():
        // dyn Trait → fat pointer {data_ptr, vtable_ptr}
        return self.get_dyn_fat_ptr_type()

    if kind == NK_TYPE_INFERRED():
        return 0  // Cannot resolve inferred types

    // Fallback
    if self.debug_type_layout_enabled():
        var msg = "[type-resolve] fallback"
        msg = msg ++ " node=" ++ int_to_string(type_node)
        msg = msg ++ " kind=" ++ int_to_string(kind)
        msg = msg ++ " span=" ++ int_to_string(self.pool.get_start(type_node)) ++ ".." ++ int_to_string(self.pool.get_end(type_node))
        with_eprintln(msg)
    wl_i32_type(self.context)

fn Codegen.resolve_primitive_named_type(self: Codegen, name: str) -> i64:
    if name == "i32": return wl_i32_type(self.context)
    if name == "i64": return wl_i64_type(self.context)
    if name == "i16": return wl_i16_type(self.context)
    if name == "i8": return wl_i8_type(self.context)
    if name == "u8": return wl_i8_type(self.context)
    if name == "u16": return wl_i16_type(self.context)
    if name == "u32": return wl_i32_type(self.context)
    if name == "u64": return wl_i64_type(self.context)
    if name == "bool": return wl_i1_type(self.context)
    if name == "f64": return wl_f64_type(self.context)
    if name == "f32": return wl_f32_type(self.context)
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
    let prim = self.resolve_primitive_named_type(name)
    if prim != 0:
        return prim
    self.resolve_user_named_type(sym)

fn Codegen.resolve_generic_type(self: Codegen, name_sym: i32, extra_start: i32, arg_count: i32) -> i64:
    let name = self.intern.resolve(name_sym)
    if name == "Option" and arg_count == 1:
        let payload_node = self.pool.get_extra(extra_start)
        let payload_ty = self.resolve_type(payload_node)
        return self.get_or_create_option_type(payload_ty)
    if name == "Result" and arg_count == 2:
        let ok_node = self.pool.get_extra(extra_start)
        let err_node = self.pool.get_extra(extra_start + 1)
        let ok_ty = self.resolve_type(ok_node)
        let err_ty = self.resolve_type(err_node)
        return self.get_or_create_result_type(ok_ty, err_ty)
    if name == "Vec" and arg_count == 1:
        let elem_node = self.pool.get_extra(extra_start)
        let elem_ty = self.resolve_type(elem_node)
        // Keep std collections on the builtin runtime layout path.
        // Older self-host seeds miscompile monomorphized Vec field bodies,
        // which then poisons stage1/stage2 collection layouts.
        return self.get_or_create_vec_type(elem_ty)
    if name == "HashMap" and arg_count == 2:
        let key_node = self.pool.get_extra(extra_start)
        let val_node = self.pool.get_extra(extra_start + 1)
        let key_ty = self.resolve_type(key_node)
        let val_ty = self.resolve_type(val_node)
        return self.get_or_create_hashmap_type(key_ty, val_ty)
    if name == "HashSet" and arg_count == 1:
        let elem_node = self.pool.get_extra(extra_start)
        let elem_ty = self.resolve_type(elem_node)
        return self.get_or_create_hashset_type(elem_ty)
    if name == "Box" and arg_count == 1:
        let inner_node = self.pool.get_extra(extra_start)
        if self.pool.kind(inner_node) == NK_TYPE_TRAIT_OBJ():
            return self.get_dyn_fat_ptr_type()
        return wl_ptr_type(self.context)
    if name == "ContextError" and arg_count == 1:
        let src_node = self.pool.get_extra(extra_start)
        let src_ty = self.resolve_type(src_node)
        return self.get_or_create_context_error_type(src_ty)
    // Unknown generic - check if it's a monomorphizable struct
    let gs_opt = self.generic_structs.get(name_sym)
    if gs_opt.is_some():
        return self.monomorphize_struct(name_sym, extra_start, arg_count)
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
    if sub_kind == TDK_STRUCT():
        let field_count = self.pool.get_extra(extra_start)
        return extra_start + 1 + field_count * 3 + 1
    if sub_kind == TDK_ENUM():
        let variant_count = self.pool.get_extra(extra_start)
        var pos = extra_start + 1
        for vi in 0..variant_count:
            pos = pos + 1 // variant name
            let payload_count = self.pool.get_extra(pos)
            pos = pos + 1 + payload_count
        return pos + 1
    if sub_kind == TDK_ALIAS() or sub_kind == TDK_DISTINCT():
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
        return

    // Set struct body
    wl_struct_set_body(st_type, vec_data_i64(&ft_vec), field_count, 0)

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
            if v_payload_count == 1:
                let p_type_node = self.pool.get_extra(offset)
                payload_ty = self.resolve_type(p_type_node)
                if payload_ty == 0:
                    with_eprintln("error: unresolved payload type for enum variant '" ++ self.intern.resolve(v_name) ++ "' in '" ++ enum_name ++ "'")
                    self.had_error = 1
                    invalid_layout = 1
            else:
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
    if node == 0 or self.pool.kind(node) != NK_FIELD_ACCESS():
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

fn Codegen.static_receiver_text(self: Codegen, node: i32) -> str:
    if node == 0:
        return ""
    let kind = self.pool.kind(node)
    if kind == NK_IDENT():
        let sym = self.pool.get_data0(node)
        let name = self.intern.resolve(sym)
        if name.len() > 0:
            return name
        return self.ident_text_from_node(node)
    if kind == NK_TYPE_NAMED() or kind == NK_TYPE_GENERIC():
        return self.intern.resolve(self.pool.get_data0(node))
    ""

fn Codegen.static_receiver_type(self: Codegen, node: i32) -> i64:
    if node != 0:
        let kind = self.pool.kind(node)
        if kind == NK_TYPE_NAMED() or kind == NK_TYPE_GENERIC():
            let resolved = self.resolve_type(node)
            if resolved != 0:
                return resolved
    self.expected_type

fn Codegen.static_receiver_type_node(self: Codegen, node: i32) -> i32:
    if node != 0:
        let kind = self.pool.kind(node)
        if kind == NK_TYPE_NAMED() or kind == NK_TYPE_GENERIC():
            return node
    self.expected_type_node

fn Codegen.gen_builtin_vec_new(self: Codegen, vec_ty: i64, vec_type_node: i32) -> i64:
    var concrete_vec_ty = vec_ty
    var elem_ty: i64 = 0
    if vec_type_node != 0:
        elem_ty = self.type_node_vec_elem_type(vec_type_node)
        if elem_ty != 0:
            concrete_vec_ty = self.get_or_create_vec_type(elem_ty)
    if concrete_vec_ty == 0:
        return wl_get_undef(wl_i32_type(self.context))
    if elem_ty == 0:
        let cache_idx = self.find_vec_cache_index_by_llvm(concrete_vec_ty)
        if cache_idx < 0:
            return self.build_default_value(concrete_vec_ty)
        elem_ty = self.vec_elem_types.get(cache_idx as i64)
    let elem_size = self.abi_size_of(elem_ty)
    let alloca = self.create_entry_alloca(concrete_vec_ty)
    wl_build_store(self.builder, self.build_default_value(concrete_vec_ty), alloca)
    let new_fn = self.ensure_vec_runtime_fn("with_vec_new_out", wl_void_type(self.context), 2)
    let new_ty = self.get_vec_fn_type("with_vec_new_out", wl_void_type(self.context), 2)
    let args: Vec[i64] = Vec.new()
    args.push(alloca)
    args.push(wl_const_int(wl_i64_type(self.context), elem_size, 0))
    let _ = wl_build_call(self.builder, new_ty, new_fn, vec_data_i64(&args), 2)
    wl_build_load(self.builder, concrete_vec_ty, alloca)

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

fn Codegen.gen_builtin_hashmap_new(self: Codegen, hm_ty: i64, hm_type_node: i32) -> i64:
    var concrete_hm_ty = hm_ty
    var key_ty: i64 = 0
    var val_ty: i64 = 0
    if hm_type_node != 0 and self.pool.kind(hm_type_node) == NK_TYPE_GENERIC():
        let name_sym = self.pool.get_data0(hm_type_node)
        if self.intern.resolve(name_sym) == "HashMap":
            let extra_start = self.pool.get_data1(hm_type_node)
            let arg_count = self.pool.get_data2(hm_type_node)
            if arg_count == 2:
                key_ty = self.resolve_type(self.pool.get_extra(extra_start))
                val_ty = self.resolve_type(self.pool.get_extra(extra_start + 1))
                if key_ty != 0 and val_ty != 0:
                    concrete_hm_ty = self.get_or_create_hashmap_type(key_ty, val_ty)
    if concrete_hm_ty == 0:
        return wl_get_undef(wl_i32_type(self.context))
    if key_ty == 0 or val_ty == 0:
        let cache_idx = self.find_hashmap_cache_index_by_llvm(concrete_hm_ty)
        if cache_idx < 0:
            return self.build_default_value(concrete_hm_ty)
        key_ty = self.hm_key_types.get(cache_idx as i64)
        val_ty = self.hm_val_types.get(cache_idx as i64)
    let key_size = self.abi_size_of(key_ty)
    let val_size = self.abi_size_of(val_ty)
    let new_fn = self.ensure_hashmap_new_declared()
    let new_ty = self.get_hashmap_new_fn_type()
    let args: Vec[i64] = Vec.new()
    args.push(wl_const_int(wl_i64_type(self.context), key_size, 0))
    args.push(wl_const_int(wl_i64_type(self.context), val_size, 0))
    let handle = wl_build_call(self.builder, new_ty, new_fn, vec_data_i64(&args), 2)
    let empty = self.build_default_value(concrete_hm_ty)
    wl_build_insert_value(self.builder, empty, handle, 0)

fn Codegen.gen_builtin_static_call(self: Codegen, obj_node: i32, method_name: str, arg_count: i32) -> i64:
    if method_name != "new" or arg_count != 0:
        return 0
    let recv_name = self.static_receiver_text(obj_node)
    let recv_ty = self.static_receiver_type(obj_node)
    let recv_type_node = self.static_receiver_type_node(obj_node)
    if recv_name == "Vec":
        return self.gen_builtin_vec_new(recv_ty, recv_type_node)
    if recv_name == "HashMap":
        return self.gen_builtin_hashmap_new(recv_ty, recv_type_node)
    0

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

    // Resolve param types
    let param_types: Vec[i64] = Vec.new()

    // Check if method (has dot in name); for missing symbol text, infer owner
    // from `self: Type` in param 0.
    var method_owner_sym = 0
    for di in 0..name_str.len() as i32:
        if name_str.byte_at(di as i64) == 46:
            method_owner_sym = self.intern.intern(name_str.slice(0, di as i64))
            break

    var has_ref_param = false
    var pi = 0
    while pi < param_count:
        let p_name = self.pool.get_extra(param_start + pi * 2)
        let p_type_node = self.pool.get_extra(param_start + pi * 2 + 1)
        if p_type_node == 0:
            param_types.push(wl_i32_type(self.context))
            pi = pi + 1
            continue

        let p_kind = self.pool.kind(p_type_node)

        // Method self parameter: lower as pointer
        if pi == 0 and p_kind == NK_TYPE_NAMED():
            let p_sym = self.pool.get_data0(p_type_node)
            let p_type_name = self.intern.resolve(p_sym)
            let p_name_text = self.intern.resolve(p_name)
            if method_owner_sym == 0 and p_name_text == "self" and self.struct_type_map.get(p_sym).is_some():
                method_owner_sym = p_sym
            if method_owner_sym != 0 and (p_type_name == "Self" or p_sym == method_owner_sym):
                param_types.push(wl_ptr_type(self.context))
                has_ref_param = true
                // Record ref param
                self.record_ref_param(name_sym, pi, param_count)
                if alias_sym != 0:
                    self.record_ref_param(alias_sym, pi, param_count)
                pi = pi + 1
                continue

        // fn type params → fat pointer
        if p_kind == NK_TYPE_FN():
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
            pi = pi + 1
            continue

        // Reference params
        if p_kind == NK_TYPE_REF():
            var ref_ty = self.resolve_type(p_type_node)
            if ref_ty == 0:
                ref_ty = wl_ptr_type(self.context)
            param_types.push(ref_ty)
            has_ref_param = true
            self.record_ref_param(name_sym, pi, param_count)
            if alias_sym != 0:
                self.record_ref_param(alias_sym, pi, param_count)
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
    if (flags / FN_FLAG_ENTRY()) % 2 == 1:
        effective_name = "main"

    let function = wl_add_function(self.llmod, effective_name, fn_type)

    // Apply attributes
    if (flags / FN_FLAG_INLINE()) % 2 == 1:
        wl_add_fn_attr(self.context, function, "alwaysinline")
    if (flags / FN_FLAG_NOINLINE()) % 2 == 1:
        wl_add_fn_attr(self.context, function, "noinline")

    self.fn_values.insert(name_sym, function)
    self.fn_fn_types.insert(name_sym, fn_type)
    if alias_sym != 0:
        self.fn_values.insert(alias_sym, function)
        self.fn_fn_types.insert(alias_sym, fn_type)

fn Codegen.record_ref_param(self: Codegen, fn_sym: i32, idx: i32, count: i32):
    if not self.fn_ref_param_starts.get(fn_sym).is_some():
        let start = self.fn_ref_param_data.len() as i32
        self.fn_ref_param_starts.insert(fn_sym, start)
        for j in 0..count:
            self.fn_ref_param_data.push(0)
    let base = self.fn_ref_param_starts.get(fn_sym).unwrap()
    self.fn_ref_param_data.set_i32((base + idx) as i64, 1)

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
        let p_type_node = self.pool.get_extra(param_start + pi * 2 + 1)
        param_types.push(self.resolve_type(p_type_node))

    let fn_type = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count, is_variadic)

    let name_str = self.intern.resolve(name_sym)
    let link_name = self.canonical_extern_name(name_str)

    // Check if already declared
    let existing = wl_get_named_function(self.llmod, link_name)
    var function = existing
    if existing == 0:
        function = wl_add_function(self.llmod, link_name, fn_type)

    let actual_fn_type = wl_global_get_value_type(function)
    self.fn_values.insert(name_sym, function)
    self.fn_fn_types.insert(name_sym, actual_fn_type)

    // Also register canonical name if different
    if link_name != name_str:
        let canonical_sym = self.intern.intern(link_name)
        if not self.fn_values.get(canonical_sym).is_some():
            self.fn_values.insert(canonical_sym, function)
            self.fn_fn_types.insert(canonical_sym, actual_fn_type)

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
        if kind == NK_FN_DECL():
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
    if self.pool.kind(ret_node) != NK_TYPE_GENERIC(): return false
    let name_sym = self.pool.get_data0(ret_node)
    let arg_count = self.pool.get_data2(ret_node)
    if arg_count != 2: return false
    let name = self.intern.resolve(name_sym)
    name == "Result"

fn Codegen.result_err_symbol_from_return(self: Codegen, ret_node: i32) -> i32:
    if not self.is_result_return_type(ret_node): return 0
    let extra_start = self.pool.get_data1(ret_node)
    let err_node = self.pool.get_extra(extra_start + 1)
    if self.pool.kind(err_node) == NK_TYPE_NAMED():
        return self.pool.get_data0(err_node)
    0

fn Codegen.is_result_unit_return(self: Codegen, ret_node: i32) -> bool:
    if not self.is_result_return_type(ret_node): return false
    let extra_start = self.pool.get_data1(ret_node)
    let ok_node = self.pool.get_extra(extra_start)
    if self.pool.kind(ok_node) == NK_TYPE_NAMED():
        let ok_name = self.intern.resolve(self.pool.get_data0(ok_node))
        return ok_name == "Unit"
    false

// ── Option/Result type construction ───────────────────────────────

fn Codegen.get_or_create_option_type(self: Codegen, payload_ty: i64) -> i64:
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

fn Codegen.collection_wrapper_name_1(self: Codegen, prefix: str, t0: i64) -> str:
    prefix ++ "." ++ i64_to_string(t0)

fn Codegen.collection_wrapper_name_2(self: Codegen, prefix: str, t0: i64, t1: i64) -> str:
    prefix ++ "." ++ i64_to_string(t0) ++ "." ++ i64_to_string(t1)

fn Codegen.get_or_create_vec_type(self: Codegen, elem_ty: i64) -> i64:
    let cached = self.vec_cache_map.get(elem_ty)
    if cached.is_some():
        let idx = cached.unwrap()
        return self.vec_llvm_types.get(idx as i64)
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
        return self.vec_llvm_types.get(cached.unwrap() as i64)
    let idx = self.vec_llvm_types.len() as i32
    self.vec_llvm_types.push(vec_ty)
    self.vec_elem_types.push(elem_ty)
    self.vec_cache_map.insert(elem_ty, idx)
    vec_ty

fn Codegen.get_or_create_hashmap_type(self: Codegen, key_ty: i64, val_ty: i64) -> i64:
    let hash = key_ty * 65537 + val_ty
    let cached = self.hm_cache_map.get(hash)
    if cached.is_some():
        let idx = cached.unwrap()
        if idx >= 0 and idx < self.hm_llvm_types.len() as i32:
            if self.hm_key_types.get(idx as i64) == key_ty and self.hm_val_types.get(idx as i64) == val_ty:
                return self.hm_llvm_types.get(idx as i64)
    let exact_idx = self.find_hashmap_cache_index_by_parts(key_ty, val_ty)
    if exact_idx >= 0:
        self.hm_cache_map.insert(hash, exact_idx)
        return self.hm_llvm_types.get(exact_idx as i64)
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
        let idx = cached.unwrap()
        if idx >= 0 and idx < self.hm_llvm_types.len() as i32:
            if self.hm_key_types.get(idx as i64) == key_ty and self.hm_val_types.get(idx as i64) == val_ty:
                return self.hm_llvm_types.get(idx as i64)
    let exact_idx = self.find_hashmap_cache_index_by_parts(key_ty, val_ty)
    if exact_idx >= 0:
        self.hm_cache_map.insert(hash, exact_idx)
        return self.hm_llvm_types.get(exact_idx as i64)
    let idx = self.hm_llvm_types.len() as i32
    self.hm_llvm_types.push(hm_ty)
    self.hm_key_types.push(key_ty)
    self.hm_val_types.push(val_ty)
    // Check if str key
    let str_sym = self.intern.intern("str")
    let str_opt = self.struct_type_map.get(str_sym)
    var is_str = 0
    if str_opt.is_some():
        if key_ty == self.struct_llvm_types.get(str_opt.unwrap() as i64):
            is_str = 1
    self.hm_is_str_keys.push(is_str)
    self.hm_cache_map.insert(hash, idx)
    hm_ty

fn Codegen.get_or_create_hashset_type(self: Codegen, elem_ty: i64) -> i64:
    let cached = self.hs_cache_map.get(elem_ty)
    if cached.is_some():
        let idx = cached.unwrap()
        return self.hs_llvm_types.get(idx as i64)
    let body: Vec[i64] = Vec.new()
    body.push(wl_ptr_type(self.context))
    let name = self.collection_wrapper_name_1("__with.HashSet", elem_ty)
    let hs_ty = wl_struct_create_named(self.context, name)
    wl_struct_set_body(hs_ty, vec_data_i64(&body), 1, 0)
    self.cache_hashset_type(elem_ty, hs_ty)
    hs_ty

fn Codegen.cache_hashset_type(self: Codegen, elem_ty: i64, hs_ty: i64) -> i64:
    let cached = self.hs_cache_map.get(elem_ty)
    if cached.is_some():
        return self.hs_llvm_types.get(cached.unwrap() as i64)
    let idx = self.hs_llvm_types.len() as i32
    self.hs_llvm_types.push(hs_ty)
    self.hs_elem_types.push(elem_ty)
    self.hs_cache_map.insert(elem_ty, idx)
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

    if invalid_layout == 0:
        wl_struct_set_body(mono_ty, vec_data_i64(&ft_vec), field_count, 0)

    self.type_binding_syms = saved_bind_syms
    self.type_binding_types = saved_bind_tys
    self.type_bindings_len = saved_bind_len

    mono_ty

// ── Build Option Some/None ────────────────────────────────────────

fn Codegen.build_option_some(self: Codegen, payload: i64, opt_type: i64) -> i64:
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

fn Codegen.emit_defers(self: Codegen):
    var i = self.defer_stack.len() as i32 - 1
    while i >= 0:
        let defer_node = self.defer_stack.get(i as i64)
        self.gen_expr(defer_node)
        i = i - 1

// ── Build fn type from AST ────────────────────────────────────────

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

    // Declare built-in str type before user types
    self.declare_builtin_str_type()

    // Pass 0a: predeclare all struct/enum names so forward references resolve.
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind != NK_TYPE_DECL():
            continue
        let name_sym = self.pool.get_data0(decl)
        let name_str = self.intern.resolve(name_sym)
        if name_sym == 0 or name_str.len() == 0:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind == TDK_STRUCT():
            if self.type_decl_tp_count(decl) > 0:
                self.generic_structs.insert(name_sym, decl)
            else:
                self.predeclare_struct_type(name_sym)
            continue
        if sub_kind == TDK_ENUM():
            if self.type_decl_tp_count(decl) > 0:
                continue
            self.predeclare_enum_type(name_sym)

    // Pass 0b: define struct/enum bodies and type aliases.
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind != NK_TYPE_DECL():
            continue
        let name_sym = self.pool.get_data0(decl)
        let name_str = self.intern.resolve(name_sym)
        if name_sym == 0 or name_str.len() == 0:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind == TDK_STRUCT():
            if self.type_decl_tp_count(decl) == 0:
                self.declare_struct_type(name_sym, decl)
            continue
        if sub_kind == TDK_ENUM():
            if self.type_decl_tp_count(decl) > 0:
                continue
            self.declare_enum_type(name_sym, decl)
            continue
        if sub_kind == TDK_ALIAS():
            let extra_start = self.pool.get_data1(decl)
            let aliased_node = self.pool.get_extra(extra_start)
            let resolved = self.resolve_type(aliased_node)
            self.type_aliases.insert(name_sym, resolved)

    if self.had_error != 0:
        return 1

    // Pass 0.5: collect trait declarations
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NK_TRAIT_DECL():
            self.collect_trait_info(decl)

    // Pass 0.6: process top-level let declarations as module constants
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NK_LET_DECL():
            self.gen_module_constant(decl)

    // Pass 1: declare all functions and externs (forward declarations)
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NK_EXTERN_FN():
            self.declare_extern_fn(decl)
            continue
        if kind != NK_FN_DECL():
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
            else if (flags / FN_FLAG_ASYNC()) % 2 == 1:
                self.declare_function(decl)
            else:
                self.declare_function(decl)

    // Pass 1.3: synthesize missing impl methods from trait defaults.
    self.generate_default_trait_methods()

    // Pass 1.25: synthesize trait vtables after all method declarations exist.
    self.generate_trait_vtables()

    // Pass 1.5: detect drop functions
    self.detect_drop_functions()

    // Pass 2: generate function bodies
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NK_FN_DECL():
            let name_sym = self.pool.get_data0(decl)
            if name_sym == 0:
                continue
            let flags = self.pool.get_data2(decl)
            let meta = self.pool.find_fn_meta(decl)
            if meta >= 0:
                let tp_count = self.pool.fn_meta_tp_count(meta)
                if tp_count == 0:
                    self.gen_function_dispatch(decl)

    if self.had_error != 0:
        return 1

    // Wrap main for exit
    self.wrap_main_for_exit()

    // Verify
    self.verify()

// ── Collect trait info ────────────────────────────────────────────

fn Codegen.collect_trait_info(self: Codegen, trait_node: i32):
    let name_sym = self.pool.get_data0(trait_node)
    let extra_start = self.pool.get_data1(trait_node)
    if self.trait_map.get(name_sym).is_some():
        return

    var pos = extra_start
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
    let method_count = self.pool.get_extra(impl_extra)
    if method_count <= 0 or slot >= method_count:
        return 0
    let decl_idx = self.find_decl_index(impl_node)
    if decl_idx <= 0:
        return 0
    let rev_syms: Vec[i32] = Vec.new()
    var di = decl_idx - 1
    while di >= 0 and rev_syms.len() as i32 < method_count:
        let decl = self.pool.get_decl(di)
        if self.pool.kind(decl) == NK_FN_DECL():
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

    let resolved = self.resolve_type(type_node)
    self.type_binding_syms = saved_syms
    self.type_binding_types = saved_tys
    self.type_bindings_len = saved_len
    resolved

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
        let type_slot = param_start + pi * 2 + 1
        if type_slot < 0 or type_slot >= self.pool.extra_len():
            return
        let p_type_node = self.pool.get_extra(type_slot)
        if pi == 0 and p_type_node != 0 and self.pool.kind(p_type_node) == NK_TYPE_NAMED():
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
    let saved_vec_local_types = self.vec_local_types
    let saved_hm_local_types = self.hm_local_types
    let saved_enum_local_types = self.enum_local_types
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
    let fresh_vec_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_hm_local_types: HashMap[i32, i32] = HashMap.new()
    let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
    let fresh_scope_syms: Vec[i32] = Vec.new()
    let fresh_scope_allocas: Vec[i64] = Vec.new()
    let fresh_scope_types: Vec[i64] = Vec.new()
    let fresh_defer_stack: Vec[i32] = Vec.new()
    let fresh_tail_allocas: Vec[i64] = Vec.new()
    self.local_allocas = fresh_local_allocas
    self.local_types = fresh_local_types
    self.local_muts = fresh_local_muts
    self.local_fn_sigs = fresh_local_fn_sigs
    self.local_pointee_structs = fresh_local_pointees
    self.task_locals = fresh_task_locals
    self.trait_locals = fresh_trait_locals
    self.trait_local_concrete_types = fresh_trait_concrete
    self.vec_local_types = fresh_vec_local_types
    self.hm_local_types = fresh_hm_local_types
    self.enum_local_types = fresh_enum_local_types
    self.scope_local_syms = fresh_scope_syms
    self.scope_local_allocas = fresh_scope_allocas
    self.scope_local_types = fresh_scope_types
    self.scope_local_count = 0
    self.defer_stack = fresh_defer_stack
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
        let name_slot = param_start + pi * 2
        let type_slot = param_start + pi * 2 + 1
        if name_slot < 0 or type_slot < 0 or type_slot >= self.pool.extra_len():
            break
        let p_name = self.pool.get_extra(name_slot)
        let p_type_node = self.pool.get_extra(type_slot)
        let p_val = wl_get_param(function, pi)
        let p_ty = wl_type_of(p_val)
        let p_alloca = wl_build_alloca(self.builder, p_ty)
        wl_build_store(self.builder, p_val, p_alloca)
        self.record_local(p_name, p_alloca, p_ty, 1)
        self.record_local_container_type(p_name, p_type_node)
        if pi == 0 and wl_get_type_kind(p_ty) == wl_pointer_type_kind():
            self.record_local_pointee_struct(p_name, impl_type_sym)
        if pi == 0 and p_type_node != 0 and self.pool.kind(p_type_node) == NK_TYPE_NAMED():
            let psym = self.pool.get_data0(p_type_node)
            if self.intern.resolve(psym) == "Self" and wl_get_type_kind(p_ty) == wl_pointer_type_kind():
                self.record_local_pointee_struct(p_name, impl_type_sym)
        pi = pi + 1

    let body_val = self.gen_expr(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        if final_ret_ty == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
        else:
            let _ = wl_build_ret(self.builder, self.coerce_value_to_type(body_val, final_ret_ty))

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
    self.vec_local_types = saved_vec_local_types
    self.hm_local_types = saved_hm_local_types
    self.enum_local_types = saved_enum_local_types
    self.scope_local_syms = saved_scope_syms
    self.scope_local_allocas = saved_scope_allocas
    self.scope_local_types = saved_scope_types
    self.scope_local_count = saved_scope_count
    self.defer_stack = saved_defer
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
        self.generate_default_trait_method_for_impl(impl_type_sym, method_start + mi)

fn Codegen.generate_default_trait_methods(self: Codegen):
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        if self.pool.kind(decl) == NK_IMPL_DECL():
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
        if self.pool.kind(decl) == NK_IMPL_DECL():
            self.generate_trait_vtable_for_impl(decl)

fn Codegen.gen_known_concrete_dispatch(self: Codegen, fat_ptr: i64, concrete_sym: i32, method_sym: i32, args_start: i32, arg_count: i32, call_node: i32) -> i64:
    let type_name = self.intern.resolve(concrete_sym)
    let method_name = self.intern.resolve(method_sym)
    let mangled = type_name ++ "." ++ method_name
    let fn_sym = self.intern.intern(mangled)
    let fv = self.fn_values.get(fn_sym)
    let ft = self.fn_fn_types.get(fn_sym)
    if not fv.is_some() or not ft.is_some():
        return 0

    let fn_val = fv.unwrap() as i64
    if wl_count_params(fn_val) <= 0:
        return 0

    let data_ptr = wl_build_extract_value(self.builder, fat_ptr, 0)
    let self_param_ty = wl_type_of(wl_get_param(fn_val, 0))
    let self_arg = if wl_get_type_kind(self_param_ty) == wl_pointer_type_kind():
        wl_build_bitcast(self.builder, data_ptr, self_param_ty)
    else:
        wl_build_load(self.builder, self_param_ty, data_ptr)

    let call_args: Vec[i64] = Vec.new()
    call_args.push(self_arg)
    for ai in 0..arg_count:
        let arg_node = self.pool.get_extra(args_start + ai)
        call_args.push(self.gen_expr(arg_node))

    let coerced = self.coerce_call_args_for_fn_value(fn_sym, fn_val, args_start, 1, call_args, arg_count + 1, "dispatch " ++ mangled, call_node)
    wl_build_call(self.builder, ft.unwrap() as i64, fn_val, vec_data_i64(&coerced), arg_count + 1)

fn Codegen.gen_dyn_dispatch(self: Codegen, fat_ptr: i64, trait_sym: i32, method_sym: i32, args_start: i32, arg_count: i32) -> i64:
    let trait_idx_opt = self.trait_map.get(trait_sym)
    if not trait_idx_opt.is_some():
        return wl_get_undef(wl_i32_type(self.context))
    let trait_idx = trait_idx_opt.unwrap()
    let method_offset = self.find_trait_method_offset(trait_idx, method_sym)
    if method_offset < 0:
        return wl_get_undef(wl_i32_type(self.context))

    let method_start = self.trait_method_starts.get(trait_idx as i64)
    var method_ret_ty = self.trait_method_ret_types.get((method_start + method_offset) as i64)
    if method_ret_ty == 0:
        method_ret_ty = wl_i32_type(self.context)
    let vtable_ty = self.trait_vtable_types.get(trait_idx as i64)
    let data_ptr = wl_build_extract_value(self.builder, fat_ptr, 0)
    let vtable_ptr = wl_build_extract_value(self.builder, fat_ptr, 1)
    let fn_gep = wl_build_struct_gep(self.builder, vtable_ty, vtable_ptr, method_offset)
    let fn_ptr = wl_build_load(self.builder, wl_ptr_type(self.context), fn_gep)

    let call_args: Vec[i64] = Vec.new()
    call_args.push(data_ptr)
    for ai in 0..arg_count:
        let arg_node = self.pool.get_extra(args_start + ai)
        call_args.push(self.gen_expr(arg_node))

    let fn_param_types: Vec[i64] = Vec.new()
    fn_param_types.push(wl_ptr_type(self.context))
    for ai in 0..arg_count:
        var arg_ty = wl_type_of(call_args.get((ai + 1) as i64))
        if arg_ty == 0:
            arg_ty = wl_i32_type(self.context)
        fn_param_types.push(arg_ty)
    let call_ft = wl_function_type(method_ret_ty, vec_data_i64(&fn_param_types), arg_count + 1, 0)
    let is_null = wl_build_icmp(self.builder, wl_int_eq(), fn_ptr, wl_const_null(wl_ptr_type(self.context)))
    let call_bb = wl_append_bb(self.context, self.current_function, "dyn.call")
    let miss_bb = wl_append_bb(self.context, self.current_function, "dyn.missing")
    let merge_bb = wl_append_bb(self.context, self.current_function, "dyn.merge")
    wl_build_cond_br(self.builder, is_null, miss_bb, call_bb)

    wl_position_at_end(self.builder, call_bb)
    let call_val = wl_build_call(self.builder, call_ft, fn_ptr, vec_data_i64(&call_args), arg_count + 1)
    if wl_get_bb_terminator(call_bb) == 0:
        wl_build_br(self.builder, merge_bb)
    let call_end = wl_get_insert_block(self.builder)

    wl_position_at_end(self.builder, miss_bb)
    let miss_val = self.build_default_value(method_ret_ty)
    if wl_get_bb_terminator(miss_bb) == 0:
        wl_build_br(self.builder, merge_bb)
    let miss_end = wl_get_insert_block(self.builder)

    wl_position_at_end(self.builder, merge_bb)
    if method_ret_ty == wl_void_type(self.context):
        return wl_get_undef(wl_void_type(self.context))

    let phi = wl_build_phi(self.builder, method_ret_ty)
    let vals: Vec[i64] = Vec.new()
    let bbs: Vec[i64] = Vec.new()
    vals.push(call_val)
    vals.push(miss_val)
    bbs.push(call_end)
    bbs.push(miss_end)
    wl_add_incoming(phi, vec_data_i64(&vals), vec_data_i64(&bbs), 2)
    phi

// ── Generate module constant ──────────────────────────────────────

fn Codegen.gen_module_constant(self: Codegen, let_node: i32):
    let name_sym = self.pool.get_data0(let_node)
    let value_node = self.pool.get_data1(let_node)
    if value_node == 0: return

    // Only handle simple constants (int/float/bool/string literals)
    let vk = self.pool.kind(value_node)
    if vk == NK_INT_LIT():
        let val = self.pool.int_lit_value(value_node)
        let global_ty = if val < -2147483648 or val > 2147483647: wl_i64_type(self.context) else: wl_i32_type(self.context)
        let name_str = self.intern.resolve(name_sym)
        let global = wl_add_global(self.llmod, global_ty, name_str)
        wl_set_initializer(global, wl_const_int(global_ty, val, 1))
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

// ── gen_function_dispatch: MIR-first with conservative fallback ──

fn Codegen.gen_function_dispatch(self: Codegen, fn_node: i32):
    // MIR codegen disabled: MIR lowering produces incorrect code for struct
    // literals (zeroinitializer instead of field values) and possibly other
    // constructs.  AST codegen is reliable.  Re-enable MIR path once
    // MirLower is fixed.
    self.gen_function(fn_node)

fn Codegen.ast_contains_struct_lit(self: Codegen, node: i32) -> bool:
    if node == 0:
        return false
    let kind = self.pool.kind(node)
    if kind == NK_STRUCT_LIT() or kind == NK_RECORD_UPDATE() or kind == NK_ENUM_VARIANT() or kind == NK_VARIANT_SHORTHAND():
        return true
    // Recurse into sub-expressions
    if kind == NK_BLOCK():
        let stmts_start = self.pool.get_data0(node)
        let stmt_count = self.pool.get_data1(node)
        let result = self.pool.get_data2(node)
        for si in 0..stmt_count:
            if self.ast_contains_struct_lit(self.pool.get_extra(stmts_start + si)):
                return true
        return self.ast_contains_struct_lit(result)
    if kind == NK_LET_DECL() or kind == NK_LET_BINDING():
        return self.ast_contains_struct_lit(self.pool.get_data1(node))
    if kind == NK_IF_EXPR():
        if self.ast_contains_struct_lit(self.pool.get_data1(node)):
            return true
        return self.ast_contains_struct_lit(self.pool.get_data2(node))
    if kind == NK_RETURN():
        return self.ast_contains_struct_lit(self.pool.get_data0(node))
    if kind == NK_ASSIGN():
        return self.ast_contains_struct_lit(self.pool.get_data1(node))
    if kind == NK_CALL():
        let extra_start = self.pool.get_data1(node)
        let arg_count = self.pool.get_data2(node)
        for ai in 0..arg_count:
            if self.ast_contains_struct_lit(self.pool.get_extra(extra_start + ai)):
                return true
        return false
    if kind == NK_GROUPED():
        return self.ast_contains_struct_lit(self.pool.get_data0(node))
    if kind == NK_MATCH():
        let extra_start = self.pool.get_data1(node)
        let arm_count = self.pool.get_data2(node)
        for ai in 0..arm_count:
            let arm = self.pool.get_extra(extra_start + ai)
            if self.ast_contains_struct_lit(self.pool.get_data1(arm)):
                return true
            if self.ast_contains_struct_lit(self.pool.get_data2(arm)):
                return true
        return false
    if kind == NK_FOR():
        return self.ast_contains_struct_lit(self.pool.get_data2(node))
    if kind == NK_WHILE():
        return self.ast_contains_struct_lit(self.pool.get_data1(node))
    false

fn Codegen.mir_place_is_supported(self: Codegen, body: MirBody, place_id: i32) -> bool:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return false
    let p_count = body.place_proj_counts.get(place_id as i64)
    // Keep MIR lowering conservative until full typed place metadata is wired.
    p_count == 0

fn Codegen.mir_operand_is_supported(self: Codegen, body: MirBody, operand_id: i32, for_call_callee: bool) -> bool:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return false
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OK_COPY() or ok == OK_MOVE():
        return self.mir_place_is_supported(body, od)
    if ok == OK_CONSTANT():
        if od < 0 or od >= body.const_kinds.len() as i32:
            return false
        let ck = body.const_kinds.get(od as i64)
        if for_call_callee:
            // Current MIR lowering sometimes uses unit as a placeholder callee.
            if ck == CK_UNIT():
                return false
            return false
        return ck == CK_INT() or ck == CK_BOOL() or ck == CK_STR() or ck == CK_UNIT() or ck == CK_FLOAT() or ck == CK_ZERO_SIZED()
    false

fn Codegen.mir_function_is_supported(self: Codegen, body: MirBody) -> bool:
    if body.lowering_failed != 0:
        return false
    if body.block_count() <= 0:
        return false
    // Aggregate rvalues still rely on AST fallback until MIR backend support
    // is complete. Accepting them here can silently miscompile named struct
    // literals such as CLI option records.
    for ri in 0..body.rval_kinds.len() as i32:
        if body.rval_kinds.get(ri as i64) == RK_AGGREGATE():
            return false

    for si in 0..body.stmt_kinds.len() as i32:
        let sk = body.stmt_kinds.get(si as i64)
        let d0 = body.stmt_d0.get(si as i64)
        let d1 = body.stmt_d1.get(si as i64)
        if sk == SK_ASSIGN():
            if not self.mir_place_is_supported(body, d0):
                return false
            if d1 < 0 or d1 >= body.rval_kinds.len() as i32:
                return false
            let rk = body.rval_kinds.get(d1 as i64)
            if rk == RK_USE():
                if not self.mir_operand_is_supported(body, body.rval_d0.get(d1 as i64), false):
                    return false
                continue
            if rk == RK_BIN_OP():
                if not self.mir_operand_is_supported(body, body.rval_d1.get(d1 as i64), false):
                    return false
                if not self.mir_operand_is_supported(body, body.rval_d2.get(d1 as i64), false):
                    return false
                continue
            if rk == RK_UN_OP():
                if not self.mir_operand_is_supported(body, body.rval_d1.get(d1 as i64), false):
                    return false
                continue
            if rk == RK_REF() or rk == RK_ADDR_OF() or rk == RK_DISCRIMINANT() or rk == RK_LEN():
                var place = body.rval_d1.get(d1 as i64)
                if rk != RK_REF():
                    place = body.rval_d0.get(d1 as i64)
                if not self.mir_place_is_supported(body, place):
                    return false
                continue
            if rk == RK_CAST():
                if not self.mir_operand_is_supported(body, body.rval_d0.get(d1 as i64), false):
                    return false
                continue
            // Aggregate/downcast-sensitive forms still fall back to AST.
            return false
        if sk == SK_STORAGE_LIVE() or sk == SK_STORAGE_DEAD():
            continue
        if sk == SK_DROP():
            if not self.mir_place_is_supported(body, d0):
                return false
            continue
        if sk == SK_NOP():
            continue
        return false

    for bb in 0..body.bb_term_kinds.len() as i32:
        let tk = body.bb_term_kinds.get(bb as i64)
        let d0 = body.bb_term_d0.get(bb as i64)
        let d2 = body.bb_term_d2.get(bb as i64)
        if tk == TK_GOTO() or tk == TK_RETURN() or tk == TK_UNREACHABLE():
            continue
        if tk == TK_SWITCH_INT():
            if not self.mir_operand_is_supported(body, d0, false):
                return false
            continue
        if tk == TK_CALL():
            if not self.mir_operand_is_supported(body, d0, true):
                return false
            if not self.mir_place_is_supported(body, d2):
                return false
            continue
        if tk == TK_DROP_AND_GOTO():
            if not self.mir_place_is_supported(body, d0):
                return false
            continue
        return false

    true

fn Codegen.mir_get_or_create_local_ptr(self: Codegen, local_id: i32, ty: i64) -> i64:
    let existing = self.mir_local_ptrs.get(local_id)
    if existing.is_some():
        return existing.unwrap() as i64
    let alloc_ty = if ty != 0: ty else: wl_i32_type(self.context)
    let ptr = self.create_entry_alloca(alloc_ty)
    self.mir_local_ptrs.insert(local_id, ptr)
    ptr

fn Codegen.mir_pointee_type(self: Codegen, ptr: i64) -> i64:
    if ptr == 0:
        return 0
    let ptr_ty = wl_type_of(ptr)
    if wl_get_type_kind(ptr_ty) != wl_pointer_type_kind():
        return 0
    wl_get_element_type(ptr_ty)

fn Codegen.mir_resolve_field_index(self: Codegen, agg_ty: i64, field_token: i32) -> i32:
    if wl_get_type_kind(agg_ty) != wl_struct_type_kind():
        return 0 - 1
    let elem_count = wl_count_struct_elem_types(agg_ty)
    if field_token >= 0 and field_token < elem_count:
        return field_token

    let st_sym = self.find_struct_type_by_llvm(agg_ty)
    if st_sym != 0:
        let fi = self.find_field_index(st_sym, field_token)
        if fi >= 0 and fi < elem_count:
            return fi

    let field_name = self.intern.resolve(field_token)
    if field_name.len() == 1:
        let ch = field_name.byte_at(0)
        if ch >= 48 and ch <= 57:
            let idx = (ch - 48) as i32
            if idx >= 0 and idx < elem_count:
                return idx

    0 - 1

fn Codegen.mir_place_ptr(self: Codegen, body: MirBody, place_id: i32, create_base: bool, create_type: i64) -> i64:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0

    let base_local = body.place_locals.get(place_id as i64)
    let p_count = body.place_proj_counts.get(place_id as i64)
    if p_count != 0:
        return 0
    let base_opt = self.mir_local_ptrs.get(base_local)
    var cur_ptr: i64 = 0
    if base_opt.is_some():
        cur_ptr = base_opt.unwrap() as i64
    if cur_ptr == 0:
        if create_base:
            cur_ptr = self.mir_get_or_create_local_ptr(base_local, create_type)
            let alloc_ty = if create_type != 0: create_type else: wl_i32_type(self.context)
            self.mir_local_types.insert(base_local, alloc_ty)
        else:
            return 0

    cur_ptr

fn Codegen.mir_const_value(self: Codegen, body: MirBody, const_id: i32, expected_ty: i64) -> i64:
    let fallback_ty = if expected_ty != 0: expected_ty else: wl_i32_type(self.context)
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        return wl_get_undef(fallback_ty)

    let ck = body.const_kinds.get(const_id as i64)
    let cd = body.const_d0.get(const_id as i64)

    if ck == CK_INT():
        let int_value = mir_const_int_value(body, const_id)
        var int_ty = expected_ty
        if int_ty == 0 or wl_get_type_kind(int_ty) != wl_integer_type_kind():
            int_ty = if int_value < -2147483648 or int_value > 2147483647: wl_i64_type(self.context) else: wl_i32_type(self.context)
        return wl_const_int(int_ty, int_value, 1)

    if ck == CK_BOOL():
        return wl_const_int(wl_i1_type(self.context), cd as i64, 0)

    if ck == CK_STR():
        let text = if cd != 0: self.decode_string_escapes(self.intern.resolve(cd)) else: ""
        return self.gen_string_literal_raw(text)

    if ck == CK_UNIT():
        if expected_ty != 0 and expected_ty != wl_void_type(self.context):
            return self.build_default_value(expected_ty)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    if ck == CK_FLOAT():
        var float_ty = expected_ty
        if float_ty == 0:
            float_ty = wl_f64_type(self.context)
        let fk = wl_get_type_kind(float_ty)
        if fk != wl_float_type_kind() and fk != wl_double_type_kind():
            float_ty = wl_f64_type(self.context)
        return wl_const_real(float_ty, 0.0)

    if ck == CK_ZERO_SIZED():
        if expected_ty != 0:
            return self.build_default_value(expected_ty)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    wl_get_undef(fallback_ty)

fn Codegen.mir_eval_operand(self: Codegen, body: MirBody, operand_id: i32, expected_ty: i64) -> i64:
    let fallback_ty = if expected_ty != 0: expected_ty else: wl_i32_type(self.context)
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return wl_get_undef(fallback_ty)

    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OK_COPY() or ok == OK_MOVE():
        let ptr = self.mir_place_ptr(body, od, false, 0)
        if ptr == 0:
            return wl_get_undef(fallback_ty)
        if od < 0 or od >= body.place_locals.len() as i32:
            return wl_get_undef(fallback_ty)
        let local_id = body.place_locals.get(od as i64)
        let ptr_ty_opt = self.mir_local_types.get(local_id)
        if not ptr_ty_opt.is_some():
            return wl_get_undef(fallback_ty)
        let ptr_ty = ptr_ty_opt.unwrap() as i64
        let loaded = wl_build_load(self.builder, ptr_ty, ptr)
        if expected_ty != 0:
            return self.coerce_value_to_type(loaded, expected_ty)
        return loaded

    if ok == OK_CONSTANT():
        return self.mir_const_value(body, od, expected_ty)

    wl_get_undef(fallback_ty)

fn Codegen.mir_build_bin_op(self: Codegen, op: i32, lhs: i64, rhs: i64) -> i64:
    let lk = wl_get_type_kind(wl_type_of(lhs))
    let rk = wl_get_type_kind(wl_type_of(rhs))
    let is_float = lk == wl_float_type_kind() or lk == wl_double_type_kind() or rk == wl_float_type_kind() or rk == wl_double_type_kind()
    if is_float:
        if op == OP_ADD() or op == OP_ADD_WRAP(): return wl_build_fadd(self.builder, lhs, rhs)
        if op == OP_SUB() or op == OP_SUB_WRAP(): return wl_build_fsub(self.builder, lhs, rhs)
        if op == OP_MUL() or op == OP_MUL_WRAP(): return wl_build_fmul(self.builder, lhs, rhs)
        if op == OP_DIV(): return wl_build_fdiv(self.builder, lhs, rhs)
        if op == OP_MOD(): return wl_build_frem(self.builder, lhs, rhs)
        if op == OP_EQ(): return wl_build_fcmp(self.builder, wl_real_oeq(), lhs, rhs)
        if op == OP_NEQ(): return wl_build_fcmp(self.builder, wl_real_one(), lhs, rhs)
        if op == OP_LT(): return wl_build_fcmp(self.builder, wl_real_olt(), lhs, rhs)
        if op == OP_GT(): return wl_build_fcmp(self.builder, wl_real_ogt(), lhs, rhs)
        if op == OP_LTE(): return wl_build_fcmp(self.builder, wl_real_ole(), lhs, rhs)
        if op == OP_GTE(): return wl_build_fcmp(self.builder, wl_real_oge(), lhs, rhs)
        return wl_get_undef(wl_i32_type(self.context))

    if op == OP_EQ() or op == OP_NEQ():
        let lhs_ty = wl_type_of(lhs)
        let rhs_ty = wl_type_of(rhs)
        if lhs_ty == rhs_ty:
            let cmp_kind = wl_get_type_kind(lhs_ty)
            if cmp_kind == wl_struct_type_kind() or cmp_kind == wl_array_type_kind():
                return self.compare_aggregate_eq(lhs, rhs, op)

    let l = self.coerce_int(lhs, wl_type_of(rhs))
    let r = self.coerce_int(rhs, wl_type_of(l))
    if op == OP_ADD() or op == OP_ADD_WRAP(): return wl_build_add(self.builder, l, r)
    if op == OP_SUB() or op == OP_SUB_WRAP(): return wl_build_sub(self.builder, l, r)
    if op == OP_MUL() or op == OP_MUL_WRAP(): return wl_build_mul(self.builder, l, r)
    if op == OP_DIV(): return wl_build_sdiv(self.builder, l, r)
    if op == OP_MOD(): return wl_build_srem(self.builder, l, r)
    if op == OP_EQ(): return wl_build_icmp(self.builder, wl_int_eq(), l, r)
    if op == OP_NEQ(): return wl_build_icmp(self.builder, wl_int_ne(), l, r)
    if op == OP_LT(): return wl_build_icmp(self.builder, wl_int_slt(), l, r)
    if op == OP_GT(): return wl_build_icmp(self.builder, wl_int_sgt(), l, r)
    if op == OP_LTE(): return wl_build_icmp(self.builder, wl_int_sle(), l, r)
    if op == OP_GTE(): return wl_build_icmp(self.builder, wl_int_sge(), l, r)
    if op == OP_BIT_AND(): return wl_build_and(self.builder, l, r)
    if op == OP_BIT_OR(): return wl_build_or(self.builder, l, r)
    if op == OP_BIT_XOR(): return wl_build_xor(self.builder, l, r)
    if op == OP_SHL(): return wl_build_shl(self.builder, l, r)
    if op == OP_SHR(): return wl_build_ashr(self.builder, l, r)
    wl_get_undef(wl_i32_type(self.context))

fn Codegen.mir_eval_rvalue(self: Codegen, body: MirBody, rval_id: i32, dest_ty: i64) -> i64:
    let fallback_ty = if dest_ty != 0: dest_ty else: wl_i32_type(self.context)
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return wl_get_undef(fallback_ty)

    let rk = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)

    if rk == RK_USE():
        return self.mir_eval_operand(body, d0, dest_ty)

    if rk == RK_BIN_OP():
        let lhs = self.mir_eval_operand(body, d1, 0)
        let rhs = self.mir_eval_operand(body, d2, 0)
        let out = self.mir_build_bin_op(d0, lhs, rhs)
        if dest_ty != 0:
            return self.coerce_value_to_type(out, dest_ty)
        return out

    if rk == RK_UN_OP():
        let arg = self.mir_eval_operand(body, d1, dest_ty)
        if d0 == UOP_NEGATE():
            let ak = wl_get_type_kind(wl_type_of(arg))
            if ak == wl_float_type_kind() or ak == wl_double_type_kind():
                return wl_build_fneg(self.builder, arg)
            return wl_build_neg(self.builder, arg)
        if d0 == UOP_NOT():
            let ak = wl_get_type_kind(wl_type_of(arg))
            if ak == wl_integer_type_kind() and wl_get_int_type_width(wl_type_of(arg)) == 1:
                return wl_build_xor(self.builder, arg, wl_const_int(wl_i1_type(self.context), 1, 0))
            return wl_build_icmp(self.builder, wl_int_eq(), arg, wl_const_int(wl_type_of(arg), 0, 0))
        return arg

    if rk == RK_REF():
        let ptr = self.mir_place_ptr(body, d1, false, 0)
        if ptr == 0:
            return wl_get_undef(fallback_ty)
        if dest_ty != 0 and wl_type_of(ptr) != dest_ty and wl_get_type_kind(dest_ty) == wl_pointer_type_kind():
            return wl_build_bitcast(self.builder, ptr, dest_ty)
        return ptr

    if rk == RK_ADDR_OF():
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr == 0:
            return wl_get_undef(fallback_ty)
        if dest_ty != 0 and wl_type_of(ptr) != dest_ty and wl_get_type_kind(dest_ty) == wl_pointer_type_kind():
            return wl_build_bitcast(self.builder, ptr, dest_ty)
        return ptr

    if rk == RK_DISCRIMINANT():
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
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    if rk == RK_CAST():
        let val = self.mir_eval_operand(body, d0, 0)
        if dest_ty != 0:
            return self.coerce_value_to_type(val, dest_ty)
        return val

    if rk == RK_LEN():
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

    if sk == SK_ASSIGN():
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let dst_local = body.place_locals.get(d0 as i64)
        var dst_ptr = self.mir_place_ptr(body, d0, false, 0)
        var dst_ty: i64 = 0
        let dst_ty_opt = self.mir_local_types.get(dst_local)
        if dst_ptr != 0 and dst_ty_opt.is_some():
            dst_ty = dst_ty_opt.unwrap() as i64
        let value = self.mir_eval_rvalue(body, d1, dst_ty)
        if dst_ptr == 0:
            let proj_count = body.place_proj_counts.get(d0 as i64)
            if proj_count != 0:
                return false
            let value_ty = wl_type_of(value)
            dst_ptr = self.mir_get_or_create_local_ptr(dst_local, value_ty)
            self.mir_local_types.insert(dst_local, value_ty)
        var final_ty: i64 = 0
        let final_ty_opt = self.mir_local_types.get(dst_local)
        if final_ty_opt.is_some():
            final_ty = final_ty_opt.unwrap() as i64
        if final_ty == 0: return false
        var coerced = value
        if wl_type_of(value) != final_ty:
            coerced = self.coerce_value_to_type(value, final_ty)
        wl_build_store(self.builder, coerced, dst_ptr)
        return true

    if sk == SK_STORAGE_LIVE():
        // Storage markers do not require dedicated IR in this backend.
        return true

    if sk == SK_STORAGE_DEAD():
        return true

    if sk == SK_DROP():
        if d0 < 0 or d0 >= body.place_locals.len() as i32:
            return false
        let local_id = body.place_locals.get(d0 as i64)
        let ty_opt = self.mir_local_types.get(local_id)
        let ptr = self.mir_place_ptr(body, d0, false, 0)
        if ptr != 0:
            if ty_opt.is_some():
                self.mir_emit_drop_ptr(ptr, ty_opt.unwrap() as i64)
        return true

    if sk == SK_NOP():
        return true

    false

fn Codegen.mir_default_unreachable_bb_value(self: Codegen) -> i64:
    if self.mir_default_unreachable_bbs.len() as i32 > 0:
        return self.mir_default_unreachable_bbs.get(0)
    let bb = wl_append_bb(self.context, self.current_function, "mir.default.unreachable")
    self.mir_default_unreachable_bbs.push(bb)
    bb

fn Codegen.mir_eval_call_operand(self: Codegen, body: MirBody, operand_id: i32, expected_ty: i64, call_context: str, arg_index: i32) -> i64:
    if expected_ty != 0 and wl_get_type_kind(expected_ty) == wl_pointer_type_kind():
        if operand_id >= 0 and operand_id < body.operand_kinds.len() as i32:
            let ok = body.operand_kinds.get(operand_id as i64)
            let od = body.operand_d0.get(operand_id as i64)
            if (ok == OK_COPY() or ok == OK_MOVE()) and od >= 0 and od < body.place_locals.len() as i32:
                let local_id = body.place_locals.get(od as i64)
                let place_ty_opt = self.mir_local_types.get(local_id)
                let place_ptr = self.mir_place_ptr(body, od, false, 0)
                if place_ptr != 0:
                    if place_ty_opt.is_some():
                        let place_ty = place_ty_opt.unwrap() as i64
                        if wl_get_type_kind(place_ty) == wl_struct_type_kind():
                            let had_error_before = self.had_error
                            let coerced = self.enforce_coerced_type(place_ptr, expected_ty, "wrong argument type")
                            if self.had_error != had_error_before:
                                self.debug_call_coerce_failure(call_context, 0, arg_index, 0, place_ptr, expected_ty)
                            return coerced

    let val = self.mir_eval_operand(body, operand_id, expected_ty)
    let had_error_before = self.had_error
    let coerced = self.enforce_coerced_type(val, expected_ty, "wrong argument type")
    if self.had_error != had_error_before:
        self.debug_call_coerce_failure(call_context, 0, arg_index, 0, val, expected_ty)
    coerced

fn Codegen.mir_emit_call_term(self: Codegen, body: MirBody, callee_operand: i32, args_id: i32, dest_place: i32, next_bb: i32) -> bool:
    let callee = self.mir_eval_operand(body, callee_operand, 0)
    let call_context = self.mir_call_context(body, callee_operand)
    var call_ft: i64 = 0
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

    let args: Vec[i64] = Vec.new()
    for ai in 0..arg_count:
        let operand_id = body.call_arg_operands.get((arg_start + ai) as i64)
        var expected_ty: i64 = 0
        if ai < param_count:
            expected_ty = param_types.get(ai as i64)
        args.push(self.mir_eval_call_operand(body, operand_id, expected_ty, call_context, ai))

    let call_val = wl_build_call(self.builder, call_ft, callee, vec_data_i64(&args), arg_count)
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

    if tk == TK_GOTO():
        if d0 < 0 or d0 >= self.mir_bb_values.len() as i32:
            return false
        let target_bb = self.mir_bb_values.get(d0 as i64)
        wl_build_br(self.builder, target_bb)
        return true

    if tk == TK_RETURN():
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

    if tk == TK_UNREACHABLE():
        wl_build_unreachable(self.builder)
        return true

    if tk == TK_SWITCH_INT():
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

    if tk == TK_CALL():
        return self.mir_emit_call_term(body, d0, d1, d2, d3)

    if tk == TK_DROP_AND_GOTO():
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
        self.gen_function(fn_node)
        return
    let function = fv.unwrap() as i64
    let ft = self.fn_fn_types.get(name_sym)
    if not ft.is_some():
        self.gen_function(fn_node)
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
    let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_local_concrete_types: HashMap[i32, i32] = HashMap.new()
    let fresh_vec_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_hm_local_types: HashMap[i32, i32] = HashMap.new()
    let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
    self.local_allocas = fresh_local_allocas
    self.local_types = fresh_local_types
    self.local_muts = fresh_local_muts
    self.local_fn_sigs = fresh_local_fn_sigs
    self.local_pointee_structs = fresh_local_pointee_structs
    self.task_locals = fresh_task_locals
    self.defer_stack = fresh_defer_stack
    self.trait_locals = fresh_trait_locals
    self.trait_local_concrete_types = fresh_trait_local_concrete_types
    self.vec_local_types = fresh_vec_local_types
    self.hm_local_types = fresh_hm_local_types
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
        let p_name = self.pool.get_extra(param_start + pi * 2)
        let p_type_node = self.pool.get_extra(param_start + pi * 2 + 1)
        let param_val = wl_get_param(function, pi)
        let param_type = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_type)
        wl_build_store(self.builder, param_val, alloca)

        self.record_local(p_name, alloca, param_type, 1)
        self.record_local_container_type(p_name, p_type_node)
        self.mir_local_ptrs.insert(pi + 1, alloca)
        self.mir_local_types.insert(pi + 1, param_type)

        if p_type_node != 0:
            let pk = self.pool.kind(p_type_node)
            if pk == NK_TYPE_FN():
                let fn_sig = self.build_fn_type_from_ast(p_type_node)
                self.record_local_fn_sig(p_name, fn_sig)
            if pk == NK_TYPE_PTR() or pk == NK_TYPE_REF():
                let pointee_node = self.pool.get_data0(p_type_node)
                if self.pool.kind(pointee_node) == NK_TYPE_NAMED():
                    let ps = self.pool.get_data0(pointee_node)
                    if self.struct_type_map.get(ps).is_some():
                        self.record_local_pointee_struct(p_name, ps)
            if pi == 0 and pk == NK_TYPE_NAMED():
                let p_sym = self.pool.get_data0(p_type_node)
                let p_n = self.intern.resolve(p_sym)
                let p_name_text = self.intern.resolve(p_name)
                if method_owner_sym == 0 and p_name_text == "self" and self.struct_type_map.get(p_sym).is_some():
                    method_owner_sym = p_sym
                    self.current_method_owner_sym = method_owner_sym
                if method_owner_sym != 0 and (p_n == "Self" or p_sym == method_owner_sym):
                    self.record_local_pointee_struct(p_name, method_owner_sym)
            if pi == 0 and method_owner_sym != 0:
                let p_n = self.intern.resolve(p_name)
                if p_n == "self":
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
        if self.debug_mir_codegen_enabled():
            with_eprintln("[mir-cg] fn=" ++ name_str ++ " bb=" ++ int_to_string(bb) ++ " llbb=" ++ i64_to_string(llbb))
        wl_position_at_end(self.builder, llbb)
        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let stmt_count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            if not self.mir_emit_stmt(body, stmt_id):
                if self.debug_mir_codegen_enabled():
                    with_eprintln("[mir-cg] fn=" ++ name_str ++ " bb=" ++ int_to_string(bb) ++ " stmt_fail=" ++ int_to_string(stmt_id))
                if wl_get_bb_terminator(llbb) == 0:
                    wl_build_unreachable(self.builder)
                break
        if wl_get_bb_terminator(llbb) == 0:
            let ok = self.mir_emit_term(body, bb)
            if self.debug_mir_codegen_enabled():
                var ok_i = 0
                if ok:
                    ok_i = 1
                with_eprintln("[mir-cg] fn=" ++ name_str ++ " bb=" ++ int_to_string(bb) ++ " term_ok=" ++ int_to_string(ok_i))
            if not ok and wl_get_bb_terminator(llbb) == 0:
                wl_build_unreachable(self.builder)

    if self.mir_default_unreachable_bbs.len() as i32 > 0:
        let ubb = self.mir_default_unreachable_bbs.get(0)
        if wl_get_bb_terminator(ubb) == 0:
            wl_position_at_end(self.builder, ubb)
            wl_build_unreachable(self.builder)

    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    self.current_result_err_symbol = saved_result_err
    self.current_fn_returns_result = saved_returns_result
    self.current_fn_saw_explicit_return = saved_saw_return
    self.tailrec_body_bb = saved_tailrec_bb
    self.tailrec_fn_sym = saved_tailrec_sym

// ── gen_function: generate a function body ────────────────────────

fn Codegen.gen_function(self: Codegen, fn_node: i32):
    let name_sym = self.pool.get_data0(fn_node)
    let resolved_name = self.intern.resolve(name_sym)
    let name_str = if resolved_name.len() > 0: resolved_name else: self.fn_decl_name_from_node(fn_node)
    if name_sym == 0:
        return
    let body_node = self.pool.get_data1(fn_node)
    let flags = self.pool.get_data2(fn_node)

    let fv = self.fn_values.get(name_sym)
    if not fv.is_some(): return
    let function = fv.unwrap() as i64
    let ft = self.fn_fn_types.get(name_sym)
    if not ft.is_some(): return
    let fn_type = ft.unwrap() as i64

    self.current_function = function
    self.current_function_name_sym = name_sym
    self.current_ret_type = wl_get_return_type(fn_type)
    self.current_method_owner_sym = 0

    // Clear locals
    let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
    let fresh_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
    let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
    let fresh_local_pointee_structs: HashMap[i32, i32] = HashMap.new()
    let fresh_task_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_vec_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_hm_local_types: HashMap[i32, i32] = HashMap.new()
    let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
    self.local_allocas = fresh_local_allocas
    self.local_types = fresh_local_types
    self.local_muts = fresh_local_muts
    self.local_fn_sigs = fresh_local_fn_sigs
    self.local_pointee_structs = fresh_local_pointee_structs
    self.task_locals = fresh_task_locals
    self.vec_local_types = fresh_vec_local_types
    self.hm_local_types = fresh_hm_local_types
    self.enum_local_types = fresh_enum_local_types
    self.scope_local_count = 0
    let fresh_defer_stack: Vec[i32] = Vec.new()
    let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_local_concrete_types: HashMap[i32, i32] = HashMap.new()
    self.defer_stack = fresh_defer_stack
    self.trait_locals = fresh_trait_locals
    self.trait_local_concrete_types = fresh_trait_local_concrete_types

    // Save/set expected type
    let saved_expected = self.expected_type
    let saved_expected_node = self.expected_type_node
    self.expected_type = self.current_ret_type
    self.expected_type_node = 0
    let saved_result_err = self.current_result_err_symbol
    let saved_returns_result = self.current_fn_returns_result
    let saved_saw_return = self.current_fn_saw_explicit_return
    self.current_result_err_symbol = 0
    let rerr = self.fn_result_err_symbols.get(name_sym)
    if rerr.is_some(): self.current_result_err_symbol = rerr.unwrap()
    self.current_fn_returns_result = self.fn_returns_result.get(name_sym).is_some()
    self.current_fn_saw_explicit_return = false

    // Save tailrec state
    let saved_tailrec_bb = self.tailrec_body_bb
    let saved_tailrec_sym = self.tailrec_fn_sym
    let saved_loops = self.capture_loop_state()
    self.tailrec_body_bb = 0
    self.tailrec_fn_sym = 0
    self.reset_loop_state()

    // Create entry block
    let entry = wl_append_bb(self.context, function, "entry")
    wl_position_at_end(self.builder, entry)

    // Add parameters as locals
    let meta = self.pool.find_fn_meta(fn_node)
    if meta < 0: return
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)

    // Detect method owner
    var method_owner_sym = 0
    for di in 0..name_str.len() as i32:
        if name_str.byte_at(di as i64) == 46:
            method_owner_sym = self.intern.intern(name_str.slice(0, di as i64))
            break
    self.current_method_owner_sym = method_owner_sym

    for pi in 0..param_count:
        let p_name = self.pool.get_extra(param_start + pi * 2)
        let p_type_node = self.pool.get_extra(param_start + pi * 2 + 1)
        let param_val = wl_get_param(function, pi)
        let param_type = wl_type_of(param_val)
        let alloca = wl_build_alloca(self.builder, param_type)
        wl_build_store(self.builder, param_val, alloca)

        self.record_local(p_name, alloca, param_type, 1)  // treat all as mutable for codegen
        self.record_local_container_type(p_name, p_type_node)

        // Track fn_sig for function pointer params
        if p_type_node != 0:
            let pk = self.pool.kind(p_type_node)
            if pk == NK_TYPE_FN():
                let fn_sig = self.build_fn_type_from_ast(p_type_node)
                self.record_local_fn_sig(p_name, fn_sig)
            // Track pointee struct for pointer/ref params
            if pk == NK_TYPE_PTR() or pk == NK_TYPE_REF():
                let pointee_node = self.pool.get_data0(p_type_node)
                if self.pool.kind(pointee_node) == NK_TYPE_NAMED():
                    let ps = self.pool.get_data0(pointee_node)
                    if self.struct_type_map.get(ps).is_some():
                        self.record_local_pointee_struct(p_name, ps)
            // Track method self pointee
            if pi == 0 and pk == NK_TYPE_NAMED():
                let p_sym = self.pool.get_data0(p_type_node)
                let p_n = self.intern.resolve(p_sym)
                let p_name_text = self.intern.resolve(p_name)
                if method_owner_sym == 0 and p_name_text == "self" and self.struct_type_map.get(p_sym).is_some():
                    method_owner_sym = p_sym
                    self.current_method_owner_sym = method_owner_sym
                if method_owner_sym != 0 and (p_n == "Self" or p_sym == method_owner_sym):
                    self.record_local_pointee_struct(p_name, method_owner_sym)
            if pi == 0 and method_owner_sym != 0:
                let p_n = self.intern.resolve(p_name)
                if p_n == "self":
                    self.record_local_pointee_struct(p_name, method_owner_sym)
            // Track dyn trait params (plain/wrapped forms).
            let trait_sym = self.dyn_trait_from_type_node(p_type_node)
            if trait_sym != 0:
                self.record_trait_local(p_name, trait_sym)

    // @[tailrec]: create body BB
    if (flags / FN_FLAG_TAILREC()) % 2 == 1 and param_count > 0:
        let body_bb = wl_append_bb(self.context, function, "tailrec.body")
        wl_build_br(self.builder, body_bb)
        wl_position_at_end(self.builder, body_bb)
        self.tailrec_body_bb = body_bb
        self.tailrec_fn_sym = name_sym
        // Collect param allocas
        let fresh_tailrec_param_allocas: Vec[i64] = Vec.new()
        self.tailrec_param_allocas = fresh_tailrec_param_allocas
        for ti in 0..param_count:
            let tp_name = self.pool.get_extra(param_start + ti * 2)
            let ta = self.local_allocas.get(tp_name)
            if ta.is_some():
                self.tailrec_param_allocas.push(ta.unwrap() as i64)
            else:
                self.tailrec_param_allocas.push(0)

    // Generate body
    let body_val = self.gen_expr(body_node)

    // Emit implicit return if block has no terminator
    let current_bb = wl_get_insert_block(self.builder)
    if wl_get_bb_terminator(current_bb) == 0:
        let ret_type = self.current_ret_type
        let is_void = ret_type == wl_void_type(self.context)
        self.emit_drops(0)
        self.emit_defers()
        if not is_void:
            let body_type = wl_type_of(body_val)
            if body_type == wl_void_type(self.context):
                if self.current_fn_returns_result:
                    if self.fn_result_unit_returns.get(name_sym).is_some():
                        let unit_val = wl_const_int(wl_i32_type(self.context), 0, 0)
                        let wrapped = self.build_result_ok(unit_val, ret_type)
                        let _ = wl_build_ret(self.builder, wrapped)
                    else:
                        self.emit_implicit_unreachable(fn_node)
                else:
                    if self.current_fn_saw_explicit_return:
                        self.emit_implicit_unreachable(fn_node)
                    else:
                        let default_val = self.build_default_value(ret_type)
                        let _ = wl_build_ret(self.builder, default_val)
            else if body_type != ret_type and self.current_fn_returns_result:
                let wrapped = self.build_result_ok(body_val, ret_type)
                let _ = wl_build_ret(self.builder, wrapped)
            else:
                let coerced = self.coerce_value_to_type(body_val, ret_type)
                let _ = wl_build_ret(self.builder, coerced)
        else:
            let _ = wl_build_ret_void(self.builder)

    // Restore state
    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    self.current_result_err_symbol = saved_result_err
    self.current_fn_returns_result = saved_returns_result
    self.current_fn_saw_explicit_return = saved_saw_return
    self.tailrec_body_bb = saved_tailrec_bb
    self.tailrec_fn_sym = saved_tailrec_sym
    self.restore_loop_state(saved_loops)

// ── gen_expr: top-level expression dispatch ───────────────────────

fn Codegen.gen_expr(self: Codegen, node: i32) -> i64:
    if node == 0: return wl_get_undef(wl_void_type(self.context))
    let kind = self.pool.kind(node)

    if kind == NK_INT_LIT(): return self.gen_int_lit(node)
    if kind == NK_FLOAT_LIT(): return self.gen_float_lit(node)
    if kind == NK_BOOL_LIT(): return self.gen_bool_lit(node)
    if kind == NK_STRING_LIT(): return self.gen_string_lit(node)
    if kind == NK_C_STRING_LIT(): return self.gen_c_string_lit(node)
    if kind == NK_IDENT(): return self.gen_ident_expr(node)
    if kind == NK_BINARY(): return self.gen_binary(node)
    if kind == NK_UNARY(): return self.gen_unary(node)
    if kind == NK_GROUPED(): return self.gen_expr(self.pool.get_data0(node))
    if kind == NK_BLOCK(): return self.gen_block(node)
    if kind == NK_LET_BINDING(): return self.gen_let_binding(node)
    if kind == NK_LET_ELSE(): return self.gen_let_else(node)
    if kind == NK_IF_EXPR(): return self.gen_if_expr(node)
    if kind == NK_CALL(): return self.gen_call(node)
    if kind == NK_RETURN(): return self.gen_return(node)
    if kind == NK_ASSIGN(): return self.gen_assign(node)
    if kind == NK_WHILE(): return self.gen_while(node)
    if kind == NK_LOOP(): return self.gen_loop(node)
    if kind == NK_FOR(): return self.gen_for(node)
    if kind == NK_BREAK(): return self.gen_break(node)
    if kind == NK_CONTINUE(): return self.gen_continue(node)
    if kind == NK_FIELD_ACCESS(): return self.gen_field_access(node)
    if kind == NK_INDEX(): return self.gen_index(node)
    if kind == NK_SLICE(): return self.gen_slice(node)
    if kind == NK_ARRAY_LIT(): return self.gen_array_lit(node)
    if kind == NK_STRUCT_LIT(): return self.gen_struct_lit(node)
    if kind == NK_MATCH(): return self.gen_match(node)
    if kind == NK_ENUM_VARIANT(): return self.gen_enum_variant(node)
    if kind == NK_VARIANT_SHORTHAND(): return self.gen_variant_shorthand(node)
    if kind == NK_CLOSURE(): return self.gen_closure(node)
    if kind == NK_CAST(): return self.gen_cast(node)
    if kind == NK_PIPELINE(): return self.gen_pipeline(node)
    if kind == NK_TUPLE(): return self.gen_tuple(node)
    if kind == NK_TUPLE_DESTRUCTURE(): return self.gen_tuple_destructure(node)
    if kind == NK_WITH_EXPR(): return self.gen_with_expr(node)
    if kind == NK_RECORD_UPDATE(): return self.gen_record_update(node)
    if kind == NK_RANGE(): return self.gen_range(node)
    if kind == NK_OPTIONAL_CHAIN(): return self.gen_optional_chain(node)
    if kind == NK_DEFER():
        let body = self.pool.get_data0(node)
        self.defer_stack.push(body)
        return wl_get_undef(wl_void_type(self.context))
    if kind == NK_ASYNC_BLOCK(): return self.gen_async_block(node)
    if kind == NK_ASYNC_SCOPE(): return self.gen_async_scope(node)
    if kind == NK_SELECT_AWAIT(): return self.gen_select_await(node)
    if kind == NK_YIELD(): return self.gen_yield(node)
    if kind == NK_AWAIT(): return self.gen_await(node)
    if kind == NK_SPAWN(): return self.gen_spawn(node)
    if kind == NK_COMPTIME(): return self.gen_comptime(node)
    if kind == NK_ARRAY_COMPREHENSION(): return self.gen_array_comprehension(node)

    // Unsupported
    wl_get_undef(wl_void_type(self.context))

fn Codegen.gen_expr_discard(self: Codegen, node: i32) -> void:
    if node == 0: return
    let kind = self.pool.kind(node)
    if kind == NK_BLOCK():
        self.gen_block_discard(node)
        return
    if kind == NK_IF_EXPR():
        self.gen_if_discard(node)
        return
    self.gen_expr(node)

// ── Literal expressions ───────────────────────────────────────────

fn Codegen.gen_int_lit(self: Codegen, node: i32) -> i64:
    let val = self.pool.int_lit_value(node)
    if self.expected_type != 0 and wl_get_type_kind(self.expected_type) == wl_pointer_type_kind() and val == 0:
        return wl_const_null(self.expected_type)
    if val >= -2147483648 and val <= 2147483647:
        return wl_const_int(wl_i32_type(self.context), val, 1)
    wl_const_int(wl_i64_type(self.context), val, 1)

fn Codegen.gen_float_lit(self: Codegen, node: i32) -> i64:
    let str_idx = self.pool.get_data0(node)
    let s = self.pool.get_string(str_idx)
    // Parse float from string - use a helper
    wl_const_real(wl_f64_type(self.context), self.parse_float(s))

fn Codegen.parse_float(self: Codegen, s: str) -> f64:
    // Simple float parser
    // TODO: handle edge cases
    0.0

fn Codegen.gen_bool_lit(self: Codegen, node: i32) -> i64:
    let val = self.pool.get_data0(node)
    wl_const_int(wl_i1_type(self.context), val as i64, 0)

fn Codegen.gen_string_lit(self: Codegen, node: i32) -> i64:
    let sym = self.pool.get_data0(node)
    let text = self.intern.resolve(sym)
    let content = self.strip_raw_string_tag(text)
    if self.is_raw_tagged_string(text):
        return self.gen_string_literal_raw(content)
    self.gen_string_literal_raw(self.decode_string_escapes(content))

fn Codegen.gen_c_string_lit(self: Codegen, node: i32) -> i64:
    let sym = self.pool.get_data0(node)
    let text = self.intern.resolve(sym)
    wl_build_global_string_ptr(self.builder, self.decode_string_escapes(text))

fn Codegen.is_raw_tagged_string(self: Codegen, text: str) -> bool:
    text.len() >= 5 and text.slice(0, 5) == "\x01raw\x01"

fn Codegen.strip_raw_string_tag(self: Codegen, text: str) -> str:
    if self.is_raw_tagged_string(text):
        return text.slice(5, text.len())
    text

fn Codegen.decode_string_escapes(self: Codegen, text: str) -> str:
    var out = ""
    let len = text.len() as i32
    var i = 0
    while i < len:
        let ch = text[i]
        if ch == 92 and i + 1 < len:  // backslash
            i = i + 1
            let esc = text[i]
            if esc == 120 and i + 2 < len:  // xNN
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
    // Build str struct: { ptr, len }
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some(): return wl_get_undef(wl_i32_type(self.context))
    let str_type = self.struct_llvm_types.get(st_opt.unwrap() as i64)

    let global_str = wl_build_global_string_ptr(self.builder, text)
    let alloca = wl_build_alloca(self.builder, str_type)
    let ptr_gep = wl_build_struct_gep(self.builder, str_type, alloca, 0)
    wl_build_store(self.builder, global_str, ptr_gep)
    let len_gep = wl_build_struct_gep(self.builder, str_type, alloca, 1)
    wl_build_store(self.builder, wl_const_int(wl_i64_type(self.context), text.len(), 1), len_gep)
    wl_build_load(self.builder, str_type, alloca)

// ── Identifier expression ─────────────────────────────────────────

fn Codegen.gen_ident_expr(self: Codegen, node: i32) -> i64:
    let sym = self.pool.get_data0(node)

    // Check __FILE__
    let file_sym = self.intern.intern("__FILE__")
    if sym == file_sym:
        return self.gen_string_literal_raw(self.source_file)

    // Check __LINE__
    let line_sym = self.intern.intern("__LINE__")
    if sym == line_sym:
        let line_no = self.span_to_line(node)
        return wl_const_int(wl_i32_type(self.context), line_no as i64, 0)

    self.gen_ident(sym)

fn Codegen.gen_ident(self: Codegen, sym: i32) -> i64:
    // Check locals
    let local_ptr = self.lookup_local_alloca(sym)
    if local_ptr != 0:
        let ty = self.lookup_local_type(sym)
        if ty != 0:
            return wl_build_load(self.builder, ty, local_ptr)
        return wl_build_load(self.builder, wl_i32_type(self.context), local_ptr)

    // Check functions
    let fn_opt = self.fn_values.get(sym)
    if fn_opt.is_some():
        return fn_opt.unwrap() as i64

    // Check module constants
    let mc_opt = self.module_constants.get(sym)
    if mc_opt.is_some():
        let global = mc_opt.unwrap() as i64
        let gty = wl_global_get_value_type(global)
        return wl_build_load(self.builder, gty, global)

    // Check enum variants (unit variants are constant ints)
    let name = self.intern.resolve(sym)
    // Look through all enum types for a matching variant name
    for ei in 0..self.enum_llvm_types.len() as i32:
        let v_start = self.enum_variant_starts.get(ei as i64)
        let v_count = self.enum_variant_counts.get(ei as i64)
        for vi in 0..v_count:
            let v_name = self.enum_variant_names.get((v_start + vi) as i64)
            if v_name == sym:
                let payload = self.enum_variant_payloads.get((v_start + vi) as i64)
                if payload == 0:
                    // Unit variant
                    let enum_ty = self.enum_llvm_types.get(ei as i64)
                    let alloca = wl_build_alloca(self.builder, enum_ty)
                    wl_build_store(self.builder, self.build_default_value(enum_ty), alloca)
                    let tag_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 0)
                    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), vi as i64, 0), tag_ptr)
                    return wl_build_load(self.builder, enum_ty, alloca)

    // Not found
    if self.debug_local_flow_enabled():
        var msg = "[local-miss]"
        if self.current_function_name_sym != 0:
            msg = msg ++ " fn=" ++ self.function_symbol_name(self.current_function_name_sym)
        msg = msg ++ " sym=" ++ int_to_string(sym)
        let sym_text = self.intern.resolve(sym)
        if sym_text.len() > 0:
            msg = msg ++ " name=" ++ sym_text
        with_eprintln(msg)
    wl_get_undef(wl_i32_type(self.context))

// ── Binary expression ─────────────────────────────────────────────

fn Codegen.gen_binary(self: Codegen, node: i32) -> i64:
    let op = self.pool.get_data0(node)
    let lhs_node = self.pool.get_data1(node)
    let rhs_node = self.pool.get_data2(node)

    // Short-circuit for & and ||
    if op == OP_AND(): return self.gen_logical_and(lhs_node, rhs_node)
    if op == OP_OR(): return self.gen_logical_or(lhs_node, rhs_node)

    // String concatenation
    if op == OP_CONCAT(): return self.gen_str_concat(lhs_node, rhs_node)

    // Default operator (??)
    if op == OP_DEFAULT(): return self.gen_default_op(lhs_node, rhs_node)

    let lhs = self.gen_expr(lhs_node)
    let rhs = self.gen_expr(rhs_node)

    let lty = wl_type_of(lhs)
    let rty = wl_type_of(rhs)

    // Float operations
    let lk = wl_get_type_kind(lty)
    if lk == wl_float_type_kind() or lk == wl_double_type_kind():
        return self.gen_float_binary(op, lhs, rhs)

    // Coerce widths
    var l = lhs
    var r = rhs
    if lty != rty:
        let lw = wl_get_int_type_width(lty)
        let rw = wl_get_int_type_width(rty)
        if lw > rw: r = wl_build_sext(self.builder, rhs, lty)
        else if rw > lw: l = wl_build_sext(self.builder, lhs, rty)

    if op == OP_EQ() or op == OP_NEQ():
        let cmp_lty = wl_type_of(l)
        let cmp_rty = wl_type_of(r)
        if cmp_lty == cmp_rty:
            let cmp_kind = wl_get_type_kind(cmp_lty)
            if cmp_kind == wl_struct_type_kind() or cmp_kind == wl_array_type_kind():
                return self.compare_aggregate_eq(l, r, op)

    // Integer operations
    if op == OP_ADD() or op == OP_ADD_WRAP(): return wl_build_add(self.builder, l, r)
    if op == OP_SUB() or op == OP_SUB_WRAP(): return wl_build_sub(self.builder, l, r)
    if op == OP_MUL() or op == OP_MUL_WRAP(): return wl_build_mul(self.builder, l, r)
    if op == OP_DIV(): return wl_build_sdiv(self.builder, l, r)
    if op == OP_MOD(): return wl_build_srem(self.builder, l, r)
    if op == OP_EQ(): return wl_build_icmp(self.builder, wl_int_eq(), l, r)
    if op == OP_NEQ(): return wl_build_icmp(self.builder, wl_int_ne(), l, r)
    if op == OP_LT(): return wl_build_icmp(self.builder, wl_int_slt(), l, r)
    if op == OP_GT(): return wl_build_icmp(self.builder, wl_int_sgt(), l, r)
    if op == OP_LTE(): return wl_build_icmp(self.builder, wl_int_sle(), l, r)
    if op == OP_GTE(): return wl_build_icmp(self.builder, wl_int_sge(), l, r)
    if op == OP_BIT_AND(): return wl_build_and(self.builder, l, r)
    if op == OP_BIT_OR(): return wl_build_or(self.builder, l, r)
    if op == OP_BIT_XOR(): return wl_build_xor(self.builder, l, r)
    if op == OP_SHL(): return wl_build_shl(self.builder, l, r)
    if op == OP_SHR(): return wl_build_ashr(self.builder, l, r)

    wl_get_undef(wl_i32_type(self.context))

fn Codegen.gen_float_binary(self: Codegen, op: i32, lhs: i64, rhs: i64) -> i64:
    if op == OP_ADD(): return wl_build_fadd(self.builder, lhs, rhs)
    if op == OP_SUB(): return wl_build_fsub(self.builder, lhs, rhs)
    if op == OP_MUL(): return wl_build_fmul(self.builder, lhs, rhs)
    if op == OP_DIV(): return wl_build_fdiv(self.builder, lhs, rhs)
    if op == OP_MOD(): return wl_build_frem(self.builder, lhs, rhs)
    if op == OP_EQ(): return wl_build_fcmp(self.builder, wl_real_oeq(), lhs, rhs)
    if op == OP_NEQ(): return wl_build_fcmp(self.builder, wl_real_one(), lhs, rhs)
    if op == OP_LT(): return wl_build_fcmp(self.builder, wl_real_olt(), lhs, rhs)
    if op == OP_GT(): return wl_build_fcmp(self.builder, wl_real_ogt(), lhs, rhs)
    if op == OP_LTE(): return wl_build_fcmp(self.builder, wl_real_ole(), lhs, rhs)
    if op == OP_GTE(): return wl_build_fcmp(self.builder, wl_real_oge(), lhs, rhs)
    wl_get_undef(wl_f64_type(self.context))

fn Codegen.gen_logical_and(self: Codegen, lhs_node: i32, rhs_node: i32) -> i64:
    let lhs = self.gen_expr(lhs_node)
    let then_bb = wl_append_bb(self.context, self.current_function, "and.rhs")
    let merge_bb = wl_append_bb(self.context, self.current_function, "and.end")
    let entry_bb = wl_get_insert_block(self.builder)
    wl_build_cond_br(self.builder, lhs, then_bb, merge_bb)
    wl_position_at_end(self.builder, then_bb)
    let rhs = self.gen_expr(rhs_node)
    let rhs_bb = wl_get_insert_block(self.builder)
    wl_build_br(self.builder, merge_bb)
    wl_position_at_end(self.builder, merge_bb)
    let phi = wl_build_phi(self.builder, wl_i1_type(self.context))
    let false_val = wl_const_int(wl_i1_type(self.context), 0, 0)
    let vals: Vec[i64] = Vec.new()
    vals.push(false_val)
    vals.push(rhs)
    let bbs: Vec[i64] = Vec.new()
    bbs.push(entry_bb)
    bbs.push(rhs_bb)
    wl_add_incoming(phi, vec_data_i64(&vals), vec_data_i64(&bbs), 2)
    phi

fn Codegen.gen_logical_or(self: Codegen, lhs_node: i32, rhs_node: i32) -> i64:
    let lhs = self.gen_expr(lhs_node)
    let else_bb = wl_append_bb(self.context, self.current_function, "or.rhs")
    let merge_bb = wl_append_bb(self.context, self.current_function, "or.end")
    let entry_bb = wl_get_insert_block(self.builder)
    wl_build_cond_br(self.builder, lhs, merge_bb, else_bb)
    wl_position_at_end(self.builder, else_bb)
    let rhs = self.gen_expr(rhs_node)
    let rhs_bb = wl_get_insert_block(self.builder)
    wl_build_br(self.builder, merge_bb)
    wl_position_at_end(self.builder, merge_bb)
    let phi = wl_build_phi(self.builder, wl_i1_type(self.context))
    let true_val = wl_const_int(wl_i1_type(self.context), 1, 0)
    let vals: Vec[i64] = Vec.new()
    vals.push(true_val)
    vals.push(rhs)
    let bbs: Vec[i64] = Vec.new()
    bbs.push(entry_bb)
    bbs.push(rhs_bb)
    wl_add_incoming(phi, vec_data_i64(&vals), vec_data_i64(&bbs), 2)
    phi

fn Codegen.gen_str_concat(self: Codegen, lhs_node: i32, rhs_node: i32) -> i64:
    let lhs = self.gen_expr(lhs_node)
    let rhs = self.gen_expr(rhs_node)
    // Call with_str_concat runtime function
    let concat_sym = self.intern.intern("with_str_concat")
    let fv = self.fn_values.get(concat_sym)
    let ft = self.fn_fn_types.get(concat_sym)
    if fv.is_some() and ft.is_some():
        let args: Vec[i64] = Vec.new()
        args.push(lhs)
        args.push(rhs)
        return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&args), 2)
    // Fallback: declare it
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

fn Codegen.gen_default_op(self: Codegen, lhs_node: i32, rhs_node: i32) -> i64:
    // ?? operator: if lhs is Some, unwrap it; else use rhs
    let lhs = self.gen_expr(lhs_node)
    let lty = wl_type_of(lhs)
    // Extract tag
    let tag = wl_build_extract_value(self.builder, lhs, 0)
    let is_some = wl_build_icmp(self.builder, wl_int_eq(), tag, wl_const_int(wl_i32_type(self.context), 0, 0))
    let then_bb = wl_append_bb(self.context, self.current_function, "default.some")
    let else_bb = wl_append_bb(self.context, self.current_function, "default.none")
    let merge_bb = wl_append_bb(self.context, self.current_function, "default.end")
    wl_build_cond_br(self.builder, is_some, then_bb, else_bb)
    // Some path: extract payload
    wl_position_at_end(self.builder, then_bb)
    let payload = wl_build_extract_value(self.builder, lhs, 1)
    let some_bb = wl_get_insert_block(self.builder)
    wl_build_br(self.builder, merge_bb)
    // None path: evaluate rhs
    wl_position_at_end(self.builder, else_bb)
    let rhs = self.gen_expr(rhs_node)
    let none_bb = wl_get_insert_block(self.builder)
    wl_build_br(self.builder, merge_bb)
    // Merge
    wl_position_at_end(self.builder, merge_bb)
    let phi = wl_build_phi(self.builder, wl_type_of(rhs))
    let vals: Vec[i64] = Vec.new()
    vals.push(payload)
    vals.push(rhs)
    let bbs: Vec[i64] = Vec.new()
    bbs.push(some_bb)
    bbs.push(none_bb)
    wl_add_incoming(phi, vec_data_i64(&vals), vec_data_i64(&bbs), 2)
    phi

// ── Unary expression ──────────────────────────────────────────────

fn Codegen.gen_unary(self: Codegen, node: i32) -> i64:
    let op = self.pool.get_data0(node)
    let operand_node = self.pool.get_data1(node)

    if op == UOP_NEGATE():
        let val = self.gen_expr(operand_node)
        let ty = wl_type_of(val)
        let tk = wl_get_type_kind(ty)
        if tk == wl_float_type_kind() or tk == wl_double_type_kind():
            return wl_build_fneg(self.builder, val)
        return wl_build_neg(self.builder, val)

    if op == UOP_NOT():
        let val = self.gen_expr(operand_node)
        let ty = wl_type_of(val)
        if ty == wl_i1_type(self.context):
            return wl_build_xor(self.builder, val, wl_const_int(wl_i1_type(self.context), 1, 0))
        // For non-i1 types (i32, i64), logical NOT: compare to zero.
        // wl_build_not does bitwise NOT which is wrong for i32 booleans
        // (e.g. ~1 = 0xFFFFFFFE which is still truthy).
        return wl_build_icmp(self.builder, wl_int_eq(), val, wl_const_int(ty, 0, 0))

    if op == UOP_REF() or op == UOP_MUT_REF():
        // &expr or &mut expr — get address of operand
        let ok = self.pool.kind(operand_node)
        if ok == NK_IDENT():
            let sym = self.pool.get_data0(operand_node)
            let la = self.local_allocas.get(sym)
            if la.is_some():
                return la.unwrap() as i64
        // General case: alloca + store
        let val = self.gen_expr(operand_node)
        let ty = wl_type_of(val)
        let alloca = wl_build_alloca(self.builder, ty)
        wl_build_store(self.builder, val, alloca)
        return alloca

    if op == UOP_DEREF():
        let ptr = self.gen_expr(operand_node)
        // Dereference: load from pointer
        // Need to know pointee type — check local info
        if self.pool.kind(operand_node) == NK_IDENT():
            let sym = self.pool.get_data0(operand_node)
            let ps = self.local_pointee_structs.get(sym)
            if ps.is_some():
                let sty = self.struct_type_map.get(ps.unwrap())
                if sty.is_some():
                    let st = self.struct_llvm_types.get(sty.unwrap() as i64)
                    return wl_build_load(self.builder, st, ptr)
        return wl_build_load(self.builder, wl_i32_type(self.context), ptr)

    if op == UOP_TRY():
        // try expr — propagate error from Result
        let val = self.gen_expr(operand_node)
        let tag = wl_build_extract_value(self.builder, val, 0)
        let is_err = wl_build_icmp(self.builder, wl_int_ne(), tag, wl_const_int(wl_i32_type(self.context), 0, 0))
        let err_bb = wl_append_bb(self.context, self.current_function, "try.err")
        let ok_bb = wl_append_bb(self.context, self.current_function, "try.ok")
        wl_build_cond_br(self.builder, is_err, err_bb, ok_bb)
        // Error path: propagate
        wl_position_at_end(self.builder, err_bb)
        if self.current_ret_type != wl_void_type(self.context):
            let _ = wl_build_ret(self.builder, val)
        else:
            let _ = wl_build_ret_void(self.builder)
        // OK path: extract payload
        wl_position_at_end(self.builder, ok_bb)
        let elem_count = wl_count_struct_elem_types(wl_type_of(val))
        if elem_count > 1:
            return wl_build_extract_value(self.builder, val, 1)
        return wl_const_int(wl_i32_type(self.context), 0, 0)

    wl_get_undef(wl_i32_type(self.context))

// ── Block expression ──────────────────────────────────────────────

fn Codegen.gen_block(self: Codegen, node: i32) -> i64:
    let extra_start = self.pool.get_data0(node)
    let stmt_count = self.pool.get_data1(node)
    let tail_node = self.pool.get_data2(node)
    let saved_scope = self.scope_local_count
    var result: i64 = wl_get_undef(wl_void_type(self.context))
    for si in 0..stmt_count:
        let stmt = self.pool.get_extra(extra_start + si)
        self.gen_expr_discard(stmt)
        // Check if current block is terminated
        let bb = wl_get_insert_block(self.builder)
        if wl_get_bb_terminator(bb) != 0:
            self.scope_local_count = saved_scope
            return wl_get_undef(wl_void_type(self.context))
    if tail_node != 0:
        result = self.gen_expr(tail_node)
    self.emit_drops(saved_scope)
    result

fn Codegen.gen_block_discard(self: Codegen, node: i32) -> void:
    let extra_start = self.pool.get_data0(node)
    let stmt_count = self.pool.get_data1(node)
    let tail_node = self.pool.get_data2(node)
    let saved_scope = self.scope_local_count
    for si in 0..stmt_count:
        let stmt = self.pool.get_extra(extra_start + si)
        self.gen_expr_discard(stmt)
    if tail_node != 0:
        self.gen_expr_discard(tail_node)
    self.emit_drops(saved_scope)

// ── If expression ─────────────────────────────────────────────────

fn Codegen.gen_if_expr(self: Codegen, node: i32) -> i64:
    let cond_node = self.pool.get_data0(node)
    let then_node = self.pool.get_data1(node)
    let else_node = self.pool.get_data2(node)
    let cond = self.gen_expr(cond_node)
    // Ensure bool
    let cond_ty = wl_type_of(cond)
    var bool_cond = cond
    if cond_ty != wl_i1_type(self.context):
        bool_cond = wl_build_icmp(self.builder, wl_int_ne(), cond, wl_const_int(cond_ty, 0, 0))
    let then_bb = wl_append_bb(self.context, self.current_function, "if.then")
    let else_bb = wl_append_bb(self.context, self.current_function, "if.else")
    let merge_bb = wl_append_bb(self.context, self.current_function, "if.end")
    wl_build_cond_br(self.builder, bool_cond, then_bb, else_bb)
    // Then
    wl_position_at_end(self.builder, then_bb)
    let then_val = self.gen_expr(then_node)
    let then_exit_bb = wl_get_insert_block(self.builder)
    let then_terminated = wl_get_bb_terminator(then_exit_bb) != 0
    if not then_terminated: wl_build_br(self.builder, merge_bb)
    // Else
    wl_position_at_end(self.builder, else_bb)
    var else_val: i64 = wl_get_undef(wl_void_type(self.context))
    var else_exit_bb = else_bb
    var else_terminated = false
    if else_node != 0:
        else_val = self.gen_expr(else_node)
        else_exit_bb = wl_get_insert_block(self.builder)
        else_terminated = wl_get_bb_terminator(else_exit_bb) != 0
    if not else_terminated: wl_build_br(self.builder, merge_bb)
    // Merge
    wl_position_at_end(self.builder, merge_bb)
    if then_terminated and else_terminated:
        wl_build_unreachable(self.builder)
        return wl_get_undef(wl_void_type(self.context))
    if else_node == 0:
        return wl_get_undef(wl_void_type(self.context))
    // If both branches produce values and neither is terminated, use phi
    if else_node != 0 and not then_terminated and not else_terminated:
        let then_ty = wl_type_of(then_val)
        let else_ty = wl_type_of(else_val)
        if then_ty != wl_void_type(self.context) and then_ty == else_ty:
            let phi = wl_build_phi(self.builder, then_ty)
            let vals: Vec[i64] = Vec.new()
            vals.push(then_val)
            vals.push(else_val)
            let bbs: Vec[i64] = Vec.new()
            bbs.push(then_exit_bb)
            bbs.push(else_exit_bb)
            wl_add_incoming(phi, vec_data_i64(&vals), vec_data_i64(&bbs), 2)
            return phi
    if not then_terminated: return then_val
    wl_get_undef(wl_void_type(self.context))

fn Codegen.gen_if_discard(self: Codegen, node: i32) -> void:
    let cond_node = self.pool.get_data0(node)
    let then_node = self.pool.get_data1(node)
    let else_node = self.pool.get_data2(node)
    let cond = self.gen_expr(cond_node)
    let cond_ty = wl_type_of(cond)
    var bool_cond = cond
    if cond_ty != wl_i1_type(self.context):
        bool_cond = wl_build_icmp(self.builder, wl_int_ne(), cond, wl_const_int(cond_ty, 0, 0))
    let then_bb = wl_append_bb(self.context, self.current_function, "if.then")
    let else_bb = wl_append_bb(self.context, self.current_function, "if.else")
    let merge_bb = wl_append_bb(self.context, self.current_function, "if.end")
    wl_build_cond_br(self.builder, bool_cond, then_bb, else_bb)
    wl_position_at_end(self.builder, then_bb)
    self.gen_expr_discard(then_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, merge_bb)
    wl_position_at_end(self.builder, else_bb)
    if else_node != 0:
        self.gen_expr_discard(else_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, merge_bb)
    wl_position_at_end(self.builder, merge_bb)

// ── Let binding ───────────────────────────────────────────────────

fn Codegen.gen_let_binding(self: Codegen, node: i32) -> i64:
    let name_sym = self.pool.get_data0(node)
    let name_text = self.intern.resolve(name_sym)
    let alias_name = if name_text.len() == 0: self.let_binding_name_from_node(node) else: ""
    let alias_sym = if alias_name.len() > 0: self.intern.intern(alias_name) else: 0
    let value_node = self.pool.get_data1(node)
    let flags = self.pool.get_data2(node)
    let is_mut = flags % 2
    var declared_ty: i64 = 0
    var declared_type_node = 0
    let ann_slot = flags / 2
    if ann_slot > 0:
        let type_extra = ann_slot - 1
        declared_type_node = self.pool.get_extra(type_extra)
        declared_ty = self.resolve_type(declared_type_node)

    let saved_expected = self.expected_type
    let saved_expected_node = self.expected_type_node
    if declared_ty != 0:
        self.expected_type = declared_ty
        self.expected_type_node = declared_type_node
    var val = self.gen_expr(value_node)
    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    var val_ty = wl_type_of(val)

    if declared_type_node != 0:
        let dyn_trait = self.dyn_trait_from_type_node(declared_type_node)
        if dyn_trait != 0:
            var concrete_sym = 0
            if value_node != 0 and self.pool.kind(value_node) == NK_IDENT():
                let src_sym = self.pool.get_data0(value_node)
                let known = self.trait_local_concrete_types.get(src_sym)
                if known.is_some():
                    concrete_sym = known.unwrap()
            if concrete_sym != 0:
                self.record_trait_local_concrete(name_sym, concrete_sym)
                if alias_sym != 0:
                    self.record_trait_local_concrete(alias_sym, concrete_sym)
            else:
                let info = self.find_dyn_concrete_arg(value_node, val_ty)
                if info.type_sym != 0:
                    if info.use_ptr != 0:
                        val = self.build_dyn_trait_value_from_ptr(val, info.type_sym, dyn_trait)
                    else:
                        val = self.build_dyn_trait_value(val, info.type_sym, dyn_trait)
                    val_ty = wl_type_of(val)
                    self.record_trait_local_concrete(name_sym, info.type_sym)
                    if alias_sym != 0:
                        self.record_trait_local_concrete(alias_sym, info.type_sym)
            self.record_trait_local(name_sym, dyn_trait)
            if alias_sym != 0:
                self.record_trait_local(alias_sym, dyn_trait)
        else if declared_ty != 0:
            val = self.coerce_value_to_type(val, declared_ty)
            val_ty = wl_type_of(val)

    let storage_ty = if declared_ty != 0: declared_ty else: val_ty
    let alloca = self.create_entry_alloca(storage_ty)
    let stored = self.coerce_value_to_type(val, storage_ty)
    wl_build_store(self.builder, stored, alloca)
    self.record_local(name_sym, alloca, storage_ty, is_mut)
    if declared_type_node != 0:
        self.record_local_container_type(name_sym, declared_type_node)
    if alias_sym != 0:
        self.record_local(alias_sym, alloca, storage_ty, is_mut)
        if declared_type_node != 0:
            self.record_local_container_type(alias_sym, declared_type_node)
    let pointee_struct = self.infer_local_pointee_struct(value_node, declared_type_node, storage_ty)
    if pointee_struct != 0:
        self.record_local_pointee_struct(name_sym, pointee_struct)
        if alias_sym != 0:
            self.record_local_pointee_struct(alias_sym, pointee_struct)
    let concrete_struct = self.infer_local_concrete_struct(value_node, storage_ty)
    if concrete_struct != 0:
        self.record_trait_local_concrete(name_sym, concrete_struct)
        if alias_sym != 0:
            self.record_trait_local_concrete(alias_sym, concrete_struct)
    // Track for scope drops
    self.scope_local_syms.push(name_sym)
    self.scope_local_allocas.push(alloca)
    self.scope_local_types.push(storage_ty)
    self.scope_local_count = self.scope_local_count + 1
    // Track vec/hashmap/enum local types
    self.track_local_type(name_sym, value_node, storage_ty)
    if alias_sym != 0:
        self.track_local_type(alias_sym, value_node, storage_ty)
    wl_get_undef(wl_void_type(self.context))

fn Codegen.track_local_type(self: Codegen, sym: i32, value_node: i32, val_ty: i64):
    // Track vec element types for Vec locals
    let _ = value_node
    let existing_vec = self.vec_local_types.get(sym)
    if not existing_vec.is_some():
        let idx = self.find_vec_cache_index_by_llvm(val_ty)
        if idx >= 0:
            self.vec_local_types.insert(sym, self.vec_elem_types.get(idx as i64))
    // Track enum local types
    let existing_enum = self.enum_local_types.get(sym)
    if not existing_enum.is_some():
        let es = self.enum_by_llvm.get(val_ty)
        if es.is_some():
            self.enum_local_types.insert(sym, es.unwrap())

// ── Let-else binding ──────────────────────────────────────────────

fn Codegen.gen_let_else(self: Codegen, node: i32) -> i64:
    let pattern_node = self.pool.get_data0(node)
    let value_node = self.pool.get_data1(node)
    let else_body = self.pool.get_data2(node)
    let val = self.gen_expr(value_node)
    // Simple implementation: try to match, else diverge
    // For Option: check tag
    let val_ty = wl_type_of(val)
    let tag = wl_build_extract_value(self.builder, val, 0)
    let is_some = wl_build_icmp(self.builder, wl_int_eq(), tag, wl_const_int(wl_i32_type(self.context), 0, 0))
    let ok_bb = wl_append_bb(self.context, self.current_function, "letelse.ok")
    let else_bb = wl_append_bb(self.context, self.current_function, "letelse.else")
    wl_build_cond_br(self.builder, is_some, ok_bb, else_bb)
    // Else path
    wl_position_at_end(self.builder, else_bb)
    self.gen_expr(else_body)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_unreachable(self.builder)
    // OK path: bind pattern
    wl_position_at_end(self.builder, ok_bb)
    self.bind_pattern(pattern_node, val)
    wl_get_undef(wl_void_type(self.context))

fn Codegen.bind_pattern(self: Codegen, pat_node: i32, val: i64):
    let pk = self.pool.kind(pat_node)
    if pk == NK_PAT_IDENT():
        let sym = self.pool.get_data0(pat_node)
        // Extract payload from Option/Result
        let elem_count = wl_count_struct_elem_types(wl_type_of(val))
        var payload = val
        if elem_count > 1:
            payload = wl_build_extract_value(self.builder, val, 1)
        let ty = wl_type_of(payload)
        let alloca = self.create_entry_alloca(ty)
        wl_build_store(self.builder, payload, alloca)
        self.record_local(sym, alloca, ty, 0)
    else if pk == NK_PAT_VARIANT():
        let v_name = self.pool.get_data0(pat_node)
        let v_extra = self.pool.get_data1(pat_node)
        let v_bind_count = self.pool.get_data2(pat_node)
        // Extract payload and bind
        let payload = wl_build_extract_value(self.builder, val, 1)
        if v_bind_count > 0:
            let bind_sym = self.pool.get_extra(v_extra)
            let ty = wl_type_of(payload)
            let alloca = self.create_entry_alloca(ty)
            wl_build_store(self.builder, payload, alloca)
            self.record_local(bind_sym, alloca, ty, 0)

// ── Return expression ─────────────────────────────────────────────

fn Codegen.gen_return(self: Codegen, node: i32) -> i64:
    let value_node = self.pool.get_data0(node)
    self.current_fn_saw_explicit_return = true
    self.emit_drops(0)
    self.emit_defers()
    if value_node == 0:
        if self.current_ret_type == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
        else:
            let default_val = self.build_default_value(self.current_ret_type)
            let _ = wl_build_ret(self.builder, default_val)
    else:
        let saved_expected = self.expected_type
        let saved_expected_node = self.expected_type_node
        self.expected_type = self.current_ret_type
        self.expected_type_node = 0
        let val = self.gen_expr(value_node)
        self.expected_type = saved_expected
        self.expected_type_node = saved_expected_node
        let val_ty = wl_type_of(val)
        if self.current_fn_returns_result and val_ty != self.current_ret_type:
            let wrapped = self.build_result_ok(val, self.current_ret_type)
            let _ = wl_build_ret(self.builder, wrapped)
        else:
            let coerced = self.coerce_value_to_type(val, self.current_ret_type)
            let _ = wl_build_ret(self.builder, coerced)
    wl_get_undef(wl_void_type(self.context))

// ── Assignment ────────────────────────────────────────────────────

fn Codegen.gen_assign(self: Codegen, node: i32) -> i64:
    let target_node = self.pool.get_data0(node)
    let value_node = self.pool.get_data1(node)
    let val = self.gen_expr(value_node)
    let tk = self.pool.kind(target_node)
    if tk == NK_IDENT():
        let sym = self.pool.get_data0(target_node)
        let la = self.local_allocas.get(sym)
        if la.is_some():
            wl_build_store(self.builder, val, la.unwrap() as i64)
            return wl_get_undef(wl_void_type(self.context))
    if tk == NK_FIELD_ACCESS():
        let obj_node = self.pool.get_data0(target_node)
        let field_sym = self.pool.get_data1(target_node)
        let ptr = self.gen_field_access_ptr(obj_node, field_sym)
        if ptr != 0:
            wl_build_store(self.builder, val, ptr)
            return wl_get_undef(wl_void_type(self.context))
    if tk == NK_INDEX():
        let arr_node = self.pool.get_data0(target_node)
        let idx_node = self.pool.get_data1(target_node)
        let ptr = self.gen_index_ptr(arr_node, idx_node)
        if ptr != 0:
            wl_build_store(self.builder, val, ptr)
            return wl_get_undef(wl_void_type(self.context))
    if tk == NK_UNARY():
        let uop = self.pool.get_data0(target_node)
        if uop == UOP_DEREF():
            let inner = self.pool.get_data1(target_node)
            let ptr = self.gen_expr(inner)
            wl_build_store(self.builder, val, ptr)
            return wl_get_undef(wl_void_type(self.context))
    wl_get_undef(wl_void_type(self.context))

// ── Field access ──────────────────────────────────────────────────

fn Codegen.gen_field_access(self: Codegen, node: i32) -> i64:
    let obj_node = self.pool.get_data0(node)
    let field_sym = self.pool.get_data1(node)
    let field_name = self.intern.resolve(field_sym)

    // Handle method calls: obj.method becomes a call lookup
    let field_ptr = self.gen_field_access_ptr(obj_node, field_sym)
    if field_ptr != 0:
        let field_type_node = self.field_access_type_node(node)
        let field_ty = self.resolve_type(field_type_node)
        if field_ty != 0 and wl_get_type_kind(field_ty) != wl_void_type_kind():
            return wl_build_load(self.builder, field_ty, field_ptr)

    // First try as struct field access
    let obj = self.gen_expr(obj_node)
    let obj_ty = wl_type_of(obj)

    // If obj is a struct, find field index
    let type_sym = self.find_struct_type_by_llvm(obj_ty)
    if type_sym != 0:
        let fi = self.find_field_index(type_sym, field_sym)
        if fi >= 0:
            return wl_build_extract_value(self.builder, obj, fi)

    // Check if obj is a pointer to struct
    if wl_get_type_kind(obj_ty) == wl_pointer_type_kind():
        // Check local pointee info
        if self.pool.kind(obj_node) == NK_IDENT():
            let sym = self.pool.get_data0(obj_node)
            let pointee_sym = self.lookup_local_pointee_struct(sym)
            if pointee_sym != 0:
                let st_opt = self.struct_type_map.get(pointee_sym)
                if st_opt.is_some():
                    let st_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
                    let fi = self.find_field_index(pointee_sym, field_sym)
                    if fi >= 0:
                        let gep = wl_build_struct_gep(self.builder, st_ty, obj, fi)
                        let fty = self.struct_field_types.get((self.struct_field_starts.get(st_opt.unwrap() as i64) + fi) as i64)
                        return wl_build_load(self.builder, fty, gep)

    // Tuple field access: .0, .1, etc.
    if field_name.len() == 1:
        let ch = field_name.byte_at(0)
        if ch >= 48 and ch <= 57:
            return wl_build_extract_value(self.builder, obj, (ch - 48) as i32)

    // len() on strings/slices/arrays
    if field_name == "len":
        let tk = wl_get_type_kind(obj_ty)
        if tk == wl_struct_type_kind():
            // str.len or slice.len → field 1
            return wl_build_extract_value(self.builder, obj, 1)

    obj

fn Codegen.gen_field_access_ptr(self: Codegen, obj_node: i32, field_sym: i32) -> i64:
    // Get a pointer to a field for assignment
    if self.pool.kind(obj_node) == NK_IDENT():
        let sym = self.pool.get_data0(obj_node)
        let local_ptr = self.lookup_local_alloca(sym)
        if local_ptr != 0:
            let ty = self.lookup_local_type(sym)
            if ty != 0:
                let type_sym = self.find_struct_type_by_llvm(ty)
                if type_sym != 0:
                    let fi = self.find_field_index(type_sym, field_sym)
                    if fi >= 0:
                        return wl_build_struct_gep(self.builder, ty, local_ptr, fi)
                // Check pointee struct
                var pointee_sym = self.lookup_local_pointee_struct(sym)
                if pointee_sym == 0 and self.current_method_owner_sym != 0 and self.intern.resolve(sym) == "self":
                    pointee_sym = self.current_method_owner_sym
                if pointee_sym != 0:
                    let st_opt = self.struct_type_map.get(pointee_sym)
                    if st_opt.is_some():
                        let st_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
                        let fi = self.find_field_index(pointee_sym, field_sym)
                        if fi >= 0:
                            let ptr = wl_build_load(self.builder, wl_ptr_type(self.context), local_ptr)
                            return wl_build_struct_gep(self.builder, st_ty, ptr, fi)
    // Nested field access
    if self.pool.kind(obj_node) == NK_FIELD_ACCESS():
        let inner_obj = self.pool.get_data0(obj_node)
        let inner_field = self.pool.get_data1(obj_node)
        let inner_ptr = self.gen_field_access_ptr(inner_obj, inner_field)
        if inner_ptr != 0:
            let inner_type_node = self.field_access_type_node(obj_node)
            let owner_sym = self.struct_owner_sym_from_type_node(inner_type_node)
            if owner_sym != 0:
                let fi = self.find_field_index(owner_sym, field_sym)
                if fi >= 0:
                    let st_opt = self.struct_type_map.get(owner_sym)
                    if st_opt.is_some():
                        let st_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
                        let inner_ty = self.resolve_type(inner_type_node)
                        if inner_ty != 0 and wl_get_type_kind(inner_ty) == wl_pointer_type_kind():
                            let ptr = wl_build_load(self.builder, wl_ptr_type(self.context), inner_ptr)
                            return wl_build_struct_gep(self.builder, st_ty, ptr, fi)
                        return wl_build_struct_gep(self.builder, st_ty, inner_ptr, fi)
    0

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
        if self.pool.kind(decl) == NK_TYPE_DECL():
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
        if self.pool.kind(decl) != NK_TYPE_DECL():
            continue
        if self.pool.get_data0(decl) != type_sym:
            continue
        let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
        if sub_kind == TDK_STRUCT():
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

fn Codegen.find_field_type_node_from_ast(self: Codegen, type_sym: i32, field_sym: i32) -> i32:
    let decl = self.find_struct_decl_node(type_sym)
    if decl == 0:
        return 0
    let extra_start = self.pool.get_data1(decl)
    let field_count = self.pool.get_extra(extra_start)
    let want_text = self.intern.resolve(field_sym)
    for fi in 0..field_count:
        let offset = extra_start + 1 + fi * 3
        let stored_sym = self.pool.get_extra(offset)
        if stored_sym == field_sym or (want_text.len() > 0 and self.intern.resolve(stored_sym) == want_text):
            return self.pool.get_extra(offset + 1)
    0

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

fn Codegen.find_field_type_node(self: Codegen, type_sym: i32, field_sym: i32) -> i32:
    let st_opt = self.struct_type_map.get(type_sym)
    if not st_opt.is_some():
        return self.find_field_type_node_from_ast(type_sym, field_sym)
    let idx = st_opt.unwrap()
    let start = self.struct_field_starts.get(idx as i64)
    let count = self.struct_field_counts.get(idx as i64)
    let want_text = self.intern.resolve(field_sym)
    for i in 0..count:
        let stored_sym = self.struct_field_names.get((start + i) as i64)
        if stored_sym == field_sym or (want_text.len() > 0 and self.intern.resolve(stored_sym) == want_text):
            if start + i < self.struct_field_type_nodes.len() as i32:
                return self.struct_field_type_nodes.get((start + i) as i64)
            return self.find_field_type_node_from_ast(type_sym, field_sym)
    self.find_field_type_node_from_ast(type_sym, field_sym)

fn Codegen.struct_owner_sym_from_type_node(self: Codegen, type_node: i32) -> i32:
    if type_node == 0:
        return 0
    let kind = self.pool.kind(type_node)
    if kind == NK_TYPE_PTR() or kind == NK_TYPE_REF():
        return self.struct_owner_sym_from_type_node(self.pool.get_data0(type_node))
    if kind == NK_TYPE_NAMED():
        let sym = self.pool.get_data0(type_node)
        if self.struct_type_map.get(sym).is_some():
            return sym
        let ty = self.resolve_named_type(sym)
        if ty != 0:
            return self.find_struct_type_by_llvm(ty)
        return 0
    if kind == NK_TYPE_GENERIC():
        let ty = self.resolve_type(type_node)
        if ty != 0:
            return self.find_struct_type_by_llvm(ty)
        return 0
    0

fn Codegen.expr_struct_owner_sym(self: Codegen, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.pool.kind(node)
    if kind == NK_IDENT():
        let sym = self.pool.get_data0(node)
        var pointee_sym = self.lookup_local_pointee_struct(sym)
        if pointee_sym == 0 and self.current_method_owner_sym != 0 and self.intern.resolve(sym) == "self":
            pointee_sym = self.current_method_owner_sym
        if pointee_sym != 0:
            return pointee_sym
        let local_ty = self.lookup_local_type(sym)
        if local_ty != 0:
            return self.find_struct_type_by_llvm(local_ty)
        return 0
    if kind == NK_FIELD_ACCESS():
        let field_type_node = self.field_access_type_node(node)
        return self.struct_owner_sym_from_type_node(field_type_node)
    0

fn Codegen.field_access_type_node(self: Codegen, node: i32) -> i32:
    if node == 0 or self.pool.kind(node) != NK_FIELD_ACCESS():
        return 0
    let base_node = self.pool.get_data0(node)
    let field_sym = self.pool.get_data1(node)
    let owner_sym = self.expr_struct_owner_sym(base_node)
    if owner_sym == 0:
        return 0
    let field_type_node = self.find_field_type_node(owner_sym, field_sym)
    field_type_node

// ── Index expression ──────────────────────────────────────────────

fn Codegen.gen_index(self: Codegen, node: i32) -> i64:
    let arr_node = self.pool.get_data0(node)
    let idx_node = self.pool.get_data1(node)
    let arr = self.gen_expr(arr_node)
    let idx = self.gen_expr(idx_node)
    let arr_ty = wl_type_of(arr)
    let tk = wl_get_type_kind(arr_ty)
    if tk == wl_array_type_kind():
        // Static array indexing
        let elem_ty = wl_get_element_type(arr_ty)
        let alloca = wl_build_alloca(self.builder, arr_ty)
        wl_build_store(self.builder, arr, alloca)
        let zero = wl_const_int(wl_i64_type(self.context), 0, 0)
        let idx64 = self.coerce_int(idx, wl_i64_type(self.context))
        let indices: Vec[i64] = Vec.new()
        indices.push(zero)
        indices.push(idx64)
        let gep = wl_build_gep(self.builder, arr_ty, alloca, vec_data_i64(&indices), 2)
        return wl_build_load(self.builder, elem_ty, gep)
    if self.is_str_type(arr_ty):
        let data_ptr = wl_build_extract_value(self.builder, arr, 0)
        let idx64 = self.coerce_int(idx, wl_i64_type(self.context))
        let indices: Vec[i64] = Vec.new()
        indices.push(idx64)
        let elem_ptr = wl_build_gep(self.builder, wl_i8_type(self.context), data_ptr, vec_data_i64(&indices), 1)
        let ch = wl_build_load(self.builder, wl_i8_type(self.context), elem_ptr)
        return wl_build_zext(self.builder, ch, wl_i32_type(self.context))
    // Default: treat as struct/vec indexing via runtime call
    arr

fn Codegen.gen_index_ptr(self: Codegen, arr_node: i32, idx_node: i32) -> i64:
    // Get pointer to array element for assignment
    if self.pool.kind(arr_node) == NK_IDENT():
        let sym = self.pool.get_data0(arr_node)
        let la = self.local_allocas.get(sym)
        if la.is_some():
            let alloca = la.unwrap() as i64
            let ty_opt = self.local_types.get(sym)
            if ty_opt.is_some():
                let ty = ty_opt.unwrap() as i64
                if wl_get_type_kind(ty) == wl_array_type_kind():
                    let idx = self.gen_expr(idx_node)
                    let zero = wl_const_int(wl_i64_type(self.context), 0, 0)
                    let idx64 = self.coerce_int(idx, wl_i64_type(self.context))
                    let indices: Vec[i64] = Vec.new()
                    indices.push(zero)
                    indices.push(idx64)
                    return wl_build_gep(self.builder, ty, alloca, vec_data_i64(&indices), 2)
    0

fn Codegen.find_binding_type(self: Codegen, syms: Vec[i32], tys: Vec[i64], sym: i32) -> i64:
    for i in 0..syms.len() as i32:
        if syms.get(i as i64) == sym:
            return tys.get(i as i64)
    0

fn Codegen.find_vec_elem_type_by_llvm(self: Codegen, vec_ty: i64) -> i64:
    let idx = self.find_vec_cache_index_by_llvm(vec_ty)
    if idx >= 0:
        return self.vec_elem_types.get(idx as i64)
    0

fn Codegen.llvm_named_struct_matches(self: Codegen, lhs: i64, rhs: i64) -> bool:
    if lhs == 0 or rhs == 0:
        return false
    if wl_get_type_kind(lhs) != wl_struct_type_kind() or wl_get_type_kind(rhs) != wl_struct_type_kind():
        return false
    let lhs_name = wl_get_struct_name(lhs)
    let rhs_name = wl_get_struct_name(rhs)
    if lhs_name.len() == 0 or rhs_name.len() == 0:
        return false
    with_str_eq(lhs_name, rhs_name) != 0

fn Codegen.find_hashset_cache_index_by_llvm(self: Codegen, hs_ty: i64) -> i32:
    for i in 0..self.hs_llvm_types.len() as i32:
        let cached_ty = self.hs_llvm_types.get(i as i64)
        if cached_ty == hs_ty or self.llvm_named_struct_matches(cached_ty, hs_ty):
            return i
    0 - 1

fn Codegen.find_vec_cache_index_by_llvm(self: Codegen, vec_ty: i64) -> i32:
    for i in 0..self.vec_llvm_types.len() as i32:
        let cached_ty = self.vec_llvm_types.get(i as i64)
        if cached_ty == vec_ty or self.llvm_named_struct_matches(cached_ty, vec_ty):
            return i
    0 - 1

fn Codegen.find_hashmap_key_type_by_llvm(self: Codegen, hm_ty: i64) -> i64:
    let idx = self.find_hashmap_cache_index_by_llvm(hm_ty)
    if idx >= 0:
        return self.hm_key_types.get(idx as i64)
    0

fn Codegen.find_hashmap_cache_index_by_llvm(self: Codegen, hm_ty: i64) -> i32:
    for i in 0..self.hm_llvm_types.len() as i32:
        let cached_ty = self.hm_llvm_types.get(i as i64)
        if cached_ty == hm_ty or self.llvm_named_struct_matches(cached_ty, hm_ty):
            return i
    0 - 1

fn Codegen.find_hashmap_cache_index_by_parts(self: Codegen, key_ty: i64, val_ty: i64) -> i32:
    for i in 0..self.hm_llvm_types.len() as i32:
        if self.hm_key_types.get(i as i64) == key_ty and self.hm_val_types.get(i as i64) == val_ty:
            return i
    0 - 1

fn Codegen.type_node_hashmap_cache_index(self: Codegen, type_node: i32) -> i32:
    if type_node == 0 or self.pool.kind(type_node) != NK_TYPE_GENERIC():
        return 0 - 1
    let name_sym = self.pool.get_data0(type_node)
    if self.intern.resolve(name_sym) != "HashMap":
        return 0 - 1
    let extra_start = self.pool.get_data1(type_node)
    let arg_count = self.pool.get_data2(type_node)
    if arg_count != 2:
        return 0 - 1
    let key_node = self.pool.get_extra(extra_start)
    let val_node = self.pool.get_extra(extra_start + 1)
    let key_ty = self.resolve_type(key_node)
    let val_ty = self.resolve_type(val_node)
    if key_ty == 0 or val_ty == 0:
        return 0 - 1
    let _ = self.get_or_create_hashmap_type(key_ty, val_ty)
    self.find_hashmap_cache_index_by_parts(key_ty, val_ty)

fn Codegen.type_node_vec_elem_type(self: Codegen, type_node: i32) -> i64:
    if type_node == 0 or self.pool.kind(type_node) != NK_TYPE_GENERIC():
        return 0
    let name_sym = self.pool.get_data0(type_node)
    if self.intern.resolve(name_sym) != "Vec":
        return 0
    let extra_start = self.pool.get_data1(type_node)
    let arg_count = self.pool.get_data2(type_node)
    if arg_count <= 0:
        return 0
    let elem_node = self.pool.get_extra(extra_start)
    self.resolve_type(elem_node)

fn Codegen.infer_vec_elem_type_from_receiver(self: Codegen, obj_node: i32, obj_ty: i64) -> i64:
    if obj_node != 0 and self.pool.kind(obj_node) == NK_IDENT():
        let sym = self.pool.get_data0(obj_node)
        let elem_ty = self.vec_local_types.get(sym)
        if elem_ty.is_some():
            return elem_ty.unwrap() as i64
    if obj_node != 0 and self.pool.kind(obj_node) == NK_FIELD_ACCESS():
        let field_type_node = self.field_access_type_node(obj_node)
        let elem_ty = self.type_node_vec_elem_type(field_type_node)
        if elem_ty != 0:
            return elem_ty
    let idx = self.find_vec_cache_index_by_llvm(obj_ty)
    if idx >= 0:
        return self.vec_elem_types.get(idx as i64)
    0

fn Codegen.infer_hashmap_cache_index_from_receiver(self: Codegen, obj_node: i32, obj_ty: i64) -> i32:
    if obj_node != 0 and self.pool.kind(obj_node) == NK_IDENT():
        let sym = self.pool.get_data0(obj_node)
        let local_idx = self.hm_local_types.get(sym)
        if local_idx.is_some():
            return local_idx.unwrap()
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            let canon_idx = self.hm_local_types.get(canon)
            if canon_idx.is_some():
                return canon_idx.unwrap()
    if obj_node != 0 and self.pool.kind(obj_node) == NK_FIELD_ACCESS():
        let field_type_node = self.field_access_type_node(obj_node)
        let field_idx = self.type_node_hashmap_cache_index(field_type_node)
        if field_idx >= 0:
            return field_idx
    self.find_hashmap_cache_index_by_llvm(obj_ty)

fn Codegen.find_hashmap_val_type_by_llvm(self: Codegen, hm_ty: i64) -> i64:
    let idx = self.find_hashmap_cache_index_by_llvm(hm_ty)
    if idx >= 0:
        return self.hm_val_types.get(idx as i64)
    0

fn Codegen.find_hashset_elem_type_by_llvm(self: Codegen, hs_ty: i64) -> i64:
    let idx = self.find_hashset_cache_index_by_llvm(hs_ty)
    if idx >= 0:
        return self.hs_elem_types.get(idx as i64)
    0

fn Codegen.find_option_payload_type_by_llvm(self: Codegen, opt_ty: i64) -> i64:
    for i in 0..self.option_llvm_types.len() as i32:
        if self.option_llvm_types.get(i as i64) == opt_ty:
            return self.option_payload_types.get(i as i64)
    0

fn Codegen.find_result_ok_type_by_llvm(self: Codegen, res_ty: i64) -> i64:
    for i in 0..self.result_llvm_types.len() as i32:
        if self.result_llvm_types.get(i as i64) == res_ty:
            return self.result_ok_types.get(i as i64)
    0

fn Codegen.find_result_err_type_by_llvm(self: Codegen, res_ty: i64) -> i64:
    for i in 0..self.result_llvm_types.len() as i32:
        if self.result_llvm_types.get(i as i64) == res_ty:
            return self.result_err_types.get(i as i64)
    0

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

fn Codegen.monomorphize_generic_call(self: Codegen, fn_sym: i32, fn_node: i32, args_start: i32, arg_count: i32, call_node: i32) -> i64:
    var generic_node = fn_node
    var meta = self.pool.find_fn_meta(generic_node)
    if self.pool.kind(generic_node) != NK_FN_DECL() or self.pool.get_data0(generic_node) != fn_sym or meta < 0 or self.pool.fn_meta_tp_count(meta) <= 0:
        for di in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(di)
            if self.pool.kind(decl) != NK_FN_DECL():
                continue
            if self.pool.get_data0(decl) != fn_sym:
                continue
            let dmeta = self.pool.find_fn_meta(decl)
            if dmeta >= 0 and self.pool.fn_meta_tp_count(dmeta) > 0:
                generic_node = decl
                meta = dmeta
                break

    if meta < 0:
        return wl_get_undef(wl_i32_type(self.context))

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)
    let tp_start = self.pool.fn_meta_tp_start(meta)
    let tp_count = self.pool.fn_meta_tp_count(meta)
    let body_node = self.pool.get_data1(generic_node)
    if param_count < 0 or param_count > 64:
        return wl_get_undef(wl_i32_type(self.context))

    let arg_vals: Vec[i64] = Vec.new()
    let arg_tys: Vec[i64] = Vec.new()
    for ai in 0..arg_count:
        let arg_node = self.pool.get_extra(args_start + ai)
        let arg_val = self.gen_expr(arg_node)
        arg_vals.push(arg_val)
        arg_tys.push(wl_type_of(arg_val))

    let tp_syms: Vec[i32] = Vec.new()
    var tp_pos = tp_start
    for ti in 0..tp_count:
        let tp_sym = self.pool.get_extra(tp_pos)
        tp_syms.push(tp_sym)
        let bound_count = self.pool.get_extra(tp_pos + 1)
        tp_pos = tp_pos + 2 + bound_count

    let bind_syms: Vec[i32] = Vec.new()
    let bind_tys: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        if pi >= arg_count:
            break
        let p_type_node = self.pool.get_extra(param_start + pi * 2 + 1)
        if p_type_node == 0:
            continue

        let arg_ty = arg_tys.get(pi as i64)
        let p_kind = self.pool.kind(p_type_node)

        if p_kind == NK_TYPE_NAMED():
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
            continue

        if p_kind == NK_TYPE_GENERIC():
            let g_name_sym = self.pool.get_data0(p_type_node)
            let g_name = self.intern.resolve(g_name_sym)
            let g_extra = self.pool.get_data1(p_type_node)
            let g_count = self.pool.get_data2(p_type_node)

            if g_name == "Vec" and g_count == 1:
                let inner = self.pool.get_extra(g_extra)
                if self.pool.kind(inner) == NK_TYPE_NAMED():
                    let inner_sym = self.pool.get_data0(inner)
                    var is_tp = false
                    for ti in 0..tp_syms.len() as i32:
                        if tp_syms.get(ti as i64) == inner_sym:
                            is_tp = true
                            break
                    if is_tp:
                        let elem_ty = self.find_vec_elem_type_by_llvm(arg_ty)
                        if elem_ty != 0:
                            var exists = false
                            for bi in 0..bind_syms.len() as i32:
                                if bind_syms.get(bi as i64) == inner_sym:
                                    exists = true
                                    break
                            if not exists:
                                bind_syms.push(inner_sym)
                                bind_tys.push(elem_ty)
                continue

            if g_name == "HashMap" and g_count == 2:
                let k_node = self.pool.get_extra(g_extra)
                let v_node = self.pool.get_extra(g_extra + 1)
                let key_ty = self.find_hashmap_key_type_by_llvm(arg_ty)
                let val_ty = self.find_hashmap_val_type_by_llvm(arg_ty)
                if key_ty != 0 and self.pool.kind(k_node) == NK_TYPE_NAMED():
                    let k_sym = self.pool.get_data0(k_node)
                    var is_tp_k = false
                    for ti in 0..tp_syms.len() as i32:
                        if tp_syms.get(ti as i64) == k_sym:
                            is_tp_k = true
                            break
                    if is_tp_k:
                        var exists_k = false
                        for bi in 0..bind_syms.len() as i32:
                            if bind_syms.get(bi as i64) == k_sym:
                                exists_k = true
                                break
                        if not exists_k:
                            bind_syms.push(k_sym)
                            bind_tys.push(key_ty)
                if val_ty != 0 and self.pool.kind(v_node) == NK_TYPE_NAMED():
                    let v_sym = self.pool.get_data0(v_node)
                    var is_tp_v = false
                    for ti in 0..tp_syms.len() as i32:
                        if tp_syms.get(ti as i64) == v_sym:
                            is_tp_v = true
                            break
                    if is_tp_v:
                        var exists_v = false
                        for bi in 0..bind_syms.len() as i32:
                            if bind_syms.get(bi as i64) == v_sym:
                                exists_v = true
                                break
                        if not exists_v:
                            bind_syms.push(v_sym)
                            bind_tys.push(val_ty)
                continue

            if g_name == "HashSet" and g_count == 1:
                let inner = self.pool.get_extra(g_extra)
                if self.pool.kind(inner) == NK_TYPE_NAMED():
                    let inner_sym = self.pool.get_data0(inner)
                    let elem_ty = self.find_hashset_elem_type_by_llvm(arg_ty)
                    if elem_ty != 0:
                        var is_tp = false
                        for ti in 0..tp_syms.len() as i32:
                            if tp_syms.get(ti as i64) == inner_sym:
                                is_tp = true
                                break
                        if is_tp:
                            var exists = false
                            for bi in 0..bind_syms.len() as i32:
                                if bind_syms.get(bi as i64) == inner_sym:
                                    exists = true
                                    break
                            if not exists:
                                bind_syms.push(inner_sym)
                                bind_tys.push(elem_ty)
                continue

            if g_name == "Option" and g_count == 1:
                let inner = self.pool.get_extra(g_extra)
                if self.pool.kind(inner) == NK_TYPE_NAMED():
                    let inner_sym = self.pool.get_data0(inner)
                    let payload_ty = self.find_option_payload_type_by_llvm(arg_ty)
                    if payload_ty != 0:
                        var is_tp = false
                        for ti in 0..tp_syms.len() as i32:
                            if tp_syms.get(ti as i64) == inner_sym:
                                is_tp = true
                                break
                        if is_tp:
                            var exists = false
                            for bi in 0..bind_syms.len() as i32:
                                if bind_syms.get(bi as i64) == inner_sym:
                                    exists = true
                                    break
                            if not exists:
                                bind_syms.push(inner_sym)
                                bind_tys.push(payload_ty)
                continue

            if g_name == "Result" and g_count == 2:
                let ok_node = self.pool.get_extra(g_extra)
                let err_node = self.pool.get_extra(g_extra + 1)
                let ok_ty = self.find_result_ok_type_by_llvm(arg_ty)
                let err_ty = self.find_result_err_type_by_llvm(arg_ty)
                if ok_ty != 0 and self.pool.kind(ok_node) == NK_TYPE_NAMED():
                    let ok_sym = self.pool.get_data0(ok_node)
                    var is_tp_ok = false
                    for ti in 0..tp_syms.len() as i32:
                        if tp_syms.get(ti as i64) == ok_sym:
                            is_tp_ok = true
                            break
                    if is_tp_ok:
                        var exists_ok = false
                        for bi in 0..bind_syms.len() as i32:
                            if bind_syms.get(bi as i64) == ok_sym:
                                exists_ok = true
                                break
                        if not exists_ok:
                            bind_syms.push(ok_sym)
                            bind_tys.push(ok_ty)
                if err_ty != 0 and self.pool.kind(err_node) == NK_TYPE_NAMED():
                    let err_sym = self.pool.get_data0(err_node)
                    var is_tp_err = false
                    for ti in 0..tp_syms.len() as i32:
                        if tp_syms.get(ti as i64) == err_sym:
                            is_tp_err = true
                            break
                    if is_tp_err:
                        var exists_err = false
                        for bi in 0..bind_syms.len() as i32:
                            if bind_syms.get(bi as i64) == err_sym:
                                exists_err = true
                                break
                        if not exists_err:
                            bind_syms.push(err_sym)
                            bind_tys.push(err_ty)
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
        mangled = mangled ++ "__" ++ self.llvm_type_mangle(bty)

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
        self.type_binding_types.push(bind_tys.get(bi as i64))
        self.type_bindings_len = self.type_bindings_len + 1

    let mono_param_types: Vec[i64] = Vec.new()
    for pi in 0..param_count:
        let p_type_node = self.pool.get_extra(param_start + pi * 2 + 1)
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
    self.mono_values.insert(mono_key, mono_fn)
    self.mono_types.insert(mono_key, mono_ft)
    self.fn_values.insert(mono_sym, mono_fn)
    self.fn_fn_types.insert(mono_sym, mono_ft)

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
    let saved_vec_local_types = self.vec_local_types
    let saved_hm_local_types = self.hm_local_types
    let saved_enum_local_types = self.enum_local_types
    let saved_expected = self.expected_type
    let saved_expected_node = self.expected_type_node
    let saved_tail_bb = self.tailrec_body_bb
    let saved_tail_sym = self.tailrec_fn_sym
    let saved_tail_allocas = self.tailrec_param_allocas
    let saved_loops = self.capture_loop_state()
    let saved_bb = wl_get_insert_block(self.builder)

    self.current_function = mono_fn
    self.current_ret_type = mono_ret_ty
    self.current_method_owner_sym = 0
    let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
    let fresh_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
    let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
    let fresh_local_pointees: HashMap[i32, i32] = HashMap.new()
    let fresh_task_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
    let fresh_trait_concrete: HashMap[i32, i32] = HashMap.new()
    let fresh_vec_local_types: HashMap[i32, i64] = HashMap.new()
    let fresh_hm_local_types: HashMap[i32, i32] = HashMap.new()
    let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
    let fresh_scope_syms: Vec[i32] = Vec.new()
    let fresh_scope_allocas: Vec[i64] = Vec.new()
    let fresh_scope_types: Vec[i64] = Vec.new()
    let fresh_defer_stack: Vec[i32] = Vec.new()
    let fresh_tail_allocas: Vec[i64] = Vec.new()
    self.local_allocas = fresh_local_allocas
    self.local_types = fresh_local_types
    self.local_muts = fresh_local_muts
    self.local_fn_sigs = fresh_local_fn_sigs
    self.local_pointee_structs = fresh_local_pointees
    self.task_locals = fresh_task_locals
    self.trait_locals = fresh_trait_locals
    self.trait_local_concrete_types = fresh_trait_concrete
    self.vec_local_types = fresh_vec_local_types
    self.hm_local_types = fresh_hm_local_types
    self.enum_local_types = fresh_enum_local_types
    self.scope_local_syms = fresh_scope_syms
    self.scope_local_allocas = fresh_scope_allocas
    self.scope_local_types = fresh_scope_types
    self.scope_local_count = 0
    self.defer_stack = fresh_defer_stack
    self.expected_type = mono_ret_ty
    self.expected_type_node = 0
    self.tailrec_body_bb = 0
    self.tailrec_fn_sym = 0
    self.tailrec_param_allocas = fresh_tail_allocas
    self.reset_loop_state()

    let entry = wl_append_bb(self.context, mono_fn, "entry")
    wl_position_at_end(self.builder, entry)
    for pi in 0..param_count:
        let p_name = self.pool.get_extra(param_start + pi * 2)
        let p_type_node = self.pool.get_extra(param_start + pi * 2 + 1)
        let p_val = wl_get_param(mono_fn, pi)
        let p_ty = wl_type_of(p_val)
        let p_alloca = wl_build_alloca(self.builder, p_ty)
        wl_build_store(self.builder, p_val, p_alloca)
        self.record_local(p_name, p_alloca, p_ty, 1)
        self.record_local_container_type(p_name, p_type_node)
        if p_type_node != 0:
            let pk = self.pool.kind(p_type_node)
            if pk == NK_TYPE_FN():
                self.record_local_fn_sig(p_name, self.build_fn_type_from_ast(p_type_node))
            let dyn_trait = self.dyn_trait_from_type_node(p_type_node)
            if dyn_trait != 0:
                self.record_trait_local(p_name, dyn_trait)

    let body_val = self.gen_expr(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        if mono_ret_ty == wl_void_type(self.context):
            let _ = wl_build_ret_void(self.builder)
        else:
            let _ = wl_build_ret(self.builder, self.coerce_value_to_type(body_val, mono_ret_ty))

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
    self.vec_local_types = saved_vec_local_types
    self.hm_local_types = saved_hm_local_types
    self.enum_local_types = saved_enum_local_types
    self.scope_local_syms = saved_scope_syms
    self.scope_local_allocas = saved_scope_allocas
    self.scope_local_types = saved_scope_types
    self.scope_local_count = saved_scope_count
    self.defer_stack = saved_defer
    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    self.tailrec_body_bb = saved_tail_bb
    self.tailrec_fn_sym = saved_tail_sym
    self.tailrec_param_allocas = saved_tail_allocas
    self.restore_loop_state(saved_loops)
    self.type_binding_syms = saved_bind_syms
    self.type_binding_types = saved_bind_tys
    self.type_bindings_len = saved_bind_len
    if saved_bb != 0:
        wl_position_at_end(self.builder, saved_bb)

    let coerced = self.coerce_call_args_for_fn_value(mono_sym, mono_fn, args_start, 0, arg_vals, arg_count, "call " ++ mangled, call_node)
    wl_build_call(self.builder, mono_ft, mono_fn, vec_data_i64(&coerced), arg_count)

// ── Call expression ───────────────────────────────────────────────

fn Codegen.gen_call(self: Codegen, node: i32) -> i64:
    let callee_node = self.pool.get_data0(node)
    let args_start = self.pool.get_data1(node)
    let arg_count = self.pool.get_data2(node)

    // Method call: expr.method(args)
    if self.pool.kind(callee_node) == NK_FIELD_ACCESS():
        return self.gen_method_call(node)

    // Direct call by name
    if self.pool.kind(callee_node) == NK_IDENT():
        let fn_sym = self.pool.get_data0(callee_node)
        var fn_name = self.intern.resolve(fn_sym)
        if fn_name.len() == 0:
            fn_name = self.ident_text_from_node(callee_node)
        var dotted_owner = ""
        var dotted_method = ""
        var last_dot = 0 - 1
        for di in 0..fn_name.len() as i32:
            if fn_name.byte_at(di as i64) == 46:
                last_dot = di
        if last_dot > 0 and last_dot + 1 < fn_name.len() as i32:
            dotted_owner = fn_name.slice(0, last_dot as i64)
            dotted_method = fn_name.slice((last_dot + 1) as i64, fn_name.len())
        var lookup_sym = fn_sym
        if fn_name.len() > 0:
            lookup_sym = self.intern.intern(fn_name)

        if dotted_method == "new" and arg_count == 0:
            if dotted_owner == "Vec":
                return self.gen_builtin_vec_new(self.expected_type, self.expected_type_node)
            if dotted_owner == "HashMap":
                return self.gen_builtin_hashmap_new(self.expected_type, self.expected_type_node)

        if fn_name == "eprintln":
            return self.gen_eprintln(args_start, arg_count)
        if fn_name == "todo" or fn_name == "unreachable":
            return self.gen_diverge_builtin(args_start, arg_count)

        let has_direct_fn = self.fn_values.get(lookup_sym).is_some()
        let has_generic_fn = self.generic_fns.get(lookup_sym).is_some()
        if not has_direct_fn and not has_generic_fn:
            // Built-in channels use runtime fiber primitives and are only
            // active when no user-defined function shadows the name.
            if fn_name == "Channel":
                return self.gen_channel_create(args_start, arg_count)
            if fn_name == "send":
                return self.gen_channel_send(args_start, arg_count)
            if fn_name == "recv":
                return self.gen_channel_recv(args_start, arg_count)
            if fn_name == "close":
                return self.gen_channel_close(args_start, arg_count)

        // Built-in: Some/None/Ok/Err
        if fn_name == "Some" and arg_count == 1:
            let arg_node = self.pool.get_extra(args_start)
            let arg = self.gen_expr(arg_node)
            let opt_ty = self.get_or_create_option_type(wl_type_of(arg))
            return self.build_option_some(arg, opt_ty)
        if fn_name == "None":
            if self.expected_type != 0:
                return self.build_option_none(self.expected_type)
            let i32_ty = wl_i32_type(self.context)
            let opt_ty = self.get_or_create_option_type(i32_ty)
            return self.build_option_none(opt_ty)
        if fn_name == "Ok" and arg_count == 1:
            let arg_node = self.pool.get_extra(args_start)
            let arg = self.gen_expr(arg_node)
            if self.expected_type != 0:
                return self.build_result_ok(arg, self.expected_type)
            return arg
        if fn_name == "Err" and arg_count == 1:
            let arg_node = self.pool.get_extra(args_start)
            let arg = self.gen_expr(arg_node)
            if self.expected_type != 0:
                return self.build_result_err(arg, self.expected_type)
            return arg

        // Enum variant constructor calls: Variant(args...)
        let enum_variant = self.gen_enum_variant_call(lookup_sym, args_start, arg_count)
        if enum_variant != 0:
            return enum_variant

        // Tail-call optimization
        if self.tailrec_body_bb != 0 and lookup_sym == self.tailrec_fn_sym:
            return self.gen_tailrec_call(args_start, arg_count)

        // Regular function call
        var call_sym = fn_sym
        var fv = self.fn_values.get(call_sym)
        var ft = self.fn_fn_types.get(call_sym)
        if (not fv.is_some() or not ft.is_some()) and lookup_sym != call_sym:
            call_sym = lookup_sym
            fv = self.fn_values.get(call_sym)
            ft = self.fn_fn_types.get(call_sym)
        if fv.is_some() and ft.is_some():
            let args: Vec[i64] = Vec.new()
            for ai in 0..arg_count:
                let arg_node = self.pool.get_extra(args_start + ai)
                let arg = self.gen_expr(arg_node)
                args.push(arg)
            let call_name = if fn_name.len() > 0: fn_name else: self.function_symbol_name(call_sym)
            let coerced = self.coerce_call_args_for_fn_value(call_sym, fv.unwrap() as i64, args_start, 0, args, arg_count, "call " ++ call_name, node)
            return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&coerced), arg_count)

        // Generic function call: instantiate a concrete specialization.
        let gf = self.generic_fns.get(lookup_sym)
        if gf.is_some():
            return self.monomorphize_generic_call(lookup_sym, gf.unwrap(), args_start, arg_count, node)

        // Fallback for imported/module-level symbols when internal symbol-key
        // maps do not contain the function entry but LLVM module lookup does.
        let named_f = wl_get_named_function(self.llmod, fn_name)
        if named_f != 0:
            let named_ft = wl_global_get_value_type(named_f)
            if wl_get_type_kind(named_ft) == wl_function_type_kind():
                let args: Vec[i64] = Vec.new()
                for ai in 0..arg_count:
                    let arg_node = self.pool.get_extra(args_start + ai)
                    args.push(self.gen_expr(arg_node))
                let coerced = self.coerce_call_args_for_fn_value(lookup_sym, named_f, args_start, 0, args, arg_count, "call " ++ fn_name, node)
                return wl_build_call(self.builder, named_ft, named_f, vec_data_i64(&coerced), arg_count)

        // Minimal c_import fallback: support unresolved printf calls by
        // declaring a variadic printf symbol in IR and emitting the call.
        if fn_name == "printf":
            let printf_fn = self.ensure_printf_declared()
            let printf_ty = self.get_printf_fn_type()
            let args: Vec[i64] = Vec.new()
            for ai in 0..arg_count:
                let arg_node = self.pool.get_extra(args_start + ai)
                args.push(self.gen_expr(arg_node))
            return wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(&args), arg_count)

        // Check if it's a function pointer local
        let la = self.local_allocas.get(lookup_sym)
        if la.is_some():
            let fs = self.local_fn_sigs.get(lookup_sym)
            if fs.is_some():
                let fn_ptr_alloca = la.unwrap() as i64
                let fn_ty_opt = self.local_types.get(lookup_sym)
                if fn_ty_opt.is_some():
                    let fat_ptr = wl_build_load(self.builder, fn_ty_opt.unwrap() as i64, fn_ptr_alloca)
                    let fn_ptr = wl_build_extract_value(self.builder, fat_ptr, 0)
                    let ctx_ptr = wl_build_extract_value(self.builder, fat_ptr, 1)
                    let args: Vec[i64] = Vec.new()
                    args.push(ctx_ptr)
                    for ai in 0..arg_count:
                        let arg_node = self.pool.get_extra(args_start + ai)
                        args.push(self.gen_expr(arg_node))
                    return wl_build_call(self.builder, fs.unwrap() as i64, fn_ptr, vec_data_i64(&args), arg_count + 1)

        let err_name = if fn_name.len() > 0: fn_name else: self.function_symbol_name(fn_sym)
        with_eprintln("error: unsupported call to '" ++ err_name ++ "'")
        with_eprintln("  line " ++ int_to_string(self.span_to_line(node)) ++
            " callee_kind=" ++ int_to_string(self.pool.kind(callee_node)) ++
            " callee_text=" ++ self.ident_text_from_node(callee_node))
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))

    // Indirect call (expression as callee)
    let callee = self.gen_expr(callee_node)
    let args: Vec[i64] = Vec.new()
    for ai in 0..arg_count:
        let arg_node = self.pool.get_extra(args_start + ai)
        args.push(self.gen_expr(arg_node))
    // Try to determine function type
    let callee_ty = wl_type_of(callee)
    if wl_get_type_kind(callee_ty) == wl_pointer_type_kind():
        let gvt = wl_global_get_value_type(callee)
        if wl_get_type_kind(gvt) == wl_function_type_kind():
            return wl_build_call(self.builder, gvt, callee, vec_data_i64(&args), arg_count)
    wl_get_undef(wl_i32_type(self.context))

fn Codegen.ensure_channel_create_decl(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "with_channel_create")
    if existing != 0:
        return existing
    let params: Vec[i64] = Vec.new()
    params.push(wl_i32_type(self.context))
    let fn_ty = wl_function_type(wl_ptr_type(self.context), vec_data_i64(&params), 1, 0)
    wl_add_function(self.llmod, "with_channel_create", fn_ty)

fn Codegen.ensure_channel_send_decl(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "with_channel_send")
    if existing != 0:
        return existing
    let params: Vec[i64] = Vec.new()
    params.push(wl_ptr_type(self.context))
    params.push(wl_i64_type(self.context))
    let fn_ty = wl_function_type(wl_void_type(self.context), vec_data_i64(&params), 2, 0)
    wl_add_function(self.llmod, "with_channel_send", fn_ty)

fn Codegen.ensure_channel_recv_decl(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "with_channel_recv")
    if existing != 0:
        return existing
    let params: Vec[i64] = Vec.new()
    params.push(wl_ptr_type(self.context))
    let fn_ty = wl_function_type(wl_i64_type(self.context), vec_data_i64(&params), 1, 0)
    wl_add_function(self.llmod, "with_channel_recv", fn_ty)

fn Codegen.ensure_channel_close_decl(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "with_channel_close")
    if existing != 0:
        return existing
    let params: Vec[i64] = Vec.new()
    params.push(wl_ptr_type(self.context))
    let fn_ty = wl_function_type(wl_void_type(self.context), vec_data_i64(&params), 1, 0)
    wl_add_function(self.llmod, "with_channel_close", fn_ty)

fn Codegen.gen_channel_create(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    let i32_ty = wl_i32_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    var capacity = wl_const_int(i32_ty, 256, 0)
    if arg_count >= 1:
        let cap_val = self.gen_expr(self.pool.get_extra(args_start))
        capacity = self.coerce_int(cap_val, i32_ty)
    let create_fn = self.ensure_channel_create_decl()
    let create_ty = wl_global_get_value_type(create_fn)
    let args: Vec[i64] = Vec.new()
    args.push(capacity)
    let ch_ptr = wl_build_call(self.builder, create_ty, create_fn, vec_data_i64(&args), 1)
    wl_build_ptr_to_int(self.builder, ch_ptr, i64_ty)

fn Codegen.gen_channel_send(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    if arg_count != 2:
        return wl_get_undef(wl_i32_type(self.context))
    let i64_ty = wl_i64_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let ch_handle = self.gen_expr(self.pool.get_extra(args_start))
    let payload = self.gen_expr(self.pool.get_extra(args_start + 1))
    let ch_i64 = self.coerce_int(ch_handle, i64_ty)
    let payload_i64 = self.coerce_int(payload, i64_ty)
    let ch_ptr = wl_build_int_to_ptr(self.builder, ch_i64, ptr_ty)
    let send_fn = self.ensure_channel_send_decl()
    let send_ty = wl_global_get_value_type(send_fn)
    let args: Vec[i64] = Vec.new()
    args.push(ch_ptr)
    args.push(payload_i64)
    let _ = wl_build_call(self.builder, send_ty, send_fn, vec_data_i64(&args), 2)
    wl_const_int(wl_i32_type(self.context), 0, 0)

fn Codegen.gen_channel_recv(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    if arg_count != 1:
        return wl_get_undef(wl_i32_type(self.context))
    let i32_ty = wl_i32_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let ch_handle = self.gen_expr(self.pool.get_extra(args_start))
    let ch_i64 = self.coerce_int(ch_handle, i64_ty)
    let ch_ptr = wl_build_int_to_ptr(self.builder, ch_i64, ptr_ty)
    let recv_fn = self.ensure_channel_recv_decl()
    let recv_ty = wl_global_get_value_type(recv_fn)
    let args: Vec[i64] = Vec.new()
    args.push(ch_ptr)
    let result_i64 = wl_build_call(self.builder, recv_ty, recv_fn, vec_data_i64(&args), 1)
    if self.expected_type == i64_ty:
        return result_i64
    wl_build_trunc(self.builder, result_i64, i32_ty)

fn Codegen.gen_channel_close(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    if arg_count != 1:
        return wl_get_undef(wl_i32_type(self.context))
    let i64_ty = wl_i64_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let ch_handle = self.gen_expr(self.pool.get_extra(args_start))
    let ch_i64 = self.coerce_int(ch_handle, i64_ty)
    let ch_ptr = wl_build_int_to_ptr(self.builder, ch_i64, ptr_ty)
    let close_fn = self.ensure_channel_close_decl()
    let close_ty = wl_global_get_value_type(close_fn)
    let args: Vec[i64] = Vec.new()
    args.push(ch_ptr)
    let _ = wl_build_call(self.builder, close_ty, close_fn, vec_data_i64(&args), 1)
    wl_const_int(wl_i32_type(self.context), 0, 0)

fn Codegen.gen_tailrec_call(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    // Store args to param allocas, then branch to body BB
    var i = 0
    while i < arg_count and i < self.tailrec_param_allocas.len() as i32:
        let arg_node = self.pool.get_extra(args_start + i)
        let arg = self.gen_expr(arg_node)
        let alloca = self.tailrec_param_allocas.get(i as i64)
        wl_build_store(self.builder, arg, alloca)
        i = i + 1
    wl_build_br(self.builder, self.tailrec_body_bb)
    // Position in dead block
    let dead_bb = wl_append_bb(self.context, self.current_function, "tailrec.dead")
    wl_position_at_end(self.builder, dead_bb)
    wl_get_undef(wl_void_type(self.context))

// ── Method call ───────────────────────────────────────────────────

fn Codegen.gen_method_call(self: Codegen, node: i32) -> i64:
    let callee_node = self.pool.get_data0(node)
    let args_start = self.pool.get_data1(node)
    let arg_count = self.pool.get_data2(node)

    let obj_node = self.pool.get_data0(callee_node)
    let method_sym = self.pool.get_data1(callee_node)
    var method_name = self.intern.resolve(method_sym)
    if method_name.len() == 0:
        method_name = self.method_text_from_field_access(callee_node)
    var method_lookup_sym = method_sym
    if method_name.len() > 0:
        method_lookup_sym = self.intern.intern(method_name)

    let builtin_static = self.gen_builtin_static_call(obj_node, method_name, arg_count)
    if builtin_static != 0:
        return builtin_static

    // Static method call: TypeName.method(args)
    var static_type_sym = 0
    if self.pool.kind(obj_node) == NK_IDENT():
        let obj_sym = self.pool.get_data0(obj_node)
        if self.struct_type_map.get(obj_sym).is_some() or self.enum_type_map.get(obj_sym).is_some():
            static_type_sym = obj_sym
        if static_type_sym == 0:
            let obj_name = self.ident_text_from_node(obj_node)
            if obj_name.len() > 0:
                let alias_sym = self.intern.intern(obj_name)
                if self.struct_type_map.get(alias_sym).is_some() or self.enum_type_map.get(alias_sym).is_some():
                    static_type_sym = alias_sym
    if static_type_sym != 0:
        let type_name = self.intern.resolve(static_type_sym)
        let mangled = type_name ++ "." ++ method_name
        let fn_sym = self.intern.intern(mangled)
        let fv = self.fn_values.get(fn_sym)
        let ft = self.fn_fn_types.get(fn_sym)
        if fv.is_some() and ft.is_some():
            let args: Vec[i64] = Vec.new()
            for ai in 0..arg_count:
                let arg_node = self.pool.get_extra(args_start + ai)
                args.push(self.gen_expr(arg_node))
            let coerced = self.coerce_call_args_for_fn_value(fn_sym, fv.unwrap() as i64, args_start, 0, args, arg_count, "method " ++ mangled, node)
            return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&coerced), arg_count)

    let obj = self.gen_expr(obj_node)
    let obj_ty = wl_type_of(obj)
    if self.debug_method_dispatch_enabled() and method_name == "get":
        let vec_idx = self.find_vec_cache_index_by_llvm(obj_ty)
        let hm_idx = self.find_hashmap_cache_index_by_llvm(obj_ty)
        var msg = "[method-dispatch] method=get"
        if self.current_function_name_sym != 0:
            msg = msg ++ " fn=" ++ self.function_symbol_name(self.current_function_name_sym)
        msg = msg ++ " obj_ty=" ++ self.llvm_type_mangle(obj_ty)
        msg = msg ++ " vec_idx=" ++ int_to_string(vec_idx)
        msg = msg ++ " hm_idx=" ++ int_to_string(hm_idx)
        with_eprintln(msg)

    if method_name == "track":
        if arg_count > 0:
            // async scope track is a task-handle passthrough in the current
            // self-host runtime contract.
            return self.gen_expr(self.pool.get_extra(args_start))
        return wl_get_undef(wl_void_type(self.context))

    // Find the type name for this object
    let type_sym = self.find_struct_type_by_llvm(obj_ty)

    // String methods
    let str_sym = self.intern.intern("str")
    if type_sym == str_sym:
        return self.gen_str_method(method_name, obj, args_start, arg_count)

    // Vec methods
    let vc = self.find_vec_cache_index_by_llvm(obj_ty)
    if vc >= 0:
        return self.gen_vec_method(method_name, obj, args_start, arg_count, obj_node)

    // HashMap methods
    let hmc = self.infer_hashmap_cache_index_from_receiver(obj_node, obj_ty)
    if hmc >= 0:
        return self.gen_hashmap_method(method_name, obj, args_start, arg_count, hmc)

    // Option methods (is_some, unwrap, etc.)
    let option_payload_ty = self.find_option_payload_type_by_llvm(obj_ty)
    if option_payload_ty != 0:
        return self.gen_option_method(method_name, obj, args_start, arg_count)

    // Auto-generated enum accessors: .is_X() and .as_X[_ref|_mut]().
    let enum_accessor = self.gen_enum_accessor_method(callee_node, obj_node, obj, obj_ty, method_name, arg_count)
    if enum_accessor != 0:
        return enum_accessor

    // Try Type.method lookup
    if type_sym != 0:
        let type_name = self.intern.resolve(type_sym)
        let mangled = type_name ++ "." ++ method_name
        let fn_sym = self.intern.intern(mangled)
        let fv = self.fn_values.get(fn_sym)
        let ft = self.fn_fn_types.get(fn_sym)
        if fv.is_some() and ft.is_some():
            let args: Vec[i64] = Vec.new()
            // Check if method takes self by pointer
            let is_ref = self.fn_ref_param_starts.get(fn_sym).is_some()
            if is_ref:
                // Pass a true mutable receiver pointer (not a temporary copy).
                args.push(self.get_mutable_receiver_ptr(obj_node, obj, obj_ty))
            else:
                args.push(obj)
            for ai in 0..arg_count:
                let arg_node = self.pool.get_extra(args_start + ai)
                args.push(self.gen_expr(arg_node))
            let coerced = self.coerce_call_args_for_fn_value(fn_sym, fv.unwrap() as i64, args_start, 1, args, arg_count + 1, "method " ++ mangled, node)
            return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&coerced), arg_count + 1)

    // Check pointer-to-struct methods
    if wl_get_type_kind(obj_ty) == wl_pointer_type_kind():
        if self.pool.kind(obj_node) == NK_IDENT():
            let sym = self.pool.get_data0(obj_node)
            let ps = self.local_pointee_structs.get(sym)
            if ps.is_some():
                let type_name = self.intern.resolve(ps.unwrap())
                let mangled = type_name ++ "." ++ method_name
                let fn_sym = self.intern.intern(mangled)
                let fv = self.fn_values.get(fn_sym)
                let ft = self.fn_fn_types.get(fn_sym)
                if fv.is_some() and ft.is_some():
                    let args: Vec[i64] = Vec.new()
                    args.push(obj)  // already a pointer
                    for ai in 0..arg_count:
                        let arg_node = self.pool.get_extra(args_start + ai)
                        args.push(self.gen_expr(arg_node))
                    let coerced = self.coerce_call_args_for_fn_value(fn_sym, fv.unwrap() as i64, args_start, 1, args, arg_count + 1, "method " ++ mangled, node)
                    return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(&coerced), arg_count + 1)

    // Dyn trait method dispatch via fat-pointer {data_ptr, vtable_ptr}.
    if self.pool.kind(obj_node) == NK_IDENT():
        let obj_sym = self.pool.get_data0(obj_node)
        let trait_sym = self.trait_locals.get(obj_sym)
        if trait_sym.is_some():
            let concrete_sym = self.trait_local_concrete_types.get(obj_sym)
            if concrete_sym.is_some():
                let direct = self.gen_known_concrete_dispatch(obj, concrete_sym.unwrap(), method_lookup_sym, args_start, arg_count, node)
                if direct != 0:
                    return direct
            return self.gen_dyn_dispatch(obj, trait_sym.unwrap(), method_lookup_sym, args_start, arg_count)

    wl_get_undef(wl_i32_type(self.context))

fn Codegen.get_mutable_receiver_ptr(self: Codegen, recv_node: i32, recv_val: i64, recv_ty: i64) -> i64:
    let rk = self.pool.kind(recv_node)
    if rk == NK_IDENT():
        let sym = self.pool.get_data0(recv_node)
        let alloca = self.lookup_local_alloca(sym)
        if alloca != 0:
            let local_ty = self.lookup_local_type(sym)
            if local_ty != 0:
                let pointee_sym = self.lookup_local_pointee_struct(sym)
                if wl_get_type_kind(local_ty) == wl_pointer_type_kind() and pointee_sym != 0:
                    return wl_build_load(self.builder, local_ty, alloca)
            return alloca
    if rk == NK_FIELD_ACCESS():
        let base = self.pool.get_data0(recv_node)
        let field = self.pool.get_data1(recv_node)
        let ptr = self.gen_field_access_ptr(base, field)
        if ptr != 0:
            return ptr
    if rk == NK_UNARY():
        let uop = self.pool.get_data0(recv_node)
        if uop == UOP_DEREF():
            return self.gen_expr(self.pool.get_data1(recv_node))
    if wl_get_type_kind(recv_ty) == wl_pointer_type_kind():
        return recv_val
    let alloca = wl_build_alloca(self.builder, recv_ty)
    wl_build_store(self.builder, recv_val, alloca)
    alloca

// ── While loop ────────────────────────────────────────────────────

fn Codegen.gen_while(self: Codegen, node: i32) -> i64:
    let cond_node = self.pool.get_data0(node)
    let body_node = self.pool.get_data1(node)
    let label_sym = self.pool.get_data2(node)
    let cond_bb = wl_append_bb(self.context, self.current_function, "while.cond")
    let body_bb = wl_append_bb(self.context, self.current_function, "while.body")
    let end_bb = wl_append_bb(self.context, self.current_function, "while.end")
    wl_build_br(self.builder, cond_bb)
    wl_position_at_end(self.builder, cond_bb)
    let cond = self.gen_expr(cond_node)
    var bool_cond = cond
    let cond_ty = wl_type_of(cond)
    if cond_ty != wl_i1_type(self.context):
        bool_cond = wl_build_icmp(self.builder, wl_int_ne(), cond, wl_const_int(cond_ty, 0, 0))
    wl_build_cond_br(self.builder, bool_cond, body_bb, end_bb)
    // Push loop context
    self.push_loop_context(end_bb, cond_bb, 0, label_sym)
    wl_position_at_end(self.builder, body_bb)
    self.gen_expr_discard(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, cond_bb)
    // Pop loop context
    self.pop_loop_context()
    wl_position_at_end(self.builder, end_bb)
    wl_get_undef(wl_void_type(self.context))

// ── Loop ──────────────────────────────────────────────────────────

fn Codegen.gen_loop(self: Codegen, node: i32) -> i64:
    let body_node = self.pool.get_data0(node)
    let label_sym = self.pool.get_data1(node)
    let body_bb = wl_append_bb(self.context, self.current_function, "loop.body")
    let end_bb = wl_append_bb(self.context, self.current_function, "loop.end")
    wl_build_br(self.builder, body_bb)
    self.push_loop_context(end_bb, body_bb, 0, label_sym)
    wl_position_at_end(self.builder, body_bb)
    self.gen_expr_discard(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, body_bb)
    self.pop_loop_context()
    wl_position_at_end(self.builder, end_bb)
    wl_get_undef(wl_void_type(self.context))

// ── For loop ──────────────────────────────────────────────────────

fn Codegen.gen_for(self: Codegen, node: i32) -> i64:
    let binding_sym = self.pool.get_data0(node)
    let iterable_node = self.pool.get_data1(node)
    let body_node = self.pool.get_data2(node)

    let iterable = self.gen_expr(iterable_node)
    let iter_ty = wl_type_of(iterable)
    let tk = wl_get_type_kind(iter_ty)

    // Range-based for
    if self.pool.kind(iterable_node) == NK_RANGE():
        return self.gen_for_range(binding_sym, iterable_node, body_node)

    // Array-based for
    if tk == wl_array_type_kind():
        return self.gen_for_array(binding_sym, iterable, body_node)

    // Default: treat as range 0..n
    wl_get_undef(wl_void_type(self.context))

fn Codegen.gen_for_range(self: Codegen, binding_sym: i32, range_node: i32, body_node: i32) -> i64:
    let start_node = self.pool.get_data0(range_node)
    let end_node = self.pool.get_data1(range_node)
    let inclusive = self.pool.get_data2(range_node)
    let start_val = if start_node != 0: self.gen_expr(start_node) else wl_const_int(wl_i32_type(self.context), 0, 0)
    let end_val = self.gen_expr(end_node)
    let iter_ty = wl_type_of(start_val)
    let alloca = self.create_entry_alloca(iter_ty)
    wl_build_store(self.builder, start_val, alloca)
    self.record_local(binding_sym, alloca, iter_ty, 1)
    let cond_bb = wl_append_bb(self.context, self.current_function, "for.cond")
    let body_bb = wl_append_bb(self.context, self.current_function, "for.body")
    let inc_bb = wl_append_bb(self.context, self.current_function, "for.inc")
    let end_bb = wl_append_bb(self.context, self.current_function, "for.end")
    wl_build_br(self.builder, cond_bb)
    wl_position_at_end(self.builder, cond_bb)
    let cur = wl_build_load(self.builder, iter_ty, alloca)
    let end_coerced = self.coerce_int(end_val, iter_ty)
    var cmp_pred = wl_int_slt()
    if inclusive != 0: cmp_pred = wl_int_sle()
    let cond = wl_build_icmp(self.builder, cmp_pred, cur, end_coerced)
    wl_build_cond_br(self.builder, cond, body_bb, end_bb)
    self.push_loop_context(end_bb, inc_bb, 0, 0)
    wl_position_at_end(self.builder, body_bb)
    self.gen_expr_discard(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, inc_bb)
    wl_position_at_end(self.builder, inc_bb)
    let next = wl_build_add(self.builder, wl_build_load(self.builder, iter_ty, alloca), wl_const_int(iter_ty, 1, 0))
    wl_build_store(self.builder, next, alloca)
    wl_build_br(self.builder, cond_bb)
    self.pop_loop_context()
    wl_position_at_end(self.builder, end_bb)
    wl_get_undef(wl_void_type(self.context))

fn Codegen.gen_for_array(self: Codegen, binding_sym: i32, arr: i64, body_node: i32) -> i64:
    let arr_ty = wl_type_of(arr)
    let elem_ty = wl_get_element_type(arr_ty)
    let arr_len = wl_get_array_length(arr_ty)
    let arr_alloca = wl_build_alloca(self.builder, arr_ty)
    wl_build_store(self.builder, arr, arr_alloca)
    let i_ty = wl_i64_type(self.context)
    let i_alloca = self.create_entry_alloca(i_ty)
    wl_build_store(self.builder, wl_const_int(i_ty, 0, 0), i_alloca)
    let elem_alloca = self.create_entry_alloca(elem_ty)
    self.record_local(binding_sym, elem_alloca, elem_ty, 0)
    let cond_bb = wl_append_bb(self.context, self.current_function, "for.cond")
    let body_bb = wl_append_bb(self.context, self.current_function, "for.body")
    let inc_bb = wl_append_bb(self.context, self.current_function, "for.inc")
    let end_bb = wl_append_bb(self.context, self.current_function, "for.end")
    wl_build_br(self.builder, cond_bb)
    wl_position_at_end(self.builder, cond_bb)
    let cur_i = wl_build_load(self.builder, i_ty, i_alloca)
    let cond = wl_build_icmp(self.builder, wl_int_slt(), cur_i, wl_const_int(i_ty, arr_len, 0))
    wl_build_cond_br(self.builder, cond, body_bb, end_bb)
    self.push_loop_context(end_bb, inc_bb, 0, 0)
    wl_position_at_end(self.builder, body_bb)
    let zero = wl_const_int(i_ty, 0, 0)
    let indices: Vec[i64] = Vec.new()
    indices.push(zero)
    indices.push(wl_build_load(self.builder, i_ty, i_alloca))
    let elem_ptr = wl_build_gep(self.builder, arr_ty, arr_alloca, vec_data_i64(&indices), 2)
    let elem = wl_build_load(self.builder, elem_ty, elem_ptr)
    wl_build_store(self.builder, elem, elem_alloca)
    self.gen_expr_discard(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, inc_bb)
    wl_position_at_end(self.builder, inc_bb)
    let next = wl_build_add(self.builder, wl_build_load(self.builder, i_ty, i_alloca), wl_const_int(i_ty, 1, 0))
    wl_build_store(self.builder, next, i_alloca)
    wl_build_br(self.builder, cond_bb)
    self.pop_loop_context()
    wl_position_at_end(self.builder, end_bb)
    wl_get_undef(wl_void_type(self.context))

// ── Break / Continue ──────────────────────────────────────────────

fn Codegen.gen_break(self: Codegen, node: i32) -> i64:
    let value_node = self.pool.get_data0(node)
    let label_sym = self.pool.get_data1(node)
    if self.loop_depth > 0:
        let idx = self.loop_depth - 1
        let bb: i64 = self.loop_break_target(idx)
        if value_node != 0:
            let val = self.gen_expr(value_node)
            let ra: i64 = self.loop_result_alloca_at(idx)
            if ra != 0:
                wl_build_store(self.builder, val, ra)
        wl_build_br(self.builder, bb)
        let dead_bb = wl_append_bb(self.context, self.current_function, "break.dead")
        wl_position_at_end(self.builder, dead_bb)
    wl_get_undef(wl_void_type(self.context))

fn Codegen.gen_continue(self: Codegen, node: i32) -> i64:
    if self.loop_depth > 0:
        let idx = self.loop_depth - 1
        let bb: i64 = self.loop_continue_target(idx)
        wl_build_br(self.builder, bb)
        let dead_bb = wl_append_bb(self.context, self.current_function, "continue.dead")
        wl_position_at_end(self.builder, dead_bb)
    wl_get_undef(wl_void_type(self.context))

// ── Match expression ──────────────────────────────────────────────

fn Codegen.gen_match(self: Codegen, node: i32) -> i64:
    let subject_node = self.pool.get_data0(node)
    let arms_start = self.pool.get_data1(node)
    let arm_count = self.pool.get_data2(node)
    var subject = self.gen_expr(subject_node)
    var subject_ty = wl_type_of(subject)

    // Method `self` values are often lowered as pointers; load enum/struct
    // pointees so match lowering can build a switch over tags/integers.
    if wl_get_type_kind(subject_ty) == wl_pointer_type_kind() and self.pool.kind(subject_node) == NK_IDENT():
        let subj_sym = self.pool.get_data0(subject_node)
        let ps = self.local_pointee_structs.get(subj_sym)
        if ps.is_some():
            let pointee_sym = ps.unwrap()
            var pointee_ty: i64 = 0
            let et = self.enum_type_map.get(pointee_sym)
            if et.is_some():
                pointee_ty = self.enum_llvm_types.get(et.unwrap() as i64)
            else:
                let st = self.struct_type_map.get(pointee_sym)
                if st.is_some():
                    pointee_ty = self.struct_llvm_types.get(st.unwrap() as i64)
            if pointee_ty != 0:
                subject = wl_build_load(self.builder, pointee_ty, subject)
                subject_ty = pointee_ty

    let merge_bb = wl_append_bb(self.context, self.current_function, "match.end")

    // Check if matching on integer or enum
    let is_int = wl_get_type_kind(subject_ty) == wl_integer_type_kind()

    // For simple int/enum matching, use switch
    if is_int or wl_get_type_kind(subject_ty) == wl_struct_type_kind():
        var tag = subject
        if wl_get_type_kind(subject_ty) == wl_struct_type_kind():
            tag = wl_build_extract_value(self.builder, subject, 0)

        // Collect arms
        let default_bb = wl_append_bb(self.context, self.current_function, "match.default")
        let sw = wl_build_switch(self.builder, tag, default_bb, arm_count)
        var result_alloca: i64 = 0
        var has_result = false
        var ai = 0
        while ai < arm_count:
            let arm_node = self.pool.get_extra(arms_start + ai)
            let pat_node = self.pool.get_data0(arm_node)
            let body_node = self.pool.get_data1(arm_node)
            let arm_bb = wl_append_bb(self.context, self.current_function, "match.arm")

            let pk = self.pool.kind(pat_node)
            if pk == NK_PAT_INT():
                let pat_val = self.pool.get_data0(pat_node) as i64
                wl_add_case(sw, wl_const_int(wl_type_of(tag), pat_val, 1), arm_bb)
            else if pk == NK_PAT_BOOL():
                let pat_val = self.pool.get_data0(pat_node) as i64
                wl_add_case(sw, wl_const_int(wl_i1_type(self.context), pat_val, 0), arm_bb)
            else if pk == NK_PAT_VARIANT() or pk == NK_PAT_ENUM_SHORTHAND():
                let v_name = self.pool.get_data0(pat_node)
                // Find variant index
                let v_idx = self.find_variant_index(subject_ty, v_name)
                if v_idx >= 0:
                    wl_add_case(sw, wl_const_int(wl_i32_type(self.context), v_idx as i64, 0), arm_bb)
            else if pk == NK_PAT_WILDCARD() or pk == NK_PAT_IDENT():
                // Default arm
                wl_position_at_end(self.builder, arm_bb)
                if wl_get_bb_terminator(arm_bb) == 0:
                    wl_build_unreachable(self.builder)
                wl_position_at_end(self.builder, default_bb)
                if pk == NK_PAT_IDENT():
                    let bind_sym = self.pool.get_data0(pat_node)
                    let alloca = self.create_entry_alloca(subject_ty)
                    wl_build_store(self.builder, subject, alloca)
                    self.record_local(bind_sym, alloca, subject_ty, 0)
                let body_val = self.gen_expr(body_node)
                if not has_result and wl_type_of(body_val) != wl_void_type(self.context):
                    result_alloca = self.create_entry_alloca(wl_type_of(body_val))
                    has_result = true
                if has_result and result_alloca != 0:
                    wl_build_store(self.builder, body_val, result_alloca)
                if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
                    wl_build_br(self.builder, merge_bb)
                ai = ai + 1
                continue

            // Generate arm body
            wl_position_at_end(self.builder, arm_bb)
            // Bind payload for variant patterns
            if pk == NK_PAT_VARIANT() or pk == NK_PAT_ENUM_SHORTHAND():
                let v_bind_count = self.pool.get_data2(pat_node)
                if v_bind_count > 0:
                    let v_extra = self.pool.get_data1(pat_node)
                    let raw_payload = wl_build_extract_value(self.builder, subject, 1)
                    var payload_val = raw_payload
                    var payload_ty = wl_type_of(raw_payload)

                    let variant_sym = self.pool.get_data0(pat_node)
                    let variant_idx = self.find_variant_index(subject_ty, variant_sym)
                    if variant_idx >= 0:
                        let es = self.enum_by_llvm.get(subject_ty)
                        if es.is_some():
                            let et = self.enum_type_map.get(es.unwrap())
                            if et.is_some():
                                let v_start = self.enum_variant_starts.get(et.unwrap() as i64)
                                let declared_payload_ty = self.enum_variant_payloads.get((v_start + variant_idx) as i64)
                                if declared_payload_ty != 0:
                                    let raw_ty = wl_type_of(raw_payload)
                                    let raw_alloca = wl_build_alloca(self.builder, raw_ty)
                                    wl_build_store(self.builder, raw_payload, raw_alloca)
                                    let cast_ptr = wl_build_bitcast(self.builder, raw_alloca, wl_ptr_type(self.context))
                                    payload_val = wl_build_load(self.builder, declared_payload_ty, cast_ptr)
                                    payload_ty = declared_payload_ty

                    let payload_fields = if wl_get_type_kind(payload_ty) == wl_struct_type_kind(): wl_count_struct_elem_types(payload_ty) else: 0
                    for bi in 0..v_bind_count:
                        var bind_sym = 0
                        if pk == NK_PAT_VARIANT():
                            let bind_pat = self.pool.get_extra(v_extra + bi)
                            if self.pool.kind(bind_pat) == NK_PAT_IDENT():
                                bind_sym = self.pool.get_data0(bind_pat)
                            else:
                                continue
                        else:
                            bind_sym = self.pool.get_extra(v_extra + bi)
                        if bind_sym == 0:
                            continue
                        var bind_val = payload_val
                        if v_bind_count > 1 and payload_fields > bi:
                            bind_val = wl_build_extract_value(self.builder, payload_val, bi)
                        let bind_ty = wl_type_of(bind_val)
                        let alloca = self.create_entry_alloca(bind_ty)
                        wl_build_store(self.builder, bind_val, alloca)
                        self.record_local(bind_sym, alloca, bind_ty, 0)

            let body_val = self.gen_expr(body_node)
            if not has_result and wl_type_of(body_val) != wl_void_type(self.context):
                result_alloca = self.create_entry_alloca(wl_type_of(body_val))
                has_result = true
            if has_result and result_alloca != 0:
                wl_build_store(self.builder, body_val, result_alloca)
            if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
                wl_build_br(self.builder, merge_bb)
            ai = ai + 1

        // Default fallthrough
        wl_position_at_end(self.builder, default_bb)
        if wl_get_bb_terminator(default_bb) == 0:
            wl_build_br(self.builder, merge_bb)

        wl_position_at_end(self.builder, merge_bb)
        if has_result and result_alloca != 0:
            return wl_build_load(self.builder, wl_get_allocated_type(result_alloca), result_alloca)

    wl_get_undef(wl_void_type(self.context))

fn Codegen.find_variant_index(self: Codegen, enum_ty: i64, variant_sym: i32) -> i32:
    // Prefer deterministic vector-order lookup by LLVM type and variant symbol.
    // This avoids map-key collision issues when multiple enums share a lowered
    // LLVM layout.
    var fallback_idx = 0 - 1
    for ei in 0..self.enum_llvm_types.len() as i32:
        if self.enum_llvm_types.get(ei as i64) != enum_ty:
            continue
        if fallback_idx < 0:
            fallback_idx = ei
        let v_start = self.enum_variant_starts.get(ei as i64)
        let v_count = self.enum_variant_counts.get(ei as i64)
        for vi in 0..v_count:
            if self.enum_variant_names.get((v_start + vi) as i64) == variant_sym:
                return vi
    if fallback_idx >= 0:
        let v_start = self.enum_variant_starts.get(fallback_idx as i64)
        let v_count = self.enum_variant_counts.get(fallback_idx as i64)
        for vi in 0..v_count:
            if self.enum_variant_names.get((v_start + vi) as i64) == variant_sym:
                return vi
    let es = self.enum_by_llvm.get(enum_ty)
    if es.is_some():
        let enum_sym = es.unwrap()
        let et = self.enum_type_map.get(enum_sym)
        if et.is_some():
            let idx = et.unwrap()
            let v_start = self.enum_variant_starts.get(idx as i64)
            let v_count = self.enum_variant_counts.get(idx as i64)
            for i in 0..v_count:
                if self.enum_variant_names.get((v_start + i) as i64) == variant_sym:
                    return i
    0 - 1

fn Codegen.find_enum_index_for_receiver(self: Codegen, obj_node: i32, obj_ty: i64, requested_variant_sym: i32) -> i32:
    // Prefer local tracked enum symbol for stable disambiguation.
    if self.pool.kind(obj_node) == NK_IDENT():
        let sym = self.pool.get_data0(obj_node)
        let es = self.enum_local_types.get(sym)
        if es.is_some():
            let et = self.enum_type_map.get(es.unwrap())
            if et.is_some():
                let idx = et.unwrap()
                if idx >= 0 and idx < self.enum_llvm_types.len() as i32:
                    if self.enum_llvm_types.get(idx as i64) == obj_ty:
                        return idx

    var fallback_idx = 0 - 1
    for ei in 0..self.enum_llvm_types.len() as i32:
        if self.enum_llvm_types.get(ei as i64) != obj_ty:
            continue
        if fallback_idx < 0:
            fallback_idx = ei
        if requested_variant_sym != 0:
            let v_start = self.enum_variant_starts.get(ei as i64)
            let v_count = self.enum_variant_counts.get(ei as i64)
            for vi in 0..v_count:
                if self.enum_variant_names.get((v_start + vi) as i64) == requested_variant_sym:
                    return ei
    fallback_idx

fn Codegen.gen_enum_accessor_method(self: Codegen, callee_node: i32, obj_node: i32, obj: i64, obj_ty: i64, method_name: str, arg_count: i32) -> i64:
    let method_len = method_name.len() as i32
    let is_is = method_len > 3 and method_name.slice(0, 3) == "is_"
    let is_as = method_len > 3 and method_name.slice(0, 3) == "as_"
    if not is_is and not is_as:
        return 0
    if arg_count != 0:
        return 0

    var variant_name = ""
    if is_is:
        variant_name = method_name.slice(3, method_name.len())
    else:
        variant_name = method_name.slice(3, method_name.len())
        if variant_name.len() > 4:
            let suffix = variant_name.slice(variant_name.len() - 4, variant_name.len())
            if suffix == "_ref" or suffix == "_mut":
                variant_name = variant_name.slice(0, variant_name.len() - 4)
    if variant_name.len() == 0:
        return 0

    let variant_sym = self.intern.intern(variant_name)
    let enum_idx = self.find_enum_index_for_receiver(obj_node, obj_ty, variant_sym)
    if enum_idx < 0:
        return 0

    let v_start = self.enum_variant_starts.get(enum_idx as i64)
    let v_count = self.enum_variant_counts.get(enum_idx as i64)
    var v_idx = 0 - 1
    for vi in 0..v_count:
        if self.enum_variant_names.get((v_start + vi) as i64) == variant_sym:
            v_idx = vi
            break
    if v_idx < 0:
        return 0

    let tag = wl_build_extract_value(self.builder, obj, 0)
    let expected_tag = wl_const_int(wl_i32_type(self.context), v_idx as i64, 0)
    let is_match = wl_build_icmp(self.builder, wl_int_eq(), tag, expected_tag)
    if is_is:
        return is_match

    let payload_ty = self.enum_variant_payloads.get((v_start + v_idx) as i64)
    if payload_ty == 0:
        let call_text = self.ident_text_from_node(callee_node)
        let err_name = if call_text.len() > 0: call_text else: method_name
        with_eprintln("error: unsupported call to '" ++ err_name ++ "'")
        self.had_error = 1
        return wl_get_undef(wl_i32_type(self.context))

    let opt_ty = self.get_or_create_option_type(payload_ty)
    let match_bb = wl_append_bb(self.context, self.current_function, "enum.as.match")
    let nomatch_bb = wl_append_bb(self.context, self.current_function, "enum.as.nomatch")
    let merge_bb = wl_append_bb(self.context, self.current_function, "enum.as.merge")
    wl_build_cond_br(self.builder, is_match, match_bb, nomatch_bb)

    wl_position_at_end(self.builder, match_bb)
    let raw_payload = wl_build_extract_value(self.builder, obj, 1)
    let raw_ty = wl_type_of(raw_payload)
    let raw_alloca = wl_build_alloca(self.builder, raw_ty)
    wl_build_store(self.builder, raw_payload, raw_alloca)
    let cast_ptr = wl_build_bitcast(self.builder, raw_alloca, wl_ptr_type(self.context))
    let payload_val = wl_build_load(self.builder, payload_ty, cast_ptr)
    let some_val = self.build_option_some(payload_val, opt_ty)
    wl_build_br(self.builder, merge_bb)
    let match_end = wl_get_insert_block(self.builder)

    wl_position_at_end(self.builder, nomatch_bb)
    let none_val = self.build_option_none(opt_ty)
    wl_build_br(self.builder, merge_bb)
    let nomatch_end = wl_get_insert_block(self.builder)

    wl_position_at_end(self.builder, merge_bb)
    let phi = wl_build_phi(self.builder, opt_ty)
    let vals: Vec[i64] = Vec.new()
    let bbs: Vec[i64] = Vec.new()
    vals.push(some_val)
    vals.push(none_val)
    bbs.push(match_end)
    bbs.push(nomatch_end)
    wl_add_incoming(phi, vec_data_i64(&vals), vec_data_i64(&bbs), 2)
    phi

fn Codegen.build_variant_payload(self: Codegen, payload_ty: i64, args_start: i32, arg_count: i32) -> i64:
    if arg_count <= 0:
        return wl_get_undef(wl_i32_type(self.context))
    if payload_ty == 0:
        return self.gen_expr(self.pool.get_extra(args_start))
    if arg_count == 1:
        let arg = self.gen_expr(self.pool.get_extra(args_start))
        return self.coerce_value_to_type(arg, payload_ty)

    if wl_get_type_kind(payload_ty) == wl_struct_type_kind():
        var payload = wl_get_undef(payload_ty)
        let field_count = wl_count_struct_elem_types(payload_ty)
        var ai = 0
        while ai < arg_count and ai < field_count:
            let arg = self.gen_expr(self.pool.get_extra(args_start + ai))
            let field_ty = wl_struct_get_type_at(payload_ty, ai)
            let coerced = self.coerce_value_to_type(arg, field_ty)
            payload = wl_build_insert_value(self.builder, payload, coerced, ai)
            ai = ai + 1
        return payload

    let first = self.gen_expr(self.pool.get_extra(args_start))
    self.coerce_value_to_type(first, payload_ty)

fn Codegen.gen_enum_variant_call(self: Codegen, variant_sym: i32, args_start: i32, arg_count: i32) -> i64:
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
            wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), vi as i64, 0), tag_ptr)
            if arg_count > 0:
                let payload_ty = self.enum_variant_payloads.get((v_start + vi) as i64)
                let elem_count = wl_count_struct_elem_types(enum_ty)
                if payload_ty != 0 and elem_count > 1:
                    let payload = self.build_variant_payload(payload_ty, args_start, arg_count)
                    let payload_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 1)
                    let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
                    wl_build_store(self.builder, payload, cast_ptr)
            return wl_build_load(self.builder, enum_ty, alloca)
    0

// ── Struct literal ────────────────────────────────────────────────

fn Codegen.gen_struct_lit(self: Codegen, node: i32) -> i64:
    let type_sym = self.pool.get_data0(node)
    let fields_start = self.pool.get_data1(node)
    let field_count = self.pool.get_data2(node)
    var actual_type_sym = type_sym
    var st_idx = 0 - 1
    let st_opt = self.struct_type_map.get(type_sym)
    if st_opt.is_some():
        st_idx = st_opt.unwrap()
    else:
        if self.expected_type_node != 0 and self.pool.kind(self.expected_type_node) == NK_TYPE_GENERIC():
            let expected_name_sym = self.pool.get_data0(self.expected_type_node)
            if expected_name_sym == type_sym:
                let mono_ty = self.monomorphize_struct(type_sym, self.pool.get_data1(self.expected_type_node), self.pool.get_data2(self.expected_type_node))
                if mono_ty != 0:
                    let mono_idx = self.find_struct_index_by_type(mono_ty)
                    if mono_idx >= 0:
                        st_idx = mono_idx
                        if mono_idx < self.struct_index_syms.len() as i32:
                            actual_type_sym = self.struct_index_syms.get(mono_idx as i64)
        if st_idx < 0 and self.expected_type != 0:
            let expected_idx = self.find_struct_index_by_type(self.expected_type)
            if expected_idx >= 0:
                var expected_sym = 0
                if expected_idx < self.struct_index_syms.len() as i32:
                    expected_sym = self.struct_index_syms.get(expected_idx as i64)
                else:
                    expected_sym = self.reverse_struct_lookup(expected_idx)
                if expected_sym != 0:
                    let expected_name = self.intern.resolve(expected_sym)
                    let base_name = self.intern.resolve(type_sym)
                    if expected_sym == type_sym or expected_name == base_name or (expected_name.len() > base_name.len() + 2 and expected_name.slice(0, base_name.len()) == base_name and expected_name.slice(base_name.len(), base_name.len() + 2) == "__"):
                        st_idx = expected_idx
                        actual_type_sym = expected_sym
        if st_idx < 0:
            let gs_opt = self.generic_structs.get(type_sym)
            if gs_opt.is_some():
                let mono_ty = self.monomorphize_struct(type_sym, 0, 0)
                if mono_ty != 0:
                    let mono_idx = self.find_struct_index_by_type(mono_ty)
                    if mono_idx >= 0:
                        st_idx = mono_idx
                        if mono_idx < self.struct_index_syms.len() as i32:
                            actual_type_sym = self.struct_index_syms.get(mono_idx as i64)
    if st_idx < 0:
        return wl_get_undef(wl_i32_type(self.context))
    let st_ty = self.struct_llvm_types.get(st_idx as i64)
    let st_field_start = self.struct_field_starts.get(st_idx as i64)
    let st_field_count = self.struct_field_counts.get(st_idx as i64)
    let alloca = wl_build_alloca(self.builder, st_ty)
    let saved_expected = self.expected_type
    let saved_expected_node = self.expected_type_node

    // Initialize all fields to zero
    for i in 0..st_field_count:
        let fty = self.struct_field_types.get((st_field_start + i) as i64)
        let gep = wl_build_struct_gep(self.builder, st_ty, alloca, i)
        wl_build_store(self.builder, self.build_default_value(fty), gep)

    // Set provided fields
    // Struct lit extra: [field_name, field_value]* pairs
    for i in 0..field_count:
        let f_name = self.pool.get_extra(fields_start + i * 2)
        let f_val_node = self.pool.get_extra(fields_start + i * 2 + 1)
        let fi = self.find_field_index(actual_type_sym, f_name)
        if fi >= 0:
            let fty = self.struct_field_types.get((st_field_start + fi) as i64)
            self.expected_type = fty
            self.expected_type_node = self.struct_field_type_nodes.get((st_field_start + fi) as i64)
            let val = self.gen_expr(f_val_node)
            let gep = wl_build_struct_gep(self.builder, st_ty, alloca, fi)
            wl_build_store(self.builder, self.coerce_value_to_type(val, fty), gep)
    self.expected_type = saved_expected
    self.expected_type_node = saved_expected_node
    wl_build_load(self.builder, st_ty, alloca)

// ── Enum variant construction ─────────────────────────────────────

fn Codegen.gen_enum_variant(self: Codegen, node: i32) -> i64:
    let type_sym = self.pool.get_data0(node)
    let variant_sym = self.pool.get_data1(node)
    let extra_start = self.pool.get_data2(node)
    let arg_count = self.pool.get_extra(extra_start)

    let et_opt = self.enum_type_map.get(type_sym)
    if not et_opt.is_some(): return wl_get_undef(wl_i32_type(self.context))
    let et_idx = et_opt.unwrap()
    let enum_ty = self.enum_llvm_types.get(et_idx as i64)
    let v_start = self.enum_variant_starts.get(et_idx as i64)
    let v_count = self.enum_variant_counts.get(et_idx as i64)

    // Find variant index
    var v_idx = 0
    for vi in 0..v_count:
        if self.enum_variant_names.get((v_start + vi) as i64) == variant_sym:
            v_idx = vi
            break

    let alloca = wl_build_alloca(self.builder, enum_ty)
    wl_build_store(self.builder, self.build_default_value(enum_ty), alloca)
    let tag_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 0)
    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), v_idx as i64, 0), tag_ptr)

    if arg_count > 0:
        let payload_ty = self.enum_variant_payloads.get((v_start + v_idx) as i64)
        let payload = self.build_variant_payload(payload_ty, extra_start + 1, arg_count)
        let elem_count = wl_count_struct_elem_types(enum_ty)
        if payload_ty != 0 and elem_count > 1:
            let payload_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 1)
            let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
            wl_build_store(self.builder, payload, cast_ptr)

    wl_build_load(self.builder, enum_ty, alloca)

// ── Variant shorthand ─────────────────────────────────────────────

fn Codegen.gen_variant_shorthand(self: Codegen, node: i32) -> i64:
    let name_sym = self.pool.get_data0(node)
    let args_start = self.pool.get_data1(node)
    let arg_count = self.pool.get_data2(node)
    if arg_count == 0:
        return self.gen_ident(name_sym)
    // .Variant(args) — try to find the variant and construct it
    // Search through enum types for matching variant
    for ei in 0..self.enum_llvm_types.len() as i32:
        let v_start = self.enum_variant_starts.get(ei as i64)
        let v_count = self.enum_variant_counts.get(ei as i64)
        for vi in 0..v_count:
            if self.enum_variant_names.get((v_start + vi) as i64) == name_sym:
                let enum_ty = self.enum_llvm_types.get(ei as i64)
                let alloca = wl_build_alloca(self.builder, enum_ty)
                wl_build_store(self.builder, self.build_default_value(enum_ty), alloca)
                let tag_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 0)
                wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), vi as i64, 0), tag_ptr)
                if arg_count > 0:
                    let payload_ty = self.enum_variant_payloads.get((v_start + vi) as i64)
                    let payload = self.build_variant_payload(payload_ty, args_start, arg_count)
                    let elem_count = wl_count_struct_elem_types(enum_ty)
                    if payload_ty != 0 and elem_count > 1:
                        let payload_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 1)
                        let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
                        wl_build_store(self.builder, payload, cast_ptr)
                return wl_build_load(self.builder, enum_ty, alloca)
    wl_get_undef(wl_i32_type(self.context))

// ── Array literal ─────────────────────────────────────────────────

fn Codegen.gen_array_lit(self: Codegen, node: i32) -> i64:
    let extra_start = self.pool.get_data0(node)
    let elem_count = self.pool.get_data1(node)
    if elem_count == 0:
        return wl_get_undef(wl_array_type(wl_i32_type(self.context), 0))
    // Generate first element to get type
    let first_node = self.pool.get_extra(extra_start)
    let first = self.gen_expr(first_node)
    let elem_ty = wl_type_of(first)
    let arr_ty = wl_array_type(elem_ty, elem_count as i64)
    let alloca = wl_build_alloca(self.builder, arr_ty)
    // Store first
    let zero = wl_const_int(wl_i64_type(self.context), 0, 0)
    let indices: Vec[i64] = Vec.new()
    indices.push(zero)
    indices.push(zero)
    let gep = wl_build_gep(self.builder, arr_ty, alloca, vec_data_i64(&indices), 2)
    wl_build_store(self.builder, first, gep)
    // Store rest
    var i = 1
    while i < elem_count:
        let e_node = self.pool.get_extra(extra_start + i)
        let val = self.gen_expr(e_node)
        let idx = wl_const_int(wl_i64_type(self.context), i as i64, 0)
        let indices2: Vec[i64] = Vec.new()
        indices2.push(zero)
        indices2.push(idx)
        let gep2 = wl_build_gep(self.builder, arr_ty, alloca, vec_data_i64(&indices2), 2)
        wl_build_store(self.builder, val, gep2)
        i = i + 1
    wl_build_load(self.builder, arr_ty, alloca)

// ── Tuple ─────────────────────────────────────────────────────────

fn Codegen.gen_tuple(self: Codegen, node: i32) -> i64:
    let extra_start = self.pool.get_data0(node)
    let elem_count = self.pool.get_data1(node)
    let elem_types: Vec[i64] = Vec.new()
    let elem_vals: Vec[i64] = Vec.new()
    for i in 0..elem_count:
        let e_node = self.pool.get_extra(extra_start + i)
        let val = self.gen_expr(e_node)
        elem_types.push(wl_type_of(val))
        elem_vals.push(val)
    let tup_ty = wl_struct_type(self.context, vec_data_i64(&elem_types), elem_count, 0)
    var result = wl_get_undef(tup_ty)
    for i in 0..elem_count:
        result = wl_build_insert_value(self.builder, result, elem_vals.get(i as i64), i)
    result

// ── Cast ──────────────────────────────────────────────────────────

fn Codegen.gen_cast(self: Codegen, node: i32) -> i64:
    let expr_node = self.pool.get_data0(node)
    let type_node = self.pool.get_data1(node)
    let val = self.gen_expr(expr_node)
    let target_ty = self.resolve_type(type_node)
    let val_ty = wl_type_of(val)
    if val_ty == target_ty: return val
    let vk = wl_get_type_kind(val_ty)
    let tk = wl_get_type_kind(target_ty)
    if vk == wl_integer_type_kind() and tk == wl_integer_type_kind():
        let vw = wl_get_int_type_width(val_ty)
        let tw = wl_get_int_type_width(target_ty)
        if vw < tw: return wl_build_sext(self.builder, val, target_ty)
        if vw > tw: return wl_build_trunc(self.builder, val, target_ty)
        return val
    if vk == wl_integer_type_kind() and (tk == wl_float_type_kind() or tk == wl_double_type_kind()):
        return wl_build_si_to_fp(self.builder, val, target_ty)
    if (vk == wl_float_type_kind() or vk == wl_double_type_kind()) and tk == wl_integer_type_kind():
        return wl_build_fp_to_si(self.builder, val, target_ty)
    if vk == wl_float_type_kind() and tk == wl_double_type_kind():
        return wl_build_fp_ext(self.builder, val, target_ty)
    if vk == wl_double_type_kind() and tk == wl_float_type_kind():
        return wl_build_fp_cast(self.builder, val, target_ty)
    if vk == wl_integer_type_kind() and tk == wl_pointer_type_kind():
        return wl_build_int_to_ptr(self.builder, val, target_ty)
    if vk == wl_pointer_type_kind() and tk == wl_integer_type_kind():
        return wl_build_ptr_to_int(self.builder, val, target_ty)
    self.coerce_int(val, target_ty)

// ── Slice ─────────────────────────────────────────────────────────

fn Codegen.gen_slice(self: Codegen, node: i32) -> i64:
    let obj_node = self.pool.get_data0(node)
    let extra_start = self.pool.get_data1(node)
    let start_node = self.pool.get_extra(extra_start)
    let end_node = self.pool.get_extra(extra_start + 1)
    let obj = self.gen_expr(obj_node)
    let obj_ty = wl_type_of(obj)
    let obj_kind = wl_get_type_kind(obj_ty)
    let i64_ty = wl_i64_type(self.context)
    // Get element type and base pointer
    var elem_ty: i64 = 0
    var base_ptr: i64 = 0
    var total_len: i64 = 0
    if obj_kind == wl_array_type_kind():
        elem_ty = wl_get_element_type(obj_ty)
        let alloca = self.create_entry_alloca(obj_ty)
        wl_build_store(self.builder, obj, alloca)
        let gep_indices: Vec[i64] = Vec.new()
        gep_indices.push(wl_const_int(wl_i64_type(self.context), 0, 0))
        gep_indices.push(wl_const_int(wl_i64_type(self.context), 0, 0))
        base_ptr = wl_build_gep(self.builder, obj_ty, alloca, vec_data_i64(&gep_indices), 2)
        total_len = wl_const_int(i64_ty, wl_get_array_length(obj_ty) as i64, 0)
    else:
        // Reslice: obj is already a {ptr, len} struct
        base_ptr = wl_build_extract_value(self.builder, obj, 0)
        total_len = wl_build_extract_value(self.builder, obj, 1)
        elem_ty = wl_i8_type(self.context) // default for slices
    // Compute start and end
    let start_val = if start_node != 0: self.gen_expr(start_node) else wl_const_int(i64_ty, 0, 0)
    let end_val = if end_node != 0: self.gen_expr(end_node) else total_len
    // GEP to start offset
    let start_ext = self.coerce_int(start_val, i64_ty)
    let end_ext = self.coerce_int(end_val, i64_ty)
    let offset_indices: Vec[i64] = Vec.new()
    offset_indices.push(start_ext)
    let slice_ptr = wl_build_gep(self.builder, elem_ty, base_ptr, vec_data_i64(&offset_indices), 1)
    let slice_len = wl_build_sub(self.builder, end_ext, start_ext)
    // Build {ptr, len} struct
    let ptr_type = wl_ptr_type(self.context)
    let fields: Vec[i64] = Vec.new()
    fields.push(ptr_type)
    fields.push(i64_ty)
    let slice_ty = wl_struct_type(self.context, vec_data_i64(&fields), 2, 0)
    var result = wl_get_undef(slice_ty)
    result = wl_build_insert_value(self.builder, result, slice_ptr, 0)
    result = wl_build_insert_value(self.builder, result, slice_len, 1)
    result

// ── Closure ───────────────────────────────────────────────────────

fn Codegen.gen_closure(self: Codegen, node: i32) -> i64:
    // Closure: create an anonymous function and return its pointer
    // For non-capturing closures, just build a function and return pointer
    let extra_start = self.pool.get_data0(node)
    let body_node = self.pool.get_data1(node)
    let param_count = self.pool.get_data2(node)
    // Build parameter types
    let param_types: Vec[i64] = Vec.new()
    for i in 0..param_count:
        let p_name = self.pool.get_extra(extra_start + i * 2)
        let p_type = self.pool.get_extra(extra_start + i * 2 + 1)
        if p_type != 0:
            param_types.push(self.resolve_type(p_type))
        else:
            param_types.push(wl_i32_type(self.context))
    // Determine return type (infer from context or use i32)
    let ret_ty = wl_i32_type(self.context)
    let fn_ty = wl_function_type(ret_ty, vec_data_i64(&param_types), param_count, 0)
    let closure_fn = wl_add_function(self.llmod, "__closure", fn_ty)
    // Save current state
    let saved_fn = self.current_function
    let saved_bb = wl_get_insert_block(self.builder)
    let saved_allocas = self.local_allocas
    let saved_types = self.local_types
    let saved_loops = self.capture_loop_state()
    let fresh_closure_locals: HashMap[i32, i64] = HashMap.new()
    let fresh_closure_types: HashMap[i32, i64] = HashMap.new()
    self.local_allocas = fresh_closure_locals
    self.local_types = fresh_closure_types
    self.reset_loop_state()
    // Build closure body
    self.current_function = closure_fn
    let entry = wl_append_bb(self.context, closure_fn, "entry")
    wl_position_at_end(self.builder, entry)
    // Add params as locals
    for i in 0..param_count:
        let p_name = self.pool.get_extra(extra_start + i * 2)
        let param_val = wl_get_param(closure_fn, i)
        let param_ty = wl_type_of(param_val)
        let alloca = self.create_entry_alloca(param_ty)
        wl_build_store(self.builder, param_val, alloca)
        self.record_local(p_name, alloca, param_ty, 1)
    let body_val = self.gen_expr(body_node)
    if body_val != 0:
        let body_ty = wl_type_of(body_val)
        if wl_get_type_kind(body_ty) != wl_void_type_kind():
            let _ = wl_build_ret(self.builder, body_val)
        else:
            let _ = wl_build_ret_void(self.builder)
    else:
        let _ = wl_build_ret_void(self.builder)
    // Restore state
    self.current_function = saved_fn
    wl_position_at_end(self.builder, saved_bb)
    self.local_allocas = saved_allocas
    self.local_types = saved_types
    self.restore_loop_state(saved_loops)
    closure_fn

// ── Pipeline ──────────────────────────────────────────────────────

fn Codegen.gen_pipeline(self: Codegen, node: i32) -> i64:
    // a |> f desugars to f(a)
    let lhs_node = self.pool.get_data0(node)
    let rhs_node = self.pool.get_data1(node)
    let lhs_val = self.gen_expr(lhs_node)
    let rhs_val = self.gen_expr(rhs_node)
    let rhs_ty = wl_type_of(rhs_val)
    // RHS should be a function pointer
    let rhs_kind = wl_get_type_kind(rhs_ty)
    if rhs_kind == wl_pointer_type_kind():
        // Direct function call with LHS as first arg
        let args: Vec[i64] = Vec.new()
        args.push(lhs_val)
        let fn_ty = wl_global_get_value_type(rhs_val)
        let ret_ty = wl_get_return_type(fn_ty)
        return wl_build_call(self.builder, fn_ty, rhs_val, vec_data_i64(&args), 1)
    // Fallback: treat as identity
    lhs_val

// ── With Expression ───────────────────────────────────────────────

fn Codegen.gen_with_expr(self: Codegen, node: i32) -> i64:
    // with expr as binding: body
    let expr_node = self.pool.get_data0(node)
    let body_node = self.pool.get_data1(node)
    let binding_sym = decode_with_binding_sym(self.pool.get_data2(node))
    let val = self.gen_expr(expr_node)
    let val_ty = wl_type_of(val)
    // Store binding as local
    let alloca = self.create_entry_alloca(val_ty)
    wl_build_store(self.builder, val, alloca)
    self.record_local(binding_sym, alloca, val_ty, 1)
    // Generate body
    self.gen_expr(body_node)

// ── Record Update ─────────────────────────────────────────────────

fn Codegen.gen_record_update(self: Codegen, node: i32) -> i64:
    // { source with field1: val1, field2: val2 }
    let source_node = self.pool.get_data0(node)
    let extra_start = self.pool.get_data1(node)
    let field_count = self.pool.get_data2(node)
    let source = self.gen_expr(source_node)
    let source_ty = wl_type_of(source)
    // Allocate copy of source
    let alloca = self.create_entry_alloca(source_ty)
    wl_build_store(self.builder, source, alloca)
    // Override each field
    for i in 0..field_count:
        let field_sym = self.pool.get_extra(extra_start + i * 2)
        let val_node = self.pool.get_extra(extra_start + i * 2 + 1)
        let val = self.gen_expr(val_node)
        // Find field index in struct
        let type_sym = self.find_struct_type_by_llvm(source_ty)
        let field_idx = self.find_field_index(type_sym, field_sym)
        if field_idx >= 0:
            let gep = wl_build_struct_gep(self.builder, source_ty, alloca, field_idx)
            wl_build_store(self.builder, val, gep)
    wl_build_load(self.builder, source_ty, alloca)

// ── Range ─────────────────────────────────────────────────────────

fn Codegen.gen_range(self: Codegen, node: i32) -> i64:
    // Ranges are typically handled inline by for-loops.
    // As a standalone expression, return a {start, end} struct.
    let start_node = self.pool.get_data0(node)
    let end_node = self.pool.get_data1(node)
    let start_val = self.gen_expr(start_node)
    let end_val = self.gen_expr(end_node)
    let i32_ty = wl_i32_type(self.context)
    let fields: Vec[i64] = Vec.new()
    fields.push(i32_ty)
    fields.push(i32_ty)
    let range_ty = wl_struct_type(self.context, vec_data_i64(&fields), 2, 0)
    var result = wl_get_undef(range_ty)
    let sv = self.coerce_int(start_val, i32_ty)
    let ev = self.coerce_int(end_val, i32_ty)
    result = wl_build_insert_value(self.builder, result, sv, 0)
    result = wl_build_insert_value(self.builder, result, ev, 1)
    result

// ── Optional Chain ────────────────────────────────────────────────

fn Codegen.gen_optional_chain(self: Codegen, node: i32) -> i64:
    // opt?.field — check if Some then access field, else return None
    let obj_node = self.pool.get_data0(node)
    let field_sym = self.pool.get_data1(node)
    let obj = self.gen_expr(obj_node)
    let obj_ty = wl_type_of(obj)
    // Extract tag (field 0)
    let tag = wl_build_extract_value(self.builder, obj, 0)
    let is_some = wl_build_icmp(self.builder, 32, tag, wl_const_int(wl_i32_type(self.context), 0, 0)) // IntEQ = 32
    let then_bb = wl_append_bb(self.context, self.current_function, "chain.some")
    let else_bb = wl_append_bb(self.context, self.current_function, "chain.none")
    let merge_bb = wl_append_bb(self.context, self.current_function, "chain.merge")
    wl_build_cond_br(self.builder, is_some, then_bb, else_bb)
    // Some path: extract payload and access field
    wl_position_at_end(self.builder, then_bb)
    let payload = wl_build_extract_value(self.builder, obj, 1)
    // Try field access on payload
    let payload_ty = wl_type_of(payload)
    var then_val: i64 = payload
    if wl_get_type_kind(payload_ty) == wl_struct_type_kind():
        let type_sym = self.find_struct_type_by_llvm(payload_ty)
        let field_idx = self.find_field_index(type_sym, field_sym)
        if field_idx >= 0:
            then_val = wl_build_extract_value(self.builder, payload, field_idx)
    // Wrap result in Option
    let result_ty = self.get_or_create_option_type(wl_type_of(then_val))
    let some_val = self.build_option_some(then_val, result_ty)
    wl_build_br(self.builder, merge_bb)
    let then_end = wl_get_insert_block(self.builder)
    // None path
    wl_position_at_end(self.builder, else_bb)
    let none_val = self.build_option_none(result_ty)
    wl_build_br(self.builder, merge_bb)
    let else_end = wl_get_insert_block(self.builder)
    // Merge
    wl_position_at_end(self.builder, merge_bb)
    let phi = wl_build_phi(self.builder, result_ty)
    let vals: Vec[i64] = Vec.new()
    let bbs: Vec[i64] = Vec.new()
    vals.push(some_val)
    vals.push(none_val)
    bbs.push(then_end)
    bbs.push(else_end)
    wl_add_incoming(phi, vec_data_i64(&vals), vec_data_i64(&bbs), 2)
    phi

// ── Tuple Destructure ─────────────────────────────────────────────

fn Codegen.gen_tuple_destructure(self: Codegen, node: i32) -> i64:
    let extra_start = self.pool.get_data0(node)
    let binding_count = self.pool.get_data1(node)
    let value_node = self.pool.get_data2(node)
    let tuple_val = self.gen_expr(value_node)
    let tuple_ty = wl_type_of(tuple_val)
    // Extract each element and bind to name
    for i in 0..binding_count:
        let name_sym = self.pool.get_extra(extra_start + i)
        let elem_val = wl_build_extract_value(self.builder, tuple_val, i)
        let elem_ty = wl_type_of(elem_val)
        let alloca = self.create_entry_alloca(elem_ty)
        wl_build_store(self.builder, elem_val, alloca)
        self.record_local(name_sym, alloca, elem_ty, 1)
    wl_get_undef(wl_void_type(self.context))

// ── Array Comprehension ───────────────────────────────────────────

fn Codegen.gen_array_comprehension(self: Codegen, node: i32) -> i64:
    // [expr for x in range] - simple single-clause comprehension
    let expr_node = self.pool.get_data0(node)
    let extra_start = self.pool.get_data1(node)
    let binding_sym = self.pool.get_extra(extra_start)
    let iterable_node = self.pool.get_extra(extra_start + 1)
    // Evaluate range
    let start_node = self.pool.get_data0(iterable_node)
    let end_node = self.pool.get_data1(iterable_node)
    let start_val = if start_node != 0: self.gen_expr(start_node) else wl_const_int(wl_i32_type(self.context), 0, 0)
    let end_val = self.gen_expr(end_node)
    let i32_ty = wl_i32_type(self.context)
    let sv = self.coerce_int(start_val, i32_ty)
    let ev = self.coerce_int(end_val, i32_ty)
    // If both are constant, compute size at compile time
    // For now generate a simple loop
    let idx_alloca = self.create_entry_alloca(i32_ty)
    wl_build_store(self.builder, sv, idx_alloca)
    // First pass to determine element type: generate the body once
    self.record_local(binding_sym, idx_alloca, i32_ty, 1)
    // Use a Vec to collect results
    let size = wl_build_sub(self.builder, ev, sv)
    let size64 = wl_build_sext(self.builder, size, wl_i64_type(self.context))
    // Create loop
    let cond_bb = wl_append_bb(self.context, self.current_function, "comp.cond")
    let body_bb = wl_append_bb(self.context, self.current_function, "comp.body")
    let done_bb = wl_append_bb(self.context, self.current_function, "comp.done")
    wl_build_br(self.builder, cond_bb)
    wl_position_at_end(self.builder, cond_bb)
    let cur_idx = wl_build_load(self.builder, i32_ty, idx_alloca)
    let cmp = wl_build_icmp(self.builder, 38, cur_idx, ev) // SLT = 38
    wl_build_cond_br(self.builder, cmp, body_bb, done_bb)
    wl_position_at_end(self.builder, body_bb)
    let elem = self.gen_expr(expr_node)
    let next_idx = wl_build_add(self.builder, cur_idx, wl_const_int(i32_ty, 1, 0))
    wl_build_store(self.builder, next_idx, idx_alloca)
    wl_build_br(self.builder, cond_bb)
    wl_position_at_end(self.builder, done_bb)
    // Return undef for now - full array comprehension needs runtime Vec
    wl_get_undef(wl_void_type(self.context))

// ── Async stubs ───────────────────────────────────────────────────

fn Codegen.gen_async_block(self: Codegen, node: i32) -> i64:
    // Stage1 contract: async blocks evaluate to task-like values consumed
    // by await/spawn/select paths.
    let body = self.pool.get_data0(node)
    self.gen_expr(body)

fn Codegen.gen_async_scope(self: Codegen, node: i32) -> i64:
    // async scope currently lowers as an explicit lexical body evaluation.
    let body = self.pool.get_data1(node)
    self.gen_expr(body)

fn Codegen.expr_contains_await(self: Codegen, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.pool.kind(node)
    if kind == NK_AWAIT():
        return 1
    if kind == NK_GROUPED() or kind == NK_ASYNC_BLOCK() or kind == NK_SPAWN() or kind == NK_DEFER() or kind == NK_YIELD() or kind == NK_COMPTIME():
        return self.expr_contains_await(self.pool.get_data0(node))
    if kind == NK_UNARY() or kind == NK_CAST() or kind == NK_CLOSURE() or kind == NK_BREAK():
        return self.expr_contains_await(self.pool.get_data0(node))
    if kind == NK_BINARY() or kind == NK_ASSIGN() or kind == NK_PIPELINE() or kind == NK_RANGE() or kind == NK_INDEX():
        if self.expr_contains_await(self.pool.get_data0(node)) != 0:
            return 1
        return self.expr_contains_await(self.pool.get_data1(node))
    if kind == NK_CALL():
        if self.expr_contains_await(self.pool.get_data0(node)) != 0:
            return 1
        let extra_start = self.pool.get_data1(node)
        let arg_count = self.pool.get_data2(node)
        for ai in 0..arg_count:
            if self.expr_contains_await(self.pool.get_extra(extra_start + ai)) != 0:
                return 1
        return 0
    if kind == NK_FIELD_ACCESS():
        return self.expr_contains_await(self.pool.get_data0(node))
    if kind == NK_SLICE():
        if self.expr_contains_await(self.pool.get_data0(node)) != 0:
            return 1
        if self.expr_contains_await(self.pool.get_data1(node)) != 0:
            return 1
        return self.expr_contains_await(self.pool.get_data2(node))
    if kind == NK_BLOCK():
        let extra_start = self.pool.get_data0(node)
        let stmt_count = self.pool.get_data1(node)
        let tail = self.pool.get_data2(node)
        for si in 0..stmt_count:
            if self.expr_contains_await(self.pool.get_extra(extra_start + si)) != 0:
                return 1
        return self.expr_contains_await(tail)
    if kind == NK_IF_EXPR():
        if self.expr_contains_await(self.pool.get_data0(node)) != 0:
            return 1
        if self.expr_contains_await(self.pool.get_data1(node)) != 0:
            return 1
        return self.expr_contains_await(self.pool.get_data2(node))
    if kind == NK_WHILE():
        if self.expr_contains_await(self.pool.get_data0(node)) != 0:
            return 1
        return self.expr_contains_await(self.pool.get_data1(node))
    if kind == NK_FOR():
        if self.expr_contains_await(self.pool.get_data1(node)) != 0:
            return 1
        return self.expr_contains_await(self.pool.get_data2(node))
    if kind == NK_LOOP() or kind == NK_RETURN():
        return self.expr_contains_await(self.pool.get_data0(node))
    if kind == NK_LET_BINDING() or kind == NK_ASYNC_SCOPE():
        return self.expr_contains_await(self.pool.get_data1(node))
    if kind == NK_TUPLE() or kind == NK_ARRAY_LIT():
        let extra_start = self.pool.get_data0(node)
        let elem_count = self.pool.get_data1(node)
        for ei in 0..elem_count:
            if self.expr_contains_await(self.pool.get_extra(extra_start + ei)) != 0:
                return 1
        return 0
    if kind == NK_STRUCT_LIT():
        let extra_start = self.pool.get_data1(node)
        let field_count = self.pool.get_data2(node)
        for fi in 0..field_count:
            if self.expr_contains_await(self.pool.get_extra(extra_start + fi * 2 + 1)) != 0:
                return 1
        return 0
    if kind == NK_MATCH():
        if self.expr_contains_await(self.pool.get_data0(node)) != 0:
            return 1
        let extra_start = self.pool.get_data1(node)
        let arm_count = self.pool.get_data2(node)
        for ai in 0..arm_count:
            let arm = self.pool.get_extra(extra_start + ai)
            if self.expr_contains_await(self.pool.get_data2(arm)) != 0:
                return 1
            if self.expr_contains_await(self.pool.get_data1(arm)) != 0:
                return 1
        return 0
    if kind == NK_SELECT_AWAIT():
        return 1
    0

fn Codegen.fn_body_contains_await(self: Codegen, fn_sym: i32) -> i32:
    for di in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(di)
        if self.pool.kind(decl) == NK_FN_DECL() and self.pool.get_data0(decl) == fn_sym:
            return self.expr_contains_await(self.pool.get_data1(decl))
    0

fn Codegen.select_arm_latency_hint(self: Codegen, task_expr: i32) -> i32:
    if task_expr == 0:
        return 0
    let kind = self.pool.kind(task_expr)
    if kind == NK_CALL():
        let callee = self.pool.get_data0(task_expr)
        if self.pool.kind(callee) == NK_IDENT():
            let fn_sym = self.pool.get_data0(callee)
            return self.fn_body_contains_await(fn_sym)
        return 0
    if kind == NK_ASYNC_BLOCK():
        return self.expr_contains_await(self.pool.get_data0(task_expr))
    0

fn Codegen.gen_select_await(self: Codegen, node: i32) -> i64:
    let extra_start = self.pool.get_data0(node)
    let arm_count = self.pool.get_data1(node)
    if arm_count <= 0:
        return wl_get_undef(wl_void_type(self.context))

    var selected = 0
    var selected_hint = 2147483647
    for ai in 0..arm_count:
        let task_expr = self.pool.get_extra(extra_start + ai * 3 + 1)
        let hint = self.select_arm_latency_hint(task_expr)
        if hint < selected_hint:
            selected = ai
            selected_hint = hint

    let arm_name = self.pool.get_extra(extra_start + selected * 3)
    let task_expr = self.pool.get_extra(extra_start + selected * 3 + 1)
    let arm_body = self.pool.get_extra(extra_start + selected * 3 + 2)

    let task_val = self.gen_expr(task_expr)
    let task_ty = wl_type_of(task_val)
    let arm_name_text = self.intern.resolve(arm_name)
    if arm_name != 0 and arm_name_text != "_":
        let alloca = self.create_entry_alloca(task_ty)
        wl_build_store(self.builder, task_val, alloca)
        self.record_local(arm_name, alloca, task_ty, 1)

    self.gen_expr(arm_body)

fn Codegen.gen_yield(self: Codegen, node: i32) -> i64:
    // Generator yield - requires generator state machine transform
    let val_node = self.pool.get_data0(node)
    if val_node != 0: return self.gen_expr(val_node)
    wl_get_undef(wl_void_type(self.context))

fn Codegen.gen_await(self: Codegen, node: i32) -> i64:
    // Async await - evaluate inner expression
    let inner_node = self.pool.get_data0(node)
    self.gen_expr(inner_node)

fn Codegen.gen_spawn(self: Codegen, node: i32) -> i64:
    // Spawn async task - evaluate inner expression
    let inner_node = self.pool.get_data0(node)
    self.gen_expr(inner_node)

fn Codegen.gen_comptime(self: Codegen, node: i32) -> i64:
    // Compile-time evaluation - for now just evaluate at runtime
    let inner_node = self.pool.get_data0(node)
    self.gen_expr(inner_node)

// ── Printf infrastructure ─────────────────────────────────────────

fn Codegen.ensure_printf_declared(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "printf")
    if existing != 0: return existing
    // printf(const char*, ...) -> i32
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(ptr_ty)
    let fn_ty = wl_function_type(i32_ty, vec_data_i64(&param_types), 1, 1) // variadic
    wl_add_function(self.llmod, "printf", fn_ty)

fn Codegen.get_printf_fn_type(self: Codegen) -> i64:
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(ptr_ty)
    wl_function_type(i32_ty, vec_data_i64(&param_types), 1, 1)

fn Codegen.ensure_fprintf_declared(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "fprintf")
    if existing != 0: return existing
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(ptr_ty)
    param_types.push(ptr_ty)
    let fn_ty = wl_function_type(i32_ty, vec_data_i64(&param_types), 2, 1)
    wl_add_function(self.llmod, "fprintf", fn_ty)

fn Codegen.ensure_stderr_declared(self: Codegen) -> i64:
    // Declare extern __stderrp (macOS) or stderr (Linux)
    let existing = wl_get_named_function(self.llmod, "__stderrp")
    if existing != 0: return existing
    let ptr_ty = wl_ptr_type(self.context)
    let g = wl_add_global(self.llmod, ptr_ty, "__stderrp")
    g

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

fn Codegen.gen_print_value(self: Codegen, val: i64, printf_fn: i64, printf_ty: i64) -> void:
    let ty = wl_type_of(val)
    let kind = wl_get_type_kind(ty)
    var print_val = val
    var fmt = "%d"
    if self.is_str_type(ty):
        print_val = self.extract_str_ptr(val)
        fmt = "%.*s"
        // For str, we need to pass len then ptr
        let len_val = wl_build_extract_value(self.builder, val, 1)
        let len32 = wl_build_trunc(self.builder, len_val, wl_i32_type(self.context))
        let fmt_str = wl_build_global_string_ptr(self.builder, fmt)
        let args: Vec[i64] = Vec.new()
        args.push(fmt_str)
        args.push(len32)
        args.push(print_val)
        wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(&args), 3)
        return
    if kind == wl_pointer_type_kind():
        fmt = "%s"
    else if kind == wl_integer_type_kind():
        let width = wl_get_int_type_width(ty)
        if width == 1:
            let true_str = wl_build_global_string_ptr(self.builder, "true")
            let false_str = wl_build_global_string_ptr(self.builder, "false")
            print_val = wl_build_select(self.builder, val, true_str, false_str)
            fmt = "%s"
        else if width <= 32:
            fmt = "%d"
        else:
            fmt = "%lld"
    else if kind == wl_float_type_kind() or kind == wl_double_type_kind():
        if kind == wl_float_type_kind():
            print_val = wl_build_fp_ext(self.builder, val, wl_f64_type(self.context))
        fmt = "%g"
    else if kind == wl_struct_type_kind():
        // Struct: try to print each field
        let field_count = wl_count_struct_elem_types(ty)
        let brace_fmt = wl_build_global_string_ptr(self.builder, "%c")
        let open_brace = wl_const_int(wl_i32_type(self.context), 123, 0)
        let open_args: Vec[i64] = Vec.new()
        open_args.push(brace_fmt)
        open_args.push(open_brace)
        wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(&open_args), 2)
        for fi in 0..field_count:
            if fi > 0:
                let comma_fmt = wl_build_global_string_ptr(self.builder, ", ")
                let comma_args: Vec[i64] = Vec.new()
                comma_args.push(comma_fmt)
                wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(&comma_args), 1)
            let fv = wl_build_extract_value(self.builder, val, fi)
            self.gen_print_value(fv, printf_fn, printf_ty)
        let close_brace = wl_const_int(wl_i32_type(self.context), 125, 0)
        let close_args: Vec[i64] = Vec.new()
        close_args.push(brace_fmt)
        close_args.push(close_brace)
        wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(&close_args), 2)
        return
    else:
        fmt = "%d"
    let fmt_str = wl_build_global_string_ptr(self.builder, fmt)
    let args: Vec[i64] = Vec.new()
    args.push(fmt_str)
    args.push(print_val)
    wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(&args), 2)

fn Codegen.gen_println(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    self.gen_print_or_println(args_start, arg_count, true)

fn Codegen.gen_print_call(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    self.gen_print_or_println(args_start, arg_count, false)

fn Codegen.gen_eprintln(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    // For eprintln, use fprintf(stderr, ...) — for simplicity, use printf for now
    self.gen_print_or_println(args_start, arg_count, true)

fn Codegen.gen_print_or_println(self: Codegen, args_start: i32, arg_count: i32, add_newline: bool) -> i64:
    let printf_fn = self.ensure_printf_declared()
    let printf_ty = self.get_printf_fn_type()
    if arg_count == 0:
        if add_newline:
            let nl = wl_build_global_string_ptr(self.builder, "\n")
            let nl_args: Vec[i64] = Vec.new()
            nl_args.push(nl)
            wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(&nl_args), 1)
        return wl_const_int(wl_i32_type(self.context), 0, 0)
    // Print each arg
    for i in 0..arg_count:
        let arg_node = self.pool.get_extra(args_start + i)
        let val = self.gen_expr(arg_node)
        self.gen_print_value(val, printf_fn, printf_ty)
    if add_newline:
        let nl = wl_build_global_string_ptr(self.builder, "\n")
        let nl_args: Vec[i64] = Vec.new()
        nl_args.push(nl)
        wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(&nl_args), 1)
    wl_const_int(wl_i32_type(self.context), 0, 0)

// ── String method dispatch ────────────────────────────────────────

fn Codegen.gen_str_method(self: Codegen, method: str, obj: i64, args_start: i32, arg_count: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let i8_ty = wl_i8_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    // Extract ptr and len from str struct
    let str_ptr = wl_build_extract_value(self.builder, obj, 0)
    let str_len = wl_build_extract_value(self.builder, obj, 1)

    if method == "len":
        return str_len
    if method == "is_empty":
        return wl_build_icmp(self.builder, wl_int_eq(), str_len, wl_const_int(i64_ty, 0, 0))
    if method == "contains" and arg_count > 0:
        let needle = self.gen_expr(self.pool.get_extra(args_start))
        let n_ptr = wl_build_extract_value(self.builder, needle, 0)
        let fn_val = self.ensure_c_fn("with_str_contains", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(obj)
        args.push(needle)
        let result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_contains", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
        return wl_build_icmp(self.builder, wl_int_ne(), result, wl_const_int(i32_ty, 0, 0))
    if method == "starts_with" and arg_count > 0:
        let prefix = self.gen_expr(self.pool.get_extra(args_start))
        let fn_val = self.ensure_c_fn("with_str_starts_with", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(obj)
        args.push(prefix)
        let result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_starts_with", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
        return wl_build_icmp(self.builder, wl_int_ne(), result, wl_const_int(i32_ty, 0, 0))
    if method == "ends_with" and arg_count > 0:
        let suffix = self.gen_expr(self.pool.get_extra(args_start))
        let fn_val = self.ensure_c_fn("with_str_ends_with", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(obj)
        args.push(suffix)
        let result = wl_build_call(self.builder, self.get_runtime_fn_type("with_str_ends_with", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
        return wl_build_icmp(self.builder, wl_int_ne(), result, wl_const_int(i32_ty, 0, 0))
    if method == "find" and arg_count > 0:
        let needle = self.gen_expr(self.pool.get_extra(args_start))
        let fn_val = self.ensure_c_fn("with_str_index_of", i64_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(obj)
        args.push(needle)
        return wl_build_call(self.builder, self.get_runtime_fn_type("with_str_index_of", i64_ty, 2), fn_val, vec_data_i64(&args), 2)
    if method == "slice" and arg_count >= 2:
        let start = self.gen_expr(self.pool.get_extra(args_start))
        let end = self.gen_expr(self.pool.get_extra(args_start + 1))
        let start64 = self.coerce_int(start, i64_ty)
        let end64 = self.coerce_int(end, i64_ty)
        // GEP to start, compute new len
        let indices: Vec[i64] = Vec.new()
        indices.push(start64)
        let new_ptr = wl_build_gep(self.builder, i8_ty, str_ptr, vec_data_i64(&indices), 1)
        let new_len = wl_build_sub(self.builder, end64, start64)
        return self.build_str_value(new_ptr, new_len)
    if method == "byte_at" and arg_count > 0:
        let index = self.gen_expr(self.pool.get_extra(args_start))
        let index64 = self.coerce_int(index, i64_ty)
        let fn_val = self.ensure_c_fn("with_str_byte_at", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(obj)
        args.push(index64)
        return wl_build_call(self.builder, self.get_runtime_fn_type("with_str_byte_at", i32_ty, 2), fn_val, vec_data_i64(&args), 2)
    if method == "to_upper" or method == "to_lower":
        // Call with_str_to_upper/to_lower runtime functions if available
        // For now, return the string unchanged
        return obj
    if method == "trim":
        return obj // Stub - needs runtime support
    if method == "repeat" and arg_count > 0:
        return obj // Stub - needs runtime support
    if method == "split" and arg_count > 0:
        return wl_get_undef(wl_i32_type(self.context)) // Stub
    if method == "replace" and arg_count >= 2:
        return obj // Stub - needs runtime support
    // Unknown method
    wl_get_undef(wl_i32_type(self.context))

fn Codegen.build_str_value(self: Codegen, ptr: i64, len: i64) -> i64:
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    if not st_opt.is_some(): return wl_get_undef(wl_i32_type(self.context))
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
       name == "with_str_index_of":
        for i in 0..param_count:
            params.push(str_type)
    else if name == "with_str_byte_at":
        params.push(str_type)
        params.push(i64_ty)
    else:
        for i in 0..param_count:
            params.push(i64_ty)
    wl_function_type(ret_ty, vec_data_i64(&params), param_count, 0)

// ── Vec method dispatch ───────────────────────────────────────────

fn Codegen.gen_vec_method(self: Codegen, method: str, obj: i64, args_start: i32, arg_count: i32, obj_node: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)

    // Vec is a struct: {data_ptr, len, cap, elem_size}
    // We need to get a mutable pointer to the Vec for push/pop
    var vec_ptr: i64 = 0
    if self.pool.kind(obj_node) == NK_IDENT():
        let sym = self.pool.get_data0(obj_node)
        vec_ptr = self.lookup_local_alloca(sym)
    else if self.pool.kind(obj_node) == NK_FIELD_ACCESS():
        let base = self.pool.get_data0(obj_node)
        let field = self.pool.get_data1(obj_node)
        vec_ptr = self.gen_field_access_ptr(base, field)

    if method == "len":
        return wl_build_extract_value(self.builder, obj, 1) // field 1 is len
    if method == "is_empty":
        let len = wl_build_extract_value(self.builder, obj, 1)
        return wl_build_icmp(self.builder, wl_int_eq(), len, wl_const_int(i64_ty, 0, 0))
    if method == "push" and arg_count > 0 and vec_ptr != 0:
        let elem = self.gen_expr(self.pool.get_extra(args_start))
        // Store elem in temp alloca, then call with_vec_push(&vec, &elem)
        let elem_ty = wl_type_of(elem)
        let elem_alloca = wl_build_alloca(self.builder, elem_ty)
        wl_build_store(self.builder, elem, elem_alloca)
        // Record element type so subsequent get/pop calls know the type.
        if self.pool.kind(obj_node) == NK_IDENT():
            let obj_sym = self.pool.get_data0(obj_node)
            if not self.vec_local_types.get(obj_sym).is_some():
                self.vec_local_types.insert(obj_sym, elem_ty)
        let push_fn = self.ensure_vec_runtime_fn("with_vec_push", wl_void_type(self.context), 2)
        let push_ty = self.get_vec_fn_type("with_vec_push", wl_void_type(self.context), 2)
        let args: Vec[i64] = Vec.new()
        args.push(vec_ptr)
        args.push(elem_alloca)
        return wl_build_call(self.builder, push_ty, push_fn, vec_data_i64(&args), 2)
    if method == "get" and arg_count > 0:
        let idx = self.gen_expr(self.pool.get_extra(args_start))
        let idx64 = self.coerce_int(idx, i64_ty)
        let get_fn = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
        let get_ty = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
        let args: Vec[i64] = Vec.new()
        if vec_ptr != 0:
            args.push(vec_ptr)
        else:
            let alloca = wl_build_alloca(self.builder, wl_type_of(obj))
            wl_build_store(self.builder, obj, alloca)
            args.push(alloca)
        args.push(idx64)
        let raw_ptr = wl_build_call(self.builder, get_ty, get_fn, vec_data_i64(&args), 2)
        // Load the element from the raw pointer
        let elem_ty = self.infer_vec_elem_type_from_receiver(obj_node, wl_type_of(obj))
        if elem_ty != 0:
            return wl_build_load(self.builder, elem_ty, raw_ptr)
        return raw_ptr
    if method == "pop" and vec_ptr != 0:
        let len_fn = self.ensure_vec_runtime_fn("with_vec_len", i64_ty, 1)
        let len_ty = self.get_vec_fn_type("with_vec_len", i64_ty, 1)
        let len_args: Vec[i64] = Vec.new()
        len_args.push(vec_ptr)
        let len = wl_build_call(self.builder, len_ty, len_fn, vec_data_i64(&len_args), 1)
        let has_items = wl_build_icmp(self.builder, wl_int_sgt(), len, wl_const_int(i64_ty, 0, 0))
        let pop_bb = wl_append_bb(self.context, self.current_function, "vec.pop")
        let merge_bb = wl_append_bb(self.context, self.current_function, "vec.pop.end")
        let empty_bb = wl_get_insert_block(self.builder)
        wl_build_cond_br(self.builder, has_items, pop_bb, merge_bb)
        let elem_ty = self.infer_vec_elem_type_from_receiver(obj_node, wl_type_of(obj))
        var popped: i64 = 0
        wl_position_at_end(self.builder, pop_bb)
        let last_idx = wl_build_sub(self.builder, len, wl_const_int(i64_ty, 1, 0))
        if elem_ty != 0:
            let get_fn = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
            let get_ty = self.get_vec_fn_type("with_vec_get_ptr", ptr_ty, 2)
            let get_args: Vec[i64] = Vec.new()
            get_args.push(vec_ptr)
            get_args.push(last_idx)
            let raw_ptr = wl_build_call(self.builder, get_ty, get_fn, vec_data_i64(&get_args), 2)
            popped = wl_build_load(self.builder, elem_ty, raw_ptr)
        let remove_fn = self.ensure_vec_runtime_fn("with_vec_remove", wl_void_type(self.context), 2)
        let remove_ty = self.get_vec_fn_type("with_vec_remove", wl_void_type(self.context), 2)
        let remove_args: Vec[i64] = Vec.new()
        remove_args.push(vec_ptr)
        remove_args.push(last_idx)
        let _ = wl_build_call(self.builder, remove_ty, remove_fn, vec_data_i64(&remove_args), 2)
        wl_build_br(self.builder, merge_bb)
        let pop_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, merge_bb)
        if elem_ty != 0:
            let default_val = self.build_default_value(elem_ty)
            let phi = wl_build_phi(self.builder, elem_ty)
            let phi_vals: Vec[i64] = Vec.new()
            let phi_bbs: Vec[i64] = Vec.new()
            phi_vals.push(popped)
            phi_vals.push(default_val)
            phi_bbs.push(pop_end)
            phi_bbs.push(empty_bb)
            wl_add_incoming(phi, vec_data_i64(&phi_vals), vec_data_i64(&phi_bbs), 2)
            return phi
        return wl_get_undef(wl_i32_type(self.context))
    if method == "set_i32" and arg_count >= 2 and vec_ptr != 0:
        let idx_expr = self.gen_expr(self.pool.get_extra(args_start))
        let val_expr = self.gen_expr(self.pool.get_extra(args_start + 1))
        let idx64 = self.coerce_int(idx_expr, i64_ty)
        let val32 = self.coerce_int(val_expr, i32_ty)
        let set_fn_name = "with_vec_set_i32"
        var set_fn = wl_get_named_function(self.llmod, set_fn_name)
        let param_types: Vec[i64] = Vec.new()
        param_types.push(ptr_ty)
        param_types.push(i64_ty)
        param_types.push(i32_ty)
        let set_ty = wl_function_type(wl_void_type(self.context), vec_data_i64(&param_types), 3, 0)
        if set_fn == 0:
            set_fn = wl_add_function(self.llmod, set_fn_name, set_ty)
        let args: Vec[i64] = Vec.new()
        args.push(vec_ptr)
        args.push(idx64)
        args.push(val32)
        return wl_build_call(self.builder, set_ty, set_fn, vec_data_i64(&args), 3)
    if method == "clear" and vec_ptr != 0:
        let clear_fn = self.ensure_vec_runtime_fn("with_vec_clear", wl_void_type(self.context), 1)
        let clear_ty = self.get_vec_fn_type("with_vec_clear", wl_void_type(self.context), 1)
        let args: Vec[i64] = Vec.new()
        args.push(vec_ptr)
        return wl_build_call(self.builder, clear_ty, clear_fn, vec_data_i64(&args), 1)
    if method == "contains" and arg_count > 0:
        // Linear scan
        let needle = self.gen_expr(self.pool.get_extra(args_start))
        let len = wl_build_extract_value(self.builder, obj, 1)
        // For simplicity, return false (full impl needs loop)
        return wl_const_int(wl_i1_type(self.context), 0, 0)
    // Higher-order methods: map, filter, fold — stubs
    if method == "map" or method == "filter" or method == "fold" or method == "join" or method == "sequence" or method == "traverse":
        return wl_get_undef(wl_i32_type(self.context))
    wl_get_undef(wl_i32_type(self.context))

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

fn Codegen.gen_hashmap_method(self: Codegen, method: str, obj: i64, args_start: i32, arg_count: i32, cache_idx: i32) -> i64:
    let i64_ty = wl_i64_type(self.context)
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)

    // HashMap stores an opaque pointer
    let map_ptr = wl_build_extract_value(self.builder, obj, 0)
    let is_str = self.hm_is_str_keys.get(cache_idx as i64)
    let is_str_val = wl_const_int(i64_ty, is_str as i64, 0)

    if method == "len":
        let fn_val = self.ensure_hm_fn("with_hashmap_len", i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&self.make_ptr_vec()), 1, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        return wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 1)
    if method == "contains" and arg_count > 0:
        let key = self.gen_expr(self.pool.get_extra(args_start))
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
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
        let result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 3)
        return wl_build_icmp(self.builder, wl_int_ne(), result, wl_const_int(i64_ty, 0, 0))
    if method == "insert" and arg_count >= 2:
        let key = self.gen_expr(self.pool.get_extra(args_start))
        let val = self.gen_expr(self.pool.get_extra(args_start + 1))
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        let val_alloca = wl_build_alloca(self.builder, wl_type_of(val))
        wl_build_store(self.builder, key, key_alloca)
        wl_build_store(self.builder, val, val_alloca)
        let fn_val = self.ensure_hm_fn("with_hashmap_insert", wl_void_type(self.context))
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(wl_void_type(self.context), vec_data_i64(&params), 4, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(val_alloca)
        args.push(is_str_val)
        return wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 4)
    if method == "get" and arg_count > 0:
        let key = self.gen_expr(self.pool.get_extra(args_start))
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        // Allocate output buffer
        let val_ty = self.hm_val_types.get(cache_idx as i64)
        let out_alloca = wl_build_alloca(self.builder, val_ty)
        let fn_val = self.ensure_hm_fn("with_hashmap_get", i64_ty)
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(&params), 4, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(out_alloca)
        args.push(is_str_val)
        let found = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 4)
        // Build Option type result
        let val = wl_build_load(self.builder, val_ty, out_alloca)
        let opt_ty = self.get_or_create_option_type(val_ty)
        let is_found = wl_build_icmp(self.builder, wl_int_ne(), found, wl_const_int(i64_ty, 0, 0))
        // Build Some(val) or None
        let some_val = self.build_option_some(val, opt_ty)
        let none_val = self.build_option_none(opt_ty)
        return wl_build_select(self.builder, is_found, some_val, none_val)
    if method == "remove" and arg_count > 0:
        let key = self.gen_expr(self.pool.get_extra(args_start))
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
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
        return wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 3)
    // increment, decrement, update, append — stubs for now
    wl_get_undef(wl_i32_type(self.context))

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

// ── Option method dispatch ────────────────────────────────────────

fn Codegen.gen_option_method(self: Codegen, method: str, obj: i64, args_start: i32, arg_count: i32) -> i64:
    let i32_ty = wl_i32_type(self.context)
    let obj_ty = wl_type_of(obj)

    // Option is {i32 tag, T payload} — tag=0 is Some, tag!=0 is None
    let tag = wl_build_extract_value(self.builder, obj, 0)
    let is_some = wl_build_icmp(self.builder, wl_int_eq(), tag, wl_const_int(i32_ty, 0, 0))

    if method == "is_some" or method == "is_ok":
        return is_some
    if method == "is_none" or method == "is_err":
        return wl_build_icmp(self.builder, wl_int_ne(), tag, wl_const_int(i32_ty, 0, 0))
    if method == "unwrap":
        // Check tag, panic if None
        let then_bb = wl_append_bb(self.context, self.current_function, "unwrap.ok")
        let panic_bb = wl_append_bb(self.context, self.current_function, "unwrap.panic")
        wl_build_cond_br(self.builder, is_some, then_bb, panic_bb)
        // Panic path: call exit(134)
        wl_position_at_end(self.builder, panic_bb)
        self.emit_exit_call(134)
        wl_build_unreachable(self.builder)
        // Ok path: extract payload
        wl_position_at_end(self.builder, then_bb)
        return wl_build_extract_value(self.builder, obj, 1)
    if method == "expect" and arg_count > 0:
        // Same as unwrap but with message
        let then_bb = wl_append_bb(self.context, self.current_function, "expect.ok")
        let panic_bb = wl_append_bb(self.context, self.current_function, "expect.panic")
        wl_build_cond_br(self.builder, is_some, then_bb, panic_bb)
        wl_position_at_end(self.builder, panic_bb)
        // Print the error message first
        let msg = self.gen_expr(self.pool.get_extra(args_start))
        let printf_fn = self.ensure_printf_declared()
        let printf_ty = self.get_printf_fn_type()
        self.gen_print_value(msg, printf_fn, printf_ty)
        self.emit_exit_call(134)
        wl_build_unreachable(self.builder)
        wl_position_at_end(self.builder, then_bb)
        return wl_build_extract_value(self.builder, obj, 1)
    if method == "unwrap_or" and arg_count > 0:
        let default_val = self.gen_expr(self.pool.get_extra(args_start))
        let payload = wl_build_extract_value(self.builder, obj, 1)
        return wl_build_select(self.builder, is_some, payload, default_val)
    if method == "map" and arg_count > 0:
        // opt.map(fn) → if Some(x) then Some(fn(x)) else None
        let fn_val = self.gen_expr(self.pool.get_extra(args_start))
        let then_bb = wl_append_bb(self.context, self.current_function, "opt.some")
        let else_bb = wl_append_bb(self.context, self.current_function, "opt.none")
        let merge_bb = wl_append_bb(self.context, self.current_function, "opt.merge")
        wl_build_cond_br(self.builder, is_some, then_bb, else_bb)
        // Some path
        wl_position_at_end(self.builder, then_bb)
        let payload = wl_build_extract_value(self.builder, obj, 1)
        let fn_ty = wl_global_get_value_type(fn_val)
        let call_args: Vec[i64] = Vec.new()
        call_args.push(payload)
        let mapped = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&call_args), 1)
        let result_opt_ty = self.get_or_create_option_type(wl_type_of(mapped))
        let some_result = self.build_option_some(mapped, result_opt_ty)
        wl_build_br(self.builder, merge_bb)
        let then_end = wl_get_insert_block(self.builder)
        // None path
        wl_position_at_end(self.builder, else_bb)
        let none_result = self.build_option_none(result_opt_ty)
        wl_build_br(self.builder, merge_bb)
        let else_end = wl_get_insert_block(self.builder)
        // Merge
        wl_position_at_end(self.builder, merge_bb)
        let phi = wl_build_phi(self.builder, result_opt_ty)
        let phi_vals: Vec[i64] = Vec.new()
        let phi_bbs: Vec[i64] = Vec.new()
        phi_vals.push(some_result)
        phi_vals.push(none_result)
        phi_bbs.push(then_end)
        phi_bbs.push(else_end)
        wl_add_incoming(phi, vec_data_i64(&phi_vals), vec_data_i64(&phi_bbs), 2)
        return phi
    if method == "and_then" and arg_count > 0:
        // opt.and_then(fn) → if Some(x) then fn(x) else None
        let fn_val = self.gen_expr(self.pool.get_extra(args_start))
        let then_bb = wl_append_bb(self.context, self.current_function, "at.some")
        let else_bb = wl_append_bb(self.context, self.current_function, "at.none")
        let merge_bb = wl_append_bb(self.context, self.current_function, "at.merge")
        wl_build_cond_br(self.builder, is_some, then_bb, else_bb)
        wl_position_at_end(self.builder, then_bb)
        let payload = wl_build_extract_value(self.builder, obj, 1)
        let fn_ty = wl_global_get_value_type(fn_val)
        let call_args: Vec[i64] = Vec.new()
        call_args.push(payload)
        let then_result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&call_args), 1)
        wl_build_br(self.builder, merge_bb)
        let then_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, else_bb)
        let result_ty = wl_type_of(then_result)
        let none_result = wl_get_undef(result_ty)
        wl_build_br(self.builder, merge_bb)
        let else_end = wl_get_insert_block(self.builder)
        wl_position_at_end(self.builder, merge_bb)
        let phi = wl_build_phi(self.builder, result_ty)
        let phi_vals: Vec[i64] = Vec.new()
        let phi_bbs: Vec[i64] = Vec.new()
        phi_vals.push(then_result)
        phi_vals.push(none_result)
        phi_bbs.push(then_end)
        phi_bbs.push(else_end)
        wl_add_incoming(phi, vec_data_i64(&phi_vals), vec_data_i64(&phi_bbs), 2)
        return phi
    if method == "filter" and arg_count > 0:
        // opt.filter(pred) → if Some(x) and pred(x) then Some(x) else None
        return obj // Simplified stub
    if method == "or_else" and arg_count > 0:
        // opt.or_else(fn) → if Some return self else fn()
        return obj // Simplified stub
    if method == "flatten":
        // Option[Option[T]].flatten() → Option[T]
        return obj // Stub
    if method == "cloned":
        return obj // Clone is identity for most types
    if method == "zip" and arg_count > 0:
        return wl_get_undef(wl_i32_type(self.context)) // Stub
    if method == "transpose":
        return obj // Stub
    if method == "ok":
        // Result.ok() → Option[T]
        let payload = wl_build_extract_value(self.builder, obj, 1)
        let opt_ty = self.get_or_create_option_type(wl_type_of(payload))
        return wl_build_select(self.builder, is_some, self.build_option_some(payload, opt_ty), self.build_option_none(opt_ty))
    if method == "err":
        return wl_get_undef(wl_i32_type(self.context)) // Stub
    if method == "context" and arg_count > 0:
        return obj // Stub
    if method == "map_err" and arg_count > 0:
        return obj // Stub
    wl_get_undef(wl_i32_type(self.context))

fn Codegen.gen_diverge_builtin(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    if arg_count > 1:
        return wl_get_undef(wl_i32_type(self.context))
    if arg_count == 1:
        // Evaluate optional message expression for side effects.
        self.gen_expr(self.pool.get_extra(args_start))
    self.emit_exit_call(134)
    wl_build_unreachable(self.builder)

    // Maintain a valid insertion point for following source statements.
    let dead_bb = wl_append_bb(self.context, self.current_function, "diverge.dead")
    wl_position_at_end(self.builder, dead_bb)
    if self.expected_type != 0:
        return wl_get_undef(self.expected_type)
    wl_get_undef(wl_i32_type(self.context))

fn Codegen.gen_assert_call(self: Codegen, args_start: i32, arg_count: i32) -> i64:
    if arg_count < 1:
        return wl_get_undef(wl_i32_type(self.context))

    let cond = self.gen_expr(self.pool.get_extra(args_start))
    var cond_bool = cond
    let cond_ty = wl_type_of(cond)
    if cond_ty != wl_i1_type(self.context):
        cond_bool = wl_build_icmp(self.builder, wl_int_ne(), cond, wl_const_int(cond_ty, 0, 0))

    let fail_bb = wl_append_bb(self.context, self.current_function, "assert.fail")
    let ok_bb = wl_append_bb(self.context, self.current_function, "assert.ok")
    wl_build_cond_br(self.builder, cond_bool, ok_bb, fail_bb)

    wl_position_at_end(self.builder, fail_bb)
    if arg_count > 1:
        let printf_fn = self.ensure_printf_declared()
        let printf_ty = self.get_printf_fn_type()
        let msg = self.gen_expr(self.pool.get_extra(args_start + 1))
        self.gen_print_value(msg, printf_fn, printf_ty)
        let nl = wl_build_global_string_ptr(self.builder, "\n")
        let nl_args: Vec[i64] = Vec.new()
        nl_args.push(nl)
        wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(&nl_args), 1)

    self.emit_exit_call(134)
    wl_build_unreachable(self.builder)

    wl_position_at_end(self.builder, ok_bb)
    wl_const_int(wl_i32_type(self.context), 0, 0)

fn Codegen.emit_exit_call(self: Codegen, code: i32):
    let exit_fn = wl_get_named_function(self.llmod, "_exit")
    if exit_fn == 0:
        let i32_ty = wl_i32_type(self.context)
        let params: Vec[i64] = Vec.new()
        params.push(i32_ty)
        let fn_ty = wl_function_type(wl_void_type(self.context), vec_data_i64(&params), 1, 0)
        let f = wl_add_function(self.llmod, "_exit", fn_ty)
        let args: Vec[i64] = Vec.new()
        args.push(wl_const_int(i32_ty, code as i64, 0))
        wl_build_call(self.builder, fn_ty, f, vec_data_i64(&args), 1)
    else:
        let fn_ty = wl_global_get_value_type(exit_fn)
        let args: Vec[i64] = Vec.new()
        args.push(wl_const_int(wl_i32_type(self.context), code as i64, 0))
        wl_build_call(self.builder, fn_ty, exit_fn, vec_data_i64(&args), 1)

fn Codegen.emit_implicit_unreachable(self: Codegen, node: i32):
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let fprintf_fn = self.ensure_fprintf_declared()
    let fprintf_ty = wl_global_get_value_type(fprintf_fn)
    let stderr_global = self.ensure_stderr_declared()
    let stderr_ptr = wl_build_load(self.builder, ptr_ty, stderr_global)
    let fmt_ptr = wl_build_global_string_ptr(self.builder, "entered implicit unreachable code at %s:%d\n")
    let file_ptr = wl_build_global_string_ptr(self.builder, self.source_file)
    let line_val = wl_const_int(i32_ty, self.span_to_line(node) as i64, 0)

    let args: Vec[i64] = Vec.new()
    args.push(stderr_ptr)
    args.push(fmt_ptr)
    args.push(file_ptr)
    args.push(line_val)
    wl_build_call(self.builder, fprintf_ty, fprintf_fn, vec_data_i64(&args), 4)
    self.emit_exit_call(134)
    wl_build_unreachable(self.builder)
