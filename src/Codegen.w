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

extern fn with_eprintln(s: str) -> void

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
extern fn wl_init_target_machine(m: i64) -> i64
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
    struct_field_starts: Vec[i32],
    struct_field_counts: Vec[i32],
    struct_field_names: Vec[i32],
    struct_field_types: Vec[i64],
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

    // Trait decl nodes: sym → trait_decl_node
    trait_decl_nodes: HashMap[i32, i32],

    // VTable globals: hash(type,trait) → global
    vtable_globals: HashMap[i64, i64],

    // Trait-typed locals
    trait_locals: HashMap[i32, i32],
    trait_local_concrete_types: HashMap[i32, i32],

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
}

// ── Codegen lifecycle ─────────────────────────────────────────────

fn Codegen.init(module_name: str) -> Codegen:
    wl_init_native_target()
    wl_init_native_asm_printer()
    let ctx = wl_context_create()
    let mod = wl_module_create(module_name, ctx)
    let bld = wl_builder_create(ctx)
    let tm = wl_init_target_machine(mod)
    Codegen {
        context: ctx,
        llmod: mod,
        builder: bld,
        target_machine: tm,
        pool: AstPool.new(),
        intern: InternPool.init(),
        current_ret_type: 0,
        current_function: 0,
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
        struct_field_starts: Vec.new(),
        struct_field_counts: Vec.new(),
        struct_field_names: Vec.new(),
        struct_field_types: Vec.new(),
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
        trait_decl_nodes: HashMap.new(),
        vtable_globals: HashMap.new(),
        trait_locals: HashMap.new(),
        trait_local_concrete_types: HashMap.new(),
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

// ── Helper: is method symbol ──────────────────────────────────────

fn Codegen.is_method_symbol(self: Codegen, sym: i32) -> bool:
    let name = self.intern.resolve(sym)
    for i in 0..name.len() as i32:
        if name.byte_at(i as i64) == 46:  // '.'
            return true
    false

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
    if vk == wl_integer_type_kind() and tk == wl_float_type_kind():
        return wl_build_si_to_fp(self.builder, val, target_ty)
    if vk == wl_integer_type_kind() and tk == wl_double_type_kind():
        return wl_build_si_to_fp(self.builder, val, target_ty)
    if vk == wl_float_type_kind() and tk == wl_integer_type_kind():
        return wl_build_fp_to_si(self.builder, val, target_ty)
    if vk == wl_double_type_kind() and tk == wl_integer_type_kind():
        return wl_build_fp_to_si(self.builder, val, target_ty)
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

// ── Helper: create entry alloca ───────────────────────────────────

fn Codegen.create_entry_alloca(self: Codegen, ty: i64) -> i64:
    wl_create_entry_alloca(self.builder, self.current_function, ty)

fn vec_data_i64(v: Vec[i64]) -> i64:
    if v.len() == 0:
        return 0
    wl_vec_data_ptr(&v)

// ── Resolve type expression → LLVM type ───────────────────────────

fn Codegen.resolve_type(self: Codegen, type_node: i32) -> i64:
    if type_node == 0: return wl_void_type(self.context)
    let kind = self.pool.kind(type_node)

    if kind == NK_TYPE_NAMED():
        let sym = self.pool.get_data0(type_node)
        return self.resolve_named_type(sym)

    if kind == NK_TYPE_PTR():
        // Check for dyn trait pointer
        let pointee = self.pool.get_data0(type_node)
        if self.pool.kind(pointee) == NK_TYPE_TRAIT_OBJ():
            // Fat pointer {data_ptr, vtable_ptr}
            let ptr_ty = wl_ptr_type(self.context)
            let fat_types: Vec[i64] = Vec.new()
            fat_types.push(ptr_ty)
            fat_types.push(ptr_ty)
            return wl_struct_type(self.context, vec_data_i64(fat_types), 2, 0)
        return wl_ptr_type(self.context)

    if kind == NK_TYPE_REF():
        let pointee = self.pool.get_data0(type_node)
        if self.pool.kind(pointee) == NK_TYPE_TRAIT_OBJ():
            let ptr_ty = wl_ptr_type(self.context)
            let fat_types: Vec[i64] = Vec.new()
            fat_types.push(ptr_ty)
            fat_types.push(ptr_ty)
            return wl_struct_type(self.context, vec_data_i64(fat_types), 2, 0)
        return wl_ptr_type(self.context)

    if kind == NK_TYPE_FN():
        // Function type → fat pointer {fn_ptr, ctx_ptr}
        let ptr_ty = wl_ptr_type(self.context)
        let fat_types: Vec[i64] = Vec.new()
        fat_types.push(ptr_ty)
        fat_types.push(ptr_ty)
        return wl_struct_type(self.context, vec_data_i64(fat_types), 2, 0)

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
        return wl_struct_type(self.context, vec_data_i64(body_types), 2, 0)

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
        return wl_struct_type(self.context, vec_data_i64(elem_types), elem_count, 0)

    if kind == NK_TYPE_GENERIC():
        let name_sym = self.pool.get_data0(type_node)
        let g_extra = self.pool.get_data1(type_node)
        let g_count = self.pool.get_data2(type_node)
        return self.resolve_generic_type(name_sym, g_extra, g_count)

    if kind == NK_TYPE_TRAIT_OBJ():
        // dyn Trait → fat pointer {data_ptr, vtable_ptr}
        let ptr_ty = wl_ptr_type(self.context)
        let fat_types: Vec[i64] = Vec.new()
        fat_types.push(ptr_ty)
        fat_types.push(ptr_ty)
        return wl_struct_type(self.context, vec_data_i64(fat_types), 2, 0)

    if kind == NK_TYPE_INFERRED():
        return 0  // Cannot resolve inferred types

    // Fallback
    wl_i32_type(self.context)

fn Codegen.resolve_named_type(self: Codegen, sym: i32) -> i64:
    let name = self.intern.resolve(sym)
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
    if name == "Unit": return wl_i32_type(self.context)
    // Check active type bindings (monomorphization)
    for i in 0..self.type_bindings_len:
        if self.type_binding_syms.get(i as i64) == sym:
            return self.type_binding_types.get(i as i64)
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
    // Unsupported
    0

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
            let ptr_ty = wl_ptr_type(self.context)
            let fat_types: Vec[i64] = Vec.new()
            fat_types.push(ptr_ty)
            fat_types.push(ptr_ty)
            return wl_struct_type(self.context, vec_data_i64(fat_types), 2, 0)
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
    self.struct_field_starts.push(self.struct_field_names.len() as i32)
    self.struct_field_counts.push(2)

    let ptr_sym = self.intern.intern("ptr")
    let len_sym = self.intern.intern("len")
    self.struct_field_names.push(ptr_sym)
    self.struct_field_names.push(len_sym)
    self.struct_field_types.push(wl_ptr_type(self.context))
    self.struct_field_types.push(wl_i64_type(self.context))
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
        self.struct_field_defaults.push(f_default)
        ft_vec.push(f_ty)

    if invalid_layout != 0:
        return

    // Set struct body
    wl_struct_set_body(st_type, vec_data_i64(ft_vec), field_count, 0)

// ── Declare enum type ─────────────────────────────────────────────

fn Codegen.declare_enum_type(self: Codegen, name_sym: i32, type_node: i32):
    let extra_start = self.pool.get_data1(type_node)
    let variant_count = self.pool.get_extra(extra_start)

    // Find the largest payload to determine enum struct size.
    // Enum is { i32 tag, [N x i8] payload }.
    var max_payload_size: i64 = 0
    let dl = wl_get_module_data_layout(self.llmod)

    let v_starts = self.enum_variant_names.len() as i32
    var offset = extra_start + 1
    for vi in 0..variant_count:
        let v_name = self.pool.get_extra(offset)
        let v_payload_count = self.pool.get_extra(offset + 1)
        offset = offset + 2
        var payload_ty: i64 = 0
        if v_payload_count > 0:
            let p_type_node = self.pool.get_extra(offset)
            payload_ty = self.resolve_type(p_type_node)
            let sz = wl_abi_size_of(dl, payload_ty)
            if sz > max_payload_size:
                max_payload_size = sz
            offset = offset + v_payload_count
        self.enum_variant_names.push(v_name)
        self.enum_variant_payloads.push(payload_ty)

    // Build enum struct: { i32, [N x i8] }
    if not self.enum_type_map.get(name_sym).is_some():
        self.predeclare_enum_type(name_sym)
    let idx = self.enum_type_map.get(name_sym).unwrap()
    let enum_type = self.enum_llvm_types.get(idx as i64)
    let body: Vec[i64] = Vec.new()
    body.push(wl_i32_type(self.context))
    if max_payload_size > 0:
        body.push(wl_array_type(wl_i8_type(self.context), max_payload_size))
    wl_struct_set_body(enum_type, vec_data_i64(body), body.len() as i32, 0)

    self.enum_variant_starts.set_i32(idx as i64, v_starts)
    self.enum_variant_counts.set_i32(idx as i64, variant_count)

// ── Declare function ──────────────────────────────────────────────

fn Codegen.declare_function(self: Codegen, fn_node: i32):
    let name_sym = self.pool.get_data0(fn_node)
    let flags = self.pool.get_data2(fn_node)
    let meta = self.pool.find_fn_meta(fn_node)
    if meta < 0: return

    let ret_type_node = self.pool.fn_meta_ret(meta)
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)

    let ret_ty = self.resolve_type(ret_type_node)

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
    let name_str = self.intern.resolve(name_sym)

    // Check if method (has dot in name)
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
        if pi == 0 and method_owner_sym != 0 and p_kind == NK_TYPE_NAMED():
            let p_sym = self.pool.get_data0(p_type_node)
            let p_name_str = self.intern.resolve(p_sym)
            if p_name_str == "Self" or p_sym == method_owner_sym:
                param_types.push(wl_ptr_type(self.context))
                has_ref_param = true
                // Record ref param
                self.record_ref_param(name_sym, pi, param_count)
                pi = pi + 1
                continue

        // fn type params → fat pointer
        if p_kind == NK_TYPE_FN():
            let ptr_ty = wl_ptr_type(self.context)
            let fat: Vec[i64] = Vec.new()
            fat.push(ptr_ty)
            fat.push(ptr_ty)
            param_types.push(wl_struct_type(self.context, vec_data_i64(fat), 2, 0))
            pi = pi + 1
            continue

        // dyn Trait params
        if p_kind == NK_TYPE_TRAIT_OBJ():
            let trait_sym = self.pool.get_data0(p_type_node)
            param_types.push(self.resolve_type(p_type_node))
            self.record_dyn_param(name_sym, pi, param_count, trait_sym)
            pi = pi + 1
            continue

        // Reference params
        if p_kind == NK_TYPE_REF():
            param_types.push(self.resolve_type(p_type_node))
            has_ref_param = true
            self.record_ref_param(name_sym, pi, param_count)
            pi = pi + 1
            continue

        param_types.push(self.resolve_type(p_type_node))
        pi = pi + 1

    let fn_type = wl_function_type(ret_ty, vec_data_i64(param_types), param_count, 0)

    // Use "main" for @[entry] functions
    var effective_name = name_str
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
    // Skip duplicate declarations
    if self.fn_values.get(name_sym).is_some(): return

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

    let fn_type = wl_function_type(ret_ty, vec_data_i64(param_types), param_count, is_variadic)

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

    // Option[T] = { i32 tag, [N x i8] payload }
    let dl = wl_get_module_data_layout(self.llmod)
    let payload_size = wl_abi_size_of(dl, payload_ty)
    let body: Vec[i64] = Vec.new()
    body.push(wl_i32_type(self.context))
    if payload_size > 0:
        body.push(wl_array_type(wl_i8_type(self.context), payload_size))
    let opt_type = wl_struct_type(self.context, vec_data_i64(body), body.len() as i32, 0)

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

    let dl = wl_get_module_data_layout(self.llmod)
    let ok_size = wl_abi_size_of(dl, ok_ty)
    let err_size = wl_abi_size_of(dl, err_ty)
    var max_size = ok_size
    if err_size > max_size: max_size = err_size

    let body: Vec[i64] = Vec.new()
    body.push(wl_i32_type(self.context))
    if max_size > 0:
        body.push(wl_array_type(wl_i8_type(self.context), max_size))
    let res_type = wl_struct_type(self.context, vec_data_i64(body), body.len() as i32, 0)

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
    wl_struct_type(self.context, vec_data_i64(body), 2, 0)

// ── Vec/HashMap/HashSet type construction ─────────────────────────

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
    let vec_ty = wl_struct_type(self.context, vec_data_i64(body), 4, 0)
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
        return self.hm_llvm_types.get(idx as i64)
    // HashMap is opaque { ptr }
    let body: Vec[i64] = Vec.new()
    body.push(wl_ptr_type(self.context))
    let hm_ty = wl_struct_type(self.context, vec_data_i64(body), 1, 0)
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
    let hs_ty = wl_struct_type(self.context, vec_data_i64(body), 1, 0)
    let idx = self.hs_llvm_types.len() as i32
    self.hs_llvm_types.push(hs_ty)
    self.hs_elem_types.push(elem_ty)
    self.hs_cache_map.insert(elem_ty, idx)
    hs_ty

// ── Monomorphize struct (stub) ────────────────────────────────────

fn Codegen.monomorphize_struct(self: Codegen, name_sym: i32, extra_start: i32, arg_count: i32) -> i64:
    // TODO: full monomorphization
    wl_i32_type(self.context)

// ── Build Option Some/None ────────────────────────────────────────

fn Codegen.build_option_some(self: Codegen, payload: i64, opt_type: i64) -> i64:
    let alloca = wl_build_alloca(self.builder, opt_type)
    // Store tag = 1 (Some)
    let tag_ptr = wl_build_struct_gep(self.builder, opt_type, alloca, 0)
    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), 1, 0), tag_ptr)
    // Store payload via bitcast
    let elem_count = wl_count_struct_elem_types(opt_type)
    if elem_count > 1:
        let payload_ptr = wl_build_struct_gep(self.builder, opt_type, alloca, 1)
        let payload_ty = wl_type_of(payload)
        let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
        wl_build_store(self.builder, payload, cast_ptr)
    wl_build_load(self.builder, opt_type, alloca)

fn Codegen.build_option_none(self: Codegen, opt_type: i64) -> i64:
    let alloca = wl_build_alloca(self.builder, opt_type)
    let tag_ptr = wl_build_struct_gep(self.builder, opt_type, alloca, 0)
    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), 0, 0), tag_ptr)
    wl_build_load(self.builder, opt_type, alloca)

fn Codegen.build_result_ok(self: Codegen, val: i64, res_type: i64) -> i64:
    let alloca = wl_build_alloca(self.builder, res_type)
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
                wl_build_call(self.builder, dft.unwrap() as i64, dfv.unwrap() as i64, vec_data_i64(args), 1)
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
    wl_function_type(ret_ty, vec_data_i64(param_types), param_count + 1, 0)

// ── gen_module: multi-pass entry point ────────────────────────────

fn Codegen.gen_module(self: Codegen, pool: AstPool, intern: InternPool) -> i32:
    self.pool = pool
    self.intern = intern

    // Declare built-in str type before user types
    self.declare_builtin_str_type()

    // Pass 0a: predeclare all struct/enum names so forward references resolve.
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NK_TYPE_DECL():
            let name_sym = self.pool.get_data0(decl)
            let sub_kind = self.pool.get_data2(decl)
            if sub_kind == TDK_STRUCT():
                self.predeclare_struct_type(name_sym)
            else if sub_kind == TDK_ENUM():
                self.predeclare_enum_type(name_sym)

    // Pass 0b: define struct/enum bodies and type aliases.
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NK_TYPE_DECL():
            let name_sym = self.pool.get_data0(decl)
            let sub_kind = self.pool.get_data2(decl)
            if sub_kind == TDK_STRUCT():
                self.declare_struct_type(name_sym, decl)
            else if sub_kind == TDK_ENUM():
                self.declare_enum_type(name_sym, decl)
            else if sub_kind == TDK_ALIAS():
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
        if kind == NK_FN_DECL():
            let flags = self.pool.get_data2(decl)
            let meta = self.pool.find_fn_meta(decl)
            // Skip generic functions (store for monomorphization)
            if meta >= 0:
                let tp_count = self.pool.fn_meta_tp_count(meta)
                if tp_count > 0:
                    let name_sym = self.pool.get_data0(decl)
                    self.generic_fns.insert(name_sym, decl)
                else if (flags / FN_FLAG_ASYNC()) % 2 == 1:
                    self.declare_function(decl)
                else:
                    self.declare_function(decl)
        else if kind == NK_EXTERN_FN():
            self.declare_extern_fn(decl)

    // Pass 1.5: detect drop functions
    self.detect_drop_functions()

    // Pass 2: generate function bodies
    for i in 0..self.pool.decl_count():
        let decl = self.pool.get_decl(i)
        let kind = self.pool.kind(decl)
        if kind == NK_FN_DECL():
            let flags = self.pool.get_data2(decl)
            let meta = self.pool.find_fn_meta(decl)
            if meta >= 0:
                let tp_count = self.pool.fn_meta_tp_count(meta)
                if tp_count == 0 and (flags / FN_FLAG_ASYNC()) % 2 == 0:
                    self.gen_function(decl)

    // Wrap main for exit
    self.wrap_main_for_exit()

    // Verify
    self.verify()

// ── Collect trait info ────────────────────────────────────────────

fn Codegen.collect_trait_info(self: Codegen, trait_node: i32):
    let name_sym = self.pool.get_data0(trait_node)
    let extra_start = self.pool.get_data1(trait_node)
    // Trait extra has method name syms (one per method, added by parser)
    // We need to figure out method count. Walk the extra until we hit something invalid.
    // Actually, trait methods were added to extra as just name syms.
    // For now, store the trait decl node for later use.
    self.trait_decl_nodes.insert(name_sym, trait_node)

// ── Generate module constant ──────────────────────────────────────

fn Codegen.gen_module_constant(self: Codegen, let_node: i32):
    let name_sym = self.pool.get_data0(let_node)
    let value_node = self.pool.get_data1(let_node)
    if value_node == 0: return

    // Only handle simple constants (int/float/bool/string literals)
    let vk = self.pool.kind(value_node)
    if vk == NK_INT_LIT():
        let val_lo = self.pool.get_data0(value_node)
        let global_ty = wl_i32_type(self.context)
        let name_str = self.intern.resolve(name_sym)
        let global = wl_add_global(self.llmod, global_ty, name_str)
        wl_set_initializer(global, wl_const_int(global_ty, val_lo as i64, 1))
        wl_set_global_constant(global, 1)
        wl_set_linkage(global, wl_internal_linkage())
        self.module_constants.insert(name_sym, global)

// ── Wrap main for exit ────────────────────────────────────────────

fn Codegen.wrap_main_for_exit(self: Codegen):
    // If user's main returns void, create an OS-facing wrapper that returns 0.
    let main_fn = wl_get_named_function(self.llmod, "main")
    if main_fn == 0: return
    let main_ft = wl_global_get_value_type(main_fn)
    let ret_ty = wl_get_return_type(main_ft)
    if ret_ty == wl_void_type(self.context):
        // Rename user main to __with_main
        wl_set_value_name(main_fn, "__with_main")
        // Create new main: i32 main() { __with_main(); return 0; }
        let i32_ty = wl_i32_type(self.context)
        let wrapper_ft = wl_function_type(i32_ty, 0, 0, 0)
        let wrapper = wl_add_function(self.llmod, "main", wrapper_ft)
        let bb = wl_append_bb(self.context, wrapper, "entry")
        wl_position_at_end(self.builder, bb)
        wl_build_call(self.builder, main_ft, main_fn, 0, 0)
        wl_build_ret(self.builder, wl_const_int(i32_ty, 0, 0))

// ── gen_function: generate a function body ────────────────────────

fn Codegen.gen_function(self: Codegen, fn_node: i32):
    let name_sym = self.pool.get_data0(fn_node)
    let body_node = self.pool.get_data1(fn_node)
    let flags = self.pool.get_data2(fn_node)

    let fv = self.fn_values.get(name_sym)
    if not fv.is_some(): return
    let function = fv.unwrap() as i64
    let ft = self.fn_fn_types.get(name_sym)
    if not ft.is_some(): return
    let fn_type = ft.unwrap() as i64

    self.current_function = function
    self.current_ret_type = wl_get_return_type(fn_type)
    self.current_method_owner_sym = 0

    // Clear locals
    self.local_allocas = HashMap.new()
    self.local_types = HashMap.new()
    self.local_muts = HashMap.new()
    self.local_fn_sigs = HashMap.new()
    self.local_pointee_structs = HashMap.new()
    self.task_locals = HashMap.new()
    self.scope_local_count = 0
    self.defer_stack = Vec.new()
    self.trait_locals = HashMap.new()
    self.trait_local_concrete_types = HashMap.new()

    // Save/set expected type
    let saved_expected = self.expected_type
    self.expected_type = self.current_ret_type
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
    self.tailrec_body_bb = 0
    self.tailrec_fn_sym = 0

    // Create entry block
    let entry = wl_append_bb(self.context, function, "entry")
    wl_position_at_end(self.builder, entry)

    // Add parameters as locals
    let meta = self.pool.find_fn_meta(fn_node)
    if meta < 0: return
    let param_start = self.pool.fn_meta_param_start(meta)
    let param_count = self.pool.fn_meta_param_count(meta)

    // Detect method owner
    let name_str = self.intern.resolve(name_sym)
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

        self.local_allocas.insert(p_name, alloca)
        self.local_types.insert(p_name, param_type)
        self.local_muts.insert(p_name, 1)  // treat all as mutable for codegen

        // Track fn_sig for function pointer params
        if p_type_node != 0:
            let pk = self.pool.kind(p_type_node)
            if pk == NK_TYPE_FN():
                let fn_sig = self.build_fn_type_from_ast(p_type_node)
                self.local_fn_sigs.insert(p_name, fn_sig)
            // Track pointee struct for pointer/ref params
            if pk == NK_TYPE_PTR() or pk == NK_TYPE_REF():
                let pointee_node = self.pool.get_data0(p_type_node)
                if self.pool.kind(pointee_node) == NK_TYPE_NAMED():
                    let ps = self.pool.get_data0(pointee_node)
                    if self.struct_type_map.get(ps).is_some():
                        self.local_pointee_structs.insert(p_name, ps)
            // Track method self pointee
            if pi == 0 and method_owner_sym != 0 and pk == NK_TYPE_NAMED():
                let p_sym = self.pool.get_data0(p_type_node)
                let p_n = self.intern.resolve(p_sym)
                if p_n == "Self" or p_sym == method_owner_sym:
                    self.local_pointee_structs.insert(p_name, method_owner_sym)
            if pi == 0 and method_owner_sym != 0:
                let p_n = self.intern.resolve(p_name)
                if p_n == "self":
                    self.local_pointee_structs.insert(p_name, method_owner_sym)
            // Track dyn trait params
            if pk == NK_TYPE_TRAIT_OBJ():
                let trait_sym = self.pool.get_data0(p_type_node)
                self.trait_locals.insert(p_name, trait_sym)

    // @[tailrec]: create body BB
    if (flags / FN_FLAG_TAILREC()) % 2 == 1 and param_count > 0:
        let body_bb = wl_append_bb(self.context, function, "tailrec.body")
        wl_build_br(self.builder, body_bb)
        wl_position_at_end(self.builder, body_bb)
        self.tailrec_body_bb = body_bb
        self.tailrec_fn_sym = name_sym
        // Collect param allocas
        self.tailrec_param_allocas = Vec.new()
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
                        wl_build_ret(self.builder, wrapped)
                    else if self.current_fn_saw_explicit_return:
                        wl_build_unreachable(self.builder)
                    else:
                        wl_build_unreachable(self.builder)
                else:
                    let default_val = self.build_default_value(ret_type)
                    wl_build_ret(self.builder, default_val)
            else if body_type != ret_type and self.current_fn_returns_result:
                let wrapped = self.build_result_ok(body_val, ret_type)
                wl_build_ret(self.builder, wrapped)
            else:
                let coerced = self.coerce_int(body_val, ret_type)
                wl_build_ret(self.builder, coerced)
        else:
            wl_build_ret_void(self.builder)

    // Restore state
    self.expected_type = saved_expected
    self.current_result_err_symbol = saved_result_err
    self.current_fn_returns_result = saved_returns_result
    self.current_fn_saw_explicit_return = saved_saw_return
    self.tailrec_body_bb = saved_tailrec_bb
    self.tailrec_fn_sym = saved_tailrec_sym

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
    if kind == NK_YIELD(): return self.gen_yield(node)
    if kind == NK_AWAIT(): return self.gen_await(node)
    if kind == NK_SPAWN(): return self.gen_spawn(node)
    if kind == NK_COMPTIME(): return self.gen_comptime(node)
    if kind == NK_ARRAY_COMPREHENSION(): return self.gen_array_comprehension(node)

    // Unsupported
    wl_get_undef(wl_void_type(self.context))

// ── Literal expressions ───────────────────────────────────────────

fn Codegen.gen_int_lit(self: Codegen, node: i32) -> i64:
    let val_lo = self.pool.get_data0(node)
    let val_hi = self.pool.get_data1(node)
    let val = (val_hi as i64) * 65536 * 65536 + (val_lo as i64)
    if val >= (0 - 2147483647 - 1) as i64 and val <= 2147483647:
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
    self.gen_string_literal_raw(text)

fn Codegen.gen_c_string_lit(self: Codegen, node: i32) -> i64:
    let sym = self.pool.get_data0(node)
    let text = self.intern.resolve(sym)
    wl_build_global_string_ptr(self.builder, text)

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
    let local_opt = self.local_allocas.get(sym)
    if local_opt.is_some():
        let alloca = local_opt.unwrap() as i64
        let ty_opt = self.local_types.get(sym)
        if ty_opt.is_some():
            let ty = ty_opt.unwrap() as i64
            return wl_build_load(self.builder, ty, alloca)
        return wl_build_load(self.builder, wl_i32_type(self.context), alloca)

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
                    let tag_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 0)
                    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), vi as i64, 0), tag_ptr)
                    return wl_build_load(self.builder, enum_ty, alloca)

    // Not found
    wl_get_undef(wl_i32_type(self.context))

// ── Binary expression ─────────────────────────────────────────────

fn Codegen.gen_binary(self: Codegen, node: i32) -> i64:
    let op = self.pool.get_data0(node)
    let lhs_node = self.pool.get_data1(node)
    let rhs_node = self.pool.get_data2(node)

    // Short-circuit for && and ||
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
    wl_add_incoming(phi, vec_data_i64(vals), vec_data_i64(bbs), 2)
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
    wl_add_incoming(phi, vec_data_i64(vals), vec_data_i64(bbs), 2)
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
        return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(args), 2)
    // Fallback: declare it
    let str_ty = self.resolve_named_type(self.intern.intern("str"))
    let param_types: Vec[i64] = Vec.new()
    param_types.push(str_ty)
    param_types.push(str_ty)
    let fn_type = wl_function_type(str_ty, vec_data_i64(param_types), 2, 0)
    let func = wl_add_function(self.llmod, "with_str_concat", fn_type)
    self.fn_values.insert(concat_sym, func)
    self.fn_fn_types.insert(concat_sym, fn_type)
    let args: Vec[i64] = Vec.new()
    args.push(lhs)
    args.push(rhs)
    wl_build_call(self.builder, fn_type, func, vec_data_i64(args), 2)

fn Codegen.gen_default_op(self: Codegen, lhs_node: i32, rhs_node: i32) -> i64:
    // ?? operator: if lhs is Some, unwrap it; else use rhs
    let lhs = self.gen_expr(lhs_node)
    let lty = wl_type_of(lhs)
    // Extract tag
    let tag = wl_build_extract_value(self.builder, lhs, 0)
    let is_some = wl_build_icmp(self.builder, wl_int_ne(), tag, wl_const_int(wl_i32_type(self.context), 0, 0))
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
    wl_add_incoming(phi, vec_data_i64(vals), vec_data_i64(bbs), 2)
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
        return wl_build_not(self.builder, val)

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
            wl_build_ret(self.builder, val)
        else:
            wl_build_ret_void(self.builder)
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
        self.gen_expr(stmt)
        // Check if current block is terminated
        let bb = wl_get_insert_block(self.builder)
        if wl_get_bb_terminator(bb) != 0:
            self.scope_local_count = saved_scope
            return wl_get_undef(wl_void_type(self.context))
    if tail_node != 0:
        result = self.gen_expr(tail_node)
    self.emit_drops(saved_scope)
    result

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
            wl_add_incoming(phi, vec_data_i64(vals), vec_data_i64(bbs), 2)
            return phi
    if not then_terminated: return then_val
    wl_get_undef(wl_void_type(self.context))

// ── Let binding ───────────────────────────────────────────────────

fn Codegen.gen_let_binding(self: Codegen, node: i32) -> i64:
    let name_sym = self.pool.get_data0(node)
    let value_node = self.pool.get_data1(node)
    let flags = self.pool.get_data2(node)
    let is_mut = flags % 2
    let val = self.gen_expr(value_node)
    let val_ty = wl_type_of(val)
    let alloca = self.create_entry_alloca(val_ty)
    wl_build_store(self.builder, val, alloca)
    self.local_allocas.insert(name_sym, alloca)
    self.local_types.insert(name_sym, val_ty)
    self.local_muts.insert(name_sym, is_mut)
    // Track for scope drops
    self.scope_local_syms.push(name_sym)
    self.scope_local_allocas.push(alloca)
    self.scope_local_types.push(val_ty)
    self.scope_local_count = self.scope_local_count + 1
    // Track vec/hashmap/enum local types
    self.track_local_type(name_sym, value_node, val_ty)
    wl_get_undef(wl_void_type(self.context))

fn Codegen.track_local_type(self: Codegen, sym: i32, value_node: i32, val_ty: i64):
    // Track vec element types for Vec locals
    let vc = self.vec_cache_map.get(val_ty)
    if vc.is_some():
        let idx = vc.unwrap()
        self.vec_local_types.insert(sym, self.vec_elem_types.get(idx as i64))
    // Track enum local types
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
    let is_some = wl_build_icmp(self.builder, wl_int_ne(), tag, wl_const_int(wl_i32_type(self.context), 0, 0))
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
        self.local_allocas.insert(sym, alloca)
        self.local_types.insert(sym, ty)
        self.local_muts.insert(sym, 0)
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
            self.local_allocas.insert(bind_sym, alloca)
            self.local_types.insert(bind_sym, ty)
            self.local_muts.insert(bind_sym, 0)

// ── Return expression ─────────────────────────────────────────────

fn Codegen.gen_return(self: Codegen, node: i32) -> i64:
    let value_node = self.pool.get_data0(node)
    self.current_fn_saw_explicit_return = true
    self.emit_drops(0)
    self.emit_defers()
    if value_node == 0:
        if self.current_ret_type == wl_void_type(self.context):
            wl_build_ret_void(self.builder)
        else:
            let default_val = self.build_default_value(self.current_ret_type)
            wl_build_ret(self.builder, default_val)
    else:
        let val = self.gen_expr(value_node)
        let val_ty = wl_type_of(val)
        if self.current_fn_returns_result and val_ty != self.current_ret_type:
            let wrapped = self.build_result_ok(val, self.current_ret_type)
            wl_build_ret(self.builder, wrapped)
        else:
            let coerced = self.coerce_int(val, self.current_ret_type)
            wl_build_ret(self.builder, coerced)
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
            let ps = self.local_pointee_structs.get(sym)
            if ps.is_some():
                let st_opt = self.struct_type_map.get(ps.unwrap())
                if st_opt.is_some():
                    let st_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
                    let fi = self.find_field_index(ps.unwrap(), field_sym)
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
        let la = self.local_allocas.get(sym)
        if la.is_some():
            let alloca = la.unwrap() as i64
            let ty_opt = self.local_types.get(sym)
            if ty_opt.is_some():
                let ty = ty_opt.unwrap() as i64
                let type_sym = self.find_struct_type_by_llvm(ty)
                if type_sym != 0:
                    let fi = self.find_field_index(type_sym, field_sym)
                    if fi >= 0:
                        return wl_build_struct_gep(self.builder, ty, alloca, fi)
                // Check pointee struct
                var pointee_sym = 0
                let ps = self.local_pointee_structs.get(sym)
                if ps.is_some():
                    pointee_sym = ps.unwrap()
                else if self.current_method_owner_sym != 0 and self.intern.resolve(sym) == "self":
                    pointee_sym = self.current_method_owner_sym
                if pointee_sym != 0:
                    let st_opt = self.struct_type_map.get(pointee_sym)
                    if st_opt.is_some():
                        let st_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
                        let fi = self.find_field_index(pointee_sym, field_sym)
                        if fi >= 0:
                            let ptr = wl_build_load(self.builder, wl_ptr_type(self.context), alloca)
                            return wl_build_struct_gep(self.builder, st_ty, ptr, fi)
    // Nested field access
    if self.pool.kind(obj_node) == NK_FIELD_ACCESS():
        let inner_obj = self.pool.get_data0(obj_node)
        let inner_field = self.pool.get_data1(obj_node)
        let inner_ptr = self.gen_field_access_ptr(inner_obj, inner_field)
        if inner_ptr != 0:
            // Load the inner field, then get sub-field
            // This is complex — for now just return 0
            return 0
    0

fn Codegen.find_struct_type_by_llvm(self: Codegen, llvm_ty: i64) -> i32:
    for i in 0..self.struct_llvm_types.len() as i32:
        if self.struct_llvm_types.get(i as i64) == llvm_ty:
            // Walk struct_type_map to find the sym
            // Since we can't iterate HashMap[i32,i32], use a reverse lookup approach
            // For now, scan decls
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

fn Codegen.find_field_index(self: Codegen, type_sym: i32, field_sym: i32) -> i32:
    let st_opt = self.struct_type_map.get(type_sym)
    if not st_opt.is_some(): return 0 - 1
    let idx = st_opt.unwrap()
    let start = self.struct_field_starts.get(idx as i64)
    let count = self.struct_field_counts.get(idx as i64)
    for i in 0..count:
        if self.struct_field_names.get((start + i) as i64) == field_sym:
            return i
    0 - 1

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
        let gep = wl_build_gep(self.builder, arr_ty, alloca, vec_data_i64(indices), 2)
        return wl_build_load(self.builder, elem_ty, gep)
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
                    return wl_build_gep(self.builder, ty, alloca, vec_data_i64(indices), 2)
    0

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
        let fn_name = self.intern.resolve(fn_sym)

        // Built-in: println/print
        if fn_name == "println":
            return self.gen_println(args_start, arg_count)
        if fn_name == "print":
            return self.gen_print_call(args_start, arg_count)
        if fn_name == "eprintln":
            return self.gen_eprintln(args_start, arg_count)

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

        // Tail-call optimization
        if self.tailrec_body_bb != 0 and fn_sym == self.tailrec_fn_sym:
            return self.gen_tailrec_call(args_start, arg_count)

        // Regular function call
        let fv = self.fn_values.get(fn_sym)
        let ft = self.fn_fn_types.get(fn_sym)
        if fv.is_some() and ft.is_some():
            let args: Vec[i64] = Vec.new()
            for ai in 0..arg_count:
                let arg_node = self.pool.get_extra(args_start + ai)
                let arg = self.gen_expr(arg_node)
                args.push(arg)
            return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(args), arg_count)

        // Check if it's a function pointer local
        let la = self.local_allocas.get(fn_sym)
        if la.is_some():
            let fs = self.local_fn_sigs.get(fn_sym)
            if fs.is_some():
                let fn_ptr_alloca = la.unwrap() as i64
                let fn_ty_opt = self.local_types.get(fn_sym)
                if fn_ty_opt.is_some():
                    let fat_ptr = wl_build_load(self.builder, fn_ty_opt.unwrap() as i64, fn_ptr_alloca)
                    let fn_ptr = wl_build_extract_value(self.builder, fat_ptr, 0)
                    let ctx_ptr = wl_build_extract_value(self.builder, fat_ptr, 1)
                    let args: Vec[i64] = Vec.new()
                    args.push(ctx_ptr)
                    for ai in 0..arg_count:
                        let arg_node = self.pool.get_extra(args_start + ai)
                        args.push(self.gen_expr(arg_node))
                    return wl_build_call(self.builder, fs.unwrap() as i64, fn_ptr, vec_data_i64(args), arg_count + 1)

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
            return wl_build_call(self.builder, gvt, callee, vec_data_i64(args), arg_count)
    wl_get_undef(wl_i32_type(self.context))

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
    let method_name = self.intern.resolve(method_sym)

    let obj = self.gen_expr(obj_node)
    let obj_ty = wl_type_of(obj)

    // Find the type name for this object
    let type_sym = self.find_struct_type_by_llvm(obj_ty)

    // String methods
    let str_sym = self.intern.intern("str")
    if type_sym == str_sym:
        return self.gen_str_method(method_name, obj, args_start, arg_count)

    // Vec methods
    let vc = self.vec_cache_map.get(obj_ty)
    if vc.is_some():
        return self.gen_vec_method(method_name, obj, args_start, arg_count, obj_node)

    // HashMap methods
    let hmc = self.hm_cache_map.get(obj_ty)
    if hmc.is_some():
        return self.gen_hashmap_method(method_name, obj, args_start, arg_count, hmc.unwrap())

    // Option methods (is_some, unwrap, etc.)
    let oc = self.option_cache_map.get(obj_ty)
    if oc.is_some():
        return self.gen_option_method(method_name, obj, args_start, arg_count)

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
            return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(args), arg_count + 1)

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
                    return wl_build_call(self.builder, ft.unwrap() as i64, fv.unwrap() as i64, vec_data_i64(args), arg_count + 1)

    wl_get_undef(wl_i32_type(self.context))

fn Codegen.get_mutable_receiver_ptr(self: Codegen, recv_node: i32, recv_val: i64, recv_ty: i64) -> i64:
    let rk = self.pool.kind(recv_node)
    if rk == NK_IDENT():
        let sym = self.pool.get_data0(recv_node)
        let la = self.local_allocas.get(sym)
        if la.is_some():
            let alloca = la.unwrap() as i64
            let lt = self.local_types.get(sym)
            if lt.is_some():
                let local_ty = lt.unwrap() as i64
                var has_pointee = self.local_pointee_structs.get(sym).is_some()
                if not has_pointee and self.current_method_owner_sym != 0 and self.intern.resolve(sym) == "self":
                    has_pointee = true
                if wl_get_type_kind(local_ty) == wl_pointer_type_kind() and has_pointee:
                    return wl_build_load(self.builder, local_ty, alloca)
            return alloca
    if rk == NK_FIELD_ACCESS():
        let base = self.pool.get_data0(recv_node)
        let field = self.pool.get_data1(recv_node)
        if self.pool.kind(base) == NK_IDENT():
            let base_sym = self.pool.get_data0(base)
            let base_alloca_opt = self.local_allocas.get(base_sym)
            if base_alloca_opt.is_some():
                let base_alloca = base_alloca_opt.unwrap() as i64
                let base_ty_opt = self.local_types.get(base_sym)
                if base_ty_opt.is_some():
                    let base_ty = base_ty_opt.unwrap() as i64
                    var st_sym = 0
                    let ps = self.local_pointee_structs.get(base_sym)
                    if ps.is_some():
                        st_sym = ps.unwrap()
                    else if self.current_method_owner_sym != 0 and self.intern.resolve(base_sym) == "self":
                        st_sym = self.current_method_owner_sym
                    if st_sym != 0:
                        let st_idx = self.struct_type_map.get(st_sym)
                        if st_idx.is_some():
                            let fi = self.find_field_index(st_sym, field)
                            if fi >= 0:
                                let st_ty = self.struct_llvm_types.get(st_idx.unwrap() as i64)
                                let base_ptr = wl_build_load(self.builder, base_ty, base_alloca)
                                return wl_build_struct_gep(self.builder, st_ty, base_ptr, fi)
                    let value_sym = self.find_struct_type_by_llvm(base_ty)
                    if value_sym != 0:
                        let fi = self.find_field_index(value_sym, field)
                        if fi >= 0:
                            return wl_build_struct_gep(self.builder, base_ty, base_alloca, fi)
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
    self.loop_break_bbs.push(end_bb)
    self.loop_continue_bbs.push(cond_bb)
    self.loop_result_allocas.push(0)
    self.loop_labels.push(label_sym)
    self.loop_depth = self.loop_depth + 1
    wl_position_at_end(self.builder, body_bb)
    self.gen_expr(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, cond_bb)
    // Pop loop context
    self.loop_depth = self.loop_depth - 1
    wl_position_at_end(self.builder, end_bb)
    wl_get_undef(wl_void_type(self.context))

// ── Loop ──────────────────────────────────────────────────────────

fn Codegen.gen_loop(self: Codegen, node: i32) -> i64:
    let body_node = self.pool.get_data0(node)
    let label_sym = self.pool.get_data1(node)
    let body_bb = wl_append_bb(self.context, self.current_function, "loop.body")
    let end_bb = wl_append_bb(self.context, self.current_function, "loop.end")
    wl_build_br(self.builder, body_bb)
    self.loop_break_bbs.push(end_bb)
    self.loop_continue_bbs.push(body_bb)
    self.loop_result_allocas.push(0)
    self.loop_labels.push(label_sym)
    self.loop_depth = self.loop_depth + 1
    wl_position_at_end(self.builder, body_bb)
    self.gen_expr(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, body_bb)
    self.loop_depth = self.loop_depth - 1
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
    self.local_allocas.insert(binding_sym, alloca)
    self.local_types.insert(binding_sym, iter_ty)
    self.local_muts.insert(binding_sym, 1)
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
    self.loop_break_bbs.push(end_bb)
    self.loop_continue_bbs.push(inc_bb)
    self.loop_result_allocas.push(0)
    self.loop_labels.push(0)
    self.loop_depth = self.loop_depth + 1
    wl_position_at_end(self.builder, body_bb)
    self.gen_expr(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, inc_bb)
    wl_position_at_end(self.builder, inc_bb)
    let next = wl_build_add(self.builder, wl_build_load(self.builder, iter_ty, alloca), wl_const_int(iter_ty, 1, 0))
    wl_build_store(self.builder, next, alloca)
    wl_build_br(self.builder, cond_bb)
    self.loop_depth = self.loop_depth - 1
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
    self.local_allocas.insert(binding_sym, elem_alloca)
    self.local_types.insert(binding_sym, elem_ty)
    self.local_muts.insert(binding_sym, 0)
    let cond_bb = wl_append_bb(self.context, self.current_function, "for.cond")
    let body_bb = wl_append_bb(self.context, self.current_function, "for.body")
    let inc_bb = wl_append_bb(self.context, self.current_function, "for.inc")
    let end_bb = wl_append_bb(self.context, self.current_function, "for.end")
    wl_build_br(self.builder, cond_bb)
    wl_position_at_end(self.builder, cond_bb)
    let cur_i = wl_build_load(self.builder, i_ty, i_alloca)
    let cond = wl_build_icmp(self.builder, wl_int_slt(), cur_i, wl_const_int(i_ty, arr_len, 0))
    wl_build_cond_br(self.builder, cond, body_bb, end_bb)
    self.loop_break_bbs.push(end_bb)
    self.loop_continue_bbs.push(inc_bb)
    self.loop_result_allocas.push(0)
    self.loop_labels.push(0)
    self.loop_depth = self.loop_depth + 1
    wl_position_at_end(self.builder, body_bb)
    let zero = wl_const_int(i_ty, 0, 0)
    let indices: Vec[i64] = Vec.new()
    indices.push(zero)
    indices.push(wl_build_load(self.builder, i_ty, i_alloca))
    let elem_ptr = wl_build_gep(self.builder, arr_ty, arr_alloca, vec_data_i64(indices), 2)
    let elem = wl_build_load(self.builder, elem_ty, elem_ptr)
    wl_build_store(self.builder, elem, elem_alloca)
    self.gen_expr(body_node)
    if wl_get_bb_terminator(wl_get_insert_block(self.builder)) == 0:
        wl_build_br(self.builder, inc_bb)
    wl_position_at_end(self.builder, inc_bb)
    let next = wl_build_add(self.builder, wl_build_load(self.builder, i_ty, i_alloca), wl_const_int(i_ty, 1, 0))
    wl_build_store(self.builder, next, i_alloca)
    wl_build_br(self.builder, cond_bb)
    self.loop_depth = self.loop_depth - 1
    wl_position_at_end(self.builder, end_bb)
    wl_get_undef(wl_void_type(self.context))

// ── Break / Continue ──────────────────────────────────────────────

fn Codegen.gen_break(self: Codegen, node: i32) -> i64:
    let value_node = self.pool.get_data0(node)
    let label_sym = self.pool.get_data1(node)
    if self.loop_depth > 0:
        let idx = self.loop_depth - 1
        let bb = self.loop_break_bbs.get(idx as i64)
        if value_node != 0:
            let val = self.gen_expr(value_node)
            let ra = self.loop_result_allocas.get(idx as i64)
            if ra != 0:
                wl_build_store(self.builder, val, ra)
        wl_build_br(self.builder, bb)
        let dead_bb = wl_append_bb(self.context, self.current_function, "break.dead")
        wl_position_at_end(self.builder, dead_bb)
    wl_get_undef(wl_void_type(self.context))

fn Codegen.gen_continue(self: Codegen, node: i32) -> i64:
    if self.loop_depth > 0:
        let idx = self.loop_depth - 1
        let bb = self.loop_continue_bbs.get(idx as i64)
        wl_build_br(self.builder, bb)
        let dead_bb = wl_append_bb(self.context, self.current_function, "continue.dead")
        wl_position_at_end(self.builder, dead_bb)
    wl_get_undef(wl_void_type(self.context))

// ── Match expression ──────────────────────────────────────────────

fn Codegen.gen_match(self: Codegen, node: i32) -> i64:
    let subject_node = self.pool.get_data0(node)
    let arms_start = self.pool.get_data1(node)
    let arm_count = self.pool.get_data2(node)
    let subject = self.gen_expr(subject_node)
    let subject_ty = wl_type_of(subject)
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
                wl_position_at_end(self.builder, default_bb)
                if pk == NK_PAT_IDENT():
                    let bind_sym = self.pool.get_data0(pat_node)
                    let alloca = self.create_entry_alloca(subject_ty)
                    wl_build_store(self.builder, subject, alloca)
                    self.local_allocas.insert(bind_sym, alloca)
                    self.local_types.insert(bind_sym, subject_ty)
                    self.local_muts.insert(bind_sym, 0)
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
                    let bind_sym = self.pool.get_extra(v_extra)
                    let payload = wl_build_extract_value(self.builder, subject, 1)
                    let pay_ty = wl_type_of(payload)
                    let alloca = self.create_entry_alloca(pay_ty)
                    wl_build_store(self.builder, payload, alloca)
                    self.local_allocas.insert(bind_sym, alloca)
                    self.local_types.insert(bind_sym, pay_ty)
                    self.local_muts.insert(bind_sym, 0)

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
    let es = self.enum_by_llvm.get(enum_ty)
    if not es.is_some(): return 0 - 1
    let enum_sym = es.unwrap()
    let et = self.enum_type_map.get(enum_sym)
    if not et.is_some(): return 0 - 1
    let idx = et.unwrap()
    let v_start = self.enum_variant_starts.get(idx as i64)
    let v_count = self.enum_variant_counts.get(idx as i64)
    for i in 0..v_count:
        if self.enum_variant_names.get((v_start + i) as i64) == variant_sym:
            return i
    0 - 1

// ── Struct literal ────────────────────────────────────────────────

fn Codegen.gen_struct_lit(self: Codegen, node: i32) -> i64:
    let type_sym = self.pool.get_data0(node)
    let fields_start = self.pool.get_data1(node)
    let field_count = self.pool.get_data2(node)
    let st_opt = self.struct_type_map.get(type_sym)
    if not st_opt.is_some(): return wl_get_undef(wl_i32_type(self.context))
    let st_idx = st_opt.unwrap()
    let st_ty = self.struct_llvm_types.get(st_idx as i64)
    let st_field_start = self.struct_field_starts.get(st_idx as i64)
    let st_field_count = self.struct_field_counts.get(st_idx as i64)
    let alloca = wl_build_alloca(self.builder, st_ty)
    let saved_expected = self.expected_type
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
        let fi = self.find_field_index(type_sym, f_name)
        if fi >= 0:
            let fty = self.struct_field_types.get((st_field_start + fi) as i64)
            self.expected_type = fty
            let val = self.gen_expr(f_val_node)
            let gep = wl_build_struct_gep(self.builder, st_ty, alloca, fi)
            wl_build_store(self.builder, self.coerce_int(val, fty), gep)
    self.expected_type = saved_expected
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
    let tag_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 0)
    wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), v_idx as i64, 0), tag_ptr)

    if arg_count > 0:
        let payload_node = self.pool.get_extra(extra_start + 1)
        let payload = self.gen_expr(payload_node)
        let elem_count = wl_count_struct_elem_types(enum_ty)
        if elem_count > 1:
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
                let tag_ptr = wl_build_struct_gep(self.builder, enum_ty, alloca, 0)
                wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), vi as i64, 0), tag_ptr)
                if arg_count > 0:
                    let arg_node = self.pool.get_extra(args_start)
                    let payload = self.gen_expr(arg_node)
                    let elem_count = wl_count_struct_elem_types(enum_ty)
                    if elem_count > 1:
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
    let gep = wl_build_gep(self.builder, arr_ty, alloca, vec_data_i64(indices), 2)
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
        let gep2 = wl_build_gep(self.builder, arr_ty, alloca, vec_data_i64(indices2), 2)
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
    let tup_ty = wl_struct_type(self.context, vec_data_i64(elem_types), elem_count, 0)
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
        base_ptr = wl_build_gep(self.builder, obj_ty, alloca, vec_data_i64(gep_indices), 2)
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
    let slice_ptr = wl_build_gep(self.builder, elem_ty, base_ptr, vec_data_i64(offset_indices), 1)
    let slice_len = wl_build_sub(self.builder, end_ext, start_ext)
    // Build {ptr, len} struct
    let ptr_type = wl_ptr_type(self.context)
    let fields: Vec[i64] = Vec.new()
    fields.push(ptr_type)
    fields.push(i64_ty)
    let slice_ty = wl_struct_type(self.context, vec_data_i64(fields), 2, 0)
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
    let fn_ty = wl_function_type(ret_ty, vec_data_i64(param_types), param_count, 0)
    let closure_fn = wl_add_function(self.llmod, "__closure", fn_ty)
    // Save current state
    let saved_fn = self.current_function
    let saved_bb = wl_get_insert_block(self.builder)
    let saved_allocas = self.local_allocas
    let saved_types = self.local_types
    self.local_allocas = HashMap.new()
    self.local_types = HashMap.new()
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
        self.local_allocas.insert(p_name, alloca)
        self.local_types.insert(p_name, param_ty)
    let body_val = self.gen_expr(body_node)
    if body_val != 0:
        let body_ty = wl_type_of(body_val)
        if wl_get_type_kind(body_ty) != wl_void_type_kind():
            wl_build_ret(self.builder, body_val)
        else:
            wl_build_ret_void(self.builder)
    else:
        wl_build_ret_void(self.builder)
    // Restore state
    self.current_function = saved_fn
    wl_position_at_end(self.builder, saved_bb)
    self.local_allocas = saved_allocas
    self.local_types = saved_types
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
        return wl_build_call(self.builder, fn_ty, rhs_val, vec_data_i64(args), 1)
    // Fallback: treat as identity
    lhs_val

// ── With Expression ───────────────────────────────────────────────

fn Codegen.gen_with_expr(self: Codegen, node: i32) -> i64:
    // with expr as binding: body
    let expr_node = self.pool.get_data0(node)
    let body_node = self.pool.get_data1(node)
    let binding_sym = self.pool.get_data2(node)
    let val = self.gen_expr(expr_node)
    let val_ty = wl_type_of(val)
    // Store binding as local
    let alloca = self.create_entry_alloca(val_ty)
    wl_build_store(self.builder, val, alloca)
    self.local_allocas.insert(binding_sym, alloca)
    self.local_types.insert(binding_sym, val_ty)
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
    let range_ty = wl_struct_type(self.context, vec_data_i64(fields), 2, 0)
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
    wl_add_incoming(phi, vec_data_i64(vals), vec_data_i64(bbs), 2)
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
        self.local_allocas.insert(name_sym, alloca)
        self.local_types.insert(name_sym, elem_ty)
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
    self.local_allocas.insert(binding_sym, idx_alloca)
    self.local_types.insert(binding_sym, i32_ty)
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
    let fn_ty = wl_function_type(i32_ty, vec_data_i64(param_types), 1, 1) // variadic
    wl_add_function(self.llmod, "printf", fn_ty)

fn Codegen.get_printf_fn_type(self: Codegen) -> i64:
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(ptr_ty)
    wl_function_type(i32_ty, vec_data_i64(param_types), 1, 1)

fn Codegen.ensure_fprintf_declared(self: Codegen) -> i64:
    let existing = wl_get_named_function(self.llmod, "fprintf")
    if existing != 0: return existing
    let i32_ty = wl_i32_type(self.context)
    let ptr_ty = wl_ptr_type(self.context)
    let param_types: Vec[i64] = Vec.new()
    param_types.push(ptr_ty)
    param_types.push(ptr_ty)
    let fn_ty = wl_function_type(i32_ty, vec_data_i64(param_types), 2, 1)
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

fn Codegen.gen_print_value(self: Codegen, val: i64, printf_fn: i64, printf_ty: i64):
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
        wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(args), 3)
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
        let open_fmt = wl_build_global_string_ptr(self.builder, "{")
        let open_args: Vec[i64] = Vec.new()
        open_args.push(open_fmt)
        wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(open_args), 1)
        for fi in 0..field_count:
            if fi > 0:
                let comma_fmt = wl_build_global_string_ptr(self.builder, ", ")
                let comma_args: Vec[i64] = Vec.new()
                comma_args.push(comma_fmt)
                wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(comma_args), 1)
            let fv = wl_build_extract_value(self.builder, val, fi)
            self.gen_print_value(fv, printf_fn, printf_ty)
        let close_fmt = wl_build_global_string_ptr(self.builder, "}")
        let close_args: Vec[i64] = Vec.new()
        close_args.push(close_fmt)
        wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(close_args), 1)
        return
    else:
        fmt = "%d"
    let fmt_str = wl_build_global_string_ptr(self.builder, fmt)
    let args: Vec[i64] = Vec.new()
    args.push(fmt_str)
    args.push(print_val)
    wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(args), 2)

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
            wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(nl_args), 1)
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
        wl_build_call(self.builder, printf_ty, printf_fn, vec_data_i64(nl_args), 1)
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
        let result = wl_build_call(self.builder, self.get_runtime_fn_type(i32_ty, 2), fn_val, vec_data_i64(args), 2)
        return wl_build_icmp(self.builder, wl_int_ne(), result, wl_const_int(i32_ty, 0, 0))
    if method == "starts_with" and arg_count > 0:
        let prefix = self.gen_expr(self.pool.get_extra(args_start))
        let fn_val = self.ensure_c_fn("with_str_starts_with", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(obj)
        args.push(prefix)
        let result = wl_build_call(self.builder, self.get_runtime_fn_type(i32_ty, 2), fn_val, vec_data_i64(args), 2)
        return wl_build_icmp(self.builder, wl_int_ne(), result, wl_const_int(i32_ty, 0, 0))
    if method == "ends_with" and arg_count > 0:
        let suffix = self.gen_expr(self.pool.get_extra(args_start))
        let fn_val = self.ensure_c_fn("with_str_ends_with", i32_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(obj)
        args.push(suffix)
        let result = wl_build_call(self.builder, self.get_runtime_fn_type(i32_ty, 2), fn_val, vec_data_i64(args), 2)
        return wl_build_icmp(self.builder, wl_int_ne(), result, wl_const_int(i32_ty, 0, 0))
    if method == "find" and arg_count > 0:
        let needle = self.gen_expr(self.pool.get_extra(args_start))
        let fn_val = self.ensure_c_fn("with_str_index_of", i64_ty, 2)
        let args: Vec[i64] = Vec.new()
        args.push(obj)
        args.push(needle)
        return wl_build_call(self.builder, self.get_runtime_fn_type(i64_ty, 2), fn_val, vec_data_i64(args), 2)
    if method == "slice" and arg_count >= 2:
        let start = self.gen_expr(self.pool.get_extra(args_start))
        let end = self.gen_expr(self.pool.get_extra(args_start + 1))
        let start64 = self.coerce_int(start, i64_ty)
        let end64 = self.coerce_int(end, i64_ty)
        // GEP to start, compute new len
        let indices: Vec[i64] = Vec.new()
        indices.push(start64)
        let new_ptr = wl_build_gep(self.builder, i8_ty, str_ptr, vec_data_i64(indices), 1)
        let new_len = wl_build_sub(self.builder, end64, start64)
        return self.build_str_value(new_ptr, new_len)
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
    // For runtime functions, all params are i64 or str-like. Use generic signature.
    let fn_ty = self.get_runtime_fn_type(ret_ty, param_count)
    wl_add_function(self.llmod, name, fn_ty)

fn Codegen.get_runtime_fn_type(self: Codegen, ret_ty: i64, param_count: i32) -> i64:
    // Runtime functions take str structs or i64 params
    // For str-based functions: params are {ptr, i64} structs
    let str_sym = self.intern.intern("str")
    let st_opt = self.struct_type_map.get(str_sym)
    let str_type = if st_opt.is_some(): self.struct_llvm_types.get(st_opt.unwrap() as i64) else wl_i64_type(self.context)
    let params: Vec[i64] = Vec.new()
    for i in 0..param_count:
        params.push(str_type)
    wl_function_type(ret_ty, vec_data_i64(params), param_count, 0)

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
        let la = self.local_allocas.get(sym)
        if la.is_some():
            vec_ptr = la.unwrap() as i64

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
        let push_fn = self.ensure_vec_runtime_fn("with_vec_push", wl_void_type(self.context), 2)
        let push_ty = self.get_vec_fn_type(wl_void_type(self.context), 2)
        let args: Vec[i64] = Vec.new()
        args.push(vec_ptr)
        args.push(elem_alloca)
        return wl_build_call(self.builder, push_ty, push_fn, vec_data_i64(args), 2)
    if method == "get" and arg_count > 0:
        let idx = self.gen_expr(self.pool.get_extra(args_start))
        let idx64 = self.coerce_int(idx, i64_ty)
        let get_fn = self.ensure_vec_runtime_fn("with_vec_get_ptr", ptr_ty, 2)
        let get_ty = self.get_vec_fn_type(ptr_ty, 2)
        let args: Vec[i64] = Vec.new()
        if vec_ptr != 0:
            args.push(vec_ptr)
        else:
            let alloca = wl_build_alloca(self.builder, wl_type_of(obj))
            wl_build_store(self.builder, obj, alloca)
            args.push(alloca)
        args.push(idx64)
        let raw_ptr = wl_build_call(self.builder, get_ty, get_fn, vec_data_i64(args), 2)
        // Load the element from the raw pointer
        // Determine element type from cache
        let vci = self.vec_cache_map.get(wl_type_of(obj))
        if vci.is_some():
            let elem_ty = self.vec_elem_types.get(vci.unwrap() as i64)
            return wl_build_load(self.builder, elem_ty, raw_ptr)
        return raw_ptr
    if method == "pop" and vec_ptr != 0:
        let len_fn = self.ensure_vec_runtime_fn("with_vec_len", i64_ty, 1)
        let len_ty = self.get_vec_fn_type(i64_ty, 1)
        let len_args: Vec[i64] = Vec.new()
        len_args.push(vec_ptr)
        let len = wl_build_call(self.builder, len_ty, len_fn, vec_data_i64(len_args), 1)
        return len // stub — full impl needs get+remove
    if method == "clear" and vec_ptr != 0:
        let clear_fn = self.ensure_vec_runtime_fn("with_vec_clear", wl_void_type(self.context), 1)
        let clear_ty = self.get_vec_fn_type(wl_void_type(self.context), 1)
        let args: Vec[i64] = Vec.new()
        args.push(vec_ptr)
        return wl_build_call(self.builder, clear_ty, clear_fn, vec_data_i64(args), 1)
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
    let fn_ty = self.get_vec_fn_type(ret_ty, param_count)
    wl_add_function(self.llmod, name, fn_ty)

fn Codegen.get_vec_fn_type(self: Codegen, ret_ty: i64, param_count: i32) -> i64:
    let ptr_ty = wl_ptr_type(self.context)
    let i64_ty = wl_i64_type(self.context)
    let params: Vec[i64] = Vec.new()
    // First param is always ptr (to Vec struct)
    params.push(ptr_ty)
    var i = 1
    while i < param_count:
        params.push(i64_ty) // remaining params are i64 or ptr
        i = i + 1
    wl_function_type(ret_ty, vec_data_i64(params), param_count, 0)

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
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(self.make_ptr_vec()), 1, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        return wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(args), 1)
    if method == "contains" and arg_count > 0:
        let key = self.gen_expr(self.pool.get_extra(args_start))
        let key_alloca = wl_build_alloca(self.builder, wl_type_of(key))
        wl_build_store(self.builder, key, key_alloca)
        let fn_val = self.ensure_hm_fn("with_hashmap_contains", i64_ty)
        let params: Vec[i64] = Vec.new()
        params.push(ptr_ty)
        params.push(ptr_ty)
        params.push(i64_ty)
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(params), 3, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(is_str_val)
        let result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(args), 3)
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
        let fn_ty = wl_function_type(wl_void_type(self.context), vec_data_i64(params), 4, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(val_alloca)
        args.push(is_str_val)
        return wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(args), 4)
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
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(params), 4, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(out_alloca)
        args.push(is_str_val)
        let found = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(args), 4)
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
        let fn_ty = wl_function_type(i64_ty, vec_data_i64(params), 3, 0)
        let args: Vec[i64] = Vec.new()
        args.push(map_ptr)
        args.push(key_alloca)
        args.push(is_str_val)
        return wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(args), 3)
    // increment, decrement, update, append — stubs for now
    wl_get_undef(wl_i32_type(self.context))

fn Codegen.ensure_hm_fn(self: Codegen, name: str, ret_ty: i64) -> i64:
    let existing = wl_get_named_function(self.llmod, name)
    if existing != 0: return existing
    let ptr_ty = wl_ptr_type(self.context)
    let params: Vec[i64] = Vec.new()
    params.push(ptr_ty)
    let fn_ty = wl_function_type(ret_ty, vec_data_i64(params), 1, 0)
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
        let mapped = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(call_args), 1)
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
        wl_add_incoming(phi, vec_data_i64(phi_vals), vec_data_i64(phi_bbs), 2)
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
        let then_result = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(call_args), 1)
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
        wl_add_incoming(phi, vec_data_i64(phi_vals), vec_data_i64(phi_bbs), 2)
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

fn Codegen.emit_exit_call(self: Codegen, code: i32):
    let exit_fn = wl_get_named_function(self.llmod, "_exit")
    if exit_fn == 0:
        let i32_ty = wl_i32_type(self.context)
        let params: Vec[i64] = Vec.new()
        params.push(i32_ty)
        let fn_ty = wl_function_type(wl_void_type(self.context), vec_data_i64(params), 1, 0)
        let f = wl_add_function(self.llmod, "_exit", fn_ty)
        let args: Vec[i64] = Vec.new()
        args.push(wl_const_int(i32_ty, code as i64, 0))
        wl_build_call(self.builder, fn_ty, f, vec_data_i64(args), 1)
    else:
        let fn_ty = wl_global_get_value_type(exit_fn)
        let args: Vec[i64] = Vec.new()
        args.push(wl_const_int(wl_i32_type(self.context), code as i64, 0))
        wl_build_call(self.builder, fn_ty, exit_fn, vec_data_i64(args), 1)
